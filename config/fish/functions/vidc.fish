function vidc --description "Интерактивная оптимизация видео (H.264/H.265)"
    # ------------------------------------------------------------------
    # Вспомогательные функции
    # ------------------------------------------------------------------
    function __vidc_abs --argument-names p --description "Абсолютный путь без разрешения симлинков"
        set -l out (path normalize -- "$p")
        if not string match -q '/*' -- "$out"
            set out "$PWD/$out"
        end
        printf '%s\n' "$out"
    end

    function __vidc_human_size --argument-names bytes --description "Человекочитаемый размер"
        set -l n 0
        if test -n "$bytes"; and string match -qr '^\d+$' -- "$bytes"
            set n "$bytes"
        end

        if test "$n" -ge 1073741824
            printf '%.2f ГБ' (math "$n / 1073741824")
        else if test "$n" -ge 1048576
            printf '%.2f МБ' (math "$n / 1048576")
        else if test "$n" -ge 1024
            printf '%.1f КБ' (math "$n / 1024")
        else
            printf '%d Б' "$n"
        end
    end

    # ------------------------------------------------------------------
    # Проверка зависимостей
    # ------------------------------------------------------------------
    set -l missing_cmds
    for dep in gum ffmpeg
        if not command -q "$dep"
            set -a missing_cmds "$dep"
        end
    end

    if test (count $missing_cmds) -gt 0
        set_color red
        printf '❌ Не найдены зависимости: %s\n' (string join ', ' $missing_cmds)
        set_color normal

        if command -q pacman
            printf 'Установите: sudo pacman -S --needed %s\n' (string join ' ' $missing_cmds)
        else if command -q apt
            printf 'Установите: sudo apt update && sudo apt install %s\n' (string join ' ' $missing_cmds)
        else if command -q dnf
            printf 'Установите: sudo dnf install %s\n' (string join ' ' $missing_cmds)
        else if command -q brew
            printf 'Установите: brew install %s\n' (string join ' ' $missing_cmds)
        else
            printf 'Установите пакеты: %s\n' (string join ' ' $missing_cmds)
        end
        return 1
    end

    if test (count $argv) -eq 0
        printf 'Использование: vidc <файл|папка>...\n'
        printf 'Примеры: vidc video.mp4 | vidc *.mkv | vidc ~/Videos/\n'
        return 1
    end

    # ------------------------------------------------------------------
    # Сбор входных видео
    # ------------------------------------------------------------------
    set -l extensions \
        .mp4 .m4v .mov .mkv .webm .avi .wmv .flv .mpeg .mpg .ts .mts .m2ts .3gp .ogv .gif
    set -l sources
    set -l input_errors 0

    for arg in $argv
        if test -d "$arg"
            if not test -r "$arg"
                set_color red
                printf '❌ Нет доступа к папке: %s\n' "$arg"
                set_color normal
                set input_errors 1
                continue
            end

            # Не заходим в уже готовые optimized/
            set -l found (find -- "$arg" -mindepth 1 \
                \( -type d -name optimized -prune \) -o \
                \( -type f \( \
                    -iname '*.mp4' -o -iname '*.m4v' -o -iname '*.mov' \
                    -o -iname '*.mkv' -o -iname '*.webm' -o -iname '*.avi' \
                    -o -iname '*.wmv' -o -iname '*.flv' -o -iname '*.mpeg' \
                    -o -iname '*.mpg' -o -iname '*.ts' -o -iname '*.mts' \
                    -o -iname '*.m2ts' -o -iname '*.3gp' -o -iname '*.ogv' \
                    -o -iname '*.gif' \
                \) -print \) 2>/dev/null)

            if test (count $found) -eq 0
                set_color yellow
                printf '⚠️  Видео не найдено: %s\n' "$arg"
                set_color normal
                set input_errors 1
                continue
            end

            for file in $found
                set -l abs (__vidc_abs "$file")
                if not contains -- "$abs" $sources
                    set -a sources "$abs"
                end
            end
        else if test -f "$arg"
            set -l ext (string lower -- (path extension -- "$arg"))
            if not contains -- "$ext" $extensions
                set_color red
                printf '❌ Неподдерживаемый формат: %s\n' "$arg"
                printf '   Поддерживаются: %s\n' (string join ', ' $extensions)
                set_color normal
                set input_errors 1
                continue
            end

            set -l abs (__vidc_abs "$arg")
            if not contains -- "$abs" $sources
                set -a sources "$abs"
            end
        else
            set_color red
            printf '❌ Файл не найден: %s\n' "$arg"
            set_color normal
            set input_errors 1
        end
    end

    if test (count $sources) -eq 0
        set_color red
        printf 'Нет видео для обработки.\n'
        set_color normal
        return 1
    end

    set sources (path sort -- $sources)

    # ------------------------------------------------------------------
    # Меню действий
    # ------------------------------------------------------------------
    printf '\n'
    set_color brblue
    printf 'Найдено видео: %s\n' (count $sources)
    set_color normal

    set -l choice (gum choose --header "Что сделать с видео?" \
        --cursor "▶ " \
        "1. Сжать бережно (H.264, CRF 20)" \
        "2. Сжать сильнее (H.264, CRF 26)" \
        "3. Сжать в H.265/HEVC (меньше размер, хуже совместимость)" \
        "4. Уменьшить до 1080p и сжать (H.264)" \
        "5. Просто показать размеры файлов (без изменений)")
    set -l gum_status $status

    if test $gum_status -ne 0; or test -z "$choice"
        printf '\nОтменено.\n'
        return 130
    end

    set -l action (string sub -l 1 -- "$choice")
    set -l codec libx264
    set -l crf 20
    set -l audio_bitrate 160k
    set -l preset medium
    set -l resize 0
    set -l dry_run 0

    switch "$action"
        case 1
            set codec libx264
            set crf 20
            set audio_bitrate 160k
        case 2
            set codec libx264
            set crf 26
            set audio_bitrate 128k
        case 3
            set codec libx265
            set crf 28
            set audio_bitrate 128k
            set preset medium
        case 4
            set codec libx264
            set crf 23
            set audio_bitrate 128k
            set resize 1
        case 5
            set dry_run 1
        case '*'
            set_color red
            printf 'Неизвестный пункт меню: %s\n' "$choice"
            set_color normal
            return 1
    end

    printf '\n'
    set_color --bold
    printf 'Режим: %s\n' "$choice"
    set_color normal

    if test "$dry_run" -eq 1
        printf 'Файлы не изменяются.\n\n'
    else
        printf 'Все результаты будут сохранены в optimized/ рядом с исходниками.\n'
        printf 'Контейнер результата: MP4. Исходники не изменяются.\n\n'
    end

    # ------------------------------------------------------------------
    # Обработка
    # ------------------------------------------------------------------
    set -l sum_names
    set -l sum_before
    set -l sum_after
    set -l planned_outputs
    set -l ok_count 0
    set -l fail_count 0

    for src in $sources
        set -l base (path basename -- "$src")
        set -l before (stat -c %s -- "$src" 2>/dev/null)

        if test -z "$before"
            set_color red
            printf '❌ Не удалось прочитать: %s\n' "$base"
            set_color normal
            set fail_count (math "$fail_count + 1")
            continue
        end

        if test "$dry_run" -eq 1
            set -a sum_names "$base"
            set -a sum_before "$before"
            continue
        end

        set -l outdir (path normalize -- (path dirname -- "$src")"/optimized")
        set -l outbase (path change-extension .mp4 -- "$base")
        set -l target "$outdir/$outbase"
        set -l collision 2
        set -l stem (path change-extension '' -- "$outbase")

        # Не даём разным исходникам затереть результат друг друга.
        while contains -- "$target" $planned_outputs
            set target "$outdir/$stem-$collision.mp4"
            set collision (math "$collision + 1")
        end

        # Жёсткая защита от optimized/, указывающей на папку с оригиналом.
        set -l real_src (realpath -- "$src" 2>/dev/null)
        set -l real_target (realpath -m -- "$target" 2>/dev/null)
        if test -n "$real_src"; and test "$real_src" = "$real_target"
            set_color red
            printf '❌ Пропуск (результат совпал бы с оригиналом): %s\n' "$base"
            set_color normal
            set fail_count (math "$fail_count + 1")
            continue
        end

        set -a planned_outputs "$target"

        if not mkdir -p -- "$outdir" 2>/dev/null
            set_color red
            printf '❌ Не удалось создать папку: %s\n' "$outdir"
            set_color normal
            set fail_count (math "$fail_count + 1")
            continue
        end

        set -l tmpdir (mktemp -d "$outdir/.vidc.XXXXXX" 2>/dev/null)
        if test -z "$tmpdir"
            set_color red
            printf '❌ Не удалось создать временную папку в: %s\n' "$outdir"
            set_color normal
            set fail_count (math "$fail_count + 1")
            continue
        end

        printf '  • %s ... ' "$base"

        set -l cmd ffmpeg -hide_banner -loglevel error -y \
            -i "$src" \
            -map 0:v:0 -map 0:a? \
            -map_metadata 0 \
            -c:v "$codec" -preset "$preset" -crf "$crf" \
            -pix_fmt yuv420p \
            -c:a aac -b:a "$audio_bitrate" \
            -movflags +faststart

        if test "$resize" -eq 1
            # Уменьшаем только видео выше 1080p, маленькие не увеличиваем.
            set -a cmd -vf "scale='if(gt(ih,1080),-2,iw)':'if(gt(ih,1080),1080,ih)'"
        end

        set -a cmd "$tmpdir/$outbase"
        set -l cmd_output ($cmd 2>&1)
        set -l cmd_status $status
        set -l produced "$tmpdir/$outbase"
        set -l after 0
        set -l success 0

        if test "$cmd_status" -eq 0; and test -s "$produced"
            set after (stat -c %s -- "$produced" 2>/dev/null)
            if test -n "$after"; and test "$after" -lt "$before"
                if test -e "$target"; or test -L "$target"
                    rm -f -- "$target" 2>/dev/null
                end
                if mv -f -- "$produced" "$target" 2>/dev/null
                    set after (stat -c %s -- "$target" 2>/dev/null)
                    set success 1
                end
            end
        end

        rm -rf -- "$tmpdir"

        if test "$success" -eq 1
            set -a sum_names "$base"
            set -a sum_before "$before"
            set -a sum_after "$after"
            set ok_count (math "$ok_count + 1")
            set_color green
            printf '✓ %s\n' (__vidc_human_size "$after")
            set_color normal
        else
            set fail_count (math "$fail_count + 1")
            set_color red
            printf '✗\n'
            set_color normal

            if test "$cmd_status" -ne 0; and test -n "$cmd_output"
                set -l shown 0
                for line in $cmd_output
                    if test "$shown" -ge 4
                        printf '      ...\n'
                        break
                    end
                    printf '      %s\n' "$line"
                    set shown (math "$shown + 1")
                end
            else if test "$cmd_status" -eq 0
                printf '      Новый файл не меньше исходного — результат удалён.\n'
            else
                printf '      Команда завершилась с ошибкой (код %s).\n' "$cmd_status"
            end
        end
    end

    # ------------------------------------------------------------------
    # Сводка
    # ------------------------------------------------------------------
    if test "$dry_run" -eq 1
        printf '\n'
        set_color --bold
        printf 'Размеры файлов\n'
        set_color normal
        printf '  %-48s  %12s\n' 'Файл' 'Размер'
        printf '  %s\n' (string repeat -n 66 '─')

        set -l i 1
        for name in $sum_names
            printf '  %-48s  %12s\n' "$name" (__vidc_human_size "$sum_before[$i]")
            set i (math "$i + 1")
        end

        if test "$input_errors" -gt 0
            return 1
        end
        return 0
    end

    printf '\n'
    set_color --bold
    printf 'Итоги оптимизации\n'
    set_color normal

    printf '  %-38s  %12s  %12s  %s\n' 'Файл' 'Размер до' 'Размер после' 'Экономия (МБ / %)'
    printf '  %s\n' (string repeat -n 88 '─')

    set -l total_before 0
    set -l total_after 0
    set -l i 1
    for name in $sum_names
        set -l before "$sum_before[$i]"
        set -l after "$sum_after[$i]"
        set -l saved (math "$before - $after")
        set -l pct 0
        if test "$before" -gt 0
            set pct (math "$saved * 100 / $before")
        end
        set -l saved_mb (math "$saved / 1048576")
        set total_before (math "$total_before + $before")
        set total_after (math "$total_after + $after")

        printf '  %-38s  %12s  %12s  ' "$name" (__vidc_human_size "$before") (__vidc_human_size "$after")

        if test "$saved" -gt 0
            set_color green
        else if test "$saved" -lt 0
            set_color red
        else
            set_color yellow
        end
        printf '%.2f МБ (%.1f%%)\n' "$saved_mb" "$pct"
        set_color normal

        set i (math "$i + 1")
    end

    if test "$ok_count" -gt 0
        set -l total_saved (math "$total_before - $total_after")
        set -l total_pct 0
        if test "$total_before" -gt 0
            set total_pct (math "$total_saved * 100 / $total_before")
        end

        printf '  %s\n' (string repeat -n 88 '─')
        printf '  Всего: %s файл(ов), %s → %s, экономия %.2f МБ (%.1f%%)\n' \
            "$ok_count" (__vidc_human_size "$total_before") (__vidc_human_size "$total_after") \
            (math "$total_saved / 1048576") "$total_pct"
    end

    if test "$fail_count" -gt 0
        set_color red
        printf '  Не обработано: %s\n' "$fail_count"
        set_color normal
    end

    set_color brblack
    printf '  Результаты: папка optimized/ рядом с каждым исходным файлом.\n'
    set_color normal

    if test "$fail_count" -gt 0; or test "$input_errors" -gt 0
        return 1
    end
    return 0
end
