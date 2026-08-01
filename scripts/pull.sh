#!/bin/bash

FOLDERS="yazi btop gtk-3.0 gtk-4.0 Thunar fastfetch cava swaync dunst fish hypr kitty micro nvim waybar rofi waypaper qt6ct"

DOTFILES_DIR="$HOME/data/dotfiles"
CONFIG_DIR="$HOME/.config"

echo "Стягиваю конфиги..."

for folder in $FOLDERS; do
    if [ -d "$CONFIG_DIR/$folder" ]; then
        echo "  Копирую $folder"
        rm -rf "$DOTFILES_DIR/config/$folder"
        cp -rf "$CONFIG_DIR/$folder" "$DOTFILES_DIR/config/"
    else
        echo "  ⚠️ $folder не найден в ~/.config/"
    fi
done

# Копируем mimeapps.list
if [ -f "$CONFIG_DIR/mimeapps.list" ]; then
    echo "  Копирую mimeapps.list"
    cp "$CONFIG_DIR/mimeapps.list" "$DOTFILES_DIR/config/"
fi

echo "Готово!"
