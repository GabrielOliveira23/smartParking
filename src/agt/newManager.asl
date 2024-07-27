{ include("$jacamo/templates/common-cartago.asl") }
{ include("$jacamo/templates/common-moise.asl") }

/* Initial beliefs */
+listaVagas([ ]).

/* Initial goals */
!criarCarteira.

/* plans */

// ----------------------------- COMMONS ------------------------------

+vagaDisponivel(Status) <-
	.send(driver, tell, vagaDisponivel(Status));
	-vagaDisponivel(Status).

+idVaga(Id) <- 
	.send(driver, tell, idVaga(Id));
	-idVaga(Id).

+!consultarVaga(TipoVaga, Data, Intencao)[source(driver)]: listaVagas(Lista) <-
	.send(driver, askOne, driverWallet(DriverW), Reply);
	.wait(3000);
	+Reply;
	+driverIntention(Intencao); // talvez seja inutil
	.print("Verificando disponibilidade...");
	!disponibilidadeCompra(TipoVaga, Data, set(Lista)).

+!consultarVaga(TipoVaga, Data, Intencao)[source(driver)] : not listaVagas(Lista) <-
	.print("Estacionamento fechado!").

+!disponibilidadeCompra(TipoVaga, Data, set([Head|Tail])): chainServer(Server) & (not vagaDisponivel(Status) | (vagaDisponivel(Status) & (Status == false))) <-
	velluscinum.tokenInfo(Server, Head, all, content);
	.wait(content(Metadata));
	verificarCompra(TipoVaga, Metadata);
	?vagaDisponivel(Status);
	+idVaga(Head).

-!disponibilidadeCompra(TipoVaga, Data, set([Head|Tail])): chainServer(Server) <-
	!disponibilidadeCompra(TipoVaga, Data, set(Tail)).

-!disponibilidadeCompra(TipoVaga, Data, set([ ])) <-
	+vagaDisponivel(false);
	.print("percorreu todas as vagas").

// -------------------------- COMPRA DIRETA ---------------------------

+valorAPagarUso(Valor) <- .send(driver, tell, valorAPagarUso(Valor)).

+querEstacionar(Id)[source(driver)] <- !ocuparVaga(Id).

+!pagamentoUsoVaga(Tipo, Minutos)[source(driver)] : driverWallet(DriverW) <-
	.print("Calculando valor...");
	calcularValorAPagarUso(Tipo, Minutos).

// -------------------------- COMPRAR RESERVA -------------------------

+!consultarReserva(TipoVaga, Data, Tempo)[source(driver)] : listaVagas(Lista) <-
	.print("Consultar reserva...");
	.send(driver, askOne, driverWallet(DriverW), Reply);
	.wait(3000);
	+Reply;
	!disponibilidadeReserva(TipoVaga, Data, Tempo, set(Lista)).

+!consultarReserva(TipoVaga, Data, Tempo)[source(driver)] : not listaVagas(Lista) <-
	.print("Estacionamento fechado!").

+!disponibilidadeReserva(TipoVaga, Data, Tempo, set([Head|Tail])): chainServer(Server) & (not vagaDisponivel(Status) | (vagaDisponivel(Status) & (Status == false))) <-
	velluscinum.tokenInfo(Server, Head, all, content);
	.wait(content(Metadata));
	verificarReserva(TipoVaga, Data, Tempo, Metadata);
	?vagaDisponivel(Status);
	.print("Vaga encontrada para reserva -> ", Head);
	+idVaga(Head).

-!disponibilidadeReserva(TipoVaga, Data, Tempo, set([Head|Tail])): chainServer(Server) <-
	!disponibilidadeReserva(TipoVaga, Data, Tempo, set(Tail)).

-!disponibilidadeReserva(TipoVaga, Data, Tempo, set([ ])) <-
	+vagaDisponivel(false);
	.print("percorreu todas as vagas").

+pagouReserva(TransactionId, IdVaga, Data, Tempo)[source(driver)] <-
	.print("Pagou reserva...");
	!stampProcess(TransactionId);
	!sendReservation(IdVaga, Data, Tempo).

+!sendReservation(IdVaga, Data, Tempo)[source(self)] : chainServer(Server) & myWallet(PrK, PuK)
			& driverWallet(DriverW) <-
	velluscinum.tokenInfo(Server, IdVaga, data, content);
	.wait(content(Content));

	getVacancyInfo(Content);
	?tipoVaga(TipoAtual);
	?statusVaga(StatusAtual);

	.concat("description:vacancy reservation;type:", TipoAtual, ";date:", Data, ";duration:", Tempo, Dados);
	.concat("description:vacancy reservation;type:", Descricao);
	velluscinum.deployNFT(Server, PrK, PuK, Dados, Descricao, nft);
	.wait(nft(ReservaId));

	!ocuparVaga(IdVaga, Data, Tempo, StatusAtual, ReservaId);
	?ocupation(OcupationId);

	.concat("reservation:", ReservaId, ";type:", TipoAtual, ";date:", Data, ";time:", Tempo, DescricaoReserva);
	velluscinum.transferNFT(Server, PrK, PuK, ReservaId, DriverW, DescricaoReserva, transfer);
	.wait(transfer(TransferId));
	
	-tipoVaga(TipoAtual);
	-statusVaga(StatusAtual);
	
	.print("Reserva transferida para motorista");
	.send(driver, tell, reservaNFT(ReservaId, TransferId)).

+!sendReservation(IdVaga, Data, Tempo)[source(self)] : not driverWallet(DriverW) <-
	.send(driver, askOne, driverWallet(DriverW), Reply);
	.wait(3000);
	+Reply;
	!sendReservation(IdVaga, Data, Tempo).

-!sendReservation(IdVaga, Data, Tempo)[source(self)] <-
	.print("Nao foi possivel reservar a vaga").

+!ocuparVaga(IdVaga, Data, Tempo, Status, ReservaId) : chainServer(Server) & myWallet(PrK, PuK) <-
	.print("Ocupando Vaga...");
	velluscinum.tokenInfo(Server, IdVaga, metadata, content);
	.wait(content(Registrado));

	registrarReserva(Registrado, Status, ReservaId, Data, Tempo);
	?reservation(Metadados);
	
	velluscinum.transferNFT(Server, PrK, PuK, IdVaga, PuK, Metadados, ocupation);
	.wait(ocupation(OcupationId));
	
	-reservation(Metadados);

	.print("Vaga ocupada com sucesso!").

// -------------------------- USO DA RESERVA --------------------------

+querUsarReserva(ReservaId, TransactionId) <-
	!stampProcess(TransactionId);
	!validarReserva(ReservaId).

+querSair(VagaId) <-
	.print("Liberando vaga motorista...");
	!liberarVaga(VagaId).

+!validarReserva(ReservaId) : listaVagas(Lista) <-
	.print("Validando reserva...");
	.print("ReservaId: ", ReservaId);
	!percorrerListaVagas(ReservaId, set(Lista));
	?reservaEncontrada(VagaId);
	.print("Vaga equivalente da reserva: ", VagaId);
	!ocuparVaga;
	.send(driver, achieve, estacionarReserva(VagaId)).

-!validarReserva(ReservaId) <-
	.print("Reserva nao encontrada").
	
+!percorrerListaVagas(ReservaId, set([Head|Tail])) : not reservaEncontrada(VagaId) <-
    !analisarVaga(ReservaId, Head, set(Tail));
    !percorrerListaVagas(ReservaId, set(Tail)).

+!percorrerListaVagas(ReservaId, set([Head|Tail])) : reservaEncontrada(VagaId) <- 
	.print("Reserva encontrada").

-!percorrerListaVagas(Type, set([ ])).

+!analisarVaga(ReservaId, VagaId, set(V)): chainServer(Server) <-
	velluscinum.tokenInfo(Server, VagaId, metadata, dadosVaga);
	.wait(dadosVaga(Dados));
	acharReserva(ReservaId, VagaId, Dados);
	-dadosVaga(Dados).

-!analisarVaga(ReservaId, VagaId, set(V)).

// ---------------------- NEGOCIACAO DA RESERVA -----------------------

+reservationAvailable(Type,Date,Min)[source(driver)] <-
	.print("Motorista colocou reserva disponivel").

// ---------------------------- AUXILIARES ----------------------------

+reservationUse(TransactionId) <- !stampProcess(TransactionId);
	.print("reserva usada");
	.send(driver, achieve, park).

+!validarPagamento(Transfer, IdVaga)[source(driver)] :  driverIntention(Intention) <-
	!stampProcess(Transfer);
	.print("Vaga paga!");
	!liberarVaga(IdVaga).

+!stampProcess(Transfer)[source(self)] : chainServer(Server) 
            & myWallet(PrK,PuK) <-
	.print("Validando transferencia...");
	velluscinum.stampTransaction(Server,PrK,PuK,Transfer).

+!ocuparVaga(Id): chainServer(Server) & myWallet(PrK, PuK) <-
	.print("Ocupando Vaga: ", Id);
	velluscinum.transferNFT(Server, PrK, PuK, Id, PuK, "status:ocupado", requestID);
	.wait(requestID(TransferId));
	.send(driver, tell, vagaOcupada(Id)).

+!ocuparVaga : chainServer(Server) & myWallet(PrK, PuK) & reservaEncontrada(VagaId) <-
	.print("Ocupando Vaga: ", VagaId);
	velluscinum.transferNFT(Server, PrK, PuK, VagaId, PuK, "status:ocupado", requestID);
	.wait(requestID(TransferId));
	.print("Vaga Ocupada").

+!liberarVaga(Id): chainServer(Server) & myWallet(PrK,PuK) <-
	.print("Liberando Vaga: ", Id);
	velluscinum.transferNFT(Server, PrK, PuK, Id, PuK, "status:disponivel", requestID);
	.wait(requestID(TransferId));
	.print("Vaga Liberada");
	.send(driver, achieve, sairEstacionamento).

// -------------------------- ANTES DE ABRIR --------------------------

+vaga(Vaga): listaVagas(Lista) & not .empty(Lista) <- 
	-+listaVagas([Vaga|Lista]).

+vaga(Vaga) <- -+listaVagas([Vaga]).

+!criarCarteira <-
	.print("Obtendo carteira digital!");
	velluscinum.loadWallet(myWallet);
	.wait(myWallet(PrK,PuK));
	+managerWallet(PuK);
	.wait(5000);
	!verificarListaVagas.

+!verificarListaVagas: chainServer(Server) & myWallet(PrK,PuK) <-
	.print("Verificando lista de vagas...");
	velluscinum.walletContent(Server, PrK, PuK, content);
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
	.print("Listando vagas...");

	velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga1;tipo:Curta", "status:disponivel", account);
	.wait(account(Vaga1Id));

	velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga2;tipo:Longa", "status:disponivel", account);
	.wait(account(Vaga2Id));

	velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga3;tipo:Longa", "status:disponivel", account);
	.wait(account(Vaga3Id));

	velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga4;tipo:CurtaCoberta", "status:disponivel", account);
	.wait(account(Vaga4Id));

	velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga5;tipo:LongaCoberta", "status:disponivel", account);
	.wait(account(Vaga5Id));

	Lista = [Vaga1Id, Vaga2Id, Vaga3Id, Vaga4Id, Vaga5Id];
	-+listaVagas(Lista).

-!listarVagas <-
	.print("Nao foi possivel listar as vagas").

+!findToken(Term,set([Head|Tail])) <- 
    !compare(Term,Head,set(Tail));
    !findToken(Term,set(Tail)).

+!compare(Term,[Type,AssetId, Qtd],set(V)): (Term  == Type) | (Term == AssetId) <-
	.print("Vaga: ", AssetId);
	+vaga(AssetId).

-!compare(Term,[Type,AssetId,Qtd],set(V)) <- .print("The Asset ",AssetId, " is not a ",Term).

-!findToken(Type,set([   ])): not vaga(Vaga) <- 
	.print("Lista de vagas nao encontrada");
	!listarVagas.

-!findToken(Type,set([   ])): vaga(Vaga) <- 
	.print("Vagas ja cadastradas").

