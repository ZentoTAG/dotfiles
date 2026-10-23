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

if [[ -f "$CONFIG_DIR/user-dirs.dirs" ]]; then
    echo "  Копирую user-dirs.dirs"
    cp -a "$CONFIG_DIR/user-dirs.dirs" "$DOTFILES_DIR/config/user-dirs.dirs"
fi

# Стягиваем кастомные ярлыки
if [[ -d "$HOME/.local/share/applications" ]]; then
    echo "  Копирую applications"
    mkdir -p "$DOTFILES_DIR/config/applications"
    rsync -a --delete --include='zapret-*.desktop' --include='flclash-*.desktop' --include='kitty-micro.desktop' --exclude='*' \
        "$HOME/.local/share/applications/" "$DOTFILES_DIR/config/applications/"
fi

echo "Готово!"
