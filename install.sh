#!/bin/bash

SANDWORM_REPO="$HOME/Sandworm/config"
CONFIG_DIR="$HOME/printer_data/config"
BACKUP_DIR="$HOME/Sandworm/Backup/backup_config_$(date +%Y%m%d_%H%M%S)"

## Colors:
OK="\e[32m[OK]\e[0m"
SKIPPED="\e[33m[SKIPPED]\e[0m"
ERROR="\e[31m[ERROR]\e[0m"

echo "🔄 Starting Sandworm update..."

set -Ee
trap 'echo -e "\e[31mERROR:\e[0m Script failed at line $LINENO"' ERR

## Root check (optional - currently not needed)
# -------------------------------------------------------------
# The following block checks if the script is run as root.
# If not, it automatically re-executes itself using sudo.
# This is only necessary if the script includes operations
# requiring root privileges (e.g. system-wide apt installs).
#
# Currently, all operations are done within the user's home
# directory, so this block is not required.
# You can re-enable it if root access becomes necessary.
#
# if [[ $EUID -ne 0 ]]; then
#     echo -e "$ERROR This script must be run as root! I'm trying to run it with sudo..."
#     exec sudo "$0" "$@"
# fi

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

## Dependency installation (optional - currently disabled)
# -------------------------------------------------------------
# This function is a placeholder for installing additional
# dependencies your project might need in the future.
#
# If you decide to use apt-get or other system package managers
# that require root access, make sure to also enable the
# root check block above, so the script can elevate privileges.
#
# To use this, simply uncomment the apt-get lines and make sure
# you add the necessary package names:
#
# sudo apt-get update
# sudo apt-get install -y your-package-name
#
# For example:
# sudo apt-get install -y git python3-pip

install_dependencies() {
    echo "🛠 Installing dependencies..."
    # sudo apt-get update
    # sudo apt-get install -y your-package-name
    echo -e "$SKIPPED No dependencies needed."
    }

## Launching functions:
# install_dependencies
backup_files
copy_files
version
cleanup

echo -e "✅ $OK Update complete! Your old config is backed up at $BACKUP_DIR"
echo -e "⚠️ $SKIPPED If you had custom modifications, check the backup folder!"
