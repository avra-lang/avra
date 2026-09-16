# Perfect-compiler program — handoff

I am the COMPTIME TASK MASTER. I own phases A–K of
`docs/2026_09_14_PERFECT_COMPILER.md` (NOT §9/phase F — the owner
excluded it). Workers do the slices; **I commit and merge, they never
do.** This file is the whole workload; keep it current.

## Integration

| | |
|---|---|
| branch | `lane/comptime`, worktree `../avra-lane-comptime` |
| head | `784e408`, pushed to origin |
| main | `0b88933` — NOT an ancestor; merge base `12738f7`. The lane needs ONE reconciliation (below) |
| sprite | `avra-comptime`; build/gate with `sh /Users/tristan/projects/tristanMatthias/avra/tools/sprite-build.sh avra-comptime <worktree> -- make gate` |
| dashboard | https://claude.ai/code/artifact/782ea599-df60-4594-a9a1-dcd500ce0b14 — file `build/scratch/perfect-compiler.html`, `P = [name, size, done, total]`, republish with the Artifact tool, same path. No text updates. |
| tasks | `export TASKS_DB=/Users/tristan/projects/tristanMatthias/avra/.tasks/avra.db`; `tasks` CLI direct, NEVER the MCP task tools. Survey wants under epic `avra-8sb5.11`. |

## Step 0 — the Sprite unblock (DONE, `0d97605` + `784e408`)

The lane could not build on a Linux Sprite: it predated main's LLVM 22
and ELF fixes. The measured minimum landed instead of the full merge —
`-fPIC` on every object this tree compiles, the wrapper's LLVM-22
context calls, `-rdynamic` for the evaluator's `dlsym`, SIGPIPE read as
141 beside the signal, `tools/sources_hash.sh`, `tools/sprite-{build,
provision}.sh`, and `sprite`/`sprite-check` targets. It exposed one
cold-tree bug: `seed-check` had no prerequisite on the objects it
links, so a fresh Sprite could not link the seed.

CONFIRMED on `avra-comptime`: `make gate` GREEN — 414/414 tests, every
suite, `traps` 7/7, `witness` Avra == C. The one Linux failure was a
macOS-only fixture (`avra_proc_which("sh", "/usr/bin:/bin")` answers
`/usr/bin/sh` on Linux); the PATH is `/bin` now. The seed was then
refreshed ON the Sprite (`make bootstrap seed`, 316312 lines) and
`seed-check` proves the new seed compiles HEAD.

## Step 1 — the front-end slice (landed on main, NOT the unblock) AND the
## weak acceptance test that said it was

`feat/lane-front-end` @ `dc809b3` landed on main at `c5c64d0`. It teaches
MAIN's compiler to PARSE the lane's front end: the member-mark SURFACE
(`( vm:mark )*` + `( pm:mark )*` in `features/enums/mod.av`, `( fm:mark )*`
in `features/structs/mod.av`, the DSL `mark` rule + `build_mark` in
`features/annotations/mod.av`, MarkWindows/payload alignment) plus the
node-named capability (`05563b4`). Excluded and verified: the role
readers, the derives, the crossing, the feature builder deletions, the
claim law, `SEED_FLOOR`/sprite/parse/capture.

**AND IT IS NOT THE UNBLOCK — because the test I wrote was too weak.**
I required "main's compiler must PARSE the merge target (F0100 at
`core/ir.av:55` becomes a parse)". It parses. It cannot TYPECHECK the
merged tree: F2003 x160 (`x.of` on a nominal), F2030 x10 (`DeclSig` has
no method `fingerprint` — a DERIVED fingerprint), F3000 x9 (`no fn
dst_of_role` — `@derive(Roles)`), F2010/F2015 (`Scoped` at a `string`
seat — phase A's seat law), F3012 x4 (the lane's cli imports
`println` from @std.io while main uses the PRELUDE — a merge defect of
mine). Main HAS `TypeName`/`stands_for`; it lacks `on_nominal`,
`check_named_of`, `lower_named_of` and the `"of"` row, and it has NONE
of the DERIVE system.

THE LAW, and it is the doctrine's own, paid for twice now: **AN
ACCEPTANCE TEST MUST NAME THE WHOLE JOB, NOT ITS FIRST DOOR.** Parsing is
a door; compiling is the destination. A test that a SUBSET of the work
can satisfy is a bound on ACCEPTANCE, not on the thing it names — and it
was written by the person who had just finished warning about exactly
this shape. The honest wording was one phrase longer: "main's compiler
must COMPILE the merged tree", and the compiler would have said #2003
rather than F0100.

STATE: the re-merge is preserved on `merge/main-into-lane-2` @ `9a8fd80`
(pushed); `lane/comptime` is back at `2556679`. `make recover` SUCCEEDS
with main's seed; `make avra` fails as measured. The path (B) rebase vs
(C+) a second capability slice is with the CEO.

RESIDUAL, named rather than hidden: `node_scaffold`'s three builder
bodies are BOUND and REGISTERED but never EXECUTED until the merge names
`Expr.StrLit`/`BoolLit`/`Interp` — their binding is tested, their bodies
are not. That is honest coverage, not a defect, and it closes at the
merge.

## The full main→lane merge — RESOLVED, PRESERVED, AND IT CANNOT BOOTSTRAP

`merge/main-into-lane` @ `4f2b112` (pushed) holds the whole
reconciliation: 24 paths, no markers, and the resolution verified by
reading it — `core/rebuild.av` keeps the lane's derived arms and lands
main's `Pat.Format` walk as `rebuilt_part`/`rebuilt_parts` + a `verb_of`
row; `source_text.av` keeps the lane's `pattern` with main's `.Format`
arm folded in; the Makefile is main's build system plus the lane's five
and the `SHA_SRC` content-hash-over-headers union; `tools/*.sh` take
main's, exactly. TWO merge laws it paid for:

- **A MERGE IS A THIRD LANE, AND INHERITANCE COLLIDES IDENTICALLY.**
  main registered `bool_comprehension` under `I43`; the lane registered
  `hand_sized_column` under `I43`. Same number, both sides — the failure
  the doctrine names (two lanes landing one number, the duplicate key
  silently dropping the earlier rule). The fix renumbered MAIN's to the
  next free `I48` in EVERY place (RULES dict, both SPECIMENS,
  DOGFOODING.md), kept the lane's `I43`, and recorded it in ROADMAP.md.
  The keeper then read clean: debt 0, next free I50.
  **AND IT FIRED AGAIN IN A WORSE REGISTRY — the DIAGNOSTIC codes, where
  NOTHING REFUSES IT.** Both branches minted `F2084`/`F2085`/`F2086` for
  different laws: the lane's `annotation.meta`/`annotation.unplaceable`/
  `annotation.unread_mark` against main's `type.row_shape`/
  `type.format_parse`/`type.format_shape`. The idiom keeper refuses a
  repeated number; the diagnostics registry has no such keeper, which is
  why the ungated merge carried all three silently — `avra explain F2085`
  answers two laws and `docs/DIAGNOSTICS.md` keys two rows to one code.
  Fixed by renumbering the LANE's three to the next free (the union tops
  out at F2089, so F2090–F2092) with every citation swept, the F2086
  WITNESS included. MEASURE it, never eyeball it:
  extract the `kind | "F####"` rows and report a code carried by more
  than one kind. (`main`'s own `F0001` pair, `clash.kind` vs `lex.error`,
  is PRE-EXISTING and out of scope.) A REGISTRY WITHOUT A KEEPER IS WHERE
  A MERGE HIDES ITS COLLISIONS.
- **A ONE-SIDE DELETION IS A DECISION, NOT A CONFLICT.** `staged.av`
  and `process_seam.av` are gone because main removed them
  deliberately (`007508d`, `957a343`); the merge drops the files AND
  their registrations. A `modify/delete` is not a tie to break.

**WHY IT CANNOT BOOTSTRAP — the actual blocker, measured.** Neither
parent's compiler reads the merged tree, and this is NOT the ladder the
doctrine describes:

| parent | cannot do |
|---|---|
| the lane's seed | resolve main's new BUILTINS — F2001 `Bytes` names no type across `interp.av`/`llvm_api.av`/`bytes/*`; F3000 `println`/`eprintln` (main's prelude); F3013 implicit deps |
| main's seed | parse the lane's FRONT END — F0100 at `core/ir.av:55 @dst` and `nodes.av:256 @verbatim`; F0102 in `bool_lit`/`str_lit` (node-named builds main's DSL cannot read) |

THE CLASSIC LADDER ASSUMES ONE PARENT MOVED THE GRAMMAR. BOTH moved the
compiler's ENGINE, not only its syntax: `Bytes` is a new BUILTIN whose
knowledge is compiled INTO the compiler (there is no old spelling of a
builtin, and a temp alias would bake the WRONG engine into gen1), and the
prelude is engine behaviour with no spelling at all. So "write the new
form in the old spelling" has no single old spelling to write.

**THE PATH — RECOMMENDED, in preference order.**

- **(C) Land the lane's FRONT END on main as its own slice.** The engine
  delta (grammar DSL accepting a mark before a PAYLOAD; node-named rules;
  the `listed`/AST-mark machinery) is CODE, and code is written WITHOUT
  the new spellings — the spellings live in the feature `mod.av` files.
  So main's compiler can build an engine-only tree. After that slice,
  main's compiler reads the lane's sources, main already has `Bytes` and
  the prelude, and the milestone merge becomes an ORDINARY merge with no
  ladder at all. This is the paradox collapse: the throwaway intermediate
  becomes a real slice, and no work is wasted.
- **(A) A designed, throwaway intermediate (gen0 = main's compiler).**
  T1 = the merged tree with the lane's new SPELLINGS reverted to their
  pre-D/pre-E2 forms (feature rules back to `-> build_x(...)` with their
  builders; `core/ir.av` roles hand-written as main has them) while
  KEEPING the lane's engine; gen0 builds T1 -> gen1; restore the
  spellings; gen1 builds the merged tree -> gen2, and gen2 == gen3. The
  shapes T1 needs exist in history, so this is mechanical but iterative.
- **(B) Rebase the lane's 47 commits onto main.** Each step is buildable
  by the previous generation, so the ladder happens implicitly one commit
  at a time. Most work, and it rewrites the shared lane history (C/D/I
  must re-base).



## Phases

| | state | worktree / branch |
|---|---|---|
| A typed names, derived copier | **DONE** 2/2 | retired |
| B one meta vocabulary, one crossing | **DONE** 3/3 | retired |
| H side tables, derived identity | **DONE** 2/2 | retired |
| G runtime header + diagnostic witnesses | **DONE** 2/2 | `../avra-phase-g`, `phase/g` @ `efb1200`, merged, clean — retire it |
| C children + fingerprints derived | 2/3, **C2a+C2c DONE, C2b BLOCKED** | `../avra-phase-c` @ `339bd2a`. C2a: `core.Payload` deleted, `PayloadRow` carries `@std.meta.Field`, `@derive(Grammar)` emits the field whole, behaviour-neutral (node_grammar KEEPS its `ty` parsers because the kinds are Unspelled mid-resolve). C2c: the F2086 witness + regenerated `docs/DIAGNOSTICS.md` (136 registered · 73 witnessed · 63 owed). Cold bootstrap proof: `make avra` clean on the Sprite, `avra diagnostics` runs. |
| D grammar names the node, fmt | 2/4, **LIVE on the CURSOR** | `../avra-phase-d` @ `509ced2` (lane merged). One ordered cursor over `store.remarks`, drained at every line-start + a file-tail drain; `DocComment.at` + a `doc_ats` side table for author order. Six goldens rewritten deliberately; `--write` stays OUT (trailing same-line `//` is avra-8sb5.11.112, doc tables avra-8sb5.11.104). Receipt: zero own-line remark loss per file over the manifests. |
| E type marks, IR roles, ownership | 2/3, **worker RETIRED** | MERGED at `4ecd176`. E3 (§6) is BLOCKED and measured: a generated decl's names resolve at the TARGET file, `semantics_of` takes a features type, core imports nothing above itself. E recommends dropping it for the cheap half — rename `Dispatch`'s 43 fields to their FEATURE names, killing a second vocabulary. |
| I ownership roles on Ins | 2/3, **LIVE — I1+I2 done, awaiting the gate** | `../avra-phase-i`. `@owns`/`@view` BESIDE `@dst` (an unmanaged `Alloca`/int-`Bin` dst is neither, and `dst_of` must still find it); `@moves` on Call/CallPtr args. `owned_dst`/`viewed_dst`/`moved_args` derived; the memory pass's two hand lists die. E3's rename DEFERRED (measured: 40 fields, 10 features with several semantics impls — no single feature name exists), filed avra-8sb5.11.113. |
| J one hole-bearing block | not started | after D |
| K attack/doc/binding/diagnostic `at` | not started | last |

## In flight

- **C2a+C2c — LIVE.** The `Field` collapse lands behaviour-neutral
  (node_grammar KEEPS its `ty` parsers until the kinds are real), then
  the `F2086` witness + regenerated `docs/DIAGNOSTICS.md`. Receipt: the
  Sprite gate green read to the end. C2b is HELD — see the phase row
  and the P1 the worker files.
- **D's CURSOR — LIVE.** One ordered cursor over `store.remarks`,
  drained at every line-start + a file-tail drain, so placement and
  consumption are the SAME derivation and a construct with no consult
  point cannot silently drop. `DocComment.at` + a `doc_ats` side table
  keep the doc/remark interleave in author order. The six goldens are
  rewritten deliberately; a test name that over-claims is renamed.
  Receipt: `fmt(x) == x` over every `.av` reachable from the manifests,
  remark loss reported per class (own-line / trailing / doc), target
  132 -> 0 own-line over the 17 files. `--write` stays OUT.
- **I1+I2 — DONE, awaiting the gate.** `@owns`/`@view`/`@moves` land
  BESIDE the structural roles; `owned_dst`/`viewed_dst`/`moved_args`
  derived; the memory pass's two hand lists die. E3's field rename is
  deferred with its measurement.
- **THE FULL main→lane MERGE is OWED** and is its own project (see the
  section above). C/D/I can gate without it — the port did that — so
  the merge happens after they are green, with the compiler as oracle.

## Rulings this program made

- C item 4 (fold in the kind-based identity WIP + retire `verb_of`):
  FIRST ruled fold-in, then REVERSED on the worker's measurement —
  enum payload kinds are `Unspelled` mid-resolve. A measurement that
  disagrees with a plan wins.
- I item 1 (`@owns`/`@view`): BESIDE `@dst`, never replacing it — an
  unmanaged destination is still a destination.
- I item 5 (E3's 43-field rename): DEFERRED on its measurement.

## Standing orders (owner)

- Subagents run **opus**, never fable.
- FULL AUTHORITY to change bad architecture, names, interfaces. Never
  work around them.
- Beautiful, fast, DRY, centralized. Idiom bar BEFORE writing each fn.
- Every slice: `/red-team`, then `/review-round`, then `/feedback`.
- Workers never commit. Report tree + proposed message; **I commit.**
- End-of-life survey per worker, filed under `avra-8sb5.11`.

## Merge protocol

1. Worker reports green gate READ TO THE END + commit message.
2. `git -C ../avra-lane-comptime fetch <worktree> <branch>; git merge`.
3. If `git diff FETCH_HEAD -- . ':!tools/watch.sh'` is EMPTY, the
   worker's gate is the receipt — say so, skip re-gating.
4. Otherwise it is code nobody gated: build, prove the fixed point,
   `make gate`, refresh the seed if a keeper says so.
5. Push, update the dashboard, update this file.

**A MERGE'S FIRST BUILD IS `make bootstrap`, NEVER `make avra`** when
either parent changed the GRAMMAR. I broke this on phase E: its payload
marks meant the lane's standing product could not parse `core/ir.av`,
so it dropped the file whole and 57 innocent importers reported "core
does not export `Reg`". The symptom accused every importer and named
nothing. Bootstrap from the merged seed instead.

**Three merges needed a LADDER**: when both parents moved the compiler,
neither parent's seed can read the merged tree. Build the intermediate
generation with the migrated grams in their OLD spelling, restore, build
twice. Expect gen1 != gen2 and gen2 == gen3 after a syntax change.

## Machine

- Lock is **three slots, entered in arrival order** (`tools/watch.sh`,
  `e21b5dd`). A ticket means WAITING, not RUNNING — drop it when a slot
  is taken or the queue defeats the slots.
- 16 GB, disk ~96% full. ENOSPC hit zero three times; **stop and report,
  never retry-loop.** Swap cannot grow when the disk is full, which is
  what panicked the machine, not the compiler.
- Kill by PID, never by pattern. Park scratch OUTSIDE `packages/`.
- `cp build/avra build/avra.pre` before every risky build — it has been
  the way back five times.

## Open, filed, unowned

| id | |
|---|---|
| `avra-9cbe` | `core.Payload` and `@std.meta.Field` are ONE concept; the poorer copy is WHY a type spelling gets parsed as text. Routed to C (owns `Kind`). |
| `avra-9tfi` | two more string-keyed spelling registries retirable onto `Kind` — same seam |
| `avra-iwls` | **P1**: an annotation on a file's FIRST statement runs TWICE, silently. `no_stmt` is `StmtId{index:0}`, a real index. Witnessed with a control. Tree is lucky, not safe. |
| `avra-jbpa` | `avra expand` traps on an empty file (pre-existing) |
| `avra-iusx` | std-process `proc_seam` race — not ours |
| `avra-egav` | phase H owes an after-census; before-baseline in the ticket |
| `avra-iemo` | a re-entrant expansion's hush may erase a spoken refusal (unwitnessed) |
| `avra-6ndp` | collapse `Variant.payload` into a projection of `fields` (shrink ladder) |
| `avra-5m62` | ANSWERED by G: summary and law are different artifacts, 60 of 72 differ |
| `avra-inr8` | **P1**: two `match` expressions in ONE derive's `Decls` lose their enum — the second's variant patterns arrive without it. Bisected to four runs. **Silent at `make avra`** (an entry lowers only reachable bodies), so a derive can be built and shipped broken. Crossing = C's. |
| `avra-wzuw` | **P1**: an undefined name in a spliced quote TRAPS (exit 2, "a span reaches outside its own text") instead of saying F3000 — a generated node carries the DERIVE file's span, read against the TARGET file's text. And `rebuild_derive.av`'s arity hatch is the tree's ONE "a derive refuses loudly" idiom and has the same trap, never fired. **So a derive cannot refuse by naming an undeclared fn until this is fixed.** |
| `avra-l4xk` | a derive's `export` is inert at the package surface — module-visible, package-invisible. Phases D and E have each worked around it independently, which is what makes it a defect and not a fact of life. |

## Laws this program paid for

- A merge of two lanes that both moved the compiler needs a **ladder**.
- **A TARGET MUST DEPEND ON WHAT IT LINKS.** `seed-check` linked
  `$(RUNTIME_OBJS)` and never named them as prerequisites, so it worked
  on a warm tree and failed on every cold one. A seeded Sprite was the
  first cold consumer, hours after the rule landed. Under the port's
  own doctrine: a check that examined nothing is not a check that
  passed — here it examined something that was not there.
- **A FIXTURE NAMING AN ABSOLUTE PATH IS A PLATFORM CLAIM.**
  `avra_proc_which("sh", "/usr/bin:/bin")` answers `/usr/bin/sh` on
  Linux and `/bin/sh` on Darwin, so `process_seam` was green on one
  machine and red on the other from the day it landed. Name ONE
  directory the platform agrees on.

- **C2b is BLOCKED on avra-8sb5.11.115, measured — not on effort** (phase
  C's write-up, which is the authority). A derive's crossing builds
  `@std.meta.Type` through `crossed_variants` -> `payload_kinds` ->
  `Decls.sig(d)`; a derive crosses DURING resolve, where the enum's sig
  is not earned ("sig mid-resolve", `workspace.sig`), so `kind_at([], j)`
  answers `Kind.Unspelled("")` for every payload. Records are unaffected
  (`@derive(Fingerprint)` on `DeclId` folds `.Int`), so the asymmetry is
  ENUM-only and annotation-ORDER-dependent. The tell is
  `avra expand core/nodes.av`: `grammar_payloads_Expr`/`_Stmt` are all
  `.Unspelled("")` while `_Pat` carries real kinds, and `@derive(Rebuild)`
  on Expr emits `.Ident(p0) -> .Ident(p0)` — every child rebuild silently
  dropped. SPEC TARGET: a derive's crossing must see the declaration's
  EARNED sig. The full retirement is parked on `parked/c2-kind` @
  `54872e1` (4 files) and applies in one pass the day 115 is fixed.
- **A KEEPER HAS TWO SURFACES: WHAT IT REFUSES AND WHAT IT ACCEPTS**, and
  a matcher whose subject is a SUB-UNIT must be exercised with the
  defect placed in a NON-FIRST unit. Phase I's per-payload role guard
  (`tools/vocab.sh`, a role mark on a payload that is not `@dst`) first
  checked the LINE — and a variant's payloads share one line, so a
  misplaced `@owns` on the SECOND payload read as satisfied by the first
  payload's `@dst`. It was witnessed PASSING on the real keeper by
  moving `@owns` from `ConstStr`'s destination to its `s: string`
  payload. The fix checks each payload (a top-level comma split — Ins
  payload types carry no nested comma, stated in the script) and fired on
  the same crafted defect. The draft was not a wrong grep a reader could
  have caught; it was a green check that had never been made to fail.
- A seed refresh is owed by the first commit that **READS** a grown
  field, not the one that grew it. Tell: an index one past a length, at
  an annotation.
- A formatter owes **losslessness**; idempotence passes *because* of the
  bug, since the second pass has nothing left to lose.
- A **performance defect and a sampling temptation are the same defect**
  — ask whether the subset was chosen by the question or by the runtime.
- A bad pattern propagates by being the **nearest example to copy**.
- A witness that no longer triggers its code is a green test proving
  nothing — assert the code FIRED.
- **One consumer adapts to a bad seam; two consumers adapting
  independently means the seam is wrong.** Phase D worked around
  `avra-l4xk` and wrote it into a comment as a fact of life; phase E hit
  it separately. The second adapter is what turns a habit into a defect.
