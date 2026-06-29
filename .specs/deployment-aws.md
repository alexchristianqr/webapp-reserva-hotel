# Especificación de Despliegue en AWS

Cómo se despliega **webapp-reserva-hotel** en AWS: una imagen Docker (Tomcat 10.1 con
el WAR como `ROOT.war`) ejecutándose en **ECS Fargate** detrás de un **ALB**, con
**RDS MySQL 8** como base de datos y **CodePipeline/CodeBuild** para CI/CD.

La infraestructura es **código** (CloudFormation) en `.aws/iac/stacks/` y se despliega
desde un único punto: `scripts/deploy.sh`.

## Arquitectura objetivo

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

- El contenedor sirve el WAR como `ROOT.war`, es decir en `/` (sin context path), para
  que el ALB acceda directamente a `/api/health` y `/login.jsp`.
- El health check del Target Group es `GET /api/health` esperando `200`
  (`servlets/HealthServlet`, que no requiere sesión ni toca la BD).
- RDS usa `ManageMasterUserPassword: true`: AWS genera y rota la contraseña en Secrets
  Manager; no hay contraseñas en texto plano en las plantillas.
- El Security Group de la BD solo admite `3306` desde el Security Group de la app.

## Los 5 stacks CloudFormation

Se despliegan **en orden**; cada uno consume *Outputs* del anterior. Los stacks **no**
usan `Export`/`ImportValue`: los outputs se pasan como `--parameter-overrides` del
siguiente (`scripts/deploy.sh` lo hace automáticamente).

| Paso | Plantilla | Nombre de stack | Crea | Outputs clave |
|------|-----------|-----------------|------|---------------|
| 01 | `step_01/ecr-stack.yml` | `reserva-hotel-ecr-<env>` | Repositorio ECR | `ExportedEcrRepositoryName` |
| 02 | `step_02/net-stack.yml` | `reserva-hotel-net-<env>` | ALB, Target Group, Security Group, Listener | `ExportedSecurityGroup`, `ExportedTargetGroupArn`, `ExportedLoadBalancerDnsName` |
| 03 | `step_03/db-stack.yml` | `reserva-hotel-db-<env>` | RDS MySQL 8, DB Security Group, DB Subnet Group, secret | `ExportedDbEndpoint`, `ExportedDbSecretArn`, `ExportedDbName` |
| 04 | `step_04/app-stack.yml` | `reserva-hotel-app-<env>` | ECS Task Definition, ECS Service, IAM Roles, Log Group | `ExportedECSServiceName` |
| 05 | `step_05/cicd-stack.yml` | `reserva-hotel-cicd-<env>` | CodePipeline, CodeBuild, bucket S3 de artefactos, IAM Roles | — |

> El repositorio ECR real se llama `<RepoName>-<env>` (p. ej. `webapp-reserva-hotel-dev`).

### Encadenamiento de Outputs → parámetros

| Output (stack origen) | Parámetro (stack destino) |
|-----------------------|---------------------------|
| `ExportedSecurityGroup` (net) | `AppSecurityGroupImported` (db), `SecurityGroupImported` (app) |
| `ExportedTargetGroupArn` (net) | `TargetGroupArnImported` (app) |
| `ExportedDbEndpoint` (db) | `DbEndpointImported` (app) |
| `ExportedDbSecretArn` (db) | `DbSecretArnImported` (app) |
| `ExportedECSServiceName` (app) | `ECSServiceNameImported` (cicd) |

### Recursos que NO crean los stacks (los aporta el despliegue)

- **Clúster ECS**: ningún stack lo crea; `scripts/deploy.sh` lo crea de forma
  idempotente (o reutiliza el existente) y pasa su ARN al stack `app`.
- **Imagen Docker inicial**: el stack `app` requiere una imagen ya presente en ECR. El
  script construye y publica la imagen (vía el `Dockerfile` de la raíz) **antes** de
  desplegar `app`.
- **VPC y subredes**: se asumen existentes y se pasan como variables.

## Variables del despliegue

Centralizadas en `scripts/deploy.env` (copia de `scripts/deploy.env.example`). El
entorno del shell tiene prioridad sobre el archivo.

| Variable | Descripción | Default |
|----------|-------------|---------|
| `AWS_REGION` | Región AWS | `us-east-1` |
| `AWS_PROFILE` | Perfil del AWS CLI (opcional) | — |
| `ENV` | Entorno: `dev`/`qa`/`prod` | `dev` |
| `STACK_PREFIX` | Prefijo de nombres de stack | `reserva-hotel` |
| `REPO_NAME` | Nombre base del repo ECR | `webapp-reserva-hotel` |
| `IMAGE_TAG` | Etiqueta de la imagen Docker | `latest` |
| `VPC_ID` | VPC existente | (obligatorio) |
| `PUBLIC_SUBNET_IDS` | Subredes públicas del ALB (≥2 AZ) | (obligatorio) |
| `PRIVATE_SUBNET_IDS` | Subredes privadas de las tareas ECS | = públicas si se omite |
| `DB_SUBNET_IDS` | Subredes del DB Subnet Group (≥2 AZ) | = privadas si se omite |
| `LISTENER_PORT` / `CONTAINER_PORT` | Puerto público / del contenedor | `80` / `8080` |
| `DB_NAME` / `DB_USERNAME` | Base de datos y usuario maestro | `db_hotel` / `admin` |
| `DB_INSTANCE_CLASS` / `ALLOCATED_STORAGE` | Clase RDS / almacenamiento GB | `db.t3.micro` / `20` |
| `ECS_CLUSTER_NAME` | Clúster ECS (se crea si falta) | `reserva-hotel-cluster` |
| `CPU` / `MEMORY` / `DESIRED_COUNT` | Recursos y réplicas de la tarea | `512` / `1024` / `1` |
| `GITHUB_OWNER` / `GITHUB_BRANCH` | Repo y rama de GitHub | `alexchristianqr` / `main` |
| `GITHUB_TOKEN` | Token de GitHub (secreto, no versionar) | (obligatorio para cicd) |

## Variables de entorno que consume el contenedor

| Variable | Origen en AWS | Default local |
|----------|---------------|---------------|
| `DB_HOST` | `Environment` (endpoint de RDS) | `127.0.0.1` |
| `DB_PORT` | `Environment` (`3306`) | `3306` |
| `DB_NAME` | `Environment` (`db_hotel`) | `db_hotel` |
| `DB_USER` | `Secrets` (clave `username` del secret de RDS) | `root` |
| `DB_PASSWORD` | `Secrets` (clave `password` del secret de RDS) | (vacío) |

## Runbook (despliegue completo)

Prerrequisitos: AWS CLI v2 configurada, Docker en ejecución, una VPC con subredes y un
token de GitHub.

```bash
# 1. Configurar variables
cp scripts/deploy.env.example scripts/deploy.env
#    editar VPC_ID, subredes, GITHUB_TOKEN, etc.

# 2. Desplegar toda la infraestructura (un solo comando)
bash scripts/deploy.sh up
#    Orden: ECR -> imagen Docker -> Networking -> RDS -> clúster ECS -> App -> CI/CD

# 3. Verificar (el script imprime el DNS del ALB al terminar)
curl http://<ALB-DNS>/api/health     # 200 {"status":"UP"}
curl -I http://<ALB-DNS>/login.jsp   # 200
```

Comandos adicionales:

```bash
bash scripts/deploy.sh up db      # desplegar solo un paso
bash scripts/deploy.sh image      # solo build + push de la imagen
bash scripts/deploy.sh outputs    # ver Outputs de los stacks
bash scripts/deploy.sh down       # eliminar la infraestructura (orden inverso)
```

Tras el primer despliegue, los `push` a la rama configurada disparan el pipeline
(CodePipeline → CodeBuild ejecuta `buildspec.yml` → ECR → Deploy a ECS), que reconstruye
y redespliega la aplicación automáticamente.

## Teardown

`scripts/deploy.sh down` elimina los stacks en orden inverso (cicd → app → db → net →
ecr) esperando a que cada uno termine.

- El **repositorio ECR** tiene `DeletionPolicy: Retain`; si conserva imágenes no se
  borra. Forzar:
  `aws ecr delete-repository --repository-name webapp-reserva-hotel-<env> --force`.
- La **instancia RDS** tiene `DeletionPolicy: Snapshot`: al eliminarse se crea un
  snapshot final.

## Pendientes / mejoras futuras

- **HTTPS/ACM** en el ALB (hoy solo HTTP :80).
- **Pool de conexiones JDBC** en la app (hoy una conexión por servicio).
- **Multi-AZ** y retención de backups extendida en RDS para producción.
- Posible migración a `Export`/`ImportValue` para encadenar stacks sin pasar parámetros
  manualmente.
