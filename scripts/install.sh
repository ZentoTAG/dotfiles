#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

echo " Шаманю с компуктером..."

for dir in "$DOTFILES_DIR/config/"*/; do
    dir_name=$(basename "$dir")
    if [ -d "$CONFIG_DIR/$dir_name" ]; then
        echo "Обновляю $dir_name (копирую файлы)"
        cp -r "$dir"/* "$CONFIG_DIR/$dir_name/"
    else
        echo "Копирую $dir_name"
        cp -r "$dir" "$CONFIG_DIR/"
    fi
done

echo "Готово!"
