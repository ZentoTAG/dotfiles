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
    --exclude 'noctalia.kdl'
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

# Niri is installed alongside Hyprland, so both sessions remain selectable.
# Noctalia's generated niri.kdl is intentionally not tracked; templates-apply
# creates it and adds the include to ~/.config/niri/config.kdl.

# Восстанавливаем конфиги оболочек
for shell_file in .bashrc .bash_profile .zshrc .zprofile; do
    if [[ -f "$DOTFILES_DIR/config/$shell_file" ]]; then
        echo "  Восстанавливаю $shell_file"
        cp -a "$DOTFILES_DIR/config/$shell_file" "$HOME/$shell_file"
    fi
done

# Копирование кастомных .desktop ярлыков
if [[ -d "$DOTFILES_DIR/config/applications" ]]; then
    echo "  Обновляю applications"
    mkdir -p "$HOME/.local/share/applications"
    rsync -a "$DOTFILES_DIR/config/applications/" "$HOME/.local/share/applications/"
    update-desktop-database "$HOME/.local/share/applications" || true
fi

# Настройка синхронизации иконок папок с палитрой Noctalia
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"
install -m 0644 "$DOTFILES_DIR/scripts/systemd/user/noctalia-folder-icons.service" \
    "$SYSTEMD_USER_DIR/noctalia-folder-icons.service"
install -m 0644 "$DOTFILES_DIR/scripts/systemd/user/noctalia-folder-icons.path" \
    "$SYSTEMD_USER_DIR/noctalia-folder-icons.path"
chmod +x "$DOTFILES_DIR/scripts/noctalia-folder-icons"
systemctl --user daemon-reload
"$DOTFILES_DIR/scripts/noctalia-folder-icons"
systemctl --user enable --now noctalia-folder-icons.path

if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
    hyprctl reload || true
fi

if command -v niri >/dev/null 2>&1; then
    niri validate -c "$CONFIG_DIR/niri/config.kdl" || true
fi

echo "Готово!"
