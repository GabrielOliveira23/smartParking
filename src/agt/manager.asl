{ include("$jacamo/templates/common-cartago.asl") }
{ include("$jacamo/templates/common-moise.asl") }

/* Initial beliefs */

/* Initial goals */
!createWallet.

/* plans */
+vagaDisponivel(X) <- .send(driver, tell, vagaDisponivel(X)).

+idVaga(X) <- .send(driver, tell, idVaga(X)).

+valueToPay(X) <- .send(driver, tell, valueToPay(X)).

+parking(Id) <- ocuparVaga(Id).

+!createWallet <-
	.print("Criando carteira digital!");
	velluscinum.buildWallet(myWallet);
	.wait(myWallet(Priv,Pub));
	+managerWallet(Pub).

+!isVagaDisponivel(Tipo, Date, Intention)[source(driver)] : true <-
	.send(driver, askOne, driverWallet(DriverW), Reply);
	.wait(5000);
	+Reply;
	+driverIntention(Intention);
	consultarVaga(Tipo, Date, Intention).
	// se a intencao for reservar fazer a condicao para isso

+!reservation(Id, Date, Minutes)[source(driver)] : true <-
	.print("Reservando vaga...");
	bookVacancy(Id, Date, Minutes).

+!stampProcess(Transfer)[source(self)] : chainServer(Server) 
            & myWallet(MyPriv,MyPub) <-
	.print("Validando transferencia...");
	velluscinum.stampTransaction(Server,MyPriv,MyPub,Transfer).

+!vacancyPayment(Transfer, IdVaga, Value)[source(driver)] :  driverIntention(Intention) <-
	!stampProcess(Transfer);
	.print("Vaga paga!");
	if (Intention == "RESERVA") {
		!sendReservation(IdVaga, Value);
	} else {
		driverExiting(IdVaga);
		.send(driver, achieve, leave);
	}.

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
	.send(driver, tell, reservationNFT(TransferId)).