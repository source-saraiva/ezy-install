#!/bin/bash

# ================================================
#   Technitium DNS Installer for Rocky Linux 10
# ================================================

set -e

# === Check for sudo availability ===
if ! command -v sudo >/dev/null 2>&1; then
  echo "'sudo' is required but not installed. Please install sudo and try again."
  exit 1
fi

# === Open required firewall ports ===
echo ""
echo "Opening required firewall ports..."

ports=(
  "5380/tcp"    # Web console (HTTP)
  "53443/tcp"   # Web console (HTTPS)
  "53/udp"      # DNS
  "53/tcp"      # DNS
  "853/udp"     # DNS-over-QUIC
  "853/tcp"     # DNS-over-TLS
  "443/udp"     # DNS-over-HTTPS (HTTP/3)
  "443/tcp"     # DNS-over-HTTPS (HTTP/1.1/2)
  "80/tcp"      # HTTP (Let's Encrypt, proxy)
  "67/udp"      # DHCP (optional)
)

for port in "${ports[@]}"; do
  echo "Adding port $port..."
  sudo firewall-cmd --permanent --add-port="$port"
done

echo "Reloading firewalld..."
sudo firewall-cmd --reload

echo ""
echo "Firewall ports configured."

# === ORIGINAL SCRIPT ===
curl -sSL https://download.technitium.com/dns/install.sh | sudo bash
