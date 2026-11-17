#!/usr/bin/env bash
set -euo pipefail

sudo -v

echo "=========================================="
echo "   CachyOS / Hyprland / Noctalia setup"
echo "=========================================="

echo
echo "Обновление системы..."
sudo pacman -Syu --noconfirm

echo
echo "Проверка yay..."
if ! command -v yay >/dev/null 2>&1; then
    echo "yay не найден. Устанавливаю..."
    sudo pacman -S --needed --noconfirm git base-devel
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' EXIT
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
else
    echo "yay уже установлен."
fi

echo
echo "Установка официальных пакетов..."
# Устаревшие пакеты (до Noctalia) закомментированы, но оставлены для истории.
PACMAN_PACKAGES=(
    cmake
    meson
    cpio
    pkgconf
    hyprland
    niri
    adw-gtk-theme
    rsync
    zoxide
    gum                     # нужен для powermode.sh, netmode и ytdl
    hyprland-guiutils
    hyprshot
    grim
    slurp
    wtype                   # отправка горячих клавиш в OBS (Alt+1/Alt+2)
    xwayland-satellite      # XWayland для Steam/старых приложений под Niri
    wl-clipboard
    # cliphist              — заменён буфером обмена Noctalia
    # quickshell            — старый Quickshell-конфиг (anicute); Noctalia 5 не требует
    discord
    ayugram-desktop         # Telegram-клиент (репозиторий CachyOS)
    kitty
    fish
    micro
    neovim
    thunar
    thunar-archive-plugin
    tumbler
    ffmpegthumbnailer
    ark
    swayimg                 # лёгкий Wayland-просмотрщик (прописан в mimeapps.list)
    # gwenview              — заменён на swayimg, оставлен для истории
    # kcalc                 — не используется
    mpv
    cava
    btop
    htop
    fastfetch
    yazi
    udiskie
    nwg-look
    qt5ct
    qt6ct
    breeze
    breeze5
    breeze-icons
    adwaita-icon-theme
    ttf-jetbrains-mono-nerd
    # ttf-font-awesome      — пакет переименован в woff2-font-awesome
    woff2-font-awesome
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    pipewire
    pipewire-pulse
    pipewire-alsa
    wireplumber
    playerctl
    pavucontrol
    networkmanager
    # network-manager-applet — трей заменён панелью Noctalia
    nm-connection-editor
    polkit-kde-agent
    power-profiles-daemon
    upower
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gnome
    xdg-desktop-portal-gtk
    # rsync                 — дубликат, уже указан выше
    expac                   # нужен для cleanup_packages.sh
    libsecret
    # freerdp               — RDP не используется
    git
    curl
    wget
    unzip
    zip
    tar
    gzip
    xz
    jq
    ripgrep
    fd
    # npm                   — Node.js/npm не используются
)
sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"

echo
echo "Установка Noctalia..."
sudo pacman -S --needed --noconfirm noctalia noctalia-greeter greetd

echo
echo "Установка пакетов через yay..."
# justray-bin — старый трей, заменён треем Noctalia (см. autostart.lua)
# yay -S --needed --noconfirm justray-bin
yay -S --needed --noconfirm zen-browser-bin

echo
echo "Включение NetworkManager..."
sudo systemctl enable NetworkManager

echo
echo "=========================================="
echo "Установка завершена!"
echo
echo "Дальше:"
echo "  ./scripts/install.sh"
echo
echo "greetd установлен, но не включён автоматически:"
echo "  sudo systemctl enable greetd   # только если уверен в настройке входа"
echo "=========================================="
