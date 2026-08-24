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
