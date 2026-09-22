#!/bin/bash
# =====================================================================
# Construye y sube las 5 imagenes Docker del proyecto a Amazon ECR.
# Rutas: microservicioFrontend/ y microserviciosBackend/ estan en la
# RAIZ del repo (junto a /infra, /scripts, /sql), no dentro de /src.
#
# Requiere: Terraform ya aplicado (los 5 repos ECR deben existir),
# credenciales de AWS Academy exportadas, Docker corriendo localmente.
#
# Uso (desde la raiz del repo):
#   ./scripts/ecr-push.sh
# =====================================================================
set -e

REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "=== Account: $ACCOUNT_ID | Region: $REGION ==="
aws ecr get-login-password --region "$REGION" | \
  docker login --username AWS --password-stdin "$REGISTRY"

declare -A SERVICES=(
  ["freshbox-frontend"]="./microservicioFrontend"
  ["freshbox-get-products"]="./microserviciosBackend/get-products"
  ["freshbox-create-product"]="./microserviciosBackend/create-product"
  ["freshbox-update-product"]="./microserviciosBackend/update-product"
  ["freshbox-delete-product"]="./microserviciosBackend/delete-product"
)

for name in "${!SERVICES[@]}"; do
  path="${SERVICES[$name]}"
  image="${REGISTRY}/${name}:latest"

  echo ""
  echo "=== Construyendo $name (ARM64, compatible con t4g.small) ==="
  docker buildx build --platform linux/arm64 -t "$image" "$path" --load

  echo "=== Subiendo $name a ECR ==="
  docker push "$image"
done

echo ""
echo "Listo. Las 5 imagenes fueron subidas a ECR."
echo "Ahora refresca el Auto Scaling Group para que las instancias App las descarguen:"
echo "  aws autoscaling start-instance-refresh --auto-scaling-group-name \$(terraform -chdir=infra output -raw asg_name)"
