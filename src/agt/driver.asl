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
// tiposDeVaga(["Curta"]).
mensagensEnviadas(0).

/* Initial goals */
!comecar.

/* Plans */

+decisao(X) <- .print("Escolha ----> ", X).

+!vagaDisponivel(Status, IdVaga) : Status == true <-
    .wait(3000);
    +idVaga(IdVaga);
    ?decisao(EscolhaDriver);
    ?dataUso(Data);
    incNegociacoes;
    if (EscolhaDriver == "COMPRA") {
        .send(manager, achieve, motoristaQuerEstacionar(IdVaga));
        !incMensagensEnviadas;
    } elif (EscolhaDriver == "RESERVA") {
        !reservar(IdVaga, Data);
    }.

-!vagaDisponivel(Status, IdVaga) : Status == true <-
    .wait(3000);
    !vagaDisponivel(Status, IdVaga).

+!vagaDisponivel(Status, IdVaga) : Status == false <-
    .print("Vaga indisponivel, aguardando...");
    .wait(5000);
    !resetar;
    // .wait(30000);
    !escolher.

+reservaNFT(ReservaId, TransferId) : listaNFTs(Lista) <- 
    .print("Reserva recebida -> ", ReservaId);
    !stampProcess(TransferId);
    -+listaNFTs([ReservaId|Lista]);
    incNegociacoesBemSucedidas;
    .abolish(reservaNFT(_,_));
    !recomecar.

+reservaNFT(ReservaId, TransferId) : not listaNFTs(Lista) <- 
    .print("Reserva recebida -> ", ReservaId);
    !stampProcess(TransferId);
    +listaNFTs([ReservaId]);
    incNegociacoesBemSucedidas;
    .abolish(reservaNFT(_,_));
    !recomecar.

+reservaNFT(fail) <- 
    .print("Erro ao receber reserva");
    !recomecar.

+!incMensagensEnviadas : mensagensEnviadas(Num) <-
    -+mensagensEnviadas(Num+1).

+!comecar <-
    joinWorkspace("network");
	lookupArtifact("utils", UtilsId);
    focus(UtilsId);
    incCiclosMotoristas;
    .wait(estacionamentoAberto);
    .send(manager, askOne, precoTabelaVagas(Tabela), TabelaVagas);
    !incMensagensEnviadas;
    .wait(2000);
    +TabelaVagas;
    !criarCarteira;
    !obterConteudoCarteira;
    .wait(coinBalance(Balance));
    .send(manager, askOne, managerWallet(Manager), Reply);
    !incMensagensEnviadas;
    .wait(1000);
    +Reply;
    !escolher.

+!recomecar <-
    !resetar;

    !obterConteudoCarteira;
    .wait(coinBalance(Balance));

    incCiclosMotoristas;
    !escolher.

+!resetar <-
    .abolish(decisao(_));
    .abolish(content(_));
    .abolish(reservaEscolhida(_));
    .abolish(vagaOcupada(_));
    .abolish(decisaoReserva(_));
    .abolish(dataUso(_));
    .abolish(tipoVaga(_));
    .abolish(idVaga(_));
    .abolish(precoVaga(_));
    .abolish(valorAPagarUso(_));
    .abolish(tempoUso(_)).

+!escolher <-
    !definirTipoVaga;
    ?tipoVaga(Tipo);
    .random(R);
    if (R < -.5) {
        +decisao("COMPRA");
        +dataUso("now");
        !comecarNegociacao;
    } else {
        +decisao("RESERVA");
        .random(R2);
        .print(R2);
        !decidirReserva(R2);
    }.

+!definirTipoVaga : tiposDeVaga(Tipos) <-
    .length(Tipos, Tam);
    .random(X);
    Indice = math.floor(Tam*X);
    .nth(Indice, Tipos, Item);
    +tipoVaga(Item).

+!decidirReserva(R2) : listaNFTs(Lista) & R2 < .5 <-
    .random(R);
    !escolherReserva(Lista);
    ?reservaEscolhida(ReservaId);
    if (R < 1) {
        .print("usar");
        +decisaoReserva("USAR");
        !usarReserva;
    } else {
        .print("vender");
        +decisaoReserva("VENDER");
        !porReservaAVenda;
    }.

+!decidirReserva(R2) : not listaNFTs(Lista) | (R2 >= .5 & R2 <= 1) <-
    .random(R);
    if (R < 1) {
        .print("Reservar gerente");
        +decisaoReserva("RESERVAR");
        !decidirDataETempo;
        !comecarNegociacao;
    } else {
        .print("Reservar motorista");
        +decisaoReserva("RESERVARMOTORISTA");
        !verificarReservasDeMotoristas;
    }.

-!decidirReserva(R2) : not reservaEscolhida(ReservaId) <-
    !recomecar.

-!decidirReserva <- 
    .print("Plano de reserva falhou").

+!verificarReservasDeMotoristas : reservasDeMotoristas(Lista) <-
    .length(Lista, Tam);
    if (Tam > 0) {
        .print("Reservas disponiveis a venda: ", Lista);
        !escolherReservaMotorista(Lista);
    } else {
        .abolish(reservasDeMotoristas(_));
        !verificarReservasDeMotoristas;
    }.

+!verificarReservasDeMotoristas <-
    .print("Nenhuma reserva de motorista disponivel");
    !recomecar.

+!decidirDataETempo <-
    ?datasReservas(Datas);
    .length(Datas, Tam);
    .random(X);
    Indice = math.floor(Tam*X);
    .nth(Indice, Datas, Data);
    +dataUso(Data);
    
    .random(Y);
    Min = math.floor(Y*100+20);
    +tempoUso(Min).

+!comecarNegociacao[source(self)] : tipoVaga(Tipo) <-
    !consultarPreco(Tipo);
    ?precoTabela(Preco);
    ?dataUso(Data);
    
    .print("Tipo da vaga: ", Tipo);
    .print("Data de uso: ", Data);
    
    !consultar.

-!comecarNegociacao <- .print("Erro ao comecar negociacao").

+!consultarPreco(TipoVaga) : precoTabelaVagas(Tabela) <-
    .member([TipoVaga, Preco], Tabela);
    -+precoTabela(Preco).

// ----------------- ACOES CARTEIRA -----------------

+driverWallet(PuK) <- 
    .send(manager, tell, driverWallet(PuK));
    !incMensagensEnviadas.

+!criarCarteira : not myWallet(PrK,PuK) <-
    .print("Obtendo carteira digital...");
    .velluscinum.loadWallet(myWallet);
	incContadorTransacoesVellus;
	.wait(myWallet(PrK,PuK));
    +driverWallet(PuK);
    
    .send(bank, askOne, chainServer(Server), Chain);
    !incMensagensEnviadas;
    .wait(2000);
    +Chain;
    .send(bank, askOne, bankWallet(BankW), Wallet);
    !incMensagensEnviadas;
    .wait(2000);
    +Wallet;
    .send(bank, askOne, cryptocurrency(Coin), ReplyCoin);
    !incMensagensEnviadas;
    .wait(2000);
    +ReplyCoin.

+!obterConteudoCarteira : chainServer(Server) & myWallet(PrK, PuK)
                & cryptocurrency(Coin) <-
    .abolish(listaNFTs(_));
    .abolish(coinBalance(_));
    .print("Obtendo conteudo da carteira...");
    .velluscinum.walletContent(Server, PrK, PuK, content);
	incContadorTransacoesVellus;
    .wait(content(Content));
    !findToken(Coin, set(Content));
    !findToken(nft, set(Content)).

+!findToken(Term,set([Head|Tail])) <- 
    !compare(Term,Head,set(Tail));
    !findToken(Term,set(Tail)).

+!compare(Term,[Type, AssetId, Qtd],set(V)) : (Term == AssetId) <- 
	+coinBalance(Qtd);
    .print("Saldo atual: ", Qtd).

+!compare(Term,[Type,AssetId,Qtd],set(V)) : (Term == Type) & listaNFTs(Lista) <-    
    // .print("Type: ", Type, " ID: ", AssetId);
    -+listaNFTs([AssetId|Lista]).

+!compare(Term,[Type,AssetId,Qtd],set(V)) : (Term == Type) & not listaNFTs(Lista) <-
    // .print("Type: ", Type, " ID: ", AssetId);
    .concat(AssetId, Lista);
    +listaNFTs([Lista]).

-!compare(Term,[Type,AssetId,Qtd],set(V)).

-!findToken(Type,set([   ])) : not coinBalance(Amount) <- 
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

	.velluscinum.deployNFT(Server, PrK, PuK, Dados,
                "description:Creating Bank Account", account);
	incContadorTransacoesVellus;
	.wait(account(AssetId));

	.velluscinum.transferNFT(Server, PrK, PuK, AssetId, BankW,
				"description:requesting lend;value_chainCoin:100",requestID);
	incContadorTransacoesVellus;
	.wait(requestID(PP));
	
	.send(bank, achieve, lending(PP, PuK, 100));
    !incMensagensEnviadas;
    .wait(bankAccount(ok));
    .abolish(pedindoEmprestimo);
    !obterConteudoCarteira.

+!pedirEmprestimo(Valor)[source(self)] : cryptocurrency(Coin) & bankWallet(BankW) 
            & chainServer(Server) & myWallet(PrK,PuK)
            & not pedindoEmprestimo <-
    // .print("dinheiro acabou, pedindo emprestimo");
    +pedindoEmprestimo;
    .abolish(bankAccount(_));

    if (emprestimoCount(Num)) {
        -+emprestimoCount(Num+1);
    } else {
        +emprestimoCount(1);
    }

	// .print("Pedindo emprestimo, valor: ", Valor);
    ?emprestimoCount(Num);
    .concat("nome:motorista;emprestimo:", Num, Data);
	.velluscinum.deployNFT(Server, PrK, PuK, Data,
                "description:Creating Bank Account", account);
	incContadorTransacoesVellus;
	.wait(account(AssetId));

    .concat("description:requesting lend;value_chainCoin:", Valor, Descricao);
	.velluscinum.transferNFT(Server, PrK, PuK, AssetId, BankW, Descricao, requestID);
	incContadorTransacoesVellus;
	.wait(requestID(PP));
	
	// .print("Lend Contract nr:", PP);
	.send(bank, achieve, lending(PP, PuK, Valor));
    !incMensagensEnviadas;
    .wait(bankAccount(ok));
    .abolish(pedindoEmprestimo).

+!pedirEmprestimo : pedindoEmprestimo <- .print("Ja esta pedindo emprestimo").

-!pedirEmprestimo <-
    // .print("Erro ao pedir emprestimo");
    .wait(5000);
    !pedirEmprestimo.

// ----- VALIDACAO -----
+!stampProcess(TransactionId)[source(self)] : chainServer(Server) & myWallet(PrK,PuK) <-
    .print("Validando transferencia...");
    .velluscinum.stampTransaction(Server, PrK, PuK, TransactionId);
	incContadorTransacoesVellus.

-!stampProcess(TransactionId) <- 
    // .print("Erro ao validar transferencia, tentando novamente");
    .wait(3000);
    !stampProcess(TransactionId).

// -------------------- CENARIOS --------------------
// ----- USO -----

+vagaOcupada(Id)[source(manager)] <-
    // .print("Vaga ocupada");
    !estacionar(Id, Tempo);
    !comprar(Tempo).

+valorAPagarUso(Value)[source(manager)] <- !pagarUso(Value).

+!consultar[source(self)] : tipoVaga(Tipo) & decisao(EscolhaDriver) 
            & EscolhaDriver == "COMPRA" <-
    .print("Consultando vaga...");
    .send(manager, achieve, consultarVaga(Tipo));
    !incMensagensEnviadas.

+!comprar(Tempo) : tipoVaga(Tipo) <- 
    // .print("Pagamento da vaga");
    .send(manager, achieve, pagamentoUsoVaga(Tipo, Tempo));
    !incMensagensEnviadas.

-!comprar(Tempo) <-
    .print("Erro ao comprar vaga").
    // !recomecar.

+!pagarUso(Valor) : not managerWallet(Manager) <-
    .wait(5000);
    .send(manager,askOne,managerWallet(Manager),Reply);
    !incMensagensEnviadas;
    +Reply;
    !pagarUso(Valor).

+!pagarUso(Valor) : cryptocurrency(Coin) & chainServer(Server)
            & myWallet(PrK,PuK) & managerWallet(Manager) 
            & (coinBalance(Balance) & (Balance >= Valor))<-
    .print("Pagamento em andamento...");
    ?idVaga(Id);
    .velluscinum.transferToken(Server,PrK,PuK,Coin,Manager,Valor,payment);
	incContadorTransacoesVellus;
    .wait(payment(TransactionId));
    .send(manager, achieve, validarPagamento(TransactionId, Id));
    !incMensagensEnviadas;
    .abolish(payment(_)).

+!pagarUso(Valor) : cryptocurrency(Coin) & chainServer(Server)
            & myWallet(PrK,PuK) & managerWallet(Manager) 
            & (coinBalance(Balance) & (Balance < Valor))<-
    .print("Saldo insuficiente");
    !pedirEmprestimo;
    !pagarUso(Valor).

+!estacionar(Id, Tempo)[source(self)] : coinBalance(Balance) & precoTabela(Price) <-
    .print("Estacionando veiculo na vaga ", Id);
    tempoEstacionado(Tempo, Balance, Price);
    .wait(Tempo*10).

// ----- RESERVAR -----

+!consultar[source(self)] : tipoVaga(Tipo) & dataUso(Data) & tempoUso(Min) 
            & decisaoReserva(EscolhaReserva) & EscolhaReserva == "RESERVAR" <-
    .print("Consultando reserva...");
    .send(manager, achieve, consultarReserva(Tipo, Data, Min));
    !incMensagensEnviadas.

+!reservar(Id, Data) : tempoUso(Min) & chainServer(Server) & myWallet(PrK,PuK) 
            & cryptocurrency(Coin) & managerWallet(Manager) <- 
    .print("Pagando reserva: ", Id);
    ?precoTabela(Preco);
    .velluscinum.transferToken(Server, PrK, PuK, Coin, Manager, Preco, payment);
	incContadorTransacoesVellus;
    .wait(payment(TransactionId));
    .send(manager, achieve, motoristaPagouReserva(TransactionId, Id, Data, Min));
    !incMensagensEnviadas.

+!reservar(Id, Data) : not managerWallet(Manager) <-
    .wait(5000);
    .send(manager,askOne,managerWallet(Manager),Reply);
    !incMensagensEnviadas;
    +Reply;
    !reservar(Id, Data).

-!reservar(Id, Data) <-
    .print("Erro ao reservar, saldo insuficiente");
    !pedirEmprestimo;
    !reservar(Id, Data);
    +semSaldo.

// --- USAR RESERVA ---

+!escolherReserva(Lista) <-
    .length(Lista, Tam);
    if (Tam <= 0) {
        .print("Nenhuma reserva disponivel");
        .fail;
    }
    .random(X);
    Indice = math.floor(Tam*X);
    .nth(Indice, Lista, ReservaId);
    !verificarReservasAVenda(ReservaId).

-!escolherReserva(Lista) <-
    .print("Erro ao escolher reserva").

+!verificarReservasAVenda(ReservaId) : minhasReservasAVenda(Lista) <-
    .member(ReservaId, Lista);
    .print("Essa reserva esta a venda").

-!verificarReservasAVenda(ReservaId) : minhasReservasAVenda(Lista) <-
    .print("Reserva escolhida: ", ReservaId);
    +reservaEscolhida(ReservaId).

+!verificarReservasAVenda(ReservaId) : not minhasReservasAVenda(Lista) <-
    .print("Reserva escolhida: ", ReservaId);
    +reservaEscolhida(ReservaId).

+!usarReserva : chainServer(Server) & myWallet(PrK, PuK)
            & managerWallet(ManagerW) & reservaEscolhida(ReservaId) <-
    incNegociacoes;
    .print("Escolha de reserva: ", ReservaId);
    .velluscinum.transferNFT(Server, PrK, PuK, ReservaId, ManagerW,
            "description:Using Reservation", usoReserva);
	incContadorTransacoesVellus;
    .wait(usoReserva(TransactionId));
    .send(manager, achieve, motoristaQuerUsarReserva(ReservaId, TransactionId));
    !incMensagensEnviadas.

// -- VENDER RESERVA --
+reservaAVenda(ReservaId, DriverWallet)[source(Motorista)] : reservasDeMotoristas(Lista) <- 
    // .print("Reserva a venda: ", ReservaId);
    -+reservasDeMotoristas([[Motorista, ReservaId, DriverWallet] | Lista]);
    .abolish(reservaAVenda(_,_)).

+reservaAVenda(ReservaId, DriverWallet)[source(Motorista)] : not reservasDeMotoristas(Lista) <- 
    // .print("Reserva a venda: ", ReservaId);
    +reservasDeMotoristas([[Motorista, ReservaId, DriverWallet]]);
    .abolish(reservaAVenda(_,_)).

+!interesseCompraReserva(ReservaId, Motorista): minhasReservasAVenda(ListaReservas) 
                & not(.empty(ListaReservas) | negociacaoEmAndamento) <-
    incNegociacoes;
    ?myWallet(PrK, PuK);
    if (.member(ReservaId, ListaReservas)) {
        .print("Motorista interessado em comprar reserva: ", ReservaId);
        +negociacaoEmAndamento;
        
        .velluscinum.tokenInfo(Server, ReservaId, data, nftInfo);
	    incContadorTransacoesVellus;
        .wait(nftInfo(Info));
        !extrairDadosReserva(Info, Duracao, TipoVaga);
        !consultarPreco(TipoVaga);
        ?precoTabela(Preco);
        stringToNumber(Duracao, DuracaoNum);
        Valor = math.ceil(Preco * DuracaoNum / 60);
        
        .send(Motorista, achieve, prosseguirCompra(ReservaId, PuK, Valor));
        !incMensagensEnviadas;
    } else {
        .print("Reserva não está em ListaReservas: ", ReservaId);
    }.

-!interesseCompraReserva(ReservaId, Motorista) : negociacaoEmAndamento 
                & minhasReservasAVenda(ListaReservas) & not(.empty(ListaReservas)) <-
    if (not(.member(ReservaId, ListaReservas))) {
        .print("Reserva não está em ListaReservas: ", ReservaId);
        .fail;
    };
    .wait(6000);
    !interesseCompraReserva(ReservaId, Motorista).

-!interesseCompraReserva(ReservaId, Motorista) <-
    .print("Erro ao comprar reserva");
    .send(Motorista, tell, prosseguirCompra(fail));
    !incMensagensEnviadas.

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
    // .velluscinum.stampTransaction(Server, PrK, PuK, TransacaoId);
    !enviarReserva(ReservaId, MotoristaW, Motorista).

-!reservaPaga(Id)[source(Motorista)] <-
    .send(Motorista, tell, reservaNFT(fail)).

+!enviarReserva(ReservaId, Carteira, Motorista) : chainServer(Server) & myWallet(PrK, PuK) <-
    .print("Enviando reserva: ", ReservaId);
    .concat("description:Sending Reservation;reservation:", ReservaId, Descricao);
    .velluscinum.transferNFT(Server, PrK, PuK, ReservaId, Carteira, Descricao, envioReserva);
	incContadorTransacoesVellus;
    .wait(envioReserva(IdTransacao));
    .send(Motorista, tell, reservaNFT(ReservaId, IdTransacao));
    !incMensagensEnviadas;
    ?listaNFTs(Lista);
    .delete(ReservaId, Lista, NovaLista);
    -+listaNFTs(NovaLista);
    .abolish(negociacaoEmAndamento).

-!enviarReserva(ReservaId, Carteira, Motorista) : chainServer(Server) & myWallet(PrK, PuK) 
                & not listaNFTs(Lista) <-
    .abolish(negociacaoEmAndamento).

-!enviarReserva(ReservaId, Carteira, Motorista) <-
    .print("Erro ao enviar reserva").

// -- COMPRAR RESERVA MOTORISTA --
+!escolherReservaMotorista(Lista) <-
    .length(Lista, Tam);
    if (Tam <= 0) {
        .print("Nenhuma reserva disponivel");
        .fail;
    }
    .random(X);
    Indice = math.floor(Tam * X);
    .nth(Indice, Lista, Tupla);
    Tupla = [Motorista, ReservaId, DriverWallet];
    // .print("Reserva escolhida: ", ReservaId, " Motorista: ", Motorista, " Carteira: ", DriverWallet);
    .my_name(Me);
    .send(Motorista, achieve, interesseCompraReserva(ReservaId, Me));
    !incMensagensEnviadas.

-!escolherReservaMotorista(Lista) <-
    .print("Nenhuma reserva disponível").

+!prosseguirCompra(ReservaId, DriverWallet, Valor)[source(Motorista)] : chainServer(Server) 
                & myWallet(PrK, PuK) & cryptocurrency(Coin) <-
    .print("Servidor: ", Server);
    .print("Carteira: ", DriverWallet);
    .print("Valor: ", Valor);
    .print("Reserva: ", ReservaId);
    .velluscinum.transferToken(Server, PrK, PuK, Coin, DriverWallet, Valor, pagamento);
	incContadorTransacoesVellus;
    .wait(pagamento(TransacaoId));
    .print("Pagamento realizado para: ", DriverWallet);
    .send(Motorista, achieve, reservaPaga(TransacaoId, ReservaId, PuK));
    !incMensagensEnviadas.

-!prosseguirCompra(ReservaId, DriverWallet, Valor) <-
    .print("Erro ao prosseguir com a compra").

+!extrairDadosReserva(Info, Duracao, TipoVaga) <-
    // .print("Info: ", Info);
    .nth(1, Info, CampoDuracao);
    .nth(1, CampoDuracao, Duracao);
    .nth(3, Info, CampoTipoVaga);
    .nth(1, CampoTipoVaga, TipoVaga).

// ----------------- ESTACIONAR E DEIXAR ESTACIONAMENTO -----------------
+!estacionarReserva(VagaId)[source(manager)] <-
    .print("Estacionando veiculo na vaga ", VagaId);
    // incNegociacoesBemSucedidas;
    +estacionado(VagaId);
    .wait(3000);
    .send(manager, achieve, motoristaQuerSair(VagaId));
    !incMensagensEnviadas.

+!sairEstacionamento <-
    incNegociacoesBemSucedidas;
    .print("Saindo da vaga");
    .abolish(estacionado(_));
    !recomecar.
