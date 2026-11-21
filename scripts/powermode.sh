#!/usr/bin/env bash
# =============================================================================
# powermode.sh — управление энергопотреблением и производительностью ноутбука
# CachyOS · AMD Ryzen 7 5700U · Hyprland · Noctalia · gum
#
# Режимы: Максимальная экономия / Обычный / Максимальная производительность
# + пункт «Показать статус».
#
# Профиль питания переключается через power-profiles-daemon — тот же backend,
# которым пользуется Noctalia. Скрипт не запускает TLP и не перетирает профиль
# настройками governor/EPP/частоты CPU.
#
# Установка:  ~/data/dotfiles/scripts/powermode.sh  (chmod +x)
# Запуск:     powermode.sh           (от обычного пользователя, sudo — по мере нужды)
#
# ВАЖНО: скрипт намеренно НЕ перезапускает себя целиком через sudo — под root
# пропадает окружение Hyprland (hyprctl) и сессии (brightnessctl). Вместо этого
# он работает от вашего пользователя, а root-команды выполняет через sudo.
# Если же запустить его через `sudo powermode.sh`, пользовательские команды
# будут автоматически выполнены от $SUDO_USER с нужным окружением.
# =============================================================================
set -euo pipefail

# ─────────────────────────── НАСТРОЙКИ (меняйте здесь) ────────────────────────
ECO_BRIGHTNESS=60         # яркость, %
NORMAL_BRIGHTNESS=60
PERF_BRIGHTNESS=100

CHARGE_LIMIT=80            # порог зарядки, %, если поддерживается

# ──────────────────────────────────────────────────────────────────────────────

CPU_SYS=/sys/devices/system/cpu
CPU0=$CPU_SYS/cpu0/cpufreq
WARN_COUNT=0
NV_DEVS=()

# ─────────────────────────── Вывод сообщений ─────────────────────────────────
ok()   { printf '\e[32m✔\e[0m %s\n' "$*"; }
info() { printf '\e[36m•\e[0m %s\n' "$*"; }
warn() { printf '\e[33m⚠\e[0m %s\n' "$*" >&2; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { printf '\e[31m✘\e[0m %s\n' "$*" >&2; WARN_COUNT=$((WARN_COUNT + 1)); }
die()  { printf '\e[31m✘\e[0m %s\n' "$*" >&2; exit 1; }

trap 'echo; exit 130' INT

# ─────────────────────────── Вспомогательные функции ─────────────────────────
have() { command -v "$1" >/dev/null 2>&1; }

# read_file <путь> [значение_по_умолчанию]
read_file() {
    local out
    if [[ -r $1 ]] && out=$(cat "$1" 2>/dev/null); then
        printf '%s' "$out"
    else
        printf '%s' "${2:-}"
    fi
}

khz_to_ghz() { awk -v k="${1:-0}" 'BEGIN { printf "%.2f ГГц", k / 1000000 }'; }

# ─────────────────────────── Права и sudo ────────────────────────────────────
SUDO=""
if (( EUID == 0 )); then
    if [[ -z ${SUDO_USER:-} || ${SUDO_USER:-} == root ]]; then
        printf '\e[33m⚠\e[0m Запущено напрямую от root: hyprctl и brightnessctl работать не будут.\n' >&2
    fi
else
    have sudo || die "sudo не найден — установите его: pacman -S sudo"
    SUDO="sudo"
fi

ensure_sudo() {
    (( EUID == 0 )) && return 0
    sudo -v || die "Не удалось получить права sudo."
}

# Выполнить пользовательскую команду (hyprctl, brightnessctl) от имени
# реального пользователя, даже если скрипт запущен через sudo.
run_user() {
    if (( EUID != 0 )); then
        "$@"
        return
    fi
    [[ -n ${SUDO_USER:-} && $SUDO_USER != root ]] || return 1
    local uid sig
    uid=$(id -u "$SUDO_USER")
    sig=$(find "/run/user/$uid/hypr" -mindepth 1 -maxdepth 1 -type d \
              -printf '%T@ %f\n' 2>/dev/null | sort -rn | head -n1 | cut -d' ' -f2 || true)
    sudo -u "$SUDO_USER" env \
        XDG_RUNTIME_DIR="/run/user/$uid" \
        HYPRLAND_INSTANCE_SIGNATURE="$sig" \
        "$@"
}

# write_sys <значение> <файл> — запись в sysfs/procfs с правами root
write_sys() {
    printf '%s' "$1" | $SUDO tee "$2" >/dev/null 2>&1
}

# ─────────────────────────── Диалог да/нет ───────────────────────────────────
# ask_yn "Вопрос" [no]   — второй аргумент "no" делает ответ по умолчанию «Нет»
ask_yn() {
    local prompt=$1 ans
    if have gum; then
        if [[ ${2:-} == no ]]; then
            gum confirm --default=false "$prompt"
        else
            gum confirm "$prompt"
        fi
        return
    fi
    read -r -p "$prompt [y/N] " ans || return 1
    [[ $ans =~ ^[YyДд] ]]
}

# ─────────────────────────── Проверка зависимостей ───────────────────────────
check_deps() {
    local cmd pkg
    # gum нужен для меню, powerprofilesctl — для переключения профиля,
    # остальные команды используются дополнительными шагами.
    local -a all=(gum powerprofilesctl brightnessctl)
    for cmd in "${all[@]}"; do
        have "$cmd" && continue
        warn "Не найдена утилита: $cmd"
        pkg=$cmd
        [[ $cmd == powerprofilesctl ]] && pkg=power-profiles-daemon
        if have pacman && ask_yn "Установить '$pkg' через pacman?"; then
            if $SUDO pacman -S --needed --noconfirm "$pkg"; then
                ok "$pkg установлен"
            else
                fail "Не удалось установить $pkg"
            fi
        fi
        if [[ $cmd == gum ]] && ! have gum; then
            die "Без gum меню недоступно. Установите: sudo pacman -S gum"
        fi
        have "$cmd" || warn "Продолжаю без $cmd — связанные шаги будут пропущены."
    done
    have rfkill  || warn "rfkill не найден (util-linux) — Bluetooth не будет затронут."
    have hyprctl || warn "hyprctl не найден — настройки Hyprland будут пропущены."
}

check_conflicts() {
    if ! have powerprofilesctl; then
        warn "powerprofilesctl не найден — профили Noctalia переключать не получится."
    fi
    if systemctl is-active --quiet tlp.service 2>/dev/null; then
        warn "Активен TLP — он может перетирать профиль, выбранный в Noctalia."
    fi
}

# ─────────────────────────── 1. ПРОФИЛЬ ПИТАНИЯ ──────────────────────────────
profile_apply() {
    local mode=$1 profile label
    case $mode in
        eco)    profile=power-saver; label="экономия" ;;
        normal) profile=balanced;    label="баланс" ;;
        perf)   profile=performance; label="производительность" ;;
        *)      warn "Неизвестный режим: $mode"; return 1 ;;
    esac

    if ! have powerprofilesctl; then
        warn "powerprofilesctl не установлен — профиль питания не изменён"
        return 0
    fi
    if ! run_user powerprofilesctl set "$profile" >/dev/null 2>&1; then
        fail "Не удалось выбрать профиль power-profiles-daemon: $profile"
        return 1
    fi
    if [[ $(run_user powerprofilesctl get 2>/dev/null || true) != "$profile" ]]; then
        warn "powerprofilesctl не подтвердил профиль '$profile'"
        return 0
    fi
    ok "Профиль питания: $label ($profile)"
}

# ─────────────────────────── 2. ЭКРАН, HYPRLAND, BLUETOOTH, NVIDIA ───────────
hypr_ok() { have hyprctl && run_user hyprctl version >/dev/null 2>&1; }

# hypr_set <ключ> <значение> <описание>
hypr_set() {
    local out
    out=$(run_user hyprctl keyword "$1" "$2" 2>&1) || out="error"
    if [[ $out == ok* ]]; then
        ok "Hyprland: $3"
    else
        warn "Hyprland: не удалось применить $1 ($3)"
    fi
}

set_brightness() {
    if ! have brightnessctl; then
        warn "brightnessctl не установлен — яркость не изменена"
        return 0
    fi
    if run_user brightnessctl -q set "$1%" >/dev/null 2>&1; then
        ok "Яркость: $1%"
    else
        warn "Не удалось изменить яркость (нужна группа video или udev-правила brightnessctl)"
    fi
}

set_bluetooth() { # block | unblock
    have rfkill || { warn "rfkill недоступен — Bluetooth не изменён"; return 0; }
    if $SUDO rfkill "$1" bluetooth >/dev/null 2>&1; then
        if [[ $1 == block ]]; then ok "Bluetooth отключён"; else ok "Bluetooth разблокирован"; fi
    else
        fail "rfkill $1 bluetooth: ошибка"
    fi
}

display_apply() {
    local mode=$1
    if hypr_ok; then
        case $mode in
            eco)
                hypr_set animations:enabled false "анимации выключены"
                hypr_set decoration:blur:enabled false "blur выключен"
                hypr_set misc:vfr true "VFR включён"
                ;;
            perf)
                # reload возвращает значения из конфига, затем явно включаем анимации
                run_user hyprctl reload >/dev/null 2>&1 || warn "hyprctl reload не удался"
                hypr_set animations:enabled true "анимации включены"
                ;;
            normal)
                if run_user hyprctl reload >/dev/null 2>&1; then
                    ok "Hyprland: настройки возвращены из конфига"
                else
                    warn "hyprctl reload не удался"
                fi
                ;;
        esac
    else
        warn "Hyprland недоступен (не запущен или нет hyprctl) — настройки окружения пропущены"
    fi

    case $mode in
        eco)
            set_brightness "$ECO_BRIGHTNESS"
            if ask_yn "Отключить Bluetooth?"; then
                set_bluetooth block
            else
                info "Bluetooth оставлен без изменений"
            fi
            ;;
        perf)
            set_brightness "$PERF_BRIGHTNESS"
            set_bluetooth unblock
            ;;
        normal)
            set_brightness "$NORMAL_BRIGHTNESS"
            set_bluetooth unblock
            ;;
    esac
}

find_nvidia() {
    NV_DEVS=()
    local d class
    for d in /sys/bus/pci/devices/*; do
        [[ $(read_file "$d/vendor" "") == 0x10de ]] || continue
        class=$(read_file "$d/class" "")
        [[ $class == 0x03* ]] || continue
        NV_DEVS+=("$d")
    done
}

nvidia_state() { # <pci-dev> → Active / Suspended / ...
    local s
    s=$(read_file "$1/power/runtime_status" "unsupported")
    case $s in
        active)    echo "Active" ;;
        suspended) echo "Suspended" ;;
        *)         echo "$s" ;;
    esac
}

nvidia_apply() {
    local mode=$1 d state
    find_nvidia
    if (( ${#NV_DEVS[@]} == 0 )); then
        info "Дискретная NVIDIA не обнаружена — шаг пропущен"
        return 0
    fi
    for d in "${NV_DEVS[@]}"; do
        if [[ $mode != perf ]]; then
            if write_sys auto "$d/power/control"; then
                ok "NVIDIA ($(basename "$d")): runtime PM = auto"
            else
                warn "NVIDIA ($(basename "$d")): не удалось включить runtime PM"
            fi
            sleep 1
        fi
        state=$(nvidia_state "$d")
        if [[ $state == Suspended ]]; then
            ok "NVIDIA ($(basename "$d")): Suspended — карта в простое"
        else
            info "NVIDIA ($(basename "$d")): $state"
            if [[ $mode != perf ]]; then
                info "Карту кто-то использует. Посмотреть: sudo lsof /dev/nvidia* /dev/dri/*"
            fi
        fi
    done
}

# ─────────────────────────── 3. ПОРОГ ЗАРЯДКИ ────────────────────────────────
charge_apply() {
    local bat f found=0
    for bat in /sys/class/power_supply/BAT*; do
        f=$bat/charge_control_end_threshold
        [[ -e $f ]] || continue
        found=1
        if write_sys "$CHARGE_LIMIT" "$f"; then
            ok "Порог зарядки $(basename "$bat"): $CHARGE_LIMIT%"
        else
            fail "Не удалось записать порог зарядки в $f"
        fi
    done
    if (( found == 0 )); then
        info "Порог зарядки этим ноутбуком/ядром не поддерживается — пропущено"
    fi
}

# ─────────────────────────── ПРИМЕНЕНИЕ РЕЖИМА ───────────────────────────────
mode_title() {
    case $1 in
        eco)    echo "🔋 Максимальная экономия" ;;
        normal) echo "⚖  Обычный (сбалансированный)" ;;
        perf)   echo "🚀 Максимальная производительность" ;;
    esac
}

apply_mode() {
    local mode=$1
    WARN_COUNT=0
    ensure_sudo
    echo
    gum style --foreground 212 --bold "Применяю режим: $(mode_title "$mode")"
    echo

    profile_apply "$mode" || true
    charge_apply          || true
    display_apply "$mode" || true
    nvidia_apply  "$mode" || true

    echo
    if (( WARN_COUNT == 0 )); then
        gum style --foreground 42 --bold "✔ Режим применён без замечаний."
    else
        gum style --foreground 214 --bold "⚠ Режим применён не полностью или с замечаниями: $WARN_COUNT (см. выше)."
    fi
    info "Дополнительные настройки могут сброситься после перезагрузки."
}

# ─────────────────────────── 4. СТАТУС ───────────────────────────────────────
row() { printf '%-24s %s\n' "$1" "$2"; }

status_profile() {
    have powerprofilesctl || { echo "powerprofilesctl не установлен"; return; }
    run_user powerprofilesctl get 2>/dev/null || echo "н/д"
}

status_cpu_freq() {
    local freqs
    freqs=$(cat "$CPU_SYS"/cpu[0-9]*/cpufreq/scaling_cur_freq 2>/dev/null || true)
    [[ -n $freqs ]] || { echo "н/д"; return; }
    awk 'NR==1 {min=max=$1} {s+=$1; if($1<min)min=$1; if($1>max)max=$1}
         END {printf "ср. %.2f ГГц (мин %.2f / макс %.2f)", s/NR/1e6, min/1e6, max/1e6}' <<<"$freqs"
}

status_battery() {
    local b="" x cap st now rate hours
    for x in /sys/class/power_supply/BAT*; do
        if [[ -d $x ]]; then b=$x; break; fi
    done
    if [[ -z $b ]]; then
        row "Батарея:" "не найдена"
        return
    fi
    cap=$(read_file "$b/capacity" "?")
    st=$(read_file "$b/status" "?")
    row "Заряд:" "${cap}% ($st)"

    now=$(read_file "$b/energy_now" "")
    [[ -n $now ]] || now=$(read_file "$b/charge_now" "")
    rate=$(read_file "$b/power_now" "")
    [[ -n $rate ]] || rate=$(read_file "$b/current_now" "")

    if [[ $st == Discharging && -n $now && -n $rate ]] && (( rate > 0 )); then
        hours=$(awk -v n="$now" -v r="$rate" 'BEGIN {h=n/r; printf "%d ч %02d мин", int(h), (h-int(h))*60}')
        row "До разрядки:" "≈ $hours"
    elif [[ $st == Charging && -n $now && -n $rate ]] && (( rate > 0 )); then
        local full
        full=$(read_file "$b/energy_full" "")
        [[ -n $full ]] || full=$(read_file "$b/charge_full" "")
        if [[ -n $full ]]; then
            hours=$(awk -v n="$now" -v f="$full" -v r="$rate" \
                'BEGIN {h=(f-n)/r; if(h<0)h=0; printf "%d ч %02d мин", int(h), (h-int(h))*60}')
            row "До полной зарядки:" "≈ $hours"
        fi
    else
        row "До разрядки:" "н/д (не на батарее)"
    fi

    if [[ -e $b/charge_control_end_threshold ]]; then
        row "Порог зарядки:" "$(read_file "$b/charge_control_end_threshold" "?")%"
    else
        row "Порог зарядки:" "не поддерживается"
    fi
}

status_nvidia() {
    find_nvidia
    if (( ${#NV_DEVS[@]} == 0 )); then
        row "NVIDIA:" "не обнаружена"
        return
    fi
    local d
    for d in "${NV_DEVS[@]}"; do
        row "NVIDIA ($(basename "$d")):" "$(nvidia_state "$d")"
    done
}

status_text() {
    local boost bt br anim
    row "Профиль питания:" "$(status_profile)"
    echo
    row "Драйвер CPU:" "$(read_file "$CPU0/scaling_driver" "н/д")"
    row "Governor:" "$(read_file "$CPU0/scaling_governor" "н/д")"
    row "EPP:" "$(read_file "$CPU0/energy_performance_preference" "н/д")"
    row "Частота CPU:" "$(status_cpu_freq)"
    row "Лимит частоты:" "$(khz_to_ghz "$(read_file "$CPU0/scaling_max_freq" 0)")"
    boost=$(read_file "$CPU_SYS/cpufreq/boost" "")
    case $boost in
        1) boost="включён" ;;
        0) boost="выключен" ;;
        *) boost="н/д" ;;
    esac
    row "CPU Boost:" "$boost"
    echo
    status_battery
    echo
    status_nvidia
    echo
    row "vm.swappiness:" "$(read_file /proc/sys/vm/swappiness "н/д")"
    row "NMI watchdog:" "$(read_file /proc/sys/kernel/nmi_watchdog "н/д")"

    if have rfkill; then
        bt=$(rfkill -n -o SOFT list bluetooth 2>/dev/null | head -n1 || true)
        row "Bluetooth:" "${bt:-н/д}"
    fi
    if have brightnessctl; then
        br=$(run_user brightnessctl -m 2>/dev/null | head -n1 | cut -d, -f4 || true)
        row "Яркость:" "${br:-н/д}"
    fi
    if hypr_ok; then
        anim=$(run_user hyprctl getoption animations:enabled 2>/dev/null | awk '/int:/ {print $2; exit}' || true)
        case $anim in
            1) anim="включены" ;;
            0) anim="выключены" ;;
            *) anim="н/д" ;;
        esac
        row "Анимации Hyprland:" "$anim"
    fi
}

show_status() {
    local text
    text=$(status_text)
    echo
    gum style --border rounded --padding "1 2" --border-foreground 212 "$text"
}

# ─────────────────────────── МЕНЮ ────────────────────────────────────────────
pause() { read -rsp $'\nEnter — вернуться в меню…' _ || true; echo; }

main_menu() {
    local choice
    while true; do
        clear
        gum style --border double --padding "0 2" --foreground 212 --bold \
            "⚡ Power Mode · Ryzen 7 5700U"
        echo
        choice=$(gum choose --header "Выберите режим:" \
            "🔋 Максимальная экономия" \
            "⚖  Обычный (сбалансированный)" \
            "🚀 Максимальная производительность" \
            "📊 Показать статус" \
            "🚪 Выход") || break

        case $choice in
            *экономия*)         apply_mode eco    || true; pause ;;
            *Обычный*)          apply_mode normal || true; pause ;;
            *производительность*) apply_mode perf || true; pause ;;
            *статус*)           show_status       || true; pause ;;
            *Выход*|"")         break ;;
        esac
    done
}

# ─────────────────────────── ТОЧКА ВХОДА ─────────────────────────────────────
main() {
    check_deps
    check_conflicts
    main_menu
    echo "Пока!"
}

main "$@"
