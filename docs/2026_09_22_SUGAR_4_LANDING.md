# Sugar 4 landing — emission as an expression

## Survey

### The want, measured against today's tree

The design (docs/2026_09_09_SUGAR_4_EMISSION_AS_EXPRESSION.md) asks for
one thing: an emission verb that mints a register AND emits the
instruction that defines it in ONE call, answering the register — so
"the mint law holds by construction" instead of by the writer
remembering to keep two statements adjacent and in order. Its own
`Cost` section already says the mechanism: "this is the emission
vocabulary's shape (features/emit.av), grown to answer registers."

Two sugars landed since this doc was written and paid most of its
motivation already:

- **Sugar 1** landed `const_int`/`const_bool`/`const_str` in
  `features/emit.av` — exactly `let n = cx.const_int(7)`, the design
  doc's own first example.
- **Sugar 3** landed `call`/`call_at`/`call_void` — exactly
  `let crossed = cx.call(row, octets)`, the design doc's own second
  example (`rt.str_of_bytes` is no longer the right spelling; the
  generated per-row methods, e.g. `cx.str_of_bytes(sh, octets)`,
  already close over the same `call`/`call_at` primitives).

So the trigger note ("Lands with sugar 1; the two together are the
lowering rewrite") undersold it — three sugars carry it, and the
runtime-call half is fully paid.

### What remains: 55 two-statement mint+emit sites, 16 files

`mint_shape`/`mint_ty`/`mint_like`/`result` bound to a `let`, followed
within a handful of lines by `(self|cx).emit(Ins.<Variant>(<same name>`
— counted by script (grep alone undercounts, the way sugar 3's survey
found for its own wrapper fns; this one walks the AST-shaped text by
hand), excluding `features/emit.av` itself:

```
Bin        18   Call        7   Un          6   Pack        5
ConstInt    3   CallPtr     3   Alloca      3   ConstStr    3
ConstBool   2   Load        2   FnAddr      1   ConstFloat  1
```

By file: `features/values.av` 14, `features/formats/lower.av` 11,
`features/expr_spine/lower.av` 7, `features/lists/walks.av` 4,
`features/impls/lower.av` 3, `features/maps/methods.av` 2,
`features/quote/lower.av` 2, `features/fns/lower.av` 2,
`features/enums/lower.av` 2, `features/loops/lower.av` 2,
`features/places.av` 1, `features/str_lit/semantics.av` 1,
`features/bool_lit/semantics.av` 1, `features/structs/lower.av` 1,
`compiler/lower/walk.av` 1, `compiler/lower/state.av` 1.

None of the six shapes above (`Bin`, `Un`, `Pack`, `Alloca`, `FnAddr`,
`Call`, `CallPtr`, a bare `Load`) has a vocabulary verb yet. Two
representative sites (`features/formats/lower.av`):

```avra
fn plus(mut cx: LowerCx, a: Reg, b: Reg) -> Reg {
    let r = cx.mint_shape(Type.Int)
    cx.emit(Ins.Bin(r, BinOp.Add, a, b))
    r
}
```

and (`features/impls/lower.av`'s `dyn_dispatch`):

```avra
let dst = cx.result(e)
cx.emit(Ins.CallPtr(dst, fp, [data].concat(s.args)))
dst
```

— the second already near-duplicates `features/values.av`'s
`called_through` (also a mint-then-`CallPtr`), the third-copy law
this sugar's sweep should collapse into one verb.

### A hazard found, not in the design doc: `const_int`/`const_bool`/`const_str` is the WRONG verb for a literal's OWN node

Three of the "remaining" `ConstInt`/`ConstBool`/`ConstStr` sites
(`features/expr_spine/lower.av`'s `.IntLit`/`.FloatLit` arms,
`features/str_lit/semantics.av`'s `str_reg`,
`features/bool_lit/semantics.av`'s bare literal `lower`) mint at
`cx.result(e)` — the NODE's own answer type — never at the fixed
`Type.Int`/`Type.Str`/`Type.Bool` `const_int`/`const_str`/`const_bool`
mint at. CLAUDE.md's named-type law ("A LITERAL fills a named seat
directly... `let id: UserId = 5`") means a literal's node can be typed
at a NAMED type, not the raw scalar — so `let dst = cx.result(e);
cx.emit(Ins.ConstInt(dst, v))` is not a lazier spelling of
`cx.const_int(v)`, it is a DIFFERENT mint. Sweeping these three sites
onto the existing `const_int`/`const_bool`/`const_str` would silently
drop a named literal's type at its own defining instruction. They need
a node-tied twin instead — `const_int_at(e, n)` etc., mirroring the
`call`/`call_at` split sugar 3 already established for exactly this
"fixed shape vs. this node's shape" fork.

### The mint-once/branch-into-several-emits exception

Two sites mint ONE register that several match arms or an early-return
branch may define (`features/values.av`'s `crossed_reg`,
`features/places.av`'s `field_slot`) — the same `dst` is read after
every arm, so it cannot collapse into a single verb call the way a
straight-line mint-then-emit can; MIRRORS sugar 3's two named
exceptions. These stay as they are, flagged so nobody re-litigates
them at the sweep.

### `compiler/suite_entry.av` — out of scope, named so nobody re-litigates

Builds the test binary's entry through its OWN `mint(ty) -> Reg` +
`e.give(...)`, a separate table and a separate builder from
`LowerCx`/`Ins.emit` (sugar 3's landing doc named this the same way,
"a follow-on, not a blocker"). Untouched here too.

## Decision

### Mechanism: grow `features/emit.av`'s emission vocabulary — no grammar, no comptime/derive

Exactly what the design doc's own `Cost` section already named. Proposed
new verbs (final names/signatures settle during Rung 0 building; this
is the shape, not a promise):

- `bin(sh: Type, op: BinOp, a: Reg, b: Reg) -> Reg` / `bin_at(e, op, a, b) -> Reg`
- `un(op: UnOp, src: Reg) -> Reg` / `un_at(e, op, src) -> Reg` (`UnOp` has
  one variant today; kept explicit for when it grows)
- `pack(ty: TypeId, elems: List<Reg>) -> Reg`
- `call_decl(sh: Type, callee: string, args: List<Reg>) -> Reg` /
  `call_decl_at(e, callee, args) -> Reg` — `Ins.Call`, a package's own
  declared-fn symbol; named apart from `call`/`call_at` (sugar 3's,
  `RtSig`-keyed) so the two never collide
- `call_ptr_at(e, f: Reg, args: List<Reg>) -> Reg` — absorbs
  `values.av`'s `called_through` and `impls/lower.av`'s raw site
- `fn_addr(sym: string) -> Reg`
- `load(sh: Type, cell: Reg) -> Reg` — a bare cell load not keyed to a
  node/type (`loaded`/`loaded_as` already cover the node/type-keyed
  cases)
- `uninit_cell(ty: TypeId) -> Reg` — mint + bare `Alloca`, no store
  (the per-turn element cell in `loops/lower.av`'s `lower_for_each`,
  filled after the turn opens — NOT `seeded_cell`, which requires a
  seed at birth)
- `const_int_at(e, n)` / `const_bool_at(e, v)` / `const_str_at(e, s)` —
  the node-tied twins the hazard above found missing

Plus a plain sweep (no new verb) of sites that already have a home and
simply aren't using it: `maps/methods.av`'s `got_reg` (Alloca+Store+
Load is exactly `seeded_cell` + `loaded`, unused), `loops/lower.av`'s
`lower_for` (same), and any `ConstInt`/`ConstBool`/`ConstStr` site
genuinely keyed at the fixed scalar shape rather than a node's.

### Checking seam and diagnostic: neither is new

Same as sugar 3: the rewrite only shortens a fn's body — every call
site is ordinary Avra, checked by ordinary typing (a wrong arg type or
count is the ordinary F2000/F2030 the ordinary fn/method call draws).
No new F-code diagnostic. The seam is `make idioms`: a new matcher
(mirroring I58's `raw_rt_call`) refusing `let X = cx.mint_shape(...)`
/`.mint_ty(...)`/`.result(...)` followed by `cx.emit(Ins.<Variant>(X,
...))` within a lowering file outside `features/emit.av`. Next free
number is I60 as of this worktree's DOGFOODING.md (re-check at landing
time per DOGFOODING's own collision law — main may have moved past it).

### Build ladder

Additive, same class as sugar 3's Rung 0/1 — new methods on an
existing pass-state struct, no new syntax, so no four-generation
syntax ladder is owed; `cp build/avra build/avra.pre` before Rung 1
regardless, matching the blast radius of touching ~16 hot lowering
files.

1. **Rung 0**: the new verbs in `features/emit.av`, tests
   (spec/given/then beside it). `make avra`, `./build/avra test
   packages/std-avrac`, gate, seed.
2. **Rung 1**: sweep the 55 sites + the two unused-verb sites, file by
   file. `cp build/avra build/avra.pre` first. `make avra` TWICE
   (product reading its own new spelling). An IR golden per swept file
   proving byte-identical `avra ir` output before/after, the same
   proof sugar 3's rung 1 used. Gate, seed.
3. **Rung 2**: the `make idioms` ratchet (I60 or whatever number is
   free at landing), CLAUDE.md's "THE EMISSION VOCABULARY" entry
   updated to name the new verbs.

Stopping here per the standing order — this changes what the
compiler's own source spells, and the verb names/signatures above are
a proposal, not yet a decision.
