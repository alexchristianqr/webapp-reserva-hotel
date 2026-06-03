---
description: Crea la especificación (QUÉ/POR QUÉ) de una nueva feature siguiendo SDD
argument-hint: <descripción de la feature en lenguaje de negocio>
---

Vas a ejecutar la **Fase 1 (specify)** del flujo SDD para este proyecto.

Contexto obligatorio a leer antes de empezar:
- `.claude/sdd/constitution.md`
- `.claude/sdd/product.md`
- `.claude/sdd/domain-model.md`
- `.claude/templates/spec-template.md`

Petición del usuario: **$ARGUMENTS**

Pasos:
1. Determina el siguiente número de feature mirando las carpetas existentes en
   `.claude/specs/` (formato `NNN-nombre-feature`, tres dígitos).
2. Crea la carpeta `.claude/specs/<NNN-nombre-feature>/`.
3. Genera `spec.md` a partir de `templates/spec-template.md`, rellenando todas las
   secciones con base en la petición y el contexto del producto/dominio.
4. Describe SOLO el QUÉ y el POR QUÉ. No incluyas clases, SQL ni nombres de archivos.
5. Donde haya ambigüedad, escribe `[NECESITA ACLARACIÓN: ...]` en lugar de inventar.
6. Al terminar, resume las preguntas abiertas que el usuario debe responder antes de
   pasar a `/plan`.
