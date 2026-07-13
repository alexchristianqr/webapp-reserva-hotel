-- ***************************************************************************** --
-- RESET DE CONTRASEÑA — db_hotel                                                --
-- ***************************************************************************** --
-- La app guarda las contraseñas con bcrypt, pero acepta un valor en TEXTO PLANO
-- como contraseña heredada y lo re-hashea a bcrypt en el primer inicio de sesión
-- correcto (ver core.utils.PasswordUtil.verificar). Por eso, para "resetear" basta
-- con escribir la nueva clave en texto plano en usuarios.pwd.
--
-- IMPORTANTE: para poder iniciar sesión, la cuenta debe cumplir DOS cosas:
--   1) rol = 'empleado' y usuarios.estado = 'activo'
--   2) tener una fila ACTIVA en 'empleados' vinculada (empleados.id_usuario = usuarios.id)
-- Si no hay empleado activo vinculado, el login responde "Credenciales inválidas".
--
-- USO:  mysql -u root db_hotel < database/db_hotel_reset_password.sql
-- ***************************************************************************** --

USE db_hotel;

-- 1) RESET de la cuenta base (Alex): tiene empleado vinculado -> login garantizado.
--    Credenciales resultantes ->  usuario: alex.quispe@gmail.com   clave: Hotel2026!
UPDATE usuarios
SET pwd = 'Hotel2026!'
WHERE username = 'alex.quispe@gmail.com';

-- 2) RESET genérico para CUALQUIER cuenta (descomenta y ajusta):
-- UPDATE usuarios SET pwd = 'NuevaClave123' WHERE username = 'TU_CORREO';

-- 3) ¿Con qué cuentas SÍ puedo entrar? (empleado activo vinculado)
--    Usa cualquiera de estos 'username' con la clave que le hayas puesto arriba.
SELECT u.id, u.username, u.rol, u.estado AS usuario_estado,
       e.id AS empleado_id, e.estado AS empleado_estado
FROM usuarios u
JOIN empleados e ON e.id_usuario = u.id AND e.estado = 'activo'
WHERE u.estado = 'activo'
ORDER BY u.id;

-- 4) (Opcional) Si tu cuenta NO aparece arriba porque le falta el empleado,
--    puedes vincularle uno. Ejemplo para 'TU_CORREO' creando persona + empleado:
-- INSERT INTO personas (nombre, apellido, tipo_documento, nrodocumento, sexo, edad)
-- VALUES ('Nombre', 'Apellido', 1, '99999999', 'M', '30');
-- INSERT INTO empleados (id_persona, id_usuario, id_empleado_perfil, sueldo)
-- VALUES (LAST_INSERT_ID(),
--         (SELECT id FROM usuarios WHERE username = 'TU_CORREO' AND estado='activo'),
--         (SELECT id FROM empleados_perfiles ORDER BY id LIMIT 1),
--         1500.00);
