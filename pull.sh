#!/bin/bash

# Список папок, которые нужно синхронизировать
FOLDERS="cava dunst fish hypr kitty micro nvim waybar wofi"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

echo "Стягиваю конфиги из ~/.config/ в dotfiles..."

for folder in $FOLDERS; do
    if [ -d "$CONFIG_DIR/$folder" ]; then
        echo "  Копирую $folder"
        rm -rf "$DOTFILES_DIR/$folder"
        cp -r "$CONFIG_DIR/$folder" "$DOTFILES_DIR/"
    else
        echo "  ⚠️folder не найден в ~/.config/"
    fi
done

echo "Готово!"
