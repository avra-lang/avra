# Roadmap

## The eras (the long path, each with its gate)

- ERA I — THE VERTICAL (done): one thin language, source to native,
  eval == native == expected held by gates, features as components,
  the workflow that keeps growth cheap.
- ERA II — EXPRESSIVE SUFFICIENCY (now): the language grows until
  it can express its own compiler. Not "all features" — a measured
  ladder derived from the vocabulary the compiler's own source
  actually uses. GATE: the fraction of the compiler's own source
  that parses, checks, and runs under `avra` — tracked, and only
  ever rising.

  The ladder (~15 rungs; five are heavyweights, marked ▲):
    1.  [x] `when` — the ledger trial, multi-way on existing regions
    2.  [x] blocks — statement scopes, multi-line bodies (`return`
        deferred to rung 3, recorded)
    3.  mutation & loops — `mut`, assignment, `while`/`for`, ranges
    4.  operators complete — `&& || !`, `!= > >= <=`, `* / %`
    5.  lists — the first aggregate; iteration; the method core
    6.  strings complete — `${}` interpolation, the method core
    7.  structs — declarations, literals, `with`, impl methods
        (and the spec's `shape`/width subtyping belongs to this
        rung — the cx family in contract.av is already waiting)
    8.  ▲ enums & match — payloads, patterns, exhaustiveness
    9.  nullability — `T?`, `null` arms, `! ?? ?.`
    10. Result & `?` — propagation as the error spine
    11. ▲ generics — mono through OUR pipeline (List<T> becomes real)
    12. ▲ traits & dyn — dispatch, cross-module impls
    13. ▲ closures & fn values — capture meets the memory ABI
    14. maps, components & tables — the self-describing surface
    15. ▲ modules & multi-file — packages, the graph, exports
  Plus the floor under it all: extern/ptr FFI (the backend already
  dogfoods it) and the core stdlib + the spec/given/then test
  feature, which ride the rungs they need. Lightweight rungs are
  `when`-sized; heavyweights are M7-sized capability milestones —
  the drivers learn machinery (patterns, mono, vtables, capture),
  paid once each.
- ERA III — SELF-HOST: module-by-module parity (avra compiles its
  own lexer, then the engine, then the passes), then the fixed
  point — avra1 compiles the compiler into avra2, and avra2 is
  byte-identical to avra1. bs2 retires; runtime.c and the LLVM
  wrapper come in-tree. GATE: the fixed point, plus the full gate
  green under the self-hosted binary.
- ERA IV — THE ENGINE: the speed doctrine made real, designed
  around the language's own facilities — per-declaration red-green
  incrementality, the content-addressed cache in ONE root,
  `avra test` as one process with JIT execution, parallelism via
  the language's own spawn/channels. Tooling as projections of the
  compiler's fact tables (P10/P12): `avra lsp`, `avra fmt` (format
  IS re-render — the AST is the source of truth), `avra doc` from
  feature docs. GATE: rebuild-after-one-edit and suite wall time,
  measured and budgeted.
- ERA V — THE SUBSTRATE: what the language is FOR (P2, P13, P14).
  The levels beyond Application become real strategies (Systems
  ownership first); concurrency lands as language (Axis 18); the
  error epic's typed effects and policies; boundaries as contracts
  (P9); services that carry their ops with them. GATE: a real
  autonomous service, written in Avra, deployed from `avra` alone.

Eras overlap at their edges — parity gates start mid-Era II, the
cache design lands with self-host — but the GATES are strict: an
era is entered by measurement, never by declaration.

The strategy: a THIN VERTICAL SLICE first — two statement kinds driven
through every pass to a world-class error — then features widen, each
vertically complete. This is the AST epic's own L0-tracer doctrine at
real scale; the design sources of truth live in
`../forge-crafting-intepreters/docs/` (see CLAUDE.md).

## Milestone 1 — the front end

- [x] Grammar engine: anchor-commit alternation, farthest-failure
      expected-sets, `@expect`/`@recover`, self-hosted DSL fixed point
- [x] Authoring surface: `LanguageFeature` component, `Builder`
      context, engine-attributed spans, compose-time coherence
- [x] Statement layer: same-name rule merging, `stmt_spine`,
      `let_stmt` (recovery), `expr_stmt`
- [x] `language/` driver seam: `assemble` + `parse_program`; recovery
      holes are explicit `Stmt.Error` nodes
- [x] Harness retirement: feature tests parse through the driver;
      private test plumbing deleted

## Milestone 2 — a world-class error, end to end

- [x] @std.errors — the base error model (describe-only trait, Loc,
      Frame, graded Suggestion); compiler diagnostics implement it
- [x] Diagnostics currency: Diag over the base, kind as identity,
      F-codes as the registry's projection, the kind|id|summary table
      registered per feature and duplicate-gated at assembly
- [x] Rendering: per-file line index (byte spans -> line/col only at
      render), the miette-shaped renderer, golden rendering tests
- [x] Driver projection: engine diagnostics -> Diag, with the
      unregistered-kind validation net
- [x] `avra check` CLI over the driver (`make check FILE=...`; a
      compiled standalone binary is later polish)
- [x] Resolve pass — the first pure query: definition-site symbols,
      facts in a pass-owned dense table (O(1) by ExprId), sequential
      visibility with shadowing, use-before-def as its own kind,
      graded nearest-candidate suggestions
- [x] Type pass: opaque `TypeId` + interning registry
      (content-addressing drops in later behind `intern`), the
      totality invariant structural — a dense `List<TypeId>`, no
      option and no Unknown; Error is interned, absorbing, and never
      cascades a second diagnostic
- [x] The consumer seam: one self-sufficient `Analysis` per source
      (every pass's facts + codes + ONE diagnostics list, answering
      `report`/`clean`/`type_name`/`target` itself), the standard
      pass signature `pass(p, ...upstream Facts) -> Facts`,
      `SourceFile` as THE input value, `avra()` as the language
- [x] GATE: `avra check` on `let x = 1 + y` prints a beautiful
      resolve error — golden-tested character-exact

## Milestone 3 — widen, vertically complete

- [x] GATE before widening: the FIRST/FIRST coherence check — shared
      first tokens, buried keywords (general terminal before the
      literal it subsumes), empty-matching non-last branches, and
      left recursion all refuse at assembly; the keyword ANCHOR
      (literal first) is the one sanctioned overlap
- [x] Comments: `//` to end of line is whitespace in BOTH lexers
      (one shared scanner, no mode); a comment-only line is a blank
      line; doc comments are a later, node-attached feature
- [x] The widening doctrine, proven: string literals landed as one
      feature directory whose `primary` branch MERGES under the
      dead-branch gate, with the second type and typing's first real
      diagnostic (`type.mismatch` F2000, operand-pointing golden).
      Every next feature follows this shape: grammar + builders +
      check rules together

## Milestone 3.5 — programs compute truth

- [x] Booleans + comparisons, vertically: `bool_lit` keyword-anchors
      `true`/`false` ahead of NAME (the gate's sanctioned shape);
      the comparison stratum lives in the spine (`==`/`<`, one
      comparison, never a chain); `==` demands MATCHING operands and
      says both sides; `<` answers bool over ints; eval compares
      value nodes by payload. Lexer grows `==` (munched before `=`)
      and `<`.

## Milestone 4 — the tracer runs

Eval-vs-LLVM is a false dichotomy (P6): the spec requires a
compile-time evaluator anyway (`@comptime`, seed validation), so the
evaluator IS the tracer back end — a permanent organ, never
throwaway.

- [x] The evaluator: a pure walk of the TYPED AST — no dynamic
      checks past the refusal gate; idents read their definition's
      SLOT (dense by StmtId — resolution is the runtime environment)
- [x] `avra run FILE` — analyze, refuse with the report on any
      diagnostic, evaluate, print the last statement's value
- [x] GATE: `make run` executes a real program (comments, lets,
      shadowing, arithmetic) and prints its value; a broken program
      refuses with the full rendered report

## Milestone 4.5 — features own their semantics

- [x] `NodeSemantics` — one trait per the whole vertical (kids,
      resolve, type_of, eval, printed), implemented per feature
      (semantics.av dispatches; check.av/eval.av hold the rules).
      Passes are DRIVERS: they own state, order, and refusal;
      `semantics_of` — the ONE exhaustive map, the compile-time
      anchor — returns a node's semantics directly, no strings, no
      lookup. A new node costs: the feature dir, the list line, the
      enum variant, a fingerprint arm, one map arm — and the trait
      impl forces every pass at compile time.
- [x] Upstream findings while landing it: dyn trait-kind loss across
      the metadata boundary (FIXED in bs2 — registry recovery at the
      method fallback); config lists do not auto-box dyn (typed-let
      boxing, noted); no generic-enum returns through dyn vtables
      (capability-fn design instead, noted)

## Recorded triggers (standardize WHEN, not before)

- Statement semantics join NodeSemantics when the FIRST new statement
  feature lands (`fn` declarations) — today the stmt spine is three
  stable kinds dispatched once, in `stmt_value`.
- [x] LANDED — the fourth pass (lower) proved the shape: `post_order`
  is THE walk (children before owners), every pass driver iterates
  it, and the per-pass recursions are gone. Per-node visitors are
  FREE FNS by doctrine (#1377).
- Passes become a uniform trait only when the L6 query engine is the
  consumer that memoizes them — typed signatures are the data-flow
  contract until then.

## Milestone 5 — Avra compiles (the design, agreed)

The goal is REPLACING bs2, so the backend is built for the scoped
abstraction levels (docs/idea_scoped_abstraction_levels.md), not just
the tracer:

- [x] `core/ir.av` — flat typed register IR with SCOPES as
      first-class structure (`ScopeEnter(level)`/`ScopeExit`,
      bindings per scope); every level of the abstraction-levels doc
      is an enum value from day one, today always Application. The
      language is already SSA (single-bind lets): a definition's reg
      IS its slot through resolution.
- [x] Lowering — pass four, standard shape; NodeSemantics grows
      `lower` (compile-enforced per feature). Lowering emits PURE
      semantics: no memory ops, ever.
- [x] Memory — pass five: strategy dispatched PER SCOPE by level.
      Application = RC (bs2 parity: releases at scope exit, correct
      even on statics — the runtime no-ops non-RC pointers); Systems
      ownership drops in later as a strategy, touching neither
      lowering nor the backend.
- [x] Backend — LLVM C API through the ALREADY-LINKED
      `llvm_wrapper.o` externs (verifier in the loop per function,
      per the epic's ORC/comptime future); programs link `runtime.c`
      — Avra's runtime library, rewritten in Avra-at-bare at the
      self-host endgame. `avra emit` prints the module (P7,
      LLVMPrintModule — a projection, never the compile path);
      `avra build` produces the object and clang-links.
- [x] GATE: `make native-check` — the compiled binary's output is
      byte-identical to the evaluator's across the corpus
      (arithmetic, strings, comparisons, runtime string equality).

## Milestone 5.5 — the vision audit (2026-08-25)

The current tree audited against the spec's ten v1.0 architectural
commitments (Axis 9) and the compiler-architecture decisions
(Axis 26). Verdict: aligned. What the audit closed or decided:

- [x] Reserved words (commitment #10): `systems` `bare` `hardware`
      `owned` `borrow` `move` `level` `unsafe` `extern` `async`
      `spawn` `await` `channel` `select` refuse as names —
      `resolve.reserved` F3002, golden-tested. Near-term keywords
      (`fn`, `if`, `match`, ...) become anchored literals when their
      features land; this list is the far-future set the spec locks.
- DECIDED — control flow lands as STRUCTURED IR (nested regions),
  never a flat CFG: the memory pass's model is "what does this
  SCOPE owe at exit," so scope structure stays visible from
  lowering through memory; blocks and phis exist only at LLVM
  emission. If the memory pass ever re-derives scopes, the fork was
  taken wrong.
- DECIDED — calls carry their contract from day one (commitments
  #6+#7): when `fn` lands, the app-level ABI is CALLEE-CLEANS (the
  callee owns its arguments; their release is the callee's scope
  exit — passing a value whose last use is the call costs zero RC
  traffic), and every Call/Ret carries (caller level, callee level)
  even while both are always Application. Systems-level boundary
  machinery — borrow injected inward, refcount-init outward —
  attaches to instructions that already exist. Callee-cleans is the
  SAME convention as a Rust/systems-level move (ownership rides in
  with the argument; the callee's scope exit cleans) — ONE ABI at
  every level, only the cleanup op differs by strategy; and it is
  the Perceus shape: last-use arguments transfer with ZERO RC
  traffic, and refcount-1 knowledge enables in-place reuse.
- TRIGGER — the first composite type: the memory pass stops
  shape-matching managed values (`managed_dst`) and consumes
  per-type generated TRAVERSALS (commitment #1: which fields need
  retain/release, invariant across strategies); layouts stay
  strategy-independent with RC headers EXTERNAL to the object
  (commitments #2-#3).
- DEBT — backend: in-process object emission through the wrapper
  (TargetMachine) replaces `.ll` text + clang's re-parse; `emit_ll`
  stays as the P7 projection, and a build-speed benchmark lands
  with the switch.

## Milestone 6 — `if`, the structured-IR proof

The riskiest recorded decision — control flow as STRUCTURE, never a
flat CFG — proven on the smallest construct that forces it, before
functions multiply the surface. Spec syntax, expression position:
`if cond { a } else { b }`.

- The IR stays ONE flat list; control flow arrives as Wasm-shaped
  BRACKETS, exactly the shape ScopeEnter/ScopeExit already chose:
  `IfStart(cond)` … `Else(gives)` … `IfEnd(dst, gives)`. Each
  branch names the register it yields; no labels, no jumps, regions
  reconstructible by matching brackets.
- Lowering and eval walks become ON-DEMAND: `reg_of`/`value_at`
  compute a child at first request (memoized), so `if` lowers its
  branches INSIDE its brackets and eval runs only the taken branch.
  The contract's names and signatures do not change — laziness is
  the driver's upgrade. Typing and resolve keep the full post-order:
  BOTH branches must check. Invariant made law: a node's result
  register mints AFTER its children's — `binary_reg` reordered.
- Each branch is a SCOPE to the memory pass, at its enclosing
  level: branch-bound managed values release at branch exit —
  except the yielded register, which escapes to the phi and is
  owned (as `dst`) by the enclosing scope. One allocation, one
  release, on whichever path ran: memory-as-strategy in anger.
- Backend: blocks and phi at emission only, the mechanics
  `bool_word` already proved; `get_insert_block` (already in the
  wrapper) tracks branch-end blocks for nested ifs.
- Typing: the condition must be `bool`; the branches must agree —
  both wordings under `type.mismatch`, golden-tested.
- Keywords join reserved words in resolve: `let`, `if`, `else`,
  `true`, `false` refuse as binding names (today `let true = 1`
  parses and shadows — the gap closes with the feature).
- Gate: `make test` green plus `native == eval` over branching
  corpus programs, strings-bound-in-branches included.

LANDED: 196/196 green; `native == eval` across all six corpus
programs, nested ifs and branch-bound strings included. The
on-demand walk landed without touching any feature impl but the
mint-order reorder in `binary_reg`; the memory pass's branch scopes
release temporaries inside their brackets and the yield escapes to
the merge, released once at the outer exit.

Then M7 — functions: the locked ABI (callee-cleans, Call/Ret
carrying levels) and statement semantics joining NodeSemantics.

## Milestone 7 — functions (the design)

The locked ABI lands, and the yield machinery becomes the calling
convention. Thin tracer: single-EXPRESSION bodies on one line —
`fn fib(n: int) -> int { if n < 2 { n } else { fib(n-1) + fib(n-2) } }`
— because that exercises the WHOLE vertical (declaration, params,
calls, recursion, frames, multi-fn LLVM, callee-cleans) without
nested statement scopes. Block bodies with `let`s are M7.5.

- AST: `Stmt.FnDecl(name, params, ret, body)` with params carrying
  their annotated type NAMES (surface syntax, resolved by typing);
  `Expr.Call(callee, args)` — direct calls by name, fn values later.
- Grammar: the decl is a `stmt` branch anchored on `fn`; the call
  is a `primary` branch `NAME "(" args ")"` ORDERED BEFORE the
  spine's bare-NAME ident — the executor backtracks, so `f(x)`
  takes the call branch and `f` alone falls through to ident. The
  dead-branch gate must sanction this second overlap class.
- Resolve: two namespaces in one pass — fn names are visible
  program-wide (recursion and mutual recursion are free); params
  bind inside their body only, resolving to (fn, param index) in a
  new dense fact; lets stay lexical.
- Typing: annotations intern to shapes; the body types under its
  params and must agree with the declared return; calls check
  arity and every argument against the signature.
- Eval: a CALL is a fresh frame of param values; body nodes are
  computed per call (the global memo dies — it was single-pass
  coupling, and each tree node still evaluates once per call).
- IR: `Lowered` becomes one body per fn plus main; registers are
  per-body, the first N minted as params. `Call(dst, callee,
  args)` and `RetVal(r)` join the closed set — a call is a control
  shape, so this is a core event by doctrine.
- Memory — the ABI, callee-cleans: the caller RETAINS each managed
  argument (`avra_rc_retain` — ownership transfers in), the callee
  releases its params at body exit MINUS the returned value
  (`kept_out` — the branch-yield rule, generalized), and the
  caller owns the call's result. Balanced on every path, aliasing
  safe.
- LLVM: one function per body, params/ret typed by shape; `Call`
  is a plain typed call. The verifier gates every fn.
- Gate: `native == eval` with recursive corpus — `fib(10)`,
  string-returning branches, mutual recursion.
- The RECORDED TRIGGER fires: FnDecl is the third statement kind —
  statement dispatch (stmt_value, binding, fingerprints, drivers)
  is audited in-milestone and statements join the semantics
  contract the moment the direct extension turns into arm-copying.

LANDED: 210/210 green; `native == eval` across all seven corpus
programs — recursive fib through LLVM included. The milestone's
hidden gem: ALTERNATION GREW UP. The executor's first-token commit
became DEFERRED commitment — a broken branch's diagnostics stand
only when no later branch hits — and the dead-branch gate learned
the matching notion of a COMMITTING branch, so `f(x)` and bare `f`
share a rule and keyword statements live behind expression
statements, all still golden-diagnosed. Statement dispatch stayed
five explicit sites (each an exhaustive match, so every new kind
breaks loudly); the contract-join waits for the fourth statement
kind to prove the pattern. Along the way lib-mode mono ate a
nullable generic local — subset-noted, bool-flagged.

## Milestone 9 — blocks (the design)

Rung 2, a capability milestone: statement scopes inside
expressions. ONE block construct, defined once and borrowed
everywhere — the `when`-on-`if` composition lesson, applied again.

- The `block` feature owns the rule and the node:
  `block = "{" v:expression "}" -> v
         | "{" ( s:stmt | BREAK )* "}" -> block(s)`
  The inline form PASSES THROUGH (a one-expression block costs no
  node — every existing one-line fn and if keeps its exact tree);
  the multi-line form reaches the second alternative by deferred
  commitment. `Expr.Block(stmts, value)`: the builder splits the
  last statement, which must be an expression — "a block ends with
  an expression" is the builder's law.
- fn bodies and if branches reference `b:block`; `when` arms stay
  expressions (the spec's shape).
- A block is a CONTROL-OWNING node: kids() = [] and every pass
  recurses through a driver capability — the on-demand doctrine,
  extended to resolve and typing for scope-carrying nodes:
  `block_scope` (sequential walk+bind under an UNDO-LOG scope;
  shadowing restores at exit; nested fn decls refused — "fn
  declarations live at the top level"), `block_type`, `run_block`
  (stmts execute under the current frame), `lower_block`.
- The IR's core event: `ScopeExit` grows `gives: Reg?` — a scope
  YIELDS like a branch does. Memory releases the scope minus its
  yield and the enclosing scope ADOPTS it (ownership moves out one
  level); the fn-body `kept` parameter dies into the same
  mechanism. Backend unchanged (scopes stay no-ops); renderer says
  `yield rN` before the closing brace.
- `return` is deferred to rung 3 (it belongs with loops and early
  exit); recorded, not slipped.
- Gate: multi-line fn bodies with block-scoped strings — releases
  inside the block, the yield adopted outward — eval == native ==
  expected.

LANDED: 221/221; nine-for-nine corpus. Multi-line expressions
arrived FREE — braces swallow their BREAKs, so a let whose value is
a multi-line if needs no design at all. The inline pass-through
held: every existing one-line construct kept its exact tree and
every golden survived except the fn-scope yield line. The arc's
real dragon was not blocks: the staleness class was finally
ROOT-CAUSED (bs2 keys `bs2 run` caches by the entry file's bytes
alone) and killed structurally — ./avra generates a content-stamped
entry, so cache keys are truthful and warm. Every phantom of the
last two milestones was that one bug in costumes.

## The growth ledger (what a feature costs)

M7 was ~1200 lines, and the fair audit says where: ~600 were the
DRIVERS learning capabilities no feature had needed before —
frames, signatures, one IR body per fn. Capability cost is
per-MILESTONE, paid once. The steady-state FEATURE cost is what
if_expr paid (~150 lines): its directory, three wiring lines, a
corpus program. The machinery that keeps it there:

- `avra new feature <name>` writes the directory — six compiling
  files and a passing test skeleton — and prints the three wiring
  edits. Review starts at the semantics, never the ceremony.
- The corpus gate: a feature's end-to-end proof is corpus/<name>.av
  plus its .expected — two tiny files — and `make gate` holds
  eval == native == expected for every program, forever.
- `dst_of` lives beside Ins: IR consumers query, never keep their
  own lists. IR growth is rare by doctrine; its touch points are
  the enum, its accessor, the renderer's arm, the backend's arm.

THE NODE MODEL, SETTLED (2026-08-26): typed enums stay. The Expr
variant a feature adds is not registration — it IS the single
definition (P12), and one definition site is the floor. The two
genuinely mechanical arms beside it (the fingerprint fold, the
semantics_of line — four lines, both exhaustive matches, so
forgetting one is a loud compile break, never a silent bug) are
temporary rent with a planned death: the epic's actual thesis is
"the AST is defined once; every mechanical operation derives or is
a compile error" — so at self-host, `@derive(fingerprint)` and
manifest-derived dispatch erase them. A uniform untyped node was
considered and REFUSED: it buys zero-growth by trading away typed
payloads and pattern matching, and the O(1) it promised is already
here — fingerprints are computed at alloc and compared in O(1)
today, and hash-consing (memory sharing, automatic incremental)
stages onto those SAME fingerprints at the cache layer in Era IV,
node model untouched. Spans living in side tables and fingerprints
ignoring them — designed in at M1 — is exactly what keeps that
staging clean.

Recorded triggers:
- Statement semantics: FIRED and DONE (rung 3's opening act).
  StmtSemantics is the stmt-spine's twin of NodeSemantics: four
  feature-owned impls (let, expr, fn — which refuses in blocks
  through its own resolve_stmt — and the hole), four capability
  contexts, one stmt_semantics_of map that breaks loudly on a
  fifth kind. The eight driver walk loops collapsed to four
  one-line prose loops (resolve_stmts, type_stmts, eval_stmts,
  lower_stmts), each serving top level and blocks alike. Landed
  behavior-preserving: zero golden changes. The next statement
  kind (assignment) costs its impl plus the map line — the same
  steady-state shape expressions already enjoy.

The falsifiable claim, TRIED (M8, `when`): the doctrine's core held
perfectly — zero new instructions, zero edits to drivers, memory,
backend, or renderer; `when` desugars entirely onto `if`'s region
brackets from its own lower.av. The claim needed ONE amendment: a
feature that claims a KEYWORD also adds one line to resolve's
keyword list. The trial also surfaced two non-feature finds, which
is what trials are for: a latent stale-cache trap (cli/avra.toml
needed [dependencies] so the compile unit's cache key sees the
compiler's sources — bs2's own cli manifest documents the same
trap) and the GREEDY-STAR LESSON: a repetition cannot be told to
stop early, so an arm that could also start the tail must be an
ordered choice inside the slot, `_`-first — never a tail after the
star. The engine could catch this class statically (star-item FIRST
∩ tail FIRST): recorded for the gate, below.

## The IR doctrine (agreed 2026-08-25)

The backend and memory pass never grow with features — they are
functions of the IR, and the IR is CLOSED vocabulary. What keeps it
closed:

- Features lower into existing instructions. A new Ins variant is a
  CORE event — a new control shape (`if`'s brackets), a new value
  category, a new memory boundary — reviewed like a spec change,
  never a feature convenience.
- Value-producing runtime needs ride `CallRt(dst, callee, args)`:
  one instruction, one backend arm, callees declared once in
  declare_runtime. String equality was the proof — its bespoke
  instruction died the day the pattern generalized.
- Memory inspects neither features nor callees: managedness is the
  destination's type SHAPE, strategy is the scope's LEVEL.
- Print stays keyed by shape — a set that grows with TYPES (a core
  event by definition), never with features.

M7's Call/Ret are the doctrine's next test: user-level calls carry
the ABI — levels, callee-cleans — and a call is a control shape,
so they are core. The day a feature wants its own instruction, the
answer is CallRt or a design conversation, in that order.

## The speed doctrine (builds, caches, tests)

Sources: Zig's incremental-compilation internals (mlugg, 2026-07),
the L6 query-engine and codegen-cache designs. The laws every
milestone answers to:

- The per-file front end (lex → parse → lower) stays a PURE
  FUNCTION of file content: embarrassingly parallel, cached per
  file by content hash. Facts stay FLAT ARRAYS keyed by typed ids —
  writing a cache is a copy, never a serialization step.
- Incrementality is per DECLARATION, not per file: analysis units
  depend on other units and on source-REGION hashes; an edit
  re-analyzes only its hash's dependents (red-green). INTERFACE
  fingerprints stop propagation — a body edit never re-checks
  callers.
- Codegen needs no cache: its granularity (per fn) IS the
  incremental granularity — only re-analyzed fns re-lower.
- Per-update work is proportional to the CHANGE, never the program
  — no O(program) flush steps (Zig's resolveReferencesInner
  lesson).
- Tests run IN-PROCESS: the linked wrapper's `avra_llvm_jit_run`
  executes a module with no linker, no file, no shell-out; the
  evaluator covers pure code cheaper still. `avra test` is ONE
  process — analyze once, share every cache, JIT what must run
  natively. Shelling out to a child binary is a test-runner defect,
  not a technique (bs2's runner is the counterexample; it dies at
  self-host).
- The compiler dogfoods the language's own concurrency (spawn,
  channels — spec Axis 18) for per-file and per-unit parallelism
  the day those land; threads/processes are language features first
  and compiler infrastructure second.
- SOURCES ARE INPUTS, NEVER OUTPUTS. All cache state lives in ONE
  root (project-local `.avra-cache/` or a global user cache dir),
  content-addressed; fast-path validators (mtime+size envelopes)
  live INSIDE the cache keyed by the source's absolute path, never
  beside the source. This is how Go (one content-addressed
  `$GOCACHE`), Cargo (everything under `target/`), and Zig
  (`.zig-cache/` + global) all do it; Python's `__pycache__` is the
  cautionary tale and bs2's `.avra-sha256` sidecars are its local
  rerun — an artifact we tolerate from the bootstrap and NEVER
  reproduce. One `avra clean` deletes the root; nothing else to
  hunt.
- ONE scheduler owns the machine: build work and test work share a
  bounded worker pool (workers = cores, memory-watermarked); an
  artifact two tests need builds ONCE — tests demand it as a query
  and suspend, and the content-addressed cache is the coordination
  point. Never a process per test and pray.
- Tests choose their execution tier by EFFECT: pure bodies run
  IN-PROCESS (evaluator or JIT, parallel on the pool — the compiler
  verifies purity, so they cannot contaminate each other);
  effectful tests get a pooled child process with a fresh temp-dir
  sandbox — isolation by process boundary, and a crash is a
  FAILURE REPORT, never a lost run. Until the effect system lands,
  the harness kind picks the tier.
- Test results are cache entries too: a test is a query keyed by
  (body hash, consumed-artifact hashes) — an untouched test replays
  its PASS instantly; an edit re-runs only the tests whose
  fingerprints moved.
- Sharing between tests is IMMUTABLE: only content-addressed
  artifacts, never mutable state — that is what makes the
  parallelism safe. Remote caches/executors drop in behind the same
  keys later; keys stay content-addressed so that door stays open.
- ENDGAME (recorded, not scheduled): a compiler-integrated
  INCREMENTAL LINKER — machine code patched in place into a mapped
  output file (Zig's MappedFile shape), rebuilds in tens of
  milliseconds. Until then: in-process object emission + the system
  linker.

## Engine sufficiency (recorded, not scheduled)

- The dead-branch gate learns the greedy-star ambiguity: flag a
  branch whose star-item FIRST set intersects its following
  required tail's FIRST set — the star eats the tail's opening and
  the branch can never finish (M8's `_`-arm lesson, made static).

The engine as it stands parses everything Avra currently is and
everything on this roadmap's near horizon — no engine work is owed.
bs2's parser runs the same core discipline (FIRST-set dispatch,
commit on the first token, no default backtracking); its extra
annotation vocabulary maps ITS language's hard corners, and becomes
relevant here only if the spec adopts a construct that demands one:

- `@peek(pred)` — only if a construct needs lookahead past one token
  (optional chains, trailing commas, `if let`).
- `@try` — only for a genuinely ambiguous multi-token prefix
  (turbofish `f<T>(x)` vs `a < b`).
- `^` same-line gate — only for layout-sensitive suffixes.
- `@when(pred)` — only for parse-state-dependent branches.
- Mode flags — only for context windows like the pipe's `it` sugar.

`@cut` never applies — anchor-commit is an automatic cut. Nothing
architectural blocks any of these; none is planned until a spec'd
feature asks.

## Multi-file design (recorded, not scheduled)

The single-file shapes ARE the multi-file design in miniature —
additions get siblings, nothing changes shape:

- A Workspace holds many per-file Analyses; `analyze` stays the
  per-file pipeline, a workspace pass orders files and feeds import
  facts in through the SAME standard signature.
- Node ids stay store-local. Cross-file references ride SymbolId —
  content-hash of (qualified path + kind), per the epic §15.5 —
  store-independent and stable across processes.
- Each Analysis grows an Exports fact: the module's PUBLIC surface as
  name -> (symbol, signature fingerprint). Importers read surfaces,
  never neighbor trees — private edits cannot invalidate importers.
- Content-addressed TypeIds (§15.3) make per-file registries agree by
  construction: same shape, same hash, everywhere — cross-file type
  identity needs no coordination step.
- The L6 query engine lands at the workspace seam: per-file Analyses
  memoized by content fingerprint (nodes already fingerprint); an
  edit re-runs importers only when the export surface's fingerprint
  moved.

## Sugar backlog — dogfooding asks

The compiler is Avra's first real program, and writing it is design
evidence: whenever its own code WANTS a construct the language
lacks, the ask lands here with the wanting site. Entries graduate
into features (or spec commitments) when their milestone comes.

- Match THROUGH the nullable: variant arms plus a `null` arm on
  `T?` (`match o.result { .Node(.NGrammar(g)) -> g, null -> ... }`)
  — wanted by every unwrap-then-match two-step (grammar_result, the
  pass drivers); the subset refuses (F9001).
- `?.` through calls, not just fields — `answers_to` wanted
  `token_name()` projected straight into a compare; today a bound
  let (and the direct compare is #1376).
- Comprehension destructuring: `[fix(i, m) for (i, m) in
  xs.enumerate()]` — wanted by attach, first_defects, joined.
- Any expression as a comprehension ELEMENT, generic bodies
  included — if-else elements die there today (F1000); wanted by
  bind_label. Same for the FILTER: `||`/`!` in a comprehension `if`
  refuse to parse; wanted by the memory pass's releases.
- Derived structural identity: `fingerprint_expr` is mechanical —
  tag + payloads + child fingerprints per variant. One source of
  truth, many projections (P12) says the compiler should DERIVE
  content hashes from type structure; wanted by every new Expr
  variant's hand-written fp arm. Same story for per-variant payload
  accessors (`truth_of`/`int_of`/`text_of`, the `_of` extractor
  sets): mechanical, derivable, erased by `@derive` at self-host.
- `it` inside `is`-expressions: `ins.filter(it is .Release)` —
  wanted by every IR test; an explicit lambda today.
- Or-patterns that BIND when the payloads agree in type:
  `.Lit(text) or .Named(text) -> text` — wanted by token_name.
- In-place mutation through self: `self.diagnostics.push(d)` — the
  `mut alias` two-step in every speak/give/record is ceremony the
  mutability rules (Axis 11) should erase.
- Structural `==` for lists (and `contains` by value for all
  elements) — every list assertion in the suite hand-rolls it.
- `??` guaranteed LAZY on the right — program_stmts wanted
  `sid ?? store.alloc_stmt(...)` and could not trust eagerness.
- Struct literals inline in argument lists — the pin rent paid
  across the tree is the evidence.
- SHAPES, evidenced (not a new ask — the spec's type/shape axis
  already holds the design): the pass capability contexts (four
  expr Cx, four stmt Cx) share a prefix — store plus one walk fn —
  and differ per pass. Width subtyping collapses this the
  structural way: each capability declares the MINIMAL shape it
  needs and every nominal cx satisfies it by its fields; shape
  algebra names the family. `shape` is reserved in bs2 for exactly
  this. contract.av is the wanting site, and this evidence bumps
  shapes' priority when rung 7 (structs) lands.

## Self-host endgames (recorded, not scheduled)

- Typed builders: `-> int_lit(v)` binds a typed fn; tables and
  positional accessors die (TECH_DEBT)
- `@derive(Error)`: the enum declaration becomes the error table —
  kinds from names, messages from doc-comment templates, generating
  exactly `describe()`
- Trait default method bodies (bs2 ICEs today): `kind()`/`message()`
  return as defaults over `describe()`
- `grammar { }` blocks replace raw-string grams
- Bare component instantiation (registry spans files)
- Query engine (L6 red-green memoization) wraps the pure passes
- A real feature-extensible language lexer

Update this file whenever a slice lands or the plan changes — the
roadmap lives HERE, not in conversation.
