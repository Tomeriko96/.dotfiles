#!/bin/bash
set -euo pipefail

SCRIPTS_DIR="$(dirname "$0")"

show_menu() {
  echo "Select components to install (y/n):"
  read -rp "Install Neovim (with LazyVim)? [y/N]: " nvim_ans
  read -rp "Install VSCode? [y/N]: " vscode_ans
  read -rp "Install Greenclip? [y/N]: " greenclip_ans
}

main() {
  show_menu
  if [[ "${nvim_ans,,}" == "y" ]]; then
    "$SCRIPTS_DIR/install_neovim.sh"
  fi
  if [[ "${vscode_ans,,}" == "y" ]]; then
    "$SCRIPTS_DIR/install_vscode.sh"
  fi
  if [[ "${greenclip_ans,,}" == "y" ]]; then
    "$SCRIPTS_DIR/install_greenclip.sh"
  fi
  echo "Done."
}

main "$@"
