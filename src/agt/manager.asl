{ include("$jacamo/templates/common-cartago.asl") }
{ include("$jacamo/templates/common-moise.asl") }

/* Initial beliefs */
mensagensEnviadas(0).

/* Initial goals */
!criarCarteira.

/* plans */

// ----------------------------- COMMONS ------------------------------
+!incMensagensEnviadas : mensagensEnviadas(Num) <-
    -+mensagensEnviadas(Num+1).
	
+!consultarVaga(TipoVaga)[source(DriverAgent)]: listaVagas(Lista) & not consultandoVaga(_,_) <- 
    .print("Motorista: ", DriverAgent, " Consultando vaga: ", TipoVaga);
    +consultandoVaga(DriverAgent, TipoVaga);
    .send(DriverAgent, askOne, driverWallet(DriverW), Reply);
    !incMensagensEnviadas;
    .wait(3000);
    +Reply;
    !disponibilidadeCompra(TipoVaga, set(Lista));
    ?vagaDisponivel(Status, Id);
    .send(DriverAgent, achieve, vagaDisponivel(Status, Id));
    !incMensagensEnviadas;
    .send(DriverAgent, tell, idVaga(Id));
    !incMensagensEnviadas;
    .abolish(vagaDisponivel(Status, Id));
    .abolish(consultandoVaga(DriverAgent, TipoVaga));
    !processarProximaConsultaVaga.

+!consultarVaga(TipoVaga)[source(DriverAgent)] : not listaVagas(Lista) <-
	.print("Estacionamento fechado!").

-!consultarVaga(TipoVaga)[source(DriverAgent)] : vagaDisponivel(Status, Id) <-
	.print("Vaga nao encontrada");
	.send(DriverAgent, achieve, vagaDisponivel(Status, Id));
	!incMensagensEnviadas.

+!consultarVaga(TipoVaga)[source(DriverAgent)] : consultandoVaga(_,_) <- 
    // .print("Motorista: ", DriverAgent, " quer consultar vaga, mas uma consulta já está em andamento. Adicionando à fila de pendências.");
    ?consultasPendentesVaga(Pendentes);
    .abolish(consultasPendentesVaga(Pendentes));
    +consultasPendentesVaga([[DriverAgent, TipoVaga] | Pendentes]).

-!consultarVaga(TipoVaga)[source(DriverAgent)] : consultandoVaga(_,_) <- 
    +consultasPendentesVaga([DriverAgent, TipoVaga]).

+!processarProximaConsultaVaga <- 
    ?consultasPendentesVaga([ProximaConsulta | Restantes]);
    -consultasPendentesVaga([ProximaConsulta | Restantes]);
    +consultasPendentesVaga(Restantes);
    ProximaConsulta = [DriverAgent, TipoVaga];
    !consultarVaga(TipoVaga)[source(DriverAgent)].

-!processarProximaConsultaVaga.

+!disponibilidadeCompra(TipoVaga, set([Head|Tail])): chainServer(Server) <-
    // .print("Verificando disponibilidade de compra de vaga: ", Head);
    .velluscinum.tokenInfo(Server, Head, all, content);
	incContadorTransacoesVellus;
    .wait(content(Content));
    .abolish(vagaDisponivel(_));
	verificarCompra(TipoVaga, Content, Status);
	.abolish(content(_));

	if (Status == true) {
		+vagaDisponivel(true, Head);
	} else {
		!disponibilidadeCompra(TipoVaga, set(Tail));
	}.

-!disponibilidadeCompra(TipoVaga, Data, set([ ])) <-
	+vagaDisponivel(false, 0);
	.print("percorreu todas as vagas").

// -------------------------- COMPRA DIRETA ---------------------------

+!motoristaQuerEstacionar(Id)[source(DriverAgent)] <- 
	!ocuparVaga(Id);
	.print(DriverAgent, " => pode estacionar");
	.send(DriverAgent, tell, vagaOcupada(Id));
	!incMensagensEnviadas.

-!motoristaQuerEstacionar(Id)[source(DriverAgent)] <-
	.print("Vaga nao ocupada").

+!pagamentoUsoVaga(Tipo, Minutos)[source(DriverAgent)] : driverWallet(DriverW) <-
	.print("Tipo: ", Tipo);
	calcularValorAPagarUso(Tipo, Minutos, Valor);
	.print(DriverAgent, " => valor a pagar: ", Valor);
	.send(DriverAgent, tell, valorAPagarUso(Valor));
	!incMensagensEnviadas.

// -------------------------- COMPRAR RESERVA -------------------------

+!consultarReserva(TipoVaga, Data, Tempo)[source(DriverAgent)] : listaVagas(Lista) & not consultandoReserva(_,_,_,_) <- 
    .print(DriverAgent, " quer consultar reserva");
    +consultandoReserva(DriverAgent, TipoVaga, Data, Tempo);
    .send(DriverAgent, askOne, driverWallet(DriverW), Reply);
	!incMensagensEnviadas;
    .wait(3000);
    +Reply;
    !disponibilidadeReserva(TipoVaga, Data, Tempo, set(Lista));
	?reservaDisponivel(Status);
    if (Status == true) {
        .print("Reserva disponível");
        ?idReserva(Id);
        .send(DriverAgent, achieve, vagaDisponivel(true, Id));
		!incMensagensEnviadas;
		.abolish(idReserva(_));
    } else {
		.print("Reserva nao disponivel");
        .send(DriverAgent, achieve, vagaDisponivel(false, 0));
		!incMensagensEnviadas;
    };
    -reservaDisponivel(Status);
    .abolish(consultandoReserva(_,_,_,_));
	.print("Prosseguindo para a proxima consulta de reserva");
    !processarProximaConsultaReserva.

+!consultarReserva(TipoVaga, Data, Tempo)[source(DriverAgent)] : consultandoReserva(_, _, _, _) <- 
    .print(DriverAgent, " Adicionado à fila de consultas Reserva.");
    ?consultasPendentes(Pendentes);
	.length(Pendentes, Tamanho);
	if (Tamanho > 15) {
		.print("Fila de consultas Reserva cheia.");
		.send(DriverAgent, achieve, vagaDisponivel(false, 0));
		!incMensagensEnviadas;
	} else {
		// .print("fila: ", Pendentes);
		// .print("adicionado: ", [DriverAgent, TipoVaga, Data, Tempo]);
		.abolish(consultasPendentes(_));
		+consultasPendentes([[DriverAgent, TipoVaga, Data, Tempo] | Pendentes]);
	}.

-!consultarReserva(TipoVaga, Data, Tempo)[source(DriverAgent)] : consultandoReserva(_, _, _, _) <-
	.print("adicionado: ", [DriverAgent, TipoVaga, Data, Tempo]);
	+consultasPendentes([[DriverAgent, TipoVaga, Data, Tempo]]).

+!processarProximaConsultaReserva <-
    ?consultasPendentes([ProximaConsulta | Restantes]);
	.length(Restantes, Tamanho);
	if (Tamanho == 0) {
		.abolish(consultasPendentes(_));
	} else {
		-+consultasPendentes(Restantes);
		// .print("Ainda tem na fila: ", Restantes);
	};
    ProximaConsulta = [DriverAgent, TipoVaga, Data, Tempo];
	.print("Proxima consulta: ", ProximaConsulta);
    !consultarReserva(TipoVaga, Data, Tempo)[source(DriverAgent)]. 

-!processarProximaConsultaReserva : not consultasPendentes <-
	.print("Nao ha consultas pendentes").

-!processarProximaConsultaReserva <- .print("Erro desconhecido").

+!disponibilidadeReserva(TipoVaga, Data, Tempo, set([Head|Tail])): chainServer(Server) <-
	// .print("Verificando disponibilidade de reserva vaga: ", Head);
	.velluscinum.tokenInfo(Server, Head, all, content);
	incContadorTransacoesVellus;
	.wait(content(Content));
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
	incContadorTransacoesVellus;
	.wait(content(Content));

	getVacancyInfo(Content);
	?tipoVaga(TipoAtual);
	?statusVaga(StatusAtual);
	.abolish(content(_));

	.concat("idVaga:", IdVaga, ";descricao:reserva de vaga;tipo:", TipoAtual, ";data:", Data, ";duracao:", Tempo, Dados);
	.concat("descricao:reserva de vaga;tipo:", Descricao);
	.velluscinum.deployNFT(Server, PrK, PuK, Dados, Descricao, nft);
	incContadorTransacoesVellus;
	.wait(nft(ReservaId));

	!ocuparVaga(IdVaga, Data, Tempo, StatusAtual, ReservaId);
	?ocupacao(IdOcupacao);

	.print("Enviando reserva: ", ReservaId, " para: ", DriverAgent);

	.concat("reservaId:", ReservaId, ";tipo:", TipoAtual, ";data:", Data, ";duracao:", Tempo, DescricaoReserva);
	.velluscinum.transferNFT(Server, PrK, PuK, ReservaId, DriverW, DescricaoReserva, transfer);
	incContadorTransacoesVellus;
	.wait(transfer(TransferId));

	.send(DriverAgent, tell, reservaNFT(ReservaId, TransferId));
	!incMensagensEnviadas;
	.abolish(nft(_));
	.abolish(transfer(_));
	
	.abolish(tipoVaga(_));
	.abolish(statusVaga(_)).

+!criarReservaNFT(IdVaga, Data, Tempo, DriverAgent)[source(self)] : not driverWallet(DriverW)[source(DriverAgent)] <-
	.send(driver, askOne, driverWallet(DriverW), Reply);
	!incMensagensEnviadas;
	.wait(3000);
	+Reply;
	!criarReservaNFT(IdVaga, Data, Tempo, DriverAgent).

-!criarReservaNFT(IdVaga, Data, Tempo, DriverAgent)[source(self)] <-
	.print("Nao foi possivel reservar a vaga").

+!ocuparVaga(IdVaga, Data, Tempo, Status, ReservaId) : chainServer(Server) & myWallet(PrK, PuK) <-
	// .print("Ocupando Vaga: ", IdVaga);
	.velluscinum.tokenInfo(Server, IdVaga, metadata, content);
	incContadorTransacoesVellus;
	.wait(content(Registrado));

	// .print("Registrado: ", Registrado);

	registrarReserva(Registrado, Status, ReservaId, Data, Tempo);
	?reservation(Metadados);
	.abolish(content(_));

	// .print("Metadados: ", Metadados);
	
	.velluscinum.transferNFT(Server, PrK, PuK, IdVaga, PuK, Metadados, ocupacao);
	incContadorTransacoesVellus;
	.wait(ocupacao(IdOcupacao));
	
	.abolish(reservation(_));

	.print("Vaga ocupada com sucesso!").

// -------------------------- USO DA RESERVA --------------------------

+!motoristaQuerUsarReserva(ReservaId, TransactionId)[source(DriverAgent)] <-
	!stampProcess(TransactionId);
	!validarReserva(ReservaId);
	?reservaEncontrada(VagaId);
	.send(DriverAgent,achieve,estacionarReserva(VagaId));
	!incMensagensEnviadas;
	.abolish(reservaEncontrada(_)).

-!motoristaQuerUsarReserva(ReservaId, TransactionId)[source(DriverAgent)] <-
	.print("Reserva nao encontrada").

+!motoristaQuerSair(VagaId)[source(DriverAgent)] <-
	!liberarVaga(VagaId);
	.send(DriverAgent, achieve, sairEstacionamento);
	!incMensagensEnviadas.

-!motoristaQuerSair(VagaId) <- .print("Vaga nao liberada").

+!validarReserva(ReservaId) : listaVagas(Lista) <-
	.print("Validando reserva: ", ReservaId);
	!percorrerListaVagas(ReservaId, set(Lista)).

-!validarReserva(ReservaId) <- .print("Reserva nao encontrada").

+!percorrerListaVagas(ReservaId, set([Head|Tail])) : not reservaEncontrada(VagaId) <-
    !analisarVaga(ReservaId, Head, set(Tail));
    !percorrerListaVagas(ReservaId, set(Tail)).

+!percorrerListaVagas(ReservaId, set([Head|Tail])) : reservaEncontrada(VagaId) <-
	.print("Reserva encontrada").

-!percorrerListaVagas(Type, set([ ])).

+!analisarVaga(ReservaId, VagaId, set(V)): chainServer(Server) <-
	.print("Analisando vaga: ", VagaId);
	.velluscinum.tokenInfo(Server, VagaId, metadata, dadosVaga);
	incContadorTransacoesVellus;
	.wait(dadosVaga(Dados));
	acharReserva(ReservaId, VagaId, Dados);
	?novoRegistro(Registro);
	// .print("novo registro: ", Registro);
	!consumirReserva(VagaId, Registro);
	.abolish(novoRegistro(_));
	.abolish(dadosVaga(_)).

-!analisarVaga(ReservaId, VagaId, set(V)).

+!consumirReserva(VagaId, Registro) : chainServer(Server) & myWallet(PrK, PuK) <-
	.velluscinum.transferNFT(Server, PrK, PuK, VagaId, PuK, Registro, validation);
	incContadorTransacoesVellus;
	.wait(validation(TransferId));
	.abolish(validation(_));
	.print("Reserva consumida, Vaga Ocupada").

-!consumirReserva(VagaId, NovoRegistro) <-
	.print("Reserva nao consumida").

// ---------------------------- AUXILIARES ----------------------------

+!validarPagamento(Transfer, IdVaga)[source(DriverAgent)] <-
	!stampProcess(Transfer);
	.print(DriverAgent, " => pagamento validado! IdVaga: ", IdVaga);
	!liberarVaga(IdVaga);
	.print(DriverAgent, " => vaga liberada!");
	.send(DriverAgent, achieve, sairEstacionamento);
	!incMensagensEnviadas.

-!validarPagamento(Transfer, IdVaga)[source(DriverAgent)] <-
	.print(DriverAgent, " => vaga nao liberada").

+!stampProcess(Transfer)[source(self)] : chainServer(Server) 
            & myWallet(PrK,PuK) <-
	.velluscinum.stampTransaction(Server,PrK,PuK,Transfer);
	incContadorTransacoesVellus.

+!ocuparVaga(Id) : chainServer(Server) & myWallet(PrK, PuK) <-
	.print("Ocupando Vaga: ", Id);
	.velluscinum.transferNFT(Server, PrK, PuK, Id, PuK, "status:ocupado", requestID);
	incContadorTransacoesVellus;
	.wait(requestID(TransferId));
	.print("Vaga ocupada").

+!liberarVaga(Id) : chainServer(Server) & myWallet(PrK,PuK) <-
	.velluscinum.tokenInfo(Server, Id, metadata, content);
	incContadorTransacoesVellus;
	.wait(content(Content));
	preparandoLiberacao(Content, Registro);
	.print("Preparando liberacao: ", Registro);
	.velluscinum.transferNFT(Server, PrK, PuK, Id, PuK, Registro, requestID);
	incContadorTransacoesVellus;
	.wait(requestID(TransferId));
	.abolish(requestID(TransferId)).

-!liberarVaga(Id) <-
	.wait(5000);
	.print("Tentando novamente liberar: ", Id);
	!liberarVaga(Id).

// -------------------------- ANTES DE ABRIR --------------------------

+vaga(Vaga): listaVagas(Lista) & not .empty(Lista) <- 
	-+listaVagas([Vaga|Lista]).

+vaga(Vaga) <- -+listaVagas([Vaga]).

+!criarCarteira <-
	.print("Obtendo carteira digital!");
	.velluscinum.loadWallet(myWallet);
	incContadorTransacoesVellus;
	.wait(myWallet(PrK,PuK));
	+managerWallet(PuK);
	.wait(5000);
	!verificarListaVagas.

+!verificarListaVagas: chainServer(Server) & myWallet(PrK,PuK) <-
	.print("Verificando lista de vagas...");
	.velluscinum.walletContent(Server, PrK, PuK, content);
	incContadorTransacoesVellus;
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

// +!listarVagas: chainServer(Server) & myWallet(PrK,PuK) <- 
// 	.velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga1;tipo:Curta", "status:disponivel", account);
// 	incContadorTransacoesVellus;
// 	.wait(account(Vaga1Id));

// 	.velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga2;tipo:Longa", "status:disponivel", account);
// 	incContadorTransacoesVellus;
// 	.wait(account(Vaga2Id));

// 	.velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga3;tipo:Longa", "status:disponivel", account);
// 	incContadorTransacoesVellus;
// 	.wait(account(Vaga3Id));

// 	.velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga4;tipo:CurtaCoberta", "status:disponivel", account);
// 	incContadorTransacoesVellus;
// 	.wait(account(Vaga4Id));

// 	.velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga5;tipo:LongaCoberta", "status:disponivel", account);
// 	incContadorTransacoesVellus;
// 	.wait(account(Vaga5Id));

// 	Lista = [Vaga1Id, Vaga2Id, Vaga3Id, Vaga4Id, Vaga5Id];
// 	-+listaVagas(Lista).

// -!listarVagas <- .print("Nao foi possivel listar as vagas").

+!findToken(Term,set([Head|Tail])) <- 
    !compare(Term,Head,set(Tail));
    !findToken(Term,set(Tail)).

+!compare(Term,[Type,AssetId, Qtd],set(V)): (Term  == Type) | (Term == AssetId) <-
	+vaga(AssetId).

-!compare(Term,[Type,AssetId,Qtd],set(V)).

-!findToken(Type,set([   ])): not vaga(Vaga) <- 
	.print("Lista de vagas nao encontrada").
	// !listarVagas.

-!findToken(Type,set([   ])): vaga(Vaga) <- 
	.print("Vagas ja cadastradas").
