#!/usr/bin/env bash
# User folders, black Papirus folders, wallpaper placeholders.
# Real images are left in place.

command -v xdg-user-dirs-update >/dev/null || die "xdg-user-dirs-update is not installed."
xdg-user-dirs-update
ok "user directories created"

# Built here, not shipped in the repo: the icons are absolute symlinks into
# /usr/share/icons/Papirus-Dark, which stow refuses to link.
papirus_black() {
    local src=/usr/share/icons/Papirus-Dark
    local dst=$HOME/.local/share/icons/Papirus-Dark-Black
    [[ -d $src ]] || die "papirus-icon-theme is not installed ($src missing)."
    rm -rf "$dst"
    mkdir -p "$dst"
    shopt -s nullglob
    local places=( "$src"/*/places "$src"/*/*/places "$src"/*@2x/places "$src"/*@2x/*/places )
    local -A seen=()
    local dirs=() d rel name target current final black
    local -A chain=()
    for d in "${places[@]}"; do
        [[ -d $d && -z ${seen[$d]+x} ]] || continue
        seen[$d]=1
        rel=${d#"$src/"}
        mkdir -p "$dst/$rel"
        dirs+=("$rel")
        for link in "$d"/*; do
            [[ -L $link ]] || continue
            name=$(basename "$link")
            current=$name
            chain=()
            final=""
            for _ in 1 2 3 4 5 6 7 8; do
                [[ -n ${chain[$current]+x} ]] && break
                chain[$current]=1
                [[ -L $d/$current ]] || { final=$current; break; }
                target=$(readlink "$d/$current")
                [[ $target != /* ]] || { final=$(basename "$target"); break; }
                current=$(basename "$target")
                final=$current
            done
            black=""
            case $final in
                folder-blue.svg) black=folder-black.svg ;;
                folder-blue-*)   black="folder-black-${final#folder-blue-}" ;;
                user-blue-*)     black="user-black-${final#user-blue-}" ;;
            esac
            [[ -n $black && -e $d/$black ]] || continue
            ln -s "$d/$black" "$dst/$rel/$name"
        done
    done
    {
        echo "[Icon Theme]"
        echo "Name=Papirus Dark (black folders)"
        echo "Comment=Papirus-Dark with the black folder colour"
        echo "Inherits=Papirus-Dark"
        echo "Example=folder"
        local IFS=,
        echo "Directories=${dirs[*]}"
        echo
        for rel in "${dirs[@]}"; do
            local size=${rel%%x*}
            size=${size%%@*}
            echo "[$rel]"
            echo "Context=Places"
            echo "Size=$size"
            echo "Type=Fixed"
            [[ $rel == *@2x* ]] && echo "Scale=2"
            echo
        done
    } > "$dst/index.theme"
    gtk-update-icon-cache -f -t "$dst" >/dev/null
    shopt -u nullglob
    ok "Papirus-Dark-Black generated"
}

papirus_black

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
