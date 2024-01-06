import java.util.ArrayList;
import java.util.List;

public class Vaga {
    private int id;
    private TipoVagaEnum tipoVaga;
    private boolean disponivel;
    private List<String> reservas;

    public Vaga(int id, TipoVagaEnum tipoVaga) {
        this.id = id;
        this.tipoVaga = tipoVaga;
        this.disponivel = true;
        reservas = new ArrayList<String>();
    }

    public void reservarVaga(String data, String hora) {
        this.disponivel = false;
        reservas.add(data + " - " + hora);
    }

    public List<String> getReservas() {
        return reservas;
    }

    public int getId() {
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