-- Monitors. Check names and modes with: hyprctl monitors
-- https://wiki.hypr.land/Configuring/Basics/Monitors/
--
-- An empty output matches every connected monitor and uses its preferred mode.
-- To pin one display, replace this with the real name, for example:
--   output = "DP-3", mode = "1920x1080@165.00", position = "0x0", scale = 1

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})
