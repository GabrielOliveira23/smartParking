{ include("$jacamo/templates/common-cartago.asl") }
{ include("$jacamo/templates/common-moise.asl") }

/* Initial beliefs */

/* Initial goals */
!criarCarteira.

/* plans */

// ----------------------------- COMMONS ------------------------------

+vagaDisponivelParaReserva(Status) <- .send(driver, tell, vagaDisponivelParaReserva(Status)).

+idVaga(Id) <- .send(driver, tell, idVaga(Id)).

+!criarCarteira <-
	.print("Criando carteira digital!");
	velluscinum.buildWallet(myWallet);
	.wait(myWallet(Priv,Pub));
	+managerWallet(Pub);
	.wait(5000);
	!listarVagas.

+!abrirEstacionamento : listaVagas(Vagas) <-
	.print("Estacionamento Aberto!");
	.broadcast(tell, estacionamentoAberto).

+!consultarVaga(TipoVaga, Data, Intencao)[source(driver)] : listaVagas(Vagas) <-
	.send(driver, askOne, driverWallet(DriverW), Reply);
	.wait(5000);
	+Reply;
	+driverIntention(Intencao);
	verificarVaga(Vagas, TipoVaga, Data, Intencao).
	// se a intencao for reservar fazer a condicao para isso

+!consultarVaga(TipoVaga, Data, Intencao)[source(driver)] : not listaVagas(Vagas) <-
	.print("Estacionamento fechado!").

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
	// !stampProcess(TransferId);
	.send(driver, tell, vagaOcupada(Id)).

+!liberarVaga(Id): chainServer(Server) & myWallet(Priv,Pub) <-
	.print("Liberando Vaga...");
	.print("Id -> ", Id);
	velluscinum.transferNFT(Server, Priv, Pub, Id, Pub, "status:disponivel", requestID);
	.wait(requestID(TransferId));
	// !stampProcess(TransferId);
	.print("Vaga Liberada");
	.send(driver, achieve, sairEstacionamento).

+!listarVagas: chainServer(Server) & myWallet(MyPriv,MyPub) <- 
	Descricao1 = "tipoVaga:Curta;status:disponivel;assetId:";
	.print("Listando vagas...");
	velluscinum.deployNFT(Server, MyPriv, MyPub, "name:Vaga1", "", account);
	.wait(account(Vaga1Id));
	.concat(Descricao1, Vaga1Id, Vaga1);

	Descricao2 = "tipoVaga:Longa;status:disponivel;assetId:";
	velluscinum.deployNFT(Server, MyPriv, MyPub, "name:Vaga2", Descricao2, account);
	.wait(account(Vaga2Id));
	.concat(Descricao2, Vaga2Id, Vaga2);

	Descricao3 = "tipoVaga:Longa;status:disponivel;assetId:";
	velluscinum.deployNFT(Server, MyPriv, MyPub, "name:Vaga3", Descricao3, account);
	.wait(account(Vaga3Id));
	.concat(Descricao3, Vaga3Id, Vaga3);

	Descricao4 = "tipoVaga:CurtaCoberta;status:disponivel;assetId:";
	velluscinum.deployNFT(Server, MyPriv, MyPub, "name:Vaga4", Descricao4, account);
	.wait(account(Vaga4Id));
	.concat(Descricao4, Vaga4Id, Vaga4);

	Descricao5 = "tipoVaga:LongaCoberta;status:disponivel;assetId:";
	velluscinum.deployNFT(Server, MyPriv, MyPub, "name:Vaga5", Descricao5, account);
	.wait(account(Vaga5Id));
	.concat(Descricao5, Vaga5Id, Vaga5);
	Lista = [Vaga1, Vaga2, Vaga3, Vaga4, Vaga5];
	+listaVagas(Lista);
	!abrirEstacionamento.

-!listarVagas <-
	.wait(5000);
	!listarVagas.