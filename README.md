# Endpoints de Servlets

Documentación rápida de los endpoints HTTP del proyecto **webapp-reserva-hotel**.

## Cómo funciona

- Todas las peticiones van por **GET/POST** al servlet con un parámetro `action`.
- El servlet despacha según `action` (`switch`) y devuelve **JSON** (`ResponseService<T>`).
- Salvo `login`, todas requieren **sesión válida** (si no, responden `401` + `redirectUrl` a `login.jsp`).

Formato de petición:

```
/webapp-reserva-hotel/XxxServlet?action=<accion>
```

## Endpoints

| Servlet | URL | Acciones (`action`) |
|---------|-----|---------------------|
| Autenticación | `/AutenticacionServlet` | `login`, `logout` |
| Clientes | `/ClienteServlet` | `listar`, `crear`, `actualizar`, `eliminar` |
| Empleados | `/EmpleadoServlet` | `listar`, `crear`, `actualizar`, `eliminar` |
| Habitaciones | `/HabitacionServlet` | `listar`, `crear`, `actualizar`, `eliminar`, `tipos` |
| Productos | `/ProductoServlet` | `listar`, `crear`, `actualizar`, `eliminar` |
| Reservas | `/ReservaServlet` | `listar`, `disponibilidad`, `crear`, `actualizar`, `eliminar` |
| Usuarios | `/UsuarioServlet` | `listar`, `crear`, `actualizar`, `eliminar` |
| Home | `/HomeServlet` | — (página inicial) |

## Respuesta (JSON)

Todos los endpoints responden con la misma estructura:

```json
{
  "success": true,
  "message": "...",
  "result": { },
  "code": 200,
  "redirectUrl": null
}
```
