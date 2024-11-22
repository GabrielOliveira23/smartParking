{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }

/* Initial beliefs and rules */
	                     					 
agents_configs( [["driver", 5, []]]).
				

num_total_agentes(0).

// AAAA MM DD HH 
data_inicial(2022,12,20,00,1).
data_atual(2022,12,20,00,1).

iter(0).

/* Initial goals */

!criarAgentes.

/* Plans */

+!criarAgentes : agents_configs(Configs) <-
	for( .member(Agent, Configs)){
		.nth(1, Agent, Num_Agents);
		?num_total_agentes(Num);
		-+num_total_agentes(Num+Num_Agents);
	}
	
	for( .member(Agent_config, Configs) ){
		.sublist([Nome_Agente,Num_Agentes,Atrbs_Agente],Agent_config);
		.length(Atrbs_Agente,Tam);
		-+atrb_counter([]);
		for(.range(K,0,Tam-1)){
			?atrb_counter(AL); 
			.concat(AL,[[K,0]],N_AL); 
			-+atrb_counter(N_AL);
		}
		
		for(.range(I,1,Num_Agentes)){
			?atrb_counter(Atrb_Counter);
			-+aux_atrib_list(Atrb_Counter);
	
			-+beliefs([]);
			-+carry_over(1);
			for(.member(Atrb,Atrbs_Agente) & .member(Counter,Atrb_Counter) &
				.sublist([Atrb_index,Atrb_data],Atrb) & .sublist([Counter_index,Counter_data],Counter) &
				Atrb_index == Counter_index){
				
				.nth(Counter_data, Atrb_data, Value);
				?beliefs(Beliefs);
				.concat(Beliefs,[Value],New_Beliefs);
				-+beliefs(New_Beliefs);
				
				?carry_over(CO);
				?aux_atrib_list(Aux_Counter);
				if( Counter_data+CO >= .length(Atrb_data) ){
					-+carry_over(1);
					!replace(Aux_Counter,Counter_index,[Counter_index,0],N_Aux_Counter);
				}else{
					-+carry_over(0);
					!replace(Aux_Counter,Counter_index,[Counter_index,Counter_data+CO],N_Aux_Counter);
				}
				-+aux_atrib_list(N_Aux_Counter);
			}
			?aux_atrib_list(Aux);
			-+atrb_counter(Aux);
			
			.concat(Nome_Agente,"_",I, Nome_Id);
			.concat(Nome_Agente,".asl", Nome_asl);
			
			?beliefs(Beliefs);
			.create_agent(Nome_Id, Nome_asl);
			.send(Nome_Id,tell,meus_atrb(Beliefs));
		}
	}.

+ready[source(Agente)] : num_total_agentes(Num) <-
	.count(ready[source(_)], N);
	if( N == 1){
		print("Agentes criados: ",0);
	}
	if( N mod (0.1*(Num-1)) == 0 ){
		print(" | ",N);
	}
	if( N == Num ){
		print("\nIniciando Agentes\n\n");
		.abolish(ready[source(_)]);
		.broadcast(achieve,start);
		.wait(100);
		!!check_next;
	}.

+!check_next <- 
	if( num_total_agentes(Num) & .count(next[source(_)], Nxt) & Nxt \== Num ){
		.print("Esperando por ",Num-Nxt," agente(s)");
		!!check_next;
	}else{
		!update_dateTime;
		!!next_phase;
	}.

+!next_phase <-
	-+nr_op(0);
	for( next_operation(Agent,Time,Operation) ){
		if( Time == 0 ){
			?nr_op(NROP);
			-+nr_op(NROP+1);
			-next_operation(Agent,Time,Operation);
			Operation;
			.wait(100);
		}else{
			-next_operation(Agent,Time,Operation);
			+next_operation(Agent,Time-1,Operation);
		}
	}
	?iter(I);
	-+iter(I+1);
	while( num_total_agentes(Num) & .count(next[source(_)], N) & N \== Num ){
		.wait(100);
	}
	?nr_op(NROP2); .print(NROP2," motoristas no turno anterior\n");
	if( next_operation(_,_,_) ){
		!!check_next;
	}.	

+!buffer(Time,Operation)[source(Agent)] <-
	if( not next_operation(Agent,_,_) ){
		+next_operation(Agent,Time,Operation);
	}.

+!update_dateTime : data_inicial(Ano,Mes,Dia,Hora,Dia_Semana) & iter(I)<-
	New_H = (Hora + I) mod 24;
	
	Aux_D = math.floor((Dia + (Hora + I)/24) mod 31);
	if( Aux_D == 0 ){ New_D = 1 }else{ New_D = Aux_D }
	
	//print((Mes + (Dia + (Hora + I)/24)/30) mod 13);
	Aux_M = math.floor(Mes + (Dia + (Hora + I)/24)/30) mod 13;
	if( Aux_M == 0 ){ New_M = 1 }else{ New_M = Aux_M }
		
	New_A = math.floor(Ano + (Mes + (Dia + (Hora + I)/24)/31)/13);
		
	Aux_DS = math.floor((Dia_Semana + (Hora + I)/24) mod 8);
	if( Aux_DS == 0 ){ New_DS = 1 }else{ New_DS = Aux_DS }
	.print("Iniciando turno ",I,"  DataHorario: ",New_A,"/",New_M,"/",New_D,":",New_H," Dia_semanda: ",New_DS," \n");
	-+data_atual(New_A,New_M,New_D,New_H,New_DS).

+!replace([_|T], 0, X, [X|T]).
+!replace([H|T], I, X, [H|R]) : I > 0 <-
	 !replace(T, I-1, X, R).

// uncomment the include below to have a agent that always complies with its organization  
//{ include("$jacamoJar/templates/org-obedient.asl") }
