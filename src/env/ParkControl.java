import cartago.*;

public class ParkControl extends Artifact {
    static NewVaga getVagaFromBelief(String vaga) {
        String[] vagaInfo = vaga.split(";");
        String tipoVaga = vagaInfo[0].split(":")[1];
        String idVaga = vagaInfo[1].split(":")[1];
        return new NewVaga(idVaga, TipoVagaEnum.setTipoVaga(tipoVaga));
    }

    @OPERATION
    void verificarVaga(Object[] listaVagas, String tipoDesejado, String data, String intencaoDriver) {
        switch (intencaoDriver) {
            case "COMPRA": {
                for (Object vagaObj : listaVagas) {
                    NewVaga vaga = getVagaFromBelief(vagaObj.toString());
                    if (vaga.getTipoVaga().equals(tipoDesejado.toUpperCase())) {
                        if (vaga.isDisponivel()) {
                            defineObsProperty("vagaDisponivel", true);
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
                    NewVaga vaga = getVagaFromBelief(vagaObj.toString());
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
    void bookVacancy(int idVacancy, String date, int minutes) {
        // use minimum price to make an offer,
        // like 0.8 of price is minimum acceptable
        // double price = ParkPricing.consultPrice(idVacancy);
        // price = Math.round(price * ((double) minutes / 60));
        // log("Valor a pagar: " + price);

        // defineObsProperty("valueToPay", price);
    }
}
