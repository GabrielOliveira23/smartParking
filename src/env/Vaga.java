import java.util.ArrayList;
import java.util.List;

public class Vaga {
    private String status;
    private String tipoVaga;
    private List<String[]> reservas;
    private List<Reserva> reservasNova;

    public Vaga(String status, String tipoVaga) {
        this.status = status;
        this.tipoVaga = tipoVaga;
        this.reservas = new ArrayList<>();
        this.reservasNova = new ArrayList<>();
    }

    public static List<Reserva> transformReservations(String reservations) {
        List<Reserva> reservas = new ArrayList<>();
        String[] rows = reservations.split("],\\[");

        for (String row : rows) {
            row = row.replace("[", "").replace("]", "");
            String[] columns = row.split(",");

            for (int i = 0; i < columns.length; i++) {
                columns[i] = columns[i].trim();
            }

            reservas.add(new Reserva(columns[0], columns[1], Integer.parseInt(columns[2])));
        }

        return reservas;
    }

    public static List<String[]> convertStringToReservations(String input) {
        input = input.substring(1, input.length() - 1);
        String[] rows = input.split("],\\[");

        List<String[]> listOfStringArrays = new ArrayList<>();

        for (String row : rows) {
            row = row.replace("[", "").replace("]", "");
            String[] columns = row.split(",");

            for (int i = 0; i < columns.length; i++) {
                columns[i] = columns[i].trim();
            }

            listOfStringArrays.add(columns);
        }

        return listOfStringArrays;
    }

    public List<String[]> getReservas() {
        return reservas;
    }

    public void setReservasNovo(String reservasMeta) {
        this.reservasNova = transformReservations(reservasMeta);
        for (Reserva reserva : reservasNova) {
            reserva.printReservaInfo();
        }
    }

    public List<Reserva> getReservasNova() {
        return reservasNova;
    }

    public void setReservas(String reservas) {
        this.reservas = convertStringToReservations(reservas);
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

    @Override
    public String toString() {
        return "Vaga{" +
                "status='" + this.status + '\'' +
                ", tipoVaga='" + this.tipoVaga + '\'' +
                ", reservas=" + this.reservasNova +
                '}';
    }
}
