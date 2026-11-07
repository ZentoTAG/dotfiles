#!/usr/bin/env bash
# winrule.sh — правила float для окон Hyprland в три шага
#
#   winrule.sh stage [title|class]  — сформировать правило для окна под курсором
#                                     (или активного) и положить во временный файл
#   winrule.sh apply                — дописать подготовленное правило в конец rules.lua
#   winrule.sh undo                 — удалить из rules.lua последнее добавленное правило
#                                     (можно жать несколько раз — снимает по одному)
#
#   title — класс + начальный заголовок (диалоги), заменяемые части станут .*
#   class — все окна приложения
#
# Правила, добавленные скриптом, обёрнуты в маркеры «-- winrule:begin/end»,
# поэтому undo никогда не трогает правила, написанные руками.
#
# Зависимости: hyprctl, jq, libnotify
set -euo pipefail

RULES_FILE=${WINRULE_FILE:-$HOME/.config/hypr/lua/rules.lua}
PENDING=${XDG_RUNTIME_DIR:-/tmp}/winrule.pending
BACKUP_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/winrule

notify() { notify-send -a winrule "Hyprland" "$1" || true; }
die()    { notify "❌ $1"; echo "$1" >&2; exit 1; }
reload() { hyprctl reload >/dev/null 2>&1 || true; }

backup() {
    mkdir -p "$BACKUP_DIR"
    cp -- "$RULES_FILE" "$BACKUP_DIR/rules.lua.bak"
}

# --- 2. Экранирование -----------------------------------------------------
re_escape()  { printf '%s' "$1" | sed -E 's/[][\\.^$*+?(){}|]/\\&/g'; }     # regex (RE2)
lua_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }    # строка Lua
slug()       { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed -E 's/-+/-/g; s/^-|-$//g' | cut -c1-30; }

# Заголовок -> regex: меняющиеся части (имена файлов, пути, числа, всё в кавычках)
# заменяются на .*, постоянный текст остаётся. Результат: GEN_RE и GEN_TEXT.
generalize() {
    local sep=$'\x1f' s p pieces=() start=0 end=0
    s=$(printf '%s' "$1" | LC_ALL=C.UTF-8 sed -E "
        s/\"[^\"]*\"/$sep/g
        s/«[^»]*»/$sep/g
        s/“[^”]*”/$sep/g
        s/[^[:space:]]*\/[^[:space:]]*/$sep/g
        s/[^[:space:]]*[0-9][^[:space:]]*/$sep/g
        s/[^[:space:]]+\.[[:alnum:]]{1,5}([[:space:]]|\$)/$sep\1/g
        s/$sep([[:space:]]*$sep)+/$sep/g")
    [[ $s == "$sep"* ]] && start=1
    [[ $s == *"$sep" ]] && end=1
    local IFS=$sep
    read -ra pieces <<<"$s"
    local re="" text="" first=1
    for p in "${pieces[@]}"; do
        p=${p#"${p%%[![:space:]]*}"}; p=${p%"${p##*[![:space:]]}"}   # trim
        [[ -z $p ]] && continue
        (( first )) || re+=".*"
        first=0
        re+=$(re_escape "$p"); text+="$p "
    done
    GEN_TEXT=${text% }
    if [[ -z $re ]]; then GEN_RE=""; return; fi
    GEN_RE="^"; (( start )) && GEN_RE+=".*"
    GEN_RE+="$re"; (( end )) && GEN_RE+=".*"
    GEN_RE+="\$"
}


# =====================================================================
#  stage — подготовить правило
# =====================================================================
cmd_stage() {
    local mode=${1:-title}

    # --- окно под курсором -----------------------------------------
    local cur cx cy active_ws win
    cur=$(hyprctl cursorpos -j)
    cx=$(jq -r '.x' <<<"$cur")
    cy=$(jq -r '.y' <<<"$cur")
    active_ws=$(hyprctl monitors -j | jq -c '[.[].activeWorkspace.id]')

    win=$(hyprctl clients -j | jq -c --argjson x "$cx" --argjson y "$cy" --argjson ws "$active_ws" '
        [ .[] | select(
            .mapped and (.hidden | not)
            and (.workspace.id as $w | $ws | index($w))
            and .at[0] <= $x and $x < (.at[0] + .size[0])
            and .at[1] <= $y and $y < (.at[1] + .size[1])
        ) ]
        | sort_by([(.floating | not), .focusHistoryID])
        | .[0] // empty')

    [[ -n $win ]] || win=$(hyprctl activewindow -j)
    [[ -n $win && $win != "{}" ]] || die "Окно не найдено"

    local class ititle
    class=$(jq -r '.class' <<<"$win")
    ititle=$(jq -r '.initialTitle' <<<"$win")
    [[ -n $class ]] || die "У окна нет class"

    # --- правило ---------------------------------------------------
    local class_pat name match comment t title_pat
    class_pat=$(lua_escape "^($(re_escape "$class"))\$")
    name="float-$(slug "$class")"

    generalize "$ititle"
    if [[ $mode == title && -n $GEN_RE ]]; then
        title_pat=$(lua_escape "$GEN_RE")
        t=$(slug "$GEN_TEXT"); [[ -n $t ]] && name+="-$t"
        match="{ class = \"$class_pat\", initial_title = \"$title_pat\" }"
        comment="-- заголовок: «$ititle»"
    else
        match="{ class = \"$class_pat\" }"
        comment="-- class: $class"
    fi

    if [[ -f $RULES_FILE ]] && grep -qF "name = \"$name\"" "$RULES_FILE"; then
        die "Правило $name уже есть в rules.lua"
    fi

    cat > "$PENDING" <<LUA
-- winrule:begin $name
$comment
hl.window_rule({
    name = "$name",
    match = $match,
    float = true,
    center = true,
})
-- winrule:end $name
LUA

    notify "📝 Подготовлено: $name  (применить — apply)"
    cat "$PENDING"
}

# =====================================================================
#  apply — дописать в rules.lua
# =====================================================================
cmd_apply() {
    [[ -s $PENDING ]] || die "Нет подготовленного правила — сначала stage"
    [[ -w $RULES_FILE ]] || die "Нет доступа к $RULES_FILE"

    local name
    name=$(sed -n '1s/^-- winrule:begin //p' "$PENDING")
    if grep -qF "name = \"$name\"" "$RULES_FILE"; then
        rm -f -- "$PENDING"
        die "Правило $name уже есть в rules.lua"
    fi

    backup
    { printf '\n'; cat "$PENDING"; } >> "$RULES_FILE"
    rm -f -- "$PENDING"
    reload
    notify "✅ Добавлено в rules.lua: $name"
}

# =====================================================================
#  undo — убрать последнее добавленное скриптом правило
# =====================================================================
cmd_undo() {
    [[ -w $RULES_FILE ]] || die "Нет доступа к $RULES_FILE"

    local first last start name tmp
    first=$(grep -n '^-- winrule:begin ' "$RULES_FILE" | tail -1 | cut -d: -f1 || true)
    [[ -n $first ]] || die "В rules.lua нет правил, добавленных winrule"

    last=$(awk -v s="$first" 'NR > s && /^-- winrule:end / { print NR; exit }' "$RULES_FILE")
    [[ -n $last ]] || die "Не найден конец правила (маркер winrule:end)"

    name=$(sed -n "${first}s/^-- winrule:begin //p" "$RULES_FILE")

    # заодно убираем пустую строку перед блоком
    start=$first
    if (( first > 1 )) && [[ -z $(sed -n "$((first - 1))p" "$RULES_FILE") ]]; then
        start=$((first - 1))
    fi

    backup
    tmp=$(mktemp)
    sed "${start},${last}d" "$RULES_FILE" > "$tmp"
    cat "$tmp" > "$RULES_FILE"      # пишем «сквозь» симлинк, не заменяя его
    rm -f -- "$tmp"
    reload
    notify "↩️ Удалено из rules.lua: $name"
}

# =====================================================================
case ${1:-} in
    stage) shift; cmd_stage "$@" ;;
    apply) cmd_apply ;;
    undo)  cmd_undo ;;
    *)     sed -n '2,15p' "$0"; exit 1 ;;
esac
