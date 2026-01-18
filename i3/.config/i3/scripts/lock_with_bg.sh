
#!/bin/bash

# Requires: i3lock, imagemagick
# Set paths (only use primary user backgrounds dir)
PRIMARY_DIR="$HOME/.local/share/backgrounds"

# Prefer current selection in primary, then bg.png in primary
if [ -f "$PRIMARY_DIR/.current" ]; then
	BG_IMAGE="$PRIMARY_DIR/$(cat "$PRIMARY_DIR/.current")"
elif [ -f "$PRIMARY_DIR/bg.png" ]; then
	BG_IMAGE="$PRIMARY_DIR/bg.png"
else
	echo "No background image found for lock screen" >&2
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
