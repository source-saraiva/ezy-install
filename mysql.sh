#!/bin/bash

install_mariadb() {
    echo -e "\nInstalling openssl...\n"
    sudo dnf -y install openssl expect >> /dev/null 2>&1

    local MARIADB_ROOT_PASSWORD=$(openssl rand -base64 16)
    local LOG_FILE="/tmp/mariadb_install.log"

    echo -e "\nStarting MariaDB installation...\n"

    sudo dnf -y update >> "$LOG_FILE" 2>&1
    sudo dnf -y install mariadb-server >> "$LOG_FILE" 2>&1

    sudo systemctl enable --now mariadb >> "$LOG_FILE" 2>&1
    sleep 5

    # Run mysql_secure_installation non-interactively using expect
    sudo expect <<EOF >> "$LOG_FILE" 2>&1
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

    echo -e "\nInstallation complete."
    echo "MariaDB root password: $MARIADB_ROOT_PASSWORD"
    echo "Installation log saved at: $LOG_FILE"
}

install_mariadb
