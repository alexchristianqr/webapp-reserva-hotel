# webapp-reserva-hotel

## Despliegue rápido (AWS)

Script: `scripts/deploy.sh`. Antes de usarlo: copia `scripts/deploy.env.example` a `scripts/deploy.env` y rellénalo. Requiere **AWS CLI v2** configurada y **Docker** en ejecución (para `up` e `image`).

| Comando | Qué hace |
|---------|----------|
| `sh scripts/deploy.sh up` | Despliega toda la infra: ECR → imagen → net → RDS → seed → ECS → app → CI/CD. |
| `sh scripts/deploy.sh image` | Reconstruye y publica solo la imagen Docker en ECR. |
| `sh scripts/deploy.sh seed` | Carga `database/*.sql` en la RDS (schema + datos semilla; abre/cierra acceso solo). |
| `sh scripts/deploy.sh pause` | Pausa costos: elimina app+net+db (cobran 24/7); conserva ecr y cicd. |
| `sh scripts/deploy.sh resume` | Reanuda tras `pause`: recrea net → db → seed → app (usa la imagen ya publicada). |
| `sh scripts/deploy.sh outputs` | Muestra los Outputs de los 5 stacks. |
| `sh scripts/deploy.sh down` | Elimina **TODOS** los stacks (incluye repo ECR y bucket de artefactos). |
| `sh scripts/deploy.sh db-creds` | Imprime host/puerto/usuario/clave de la BD. |
| `sh scripts/deploy.sh db-open` / `db-close` | Abre/cierra acceso temporal a la RDS desde tu IP (Workbench, DBeaver...). |

> Ayuda completa: `sh scripts/deploy.sh -h`

---

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
