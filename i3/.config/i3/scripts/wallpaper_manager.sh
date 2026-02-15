#!/usr/bin/env bash
# Improved i3 wallpaper manager - robust, debug-friendly, handles multi-monitor
#
# THEME-AWARE WALLPAPER DIRECTORY USAGE:
#   - For Catppuccin Mocha (dark): use ./backgrounds (symlinked to ~/.local/share/backgrounds)
#   - For Catppuccin Latte (light): use ./backgrounds-latte (symlinked to ~/.local/share/backgrounds-latte)
#
#   theme-switch.sh will call this script with the correct directory for the current theme.
#   This script will ONLY use the directory passed as the first argument (if valid),
#   so latte mode will never show dark wallpapers and vice versa.
#
# Usage: wallpaper_manager.sh [apply|next|prev|random|list|set <name>] [WALLPAPER_DIR]
#
# Place wallpapers in:
#   - ~/.local/share/backgrounds         (for dark/mocha)
#   - ~/.local/share/backgrounds-latte   (for light/latte)


set -euo pipefail

readonly SCRIPT_DIR="${BASH_SOURCE[0]%/*}"

# THEME DIRECTORY LOGIC
# 1. If a directory argument is given, use it (for theme-switch.sh)
# 2. Otherwise, auto-detect theme from ~/.config/i3/themes/current-colors
#    and use the correct backgrounds directory for mocha/latte
if [ -n "${1:-}" ] && [ -d "$1" ]; then
    DIR="$1"
else
    # Try to detect theme from i3 current-colors
    I3_COLORS="$HOME/.config/i3/themes/current-colors"
    if [ -f "$I3_COLORS" ]; then
        if grep -q '# latte' "$I3_COLORS"; then
            DIR="$HOME/.local/share/backgrounds_latte"
        else
            DIR="$HOME/.local/share/backgrounds"
        fi
    else
        DIR="$HOME/.local/share/backgrounds"
    fi
fi
CURRENT_FILE="$DIR/.current"
LOG_FILE="/tmp/wallpaper_manager.log"

# Colors for better error feedback
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly NC='\033[0m' # No Color

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}ERROR: $1${NC}" >&2 | tee -a "$LOG_FILE"
    exit 1
}

ensure_feh() {
    if ! command -v feh >/dev/null 2>&1; then
        error "feh is required but not installed. Install with: sudo apt install feh"
    fi
}

ensure_dir() {
    mkdir -p "$DIR" || error "Cannot create directory: $DIR"
}

# Get sorted list of image files (more formats, natural sort)
images() {
    shopt -s nullglob
    local files=("$DIR"/*.{png,jpg,jpeg,gif,bmp,tiff,svg,webp,JPG,JPEG,PNG})
    if (( ${#files[@]} == 0 )); then
        return 1
    fi
    printf '%s\n' "${files[@]##*/}" | LC_ALL=C sort -V
}

# Initialize .current if missing (pick first image)
ensure_current() {
    if [[ ! -f "$CURRENT_FILE" ]]; then
        local first_image
        first_image=$(images | head -n1)
        if [[ -n "$first_image" ]]; then
            log "No .current file found, setting first image: $first_image"
            echo "$first_image" > "$CURRENT_FILE"
        else
            error "No images found in $DIR"
        fi
    fi
}

# Apply current wallpaper to ALL outputs (feh handles multi-monitor automatically)
apply_wallpaper() {
    local image="$1"
    local image_path="$DIR/$image"
    
    [[ ! -f "$image_path" ]] && error "Image not found: $image_path"
    
    log "Applying wallpaper: $image_path"
    feh --no-fehbg --bg-scale "$image_path" || error "feh failed to set wallpaper"
    notify-send -t 1000 "Wallpaper" "Set: ${image##*/}" 2>/dev/null || true
}

# Main apply command
apply_current() {
    ensure_dir
    ensure_feh
    ensure_current
    
    local current_image
    current_image=$(cat "$CURRENT_FILE")
    apply_wallpaper "$current_image"
}

# Cycle through wallpapers (next/prev)
cycle() {
    local direction="$1"  # "next" or "prev"
    local image_list=($(images))
    
    (( ${#image_list[@]} == 0 )) && error "No images found in $DIR"
    
    local current_image
    if [[ -f "$CURRENT_FILE" ]]; then
        current_image=$(cat "$CURRENT_FILE")
    else
        current_image="${image_list[0]}"
    fi
    
    # Find current index
    local current_idx=-1
    for i in "${!image_list[@]}"; do
        if [[ "${image_list[i]}" == "$current_image" ]]; then
            current_idx=$i
            break
        fi
    done
    
    # Calculate new index
    if (( current_idx == -1 )); then
        current_idx=0
    elif [[ "$direction" == "next" ]]; then
        (( current_idx = (current_idx + 1) % ${#image_list[@]} ))
    else  # prev
        (( current_idx = (current_idx - 1 + ${#image_list[@]} ) % ${#image_list[@]} ))
    fi
    
    local new_image="${image_list[current_idx]}"
    echo "$new_image" > "$CURRENT_FILE"
    apply_wallpaper "$new_image"
    log "Cycled $direction -> $new_image (index $current_idx/${#image_list[@]})"
}

# Set specific wallpaper
set_wallpaper() {
    local image_name="$1"
    [[ -z "$image_name" ]] && error "No wallpaper name provided"
    
    local image_path="$DIR/$image_name"
    [[ ! -f "$image_path" ]] && error "Wallpaper not found: $image_path"
    
    echo "$image_name" > "$CURRENT_FILE"
    apply_wallpaper "$image_name"
    log "Set specific wallpaper: $image_name"
}

# Pick random wallpaper
random_wallpaper() {
    local image_list=($(images))
    (( ${#image_list[@]} == 0 )) && error "No images found in $DIR"
    
    local random_idx=$(( RANDOM % ${#image_list[@]} ))
    local random_image="${image_list[random_idx]}"
    
    echo "$random_image" > "$CURRENT_FILE"
    apply_wallpaper "$random_image"
    log "Random wallpaper: $random_image"
}

# List all available wallpapers
list_wallpapers() {
    images || echo "No images found in $DIR"
}

# Main command dispatch
main() {
    local cmd="${1:-apply}"
    
    log "Running: $0 $*" 
    
    case "$cmd" in
        apply)
            apply_current
            ;;
        next)
            cycle "next"
            ;;
        prev)
            cycle "prev"
            ;;
        random)
            random_wallpaper
            ;;
        set)
            shift
            set_wallpaper "$1"
            ;;
        list)
            list_wallpapers
            ;;
        *)
            cat << EOF
Usage: $0 [apply|next|prev|random|set <name>|list]

Commands:
  apply    - Set current wallpaper (default)
  next     - Next wallpaper  
  prev     - Previous wallpaper
  random   - Random wallpaper
  set <name> - Set specific wallpaper filename
  list     - List available wallpapers

Wallpapers should be placed in: $DIR
EOF
            exit 0
            ;;
    esac
}

main "$@"
