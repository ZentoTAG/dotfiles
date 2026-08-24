#!/bin/bash

# ============================================================
# СОЗДАНИЕ ПУСТОЙ СТРУКТУРЫ ~/data (ТОЛЬКО ПАПКИ)
# ============================================================

echo "📁 Создаю пустую структуру ~/data..."

# ============================================================
# ОСНОВНЫЕ ПАПКИ
# ============================================================
mkdir -p ~/data/desktop
mkdir -p ~/data/dev/{LABS_PSTU,projects,scripts}
mkdir -p ~/data/docs/{guides,obsidian,studying/project,task}
mkdir -p ~/data/dotfiles/{assets/backgrounds,config,scripts,docs}
mkdir -p ~/data/downloads
mkdir -p ~/data/games
mkdir -p ~/data/media/{music,pictures,screenshots,videos,wallpapers}
mkdir -p ~/data/tools
mkdir -p ~/data/external

# ============================================================
# ПОДПАПКИ ВНУТРИ dotfiles/config
# ============================================================
mkdir -p ~/data/dotfiles/config/{btop,cava,dunst,fastfetch,fish,gtk-3.0,gtk-4.0,hypr,kitty,micro,nvim,qt6ct,rofi,swaync,Thunar,waybar,waypaper,yazi}

# ============================================================
# ПОДПАПКИ ВНУТРИ media
# ============================================================
mkdir -p ~/data/media/pictures/{genshin,anime,class}
mkdir -p ~/data/media/wallpapers/video

# ============================================================
# ПОДПАПКИ ВНУТРИ tools (пустые, для программ)
# ============================================================
mkdir -p ~/data/tools/{v2rayN-linux-64,PortProton,PrismLauncher,DankMaterialShell,end-4-dots,framework-dotfiles,balenaEtcher,Discord,osu.AppImage,LunarClient,LabyModLauncher,drawio,xmcl}

# ============================================================
# ПОДПАПКИ ВНУТРИ external (пустые, для сторонних проектов)
# ============================================================
mkdir -p ~/data/external/{caelestia,lol,monasm-dots,zenith-shell}

# ============================================================
# ГОТОВО!
# ============================================================
echo ""
echo "✅ Пустая структура ~/data создана!"
echo ""
echo "📁 Созданы все папки:"
echo "  ~/data/desktop/"
echo "  ~/data/dev/"
echo "  ~/data/docs/"
echo "  ~/data/dotfiles/"
echo "  ~/data/downloads/"
echo "  ~/data/games/"
echo "  ~/data/media/"
echo "  ~/data/tools/        ← сюда поставишь программы"
echo "  ~/data/external/     ← сюда скачаешь проекты"
echo ""
echo "🎯 Все папки пустые, содержимое добавляй сам."
