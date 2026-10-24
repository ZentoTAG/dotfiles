# Мои команды

## Файлы и папки
```bash
ls -la                       # показать все файлы + права доступа
mkdir папка                  # создать папку
rm -rf папка                 # удалить папку и всё внутри (осторожно!)
cp -r откуда куда            # скопировать папку рекурсивно
mv откуда куда               # переместить или переименовать
```

## Архивы (tar)
```bash
tar cf archive.tar папка/           # создать архив без сжатия
tar czf archive.tar.gz папка/       # создать архив + сжатие gzip
tar cJf archive.tar.xz папка/       # создать архив + сжатие xz
tar xf archive.tar                  # распаковать .tar
tar xzf archive.tar.gz              # распаковать .tar.gz
tar xJf archive.tar.xz              # распаковать .tar.xz
tar tf archive.tar                  # посмотреть содержимое без распаковки
```

## Запись образа на флешку
```bash
sudo dd if=/путь/к/образу.iso of=/dev/sdX bs=4M status=progress oflag=sync
# if  — входной файл (образ)
# of  — выходной файл (флешка)
# bs  — размер блока (ускоряет запись)
# status=progress — показывает прогресс
# oflag=sync — гарантирует физическую запись
```

## Dotfiles
```bash
~/data/dotfiles/scripts/install.sh    # развернуть конфиги из репо в систему
~/data/dotfiles/scripts/pull.sh       # стянуть конфиги из системы в репо
~/data/dotfiles/scripts/auto_push.sh  # закоммитить и запушить изменения
```

## Git
```bash
git add .
git commit -m "текст"
git push
git pull
git status
```

## Hyprland / Noctalia
```bash
hyprctl reload                    # перезагрузить конфиг без перезапуска
hyprctl configerrors              # проверить ошибки конфига
hyprctl clients | grep class      # найти класс окна
hyprctl binds                     # показать горячие клавиши

noctalia msg templates-apply      # перегенерировать темы (GTK, Qt, Kitty, btop, cava)
noctalia msg settings-toggle      # настройки Noctalia
noctalia msg panel-toggle launcher
```

## OBS
```text
SUPER+ALT+1  — начать запись (OBS должен слушать Ctrl+F10)
SUPER+ALT+2  — остановить запись (Ctrl+F11)
```

## Система
```bash
yay -Syu                          # обновить систему
sudo pacman -S пакет              # установить пакет из официальных реп
yay -S пакет                      # установить пакет из AUR
sudo pacman -Rns пакет            # удалить пакет
sudo systemctl restart greetd     # перезапустить greetd (если используется)
fastfetch                         # информация о системе
```

## Пути
```text
~/.config/                        # конфиги программ
~/data/dotfiles/                  # репозиторий с конфигами
~/data/downloads/                 # загрузки
~/data/media/screenshots/         # скриншоты
~/data/dev/projects/              # проекты (код)
~/data/media/wallpapers/          # обои
~/data/backups/                   # резервные копии конфигов
```

## Прочее
```bash
echo $XDG_SESSION_TYPE            # Wayland или X11
ps aux | grep "название"          # найти процесс
btop                              # системный монитор
uname -r                          # версия ядра
```

## Конвертация видео и обоев
```bash
cd ~/data/media/videos
for file in *.mp4; do
    ffmpeg -i "$file" -vf scale=1920:1080 -c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus "${file%.mp4}.webm"
done

cd ~/data/dotfiles/assets/backgrounds
for file in *.jpg *.jpeg; do
    ffmpeg -i "$file" -c:v libwebp -quality 85 "${file%.*}.webp"
done
```
