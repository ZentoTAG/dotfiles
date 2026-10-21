#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$HOME/.config"

if [[ ! -d "$DOTFILES_DIR/config" ]]; then
    echo "Ошибка: папка config/ не найдена в $DOTFILES_DIR" >&2
    exit 1
fi

echo "Шаманю с компуктером..."

# Генерируемые темы и локальное состояние не копируем из репозитория
RSYNC_EXCLUDES=(
    --exclude 'noctalia.css'
    --exclude 'noctalia.conf'
    --exclude 'noctalia.jsonc'
    --exclude 'noctalia.theme'
    --exclude 'noctalia'
    --exclude 'matugen.conf'
    --exclude 'fish_variables'
    --exclude 'marks'
    --exclude 'plug/'
    --exclude 'buffers/'
    --exclude 'backups/'
    --exclude 'pngs/'
    --exclude '*.backup'
    --exclude '*.bak'
    --exclude '*.old'
    --exclude '*.orig'
)

if [[ -f "$DOTFILES_DIR/config/mimeapps.list" ]]; then
    echo "  Копирую mimeapps.list"
    cp -a "$DOTFILES_DIR/config/mimeapps.list" "$CONFIG_DIR/mimeapps.list"
fi

for dir in "$DOTFILES_DIR/config/"*/; do
    [[ -d "$dir" ]] || continue
    name="$(basename "$dir")"

    echo "  Обновляю $name"
    mkdir -p "$CONFIG_DIR/$name"
    rsync -a "${RSYNC_EXCLUDES[@]}" "$dir" "$CONFIG_DIR/$name/"
done

if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
    hyprctl reload || true
fi

echo "Готово!"
