#!/usr/bin/env bash

if command -v nvidia-smi >/dev/null 2>&1; then
    util="$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -d ' ')"
    if [[ -n "$util" && "$util" != "N/A" ]]; then
        printf '%s\n' "$util"
        exit 0
    fi
fi

util="$(nvtop -s 2>/dev/null | jq -r '.[0].gpu_util // empty' 2>/dev/null | tr -d '%')"

if [[ -z "$util" || "$util" == "null" ]]; then
    printf '%s\n' "0"
    exit 0
fi

printf '%s\n' "$util"
