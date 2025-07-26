#!/bin/bash

clear 

install_mariadb() {
    # Install required packages
    sudo dnf -y install openssl expect

    echo
    echo "=== MariaDB Installation Script for Rocky Linux 10 ==="
    echo

    # Prompt the user for a password
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

    # If no password was entered, generate one
    if [[ -z "$MARIADB_ROOT_PASSWORD" ]]; then
        echo "No password provided. Generating a secure random password..."
        MARIADB_ROOT_PASSWORD=$(openssl rand -base64 16)
    fi

    local LOG_FILE="/tmp/mariadb_install.log"

    echo
    echo "Starting MariaDB installation..."
    echo "Installation logs will be saved to: $LOG_FILE"
    echo

    # Update system and install MariaDB server
    sudo dnf -y update | tee -a "$LOG_FILE"
    sudo dnf -y install mariadb-server | tee -a "$LOG_FILE"

    # Enable and start the MariaDB service
    sudo systemctl enable --now mariadb | tee -a "$LOG_FILE"
    sleep 5

    # Automate mysql_secure_installation using expect
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
    echo "installation completed successfully"
    echo
    echo " # === Save this information securely ==="
    echo
    echo "MariaDB root password: $MARIADB_ROOT_PASSWORD"
    echo "Log file location: $LOG_FILE"
    echo
}

install_mariadb
