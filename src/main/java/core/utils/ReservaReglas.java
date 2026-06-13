package core.utils;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;

/**
 * Reglas de negocio PURAS de las reservas (sin acceso a BD).
 *
 * <p>Se extrae aquí la lógica que antes vivía embebida en {@code ReservaService}
 * para poder validarla con pruebas unitarias sin necesitar MySQL ni un servidor.
 * El {@code ReservaService} delega en estos métodos; la consulta SQL de
 * disponibilidad implementa la misma regla de solape que {@link #haySolape}.
 */
public final class ReservaReglas {

    public static final DateTimeFormatter FORMATO_FECHA = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    private ReservaReglas() {
    }

    /**
     * Valida el rango de fechas y devuelve el número de noches (salida - entrada).
     *
     * @param exigirEntradaFutura si es {@code true}, la entrada no puede ser anterior a hoy.
     * @throws IllegalArgumentException si faltan fechas o el rango es inválido.
     */
    public static long calcularNoches(String fechaEntrada, String fechaSalida, boolean exigirEntradaFutura) {
        if (fechaEntrada == null || fechaSalida == null) {
            throw new IllegalArgumentException("Debe indicar fecha de entrada y fecha de salida");
        }

        LocalDate entrada = LocalDate.parse(fechaEntrada, FORMATO_FECHA);
        LocalDate salida = LocalDate.parse(fechaSalida, FORMATO_FECHA);

        if (!salida.isAfter(entrada)) {
            throw new IllegalArgumentException("La fecha de salida debe ser mayor que la fecha de entrada");
        }
        if (exigirEntradaFutura && entrada.isBefore(LocalDate.now())) {
            throw new IllegalArgumentException("La fecha de entrada no puede ser anterior a hoy");
        }

        return ChronoUnit.DAYS.between(entrada, salida);
    }

    /**
     * Regla de solape de fechas entre una reserva existente y un rango nuevo:
     * chocan si (entradaExistente &lt; salidaNueva) Y (salidaExistente &gt; entradaNueva).
     *
     * <p>Nota: un check-out que coincide con un check-in NO se considera solape
     * (la habitación queda libre el mismo día).
     */
    public static boolean haySolape(LocalDate entradaExistente, LocalDate salidaExistente,
                                    LocalDate entradaNueva, LocalDate salidaNueva) {
        return entradaExistente.isBefore(salidaNueva) && salidaExistente.isAfter(entradaNueva);
    }

    /** Variante que recibe las fechas en formato {@code yyyy-MM-dd}. */
    public static boolean haySolape(String entradaExistente, String salidaExistente,
                                    String entradaNueva, String salidaNueva) {
        return haySolape(
                LocalDate.parse(entradaExistente, FORMATO_FECHA),
                LocalDate.parse(salidaExistente, FORMATO_FECHA),
                LocalDate.parse(entradaNueva, FORMATO_FECHA),
                LocalDate.parse(salidaNueva, FORMATO_FECHA));
    }
}
