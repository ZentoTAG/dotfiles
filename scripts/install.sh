#!/bin/bash

# Определяем корень dotfiles (на уровень выше)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$HOME/.config"

echo " Шаманю с компуктером..."

if [ ! -d "$DOTFILES_DIR/config" ]; then
    echo "Ошибка: папка config/ не найдена в $DOTFILES_DIR"
    exit 1
fi

for dir in "$DOTFILES_DIR/config/"*/; do
    [ -d "$dir" ] || continue
    dir_name=$(basename "$dir")

    if [ -d "$CONFIG_DIR/$dir_name" ]; then
        echo "Обновляю $dir_name (копирую файлы)"
        cp -r "$dir"/* "$CONFIG_DIR/$dir_name/" 2>/dev/null
    else
        echo "Копирую $dir_name"
        cp -r "$dir" "$CONFIG_DIR/"
    fi
done

hyprctl reload

echo "Готово!"

