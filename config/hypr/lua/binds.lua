local mainMod = "SUPER"
local terminal = "kitty"
local fileManager = "thunar"
local menu = "rofi -show drun -modi \"drun,run,emoji,settings:~/.config/rofi/settings-mode.sh\" -theme ~/.config/rofi/theme.rasi"

-- Приложения
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + b", hl.dsp.exec_cmd("kitty --title btop -e btop"))

-- Скриншоты
hl.bind("ALT + K", hl.dsp.exec_cmd("hyprshot -m region -o ~/data/media/screenshots"))
hl.bind("ALT + J", hl.dsp.exec_cmd("hyprshot -m output -o ~/data/media/screenshots"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("hyprshot -m window"))

-- OBS через obs-cmd (самый надёжный способ)
-- OBS через xdotool (выбираем первое окно из списка)
-- OBS через send_shortcut (официальный способ)
hl.bind("ALT + 1", hl.dsp.send_shortcut({ mods = "CTRL", key = "F10", window = "class:^(com\\.obsproject\\.Studio)$" }))
hl.bind("ALT + 2", hl.dsp.send_shortcut({ mods = "CTRL", key = "F11", window = "class:^(com\\.obsproject\\.Studio)$" }))
-- Управление окнами
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + S", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("wlogout"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("waypaper"))

-- Навигация
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Перемещение окон
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

-- Изменение размера
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0, y = 100, relative = true }))

-- Макеты
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("hyprctl keyword general:layout dwindle"))
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("hyprctl keyword general:layout master"))

-- Рабочие столы
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Навигация по столам
hl.bind(mainMod .. " + TAB", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.focus({ workspace = "m-1" }))

-- Выход
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("notify-send \"Выход\" \"Нажми SUPER+SHIFT+Q для выхода\""))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit())

-- Громкость
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
