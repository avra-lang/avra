#!/bin/sh
# tool-witness: run by the gate's keeper slices (tools/gate.sh, a planted row ending each)
# A KEEPER SHOWN TO REFUSE: the keeper a plant names, run over a copy of this tree (HEAD, a worktree of
# its own, its build/ the tree's) with one fault planted in what the keeper judges. It holds, exit 0,
# only where the keeper refuses AND its words name the plant; a keeper that passes over its fault, or
# refuses for another reason, fails the row. Every keeper slice ends with one, so a slice whose keepers
# examined nothing is no slice that passes.
#
#   sh tools/keeper_planted.sh <plant>        a plant of PLANTS, named for its keeper
#   sh tools/keeper_planted.sh --list         each plant, one a line
#   sh tools/keeper_planted.sh --pick <k>…    the first of the keepers `k` that has a plant, else nothing
. "$(dirname "$0")/lib/scratch.sh"
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
PLANTS="fmt-lossless traps clock-holds wasm-refuses tool-witnesses runtime-tests witness-place-kill witness-machine-store inputs externs layers bash-parse dogfooding-rules rt-header pkgs-witness"
case ${1:-} in
    --list) printf '%s\n' $PLANTS; exit 0 ;;
    --pick)
        shift
        for k in "$@"; do
            case " $PLANTS " in *" $k "*) echo "$k"; exit 0 ;; esac
        done
        exit 0
        ;;
esac
plant=${1:?a plant: one of $PLANTS}
case " $PLANTS " in *" $plant "*) ;; *) echo "keeper_planted: no plant named $plant — one of $PLANTS"; exit 1 ;; esac
scratch_dir tmp
tree="$tmp/tree"
ended() {
    git -C "$root" worktree remove --force "$tree" >/dev/null 2>&1 || :
    rmdir "$tmp" 2>/dev/null || :
    git -C "$root" worktree prune >/dev/null 2>&1 || :
}
scratch_also ended
git -C "$root" worktree add -q --detach "$tree" HEAD || { echo "keeper_planted: no worktree of HEAD at $tree"; exit 1; }
ln -s "$root/build" "$tree/build"
cd "$tree" || exit 1

# the fault each plant writes into the copy, staged so a keeper reading the tracked files sees it, the
# words its refusal must hold, and the command that runs the keeper
run="make -s -o avra $plant"
case $plant in
    fmt-lossless)
        printf '\nfn  planted_spacing() -> int { 1 }\n' >>packages/std-text/src/text.av
        word='packages/std-text/src/text.av'
        ;;
    traps)
        sed -i.planted "s/^trapped printed_before_a_trap_native 'before$/trapped printed_before_a_trap_native 'planted-before/" tools/traps.sh
        word='printed_before_a_trap_native'
        ;;
    clock-holds)
        printf '#include <unistd.h>\nvoid avra_planted_wait(void) { sleep(1); }\n' >runtime/avra_planted.c
        word='avra_planted.c'
        ;;
    wasm-refuses)
        sed -i.planted "s/^check package '@std\/process' || fail=1$/check package '@std\/planted' || fail=1/" tools/wasm-refuses.sh
        word='@std/planted'
        ;;
    tool-witnesses)
        printf '#!/bin/sh\n[ "$1" = --self-test ] && exit 0\n' >tools/planted_selftest.sh
        word='planted_selftest.sh'
        ;;
    runtime-tests)
        printf '#include <stdio.h>\nint main(void) { puts("planted_test: a planted failure"); return 1; }\n' >runtime/tests/planted_test.c
        word='planted_test'
        ;;
    witness-place-kill | witness-machine-store)
        printf '#!/bin/sh\necho "planted compiler: it builds nothing"\nexit 1\n' >"$tmp/planted-avra"
        chmod +x "$tmp/planted-avra"
        run="sh tools/$(echo "$plant" | tr - _).sh $tmp/planted-avra"
        word='planted compiler'
        ;;
    inputs)
        printf 'use @std.io.{env}\n\nexport fn planted_read() -> string? { env("AVRA_PLANTED_READ") }\n' >packages/cli/src/commands/planted_read.av
        word='planted_read.av'
        ;;
    externs)
        printf 'extern fn avra_planted_width(n: int) -> int\n' >packages/cli/src/commands/planted_extern.av
        word='avra_planted_width'
        ;;
    layers)
        printf 'use compiler.{analyze}\n' >packages/std-avrac/src/core/planted_layer.av
        word='planted_layer.av'
        ;;
    bash-parse)
        printf '#!/bin/sh\nif then fi\n' >tools/planted_parse.sh
        word='planted_parse.sh'
        ;;
    dogfooding-rules)
        sed -i.planted '0,/^- closures\.pronoun_lambda /s//- closures.pronoun_lambda PLANTED /' DOGFOODING.md
        word='closures.pronoun_lambda'
        ;;
    rt-header)
        printf '/* planted: a row the rows do not say */\n' >>runtime/avra_rt.h
        word='planted: a row the rows do not say'
        ;;
    pkgs-witness)
        sed -i.planted 's/^named_suites() { printf .%s\\n. std-avrac /named_suites() { printf '"'"'%s\\n'"'"' std-queue_store std-avrac /' tools/gate.sh
        word='did not select std-queue_store'
        ;;
esac
find . -name '*.planted' -type f -exec rm -f {} + 2>/dev/null
git add -A . >/dev/null 2>&1
out=$(sh -c "$run" 2>&1)
st=$?
if [ "$st" = 0 ]; then
    echo "keeper_planted: $plant PASSED over its planted fault — a keeper that cannot refuse proves nothing"
    printf '%s\n' "$out" | tail -n 5
    exit 1
fi
if ! printf '%s\n' "$out" | grep -qF -- "$word"; then
    echo "keeper_planted: $plant refused, but not at its plant (\`$word\`) — it refused for another reason:"
    printf '%s\n' "$out" | tail -n 8
    exit 1
fi
echo "keeper_planted: $plant refused its planted fault, naming it (\`$word\`)"
