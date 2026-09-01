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
    8.  [x] ▲ enums & match — slices (a)+(b) LANDED: declarations,
        unit and payload variants, pattern binds, total match (the
        match-chain SHAPE decision stays recorded, not blocking)
    8.5 [x] the TYPE SURFACE — annotations are a type EXPRESSION,
        not a NAME (found blocking rung 9); slice (a) landed `T?`,
        `null`, `??`, widening and the join
    9.  [x] ▲ nullability — COMPLETE 2026-08-31: `T?`, `null`
        arms, `! ?? ?. ?` (the representation decision below:
        niche + pair, never-allocates law ON); `if let v? = e`;
        effectively-final narrowing; `?` propagation (rides
        FnExit); and `let v? = e else { }` (slice N4 — the
        divergence law arrived with the `diverges` registry).
        `while let` stays a recorded trigger (wants loops polish)
    10. [x] Result & `?` — the ERROR SPINE COMPLETE 2026-08-31
        (R0 slots + R1 spine + R2 catch: Type.Res, fail, auto-Ok,
        `?`, match-for-free, divergence-aware blocks, catch at
        four granularities). The R4 triggers (unions, topology,
        handlers, `? context`) wait on their enabling rungs
    11. [x] ▲ generics — COMPLETE 2026-08-31: G1 generic fns
        (monomorphized, two red-team rounds), G2 generic type
        declarations (Type.App; the Res fold re-measured and
        REFUSED), G3 List<T> real (elements widened, `[]`
        adopted, the element walk). The METHOD vocabulary rides
        rung 13's closures
    11.5 [x] ▲ THE OWNERSHIP MILESTONE — CORE LANDED 2026-09-01
        (O1 registry kinds + O2 managed aggregates + O3 strings in
        slots + the MUT-CELL PROTOCOL). Result<T, string> works —
        the self-host critical path: fail carries an interpolated
        owned message through `?` and catch. What today leaked by
        design now releases; 47 corpus pairs prove it thrice over
        (the evaluator has no memory model — agreement IS the
        proof). The design record below carries the slice detail
        and the two use-after-frees the differential caught. O4
        remains recorded: nullable slots in aggregates, errdefer,
        the Result register TRIPLE (P4's gate).
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

## Milestone 15 slice (b) — payloads and pattern binds (the design)

The rung that makes enums carry data, and the FIRST expression-level
binding in the language. Two steps, each gate-able:

(b1) PAYLOADS — a variant carries ONE named field in v1
  (`circle(radius: int)`; multi-field rides the same shape later,
  and the spec's positional wrappers wait for generics).
  - REPR: the slot array already tags at 0; the payload joins at
    slot 1. Still no new instructions.
  - SURFACE: construction is `Shape.circle(5)` through its OWN
    primary branch anchored by the `(` — three required items
    before it, so the branch never commits and `p.x` still falls
    through to the ladder (first.av's law, the same reasoning that
    made the struct literal safe).
  - NODES: `EnumDecl(name, variants: List<Param>)` (a Param with an
    empty `ty` IS a unit variant — one shape for both) and
    `VariantLit(tname, variant, args)`.
  - FACTS: EnumSig gains `payloads: List<TypeId?>`, null for unit.
  - LAWS: arity is exact — a unit variant refuses arguments, a
    payload variant refuses bare `Shape.circle` (the Prop path
    names the remedy), and the argument's type must match.

(b1) LANDED (2026-08-29): 340/340; twenty-for-twenty corpus.
  Construction with an argument is its own branch and never
  commits, so `p.x` still reaches the ladder untouched. The ARITY
  law lives on BOTH construction paths — a unit variant refuses an
  argument (F2015) and a carrying variant refuses being named bare
  (it would have built a value missing its payload, silently: found
  by asking what the Prop path does with a payload variant).
  THE BUILDER FINDING: optional captures in a repetition do NOT
  align — `enum E { a b(x: int) }` accumulates one payload and index
  0 would hand it to `a`. Tokens carry SPANS, so the builder aligns
  by position: a payload belongs to the variant whose name precedes
  it and whose successor follows it. Recorded because every future
  optional-in-repetition capture hits this.
  And the bar caught the rung's OWN new code within minutes — a
  refusal test missing its count, and kids() becoming a 2-arm
  registry — which is the whole point of it.

THE EQUALITY DIVERGENCE (red team, second pass — the worst class
of finding available, and it was PRE-EXISTING since M14): `==` typed
clean on two aggregates, and then the engines DISAGREED. The
interpreter refused with an internal defect ("a non-int reached
arithmetic"); the backend quietly answered `false` — comparing
ADDRESSES, so two identical records were "different". A silently
wrong native answer AND a divergence, reachable by writing the most
obvious thing a person writes about two values.
The law now names what `==` can compare: values the runtime tests BY
VALUE (int, bool, string). Everything holding a pointer refuses, and
the help is shape-specific — a list says compare an element, a
record says compare a field, an enum says MATCH on it, because a
match is how an enum is asked what it is. Found by attacking a
feature that turned out not to own the bug, which is the argument
for red-teaming the CROSSINGS and not just the feature.

RED-TEAMED b1 (the new skill's first run — 58 programs, every one
enumerated from the feature's own surface). b1 itself held: no wrong
answer, no crash, no engine divergence, no internal defect. What the
attack surfaced was THREE pre-existing defects it happened to walk
past, which is the argument for running it on every commit:
  1. A TYPE DECLARED IN A BLOCK was silently ignored, and the later
     USE was blamed ("`E` is not defined") for a mistake made at the
     declaration. Nested fns already refused properly; types now do
     too (F3007), through a `nested_decl` law the third copy earned.
  2. MULTI-LINE `when` DID NOT PARSE — `match` accepted
     newline-separated arms and `when` demanded commas, the same
     construct written two ways. `when` now takes both.
  3. A BLOCK IS NOT AN EXPRESSION: `let v = { let n = 2\n n + 1 }`
     does not parse, because `primary` never references `block` —
     only `if` and `fn` bodies do. RECORDED, not fixed: making
     blocks general expressions is a surface decision with its own
     parse consequences, and it wants its own rung.
SETTLED while attacking: a variant name may be a keyword or a
reserved word (`enum E { let(int) owned }` works in both engines) —
variant names are NAMESPACED under their enum, so the law that keeps
free identifiers clear of future keywords does not reach them.

THE ROUND ON b1 (asked for immediately, and it earned its keep —
five findings in code an hour old, two of them real defects):
  1. THE PAYLOAD SURFACE WAS A MODELLING HACK. `circle(radius: int)`
     forced a field name that the node then DISCARDED — so two enums
     differing only in field name fingerprinted IDENTICALLY, and
     content identity is supposed to be the source's content. The
     spec's own style rule settles it: a single-value wrapper is
     POSITIONAL (`circle(int)`), which loses nothing and is what
     `Ok(T)`/`Some(T)` want. Named fields arrive with multi-field
     variants, which need a real field list anyway.
  2. MANAGED PAYLOADS WERE ACCEPTED. A record's field must be scalar
     until ownership analysis; an enum's payload is the same kind of
     slot in the same kind of array, and nothing refused
     `s(string)`. Latent today (b1 cannot read a payload) and a
     use-after-free the moment b2 can. Both now go through ONE
     declared-slot law, each site keeping its kind and words.
  3. `b.span_end()` answered 0 for an absent span — a sentinel that
     would have silently mis-aligned every payload. It answers
     `int?` now and the caller refuses.
  4. `E.a()` said "expected BREAK". The grammar now accepts the
     empty argument so TYPING can say "`E.a` carries a `int`, given
     nothing" — the house rule that a generous parse buys a precise
     message.
  5. `zip_defect` said "field names" while match arms used it.
  bs2 trap found: `given` is RESERVED as a local (the spec DSL's
  words are lexed in ordinary code) — recorded in CLAUDE.md.

(b2) PATTERN BINDS — LANDED 2026-08-29.
  `match s { .circle(r) -> r * 2, .point -> 0 }`.
  - `Binding` grew the variant its arc PROMISED: the first bind
    that is not a statement. Its identity is the ARM'S VALUE, not
    (match, index) — so both later passes key their fact by an
    ExprId like every other node fact, and nested matches need no
    special care at all.
  - A match is now CONTROL-OWNING (the Block shape): `kids` hides
    the arm values and the driver walks each under `arm_scope`,
    the FIRST scope an expression opens.
  - TYPING: the arm's OWNER speaks the bind's type into a table
    before the arm is walked (`cx.bind_type`) — the pass never
    matches a feature's node to learn it. The first draft DID,
    and that was the doctrine violation this round removed.
  - LOWERING: the bind reads slot 1 of the subject INSIDE the arm's
    region — pinned by an IR golden, so an untaken arm provably
    never loads. A called subject lowers ONCE, also pinned.
  - THE RED TEAM'S HAUL (three real defects, all pre-existing or
    new, now tests):
    1. A fn PARAM outranked every inner scope. `resolve_name`
       consulted params BEFORE the overlays, so `fn f(n: int)` made
       `let n = 7` inside an if-branch a no-op — a SILENT wrong
       answer shipped since blocks landed, found by attacking arm
       binds. The chain is now ONE ordered ladder (`value_binding`)
       whose order IS the shadowing law: overlays, params, program
       scope, type-as-value.
    2. An unknown variant with a bind earned TWO refusals — the
       bind law now stays silent where `arm_checks` already spoke.
    3. `semantics_of` matched `.Match(_, _, _)` after Match grew a
       fourth payload, and a test helper `.Pattern(_, _)` after
       Pattern shrank to one. bs2 accepts BOTH silently: it does
       not check pattern arity. I25 now does (see DOGFOODING).
  - Still refused, by design: a payload holds a SCALAR (strings and
    aggregates wait for ownership analysis), and an arm's value
    cannot be a block — blocks are not expressions anywhere yet
    (that rung is already recorded).
  - Sugar the compiler WANTED here: an arm's variant name has no
    span of its own, so `.zz(m)`'s refusal points at the arm's
    VALUE. Arms are not nodes, and node facts key by typed id —
    the fix is an arm node, which waits until a second construct
    needs one (trigger: `match` guards, or `when` arms wanting
    spans).

## Rung 8.5 — THE TYPE SURFACE (found 2026-08-29, designed)

Rung 9 (nullability) could not start: `T?` is the language's first
type CONSTRUCTOR, and an annotation cannot hold one. Types are a
bare NAME token everywhere they are spelled — `Param.ty: string`.
What that costs TODAY, before nullability is even considered:
  - `fn f(xs: List<int>)` DOES NOT PARSE. A list cannot cross a fn
    boundary. Rung 5 shipped lists that only ever lived local, so
    nobody hit it.
  - `let x: int = 1` does not parse either: a `let` takes no
    annotation at all, while the spec writes `let x: int? = null`.
  - Struct fields and enum payloads take a name, so neither can
    ever hold a list, a nullable, or (rung 11) a generic.
The measurement that settles the shape: `Param.ty` is read in FOUR
places, ALL in typing.av. The annotation seam is already central;
only the PRODUCERS (three grams) pay.

THE SHAPE — annotations become a small type EXPRESSION, carried as
DATA, not as a third node namespace:

    export type TypeRef = { name: string, args: List<TypeRef>,
                            optional: bool, span: Span }

  - Why data and not nodes: no pass WALKS an annotation. Resolve
    does not visit it, lowering never sees it — typing reads it and
    interns a TypeId. Ids exist to key side tables for passes that
    walk; a third namespace (Stmt, Expr, TypeExpr) would buy ids
    nothing consumes. The span rides the ref itself because the ref
    is not a node — this is the ONE place that is honest, and it
    buys `int?` diagnostics that point AT the annotation instead of
    at the statement. Probed: bs2 compiles a recursive struct
    (a struct holding `List<Self>`), so the shape is expressible.
  - REVERSIBLE by design: if generics (rung 11) turn out to want a
    walk over type expressions, TypeRef promotes to a node kind and
    the four reads move. Nothing else in the tree knows.
  - A `types` FEATURE owns the `type` rule and its builder — the
    gram-builder unity law. Other features REFERENCE the rule, the
    way several already reference `expression`; the partial test
    assemblies that parse annotations must include it, which is the
    same dangling-name discipline the tree already keeps.

SLICE (a) LANDED 2026-08-29 — the surface, `T?`, `null`, `??`,
widening, and the join. What the build taught, beyond the design:
  - THE JOIN was NOT in the design and the corpus demanded it: the
    natural way to make a nullable is `if c { v } else { null }`,
    and branches that disagree had no join. `joined_type` now lives
    beside the assignment law — equal types join to themselves, a
    value beside an ABSENCE joins to the nullable covering both, and
    an already-nullable branch absorbs the absence without lifting
    twice. Two laws, one home.
  - WIDENING needed no expected-type threading: the assignment law
    RECORDS the lift into `Typing.widens`, and `lower_subtree` — the
    one place every expression passes through — wraps it. One table,
    one wrap point.
  - `??`'s PRECEDENCE was wrong first: placed above conjunction,
    `x ?? 0 == 0` grouped as `x ?? (0 == 0)` and refused. It binds
    TIGHTER than comparison and looser than arithmetic, so the
    comparison asks about the ANSWER. Found by red-teaming.
  - A NEW LOWERING LAW, found the hard way: registers must be MINTED
    IN EMISSION ORDER or the backend indexes past its value table
    (`index 6 out of bounds`) while the interpreter answers correctly
    — an engine divergence with no diagnostic. Recorded in
    DOGFOODING; the payload load in `??` had them reversed.
  - A managed nullable (`string?`, `P?`) refuses through the SAME
    declared-slot law a field and a payload obey. `T?` IS a slot
    array, so it waits on ownership analysis with everything else.
  - The tagged slot array is now ONE definition (`tagged_value`): an
    enum's variant, a nullable's absence, and a widened value are
    the same shape, which is why `match` and `??` read them alike.

THE RED TEAM ON SLICE (a) — 118 programs across the eight attack
classes; three defects, TWO of them older than this rung:
  1. THE SLOT LAW SPOKE OVER THE NAME LAW. `x: Foo` in a struct
     field said "struct fields hold scalars for now" when the real
     mistake was that `Foo` names no type — and the enum payload
     and the new nullable inherited it, three features misreporting
     one mistake. The name law now speaks FIRST and the slot law
     absorbs; one fix, three features, found by attacking `Foo?`.
  2. A KEYWORD AS A CALLEE offered an impossible remedy: `if()`
     said "no `fn if` is defined" while the naming law forbids ever
     declaring one. `resolve_call` now runs the SAME `refused_name`
     law `let` and params run — general to every keyword, found
     by attacking `null()`.
  3. THE JOIN LIVED IN ONE FEATURE. `if` joined a value with an
     absence; `when` and `match` did not, so the natural
     `match e { .a -> 1, .b -> null }` refused. The join is now
     PURE (`join_of`) with `accepts` doing every recording, and the
     SHARED arms law joins across all arms — one rule, and any
     branching construct added later joins by asking it.
  CLEAN under attack: all 18 slot×type positions of `??`; every
  malformed-surface mutation (delete/duplicate/swap/keyword at each
  token) produced a diagnostic, never a crash; 15 crossings with
  other features and 4 name attacks agreed eval == native; 1000
  nullables allocated in a loop; and the diagnostic COUNT was exact
  everywhere (the one 2-count program contained two real mistakes).

THE SECOND RED-TEAM ROUND (deeper, past the mechanical classes) —
three more defects, all of them OLDER than this rung:
  4. A BUILT-IN TYPE NAME COULD BE REDECLARED, and the two
     resolution paths then DISAGREED: `type int = { x: bool }` was
     accepted, `fn f(v: int)` still meant the builtin (so the user's
     own type was invisible and the error blamed the property),
     while `int { x: true }` resolved to the DECLARATION and ran
     clean. One name, two meanings, no diagnostic. Refused at the
     declaration now (F3008), where the keyword law already sat.
  5. THE SLOT LAW SPOKE OVER THE NAME LAW (round one, restated
     because it was the same shape): the name law speaks first.
  6. A KEYWORD AS A CALLEE offered an impossible remedy (round one).
  WHAT THE DEEP PASS PROVED, beyond the mechanical classes:
  - CONTENT IDENTITY holds for the new surface: `int` and `int?`
    fingerprint differently, an ABSENT annotation differs from every
    written one, a field's written type is part of its record's
    identity, and two spellings of one type still agree — spans
    never count. Five attacks, now tests in core/nodes.
  - THE TWO FACT TABLES COEXIST: a pattern bind and a widening key
    the same ExprId, and the IR shows both landing INSIDE the arm —
    payload load, then wrap, registers sequential.
  - THE WRAP IS NEVER EAGER: an untaken branch allocates nothing;
    the IR golden shows the lift inside the branch that answers.
  - `??` AS A NEW TOKEN munches nothing it should not — tight
    against `)`, `{`, `,` and with no spaces at all — and a `??`
    split across lines refuses exactly as `+` does.
  - Every branching construct now joins, and every ALL-absent shape
    (`if`, `when`, `match`) answers absent rather than refusing.

TEST ORGANIZATION (the same round): the enums adversarial suite had
grown to 406 lines — the largest file in the tree — so the PATTERN
BIND attacks moved to `enums_binds_adversarial_test.av`: the closed
SET and the bind are two surfaces, each with its own attack list.
The TYPE SURFACE got its own suite too (`type_expr_adversarial`),
taking the spelling attacks that had been living in nullable's,
which now holds only what a nullable MEANS.
RECORDED GAP: 14 of 17 features still have no adversarial suite —
the red team began at enums, and everything older than it was never
attacked. Trigger: when a rung touches one of those features, it
earns its suite then, rather than a sweep nobody would review.

THE TREE-WIDE ROUND (after the arc was called near-dry, the hunt
widened past it — and the tree, not the arc, is where the weight
was):
  - THE ABSORBING ANSWER had THREE spellings and 35 sites. Typing's
    most-typed phrase was `cx.intern(Type.Error)`, which says how
    rather than what. `error_type` is now a VALUE on the context,
    interned once, and the absorb law reads at a glance:
    `if sh is .Error { return cx.error_type }` — Error in, Error
    out. Extracting the absorb one-liner itself was REFUSED: every
    shared form was longer than the line it replaced, which is the
    over-abstraction smell.
  - THREE SHARED PHRASES were split across two features each —
    `fields_are`, `build_a_record`, `variant_defect` — the same
    species as `variants_are`, whose home they now share. A help
    that two features give must be one sentence.
  - 26 COPIES of two test helpers. `shown` was byte-identical in 21
    files and `refusals` in 5, because test files are separate
    compilation units. `@std.avrac.testing` now holds both; the
    ratchet then caught FOUR unused imports the sweep had orphaned,
    which is the gate doing what it is for.
  - A NON-FINDING, recorded so nobody re-hunts it: `.length == 0`
    looked like six missing `is_empty()` calls. It is a bs2 GAP —
    `is_empty` is a list method and ICEs on a string — so
    `s.length == 0` IS the idiomatic emptiness test for text. The
    one list-typed site is inside vendored spec_test.
  - I11 catches duplicate strings within ONE file only; the
    cross-FILE sweep that found the three shared phrases was
    hand-run. Trigger: ratchet it when a fourth cross-file phrase
    appears — a rule that must exempt every legitimate
    summary/message/test echo would flag ~45 honest sites today.

THE READ-IT-WHOLE ROUND. The previous round called the well dry on
the strength of greps; the skill says that claim is earned only by
READING. Three files read end to end (resolve, contract, interp)
produced five findings, two of them defects:
  - A KEYWORD USED AS A VALUE still said "`while` is not defined".
    The earlier fix reached CALLEES only, and a plain name use takes
    a different path — `resolve_name` was checking `reserved()`
    directly instead of the one `refused_name` law. Every path now
    runs the same law, and `reserved()` is reachable only through it.
  - THE SCOPE SCAN read every overlay even after finding its answer,
    folding a `mut found` flag under a LICENSED I4 exemption it did
    not need. An early `return` inside a `while` was probed first
    (it works; the #1377 ICE needs a closure-captured receiver), so
    the scan now stops at the first hit — which IS the shadowing
    rule: the nearest scope wins and the outer ones are never asked.
  - I7 WAS BLIND TO DOTTED RECEIVERS, hiding six product sites
    including the interpreter's per-instruction register read.
    `.last()!` was proved to ALIAS by converting them and watching
    all 21 corpus programs still agree eval == native — recorded,
    since a copying `.last()` would have made every register write
    vanish.
  - CONTRACT.AV HELD TWO CONCERNS: what a feature DOES at each pass,
    and what its VALUES are. The tagged slot array moved to
    values.av (394 -> 359 + 46), where the next value CATEGORY will
    join it; the module map, which still named four of eight shared
    phrases, now tells the truth.
  - The interpreter spelled "in a clean program" by hand four times
    while `defect_val` was already building it. One `defect` verb.

THE WIDE-AND-DEEP ROUND. Reading kept paying, and the RULES turned
out to be the richest seam:
  - THE LARGEST UNREVIEWED FILE (executor.av, 492 lines) wrote its
    non-hit result FIVE times — three named constructors differing
    only in a status constant, plus two inline copies holding a
    status in hand. One `ended` shape behind the three verbs; the
    two inline sites now call it directly. Its pass-through branch
    also indexed `vals[0]` where an empty branch would trap, and now
    refuses through the builder's own channel.
  - FOUR MATCHER BLIND SPOTS, and the fourth changed the tooling.
    I3 could not see a ONE-LINE push loop and had hidden 13 sites
    (its own docstring admitted replacing a line-grep); I4 could not
    see `Map<a, b>?`. The lesson outgrew the rules: SPECIMENS now
    holds every SPELLING a rule claims, and the self-test refuses
    the tool when any is missed. Proved by reintroducing I3's blind
    spot and watching it name the two spellings lost.
  - THE SCOPE-CLOSING TRIO in memory.av — pop, then release what the
    scope still owns — was written three times. One
    `closing_releases`, and the sites read as `out = concat(...)`.
  - TWO I3 SITES WOULD HAVE BROKEN IF CONVERTED: `tys` and `top`
    ALIAS a list inside another structure, so `concat` would rebind
    the local and silently drop every write. LICENSED at the code
    with that reason — and the aliasing itself is now a recorded
    bs2 fact, correcting a note that claimed in-place-mutating
    helpers are inexpressible. They are expressible; we decline
    them, because mutation invisible at the call site is worse than
    an explicit `concat`.

THE SLICES (each vertical, each gated):
  (a) THE SURFACE + `T?` + `null` + `??` — the type constructor, the
      value that inhabits it, and one consumer, so the slice is
      observable end to end: `let x: int? = null` then `x ?? 0`
      runs and prints. `Type.Opt(inner)` joins the type vocabulary
      (nine exhaustive Type consumers break until each answers).
      The agreement law gains ONE rule, in the ONE place it lives:
      a `null` agrees with any `Opt`. Representation follows the
      spec's own license — "the compiler MAY represent it
      internally as a two-variant enum" — so a nullable IS the slot
      array enums already lower to, tag 0 absent / tag 1 present,
      and NO new instruction is needed.
  (b) [x] LANDED 2026-08-30 — `List<int>` annotations, closing the
      fn-boundary hole. The type rule gained two branches, ordered
      LONGEST FIRST because every branch starts with NAME. The
      element goes back through `full_type`, so `List<List<int>>`
      and `List<int?>` need no rule of their own — and the ONE
      applied type is `List`, because the registry has no shape for
      another and inventing one would be a type nothing can lower.
      The declared-slot law reads the WHOLE written type now, so
      `List<int>?` refuses in the slot law's words rather than
      claiming `List` names no type.
      RED TEAM, three rounds, ~70 programs. THREE defects, all in
      the slice's own week-old code:
        1. THE SPECIFIC LAW SPOKE OVER THE NAME LAW — a THIRD time.
           `Foo<int>` said "`Foo` takes no type arguments", which
           implies Foo IS a type that merely is not generic. It
           names no type at all. The name law speaks first now.
        2. `type List = { x: int }` WAS ACCEPTED, and the program
           then RAN, answering 6: `List<int>` meant the builtin
           while `List { x: 5 }` meant the record — one name, two
           types, no diagnostic. Exactly the bug fixed for `int` a
           day earlier, and missed because `List` is a CONSTRUCTOR
           rather than a shape. `applied_arity` is now the ONE
           table: resolve refuses those names, typing applies them.
        3. A LATENT LIE: the arity refusal hardcoded the word ONE
           while checking against the table, so the first
           two-argument constructor would have refused correctly
           and then explained itself wrongly.
      CLEAN under attack: content identity (`List<int>` vs `int` vs
      `List<bool>` vs `List<List<int>>` all distinct); the registry
      (distinguishes element types, unifies the same type across
      fns); the `<` ambiguity against comparison and `>=`; ordered
      choice in every parameter order; 20-deep nesting; and
      OWNERSHIP under AVRA_RC_STRICT — a list param survives being
      passed twice, escaping as a return, crossing three frames,
      and 500 allocations in a loop, with eval == native throughout.

      WHAT THE SLICE MET, all pre-existing and none of them its
      business: `for x in xs` iterates ranges only, list literals
      still refuse managed elements (so `List<string>` annotates but
      `["a"]` does not build), and `if` without `else` is not a
      statement. Each is a rung of its own.
  (c) [x] `!` LANDED and `match v { b? -> }` LANDED. `?.` is
      BLOCKED, with evidence: it has no valid subject. The only
      nullable that types today is a SCALAR (`int?`, `bool?`), and a
      scalar has no members — every nullable that could carry one
      (a record, a list, a string) is refused by the declared-slot
      law. `?.` therefore waits on nullable MANAGED values, which
      wait on ownership analysis. SUPERSEDED: that last clause
      conflated two problems — the representation decision below
      unblocks `fn f(p: P?)` with NO ownership work, and `?.`
      builds the day slice (N1) lands.
      The match arms took their OWN node rather than extending
      `Match`: an enum's arms are keyed by a variant NAME, and
      keying `null`/`b?` by a string would be tagging behaviour with
      text. A nullable has exactly TWO cases — that is its nature —
      so `MatchOpt(subject, bind, present, absent)` says it without
      a tag. `nullable` merges BEFORE `enums` because its arms are
      more specific and enums' branch `@expect`s its own `}`.
  (d) [x] `?` propagation LANDED 2026-08-30 (spec Axis 10.5),
      and it is the vocabulary paying rent: NO new instruction —
      the same presence region every consumer of absence opens,
      with the return arc's `FnExit` on the absent arm (the memory
      pass settles every open scope at the site; the backend parks
      the arm's dead yield in the exit's continuation). The parse
      is one token-alt in the spine's forced rule — `!` and `?`
      fold link by link, the `prop_link` precedent. SURFACE LAW,
      decided by maximal munch and worth remembering: `w?.length`
      is the CHAIN (`?.` wins the lex); propagation before a
      member takes parens, `(w?).length` — pinned. Typing needs
      the enclosing fn's promise, so `enclosing_ret` MOVED from
      StmtTypeCx into TypeCx (which the stmt cx nests — net zero
      verbs) and LowerCx gained the twin (diet cost: one verb, one
      Lower field). The round's find: FIVE copies of the
      guarantee/always-absent refusal shape had accreted in
      check.av — extracted as `not_absent_able`, three fns died,
      the chain stays licensed apart (its remedy is actionable).
      RT10: 32 programs, all clean — every interleaving (`v!?`,
      `v?!`, `v? ?? x`, a match subject eating the `?`), every
      crossing (switch arms, loops, `??`'s lazy right side,
      beside `return`), 200-iteration owned churn through
      propagating exits, two-scope-deep exits. Refusal-quality
      DEBT found and recorded (pre-existing, not this slice's): a
      garbage token at a block's head cascades to TWO errors and
      shows users "builder failed: a block ends with an
      expression" (F0102) — fix with the diagnostics-quality pass,
      trigger: any user report or the next parser-recovery arc.

## The nullable representation (decided 2026-08-30)

The question DECISION_nullable_representation.md carried, answered
so it is never re-litigated. The box chose itself in slice (a) for
uniformity with enums, unmeasured against alternatives; measuring
inverted the frame — `User?` is the EASY case and `int?` the hard
one, and we had built the hard one and gated the easy one.

THE DECISION: dual representation behind ONE protocol. Pointer
inners (`string?`, `List<int>?`, `User?`, enum values) take the
NULL-POINTER NICHE — the nullable IS the value, absence is address
zero, which no legitimate value ever holds (verified: the runtime
allocates or interns every pointer it hands out). Scalar inners
(`int?`, `bool?`) become an UNBOXED PAIR `{present, value}` living
in registers. The heap box dies. The old tree ratified this same
dual shape (NULLABILITY_OPTION_EPIC §1.1, "done correctly from day
one") and its reason to refuse "uniform first, niche later" —
swapping a shipped representation is the expensive path — holds
here too.

WHY, each a paradox collapsed (P6):
- UNIFORM VS SPECIALIZED dissolves at a seam already built:
  values.av. The surface stays ONE (`T?`, `null`, `??`, `!`,
  match), the protocol stays ONE — the verbs become `absent_into`,
  `present_into`, `presence_of` (an i1), `carried_of` — and the
  layouts go plural behind one `repr_of(inner)` query. The feature
  never learns which layout it got. Uniformity lives in the
  vocabulary; specialization lives in the dispatch.
- "SAFETY WAITS ON OWNERSHIP" was TRUE for containers and FALSE
  for nullable pointers, and one law (F2018) gated both. A nullable
  pointer is NOT a container: under the niche, `carried_of` is
  IDENTITY — the nullable is the very value the memory pass already
  manages — and absence is a null pointer the runtime already
  no-ops BY CONSTRUCTION (avra_rc_release guards NULL and ignores
  unregistered pointers). The representation IS the safety
  argument. `is_managed` learns one thing: see through `Opt`.
- THE BOX WAS AN OPTIMIZATION BARRIER, not merely an allocation.
  LLVM cannot see through `avra_array_new`; it sees straight
  through `{i1, i64}` — SROA splits the pair into scalars and the
  discriminant CONSTANT-FOLDS AWAY wherever flow already proved
  presence, which after rung 9's bind-fresh trio is most checked
  code. We do not build presence-elision; we choose the shape that
  lets the optimizer do it. The discriminant is a ghost.
- NULL HAS NO LAYOUT UNTIL A TYPE CLAIMS IT. The absent literal
  gets no representation of its own: `accepts` records the widen
  target for `null` too (it currently skips it), and `widened` —
  the one edge every expression already crosses — mints the
  claiming type's absent form. One line in the checker, one
  dispatch at an existing edge.

THE IR ANSWER (the genuinely open question): FIRST-CLASS AGGREGATE
REGISTERS — none of the three shapes the decision doc listed.
`Reg`'s contract changes from "one machine word" to "ONE SSA
VALUE", and a value may be a small immutable aggregate. Two
instructions, general on purpose:
    Pack(dst, elems: List<Reg>)      build a register aggregate
    Extract(dst, src, i: int)        project element i
`int?` is LLVM `{i1, i64}` — two machine registers through the
existing C ABI, never memory. The consumers each answer in a line
or two (the build counted SIX — `give` joined the five, see the
N2 record); the interpreter rides its existing arrays table (its
Val vocabulary is private bookkeeping, not layout). Not
option-machinery: rung 8(b) scalar enum payloads and any future
multi-return ride the same pair. Pack of a MANAGED element is
refused at lowering until ownership analysis — the declared-slot
law restated at the IR seam, so the container problem stays where
it belongs.

THE LAW, ratcheted: NULLABILITY NEVER ALLOCATES. Once (N2) lands,
no nullable lowering may emit `avra_array_new` — pinned by the IR
goldens plus a negative assertion in the nullable suite. Rust's
"Option<Box<T>> is one word" is folklore; ours is a tested,
citable guarantee. Honesty about prior art, per the spec's own
Axis 9 assessment: niche and pair are 40-year-old primitives; the
stance — representation as a PUBLISHED, TESTED CONTRACT — is the
innovation, and it is shipping-level, not research-level.

THE SLICES (each vertical, each gated):
  (N1) [x] THE NICHE — LANDED 2026-08-30. No vocabulary growth, the
       unlock: `repr_of` + the verbs in values.av (`presence_of`,
       `carried_of`, `adopted`, `insisted`; scalars keep the box PRO
       TEM behind the same verbs, so nothing user-visible
       regresses); F2018 died (typing.av `full_type`);
       `nullable_over` lifts pointer shapes; null literals recorded
       as widens; nullable/lower.av rewrote onto
       `IfStart(presence)` — the SwitchStart-on-tag shape was a box
       artifact; the interpreter grew a private `Val.N`;
       `avra_insist` joined the runtime (`!` for pointers, refusing
       in `avra_unwrap`'s exact words). What the build taught:
       - The predicted `int→ptr` coercion gap NEVER OPENED:
         `avra_insist` declares `ret: Ptr`, so `call_rt_value`
         needed nothing — the registry's ret kinds were already the
         seam. `ll_type_of` needed nothing either: every N1 repr is
         pointer-shaped, so `Opt(_) -> pointer` stayed true.
       - The null CONSTANT is `ConstInt 0` aimed at a pointer-shaped
         register; both engines share one rule (backend: const null
         pointer; interp: `Val.N`) — no new instruction, exactly as
         designed. The presence test is one `Bin Ne` against it.
       - LowerCx grew ONE verb (`shape_of: TypeId -> Type`) — the
         first time a feature's lowering needed a TypeId's shape,
         and TypeCx already had the twin.
       - The c2 lowering typed a box's payload as the PRESENT ARM's
         type, not the subject's carried type — latent (rt_owns
         false kept it from releasing wrong), fixed by
         `carried_type` in the rewrite.
       - Widening a pointer into its nullable adds NO instruction,
         a pointer nullable builds NO box, a scalar still boxes
         exactly once — all three now PINNED as lower_test laws;
         the never-allocates gate law completes at (N2).
       Corpus: nullable_niche.av (`User?`, `string?`, `List<int>?`
       through `??`/`!`/match, fn boundaries both ways) and
       nullable_churn.av (500 owned strings widened, answered and
       released per iteration — the evaluator has no refcounts, so
       eval == native there IS the ownership proof), eval == native.
       THE RED TEAM on the slice: 59 programs across the eight
       classes — zero wrong answers, zero divergences, zero crashes,
       zero defects shown; every guarantee shape refused at every
       nullable slot in its own words, exactly once. Survivors
       pinned: the ownership seven (owned escape, force-alias,
       absent-through-frames, relay+force, double-read, loop-500,
       enum niche) and the field-law-speaks-once cascade guard.
       Found and left, recorded: the match FAMILY cascades 3–4
       parse errors on a malformed arm (pre-existing — enum matches
       cascade identically; belongs to the match-chain arc); an
       unannotated `let x = null` binds an inert `null`-typed name
       (every USE refuses; rung 9's bind-fresh trio owns the
       revisit). `?.` now has real subjects — next.
  (N1b) [x] `?.` LANDED 2026-08-30 — the chain, on the niche's
       subjects. The `"?."` token joined the two-char roster; the
       spine's postfix slot became a LINK choice (`( "?." | "." )
       NAME`, the op-alternative precedent) with parse in the
       ladder and meaning in `nullable`, exactly as `??` and `!`.
       What the build taught:
       - THE MEMBER LAW CENTRALIZED AT ITS SECOND COPY, because a
         law copied by hand disagrees with itself: `member_type_of`
         (checks.av) now answers fields and `length` for the bare
         read AND the chain, shown as the caller displays the
         subject — the chain shows the CARRIED type, so
         `find_user(7)?.nope` says "no field `nope` on `User`".
       - THE PRESENCE REGION got its ONE definition at its third
         copy, as the review round's trigger predicted: `??`,
         `match` and `?.` all open `presence_region` (block-bodied
         zero-arg thunks — probed into CLAUDE.md — keep each arm's
         instructions inside its brackets, which is what makes the
         absent side lazy).
       - FLATTENING is typed by `nullable_over` (nothing lifts
         twice) and GUARDED at lowering: a member wearing a type
         the lift does not expect is a loud lower_defect, so the
         day nullable members exist, the flatten lowering must be
         written — it cannot silently double-wrap.
       - THE RED TEAM (35 programs, eight classes; the N1 suite
         rerun bit-clean beside it): one real finding — a PLAIN
         `.` on a nullable subject offered "the one property today
         is `length`" as its remedy; the member law now refuses it
         toward the chain ("`?.age` reaches through the absence —
         or answer it first with `??`"), test-first. Parity probes
         settled two non-findings: spaced `?. name` reads fine
         (plain `.` spaces too) and a keyword member reaches
         typing's "no property" on both link forms.
       Corpus: chain.av (fields and `length` through `User?`,
       `string?`, `List<int>?`; absent short-circuit; `??` and `!`
       over the chain), eval == native. 732/732.
       LEFT with triggers: member LOWERING exists twice (spine
       expr-keyed, chain type-keyed) — the method core (rung 13)
       owns the one member-resolution query, typing and lowering
       both; `?.` on METHODS rides the same rung.
  (N2) [x] THE PAIR — LANDED 2026-08-30. One vocabulary event:
       `Pack(dst, elems)` / `Extract(dst, src, at)` — first-class
       aggregate REGISTERS, the register's contract now ONE VALUE,
       not one word. `int?` is LLVM `{i1, i64}`, `bool?` is
       `{i1, i1}`; the scalar repr flipped box→pair INSIDE
       values.av and nowhere else; the box path and `avra_unwrap`
       retired (`avra_insist_scalar` guards the pair `!`).
       THE LAW IS ON: nullability never allocates — pinned by
       lower_test's law block (niche, pair, identity widening, and
       an aggregate-free every-consumer witness), plus the
       visible-magic pin: `avra ir` SHOWS `pack r7, r6` and `r1.0`.
       What the build taught:
       - A SIXTH consumer surfaced, by the guarantee working: the
         driver's `give` (does the runtime registry validate this
         instruction?) broke exhaustively alongside the five. The
         doctrine now says SIX everywhere — CLAUDE.md, core/ir.av,
         vocab.sh's consumer registry, and `avra new ins`.
       - `ptr_shape` CANNOT see what an `Opt` carries (a bare shape
         holds a TypeId it cannot resolve), so the carried-aware
         truth is the registry's `rides_pointer` — the machine
         projections (rt_arg coercion, both engines' null-constant
         rule, `ll_type_of`) ask it; the flat shape question stays
         for the laws that mean "not a scalar".
       - The LAW's witness must be AGGREGATE-FREE: a struct
         literal's box is a struct cost, not the nullable's, and
         the first witness said otherwise until it was cut down.
       - The pair's corpus twin (pair_zero.av) pins the two
         distinctions only a flag can carry: present ZERO beats the
         fallback, present FALSE is not absence — eval == native.
       RED TEAM: the three standing suites (120 programs) rerun
       green ON the pair — rt1's whole scalar attack record now
       exercises it — plus 8 pair-edge attacks (present-false
       asked/forced/compared, hollow payload never observable,
       three-frame relays, region-join into match, trap parity on
       both scalar shapes) and a 1000-iteration churn, eval ==
       native throughout.
       TRIGGER FIRED 2026-08-30, with mut annotations: the cell law
       now asks TypeCx's `rides_pointer` — `mut x: int? = null`
       lives (the pair is two unmanaged words), the niche still
       refuses (it IS its managed pointer), ptr_shape untouched,
       exactly as prescribed. The red team's reassign-to-absent
       then `!` traps at runtime in both engines — the soundness
       hole 10.4 warns about cannot open, because no narrowing
       exists to fool.
       CONSIDERED AND REFUSED (the N2 beauty round): making the two
       reprs TRAIT IMPLS when rung 12 lands, dissolving values.av's
       per-verb `match repr_of`. Refused: two statically-known arms
       beat a vtable in the hottest lowering path (P4), and the
       match IS the readable registry — re-argue only if a THIRD
       repr ever appears.
  (N3) [x] `if let` — LANDED 2026-08-30. The bind-fresh form (spec
       Axis 10.4), PURE SUGAR: one gram branch in `nullable` whose
       action is the existing `match_opt` builder, arms as BLOCKS —
       zero new nodes, zero new semantics, every pass untouched.
       The refusal wording centralized to serve both surfaces: the
       asking arms now speak the BIND's name (`` `v?` asks a
       nullable, this is `int` `` — form-neutral, F2022 reworded),
       and arms over absence itself say "always absent" instead of
       falsely calling `null` a guarantee (found test-first).
       What the build taught:
       - A MID-SEQUENCE `@expect` fails the DSL parse of the WHOLE
         assembly, with cascades that never name the offending
         fragment — probed, recorded as a grammar-authoring law in
         CLAUDE.md. The DSL wants a pointed refusal there someday.
       - The `@expect("else", …)` at a branch TAIL never fires on a
         bare missing `else` — in PLAIN `if` too (parity probed,
         both fall to the floor with 2 errors). Pinned as a parity
         test; the if-family's recovery debt, one bucket with the
         match-family cascade (the match-chain arc owns both).
       - `if let` lands AFTER if_expr in branch order and works
         because plain-if fails NON-COMMITTING on `let` — the
         clean-failure path is proven by the corpus, not assumed.
       DEFERRED with triggers: `let v? = e else { }` rides the
       `return` rung (its else must DIVERGE, and the language has
       no diverging statement yet); `while let` rides the same;
       effectively-final narrowing is its own slice (needs `!=
       null` presence tests in the eq law first).
       Corpus: if_let.av (present/absent, chain-fed, block bodies,
       string? length), eval == native. 749/749, 30 corpus.
  (N4) [x] `let v? = e else { }` — LANDED 2026-08-31, closing rung
       9. The trigger fired exactly as recorded: `return` gave the
       language its first diverging statement, and let-else needed
       only a DIVERGENCE FACT, not a Never type — `diverges(s)` is
       a NodeStore registry spelling every Stmt arm (a new
       statement kind must answer; a diverging one cannot slip in
       as a silent false). PARSE lives in `let_stmt` — the
       recovering plain-let branch COMMITS on `let b? =` (probed),
       so the let-else branch merges FIRST in that feature's own
       gram, non-committing (an @recover there would eat every
       plain let: two branches share the anchor); MEANING lives in
       nullable (the Chain precedent, now proven for statements).
       The bind lands in the ENCLOSING scope by making the
       presence region's MERGE register the binding — present arm
       yields the carried value, absent arm runs the else (typing
       demands its LAST stmt diverge) and yields a hollow the
       merge never reads. No new instruction, again. Diet: ONE
       verb (`record_binding` — the computed twin of the annotated
       law's write) — and the slice PAID DOWN the contract:
       StmtLowerCx now NESTS `expr: LowerCx` (the typing cx's
       twin) and its six duplicate verbs died (mint, mint_like,
       mint_shape, emit, fail, lower — 12 fields to 6; mint_like
       moved to its one home on LowerCx). RT11: 25 programs, all
       clean — the divergence law position by position (dead code
       after return still refuses: the LAST stmt is the law;
       if-then-return ending in bare return is legal), the shared
       parse's fall-through (a forgotten `else` refuses via the
       plain let's "expected `=`" — misleading first words, filed
       with the F0102 recovery debt), shadowing (legal, consistent
       with plain re-`let`), `??`-in-subject makes a guarantee
       (pinned — coalesce answers carried, so the two never
       stack), 200-iteration owned churn through both exits.

THE RULINGS on the decision doc's open questions:
- VISIBLE (P7): yes. `avra ir` already shows the truth (a bare
  pointer, a pair); `repr_of` is one projection from answering
  "what did the compiler do with my `T?`" in tooling. TRIGGER:
  ship that projection when `avra explain` exists.
- `?.` FLATTENS at the chain: `a?.b` where `b: V?` types `V?` —
  the Swift/Kotlin convention, the maximal P1 prior. The whole
  chain short-circuits on first absence.
- `T??` cannot even be SPELLED today (`TypeRef.optional` is a
  bool); generics will manufacture it. Recorded for rung 11, built
  never until needed: structurally the registry already interns
  `Opt(Opt(T))` distinctly, and the niche extends by SENTINEL
  LADDER — 0, 1, 2… are all invalid addresses (every mainstream OS
  guards the zero page), so pointer nullables get ~4096 nesting
  levels free; scalar pairs nest structurally.
- ZIG'S POINTER-STABILITY LOCKS (2026-08-27): recorded as a
  systems/bare-level tool and debug-build backstop for the
  CONTAINER problem; rejected as app-level default — a runtime
  panic is strong feedback in a human loop and weak for a
  generator judged before anything runs (P1).
- THE SURFACE STANDS WITH THE SPEC: `null` (not the old epic's
  `none`) and UNIFIED `?` (not its Zig split). The epic's
  counterarguments are recorded here so rung 10 rules with both in
  hand: `none` co-occurs with safe-optional code in training data
  while `null` co-occurs with unsafe code; and a split `?` gives
  one token one meaning where unified `?` couples the meaning to
  the enclosing return type. Against them: `T?`+`null` is the
  Kotlin/TS surface with enormous prior, the spec's `u? / null`
  match arms are load-bearing, and the clean room dogfoods `null`
  pervasively. If rung 10 finds the split argument winning in
  practice, it re-opens THERE, with evidence.

THE BOUNDARY, kept honest so §4's conflation never reforms:
`repr_of` decides the REGISTER/ABI form only. A container slot —
`List<int?>` elements, a struct field, an enum payload — stays the
container laws' problem (F2008 family) until ownership analysis
sizes elements by type. Two problems, two laws, on purpose.

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

AMENDED 2026-08-30 — THE FIRST ENTRY WAS WRONG, and the way it was
wrong is the lesson. It blamed lowering (a per-node `LowerCx`) for a
superlinear curve, on reasoning alone. Measuring by SPLITTING the
commands settled it in one run: `run` lowers exactly as `ir` does and
then interprets, and `run` tracked `check` linearly while `ir` blew
up — so lowering was never implicated. The per-node context costs
something, but nothing that shows.

THE ACTUAL BUG was `joined`, in core/lists.av: it accumulated with
`out = "${out}${x}"` per element, re-copying the whole string every
turn — quadratic in the TEXT, and `avra ir` renders a lot of text.
n=2000 took 41.1s. Merging in PAIRS instead (log n passes, each
copying every character once) took it to 2.1s, and at n=4000
rendering is no longer measurable against the front end at all
(ir 6.0s vs check 6.6s). The same accumulator trap as
`out = concat(out, x)`, in the helper nobody had tested.

CLOSED 2026-08-30, and the cause was one line repeated eight times.
A STRING's `.length` is `strlen` in the runtime — O(length), every
time it is asked — so every `while i < s.length` re-measured the
whole string per iteration. The lexer did it per character AND per
token; `fp_str` did it for every string in the AST; `edit_distance`
did it inside an O(a*b) matrix, making the distance O(a*b*(a+b)).

  check, n=4000   2.22s -> 0.96s
  check, n=8000   6.81s -> 1.64s
  per line        0.81ms -> 0.17ms, and FLAT: 0.17 at both sizes

The curve is linear now. Found only by profiling (`sample` on the
forked child): two prior hypotheses — the per-node LowerCx, then the
parser's repetition accumulator — were both measured and both WRONG.
Ratcheted as I27, which immediately found an eighth site the hand
sweep had missed.

WHAT REMAINS is diffuse and normal: allocation and refcounting ~27%,
array ops ~9%, closure dispatch ~5% (the capability contexts),
bs2's own memory polling ~5%. No single lever left at this scale.
The one large win still available needs bs2: `s.char_code(i)`
SILENTLY IGNORES its index (returns index 0's code), which is why
`code_at` allocates a one-character string per byte.

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

- GRAM FRAGMENTS: the parameter-list shape
  `( ps:NAME ( ":" pt:type )? ( "," … )* )?` is spelled THRICE
  (fns, trait sigs, lambdas) — the grammar DSL wants named,
  reusable fragments (`fragment params = …`). An ENGINE feature
  (grammar/ is language-agnostic); wanting sites: the three grams.
- EXPRESSION CONTINUATION: a leading-operator continuation line
  (`a(x)\n    ?? b(x)`) refuses — BREAK ends the statement. The
  five-fork dot-call dispatch would read as one `??` chain if
  continuations parsed. Probed 2026-09-01; a lexer/BREAK design
  question, not a grammar rule.
- [x] POSTFIX CALL + MULTILINE LITERALS — landed with L2
  2026-09-01 (the unified postfix star; BREAK-tolerant literal
  grams for structs, decls, and lists).
- THE LAMBDA BARRIER'S VOICES: return/`?` inside a lambda refuse
  through the top-level wordings ("the top level has none") —
  correct law, misleading flavor. And a keyword PARAM speaks
  twice (the lambda's refusal + the body ident's — the same
  pre-existing cascade fns have). Both polish-grade.
- THE EXPECTED-TYPE CHANNEL. A literal cannot hear what its slot
  declares: `[P{…}, G.hot]` under a `let xs: List<dyn Show>`
  refuses at its own site (elements judged against the head), and
  a branch join meets the same wall — the widen laws only run at
  the boundary AFTER the value typed itself bottom-up. bs2 grew
  exactly this channel (mono threads expected types through match
  arms, list elements, if-branches) and its dyn shares the
  limitation. Wanting site: corpus/dyn.av's heterogeneous list,
  written with three pre-boxed lets. Lands as its own milestone —
  the ask threads the driver, not one feature.
- PROP-READ HELP ON A DYN: `d.show` (no parens) says "no property
  `show` on `dyn Show`" — when the contract HAS that method, the
  help should say "write `d.show()`". Wanting site: rt21's
  no_c3_prop_read. Small; rides any chain-feature touch.

- A PROJECTION PER VARIANT, generated. `fn_sig_of`, `record_sig_of`
  and `variant_sig_of` (features/contract.av) are three copies of
  six lines of ceremony for a one-line concept: guard the option,
  match the one variant, `_ -> null`. They cannot merge in the
  subset — a generic over an enum's VARIANT does not exist, and
  threading the reader as a fn argument corrupts scalar payloads
  through mono (F1002). Avra should generate `DeclSig.fn_sig()` and
  its siblings from the declaration. Wanting site: every consumer
  of a one-of-N declaration table, and the same shape will recur
  for the next such enum. Filed 2026-08-30 by the slice (b) review.

- MULTI-CLAUSE `if let` — `if let a? = f(), b? = g() { use both }
  else { }` (Swift's precedent). One absent clause takes the else;
  each bind is fresh. Kills the nesting pyramid that
  nullable_test's "it nests, each bind in its own scope" exhibits —
  written BY the primary consumer, who reached for the flat form
  first. Pure sugar over nested MatchOpt; can land any time after
  N3. Filed 2026-08-30 by the consumer's-hat review.

- LEFT-CHAINED `??` — `a ?? b ?? c` with no parens: relax the
  coalesce RIGHT side to accept the carried type OR its nullable;
  the chain stays nullable until a guarantee closes it. The
  JS/Kotlin/C# elvis prior is left-associative chains that just
  work, so P1 says models will write it (this one did, in the
  first red team). Today it refuses with the group-right help —
  good message, wrong requirement. SPEC TOUCH (Axis 10.3's
  "right side is the guaranteed-present fallback") — needs
  ratification before building. Filed 2026-08-30 by the
  consumer's-hat review.

- ONE INTERLEAVED POSTFIX FOLD — a GRAMMAR-ENGINE ask, found by the
  deep red team on `?.`: `x!.length` does not parse, because `!`
  (the `forced` level) sits BELOW member access in the ladder, so a
  member can never follow a force. Kotlin's `a!!.b` is the everyday
  spelling this blocks; the workarounds hold (`(x!).length`, or
  bind then read — both probed) and the bind-fresh trio will thin
  the need, but the honest fix is postfix operators as ONE fold:
  `( "?." NAME | "." NAME | "!" )*`. The DSL can SPELL that today;
  the builder cannot RECONSTRUCT it — captures arrive per-slot
  (`b.tokens(n)`), so the interleaving of links and forces is lost.
  The engine wants a POSITION-TAGGED capture stream for alternated
  groups in a star. Wanting site: expr_spine's `forced`+`postfix`
  split (mod.av). Pinned: the refusal is a test, so closing the gap
  is noticed. Filed 2026-08-30 by the deep red team.
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

FLAGS FROM THE G2 ROUND (2026-08-31), each with its trigger:
- THE PLAIN PATH IS THE ZERO-TPARAM DEGENERATE: PROVEN on the
  variant-lit pair (2026-08-31) — generic_variant_lit is DEAD,
  one law serves both (unify with no Vars IS the agreement
  check), and the shared instantiation rituals (tparams_refused/
  unpinned_of/bound_closed) replaced the thrice-spelled walks in
  all three surfaces. REMAINS: the call pair (checked_call vs
  generic_call) and the struct-lit pair (check_fields vs
  generic_lit) — same collapse, trigger: the G3 round. Bonus
  find: the interner keeps the FIRST shape per key, so a
  throwaway name in an intern call poisons printing program-wide
  — recorded at variants_declared, worth a registry guard when
  content-addressing lands.
- THE COMPILER'S OWN CODE WANTS ITS OWN NEW FEATURES: every guard
  ladder in the check files is a hand-spelled `let sig? = … else
  { return voice(…) }`, and every `X? -> refuse -> unwrap` wants
  the error spine. Recorded as SELF-HOST PAYOFF EVIDENCE — the
  ladders are the before pictures.
- I28 MINTED (laws call voices): the enums exemplar landed; the
  round applies it opportunistically file by file — structs and
  fns are half-converted, nullable's not_absent_able led the way.

ASK FROM G1 (2026-08-31): FOUR hand-written walks now recurse the
Type composite (unify, substituted, fully_bound, unlawful_side —
checks.av and core/types.av), each a different fold over the same
shape. The compiler wants DERIVED STRUCTURAL RECURSION (a visitor/
fold the enum carries). Trigger: the FIFTH walk forces the seam.

ASKS FROM THE PROPAGATE SLICE (2026-08-30), both hit writing its
tests: (1) string `+` concatenation — `(shout(true) ?? "q") + ...`
refused (`+` is int-only), and the test had to split in two;
interpolation covers most cases but concatenation of two computed
strings has no spelling outside a hole. (2) `for` over a LIST —
`for x in [1, 2]` refuses ("expected `..`"); ranges only today.
Both wait on their natural rungs (strings polish; lists/generics),
recorded here so the wanting sites are named.

## The error spine (rung 10 — designed 2026-08-31, from the epic)

Source: `../forge-crafting-intepreters/docs/2026_06_08_ERROR_HANDLING_EPIC.md`
read in full, with spec Axis 12 under it. The epic is a five-phase
program (produce -> handle -> topology -> resumption -> agent layer);
this record fixes what OUR tree takes now, what waits on which rung,
and the three places we deliberately diverge. Read the epic before
touching any slice — it is the ergonomics contract.

THE COLLAPSES (P6), each killing a machinery bill:

1. RESULT IS A BUILT-IN ENUM. `Result<T, E>` needs no generics:
   `Type.Res(ok, err)` is a structural core constructor, interned
   like `Opt` (the nullable precedent, replayed). `variants_of`
   answers `{Ok: T, Err: E}` for a Res type, so MATCH, its
   exhaustiveness, payload binds, and refusals all ride the enums
   feature UNCHANGED — the match story costs zero new nodes.
2. THE ERROR PATH IS A POINTER MOVE. v1 repr = the enum layout
   (tagged box, tag 0 = Ok / 1 = Err, payload slot 1). An `.Err`
   box of `Result<_, E>` is bit-for-bit a valid `.Err` of EVERY
   `Result<_, E>` — `?` on failure re-emits the SAME register
   through FnExit. No repacking, no allocation on the propagation
   path. The register TRIPLE `{tag, ok, err}` (never-allocates,
   Pack/Extract already paid) is the recorded POST-OWNERSHIP
   optimization: a managed payload in a triple needs retain-at-pack
   accounting the memory pass cannot balance yet. Re-measure at the
   ownership milestone; do not re-argue before it.
3. `?` STAYS UNIFIED — the epic's F1202 `?`-split is REFUSED for
   Avra (it depended on a nullability epic we superseded). Our
   ratified 2026-08-30 decision + spec 12.2 stand: ONE operator,
   "pass it on", channel picked by the SUBJECT's type — `T?`
   propagates null (needs nullable ret), `Result` propagates the
   Err (needs Result ret, same E in v1). Locally legible: the
   subject's type and the signature are both at hand. The epic's
   real invariant survives intact: `??` is Option-only, `catch`
   is Result-only, `fail` is raise — one verb per intent.

DECIDED SURFACE (v1 spellings):
- `.Ok` / `.Err` UPPERCASE — the epic's consistent spelling and the
  self-host source's own (bs2's Result); spec 12.1's lowercase is
  superseded.
- `fail e` — a STATEMENT v1 (keyword-anchored, @recover like
  `return`), desugaring to an Err exit; it DIVERGES, so it joins
  the `diverges` registry and a let-else's else can `fail`.
  Expression-position fail rides the divergence-aware-blocks
  trigger with return's.
- AUTO-OK (epic §3.2, implicit, the Gleam way): a tail/return value
  of exactly T Ok-wraps at the ONE widening edge (the widens table
  already dispatches on the target's shape — Res joins Opt there).
  The guard rule is law: a Result-shaped value never silently
  double-wraps.
- E v1 is ONE nominal enum type, matched exactly. UNION error types
  + auto-widening at `?` (the epic's crown) need union types — a
  design of their own, NOT rushed here; recorded as the R4 trigger.

THE SLICES:
  (R0) [x] the SLOT LAW widened — LANDED 2026-08-31. ONE law
       (`slot_law`, was scalar_slot) for enum payloads and struct
       fields: unmanaged word-shaped types ride slots — Int, Bool,
       Struct, Enum, TypeName, List, and now Res. Str stays refused
       (managed); Opt slots stay refused (the pair is a register
       aggregate, not a word — nullable fields are a recorded
       want). The MUT CELL law widened the same day to the same
       truth (`managed_cell` — the strategy's answer, shape-down).
       WHAT THE RED TEAM FOUND (rt12): the native backend had never
       moved a pointer through the runtime's I64 word slots — the
       result-coercion half of the ABI shim was missing
       (`answers_word` + inttoptr, rt_arg's mirror); the evaluator
       hid it, the differential caught it. SELF-RECURSIVE enums
       (`a(E)`) now legal — recursion rides the box; pinned with
       50-deep churn. The LIST ELEMENT law deliberately not
       widened — its trigger is rung 11's List<T> work.
  (R1) [x] the SPINE — LANDED 2026-08-31, eval == native on first
       run of the kitchen-sink witness. `Result<T, E>` -> Type.Res
       (7 Type consumers answered, compiler-listed); the
       variants_of/variants_at bridges answer `res_enum_sig` and
       MATCH, exhaustiveness, payload binds all arrived FREE
       through the enums feature (zero new nodes); `fail` (its own
       feature dir, keyword-anchored, diverges — let-else's else
       can fail); auto-Ok at the ONE widening edge (res_accepts +
       widened's Res arm; the guard rule holds — identity meets
       the equality case first, Ok(Ok(x)) cannot happen silently);
       `?` extended to Res subjects (okness region; the Err arm
       FnExits THE SUBJECT'S OWN BOX — zero repacking, the pointer
       move the record promised). Diet cost: ZERO context verbs —
       okayed/failed/okness_of are values.av vocabulary.
       AND THE TRIGGER PAID: divergence-aware block tails. A
       fail-last body broke the block law ("a block ends with an
       expression"), so the recorded trigger fired mid-slice:
       Block's tail is now OPTIONAL, built tailless only when the
       builder PROVES the last statement diverges (the `diverges`
       registry, syntactic); a block that LEAVES answers WHATEVER
       THE FN IT LEAVES PROMISES — the body check passes exactly,
       and a value-position arm joins only where the promise's
       type fits (codegen's phi protected by typing, no Never type
       needed). `let got = if let v? = e { v } else { return -1 }`
       — the epic's guard shape — now runs, pinned both engines.
       RT13: 25 programs — every mis-aim refused in its own words
       (fail at top/plain fn/wrong E/ok-side value; `?` in plain,
       nullable, and wrong-E fns; Result arity; match missing
       .Err), 200-iteration owned churn through failure exits,
       fail inside let-else, mut Result cells, Result<User, E>
       riding R0's slots.
  (R2) [x] `catch` — LANDED 2026-08-31, one node, four surfaces:
       a VALUE (`catch 99`), a catch-all BIND (`catch e ->`),
       braces ARMS (total when every variant answers), and a
       SELECTIVE arm whose unmatched failures leave through the
       SAME exit `?` uses (the §5.10 rule landed exactly: the
       answer is always the ok side; coverage only decides whether
       a channel is needed). PARSE: the LOOSEST ladder layer, in
       the spine (the `??` precedent) — ONE branch, the four
       surfaces as alternatives of one optional group (the
       enum-decl group-alternation precedent), so `disjunction`
       parses once; a captured `catch` keyword is the WITNESS that
       separates `catch { }` (refused: needs an arm) from no catch
       at all. WHAT THE BUILD TAUGHT: (1) four competing
       expression branches re-parse and ORPHAN arena nodes — the
       assembly's coherence checker refused the shadowing outright
       (a defense that WORKED); (2) `b.tokens(i)?.method()` is the
       recorded bs2 poison, twice; (3) `Result<int?, E>` broke the
       verifier — a Res SIDE is a slot of its box, so the slot law
       now judges both sides at the surface (nullable and string
       sides wait for ownership, consistently); (4) Error-shaped
       enclosing rets now ABSORB in fail/`?`/catch (one mistake,
       one message). Aligned_binds moved to the shared authoring
       surface (two features needed the span-window law). CHAINS
       v1: value-form nests right (`a catch b catch c` recovers
       with `b catch c` — lazily evaluated, the or_else meaning);
       arm-form chains take parens; flat left-assoc chaining is
       recorded with unions. `it`-blocks wait for closures' pronoun
       (rung 13). RT14: 22 programs, all clean — 200-iteration
       churn through selective recovery, `?` inside arms (the
       fallback chain's spelling), catch feeding let-else.
       COMPOUND LIFT recorded: a bare `null` tail into
       `Result<T?, E>` would need null -> T? -> Ok — explicit for
       now, revisit with unions.
  (R3) `.Ok(v)`/`.Err(e)` in EXPRESSION position, `is`-patterns
       over Res, `? context "…"`.
  (R4) recorded triggers, each on its enabling rung — PLUS, from
       the 2026-08-31 debts review:
       - AT RUNG 11, RE-MEASURE: does `Type.Res` fold into the
         general instantiation machinery (a built-in generic enum
         declaration)? Instantiation is already pure interning —
         nothing multiplies per Result type — the question is only
         whether THREE hard-wired constructors (List, Opt, Res)
         become instances of one mechanism. The surface (`?`,
         `fail`, auto-Ok, `catch`) stays language-level either way.
       - a true NEVER type replaces "a diverging block answers the
         fn's promise" when it earns its keep (the wording wart in
         join refusals is the only cost today; sound, codegen-safe).
       - the variants bridge lives in TWO files (typing.variants_of,
         lower.variants_ty — one match each); the third copy forces
         a shared home.
       - flat left-assoc `catch` chains (arm forms) ride the unions
         design; value-form chains already nest usefully.
       Original list, each on its enabling rung: union types +
       inferred unions + widening (own design doc first); managed
       payloads + the register triple (ownership milestone);
       errdefer (ownership milestone); resumable handlers /
       retry / handler values (fibers, rung 18); failure topology +
       explain-failures (after unions); Transient/Remediation/
       catch auto (traits, rung 12); @derive(failure_tests)
       (derive infra).

## Generics — rung 11 (designed 2026-08-31, awaiting ratification)

Spec Axis 5 governs: parametric + traits BOTH, MONO by default
(P4), `dyn` the later escape hatch. Rung 11 takes the UNCONSTRAINED
subset — bounds (trait/shape) arrive with rung 12's traits; const
generics are spec-deferred to v1.x. The old tree left no mono
pipeline design (its standardization doc stops at parsing), so this
is ours, shaped by our pass architecture.

THE ARCHITECTURE (recommended): abstract bodies, substituted views.
1. TYPE VARIABLES ARE SHAPES: `Type.Var(decl, name)` joins the
   registry — a generic fn's `T` interns once per declaration site,
   nominal like TypeName. An UNCONSTRAINED T is fully checkable
   abstractly: its values can only be moved (bound, passed,
   returned, stored in slots) — every operator law already refuses
   what T cannot prove. The generic body TYPE-CHECKS ONCE.
2. CALLS INSTANTIATE BY DIRECT ARGUMENTS ONLY (the bs2 rule kept as
   LAW, not limitation — local legibility: the substitution is
   readable at the call): unify each param type against its arg's
   computed type; every Var must bind or the call refuses
   ("`T` is not pinned by the arguments — write `f<int>(…)`");
   explicit `f<int>(…)` pins the rest. The call's answer is the
   substituted return. Typing records the SUBSTITUTION as a fact
   keyed by call expr (a table, like widens/narrows).
3. MONO AT LOWERING, BEHIND A VIEW: the lowering driver walks
   (fn, substitution) pairs discovered by typing — a worklist
   seeded by concrete calls, closed under generic-calls-generic
   (each body lowered once per DISTINCT substitution, keyed by
   substituted param types; names mangle as `first__int`). The
   ONE mechanism: `subst(types, map, ty)` applied inside the
   lowering context's type_at/enclosing_ret wirings when a body
   lowers under a substitution — registers mint CONCRETE types, so
   values.av's reprs, the backend, memory, and the interpreter are
   ALL UNTOUCHED. Call lowering routes to the mangled name.
4. GENERIC USER TYPES (`type Pair<A, B>`) are slice G2: the same
   Var machinery + `applied` growing user names (arity from the
   declaration); instantiation is interning (the List/Opt/Res
   precedent — R4's fold re-measure lands here naturally).
SHARPENINGS (2026-08-31, the measure-twice pass):
- THE `f<int>(x)` AMBIGUITY DISSOLVES FREE: comparison refuses
  chains (`( op … )?` — at most one), so `a<b>(c)` has NO legal
  comparison reading — a pinned-call primary branch claims it
  outright, stealing nothing. The no-chain law pays twice.
- THE VIEW COVERS THE FACT TABLES: widens/narrows/asks hold
  ABSTRACT types (T widening into T?), so substitution sits at the
  Lower level and every fact read passes through it — not only
  type_at/enclosing_ret.
- SUBSTITUTIONS COMPOSE: an inner generic call's recorded subst is
  in the OUTER's Vars; lowering under map m applies m ∘ inner.
- MANGLING: `name$` + interned type ids (uncollidable, stable per
  run); ir_text pretty-prints via name_of.
- POLYMORPHIC RECURSION (f<T> calling f<List<T>>) diverges the
  worklist: v1 refuses at a specialization-count guard with a
  named message.
WHY NOT AST-CLONING MONO (considered, refused): cloning specialized
subtrees into the store re-types every clone, bloats the arenas the
fingerprints exist to keep honest, and forces typing to iterate;
the substituted-view keeps ONE body, ONE check, N lowerings — and
the pass signatures stay pure queries.

THE SLICES:
  (G1) [x] generic FNS end to end — LANDED 2026-08-31, the design
       executed as recorded: Var shapes (nine Type consumers
       answered; the mut-cell and slot laws go CONSERVATIVE on T),
       the abstract body checked ONCE (T refuses arithmetic and
       comparison through the EXISTING laws — zero new refusal
       code), exact unification with first-bind-wins, explicit
       pins (`id<int>(9)` — the no-chain dissolution held), the
       worklist draining behind the substitution view (registers
       concrete; backend/memory/interp untouched, as promised),
       `$`-mangled bodies, subst COMPOSITION proven live
       (generic-calls-generic), self-recursion terminating the
       worklist, and the 1000-spec guard standing.
       THE RED TEAM'S REAL FIND (rt15, 25 programs): `Result<T,E>`
       in a generic sig hit the conservative slot law — and fixing
       it surfaced the MIRROR hole: a call binding T = `int?`
       could smuggle a pair into a Res side past the surface law.
       The cure is the pair: Var passes slot laws ABSTRACTLY, and
       `unlawful_side` RE-JUDGES every substituted param and
       return per instantiation ("this call makes a `Result` side
       `int?`…"). Also: `spec` is a reserved word (the DSL-lexing
       family); pin-failure and duplicate-tparam cascades absorb;
       per-operand refusals are convention, pinned. RECORDED: the
       empty-list-literal-under-a-pin waits on target-typing (the
       existing "annotations arrive with generics" help names it —
       G3's literal laws). Corpus generics.av: identity over four
       types, composition, List<T>, T?, Result<T,E> with `?` and
       catch in generic bodies, 100-iteration string-spec churn —
       eval == native.
       ROUND TWO (rt16, 22 programs — the consequential-feature
       pass): found and PAID the fully-bound fallback — once pins
       (or earlier arguments) make a param concrete, the ordinary
       assignment law judges it, so `or_else<int>(null, 5)` and
       widening-into-pinned-`T?` work; an UNPINNED `null` refuses
       naming the pin. Unify absorbs an already-refused param.
       PROVEN CLEAN: four tparams; pin-only calls (unused or
       zero-arg T); T = int?/Result/List (a pair-typed T rides fn
       ABI structs correctly); deep List<List<T>>-style conflicts
       refuse; the comparison ladder survives the pinned-call
       branch everywhere; `f<T, U>` whose body cannot make a U
       refuses at the body; 200-iteration two-string pick churn
       and composed-string churn agree across engines. HONEST
       REFUSALS pinned: member-of-T, printing-T (MOVE only —
       Display rides rung 12), match/`??` mixing T with concretes.
       Arg-order dependence of inference recorded as LAW (direct
       arguments, left to right; pins lift it).
  (G2) [x] generic TYPE declarations — LANDED 2026-08-31, the
       design executed: `type Pair<A, B> = { first: A, second: B }` and
       `enum Opt2<T> { some(T) none }`.
       THE SHAPE: `Type.App(decl, args)` joins the registry — a
       generic declaration INSTANTIATED, nominal by decl + interned
       by args (the List/Opt/Res precedent generalized to USER
       names). The declared field/variant tables keep their Vars
       (the SAME Var machinery — a type decl's tparams intern
       Var(decl, ordinal, name)); `fields_of(App)`/`variants_of(App)`
       answer the declared sig SUBSTITUTED — one projection, so
       member reads, match, exhaustiveness, and construction all
       ride existing machinery. `applied_arity` learns user names
       from the declarations (the built-ins stay hard-wired until
       the fold re-measure).
       CONSTRUCTION: `Pair { first: 1, second: true }` infers by
       unifying declared field types against value types (the
       call-site law reused verbatim — same unify, same
       fully-bound fallback, same re-judged slot laws);
       `Pair<int, bool> { ... }` pins. Enum variants infer from
       the payload (`Opt2.some(5)`); unit variants need the pin
       (`Opt2<int>.none` — surface TBD at build, recorded).
       THE RES-FOLD RE-MEASURE lands here: once App exists,
       Result COULD become a built-in generic enum declaration —
       re-measure whether Type.Res folds into App or stays (the
       six-consumer arms and res_parts weigh against two shapes
       for one concept).
       LAWS: an App is a BOX (ptr_shape true); its slots re-judge
       per instantiation exactly like calls (unlawful_side grows
       App); recursion through App (a generic tree!) rides the box.
       REFUSED FOR NOW: generic type aliases, nested tparam
       shadowing (a type's T inside a fn's T scope — outer wins,
       red-team pins).
       WHAT LANDED, beyond the design: Lower.fields_of missing its
       App arm shipped a WRONG ANSWER for one probe cycle (an
       empty box + a length-read fallback — silent!) — the fix is
       the arm plus a HARDENED lit_reg (a null sig is a defect
       now, never a silent empty box). rt17 (25 programs): the
       tparam-name law now covers TYPE declarations (`type
       Box<int>` had sailed through to a printing refusal);
       bare unit variants of generic enums refuse ("nothing
       carries it" — they ride the property ladder, a path the
       design missed); dup-tparam absorbs mirror the call path.
       PROVEN both engines: swap<A,B> (an instantiation
       REVERSED), Box<Box<int>>, recursive Tree<T> with
       generic-payload unification, App-in-Result, App? via
       let-else, `with` on an App, match-generic-in-generic,
       200-churn. The field-law voices extracted (both paths, one
       wording); the slot-law help worded once.
       THE RES-FOLD RE-MEASURE, answered: Type.Res STAYS. App is
       nominal by a DECLARATION SITE and Result has none — folding
       would mint a synthetic stmt (the fake-id smell the test-
       honesty rounds purge), and `?`/fail/catch key off res_parts
       (folding would re-detect Result by name — string-matching
       the doctrine bans). Re-measure ONLY if a stdlib prelude
       with real declarations arrives at self-host.
       THE CONSTRUCTOR TAXONOMY (asked twice, settled 2026-08-31):
       instantiation is interning for EVERY constructor — nothing
       is per-X anywhere. Of the built-ins: RES is semantically a
       declaration (folds at the prelude, per the re-measure
       above); LIST is a true primitive (a growable runtime array
       is not expressible as any declaration); OPT is primitive
       for a sharper reason — its REPR forks per carried type
       (niche/pair, the never-allocates law), which no declaration
       could say. The residual cost of a constructor (~10 match
       arms across the type consumers) is the exhaustiveness
       guarantee, and it shrinks when the type-walk visitor ask
       lands.
  (G3) [x] List<T> BECOMES REAL — LANDED 2026-08-31, three moves:
       (1) the ELEMENT LAW widened to the slot law (R0's widening
       reached lists): List<Struct>, List<Enum>, List<App>, nested
       List<List<…>> all live; strings and nullables wait for
       ownership, same words as every slot. (2) `[]` IS TO LIST
       WHAT NULL IS TO OPT: Type.EmptyList inhabits every List<T>,
       adopted at the ONE widening edge with an IDENTITY lift (an
       empty array is a valid list of anything) — typed lets,
       pinned generic args, and the one honest compound lift
       ([] Ok-wraps raw; null->T?->Ok stays explicit/recorded). A
       Var never binds absence — `null` and `[]` force the pin.
       The "seed one element" wart is dead. (3) `for x in xs` —
       the ELEMENT WALK: its own node, the let-else merge lesson
       applied (non-committing branch first, the range's @recover
       second), lowered as index cell + element CELL the name
       binds through; early return unwinds it; nested walks nest;
       the range form untouched. RT18 (18 programs): shadowing,
       walks in generic bodies, list-of-enums matched per element,
       OOB reads trap identically both engines, owned churn in
       bodies. STILL WAITING (recorded): the METHOD vocabulary
       (push/find/any/all…) needs method-call surface + closures —
       rung 13's opening slice; `while let` likewise.
  (G4) recorded: bounds ride rung 12; `dyn` rides rung 12;
       for-over-lists rides G3; comprehensions ride G3.

## Traits & dyn — rung 12 (designed 2026-08-31)

Spec: Axis 3.4 (nominal behavior — `trait` is the third keyword of
the nominal/structural collapse), 4.5 (method calls resolve
PROVABLY: bounds or concrete types, never Go-style lookup), 5.x
(mono by default, `dyn` the heterogeneity hatch), 12.10 (the Error
trait rides this rung). The compiler's own bs2 source IS the
target shape: NodeSemantics/StmtSemantics — traits, impls, dyn
fields, method calls — so this rung is self-host's beating heart.

THE SLICES:
  (T1) [x] LANDED 2026-08-31 — the METHOD SURFACE + INHERENT
       IMPLS, static dispatch, the design executed with ONE
       collapse it did not predict: `X.y(args)` clashed with
       enum-variant construction (the enums primary claimed
       `p.area()` and demanded `type p`), and the cure is the
       spec's own "dot-contextual" reading — ONE parse
       (MethodCall), typing dispatching by RECEIVER KIND: a value
       routes through the impl table, a TYPE NAME constructs its
       variant (`construct_variant` moved to checks.av as the
       shared law; the VariantLit node is parse-dead, its removal
       recorded for the round). Params' types went OPTIONAL in
       the PARSE (span-window law, third user) so bare `self`
       needs no keyword — `self.x` stays an ordinary ident. A
       refused method declares its WRECKAGE (every param a hole)
       so the walks stay total — rt19 found the crash. Methods
       lower as qualified fns (`P.area`), the call as a direct
       Call with self riding seat 0 — mono, memory, backend,
       interp untouched AGAIN. N-arg construction arity law
       landed (the old single-arg gram had hidden it). RT19: 20
       programs — chains, methods-calling-methods, Result-
       returning methods with catch, shadowing a free fn, 200
       method churn, construction intact.
       ORIGINAL DESIGN NOTE —
       `impl P { fn double(self) -> int { … } }` and `p.double()`.
       - PARSE: `impl` blocks hold ordinary fn decls whose first
         param may be BARE `self` (Param.ty is already nullable —
         zero node cost); the call rides the postfix props fold
         with per-link optional argument lists (the span-window
         alignment law, third user). One node: MethodCall.
       - SELF IS A PARAM: the inner fn's sig types `self` as the
         impl's target — methods ARE fns with a qualified name
         (`P.double` — `$`-mangled like specializations), so
         declare, mono, lowering, and the backend change almost
         nowhere: a method CALL lowers as Call(qualified, [self,
         args…]). The drivers learn ONE thing: impl bodies join
         the fn walks (declare/resolve/type/lower).
       - RESOLUTION AT TYPING, not resolve: the receiver's TYPE
         names the impl (its decl name); the method table is
         (type name × method) -> fn stmt, built at declare.
       - v1 BOUNDS: none — concrete receivers only; impls on
         plain declared types (generic receivers ride T2 with
         the impl's own tparams).
  (T2) [x] LANDED 2026-08-31 — TRAITS with static dispatch, the
       design executed to the letter. A trait's sigs mint as
       BODYLESS FnDecls (the body an Error hole no pass walks) so
       declare/totality reuse the fn machinery whole; the sigs
       declare SELF-OMITTED, and `sigs_agree` compares offset by
       one seat. `impl Show for P` keys `trait_impls` as
       "Trait.Target"; TOTALITY is three laws at declare: every
       trait method answered (its absence named), no method
       beyond the trait, and both sigs agree exactly (the refusal
       names both sides: "`P.show` does not wear `Show.show`'s
       signature"). Bounds ride Param.ty on FnDecl.tparams (now
       List<Param> — the List<string> change corrupted through
       ONE stale typed-let route; decl_tparams is the projection).
       A bounded T's method call resolves through the TRAIT's sig
       at checking (`bounded_call`), and `bounds_hold` re-judges
       every instantiation — "`Q` does not implement `Show`" at
       the CALL, mono never sees an unproven bind. An unbounded
       T refuses with the spec's remedy ("add a bound —
       `<T: SomeTrait>`"). Backend/memory/interp untouched a
       FIFTH consecutive slice. RT20: 16 programs clean first
       run — totality violations, sig drift, bound churn 200×,
       inherent+trait coexistence. corpus/traits.av pins the
       story; the vertical pins carry rt20's refusal wordings.
       POLISH RECORDED: a bound is validated only at
       instantiation — a never-called `fn f<T: Bogus>` sails; the
       declare-time "is the bound a declared trait" law waits for
       T3's vtable minting, which must look bounds up anyway.
  (T3) [x] LANDED 2026-08-31 — DYN, the recorded design executed:
       the box carries [value, methods…] as an ORDINARY slot array
       (the same runtime arrays structs ride — zero new memory
       machinery), and boxing is the FOURTH widening at the one
       lifting edge (nullable, auto-Ok, empty-list, dyn) — typing
       records `widens[e]`, the target's shape picks the wrap.
       Type.Dyn(decl, name), canon "14:", `dyn Name` and
       `dyn Name?` in the type grammar (TypeRef gains `dynamic` —
       `dyn` is a bs2 RESERVED word, so the field could not wear
       the name). Trait NAMES now register before ANY sig
       resolves (three declare waves) so a struct field, fn
       param, or another trait's sig wears `dyn Show` regardless
       of order. IR grew TWO variants — the whole rung's total:
       FnAddr (a named fn's address as a value) and CallPtr (the
       indirect call) — both GENERAL machine shapes rung 13's
       closures reuse; the six consumers paid, `make vocab`
       green, the indirect fn TYPE derived from the call site's
       own registers. Typing shares ONE `trait_judged` law
       between the bound half and the dyn half of the dot-call
       surface. The Dispatch shape works: dyn struct fields, dyn
       params/returns, List<dyn Show> walked by for-each,
       mut-rebinding across impls, dyn riding Result payloads and
       catch joins, self-referential trait sigs. RT21: 30
       programs — TWO REAL FINDS fixed: (1) `impl P { fn show }`
       beside `impl Show for P`'s `show` silently shadowed one
       body at the shared symbol — now "`P.show` is declared
       twice" at declare; (2) struct FIELD slots judged by raw
       type-identity instead of the one assignment door — fields
       now `accepts` (dyn boxing AND auto-Ok reach fields). Plus
       a latent-abort class disarmed: matches spelled directly on
       fn-field call results skip exhaustiveness (the recorded
       discipline) — receiver_name and walked_elem got annotated
       binds; a new Type variant now breaks them at compile time.
       V1 SCOPE, recorded: a heterogeneous list LITERAL
       (`[P{…}, G.hot]` under `List<dyn Show>`) refuses — bs2
       shares this exact shape (box under typed lets, then
       select); the cure is the expected-type channel (backlog).
  (T4) recorded: GENERIC IMPLS (`impl Show for List<T>`, generic
       methods, impl tparams — T2's round found the refusals still
       promising "arrive with traits" after traits landed; the
       messages now say "recorded, not landed" and this entry is
       the record), shape bounds + `&` intersections, where
       clauses, default methods, associated types, @derive (Error/
       failure_tests ride it), operator traits (the Var
       compare-help names them).

## Closures & fn values — rung 13 (designed 2026-09-01)

Spec: `(params) -> body` (one arrow, one meaning), param types
inferred from call-site context (annotate only without context),
capture inferred. The self-host stake: the capability records our
own source lives on (TypeCx's fn fields) become expressible.

V1 CAPTURE LAW, narrowed by the value-semantics doctrine: capture
BY VALUE at creation — each captured name is retained-at-pack into
the closure's box; assignment to a captured name inside a lambda
REFUSES ("a closure captures values — it cannot assign the
original"; the spec's mut-ref capture waits on rung 14's interior-
mutation design and the Systems level). Sharing being unobservable
makes by-value capture semantically silent.

REPRESENTATION — everything is already paid for: a closure IS a
box `[FnAddr(lifted body), captured…]` (managed, reclaimed, slots
owned like any box); the lambda body LIFTS to a top-level fn
taking (env, params…); a call through a fn-typed value is
CallPtr(box[0], [box, args…]) — the env rides seat 0 exactly as
`self` does. A NAMED fn as a value wraps in a captureless box —
ONE uniform representation, one call path (unboxing direct calls
is a V2-class optimization; a generic fn as a value refuses in v1
— instantiate first).

THE SLICES:
  (L1) [x] LANDED 2026-09-01 — LAMBDAS + FN VALUES, the design
       executed plus TWO unplanned wins the probes demanded:
       fn-FIELD calls (`ops.describe(v)` — the capability-record
       pattern, a FIFTH fork of the one dot-call surface) and
       STRUCTURAL Fn unification (`fn(T) -> T` meets
       `fn(int) -> int` and binds T — apply/map's shape). The
       resolver grew LAMBDA FRAMES: a stack on the Resolver (no
       context threading — nested scopes just work), overlay
       FLOORS telling frame-local binds from captures, and
       TRANSITIVE capture chains (Capture through Capture) for
       nested lambdas. Binding grew LambdaParam + Capture — both
       columns answered (annotation table + env reads). The LIFT
       rides the mono worklist (three job kinds: specializations,
       lifts, WRAPPERS — a named fn boxes behind a generated
       wrapper wearing the uniform (env, args…) convention; the
       convention mismatch was caught by the corpus as an eval
       DEFECT: `double` received the box as its argument).
       Captures are BY VALUE per the doctrine; return/`?`/fail
       inside a lambda refuse through the fn_ret BARRIER; a
       refused param name still binds (wreckage). Managed
       captures ride retain-at-pack unchanged — a struct with a
       string field captured into an ESCAPING closure churned
       100 deep, both engines agreeing. rt23 16/16; the
       written-type family went Loc-based (annotations now live
       at expressions too). ZERO new IR: FnAddr + CallPtr,
       prepaid at T3, carry the whole rung.
  (L2) [x] LANDED 2026-09-01 — THE LIST VOCABULARY: map/filter/
       find/any/all as the builtin fork of the one dot-call
       surface. Typing is ONE registry law in checks.av
       (list_method_call: the fn argument's single seat IS the
       element, identity-exact; predicates answer bool; `[]`
       refuses with the typed-let remedy). Lowering is walks.av —
       one loop skeleton (opened/turn_open/turn_elem/turn_call/
       turn_close), five aftermaths; early exit is the BREAK
       IDIOM (store the index past the length); find/any/all ride
       CELLS under the mut-cell protocol, so ownership costs
       nothing new. Walks chain, nest, run inside lambdas and
       generic bodies (Var elements re-judged per specialization),
       and carry managed elements — 200-churn agreed. LANDED WITH
       IT, pulled from the backlog by rt24: THE UNIFIED POSTFIX —
       props, indexes, and calls are ONE star folded in source
       order (a three-way span merge), so `xs.map(f)[2]`,
       `pickers()[1]`, `adder(40)(2)`, and `m[k](x)` all read;
       CallValue is the node (`null()` moved from a parse error
       to a NAMED typing refusal). Multiline struct, decl, and
       list literals landed (BREAK-tolerant grams). rt24 11/11;
       corpus/walks.av is the witness; corpus 50.
  (L3) recorded: the `it` pronoun (parse-time lambda sugar), pipe
       `|>`, mut-ref captures (rung 14 + Systems), fn-value
       equality (refuses — compare_help), closure printing
       (unprintable, names its type).

## Ownership 11.5 — the design (recorded 2026-08-31)

The registry model extends, headers stay refused. THE LAW that
makes it cheap: `avra_rc_retain/release` no-op on unregistered
pointers BY CONSTRUCTION — so statics, literals, and the niche's
null pointer need no guards anywhere.

  (O1) THE RUNTIME LEARNS AGGREGATES: OwnEntry gains a KIND (str |
       array); `avra_array_new` registers rc 1; AvraArray carries
       a parallel owned-slot byte map; release at rc 0 first
       deletes the entry (reentrancy), then releases each owned
       slot (nesting recurses naturally), then frees data+struct.
       Two new fns, rows, and interp hosts: `avra_array_push_owned`
       (push + mark + retain — RETAIN-AT-PACK) and
       `avra_array_get_owned` (get + retain — every managed read
       is an owned +1, adopted by the reader's scope; aliasing
       stays intact because the POINTER is shared, only the count
       moves). Unused until O2; gate trivially green.
  (O2) THE PASS OWNS THE STORY: memory.av — is_managed grows the
       aggregate shapes; rt_owns(avra_array_new) flips true; and
       the pass REWRITES pack/read sites by REGISTER TYPES
       (push with a managed arg -> push_owned; get with a managed
       dst -> get_owned). Lowering changes NOWHERE — ownership
       stays one file's concern, and every existing corpus
       program becomes the no-premature-free proof (the evaluator
       has no memory model; agreement IS the ownership proof).
       Today's by-design leaks start releasing.
  (O3) STRINGS IN SLOTS: slot_worthy(Str) = true; the slot-law
       voices retire their string clause; `avra_strs_text` prints
       List<string>. THE WITNESS: `Result<Thing, string>` — the
       builders' own shape, the self-host critical path. rt22
       hunts use-after-free: strings through struct fields,
       Result payloads, catch joins, dyn boxes, 10k churn.
  (O2/O3 LANDINGS, 2026-09-01): the differential caught TWO real
       use-after-frees on the way in. (1) corpus/methods.av: a mut
       cell's managed content — loads adopted the box per turn and
       released it while the cell still pointed; the cure is THE
       MUT-CELL PROTOCOL, forced from O4 into O2: the cell owns
       ONE reference (seed store retains; an overwrite retains the
       incoming value FIRST — a self-store must not free what it
       keeps — then releases the old through avra_cell_release,
       which reads the slot so the pass mints no registers; loads
       are owned +1s so borrows survive overwrites; the cell
       settles when its scope does — lower_test pins the shape).
       The CELL LAW in mutation/check RETIRED with it: mut
       strings, mut string?-niches, and mut T cells all work.
       (2) corpus/foreach.av, nondeterministic: EmptyList is the
       one identity widen whose pointer is a REAL box — the caller
       judged it unmanaged while the callee's List param released
       it; EmptyList joined the managed shapes. Five test files'
       "waits for ownership" pins flipped to working stories; two
       IR goldens gained their release lines; six rt suites' stale
       no_ attacks flipped to ok_ differentials.
  (O4) recorded, each with its trigger: Opt in AGGREGATE slots
       (slot_worthy needs the registry to see the carried shape —
       niche strings in mut CELLS already work); errdefer; the
       Result register TRIPLE (P4 — after the corpus can measure
       it).

## The memory doctrine — safe + fast + beautiful (recorded 2026-09-01)

The goal, stated once: Rust's safety, Rust/Zig's speed, Swift/TS's
surface — refusing the trilemma (P6). RC is the FLOOR STRATEGY,
never the identity; the identity is GRADUAL MEMORY DISCIPLINE over
strategy-independent semantics.

THE TWO LOAD-BEARING FACTS, already built:
- Semantics are strategy-independent: the IR interpreter has no
  memory model, and eval == native over the corpus is the proof
  every strategy must re-earn. THE INTERPRETER IS A PERMANENT
  ORGAN, not bootstrap scaffolding — it is the executable spec of
  the IR, the future `avra test` JIT (Era IV), and the referee
  that lets the strategy ladder below land one rung at a time
  without semantic drift. (bs2 retires at self-host; the
  differential does not.)
- VALUE SEMANTICS, currently by accident, henceforth BY LAW:
  today no field or element assigns — only whole cells rebind —
  so sharing is UNOBSERVABLE and the compiler may copy, share, or
  move at will; cycles are unconstructible, so RC's classic leak
  cannot be written. STANDING CONSTRAINT on every future mutation
  design (interior mutation, rung 14+): `u.age = 5` demands
  exclusivity — statically proven where possible, copy-on-write
  where not — and aliasing NEVER becomes observable. A mutation
  feature that would let a program detect sharing forfeits phases
  V1/V3 and the cycle guarantee at once; refuse it.

THE LADDER (each phase differential-verified, none blocks self-host):
  (V1) value-semantics lock-in — the constraint above, enforced at
       every mutation-design review.
  (V2) OWNERSHIP INFERENCE: liveness in the memory pass — move at
       last use, cancel adjacent retain/release pairs, stack/arena
       for provably scope-local values (Lobster ~95% elision;
       Perceus precision). No surface change; pass work only.
  (V3) UNIQUENESS REUSE: a proven-unique value updates IN PLACE —
       `with` stops copying when the count is one (Koka/Roc FBIP).
       The prettiest code becomes the fastest code.
  (V4) THE SYSTEMS LEVEL: per-scope promotion to full static
       discipline — zero rc, arenas, moves proven, refusals that
       NAME the escaping value and the remedy. Gradual the way TS
       types are gradual; signatures stay clean (Application is
       the default ABI; promotion checks at boundaries, P9). The
       substrate case: request = region = free-at-once (P2).
  (V5) HARDENING: leak-accounting gate (rc_outstanding == 0 at
       exit for witness programs), ASan corpus lane, and Vale-
       style GENERATIONS on the registry (a stale release or read
       becomes a deterministic named trap, never corruption).
       CHERI rides the Hardware level when it arrives.

THE FRONTIER (explored 2026-09-01; maturity labeled, none
committed):
  (F1) TEST-WITNESSED OWNERSHIP — every module already OWES
       spec/given/then tests; run them instrumented and the
       OBSERVED lifetimes become candidate facts the compiler
       merely VERIFIES (checking a guess is far cheaper than
       inference). Profile-guided ownership; the mandated test
       culture becomes the ownership oracle. Novel as a design;
       sound only through the verifier.
  (F2) OWNERSHIP AS SUBSTRATE, NEVER SURFACE (P11 applied to
       memory) — ownership facts live in the machine projection as
       CHECKED CERTIFICATES (proof-carrying code, economics
       transformed by LLM generation: the GENERATOR proposes,
       the compiler only checks, locally and fast); the human
       projection stays annotation-free forever. A missing or
       wrong certificate degrades gracefully to the RC floor plus
       a NAMED fact request. Gradual per-VALUE, not just
       per-scope. `avra explain ownership <fn>` renders the facts
       (P7 — the magic stays visible on demand).
  (F3) THE CALL TREE IS THE LIFETIME — structured concurrency's
       task tree as the default region tree: a value lives with
       its task node; escape is explicit PROMOTION to the parent.
       For the service substrate this is the true shape of P2.
       Rides Axis 18's concurrency design.
Honest note: V2/V3 recombine published work (Perceus, Lobster,
Hylo, Nim ARC, Vale); the INVENTION is the composition — gradual
discipline over fixed semantics, certificates over annotations,
surface/substrate split, differential-refereed — the way Rust's
invention was composing Cyclone's regions and affine types
shippably. Nobody has shipped this composition.

## The capability diet (decided 2026-08-30)

The user's concern, made doctrine: the capability surface was
compounding — a verb per registry question, a mirror projection per
capability space. THE RULE NOW: **a context carries the registry
WHOLE (`types: TypeRegistry`) and never wraps a registry query in a
verb again.** Applied retroactively: `intern`, `shape_of`,
`type_name` and `rides_pointer` died from TypeCx, `shape_of` from
LowerCx, and checks.av's `opt_inner` mirror died outright — 47 call
sites now ask `cx.types.*` directly, five verbs and one mirror
gone, and every FUTURE registry query (carried, layouts, the
member-resolution query rung 13 wants) costs zero contract growth.
The test of any new capability verb from here: does it carry PASS
STATE the driver owns (walks, records, mints)? A pure query over a
value the cx can simply CARRY is not a verb. values.av's
`carried_type` stays as lowering's one pinned-catch-all projection;
the scaffold templates teach the new shape.

## The consumer's-hat review (2026-08-30, recorded)

The primary consumer (the LLM building this compiler) reviewed the
nullability arc wearing the "world's best language" hat. What it
wrote wrong FIRST TRY this session is P1's own metric failing, so
the friction list is evidence, not opinion:

THE P1 FRICTION LIST, with proposed promotions (the consumer's
recommended order was accepted as the working sequence):
1. [x] ANNOTATED `let` — LANDED 2026-08-30. `let x: T = v` parses;
   the binding HOLDS WHAT IT DECLARES: `bind_declared` records the
   type, `def_type` prefers it over inference, and the shared
   `declared_binding` law (checks.av, F2024 — ready for `mut`)
   accepts the value with widening recorded, so `let x: int? = 5`
   births the pair and `let x: int? = null` — the spec's own
   sentence — finally runs.
   FOLLOWED 2026-08-30 by `mut` annotations riding the same shared
   law (`declared_binding`, `bind_declared`, `binding_ty` covering
   both forms), the ASSIGNMENT law upgraded from raw disagreement
   to ACCEPTANCE against the binding's DECLARED type (widening at
   the assign edge — it silently never widened before), and the
   cell slot now minted from the STORED register's type
   (`mint_like`), which the annotated widen made load-bearing.
   THE FULL RED TEAM (41 programs, eight classes) then found the
   arc's best catch: an ENGINE DIVERGENCE — a for counter assigned
   into a pair cell defected in eval and mis-flagged natively,
   because the COUNTER HAD NO TYPE: def_type fell through For's
   absent value to the absorbing Error, and every law had silently
   forgiven the counter since rung 3. `let s: string = i` inside a
   for PASSED. The counter now types as the int the range law
   always implied; the absorb-detector and the divergence are
   pinned in loops and mutation adversarial records. A second
   cascade fixed the same day: check_mut now RECORDS the declared
   type before refusing a type-as-value, so later reads see the
   declaration, not the wreckage. What the build taught: the RED TEAM
   (23 programs) found ONE cascade — a TYPE as the value spoke
   through the value law AND the binding law; the binding law now
   absorbs TypeName (test-first). Non-findings by design:
   `let int: int = 1` binds the VALUE namespace (the two
   namespaces are separate), and same-scope re-`let` shadows
   intentionally (the mut law's own help recommends it). bs2 trap
   recorded: `v!.field` fails inside a match ARM (fine in fn
   bodies) — hoist the predicate. Corpus: annotated_let.av,
   eval == native. 764/764, 31 corpus.
2. [x] `return` — LANDED 2026-08-30, with the elseless MULTILINE
   statement-`if` as its companion (the guard idiom's home).
   `FnExit(gives)` joined the vocabulary (six consumers paid): the
   backend rets IN PLACE and opens a dead continuation; the memory
   pass settles EVERY open scope's debts at the site without
   popping (`exit_releases`); the interpreter answers and jumps.
   `return null` widens into a declared nullable; the TAIL value
   stays the law (return is for early exits — full divergence
   typing deferred). Capability cost under the diet: ONE Typer
   field (`fn_ret` + its bracket), ONE StmtTypeCx verb
   (`enclosing_ret`), walk_under threading the declared answer,
   and mint_shape joining StmtLowerCx — everything else is
   feature-dir rule bodies.
   WHAT THE BUILD TAUGHT, the hard way: the first statement-if
   STOLE 49 value-position ifs, and the fix is a design sentence —
   ELSELESS keeps the two if-forms unambiguous, and an OPENING
   BREAK keeps single-line arms out of the statement parse
   (the floor's @recover commits inside single-line stmt-list
   arms — now a recorded grammar-authoring law). The old
   missing-else parity debt is HALF PAID: elseless plain `if` is
   now legal; `if let` still demands its else.
   RED TEAM: 16 programs — two-deep unwinds, for-loops, nested
   guards, unreachable-tail typing, 200-iteration two-scope owned
   churn (eval == native IS the exit-release proof), exact refusal
   counts. TRIGGERS: divergence-aware blocks (a diverging last
   stmt should satisfy the block tail — the LAST piece of
   let-else); statement-if WITH else (needs a disambiguated
   form); `?` propagation now unblocked (slice d rides FnExit).
3. [x] `!= null` presence tests + effectively-final narrowing —
   LANDED 2026-08-30, the P1 sequence's third promotion. The eq
   law gained THE PRESENCE TEST (a nullable beside `null` answers
   a bool; a guarantee beside null and `null == null` refuse in
   the family's words), and NARROWING landed as sugar over
   bind-fresh, exactly as spec 10.4 bounds it:
   - `if` became CONTROL-OWNING (branches hidden from the walk,
     the MatchOpt pattern) so a branch can type under its proof.
   - THE ASK IS A FACT: the spine RECORDS which name a presence
     test asked about (`Asked`, a side-table row); `if` QUERIES
     it — features never match each other's nodes.
   - NARROWS MIRROR WIDENS: each proven read is recorded by
     typing and unwrapped by lowering at the same one edge where
     widening lifts — carried_of in, adopted out.
   - EFFECTIVELY-FINAL means a `let` or a PARAM; a `mut` never
     narrows (reassignment could lie — pinned); a pattern bind is
     already the carried value and re-asking refuses; re-asking a
     NARROWED name is told the question is answered; `!` under
     the narrow is told it insists on a guarantee.
   - THE JOIN COMPLETED while landing it: a guarantee beside ITS
     OWN nullable joins wide (`if v != null { v } else { v }` is
     `int?`), which every branching construct inherits.
   TRIGGERS: `when` conditions test presence but narrow nothing
   yet (pinned); `&&`-compound tests narrow nothing (single test
   only); both ride a later slice.
4. LEFT-CHAINED `??` — filed in the sugar backlog; spec touch,
   awaits ratification.
5. THE PARSE-RECOVERY FLOOR — "expected BREAK" at the wrong token
   is the most EXPENSIVE error class for a generating consumer (a
   wrong span means a wrong repair). The match-chain/recovery arc
   is a P1 arc, not polish.

WHAT IS ALREADY WORLD-CLASS from the consumer's seat, named so it
is amplified, not diluted: refusals that contain the fix; the
eval == native differential; visible IR (`avra ir` was used to
debug the compiler's own author this session); the ratchets
(mechanical guardrails outrank documentation for a consumer whose
failure mode is plausible-but-wrong).

FUTURE FEATURES RECORDED (ideas, not commitments — each needs a
design round when its time comes):
- TYPED HOLES as the drafting workflow: promote the error-tolerant
  parse's holes to surface (`todo` as a typed expression); the
  compiler answers each hole's expected type + in-scope candidates;
  generation becomes draft-holes-fill. Agda/Idris precedent for
  humans; nobody ships it as the GENERATION loop's interface.
- DIAGNOSTICS AS STRUCTURED EDITS: every refusal carries
  `suggested_edit { span, replacement }`; `--diagnostics=json`;
  `avra fix` applies the deterministic ones. The old tree's epic
  ratified this (its Phase 6); the clean room re-commits. Our
  remedies are already English one step from being edits.
- `avra why <span>` — PROVENANCE as a query (P10): the chain of
  facts that made an expression's type what it is, printed from
  the side tables that already hold them.
- LAYOUT AS A SOCIAL FACT: extend the never-allocates pattern —
  every representation choice queryable (`avra layout User?`) and
  CI-pinned, so guarantees are citable artifacts.
- THE TRAP LIST AS NEGATIVE SPEC: every bs2 subset trap in
  CLAUDE.md is a sentence of the form "the real Avra must make
  this impossible". TRIGGER: at self-host, the list converts into
  a test suite — the language's negative space, pinned.

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
