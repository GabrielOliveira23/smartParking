{ include("$jacamo/templates/common-cartago.asl") }
{ include("$jacamo/templates/common-moise.asl") }

// listaNFTs([a,b,c,d,e]).
tiposDeVaga(["Longa", "Curta", "LongaCoberta", "CurtaCoberta"]).

!escolherAcao.

+!escolherAcao <-
    !paraTeste;
    !definirTipoVaga;
    ?tipoVaga(Tipo);
    .print("TipoVaga: ", Tipo);
    .random(R);
    if (R > .33){
        .print("compra");
        +decisao("COMPRA");
        +dataUso("now");
        .print("!comecarNegociacao");
    } elif (R < .66){
        .print("reserva");
        +decisao("RESERVA");
        !reserva;
    } else {
        .print("comprarReserva");
        +decisao("COMPRARESERVA");
        // definir data
    }.

+!reserva <-
    ?listaNFTs(Lista);
    .random(R);
    if (R < .33) {
        .print("usar");
        +decisaoReserva("USAR");
        .length(Lista, Tam);
        !escolherReserva(Tam);
        .print("!usarReserva");
    } elif (R < .66) {
        .print("reservar");
        +decisaoReserva("RESERVAR");
        .print("!comecarNegociacao");
    } else {
        .print("vender");
        +decisaoReserva("VENDER");
        .print("!makeVacancyAvailable");
    }.

-!reserva : not listaNFTs(Lista) <-
    .print("reservar");
    +decisaoReserva("RESERVAR").

-!reserva <- 
    .print("Plano de reserva falhou").

+!escolherReserva(Tam) : listaNFTs(Lista) <-
    .print("Tamanho da lista: ", Tam);
    .random(X);
    Indice = math.floor(Tam*X);
    .nth(Indice, Lista, Item);
    .print(Item).

+!escolherReserva(Tam) : not listaNFTs(Lista) <-
    .print("nao tem lista").

+!definirTipoVaga : tiposDeVaga(Tipos) <-
    .length(Tipos, Tam);
    .random(X);
    Indice = math.floor(Tam*X);
    .nth(Indice, Tipos, Item);
    +tipoVaga(Item).
    


+!paraTeste <-
    .random(X);
    if (X < .5) {
        +listaNFTs([a,b,c,d,e,f,g,h,i,j,k]);
    }.