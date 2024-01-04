{ include("$jacamo/templates/common-cartago.asl") }
{ include("$jacamo/templates/common-moise.asl") }

/* Initial beliefs */

/* Initial goals */

!choose.

/* Plans */

+vagaDisponivel(X)[source(self)] <- .print("Vaga disponivel: ", X).

+!startNegotiation <- 
    ?decisao(Choice);
    .print("Escolha: ", Choice);
    ?tipoVaga(Tipo);

    consultPrice(Tipo);
    ?precoTabela(Price);
    
    .print("Tipo da vaga: ", Tipo);
    .print("Preco da vaga: ", Price);

    if (Choice == "COMPRA") {
        .send(manager, achieve, isVagaDisponivel(Tipo, Choice));
    } else {
        .print("Escolha invalida");
    }.

+vagaDisponivel(X)[source(Manager)] : true <-
    if (X == true) {
        ?decisao(Choice);
        if (Choice == "COMPRA") {
            ?idVaga(Id);
            !park;
            !compra(Id);
        } else {
            .print("Escolha invalida");
        }
    } elif (X == false) {
        .print("Vaga indisponivel");
    }.

+!choose : true <-
    defineChoice;
    !startNegotiation.

+!createWallet : true <-
    velluscinum.buildWallet(myWallet);
	.wait(myWallet(MyPriv,MyPub));
    +driverWallet(MyPub).

+!compra(Id) : true <- 
    .print("Compra de vaga");
    ?useTime(Minutes);
    defineValueToPay(Id, Minutes);
    ?valueToPay(Value);
    !pay(Value).
    //enviar mensagem para o gerente para a verificacao de transferencia

+!pay(Price) : not bankAccount(ok)[source(bank)] & not driverWallet(MyPub) <-
    .print("Criando conta bancaria");
    !createWallet;
	!requestLend;
	.send(manager,askOne,managerWallet(Manager),Reply);
	.wait(5000);
	+Reply;
	!pay(Price).

+!pay(Price) : bankAccount(ok)[source(bank)] & cryptocurrency(Coin) 
			& chainServer(Server) & myWallet(MyPriv,MyPub) 
			& managerWallet(Manager) <-
    ?useTime(Min);
    .print("Tempo de uso (minutos): ", Min);

    .print("Pagando vaga.....");
    
    ?tipoVaga(Vaga);
	velluscinum.transferToken(Server,MyPriv,MyPub,Coin,Manager,Price,payment);
	.wait(payment(IdTransfer));
    .print("Pagamento realizado");
	
    .send(manager, achieve, vacancyPayment(IdTransfer)).

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
	.send(bank,achieve,lending(PP,MyPub,100)).

+!park: true <-
    ?idVaga(Id);
    .print("Estacionando veiculo na vaga ", Id);
    .print("--------------------------------------------------------------");
    ?useTime(Min);
    .wait(Min*10).

+!leave[source(manager)] : true <-
    .print("Saindo da vaga");
    .print("--------------------------------------------------------------").