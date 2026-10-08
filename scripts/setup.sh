#!/bin/bash

sudo -v

echo "=========================================="
echo "      CachyOS Setup Script"
echo "=========================================="

echo
echo "Обновление системы..."
sudo pacman -Syu --noconfirm

echo
echo "Проверка yay..."

if ! command -v yay >/dev/null 2>&1; then
    echo "yay не найден. Устанавливаю..."

    sudo pacman -S --needed --noconfirm git base-devel

    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay

    makepkg -si --noconfirm

    cd -
    rm -rf /tmp/yay
else
    echo "yay уже установлен."
fi

echo
echo "Установка официальных пакетов..."

sudo pacman -S --needed --noconfirm \
    rofi-emoji \
    fd \
    powertop \
    tumbler \
    ffmpegthumbnailer \
    upower \
    nwg-look \
    breeze5 \
    waypaper \
    swww \
    polkit-kde-agent \
    power-profiles-daemon \
    mpv \
    hyprland \
    hyprlock \
    base-devel \
    python-pip \
    yazi \
    hypridle \
    hyprpaper \
    rofi \
    kitty \
    dunst \
    swaync \
    cava \
    fish \
    micro \
    neovim \
    thunar \
    telegram-desktop \
    playerctl \
    pavucontrol \
    pipewire \
    pipewire-pulse \
    wireplumber \
    networkmanager \
    network-manager-applet \
    nm-connection-editor \
    wlogout \
    hyprshot \
    udiskie \
    zen-browser \
    btop \
    htop \
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
    npm \
    rust \
    ttf-jetbrains-mono-nerd \
    ttf-font-awesome \
    adwaita-icon-theme \
    qt5ct \
    gwenview \
    ark \
    kcalc \
    breeze \
    qt6ct \
    breeze-gtk

echo
echo "Установка pyright..."

sudo npm install -g pyright

echo
echo "Установка пакетов из AUR..."

yay -S --needed --noconfirm \
    cmatrix-git \
    waybar-git

echo
echo "Установка nw-manager-tui..."

if ! command -v cargo &>/dev/null; then
    echo "📦 Устанавливаю Rust..."
    sudo pacman -S --noconfirm rust
fi

if ! command -v nw-manager-tui &>/dev/null; then
    echo "📦 Устанавливаю nw-manager-tui..."
    cargo install nw-manager-tui

    echo "📁 Копирую иконки..."
    mkdir -p ~/.local/share/nw-manager-tui
    git clone --depth 1 https://github.com/z4nder/nw-manager-tui /tmp/nw-manager-tui 2>/dev/null
    cp -r /tmp/nw-manager-tui/assets ~/.local/share/nw-manager-tui/
    rm -rf /tmp/nw-manager-tui
else
    echo "✅ nw-manager-tui уже установлен"
fi

echo
echo "Включение сервисов..."

sudo systemctl enable NetworkManager

echo
echo "=========================================="
echo "Установка завершена!"
echo
echo "Теперь выполни:"
echo "./install.sh"
echo "=========================================="
