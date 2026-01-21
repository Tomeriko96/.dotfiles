#!/bin/sh


# Use the current timestamp as the unique filename of the screenshot.
FILE_PATH="/home/$USER/Pictures/screenshot-$(date -u +'%Y%m%d-%H%M%SZ').png"

main() {
    case $1 in
        full)
            # Fullscreen capture, save to file and copy to clipboard
            flameshot full -c -p "$FILE_PATH"
            ;;
        select)
            # GUI region select, save to file and copy to clipboard
            flameshot gui -c -p "$FILE_PATH"
            ;;
        window)
            # Simulate window capture by letting user select a window region
            flameshot gui -c -p "$FILE_PATH"
            ;;
    esac
}

main "$@"
