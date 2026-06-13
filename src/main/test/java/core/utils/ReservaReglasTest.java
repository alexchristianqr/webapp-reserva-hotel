package core.utils;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/**
 * Pruebas UNITARIAS de la lógica de negocio central de las reservas.
 *
 * <p>No necesitan MySQL ni Tomcat: validan reglas puras de {@link ReservaReglas}.
 * Se ejecutan con: {@code mvn test} (fase test, plugin surefire).
 */
class ReservaReglasTest {

    // ---------------------------------------------------------------
    // PRUEBA 1: cálculo de noches y validación del rango de fechas
    // (regla central del precio: monto = precio_noche * noches)
    // ---------------------------------------------------------------
    @Nested
    @DisplayName("calcularNoches")
    class CalcularNoches {

        @Test
        @DisplayName("cuenta correctamente las noches de un rango válido")
        void calculaNochesDeRangoValido() {
            long noches = ReservaReglas.calcularNoches("2026-06-10", "2026-06-13", false);
            assertEquals(3L, noches, "Del 10 al 13 deben ser 3 noches");
        }

        @Test
        @DisplayName("rechaza salida <= entrada")
        void rechazaSalidaNoPosterior() {
            IllegalArgumentException ex = assertThrows(
                    IllegalArgumentException.class,
                    () -> ReservaReglas.calcularNoches("2026-06-13", "2026-06-13", false));
            assertTrue(ex.getMessage().toLowerCase().contains("salida"));
        }

        @Test
        @DisplayName("rechaza fechas nulas")
        void rechazaFechasNulas() {
            assertThrows(IllegalArgumentException.class,
                    () -> ReservaReglas.calcularNoches(null, "2026-06-13", false));
        }
    }

    // ---------------------------------------------------------------
    // PRUEBA 2: regla de disponibilidad (cruce de fechas)
    // Es el corazón del sistema: evita doble reserva de una habitación.
    // ---------------------------------------------------------------
    @Nested
    @DisplayName("hayCruce (disponibilidad de habitación)")
    class HaySolape {

        @Test
        @DisplayName("detecta cruce cuando los rangos se cruzan")
        void detectaSolapeParcial() {
            // Existente 10-15, nueva 12-18 -> se cruzan
            assertTrue(ReservaReglas.haySolape("2026-06-10", "2026-06-15", "2026-06-12", "2026-06-18"));
        }

        @Test
        @DisplayName("NO hay cruce cuando el check-out coincide con el check-in")
        void sinSolapeEnFronteraExacta() {
            // Existente 10-13, nueva 13-16 -> la habitación queda libre el día 13
            assertFalse(ReservaReglas.haySolape("2026-06-10", "2026-06-13", "2026-06-13", "2026-06-16"));
        }

        @Test
        @DisplayName("NO hay cruce entre rangos completamente separados")
        void sinSolapeRangosSeparados() {
            assertFalse(ReservaReglas.haySolape("2026-06-01", "2026-06-05", "2026-06-20", "2026-06-25"));
        }
    }
}
