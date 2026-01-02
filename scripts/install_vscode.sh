#!/bin/bash
# VSCode installer (migrated from i3 config)
set -euo pipefail

RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' NC='\033[0m'
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

main() {
  log "VSCode + Microsoft APT repo installer"
  sudo apt update
  sudo apt install -y wget gpg ca-certificates curl gnupg
  curl -fSsL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | sudo tee /usr/share/keyrings/microsoft-vscode.gpg >/dev/null
  echo "Types: deb\nURIs: https://packages.microsoft.com/repos/vscode\nSuites: stable\nComponents: main\nArchitectures: amd64\nSigned-By: /usr/share/keyrings/microsoft-vscode.gpg" | \
    sudo tee /etc/apt/sources.list.d/vscode.sources
  sudo apt update
  sudo apt install -y code
  log "\u2705 VSCode installed! Run 'code' or find in menu"
  log "Updates via: sudo apt upgrade"
}

main "$@"
