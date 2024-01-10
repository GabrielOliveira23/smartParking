public enum TipoVagaEnum {
    LONGA,
    CURTA,
    LONGACOBERTA,
    CURTACOBERTA;

    public String tipoVaga() {
        switch (this) {
            case LONGA:
                return "Longa";
            case CURTA:
                return "Curta";
            case LONGACOBERTA:
                return "LongaCoberta";
            case CURTACOBERTA:
                return "CurtaCoberta";
            default:
                return "Tipo de vaga inválido";
        }
    }

    public static TipoVagaEnum setTipoVaga(String tipoVaga) {
        tipoVaga = tipoVaga.toUpperCase();
        try {
            return TipoVagaEnum.valueOf(tipoVaga);
        } catch (IllegalArgumentException e) {
            System.out.println("Tipo de vaga inválido");
            return null; 
        }
    }
}
