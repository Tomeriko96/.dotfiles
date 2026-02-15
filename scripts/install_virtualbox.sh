#!/bin/bash
# VirtualBox installer for Debian 13 (Trixie)
set -euo pipefail

RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' NC='\033[0m'
log()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error(){ echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

main() {
  log "Oracle VirtualBox + APT repo installer for Debian 13 (Trixie)"

  if [[ $(id -u) -eq 0 ]]; then
    warn "You are running this script as root; sudo will be skipped."
    SUDO=""
  else
    SUDO="sudo"
  fi

  $SUDO apt update
  $SUDO apt install -y wget curl gpg ca-certificates gnupg lsb-release

  log "Installing Oracle GPG key"
  $SUDO mkdir -p /usr/share/keyrings
  curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc \
    | gpg --dearmor \
    | $SUDO tee /usr/share/keyrings/oracle_vbox_2016.gpg >/dev/null

  log "Configuring VirtualBox APT repository for Trixie"
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle_vbox_2016.gpg] \
http://download.virtualbox.org/virtualbox/debian trixie contrib" \
    | $SUDO tee /etc/apt/sources.list.d/virtualbox.list >/dev/null

  log "Refreshing APT package index"
  $SUDO apt update

  log "Installing VirtualBox 7.2"
  $SUDO apt install -y virtualbox-7.2

  log "Adding user to vboxusers group (for USB etc.)"
  if [[ -n "${SUDO:-}" ]]; then
    $SUDO usermod -aG vboxusers "$USER"
  else
    usermod -aG vboxusers "$SUDO_USER"
  fi

  log "✔️ VirtualBox installed! Run 'virtualbox' or use your desktop menu."
  log "Updates will come via: 'sudo apt upgrade'."
  log "Log out and back in so the vboxusers group membership takes effect."
}

main "$@"

