
#!/bin/bash

# Requires: i3lock, imagemagick
# Set paths
BG_IMAGE="$HOME/.local/share/backgrounds/bg.png"
TMP_BG="/tmp/i3lock_bg.png"

# Get screen resolution (works for single monitor setups)
RES=$(xdpyinfo | awk '/dimensions/{print $2}')

# Blur and dim the image
convert "$BG_IMAGE" -resize "$RES^" -gravity center -extent "$RES" \
	-blur 0x8 -fill black -colorize 40% "$TMP_BG"

# Call i3lock with the processed image
i3lock -i "$TMP_BG"

# Optionally, remove the temp file after unlocking
rm "$TMP_BG"
