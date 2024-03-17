import cartago.*;

public class ParkControl extends Artifact {
    static KeyValueObject extractData(Object[] field) {
        String key = field[0].toString();
        String value = field[1].toString();
        return new KeyValueObject(key, value);
    }

    @OPERATION
    void verificarVaga(String type, String date, String driverIntention, Object[] metaDataList) {
        NewVaga vaga = new NewVaga("", "");
        for (Object metaData : metaDataList) {
            KeyValueObject object = extractData((Object[]) metaData);
            if (object.getKey().equals("status") && object.getValue().equals("disponivel")) {
                vaga.setStatus(object.getValue());
            } else if (object.getKey().equals("tipo") && object.getValue().equals(type)) {
                vaga.setTipoVaga(object.getValue());
            }
        }
        if (vaga.getStatus().equals("")) {
            vaga.setStatus("disponivel");
        }
        switch (driverIntention) {
            case "COMPRA": {
                if (vaga.getStatus().equals("disponivel") && vaga.getTipoVaga().equals(type)) {
                    System.out.println("Vaga disponível: " + vaga.getTipoVaga());
                    defineObsProperty("vagaDisponivel", true);
                    defineObsProperty("tipoVaga", vaga.getTipoVaga());
                }
                break;
            }
            case "RESERVA": {
                if (vaga.getStatus().equals("disponivel") && vaga.getTipoVaga().equals(type)) {
                    System.out.println("Vaga disponível: " + vaga.getTipoVaga());
                    defineObsProperty("vagaDisponivel", true);
                    defineObsProperty("tipoVaga", vaga.getTipoVaga());
                    defineObsProperty("dataUso", date);
                }
                break;
            }
            default: {
                log("Intenção não reconhecida");
                break;
            }
        }
    }

    @OPERATION
    void getCurrentStatus(Object[] dataList) {
        for (Object data : dataList) {
            KeyValueObject object = extractData((Object[]) data);
            if (object.getKey().equals("status")) {
                defineObsProperty("currentStatus", object.getValue());
                log("Current status -> " + object.getValue());
                return;
            }
        }
    }

    @OPERATION
    void calcularValorAPagarUso(String tipoVaga, int minutos) {
        double preco = ParkPricing.getPreco(TipoVagaEnum.setTipoVaga(tipoVaga));
        log("Preço da tabela: " + preco);
        preco = Math.round(preco * ((double) minutos / 60));
        log("Valor a pagar: " + preco);
        defineObsProperty("valorAPagarUso", preco);
    }

    @OPERATION
    void bookVacancy(String tipoVaga, Object[] listaVagas, String data, int minutos){
        
    }

    // @OPERATION
    // void bookVacancy(String tipoVaga, Object[] listaVagas, String data, int minutos) {
    //     for (Object vagaObj : listaVagas) {
    //         Vaga vaga = getVagaFromBelief(vagaObj.toString());
    //         if (vaga.getTipoVaga().equals(tipoVaga.toUpperCase())) {
    //             if (vaga.getReservas().isEmpty()) {
    //                 log("Vaga consultada: " + vaga.getId());
    //                 log("---------> Não tem reservas");
    //                 defineObsProperty("vagaDisponivelParaReserva", vaga.isDisponivel());
    //                 defineObsProperty("idVaga", vaga.getId());
    //                 return;
    //             } else {
    //                 // if exist reservations
    //                 String[] dateTimeRequired = data.split(" - ");
    //                 for (String reserva : vaga.getReservas()) {
    //                     String[] dateTime = reserva.split(" - ");
    //                     if (dateTime[0].equals(dateTimeRequired[0]) && dateTime[1].equals(dateTimeRequired[1])) {
    //                         // if the reservation is the same as the required
    //                         defineObsProperty("vagaDisponivel", false);
    //                         return;
    //                     }
    //                 }
    //             }
    //         }
    //     }

    //     // use minimum price to make an offer,
    //     // like 0.8 of price is minimum acceptable
    //     // double price = ParkPricing.consultPrice(idVacancy);
    //     // price = Math.round(price * ((double) minutes / 60));
    //     // log("Valor a pagar: " + price);

    //     // defineObsProperty("valueToPay", price);
    // }
}
