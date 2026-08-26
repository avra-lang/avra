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
type-checks, runs on the reference evaluator, lowers to a scoped IR,
takes its memory plan from a per-scope strategy pass, and compiles
through LLVM into a native binary that answers byte-for-byte what
the evaluator says:

```
fn fib(n: int) -> int { if n < 2 { n } else { fib(n - 1) + fib(n - 2) } }
fib(10)
```

The language so far: `let`, `fn` with calls and recursion,
`if c { a } else { b }` as an expression, ints, strings, bools,
`+ - == <`, comments — every construct golden-tested from its parse
tree to its diagnostics to its native output.

## The compiler, in pipeline order

```
source
  │  lex + parse        the grammar engine, executing the merged
  │                     feature grammar; holes survive bad input
  │  resolve            names -> definition sites; two namespaces
  │  type-check         expressions -> types, fns -> signatures
  ├─ eval               the reference semantics — `avra run`
  │  lower              a scoped IR: regions as brackets, born SSA
  │  memory             the strategy pass: retains and releases,
  │                     decided per scope by its LEVEL
  │  llvm               one LLVM fn per body, verifier-gated
  └─ clang + runtime.o  a native binary — `avra build`
```

The compiler answers to its own name:

```sh
./avra run corpus/fns.av      # the evaluator says BIG!
./avra build corpus/fns.av    # a native binary that agrees
./avra ir corpus/branch.av    # the memory-annotated IR
./avra grammar                # the assembled language
./avra explain F2000          # any diagnostic code
```

Every layer is inspectable (P7) — the grammar, the IR, the LLVM
module (`emit`), the diagnostics registry.

## The gates

```sh
make test     # every module's spec/given/then suite
make corpus   # every corpus/*.av: eval == native == .expected
make gate     # both — the bar for every change
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
  grammar/     the grammar engine (language-agnostic)
  features/    the language, one directory per feature
  language/    the driver: assembly, passes, backend
  diagnostics/ structured errors and their rendering
packages/cli/  the avra command; each subcommand one file
corpus/        the proof-by-example suite
```

Layering is one-way: core → grammar → features → language.

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
