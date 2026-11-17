#!/usr/bin/env bash
# =============================================================================
# powermode.sh — управление энергопотреблением и производительностью ноутбука
# CachyOS · AMD Ryzen 7 5700U · Hyprland · gum
#
# Режимы: Максимальная экономия / Обычный / Максимальная производительность
# + пункт «Показать статус».
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
ECO_MAX_KHZ=1800000        # лимит частоты в экономии (1.8 ГГц)
ECO_BRIGHTNESS=30          # яркость, %
NORMAL_BRIGHTNESS=60
PERF_BRIGHTNESS=100

CHARGE_LIMIT=80            # порог зарядки, %, если поддерживается

SWAPPINESS_ECO=10
SWAPPINESS_NORMAL=60
SWAPPINESS_PERF=60

NMI_ECO=0                  # NMI watchdog: 0 — выкл (экономия), 1 — вкл
NMI_NORMAL=1
NMI_PERF=1

EPP_ECO="power"
EPP_NORMAL="balance_power"
EPP_PERF="performance"
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

has_word() { [[ " $1 " == *" $2 "* ]]; }

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

# set_cpu_attr <атрибут cpufreq> <значение> — для всех ядер сразу
set_cpu_attr() {
    local attr=$1 value=$2
    local files=("$CPU_SYS"/cpu[0-9]*/cpufreq/"$attr")
    [[ -e ${files[0]} ]] || return 2
    printf '%s' "$value" | $SUDO tee "${files[@]}" >/dev/null 2>&1
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
    local cmd
    # gum — обязателен, остальное — по желанию (соответствующие шаги будут пропущены)
    local -a all=(gum tlp cpupower brightnessctl)
    for cmd in "${all[@]}"; do
        have "$cmd" && continue
        warn "Не найдена утилита: $cmd"
        if have pacman && ask_yn "Установить '$cmd' через pacman?"; then
            if $SUDO pacman -S --needed --noconfirm "$cmd"; then
                ok "$cmd установлен"
            else
                fail "Не удалось установить $cmd"
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
    if systemctl is-active --quiet power-profiles-daemon.service 2>/dev/null; then
        warn "Активен power-profiles-daemon — он конфликтует с TLP и может перебивать настройки."
        info "Рекомендация: sudo systemctl disable --now power-profiles-daemon && sudo systemctl enable --now tlp"
    fi
    if have tlp && ! systemctl is-enabled --quiet tlp.service 2>/dev/null; then
        warn "Служба tlp.service не включена (sudo systemctl enable --now tlp)."
    fi
}

# ─────────────────────────── 1. ПРОЦЕССОР ────────────────────────────────────
set_governor() {
    local avail g
    avail=$(read_file "$CPU0/scaling_available_governors" "")
    for g in "$@"; do
        has_word "$avail" "$g" || continue
        if set_cpu_attr scaling_governor "$g"; then
            ok "Governor: $g"
            return 0
        fi
        fail "Не удалось выставить governor '$g'"
        return 1
    done
    warn "Подходящий governor не найден (доступны: ${avail:-нет данных})"
    return 1
}

set_epp() {
    local avail p
    avail=$(read_file "$CPU0/energy_performance_available_preferences" "")
    if [[ -z $avail ]]; then
        warn "EPP не поддерживается текущим драйвером — пропущено"
        return 0
    fi
    for p in "$@"; do
        has_word "$avail" "$p" || continue
        if set_cpu_attr energy_performance_preference "$p"; then
            ok "EPP (energy_performance_preference): $p"
        else
            warn "EPP '$p' не применился (при governor=performance это нормально — он зафиксирован)"
        fi
        return 0
    done
    warn "Нужное значение EPP недоступно (есть: $avail)"
}

set_boost() {
    local f=$CPU_SYS/cpufreq/boost label
    label=$([[ $1 == 1 ]] && echo "включён" || echo "выключен")
    if [[ ! -e $f ]]; then
        warn "CPU Boost: управление не поддерживается ($f отсутствует)"
        return 0
    fi
    if write_sys "$1" "$f"; then
        ok "CPU Boost $label"
    else
        fail "CPU Boost: не удалось записать в $f"
    fi
}

# set_max_freq <kHz | max>
set_max_freq() {
    local target=$1 hw done_=0
    hw=$(read_file "$CPU0/cpuinfo_max_freq" "")
    [[ $target == max ]] && target=$hw
    if [[ -z $target ]]; then
        warn "Не удалось определить максимальную частоту — лимит не изменён"
        return 0
    fi
    if have cpupower; then
        if $SUDO cpupower frequency-set -u "${target}kHz" >/dev/null 2>&1; then
            done_=1
        else
            warn "cpupower не справился, пишу напрямую в sysfs"
        fi
    fi
    if (( done_ == 0 )); then
        if set_cpu_attr scaling_max_freq "$target"; then
            done_=1
        fi
    fi
    if (( done_ == 1 )); then
        ok "Максимальная частота: $(khz_to_ghz "$target")"
    else
        fail "Не удалось установить лимит частоты"
    fi
}

cpu_apply() {
    local mode=$1 driver epp_driver=0
    if [[ ! -d $CPU0 ]]; then
        warn "cpufreq недоступен — настройки CPU пропущены"
        return 0
    fi
    driver=$(read_file "$CPU0/scaling_driver" "unknown")
    info "Драйвер CPU: $driver"
    case $driver in
        amd-pstate-epp) epp_driver=1 ;;
        acpi-cpufreq|amd-pstate|amd-pstate-guided) ;;
        *) warn "Нестандартный драйвер '$driver' — применяю настройки по возможности" ;;
    esac
    [[ -e $CPU0/energy_performance_preference ]] && epp_driver=1

    case $mode in
        eco)
            set_governor powersave schedutil || true
            (( epp_driver )) && { set_epp "$EPP_ECO" powersave || true; }
            set_max_freq "$ECO_MAX_KHZ" || true
            set_boost 0 || true
            ;;
        perf)
            # Сначала Boost, потом снимаем лимит — иначе cpuinfo_max_freq может быть занижен
            set_boost 1 || true
            set_max_freq max || true
            set_governor performance || true
            (( epp_driver )) && { set_epp "$EPP_PERF" || true; }
            ;;
        normal)
            set_boost 1 || true
            set_max_freq max || true
            if (( epp_driver )); then
                # В режиме EPP доступны только performance/powersave
                set_governor powersave || true
                set_epp "$EPP_NORMAL" balance_performance || true
            else
                set_governor schedutil ondemand powersave || true
            fi
            ;;
    esac
}

# ─────────────────────────── 2. TLP ──────────────────────────────────────────
tlp_apply() {
    local mode=$1 label
    local -a cmd
    if ! have tlp; then
        warn "TLP не установлен — шаг пропущен"
        return 0
    fi
    case $mode in
        eco)    cmd=(tlp bat);                label="профиль BAT (tlp bat)" ;;
        perf)   cmd=(tlp ac);                 label="профиль AC (tlp ac)" ;;
        normal) cmd=(systemctl restart tlp);  label="перезапуск, профиль по источнику питания" ;;
    esac
    if $SUDO "${cmd[@]}" >/dev/null 2>&1; then
        ok "TLP: $label"
    else
        fail "TLP: команда '${cmd[*]}' завершилась ошибкой"
    fi
}

# ─────────────────────────── 3. ЭКРАН, HYPRLAND, BLUETOOTH, NVIDIA ───────────
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

# ─────────────────────────── 4. ПОРОГ ЗАРЯДКИ ────────────────────────────────
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
        warn "Порог зарядки: не поддерживается этим ноутбуком/ядром — пропущено"
    fi
}

# ─────────────────────────── 5. СИСТЕМНЫЕ НАСТРОЙКИ ──────────────────────────
sys_apply() {
    local mode=$1 swap nmi
    case $mode in
        eco)    swap=$SWAPPINESS_ECO;    nmi=$NMI_ECO ;;
        perf)   swap=$SWAPPINESS_PERF;   nmi=$NMI_PERF ;;
        normal) swap=$SWAPPINESS_NORMAL; nmi=$NMI_NORMAL ;;
    esac

    if [[ -e /proc/sys/vm/swappiness ]]; then
        if $SUDO sysctl -qw "vm.swappiness=$swap" >/dev/null 2>&1; then
            ok "vm.swappiness = $swap"
        else
            fail "Не удалось установить vm.swappiness"
        fi
    else
        warn "vm.swappiness не поддерживается"
    fi

    if [[ -e /proc/sys/kernel/nmi_watchdog ]]; then
        if $SUDO sysctl -qw "kernel.nmi_watchdog=$nmi" >/dev/null 2>&1; then
            ok "NMI watchdog = $nmi"
        else
            fail "Не удалось изменить NMI watchdog"
        fi
    else
        warn "NMI watchdog: не поддерживается (отключён при загрузке ядра)"
    fi

    if [[ $mode == eco ]]; then
        if have powertop; then
            warn "powertop --auto-tune включает autosuspend для USB: возможны лаги мыши/клавиатуры."
            if ask_yn "Всё же применить powertop --auto-tune?" no; then
                if $SUDO powertop --auto-tune >/dev/null 2>&1; then
                    ok "powertop --auto-tune применён (до перезагрузки)"
                else
                    fail "powertop --auto-tune завершился ошибкой"
                fi
            else
                info "powertop --auto-tune пропущен"
            fi
        else
            info "powertop не установлен — автонастройка USB пропущена (TLP и так управляет USB autosuspend)"
        fi
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

    # Порядок важен: TLP первым, чтобы наши настройки CPU его не перебили
    tlp_apply     "$mode" || true
    cpu_apply     "$mode" || true
    sys_apply     "$mode" || true
    charge_apply          || true
    display_apply "$mode" || true
    nvidia_apply  "$mode" || true

    echo
    if (( WARN_COUNT == 0 )); then
        gum style --foreground 42 --bold "✔ Режим применён без замечаний."
    else
        gum style --foreground 214 --bold "✔ Режим применён, замечаний: $WARN_COUNT (см. выше)."
    fi
    info "Часть настроек (sysctl, sysfs) сбросится после перезагрузки."
}

# ─────────────────────────── 6. СТАТУС ───────────────────────────────────────
row() { printf '%-24s %s\n' "$1" "$2"; }

status_tlp() {
    have tlp-stat || { echo "TLP не установлен"; return; }
    local out state mode
    out=$($SUDO tlp-stat -s 2>/dev/null) || out=""
    state=$(grep -m1 -E '^State' <<<"$out" | sed -E 's/^State *= *//' || true)
    mode=$(grep -m1 -E '^(Mode|Power source)' <<<"$out" | sed -E 's/^[A-Za-z ]+= *//' || true)
    echo "${mode:-н/д}${state:+ (служба: $state)}"
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
    row "Профиль TLP:" "$(status_tlp)"
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
    ensure_sudo
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
