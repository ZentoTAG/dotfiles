# ============================================================================
#  cleanup.fish — интерактивный системный уборщик для Fish shell
#
#  Требования : gum, pacman-contrib (paccache), pacman, awk
#  Опционально : yay (пункты 1.2, 1.4), trash-cli (пункт 2.3)
#
#  ВАЖНО (CachyOS):
#    /usr/share/cachyos-fish-config/cachyos-config.fish содержит
#        alias cleanup='sudo pacman -Rns (pacman -Qtdq)'
#    Этот алиас создаётся при каждом старте и перекрывает функцию.
#    Поэтому в ~/.config/fish/config.fish нужно добавить в конец:
#        functions -e cleanup 2>/dev/null
#        source ~/.config/fish/functions/cleanup.fish
# ============================================================================

# ---------------------------------------------------------------------------
#  Проверка зависимостей
# ---------------------------------------------------------------------------
function __cl_check_deps
    set -l missing
    command -q gum; or set -a missing gum
    command -q paccache; or set -a missing pacman-contrib
    command -q pacman; or set -a missing pacman

    if test (count $missing) -gt 0
        echo (set_color red)"❌ Не найдены зависимости: "(set_color --bold)(string join ', ' $missing)(set_color normal)
        for m in $missing
            switch $m
                case gum
                    echo "   sudo pacman -S gum"
                case pacman-contrib
                    echo "   sudo pacman -S pacman-contrib"
                case pacman
                    echo "   sudo pacman -S pacman"
            end
        end
        return 1
    end

    command -q yay; or echo (set_color yellow)"⚠  yay не найден — пункты 1.2 и 1.4 будут недоступны"(set_color normal)
    command -q trash-empty; or echo (set_color yellow)"⚠  trash-empty не найден (trash-cli) — корзина будет очищена напрямую"(set_color normal)
    return 0
end

# ---------------------------------------------------------------------------
#  sudo
# ---------------------------------------------------------------------------
function __cl_sudo
    if sudo -n true 2>/dev/null
        return 0
    end
    echo (set_color yellow)"🔐 Требуется пароль sudo:"(set_color normal)
    if not sudo -v
        echo (set_color red)"❌ Не удалось получить права sudo — действие отменено."(set_color normal)
        return 1
    end
    return 0
end

# ---------------------------------------------------------------------------
#  Измерение размеров
# ---------------------------------------------------------------------------
function __cl_size_paths --description "Суммарный размер путей в байтах"
    set -l total 0
    for p in $argv
        test -e "$p"; or continue
        set -l b (LC_ALL=C du -sB1 -- "$p" 2>/dev/null | awk '{print $1; exit}')
        test -z "$b"; and set b 0
        set total (math "$total + $b")
    end
    echo $total
end

function __cl_size_paths_sudo --description "Суммарный размер путей через sudo"
    set -l total 0
    for p in $argv
        test -e "$p"; or continue
        set -l b (sudo -n du -sB1 -- "$p" 2>/dev/null | awk '{print $1; exit}')
        if test -z "$b"
            set b (LC_ALL=C du -sB1 -- "$p" 2>/dev/null | awk '{print $1; exit}')
        end
        test -z "$b"; and set b 0
        set total (math "$total + $b")
    end
    echo $total
end

function __cl_parse_size --description "Строка вида '160.44 MiB' / '45.8M' -> байты"
    printf '%s\n' "$argv[1]" | LC_ALL=C awk '{
        s = $0
        gsub(/,/, ".", s)
        if (s !~ /[0-9]/) { print 0; exit }
        match(s, /[0-9]+(\.[0-9]+)?/)
        num = substr(s, RSTART, RLENGTH) + 0
        rest = substr(s, RSTART + RLENGTH)
        u = ""
        if (match(rest, /[KkMmGgTtPpEe]/)) u = toupper(substr(rest, RSTART, 1))
        if (u == "K") num *= 1024
        else if (u == "M") num *= 1048576
        else if (u == "G") num *= 1073741824
        else if (u == "T") num *= 1099511627776
        else if (u == "P") num *= 1125899906842624
        printf "%.0f\n", num
    }'
end

function __cl_human --description "Байты -> человекочитаемо"
    LC_ALL=C awk -v b="$argv[1]" 'BEGIN{
        if (b < 1024) printf "%d B", b
        else if (b < 1048576) printf "%.1f KiB", b/1024
        else if (b < 1073741824) printf "%.1f MiB", b/1048576
        else if (b < 1099511627776) printf "%.2f GiB", b/1073741824
        else printf "%.2f TiB", b/1099511627776
    }'
end

function __cl_mb --description "Байты -> МБ (число)"
    LC_ALL=C awk -v b="$argv[1]" 'BEGIN{ printf "%.1f", b/1048576 }'
end

function __cl_pkg_bytes --description "Установленный размер пакетов (строка через пробел) в байтах"
    set -l total 0
    for p in (string split " " -- "$argv[1]")
        test -z "$p"; and continue
        # на случай цели вида name=version
        set -l base (string split "=" -- $p)[1]
        set -l line (LC_ALL=C pacman -Qi -- "$base" 2>/dev/null | awk -F': *' '/^Installed Size/ {print $2; exit}')
        test -z "$line"; and continue
        set -l add (__cl_parse_size "$line")
        set total (math "$total + $add")
    end
    echo $total
end

function __cl_journal_bytes --description "Размер журнала systemd в байтах"
    set -l line (LC_ALL=C journalctl --disk-usage 2>/dev/null | tail -1)
    set -l sz (printf '%s\n' "$line" | LC_ALL=C awk '{
        for (i = 1; i <= NF; i++) {
            t = $i
            gsub(/,/, ".", t)
            if (t ~ /^[0-9]+(\.[0-9]+)?[KMGTPE]?B?$/) { print t; exit }
        }
    }')
    if test -z "$sz"
        echo 0
    else
        __cl_parse_size "$sz"
    end
end

function __cl_pause --description "Пауза перед возвратом в меню"
    read -P (set_color brblack)"  ↵ Enter — вернуться в меню..." -l __cl_dummy
end

# ---------------------------------------------------------------------------
#  Универсальное действие: ДО -> подтверждение -> выполнение -> ПОСЛЕ
# ---------------------------------------------------------------------------
function __cl_run_action
    set -l label $argv[1]
    set -l mtype $argv[2]
    set -l marg  $argv[3]
    set -l cmd   $argv[4..-1]

    echo
    echo (set_color cyan --bold)"▶ $label"(set_color normal)
    echo (set_color brblack)"──────────────────────────────────────────────────────"(set_color normal)

    # --- ДО ---
    set -l before 0
    switch $mtype
        case dir
            set before (__cl_size_paths $marg)
        case dirsudo
            if not __cl_sudo
                return 1
            end
            set before (__cl_size_paths_sudo $marg)
        case yay
            if not __cl_sudo
                return 1
            end
            set -l a (__cl_size_paths_sudo /var/cache/pacman/pkg)
            set -l b (__cl_size_paths "$HOME/.cache/yay")
            set before (math "$a + $b")
        case pkg
            set before (__cl_pkg_bytes "$marg")
        case journal
            set before (__cl_journal_bytes)
        case none
            set before 0
    end

    echo (set_color yellow)"  Размер ДО: "(set_color --bold)(__cl_human $before)(set_color normal)

    if not gum confirm "Точно выполнить?" --affirmative "Да" --negative "Нет"
        echo (set_color yellow)"  Отменено."(set_color normal)
        return 0
    end

    if test (count $cmd) -eq 0
        echo (set_color red)"  ❌ Команда не задана."(set_color normal)
        return 1
    end

    echo (set_color green)"  Выполняю: $cmd"(set_color normal)
    $cmd
    set -l rc $status

    # --- ПОСЛЕ ---
    set -l after 0
    switch $mtype
        case dir
            set after (__cl_size_paths $marg)
        case dirsudo
            set after (__cl_size_paths_sudo $marg)
        case yay
            set -l a2 (__cl_size_paths_sudo /var/cache/pacman/pkg)
            set -l b2 (__cl_size_paths "$HOME/.cache/yay")
            set after (math "$a2 + $b2")
        case pkg
            set after (__cl_pkg_bytes "$marg")
        case journal
            set after (__cl_journal_bytes)
        case none
            set after $before
    end

    set -l saved (math "$before - $after")
    test $saved -lt 0; and set saved 0

    if test $rc -ne 0
        echo (set_color red)"  ⚠  Команда завершилась с кодом $rc (продолжаю)."(set_color normal)
    end
    echo (set_color yellow)"  Размер ПОСЛЕ: "(set_color --bold)(__cl_human $after)(set_color normal)
    echo (set_color green --bold)"  ✅ Освобождено: "(__cl_human $saved)" ("(__cl_mb $saved)" МБ)"(set_color normal)

    set -g __cl_total (math "$__cl_total + $saved")
    set -ga __cl_results "$label|$saved"

    __cl_pause
end

# ---------------------------------------------------------------------------
#  Анализ ядер linux-cachyos
# ---------------------------------------------------------------------------
function __cl_kernels_analyze --description "Печать отчёта, заполнение __cl_kernel_candidates"
    set -g __cl_kernel_candidates
    set -g __cl_kernel_notes
    set -g __cl_running_ver ""

    set -l running (uname -r)
    set -l cur_ver (LC_ALL=C pacman -Qo /usr/lib/modules/$running 2>/dev/null | awk '{print $NF; exit}')
    if test -z "$cur_ver"
        set cur_ver (LC_ALL=C pacman -Q linux-cachyos 2>/dev/null | awk '{print $2; exit}')
    end
    set -g __cl_running_ver "$cur_ver"

    set -l installed (LC_ALL=C pacman -Q 2>/dev/null | awk '$1 ~ /^linux-cachyos/ {print $1" "$2}')

    for pair in $installed
        set -l nm (string split " " -- $pair)[1]
        set -l vr (string split " " -- $pair)[2]

        # есть ли более новая версия этого же пакета
        set -l is_newest 1
        set -l vers_of_name 0
        for other in $installed
            set -l on (string split " " -- $other)[1]
            set -l ov (string split " " -- $other)[2]
            if test "$on" = "$nm"
                set vers_of_name (math "$vers_of_name + 1")
                set -l cmp (vercmp "$ov" "$vr")
                if test "$cmp" -gt 0
                    set is_newest 0
                end
            end
        end

        set -l cmp_cur (vercmp "$vr" "$cur_ver")
        set -l state "старое"
        if test "$vr" = "$cur_ver"
            set state "ТЕКУЩЕЕ"
        else if string match -q 'linux-cachyos-lts*' -- $nm
            if test $is_newest -eq 1
                set state "LTS"
            else
                set state "старое LTS"
            end
        else if test "$cmp_cur" -gt 0
            # установлено обновление, но система ещё не перезагружена
            set state "новее текущего"
        end

        printf '%s|%s|%s\n' "$nm" "$vr" "$state"

        # Кандидаты: не текущее, не LTS и не новее запущенного.
        if test "$vr" != "$cur_ver"; and not string match -q 'linux-cachyos-lts*' -- $nm; and test "$cmp_cur" -le 0
            # Сколько версий этого имени установлено? Если больше одной,
            # pacman -Rns <name> снесёт ВСЕ версии, включая нужную.
            if test $vers_of_name -gt 1
                set -l note "$nm: установлено несколько версий — удалите вручную"
                contains -- "$note" $__cl_kernel_notes; or set -ga __cl_kernel_notes "$note"
            else
                set -ga __cl_kernel_candidates "$nm"
            end
        end
    end
end

# ---------------------------------------------------------------------------
#  Меню 1: кэш и пакеты
# ---------------------------------------------------------------------------
function __cl_menu_cache
    while true
        set -l choice (printf '%s\n' \
            "1.1. Очистить кэш pacman (paccache -r)" \
            "1.2. Очистить кэш yay (yay -Sc)" \
            "1.3. Удалить пакеты-сироты (pacman -Qdtq)" \
            "1.4. Очистить кэш исходников AUR (yay -Yc)" \
            "← Назад" | gum choose --header "[1. КЭШ И ПАКЕТЫ]" --height 10 --cursor "▶ ")

        test -z "$choice"; and break

        switch $choice
            case "1.1. Очистить кэш pacman (paccache -r)"
                __cl_run_action "Очистка кэша pacman (paccache -r)" dirsudo "/var/cache/pacman/pkg" sudo paccache -r
            case "1.2. Очистить кэш yay (yay -Sc)"
                if not command -q yay
                    echo (set_color red)"  yay не установлен."(set_color normal)
                    __cl_pause
                    continue
                end
                __cl_run_action "Очистка кэша yay (yay -Sc)" yay "" yay -Sc --noconfirm
            case "1.3. Удалить пакеты-сироты (pacman -Qdtq)"
                __cl_action_orphans
            case "1.4. Очистить кэш исходников AUR (yay -Yc)"
                if not command -q yay
                    echo (set_color red)"  yay не установлен."(set_color normal)
                    __cl_pause
                    continue
                end
                __cl_run_action "Очистка кэша AUR (yay -Yc)" dir "$HOME/.cache/yay" yay -Yc --noconfirm
            case "← Назад"
                break
        end
    end
end

function __cl_action_orphans
    set -l orphans (pacman -Qdtq 2>/dev/null)

    echo
    if test (count $orphans) -eq 0
        echo (set_color green)"✅ Пакеты-сироты не найдены."(set_color normal)
        __cl_pause
        return 0
    end

    echo (set_color yellow)"  Найдены пакеты-сироты:"(set_color normal)
    for p in $orphans
        echo "    • $p"
    end

    set -l joined (string join " " $orphans)
    __cl_run_action "Удаление пакетов-сирот" pkg "$joined" sudo pacman -Rns --noconfirm $orphans
end

# ---------------------------------------------------------------------------
#  Меню 2: логи и ядра
# ---------------------------------------------------------------------------
function __cl_menu_logs
    while true
        set -l choice (printf '%s\n' \
            "2.1. Очистить старые логи systemd (vacuum-time=3d)" \
            "2.2. Показать и удалить старые ядра (linux-cachyos)" \
            "2.3. Очистить корзину" \
            "← Назад" | gum choose --header "[2. СИСТЕМНЫЕ ЛОГИ И ЯДРА]" --height 10 --cursor "▶ ")

        test -z "$choice"; and break

        switch $choice
            case "2.1. Очистить старые логи systemd (vacuum-time=3d)"
                __cl_run_action "Очистка логов systemd (3 дня)" journal "" sudo journalctl --vacuum-time=3d
            case "2.2. Показать и удалить старые ядра (linux-cachyos)"
                __cl_action_kernels
            case "2.3. Очистить корзину"
                __cl_action_trash
            case "← Назад"
                break
        end
    end
end

function __cl_action_kernels
    echo
    echo (set_color cyan --bold)"▶ Анализ ядер linux-cachyos"(set_color normal)
    echo (set_color yellow)"  Запущено: "(set_color --bold)(uname -r)(set_color normal)
    echo

    set -l report (__cl_kernels_analyze)

    echo (set_color --bold)"  Установленные пакеты:"(set_color normal)
    for r in $report
        set -l nm (string split "|" -- $r)[1]
        set -l vr (string split "|" -- $r)[2]
        set -l st (string split "|" -- $r)[3]
        set -l col (set_color normal)
        switch $st
            case ТЕКУЩЕЕ
                set col (set_color green)
            case LTS
                set col (set_color cyan)
            case новейшее
                set col (set_color blue)
            case старое
                set col (set_color red)
            case "старое LTS"
                set col (set_color magenta)
        end
        printf "    %-42s %-12s %s%s%s\n" "$nm" "$vr" $col "$st" (set_color normal)
    end

    if test (count $__cl_kernel_notes) -gt 0
        echo
        echo (set_color yellow)"  ⚠  Требуют ручного вмешательства:"(set_color normal)
        for n in $__cl_kernel_notes
            echo "    • $n"
        end
    end

    if test (count $__cl_kernel_candidates) -eq 0
        echo
        echo (set_color green)"✅ Старых ядер нет: оставлены текущее и LTS."(set_color normal)
        __cl_pause
        return 0
    end

    echo
    echo (set_color red)"  Кандидаты на удаление (не текущее и не LTS):"(set_color normal)
    for c in $__cl_kernel_candidates
        echo "    • $c"
    end

    __cl_run_action "Удаление старых ядер" pkg (string join " " $__cl_kernel_candidates) sudo pacman -Rns --noconfirm $__cl_kernel_candidates
end

function __cl_action_trash
    set -l trash_dir "$HOME/.local/share/Trash"

    if command -q trash-empty
        __cl_run_action "Очистка корзины (trash-empty)" dir "$trash_dir" trash-empty
        return
    end

    echo
    echo (set_color cyan --bold)"▶ Очистка корзины (встроенная)"(set_color normal)
    if not test -d "$trash_dir"
        echo (set_color green)"  Корзина отсутствует — чистить нечего."(set_color normal)
        __cl_pause
        return 0
    end

    set -l before (__cl_size_paths "$trash_dir")
    echo (set_color yellow)"  Размер ДО: "(set_color --bold)(__cl_human $before)(set_color normal)

    if not gum confirm "Очистить корзину?" --affirmative "Да" --negative "Нет"
        echo (set_color yellow)"  Отменено."(set_color normal)
        return 0
    end

    for sub in files info expunged
        if test -d "$trash_dir/$sub"
            find "$trash_dir/$sub" -mindepth 1 -delete 2>/dev/null
        end
    end

    set -l after (__cl_size_paths "$trash_dir")
    set -l saved (math "$before - $after")
    test $saved -lt 0; and set saved 0
    echo (set_color yellow)"  Размер ПОСЛЕ: "(set_color --bold)(__cl_human $after)(set_color normal)
    echo (set_color green --bold)"  ✅ Освобождено: "(__cl_human $saved)" ("(__cl_mb $saved)" МБ)"(set_color normal)

    set -g __cl_total (math "$__cl_total + $saved")
    set -ga __cl_results "Очистка корзины|$saved"
    __cl_pause
end

# ---------------------------------------------------------------------------
#  Меню 3: домашняя папка
# ---------------------------------------------------------------------------
function __cl_menu_home
    while true
        set -l choice (printf '%s\n' \
            "3.1. Показать ТОП-15 самых тяжёлых папок в ~" \
            "3.2. Файлы старше 30 дней в ~/Downloads и ~/data/downloads" \
            "3.3. Очистить миниатюры (~/.cache/thumbnails)" \
            "← Назад" | gum choose --header "[3. ДОМАШНЯЯ ПАПКА]" --height 10 --cursor "▶ ")

        test -z "$choice"; and break

        switch $choice
            case "3.1. Показать ТОП-15 самых тяжёлых папок в ~"
                __cl_action_top_folders
            case "3.2. Файлы старше 30 дней в ~/Downloads и ~/data/downloads"
                __cl_action_old_downloads
            case "3.3. Очистить миниатюры (~/.cache/thumbnails)"
                __cl_run_action "Очистка миниатюр" dir "$HOME/.cache/thumbnails" find "$HOME/.cache/thumbnails" -mindepth 1 -delete
            case "← Назад"
                break
        end
    end
end

function __cl_action_top_folders
    echo
    echo (set_color cyan --bold)"▶ ТОП-15 самых тяжёлых папок в ~"(set_color normal)
    echo (set_color brblack)"  Исключены: .git, node_modules, .cache, steamapps"(set_color normal)
    echo

    set -l total (LC_ALL=C du -x -sB1 \
        --exclude='.git' \
        --exclude='node_modules' \
        --exclude='.cache' \
        --exclude='steamapps' \
        -- "$HOME" 2>/dev/null | awk '{print $1; exit}')
    test -z "$total"; and set total 0
    echo (set_color yellow)"  Всего в ~: "(set_color --bold)(__cl_human $total)(set_color normal)
    echo (set_color brblack)"──────────────────────────────────────────────────────"(set_color normal)

    LC_ALL=C du -x -B1 --max-depth=1 \
        --exclude='.git' \
        --exclude='node_modules' \
        --exclude='.cache' \
        --exclude='steamapps' \
        -- "$HOME" 2>/dev/null \
        | awk -F'\t' -v h="$HOME" '$2 != h' \
        | sort -rn \
        | head -15 \
        | awk -F'\t' -v h="$HOME" '
            function hum(b) {
                if (b < 1024) return sprintf("%d B", b)
                if (b < 1048576) return sprintf("%.1f KiB", b/1024)
                if (b < 1073741824) return sprintf("%.1f MiB", b/1048576)
                if (b < 1099511627776) return sprintf("%.2f GiB", b/1073741824)
                return sprintf("%.2f TiB", b/1099511627776)
            }
            {
                p = $2
                sub(h, "~", p)
                printf "  %10s   %s\n", hum($1 + 0), p
            }'

    echo (set_color brblack)"──────────────────────────────────────────────────────"(set_color normal)
    __cl_pause
end

function __cl_action_old_downloads
    echo
    echo (set_color cyan --bold)"▶ Файлы старше 30 дней (только просмотр)"(set_color normal)

    set -l dirs
    test -d "$HOME/Downloads"; and set -a dirs "$HOME/Downloads"
    test -d "$HOME/data/downloads"; and set -a dirs "$HOME/data/downloads"

    if test (count $dirs) -eq 0
        echo (set_color yellow)"  Каталоги ~/Downloads и ~/data/downloads не найдены."(set_color normal)
        __cl_pause
        return 0
    end

    set -l grand_count 0
    set -l grand_size 0

    for d in $dirs
        echo
        echo (set_color yellow --bold)"  📁 "(string replace "$HOME" "~" $d)(set_color normal)
        echo (set_color brblack)"  ──────────────────────────────────────────────"(set_color normal)

        set -l lines (find "$d" -type f -mtime +30 -printf '%s\t%p\n' 2>/dev/null)
        if test (count $lines) -eq 0
            echo "    (нет файлов старше 30 дней)"
            continue
        end

        set -l cnt (count $lines)
        set -l sz (printf '%s\n' $lines | awk -F'\t' '{s += $1} END {print s + 0}')
        set grand_count (math "$grand_count + $cnt")
        set grand_size (math "$grand_size + $sz")

        printf '%s\n' $lines | sort -rn | head -15 | awk -F'\t' -v h="$HOME" '
            function hum(b) {
                if (b < 1024) return sprintf("%d B", b)
                if (b < 1048576) return sprintf("%.1f KiB", b/1024)
                if (b < 1073741824) return sprintf("%.1f MiB", b/1048576)
                if (b < 1099511627776) return sprintf("%.2f GiB", b/1073741824)
                return sprintf("%.2f TiB", b/1099511627776)
            }
            {
                p = $2
                sub(h, "~", p)
                printf "    %10s   %s\n", hum($1 + 0), p
            }'

        if test $cnt -gt 15
            echo (set_color brblack)"    … показаны 15 самых больших из $cnt"(set_color normal)
        end
        echo (set_color brblack)"    Всего: $cnt файлов, "(__cl_human $sz)(set_color normal)
    end

    echo
    echo (set_color brblack)"──────────────────────────────────────────────────────"(set_color normal)
    echo (set_color yellow)"  Итого: "(set_color --bold)"$grand_count"(set_color normal)" файлов, "(set_color --bold)(__cl_human $grand_size)(set_color normal)
    echo (set_color magenta)"  ℹ  Удаление не выполняется."(set_color normal)
    __cl_pause
end

# ---------------------------------------------------------------------------
#  Меню 4: диагностика
# ---------------------------------------------------------------------------
function __cl_menu_diag
    while true
        set -l choice (printf '%s\n' \
            "4.1. Проверить целостность системы (pacman -Dk)" \
            "4.2. Проверить висячие старые ядра" \
            "4.3. Показать состояние диска (df -h /)" \
            "← Назад" | gum choose --header "[4. ДИАГНОСТИКА]" --height 10 --cursor "▶ ")

        test -z "$choice"; and break

        switch $choice
            case "4.1. Проверить целостность системы (pacman -Dk)"
                __cl_diag_integrity
            case "4.2. Проверить висячие старые ядра"
                __cl_diag_kernels
            case "4.3. Показать состояние диска (df -h /)"
                __cl_diag_disk
            case "← Назад"
                break
        end
    end
end

function __cl_diag_integrity
    echo
    echo (set_color cyan --bold)"▶ Проверка целостности системы"(set_color normal)
    echo (set_color brblack)"──────────────────────────────────────────────────────"(set_color normal)

    echo (set_color yellow)"[pacman -Dk]"(set_color normal)
    pacman -Dk 2>&1

    echo
    echo (set_color yellow)"[pacman -Qk — файлы пакетов]"(set_color normal)
    if sudo -n true 2>/dev/null
        set -l broken (LC_ALL=C sudo -n pacman -Qk 2>/dev/null | grep -v ' 0 missing files' | head -40)
        if test -z "$broken"
            echo (set_color green)"  Пропущенных файлов не обнаружено."(set_color normal)
        else
            printf '%s\n' $broken
        end
    else
        echo (set_color brblack)"  Проверка файлов пропущена: нужен root."(set_color normal)
        echo (set_color brblack)"  Выполните «sudo -v», затем повторите пункт 4.1."(set_color normal)
    end

    echo (set_color brblack)"──────────────────────────────────────────────────────"(set_color normal)
    __cl_pause
end

function __cl_diag_kernels
    echo
    echo (set_color cyan --bold)"▶ Ядра linux-cachyos"(set_color normal)
    echo (set_color brblack)"──────────────────────────────────────────────────────"(set_color normal)

    set -l report (__cl_kernels_analyze)
    for r in $report
        set -l nm (string split "|" -- $r)[1]
        set -l vr (string split "|" -- $r)[2]
        set -l st (string split "|" -- $r)[3]
        printf "  %-42s %-12s %s\n" "$nm" "$vr" "$st"
    end

    echo
    echo (set_color yellow)"  Запущено: "(set_color --bold)(uname -r)(set_color normal)
    if test (count $__cl_kernel_candidates) -gt 0
        echo (set_color red)"  ⚠  Есть висячие старые ядра: "(string join ', ' $__cl_kernel_candidates)(set_color normal)
    else
        echo (set_color green)"  ✅ Висячих старых ядер нет."(set_color normal)
    end

    echo (set_color brblack)"──────────────────────────────────────────────────────"(set_color normal)
    __cl_pause
end

function __cl_diag_disk
    echo
    echo (set_color cyan --bold)"▶ Состояние диска"(set_color normal)
    echo (set_color brblack)"──────────────────────────────────────────────────────"(set_color normal)
    df -h / 2>&1
    echo
    echo (set_color yellow)"[Точки монтирования]"(set_color normal)
    df -hT / $HOME 2>&1
    echo (set_color brblack)"──────────────────────────────────────────────────────"(set_color normal)
    __cl_pause
end

# ---------------------------------------------------------------------------
#  Итоговая таблица
# ---------------------------------------------------------------------------
function __cl_summary
    echo
    echo (set_color green --bold)"╭──────────────────────────────────────────────────────────────╮"(set_color normal)
    echo (set_color green --bold)"│                     ИТОГОВАЯ СВОДКА                           │"(set_color normal)
    echo (set_color green --bold)"╰──────────────────────────────────────────────────────────────╯"(set_color normal)
    echo

    if test (count $__cl_results) -eq 0
        echo (set_color yellow)"  За сессию ничего не было очищено."(set_color normal)
        echo
        return 0
    end

    printf "  %s%-42s | %-16s%s\n" (set_color --bold) "Действие" "Освобождено" (set_color normal)
    echo (set_color brblack)"  "(string repeat -n 42 '─')"┼"(string repeat -n 18 '─')(set_color normal)

    for r in $__cl_results
        set -l label (string split "|" -- $r)[1]
        set -l byt (string split "|" -- $r)[2]
        set -l h (__cl_human $byt)
        if test (string length -- "$label") -gt 42
            set label (string sub -l 39 -- "$label")"..."
        end
        printf "  %-42s | %s%-16s%s\n" "$label" (set_color green) "$h" (set_color normal)
    end

    echo (set_color brblack)"  "(string repeat -n 42 '─')"┼"(string repeat -n 18 '─')(set_color normal)
    printf "  %s%-42s%s | %s%-16s%s\n" (set_color --bold) "ИТОГО ЗА СЕССИЮ" (set_color normal) (set_color green --bold) (__cl_human $__cl_total) (set_color normal)
    echo (set_color brblack)"  ("(__cl_mb $__cl_total)" МБ)"(set_color normal)
    echo
end

# ---------------------------------------------------------------------------
#  Главная функция
# ---------------------------------------------------------------------------
function cleanup --description "Интерактивный системный уборщик (кэш, ядра, логи, ~)"
    set -g __cl_results
    set -g __cl_total 0
    set -g __cl_kernel_candidates

    echo
    echo (set_color magenta --bold)"╔════════════════════════════════════════════════════╗"(set_color normal)
    echo (set_color magenta --bold)"║          ИНТЕРАКТИВНЫЙ СИСТЕМНЫЙ УБОРЩИК           ║"(set_color normal)
    echo (set_color magenta --bold)"╚════════════════════════════════════════════════════╝"(set_color normal)

    if not __cl_check_deps
        return 1
    end
    echo

    while true
        set -l choice (printf '%s\n' \
            "1. КЭШ И ПАКЕТЫ" \
            "2. СИСТЕМНЫЕ ЛОГИ И ЯДРА" \
            "3. ДОМАШНЯЯ ПАПКА" \
            "4. ДИАГНОСТИКА" \
            "0. ВЫХОД" | gum choose --header "🧹 Что чистим?" --height 12 --cursor "▶ ")

        test -z "$choice"; and break

        switch $choice
            case "1. КЭШ И ПАКЕТЫ"
                __cl_menu_cache
            case "2. СИСТЕМНЫЕ ЛОГИ И ЯДРА"
                __cl_menu_logs
            case "3. ДОМАШНЯЯ ПАПКА"
                __cl_menu_home
            case "4. ДИАГНОСТИКА"
                __cl_menu_diag
            case "0. ВЫХОД"
                break
        end
    end

    __cl_summary
end
