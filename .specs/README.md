# Especificaciones de webapp-reserva-hotel

Esta carpeta contiene las **especificaciones del proyecto**: la descripción
canónica de qué hace el sistema, cómo está construido y cómo se despliega.

> **Independiente de herramientas.** Estos documentos están escritos para cualquier
> persona del equipo —desarrollo, operaciones o QA— y no dependen de ningún editor,
> asistente ni flujo de trabajo concreto. Son la referencia neutral del proyecto.

## Contenido

| Documento | Describe |
|-----------|----------|
| [`product.md`](product.md) | Visión de producto: problema, usuarios, capacidades, alcance. |
| [`architecture.md`](architecture.md) | Stack técnico, estructura del repo y flujo de una petición. |
| [`domain-model.md`](domain-model.md) | Esquema de la base de datos `db_hotel` y los POJOs. |
| [`conventions.md`](conventions.md) | Convenciones de código backend (servlets/controllers/services) y frontend (JSP + Vue). |
| [`deployment-aws.md`](deployment-aws.md) | Arquitectura cloud, los 5 stacks CloudFormation, variables y runbook de despliegue. |

## Cómo usar estas specs

- **Antes de añadir una funcionalidad**, revisa `product.md` (alcance) y
  `domain-model.md` (datos existentes).
- **Al escribir código**, sigue `architecture.md` y `conventions.md` para mantener la
  coherencia con el patrón en capas existente.
- **Para desplegar o tocar la infraestructura**, usa `deployment-aws.md` junto con el
  script único `scripts/deploy.sh` y las plantillas de `.aws/iac/stacks/`.

## Fuentes de verdad relacionadas

- Esquema de base de datos: `database/db_hotel.sql` (+ migraciones `db_hotel_migracion_*.sql`).
- Infraestructura como código: `.aws/iac/stacks/` (5 stacks CloudFormation).
- Despliegue: `scripts/` (`deploy.sh`, `deploy.env.example`).
