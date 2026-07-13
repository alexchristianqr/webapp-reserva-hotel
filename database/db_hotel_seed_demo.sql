-- ***************************************************************************** --
-- SEED DE DEMOSTRACIÓN — db_hotel                                               --
-- ***************************************************************************** --
-- Genera un volumen realista de datos para que el módulo de Reportes se vea
-- "muy cargado" y consistente: más habitaciones y tipos, clientes, empleados,
-- productos y ~200 reservas repartidas en los últimos 12 meses, con consumos y
-- comprobantes coherentes.
--
-- CONSISTENCIA GARANTIZADA:
--   * reservas.monto_total = habitaciones.precio * numero_noches
--   * numero_noches = DATEDIFF(fecha_salida, fecha_entrada)
--   * reservas_consumo.precio = precio vigente del producto (se "congela")
--   * comprobantes solo para reservas en estado 'pagado'
--   * las fechas se calculan con NOW(), así que siempre caen en los últimos
--     12 meses respecto al momento en que se ejecuta este script.
--
-- USO (ejecutar DESPUÉS de database/db_hotel.sql):
--   mysql -u root db_hotel < database/db_hotel_seed_demo.sql
-- o abrir el archivo en MySQL Workbench y ejecutarlo completo.
-- ***************************************************************************** --

USE db_hotel;

-- --------------------------------------------------------------------------- --
-- 1) DATOS MAESTROS: tipos de habitación y habitaciones                       --
-- --------------------------------------------------------------------------- --
-- (el esquema base ya trae tipo 'clasico' con id 1 y la habitación 101)

INSERT INTO tipo_habitacion (descripcion) VALUES
    ('Matrimonial'),
    ('Doble'),
    ('Familiar'),
    ('Ejecutiva'),
    ('Suite');

-- Habitaciones por tipo (precios diferenciados para variar los ingresos por tipo).
-- Se referencian los tipos por su descripción para no depender de IDs fijos.
INSERT INTO habitaciones (id_tipohabitacion, descripcion, nivel, numero_piso, precio, cantidad_camas)
SELECT t.id, x.descripcion, x.nivel, x.numero_piso, x.precio, x.camas
FROM (
    -- Clásicas (~50)
    SELECT 'clasico'     AS tipo, 'Clásica con agua caliente + TV'      AS descripcion, '1' AS nivel, '102' AS numero_piso, 52.00 AS precio, 1 AS camas UNION ALL
    SELECT 'clasico',      'Clásica con vista interior',                  '1', '103', 55.00, 1 UNION ALL
    SELECT 'clasico',      'Clásica doble económica',                     '1', '104', 58.00, 2 UNION ALL
    SELECT 'clasico',      'Clásica con ventilador',                      '1', '105', 50.00, 1 UNION ALL
    -- Matrimoniales (~110)
    SELECT 'Matrimonial',  'Matrimonial estándar',                        '2', '201', 110.00, 1 UNION ALL
    SELECT 'Matrimonial',  'Matrimonial con balcón',                      '2', '202', 125.00, 1 UNION ALL
    SELECT 'Matrimonial',  'Matrimonial con vista a la ciudad',           '2', '203', 130.00, 1 UNION ALL
    SELECT 'Matrimonial',  'Matrimonial premium',                         '2', '204', 145.00, 1 UNION ALL
    -- Dobles (~85)
    SELECT 'Doble',        'Doble estándar',                              '2', '205', 85.00, 2 UNION ALL
    SELECT 'Doble',        'Doble con escritorio',                        '2', '206', 90.00, 2 UNION ALL
    SELECT 'Doble',        'Doble superior',                              '3', '301', 98.00, 2 UNION ALL
    SELECT 'Doble',        'Doble con vista al jardín',                   '3', '302', 95.00, 2 UNION ALL
    -- Familiares (~160)
    SELECT 'Familiar',     'Familiar 3 camas',                            '3', '303', 160.00, 3 UNION ALL
    SELECT 'Familiar',     'Familiar 4 camas',                            '3', '304', 185.00, 4 UNION ALL
    SELECT 'Familiar',     'Familiar con sala',                           '3', '305', 175.00, 3 UNION ALL
    -- Ejecutivas (~210)
    SELECT 'Ejecutiva',    'Ejecutiva con minibar',                       '4', '401', 210.00, 1 UNION ALL
    SELECT 'Ejecutiva',    'Ejecutiva doble',                             '4', '402', 235.00, 2 UNION ALL
    SELECT 'Ejecutiva',    'Ejecutiva con sala de trabajo',               '4', '403', 250.00, 1 UNION ALL
    -- Suites (~330)
    SELECT 'Suite',        'Suite junior',                                '5', '501', 320.00, 1 UNION ALL
    SELECT 'Suite',        'Suite con jacuzzi',                           '5', '502', 380.00, 1 UNION ALL
    SELECT 'Suite',        'Suite presidencial',                          '5', '503', 480.00, 2
) x
JOIN tipo_habitacion t ON t.descripcion = x.tipo;

-- --------------------------------------------------------------------------- --
-- 2) DATOS MAESTROS: productos (consumibles del hotel)                        --
-- --------------------------------------------------------------------------- --
-- (el esquema base ya trae 'botella de agua cielo' con id 1)

INSERT INTO productos (descripcion, precio, cantidad_stock) VALUES
    ('Gaseosa Inca Kola 500ml',        6.50, 500),
    ('Cerveza Cusqueña 330ml',         9.00, 400),
    ('Agua mineral San Luis 625ml',    4.50, 600),
    ('Snack de papas fritas',          5.00, 350),
    ('Barra de chocolate',             4.00, 300),
    ('Café americano',                 8.00, 999),
    ('Desayuno continental',          22.00, 999),
    ('Almuerzo ejecutivo',            28.00, 999),
    ('Cena a la carta',               38.00, 999),
    ('Servicio de lavandería',        18.00, 999),
    ('Late check-out',                30.00, 999),
    ('Botella de vino tinto',         55.00, 120),
    ('Tabla de piqueos',              32.00, 200),
    ('Jugo de naranja natural',       10.00, 250);

-- --------------------------------------------------------------------------- --
-- 3) PROCEDIMIENTOS GENERADORES                                               --
-- --------------------------------------------------------------------------- --

DELIMITER $$

-- 3.1) Genera N clientes (persona + usuario + cliente enlazados).
DROP PROCEDURE IF EXISTS sp_seed_clientes $$
CREATE PROCEDURE sp_seed_clientes(IN n INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_nombre VARCHAR(100);
    DECLARE v_apellido VARCHAR(100);
    DECLARE v_sexo CHAR(1);
    DECLARE v_edad VARCHAR(5);
    DECLARE v_tel VARCHAR(30);
    DECLARE v_doc VARCHAR(30);
    DECLARE v_user VARCHAR(100);
    DECLARE v_empresa VARCHAR(250);
    DECLARE v_persona INT;
    DECLARE v_usuario INT;
    DECLARE v_perfil INT;

    WHILE i < n DO
        SET v_nombre = ELT(FLOOR(1 + RAND()*20),
            'Juan','María','Carlos','Lucía','Pedro','Ana','Jorge','Rosa','Luis','Carmen',
            'Miguel','Elena','José','Sofía','Diego','Valeria','Fernando','Patricia','Andrés','Gabriela');
        SET v_apellido = ELT(FLOOR(1 + RAND()*20),
            'García','Rodríguez','Martínez','López','Gonzáles','Pérez','Sánchez','Ramírez','Torres','Flores',
            'Rivera','Vargas','Castro','Rojas','Mendoza','Chávez','Díaz','Reyes','Cruz','Morales');
        SET v_sexo = IF(RAND() < 0.5, 'M', 'F');
        SET v_edad = CAST(FLOOR(20 + RAND()*45) AS CHAR);
        SET v_tel = CONCAT('9', LPAD(FLOOR(RAND()*100000000), 8, '0'));
        SET v_doc = LPAD(40000000 + i, 8, '0');
        SET v_user = CONCAT('cliente', LPAD(i + 1, 3, '0'), '@demo.com');
        SET v_empresa = IF(RAND() < 0.30,
            ELT(FLOOR(1 + RAND()*6),
                'Inversiones Andinas SAC','Comercial Los Incas EIRL','TravelPeru Tours',
                'Corporación del Sur SA','Servicios Globales SAC','Minera Tierra Alta SAC'),
            NULL);

        INSERT INTO personas (nombre, apellido, tipo_documento, nrodocumento, sexo, edad, telefono)
        VALUES (v_nombre, v_apellido, 1, v_doc, v_sexo, v_edad, v_tel);
        SET v_persona = LAST_INSERT_ID();

        INSERT INTO usuarios (nombres, apellidos, rol, username, pwd, estado)
        VALUES (v_nombre, v_apellido, 'cliente', v_user, '12345678', 'activo');
        SET v_usuario = LAST_INSERT_ID();

        SELECT id INTO v_perfil FROM clientes_perfiles ORDER BY RAND() LIMIT 1;

        INSERT INTO clientes (id_persona, id_usuario, id_cliente_perfil, empresa)
        VALUES (v_persona, v_usuario, v_perfil, v_empresa);

        SET i = i + 1;
    END WHILE;
END $$

-- 3.2) Genera N empleados (persona + usuario + empleado enlazados).
DROP PROCEDURE IF EXISTS sp_seed_empleados $$
CREATE PROCEDURE sp_seed_empleados(IN n INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_nombre VARCHAR(100);
    DECLARE v_apellido VARCHAR(100);
    DECLARE v_sexo CHAR(1);
    DECLARE v_edad VARCHAR(5);
    DECLARE v_tel VARCHAR(30);
    DECLARE v_doc VARCHAR(30);
    DECLARE v_user VARCHAR(100);
    DECLARE v_sueldo DECIMAL(10,2);
    DECLARE v_persona INT;
    DECLARE v_usuario INT;
    DECLARE v_perfil INT;

    WHILE i < n DO
        SET v_nombre = ELT(FLOOR(1 + RAND()*10),
            'Ricardo','Milagros','Sergio','Katia','Óscar','Verónica','Raúl','Diana','Iván','Melissa');
        SET v_apellido = ELT(FLOOR(1 + RAND()*10),
            'Salazar','Núñez','Herrera','Paredes','Cáceres','Aguilar','Espinoza','Ríos','Salcedo','Bravo');
        SET v_sexo = IF(RAND() < 0.5, 'M', 'F');
        SET v_edad = CAST(FLOOR(22 + RAND()*38) AS CHAR);
        SET v_tel = CONCAT('9', LPAD(FLOOR(RAND()*100000000), 8, '0'));
        SET v_doc = LPAD(20000000 + i, 8, '0');
        SET v_user = CONCAT('empleado', LPAD(i + 1, 3, '0'), '@hotel.com');
        SET v_sueldo = ROUND(1200 + RAND()*2300, 2);

        INSERT INTO personas (nombre, apellido, tipo_documento, nrodocumento, sexo, edad, telefono)
        VALUES (v_nombre, v_apellido, 1, v_doc, v_sexo, v_edad, v_tel);
        SET v_persona = LAST_INSERT_ID();

        INSERT INTO usuarios (nombres, apellidos, rol, username, pwd, estado)
        VALUES (v_nombre, v_apellido, 'empleado', v_user, '12345678', 'activo');
        SET v_usuario = LAST_INSERT_ID();

        SELECT id INTO v_perfil FROM empleados_perfiles ORDER BY RAND() LIMIT 1;

        INSERT INTO empleados (id_persona, id_usuario, id_empleado_perfil, sueldo)
        VALUES (v_persona, v_usuario, v_perfil, v_sueldo);

        SET i = i + 1;
    END WHILE;
END $$

-- 3.3) Genera N reservas con consumos y comprobantes consistentes.
DROP PROCEDURE IF EXISTS sp_seed_operacion $$
CREATE PROCEDURE sp_seed_operacion(IN n INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_cliente INT;
    DECLARE v_empleado INT;
    DECLARE v_habitacion INT;
    DECLARE v_precio DECIMAL(10,2);
    DECLARE v_noches INT;
    DECLARE v_huespedes INT;
    DECLARE v_monto DECIMAL(10,2);
    DECLARE v_fecha_reserva DATETIME;
    DECLARE v_fecha_entrada DATETIME;
    DECLARE v_fecha_salida DATETIME;
    DECLARE v_estado VARCHAR(20);
    DECLARE v_reserva INT;
    DECLARE v_rand DOUBLE;
    DECLARE v_lineas INT;
    DECLARE j INT;
    DECLARE v_producto INT;
    DECLARE v_pprecio DECIMAL(10,2);
    DECLARE v_pcant INT;
    DECLARE v_tipo_comp INT;

    WHILE i < n DO
        SELECT id INTO v_cliente FROM clientes WHERE estado = 'activo' ORDER BY RAND() LIMIT 1;
        SELECT id INTO v_empleado FROM empleados WHERE estado = 'activo' ORDER BY RAND() LIMIT 1;
        SELECT id, precio INTO v_habitacion, v_precio FROM habitaciones WHERE estado = 'activo' ORDER BY RAND() LIMIT 1;

        SET v_noches = FLOOR(1 + RAND()*6);        -- 1..6 noches
        SET v_huespedes = FLOOR(1 + RAND()*3);     -- 1..3 huéspedes
        SET v_monto = v_precio * v_noches;         -- monto consistente

        -- fecha_reserva en los últimos 12 meses; entrada unos días después; salida = entrada + noches
        SET v_fecha_reserva = DATE_ADD(
            DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*365) DAY),
            INTERVAL FLOOR(RAND()*13) HOUR);
        SET v_fecha_entrada = DATE_ADD(DATE(v_fecha_reserva), INTERVAL FLOOR(RAND()*15) DAY);
        SET v_fecha_salida = DATE_ADD(v_fecha_entrada, INTERVAL v_noches DAY);

        -- estado ponderado (más pagadas/activas que canceladas)
        SET v_rand = RAND();
        IF v_rand < 0.45 THEN SET v_estado = 'pagado';
        ELSEIF v_rand < 0.68 THEN SET v_estado = 'activo';
        ELSEIF v_rand < 0.87 THEN SET v_estado = 'pendiente_pago';
        ELSE SET v_estado = 'cancelado';
        END IF;

        INSERT INTO reservas (id_cliente, id_habitacion, id_empleado, monto_total, numero_noches,
                              cantidad_huespedes, fecha_reserva, fecha_entrada, fecha_salida, estado, fecha_creado)
        VALUES (v_cliente, v_habitacion, v_empleado, v_monto, v_noches,
                v_huespedes, v_fecha_reserva, v_fecha_entrada, v_fecha_salida, v_estado, v_fecha_reserva);
        SET v_reserva = LAST_INSERT_ID();

        -- Consumos: ~70% de las reservas no canceladas tienen 1..3 líneas
        IF v_estado <> 'cancelado' AND RAND() < 0.70 THEN
            SET v_lineas = FLOOR(1 + RAND()*3);
            SET j = 0;
            WHILE j < v_lineas DO
                SELECT id, precio INTO v_producto, v_pprecio FROM productos WHERE estado = 'activo' ORDER BY RAND() LIMIT 1;
                SET v_pcant = FLOOR(1 + RAND()*4);
                INSERT INTO reservas_consumo (id_producto, id_reserva, cantidad, precio, fecha_creado)
                VALUES (v_producto, v_reserva, v_pcant, v_pprecio, v_fecha_entrada);
                SET j = j + 1;
            END WHILE;
        END IF;

        -- Comprobante solo para reservas pagadas
        IF v_estado = 'pagado' THEN
            SET v_tipo_comp = IF(RAND() < 0.5, 1, 2);  -- 1: FACTURA, 2: BOLETA
            INSERT INTO comprobantes (id_reserva, id_empleado, tipo_comprobante, estado, fecha_creado, fecha_pagado)
            VALUES (v_reserva, v_empleado, v_tipo_comp, 'pagado', v_fecha_salida, v_fecha_salida);
        END IF;

        SET i = i + 1;
    END WHILE;
END $$

DELIMITER ;

-- --------------------------------------------------------------------------- --
-- 4) EJECUCIÓN                                                                --
-- --------------------------------------------------------------------------- --

CALL sp_seed_empleados(5);     -- + 5 empleados (además del Alex del esquema base)
CALL sp_seed_clientes(25);     -- + 25 clientes
CALL sp_seed_operacion(200);   -- 200 reservas con consumos y comprobantes

-- Limpieza de los procedimientos auxiliares
DROP PROCEDURE IF EXISTS sp_seed_clientes;
DROP PROCEDURE IF EXISTS sp_seed_empleados;
DROP PROCEDURE IF EXISTS sp_seed_operacion;

-- --------------------------------------------------------------------------- --
-- 5) RESUMEN (comprobación rápida tras la carga)                              --
-- --------------------------------------------------------------------------- --
SELECT 'habitaciones' AS tabla, COUNT(*) AS total FROM habitaciones
UNION ALL SELECT 'tipo_habitacion', COUNT(*) FROM tipo_habitacion
UNION ALL SELECT 'productos',       COUNT(*) FROM productos
UNION ALL SELECT 'clientes',        COUNT(*) FROM clientes
UNION ALL SELECT 'empleados',       COUNT(*) FROM empleados
UNION ALL SELECT 'reservas',        COUNT(*) FROM reservas
UNION ALL SELECT 'reservas_consumo',COUNT(*) FROM reservas_consumo
UNION ALL SELECT 'comprobantes',    COUNT(*) FROM comprobantes;

-- Ingresos por estado (debe reflejarse en el gráfico "Reservas por estado")
SELECT estado, COUNT(*) AS reservas, SUM(monto_total) AS monto_hospedaje
FROM reservas GROUP BY estado ORDER BY reservas DESC;
