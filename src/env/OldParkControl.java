// import cartago.*;
// import java.util.List;
// import java.util.ArrayList;
// import java.util.Random;

// public class OldParkControl extends Artifact {
//     static List<Vaga> listaVagas = new ArrayList<Vaga>();
//     Proposta proposta = new Proposta();

//     void init() {
//         Random random = new Random();

//         for (int i = 1; i < 6; i++) {
//             listaVagas.add(new Vaga(i, TipoVagaEnum.CURTA));
//             if (random.nextBoolean())
//                 listaVagas.get(i - 1).ocuparVaga();
//         }

//         for (int i = 6; i < 11; i++) {
//             listaVagas.add(new Vaga(i, TipoVagaEnum.LONGA));
//             if (random.nextBoolean())
//                 listaVagas.get(i - 1).ocuparVaga();
//         }

//         for (int i = 11; i < 15; i++) {
//             listaVagas.add(new Vaga(i, TipoVagaEnum.LONGACOBERTA));
//             if (random.nextBoolean())
//                 listaVagas.get(i - 1).ocuparVaga();
//         }

//         for (int i = 15; i < 21; i++) {
//             listaVagas.add(new Vaga(i, TipoVagaEnum.CURTACOBERTA));
//             if (random.nextBoolean())
//                 listaVagas.get(i - 1).ocuparVaga();
//         }
//     }

//     static String consultarTipoVaga(int idVaga) {
//         for (Vaga vaga : listaVagas) {
//             if (vaga.getId() == idVaga)
//                 return vaga.getTipoVaga();
//         }
//         return null;
//     }

//     @OPERATION
//     void consultarVaga(String tipoVaga, String date, String driverIntention) {
//         boolean isBooked = true;
//         for (Vaga vaga : listaVagas) {
//             if (vaga.getTipoVaga().equals(tipoVaga.toUpperCase())) {
//                 switch (driverIntention) {
//                     case "COMPRA": {
//                         if (vaga.isDisponivel()) {
//                             defineObsProperty("vagaDisponivel", true);
//                             defineObsProperty("idVaga", vaga.getId());
//                             log("Vaga consultada: " + vaga.getId() + " - " + vaga.getTipoVaga() + " - "
//                                             + vaga.isDisponivel());
//                             return;
//                         }
//                         break;
//                     }
//                     case "RESERVA": {
//                         List<String> reservations = vaga.getReservas();
//                         if (vaga.getReservas().isEmpty()) {
//                             // if doesnt exist reservations
//                             defineObsProperty("vagaDisponivel", true);
//                             defineObsProperty("idVaga", vaga.getId());
//                             return;
//                         } else {
//                             // if exist reservations
//                             String[] dateTimeRequired = date.split(" - ");
//                             for (String reserva : reservations) {
//                                 String[] dateTime = reserva.split(" - ");
//                                 if (dateTime[0].equals(dateTimeRequired[0])
//                                         && dateTime[1].equals(dateTimeRequired[1])) {
//                                     // if the reservation is the same as the required
//                                     isBooked = true;
//                                     log("------- Vaga " + vaga.getId() + " reservada -------");
//                                     break;
//                                 }
//                             }
//                         }
//                         break;
//                     }
//                     default:
//                         log("Intenção não reconhecida");
//                         break;
//                 }
//             }
//             if (!isBooked) {
//                 defineObsProperty("vagaDisponivel", true);
//                 defineObsProperty("idVaga", vaga.getId());
//                 return;
//             }
//         }
//         defineObsProperty("vagaDisponivel", false);
//     }

//     @OPERATION
//     void ocuparVaga(int idVaga) {
//         for (Vaga vaga : listaVagas) {
//             if ((vaga.getId() == idVaga) && vaga.isDisponivel()) {
//                 vaga.ocuparVaga();
//                 return;
//             }
//         }
//     }

//     @OPERATION
//     void driverExiting(int idVaga) {
//         for (Vaga vaga : listaVagas) {
//             if ((vaga.getId() == idVaga) && !vaga.isDisponivel()) {
//                 vaga.liberarVaga();
//                 log("Vaga liberada: " + vaga.getId());
//                 return;
//             }
//         }
//     }

//     @OPERATION
//     void bookVacancy(int idVacancy, String date, int minutes) {
//         // use minimum price to make an offer,
//         // like 0.8 of price is minimum acceptable
//         double price = ParkPricing.consultPrice(idVacancy);
//         price = Math.round(price * ((double) minutes / 60));
//         log("Valor a pagar: " + price);

//         defineObsProperty("valueToPay", price);
//     }

//     @OPERATION
//     void analisarProposta(double margemLucro) {
//         Double precoProposta = proposta.getPrecoProposta();
//         Double precoTabela = proposta.getPrecoTabela();

//         if (precoProposta >= precoTabela * 0.8) {
//             switch (proposta.getTipoVaga()) {
//                 case "CURTA":
//                     Double taxaDisponivel = verificarQuantidadeDisponivel(TipoVagaEnum.CURTA);
//                     defineObsProperty("decisaoProposta", getResultadoProposta(taxaDisponivel, margemLucro));
//                     break;
//                 case "LONGA":
//                     taxaDisponivel = verificarQuantidadeDisponivel(TipoVagaEnum.LONGA);
//                     defineObsProperty("decisaoProposta", getResultadoProposta(taxaDisponivel, margemLucro));
//                     break;
//                 case "LONGACOBERTA":
//                     taxaDisponivel = verificarQuantidadeDisponivel(TipoVagaEnum.LONGACOBERTA);
//                     defineObsProperty("decisaoProposta", getResultadoProposta(taxaDisponivel, margemLucro));
//                     break;
//                 case "CURTACOBERTA":
//                     taxaDisponivel = verificarQuantidadeDisponivel(TipoVagaEnum.CURTACOBERTA);
//                     defineObsProperty("decisaoProposta", getResultadoProposta(taxaDisponivel, margemLucro));
//                     break;
//             }
//         } else {
//             defineObsProperty("decisaoProposta", false);
//         }
//     }

//     Double verificarQuantidadeDisponivel(TipoVagaEnum tipoVaga) {
//         int quantidadeDisponivel = 0;
//         int quantidadeVagas = 0;
//         for (Vaga vaga : listaVagas) {
//             if (vaga.getTipoVaga().equals(tipoVaga.tipoVaga().toUpperCase())) {
//                 quantidadeVagas++;
//                 if (vaga.isDisponivel())
//                     quantidadeDisponivel++;
//             }
//         }

//         return (double) (quantidadeDisponivel / quantidadeVagas);
//     }

//     boolean getResultadoProposta(Double taxaDisponivel, Double margemLucro) {
//         Double precoProposta = proposta.getPrecoProposta();
//         Double precoTabela = proposta.getPrecoTabela();

//         if (taxaDisponivel >= 0.75) {
//             return true;
//         } else if (taxaDisponivel >= 0.5 && precoProposta >= precoTabela) {
//             return true;
//         } else if (precoProposta > precoTabela + (precoTabela * margemLucro)) {
//             return true;
//         } else {
//             return false;
//         }
//     }

//     @OPERATION
//     void setIdVaga(int id) {
//         proposta.setId(id);
//     }

//     @OPERATION
//     void setTipoVaga(String tipoVaga) {
//         proposta.setTipoVaga(tipoVaga);
//     }

//     @OPERATION
//     void setPrecoProposta(double precoProposta) {
//         proposta.setPrecoProposta(precoProposta);
//     }

//     @OPERATION
//     void setPrecoTabela(double precoTabela) {
//         proposta.setPrecoTabela(precoTabela);
//     }

// }
