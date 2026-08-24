# #!/bin/bash
# echo "Получено: $1" >> /tmp/waybar_debug.log
# hyprctl dispatch "hl.dsp.focus({ workspace = $1 })" >> /tmp/waybar_debug.log 2>&1

#!/bin/bash
hyprctl dispatch "hl.dsp.focus({ workspace = $1 })"
