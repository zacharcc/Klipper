#!/bin/bash

# Debug:
#!/bin/bash
echo "DEBUG: install.sh was called" >> /tmp/sandworm_debug.log


# --- Trap ---
set -Ee
trap 'echo -e "$ERROR Script failed at line $LINENO"' ERR

# --- Brake line after git clone messages ---
echo ""

# --- Paths ---
# SANDWORM_REPO="$HOME/Sandworm/config"
# CONFIG_DIR="$HOME/printer_data/config"
# MOONRAKER_CONF="$CONFIG_DIR/moonraker.conf"
SANDWORM_REPO="$HOME/Sandworm/test"
CONFIG_DIR="$HOME/printer_data/config/TEST/update_test"
MOONRAKER_CONF="$HOME/printer_data/config/moonraker.conf"
BACKUP_DIR="$HOME/Sandworm/backup/backup_config_$(date +%Y_%m_%d-%Hh%Mm)"
LOGFILE="$HOME/printer_data/logs/sandworm_update.log"
TMP_LOG_DIR="$HOME/Sandworm/tmp"
TMP_UPDATE_LOG="$TMP_LOG_DIR/sandworm_tmp_update.log"

# --- Colors (for plain SSH/logs compatibility) ---
OK="[OK]"
INFO="[INFO]"
SKIPPED="[SKIPPED]"
ERROR="[ERROR]"

# --- Git Version ---
if git -C "$HOME/Sandworm" tag | grep -q .; then
    VERSION=$(git -C "$HOME/Sandworm" describe --tags --exact-match 2>/dev/null)
    if [ -z "$VERSION" ]; then
        VERSION=$(git -C "$HOME/Sandworm" describe --tags --always | cut -d '-' -f 1)
    fi
else
    VERSION=$(git -C "$HOME/Sandworm" rev-parse --short HEAD)
fi

# --- Custom version from version.txt ---
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
    exec > >(tee "$LOGFILE") 2>&1 
    exec 3>/dev/tty
else
    exec > >(tee "$TMP_UPDATE_LOG") 2>&1  # temporary update log
fi

# --- Message Header ---
start_message() {
    if [[ "$IS_COLD_INSTALL" = true ]]; then
        echo "============ Cold Install ============"
    else
        echo ""
        echo "============= Update ================="
    fi
    echo "Started: $(date)"
    echo "Git version: $VERSION"
    echo "Custom version: $CUSTOM_VERSION"
    echo ""
    if [[ "$IS_COLD_INSTALL" = true ]]; then
        echo "Starting installation of automatic Sandworm updates..."
    else
        echo "Starting update of Sandworm macros..."
    fi
    echo ""
}

# --- countdown progress bar ---
fancy_restart_bar() {
    sleep 0.6

    for i in {8..0}; do
        if [ "$i" -eq 8 ]; then
            empty=""
        else
            empty=$(printf '□ %.0s' $(seq 1 $((8 - i))))
        fi

        if [ "$i" -eq 0 ]; then
            filled=""
        else
            filled=$(printf '■ %.0s' $(seq 1 $i))
        fi

        # Tiskni pouze do terminálu (ne do logu)
        echo -ne "[$filled$empty]\r" >&3
        sleep 0.6
    done
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
    echo ""
    echo "--------------------------------------"
    echo -e "$OK Added [update_manager Sandworm] configuration block to moonraker.conf"
}

backup_files() {
    echo "Creating backup of the config directory in: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    cp -r "$CONFIG_DIR/"* "$BACKUP_DIR/" || echo -e "$ERROR Backup failed!"
    echo "$OK Backup complete – Saved to: $BACKUP_DIR"
}

copy_files() {
    echo ""
    echo "--------------------------------------"
    echo "Copying new files from: $SANDWORM_REPO to: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
    rsync -av "$SANDWORM_REPO/" "$CONFIG_DIR/"
    echo "$OK Copying completed."
}

restart_klipper() {
    echo ""
    echo "Restarting Klipper to load new config..."
    sleep 5
    curl -X POST 'http://localhost:7125/printer/restart'
}

restart_moonraker() {
    echo ""
    echo "Restarting Moonraker to apply config changes..."
    fancy_restart_bar
    sudo systemctl restart moonraker
}

# --- Execution ---
start_message

if [ "$IS_COLD_INSTALL" = true ]; then
    mkdir -p "$HOME/Sandworm/config"
    backup_files
    copy_files

    if ! grep -q "^\[update_manager Sandworm\]" "$MOONRAKER_CONF" 2>/dev/null; then
        add_update_manager_block
    else
        echo -e "$SKIPPED update_manager already exists in moonraker.conf"
    fi

    echo -e "$OK The Sandworm installation was completed successfully!"
    restart_moonraker

else
    if [ ! -d "$SANDWORM_REPO" ]; then
        echo -e "$ERROR Source repo directory $SANDWORM_REPO not found!"
        exit 1
    fi

    backup_files
    copy_files

    echo -e "$OK The Sandworm update was completed successfully!"
    echo -e "$INFO (Your config was backed up at: $BACKUP_DIR ,"
    echo -e "$INFO so if you had custom changes, check backup manually)."

    # Replace previous update block with new one in log
    if [ -f "$LOGFILE" ]; then
        awk '
            BEGIN { skip=0 }
            /^=+ Update =+/ { skip=1; next }
            skip && /^=+/ && !/^=+ Update =+/ { skip=0 }
            !skip
        ' "$LOGFILE" > "${LOGFILE}.tmp"
        cat "$TMP_UPDATE_LOG" >> "${LOGFILE}.tmp"
        mv "${LOGFILE}.tmp" "$LOGFILE"
    else
        cat "$TMP_UPDATE_LOG" > "$LOGFILE"
    fi
    rm "$TMP_UPDATE_LOG"

    restart_klipper
fi
