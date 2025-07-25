#!/bin/bash

# ezy-install: Simple command-line installer for predefined scripts hosted on GitHub
# Author: source-saraiva
# Repository: https://github.com/source-saraiva/ezy-install

REPO_OWNER="source-saraiva"
REPO_NAME="ezy-install"
BRANCH="main"
RAW_BASE_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH"
API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents"

show_help() {
  echo "Usage: ezy-install <script-name>"
  echo
  echo "Options:"
  echo "  --help       Show this help message"
  echo "  --list       List available installer scripts from GitHub"
  echo
  echo "Example:"
  echo "  ezy-install mysql"
}

list_available_scripts() {
  echo "Fetching available scripts from GitHub..."

  scripts=$(curl -fsSL "$API_URL" | grep '"name":' | grep '.sh' | cut -d '"' -f 4 | grep -v '^ezy-install.sh$')

  if [ -z "$scripts" ]; then
    echo "No scripts found or unable to reach GitHub."
    exit 1
  fi

  echo "Available scripts:"
  echo "$scripts" | sed 's/\.sh$//' | sort
}

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

# Main logic
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

