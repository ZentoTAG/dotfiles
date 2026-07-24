#!/bin/bash

FOLDERS="cava dunst fish hypr kitty micro nvim waybar rofi waypaper"

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

echo "Готово!"
