{ include("$jacamo/templates/common-cartago.asl") }
{ include("$jacamo/templates/common-moise.asl") }

/* Initial beliefs */

/* Initial goals */
!escolher.

/* Plans */

+decisao(X) : true <- .print("Escolha: ", X).

+vagaDisponivel(X)[source(self)] <- .print("Vaga disponivel: ", X).

+vagaDisponivelParaReserva(X)[source(manager)] : X == true <-
    .wait(3000);
    ?tipoVaga(Tipo);
    ?decisao(Choice);
    ?dataUso(Data);
    if (Choice == "COMPRA") {
        !estacionar;
    } elif (Choice == "RESERVA") {
        .print("Indo para reservar vaga...");
        !reservar(Tipo, Data);
    } else {
        .print("Escolha invalida");
    }.

+vagaDisponivelParaReserva(Status) : X == false <-
    .print("Vaga indisponivel").

+reservationNFT(AssetId, TransactionId)[source(manager)] <- 
    !stampProcess(TransactionId);
    .print("Reserva recebida");
    defineReservationChoice(AssetId).

+reservationAvailable(Type,Date,Min)[source(driver)] <-
    .print("Motorista colocou a reserva disponivel").

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

// -------------------- CENARIOS --------------------
// ----- USO -----

+vagaOcupada(Id)[source(manager)] <-
    .print("Vaga ocupada");
    ?tempoUso(Min);
    .wait(Min*10);
    !comprar.

+valorAPagarUso(Value)[source(manager)] <- !pagarUso(Value).

+!comecarNegociacao[source(self)] : decisao(EscolhaDriver) & tipoVaga(Tipo) 
            & EscolhaDriver == "COMPRA" <-
    consultPrice(Tipo);
    ?precoTabela(Price);
    ?dataUso(Data);
    
    .print("Tipo da vaga: ", Tipo);
    .print("Preco da vaga (por hora): ", Price);
    .print("Data de uso: ", Data);
    .send(manager, achieve, consultarVaga(Tipo, Data, EscolhaDriver)).

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

+!estacionar[source(self)] : tempoUso(Min) & idVaga(Id) <-
    .print("--------------------------------------------------------------");
    .print("Estacionando veiculo na vaga ", Id);
    .send(manager, tell, querEstacionar(Id)).

// ----- RESERVAR -----

+!comecarNegociacao[source(self)] : decisao(EscolhaDriver) & tipoVaga(Tipo)
            & EscolhaDriver == "RESERVA" <-
    ?dataUso(Data);

    .print("Tipo da vaga: ", Tipo);
    .print("Data de uso: ", Data);

    !reservar(Tipo, Data).

+!reservar(Tipo, Data) : tempoUso(Min) & chainServer(Server)
            & myWallet(Priv,Pub) & cryptocurrency(Coin) <- 
    .print("Solicitando reserva...");
    .send(manager, achieve, querReservar(Tipo, Data, Min)).

+reservationChoice(Choice) <- 
    .print("Escolha de reserva: ", Choice);
    if (Choice == "USAR") {
        !useReservation;
    } elif(Choice == "VENDER") {
        !makeVacancyAvailable;
    } else {
        .print("Escolha invalida");
    }.

// ----- VALIDACAO -----
+!stampProcess(TransactionId)[source(self)] : chainServer(Server)
            & myWallet(MyPriv,MyPub) <-
    .print("Validando transferencia...");
    velluscinum.stampTransaction(Server, MyPriv, MyPub, TransactionId).

// ----------------- ESTACIONAR E DEIXAR ESTACIONAMENTO -----------------

+!estacionar[source(manager)] : tempoUso(Min) & idVaga(Id) <-
    .print("--------------------------------------------------------------");
    .print("Estacionando veiculo na vaga ", Id);
    +parked(Id);
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