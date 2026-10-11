-- Look and feel: thin borders, small gaps, 4px corners, no blur/shadow,
-- short animations (<= 150ms).
-- https://wiki.hypr.land/Configuring/Basics/Variables/

-- Colours come from ../colors.lua (rewritten by `theme`).
-- If it is missing or broken, fall back to Rosé Pine so borders still render.
local fallback = {
    background = "rgb(191724)",
    outline    = "rgb(403d52)",
    primary    = "rgb(c4a7e7)",
}
local ok, c = pcall(require, "colors")
if not ok or type(c) ~= "table" then
    c = fallback
end

hl.config({
    general = {
        gaps_in     = 3,  -- 3 + 3 = 6px between windows
        gaps_out    = 6,
        border_size = 2,

        col = {
            active_border   = c.primary or fallback.primary,
            inactive_border = c.outline or fallback.outline,
        },

        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 4,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = { enabled = false },
        blur   = { enabled = false },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        background_color         = c.background or fallback.background,
    },

    ecosystem = {
        no_update_news = true,
    },
})

-- Animations: speed is in deciseconds, so 1.5 = 150ms.
hl.curve("out", { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })

hl.animation({ leaf = "global",     enabled = true, speed = 1.5, bezier = "out" })
hl.animation({ leaf = "windows",    enabled = true, speed = 1.5, bezier = "out", style = "popin 95%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.0, bezier = "out", style = "popin 95%" })
hl.animation({ leaf = "border",     enabled = true, speed = 1.5, bezier = "out" })
hl.animation({ leaf = "fade",       enabled = true, speed = 1.5, bezier = "out" })
hl.animation({ leaf = "layers",     enabled = true, speed = 1.5, bezier = "out", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.5, bezier = "out", style = "fade" })
