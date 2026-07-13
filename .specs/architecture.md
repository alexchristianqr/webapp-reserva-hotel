# Arquitectura Técnica

## Stack

| Capa        | Tecnología                                          | Versión          |
|-------------|-----------------------------------------------------|------------------|
| Lenguaje    | Java                                                | 21               |
| Plataforma  | Jakarta EE: Servlet API / JSP / EL                  | 6.0 / 3.1 / 5.0  |
| Build       | Maven (empaquetado `war`, `finalName=webapp-reserva-hotel`) | —        |
| Servidor    | Apache Tomcat                                       | 10.1             |
| BD          | MySQL (JDBC puro, sin ORM)                          | 8.x              |
| Driver      | `com.mysql:mysql-connector-j`                       | 8.2.0            |
| JSON        | Gson                                                | 2.10.1           |
| Contraseñas | bcrypt (`at.favre.lib:bcrypt`)                      | 0.10.2           |
| PDF         | OpenPDF (`com.github.librepdf:openpdf`)             | 1.3.39           |
| Excel       | Apache POI (`org.apache.poi:poi-ooxml`)             | 5.2.5            |
| Frontend    | Vue 3 (build global CDN) + Bootstrap 5.3 (CDN)      | —                |
| Tests       | JUnit Jupiter                                       | 5.10.2           |

## Layout del repositorio (estándar de Maven)

```
pom.xml                       empaquetado WAR (target/webapp-reserva-hotel.war)
Dockerfile                    build multi-stage (Maven -> Tomcat ROOT.war)
buildspec.yml                 build de CodeBuild (CI/CD)
database/                     esquema y migraciones SQL
├── db_hotel.sql              esquema + datos semilla de MySQL
└── db_hotel_migracion_*.sql  migraciones
src/main/java/
├── servlets/                 capa HTTP (@WebServlet)
├── controllers/              orquestación -> ResponseService
├── services/                 lógica de negocio + SQL
├── models/                   POJOs de dominio (Cliente/Empleado extienden Persona)
└── core/
    ├── servlets/             BaseServlet
    ├── services/             MysqlDBService, ResponseService
    ├── utils/                lógica pura testeable (PasswordUtil, ReservaReglas)
    └── (BaseController, BaseService)
src/main/resources/           recursos del classpath (META-INF/context.xml)
src/main/webapp/              páginas JSP (una por entidad) + includes/, imágenes
src/main/test/java/           tests JUnit (¡NO src/test/java!)
src/test/jmeter/              planes de prueba de carga (JMeter)
src/test/security/zap/        planes de prueba de seguridad (OWASP ZAP)
.aws/iac/stacks/              infraestructura como código (CloudFormation)
scripts/                      despliegue (deploy.sh)
```

> Las fuentes Java van en `src/main/java` y los tests JUnit en `src/main/test/java`
> (configurado en `pom.xml`).

## Diagrama de flujo de una petición

```
┌────────────────────────────────────────────────────────────────────┐
│ Navegador: src/main/webapp/xxx.jsp  (Vue 3 + Bootstrap)             │
│   fetch('/XxxServlet?action=listar')                                │
└───────────────────────────────┬──────────────────────────────────────┘
                                 │  HTTP GET/POST (params; action)
                                 ▼
┌────────────────────────────────────────────────────────────────────┐
│ servlets/XxxServlet  extends BaseServlet                            │
│   • BaseServlet exige sesión válida (salvo action=login) → 401      │
│   • processRequest(): switch(action) -> método privado por acción   │
│   • lee request.getParameter(...), construye el model               │
│   • new Gson().toJson(responseService) -> response.getWriter()      │
└───────────────────────────────┬──────────────────────────────────────┘
                                 ▼
┌────────────────────────────────────────────────────────────────────┐
│ controllers/XxxController  extends BaseController<Model, Service>   │
│   • instancia el Service en su constructor                          │
│   • llama al Service y envuelve el resultado en ResponseService<T>  │
└───────────────────────────────┬──────────────────────────────────────┘
                                 ▼
┌────────────────────────────────────────────────────────────────────┐
│ services/XxxService  extends BaseService                            │
│   • db = new MysqlDBService() en el constructor                     │
│   • define querySQL_1..4 y Object[] de parámetros                   │
│   • usa db.queryConsultar / queryInsertar / queryActualizar / ...   │
│   • mapea ResultSet -> modelos ; finally -> db.cerrarConsulta()     │
└───────────────────────────────┬──────────────────────────────────────┘
                                 ▼
┌────────────────────────────────────────────────────────────────────┐
│ core/services/MysqlDBService  (JDBC)                                │
│   • conexión configurable por variables de entorno DB_* (ver abajo) │
│   • PreparedStatement con parámetros (bindParameters)               │
│   • soporta commit/rollback/setAutoCommit para transacciones        │
└────────────────────────────────────────────────────────────────────┘
```

La respuesta vuelve serializada como JSON (`ResponseService<T>` → Gson).
**Excepción:** `ReporteServlet` mezcla ambos formatos según la `action`: `dashboard`
devuelve JSON (KPIs + series para gráficos), mientras que `reserva` escribe binario
`application/pdf` (OpenPDF) y `excel` escribe binario `.xlsx` (Apache POI) directamente.

## Configuración de conexión a la base de datos

`MysqlDBService` lee la conexión de variables de entorno, con *fallback* a valores
locales para desarrollo:

| Variable     | Default local | Origen en producción (AWS)            |
|--------------|---------------|---------------------------------------|
| `DB_HOST`    | `127.0.0.1`   | Endpoint de RDS                        |
| `DB_PORT`    | `3306`        | `3306`                                 |
| `DB_NAME`    | `db_hotel`    | `db_hotel`                            |
| `DB_USER`    | `root`        | Secrets Manager (clave `username`)     |
| `DB_PASSWORD`| (vacío)       | Secrets Manager (clave `password`)     |

## Clases base (infraestructura)

### `core.servlets.BaseServlet` (abstract, extends HttpServlet)
- `doGet`/`doPost` → verificación de sesión → `processRequest()` (lo implementa el hijo).
- Si `action != "login"` y no hay `usuario` en sesión → `401` + JSON con `redirectUrl`
  a `login.jsp`. El usuario autenticado se guarda en `HttpSession` bajo la clave `"usuario"`.
- Helpers: `getUsuarioAutenticado`, `defaultError(action)`, `parseIntSafe`,
  `parseDoubleSafe`, `sendJsonResponse`.

### `core.BaseController<T, U>` (abstract)
- Campos: `List<T> lista`, `U service`, `querySQL_1..3`. Utilitario `idAutoincrementado()`.

### `core.BaseService` (abstract)
- Campos: `MysqlDBService db`, `querySQL_1..4`.

### `core.services.MysqlDBService` (extends BaseService)
- Métodos: `queryConsultar(sql[,params])`, `queryInsertar` (devuelve id generado),
  `queryActualizar`, `queryEliminar`, `cerrarConsulta`, `desconectar`,
  `commit`/`rollback`/`setAutoCommit`.

### `core.services.ResponseService<T>`
- Campos: `success`, `message`, `result` (`T`), `code`, `redirectUrl`.

### `core.utils` (lógica pura testeable)
- `PasswordUtil` (bcrypt: `hashear`/`verificar`) y `ReservaReglas` (cálculo de noches y
  solape de fechas). El SQL de `disponibilidad` implementa la misma regla de solape que
  `ReservaReglas.haySolape`.

## Frontend (JSP + Vue)

- Cada página incluye `includes/header.jsp` (CDNs de Bootstrap + Vue + bootstrap-icons)
  y `includes/footer.jsp`.
- Monta una app Vue 3 con `createApp({ setup() {...} }).mount('#app')`.
- Comunicación: `fetch` al servlet correspondiente; en `crear/actualizar` se usa
  `FormData` con `action` incluido y `method: 'POST'`.
- Manejo de `401`: redirige a `login.jsp`.

## Persistencia y transacciones

- Sin pool de conexiones: cada `*Service` crea su propia `MysqlDBService`.
- Operaciones multi-tabla (p. ej. crear cliente = insertar en `personas` + `clientes`)
  pueden envolverse con `setAutoCommit`/`commit`/`rollback`.

## Seguridad

- **Contraseñas con bcrypt**: nunca en texto plano. `PasswordUtil.hashear()` al
  crear/actualizar y `PasswordUtil.verificar()` al validar. Una cuenta heredada en
  texto plano se re-hashea con bcrypt en su primer inicio de sesión.
- **SQL siempre parametrizado** (`PreparedStatement`): nunca se concatena input de usuario.

## Deuda técnica conocida

- No hay pool de conexiones JDBC (una conexión por servicio).
- Manejo de errores mayormente vía `RuntimeException`; sin logging estructurado.
- Cobertura de tests acotada: pruebas unitarias de lógica pura (`ReservaReglasTest`);
  las capas servlet/service/controller aún sin tests.
- En el ALB solo hay HTTP (:80); falta HTTPS/ACM (ver `deployment-aws.md`).
