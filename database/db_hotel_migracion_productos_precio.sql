-- ************************************************************ --
-- Migración: corrige el tipo de productos.precio                --
-- Ejecutar SOLO sobre una BD db_hotel ya existente.            --
-- (En instalaciones nuevas basta con correr db_hotel.sql)      --
--                                                              --
-- Causa del bug "Productos: no actualiza bien": la columna     --
-- precio estaba declarada como DECIMAL (escala 0), por lo que  --
-- MySQL redondeaba el precio a un entero en cada guardado.     --
-- ************************************************************ --

USE db_hotel;

ALTER TABLE productos
    MODIFY COLUMN precio DECIMAL(10,2) NOT NULL;
