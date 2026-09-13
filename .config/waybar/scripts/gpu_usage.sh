#!/usr/bin/env bash

is_number() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

if [[ -e /dev/nvidia0 ]] && command -v nvidia-smi >/dev/null 2>&1; then
    util="$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -d '[:space:]')"
    if is_number "$util"; then
        printf '%s\n' "$util"
        exit 0
    fi
fi

util="$(nvtop -s 2>/dev/null | jq -r '.[0].gpu_util // empty' 2>/dev/null | tr -d '%[:space:]')"

if ! is_number "$util"; then
    printf '%s\n' "0"
    exit 0
fi

printf '%s\n' "$util"
