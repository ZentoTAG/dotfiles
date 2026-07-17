# Мои команды

## Файлы и папки
ls -la                       # показать все файлы + права доступа
mkdir папка                  # создать папку
rm -rf папка                 # удалить папку и всё внутри
cp -r откуда куда            # скопировать папку рекурсивно
mv откуда куда               # переместить или переименовать

## Архивы (tar)
tar cf archive.tar папка/           # создать архив без сжатия
tar czf archive.tar.gz папка/       # создать архив + сжатие gzip
tar cJf archive.tar.xz папка/       # создать архив + сжатие xz
tar xf archive.tar                  # распаковать .tar
tar xzf archive.tar.gz              # распаковать .tar.gz
tar xJf archive.tar.xz              # распаковать .tar.xz
tar tf archive.tar                  # посмотреть что внутри без распаковки

## Запись образа на флешку
sudo dd if=/путь/к/образу.iso of=/dev/sdX bs=4M status=progress oflag=sync
# if  — входной файл (образ)
# of  — выходной файл (флешка)
# bs  — размер блока (ускоряет запись)
# status=progress — показывает прогресс
# oflag=sync — гарантирует, что данные записались физически

## Dotfiles
~/data/dotfiles/install.sh        # развернуть конфиги из репо в систему
~/data/dotfiles/pull.sh           # стянуть конфиги из системы в репо

## Git
git add .                         # добавить все изменения
git commit -m "текст"             # закоммитить с сообщением
git push                          # отправить на GitHub
git pull                          # скачать с GitHub
git status                        # проверить изменения

## Hyprland
hyprctl reload                    # перезагрузить конфиг без перезапуска
hyprctl clients | grep class      # найти класс окна (для биндов)
hyprctl binds                     # показать все горячие клавиши

## OBS (вставлять в hyprland.conf)
bind = ALT, 1, sendshortcut, CTRL, F10, class:com.obsproject.Studio   # начать запись
bind = ALT, 2, sendshortcut, CTRL, F11, class:com.obsproject.Studio   # остановить запись
# В OBS нужно назначить горячие клавиши Ctrl+F10 / Ctrl+F11

## Система
yay -Syu                          # обновить систему
sudo pacman -S пакет              # установить пакет из официальных реп
yay -S пакет                      # установить пакет из AUR
sudo pacman -Rns пакет            # удалить пакет
sudo systemctl restart sddm       # перезапустить экран входа (SDDM)

## Пути (мои папки)
~/.config/                        # все конфиги программ
~/data/dotfiles/                  # репозиторий с конфигами
~/data/downloads/                 # загрузки
~/data/screenshots/               # скриншоты
~/data/projects/                  # проекты (код)
~/data/media/wallpapers/          # обои

## Прочее
echo $XDG_SESSION_TYPE            # узнать, Wayland или X11
ps aux | grep "название"          # найти запущенный процесс
htop                              # диспетчер задач
neofetch                          # информация о системе
uname -r                          # версия ядра
