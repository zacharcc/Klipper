#!/bin/bash

# --- Paths ---
#SANDWORM_REPO="$HOME/Sandworm/config"
# CONFIG_DIR="$HOME/printer_data/config
# MOONRAKER_CONF="$CONFIG_DIR/moonraker.conf"
SANDWORM_REPO="$HOME/Sandworm/test"
CONFIG_DIR="$HOME/printer_data/config/TEST/update_test"
MOONRAKER_CONF="$HOME/printer_data/config/moonraker.conf"
BACKUP_DIR="$HOME/Sandworm/Backup/backup_config_$(date +%Y%m%d_%H%M%S)"
LOGFILE="$HOME/Sandworm/update_logs/update_$(date +%Y%m%d_%H%M%S).log"

# --- Colors ---
OK="\e[32m[OK]\e[0m"
SKIPPED="\e[33m[SKIPPED]\e[0m"
ERROR="\e[31m[ERROR]\e[0m"

# --- Logging ---
mkdir -p "$(dirname "$LOGFILE")"
exec > >(tee -a "$LOGFILE") 2>&1

echo "🔄 Starting Sandworm install/update script..."

set -Ee
trap 'echo -e "$ERROR Script failed at line $LINENO"' ERR

# --- Functions ---
add_update_manager_block() {
    echo -e "\n[update_manager Sandworm]
type: git_repo
origin: https://github.com/zacharcc/Klipper.git
path: ~/Sandworm
primary_branch: main
managed_services: klipper
install_script: install.sh
version: ~/Sandworm/version.txt" >> "$MOONRAKER_CONF"
}

backup_files() {
    echo "📂 Creating backup of your current config in $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    cp -r "$CONFIG_DIR/"* "$BACKUP_DIR/" || echo -e "$ERROR Backup failed!"
}

add_update_manager_block() {
    VERSION=$(cat "$SANDWORM_REPO/version.txt" | tr -d '\r')  # Načítá verzi z version.txt
    echo -e "\n[update_manager Sandworm]
    type: git_repo
    origin: https://github.com/zacharcc/Klipper.git
    path: ~/Sandworm
    primary_branch: main
    managed_services: klipper
    install_script: install.sh
    version: $VERSION" >> "$MOONRAKER_CONF"
    echo -e "$OK Added update_manager block to moonraker.conf with version $VERSION"
}

version() {
    if [ -f "$HOME/Sandworm/version.txt" ]; then
        VERSION=$(cat "$HOME/Sandworm/version.txt")
        echo "📌 Updating to Sandworm version $VERSION"
    else
        echo "⚠️ version.txt not found!"
    fi
}

restart_klipper() {
    echo "♻️ Restarting Klipper to load new config..."
    for i in {5..1}; do
        echo "Restarting in $i seconds..."
        sleep 1
    done
    curl -X POST 'http://localhost:7125/printer/restart'
}

restart_moonraker() {
    echo "♻️ Restarting Moonraker to apply config changes..."
    sudo systemctl restart moonraker
}

# --- Cold Install Detection ---
IS_COLD_INSTALL=false
if [ ! -f "$MOONRAKER_CONF" ]; then
	echo -e "$ERROR moonraker.conf not found: $MOONRAKER_CONF"
    IS_COLD_INSTALL=true
elif ! grep -q "^\[update_manager Sandworm\]" "$MOONRAKER_CONF"; then
    IS_COLD_INSTALL=true
fi

if [ "$IS_COLD_INSTALL" = true ]; then
    echo "🧊 Cold install detected..."

    mkdir -p "$HOME/Sandworm/config"
    backup_files
    copy_files

    if ! grep -q "^\[update_manager Sandworm\]" "$MOONRAKER_CONF" 2>/dev/null; then
        add_update_manager_block
        echo -e "$OK Added update_manager block to moonraker.conf"
    else
        echo -e "$SKIPPED update_manager already exists in moonraker.conf"
    fi
	
    echo -e "$OK Cold install finished."
    restart_moonraker
    
else
    echo "🔁 Regular update mode..."
    if [ ! -d "$SANDWORM_REPO" ]; then
        echo -e "$ERROR Source repo directory $SANDWORM_REPO not found!"
        exit 1
    fi

    backup_files
    copy_files
    version

    echo -e "$OK Update complete! Your config was backed up at $BACKUP_DIR"
    echo -e "$SKIPPED If you had custom changes, check backup manually."

    restart_klipper
fi
