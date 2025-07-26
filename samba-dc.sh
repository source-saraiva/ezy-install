#!/bin/bash

# === Samba AD DC Installation Script for Rocky Linux 10 ===
# Author: source-saraiva
# This script installs and configures Samba as an Active Directory Domain Controller.

# Exit if any command fails
set -e

# Check if user is root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root."
  exit 1
fi

# Check if IP address is static
check_static_ip() {
  local iface=$(ip route | grep default | awk '{print $5}')
  if grep -q 'dhcp' "/etc/sysconfig/network-scripts/ifcfg-$iface"; then
    echo "Your IP address is assigned via DHCP. Please configure a static IP before proceeding."
    echo "Edit /etc/sysconfig/network-scripts/ifcfg-$iface and set BOOTPROTO=static"
    exit 1
  fi
}

# Install dependencies
install_dependencies() {
  dnf install -y epel-release
  dnf update -y
  dnf install -y samba samba-dc samba-client samba-common \
    bind-utils krb5-workstation policycoreutils-python-utils \
    expect net-tools
}

# Prompt user for configuration
prompt_config() {
  echo
  read -p "Create new domain forest or join existing? [new/join]: " DOMAIN_MODE

  DOMAIN_MODE=$(echo "$DOMAIN_MODE" | tr '[:upper:]' '[:lower:]')
  if [[ "$DOMAIN_MODE" != "new" && "$DOMAIN_MODE" != "join" ]]; then
    echo "Invalid option. Choose 'new' or 'join'."
    exit 1
  fi

  DEFAULT_REALM="$(hostname -d 2>/dev/null || echo example.local)"
  DEFAULT_NETBIOS="$(hostname -s | tr '[:lower:]' '[:upper:]')"

  read -p "Enter FQDN for the domain (e.g., example.local) [${DEFAULT_REALM}]: " REALM
  REALM=${REALM:-$DEFAULT_REALM}

  read -p "Enter NETBIOS domain name (e.g., EXAMPLE) [${DEFAULT_NETBIOS}]: " NETBIOS
  NETBIOS=${NETBIOS:-$DEFAULT_NETBIOS}

  DEFAULT_HOSTNAME_FQDN="$(hostname -f 2>/dev/null || echo dc1.$REALM)"
  read -p "Enter FQDN for this host (e.g., dc1.example.local) [${DEFAULT_HOSTNAME_FQDN}]: " HOSTNAME_FQDN
  HOSTNAME_FQDN=${HOSTNAME_FQDN:-$DEFAULT_HOSTNAME_FQDN}

  read -s -p "Set Administrator password: " ADMIN_PASS
  echo
}

# Provision new domain
provision_domain() {
  echo "Provisioning new domain..."
  samba-tool domain provision \
    --use-rfc2307 \
    --realm="$REALM" \
    --domain="$NETBIOS" \
    --server-role=dc \
    --dns-backend=SAMBA_INTERNAL \
    --adminpass="$ADMIN_PASS"
}

# Join existing domain
join_domain() {
  echo "Joining existing domain..."
  samba-tool domain join "$REALM" DC \
    --dns-backend=SAMBA_INTERNAL \
    --username=Administrator \
    --password="$ADMIN_PASS"
}

# Configure system to use Samba
configure_system() {
  # Backup and replace smb.conf
  mv -f /etc/samba/smb.conf /etc/samba/smb.conf.bak
  cp /var/lib/samba/private/krb5.conf /etc/krb5.conf

  # Enable and start Samba AD DC
  systemctl enable --now samba
}

# Show final instructions
show_summary() {
  echo
  echo "Samba AD DC setup is complete."
  echo "Realm: $REALM"
  echo "NetBIOS: $NETBIOS"
  echo "Hostname: $HOSTNAME_FQDN"
  echo "You may now join Windows clients to the domain."
  echo "Use the Administrator account with the password you provided."
  echo
}

### MAIN EXECUTION ###

check_static_ip
install_dependencies
prompt_config

if [ "$DOMAIN_MODE" = "new" ]; then
  provision_domain
else
  join_domain
fi

configure_system
show_summary


