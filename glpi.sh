#!/bin/bash

# ================================================
#   GLPI Installer (Apache + MariaDB + PHP)
# ================================================

set -e
clear

# === INPUT VARIABLES ===
LOG_FILE="/tmp/glpi_install.log"
GLPI_VERSION="10.0.19"
GLPI_ARCHIVE="glpi-${GLPI_VERSION}.tgz"
GLPI_URL="https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/${GLPI_ARCHIVE}"
GLPI_TEMP_DIR="/tmp/glpi"
GLPI_DEST="${GLPI_TEMP_DIR}/${GLPI_ARCHIVE}"
INSTALL_DIR="/var/www/html/glpi"
DB_NAME="glpi"
DB_USER="glpi"

# === PROMPT DOMAIN ===
echo
read -p "Please enter the IP or URL you will use to access GLPI (leave blank to use $(hostname -I | awk '{print $1}')): " SERVER_IP
[ -z "$SERVER_IP" ] && SERVER_IP=$(hostname -I | awk '{print $1}')

# === PROMPT FOR PASSWORDS ===
echo
while true; do
  read -s -p "Enter MariaDB root password (leave blank to auto-generate): " MYSQL_ROOT_PASS
  echo
  read -s -p "Re-enter root password (leave empty to confirm auto-generation): " MYSQL_ROOT_PASS_CONFIRM
  echo
  if [[ "$MYSQL_ROOT_PASS" != "$MYSQL_ROOT_PASS_CONFIRM" ]]; then
    echo "Passwords do not match. Try again."
  else
    break
  fi
done

if [[ -z "$MYSQL_ROOT_PASS" ]]; then
  MYSQL_ROOT_PASS=$(openssl rand -base64 16)
  echo "Generated MariaDB root password: $MYSQL_ROOT_PASS"
fi

echo
while true; do
  read -s -p "Enter password for GLPI DB user '$DB_USER' (leave blank to auto-generate): " GLPI_DB_PASS
  echo
  read -s -p "Re-enter password (leave empty to confirm auto-generation): " GLPI_DB_PASS_CONFIRM
  echo
  if [[ "$GLPI_DB_PASS" != "$GLPI_DB_PASS_CONFIRM" ]]; then
    echo "Passwords do not match. Try again."
  else
    break
  fi
done

if [[ -z "$GLPI_DB_PASS" ]]; then
  GLPI_DB_PASS=$(openssl rand -base64 16)
  echo "Generated GLPI DB user password: $GLPI_DB_PASS"
fi

# === FIREWALL ===
echo "Configuring firewall..." | tee -a "$LOG_FILE"
sudo firewall-cmd --add-service={http,https} --permanent
sudo firewall-cmd --reload

# === INSTALL PACKAGES ===
echo "Installing required packages..." | tee -a "$LOG_FILE"
sudo dnf update -y | tee -a "$LOG_FILE"
sudo dnf install -y epel-release wget tar unzip net-tools bzip2 policycoreutils-python-utils | tee -a "$LOG_FILE"
sudo dnf install -y httpd mod_ssl | tee -a "$LOG_FILE"
sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-10.rpm | tee -a "$LOG_FILE"
sudo dnf module reset php -y && sudo dnf module enable php:remi-8.2 -y | tee -a "$LOG_FILE"
sudo dnf install -y php php-{mbstring,mysqli,xml,cli,ldap,openssl,xmlrpc,pecl-apcu,zip,curl,gd,json,session,imap,intl,zlib,redis} | tee -a "$LOG_FILE"
sudo dnf install -y mariadb mariadb-server | tee -a "$LOG_FILE"

# === ENABLE SERVICES ===
echo "Enabling services..." | tee -a "$LOG_FILE"
sudo systemctl enable --now httpd mariadb php-fpm | tee -a "$LOG_FILE"

# === SECURE MARIADB ===
echo "Configuring MariaDB..." | tee -a "$LOG_FILE"
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASS}';"
sudo mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "DROP DATABASE IF EXISTS test;"
sudo mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "FLUSH PRIVILEGES;"
sudo mysql_tzinfo_to_sql /usr/share/zoneinfo | sudo mysql -u root -p"${MYSQL_ROOT_PASS}" mysql

# === CREATE GLPI DB USER ===
echo "Creating GLPI database and user..." | tee -a "$LOG_FILE"
sudo mysql -uroot -p"${MYSQL_ROOT_PASS}" <<EOF
CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE OR REPLACE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${GLPI_DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# === DOWNLOAD GLPI ===
echo "Downloading GLPI..." | tee -a "$LOG_FILE"
mkdir -p "$GLPI_TEMP_DIR"
cd "$GLPI_TEMP_DIR"
if [ ! -f "$GLPI_DEST" ]; then
  wget -O "$GLPI_DEST" "$GLPI_URL"
else
  echo "GLPI archive already exists. Skipping download."
fi
sudo tar -xzf "$GLPI_DEST" -C /var/www/html/

# === INSTALL GLPI DATABASE ===
echo "Installing GLPI database..." | tee -a "$LOG_FILE"
sudo php /var/www/html/glpi/bin/console db:install \
  --db-host=localhost \
  --db-name="$DB_NAME" \
  --db-user="$DB_USER" \
  --db-password="$GLPI_DB_PASS" \
  --no-interaction \
  --lang=pt_PT

# === CONFIGURE APACHE ===
echo "Creating Apache vhost..." | tee -a "$LOG_FILE"
sudo tee /etc/httpd/conf.d/glpi.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName ${SERVER_IP}
    DocumentRoot /var/www/html/glpi/public

    <Directory /var/www/html/glpi/public>
        AllowOverride All
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>

    ErrorLog /var/log/httpd/glpi_error.log
    CustomLog /var/log/httpd/glpi_access.log combined
</VirtualHost>
EOF

# === SET PERMISSIONS ===
echo "Configuring permissions..." | tee -a "$LOG_FILE"
sudo chown -R apache:apache "$INSTALL_DIR"
sudo chmod -R 755 "$INSTALL_DIR"
sudo rm -f "$INSTALL_DIR/install/install.php"

# === ADJUST PHP SETTINGS ===
echo "Adjusting PHP configuration..." | tee -a "$LOG_FILE"
sudo cp /etc/php.ini /etc/php.ini.bak
sudo sed -i 's/^session.cookie_httponly =.*/session.cookie_httponly = 1/' /etc/php.ini
sudo systemctl restart php-fpm

# === SELINUX SETTINGS ===
echo "Adjusting SELinux policies..." | tee -a "$LOG_FILE"
sudo semanage fcontext -a -t httpd_sys_rw_content_t "${INSTALL_DIR}(/.*)?"
sudo restorecon -Rv "$INSTALL_DIR"
sudo setsebool -P httpd_can_sendmail 1
sudo setsebool -P httpd_can_network_connect 1
sudo setsebool -P httpd_can_network_connect_db 1
sudo setsebool -P httpd_mod_auth_ntlm_winbind 1
sudo setsebool -P allow_httpd_mod_auth_ntlm_winbind 1

# Apache restart 
sudo systemctl restart httpd

# === SAVE THIS INFORMATION ===
echo
echo "# === Save this information for future reference ==="
echo "GLPI URL:                        http://${SERVER_IP}/"
echo "MariaDB root password:           ${MYSQL_ROOT_PASS}"
echo "GLPI DB user:                    ${DB_USER}"
echo "GLPI DB password:                ${GLPI_DB_PASS}"
echo "Database name:                   ${DB_NAME}"
echo "Apache configuration:            /etc/httpd/conf.d/glpi.conf"
echo "PHP configuration:               /etc/php.ini"
echo "Log file:                        ${LOG_FILE}"
echo "default user (case-sensitive):   glpi"
echo "default pass (case-sensitive):   glpi"
echo
echo "# === Common commands ==="
echo "To check logs:                   journalctl -u httpd"
echo "To stop/start Apache:            sudo systemctl stop/start httpd"
echo "To stop/start MariaDB:           sudo systemctl stop/start mariadb"
echo
echo "# === Next steps ==="
echo "1. Open the URL above to access GLPI."
echo "2. Configure HTTPS using Let's Encrypt or other method."
echo
