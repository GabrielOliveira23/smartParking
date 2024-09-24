{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }

/* Initial beliefs and rules */

/* Initial goals */

!setup.

/* Plans */

+!setup : meus_atrb(Beliefs) <- 
	.print("Beliefs> ",Beliefs);
	.sublist([Tipo_Veiculo,Ordem_Reducao|Preferencias],Beliefs);
	.sublist([Nome,ID],Tipo_Veiculo);
	+tipo_veiculo(Nome,ID);
	+prefs_originais(Preferencias);
	+preferencias(Preferencias);
	
	Terceiro = Ordem_Reducao mod 10;
	Segundo = math.floor(Ordem_Reducao/10) mod 10;
	Primeiro = math.floor(Ordem_Reducao/100);
	+ordem_reducao( [Primeiro, Segundo, Terceiro] );
	
	//.print(Nome," ",Preferencias," ",Primeiro," ",Segundo," ",Terceiro);
	
	.send(creator,tell,ready).
	
+!setup <- .wait(50); !setup.

+!start <- 
	.my_name(Name);
	.send(creator,achieve,buffer(math.floor(math.random(50)),.send(Name,achieve,adquirirVaga)));
	.send(creator,tell,next).

+!adquirirVaga : tipo_veiculo(Nome,TV) & preferencias(Prefs) <- 
	.send(creator,untell,next);
	.sublist([Pr,S,TVg,TU],Prefs);
	.send(creator,askOne,data_atual(A,M,D,H,DS),X); +X; ?data_atual(A,M,D,H,DS);
	.print("Pedindo oferta com seguintes dados: ",[TV,DS,H,TU,S,Pr,TVg]);
	-+pedido([TV,DS,H,TU,S,Pr,TVg]);
	.send("gerente_1",achieve,pedirOferta(TV,DS,H,TU,S,Pr,TVg));
	.

+!oferta(S,Pr,TVg)[source(Gerente)] : preferencias(Prefs) <-
	.sublist([Preco_Desejado, Setor_Desejado, Tipo_Vaga,_],Prefs);
	Valor_Vaga = Tipo_Vaga/TVg;
	Valor_Preco = Preco_Desejado/Pr;
	Valor_Setor = Setor_Desejado/S;
	
	if( (Valor_Vaga + Valor_Preco + Valor_Setor)/3 >= 1 ){
		.print("Aceito a oferta (S:",S,", Pr:",Pr,", TVg:",TVg,") do ",Gerente, " | Queria: (S:",Setor_Desejado,", Pr:",Preco_Desejado,", TVg:",Tipo_Vaga,")");
		.send(Gerente,achieve,resposta([0,"oferta aceita"]));
	}else{
		.min([[Valor_Setor,1,"setor muito longe"],[Valor_Preco,2,"preco muito alto"],[Valor_Vaga,3,"tipo de vaga indesejado"]],X);
		.sublist([_|Resposta],X);
		.nth(1,Resposta,Str);
		.print("Recuso a oferta (S:",S,", Pr:",Pr,", TVg:",TVg,") do ",Gerente," devido a ",Str," | Queria: (S:",Setor_Desejado,", Pr:",Preco_Desejado,", TVg:",Tipo_Vaga,")");
		.send(Gerente,achieve,resposta(Resposta));
		
		!reduzirPref;
		if(reduzida){
			-reduzida;
			!!adquirirVaga;
		}else{
			?prefs_originais(Prefs_OG);
			-+preferencias(Prefs_OG);
			!!start;
		}
	}.

+!reduzirPref : ordem_reducao(Ordem) & preferencias(Prefs) <-
	for( .member(P, Ordem) ){
		if( .nth(P, Prefs, Pref) & Pref < 3 & not reduzida ){
			!replace(Prefs, P, Pref+1, New_Prefs);
			-+preferencias(New_Prefs);
			+reduzida;
		}
	}.

+!aumentarPref : ordem_reducao(Ordem) & preferencias(Prefs) <-
	for( .member(P, Ordem) ){
		if( .nth(P, Prefs, Pref) & Pref > 1 & not aumentada ){
			!replace(Prefs, P, Pref-1, New_Prefs);
			-+preferencias(New_Prefs);
			+aumentada;
		}
	}.
	
+!vagaIndisponivel(ID,S,TVg)[source(Gerente)] <-
	if( not aumentada ){
		.print("Verificando vagas mais caras.");
		!aumentarPref;
		if(aumentada){
			!!adquirirVaga;
		}else{
			?prefs_originais(Prefs_OG);
			-+preferencias(Prefs_OG);
			!!start;
		}
	}else{
		.print("Volto em outro momento.");
		-aumentada;
		?prefs_originais(Prefs_OG);
		-+preferencias(Prefs_OG);
		!!start;
	}.


+!vagaAlocada(ID,S,TVg)[source(Gerente)] <-
	.my_name(Name);
	-+vaga(ID,S,TVg);
	?pedido(Pedido);
	.nth(3,Pedido,TU);
	.nth(TU,[-1,[50,25,10,5],[4],[2]],Times);
	.random(Times,Time);
	.print("Estacionando na vaga> ",ID,"-",S,"-",TVg," por ",Time," horas");
	.send(Gerente,achieve,estacionar(ID,S,TVg));
	.send(creator,achieve,buffer(math.floor(math.random(Time)),.send(Name,achieve,sairEstacionamento)));
	.send(creator,tell,next).
	
+!sairEstacionamento : vaga(ID,S,TVg) <-
	.print("Sainda da vaga> ",ID,"-",S,"-",TVg);
	.send("gerente_1",achieve,sairDaVaga(ID,S,TVg));
	!!start.

+!replace([_|T], 0, X, [X|T]).
+!replace([H|T], I, X, [H|R]) : I > 0 <-
	 !replace(T, I-1, X, R).
	
