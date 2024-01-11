import cartago.*;

import java.util.Random;

public class DriverControl extends Artifact {
    // private Proposta proposta = new Proposta();

    @OPERATION
    void defineChoice() {
        Random random = new Random();
        int choice = random.nextInt(2);
        int useMinutes = random.nextInt(180);

        useMinutes = useMinutes < 20 ? 20 : useMinutes;

        // choice = 1;
        switch (choice) {
            case 0: {
                /*
                 * primeiro caso: motorista quer escolher um tipo de vaga
                 * e pagar agora sem proposta, apenas com o preço de tabela
                 */

                defineObsProperty("decisao", "COMPRA");
                defineObsProperty("useTime", useMinutes);
                defineObsProperty("useDate", "NOW");
                // trocar para now
                definirTipoVaga();
                break;
            }
            case 1: {
                /*
                 * segundo caso: motorista quer reservar uma vaga para
                 * para utilizar em um tempo futuro
                 */

                defineObsProperty("decisao", "RESERVA");
                defineObsProperty("useTime", useMinutes);
                defineObsProperty("useDate", "31/01 - 10:00");
                definirTipoVaga();
                break;
            }
            default: {
                log("Escolha inválida");
                break;
            }
        }
    }

    @OPERATION
    void defineReservationChoice() {
        Random random = new Random();
        int choice = random.nextInt(2);

        choice = 0;
        switch (choice) {
            case 0: {
                /*
                 * primeiro caso: usar a reserva para entrar
                 * no estacionamento
                 */
                log("Entrar no estacionamento");
                defineObsProperty("reservationChoice", "USAR");
                break;
            }
        }
    }

    void definirTipoVaga() {
        Random random = new Random();
        int randomInt = random.nextInt(4);

        TipoVagaEnum tipoVaga = TipoVagaEnum.values()[randomInt];
        defineObsProperty("tipoVaga", tipoVaga.tipoVaga());
    }

    @OPERATION
    void defineValueToPay(int idVacancy, int minutes) {
        double vacancyPrice = (double) ParkPricing.consultPrice(idVacancy);
        double valueToPay = vacancyPrice * ((double) minutes / 60);

        valueToPay = Math.round(valueToPay);

        defineObsProperty("valueToPay", valueToPay);
    }

    @OPERATION
    void makeOffer(int idVaga, double precoTabela, String tipoVaga) {
        // if (tipoVaga != null) {
        //     TipoVagaEnum typeVaga = TipoVagaEnum.setTipoVaga(tipoVaga);

        //     double precoFinal = barganhar(precoTabela);
        // }
    }

    double barganhar(Double precoTabela) {
        Random random = new Random();

        Double min = 0.8;
        Double max = 1.5;

        Double valorAleatorio = min + (max - min) * random.nextDouble();

        Double precoFinal = precoTabela * valorAleatorio;

        precoFinal = Math.round(precoFinal * 100.0) / 100.0;

        defineObsProperty("precoVaga", precoFinal);
        return precoFinal;
    }
}
