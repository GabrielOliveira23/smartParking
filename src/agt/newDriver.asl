{ include("$jacamo/templates/common-cartago.asl") }
{ include("$jacamo/templates/common-moise.asl") }

/* Initial beliefs */

/* Initial goals */
!escolher.

/* Plans */

+decisao(X) : true <-
    .print("Escolha: ", X).

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

+!escolher : true <-
    // balanceNFT <---------- verificar se tem alguma reserva na carteira
    defineChoice;
    .print("Criando conta bancaria");
    !criarCarteira;
	!pedirEmprestimo;
	.send(manager,askOne,managerWallet(Manager),Reply);
	.wait(5000);
	+Reply;
    !comecarNegociacao.

+!comecarNegociacao[source(self)] : decisao(Choice) & tipoVaga(Type) <-
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

// ----------------- ACOES CARTEIRA -----------------

+!criarCarteira : true <-
    velluscinum.buildWallet(myWallet);
	.wait(myWallet(MyPriv,MyPub));
    +driverWallet(MyPub).

+!pedirEmprestimo : cryptocurrency(Coin) & bankWallet(BankW) 
            & chainServer(Server) 
            & myWallet(MyPriv,MyPub) <-
	.print("Pedindo emprestimo...");
	velluscinum.deployNFT(Server,MyPriv,MyPub,
				"name:motorista;address:5362fe5e-aaf1-43e6-9643-7ab094836ff4",
				"description:Createing Bank Account",
				account);
				
	.wait(account(AssetID));
	velluscinum.transferNFT(Server,MyPriv,MyPub,AssetID,BankW,
				 "description:requesting lend;value_chainCoin:100",requestID);
	.wait(requestID(PP));
	
	.print("Lend Contract nr:",PP);
	.send(bank, achieve, lending(PP,MyPub,100)).

// ----------------- PAGAMENTO E CONFIRMACAO -----------------

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

// ----------------- ESTACIONAR E DEIXAR ESTACIONAMENTO -----------------

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