#!/bin/bash
# =====================================================================
# User Data - MySQL (instancia unica, AZ1a) - segun guia oficial del docente
# Instala MySQL 8, crea el usuario de aplicacion (alumno) e importa el
# esquema real de init.sql del repositorio. Alta disponibilidad y
# recuperacion ante desastres se resuelven con AWS Backup (snapshot
# diario), NO con una replica en vivo.
# =====================================================================
exec > >(tee /var/log/user-data.log) 2>&1
set -x

yum update -y

# AL2023 puede no tener el paquete "mysql-server" con ese nombre exacto
# (a veces solo trae MariaDB, compatible con el protocolo MySQL, bajo un
# nombre de paquete distinto). Probamos las opciones mas comunes en orden
# y detectamos el servicio systemd correcto segun cual se instalo.
SVC=""
if yum install -y mysql-server; then
  SVC="mysqld"
elif yum install -y mariadb105-server; then
  SVC="mariadb"
elif yum install -y mariadb-server; then
  SVC="mariadb"
else
  echo "FATAL: no se encontro ningun paquete de MySQL/MariaDB disponible en los repos"
fi
echo "=== Paquete de base de datos instalado, servicio: $SVC ==="

# Configurar MySQL/MariaDB para aceptar conexiones desde la red (no solo
# localhost). Sin esto, escucha solo en 127.0.0.1 y cualquier conexion
# externa recibe ECONNREFUSED, aunque el servicio este corriendo sin errores.
mkdir -p /etc/my.cnf.d
cat > /etc/my.cnf.d/networking.cnf << 'MYCNF'
[mysqld]
bind-address=0.0.0.0
MYCNF

systemctl enable "$SVC"
systemctl start "$SVC"
systemctl status "$SVC" --no-pager || true

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