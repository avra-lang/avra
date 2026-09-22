# Sugar 3 landing — typed runtime rows

## Survey

### The sites

`grep -rn 'Ins.CallRt(Void)?(' packages/std-avrac/src`, tests excluded: 59
call/void-call sites across 21 files.

- 56 name their row with a STRING LITERAL (`"avra_str_of_bytes"`) — the
  direct sweep targets.
- 12 name their row with a `callee`/`word`/`symbol` PARAMETER threaded
  through a small wrapper fn, itself always called with a literal at
  ITS call sites. Two of these (`compiler/memory/memory.av:530,532`)
  rewrite an ALREADY-LOWERED `Ins.CallRt`'s string field (the owned-twin
  substitution) and are untouched by this sugar — the IR's own
  `CallRt.callee: string` shape does not change, only how FEATURES
  spell emitting it. The other 10 sit inside five wrapper fns that
  collapse into the new vocabulary (below).
- 1 (`features/fns/lower.av`'s `extern_call_reg`) names a PACKAGE'S
  OWN extern symbol, resolved per-call via `cx.extern_callee(e)` — not
  a `rt_sigs()` row at all. Out of scope; it is checked by the
  separate `checked_extern`/`crossing_law` path in
  `features/fns/check.av`.

The five wrapper fns to retire, each a private near-copy of the same
shape (dst = mint; emit CallRt; answer dst), CLAUDE.md's "third copy
names the concept":
- `features/values.av`: `spelled_by(callee, v)`, `rt_method(mc, callee, extra)`
- `features/formats/lower.av`: local `rt1(cx, sh, callee, a)`, `rt2(cx, sh, callee, a, b)`
- `features/str_lit/lower.av`: its OWN separate `rt1(cx, e, callee, v)` (a
  second, independent copy of formats/lower.av's — already a smell
  before this sugar)
- `compiler/lower/walk.av`: `text_call(callee, v)`

Two per-shape registries return `string?` today and should return the
row itself: `features/values.av`'s `equality_word(sh) -> string?`
(`avra_streq`/`avra_bytes_eq`) and `length_word(sh) -> string?`
(`avra_str_len`/`avra_bytes_len`/`avra_array_len`/`avra_map_len`).
Both are exhaustive matches (I22-safe) and stay exhaustive.

`compiler/suite_entry.av` builds its OWN separate `List<RtSig>` tables
(`runner_rows`, `program_rows`, via `extern_row(...)`) for the test
binary's entry, emitted through a different builder (`e.give(...)`,
not `LowerCx`). Some of its rows share a name with `rt_sigs()`
(`avra_puts`, `avra_streq`, `avra_int_text`, `avra_str_concat`) and
could be swept to `rt.puts` etc. as a bonus; its own rows
(`avra_case_begin`, `avra_capture_begin/end`, `avra_process_exit`)
have no `rt_sigs()` entry. Left alone this rung — a follow-on, not a
blocker.

### `rt_sigs()` today

`core/runtime_api.av`'s `export once fn rt_sigs() -> List<RtSig>`
returns 91 rows (verified: `grep -oE 'name: "avra_[a-zA-Z0-9_]+"' | sed 's/avra_//' | sort -u` also
counts 91 — no collision after stripping the `avra_` prefix, and none
of the 91 short names collides with a reserved word). `RtSig` (core/ir.av):

    export type RtSig = { name: string, ret: RtKind, params: List<RtKind>,
        owns_result: bool, has_owned_twin: bool, host: RtHost, lends: bool = false,
        keeps: List<bool> = [], cells: List<RtKind> = [], reach: Reach = Reach.Pure,
        boxes: List<Box> = [], answer: Box = Box.Any, inert: bool = false }

The five registry consumers named in `runtime_header.av`'s own module
doc: the backend DECLARES from it (`llvm.av`'s `rt_sigs().concat(l.externs)`),
COERCES arguments by it, the memory pass derives OWNERSHIP from it
(`rt_owns`/`rt_owned_twin`/`rt_lends`/`rt_keeps`), lowering REFUSES an
unknown extern callee against it (`features/fns/check.av`'s
`checked_extern`), and the interpreter HOSTS every row by its `host`
column. A sixth, narrower reader: `core/runtime_header.av` projects it
into the C header's static asserts (`make rt-header`, already a GATE
step). None of these change — they keep reading `rt_sigs()`/`rt_index()`
exactly as today; `rt` is a NEW projection alongside them, not a
replacement.

`rt_sig_of(name)`/`rt_index()` already give O(1) named lookup; no new
runtime data structure is needed.

### The comptime/derive question

Read `compiler/derive.av` and `features/statics.av` (the comptime/derive
machinery that landed on main since the doc was written, 2026-09-13/14).
Neither fits: `@derive(X)` types the ANNOTATED DECLARATION's own shape
(a struct's fields, an enum's variants) and generates methods against
it — there is no derive surface for "project this arbitrary `List`
that a `once fn` computes into a namespace of named consts."
`features/statics.av` lays out a PROGRAM's own const data as binary
globals at link time (the "a settled aggregate is static data" law) —
it is about the TARGET program's data, not about generating the
COMPILER's own source. Comptime buys nothing here that
`runtime_header.av`'s existing pattern does not already buy.

## Design decision

STD MASTER's ruling on the survey approved deviation 1 (the caller
keeps the destination type) and ordered a probe before accepting
deviation 2's keeper-plus-defect plan: generate ONE FN PER ROW, with
the row's ARITY riding the fn's own SIGNATURE, so a wrong seat count
is the ordinary fn-arity refusal at typing — no keeper, no defect.

### Probe (in /tmp/sugar3/, discarded — not part of the tree)

A struct whose fields are `fn(mut Cx, ...)`-typed, filled by named
top-level fns, called through the field: `./avra check` on the happy
path exited 0 (past typing, into a later const-settlement defect —
below); the wrong-arity call refused at TYPING with
`error[F2000]: 'one' takes 2 arguments, found 3`; the misspelled-field
call refused with `error[F2030]: 'Rt' has no method 'thre'`
(`Rt` — treating `receiver.name(args)` as a method call first, field-
as-callable only as a fallback; still a real, typing-time, check-time
refusal, just F2030's wording rather than F2003's). A LAMBDA directly
as the struct's field value does NOT parse the same way
(`error[F0100]: expected BREAK` on `(mut cx: Cx, a: int) -> int { ... }`
in a field position) — named top-level fns are the only proven shape.

One real finding: a top-level `const rt: Rt = Rt { one: one_body, ... }`
whose fields are FN VALUES traps at a LATER pass with
`error[F0900]: defect: a compile-time value did not cross as 'Rt'` —
const-settlement ("A SETTLED AGGREGATE IS STATIC DATA") cannot fold an
aggregate holding fn references. A plain `let` or a `once fn` (the
exact shape `rt_sigs()` itself already uses) avoids it entirely and
still types clean. **Verdict: the mechanism works — build it, as a
`once fn`, never a `const`.**

### The mechanism, once built, forced a second correction: I39

Built as designed — a generated `Rt` struct of fn-typed fields, filled
by 91 generated top-level wrapper fns, each `fn rt_<name>(mut cx:
LowerCx, ...) { cx.call(...) }` — `make idioms` refused it OUTRIGHT,
one violation per wrapper: **I39, "a vocabulary verb as a free fn
taking a pass state first — the state's impl is its vocabulary: write
`mut fn verb(…)` there and call `cx.verb(…)`."** This is CLAUDE.md's
Style law ("A pass CONTEXT carries the pass's STATE verbs only... A
feature-named fn on a cx... is a rule body living in a driver") caught
by its own ratchet, already in the tree from sugar 1: every one of the
91 generated wrappers is EXACTLY the free-fn-taking-cx-first shape I39
exists to refuse.

So the namespace pivots to what I39 already demands: **91 generated
METHODS directly on `LowerCx`**, not a separate `rt` value at all.
`core/rt_namespace.av` now emits ONE `impl LowerCx { ... }` block, one
method per row:

    mut fn str_of_bytes(sh: Type, a0: Reg) -> Reg {
        self.call(sh, rt_sig_of("avra_str_of_bytes")!, [a0])
    }
    mut fn puts(a0: Reg) {
        self.call_void(rt_sig_of("avra_puts")!, [a0])
    }

A call site reads `cx.str_of_bytes(sh, octets)` / `cx.puts(text)` —
CLEANER than the design doc's own `cx.call(rt.str_of_bytes, octets)`,
with no separate namespace value or lookup at all. This is a bigger
deviation from the original doc than deviation 1 was (dropping `rt` as
a value entirely, in favor of `cx` itself being the one namespace
every pass site already holds), forced by an EXISTING gate rule rather
than chosen — I am reporting it in this same landing doc rather than
stopping again, per the standing order to proceed through Rung 0's
gate; happy to revisit if this reads wrong once seen whole.

`equality_word`/`length_word` (values.av) will still change their
return type from `string?` to `RtSig?` at the sweep rung, since the
consuming call sites now read `cx.<the row's own method>(...)`
directly rather than through a shared `word`-parameterised helper —
each ARM of those two matches becomes a direct method call, so the
two fns likely collapse into the call sites themselves rather than
surviving as a separate `RtSig?`-returning registry. Decided at the
sweep, not here.

### Form: `cx.<name>(...)`, checked in full at typing — no keeper needed

Both halves of "checked at typing time — seat count, seat kinds,
ownership" are now genuine, ordinary Avra typing, with ZERO new
compiler machinery and ZERO keeper beyond the drift check:

- **Row name**: a misspelled `cx.str_of_byte(...)` is F2030 "`LowerCx`
  has no method `str_of_byte`" — the SAME refusal every other missing
  method on any receiver draws.
- **Seat count**: a wrong-arity `cx.array_push(box)` (one argument to
  a two-seat row) is F2030 "`LowerCx.array_push` takes 2 arguments
  beside `self`, found 1" — the SAME code the name check draws,
  because a method call's arity mismatch and its missing-method
  refusal are one family (F2030), not the ordinary fn-arity F2000 —
  the probe above drew F2000 because it called a FN VALUE held in a
  struct field, a different call form from the landed one. Re-verified
  directly against the landed mechanism (red-team, 2026-09-22): a
  misspelled name and a wrong seat count both fire as F2030 on a real
  generated method, at typing, on the compiler's own source.
- **Seat kind**: every seat is `Reg` regardless of `RtKind` — a
  register is a uniform IR handle; the KIND a seat takes is the
  backend's question (`ll_rt_kind`/`rt_arg`), never this projection's,
  so there is nothing for Avra's own type system to check here — this
  was already true of the OLD raw-string form (`Ins.CallRt`'s `args`
  field is untyped-by-kind too) and stays exactly as safe as it was.
- **Ownership**: unchanged — the memory pass still derives it from
  `rt_owns`/`rt_owned_twin`/`rt_lends`/`rt_keeps` reading `rt_sigs()`
  by the row's `name`, which every generated method still carries
  (`row.name`, read once per method body via `rt_sig_of`).

`self.call`/`self.call_at`/`self.call_void` (in `features/emit.av`,
under "THE EMISSION VOCABULARY") stay as the ONE shared primitive
every generated method delegates to — this satisfies "the third copy
of a shape names the concept" for the five near-duplicate wrapper fns
the survey found, and keeps `Ins.CallRt`/`CallRtVoid` emission behind
one door:

    mut fn call(sh: Type, row: RtSig, args: List<Reg>) -> Reg {
        let dst = self.mint_shape(sh)
        self.emit(Ins.CallRt(dst, row.name, args))
        dst
    }
    mut fn call_at(e: ExprId, row: RtSig, args: List<Reg>) -> Reg {
        let dst = self.result(e)
        self.emit(Ins.CallRt(dst, row.name, args))
        dst
    }
    mut fn call_void(row: RtSig, args: List<Reg>) {
        self.emit(Ins.CallRtVoid(row.name, args))
    }

The destination TYPE stays an explicit caller argument on `call`
itself, deliberately, because `RtKind`/`Box` are too coarse to
reconstruct it in general (`Box.List` erases the element type, and
`avra_array_get`'s callers mint at the walk's element type, not
`Type.Int`) — a generated method's OWN `sh: Type` parameter is how
that context still reaches the call site.

### Mechanism: a generated, checked-in Avra source file

`avra runtime-namespace` (a new CLI command mirroring
`avra runtime-header` exactly) projects `rt_sigs()` into
`packages/std-avrac/src/features/rt.av` — `features/`, not `core/`,
because the generated methods are typed against `LowerCx`, a
`features`-layer type; `core -> features` is the wrong direction for
the generator's OWN imports to run, but the generator itself only
EMITS the words "LowerCx"/"Type"/"Reg" as text (exactly as
`runtime_header.av` emits the word "int64_t" without importing C
types), so `core/rt_namespace.av` stays in `core/` while its OUTPUT
lives in `features/`. A `make rt-ns` gate step (beside `rt-header` in
the `gate:` prerequisite list) regenerates into `build/rt.av.gen` and
diffs against the checked-in file, refusing drift with the same
two-line wording `rt-header` uses.

### Out of scope, named so nobody re-litigates

- `features/fns/lower.av`'s `extern_call_reg` (a package's own extern
  symbol, not an `rt_sigs()` row).
- `compiler/memory/memory.av`'s owned-twin substitution (rewrites an
  ALREADY-LOWERED instruction's string field; `Ins.CallRt`'s own shape
  is unchanged by this sugar).
- `compiler/suite_entry.av`'s `runner_rows`/`program_rows` (a separate
  table, a separate builder) — a follow-on, not a blocker.

### The ladder

Rung 0 is additive (a new const, a new type, three new methods — no
grammar change, no new syntax), so it does not need the four-generation
syntax-change ladder; it needs the ordinary one-generation-ahead
build any new library fn needs. Rung 1 touches ~56 sites across the
compiler's own hot lowering paths, so `cp build/avra build/avra.pre`
before it regardless, per "A SYNTAX CHANGE... runs in one order" 's
spirit even though this is not a syntax change — the blast radius is
the same.

1. **Rung 0**: `core/rt.av` (generated, checked in) + `avra runtime-namespace`
   + `make rt-ns` (drift + arity keeper) + the three `cx.call*` verbs in
   `emit.av`. Old raw-string sites untouched and still compile.
   `make avra`, `./avra test packages/std-avrac`, gate, seed.
2. **Rung 1**: sweep the 56 literal sites + the five wrapper fns + the
   two registries, file by file. `cp build/avra build/avra.pre` first.
   `make avra` TWICE (product reading its own new spelling), an IR
   golden per swept file proving byte-identical `avra ir` output
   before/after the sweep, gate, seed.
3. **Rung 2** (recommended, matching sugar 1/2's own precedent of
   retiring the old form once swept): a `make idioms` ratchet refusing
   a NEW raw-string `Ins.CallRt("avra_...", ...)` site outside
   `emit.av`'s three verbs and the two named exceptions
   (`fns/lower.av`, `memory.av`). New idiom number picked at landing
   time (this worktree's DOGFOODING.md tops out at I55; main has since
   landed I56 — per DOGFOODING's own collision law, `make idioms`
   itself refuses a repeated number, so no manual coordination is
   needed beyond re-checking at landing).

## Landed

**Rung 0** — additive infrastructure, gate green (`make gate` status 0,
`rt-ns: 91 row(s) reach a typed LowerCx method`, `rt-header: 91 row(s)
claim a C body`, `6026/6026 tests passed` over `packages/std-avrac`):
- `packages/std-avrac/src/core/rt_namespace.av` — the generator
  (`runtime_namespace() -> string`).
- `packages/std-avrac/src/features/rt.av` — the generated, checked-in
  `impl LowerCx` block, 91 methods.
- `packages/std-avrac/src/core/tests/rt_namespace_test.av` — spec/
  given/then over the generator's output shape.
- `packages/std-avrac/src/features/emit.av` — `call`/`call_at`/
  `call_void` added to "THE EMISSION VOCABULARY".
- `packages/cli/src/commands/runtime_namespace.av` + `main.av` — the
  `avra runtime-namespace` subcommand.
- `Makefile` — `rt-ns` gate step, wired into `gate:`.

No existing call site swept yet; old raw-string `Ins.CallRt` sites are
untouched and still compile. Commit history follows.

**Rung 1** — the sweep, gate green:

The survey undercounted. `grep 'Ins.CallRt('` only finds DIRECT
sites; `values.av`'s `rt_method(mc, "avra_...", extra)` wrapper (a
method-call shape: subject + `mc.args` + extra, dst minted at
`result(mc.e)`) had 21 further call sites invisible to that grep —
`bytes/lower.av` (8), `lists/walks.av` (3), `str_lit/lower.av` (10,
one of them `char_code`'s two-branch form). Counting these, the true
site count was ~79, not 56.

Three helper fns (`values.av`'s `grown_box`, `tagged_value`, `fn_box`)
took an ALREADY-MINTED `dst: Reg` as a parameter — their own single
`avra_array_sized` call target, pre-minted by ~17 callers across 10
files so the same register could be pushed into afterward. Since a
generated method always mints its OWN destination, these three were
refactored to mint internally and RETURN the register instead —
mechanically safe because every one of the 17 callers minted `dst`
solely to hand it to the helper and used it for nothing else in
between (checked at each site). One site
(`compiler/lower/state.av`'s `fn_value_reg`) minted through a
MONO-SUBSTITUTED type (`self.concrete(self.facts.type_at(e))`, not
plain `self.type_at(e)`) — preserved exactly via
`self.view.types.shape_of(self.concrete(self.facts.type_at(e)))`,
which is provably the same register by the interning identity
`intern(shape_of(ty)) == ty`.

Where a destination was minted via `self.result(e)`/`cx.result(mc.e)`
(an expression's own answer register) rather than a literal `Type`,
call sites use `cx.shape_at(e)`/`self.view.types.shape_of(ty)` — both
provably equivalent to the original minting path via the same
interning identity, confirmed by the IR-diff proof below.

Found and deleted along the way: `str_lit/lower.av` carried its own
private `rt1` wrapper, wholly UNUSED (dead code predating this sugar
— its only references were in a different file, `formats/lower.av`,
which has its OWN separate `rt1`/`rt2` — two independent copies of
one shape, one of them already dead). `equality_word`/`length_word`
(the two `string?`-returning registries named in the survey) are
retired — inlined as exhaustive `match`es over `Type` at their one
call site each (`values.av`'s `same_value`, `emit.av`'s
`measure_of`), calling the generated methods directly in the
text/bytes arms.

Swept: `values.av`, `emit.av`, `places.av`, `cells/mod.av`,
`maps/methods.av`, `maps/lower.av`, `formats/lower.av`,
`lists/walks.av`, `lists/lower.av`, `expr_spine/lower.av`,
`mutation/lower.av`, `structs/lower.av`, `str_lit/lower.av`,
`bytes/lower.av`, `quote/lower.av`, `closures/lower.av`,
`enums/lower.av`, `impls/lower.av`, `compiler/lower/walk.av`,
`compiler/lower/state.av` — 20 files, ~79 sites, zero raw-string
`Ins.CallRt`/`CallRtVoid` sites left outside `emit.av`'s three
primitives and the two named exceptions (confirmed by
`grep -rn 'Ins.CallRt(Void)?(' packages/std-avrac/src` after the
sweep — every remaining hit is `row.name`-keyed in `emit.av`, a
package-extern symbol in `fns/lower.av`, or `compiler/suite_entry.av`/
`compiler/memory/memory.av`'s named exceptions).

`make avra` succeeded on the FIRST build after the sweep (no syntax
change, so no four-generation ladder was needed) — `cp build/avra
build/avra.pre` was taken first regardless, per the plan, and proved
unnecessary this rung. `./avra test packages/std-avrac`:
`eval == native == expected` on every program, unchanged. IR-identity
proved directly: `avra.pre ir <file>` vs the swept `avra ir <file>`,
byte-for-byte, over every test file under `features/lists/tests`,
`features/maps/tests`, `features/structs/tests`, `features/enums/tests`,
`features/cells/tests`, and `features/bytes/tests/bytes_scan` (154
lines, exercising `avra_bytes_run`/`eq_at`/`ieq_at`/`of_str` and list
comprehension) — zero diffs. `make gate`: green, no new warnings in
any swept file. `make seed`: regenerated.

**Rung 2** — the idiom ratchet, gate green:

`tools/idioms.py`'s `raw_rt_call` (I56) refuses a NEW
`Ins.CallRt(Void)?(..., "avra_...", ...)` site outside the three
named exceptions (`features/emit.av`'s own primitives,
`compiler/suite_entry.av`'s separate row table, `compiler/memory/
memory.av`'s owned-twin substitution). Registered in `DOGFOODING.md`
(next free number at this worktree's base — collision handled by the
tool's own duplicate-number check per the standing law, not by hand
coordination).

Running it against the swept tree found 3 real hits, none from the
sweep itself:
- `core/rt_namespace.av`'s own module doc quoted the OLD raw form as
  a worked example — reworded to prose, since a doc comment
  reproducing the very shape a ratchet refuses is a false positive
  the ratchet correctly caught.
- `compiler/tests/settle_test.av`, two sites: this test constructs
  SYNTHETIC `Ins.CallRtVoid` instructions BY HAND to probe the const-
  settlement REACH LAW directly — the row's NAME is the test's own
  subject (one case tests `"avra_io_write"` reaching the World, a
  third — unflagged, since it does not start with `avra_` — tests
  `"sqlite3_open"`, a row `rt_sigs()` does not know at all, so no
  generated method could exist for it regardless). Licensed at both
  sites (`// LICENSED I56: …`) rather than exempting the whole file:
  a test file CAN still accidentally spell a feature-shaped raw call,
  and a blanket file exemption would stop the ratchet from ever
  seeing that.

`python3 tools/idioms.py --self-test`: green (the new matcher's
SPECIMENS fire, its CLEAN fixtures — the generated method form —
do not). `python3 tools/idioms.py`: "no new violations. debt 0 ()
— 538 file(s) in 19 package(s), next free I57". `make gate`: green
(one `std-http` adversarial network test failed once, reproduced as
FLAKY — 434/434 clean on an isolated re-run of `packages/std-http`
alone, and the full gate re-run came back clean; the test is
timing-sensitive by its own name and untouched by this sugar).
`make seed`: `bootstrap/seed.ll` unchanged byte-for-byte (nothing in
`packages/cli`'s own compiled output moved); `bootstrap/seed.sources`
updated for the changed source hashes.
