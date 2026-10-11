#!/usr/bin/env bash
# Wallpaper folders and solid placeholders. Real images are left in place.

walls=$HOME/Pictures/Wallpapers
state=${XDG_STATE_HOME:-$HOME/.local/state}/theme
mkdir -p "$walls/matugen" "$walls/rose-pine" "$walls/gruvbox" "$state" \
    "$HOME/.config/theme/generated"

placeholder() {
    local dest=$1 spec=$2
    [[ -e $dest ]] && return 0
    command -v magick >/dev/null || die "ImageMagick (magick) is not installed."
    magick -size 1920x1080 "$spec" "$dest"
}

if [[ -z $(find "$walls/matugen" -maxdepth 1 -type f -print -quit) ]]; then
    placeholder "$walls/matugen/placeholder-1-teal.png" "gradient:#0f3b4a-#06141b"
    placeholder "$walls/matugen/placeholder-2-ember.png" "radial-gradient:#b8553a-#1a0d0a"
fi
if [[ -z $(find "$walls/rose-pine" -maxdepth 1 -type f -print -quit) ]]; then
    placeholder "$walls/rose-pine/placeholder-1.png" "gradient:#26233a-#191724"
    placeholder "$walls/rose-pine/placeholder-2.png" "radial-gradient:#403d52-#191724"
fi
if [[ -z $(find "$walls/gruvbox" -maxdepth 1 -type f -print -quit) ]]; then
    placeholder "$walls/gruvbox/placeholder-1.png" "gradient:#3c3836-#1d2021"
    placeholder "$walls/gruvbox/placeholder-2.png" "radial-gradient:#504945-#282828"
fi

if [[ ! -f $state/current ]]; then
    first=$(find "$walls/rose-pine" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | sort | head -n 1)
    [[ -n $first ]] || die "no wallpaper in $walls/rose-pine"
    printf 'theme=rose-pine\nwall.rose-pine=%s\n' "$first" >"$state/current"
fi

ok "theme folders ready"
