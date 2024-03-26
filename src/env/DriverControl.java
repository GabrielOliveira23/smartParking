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
    void defineReservationChoice(String nft) {
        Random random = new Random();
        int choice = random.nextInt(2);

        if (nft.isEmpty()) {
            log("Nenhuma reserva encontrada");
            // testing plan fail
            failed("Nenhuma reserva encontrada");
            return;
        }

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
            case 1: {
                /*
                 * segundo caso: transferir a reserva para
                 * outro motorista
                 */
                log("Processo de venda de reserva");
                defineObsProperty("reservationChoice", "VENDER");
                break;
            }
        }
    }

    @OPERATION
    void escolherReserva(Object[] nftList) {
        if (nftList.length == 0) {
            log("Nenhuma reserva encontrada");
            return;
        }
        
        Random random = new Random();
        if(random.nextInt(2) == 0) {
            log("Motorista escolheu não usar nenhuma reserva");
            return;
        }

        int randomInt = random.nextInt(nftList.length);
        int escolhaReserva = random.nextInt(2);

        String nft = nftList[randomInt].toString();
        defineObsProperty("reservaEscolhida", nft);

        switch (escolhaReserva) {
            case 0: {
                /*
                 * primeiro caso: usar a reserva para entrar
                 * no estacionamento
                 */
                log("Entrar no estacionamento");
                defineObsProperty("decisaoReserva", "USAR");
                break;
            }
            case 1: {
                /*
                 * segundo caso: transferir a reserva para
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
