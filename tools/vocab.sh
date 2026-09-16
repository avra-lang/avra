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
#
# A ROW SAYS HOW ITS CONSUMER IS GUARDED, AND A ROW THAT FINDS NEITHER
# FORM FAILS. `spelled` means a person wrote the arms, so this greps
# them for a catch-all. `derived:<Trait>` means the arms are generated
# off the enum's own declaration — one arm per variant, read from the
# variant list, with no catch-all and typed like any other match — so
# what this asserts is that the annotation is still THERE. Without the
# second form a consumer that becomes derived reports SUCCESS having
# examined nothing: the fn is no longer in the file, the grep matches
# no lines, and three rows go vacuous in one commit. The refusal
# protects the spelled rows from a rename by the same stroke, which
# is the wider prize.
set -e
cd "$(dirname "$0")/.."

# enum <TAB> file <TAB> dispatch fn <TAB> how <TAB> what it decides
CONSUMERS="Ins	packages/std-avrac/src/core/ir.av	dst_of	derived:Roles	the register it defines
Ins	packages/std-avrac/src/core/ir.av	reads_of	derived:Roles	the registers it reads
Ins	packages/std-avrac/src/core/ir.av	seat_regs	derived:Roles	an Avra call's argument seats
Ins	packages/std-avrac/src/core/ir.av	owned_dst	derived:Roles	the register it defines that owns a reference
Ins	packages/std-avrac/src/core/ir.av	viewed_dst	derived:Roles	the register that is a view of another box
Ins	packages/std-avrac/src/core/ir.av	moved_args	derived:Roles	an Avra call's moved-in seats
Ins	packages/std-avrac/src/core/ir.av	escapes_in	spelled	which uses let a register outlive its instruction
Ins	packages/std-avrac/src/core/ir.av	call_symbol	derived:Roles	the body an Avra call enters
Ins	packages/std-avrac/src/language/interp.av	step	spelled	its MEANING, interpreted
Ins	packages/std-avrac/src/language/memory.av	memory_ins	spelled	its ownership effect
Ins	packages/std-avrac/src/language/memory.av	managed_dst	spelled	whether its answer is the caller's to release
Ins	packages/std-avrac/src/language/memory.av	view_of	spelled	which non-owning read borrows a box
Ins	packages/std-avrac/src/language/ir_text.av	body_lines	spelled	its human projection
Ins	packages/std-avrac/src/language/llvm.av	emit_ins	spelled	its machine projection
Ins	packages/std-avrac/src/features/facts.av	give	spelled	whether the runtime registry validates it
Ins	packages/std-avrac/src/core/ir.av	body_symbol	derived:Roles	the program body it names
Ins	packages/std-avrac/src/core/ir.av	hosted_symbol	derived:Roles	the hosted fn it calls
RtKind	packages/std-avrac/src/core/runtime_header.av	c_kind	spelled	the C type, probe and word it crosses as
RtKind	packages/std-avrac/src/language/llvm.av	ll_rt_kind	spelled	the LLVM type it becomes
RtKind	packages/std-avrac/src/language/llvm.av	rt_arg	spelled	how an argument crosses the boundary
RtKind	packages/std-avrac/src/language/llvm.av	answers_word	spelled	how an answer crosses back
RtKind	packages/std-avrac/src/language/llvm.av	answered	spelled	the SIGN a narrow answer widens with
RtKind	packages/std-avrac/src/language/llvm.av	narrow_sign	spelled	the SIGN an inout cell normalises with
Type	packages/std-avrac/src/features/checks.av	comparable	spelled	which shapes equality may compare
Type	packages/std-avrac/src/features/str_lit/check.av	printable	spelled	which shapes an interpolation hole may show
Type	packages/std-avrac/src/features/crossing.av	kind_of	spelled	which @std/meta shape it crosses as
Kind	packages/std-avrac/src/features/crossing.av	meta_of_kind	spelled	how it crosses into the evaluator
Kind	packages/std-meta/src/meta.av	spelled	spelled	the words it is written with"

# A here-doc, not a pipe: the loop runs in THIS shell, so `exit 1`
# ends the script rather than a subshell the gate never sees.
while IFS='	' read -r enum file fn how what; do
  [ -n "$file" ] || continue
  if [ ! -f "$file" ]; then
    echo "vocab: $file is gone — the $enum consumer registry is stale"
    exit 1
  fi
  case "$how" in
  derived:*)
    trait=${how#derived:}
    if ! grep -q "^@derive($trait)\$" "$file"; then
      echo "vocab: ${file} decides ${what} through @derive($trait) and carries no such annotation."
      echo "  A DERIVED CONSUMER IS GUARDED BY ITS ANNOTATION, and the annotation is gone —"
      echo "  so ${fn} is either hand-written again (make this row \`spelled\`) or unguarded."
      exit 1
    fi
    # ANCHORED, BECAUSE A SUBSTRING IS NOT A DECLARATION: `trait Roles`
    # matches `trait RolesX`, so renaming the trait away left this
    # check green. Witnessed failing to fail.
    if ! grep -rqE "^ *(export )?trait $trait *\{" packages/; then
      echo "vocab: @derive($trait) stands in ${file} and no \`trait $trait\` is declared."
      exit 1
    fi
    continue
    ;;
  esac
  hit=$(awk -v fn="$fn" '
    $0 ~ "^ *(export )?fn " fn "\\(" { inside = 1; seen = 1 }
    inside && (/_ ->/ || / is \./) { print FNR ": " $0 }
    inside && /^ *}$/ && inside { inside = 0 }
    END { if (!seen) print "ABSENT" }
  ' "$file")
  if [ "$hit" = "ABSENT" ]; then
    echo "vocab: ${file} declares no \`fn ${fn}\` — the $enum consumer registry names a fn that is gone."
    echo "  A CHECK THAT EXAMINED NOTHING IS NOT A CHECK THAT PASSED: this row would have"
    echo "  reported success over a file it never read. Rename the row, move it, or"
    echo "  mark it \`derived:<Trait>\` if its arms are generated now."
    exit 1
  fi
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

# A ROLE MARK STANDS ON A DESTINATION. `@owns` and `@view` say what a
# register the step DEFINES does with its reference; on a payload that
# is not `@dst` the claim has no subject, and the readers
# (`owned_dst`/`viewed_dst`) would answer a register the step never
# defines. `@moves` is the one role that stands on a SOURCE, so it is
# not asked to carry `@dst`.
#
# CHECKED PER PAYLOAD, NEVER PER LINE: a variant's payloads share one
# line, so a line-scoped grep reads a misplaced `@owns` on the second
# payload as satisfied by the first payload's `@dst` — the defect the
# check exists for, witnessed passing. Ins payload types are scalars,
# `List<…>` and one `Reg?`, so a top-level comma splits them; a payload
# type carrying its own comma would need this scan to track `<>`.
roleless=$(awk '
  /^export enum Ins/ { inside = 1 }
  inside && /^}/ { inside = 0 }
  inside && /^    [A-Z]/ {
    n = split($0, parts, ",")
    for (j = 1; j <= n; j++) {
      if (parts[j] ~ /@(owns|view)/ && parts[j] !~ /@dst/) {
        print FNR ": " $0
        next
      }
    }
  }
' packages/std-avrac/src/core/ir.av)
if [ -n "$roleless" ]; then
  echo "vocab: a role mark stands on a destination, and these payloads carry @owns/@view without @dst:"
  echo "$roleless" | sed 's/^/    /'
  echo "  A role names what a DEFINED register does; without @dst it has no subject, and"
  echo "  the reader (owned_dst/viewed_dst) answers a register this step never defines."
  exit 1
fi

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
for e in $(echo "$CONSUMERS" | cut -f1 | sort -u); do
  line="$line $e $(echo "$CONSUMERS" | grep -c "^$e	")"
done
echo "vocab: consumers GUARDED —$line"
echo "vocab: the lists are CURATED, not a census: a consumer they do not name is"
echo "vocab: unguarded, and naming it is how this law reaches it."
