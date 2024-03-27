public class NewVaga {
    private String status;
    private String tipoVaga;

    public NewVaga(String status, String tipoVaga) {
        this.status = status;
        this.tipoVaga = tipoVaga;
    }

    public String getStatus() {
        return status;
    }

    public String getTipoVaga() {
        return tipoVaga;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public void setTipoVaga(String tipoVaga) {
        this.tipoVaga = tipoVaga;
    }
}
