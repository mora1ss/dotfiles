#!/usr/bin/env bash
# Official packages, paru, then AUR packages. Sourced by install.sh.

PACMAN_PKGS=(
    hyprland hypridle hyprlock hyprpolkitagent
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    waybar rofi swaync kitty cava fastfetch fish
    thunar thunar-volman thunar-archive-plugin tumbler gvfs xarchiver
    sddm qt6-svg qt6-declarative qt6-virtualkeyboard qt6-multimedia-ffmpeg qt6-5compat
    matugen awww
    cliphist wl-clipboard grim slurp swappy
    playerctl wireplumber pipewire pipewire-pulse pipewire-alsa
    papirus-icon-theme adw-gtk-theme nwg-look qt6ct kvantum
    ttf-jetbrains-mono-nerd inter-font noto-fonts noto-fonts-emoji
    polkit libnotify jq imagemagick
    starship yazi hyprpicker
    stow git base-devel
)

AUR_PKGS=(
    vscodium-bin
    sddm-astronaut-theme
    bibata-cursor-theme-bin
)

need_sudo "install and upgrade packages"
sudo pacman -Syu --needed --noconfirm "${PACMAN_PKGS[@]}"

if ! command -v paru >/dev/null; then
    if pacman -Si paru >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm paru
    else
        log "paru is not in the repos; building paru-bin from the AUR"
        tmp=$(mktemp -d)
        git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
        (cd "$tmp/paru-bin" && makepkg -si --noconfirm)
        rm -rf "$tmp"
    fi
fi

command -v paru >/dev/null || die "paru is still not available."
log "AUR packages (paru will ask for your password itself)"
paru -S --needed --noconfirm "${AUR_PKGS[@]}"
ok "packages installed"
