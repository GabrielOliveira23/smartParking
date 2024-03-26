import cartago.*;

public class ParkControl extends Artifact {
    static KeyValueObject extractData(Object[] field) {
        String key = field[0].toString();
        String value = field[1].toString();
        return new KeyValueObject(key, value);
    }

    // static KeyValueObject extractData(String field) {

    // }

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
    void verificarReserva(Object[] dataList) {
        for (Object data : dataList) {
            KeyValueObject object = extractData((Object[]) data);
            if (object.getKey().equals("reservationDate")) {
                defineObsProperty("reservaDisponivel", false);
                return;
            }
        }
        defineObsProperty("reservaDisponivel", true);
    }

    @OPERATION
    void acharReserva(String assetId, Object[] listaVagas) {
        for (Object data : listaVagas) {
            KeyValueObject object = extractData((Object[]) data);
            System.out.println(object.getKey() + " - " + object.getValue());
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
}
