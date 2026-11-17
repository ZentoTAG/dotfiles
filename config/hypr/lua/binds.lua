local mainMod = "SUPER"
local terminal = "kitty --directory " .. os.getenv("HOME")
local fileManager = "thunar"
local home = os.getenv("HOME")

-- ============================================================
-- ПРИЛОЖЕНИЯ
-- ============================================================
-- Лаунчер (замена rofi)
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))

-- hl.bind(mainMod .. " + ALT + I", hl.dsp.exec_cmd(
--     [[hyprctl activewindow -j | jq -r '"hl.window_rule({\n    name = \"float-" + (.class|ascii_downcase) + "\",\n    match = { class = \"" + .class + "\" },\n    float = true,\n    center = true,\n})"' | wl-copy && notify-send "Hyprland" "Правило по class скопировано"]]
-- ))

hl.bind("ALT + 4", hl.dsp.send_shortcut({ mods = "CTRL", key = "F2", window = "class:^(com\\.obsproject\\.Studio)$" }))
hl.bind("ALT + 3", hl.dsp.send_shortcut({ mods = "CTRL", key = "F1", window = "class:^(com\\.obsproject\\.Studio)$" }))


hl.bind(mainMod .. " + ALT + T", hl.dsp.exec_cmd("kitty --class kitty-float --directory " .. os.getenv("HOME") .. " -e /home/zento/data/dotfiles/scripts/timer.sh"))

-- Путь к скрипту
local timer = "/home/zento/data/dotfiles/scripts/timer.sh"

-- Показать список активных таймеров (ждет нажатия клавиши перед закрытием)
hl.bind(mainMod .. " + ALT + Y", hl.dsp.exec_cmd(
    "kitty --class kitty-float -e sh -c '" .. timer .. " ls; echo; read -n 1 -s -r -p \"Нажми любую клавишу для выхода...\"'"
))

-- Отмена таймера на SUPER + ALT + C (Cancel)
hl.bind(mainMod .. " + ALT + C", hl.dsp.exec_cmd(
    "kitty --class kitty-float -e sh -c '" .. timer .. " cancel; echo; read -n 1 -s -r -p \"Нажми любую клавишу для выхода...\"'"
))

-- hl.bind("ALT + 4", hl.dsp.exec_cmd("pkill -USR1 -f gpu-screen-recorder")) 
-- hl.bind(mainMod .. " + ALT + S", hl.dsp.exec_cmd("pkill -INT -f gpu-screen-recorder"))
local winrule = home .. "/data/dotfiles/scripts/winrule.sh"
-- hl.bind(mainMod .. " + ALT + O", hl.dsp.exec_cmd(winrule .. " stage title"))  -- правило по классу + заголовку
hl.bind(mainMod .. " + ALT + W", hl.dsp.exec_cmd("hyprwrc"))
hl.bind(mainMod .. " + ALT + I", hl.dsp.exec_cmd(winrule .. " stage class"))  -- правило по классу
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd(winrule .. " apply"))        -- дописать в rules.lua
hl.bind(mainMod .. " + ALT + U", hl.dsp.exec_cmd(winrule .. " undo"))         -- убрать последнее
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
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(fileManager .. " --title=\"Floating Thunar\""))

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
-- НАВИГАЦИЯ И ПЕРЕМЕЩЕНИЕ ОКОН
-- ============================================================

local function layout_bind(dispatchers)
    return function()
        local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
        local dispatcher = workspace and dispatchers[workspace.tiled_layout]
        if dispatcher then hl.dispatch(dispatcher) end
    end
end

for key, direction in pairs({ left = "l", right = "r", up = "u", down = "d" }) do
    hl.bind(mainMod .. " + " .. key, layout_bind({
        scrolling = hl.dsp.layout("focus " .. direction),
        dwindle = hl.dsp.focus({ direction = direction }),
    }))

    local move = { dwindle = hl.dsp.window.move({ direction = direction }) }
    if key == "left" then move.scrolling = hl.dsp.layout("move -col") end
    if key == "right" then move.scrolling = hl.dsp.layout("move +col") end
    hl.bind(mainMod .. " + SHIFT + " .. key, layout_bind(move))
end

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

-- Переключение фокуса между плавающим и тайлинговым окном
hl.bind(mainMod .. " + ALT + Space", function()
    local window = hl.get_active_window()
    if not window then return end
    hl.dispatch(hl.dsp.window.cycle_next({
        floating = not window.floating,
        tiled = window.floating,
    }))
end)

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

-- Изменить направление разделения в dwindle
hl.bind(mainMod .. " + T", layout_bind({ dwindle = hl.dsp.layout("togglesplit") }))

-- Переключить раскладку текущего рабочего стола
hl.bind(mainMod .. " + G", function()
    local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
    if not workspace then return end

    local layout = workspace.tiled_layout == "dwindle" and "scrolling" or "dwindle"
    -- Для обычных рабочих столов числовой id надёжнее, чем селектор name:.
    local selector = workspace.special and tostring(workspace.name) or tostring(workspace.id)
    hl.workspace_rule({ workspace = selector, layout = layout })
end)

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

-- -- ALT+TAB — переключение окон (через Noctalia)
-- hl.bind("ALT + code:23", hl.dsp.exec_cmd("noctalia msg window-switcher hold"))
-- hl.bind("ALT + SHIFT + code:23", hl.dsp.exec_cmd("noctalia msg window-switcher hold"))
-- ALT+TAB — вызов оверлея Noctalia (без hold, чтобы открывался сразу)
hl.bind("ALT + code:23", hl.dsp.exec_cmd("noctalia msg window-switcher"))

-- ALT+SHIFT+TAB — назад (Noctalia сам понимает Shift внутри оверлея)
-- hl.bind("ALT + SHIFT + code:23", hl.dsp.exec_cmd("noctalia msg window-switcher"))
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
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("libreoffice " .. home .. "/data/docs/расписание.xlsx"))

-- Свободный (плавающий) терминал
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd("kitty --class kitty-float"))


-- ============================================================
-- ПЕРЕМЕЩЕНИЕ ПЛАВАЮЩИХ ОКОН И УПРАВЛЕНИЕ КОЛОНКАМИ
-- ============================================================

for key, move in pairs({
    left = { x = -20, y = 0, relative = true },
    right = { x = 20, y = 0, relative = true },
    up = { x = 0, y = -20, relative = true },
    down = { x = 0, y = 20, relative = true },
}) do
    local keys = mainMod .. " + ALT + " .. key

    -- Повторение при удержании только для плавающих окон.
    hl.bind(keys, function()
        local window = hl.get_active_window()
        if window and window.floating then hl.dispatch(hl.dsp.window.move(move)) end
    end, { repeating = true })

    -- Одно действие на нажатие: повторение меняло бы колонку туда и обратно.
    hl.bind(keys, function()
        local window = hl.get_active_window()
        local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
        if not window or window.floating or not workspace or workspace.tiled_layout ~= "scrolling" then return end

        if key == "left" or key == "right" then
            local side = key == "left" and "prev" or "next"
            hl.dispatch(hl.dsp.layout("consume_or_expel " .. side))
        else
            local direction = key == "up" and "u" or "d"
            hl.dispatch(hl.dsp.window.move({ direction = direction }))
        end
    end)
end

-- Вынести активное окно в отдельную колонку
hl.bind(mainMod .. " + ALT + Return", function()
    local window = hl.get_active_window()
    local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
    if window and not window.floating and workspace and workspace.tiled_layout == "scrolling" then
        hl.dispatch(hl.dsp.layout("expel"))
    end
end)
