public class Reserva {
    private String id;
    protected String data;
    protected int tempoUso;

    public Reserva(String id, String data, int tempoUso) {
        this.id = id;
        this.data = data;
        this.tempoUso = tempoUso;
    }

    public void printReservaInfo() {
        System.out.println("\nReserva ID: " + id);
        System.out.println("Data: " + data);
        System.out.println("Tempo de uso: " + tempoUso);
        System.out.println();
    }

    public static String tratarRegistro(Reserva novaReserva, String status) {
        return "status:" + status + ";reservas:[[" + novaReserva.getId() + ","
                + novaReserva.data + "," + novaReserva.tempoUso + "]]";
    }

    public static String tratarRegistro(KeyValueObject registro, Reserva novaReserva, String status) {
        return "status:" + status + ";reservas:["
                + registro.getValue().substring(1, registro.getValue().length() - 1) + ",[" + novaReserva.getId() + ","
                + novaReserva.data + "," + novaReserva.tempoUso + "]]";
    }

    public Long getDataFinalPrevista() {
        return Long.parseLong(data) + tempoUso;
    }

    public String getId() {
        return id;
    }

    public String getData() {
        return data;
    }

    public int getTempoUso() {
        return tempoUso;
    }

    public void setId(String id) {
        this.id = id;
    }

    public void setData(String data) {
        this.data = data;
    }

    public void setTempoUso(int tempoUso) {
        this.tempoUso = tempoUso;
    }
}
