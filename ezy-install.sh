#!/bin/bash

# ===========================================================
# ezy-install: Wrapper installer with Rocky Linux version detection
# Author: source-saraiva
# Repository: https://github.com/source-saraiva/ezy-install
# ===========================================================

CURRENT_VERSION="0.2.2"
REPO_OWNER="source-saraiva"
REPO_NAME="ezy-install"
BRANCH="main"
RAW_BASE_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH"
API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents"

# ==============================
# Detect Rocky Linux version
# ==============================
ROCKY_VERSION=$(rpm -E %{rhel})

# ==============================
# Functions
# ==============================

# Show usage
usage() {
    echo "Usage: $0 [options] <script>"
    echo
    echo "Options:"
    echo "  -l            List available scripts"
    echo "  -h            Show this help"
    echo
    echo "Example:"
    echo "  $0 nextcloud"
    echo
}

# List available scripts
list_scripts() {
    echo "==========================================================="
    echo "                       Available Scripts"
    echo "==========================================================="
    echo "Fetching available Rocky Linux $ROCKY_VERSION scripts from GitHub..."
    echo

    curl -s "$API_URL/scripts" | \
    grep '"name"' | cut -d '"' -f 4 | sort | column
    echo
}

# Run the requested script
run_script() {
    local script_name=$1
    local script_url="$RAW_BASE_URL/scripts/$script_name.sh"

    echo "==========================================================="
    echo "                  Running: $script_name"
    echo "==========================================================="

    curl -fsSL "$script_url" -o /tmp/$script_name.sh
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch $script_name.sh from GitHub."
        exit 1
    fi

    chmod +x /tmp/$script_name.sh
    /bin/bash /tmp/$script_name.sh
}

# ==============================
# Main logic
# ==============================

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

while getopts ":lh" opt; do
    case ${opt} in
        l )
            list_scripts
            exit 0
            ;;
        h )
            usage
            exit 0
            ;;
        \? )
            echo "Invalid option: -$OPTARG" >&2
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

SCRIPT=$1
run_script "$SCRIPT"
