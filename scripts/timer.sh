#!/usr/bin/env bash
# timer.sh — таймер, который живёт в фоне (systemd --user), окно терминала можно закрыть.
#
#   timer.sh [время]     запустить таймер в фоне (без аргумента — спросит время)
#   timer.sh -f [время]  то же, но с живым отсчётом в окне (закроешь окно — таймер отменится)
#   timer.sh ls          показать активные таймеры и сколько осталось
#   timer.sh cancel      отменить таймер (выбор из списка; «cancel all» — все)
#
# Форматы времени: 90 (= минуты), 45s, 5m, 1h30m, 1:30 (= 1 мин 30 с), 25m30s
# Зависимости: systemd (--user), notify-send; опционально gum, paplay
set -u

SELF=$(readlink -f "$0")
META=${XDG_CACHE_HOME:-$HOME/.cache}/timers
mkdir -p "$META"

parse() {   # строка -> секунды (код 1 при ошибке)
    local s=${1,,} total=0 n u
    s=${s//[[:space:]]/}
    [[ -z $s ]] && return 1
    if [[ $s =~ ^[0-9]+$ ]]; then echo $((10#$s * 60)); return; fi
    if [[ $s =~ ^([0-9]+):([0-9]{1,2})$ ]]; then echo $((10#${BASH_REMATCH[1]} * 60 + 10#${BASH_REMATCH[2]})); return; fi
    while [[ -n $s ]]; do
        [[ $s =~ ^([0-9]+)(h|m|s)(.*)$ ]] || return 1
        n=${BASH_REMATCH[1]}; u=${BASH_REMATCH[2]}; s=${BASH_REMATCH[3]}
        case $u in h) total=$((total + 10#$n * 3600));; m) total=$((total + 10#$n * 60));; s) total=$((total + 10#$n));; esac
    done
    echo "$total"
}

fmt() { local t=$1; if (( t >= 3600 )); then printf '%d:%02d:%02d' $((t/3600)) $((t%3600/60)) $((t%60)); else printf '%02d:%02d' $((t/60)) $((t%60)); fi; }

ask_time() {
    local input
    if command -v gum >/dev/null; then
        input=$(gum input --placeholder "Время: 5m, 1h30m, 90s, 1:30 …" --prompt "⏱  ") || exit 0
    else
        read -r -p "⏱  Время (5m, 1h30m, 90s, 1:30): " input || exit 0
    fi
    echo "$input"
}

alarm() {   # уведомление + звук
    notify-send -u critical -a timer "⏰ Таймер" "$1" 2>/dev/null
    local snd
    for snd in /usr/share/sounds/freedesktop/stereo/complete.oga /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga; do
        if [[ -f $snd ]] && command -v paplay >/dev/null; then paplay "$snd" 2>/dev/null; break; fi
    done
}

active_units() { systemctl --user list-units 'timer-*.timer' --no-legend --plain 2>/dev/null | awk '{print $1}'; }

cmd_start() {
    local input=${1:-} secs unit label endclock
    [[ -z $input ]] && input=$(ask_time)
    secs=$(parse "$input") || { echo "Не понял «$input». Примеры: 5m, 1h30m, 90s, 1:30"; read -r -n1 -p "Enter…"; exit 1; }
    (( secs > 0 )) || exit 0

    unit="timer-$(date +%s)-$RANDOM"
    label=$(fmt "$secs")
    endclock=$(date -d "+$secs sec" +%H:%M:%S)
    echo $(( $(date +%s) + secs )) > "$META/$unit"

    if systemd-run --user --quiet --unit="$unit" --on-active="${secs}s" \
            --timer-property=AccuracySec=1s --description="Таймер $label" \
            "$SELF" _fire "$label" "$unit"; then
        echo "  ✅ Таймер на $label запущен — сработает в $endclock"
        echo "     Работает в фоне, окно можно закрыть."
        sleep 2
    else
        rm -f "$META/$unit"
        echo "  ❌ Не удалось запустить через systemd-run --user"
        read -r -n1 -p "Enter…"; exit 1
    fi
}

cmd_foreground() {
    local input=${1:-} secs end left
    [[ -z $input ]] && input=$(ask_time)
    secs=$(parse "$input") || { echo "Не понял «$input»."; read -r -n1 -p "Enter…"; exit 1; }
    (( secs > 0 )) || exit 0
    trap 'printf "\n\nОтменено.\n"; exit 0' INT TERM
    printf '\033[?25l'; trap 'printf "\033[?25h"' EXIT
    end=$(( $(date +%s) + secs ))
    while :; do
        left=$(( end - $(date +%s) )); (( left <= 0 )) && break
        printf '\r\033[K  ⏱  %s   (Ctrl+C — отмена)' "$(fmt "$left")"; sleep 0.2
    done
    printf '\r\033[K  ⏰  Время вышло!\n'
    alarm "Прошло $(fmt "$secs")"
    read -r -n1 -p "  Enter — закрыть "
}

cmd_ls() {
    local u n=0 now left
    now=$(date +%s)
    for u in $(active_units); do
        u=${u%.timer}
        [[ -f $META/$u ]] || continue
        left=$(( $(<"$META/$u") - now )); (( left < 0 )) && left=0
        printf '  %-28s осталось %s\n' "$u" "$(fmt "$left")"; n=$((n+1))
    done
    (( n == 0 )) && echo "  Активных таймеров нет."
    return 0
}

cmd_cancel() {
    local units=() u pick now left lines=()
    now=$(date +%s)
    for u in $(active_units); do u=${u%.timer}; [[ -f $META/$u ]] && units+=("$u"); done
    if (( ${#units[@]} == 0 )); then echo "  Активных таймеров нет."; sleep 1.5; return; fi
    if [[ ${1:-} == all ]]; then pick=all
    else
        for u in "${units[@]}"; do left=$(( $(<"$META/$u") - now )); lines+=("$u  (осталось $(fmt $(( left>0?left:0 ))))"); done
        if command -v gum >/dev/null; then pick=$(printf '%s\n' "${lines[@]}" "all  (отменить все)" | gum choose --header "Какой таймер отменить?") || return
        else printf '%s\n' "${lines[@]}"; read -r -p "Имя таймера (или all): " pick; fi
        pick=${pick%% *}
    fi
    for u in "${units[@]}"; do
        if [[ $pick == all || $pick == "$u" ]]; then
            systemctl --user stop "$u.timer" "$u.service" 2>/dev/null; rm -f "$META/$u"; echo "  Отменён: $u"
        fi
    done
    sleep 1
}

case ${1:-} in
    _fire)  alarm "Прошло $2"; rm -f "$META/$3" ;;     # вызывается systemd по окончании
    ls)     cmd_ls ;;
    cancel) cmd_cancel "${2:-}" ;;
    -f)     cmd_foreground "${2:-}" ;;
    *)      cmd_start "${1:-}" ;;
esac
