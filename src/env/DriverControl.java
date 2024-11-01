import cartago.*;

import java.time.LocalDateTime;
import java.util.Random;

public class DriverControl extends Artifact {
    @OPERATION
    void emprestimoCount() {
        ObsProperty emprestimoNum = getObsProperty("emprestimoNum");
        if (emprestimoNum != null) {
            int count = emprestimoNum.intValue();
            count++;
            defineObsProperty("emprestimoNum", count);
        } else {
            defineObsProperty("emprestimoNum", 0);
        }
    }

    @OPERATION
    void tempoEstacionado(OpFeedbackParam<Integer> tempo, int maxOrcamento, double precoTabela) {
        Random random = new Random();
        int useMinutes = random.nextInt(180);

        useMinutes = useMinutes < 20 ? 20 : useMinutes;

        if (useMinutes / 60 * precoTabela > maxOrcamento) {
            // useMinutes = (int) (maxOrcamento / precoTabela * 60);
            // log("Tempo estacionado excedeu o orçamento");
            return;
        }

        // log("Tempo estacionado: " + useMinutes + " minutos");
        tempo.set(useMinutes);
    }

    @OPERATION
    void defineChoice() {
        double num = getObsProperty("numero").floatValue();
        System.out.println("--------------------> Número: " + num);
        Random random = new Random();
        // int choice = random.nextInt(3);
        int choice = random.nextInt(2);
        int useMinutes = random.nextInt(180);

        useMinutes = useMinutes < 20 ? 20 : useMinutes;

        choice = 0;
        switch (choice) {
            case 0: {
                /*
                 * primeiro caso: motorista quer escolher um tipo de vaga
                 * e pagar agora sem proposta, apenas com o preço de tabela
                 */

                // defineObsProperty("decisao", "COMPRA");
                // defineObsProperty("dataUso", "now");
                signal("decisao", "COMPRA");
                signal("dataUso", "now");
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
                defineObsProperty("dataUso", definirDataReserva());
                definirTipoVaga();
                break;
            }
            case 2: {
                /*
                 * terceiro caso: motorista quer negociar a
                 * transferencia de uma reserva de outro motorista
                 */

                defineObsProperty("decisao", "COMPRARESERVA");
                defineObsProperty("dataUso", definirDataReserva());
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
        int escolhaReserva = -1;
        String nft = "";

        if (nftList.length != 0) {
            int randomInt = random.nextInt(nftList.length);
            nft = nftList[randomInt].toString();
            escolhaReserva = 0;
        }

        if (escolhaReserva == -1) {
            escolhaReserva = random.nextInt(2);
            // escolhaReserva = 1;
        }

        switch (escolhaReserva) {
            case 0: {
                /*
                 * primeiro caso: usar a reserva para entrar
                 * no estacionamento
                 */
                log("Entrar no estacionamento");
                defineObsProperty("decisaoReserva", "USAR");
                // log("Reserva escolhida: " + nft);
                defineObsProperty("reservaEscolhida", nft);
                break;
            }
            case 1: {
                /*
                 * segundo caso: comprar uma reserva de vaga
                 */
                log("Comprar uma reserva");
                defineObsProperty("decisaoReserva", "RESERVAR");
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

    private void definirTipoVaga() {
        Random random = new Random();
        int randomInt = random.nextInt(4);

        TipoVagaEnum tipoVaga = TipoVagaEnum.values()[randomInt];
        defineObsProperty("tipoVaga", tipoVaga.tipoVaga());
        // signal(agentName, "tipoVaga", tipoVaga.tipoVaga());
    }

    private long definirDataReserva() {
        LocalDateTime currentDateTime = LocalDateTime.now();
        LocalDateTime dataReserva;
        long unixTimestamp = 0;
        Random random = new Random();

        switch (random.nextInt(3)) {
            case 0:
                dataReserva = Funcoes.getNextHalfHour(currentDateTime.plusHours(1));
                unixTimestamp = Funcoes.toUnixTimestamp(dataReserva);
                break;
            case 1:
                dataReserva = Funcoes.getNextHalfHour(currentDateTime.plusDays(1));
                unixTimestamp = Funcoes.toUnixTimestamp(dataReserva);
                break;
            case 2:
                dataReserva = Funcoes.getNextHalfHour(currentDateTime.plusDays(7));
                unixTimestamp = Funcoes.toUnixTimestamp(dataReserva);
                break;
        }

        return unixTimestamp;
    }
}