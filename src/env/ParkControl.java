import cartago.*;

public class ParkControl extends Artifact {
    static Vaga getVagaFromBelief(String vaga) {
        String[] vagaInfo = vaga.split(";");
        String tipoVaga = vagaInfo[0].split(":")[1];
        String status = vagaInfo[1].split(":")[1];
        String idVaga = vagaInfo[2].split(":")[1];
        return new Vaga(idVaga, TipoVagaEnum.setTipoVaga(tipoVaga), status);
    }

    static KeyValueObject extractData(Object[] field) {
        String key = field[0].toString();
        String value = field[1].toString();
        return new KeyValueObject(key, value);
    }

    @OPERATION
    void tratarListaVagas(String type, String date, String driverIntention, Object[] metaDataList) {
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
                } else {
                    defineObsProperty("vagaDisponivel", false);
                }
                break;
            }
            case "RESERVA": {
                // if (vaga.getStatus().equals("disponivel")) {
                // defineObsProperty("vagaDisponivel", true);
                // defineObsProperty("tipoVaga", vaga.getTipoVaga());
                // defineObsProperty("dataUso", data);
                // } else {
                // defineObsProperty("vagaDisponivel", false);
                // }
                // break;
            }
            default: {
                log("Intenção não reconhecida");
                break;
            }
        }
    }

    @OPERATION
    void verificarVaga(Object[] listaVagas, String tipoDesejado, String data, String intencaoDriver) {
        switch (intencaoDriver) {
            case "COMPRA": {
                for (Object vagaObj : listaVagas) {
                    System.out.println(vagaObj.toString());
                    Vaga vaga = getVagaFromBelief(vagaObj.toString());
                    if (vaga.getTipoVaga().equals(tipoDesejado.toUpperCase())) {
                        if (vaga.isDisponivel()) {
                            defineObsProperty("vagaDisponivel", vaga.isDisponivel());
                            defineObsProperty("idVaga", vaga.getId());
                            log("Vaga consultada: " + vaga.getId());
                            log(vaga.getTipoVaga() + " - " + vaga.isDisponivel());
                            return;
                        }
                    }
                }
                break;
            }
            case "RESERVA": {
                for (Object vagaObj : listaVagas) {
                    Vaga vaga = getVagaFromBelief(vagaObj.toString());
                    if (vaga.getTipoVaga().equals(tipoDesejado.toUpperCase())) {
                        if (vaga.getReservas().isEmpty()) {
                            // if doesnt exist reservations
                            defineObsProperty("vagaDisponivel", true);
                            defineObsProperty("idVaga", vaga.getId());
                            return;
                        } else {
                            // if exist reservations
                            String[] dateTimeRequired = data.split(" - ");
                            for (String reserva : vaga.getReservas()) {
                                String[] dateTime = reserva.split(" - ");
                                if (dateTime[0].equals(dateTimeRequired[0])
                                        && dateTime[1].equals(dateTimeRequired[1])) {
                                    // if the reservation is the same as the required
                                    defineObsProperty("vagaDisponivel", false);
                                    return;
                                }
                            }
                        }
                    }
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
    void calcularValorAPagarUso(String tipoVaga, int minutos) {
        double preco = ParkPricing.getPreco(TipoVagaEnum.setTipoVaga(tipoVaga));
        log("Preço da tabela: " + preco);
        preco = Math.round(preco * ((double) minutos / 60));
        defineObsProperty("valorAPagarUso", preco);
    }

    @OPERATION
    void bookVacancy(String tipoVaga, Object[] listaVagas, String data, int minutos) {
        for (Object vagaObj : listaVagas) {
            Vaga vaga = getVagaFromBelief(vagaObj.toString());
            if (vaga.getTipoVaga().equals(tipoVaga.toUpperCase())) {
                if (vaga.getReservas().isEmpty()) {
                    log("Vaga consultada: " + vaga.getId());
                    log("---------> Não tem reservas");
                    defineObsProperty("vagaDisponivelParaReserva", vaga.isDisponivel());
                    defineObsProperty("idVaga", vaga.getId());
                    return;
                } else {
                    // if exist reservations
                    String[] dateTimeRequired = data.split(" - ");
                    for (String reserva : vaga.getReservas()) {
                        String[] dateTime = reserva.split(" - ");
                        if (dateTime[0].equals(dateTimeRequired[0]) && dateTime[1].equals(dateTimeRequired[1])) {
                            // if the reservation is the same as the required
                            defineObsProperty("vagaDisponivel", false);
                            return;
                        }
                    }
                }
            }
        }

        // use minimum price to make an offer,
        // like 0.8 of price is minimum acceptable
        // double price = ParkPricing.consultPrice(idVacancy);
        // price = Math.round(price * ((double) minutes / 60));
        // log("Valor a pagar: " + price);

        // defineObsProperty("valueToPay", price);
    }
}
