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
    mpv \
    hyprland \
    hyprlock \
    base-devel \
    python-pip \
    yazi \
    hyprpolkitagent \
    hypridle \
    hyprpaper \
    waybar \
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
    polkit-kde-agent \
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
    zen-browser-bin \
    cmatrix-git

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
