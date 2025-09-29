#!/bin/bash

# ================================================
#   Nextcloud ezy-install installation script
#   Adapted for Rocky Linux 9
# ================================================

set -e
clear

# === INPUT VARIABLES ===
LOG_FILE="/tmp/nextcloud_install.log"
NC_DB_NAME="nextcloud"
NC_DB_USER="nextcloud"
SERVER_IP=$(hostname -I | awk '{print $1}')

# === PROMPT DOMAIN ===
echo
read -p "Please enter the IP or URL you will use to access Nextcloud (leave blank to use $(hostname -I | awk '{print $1}')): " SERVER_IP
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
  read -s -p "Enter password for Nextcloud DB user '$NC_DB_USER' (leave blank to auto-generate): " SOLUTIONS_DB_PASS
  echo
  read -s -p "Re-enter password (leave empty to confirm auto-generation): " SOLUTIONS_DB_PASS_CONFIRM
  echo
  if [[ "$SOLUTIONS_DB_PASS" != "$SOLUTIONS_DB_PASS_CONFIRM" ]]; then
    echo "Passwords do not match. Try again."
  else
    break
  fi
done

if [[ -z "$SOLUTIONS_DB_PASS" ]]; then
  SOLUTIONS_DB_PASS=$(openssl rand -base64 16)
  echo "Generated Nextcloud DB user password: $SOLUTIONS_DB_PASS"
fi

# === FIREWALL ===
echo "Configuring firewall..." | tee -a "$LOG_FILE"
sudo firewall-cmd --add-service={http,https} --permanent
sudo firewall-cmd --reload

# === ENABLE CRB REPO ===
echo "Enabling CodeReady Builder (CRB) repository..." | tee -a "$LOG_FILE"
sudo dnf config-manager --set-enabled crb | tee -a "$LOG_FILE"

# === INSTALL PACKAGES ===
echo "Installing required packages..." | tee -a "$LOG_FILE"
sudo dnf install -y epel-release unzip wget curl | tee -a "$LOG_FILE"
sudo dnf install -y setroubleshoot-server policycoreutils-python-utils | tee -a "$LOG_FILE"
sudo dnf install -y httpd httpd-tools | tee -a "$LOG_FILE"
sudo dnf install -y php php-cli php-fpm php-mysqlnd php-zip php-devel \
  php-gd php-json php-mbstring php-curl php-xml php-pear php-bcmath \
  php-opcache php-intl php-ldap | tee -a "$LOG_FILE"
sudo dnf install -y mariadb mariadb-server mariadb-devel | tee -a "$LOG_FILE"

# === ENABLE SERVICES ===
echo "Enabling and starting services..." | tee -a "$LOG_FILE"
sudo systemctl enable --now httpd mariadb php-fpm | tee -a "$LOG_FILE"

# === SECURE MARIADB ===
echo "Configuring MariaDB..." | tee -a "$LOG_FILE"
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASS}';"
sudo mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "DROP DATABASE IF EXISTS test;"
sudo mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "FLUSH PRIVILEGES;"

# === CREATE NEXTCLOUD DB ===
echo "Creating Nextcloud database and user..." | tee -a "$LOG_FILE"
sudo mysql -uroot -p"${MYSQL_ROOT_PASS}" <<EOF
CREATE DATABASE ${NC_DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE OR REPLACE USER '${NC_DB_USER}'@'localhost' IDENTIFIED BY '${SOLUTIONS_DB_PASS}';
GRANT ALL PRIVILEGES ON ${NC_DB_NAME}.* TO '${NC_DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# === TUNE MARIADB ===
sudo tee /etc/my.cnf.d/nextcloud.cnf > /dev/null <<EOF
[mysqld]
innodb_buffer_pool_size = 128M
innodb_log_file_size = 32M
query_cache_type = 1
query_cache_size = 16M
tmp_table_size = 32M
max_heap_table_size = 32M
max_connections = 500
thread_cache_size = 50
open_files_limit = 65535
table_definition_cache = 4096
table_open_cache = 4096
EOF

sudo systemctl restart mariadb

# === DOWNLOAD NEXTCLOUD ===
echo "Downloading Nextcloud..." | tee -a "$LOG_FILE"
cd /tmp
sudo mkdir -p nextcloud && cd nextcloud
if [ ! -f latest.zip ]; then
    sudo wget https://download.nextcloud.com/server/releases/latest.zip
else
    echo ">> latest.zip already exists, skipping download."
fi
sudo unzip latest.zip -d /var/www/html/
sudo rm latest.zip

# === SET PERMISSIONS ===
echo "Configuring permissions..." | tee -a "$LOG_FILE"
sudo mkdir -p /var/www/nextcloud-data
sudo chown -R apache:apache /var/www/html/nextcloud /var/www/nextcloud-data
sudo find /var/www/html/nextcloud/ -type d -exec chmod 755 {} \;
sudo find /var/www/html/nextcloud/ -type f -exec chmod 644 {} \;
sudo chmod +x /var/www/html/nextcloud/occ
sudo chmod 775 /var/www/html/nextcloud/config /var/www/html/nextcloud/apps /var/www/nextcloud-data

# === CONFIGURE APACHE ===
echo "Creating Apache config..." | tee -a "$LOG_FILE"
sudo tee /etc/httpd/conf.d/nextcloud.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName ${SERVER_IP}
    DocumentRoot /var/www/html/nextcloud

    <Directory /var/www/html/nextcloud>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
        SetEnv HOME /var/www/html/nextcloud
        SetEnv HTTP_HOME /var/www/html/nextcloud
    </Directory>

    # === Security Headers ===
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "DENY"
    Header always set X-XSS-Protection "1; mode=block"

    ErrorLog /var/log/httpd/nextcloud_error.log
    CustomLog /var/log/httpd/nextcloud_access.log combined
</VirtualHost>
EOF

sudo httpd -t && sudo systemctl restart httpd

# === PHP SETTINGS ===
echo "Adjusting PHP configuration..." | tee -a "$LOG_FILE"
sudo cp /etc/php.ini /etc/php.ini.bak
sudo sed -i 's/^memory_limit = .*/memory_limit = 512M/' /etc/php.ini
sudo sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 512M/' /etc/php.ini
sudo sed -i 's/^post_max_size = .*/post_max_size = 512M/' /etc/php.ini
sudo sed -i 's/^max_execution_time = .*/max_execution_time = 300/' /etc/php.ini
sudo sed -i 's/^max_input_time = .*/max_input_time = 300/' /etc/php.ini
sudo sed -i 's@^;date.timezone =@date.timezone = "UTC"@' /etc/php.ini

# === OPCACHE ===
echo "Tuning OPCache..." | tee -a "$LOG_FILE"
sudo cp /etc/php.d/10-opcache.ini /etc/php.d/10-opcache.ini.bak
sudo sed -i 's/^;opcache.enable=.*/opcache.enable=1/' /etc/php.d/10-opcache.ini
sudo sed -i 's/^;opcache.memory_consumption=.*/opcache.memory_consumption=128/' /etc/php.d/10-opcache.ini
sudo sed -i 's/^;opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=10/' /etc/php.d/10-opcache.ini
sudo sed -i 's/^;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=4000/' /etc/php.d/10-opcache.ini
sudo sed -i 's/^;opcache.revalidate_freq=.*/opcache.revalidate_freq=2/' /etc/php.d/10-opcache.ini
echo "opcache.fast_shutdown=1" | sudo tee -a /etc/php.d/10-opcache.ini

# === SELINUX SETTINGS ===
echo "Adjusting SELinux contexts..." | tee -a "$LOG_FILE"
sudo semanage fcontext -a -t httpd_exec_t "/var/www/html/nextcloud/occ"
sudo semanage fcontext -a -t httpd_config_t "/var/www/html/nextcloud/config(/.*)?"
sudo semanage fcontext -a -t httpd_config_t "/var/www/nextcloud-data(/.*)?"
#sudo semanage fcontext -a -t httpd_rw_content_t "/var/www/html/nextcloud/data(/.*)?"
sudo semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html/nextcloud/data(/.*)?"
#sudo semanage fcontext -a -t httpd_rw_content_t "/var/www/html/nextcloud/config(/.*)?"
sudo semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html/nextcloud/config(/.*)?"
#sudo semanage fcontext -a -t httpd_rw_content_t "/var/www/html/nextcloud/apps(/.*)?"
sudo semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html/nextcloud/apps(/.*)?"
#sudo semanage fcontext -a -t httpd_rw_content_t "/var/www/nextcloud-data(/.*)?"
sudo semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/nextcloud-data(/.*)?"
sudo restorecon -Rv /var/www/html/nextcloud/ /var/www/nextcloud-data/
sudo setsebool -P httpd_can_network_connect 1
sudo setsebool -P httpd_can_network_connect_db 1
sudo setsebool -P httpd_execmem 1
sudo setsebool -P httpd_unified 1

sudo systemctl restart php-fpm httpd

# === SAVE THIS INFORMATION ===
echo
echo "# === Save this information for future reference ==="
echo "Nextcloud URL:                  http://${SERVER_IP}/"
echo "MariaDB root password:          ${MYSQL_ROOT_PASS}"
echo "Nextcloud DB user:              ${NC_DB_USER}"
echo "Nextcloud DB password:          ${SOLUTIONS_DB_PASS}"
echo "Database name:                  ${NC_DB_NAME}"
echo "Apache configuration:           /etc/httpd/conf.d/nextcloud.conf"
echo "PHP configuration:              /etc/php.ini"
echo "OPcache configuration:          /etc/php.d/10-opcache.ini"
echo "Log file:                       ${LOG_FILE}"
echo
echo "# === Common commands ==="
echo "To check logs:                   journalctl -u httpd"
echo "To check status:                 sudo systemctl stop httpd"
echo "To stop service:                 sudo systemctl stop httpd"
echo "To start service:                sudo systemctl start httpd"
echo "To disable service:              sudo systemctl disable httpd"
echo
echo "# === Next steps ==="
echo "1. Open the URL above to complete the Nextcloud web setup wizard."
echo "2. Configure HTTPS with Let's Encrypt or another certificate provider."
echo
