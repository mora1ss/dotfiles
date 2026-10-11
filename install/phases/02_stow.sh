#!/usr/bin/env bash
# Symlink each file in home/ onto $HOME. Directories are created, not replaced,
# so the rest of $HOME/.config is left alone. A file that is already there and
# is not this symlink is moved into a backup directory first.

PKG="$DOTFILES_ROOT/home"
command -v stow >/dev/null || die "stow is not installed (phase 01 should have installed it)."
[[ -d $PKG ]] || die "missing package directory: $PKG"

# Stow refuses absolute symlinks and then aborts the whole link step.
abs=$(find "$PKG" -type l -lname '/*' -print)
if [[ -n $abs ]]; then
    die "refusing to stow absolute symlinks (remove them from the repo):"$'\n'"$abs"
fi

backup=$(backup_root)
moved=0

while IFS= read -r -d '' src; do
    rel=${src#"$PKG/"}
    dest="$HOME/$rel"
    [[ -e $dest || -L $dest ]] || continue
    [[ -d $dest && ! -L $dest ]] && continue
    current=$(readlink -f "$dest" 2>/dev/null || true)
    target=$(readlink -f "$src")
    [[ $current == "$target" ]] && continue
    mkdir -p "$backup/$(dirname "$rel")"
    mv "$dest" "$backup/$rel"
    moved=$((moved + 1))
done < <(find "$PKG" -type f -print0)

if (( moved > 0 )); then
    warn "moved $moved existing file(s) to $backup"
fi

log "stow home -> $HOME"
stow --no-folding -v -t "$HOME" -d "$DOTFILES_ROOT" home
ok "configs linked"
