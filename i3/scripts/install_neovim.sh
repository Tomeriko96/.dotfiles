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

NVIM_PATH="/usr/bin/nvim"
CONFIG_DIR="$HOME/.config/nvim"
LAZYVIM_REPO="https://github.com/LazyVim/starter"

download_neovim() {
  LATEST_VERSION=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
  
  NVIM_TARBALL_X64="nvim-linux-x86_64.tar.gz"
  NVIM_TARBALL_64="nvim-linux64.tar.gz"
  NVIM_URL_X64="https://github.com/neovim/neovim/releases/download/${LATEST_VERSION}/${NVIM_TARBALL_X64}"
  NVIM_URL_64="https://github.com/neovim/neovim/releases/download/${LATEST_VERSION}/${NVIM_TARBALL_64}"
  
  log "Downloading Neovim $LATEST_VERSION..."
  rm -f "$NVIM_TARBALL_X64" "$NVIM_TARBALL_64"
  
  if curl -L --retry 3 --fail -LO "$NVIM_URL_X64" 2>/dev/null; then
    NVIM_TARBALL="$NVIM_TARBALL_X64"
  elif curl -L --retry 3 --fail -LO "$NVIM_URL_64" 2>/dev/null; then
    NVIM_TARBALL="$NVIM_TARBALL_64"
  else
    error "Both tarball URLs failed"
  fi
  
  ACTUAL_SIZE=$(stat -c%s "$NVIM_TARBALL" 2>/dev/null || stat -f%z "$NVIM_TARBALL")
  if [[ $ACTUAL_SIZE -lt 10000000 ]]; then
    error "Download too small ($ACTUAL_SIZE bytes)"
  fi
  log "✅ Download verified: $(numfmt --to=iec-i --suffix=B $ACTUAL_SIZE)"
}

install_neovim() {
  download_neovim
  sudo rm -rf /usr/share/nvim /usr/bin/nvim /usr/nvim-linux-*
  
  sudo tar -C /usr -xzf "$NVIM_TARBALL"
  
  # Create proper symlink (handles both naming conventions)
  if [[ -x "/usr/nvim-linux-x86_64/bin/nvim" ]]; then
    sudo ln -sf /usr/nvim-linux-x86_64/bin/nvim /usr/bin/nvim
    log "✅ Symlink created: /usr/nvim-linux-x86_64/bin/nvim → /usr/bin/nvim"
  elif [[ -x "/usr/nvim-linux64/bin/nvim" ]]; then
    sudo ln -sf /usr/nvim-linux64/bin/nvim /usr/bin/nvim
    log "✅ Symlink created: /usr/nvim-linux64/bin/nvim → /usr/bin/nvim"
  else
    error "nvim binary not found after extraction"
  fi
  
  rm "$NVIM_TARBALL"
  log "✅ Neovim installed: $(nvim --version | head -n1)"
}

setup_lazyvim() {
  log "Setting up LazyVim..."
  mkdir -p "$HOME/.config"
  if [[ ! -d "$CONFIG_DIR" ]]; then
    git clone "$LAZYVIM_REPO" "$CONFIG_DIR"
    rm -rf "$CONFIG_DIR/.git"
    log "✅ LazyVim installed"
  else
    warn "LazyVim already exists - skipping"
  fi
}

main() {
  log "Neovim + LazyVim installer"
  
  if [[ ! -x "$NVIM_PATH" ]] || ! nvim --version 2>/dev/null | grep -q "0.9"; then
    install_neovim
  else
    warn "Neovim 0.9+ already installed - skipping"
  fi
  
  setup_lazyvim
  log "✅ Done! Run 'nvim'"
}

main "$@"

