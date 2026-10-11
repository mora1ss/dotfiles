-- Autostart: runs once, when Hyprland starts (not on reload).
-- https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function()
    -- Export the session environment to D-Bus/systemd so portals see it.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")

    -- Graphical polkit prompts (user unit shipped by hyprpolkitagent).
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    -- Bar and notifications.
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")

    -- Wallpaper daemon, then re-apply the saved theme/wallpaper
    -- (`theme restore` waits for the daemon socket itself).
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/theme restore")

    -- Idle/lock daemon (configured in phase 5; exits quietly without a config).
    hl.exec_cmd("hypridle")

    -- Clipboard history (text and images).
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
