# Dotfiles

Hyprland · Waybar · Kitty · Fish · Neovim

## Состав

| Компонент | Описание |
|-----------|----------|
| Hyprland | Wayland-композитор |
| Waybar | Панель |
| Rofi | Лаунчер |
| Kitty | Терминал |
| Swaync | Уведомления |
| hyprlock | Экран блокировки |
| waypaper | Управление обоями |
| Fish | Оболочка |
| Micro / Neovim | Редакторы |

## Установка

```bash
git clone git@github.com:ZentoTAG/dotfiles.git ~/data/dotfiles
cd ~/data/dotfiles
./scripts/setup.sh
./scripts/install.sh

## Обновление
cd ~/data/dotfiles
./scripts/pull.sh
git add .
git commit -m "update"
git push

## Структура
~/data/dotfiles/
├── assets/backgrounds/   # обои
├── config/               # конфиги (~/.config/)
├── docs/                 # шпаргалка
└── scripts/              # install.sh, pull.sh, setup.sh

## Система
OS: CachyOS (Arch)
WM: Hyprland
GPU: NVIDIA GTX 1660 Ti
CPU: Xeon E5-2640 v0

ZentoTAG · 2026
---
