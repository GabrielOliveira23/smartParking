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

+reservationNFT(TransactionId)[source(manager)] <- 
    !stampProcess(TransactionId);
    .print("Reserva recebida");
    defineReservationChoice.

+reservationChoice(Choice) <- 
    .print("Escolha de reserva: ", Choice).

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
	.print("Requesting Lend");
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


+!startNegotiation[source(self)] : decisao(Choice) & tipoVaga(Tipo) <- 
    .print("Escolha: ", Choice);

    consultPrice(Tipo);
    ?precoTabela(Price);
    ?useDate(Date);
    
    .print("Tipo da vaga: ", Tipo);
    .print("Preco da vaga (por hora): ", Price);
    .print("Data de uso: ", Date);

    if (Choice == "COMPRA" | Choice == "RESERVA") {
        .send(manager, achieve, isVagaDisponivel(Tipo, Date, Choice));
    } else {
        .print("Escolha invalida");
    }.



+!buy(Id) : true <- 
    .print("Compra de vaga");
    ?useTime(Minutes);
    // make manager define value
    defineValueToPay(Id, Minutes);
    ?valueToPay(Value);
    !pay(Value).
    //enviar mensagem para o gerente para a verificacao de transferencia

+!book(Id) : true <-
    .print("Reserva de vaga");
    ?useTime(Minutes);
    ?useDate(Date);
    .send(manager, achieve, reservation(Id,Date,Minutes)).

+!pay(Price) : bankAccount(ok)[source(bank)] & cryptocurrency(Coin) 
			& chainServer(Server) & myWallet(MyPriv,MyPub) 
			& managerWallet(Manager) & idVaga(IdVaga)
            & useTime(Min) <-
    .print("Tempo de uso (minutos): ", Min);
    .print("Valor a pagar: ", Price);

    .print("Pagamento em andamento...");
    
    ?tipoVaga(Vaga);
	velluscinum.transferToken(Server,MyPriv,MyPub,Coin,Manager,Price,payment);
	.wait(payment(IdTransfer));
    .print("Pagamento realizado");
	
    .send(manager, achieve, vacancyPayment(IdTransfer, IdVaga, Price)).

+!stampProcess(TransactionId)[source(self)] : chainServer(Server)
            & myWallet(MyPriv,MyPub) <-
    .print("Stamping process...");
    velluscinum.stampTransaction(Server, MyPriv, MyPub, TransactionId).

+!park: true <-
    ?idVaga(Id);
    .print("Estacionando veiculo na vaga ", Id);
    .send(manager, tell, parking(Id));
    .print("--------------------------------------------------------------");
    ?useTime(Min);
    .wait(Min*10).

+!leave[source(manager)] : true <-
    .print("Saindo da vaga");
    .print("--------------------------------------------------------------").