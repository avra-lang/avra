# avra-lane-lowering-quality

Branch `avra-lane-lowering-quality` on `batch41` (16a64281). Three commits, all in the program layer's
own lowering (one definition each; the old path's rules untouched).

## Soundness (#13, #25, #27): no bug — evidence

Each probe was a package built on the layer (`AVRA_PROGRAM=1 build/avra-try build`), run plain, under
`AVRA_RC_GUARD=1` and `AVRA_MEM_STATS=1`, and against `avra run` (eval). Lawful control: a joined
string released twice → exit 134 under the guard (0 unguarded): the guard is live.

- **#13** `state counter: List<int> = nap()` (the initializer parks), read by a task cancelled
  mid-initializer, then read again: the layer judges the state's unit by its own cancel fact — a
  caller of a unit that may park carries `flag unwinding` right after `call counter()`; one over
  `state plain: int = 0` carries none (precise, not conservative). Output `9` = eval, guard 0, 0 live.
- **#25** `mut x: Far? = Far{..}; x = null` ×1000: `call avra_cell_release(r8)` stands before
  `store r8 <- null` (3 cell releases in `drop`, 3 in `hold`), 0 bytes live at exit, guard 0, eval same.
- **#27** `stays` (the write stands between borrow and read): `avra_slot_get_owned` +
  `avra_array_get_owned`, released after the read; `skips` (the arm returns): plain gets. Driver
  that empties the bag through `touched` on every turn: guard 0, 0 live, eval same.
- The spec rows #22–#27 fail on the layer only because they find bodies by exact name
  (`body_of(text, "drop")` looks for `fn drop(`, `l.fns.find(it.name == "stays")`), while the layer
  names them `alone/src/main.av.drop`. Read directly, #22 (the minted text released before the test,
  inside the loop), #23 (the lending read borrows, no owned get), #24, #26 hold too.

## H fixes

| # | change | micro-benchmark (native --release, best of 3, same source) |
|---|---|---|
| 1–2 | a `defer`/`errdefer` whose body is one call of a declared fn or method, each operand a scalar literal or a name holding no counted reference, is that call lowered in place (cleanup landing + each exit), each name held as at the statement; no task test after it (as the pointer call has none). Anything else keeps the box. | 20M calls each of `defer note(x)` and `defer p.seen()` (flat record): **877 → 36 ms** |
| 3–5 | one code-point walk in the core (`core/code_points.av`): a `for`, a comprehension head and a walk chain whose source is `s.chars()` walk the text itself — step by the lead's declared width (1 where a tail is missing), decode in place, count the place apart. The `for` meaning leaves a chars view to the statement's own rule. | 36k-char text ×300 walks (for / comprehension / filter-count): **97 → 72 ms** |
| 11–12 | `m.set(k, f(m.get(k)))`: where the value reads `get` of the written place under the written key and names neither the root nor a key-name elsewhere, `put` probes once before the value, lends the probe to that read (taken only where root and key are still bound as found), and writes `avra_map_set_at` (`_maybe` for a nullable value). | 3M counted writes over 1000 keys: **51 → 39 ms** |

Semantics checked on the layer, guarded, eval == native: defer-time values for a reassigned `mut`
int and a reassigned flat record, `errdefer` on fail, early return, a cancelled task's deferred
in-place calls under the shield (one callee with its own `within`); hostile UTF-8 (`char_hostile`);
fused/unfused map writes (other key, map named again, key named again, `self.counts`, a field path,
text values with `_owned`, nullable values with `_maybe`). Program tests run on the layer as packages
under the guard, all matching `.expected`: defers (9), maps (34), chars (6).

## M items — read, not changed

- **#6–#10** (`const` seats never specialized): real; needs per-settled-value units on the layer.
- **#28** (no consumed mark): real. The consumes pass is the old Workspace's; the layer's bodies carry
  empty `marks`, and cross-bucket callee stubs (`declared_stub`) carry none either, so the memory
  pass can't move a dying argument. Needs a layer consumes query feeding `Body.marks` and the stubs,
  and the callers' saved answers keyed on the callee marks.
- **#23 / #26**: not gaps (see above).

## `ir_of` pins

`ir_of` (testing/mod.av) still lowers on the old path; none of these ir_of cases is pinned in
tools/gate/std-avrac.names, so there is no line to take away. The layer's IR was read with
`AVRA_IR_OF=<name>` on package builds.

## Receipts (HEAD 96e03588 unless said; e877558f only renames two `_ ->` arms to `rest ->`)

- `make try` (layer, release mode) exit 0 at each commit.
- `sh tools/gate.sh`: avrac-a PASS (306s), avrac-g PASS (286s), avrac-b PASS (662s; again at e877558f: PASS 712s)
  , avrac-c PASS (547s), avrac-d PASS (376s), avrac-e PASS (500s), avrac-f PASS (87s) — no unpinned
  failure; refusal-a PASS, refusal-b PASS, refusal-c FAIL on ONE case, `builds_map_key_alias`
  (`alias K = string; let m: Map<K, int> = {}` → type.applied), which fails identically with a compiler
  `make try`-built from batch41 itself (worktree at 16a64281): pre-existing, a typing law, not lowering.
  271/275 hold, 3 known to differ, 2 untooled.
- findings-a PASS (tapes --findings on std-avrac and cli, 0 refusals; std-avrac built, 0 false refusals).
- `AVRA_PROGRAM=1 build/avra-try build packages/cli --release` exit 0 (3m03s), and the product runs.
- `AVRA_PROGRAM=1 build/avra-try check packages/std-avrac` exit 0, 0 errors.
- `sh tools/witness_program_runs.sh build/avra-try`: nested, forks, guarded, rc, static_write and traps hold.
- idioms: `check packages/cli --baseline tools/idioms.baseline` (old path) exit 0 → 0 NEW.
- Benchmarks re-measured against a compiler built from batch41's own source (worktree), same sources,
  outputs `cmp`-equal: 869 → 36 ms, 99 → 71 ms, 50 → 39 ms.

## Unproven / not run

- AVRA_SOUND_CHECK=1 check packages/cli, the doors/cli/edit/warnings slices.
- The std-avrac spec rows #1–#5/#11–#12 still read the OLD path through `ir_of`; the layer's shapes were
  read with `AVRA_IR_OF` on package builds.

## Next I'd take

#28 (a layer consumes query feeding `Body.marks` and the cross-bucket stubs, callers keyed on it), then
#6–#10 (a unit per settled `const` value); and the spec helpers that find bodies by exact name
(`body_of`, `fns.find(it.name == ...)`) taught the layer's file-qualified names once `ir_of` moves.

---

# Second hand-back: #28 and #6–#10 (e877558f..26e5626c)

## #28 — consumed seats on the layer (df9197c0, 841c3f34)
- The consumes scan is ONE definition (`kept_seats`, compiler/consumes.av), parametrized by how a read
  names a seat: the old path's bindings, or a layer body's own `NamesRead` (seat binder, no lambda
  crossed).
- A free fn's unit (no method, host fn, `once`, case; seat not mut/const/state/isolated/spread/rest,
  counted layout) carries `LoweredFn.consumed`; its body wears the marks; its facts' `BodySeen`
  declares them, so a caller's bucket key ("what it sees") moves with them; `bucket_lowered` hands the
  memory pass marks-only weak stubs for consuming bodies homed in other buckets. A fn a lazily grown
  program makes late (callers made before it) consumes nothing.
- The memory pass's proof counted a body's seats by `b.params` (empty on layer bodies); it now counts
  by `b.seats`, as the pass does. Without that, the sound-checked cli build said 20918 false defects.
- Evidence: `always(p)` → `push_moved` (was retain); caller retains where p is read after, moves where
  it dies; a fn value's wrapper `always$w` retains first; cross-file callers read the marks; a const
  settled through a consuming fn at compile time = run. Guard clean, 0 live, eval == native.
  Witness `features/fns/tests/consumed_through_values` (2790 checked by hand); `consuming_params`
  now exercises the layer and holds under the guard.
- Self-build: `AVRA_SOUND_CHECK=1` layer build of cli → 0 defects; gen2 (built by this compiler)
  builds gen3 byte-identical (fixed point). Old-path `AVRA_SOUND_CHECK=1 check packages/cli`: 0 `defect: in`.
- Bench (3M calls handing records/text to consuming seats): 340 → 323 ms.

## #6–#10 — a unit per settled `const` value (9f7ac2dc, 26e5626c)
- A call of a declared free fn (generic included) whose `const` seats each get a literal, or a const
  whose value is one (top-level, a body const that settled, or a seat its own unit settles —
  forwarding), reaches `<symbol>$@<digest of seats+values>`, asked by its own query
  (`BodyAsked.Settled` → `lowered_settled`); the settled seats leave the call's seats and are bound
  in the body as settled consts, so a body `const` reading one settles at compile time per value.
  Anything else (a settled aggregate, named/spread args, a method) hands the argument as before.
- Shown: 2 `pick` units for "abc"/K and "xyz", 2 `pair`, 2 `first<T>`, 2 `inner` through 2 `outer`;
  `const h = heavy(p)` → `int 96354` in the unit. Witness `features/fns/tests/const_seat_units`;
  the package test `fns/tests/const_seat` matches its expected under the guard.
- Bench (`const weights = weigh(pattern)` per call, 4M calls): **790 → 61 ms**.
- Fixed point re-checked after #6–10: sound-checked gen2 0 defects, gen3 == gen2.

## Receipts at 9f7ac2dc (26e5626c only folds a duplicated line into a helper; rebuilt, idioms re-run)
avrac-a/g/b/c/d/e/f PASS; refusal-a/b PASS, refusal-c the one known `builds_map_key_alias`;
findings-a PASS; witness-b PASS; sound PASS; edit-a..g PASS (all seven); `--release` cli build 0;
layer `check packages/std-avrac` 0 errors; idioms 0 NEW at 26e5626c (2 NEW at 9f7ac2dc, fixed).

## Unpinning
Waiting on batch 42 (ir_of on the layer, the 29 pinned): I'll merge it and take away the lines my
fixes turn green (#1–5, #11–12, #28, #6–10), and report which of #22–#27 pass once the name lookups
read the layer's names.

---

# Third hand-back: batch 44 merged (batch44..a5ced332)

- Merge 5c976701: item_lowered.av, one definition — `answered_fn` (inference + typing) now also takes
  batch 44's `seats_taken`, read by both `lowered_under` and `lowered_settled`; the unwind frame keeps
  the settled unit's name with batch 44's `body_written_at`.
- d5878f9a: a regression of my #6–10 the layer-read spec found — `extern fn c_abs(const n: i32)`:
  an extern's / host fn's `const` seat was specialized (symbol and argument dropped). Externs and host
  fns now keep every seat their row takes (fns_adversarial "an extern `const` seat is no INOUT" passes).
- a5ced332: unpinned 12 IR cases. The cases found bodies by bare name; on the layer a lone program's
  bodies are `alone/src/main.av.<name>` (the spec already spells it so at lower_test:900), so their
  lookups read that: defers "a deferred call opens a cleanup region…" (#2); fns "TWO units",
  "specializes like a plain one", "keep their ORDER", "split PER VALUE", adversarial "THE VALUE
  alone" (#6–10); lower_test #22 MINTS, #23 LENDING, #24 settles at scope end, #25 null store
  releases, #26 costs no retain, #27 stays owned — all six pass under layer names.
- Still pinned: #28 "the body's own lowered marks say so" — its program isn't MADE on the layer
  ("a shown `List<P>`, which no text spells yet, at the entry": the entry's last value is a
  `List<P>` the layer can't print), so ir_of falls back to the empty program; the marks themselves
  hold (witness consumed_through_values; `always` → `push_moved`). Also still pinned, not this lane's:
  the comprehension nest, the three chain-order cases (#17–#21 order), pointer widths, aftercall,
  back-edge, cancel_reach, state cells.

Receipts at a5ced332: avrac-a..g PASS; refusal-a/b/c PASS (map_key_alias holds now); findings-a PASS;
sound PASS; edit-a..g PASS; witness-b PASS (first run failed `flow-trace` only on stores the
9f7ac2dc compiler left in build/flow-trace/*/.avra-cache — the gate doesn't empty them; emptied, it
passes; the re-run slice PASS); `--release` cli 0; layer `check packages/std-avrac` 0 errors; idioms:
1 NEW, `testing/held.av` repeated_unwrap — batch 44's own (its tree gives the same 1 NEW), 0 from this diff.

---

# Fourth hand-back: #28 on the layer (batch45c..ee14fe83)

The consumed-mark case's lone program wasn't made: its entry shows a `List<P>`, and the layer spelled
only scalars, text, and lists of int/bool/text. ee14fe83 spells an entry's answer built of numbers,
truths, text, lists and records, one definition (`value_spelled`, compiler/item_entry.av): a list
or a record is the list of its parts' texts joined by `avra_strs_text` — the evaluator's own format;
a list of ints/truths/text keeps its joining row. A nullable, an enum, a map, a self-holding type
stays unshown, as before (a bare record answer stays refused by the projection law).

- Evaluator (old path) vs layer, identical: `[[1, []]]`; records with string/float/bool/List<string>/
  List<int> fields `[[1, [a b, 1.5, true, [x, y], [3]]], [2, [, 0.25, false, [], []]]]`; `[[1, 2], [3]]`;
  `[1.5, 2.0]`; value record `[[1, 2.5]]`. Native under the guard: 0; the entry's IR releases every
  text it builds (live-at-exit bytes are the program's static literal data — the old row's
  `["a b", "c"]` reads 151 too).
- lower_test #28 passes; its line leaves the pinned list.

Receipts at ee14fe83: avrac-a..g, refusal-a/b/c, findings-a, witness-b, sound PASS; `--release` cli 0;
layer `check packages/std-avrac` 0 errors; idioms 0 NEW.

---

# Fifth hand-back: #16 and the ir_of pins at 0 (ee14fe83..4b536d4c)

Ranking (old path lone-file build vs layer package, native --release best of 3/7, outputs and evals
equal): only #16 cost anything (35 → 42 ms, 30M calls). Correction to the ranking post: the old
binary also reads the flag twice a turn; its exit was branchless (`cmovne`) because it pushed no frame
and ran no shield, where the layer's called `avra_unwind_push` + the shield pair inside the loop.

- b927efd3: a program that links no scheduler can't unwind (only a cancel or a passed limit raises the
  flag, met at a wait or a tick, which it never runs), so a test placed there keeps its read and its
  exit but calls none of the rows only an unwind reads (frame push, shield pair) — one rule in
  `tests_kept`, chosen by `TaskChecks.unwinds()`. r16: 42 → 33 ms (old 34), branchless as the old.
  Same commit: an `@unbroken` fn's own `while` carries no tick and is no cancel point (the old
  path's rule; the layer had a tick there) via `wears_meta` on the fn's statement.
- 4b536d4c: each remaining ir_of pin rewritten to the property its name claims, or its program fixed:
  comprehension (3 loops, 1 list, 1 push, output 6), chains (1 loop, no list / 1 push, no callptr,
  outputs), for-end (end evaluated once, `continue` moves on: "8 1"), unit-call test (tested where
  the unit may park, not where it can't), task cold exit / top-level park / pointer widths (case
  programs fixed: newline-separated statements, the spawned fn declared, the extern's answer not
  shown), state cell (the two representation pins became the behaviour, annotated local too).
  cancel_reach's shield case passes as written after b927efd3. The ir_of block of std-avrac.names: 0.

Receipts at 4b536d4c: avrac-a..g, refusal-a/b/c, findings-a, witness-b, sound, doors-a PASS; --release
cli 0; layer check std-avrac 0 errors; idioms 0 NEW.
