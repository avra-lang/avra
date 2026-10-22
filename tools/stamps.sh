#!/bin/sh
# tool-witness: --self-test
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

# sum: the SHA-256 of stdin, as 64 hex digits; sums <file>...: `<hash>  <file>` a line, in ONE process.
sum() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum; else shasum -a 256; fi | cut -d' ' -f1
}
sums() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$@"; else shasum -a 256 "$@"; fi
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

# settle <stamp> <digest>: write the stamp when its digest moved, and retire its object.
settle() {
    old=""
    [ ! -f "$1" ] || IFS= read -r old < "$1" || :
    [ "$old" != "$2" ] || return 0
    mkdir -p "$(dirname "$1")"
    printf '%s\n' "$2" > "$1.tmp"
    mv -f "$1.tmp" "$1"
    object="${1%.sha}.o"
    if [ -e "$object" ]; then find "$object" -delete; fi
}

stamped() { settle "$1" "$(digest "$2" "$3")"; }

# all <stamp> <sources> <flags>…: every stamp at once, answering exactly what `stamped`
# answers — each source hashed once and every stamp's text hashed, in two processes.
all() {
    w=$(mktemp -d)
    i=0
    : > "$w/list"
    while [ "$#" -ge 3 ]; do
        i=$((i + 1))
        printf '%s\n' "$1" > "$w/$i.stamp"
        for p in $2; do printf 'S %s %s\n' "$i" "$p"; done >> "$w/list"
        printf 'F %s %s\n' "$i" "$3" >> "$w/list"
        shift 3
    done
    [ "$i" -gt 0 ] || { find "$w" -delete; return 0; }
    files=$(awk '$1 == "S" { print $3 }' "$w/list" | sort -u | while IFS= read -r p; do if [ -f "$p" ] && [ -r "$p" ]; then echo "$p"; fi; done)
    # shellcheck disable=SC2086
    { [ -z "$files" ] || sums $files; } > "$w/hashes"
    awk -v w="$w" 'FNR == NR { h[substr($0, index($0, "  ") + 2)] = $1; next }
        { rest = substr($0, length($1 " " $2 " ") + 1); out = w "/" $2 ".text" }
        $1 == "S" { print ((rest in h) ? h[rest] : "-") "  " rest > out }
        $1 == "F" { print "flags: " rest > out; close(out) }' "$w/hashes" "$w/list"
    n=0 texts=""
    while [ "$n" -lt "$i" ]; do n=$((n + 1)); texts="$texts $n.text"; done
    # shellcheck disable=SC2086
    (cd "$w" && sums $texts) > "$w/digests"
    while read -r dg f; do
        IFS= read -r stamp < "$w/${f%.text}.stamp"
        settle "$stamp" "$dg"
    done < "$w/digests"
    find "$w" -delete
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
    printf 'b' > "$d/b.c"
    all "$d/p.sha" "$d/a.c $d/b.c" "-O2" "$d/q.sha" "$d/a.c" "" "$d/r.sha" "$d/gone.c $d/b.c" "-g -O1"
    for s in "p:$d/a.c $d/b.c:-O2" "q:$d/a.c:" "r:$d/gone.c $d/b.c:-g -O1"; do
        name=${s%%:*} rest=${s#*:}
        [ "$(cat "$d/$name.sha")" = "$(digest "${rest%%:*}" "${rest#*:}")" ] || { echo "stamps: the batch disagreed with one stamp's digest ($name)"; exit 1; }
    done
    echo "stamps: self-test passed — written only on change, a moved stamp retires its object, a missing source stamps, the batch answers each stamp's own digest"
    exit 0
fi

all "$@"
