#!/usr/bin/env bash
# Dotfiles installer.
#
# From a fresh TTY, after the repository is on GitHub:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/mora1ss/dotfiles/main/install/install.sh)"
#
# From a local clone:
#   bash install/install.sh
#
# Never run this as root.

set -euo pipefail

REPO_URL="https://github.com/mora1ss/dotfiles.git"
CLONE_DIR="${DOTFILES_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles}"

# curl | bash has no script file. Clone, then re-exec the file on disk
# so the phases can be sourced.
if [[ ! -f ${BASH_SOURCE[0]:-} ]]; then
    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
        echo "Do not run this installer as root or with sudo." >&2
        exit 1
    fi
    command -v git >/dev/null || { echo "git is required to download the dotfiles." >&2; exit 1; }
    if [[ -d $CLONE_DIR/.git ]]; then
        git -C "$CLONE_DIR" pull --ff-only
    else
        git clone "$REPO_URL" "$CLONE_DIR"
    fi
    exec bash "$CLONE_DIR/install/install.sh"
fi

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export DOTFILES_ROOT
# shellcheck source=utils.sh
source "$DOTFILES_ROOT/install/utils.sh"

require_user

log "dotfiles: $DOTFILES_ROOT"
log "user: $USER  home: $HOME"

for phase in 01_packages.sh 02_stow.sh 03_themes.sh 04_system.sh; do
    log "phase $phase"
    # shellcheck source=/dev/null
    source "$DOTFILES_ROOT/install/phases/$phase"
done

ok "done. Log out and start Hyprland. On the next boot, SDDM should be the login screen."
ok "Pick the Hyprland session, not hyprland-uwsm."
ok "Wallpapers go in ~/Pictures/Wallpapers/{matugen,rose-pine,gruvbox}."
