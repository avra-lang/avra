# Comptime — `const`, annotations, quotes

> **STATUS 2026-09-13 (lane/comptime):** S1 (the reach refusal's full
> call chain included), S3f, S3g, S3h (`@deprecated`) and **S4** DONE —
> the `quote { … }` literal with `${}` holes, generated source parsed
> into the asking file's own store, and `@derive` with `Show`/`Eq`
> shipped in `@std/derive` (a struct and an enum, eval == native ==
> expected), and **the compiler DERIVES ITS OWN accessors**
> (`@derive(Projections)` on `DeclSig`; `BEYOND` below). **S5a, S5b
> and S5c DONE** — a fn seat's contracts are ONE `SeatMark` channel
> (`mutable`, `settled`), a `const` mark parses on every param list,
> a settled seat's VALUE fingerprint rides the call's `Sub` (one unit
> per distinct value), and a `const` in a unit FOLDS to that value.
> The folding slice also fixed a P1 wrong answer at HEAD (a `const`
> reading a plain parameter was silently mis-settled). **S1's `export
> const` LANDED** too — an exported top-level `const` is a declaration
> and crosses a module. **DOGFOODED on the compiler itself**: 86
> zero-arg constant fns became `export const` (368 call sites), the
> grammar and the diagnostic registry now settle once, and a module
> may hold a private `const` (F0902 was about effects, not values).
> The sweep exposed the one gap left, PAID on comptime/const
> (2026-09-13): EVERY top-level `const` is a module declaration like
> a private `fn` — order-free, visible across the module's files,
> exported only when it says so — and 58 `export`s the sweep owed
> came back off. **THE S5 REFINEMENTS LANDED** — a settled seat FORWARDS
> to another fn, and a direct AGGREGATE literal settles a seat; both
> ride the ONE S5c channel, widened to the crossing tree every
> compile-time value already travels as. **S4r LANDED (2026-09-13)**:
> a quote is a `Code` VALUE whose runs remember the file that wrote
> them (`@std.meta.Code`, `Piece`, `joined`, `spliced`); the resolver
> keys a generated node's binders and reads by that origin and looks
> a template's module names up in the writing file — ORIGIN HYGIENE,
> proven by a derive calling its own private helper unqualified and a
> template `let tmp` that cannot capture the user's; every diagnostic
> inside generated code is HOMED at the template line (or the asking
> annotation), and a generated source that does not parse now SPEAKS
> there. `Code<T>` is decided: untyped `Code` (§7 question 2). **See
> the LANE HANDOFF at the top of §6** for the laws pinned, the seams,
> and where to pick up.

Designed 2026-09-09, from first principles, for ratification.

Sources, in authority order: the spec (1.2 erased binary, 1.3 unified
lifted code, the `@derive` note, Axis 17 providers, Axis 30
annotations, 14.4 totality); this tree's seams (every `file:line`
below is here); the old tree's build and its recorded pain
(attributed, `../forge-crafting-intepreters`); prior art (§2).

The one-line thesis: **comptime is not a feature. It is the program
running earlier.** Everything below is what falls out of taking that
literally in a tree that already has one IR, two engines that read
it, and a query kernel that memoizes by fingerprint.

---

## 0. The affordance story

Five things a program can say. No new keyword beyond `quote`; no
marker on a fn; no second language.

```avra
// 1. A value the compiler computes. Every read IS the value.
const CRC: List<int> = crc_table(256)

// 2. A trait writes its own impl for a type.
@derive(Show, Eq)
type Pt = { x: int, y: int }

// 3. A fn wraps a fn. `traced: fn(Fn, string) -> Fn`.
@traced("http")
fn handle(req: Request) -> Response { ... }

// 4. A seat the caller must settle. The body folds per pattern.
fn matches(const pattern: string, s: string) -> bool {
    const prog = compile(pattern)      // once per distinct pattern
    run(prog, s)
}

// 5. A build input the compiler tracks. Edit the file, rebuild.
const DEFAULTS: Config = parse(embed("defaults.toml"))
```

And two things a program can ask:

```
avra expand src/user.av     # the file as compiled: consts settled,
                            # generated declarations inlined, each
                            # marked with what generated it
avra explain @traced        # its signature — which IS its effect
```

Ceremony count, for P3: a derive is a fn that answers `Decls`; an
annotation is a fn whose first seat is a declaration; a comptime
value is `const`. Three words the language already has, one it does
not (`quote`).

---

## 1. Principles applied — six paradoxes collapsed (P6)

Each row is a binary choice every other language made. Avra refuses
the premise.

| the false dichotomy | who picked a side | Avra's collapse |
|---|---|---|
| **comptime (values) vs macros (syntax)** | Zig values only (so no `@derive`); Rust both, separately | **Code is a value.** `Decls`, `Code<T>` are ordinary types; a `quote` is a literal of that type. A derive is a fn from a `Type` to `Decls`. |
| **annotation vs function** | every language: a registry, a naming convention (`derive_X`), a plugin API | **An annotation IS a call.** `@name(args) decl` evaluates `name(decl, args)` at compile time. Resolution is `use`. There is no registration API. |
| **declared effect vs actual effect** | spec 30.3's `Effect.{metadata, validate, transform_body, derive}` enum | **The answer type is the effect.** `-> Decls` adds beside; `Fn -> Fn` replaces; `-> Diagnostics` validates; `-> void` is metadata. A flag can lie; a signature cannot. |
| **comptime evaluator vs runtime semantics** | Zig (comptime int ≠ runtime int), Nim (VM gaps), old tree (two 400-line codecs) | **One IR, one interpreter, already built.** `language/interp.av` runs the post-memory stream; `eval == native` is a gate. Comptime is that interpreter with arguments. |
| **comptime params vs generics** | Zig `comptime T: type`; C++ non-type template params | **`const` is a seat mark, like `mut`.** Mono already keys on types (`Sub`); a `const` seat adds its value to the key. Zig's whole system is two words we have. |
| **quote vs embedded sublanguage** | every macro system has its own quasi-quote | **A quote is Avra as a sublanguage.** `grammar { }`, `table<R> { }`, `sql { }` and `quote { }` are one shape: a block parsed by a grammar, typed by its builder, holes spelled `${}`. |

And the one the spec already made: **no separate meta-language.**
The compiler is a package (`@std/avrac`); the meta surface
(`@std/meta`) is Avra types and Avra fns. A derive is tested like
any fn.

---

## 2. Prior art — what each got right, what we take, what we refuse

| language | its best idea | we take | we refuse |
|---|---|---|---|
| **Zig** | comptime = partial evaluation of the same code; types as values; lazy per-decl analysis with cycle errors | the mental model; `const` seats; demand-driven queries with a diagnosed cycle | duck-typed generics (P9); no code generation (kills `@derive`); a second integer semantics |
| **Rust** | MIRI: const eval runs the compiler's own IR — one semantics | that architecture (ours is `interp.av`) | proc macros over token streams with no types; `const fn` as a growing subset; `derive` found by crate name |
| **Jai** | `#run` anything; metaprogram sees typed declarations | full-language comptime; declarations as values | string `#insert`; the imperative message loop |
| **Nim** | `quote do:` with typed access; templates hygienic | quotes + hygiene by origin | the untyped/typed two-tier; a VM with a "cannot" list |
| **D** | CTFE of ordinary fns; `static if` | CTFE of ordinary fns | string mixins (every user's regret) |
| **C++ P2996** | reflect → opaque value; splice → code; `consteval` fns in between | the value ↔ splice shape (`Type` in, `Code` out) | the syntax (`^^`, `[: :]`) |
| **Racket** | phase separation as a principle; scope-set hygiene; partial expansion to discover definitions | two-tier namespace (written first, generated on a miss); hygiene as a side table | syntax-only macros (no types) |
| **Scala 3** | `inline`; typed quotes `'{ }`/`${ }` with `Expr[T]`; stage in the type | `Code<T>`, `${}` splices | full stage typing (its cost is the whole type system) |
| **Lean 4** | syntax categories + macros + elaborators in one file; the best-designed extensible syntax | the ambition; sublanguages via `grammar { }` | in-file extension of Avra's own grammar (embedded-languages non-goal stands) |
| **Julia** | `@generated`: a body computed from argument TYPES | mono per const seat is this for values | `eval` at runtime |
| **Elixir** | AST is plain data; `quote`/`unquote`; hygiene default | the plain-data feel (a `Code` value is a template + holes) | `unquote` naming (`${}` is Avra's hole) |
| **Haxe** | macros run in the compiler's typer with full access; cached per build | the compiler as the meta host; memoized | a separate macro interpreter |
| **Swift 5.9** | macro ROLES declared (`@attached(member)`) | roles — as answer types, not attributes | out-of-process plugins over syntax |
| **Mojo** | comptime interprets the same IR that compiles | same | — |
| **Old tree** | `quote stmt { }` splicing real arena nodes; `@derive` engine; purity walk before any fold; step + memory budgets | budgets; provenance blame (`[from @expand(m)]`); the derive-engine shape as a *library* | the pass-ordered expand fixpoint (cap 16, F4012); `@expand` on a placeholder; `~` splice; a deny-list of C symbols; two hand-written codecs; a closed derive registry |

The two old-tree lessons that shape §4: the **founding bug** (expansion
ran after resolution, so generated declarations were invisible; fixed
by a bounded fixpoint) is a pass-grained design fighting a
demand-driven problem — this tree's `sig(DeclId)` is already lazy
(`workspace.av:390`), so the cure is a family, not a fixpoint. And the
**codec debt** (Value ↔ AST, ~800 lines) came from macros building
trees in "Value space"; a quote as a *pre-parsed template plus hole
fillings* makes the crossing tiny (§4.3).

---

## 3. The surface

### 3.1 `const` — the demand

`const NAME[: T] = expr` settles `expr` at compile time. Today the law
accepts a literal and says so (`features/consts/check.av:29-36`, F2045
"today that means a literal"). The law's wording already names the
change: "tomorrow anything the evaluator finishes".

Rules, each a voice:

- **Settles or refuses.** The initializer's transitive lowered units
  may reach only rows the registry marks `Reach.Pure` (§4.4) and
  `embed`. Refusal names the chain: *"`const CFG` reaches
  `avra_io_read_text` through `load` → `read_text` — a const cannot
  read the world; `embed("cfg.toml")` reads a file the build tracks."*
- **Budgeted.** Steps and allocation, per settlement (defaults in
  §4.4, manifest-overridable). *"`const CRC` ran past 10,000,000
  steps at crc.av:12 (`fold`)"* with the lifted stack.
- **A trap is a diagnostic.** Division by zero, index out of range, a
  `fail` that escapes — each becomes an error at the const, carrying
  the lifted stack. Never a compiler crash.
- **Every read is the value.** Scalars and strings lower to `Const*`
  (already: `consts/lower.av:8`). Aggregates: §4.5.
- **A const is a declaration.** It may live in a module file and be
  exported (`export const`), retiring F0902 and F3014 for `const`
  (sugar backlog ROADMAP:7175, "module-level constants that cross
  imports"). Nothing runs at load: a settled value has no initializer.
- **Deterministic by construction.** Pure rows, no clock, no map
  walk, both engines agreeing — so a settled value is a function of
  its fingerprints and the memo is exact.

`const` and `once` are the same word at two times: `const` answers
once per build, `once fn` once per process. Both are one word.

### 3.2 `const` seats — per-instantiation settlement

```avra
fn matches(const pattern: string, s: string) -> bool {
    const prog = compile(pattern)
    run(prog, s)
}
```

- A `const` seat must be filled by a settled value at every call
  (a literal, a const, another const seat). Otherwise: *"`pattern`
  is a `const` seat — `matches` settles it at compile time, and `p`
  is computed at run time"*.
- Mono already instantiates per type (`Sub { target, args }`,
  `features/contract.av:80`, mangled `name$ids`, `lower.av:393`). A
  const seat widens `Sub` with its value's fingerprint: one unit per
  distinct pattern. Inside the unit the seat IS a const, so a `const`
  in the body folds per instantiation. That is the whole mechanism.
- Marks ride the fn type's key already (the `mut` seat law); `const`
  is the second mark. `fn(const string, string) -> bool` is a
  distinct type; a plain seat refuses a fn that demands settlement.

This is Zig's `comptime` parameter, Julia's `@generated`, C++'s
non-type template parameter — as one mark on a seat.

### 3.3 Annotations — a call with the declaration as its first seat

```avra
@traced("http")
fn handle(req: Request) -> Response { ... }
```

is, at compile time,

```avra
traced(<the declaration handle>, "http")
```

- **Resolution is `use`.** `traced` is a name in scope, imported from
  the package that exports it. No manifest list, no
  `@provider_register`, no namespacing scheme: two packages exporting
  `traced` collide exactly as two fns would, and the fix is the same.
- **The first seat says what it accepts.** `Fn`, `Type`, `Trait`,
  `Impl` (`@std/meta`, §3.6). `@traced` on a `type` is *"`traced`
  takes a `Fn` — this is `type Pt`"*. P9 at the cheapest possible
  price.
- **The answer type is the effect.**

  | answers | effect | example |
  |---|---|---|
  | `Decls` | ADD beside the declaration; it stays | `@derive(Show)` |
  | `Fn` (from `Fn`) | REPLACE the fn | `@traced`, `@cached` |
  | `Type` (from `Type`) | REPLACE the type | type operators, later |
  | `Diagnostics` | VALIDATE; empty passes | `@requires`, project lints |
  | `void` | METADATA only | `@deprecated("…")` |

  Every annotation, whatever it answers, is recorded in a side table
  (name, args, site) — that is the metadata tools and the LSP read.
  A `void` annotation is simply one that adds nothing else.
- **Stacking is composition, innermost first.** `@a @b fn f` is
  `a(b(f))`. (The spec said outer-first; Python's rule is what every
  model already knows, and composition reads right-to-left. Flagged in
  §5.)
- **Arguments are ordinary values**, settled like a const's
  initializer — with ONE scoped rule: in an annotation's argument
  list a declaration's name is its meta value, so `@derive(Show, Eq)`
  hands two `Trait`s. Everywhere else a type as a value stays F2014.
- **Errors point at the user.** A `Diagnostics` answer, or a `fail`
  inside the annotation, lands at the annotated declaration by
  default; a diagnostic built from a meta value's `span` (`f.span`
  for a field) lands there. *"`@derive(Show)` on `User`: field
  `password` is `Secret`, which has no `Show` — derive it on
  `Secret`, or skip the field: `@derive(Show { skip: [password] })`."*
  That sentence is what P1 buys.

### 3.4 `@derive` — the trait writes its own impl

The spec wants derives open, extensible, shipped by whoever ships the
trait, with no list in the compiler. The naming convention it reached
for (`derive_X`) is a string tag. The collapse:

```avra
trait Show {
    fn show(self) -> string

    fn derive(t: Type) -> Decls {
        let shown = [quote { ${f.name} + ": " + self.${f}.show() } for f in t.fields]
        quote {
            impl Show for ${t} {
                fn show(self) -> string {
                    ${t.name} + " { " + ${joined(shown, ", ")} + " }"
                }
            }
        }
    }
}
```

- A trait may declare **associated fns** (no `self`). `derive` is one.
- `@derive` is itself std code, not a compiler word:

  ```avra
  export fn derive(t: Type, traits: List<Trait>) -> Decls {
      flatten([tr.derive(t) for tr in traits])
  }
  ```

  `Trait.derive(t)` is a meta verb: the compiler runs that trait's
  associated `derive` on `t`. A trait without one: *"`Show` declares
  no `derive` — `@derive(Show)` needs `fn derive(t: Type) -> Decls`
  in `trait Show`"*.
- Config rides named arguments once sugar 5 lands
  (`@derive(Show { skip: [password] })` is a struct argument today).
- **The compiler is the first customer.** ROADMAP:6416 and :7156 name
  the rent: every `fingerprint_stmt` arm, every `_of` accessor, every
  `binds`/`value_of` body is "mechanical, derivable, erased by
  `@derive` at self-host"; SUGAR_3 wants the typed runtime-row
  namespace as "a compile-time projection once `@comptime` lands";
  ROADMAP:11664 wants `@derive(Error)` turning an enum into its error
  table. Each is a derive over an `Enum`'s variants — the same shape
  as `Show` over a `Struct`'s fields.

### 3.5 `quote` and `${}` — templates, not trees

```avra
quote { impl Show for ${t} { fn show(self) -> string { ${body} } } }
```

- **A quote is parsed where it is written.** Its body is Avra,
  parsed by the assembled grammar at the lifted fn's parse time into
  that file's own store. At run time its value is
  `(template, [hole fillings])` — nothing else crosses. Splicing
  copies the template's subtree into the target store and fills the
  holes. (Scala and Lean do this; the old tree rebuilt trees from
  constructor calls and paid two codecs.)
- **`${}` is the one hole.** A string's `${}`, a sublanguage's typed
  splice (`sql { … ${uid} }` in the embedded-languages design), and a
  quote's hole are one terminal. Inside a quoted string literal the
  `${}` belongs to the GENERATED program's string; in code position it
  belongs to the quote. A derive that wants a value in a generated
  string builds the string outside and splices it as a literal.
- **A hole is typed by its position.** A name position takes a
  `string` or a `Field`/`Variant`/`Type` (its name); a type position
  takes a `Type`; an expression position takes `Code<T>` or a settled
  scalar/string/list (lifted to a literal); an arm-list position
  takes `List<Code<Arm>>`; a declaration position takes `Decl` or
  `Decls`. Wrong shape: *"a hole in type position takes a `Type` —
  this is `Code<int>`"*, at the hole.
- **Kinds are inferred from what parses.** The body is an ordered
  choice: declarations → `Decls` (one → `Decl`); a match arm → `Code<Arm>`;
  statements whose tail is an expression → `Code<T>`; statements
  with no value → `Code<void>`. No `quote stmt`/`quote arm` words.
- **`Code<T>`'s `T` is a claim, checked at splice.** Generated code
  is re-resolved and re-typed in the target, never trusted (the spec's
  and the old tree's rule). A claim that fails blames both sites:
  the annotation and the template line.
- **Hygiene by origin, visibility by intent.** A template's own
  names resolve in the module that wrote the quote, recorded in a
  side table keyed by the spliced node (node facts live in side
  tables — this is one more). A name that ARRIVES through a hole
  resolves at the splice site. So `impl Show for ${t}` names the
  user's type, `self.${f}` the user's field, and a `let tmp` inside
  the template can never capture or be captured. Top-level
  declaration names a derive introduces (`UserRow`) are built from
  hole values and are meant to be seen — the old tree's pinned rule
  (`expand_name_survival_test.av`) becomes the natural consequence
  rather than an exception.
- **Provenance is a side table.** Every spliced node records
  (annotation site, annotation fn, template site). `avra expand`
  prints it; a diagnostic inside generated code shows both.

### 3.6 `@std/meta` — the contract

Users never import `@std/avrac`. The meta package is the curated
boundary (P9), implemented over the compiler library. Small enough to
learn in one read:

| type | holds |
|---|---|
| `Type` | `name`, `kind: Kind`, `params`, `span`, and the verbs `fields`, `variants`, `implements(tr)` |
| `Kind` | `Struct(List<Field>)`, `Enum(List<Variant>)`, `Scalar`, `List(Type)`, `Map(Type)`, `Nullable(Type)`, `Fn(…)`, `Dyn(Trait)` |
| `Field` | `name`, `ty: Type`, `mutable: bool`, `span` |
| `Variant` | `name`, `payload: List<Type>`, `span` |
| `Fn` | `name`, `params: List<Param>`, `answer: Type`, `body: Code<T>?`, `span`, `is_method` |
| `Trait` | `name`, `methods: List<Sig>`, and the verb `derive(t)` |
| `Impl` | `trait: Trait?`, `target: Type`, `methods` |
| `Decl` / `Decls` | a declaration template / a list of them |
| `Code<T>` | an expression or statement template answering `T`; `Arm` for match arms |
| `Diagnostic`, `Diagnostics` | `@std/errors`'s shape: `kind`, `span`, `message`, `help`, `suggestions` |

Verbs: `embed(path) -> string` (§3.7), `target() -> Target` (os, arch,
for conditional declarations), `fresh(hint) -> string` (a name that
collides with nothing; rarely needed under origin hygiene).

Every meta value carries a `span`, so a derive's diagnostic can point
at the user's field. Every meta type is plain data: a derive is
tested with a `spec` block and a golden of `avra expand`'s output.

### 3.7 `embed` — the build input door

`embed("defaults.toml")` answers a file's text, resolved relative to
the source file, and RECORDS the file as an input of the settlement
(a `source`-shaped input in the query kernel, hashed by content). A
missing file: *"`embed` finds no `defaults.toml` beside user.av"*.

That is the only door open by default. The root manifest may widen it
per the root-is-the-only-door design (attributed: old tree,
`fs.src.data(p"…")` with `phase = "comptime"`): a `[lifted] reads =
["schema/"]` grant. Network, process, environment, clock: never at
compile time. A build that reaches the network is a different tool.

### 3.8 What refuses, and how it speaks

Each is a registered kind with an F-code, help, and a golden. Names
are provisional; the wording is the point.

| refusal | wording (the law, not the symptom) |
|---|---|
| impure reach | "a const cannot read the world — `embed` reads a file the build tracks" (names the chain) |
| budget | "`const X` ran past N steps at file:line" |
| trap / escaped `fail` | the trap's own words, at the const or annotation, with the lifted stack |
| cycle | "settling `A` asks for `B`, which asks for `A`" (the chain, each link a site) |
| unfilled const seat | "`pattern` is a `const` seat — `matches` settles it at compile time" |
| wrong receiver | "`traced` takes a `Fn` — this is `type Pt`" |
| wrong hole shape | "a hole in type position takes a `Type` — this is `Code<int>`" |
| claim failed at splice | "`@derive(Show)` on `User` produced `self.secret.show()`, and `Secret` has no `show`" — two frames |
| meta value at run time | "a `Type` lives at compile time — splice it, or ask it something" |
| trait without derive | "`Show` declares no `derive`" |

---

## 4. The architecture

### 4.1 Evaluation is the interpreter, given arguments

`language/interp.av` runs the post-memory instruction stream with a
`Val` enum (`:16-33`) and hosts every registry row (`rt_dispatch`
`:516`, 61 arms, the registry's fifth consumer). Its one gap for
comptime is a public seat: `run_body(b, args)` (`:128`) is private and
the three exports start from zero arguments. The slice adds
`run_call(l: Lowered, symbol, args: List<Val>) -> Result<Val, Trap>`
— arguments in, an answer or a trap with its stack out — and a
`budget` on `Machine`.

The lowered program a settlement runs is `Decls.union` with the
callee as entry (`lower.av:164` drains the mono worklist from a root),
so a lifted call lowers exactly its closure, memoized per mangled
symbol as today.

The JIT (L2's plan; MCJIT in the old wrapper) is the same seam with
a faster engine and an identity marshal. It is P4's answer for a
64K-entry table; it changes nothing above this line. The interpreter
stays the semantic reference the differential gate needs.

### 4.2 Two families, demand-driven, cycle-diagnosed

The workspace has fourteen families (`workspace.av:118-133`), each
`ask → begin → compute → settle → keep`, verified by dependency
fingerprints with early cutoff (`query/db.av`). Comptime adds two:

- **`settled(DeclId) -> ConstVal`** — a const's value. Deps: the
  initializer's `typed` facts, the lowered units it reaches, every
  `embed`. Hash: the value's fingerprint, so a rebuild that computes
  the same table cuts off downstream.
- **`expanded(DeclId) -> Decls`** — an annotated declaration's
  generated declarations. Deps: the receiver's `stmt_fingerprint`
  (spans excluded, so reformatting never re-runs a derive), the
  annotation's settled arguments, the annotation fn's lowered unit,
  and every `sig` it asked.

Where they sit: `items(FileId)` (`:312`) mints DeclIds from parse.
It becomes written ∪ generated. **The namespace is two-tier:** a
lookup answers a WRITTEN name at once; a miss demands the module's
pending expansions and looks again. That is Racket's partial
expansion (heads first, bodies after), and it is what lets a derive
on `User` ask `sig(Address)` without expanding the world. A derive
that asks about a name only its own output introduces is the
`Verdict.Cycle` the kernel already answers (`db.av:24`), spoken as
the chain. The old tree's fixpoint of 16 and F4012 are this, done by
the kernel instead of by hand.

Order among slices matters here: consts add no names (S1 is a family
with no namespace change); derives do (S3 is the two-tier namespace).

### 4.3 What crosses the boundary is small

Three crossings, each one verb:

1. **Meta values in.** The compiler builds `Type`/`Fn`/`Trait` as
   `Val`s from its own tables (`Decls.sig`, `TypeRegistry`) through
   the interpreter's constructors. Hand-written, one per meta type,
   ~10 types — the last hand-written codec, and the derive that would
   erase it is the one it enables.
2. **Values out.** A settled value is spelled as a literal expression
   (int, float, bool, string, list, struct, enum, map, null — the
   value protocol's categories, `core/nodes.av:283-325`). One fold,
   which also serves `avra expand`.
3. **Code out.** A `Code`/`Decl` value is `(template id, hole
   fillings)`. The template is already in a store the compiler owns;
   splice is a subtree copy with substitution. The old tree's
   `construct_stmt`/`enum_value_to_stmt` pair (~800 lines) does not
   exist here.

Under a JIT, crossing 1 becomes identity. Crossings 2 and 3 are
already tiny.

### 4.4 Purity is a registry column; budgets are a counter

`rt_sigs()` (`core/runtime_api.av:10`, 86 rows) gains `reach: Reach`
— `Pure` (text, lists, maps, math, traps, `once`), `Embed`, `World`
(io, process, time, env). The vocabulary seam rule says data goes in
a row, and this is data: adding a row still touches no dispatch. The
old tree's deny-list of C symbol names is the string-matching shape
this refuses.

The check is static and over IR: walk the settlement's units,
`hosted_symbol` (`core/ir.av:349`) names each row, refuse the first
`World` with the call chain that reached it. A program-declared
`extern fn` is `World` (the interpreter cannot host it —
`interp.av:589` already says so).

Budgets: `Machine.budget` decremented per `step`; a memory ceiling
via the runtime's accounting. Defaults: 10M steps, 256 MiB (the old
tree's, kept until measured). `[lifted] steps = N` in the manifest.

`@total` (14.4) is the eventual static answer; the budget is the
dynamic one and stays as the belt.

### 4.5 Materializing a settled aggregate

Scalars and strings are `Const*` today. For lists, structs, enums,
maps there are two honest forms:

- **v1: the literal, under `once`.** The const's initializer is
  REPLACED by its settled literal spelling (crossing 2) and the
  declaration rides the `once` path (`lower_walk.av:102-116`,
  `avra_once_get/set`): built at first read from constants, immortal
  after. Every read is a load of a cached pointer, and nothing
  computes at run time. Visible in `avra expand` as the literal.
- **later: static data.** The backend lays the value out as an
  immortal headered object (kind STATIC, as string constants are).
  Then a read is an address. A backend slice, no change above.

`const` promises "nothing the program computes", not "no load"; v1
keeps the promise and says so.

### 4.6 Visible magic: `avra expand`, provenance, `explain`

- `avra expand <file>` prints the file as compiled: consts as their
  literal, generated declarations inlined after their annotated
  declaration, each headed `// from @derive(Show) on Pt
  (std-show/show.av:12)`. The exhaustive **source printer** for nodes
  is now `language/source_text.av`; `fmt` can consume the same
  projection. Const literal substitution and richer provenance text
  arrive with the slices that produce those values/templates.
- The provenance side table (§3.5) is what `expand` and the LSP read.
- `avra explain @traced` prints the annotation fn's signature and
  doc comment. The signature is the effect (§3.3); nothing else needs
  explaining.
- A diagnostic inside generated code carries two frames: the
  template line and the annotation site. The old tree's `[from
  @expand(m)]` blame, generalized.

### 4.7 Caching, determinism, cost

- A settlement is a pure function of fingerprints (pure rows, no
  clock, no map walk, `embed` hashed by content). The memo is exact;
  a hit is a hash compare.
- Early cutoff per consumer: a derive that regenerates identical
  code re-types nothing downstream.
- Independent settlements are independent queries; parallel
  evaluation is a kernel property, later.
- Cross-build persistence rides the L6 codegen-cache design when it
  lands; nothing here depends on it.
- The spec's mitigations for compile time (cached, parallelized,
  budgeted) are §4.2, §4.7, §4.4 respectively.

---

## 5. Divergences — from the spec, and from the old tree

Flagged so ratification is a decision, not a surprise.

1. **No `@lifted` and no `@comptime` marker on fns.** The stage is
   the CALL's (`const`, an annotation site, a `const` seat), never the
   fn's. A fn taking `Type` can only run at compile time because its
   argument exists nowhere else; a fn taking `int` runs wherever it is
   called. Marking is ceremony (P3), and Rust's `const fn` shows the
   marked subset only ever grows toward "everything". The spec's
   user-facing word "lifted" survives only as the manifest section.
2. **`@derive` lives on the trait**, as an associated `derive` fn, and
   `@derive` is std code. The spec's `derive_X(t)` convention is a
   name tag.
3. **The answer type replaces `Effect`** (30.3). The compiler still
   enforces "a metadata annotation cannot sneak codegen" — by type.
4. **Stacking is innermost-first**, not the spec's outer-first.
5. **"Pure syntactic transforms are not supported" stands, and is
   sharpened.** An annotation sees declarations as VALUES (`Fn`,
   `Type`), never token streams; a quote BUILDS code, it never
   pattern-matches it. That is what keeps derives testable and errors
   pointable.
6. **No keyword registration.** The embedded-languages design's
   non-goal (no user extension of Avra's grammar; sublanguages via
   `grammar { }`) stands; a `sql { }` block's builder is a lifted
   call, so sublanguages are a CONSUMER of this design, not a second
   mechanism. Spec 17.3's keyword registration is not built.
7. **`${}` replaces the old `~` splice**; quote kinds are inferred,
   not spelled.
8. **No `@expand` on a placeholder.** An annotation is that.
9. **Purity is a registry column**, not a deny-list of C names.

---

## 6. Slices, in order, each with its proof

### LANE HANDOFF (lane/comptime, 2026-09-11)

HEAD `bc5a7a7`, tree clean, `make gate` green. Take the lock, then
work in the order below.

DONE: **S3f** (two-tier namespace; `@traced` generates and runs),
all of **S3g** (stored doc comments appended to `avra explain @name`,
provenance, the exhaustive Expr/Stmt source printer, and full-file
`avra expand`), and S3h's `@deprecated`: a `Validates` annotation's
WARNINGS are kept on the declaration and spoken at every USE of it,
while its errors speak at the declaration. NEXT: S3h's compiler
derive is BLOCKED on the per-file generated namespace (below); then
S4/S5.

THE WARNING CHANNEL (S3h's `@deprecated`):
- A `@std.meta.Diagnostic` carries `warning: bool`; `warn(message)`
  mints one and `@std.meta.deprecated(what: Named, note)` answers it.
  A `Named` receiver (`{ name, at }`) is the metadata-only first seat
  that accepts ANY declaration — fn, record or enum.
- `Decls.marks(d)` is a QUERY, armed by the workspace
  (`arm_marks`/`marks_ensured`): it runs the declaration's
  `List<Diagnostic>` annotations on first ask, keeps their warnings
  and records them. A use reads it through `TypeCx.warn_use(e)`,
  called wherever a name is typed — `spine_type`'s `.Ident`, a
  call's node, and a struct literal's node — and speaks each warning
  AT THE USE. So a caller is warned, not the declaration, and a use
  BEFORE the declaration still warns, because asking IS the query.
- `check_annotation` therefore speaks only ERRORS at the declaration;
  a warning is the declaration's word for its users.
- A builtin or synthetic declaration has no statement record; marks
  return empty for it (`computed_marks`'s stmt guard).

THE DERIVE, RETIRED INTO S4: erasing the `_of` accessor family from
`features/contract.av` in its FREE-FN form is dropped. Generated
declarations are admitted only to `file_decls`, the two-tier name
lookup (`generated_named(f, …)`) is PER FILE, and `namespace(m)`
binds from `items(file)`, which never sees them — so a free fn
generated in one file is invisible in another, and pulling `expanded`
into `namespace` is the cycle the two-tier design exists to avoid.
The first real derive therefore lands in S4 and is IMPL-SHAPED: its
members are found through `Decls.methods`, which is already
program-wide, so no namespace widening is owed. (`DeclSig`'s accessors
can become methods — `d.fn_sig?` — if that family is the chosen
proof.) The module-namespace widening remains a LATER slice for any
derive that MUST splice a module-level declaration used cross-file,
e.g. a `Code<T>` template; it is not owed by S3h.

THE LAWS S3f/S3g pinned — a next agent must not re-derive them:
- A `Declares` annotation's arguments are LITERALS (F2067,
  "generates declarations, so its arguments come from the source
  alone"): its generated name must exist while names are still being
  resolved, so a computed arg cannot cross. Aggregates work for
  `Records`/`Validates` (they run after resolve).
- A `Declares` annotation's fn must stand in ANOTHER file (F2067,
  "generates declarations and stands in this file") — the provider
  guard; a same-file one cannot compute its own file's names.

THE MECHANICS — where the seams are:
- `Decls.mint_generated` (features/decls.av) mints the twin and admits
  it to `file_decls` AND grows `decl_ids` (a table born at file-declare
  time); it records `Provenance { ann, original, at }`.
- `Workspace.resolved(f)` MATERIALIZES expansions BEFORE the resolver
  sizes its per-expression tables, and `resolve` walks the generated
  statements after the written ones — a table sized before the arena
  grows is the class of bug that bit twice (see ROADMAP's feedback
  survey; a keeper for it is requested).
- `expanded(f)` runs during `resolved` and must not need the typed
  answers of the file it is expanding.

TESTS: `annotations/tests/traced/` (program test, eval == native ==
expected), `annotations_adversarial_test.av` (20 cases, including exact
expanded-source goldens), and `language/tests/source_text_test.av` (12
canonical/structural round trips). The loop per commit is work ->
`/red-team` -> `/review-round` -> `/feedback`; the `/feedback` skill
files findings under ROADMAP.md.

Sizes are for one lane. Each slice lands with its program tests,
goldens, F-codes, `make gate` green, and its idiom entries.

| # | slice | what lands | proof | size |
|---|---|---|---|---|
| **S1** | **`const` settles** | `run_call` seat + `Machine.budget`; `reach` column on `rt_sigs`; the static reach check; `settled` family; `settles` (`consts/check.av:29`) asks the evaluator; scalar/string materialization; `const` as an exportable declaration; F-codes for reach, budget, trap, cycle | `const CRC = crc_table(256)` folds; eval == native; a `read_text` in a const refuses with the chain; a `while true` refuses at the budget; `avra check` over `@std/avrac` unchanged | 3–4 days |
| **S2** | **`embed` + aggregates** | `embed` row with file-input deps; literal spelling of values; aggregate consts under `once` | a TOML const parsed at compile time; editing the file re-settles; a list const reads as a load | 2 days |
| **S3** | **annotations + `@std/meta` + expansion** | `@name(args)` grammar (`@` already lexes as `Pkg`, `lexer.av:374`); first-seat law; answer-type effects; meta values in (crossing 1); `expanded` family; two-tier namespace; provenance table; annotation side table; `explain @name` | `@deprecated`, a `Diagnostics` lint, and `Fn -> Fn` `@traced` written in a test package; a derive built from meta values directly (no quotes yet) erasing one `_of` accessor family in the compiler | 5–6 days |
| **S4** | **`quote` + `${}`** | the quote literal (Avra as a sublanguage of the assembled grammar); hole typing by position; template store + splice copy; origin-hygiene table; `Code<T>` claim check; quote/template provenance through the landed source printer; trait associated fns + `Trait.derive`; `@derive` in std | `@derive(Show, Eq)` on a struct and an enum, in std, tested by `spec` + `expand` golden; `fingerprint_stmt`'s arms erased by `@derive` in the compiler's own source | 5–7 days |
| **S5** | **`const` seats** | the seat mark in fn types; `Sub` widened by settled values; per-instantiation folding | `matches(const pattern, s)` compiles one unit per pattern; the regex body folds | 3 days |
| later | the `Code<T>` claim and origin hygiene (S4 refinements); static data for aggregates; JIT engine behind `run_call`; type operators (`Type -> Type`, needs aliases); typed sublanguage holes (`sql { }`); manifest read grants; parallel settlement; `@total` | | |

S1 STATUS (lane/comptime, 2026-09-09): LANDED for scalars and text.
`run_settle` (interp.av) + `Machine.budget`; `reach` column on
`rt_sigs` (24 World rows); `settlement`/`lower_const` (lower.av);
the typed `Settled` query family + kernel cycle verdict; F2060 reach, F2061
budget, F2062 trap, F2063 form. The §3.1 deviation closed: a computed
const INFERS its type through the const-type query family
(`decls.const_type`, workspace.av). Not yet: the
`const` as an exportable module declaration and the reach refusal's
full call chain (it names the row and the body).

S2 STATUS (lane/comptime, 2026-09-09): LANDED, both halves. `embed`
is `@std/meta`'s one verb over the `avra_embed` row (reach `Embed`):
the interpreter reads beside the const's source and records the file;
the `Settled` family records each one as a source-input dependency.
Natively it traps. Embed is admitted where the result crosses back
into compiler-owned data — const settlement and crossed annotation
args — and refused in lifted annotation fn bodies, which cannot
return build inputs. Outside a const it is a run-time trap (ROADMAP
trigger). Red-teamed: 27 aggregate programs and 11 embed programs,
no divergence; mutation of a const refuses as on a `let`. A const whose value rides a pointer (a list, a
map, text/list/map under `?`) is settled by the evaluator for the
laws and then CALLED by the program: its unit is `once`-shaped
(`lower_const` → `once_body`), answering the value once per process
and the same box after (`const_call`, lower_state.av). The value
crosses as one `MetaVal` tree that lowering materializes under the
const's type (values.av); a type with no compile-time value form
refuses with F2063. Static data (§4.5 later) remains. A runtime path
reaching `embed` still traps dynamically; its static effect-graph
refusal is recorded in ROADMAP because a phase bit on a memoized body
is unsound.

S3 STATUS (lane/comptime, 2026-09-09): S3a–S3c LANDED as a reviewed
checkpoint. `@name(args)` is ordinary resolved and typed syntax;
`@std.meta` supplies the nominal `Fn`, `Type`, and `Diagnostic`
boundary; validation fns run in the evaluator with ordinary values
and a `MetaHeap` for declaration metadata. The `Lifted`
query family now owns each annotation call's memoization,
fingerprint, dependency edges, and recursion verdict; the former
parallel `LiftStatus` map is gone. Program proofs cover stacked
annotations, fn/record/enum metadata, `void` and diagnostic effects,
float and nested aggregate crossing, counterfeit meta types, and
precise source locations on fn parameters, record fields and enum variants.
Still to land: declaration-producing and fn-replacing effects; the
two-tier expansion namespace and provenance; annotation facts and
`explain @name`. Quotes and derive remain S4.

NEXT SLICE — S3d THE ACTIVE LIST (opened 2026-09-10):

- [x] **S3d — construction probe (the gate).** DONE 2026-09-10 —
      docs/2026_09_10_COMPTIME_S3D_CONSTRUCTION_PROBE.md. VERDICT: a
      narrow DIRECTED API, permanent — emitter fns at the meta
      boundary answer a data-shaped `Decls`, and the compiler owns
      ONE materializer, a registry over the directive KINDS
      (`Trace`, `Projection`, `Template` — S4's quote is one more
      arm, never a second seam). No node assembly in user derives;
      the 800-line encoder/decoder MIRROR cannot recur because there
      is one direction and the registry spells every arm (I22).
      `@traced` is the Trace arm (the Wrap precedent), the `_of`
      accessors are the Projection arm (three copies of one shape),
      and `@derive(Show)` on an arbitrary struct does NOT fit — its
      body is the user's template, S4's.
- [x] **S3e — the effect doors.** LANDED with S3f: the census
      answers `Declares` for `List<Directive>`, the `Lifted` crossing
      returns directives, and `@std/meta` ships `traced`/`Directive`
      (the parked `Decl` name is retired — it collided with the
      compiler's own declaration record).
- [x] **S3f — two-tier namespace.** LANDED (lane/comptime):
      `Decls.mint_generated` mints a twin into the file's store and
      decl table under a `generated_key`; `file_decls` and `decl_ids`
      admit it, so `items`, `bodies_of` and lowering read it as
      written; `resolve` walks the generated statements after the
      written ones; `resolved(f)` materializes the expansions BEFORE
      the resolver sizes its per-expression tables — the arena must be
      complete first, or a table is born short. The resolver's miss
      (`generated_named`) is still the second LOOK. A `@traced("sum")`
      proof generates `sum_traced` and answers in both engines
      (`annotations/tests/traced`). A DECLARES annotation reaches
      LITERAL arguments only: its generated name must exist while the
      file's names are still being resolved, so a computed argument
      refuses (F2067, "generates declarations, so its arguments come
      from the source alone") rather than cycling, and its fn must
      stand in ANOTHER file (F2067) — the provider guard refuses a
      same-file annotation fn instead of silently skipping it. The
      splice PROVENANCE landed with S3g.
- [x] **S3g — visible magic.** LANDED (lane/comptime):
      `avra explain @name` (`Program.explain_annotation`) prints the
      declared fn's signature, which IS its effect — `avra explain
      @traced` answers `fn traced(Fn, string) -> List<Directive>` —
      and its stored DOC COMMENT (`f868c2f`); and PROVENANCE (S3f's
      other half): `mint_generated` records
      `Provenance { ann, original, at }` per generated declaration, and
      `avra expand <file>` now prints the whole canonical file and
      inlines each generated declaration after its annotated origin.
      `language/source_text.av` exhaustively projects Expr, Stmt and
      Pat nodes; source quoting protects interpolation openers, types
      preserve `dyn`, fn arrows and `mut` seats, and the test suite
      proves parse/print fixed points plus statement fingerprints.
- [x] **S3h — the proof.** LANDED: a `Diagnostics` lint in a test
      package, Fn→Fn `@traced`, and `@deprecated` (warning channel +
      call-site provenance; see the handoff). The compiler derive's
      free-fn form is RETIRED — it needs generated declarations to
      join the MODULE namespace (the cycle the two-tier design
      dodges), and an impl-shaped derive rides `Decls.methods`
      instead, so the proof moves into S4 with the first real
      `@derive`.
- [x] **S4 — quotes + `${}` + `@derive`.** LANDED (lane/comptime; the `Code<T>` claim and origin hygiene are refinements on the later list):
      S4a LANDED — a trait's `static fn` is an ASSOCIATED fn: no
      receiver seat, `Self` out of scope (a signature naming it
      refuses F2001), answered exactly by each impl-for and called
      through the type (`P.derive(3)`). S4b LANDED — a declaration's
      NAME in an annotation's argument list IS its meta value: typed
      as the seat, crossed by identity, so `@uses(Show)` hands a
      `Trait` and `@pair(Q)` a `Type` (and a genuinely failed argument
      still speaks). S4c LANDED — `@derive`: `@std/meta.derive(what:
      Named, tr: Trait) -> Derived` is the annotation; the compiler's
      `.Derives` effect runs the named trait's associated `derive`
      over the annotated declaration and materializes the directives
      it answers (stack `@derive` for more traits; a list seat is a
      follow-up). A trait's `derive` stands in ANOTHER file — the
      provider law — and a same-file one speaks; F2072 refuses a name
      that is not a trait and a trait that declares no `derive`. S4d
      LANDED — the
      TEMPLATE PRIMITIVE: a `Directive` may carry `code`, generated
      SOURCE; the compiler parses it INTO the annotated file's store
      (`parse_into`, no cross-store copy), admits its declarations,
      and they type and run as written. A trait's `derive` builds that
      source with ordinary interpolation today; a program test has
      `@derive(Show)` generate `fn show` on a struct. S4e LANDED — the
      `quote { … }` surface: the lexer takes the body whole (like a
      `grammar` block) and the parser makes it one string literal, so
      braces, quotes and newlines inside need no escaping. S4f LANDED —
      `${e}` HOLES: the raw scan is brace-depth aware across holes
      (a generated fn's own `{}` count, a `}` in the body's string
      literal does not), a hole in code position splices its value,
      and a `${}` inside the generated program's string literal stays
      that program's. THE CROSSING IS PARSE-ONLY (fixed with S4f): a
      `Type` receiver's fields and variants are read from the PARSE
      tree, never the signature — asking a sig re-entered the resolve
      being served. S4's acceptance is PROVEN with `Show`: the same
      derive generates an impl on a STRUCT (fields interpolated) and
      on an ENUM (one arm per variant) — `Point { x: 1, y: hi } /
      Color.Green`, eval == native == expected. NEXT: the `Code<T>`
      claim + origin hygiene. `Show` and `Eq` now SHIP in `@std/derive`
      (`packages/std-derive`); the `derive` program test stacks
      `@derive(Show)` and `@derive(Eq)` on a struct and derives `Show`
      on an enum — `Point { x: 1, y: hi } / Color.Green / true`, eval
      == native == expected.
- [x] **S1 leftovers (small).** DONE: the reach refusal's full call
      chain (`world_reached` walks the lowered bodies from the entry,
      and the label reads `reaches `row` in `leaf`, called from
      `caller`, …`), and `export const` (landed 2026-09-12).
### THE REMAINING QUEUE — one slice per bullet

S1, S3f, S3g, S3h and S4 are DONE. Each bullet below is whole enough
to start cold; the size is the design's estimate.

- [x] **S5a — the `const` seat MARK. LANDED (2026-09-12).** `fn(const
      pattern: string, s: string) -> bool`. The landing DEVIATED from
      the plan's parallel `consts: List<bool>`: a fn seat's promises
      are ONE `SeatMark { mutable, settled }` channel on `Type.Fn`,
      `Arrow`, `TypeRef` and `Param` — so a third promise is a field,
      never a third list at ~90 sites — and `TypeLit.Fn` keeps the
      grammar's two spelling lists, zipped once in `interned`.
      `intern` normalizes trailing plain marks, `mark_at` reads
      absence as plain, `fn_fits` gained the settled half of the seat
      law, `@std/meta.Param` gained `settled`, and every param list
      (fn, method, trait sig, extern, lambda, trailing block, fn type)
      takes `( "const" )?`. Proof: `fns_test.av`'s four `const` cases —
      a distinct type, a plain seat refuses a settled callee, a
      settled seat accepts a plain one, and a method demands it.

- [ ] **LATER — the shared `param` grammar rule (leave-alone).**
      S5a made every param list spell `( ck:"const" )? ( mk:"mut" )?`
      (fn, extern, once, trait sig, static fn, mut fn, lambda,
      trailing block, fn type). The LOGIC is one place
      (`marked_seats`/`seat_marks`); the grammar TEXT is not, because
      the DSL has no reusable parameter rule. TRIGGER: a THIRD seat
      mark, or a new param-taking declaration form — then extract a
      `param` rule the declaration fragments reference, its builder
      answering `List<Param>` so the window alignment dies with it.

- [x] **S5c — per-instantiation folding. LANDED (2026-09-12).** A
      `const` in a specialized body folds to its unit's settled seat
      value: `SeatValue { index, fp, ty, value }` rides `Wanted` and
      `LowerCx`, `lower_root` SEEDS each seat's register with a
      constant before the isolated settlement lowers, and the
      settlement AND the materialized const unit are keyed per unit
      (`settled_symbol`), so two calls fold to their OWN values. The
      law landed WITH it: a `const` may depend only on its fn's
      `const` seats, and `runtime_read` (a `post_order` walk of the
      initializer) refuses any other parameter with F2074. This also
      FIXED A P1 WRONG ANSWER at HEAD — a `const` reading a plain
      parameter was silently mis-settled and cached
      (`fn f(x) { const y = x + 1; y }` answered `2` for `f(10)`).
      Proof: the fold, two-unit, method, static-method and refusal
      cases, plus the `const_seat` program (eval == native ==
      expected).
- [x] **S5b — settled seats widen `Sub`. LANDED (2026-09-12).**
      `Sub` gains `consts: List<string>`, the settled seats' VALUE
      fingerprints; `mangle` appends them after `@` (`name$ids@fps`),
      which keeps every existing generic name unchanged and the name
      injective (`$`, `@` are unwritable; the backend escapes both).
      Typing computes the fingerprints where the marks are already
      read — free fns, static fns, instance methods and contract
      methods — and records them on the call's `Sub`; mono lowers ONE
      unit per distinct settled value. F2073 is the call-site law: a
      `const` seat takes a literal or a `const` (computed ones
      included); a `let`, a call result or a field read refuses.
      Proof: `pick("x")`/`pick("y")` lower two units and a repeated
      `"x"` shares one; two settled seats keep their order; the
      `const_seat` program is eval == native == expected across int,
      const, string and plain-fn-into-const-seat calls.
      BOUNDARIES, pinned by test, all S5c's: a settled seat cannot be
      FORWARDED to another (`outer(const y) { inner(y) }` refuses — the
      value is per-unit), and a direct aggregate literal
      (`take(P { x: 3 })`) wants a `const` binding. A `dyn` method's
      settled seat is enforced but not specialized (dynamic dispatch
      has no static unit).
- [x] **S5 REFINEMENTS — the two boundaries, LIFTED (2026-09-13).**
      Both now work: a settled seat FORWARDED to another fn
      (`outer(const y) { inner(y) }`), and a direct AGGREGATE literal
      at a settled seat (`take(P { x: 3 })`). THE MECHANISM, one
      channel extended: `SeatValue.value` is now the CROSSING TREE
      (`MetaVal` + `MetaHeap`) the whole compiler already moves values
      as, built by `literal_meta` (features/values.av) — a source
      value's spelling checked by the SAME test at typing and at
      lowering. `test` — `call_seats` resolves each fill: a
      source-spelled value, a `const` name (settled if computed,
      keyed `v`), or a settled seat of the ENCLOSING unit (forwarded —
      keyed by the OUTER seat's value, so the unit is per value, not
      per read site); the fingerprint carries its KIND (`e` source,
      `v` settled) so the `_` join can never swap a seat's role.
      `seed_seats` materializes with `materialized` and records the
      register in `LowerCtx.seat_regs` (a scalar is its seat's index;
      an aggregate spans several), which `read_wearing` consults. A
      TEMPLATE body cannot resolve a forwarded seat, so it falls back
      to the plain callee (its consts are already skipped); a computed
      `const` at a seat settles on the enclosing unit's seats. An
      AGGREGATE must be FULLY written — an omitted default is a body
      the evaluator runs, not source-spelled. A `dyn` method's settled
      seat stays enforced-but-unspecialized by construction. Proof:
      `fns_test`'s forwarding cases, `fns_adversarial_test`'s
      aggregate cases, and the `const_seat` program test (forwarded
      scalar, forwarded computed `const`, aggregate literal, method
      forward, forwarded-into-a-const-body) eval == native == expected.
      REMEMBER: `avra run`/`build` lower REACHED units only; `avra
      test` lowers EVERY declared body (every-mode) — a template-body
      change must be proved with `test`.
- [x] **S1 — `export const`. LANDED (2026-09-12); its "only when
      exported" scoping SUPERSEDED by THE PRIVATE CONST above
      (2026-09-13).** An EXPORTED
      top-level `const` is a DECLARATION: `DeclKind.Const` is admitted
      (only when exported), it binds in the module's value namespace
      with fns, `use util.{K}` imports it, and a cross-file read
      settles the value in the DECLARATION's own file. The design's
      premise was WRONG and is corrected here: a PLAIN module `const`
      IS F0902 today (the entry-only rule), so a module const must be
      `export const` to be a declaration — which is also why the
      scoping is `is_exported`, keeping a plain top-level const's
      file-local shadowing semantics (the const adversarial suite is
      unchanged). Proof: the `export_const` program test — int,
      string and computed consts imported and read, eval == native ==
      expected.
- [x] **THE PRIVATE CONST — a top-level `const` is a DECLARATION.
      LANDED (2026-09-13, comptime/const).** The `export const` slice
      admitted a const only when exported; now `admit` mints a
      `DeclKind.Const` for every top-level const, `is_declaration`
      answers true for one (a const never runs), the resolver's
      `bind_checked` leaves a declared statement to the namespace,
      and the three crossing laws the file-local const needed
      (`settled_binding`, the floor's const clause, the capture
      exception) are gone — a const crosses a floor because it is a
      declaration. A `let` of the same name shadows it from its line
      on, in the sequence alone (a fn body reads the const); two in
      one module clash as two fns do. A declared const fills a
      `const` SEAT from any file (`declared_seat`, settled in its own
      file on no seats); a body's own nested const keeps the
      spelled-or-settled-on-this-unit's-seats path. THE LAW THIS
      PINNED: a const's value now resolves the const's own name, so
      the TYPE cycle must speak — `Decls.const_type` answers
      `ConstType` (`Known`/`Refused`/`Cyclic`), the workspace reads
      the cycle from BOTH sides (its own memo's `.Cycle`, or the
      const's `typed` query already OPEN — `Memo.open`), and the read
      speaks F2078 once at the const; an annotated self-reference
      types without asking and traps while settling (F2062). Proof:
      `consts/tests/private_const` (a private const read from another
      file, before its line, at a `const` seat, eval == native ==
      expected), the adversarial suite's shadowing group rewritten
      DELIBERATELY, and the cycle group. The compiler sweep: 58
      module-private `export const` lost their `export`; the seed is
      refreshed. RED-TEAMED (71 programs over the eight classes, 24
      accepted ones eval == native): TWO more landed. An assignment
      to a const (`K = 2`, `K.x = 2`) reached lowering as a non-place
      and blamed the compiler (F0900) — the assignment law's `Decl`
      arm answered nothing for a const; it refuses in the const's
      words now (F3005, `consts_adversarial_test`). And a GENERATED
      top-level `const` was never admitted at all (pre-existing:
      `mint_code_stmt` minted fns, types and impls only), so a
      template could not generate one; `mint_code_const` mints it
      wearing its value's range, proven by `consts/tests/
      generated_const` (read at the top level, in a fn, at a `const`
      seat; eval == native == expected). FOUND, NOT FIXED, pre-existing
      and recorded in the ROADMAP: a template cannot name what it
      generates — its names resolve in the WRITING file, so a
      generated const reading its generated sibling (and a generated
      fn calling one) is "not defined".
- [x] **THE SEAT LAW READS THE SOURCE — survey #6's two leftovers.
      LANDED (2026-09-13, comptime/const).** A `const` seat's argument
      was judged by `literal_meta` (does the crossing tree build from
      the source alone?), which has no bindings table and reads the
      typing facts — so a const NESTED in an aggregate (`take(P { x:
      N })`) and an inline variant (`take(.B)`, typed only once the
      seat's want lands) both refused F2073. The law is a WALK now
      (`spelled_by_source`, features/checks.av): every node of the
      argument is a literal, an aggregate or variant of such, a
      `const`'s name (a body's own or a declared one), a forwarded
      settled seat, or an enum's name under a variant (`K.B`,
      `K.B(1)`); a `let`, a call, an operator, a field read — a
      const's included — is computed at run time. It reads the SOURCE
      and the bindings, never the facts, which is why the ORDER change
      survey #6 proposed (feed the seat wants before the const-seat
      check) was NOT needed. Lowering keeps the literal fast path
      (`e`-keyed) and otherwise SETTLES THE ARGUMENT as an expression
      of its unit — `SettleRoot.Expr`, the one settlement door
      widened from a const's statement to an expression, on the unit's
      seats so a nested forwarded value folds — keyed on the VALUE
      (`v`). Proof: `fns_adversarial_test`'s nine seat cases (nested
      consts, nested forwarded seat, bare/qualified/payload variants,
      and the three refusals) and the `const_seat` program (eval ==
      native == expected).
- [x] **`avra check --every` — survey #6's third leftover. LANDED
      (2026-09-13, comptime/const).** `run`/`build`/`check` lower only
      what the entry REACHES; `test` lowers every declared body, which
      is where a template body's defect surfaces. `check --every`
      (`Program.check_every`, one `check_bodies(every)` behind both
      verbs) lowers every declared body under the entry's laws, so a
      lane can probe a template body without writing a package test.
      Proof: `language/tests/check_every_test.av` — an unreached body's
      settlement trap is silent under `check` and spoken under
      `check_every`; a reached one speaks under both.
- [x] **S4r — the `Code` value and the claim. LANDED (2026-09-13),
      DECIDED as UNTYPED `Code`.** A quote answers `@std.meta.Code`:
      `{ pieces: List<Piece> }`, each `Piece { text, origin, at }` a
      run of source and the FILE that wrote it (absent for a hole's
      text). `Expr.Quote(parts, holes)` is the node (where each run
      starts is a store fact, `quote_starts_of`); typing answers the
      meta `Code` (F2076 when the program loads no `@std/meta`) and
      holds each hole to TEXT, a scalar, a NAMED meta value (`${t}`,
      `${f}` splice their names) or `Code` (F2075); lowering is three
      meta calls — `quoted` per run, `spliced` per text hole, one
      `joined` — no new instruction. `Directive.source: Code?` carries
      it; the compiler's own derives (`ValueProtocol`, `Projections`)
      write quotes too, and the `code: string?` bridge the seed ladder
      needed for one build is gone. A hole-less quote is a LITERAL (`is_literal`),
      so `@wrapped(quote { … })` crosses a user's code into an
      annotation (`quote_meta`). WHY NO `Code<T>`: under text
      templates a hole's position is unknown until the splice parses,
      so a claim on the quote could only be checked where typing the
      generated code already checks it — the claim would be a promise
      the compiler cannot test earlier than it already does. What the
      claim was FOR — blaming the template line — is paid instead by
      HOMING: every diagnostic inside generated code points into the
      quote that wrote the run (file, byte, column), a hole's text at
      the asking annotation, and a generated source that does not
      PARSE speaks the same way (`Decls.expansion_voices`, spoken by
      the file's resolve). Re-open `Code<T>` only if templates are
      ever parsed at the quote (§3.5's tree model).
- [x] **S4r — origin hygiene. LANDED (2026-09-13).** A GENERATION is
      recorded per admitted source (`Decls.generations`: the arena
      ranges its nodes took, the text's `Segment`s with their origin
      file and offset, the asking annotation's span). The resolver
      KEYS every binder and read by the origin of the node's own text
      (`keyed(name, origin)` — `name@<file>`, `@` being unwritable)
      and looks a template's module names up in the WRITING file's
      namespace (`Elsewhere.written_in`, beside the two-tier
      `generated` look); an arm's binders wear their own pattern's
      origin (`Bound`), because a generated pattern and its arm value
      can come from different runs. THE RULE FOR A NAME THAT STRADDLES
      RUNS: its origin is its FIRST BYTE's — so spell a manufactured
      binder and its read the same way (`@std/derive`'s `eq_arm`
      splices both). Proof: `quote/tests/hygiene` (a private `shout`
      found unqualified; `@wrapped(quote { tmp })` where the template
      binds `tmp` and the user's `tmp` is a fn — answers `Point! 11`,
      eval == native == expected) and `quote/tests/quote_test.av` (10
      cases: the hole law, the printer, hygiene both ways, homed
      refusals). `@std/derive` is rewritten over quotes: `${t}`,
      `${f}`, `${v}` name holes, `joined(arms, ", ")`.
      THE LAWS THIS SLICE PINNED, each found by the derive breaking:
      - A WHOLE-PROGRAM PASS MUST NOT RUN INSIDE A RESOLVE — its third
        instance. The RECEIVERS pass (`receivers()`) asks every fn's
        sig; asked from a lifted derive it signed nodes.av's decls
        from a smaller view and KEPT them (`ExprId` lost `index`,
        `Expr` lost `int_of`). It returns unsettled while any Resolved
        query is open, as `method_diagnostics` does; declared bits
        answer until the resolve closes. Cost: a body typed inside a
        lifted chain may miss an F2047 WARNING (errors read declared
        marks).
      - A NAME-KEYED TABLE CROSSES MODULES. `impls_by_name` files every
        `impl` under its NAME, so `methods(target)` signed the
        compiler's own `impl Code` while asking about
        `@std.meta.Code` — dragging `features` into the derive's
        resolve. `aims_at` keeps only impls whose FILE can name the
        target (`visible(file).types`), no resolve needed.
      - A RAW BODY'S CLOSING BRACE IS A TOKEN. `quote {`/`grammar {`
        emitted their `{` and swallowed the `}`, so the line law's
        bracket stack held a brace nothing closed and `[quote { … }
        for x in xs]` dropped the break after the line. The lexer
        emits the `}` and both grammars consume it.
      - THE PER-FILE REPORT RENDERS OVER EVERY LOADED SOURCE
        (`Program.rendered`): a homed Loc names a DEPENDENCY's file,
        and rendering it against the target's text tripped the
        span trap.
      - A FAILED TRAIT DERIVE SPEAKS: `derive_law` re-asks the memoized
        lifted call and voices its `Unsettled` — silence was how the
        derive's own refusal hid behind "no method `show`".
      RED-TEAMED (2026-09-13, 50 programs over the eight classes; eval
      == native on all 17 accepted): FOUR more, each pinned in
      `quote_adversarial_test.av`. A raw body opened INSIDE a hole
      (`"${quote { x }}"`, `quote { ${quote { y }} }`) never closed —
      its `{` was counted against the enclosing hole and its `}` never
      passed the count (`balanced`). A `}` inside a `//` comment in a
      quote or grammar body ended the body — both raw scans skip line
      comments now. A hole-less quote claimed `is_literal`, and the
      const path's literal fast-path (`settled_reg`) then read a
      register that was never minted — `is_literal` is the value
      protocol's again and the annotation gates ask `source_spelled`.
      And a generated fn the file ALREADY declares lost to the written
      one in silence (the two-tier lookup asks the written names
      first) — F2077 speaks at the asking annotation. SURVIVED: every
      wrong hole type (12) refuses with F2075; degenerate quotes (empty
      body, hole-only, adjacent holes, empty `joined`, a derive
      answering nothing) all run; 200 quotes joined twice run clean
      under `AVRA_RC_GUARD`. Poor but honest: an empty hole `${}` and
      an unclosed quote cascade into "expected `}` to close the
      trailing block" (the parser's nearest @expect).
- [x] **BEYOND — the compiler derives its own accessors. LANDED
      (2026-09-11).** `@derive(Projections)` (`features/projections.av`,
      a `std-avrac` trait) generates `impl DeclSig { fn fn_sig() ->
      FnSig? { match self { .Fn(s) -> s, _ -> null } } … }`; the three
      `*_sig_of` free fns are DELETED and every call site reads
      `d.fn_sig()` / `d.record_sig()` / `d.enum_sig()`. `std-avrac`
      gained the `@std/meta` dependency (the derive vocabulary), and
      the committed seed was refreshed (`make seed`) so a cold `make
      bootstrap` understands `.Derives`. The other `_of` families
      (`Expr`'s value protocol, `Ins`'s readers) are the SAME shape and
      now a mechanical repeat: annotate the enum, add its provider
      trait, sweep the call sites.

      THE THREE LAWS THIS SLICE PINNED, each worth a keeper:
      - AN INCOMPLETE QUERY RESULT MUST NOT BE MEMOIZED. `methods(target)`
        must return the table-so-far WITHOUT `settle` when an impl's
        file is resolving; the draft that settled it cached an EMPTY
        method set for the very type a derive was mid-minting, and
        every call site then refused.
      - A WHOLE-PROGRAM PASS MUST NOT RUN INSIDE A RESOLVE. A lifted
        call runs inside `resolved`; computing the provider's analysis
        fanned out (`method_diagnostics` over EVERY record/enum, the
        receiver pass forcing signatures) and re-entered the resolve
        being served. `method_diagnostics` returns early while any
        `Resolved` query is open (`Db.family_active`), and `methods`
        consults the same.
      - `resolved` IS A RECURSIVE QUERY. It used the acyclic `start`,
        whose cycle answer is a DEFECT (`memo family 5 reused missing
        key 79`); `start_recursive` answers a re-entry with a smaller
        view — which is exactly what the two-tier expansion always
        claimed. Found by integrating the derive: typing a generated
        method asks the receiver pass for a signature, which asks for a
        resolve.
      AND A REFUSED GENERATED SOURCE WAS SILENT until S4r (2026-09-13):
      `admit_code` dropped a parse-refused generation — that silence
      is how the `" "` vs `"\n"` method-join bug hid. It speaks now,
      homed at the template line (`Decls.expansion_voices`). Also:
      generated decls carry their OWN `[lo, hi)` range, not the whole
      block's.

### THE MECHANICAL-CLASS INVENTORY (2026-09-11)

A tree-wide sweep (functions whose body is a one-variant projection,
plus the big dispatch tables). The classes, and HONESTLY which the
`Projections` treatment reaches:

- **A. UNIFORM PAYLOAD PROJECTIONS — the clean ones.** The body is
  `match x { .V(s) -> s, _ -> null }`, so a provider DERIVES the body
  from the variant metadata; nothing is spelled twice.
  - `DeclSig` (features/contract.av): DONE (`@derive(Projections)`).
  - `Val` (language/interp.av): `array_id(.A)`, `map_id(.M)`,
    `call_ptr_val(.I)` — 3 fns, clean, would become `v.array_id()`.
  - `Expr` value protocol (core/nodes.av): DONE — `@derive(ValueProtocol)`
    in `core/protocol.av`; the six free fns are gone, call sites read
    `e.bool_of()`.
  - `Captured` over `GrammarNode` (grammar/builders.av): 8 fns,
    UNIFORM-NESTED (`match v { .Node(.NAlt(a)) -> a, _ -> null }`); a
    provider that writes `.Node(.<inner>(s)) -> s` derives them.
  - `features/builder.av` `*_at` (6): `.Node(n)` then a CAST — NOT a
    plain payload; needs the provider to spell the cast.
- **B. THE `Expr` VALUE PROTOCOL (core/nodes.av): 6 fns.** 5 are the
  clean shape (`bool_of`, `int_of`, `bits_of`, `text_of`, `elems_of`);
  `pairs_of` builds a `MapPairs` from TWO payloads, so it needs a
  RECORD-PROJECTION arm (or stays hand-written). ~37 call sites.
  `is_literal` composes four of them.
- **C. `NodeStore` STMT PROJECTIONS (core/parts.av): 14 fns**
  (`fn_parts` 24 uses, `const_value` 9, `impl_parts` 8, …). They are
  STORE METHODS (project a `StmtId`), so the derive — which emits an
  `impl` on the ENUM — does not fit as-is; the treatment would move
  them to `Stmt` methods (`store.stmt(s).fn_parts()`), a 14 × ~5-site
  sweep. They also build `TParts` records by FIELD, so several need
  the record-projection arm.
- **D. EXHAUSTIVE DISPATCH — DO NOT DERIVE.** `fingerprint_stmt` (23),
  `dst_of` (21), `reads_of` (23), `hosted_symbol` (12),
  `fingerprint_expr` (~40), `pat_fingerprint` (3), `emit_ins`,
  `interp.step`, `memory_ins`, `body_lines`, `give`. Their VALUE is
  that every variant is spelled; a derive would defeat the vocabulary
  guarantee (CLAUDE.md's IR growth protocol). Some ARMS could delegate
  to derived per-variant helpers, but the dispatch stays.
- **E. PER-VARIANT COMPUTATION — S4's job, not A's.**
  `fingerprint_expr`'s arms are `fp(tag, [child fps])` with per-arm
  variation (a list vs a string vs a conditional tag), and multi-
  payload variants need BINDER NAMES (the meta `Variant` carries only
  payload TYPE spellings today). Erasing these is `@derive` with
  quotes/templates + binder names in `@std/meta.Variant` — the S4
  slice, not `Projections`.
- **F. ENUM→WORD MAPS — exhaustive by design.** `op_symbol`,
  `un_symbol`, `kind_word`, `answer_word`, `mark_word`, `length_word`
  (`TypeRegistry` methods), `count_word`, `seat_word`.

AND THE VOCABULARY-NAME COLLISION, SOLVED DRY: the provider must
name its seat types `@std.meta.Type`/`Variant`, and `core` already has
both (F3018). The fix is NOT a second vocabulary (option (b) would
maintain two) but **IMPORT ALIASES** — `use @std.meta.{Type as
MetaType, Variant as MetaVariant}`: one declaration, renamed at the
import site. LANDED, with `Decls.meta_type`/`is_declares` reading the
DECLARATION's name rather than the written spelling. Option (b) is
REFUSED as not DRY. This unblocked `Expr`'s value protocol, which is
now `@derive(ValueProtocol)` in `core` (5 accessors + `pairs_of`).

THE SEQUENCE the inventory implies:
1. `Val`'s 3 accessors and `Captured`'s 8 (A) — the same
   `Projections` treatment; the `Captured` provider emits a nested
   pattern, proving the provider can write any body shape. (BLOCKED
   on the collision where the module imports `Type`/`Variant`.)
2. The `Expr` value protocol (B) once `pairs_of` has a
   record-projection arm, or split (5 derived, 1 kept).
3. The `Stmt` projections (C) as a separate, larger sweep.
4. `fingerprint_*` (D/E) stays until S4's quotes + `Variant.payload`
   binder names.

- [ ] **Later list, unstarted.** Static aggregate data (§4.5); a JIT
      engine behind `run_call`; type operators (`Type -> Type`, needs
      aliases); typed sublanguage holes (`sql { }`); manifest read
      grants; parallel settlement; `@total`.
- RECORDED TRIGGER (S3e): **PAID by S3f** — the `Declares` effect is
  back in the census, `@std/meta`'s `Directive`/`traced` are consumed
  by `expanded`, and the twin's name is spellable (`sum_traced`). The
  next trigger: an aggregate `Declares` argument, which waits on the
  quote phase (S4) — today it refuses with F2067, because a computed
  argument needs typed answers that do not exist until the name it
  makes is known.

Order rationale: S1 is what the owner already queued (ROADMAP:8218,
"NEXT: comptime (`const`, evaluated at compile time)") and proves the
engine seam with no namespace change. S3 before S4 because the
compiler's own first derives (variant-keyed accessor tables) need
meta values, not templates, and landing the expansion family without
quotes keeps the two hard problems apart.

---

## 7. Open questions (five)

1. **Spelling a type as a value in user code.** Inside the compiler
   it is `v.type(T)` (sugar 2). In an annotation's argument list a
   bare name is its meta value (§3.3). Is a bare `type(User)`
   elsewhere wanted, or is the annotation position enough?
2. **`Code<T>` vs untyped `Code`.** DECIDED 2026-09-13: untyped
   `Code`. A text template's hole has no position until the splice
   parses, so the claim could only be checked where typing the
   generated code checks it already; the two-frame error is paid by
   HOMING instead (S4r in §6). Re-open only with a tree-template
   model.
3. **Arms as a quote kind.** `quote { .A(x) -> f(x) }` is what the
   compiler's own enum derives write; it is neither statement nor
   expression. Ordered choice in the quote body (arm first) is the
   proposal.
4. **Budget defaults.** 10M steps / 256 MiB are inherited numbers.
   Measure the compiler's own derives under S4 and set them from that.
5. **Where diagnostics kinds for user annotations register.** Every
   diagnostic names a registered kind; a package's annotation needs a
   package-namespaced kind (`@myorg/audited: E1`). The registry is
   per-feature today (`code_registry`, `language/mod.av:113`).
