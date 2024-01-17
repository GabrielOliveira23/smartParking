{ include("$jacamo/templates/common-cartago.asl") }
{ include("$jacamo/templates/common-moise.asl") }

/* Initial beliefs */

/* Initial goals */
!choose.

/* Plans */

+vagaDisponivel(X)[source(self)] <- .print("Vaga disponivel: ", X).

+valueToPay(Value)[source(manager)] <- !pay(Value).

+vagaDisponivel(X)[source(manager)] : true <-
    .wait(3000);
    if (X == true) {
        ?idVaga(Id);
        ?decisao(Choice);
        if (Choice == "COMPRA") {
            !park;
            !buy(Id);
        } elif (Choice == "RESERVA") {
            !book(Id);
        } else {
            .print("Escolha invalida");
        }
    } elif (X == false) {
        .print("Vaga indisponivel");
    }.

+reservationNFT(AssetId, TransactionId)[source(manager)] <- 
    !stampProcess(TransactionId);
    .print("Reserva recebida");
    defineReservationChoice(AssetId).

+reservationAvailable(Type,Date,Min)[source(driver)] <-
    .print("Motorista colocou a reserva disponivel").

+reservationChoice(Choice) <- 
    .print("Escolha de reserva: ", Choice);
    if (Choice == "USAR") {
        !useReservation;
    } elif(Choice == "VENDER") {
        !makeVacancyAvailable;
    } else {
        .print("Escolha invalida");
    }.

+!choose : true <-
    defineChoice;
    .print("Criando conta bancaria");
    !createWallet;
	!requestLend;
	.send(manager,askOne,managerWallet(Manager),Reply);
	.wait(5000);
	+Reply;
    !startNegotiation.
    
+!createWallet : true <-
    velluscinum.buildWallet(myWallet);
	.wait(myWallet(MyPriv,MyPub));
    +driverWallet(MyPub).

+!requestLend : cryptocurrency(Coin) & bankWallet(BankW) 
            & chainServer(Server) 
            & myWallet(MyPriv,MyPub) <-
	.print("Pedindo emprestimo...");
	velluscinum.deployNFT(Server,MyPriv,MyPub,
				"name:motorista;address:5362fe5e-aaf1-43e6-9643-7ab094836ff4",
				"description:Createing Bank Account",
				account);
				
	.wait(account(AssetID));
	velluscinum.transferNFT(Server,MyPriv,MyPub,AssetID,BankW,
				 "description:requesting lend;value_chainCoin:10",requestID);
	.wait(requestID(PP));
	
	.print("Lend Contract nr:",PP);
	.send(bank, achieve, lending(PP,MyPub,100)).


+!startNegotiation[source(self)] : decisao(Choice) & tipoVaga(Type) <- 
    .print("Escolha: ", Choice);

    consultPrice(Type);
    ?precoTabela(Price);
    ?useDate(Date);
    
    .print("Tipo da vaga: ", Type);
    .print("Preco da vaga (por hora): ", Price);
    .print("Data de uso: ", Date);

    if (Choice == "COMPRA" | Choice == "RESERVA") {
        .send(manager, achieve, isVagaDisponivel(Type, Date, Choice));
    } elif (Choice == "COMPRARESERVA") {
        !buyReservation(Type, Date);
    } else {
        .print("Escolha invalida");
    }.


+!buy(Id) : true <- 
    .print("Pagamento da vaga");
    ?useTime(Minutes);
    // make manager define value
    defineValueToPay(Id, Minutes);
    ?valueToPay(Value);
    !pay(Value).
    //enviar mensagem para o gerente para a verificacao de transferencia


+!buyReservation(Type, Date)[source(self)] : reservationAvailable <-
    .print("comprando reserva de outro motorista").

+!book(Id) : true <-
    .print("Reserva de vaga");
    ?useTime(Minutes);
    ?useDate(Date);
    .send(manager, achieve, reservation(Id,Date,Minutes)).

+!useReservation[source(self)] : reservationNFT(AssetId, TransactionId)
            & chainServer(Server) & myWallet(MyPriv,MyPub)
            & managerWallet(ManagerW) <-
    .wait(5000);
    .print("Cheguei no estacionamento");
    .print("Usando reserva...");
    velluscinum.transferNFT(Server,MyPriv,MyPub,AssetId,ManagerW,
                 "description:using reservation;",requestID);
    .wait(requestID(TransferId));
    .send(manager, tell, reservationUse(TransferId)).

+!makeVacancyAvailable[source(self)] : useDate(Date) 
            & useTime(Min) & tipoVaga(Type) <-
    .print("RESERVA DISPONIBILIZADA");
    .broadcast(tell, reservationAvailable(Type,Date,Min)).

+!makeVacancyAvailable : not useDate(Date) <- .print("DATA").

+!makeVacancyAvailable : not useTime(Min) <- .print("TEMPO").

+!makeVacancyAvailable : not tipoVaga(Type) <- .print("TIPO").

// as vezes a carteira do gerente nao esta criada
+!pay(Price) : not managerWallet(Manager) <-
    .wait(5000);
    .send(manager,askOne,managerWallet(Manager),Reply);
    +Reply;
    !pay(Price).

+!pay(Price) : bankAccount(ok)[source(bank)] & cryptocurrency(Coin) 
			& chainServer(Server) & myWallet(MyPriv,MyPub) 
			& managerWallet(Manager) <-
    ?idVaga(IdVaga);
    ?useTime(Min);    
    ?tipoVaga(Vaga);

    .print("Tempo de uso (minutos): ", Min);
    .print("Valor a pagar: ", Price);
    .print("Pagamento em andamento...");

	velluscinum.transferToken(Server,MyPriv,MyPub,Coin,Manager,Price,payment);
	.wait(payment(IdTransfer));
    .print("Pagamento realizado");
	
    .send(manager, achieve, vacancyPayment(IdTransfer, IdVaga, Price)).

+!stampProcess(TransactionId)[source(self)] : chainServer(Server)
            & myWallet(MyPriv,MyPub) <-
    .print("Validando transferencia...");
    velluscinum.stampTransaction(Server, MyPriv, MyPub, TransactionId).

+!park[source(self)] : useTime(Min) & idVaga(Id) <-
    .print("--------------------------------------------------------------");
    .print("Estacionando veiculo na vaga ", Id);
    .send(manager, tell, parking(Id));
    +parked(Id);
    .wait(Min*10).

+!park[source(manager)] : useTime(Min) & idVaga(Id) <-
    .print("--------------------------------------------------------------");
    .print("Estacionando veiculo na vaga ", Id);
    +parked(Id);
    // possibilidade de exceder o valor especificado pela reserva
    .wait(Min*10);
    !leave.

+!leave : true <-
    .print("Saindo da vaga");
    -parked(Id);
    .print("--------------------------------------------------------------").