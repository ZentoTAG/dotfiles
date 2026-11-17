#!/usr/bin/env bash
set -euo pipefail

# Безопасное удаление пакетов, которые больше не используются.
# Запускать только после проверки списка:
#   sudo ./scripts/cleanup_packages.sh
#   sudo ./scripts/cleanup_packages.sh --yes
#   ./scripts/cleanup_packages.sh --dry-run   # только показать список
#
# quickshell, justray-bin, Qt5, greetd/noctalia-greeter, discord/vesktop
# намеренно не входят в список.
# headers можно убрать из CANDIDATES, если собираешь DKMS-модули.

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
fi

if [[ ${EUID} -ne 0 && $DRY_RUN -eq 0 ]]; then
    echo "Запусти через sudo: sudo $0" >&2
    echo "Только посмотреть список: $0 --dry-run" >&2
    exit 1
fi

CANDIDATES=(
    waybar-git
    rofi
    rofi-emoji
    dunst
    swaync
    wlogout
    waypaper
    hyprlock
    hypridle
    hyprpaper
    telegram-desktop
    ttf-meslo-nerd
    cachyos-zsh-config
    cachyos-wallpapers
    breeze-gtk
    linux-cachyos-headers
    linux-cachyos-lts-headers
)

# VLC-плагины без самого VLC не нужны
if ! pacman -Qq vlc >/dev/null 2>&1; then
    while IFS= read -r pkg; do
        CANDIDATES+=("$pkg")
    done < <(pacman -Qq | grep -E '^vlc-plugin')
fi

PROTECTED=(
    quickshell
    justray-bin
    qt5-base
    qt5ct
    qt5-declarative
    qt5-multimedia
    qt5-speech
    qt5-svg
    qt5-translations
    qt5-wayland
    qt5-x11extras
    greetd
    greetd-agreety
    noctalia
    noctalia-greeter
    discord
    vesktop-bin
)

INSTALLED=()
for pkg in "${CANDIDATES[@]}"; do
    if ! pacman -Qq "$pkg" >/dev/null 2>&1; then
        continue
    fi
    for keep in "${PROTECTED[@]}"; do
        if [[ "$pkg" == "$keep" ]]; then
            echo "Пропускаю защищённый пакет: $pkg" >&2
            continue 2
        fi
    done
    INSTALLED+=("$pkg")
done

if (( ${#INSTALLED[@]} == 0 )); then
    echo "Нечего удалять."
    exit 0
fi

echo "Будут удалены пакеты:"
printf '  %s\n' "${INSTALLED[@]}"
echo
echo "Их размер (приблизительно):"
expac -H M '%m\t%n' "${INSTALLED[@]}" 2>/dev/null | sort -hr || true
echo

if (( DRY_RUN )); then
    echo "Dry-run: удаление не выполнено."
    exit 0
fi

if [[ "${1:-}" != "--yes" ]]; then
    read -r -p "Продолжить? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || { echo "Отменено."; exit 0; }
fi

TARGET_HOME="$(getent passwd "${SUDO_USER:-$(id -un)}" | cut -d: -f6)"
BACKUP_DIR="$TARGET_HOME/data/backups/pacman-removed-$(date +%Y-%m-%d_%H-%M-%S)"
mkdir -p "$BACKUP_DIR"
pacman -Q "${INSTALLED[@]}" > "$BACKUP_DIR/packages-before-removal.txt"

pacman -Rns --noconfirm "${INSTALLED[@]}"
echo "Готово. Список удалённых пакетов: $BACKUP_DIR/packages-before-removal.txt"
