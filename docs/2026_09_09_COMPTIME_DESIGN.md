# Comptime — `const`, annotations, quotes

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
  (std-show/show.av:12)`. It needs a **source printer** for nodes —
  the tree has a DSL renderer (`grammar/render.av`) and an IR printer
  (`ir_text.av`), not this. The printer is its own slice and `fmt`
  wants it too.
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

Sizes are for one lane. Each slice lands with its program tests,
goldens, F-codes, `make gate` green, and its idiom entries.

| # | slice | what lands | proof | size |
|---|---|---|---|---|
| **S1** | **`const` settles** | `run_call` seat + `Machine.budget`; `reach` column on `rt_sigs`; the static reach check; `settled` family; `settles` (`consts/check.av:29`) asks the evaluator; scalar/string materialization; `const` as an exportable declaration; F-codes for reach, budget, trap, cycle | `const CRC = crc_table(256)` folds; eval == native; a `read_text` in a const refuses with the chain; a `while true` refuses at the budget; `avra check` over `@std/avrac` unchanged | 3–4 days |
| **S2** | **`embed` + aggregates** | `embed` row with file-input deps; literal spelling of values; aggregate consts under `once` | a TOML const parsed at compile time; editing the file re-settles; a list const reads as a load | 2 days |
| **S3** | **annotations + `@std/meta` + expansion** | `@name(args)` grammar (`@` already lexes as `Pkg`, `lexer.av:374`); first-seat law; answer-type effects; meta values in (crossing 1); `expanded` family; two-tier namespace; provenance table; annotation side table; `explain @name` | `@deprecated`, a `Diagnostics` lint, and `Fn -> Fn` `@traced` written in a test package; a derive built from meta values directly (no quotes yet) erasing one `_of` accessor family in the compiler | 5–6 days |
| **S4** | **`quote` + `${}`** | the quote literal (Avra as a sublanguage of the assembled grammar); hole typing by position; template store + splice copy; origin-hygiene table; `Code<T>` claim check; `avra expand` + the source printer; trait associated fns + `Trait.derive`; `@derive` in std | `@derive(Show, Eq)` on a struct and an enum, in std, tested by `spec` + `expand` golden; `fingerprint_stmt`'s arms erased by `@derive` in the compiler's own source | 5–7 days |
| **S5** | **`const` seats** | the seat mark in fn types; `Sub` widened by settled values; per-instantiation folding | `matches(const pattern, s)` compiles one unit per pattern; the regex body folds | 3 days |
| later | static data for aggregates; JIT engine behind `run_call`; type operators (`Type -> Type`, needs aliases); typed sublanguage holes (`sql { }`); manifest read grants; parallel settlement; `@total` | | |

S1 STATUS (lane/comptime, 2026-09-09): LANDED for scalars and text.
`run_settle` (interp.av) + `Machine.budget`; `reach` column on
`rt_sigs` (24 World rows); `settlement`/`lower_const` (lower.av);
`Workspace.settled` memo + self-cycle guard; F2060 reach, F2061
budget, F2062 trap, F2063 declares. ONE DEVIATION FROM §3.1: a
computed const DECLARES its scalar type (`const F: int = fact(5)`),
because a const's type is read from the store alone (contexts.av
`settled_type`); inference is a sugar-backlog entry. Not yet: the
`settled` FAMILY (the memo is a workspace map, per build), aggregate
values (S2), `const` as an exportable module declaration, the reach
refusal's full call chain (it names the row and the body), and the
refusal pointing at the declaration (it points at the first use).

S2 STATUS (lane/comptime, 2026-09-09): LANDED, both halves. `embed`
is `@std/meta`'s one verb over the `avra_embed` row (reach `Embed`):
the interpreter reads beside the const's source and records the file
(`Settled.embeds`, unused until the family), natively it traps. It is
allowed only where the value is SPELLED (a text const): a boxed const
is built at run time, where no source sits beside the program, and
the refusal says so. Outside a const it is a run-time trap (ROADMAP
trigger). Red-teamed: 27 aggregate programs and 11 embed programs,
no divergence; mutation of a const refuses as on a `let`. A const whose value rides a pointer (a list, a
map, text/list/map under `?`) is settled by the evaluator for the
laws and then CALLED by the program: its unit is `once`-shaped
(`lower_const` → `once_body`), answering the value once per process
and the same box after (`const_call`, lower_state.av). The type is
still read from the store, so it is spelled in WORDS (`spelled_type`,
contexts.av: scalars, `List<…>`, `Map<string, …>`, `?` over a
pointer-riding one); a declared type's NAME and `?` over a scalar
refuse with F2064. Static data (§4.5 later) and `embed` remain.

S3 STATUS (lane/comptime, 2026-09-09): S3a and S3b LANDED as a
reviewed checkpoint. `@name(args)` is stored on the declaration and
composes innermost-first. Its callee and arguments use ordinary
resolution and typing. The first seat accepts the nominal
`@std.meta.Fn` or `@std.meta.Type`; the answer is `void` or
`List<@std.meta.Diagnostic>`. The same lowered evaluator runs the
call under the const purity and step laws. `Fn`, record, enum and
source-location metadata cross by field name through `MetaHeap`;
scalar arguments include int, float, bool and text. A per-call state
breaks the lowering/type recursion and memoizes the answer. The
program proof in `features/annotations/tests/comptime_annotations`
exercises metadata, validation and void annotations through the real
`@std/meta` package. Still S3c: make this state a query family; cross
aggregate arguments; implement `Decls`, `Fn -> Fn`, the two-tier
namespace and provenance; expose annotation facts and `explain`.

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
2. **`Code<T>` vs untyped `Code`.** The claim is checked only at
   splice. Keep `T` for intent and the two-frame error, or drop it
   until stage typing is worth its cost?
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
