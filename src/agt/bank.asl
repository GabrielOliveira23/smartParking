// Agent bank in project chefBankGlutton
/* Initial beliefs and rules */
chainServer("http://testchain.chon.group:9984/").

/* Initial goals */
!carregarCarteira.

/* Plans */
+!carregarCarteira: chainServer(Server) <-
	.broadcast(tell, chainServer(Server));
	.print("Obtendo carteira digital");
	velluscinum.loadWallet(myWallet);
	.wait(myWallet(PrK,PuK));
	.broadcast(tell, bankWallet(PuK));

	velluscinum.walletContent(Server, PrK, PuK, content);
    .wait(content(Content));
	!findToken(token, set(Content));
	.wait(smartCoin(Coin));
	.broadcast(tell, cryptocurrency(Coin)).

+!findToken(Term,set([Head|Tail])) <- 
    !compare(Term,Head,set(Tail));
    !findToken(Term,set(Tail)).

+!compare(Term,[Type,AssetID, Qtd],set(V)): (Term  == Type) | (Term == AssetID) <- 
    .print("Type: ", Type, " ID: ", AssetID," Qtd: ", Qtd);
	+smartCoin(AssetID);
	+smartCoinBalance(Qtd).

-!compare(Term,[Type,AssetID,Qtd],set(V)) <- .print("The Asset ",AssetID, " is not a ",Term).

-!findToken(Type,set([   ])): not smartCoin(Coin) <- 
	.print("Moeda Nao encontrada");
	!criarMoeda.

-!findToken(Type,set([   ])): smartCoin(Coin) <- 
	.print("Moeda ja na carteira").
	
+!criarMoeda: chainServer(Server) & myWallet(PrK, PuK) <- 
	.print("Criando moeda");
	velluscinum.deployToken(Server, PrK, PuK, "name:smartCoin", 200, smartCoin);
	.wait(smartCoin(Coin)).

+!lending(ResquestNumber,ClientWallet,Value)[source(Client)]: 
			smartCoin(Coin) & smartCoinBalance(Amount) & myWallet(PrK,PuK) & chainServer(Server) <-
	.print("Olá agente ",Client,", Bem vindo ao SmartBank! - Por favor espere enquanto validamos a transferência.");
	velluscinum.stampTransaction(Server,PrK,PuK,ResquestNumber,loan(Client));
	if (Amount >= Value) {
		.print("Transferência validada. Aguarde enquanto processamos a transação.");
		velluscinum.transferToken(Server,PrK,PuK,Coin,ClientWallet,Value,transactionTransfer);
		.print("Transação processada com sucesso. Obrigado por escolher o SmartBank!");
		.send(Client,tell,bankAccount(ok));
	} else {
		.print("Não há saldo suficiente para esta moeda. Transação cancelada. Obrigado por escolher o SmartBank!");
		.send(Client,tell,bankAccount(fail));
	}.
