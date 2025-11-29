#!/usr/bin/env bash

makefile_list="$1"

awk '
BEGIN {
        FS = ":.*?## "
        maxlen = 0
        n = 0
}

/^[a-zA-Z_-]+:.*?## / {
        targets[n] = $1
        descriptions[n] = $2
        if (length($1) > maxlen) {
                maxlen = length($1)
        }
        n++
}

END {
        for (i = 0; i < n; i++) {
                printf "  %-*s %s\n", maxlen, targets[i], descriptions[i]
        }
}
' "$makefile_list"
