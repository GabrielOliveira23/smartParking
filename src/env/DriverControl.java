import cartago.*;

import java.util.Random;

public class DriverControl extends Artifact {
    // private Proposta proposta = new Proposta();
    @OPERATION
    void emprestimoCount() {
        ObsProperty emprestimoNum = getObsProperty("emprestimoNum");
        if (emprestimoNum != null) {
            int count = emprestimoNum.intValue();
            count++;
            log("Emprestimo num: " + count);
            defineObsProperty("emprestimoNum", count);
        } else {
            defineObsProperty("emprestimoNum", 0);
        }
    }

    @OPERATION
    void defineChoice() {
        Random random = new Random();
        int choice = random.nextInt(3);
        int useMinutes = random.nextInt(180);

        useMinutes = useMinutes < 20 ? 20 : useMinutes;

        choice = 1;
        switch (choice) {
            case 0: {
                /*
                 * primeiro caso: motorista quer escolher um tipo de vaga
                 * e pagar agora sem proposta, apenas com o preço de tabela
                 */

                defineObsProperty("decisao", "COMPRA");
                defineObsProperty("tempoUso", useMinutes);
                defineObsProperty("dataUso", "now");
                definirTipoVaga();
                break;
            }
            case 1: {
                /*
                 * segundo caso: motorista quer reservar uma vaga para
                 * para utilizar em um tempo futuro
                 */

                defineObsProperty("decisao", "RESERVA");
                defineObsProperty("tempoUso", useMinutes);
                defineObsProperty("dataUso", "20242504");
                definirTipoVaga();
                break;
            }
            case 2: {
                /*
                 * terceiro caso: motorista quer negociar a
                 * transferencia de uma reserva de outro motorista
                 */

                defineObsProperty("decisao", "COMPRARESERVA");
                defineObsProperty("dataUso", "20242504");
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
    void escolherReserva(Object[] nftList) {
        Random random = new Random();
        int escolhaReserva = random.nextInt(3);
        String nft = "";

        if (nftList.length != 0) {
            int randomInt = random.nextInt(nftList.length);
            nft = nftList[randomInt].toString();
            escolhaReserva = 1;
        } else {
            escolhaReserva = 0;
        }

        switch (escolhaReserva) {
            case 0: {
                /*
                 * primeiro caso: comprar uma reserva de vaga
                 */
                log("Comprar uma reserva");
                defineObsProperty("decisaoReserva", "RESERVAR");
                break;
            }
            case 1: {
                /*
                 * segundo caso: usar a reserva para entrar
                 * no estacionamento
                 */
                log("Entrar no estacionamento");
                defineObsProperty("decisaoReserva", "USAR");
                log("Reserva escolhida: " + nft);
                defineObsProperty("reservaEscolhida", nft);
                break;
            }
            case 2: {
                /*
                 * terceiro caso: transferir a reserva para
                 * outro motorista
                 */
                log("Processo de venda de reserva");
                defineObsProperty("decisaoReserva", "VENDER");
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
}
