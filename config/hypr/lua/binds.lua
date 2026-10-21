local mainMod = "SUPER"
local terminal = "kitty"
local fileManager = "thunar"

-- ============================================================
-- ПРИЛОЖЕНИЯ
-- ============================================================
-- Лаунчер (замена rofi)
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))

-- Экран блокировки (замена hyprlock)
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("noctalia msg session lock"))

-- Меню питания (замена wlogout)
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("noctalia msg panel-toggle session"))

-- Панель управления (новая)
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"))

-- Настройки Noctalia
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("noctalia msg settings-toggle"))

-- Буфер обмена
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"))

-- Выбор обоев
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("noctalia msg panel-toggle wallpaper"))

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
-- hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + b", hl.dsp.exec_cmd("kitty --title btop -e btop"))

-- ============================================================
-- СКРИНШОТЫ
-- ============================================================

hl.bind("ALT + K", hl.dsp.exec_cmd("hyprshot -m region -o ~/data/media/screenshots"))
hl.bind("ALT + J", hl.dsp.exec_cmd("hyprshot -m output -o ~/data/media/screenshots"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("hyprshot -m window"))

-- ============================================================
-- OBS
-- ============================================================
-- ============================================================
-- OBS(не менять)
-- ============================================================

hl.bind("ALT + 1", hl.dsp.send_shortcut({ mods = "CTRL", key = "F10", window = "class:^(com\\.obsproject\\.Studio)$" }))
hl.bind("ALT + 2", hl.dsp.send_shortcut({ mods = "CTRL", key = "F11", window = "class:^(com\\.obsproject\\.Studio)$" }))
-- ============================================================
-- УПРАВЛЕНИЕ ОКНАМИ
-- ============================================================

hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + S", hl.dsp.window.float({ action = "toggle" }))
-- hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
-- hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("wlogout"))
-- hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("waypaper"))

-- ============================================================
-- НАВИГАЦИЯ (scrolling layout)
-- ============================================================

hl.bind(mainMod .. " + left",  hl.dsp.layout("focus l"))
hl.bind(mainMod .. " + right", hl.dsp.layout("focus r"))
hl.bind(mainMod .. " + up",    hl.dsp.layout("focus u"))
hl.bind(mainMod .. " + down",  hl.dsp.layout("focus d"))

-- ============================================================
-- ПЕРЕМЕЩЕНИЕ ОКОН МЕЖДУ КОЛОНКАМИ (scrolling layout)
-- ============================================================

-- В scrolling нет movewindow — только move ±col
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.layout("move -col"))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.layout("move +col"))

-- Дублирующие бинды на period/comma — оставь, если удобно
hl.bind(mainMod .. " + period", hl.dsp.layout("move +col"))
hl.bind(mainMod .. " + comma",  hl.dsp.layout("move -col"))

-- ============================================================
-- SCROLLING LAYOUT
-- ============================================================

-- Смена колонок местами
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.layout("swapcol r"))
hl.bind(mainMod .. " + SHIFT + comma",  hl.dsp.layout("swapcol l"))

-- Изменение ширины колонки
hl.bind(mainMod .. " + equal", hl.dsp.layout("colresize +0.05"))
hl.bind(mainMod .. " + minus", hl.dsp.layout("colresize -0.05"))

-- Сброс ширины колонки к 0.5
hl.bind(mainMod .. " + SHIFT + minus", hl.dsp.layout("colresize 0.5"))

-- Вписать активное окно в экран
hl.bind(mainMod .. " + Space", hl.dsp.layout("fit active"))

-- Сброс ширины активной колонки
hl.bind(mainMod .. " + SHIFT + Space", hl.dsp.layout("colresize 0.5"))

-- ============================================================
-- РАЗМЕР ОКОН (для плавающих / ручной resize с зажатием)
-- ============================================================

hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })
-- ============================================================
-- МАКЕТЫ
-- ============================================================

-- В scrolling нет togglesplit — убрано
-- hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit"))

-- Возврат к scrolling (если случайно переключился)
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("hyprctl eval 'hl.config({ general = { layout = \"scrolling\" } })'"))

-- ============================================================
-- РАБОЧИЕ СТОЛЫ
-- ============================================================

for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Навигация по столам (e+1 / e-1 — на текущем мониторе)
hl.bind(mainMod .. " + TAB", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }))

-- ============================================================
-- ALT+TAB — переключение окон
-- ============================================================

-- ALT+TAB — переключение окон (через Noctalia)
hl.bind("ALT + code:23", hl.dsp.exec_cmd("noctalia msg window-switcher hold"))
hl.bind("ALT + SHIFT + code:23", hl.dsp.exec_cmd("noctalia msg window-switcher hold"))
-- ============================================================
-- ВЫХОД
-- ============================================================

hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("notify-send \"Выход\" \"Нажми SUPER+SHIFT+Q для выхода\""))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit())

-- ============================================================
-- ГРОМКОСТЬ
-- ============================================================

-- hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
-- hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
-- hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("noctalia msg volume-mute"), { locked = true })
-- ============================================================
-- ПРОЧЕЕ
-- ============================================================

-- Открыть расписание в LibreOffice
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("libreoffice /home/zento/data/docs/расписание.xlsx"))

-- Свободный (плавающий) терминал
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd("kitty --class kitty-float"))


-- ============================================================
-- ПЕРЕМЕЩЕНИЕ ПЛАВАЮЩИХ ОКОН (с зажатием)
-- ============================================================

hl.bind(mainMod .. " + ALT + left",  hl.dsp.window.move({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.move({ x = 20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + up",    hl.dsp.window.move({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + down",  hl.dsp.window.move({ x = 0, y = 20, relative = true }), { repeating = true })
