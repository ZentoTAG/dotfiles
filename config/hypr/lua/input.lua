hl.config({
    input = {
        kb_layout = "us,ru",
        kb_options = "grp:alt_shift_toggle",
        repeat_rate = 50,
        repeat_delay = 200,
        sensitivity = 0.0,
        accel_profile = "flat",
        touchpad = { natural_scroll = false },
    },
})

local mainMod = "SUPER"
-- hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
-- hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Двигать с SUPER
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

touchpad = {
    natural_scroll = true,        -- естественная прокрутка
    disable_while_typing = true,  -- отключать тачпад при печати
    clickfinger_behavior = true,  -- 2 пальца = ПКМ, 3 = СКМ
    scroll_factor = 0.5,          -- скорость прокрутки
}

hl.device({
    name = "synps/2-synaptics-touchpad",
    sensitivity = 0.5, -- от -1.0 до 1.0 (0.0 — по умолчанию)
    -- другие настройки тачпада можно перенести сюда:
    natural_scroll = true,
    disable_while_typing = true,
    clickfinger_behavior = true,
    scroll_factor = 0.5,
})
