#!/usr/bin/env bash
set -euo pipefail

sudo -v

echo "=========================================="
echo "      CachyOS / Hyprland setup"
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
sudo pacman -S --needed --noconfirm \
    hyprland \
    zoxide \
    hyprland-guiutils \
    hyprshot \
    grim \
    slurp \
    wl-clipboard \
    cliphist \
    quickshell \
    discord \
    kitty \
    fish \
    micro \
    neovim \
    thunar \
    thunar-archive-plugin \
    tumbler \
    ffmpegthumbnailer \
    ark \
    gwenview \
    kcalc \
    mpv \
    cava \
    btop \
    htop \
    fastfetch \
    yazi \
    udiskie \
    nwg-look \
    qt5ct \
    qt6ct \
    breeze \
    breeze5 \
    breeze-icons \
    adwaita-icon-theme \
    ttf-jetbrains-mono-nerd \
    ttf-font-awesome \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    wireplumber \
    playerctl \
    pavucontrol \
    networkmanager \
    network-manager-applet \
    nm-connection-editor \
    polkit-kde-agent \
    power-profiles-daemon \
    upower \
    xdg-desktop-portal \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    rsync \
    expac \
    libsecret \
    freerdp \
    git \
    curl \
    wget \
    unzip \
    zip \
    tar \
    gzip \
    xz \
    jq \
    ripgrep \
    fd \
    npm

echo
echo "Установка Noctalia..."
sudo pacman -S --needed --noconfirm noctalia noctalia-greeter greetd

echo
echo "Установка AUR-пакетов..."
yay -S --needed --noconfirm zen-browser-bin justray-bin

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
