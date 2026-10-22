#!/bin/sh
# THE CONTENT STAMPS, ONE PROCESS FOR A MAKE. Make hands every stamp as three words — the stamp,
# the sources it hashes, the flags it was asked to compile under; the stamp's file is the digest
# of all three, and it is WRITTEN ONLY WHEN IT DIFFERS — an unchanged stamp keeps its mtime, so
# nothing downstream of it rebuilds. A stamp that moves takes its object with it: make compares
# mtimes to the second, so an object built in the same second as the stamp that retires it would
# otherwise read current.
#
# Plain POSIX shell: the stamps settle while make reads its own Makefile, before any compiler or
# interpreter beyond the platform's exists, so a cold machine builds Avra with no Python.
#
#   sh tools/stamps.sh <stamp> <sources> <flags> [<stamp> <sources> <flags>]…
#   sh tools/stamps.sh --self-test
set -eu

# sum: the SHA-256 of stdin, as 64 hex digits.
sum() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum; else shasum -a 256; fi | cut -d' ' -f1
}

# digest <sources> <flags>: the digest of each source's own hash and path, then the flags.
digest() {
    {
        for path in $1; do
            if [ -f "$path" ] && [ -r "$path" ]; then body=$(sum < "$path"); else body=-; fi
            printf '%s  %s\n' "$body" "$path"
        done
        printf 'flags: %s\n' "$2"
    } | sum
}

# stamped <stamp> <sources> <flags>: write the stamp when its digest moved, and retire its object.
stamped() {
    now=$(digest "$2" "$3")
    if [ -f "$1" ] && [ "$(cat "$1")" = "$now" ]; then return 0; fi
    mkdir -p "$(dirname "$1")"
    printf '%s\n' "$now" > "$1.tmp"
    mv -f "$1.tmp" "$1"
    object="${1%.sha}.o"
    if [ -e "$object" ]; then find "$object" -delete; fi
}

if [ "${1:-}" = --self-test ]; then
    d=$(mktemp -d)
    printf 'a' > "$d/a.c"
    stamped "$d/x.sha" "$d/a.c" "-O2"
    first=$(cat "$d/x.sha")
    : > "$d/x.o"
    stamped "$d/x.sha" "$d/a.c" "-O2"
    [ -f "$d/x.o" ] || { echo "stamps: an unchanged stamp retired its object"; exit 1; }
    stamped "$d/x.sha" "$d/a.c" "-O3"
    [ "$(cat "$d/x.sha")" != "$first" ] || { echo "stamps: a moved flag did not move the stamp"; exit 1; }
    [ ! -f "$d/x.o" ] || { echo "stamps: a moved stamp left its object"; exit 1; }
    stamped "$d/y.sha" "$d/gone.c" "-O2"
    [ "$(wc -c < "$d/y.sha" | tr -d ' ')" = 65 ] || { echo "stamps: a missing source did not stamp"; exit 1; }
    echo "stamps: self-test passed — written only on change, a moved stamp retires its object, a missing source stamps"
    exit 0
fi

while [ "$#" -ge 3 ]; do
    stamped "$1" "$2" "$3"
    shift 3
done
