#!/usr/bin/env bash
# Super+F10        → region capture, then Satty
# Super+Shift+F10  → focused monitor, save only (no Satty)

set -euo pipefail

out_dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$out_dir"
filename="$(date +%Y-%m-%d_%H-%M-%S).png"

case "${1:-region}" in
    output)
        hyprshot -m output -o "$out_dir" -f "$filename"
        ;;
    region)
        hyprshot -m region -s --raw | satty \
            --filename - \
            --output-filename "$out_dir/$filename"
        ;;
    *)
        printf 'usage: %s output|region\n' "$0" >&2
        exit 1
        ;;
esac
