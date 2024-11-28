import java.util.ArrayList;
import java.util.List;

public class Vaga {
    private String status;
    private String tipoVaga;
    private List<Reserva> reservas;

    public Vaga(String status, String tipoVaga) {
        this.status = status;
        this.tipoVaga = tipoVaga;
        this.reservas = new ArrayList<>();
    }

    public static List<Reserva> transformarReservas(String reservations) {
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

    public static String convertReservationsToString(List<Reserva> reservations) {
        String result = "";
        for (Reserva reserva : reservations) {
            result += "[" + reserva.getId() + "," + reserva.getData() + "," + reserva.getTempoUso() + "],";
        }

        return result.substring(0, result.length() - 1);
    }

    public void setReservas(String reservasMeta) {
        this.reservas = transformarReservas(reservasMeta);
    }

    public List<Reserva> getReservas() {
        return this.reservas;
    }

    public String getStatus() {
        return this.status;
    }

    public String getTipoVaga() {
        return this.tipoVaga;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public void setTipoVaga(String tipoVaga) {
        this.tipoVaga = tipoVaga;
    }
}
