#!/bin/bash

install_mysql() {
    local MYSQL_ROOT_PASSWORD=$(openssl rand -base64 16)
    local LOG_FILE="/root/mysql_install.log"

    echo -e "\nStarting MySQL installation...\n"

    dnf -y update >> "$LOG_FILE" 2>&1
    dnf -y install https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm >> "$LOG_FILE" 2>&1
    dnf -y module disable mysql >> "$LOG_FILE" 2>&1
    dnf -y install mysql-community-server >> "$LOG_FILE" 2>&1

    systemctl enable --now mysqld
    sleep 5

    TEMP_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')

    # Automate the secure installation process
    mysql_secure_installation <<EOF

$TEMP_PASSWORD
$MYSQL_ROOT_PASSWORD
$MYSQL_ROOT_PASSWORD
y
y
y
y
EOF

    echo -e "\nInstallation complete."
    echo "MySQL root password: $MYSQL_ROOT_PASSWORD"
    echo "Installation log saved at: $LOG_FILE"
}

install_mysql
