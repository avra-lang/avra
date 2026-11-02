#!/bin/sh
# ONE STORE, TWO PRINTS: a package whose files instance a dependency's components is
# checked by one compiler, then by another print over the same store. Every row the
# second reads must be one it can stand on, so it answers what a cold check answers.
#
#   sh tools/print_mix_attack.sh
set -u
A=$(pwd)/avra
R=$(pwd)/build/print-mix-attack
fails=0; cases=0
find "$R" -delete 2>/dev/null; mkdir -p "$R/src/commands"
printf '[package]\nname = "print-mix"\nversion = "0.1.0"\n' > "$R/avra.toml"
cat > "$R/src/commands/greet.av" <<'AV'
use @std.cli.{command, flag, Runnable, CliResult}

type Greet = {}

impl Runnable for Greet {
    fn run(args: CliResult) -> int { if args.has_flag("loud") { 1 } else { 0 } }
}

export command greet {
    description: "Say hello"
    flag loud { description: "shout" }
    run: Greet {}
}
AV
cat > "$R/src/main.av" <<'AV'
use @std.cli.{cli}
use commands.{greet}

cli app {
    description: "print-mix"
    greet
}
AV
check() {
    cases=$((cases + 1))
    if [ "$2" = 0 ]; then echo "print-mix-attack: $1"; else fails=$((fails + 1)); echo "print-mix-attack: FAILED — $1 (status $2)"; cat "$R/out"; fi
}
"$A" check "$R" > "$R/out" 2>&1; check "a cold check is clean" $?
AVRA_INLINE_RUNTIME=0 "$A" check "$R" > "$R/out" 2>&1; check "another print over the same store is clean" $?
echo "// edited" >> "$R/src/commands/greet.av"
AVRA_INLINE_RUNTIME=0 "$A" check "$R" > "$R/out" 2>&1; check "and after an edit, still clean" $?
"$A" check "$R" > "$R/out" 2>&1; check "the first print after the edit is clean" $?
[ $fails -eq 0 ] || { echo "print-mix-attack: $fails of $cases FAILED"; exit 1; }
echo "print-mix-attack: $cases cases passed"
