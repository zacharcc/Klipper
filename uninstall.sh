#!/bin/bash

# ══════════════════════════════════════════════
#  Uninstall script for Sandworm macros
# ══════════════════════════════════════════════

set -Ee
trap 'echo -e "$ERROR Script failed at line $LINENO"' ERR

# --- Paths ---
# CONFIG_DIR="$HOME/printer_data/config"
CONFIG_DIR="$HOME/printer_data/config/TEST/update_test"
BACKUP_ROOT="$HOME/Sandworm/backup"
MOONRAKER_CONF="$CONFIG_DIR/moonraker.conf"
LOGFILE="$HOME/printer_data/logs/sandworm_uninstall_$(date +%Y_%m_%d-%Hh%Mm).log"
SANDWORM_DIR="$HOME/Sandworm"

# --- Status messages ---
OK="[OK]"
INFO="[INFO]"
SKIPPED="[SKIPPED]"
ERROR="[ERROR]"
MESS_DELAY=0.5

print_row() {
    local msg="$1"
    printf "║ %-79s ║\n" "$msg"
}

# --- Logging setup ---
exec > >(tee -a "$LOGFILE") 2>&1

echo "╔═════════════════════════════════════════════════════════════════════════════════╗"
echo "║                             Sandworm Uninstall Script                           ║"
echo "╠═════════════════════════════════════════════════════════════════════════════════╣"

print_row "Started: $(date)"
print_row ""
print_row "This will uninstall Sandworm macros and restore your previous configuration."
print_row ""
print_row "Actions to be performed:"
print_row "1. Restore backup files from: $BACKUP_ROOT"
print_row "2. Remove: [update_manager Sandworm] and [power printer] from moonraker.conf"
print_row "3. Delete folder: $SANDWORM_DIR"
print_row ""
echo "╚═════════════════════════════════════════════════════════════════════════════════╝"
echo ""

# --- Safety confirmation ---
sleep $MESS_DELAY
read -rp "⚠️  Do you really want to proceed with uninstalling Sandworm? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo ""
    echo "$INFO Uninstall cancelled by user."
    exit 0
fi

# --- Step 1: Find most recent backup ---
LATEST_BACKUP=$(find "$BACKUP_ROOT" -maxdepth 1 -type d -name "backup_config_*" | sort -r | head -n 1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "$ERROR No backup directory found in $BACKUP_ROOT!"
    exit 1
fi

echo ""
echo "╔═════════════════════════════════════════════════════════════════════════════════╗"
print_row "1. Restoring backup:"

from_path="  ● from: $LATEST_BACKUP"
to_path="  ●   to: $CONFIG_DIR"

formatted_from=$(printf "%-82s" "$from_path")
formatted_to=$(printf "%-82s" "$to_path")

echo -e "║ $formatted_from║"
echo -e "║ $formatted_to║"

print_row ""

if cp -r "$LATEST_BACKUP/"* "$CONFIG_DIR/"; then
    print_row "   $OK Backup restored."
else
    print_row "   $ERROR Failed to restore files from backup!"
    exit 1
fi

# --- Step 2: Remove Sandworm sections from moonraker.conf ---
print_row ""
echo "╟─────────────────────────────────────────────────────────────────────────────────╢"
print_row "2. Removing Sandworm-related config blocks from: $MOONRAKER_CONF"

if [ ! -f "$MOONRAKER_CONF" ]; then
    print_row "   $ERROR moonraker.conf not found!"
else
    sed -i '/^\[update_manager Sandworm\]/,/^[[]/d' "$MOONRAKER_CONF"
    sed -i '/^\[power printer\]/,/^[[]/d' "$MOONRAKER_CONF"
    print_row "   $OK Config blocks removed."
fi

# --- Step 3: Delete ~/Sandworm directory safely ---
print_row ""
echo "╟─────────────────────────────────────────────────────────────────────────────────╢"

if [ -d "$SANDWORM_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ "$SCRIPT_DIR" == "$SANDWORM_DIR"* ]]; then
        print_row "$INFO Script is running from inside Sandworm folder. Moving to safe location..."
        cd /tmp || exit 1
    fi

    print_row "3. Deleting directory: $SANDWORM_DIR"
    rm -rf "$SANDWORM_DIR"
    print_row "$OK Sandworm directory removed."
else
    print_row "$SKIPPED No Sandworm directory found to delete."
fi

# --- Done ---
print_row ""
echo "╟─────────────────────────────────────────────────────────────────────────────────╢"
print_row "$OK Sandworm macros have been uninstalled successfully!"
print_row "To apply the changes, please restart Moonraker using the [Y] option."
print_row "Uninstall log saved to: $LOGFILE"
echo "╚═════════════════════════════════════════════════════════════════════════════════╝"


# --- Optional [y/N]: Restart Moonraker ---
echo ""
sleep $MESS_DELAY
read -rp "Do you want to restart Moonraker now to apply config changes? [y/N]: " restart_moonraker
if [[ "$restart_moonraker" =~ ^[Yy]$ ]]; then
    echo "$INFO Restarting Moonraker..."
    curl --no-progress-meter -X POST http://localhost:7125/server/restart > /dev/null 2>&1
    echo "$OK Moonraker restart command sent."
else
    echo "$INFO Moonraker restart skipped. Changes will apply after manual restart."
fi

echo ""
sleep $MESS_DELAY