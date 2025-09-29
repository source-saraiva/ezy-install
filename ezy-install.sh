#!/bin/bash

# ezy-install: Wrapper installer with Rocky Linux version detection
# Author: source-saraiva
# Repository: https://github.com/source-saraiva/ezy-install

CURRENT_VERSION="0.2.1"
REPO_OWNER="source-saraiva"
REPO_NAME="ezy-install"
BRANCH="main"
RAW_BASE_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH"
API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents"

# === DISPLAY HELP ===
show_help() {
  echo "Usage: ezy-install <script-name>"
  echo
  echo "Options:"
  echo " -h or --help       Show this help message"
  echo " -l or --list       List available installer scripts from GitHub"
  echo
  echo "Example:"
  echo "  ezy-install glpi"
  echo
  echo "Description:"
  echo "  ezy-install auto-detects Rocky Linux version (9 or 10) and runs"
  echo "  the corresponding script (e.g., glpi_rocky9.sh or glpi_rocky10.sh)."
  echo
}

# === SELF UPDATE CHECK ===
self_update() {
  echo "Checking for ezy-install updates..."
  echo "Local version: $CURRENT_VERSION"

  REMOTE_SCRIPT=$(curl -fsSL "$RAW_BASE_URL/ezy-install.sh")
  if [ -z "$REMOTE_SCRIPT" ]; then
    echo "Warning: Could not fetch remote script. Skipping update check."
    return
  fi

  REMOTE_VERSION=$(echo "$REMOTE_SCRIPT" | grep '^CURRENT_VERSION=' | cut -d '"' -f2)

  if [ -z "$REMOTE_VERSION" ]; then
    echo "Warning: Remote version not found. Skipping update check."
    return
  fi

  echo "Remote version:  $REMOTE_VERSION"

  if [[ "$REMOTE_VERSION" != "$CURRENT_VERSION" ]]; then
    echo "New version available: $REMOTE_VERSION"
    echo "Downloading new version..."

    TMP_FILE=$(mktemp /tmp/ezy-install.XXXXXX)

    if curl -fsSL "$RAW_BASE_URL/ezy-install.sh" -o "$TMP_FILE"; then
      chmod +x "$TMP_FILE"

      # Write update instructions to temporary script
      UPDATER_SCRIPT=$(mktemp /tmp/ezy-updater.XXXXXX.sh)

      cat <<EOF > "$UPDATER_SCRIPT"
#!/bin/bash
echo "Updater: Installing new version to /usr/local/bin/ezy-install"
sudo mv "$TMP_FILE" /usr/local/bin/ezy-install
sudo chmod +x /usr/local/bin/ezy-install
echo "Updater: Updated to version $REMOTE_VERSION."
echo "Updater: Please re-run your previous ezy-install command."
EOF

      chmod +x "$UPDATER_SCRIPT"

      echo "Updater: Launching interactive updater..."
      exec bash "$UPDATER_SCRIPT"
    else
      echo "Error downloading update. Aborting."
      rm -f "$TMP_FILE"
    fi
  fi
}

# === LIST AVAILABLE SCRIPTS ===
list_available_scripts() {
  echo "Fetching available scripts from GitHub..."

  scripts=$(curl -fsSL "$API_URL" \
    | grep '"name":' \
    | grep '.sh' \
    | cut -d '"' -f 4 \
    | grep -v '^ezy-install.sh$' \
    | sed -E 's/_rocky[0-9]+\.sh$/.sh/' \
    | sed 's/\.sh$//' \
    | sort -u)

  if [ -z "$scripts" ]; then
    echo "No scripts found or unable to reach GitHub."
    exit 1
  fi

  echo
  echo "==========================================================="
  echo "                       Available Scripts"
  echo "==========================================================="
  echo "$scripts" | column
  echo
}

# === DETECT ROCKY VERSION ===
detect_rocky_version() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    rocky_version=$(echo "$VERSION_ID" | cut -d '.' -f1)
  else
    echo "Cannot detect OS version (missing /etc/os-release)."
    exit 1
  fi
  echo "$rocky_version"
}

# === RUN INSTALLER SCRIPT ===
run_script() {
  base_name="$1"
  rocky_version=$(detect_rocky_version)

  target_script="${base_name}_rocky${rocky_version}.sh"
  tmp_file=$(mktemp "/tmp/${target_script}.XXXXXX.sh")
  script_url="$RAW_BASE_URL/${target_script}"

  echo "Detected Rocky Linux $rocky_version"
  echo "Downloading script: $target_script"
  if ! curl -fsSL "$script_url" -o "$tmp_file"; then
    echo "Error: Failed to download script '$target_script'."
    exit 1
  fi

  chmod +x "$tmp_file"
  echo "Executing script: $tmp_file"
  sudo bash "$tmp_file"

  # Clean up after execution
  rm -f "$tmp_file"
}

# === MAIN LOGIC ===
self_update

case "$1" in
  --help|-h)
    show_help
    ;;
  --list|-l)
    list_available_scripts
    ;;
  "")
    echo "Error: No script specified."
    echo "Run 'ezy-install --help' for usage."
    exit 1
    ;;
  *)
    run_script "$1"
    ;;
esac
