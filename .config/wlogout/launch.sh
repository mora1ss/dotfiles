#!/usr/bin/env bash
# Centered power menu that scales to the focused monitor.
# The original rice used -L 1700 -R 1700 -T 325 -B 325, which only
# leaves room for buttons on a ~4K display. On a VM (or 1080p) that
# leftover space is negative, so you only see the grey overlay.

set -euo pipefail

if pgrep -x wlogout >/dev/null; then
    exit 0
fi

CONF="${XDG_CONFIG_HOME:-$HOME/.config}/wlogout"

width=""
height=""
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    read -r width height < <(
        hyprctl -j monitors 2>/dev/null | jq -r '
            .[] | select(.focused == true) |
            "\((.width / (.scale // 1)) | floor) \((.height / (.scale // 1)) | floor)"
        ' | head -n 1
    )
fi

if [[ -z "${width:-}" || -z "${height:-}" || "$width" -le 0 || "$height" -le 0 ]]; then
    width="${width:-1920}"
    height="${height:-1080}"
fi

# Compact vertical stack of 3 round buttons, centered.
col_w=$(( width * 12 / 100 ))
(( col_w < 160 )) && col_w=160
(( col_w > 280 )) && col_w=280

stack_h=$(( height * 48 / 100 ))
(( stack_h < 360 )) && stack_h=360
(( stack_h > 720 )) && stack_h=720
(( stack_h > height - 40 )) && stack_h=$(( height - 40 ))

ml=$(( (width - col_w) / 2 ))
mr=$ml
mt=$(( (height - stack_h) / 2 ))
mb=$mt

(( ml < 0 )) && ml=0
(( mr < 0 )) && mr=0
(( mt < 0 )) && mt=0
(( mb < 0 )) && mb=0

# GTK resolves CSS url() against CWD, not the stylesheet path.
cd "$CONF"

exec wlogout \
    -b 1 \
    -c 20 \
    -r 20 \
    -L "$ml" \
    -R "$mr" \
    -T "$mt" \
    -B "$mb" \
    -l "$CONF/layout" \
    -C "$CONF/style.css"
