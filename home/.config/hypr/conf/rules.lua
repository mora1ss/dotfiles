-- Window, workspace and layer rules. Inspect windows with: hyprctl clients
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Workspace roles: 1 terminal, 2 code, 3 browser, 4 docs/chat, 5 media.
-- Persistent so they always show in the bar.
for i = 1, 5 do
    hl.workspace_rule({ workspace = tostring(i), persistent = true })
end

-- General -----------------------------------------------------------------
hl.window_rule({
    -- Ignore maximize requests from apps; use SUPER + M instead.
    name  = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland.
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Workspace assignment (examples; adjust classes with `hyprctl clients`) ---
hl.window_rule({ name = "ws-code",    match = { class = "^(codium|VSCodium)$" },                         workspace = "2" })
hl.window_rule({ name = "ws-browser", match = { class = "^(firefox|zen|chromium|brave-browser)$" },      workspace = "3" })
hl.window_rule({ name = "ws-chat",    match = { class = "^(vesktop|discord|org.telegram.desktop|obsidian)$" }, workspace = "4" })
hl.window_rule({ name = "ws-media",   match = { class = "^(mpv|spotify|vlc)$" },                         workspace = "5" })

-- Floating utilities --------------------------------------------------------
hl.window_rule({
    name   = "float-utilities",
    match  = { class = "^(org.pulseaudio.pavucontrol|nwg-look|qt6ct|kvantummanager|swappy|xdg-desktop-portal-gtk|hyprland-run)$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name  = "float-dialogs",
    match = { title = "^(Open File|Save File|Save As|Open Folder|File Operation Progress)(.*)$" },
    float = true,
    center = true,
})

-- Scratchpad terminal (see binds.lua) ---------------------------------------
hl.window_rule({
    name      = "scratchpad",
    match     = { class = "^scratchpad$" },
    float     = true,
    size      = { "monitor_w*0.6", "monitor_h*0.6" },
    center    = true,
    workspace = "special:scratch silent",
})

-- Layers --------------------------------------------------------------------
-- slurp's selection overlay should appear instantly.
hl.layer_rule({ name = "no-anim-selection", match = { namespace = "^selection$" }, no_anim = true })
