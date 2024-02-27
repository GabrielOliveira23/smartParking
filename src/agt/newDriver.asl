{ include("$jacamo/templates/common-cartago.asl") }
{ include("$jacamo/templates/common-moise.asl") }

/* Initial beliefs */

/* Initial goals */
!escolher.

/* Plans */

+decisao(X) : true <- .print("Escolha: ", X).

+vagaDisponivel(X)[source(self)] <- .print("Vaga disponivel: ", X).

+valorAPagarUso(Value)[source(manager)] <- !pagarUso(Value).

+vagaDisponivel(X)[source(manager)] : true <-
    .wait(3000);
    if (X == true) {
        ?idVaga(Id);
        ?decisao(Choice);
        if (Choice == "COMPRA") {
            !estacionar;
        } elif (Choice == "RESERVA") {
            !book(Id);
        } else {
            .print("Escolha invalida");
        }
    } elif (X == false) {
        .print("Vaga indisponivel");
    }.

+liberadoParaEstacionar(Id)[source(manager)] <-
    ?tempoUso(Min);
    +parked(Id).

+vagaOcupada(Id)[source(manager)] <-
    .print("Vaga ocupada");
    ?tempoUso(Min);
    .wait(Min*10);
    !comprar.

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
    .wait(estacionamentoAberto);
    // balanceNFT <---------- verificar se tem alguma reserva na carteira
    defineChoice;
    .print("Criando conta bancaria");
    !criarCarteira;
	!pedirEmprestimo;
	.send(manager,askOne,managerWallet(Manager),Reply);
	.wait(5000);
	+Reply;
    !comecarNegociacao.

+!comecarNegociacao[source(self)] : decisao(EscolhaDriver) & tipoVaga(Type) <-
    consultPrice(Type);
    ?precoTabela(Price);
    ?dataUso(Data);
    
    .print("Tipo da vaga: ", Type);
    .print("Preco da vaga (por hora): ", Price);
    .print("Data de uso: ", Data);

    if (EscolhaDriver == "COMPRA" | EscolhaDriver == "RESERVA") {
        .send(manager, achieve, consultarVaga(Type, Data, EscolhaDriver));
    } elif (EscolhaDriver == "COMPRARESERVA") {
        !buyReservation(Type, Data);
    } else {
        .print("Escolha invalida");
    }.

+!comecarNegociacao : true <-
    .print("Escolha de acao invalida").

// ----------------- ACOES CARTEIRA -----------------

+!criarCarteira : true <-
    .print("Criando carteira...");
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

+!pedirEmprestimo : true <-
    .print("Erro ao pedir emprestimo");
    .wait(5000);
    !pedirEmprestimo.

// ----------------- PAGAMENTO E CONFIRMACAO -----------------

+!comprar : true <- 
    .print("Pagamento da vaga");
    ?tempoUso(Minutes);
    ?tipoVaga(Tipo);
    .send(manager, achieve, pagamentoUsoVaga(Tipo, Minutes)).

+!pagarUso(Valor) : not managerWallet(Manager) <-
    .wait(5000);
    .send(manager,askOne,managerWallet(Manager),Reply);
    +Reply;
    !pagarUso(Valor).

+!pagarUso(Valor) : bankAccount(ok)[source(bank)] & cryptocurrency(Coin)
            & chainServer(Server) & myWallet(MyPriv,MyPub)
            & managerWallet(Manager) <-
    .print("Pagamento em andamento...");
    ?idVaga(IdVaga);
    velluscinum.transferToken(Server,MyPriv,MyPub,Coin,Manager,Valor,payment);
    .wait(payment(TransactionId));
    .print("Pagamento realizado");
    .send(manager, achieve, validarPagamento(TransactionId, IdVaga, Valor)).

+!stampProcess(TransactionId)[source(self)] : chainServer(Server)
            & myWallet(MyPriv,MyPub) <-
    .print("Validando transferencia...");
    velluscinum.stampTransaction(Server, MyPriv, MyPub, TransactionId).

// ----------------- ESTACIONAR E DEIXAR ESTACIONAMENTO -----------------

+!estacionar[source(self)] : tempoUso(Min) & idVaga(Id) <-
    .print("--------------------------------------------------------------");
    .print("Estacionando veiculo na vaga ", Id);
    .send(manager, tell, querEstacionar(Id)).

+!estacionar[source(manager)] : tempoUso(Min) & idVaga(Id) <-
    .print("--------------------------------------------------------------");
    .print("Estacionando veiculo na vaga ", Id);
    +parked(Id);
    // possibilidade de exceder o valor especificado pela reserva
    .wait(Min*10);
    !leave.

+!sairEstacionamento[source(manager)] : true <-
    .print("Saindo do estacionamento");
    -parked(Id);
    .print("--------------------------------------------------------------").

+!leave : true <-
    .print("Saindo da vaga");
    -parked(Id);
    .print("--------------------------------------------------------------").