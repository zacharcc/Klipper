#!/bin/bash

## --- Trap ---
set -Ee
trap 'echo -e "$ERROR Script failed at line $LINENO"' ERR

## --- Brake line after git clone messages ---

# --- Paths ---
CONFIG_DIR="$HOME/printer_data/config"
MOONRAKER_CONF="$CONFIG_DIR/moonraker.conf"
SANDWORM_REPO="$HOME/Sandworm/config"
BACKUP_DIR="$HOME/Sandworm/backup/backup_config_$(date +%Y_%m_%d-%Hh%Mm)"
HOOK_PATH="$HOME/Sandworm/.git/hooks/post-merge"
LOGFILE="$HOME/printer_data/logs/sandworm_update.log"
TMP_LOG_DIR="$HOME/Sandworm/tmp"
TMP_UPDATE_LOG="$TMP_LOG_DIR/sandworm_tmp_update.log"

## --- Message status ---
OK="[OK]"
INFO="[INFO]"
SKIPPED="[SKIPPED]"
ERROR="[ERROR]"
MESS_DELAY=0.8
MESS_sDELAY=0.2

# --- Sources ---
source "$HOME/Sandworm/tools/translate.sh"
source "$HOME/Sandworm/tools/game_intro.sh"
source "$HOME/Sandworm/tools/game_intro_ascii.sh"

print_row() {
    local msg="$1"
    local visible_length=$(echo -n "$msg" | wc -m)
    local total_width=82
    local padding=$((total_width - visible_length))
    [ $padding -lt 0 ] && padding=0
    printf "║ %s%*s ║\n" "$msg" "$padding" ""
}

open_box() {
    echo -e "╔════════════════════════════════════════════════════════════════════════════════════╗"
}

close_box() {
    echo -e "╚════════════════════════════════════════════════════════════════════════════════════╝"
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

# Function: Interactive language selector (← →) + (Enter):
select_lang() {
    local options=("English" "Czech" "German")
    local lang_codes=(1 2 3)
    local selected=0

    GREEN="\033[1;32m"
    RESET="\033[0m"

    echo "" > /dev/tty
    echo -e "Select language using arrows ${GREEN}(← →)${RESET}, confirm with [Enter]:" > /dev/tty

    draw_selector() {
        echo -ne "\r\033[K" > /dev/tty
        for i in "${!options[@]}"; do
            if [[ $i -eq $selected ]]; then
                echo -ne "${GREEN}[${options[$i]}]${RESET} " > /dev/tty
            else
                echo -ne " ${options[$i]}  " > /dev/tty
            fi
        done
    }

    draw_selector
    while true; do
        IFS= read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 -t 0.1 key
            if [[ $key == "[C" ]]; then
                selected=$(( (selected + 1) % ${#options[@]} ))
            elif [[ $key == "[D" ]]; then
                selected=$(( (selected - 1 + ${#options[@]}) % ${#options[@]} ))
            fi
        elif [[ $key == "" ]]; then
            break
        fi
        echo -ne "\r\033[K" > /dev/tty
        draw_selector
    done

    echo "" > /dev/tty
    export LANG_SELECTED=${lang_codes[$selected]}
    echo "$OK Language selected: ${options[$selected]} (lang=$LANG_SELECTED)"
}

if [ "$IS_COLD_INSTALL" = true ]; then
    select_lang
fi

# Set value in variables.cfg
set_variable_cfg() {
    local key="$1"
    local value="$2"
    local file="$HOME/printer_data/config/variables.cfg"

    if [ ! -f "$file" ]; then
        print_row "$(translate_string "$LANG_SELECTED" "skipped_variables")"
        from_path="  ● $file"
        formatted_at=$(printf "%-86s" "$from_path")
        echo -e "║$formatted_at║"
        return
    fi

    if grep -q "^$key\s*=" "$file"; then
        sed -i "s/^$key\s*=.*/$key = $value/" "$file"
        if [ "$IS_COLD_INSTALL" = true ]; then
            # Dynamic key to the translator, e.g. "set_update_msg"
            print_row "$(translate_string "$LANG_SELECTED" "set_${key}")"
        else
            echo -e "$OK Updated $key to $value in variables.cfg"
        fi
    else
        print_row "$SKIPPED Variable '$key' not found in variables.cfg"
    fi
}

## ---  Logging setup ---
mkdir -p "$TMP_LOG_DIR"
if [ "$IS_COLD_INSTALL" = true ]; then
    set_game_variables

    # ASCII intro to log
    exec 4>"$LOGFILE"
    print_game_intro_ascii >&4
    exec 4>&-

    # stdout/stderr do logu a tee (append místo přepisu)
    exec > >(tee -a "$LOGFILE") 2>&1
    exec 3>/dev/tty

    # color intro to console
    draw_game_intro >&3
else
    exec > >(tee "$TMP_UPDATE_LOG") 2>&1
fi

## ---  Conditional GPIO settings ---
setup_gpio_permissions() {
    echo -e "║                                                                                    ║"
    echo -e "╟────────────────────────────────────────────────────────────────────────────────────╢"
    print_row "$(translate_string "$LANG_SELECTED" "gpio_header")"
    echo -e "║                                                                                    ║"

    LOCAL_USER=$(logname 2>/dev/null || echo "$USER")
    MODEL=$(tr -d '\0' < /proc/device-tree/model 2>/dev/null || echo "unknown")

    print_row "$(translate_string "$LANG_SELECTED" "gpio_info")"
    print_row ""

    # Raspberry Pi = everything without sudo → no table breaks
    if echo "$MODEL" | grep -qi "Raspberry Pi"; then
        print_row "$(translate_string "$LANG_SELECTED" "gpio_rpi_skip")"
        return
    fi

    GROUP_CREATE_NEEDED=0
    USER_ADD_NEEDED=0

    # check whether groupadd is needed
    if ! getent group gpio >/dev/null; then
        GROUP_CREATE_NEEDED=1
    fi

    # check if usermod is needed
    if ! groups "$LOCAL_USER" | grep -qw gpio; then
        USER_ADD_NEEDED=1
    fi

    # If sudo is not needed → everything inside the table
    if [ $GROUP_CREATE_NEEDED -eq 0 ] && [ $USER_ADD_NEEDED -eq 0 ]; then
        print_row "$(translate_string "$LANG_SELECTED" "gpio_exists")"
        print_row "$(translate_string "$LANG_SELECTED" "gpio_user_exists")"
        return
    fi

    # Table break due to sudo
    close_box

    # Sudo section
    if [ $GROUP_CREATE_NEEDED -eq 1 ]; then
        sudo groupadd gpio
    fi

    if [ $USER_ADD_NEEDED -eq 1 ]; then
        sudo usermod -aG gpio "$LOCAL_USER"
    fi

    sudo udevadm control --reload-rules
    sudo udevadm trigger

    open_box

    # all sudo-rows in one table:
    [ $GROUP_CREATE_NEEDED -eq 1 ] && \
        print_row "$(translate_string "$LANG_SELECTED" "gpio_create")"

    [ $USER_ADD_NEEDED -eq 1 ] && \
        print_row "$(translate_string "$LANG_SELECTED" "gpio_add_user")"

    print_row ""
    print_row "$(translate_string "$LANG_SELECTED" "gpio_done")"
}

## --- Message Header ---
start_message() {
    if [[ "$IS_COLD_INSTALL" = true ]]; then
        echo -e "╔════════════════════════════════════════════╗"
        translate_echo "$LANG_SELECTED" "title_cold_install"
        echo -e "╠════════════════════════════════════════════╩═══════════════════════════════════════╗"
        print_row "$(translate_string "$LANG_SELECTED" "start_date")"
        print_row "$(translate_string "$LANG_SELECTED" "git_version")"
        print_row "$(translate_string "$LANG_SELECTED" "install_version")"
        print_row ""
        print_row "$(translate_string "$LANG_SELECTED" "description")"
        print_row ""
    else
        echo -e "╔════════════════════════════════════════════╗"
        echo -e "║           ** Sandworm Update **            ║"
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
backup_files() {
    echo -e "╟────────────────────────────────────────────────────────────────────────────────────╢"
    print_row "$(translate_string "$LANG_SELECTED" "backup")"
   
    from_path="  ● $(translate_string "$LANG_SELECTED" "from") $CONFIG_DIR"
    to_path="  ● $(translate_string "$LANG_SELECTED" "to") $BACKUP_DIR"

    formatted_from=$(printf "%-85s" "$from_path")
    formatted_to=$(printf "%-85s" "$to_path")
    
    echo -e "║ $formatted_from║"  
    echo -e "║ $formatted_to║"
   
    mkdir -p "$BACKUP_DIR"
    cp -r "$CONFIG_DIR"/. "$BACKUP_DIR"/ || echo -e "$ERROR Backup failed!"
    
    print_row ""
    print_row "$(translate_string "$LANG_SELECTED" "backup_done")"
    sleep $MESS_sDELAY
}

backup_files_update() {
    echo ""
    echo "─────────────────────────────────────────────────────────────────────────────────────"
    echo "Creating backup of the printer config directory:"  
    echo "  ● from: $CONFIG_DIR"  
    echo "  ●   to: $BACKUP_DIR"  

    mkdir -p "$BACKUP_DIR"
    cp -r "$CONFIG_DIR"/. "$BACKUP_DIR"/ || echo -e "$ERROR Backup failed!"
    echo ""
    echo "$OK Backup complete."
    sleep $MESS_sDELAY
}

copy_files() {
    echo -e "║                                                                                    ║"
    echo -e "╟────────────────────────────────────────────────────────────────────────────────────╢"
    print_row "$(translate_string "$LANG_SELECTED" "copy")"

    from_path="  ● $(translate_string "$LANG_SELECTED" "from") $SANDWORM_REPO"
    to_path="  ● $(translate_string "$LANG_SELECTED" "to") $CONFIG_DIR"

    formatted_from=$(printf "%-85s" "$from_path")
    formatted_to=$(printf "%-85s" "$to_path")

    echo -e "║ $formatted_from║"  
    echo -e "║ $formatted_to║" 
    print_row ""

    mkdir -p "$CONFIG_DIR"
    RSYNC_OUTPUT=$(rsync -av "$SANDWORM_REPO/" "$CONFIG_DIR/")

    # rsync output in rows:
    while IFS= read -r line; do
        formatted_line=$(printf "%-81s" "$line")
        echo -e "║ $formatted_line  ║"
    done <<< "$RSYNC_OUTPUT"

    print_row ""
    print_row "$(translate_string "$LANG_SELECTED" "copying_done")"
    sleep $MESS_sDELAY
}

copy_files_update() {
    echo ""
    echo "─────────────────────────────────────────────────────────────────────────────────────"
    echo "Copying new files:"
    echo "  ● from: $SANDWORM_REPO"
    echo "  ●   to: $CONFIG_DIR"

    echo ""
    mkdir -p "$CONFIG_DIR"
    rsync -av --exclude 'printer.cfg' "$SANDWORM_REPO/" "$CONFIG_DIR/"
    sleep 0.5
    echo ""
    
    echo "$OK Copying completed."
    sleep $MESS_sDELAY
}

ensure_trailing_newline() {
    # Pokud poslední byte není newline → přidáme jeden
    if [ -f "$MOONRAKER_CONF" ] && [ -s "$MOONRAKER_CONF" ]; then
        if [ "$(tail -c1 "$MOONRAKER_CONF" | wc -l)" -eq 0 ]; then
            echo "" >> "$MOONRAKER_CONF"
        fi
    fi
}

add_update_manager_block() {
    ensure_trailing_newline
    printf "\n[update_manager Sandworm]\n\
type: git_repo\n\
origin: https://github.com/Urobotos/Sandworm.git\n\
path: ~/Sandworm\n\
primary_branch: main\n\
managed_services: klipper\n\
install_script: install.sh\n" >> "$MOONRAKER_CONF"

    echo -e "║                                                                                    ║"
    echo -e "╟────────────────────────────────────────────────────────────────────────────────────╢"
    print_row "$(translate_string "$LANG_SELECTED" "add_update_manager")"
}

add_power_printer_block() {
    ensure_trailing_newline
    printf "\n[power printer]\n\
type: gpio\n\
pin: gpiochip0/gpio72               # Can be reversed with \"!\", (Bigtreetech PI V1.2 GPIO pin PC8)\n\
initial_state: off\n\
off_when_shutdown: True             # Turn off power on shutdown/error\n\
locked_while_printing: True         # Prevent power-off during a print\n\
restart_klipper_when_powered: True\n\
restart_delay: 1\n\
bound_service: klipper              # Ensures Klipper service starts/restarts with power toggle\n" >> "$MOONRAKER_CONF"

    print_row "$(translate_string "$LANG_SELECTED" "add_power_printer")"
}

create_post_merge_hook() {
    if [ ! -f "$HOOK_PATH" ]; then
        cat << 'EOF' > "$HOOK_PATH"
#!/bin/bash
/home/biqu/Sandworm/install.sh
EOF
        chmod +x "$HOOK_PATH"
        print_row "$(translate_string "$LANG_SELECTED" "post-merge_hook")"
    else
        print_row "$(translate_string "$LANG_SELECTED" "skipped_post-merge_hook")"
    fi
}

restart_klipper() {
    echo ""
    echo -e "Restarting Klipper to load new config..."
    sleep 5
    curl --no-progress-meter -X POST 'http://localhost:7125/printer/restart' > /dev/null 2>&1
}

restart_moonraker() {
    prompt=$(translate_string "$LANG_SELECTED" "restart_prompt")
    read -rp "$prompt" answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        translate_echo "$LANG_SELECTED" "restart_now"
        fancy_restart_bar
        curl --no-progress-meter -X POST http://localhost:7125/server/restart > /dev/null 2>&1
    else
        echo ""
        translate_echo "$LANG_SELECTED" "restart_skipped"
        translate_echo "$LANG_SELECTED" "restart_manual"
        translate_echo "$LANG_SELECTED" "restart_manual_1"
        translate_echo "$LANG_SELECTED" "restart_manual_2"
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
        print_row "$(translate_string "$LANG_SELECTED" "skipped_power_printer")"
    fi

    setup_gpio_permissions

    echo -e "║                                                                                    ║"
    echo -e "╟────────────────────────────────────────────────────────────────────────────────────╢"
	echo -e "║                                                                                    ║"

    # Set message on startup and language:
    set_variable_cfg "update_msg" 1
    set_variable_cfg "lang" "$LANG_SELECTED"

    create_post_merge_hook  

    echo -e "║                                                                                    ║"
    print_row "$(translate_string "$LANG_SELECTED" "install_success")"
    echo -e "║                                                                                    ║"
    echo -e "╚════════════════════════════════════════════════════════════════════════════════════╝"
    sleep $MESS_DELAY
    echo ""
    restart_moonraker

    echo ""
    sleep $MESS_sDELAY
else
    if [ ! -d "$SANDWORM_REPO" ]; then
        echo -e "$ERROR Source repo directory $SANDWORM_REPO not found!"
        exit 1
    fi

    backup_files_update
    copy_files_update

    # Set message on startup:
    set_variable_cfg "update_msg" 2

    echo -e ""
    echo -e "┌────────────────────────────────────────────────────────────────────────────────────"
    echo -e "│ ** NOTES: **"
    echo -e "│ ✅ The Sandworm update was completed successfully!"
    echo -e "│ 💾 Your config folder was backed up at: $BACKUP_DIR"
    echo -e "│ 📜 For full update details, see the log: $LOGFILE"
    echo -e "└────────────────────────────────────────────────────────────────────────────────────"
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
