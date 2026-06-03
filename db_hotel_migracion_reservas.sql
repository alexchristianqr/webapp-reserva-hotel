-- ************************************************************ --
-- Migración: campos de gestión de reservas                     --
-- Ejecutar SOLO sobre una BD db_hotel ya existente.            --
-- (En instalaciones nuevas basta con correr db_hotel.sql)      --
-- ************************************************************ --

USE db_hotel;

-- número de noches calculado al crear/actualizar la reserva (salida - entrada)
ALTER TABLE reservas
    ADD COLUMN numero_noches INT NOT NULL DEFAULT 1 AFTER monto_total;

-- cantidad de huéspedes que ocuparán la habitación
ALTER TABLE reservas
    ADD COLUMN cantidad_huespedes INT NOT NULL DEFAULT 1 AFTER numero_noches;

-- normaliza datos antiguos: recalcula las noches a partir de las fechas
UPDATE reservas
SET numero_noches = GREATEST(1, DATEDIFF(fecha_salida, fecha_entrada))
WHERE fecha_entrada IS NOT NULL AND fecha_salida IS NOT NULL;
