#!/bin/bash

# ezy-install: Simple command-line installer for predefined scripts hosted on GitHub
# Author: source-saraiva
# Repository: https://github.com/source-saraiva/ezy-install

CURRENT_VERSION="0.0.4"
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
  echo "  --help       Show this help message"
  echo "  --list       List available installer scripts from GitHub"
  echo
  echo "Example:"
  echo "  ezy-install mysql"
  echo
  echo "Description:"
  echo "  ezy-install is a lightweight command-line launcher that fetches and runs installation scripts"
  echo "  directly from this repository. It simplifies the setup of common solutions with one command."
}

# === SELF UPDATE CHECK ===
self_update() {
  echo "Checking for ezy-install updates..."
  echo "Current version: $CURRENT_VERSION"

  # Fetch remote script content
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
    echo "Updating ezy-install.sh in /usr/local/bin..."

    TMP_SCRIPT=$(mktemp)

    if sudo curl -fsSL "$RAW_BASE_URL/ezy-install.sh" -o "$TMP_SCRIPT"; then
      sudo chmod +x "$TMP_SCRIPT"
      sudo mv "$TMP_SCRIPT" /usr/local/bin/ezy-install
      echo "ezy-install updated successfully to version $REMOTE_VERSION."
      echo "Please re-run your command."
      exit 0
    else
      echo "Error downloading update. Aborting."
      rm -f "$TMP_SCRIPT"
    fi
  fi
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

# === RUN INSTALLER SCRIPT ===
run_script() {
  script_name="$1"
  script_url="$RAW_BASE_URL/${script_name}.sh"

  echo "Downloading and executing script: $script_name"

  curl -fsSL "$script_url" | bash
  if [ $? -ne 0 ]; then
    echo "Error: Failed to run script '$script_name'."
    exit 1
  fi
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
