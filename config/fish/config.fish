source /usr/share/cachyos-fish-config/cachyos-config.fish

# Отключаем fastfetch
function fish_greeting
end

# Копирование в буфер
function copy
    wl-copy
end

function showall
    # Если передан аргумент — используем его, иначе текущую папку
    set target $argv[1]
    if test -z "$target"
        set target .
    end
    
    find $target -type f -exec echo "=== {} ===" \; -exec cat {} \;
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

# ============================================
# ПРОЕКТЫ И КОНФИГИ
# ============================================
alias prog "cd ~/data/programs/"
alias dots "cd ~/data/dotfiles"
alias com "micro ~/data/dotfiles/docs/commands.md"
alias combat "bat ~/data/dotfiles/docs/commands.md"
alias comcat "cat ~/data/dotfiles/docs/commands.md"
alias hypr "micro ~/.config/hypr/hyprland.conf"
alias config "cd ~/.config/"

# ============================================
# СИСТЕМА
# ============================================
alias upd "sudo pacman -Syu"
alias kl "killall"
alias vacuum "journalctl --vacuum-size=100M"
alias syslog_emerg "sudo dmesg --level=emerg,alert,crit"
alias syslog "sudo dmesg --level=err,warn"

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
