#!/bin/bash

## INSTALL VERSION FOR TESTING:

## --- Trap ---
set -Ee
trap 'echo -e "$ERROR Script failed at line $LINENO"' ERR

## --- Brake line after git clone messages ---

# --- Paths ---

# TAKÉ PŘENASTAVIT variables.cfg sekci a PATH!!!!!
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

## --- Message status ---
OK="[OK]"
INFO="[INFO]"
SKIPPED="[SKIPPED]"
ERROR="[ERROR]"
MESS_DELAY=0.8
MESS_sDELAY=0.2

print_row() {
    local msg="$1"
    local visible_length=$(echo -n "$msg" | wc -m)
    local total_width=82
    local padding=$((total_width - visible_length))
    [ $padding -lt 0 ] && padding=0
    printf "║ %s%*s ║\n" "$msg" "$padding" ""
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

    # Barvy
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
        print_row "$SKIPPED variables.cfg not found at:"
        to_path="  ● $file"
        formatted_to=$(printf "%-85s" "$to_path")
        return
    fi

    if grep -q "^$key\s*=" "$file"; then
        sed -i "s/^$key\s*=.*/$key = $value/" "$file"
        if [ "$IS_COLD_INSTALL" = true ]; then
            # Dynamický klíč do překladače, např. "set_update_msg"
            print_row "$(translate_string "$LANG_SELECTED" "set_${key}")"
        else
            print_row "$OK Updated $key to $value in variables.cfg"
        fi
    else
        print_row "$SKIPPED Variable '$key' not found in variables.cfg"
    fi
}

# Usage:
# select_lang
# set_variable_cfg "lang" "$LANG_SELECTED"

# Echo's Legendary Great Dictionary:
translate_echo() {
    local lang=$1
    local key=$2
    shift 2

    case $key in
        "title_cold_install")
            case $lang in
                1) echo -e "║        ** Sandworm installation **         ║" ;;
                2) echo -e "║          ** Sandworm instalace **          ║" ;;
                3) echo -e "║        ** Sandworm-Installation **         ║" ;;
                *) echo -e "║        ** Sandworm installation **         ║" ;;
            esac
        ;;
    esac
}

translate_string() {
    local lang=$1
    local key=$2
    case $key in
        "start_date")
            case $lang in
                1) echo -e "Started: $(date)" ;;
                2) echo -e "Zahájeno: $(date)" ;;
                3) echo -e "Gestartet: $(date)" ;;
                *) echo -e "Started: $(date)" ;;
            esac ;;
        "git_version")
            case $lang in
                1) echo "Git version: $VERSION" ;;
                2) echo "Git verze: $VERSION" ;;
                3) echo "Git-Version: $VERSION" ;;
                *) echo "Git version: $VERSION" ;;
            esac ;;
        "install_version")
            case $lang in
                1) echo "Install version: $CUSTOM_VERSION" ;;
                2) echo "Verze instalace: $CUSTOM_VERSION" ;;
                3) echo "Installationsversion: $CUSTOM_VERSION" ;;
                *) echo "Install version: $CUSTOM_VERSION" ;;
            esac ;;
         "description")
            case $lang in
                1) echo "Sandworm installation with automatic updates has started..." ;;
                2) echo "Zahájena instalace Sandworm s automatickými aktualizacemi..." ;;
                3) echo "Die Sandworm-Installation mit automatischen Updates wurde gestartet..." ;;
                *) echo "Sandworm installation with automatic updates has started..." ;;
            esac ;;
        "from") case $lang in 1) echo "from:" ;; 2) echo " z:" ;; 3) echo " von:" ;; esac ;;
        "to")   case $lang in 1) echo "  to:" ;;   2) echo "do:" ;; 3) echo "nach:" ;; esac ;;
        "backup")
            case $lang in
                1) echo "Creating backup of the printer config directory:" ;;
                2) echo "Vytváření zálohy konfiguračního adresáře tiskárny:" ;;
                3) echo "Erstellen einer Sicherungskopie des Druckerkonfigurationsverzeichnisses:" ;;
                *) echo "Creating backup of the printer config directory:" ;;
            esac ;;
        "backup_done")
            case $lang in
                1) echo "$OK Backup complete." ;;
                2) echo "$OK Záloha byla úspěšně dokončena." ;;
                3) echo "$OK Sicherung erfolgreich abgeschlossen." ;;
                *) echo "$OK Backup complete." ;;
            esac ;;
        "copy")
            case $lang in
                1) echo "Copying new files:" ;;
                2) echo "Kopírování nových souborů:" ;;
                3) echo "Neue Dateien kopieren:" ;;
                *) echo "Copying new files:" ;;
            esac ;;
        "copying_done")
            case $lang in
                1) echo "$OK Copying completed." ;;
                2) echo "$OK Kopírování dokončeno." ;;
                3) echo "$OK Kopiervorgang abgeschlossen." ;;
                *) echo "$OK Copying completed." ;;
            esac ;;
        "add_update_manager")
            case $lang in
                1) echo "$OK Added [update_manager Sandworm] config block to: moonraker.conf" ;;
                2) echo "$OK Přidán [update_manager Sandworm] konfig blok do: moonraker.conf" ;;
                3) echo "$OK Konfigblock [update_manager Sandworm] hinzugefügt zu: moonraker.conf" ;;
                *) echo "$OK Added [update_manager Sandworm] config block to: moonraker.conf" ;;
            esac ;;
        "add_power_printer")
            case $lang in
                1) echo "$OK Added [power printer] config block to: moonraker.conf" ;;
                2) echo "$OK Přidán [power printer] konfigurační blok do: moonraker.conf" ;;
                3) echo "$OK Konfigblock [power printer] hinzugefügt zu: moonraker.conf" ;;
                *) echo "$OK Added [power printer] config block to: moonraker.conf" ;;
            esac ;;
        "skipped_power_printer")
            case $lang in
                1) echo "$SKIPPED [power printer] already exists in moonraker.conf" ;;
                2) echo "$SKIPPED [power printer] již existuje v moonraker.conf" ;;
                3) echo "$SKIPPED [Power Printer] existiert bereits in moonraker.conf" ;;
                *) echo "$SKIPPED [power printer] already exists in moonraker.conf" ;;
            esac ;;
        "post-merge_hook")
            case $lang in
                1) echo "$OK Git post-merge hook created at: $HOOK_PATH" ;;
                2) echo "$OK Git post-merge hook vytvořen v: $HOOK_PATH" ;;
                3) echo "$OK Git post-merge hook erstellt unter: $HOOK_PATH" ;;
                *) echo "$OK Git post-merge hook created at: $HOOK_PATH" ;;
            esac ;;
        "skipped_post-merge_hook")
            case $lang in
                1) echo "$SKIPPED Git post-merge hook already exists." ;;
                2) echo "$SKIPPED Git post-merge hook již existuje." ;;
                3) echo "$SKIPPED Git post-merge hook ist bereits vorhanden." ;;
                *) echo "$SKIPPED Git post-merge hook already exists." ;;
            esac ;;
        "set_update_msg")
            case $lang in
                1) echo "$OK Introductory message enabled in [variables.cfg]" ;;
                2) echo "$OK Zobrazení úvodní zprávy nastaveno v [variables.cfg]" ;;
                3) echo "$OK Startnachricht in [variables.cfg] aktiviert." ;;
                *) echo "$OK The opening message was set in the [variables.cfg] files." ;;
            esac ;;
        "set_lang")
            case $lang in
                1) echo "$OK English language has been set in [variables.cfg]." ;;
                2) echo "$OK Čeština byla nastavena v souboru [variables.cfg]." ;;
                3) echo "$OK Deutsch wurde in der Datei [variables.cfg] festgelegt." ;;
                *) echo "$OK Language setting has been saved in [variables.cfg]." ;;
            esac ;;
        "install_success")
            case $lang in
                1) echo "$OK The Sandworm installation was completed successfully!" ;;
                2) echo "$OK Instalace Sandworm byla úspěšně dokončena!" ;;
                3) echo "$OK Die Sandworm-Installation wurde erfolgreich abgeschlossen!" ;;
                *) echo "$OK The Sandworm installation was completed successfully!" ;;
            esac ;;
        # ... další klíče sem
        *)
            print_row "$key"  # fallback
        ;;
    esac

# print_row "$(translate_string "$LANG_SELECTED" "set_update_msg")"

}


## ---  Logging setup ---
mkdir -p "$TMP_LOG_DIR"
if [ "$IS_COLD_INSTALL" = true ]; then
    set_game_variables

    # ASCII intro do logu
    exec 4>"$LOGFILE"
    print_game_intro_ascii >&4
    exec 4>&-

    # stdout/stderr do logu a tee (append místo přepisu)
    exec > >(tee -a "$LOGFILE") 2>&1
    exec 3>/dev/tty

    # barevné intro do konzole
    draw_game_intro >&3
else
    exec > >(tee "$TMP_UPDATE_LOG") 2>&1
fi

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
    cp -r "$CONFIG_DIR/"* "$BACKUP_DIR/" || echo -e "$ERROR Backup failed!"
    
    echo -e "║                                                                                    ║"
    print_row "$(translate_string "$LANG_SELECTED" "backup_done")"
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
    echo -e "║                                                                                    ║"

    mkdir -p "$CONFIG_DIR"
    RSYNC_OUTPUT=$(rsync -av "$SANDWORM_REPO/" "$CONFIG_DIR/")

    # rsync output in rows:
    while IFS= read -r line; do
        formatted_line=$(printf "%-81s" "$line")
        echo -e "║ $formatted_line  ║"
    done <<< "$RSYNC_OUTPUT"

    echo -e "║                                                                                    ║"
    print_row "$(translate_string "$LANG_SELECTED" "copying_done")"
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
    sleep $MESS_sDELAY
}

add_update_manager_block() {
    echo -e "\n[update_manager Sandworm]
type: git_repo
origin: https://github.com/zacharcc/Klipper.git
path: ~/Sandworm
primary_branch: test
managed_services: klipper
install_script: install.sh" >> "$MOONRAKER_CONF"
    echo -e "║                                                                                    ║"
    echo -e "╟────────────────────────────────────────────────────────────────────────────────────╢"
    print_row "$(translate_string "$LANG_SELECTED" "add_update_manager")"
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
        print_row "$(translate_string "$LANG_SELECTED" "skipped_power_printer")"
    fi

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