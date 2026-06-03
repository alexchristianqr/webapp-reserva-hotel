# Tareas: [NOMBRE DE LA FEATURE]

- **Plan asociado**: `specs/NNN-nombre-feature/plan.md`
- **Fecha**: [YYYY-MM-DD]

> Tareas pequeñas, ordenadas por dependencia y verificables de forma independiente.
> `[P]` = puede ejecutarse en paralelo con otras `[P]`. Marca `[x]` al completar.

## Convención

- Sigue el orden de capas de dentro hacia afuera: **BD → Model → Service → Controller → Servlet → Vista**.
- Cada tarea indica el archivo afectado y un criterio de "hecho".

## Lista de tareas

- [ ] **T01** — [BD] Crear/ajustar tabla(s) en `db_hotel.sql`.
      *Hecho cuando*: el script corre sin error y refleja `domain-model.md`.
- [ ] **T02** — [Model] Crear `models/Xxx.java` con campos/getters/setters.
      *Hecho cuando*: compila y mapea las columnas de la tabla.
- [ ] **T03** — [Service] Implementar `services/XxxService.java` (`listar/crear/actualizar`).
      *Hecho cuando*: SQL parametrizado, cierra recursos, compila.
- [ ] **T04** — [Controller] Implementar `controllers/XxxController.java`.
      *Hecho cuando*: cada método devuelve `ResponseService<T>` con success/message.
- [ ] **T05** — [Servlet] Implementar `servlets/XxxServlet.java` con despacho por `action`.
      *Hecho cuando*: `@WebServlet` registrado y serializa JSON con Gson.
- [ ] **T06** [P] — [Vista] Crear `web/xxx.jsp` (tabla + modal + app Vue + fetch).
      *Hecho cuando*: lista, crea y edita contra el servlet; maneja 401.
- [ ] **T07** [P] — [Test] Añadir/ajustar pruebas en `src/test/java/...` si aplica.
- [ ] **T08** — [Verificación] `mvn -q clean package` y prueba manual con `run.bat`.
      *Hecho cuando*: compila, la feature funciona end-to-end.

## Notas de implementación

[Decisiones tomadas durante la ejecución, desviaciones respecto al plan, pendientes.]
