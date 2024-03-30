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
            if (object.getKey().equals("status")) {
                vaga.setStatus(object.getValue());
            } else if (object.getKey().equals("tipo")) {
                vaga.setTipoVaga(object.getValue());
            }
        }
        if (vaga.getStatus().equals("")) {
            vaga.setStatus("disponivel");
        }
        switch (driverIntention) {
            case "COMPRA": {
                if (vaga.getStatus().equals("disponivel") && vaga.getTipoVaga().equals(type)) {
                    log("Vaga disponivel: " + vaga.getTipoVaga());
                    defineObsProperty("vagaDisponivel", true);
                    defineObsProperty("tipoVaga", vaga.getTipoVaga());
                }
                break;
            }
            case "RESERVA": {
                if (vaga.getStatus().equals("disponivel") && vaga.getTipoVaga().equals(type)) {
                    log("Vaga disponível: " + vaga.getTipoVaga());
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
    void acharReserva(String reservationId, String assetId, Object[] metadata) {
        for (Object data : metadata) {
            KeyValueObject object = extractData((Object[]) data);
            if (object.getKey().equals("reservationId") && object.getValue().equals(reservationId)) {
                log("Reserva encontrada: " + reservationId);
                log("Reserva encontrada: " + assetId);
                defineObsProperty("reservaEncontrada", assetId);
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
}
