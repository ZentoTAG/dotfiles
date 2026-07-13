# Dotfiles

Hyprland · Waybar · Kitty · Fish · Neovim

## Состав

| Компонент | Описание |
|-----------|----------|
| Hyprland | Wayland-композитор |
| Waybar | Панель |
| Wofi | Лаунчер |
| Kitty | Терминал |
| Dunst | Уведомления |
| Cava | Аудиовизуализатор |
| Fish | Оболочка |
| Micro | Редактор |
| Neovim | Редактор (NvChad) |

## Установка

git clone git@github.com:ZentoTAG/dotfiles.git ~/data/dotfiles
cd ~/data/dotfiles
./install.sh

## Структура

~/.config/
├── cava/
├── dunst/
├── fish/
├── hypr/
├── kitty/
├── micro/
├── nvim/
├── waybar/
└── wofi/

## Обновление

cd ~/data/dotfiles
git add .
git commit -m "update"
git push

## Система

- OS: CachyOS (Arch)
- WM: Hyprland
- GPU: NVIDIA GTX 1660 Ti
- CPU: Xeon E5-2640 v0

ZentoTAG · 2026
