#!/bin/sh
# THE VOCABULARY GATE. Growing the IR is allowed — performance is a
# first-class reason (P4) — and it is SAFE for exactly one reason:
# every consumer of `Ins` dispatches EXHAUSTIVELY, so a new variant
# breaks all of them at compile time and cannot ship half-implemented.
#
# The same law covers every REGISTRY enum, not only `Ins`: a registry
# this table does not NAME is unguarded, so naming it is how the law
# reaches it. And `is .Variant` is refused beside `_ ->`, because over
# a registry the two say the same thing — this variant, and silence
# for the ones that do not exist yet.
#
# ONE TABLE, THREE REGISTRIES. It was two loops with two messages
# saying the same thing in different words; the third registry is what
# named the concept. A row is: the enum, the file, the dispatch fn,
# and what it decides.
#
# WHAT IS NOT HERE IS A DECISION, NOT AN OVERSIGHT. Only a REGISTRY
# belongs — two or more arms answering. A PROJECTION (one arm answers,
# the catch-all honest for variants that do not exist yet) is right to
# use `is`, and naming it here would demand ceremony: `needs` in
# expr_spine/check.av asks whether a shape is the ERROR ABSORBER, and
# a new type is never the absorber.
set -e
cd "$(dirname "$0")/.."

# enum <TAB> file <TAB> dispatch fn <TAB> what it decides
CONSUMERS="Ins	packages/std-avrac/src/core/ir.av	dst_of	the register it defines
Ins	packages/std-avrac/src/language/interp.av	step	its MEANING, interpreted
Ins	packages/std-avrac/src/language/memory.av	memory_ins	its ownership effect
Ins	packages/std-avrac/src/language/memory.av	managed_dst	whether its answer is the caller's to release
Ins	packages/std-avrac/src/language/ir_text.av	body_lines	its human projection
Ins	packages/std-avrac/src/language/llvm.av	emit_ins	its machine projection
Ins	packages/std-avrac/src/features/facts.av	give	whether the runtime registry validates it
Ins	packages/std-avrac/src/core/ir.av	body_symbol	the program body it names
Ins	packages/std-avrac/src/core/ir.av	hosted_symbol	the hosted fn it calls
RtKind	packages/std-avrac/src/language/llvm.av	ll_rt_kind	the LLVM type it becomes
RtKind	packages/std-avrac/src/language/llvm.av	rt_arg	how an argument crosses the boundary
RtKind	packages/std-avrac/src/language/llvm.av	answers_word	how an answer crosses back
RtKind	packages/std-avrac/src/language/llvm.av	answered	the SIGN a narrow answer widens with
RtKind	packages/std-avrac/src/language/llvm.av	narrow_sign	the SIGN an inout cell normalises with
RtKind	packages/std-avrac/src/language/interp.av	stage_seat	how an argument crosses, interpreted
RtKind	packages/std-avrac/src/language/interp.av	answered	how an answer crosses back, interpreted
RtKind	packages/std-avrac/src/language/interp.av	rides_fp	which register file a seat rides
RtKind	packages/std-avrac/src/language/interp.av	carries_cell	whether a seat holds an inout's address
RtKind	packages/std-avrac/src/language/interp.av	carries_text	whether a seat could carry text across the seam
Type	packages/std-avrac/src/features/checks.av	comparable	which shapes equality may compare
Type	packages/std-avrac/src/features/str_lit/check.av	printable	which shapes an interpolation hole may show
Type	packages/std-avrac/src/language/llvm.av	names_a_name	which shapes a callee reads as a NUL-terminated name
Type	packages/std-avrac/src/core/types.av	ptr_shape	whether a shape travels as a pointer
Type	packages/std-avrac/src/features/unify.av	slot_worthy	which shapes a slot may hold
Type	packages/std-avrac/src/language/llvm.av	ll_type_of	the LLVM type a shape becomes
Type	packages/std-avrac/src/language/llvm.av	slot_form	which conversion a category owes the word slot
SlotForm	packages/std-avrac/src/language/llvm.av	worded	the cast INTO the slot
SlotForm	packages/std-avrac/src/language/llvm.av	unworded	the cast back out of it
SlotForm	packages/std-avrac/src/language/llvm.av	answer_form	which of them survives a non-word answer
RtHost	packages/std-avrac/src/language/interp.av	rt_dispatch	the arm that evaluates a row
Type	packages/std-avrac/src/features/crossing.av	kind_of	which @std/meta shape it crosses as
Kind	packages/std-avrac/src/features/crossing.av	meta_of_kind	how it crosses into the evaluator
Kind	packages/std-meta/src/meta.av	spelled	the words it is written with"

# A here-doc, not a pipe: the loop runs in THIS shell, so `exit 1`
# ends the script rather than a subshell the gate never sees.
# SELF-TEST, both surfaces: a catch-all AFTER a braced arm is refused
# (the shape that once ended the scan), and its clean twin passes.
selftest=$(mktemp)
cat > "$selftest" <<'FIX'
fn probe(i: Ins) -> int {
    match i {
        .A -> {
            1
        }
        _ -> 0,
    }
}
fn clean(i: Ins) -> int {
    match i {
        .A -> {
            1
        }
        .B -> 0,
    }
}
FIX
count() { awk -v fn="$2" '
    !inside && $0 ~ "^ *(export )?fn " fn "\\(" {
      inside = 1; match($0, /^ */); close_rx = "^" substr($0, 1, RLENGTH) "}$"
    }
    inside { seen++ }
    inside && $0 ~ close_rx { inside = 0 }
    END { print seen+0 }
  ' "$1"; }
scan() { awk -v fn="$2" '
    !inside && $0 ~ "^ *(export )?fn " fn "\\(" {
      inside = 1; match($0, /^ */); close_rx = "^" substr($0, 1, RLENGTH) "}$"
    }
    inside && (/_ ->/ || / is \./) { print FNR ": " $0 }
    inside && $0 ~ close_rx { inside = 0 }
  ' "$1"; }
[ -n "$(scan "$selftest" probe)" ] || { echo "vocab: SELF-TEST — a catch-all after a braced arm was not seen"; exit 1; }
[ -z "$(scan "$selftest" clean)" ] || { echo "vocab: SELF-TEST — a clean dispatch was refused"; exit 1; }
rm -f "$selftest"

examined=""
while IFS='	' read -r enum file fn what; do
  [ -n "$file" ] || continue
  if [ ! -f "$file" ]; then
    echo "vocab: $file is gone — the $enum consumer registry is stale"
    exit 1
  fi
  # A fn ends at the `}` on ITS OWN indent, never at the first
  # closing brace: a braced arm closes deeper, and ending there read
  # three of nine `Ins` consumers only up to their first arm.
  hit=$(scan "$file" "$fn")
  examined="$examined $fn:$(count "$file" "$fn")"
  if [ -n "$hit" ]; then
    echo "vocab: ${file}:${fn} decides ${what} and does not answer exhaustively:"
    echo "$hit" | sed 's/^/    /'
    echo "  A catch-all — or an \`is .Variant\` test, which is a catch-all in"
    echo "  different clothes — lets the NEXT $enum variant ship unhandled."
    echo "  Spell the arms; or-runs keep it affordable."
    exit 1
  fi
done <<EOF
$CONSUMERS
EOF

# THE COUNT IS OF THE LIST, NOT OF THE TREE. "Type has 2 exhaustive
# consumers" was a sentence about Type; what this script knows is a
# sentence about ITSELF. A lane counting the cost of a new `Type`
# variant found 44 exhaustive matches across 19 files and read the
# line as a census — the label-wider-than-its-coverage species, in the
# output of the keeper that exists to catch it.
# AND THE ENUMS ARE READ FROM THE TABLE, NEVER LISTED AGAIN. This
# loop named `Ins RtKind Type` by hand — a SECOND spelling of the
# table's first column — and it went stale the moment a fourth
# registry was named: the rows were guarded and the summary said
# nothing about them, so the keeper was doing work it did not
# report. A label NARROWER than its coverage, in the tool whose own
# comment warns about the wider kind.
line=""
for e in $(printf '%s\n' "$CONSUMERS" | cut -f1 | sort -u); do
  line="$line $e $(echo "$CONSUMERS" | grep -c "^$e	")"
done
echo "vocab: consumers GUARDED —$line"
echo "vocab: lines examined per consumer —$examined"
echo "vocab: the lists are CURATED, not a census: a consumer they do not name is"
echo "vocab: unguarded, and naming it is how this law reaches it."
