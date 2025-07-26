#!/bin/bash

# === Check for sudo/root ===

if [ "$(id -u)" -ne 0 ]; then
  if ! command -v sudo &>/dev/null; then
    echo "This script requires root or sudo access. Please run as root or install sudo."
    exit 1
  fi
  SUDO="sudo"
else
  SUDO=""
fi

# === Ask all required inputs ===

read -p "Enter the port for Beszel Hub [8090]: " PORT
PORT=${PORT:-8090}

read -p "Enter GitHub proxy URL (leave blank to use default https://ghfast.top/): " GITHUB_PROXY_URL
GITHUB_PROXY_URL=${GITHUB_PROXY_URL:-"https://ghfast.top/"}
[[ "$GITHUB_PROXY_URL" != */ ]] && GITHUB_PROXY_URL="${GITHUB_PROXY_URL}/"

# === Install dependencies ===

echo "Installing required packages (tar, curl, firewalld)..."
$SUDO dnf install -y tar curl firewalld || {
  echo "Dependency installation failed."
  exit 1
}

# === Start and enable firewalld ===

echo "Ensuring firewalld is running..."
$SUDO systemctl enable --now firewalld

# === Add firewall rule ===

echo "Opening port ${PORT}/tcp in the firewall..."
$SUDO firewall-cmd --permanent --add-port=${PORT}/tcp
$SUDO firewall-cmd --reload

# === Create beszel user ===

echo "Ensuring system user 'beszel' exists..."
if ! id beszel &>/dev/null; then
  $SUDO useradd -r -s /usr/sbin/nologin beszel
  echo "User 'beszel' created."
fi

# === Download Beszel ===

ARCH=$(uname -m)
case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64) ARCH="arm64" ;;
  armv7l) ARCH="arm" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

OS=$(uname -s)
TARBALL="beszel_${OS}_${ARCH}.tar.gz"
TMP_PATH="/tmp/${TARBALL}"
INSTALL_DIR="/opt/beszel"

echo "Downloading from: ${GITHUB_PROXY_URL}https://github.com/henrygd/beszel/releases/latest/download/${TARBALL}"
curl -sL "${GITHUB_PROXY_URL}https://github.com/henrygd/beszel/releases/latest/download/${TARBALL}" -o "$TMP_PATH"

# === Install Beszel ===

echo "Extracting and installing Beszel..."
$SUDO mkdir -p "${INSTALL_DIR}/beszel_data"
$SUDO tar -xzf "$TMP_PATH" -C "$INSTALL_DIR"
$SUDO chmod +x "${INSTALL_DIR}/beszel"
$SUDO chown -R beszel:beszel "$INSTALL_DIR"

# === Create systemd unit ===

echo "Creating systemd service..."
$SUDO tee /etc/systemd/system/beszel-hub.service > /dev/null <<EOF
[Unit]
Description=Beszel Hub Service
After=network.target

[Service]
ExecStart=${INSTALL_DIR}/beszel serve --http 0.0.0.0:${PORT}
WorkingDirectory=${INSTALL_DIR}
User=beszel
Group=beszel
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# === Enable and start ===

echo "Starting beszel-hub.service..."
$SUDO systemctl daemon-reload
$SUDO systemctl enable --now beszel-hub.service

# === Status Check ===

echo "Waiting for Beszel Hub to start..."
sleep 2

if $SUDO systemctl is-active --quiet beszel-hub.service; then
  echo "✅ Beszel Hub is running on port ${PORT}"
else
  echo "❌ Failed to start Beszel Hub. Use: journalctl -u beszel-hub.service"
  exit 1
fi

# === Save this information ===

echo
echo " # === Save this information securely ==="
echo "Beszel Hub installed in:         ${INSTALL_DIR}"
echo "Systemd service name:            beszel-hub.service"
echo "Runs as user:                    beszel"
echo "Port configured:                 ${PORT}"
echo "Firewall port opened:            ${PORT}/tcp"
echo "GitHub proxy used:               ${GITHUB_PROXY_URL}"
echo "To check logs:                   journalctl -u beszel-hub.service"
echo "To stop service:                 sudo systemctl stop beszel-hub"
echo "To disable service:              sudo systemctl disable beszel-hub"
echo "To remove:                       sudo rm -rf ${INSTALL_DIR} /etc/systemd/system/beszel-hub.service"
echo 
