#!/bin/bash
case "$ROFI_RETV" in
    0)
        printf '%s\0info\x1f%s\n' "Обои" "wallpaper"
        printf '%s\0info\x1f%s\n' "GTK-темы" "gtk"
        printf '%s\0info\x1f%s\n' "QT-темы" "qt"
        printf '%s\0info\x1f%s\n' "Звук" "audio"
        printf '%s\0info\x1f%s\n' "Сеть" "network"
        printf '%s\0info\x1f%s\n' "Мониторы" "display"
        printf '%s\0info\x1f%s\n' "Quickshell" "quickshell"
        printf '%s\0info\x1f%s\n' "Hyprland" "hyprland"
        printf '%s\0info\x1f%s\n' "Waybar" "waybar"
        ;;
    1)
        "$HOME/.config/rofi/settings.sh" "$ROFI_INFO"
        ;;
esac
