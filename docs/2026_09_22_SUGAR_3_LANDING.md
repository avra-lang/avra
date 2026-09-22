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

### Mechanism: a generated, checked-in Avra source file

A new CLI command, `avra runtime-namespace`, mirroring
`avra runtime-header` exactly (same shape: a preamble, one entry per
row, a keeper), projects `rt_sigs()` into `packages/std-avrac/src/core/rt.av`:

    export type Rt = { str_of_bytes: RtSig, array_new: RtSig, ... }
    export const rt: Rt = Rt { str_of_bytes: RtSig { name: "avra_str_of_bytes", ... }, ... }

One field per row, named by stripping the row's `avra_` prefix (the
generator refuses on a row that does not start with `avra_` or on a
post-strip collision — neither fires today, per the survey above). A
`make rt-ns` gate step (added beside `rt-header` in the `gate:`
prerequisite list) regenerates into `build/rt.av.gen` and diffs
against the checked-in file, refusing drift with the same two-line
"regenerate it" wording `rt-header` uses.

This is the SAME mechanism twice, not a new one — CLAUDE.md's own
"prefer the variant that makes an existing concept more general"
applies to tooling as much as to the IR. It is also exactly what the
sugar-3 doc's own Cost section named as the fallback: "a checked-in
projection, regenerated by `make`, with a keeper that refuses drift."

### Form: `rt.<name>` plus three verbs, not one

`rt.<name>` is an ORDINARY struct field read on `core.rt`. A misspelled
name is F2003 "`Rt` has no field `<name>`" (`features/structs/check.av`'s
`fields_are(sig)`, which lists every real field) — an EXISTING
refusal, for free, satisfying "a row that does not exist is a
check-time refusal naming the nearest row" with zero new compiler
machinery, and checked at genuine TYPING TIME: `rt.<name>` is typed by
the same pass that types every other field read in the compiler's own
source, the moment the compiler's source is itself compiled.

Three new verbs in `features/emit.av`, in "THE EMISSION VOCABULARY"
section, replacing the five wrapper fns above and every raw
`self.emit(Ins.CallRt("avra_...", ...))` site:

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

The destination TYPE stays an explicit caller argument rather than
being derived from `row.answer`/`row.ret` — deliberately, because
`RtKind`/`Box` are too coarse to reconstruct it in general.
`Box.List` erases the element type, and several rows answering
`RtKind.I64` are NOT minted as `Type.Int` at their use site today (the
walk's element read mints at `w.elem`, not `Type.Int` — `emit.av`'s
`turn_elem`). Every existing wrapper already carries this same
caller-decides-the-type shape (`spelled_by` hardcodes `Type.Str`,
`rt_method` uses `self.result(mc.e)`); `cx.call` centralizes the ONE
thing that was actually duplicated — the `Ins.CallRt` plus its string
literal — without pretending to infer what only the call site's
context knows. This is a form-level deviation from the doc's two-word
example (`cx.call(rt.str_of_bytes, octets)`); I am reporting it before
building rather than choosing silently, since it is exactly the kind
of mechanism decision this survey step exists to settle.

Callee-string-hole (single-argument) rows compile to
`cx.call(Type.Str, rt.str_of_bytes, [octets])` — args still a
`List<Reg>` rather than variadic positional registers, matching every
existing call site's own shape (`Ins.CallRt`'s own `args: List<Reg>`
field) and needing no new grammar (variadic Avra fns are not in the
subset today).

`equality_word`/`length_word` change their return type from `string?`
to `RtSig?`, spelling `rt.streq` etc. in their arms; still exhaustive
matches.

### Checking seam: row NAME at typing, seat ARITY at a keeper plus a defect

Two separate mechanisms, honestly separated rather than one claimed
to do both:

1. **Row name** — F2003, as above. Real typing-time checking, for
   free.
2. **Seat count / kind / ownership** — NOT achievable as a static
   Avra-level check today. Giving `cx.call` a signature that varies by
   WHICH `RtSig` was passed would need generic bounds on structs or
   arity-polymorphic types, neither landed ("The subset today": no
   bound on a generic struct, no generic methods, no variadic fns).
   `RtSig` is one homogeneous type regardless of row; `args: List<Reg>`'s
   length is a runtime property. So:
   - A GATE-TIME KEEPER, `make rt-ns` (extended beyond the drift
     check above, or a sibling `make rt-calls`), walks the compiler's
     own source for every `cx.call`/`cx.call_at`/`cx.call_void(rt.<name>, [...])`
     site whose argument list is a LITERAL (the large majority) and
     checks the literal's length against `rt_sigs()`'s row for
     `<name>` — the same style `tools/idioms.py`/`tools/externs.py`
     already use to read the compiler's own source structurally,
     before the compiler ever runs it. This is genuinely
     typing-time-adjacent: a gate failure, not a crash.
   - For the residue (an args list built via `.concat`/a loop — none
     found in the 56-site survey, but the mechanism must not silently
     pass one), `cx.call`'s body carries a RUNTIME assertion:
     `args.length != row.params.length` refuses via
     `self.lower_defect(e, "…")`, the project's standing idiom for "a
     dispatch guaranteed this but the guarantee broke." Kind/ownership
     checking is deferred past this rung — it would need `cx.call` to
     read the same `reg_types` table the memory pass already reads,
     which is more machinery than this survey's mandate covers; I am
     naming it as a named gap rather than silently doing less than
     the doc implies.

   Because the compiler is self-hosted and `make gate` runs the whole
   spec corpus (plus the compiler compiling itself) every time, an
   arity defect fires on the FIRST body that reaches it in that same
   gate run — caught before anything ships, which is the honest,
   buildable version of "checked... not at emission" until
   `@comptime`-driven per-row typing is worth a much larger effort.
   I am stating this gap plainly rather than overclaiming a
   typing-time guarantee the subset cannot deliver — CLAUDE.md's own
   law about a help/remedy naming a form nothing checks applies here
   in reverse: a doc must not claim a check nothing performs.

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

(filled in as each rung lands)
