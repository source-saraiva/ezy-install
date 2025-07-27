#!/bin/bash

# ================================================
#   ezy-install: Lightweight Script Installer
#   Author: source-saraiva
#   Repository: https://github.com/source-saraiva/ezy-install
#   ezy-install version: 0.0.2
# ================================================

REPO_OWNER="source-saraiva"
REPO_NAME="ezy-install"
BRANCH="main"
RAW_BASE_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH"
SCRIPT_NAME="ezy-install.sh"
SCRIPT_URL="$RAW_BASE_URL/$SCRIPT_NAME"
API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents"

# === GET LOCAL VERSION ===
get_local_version() {
  grep -E '^#   ezy-install version:' "$0" | awk '{print $NF}'
}

# === GET REMOTE VERSION ===
get_remote_version() {
  curl -fsSL "$SCRIPT_URL" | grep -E '^#   ezy-install version:' | awk '{print $NF}'
}

# === COMPARE VERSIONS ===
version_gt() {
  # returns 0 if $1 > $2
  [ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" ]
}

# === SELF-UPDATE ===
self_update() {
  echo "Checking for ezy-install updates..."

  local_version=$(get_local_version)
  remote_version=$(get_remote_version)

  if version_gt "$remote_version" "$local_version"; then
    echo "New version available: $remote_version (current: $local_version)"
    echo "Updating ezy-install.sh..."

    curl -fsSL "$SCRIPT_URL" -o "$0.tmp"
    if [ $? -ne 0 ]; then
      echo "Error downloading update. Aborting."
      rm -f "$0.tmp"
      return
    fi

    chmod +x "$0.tmp"
    mv "$0.tmp" "$0"
    echo "ezy-install has been updated to version $remote_version. Please re-run your command."
    exit 0
  else
    echo "ezy-install is up to date (version $local_version)."
  fi
}

# === SHOW HELP ===
show_help() {
  echo "Usage: ezy-install <script-name>"
  echo
  echo "Options:"
  echo "  --help       Show this help message"
  echo "  --list       List available installer scripts from GitHub"
  echo
  echo "Example:"
  echo "  ezy-install zabbix"
  echo
  echo "Description:"
  echo "  ezy-install is a lightweight command-line launcher that fetches and runs installation scripts"
  echo "  directly from this repository. It simplifies the setup of common solutions with one command."
  echo "  It also alleviates the trial-and-error process typically required when installing software,"
  echo "  making the experience more like Windows-style roles and features installation."
  echo
}

# === LIST AVAILABLE SCRIPTS ===
list_available_scripts() {
  echo "Fetching available scripts from GitHub..."

  scripts=$(curl -fsSL "$API_URL" | grep '"name":' | grep '.sh' | cut -d '"' -f 4 | grep -v '^ezy-install.sh$')

  if [ -z "$scripts" ]; then
    echo "No scripts found or unable to reach GitHub."
    exit 1
  fi

  echo "Available scripts:"
  echo "$scripts" | sed 's/\.sh$//' | sort
  echo
}

# === RUN SPECIFIED SCRIPT ===
run_script() {
  script_name="$1"
  script_url="$RAW_BASE_URL/${script_name}.sh"

  echo "Downloading and executing script: $script_name"

  TMP_SCRIPT=$(mktemp)
  curl -fsSL "$script_url" -o "$TMP_SCRIPT"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to download script '$script_name'."
    rm -f "$TMP_SCRIPT"
    exit 1
  fi

  chmod +x "$TMP_SCRIPT"
  bash "$TMP_SCRIPT"
  rm -f "$TMP_SCRIPT"
}

# === MAIN LOGIC ===
self_update

case "$1" in
  --help|-h)
    show_help
    ;;
  --list)
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
