#!/bin/sh
# THE GATE'S RECEIPT NAMES THE TREE IT PROVED. A green gate is a fact
# about one tree, and the integrator used to re-establish that fact
# for a tree it already had a receipt for: when main has not moved
# since the lane gated, the merge takes the lane's own tree and the
# second gate is the first one again, 8 to 20 minutes per PR.
#
# The receipt is `build/.gate-green` (per worktree, ignored, gone with
# `make clean`): one line, the TREE HASH the gate read, then HEAD and
# the date for a reader. A missing or stale receipt means a full gate,
# which is the safe direction and the default.
#
# IT IS WRITTEN ONLY FOR A CLEAN TREE. `make gate` reads the WORKING
# tree; `HEAD^{tree}` names the committed one. They differ exactly
# when something is uncommitted, and a receipt written then would name
# a tree the gate never read — the lie this whole mechanism must not
# tell. A dirty gate writes no receipt and says so.
#
# A RECEIPT NAMES ITS TREE OR REFUSES TO BE ONE. Refusal is a REAL
# failure — stderr carries the reason, the exit code carries the
# refusal — never the "declined, and that is fine" contract a dirty
# tree gets. A caller that must not let a decline read as a gate
# failure (`make gate`) discards the status at its own call site.
#
# EVERY VERB IS A FUNCTION AND THE FIXTURES CALL THE FUNCTIONS. The
# first draft had `write` run the fixtures first — "an instrument
# proves itself before it certifies anything" — and the fixtures
# invoke `write`: 986 self-tests and 985 writes in one parent-child
# chain, 2441 of this machine's 2666 fork limit, and every OTHER
# session's builds died on `fork: Resource temporarily unavailable`.
# A FORK BOMB LOOKS LIKE UNRELATED WORK BREAKING, which is what made
# it cost three sessions rather than one. The shape is the fix, never
# a depth counter: a self-test that cannot re-enter the entry point
# cannot recurse, and the fixtures still exercise the real verbs.
set -e

# The receipt for a worktree's own tree, written only when the working
# tree is the committed one. A DIRTY tree declines and answers 0. A
# tree naming no git commit at all cannot decline this way — there is
# no tree to name — so it fails instead: stderr says why, exit 1.
receipt_write() {
    root="$1"
    receipt="$root/build/.gate-green"
    if ! tree="$(git -C "$root" rev-parse --verify -q HEAD^{tree} 2>/dev/null)" || [ -z "$tree" ]; then
        rm -f "$receipt"
        echo "gate: $root names no git tree (no .git here, or no commit yet) — no receipt written, an integration gates this tree itself" >&2
        return 1
    fi
    if [ -n "$(git -C "$root" status --porcelain)" ]; then
        rm -f "$receipt"
        echo "gate: green over a DIRTY tree — no receipt written (the integrator will gate its own)"
        return 0
    fi
    mkdir -p "$root/build"
    printf '%s %s %s\n' "$tree" "$(git -C "$root" rev-parse HEAD)" \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$receipt"
    echo "gate: receipt for tree $(cut -c1-12 "$receipt") — an integration taking this exact tree may trust it"
}

# Whether a worktree's receipt names EXACTLY this tree. Every other
# answer is 1 — no receipt, an unreadable one, another tree — all
# meaning a gate is owed.
#
# STDOUT CARRIES CONSENT AND NOTHING ELSE; every refusal explains
# itself on STDERR. A REFUSAL THAT EXPLAINS ITSELF ON THE SAME
# CHANNEL AS ITS CONSENT IS A TRAP FOR THE NEXT CALLER, and this one
# sprang on its first integration: the reason printed on stdout, the
# caller read stdout and swallowed the status, so "no receipt in
# …/build" READ AS PERMISSION and the skip fired exactly where it
# must not. The caller was fixed to test the status; this makes the
# CONTRACT fail safe instead — stdout is non-empty if and only if the
# tree is trusted, so a caller that ignores the status refuses rather
# than trusts, and the reason still reaches the log.
receipt_trusts() {
    receipt="$1/build/.gate-green"
    [ -f "$receipt" ] || { echo "no receipt in $1/build" >&2; return 1; }
    read -r tree head when < "$receipt" || { echo "the receipt is unreadable" >&2; return 1; }
    [ -n "$tree" ] && [ "$tree" = "$2" ] || { echo "the receipt names tree ${tree:-?}, this integration takes $2" >&2; return 1; }
    echo "$head at $when"
}

# BOTH DIRECTIONS, because a skip that cannot refuse is worse than no
# skip at all: the matching tree is trusted, and ONE BYTE anywhere is
# not. The fixtures call the verbs above directly.
self_test() {
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    lane="$tmp/lane"
    mkdir -p "$lane"
    git init -q "$lane"
    git -C "$lane" config user.email t@e
    git -C "$lane" config user.name t
    echo "one" > "$lane/a.txt"
    printf 'build/\n' > "$lane/.gitignore"
    git -C "$lane" add -A
    git -C "$lane" commit -q -m one
    receipt_write "$lane" > /dev/null
    tree="$(git -C "$lane" rev-parse HEAD^{tree})"
    receipt_trusts "$lane" "$tree" > /dev/null || { echo "gate_receipt: a matching tree was NOT trusted"; return 1; }
    echo "two" > "$lane/a.txt"
    git -C "$lane" add -A
    git -C "$lane" commit -q -m two
    changed="$(git -C "$lane" rev-parse HEAD^{tree})"
    [ "$changed" != "$tree" ] || { echo "gate_receipt: the fixture changed nothing"; return 1; }
    if receipt_trusts "$lane" "$changed" > /dev/null 2>&1; then
        echo "gate_receipt: a CHANGED tree was trusted — the skip cannot refuse"; return 1
    fi
    rm -f "$lane/build/.gate-green"
    echo "three" > "$lane/a.txt"
    receipt_write "$lane" > /dev/null
    [ ! -f "$lane/build/.gate-green" ] || { echo "gate_receipt: a DIRTY gate wrote a receipt"; return 1; }
    if receipt_trusts "$lane" "$changed" > /dev/null 2>&1; then
        echo "gate_receipt: a MISSING receipt was trusted"; return 1
    fi
    # A TREE WITH NO GIT AT ALL (the Sprite's synced copy) and its
    # sibling WITH git but NO COMMIT YET both name no tree to write a
    # receipt for — `write` must refuse loudly, never print one with
    # a blank field.
    gitless="$tmp/gitless"
    mkdir -p "$gitless"
    if receipt_write "$gitless" > /dev/null 2>"$tmp/gitless.err"; then
        echo "gate_receipt: a GITLESS tree's write did not refuse"; return 1
    fi
    [ ! -f "$gitless/build/.gate-green" ] || { echo "gate_receipt: a GITLESS tree wrote a receipt"; return 1; }
    [ -s "$tmp/gitless.err" ] || { echo "gate_receipt: a gitless refusal said nothing on stderr"; return 1; }
    nocommit="$tmp/nocommit"
    mkdir -p "$nocommit"
    git init -q "$nocommit"
    if receipt_write "$nocommit" > /dev/null 2>"$tmp/nocommit.err"; then
        echo "gate_receipt: a NO-COMMIT tree's write did not refuse"; return 1
    fi
    [ ! -f "$nocommit/build/.gate-green" ] || { echo "gate_receipt: a NO-COMMIT tree wrote a receipt"; return 1; }
    [ -s "$tmp/nocommit.err" ] || { echo "gate_receipt: a no-commit refusal said nothing on stderr"; return 1; }
    # THE CALLING CONVENTION IS PART OF THE CONTRACT, and the fixtures
    # above test only the status — which is how a caller reading
    # STDOUT shipped a skip that fired on "no receipt". A caller that
    # ignores the status must refuse, so stdout is checked here the
    # way that caller read it.
    said="$(receipt_trusts "$lane" "$changed" 2>/dev/null || true)"
    [ -z "$said" ] || { echo "gate_receipt: a refusal put words on stdout — a status-blind caller reads them as consent"; return 1; }
    git -C "$lane" add -A
    git -C "$lane" commit -q -m three
    receipt_write "$lane" > /dev/null
    said="$(receipt_trusts "$lane" "$(git -C "$lane" rev-parse HEAD^{tree})" 2>/dev/null || true)"
    [ -n "$said" ] || { echo "gate_receipt: consent said nothing on stdout"; return 1; }
    echo "gate_receipt: self-test passed — 8 fixtures"
}

case "$1" in
write)      receipt_write "${2:-$(cd "$(dirname "$0")/.." && pwd)}" ;;
trusts)     receipt_trusts "$2" "$3" ;;
--self-test) self_test ;;
*)
    echo "usage: gate_receipt.sh write | trusts <worktree> <tree> | --self-test" >&2
    exit 2
    ;;
esac
