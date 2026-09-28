#!/bin/sh
# THE FORMATTER'S REAL RECEIPT: `fmt(x) == x` for an already-canonical
# file — BYTE EQUALITY, never idempotence (`fmt(fmt(x)) == fmt(x)` stays
# green while a comment is being deleted, because the second pass has
# nothing left to lose — CLAUDE.md, "A CHECK CAN PASS BECAUSE OF THE
# BUG"). `tools/fmt_roundtrip.sh` counts comment CLASSES lost; this
# counts FILES that do not come back at all, whatever the cause —
# comment loss, a reordered annotation, a dropped `export`, layout.
#
# ONE PROCESS, TREE-WIDE: `avra fmt --check` walks every package
# under `root` itself, in a digest-keyed cache of its own
# (cli/commands/fmt.av, avra-8sb5.25.37) — the per-file `avra` this
# script once spawned (~730 times, ~30s of nothing but process
# launches) is gone; the whole tree now runs cold in seconds and warm
# in under one. GATE-CHECKED: the tree reports 0 differing
# (docs/2026_09_21_FORMATTER_DESIGN.md §4, §10 phase 4), and `avra fmt
# --check`'s own exit status IS this script's — 1 when anything
# differs, 0 otherwise.
set -u
avra=${AVRA:-build/avra}
root=${1:-.}
shift || true
if [ "$#" -gt 0 ]; then
    "$avra" fmt --check "$@"
else
    "$avra" fmt --check "$root/packages"
fi
