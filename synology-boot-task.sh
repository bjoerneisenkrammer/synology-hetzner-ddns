#!/bin/bash
set -euo pipefail

# -------------------------------------------------------
# Synology Boot Task: Hetzner DDNS Setup
#
# Zweck:
#   Stellt nach einem DSM-Update sicher, dass hetznerddns.sh
#   wieder installiert und ddns_provider.conf konfiguriert ist.
#
# Einrichtung:
#   1. Dieses Script auf /volume1/ ablegen (überlebt DSM-Updates)
#   2. In DSM > Aufgabenplanung > Erstellen > Ausgelöste Aufgabe
#      - Benutzer: root
#      - Ereignis: Starten
#      - Script: bash /volume1/<pfad>/synology-boot-task.sh
# -------------------------------------------------------

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

SCRIPT_URL="https://raw.githubusercontent.com/bjoerneisenkrammer/synology-hetzner-ddns/main/hetznerddns.sh"
INSTALL_PATH="/sbin/hetznerddns.sh"
DDNS_CONF="/etc.defaults/ddns_provider.conf"
LOG_TAG="hetzner-ddns-setup"

log() {
    logger -t "$LOG_TAG" "$1"
    echo "$1"
}

log "=== Hetzner DDNS Setup gestartet ==="

# Script herunterladen
log "Lade hetznerddns.sh herunter..."
if curl -fsSL "$SCRIPT_URL" -o "$INSTALL_PATH"; then
    log "Download erfolgreich: $INSTALL_PATH"
else
    log "FEHLER: Download fehlgeschlagen"
    exit 1
fi

# Ausführungsrechte setzen
chmod +x "$INSTALL_PATH"
log "Berechtigungen gesetzt: +x $INSTALL_PATH"

# Provider-Eintrag in ddns_provider.conf hinzufügen (idempotent)
if grep -q "^\[Hetzner\]" "$DDNS_CONF" 2>/dev/null; then
    log "ddns_provider.conf enthält bereits [Hetzner]-Eintrag, wird übersprungen."
else
    cat >> "$DDNS_CONF" << 'EOF'
[Hetzner]
        modulepath=/sbin/hetznerddns.sh
        queryurl=https://dns.hetzner.com/api/v1
        website=https://dns.hetzner.com
EOF
    log "Eintrag [Hetzner] zu $DDNS_CONF hinzugefügt."
fi

log "=== Setup abgeschlossen ==="
