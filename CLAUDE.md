# CLAUDE.md

Guía para Claude Code (y cualquier agente de IA) al trabajar en este repositorio.

> Para el flujo de trabajo formal de **Spec-Driven Development (SDD)** y las
> especificaciones detalladas, lee `.claude/README.md` y la carpeta `.claude/sdd/`.
> Este archivo es el resumen operativo de alto nivel.

## Qué es este proyecto

**webapp-reserva-hotel** — Sistema web de reservas para el **Hotel Tierra Colorada**.
Permite a empleados autenticados gestionar clientes, habitaciones, productos,
empleados, usuarios y reservas mediante un panel web.

## Stack técnico

| Capa        | Tecnología                                                        |
|-------------|-------------------------------------------------------------------|
| Lenguaje    | Java 21 (`maven.compiler.release=21`)                             |
| Plataforma  | Jakarta EE — Servlets 6.0, JSP 3.1, EL 5.0                        |
| Build       | Maven, empaquetado **WAR** (`finalName=webapp-reserva-hotel`)     |
| Servidor    | Apache Tomcat 10.1                                                 |
| BD          | MySQL 8 vía **JDBC puro** (sin ORM) — driver `mysql-connector-j`  |
| JSON        | Gson 2.10.1                                                        |
| Frontend    | JSP + **Vue 3** (build global por CDN) + **Bootstrap 5.3** (CDN)  |
| Tests       | JUnit 5 (Jupiter)                                                  |

> ⚠️ El código fuente vive en `src/java` (NO en el `src/main/java` estándar de Maven).
> Tests en `src/test/java`. Recursos web en `web/`. Esto está configurado en `pom.xml`.

## Comandos esenciales

```bash
# Compilar y empaquetar el WAR
mvn -q clean package

# Ejecutar tests
mvn test

# Build + desplegar en Tomcat + arrancar (Windows). Ajusta rutas dentro del .bat.
run.bat
```

- App: `http://localhost:8080/webapp-reserva-hotel/login.jsp`
- Login de ejemplo: `alex.quispe@gmail.com` / `12345678`
- Requiere MySQL corriendo con la BD `db_hotel` (ver `db_hotel.sql`).

## Arquitectura en capas

Flujo de una petición:

```
Navegador (JSP + Vue, fetch)
   │  GET/POST  ?action=<accion>
   ▼
servlets/XxxServlet  (extends BaseServlet)   ← parsea params, despacha por "action"
   ▼
controllers/XxxController (extends BaseController<T,U>) ← arma ResponseService<T>
   ▼
services/XxxService (extends BaseService)    ← lógica + SQL crudo
   ▼
core/services/MysqlDBService                 ← JDBC (PreparedStatement)
   ▼
MySQL (db_hotel)
```

La respuesta vuelve serializada como JSON (`ResponseService<T>` → Gson) al navegador.

| Carpeta                  | Responsabilidad                                                       |
|--------------------------|-----------------------------------------------------------------------|
| `src/java/servlets/`     | Capa HTTP. `@WebServlet`, lee `request.getParameter`, despacha `action`. |
| `src/java/controllers/`  | Orquestación. Envuelve resultados en `ResponseService<T>`.            |
| `src/java/services/`     | Lógica de negocio + SQL crudo contra `MysqlDBService`.               |
| `src/java/models/`       | POJOs (`Cliente`/`Empleado` extienden `Persona`).                    |
| `src/java/core/`         | Infraestructura: `MysqlDBService`, `ResponseService`, `BaseServlet`, utils. |
| `web/`                   | Páginas JSP (una por entidad) con app Vue embebida.                  |

## Convenciones clave (NO romper)

1. **Idioma español** en nombres de dominio: `listar`, `crear`, `actualizar`,
   `eliminar`, `Cliente`, `Habitacion`, `Reserva`, etc. Mantén la coherencia.
2. **Despacho por `action`**: cada servlet usa `switch (action)` con casos
   `listar` / `crear` / `actualizar` / `eliminar` y `defaultError(action)` por defecto.
3. **Respuestas**: SIEMPRE devuelve `ResponseService<T>` con `success`, `message`,
   `result` (y `code`/`redirectUrl` cuando aplique). Serializa con `new Gson().toJson(...)`.
4. **SQL parametrizado**: usa `PreparedStatement` vía los métodos de `MysqlDBService`
   (`queryConsultar`, `queryInsertar`, `queryActualizar`, `queryEliminar`) pasando
   `Object[]` de parámetros. **Nunca concatenes input de usuario en el SQL.**
   Los servicios guardan sus sentencias en los campos `querySQL_1..4`.
5. **Cierre de recursos**: tras consultar, llama `db.cerrarConsulta()` (normalmente
   en `finally`).
6. **Autenticación**: `BaseServlet.verificarSesion` exige sesión válida salvo para
   `action=login`; si no hay sesión responde `401` + JSON con `redirectUrl` a `login.jsp`.
   El usuario autenticado se guarda en `HttpSession` bajo la clave `"usuario"`.
7. **Frontend**: cada `.jsp` incluye `includes/header.jsp` + `includes/footer.jsp`,
   monta una app Vue 3 con `createApp({ setup() {...} }).mount('#app')`, usa `fetch`
   contra el servlet correspondiente y maneja `401` redirigiendo a login.

## Patrón para añadir una nueva entidad (CRUD)

Sigue el patrón existente de `Cliente` end-to-end:

1. **Modelo** `models/Xxx.java` — POJO con getters/setters (extiende `Persona` si es una persona).
2. **Service** `services/XxxService.java extends BaseService` — `new MysqlDBService()` en
   el constructor; métodos `listarXxx` / `crearXxx` / `actualizarXxx` / `eliminarXxx` con SQL.
3. **Controller** `controllers/XxxController.java extends BaseController<Xxx, XxxService>` —
   instancia el service y envuelve cada resultado en `ResponseService`.
4. **Servlet** `servlets/XxxServlet.java extends BaseServlet` — `@WebServlet(urlPatterns={"/XxxServlet"})`,
   despacho por `action`, serializa con Gson.
5. **Vista** `web/xxx.jsp` — copia la estructura de `clientes.jsp` (tabla + modal + app Vue + fetch).
6. **BD** — si necesitas tabla nueva, añádela en `db_hotel.sql`.

## Deuda técnica / cosas a tener en cuenta

- Credenciales de BD **hardcodeadas** en `MysqlDBService` (`root` / sin contraseña,
  `127.0.0.1:3306/db_hotel`). No hay capa de configuración externa.
- Contraseñas de usuario se guardan/comparan **en texto plano** (`usuarios.pwd`).
- No hay pool de conexiones; cada `*Service` abre su propia conexión.
- Los tests (`UtilTest`) están comentados; no hay cobertura real todavía.
- Manejo de errores mayormente vía `RuntimeException`/`Error`; sin logging estructurado.

> Al proponer cambios respeta el estilo actual salvo que la tarea pida explícitamente
> refactorizar. Si tocas deuda técnica conocida, menciónalo en la respuesta.
