# Arquitectura Técnica

## Stack

| Capa       | Tecnología                                          | Versión   |
|------------|-----------------------------------------------------|-----------|
| Lenguaje   | Java                                                | 21        |
| Plataforma | Jakarta EE: Servlet API / JSP / EL                  | 6.0 / 3.1 / 5.0 |
| Build      | Maven (empaquetado `war`)                           | —         |
| Servidor   | Apache Tomcat                                       | 10.1      |
| BD         | MySQL (JDBC puro, sin ORM)                          | 8.x       |
| Driver     | `com.mysql:mysql-connector-j`                       | 8.2.0     |
| JSON       | Gson                                                | 2.10.1    |
| Frontend   | Vue 3 (build global CDN) + Bootstrap 5.3 (CDN)      | —         |
| Tests      | JUnit Jupiter                                       | 5.10.2    |

## Layout del repositorio (no estándar de Maven)

```
pom.xml                       sourceDirectory = src/java ; testSourceDirectory = src/test/java
run.bat                       build + deploy a Tomcat + arranque (Windows)
db_hotel.sql                  esquema + datos semilla de MySQL
src/java/
├── servlets/                 capa HTTP (@WebServlet)
├── controllers/              orquestación → ResponseService
├── services/                 lógica de negocio + SQL
├── models/                   POJOs de dominio
└── core/
    ├── servlets/             BaseServlet
    ├── services/             MysqlDBService, ResponseService
    └── utils/                Util, Validation, HtmlGenerator, ...
src/test/java/                tests JUnit
web/
├── *.jsp                     una página por entidad (Vue embebido)
├── includes/                 header.jsp (CDNs), footer.jsp
├── imagenes/ , META-INF/ , WEB-INF/
```

> ⚠️ El `<sourceDirectory>` apunta a `src/java`, **no** a `src/main/java`. Cualquier
> archivo nuevo debe respetar esta ruta o no se compilará.

## Diagrama de flujo de una petición

```
┌────────────────────────────────────────────────────────────────────┐
│ Navegador: web/xxx.jsp  (Vue 3 + Bootstrap)                          │
│   fetch('/webapp-reserva-hotel/XxxServlet?action=listar')            │
└───────────────────────────────┬──────────────────────────────────────┘
                                 │  HTTP GET/POST (params; action)
                                 ▼
┌────────────────────────────────────────────────────────────────────┐
│ servlets/XxxServlet  extends BaseServlet                            │
│   • BaseServlet.verificarSesion() → 401 + redirect si no hay sesión │
│   • processRequest(): switch(action) → método privado por acción    │
│   • lee request.getParameter(...), construye el model                │
│   • new Gson().toJson(responseService) → response.getWriter()        │
└───────────────────────────────┬──────────────────────────────────────┘
                                 ▼
┌────────────────────────────────────────────────────────────────────┐
│ controllers/XxxController  extends BaseController<Model, Service>   │
│   • instancia el Service en su constructor                           │
│   • llama al Service y envuelve el resultado en ResponseService<T>   │
└───────────────────────────────┬──────────────────────────────────────┘
                                 ▼
┌────────────────────────────────────────────────────────────────────┐
│ services/XxxService  extends BaseService                            │
│   • db = new MysqlDBService() en el constructor                      │
│   • define querySQL_1..4 y Object[] de parámetros                    │
│   • usa db.queryConsultar / queryInsertar / queryActualizar / ...    │
│   • mapea ResultSet → modelos ; finally → db.cerrarConsulta()        │
└───────────────────────────────┬──────────────────────────────────────┘
                                 ▼
┌────────────────────────────────────────────────────────────────────┐
│ core/services/MysqlDBService  (JDBC)                                 │
│   • conexión a jdbc:mysql://127.0.0.1:3306/db_hotel (root, sin pwd)  │
│   • PreparedStatement con bindParameters(Object[])                   │
│   • soporta commit/rollback/setAutoCommit para transacciones         │
└────────────────────────────────────────────────────────────────────┘
```

## Clases base (infraestructura)

### `core.servlets.BaseServlet` (abstract, extends HttpServlet)
- `doGet`/`doPost` → `verificarSesion()` → `processRequest()` (lo implementa el hijo).
- `verificarSesion`: si `action != "login"` y no hay `usuario` en sesión → `401` +
  JSON con `redirectUrl` a `login.jsp`.
- Helpers: `getUsuarioAutenticado`, `defaultError(action)`, `parseIntSafe`,
  `parseDoubleSafe`, `sendJsonResponse`.

### `controllers.BaseController<T, U>` (abstract)
- Campos: `List<T> lista`, `U service`, `querySQL_1..3`.
- `idAutoincrementado()` utilitario.

### `services.BaseService` (abstract)
- Campos: `MysqlDBService db`, `querySQL_1..4`.

### `core.services.MysqlDBService` (extends BaseService)
- Métodos: `queryConsultar(sql[,params])`, `queryInsertar` (devuelve id generado),
  `queryActualizar`, `queryEliminar`, `cerrarConsulta`, `desconectar`,
  `commit`/`rollback`/`setAutoCommit`.

### `core.services.ResponseService<T>`
- Campos: `success`, `message`, `result` (`T`), `code`, `redirectUrl`.

## Frontend (JSP + Vue)

- Cada página incluye `includes/header.jsp` (CDNs de Bootstrap + Vue + bootstrap-icons)
  y `includes/footer.jsp`.
- El `<body id="app">` actúa como punto de montaje de Vue.
- Patrón: `createApp({ setup() { const state = reactive({...}); ... return {...}; } }).mount('#app')`.
- Comunicación: `fetch` a `/webapp-reserva-hotel/XxxServlet`; en `crear/actualizar`
  se usa `FormData` con `action` incluido y `method: 'POST'`.
- Manejo de `401`: `window.location.href = '/webapp-reserva-hotel/login.jsp'`.

## Persistencia y transacciones

- Sin pool de conexiones: cada `*Service` crea su propia `MysqlDBService`.
- Operaciones multi-tabla (p. ej. crear cliente = insertar en `personas` + `clientes`)
  se hacen con varios `queryInsertar` consecutivos; `MysqlDBService` ofrece
  `setAutoCommit`/`commit`/`rollback` para envolverlas en transacción cuando se requiera.

## Deuda técnica conocida

Ver lista detallada en `CLAUDE.md` → "Deuda técnica". Resumen: credenciales
hardcodeadas, contraseñas en texto plano, sin pool de conexiones, tests comentados,
errores vía `RuntimeException`.
