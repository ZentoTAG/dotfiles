source /usr/share/cachyos-fish-config/cachyos-config.fish

function fish_greeting
end

# ============================================
# АВТОЗАПУСК HYPRLAND
# ============================================
if status is-login && test -z "$WAYLAND_DISPLAY" && test (tty) = /dev/tty1
    sleep 2
    exec start-hyprland
end

source ~/.config/fish/functions/copy.fish

# ============================================
# ПЕРЕОПРЕДЕЛЕНИЕ СИСТЕМНОГО ALIAS cleanup
# ============================================
# /usr/share/cachyos-fish-config/cachyos-config.fish (строка 117) создаёт
#   alias cleanup='sudo pacman -Rns (pacman -Qtdq)'
# который перекрывает нашу функцию cleanup. Удаляем алиас и загружаем функцию.
functions -e cleanup 2>/dev/null
source ~/.config/fish/functions/cleanup.fish
