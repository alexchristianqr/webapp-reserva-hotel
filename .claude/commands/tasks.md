---
description: Descompone el plan de una feature en tareas verificables, según SDD
argument-hint: <ID de la feature, p. ej. 001-gestion-comprobantes>
---

Vas a ejecutar la **Fase 3 (tasks)** del flujo SDD.

Feature objetivo: **$ARGUMENTS** (carpeta `.claude/specs/<ID>/`)

Contexto obligatorio a leer antes de empezar:
- `.claude/specs/<ID>/plan.md`
- `.claude/sdd/workflow.md`
- `.claude/templates/tasks-template.md`

Pasos:
1. Genera `.claude/specs/<ID>/tasks.md` usando `templates/tasks-template.md`.
2. Ordena las tareas por dependencia, de dentro hacia afuera:
   **BD → Model → Service → Controller → Servlet → Vista → Verificación**.
3. Cada tarea debe ser pequeña, con archivo afectado y criterio de "hecho".
4. Marca con `[P]` las tareas que pueden ejecutarse en paralelo (sin dependencia mutua).
5. Incluye una tarea final de verificación: `mvn -q clean package` y prueba manual.
6. No implementes todavía: solo produce la lista de tareas.
