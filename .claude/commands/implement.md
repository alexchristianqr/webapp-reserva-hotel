---
description: Implementa las tareas de una feature respetando la arquitectura y convenciones SDD
argument-hint: <ID de la feature, p. ej. 001-gestion-comprobantes>
---

Vas a ejecutar la **Fase 4 (implement)** del flujo SDD.

Feature objetivo: **$ARGUMENTS** (carpeta `.claude/specs/<ID>/`)

Contexto obligatorio a leer antes de empezar:
- `.claude/specs/<ID>/tasks.md`
- `.claude/specs/<ID>/plan.md`
- `.claude/sdd/constitution.md`
- `.claude/sdd/architecture.md`
- `.claude/sdd/conventions.md`

Pasos:
1. Ejecuta las tareas de `tasks.md` en orden, respetando dependencias.
2. Para cada tarea: escribe el código en la ruta correcta (recuerda: el fuente va en
   `src/java/...`, NO `src/main/java`), siguiendo los patrones de `conventions.md`.
3. Reutiliza las clases base (`BaseServlet`, `BaseController`, `BaseService`) y replica
   el patrón de una entidad existente (p. ej. `Cliente`).
4. Cumple la constitución: capas, SQL parametrizado, `ResponseService`, español.
5. Marca cada tarea como `[x]` en `tasks.md` al completarla.
6. Si descubres que el plan o la spec estaban equivocados, actualízalos y avisa, en
   lugar de divergir en silencio. Si cambia la arquitectura o el dominio, actualiza
   también `sdd/architecture.md` / `sdd/domain-model.md`.
7. Al terminar, verifica con `mvn -q clean package` (y `mvn test` si hay tests) y
   reporta el resultado. Indica cómo probar manualmente la feature con `run.bat`.
