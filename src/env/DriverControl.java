import cartago.*;

import java.util.Random;

public class DriverControl extends Artifact {
    private Proposta proposta = new Proposta();

    @OPERATION
    void defineChoice() {
        Random random = new Random();
        int choice = random.nextInt(2);
        int useMinutes = random.nextInt(180);

        if (useMinutes < 20) {
            useMinutes = 20;
        }

        defineObsProperty("decisao", "COMPRA");
        defineObsProperty("useTime", useMinutes);
        definirTipoVaga();

        // switch(choice) {
        // case 0:
        // /*
        // primeiro caso: motorista quer escolher um tipo de vaga
        // e pagar agora sem proposta, apenas com o preço de tabela
        // */
        // defineObsProperty("escolha", "COMPRAR");
        // break;
        // case 1:
        // proposta.setTipoVaga("LONGA");
        // break;
        // case 2:
        // proposta.setTipoVaga("COBERTA");
        // break;
        // }
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
        double valueToPay = vacancyPrice * ((double)minutes / 60);

        valueToPay = Math.round(valueToPay);

        defineObsProperty("valueToPay", valueToPay);
    }

    @OPERATION
    void makeOffer(int idVaga, double precoTabela, String tipoVaga) {
        if (tipoVaga != null) {
            TipoVagaEnum typeVaga = TipoVagaEnum.setTipoVaga(tipoVaga);

            double precoFinal = barganhar(precoTabela);
        }
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
