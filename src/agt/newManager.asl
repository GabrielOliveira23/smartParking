{ include("$jacamo/templates/common-cartago.asl") }
{ include("$jacamo/templates/common-moise.asl") }

/* Initial beliefs */
+listaVagas([ ]).

/* Initial goals */
!criarCarteira.

/* plans */

// ----------------------------- COMMONS ------------------------------

+vagaDisponivel(Status) <- .send(driver, tell, vagaDisponivel(Status)).

+idVaga(Id) <- .send(driver, tell, idVaga(Id)).

+!consultarVaga(TipoVaga, Data, Intencao)[source(driver)]: listaVagas(Lista) <-
	.send(driver, askOne, driverWallet(DriverW), Reply);
	.wait(3000);
	+Reply;
	+driverIntention(Intencao);
	!verificarDisponibilidade(TipoVaga, Data, Intencao, set(Lista)).

+!consultarVaga(TipoVaga, Data, Intencao)[source(driver)] : not listaVagas(Vagas) <-
	.print("Estacionamento fechado!").

+!verificarDisponibilidade(TipoVaga, Data, Intencao, set([Head|Tail])): chainServer(Server) & not vagaDisponivel(X) <-
	.print("Verificando disponibilidade...");
	.print("Vaga -> ", Head);
	velluscinum.tokenInfo(Server, Head, all, content);
	.wait(content(Metadata));
	verificarVaga(TipoVaga, Data, Intencao, Metadata);
	?vagaDisponivel(X);
	+idVaga(Head).

-!verificarDisponibilidade(TipoVaga, Data, Intencao, set([Head|Tail])): chainServer(Server) <-
	!verificarDisponibilidade(TipoVaga, Data, Intencao, set(Tail)).

-!verificarDisponibilidade(TipoVaga, Data, Intencao, set([ ])) <-
	+vagaDisponivel(false);
	.print("percorreu todas as vagas").

// -------------------------- COMPRA DIRETA ---------------------------

+valorAPagarUso(Valor) <- .send(driver, tell, valorAPagarUso(Valor)).

+querEstacionar(Id)[source(driver)] <- !ocuparVaga(Id).

+!pagamentoUsoVaga(Tipo, Minutos)[source(driver)] : driverWallet(DriverW) <-
	.print("Calculando valor...");
	calcularValorAPagarUso(Tipo, Minutos).

// -------------------------- COMPRAR RESERVA -------------------------

+pagouReserva(TransactionId, IdVaga, Data, Tempo)[source(driver)] <-
	.print("Validando pagamento...");
	!stampProcess(TransactionId);
	!sendReservation(IdVaga, Data, Tempo).

+!sendReservation(Id, Date, Tempo)[source(self)] : chainServer(Server) & myWallet(PrK, PuK)
			& driverWallet(DriverW) <-
	.print("Reservando vaga...");
	velluscinum.tokenInfo(Server, Id, metadata, content);
	.wait(content(Content));
	verificarReserva(Content);
	getCurrentStatus(Content);
	.wait(currentStatus(Status));

	.concat("status:", Status, ";reservation:", Id, ";date:", Date, Data);
	.concat("description:vacancy reservation", Descricao);
	velluscinum.deployNFT(Server, PrK, PuK, Data, Descricao, nft);
	.wait(nft(ReservaId));
	
	!ocuparVaga(Id, Date, Tempo, Status, ReservaId);
	?ocupation(OcupationId);

	.concat("reservation:", Id, ";date:", Date, ";time:", Tempo, DescricaoReserva);
	velluscinum.transferNFT(Server, PrK, PuK, ReservaId, DriverW, DescricaoReserva, transfer);
	.wait(transfer(TransferId));
	
	.print("Reserva transferida para motorista");
	.send(driver, tell, reservaNFT(ReservaId, TransferId)).

+!sendReservation(Id, Date, Tempo)[source(self)] : not driverWallet(DriverW) <-
	.send(driver, askOne, driverWallet(DriverW), Reply);
	.wait(3000);
	+Reply;
	!sendReservation(Id, Date, Tempo).

-!sendReservation(Id, Date, Tempo)[source(self)] <-
	.print("Nao foi possivel reservar a vaga").

+!ocuparVaga(Id, Data, Tempo, Status, ReservaId) : chainServer(Server) & myWallet(PrK, PuK)
			& (reservaDisponivel(X) & (X == true)) <-
	.print("Ocupando Vaga...");
	.print("Id -> ", Id);
	.print("Data -> ", Data);
	.concat("status:", Status, ";reservationId:", ReservaId, 
			";reservationDate:", Data, ";reservationTime:", Tempo, Metadata);
	velluscinum.transferNFT(Server, PrK, PuK, Id, PuK, Metadata, ocupation);
	.wait(ocupation(OcupationId));
	.print("Vaga Ocupada!").

// -------------------------- USO DA RESERVA --------------------------

+querUsarReserva(AssetId, TransactionId) <- 
	!validarReserva(AssetId);
	!stampProcess(TransactionId);
	.send(driver, achieve, park).

+!validarReserva(AssetId) : chainServer(Server) & myWallet(PrK, PuK)
			& listaVagas(Lista) <-
	.print("Validando reserva...");
	acharReserva(AssetId, Lista).

// ---------------------- NEGOCIACAO DA RESERVA -----------------------

+reservationAvailable(Type,Date,Min)[source(driver)] <-
	.print("Motorista colocou reserva disponivel").

// ---------------------------- AUXILIARES ----------------------------

+reservationUse(TransactionId) <- !stampProcess(TransactionId);
	.print("reserva usada");
	.send(driver, achieve, park).

+!validarPagamento(Transfer, IdVaga)[source(driver)] :  driverIntention(Intention) <-
	!stampProcess(Transfer);
	.print("Vaga paga!");
	!liberarVaga(IdVaga).

+!stampProcess(Transfer)[source(self)] : chainServer(Server) 
            & myWallet(PrK,PuK) <-
	.print("Validando transferencia...");
	velluscinum.stampTransaction(Server,PrK,PuK,Transfer).

+!ocuparVaga(Id): chainServer(Server) & myWallet(PrK, PuK) <-
	.print("Ocupando Vaga...");
	.print("Id -> ", Id);
	velluscinum.transferNFT(Server, PrK, PuK, Id, PuK, "status:ocupado", requestID);
	.wait(requestID(TransferId));
	.send(driver, tell, vagaOcupada(Id)).

+!liberarVaga(Id): chainServer(Server) & myWallet(PrK,PuK) <-
	.print("Liberando Vaga...");
	.print("Id -> ", Id);
	velluscinum.transferNFT(Server, PrK, PuK, Id, PuK, "status:disponivel", requestID);
	.wait(requestID(TransferId));
	.print("Vaga Liberada");
	.send(driver, achieve, sairEstacionamento).

// -------------------------- ANTES DE ABRIR --------------------------

+vaga(Vaga): listaVagas(Lista) & not .empty(Lista) <- 
	-+listaVagas([Vaga|Lista]).

+vaga(Vaga) <- -+listaVagas([Vaga]).

+!criarCarteira <-
	.print("Obtendo carteira digital!");
	velluscinum.loadWallet(myWallet);
	.wait(myWallet(PrK,PuK));
	+managerWallet(PuK);
	.wait(5000);
	!verificarListaVagas.

+!verificarListaVagas: chainServer(Server) & myWallet(PrK,PuK) <-
	.print("Verificando lista de vagas...");
	velluscinum.walletContent(Server, PrK, PuK, content);
	.wait(content(Content));
	!findToken(nft, set(Content));
	!abrirEstacionamento.

+!verificarListaVagas: not chainServer(Server) <-
	.wait(5000);
	!verificarListaVagas.

+!abrirEstacionamento : listaVagas(Vagas) <-
	.print("Estacionamento Aberto!");
	.broadcast(tell, estacionamentoAberto).

+!listarVagas: chainServer(Server) & myWallet(PrK,PuK) <- 
	.print("Listando vagas...");

	velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga1;tipo:Curta", "status:disponivel", account);
	.wait(account(Vaga1Id));

	velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga2;tipo:Longa", "status:disponivel", account);
	.wait(account(Vaga2Id));

	velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga3;tipo:Longa", "status:disponivel", account);
	.wait(account(Vaga3Id));

	velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga4;tipo:CurtaCoberta", "status:disponivel", account);
	.wait(account(Vaga4Id));

	velluscinum.deployNFT(Server, PrK, PuK, "name:Vaga5;tipo:LongaCoberta", "status:disponivel", account);
	.wait(account(Vaga5Id));

	Lista = [Vaga1Id, Vaga2Id, Vaga3Id, Vaga4Id, Vaga5Id];
	-+listaVagas(Lista);
	!abrirEstacionamento.

+!findToken(Term,set([Head|Tail])) <- 
    !compare(Term,Head,set(Tail));
    !findToken(Term,set(Tail)).

+!compare(Term,[Type,AssetID, Qtd],set(V)): (Term  == Type) | (Term == AssetID) <-
	.print("Vaga: ", AssetID);
	+vaga(AssetID).

-!compare(Term,[Type,AssetID,Qtd],set(V)) <- .print("The Asset ",AssetID, " is not a ",Term).

-!findToken(Type,set([   ])): not vaga(Vaga) <- 
	.print("Lista de vagas nao encontrada");
	!listarVagas.

-!findToken(Type,set([   ])): vaga(Vaga) <- 
	.print("Vagas ja cadastradas").

