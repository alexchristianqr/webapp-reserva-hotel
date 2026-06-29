# CLAUDE.md

Guía para Claude Code (y cualquier agente de IA) al trabajar en este repositorio.

> Para el flujo de trabajo formal de **Spec-Driven Development (SDD)** y las
> especificaciones detalladas, lee `.claude/README.md` y la carpeta `.claude/sdd/`.
> Este archivo es el resumen operativo de alto nivel.

## Qué es este proyecto

**webapp-reserva-hotel** — Sistema web de reservas para el **Hotel Tierra Colorada**.
Permite a empleados autenticados gestionar clientes, habitaciones, productos,
empleados, usuarios, reservas, consumos y comprobantes mediante un panel web,
y emitir reportes PDF de reservas.

## Stack técnico

| Capa        | Tecnología                                                        |
|-------------|-------------------------------------------------------------------|
| Lenguaje    | Java 21 (`maven.compiler.release=21`)                             |
| Plataforma  | Jakarta EE — Servlets 6.0, JSP 3.1, EL 5.0                        |
| Build       | Maven, empaquetado **WAR** (`finalName=webapp-reserva-hotel`)     |
| Servidor    | Apache Tomcat 10.1                                                 |
| BD          | MySQL 8 vía **JDBC puro** (sin ORM) — driver `mysql-connector-j`  |
| JSON        | Gson 2.10.1                                                        |
| Contraseñas | **bcrypt** (`at.favre.lib:bcrypt`)                                |
| PDF         | **OpenPDF** (`com.github.librepdf:openpdf`) para reportes        |
| Frontend    | JSP + **Vue 3** (build global por CDN) + **Bootstrap 5.3** (CDN)  |
| Tests       | JUnit 5 (Jupiter); perf con **JMeter**; seguridad con **OWASP ZAP** |

> ⚠️ Layout Maven **estándar** (migrado desde el layout antiguo `src/java`/`web`):
> - Código fuente: `src/main/java`
> - Tests JUnit: `src/main/test/java` (¡ojo, NO `src/test/java`!)
> - Recursos web (JSP/HTML/imágenes): `src/main/webapp`
> - Recursos del classpath: `src/main/resources` (incluye `META-INF/context.xml`)
> - `src/test/jmeter` y `src/test/security/zap` contienen planes de prueba (no son
>   fuentes Maven). Todo esto está configurado en `pom.xml`.

## Comandos esenciales

```bash
# Compilar y empaquetar el WAR (queda en target/webapp-reserva-hotel.war)
mvn -q clean package

# Ejecutar todos los tests
mvn test

# Ejecutar una sola clase / un solo método de test
mvn test -Dtest=ReservaReglasTest
mvn test -Dtest=ReservaReglasTest#calculaNochesDeRangoValido
```

- **No hay script de arranque** (el antiguo `run.bat` ya no existe). Despliega el WAR
  generado en `target/` sobre **Tomcat 10.1** manualmente o desde el IDE.
- App: `http://localhost:8080/webapp-reserva-hotel/login.jsp`
- Login de ejemplo: `alex.quispe@gmail.com` / `12345678`
- Requiere MySQL corriendo con la BD `db_hotel`. Los scripts están en **`database/`**:
  `db_hotel.sql` (esquema/seed) + migraciones (`db_hotel_migracion_*.sql`).

## Arquitectura en capas

Flujo de una petición:

```
Navegador (JSP + Vue, fetch)
   │  GET/POST  ?action=<accion>
   ▼
servlets/XxxServlet  (extends core.servlets.BaseServlet)  ← parsea params, despacha por "action"
   ▼
controllers/XxxController (extends BaseController<T,U>)    ← arma ResponseService<T>
   ▼
services/XxxService (extends BaseService)                 ← lógica + SQL crudo
   ▼
core/services/MysqlDBService                              ← JDBC (PreparedStatement)
   ▼
MySQL (db_hotel)
```

La respuesta vuelve serializada como JSON (`ResponseService<T>` → Gson) al navegador.
**Excepción:** `ReporteServlet` escribe binario `application/pdf` directamente (no JSON).

| Carpeta                       | Responsabilidad                                                       |
|-------------------------------|-----------------------------------------------------------------------|
| `src/main/java/servlets/`     | Capa HTTP. `@WebServlet`, lee `request.getParameter`, despacha `action`. |
| `src/main/java/controllers/`  | Orquestación. Envuelve resultados en `ResponseService<T>`.            |
| `src/main/java/services/`     | Lógica de negocio + SQL crudo contra `MysqlDBService`.               |
| `src/main/java/models/`       | POJOs (`Cliente`/`Empleado` extienden `Persona`).                    |
| `src/main/java/core/`         | Infraestructura: `BaseController`, `BaseService`, `services/` (`MysqlDBService`, `ResponseService`), `servlets/BaseServlet`, `utils/`. |
| `src/main/java/core/utils/`   | Lógica PURA testeable: `PasswordUtil` (bcrypt), `ReservaReglas` (fechas/solape). |
| `src/main/webapp/`            | Páginas JSP (una por entidad) con app Vue embebida + `includes/`.    |
| `database/`                   | Esquema y migraciones SQL.                                            |

### Entidades y endpoints (servlets)

| Servlet                 | URL                      | Acciones (`action`)                              |
|-------------------------|--------------------------|--------------------------------------------------|
| `AutenticacionServlet`  | `/AutenticacionServlet`  | `login`, `logout`                                |
| `ClienteServlet`        | `/ClienteServlet`        | `listar`, `crear`, `actualizar`, `eliminar`      |
| `EmpleadoServlet`       | `/EmpleadoServlet`       | `listar`, `crear`, `actualizar`, `eliminar`      |
| `HabitacionServlet`     | `/HabitacionServlet`     | `listar`, `crear`, `actualizar`, `eliminar`, `tipos` |
| `ProductoServlet`       | `/ProductoServlet`       | `listar`, `crear`, `actualizar`, `eliminar`      |
| `UsuarioServlet`        | `/UsuarioServlet`        | `listar`, `crear`, `actualizar`, `eliminar`      |
| `ReservaServlet`        | `/ReservaServlet`        | `listar`, `disponibilidad`, `crear`, `actualizar`, `eliminar` |
| `ConsumoServlet`        | `/ConsumoServlet`        | `listar`, `crear`, `eliminar`                    |
| `ComprobanteServlet`    | `/ComprobanteServlet`    | `listar`, `crear`                                |
| `ReporteServlet`        | `/ReporteServlet`        | `reserva` (devuelve PDF, no JSON)                |
| `HomeServlet`           | `/HomeServlet`           | — (página inicial)                               |

## Convenciones clave (NO romper)

1. **Idioma español** en nombres de dominio: `listar`, `crear`, `actualizar`,
   `eliminar`, `Cliente`, `Habitacion`, `Reserva`, etc. Mantén la coherencia.
2. **Despacho por `action`**: cada servlet usa `switch (action) { case "..." -> ... }`
   (switch con flechas) con casos `listar`/`crear`/`actualizar`/`eliminar` y
   `defaultError(action)` por defecto.
3. **Respuestas**: SIEMPRE devuelve `ResponseService<T>` con `success`, `message`,
   `result` (y `code`/`redirectUrl` cuando aplique). Serializa con `new Gson().toJson(...)`
   (o `sendJsonResponse(...)` de `BaseServlet`). Único caso aparte: `ReporteServlet` (PDF).
4. **SQL parametrizado**: usa `PreparedStatement` vía los métodos de `MysqlDBService`
   (`queryConsultar`, `queryInsertar`, `queryActualizar`, `queryEliminar`) pasando
   `Object[]` de parámetros. **Nunca concatenes input de usuario en el SQL.**
   Los servicios guardan sus sentencias en los campos `querySQL_1..4`.
5. **Cierre de recursos**: tras consultar, llama `db.cerrarConsulta()` (normalmente
   en `finally`). `MysqlDBService` soporta transacciones manuales
   (`setAutoCommit`/`commit`/`rollback`) si una operación toca varias tablas.
6. **Autenticación**: `BaseServlet` (en `core.servlets`) exige sesión válida salvo
   para `action=login`; si no hay sesión responde `401` + JSON con `redirectUrl` a
   `login.jsp`. El usuario autenticado se guarda en `HttpSession` bajo la clave `"usuario"`.
7. **Contraseñas**: NUNCA en texto plano. Usa `core.utils.PasswordUtil.hashear()` al
   crear/actualizar credenciales y `PasswordUtil.verificar()` al validar (`AuthService.login`).
   Hay migración transparente: una cuenta heredada en texto plano se re-hashea con bcrypt
   en su primer login.
8. **Lógica de negocio pura** (validable sin BD): extráela a `core.utils` con su test en
   `src/main/test/java`, como `ReservaReglas` (fechas y solape de reservas). El SQL de
   `disponibilidad` debe implementar la misma regla de solape que `ReservaReglas.haySolape`.
9. **Frontend**: cada `.jsp` incluye `includes/header.jsp` + `includes/footer.jsp`,
   monta una app Vue 3 con `createApp({ setup() {...} }).mount('#app')`, usa `fetch`
   contra el servlet correspondiente y maneja `401` redirigiendo a login.

## Patrón para añadir una nueva entidad (CRUD)

Sigue el patrón existente de `Cliente` end-to-end:

1. **Modelo** `models/Xxx.java` — POJO con getters/setters (extiende `Persona` si es una persona).
2. **Service** `services/XxxService.java extends BaseService` — `db = new MysqlDBService()` en
   el constructor; métodos `listarXxx`/`crearXxx`/`actualizarXxx`/`eliminarXxx` con SQL.
3. **Controller** `controllers/XxxController.java extends BaseController<Xxx, XxxService>` —
   instancia el service y envuelve cada resultado en `ResponseService`.
4. **Servlet** `servlets/XxxServlet.java extends BaseServlet` — `@WebServlet(urlPatterns={"/XxxServlet"})`,
   despacho por `action`, serializa con Gson.
5. **Vista** `src/main/webapp/xxx.jsp` — copia la estructura de `clientes.jsp` (tabla + modal + app Vue + fetch).
6. **BD** — si necesitas tabla nueva, añádela en `database/db_hotel.sql` (o una migración
   `database/db_hotel_migracion_*.sql`) y actualiza `.claude/sdd/domain-model.md`.

## Deuda técnica / cosas a tener en cuenta

- Credenciales de BD **hardcodeadas** en `MysqlDBService` (`root` / sin contraseña,
  `127.0.0.1:3306/db_hotel`). No hay capa de configuración externa (`context.xml` está vacío).
- No hay **pool de conexiones**; cada `*Service` abre su propia conexión a MySQL.
- Manejo de errores mayormente vía `RuntimeException`/`Error`; sin logging estructurado
  (se usa `System.out.println`, incluido el volcado del SQL ejecutado).
- Cobertura de tests aún acotada: solo hay pruebas unitarias de lógica pura
  (`ReservaReglasTest`); las capas servlet/service/controller no tienen tests.
- En `pom.xml` se declaran `jmeter.plugin.version` y `exec.plugin.version` como
  propiedades pero ningún plugin las usa todavía (los `.jmx`/ZAP se ejecutan aparte).

> Al proponer cambios respeta el estilo actual salvo que la tarea pida explícitamente
> refactorizar. Si tocas deuda técnica conocida, menciónalo en la respuesta.
