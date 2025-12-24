#!/bin/sh
# monitor-layout.sh - Handles DP-2 external only or eDP-1 laptop fallback

# Always ensure laptop screen is available as fallback first
xrandr --output eDP-1 --auto

# Check if external monitor DP-2 is connected
if xrandr | grep -q "^DP-2 connected"; then
    # External connected: use DP-2 only, disable laptop screen
    xrandr --output DP-2 --auto --primary --output eDP-1 --off
else
    # External disconnected: use laptop screen only, ensure DP-2 is off
    xrandr --output eDP-1 --auto --primary --output DP-2 --off
fi

