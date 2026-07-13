#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

echo " Шаманю с компуктером..."

for dir in "$DOTFILES_DIR"/*/; do
    dir_name=$(basename "$dir")
    if [ -d "$CONFIG_DIR/$dir_name" ]; then
        echo "dir_name уже существует, пропускаю"
    else
        echo "Копирую $dir_name"
        cp -r "$dir" "$CONFIG_DIR/"
    fi
done

echo "Готово!"

