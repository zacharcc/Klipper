#!/bin/bash

# --- Sandworm Git Watcher ---
# Spouští se při restartu služby sandworm.service
# Účel: detekce změny v Git HEAD a přesun nových souborů ze Sandworm do Klipper config

# --- Cesty ---
REPO_DIR="$HOME/Sandworm"
SOURCE_DIR="$REPO_DIR/test"  # Produkčně pak bude: $REPO_DIR/config
DEST_DIR="$HOME/printer_data/config/TEST/update_test"
BACKUP_DIR="$REPO_DIR/backup/backup_config_$(date +%Y_%m_%d-%Hh%Mm)"
LAST_HASH_FILE="$REPO_DIR/.last_git_hash"
LOGFILE="$HOME/printer_data/logs/sandworm_update.log"

# --- Funkce logování ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

# --- Získání aktuálního Git hashe ---
CURRENT_HASH=$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null)

# --- Získání předchozího hashe (pokud existuje) ---
if [ -f "$LAST_HASH_FILE" ]; then
    LAST_HASH=$(cat "$LAST_HASH_FILE")
else
    LAST_HASH=""
fi

# --- Porovnání hashů ---
if [ "$CURRENT_HASH" != "$LAST_HASH" ]; then
    log "Git hash změněn: $LAST_HASH → $CURRENT_HASH"

    # --- Záloha stávající konfigurace ---
    log "Vytvářím zálohu do: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    cp -r "$DEST_DIR/"* "$BACKUP_DIR/" 2>/dev/null && log "Záloha dokončena." || log "Chyba při záloze!"

    # --- Přesun nových souborů ---
    log "Kopíruji nové soubory z: $SOURCE_DIR do: $DEST_DIR"
    mkdir -p "$DEST_DIR"
    rsync -a --delete "$SOURCE_DIR/" "$DEST_DIR/" && log "Kopírování dokončeno." || log "Chyba při kopírování!"

    # --- Uložení nového hashe ---
    echo "$CURRENT_HASH" > "$LAST_HASH_FILE"
    log "Aktualizace dokončena."
else
    log "Žádná změna v Git repozitáři. Přeskakuji aktualizaci."
fi

exit 0
