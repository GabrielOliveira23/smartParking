{ include("$jacamo/templates/common-cartago.asl") }
{ include("$jacamo/templates/common-moise.asl") }

/* Initial beliefs */
+listaVagas([ ]).

/* Initial goals */
!criarCarteira.

/* plans */

// ----------------------------- COMMONS ------------------------------
+!consultarVaga(TipoVaga, Data)[source(DriverAgent)]: listaVagas(Lista) <-
	.print("Motorista: ", DriverAgent, " Consultando vaga: ", TipoVaga);
	.send(DriverAgent, askOne, driverWallet(DriverW), Reply);
	incrementarContadorMensagens;
	.wait(3000);
	+Reply;
	!disponibilidadeCompra(TipoVaga, Data, set(Lista));
	?vagaDisponivel(Status, Id);
	.send(DriverAgent, achieve, vagaDisponivel(Status, Id));
	incrementarContadorMensagens;
	.send(DriverAgent, tell, idVaga(Head));
	incrementarContadorMensagens;
	.abolish(vagaDisponivel(_,_)).

+!consultarVaga(TipoVaga, Data)[source(DriverAgent)] : not listaVagas(Lista) <-
	.print("Estacionamento fechado!").

-!consultarVaga(TipoVaga, Data)[source(DriverAgent)] : vagaDisponivel(Status, Id) <-
	.print("Vaga nao encontrada");
	.send(DriverAgent, achieve, vagaDisponivel(Status, Id));
	incrementarContadorMensagens.

+!disponibilidadeCompra(TipoVaga, Data, set([Head|Tail])): chainServer(Server) <-
	.velluscinum.tokenInfo(Server, Head, all, content);
	incrementarContadorTransacoes;
	.wait(content(Metadata));
	verificarCompra(TipoVaga, Metadata, Status);
	.abolish(content(_));

	if (Status == true) {
		+vagaDisponivel(true, Head);
	} else {
		.fail;
	}.

-!disponibilidadeCompra(TipoVaga, Data, set([Head|Tail])): chainServer(Server) <-
	!disponibilidadeCompra(TipoVaga, Data, set(Tail)).

-!disponibilidadeCompra(TipoVaga, Data, set([ ])) <-
	+vagaDisponivel(false, 0);
	.print("percorreu todas as vagas").

// -------------------------- COMPRA DIRETA ---------------------------

+!motoristaQuerEstacionar(Id)[source(DriverAgent)] <- 
	!ocuparVaga(Id);
	?vagaOcupada(Id);
	.print(DriverAgent, " => pode estacionar");
	.send(DriverAgent, tell, vagaOcupada(Id));
	incrementarContadorMensagens;
	.abolish(vagaOcupada(_)).

-!motoristaQuerEstacionar(Id)[source(DriverAgent)] <-
	.print("Vaga nao ocupada").

+!pagamentoUsoVaga(Tipo, Minutos)[source(DriverAgent)] : driverWallet(DriverW) <-
	.print("Tipo: ", Tipo);
	calcularValorAPagarUso(Tipo, Minutos, Valor);
	.print(DriverAgent, " => valor a pagar: ", Valor);
	.send(DriverAgent, tell, valorAPagarUso(Valor));
	incrementarContadorMensagens.

// -------------------------- COMPRAR RESERVA -------------------------

+!consultarReserva(TipoVaga, Data, Tempo)[source(DriverAgent)] : listaVagas(Lista) & not consultandoReserva(_,_,_,_) <- 
    .print(DriverAgent, " quer consultar reserva");
    +consultandoReserva(DriverAgent, TipoVaga, Data, Tempo);
    .send(DriverAgent, askOne, driverWallet(DriverW), Reply);
	incrementarContadorMensagens;
    .wait(3000);
    +Reply;
    !disponibilidadeReserva(TipoVaga, Data, Tempo, set(Lista));
	?reservaDisponivel(Status);
    if (Status == true) {
        .print("Reserva disponível");
        ?idReserva(Id);
		incrementarContadorMensagens;
        .send(DriverAgent, achieve, vagaDisponivel(true, Id));
		incrementarContadorMensagens;
    } else {
		.print("Reserva nao disponivel");
        .send(DriverAgent, achieve, vagaDisponivel(false, 0));
		incrementarContadorMensagens;
    };
    .abolish(reservaDisponivel(_));
    .abolish(vagaDisponivel(_,_));
    .abolish(consultandoReserva(_,_,_,_));
    !processarProximaConsulta.

+!consultarReserva(TipoVaga, Data, Tempo)[source(DriverAgent)] : consultandoReserva(_, _, _, _) <- 
    .print(DriverAgent, " quer consultar. Adicionando à fila de pendências.");
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
	incrementarContadorTransacoes;
	.wait(content(Content));
	.abolish(vagaDisponivel(_,_));
	.abolish(reservaDisponivel(_));
	
	verificarReserva(Head, TipoVaga, Data, Tempo, Content);
	?reservaDisponivel(Status);
	.abolish(content(_));
	if (Status == true) {
		.print("Vaga encontrada para reserva -> ", Head);
		+idReserva(Head);
	} else {
		!disponibilidadeReserva(TipoVaga, Data, Tempo, set(Tail));
	}.

-!disponibilidadeReserva: not vagaDisponivel(Status, Id) <-
	.print("sem vaga disponivel!").

-!disponibilidadeReserva(TipoVaga, Data, Tempo, set([Head|Tail])): chainServer(Server) <-
	!disponibilidadeReserva(TipoVaga, Data, Tempo, set(Tail)).

-!disponibilidadeReserva(TipoVaga, Data, Tempo, set([ ])) <-
	+reservaDisponivel(false);
	.print("percorreu todas as vagas").

+!motoristaPagouReserva(TransactionId, IdVaga, Data, Tempo)[source(DriverAgent)] <-
	!stampProcess(TransactionId);
	!criarReservaNFT(IdVaga, Data, Tempo, DriverAgent);
	.abolish(reservaNFT(_)).

-!motoristaPagouReserva(TransactionId, IdVaga, Data, Tempo)[source(DriverAgent)] <-
	.print("Reserva nao gerada").

+!criarReservaNFT(IdVaga, Data, Tempo, DriverAgent)[source(self)] : chainServer(Server) & myWallet(PrK, PuK) 
				& driverWallet(DriverW)[source(Agente)] & Agente = DriverAgent  <-
	.velluscinum.tokenInfo(Server, IdVaga, data, content);
	incrementarContadorTransacoes;
	.wait(content(Content));

	getVacancyInfo(Content);
	?tipoVaga(TipoAtual);
	?statusVaga(StatusAtual);
	.abolish(content(_));

	.concat("description:vacancy reservation;type:", TipoAtual, ";date:", Data, ";duration:", Tempo, Dados);
	.concat("description:vacancy reservation;type:", Descricao);
	.velluscinum.deployNFT(Server, PrK, PuK, Dados, Descricao, nft);
	incrementarContadorTransacoes;
	.wait(nft(ReservaId));

	!ocuparVaga(IdVaga, Data, Tempo, StatusAtual, ReservaId);
	?ocupacao(IdOcupacao);

	.print("Enviando reserva: ", ReservaId, " para: ", DriverAgent);

	.concat("reservation:", ReservaId, ";type:", TipoAtual, ";date:", Data, ";time:", Tempo, DescricaoReserva);
	.velluscinum.transferNFT(Server, PrK, PuK, ReservaId, DriverW, DescricaoReserva, transfer);
	incrementarContadorTransacoes;
	.wait(transfer(TransferId));

	.send(DriverAgent, tell, reservaNFT(ReservaId, TransferId));
	incrementarContadorMensagens;
	.abolish(nft(_));
	.abolish(transfer(_));
	
	.abolish(tipoVaga(_));
	.abolish(statusVaga(_)).

+!criarReservaNFT(IdVaga, Data, Tempo, DriverAgent)[source(self)] : not driverWallet(DriverW)[source(DriverAgent)] <-
	.send(driver, askOne, driverWallet(DriverW), Reply);
	incrementarContadorMensagens;
	.wait(3000);
	+Reply;
	!criarReservaNFT(IdVaga, Data, Tempo, DriverAgent).

-!criarReservaNFT(IdVaga, Data, Tempo, DriverAgent)[source(self)] <-
	.print("Nao foi possivel reservar a vaga").

+!ocuparVaga(IdVaga, Data, Tempo, Status, ReservaId) : chainServer(Server) & myWallet(PrK, PuK) <-
	// .print("Ocupando Vaga: ", IdVaga);
	.velluscinum.tokenInfo(Server, IdVaga, metadata, content);
	incrementarContadorTransacoes;
	.wait(content(Registrado));

	// .print("Registrado: ", Registrado);

	registrarReserva(Registrado, Status, ReservaId, Data, Tempo);
	?reservation(Metadados);
	.abolish(content(_));

	// .print("Metadados: ", Metadados);
	
	.velluscinum.transferNFT(Server, PrK, PuK, IdVaga, PuK, Metadados, ocupacao);
	incrementarContadorTransacoes;
	.wait(ocupacao(IdOcupacao));
	
	.abolish(reservation(_));

	.print("Vaga ocupada com sucesso!").

// -------------------------- USO DA RESERVA --------------------------

+!motoristaQuerUsarReserva(ReservaId, TransactionId)[source(DriverAgent)] <-
	!stampProcess(TransactionId);
	!validarReserva(ReservaId);
	?reservaEncontrada(VagaId);
	.send(DriverAgent,achieve,estacionarReserva(VagaId));
	incrementarContadorMensagens;
	.abolish(reservaEncontrada(_)).

-!motoristaQuerUsarReserva(ReservaId, TransactionId)[source(DriverAgent)] <-
	.print("Reserva nao encontrada").

+!motoristaQuerSair(VagaId)[source(DriverAgent)] <-
	!liberarVaga(VagaId);
	?vagaLiberada;
	.send(DriverAgent, achieve, sairEstacionamento);
	incrementarContadorMensagens.

-!motoristaQuerSair(VagaId) <- .print("Vaga nao liberada").

+!validarReserva(ReservaId) : listaVagas(Lista) <-
	.print("Validando reserva: ", ReservaId);
	!percorrerListaVagas(ReservaId, set(Lista));
	?reservaEncontrada(VagaId);
	!ocuparVaga.

-!validarReserva(ReservaId) <- .print("Reserva nao encontrada").
	
+!percorrerListaVagas(ReservaId, set([Head|Tail])) : not reservaEncontrada(VagaId) <-
    !analisarVaga(ReservaId, Head, set(Tail));
    !percorrerListaVagas(ReservaId, set(Tail)).

+!percorrerListaVagas(ReservaId, set([Head|Tail])) : reservaEncontrada(VagaId) <-
	.print("Reserva encontrada").

-!percorrerListaVagas(Type, set([ ])).

+!analisarVaga(ReservaId, VagaId, set(V)): chainServer(Server) <-
	.print("Analisando vaga: ", VagaId);
	.print("Reserva: ", ReservaId);
	.velluscinum.tokenInfo(Server, VagaId, metadata, dadosVaga);
	incrementarContadorTransacoes;
	.wait(dadosVaga(Dados));
	acharReserva(ReservaId, VagaId, Dados);
	.abolish(dadosVaga(_)).

-!analisarVaga(ReservaId, VagaId, set(V)).

// ---------------------------- AUXILIARES ----------------------------

+!validarPagamento(Transfer, IdVaga)[source(DriverAgent)] <-
	!stampProcess(Transfer);
	.print(DriverAgent, " => pagamento validado!");
	!liberarVaga(IdVaga);
	?vagaLiberada;
	.print(DriverAgent, " => vaga liberada!");
	.send(DriverAgent, achieve, sairEstacionamento);
	incrementarContadorMensagens.

-!validarPagamento(Transfer, IdVaga)[source(DriverAgent)] <-
	.print(DriverAgent, " => vaga nao liberada").

+!stampProcess(Transfer)[source(self)] : chainServer(Server) 
            & myWallet(PrK,PuK) <-
	.velluscinum.stampTransaction(Server,PrK,PuK,Transfer);
	incrementarContadorTransacoes.

+!ocuparVaga(Id): chainServer(Server) & myWallet(PrK, PuK) <-
	.velluscinum.transferNFT(Server, PrK, PuK, Id, PuK, "status:ocupado", requestID);
	incrementarContadorTransacoes;
	.wait(requestID(TransferId));
	+vagaOcupada(Id).

+!ocuparVaga : chainServer(Server) & myWallet(PrK, PuK) & reservaEncontrada(VagaId) <-
	.velluscinum.transferNFT(Server, PrK, PuK, VagaId, PuK, "status:ocupado", requestID);
	incrementarContadorTransacoes;
	.wait(requestID(TransferId));
	.print("Vaga Ocupada").

+!liberarVaga(Id): chainServer(Server) & myWallet(PrK,PuK) <-
	// verificar se a reserva ainda existe se a vaga for liberada
	.velluscinum.transferNFT(Server, PrK, PuK, Id, PuK, "status:disponivel", requestID);
	incrementarContadorTransacoes;
	.wait(requestID(TransferId));
	+vagaLiberada.

// -------------------------- ANTES DE ABRIR --------------------------

+vaga(Vaga): listaVagas(Lista) & not .empty(Lista) <- 
	-+listaVagas([Vaga|Lista]).

+vaga(Vaga) <- -+listaVagas([Vaga]).

+!criarCarteira <-
	.print("Obtendo carteira digital!");
	.velluscinum.loadWallet(myWallet);
	incrementarContadorTransacoes;
	.wait(myWallet(PrK,PuK));
	+managerWallet(PuK);
	.wait(5000);
	!verificarListaVagas.

+!verificarListaVagas: chainServer(Server) & myWallet(PrK,PuK) <-
	.print("Verificando lista de vagas...");
	.velluscinum.walletContent(Server, PrK, PuK, content);
	incrementarContadorTransacoes;
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
	incrementarContadorTransacoes;
	.wait(account(Vaga1Id));

	.velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga2;tipo:Longa", "status:disponivel", account);
	incrementarContadorTransacoes;
	.wait(account(Vaga2Id));

	.velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga3;tipo:Longa", "status:disponivel", account);
	incrementarContadorTransacoes;
	.wait(account(Vaga3Id));

	.velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga4;tipo:CurtaCoberta", "status:disponivel", account);
	incrementarContadorTransacoes;
	.wait(account(Vaga4Id));

	.velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga5;tipo:LongaCoberta", "status:disponivel", account);
	incrementarContadorTransacoes;
	.wait(account(Vaga5Id));

	Lista = [Vaga1Id, Vaga2Id, Vaga3Id, Vaga4Id, Vaga5Id];
	-+listaVagas(Lista).

-!listarVagas <- .print("Nao foi possivel listar as vagas").

+!findToken(Term,set([Head|Tail])) <- 
    !compare(Term,Head,set(Tail));
    !findToken(Term,set(Tail)).

+!compare(Term,[Type,AssetId, Qtd],set(V)): (Term  == Type) | (Term == AssetId) <-
	+vaga(AssetId).

-!compare(Term,[Type,AssetId,Qtd],set(V)).

-!findToken(Type,set([   ])): not vaga(Vaga) <- 
	.print("Lista de vagas nao encontrada");
	!listarVagas.

-!findToken(Type,set([   ])): vaga(Vaga) <- 
	.print("Vagas ja cadastradas").

