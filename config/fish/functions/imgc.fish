function imgc --description "Интерактивная оптимизация изображений (JPG/PNG/WebP)"
    # ------------------------------------------------------------------
    # Вспомогательные функции
    # ------------------------------------------------------------------
    function __imgc_abs --argument-names p --description "Абсолютный путь без разрешения симлинков"
        set -l out (path normalize -- "$p")
        if not string match -q '/*' -- "$out"
            set out "$PWD/$out"
        end
        printf '%s\n' "$out"
    end

    function __imgc_human_size --argument-names bytes --description "Человекочитаемый размер"
        set -l n 0
        if test -n "$bytes"
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
    set -l missing_pkgs
    for dep in gum jpegoptim oxipng cwebp
        if not command -q "$dep"
            set -a missing_cmds "$dep"
            switch "$dep"
                case gum
                    set -a missing_pkgs gum
                case jpegoptim
                    set -a missing_pkgs jpegoptim
                case oxipng
                    set -a missing_pkgs oxipng
                case cwebp
                    set -a missing_pkgs libwebp-utils
            end
        end
    end

    if test (count $missing_cmds) -gt 0
        set_color red
        printf '❌ Не найдены зависимости: %s\n' (string join ', ' $missing_cmds)
        set_color normal
        printf 'Установите: sudo pacman -S --needed %s\n' (string join ' ' $missing_pkgs)
        return 1
    end

    if test (count $argv) -eq 0
        printf 'Использование: imgc <файл|папка>...\n'
        printf 'Примеры: imgc photo.jpg | imgc *.png | imgc ~/Downloads/\n'
        return 1
    end

    # ------------------------------------------------------------------
    # Сбор входных изображений
    # ------------------------------------------------------------------
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

            # Рекурсивно ищем картинки, но не заходим в уже готовые optimized/
            set -l found (find -- "$arg" -mindepth 1 \
                \( -type d -name optimized -prune \) -o \
                \( -type f \( \
                    -iname '*.jpg' -o -iname '*.jpeg' -o \
                    -iname '*.png' -o -iname '*.webp' \
                \) -print \) 2>/dev/null)

            if test (count $found) -eq 0
                set_color yellow
                printf '⚠️  Изображений не найдено (jpg/jpeg/png/webp): %s\n' "$arg"
                set_color normal
                set input_errors 1
                continue
            end

            for file in $found
                set -l abs (__imgc_abs "$file")
                if not contains -- "$abs" $sources
                    set -a sources "$abs"
                end
            end
        else if test -f "$arg"
            set -l ext (string lower -- (path extension -- "$arg"))
            if not contains -- "$ext" .jpg .jpeg .png .webp
                set_color red
                printf '❌ Неподдерживаемый формат: %s (нужен jpg, jpeg, png или webp)\n' "$arg"
                set_color normal
                set input_errors 1
                continue
            end

            set -l abs (__imgc_abs "$arg")
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
        printf 'Нет изображений для обработки.\n'
        set_color normal
        return 1
    end

    set sources (path sort -- $sources)

    # ------------------------------------------------------------------
    # Меню действий
    # ------------------------------------------------------------------
    printf '\n'
    set_color brblue
    printf 'Найдено изображений: %s\n' (count $sources)
    set_color normal

    set -l choice (gum choose --header "Что сделать с изображениями?" \
        --cursor "▶ " \
        "1. Сжать бережно (JPG 92%, PNG без потерь)" \
        "2. Сжать сильнее (JPG 85%)" \
        "3. Конвертировать в WebP (качество 90)" \
        "4. Уменьшить разрешение и конвертировать в WebP (макс. ширина 2560px)" \
        "5. Просто показать размеры файлов (без изменений)")
    set -l gum_status $status

    if test $gum_status -ne 0 -o -z "$choice"
        printf '\nОтменено.\n'
        return 130
    end

    set -l action (string sub -l 1 -- "$choice")
    set -l jpeg_q 92
    set -l webp_q 92
    set -l make_webp 0
    set -l resize_webp 0
    set -l dry_run 0

    switch "$action"
        case 1
            set jpeg_q 92
            set webp_q 92
        case 2
            set jpeg_q 85
            set webp_q 85
        case 3
            set webp_q 90
            set make_webp 1
        case 4
            set webp_q 90
            set make_webp 1
            set resize_webp 1
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
        set -l ext (string lower -- (path extension -- "$src"))
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

        # Итоговое имя: для WebP-конвертации меняем расширение
        set -l outbase "$base"
        if test "$make_webp" -eq 1
            set outbase (path change-extension .webp -- "$base")
        end

        # Не даём разным исходникам затереть результат друг друга
        set -l target "$outdir/$outbase"
        set -l collision 2
        set -l stem (path change-extension '' -- "$outbase")
        set -l target_ext (path extension -- "$outbase")
        while contains -- "$target" $planned_outputs
            set target "$outdir/$stem-$collision$target_ext"
            set collision (math "$collision + 1")
        end

        # Жёсткая защита: optimized/ может оказаться симлинком на папку с оригиналом
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

        # Работаем через временную папку: старый optimized-файл не пострадает,
        # если конвертация внезапно упадёт.
        set -l tmpdir (mktemp -d "$outdir/.imgc.XXXXXX" 2>/dev/null)
        if test -z "$tmpdir"
            set_color red
            printf '❌ Не удалось создать временную папку в: %s\n' "$outdir"
            set_color normal
            set fail_count (math "$fail_count + 1")
            continue
        end

        printf '  • %s ... ' "$base"

        set -l cmd_status 1
        set -l cmd_output

        if test "$make_webp" -eq 1; or test "$ext" = .webp
            # cwebp: JPG/PNG -> WebP, либо пережатие существующего WebP
            set -l cmd cwebp -quiet -q "$webp_q"
            if test "$resize_webp" -eq 1
                # down_only не даёт увеличивать картинки, которые уже меньше 2560px
                set -a cmd -resize 2560 0 -resize_mode down_only
            end
            set -a cmd "$src" -o "$tmpdir/$outbase"
            set cmd_output ($cmd 2>&1)
            set cmd_status $status
        else if test "$ext" = .jpg -o "$ext" = .jpeg
            set cmd_output (jpegoptim --dest="$tmpdir" --max="$jpeg_q" \
                --strip-none --force --overwrite -- "$src" 2>&1)
            set cmd_status $status
        else if test "$ext" = .png
            set cmd_output (oxipng --dir "$tmpdir" -o 2 -- "$src" 2>&1)
            set cmd_status $status
        else
            set cmd_output "Неподдерживаемый формат: $ext"
        end

        set -l produced "$tmpdir/$outbase"
        set -l after 0
        set -l success 0
        set -l kept_original 0

        if test -f "$produced"; and test -s "$produced"
            # Для тех же форматов не даём "оптимизатору" сделать файл больше:
            # если результат не меньше исходника — кладём в optimized копию оригинала.
            if test "$make_webp" -eq 0
                set -l produced_size (stat -c %s -- "$produced" 2>/dev/null)
                if test -n "$produced_size"; and test "$produced_size" -ge "$before"
                    rm -f -- "$produced"
                    if cp --preserve=mode,timestamps -- "$src" "$produced" 2>/dev/null
                        set kept_original 1
                    end
                end
            end

            if test -e "$target"; or test -L "$target"
                rm -f -- "$target" 2>/dev/null
            end
            if mv -f -- "$produced" "$target" 2>/dev/null
                set after (stat -c %s -- "$target" 2>/dev/null)
                set success 1
            end
        end

        rm -rf -- "$tmpdir"

        if test "$success" -eq 1
            set -a sum_names "$base"
            set -a sum_before "$before"
            set -a sum_after "$after"
            set ok_count (math "$ok_count + 1")
            set_color green
            printf '✓ %s' (__imgc_human_size "$after")
            if test "$kept_original" -eq 1
                printf ' (без изменений)'
            end
            printf '\n'
            set_color normal
        else
            set fail_count (math "$fail_count + 1")
            set_color red
            printf '✗\n'
            set_color normal

            if test -n "$cmd_output"
                set -l shown 0
                for line in $cmd_output
                    if test "$shown" -ge 4
                        printf '      ...\n'
                        break
                    end
                    printf '      %s\n' "$line"
                    set shown (math "$shown + 1")
                end
            else if test "$cmd_status" -ne 0
                printf '      Команда завершилась с ошибкой (код %s).\n' "$cmd_status"
            else
                printf '      Не удалось получить результат.\n'
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
        printf '  %-38s  %12s\n' 'Файл' 'Размер'
        printf '  %s\n' (string repeat -n 56 '─')

        set -l i 1
        for name in $sum_names
            printf '  %-38s  %12s\n' "$name" (__imgc_human_size "$sum_before[$i]")
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

        printf '  %-38s  %12s  %12s  ' "$name" (__imgc_human_size "$before") (__imgc_human_size "$after")

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
            "$ok_count" (__imgc_human_size "$total_before") (__imgc_human_size "$total_after") \
            (math "$total_saved / 1048576") "$total_pct"
    end

    if test "$fail_count" -gt 0
        set_color red
        printf '  Ошибок: %s\n' "$fail_count"
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
