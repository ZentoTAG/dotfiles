#!/bin/bash

ACTION="$1"

case "$ACTION" in
    wallpaper)
        nohup waypaper > /dev/null 2>&1 &
        ;;
    gtk)
        nohup nwg-look > /dev/null 2>&1 &
        ;;
    qt)
        nohup qt6ct > /dev/null 2>&1 &
        ;;
    audio)
        nohup pavucontrol > /dev/null 2>&1 &
        ;;
    network)
        nohup nm-connection-editor > /dev/null 2>&1 &
        ;;
    display)
        nohup wdisplays > /dev/null 2>&1 &
        ;;
    quickshell)
        nohup kitty -e micro "$HOME/.config/quickshell/shell.qml" > /dev/null 2>&1 &
        ;;
    hyprland)
        nohup kitty -e micro "$HOME/.config/hypr/hyprland.conf" > /dev/null 2>&1 &
        ;;
    waybar)
        nohup kitty -e micro "$HOME/.config/waybar/config" > /dev/null 2>&1 &
        ;;
esac

exit 0
