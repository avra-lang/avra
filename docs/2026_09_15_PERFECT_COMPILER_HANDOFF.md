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

## The full main→lane merge — OWED, and it is a PROJECT

`git merge-tree HEAD main` measures 20 conflicted files. At least eight
are SEMANTIC, where a textual union is wrong:

- `core/rebuild.av` — the lane DELETED main's `rebuilt_expr/stmt/pat`
  and derives those arms (`@derive(Rebuild)` + `verb_of`); main ADDED
  hand arms for its new variants. The union is the lane's structure
  plus main's `FormatPart` walk as a `verb_of` row, never both.
- `language/source_text.av`, `features/{decls,enums/check,enums/lower,
  fns/check}.av`, `language/{llvm,resolve}.av` — both sides moved these.
- `Makefile` — main replaced the hand-kept object list with one glob,
  a stem-uniqueness law, `tools/suites.py` and `tools/libs.py`; the
  lane has its own additions (`SEED_FLOOR`, `rt-header`, `witnesses`,
  `gate` deps, `avra_rt.h` in `runtime.sha`). The union is main's build
  system plus those five.
- `tools/{idioms.py,vocab.sh,watch.sh,integrate.sh}` — both lanes moved
  the keepers.

AND IT NEEDS A LADDER: neither parent's binary reads the merged tree
(the lane's payload-mark grammar vs main's later lexer). Rule the merge
WITH the compiler as oracle — which is now possible, because the lane
gates on a Sprite.

AT THE MERGE: take MAIN's version of `tools/sprite-build.sh` (it has
`--receipt`, `--prebuild`, the doctrine files and the root `avra` shim)
and main's `tools/sprite-provision.sh`.


## Phases

| | state | worktree / branch |
|---|---|---|
| A typed names, derived copier | **DONE** 2/2 | retired |
| B one meta vocabulary, one crossing | **DONE** 3/3 | retired |
| H side tables, derived identity | **DONE** 2/2 | retired |
| G runtime header + diagnostic witnesses | **DONE** 2/2 | `../avra-phase-g`, `phase/g` @ `efb1200`, merged, clean — retire it |
| C children + fingerprints derived | 2/3, **LIVE on C2, REDUCED** | `../avra-phase-c`. C2 is now C2a (the `Field` collapse, behaviour-neutral — node_grammar KEEPS its `ty` parsers) + C2c (the F2086 witness). **C2b is HELD and filed P1**: the uncommitted kind-based WIP is silently wrong — a derive's crossing sees enum payload kinds as `Unspelled("")` mid-resolve, so `rebuilt` stops rebuilding children and `@derive(Grammar)` misclassifies. The crossing must see the declaration's EARNED sig; that is a slice of its own and the real prerequisite for avra-9cbe/9tfi. |
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
