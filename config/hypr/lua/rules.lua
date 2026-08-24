-- ============================================================
-- WINDOW RULES
-- ============================================================

hl.window_rule({
    name = "v2rayN-workspace",
    match = { class = ".*v2rayN.*" },
    workspace = 9,
    no_initial_focus = true,
})

hl.window_rule({
    name = "steam-workspace",
    match = { class = ".*[sS]team.*" },
    workspace = 3,
    no_initial_focus = true,
})

hl.window_rule({
    name = "steam-app-workspace",
    match = { class = ".*steam_app_3143298597.*" },
    workspace = 4,
    no_initial_focus = true,
})

hl.window_rule({
    name = "genshin-workspace",
    match = { title = ".*Genshin Impact.*" },
    workspace = 4,
    no_initial_focus = true,
})

hl.window_rule({
    name = "hoyoplay-workspace",
    match = { title = ".*HoYoPlay.*" },
    workspace = 4,
    no_initial_focus = true,
})

hl.window_rule({
    name = "waypaper-float",
    match = { class = "waypaper" },
    float = true,
    center = true,
})
