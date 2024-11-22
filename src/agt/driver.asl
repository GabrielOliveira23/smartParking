{ include("$jacamo/templates/common-cartago.asl") }
{ include("$jacamo/templates/common-moise.asl") }

/* Initial beliefs */
// hoje
// amanha
// depois de amanha
datasReservas([
    "1729270800",
    "1729357200",
    "1729443600"
    ]).
tiposDeVaga(["Curta", "Longa", "CurtaCoberta", "LongaCoberta"]).

/* Initial goals */
!comecar.

/* Plans */

+decisao(X) <- .print("Escolha: ", X).

+!vagaDisponivel(Status)[source(manager)] : Status == true <-
    .wait(3000);
    ?idVaga(Id);
    ?decisao(EscolhaDriver);
    ?dataUso(Data);
    if (EscolhaDriver == "COMPRA") {
        !estacionar(Id);
    } elif (EscolhaDriver == "RESERVA") {
        !reservar(Id, Data);
    }.

+!vagaDisponivel(Status)[source(manager)] : Status == false <-
    .print("Vaga indisponivel, aguardando...");
    .print("--------------------------------------------------------------");
    .wait(8000);
    !recomecar.

+reservaNFT(ReservaId, TransferId) : listaNFTs(Lista) <- 
    .print("Reserva recebida");
    .print("Reserva Id: ", ReservaId);
    !stampProcess(TransferId);
    -+listaNFTs([ReservaId|Lista]);
    !recomecar.

+reservaNFT(ReservaId, TransferId) : not listaNFTs(Lista) <- 
    .print("Reserva recebida");
    .print("Reserva Id: ", ReservaId);
    !stampProcess(TransferId);
    +listaNFTs([ReservaId]);
    !recomecar.

+reservaNFT(fail) <- 
    .print("Erro ao receber reserva");
    !recomecar.

+reservationAvailable(Type,Date,Min)[source(driver)] <-
    .print("Motorista colocou a reserva disponivel").

+!comecar <-
    joinWorkspace("network");
	lookupArtifact("utils", UtilsId);
    focus(UtilsId);
    .wait(estacionamentoAberto);
    .send(manager, askOne, precoTabelaVagas(Tabela), TabelaVagas);
    incrementarContadorMensagens; // counter
    .wait(2000);
    +TabelaVagas;
    !criarCarteira;
    !obterConteudoCarteira;
    .wait(coinBalance(Balance));
    .send(manager, askOne, managerWallet(Manager), Reply);
    incrementarContadorMensagens; // counter
    .wait(1000);
    +Reply;
    !escolher.

+!recomecar <-
    .abolish(decisao(_));
    .abolish(content(_));
    .abolish(reservaEscolhida(_));
    .abolish(vagaOcupada(_));
    .abolish(decisaoReserva(_));
    .abolish(dataUso(_));
    .abolish(tipoVaga(_));
    .abolish(idVaga(_));
    .abolish(precoVaga(_));

    !obterConteudoCarteira;
    .wait(coinBalance(Balance));

    !escolher.

+!escolher <-
    .print("==============================================================");
    !definirTipoVaga;
    ?tipoVaga(Tipo);
    .random(R);
    if (R < .5) {
        .print("Escolha ----> COMPRA");
        +decisao("COMPRA");
        +dataUso("now");
        !comecarNegociacao;
    // } elif (R <= 1){
    } else {
        .print("Escolha ----> RESERVA");
        +decisao("RESERVA");
        !decidirReserva;
    }.
    // } else {
    //     // comprar de outro motorista
    //     .print("Escolha ----> COMPRARESERVA");
    //     +decisao("COMPRARESERVA");
    //     // definir data
    // }.

-!escolher : not listaNFTs(Lista) <-
    +listaNFTs([]).

+!definirTipoVaga : tiposDeVaga(Tipos) <-
    .length(Tipos, Tam);
    .random(X);
    Indice = math.floor(Tam*X);
    .nth(Indice, Tipos, Item);
    +tipoVaga(Item).

+!decidirReserva <-
    ?listaNFTs(Lista);
    .random(R);
    // if (R < -.33) {
    if (R < .33) {
        .print("usar");
        +decisaoReserva("USAR");
        !escolherReserva(Lista);
        ?reservaEscolhida(ReservaId);
        !usarReserva;
    } elif (R < .66) {
    // } elif (R < .5) {
        .print("reservar");
        +decisaoReserva("RESERVAR");
        !verificarReservasDeMotoristas;
    } else {
        .print("vender");
        +decisaoReserva("VENDER");
        !escolherReserva(Lista);
        ?reservaEscolhida(ReservaId);
        !porReservaAVenda;
    }.

-!decidirReserva : not listaNFTs(Lista) <-
    .print("reservar sem lista");
    +decisaoReserva("RESERVAR");
    !decidirDataETempo;
    !comecarNegociacao.

-!decidirReserva : not reservaEscolhida(ReservaId) <-
    !recomecar.

-!decidirReserva <- 
    .print("Plano de reserva falhou").

+!verificarReservasDeMotoristas : reservasDeMotoristas(Lista) <-
    .print("Verificando reservas de motoristas");
    .length(Lista, Tam);
    if (Tam > 0) {
        .print("Reservas disponiveis a venda: ", Lista);
        !escolherReservaMotorista(Lista);
    } else {
        .print("Nenhuma reserva de motorista disponivel");
        !decidirDataETempo;
        !comecarNegociacao;
    }.

+!decidirDataETempo <-
    ?datasReservas(Datas);
    .length(Datas, Tam);
    .random(X);
    Indice = math.floor(Tam*X);
    .nth(Indice, Datas, Data);
    +dataUso(Data);
    
    .random(Y);
    Min = math.floor(Y*100+20);
    +tempoUso(Min);
    .print("Data: ", Data, " Minutos: ", Min).

+!comecarNegociacao[source(self)] : tipoVaga(Tipo) <-
    !consultarPreco(Tipo);
    ?precoTabela(Preco);
    ?dataUso(Data);
    
    .print("Tipo da vaga: ", Tipo);
    .print("Data de uso: ", Data);
    
    !consultar.

-!comecarNegociacao <-
    .print("Erro ao comecar negociacao").

+!consultarPreco(TipoVaga) : precoTabelaVagas(Tabela) <-
    .member([TipoVaga, Preco], Tabela);
    -+precoTabela(Preco).

// ----------------- ACOES CARTEIRA -----------------

+driverWallet(PuK) <- 
    .send(manager, tell, driverWallet(PuK));
    incrementarContadorMensagens. // counter

+!criarCarteira : not myWallet(PrK,PuK) <-
    .print("Obtendo carteira digital...");
    .velluscinum.loadWallet(myWallet);
	.wait(myWallet(PrK,PuK));
    +driverWallet(PuK);
    
    .send(bank, askOne, chainServer(Server), Chain);
    incrementarContadorMensagens; // counter
    .wait(2000);
    +Chain;
    .send(bank, askOne, bankWallet(BankW), Wallet);
    incrementarContadorMensagens; // counter
    .wait(2000);
    +Wallet;
    .send(bank, askOne, cryptocurrency(Coin), ReplyCoin);
    incrementarContadorMensagens; // counter
    .wait(2000);
    +ReplyCoin.

+!obterConteudoCarteira : chainServer(Server) & myWallet(PrK, PuK)
                & cryptocurrency(Coin) <-
    .abolish(listaNFTs(_));
    .abolish(coinBalance(_));
    .print("Obtendo conteudo da carteira...");
    .velluscinum.walletContent(Server, PrK, PuK, content);
    .wait(content(Content));
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
    if (emprestimoCount(Num)) {
        -+emprestimoCount(Num+1);
    } else {
        +emprestimoCount(1);
    }

	.print("Pedindo emprestimo...");
    ?emprestimoCount(Num);
    .concat("nome:motorista;emprestimo:", Num, Dados);
    .print("Server: ", Server);
    .print("PrK: ", PrK);
    .print("PuK: ", PuK);
    .print("Dados: ", Dados);

	.velluscinum.deployNFT(Server, PrK, PuK, Dados,
                "description:Creating Bank Account", account);
	.wait(account(AssetId));

	.velluscinum.transferNFT(Server, PrK, PuK, AssetId, BankW,
				"description:requesting lend;value_chainCoin:100",requestID);
	.wait(requestID(PP));
	
	.print("Lend Contract nr:",PP);
	.send(bank, achieve, lending(PP, PuK, 100));
    incrementarContadorMensagens; // counter
    .wait(bankAccount(ok));
    .abolish(pedindoEmprestimo);
    !obterConteudoCarteira.

+!pedirEmprestimo(Valor)[source(self)] : cryptocurrency(Coin) & bankWallet(BankW) 
            & chainServer(Server) & myWallet(PrK,PuK)
            & not pedindoEmprestimo <-
    .print("dinheiro acabou, pedindo emprestimo");
    +pedindoEmprestimo;
    .abolish(bankAccount(_));

    if (emprestimoCount(Num)) {
        -+emprestimoCount(Num+1);
    } else {
        +emprestimoCount(1);
    }

	.print("Pedindo emprestimo, valor: ", Valor);
    ?emprestimoCount(Num);
    .concat("nome:motorista;emprestimo:", Num, Data);
	.velluscinum.deployNFT(Server, PrK, PuK, Data,
                "description:Creating Bank Account", account);
	.wait(account(AssetId));

    .concat("description:requesting lend;value_chainCoin:", Valor, Descricao);
	.velluscinum.transferNFT(Server, PrK, PuK, AssetId, BankW, Descricao, requestID);
	.wait(requestID(PP));
	
	.print("Lend Contract nr:", PP);
	.send(bank, achieve, lending(PP, PuK, Valor));
    incrementarContadorMensagens; // counter
    .wait(bankAccount(ok));
    .abolish(pedindoEmprestimo).

+!pedirEmprestimo : pedindoEmprestimo <-
    .print("Ja esta pedindo emprestimo").

-!pedirEmprestimo <-
    .print("Erro ao pedir emprestimo");
    .wait(5000);
    !pedirEmprestimo.

// ----- VALIDACAO -----
+!stampProcess(TransactionId)[source(self)] : chainServer(Server) & myWallet(PrK,PuK) <-
    .print("Validando transferencia...");
    .print("Server: ", Server);
    .print("PrK: ", PrK);
    .print("PuK: ", PuK);
    .print("TransactionId: ", TransactionId);
    .velluscinum.stampTransaction(Server, PrK, PuK, TransactionId).

-!stampProcess(TransactionId) <- 
    .print("Erro ao validar transferencia, tentando novamente");
    .wait(3000);
    !stampProcess(TransactionId).

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
    .send(manager, achieve, consultarVaga(Tipo, Data));
    incrementarContadorMensagens. // counter

+!comprar(Tempo) <- 
    // .print("Pagamento da vaga");
    ?tipoVaga(Tipo);
    .send(manager, achieve, pagamentoUsoVaga(Tipo, Tempo));
    incrementarContadorMensagens. // counter

+!pagarUso(Valor) : not managerWallet(Manager) <-
    .wait(5000);
    .send(manager,askOne,managerWallet(Manager),Reply);
    incrementarContadorMensagens; // counter
    +Reply;
    !pagarUso(Valor).

+!pagarUso(Valor) : cryptocurrency(Coin) & chainServer(Server)
            & myWallet(PrK,PuK) & managerWallet(Manager) 
            & (coinBalance(Balance) & (Balance >= Valor))<-
    .print("Pagamento em andamento...");
    ?idVaga(Id);
    .velluscinum.transferToken(Server,PrK,PuK,Coin,Manager,Valor,payment);
    .wait(payment(TransactionId));
    .print("Pagamento realizado");
    .send(manager, achieve, validarPagamento(TransactionId, Id));
    incrementarContadorMensagens; // counter
    .abolish(payment(_)).

+!pagarUso(Valor) : cryptocurrency(Coin) & chainServer(Server)
            & myWallet(PrK,PuK) & managerWallet(Manager) 
            & (coinBalance(Balance) & (Balance < Valor))<-
    .print("Saldo insuficiente");
    !pedirEmprestimo;
    !pagarUso(Valor).

+!estacionar(Id)[source(self)] <-
    .print("--------------------------------------------------------------");
    .print("Estacionando veiculo na vaga ", Id);
    .send(manager, tell, querEstacionar(Id));
    incrementarContadorMensagens. // counter

// ----- RESERVAR -----

+!consultar[source(self)] : tipoVaga(Tipo) & dataUso(Data) & tempoUso(Min) 
            & decisaoReserva(EscolhaReserva) & EscolhaReserva == "RESERVAR" <-
    .print("Tempo de reserva: ", Min);
    .print("Consultando vaga...");
    .send(manager, achieve, consultarReserva(Tipo, Data, Min));
    incrementarContadorMensagens. // counter

+!reservar(Id, Data) : tempoUso(Min) & chainServer(Server) & myWallet(PrK,PuK) 
            & cryptocurrency(Coin) & managerWallet(Manager) <- 
    .print("Pagando reserva...");
    ?precoTabela(Preco);
    .velluscinum.transferToken(Server, PrK, PuK, Coin, Manager, Preco, payment);
    .wait(payment(TransactionId));
    .send(manager, tell, pagouReserva(TransactionId, Id, Data, Min));
    incrementarContadorMensagens. // counter

+!reservar(Id, Data) : not managerWallet(Manager) <-
    .wait(5000);
    .send(manager,askOne,managerWallet(Manager),Reply);
    incrementarContadorMensagens; // counter
    +Reply;
    !reservar(Id, Data).

-!reservar(Id, Data) <-
    .print("Erro ao reservar, saldo insuficiente");
    !pedirEmprestimo;
    !reservar(Id, Data);
    +semSaldo.

// --- USAR RESERVA ---

+!escolherReserva(Lista) <-
    if (.empty(Lista)) {
        .print("Nenhuma reserva disponivel");
        .fail;
    }
    .length(Lista, Tam);
    .random(X);
    Indice = math.floor(Tam*X);
    .nth(Indice, Lista, ReservaId);
    .print("Reserva escolhida: ", ReservaId);
    +reservaEscolhida(ReservaId).


+!usarReserva : chainServer(Server) & myWallet(PrK, PuK)
            & managerWallet(ManagerW) & reservaEscolhida(ReservaId) <-
    .print("Escolha de reserva: ", ReservaId);
    .velluscinum.transferNFT(Server, PrK, PuK, ReservaId, ManagerW,
            "description:Using Reservation", usoReserva);
    .wait(usoReserva(TransactionId));
    .send(manager, tell, querUsarReserva(ReservaId, TransactionId));
    incrementarContadorMensagens. // counter

// -- VENDER RESERVA --
+reservaAVenda(ReservaId, DriverWallet)[source(Motorista)] : reservasDeMotoristas(Lista) <- 
    .print("Reserva a venda: ", ReservaId);
    -+reservasDeMotoristas([[Motorista, ReservaId, DriverWallet] | Lista]);
    .abolish(reservaAVenda(_,_)).

+reservaAVenda(ReservaId, DriverWallet)[source(Motorista)] : not reservasDeMotoristas(Lista) <- 
    .print("Reserva a venda: ", ReservaId);
    +reservasDeMotoristas([[Motorista, ReservaId, DriverWallet]]);
    .abolish(reservaAVenda(_,_)).

+!interesseCompraReserva(ReservaId, Motorista): minhasReservasAVenda(ListaReservas) 
                & not(.empty(ListaReservas) | negociacaoEmAndamento) <-
    ?myWallet(PrK, PuK);
    if (.member(ReservaId, ListaReservas)) {
        .print("------------------> Motorista interessado em comprar reserva: ", ReservaId);
        +negociacaoEmAndamento;
        // .delete(ReservaId, ListaReservas, NovaLista);
        // .print("Lista original: ", ListaReservas);
        // .print("Item removido: ", ReservaId);
        // .print("Nova lista: ", NovaLista);
        // -+minhasReservasAVenda(NovaLista);
        .send(Motorista, achieve, prosseguirCompra(ReservaId, PuK));
        incrementarContadorMensagens; // counter
    } else {
        .print("------------------> ReservaId não está em ListaReservas: ", ReservaId);
    }.

-!interesseCompraReserva(ReservaId, Motorista) : negociacaoEmAndamento 
                & minhasReservasAVenda(ListaReservas) & not(.empty(ListaReservas)) <-
    if (not(.member(ReservaId, ListaReservas))) {
        .print("------------------> ReservaId não está em ListaReservas: ", ReservaId);
        .fail;
    };
    .wait(6000);
    !interesseCompraReserva(ReservaId, Motorista).

-!interesseCompraReserva(ReservaId, Motorista) <-
    .print("Erro ao comprar reserva");
    .send(Motorista, tell, prosseguirCompra(fail));
    incrementarContadorMensagens. // counter

+!porReservaAVenda: reservaEscolhida(ReservaId) & minhasReservasAVenda(ListaReservas) & myWallet(PrK, PuK) <-
    !atualizarReservasAVenda(ReservaId);
    .print("Colocando reserva a venda -> ", ReservaId);
    .broadcast(tell, reservaAVenda(ReservaId, PuK));
    .wait(3000);
    !recomecar.

+!porReservaAVenda: reservaEscolhida(ReservaId) <-
    !atualizarReservasAVenda(ReservaId);
    !recomecar.

+!atualizarReservasAVenda(NovaReserva) : minhasReservasAVenda(ListaReservas) & listaNFTs(NFTs) <-
    .member(NovaReserva, ListaReservas);
    .print("Reserva ja esta a venda");
    !recomecar.

+!atualizarReservasAVenda(NovaReserva) : not(minhasReservasAVenda(ListaReservas)) & myWallet(PrK, PuK) <-
    .print("Colocando reserva a venda -> ", NovaReserva);
    .broadcast(tell, reservaAVenda(NovaReserva, PuK));
    +minhasReservasAVenda([NovaReserva]).

+!atualizarReservasAVenda(NovaReserva) : minhasReservasAVenda(ListaReservas) & not(.member(NovaReserva, ListaReservas)) & myWallet(PrK, PuK) <-
    .print("Colocando reserva a venda -> ", NovaReserva);
    .broadcast(tell, reservaAVenda(NovaReserva, PuK));
    -+minhasReservasAVenda([NovaReserva|ListaReservas]).

-!atualizarReservasAVenda(NovaReserva).

+!reservaPaga(TransacaoId, ReservaId, MotoristaW)[source(Motorista)] : myWallet(PrK, PuK) & chainServer(Server) <-
    .print("Reserva paga: ", ReservaId);
    // !stampProcess(TransacaoId);
    .print("Server: ", Server);
    .print("PrK: ", PrK);
    .print("PuK: ", PuK);
    .print("TransacaoId: ", TransacaoId);
    .print("000000000000000000000000000000000000000000000");
    // .wait(100000); // timer
    .velluscinum.stampTransaction(Server, PrK, PuK, TransacaoId);
    !enviarReserva(ReservaId, MotoristaW, Motorista).

-!reservaPaga(Id)[source(Motorista)] <-
    .print("XXXXXXXXXXXXXXXXX Erro ao validar reserva XXXXXXXXXXXXXXXXX");
    .send(Motorista, tell, reservaNFT(fail)).

+!enviarReserva(ReservaId, Carteira, Motorista) : chainServer(Server) & myWallet(PrK, PuK) <-
    .print("Enviando reserva: ", ReservaId);
    .velluscinum.transferNFT(Server, PrK, PuK, ReservaId, Carteira,
            "description:Sending Reservation", envioReserva);
    .wait(envioReserva(IdTransacao));
    .send(Motorista, tell, reservaNFT(ReservaId, IdTransacao));
    incrementarContadorMensagens; // counter
    ?listaNFTs(Lista);
    .delete(ReservaId, Lista, NovaLista);
    -+listaNFTs(NovaLista);
    .abolish(negociacaoEmAndamento).

// -- COMPRAR RESERVA MOTORISTA --
+!escolherReservaMotorista(Lista) <-
    if (.empty(Lista)) {
        .print("Nenhuma reserva disponível");
        .fail;
    }
    .length(Lista, Tam);
    .random(X);
    Indice = math.floor(Tam * X);
    .nth(Indice, Lista, Tupla);
    Tupla = [Motorista, ReservaId, DriverWallet];
    .print("Reserva escolhida: ", ReservaId, " Motorista: ", Motorista, " Carteira: ", DriverWallet);
    .my_name(Me);
    .send(Motorista, achieve, interesseCompraReserva(ReservaId, Me));
    incrementarContadorMensagens. // counter

+!prosseguirCompra(ReservaId, DriverWallet)[source(Motorista)] : chainServer(Server) 
                & myWallet(PrK, PuK) & cryptocurrency(Coin) <-
    .print("Proseguindo com a compra");
    .velluscinum.tokenInfo(Server, ReservaId, data, nftInfo);
    .wait(nftInfo(Info));
    !extrairDadosReserva(Info, Duracao, TipoVaga);
    !consultarPreco(TipoVaga);
    ?precoTabela(Preco);
    stringToNumber(Duracao, DuracaoNum);
    Valor = math.ceil(Preco * DuracaoNum / 60);
    .print("Preco calculado: ", Valor);
    .velluscinum.transferToken(Server, PrK, PuK, Coin, DriverWallet, Valor, pagamento);
    .wait(pagamento(TransacaoId));
    .print("Pagamento realizado para: ", DriverWallet);
    .print("TransacaoId: ", TransacaoId);
    .send(Motorista, achieve, reservaPaga(TransacaoId, ReservaId, PuK));
    incrementarContadorMensagens. // counter

-!prosseguirCompra(ReservaId, DriverWallet) <-
    .print("Erro ao prosseguir com a compra").

+!extrairDadosReserva(Info, Duracao, TipoVaga) <-
    .print("Info: ", Info);
    .nth(1, Info, CampoDuracao);
    .nth(1, CampoDuracao, Duracao);
    .nth(3, Info, CampoTipoVaga);
    .nth(1, CampoTipoVaga, TipoVaga).

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

+!estacionarReserva(VagaId)[source(manager)] <-
    .print("--------------------------------------------------------------");
    .print("Estacionando veiculo na vaga ", VagaId);
    +estacionado(VagaId);
    .wait(3000);
    // .abolish(tempoUso(_));
    .send(manager, tell, querSair(VagaId));
    incrementarContadorMensagens. // counter

+!sairEstacionamento : true <-
    .print("Saindo da vaga");
    .abolish(estacionado(_));
    .print("--------------------------------------------------------------");
    !recomecar.
