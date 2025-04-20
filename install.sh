#!/bin/bash

## --- Trap ---
set -Ee
trap 'echo -e "$ERROR Script failed at line $LINENO"' ERR

## --- Brake line after git clone messages ---
echo ""

# --- Paths ---
# CONFIG_DIR="$HOME/printer_data/config"
# MOONRAKER_CONF="$CONFIG_DIR/moonraker.conf"
SANDWORM_REPO="$HOME/Sandworm/config"
CONFIG_DIR="$HOME/printer_data/config/TEST/update_test"
MOONRAKER_CONF="$HOME/printer_data/config/moonraker.conf"
BACKUP_DIR="$HOME/Sandworm/backup/backup_config_$(date +%Y_%m_%d-%Hh%Mm)"
HOOK_PATH="$HOME/Sandworm/.git/hooks/post-merge"
LOGFILE="$HOME/printer_data/logs/sandworm_update.log"
TMP_LOG_DIR="$HOME/Sandworm/tmp"
TMP_UPDATE_LOG="$TMP_LOG_DIR/sandworm_tmp_update.log"

# --- Sources ---
source "$HOME/Sandworm/tools/game_intro.sh"
source "$HOME/Sandworm/tools/game_intro_ascii.sh"

## --- Colors (for plain SSH/logs compatibility) ---
OK="[OK]"
INFO="[INFO]"
SKIPPED="[SKIPPED]"
ERROR="[ERROR]"

## --- Git Version ---
if [ -d "$HOME/Sandworm/.git" ]; then
    VERSION=$(git -C "$HOME/Sandworm" describe --tags --exact-match 2>/dev/null || \
              git -C "$HOME/Sandworm" describe --tags --always 2>/dev/null | cut -d '-' -f 1 || \
              git -C "$HOME/Sandworm" rev-parse --short HEAD 2>/dev/null)
else
    VERSION="unknown"
fi

## --- Custom version from version.txt ---
VERSION_FILE="$HOME/Sandworm/version.txt"
if [ -f "$VERSION_FILE" ]; then
    CUSTOM_VERSION=$(head -n 1 "$VERSION_FILE" | tr -d '\r')
else
    CUSTOM_VERSION="N/A"
fi

set_game_variables() {
    if [ -f "$VERSION_FILE" ]; then
        source "$VERSION_FILE"
        : "${game_save:=0}"
        : "${level:=0}"
    else
        game_save=0
        level=0
    fi

    formatted_game_save=$(printf "%4s" "$game_save")
    formatted_level=$(printf "%02d" "$level")
}

## --- Cold Install Detection ---
IS_COLD_INSTALL=false
if [ ! -f "$MOONRAKER_CONF" ]; then
    echo -e "$ERROR moonraker.conf not found: $MOONRAKER_CONF"
    IS_COLD_INSTALL=true
elif ! grep -q "^\[update_manager Sandworm\]" "$MOONRAKER_CONF"; then
    IS_COLD_INSTALL=true
fi

## ---  Logging setup ---
mkdir -p "$TMP_LOG_DIR"
if [ "$IS_COLD_INSTALL" = true ]; then
    set_game_variables

    # ASCII do logu (přes FD 4)
    exec 4>"$LOGFILE"
    print_game_intro_ascii >&4
    exec 4>&-

    # stdout/stderr do logu a tee
    exec > >(tee "$LOGFILE") 2>&1
    exec 3>/dev/tty

    # barevné intro do konzole
    draw_game_intro >&3
else
    exec > >(tee "$TMP_UPDATE_LOG") 2>&1
    echo "Update version: $CUSTOM_VERSION"
fi


## --- Message Header ---
start_message() {
    if [[ "$IS_COLD_INSTALL" = true ]]; then
        echo "============== Cold Install =============="
    else
        echo "================= Update ================="
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
}

## --- countdown progress bar ---
fancy_restart_bar() {
    sleep 0.4

    for i in {12..0}; do
        if [ "$i" -eq 12 ]; then
            empty=""
        else
            empty=$(printf '□%.0s' $(seq 1 $((12 - i))))
        fi

        if [ "$i" -eq 0 ]; then
            filled=""
        else
            filled=$(printf '■%.0s' $(seq 1 $i))
        fi

        echo -ne "[$filled$empty]\r" >&3
        sleep 0.6
    done
    echo ""
    echo ""
}

## --- Functions ---

create_post_merge_hook() {
    if [ ! -f "$HOOK_PATH" ]; then
        cat << 'EOF' > "$HOOK_PATH"
#!/bin/bash
/home/biqu/Sandworm/install.sh
EOF
        chmod +x "$HOOK_PATH"
        echo "$OK Git post-merge hook created at: $HOOK_PATH"
    else
        echo "$SKIPPED Git post-merge hook already exists."
    fi
}

add_update_manager_block() {
    echo -e "\n[update_manager Sandworm]
type: git_repo
origin: https://github.com/zacharcc/Klipper.git
path: ~/Sandworm
primary_branch: test
managed_services: klipper
install_script: install.sh" >> "$MOONRAKER_CONF"
    echo ""
    echo "------------------------------------------"
    echo -e "$OK Added [update_manager Sandworm] config block to: moonraker.conf"
}

backup_files() {
    echo ""
    echo "------------------------------------------"
    echo "Creating backup of the printer config directory:"
	echo "  ● from: $CONFIG_DIR"
	echo "  ●   to: $BACKUP_DIR"
	
    mkdir -p "$BACKUP_DIR"
    cp -r "$CONFIG_DIR/"* "$BACKUP_DIR/" || echo -e "$ERROR Backup failed!"
    echo ""
    echo "$OK Backup complete."
}

copy_files() {
    echo ""
    echo "------------------------------------------"
    echo "Copying new files:"
    echo "  ● from: $SANDWORM_REPO"
	echo "  ●   to: $CONFIG_DIR"
	
    echo ""
    mkdir -p "$CONFIG_DIR"
    rsync -av "$SANDWORM_REPO/" "$CONFIG_DIR/"
    echo ""
    
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
    read -rp "Do you want to restart Moonraker now to apply changes? [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
	
        echo "Restarting Moonraker service in 5 seconds..."
        fancy_restart_bar

        curl -X POST http://localhost:7125/server/restart

    else
	    echo ""
        echo -e "$INFO Moonraker restart skipped. Changes have not been applied!"
		echo -e "But you can restart Moonraker manually later via:"
        echo -e "  1. The web interface: Power -→ Service Control -→ Moonraker"
        echo -e "  2. Command line: curl -X POST http://localhost:7125/server/restart"
    fi
	echo ""
}

## --- Execution ---
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

    create_post_merge_hook  

    echo -e "$OK The Sandworm installation was completed successfully!"
    restart_moonraker

else
    if [ ! -d "$SANDWORM_REPO" ]; then
        echo -e "$ERROR Source repo directory $SANDWORM_REPO not found!"
        exit 1
    fi

    echo "Update version: $CUSTOM_VERSION"

    backup_files
    copy_files

    echo ""
    echo "------------------------------------------"
    echo -e "$OK The Sandworm update was completed successfully!"
    echo -e "$INFO Your config folder was backed up at: $BACKUP_DIR"
    echo ""
    echo ""

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