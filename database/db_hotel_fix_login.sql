-- ***************************************************************************** --
-- FIX LOGIN — db_hotel                                                          --
-- ***************************************************************************** --
-- Deja una (o varias) cuenta(s) LISTA(S) para iniciar sesión, creando o
-- reparando TODO lo que el login necesita:
--   * usuarios: rol='empleado', estado='activo', pwd en texto plano conocido
--     (la app la re-hashea a bcrypt en el primer login correcto).
--   * personas: una fila para el empleado.
--   * empleados_perfiles: al menos un perfil.
--   * empleados: una fila ACTIVA vinculada al usuario (esto es lo que faltaba y
--     hacía que el login respondiera "Credenciales inválidas").
--
-- Es IDEMPOTENTE: puedes ejecutarlo las veces que quieras. Repara la cuenta si
-- ya existe o la crea desde cero si no existe.
--
-- USO:  mysql -u root db_hotel < database/db_hotel_fix_login.sql
--
-- CREDENCIALES QUE DEJA LISTAS:
--   usuario: admin@hotel.com          clave: Hotel2026!
--   usuario: alex.quispe@gmail.com    clave: Hotel2026!
-- ***************************************************************************** --

USE db_hotel;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_fix_login $$
CREATE PROCEDURE sp_fix_login(
    IN p_username VARCHAR(100),
    IN p_password VARCHAR(250),
    IN p_nombre   VARCHAR(100),
    IN p_apellido VARCHAR(100),
    IN p_doc      VARCHAR(30)
)
BEGIN
    DECLARE v_usuario  INT DEFAULT NULL;
    DECLARE v_persona  INT DEFAULT NULL;
    DECLARE v_empleado INT DEFAULT NULL;
    DECLARE v_perfil   INT DEFAULT NULL;

    -- 1) Asegurar que exista al menos un perfil de empleado
    SELECT id INTO v_perfil FROM empleados_perfiles ORDER BY id LIMIT 1;
    IF v_perfil IS NULL THEN
        INSERT INTO empleados_perfiles (nombre, permisos) VALUES ('Administrador', '{}');
        SET v_perfil = LAST_INSERT_ID();
    END IF;

    -- 2) Usuario: crear o reparar (activo, rol empleado, clave conocida)
    SELECT id INTO v_usuario FROM usuarios
        WHERE username = p_username
        ORDER BY (estado = 'activo') DESC, id DESC LIMIT 1;
    IF v_usuario IS NULL THEN
        INSERT INTO usuarios (nombres, apellidos, rol, username, pwd, estado)
        VALUES (p_nombre, p_apellido, 'empleado', p_username, p_password, 'activo');
        SET v_usuario = LAST_INSERT_ID();
    ELSE
        UPDATE usuarios
        SET rol = 'empleado', estado = 'activo', pwd = p_password,
            nombres = IF(nombres IS NULL OR nombres = '', p_nombre, nombres),
            apellidos = IF(apellidos IS NULL OR apellidos = '', p_apellido, apellidos)
        WHERE id = v_usuario;
    END IF;

    -- 3) Persona: reutilizar la del empleado existente; si no, por documento; si no, crear
    SELECT e.id_persona INTO v_persona FROM empleados e
        WHERE e.id_usuario = v_usuario ORDER BY e.id DESC LIMIT 1;
    IF v_persona IS NULL THEN
        SELECT id INTO v_persona FROM personas
            WHERE tipo_documento = 1 AND nrodocumento = p_doc LIMIT 1;
    END IF;
    IF v_persona IS NULL THEN
        INSERT INTO personas (nombre, apellido, tipo_documento, nrodocumento, sexo, edad, estado)
        VALUES (p_nombre, p_apellido, 1, p_doc, 'M', '30', 'activo');
        SET v_persona = LAST_INSERT_ID();
    END IF;

    -- 4) Empleado: crear uno activo vinculado o reactivar el existente
    SELECT id INTO v_empleado FROM empleados
        WHERE id_usuario = v_usuario ORDER BY id DESC LIMIT 1;
    IF v_empleado IS NULL THEN
        INSERT INTO empleados (id_persona, id_usuario, id_empleado_perfil, sueldo, estado)
        VALUES (v_persona, v_usuario, v_perfil, 1500.00, 'activo');
    ELSE
        UPDATE empleados
        SET estado = 'activo', id_persona = v_persona, id_empleado_perfil = v_perfil
        WHERE id = v_empleado;
    END IF;
END $$

DELIMITER ;

-- Dejar listas dos cuentas (clave: Hotel2026!)
CALL sp_fix_login('admin@hotel.com',       'Hotel2026!', 'Administrador', 'General', '10000001');
CALL sp_fix_login('alex.quispe@gmail.com', 'Hotel2026!', 'Alex',          'Quispe',  '12345678');

DROP PROCEDURE sp_fix_login;

-- Verificación: cuentas que YA pueden iniciar sesión (empleado activo vinculado)
SELECT u.id, u.username, u.rol, u.estado AS usuario_estado,
       e.id AS empleado_id, e.estado AS empleado_estado
FROM usuarios u
JOIN empleados e ON e.id_usuario = u.id AND e.estado = 'activo'
WHERE u.estado = 'activo'
ORDER BY u.id;
