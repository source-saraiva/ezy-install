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

# (o resto do script é igual ao que enviaste, sem alterações necessárias)
