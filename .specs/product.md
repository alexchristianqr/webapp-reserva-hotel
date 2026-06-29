# Visión de Producto

## Resumen

**webapp-reserva-hotel** es el sistema web interno de gestión de reservas del
**Hotel Tierra Colorada**. Centraliza la administración de clientes, habitaciones,
productos, empleados, usuarios, reservas, consumos y comprobantes en un único panel
web operado por personal autenticado del hotel, e incluye la emisión de reportes PDF
de reservas.

## Problema que resuelve

El hotel necesita registrar y consultar reservas, controlar el inventario de
habitaciones y productos, y mantener los datos de clientes y empleados sin depender de
hojas de cálculo dispersas. El sistema ofrece un punto único de gestión con control de
acceso por sesión.

## Usuarios

| Rol        | Acceso                                                                 |
|------------|------------------------------------------------------------------------|
| `empleado` | Rol operativo principal. Inicia sesión y gestiona las entidades.       |
| `admin`    | Definido en el esquema (`usuarios.rol`); administración general.        |
| `cliente`  | Contemplado en el esquema y comentado en el código; **no activo** hoy. |

> Hoy el inicio de sesión habilita el flujo del rol `empleado` (ver `AuthService.login`).

## Capacidades (alcance actual)

Cada capacidad sigue el patrón CRUD por entidad, accesible desde su página JSP:

| Módulo        | Página JSP            | Servlet                  | Acciones típicas                              |
|---------------|-----------------------|--------------------------|-----------------------------------------------|
| Autenticación | `login.jsp`           | `AutenticacionServlet`   | `login`, `logout`                             |
| Clientes      | `clientes.jsp`        | `ClienteServlet`         | `listar`, `crear`, `actualizar`, `eliminar`   |
| Habitaciones  | `habitaciones.jsp`    | `HabitacionServlet`      | `listar`, `crear`, `actualizar`, `eliminar`, `tipos` |
| Productos     | `productos.jsp`       | `ProductoServlet`        | `listar`, `crear`, `actualizar`, `eliminar`   |
| Empleados     | `empleados.jsp`       | `EmpleadoServlet`        | `listar`, `crear`, `actualizar`, `eliminar`   |
| Usuarios      | `usuarios.jsp`        | `UsuarioServlet`         | `listar`, `crear`, `actualizar`, `eliminar`   |
| Reservas      | `reservas.jsp`        | `ReservaServlet`         | `listar`, `disponibilidad`, `crear`, `actualizar`, `eliminar` |
| Consumos      | `consumos.jsp`        | `ConsumoServlet`         | `listar`, `crear`, `eliminar`                 |
| Comprobantes  | `comprobantes.jsp`    | `ComprobanteServlet`     | `listar`, `crear`                             |
| Reportes      | —                     | `ReporteServlet`         | `reserva` (devuelve PDF, no JSON)             |
| Inicio        | `home.jsp`            | `HomeServlet`            | panel / navegación                            |

## Flujo principal: crear una reserva

1. El empleado inicia sesión (`login.jsp` → `AutenticacionServlet`).
2. Navega a `reservas.jsp`.
3. Selecciona cliente, habitación, fechas de entrada/salida y datos de la reserva.
4. El sistema valida la disponibilidad (regla de solape de fechas) antes de confirmar.
5. El frontend (Vue) envía la acción `crear` a `ReservaServlet`.
6. El backend calcula el monto, persiste la reserva y devuelve `ResponseService`.
7. La tabla se refresca con la nueva reserva. Opcionalmente se emite un reporte PDF.

## Fuera de alcance (hoy)

- Portal de auto-reserva para clientes finales.
- Pasarela de pagos real (existen `comprobantes` y estados de pago, pero sin integración externa).
- Reportería avanzada / dashboards analíticos.
- Multi-hotel / multi-sucursal.

## Oportunidades futuras

- Activar el rol `cliente` (código ya esbozado y comentado en `AuthService`).
- Gestión ampliada de consumo de productos por reserva y comprobantes.
- Configuración externa de credenciales y secretos (ya iniciada para el despliegue cloud).
