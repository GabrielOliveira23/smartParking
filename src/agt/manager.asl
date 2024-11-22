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
	incrementarContadorMensagens; // counter
	.wait(3000);
	+Reply;
	!disponibilidadeCompra(TipoVaga, Data, set(Lista));
	?vagaDisponivel(Status);
	?idVaga(Head);
	.send(DriverAgent, achieve, vagaDisponivel(Status));
	incrementarContadorMensagens; // counter
	.send(DriverAgent, tell, idVaga(Head));
	incrementarContadorMensagens; // counter
	.abolish(vagaDisponivel(_));
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
	} else {
		.fail;
	}.

	// ?vagaDisponivel(Status).

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
	incrementarContadorMensagens; // counter
	.abolish(querEstacionar(_));
	.abolish(vagaOcupada(_)).

-querEstacionar(Id)[source(DriverAgent)] <-
	.print("Vaga nao ocupada").

+!pagamentoUsoVaga(Tipo, Minutos)[source(DriverAgent)] : driverWallet(DriverW) <-
	// .print("Calculando valor...");
	calcularValorAPagarUso(Tipo, Minutos, Valor);
	.print(DriverAgent, " => valor a pagar: ", Valor);
	.send(DriverAgent, tell, valorAPagarUso(Valor));
	incrementarContadorMensagens. // counter

// -------------------------- COMPRAR RESERVA -------------------------

+!consultarReserva(TipoVaga, Data, Tempo)[source(DriverAgent)] : listaVagas(Lista) & not consultandoReserva(_,_,_,_) <- 
    .print(DriverAgent, " quer consultar reserva");
    +consultandoReserva(DriverAgent, TipoVaga, Data, Tempo);
    .send(DriverAgent, askOne, driverWallet(DriverW), Reply);
	incrementarContadorMensagens; // counter
    .wait(3000);
    +Reply;
    !disponibilidadeReserva(TipoVaga, Data, Tempo, set(Lista));
	?reservaDisponivel(Status);
    if (Status == true) {
        .print("Reserva disponível");
        ?idReserva(Id);
        .send(DriverAgent, tell, idVaga(Id));
		incrementarContadorMensagens; // counter
        .send(DriverAgent, achieve, vagaDisponivel(true));
		incrementarContadorMensagens; // counter
    } else {
		.print("Reserva nao disponivel");
        .send(DriverAgent, achieve, vagaDisponivel(false));
		incrementarContadorMensagens; // counter
    };
    .abolish(reservaDisponivel(_));
    .abolish(vagaDisponivel(_));
    .abolish(consultandoReserva(_,_,_,_));
    !processarProximaConsulta.

+!consultarReserva(TipoVaga, Data, Tempo)[source(DriverAgent)] : consultandoReserva(_, _, _, _) <- 
    .print(DriverAgent, " quer consultar, mas uma consulta já está em andamento. Adicionando à fila de pendências.");
    ?consultasPendentes(Pendentes);
    .abolish(consultasPendentes(_));
    +consultasPendentes([[DriverAgent, TipoVaga, Data, Tempo] | Pendentes]).

-!consultarReserva(TipoVaga, Data, Tempo)[source(DriverAgent)] : consultandoReserva(_, _, _, _) <-
	+consultasPendentes([[DriverAgent, TipoVaga, Data, Tempo]]).

+!processarProximaConsulta : true <- 
    ?consultasPendentes([ProximaConsulta | Restantes]);
	-+consultasPendentes(Restantes);
    ProximaConsulta = [DriverAgent, TipoVaga, Data, Tempo];
    !consultarReserva(TipoVaga, Data, Tempo)[source(DriverAgent)]. 

-!processarProximaConsulta.

+!disponibilidadeReserva(TipoVaga, Data, Tempo, set([Head|Tail])): chainServer(Server) <-
	.print("Verificando disponibilidade de reserva vaga: ", Head);
	.velluscinum.tokenInfo(Server, Head, all, content);
	.wait(content(Content));
	.abolish(vagaDisponivel(_));
	.abolish(reservaDisponivel(_));
	
	// .print("Content: ", Content);
	verificarReserva(Head, TipoVaga, Data, Tempo, Content);
	?reservaDisponivel(Status);
	.abolish(content(_));
	.print("reservaDisponivel: ", Status);
	if (Status == true) {
		.print("Vaga encontrada para reserva -> ", Head);
		+idReserva(Head);
	} else {
		!disponibilidadeReserva(TipoVaga, Data, Tempo, set(Tail));
	}.

-!disponibilidadeReserva: not vagaDisponivel(Status) <-
	.print("sem vaga disponivel!").

-!disponibilidadeReserva(TipoVaga, Data, Tempo, set([Head|Tail])): chainServer(Server) <-
	!disponibilidadeReserva(TipoVaga, Data, Tempo, set(Tail)).

-!disponibilidadeReserva(TipoVaga, Data, Tempo, set([ ])) <-
	+reservaDisponivel(false);
	.print("percorreu todas as vagas").

+pagouReserva(TransactionId, IdVaga, Data, Tempo)[source(DriverAgent)] <-
	!stampProcess(TransactionId);
	!criarReservaNFT(IdVaga, Data, Tempo, DriverAgent);
	.abolish(pagouReserva(_));
	.abolish(reservaNFT(_)).

-pagouReserva(TransactionId, IdVaga, Data, Tempo)[source(DriverAgent)] <-
	.print("Reserva nao gerada").

+!criarReservaNFT(IdVaga, Data, Tempo, DriverAgent)[source(self)] : chainServer(Server) & myWallet(PrK, PuK) 
				& driverWallet(DriverW)[source(Agente)] & Agente = DriverAgent  <-
	.velluscinum.tokenInfo(Server, IdVaga, data, content);
	.wait(content(Content));

	getVacancyInfo(Content);
	?tipoVaga(TipoAtual);
	?statusVaga(StatusAtual);
	.abolish(content(_));

	.concat("description:vacancy reservation;type:", TipoAtual, ";date:", Data, ";duration:", Tempo, Dados);
	.concat("description:vacancy reservation;type:", Descricao);
	.velluscinum.deployNFT(Server, PrK, PuK, Dados, Descricao, nft);
	.wait(nft(ReservaId));

	!ocuparVaga(IdVaga, Data, Tempo, StatusAtual, ReservaId);
	?ocupacao(IdOcupacao);

	.print("Enviando reserva: ", ReservaId, " para: ", DriverAgent);
	.print("Carteira: ", DriverW);

	.concat("reservation:", ReservaId, ";type:", TipoAtual, ";date:", Data, ";time:", Tempo, DescricaoReserva);
	.velluscinum.transferNFT(Server, PrK, PuK, ReservaId, DriverW, DescricaoReserva, transfer);
	.wait(transfer(TransferId));

	// +reservaNFT(ReservaId, TransferId);
	.print("mandando para o motorista: ", DriverAgent);
	.send(DriverAgent, tell, reservaNFT(ReservaId, TransferId));
	incrementarContadorMensagens; // counter
	.abolish(nft(_));
	.abolish(transfer(_));
	
	.abolish(tipoVaga(_));
	.abolish(statusVaga(_)).

+!criarReservaNFT(IdVaga, Data, Tempo, DriverAgent)[source(self)] : not driverWallet(DriverW)[source(DriverAgent)] <-
	.send(driver, askOne, driverWallet(DriverW), Reply);
	incrementarContadorMensagens; // counter
	.wait(3000);
	+Reply;
	!criarReservaNFT(IdVaga, Data, Tempo, DriverAgent).

-!criarReservaNFT(IdVaga, Data, Tempo, DriverAgent)[source(self)] <-
	.print("Nao foi possivel reservar a vaga").

+!ocuparVaga(IdVaga, Data, Tempo, Status, ReservaId) : chainServer(Server) & myWallet(PrK, PuK) <-
	// .print("Ocupando Vaga: ", IdVaga);
	.velluscinum.tokenInfo(Server, IdVaga, metadata, content);
	.wait(content(Registrado));

	// .print("Registrado: ", Registrado);

	registrarReserva(Registrado, Status, ReservaId, Data, Tempo);
	?reservation(Metadados);
	.abolish(content(_));

	// .print("Metadados: ", Metadados);
	
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
	incrementarContadorMensagens; // counter
	.abolish(reservaEncontrada(_));
	.abolish(querUsarReserva(_)).

-querUsarReserva(ReservaId, TransactionId)[source(DriverAgent)] <-
	.print("Reserva nao encontrada").

+querSair(VagaId)[source(DriverAgent)] <-
	// .print("Liberando vaga motorista...");
	!liberarVaga(VagaId);
	?vagaLiberada;
	.send(DriverAgent, achieve, sairEstacionamento);
	incrementarContadorMensagens. // counter

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

// ---------------------------- AUXILIARES ----------------------------

// fazer metodo para quando nao for validado o stamp
+!validarPagamento(Transfer, IdVaga)[source(DriverAgent)] <-
	!stampProcess(Transfer);
	.print(DriverAgent, " => pagamento validado!");
	!liberarVaga(IdVaga);
	?vagaLiberada;
	.print(DriverAgent, " => vaga liberada!");
	.send(DriverAgent, achieve, sairEstacionamento);
	incrementarContadorMensagens. // counter

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
	.abolish(content(_));
	!abrirEstacionamento.

+!verificarListaVagas: not chainServer(Server) <-
	.wait(5000);
	!verificarListaVagas.

+!abrirEstacionamento : listaVagas(Vagas) <-
	.print("Estacionamento Aberto!");
	.broadcast(tell, estacionamentoAberto);
	.broadcast(tell, precoTabelaVagas([
					["Curta", 10],
					["Longa", 14],
					["CurtaCoberta", 18],
					["LongaCoberta", 20]
					])).

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

-!compare(Term,[Type,AssetId,Qtd],set(V)).
// <- .print("The Asset ",AssetId, " is not a ",Term).

-!findToken(Type,set([   ])): not vaga(Vaga) <- 
	.print("Lista de vagas nao encontrada");
	!listarVagas.

-!findToken(Type,set([   ])): vaga(Vaga) <- 
	.print("Vagas ja cadastradas").

