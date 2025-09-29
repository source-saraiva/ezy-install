#!/bin/bash
#
# ezy-install wrapper script
# This script fetches and runs installation scripts from the GitHub repo source-saraiva/ezy-install
#

# ==============================
# Configuration
# ==============================
GITHUB_REPO="https://raw.githubusercontent.com/source-saraiva/ezy-install/main/scripts"

# Detect Rocky Linux version (only major version)
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

    curl -s https://api.github.com/repos/source-saraiva/ezy-install/contents/scripts | \
    grep '"name"' | cut -d '"' -f 4 | sort | column
    echo
}

# Run the requested script
run_script() {
    local script_name=$1
    local script_url="$GITHUB_REPO/$script_name.sh"

    echo "==========================================================="
    echo "                  Running: $script_name"
    echo "==========================================================="

    # Fetch and run script
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

# Run given script
SCRIPT=$1
run_script "$SCRIPT"
