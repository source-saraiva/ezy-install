#!/bin/bash

# ===============================
#   Beszel Hub Installation Script
# ===============================

# === CLEAR TERMINAL ===
clear

# === INPUT VARIABLES ===
version=0.12.1
PORT=8090
GITHUB_PROXY_URL="https://ghfast.top/"    # Optional proxy to speed up GitHub downloads


# === PROMPT ===
#SERVER_IP=$(hostname -I | awk '{print $1}')
echo
echo "Please enter the IP you will use to access beszel (leave blank to use $(hostname -I | awk '{print $1}')):"
read -r SERVER_IP
[ -z "$SERVER_IP" ] && SERVER_IP=$(hostname -I | awk '{print $1}')
echo
echo "Please enter the URL you will use to access beszel (leave blank to use $(hostname -f)):"
read -r ACCESS_URL
[ -z "$ACCESS_URL" ] && ACCESS_URL=$(hostname -f)






# === INSTALL REQUIRED TOOLS ===
echo "Installing required packages..."
sudo dnf install -y tar curl


# === ENSURE BESZEL SYSTEM USER EXISTS ===
echo "Ensuring system user 'beszel' exists..."
if ! id beszel &>/dev/null; then
  sudo useradd -r -s /usr/sbin/nologin beszel
  echo "User 'beszel' created."
else
  echo "User 'beszel' already exists."
fi

# === DETECT SYSTEM ARCHITECTURE ===
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

# === DOWNLOAD AND EXTRACT BESZEL ===
echo "Downloading Beszel ${version} (${OS}/${ARCH})..."
curl -L "${GITHUB_PROXY_URL}https://github.com/henrygd/beszel/releases/latest/download/${TARBALL}" -o "$TMP_PATH"

echo "Extracting Beszel to ${INSTALL_DIR}..."
sudo mkdir -p "${INSTALL_DIR}/beszel_data"
sudo tar -xzf "$TMP_PATH" -C "$INSTALL_DIR"
sudo chmod +x "${INSTALL_DIR}/beszel"
sudo chown -R beszel:beszel "$INSTALL_DIR"

# === CREATE SYSTEMD SERVICE ===
echo "Creating systemd service 'beszel-hub.service'..."

sudo tee /etc/systemd/system/beszel-hub.service > /dev/null <<EOF
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

# === ENABLE AND START THE SERVICE ===
echo "Enabling and starting beszel-hub.service..."
sudo systemctl daemon-reload
sudo systemctl enable --now beszel-hub.service

# === SHOW SERVICE STATUS ===
echo "Checking service status..."
sudo systemctl status beszel-hub.service --no-pager

# === INTEGRATE WITH NGNIX ===
sudo dnf install nginx -y
sudo systemctl enable --now nginx

# === DATA FOR ACCESS URL ===


cat <<EOF | sudo tee /etc/nginx/conf.d/beszel.conf
server {
    listen 80;
    server_name ${SERVER_IP} ${ACCESS_URL};

    access_log /var/log/nginx/beszel_access.log;
    error_log /var/log/nginx/beszel_error.log;

    # Redirect HTTP to HTTPS (if SSL set up)
    # return 301 https://$server_name$request_uri;

    location / {
        proxy_pass http://localhost:8090;
        proxy_buffering off;
        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        client_max_body_size 0;

        # Optional timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # Optional buffering settings for large requests
        proxy_buffer_size   128k;
        proxy_buffers   4 256k;
        proxy_busy_buffers_size 256k;
    }
}

EOF



# === CONFIGURE SELINUX ===
sudo setsebool -P httpd_can_network_connect 1
sudo nginx -t
sudo systemctl enable --now nginx


# === CONFIGURE FIREWALL ===
echo "Opening port ${PORT}/tcp in the firewall permanently..."
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --reload

# === FORCE LOADING ===
sudo systemctl restart nginx

# === SAVE THIS INFORMATION ===
echo
echo "# === Save this information for future reference ==="
echo "Beszel Hub installed in:         ${INSTALL_DIR}"
echo "Systemd service name:            beszel-hub.service"
echo "Runs as user:                    beszel"
echo "Port configured:                 ${PORT}"
echo "Firewall port opened:            ${PORT}/tcp"
echo "GitHub proxy used:               ${GITHUB_PROXY_URL}"
echo "Web UI access:                   http://${SERVER_IP} or http://${ACCESS_URL}"
echo "Ensure port 45876 is open on all client devices"
echo
echo "# === Common commands ==="
echo "To check logs:                   journalctl -u beszel-hub.service"
echo "To stop service:                 sudo systemctl stop beszel-hub"
echo "To start service:                sudo systemctl start beszel-hub"
echo "To disable service:              sudo systemctl disable beszel-hub"
echo "To restart service:              sudo systemctl restart beszel-hub"
echo
echo "# === Manual steps required ==="
echo "1. Open the web URL and create a new user to access beszel."
echo "2. Configure HTTPS with a certificate (Let's Encrypt or custom)."
echo
