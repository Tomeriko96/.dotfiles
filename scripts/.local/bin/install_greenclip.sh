#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

main() {
  log "PATH: $PATH"

  # Get latest release tag from GitHub API
  LATEST_TAG=$(curl -s https://api.github.com/repos/erebe/greenclip/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
  if [[ -z "$LATEST_TAG" ]]; then
    error "Could not fetch latest greenclip release tag"
  fi
  log "Latest greenclip version: $LATEST_TAG"

  # Download greenclip binary
  URL="https://github.com/erebe/greenclip/releases/download/${LATEST_TAG}/greenclip"
  TMP_BIN="/tmp/greenclip"
  log "Downloading: $URL"
  if ! curl -L --retry 3 --fail -o "$TMP_BIN" "$URL"; then
    error "Failed to download greenclip binary"
  fi

  # Install to /usr/local/bin
  sudo mv "$TMP_BIN" /usr/local/bin/greenclip
  sudo chmod +x /usr/local/bin/greenclip
  log "✅ Installed /usr/local/bin/greenclip"
  log "Run: greenclip daemon"
}

main "$@"
