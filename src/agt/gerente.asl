{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }

/* Initial beliefs and rules */

/* Initial goals */

!setup.

/* Plans */

+!setup : meus_atrb(Beliefs) <-
	.print("Beliefs> ",Beliefs);
	.sublist([Num_Vagas,Composicao_Vagas_Tipos,Composicao_Vagas_Setores],Beliefs);
	.print(Num_Vagas," ",Composicao_Vagas_Tipos," ",Composicao_Vagas_Setores);
	
	!createSpots(Num_Vagas,Composicao_Vagas_Tipos,Composicao_Vagas_Setores);
	
	makeArtifact("bancoDeCasos", "sma_CBR.bancoDeCasos", [], ArtCasos);
	focus(ArtCasos);
	
	makeArtifact("portaria", "sma_CBR.portaria", [], ArtCatraca);
	focus(ArtCatraca);
	
	.send(creator,tell,ready).
	
+!setup <- .wait(50); !setup.

+!createSpots(Num_Vagas,Composicao_Vagas_Tipos,Composicao_Vagas_Setores) <-
	+x(1);
	for( .member(Tipo_Vaga,Composicao_Vagas_Tipos)){
		?x(X);
		.sublist([Tipo,TipoID,TipoPerc],Tipo_Vaga);
		for( .range(I,X,(X-1)+math.floor(Num_Vagas*TipoPerc)) ){
			+vaga(I,"none",TipoID,"none");
			-+x(I+1);
		}
	}
	-+x(1);
	for( .member(Tipo_Vaga,Composicao_Vagas_Tipos)){
		.sublist([Tipo,TipoID,TipoPerc],Tipo_Vaga);
		for( .member(Setor_Vaga,Composicao_Vagas_Setores) ){
			?x(X);
			.sublist([SetorID,SetorPerc],Setor_Vaga);
			for( .range(I,X,(X-1)+math.floor(Num_Vagas*TipoPerc*SetorPerc)) ){
				-vaga(I,_,TipoID,Agent);
				+vaga(I,SetorID,TipoID,Agent);
				-+(x(I+1));
			}
		}
	}.
	
	//for( vaga(I,S,T,A) ){
	//	.print([I,S,T,A]);
	//}.

+!start <- .send(creator,tell,next).

+!pedirOferta(TV,DS,HC,TU,S,Pr,TVg)[source(Motorista)] <-
	!vagas_restantes;
	?vagasRestantes(VagasRest);
	.print("Vagas Restantes> ",VagasRest);
	recuperarCaso([TV,DS,HC,TU,S,Pr,TVg],VagasRest,Oferta);
	if( Oferta == [] ){
		.print("Sem vagas disponiveis");
		.send(Motorista,achieve,vagaIndisponivel(_,S,TVg));	
	}else{
		.sublist([Setor,Preco,TipoVaga],Oferta);
		.print("Enviado oferta criada: (S:",Setor,", Pr:",Preco,", TVg:",TipoVaga,") ao ",Motorista);
		+oferta(Motorista,TV,DS,HC,TU,Setor,Preco,TipoVaga);
		.send(Motorista,achieve,oferta(Setor,Preco,TipoVaga));
	}.
	
+!resposta(Resposta)[source(Motorista)] : oferta(Motorista,TV,DS,HC,TU,S,Pr,TVg) <-
	.sublist([Chave,String],Resposta);
	reterCaso([TV,DS,HC,TU,S,Pr,TVg,Chave]);
	if( Chave == 0 ){
		-oferta(Motorista,TV,DS,HC,TU,S,Pr,TVg);
		!alocarVaga(Motorista,S,TVg);
	}.
	
+!resposta(Resposta)[source(Motorista)] <-
	.print("N�o existe oferta"). 

+!alocarVaga(Motorista,S,TVg) <-
	!escolherVaga(Motorista,S,TVg);
	if( vaga(ID,S,TVg,Motorista) ){
		.print("Alocando vaga> ",ID,"-",S,"|",TVg," ao ",Motorista);
		.send(Motorista,achieve,vagaAlocada(ID,S,TVg));
	}else{
		.print("Sem vagas dispon�vel para o ",Motorista);
		.send(Motorista,achieve,vagaIndisponivel(ID,S,TVg));
	}.	

+!escolherVaga(Motorista,Setor,TipoVaga) <- 
	.findall([Index,Setor,TipoVaga],vaga(Index,Setor,TipoVaga,"none"),VagasLivres);
	+vagasLivres(Motorista, VagasLivres);
	
	while( not alocado(Motorista) & not todasVagasUsadas(Motorista) ){
		?vagasLivres(Motorista, ListaVagas);
		if( ListaVagas \== [] ){
			.random(ListaVagas, Vaga);
			-vagasLivres(Motorista, ListaVagas);
			.delete(Vaga, ListaVagas, N_ListaVagas);
			+vagasLivres(Motorista, N_ListaVagas);
			.sublist([ID,S,TVg], Vaga);
		
			+escolhendo(Motorista);
			while( not alocado(Motorista) & not falho(Motorista)){
				?escolhendo(Motrst);
				if( not tudoOcupado & not escolhendoVaga & Motorista == Motrst ){
					+escolhendoVaga;
					if( vaga(ID,S,TVg,"none") ){
						-vaga(ID,S,TVg,"none");
						+vaga(ID,S,TVg,Motorista);
						+alocado(Motorista);
					}else{
						+falho(Motorista);
						.print("Vaga perdida");
					}
					-escolhendo(Motorista);
					-escolhendoVaga;
				}
			}
			-escolhendo(Motorista);
			-falho(Motorista);
		}else{
			+todasVagasUsadas(Motorista);
			.print("All Spots used before choosing for ",Motorista,"!");
		}
	}
	-alocado(Motorista);
	-vagasLivres(Motorista, FS);
	if( todasVagasUsadas(Motorista) ){
		-todasVagasUsadas(Motorista);
		.print("Couldn't prepare spot for ",Motorista);
	}.


+!estacionar(ID,S,TVg)[source(Motorista)] <-
	.print(Motorista," estacionado na vaga> ",ID,"-",S,"|",TVg);
	!print_vagas.

+!sairDaVaga(ID,S,TVg)[source(Motorista)] <-
	if( vaga(ID,S,TVg,Motorista) ){
		.print(Motorista," saindo da vaga> ",ID,"-",S,"|",TVg);
		-vaga(ID,S,TVg,Motorista);
		+vaga(ID,S,TVg,"none");
		!print_vagas;
	}else{
		.print("Vaga nao existe : ",[ID,S,TVg,Motorista]);
	}
	.
	
+!print_vagas <-
	.count(vaga(_,_,_,_),N);
	.count(vaga(_,_,_,"none"),NU);
	!vagas_restantes;
	?vagasRestantes(VagasRest);
	.print("Restantes:",NU," / Total:",N," - ",VagasRest," \n").
	
+!vagas_restantes <-
	-+vagasRestantes([[0,0,0],[0,0,0],[0,0,0]]);
	for(.range(I,1,3)){
		for(.range(J,1,3)){
			.count(vaga(_,I,J,"none"), S);
			?vagasRestantes(M);
			!replace(M,I-1,J-1,S,V);
			-+vagasRestantes(V);
		}
	}.


+!replace( [L|Ls] , 0 , Y , Z , [R|Ls] ) <-
  !replace_column(L,Y,Z,R).
                                        
+!replace( [L|Ls] , X , Y , Z , [L|Rs] ) : X > 0 <-                                                         
  !replace( Ls , X-1 , Y , Z , Rs ).                                       

+!replace_column( [_|Cs] , 0 , Z , [Z|Cs] ). 
+!replace_column( [C|Cs] , Y , Z , [C|Rs] ) : Y > 0 <-                                                              
  !replace_column( Cs , Y-1 , Z , Rs ).                       

+!print([]) <-
	print("\n").
+!print([H|T]) <-
	print(H," ");
	!print(T).
	