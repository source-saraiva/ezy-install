#!/bin/bash

# ===================================================
#   PostgreSQL 17 ezy-install installation script
#   Compatible with Rocky Linux 9
# ===================================================

# === CLEAR TERMINAL ===
clear

# === SET STRICT MODE ===
set -e

# === INPUT VARIABLES ===
PG_VERSION=17
PG_PORT=5432
LOG_FILE="/tmp/postgresql_install.log"

# === INSTALL PGDG REPOSITORY AND DISABLE MODULE ===
echo "Adding PostgreSQL Global Development Group (PGDG) repository..."
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm | tee -a "$LOG_FILE"

echo "Disabling default PostgreSQL module..."
sudo dnf -qy module disable postgresql | tee -a "$LOG_FILE"

# === INSTALL POSTGRESQL SERVER PACKAGE ===
echo "Installing PostgreSQL ${PG_VERSION} server package..."
sudo dnf install -y postgresql${PG_VERSION}-server | tee -a "$LOG_FILE"

# === INITIALISE DATABASE ===
echo "Initialising PostgreSQL ${PG_VERSION} database cluster..."
sudo /usr/pgsql-${PG_VERSION}/bin/postgresql-${PG_VERSION}-setup initdb | tee -a "$LOG_FILE"

# === ENABLE AND START SERVICE ===
echo "Enabling and starting PostgreSQL service..."
sudo systemctl enable --now postgresql-${PG_VERSION} | tee -a "$LOG_FILE"

# === VERIFY INSTALLATION ===
echo "PostgreSQL version installed:"
/usr/pgsql-${PG_VERSION}/bin/psql --version | tee -a "$LOG_FILE"

# === CONFIGURE FIREWALL ===
echo "Opening PostgreSQL port ${PG_PORT}/tcp in the firewall..."
sudo firewall-cmd --permanent --zone=public --add-port=${PG_PORT}/tcp
sudo firewall-cmd --reload

# === SHOW SERVICE STATUS ===
echo "Checking service status..."
sudo systemctl status postgresql-${PG_VERSION} --no-pager

# === SAVE THIS INFORMATION ===
echo
echo "# === Save this information for future reference ==="
echo "PostgreSQL version:              ${PG_VERSION}"
echo "Systemd service name:            postgresql-${PG_VERSION}"
echo "Port configured:                 ${PG_PORT}/tcp"
echo "Firewall port opened:            ${PG_PORT}/tcp"
echo "PostgreSQL binaries location:    /usr/pgsql-${PG_VERSION}/bin/"
echo "Data directory (default):        /var/lib/pgsql/${PG_VERSION}/data"
echo "Installation log:                ${LOG_FILE}"
echo
echo "# === Common commands ==="
echo "To check logs:                   journalctl -u postgresql-${PG_VERSION}"
echo "To stop service:                 sudo systemctl stop postgresql-${PG_VERSION}"
echo "To start service:                sudo systemctl start postgresql-${PG_VERSION}"
echo "To disable service:              sudo systemctl disable postgresql-${PG_VERSION}"
echo "To restart service:              sudo systemctl restart postgresql-${PG_VERSION}"
echo "To connect to DB:                sudo -u postgres /usr/pgsql-${PG_VERSION}/bin/psql"
