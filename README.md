# Dotfiles

Hyprland · Noctalia · Kitty · Fish · Neovim

## Состав

| Компонент | Описание |
|-----------|----------|
| Hyprland | Wayland-композитор, конфиг на Lua |
| Noctalia | Панель, лаунчер, уведомления, lock/idle, обои и темы |
| Kitty | Терминал |
| Fish | Оболочка |
| Thunar | Файловый менеджер |
| Micro / Neovim | Редакторы |
| btop / cava | Системный монитор и визуализация звука |
| GTK / Qt | Единая палитра Noctalia для GTK3/GTK4, Qt5/Qt6 и KDE-приложений |

## Установка

```bash
git clone git@github.com:ZentoTAG/dotfiles.git ~/data/dotfiles
cd ~/data/dotfiles
./scripts/setup.sh    # установить пакеты (нужен sudo)
./scripts/install.sh  # развернуть конфиги в ~/.config
```

`install.sh` копирует конфиги из репозитория и не удаляет лишние файлы в `~/.config`.
Сгенерированные темы Noctalia (GTK CSS, цвета Qt, тема Kitty и т.п.) в репозитории не хранятся:
их создаёт `noctalia msg templates-apply`.

## Обновление

```bash
cd ~/data/dotfiles
./scripts/pull.sh       # забрать текущие конфиги из системы в репозиторий
./scripts/auto_push.sh  # закоммитить и запушить изменения
```

`pull.sh` просто синхронизирует `~/.config` с `config/` в репозитории; отдельных копий в `~/data/backups/` не делает.

## Обслуживание

```bash
./scripts/cleanup_packages.sh --dry-run  # посмотреть список неиспользуемых пакетов
sudo ./scripts/cleanup_packages.sh       # удалить после проверки
```

## Структура

```text
~/data/dotfiles/
├── assets/backgrounds/   # обои
├── config/               # конфиги для ~/.config/
├── docs/                 # шпаргалка
└── scripts/              # setup.sh, install.sh, pull.sh, auto_push.sh
```

## Система

- OS: CachyOS (Arch)
- WM: Hyprland
- Shell: Noctalia
- GPU: NVIDIA GTX 1660 Ti
- CPU: Intel Xeon E5-2640 v0

ZentoTAG · 2026
