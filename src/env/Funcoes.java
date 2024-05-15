import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

public class Funcoes {
    public static LocalDateTime getNextHalfHour(LocalDateTime currentDateTime) {
        int minute = currentDateTime.getMinute();

        if (minute < 30)
            return currentDateTime.withMinute(30).withSecond(0).withNano(0);

        else
            return currentDateTime.plusHours(1).withMinute(0).withSecond(0).withNano(0);
    }

    public static long toUnixTimestamp(LocalDateTime dateTime) {
        return dateTime.toInstant(ZoneOffset.UTC).toEpochMilli() / 1000;
    }

    public static boolean isBetweenDates(long timestamp, long startTimestamp, long endTimestamp) {
        return timestamp >= startTimestamp && timestamp <= endTimestamp;
    }

    public static boolean hasConflict(long startTimestamp1, long endTimestamp1, long startTimestamp2,
            long endTimestamp2) {
        return (startTimestamp1 <= endTimestamp2 && endTimestamp1 >= startTimestamp2);
    }

    public static Long getDateWithMinutesAfter(Long date, int minutes) {
        Instant instant = Instant.ofEpochSecond(date);
        Instant newInstant = instant.plus(Duration.ofMinutes(minutes));
        long newUnixTimestamp = newInstant.getEpochSecond();
        return newUnixTimestamp;
    }
}
