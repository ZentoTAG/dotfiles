#!/usr/bin/env bash
set -euo pipefail

# hyprpm работает только внутри запущенной сессии Hyprland
if ! hyprctl version >/dev/null 2>&1; then
    echo "Hyprland не запущен: запусти этот скрипт из сессии Hyprland"
    exit 0
fi

hyprpm update

if ! hyprpm list | grep -q scrolloverview; then
    hyprpm add https://github.com/yayuuu/hyprland-scroll-overview.git
fi

hyprpm enable scrolloverview
