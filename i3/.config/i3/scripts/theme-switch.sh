#!/usr/bin/env bash
set -euo pipefail

# theme-switch.sh — Catppuccin theme switcher for Alacritty, Rofi, btop, i3, Polybar, picom, GTK, and wallpaper.
# Usage: theme-switch.sh <mocha|latte|toggle|dry-run>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(realpath "$SCRIPT_DIR/../../../../")"

TARGET_ALACRITTY="$HOME/.config/alacritty/current-theme.toml"
TARGET_ROFI="$HOME/.config/rofi/theme.rasi"
TARGET_BTOP="$HOME/.config/btop/themes/current.theme"
TARGET_I3_COLORS="$HOME/.config/i3/themes/current-colors"
TARGET_POLYBAR="$HOME/.config/polybar/config.ini"
I3_CONFIG="$HOME/.config/i3/config"

MODE="${1:-toggle}"
DRY_RUN=false
if [ "$MODE" = "dry-run" ]; then
  DRY_RUN=true
  MODE="toggle"
fi

# ---------- Theme selection ----------
choose_theme() {
  case "$1" in
    mocha|latte) echo "$1" ;;
    toggle)
      if [ -f "$TARGET_I3_COLORS" ]; then
        if grep -q "# latte" "$TARGET_I3_COLORS" 2>/dev/null; then
          echo "mocha"
        else
          echo "latte"
        fi
      else
        echo "mocha"
      fi
      ;;
    *) echo "mocha" ;;
  esac
}

# ---------- GTK persistence helper ----------
apply_gtk_theme_persistent() {
  local theme="$1"
  if command -v gsettings >/dev/null 2>&1; then
    echo "Setting persistent GTK theme for $theme..."
    if [ "$theme" = "mocha" ]; then
      gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
    else
      gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' || true
    fi
    dbus-launch dconf update >/dev/null 2>&1 || true
  fi
}

# ---------- Start ----------
THEME=$(choose_theme "$MODE")
THEME_DIR="$DOTFILES_DIR/theme/catppuccin/$THEME"

echo "Switching theme → $THEME"
if command -v notify-send >/dev/null 2>&1; then
  notify-send "Theme switched" "Catppuccin $THEME applied"
fi

if [ "$DRY_RUN" = true ]; then
  echo "Dry run mode. Files would be copied from:"
  echo "  $THEME_DIR"
  exit 0
fi

# ---------- Copy theme files ----------
mkdir -p "$HOME/.config/alacritty" \
         "$(dirname "$TARGET_ROFI")" \
         "$(dirname "$TARGET_BTOP")" \
         "$(dirname "$TARGET_I3_COLORS")" \
         "$HOME/.config/polybar"

cp -v "$THEME_DIR/alacritty.toml" "$TARGET_ALACRITTY"
cp -v "$THEME_DIR/rofi.rasi" "$TARGET_ROFI"
cp -v "$THEME_DIR/btop.theme" "$TARGET_BTOP"
cp -v "$THEME_DIR/i3-colors" "$TARGET_I3_COLORS"
if [ -f "$THEME_DIR/polybar.ini" ]; then
  cp -v "$THEME_DIR/polybar.ini" "$TARGET_POLYBAR"
  echo "Installed polybar config for $THEME."
fi

# ---------- Persist GTK before reload ----------
apply_gtk_theme_persistent "$THEME"

# ---------- Wallpaper switching ----------
WALLPAPER_DIR="$HOME/.local/share/backgrounds"
if [ "$THEME" = "latte" ]; then
  LATTE_BG_DIR="$HOME/.local/share/backgrounds-latte"
  mkdir -p "$LATTE_BG_DIR"
  if ! ls "$LATTE_BG_DIR"/*.{png,jpg,jpeg,gif,bmp,tiff,svg,webp,JPG,JPEG,PNG} >/dev/null 2>&1; then
    if [ -f "$HOME/.local/share/backgrounds/bg.png" ]; then
      cp "$HOME/.local/share/backgrounds/bg.png" "$LATTE_BG_DIR/bg.png"
    fi
  fi
  WALLPAPER_DIR="$LATTE_BG_DIR"
fi

if [ -x "$HOME/.config/i3/scripts/wallpaper_manager.sh" ]; then
  "$HOME/.config/i3/scripts/wallpaper_manager.sh" apply "$WALLPAPER_DIR"
fi

# ---------- Determine if i3 manages Polybar ----------
I3_POLYBAR_MANAGED=false
if [ -f "$I3_CONFIG" ] && grep -q "polybar" "$I3_CONFIG"; then
  if grep -qE 'exec(_always)?\s+.*polybar' "$I3_CONFIG"; then
    I3_POLYBAR_MANAGED=true
  fi
fi

# ---------- Reload i3 ----------
if command -v i3-msg >/dev/null 2>&1; then
  i3-msg reload || true
  sleep 0.5
fi

# ---------- Polybar handling ----------
if [ "$I3_POLYBAR_MANAGED" = false ]; then
  echo "Polybar is script-managed. Restarting..."
  pkill -f polybar || true
  sleep 0.5
  if [ -x "$HOME/.config/polybar/launch_polybar.sh" ]; then
    "$HOME/.config/polybar/launch_polybar.sh" &
  elif [ -x "$HOME/.config/polybar/launch_polybar" ]; then
    "$HOME/.config/polybar/launch_polybar" &
  fi
else
  echo "Polybar managed by i3 config — skipping manual restart."
fi

# ---------- Restart picom ----------
pkill picom || true
if command -v picom >/dev/null 2>&1; then
  picom --config "$HOME/.config/picom.conf" &
fi

# ---------- Reapply GTK after reload ----------
if command -v gsettings >/dev/null 2>&1; then
  echo "Reapplying GTK theme to ensure consistency..."
  sleep 1
  if [ "$THEME" = "mocha" ]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
  else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' || true
  fi
fi

echo "Theme switch complete → $THEME"
echo "Restart Alacritty, Neovim, or btop if they didn’t reload colors."

