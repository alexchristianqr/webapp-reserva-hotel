# scripts/ — Despliegue de la infraestructura AWS

Punto único de despliegue de la infraestructura de **webapp-reserva-hotel** en AWS.
`deploy.sh` orquesta los 5 stacks CloudFormation de `.aws/iac/stacks/` encadenando
automáticamente los *Outputs* de cada stack como parámetros del siguiente, crea el
clúster ECS si no existe y publica la imagen Docker en ECR.

> Especificación detallada de la infraestructura: [`.specs/deployment-aws.md`](../.specs/deployment-aws.md).

## Requisitos

- **AWS CLI v2** configurada (`aws configure` o SSO) con permisos para CloudFormation,
  ECR, ECS, RDS, EC2, ELBv2, IAM, S3, CodeBuild/CodePipeline y Secrets Manager.
- **Docker** en ejecución (necesario para `up` y `image`).
- **bash** (en Windows: Git Bash o WSL).

## Configuración

```bash
cp scripts/deploy.env.example scripts/deploy.env
# edita scripts/deploy.env con tu VPC, subredes, clúster, token de GitHub, etc.
```

`scripts/deploy.env` está excluido de git (contiene el token de GitHub). Las variables
del entorno del shell tienen prioridad sobre el archivo.

## Uso

```bash
# Despliegue completo end-to-end (ECR -> imagen -> red -> RDS -> ECS -> CI/CD)
bash scripts/deploy.sh up

# Desplegar un solo paso
bash scripts/deploy.sh up ecr
bash scripts/deploy.sh up net
bash scripts/deploy.sh up db
bash scripts/deploy.sh up app
bash scripts/deploy.sh up cicd

# Solo construir y publicar la imagen Docker en ECR
bash scripts/deploy.sh image

# Ver los Outputs de los stacks
bash scripts/deploy.sh outputs

# Eliminar toda la infraestructura (orden inverso)
bash scripts/deploy.sh down

# Ayuda
bash scripts/deploy.sh help
```

Al finalizar `up`, el script imprime el DNS del ALB y las URLs de health/login:

```
http://<alb-dns>/api/health   ->  200 {"status":"UP"}
http://<alb-dns>/login.jsp
```

## Orden de despliegue

| Paso  | Stack                       | Crea                                          |
|-------|-----------------------------|-----------------------------------------------|
| ecr   | `reserva-hotel-ecr-<env>`   | Repositorio ECR                               |
| image | —                           | Build + push de la imagen Docker a ECR        |
| net   | `reserva-hotel-net-<env>`   | ALB + Target Group + Security Group           |
| db    | `reserva-hotel-db-<env>`    | RDS MySQL 8 + SG + secret (Secrets Manager)   |
| app   | `reserva-hotel-app-<env>`   | Clúster ECS (si falta) + ECS Fargate Service  |
| cicd  | `reserva-hotel-cicd-<env>`  | CodePipeline + CodeBuild (GitHub)             |

La imagen Docker se publica **antes** del stack `app` para que el servicio ECS arranque
con una imagen válida ya presente en ECR.

## Notas

- El repositorio ECR tiene `DeletionPolicy: Retain`; `down` no lo elimina si conserva
  imágenes. El propio comando imprime cómo forzar su borrado.
- RDS tarda varios minutos en aprovisionarse durante `up`.
- Tras el primer despliegue, los `push` a la rama configurada disparan el pipeline
  (CodePipeline → CodeBuild → ECR → ECS), que reconstruye y redespliega automáticamente.
