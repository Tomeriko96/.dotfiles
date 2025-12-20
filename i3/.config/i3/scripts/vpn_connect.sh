#!/usr/bin/env bash
#
# vpn_connect.sh - Safely connect OpenVPN with expiry check
#
# Usage: sudo ./vpn_connect.sh /path/to/config.ovpn
#        (chmod 700 vpn_connect.sh first)
#
# Checks .ovpn expiry before connecting; requires sudo for tun/routing.

set -euo pipefail

if [[ $# -lt 1 ]]; then
    printf 'Usage: %s /path/to/config.ovpn\n' "$0" >&2
    exit 1
fi

OVPN_FILE=$1

if [[ ! -r "$OVPN_FILE" ]]; then
    printf 'ERROR: Config file not readable: %s\n' "$OVPN_FILE" >&2
    exit 1
fi

# Extract and check expiry (warns but continues if missing/unparsable)
expiry_line=$(grep '^# Expires:' "$OVPN_FILE" || true)
if [[ -n "$expiry_line" ]]; then
    expiry_iso=${expiry_line#\# Expires:}
    expiry_iso=${expiry_iso## }; expiry_iso=${expiry_iso%% }
    
    if expiry_epoch=$(date -d "$expiry_iso" +%s 2>/dev/null); then
        if (( $(date +%s) >= expiry_epoch )); then
            printf 'ERROR: VPN profile expired (%s). Renew first.\n' "$expiry_iso" >&2
            exit 1
        fi
    fi
fi

printf 'Using: %s\n' "$OVPN_FILE"
exec openvpn --config "$OVPN_FILE"

