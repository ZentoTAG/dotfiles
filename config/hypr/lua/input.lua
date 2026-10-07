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

hl.device({
    name = "pnp0c50:00-0911:5288-1",
    sensitivity = 1.0,           -- попробуй 0.3–0.7 для начала
    natural_scroll = true,
    disable_while_typing = true,
    clickfinger_behavior = false,
    scroll_factor = 0.5,
})
