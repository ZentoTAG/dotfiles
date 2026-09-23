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

-- Правило для слоя выделения (отключает анимации)
hl.layer_rule({
    match = { namespace = "selection" },
    no_anim = true,
})

-- ============================================================
-- WINAPPS FIX
-- ============================================================

hl.window_rule({
    name = "winapps-microsoft",
    match = {
        class = ".*Microsoft.*",
    },
    float = true,
    no_anim = true,
})

hl.window_rule({
    name = "winapps-suppress-maximize",
    match = {
        class = ".*Microsoft.*",
    },
    suppress_event = "maximize",
})

-- ============================================================
-- ИГРОВЫЕ ПРАВИЛА (максимальная производительность)
-- ============================================================

-- Все игровые окна (Steam, Proton, Wine)
-- Убираем анимации, границы и скругление
hl.window_rule({
    name = "game-optimization",
    match = {
        class = ".*steam_app_.*",
    },
    no_anim = true,
    border_size = 0,
    rounding = 0,
})

-- Proton игры
hl.window_rule({
    name = "game-proton-optimization",
    match = {
        class = ".*proton.*",
    },
    no_anim = true,
    border_size = 0,
    rounding = 0,
})

-- Wine игры
hl.window_rule({
    name = "game-wine-optimization",
    match = {
        class = ".*wine.*",
    },
    no_anim = true,
    border_size = 0,
    rounding = 0,
})

-- Genshin Impact (особое правило)
hl.window_rule({
    name = "genshin-performance",
    match = {
        title = ".*Genshin Impact.*",
    },
    no_anim = true,
    border_size = 0,
    rounding = 0,
    fullscreen = true,
})
