import java.time.LocalDateTime;

import cartago.*;

public class ParkControl extends Artifact {
    private KeyValueObject extrairDados(Object[] campo) {
        String key = campo[0].toString();
        String value = campo[1].toString();
        return new KeyValueObject(key, value);
    }

    private boolean verificarData(Long data, Vaga vaga) {
        for (String[] reserva : vaga.getReservas()) {
            Long dataInicio = Long.valueOf(reserva[0]);
            Long dataFinal = Long.valueOf(reserva[1]) + dataInicio;
            if (Funcoes.isBetweenDates(data, dataInicio, dataFinal)) {
                return false;
            } else if (Funcoes.isBetweenDates(data, dataFinal, Funcoes.getDateWithMinutesAfter(dataFinal, 30))) {
                return false;
            }
        }
        return true;
    }

    private boolean verificarData(Long dataInicioDesejada, Long dataFinalDesejada, Vaga vaga) {
        for (String[] reserva : vaga.getReservas()) {
            Long dataInicio = Long.valueOf(reserva[0]);
            Long dataFinal = Long.valueOf(reserva[1]) + dataInicio;

            if (Funcoes.hasConflict(dataInicioDesejada, dataFinalDesejada, dataInicio, dataFinal))
                return false;
            if (Funcoes.hasConflict(dataInicioDesejada, dataFinalDesejada, dataFinal,
                    Funcoes.getDateWithMinutesAfter(dataFinal, 30)))
                return false;
        }
        return true;
    }

    private Vaga preencherVaga(Object[] metaDataList) {
        Vaga vaga = new Vaga("", "", "");
        for (Object metaData : metaDataList) {
            KeyValueObject object = extrairDados((Object[]) metaData);
            if (object.getKey().equals("status")) {
                vaga.setStatus(object.getValue());
            } else if (object.getKey().equals("tipo")) {
                vaga.setTipoVaga(object.getValue());
            } else if (object.getKey().equals("reservas")) {
                vaga.setReservas(object.getValue());
            }
        }
        return vaga;
    }

    @OPERATION
    void verificarCompra(String type, Object[] metaDataList) {
        Vaga vacancy = preencherVaga(metaDataList);
        LocalDateTime currentDateTime = LocalDateTime.now();
        String date = String.valueOf(Funcoes.toUnixTimestamp(currentDateTime));

        if (vacancy.getStatus().equals("disponivel") && vacancy.getTipoVaga().equals(type)) {
            if (verificarData(Long.valueOf(date), vacancy)) {
                log("Vaga disponível: " + vacancy.getTipoVaga());
                defineObsProperty("vagaDisponivel", true);
                defineObsProperty("tipoVaga", vacancy.getTipoVaga());
            }
        }
    }

    @OPERATION
    void verificarReserva(String type, long date, int duration, Object[] metaDataList) {
        Vaga vacancy = preencherVaga(metaDataList);

        if (vacancy.getStatus().equals("disponivel") && vacancy.getTipoVaga().equals(type)) {
            if (verificarData(date, Funcoes.getDateWithMinutesAfter(date, duration), vacancy)) {
                log("Vaga disponível: " + vacancy.getTipoVaga());
                defineObsProperty("vagaDisponivel", true);
                defineObsProperty("tipoVaga", vacancy.getTipoVaga());
                defineObsProperty("dataUso", date);
            }
        }
    }

    @OPERATION
    void getVacancyType(Object[] dataList) {
        for (Object data : dataList) {
            KeyValueObject object = extrairDados((Object[]) data);
            if (object.getKey().equals("tipoVaga")) {
                defineObsProperty("tipoVaga", object.getValue());
                log("Current vacancy type -> " + object.getValue());
                return;
            }
        }
    }

    @OPERATION
    void acharReserva(String reservationId, String assetId, Object[] metadata) {
        for (Object data : metadata) {
            KeyValueObject object = extrairDados((Object[]) data);
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
