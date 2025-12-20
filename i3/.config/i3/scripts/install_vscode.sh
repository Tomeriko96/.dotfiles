#!/bin/bash
set -euo pipefail

RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' NC='\033[0m'
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

main() {
  log "VSCode + Microsoft APT repo installer"
  
  # Install prerequisites
  sudo apt update
  sudo apt install -y wget gpg ca-certificates curl gnupg
  
  # Add Microsoft GPG key (modern method)
  curl -fSsL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | sudo tee /usr/share/keyrings/microsoft-vscode.gpg >/dev/null
  
  # Add VSCode repo (DEB822 format)
  echo "Types: deb
URIs: https://packages.microsoft.com/repos/vscode
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/microsoft-vscode.gpg" | \
    sudo tee /etc/apt/sources.list.d/vscode.sources
  
  # Update and install
  sudo apt update
  sudo apt install -y code
  
  log "✅ VSCode installed! Run 'code' or find in menu"
  log "Updates via: sudo apt upgrade"
}

main "$@"

