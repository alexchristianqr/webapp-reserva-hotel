package core.utils;

import at.favre.lib.crypto.bcrypt.BCrypt;

/**
 * Utilidad PURA para el manejo seguro de contraseñas con bcrypt.
 *
 * <p>Las contraseñas NUNCA deben guardarse en texto plano. Esta clase centraliza
 * el hashing (al crear o actualizar credenciales) y la verificación (al iniciar
 * sesión), de modo que el resto de servicios no dependa directamente de bcrypt.
 *
 * <p>bcrypt incorpora la sal dentro del propio hash y un factor de costo
 * configurable, por lo que el mismo texto produce hashes distintos y la
 * comparación se hace siempre con {@link #verificar(String, String)}.
 */
public final class PasswordUtil {

    /**
     * Factor de costo (2^COSTO iteraciones). 12 es un balance razonable entre
     * seguridad y rendimiento para una app web; subirlo encarece cada login.
     */
    private static final int COSTO = 12;

    private PasswordUtil() {
    }

    /** Genera el hash bcrypt de una contraseña en texto plano. */
    public static String hashear(String passwordPlano) {
        if (passwordPlano == null || passwordPlano.isBlank()) {
            throw new IllegalArgumentException("La contraseña no puede estar vacía");
        }
        return BCrypt.withDefaults().hashToString(COSTO, passwordPlano.toCharArray());
    }

    /**
     * Verifica una contraseña en texto plano contra el valor guardado en BD.
     *
     * <p>Si el valor guardado es un hash bcrypt se valida con bcrypt. Si es una
     * contraseña heredada en texto plano (datos antiguos previos a esta mejora)
     * se compara directamente, para no romper las cuentas ya existentes; esos
     * registros se re-hashean de forma transparente al iniciar sesión.
     */
    public static boolean verificar(String passwordPlano, String hashGuardado) {
        if (passwordPlano == null || hashGuardado == null || hashGuardado.isBlank()) {
            return false;
        }
        if (esHashBcrypt(hashGuardado)) {
            return BCrypt.verifyer().verify(passwordPlano.toCharArray(), hashGuardado).verified;
        }
        // Compatibilidad con contraseñas heredadas en texto plano
        return passwordPlano.equals(hashGuardado);
    }

    /** Indica si el valor almacenado ya está hasheado con bcrypt. */
    public static boolean esHashBcrypt(String valor) {
        return valor != null && (valor.startsWith("$2a$") || valor.startsWith("$2b$") || valor.startsWith("$2y$"));
    }
}
