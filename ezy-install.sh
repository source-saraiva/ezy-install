#!/bin/bash

# ezy-install: Wrapper installer with Rocky Linux version detection
# Author: source-saraiva
# Repository: https://github.com/source-saraiva/ezy-install

CURRENT_VERSION="0.2.4"
REPO_OWNER="source-saraiva"
REPO_NAME="ezy-install"
BRANCH="main"
RAW_BASE_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH"
API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents"

# Detect Rocky Linux version (9, 10, 11, etc.)
ROCKY_VERSION=$(grep -oP '(?<=VERSION_ID=")[0-9]+' /etc/os-release 2>/dev/null)
if [[ -z "$ROCKY_VERSION" ]]; then
    echo "Could not detect Rocky Linux version. Defaulting to 10."
    ROCKY_VERSION="10"
fi

# --- Function: Check for updates ---
check_updates() {
    LATEST_VERSION=$(curl -s "https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH/ezy-install.version" 2>/dev/null)
    if [[ -n "$LATEST_VERSION" && "$LATEST_VERSION" != "$CURRENT_VERSION" ]]; then
        echo "⚠️  A new version of ezy-install is available: $LATEST_VERSION (current: $CURRENT_VERSION)"
        echo "Update with: curl -o /usr/local/bin/ezy-install https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH/ezy-install.sh && chmod +x /usr/local/bin/ezy-install"
    fi
}

# --- Function: List available scripts ---
list_scripts() {
    echo "==========================================================="
    echo "                       Available Scripts"
    echo "==========================================================="
    echo "Fetching available Rocky Linux $ROCKY_VERSION scripts from GitHub..."

    FILES=$(curl -s "$API_URL" | jq -r '.[].name')

    for file in $FILES; do
        if [[ "$file" == *_rocky*.sh ]]; then
            echo "${file%.sh}"
        fi
    done
}

# --- Function: Run a script ---
run_script() {
    SCRIPT_NAME="$1"

    if [[ -z "$SCRIPT_NAME" ]]; then
        echo "Usage: ezy-install <script>"
        exit 1
    fi

    SCRIPT_FILE="${SCRIPT_NAME}_rocky${ROCKY_VERSION}.sh"
    SCRIPT_URL="$RAW_BASE_URL/$SCRIPT_FILE"

    echo "Downloading $SCRIPT_FILE ..."
    curl -s -O "$SCRIPT_URL"

    if [[ -f "$SCRIPT_FILE" ]]; then
        chmod +x "$SCRIPT_FILE"
        echo "Running $SCRIPT_FILE ..."
        bash "$SCRIPT_FILE"
    else
        echo "Error: $SCRIPT_FILE not found in repository."
    fi
}

# --- Main ---
case "$1" in
    -l|--list)
        check_updates
        list_scripts
        ;;
    -v|--version)
        echo "ezy-install version $CURRENT_VERSION"
        ;;
    ""|-h|--help)
        echo "Usage: ezy-install <script> | -l (list) | -v (version)"
        ;;
    *)
        check_updates
        run_script "$1"
        ;;
esac
