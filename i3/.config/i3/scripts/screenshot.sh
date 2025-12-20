#!/bin/sh

# Use the current timestamp as the unique filename of the screenshot.
FILE_PATH="/home/$USER/Pictures/screenshot-$(date -u +'%Y%m%d-%H%M%SZ').png"

main() {
    case $1 in
        full) maim --format=png $FILE_PATH ;;
        select) maim --select $FILE_PATH ;;
        window) maim --window $(xdotool getactivewindow) $FILE_PATH
    esac
}

main "$@"
