#!/bin/bash
# =====================================================================
# User Data - MySQL (instancia unica, AZ1a) - segun guia oficial del docente
# Instala MySQL 8, crea el usuario de aplicacion (alumno) e importa el
# esquema real de init.sql del repositorio. Alta disponibilidad y
# recuperacion ante desastres se resuelven con AWS Backup (snapshot
# diario), NO con una replica en vivo.
# =====================================================================
exec > /var/log/user-data.log 2>&1
set -x

yum update -y
yum install -y mysql-server
systemctl enable mysqld
systemctl start mysqld

mysql -uroot -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${db_root_password}';" 2>/dev/null || \
mysql -uroot -p"${db_root_password}" -e "SELECT 1;" 2>/dev/null || true

MYSQL="mysql -uroot -p${db_root_password}"

$MYSQL -e "CREATE DATABASE IF NOT EXISTS ${db_name};"
$MYSQL -e "CREATE USER IF NOT EXISTS '${db_user}'@'%' IDENTIFIED BY '${db_password}';"
$MYSQL -e "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'%';"
$MYSQL -e "FLUSH PRIVILEGES;"

# Importar el esquema real del proyecto (tabla productos + 5 registros de ejemplo)
cat > /tmp/init.sql << 'INITSQL'
${init_sql_content}
INITSQL
$MYSQL < /tmp/init.sql

echo "=== MySQL listo (BD ${db_name} poblada, usuario ${db_user} creado) ==="
