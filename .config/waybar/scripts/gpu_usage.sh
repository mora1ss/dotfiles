#!/bin/bash

util="$(nvtop -s 2>/dev/null | jq -r '.[0].gpu_util // empty' 2>/dev/null | tr -d '%')"

if [[ -z "$util" || "$util" == "null" ]]; then
    printf '%s\n' "0"
    exit 0
fi

printf '%s\n' "$util"
