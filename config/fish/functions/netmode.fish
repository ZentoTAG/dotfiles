# netmode — управление лимитом скорости интернета через tc + CAKE.
# Запуск: sudo -v && netmode
# Требования: gum, iproute2 (tc/ip), kmod (modprobe), sudo.

function netmode --description "Управление лимитом скорости интернета (tc + CAKE + IFB)"

    # ==================================================================
    # Проверка зависимостей
    # ==================================================================
    set -l missing
    for dep in gum tc ip awk sudo modprobe
        if not command -q -- $dep
            set -a missing $dep
        end
    end

    if test (count $missing) -gt 0
        __netmode_error "❌ Не найдены команды: "(string join ', ' $missing)
        echo '   Установите: sudo pacman -S --needed iproute2 gum kmod sudo gawk'
        return 1
    end

    # ==================================================================
    # Активный интерфейс
    # ==================================================================
    set -l iface (ip route show default 2>/dev/null | awk '{print $5; exit}')

    # Если поле №5 — не имя интерфейса (VPN, multipath и т.п.),
    # ищем значение сразу после "dev".
    if test -z "$iface"
        set iface (ip route show default 2>/dev/null | awk '{
            for (i = 1; i <= NF; i++)
                if ($i == "dev") { print $(i + 1); exit }
        }')
    else if not ip link show dev "$iface" >/dev/null 2>&1
        set iface (ip route show default 2>/dev/null | awk '{
            for (i = 1; i <= NF; i++)
                if ($i == "dev") { print $(i + 1); exit }
        }')
    end

    if test -z "$iface"
        __netmode_error '❌ Не удалось определить активный интерфейс.'
        echo '   Маршрут по умолчанию не найден. Проверьте сеть:'
        echo '   ip route show default'
        return 1
    end

    if not ip link show dev "$iface" >/dev/null 2>&1
        __netmode_error "❌ Интерфейс \"$iface\" не найден."
        return 1
    end

    # ==================================================================
    # Права root через sudo
    # ==================================================================
    if not sudo -n true 2>/dev/null
        __netmode_error '❌ Нет активных прав sudo.'
        echo '   Сначала выполните:  sudo -v'
        echo '   Затем запустите:    netmode'
        return 1
    end

    # ==================================================================
    # Меню
    # ==================================================================
    set -l label_off 'Без ограничений (выключить)'
    set -l label_40 'Ограничить до 40 Мбит'
    set -l label_30 'Ограничить до 30 Мбит'
    set -l label_20 'Ограничить до 20 Мбит'
    set -l label_10 'Ограничить до 10 Мбит'
    set -l label_status 'Показать текущий статус'

    set -l choice (gum choose \
        --header "🌐 Скорость интернета · $iface" \
        --cursor '➜ ' \
        --height 8 \
        "$label_off" "$label_40" "$label_30" "$label_20" "$label_10" "$label_status")
    set -l pick_status $status

    if test $pick_status -ne 0
        # Esc / Ctrl-C — выходим без ошибки.
        return 0
    end

    set -l rate ''

    switch "$choice"
        case "$label_off"
            __netmode_clear "$iface"
            set_color green
            echo '✅ Ограничения сняты — интернет на полной скорости.'
            set_color normal
            printf '   Интерфейс: %s\n' "$iface"
            return 0

        case "$label_40"
            set rate 40
        case "$label_30"
            set rate 30
        case "$label_20"
            set rate 20
        case "$label_10"
            set rate 10
        case "$label_status"
            __netmode_status "$iface"
            return 0
        case '*'
            __netmode_error '❌ Неизвестный пункт меню.'
            return 1
    end

    # ==================================================================
    # Применение лимита
    # ==================================================================
    __netmode_limit "$iface" "$rate"
    or return 1

    set_color green
    printf '✅ Ограничение включено: %s Мбит (upload + download).\n' "$rate"
    set_color normal
    printf '   Интерфейс: %s\n' "$iface"
    echo '   Статус: netmode → «Показать текущий статус»'
    return 0
end

# ======================================================================
# Вспомогательные функции
# ======================================================================

function __netmode_error --argument-names message
    set_color red
    printf '%s\n' "$message"
    set_color normal
end

function __netmode_clear --argument-names iface
    # Upload: убираем CAKE с корня физического интерфейса.
    sudo tc qdisc del dev "$iface" root 2>/dev/null

    # Download: удаляем ingress-qdisc вместе со всеми фильтрами.
    sudo tc qdisc del dev "$iface" ingress 2>/dev/null

    # Download: убираем CAKE с IFB-интерфейса, если он существует.
    if ip link show dev ifb0 >/dev/null 2>&1
        sudo tc qdisc del dev ifb0 root 2>/dev/null
    end

    return 0
end

function __netmode_limit --argument-names iface rate
    # ------------------------------------------------------------------
    # 1. Готовим IFB для ограничения скачивания
    # ------------------------------------------------------------------
    if not sudo modprobe ifb 2>/dev/null
        if not ip link show dev ifb0 >/dev/null 2>&1
            __netmode_error '❌ Не удалось загрузить модуль ifb.'
            echo '   Проверьте вручную: sudo modprobe ifb'
            return 1
        end
    end

    if not ip link show dev ifb0 >/dev/null 2>&1
        if not sudo ip link add ifb0 type ifb
            __netmode_error '❌ Не удалось создать интерфейс ifb0.'
            return 1
        end
    end

    if not sudo ip link set dev ifb0 up
        __netmode_error '❌ Не удалось поднять интерфейс ifb0.'
        return 1
    end

    # ------------------------------------------------------------------
    # 2. Download: ingress на физическом интерфейсе → ifb0 → CAKE
    # ------------------------------------------------------------------
    # Удаляем старый ingress, чтобы повторный запуск не создавал дубли.
    sudo tc qdisc del dev "$iface" ingress 2>/dev/null

    if not sudo tc qdisc add dev "$iface" handle ffff: ingress
        __netmode_error '❌ Не удалось создать ingress-qdisc для скачивания.'
        return 1
    end

    if not sudo tc filter add dev "$iface" parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev ifb0
        __netmode_error '❌ Не удалось перенаправить входящий трафик в ifb0.'
        sudo tc qdisc del dev "$iface" ingress 2>/dev/null
        return 1
    end

    if not sudo tc qdisc replace dev ifb0 root cake bandwidth "$rate"mbit
        __netmode_error '❌ Не удалось включить CAKE на ifb0.'
        sudo tc qdisc del dev "$iface" ingress 2>/dev/null
        return 1
    end

    # ------------------------------------------------------------------
    # 3. Upload: CAKE на корне физического интерфейса
    # ------------------------------------------------------------------
    if not sudo tc qdisc replace dev "$iface" root cake bandwidth "$rate"mbit
        __netmode_error '❌ Не удалось включить CAKE для upload.'
        # Откатываем download, чтобы не оставлять половину лимита.
        sudo tc qdisc del dev "$iface" ingress 2>/dev/null
        sudo tc qdisc del dev ifb0 root 2>/dev/null
        return 1
    end

    return 0
end

function __netmode_status --argument-names iface
    set -l root_qdisc (sudo tc qdisc show dev "$iface" root 2>/dev/null | string collect)
    set -l ingress_qdisc (sudo tc qdisc show dev "$iface" 2>/dev/null | string match -r 'qdisc ingress' | string collect)
    set -l ifb_qdisc (sudo tc qdisc show dev ifb0 root 2>/dev/null | string collect)
    set -l filters (sudo tc filter show dev "$iface" parent ffff: 2>/dev/null | string collect)

    # Upload
    set -l up_on 0
    set -l up_rate ''
    if string match -qr '^qdisc cake' -- "$root_qdisc"
        set up_on 1
        set up_rate (string match -r 'bandwidth [0-9.]+[KMGT]?bit' -- "$root_qdisc" |
            string replace 'bandwidth ' '' | head -n1)
    end

    # Download: нужны ingress, перенаправление в ifb0 и CAKE на ifb0.
    set -l has_redirect 0
    if string match -qr ifb0 -- "$filters"
        set has_redirect 1
    end

    set -l down_on 0
    set -l down_rate ''
    if test -n "$ingress_qdisc"; and test -n "$ifb_qdisc"
        set down_rate (string match -r 'bandwidth [0-9.]+[KMGT]?bit' -- "$ifb_qdisc" |
            string replace 'bandwidth ' '' | head -n1)
        if string match -qr '^qdisc cake' -- "$ifb_qdisc"; and test $has_redirect -eq 1
            set down_on 1
        end
    end

    # Есть ли вообще остатки правил (для частичного состояния).
    set -l down_any 0
    if test -n "$ingress_qdisc"
        set down_any 1
    end
    if string match -qr '^qdisc cake' -- "$ifb_qdisc"
        set down_any 1
    end
    if test $has_redirect -eq 1
        set down_any 1
    end

    # ------------------------------------------------------------------
    # Вывод
    # ------------------------------------------------------------------
    set_color --bold
    echo '🌐 Статус ограничения'
    set_color normal
    printf '   Интерфейс: %s\n' "$iface"

    if test $up_on -eq 1; and test $down_on -eq 1
        printf '   Состояние: включено (upload + download)\n'
    else if test $up_on -eq 1
        printf '   Состояние: включено частично (только upload)\n'
    else if test $down_on -eq 1
        printf '   Состояние: включено частично (только download)\n'
    else if test $down_any -eq 1
        printf '   Состояние: настроено частично / есть остатки правил\n'
    else
        printf '   Состояние: выключено\n'
    end

    if test $up_on -eq 1
        if test -n "$up_rate"
            printf '   Upload:    %s (CAKE)\n' (__netmode_pretty_rate "$up_rate")
        else
            printf '   Upload:    CAKE без параметра bandwidth\n'
        end
    else
        printf '   Upload:    без ограничений\n'
    end

    if test $down_on -eq 1
        printf '   Download:  %s (CAKE через ifb0)\n' (__netmode_pretty_rate "$down_rate")
    else if test $down_any -eq 1
        printf '   Download:  правила есть, но настроены не полностью\n'
    else
        printf '   Download:  без ограничений\n'
    end
end

function __netmode_pretty_rate --argument-names raw
    switch "$raw"
        case '*Mbit'
            string replace Mbit ' Мбит' -- "$raw"
        case '*Gbit'
            string replace Gbit ' Гбит' -- "$raw"
        case '*Kbit'
            string replace Kbit ' Кбит' -- "$raw"
        case '*'
            printf '%s\n' "$raw"
    end
end
