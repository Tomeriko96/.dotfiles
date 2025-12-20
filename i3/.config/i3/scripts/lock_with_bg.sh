#!/bin/bash

# Set paths
BG_IMAGE="$HOME/.config/backgrounds/bg.png"
TMP_BG="/tmp/i3lock_bg.png"

# Get screen resolution (works for single monitor setups)
RES=$(xdpyinfo | awk '/dimensions/{print $2}')

# Scale the image to fit the screen
convert "$BG_IMAGE" -resize "$RES^" -gravity south -extent "$RES" "$TMP_BG"

# Call i3lock with the scaled image
i3lock -i "$TMP_BG"

# Optionally, remove the temp file after unlocking
rm "$TMP_BG"

