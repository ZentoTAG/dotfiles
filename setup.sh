#!/bin/bash

# ============================================
#  УСТАНОВКА ПАКЕТОВ ДЛЯ CACHYOS
# ============================================

echo "Обновление системы..."
sudo pacman -Syu --noconfirm

echo "Установка базовых пакетов..."
sudo pacman -S --noconfirm \
    waybar \
    hyprland \
    wofi \
    kitty \
    dunst \
    cava \
    fish \
    micro \
    neovim \
    thunar \
    telegram-desktop \
    playerctl \
    pavucontrol \
    pulseaudio \
    pipewire \
    wireplumber \
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
    base-devel \
    yay \
    jq \
    ripgrep

# ============================================
#  УСТАНОВКА NPM И PYRIGHT
# ============================================

echo "📦 Установка npm..."
sudo pacman -S --noconfirm npm

echo "📦 Установка pyright через npm..."
sudo npm install -g pyright

# ============================================
#  УСТАНОВКА ИЗ AUR
# ============================================

echo "📦 Установка пакетов из AUR..."
yay -S --noconfirm \
    sddm \
    zen-browser-bin

# ============================================
#  НАСТРОЙКА ТЕМ И ШРИФТОВ
# ============================================

echo "🎨 Установка тем и шрифтов..."
sudo pacman -S --noconfirm \
    ttf-jetbrains-mono-nerd \
    ttf-font-awesome \
    adwaita-icon-theme

# ============================================
#  ЗАВЕРШЕНИЕ
# ============================================

echo "✅ Готово! Теперь запусти install.sh для разворачивания конфигов."
