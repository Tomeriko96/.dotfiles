#!/usr/bin/env bash
set -euo pipefail

# theme-switch.sh - copy theme files from dotfiles to user config and reload services
# Usage: theme-switch.sh <mocha|latte|toggle|dry-run>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(realpath "$SCRIPT_DIR/../../../../")"

TARGET_ALACRITTY="$HOME/.config/alacritty/current-theme.toml"
TARGET_ROFI="$HOME/.config/rofi/theme.rasi"
TARGET_BTOP="$HOME/.config/btop/themes/current.theme"
TARGET_I3_COLORS="$HOME/.config/i3/themes/current-colors"
TARGET_POLYBAR="$HOME/.config/polybar/config.ini"

MODE="${1:-toggle}"
DRY_RUN=false
if [ "$MODE" = "dry-run" ]; then
  DRY_RUN=true
  MODE="toggle"
fi

choose_theme(){
  case "$1" in
    mocha|latte) echo "$1" ;;
    toggle)
      # read current marker if exists
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

THEME=$(choose_theme "$MODE")
THEME_DIR="$DOTFILES_DIR/theme/catppuccin/$THEME"

echo "Switching theme -> $THEME"
if command -v notify-send >/dev/null 2>&1; then
  notify-send "Theme switched" "Catppuccin $THEME applied"
fi

if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN: will copy from $THEME_DIR to user config targets:" >&2
  echo "  $TARGET_ALACRITTY" >&2
  echo "  $TARGET_ROFI" >&2
  echo "  $TARGET_BTOP" >&2
  echo "  $TARGET_I3_COLORS" >&2
  exit 0
fi

mkdir -p "$HOME/.config/alacritty"
mkdir -p "$(dirname "$TARGET_ROFI")"
mkdir -p "$(dirname "$TARGET_BTOP")"
mkdir -p "$(dirname "$TARGET_I3_COLORS")"
mkdir -p "$HOME/.config/polybar"

cp -v "$THEME_DIR/alacritty.toml" "$TARGET_ALACRITTY"
cp -v "$THEME_DIR/rofi.rasi" "$TARGET_ROFI"
cp -v "$THEME_DIR/btop.theme" "$TARGET_BTOP"
cp -v "$THEME_DIR/i3-colors" "$TARGET_I3_COLORS"

# Copy the full polybar config for the selected theme
if [ -f "$THEME_DIR/polybar.ini" ]; then
  cp -v "$THEME_DIR/polybar.ini" "$TARGET_POLYBAR"
  echo "Installed polybar config for $THEME"
fi


# GTK color-scheme
if command -v gsettings >/dev/null 2>&1; then
  if [ "$THEME" = "mocha" ]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
  else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' || true
  fi
fi

# VSCode Catppuccin theme switching (colorTheme and iconTheme)
if command -v code >/dev/null 2>&1; then
  code --install-extension Catppuccin.catppuccin-vsc --force >/dev/null 2>&1 || true
  VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"
  if [ "$THEME" = "mocha" ]; then
    THEME_NAME="Catppuccin Mocha"
    ICON_NAME="catppuccin-mocha"
  else
    THEME_NAME="Catppuccin Latte"
    ICON_NAME="catppuccin-latte"
  fi
  if [ -f "$VSCODE_SETTINGS" ]; then
    # Use jq if available, else fallback to sed
    if command -v jq >/dev/null 2>&1; then
      tmpfile=$(mktemp)
      jq --arg theme "$THEME_NAME" --arg icon "$ICON_NAME" '. + {"workbench.colorTheme": $theme, "workbench.iconTheme": $icon}' "$VSCODE_SETTINGS" > "$tmpfile" && mv "$tmpfile" "$VSCODE_SETTINGS"
    else
      # crude sed fallback: replace or add the colorTheme and iconTheme lines
      if grep -q '"workbench.colorTheme"' "$VSCODE_SETTINGS"; then
        sed -i "s/\("workbench.colorTheme" *: *\)\"[^"]*\"/\1\"$THEME_NAME\"/" "$VSCODE_SETTINGS"
      else
        sed -i "1s/^/{\n  \"workbench.colorTheme\": \"$THEME_NAME\",\n/" "$VSCODE_SETTINGS"
      fi
      if grep -q '"workbench.iconTheme"' "$VSCODE_SETTINGS"; then
        sed -i "s/\("workbench.iconTheme" *: *\)\"[^"]*\"/\1\"$ICON_NAME\"/" "$VSCODE_SETTINGS"
      else
        sed -i "1s/^/{\n  \"workbench.iconTheme\": \"$ICON_NAME\",\n/" "$VSCODE_SETTINGS"
      fi
    fi
  fi
fi

# Wallpaper switching: use backgrounds or backgrounds-latte, create latte dir and copy bg.png if missing
WALLPAPER_DIR="$HOME/.local/share/backgrounds"
if [ "$THEME" = "latte" ]; then
  LATTE_BG_DIR="$HOME/.local/share/backgrounds-latte"
  if [ ! -d "$LATTE_BG_DIR" ]; then
    mkdir -p "$LATTE_BG_DIR"
  fi
  # If no images in latte dir, copy bg.png from main backgrounds as default
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

# Reload i3 (reload config to pick up include)
if command -v i3-msg >/dev/null 2>&1; then
  i3-msg reload || true
fi

# Restart polybar (ensure all old instances are gone before launching)
pkill -f polybar || true
sleep 0.5
if [ -x "$HOME/.config/polybar/launch_polybar.sh" ]; then
  "$HOME/.config/polybar/launch_polybar.sh" &
elif [ -x "$HOME/.config/polybar/launch_polybar" ]; then
  "$HOME/.config/polybar/launch_polybar" &
fi

# Restart picom
pkill picom || true
if command -v picom >/dev/null 2>&1; then
  picom --config "$HOME/.config/picom.conf" &
fi

echo "Theme switch complete. Note: Alacritty, Neovim, and btop may need restarting to pick up new themes."
