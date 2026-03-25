#!/usr/bin/env bash
# Bootstrap colors.ini from mocha defaults if not yet created by theme-switch.sh
COLORS="$HOME/.config/polybar/colors.ini"
if [ ! -f "$COLORS" ]; then
  # Resolve the real script location (follows stow symlinks) to find dotfiles
  REAL_SCRIPT="$(realpath "${BASH_SOURCE[0]}")"
  DOTFILES_DIR="$(realpath "$(dirname "$REAL_SCRIPT")/../../../..")"
  DOTFILES_COLORS="$DOTFILES_DIR/theme/catppuccin/mocha/polybar-colors.ini"
  if [ -f "$DOTFILES_COLORS" ]; then
    cp "$DOTFILES_COLORS" "$COLORS"
  fi
fi

if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar --reload toph &
  done
else
  polybar --reload toph &
fi
