#!/bin/bash

# ================================================
#   Zabbix ezy-install installation script
# ================================================

# === CLEAR TERMINAL ===
clear

# === SET STRICT MODE ===
set -e

# === INPUT VARIABLES ===
PG_VERSION=17
PG_PORT=5432
ZBX_DB_NAME="zabbix"
ZBX_DB_USER="zabbix"
ZBX_PORT=10051
ZBX_WEB_PORT=80
LOG_FILE="/tmp/zabbix_postgresql_install.log"

# === PROMPT FOR ZABBIX DB PASSWORD ===
echo
while true; do
  read -s -p "Enter password for database user '${ZBX_DB_USER}' (leave empty to auto-generate): " ZBX_DB_PASSWORD
  echo
  read -s -p "Re-enter password (leave empty to confirm auto-generation): " ZBX_DB_PASSWORD_CONFIRM
  echo
  if [[ "$ZBX_DB_PASSWORD" != "$ZBX_DB_PASSWORD_CONFIRM" ]]; then
    echo "Passwords do not match. Please try again."
  else
    break
  fi
done

if [[ -z "$ZBX_DB_PASSWORD" ]]; then
  echo "No password provided. Generating a secure random password..."
  sudo dnf install -y openssl sudo
  ZBX_DB_PASSWORD=$(openssl rand -base64 16)
fi

# === INSTALL POSTGRESQL ===
echo "Installing PostgreSQL ${PG_VERSION}..."
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm | tee -a "$LOG_FILE"
sudo dnf -qy module disable postgresql | tee -a "$LOG_FILE"
sudo dnf install -y postgresql${PG_VERSION}-server | tee -a "$LOG_FILE"
sudo /usr/pgsql-${PG_VERSION}/bin/postgresql-${PG_VERSION}-setup initdb | tee -a "$LOG_FILE"
sudo systemctl enable --now postgresql-${PG_VERSION} | tee -a "$LOG_FILE"
sleep 5

# === INSTALL ZABBIX ===
echo "Installing Zabbix 7.4 and dependencies..."
sudo dnf install -y epel-release | tee -a "$LOG_FILE"
sudo sed -i '/^\[epel\]/,/^\[/ s/^excludepkgs=.*/excludepkgs=zabbix*/' /etc/yum.repos.d/epel.repo || \
  echo -e "\n[epel]\nexcludepkgs=zabbix*" | sudo tee -a /etc/yum.repos.d/epel.repo

sudo rpm -Uvh https://repo.zabbix.com/zabbix/7.4/release/rocky/9/noarch/zabbix-release-latest-7.4.el9.noarch.rpm | tee -a "$LOG_FILE"
sudo dnf clean all
sudo dnf install -y zabbix-server-pgsql zabbix-web-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent2 | tee -a "$LOG_FILE"
sudo dnf install -y zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql | tee -a "$LOG_FILE"

# === CREATE ZABBIX DATABASE AND USER ===
echo "Creating Zabbix database and user..."
sudo -u postgres psql -c "CREATE USER ${ZBX_DB_USER} WITH ENCRYPTED PASSWORD '${ZBX_DB_PASSWORD}';" | tee -a "$LOG_FILE"
sudo -u postgres createdb -O ${ZBX_DB_USER} ${ZBX_DB_NAME} | tee -a "$LOG_FILE"
zcat /usr/share/zabbix/sql-scripts/postgresql/server.sql.gz | sudo -u ${ZBX_DB_USER} psql ${ZBX_DB_NAME} | tee -a "$LOG_FILE"

# === TEST DATABASE CONNECTION ===
echo "Testing database connection..."
PGPASSWORD="${ZBX_DB_PASSWORD}" psql -U "${ZBX_DB_USER}" -d "${ZBX_DB_NAME}" -h localhost -c "\\conninfo" | tee -a "$LOG_FILE"

# === CONFIGURE ZABBIX SERVER ===
echo "Configuring zabbix_server.conf..."
sudo sed -i "s|^# DBPassword=.*|DBPassword=${ZBX_DB_PASSWORD}|" /etc/zabbix/zabbix_server.conf

# === ENABLE AND START SERVICES ===
echo "Enabling and starting Zabbix services..."
sudo systemctl restart zabbix-server zabbix-agent2 nginx php-fpm
sudo systemctl enable zabbix-server zabbix-agent2 nginx php-fpm

# === CONFIGURE FIREWALL ===
echo "Opening firewall ports for Zabbix and Web access..."
sudo firewall-cmd --permanent --zone=public --add-port=${ZBX_PORT}/tcp
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --reload

# === CONFIGURE SELINUX ===
echo "Adjusting SELinux settings..."
sudo setsebool -P httpd_can_network_connect 1
sudo systemctl restart nginx

# === SHOW SERVICE STATUS ===
echo "Checking service status..."
sudo systemctl status zabbix-server --no-pager
sudo systemctl status nginx --no-pager

# === SAVE THIS INFORMATION ===
SERVER_IP=$(hostname -I | awk '{print $1}')
echo
echo "# === Save this information for future reference ==="
echo "Zabbix version:                  7.4"
echo "Zabbix database name:            ${ZBX_DB_NAME}"
echo "Database user:                   ${ZBX_DB_USER}"
echo "Database password:               ${ZBX_DB_PASSWORD}"
echo "Zabbix server port:              ${ZBX_PORT}/tcp"
echo "Web UI access:                   http://${SERVER_IP}/setup.php"
echo "PostgreSQL port:                 ${PG_PORT}/tcp"
echo "Log file location:               ${LOG_FILE}"
echo "default user (case-sensitive):   Admin"
echo "default pass (case-sensitive):   zabbix"
echo
echo "# === Common commands ==="
echo "Check Zabbix logs:               journalctl -u zabbix-server"
echo "Restart Zabbix:                  sudo systemctl restart zabbix-server"
echo "Restart Zabbix Agent:            sudo systemctl restart zabbix-agent2"
echo "Restart NGINX:                   sudo systemctl restart nginx"
echo "Restart PHP-FPM:                 sudo systemctl restart php-fpm"
echo "Disable a service:               sudo systemctl disable <service-name>"
echo 
echo "# === Manual steps required ==="
echo "1. Open the web URL and complete the setup wizard."
echo "2. Configure HTTPS with a certificate (Let's Encrypt or custom)."
