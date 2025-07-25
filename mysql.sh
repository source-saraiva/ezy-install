#!/bin/bash

install_mariadb() {
    sudo dnf -y install openssl expect

    local MARIADB_ROOT_PASSWORD=$(openssl rand -base64 16)
    local LOG_FILE="/tmp/mariadb_install.log"

    echo
    echo "Starting MariaDB installation on Rocky Linux 10..."
    echo "Log file: $LOG_FILE"
    echo

    # Update system and install MariaDB
    sudo dnf -y update | tee -a "$LOG_FILE"
    sudo dnf -y install mariadb-server | tee -a "$LOG_FILE"

    sudo systemctl enable --now mariadb | tee -a "$LOG_FILE"
    sleep 5

    # Run mysql_secure_installation using expect
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

    echo
    echo "Installation complete."
    echo "MariaDB root password: $MARIADB_ROOT_PASSWORD"
    echo "Log saved at: $LOG_FILE"
}

install_mariadb

