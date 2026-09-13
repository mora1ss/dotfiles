#!/usr/bin/env bash
# Set a wallpaper if awww has none yet (first login / empty output).

set -euo pipefail

sleep 0.4

if ! command -v awww >/dev/null 2>&1; then
    exit 0
fi

if awww query 2>/dev/null | grep -qE '/|\\'; then
    exit 0
fi

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Wallpapers"
[[ -d "$dir" ]] || exit 0

wall="$(find "$dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) ! -path '*/Showcase/*' | sort | head -n 1)"
[[ -n "$wall" ]] || exit 0

awww img "$wall"
