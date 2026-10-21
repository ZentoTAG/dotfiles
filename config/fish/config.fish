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
