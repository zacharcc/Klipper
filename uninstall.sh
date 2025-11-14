#!/bin/bash

# ══════════════════════════════════════════════
#  Uninstall script for Sandworm macros
# ══════════════════════════════════════════════

set -Ee
trap 'echo -e "$ERROR Script failed at line $LINENO"' ERR

# --- Paths ---
CONFIG_DIR="$HOME/printer_data/config"
MOONRAKER_CONF="$CONFIG_DIR/moonraker.conf"
BACKUP_ROOT="$HOME/Sandworm/backup"
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

echo ""
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
PREFERRED_BACKUP=$(find "$BACKUP_ROOT" -maxdepth 1 -type d -name "backup_config_*" | sort | head -n 1)

if [ -n "$PREFERRED_BACKUP" ]; then
    LATEST_BACKUP="$PREFERRED_BACKUP"
else
    echo "$ERROR No backup directory found in $BACKUP_ROOT!"
    exit 1
fi

echo ""
echo "╔═════════════════════════════════════════════════════════════════════════════════╗"
print_row "1. Restoring backup:"

from_path="   ● from: $LATEST_BACKUP"
to_path="   ●   to: $CONFIG_DIR"

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
print_row "2. Removing Sandworm-related config blocks:"

from_path="   ● from: $MOONRAKER_CONF"
formatted_from=$(printf "%-82s" "$from_path")
echo -e "║ $formatted_from║"

if [ ! -f "$MOONRAKER_CONF" ]; then
    print_row ""
    print_row "   $ERROR moonraker.conf not found!"
else
    sed -i '/^\[update_manager Sandworm\]/,/^\[/{
        /^\[update_manager Sandworm\]/d
        /^\[power printer\]/!{/^\[/!d}
    }' "$MOONRAKER_CONF"

    sed -i '/^\[power printer\]/,/^\[/{
        /^\[power printer\]/d
        /^\[update_manager Sandworm\]/!{/^\[/!d}
    }' "$MOONRAKER_CONF"

    # --- Also handle EOF case ---
    # Delete trailing block if it's the last in file (no new [section])
    sed -i '/^\[update_manager Sandworm\]/,$d' "$MOONRAKER_CONF"
    sed -i '/^\[power printer\]/,$d' "$MOONRAKER_CONF"
    print_row ""
    print_row "   $OK Config blocks removed."
fi

# --- Step 3: Delete ~/Sandworm directory safely ---
print_row ""
echo "╟─────────────────────────────────────────────────────────────────────────────────╢"

if [ -d "$SANDWORM_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ "$SCRIPT_DIR" == "$SANDWORM_DIR"* ]]; then
        print_row "3. $INFO Moving the running script out of the ~Sandworm folder..."
        cd /tmp || exit 1
    fi

    PRESERVE_DIR="$HOME/Sandworm_backups"

    if [ -d "$SANDWORM_DIR/backup" ]; then
        print_row "   $INFO Preserving backup folder..."

        # Delete old folder, if exist:
        rm -rf "$PRESERVE_DIR/backup"

        mkdir -p "$PRESERVE_DIR"
        mv "$SANDWORM_DIR/backup" "$PRESERVE_DIR/"

        print_row "   $OK Backup moved to: $PRESERVE_DIR/backup"
    fi


    print_row ""
    print_row "   Deleting directory: $SANDWORM_DIR"
    rm -rf "$SANDWORM_DIR"
    print_row "   $OK Sandworm directory removed."
else
    print_row ""
    print_row "   $SKIPPED No Sandworm directory found to delete."
fi

# --- Done ---
print_row ""
echo "╟─────────────────────────────────────────────────────────────────────────────────╢"
print_row "$INFO To apply the changes, please restart Moonraker using the [Y] option."
print_row "$INFO Uninstall log saved to:"
echo -e "║    ● $LOGFILE      ║"
print_row ""
print_row "$OK Sandworm macros have been uninstalled successfully!"
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
