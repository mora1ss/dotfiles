#!/usr/bin/env bash
# SDDM theme and enablement. Does not start the display manager.
# hypridle and hyprpolkitagent are started by Hyprland autostart, not here,
# so they are not launched before a Wayland session exists.

theme_pkg=/usr/share/sddm/themes/sddm-astronaut-theme
meta=$theme_pkg/metadata.desktop
[[ -f $meta ]] || die "sddm-astronaut-theme is not installed ($meta missing)."
[[ -f $theme_pkg/Themes/post-apocalyptic_hacker.conf ]] || die "Post-apocalyptic hacker variant is missing."

need_sudo "write /etc/sddm.conf.d and enable sddm"

sudo mkdir -p /etc/sddm.conf.d
sudo cp "$DOTFILES_ROOT/etc/sddm/10-theme.conf" /etc/sddm.conf.d/10-theme.conf
sudo cp "$DOTFILES_ROOT/etc/sddm/10-general.conf" /etc/sddm.conf.d/10-general.conf
sudo sed -i 's|^ConfigFile=.*|ConfigFile=Themes/post-apocalyptic_hacker.conf|' "$meta"

sudo systemctl enable sddm.service
ok "sddm enabled for the next boot (not started)"

# A desktop-less install does not start NetworkManager on its own.
sudo systemctl enable --now NetworkManager.service
ok "NetworkManager enabled and started"
