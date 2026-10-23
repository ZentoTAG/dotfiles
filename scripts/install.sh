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

if [[ -f "$DOTFILES_DIR/config/user-dirs.dirs" ]]; then
    echo "  Копирую user-dirs.dirs"
    cp -a "$DOTFILES_DIR/config/user-dirs.dirs" "$CONFIG_DIR/user-dirs.dirs"
    # Обновить кэш xdg-user-dirs (если утилита установлена)
    if command -v xdg-user-dirs-update >/dev/null 2>&1; then
        xdg-user-dirs-update
    fi
fi

for dir in "$DOTFILES_DIR/config/"*/; do
    [[ -d "$dir" ]] || continue
    name="$(basename "$dir")"

    # Пропускаем applications, так как для них есть отдельный блок ниже
    [[ "$name" == "applications" ]] && continue

    echo "  Обновляю $name"
    mkdir -p "$CONFIG_DIR/$name"
    rsync -a "${RSYNC_EXCLUDES[@]}" "$dir" "$CONFIG_DIR/$name/"
done


# Копирование кастомных .desktop ярлыков
if [[ -d "$DOTFILES_DIR/config/applications" ]]; then
    echo "  Обновляю applications"
    mkdir -p "$HOME/.local/share/applications"
    rsync -a "$DOTFILES_DIR/config/applications/" "$HOME/.local/share/applications/"
    update-desktop-database "$HOME/.local/share/applications" || true
fi

if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
    hyprctl reload || true
fi

echo "Готово!"
