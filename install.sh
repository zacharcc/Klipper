#!/bin/bash

# --- Trap ---
set -Ee
trap 'echo -e "$ERROR Script failed at line $LINENO"' ERR

# --- Paths ---
# SANDWORM_REPO="$HOME/Sandworm/config"
# CONFIG_DIR="$HOME/printer_data/config
# MOONRAKER_CONF="$CONFIG_DIR/moonraker.conf"
SANDWORM_REPO="$HOME/Sandworm/test"
CONFIG_DIR="$HOME/printer_data/config/TEST/update_test"
MOONRAKER_CONF="$HOME/printer_data/config/moonraker.conf"
BACKUP_DIR="$HOME/Sandworm/Backup/backup_config_$(date +%Y%m%d_%H%M%S)"
LOGFILE="$HOME/Sandworm/update_logs/update_$(date +%Y%m%d_%H%M%S).log"

# --- Colors ---
OK="\e[32m[OK]\e[0m"
INFO="\e[37m[INFO]\e[0m"
SKIPPED="\e[90m[SKIPPED]\e[0m"
ERROR="\e[31m[ERROR]\e[0m"

# --- Logging ---
mkdir -p "$(dirname "$LOGFILE")"
exec > >(tee -a "$LOGFILE") 2>&1

# --- Version ---
# VERSION=$(git -C "$HOME/Sandworm" describe --tags --always)
VERSION=$(git -C "$HOME/Sandworm" describe --tags --exact-match 2>/dev/null)
if [ -z "$VERSION" ]; then
    VERSION=$(git -C "$HOME/Sandworm" describe --tags --always | cut -d '-' -f 1)
fi
echo "Detected version: $VERSION"

# --- Cold Install Detection ---
IS_COLD_INSTALL=false
if [ ! -f "$MOONRAKER_CONF" ]; then
    echo -e "$ERROR moonraker.conf not found: $MOONRAKER_CONF"
    IS_COLD_INSTALL=true
elif ! grep -q "^\[update_manager Sandworm\]" "$MOONRAKER_CONF"; then
    IS_COLD_INSTALL=true
fi

# --- Message wrapper ---
start_message() {
    if [[ "$IS_COLD_INSTALL" = true ]]; then
        echo "Starting installation of automatic Sandworm updates..."
    else
        echo "🔄 Starting update of Sandworm macros..."
        echo "hint: 🔄 Starting update of Sandworm macros..."
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
install_script: install.sh
version: " >> "$MOONRAKER_CONF"
    echo -e "$OK Added update_manager config block to moonraker.conf"
    echo "hint: 📝 update_manager block added"
}

backup_files() {
    if [[ "$IS_COLD_INSTALL" = true ]]; then
        echo "Creating backup of your current config in $BACKUP_DIR..."
    else
        echo "📂 Creating backup of your current config in $BACKUP_DIR..."
        echo "hint: 📂 Creating backup of config in $BACKUP_DIR..."
    fi
    mkdir -p "$BACKUP_DIR"
    cp -r "$CONFIG_DIR/"* "$BACKUP_DIR/" || echo -e "$ERROR Backup failed!"
}

copy_files() {
    if [[ "$IS_COLD_INSTALL" = true ]]; then
        echo "Updating Sandworm config..."
    else
        echo "🚀 Updating Sandworm config..."
        echo "hint: 🚀 Copying files from $SANDWORM_REPO to $CONFIG_DIR"
    fi
    mkdir -p "$CONFIG_DIR"
    rsync -av "$SANDWORM_REPO/" "$CONFIG_DIR/"
}

restart_klipper() {
    echo "♻ Restarting Klipper to load new config..."
    echo "hint: ♻ Restarting Klipper..."
    for i in {5..1}; do
        echo "Restarting in $i seconds..."
        sleep 1
    done
    curl -X POST 'http://localhost:7125/printer/restart'
}

restart_moonraker() {
    echo "Restarting Moonraker to apply config changes..."
    sleep 1
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

    echo -e "$OK Cold install finished."
    restart_moonraker

else
    echo "🔁 Regular update mode..."
    echo "hint: 🔁 Regular update mode..."

    if [ ! -d "$SANDWORM_REPO" ]; then
        echo -e "$ERROR Source repo directory $SANDWORM_REPO not found!"
        echo "hint: ❌ ERROR – Source repo directory not found: $SANDWORM_REPO"
        exit 1
    fi

    backup_files
    echo "hint: ✅ Backup complete – saved to $BACKUP_DIR"

    copy_files
    echo "hint: 🧩 Files copied from $SANDWORM_REPO to $CONFIG_DIR"

    echo -e "✅ $OK Update complete! Your config was backed up at $BACKUP_DIR"
    echo "hint: ✅ Update complete! Backup saved at $BACKUP_DIR"

    echo -e "ℹ $INFO If you had custom changes, check backup manually."
    echo "hint: ℹ️ Check backup manually if you had custom changes."

    restart_klipper
fi
