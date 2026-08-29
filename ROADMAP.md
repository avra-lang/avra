# Roadmap

## The north star (recorded 2026-08-26)

The compiler is not a pipeline. It is a DATABASE: a
content-addressed semantic store, a tiny pure-derivation kernel,
the language itself as a hashed value, and everything else — the
binary included — as a projection. The layers, from zero:

- L0 STORE: machine-global, persistent, content-addressed. Keys
  are content PLUS environment (a node's meaning depends on its
  scope). Nothing is computed twice anywhere on the machine.
  Fingerprints-at-alloc are this store's keys, already born.
- L1 KERNEL: compilation is memoized evaluation of pure fns over
  the store with automatic dependency capture — red-green at
  declaration granularity. Incrementality and parallelism are the
  EXECUTION MODEL, not features. The kernel stays small, boring,
  and verified.
- L2 LANGUAGE-AS-VALUE: the assembled language (grammar,
  semantics, diagnostics, idiom rules) is a hashed object; every
  program records the language hash it was written against — P9
  applied to the language itself. explain/docs/LSP metadata are
  its projections.
- L3 ONE SEMANTICS, THREE ENGINES: features define meaning ONCE —
  lowering to the IR — and the evaluator becomes an IR
  INTERPRETER. The same semantics object runs interpreted
  (comptime, tests, REPL), JITted (dev), and AOT (release).
  eval == native graduates from our best test into a structural
  impossibility. LANDED (same day): language/interp.av walks the
  lowered stream — a Val enum, bracket-scan control flow, frames
  and heaps in machine tables, and the runtime registry's fifth
  consumer hosting every CallRt row with matched refusal wording.
  The per-feature eval.av layer DIED (eight files, the EvalCx and
  StmtEvalCx contracts, the printed method, literal_eq, the
  evaluated-payload verbs): 688 lines out, 321 in, and every
  behavioral test passed UNCHANGED — the semantics were already
  one; now they are written once. The heavyweights will each be
  specified exactly once. The collapse then went one deeper:
  Ins.Print DIED — printing is lowering (the answer's text
  projection call plus one puts), so the backend's per-type print
  dispatch and the interpreter's print arm vanished, the registry's
  coercion replaced the hand-written bool widening, and the IR
  goldens now SHOW the provenance system working: an owned
  int_text result releases, a static bool_text answer does not.
- L4 MEMORY AS KNOWLEDGE: the ownership registry in the runtime
  is scaffolding; the destination is full static ownership from
  the memory pass — the runtime knows allocate and free,
  refcounts only where escape analysis provably cannot decide.
- L5 EVERYTHING IS A PROJECTION: text files render from the
  semantic object (fmt = render, rename = graph edit);
  diagnostics are structured repair objects (human text and
  --json are two renderings, `avra fix` applies edit sets);
  compilation is TOTAL (every program runs, holes refuse at the
  hole); the compiler process is the one long-lived query engine
  behind CLI, LSP, build, and — Era V — the service orchestrator.

What the current tree already got right (build on, never churn):
pure pass signatures ARE derivations; fingerprints ARE store
keys; features-as-values IS the language object; the closed IR IS
the one semantics; Analysis IS a query bundle; the idiom registry
IS a language-object member. The deltas land by era: the
eval-collapse next (queued), store/kernel at Era IV (contract
recorded), static ownership with the ownership arc,
text-as-projection after self-host, the service store at Era V.

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
    3.  [x] mutation & loops — `mut`, assignment, `while`, range `for`
    4.  [x] operators complete — `&& || !`, `!= > >= <=`, `* / %`,
        grouping parens
    5.  [x] lists — the first aggregate; iteration; `.length` opens
        the method core (the scan methods ride closures, rung 13)
    6.  [x] strings complete — `${}` interpolation and `.length`
        (the remaining method words ride method-call-with-args,
        recorded at the method core)
    7.  [x] structs — declarations, literals, `with` (impl methods
        ride the method core, rung 13; the spec's `shape`/width
        subtyping keeps its recorded arc)
    8.  ▲ enums & match — slice (a) LANDED (declarations, unit
        variants, total match); slice (b) is payloads + pattern
        binds (Binding grows its variant)
    9.  nullability — `T?`, `null` arms, `! ?? ?.` — and the
        spec's bind-fresh trio (Axis 10): `let v? = e else { }`,
        `if let v? = e`, effectively-final narrowing. The trio is
        the answer to the guard-and-bang ceremony; index_value in
        expr_spine/eval.av is the exhibit
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
  feature docs — and THE IDIOM ENGINE: pattern-detecting rewrites
  ("this accumulate loop is a map — here is the comprehension") as
  warning-grade diagnostics with structured fixes, riding the
  Suggestion/Edit machinery diagnostics already carry. Idiom rules
  are PER-FEATURE manifest entries (an `idioms` table beside
  `gram`/`builders`/`diags`) — each feature owns the beautiful
  form of its own constructs; DOGFOODING.md is the rulebook being
  written by hand until then, and the trigger is self-host: idiom
  rules are Avra fns matching Avra's own AST. GATE: rebuild-after-
  one-edit and suite wall time, measured and budgeted.
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
  `IfStart(cond)` … `ArmEnd(gives)` … `RegionEnd(dst, gives)`. Each
  arm names the register it yields; no labels, no jumps, regions
  reconstructible by matching brackets. (The arm/region spellings
  arrived with SwitchStart, which generalized this shape from two
  arms to N — the design was right, the names were If-flavored.)
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

## Milestone 10 — mutation & loops (the design)

Rung 3 proper. Two features, three statement kinds, two core
events — and the statements contract's first steady-state test.

- MUTATION (one feature: `mutation`): `mut x = e` declares a
  reassignable binding; `x = e` assigns to one. Assignment to an
  immutable let, a param, or a fn refuses (resolve.immutable);
  assignment must keep the declared type. V1 RESTRICTION, honest:
  mut bindings hold SCALARS (int, bool) — a mut string needs
  store-over-release ownership analysis, and that arrives with the
  memory pass's next chapter, not as a footnote here.
- LOOPS (one feature: `loops`): `while c { statements }` — a
  statement, no value; its body is a statement list under its own
  scope, cond re-evaluated each turn.
- THE IR: mutation lands as SLOTS — `Alloca`/`Load`/`Store` (a mut
  binding's slot is memory, loads mint fresh registers, so
  born-SSA survives BY DESIGN: registers stay single-assignment
  and mutation lives in memory, exactly LLVM's own answer, with
  -O1 mem2reg recovering registers). Loops land as brackets —
  `LoopStart`/`LoopCond(c)`/`LoopEnd` — the third bracket family
  after scopes and regions. Both are core events by doctrine:
  a memory boundary and a control shape.
- The DRIVER seam stays thin: an ident whose target is mut gets
  its Load minted by def_reg — the spine's ident rule stays dumb.
  Eval is trivial: slots were always a table; assignment writes
  the target's slot through one new capability.
- `require_bool` extracts on its THIRD copy (if, when, while) —
  the recorded trigger, fired on schedule.
- Range `for` follows as its own quickie: it desugars to mut+while
  INSIDE its feature — zero new instructions, the when-lesson
  again. `return` stays deferred: early exit is its own
  capability arc.
- Gate: a native countdown loop — mut, assignment, while, and a
  string built by branches inside the loop, eval == native ==
  expected.

RANGE-FOR LANDED (the rung 3 tail, and the inversion's PROOF):
242/242; twelve-for-twelve corpus, for.av driving nested counters
through a fn natively. The claim held where it mattered: every
rule body lives in the loops directory — `for` joined the EXISTING
feature, so even the stanza line was free, and its keywords
(`for`, `in`) derived from the gram with zero list edits. Outside
the dir: the node variant + fp arm, the map line + import (the
four one-liners), the corpus pair — plus THREE capability events,
honestly counted: the `..` token (the lexer is not
feature-extensible yet — recorded endgame), the `bound_scope`
resolve verb (a fresh scope holding its owner's binding — rung 5's
for-each reuses it), and two resolve-law refinements the new scope
shape forced (a name resolves ONCE, first walk wins, diagnostics
included; a SCOPED binder never counts as a later definition). The
desugar is parse-time and fully inspectable: `avra ir` shows the
counter cell, the re-run condition, and the step store — mut+while
in costume, zero new instructions (P7 held).

LANDED: 233/233; ten-for-ten corpus, loop.av native through slots
and the third bracket family. The statements contract's first
steady-state test PASSED: three new statement kinds cost their
semantics impls plus map lines — zero new driver walk loops. The
arc's one regression taught a grammar law now in CLAUDE.md:
@recover converts a break into a hole HIT, so it belongs only on
keyword-anchored branches — a recovering NAME-headed assign branch
swallowed every expression line in the language. Range `for` is
rung 3's tail, next: it desugars to mut+while inside its feature,
zero core events, the when-lesson replayed at statement level.

## Milestone 11 — operators complete (landed with its design)

Rung 4, and the closed-vocabulary IR's price check. The ladder:
`|| && (== != < <= > >=) (+ -) (* / %) ! primary` — plus grouping
parens, discovered MISSING by the first probe (`!(a != 7)` had
nowhere to parse; precedence override is part of "complete").

- EAGER ops (`* / % != > >= <=`): BinOp variants + table rows +
  law arms — they ride Ins.Bin untouched. The doctrine's cheap
  path, confirmed: zero IR, zero backend shape changes, the llvm
  arm is one icmp number.
- LAZY ops (`&&`/`||`): BinOps whose OWNER treats them as control —
  eval short-circuits (the on-demand walk never touches a side
  that cannot matter), lowering desugars onto the if-region
  brackets exactly as `when` did. corpus/ops.av pins a division
  by zero sitting UNEXECUTED behind both ops, natively. One new
  general LowerCx verb (`mint` — a scratch register, mirroring
  StmtLowerCx's) paid for the constant arm.
- `!`: Expr.Not plus the IR's missing INSTRUCTION SHAPE — `Un(dst,
  op, src)`, one core event that covers every future unary (minus
  arrives free). String `!=` is streq + Un Not.
- Division by zero: eval REFUSES the run ("division by zero");
  native traps. A recorded divergence — the policy belongs to the
  error spine (rung 10), not to an operator milestone.
- Unary minus: deferred until literals/negation design (the spec's
  call); recorded, not slipped.

LANDED: 254/254; thirteen-for-thirteen corpus. No new keywords —
all operators are symbolic, and the derived-keyword list did not
move. Touch bill: core (BinOp + Not + Un), the spine's dir, the
three backend arm sets (renderer, llvm, memory pass-through), one
LowerCx verb, six lexer tokens. The round after: the op<->symbol
truth moved beside its enum (`op_symbol`/`all_binops` in core —
the parse table, the checker's wording map, and the renderer's map
were three copies), the homogeneous-operand law extracted to ONE
`needs` (int and bool mismatches were the same sentence), and the
lexer's eight two-char munch arms became one data-driven scan.

## Milestone 12 — lists (the design)

Rung 5: the first aggregate, vertically. The native story cost
zero design: the bootstrap runtime already ships dynamic arrays
(`avra_array_new/push/get/len`, int64 slots), so lists ride CallRt
— the closed vocabulary's escape hatch doing exactly its job.

- SURFACE: `[e, e, e]` literals; `xs[i]` indexing; `xs.length`;
  iteration is range-`for` over indices (`for i in 0..xs.length`)
  — for-EACH sugar waits for the two-binding For design, recorded.
- OWNERSHIP: the `lists` feature owns the literal and the List
  TYPE's laws; the SPINE owns the postfix ladder rungs (`indexed`,
  `postfix`) and the Index/Prop nodes — access is expression
  structure, like Binary. Index's eval reads elements through the
  value protocol's new projection (`elems_of`) — no cross-feature
  match. Properties parse as ANY name; TYPING refuses unknown ones
  by name — the method core's opening, better errors than a parse
  refusal.
- V1 RESTRICTIONS, honest, each with its trigger: elements are
  SCALARS (strings-in-lists wait for ownership analysis, same
  clause as mut strings); `[]` refuses at typing (no annotation
  syntax can seed it yet); lists cannot cross fn boundaries (the
  annotation grammar is one NAME — generic annotations are rung
  11's); `==` on lists refuses (element-wise equality needs the
  runtime story); a program cannot PRINT a list natively (the
  in-tree runtime brings the printer — eval prints `[1, 2, 3]`);
  `mut` still holds scalars only; v1 postfix stratifies — indexing
  binds tighter than properties, interleaved chains redesign at
  structs (rung 7).
- MEMORY: bootstrap arrays are malloc'd and process-lifetime (no
  avra_array_free exists) — List registers are NOT managed: the
  memory pass passes them through like ints. The real strategy
  arrives with the in-tree runtime; leak-by-design is the
  bootstrap's own answer.
- CORE EVENTS: `Type.List(elem)` — the first composite, exactly
  what the registry's canon-key design waited for; `CallRtVoid` —
  the effect-only runtime call (push has no value); the `elems_of`
  value projection; three Expr variants (ListLit, Index, Prop).
- Gate: a corpus program that builds a list, indexes it, measures
  it, and folds it through a range-for — ending in a scalar,
  eval == native == expected.

LANDED: 269/269; fourteen-for-fourteen corpus, lists.av folding
eight elements through a range-for natively. The design held with
one addition earned along the way: the spine's postfix ladder
(`indexed`, `postfix`) — property names parse generously and
typing refuses them BY NAME (`no property `size` on `List<int>``,
help naming the one that exists). The `.` token joined the lexer's
single-op set (the golden that said a lone `.` is an error changed
because the TRUTH changed). Every v1 restriction refuses with its
remedy in words: empty literal, mixed elements, managed elements,
list `==`, mut lists, and the native list answer — the last as
F0901 language.unsupported at lowering, while `avra run` happily
prints `[1, 2, 3]`. Two new subset pins recorded (enum-list and
`?? []` tails both need typed lets).

## Milestone 13 — strings complete (the design)

Rung 6: `${}` interpolation, and the string side of the property
core. The native story again costs zero runtime edits: parts and
stringified holes ride the SAME array machinery lists built, and
ONE `avra_str_join(arr, "")` answers — plus `avra_json_stringify_int`
(decimal IS json), `avra_bool_to_string`, and libc `strlen` for
string `.length` (closing M12's recorded gap). `avra_bytes_concat`
was probed and REFUSED: it reads length-prefixed bytes values, not
C strings.

- THE CAPABILITY COST, named: the lexer learns interpolation MODES.
  `"a ${x + 1} b"` lexes as ISTR_BEGIN("a ") <hole tokens>
  ISTR_MID/ISTR_END(" b") — a stack of open holes with per-hole
  brace depth, so `}` closes the RIGHT thing. Three new terminals
  join TokenKind and the DSL's term table; the engine matches them
  by kind like every terminal.
- The node: `Expr.Interp(parts, holes)` — parts one longer than
  holes, owned by the str_lit feature (interpolation IS the string
  feature growing; its gram gains one primary branch).
- Typing: every hole prints as a scalar or string; the answer is
  Str. Eval: the value protocol's projections build the text.
  Lowering: stringify each hole (Str as-is, Int via
  json_stringify_int, Bool via bool_to_string), array-push the
  pieces, join once. Memory: the result is managed Str — the
  existing machinery releases it; bootstrap-malloc'd intermediates
  leak by the bootstrap's own design (rc_release no-ops on
  pointers outside the rc set — probed in the source).
- String `.length` (bytes, via strlen) joins Prop — the "for now"
  message dies.
- V1 RESTRICTIONS: a hole takes any brace-balanced expression
  (depth-counted); List-valued holes refuse with the remedy
  (print an element or `length`).
- Gate: a corpus program interpolating ints, bools, strings, and
  nested arithmetic natively — eval == native == expected.

LANDED: 276/276; fifteen-for-fifteen corpus, interp.av printing
`hello avra, 3 things are true: n=7` natively through array + join.
The steady-state claim's strongest showing yet: interpolation cost
ZERO driver edits — resolve, typing, eval, lower, and memory were
untouched; the feature dir, the lexer capability, one map arm, and
the backend's declares carried everything.
The design held with one discovery the verifier forced: the
runtime's int64 SLOTS carry every value category, so the backend
grew `rt_arg` — pointer registers cast down (ptr_to_int) and bools
widen (zext) on the way into a slot param, declared per callee in
`slot_param`. That closed a LATENT native hazard too: a bool
element pushed into a list had never met the verifier. String
`.length` landed via libc strlen (the "for now" message died); the
ratchet fired TWICE during the build — once on a label string the
I13 binds had just unified (fixed by `this_is`, the pointing
label's one definition) and once on rt_args' licensed
enumerate-loop (bumped deliberately, in the open). bs2 note: `\$`
is NOT a bs2 escape — test sources build `${` by concatenation;
OUR `\$` escape is how Avra text holds a literal hole.

## Milestone 14 — structs (the design)

Rung 7: the first user-defined type. The native story is the lists
machinery a THIRD time: a struct value is a fixed slot array —
literals are array_new + one push per field, field reads are
array_get at the field's compile-time INDEX. Zero new
instructions; rt_arg's slot coercions already carry every field
category.

- SURFACE: `type Point = { x: int, y: int }` (a STATEMENT, name in
  its own namespace, program-wide like fns); literals
  `Point { x: 1, y: 2 }` (every field, once, any order); reads
  `p.x` through the EXISTING Prop node — the postfix ladder was
  built for this.
- THE TYPE: `Type.Struct(decl: StmtId)` — nominal by declaration
  site; the registry's canon key is the decl id. Field names,
  types, and ORDER live in a pass fact (the decl's signature,
  collected before bodies like fn sigs).
- OWNERSHIP: a `structs` feature owns the declaration statement,
  the literal, and the type's laws; the spine's Prop typing asks
  the FIELD TABLE first, `length` second — property resolution
  becomes a chain of owners.
- V1 RESTRICTIONS, each with its trigger: scalar fields (managed
  fields ride ownership analysis); no `with` yet (its own quickie
  on this node); no impl methods (the method core); no struct
  equality (`==` refuses with the remedy); annotations name
  declared types (shape_named consults the decl registry — the
  table gains rows at last); shapes/width subtyping deferred to
  its recorded spec arc.
- Gate: a corpus program declaring a struct, building literals in
  a fn, reading fields through arithmetic and interpolation —
  eval == native == expected.

CAPABILITY STANDARDIZATION (considered here, from review — and
DEFERRED to the query model): should driver machinery itself be
modular, trait-shaped? The seams already ARE standard — cx structs
(data + wired verbs, nested composition) for rules, the semantics
traits for features, ONE pass signature for facts — and the
machinery species with real copy-counts are recorded (dense
id-keyed tables ~9 sites; namespaces 2, trigger at enums; scopes
1). A bs2 trait kit is REFUSED: default methods ICE, dyn
mis-boxes, generic containers corrupt through mono — it would
stand on the toolchain's three weakest legs. The real
standardization is Era IV's: a capability IS a query surface over
DECLARED facts ("provides bindings: ExprId -> Binding; requires
struct_sigs") and the compiler derives tables, wiring, and
memoization from the schema. The cx structs are today's
hand-written projection of that schema; at self-host the schema
becomes the interface and fact-kinds become registrable forms.

THE FORM-VS-HALLWAY LAW (settled here, from review): a capability
lands either as a FORM — a slot later features register into — or
a HALLWAY — driver code the next feature must edit again. Grammar
+ features IS the language; the drivers are the vocabulary of
fact-KINDS, and that vocabulary grows only at capability events —
but each growth must leave a form behind. M14's audit: the field
table and its verbs are forms (the Prop chain was edited ONCE to
ask fields_of; future field-bearing types answer through it); the
TYPE NAMESPACE is a hallway — declare_types hand-parallels
declare_fns, the second copy of "a program-wide namespace declared
from a statement projection". RECORDED TRIGGER: the third
namespace (enums) converts namespaces into feature-registered
rows ({stmt projection, namespace, duplicate kind} in the
manifest), collapsing fn_defs and type_defs into the same
registration path as builders and diags. The declare-phase
ordering (struct sigs before fn sigs) dissolves under Era IV's
query model — sigs QUERY field tables, no phase to sequence.

DEEP ROUND TWO (same day, from review — "can't we use `?`"): the
user's instinct was right and the probe trail it opened found a
THIRD closure-field trap. (1) `?` works on method results, in
argument position, and after an annotated bind — the Err
passthrough matches (run, emit, compose) were trap-fear, now `?`.
(2) But `?` DIRECTLY on a closure-field call corrupts, and (3) a
LAMBDA returning a scalar-payload generic enum through a fn field
corrupts its answers wholesale (named fns are safe; the engine's
pointer-payload build lambda survives, suite-pinned). All three
traps are now ONE DISCIPLINE in CLAUDE.md: a closure-field call's
result is consumed only through an annotated let. (4) `avra
check` disagreed with run/build: it reported analysis only, so a
no-projection program checked CLEAN yet refused to run — check
now renders lowering's refusals too, test-pinned. Also read whole
this round: first.av (which PROVES the struct-literal-before-NAME
ordering safe: two required items → non-committing → overlap
harmless), validate, coherence, builder.av, stmt_spine, bool_lit
(stale printed-era doc fixed), expr_stmt, cli run/check/main,
core span/arena/results/chars, diagnostics/mod, grammar/ast.

THE DEEP ROUND after the `with` tail (2026-08-28) — the finds:
(1) THE UNCHECKED-MATCH TRAP: bs2 skips exhaustiveness when a
match's subject is a CLOSURE-FIELD call — compiles clean, aborts at
runtime on an unlisted variant. Found because str_lit's hole_reg
survived M14 missing its .Struct arm; the capability-cx pattern
makes cx-verb matches our most exposed shape. Cure (probed):
annotated-let bind restores the check; untyped lets do not;
method/free-fn/index subjects are checked fine. One landmine
existed tree-wide (hole_reg — unreachable only because the interp
hole law is an allow-list); fixed, trap recorded in CLAUDE.md and
the upstream ledger. (2) NO-PROJECTION ANSWERS diverged the
engines: a struct-valued program answer printed nothing natively
but refused as "empty" in eval — now a LOWERING refusal (F0901,
with the remedy) through the new ONE checked seam,
Analysis.lowered_checked(), which run/emit/build all take (build
previously IGNORED lowering diagnostics entirely). (3) The managed
laws named: core's ptr_shape (heap-shaped, exhaustive on purpose —
enums must decide) closes the MUT-STRUCT GAP (mut p = P{..} slipped
the scalar fence); memory's is_managed (the RC strategy's Str-only
law) is now one fn with four callers and a comment separating the
two laws. Beauty: interp's run loop is one match; both bracket
scans share the ahead shape; loop_header's flag-match died.
Read WHOLE this round: interp, llvm, memory, executor, lexer,
grammar/builders, builder.av, ir, ir_text, render, source,
core/lists, core/text, and every feature check/lower touched since
M12; the rest swept by battery.

THE `with` TAIL (landed same arc): `subject with { field: v, ... }`
— its own precedence level (`withed`, between unary and postfix),
copy-or-carry pushes per declaration slot, the subject untouched;
zero new instructions again. The written-field law SHARED with the
literal (`written_checks`); `with` on a non-struct refuses (F2011).
Chained copies parenthesize today — a bare chain is a RECORDED
TRIGGER (the star flattens group captures; chains need per-group
boundaries from the executor). THE GRAM-BUILDER UNITY LAW,
discovered by the partial-assembly tests crashing: a builder named
in a feature's gram registers in THAT feature — the ladder's
`fold_with` is spine's; the With node's MEANING stays structs' via
semantics_of (parse ownership and meaning ownership are separate
axes, and the map is where meaning is assigned).

LANDED: 302/302; seventeen-for-seventeen corpus, structs.av
building literals in ANY field order (slots reorder to the
declaration) and crossing fn boundaries both ways. The design
held: zero new instructions, zero interp changes, zero memory
changes — the literal is array_new + ordered pushes, a field read
is array_get at a compile-time slot, all over the registry's
existing rows. The eval collapse and the runtime registry paid
for themselves in one rung. Costs beyond the feature dir: two
TypeCx verbs (bound_def, fields_of), two LowerCx verbs (mint_int,
field_slot), resolve's third namespace (type_defs, mirroring
fn_defs), Typing.struct_sigs declared BEFORE fn sigs. THE
DISCOVERY — the stmt-floor law: expr_stmt's recovering
NAME-headed branch was stealing keyword lines that merge after
it (`type P = ...` parsed as ident + failed BREAK + hole), so
expr_stmt now merges LAST and every statement feature lands
before it (CLAUDE.md grammar authoring). V1 restrictions stand
as designed (scalar fields, no `with`, no methods, `==` refuses,
no struct text projection for main's answer — project a field);
each trigger recorded in the design above.

## Milestone 15 — enums & match (the design, rung 8)

The second user-defined type and the first control-flow node a
feature owns end to end. Two slices, each gate-able:
(a) declarations, unit variants, exhaustive match;
(b) payload variants and pattern BINDS (Binding grows its variant).

- REPR: an enum value is the lists machinery AGAIN — a slot array
  with the TAG at slot 0 ([tag] for unit variants; payloads join at
  slots 1.. in slice b). Uniform array repr v1; a packed-int repr
  for unit-only enums is an optimization with a recorded trigger
  (profiling). ptr_shape(Enum) = true; is_managed stays Str.
- SURFACE: `enum Name { VariantA\n VariantB }` — a statement,
  newline-separated variants (spec 8.1); the name joins the ONE
  type namespace (type_defs — enums and structs are both types, so
  the duplicate-name law is free and the namespace-form trigger
  did NOT fire: still two namespaces, recorded honestly).
  Construction is QUALIFIED v1: `Color.red` (dot shorthand `.red`
  waits on expected-type threading, recorded). Match:
  `match subject { .red -> e, .green -> e }` — arms comma- OR
  newline-separated via the block's mixed-star idiom; NO `_` arm:
  exhaustive matching is the correctness guarantee (a `_` form is
  a later, deliberate decision).
- THE TypeName MARKER: `Color` in expression position resolves (a
  name that is a type binds Def(decl) instead of refusing) and
  types as Type.TypeName(decl, name) — a compile-only shape no
  runtime value ever has (ptr_shape false; refused by operand laws
  and the answer projection). The Prop chain grows its third
  owner: TypeName subject -> variant construction (structs' field
  table second, length third). Construction lowers WITHOUT
  lowering the subject: array_new + push ConstInt(tag).
- MATCH SEMANTICS: the enums feature owns Match (kids = subject +
  arm values, the If precedent); typing checks the subject is an
  enum, every variant exactly once, arms agree on one type (first
  arm anchors, when's wording). AMENDED after the trial: lowering
  was a region CHAIN of tag comparisons, and the user's call to let
  performance grow the vocabulary replaced it with ONE `SwitchStart`
  region — a jump table natively. The "zero new instructions" claim
  held for the rung and was then deliberately spent, once, under the
  protocol.
- FACTS: EnumSig { names, payloads } beside StructSig; typing
  declares enum sigs in the struct-sig phase; annotated() picks
  Struct vs Enum by decl-kind projection (enum_parts beside
  struct_parts).
- Codes: F2012 (enum declaration laws), F2013 (match laws).
- Gate: corpus/enums.av — declare, construct, match, cross a fn
  boundary — eval == native == expected.

SLICE (a) LANDED (2026-08-28): 330/330; nineteen-for-nineteen
corpus. The design held end to end — zero new instructions, zero
interpreter changes, zero memory changes, and the backend needed
only its two type arms. `avra ir` shows the whole meaning: read
tag at slot 0, then nested compare-regions, the last arm the
final else. THE TYPENAME MARKER earned its place: `Color` in
expression position resolves to its declaration and types as the
compile-only `Type.TypeName`, which no runtime value ever has —
so `Color.red` (construction) and `p.x` (field read) are ONE
parse shape decided by the subject's TYPE, and every operand law
and the answer projection refuse the marker for free.
THE EXHAUSTIVENESS DIVIDEND, immediate: adding two Type variants
broke `hole_reg` at COMPILE time — the same site that silently
survived M14 and aborted at runtime, before last round's
annotated-let fix restored the checker. The discipline paid for
itself within one rung.
THE NAMESPACE TRIGGER DID NOT FIRE, honestly: enums and records
SHARE the type namespace (both are types), so `type_defs` grew a
second declaration kind, not a third namespace — the
feature-registered-namespace form still waits for a genuine third
(recorded trigger unchanged). What DID arrive: `duplicate_member`,
one refusal for every declared table (a record's fields, an
enum's variants), which also revealed that the struct field-dup
law lives in TYPING (a driver) rather than with structs — its own
recorded trigger: it moves home when declaration sigs become
feature-owned queries.
THE POST-RUNG AUDIT (asked for, and it paid): two real defects of
mine, fixed and pinned. (1) `let c = Color` answered with an
INTERNAL DEFECT (F0900) — a compiler-blames-itself message for an
ordinary mistake — because TypeName was accepted anywhere and only
the Prop chain consumed it. Cured by ONE law, `refuses_type_value`
in features/checks.av (F2014), called at the value seam: the
statement-value ritual `walk_value` (so let, expr-stmt and every
future value-taking statement inherit it) plus mutation's own read.
The message names the remedy — a variant or a record literal — and
covers records and enums alike. (2) TWO `?? 0` fallbacks in
lowering would have SILENTLY built or compared the FIRST variant if
typing ever grew a hole; both are now defect refusals, the shape
every other lowering site already used. Also: a single-variant
match no longer reads a tag nobody chooses on (the subject still
evaluates — effects must not vanish), a dead parameter died, and
F2012's kind became `type.enum_decl` so its registry summary stops
lying about the duplicate-variant refusal it also fires on.

THE DECLARATION CURRENCY (the audit's architecture find, LANDED):
`sigs`, `struct_sigs`, and `enum_sigs` had become three parallel
dense StmtId tables filled in one declare phase with three verbs —
precisely the shape the Binding unification already collapsed once.
They are now ONE `DeclSig` enum (`Fn | Record | Variants`) in one
dense table, with three projections beside the enum; consumers ask
(`fn_sig_of`, `record_sig_of`, `variant_sig_of`) and never match.
Slice (b)'s payload tables join the enum instead of adding a
fourth table, and the recorded "declaration sigs become
feature-owned queries" move now has ONE seam to move, not three.

DOCTRINE CHANGED (2026-08-28, the user's call, and it outranks the
old rule): **performance may grow the vocabulary.** "I don't want
to limit our vocab if it means we get optimizations or performance
gains" — so P4 beats minimalism, and the old "the IR is CLOSED"
line is retired. What replaces it is not licence but PROCESS: THE
IR VOCABULARY PROTOCOL (CLAUDE.md holds the working copy).
  1. JUSTIFY — a new control shape, value category, memory
     boundary, or a MACHINE SHAPE the backend can exploit but
     cannot reliably infer. Never when an existing shape says it.
  2. GENERALIZE BEFORE ADDING — the anti-cluster rule. `SwitchStart`
     reuses `ArmEnd` and `RegionEnd`, so an N-arm region and a 2-arm `if`
     became ONE mechanism in all five consumers; adding
     SwitchArm/SwitchEnd would have been three variants and a
     parallel concept. One variant, and the region idea got
     STRONGER instead of duplicated.
  3. PAY THE FIVE CONSUMERS — dst_of, interp's step, memory_ins,
     ir_text's body_lines, llvm's emit_ins — plus a corpus program
     (eval == native) and an IR golden.
  4. THE GUARANTEE that keeps it clean: all five dispatches are
     exhaustive, so a new variant BREAKS every one at compile time.
     The vocabulary cannot grow half-way; an unimplemented variant
     cannot ship. This is why growth is safe here and would not be
     in a codebase with catch-alls.

THE VOCABULARY SEAM RULE (settled 2026-08-28 — the general answer
to "what is the standard, pluggable way to add a vocabulary item?").
This tree has TWO vocabularies and they take DIFFERENT shapes, on
purpose, and the discriminator is one question:

    IS THE ITEM DATA, OR IS IT BEHAVIOR?

DATA -> A REGISTRY ROW. The runtime surface is data (a name, param
kinds, whether the result is owned), so runtime_api.av is ONE table
and adding a runtime fn is ONE row plus one C body — five consumers
(backend declares, rt_arg coerces, memory asks ownership, lowering
validates, interp hosts) all READ the row. Genuinely pluggable:
nothing dispatches, everything queries. That is the shape whenever
an item's whole nature fits in fields.

BEHAVIOR -> THE ENUM PLUS EXHAUSTIVE DISPATCH, and here is the part
worth saying out loud: THE EXHAUSTIVE MATCH *IS* THE REGISTRATION
MECHANISM. You cannot forget to register an instruction, because
the five dispatches refuse to compile until every one of them
answers for it. A registry you can forget to write is weaker than a
compiler that will not build without you. What that seam was
missing was never enforcement — it was DISCOVERABILITY and
DURABILITY, and both now exist: core/ir.av's `Ins` names its five
consumers at the definition site, `avra new ins <Name>` prints the
protocol and the paste-ready arms, and `make vocab` (in the gate)
fails if any of the five grows a `_ ->` that would let the next
variant ship unimplemented.

CONSIDERED AND REFUSED — per-instruction spec files (`language/ins/
switch.av` holding all five behaviors as fn fields, registered in a
table, exactly as LanguageFeature does for features). The mechanism
WOULD work (BuilderRow already proves fn-field tables in bs2), and
the analogy is tempting. It is refused on a measurement: the five
dispatches total 209 LINES for 24 instructions — under 9 lines per
instruction across ALL five passes, most arms one-liners. Spec
files would cost ~24 files x (imports + struct + five fns each
re-destructuring its own payload) — roughly 4-5x MORE code to gain
co-location, and it would scatter algorithms that read as wholes
(the interpreter's step loop reads as a machine; the memory pass
reads as a strategy in seven arms, not twenty-four). The
LanguageFeature contrast is the point: a FEATURE owns ~150 lines of
real per-pass logic, so a directory earns itself; an INSTRUCTION
owns ~9, so a directory would be 90% ceremony. REVISIT TRIGGER: if
instructions grow substantial per-pass logic, or the count passes
~40, the trade flips — re-measure then, do not re-argue.

THE IDIOM BAR REBUILT (2026-08-28, from "I am seeing a LOT of
idioms being violated — why are they not being captured?"). The
user was right and the old ratchet had FOUR holes, each measured:
  1. IT COMPARED COUNTS. Fixing one smell while adding another
     passed silently — a net-zero swap, which is exactly the shape
     of a refactoring commit.
  2. THE BASELINE WAS AN AMNESTY THAT DRIFTED UP: I1 went
     39 -> 41 -> 40 -> 41 -> 43 across four milestones, every bump
     self-licensed in the same commit. ~103 smells sat green.
  3. SIX OF SEVENTEEN IDIOMS HAD NO RULE, and the three NEWEST
     (I15, I16, I17) were all unenforced — backwards, since the
     newest are the least internalized.
  4. THE GREPS WERE LINE-LOCAL: I3 required the loop and its push
     on ONE line (11 hits) while 14 ordinary multi-line loops were
     invisible. It caught the rare shape and reported success.
THE REPLACEMENT (tools/idioms.py) rests on five laws, each closing
one hole and each PROVEN by a live test before being claimed:
  1. the baseline LISTS SITES, so a new one fails at equal count;
  2. NO TOOL PATH ADDS to it — `--accept` only prunes, so the debt
     can only fall and "bump the number" is not an option;
  3. a LICENSE LIVES AT THE SITE with its reason, in the code,
     forever;
  4. the REGISTRY MAY NOT OUTRUN THE RATCHET — every I-code needs a
     matcher or an UNRATCHETED reason, or the tool refuses to run;
  5. NO DEAD RULES — every matcher must catch its own specimen on
     every run. This law caught I18 shipping with a regex that
     could not span a nested call: a rule that cannot fire reports
     success forever, which is the same disease one level up.
THE BURN-DOWN: 117 sites -> ZERO. 33 licensed in place with real
reasons; I11's 21 test/comment hits were rule INACCURACY (its
domain is product messages that drift) and its 8 real hits became
three extractions; I8 and I1 were RETIRED with written reasons —
I8's matcher had a 100% false-positive rate (the ritual and the
only legitimate use are textually identical), and I1's accumulator
DECLARATION was a weak proxy for I3's precise loop shape. Debt is
now zero, so a single new violation fails the gate with nothing to
hide behind.

THE DEEP ROUND'S OWN FIND — I18, THE PLAUSIBLE LIE: a projection
the dispatch GUARANTEES, read with a default, compiles a silently
wrong program. `truth_of(e) ?? false` emits `false` for a node that
was not a bool. FIVE sites said a plausible lie (bool, string,
list, and two in enums/structs); all now refuse through the
extracted `lower_defect(cx, e, ...)` — which was itself the fourth
copy of "record a defect and stand on a register". Ratcheted, with
its specimen. And `int_of` died: the value protocol's only member
with no consumer, because its one reader binds the payload in its
own dispatch — the doctrine now says so instead of implying a
completeness that was never used.

THE ROUND THAT FOLLOWED THE SWITCH (2026-08-28) — four finds, all
in code written the same day. (1) THE VOCABULARY WAS LYING: a
switch's arms were separated by `Else` and closed by `IfEnd`, names
inherited from the two-arm case they no longer described. Renamed
to `ArmEnd`/`RegionEnd` across nine files with zero test churn (the
IR text prints syntax, not instruction names) — and the exhaustive
dispatches found every site. Recorded as I17: rename AT the
generalization, because instruction names are published surface.
(2) THE REGION FACTS JOINED THEIR ENUM: `opens_region`/
`closes_region` moved to core beside `dst_of`, which is where every
fact about the vocabulary already lives — the interpreter was
re-deriving what the owner should answer. (3) A SEAM HAD BEEN
CROSSED: lowering read `typing.decls[...]` directly three times,
reaching past Analysis into a pass's private table while every
other fact goes through a verb; `Analysis.decl_sig(s)` restores it.
(4) TEST HONESTY: five refusal tests asserted `contains` with no
diagnostic COUNT — the shape that once let a cascade hide. All five
pinned, and all five counts held (no cascade was hiding). Also
amended, not rewritten: two ROADMAP records that still named the
old instructions, and the M15 design bullet whose "zero new
instructions" claim was deliberately spent by the switch.

THE M15 TOUCH-POINT AUDIT (the growth ledger, kept honest): the
enums feature dir is 271 lines, its tests 111, its corpus proof 30.
Everything else across the rung — TypeName, the type namespace, the
DeclSig unification, the audit's fixes, the switch and its five
consumers, the wrapper, the vocab gate — was capability and
doctrine, paid once. Slice (b) (payloads, pattern binds) should
show the steady-state shape: the feature dir plus a Binding
variant, and little else.

SWITCH LANDED (the first variant under the protocol): a `match`
is now ONE N-arm region over the tag, and the backend emits a real
`switch i64 %tag, label %default [...]` — a jump table, O(1),
instead of walking up to N-1 comparisons. Owning the C paid again:
`avra_llvm_build_switch`/`avra_llvm_add_case` were simply ADDED to
backend/llvm_wrapper.c (and the Makefile now installs our wrapper
where bs2 links from — recorded rent: `make test` cannot catch
that class, since the interpreter never links LLVM). `avra ir`
prints `switch r2 over [0, 1] { … } arm { … } -> r6`.

SUPERSEDED — THE MATCH CHAIN'S SHAPE (the pending decision this
replaces):
a match lowers to nested compare-regions, so N variants cost up to
N-1 comparisons at runtime; LLVM offers `switch` (a jump table).
P4 says this matters eventually, and P17 says not to grow the IR
for it lightly. The three options, in the order I'd rank them:
(a) BACKEND RECOGNITION — llvm.av notices the compare-chain shape
and emits a switch; the IR stays closed, the interpreter is
untouched, and nothing above the backend changes. (b) A `Switch`
Ins variant — a CORE event under the closed-vocabulary rule, paid
once, honest in the IR text, but every consumer (interp, memory,
ir_text, backend) grows an arm and features gain a second way to
say "choose". (c) LEAVE IT — correct today, and small enums cost
nothing measurable. Firing condition: the first enum wide enough to
measure, or a profile showing match dispatch in the hot path —
never before `make bench` can show the difference.

THE PROP CHAIN NOW HAS THREE OWNERS (type name, struct field,
length) asked in order inside expr_spine — the honest cost of one
syntax serving three meanings. At self-host this collapses into a
single member-resolution query; recorded as that trigger.
V1 restrictions with triggers: qualified construction only
(`Color.red` — dot shorthand waits on expected-type threading);
unit variants only (payloads are slice b); no `_` arm ever (the
correctness guarantee); an enum answer has no text projection
(derived show).

## The breather — architecture heads-up (decided 2026-08-26)

Before the heavyweight rungs, six structural decisions, each made
so the heavyweights land into ground built for them:

1. OWN THE RUNTIME — LANDED: `runtime/avra_runtime.c` in-tree,
   compiled by our Makefile — the bootstrap's runtime.o copy dies.
   The runtime IS language semantics (join is what interpolation
   MEANS); it cannot live in another repo. First-principles v1:
   an ownership REGISTRY (ptr -> refcount) instead of headers or
   trust — release/retain of unowned pointers (statics) are
   no-ops by construction, owned strings actually reclaim, and
   every fn is a documented CONTRACT. Native list printing came
   with it — the F0901 answer-refusal died, corpus/show.av prints
   a list answer natively, and the trap wording (out of bounds)
   matches the evaluator's refusal exactly, pinned. The runtimes
   are SEPARATE on purpose: build/runtime.o (bootstrap copy) is
   what bs2-compiled binaries link — the COMPILER's runtime, dead
   at self-host; build/avra_runtime.o is what avra-built programs
   link — the LANGUAGE's.

   THE OWNERSHIP DOCTRINE (the "move everything over?" answer):
   there are two runtimes because there are two LANGUAGES in play.
   Everything AVRA is ours already: the language runtime
   (runtime/), and now the LLVM wrapper too
   (backend/llvm_wrapper.c — adopted whole, compiled by our
   Makefile, extended HERE from now on; it serves the backend
   through self-host and beyond). What remains borrowed is bs2's
   own flesh — the bs2 binary and ITS runtime.o for bs2-compiled
   binaries — pure toolchain, like depending on clang, deleted
   WHOLESALE at self-host rather than migrated piecemeal.
   Reimplementing bs2's ABI now would be scaffolding work thrown
   away with the scaffold.

   THE RUNTIME REGISTRY (landed with it): the native seam is ONE
   table — runtime_api.av's RtSig rows (name, ret, params,
   owns_result) — with FOUR consumers: the backend DECLARES from
   it, COERCES slot arguments by it (slot_param died into data),
   the memory pass derives OWNERSHIP from it (a static answer like
   bool_text never earns a release — provenance refining type),
   and lowering REFUSES an unknown callee loudly instead of
   crashing the backend. A new runtime fn is one row plus its C
   body — nothing else, checked at every link in the chain.
2. ONE BINDING CURRENCY — LANDED: Resolution's parallel tables
   became one `Binding` enum fact (`Param(i) | Def(stmt)`) with
   one projection; typing's target_type, the call signature
   lookup, and lower's def_reg each dispatch ONCE, and rung 8's
   pattern binds extend the ENUM. The arc also taught a lesson
   the doctrine already knew: the let_name/stmt_value projections
   returned to program.av as DIRECT matches (projections are data
   about variants, zero dispatch cost; the trait carries
   behavior) — and the first draft's `_ ->` catch-all silently
   dropped For's counter arm, exactly what the no-catch-all
   dispatch rule exists to prevent. Both registries are now
   exhaustive; the trait shrank to three methods.
3. DISPATCH BUILT ONCE — LANDED: the sixteen boxed impls build
   once per parse into a Dispatch value on ParsedProgram (dyn
   struct fields hold, boxed under typed lets); semantics_of and
   stmt_semantics_of only SELECT. The allocate-per-node-visit
   shape is gone before self-host could inherit it.
4. PARSE-ERROR QUALITY ARC (named, scheduled): parse diagnostics
   are the weakest in the system while pass diagnostics are the
   strongest — P1 says close the gap: expected-set wording,
   contextual help, an @expect coverage audit per feature, goldens
   for the common stumbles.
5. THE INCREMENTALITY CONTRACT (recorded, not built): Era IV keys
   cached facts by fingerprint PLUS ENVIRONMENT (resolution is
   context-dependent). Until then: passes stay pure, facts stay
   dense-by-id, and no pass may bake in cross-declaration order
   dependence beyond what ids already carry. Heavyweight fact
   tables (mono instances, vtables, captures) are designed
   against this contract.
6. THE DIVERGENCE REGISTRY (recorded): every eval-vs-native
   divergence (div-by-zero refuse/trap, OOB refuse/trap) is a
   CHOSEN behavior pinned by paired tests, never an accident.
   And rung 15 will stress the one-SourceFile assumption threaded
   through Analysis — recorded trigger.

The second ideas round (same day) added three, each a PRINCIPLE
cashing out:
7. `avra check --json` (P11): machine-readability is the
   substrate — the human renderer is one projection of Diag;
   agents get the structured one. Cheap: Diag is already
   structured (kinds, locs, suggestions, edits).
8. `avra trace <file> <line>` (P7/P10): visible magic — dump what
   every pass KNOWS about a node (its type, its binding, its
   register, its releases). The fact tables all exist; this is a
   projection, and it becomes the debugging front door.
9. THE QUALITY HARNESS — bench and fuzz LANDED: `make bench`
   prints the measured curve (first reading, 2026-08-27: suite
   ~2.2s, native corpus of 16 ~21.6s — bs2-era numbers, now
   watchable); `make fuzz` runs 112 deterministic corpus mutants
   through `avra check` — first pass: all diagnosed, none
   crashed. Still open here: the render/parse fixed point as a
   standing property test. F-codes are API: never renumbered,
   like fingerprint tags — a reused code or kind REFUSES assembly
   (coherence's law, both arms pinned by tests). And
   `make scaffold-check` guards the scaffolder: the templates
   rotted silently when the eval layer died (they still wrote
   eval.av/EvalCx), so the harness now scaffolds a throwaway
   feature, compiles the tree with it, and removes it.

The consolidation round closing the breather (2026-08-27):
`Analysis.run()` now interprets the POST-MEMORY stream — interp
and backend consume the identical instruction list, Retain and
Release included (interp no-ops them), so eval == native shares
every bracket, not just the semantics. `under_overlay` (I15's
first instance) collapsed resolve's three overlay push/pops;
interp's three forward bracket scans became ONE `ahead` scanner
taking open/close/target predicates (`loop_header` stays: the
one backward scan); values.av merged into contract.av (a
feature-root file under 40 lines was rent, not a concept).
ACCEPTED RESIDUAL: interp's `rt_dispatch` is the registry's
third consumer site by NAME (backend declares by row, memory
asks `rt_owns`, interp hosts by match) — guarded twice: Lower
refuses unknown callees at build, and the `_ ->` arm is a defect
refusal, never a silent miss. It merges into the registry only
when rows grow a hosted-fn field — blocked on fn-typed struct
fields surviving mono (upstream ledger).

THE UPSTREAM LEDGER: we may fix bs2 itself (license granted).
Decisions in THIS tree shaped by bs2 defects, each with its
post-fix simplification: the dyn-in-match-arm mis-dispatch
(typed-lets-first maps — shape stays healthy regardless); #1377
method-on-captured-local ICE (free-fn exception in the style
doctrine — dies with the fix); fn-typed args through generics
corrupt (fn_parts detours); the executor's nullable-generic mono
corruption (fb_diags bool-flag reconstruction — the ugliest
workaround standing); `?.field`-after-`?` silent corruption (the
helper-split rule); trait default-method ICE (mandatory-methods
doctrine). Fixing is its own arc per defect, prioritized by how
much of our tree each unlocks; the executor's fb_diags and #1377
lead.

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
- `dst_of` lives beside Ins, `op_symbol`/`all_binops` beside BinOp:
  consumers query the owner's projection, never keep their own
  lists. IR growth is rare by doctrine; its touch points are the
  enum, its accessor, the renderer's arm, the backend's arm.

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

THE CAPABILITY INVERSION (2026-08-26): M10 shipped its rules as
driver-side closures — `check_mut` in typing.av, `emit_loop` in
lower.av, `resolve_assign` in resolve.av — and the statement
contexts became switchboards: every statement feature would have
edited contract.av plus four drivers, forever. Inverted the same
day: contexts now carry STATE verbs only (lookup, record_assign,
emit, mint, slot_of, bind_slot; the typing cx nests the whole
expression TypeCx), and every rule body lives in its feature's
directory by concern. Fallout, all wins: the driver's `is .MutLet`
match died (a slot bound through `bind_slot` is a memory cell —
mechanism, not feature knowledge), which also caught a LATENT
eval/native divergence (a program ending in a mut declaration
printed the cell POINTER natively — corpus/mut.av pins it);
`binds`/`value_of` joined StmtSemantics so the spine projections
stopped growing in program.av; and the hand-kept keyword list died
— keywords derive from the assembled grammar's identifier-shaped
literals, so a feature's gram fragment IS its keyword claim. The
steady-state statement feature is now: its directory, the node
variant + fingerprint arm (rent until @derive), one map line, one
stanza line, the corpus pair. Range `for` is the proof: it must
touch nothing else.

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
- THE BIND-FRESH TRIO, from spec Axis 10 (already committed, lands
  at rung 9): `let v? = e else { diverge }`, `if let v? = e`, and
  effectively-final narrowing sugar. Wanted by expr_spine/eval.av's
  index_value — three contract clauses cost eleven lines, two `!`,
  and two rebinds today; the trio prices each clause at ONE line,
  born unwrapped. Every guard-then-use rule body is a wanting site.
- PARTIAL READS RETURN ABSENCE: `xs.get(i) -> T?` beside the
  panicking `xs[i]` (spec: indexing panics, structured and
  task-contained). A bounds check then isn't arithmetic, it's
  absence — and absence composes with `??`, whose fallback may BE
  the failure channel (`es.get(at) ?? failed(...)` — guard and
  fallback were never different things, P6). Wanted by index_value;
  rides the method core (method-with-args).
- `?.` through calls, not just fields — `answers_to` wanted
  `token_name()` projected straight into a compare; today a bound
  let (and the direct compare is #1376).
- Comprehension destructuring: `[fix(i, m) for (i, m) in
  xs.enumerate()]` — wanted by attach, first_defects, joined, and
  both zip builders (fns and structs zip parallel token lists by
  index loop).
- Comprehension BINDINGS (or `filter_map`): the filter and the
  element cannot share a computed value — `[Def { name: n, ... }
  for s in stmts let n = store.let_name(s) if n != null]` doesn't
  exist, so defs_of projects `let_name` twice. Wanted by every
  filter-map whose predicate IS the projection.
- TOTAL MAPS over enum keys: `table<Feature, dyn NodeSemantics>`
  whose literal the compiler checks EXHAUSTIVE — lookup answers
  `V`, not `V?`, and a new key variant breaks every literal at
  compile time. Wanted by Dispatch (program.av): today the struct
  of dyn fields plus `semantics_of`'s match IS a hand-rolled total
  map — the struct holds totality, the match holds the key mapping;
  the sugar would let one table hold both without surrendering the
  compile-time break.
- SPREAD in list literals: `[head, ..tail]` / `[..a, ..b, last]` —
  the concat/flatten ceremony that remains AFTER comprehensions.
  Wanted by every mixed fingerprint arm (`fp(14,
  concat(self.stmt_fps(stmts), [self.expr_fingerprint(value)]))`
  wants `fp(14, [..self.stmt_fps(stmts),
  self.expr_fingerprint(value)])`) and the When/FnDecl flattens.
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
  sets, and every StmtSemantics `binds`/`value_of` body — the same
  one-variant projection match, per impl): mechanical, derivable,
  erased by `@derive` at self-host.
- String char iteration: `for c in s.codes()` (or chars) — every
  char-wise walk hand-rolls `mut i` + `code_at` + `substring`
  today; wanted by the lexer's whole scan loop, render's `quoted`,
  and line_end. Index arithmetic is the licensed loop exception
  ONLY because the language leaves no alternative.
- String repeat: `s.repeat(n)` — the tree holds TWO hand-rolled
  copies of the concept (diagnostics/render.av `repeated`,
  ir_text.av `line`'s indent loop) that cannot merge because the
  primitive is missing.
- Module-level constants that cross imports: `reserved()`,
  `engine_codes()`, and `pass_codes()` are DATA wearing fn clothes
  — re-allocated per call, scanned per lookup — because a
  module-level `let` does not resolve through imports (subset).
  Data should get to be data.
- `it` inside `is`-expressions: `ins.filter(it is .Release)` —
  wanted by every IR test; an explicit lambda today.
- Or-patterns that BIND when the payloads agree in type:
  `.Lit(text) or .Named(text) -> text` — wanted by token_name.
- In-place mutation through self: `self.diagnostics.push(d)` — the
  `mut alias` two-step in every speak/give/record is ceremony the
  mutability rules (Axis 11) should erase. Counted 2026-08-26: 38
  sites in product code, and every new state struct pays it again —
  the only backlog cost that still GROWS.
- Fn-typed arguments that carry type evidence through generics — the
  subset ban (F1002 + mono corruption) forces EIGHT copies of one
  idea: grammar/builders.av's five `as_*` walkers and Builder's
  three repeated-capture methods are each `for x in list {
  out.push(want(kind_of(x), "...")?) }` with only the extractor
  differing. One generic `as_each(v, of, what)` is the shape the
  code wants to be.
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
  return as defaults over `describe()` — and every `nothing()` /
  bare-`null` pass method in the StmtSemantics impls collapses into
  defaults, so an impl states only what it DOES.
- The #1377 ICE class dies (a method call on a closure-captured
  local in a loop with an early return): our codegen must not have
  it, and the pass visitors then become methods — the vocabulary
  rule applied to the hottest code in the tree, currently barred.
- `grammar { }` blocks replace raw-string grams
- Bare component instantiation (registry spans files)
- Query engine (L6 red-green memoization) wraps the pure passes
- A real feature-extensible language lexer

Update this file whenever a slice lands or the plan changes — the
roadmap lives HERE, not in conversation.
