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

hl.device({
    name = "pnp0c50:00-0911:5288-1",
    sensitivity = 1.0,
})

local mainMod = "SUPER"
-- hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
-- hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Двигать с SUPER
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
