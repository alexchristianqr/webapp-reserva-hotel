# STEPS — Despliegue de webapp-reserva-hotel en AWS

App Java 21 (WAR sobre Tomcat 10.1) + MySQL 8, desplegada como contenedor en
**ECS Fargate** detrás de un **ALB**, con **RDS MySQL** y CI/CD por **CodePipeline/CodeBuild**.

> Documentación detallada del diseño y decisiones: `.aws/iac/docs/despliegue-aws.md`.
> Acceso a la BD RDS y carga del schema (login de la app): `.aws/iac/docs/acceso-bd-rds.md`.

Orden de despliegue (cada stack consume outputs del anterior):

| Step | Plantilla | Crea |
|------|-----------|------|
| 01 | `step_01/ecr-stack.yml` | Repositorio ECR |
| 02 | `step_02/net-stack.yml` | ALB + Target Group + Security Group |
| 03 | `step_03/db-stack.yml`  | RDS MySQL 8 + SG + secret (Secrets Manager) |
| 04 | `step_04/app-stack.yml` | ECS Fargate (Task Definition + Service) |
| 05 | `step_05/cicd-stack.yml`| CodePipeline + CodeBuild (GitHub) |

## Despliegue en un comando (`scripts/deploy.sh`) — recomendado

Para un enfoque académico, `scripts/deploy.sh` orquesta **todo** (construye la imagen,
despliega los 5 stacks encadenando Outputs, crea el clúster ECS y **siembra la BD**), y
también permite **eliminar y recrear todo de un solo comando**.

> Requisitos: AWS CLI v2 configurada, **Docker en ejecución**, y `scripts/deploy.env` con
> tus variables (cópialo de `scripts/deploy.env.example`).

```bash
# ── LEVANTAR TODO (de cero a app funcionando, con login operativo) ──
scripts/deploy.sh up
#   ECR → imagen Docker → Networking → RDS → SEED BD → clúster ECS → App → CI/CD
#   El paso 'seed' carga database/db_hotel.sql (abre acceso temporal a RDS y lo cierra solo).

# ── ELIMINAR TODO (orden inverso, seguro) ──
scripts/deploy.sh down
#   cicd → app → db → net → ecr   (el repo ECR tiene DeletionPolicy: Retain)

# ── CICLO COMPLETO (deshacer y volver a crear de un tirón) ──
scripts/deploy.sh down && scripts/deploy.sh up

# ── Pasos sueltos (si solo quieres uno) ──
scripts/deploy.sh up image     # solo rebuild + push de la imagen
scripts/deploy.sh up app       # solo redeploy del servicio ECS
scripts/deploy.sh seed         # recargar el schema/datos en la BD

# ── Acceso a la BD para un gestor (MySQL Workbench / DBeaver) ──
scripts/deploy.sh db-creds     # imprime host, puerto, usuario y clave (del secret)
scripts/deploy.sh db-open      # habilita acceso temporal a RDS desde tu IP
scripts/deploy.sh db-close     # cierra el acceso temporal (vuelve privada)

scripts/deploy.sh help         # ayuda completa
```

> **Tras `down`/`up`, la app queda con el login listo** (`alex.quispe@gmail.com` / `12345678`),
> porque `up` ya siembra la BD. El detalle del acceso a la BD está en
> `.aws/iac/docs/acceso-bd-rds.md`.

> Nota: borrar el ECR con imágenes (tiene `DeletionPolicy: Retain`):
> `aws ecr delete-repository --repository-name webapp-reserva-hotel-dev --force`

## Costos y pausa/reanudación (ahorro)

No todo cuesta igual. Lo que cobra **24/7** son tres recursos; el resto es casi gratis:

| Stack | Recurso | Costo si queda 24/7 (aprox.) | ¿Apagar para ahorrar? |
|-------|---------|------------------------------|------------------------|
| `net` | ALB (Application Load Balancer) | ~$16/mes | 🔴 Sí |
| `db`  | RDS db.t3.micro + 20GB + backups | ~$15-18/mes | 🔴 Sí |
| `app` | ECS Fargate (0.5 vCPU/1GB × 2 tareas) | ~$30/mes | 🔴 Sí |
| `ecr` | Repositorio + imágenes | centavos | 🟢 Conservar |
| `cicd`| CodePipeline + CodeBuild (por build) | ~$1-2/mes | 🟢 Conservar |
| —     | Secrets Manager, CloudWatch Logs, SGs, cluster ECS vacío | centavos / gratis | 🟢 Conservar |

> No hay NAT Gateway (se usa IP pública), lo que ahorra ~$32/mes.

Para **pausar el gasto sin destruir todo** (conserva imágenes y pipeline):

```bash
# Apagar lo caro (ALB + RDS + Fargate). Conserva ECR + CICD.
scripts/deploy.sh pause

# Volver a levantar (recrea net -> db -> seed -> app; reusa la imagen de ECR).
scripts/deploy.sh resume
```

- `pause` borra `app`, `db` y `net`. Quedan `ecr` (imágenes) y `cicd` (pipeline).
- `resume` recrea solo lo apagado y **siembra la BD** de nuevo (login operativo).
- Si cambiaste código entre medias, corre `scripts/deploy.sh up image` antes de `resume`
  para publicar la imagen nueva.
- `down` (teardown total) sí borra **todo**, incluido ECR y el bucket de artefactos del
  pipeline (se vacía automáticamente para que no falle el borrado).

> Nota RDS: al borrar el `db-stack` se crea un **snapshot final** (DeletionPolicy: Snapshot).
> Si haces muchos ciclos, esos snapshots se acumulan; bórralos desde la consola de RDS si no
> los necesitas (cada `resume` crea una BD nueva vacía y la vuelve a sembrar).

## Ejecutar con SAM CLI

```bash
# --- Validaciones de las plantillas ---
sam validate --template-file ".aws/iac/stacks/step_01/ecr-stack.yml" --lint
sam validate --template-file ".aws/iac/stacks/step_02/net-stack.yml" --lint
sam validate --template-file ".aws/iac/stacks/step_03/db-stack.yml"  --lint
sam validate --template-file ".aws/iac/stacks/step_04/app-stack.yml" --lint
sam validate --template-file ".aws/iac/stacks/step_05/cicd-stack.yml" --lint

# ============================================================
# STEP 01 — ECR
# ============================================================
sam deploy --template-file ".aws/iac/stacks/step_01/ecr-stack.yml" \
  --stack-name "reserva-hotel-ecr-dev" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides Env="dev" RepoName="webapp-reserva-hotel"

# ============================================================
# STEP 02 — Networking (ALB + Target Group + Security Group)
# Listener publico en :80, Target Group hacia el contenedor en :8080
# ============================================================
sam deploy --template-file ".aws/iac/stacks/step_02/net-stack.yml" \
  --stack-name "reserva-hotel-net-dev" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides Env="dev" \
    VpcId="vpc-XXXXXXXX" \
    PublicSubnetIds="subnet-AAAA,subnet-BBBB" \
    ListenerPort=80 ContainerPort=8080
# Toma de los Outputs: ExportedSecurityGroup, ExportedTargetGroupArn

# ============================================================
# STEP 03 — RDS MySQL
# AppSecurityGroupImported = ExportedSecurityGroup del step_02
# ============================================================
sam deploy --template-file ".aws/iac/stacks/step_03/db-stack.yml" \
  --stack-name "reserva-hotel-db-dev" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides Env="dev" \
    VpcId="vpc-XXXXXXXX" \
    DbSubnetIds="subnet-PRIV1,subnet-PRIV2" \
    AppSecurityGroupImported="sg-XXXX" \
    DBName="db_hotel" DBUsername="admin" \
    DBInstanceClass="db.t3.micro" AllocatedStorage=20
# Toma de los Outputs: ExportedDbEndpoint, ExportedDbSecretArn

# ============================================================
# STEP 04 — Aplicacion (ECS Fargate)
# Importa SG/TargetGroup del step_02 y endpoint/secret del step_03
# ============================================================
sam deploy --template-file ".aws/iac/stacks/step_04/app-stack.yml" \
  --stack-name "reserva-hotel-app-dev" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides Env="dev" \
    ECSClusterArn="arn:aws:ecs:us-east-1:ACCOUNT:cluster/mi-cluster" \
    PrivateSubnetIds="subnet-PRIV1,subnet-PRIV2" \
    Cpu=512 Memory=1024 \
    RepoName="webapp-reserva-hotel" ImageTag="latest" \
    ContainerPort=8080 DesiredCount=1 \
    SecurityGroupImported="sg-XXXX" \
    TargetGroupArnImported="arn:aws:elasticloadbalancing:...:targetgroup/reserva-hotel-net-dev-tg/..." \
    DbEndpointImported="reserva-hotel-db-dev-mysql.xxxx.us-east-1.rds.amazonaws.com" \
    DbName="db_hotel" \
    DbSecretArnImported="arn:aws:secretsmanager:us-east-1:ACCOUNT:secret:rds!db-xxxx"
# Toma del Output: ExportedECSServiceName

# ============================================================
# STEP 05 — CI/CD (CodePipeline + CodeBuild desde GitHub)
# ECSServiceNameImported = ExportedECSServiceName del step_04
# ============================================================
sam deploy --template-file ".aws/iac/stacks/step_05/cicd-stack.yml" \
  --stack-name "reserva-hotel-cicd-dev" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides Env="dev" \
    RepoOwner="alexchristianqr" RepoName="webapp-reserva-hotel" Branch="main" \
    GitHubToken="ghp_XXXXXXXX" \
    ECRRepoName="webapp-reserva-hotel" \
    ECSClusterName="mi-cluster" \
    ECSServiceNameImported="reserva-hotel-app-dev-ecs"
```

> Nota: La primera vez, el `step_04` desplegara la tarea pero la imagen aun no existe
> en ECR. Ejecuta el `step_05` (pipeline) para construir y publicar la imagen, o haz
> un `docker build/push` manual con el `buildspec.yml`/`Dockerfile` de la raiz.

## Comandos AWS CloudFormation utiles

```bash
# Listar pilas
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE

# Listar recursos de una pila
aws cloudformation list-stack-resources --stack-name reserva-hotel-app-dev --output table

# Ver eventos / errores de despliegue
aws cloudformation describe-stack-events --stack-name reserva-hotel-app-dev

# Ver Outputs de una pila (para encadenar parametros al siguiente step)
aws cloudformation describe-stacks --stack-name reserva-hotel-net-dev \
  --query "Stacks[0].Outputs" --output table

# Eliminar pilas (orden inverso)
sam delete --stack-name reserva-hotel-cicd-dev --no-prompts
sam delete --stack-name reserva-hotel-app-dev  --no-prompts
sam delete --stack-name reserva-hotel-db-dev   --no-prompts
sam delete --stack-name reserva-hotel-net-dev  --no-prompts
sam delete --stack-name reserva-hotel-ecr-dev  --no-prompts

# Forzar eliminacion de un ECR Repository con imagenes (tiene DeletionPolicy: Retain)
aws ecr delete-repository --repository-name "webapp-reserva-hotel-dev" --force
```
