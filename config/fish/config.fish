source /usr/share/cachyos-fish-config/cachyos-config.fish

# Удалить всё, что содержит слово (поиск в ~/.config, ~/.cache, ~/.local/share)
function del
    set word $argv[1]
    if test -z "$word"
        echo "❌ Укажи слово"
        return 1
    end
    find ~/.config ~/.cache ~/.local/share -iname "*$word*" -exec rm -rf {} \; 2>/dev/null
    echo "✅ Удалено!"
end

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

# ============================================================
# КОНВЕРТАЦИЯ ФАЙЛОВ (heavy по умолчанию) — БЫСТРАЯ
# ============================================================

function conv
    set -l quality "heavy"
    set -l from_ext ""
    set -l to_ext ""
    set -l files ""

    # Парсим аргументы
    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case light medium heavy
                set quality $argv[$i]
            case "*.*"
                if test -z "$from_ext"
                    set from_ext $argv[$i]
                else if test -z "$to_ext"
                    set to_ext $argv[$i]
                else
                    set files $files $argv[$i]
                end
            case "*"
                if test -z "$from_ext"
                    set from_ext $argv[$i]
                else if test -z "$to_ext"
                    set to_ext $argv[$i]
                else
                    set files $files $argv[$i]
                end
        end
        set i (math $i + 1)
    end

    # Проверяем, что указаны форматы
    if test -z "$from_ext" -o -z "$to_ext"
        echo "❌ Использование: conv [light|medium|heavy] <откуда> <куда> [файлы]"
        echo ""
        echo "По умолчанию: heavy (без сжатия)"
        echo ""
        echo "Примеры:"
        echo "  conv png jpg                  # все PNG → JPG в текущей папке"
        echo "  conv light png jpg            # все PNG → JPG (сжатие)"
        echo "  conv heavy png jpg            # все PNG → JPG (без сжатия)"
        echo "  conv mp4 webm *.mp4           # конкретные файлы"
        return 1
    end

    # Если файлы не переданы, берём все в текущей папке
    if test (count $files) -eq 0
        set files (ls *.$from_ext 2>/dev/null)
    end

    if test (count $files) -eq 0
        echo "❌ Нет файлов с расширением .$from_ext"
        return 1
    end

    echo "🔄 Режим: $quality | Конвертирую (count $files) файлов .$from_ext → .$to_ext"
    echo ""

    for file in $files
        set -l base (basename $file .$from_ext)
        set -l output "$base.$to_ext"

        if test -f "$output"
            echo "⚠️  $output уже существует, пропускаю"
            continue
        end

        # === Выбор инструмента ===
        switch "$from_ext:$to_ext"
            # Картинки (ImageMagick) — БЫСТРО
            case "png:jpg" "png:jpeg" "jpg:png" "jpeg:png" "webp:png" "png:webp" "jpg:webp" "jpeg:webp" "webp:jpg" "webp:jpeg"
                echo "  🖼️  $file → $output [$quality]"
                
                # Выбираем параметры качества
                switch $quality
                    case light
                        magick "$file" -quality 60 -strip "$output"
                    case medium
                        magick "$file" -quality 85 -strip "$output"
                    case heavy
                        magick "$file" -quality 100 -strip "$output"
                end

            # Видео (ffmpeg)
            case "mp4:webm"
                echo "  🎬  $file → $output [$quality]"
                switch $quality
                    case light
                        ffmpeg -i "$file" -c:v libvpx-vp9 -crf 35 -b:v 0 -c:a libopus "$output" 2>/dev/null
                    case medium
                        ffmpeg -i "$file" -c:v libvpx-vp9 -crf 28 -b:v 0 -c:a libopus "$output" 2>/dev/null
                    case heavy
                        ffmpeg -i "$file" -c:v libvpx-vp9 -crf 18 -b:v 0 -c:a libopus "$output" 2>/dev/null
                end
            case "mp4:gif"
                echo "  🎬  $file → $output [$quality]"
                ffmpeg -i "$file" -vf "fps=10,scale=-1:-1:flags=lanczos" -c:v gif "$output" 2>/dev/null
            case "webm:mp4"
                echo "  🎬  $file → $output [$quality]"
                ffmpeg -i "$file" -c:v libx264 -preset medium -crf 23 -c:a aac "$output" 2>/dev/null
            case "gif:mp4"
                echo "  🎬  $file → $output [$quality]"
                ffmpeg -i "$file" -c:v libx264 -preset medium -crf 23 "$output" 2>/dev/null
            case "mp4:mp3"
                echo "  🎵  $file → $output [$quality]"
                switch $quality
                    case light
                        ffmpeg -i "$file" -vn -c:a libmp3lame -b:a 96k "$output" 2>/dev/null
                    case medium
                        ffmpeg -i "$file" -vn -c:a libmp3lame -b:a 192k "$output" 2>/dev/null
                    case heavy
                        ffmpeg -i "$file" -vn -c:a libmp3lame -b:a 320k "$output" 2>/dev/null
                end

            # Аудио
            case "mp3:ogg" "mp3:flac" "flac:mp3" "wav:mp3"
                echo "  🎵  $file → $output [$quality]"
                switch $quality
                    case light
                        ffmpeg -i "$file" -b:a 96k "$output" 2>/dev/null
                    case medium
                        ffmpeg -i "$file" -b:a 192k "$output" 2>/dev/null
                    case heavy
                        ffmpeg -i "$file" -b:a 320k "$output" 2>/dev/null
                end

            case "*"
                echo "❌ Не знаю, как конвертировать $from_ext → $to_ext"
                echo "   Поддерживаемые форматы:"
                echo "   Картинки: png, jpg, jpeg, webp"
                echo "   Видео: mp4, webm, gif"
                echo "   Аудио: mp3, ogg, flac, wav"
                return 1
        end

        if test -f "$output"
            echo "  ✅ $output"
        else
            echo "  ❌ Ошибка при конвертации $file"
        end
    end

    echo ""
    echo "✅ Готово!"
end

function discord-proxy
    # Запускаем SpoofDPI в фоне
    spoofdpi &
    # Ждём секунду, чтобы он успел подняться
    sleep 1
    # Запускаем Discord
    discord
end

function v2rayN
    nohup /home/zento/data/tools/v2rayN-linux-64/v2rayN $argv > /dev/null 2>&1 &
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
alias ff "fastfetch"
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

# Starship — красивый промпт
# starship init fish | source
