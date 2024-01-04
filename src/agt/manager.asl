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

+!isVagaDisponivel(Vaga, Intention) : true <-
	+driverIntention(Intention);
	consultarVaga(Vaga).
	// se a intencao for reservar fazer a condicao para isso

+!vacancyPayment(Transfer) : cryptocurrency(Coin)
            & chainServer(Server) 
            & myWallet(MyPriv,MyPub) <-
	.print("Validating vacancy payment!");
	velluscinum.stampTransaction(Server,MyPriv,MyPub,Transfer);
	.print("Vacancy paid!");
	.send(driver, achieve, leave).

+vagaDisponivel(X) <-
	.send(driver, tell, vagaDisponivel(X)).

+idVaga(X) <-
	.send(driver, tell, idVaga(X)).
	