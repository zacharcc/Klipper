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
        "restart_now")
            case $lang in
                1) echo -e "Restarting Moonraker service in 5 seconds..." ;;
                2) echo -e "Restart Moonrakeru začne za 5 sekund..." ;;
                3) echo -e "Moonraker wird in 5 Sekunden neu gestartet..." ;;
                *) echo -e "Restarting Moonraker service in 5 seconds..." ;;
            esac
        ;;
        "restart_skipped")
            case $lang in
                1) echo -e "$INFO Moonraker restart skipped. Changes have not been applied!" ;;
                2) echo -e "$INFO Restart Moonrakeru byl přeskočen. Změny nebyly použity!" ;;
                3) echo -e "$INFO Moonraker-Neustart übersprungen. Änderungen wurden nicht übernommen!" ;;
                *) echo -e "$INFO Moonraker restart skipped. Changes have not been applied!" ;;
            esac
        ;;
        "restart_manual")
            case $lang in
                1) echo -e "You can restart Moonraker manually later via:" ;;
                2) echo -e "Moonraker můžete později restartovat ručně pomocí:" ;;
                3) echo -e "Sie können Moonraker später manuell neu starten über:" ;;
                *) echo -e "You can restart Moonraker manually later via:" ;;
            esac
        ;;
        "restart_manual_1")
            case $lang in
                1) echo -e "  1. The web interface: Power -→ Service Control -→ Moonraker" ;;
                2) echo -e "  1. Webového rozhraní: Power -→ Service Control -→ Moonraker" ;;
                3) echo -e "  1. Webinterface: Power -→ Service Control -→ Moonraker" ;;
                *) echo -e "  1. The web interface: Power -→ Service Control -→ Moonraker" ;;
            esac
        ;;
        "restart_manual_2")
            case $lang in
                1) echo -e "  2. Command line: curl -X POST http://localhost:7125/server/restart" ;;
                2) echo -e "  2. Příkazového řádku: curl -X POST http://localhost:7125/server/restart" ;;
                3) echo -e "  2. Befehlszeile: curl -X POST http://localhost:7125/server/restart" ;;
                *) echo -e "  2. Command line: curl -X POST http://localhost:7125/server/restart" ;;
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
                1) echo "$OK English language set in [variables.cfg]." ;;
                2) echo "$OK Čeština nastavena v souboru [variables.cfg]." ;;
                3) echo "$OK Deutsch in [variables.cfg] eingestellt." ;;
                *) echo "$OK Language setting saved in [variables.cfg]." ;;
            esac ;;
        "skipped_variables")
            case $lang in
                1) echo "$SKIPPED The file [variables.cfg] was not found in:" ;;
                2) echo "$SKIPPED Soubor [variables.cfg] nebyl nalezen v:" ;;
                3) echo "$SKIPPED Die Datei [variables.cfg] wurde nicht gefunden in:" ;;
                *) echo "$SKIPPED The file [variables.cfg] was not found in:" ;;
            esac ;;
        "install_success")
            case $lang in
                1) echo "$OK The Sandworm installation was completed successfully!" ;;
                2) echo "$OK Instalace Sandworm byla úspěšně dokončena!" ;;
                3) echo "$OK Die Sandworm-Installation wurde erfolgreich abgeschlossen!" ;;
                *) echo "$OK The Sandworm installation was completed successfully!" ;;		
            esac ;;
        "restart_prompt")
            case $lang in
                1) echo "Do you want to restart Moonraker now to apply changes? [y/N]: " ;;
                2) echo "Chcete nyní restartovat Moonraker pro aplikování změn? [y/N]: " ;;
                3) echo "Möchten Sie Moonraker jetzt neu starten, um die Änderungen anzuwenden? [y/N]: " ;;
                *) echo "Do you want to restart Moonraker now to apply changes? [y/N]: " ;;
            esac ;;
         # ... další klíče sem
        *)
            echo "$key"
        ;;
    esac

# usage: print_row "$(translate_string "$LANG_SELECTED" "install_success")"
}
