function ytdl --description "Скачать видео или плейлист через yt-dlp"
    # ------------------------------------------------------------------
    # Вспомогательная функция: человекочитаемый размер
    # ------------------------------------------------------------------
    function __ytdl_human_size --argument-names bytes --description "Размер в удобном виде"
        if test -z "$bytes"; or not string match -qr '^\d+$' -- "$bytes"
            echo неизвестно
            return
        end

        if test "$bytes" -ge 1073741824
            printf '%.2f ГБ' (math "$bytes / 1073741824")
        else if test "$bytes" -ge 1048576
            printf '%.2f МБ' (math "$bytes / 1048576")
        else if test "$bytes" -ge 1024
            printf '%.1f КБ' (math "$bytes / 1024")
        else
            printf '%d Б' "$bytes"
        end
    end

    function __ytdl_detect_browser_cookies --description "Найти cookies Firefox-совместимого браузера"
        set -l dirs \
            "$HOME/.config/zen" \
            "$HOME/.mozilla/firefox" \
            "$HOME/.librewolf" \
            "$HOME/.config/librewolf" \
            "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox" \
            "$HOME/.var/app/io.github.zen_browser.zen/.zen"

        set -l newest_db
        set -l newest_time 0

        for dir in $dirs
            if not test -d "$dir"
                continue
            end
            for db in $dir/*/cookies.sqlite
                if not test -f "$db"
                    continue
                end
                set -l mtime (command stat -c %Y -- "$db" 2>/dev/null)
                if test -z "$mtime"
                    continue
                end
                if test "$mtime" -gt "$newest_time"
                    set newest_time "$mtime"
                    set newest_db "$db"
                end
            end
        end

        if test -n "$newest_db"
            printf 'firefox:%s\n' (command dirname -- "$newest_db")
            return 0
        end

        set -l chromium_dirs \
            "chrome:$HOME/.config/google-chrome" \
            "chromium:$HOME/.config/chromium" \
            "brave:$HOME/.config/BraveSoftware/Brave-Browser" \
            "edge:$HOME/.config/microsoft-edge" \
            "vivaldi:$HOME/.config/vivaldi" \
            "opera:$HOME/.config/opera"

        for entry in $chromium_dirs
            set -l parts (string split -m 1 ':' -- "$entry")
            if test (count $parts) -ge 2; and test -d "$parts[2]"
                echo "$parts[1]"
                return 0
            end
        end

        return 1
    end

    # ------------------------------------------------------------------
    # Проверка зависимостей
    # ------------------------------------------------------------------
    set -l missing
    for dep in yt-dlp gum ffmpeg
        if not command -q -- "$dep"
            set -a missing "$dep"
        end
    end

    if test (count $missing) -gt 0
        set_color red
        printf '❌ Не найдены зависимости: %s\n' (string join ', ' $missing)
        set_color normal

        if command -q pacman
            printf 'Установите: sudo pacman -S --needed %s\n' (string join ' ' $missing)
        else if command -q apt
            printf 'Установите: sudo apt update && sudo apt install %s\n' (string join ' ' $missing)
        else if command -q dnf
            printf 'Установите: sudo dnf install %s\n' (string join ' ' $missing)
        else if command -q brew
            printf 'Установите: brew install %s\n' (string join ' ' $missing)
        else
            printf 'Установите пакеты: %s\n' (string join ' ' $missing)
        end

        if contains -- yt-dlp $missing
            echo "Для yt-dlp также подойдёт: python3 -m pip install -U yt-dlp"
        end
        return 1
    end

    # ------------------------------------------------------------------
    # Проверка аргументов
    # ------------------------------------------------------------------
    if test (count $argv) -eq 0
        set_color yellow
        echo "❌ Не указана ссылка на видео или плейлист."
        set_color normal
        echo "Использование: ytdl <ссылка>"
        echo "Пример:        ytdl 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'"
        return 1
    end

    if test (count $argv) -gt 1
        set_color red
        printf '❌ Ожидается одна ссылка, получено аргументов: %d.\n' (count $argv)
        set_color normal
        echo "Использование: ytdl <ссылка>"
        return 1
    end

    set -l url (string trim -- "$argv[1]")
    if not string match -rqi '^https?://' -- "$url"
        set_color red
        printf '❌ Некорректная ссылка: %s\n' "$url"
        set_color normal
        echo "Ссылка должна начинаться с http:// или https://"
        return 1
    end

    # ------------------------------------------------------------------
    # Выбор папки назначения
    # ------------------------------------------------------------------
    set -l preferred "$HOME/data/media/videos"
    set -l outdir

    if test -d "$preferred"; and test -w "$preferred"
        set outdir "$preferred"
    else
        set outdir "$PWD"
        if not test -d "$preferred"
            printf 'ℹ️  Папка %s не найдена — сохраняю в текущую: %s\n' "$preferred" "$outdir"
        else
            printf '⚠️  Нет прав на запись в %s — сохраняю в текущую: %s\n' "$preferred" "$outdir"
        end
    end

    # ------------------------------------------------------------------
    # Интерактивный выбор качества
    # ------------------------------------------------------------------
    set -l best "Лучшее качество (4K/8K, если есть)"
    set -l hd1080 "1080p (Full HD)"
    set -l hd720 "720p (HD)"
    set -l audio "Только звук (MP3 / M4A)"

    set -l quality (gum choose \
        --header "Выберите качество:" \
        --cursor "➜ " \
        --height 6 \
        "$best" "$hd1080" "$hd720" "$audio")

    set -l gum_status $status
    if test $gum_status -ne 0; or test -z "$quality"
        set_color yellow
        echo "⚠️  Выбор отменён (нужен интерактивный терминал)."
        set_color normal
        return 1
    end

    set -l format
    set -l is_audio 0

    switch "$quality"
        case "$best"
            set format "bv*+ba/b"
        case "$hd1080"
            set format "bv*[height<=1080]+ba/b[height<=1080]/bv*+ba/b"
        case "$hd720"
            set format "bv*[height<=720]+ba/b[height<=720]/bv*+ba/b"
        case "$audio"
            set is_audio 1
            set format ba/b
        case '*'
            set_color red
            printf '❌ Неизвестный выбор: %s\n' "$quality"
            set_color normal
            return 1
    end

    # ------------------------------------------------------------------
    # Скачивание
    # ------------------------------------------------------------------
    set -l paths_file (mktemp)
    set -l log_file (mktemp)
    set -l base_args \
        --no-cache-dir \
        --concurrent-fragments 4 \
        --retries 10 \
        --newline \
        --quiet \
        --progress \
        --no-simulate \
        --print-to-file after_move:filepath "$paths_file" \
        --output "$outdir/%(title)s.%(ext)s" \
        --format "$format"

    if test $is_audio -eq 1
        set -a base_args --extract-audio --audio-format mp3 --audio-quality 0
        echo "🎵 Режим: только звук (MP3, лучшее качество)"
    else
        set -a base_args --merge-output-format mp4
        printf '🎬 Режим: %s\n' "$quality"
    end

    set -l cookie_args
    set -l cookies_used 0
    if test -n "$YTDL_COOKIE_FILE"
        set cookie_args --cookies "$YTDL_COOKIE_FILE"
        set cookies_used 1
    else if test -n "$YTDL_COOKIES_FROM_BROWSER"
        set cookie_args --cookies-from-browser "$YTDL_COOKIES_FROM_BROWSER"
        set cookies_used 1
    end

    set -l args $base_args $cookie_args -- "$url"

    echo "⬇️  Скачиваю: $url"
    printf '📁 Куда:     %s\n\n' "$outdir"

    command yt-dlp $args 2>&1 | tee -- "$log_file"
    set -l rc $pipestatus[1]

    # Если YouTube требует вход или подтверждение возраста — пробуем cookies
    if test $rc -ne 0; and test $cookies_used -eq 0
        if string match -qir 'sign in to confirm|age[- ]restricted|confirm your age|use --cookies|login required|log in to|not a bot|members-only|requires? authentication' <"$log_file"
            set -l cookie_source (__ytdl_detect_browser_cookies)
            if test -n "$cookie_source"
                set_color yellow
                echo ""
                echo "⚠️  Видео требует входа в аккаунт или подтверждения возраста."
                echo "🔑 Повторяю попытку с cookies из браузера..."
                set_color normal
                echo ""
                set args $base_args --cookies-from-browser "$cookie_source" -- "$url"
                command yt-dlp $args 2>&1 | tee -- "$log_file"
                set rc $pipestatus[1]
            end
        end
    end

    if test $rc -ne 0
        set_color red
        printf '❌ yt-dlp завершился с ошибкой (код %d).\n' $rc
        set_color normal
        echo "Проверьте ссылку, доступ к видео и подключение к интернету."
        echo "Частые причины: приватное видео, возрастное ограничение,"
        echo "требуется авторизация или запрошенный формат недоступен."

        if string match -qir 'sign in to confirm|age[- ]restricted|confirm your age|not a bot|login required|requires? authentication' <"$log_file"
            echo ""
            echo "Совет: войдите в YouTube в браузере или укажите cookies вручную:"
            echo "  set -gx YTDL_COOKIES_FROM_BROWSER firefox"
            echo "  # либо: set -gx YTDL_COOKIE_FILE ~/cookies.txt"
        end

        command rm -f -- "$paths_file" "$log_file"
        return $rc
    end

    # ------------------------------------------------------------------
    # Итог: путь и размер
    # ------------------------------------------------------------------
    set -l raw_files (command cat -- "$paths_file" 2>/dev/null)
    command rm -f -- "$paths_file" "$log_file"

    set -l files
    for p in $raw_files
        if not contains -- "$p" $files
            set -a files "$p"
        end
    end

    set_color green
    echo ""
    echo "✅ Готово!"
    set_color normal

    if test (count $files) -eq 0
        printf '📁 Файлы сохранены в: %s\n' "$outdir"
        echo "(yt-dlp не вернул точный путь — проверьте папку.)"
        return 0
    end

    set -l total 0
    for f in $files
        if test -f "$f"
            set -l bytes (command stat -c %s -- "$f" 2>/dev/null)
            if test -z "$bytes"
                set bytes 0
            end
            set total (math "$total + $bytes")
            printf '📄 %s\n   Размер: %s\n' "$f" (__ytdl_human_size "$bytes")
        else
            printf '📄 %s\n   Размер: файл не найден\n' "$f"
        end
    end

    if test (count $files) -gt 1
        printf '\n📦 Всего файлов: %d, общий размер: %s\n' (count $files) (__ytdl_human_size "$total")
    end

    return 0
end
