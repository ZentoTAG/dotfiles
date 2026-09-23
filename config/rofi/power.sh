#!/bin/bash

THEME="$HOME/.config/rofi/theme.rasi"

choice=$(printf '%s\n' \
    "󰌾  Lock" \
    "󰍃  Logout" \
    "󰜉  Reboot" \
    "󰐥  Shutdown" \
    | rofi -dmenu \
        -i \
        -p "Power" \
        -theme "$THEME")

case "$choice" in
    *"Lock")
        hyprlock
        ;;

    *"Logout")
        hyprctl dispatch exit
        ;;

    *"Reboot")
        systemctl reboot
        ;;

    *"Shutdown")
        systemctl poweroff
        ;;
esac
