#!/bin/bash

# Debug log (persistent)
DEBUG_LOG="$HOME/Sandworm/debug/debug.log"
mkdir -p "$(dirname "$DEBUG_LOG")"
echo "DEBUG: install.sh was called" >> "$DEBUG_LOG"


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
# --- Git Version ---
if [ -d "$HOME/Sandworm/.git" ]; then
    VERSION=$(git -C "$HOME/Sandworm" describe --tags --exact-match 2>/dev/null || \
              git -C "$HOME/Sandworm" describe --tags --always 2>/dev/null | cut -d '-' -f 1 || \
              git -C "$HOME/Sandworm" rev-parse --short HEAD 2>/dev/null)
else
    VERSION="unknown"
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

        echo -ne "[$filled$empty]\r" >&3
        sleep 0.6
    done
}

# --- Functions ---
link_config_folder() {
    if [ ! -L "$CONFIG_DIR/Sandworm" ]; then
        ln -s "$HOME/Sandworm/test" "$CONFIG_DIR/Sandworm"
        echo "$OK Symlink created: $CONFIG_DIR/Sandworm › $HOME/Sandworm/test"
    else
        echo "$SKIPPED Symlink already exists: $CONFIG_DIR/Sandworm"
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
    link_config_folder

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


-----------------------------------------------------

git clone https://github.com/zacharcc/Klipper.git ~/Sandworm && bash ~/Sandworm/install.sh
# branch test
git clone --branch test https://github.com/zacharcc/Klipper.git ~/Sandworm && bash ~/Sandworm/install.sh


13:01:30	Updating Application Sandworm...
13:01:30	Git Repo Sandworm: Updating Repo...
13:01:31	hint: Pulling without specifying how to reconcile divergent branches is
13:01:31	hint: discouraged. You can squelch this message by running one of the following
13:01:31	hint: commands sometime before your next pull:
13:01:31	hint:
13:01:31	hint: git config pull.rebase false # merge (the default strategy)
13:01:31	hint: git config pull.rebase true # rebase
13:01:31	hint: git config pull.ff only # fast-forward only
13:01:31	hint:
13:01:31	hint: You can replace "git config" with "git config --global" to set a default
13:01:31	hint: preference for all repositories. You can also pass --rebase, --no-rebase,
13:01:31	hint: or --ff-only on the command line to override the configured default per
13:01:31	hint: invocation.
13:01:32	Updating 9746cd5..8d80d40
13:01:32	Fast-forward
13:01:32	test/macro2.cfg | 2 +-
13:01:32	1 file changed, 1 insertion(+), 1 deletion(-)
13:01:33	Git Repo Sandworm: Restarting service klipper...
13:01:33	Git Repo Sandworm: Update Finished...


