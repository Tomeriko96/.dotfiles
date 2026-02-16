
#!/bin/bash

# Requires: i3lock, imagemagick

# Detect current theme (mocha/latte) using i3 theme marker
TARGET_I3_COLORS="$HOME/.config/i3/themes/current-colors"
THEME="mocha"
if [ -f "$TARGET_I3_COLORS" ]; then
	if grep -q "# latte" "$TARGET_I3_COLORS" 2>/dev/null; then
		THEME="latte"
	fi
fi

# Set backgrounds dir based on theme (underscore for latte)
if [ "$THEME" = "latte" ]; then
	BG_DIR="$HOME/.local/share/backgrounds_latte"
else
	BG_DIR="$HOME/.local/share/backgrounds"
fi

# Prefer current selection in theme dir, then bg.png in theme dir
if [ -f "$BG_DIR/.current" ]; then
	BG_IMAGE="$BG_DIR/$(cat "$BG_DIR/.current")"
elif [ -f "$BG_DIR/bg.png" ]; then
	BG_IMAGE="$BG_DIR/bg.png"
else
	echo "No background image found for lock screen in $BG_DIR" >&2
	exit 1
fi

TMP_BG="/tmp/i3lock_bg.png"

# Get screen resolution (works for single monitor setups)
RES=$(xdpyinfo | awk '/dimensions/{print $2}')

# Blur the image only (no dimming or transparency)
convert "$BG_IMAGE" -resize "$RES^" -gravity center -extent "$RES" \
	-blur 0x8 "$TMP_BG"

# Call i3lock with the processed image
i3lock -i "$TMP_BG"

# Optionally, remove the temp file after unlocking
rm "$TMP_BG"
