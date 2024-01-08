{ include("$jacamo/templates/common-cartago.asl") }
{ include("$jacamo/templates/common-moise.asl") }

/* Initial beliefs */


/* Initial goals */
!createWallet.

/* plans */
+!createWallet <-
	.print("Creating a digital wallet!");
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
	.print("Reserving vacancy");
	bookVacancy(Id, Date, Minutes).

+!vacancyPayment(Transfer, IdVaga, Value)[source(driver)] : chainServer(Server) 
            & myWallet(MyPriv,MyPub) & driverIntention(Intention) <-
	.print("Validating payment -> Vacancy: ", IdVaga);
	velluscinum.stampTransaction(Server,MyPriv,MyPub,Transfer);
	.print("Vacancy paid!");
	if (Intention == "RESERVA") {
		!sendReservation(DriverW, IdVaga, Value);
	} else {
		driverExiting(IdVaga);
		.send(driver, achieve, leave);
	}.

+!sendReservation(DriverW, IdVaga, Value)[source(self)] : chainServer(Server) 
            & myWallet(MyPriv,MyPub) & driverWallet(DriverW) <-
	.concat("name:manager;reservation:", IdVaga, Name);
    velluscinum.deployNFT(Server, MyPriv, MyPub,
				Name, 
				"description:reservation",
				account);
	.wait(account(AssetId));
	// transfer nft
	.concat("description:reservation;vacancy:", IdVaga, Description);
	velluscinum.transferNFT(Server, MyPriv, MyPub, AssetId, DriverW,
				Description, requestID);
	.wait(requestID(TransferId));
	// send id transfer to driver
	.send(driver, tell, reservationNFT(TransferId)).

+vagaDisponivel(X) <-
	.send(driver, tell, vagaDisponivel(X)).

+idVaga(X) <-
	.send(driver, tell, idVaga(X)).

+valueToPay(X) <-
	.send(driver, tell, valueToPay(X)).

+parking(Id) <-
	ocuparVaga(Id).