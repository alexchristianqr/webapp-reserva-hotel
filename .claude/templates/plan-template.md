# Plan Técnico: [NOMBRE DE LA FEATURE]

- **Spec asociada**: `specs/NNN-nombre-feature/spec.md`
- **Fecha**: [YYYY-MM-DD]

> Describe el CÓMO. Debe respetar `sdd/architecture.md`, `sdd/conventions.md`,
> `sdd/domain-model.md` y la `sdd/constitution.md`.

## 1. Enfoque general

[Resumen de la estrategia técnica en 2-4 frases.]

## 2. Verificación contra la constitución

| Artículo | ¿Cumple? | Nota |
|----------|----------|------|
| I  Capas (Servlet→Controller→Service→DB) | Sí/No | |
| II Contrato ResponseService             | Sí/No | |
| III SQL parametrizado + sesión          | Sí/No | |
| IV Nomenclatura en español              | Sí/No | |
| V  Reutilización / mínimo cambio        | Sí/No | |

> Si algún artículo es "No", justifica o replantea el enfoque.

## 3. Cambios en la base de datos

[Tablas/columnas nuevas o modificadas. Si no hay, indícalo. Actualiza `db_hotel.sql`
y `sdd/domain-model.md` si aplica.]

## 4. Componentes a crear / modificar

| Capa       | Archivo                                  | Acción           |
|------------|------------------------------------------|------------------|
| Model      | `src/java/models/Xxx.java`               | crear / modificar |
| Service    | `src/java/services/XxxService.java`      | crear / modificar |
| Controller | `src/java/controllers/XxxController.java`| crear / modificar |
| Servlet    | `src/java/servlets/XxxServlet.java`      | crear / modificar |
| Vista      | `web/xxx.jsp`                            | crear / modificar |

## 5. Contrato de la API (acciones del servlet)

| action       | Método | Parámetros                | Devuelve (`result`)       |
|--------------|--------|---------------------------|---------------------------|
| `listar`     | GET    | `buscar?`                 | `List<Xxx>`               |
| `crear`      | POST   | campos del formulario     | `Boolean`                 |
| `actualizar` | POST   | `idXxx`, campos           | `Boolean`                 |

## 6. SQL previsto

[Sentencias principales (SELECT/INSERT/UPDATE) que usará el Service, con sus joins.]

## 7. Frontend

[Estructura de la página: tabla, modal, estado Vue, llamadas fetch.]

## 8. Riesgos y consideraciones

[Transacciones, integridad referencial, rendimiento, deuda técnica que se toca.]

## 9. Estrategia de verificación

- Compilación: `mvn -q clean package`
- Tests: `mvn test` (qué se prueba, si aplica)
- Manual: pasos para validar en la app (`run.bat`).
