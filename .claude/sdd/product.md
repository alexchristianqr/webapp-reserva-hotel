# Visión de Producto

## Resumen

**webapp-reserva-hotel** es el sistema web interno de gestión de reservas del
**Hotel Tierra Colorada**. Centraliza la administración de clientes, habitaciones,
productos, empleados, usuarios y reservas en un único panel web operado por personal
autenticado del hotel.

## Problema que resuelve

El hotel necesita registrar y consultar reservas, controlar el inventario de
habitaciones y productos, y mantener los datos de clientes y empleados sin depender
de hojas de cálculo dispersas. El sistema ofrece un punto único de gestión con
control de acceso por sesión.

## Usuarios

| Rol        | Acceso                                                                 |
|------------|------------------------------------------------------------------------|
| `empleado` | Rol operativo principal. Inicia sesión y gestiona las entidades.       |
| `admin`    | Definido en el esquema (`usuarios.rol`); administración general.       |
| `cliente`  | Contemplado en el esquema y comentado en el código; **no activo** hoy. |

> Hoy el login solo habilita el flujo del rol `empleado` (ver `AuthService.login`).

## Capacidades (alcance actual)

Cada capacidad sigue el patrón CRUD por entidad, accesible desde su página JSP:

| Módulo        | Página JSP            | Servlet                  | Acciones típicas             |
|---------------|-----------------------|--------------------------|------------------------------|
| Autenticación | `login.jsp`           | `AutenticacionServlet`   | `login`, `logout`            |
| Clientes      | `clientes.jsp`        | `ClienteServlet`         | `listar`, `crear`, `actualizar` |
| Habitaciones  | `habitaciones.jsp`    | `HabitacionServlet`      | `listar`, `crear`, `actualizar` |
| Reservas      | `reservas.jsp`        | `ReservaServlet`         | `listar`, `crear`, `actualizar` |
| Empleados     | `empleados.jsp`       | (gestión vía controller) | `listar`, `crear`, `actualizar` |
| Usuarios      | `usuarios.jsp`        | (gestión vía controller) | `listar`, `crear`, `actualizar` |
| Productos     | `productos.jsp`       | (gestión vía controller) | `listar`, `crear`, `actualizar` |
| Inicio        | `home.jsp`            | `HomeServlet`            | panel / navegación           |
| Config        | `configuraciones.jsp` | —                        | accesos a los módulos        |

## Flujo principal: crear una reserva

1. El empleado inicia sesión (`login.jsp` → `AutenticacionServlet`).
2. Navega a `reservas.jsp`.
3. Selecciona cliente, habitación, fechas de entrada/salida y datos de la reserva.
4. El frontend Vue envía la acción `crear` a `ReservaServlet`.
5. El backend calcula el monto, persiste la reserva y devuelve `ResponseService`.
6. La tabla se refresca con la nueva reserva.

## Fuera de alcance (hoy)

- Portal de auto-reserva para clientes finales.
- Pasarela de pagos real (existe la tabla `comprobantes` y estados de pago, pero no
  integración externa).
- Reportería avanzada / dashboards analíticos.
- Multi-hotel / multi-sucursal.

## Oportunidades futuras (backlog informal)

- Activar el rol `cliente` (código ya esbozado y comentado en `AuthService`).
- Hash de contraseñas y configuración externa de credenciales de BD.
- Gestión de consumo de productos por reserva (`reservas_consumo`) y comprobantes.
