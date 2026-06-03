---
description: Genera el plan técnico (CÓMO) de una feature a partir de su spec, según SDD
argument-hint: <ID de la feature, p. ej. 001-gestion-comprobantes>
---

Vas a ejecutar la **Fase 2 (plan)** del flujo SDD.

Feature objetivo: **$ARGUMENTS** (carpeta `.claude/specs/<ID>/`)

Contexto obligatorio a leer antes de empezar:
- `.claude/specs/<ID>/spec.md` (la especificación de esta feature)
- `.claude/sdd/constitution.md`
- `.claude/sdd/architecture.md`
- `.claude/sdd/conventions.md`
- `.claude/sdd/domain-model.md`
- `.claude/templates/plan-template.md`

Pasos:
1. Si el `spec.md` tiene `[NECESITA ACLARACIÓN]` sin resolver, pídeselas al usuario
   antes de continuar.
2. Genera `.claude/specs/<ID>/plan.md` usando `templates/plan-template.md`.
3. Define exactamente qué Servlet/Controller/Service/Model/JSP se crean o modifican,
   respetando el flujo en capas y la nomenclatura en español.
4. Detalla cambios de BD (y si los hay, anota que se actualizará `db_hotel.sql` y
   `sdd/domain-model.md`).
5. Rellena la tabla de verificación contra la constitución. Si algún artículo no se
   cumple, replantea el enfoque o justifícalo explícitamente.
6. No escribas código todavía: este es el diseño.
