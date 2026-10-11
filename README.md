# dotfiles

Hyprland rice for CachyOS: dark, 4px corners, and three switchable themes (Matugen, Rosé Pine, Gruvbox).

The installer does not hardcode a home directory or a username. It uses `$HOME` and `$USER`.

## Install

On a fresh CachyOS install, from a TTY, as your user (not root):

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/mora1ss/dotfiles/main/install/install.sh)"
```

From a clone you already have:

```bash
bash install/install.sh
```

Running it with `sudo` or as root stops immediately. `sudo` is used only for `pacman`, SDDM, and `/etc`. `paru` runs as your user and asks for the password itself.

## What it does

1. Full upgrade and install of the Hyprland stack from the official repos, then `paru` if it is missing, then the AUR packages (`vscodium-bin`, `sddm-astronaut-theme`, `bibata-cursor-theme-bin`).
2. Moves any conflicting files under `$HOME` to `~/.config-backup/dotfiles-<date>/` and symlinks this repo with GNU stow.
3. Creates `~/Pictures/Wallpapers/{matugen,rose-pine,gruvbox}` and, if a folder is empty, a couple of placeholder images.
4. Points SDDM at the Post-apocalyptic hacker variant and enables it for the next boot. It does not start SDDM in the current session.

Log out and start Hyprland. At the SDDM screen choose **Hyprland**, not `hyprland-uwsm`.

## Themes

`SUPER + T` opens Matugen, Rosé Pine, and Gruvbox. Put images in the matching wallpaper folder. Matugen recolours from the image. The other two keep a fixed palette.

VSCodium themes to install yourself (Open VSX, inside VSCodium):

- Rosé Pine: `mvllow.rose-pine`
- Gruvbox Dark Medium: `jdinhlife.gruvbox`

The Matugen theme is a local extension and does not need a download.

## Monitor

`hypr/conf/monitors.lua` uses the preferred mode of whatever is connected. To pin a display:

```lua
hl.monitor({
    output   = "DP-3",
    mode     = "1920x1080@165.00",
    position = "0x0",
    scale    = 1,
})
```

`hyprctl monitors` prints the output name and the modes.
