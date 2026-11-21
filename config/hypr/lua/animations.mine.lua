-- ============================================================
-- ANIMATIONS
-- ============================================================

-- Кастомные кривые из конфига знакомого
hl.curve("hybridSpring", {
    type = "spring",
    mass = 1,
    stiffness = 240,
    damping = 24
})

hl.curve("hybridEase", {
    type = "bezier",
    points = {
        {0.22, 1.0},
        {0.36, 1.0}
    }
})

hl.curve("hybridFast", {
    type = "bezier",
    points = {
        {0.3, 0.0},
        {0.2, 1.0}
    }
})

-- Анимации из конфига знакомого
hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 2.2,
    spring = "hybridSpring",
    style = "popin 92%"
})

hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 2.0,
    spring = "hybridSpring",
    style = "popin 92%"
})

hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 1.5,
    bezier = "hybridEase",
    style = "popin 96%"
})

hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 2.4,
    spring = "hybridSpring"
})

hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 1.8,
    bezier = "hybridEase"
})

hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 1.4,
    bezier = "hybridFast"
})

hl.animation({
    leaf = "fadeSwitch",
    enabled = true,
    speed = 1.5,
    bezier = "hybridEase"
})

hl.animation({
    leaf = "fadeDim",
    enabled = true,
    speed = 1.8,
    bezier = "hybridEase"
})

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 4,
    bezier = "hybridEase",
    style = "slidefade 20%"
})

hl.animation({
    leaf = "specialWorkspace",
    enabled = true,
    speed = 2.2,
    bezier = "hybridEase",
    style = "slidefade"
})

hl.animation({
    leaf = "border",
    enabled = true,
    speed = 2.5,
    bezier = "hybridEase"
})

-- hl.config({
--     misc = { animate_manual_resizes = true },
--     dwindle = { preserve_split = true },
-- })

hl.config({
    general = {
        layout = "scrolling",
    },
    misc = { animate_manual_resizes = true },
    dwindle = { preserve_split = true },
    scrolling = {
        column_width = 0.5,              -- ширина колонки (0.5 = половина экрана)
        fullscreen_on_one_column = true, -- не разворачивать одно окно на весь экран
        focus_fit_method = 1,            -- 1 = вписывать активное окно в экран
        follow_focus = true,
        direction = "right"             -- прокручивать ленту при смене фокуса
    },
})
