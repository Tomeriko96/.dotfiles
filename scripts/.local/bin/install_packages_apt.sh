#!/bin/bash
set -euo pipefail

# Install all required packages for this dotfiles setup (Debian/Ubuntu)
REQUIRED_PACKAGES=(
  stow
  i3
  alacritty
  polybar
  picom
  rofi
  starship
  waybar
  fzf
  maim
  xclip
  xdotool
  imagemagick
  openvpn
  wget
  gpg
  curl
  gnupg
  git
  zsh
  parted
  exfatprogs
  ffmpeg
  bat
  fonts-nerd-fonts
  unzip
  build-essential
  # Add more packages below as needed for your workflow
)

sudo apt update
sudo apt install -y "${REQUIRED_PACKAGES[@]}"

echo "All required packages installed."
