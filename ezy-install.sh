#!/bin/bash


CURRENT_VERSION="0.1.1"
REPO_OWNER="source-saraiva"
REPO_NAME="ezy-install"
BRANCH="main"
RAW_BASE_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH"
API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents"

DISTRO_SUFFIX=""

# === DETECT DISTRO AND VERSION ===
detect_distro_suffix() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    distro_id=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
    version_major=$(echo "$VERSION_ID" | cut -d '.' -f1)

    case "$distro_id" in
      rocky)
        DISTRO_SUFFIX="rockylinux_${version_major}"
        ;;
      almalinux)
        DISTRO_SUFFIX="almalinux_${version_major}"
        ;;
      ubuntu)
        DISTRO_SUFFIX="ubuntu_${version_major}"
        ;;
      debian)
        DISTRO_SUFFIX="debian_${version_major}"
        ;;
      *)
        echo "Warning: Unsupported or unknown distro '$distro_id'."
        DISTRO_SUFFIX=""
        ;;
    esac

    if [ -n "$DISTRO_SUFFIX" ]; then
      echo "Detected system: $distro_id $VERSION_ID → suffix: $DISTRO_SUFFIX"
    fi
  fi
}

# === DISPLAY HELP ===
show_help() {
  echo "Usage: ezy-install <script-name>"
  echo
  echo "Options:"
  echo " -h or --help       Show this help message"
  echo " -l or --list       List available installer scripts from GitHub"
  echo
  echo "Example:"
  echo "  ezy-install mysql"
  echo
}

# === SELF UPDATE CHECK ===
self_update() {
  echo "Checking for ezy-install updates..."
  echo "Local version: $CURRENT_VERSION"

  REMOTE_SCRIPT=$(curl -fsSL "$RAW_BASE_URL/ezy-install.sh")
  REMOTE_VERSION=$(echo "$REMOTE_SCRIPT" | grep '^CURRENT_VERSION=' | cut -d '"' -f2)

  echo "Remote version:  $REMOTE_VERSION"

  if [[ "$REMOTE_VERSION" != "$CURRENT_VERSION" ]]; then
    echo "New version available: $REMOTE_VERSION"
    TMP_FILE=$(mktemp /tmp/ezy-install.XXXXXX)
    curl -fsSL "$RAW_BASE_URL/ezy-install.sh" -o "$TMP_FILE" && chmod +x "$TMP_FILE"

    UPDATER_SCRIPT=$(mktemp /tmp/ezy-updater.XXXXXX.sh)
    cat <<EOF > "$UPDATER_SCRIPT"
#!/bin/bash
sudo mv "$TMP_FILE" /usr/local/bin/ezy-install
sudo chmod +x /usr/local/bin/ezy-install
echo "Updated to version $REMOTE_VERSION."
EOF
    chmod +x "$UPDATER_SCRIPT"
    exec bash "$UPDATER_SCRIPT"
  fi
}

# === LIST AVAILABLE SCRIPTS ===
list_available_scripts() {
  echo "Fetching available scripts from GitHub..."

  scripts=$(curl -fsSL "$API_URL" | grep '"name":' | grep '.sh' | cut -d '"' -f 4 | grep -v '^ezy-install.sh$')

  echo
  echo "==========================================================="
  echo "                       Available Scripts"
  echo "==========================================================="

  filtered=()
  for script in $scripts; do
    base=$(basename "$script" .sh)
    if [[ "$base" == *_${DISTRO_SUFFIX} ]]; then
      clean_name="${base%_${DISTRO_SUFFIX}}"
      filtered+=("$clean_name")
    fi
  done

  total=${#filtered[@]}
  cols=3
  rows=$(( (total + cols - 1) / cols ))

  for ((i = 0; i < rows; i++)); do
    for ((j = 0; j < cols; j++)); do
      index=$((j * rows + i))
      if [ $index -lt $total ]; then
        printf "%-25s" "${filtered[$index]}"
      fi
    done
    echo
  done

  echo
}

# === RUN INSTALLER SCRIPT ===
run_script() {
  script_name="$1"

  if [[ -n "$DISTRO_SUFFIX" ]]; then
    full_script_name="${script_name}_${DISTRO_SUFFIX}"
  else
    full_script_name="$script_name"
  fi

  tmp_file=$(mktemp "/tmp/${full_script_name}.XXXXXX.sh")
  script_url="$RAW_BASE_URL/${full_script_name}.sh"

  echo "Downloading script: $full_script_name"
  if ! curl -fsSL "$script_url" -o "$tmp_file"; then
    echo "Error: Failed to download script '$full_script_name'."
    exit 1
  fi

  chmod +x "$tmp_file"
  echo "Executing script: $tmp_file"
  sudo bash "$tmp_file"
  rm -f "$tmp_file"
}

# === MAIN LOGIC ===
self_update
detect_distro_suffix

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
