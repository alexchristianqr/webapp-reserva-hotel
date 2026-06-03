# Flujo de Trabajo SDD (Spec-Driven Development)

El desarrollo sigue cuatro fases. Cada una produce un artefacto que alimenta la
siguiente. La especificación es la fuente de verdad; el código es su resultado.

```
  IDEA                                         CÓDIGO QUE FUNCIONA
   │                                                   ▲
   ▼                                                   │
┌─────────┐   ┌────────┐   ┌─────────┐   ┌───────────────┐
│ specify │ → │  plan  │ → │  tasks  │ → │   implement   │
│ spec.md │   │ plan.md│   │ tasks.md│   │ código + tests │
└─────────┘   └────────┘   └─────────┘   └───────────────┘
   QUÉ/         CÓMO          PASOS          EJECUCIÓN
  POR QUÉ      (técnico)    (verificables)
```

## Fase 1 — `specify` (QUÉ y POR QUÉ)

- Entrada: una idea o petición en lenguaje de negocio.
- Salida: `.claude/specs/<NNN-nombre-feature>/spec.md` (usa `templates/spec-template.md`).
- Describe usuarios, historias, requisitos funcionales y criterios de aceptación.
- **No** se habla de implementación, clases ni SQL todavía.
- Marca lo ambiguo con `[NECESITA ACLARACIÓN: ...]` en vez de inventar.

## Fase 2 — `plan` (CÓMO)

- Entrada: `spec.md` + `sdd/architecture.md` + `sdd/conventions.md` + `sdd/domain-model.md`.
- Salida: `plan.md` (usa `templates/plan-template.md`).
- Define qué Servlet/Controller/Service/Model/JSP se crean o modifican, qué SQL/tablas
  se tocan y cómo encaja en las capas existentes.
- Debe verificarse contra la **constitución** (`sdd/constitution.md`).

## Fase 3 — `tasks` (PASOS)

- Entrada: `plan.md`.
- Salida: `tasks.md` (usa `templates/tasks-template.md`).
- Lista numerada de tareas pequeñas, ordenadas por dependencia, cada una verificable
  de forma independiente. Marca con `[P]` las que pueden ir en paralelo.

## Fase 4 — `implement` (EJECUCIÓN)

- Entrada: `tasks.md`.
- Salida: código en `src/java/...` y/o `web/...`, marcando cada tarea como `[x]`.
- Sigue el orden de las tareas; respeta capas y convenciones.
- Verifica: `mvn -q clean package` (compila) y `mvn test` (si hay tests).

## Numeración de features

Las features se numeran con tres dígitos incrementales:
`specs/001-gestion-comprobantes/`, `specs/002-portal-cliente/`, etc.

## Mantenimiento de las specs

- Si durante `implement` descubres que la spec o el plan estaban equivocados,
  **actualiza el archivo** y deja constancia, en vez de divergir en silencio.
- Si el cambio altera arquitectura o modelo de dominio, actualiza también
  `sdd/architecture.md` o `sdd/domain-model.md`.

## Uso con distintas IAs

- **Claude Code**: usa los comandos `/specify`, `/plan`, `/tasks`, `/implement`
  (definidos en `.claude/commands/`).
- **Otras IAs**: pega el contenido del archivo de `commands/` correspondiente más los
  archivos de `sdd/` relevantes como contexto.
