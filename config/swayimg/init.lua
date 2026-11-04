-- ============================================================
-- Swayimg — лёгкий просмотрщик изображений для Wayland/Hyprland
-- Цвета подогнаны под текущую тему Noctalia
-- ============================================================

local bg         = 0xff1c1015 -- фон Noctalia
local surface    = 0xff291c21 -- поверхность
local surface_hi = 0xff3a2730 -- поверхность под курсором
local fg         = 0xfff5dce4 -- основной текст
local accent     = 0xffffafd0 -- акцент Noctalia
local shadow     = 0x99000000

-- ------------------------------------------------------------
-- Общие настройки
-- ------------------------------------------------------------
swayimg.appid = "swayimg"
swayimg.mode = "viewer"
swayimg.antialiasing = true
swayimg.decoration = false        -- без клиентского заголовка, рамку рисует Hyprland
swayimg.overlay = false
swayimg.exif_orientation = true

-- Видео в swayimg не декодируем: раскадровка подвешивает листание.
-- Видеофайлы из Thunar открываются в mpv (там же и настройки).
swayimg.format_conf = {
    video = {
        enable = false,
    },
}

-- ------------------------------------------------------------
-- Список изображений
-- ------------------------------------------------------------
swayimg.imagelist.order = "numeric"
swayimg.imagelist.reverse = false
swayimg.imagelist.recursive = false
swayimg.imagelist.adjacent = true -- открыл одну картинку — листаешь всю папку
swayimg.imagelist.fsmon = true

-- ------------------------------------------------------------
-- Информационный оверлей
-- ------------------------------------------------------------
swayimg.text.visible = true
swayimg.text.font = "JetBrains Mono Nerd Font"
swayimg.text.size = 18
swayimg.text.spacing = 2
swayimg.text.padding = 18
swayimg.text.color = fg
swayimg.text.background = 0xcc1c1015
swayimg.text.shadow = shadow
swayimg.text.timeout = 3
swayimg.text.status_timeout = 2

-- ------------------------------------------------------------
-- Режим просмотра
-- ------------------------------------------------------------
swayimg.viewer.default_scale = "optimal"
swayimg.viewer.default_position = "center"
swayimg.viewer.drag_button = "MouseLeft"
swayimg.viewer.autopos = "center"
swayimg.viewer.loop = true
swayimg.viewer.focus_radius = 0
swayimg.viewer.focus_factor = 0.5
swayimg.viewer.preload = 2
swayimg.viewer.history = 4
swayimg.viewer.mark_color = accent
swayimg.viewer.pinch_factor = 1.0

swayimg.viewer.text = {
    topleft = {
        "{name}",
    },
    topright = {
        "{list.index} / {list.total}",
    },
    bottomleft = {
        "{frame.width}x{frame.height}  ·  {sizehr}",
    },
    bottomright = {
        "{scale}%",
    },
}

-- Размытый фон из самой картинки + шахматка для прозрачных PNG
swayimg.viewer.set_window_background("auto")
swayimg.viewer.set_image_chessboard(24, surface, bg)

-- ------------------------------------------------------------
-- Галерея
-- ------------------------------------------------------------
swayimg.gallery.thumb_size = 220
swayimg.gallery.aspect = "fit"
swayimg.gallery.padding_size = 12
swayimg.gallery.border_size = 4
swayimg.gallery.border_color = accent
swayimg.gallery.selected_scale = 1.08
swayimg.gallery.selected_color = surface_hi
swayimg.gallery.unselected_color = surface
swayimg.gallery.window_color = bg
swayimg.gallery.hover = true
swayimg.gallery.cache = 200
swayimg.gallery.preload = true
swayimg.gallery.embedded_thumb = true
swayimg.gallery.pstore = true      -- кэш миниатюр между запусками
swayimg.gallery.mark_color = accent

swayimg.gallery.text = {
    topleft = {
        "{name}",
    },
    topright = {
        "{list.index} / {list.total}",
    },
    bottomleft = {
        "{dir}",
    },
}

-- ------------------------------------------------------------
-- Слайдшоу
-- ------------------------------------------------------------
swayimg.slideshow.timeout = 5
swayimg.slideshow.loop = true
swayimg.slideshow.default_scale = "fit"
swayimg.slideshow.set_window_background("auto")

-- ------------------------------------------------------------
-- Удобные клавиши
-- ------------------------------------------------------------
swayimg.viewer.on_key("d", function() swayimg.viewer.open("next") end)
swayimg.viewer.on_key("a", function() swayimg.viewer.open("prev") end)
swayimg.viewer.on_key("n", function() swayimg.viewer.open("next") end)
swayimg.viewer.on_key("p", function() swayimg.viewer.open("prev") end)
swayimg.viewer.on_key("в", function() swayimg.viewer.open("next") end)
swayimg.viewer.on_key("ф", function() swayimg.viewer.open("prev") end)
swayimg.viewer.on_key("т", function() swayimg.viewer.open("next") end)
swayimg.viewer.on_key("з", function() swayimg.viewer.open("prev") end)
swayimg.viewer.on_key("home", function() swayimg.viewer.open("first") end)
swayimg.viewer.on_key("end", function() swayimg.viewer.open("last") end)

swayimg.slideshow.on_key("n", function() swayimg.viewer.open("next") end)
swayimg.slideshow.on_key("p", function() swayimg.viewer.open("prev") end)

swayimg.gallery.on_key("n", function() swayimg.gallery.open("next") end)
swayimg.gallery.on_key("p", function() swayimg.gallery.open("prev") end)


