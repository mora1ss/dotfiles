-- Hyprland entry point: only requires modules.
-- Each require() runs in its own scope, so an error in one module does not
-- stop the others from loading. Colours live in colors.lua (managed by `theme`).

require("conf/env")
require("conf/monitors")
require("conf/input")
require("conf/look")
require("conf/rules")
require("conf/binds")
require("conf/autostart")
