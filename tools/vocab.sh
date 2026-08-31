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
packages/std-avrac/src/language/lower.av	give	whether the runtime registry validates it"

fail=0
echo "$CONSUMERS" | while IFS='	' read -r file fn what; do
  if [ ! -f "$file" ]; then
    echo "vocab: $file is gone — the consumer registry is stale"
    exit 1
  fi
  hit=$(awk -v fn="$fn" '
    $0 ~ "^(export )?fn " fn "\\(" { inside = 1 }
    inside && /_ ->/ { print FNR ": " $0 }
    inside && /^}/ { inside = 0 }
  ' "$file")
  if [ -n "$hit" ]; then
    echo "vocab: ${file}:${fn} decides ${what} and grew a catch-all:"
    echo "$hit" | sed 's/^/    /'
    echo "  A catch-all here lets the NEXT instruction ship unimplemented."
    echo "  Spell the arms — or-runs keep it affordable."
    exit 1
  fi
done

echo "vocab: Ins has 5 exhaustive consumers; a new variant breaks all 5"
