#!/bin/sh
# THE HOST A MEASUREMENT IS KEYED BY, the one definition: `<platform>-<machine>-<cpu>`, lowercased and
# tokenized (SPEED_HOST overrides). The CPU is in the key because two x86_64 Linux machines (a Sprite and
# a runner) are not one machine, and a ceiling recorded on one must never judge the other. A Mac that
# delegates to its Sprite keys the number the Sprite's.
token() { printf '%s' "$1" | tr 'A-Z' 'a-z' | tr -cs 'a-z0-9' '-' | sed 's/^-*//;s/-*$//'; }
cpu() {
    if [ -r /proc/cpuinfo ]; then
        awk -F: '/model name/ { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit }' /proc/cpuinfo
    else
        sysctl -n machdep.cpu.brand_string 2>/dev/null || uname -p
    fi
}
echo "${SPEED_HOST:-$(token "$(uname -s)")-$(token "$(uname -m)")-$(token "$(cpu)")}"
