#!/bin/bash

# ===========================================
#   MariaDB ezy-install installation script
# ===========================================

# === CLEAR TERMINAL ===
clear

# === SET STRICT MODE ===
set -e

# === INPUT VARIABLES ===
MARIADB_PORT=3306
LOG_FILE="/tmp/mariadb_install.log"

# === PROMPT FOR ROOT PASSWORD ===

echo

while true; do
  read -s -p "Enter desired MariaDB root password (leave empty to auto-generate): " MARIADB_ROOT_PASSWORD
  echo
  read -s -p "Re-enter password (leave empty to confirm auto-generation): " MARIADB_ROOT_PASSWORD_CONFIRM
  echo

  if [[ "$MARIADB_ROOT_PASSWORD" != "$MARIADB_ROOT_PASSWORD_CONFIRM" ]]; then
    echo "Passwords do not match. Please try again."
  else
    break
  fi
done

if [[ -z "$MARIADB_ROOT_PASSWORD" ]]; then
  echo "No password provided. Generating a secure random password..."
  MARIADB_ROOT_PASSWORD=$(openssl rand -base64 16)
fi

# === INSTALL DEPENDENCIES ===
echo "Installing required packages..."
sudo dnf install -y openssl expect mariadb-server | tee -a "$LOG_FILE"

# === ENABLE AND START MARIADB SERVICE ===
echo "Enabling and starting mariadb.service..."
sudo systemctl enable --now mariadb | tee -a "$LOG_FILE"
sleep 5

# === CONFIGURE MARIADB SECURELY USING EXPECT ===
echo "Configuring MariaDB securely..."
sudo expect <<EOF | tee -a "$LOG_FILE"
spawn mysql_secure_installation

expect "Enter current password for root (enter for none):"
send "\r"

expect "Switch to unix_socket authentication"
send "n\r"

expect "Set root password?"
send "y\r"

expect "New password:"
send "$MARIADB_ROOT_PASSWORD\r"

expect "Re-enter new password:"
send "$MARIADB_ROOT_PASSWORD\r"

expect "Remove anonymous users?"
send "y\r"

expect "Disallow root login remotely?"
send "y\r"

expect "Remove test database and access to it?"
send "y\r"

expect "Reload privilege tables now?"
send "y\r"

expect eof
EOF

# === CONFIGURE FIREWALL ===
echo "Opening MariaDB port ${MARIADB_PORT}/tcp in the firewall..."
sudo firewall-cmd --permanent --zone=public --add-port=${MARIADB_PORT}/tcp
sudo firewall-cmd --reload

# === SHOW SERVICE STATUS ===
echo "Checking service status..."
sudo systemctl status mariadb --no-pager

# === SAVE THIS INFORMATION ===
echo
echo "# === Save this information for future reference ==="
echo "MariaDB installed and configured."
echo "Systemd service name:            mariadb"
echo "Port configured:                 ${MARIADB_PORT}/tcp"
echo "Firewall port opened:            ${MARIADB_PORT}/tcp"
echo "MariaDB root password:           ${MARIADB_ROOT_PASSWORD}"
echo "Installation log:                ${LOG_FILE}"
echo
echo "# === Common commands ==="
echo "To check logs:                   journalctl -u mariadb"
echo "To stop service:                 sudo systemctl stop mariadb"
echo "To start service:                sudo systemctl start mariadb"
echo "To disable service:              sudo systemctl disable mariadb"
echo "To restart service:              sudo systemctl restart mariadb"
echo
