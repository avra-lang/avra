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

## Step 2 — engine-first capabilities (IN FLIGHT)

Each capability lands ENGINE-ONLY on main: it adds the MACHINERY and uses
it nowhere, so main's own compiler builds it; the USES arrive later with
the rebased lane. THREE so far, each with a shrinking refusal set as the
receipt (acceptance is COMPILE, never parse):

- **(a) `Type.Bytes`** — ONE site: `features/crossing.av`'s `kind_of`
  fallback now carries `.Bytes` with the other unworried shapes (the meta
  vocabulary has no bytes word, so Bytes crosses as the compiler's own
  spelling). Lands on `rebased/lane` (`cd60486`) because it cannot exist
  on the lane alone, whose `Type` has no `Bytes`. `F2013` -> 0.
- **(b) the typed-name `of` PROPERTY** — 8 engine files on main
  (`feat/typed-name-of` @ `df50d1c`), the row plus `on_nominal`,
  `check_named_of`, `lower_named_of`, and the register+type reseatings the
  chain forced. `.of` is read nowhere in the slice. `F2003` x161 -> 0.
  **RESIDUAL, stated as coverage:** the gate CANNOT EXERCISE `of` while
  it is engine-only — main's source reads none, and a test that read one
  would break the old-seed build — so its LOWERING is type-proven, not
  run-proven, until the uses land with the lane.
- **(c) the DERIVE ENGINE** — ~1500 lines / ~14 files: the lane's
  `core/{fingerprint,ir_roles,children_derive,identity_derive,
  rebuild_derive,grammar_derive,protocol,fp,payloads}` (~825 lines), the
  `@std/meta` vocabulary (`Kind`/`Mark`/`Seat`, `Variant.fields`/`marks`,
  `Field.kind`/`marks`, `Fn.answers`), the lane's `features/crossing.av`
  UNIONED with main's, and the derive-relevant parts of `ir.av`,
  `nodes.av`, `decls.av`, `worklist.av`, `node_scaffold.av`. MAIN ALREADY
  HAS THE DERIVE ENGINE (`@std.meta.derive`, the F2072 dispatch,
  `is_derived`, `derive_directives`, quote, @std/derive) — what is missing
  is the VOCABULARY and the GENERATORS. The fallback (revert the derive
  USES to main's hand-written `dst_of`/pre-H fingerprints/pre-C grammar
  reads) is HELD, not chosen: it would DE-LAND phases C/E/H, the
  program's core design, and re-landing means redoing.

ALSO OWED and mine: `rebased/lane`'s `runtime/avra_rt.h` is stale
(`avra_io_*`/`avra_proc_*` asserts against main's renamed ABI) — the
generated header must be regenerated from the rebased tree's rows, the
same class as the merge's, with the empty-header/recover/regenerate
sequence.

## Two statements that must travel with the landing

**1. THE MILESTONE RECEIPT IS A LOCAL WATCHDOG GATE, NOT A SPRITE GATE.**
The owner's standing directive is cloud builds. This landing deviates, and
the deviation is deliberate and measured: on a WARM machine the local
`sh tools/watch.sh 4000 make gate` is MINUTES, while a Sprite gate is
~20 minutes because (a) the sprite helper unpacks the tree into a
directory keyed by the source HASH, so every edit mints a fresh directory
with no `build/` and pays a COLD build of the whole product, and (b)
`seed-check` recompiles the entire tree with a throwaway seed compiler on
every run, uncached. Both are fixed by the ROADMAP build-cache entry,
which the owner deferred until the program is further along. So the
RECEIPT for this landing is local and says so; a cloud receipt is owed by
the first landing that follows the cache work.

**2. THE SPRITE PATH MUST NOT ROT.** It is what a fresh session, another
lane, or a cold tree uses, and it is the only thing that proves the tree
builds on Linux/ELF under LLVM 22 from a clean start. Parked for
ITERATION is not abandoned: keep it healthy with a periodic cold run
(`make sprite-check` says whether a tree takes the seed whole, and
`avra-dev` retains its built trees), and re-verify it after any change to
the Makefile, the seed, or the runtime ABI. Tonight's detour taught the
shape of a healthy use of it: one COLD receipt per landing, never one per
edit.

## CORRECTION — the landing did NOT carry C2a or C2c

My Step 4 and the C row both say C2a+C2c are on main. **They are not**, and
phase C measured it before spending a day on a base where its witness
cannot exist: on `origin/main` (`ec7d63e`) `core/payloads.av` still
declares `Payload` and `PayloadRow.payloads: List<Payload>`, and the
`F2092` witness row count in `language/witnesses.av` is **0**. Both live
only on `phase/c`.

WHY, named rather than excused: when I assembled the landing I cherry-picked
from phase C's branch only what CONFLICTED (the I24 fix) and took its
renumber from the integration tree's identical move — **I never reviewed
C's four commits as a SET**. The other branches I took whole (I's three,
D's six), which is exactly why the omission hid: the assembly LOOKED
complete because every other branch's tip was accounted for.

THE FIX: C2a (`0ce0159`) and C2c (`44f7b04`) are re-applied as the first
rungs of `phase/115` and land with the 115 fix, in that order — C2a is
what makes the 115 witness PRODUCIBLE (`Field` carries `kind`), which is
why C was right to hold rather than budget the day on a base where the
symptom cannot exist. THE GENERAL LAW: **an assembly's completeness is a
claim about every branch's commit SET, not about every branch's TIP** —
check the set, by name, or a slice lands nowhere while every receipt
looks complete.

## Step 4 — LANDED ON MAIN (`61402d1`)

`origin/main` = **`61402d1`**, a FAST-FORWARD from `c5c64d0`, with a receipt:
`gate: receipt for tree 74615c99bb7e`, `3079/3079` tests, `traps: 24
contracts held`, `witness: Avra == C`, `seed-check` green on the refreshed
seed, peak 1046 MB, clean tree.

HOW: assembled LOCALLY in ONE pass — the green milestone `rebased/lane`
812565d + a merge of main + I's three commits (already linear on it) + D's
cursor + C's I24 fix — then ONE local gate under the watchdog. MINUTES,
not three 20-minute Sprite gates. The process law this paid for: on a
WARM machine the local gate is the fast instrument, and the Sprite's cost
is (a) a cold build per content-hash directory and (b) `seed-check`'s
uncached full recompile. Both are the ROADMAP build-cache entry's job,
which the owner has deferred until the program is further along, so
Sprite work is PARKED and iteration is local from here.

FIVE integration defects surfaced in that one pass, each found by the
keeper that owns the question — and one of them is a law:
- **A RECORD LITERAL IS THE ONE PLACE "TAKE THEIRS" DELETES A FIELD.** The
  replayed `NodeStore` literal predated main's `grammars:` field, so
  taking that side wholesale lost it (F2010, "every declared field
  appears exactly once"). The resolution is a UNION of field lists.
- an unused `Field` import (I24), a `Payload` import that the test body
  actually needs, two CLAUDE.md citations of fns the cursor DELETED
  (licensed in `cited.allow` with their reason), and the stale marks-test
  expectation the claim law had invalidated.

REMAINING ON THE PROGRAM: **J** (one hole-bearing block, after D), **K**
(attack/doc/binding/diagnostics' `at`), **C2b** (blocked on
`avra-8sb5.11.115`; retirement parked on `parked/c2-kind` @ `54872e1`).

## Step 3 — THE MILESTONE TREE IS GREEN, and the landing is in motion

`rebased/lane` @ `812565d` — the WHOLE lane replayed onto main, 39 commits,
self-hosting, gate GREEN (`traps: 24 contracts held`, `witness: Avra == C`,
`gate_receipt: self-test passed`, peak 1031 MB). It carries every finished
phase's engine in ONE tree: A/B/H/G/E, C2a+C2c, D's cursor, I's ownership
roles, the derive engine, the member-mark surface, the typed-name seat law.
It took FOUR small integration fixes after the replay, each found by the
cheapest instrument: the fingerprint tag (keeper), the diagnostic codes
(keeper), the licensed citation (`cited`), and one stale test expectation
that main's slice had encoded before the claim law existed.

THE LANDING, sequentially so there is always exactly ONE gated tree:
**I → D → C**, each replaying onto the CURRENT green tip (never a merge: the
replay rewrote the lane's SHAs, so a merge would re-present the full
36-conflict reconciliation per worker, with "take theirs" as every answer).
Then the seed refresh, then `lane → main`, which discharges STD's hold.

| worker | own commits to replay | expected |
|---|---|---|
| I | `3deb776`, `b2b4b1e`, `ab0aec3` | already proven clean: 0 conflicts, `diff` = exactly its 9 files |
| D | 6 (merges excluded) | one real conflict: `source_text.av`, main's `.Format` vs the cursor's `pattern` |
| C | the renumber + an I24 fix | nearly empty — the milestone ALREADY carries the renumber (`F2090`–`F2092`) |

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
| C children + fingerprints derived | 2/3, **C2a+C2c DONE, C2b BLOCKED** | `../avra-phase-c` @ `339bd2a`. C2a: `core.Payload` deleted, `PayloadRow` carries `@std.meta.Field`, `@derive(Grammar)` emits the field whole, behaviour-neutral (node_grammar KEEPS its `ty` parsers because the kinds are Unspelled mid-resolve). C2c: the F2092 witness (the claim law's code, renumbered clear of main's `type.format_shape`) + regenerated `docs/DIAGNOSTICS.md` (136 registered · 73 witnessed · 63 owed). Cold bootstrap proof: `make avra` clean on the Sprite, `avra diagnostics` runs. |
| D grammar names the node, fmt | 2/4, **cursor DONE** | `../avra-phase-d` @ `509ced2` (lane merged). One ordered cursor over `store.remarks`, drained at every line-start + a file-tail drain; `DocComment.at` + a `doc_ats` side table for author order. Six goldens rewritten deliberately; `--write` stays OUT (trailing same-line `//` is avra-8sb5.11.112, doc tables avra-8sb5.11.104). Receipt: zero own-line remark loss per file over the manifests. |
| E type marks, IR roles, ownership | 2/3, **worker RETIRED** | MERGED at `4ecd176`. E3 (§6) is BLOCKED and measured: a generated decl's names resolve at the TARGET file, `semantics_of` takes a features type, core imports nothing above itself. E recommends dropping it for the cheap half — rename `Dispatch`'s 43 fields to their FEATURE names, killing a second vocabulary. |
| I ownership roles on Ins | **DONE 3/3** | `../avra-phase-i`. `@owns`/`@view` BESIDE `@dst` (an unmanaged `Alloca`/int-`Bin` dst is neither, and `dst_of` must still find it); `@moves` on Call/CallPtr args. `owned_dst`/`viewed_dst`/`moved_args` derived; the memory pass's two hand lists die. E3's rename DEFERRED (measured: 40 fields, 10 features with several semantics impls — no single feature name exists), filed avra-8sb5.11.113. |
| J one hole-bearing block | not started | after D |
| K attack/doc/binding/diagnostic `at` | not started | last |

## In flight

- **C2a+C2c — LIVE.** The `Field` collapse lands behaviour-neutral
  (node_grammar KEEPS its `ty` parsers until the kinds are real), then
  the `F2092` witness + regenerated `docs/DIAGNOSTICS.md`. Receipt: the
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

## THE ASSEMBLY COMPLETENESS CHECK — a command, not a resolution

Before landing ANY assembly, for every branch whose work it carries, list
that branch's commits and TICK EACH ONE BY NAME against the assembled tree:

    for b in <branches>; do echo "== $b"; git log --oneline --no-merges <assembled>.."$b"; done

EVERY LINE PRINTED MUST BE TICKED. A tick is a commit whose CONTENT is in
the tree, never a matching SHA — an assembly ADAPTS commits (a conflict
resolution changes the patch) and a MERGE commit never appears in a cherry
list at all.

DO NOT USE `git cherry` AS THE check, measured: it compares PATCH-IDs, so
an adapted commit reads as absent (this assembly's own I24 fix and the
integration tree's renumber both show as `+` while their content is in
`main`), and a branch with merges is mostly noise (`phase/d` reads 30
"omitted" of which the merges are most). Patch-identity is the wrong
question; CONTENT is the right one, and `git log` names the set a person
can tick.

THE INSTANCE THAT PAID FOR IT: an assembly cherry-picked from a branch ONLY
WHAT CONFLICTED and took the rest of that branch's work from a sibling
tree's identical move — so two commits (C2a, C2c) landed nowhere while
every receipt read complete, because every OTHER branch was taken whole and
every branch TIP was accounted for.

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
- **A REBASE RE-PARENTS COMMITS; IT DOES NOT REORDER ENGINE BEFORE
  USE.** A capability whose own source USES it cannot be added by a
  compiler that LACKS it — the lane's commits carry the engine and its
  uses TOGETHER, so main's seed refuses at the first commit that carries
  one. That is why the merge and the rebase dead-end at the SAME wall
  (`F2003 no property of on Plain/Scoped/Nominal` ×187, `F3000
  grammar_payloads_*`, `F2030 a derived fingerprint`, `F2015/F2010`, and
  `F2013 match on Type must handle .Bytes`), and why the front-end slice
  WORKED: it was ENGINE-ONLY, with no uses. The rebase reorders nothing;
  it only re-parents. SO THE CAPABILITIES MUST LAND ENGINE-FIRST, each
  buildable by the previous generation.
- **A RUNNING SCRIPT IS READ INCREMENTALLY, SO AN EDIT MID-RUN
  CORRUPTS THE RUN.** A POSIX shell reads a script AS IT EXECUTES it, so
  editing the file while it is out is read PARTIALLY — the tail of an old
  line welded to the head of a new one. That is how `tools/sprite-build.sh`'s
  fallback came to print the nonsense `ite-build: command not found`: the
  edit's own author was fixing something else while a gate was running.
  THE TELL IS A COMMAND THAT LOOKS LIKE TWO COMMANDS WELDED TOGETHER, and
  the rule is simply: do not edit a shared tool while a run of it is out.
  Freeze it, or let the run finish.
- **AT A MILESTONE MERGE, MEASURE EVERY REGISTRY FOR A COLLIDED KEY
  BEFORE THE FIRST GATE.** Two branches mint keys in the same namespace
  and neither can see the other's; each registry either refuses LATE or
  not at all, so the collision surfaces one refusal at a time, after
  hours of building. FIVE instances in one merge: `I43` among idioms
  (the keeper refused it), `F2084`/`F2085`/`F2086` among diagnostic codes
  (the lane's keeper refused it, but only on the OTHER tree), fingerprint
  tag `129` among `core/nodes.av`'s tags (the fingerprints keeper found
  it), plus the two artifacts that are not keys at all — an empty
  gate receipt and a `seed.sources` staged without its seed. The
  registries are KNOWN and the sweep is cheap: idiom numbers, diagnostic
  codes, fingerprint tags, runtime-row names, and the next registry
  nobody has thought of yet. AND ASK THE KEEPER, NEVER GREP THE SOURCE —
  a key can be COMPUTED (`fp(if … { 106 } else { 107 }, …)`) or spelled
  in two places, so a literal grep lies by omission, which is how four
  of ten tags read as free.
- **A RESOLUTION RULE THAT NAMES THE OTHER SIDE MUST FIRST MEASURE THE
  OTHER SIDE.** I told the workers to resolve the renumbering conflict to
  THEIRS, on the assumption that the milestone tree already carried the
  move — at its COMMITTED tip it did not, so obeying me would have
  REVERTED the very fix the instruction existed to protect. Phase C
  measured the other tree (`COLLISION F2084/85/86`, `codes 141`) before
  rewriting anything, and was right to. "Take theirs" is a claim about
  the other side's state; verify the state, then resolve. The same
  asymmetry hid in the command itself: the upstream I named for its
  rebase (`2556679`) was a LANE docs commit, not the merge's second
  parent (`034b54b`), so it would have replayed a lane commit the
  milestone already carried.
- **THE SIDE-TABLE LAW IS ABOUT FACTS *ABOUT* A NODE, NEVER THE NODE'S
  OWN CONTENT.** A span, an identity, a type, a fingerprint are facts
  keyed by an id; the parsed body of a quote, a sublanguage's expansion,
  and a body's text runs are what the node IS. I ruled the latter into a
  table and it broke the DERIVE ENGINE'S contract: a derive GENERATES FROM
  THE DECLARATION, so anything in a table is INVISIBLE to the mechanical
  walk the declaration guarantees ("a payload's TYPE says whether it
  carries expressions"). THE TELL, measured by phase D: Children on a
  resolved body would walk the TEMPLATE's holes and stop seeing the
  EXPANDED program. AND THE SHAPE THAT WINS IS NEITHER THE TABLE NOR A
  FLAT UNION: a child-bearing payload of a non-Expr type is already
  handled by each derive's per-TYPENAME verb row (`Arm`, `Variant`,
  `Param`, `Case` are all this), so ONE ENUM PAYLOAD (`BodyView`: None /
  Verbatim / Expanded) keeps the payload set FIXED, makes the walk
  mechanical, and lets the per-VARIANT marks (`@verbatim`, `@expands`)
  DIE with the variants they marked. A union on the node would make the
  payload set word-dependent; a table would make a child invisible.
- **A STANDING BINARY CAN BECOME SELF-REFUSING.** A product whose BAKED
  grammar is invalid fails at its OWN runtime `assemble()`, so it cannot
  compile anything and `make avra` keeps rebuilding the bad rule — the
  failure looks like a tree problem and is a BINARY problem. Phase J hit
  it: a rule `-> Expr.Body` whose payloads (`word`, `view`) are neither a
  list nor nullable is refused ("only a list or a nullable payload may go
  unnamed"), the fix is a CUSTOM builder call (`-> body_text(parts,
  holes)` + a `builders` row, which the node validator does not judge),
  and in the meantime `make recover` (link the seed) was the way out.
  Beside "the build that succeeded was the build that lied": the build
  that SUCCEEDED can also be the build that CANNOT SPEAK, and `make
  recover` is the way back from both.
- **A LANDING'S GATE CAN BE RED FOR AN ENVIRONMENTAL REASON, AND THE
  EVIDENCE IS WHAT DECIDES — NEVER A RETRY.** Landing slice J (2026-09-16)
  took TWO full local gates, each red on ONE case of
  `packages/std-process/src/tests/pipeline_test.av` and a DIFFERENT case
  each time (`three stages` line 240, then `many at once` line 205); the
  single file then passed 18/18 on re-run, the machine's load average was
  **78 on 8 cores** (up 8 days, six users, three other campaigns), and J
  touches NOTHING near processes. So the red was the ENVIRONMENT, and the
  landing went ahead with the exception written down and the suite FILED
  (`avra-uswz`) rather than a third gate. THE TEST: can the failing case be
  BUILT and does it fail deterministically? If it passes quietly and fails
  loaded, the gate is measuring the machine. AND A FLAKY SUITE IS A
  READINESS DEFECT: it reddens ANY landing, and a red gate is read as a
  regression, so the author of an innocent change spends an hour on it.
- **A CLAIM ABOUT A REPLACED SHAPE MUST NAME ITS SCOPE**, or a reader
  who greps finds the survivors and distrusts the larger claim. §10.5's
  claim, stated EXACTLY: ZERO `Expr` VARIANTS (`Expr.Interp`,
  `Expr.Quote`, `Expr.Sublang`) and ZERO DSL MARKS (`@verbatim`,
  `@expands`) — measured. FOUR NAMES SURVIVE, and each is out of scope,
  named here so no grep reads as a leftover: `Node.Interp` is `@std/meta`'s
  own meta-vocabulary node, which the crossing builds for the evaluator (a
  DIFFERENT enum); `QuoteKind`/`quote_kind` describe a body's text runs (a
  type ABOUT a body, not a variant); `Rebuilder.verbatim` is the
  rebuilder's own flag, now set from the VIEW instead of a mark; and
  `SublangSemantics`/`features/sublang/` is the FEATURE that owns one
  `word` of the word registry.
- **LANDING GATES RUN ON A SPRITE; LOCAL GATES ARE FOR SUB-MINUTE
  ITERATION.** The machine's load average is 40–78 on 8 cores (up 8 days,
  six users) while our campaigns use ~1.3 cores, so a LOCAL gate measures
  the HOST: it was red twice on a load-flaky process suite (`avra-uswz`).
  A Sprite sells a QUIET machine, which is what a receipt needs. ONE cold
  receipt per landing; local for the keepers and `./avra check`.
- **A LANDING RUNS `make seed` AND COMMITS IT — THE SEED'S SOURCES HASH
  IS PART OF THE LANDING.** My K and J landings were BARE MERGES, and I
  read `seed-check: the seed compiles HEAD` as the seed's receipt. It is
  not: it proves the seed can COMPILE the tree, never that the seed IS the
  tree's source, so `bootstrap/seed.sources` stayed at the old hash
  (`68fd130f…` against the computed `20c776ca…`) while every receipt read
  complete — the Sprite fast path was dead for two commits. AND THE GENERAL
  SHAPE, which is the same one as the C2a/C2c omission: **A CHECK WHOSE
  SCOPE IS NARROWER THAN THE CLAIM IT IS READ AS.** `make sprite-check`
  already computes the comparison that was missing; the landing owed the
  command, not a new tool.
- **AND THE GUARD'S OWN HAZARD, named before it is built:**
  `tools/sources_hash.sh` reads the WORKING TREE, so a DIRTY tree always
  mismatches. A naive seed-hash guard therefore fires on every iteration
  and becomes a check everyone learns to ignore — so it must REFUSE on a
  clean tree and say "seed not checked — tree dirty" on a dirty one, or
  compare COMMITTED content instead, which is the better question if the
  tool can ask it.
- **A REFUTATION FROM AN ANVIL TOO SMALL.** The ROADMAP measured a
  mechanism ONE FILE AT A TIME and STRUCK the fix for it ("LINEAR ... the
  prefix snapshot is not needed; struck") — while the cost was per-FILE x
  program-GLOBAL names: invisible at one file, DOMINANT at 513. Measured
  2026-09-17: `check packages/cli` 116.5s user CPU against the recorded
  5.25s, 22x, while the tree grew 1.86x in files
  (`Decls.file_names` re-binds every module name AND every builtin per
  file; 1.37 B `avra_slot_unique` calls on a 2,400-line program,
  tool-verified by backtrace, filed `avra-b5y6`). A MEASUREMENT'S SCOPE IS
  PART OF ITS CLAIM: a per-file measurement cannot refute a per-program
  cost, and the label on the measurement ("LINEAR") is what made it read
  as general. THE OWED ARTIFACT IS A TWO-SIZE HARNESS — a single-file
  program AND the compiler — as the judge for every analysis or executor
  change from here.
- **A VALUE HANDED TO A SHELL IS REINTERPRETED, AND THE SHELL'S
  REINTERPRETATION IS SILENT.** Three instances in one night, three
  authors: (1) backticks inside a DOUBLE-quoted argument EXECUTE, so a
  commit message that documented a weld ran the text it documented;
  (2) an apostrophe inside a SINGLE-quoted `-m` ends the quote, so the
  message fragmented and the commit refused with a pathspec error naming
  a word from the sentence; (3) `set -e` DOES NOT ABORT ON A FAILING
  COMMAND SUBSTITUTION USED AS AN ARGUMENT — `printf '%s\n' "$(false)"`
  prints a blank line and SUCCEEDS — so the gate receipt built its tree id
  inside a substitution and wrote a BLANK id while reporting success (the
  empty id is rejected downstream, which is why the defect was latent
  rather than live). THE RULE: when a value crosses into a shell, ask what
  the shell will do with it, and prefer a form that cannot be
  reinterpreted (a heredoc, a file, `git commit -F -`) over quoting that
  survives review by habit.
- **A `Cell`'S READ-MODIFY-WRITE ROUND TRIP IS A COPY PER ELEMENT, AND
  THE FIX IS A VERB.** Measured (20,000 appends, native, user CPU): a local
  `mut` push 0.002s, a field push `r.xs.push(i)` 0.002s, and
  `cell.get()->push()->set()` **0.453s** — 200x, because the round trip
  copies the whole list on every element. Copy-on-write IS amortized and
  `List`/`Table`/`Namespace` are fine; `Cell` existed precisely to make
  mutation through sharing cheap, and `lower_set` already emits the
  in-place `avra_slot_set`, so the runtime could always do it — only the
  VERB was missing (`Cell.push`, lowering to `slot_read` + the existing
  `avra_array_push`: no new runtime row, no new `rt_sigs` row). The
  general law: a VOCABULARY WRITE on a cell must lower through the slot; a
  get/mutate/set round trip is a copy per element, and it reads as ordinary
  code. Two hot spots collapsed to this one shape the same day
  (`Db.record_dep` 97% of `bodies`, `Decls.note_origins` 97% of `resolve`),
  which is what makes it a defect CLASS rather than a site: the next one
  will also read as ordinary code.
- **THE IDIOM'S OWN ADVICE CAN BE THE QUADRATIC.** I3 fires on "a
  for-loop whose body is one push — that is a comprehension (or concat)"
  and it fired on FOUR sites of the perf slice, where the licensed answer
  is the IN-PLACE PUSH: a comprehension or a `concat` is O(n) PER CALL, so
  following the idiom literally would reintroduce the quadratic the slice
  existed to remove. The license carries that reason AT EACH SITE, which
  is the exemption law doing what it is for. THE GENERAL FORM: a matcher
  that recommends a "more idiomatic" shape must know that shape's COST, or
  the idiom becomes a performance defect wearing doctrine's clothes — and
  the license is where the disagreement between two laws is written down
  rather than silently resolved.
- **A VERB AND ITS FIRST USE ARE TWO GENERATIONS, SO THE SEED RIDES THE
  SLICE.** Three times in ONE day: a feature that teaches a verb cannot
  compile its own USE with a seed predating the verb — F2030 on
  `Cell<List<Key>>`, then again on `Cell<List<Origin>>`, in two consecutive
  commits of one perf slice. So a seed refresh is PART OF such a slice, and
  the commits are ordered VERB-FIRST. This is the normal shape of a perf
  slice in this tree, not an exception.
  AND ITS REWARD, measured: the slice's only diagnostic difference was a
  NEW `F2050` — `mut fn note_origins` no longer writes through `self` once
  the tables are mutated in place, so its `mut` was a LIE and the compiler
  said so; dropping it made diagnostics identical. **A PERF CHANGE THAT
  MAKES A DECLARATION HONEST IS THE TREE SAYING THE SHAPE IMPROVED** — the
  opposite of the usual keeper finding, where a warning must be silenced
  rather than obeyed.
- **A LOST OUTPUT IS NOT A FLAKY ASSERTION.** Three runs of ONE gated
  commit gave `rc=1, rc=1, rc=0`, and the differing bytes are DROPPED CHILD
  OUTPUT — `.expected` reads `a b warned clean … p1+p2+ with code 5`, a
  failing run reads `  warned clean … p1++ with code 5` — so a child's
  words are lost under load. That is a REAL `@std/process` defect and it is
  the ORDER law's territory (a capture must hold everything readable WHEN a
  deadline fired, so the last act before declaring is a DRAIN and the grace
  is a FLOOR). THE CONSEQUENCE FOR EVERY LANDING: the gate reddens for a
  reason unrelated to the change, and MOST OFTEN when the box is LOADED,
  which is when landings happen — so a lane that reads it as its own
  regression will revert a correct change. (One campaign was one step from
  doing exactly that, having first attributed the red to its OWN edit.)
  SO: before attributing a red gate to your change, RE-RUN the failing
  suite, and ask whether the difference is LOST OUTPUT rather than a
  different answer.
- **A PERF FIX WITH NO MEASURABLE WIN AND A SEMANTIC HAZARD IS NOT A FIX.**
  `core/table.av`'s `keep` grows `self.rows` with a bare push, so placing
  into a Table of n rows costs n, and EVERY dense-by-id column and memo
  value is a Table — the same spelling one level further down. It was
  implemented, measured (A/B three alternating rounds: no measurable win)
  and REVERTED, because `Table` was a VALUE: copying it gave independent
  rows, and a shared `Cell` makes copies SHARE, so any snapshot-by-copy
  becomes a LIVE VIEW — an audit, not a perf slice. FOUND AND NOT LANDED is
  a result, and the measurement is what makes it one.
- **A GENERATED FILE'S CONFLICT IS RESOLVED BY REGENERATING, NEVER BY
  MERGING.** A merge of two branches that both refreshed a generated
  artifact produces a THIRD value neither side wrote — an LLVM module, or a
  `seed.sources` naming a tree that never existed. Phase D hit it
  (`bootstrap/seed.sources` on both sides) and resolved it by taking one
  side and running `make seed` on the MERGED tree, then committing what the
  generator emitted (`seed.ll` came out byte-identical to the emitted one).
  The same rule covers `runtime/avra_rt.h`, `docs/DIAGNOSTICS.md` and every
  other projection: AN AUTO-MERGED ARTIFACT IS A HYPOTHESIS, and the
  generator is the only thing that can settle it. It is also why a
  generated file in a conflict is never a reason to think twice — the
  resolution is one command, not a judgement.
- **INSTANCE OF `CLAUDE.md`'s "A COMPILER UNDER TEST MUST STAND WHERE A
  COMPILER STANDS"** (main:CLAUDE.md:790 — `@std/*` resolves from the
  BINARY'S OWN DIRECTORY, so a harness that links it elsewhere changes what
  it can resolve; `seed-check` was the first to pay it). The cache
  campaign's FIRST verification of its own artifact failed for this reason:
  it ran the built compiler from `packages/cli/src/`, which moves
  `avra_self_dir()`, so the std root resolved elsewhere and `println`
  vanished. THE ARTIFACT WAS GOOD AND THE HARNESS MOVED THE GROUND, and
  the tell is that it "looks exactly like a bad binary".
  AND ITS OWN META-INSTANCE, which is why the law was cited at me: I
  grepped SIX spellings of it in MY worktree's CLAUDE.md and found none,
  and told the CEO it was not doctrine — my grep was right and the TREE was
  stale (`lane/comptime` predates the milestone it produced). **A PROBE
  RESULT NAMES THE BASE THAT ANSWERED IT**, and six spellings against one
  older tree is the cleanest demonstration this program has.
  AND ITS OPERATIONAL HALF, which the sync paid for: **YOUR DOCTRINE
  SURFACE IS THE TREE YOU READ.** A branch that predates the milestone it
  produced keeps a stale `CLAUDE.md`, a stale `ROADMAP` and stale code, so
  a law "not in the doctrine" may simply not be in YOUR copy of it — read
  doctrine from `origin/main` when the answer decides an action, and keep
  the working branch synced (a RESET when main already holds the content
  by another name, as here: 79 superseded commits, one commit to sync, and
  `git diff --stat origin/main HEAD` = the handoff and nothing else).

- **One consumer adapts to a bad seam; two consumers adapting
  independently means the seam is wrong.** Phase D worked around
  `avra-l4xk` and wrote it into a comment as a fact of life; phase E hit
  it separately. The second adapter is what turns a habit into a defect.

- **INSTANCE OF THE ORDER LAW (`CLAUDE.md`): THE REAP WAS AN ORDERING
  APPROXIMATED AGAINST THE DRAIN.** `@std/process`'s `ticked` did
  `poll -> drain what the poll reported -> reap`, then set `stopped`, so a
  child that WROTE AND EXITED in the gap between the poll answering
  "nothing ready" and the reap was declared gone with its word still in the
  pipe — and the callers that collect when `stopped` is true (`parallel`,
  `race`, `Pipeline.outcome`) gathered an EMPTY capture. `Command.outcome`
  was spared only because its `grace` sweeps after the loop; the others
  have no grace. MEASURED: 5-in-10 suite runs red pre-fix (dropped `a b`,
  `p1+p2+ -> p1++`), a 144-word direct probe losing 3 then 8, and 0-in-15
  plus a green probe post-fix. THE FIX IS ONE DEFINITION WHERE THE FACT IS
  MINTED: sweep both streams (non-blocking read-to-EOF) BEFORE returning
  `stopped: true`, +13/-2, no caller changes — and the ordinary path is
  SHORTER (objdump: prologue byte-identical, every added retain and sweep
  behind the `cbz` on the reap). BEYOND THE LAW: a suite red 5-in-10 does
  not merely annoy, it TEACHES LANES TO DISTRUST REAL REDS.
- **A SOURCE HOST AND AN ARTIFACT STORE ARE DIFFERENT THINGS.** The
  cache collapsed `Store` into `Host` and lost the distinction exactly
  where the two diverge: a LONE FILE's host is in memory, so its `.ll`,
  `.plan` and `.warn` went into a map and vanished with the process while
  the binary (copied by the command) reached the real disk — benign only
  because the binary is consulted FIRST. A host is where SOURCES are read;
  a store is where ARTIFACTS persist, and a lone file is the case that
  tells them apart. The seam is owed back before anything else depends on
  the artifact path.
- **AN EVICTION ORDER MUST BE A FACT ABOUT USE, NOT ABOUT THE CLOCK.**
  The cache's cap is deterministic and clock-free: a HIT and a STORE both
  move a key to the front of `.avra-cache/recent` and eviction takes the
  tail — no mtime, no tie-break, nothing machine-dependent — and the file
  is readable, so what drops next is inspectable instead of asserted. Its
  witness fails first and passes: edits 1..8 keep keys 1..8, edits 9..11
  keep 8, 8, 8.

- **THE PER-FILE MODULE RUNG'S SPEC, named so it can wait.** The good
  news first: NO NEW C IS NEEDED — each per-file module can be its own
  `.ll` and clang links them together. The three blockers, in the order
  they must be taken: (a) `emit_ll` always emits the ENTRY, so every module
  would define `main` and the link fails — it needs `with_entry: bool`;
  (b) `Body` does not name its file, so either it carries the FileId (a
  GROWTH — check the payload hashes before adding a field, per the hash
  law) or the drain happens per file in `lowered_from`; (c) statics are
  DEFINED by `emit_static` and a module that is not their owner must
  DECLARE them, with no declare-only path today — the fiddliest part. It
  waits for its own cycle; the cap and eviction make the disk BOUNDED in
  the meantime (~149MB at `cache_kept = 8` for the compiler).

- **A GENERATED ARTIFACT IS NOT A CONCERN TO REVIEW.** The cache landing's
  diff reads 37 files / +1077/-145 = **1222 lines** with the seed EXCLUDED,
  and 39 files / +25991/-21632 with it included — the second number would
  have forced a SPLIT THAT NOTHING NEEDED. So a diff-size rule (the ≤3k
  line rule, any review budget) must EXCLUDE generated artifacts
  (`bootstrap/seed.ll`, `seed.sources`, `runtime/avra_rt.h`,
  `docs/DIAGNOSTICS.md`, every `*_mechanical_test.av`), or the generator's
  output is measured as if a person wrote it. AND THE SAME EXCLUSION IS WHY
  A GENERATED FILE'S CONFLICT IS ONE COMMAND (see above): both follow from
  the artifact being a PROJECTION, not a decision.

- **A CROSS-PLATFORM TOOL MUST BE WITNESSED ON BOTH PLATFORMS, BECAUSE THE
  PLATFORM THE GATE RAN ON IS NOT NECESSARILY THE PLATFORM THE TOOL WILL
  RUN ON.** `tools/stems.sh` shipped `sed -n 's/.* T _\?//p'` — `\?` is a
  GNU BRE extension, BSD/macOS sed rejects it — and it PASSED every Sprite
  gate because the Sprite's sed is GNU sed. So main's MACOS gate went red
  and blocked every macOS lane, from ONE LINE. THE TELL: a gate that runs
  on one platform witnesses only that platform's DIALECT. The sweep that
  finds this class is cheap and named: `sed -r` (BSD wants `-E`), `\?`/`\+`
  in a BRE, `\s`/`\w`, `grep -P`, `readlink -f`, `stat -c`, `sort -V`,
  `date -d`, `echo -e`. Run it over `tools/*.sh` and treat a hit as a bug
  until a witness on the OTHER platform says otherwise.

- **THE BUILD CACHE'S WAIST IS THE INTERFACE, NOT THE IR** — the correction
  that re-aimed the campaign, from its own measurement. An EDIT's cost is
  ANALYSIS-bound (parse ~7.5s + resolve/typing ~14-18s + lower/emit ~5s +
  link ~10s), so per-declaration IR caching buys about **1.2x** and any plan
  that only caches IR has aimed at the SMALLER half. The tree already holds
  the derivation graph (the query kernel IS it); what is wrong is that it
  DIES WITH THE PROCESS and that its bottom cutoff covers STRUCTURE but not
  text or spans. And only the INTERFACE crosses a file boundary — so
  interfaces are the only thing that must learn to persist. THE HONEST
  LADDER, stated so nobody is surprised: interfaces remove ~14s of
  resolve+typing; per-file objects remove ~5s of emit; PARSE and LINK need
  a RESIDENT ENGINE and an INCREMENTAL LINKER respectively, so a truly
  instant edit is three rungs and the first two are stateless. AND THE
  RUNG THAT SOUNDS BEST IS THE ONE TO DISTRUST: semantic addressing is
  sound ONLY IF normalization is conservative, because inventing an
  equality is a silently wrong binary.

- **A PERSISTENT KEY MUST NOT COVER GLOBAL STATE — AND THE SAME VALUE IS
  RIGHT IN ONE LIFETIME AND WRONG IN THE OTHER.** `sig_hash` folds interned
  `TypeId` ORDINALS, a dense index into the workspace's registry, so
  introducing `string` ANYWHERE shifts every signature that mentions a type
  and an unrelated edit invalidates EVERY file. MEASURED BY A CONTROL LEG: a
  BODY in an unrelated module leaves a key stable; a SEAT (`int -> string`)
  in an unrelated module MOVES it. **THE DUAL LAW, and both halves are key
  defects: too LITTLE coverage (structure without text or spans) reuses a
  stale artifact — a WRONG BINARY; covering GLOBAL state (an interning
  ordinal, a revision, a clock) invalidates everything — a USELESS CACHE.**
  Neither was CHOSEN: both are what a convenient number happened to
  include, and the second is a performance failure wearing correctness's
  clothes. In-process the ordinals are fixed for the run, so `sig_hash` IS
  the right early cutoff; PERSISTED it is the wrong identity, and a key that
  outlives one run folds the type's SPELLING or a STRUCTURAL digest of its
  shape instead.
- **A POSITIVE-ONLY WITNESS CANNOT SEE OVER-INVALIDATION.** Every leg that
  proves "this hit was not wrongly given" passes while a key moves for a
  reason it should not — it takes A LEG THAT ASSERTS A KEY MUST NOT MOVE.
  This campaign's two controlling legs have now found two defects the
  positive legs could not, and in both cases the CONTROL was the case that
  failed.

- **THE PER-FILE RUNG IS TWO PARTS, NOT THREE, AND HERE IS ITS EXACT RESUME
  POINT** (from the campaign's own sizing, which it stopped at a clean
  boundary to report). (a) IS DONE AND INERT: `emit_module(l, path,
  with_entry)` with `emit_ll` a one-line call passing `true`, verified by
  `emit` output being BYTE-IDENTICAL before and after — the right receipt
  for a part that exists only to make the next one possible. THEN (c) AND
  (b) ARE ONE CHANGE, because SPLITTING BODIES PER FILE IMMEDIATELY REQUIRES
  STATICS TO BE DECLARED BUT NOT DEFINED outside their owner module —
  otherwise every per-file module defines the same globals and the link
  fails on duplicate symbols, so there is NO intermediate state. And
  `unheld_name(l)` (the closure check that refuses "nothing declares X")
  means each module must still DECLARE every user fn while DEFINING only its
  own bodies, so the signature is ONE `Lowered` plus `only: FileId?`, not
  two `Lowered` values. THE EXACT STEPS: `Body` and `Static` each gain
  `file: FileId? = null` (growths — `Body` is NOT fingerprinted and both are
  records, so all 24 construction sites stay untouched); `lower_fn`/the unit
  drain set that field from `Wanted.file`; `emit_module(l, path, with_entry,
  only: FileId?)` declares everything, calls `emit_static` only for the entry
  module and emits bodies only for `only`; the driver emits one module per
  file plus the entry module and the link plan lists them all; and the judge
  is `emit` byte-identical for a single-module program, then the link runs,
  then `check packages/cli` diagnostics identical. NO NEW C: clang links the
  N `.ll`s.

- **A SPLIT THAT DUPLICATES EVERY DECLARATION AND STATIC INFLATES WHAT IT
  SPLITS.** Emitting one module per file inflated `packages/cli`'s IR from
  **19MB to 210MB for ONE cache key** (257 modules) and regressed the
  compiler's own no-op from 0.25s to **21s** — so the DISK rung, whose whole
  purpose was to REDUCE disk, multiplied it eleven-to-thirteen times, because
  every per-file module repeats every declaration and every static. THE LAW:
  a per-file split is a NEGATIVE until the duplicated parts are SHARED (one
  declarations module, statics emitted once) — and it serves neither goal
  until then, since it buys only `lower+emit` (~5s of 35s) and touches none
  of the analysis that dominates. The measurement cost one sitting and
  re-aimed the campaign; it is the same shape as "allocation here is cheap,
  so avoiding one is a trade" — a structural change must be MEASURED,
  because SMALLER UNITS ARE NOT SMALLER BYTES.
- **AN UNRESOLVABLE `use` NAME SILENTLY REMOVES A FILE'S ENTIRE CONTRIBUTION
  TO ITS MODULE.** `use core.{…, Lowered}` where `Lowered` lives in the
  module ITSELF made every export of `build_cache.av` vanish — and the
  symptom appeared in OTHER files ("does not export `unit_key`", "does not
  export `build_program`"). A FILE-LEVEL TYPO, A MODULE-LEVEL AMPUTATION,
  REPORTED AGAINST INNOCENTS.

- **A LANDING THAT TEACHES A VERB NEEDS A COMPILER THAT KNOWS IT** — the
  two-generation law RE-INSTANCED, same shape as a grammar change. The
  landed seed predates the cache's `Cell.push`/`set_at`, so it cannot
  compile the tree that USES them (F2030 on `Cell<List<Origin>>`), while the
  campaign's OWN product can — so the fresh seed (344,513 lines) was emitted
  by that product over the rebased tree, and THAT is what let the gate pass.
  The symptom accuses the tree; the cause is the seed's generation.
- **A UNION'S GRANULARITY MUST MATCH THE CONFLICT'S GRANULARITY.** A
  conflict that is ONE NAME (`attack_command` vs `keys_command` in a `use`
  list) needs a NAME for its resolution; a script that unions the two SIDES
  glues a whole command list into a mid-list position and the parser refuses
  the line. The file-level instinct is wrong at exactly the place it looks
  safest, and the build caught it rather than any review. Beside "a merge is
  a third lane": both are laws about RESOLVING rather than deciding.
- **DERIVED DATA NEVER TRAVELS.** The cache writes `<program root>/
  .avra-cache/`, and for a program under `packages/` that is INSIDE
  `packages/` — gitignored, so invisible to `git status`, and 476MB of
  artifacts rode the sprite archive into a PUT timeout TWICE. The archive now
  excludes `*/.avra-cache/*` (the structural fix for our tools). AND THE
  LOCATION IS A DESIGN QUESTION, not settled: a program under `packages/`
  writing a gitignored store inside `packages/` will bite any walker that
  trusts a `.gitignore`-blind `find` — a per-tree root would not.

- **A FIXTURE THAT CANNOT EXHIBIT THE DEFECT PASSES WHILE THE REAL TREE
  FAILS.** The cache's store-placement walk kept the highest ancestor
  "while every ancestor looked like a tree", so it stopped at the first
  PLAIN directory — and `packages/` holds no `.git` and no manifest, so it
  wrote the store EXACTLY where the change existed to keep it from going.
  The NESTED-PACKAGE TEST PASSED and the compiler's own build failed,
  because a two-level fixture has NO PLAIN DIRECTORY between its root and
  its package: the fixture could not exhibit the defect. THE TEST: for a
  rule about ANCESTRY or SHAPE, ask whether the fixture contains the case
  the rule is about — a two-level fixture tests two levels and nothing else.
- **STORE PLACEMENT IS NOT A CORRECTNESS QUESTION, WHICH IS WHY IT WAS EASY.**
  Every artifact is named by a key over the whole input tuple AND the tuple
  is checked before the artifact is believed, so a store in the WRONG PLACE
  costs a rebuild and can never hand back a wrong answer. Placement is then
  about blast radius and sharing alone, and both point the same way: per-tree
  is ONE directory at the checkout root (beside `.git`), SHARED across the
  packages in it, still dying with the worktree. The whole-program cache
  already held that property; the placement work extended it.

- **ONE DEFINITION OF "WHAT DOES THIS FILE EXPORT".** `interface_lines`
  produces a module's entries, `module_surface` FOLDS them into the
  contract's key, and the record KEEPS them — one projection, three uses,
  because two spellings would let the cache VALIDATE one thing and SERVE
  another. And an entry carries NO KIND FIELD: the signature's own prefix
  says it (`fn(string)void`, `enum(Ok,Err|T1;T2)`), because a second copy of
  what the signature carries is a copy that can disagree with it.
- **A FIELD THAT READS COMPLETE WHILE CARRYING NOTHING IS A HOLE, AND THE
  FIRST LOOK IS WHEN TO CATCH IT.** A few PRELUDE entries carry an EMPTY
  signature (`List`, `Map`) because a builtin has no `DeclSig` to render — so
  an entry that looks like every other entry is a HOLE in what a driver can
  mint. The fix belongs at the WRITER (refuse to write one) or the LOADER
  (treat it as a builtin) and must be decided BEFORE the loader exists. Same
  shape as the empty-value law: the spare value is spent where nobody looked,
  and here it is a record row that reads complete.

- **A GREEN THAT PROVED LESS THAN IT LOOKED LIKE.** A witness re-run is not
  a re-run until you READ WHAT YOU CHANGED: the cache's first re-check of the
  three-leg witness set `util` back to the SAME content, so it exercised leg
  0 (nothing changed -> everything holds) and NOT the two legs that matter.
  The suite was green and the property was untested — same family as "a
  check that examined nothing is not a check that passed" and "a fixture
  that cannot exhibit the defect", and the catch is READING THE DIFF, never
  the result.
- **THE TWO CAUSES OF AN ABSENT VALUE MUST NOT SHARE A SPELLING — IN A
  RECORD ROW TOO.** A builtin has no `DeclSig` to render, so its entry read
  COMPLETE WHILE CARRYING NOTHING, and a loader could not tell "there is
  nothing to mint, the compiler provides this name" from "there is
  something to mint that the writer FAILED to write". The fix is a WORD:
  `builtin\tList` says the first, and a signature says the second, with
  `entry_line` the ONE place that decides which — so the writer cannot
  disagree with itself about what an absent signature means. (`CACHE_FORMAT`
  moves, so old entries are unreachable rather than wrong.)

- **A MEASUREMENT THAT CANNOT EXHIBIT THE CHANGE IS THE FIXTURE LAW ONE
  LAYER DOWN.** The cache's eager index measured 7% (17.6s against 16.4s) —
  against a binary whose `packages/cli/src/main` was STALE, because the
  build meant to replace it had FAILED and left the old artifact in place.
  The timing looked plausible and was about the WRONG ARTIFACT. So a number
  is trustworthy only once the binary is known to be the one just built:
  the same test as "can this fixture exhibit the defect", applied to the
  THING BEING MEASURED rather than to the case.
- **A PROJECTION FILLED ON EVERY WRITE ANSWERS A QUESTION ONLY A READER
  ASKS.** The name->id index filled on every `intern` cost 7% of a package
  check — a rendering and a map write for every type the compiler makes, to
  serve a LOADER — and LAZY it is FREE (an alternating A/B of three runs
  each: 0.2%, inside this machine's noise), because a build that loads no
  record never builds it. The question's READER decides when it is worth
  paying for.
- **A NAME IS NOT UNIQUE, SO A CALLER THAT MINTS FROM ONE CHECKS THE ROUND
  TRIP.** Two declarations in different modules may render the same text and
  `by_name` answers the FIRST interned — so a minting caller re-renders what
  it got and REFUSES unless it equals the spelling it asked for. A collision
  then costs a REFUSAL, never a wrong type: the only direction this may fail
  in. AND THE LIFETIME DISTINCTION DECIDED A THIRD DESIGN — `ids` LOOKED like
  the inverse and is not, because it is keyed by `canon`, which spells its
  children by INDEX and so belongs to ONE RUN, while a record outlives one
  and needs the PRINTING text.

- **A GUESSED ANSWER IS WORSE THAN A MISSING ONE, AND A PARTIAL ONE IS
  WORSE THAN BOTH.** The cache's decoder refuses THREE things rather than
  answering plausibly: a spelling whose ROUND TRIP disagrees (`by_name`
  answers the FIRST type that ever rendered that text and cannot know it is
  the one the record meant, so the signature is rendered BACK with the
  writer's own projection and a disagreement is a REFUSAL); every kind that
  is not a `fn` (a call site reads a callee's parameters and answer and
  nothing else — a declaration whose shape was GUESSED is a wrong program,
  while a missing one is a diagnostic); and a NESTED seat
  (`fn(fn(int)int)void` carries a `)` inside its parameters, so a decoder
  splitting on the first one would SILENTLY TAKE HALF A SIGNATURE). ONE
  PRINCIPLE, THREE GUARDS: where an answer can be PARTIAL, refusal is the
  only sound direction — and the failure is then a diagnostic rather than a
  wrong program. AND THE EMPTY CASE IS SPELLED: the prelude's four `builtin`
  entries mint NOTHING, so "nothing to mint" and "failed to write" are not
  the same silence (the `entry_line` decision paying off one step later).

- **A HOOK THAT COMPUTES ON FIRST ASK IS A TRAP FOR A VALUE THAT WAS NEVER
  COMPUTED.** `sig(d)` answers through `ensure`, a per-file hook that computes
  a signature FROM THE PARSE on first ask (`no_ensure` by default). A MINTED
  declaration must answer WITHOUT that hook — there is no parse — and it would
  NOT fail loudly: it would compute from an EMPTY STORE and produce a
  signature shaped like nothing. So registration owes four coordinated table
  writes (`decls`, `sigs`, `file_decls` — the tables `items(f)` walks) AND a
  decision about the hook, and that decision rests on ONE unverified fact:
  does `sig` really short-circuit on a filled table? **VERIFY THE DECIDING
  FACT BEFORE THE CODE** — a guess here produces a plausible wrong signature
  rather than an error, which is the worst of the three outcomes.
- **AND THE DECIDING FACT IS FOUND BY READING ONE CALL PAST WHERE YOU
  LOOKED.** `exported_decls(m)` seemed to "not read the parse at all — it
  walks a FILE'S ITEMS and filters by `exported`" — AND THAT WAS WRONG: it
  calls `items(f)`, and `items(f)` calls `self.parsed(f)`. A claim made from
  the layer above WITHOUT FOLLOWING THE CALL is this campaign's recurring
  error, and here it inverted the shape: MINTING ROWS IS NOT SUFFICIENT for
  a held module to be VISIBLE, because `exported_decls` would go on parsing
  the file the rung exists to skip. So `items(f)` — not `exported_decls(m)` —
  is where a held module must answer without a parse: SIX touch points, one
  of them a behaviour change that must not alter the parsed path.
- **THE DEFECT CAN BE THE ABSENCE OF A CHANGE, AND EVERY GATE PASSES.** A
  registration that fills the tables but leaves `items` reaching for `parsed`
  produces a build that is CORRECT AND NOT FASTER: the differential is green
  (both builds parsed everything, so both .ll's are identical), every gate is
  green, and the SAVING is simply absent. "A fixture that cannot exhibit the
  defect" is the same family, in the one place where the defect is the
  ABSENCE of an effect rather than a wrong value. THE RECEIPT THEREFORE
  PROVES THE THING IT EXISTS TO SKIP WAS SKIPPED — a CALL COUNT (did
  `parsed` run for this module?), never only a clock and never only an
  identical output.

- **A FILLED TABLE IS NOT THE WHOLE ANSWER WHEN A QUERY CELL DECIDES WHETHER
  THE TABLE IS CONSULTED.** `sig`'s short-circuit reads `if
  !(self.db.ask(k) is .Compute) || x.kind is .Builtin`, so a filled `sigs`
  row is returned ONLY when the cell is not `.Compute` — and a never-asked
  cell IS `.Compute`, so a minted declaration needs a FIFTH write
  (`db.set_input` or a settle) beyond the four tables. THE GUESS THAT WOULD
  HAVE HIDDEN IT: write the row, watch `sig` return it in the happy path, and
  the failure appears only for a declaration whose cell was never touched — a
  PLAUSIBLE WRONG SIGNATURE, which no gate catches.
- **A ROW THAT READS COMPLETE AND CARRIES NOTHING, ONE TABLE OVER.** A `Decl`
  carries `stmt` and `root`, and a MINTED declaration has NEITHER (there is no
  parse) — fine while nothing reads them, and LATER PASSES DO: lowering walks
  a declaration's `root`. So registration cannot be one pass. THE RULING:
  **SIGNATURES ONLY** — a held module's signatures are what a CALLER reads and
  its body is what (c)'s per-file IR is for, so the driver registers what the
  loader needs and leaves bodies alone. The alternative — minted declarations
  carrying a MARK every pass must honour — is a contract the whole backend
  keeps AND A FLAG BESIDE THE CLAIM, which this tree refuses because a flag can
  be set wrong and stay invisible. And a held module's FILE is not lowered, so
  its declarations never reach the tree-walking passes at all.

- **THE WITNESS FOR A CACHE IS A GHOST, NOT A CALL COUNT.** `util/m.av`
  declares exactly ONE fn; a name (`ghost`) was injected into the RECORD and
  nowhere else; and the workspace's answer for what that module exports grew
  by EXACTLY ONE (entries 7->8, mintable 3->4, minted 3->4, surface 3->4)
  with nothing else moving. A call count would have said `parsed` did not run
  — a PROXY. The ghost says the name could ONLY have come from the record,
  which is the PROPERTY ITSELF. So prefer the witness that could not be true
  any other way, and keep the control beside it: a targeted injection moves
  one count, in one module.
- **THE INVISIBLE WRITE IS THE ONE THAT MATTERS.** Four writes register a
  held module: `decls.mint` (the dense rows), `declare` (the signature),
  `minted.set` (visibility), and `db.set_input` (marking the signature CELL)
  — because `sig` consults `db.ask` BEFORE the table, so a filled row whose
  cell still read `.Compute` recomputes from a tree that is not there. The
  registration would have LOOKED correct and produced a PLAUSIBLE WRONG
  SIGNATURE. The three writes a reader can see are not the whole contract;
  the fourth is the one that makes the other three true.
- **A FORM THAT PARSES IN ONE PLACE AND NOT ANOTHER IS EITHER A DEFECT OR A
  READING, AND THE PROBE DECIDES.** The cache lane recorded rather than
  swallowed that `mut ids: List<DeclId> = []` was refused F0100 at the `<`
  while "the same form parses elsewhere in the tree". Probed here on a fresh
  package (`avra-lane-cache` @ `8bd4195`): the form PARSES CLEAN, and the
  tree carries four sites of the same shape. So the FORM is not the defect
  and the suspect is the reading or the context — but the report was still
  right to exist, because a workaround is how a real one would have died.

- **A DIFFERENTIAL PROVES CORRECTNESS, NEVER THAT WORK WAS SKIPPED — SO
  EVERY RUNG NEEDS A SECOND LEG.** (c) passed on the letter: `.ll`
  byte-identical (3888 bytes) AND diagnostics identical, with A genuinely
  minting and B genuinely not. The work count then said NO SPEEDUP —
  15.8s/15.1s minting against 15.6s/14.5s minting nothing. THE TRAP'S SHAPE:
  differential green, keepers green, saving ABSENT. That is the "fixture that
  cannot exhibit the defect" family, and this campaign has now named THREE
  members: a number taken against a stale artifact, a registration that was
  correct and not faster, and this one. A perf rung's receipt carries BOTH
  legs, and the second is the one that decides whether the rung is real.
- **THE WORK IS SAVED WHERE IT IS CHEAP AND PAID WHERE IT IS EXPENSIVE.**
  Minting saves a held module's ITEMS parse (`items` answers from the record)
  and pays its RESOLVE parse anyway — `analyze_all` calls `resolved(fi.id)`
  and `analysis(fi.id)` for EVERY file, and both call `parsed(f)`. So a cache
  covering the cheap half looks complete and moves the clock by zero: find
  WHERE the time is before deciding WHAT to cache.
- **A SKIP THAT REMOVES A FILE FROM `Program.files` ALSO REMOVES ITS BODIES,
  SO THE BODIES COME FIRST.** Skipping `resolve` for a held file drops it
  from `Program.files`, and LOWERING WALKS `Program.files` TO EMIT BODIES — so
  the skip without per-file IR produces a program MISSING ITS FUNCTIONS. **THE
  IR COMES BEFORE THE SKIP**, a build order decided by a measurement rather
  than by the design's convenience, and the split's own 1.06x (16.4MB whole
  against 17.3MB over 272 modules) is what says it is affordable.

- **A WORK COUNT IS TAKEN WHEN THE MECHANISM LANDS, NOT WHEN THE SAVING IS
  QUESTIONED.** The zero that (c) reported was found by measuring what the
  differential cannot see — and the cheapest time to take that measurement is
  the step that INTRODUCES the mechanism. So the per-file IR's FIRST
  measurement is the number of FILES EMITTED, and "correct and not faster" is
  caught on the step that causes it rather than two steps later. A perf
  receipt's work count is not a follow-up; it is part of done.
- **AN ENABLER'S RECEIPT IS NOT A NUMBER, SO BANK IT WITH THE SPEEDUP.** The
  identity half is inert (byte-identical `.ll`, identical diagnostics), so
  landing it alone spends a rebase, a seed refresh and a Sprite gate on
  nothing user-visible AND bakes an inert half into the committed seed. Land
  for a receipt rather than for a commit: the enabler rides with the number it
  enables.
- **THE ENTRY FILE GETS NO SEPARATE MODULE, OR ITS BODIES ARE EMITTED TWICE.**
  The per-file split is N modules — `emit_module(l, p_i, false, f_i)`, each
  DECLARING what its bodies name and DEFINING what it owns — plus ONE entry
  module (`..., true, f_entry`) which emits that file's bodies AND `main`
  exactly once, because `with_entry` decides who defines the entry. AND THE
  PIECE THAT MAKES IT CHEAP: `Body.file` is ALREADY set on the entry, so the
  split needs NO change to lowering — the pieces were standing.

