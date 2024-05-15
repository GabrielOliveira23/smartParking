import java.util.ArrayList;
import java.util.List;

public class Vaga {
    private String status;
    private String tipoVaga;
    private List<String[]> reservas;

    public Vaga(String status, String tipoVaga, String reservas) {
        this.status = status;
        this.tipoVaga = tipoVaga;
        this.reservas = new ArrayList<>();
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
}
