#!/bin/bash

## --- Trap ---
set -Ee
trap 'echo -e "$ERROR Script failed at line $LINENO"' ERR

## --- Brake line after git clone messages ---
echo -e ""

# --- Paths ---
SANDWORM_REPO="$HOME/Sandworm/config"
CONFIG_DIR="$HOME/printer_data/config"
MOONRAKER_CONF="$CONFIG_DIR/moonraker.conf"
BACKUP_DIR="$HOME/Sandworm/backup/backup_config_$(date +%Y_%m_%d-%Hh%Mm)"
HOOK_PATH="$HOME/Sandworm/.git/hooks/post-merge"
LOGFILE="$HOME/printer_data/logs/sandworm_update.log"
TMP_LOG_DIR="$HOME/Sandworm/tmp"
TMP_UPDATE_LOG="$TMP_LOG_DIR/sandworm_tmp_update.log"

# --- Sources ---
source "$HOME/Sandworm/tools/game_intro.sh"
source "$HOME/Sandworm/tools/game_intro_ascii.sh"

## --- Message status ---
OK="[OK]"
INFO="[INFO]"
SKIPPED="[SKIPPED]"
ERROR="[ERROR]"
MESS_DELAY=0.8
MESS_sDELAY=0.2

print_row() {
    local msg="$1"
    printf "║ %-79s ║\n" "$msg"
}

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

    # ASCII intro to log
    exec 4>"$LOGFILE"
    print_game_intro_ascii >&4
    exec 4>&-

    # stdout/stderr to log and tee (append instead of rewrite)
    exec > >(tee -a "$LOGFILE") 2>&1
    exec 3>/dev/tty

    # colors intro to console output
    draw_game_intro >&3
else
    exec > >(tee "$TMP_UPDATE_LOG") 2>&1
fi

## --- Message Header ---
start_message() {
    if [[ "$IS_COLD_INSTALL" = true ]]; then
        echo -e "╔════════════════════════════════════════════╗"
        echo -e "║             ** Cold Install **             ║"
        echo -e "╠════════════════════════════════════════════╩════════════════════════════════════╗"     
        print_row "Started: $(date)"    
        print_row "Git version: $VERSION"     
        print_row "Install version: $CUSTOM_VERSION"     
        print_row ""
        print_row "Starting installation of automatic Sandworm updates..."
		sleep $MESS_sDELAY
        print_row ""
    else
        echo -e "╔════════════════════════════════════════════╗"
        echo -e "║                ** Update **                ║"
        echo -e "╚════════════════════════════════════════════╝"
        echo -e "Started: $(date)"
        echo -e "Git version: $VERSION"
        echo -e "Game version: $CUSTOM_VERSION"
        echo -e ""
        echo -e "Starting update of Sandworm macros..."
    fi		
}

## --- countdown progress bar ---
fancy_restart_bar() {
    sleep 0.4  # initial delay

    for i in {24..0}; do
        if [ "$i" -eq 24 ]; then
            empty=""
        else
            empty=$(printf '□%.0s' $(seq 1 $((24 - i))))
        fi

        if [ "$i" -eq 0 ]; then
            filled=""
        else
            filled=$(printf '■%.0s' $(seq 1 $i))
        fi

        echo -ne "${G2}[$filled$empty]\r${C0}" >&3
        sleep 0.2
    done
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

        print_row "$OK Git post-merge hook created at: $HOOK_PATH"       
    else
        print_row "$SKIPPED Git post-merge hook already exists."
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
    echo "║                                                                                 ║"
    echo -e "╟─────────────────────────────────────────────────────────────────────────────────╢"
    echo -e "║ $OK Added [update_manager Sandworm] config block to: moonraker.conf            ║"  
}

add_power_printer_block() {
    echo -e "\n[power printer]
type: gpio
pin: gpiochip0/gpio72               # Can be reversed with "!", (Bigtreetech PI V1.2 GPIO pin PC8)
initial_state: off
off_when_shutdown: True             # Turn off power on shutdown/error
locked_while_printing: True         # Prevent power-off during a print
restart_klipper_when_powered: True
restart_delay: 1
bound_service: klipper              # Ensures Klipper service starts/restarts with power toggle" >> "$MOONRAKER_CONF"
    echo -e "║ $OK Added [power printer] config block to: moonraker.conf                      ║"   
}

backup_files() {
    echo -e "╟─────────────────────────────────────────────────────────────────────────────────╢"
    echo -e "║ Creating backup of the printer config directory:                                ║"   

    from_path="  ● from: $CONFIG_DIR"
    to_path="  ●   to: $BACKUP_DIR"
    
    formatted_from=$(printf "%-82s" "$from_path")
    formatted_to=$(printf "%-82s" "$to_path")
    
    echo -e "║ $formatted_from║"  
    echo -e "║ $formatted_to║"  

    mkdir -p "$BACKUP_DIR"
    cp -r "$CONFIG_DIR/"* "$BACKUP_DIR/" || echo -e "$ERROR Backup failed!"
    
    echo "║                                                                                 ║"
    echo -e "║ $OK Backup complete.                                                           ║"
    sleep $MESS_sDELAY
}

backup_files_update() {
    echo ""
    echo "──────────────────────────────────────────────"
    echo "Creating backup of the printer config directory:"  
    echo "  ● from: $CONFIG_DIR" 
    echo "  ●   to: $BACKUP_DIR"  

    mkdir -p "$BACKUP_DIR"
    cp -r "$CONFIG_DIR/"* "$BACKUP_DIR/" || echo -e "$ERROR Backup failed!"
    echo ""
    echo "$OK Backup complete."
    sleep $MESS_DELAY
}

copy_files() {
    echo "║                                                                                 ║"
    echo -e "╟─────────────────────────────────────────────────────────────────────────────────╢"
    echo -e "║ Copying new files:                                                              ║"  

    from_path="  ● from: $SANDWORM_REPO"
    to_path="  ●   to: $CONFIG_DIR"
    
    formatted_from=$(printf "%-82s" "$from_path")
    formatted_to=$(printf "%-82s" "$to_path")

    echo -e "║ $formatted_from║"   
    echo -e "║ $formatted_to║"  

    echo "║                                                                                 ║"

    mkdir -p "$CONFIG_DIR"
    RSYNC_OUTPUT=$(rsync -av "$SANDWORM_REPO/" "$CONFIG_DIR/")

    # výpis zarovnaného rsync výstupu
    while IFS= read -r line; do
        formatted_line=$(printf "%-78s" "$line")
        echo -e "║ $formatted_line  ║"
    done <<< "$RSYNC_OUTPUT"

    echo "║                                                                                 ║"
    echo -e "║ $OK Copying completed.                                                         ║"
    sleep $MESS_sDELAY
}

copy_files_update() {
    echo ""
    echo "──────────────────────────────────────────────"
    echo "Copying new files:"  
    echo "  ● from: $SANDWORM_REPO"
    echo "  ●   to: $CONFIG_DIR"

    echo ""
    mkdir -p "$CONFIG_DIR"
    rsync -av "$SANDWORM_REPO/" "$CONFIG_DIR/"
    sleep 0.5
    echo ""
    
    echo "$OK Copying completed."
    sleep $MESS_DELAY
}

restart_klipper() {
    echo ""
    echo -e "Restarting Klipper to load new config..."
    sleep 5
    curl --no-progress-meter -X POST 'http://localhost:7125/printer/restart' > /dev/null 2>&1
}

restart_moonraker() {
    read -rp "Do you want to restart Moonraker now to apply changes? [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then

        echo -e "Restarting Moonraker service in 5 seconds..."
        fancy_restart_bar

        curl --no-progress-meter -X POST http://localhost:7125/server/restart > /dev/null 2>&1

    else
        echo ""
        echo -e "$INFO Moonraker restart skipped. Changes have not been applied!"
        echo -e "But you can restart Moonraker manually later via:"
        echo -e "  1. The web interface: Power -→ Service Control -→ Moonraker"
        echo -e "  2. Command line: curl -X POST http://localhost:7125/server/restart"
    fi
}

## --- Execution ---
start_message

if [ "$IS_COLD_INSTALL" = true ]; then
    mkdir -p "$HOME/Sandworm/config"

    backup_files
    copy_files 
    add_update_manager_block

    if ! grep -q "^\[power printer\]" "$MOONRAKER_CONF" 2>/dev/null; then
        add_power_printer_block
    else
        echo -e "║ $SKIPPED [power printer] already exists in moonraker.conf                      ║"
    fi

    create_post_merge_hook  

    echo -e "║ $OK The Sandworm installation was completed successfully!                      ║"   
    echo "║                                                                                 ║"
    echo -e "║ $INFO ⚠️ After restarting, please refresh the web interface (press F5)         ║"
    echo -e "║ to clear the memory and avoid UI cache issues (duplicate folders, etc).         ║"
    echo -e "╚═════════════════════════════════════════════════════════════════════════════════╝"
    sleep $MESS_DELAY
    echo ""
    restart_moonraker
    echo ""
else
    if [ ! -d "$SANDWORM_REPO" ]; then
        echo -e "$ERROR Source repo directory $SANDWORM_REPO not found!"
        exit 1
    fi

    backup_files_update
    copy_files_update

    echo -e ""
    echo -e "┌─────────────────────────────────────────────────────────────────────────"
    echo -e "│ ** NOTES: **"
    echo -e "│ ✅ The Sandworm update was completed successfully!"
    echo -e "│ 💾 Your config folder was backed up at: $BACKUP_DIR"
    echo -e "│ 📜 For full update details, see the log: $LOGFILE"
    echo -e "│ ⚠️ After restarting, please refresh the Klipper web interface (press F5)"
    echo -e "│ to clear the memory and avoid UI cache issues (duplicate folders, etc)."
    echo -e "└─────────────────────────────────────────────────────────────────────────"
    echo -e ""

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