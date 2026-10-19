#!/bin/sh
# THE SHIM'S GUARD LAW, held by the shim itself: `AVRA_RC_GUARD` over a directory argument is
# refused with a voice naming a single program and the way past; over a file, or with the way past
# taken, it is not. Neither run reaches a compiler — a missing `AVRA_BIN` ends the shim's own path.
set -u
cd "$(dirname "$0")/.."
T=build/shim-guard-test; mkdir -p $T; : > $T/one.av
bad() { echo "shim-guard self-test: $1"; exit 1; }
run() { AVRA_BIN=build/none "$@" 2>&1; }
out=$(AVRA_RC_GUARD=1 run ./avra check $T); st=$?
[ "$st" = 2 ] || bad "a guarded package run exited $st, not 2"
case "$out" in *"name a file"*) ;; *) bad "the refusal does not name a single program: $out" ;; esac
case "$out" in *"no build/none"*) bad "the guarded package run reached the compiler lookup" ;; esac
out=$(AVRA_RC_GUARD=1 run ./avra check $T/one.av)
case "$out" in *"no build/none"*) ;; *) bad "a guarded single file was refused: $out" ;; esac
out=$(AVRA_RC_GUARD=1 AVRA_GUARDED_PACKAGE=1 run ./avra check $T)
case "$out" in *"no build/none"*) ;; *) bad "the way past did not pass: $out" ;; esac
out=$(AVRA_RC_GUARD=0 run ./avra check $T)
case "$out" in *"no build/none"*) ;; *) bad "an unset guard (0) refused a package run: $out" ;; esac
echo "shim-guard self-test: 5 cases passed"
