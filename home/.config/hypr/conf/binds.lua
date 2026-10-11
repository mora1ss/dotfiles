-- Keybinds. List active binds with: hyprctl binds
-- https://wiki.hypr.land/Configuring/Basics/Binds/
-- https://wiki.hypr.land/Configuring/Basics/Dispatchers/

local mod  = "SUPER"
local bin  = os.getenv("HOME") .. "/.local/bin/"
local exec = hl.dsp.exec_cmd

local terminal = "kitty"
local files    = "thunar"

-- Apps ------------------------------------------------------------------
hl.bind(mod .. " + Return", exec(terminal),                  { description = "Terminal" })
hl.bind(mod .. " + E",      exec(files),                     { description = "File manager" })
-- Float the active window. If it becomes floating, size it to 70% and center it.
hl.bind(mod .. " + Space", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))

    local w = hl.get_active_window()
    if w ~= nil and w.floating then
        local mon = hl.get_active_monitor()
        if mon ~= nil then
            local target_w = math.floor(mon.width * 0.7)
            local target_h = math.floor(mon.height * 0.7)
            hl.dispatch(hl.dsp.window.resize({ x = target_w, y = target_h, relative = false }))

            local mon_x = mon.x or 0
            local mon_y = mon.y or 0
            local target_x = mon_x + math.floor((mon.width - target_w) / 2)
            local target_y = mon_y + math.floor((mon.height - target_h) / 2)
            hl.dispatch(hl.dsp.window.move({ x = target_x, y = target_y, relative = false }))
        end
    end
end, { description = "Float, resize and center" })
hl.bind(mod .. " + R",      exec("rofi -show drun"),         { description = "App launcher" })
hl.bind(mod .. " + Tab",    exec("rofi -show window"),       { description = "Window switcher" })
hl.bind(mod .. " + V",      exec("cliphist list | rofi -dmenu -p clipboard -display-columns 2 | cliphist decode | wl-copy"),
                                                             { description = "Clipboard history" })
hl.bind(mod .. " + SHIFT + P", exec("hyprpicker -a"),        { description = "Colour picker" })

-- Session ---------------------------------------------------------------
-- Lock goes through logind so hypridle (phase 5) owns the lock command.
hl.bind(mod .. " + Escape", exec("loginctl lock-session"),  { description = "Lock" })
hl.bind(mod .. " + X",      exec(bin .. "powermenu"),        { description = "Power menu" })

-- Notifications (swaync) --------------------------------------------------
hl.bind(mod .. " + N",         exec("swaync-client -t -sw"), { description = "Notification panel" })
hl.bind(mod .. " + SHIFT + N", exec("swaync-client -d -sw"), { description = "Toggle do-not-disturb" })

-- Theme (script added in phase 4) -----------------------------------------
hl.bind(mod .. " + T",         exec(bin .. "theme menu"),    { description = "Theme menu" })
hl.bind(mod .. " + SHIFT + W", exec(bin .. "theme wall"),    { description = "Pick wallpaper" })
hl.bind(mod .. " + CTRL + W",  exec(bin .. "theme random"),  { description = "Random wallpaper" })

-- Screenshots -------------------------------------------------------------
hl.bind("Print",               exec(bin .. "screenshot area"),      { description = "Screenshot area (edit)" })
hl.bind("SHIFT + Print",       exec(bin .. "screenshot full"),      { description = "Screenshot full screen" })
hl.bind(mod .. " + SHIFT + S", exec(bin .. "screenshot area-clip"), { description = "Screenshot area to clipboard" })

-- Windows -----------------------------------------------------------------
hl.bind(mod .. " + Q",             hl.dsp.window.close(),                         { description = "Close window" })
hl.bind(mod .. " + F",             hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Fullscreen" })
hl.bind(mod .. " + M",             hl.dsp.window.fullscreen({ mode = "maximized" }),  { description = "Maximize" })
hl.bind(mod .. " + SHIFT + Space", hl.dsp.window.float({ action = "toggle" }),    { description = "Toggle floating" })
hl.bind(mod .. " + O",             hl.dsp.layout("togglesplit"),                  { description = "Toggle split (dwindle)" })

-- Focus / move: arrows and vim keys.
local dirs = {
    { "left",  "H", "left"  },
    { "right", "L", "right" },
    { "up",    "K", "up"    },
    { "down",  "J", "down"  },
}
for _, d in ipairs(dirs) do
    local arrow, vim, dir = d[1], d[2], d[3]
    hl.bind(mod .. " + " .. arrow,             hl.dsp.focus({ direction = dir }))
    hl.bind(mod .. " + " .. vim,               hl.dsp.focus({ direction = dir }))
    hl.bind(mod .. " + SHIFT + " .. arrow,     hl.dsp.window.move({ direction = dir }))
    hl.bind(mod .. " + SHIFT + " .. vim,       hl.dsp.window.move({ direction = dir }))
end

-- Mouse: SUPER + LMB drag, SUPER + RMB resize, SUPER + wheel cycles workspaces.
hl.bind(mod .. " + mouse:272",  hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273",  hl.dsp.window.resize(), { mouse = true })
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Resize submap: SUPER + SHIFT + R, then arrows/hjkl; Escape or Return to leave.
hl.bind(mod .. " + SHIFT + R", hl.dsp.submap("resize"), { description = "Resize mode" })
hl.define_submap("resize", function()
    local step = 30
    local keys = {
        { "right", "L",  step, 0 },
        { "left",  "H", -step, 0 },
        { "down",  "J",  0,  step },
        { "up",    "K",  0, -step },
    }
    for _, k in ipairs(keys) do
        local r = hl.dsp.window.resize({ x = k[3], y = k[4], relative = true })
        hl.bind(k[1], r, { repeating = true })
        hl.bind(k[2], r, { repeating = true })
    end
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("Return", hl.dsp.submap("reset"))
end)

-- Workspaces 1-9 ----------------------------------------------------------
for i = 1, 9 do
    hl.bind(mod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad terminal: SUPER + ` toggles it, launching it on first use.
-- The "scratchpad" class is routed to special:scratch by a rule in rules.lua.
hl.bind(mod .. " + grave", function()
    if #hl.get_windows({ class = "^scratchpad$" }) == 0 then
        hl.exec_cmd("kitty --class scratchpad")
    end
    hl.dispatch(hl.dsp.workspace.toggle_special("scratch"))
end, { description = "Scratchpad terminal" })
hl.bind(mod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:scratch" }),
        { description = "Send window to scratchpad" })

-- Media keys (work on the lock screen too) ---------------------------------
-- No backlight device on this machine, so no brightness keys.
hl.bind("XF86AudioRaiseVolume", exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",     exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
hl.bind("XF86AudioPlay",        exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause",       exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",        exec("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",        exec("playerctl previous"),   { locked = true })
