#!/bin/bash

# === GitHub raw base URL (main branch) ===
BASE_URL="https://raw.githubusercontent.com/source-saraiva/ezy-install/main"

# === List of available scripts (update manually) ===
AVAILABLE_SCRIPTS=("mysql" "mariadb" "docker" "lamp" "nginx")

# === Show usage instructions ===
show_help() {
    echo ""
    echo "ezy-install - Download and execute install scripts from GitHub"
    echo ""
    echo "Usage:"
    echo "  ezy-install <script>     Run a specific installation script"
    echo "  ezy-install --list       List available scripts"
    echo "  ezy-install --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  ezy-install glpi"
    echo "  ezy-install mariadb"
    echo ""
}

# === List all available scripts ===
show_list() {
    echo ""
    echo "Available scripts:"
    for script in "${AVAILABLE_SCRIPTS[@]}"; do
        echo "  - $script"
    done
    echo ""
}

# === Entry point ===
SCRIPT_NAME="$1"

if [[ -z "$SCRIPT_NAME" ]]; then
    echo "Missing argument. Use --help for instructions."
    exit 1
fi

case "$SCRIPT_NAME" in
    --help|-h)
        show_help
        exit 0
        ;;
    --list|-l)
        show_list
        exit 0
        ;;
    *)
        SCRIPT_URL="${BASE_URL}/${SCRIPT_NAME}.sh"
        echo "Downloading script from: $SCRIPT_URL"
        curl -fsSL "$SCRIPT_URL" | bash
        if [[ $? -ne 0 ]]; then
            echo "Failed to execute script: $SCRIPT_NAME"
            exit 2
        fi
        ;;
esac

