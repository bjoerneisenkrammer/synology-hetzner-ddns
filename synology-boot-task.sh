#!/bin/bash
set -euo pipefail

# -------------------------------------------------------
# Synology Boot Task: Hetzner DDNS Setup
#
# Purpose:
#   Ensures hetznerddns.sh is reinstalled and ddns_provider.conf
#   is configured after a DSM update.
#
# Setup:
#   1. Store this script on /volume1/ (survives DSM updates)
#   2. In DSM > Task Scheduler > Create > Triggered Task
#      - User: root
#      - Event: Boot-up
#      - Script: bash /volume1/<path>/synology-boot-task.sh
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

log "=== Hetzner DDNS setup started ==="

# Download latest script
log "Downloading hetznerddns.sh..."
if curl -fsSL "$SCRIPT_URL" -o "$INSTALL_PATH"; then
	log "Download successful: $INSTALL_PATH"
else
	log "ERROR: Download failed"
	exit 1
fi

# Set execute permissions
chmod +x "$INSTALL_PATH"
log "Permissions set: +x $INSTALL_PATH"

# Add provider entry to ddns_provider.conf (idempotent)
if grep -q "^\[Hetzner\]" "$DDNS_CONF" 2>/dev/null; then
	log "ddns_provider.conf already contains [Hetzner] entry, skipping."
else
	cat >>"$DDNS_CONF" <<'EOF'
[Hetzner]
        modulepath=/sbin/hetznerddns.sh
        queryurl=https://dns.hetzner.com/api/v1
        website=https://dns.hetzner.com
EOF
	log "Added [Hetzner] entry to $DDNS_CONF."
fi

log "=== Setup complete ==="
