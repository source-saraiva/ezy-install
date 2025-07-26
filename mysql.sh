#!/bin/bash

install_mariadb() {
    # Ensure required tools are installed
    sudo dnf -y install openssl expect

    echo
    echo "=== MariaDB Installation Script for Rocky Linux 10 ==="
    echo

    # Prompt the user for a root password
    read -s -p "Enter desired MariaDB root password (leave empty to auto-generate): " MARIADB_ROOT_PASSWORD
    echo

    # Generate password if not provided
    if [[ -z "$MARIADB_ROOT_PASSWORD" ]]; then
        echo "No password entered. Generating a secure random password..."
        MARIADB_ROOT_PASSWORD=$(openssl rand -base64 16)
    fi

    local LOG_FILE="/tmp/mariadb_install.log"

    echo
    echo "Starting MariaDB installation..."
    echo "All actions will be logged to: $LOG_FILE"
    echo

    # Update system and install MariaDB
    sudo dnf -y update | tee -a "$LOG_FILE"
    sudo dnf -y install mariadb-server | tee -a "$LOG_FILE"

    # Enable and start the MariaDB service
    sudo systemctl enable --now mariadb | tee -a "$LOG_FILE"
    sleep 5

    # Run secure installation using expect
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
    echo "=== Installation complete ==="
    echo
    echo " # === Save this information securely ==="
    echo
    echo "MariaDB root password: $MARIADB_ROOT_PASSWORD"
    echo "Installation log saved at: $LOG_FILE"
    echo
}

install_mariadb
