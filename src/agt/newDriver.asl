{ include("$jacamo/templates/common-cartago.asl") }
{ include("$jacamo/templates/common-moise.asl") }

/* Initial beliefs */

/* Initial goals */
!comecar.

/* Plans */

+decisao(X) : true <- 
    .print("==============================================================");
    .print("Escolha: ", X).

+vagaDisponivel(Status)[source(manager)] : Status == true <-
    .wait(3000);
    ?idVaga(Id);
    ?decisao(EscolhaDriver);
    ?dataUso(Data);
    if (EscolhaDriver == "COMPRA") {
        !estacionar(Id);
    } elif (EscolhaDriver == "RESERVA") {
        !reservar(Id, Data);
    }.

+vagaDisponivel(Status) <-
    .print("Vaga indisponivel, aguardando...");
    .print("--------------------------------------------------------------");
    .wait(8000);
    !recomecar.

+reservaNFT(ReservaId, TransferId)[source(manager)] : listaNFTs(Lista) <- 
    .print("Reserva recebida");
    !stampProcess(TransferId);
    -+listaNFTs([ReservaId|Lista]);
    !escolher.

+reservaNFT(ReservaId, TransferId)[source(manager)] : not listaNFTs(Lista) <- 
    .print("Reserva recebida");
    !stampProcess(TransferId);
    +listaNFTs([ReservaId]);
    !escolher.

+reservationAvailable(Type,Date,Min)[source(driver)] <-
    .print("Motorista colocou a reserva disponivel").

+!comecar <-
    lookupArtifact("parkPricing", ParkPricing);
    focus(ParkPricing);
    .wait(estacionamentoAberto);
    !criarCarteira;
    !obterConteudoCarteira;
    .wait(coinBalance(Balance));
    .send(manager,askOne,managerWallet(Manager),Reply);
    .wait(5000);
    +Reply;
    !escolher.

+!recomecar <-
    .abolish(decisao(_));
    .abolish(vagaDisponivel(_));
    .abolish(reservaEscolhida(_));
    .abolish(vagaOcupada(_));
    .abolish(decisaoReserva(_));
    .abolish(dataUso(_));
    .abolish(tipoVaga(_));
    .abolish(idVaga(_));

    !obterConteudoCarteira;
    .wait(coinBalance(Balance));

    !escolher.

+!escolher <-
    // defineChoice;
    ?decisao(EscolhaDriver);
    if (EscolhaDriver == "RESERVA") {
        ?listaNFTs(Lista);
        escolherReserva(Lista);
    } elif (EscolhaDriver == "COMPRA") {
        !comecarNegociacao;
    }.

-!escolher : not listaNFTs(Lista) <-
    +listaNFTs([]);
    escolherReserva([]).

+!comecarNegociacao[source(self)] : tipoVaga(Tipo) <-
    consultPrice(Tipo);
    ?precoTabela(Price);
    ?dataUso(Data);
    
    .print("Tipo da vaga: ", Tipo);
    .print("Data de uso: ", Data);
    // .print("Preco tabelado da vaga: ", Price);
    !consultar.

// ----------------- ACOES CARTEIRA -----------------

+driverWallet(PuK) <- .broadcast(tell, driverWallet(PuK)).

+!criarCarteira : not myWallet(PrK,PuK) <-
    .print("Obtendo carteira digital...");
    .velluscinum.loadWallet(myWallet);
	.wait(myWallet(PrK,PuK));
    +driverWallet(PuK);
    .send(bank,askOne,chainServer(Server),Reply);
    .wait(5000);
    +Reply;
    .send(bank,askOne,cryptocurrency(Coin),ReplyCoin);
    .wait(5000);
    +ReplyCoin.

+!obterConteudoCarteira : chainServer(Server) & myWallet(PrK, PuK)
                & cryptocurrency(Coin) <-
    .abolish(listaNFTs(_));
    .abolish(coinBalance(_));
    .print("Obtendo conteudo da carteira...");
    .velluscinum.walletContent(Server, PrK, PuK, content);
    .wait(content(Content));
    .send(bank,askOne,bankWallet(BankW),Reply);
    .wait(5000);
    +Reply;
    !findToken(Coin, set(Content));
    !findToken(nft, set(Content)).

+!findToken(Term,set([Head|Tail])) <- 
    !compare(Term,Head,set(Tail));
    !findToken(Term,set(Tail)).

+!compare(Term,[Type, AssetId, Qtd],set(V)) : (Term == AssetId) <- 
    .print("Moeda: ", AssetId);
	+coinBalance(Qtd);
    .print("Saldo atual: ", Qtd).

+!compare(Term,[Type,AssetId,Qtd],set(V)) : (Term == Type) & listaNFTs(Lista) <-    
    .print("Type: ", Type, " ID: ", AssetId);
    -+listaNFTs([AssetId|Lista]).

+!compare(Term,[Type,AssetId,Qtd],set(V)) : (Term == Type) & not listaNFTs(Lista) <-
    .print("Type: ", Type, " ID: ", AssetId);
    .concat(AssetId, Lista);
    +listaNFTs([Lista]).

-!compare(Term,[Type,AssetId,Qtd],set(V)).

-!findToken(Type,set([   ])) : not coinBalance(Amount) <- 
	.print("Moeda Nao encontrada");
    !pedirEmprestimo.

-!findToken(Type,set([   ])).

+!pedirEmprestimo : cryptocurrency(Coin) & bankWallet(BankW) 
            & chainServer(Server) & myWallet(PrK,PuK)
            & not pedindoEmprestimo <-
    +pedindoEmprestimo;
    emprestimoCount;
	.print("Pedindo emprestimo...");
    ?emprestimoNum(Num);
    .concat("nome:motorista;emprestimo:", Num, Data);
	.velluscinum.deployNFT(Server, PrK, PuK, Data,
                "description:Creating Bank Account", account);
	.wait(account(AssetId));

	.velluscinum.transferNFT(Server, PrK, PuK, AssetId, BankW,
				"description:requesting lend;value_chainCoin:100",requestID);
	.wait(requestID(PP));
	
	.print("Lend Contract nr:",PP);
	.send(bank, achieve, lending(PP, PuK, 100));
    .wait(bankAccount(ok));
    .abolish(pedindoEmprestimo);
    !obterConteudoCarteira.

+!pedirEmprestimo : pedindoEmprestimo <-
    .print("Ja esta pedindo emprestimo").

-!pedirEmprestimo <-
    .print("Erro ao pedir emprestimo");
    .wait(5000);
    !pedirEmprestimo.

// -------------------- CENARIOS --------------------
// ----- USO -----

+vagaOcupada(Id)[source(manager)] : coinBalance(Balance) & precoTabela(Price) <-
    .print("Vaga ocupada");
    tempoEstacionado(Tempo, Balance, Price);
    // ?tempoUso(Min);
    .wait(Tempo*10);
    !comprar(Tempo).

+valorAPagarUso(Value)[source(manager)] <- !pagarUso(Value).

+!consultar[source(self)] : tipoVaga(Tipo) & decisao(EscolhaDriver) 
            & EscolhaDriver == "COMPRA" <-
    // .print("Consultando vaga...");
    .send(manager,achieve,consultarVaga(Tipo, Data)).

+!comprar(Tempo) <- 
    // .print("Pagamento da vaga");
    ?tipoVaga(Tipo);
    .send(manager, achieve, pagamentoUsoVaga(Tipo, Tempo)).

+!pagarUso(Valor) : not managerWallet(Manager) <-
    .wait(5000);
    .send(manager,askOne,managerWallet(Manager),Reply);
    +Reply;
    !pagarUso(Valor).

+!pagarUso(Valor) : cryptocurrency(Coin) & chainServer(Server)
            & myWallet(PrK,PuK) & managerWallet(Manager) 
            & (coinBalance(Balance) & (Balance >= Valor))<-
    // .print("Pagamento em andamento...");
    ?idVaga(Id);
    .velluscinum.transferToken(Server,PrK,PuK,Coin,Manager,Valor,payment);
    .wait(payment(TransactionId));
    .print("Pagamento realizado");
    .send(manager, achieve, validarPagamento(TransactionId, Id)).

+!pagarUso(Valor) : cryptocurrency(Coin) & chainServer(Server)
            & myWallet(PrK,PuK) & managerWallet(Manager) 
            & (coinBalance(Balance) & (Balance < Valor))<-
    .print("Saldo insuficiente");
    !pedirEmprestimo;
    !pagarUso(Valor).

+!estacionar(Id)[source(self)] <-
    .print("--------------------------------------------------------------");
    .print("Estacionando veiculo na vaga ", Id);
    .send(manager, tell, querEstacionar(Id)).

// ----- RESERVAR -----

+!consultar[source(self)] : tipoVaga(Tipo) & dataUso(Data) & tempoUso(Min) 
            & decisao(EscolhaDriver) & EscolhaDriver == "RESERVA" <-
    .print("Tempo de reserva: ", Min);
    .print("Consultando vaga...");
    .send(manager, achieve, consultarReserva(Tipo, Data, Min)).

+!reservar(Id, Data) : tempoUso(Min) & chainServer(Server) & myWallet(PrK,PuK) 
            & cryptocurrency(Coin) & managerWallet(Manager) <- 
    .print("Pagando reserva...");
    ?precoTabela(Preco);
    .velluscinum.transferToken(Server, PrK, PuK, Coin, Manager, Preco, payment);
    .wait(payment(TransactionId));
    .send(manager, tell, pagouReserva(TransactionId, Id, Data, Min)).

+!reservar(Id, Data) : not managerWallet(Manager) <-
    .wait(5000);
    .send(manager,askOne,managerWallet(Manager),Reply);
    +Reply;
    !reservar(Id, Data).

+decisaoReserva(Choice) <- 
    .print("Decisao da reserva: ", Choice);
    if (Choice == "RESERVAR") {
        !comecarNegociacao;
    } elif (Choice == "USAR") {
        !usarReserva;
    } elif(Choice == "VENDER") {
        !makeVacancyAvailable;
    } else {
        .print("Escolha invalida");
    }.

// --- USAR RESERVA ---

+!usarReserva : chainServer(Server) & myWallet(PrK, PuK)
            & managerWallet(ManagerW) & reservaEscolhida(ReservaId) <-
    .print("Escolha de reserva: ", ReservaId);
    .velluscinum.transferNFT(Server, PrK, PuK, ReservaId, ManagerW,
            "description:Using Reservation", usoReserva);
    .wait(usoReserva(TransactionId));
    .send(manager, tell, querUsarReserva(ReservaId, TransactionId)).

// ----- VALIDACAO -----
+!stampProcess(TransactionId)[source(self)] : chainServer(Server)
            & myWallet(PrK,PuK) <-
    .print("Validando transferencia...");
    .velluscinum.stampTransaction(Server, PrK, PuK, TransactionId).

// ----------------- ESTACIONAR E DEIXAR ESTACIONAMENTO -----------------

+!estacionar[source(manager)] : idVaga(Id) & not tempoUso(Min) <-
    .print("--------------------------------------------------------------");
    .print("Estacionando veiculo na vaga ", Id);
    +estacionado(Id);
    tempoEstacionado;
    ?tempoUso(Min);
    .wait(Min*10);
    .abolish(tempoUso(_));
    !sairEstacionamento.

+!estacionarReserva(VagaId)[source(manager)] : tempoUso(Min) <-
    .print("--------------------------------------------------------------");
    .print("Estacionando veiculo na vaga ", VagaId);
    +estacionado(VagaId);
    .wait(Min*10);
    .abolish(tempoUso(_));
    .send(manager, tell, querSair(VagaId)).

+!sairEstacionamento : true <-
    .print("Saindo da vaga");
    .abolish(estacionado(_));
    .print("--------------------------------------------------------------");
    !recomecar.
