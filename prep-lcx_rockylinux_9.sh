#!/bin/bash

# prep-lcx_rocky9.sh : Prepare Rocky Linux 9 container for troubleshooting and template conversion
# Author: source-saraiva
# Repository: https://github.com/source-saraiva/ezy-install
# Description:
#   This script prepares a Rocky Linux 9 container/VM by:
#     - Installing troubleshooting tools
#     - Cleaning SSH keys, logs, caches
#     - Resetting networking leases
#     - Making the system ready to be converted into a template

# ==============================
# === USER CONFIRMATION STEP ===
# ==============================

echo "=========================================================="
echo " Prepare Rocky Linux 9 Container for Template Conversion"
echo "=========================================================="
echo
read -p "This script will install packages and clean the system. Continue? (y/n): " choice
if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
  echo "Aborted."
  exit 1
fi

# ==============================
# === ENABLE REPOSITORIES ===
# ==============================

echo "[Step 1/6] Enabling repositories..."
sudo /usr/bin/crb enable
sudo dnf install -y epel-release

# ==============================
# === INSTALL TROUBLESHOOTING TOOLS ===
# ==============================

echo "[Step 2/6] Installing troubleshooting tools..."
sudo dnf install -y \
  wget \
  tcpdump \
  bind-utils \
  ncurses-term \
  htop \
  net-tools \
  telnet \
  traceroute \
  iputils \
  curl \
  jq \
  vim \
  less \
  NetworkManager NetworkManager-tui \
  nano \
  man \
  strace \
  lsof \
  sysstat \
  iotop \
  atop \
  iproute \
  whois \
  ethtool \
  nmap \
  ncurses \
  mtr \
  firewalld \
  openssh-server \
  nc

echo "[Step 2/6] Updating system..."
sudo dnf update -y && sudo dnf upgrade -y

echo "[Verification] Listing key installed packages..."
rpm -qa | egrep "tcpdump|htop|nmap|NetworkManager|ncurses"

# ==============================
# === CLEAN SSH KEYS ===
# ==============================

echo "[Step 3/6] Cleaning SSH keys..."
rm -f ~/.ssh/known_hosts
rm -f /root/.ssh/known_hosts
rm -f /etc/ssh/ssh_host_*
rm -f ~/.ssh/authorized_keys
rm -f /root/.ssh/authorized_keys

# ==============================
# === CLEAN SYSTEM LOGS ===
# ==============================

echo "[Step 4/6] Cleaning system logs..."
sudo journalctl --rotate
sudo journalctl --vacuum-time=1s
sudo rm -rf /var/log/*
sudo mkdir -p /var/log
sudo chmod 755 /var/log

# ==============================
# === RESET NETWORK LEASES ===
# ==============================

echo "[Step 5/6] Resetting network leases..."
sudo rm -f /var/lib/NetworkManager/*lease*
sudo rm -f /var/lib/dhclient/*

# ==============================
# === CLEAN CACHES & HISTORY ===
# ==============================

echo "[Step 6/6] Cleaning caches and history..."
sudo dnf clean all
sudo rm -rf /var/cache/dnf
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
history -c
cat /dev/null > ~/.bash_history
cat /dev/null > /root/.bash_history
rm -f /var/log/bash_history


# ==============================
# === ADD PERMIT ROOT LOGIN ===
# ==============================
echo "PermitRootLogin yes" | sudo tee /etc/ssh/sshd_config.d/permit_root.conf


# ==============================
# === FINAL INSTRUCTIONS ===
# ==============================

echo
echo "=========================================================="
echo " Save this information"
echo "=========================================================="
echo "The container has been cleaned and is now ready to be"
echo "converted into a template. Recommended next step:"
echo
echo "Note: SSH Root login is permitted"
echo "Change 'PermitRootLogin no' on file: /etc/ssh/sshd_config.d/permit_root.conf"
echo "  shutdown now"
echo
echo "After shutdown, convert this VM/container into a template."
echo "=========================================================="
