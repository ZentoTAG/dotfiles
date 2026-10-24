hl.on("hyprland.start", function()
    -- hl.exec_cmd("hyprlock")           -- Noctalia имеет свой локскрин
    -- hl.exec_cmd("hypridle")           -- у Noctalia свой idle-сервис
    -- hl.exec_cmd("awww-daemon &")      -- Noctalia сама управляет обоями
    hl.exec_cmd("noctalia")

    hl.exec_cmd("[workspace 9 silent] /home/zento/data/tools/v2rayN-linux-64/v2rayN")
    -- hl.exec_cmd("sleep 2 && /home/zento/data/dotfiles/scripts/apply_wallpaper.sh")
    -- hl.exec_cmd("justrayd")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    -- hl.exec_cmd("swaync")             -- Noctalia имеет свой центр уведомлений
    -- hl.exec_cmd("waybar")             -- Noctalia имеет свою панель
    hl.exec_cmd("udiskie")
    hl.exec_cmd("[workspace 1 silent] sleep 2 && zen-browser")
    hl.exec_cmd("[workspace 2 silent] sh -c \"sleep 3 && AyuGram\"")
end)
