#!/usr/bin/env bash
# Shared helpers. Sourced by the installer; do not execute directly.

if [[ -z ${DOTFILES_ROOT:-} ]]; then
    echo "DOTFILES_ROOT is not set" >&2
    exit 1
fi

if [[ -t 1 ]]; then
    C_RED=$'\033[31m'
    C_GRN=$'\033[32m'
    C_YEL=$'\033[33m'
    C_BLU=$'\033[34m'
    C_OFF=$'\033[0m'
else
    C_RED="" C_GRN="" C_YEL="" C_BLU="" C_OFF=""
fi

log()  { printf '%s==>%s %s\n' "$C_BLU" "$C_OFF" "$*"; }
ok()   { printf '%s ok%s %s\n' "$C_GRN" "$C_OFF" "$*"; }
warn() { printf '%s !!%s %s\n' "$C_YEL" "$C_OFF" "$*" >&2; }
die()  { printf '%sERR%s %s\n' "$C_RED" "$C_OFF" "$*" >&2; exit 1; }

require_user() {
    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
        die "Do not run this installer as root or with sudo. Run it as your user; it will call sudo when it needs to."
    fi
    command -v sudo >/dev/null || die "sudo is not installed."
}

need_sudo() {
    log "sudo is required for: $*"
    sudo -v || die "sudo authentication failed."
}

backup_root() {
    printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}-backup/dotfiles-$(date +%Y%m%d-%H%M%S)"
}
