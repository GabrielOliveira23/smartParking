import cartago.*;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;

public class ParkPricing extends Artifact { 
    private static Map<TipoVagaEnum, Double> precos;
    
    void init() {
        precos = new HashMap<>();
        precos.put(TipoVagaEnum.CURTA, 10.0);
        precos.put(TipoVagaEnum.LONGA, 14.0);
        precos.put(TipoVagaEnum.CURTACOBERTA, 18.0);
        precos.put(TipoVagaEnum.LONGACOBERTA, 20.0);
    }

    public static Double getPreco(TipoVagaEnum tipoVaga) {
        return precos.getOrDefault(tipoVaga, 0.0);
    }

    @OPERATION
    void consultPrice(String tipoVaga) {
        if (tipoVaga != null) {
            TipoVagaEnum typeVaga = TipoVagaEnum.setTipoVaga(tipoVaga);
            Double precoTabela = getPreco(typeVaga);

            defineObsProperty("precoTabela", precoTabela);
        }
    }

    static double consultPrice(int idVaga) {
        String tipo = ParkControl.consultarTipoVaga(idVaga);
        if (tipo != null) {
            TipoVagaEnum typeVaga = TipoVagaEnum.setTipoVaga(tipo);
            return getPreco(typeVaga);
        }
        return 0.0;
    }

    
// levar para driver
    @OPERATION
    void defineVagaType() {
        Random random = new Random();
        int randomInt = random.nextInt(4);

        TipoVagaEnum tipoVaga = TipoVagaEnum.values()[randomInt];
        defineObsProperty("tipoVaga", tipoVaga.tipoVaga());
    }

    @OPERATION
    void consultTable(String tipoVaga) {
        if (tipoVaga != null) {
            TipoVagaEnum typeVaga = TipoVagaEnum.setTipoVaga(tipoVaga);
            Double precoTabela = getPreco(typeVaga);

            defineObsProperty("precoTabela", precoTabela);
        }
    }
    
    
}