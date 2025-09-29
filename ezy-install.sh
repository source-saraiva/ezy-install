#!/bin/bash
# ==========================================================
# ezy-install: Simple command-line installer for predefined scripts hosted on GitHub
# Author: source-saraiva
# Repository: https://github.com/source-saraiva/ezy-install
# ==========================================================

CURRENT_VERSION="0.1.1"
REPO_OWNER="source-saraiva"
REPO_NAME="ezy-install"
BRANCH="main"

RAW_BASE_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH"
API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents"

# --- Detect Rocky Linux version ---
ROCKY_VERSION=$(rpm -E %{rhel})
SCRIPT_NAME=$(basename "$0")
BASE_NAME=${SCRIPT_NAME%.*}   # remove extension if exists

# --- Expected script name ---
TARGET_SCRIPT="${BASE_NAME}_rocky${ROCKY_VERSION}.sh"

echo "Detected Rocky Linux version: ${ROCKY_VERSION}"
echo "Looking for script: ${TARGET_SCRIPT}"

# --- Check if target script exists in same directory ---
if [[ -f "$(dirname "$0")/${TARGET_SCRIPT}" ]]; then
    echo "Found ${TARGET_SCRIPT}, executing..."
    bash "$(dirname "$0")/${TARGET_SCRIPT}" "$@"
else
    echo "ERROR: Script ${TARGET_SCRIPT} not found!"
    echo "Please make sure you have the correct script for Rocky Linux ${ROCKY_VERSION}."
    exit 1
fi
