#!/usr/bin/env bash
#
# deploy.sh — Despliegue end-to-end de la infraestructura AWS de webapp-reserva-hotel.
#
# Orquesta los 5 stacks CloudFormation de .aws/iac/stacks/ (ECR, Networking, RDS,
# ECS Fargate, CI/CD) desde un único comando, encadenando automáticamente los
# Outputs de un stack como parámetros del siguiente. Además crea el clúster ECS si
# no existe y construye/publica la imagen Docker en ECR para que el primer
# despliegue del servicio arranque con una imagen válida.
#
# Requisitos: AWS CLI v2 (configurada), Docker (para `image`/`up`), bash.
#
# Uso:
#   scripts/deploy.sh up [ecr|image|net|db|app|cicd]   Despliega todo (o un paso)
#   scripts/deploy.sh down                              Elimina todos los stacks (orden inverso)
#   scripts/deploy.sh image                             Solo build + push de la imagen Docker
#   scripts/deploy.sh outputs                           Muestra los Outputs de los stacks
#   scripts/deploy.sh help                              Esta ayuda
#
# Variables: se cargan desde scripts/deploy.env (ver scripts/deploy.env.example).
# También pueden venir del entorno; el entorno tiene prioridad sobre el archivo.

set -euo pipefail

# --------------------------------------------------------------------------------------
# Rutas base
# --------------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
STACKS_DIR="${ROOT_DIR}/.aws/iac/stacks"
ENV_FILE="${ENV_FILE:-${SCRIPT_DIR}/deploy.env}"

# --------------------------------------------------------------------------------------
# Logging
# --------------------------------------------------------------------------------------
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_INFO=$'\033[0;36m'; C_OK=$'\033[0;32m'
  C_WARN=$'\033[0;33m'; C_ERR=$'\033[0;31m'; C_STEP=$'\033[1;35m'
else
  C_RESET=""; C_INFO=""; C_OK=""; C_WARN=""; C_ERR=""; C_STEP=""
fi

info()  { printf '%s[info]%s  %s\n'  "${C_INFO}" "${C_RESET}" "$*"; }
ok()    { printf '%s[ ok ]%s  %s\n'  "${C_OK}"   "${C_RESET}" "$*"; }
warn()  { printf '%s[warn]%s  %s\n'  "${C_WARN}" "${C_RESET}" "$*" >&2; }
step()  { printf '\n%s===> %s%s\n'   "${C_STEP}" "$*" "${C_RESET}"; }
die()   { printf '%s[err ]%s  %s\n'  "${C_ERR}"  "${C_RESET}" "$*" >&2; exit 1; }

# --------------------------------------------------------------------------------------
# Carga de variables
# --------------------------------------------------------------------------------------
load_env() {
  if [[ -f "${ENV_FILE}" ]]; then
    info "Cargando variables de ${ENV_FILE}"
    set -a
    # shellcheck disable=SC1090
    source "${ENV_FILE}"
    set +a
  else
    warn "No existe ${ENV_FILE}. Usando solo variables de entorno y defaults."
    warn "Crea uno con: cp scripts/deploy.env.example scripts/deploy.env"
  fi

  # Defaults (no obligatorios)
  AWS_REGION="${AWS_REGION:-us-east-1}"
  AWS_PROFILE="${AWS_PROFILE:-}"
  ENV="${ENV:-dev}"
  STACK_PREFIX="${STACK_PREFIX:-reserva-hotel}"
  REPO_NAME="${REPO_NAME:-webapp-reserva-hotel}"
  IMAGE_TAG="${IMAGE_TAG:-latest}"
  LISTENER_PORT="${LISTENER_PORT:-80}"
  CONTAINER_PORT="${CONTAINER_PORT:-8080}"
  DB_NAME="${DB_NAME:-db_hotel}"
  DB_USERNAME="${DB_USERNAME:-admin}"
  DB_INSTANCE_CLASS="${DB_INSTANCE_CLASS:-db.t3.micro}"
  ALLOCATED_STORAGE="${ALLOCATED_STORAGE:-20}"
  ECS_CLUSTER_NAME="${ECS_CLUSTER_NAME:-${STACK_PREFIX}-cluster}"
  CPU="${CPU:-512}"
  MEMORY="${MEMORY:-1024}"
  DESIRED_COUNT="${DESIRED_COUNT:-1}"
  GITHUB_OWNER="${GITHUB_OWNER:-alexchristianqr}"
  GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
  GITHUB_TOKEN="${GITHUB_TOKEN:-}"

  # Las subredes privadas y de BD por defecto reutilizan las públicas si no se definen.
  PRIVATE_SUBNET_IDS="${PRIVATE_SUBNET_IDS:-${PUBLIC_SUBNET_IDS:-}}"
  DB_SUBNET_IDS="${DB_SUBNET_IDS:-${PRIVATE_SUBNET_IDS:-}}"

  # Nombres de stack derivados
  STACK_ECR="${STACK_PREFIX}-ecr-${ENV}"
  STACK_NET="${STACK_PREFIX}-net-${ENV}"
  STACK_DB="${STACK_PREFIX}-db-${ENV}"
  STACK_APP="${STACK_PREFIX}-app-${ENV}"
  STACK_CICD="${STACK_PREFIX}-cicd-${ENV}"

  # Repo ECR efectivo (la plantilla añade el sufijo de entorno)
  ECR_REPO="${REPO_NAME}-${ENV}"
}

require_vars() {
  local missing=()
  local v
  for v in "$@"; do
    if [[ -z "${!v:-}" ]]; then
      missing+=("${v}")
    fi
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    die "Faltan variables obligatorias: ${missing[*]} (revisa ${ENV_FILE})"
  fi
}

# --------------------------------------------------------------------------------------
# Helpers de AWS CLI
# --------------------------------------------------------------------------------------
aws_args() {
  # Imprime los flags comunes (region/profile) para componer comandos.
  local out=(--region "${AWS_REGION}")
  if [[ -n "${AWS_PROFILE}" ]]; then
    out+=(--profile "${AWS_PROFILE}")
  fi
  printf '%s\n' "${out[@]}"
}

# Wrapper sobre `aws` que inyecta region/profile.
awsx() {
  local common=()
  mapfile -t common < <(aws_args)
  aws "${common[@]}" "$@"
}

preflight() {
  command -v aws >/dev/null 2>&1 || die "AWS CLI no está instalado (se requiere AWS CLI v2)."
  step "Preflight"
  info "Verificando credenciales AWS (sts get-caller-identity)..."
  ACCOUNT_ID="$(awsx sts get-caller-identity --query Account --output text)" \
    || die "No se pudieron obtener credenciales AWS. Configura 'aws configure'."
  ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
  ok "Cuenta AWS: ${ACCOUNT_ID} | Región: ${AWS_REGION} | Entorno: ${ENV}"
}

# Despliega una plantilla CloudFormation de forma idempotente.
# Uso: cfn_deploy <stack-name> <template-rel-path> <ParamKey=Value>...
cfn_deploy() {
  local stack="$1"; shift
  local template="$1"; shift
  step "Desplegando stack: ${stack}"
  info "Plantilla: ${template}"
  awsx cloudformation deploy \
    --stack-name "${stack}" \
    --template-file "${STACKS_DIR}/${template}" \
    --capabilities CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset \
    --parameter-overrides "$@"
  ok "Stack ${stack} desplegado."
}

# Lee un Output de un stack. Uso: cfn_output <stack> <OutputKey>
cfn_output() {
  local stack="$1"; local key="$2"
  awsx cloudformation describe-stacks \
    --stack-name "${stack}" \
    --query "Stacks[0].Outputs[?OutputKey=='${key}'].OutputValue" \
    --output text
}

stack_exists() {
  awsx cloudformation describe-stacks --stack-name "$1" >/dev/null 2>&1
}

# --------------------------------------------------------------------------------------
# Pasos de despliegue
# --------------------------------------------------------------------------------------
deploy_ecr() {
  cfn_deploy "${STACK_ECR}" "step_01/ecr-stack.yml" \
    "Env=${ENV}" \
    "RepoName=${REPO_NAME}"
}

build_and_push_image() {
  command -v docker >/dev/null 2>&1 || die "Docker no está instalado (necesario para build/push de la imagen)."
  : "${ACCOUNT_ID:?Ejecuta preflight antes de build_and_push_image}"
  step "Construyendo y publicando imagen Docker en ECR"
  local image_uri="${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"
  local latest_uri="${ECR_REGISTRY}/${ECR_REPO}:latest"

  info "Login a ECR (${ECR_REGISTRY})..."
  awsx ecr get-login-password | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

  info "docker build -> ${image_uri}"
  docker build -t "${image_uri}" -t "${latest_uri}" "${ROOT_DIR}"

  info "docker push..."
  docker push "${image_uri}"
  docker push "${latest_uri}"
  ok "Imagen publicada: ${image_uri}"
}

deploy_net() {
  require_vars VPC_ID PUBLIC_SUBNET_IDS
  cfn_deploy "${STACK_NET}" "step_02/net-stack.yml" \
    "Env=${ENV}" \
    "VpcId=${VPC_ID}" \
    "PublicSubnetIds=${PUBLIC_SUBNET_IDS}" \
    "ListenerPort=${LISTENER_PORT}" \
    "ContainerPort=${CONTAINER_PORT}"
}

deploy_db() {
  require_vars VPC_ID DB_SUBNET_IDS
  local app_sg
  app_sg="$(cfn_output "${STACK_NET}" ExportedSecurityGroup)"
  [[ -n "${app_sg}" && "${app_sg}" != "None" ]] || die "No se obtuvo ExportedSecurityGroup de ${STACK_NET}. Despliega 'net' primero."
  info "Security Group de la app (del net-stack): ${app_sg}"
  cfn_deploy "${STACK_DB}" "step_03/db-stack.yml" \
    "Env=${ENV}" \
    "VpcId=${VPC_ID}" \
    "DbSubnetIds=${DB_SUBNET_IDS}" \
    "AppSecurityGroupImported=${app_sg}" \
    "DBName=${DB_NAME}" \
    "DBUsername=${DB_USERNAME}" \
    "DBInstanceClass=${DB_INSTANCE_CLASS}" \
    "AllocatedStorage=${ALLOCATED_STORAGE}"
}

ensure_ecs_cluster() {
  step "Asegurando clúster ECS: ${ECS_CLUSTER_NAME}"
  local status
  status="$(awsx ecs describe-clusters --clusters "${ECS_CLUSTER_NAME}" \
    --query "clusters[0].status" --output text 2>/dev/null || echo "None")"
  if [[ "${status}" == "ACTIVE" ]]; then
    ok "El clúster ya existe y está ACTIVE."
  else
    info "Creando clúster ECS..."
    awsx ecs create-cluster --cluster-name "${ECS_CLUSTER_NAME}" >/dev/null
    ok "Clúster creado."
  fi
  ECS_CLUSTER_ARN="$(awsx ecs describe-clusters --clusters "${ECS_CLUSTER_NAME}" \
    --query "clusters[0].clusterArn" --output text)"
  [[ -n "${ECS_CLUSTER_ARN}" && "${ECS_CLUSTER_ARN}" != "None" ]] || die "No se pudo resolver el ARN del clúster ECS."
  info "ARN del clúster: ${ECS_CLUSTER_ARN}"
}

deploy_app() {
  require_vars PRIVATE_SUBNET_IDS
  : "${ECS_CLUSTER_ARN:?Ejecuta ensure_ecs_cluster antes de deploy_app}"
  local sg tg db_endpoint db_secret
  sg="$(cfn_output "${STACK_NET}" ExportedSecurityGroup)"
  tg="$(cfn_output "${STACK_NET}" ExportedTargetGroupArn)"
  db_endpoint="$(cfn_output "${STACK_DB}" ExportedDbEndpoint)"
  db_secret="$(cfn_output "${STACK_DB}" ExportedDbSecretArn)"
  for pair in "ExportedSecurityGroup=${sg}" "ExportedTargetGroupArn=${tg}" \
              "ExportedDbEndpoint=${db_endpoint}" "ExportedDbSecretArn=${db_secret}"; do
    local val="${pair#*=}"
    [[ -n "${val}" && "${val}" != "None" ]] || die "Output faltante: ${pair%%=*}. Despliega net y db primero."
  done
  cfn_deploy "${STACK_APP}" "step_04/app-stack.yml" \
    "Env=${ENV}" \
    "ECSClusterArn=${ECS_CLUSTER_ARN}" \
    "PrivateSubnetIds=${PRIVATE_SUBNET_IDS}" \
    "Cpu=${CPU}" \
    "Memory=${MEMORY}" \
    "RepoName=${REPO_NAME}" \
    "ImageTag=${IMAGE_TAG}" \
    "ContainerPort=${CONTAINER_PORT}" \
    "DesiredCount=${DESIRED_COUNT}" \
    "SecurityGroupImported=${sg}" \
    "TargetGroupArnImported=${tg}" \
    "DbEndpointImported=${db_endpoint}" \
    "DbName=${DB_NAME}" \
    "DbSecretArnImported=${db_secret}"
}

deploy_cicd() {
  require_vars GITHUB_TOKEN
  local svc
  svc="$(cfn_output "${STACK_APP}" ExportedECSServiceName)"
  [[ -n "${svc}" && "${svc}" != "None" ]] || die "No se obtuvo ExportedECSServiceName de ${STACK_APP}. Despliega 'app' primero."
  cfn_deploy "${STACK_CICD}" "step_05/cicd-stack.yml" \
    "Env=${ENV}" \
    "RepoOwner=${GITHUB_OWNER}" \
    "RepoName=${REPO_NAME}" \
    "Branch=${GITHUB_BRANCH}" \
    "GitHubToken=${GITHUB_TOKEN}" \
    "ECRRepoName=${REPO_NAME}" \
    "ECSClusterName=${ECS_CLUSTER_NAME}" \
    "ECSServiceNameImported=${svc}"
}

print_summary() {
  step "Resumen del despliegue"
  local dns
  dns="$(cfn_output "${STACK_NET}" ExportedLoadBalancerDnsName 2>/dev/null || echo "")"
  if [[ -n "${dns}" && "${dns}" != "None" ]]; then
    ok "ALB DNS:      http://${dns}"
    ok "Health check: http://${dns}/api/health"
    ok "Login:        http://${dns}/login.jsp"
  else
    warn "No se pudo resolver el DNS del ALB (¿se desplegó 'net'?)."
  fi
}

# --------------------------------------------------------------------------------------
# Comandos de alto nivel
# --------------------------------------------------------------------------------------
cmd_up() {
  local only="${1:-}"
  preflight
  case "${only}" in
    "")
      deploy_ecr
      build_and_push_image
      deploy_net
      deploy_db
      ensure_ecs_cluster
      deploy_app
      deploy_cicd
      print_summary
      ;;
    ecr)   deploy_ecr ;;
    image) build_and_push_image ;;
    net)   deploy_net ;;
    db)    deploy_db ;;
    app)   ensure_ecs_cluster; deploy_app ;;
    cicd)  deploy_cicd ;;
    *)     die "Paso desconocido: '${only}'. Usa: ecr|image|net|db|app|cicd" ;;
  esac
  ok "Listo."
}

cmd_image() {
  preflight
  build_and_push_image
}

delete_stack() {
  local stack="$1"
  if stack_exists "${stack}"; then
    step "Eliminando stack: ${stack}"
    awsx cloudformation delete-stack --stack-name "${stack}"
    info "Esperando a que se elimine ${stack}..."
    awsx cloudformation wait stack-delete-complete --stack-name "${stack}" \
      && ok "Eliminado: ${stack}" \
      || warn "No se pudo confirmar la eliminación de ${stack} (revisa la consola)."
  else
    info "El stack ${stack} no existe; se omite."
  fi
}

cmd_down() {
  preflight
  warn "Se eliminarán los stacks de '${ENV}' en orden inverso."
  # Orden inverso: cicd -> app -> db -> net -> ecr
  delete_stack "${STACK_CICD}"
  delete_stack "${STACK_APP}"
  delete_stack "${STACK_DB}"
  delete_stack "${STACK_NET}"
  delete_stack "${STACK_ECR}"
  warn "Nota: el repositorio ECR tiene DeletionPolicy: Retain y puede conservarse con imágenes."
  warn "Para forzar su borrado: aws ecr delete-repository --repository-name ${ECR_REPO} --force ${AWS_PROFILE:+--profile ${AWS_PROFILE}} --region ${AWS_REGION}"
  ok "Teardown completado."
}

cmd_outputs() {
  preflight
  local s k
  for s in "${STACK_ECR}" "${STACK_NET}" "${STACK_DB}" "${STACK_APP}" "${STACK_CICD}"; do
    step "Outputs de ${s}"
    if stack_exists "${s}"; then
      awsx cloudformation describe-stacks --stack-name "${s}" \
        --query "Stacks[0].Outputs" --output table || true
    else
      info "El stack ${s} no existe todavía."
    fi
  done
}

usage() {
  cat <<EOF
deploy.sh — Despliegue end-to-end de la infraestructura AWS de webapp-reserva-hotel.

USO:
  scripts/deploy.sh up [ecr|image|net|db|app|cicd]
        Despliega toda la infra (sin argumento extra) o solo el paso indicado.
        Orden completo: ECR -> imagen Docker -> Networking -> RDS -> clúster ECS
        -> App (ECS Fargate) -> CI/CD. Encadena los Outputs automáticamente.

  scripts/deploy.sh image
        Solo construye y publica la imagen Docker en ECR.

  scripts/deploy.sh outputs
        Muestra los Outputs de los 5 stacks.

  scripts/deploy.sh down
        Elimina todos los stacks en orden inverso (cicd -> app -> db -> net -> ecr).

  scripts/deploy.sh help
        Muestra esta ayuda.

CONFIGURACIÓN:
  Copia scripts/deploy.env.example a scripts/deploy.env y rellena las variables.
  El entorno del shell tiene prioridad sobre el archivo. Variables principales:
  AWS_REGION, ENV, VPC_ID, PUBLIC_SUBNET_IDS, PRIVATE_SUBNET_IDS, DB_SUBNET_IDS,
  ECS_CLUSTER_NAME, GITHUB_OWNER, GITHUB_TOKEN.

REQUISITOS:
  - AWS CLI v2 configurada (aws configure / SSO).
  - Docker en ejecución (para 'up' y 'image').
EOF
}

main() {
  local cmd="${1:-help}"
  case "${cmd}" in
    up)      load_env; shift || true; cmd_up "${1:-}" ;;
    image)   load_env; cmd_image ;;
    down)    load_env; cmd_down ;;
    outputs) load_env; cmd_outputs ;;
    help|-h|--help) usage ;;
    *)       usage; die "Comando desconocido: '${cmd}'" ;;
  esac
}

main "$@"
