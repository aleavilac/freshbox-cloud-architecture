#!/bin/bash
# =====================================================================
# User Data - Instancia de la capa App (EC2 + Docker, ARM/t4g)
# Adaptado de los scripts oficiales del docente:
#   user-data-ec2.sh (instalacion) + deploy-containers.sh (despliegue)
# Diferencia: aqui DB_HOST se inyecta dinamicamente desde Terraform
# (en el script original era un valor "10.0.2.X" a editar a mano).
# =====================================================================
exec > /var/log/user-data.log 2>&1
set -x

yum update -y
yum install -y docker telnet mysql
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-linux-aarch64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# --- Login a ECR usando el rol de instancia (LabInstanceProfile, sin credenciales estaticas) ---
aws ecr get-login-password --region ${aws_region} | \
  docker login --username AWS --password-stdin ${ecr_registry}

# --- Red Docker compartida: permite que nginx (frontend) llegue a cada
#     backend por su nombre de contenedor (reverse proxy interno) ---
docker network create freshbox-net 2>/dev/null || true

# --- Descargar las 5 imagenes ---
docker pull ${ecr_registry}/freshbox-frontend:latest
docker pull ${ecr_registry}/freshbox-get-products:latest
docker pull ${ecr_registry}/freshbox-create-product:latest
docker pull ${ecr_registry}/freshbox-update-product:latest
docker pull ${ecr_registry}/freshbox-delete-product:latest

# --- Limpiar contenedores previos (idempotencia ante reinicio del user-data) ---
docker stop freshbox-frontend freshbox-get-products freshbox-create-product freshbox-update-product freshbox-delete-product 2>/dev/null || true
docker rm freshbox-frontend freshbox-get-products freshbox-create-product freshbox-update-product freshbox-delete-product 2>/dev/null || true

# --- Levantar los 4 backends ---
docker run -d --name freshbox-get-products --network freshbox-net --restart unless-stopped \
  -p 3001:3001 -e DB_HOST="${db_host}" -e DB_USER="${db_user}" -e DB_PASS="${db_password}" -e DB_NAME="${db_name}" -e PORT=3001 \
  ${ecr_registry}/freshbox-get-products:latest

docker run -d --name freshbox-create-product --network freshbox-net --restart unless-stopped \
  -p 3002:3002 -e DB_HOST="${db_host}" -e DB_USER="${db_user}" -e DB_PASS="${db_password}" -e DB_NAME="${db_name}" -e PORT=3002 \
  ${ecr_registry}/freshbox-create-product:latest

docker run -d --name freshbox-update-product --network freshbox-net --restart unless-stopped \
  -p 3003:3003 -e DB_HOST="${db_host}" -e DB_USER="${db_user}" -e DB_PASS="${db_password}" -e DB_NAME="${db_name}" -e PORT=3003 \
  ${ecr_registry}/freshbox-update-product:latest

docker run -d --name freshbox-delete-product --network freshbox-net --restart unless-stopped \
  -p 3004:3004 -e DB_HOST="${db_host}" -e DB_USER="${db_user}" -e DB_PASS="${db_password}" -e DB_NAME="${db_name}" -e PORT=3004 \
  ${ecr_registry}/freshbox-delete-product:latest

# --- Levantar el frontend (nginx expone 80 y reverse-proxea /api/products hacia los backends) ---
docker run -d --name freshbox-frontend --network freshbox-net --restart unless-stopped \
  -p 80:80 ${ecr_registry}/freshbox-frontend:latest

echo "=== FreshBox App tier listo ==="
docker ps
