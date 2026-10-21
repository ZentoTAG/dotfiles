#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/data/dotfiles"
CONFIG_DIR="$HOME/.config"

FOLDERS=(
    btop
    cava
    fastfetch
    fish
    gtk-3.0
    gtk-4.0
    hypr
    kitty
    micro
    mpv
    nvim
    nwg-look
    qt5ct
    qt6ct
    Thunar
    yazi
)

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

echo "Стягиваю конфиги..."
for folder in "${FOLDERS[@]}"; do
    if [[ -d "$CONFIG_DIR/$folder" ]]; then
        echo "  Копирую $folder"
        mkdir -p "$DOTFILES_DIR/config/$folder"
        rsync -a --delete "${RSYNC_EXCLUDES[@]}" \
            "$CONFIG_DIR/$folder/" "$DOTFILES_DIR/config/$folder/"
    else
        echo "  ⚠️  $folder не найден в ~/.config/"
    fi
done

if [[ -f "$CONFIG_DIR/mimeapps.list" ]]; then
    echo "  Копирую mimeapps.list"
    cp -a "$CONFIG_DIR/mimeapps.list" "$DOTFILES_DIR/config/mimeapps.list"
fi

echo "Готово!"
