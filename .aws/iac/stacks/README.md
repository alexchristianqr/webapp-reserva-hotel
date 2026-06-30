# Despliegue de webapp-reserva-hotel en AWS

App Java 21 (WAR sobre Tomcat 10.1) + MySQL 8, en **ECS Fargate** detrás de un **ALB**, con
**RDS MySQL** y CI/CD por **CodePipeline/CodeBuild**.

> **Esta es la guía operativa única.** Todo se maneja con `scripts/deploy.sh`.
> Detalle de acceso a la BD → [`docs/acceso-bd-rds.md`](../docs/acceso-bd-rds.md) ·
> Diseño y decisiones → [`docs/despliegue-aws.md`](../docs/despliegue-aws.md).

---

## TL;DR — los comandos que necesitas

| Quiero… | Comando |
|---------|---------|
| **Levantar todo** (de cero a app funcionando) | `scripts/deploy.sh up` |
| **Pausar** para ahorrar (apaga lo caro) | `scripts/deploy.sh pause` |
| **Reanudar** tras pausar | `scripts/deploy.sh resume` |
| **Borrar todo** | `scripts/deploy.sh down` |

**Requisitos:** AWS CLI v2 configurada · **Docker en ejecución** · `scripts/deploy.env`
(cópialo de `scripts/deploy.env.example` y rellena tus valores).

**Tras `up` o `resume`, el login ya funciona:** usuario `alex.quispe@gmail.com` · clave `12345678`.
La URL del ALB la imprime el script al final (o con `scripts/deploy.sh outputs`).

---

## `up` — levantar todo

```bash
scripts/deploy.sh up
```
Hace en orden, encadenando todo automáticamente:

`ECR → imagen Docker → Networking (ALB) → RDS → SEED de la BD → clúster ECS → App (2 tareas) → CI/CD`

- Construye y publica la imagen en ECR.
- Crea los 5 stacks (ver tabla abajo).
- **Siembra la BD** (`database/db_hotel.sql`) para que el login funcione sin pasos manuales.
- Deja la app con **2 tareas** balanceadas por el ALB.

---

## `pause` / `resume` — pausar para ahorrar

No todo cuesta igual. Solo 3 recursos cobran 24/7; el resto es casi gratis:

| Stack | Recurso | Costo 24/7 (aprox.) | En `pause` |
|-------|---------|---------------------|------------|
| `app` | ECS Fargate (2 tareas) | ~$30/mes | 🔴 se borra |
| `net` | ALB | ~$16/mes | 🔴 se borra |
| `db`  | RDS db.t3.micro | ~$15-18/mes | 🔴 se borra |
| `ecr` | Imágenes | centavos | 🟢 se conserva |
| `cicd`| Pipeline | ~$1-2/mes | 🟢 se conserva |

```bash
scripts/deploy.sh pause     # apaga app + net + db (ALB+RDS+Fargate). Conserva ecr + cicd.
scripts/deploy.sh resume    # recrea net → db → seed → app. Reusa la imagen de ECR.
```

- `resume` **vuelve a sembrar la BD** (login operativo de nuevo).
- Si cambiaste código entre medias: `scripts/deploy.sh up image` **antes** de `resume`.
- No hay NAT Gateway (se usa IP pública), lo que ahorra ~$32/mes.

> Nota: borrar el `db-stack` crea un **snapshot final** de RDS (DeletionPolicy: Snapshot). Si
> haces muchos ciclos, esos snapshots se acumulan; bórralos en la consola de RDS si no los
> necesitas (cada `resume` crea una BD nueva vacía y la siembra otra vez).

---

## `down` — borrar todo

```bash
scripts/deploy.sh down
```
Elimina **los 5 stacks** en orden inverso (`cicd → app → db → net → ecr`), incluido el
repositorio ECR y el bucket de artefactos del pipeline (se **vacía automáticamente** para que
el borrado no falle).

> Para empezar de cero limpio: `scripts/deploy.sh down && scripts/deploy.sh up`.

---

## Otros comandos (referencia)

| Comando | Para qué |
|---------|----------|
| `scripts/deploy.sh up image` | Solo reconstruir + publicar la imagen Docker. |
| `scripts/deploy.sh up app` | Solo redeploy del servicio ECS. |
| `scripts/deploy.sh seed` | Recargar el schema/datos en la BD. |
| `scripts/deploy.sh db-creds` | Imprime host, puerto, usuario y clave de la BD (del secret). |
| `scripts/deploy.sh db-open` | Habilita acceso temporal a RDS desde tu IP (para un gestor de BD). |
| `scripts/deploy.sh db-close` | Cierra ese acceso (RDS vuelve privada). |
| `scripts/deploy.sh outputs` | Muestra los Outputs de los stacks (URL del ALB, etc.). |
| `scripts/deploy.sh help` | Ayuda completa. |

Conectarte a la BD con MySQL Workbench/DBeaver → ver [`docs/acceso-bd-rds.md`](../docs/acceso-bd-rds.md).

---

## ¿Qué se crea? (los 5 stacks)

| Step | Plantilla | Crea |
|------|-----------|------|
| 01 | `step_01/ecr-stack.yml` | Repositorio ECR |
| 02 | `step_02/net-stack.yml` | ALB + Target Group (con sticky sessions) + Security Group |
| 03 | `step_03/db-stack.yml`  | RDS MySQL 8 + SG + secret (Secrets Manager) |
| 04 | `step_04/app-stack.yml` | ECS Fargate (Task Definition + Service, 2 tareas) |
| 05 | `step_05/cicd-stack.yml`| CodePipeline + CodeBuild (GitHub) |

---

## Comprobar el balanceo de carga (ALB)

El servicio corre con **2 tareas**. El endpoint `/api/health` devuelve la tarea que responde:

```json
{"status":"UP","instance":{"host":"ip-172-31-73-145.ec2.internal","ip":"172.31.73.145"}}
```

> ⚠️ El Target Group tiene **sticky sessions** (cookie `AWSALB`) para no perder el login. Por
> eso un **mismo navegador siempre ve la misma IP**. Para ver las 2 IPs, pide sin esa cookie:

```bash
# curl no guarda cookies → el ALB hace round-robin y la IP alterna
ALB=$(aws cloudformation describe-stacks --stack-name reserva-hotel-net-dev \
  --query "Stacks[0].Outputs[?OutputKey=='ExportedLoadBalancerDnsName'].OutputValue" --output text)
for i in $(seq 1 10); do curl -s http://$ALB/api/health; echo; done
```

Verás alternar dos IPs (tareas en `us-east-1a` y `us-east-1f`), ~50/50. En navegador, usa
**ventanas de incógnito** distintas para caer en tareas diferentes.

| Escenario | Resultado | Motivo |
|-----------|-----------|--------|
| App real (login, mismo navegador) | siempre **1 tarea** | sticky session preserva el login |
| `/api/health` con `curl` (sin cookie) | alterna **2 IPs** | sin cookie, round-robin |

**Failover:** detén una tarea y repite el `curl`; responderá solo la IP viva y ECS levanta otra en ~20-30s:
```bash
TASK=$(aws ecs list-tasks --cluster reserva-hotel-cluster --service-name reserva-hotel-app-dev-ecs --query "taskArns[0]" --output text)
aws ecs stop-task --cluster reserva-hotel-cluster --task "$TASK" --reason "prueba failover"
```

---

<details>
<summary><b>Apéndice — Despliegue manual con SAM CLI (avanzado, sin deploy.sh)</b></summary>

Normalmente no hace falta: `scripts/deploy.sh` ya orquesta esto. Útil para entender cada paso
o desplegar uno aislado. Cada stack consume Outputs del anterior.

```bash
# Validar plantillas
sam validate --template-file ".aws/iac/stacks/step_01/ecr-stack.yml" --lint   # (idem 02..05)

# 01 — ECR
sam deploy --template-file ".aws/iac/stacks/step_01/ecr-stack.yml" \
  --stack-name "reserva-hotel-ecr-dev" --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides Env="dev" RepoName="webapp-reserva-hotel"

# 02 — Networking (ALB + Target Group + SG). Listener :80 → contenedor :8080
sam deploy --template-file ".aws/iac/stacks/step_02/net-stack.yml" \
  --stack-name "reserva-hotel-net-dev" --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides Env="dev" VpcId="vpc-XXXX" \
    PublicSubnetIds="subnet-AAAA,subnet-BBBB" ListenerPort=80 ContainerPort=8080
# Outputs: ExportedSecurityGroup, ExportedTargetGroupArn

# 03 — RDS MySQL (AppSecurityGroupImported = ExportedSecurityGroup del step_02)
sam deploy --template-file ".aws/iac/stacks/step_03/db-stack.yml" \
  --stack-name "reserva-hotel-db-dev" --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides Env="dev" VpcId="vpc-XXXX" \
    DbSubnetIds="subnet-AAAA,subnet-BBBB" AppSecurityGroupImported="sg-XXXX" \
    DBName="db_hotel" DBUsername="admin" DBInstanceClass="db.t3.micro" AllocatedStorage=20
# Outputs: ExportedDbEndpoint, ExportedDbSecretArn

# 04 — App (ECS Fargate). Importa SG/TargetGroup del 02 y endpoint/secret del 03
sam deploy --template-file ".aws/iac/stacks/step_04/app-stack.yml" \
  --stack-name "reserva-hotel-app-dev" --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides Env="dev" \
    ECSClusterArn="arn:aws:ecs:us-east-1:ACCOUNT:cluster/reserva-hotel-cluster" \
    PrivateSubnetIds="subnet-AAAA,subnet-BBBB" Cpu=512 Memory=1024 \
    RepoName="webapp-reserva-hotel" ImageTag="latest" ContainerPort=8080 DesiredCount=2 \
    SecurityGroupImported="sg-XXXX" TargetGroupArnImported="arn:...:targetgroup/..." \
    DbEndpointImported="reserva-hotel-db-dev-mysql.xxxx.us-east-1.rds.amazonaws.com" \
    DbName="db_hotel" DbSecretArnImported="arn:aws:secretsmanager:...:secret:rds!db-xxxx"
# Output: ExportedECSServiceName

# 05 — CI/CD (ECSServiceNameImported = ExportedECSServiceName del step_04)
sam deploy --template-file ".aws/iac/stacks/step_05/cicd-stack.yml" \
  --stack-name "reserva-hotel-cicd-dev" --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides Env="dev" RepoOwner="alexchristianqr" RepoName="webapp-reserva-hotel" \
    Branch="main" GitHubToken="ghp_XXXX" ECRRepoName="webapp-reserva-hotel" \
    ECSClusterName="reserva-hotel-cluster" ECSServiceNameImported="reserva-hotel-app-dev-ecs"
```

> Manual: tras el step_04 la imagen debe existir en ECR (haz `docker build/push` con el
> `Dockerfile`/`buildspec.yml` de la raíz, o corre el pipeline del step_05).

</details>

<details>
<summary><b>Apéndice — Comandos AWS CloudFormation útiles</b></summary>

```bash
# Listar pilas activas
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE

# Recursos / eventos / outputs de una pila
aws cloudformation list-stack-resources --stack-name reserva-hotel-app-dev --output table
aws cloudformation describe-stack-events --stack-name reserva-hotel-app-dev
aws cloudformation describe-stacks --stack-name reserva-hotel-net-dev --query "Stacks[0].Outputs" --output table

# Forzar borrado del repo ECR con imágenes (DeletionPolicy: Retain)
aws ecr delete-repository --repository-name "webapp-reserva-hotel-dev" --force
```

</details>
