#!/bin/bash

SANDWORM_REPO="$HOME/Sandworm/test/"
CONFIG_DIR="$HOME/printer_data/config/TEST/update_test/"
BACKUP_DIR="$HOME/Sandworm/Backup/backup_config_$(date +%Y%m%d_%H%M%S)"

## Colors:
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

## Functions for backing up files with control:
backup_files() {
    echo "📂 Creating backup of your current config in $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    cp -r "$CONFIG_DIR/"* "$BACKUP_DIR/" || echo -e "$ERROR Backup copy error!" 
    }

## Functions for copying files with control:
copy_files() {
    echo "🚀 Updating Sandworm config..."
    mkdir -p "$CONFIG_DIR"
    rsync -av "$SANDWORM_REPO/" "$CONFIG_DIR/" || echo -e "$ERROR Update copy error!" 
    rsync -av --itemize-changes "$SANDWORM_REPO/" "$CONFIG_DIR/"
    }

## Version check function:
version() {
    if [ -f "$SANDWORM_REPO/version.txt" ]; then
       VERSION=$(cat "$SANDWORM_REPO/version.txt")
       echo "📌 Updating to Sandworm version $VERSION"
    else
       echo "⚠️ Warning: version.txt not found! Update may be incomplete."
    fi }

## Functions for cleaning old files:
cleanup() {
    echo "🧹 Cleaning up outdated files..."
    find "$CONFIG_DIR" -name '*.bak' -type f -delete
    echo -e "$OK Cleaning completed." 
    }

## Launching functions:
backup_files
copy_files
version
cleanup

LOGFILE="$HOME/Sandworm/update_logs/update_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$(dirname "$LOGFILE")"
exec > >(tee -a "$LOGFILE") 2>&1

version=$(cat "$SRC/version.txt")
sed "s|{version}|$version|g" "$SRC/extras/SANWORM_UPDATE_TEMPLATE.cfg" > "$CONFIG_PATH/SANWORM_UPDATED.cfg"


echo -e "✅ $OK Update complete! Your old config is backed up at $BACKUP_DIR"
echo -e "⚠️ $SKIPPED If you had custom modifications, check the backup folder!"

echo "Provádím restart firmware pro načtení aktualizace..."
curl -X POST 'http://localhost:7125/printer/restart'
## Functions for copying files with control:
copy_files() {
    echo "🚀 Updating Sandworm config..."
    mkdir -p "$CONFIG_DIR"
    rsync -av "$SANDWORM_REPO/" "$CONFIG_DIR/" || echo -e "$ERROR Update copy error!" 
    rsync -av --itemize-changes "$SANDWORM_REPO/" "$CONFIG_DIR/"
    }

## Version check function:
version() {
    if [ -f "$SANDWORM_REPO/version.txt" ]; then
       VERSION=$(cat "$SANDWORM_REPO/version.txt")
       echo "📌 Updating to Sandworm version $VERSION"
    else
       echo "⚠️ Warning: version.txt not found! Update may be incomplete."
    fi }

## Functions for cleaning old files:
cleanup() {
    echo "🧹 Cleaning up outdated files..."
    find "$CONFIG_DIR" -name '*.bak' -type f -delete
    echo -e "$OK Cleaning completed." 
    }

## Launching functions:
backup_files
copy_files
version
cleanup

LOGFILE="$HOME/Sandworm/update_logs/update_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$(dirname "$LOGFILE")"
exec > >(tee -a "$LOGFILE") 2>&1

echo -e "✅ $OK Update complete! Your old config is backed up at $BACKUP_DIR"
echo -e "⚠️ $SKIPPED If you had custom modifications, check the backup folder!"



