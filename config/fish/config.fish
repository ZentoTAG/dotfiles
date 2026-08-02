source /usr/share/cachyos-fish-config/cachyos-config.fish

# Отключаем fastfetch
function fish_greeting
end

# Копирование в буфер
function copy
    wl-copy
end

# Показать содержимое всех файлов с указанным расширением (исключая бинарные папки)
function show
    set ext $argv[1]
    set target $argv[2]
    
    if test -z "$ext"
        echo "❌ Укажи расширение, например: show txt"
        return 1
    end
    
    if test -z "$target"
        set target .
    end
    
    # Ищем файлы, исключая папки micro/buffers и micro/backups
    find $target -type f -name "*.$ext" \
        ! -path "*/micro/buffers/*" \
        ! -path "*/micro/backups/*" \
        ! -name "*.db" \
        ! -name "*.sqlite" \
        ! -name "*.bin" \
        ! -name "*.so" \
        ! -name "*.dll" \
        ! -name "*.o" \
        ! -name "*.exe" \
        -exec echo "=== {} ===" \; -exec cat {} \;
end

function discord-proxy
    # Запускаем SpoofDPI в фоне
    spoofdpi &
    # Ждём секунду, чтобы он успел подняться
    sleep 1
    # Запускаем Discord
    discord
end

function showall
    set target $argv[1]
    if test -z "$target"
        set target .
    end
    
    # Исключаем бинарные файлы
    find $target -type f \
        ! -name "*.png" \
        ! -name "*.jpg" \
        ! -name "*.jpeg" \
        ! -name "*.gif" \
        ! -name "*.webp" \
        ! -name "*.ico" \
        ! -name "*.svg" \
        ! -name "*.ttf" \
        ! -name "*.otf" \
        ! -name "*.woff" \
        ! -name "*.woff2" \
        ! -name "*.mp3" \
        ! -name "*.mp4" \
        ! -name "*.webm" \
        ! -name "*.avi" \
        ! -name "*.mkv" \
        ! -name "*.pdf" \
        ! -name "*.zip" \
        ! -name "*.gz" \
        ! -name "*.tar" \
        ! -name "*.xz" \
        ! -name "*.db" \
        ! -name "*.sqlite" \
        ! -name "*.so" \
        ! -name "*.dll" \
        ! -name "*.o" \
        ! -name "*.exe" \
        ! -name "*.bin" \
        -exec echo "=== {} ===" \; -exec cat {} \;
end

# ============================================
# РЕДАКТОРЫ И РАЗРАБОТКА
# ============================================
alias b "bash"
alias m "micro"
alias g "git"
alias n "nvim"
alias ga "git add"
alias gc "git commit -m"
alias gpush "git push"
alias gpull "git pull"
alias yz "yazi"

# ============================================
# ПРОЕКТЫ И КОНФИГИ
# ============================================
alias prog "cd ~/data/programs/"
alias dots "cd ~/data/dotfiles"
alias com "micro ~/data/dotfiles/docs/commands.md"
alias combat "bat ~/data/dotfiles/docs/commands.md"
alias comcat "cat ~/data/dotfiles/docs/commands.md"
alias hypr "cd ~/.config/hypr/"
alias config "cd ~/.config/"

# ============================================
# СИСТЕМА
# ============================================
alias upd "sudo pacman -Syu"
alias kl "killall"
alias vacuum "journalctl --vacuum-size=100M"
alias syslog_emerg "sudo dmesg --level=emerg,alert,crit"
alias syslog "sudo dmesg --level=err,warn"
alias du-sort "du -sh * | sort -h"
alias foldersize "du -sh"
alias sz "du -sh"

# ============================================
# УТИЛИТЫ
# ============================================
alias yt1080 "yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best'"
alias cmatrix "cmatrix -C white"
alias v2rayn "~/.data/programs/v2rayN-linux-64/v2rayN"

# ============================================
# САЙТЫ
# ============================================
alias gh "xdg-open https://github.com"
alias yt "xdg-open https://youtube.com"
alias gmail "xdg-open https://mail.google.com"
alias gd "xdg-open https://genshindrop.io/checkin"
alias dpk "xdg-open https://chat.deepseek.com"
alias vk "xdg-open https://vk.com"
alias ozon "xdg-open https://ozon.ru"
alias wb "xdg-open https://wildberries.ru"
alias gos "xdg-open https://gosuslugi.ru"
alias amd "xdg-open https://amd.online/"
alias hani "xdg-open https://www.hanime1.nl/enter"
alias r34 "xdg-open https://rule34hub.com/"
alias translate "xdg-open https://translate.yandex.ru/"
alias gpt "xdg-open https://chatgpt.com/"

# ============================================
# ПЕРЕМЕННЫЕ ОКРУЖЕНИЯ
# ============================================
set -gx EDITOR micro
set -gx VISUAL micro
set -gx BROWSER zen-browser
set -gx PATH $PATH ~/.local/bin
set -gx PATH $PATH ~/data/dotfiles/scripts

# Bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH


# ============================================
# АВТОЗАПУСК HYPRLAND
# ============================================
if status is-login && test -z "$WAYLAND_DISPLAY" && test (tty) = /dev/tty1
    exec start-hyprland
end
