-- Environment variables, inherited by everything Hyprland launches.
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
-- https://wiki.hypr.land/Nvidia/

local home = os.getenv("HOME")

-- User scripts (theme, screenshot, powermenu) live here.
hl.env("PATH", home .. "/.local/bin:" .. (os.getenv("PATH") or "/usr/bin"))

-- Session identity (Hyprland also sets most of these; explicit for portals/apps).
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE",    "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- NVIDIA ---------------------------------------------------------------
-- VA-API hardware video decode through nvidia-vaapi-driver (libva-nvidia-driver).
hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- Make GLVND pick NVIDIA's GLX for XWayland apps.
-- If an X11 app (e.g. some screen-share tools) misbehaves, try removing this one.
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
-- nvidia-vaapi-driver backend; "direct" is required on current drivers.
-- The driver itself is still considered experimental by its author.
hl.env("NVD_BACKEND", "direct")

-- Toolkits --------------------------------------------------------------
-- Electron apps (VSCodium, etc.) run natively on Wayland when possible.
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
-- Qt: Wayland first, X11 as fallback; colours/style via qt6ct + kvantum.
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

-- Cursor (Bibata is an XCursor theme; hyprcursor falls back to it).
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
