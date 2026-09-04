# Avra

A clean-room compiler for the Avra language, built slowly, one
reviewed file at a time. The language is assembled from
`LanguageFeature` components — each feature declares its syntax in a
grammar fragment and owns its semantics in every pass; the compiler
derives the rest. The spec's Part 0 principles frame every decision;
above all P6: when a trade-off feels forced, the model is wrong, not
the requirements.

## Today

A program parses through the feature-merged grammar, resolves,
type-checks, lowers to a scoped IR, and takes its memory plan from a
per-scope strategy pass. From there, ONE meaning runs on two
engines: the IR interpreter (`avra run`) and the LLVM backend
(`avra build`) consume the identical instruction stream, so the
native binary answers byte-for-byte what the interpreter says —
divergence has nowhere to live:

```
fn fib(n: int) -> int { if n < 2 { n } else { fib(n - 1) + fib(n - 2) } }
fib(10)
```

The language so far: `let` and `mut` with assignment, `fn` with
calls and recursion, `if c { a } else { b }` as an expression,
subjectless `when`, `while`, range `for` and `for x in xs`, blocks
that answer, ints, bools, strings with `${}` interpolation, lists,
records (`type P = { x: int }`, literals and `with`), enums with a
total `match` and pattern binds, nullability (`T?`, `null`, `??`,
`!`, `?.`, `if let`, let-else) where every other type is a
guarantee, the full error spine (`Result<T, E>`, `fail`, auto-Ok,
`?` propagation, `catch` at four granularities), generics with
monomorphization (`fn id<T>`, `type Box<T>`, `List<T>` for real),
methods and traits with static dispatch (`impl P`, `trait Show`,
`impl Show for P`, bounds `fn f<T: Show>`), `dyn Show` when
heterogeneity is worth its visible cost, ownership (every box
reclaims; strings ride struct fields, enum payloads, list
elements, and `Result<T, string>` — the self-host shape),
closures (`(x: int) -> x + n` capturing by value, fn-typed fields
making capability records first-class), maps (`Map<string, T>`,
insertion-ordered, `.get`/`.set`), typed table literals
(`table<Row> { … }`), components and record field defaults
(`type P = { y: int = 2 }` — a default is a declaration every
literal that omits the field calls), index-paired `for i, x in xs`,
and modules (`use a.b.{f}`, `export`, an `avra.toml` marking the
package root, and `avra check <dir>` checking every file under it)
— every construct golden-tested from its parse tree to its
diagnostics to its native output, on both engines.

## Debugging ownership

`AVRA_RC_GUARD=1 <program>` turns the runtime's reference counting
into a tracer: a box that reaches zero is POISONED and kept, the
second release of it aborts, and the report prints that box's whole
retain/release history with each caller's address. Symbolize those
with `lldb -b -o "image lookup -a <addr>" <binary>`. It found half
the self-hosting bugs; off, it costs one `getenv` per program.

## The compiler, in pipeline order

```
source(s)
  │  workspace     a package root's files; every stage below is a
  │                memoized query family over the red-green kernel
  │                (`query/`), so a body edit re-runs only what read it
  │  lex + parse   the grammar engine, executing the merged
  │                feature grammar; holes survive bad input
  │  resolve       names -> bindings (a param or a definition)
  │  type-check    expressions -> types, fns -> signatures
  │  lower         a scoped IR: regions as brackets, born SSA —
  │                lowering IS the one semantics
  │  memory        the strategy pass: retains and releases,
  │                decided per scope by its LEVEL
  ├─ interp        the IR interpreter — `avra run`
  └─ llvm + cc     one LLVM fn per body, verifier-gated, linked
                   against our runtime — `avra build`
```

The compiler answers to its own name:

```sh
./avra run corpus/fns.av      # the interpreter says BIG!
./avra build corpus/fns.av    # a native binary that agrees
./avra ir corpus/branch.av    # the memory-annotated IR
./avra grammar                # the assembled language
./avra explain F2000          # any diagnostic code
```

Every layer is inspectable (P7) — the grammar, the IR, the LLVM
module (`emit`), the diagnostics registry.

## The gates

```sh
make gate     # the bar for every change: vocab + idioms + test + corpus
make vocab    # the IR seam: every Ins consumer stays exhaustive
make idioms   # the ratchet: mechanical smells may never RISE
make test     # every module's spec/given/then suite
make corpus   # every corpus/*.av: eval == native == .expected
make bench    # the measured curve: suite + corpus wall times
make fuzz     # corpus mutants through `avra check`: diagnose, never crash
make scaffold-check   # `avra new feature` templates still compile
```

`corpus/` is the language's proof by example: each program is a few
lines, states what it proves, and is held to its expected output
through both the evaluator and the compiled binary, forever.

## Growing the language

```sh
avra new feature <name>   # scaffolds the feature directory
```

A feature is a directory: its grammar fragment, its builders, and
one rule per pass. Wiring it into the language is three one-line
edits (the scaffolder prints them); proving it is a corpus pair.
The ROADMAP's growth ledger holds the doctrine — and the falsifiable
claim that this stays true.

## Layout

```
packages/std-avrac/src/
  core/        shared vocabulary: spans, nodes, types, the IR
  query/       the memo kernel: red-green cells, families, revisions
  grammar/     the grammar engine (language-agnostic)
  features/    the language, one directory per feature; the contract
  language/    the driver: assembly, the workspace's query families,
               passes, interp, backend
  diagnostics/ structured errors and their rendering
  testing/     what every spec asks of a program: shown, refused_with
packages/cli/  the avra command; each subcommand one file
runtime/       avra_runtime.c — the native half of the semantics
backend/       llvm_wrapper.c — the compiler's LLVM binding
corpus/        the proof-by-example suite
tools/         the gate's scripts: the idiom ratchet, bench, fuzz
```

Layering is one-way: core → query → grammar → features → language.
`query/` and `diagnostics/` are infrastructure — language-agnostic,
imported by everything above them.

## Toolchain

Built and tested with the bootstrap compiler `bs2`
(`../forge-crafting-intepreters/bootstrap/build/bs2`) until Avra can
express its own compiler — the self-host endgame recorded in
ROADMAP.md. Design sources of truth live in the same tree:
`docs/2026_04_18_FULL_SPEC.md` (the language),
`docs/2026_06_14_AST_SOURCE_OF_TRUTH_EPIC.md` (the node model),
`bootstrap/docs/2026_08_19_STANDARDIZATION.md` (front-end shape).

bs2 fixes parts of the layout: package entries resolve at
`packages/<scope>-<name>/src/<name>.av`, the test runner loads
vendored `spec_test/` and `std-cli/` (see their VENDORED notes), and
build byproducts (`*.avra-sha256`, `*.av.ll`, `build/`) are cleaned
by `make clean`.
