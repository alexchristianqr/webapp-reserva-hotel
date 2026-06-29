# Modelo de Dominio

Esquema real de la base de datos `db_hotel` (ver `database/db_hotel.sql` y las
migraciones `database/db_hotel_migracion_*.sql`) y su correspondencia con los POJOs de
`src/main/java/models/`. Esta es la **fuente de verdad** del modelo de datos.

## Diagrama de relaciones

```
usuarios ──┐
           ├──< empleados >── empleados_perfiles
personas ──┤        │
           └──< clientes >──── clientes_perfiles
                    │              │
                    │              └─ (id_usuario)
                    ▼
tipo_habitacion ──< habitaciones ──< reservas >── empleados
                                        │  ▲
                                        │  └── clientes
                                        ▼
                              reservas_consumo >── productos
                                        │
reservas ──< comprobantes >── empleados
```

## Tablas

### `usuarios`
Credenciales y rol de acceso.
| Columna | Tipo | Notas |
|---------|------|-------|
| id | INT PK AI | |
| nombres, apellidos | VARCHAR(100) | |
| rol | ENUM('cliente','empleado','admin') | |
| username | VARCHAR(100) | UNIQUE(username, estado) |
| pwd | VARCHAR(250) | hash bcrypt |
| estado | ENUM('activo','inactivo') | default 'activo' |
| fecha_creado / fecha_actualizado / fecha_eliminado | DATETIME | |

### `personas`
Datos personales compartidos por clientes y empleados.
| Columna | Tipo | Notas |
|---------|------|-------|
| id | INT PK AI | |
| nombre, apellido | VARCHAR(100) | |
| tipo_documento | INT | 1=DNI, 2=Pasaporte (convención de UI) |
| nrodocumento | VARCHAR(30) | UNIQUE(tipo_documento, nrodocumento) |
| sexo | ENUM('F','M') | |
| edad | VARCHAR(5) | almacenado como texto |
| telefono | VARCHAR(30) | |
| fecha_nacimiento | VARCHAR(30) | |
| estado_civil | ENUM('soltero','casado','viudo') | default 'soltero' |
| estado | ENUM('activo','inactivo') | default 'activo' |
| fecha_creado / fecha_actualizado | DATETIME | |

### `clientes`
| Columna | Tipo | Notas |
|---------|------|-------|
| id | INT PK AI | |
| id_persona | INT FK→personas | |
| id_usuario | INT FK→usuarios | |
| id_cliente_perfil | INT FK→clientes_perfiles | |
| empresa | VARCHAR(250) | |
| estado, fecha_creado, fecha_actualizado | | |

### `clientes_perfiles`
Perfiles/permisos de cliente: `id, nombre, permisos (TEXT), estado, fechas`.

### `empleados`
| Columna | Tipo | Notas |
|---------|------|-------|
| id | INT PK AI | |
| id_persona | INT FK→personas | |
| id_usuario | INT FK→usuarios | |
| id_empleado_perfil | INT FK→empleados_perfiles | |
| sueldo | DECIMAL(10,2) | |
| estado, fecha_creado, fecha_actualizado | | |

### `empleados_perfiles`
Perfiles/permisos de empleado: `id, nombre, permisos (TEXT), estado, fechas`.

### `tipo_habitacion`
`id, descripcion, fechas`.

### `habitaciones`
| Columna | Tipo | Notas |
|---------|------|-------|
| id | INT PK AI | |
| id_tipohabitacion | INT FK→tipo_habitacion | |
| descripcion | VARCHAR(250) | |
| nivel, numero_piso | VARCHAR(25) | |
| precio | DECIMAL(10,2) | |
| cantidad_camas | INT | |
| estado, fechas | | |

### `productos`
`id, descripcion, precio DECIMAL, cantidad_stock INT, estado, fechas`.

### `reservas`
| Columna | Tipo | Notas |
|---------|------|-------|
| id | INT PK AI | |
| id_cliente | INT FK→clientes | |
| id_habitacion | INT FK→habitaciones | |
| id_empleado | INT FK→empleados | |
| monto_total | DECIMAL(10,2) | |
| fecha_reserva / fecha_entrada / fecha_salida | DATETIME | |
| estado | ENUM('activo','pendiente_pago','pagado','cancelado') | default 'activo' |
| fecha_creado / fecha_actualizado | DATETIME | |

### `reservas_consumo`
Productos consumidos durante una reserva.
`id, id_reserva, id_producto, cantidad, precio DECIMAL(10,2), estado, fechas`.

### `comprobantes`
| Columna | Tipo | Notas |
|---------|------|-------|
| id | INT PK AI | |
| id_reserva | INT FK→reservas | |
| id_empleado | INT FK→empleados | |
| tipo_comprobante | INT | 1=FACTURA, 2=BOLETA |
| estado | ENUM('activo','pendiente_pago','pagado','cancelado') | |
| fecha_creado / fecha_pagado | DATETIME | |

## POJOs (`src/main/java/models/`)

| Modelo | Extiende | Notas |
|--------|----------|-------|
| `Persona` | — | base con nombre, apellidos, documento, sexo, edad, teléfono, estado, fechas |
| `Cliente` | `Persona` | añade `idCliente` |
| `Empleado` | `Persona` | añade `idEmpleado`, `idPersona`, `idUsuario`, sueldo, etc. |
| `Usuario` | — | credenciales + rol; referencia a `Empleado`/`Cliente` |
| `Habitacion` | — | tipo, nivel, piso, precio, camas |
| `Producto` | — | descripción, precio, stock |
| `Reserva` | — | referencias a `Cliente`, `Empleado`, `Habitacion`; montos y fechas |

## Convenciones del modelo

- Los campos de fecha se manejan frecuentemente como `String` en los POJOs.
- `tipo_documento`: `1`=DNI, `2`=Pasaporte (mapeo de la UI, no enum en BD).
- `estado` textual `'activo'`/`'inactivo'` en la mayoría de entidades.
- Al crear una persona-derivada (cliente/empleado) se inserta primero en `personas` y
  luego en la tabla específica usando el `id` generado.
- La regla de solape de reservas (no reservar la misma habitación en fechas que se
  cruzan) está implementada tanto en `core.utils.ReservaReglas.haySolape` como en el SQL
  de `disponibilidad`; ambas deben mantenerse equivalentes.
