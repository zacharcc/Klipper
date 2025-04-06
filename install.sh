#!/bin/bash

SANDWORM_REPO="$HOME/Sandworm/test/"
CONFIG_DIR="$HOME/printer_data/config/TEST/update_test/"
BACKUP_DIR="$HOME/Sandworm/Backup/backup_config_$(date +%Y%m%d_%H%M%S)"

# Colors:
OK="\e[32m[OK]\e[0m"
SKIPPED="\e[33m[SKIPPED]\e[0m"
ERROR="\e[31m[ERROR]\e[0m"

echo "🔄 Starting Sandworm update..."

set -Ee
trap 'echo -e "\e[31mERROR:\e[0m Script failed at line $LINENO"' ERR

if [ ! -d "$SANDWORM_REPO" ]; then
    echo -e "$ERROR Source repo directory $SANDWORM_REPO not found!"
    exit 1
fi

# Backup function:
backup_files() {
    echo "📂 Creating backup of your current config in $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    cp -r "$CONFIG_DIR/"* "$BACKUP_DIR/" || echo -e "$ERROR Backup copy error!"
    }

# Copy files:
copy_files() {
    echo "🚀 Updating Sandworm config..."
    mkdir -p "$CONFIG_DIR"
    rsync -av "$SANDWORM_REPO/" "$CONFIG_DIR/" || echo -e "$ERROR Update copy error!"
    rsync -av --itemize-changes "$SANDWORM_REPO/" "$CONFIG_DIR/" }

# Version check:
version() {
    if [ -f "$SANDWORM_REPO/version.txt" ]; then
        VERSION=$(cat "$SANDWORM_REPO/version.txt")
        echo "📌 Updating to Sandworm version $VERSION"
    else
        echo "⚠️ Warning: version.txt not found! Update may be incomplete."
    fi }

# Cleanup:
cleanup() {
    echo "🧹 Cleaning up outdated files..."
    find "$CONFIG_DIR" -name '*.bak' -type f -delete
    echo -e "$OK Cleaning completed."
    }

# Run steps:
backup_files
copy_files
version
cleanup

# Logging:
LOGFILE="$HOME/Sandworm/update_logs/update_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$(dirname "$LOGFILE")"
exec > >(tee -a "$LOGFILE") 2>&1

# Finish:
echo -e "✅ $OK Update complete! Your old config is backed up at $BACKUP_DIR"
echo -e "⚠️ $SKIPPED If you had custom modifications, check the backup folder!"

# Countdown before restart:
for i in {5..1}; do
    echo "Rebooting firmware to load update in $i seconds..."
    sleep 1
done

# Trigger Klipper restart:
curl -X POST 'http://localhost:7125/printer/restart'
