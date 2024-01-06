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
	+driverIntention(Intention);
	consultarVaga(Tipo, Date, Intention).
	// se a intencao for reservar fazer a condicao para isso

+!reservation(Id, Date, Minutes)[source(driver)] : true <-
	.print("Reserving vacancy");
	bookVacancy(Id, Date, Minutes).
	

+!vacancyPayment(Transfer, IdVaga, Value)[source(driver)] : chainServer(Server) 
            & myWallet(MyPriv,MyPub) & driverIntention(Intention) <-
	.send(driver, askOne, driverWallet(Driver), Reply);
	+Reply;
	.print("Validating payment -> Vacancy: ", IdVaga);
	velluscinum.stampTransaction(Server,MyPriv,MyPub,Transfer);
	.print("Vacancy paid!");
	if (Intention == "RESERVA") {
		!sendReservation(Driver, IdVaga, Value);
	} else {
		driverExiting(IdVaga);
		.send(driver, achieve, leave);
	}.

+!sendReservation(Driver, IdVaga, Value)[source(self)] : chainServer(Server) 
            & myWallet(MyPriv,MyPub) <-
	.concat("Vacancy Reservation -> Id: ", IdVaga, Name);
    velluscinum.deployNFT(Server, MyPriv, MyPub, Name, Value, registredContract);
	// transfer nft
	// send id transfer to driver
	.print("Sending reservation to server").

+vagaDisponivel(X) <-
	.send(driver, tell, vagaDisponivel(X)).

+idVaga(X) <-
	.send(driver, tell, idVaga(X)).

+valueToPay(X) <-
	.send(driver, tell, valueToPay(X)).

+parking(Id) <-
	ocuparVaga(Id).