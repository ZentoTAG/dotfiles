# # ~/.bash_profile — логин-шелл: автозапуск Hyprland на tty1
# [[ -f ~/.bashrc ]] && source ~/.bashrc
# 
# if [[ -z $WAYLAND_DISPLAY && $(tty) == /dev/tty1 ]]; then
#     sleep 2
#     exec start-hyprland
# fi
