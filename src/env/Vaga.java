import java.util.ArrayList;
import java.util.List;

public class Vaga {
    private String id;
    private TipoVagaEnum tipoVaga;
    private boolean disponivel;
    private List<String> reservas;

    public Vaga(String id, TipoVagaEnum tipoVaga, String status) {
        this.id = id;
        this.tipoVaga = tipoVaga;
        if(status.equals("disponivel"))
            this.disponivel = true;
        else
            this.disponivel = false;
        reservas = new ArrayList<String>();
    }

    public void reservarVaga(String data, String hora) {
        this.disponivel = false;
        reservas.add(data + " - " + hora);
    }

    public List<String> getReservas() {
        return reservas;
    }

    public String getId() {
        return id;
    }

    public boolean isDisponivel() {
        return disponivel;
    }

    public void ocuparVaga() {
        this.disponivel = false;
    }

    public void liberarVaga() {
        this.disponivel = true;
    }

    public String getVagaInfo() {
        System.out.println("Vaga: " + this.id + " - " + this.tipoVaga.tipoVaga() + " - " + this.disponivel);
        return "Vaga: " + this.id + " - " + this.tipoVaga.tipoVaga() + " - " + this.disponivel;
    }

    public String getTipoVaga() {
        return this.tipoVaga.tipoVaga().toString().toUpperCase();
    }
}