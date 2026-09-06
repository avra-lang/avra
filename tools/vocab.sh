#!/bin/sh
# THE VOCABULARY GATE. Growing the IR is allowed — performance is a
# first-class reason (P4) — and it is SAFE for exactly one reason:
# every consumer of `Ins` dispatches EXHAUSTIVELY, so a new variant
# breaks all of them at compile time and cannot ship half-implemented.
#
# This script is that guarantee's keeper AND the consumer registry:
# the list below is the authoritative answer to "what does a new
# instruction owe?", and the gate fails if any of these dispatches
# grows a `_ ->` catch-all, which would let the next variant slip
# through unimplemented.
set -e
cd "$(dirname "$0")/.."

# file <TAB> dispatch fn <TAB> what it decides
CONSUMERS="packages/std-avrac/src/core/ir.av	dst_of	the register it defines
packages/std-avrac/src/language/interp.av	step	its MEANING, interpreted
packages/std-avrac/src/language/memory.av	memory_ins	its ownership effect
packages/std-avrac/src/language/ir_text.av	body_lines	its human projection
packages/std-avrac/src/language/llvm.av	emit_ins	its machine projection
packages/std-avrac/src/features/facts.av	give	whether the runtime registry validates it
packages/std-avrac/src/core/ir.av	body_symbol	the program body it names
packages/std-avrac/src/core/ir.av	hosted_symbol	the hosted fn it calls"

# A here-doc, not a pipe: the loop runs in THIS shell, so `exit 1`
# ends the script rather than a subshell the gate never sees.
while IFS='	' read -r file fn what; do
  if [ ! -f "$file" ]; then
    echo "vocab: $file is gone — the consumer registry is stale"
    exit 1
  fi
  hit=$(awk -v fn="$fn" '
    $0 ~ "^ *(export )?fn " fn "\\(" { inside = 1 }
    inside && /_ ->/ { print FNR ": " $0 }
    inside && /^ *}$/ && inside { inside = 0 }
  ' "$file")
  if [ -n "$hit" ]; then
    echo "vocab: ${file}:${fn} decides ${what} and grew a catch-all:"
    echo "$hit" | sed 's/^/    /'
    echo "  A catch-all here lets the NEXT instruction ship unimplemented."
    echo "  Spell the arms — or-runs keep it affordable."
    exit 1
  fi
done <<EOF
$CONSUMERS
EOF

# THE SECOND REGISTRY. `RtKind` is the extern seam's width vocabulary,
# and it has consumers exactly as `Ins` does — but it stayed three
# variants for so long that nothing guarded them, and two of its
# consumers had become `is .I64` BOOLEAN tests rather than matches. An
# `is` test is a partial handler the compiler cannot see: grow the
# enum and it silently answers "no" for every new kind, which at these
# two sites means an argument crosses the boundary UNCONVERTED. So a
# catch-all is refused here AND so is `is .` — both are ways of not
# answering for a variant that does not exist yet.
KIND_CONSUMERS="packages/std-avrac/src/language/llvm.av	ll_rt_kind	the LLVM type it becomes
packages/std-avrac/src/language/llvm.av	rt_arg	how an argument crosses the boundary
packages/std-avrac/src/language/llvm.av	answers_word	how an answer crosses back"

while IFS='	' read -r file fn what; do
  if [ ! -f "$file" ]; then
    echo "vocab: $file is gone — the RtKind consumer registry is stale"
    exit 1
  fi
  hit=$(awk -v fn="$fn" '
    $0 ~ "^ *(export )?fn " fn "\\(" { inside = 1 }
    inside && (/_ ->/ || / is \./) { print FNR ": " $0 }
    inside && /^ *}$/ && inside { inside = 0 }
  ' "$file")
  if [ -n "$hit" ]; then
    echo "vocab: ${file}:${fn} decides ${what} and does not answer exhaustively:"
    echo "$hit" | sed 's/^/    /'
    echo "  A catch-all or an \`is .Variant\` test here lets the NEXT RtKind"
    echo "  cross the extern boundary unconverted. Spell the arms."
    exit 1
  fi
done <<EOF
$KIND_CONSUMERS
EOF

echo "vocab: Ins has $(echo "$CONSUMERS" | wc -l | tr -d ' ') exhaustive consumers and RtKind $(echo "$KIND_CONSUMERS" | wc -l | tr -d ' '); a new variant breaks them all"
