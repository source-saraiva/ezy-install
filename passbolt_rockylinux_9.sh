#!/usr/bin/bash
# ===========================================================
# Passbolt CE Automated Installer (Rocky Linux 9)
# Author: MikeSierra / Source-Saraiva
# ===========================================================
# Description:
# Automated Passbolt CE installer that:
#  - Collects user input with defaults
#  - Adds domain/IP to /etc/hosts
#  - Generates self-signed SSL certificate (option 2)
#  - Runs passbolt-configure in non-interactive mode
# ===========================================================

set -euo pipefail

echo "==========================================================="
echo "     Passbolt CE Automated Installer for Rocky Linux 9"
echo "==========================================================="

# -----------------------------------------------------------
# 1. COLLECT USER INPUT WITH DEFAULTS
# -----------------------------------------------------------

# --- Detect server IP ---
SERVER_IP=$(hostname -I | awk '{print $1}')
read -p "Enter the domain name (or IP) for Passbolt (leave blank to use ${SERVER_IP}): " PASSBOLT_DOMAIN
[ -z "$PASSBOLT_DOMAIN" ] && PASSBOLT_DOMAIN="$SERVER_IP"

# --- SSL selection ---
echo ""
echo "Choose SSL setup mode:"
echo "1) Automatic (Let's Encrypt)"
echo "2) Self-signed certificate"
echo "3) None (HTTP only)"
read -rp "Select option [1-3]: " SSL_OPTION



# --- Database selection ---
#echo ""
#echo "Choose database setup:"
#echo "1) Local MariaDB (installed by Passbolt)"
#echo "2) Remote or preinstalled database"
#read -rp "Select option [1-2]: " DB_OPTION



# --- Execution ---
SSL_CERT_PATH="/etc/ssl/certs/passbolt_selfsigned.crt"
SSL_KEY_PATH="/etc/ssl/certs/passbolt_selfsigned.key"

if [[ "$SSL_OPTION" == "1" ]]; then
    SSL_MODE="auto"
    read -rp "Enter email for Let's Encrypt registration: " SSL_EMAIL
elif [[ "$SSL_OPTION" == "2" ]]; then
    SSL_MODE="manual"
    echo ">>> Generating self-signed SSL certificate..."
    sudo mkdir -p /etc/ssl/certs
    sudo openssl req -x509 -nodes -days 825 \
        -newkey rsa:4096 \
        -keyout "$SSL_KEY_PATH" \
        -out "$SSL_CERT_PATH" \
        -subj "/C=XA/ST=Mars/L=Mars/O=Source-Saraiva/OU=IT/CN=$PASSBOLT_DOMAIN"
    echo "Self-signed certificate generated:"
    echo " - Certificate: $SSL_CERT_PATH"
    echo " - Key:         $SSL_KEY_PATH"
else
    SSL_MODE="none"
fi

DB_OPTION=1
DB_NAME="passboltdb"
DB_USER="passbolt"
DB_PASS=$(openssl rand -base64 16)
DB_ROOT_PASS=$(openssl rand -base64 16)
DB_MODE="local"

#if [[ "$DB_OPTION" == "1" ]]; then
#    read -rp "Enter MariaDB root password (leave empty to auto-generate): " DB_ROOT_PASS
#    [ -z "$DB_ROOT_PASS" ] && DB_ROOT_PASS=$(openssl rand -base64 16)
    #read -rp "Enter Passbolt database name [default: passboltdb]: " DB_NAME
    #[ -z "$DB_NAME" ] && DB_NAME="passboltdb"
    #read -rp "Enter Passbolt database username [default: passbolt]: " DB_USER
    #[ -z "$DB_USER" ] && DB_USER="passbolt"
#    read -rp "Enter password for Passbolt database user [default: passbolt123]: " DB_PASS
#    [ -z "$DB_PASS" ] && DB_PASS=$(openssl rand -base64 16)
#    DB_MODE="local"
#else
#    DB_MODE="remote"
#fi

# -----------------------------------------------------------
# 2. ADD HOSTS ENTRY
# -----------------------------------------------------------
echo ""
echo ">>> Updating /etc/hosts to allow local domain resolution..."
if ! grep -q "$PASSBOLT_DOMAIN" /etc/hosts; then
    echo "$SERVER_IP   $PASSBOLT_DOMAIN" | sudo tee -a /etc/hosts >/dev/null
    echo "Added: $SERVER_IP   $PASSBOLT_DOMAIN"
else
    echo "Host entry already exists in /etc/hosts."
fi

# -----------------------------------------------------------
# 3. INSTALL REPOSITORY AND PASSBOLT PACKAGE
# -----------------------------------------------------------
echo ""
echo ">>> Downloading and verifying Passbolt repository setup..."
curl -LO "https://download.passbolt.com/ce/installer/passbolt-repo-setup.ce.sh"
curl -LO "https://github.com/passbolt/passbolt-dep-scripts/releases/latest/download/passbolt-ce-SHA512SUM.txt"

if sha512sum -c passbolt-ce-SHA512SUM.txt | grep -q "OK"; then
    echo "Checksum OK. Proceeding..."
    sudo bash ./passbolt-repo-setup.ce.sh
else
    echo "Bad checksum. Aborting."
    rm -f passbolt-repo-setup.ce.sh
    exit 1
fi

echo ""
echo ">>> Installing Passbolt CE Server..."
sudo dnf install -y passbolt-ce-server

# -----------------------------------------------------------
# 4. BUILD CONFIGURATION COMMAND
# -----------------------------------------------------------
CONFIG_CMD="sudo /usr/local/bin/passbolt-configure"

# Database section
if [[ "$DB_MODE" == "local" ]]; then
    CONFIG_CMD+=" -P \"$DB_ROOT_PASS\" -u \"$DB_USER\" -p \"$DB_PASS\" -d \"$DB_NAME\""
else
    CONFIG_CMD+=" -r"
fi

# Hostname
CONFIG_CMD+=" -H \"$PASSBOLT_DOMAIN\""

# SSL section
if [[ "$SSL_MODE" == "auto" ]]; then
    CONFIG_CMD+=" -a -m \"$SSL_EMAIL\""
elif [[ "$SSL_MODE" == "manual" ]]; then
    CONFIG_CMD+=" -c \"$SSL_CERT_PATH\" -k \"$SSL_KEY_PATH\""
else
    CONFIG_CMD+=" -n"
fi

# -----------------------------------------------------------
# 5. RUN CONFIGURATION
# -----------------------------------------------------------
echo ""
echo ">>> Running Passbolt configuration..."
eval "$CONFIG_CMD"

# -----------------------------------------------------------
# 6. SAVE THIS INFORMATION
# -----------------------------------------------------------
echo ""
echo "==========================================================="
echo "                 SAVE THIS INFORMATION"
echo "==========================================================="
echo "Passbolt domain/IP:   $PASSBOLT_DOMAIN"
echo "Server IP:            $SERVER_IP"
if [[ "$SSL_MODE" == "auto" ]]; then
    echo "SSL: Let's Encrypt (email: $SSL_EMAIL)"
elif [[ "$SSL_MODE" == "manual" ]]; then
    echo "SSL: Self-signed certificate"
    echo "Cert file: $SSL_CERT_PATH"
    echo "Key file:  $SSL_KEY_PATH"
else
    echo "SSL: None (HTTP only)"
fi
if [[ "$DB_MODE" == "local" ]]; then
    echo "Database type: Local MariaDB"
    echo "DB name:       $DB_NAME"
    echo "DB user:       $DB_USER"
    echo "DB password:   $DB_PASS"
    echo "Root password: $DB_ROOT_PASS"
else
    echo "Database type: Remote/Existing"
fi
echo "==========================================================="
echo "Installation complete!"
echo "Access Passbolt at: https://${PASSBOLT_DOMAIN}"
echo "==========================================================="

# End of Script
