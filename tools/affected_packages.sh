#!/bin/sh
# WHICH PACKAGES A LANDING MUST TEST — from a diff's own touched files,
# never from a guess. `sh tools/affected_packages.sh <base> <branch>
# [<repo-root>]` prints one package NAME per line on stdout
# (`packages/<name>`, as a path a caller hands straight to `build/avra
# test`), and its reasoning on stderr.
#
# `--touched` first answers the touched packages alone, no dependents:
# what a PR's own check runs, the train running the rest.
#
# THE ROOT IS AN ARGUMENT, NEVER THIS SCRIPT'S OWN LOCATION: a caller
# tests a DIFFERENT tree than the one this copy of the script happens to
# live in, so a root guessed from `$0` would read the wrong tree's
# packages. Omitted, it falls back to the git repo standing at the
# CURRENT directory.
#
# THE RULE: every package the diff touched, plus every package that
# REACHES one of them — a `use @std.<x>` in its own source, or an
# explicit `path = "…"` row under its manifest's `[dependencies]` (none
# exist in this tree today; the read stays generic so a future package
# that adds one is caught without a second script). A DEPENDENT is
# found by the graph, never assumed: two rounds of reverse-lookup would
# miss a three-deep chain, so the closure runs until it stops growing.
#
# A CHANGE UNDER packages/std-avrac, packages/cli, packages/std-meta,
# packages/std-relation (the kernel every compile runs through) OR
# runtime/ IS A COMPILER CHANGE: every package's own build depends on
# the compiler that builds it, so the affected set is then everything —
# the one case an import graph cannot capture, since the compiler is
# not `use`d, it is invoked.
set -eu

usage="usage: sh tools/affected_packages.sh [--touched] <base-ref> <branch-ref> [<repo-root>]"
touched_only=0
[ "${1:-}" != --touched ] || { touched_only=1; shift; }
base="${1:?$usage}"
branch="${2:?$usage}"
root="${3:-$(git rev-parse --show-toplevel)}"
cd "$root"

touched_files="$(git diff --name-only "$base...$branch" 2>&1)" || {
    echo "affected_packages: git diff $base...$branch failed:" >&2
    echo "$touched_files" >&2
    exit 1
}

# Every package this tree carries: its directory name and, when its
# manifest names a `@std/…` package, the word a `use @std.<word>` spells.
all_pkgs=""
for d in packages/*/; do
    name="$(basename "$d")"
    all_pkgs="$all_pkgs $name"
done

# The word each package answers to, read ONCE: "<word> <name>" per line.
# A package that is not `@std/*` is never `use`d that way and has no row.
words_of="$(for d in packages/*/; do
    w="$(sed -nE 's/^[[:space:]]*name[[:space:]]*=[[:space:]]*"@std\/([^"]+)".*/\1/p' "${d}avra.toml" 2>/dev/null | head -1)"
    [ -z "$w" ] || echo "$w $(basename "$d")"
done)"

# edges: "depender dependee" pairs, one per line — POSIX sh has no maps,
# and a package count in the dozens makes a linear scan of pairs cheap
# enough that a real table would only add a second bug surface.
edges=""
for d in packages/*/; do
    name="$(basename "$d")"
    [ -d "${d}src" ] || continue
    # @std/* reached by a `use` — the implicit door every package walks
    # through with no manifest row (the toolchain resolves it, not the
    # manifest; see CLAUDE.md's `@std/*` law).
    used="$(grep -rhoE 'use @std\.[A-Za-z_][A-Za-z0-9_]*' "${d}src" 2>/dev/null \
        | sed -E 's/use @std\.//' | sort -u)"
    for w in $used; do
        for oname in $(printf '%s\n' "$words_of" | sed -n "s/^$w //p"); do
            [ "$oname" = "$name" ] || edges="$edges
$name $oname"
        done
    done
    # An explicit manifest dependency row: `"@x/y" = { path = "../y" }`,
    # read generically so the day one lands this needs no second pass.
    if [ -f "${d}avra.toml" ]; then
        paths="$(grep -E '\{\s*path\s*=' "${d}avra.toml" 2>/dev/null \
            | sed -E 's/.*path\s*=\s*"([^"]+)".*/\1/')"
        for p in $paths; do
            resolved="$(cd "$d" 2>/dev/null && cd "$p" 2>/dev/null && pwd)" || continue
            edges="$edges
$name $(basename "$resolved")"
        done
    fi
done

# Every package a diff's files stand in.
touched_pkgs=""
for f in $touched_files; do
    case "$f" in
        packages/*/*)
            name="$(printf '%s\n' "$f" | sed -E 's#^packages/([^/]+)/.*#\1#')"
            case " $touched_pkgs " in *" $name "*) ;; *) touched_pkgs="$touched_pkgs $name" ;; esac
            ;;
    esac
done

# `--touched` stops here: a PR's own check runs the packages its diff
# stands in, and their dependents are the train's to run.
if [ "$touched_only" -eq 1 ]; then
    echo "affected_packages: touched:$touched_pkgs — dependents left to the train" >&2
    for name in $touched_pkgs; do echo "$name"; done
    exit 0
fi

compiler_changed=0
for f in $touched_files; do
    case "$f" in
        packages/std-avrac/*|packages/cli/*|packages/std-meta/*|packages/std-relation/*|runtime/*) compiler_changed=1 ;;
    esac
done

if [ "$compiler_changed" -eq 1 ]; then
    echo "affected_packages: the compiler changed (packages/std-avrac, packages/cli, packages/std-meta, packages/std-relation or runtime/) — testing every package" >&2
    for name in $all_pkgs; do echo "$name"; done
    exit 0
fi

if [ -z "$touched_files" ]; then
    echo "affected_packages: no files differ between $base and $branch — nothing to test" >&2
    exit 0
fi

if [ -z "$(echo "$touched_pkgs" | tr -d ' ')" ]; then
    echo "affected_packages: the diff touches no package (tools/, docs/, …) — nothing to test" >&2
    exit 0
fi

# The closure: keep adding a package that DEPENDS ON one already in the
# set, until a whole pass adds none.
affected="$touched_pkgs"
grew=1
while [ "$grew" -eq 1 ]; do
    grew=0
    echo "$edges" | while IFS=' ' read -r depender dependee; do
        [ -z "$depender" ] && continue
        case " $affected " in *" $dependee "*) ;; *) continue ;; esac
        case " $affected " in *" $depender "*) continue ;; esac
        echo "$depender"
    done > /tmp/affected_packages.$$.new
    while read -r add; do
        [ -z "$add" ] && continue
        case " $affected " in *" $add "*) ;; *) affected="$affected $add"; grew=1 ;; esac
    done < /tmp/affected_packages.$$.new
    rm -f /tmp/affected_packages.$$.new
done

echo "affected_packages: touched:$touched_pkgs — affected set (with dependents):$affected" >&2
for name in $affected; do echo "$name"; done
