#!/bin/bash

# --- Trap ---
set -Ee
trap 'echo -e "$ERROR Script failed at line $LINENO"' ERR

# --- Brake line after git clone messages---
echo ""

# --- Paths ---
# SANDWORM_REPO="$HOME/Sandworm/config"
# CONFIG_DIR="$HOME/printer_data/config"
# MOONRAKER_CONF="$CONFIG_DIR/moonraker.conf"
SANDWORM_REPO="$HOME/Sandworm/test"
CONFIG_DIR="$HOME/printer_data/config/TEST/update_test"
MOONRAKER_CONF="$HOME/printer_data/config/moonraker.conf"
BACKUP_DIR="$HOME/Sandworm/backup/backup_config_$(date +%Y%m%d_%H%M%S)"
LOGFILE="$HOME/printer_data/logs/sandworm_update.log"
TMP_LOG_DIR="$HOME/Sandworm/tmp"
TMP_UPDATE_LOG="$TMP_LOG_DIR/sandworm_tmp_update.log"

# --- Colors (plain text for universal compatibility) ---
OK="[OK]"
INFO="[INFO]"
SKIPPED="[SKIPPED]"
ERROR="[ERROR]"

# --- Version from Git tag ---
if git -C "$HOME/Sandworm" tag | grep -q .; then
    VERSION=$(git -C "$HOME/Sandworm" describe --tags --exact-match 2>/dev/null)
    if [ -z "$VERSION" ]; then
        VERSION=$(git -C "$HOME/Sandworm" describe --tags --always | cut -d '-' -f 1)
    fi
else
    VERSION=$(git -C "$HOME/Sandworm" rev-parse --short HEAD)
fi

# --- Optional custom name (from version.txt) ---
VERSION_FILE="$HOME/Sandworm/version.txt"
if [ -f "$VERSION_FILE" ]; then
    CUSTOM_VERSION=$(head -n 1 "$VERSION_FILE" | tr -d '\r')
else
    CUSTOM_VERSION="N/A"
fi

# --- Cold Install Detection ---
IS_COLD_INSTALL=false
if [ ! -f "$MOONRAKER_CONF" ]; then
    echo -e "$ERROR moonraker.conf not found: $MOONRAKER_CONF"
    IS_COLD_INSTALL=true
elif ! grep -q "^\[update_manager Sandworm\]" "$MOONRAKER_CONF"; then
    IS_COLD_INSTALL=true
fi

# --- Logging ---
mkdir -p "$TMP_LOG_DIR"
if [ "$IS_COLD_INSTALL" = true ]; then
    echo "============ Cold Install ============" > "$LOGFILE"
    echo "Started: $(date)" >> "$LOGFILE"
    echo "Git version: $VERSION" >> "$LOGFILE"
    echo "Custom version: $CUSTOM_VERSION" >> "$LOGFILE"
    echo "" >> "$LOGFILE"
    exec > >(tee -a "$LOGFILE") 2>&1
else
    echo ""
    echo "================ Update ===============" > "$TMP_UPDATE_LOG"
    echo "Started: $(date)" >> "$TMP_UPDATE_LOG"
    echo "Git version: $VERSION" >> "$TMP_UPDATE_LOG"
    echo "Custom version: $CUSTOM_VERSION" >> "$TMP_UPDATE_LOG"
    echo "" >> "$TMP_UPDATE_LOG"
    exec > >(tee "$TMP_UPDATE_LOG") 2>&1
fi

# --- Message wrapper ---
start_message() {
    if [[ "$IS_COLD_INSTALL" = true ]]; then
        echo "Starting installation of automatic Sandworm updates..."
    else
        echo "Starting update of Sandworm macros..."
    fi
}

# --- Functions ---
add_update_manager_block() {
    echo -e "\n[update_manager Sandworm]
type: git_repo
origin: https://github.com/zacharcc/Klipper.git
path: ~/Sandworm
primary_branch: test
managed_services: klipper
install_script: install.sh" >> "$MOONRAKER_CONF"
    echo -e "$OK Added update_manager config block to moonraker.conf"
}

backup_files() {
    echo "Creating backup of your current config in $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    cp -r "$CONFIG_DIR/"* "$BACKUP_DIR/" || echo -e "$ERROR Backup failed!"
    echo "$OK Backup complete – Saved to $BACKUP_DIR"
}

copy_files() {
    echo "Copying new files from $SANDWORM_REPO to $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
    rsync -av "$SANDWORM_REPO/" "$CONFIG_DIR/"
    echo "$OK Copying completed."
}

restart_klipper() {
    echo "Restarting Klipper to load new config..."
    for i in {5..1}; do
        echo "Restarting in $i seconds..."
        sleep 1
    done
    curl -X POST 'http://localhost:7125/printer/restart'
}

restart_moonraker() {
    echo "Restarting Moonraker to apply config changes..."
    sleep 2
    sudo systemctl restart moonraker
}

# --- Execution ---
start_message

if [ "$IS_COLD_INSTALL" = true ]; then
    echo "Cold install detected..."

    mkdir -p "$HOME/Sandworm/config"
    backup_files
    copy_files

    if ! grep -q "^\[update_manager Sandworm\]" "$MOONRAKER_CONF" 2>/dev/null; then
        add_update_manager_block
    else
        echo -e "$SKIPPED update_manager already exists in moonraker.conf"
    fi
    
    echo ""
    echo -e "$OK Cold install finished."
    restart_moonraker

else
    echo "Regular update mode..."

    if [ ! -d "$SANDWORM_REPO" ]; then
        echo -e "$ERROR Source repo directory $SANDWORM_REPO not found!"
        exit 1
    fi

    backup_files
    copy_files
    
    echo ""
    echo -e "$OK Update complete! Your config was backed up at $BACKUP_DIR"
    echo -e "$INFO If you had custom changes, check backup manually."

    # Append update log to main log
    cat "$TMP_UPDATE_LOG" >> "$LOGFILE"
    rm "$TMP_UPDATE_LOG"

    restart_klipper
fi
