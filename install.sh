#!/usr/bin/env bash

set -uo pipefail

# 43PR/dotfiles installer
# Arch-compatible Linux + Hyprland
#
# Usage:
#   ./install.sh
#
# This script:
#   1. Verifies that the system is Arch-based
#   2. Detects the available package manager(s)
#   3. Splits packages.txt into "official repo" vs "AUR-only" and
#      installs each with the right tool, so a single AUR-only or
#      unresolvable name never aborts the whole install
#   4. Backs up existing ~/.config
#   5. Installs this repository's configuration
#   6. Installs SDDM + SilentSDDM (configs/rei.conf, blue-light)
#   7. Enables SDDM on graphical.target so Hyprland starts after reboot
#   8. Configures NVIDIA DRM / VA-API when an NVIDIA GPU is detected
#
# Supported package managers:
#   - pacman       (official repos: Arch, Manjaro, EndeavourOS, CachyOS, etc.)
#   - paru / yay   (AUR helpers, optional but recommended)

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_ROOT="$HOME/.config-backups"
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

# --------------------------------------------------
# Colors / output
# --------------------------------------------------

info() {
    printf '\n\033[1;34m[INFO]\033[0m %s\n' "$1"
}

success() {
    printf '\n\033[1;32m[DONE]\033[0m %s\n' "$1"
}

warning() {
    printf '\n\033[1;33m[WARN]\033[0m %s\n' "$1"
}

error() {
    printf '\n\033[1;31m[ERROR]\033[0m %s\n' "$1" >&2
}

# --------------------------------------------------
# Checks
# --------------------------------------------------

if [[ "${EUID}" -eq 0 ]]; then
    error "Do not run this script as root."
    exit 1
fi

if [[ ! -f /etc/os-release ]]; then
    error "Cannot determine the operating system."
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

# Arch-compatible distributions normally identify themselves
# through ID_LIKE=arch or ID=arch.
if [[ "${ID:-}" != "arch" && "${ID_LIKE:-}" != *arch* ]]; then
    error "This installer is intended for Arch-compatible Linux distributions."
    error "Detected: ${PRETTY_NAME:-unknown}"
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    error "sudo is required."
    exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
    error "pacman was not found. This installer requires an Arch-based system."
    exit 1
fi

# --------------------------------------------------
# Package manager detection
# --------------------------------------------------

PACKAGE_FILE="$REPO_DIR/packages.txt"

if [[ ! -f "$PACKAGE_FILE" ]]; then
    error "packages.txt not found."
    exit 1
fi

AUR_HELPER=""
if command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
elif command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
fi

info "Detected distribution: ${PRETTY_NAME:-unknown}"

if [[ -n "$AUR_HELPER" ]]; then
    info "AUR helper available: $AUR_HELPER"
else
    info "No AUR helper found. Bootstrapping yay..."

    if sudo pacman -S --needed --noconfirm git base-devel; then
        YAY_BUILD_DIR="$(mktemp -d)"

        if git clone https://aur.archlinux.org/yay.git "$YAY_BUILD_DIR/yay" \
            && (cd "$YAY_BUILD_DIR/yay" && makepkg -si --noconfirm); then
            AUR_HELPER="yay"
            success "yay installed."
        else
            warning "Failed to build/install yay automatically."
            warning "You can install one manually (paru or yay) and re-run this script."
        fi

        rm -rf "$YAY_BUILD_DIR"
    else
        warning "Failed to install git/base-devel; cannot bootstrap an AUR helper."
        warning "AUR-only packages will be listed but skipped."
    fi
fi

# --------------------------------------------------
# Packages: split into official-repo vs AUR-only
# --------------------------------------------------

mapfile -t PACKAGES < <(
    grep -vE '^[[:space:]]*(#|$)' "$PACKAGE_FILE"
)

OFFICIAL_PACKAGES=()
AUR_PACKAGES=()
UNKNOWN_PACKAGES=()

if [[ "${#PACKAGES[@]}" -eq 0 ]]; then
    warning "packages.txt does not contain any packages."
else
    info "Resolving packages against official repos..."

    for pkg in "${PACKAGES[@]}"; do
        if pacman -Si "$pkg" >/dev/null 2>&1; then
            OFFICIAL_PACKAGES+=("$pkg")
        elif [[ -n "$AUR_HELPER" ]] && "$AUR_HELPER" -Si "$pkg" >/dev/null 2>&1; then
            AUR_PACKAGES+=("$pkg")
        else
            UNKNOWN_PACKAGES+=("$pkg")
        fi
    done

    if [[ "${#OFFICIAL_PACKAGES[@]}" -gt 0 ]]; then
        info "Installing official-repo packages..."
        if sudo pacman -Syu --needed --noconfirm "${OFFICIAL_PACKAGES[@]}"; then
            success "Official-repo packages installed."
        else
            warning "pacman reported an error installing one or more official-repo packages. Continuing anyway."
        fi
    fi

    if [[ "${#AUR_PACKAGES[@]}" -gt 0 ]]; then
        if [[ -n "$AUR_HELPER" ]]; then
            info "Installing AUR packages with $AUR_HELPER: ${AUR_PACKAGES[*]}"
            if "$AUR_HELPER" -S --needed --noconfirm "${AUR_PACKAGES[@]}"; then
                success "AUR packages installed."
            else
                warning "$AUR_HELPER reported an error installing one or more AUR packages. Continuing anyway."
            fi
        fi
    fi

    if [[ "${#UNKNOWN_PACKAGES[@]}" -gt 0 ]]; then
        warning "Could not resolve the following package(s) in any repo: ${UNKNOWN_PACKAGES[*]}"
        warning "Check the name with 'pacman -Ss <name>' or https://aur.archlinux.org, then fix packages.txt."
    fi
fi

# --------------------------------------------------
# Default shell
# --------------------------------------------------

if [[ -x /bin/zsh ]]; then
    if [[ "$SHELL" != "/bin/zsh" ]]; then
        info "Setting Zsh as the default shell..."

        if chsh -s /bin/zsh; then
            success "Default shell changed to Zsh."
            warning "Log out and back in for the shell change to take effect."
        else
            warning "Failed to change the default shell to Zsh."
        fi
    else
        info "Zsh is already the default shell."
    fi
else
    warning "Zsh is not installed; skipping default shell configuration."
fi

# --------------------------------------------------
# Backup existing configuration
# --------------------------------------------------

if [[ -d "$CONFIG_DIR" ]]; then
    info "Backing up existing ~/.config..."

    mkdir -p "$BACKUP_DIR"

    # Only back up directories/files that this repository
    # is going to replace.
    for item in "$REPO_DIR/.config/"*; do
        [[ -e "$item" ]] || continue

        name="$(basename "$item")"

        if [[ -e "$CONFIG_DIR/$name" ]]; then
            cp -a "$CONFIG_DIR/$name" "$BACKUP_DIR/"
        fi
    done

    success "Existing configuration backed up to:"
    printf '  %s\n' "$BACKUP_DIR"
else
    mkdir -p "$CONFIG_DIR"
fi

# --------------------------------------------------
# Install dotfiles
# --------------------------------------------------

info "Installing dotfiles..."

# Install ~/.config files
cp -a "$REPO_DIR/.config/." "$CONFIG_DIR/"

# Install ~/.zshrc
if [[ -f "$REPO_DIR/.config/.zshrc" ]]; then
    cp "$REPO_DIR/.config/.zshrc" "$HOME/.zshrc"
    success "Installed .zshrc."
else
    warning ".zshrc not found; skipping."
fi

success "Dotfiles installed."

# --------------------------------------------------
# Rewrite machine-specific paths for the installing user
# --------------------------------------------------

info "Rewriting config paths for $USER..."

while IFS= read -r -d '' file; do
    grep -q '/home/rp34' "$file" 2>/dev/null || continue
    sed -i "s|/home/rp34|$HOME|g" "$file"
done < <(find "$CONFIG_DIR" -type f -print0 2>/dev/null)

if [[ -f "$HOME/.zshrc" ]] && grep -q '/home/rp34' "$HOME/.zshrc" 2>/dev/null; then
    sed -i "s|/home/rp34|$HOME|g" "$HOME/.zshrc"
fi

if [[ -f "$CONFIG_DIR/spicetify/config-xpui.ini" ]]; then
    sed -i "s|^prefs_path[[:space:]]*=.*|prefs_path             = $HOME/.config/spotify/prefs|" \
        "$CONFIG_DIR/spicetify/config-xpui.ini"
fi

success "Config paths set for $HOME."

# --------------------------------------------------
# Papirus folder color
# --------------------------------------------------

if [[ -n "$AUR_HELPER" ]]; then
    info "Installing Papirus folders..."

    if "$AUR_HELPER" -S --needed --noconfirm papirus-folders; then
        if papirus-folders -C white; then
            success "Papirus folders set to white."
        else
            warning "papirus-folders was installed, but setting the folder color failed."
        fi
    else
        warning "Failed to install papirus-folders."
    fi
else
    warning "No AUR helper available; skipping papirus-folders."
fi

# --------------------------------------------------
# Wallpapers
# --------------------------------------------------

if [[ -d "$REPO_DIR/Wallpapers" ]]; then
    info "Installing wallpapers..."

    mkdir -p "$HOME/Pictures/Wallpapers"
    cp -a "$REPO_DIR/Wallpapers/." "$HOME/Pictures/Wallpapers/"

    success "Wallpapers installed."
fi

# --------------------------------------------------
# Default user directories
# --------------------------------------------------

info "Creating default user directories..."

if ! command -v xdg-user-dirs-update >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm xdg-user-dirs >/dev/null 2>&1 || true
fi

write_user_dirs() {
    mkdir -p \
        "$HOME/Ambiente de trabalho" \
        "$HOME/Transferências" \
        "$HOME/Modelos" \
        "$HOME/Público" \
        "$HOME/Documentos" \
        "$HOME/Música" \
        "$HOME/Pictures/Wallpapers" \
        "$HOME/Pictures/Screenshots" \
        "$HOME/Vídeos"

    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_DIR/user-dirs.dirs" <<'EOF'
XDG_DESKTOP_DIR="$HOME/Ambiente de trabalho"
XDG_DOWNLOAD_DIR="$HOME/Transferências"
XDG_TEMPLATES_DIR="$HOME/Modelos"
XDG_PUBLICSHARE_DIR="$HOME/Público"
XDG_DOCUMENTS_DIR="$HOME/Documentos"
XDG_MUSIC_DIR="$HOME/Música"
XDG_PICTURES_DIR="$HOME/Pictures"
XDG_VIDEOS_DIR="$HOME/Vídeos"
EOF
    printf 'pt_PT\n' > "$CONFIG_DIR/user-dirs.locale"
}

write_user_dirs

if command -v xdg-user-dirs-update >/dev/null 2>&1; then
    xdg-user-dirs-update
    write_user_dirs
fi

success "Default folders ready (Documentos, Transferências, Vídeos, …)."

# --------------------------------------------------
# Enable user audio services
# --------------------------------------------------

if command -v systemctl >/dev/null 2>&1; then
    info "Enabling PipeWire..."

    systemctl --user enable --now pipewire.service
    systemctl --user enable --now pipewire-pulse.service
    systemctl --user enable --now wireplumber.service

    success "PipeWire configured."
else
    warning "systemctl was not found; skipping PipeWire service setup."
fi

# --------------------------------------------------
# Permissions
# --------------------------------------------------

info "Setting executable permissions on scripts..."

if [[ -d "$CONFIG_DIR/hypr/scripts" ]]; then
    find "$CONFIG_DIR/hypr/scripts" -type f -exec chmod +x {} \;
fi

if [[ -d "$CONFIG_DIR/waybar/scripts" ]]; then
    find "$CONFIG_DIR/waybar/scripts" -type f -exec chmod +x {} \;
fi

if [[ -d "$CONFIG_DIR/quickshell" ]]; then
    find "$CONFIG_DIR/quickshell" -type f -name '*.sh' -exec chmod +x {} \;
fi

if [[ -f "$CONFIG_DIR/wlogout/launch.sh" ]]; then
    chmod +x "$CONFIG_DIR/wlogout/launch.sh"
fi

success "Permissions configured."

# --------------------------------------------------
# NVIDIA (RTX 30xx / Ampere — DRM, VA-API, suspend)
# --------------------------------------------------

has_nvidia_gpu() {
    lspci 2>/dev/null | grep -qiE 'VGA compatible controller.*NVIDIA|3D controller.*NVIDIA|NVIDIA Corporation.*(VGA|3D)'
}

nvidia_kernel_pkg_installed() {
    pacman -Qq 2>/dev/null | grep -qE '^(nvidia|nvidia-lts|nvidia-dkms|nvidia-open|nvidia-open-dkms|linux-cachyos-nvidia|linux-cachyos-nvidia-open)(-open)?$'
}

install_nvidia_stack() {
    if ! has_nvidia_gpu; then
        info "No NVIDIA GPU detected; skipping NVIDIA DRM/VA-API setup."
        return 0
    fi

    info "NVIDIA GPU detected. Configuring DRM, VA-API and suspend..."

    local nvidia_pkgs=(nvidia-utils egl-wayland libva-nvidia-driver libva-utils nvidia-settings)
    sudo pacman -S --needed --noconfirm "${nvidia_pkgs[@]}" || \
        warning "Failed to install one or more NVIDIA userspace packages."

    if pacman -Slq multilib 2>/dev/null | grep -qx lib32-nvidia-utils; then
        sudo pacman -S --needed --noconfirm lib32-nvidia-utils || true
    fi

    if ! nvidia_kernel_pkg_installed; then
        local headers=""
        if pacman -Q linux-cachyos >/dev/null 2>&1; then
            headers="linux-cachyos-headers"
        elif pacman -Q linux-zen >/dev/null 2>&1; then
            headers="linux-zen-headers"
        elif pacman -Q linux-lts >/dev/null 2>&1; then
            headers="linux-lts-headers"
        elif pacman -Q linux >/dev/null 2>&1; then
            headers="linux-headers"
        fi

        if [[ -n "$headers" ]]; then
            sudo pacman -S --needed --noconfirm "$headers" || true
        fi

        if pacman -Si nvidia-open-dkms >/dev/null 2>&1; then
            info "Installing nvidia-open-dkms (recommended for RTX 3060 / Ampere)..."
            sudo pacman -S --needed --noconfirm nvidia-open-dkms || \
                warning "Failed to install nvidia-open-dkms. Install the matching NVIDIA kernel module for your kernel."
        fi
    else
        info "NVIDIA kernel module already installed; leaving it unchanged."
    fi

    sudo tee /etc/modprobe.d/nvidia-hyprland.conf >/dev/null <<'EOF'
options nvidia_drm modeset=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
EOF

    if [[ -f /etc/mkinitcpio.conf ]] && ! grep -q 'nvidia_drm' /etc/mkinitcpio.conf; then
        sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
        if command -v mkinitcpio >/dev/null 2>&1; then
            info "Rebuilding initramfs for early NVIDIA KMS..."
            sudo mkinitcpio -P || warning "mkinitcpio -P failed; rebuild it manually after reboot if DRM is N."
        fi
    fi

    if [[ -d /boot/loader/entries ]]; then
        local entry
        for entry in /boot/loader/entries/*.conf; do
            [[ -f "$entry" ]] || continue
            if ! grep -q 'nvidia-drm.modeset' "$entry"; then
                sudo sed -i '/^options / s/$/ nvidia-drm.modeset=1 nvidia.NVreg_PreserveVideoMemoryAllocations=1/' "$entry"
            fi
        done
    elif [[ -f /etc/default/grub ]] && ! grep -q 'nvidia-drm.modeset' /etc/default/grub; then
        sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 nvidia.NVreg_PreserveVideoMemoryAllocations=1 /' /etc/default/grub
        if command -v grub-mkconfig >/dev/null 2>&1; then
            sudo grub-mkconfig -o /boot/grub/grub.cfg || true
        fi
    fi

    sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service 2>/dev/null || true

    if [[ -r /sys/module/nvidia_drm/parameters/modeset ]]; then
        info "nvidia_drm modeset=$(cat /sys/module/nvidia_drm/parameters/modeset) (Y = DRM enabled)"
    else
        warning "nvidia_drm is not loaded yet. After reboot, 'cat /sys/module/nvidia_drm/parameters/modeset' should print Y."
    fi

    success "NVIDIA DRM / VA-API configured. Reboot for KMS to take effect."
}

install_nvidia_stack

# --------------------------------------------------
# SDDM + SilentSDDM (rei / blue-light)
# --------------------------------------------------

install_sddm_silent() {
    local theme_src theme_dst metadata session_file

    info "Installing SDDM and SilentSDDM (preset rei / blue-light)..."

    if ! command -v git >/dev/null 2>&1; then
        warning "git is not available; skipping SilentSDDM."
        return 1
    fi

    local qt_pkgs=(sddm qt6-svg qt6-virtualkeyboard qt6-imageformats)
    if pacman -Si qt6-multimedia-ffmpeg >/dev/null 2>&1; then
        qt_pkgs+=(qt6-multimedia-ffmpeg)
    elif pacman -Si qt6-multimedia >/dev/null 2>&1; then
        qt_pkgs+=(qt6-multimedia)
    fi

    if ! sudo pacman -S --needed --noconfirm "${qt_pkgs[@]}"; then
        warning "Failed to install SDDM / Qt6 dependencies. Continuing anyway."
    fi

    theme_src="$(mktemp -d)"
    theme_dst="/usr/share/sddm/themes/silent"

    if ! git clone -b main --depth=1 https://github.com/uiriansan/SilentSDDM "$theme_src/SilentSDDM"; then
        warning "Failed to clone SilentSDDM."
        rm -rf "$theme_src"
        return 1
    fi

    sudo mkdir -p "$theme_dst"
    sudo cp -rf "$theme_src/SilentSDDM/." "$theme_dst/"
    rm -rf "$theme_src"

    if [[ -d "$theme_dst/fonts/redhat" ]]; then
        sudo cp -r "$theme_dst/fonts/redhat" /usr/share/fonts/
    fi
    if [[ -d "$theme_dst/fonts/redhat-vf" ]]; then
        sudo cp -r "$theme_dst/fonts/redhat-vf" /usr/share/fonts/
    fi
    if command -v fc-cache >/dev/null 2>&1; then
        sudo fc-cache -f >/dev/null 2>&1 || true
    fi

    metadata="$theme_dst/metadata.desktop"
    if [[ -f "$metadata" ]]; then
        sudo sed -i -E 's/^ConfigFile=.*/ConfigFile=configs\/rei.conf/' "$metadata"
        success "SilentSDDM preset set to configs/rei.conf (blue-light)."
    else
        warning "SilentSDDM metadata.desktop not found; could not select rei.conf."
    fi

    sudo mkdir -p /etc/sddm.conf.d
    sudo tee /etc/sddm.conf.d/99-silent-hyprland.conf >/dev/null <<'EOF'
[General]
InputMethod=qtvirtualkeyboard
GreeterEnvironment=QML2_IMPORT_PATH=/usr/share/sddm/themes/silent/components/,QT_IM_MODULE=qtvirtualkeyboard

[Theme]
Current=silent
EOF

    session_file=""
    if [[ -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
        session_file="hyprland.desktop"
    elif [[ -f /usr/share/wayland-sessions/hyprland-uwsm.desktop ]]; then
        session_file="hyprland-uwsm.desktop"
    elif [[ -f /usr/share/wayland-sessions/start-hyprland.desktop ]]; then
        session_file="start-hyprland.desktop"
    else
        local hypr_exec=""
        if command -v start-hyprland >/dev/null 2>&1; then
            hypr_exec="start-hyprland"
        elif command -v Hyprland >/dev/null 2>&1; then
            hypr_exec="Hyprland"
        fi

        if [[ -n "$hypr_exec" ]]; then
            sudo mkdir -p /usr/share/wayland-sessions
            sudo tee /usr/share/wayland-sessions/hyprland.desktop >/dev/null <<EOF
[Desktop Entry]
Name=Hyprland
Comment=Hyprland compositor
Exec=${hypr_exec}
Type=Application
DesktopNames=Hyprland
EOF
            session_file="hyprland.desktop"
            info "Created wayland session ${session_file} (Exec=${hypr_exec})."
        fi
    fi

    if [[ -n "$session_file" ]]; then
        sudo mkdir -p /var/lib/sddm
        sudo tee /var/lib/sddm/state.conf >/dev/null <<EOF
[Last]
Session=${session_file}
User=${USER}
EOF
        info "SDDM default session: $session_file"
    else
        warning "No Hyprland wayland-session file found yet. SDDM will list whatever sessions exist after reboot."
    fi

    for dm in gdm gdm3 lightdm lxdm ly greetd; do
        if systemctl list-unit-files "${dm}.service" >/dev/null 2>&1; then
            sudo systemctl disable "$dm.service" >/dev/null 2>&1 || true
            sudo systemctl stop "$dm.service" >/dev/null 2>&1 || true
        fi
    done

    if sudo systemctl enable sddm.service && sudo systemctl set-default graphical.target; then
        success "SDDM enabled. After reboot you get SilentSDDM, then Hyprland — no start-hyprland."
    else
        warning "Failed to enable SDDM or set graphical.target."
        return 1
    fi
}

install_sddm_silent

# --------------------------------------------------
# Finish
# --------------------------------------------------

printf '\n'
printf '\033[1;32m========================================\033[0m\n'
printf '\033[1;32m       43PR Hyprland Setup Ready       \033[0m\n'
printf '\033[1;32m========================================\033[0m\n'
printf '\n'

printf 'Distribution:  %s\n' "${PRETTY_NAME:-unknown}"
printf 'AUR helper:    %s\n' "${AUR_HELPER:-none}"
printf 'Configuration: %s\n' "$CONFIG_DIR"

if [[ -d "$BACKUP_DIR" ]]; then
    printf 'Backup:        %s\n' "$BACKUP_DIR"
fi

if [[ "${#UNKNOWN_PACKAGES[@]:-0}" -gt 0 ]]; then
    printf '\n'
    warning "Unresolved packages (install manually): ${UNKNOWN_PACKAGES[*]}"
fi

printf '\n'
warning "Reboot to enter SilentSDDM (rei / blue-light). Log in and Hyprland starts automatically."
printf '  sudo reboot\n'

printf '\n'
success "Installation complete!"
