# Despliegue de webapp-reserva-hotel en AWS con CloudFormation (IaC)

> Documento de la tarea: análisis del directorio `.aws`, refactorización de la
> infraestructura como código y preparación de la app Java/Maven para desplegarse
> en AWS. Fecha: 2026-06-25.

## 1. Diagnóstico (estado inicial)

El directorio `.aws/iac/stacks/` contenía **4 plantillas de CloudFormation copiadas de
otro proyecto** (un microservicio **NestJS** llamado `series-ms` / `hotel-channel-service-ms`).
No correspondían a esta aplicación, que es:

- **Java 21**, empaquetada como **WAR** (`webapp-reserva-hotel.war`) sobre **Tomcat 10.1**.
- Persistencia en **MySQL 8** (base `db_hotel`) vía JDBC puro.

Desajustes encontrados en la plantilla original:

| Aspecto | Plantilla (NestJS) | App real (Java) |
|---------|--------------------|-----------------|
| Contenedor | `nginx-nestjs`, puerto `3000` | Tomcat, puerto `8080` |
| Base imagen CI | `node:20-alpine` | Maven + Tomcat (Dockerfile) |
| Persistencia | DynamoDB (permisos IAM) | MySQL (RDS) |
| Config | Secrets `NODE_ENV/PORT/...` (SSM) | Vars `DB_*` |
| Health check | `/api/health` (inexistente) | (se añade servlet) |
| Stack de BD | No existía | RDS MySQL nuevo |
| Dockerfile / buildspec | No existían | Se crean |
| Credenciales BD | Hardcodeadas en `MysqlDBService.java` | Externalizadas a env vars |

## 2. Arquitectura objetivo

```
GitHub (push) ──► CodePipeline ──► CodeBuild ──► ECR (imagen Docker)
                                       │
                                       └─► Deploy ECS ──► ECS Service (Fargate)
                                                                │
Internet ──► ALB (:80) ──► Target Group (:8080) ──► Tomcat (ROOT.war)
                                                                │
                                                                └─► RDS MySQL (:3306)
                                                                       creds: Secrets Manager
```

Stacks (orden de despliegue; cada uno consume outputs del anterior):

| Step | Plantilla | Recursos | Outputs clave |
|------|-----------|----------|---------------|
| 01 | `step_01/ecr-stack.yml` | ECR Repository | `ExportedEcrRepositoryName` |
| 02 | `step_02/net-stack.yml` | ALB, Target Group, Security Group, Listener | `ExportedSecurityGroup`, `ExportedTargetGroupArn`, `ExportedLoadBalancerDnsName` |
| 03 | `step_03/db-stack.yml` | RDS MySQL 8, DB SG, DB Subnet Group, secret (RDS-managed) | `ExportedDbEndpoint`, `ExportedDbSecretArn`, `ExportedDbName` |
| 04 | `step_04/app-stack.yml` | ECS Task Definition, ECS Service, IAM Roles, Log Group | `ExportedECSServiceName` |
| 05 | `step_05/cicd-stack.yml` | CodePipeline, CodeBuild, S3 artefactos, IAM Roles | — |

> Los stacks **no usan `Export`/`ImportValue`**; los outputs de un stack se pasan
> manualmente como `--parameter-overrides` del siguiente (ver `README.md`).

## 3. Decisiones tomadas

1. **Base de datos: RDS MySQL nuevo (CloudFormation).** Se añadió `step_03/db-stack.yml`
   con una instancia RDS MySQL 8. Se usa `ManageMasterUserPassword: true` para que **RDS
   genere y rote la contraseña en AWS Secrets Manager** (sin contraseñas en texto plano en
   la plantilla). El SG de la BD solo admite `3306` desde el SG de la app.

2. **Health check: `HealthServlet` en `/api/health`.** El Target Group del ALB ya apuntaba
   a `/api/health`. Se creó `servlets/HealthServlet.java` (extiende `HttpServlet`
   directamente, **no** `BaseServlet`, para no exigir sesión y evitar 401) que devuelve
   `200 {"status":"UP"}` sin tocar la BD.

3. **CI/CD con GitHub (mantenido).** Se refactorizó el pipeline: CodeBuild ejecuta el
   `buildspec.yml`, que construye la imagen vía `Dockerfile` multi-stage (Maven compila el
   WAR, Tomcat lo sirve), la publica en ECR y genera `imagedefinitions.json` para que la
   etapa Deploy actualice el servicio ECS.

## 4. Cambios realizados

### Código de la aplicación
- `src/main/java/core/services/MysqlDBService.java`: la URL/usuario/clave de JDBC ahora se
  leen de variables de entorno (`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`)
  con *fallback* a los valores locales (`127.0.0.1` / `root` / sin clave). No rompe el
  desarrollo local.
- `src/main/java/servlets/HealthServlet.java` (**nuevo**): endpoint `/api/health`.

### Contenedor / build (raíz del repo)
- `Dockerfile` (**nuevo**): multi-stage `maven:3.9-eclipse-temurin-21` → `tomcat:10.1-jre21-temurin`.
  El WAR se despliega como `ROOT.war` (la app queda servida en `/`).
- `buildspec.yml` (**nuevo**): login a ECR, `docker build/push`, `imagedefinitions.json`.

### Infraestructura
- `step_02/net-stack.yml`: se separó `ListenerPort` (80, público) de `ContainerPort`
  (8080, contenedor); se añadió una regla de ingreso self-referenciada para que el ALB
  alcance el contenedor en `8080`.
- `step_03/db-stack.yml` (**nuevo**): RDS MySQL.
- `step_04/app-stack.yml` (movido desde `step_03`): contenedor `webapp-reserva-hotel`,
  puerto `8080`, sin permisos DynamoDB, variables `DB_*` (host/puerto/nombre por env y
  usuario/clave por Secrets Manager), logs con prefijo `tomcat`, `DesiredCount` parametrizable.
- `step_05/cicd-stack.yml` (movido desde `step_04`): `CONTAINER_NAME_1=webapp-reserva-hotel`,
  sin `BaseImage` de Node, `AWS_ACCOUNT_ID` para el buildspec, rama por defecto `main`.

## 5. Variables de entorno que consume el contenedor

| Variable | Origen (en AWS) | Default local |
|----------|-----------------|---------------|
| `DB_HOST` | `Environment` (endpoint RDS) | `127.0.0.1` |
| `DB_PORT` | `Environment` (`3306`) | `3306` |
| `DB_NAME` | `Environment` (`db_hotel`) | `db_hotel` |
| `DB_USER` | `Secrets` (clave `username` del secret RDS) | `root` |
| `DB_PASSWORD` | `Secrets` (clave `password` del secret RDS) | `` (vacío) |

## 6. Despliegue (resumen)

Ver comandos completos en `.aws/iac/stacks/README.md`. Orden: **01 → 02 → 03 → 04 → 05**,
encadenando los Outputs de cada stack como parámetros del siguiente
(`aws cloudformation describe-stacks --stack-name <x> --query "Stacks[0].Outputs"`).

## 7. Verificación

1. `mvn -q clean package` → genera `target/webapp-reserva-hotel.war` y pasa los tests.
2. Build/run local del contenedor:
   ```bash
   docker build -t reserva-hotel:test .
   docker run -p 8080:8080 -e DB_HOST=host.docker.internal -e DB_USER=root -e DB_PASSWORD= reserva-hotel:test
   curl http://localhost:8080/api/health   # 200 {"status":"UP"}
   curl -I http://localhost:8080/login.jsp # 200
   ```
3. `sam validate --lint` para los 5 stacks.
4. End-to-end: `curl http://<ALB-DNS>/api/health` → 200; target *healthy*; login funcional.

## 8. Pendientes / mejoras futuras

- HTTPS/ACM en el ALB (hoy solo HTTP :80).
- Pool de conexiones JDBC (hoy una conexión por servicio).
- `Multi-AZ` y backups extendidos en RDS para producción.
- Posible migración de la app a `Export`/`ImportValue` para encadenar stacks sin parámetros manuales.
