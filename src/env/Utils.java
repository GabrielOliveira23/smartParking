import java.util.Random;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

import cartago.*;

public class Utils extends Artifact {
    private int counter = 0;
    private int counterSuccess = 0;
    private int counterVellus = 0;
    private int counterDriversCicles = 0;
    private ScheduledExecutorService scheduler;

    void init() {
        scheduler = Executors.newScheduledThreadPool(1);
        startPrintContador();
    }

    void startPrintContador() {
        scheduler.scheduleAtFixedRate(new Runnable() {
            @Override
            public void run() {
                execInternalOp("printContador");
            }
        }, 0, 10, TimeUnit.SECONDS);
    }

    @INTERNAL_OPERATION
    void printContador() {
        log("Negociações com sucesso: " + this.counterSuccess + "/" + this.counter);
        log("Transações realizadas pelo Velluscinum: " + this.counterVellus);
        log("Ciclos de motoristas: " + this.counterDriversCicles);
    }

    @OPERATION
    void stringToNumber(String str, OpFeedbackParam<Double> result) {
        try {
            double number = Double.parseDouble(str);
            result.set(number);
        } catch (NumberFormatException e) {
            failed("Invalid number format");
        }
    }

    @OPERATION
    void incNegociacoes() {
        this.counter++;
    }

    @OPERATION
    void incNegociacoesBemSucedidas() {
        this.counterSuccess++;
    }

    @OPERATION
    void incContadorTransacoesVellus() {
        this.counterVellus++;
    }

    @OPERATION
    void incCiclosMotoristas() {
        this.counterDriversCicles++;
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
}
