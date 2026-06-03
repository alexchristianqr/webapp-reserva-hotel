# `.claude/` — Spec-Driven Development (SDD)

Esta carpeta contiene las **especificaciones del proyecto** y la **metodología de
desarrollo guiado por especificaciones (SDD)**. Está pensada para usarse con
**cualquier asistente de IA** (Claude Code, Cursor, Copilot, ChatGPT, Gemini, etc.),
no solo con Claude.

> En SDD la **especificación es la fuente de verdad**: primero se describe *qué* y
> *por qué*, luego *cómo*, después se descompone en *tareas* y por último se *implementa*.
> El código es la salida de la especificación, no al revés.

## Estructura

```
.claude/
├── README.md                  ← este archivo (cómo usar el SDD)
├── sdd/                        ← especificaciones permanentes del proyecto
│   ├── constitution.md         ← principios y reglas inviolables
│   ├── product.md              ← visión de producto, usuarios, alcance
│   ├── architecture.md         ← arquitectura técnica en capas
│   ├── domain-model.md         ← entidades, esquema de BD y relaciones
│   ├── conventions.md          ← convenciones de código y estilo
│   └── workflow.md             ← el ciclo de trabajo SDD paso a paso
├── templates/                 ← plantillas reutilizables para nuevas features
│   ├── spec-template.md        ← plantilla de especificación (QUÉ/POR QUÉ)
│   ├── plan-template.md        ← plantilla de plan técnico (CÓMO)
│   └── tasks-template.md       ← plantilla de desglose en tareas
├── commands/                  ← comandos slash para Claude Code (y guía manual)
│   ├── specify.md
│   ├── plan.md
│   ├── tasks.md
│   └── implement.md
└── specs/                     ← (se va llenando) una carpeta por feature
    └── <NNN-nombre-feature>/
        ├── spec.md
        ├── plan.md
        └── tasks.md
```

## Cómo usarlo con CUALQUIER IA

Si tu herramienta no soporta comandos slash, simplemente **pega el contenido** del
archivo de `commands/` correspondiente en el chat, junto con los archivos de `sdd/`
que den contexto. El flujo es siempre el mismo:

1. **`/specify`** — Describe la funcionalidad en lenguaje de negocio. Genera
   `specs/<NNN-feature>/spec.md` a partir de `templates/spec-template.md`.
   *No* se habla de implementación todavía.
2. **`/plan`** — A partir del `spec.md` y respetando `sdd/architecture.md` +
   `sdd/conventions.md`, genera `plan.md` con el diseño técnico.
3. **`/tasks`** — Descompone el plan en tareas pequeñas y verificables → `tasks.md`.
4. **`/implement`** — Ejecuta las tareas una a una, marcándolas como hechas.

## Reglas para el agente

- Antes de escribir código, **lee `sdd/constitution.md`** — son reglas que no se rompen.
- Respeta `sdd/architecture.md` (flujo en capas) y `sdd/conventions.md` (estilo).
- Usa `sdd/domain-model.md` como referencia del esquema real de la BD.
- Si una petición contradice la constitución o la arquitectura, **detente y avísalo**
  en lugar de improvisar.
- Mantén las especificaciones actualizadas: si un cambio altera la arquitectura o el
  modelo de dominio, actualiza el archivo correspondiente en `sdd/`.

## Relación con `CLAUDE.md`

`CLAUDE.md` (en la raíz) es el **resumen operativo** que Claude Code carga
automáticamente. Esta carpeta `.claude/sdd/` es la **referencia detallada**. Ante
cualquier duda, los archivos de `sdd/` mandan sobre el resumen.
