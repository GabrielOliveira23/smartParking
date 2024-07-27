import java.time.LocalDateTime;

import cartago.*;

public class ParkControl extends Artifact {
    private KeyValueObject extrairDados(Object[] campo) {
        String key = campo[0].toString();
        String value = campo[1].toString();
        return new KeyValueObject(key, value);
    }

    private Vaga preencherVaga(Object[] metaDataList) {
        Vaga vaga = new Vaga("", "");
        for (Object metaData : metaDataList) {
            KeyValueObject object = extrairDados((Object[]) metaData);
            if (object.getKey().equals("status")) {
                vaga.setStatus(object.getValue());
            } else if (object.getKey().equals("tipo")) {
                vaga.setTipoVaga(object.getValue());
            } else if (object.getKey().equals("reservas")) {
                vaga.setReservasNovo(object.getValue());
            }
        }
        return vaga;
    }

    @OPERATION
    void verificarCompra(String type, Object[] metaDataList) {
        Vaga vaga = preencherVaga(metaDataList);
        LocalDateTime currentDateTime = LocalDateTime.now();
        String date = String.valueOf(Funcoes.toUnixTimestamp(currentDateTime));

        if (vaga.getStatus().equals("disponivel") && vaga.getTipoVaga().equals(type)) {
            if (verificarData(Long.valueOf(date), vaga)) {
                log("Vaga disponível: " + vaga.getTipoVaga());
                defineObsProperty("vagaDisponivel", true);
                defineObsProperty("tipoVaga", vaga.getTipoVaga());
            }
        }
    }

    private boolean verificarData(Long data, Vaga vaga) {
        for (Reserva reserva : vaga.getReservasNova()) {
            Long dataInicio = Long.valueOf(reserva.getData());
            Long dataFinal = reserva.getDataFinalPrevista();
            if (Funcoes.isBetweenDates(data, dataInicio, dataFinal)) {
                return false;
            } 
            // else if (Funcoes.isBetweenDates(data, dataFinal, Funcoes.getDateWithMinutesAfter(dataFinal, 30))) {
            //     return false;
            // }
        }
        return true;
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

    private boolean verificarData(Long dataInicioDesejada, Long dataFinalDesejada, Vaga vaga) {
        for (String[] reserva : vaga.getReservas()) {
            Long dataInicio = Long.valueOf(reserva[1]);
            Long dataFinal = Long.valueOf(reserva[2]) + dataInicio;

            if (Funcoes.hasConflict(dataInicioDesejada, dataFinalDesejada, dataInicio, dataFinal))
                return false;
            if (Funcoes.hasConflict(dataInicioDesejada, dataFinalDesejada, dataFinal,
                    Funcoes.getDateWithMinutesAfter(dataFinal, 30)))
                return false;
        }
        return true;
    }

    @OPERATION
    void getVacancyInfo(Object[] dataList) {
        int isDone = 0;

        for (Object data : dataList) {
            KeyValueObject object = extrairDados((Object[]) data);
            System.out.println(object.getKey() + ":" + object.getValue());
            if (object.getKey().equals("tipo")) {
                defineObsProperty("tipoVaga", object.getValue());
                log("Current vacancy type -> " + object.getValue());
                isDone++;
            }
            if (object.getKey().equals("status")) {
                defineObsProperty("statusVaga", object.getValue());
                log("Current vacancy status -> " + object.getValue());
                isDone++;
            }
            if (isDone == 2) {
                return;
            }
        }
        if (isDone == 1) {
            defineObsProperty("statusVaga", "disponivel");
        }

        return;
    }

    @OPERATION
    void registrarReserva(Object[] registrado, String status, String reservaId, long data, int tempo) {
        String registro;
        Reserva reserva = new Reserva(reservaId, String.valueOf(data), tempo);
        for (Object dados : registrado) {
            KeyValueObject object = extrairDados((Object[]) dados);
            if (object.getKey().equals("reservas")) {
                registro = Reserva.tratarRegistro(object, reserva, status);
                log("Reservas registradas atualizadas: " + registro);
                defineObsProperty("reservation", registro);
                return;
            }
        }
        registro = Reserva.tratarRegistro(reserva, status);
        log("Reservas registradas atualizadas: " + registro);
        defineObsProperty("reservation", registro);
    }

    @OPERATION
    void acharReserva(String reservationId, String assetId, Object[] metadata) {
        Vaga vaga = preencherVaga(metadata);
        for (Reserva reserva : vaga.getReservasNova()) {
            if (reservationId.equals(reserva.getId())) {
                log("Reserva encontrada reservationId: " + reservationId);
                log("Reserva encontrada assetId: " + assetId);
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
