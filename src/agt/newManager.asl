{ include("$jacamo/templates/common-cartago.asl") }
{ include("$jacamo/templates/common-moise.asl") }

/* Initial beliefs */
+listaVagas([ ]).

/* Initial goals */
!criarCarteira.

/* plans */

// ----------------------------- COMMONS ------------------------------
+!consultarVaga(TipoVaga, Data)[source(DriverAgent)]: listaVagas(Lista) <-
	.send(DriverAgent, askOne, driverWallet(DriverW), Reply);
	.wait(3000);
	+Reply;
	// +driverIntention(Intencao); // talvez seja inutil
	// .print("Verificando disponibilidade...");
	!disponibilidadeCompra(TipoVaga, Data, set(Lista));
	?vagaDisponivel(Status);
	.send(DriverAgent, tell, vagaDisponivel(Status));
	.abolish(vagaDisponivel(_));
	?idVaga(Head);
	.send(DriverAgent, tell, idVaga(Head));
	.abolish(idVaga(_)).

+!consultarVaga(TipoVaga, Data)[source(DriverAgent)] : not listaVagas(Lista) <-
	.print("Estacionamento fechado!").

-!consultarVaga(TipoVaga, Data)[source(DriverAgent)] <-
	.print("Vaga nao encontrada").

+!disponibilidadeCompra(TipoVaga, Data, set([Head|Tail])): chainServer(Server) <-
	.velluscinum.tokenInfo(Server, Head, all, content);
	.wait(content(Metadata));
	verificarCompra(TipoVaga, Metadata, Status);
	.abolish(content(_));

	if (Status == true) {
		+idVaga(Head);
		+vagaDisponivel(true);
	}

	?vagaDisponivel(Status).

-!disponibilidadeCompra(TipoVaga, Data, set([Head|Tail])): chainServer(Server) <-
	!disponibilidadeCompra(TipoVaga, Data, set(Tail)).

-!disponibilidadeCompra(TipoVaga, Data, set([ ])) <-
	+vagaDisponivel(false);
	.print("percorreu todas as vagas").

// -------------------------- COMPRA DIRETA ---------------------------

+querEstacionar(Id)[source(DriverAgent)] <- 
	!ocuparVaga(Id);
	?vagaOcupada(Id);
	.print(DriverAgent, " => pode estacionar");
	.send(DriverAgent, tell, vagaOcupada(Id));
	.abolish(querEstacionar(_));
	.abolish(vagaOcupada(_)).

-querEstacionar(Id)[source(DriverAgent)] <-
	.print("Vaga nao ocupada").

+!pagamentoUsoVaga(Tipo, Minutos)[source(DriverAgent)] : driverWallet(DriverW) <-
	// .print("Calculando valor...");
	calcularValorAPagarUso(Tipo, Minutos, Valor);
	.print(DriverAgent, " => valor a pagar: ", Valor);
	.send(DriverAgent,tell,valorAPagarUso(Valor)).

// -------------------------- COMPRAR RESERVA -------------------------

+!consultarReserva(TipoVaga, Data, Tempo)[source(DriverAgent)] : listaVagas(Lista) <-
	.print(DriverAgent, " quer consultar reserva");
	// .print("Consultar reserva...");
	.send(DriverAgent, askOne, driverWallet(DriverW), Reply);
	.wait(3000);
	+Reply;
	!disponibilidadeReserva(TipoVaga, Data, Tempo, set(Lista));
	if (reservaDisponivel(Status) & Status == true) {
		.print("Reserva disponivel");
		?idVaga(Id);
		.send(DriverAgent, tell, idVaga(Id));
		.send(DriverAgent, tell, vagaDisponivel(true));
		.abolish(vagaDisponivelId(_));
		.abolish(reservaDisponivel(_));
	}.

+!consultarReserva(TipoVaga, Data, Tempo)[source(DriverAgent)] : not listaVagas(Lista) <-
	.print("Estacionamento fechado!").

-!consultarReserva(TipoVaga, Data, Tempo)[source(DriverAgent)] <-
	.print("Nao foi possivel consultar a reserva").

+!disponibilidadeReserva(TipoVaga, Data, Tempo, set([Head|Tail])): chainServer(Server) <-
	.print("Verificando disponibilidade da reserva : ", Head);
	.velluscinum.tokenInfo(Server, Head, all, content);
	.wait(content(Content));
	.print("content -> ", Content);
	.abolish(vagaDisponivel(_));
	.abolish(reservaDisponivel(_));
	
	verificarReserva(TipoVaga, Data, Tempo, Content);
	.abolish(content(_));
	?reservaDisponivel(Status);
	.print("reservaDisponivel: ", Status);
	if (Status == true) {
		.print("Vaga encontrada para reserva -> ", Head);
		+idVaga(Head);
	} else {
		!disponibilidadeReserva(TipoVaga, Data, Tempo, set(Tail));
	}.

-!disponibilidadeReserva: not vagaDisponivel(Status) <-
	.print("sem vaga disponivel!").

-!disponibilidadeReserva(TipoVaga, Data, Tempo, set([Head|Tail])): chainServer(Server) <-
	!disponibilidadeReserva(TipoVaga, Data, Tempo, set(Tail)).

-!disponibilidadeReserva(TipoVaga, Data, Tempo, set([ ])) <-
	+vagaDisponivel(false);
	.print("percorreu todas as vagas").

+pagouReserva(TransactionId, IdVaga, Data, Tempo)[source(DriverAgent)] <-
	!stampProcess(TransactionId);
	!sendReservation(IdVaga, Data, Tempo);
	?reservaNFT(ReservaId, TransferId);
	.send(DriverAgent, tell, reservaNFT(ReservaId, TransferId));
	.abolish(reservaNFT(_)).

-pagouReserva(TransactionId, IdVaga, Data, Tempo)[source(DriverAgent)] <-
	.print("Reserva nao gerada").

+!sendReservation(IdVaga, Data, Tempo)[source(self)] : chainServer(Server) & myWallet(PrK, PuK)
			& driverWallet(DriverW) <-
	.abolish(nft(_));
	.abolish(transfer(_));

	.velluscinum.tokenInfo(Server, IdVaga, data, content);
	.wait(content(Content));

	getVacancyInfo(Content);
	?tipoVaga(TipoAtual);
	?statusVaga(StatusAtual);

	.concat("description:vacancy reservation;type:", TipoAtual, ";date:", Data, ";duration:", Tempo, Dados);
	.concat("description:vacancy reservation;type:", Descricao);
	.velluscinum.deployNFT(Server, PrK, PuK, Dados, Descricao, nft);
	.wait(nft(ReservaId));

	!ocuparVaga(IdVaga, Data, Tempo, StatusAtual, ReservaId);
	?ocupacao(IdOcupacao);

	.concat("reservation:", ReservaId, ";type:", TipoAtual, ";date:", Data, ";time:", Tempo, DescricaoReserva);
	.velluscinum.transferNFT(Server, PrK, PuK, ReservaId, DriverW, DescricaoReserva, transfer);
	.wait(transfer(TransferId));

	+reservaNFT(ReservaId, TransferId);
	
	.abolish(tipoVaga(_));
	.abolish(statusVaga(_)).

+!sendReservation(IdVaga, Data, Tempo)[source(self)] : not driverWallet(DriverW) <-
	.send(driver, askOne, driverWallet(DriverW), Reply);
	.wait(3000);
	+Reply;
	!sendReservation(IdVaga, Data, Tempo).

-!sendReservation(IdVaga, Data, Tempo)[source(self)] <-
	.print("Nao foi possivel reservar a vaga").

+!ocuparVaga(IdVaga, Data, Tempo, Status, ReservaId) : chainServer(Server) & myWallet(PrK, PuK) <-
	// .print("Ocupando Vaga: ", IdVaga);
	.velluscinum.tokenInfo(Server, IdVaga, metadata, content);
	.wait(content(Registrado));

	registrarReserva(Registrado, Status, ReservaId, Data, Tempo);
	?reservation(Metadados);
	
	.velluscinum.transferNFT(Server, PrK, PuK, IdVaga, PuK, Metadados, ocupacao);
	.wait(ocupacao(IdOcupacao));
	
	.abolish(reservation(_));

	.print("Vaga ocupada com sucesso!").

// -------------------------- USO DA RESERVA --------------------------

+querUsarReserva(ReservaId, TransactionId)[source(DriverAgent)] <-
	!stampProcess(TransactionId);
	!validarReserva(ReservaId);
	?reservaEncontrada(VagaId);
	.send(DriverAgent,achieve,estacionarReserva(VagaId));
	.abolish(reservaEncontrada(_));
	.abolish(querUsarReserva(_)).

-querUsarReserva(ReservaId, TransactionId)[source(DriverAgent)] <-
	.print("Reserva nao encontrada").

+querSair(VagaId)[source(DriverAgent)] <-
	// .print("Liberando vaga motorista...");
	!liberarVaga(VagaId);
	?vagaLiberada;
	.send(DriverAgent, achieve, sairEstacionamento).

-querSair(VagaId) <-
	.print("Vaga nao liberada").

+!validarReserva(ReservaId) : listaVagas(Lista) <-
	.print("Validando reserva: ", ReservaId);
	!percorrerListaVagas(ReservaId, set(Lista));
	?reservaEncontrada(VagaId);
	// .print("Vaga equivalente da reserva: ", VagaId);
	!ocuparVaga.

-!validarReserva(ReservaId) <-
	.print("Reserva nao encontrada").
	
+!percorrerListaVagas(ReservaId, set([Head|Tail])) : not reservaEncontrada(VagaId) <-
    !analisarVaga(ReservaId, Head, set(Tail));
    !percorrerListaVagas(ReservaId, set(Tail)).

+!percorrerListaVagas(ReservaId, set([Head|Tail])) : reservaEncontrada(VagaId) <- 
	.print("Reserva encontrada").

-!percorrerListaVagas(Type, set([ ])).

+!analisarVaga(ReservaId, VagaId, set(V)): chainServer(Server) <-
	// fazer verificacao se o NFT eh uma vaga mesmo
	// .print("Analisando vaga: ", VagaId);
	.velluscinum.tokenInfo(Server, VagaId, metadata, dadosVaga);
	.wait(dadosVaga(Dados));
	acharReserva(ReservaId, VagaId, Dados);
	.abolish(dadosVaga(_)).

-!analisarVaga(ReservaId, VagaId, set(V)).

// ---------------------- NEGOCIACAO DA RESERVA -----------------------

+reservationAvailable(Type,Date,Min)[source(driver)] <-
	.print("Motorista colocou reserva disponivel").

// ---------------------------- AUXILIARES ----------------------------

// fazer metodo para quando nao for validado o stamp
+!validarPagamento(Transfer, IdVaga)[source(DriverAgent)] <-
	!stampProcess(Transfer);
	.print(DriverAgent, " => pagamento validado!");
	!liberarVaga(IdVaga);
	?vagaLiberada;
	.print(DriverAgent, " => vaga liberada!");
	.send(DriverAgent, achieve, sairEstacionamento).

-!validarPagamento(Transfer, IdVaga)[source(DriverAgent)] <-
	.print(DriverAgent, " => vaga nao liberada").

+!stampProcess(Transfer)[source(self)] : chainServer(Server) 
            & myWallet(PrK,PuK) <-
	.velluscinum.stampTransaction(Server,PrK,PuK,Transfer).

+!ocuparVaga(Id): chainServer(Server) & myWallet(PrK, PuK) <-
	.velluscinum.transferNFT(Server, PrK, PuK, Id, PuK, "status:ocupado", requestID);
	.wait(requestID(TransferId));
	+vagaOcupada(Id).

+!ocuparVaga : chainServer(Server) & myWallet(PrK, PuK) & reservaEncontrada(VagaId) <-
	.velluscinum.transferNFT(Server, PrK, PuK, VagaId, PuK, "status:ocupado", requestID);
	.wait(requestID(TransferId));
	.print("Vaga Ocupada").

+!liberarVaga(Id): chainServer(Server) & myWallet(PrK,PuK) <-
	// .print("Liberando Vaga: ", Id);
	// verificar se a reserva ainda existe se a vaga for liberada
	.velluscinum.transferNFT(Server, PrK, PuK, Id, PuK, "status:disponivel", requestID);
	.wait(requestID(TransferId));
	+vagaLiberada.

// -------------------------- ANTES DE ABRIR --------------------------

+vaga(Vaga): listaVagas(Lista) & not .empty(Lista) <- 
	-+listaVagas([Vaga|Lista]).

+vaga(Vaga) <- -+listaVagas([Vaga]).

+!criarCarteira <-
	.print("Obtendo carteira digital!");
	.velluscinum.loadWallet(myWallet);
	.wait(myWallet(PrK,PuK));
	+managerWallet(PuK);
	.wait(5000);
	!verificarListaVagas.

+!verificarListaVagas: chainServer(Server) & myWallet(PrK,PuK) <-
	.print("Verificando lista de vagas...");
	.velluscinum.walletContent(Server, PrK, PuK, content);
	.wait(content(Content));
	!findToken(nft, set(Content));
	!abrirEstacionamento.

+!verificarListaVagas: not chainServer(Server) <-
	.wait(5000);
	!verificarListaVagas.

+!abrirEstacionamento : listaVagas(Vagas) <-
	.print("Estacionamento Aberto!");
	.broadcast(tell, estacionamentoAberto).

+!listarVagas: chainServer(Server) & myWallet(PrK,PuK) <- 
	.velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga1;tipo:Curta", "status:disponivel", account);
	.wait(account(Vaga1Id));

	.velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga2;tipo:Longa", "status:disponivel", account);
	.wait(account(Vaga2Id));

	.velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga3;tipo:Longa", "status:disponivel", account);
	.wait(account(Vaga3Id));

	.velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga4;tipo:CurtaCoberta", "status:disponivel", account);
	.wait(account(Vaga4Id));

	.velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga5;tipo:LongaCoberta", "status:disponivel", account);
	.wait(account(Vaga5Id));

	Lista = [Vaga1Id, Vaga2Id, Vaga3Id, Vaga4Id, Vaga5Id];
	-+listaVagas(Lista).

-!listarVagas <-
	.print("Nao foi possivel listar as vagas").

+!findToken(Term,set([Head|Tail])) <- 
    !compare(Term,Head,set(Tail));
    !findToken(Term,set(Tail)).

+!compare(Term,[Type,AssetId, Qtd],set(V)): (Term  == Type) | (Term == AssetId) <-
	// .print("Vaga: ", AssetId);
	+vaga(AssetId).

-!compare(Term,[Type,AssetId,Qtd],set(V)) <- .print("The Asset ",AssetId, " is not a ",Term).

-!findToken(Type,set([   ])): not vaga(Vaga) <- 
	.print("Lista de vagas nao encontrada");
	!listarVagas.

-!findToken(Type,set([   ])): vaga(Vaga) <- 
	.print("Vagas ja cadastradas").

