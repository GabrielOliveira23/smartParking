package env;

import cartago.*;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;

public class ParkPricing extends Artifact { 
    private Map<TipoVagaEnum, Double> precos;
    
    void init() {
        defineObsProperty("precoVaga", 0);

        precos = new HashMap<>();
        precos.put(TipoVagaEnum.CURTA, 10.0);
        precos.put(TipoVagaEnum.LONGA, 15.0);
        precos.put(TipoVagaEnum.COBERTA, 20.0);
        precos.put(TipoVagaEnum.DESCOBERTA, 12.0);
    }

    public Double getPreco(TipoVagaEnum tipoVaga) {
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