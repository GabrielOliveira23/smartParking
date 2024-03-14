{ include("$jacamo/templates/common-cartago.asl") }
{ include("$jacamo/templates/common-moise.asl") }

/* Initial beliefs */
+listaVagas([ ]).

/* Initial goals */
!criarCarteira.

/* plans */

// ----------------------------- COMMONS ------------------------------

+vagaDisponivel(Status) <- .send(driver, tell, vagaDisponivel(Status)).

+idVaga(Id) <- .send(driver, tell, idVaga(Id)).

+!consultarVaga(TipoVaga, Data, Intencao)[source(driver)]: listaVagas(Lista) <-
	.send(driver, askOne, driverWallet(DriverW), Reply);
	.wait(3000);
	+Reply;
	+driverIntention(Intencao);
	!verificarDisponibilidade(TipoVaga, Data, Intencao, set(Lista)).

+!consultarVaga(TipoVaga, Data, Intencao)[source(driver)] : not listaVagas(Vagas) <-
	.print("Estacionamento fechado!").

+!verificarDisponibilidade(TipoVaga, Data, Intencao, set([Head|Tail])): chainServer(Server) & not vagaDisponivel(X) <-
	.print("Verificando disponibilidade...");
	.print("Vaga -> ", Head);
	velluscinum.tokenInfo(Server, Head, all, content);
	.wait(content(Metadata));
	.print("Metadata -> ", Metadata);
	verificarVaga(TipoVaga, Data, Intencao, Metadata);
	?vagaDisponivel(X);
	+idVaga(Head).

-!verificarDisponibilidade(TipoVaga, Data, Intencao, set([Head|Tail])): chainServer(Server) <-
	!verificarDisponibilidade(TipoVaga, Data, Intencao, set(Tail)).

-!verificarDisponibilidade(TipoVaga, Data, Intencao, set([ ])) <-
	+vagaDisponivel(false);
	.print("percorreu todas as vagas").

// -------------------------- COMPRA DIRETA ---------------------------

+valorAPagarUso(Valor) <- .send(driver, tell, valorAPagarUso(Valor)).

+querEstacionar(Id)[source(driver)] <- !ocuparVaga(Id).

+!pagamentoUsoVaga(Tipo, Minutos)[source(driver)] : driverWallet(DriverW) <-
	.print("Calculando valor...");
	calcularValorAPagarUso(Tipo, Minutos).

// -------------------------- COMPRAR RESERVA -------------------------

+!querReservar(Tipo, Date, Minutes)[source(driver)] : listaVagas(Lista) <-
	.print("Reservando vaga...");
	bookVacancy(Tipo, Lista, Date, Minutes).

+!sendReservation(IdVaga, Value)[source(self)] : chainServer(Server) 
            & myWallet(MyPriv,MyPub) & driverWallet(DriverW) <-
	.concat("name:manager;reservation:", IdVaga, Name);
    velluscinum.deployNFT(Server, MyPriv, MyPub, Name, 
				"description:reservation",
				account);
	.wait(account(AssetId));
	.concat("description:reservation;vacancy:", IdVaga, Description);
	velluscinum.transferNFT(Server, MyPriv, MyPub, AssetId, DriverW,
				Description, requestID);
	.wait(requestID(TransferId));
	.send(driver, tell, reservationNFT(AssetId, TransferId)).

// ---------------------- NEGOCIACAO DA RESERVA -----------------------

+reservationAvailable(Type,Date,Min)[source(driver)] <-
	.print("Motorista colocou reserva disponivel").

// ---------------------------- AUXILIARES ----------------------------

+!validarPagamento(Transfer, IdVaga, Value)[source(driver)] :  driverIntention(Intention) <-
	!stampProcess(Transfer);
	.print("Vaga paga!");
	if (Intention == "RESERVA") {
		!sendReservation(IdVaga, Value);
	} else {
		!liberarVaga(IdVaga);
	}.

+reservationUse(TransactionId) <- !stampProcess(TransactionId);
	.print("reserva usada");
	.send(driver, achieve, park).

+!stampProcess(Transfer)[source(self)] : chainServer(Server) 
            & myWallet(MyPriv,MyPub) <-
	.print("Validando transferencia...");
	velluscinum.stampTransaction(Server,MyPriv,MyPub,Transfer).

+!ocuparVaga(Id): chainServer(Server) & myWallet(Priv,Pub) <-
	.print("Ocupando Vaga...");
	.print("Id -> ", Id);
	velluscinum.transferNFT(Server, Priv, Pub, Id, Pub, "status:ocupado", requestID);
	.wait(requestID(TransferId));
	.send(driver, tell, vagaOcupada(Id)).

+!liberarVaga(Id): chainServer(Server) & myWallet(Priv,Pub) <-
	.print("Liberando Vaga...");
	.print("Id -> ", Id);
	velluscinum.transferNFT(Server, Priv, Pub, Id, Pub, "status:disponivel", requestID);
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
	.wait(myWallet(Priv,Pub));
	+managerWallet(Pub);
	.wait(5000);
	!verificarListaVagas.

+!verificarListaVagas: chainServer(Server) & myWallet(MyPriv,MyPub) <-
	.print("Verificando lista de vagas...");
	velluscinum.walletContent(Server, MyPriv, MyPub, content);
	.wait(content(Content));
	!findToken(nft, set(Content));
	!abrirEstacionamento.

+!verificarListaVagas: not chainServer(Server) <-
	.wait(5000);
	!verificarListaVagas.

+!abrirEstacionamento : listaVagas(Vagas) <-
	.print("Estacionamento Aberto!");
	.broadcast(tell, estacionamentoAberto).

+!listarVagas: chainServer(Server) & myWallet(MyPriv,MyPub) <- 
	.print("Listando vagas...");

	velluscinum.deployNFT(Server, MyPriv, MyPub, "name:Vaga1;tipo:Curta", "status:disponivel", account);
	.wait(account(Vaga1Id));

	velluscinum.deployNFT(Server, MyPriv, MyPub, "name:Vaga2;tipo:Longa", "status:disponivel", account);
	.wait(account(Vaga2Id));

	velluscinum.deployNFT(Server, MyPriv, MyPub, "name:Vaga3;tipo:Longa", "status:disponivel", account);
	.wait(account(Vaga3Id));

	velluscinum.deployNFT(Server, MyPriv, MyPub, "name:Vaga4;tipo:CurtaCoberta", "status:disponivel", account);
	.wait(account(Vaga4Id));

	velluscinum.deployNFT(Server, MyPriv, MyPub, "name:Vaga5;tipo:LongaCoberta", "status:disponivel", account);
	.wait(account(Vaga5Id));

	Lista = [Vaga1Id, Vaga2Id, Vaga3Id, Vaga4Id, Vaga5Id];
	-+listaVagas(Lista);
	!abrirEstacionamento.

+!findToken(Term,set([Head|Tail])) <- 
    !compare(Term,Head,set(Tail));
    !findToken(Term,set(Tail)).

+!compare(Term,[Type,AssetID, Qtd],set(V)): (Term  == Type) | (Term == AssetID) <-
	.print("Vaga: ", AssetID);
	+vaga(AssetID).

-!compare(Term,[Type,AssetID,Qtd],set(V)) <- .print("The Asset ",AssetID, " is not a ",Term).

-!findToken(Type,set([   ])): not vaga(Vaga) <- 
	.print("Lista de vagas nao encontrada");
	!listarVagas.

-!findToken(Type,set([   ])): vaga(Vaga) <- 
	.print("Vagas ja cadastradas").

