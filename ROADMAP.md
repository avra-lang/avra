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
    12. [x] ▲ traits & dyn — T1-T3 LANDED 2026-09-01 (dispatch,
        cross-module impls, the contract carried through dyn)
    13. [x] ▲ closures & fn values — L1-L3 LANDED 2026-09-01
        (lambdas, the walk vocabulary, the expected-type channel,
        the `it` pronoun); mut-ref captures wait on rung 14
    14. [x] ▲ interior mutation, maps, components & tables — M1-M4
        LANDED 2026-09-02 (places by copy-on-write, string-keyed
        maps, tables and components as sugar over field defaults,
        raw strings, index pairing); mutating methods and the pass-
        state pattern wait on ratification (design below)
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
       THE LAW IS ON: nullability never allocates (ONE exception
       since unboxed records: a FLAT record is a machine word with no
       spare value and no room for a flag, so its nullable is a
       one-slot box — `Repr.Boxed`, pinned by lower_test) — pinned by
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

- FIELD PUNNING: `T { name, value }` where a local of each name is
  in scope. Refused today ("expected BREAK") and it is OURS, not
  bs2's — the ledger entry that blamed bs2 was checked and moved
  here. Wanting sites: every builder that binds locals and then
  repeats their names into a literal.
- TRAIT DEFAULT METHOD BODIES. A trait carries mandatory methods
  only; a body in a trait refuses at parse. The self-host endgame
  already names what it buys — `kind()`/`message()` as defaults over
  `describe()`, and every `nothing()` / bare-`null` pass method in
  the StmtSemantics impls collapsing so an impl states only what it
  DOES.
- A PRELUDE, or QUALIFIED EXPRESSION PATHS. `grammar { … }` expands
  into constructors the source never spells, so 33 files import ten
  type names to satisfy an expansion. Avra has neither
  `grammar.Prim.Lit(…)` nor a per-package prelude, so there is no
  honest way to write it once. FIRING CONDITION: the second construct
  whose expansion names types its source does not.
- A SPEC HELPER THAT IMPORTS. `shown(src)` analyses a LONE source, so
  a spec cannot exercise anything whose program needs `use` — the
  `grammar { }` round trip had to move into a file inside the package
  to be tested at all. Wanting site:
  features/grammar_lit/tests, and every future construct whose
  expansion or surface names a package type.
- A ONCE-PER-PROCESS BINDING for a PURE fn. `avra()` is pure and was
  re-run 1532 times; the fix landed as "stop making the work
  expensive" rather than "remember the answer", because Avra has no
  lazy static and the epic forbids mutable globals — rightly, but a
  memo of a pure fn breaks neither parallelism nor incrementality.
  FIRING CONDITION: the second pure whole-program value that wants
  computing once (the dispatch table is the likely next).
- A PAIRED COMPREHENSION: `[f(i, x) for i, x in xs]`. The loop form
  landed (rung 14 M4) and 69 sites took it, but seven loops whose
  body is one push still carry a LICENSED I3 because the
  comprehension cannot pair. Wanting sites: features/builder.av (x3),
  features/decls.av, features/impls/builders.av, language/ir_text.av,
  language/typing_declare.av.

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
- NULLABLE SLOTS, the policy (rt27): a nullable is two words and
  a list slot is one — `List<int?>` built natively and ICEd at
  LLVM verification, the first program ever to build one. The
  struct-field gate (F2008) already refuses nullable slots; lists
  now refuse the same way at BOTH construction paths (the literal
  under any want, and `map` collecting a nullable answer), with
  the same voice: "arrive with ownership's next slice". Nullable
  POINTERS in lists happened to work natively and are refused
  too — unmodeled by the memory pass, consistent with F2008.
  `find`'s `T?` answer is a register, untouched. Settled laws:
  a refused call ABSORBS its arguments' hunger (one mistake, one
  voice) — THE SETTLEMENT LAW, one fn (`settled_call`) every call
  shape passes through; extracting it found `checked_call`, a
  hand copy of `seats_judged` that answered `s.ret` after an
  arity refusal where every other copy answered Error, so the
  named-fn path alone cascaded — the copy is dead; a seat that cannot feed a hungry lambda STARVES it and
  the walk-end voice speaks in the seat's words (pronoun-aware);
  callee position finds FNS before locals (`fn it` + `[3].map(it(it))`
  is 6 — the pronoun's param is shadowed as callee only); `?`
  behind the lambda barrier names the lambda (trigger: could a
  lambda's inferred answer BECOME nullable under `?`? Rust says
  yes for closures — decide with rung 14). Bare block
  expressions are not in the language (pronoun_rides' Block arm
  is dormant, kept for exhaustiveness).
- CHANNEL TRIGGERS, recorded with the landing: a want does not
  yet TRANSFORM through nested literals (`List<List<fn>>` — the
  inner literal walks before the outer consults; the refusal is
  one clean hunger voice, so nothing cascades — the fix is a
  transforming-heirs hook, wanted the day a real program nests);
  and `catch` arms are not heirs (a lambda in a catch arm stays
  hungry — same shape, same trigger).
- [x] THE EXPECTED-TYPE CHANNEL — LANDED 2026-09-01, its own
  slice. THE DESIGN: wants are a side table PLANTED before values
  walk (annotated let/mut, return, the fn body's tail) and
  DISTRIBUTED through `heirs` — NodeSemantics' fifth method: the
  sub-exprs a want flows into unchanged (if/when/match arms,
  block values) — so a lambda three arms deep hears its slot. A
  lambda that hears nothing DEFERS (hungry, quiet); the first
  judging seat RESCUES it (retype_seated — inside `accepts`, the
  one assignment door, so calls/args/fields/assignment all rescue
  for free; the walks hand their element seat directly); a lambda
  still hungry when typing ends speaks ONE refusal. List literals
  under a known slot judge every element by the door —
  heterogeneous `List<dyn Show>` literals box in place (the T3
  scope-cut repaid), lambda lists hear their seats.
  corpus/hears.av is the witness; rt25 6/6.
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

## Modules & multi-file — rung 15 (designed 2026-09-02, amended after the ps3t read; ratified 2026-09-02; 15a LANDED 2026-09-02)

Sources, in authority order: the L6 query-engine design
(`docs/2026_07_16_L6_QUERY_ENGINE_DESIGN.md`, `ps3t.8.1` — the
Salsa-shaped red-green engine, per-ITEM granularity, resolution
as a query keyed by (scope chain, visible imports), the two
fingerprints sig_fp/body_fp, symbol id = hash(qualified path +
kind), persistence in-process -> mmap'd on-disk -> daemon/LSP,
diagnostics riding with values, parallelism free by purity); the
codegen-cache design (per-fn units keyed by body_fp; ORC JIT for
the dev loop, ThinLTO for release); the manifest spec
(`spec_build_manifest.md`: [package]/[bin]/[lib]/[dependencies]);
spec Axis 16; the engine doctrine above. THE CENSUS (152 files):
309 `use path.{items}`, 32 `@std.<pkg>`; 0 aliases/globs/`export
use`; 242 `export fn`, 100 `export type`, 23 `export enum`. THE
BASELINE (bs2-compiled compiler): ~4.2 KLOC/s to check, 0.46 s
fixed startup, +0.34 s LLVM+link on 5.4k lines.

THE ONE AMENDMENT THE ps3t READ FORCES: rung 15 is not "a
workspace pass"; it is THE FIRST CONSUMER OF THE QUERY ENGINE.
The multi-file driver IS the in-process memo core (L6 P1): a `Db`
of queries with red-green verification, and the module graph is
its first multi-key query family. Building the graph any other
way would build it twice.

THE DESIGN, in laws:

1. A MODULE IS A DIRECTORY (proposed amendment to spec 16.1 —
   the owner decides). `use a.b` names the directory `a/b/`
   (every `.av` file in it, ONE namespace) or, absent that, the
   file `a/b.av`. Files inside a directory see each other without
   ceremony; `export` marks what crosses the MODULE boundary.
   Why not per-file modules (the spec's 16.1, and what the first
   draft argued): under L6 the unit of caching is the ITEM, not
   the file — a private edit in a sibling changes no sig_fp, so
   no importer recomputes — and the per-file-closure argument
   loses its teeth. What remains is the ergonomics: Go's
   directory-package (no sibling `use`, no `mod` declarations,
   no `super::`) is the shape P3 asks for and the shape the
   compiler's own 152 files are already written in — zero
   rewrite at parity. Rust's import surface (`use path.{items}`,
   `export`) stays. `mod.av` is conventional, not special: the
   file that curates a module's surface.
2. ONE SEPARATOR, ONE RESOLVER (decided by the owner): `.` is the
   path separator EVERYWHERE — modules `a.b`, packages `@std.errors`,
   members. No `/` form. `ModulePath` is ONE core type and
   `locate(path)` ONE fn (package root -> directory or file) that
   every consumer queries — `use`, the CLI, tests, the manifest.
   Spec 16.3/16.4's `@std/http` becomes `@std.http` (amendment).
3. SURFACES, NOT TREES. `surface(module)` = name -> (symbol,
   kind, sig_fp). Importers read surfaces. Exportable: fn, type,
   enum, trait, component, const — annotation-complete
   signatures; a top-level `let` is module-private.
4. ITEMS ARE THE UNIT. Interfaces are known before any body types
   (annotation-complete signatures), so bodies type per item in
   any order across files: intra-package cycles are legal (spec
   16.6's declare-then-resolve IS this), cross-package cycles
   refuse naming the cycle, and typing is parallel-ready.
5. IDENTITY IS CONTENT. Symbol id = hash(qualified path + kind)
   (`Binding.Foreign(symbol)`); types intern in ONE registry per
   Db now, content-addressed TypeIds (sh48) as the zero-churn
   swap behind the opaque-handle rule; fingerprints-at-alloc
   (already born) become body_fp; sig_fp composes them over
   signatures.
6. THE Db IS THE DRIVER: inputs `source(file)`, `flags()`;
   derived `parsed(file)` (pure: lex, parse, declare), `graph()`
   (from the `use` heads — no typing to know the program's
   shape), `surface(module)`, `analysis(file)` keyed by (content,
   imported surfaces), `lowered(item)`, `linked()`. Red-green
   fetch with early cutoff; deps discovered by execution; a
   cycle among queries is a defect (fixpoint opt-in later).
   THE ORACLE: incremental == scratch, byte-identical IR, pinned
   by a workspace test that edits and re-fetches.
7. COHERENCE: the strict orphan rule (16.5); impls are program-
   global facts collected per module.
8. VISIBLE MAGIC (P7): `avra check --time` prints per-phase ms
   and per-query hit/miss/cutoff counts; `--json` carries them.
   `make bench` gains the compiler's own source the day it
   parses. Every performance claim in this rung is a number.

THE PERFORMANCE PROGRAM (owner's bar: Rust/Zig class, "as fast
as possible"):
- ARCHITECTURE first: O(what-changed) rebuilds (L6), per-item
  early cutoff, per-file parse memo, one content-addressed cache
  root, the dev loop on ORC JIT per fn (no linker), release on
  per-fn object cache + ThinLTO. These are the 100x; they land
  through 15a-15e.
- CONSTANT FACTORS now, under bs2: the front end's known traps
  are the bootstrap's — `code_at` allocates a string per byte,
  string `.length` is strlen — and bs2-compiled binaries are
  unoptimized. The compiler links our own C (the LLVM wrapper is
  ours already), so BYTE-LEVEL primitives can be extern'd today:
  a byte-at, a substring-free scanner, a hash — a 10x on lexing
  without waiting for self-host. PF-slices: PF1 `--time` + bench
  corpus; PF2 the lexer over bytes; PF3 the PEG engine's hot
  loop (captures, memo); PF4 at self-host: LLVM -O2 + value-
  semantics COW + arenas — the compiler compiling itself.
- TARGETS, stated to be measured: now (bs2) — the compiler's own
  17k lines check under 3 s cold, `--time` proving no per-line
  regression from the module machinery; at self-host — lex+parse
  >= 5 MLOC/s per core, full check >= 1 MLOC/s per core cold,
  warm daemon edit-to-diagnostics <= 200 ms (the old tree's M1),
  parallel per item across cores.

THE SLICES:
- 15a THE KERNEL AND THE GRAPH: the `Db` memo core with red-green
  (L6 P0+P1) driving the existing per-file pipeline as coarse
  queries; directory-modules; `export`; `use path.{items}`; the
  ONE resolver; surfaces, Foreign bindings, cross-file calls,
  types, enums, traits, impls; intra-package cycles; the shared
  registry; `avra check <root>` / `run`/`build` an entry's
  closure; `--time`; the differential oracle. Red team + round.
- 15b PACKAGES: `avra.toml` per the manifest spec, path
  dependencies, `@scope.name`, cross-package cycle refusal.
- 15c THE IMPORT SURFACE: `use a.b.x` (braces optional for one
  item), `use a.b` whole-module and `as`, `export use`, glob
  (linted), the unused-`use` warning, and `avra fix use` — the
  compiler writes the imports (P10): an unresolved name that one
  visible module exports becomes a structured fix, so neither a
  person nor an LLM needs to know the layout. Avra programs get
  the syntax now; the compiler's own source adopts at parity
  (bs2 parses it until then).
- 15d FINGERPRINTS PER ITEM (L6 P3/P4): sig_fp/body_fp, resolve-
  as-a-query, per-item typeck with early cutoff — real
  incrementality.
- 15e PERSISTENCE AND THE DAEMON (L6 P5/P6, Era IV): the mmap'd
  on-disk cache namespaced by (compiler, hash-version), the warm
  daemon that IS the LSP and the agent surface.

15b DESIGNED FROM FIRST PRINCIPLES (2026-09-03; the owner ratified
the shape in conversation; each decision below is one paradox
collapsed, and the failure ledger is part of the design):

THE THESIS. The package manager disappears into the compiler,
because the compiler already knows what every package manager
guesses at: what you use, each item's signature, what changed,
what calls the OS. The design is not a better Cargo: nothing to
install, no version to pick, a lock nobody reads, a manifest of
ten lines, and a security policy that falls out of the build.

THE DECISIONS:
D1  IDENTITY IS CONTENT. A package content is a tree hash. An
    item has TWO hashes: its signature hash (NOMINAL about the
    types it mentions — structural hashing cascades one added
    field into every contract, Elm's crudeness) and its body
    hash. Hashes carry an algorithm prefix (`b3:`).
D2  TWO FILES. `avra.toml`, written by people: name, where names
    come from, which names at which label, what the program is
    granted. `avra.lock`, written by the compiler, sorted and
    mergeable: content hash, the items REACHED with signature
    hash and USE KIND, the compiler hash.
D3  THE COMPILER PROPOSES, NEVER APPLIES UNASKED. An unresolved
    `use @x.y` is a structured fix that writes the dependency
    line; `avra fix` or a flag applies it, a build never does
    (Go removed build-time go.mod edits in 1.16 for this). A
    build writes only the lock; `--locked` refuses drift; CI runs
    locked.
D4  SOURCES ARE AN ALLOWLIST. A name resolves only through a
    source the manifest lists — nothing is pulled because a file
    mentioned it. This is what keeps an autonomous agent (P2)
    from being owned by a typo.
D5  CONTRACTS BY USE KIND. Compatibility is judged per site:
    call, value, construct, read, match, implement. A field with
    a default keeps constructors compatible; an added variant
    breaks only exhaustive matches; a trait method breaks
    implementors, not callers. Contract = signature level; lock =
    body level — that split IS the pin-versus-float answer (a
    body-only fix moves the lock and touches no contract). Where
    the compiler cannot see a use it says so: a body change in a
    reached item is SHOWN, never called compatible.
D6  LABELS STAY, VERDICTS ARE ADDED. Authors choose versions;
    publishing refuses a label the surface diff refutes, naming
    the items; both are shown. "We are on 2.3" survives and the
    number stops lying. LLMs writing `http = "1.2"` from Cargo
    habit are accepted and rewritten, never refused (P1).
D7  ONE CONTENT PER NAME PER PROGRAM (Go's rule; Cargo's two-
    serdes confusion refused). Conflicts name the item.
    `[patch]` overrides a name for this program only — day one,
    because every real project forks a dependency once.
D8  NEEDS ARE COMPUTED, GRANTS ARE WRITTEN. A library never
    declares capabilities: its needs are its extern closure,
    computed and published as metadata (`avra why
    network.outbound` prints the chain). Only a PROGRAM grants,
    at the top, deny by default, over a small implicit base
    (memory, stdout). C linkage is a TAINT: a package that links C
    needs everything unless an audit statement narrows it.
    `@comptime` and any build-time execution are doors too.
D9  THE HONEST CLAIM. A dependency cannot perform an effect
    outside its computed needs. It can still hand you bad data
    (the confused deputy is not solved) — the docs say so.
D10 UPGRADES REPORT AT YOUR CALL SITES. Moving the lock prints
    only the reached items that changed; renames are detected by
    body hash ("`get` became `fetch`, same body") and their
    migrations write themselves; authored migrations apply under
    `--fix` as a previewable diff (2to3's reputation refused).
D11 EVERY BINARY EMBEDS ITS CLOSURE HASH. Provenance and
    reproducibility are a rebuild and a compare; the SBOM is a
    projection of the lock — packages stay the unit of
    PROVENANCE (license, ownership, audit, advisory, takedown)
    while items are the unit of BUILD; the lock names both.
D12 POLICY FOR AGENTS: the spec's `[permissions]` table decides
    whether adding a dependency or a grant is applied or held for
    review.
D13 WORKSPACES: a root manifest lists members; sibling path
    dependencies are UNPINNED in the lock (siblings move
    together; pinning them is noise). Own slice; the lock leaves
    the seat.
D14 TOOLCHAIN IN THE LOCK: the compiler hash; a different compiler
    warns, `--locked` refuses. No separate toolchain file.
D15 ANY GIT HOST, BY URL (https or ssh), plus `path` for a package
    inside a monorepo and `rev` as tag, branch or commit; the
    package's manifest at that path must call itself the keyed
    name. URLs NEVER appear in code (Go's most regretted choice:
    a moved repo edits every importer, and hostnames carry dots).
D16 SCOPE PATTERNS: `"@acme/*" = { git = "https://gitlab.com/acme/" }`
    resolves every package of an org in one allowlisted line.
D17 THE LOCK PINS THE COMMIT AND OUR CONTENT HASH: rev is how to
    fetch, content is what arrived; a force-pushed tag fails
    verification (go.sum's protection). Branches are intent in
    the manifest, a commit in the lock.
D18 `avra add <url>`: fetch, read the package's own name, write
    the source line and the dependency line — Go's paste-a-URL
    feel without the URL in the code.
D19 TRANSPORT IS THE SYSTEM `git`: shallow fetch of one commit
    into the content-addressed store; ssh agents and credential
    helpers work unchanged; submodules and LFS wait for a need.
    Availability: the store is the cache, `avra vendor` writes a
    READABLE tree (the Nix-store experience refused), `--offline`
    refuses the network; a registry, when one exists, is an index
    AND a mirror of git-sourced content. Nothing built stops
    building.

THE FILES:
  avra.toml:  [package] name/version · [sources] "@std/*" =
  "registry", "@acme/*" = { git = … }, "@me/x" = { git = …, path =
  … } · [dependencies] "@std/http" = "2", "@me/x" = { branch =
  "main" } · [patch] · [grants] network.outbound = [hosts] ·
  [permissions].
  avra.lock:  compiler = "b3:…" · per name: label, source { git,
  rev } or { path }, content, items = [{ name, sig, use }] ·
  per-target sections only where they differ.

THE FAILURE LEDGER (what bites, and the answer):
- same signature, different behavior: shown, `@breaking`, tests
  travel with items; never claimed compatible when a reached body
  changed.
- transitive pins rot exactly as today when a dependency's
  contract breaks in code you do not own — shrunk, not dissolved;
  labels and computed compatibility are the float.
- capability fatigue (Deno's `-A`): libraries declare nothing,
  programs grant, the base is implicit.
- manifest churn: the contract lives in the lock, sorted.
- humans talk in versions: labels stay (D6).
- unreadable stores and package-thinking compliance tools:
  `avra vendor`, SBOM export, packages as provenance (D11).
- cold builds compile dependencies from source: the signed shared
  item cache, a trust decision made explicit.
- per-target needs and signatures: deferred with conditional
  compilation; the lock has the seat.
- scope ownership without a registry is unenforced: only a
  consumer who points at a claimant is affected; the transparency
  log binds names globally later.
- immutable content still gets taken down: identity is immutable,
  availability is not; withdrawn names warn.

WHAT IS BORROWED (said out loud): content addressing (Unison),
surface diffing (Elm), hermeticity (Nix), no-install (Deno, Go),
the content store (pnpm), go.sum and the sumdb (Go), reachable
advisories (govulncheck). NEW is the combination under one
compiler that owns semantics: computed needs for a native
language, contracts by use kind replacing versions, the manifest
as a compiler output.

THE TEST SYSTEM, DESIGNED (2026-09-03; the owner asked for it after
bs2's runner: 55 s for 1372 tests, and one machine crash):

WHAT BS2 GOT WRONG, PRECISELY: each test file is its own whole-
program unit, so a suite is N compiles of the compiler (sharding
eight files per unit only trades N for N/8: warm 39 s -> 19 s, cold
471 s -> 334 s on 4 cores, per the TRD's d4jv log); concurrency was
bounded by a per-shard memory RESERVE and a retry floor (a race
still OOM-killed ~40 shards); which files share a shard is a hash
nobody chose, and results depended on neighbours; no memory of
results, so a one-line change cost a cold start. The old tree's
docs (feat_std_test.md, feat_test_runner_upgrades.md, spec Axis
24) carry the VISION this design keeps: spec/given/then with
boolean bodies and an expression diff, where-tables, should_fail,
`is`, roughly, eventually, snapshots with an accept workflow and
sanitizers, properties with derived Arbitrary<T> and shrinking,
bench with branch comparison, skip/todo, live progress, a streaming
JSON format whose fail events carry a structured fix for agents,
watch mode re-running only affected tests, coverage, @test_only.
(Axis 24's `test`/`describe`/`assert_eq` spelling is superseded by
the feature doc's spec/given/then, which 1372 tests already use.)

THE DECISIONS:
T1 ONE COMPILE. `avra test` is one invocation over the workspace
   through the query engine; tests are declarations in the module
   graph, compiled once, only their reachable closure lowered. No
   shard, no second unit — the root fix; every mitigation bs2 built
   (admission, fixture locks, striping) has nothing left to mitigate.
T2 TESTS ARE ITEMS: each `then` has an identity (body hash + the
   signature closure it reaches). With 15d: only affected tests
   re-run; green results are cached facts keyed by that hash and
   the compiler hash; coverage is a query (which exported items no
   test reaches); watch mode is the same question asked on change.
T3 COMPILE ONCE, FORK WORKERS: N workers forked from the compiled
   image (copy-on-write), each pulling ONE test at a time from a
   shared queue — a slow test never blocks a group. Scheduling is
   COST-AWARE: every test's measured duration lives in the results
   cache and the next run schedules longest-first (bs2's lesson:
   source size is a poor proxy for cost).
T4 MEMORY CANNOT RUN AWAY, BY CONSTRUCTION: a hard address-space
   limit per worker, a wall-clock budget per test (over budget
   FAILS, with the measured cost — the suite cannot drift slow
   silently), the pool sized from MEASURED free memory (min(cores,
   free / per-worker cap)), and a second `avra test` in the same
   workspace QUEUES on the first (the daemon's shape, 15e).
T5 CRASH ISOLATION WITHOUT PROCESS-PER-TEST: a trap unwinds to the
   worker and records the failure; a worker that dies is respawned,
   its test marked crashed with the signal, the run continues; the
   parent never executes test code.
T6 THE COMPILER EXPLAINS THE FAILURE: a `then` body stays a boolean
   expression; the compiler owns the tree, so a failing conjunction
   prints each conjunct's value (`a.diagnostics.length = 2`), and
   `==` over structs and lists renders a structured diff. No
   assertion vocabulary; the same rendering feeds `--json`, whose
   fail events carry a `Suggestion` when the compiler has one.
T7 DETERMINISTIC REPORTS: declaration order whatever the
   scheduling; quiet by default (one summary line, then failures);
   `--time` lists the slowest; randomness runs from a recorded
   seed; live progress and colour only on a TTY.
T8 SNAPSHOTS ARE FILES beside the spec (`<spec>.snap/<name>`),
   first run records, mismatch fails with a diff, `--accept` (all
   or one) rewrites, CI never accepts, sanitizers for volatile
   values — Axis 24.3 as written.
T9 THE DSL IS A FEATURE, THE RUNNER IS A PACKAGE: spec/given/then
   are grammar lowering each `then` to a fn registered with its
   name path, location and needs; queue, workers, budgets, reporter,
   snapshots, `where`, `should_fail`, `skip`/`todo` are
   `@std/testing` (packages/std-testing), Avra over a few externs
   (fork, pipes, limits); the compiler-specific helpers stay in
   std-avrac's testing module; the CLI is the driver only —
   `avra test` CALLS the library, and `@std/testing` ships no CLI
   of its own (the owner's rule, 2026-09-03).

STAGES: the parity rung lands T1, T9 and a minimal in-process
sequential runner with T6's expression diff (the Era III gate is
the suite green under our binary); the Era IV test rung lands T2–T5,
T7, T8, `where`, `should_fail`, `skip`/`todo`, results caching and
`--json`; later: properties with derived generators and shrinking,
`eventually`, `bench` with branch comparison, coverage, `@test_only`
(with 15c). Targets: cold run = one compile of the closure plus the
tests in parallel (seconds, against 55 today); warm run after a one-
line change under a second.

LAYOUT TAIL (2026-09-03, after rung 5): a `.name` line indented
deeper than the line it continues joins it (a method chain; a match
arm sits level with its siblings and follows a `{`, so it stays an
arm); an `else` on its own line continues the if; `or` at a line's
end continues an arm's alternatives; our lexer's helper named
`fail` (a keyword) is `refused` at parity, and `-> return x` in an
arm is spelled `-> { return x }` (a block that leaves) — the
expression form is not a construct; a trailing comma closes an
argument list (`f(a,\n    b,\n)`). CENSUS: 99 -> 82 files — the test
DSL (71) and the last few constructs (fn types in fields, extern,
generic impls). And the block's expression form is GONE: since
END, `{ x }` parses as a statement list whose tail answers, so the
`"{" v:expression "}"` alternative was redundant — and wrong: a
keyword lexes as a NAME, so `-> { return x }` read `return` as an
identifier and the @expect'd `}` hole-hit. One form, one law.

`const` LANDED, SLICE 1 (2026-09-03) — A VALUE THE COMPILER SETTLES.
`const NAME = value`, optionally annotated: the declaration emits
NOTHING and every use emits the value itself, so a const costs a
constant and never a load (corpus/consts, and the spec asserts the
IR carries no slot). A const also crosses a fn body's floor, where a
top-level `let` is refused as a run-time binding — because the
compiler settled it, and what the compiler settled is not the
program's to compute.

THE SETTLED LAW (F2045) is the whole point and the whole limit: what
may stand in a const is what the compiler can settle. Today that is
a LITERAL — a call, a name, an expression are all refused, and the
refusal says so rather than pretending. Slice 2 replaces `settles`
with the evaluator: the value lowers to a body, the IR interpreter
runs it under a step budget, and the folded value materializes. Two
laws wait there — TERMINATION (a step budget with its own voice) and
PURITY (the evaluator already refuses `extern`, which is exactly the
restriction a const wants; it becomes a stated law rather than an
accident).

Slice 1's shape is what makes slice 2 small: `settled_reg` in
lower_state.av is the ONE place a settled value becomes an
instruction, and `settled_type` in contexts.av is the ONE place its
type is read — both from the VALUE, never from a body's facts,
because every body may read a const and no body's fact table holds
another's range. Core's value protocol grew `int_of` at its second
reader, as the protocol's rule says.

THE RED-TEAM ROUND (2026-09-03) — four wrong answers, all one
species: A CONST IS A PROGRAM'S FACT, AND THREE PLACES ASKED A BODY.
(1) A const read inside a LAMBDA answered its env's capture slot —
a value nothing had put there. The crossing law now asks
`settled_binding`, and a const is returned uncaptured. (2) A `let`
shadowing a const TRAPPED inside a fn ("index -1"): the law asked
whether the NAME's first definition was a const, then handed back
the binding CURRENTLY visible — a different statement. Both the
crossing law and the hiding law now ask ONE question of a
STATEMENT (`settled_stmt`), never of a name. (3) A nullable
annotation was DROPPED at every use: the declaration emits nothing,
so the lift the annotation asked for had nowhere to happen and `A!`
extracted from a non-pack. `settled_reg` now mints the constant in
the LITERAL's shape and lifts it into what the use wears — the
declaration's lift, re-emitted per use. (4) The same annotation was
dropped across a fn floor, because the declared type lived in the
DECLARING body's fact table and every other body has its own.
`settled_type` reads the annotation's `optional` bit from the
STORE, so every body agrees. Its regression is recorded too: the
annotation law must compare the value against the DECLARED type it
computed, not ask the const for its type — that compares the value
against itself. 18 adversarial specs in
`features/consts/tests/consts_adversarial_test.av`.

THE RUNNER'S VERDICT (2026-09-03, same round) — the test binary
exited with the FAILURE COUNT, and a status is eight bits: 256
failing cases read as SUCCESS, and a case that TRAPPED killed the
process so every case after it "passed". Three laws now: the binary
prints its own tally and exits 0 or 1 (a VERDICT, never a count);
`avra_trap` exits 2, because a wreck is not a verdict; and every
case announces itself to `avra_case_begin`, so the wreck names the
case it died in and the runner says the cases after it never ran.

BS2 IS OUT OF THE LOOP (2026-09-03). The toolchain is the compiler
itself: `make avra` builds `build/avra` with the `build/avra` that is
already there, `./avra` prefers that binary, and `make gate` — 1548
specs, the corpus through both engines, idioms, vocab, scaffold —
runs with ZERO bs2 invocations (6m16 against bs2's ~3m, the trade the
owner accepted). What the switch cost:
- THE SUITE runs as five native binaries, one per package with cases
  (std-errors 4, std-toml 42, std-testing 9, std-avrac 1493, cli
  none — its only `spec` is inside a scaffold template). A green case
  says nothing now; only failures speak, and the tally closes.
- THE SCAFFOLDER met the first real divergence: our `"""` blocks are
  RAW — no interpolation, no escapes — where bs2's interpolate. The
  templates named their holes (`${name}`, `${ty}`) and filled them
  through `filled_in`, and the delimiter itself became a hole
  (`${raw}`) because a raw block cannot hold the thing that ends it.
- WHAT REMAINS of the bootstrap: one path in `./avra`, taken only
  when `build/avra` is missing. A tree with a compiler never reads
  it. The bs2 runtime copy, the wrapper install, the sidecar sweeps
  and the stamped entry are gone from the Makefile.
NEXT, in the owner's order: comptime (`const`, evaluated at compile
time — see the sugar ask below), then the suite's speed.

THE SUITE'S COST, MEASURED (2026-09-03). `avra test` runs a
package's cases as ONE native binary — `cases_entry` builds its
entry in IR, calls each case by symbol, and leaves the failure count
as the exit code. The compiler's own 1493 cases: 7.9s to analyze and
lower, ~38s of clang, ~116s to run. Where that 116s goes, measured:

  one language assembly  72ms   (of which the grammar DSL parse 66ms)
  one analyze_source     78ms   — the assembly IS the cost
  1493 cases            ~116s   = 1493 assemblies

So the suite pays to rebuild the language once per case. Two ways
out, both open:
- ONCE PER PROCESS. `avra()` is a pure fn of nothing; a language
  that could say "compute this once" would erase the whole 116s.
  Avra has no static, no lazy const, and a module-level `let` does
  not cross imports — SUGAR ASK, with this as the wanting site.
- A FASTER ENGINE. 66ms to parse 8.5KB of DSL is ~120KB/s. The
  matcher allocates a MatchResult (5 cells), a MatchState and a
  bindings list PER STEP, and every allocation joins the ownership
  registry's hash table. Packrat memoization landed (a rule at a
  cursor answers once — 7% off the compiler's own parse and a bound
  on pathological backtracking); the rest is allocation churn, and
  the honest fix is fewer boxes per step or a cheaper allocation
  path than the registry.
For comparison: bs2 runs 1548 cases in ~70s of WALL time across
eight shards — about 560s of CPU. Ours is ~124s of CPU, single
threaded.

SELF-HOSTED (2026-09-03). `avra1` (built by the bs2-hosted
compiler) builds `avra2`, which builds `avra3`, and **avra2 and
avra3 are byte-identical** — the fixed point. Each stage runs the
whole corpus, 68/68, through BOTH engines (eval and native), and
checks packages clean. The suite stayed at 1548 the whole way.

What self-hosting cost, and what each gap taught:
(1) THE ALIAS DEBT, collected. The tree was written against bs2's
list ALIASING; Avra's law is value semantics, so every write
through a handed-over list silently vanished in a self-hosted
build. The honest forms, now everywhere: a value written BACK
(`copied`, the scope stack's `taking`, the interpreter's frames
and heap, the query kernel's rows, the declaration tables), a
PLACE — a struct field a fn writes through (`Pins` for the
unifier's slots, `Frames` for the narrow stacks, `Table<T>` for
every memo), or a METHOD on the owner (`Jobs.take_lift`, which the
lift queue needed: a snapshot dropped every lambda minted mid-drain).
THE RULE the tree now obeys: a fn writes through a PARAMETER'S
FIELD PATH or its RECEIVER — never through a list it was handed,
and never through an ELEMENT it read (that is a copy).
(2) `!` ANSWERS AN OWNED REFERENCE. `avra_insist` handed back the
same box without a reference; the caller's scope released the
subject, and a memoized value died under the table still holding
it. The row says `owns_result: true` and the C retains.
(3) A CELL SETTLES BY FORGETTING. `avra_cell_release` left the
pointer in the cell, so a loop iteration that never stored released
the previous one's value again.
(4) A REGION ARM'S YIELD (see rung 13's laws) and the ESCAPES it
implies: an arm that yields a BORROWED register retains it, or the
merge and the original both release it.
(5) THE ESCAPES: `\n`, `\t` and `\r` were never unescaped — the
composed grammar carried a literal backslash-n per feature, and the
lexer refused it. The escape table is the language's, not bs2's.
(6) AN OR-RUN READS NOTHING. An arm over variants of different
arity bound from its FIRST pattern, reading payloads off the end of
a shorter value (`looks_inside`; corpus/or_arms).
(7) A GENERIC METHOD's body cannot yet name its impl's type
parameter in a local annotation (`let held: T? = …` inside
`impl Table<T>`) — the signature scope does not reach the body.
Recorded; the workaround is the un-annotated tail.
THE GUARD that found half of these: `AVRA_RC_GUARD=1` keeps a
released box registered and poisoned, traps the second release, and
prints the box's whole retain/release history with the caller's
address. It stays in the runtime, one getenv when off.

RUNG 13 LANDED (2026-09-03) — THE WHOLE-PROGRAM LOWERING, proved
by lowering the compiler itself. `./avra build packages/cli` walked
1718 bodies and every step of it named a law the small corpus never
reached:
(1) THE ENTRY IS ITS STATEMENTS. A package's entry file runs its
top-level statements; a `fn main()` is an ordinary declaration
nobody calls, so the CLI's entry now IS the composition (bs2 runs
top-level statements first, so one file serves both toolchains).
(2) A LIFTED BODY CARRIES ITS FILE. A lambda's symbol was its node
id alone, which is unique in ONE file — two files' `l217` collided
and LLVM tolerated the drift until the verifier refused. A lifted
body now takes its file's module and stem (`Decls.lifted_symbol`,
`stem_of`), as every named body already did.
(3) A VALUELESS BLOCK YIELDS ITS OWN TYPE. Lowering typed the tail
of every valueless block as the FN's promise (right for a block
that departed, wrong for a statement block, whose type is void):
the merge phi disagreed with its arms. `block_reg` takes the type
typing settled.
(4) AN ARM'S YIELD WEARS THE REGION'S TYPE. A LEAVING arm
(`{ return x }`) yields the fn's promise into a merge typed by the
staying arms; `arm_yield` gives the region's hollow instead —
nothing reads a departed arm's value.
(5) EITHER SIDE MAY BE THE NULLABLE. `a == b` across presence
tested the LEFT for presence, so `it.file == file` read a presence
pair out of a plain string. The nullable side leads now, whichever
side wrote it (corpus/nullable_eq).
(6) A LIST'S ELEMENT OBEYS THE SLOT LAW. `List` alone declared
`slots = false`, so `List<int?>` was expressible by ANNOTATION and
lowered a register pair into an i64 cell — silently. The row says
`true`; the written type is refused where it is written, and the
value beneath it says nothing more (`want_refused` — one mistake,
one voice).
(7) THE CLOSURE LAW: before emission, every name a program's steps
call must be one the module will declare — a lowered body, a
runtime row, or an extern (`body_symbol`, `hosted_symbol`,
`unheld_name`). A missing body was a null function pointer and a
segfault inside LLVM; it is a named defect now.
Also: the drain guard counts DISTINCT bodies against a ceiling only
polymorphic recursion can climb (1000 pops refused the compiler's
own 1718 bodies).

PARITY RUNG 12 LANDED (2026-09-03) — THE HOST SEAM: `extern fn`.
`extern fn name(p: T, …) -> R` is a statement of the fns feature
(`Stmt.ExternFn`, `ExternParts`): a fn declaration (`DeclKind.Fn`)
with no body — its sig from its annotations, its SYMBOL its bare
name (`Decls.is_extern`, `symbol`), never lowered. A call to one
lowers as a runtime call (`CallRt`/`CallRtVoid` by the answer's
shape) — THE VOCABULARY SEAM RULE: an extern is DATA, a row: the
program's externs are rows (`extern_rows`: name, `rt_kind_of` per
seat — scalars are words, pointer shapes pointers, void nothing)
carried on `Lowered.externs`; the emitter admits their names beside
the registry's (`unknown_callee`), the backend DECLARES them like
the runtime's rows (`declare_externs`) and coerces their seats by
the same table (`callee_sig`), the memory pass owns nothing of
theirs, and the evaluator REFUSES them by name ("`avra_now_ns` is
extern — the evaluator cannot host it; build natively"). `ptr` is
a word of the language (`Type.Ptr`): an opaque host pointer,
slot-worthy, unmanaged, a pointer to the backend, comparable to
nothing — twenty-five arms learned it. THE HOST RUNTIME
(runtime/avra_runtime.c) grew the bodies the CLI leans on —
`println`/`eprintln`, `avra_now_ns`, `avra_process_exit`,
`avra_selfhost_file_exists`/`read_file`/`write_file` (through a
temp file and a rename), `avra_shell_exec_status`, `avra_mkdir_p`,
`avra_host_is_dir`/`list_dir` (newline-joined) — written to the
CLI's reading of each, not copied. bs2 takes `extern fn println`
too (probed), so the CLI declares its printing externs in both
dialects. A NATIVE CORPUS LANE (`corpus/native/`, in the gate)
proves programs the evaluator cannot run. CENSUS: std-avrac 4 -> 2
files (the vendored spec_test alone), cli 15 -> 3 (bs2's `mod`
stub and one line of std-cli). Suite 1542.

PARITY RUNG 11 LANDED (2026-09-03) — GENERIC IMPLS, THE RECEIVER,
AND THE PACKAGE SEAM. (1) `impl Arena<N> { … }` LANDS: an impl's
type parameters parse (after either name) and are the TARGET's own
— its methods declare under the target's Vars (`enter_target_scope`,
`impl_self_type` = the App over its Vars), the impl decl REMEMBERS
its target (`Decls.targets`; an impl's `tparams` are its target's,
so `lowers_plain` waits), a call on an instantiated receiver
(`Arena<Expr>`) substitutes the sig by the receiver's arguments and
RECORDS the instantiation (`instantiated_sig`), and the body lowers
once per instantiation through the generic machinery unchanged.
A trait impl over a generic type stays recorded. (2) THE RECEIVER
IS A PLACE: a method writes through `self` (`self.n = v`,
`self.xs.push(v)` — `through_receiver` at resolve, `is_mut_at`,
`unique_box` handing a param's register through); 61 alias-trick
sites in the tree rewrote to it (`self.field.push(v)`, which bs2
takes), and a `mut` bound to a PARAMETER'S FIELD PATH is a BORROW
(`borrows_field`/`mark_borrow`/`unique_box`'s Load) — both entries
of THE bs2 DEBT LEDGER below, with their post-self-host fix. (3)
HUNGER, completed: a hungry node remembers its parameter scope
(`ParamScope`; starving under an empty scope crashed the census —
lldb named `target_type`), a generic construction with nothing
pinned goes hungry (`unfed_construction`), a generic unit variant
reads the want, a list literal's leading element skips the hungry,
and a LEAVING arm (`{ return … }`) joins with anything (`leaves`,
`stays`). (4) THE PACKAGE SEAM: `holder_of_path` compared a
dependency's source path length against the ROOT's even when the
root did not hold the file, so any dependency shorter than the root
lost to it — a dependency's own names resolved only by luck of path
length (found by checking the compiler with three dependencies);
and a dependency's own local `use` paths now QUALIFY by its package
(`qualified`). `dyn` dispatch reads the contract's DECLARATION
(`trait_sig_under`), never a name in the caller's scope. (5) The
tree, made honest by its own compiler: `.Call(_, _)` (a wrong-arity
pattern bs2 took), five `break`/`continue` sites restructured, the
scalar-nullable fields retyped (`deps_at: Span?`, `Program.entry:
Entry?`), `string(n)` and `owned`/`none` gone, seven helper names
unclashed, the TOML package's own `break`. CENSUS: std-avrac 27 ->
4 files — llvm_api.av and the vendored spec_test, all `extern fn`;
std-toml, std-errors, std-testing CLEAN; cli 15 (externs and the
printing fns). Suite 1538, corpus/generic_impls proves two
instantiations native.

THE bs2 DEBT LEDGER (opened 2026-09-03, the owner's order: every
problem borrowed from bs2 is written here at discovery and FIXED,
all of them, once the compiler compiles itself). Each line: the
habit or law, where it lives, and the fix. The bootstrap dialect is
the INTERSECTION of bs2 and Avra; each entry is a place the two
disagree and the tree spells bs2's side.
- THE ALIAS BORROW. bs2 has no `mut` parameters and lists alias, so
  a state fn writes `mut xs = m.field; xs.push(v)` and the caller's
  record changes. Avra's law is value semantics (copy-on-write);
  the tree's 38 free state fns (interp.av `m.frames`, resolve.av
  `r.overlays`, workspace.av `ws.specs`, llvm.av `em.vals`, …)
  rely on the alias. HONORED as a `borrow`: a `mut` bound to a
  PARAMETER'S FIELD PATH writes through (`borrows_field`,
  `mark_borrow`, `unique_box`'s Load); a local's field copies. FIX:
  make each state fn a METHOD (`impl Machine { fn run_body(self,
  …) }` — bs2's #1377 ICE is why they are free fns) writing
  `self.field.push(v)`, then delete the borrow and refuse a `mut`
  bound to a parameter's path.
- RECEIVER ALIASING. A method writes through `self` (`self.n = v`,
  `self.xs.push(v)`) into the caller's box without opening it
  unique — `let d = c; d.set(5)` changes `c`, which the V1 law
  ("aliasing never observable", ROADMAP: the memory doctrine)
  forbids. Needed because the compiler's methods mutate their
  state structs through `self` (61 sites rewritten from the alias
  trick to `self.field.push(v)`, which bs2 accepts). FIX: infer
  `mut self` (a method that writes through self), require a mut
  place at the call, open it unique before the call.
- ~~`Result.Ok(v)` / `Result.Err(e)` (89 sites)~~ — PAID 2026-09-04:
  92 sites rewritten to `.Ok(v)` / `.Err(e)`. The type-receiver form
  stays the ordinary enum surface, and results_test still proves it
  by NAME beside the dot — the two spellings are one feature's two
  faces, not a migration.
- ~~`for (j, v) in xs.enumerate()` (77 sites)~~ — PAID 2026-09-04: 69
  loops now spell `for j, v in xs` (rung 14 M4), and 32 LICENSED I3
  exceptions retired with them. What REMAINS licensed is the honest
  half: a loop whose body is one push, where a PAIRED COMPREHENSION
  (`[f(i, x) for i, x in xs]`) would say it and does not parse — our
  own sugar backlog, not bs2's.
- `code_at(s, i)` = `s.substring(i, i + 1).char_code()` (bs2's
  `char_code` drops its index): an allocation per byte in every
  scanner. FIX: `s.char_code(i)` (landed in rung 8) everywhere;
  `code_at` becomes it.
- `s.length` is `strlen` (hoisted at 8+ sites, I27). FIX:
  length-carrying strings in the runtime; the ratchet retires.
- Typed ids interchangeable, pattern and construction arity
  unchecked (the `.Call(_, _)` in program.av survived bs2; Avra
  refused it). FIX: none needed — Avra checks; the I25 ratchet
  retires at self-host.
- The reserved words bs2 lexes even as fields/locals (`spec`,
  `given`, `then`, `none`, `level`, `owned`): renames across the
  tree (`suite`, `group`, `tier`, `runs`, `moved`). FIX: none
  needed; the renames stand.
- Test-string `${`, struct literals pinned under `let` in free-fn
  argument lists and closure-field calls, `dyn` boxing only under
  typed lets, explicit `<N>` pins, the `it` pronoun's limits, the
  closure-field-call discipline, comprehension limits, one-line
  enums, multi-line `use`, `.reverse()` in place, `contains` by
  identity, `is_empty` on strings, module-level `let` across files,
  trait default bodies — every entry of CLAUDE.md's "bs2 subset
  notes" is a borrowed constraint on the tree; each is lifted the
  day bs2 retires, and the notes section is deleted with it.
- FIELD PUNNING (`T { name, value }`, two sites in std-cli): bs2 has
  it; Avra's `NAME {` cannot without a lexical class for type names —
  `null { v }` would be a literal and every `if … != null { v }`
  would break. The two sites spell `name: name`. FIX: decide the
  type-name class (Capitalized?) with the spec, then punning lands.
- bs2's `mod x` stub (cli/src/main.av): a directory IS a module in
  Avra; `mod x` parses as `use x.{}` (the module named, nothing
  imported). FIX: delete the line at self-host.
- The vendored `spec_test` feature and `std-cli`: bs2's test runner
  and CLI. FIX: `avra test` (landed) replaces the runner; delete
  both packages at self-host.
- THE GENERIC ANSWER'S IDENTITY: a field read or `with` on a
  generic method's answer ICEs bs2 ("unknown struct"), so the tree
  binds an annotated let first (`memory.av`'s scope reads). And a
  generic impl's body cannot name its own `T` in an annotation.
  FIX: none needed — Avra types both; delete the extra binds when
  bs2 goes.
- ~~THE `"}"` LITERAL~~ — PAID 2026-09-04: ours lexes a `}` inside a
  string, so `closing_brace` reads `index_of("}")` and says what it
  means. Its companion paid with it: 206 sites across 31 files spelled
  a literal `${` as `"$" + "{"` because bs2 has no `\$` escape. Ours
  does, and they say `\${` now.
- THE ELEMENT WRITE (`mut x = xs[i]; x.push(v)`, ~12 sites, all
  rewritten): bs2 aliases an element, so mutating the copy changed
  the container. Avra copies. FIX: none needed — the tree now
  writes the value BACK, or reaches the place through a field or a
  receiver. The pattern is recorded in DOGFOODING; delete this
  entry when bs2 goes.
- THE STAMPED ENTRY (`packages/cli/src/main_stamped.av`, written by
  `./avra` and EXCLUDED from the cli package's own manifest): bs2
  keys a run's cache by the entry file's bytes alone, so the front
  door regenerates an entry carrying a hash of every package source.
  Our compiler needs no such stamp — it keys each file. FIX: delete
  the generator, the `exclude`, and the `./avra` shim at self-host;
  `avra` is then the built binary.
- `extern fn println` / `eprintln` in the compiler's own entry and
  commands: bs2 has no host surface of its own, so the tree declares
  the C prototypes it links against. FIX: a `@std/io` package over
  the same externs, so a program prints without declaring C.

PARITY RUNG 10 LANDED (2026-09-03) — SLOTS: a nullable POINTER is
its own word. THE SLOT LAW sees through a nullable to what it
carries (`slot_worthy(types, sh)`: `Opt(inner)` qualifies when
`inner` rides a pointer — the field, the enum payload, the list
element, the map value and the Result side all read one law; a
scalar nullable is still a register pair and still waits): the
slot holds the pointer, absence the null one, and every read
through `?.`, `??`, `!` and `match` is the niche verbs unchanged;
the memory pass retains and releases through NULL for free. The
chain FLATTENS: `a?.b` where `b` is itself nullable IS the chain's
answer (one absence, never two — the lowering reads a field
already wearing the answer straight, adopts one wearing the
carried type, and defects on anything else). THE EMPTIES: `[]`
unifies into a `List<T>` seat and `{}` into a `Map` seat without
pinning (a variant payload, a generic call), `join_of` adopts an
empty beside a list (`if b { [7] } else { [] }`), and a list
literal's leading NON-EMPTY element names the type so `[[1], [],
[2]]` types. A `null` unifies into a concrete nullable seat and a
PRESENT value widens into one. THE NARROWING IS INVISIBLE: `v!`
and `v ?? x` on a read a narrowing proved present are the value
itself, silently (the compiler's own `if x != null { … x! … }`
idiom, everywhere); `??` on a value that was never nullable warns
(`type.coalesce_never` F2044: "never fires") and answers it; a
chain `a ?? b ?? c` stays nullable until the last. EQUALITY
THROUGH PRESENCE: `T? == T` and `T? == T?` (`!=` too) compare the
carried values when both are present, absent equals only absence
— the lowering nests `presence_region` (now the shared verb in
values.av). `with` on its own line continues the literal. THE
RUNG 9 REVIEW, folded in: a builtin's row is found BY KIND (a
program's enum named like a row reached the row — a crash);
`pinned_by_want` pins only when the want IS this declaration's
(`wants_decl`: the row rebuilt over the want's args, or an App of
the decl) and looks through a nullable want; a builtin's signature
is declared AT ADMISSION from its row (no typer, no file-0
ritual); a generic unit variant (`Maybe.none`) reads the want;
HUNGER BUBBLES — a node whose kid or HEIR is hungry is hungry, and
the feed re-runs every hungry node beneath (kids and the arms a
control node hides), so `take(if b { .Ok(3) } else { .Err("x") })`
and `[[(x) -> x + 1]]` under a typed let both type; the seat law
is ONE fn (`seats_fit`) under `seats_judged`, `seated` and the
literal; the pop-flip was an UNVERIFIED expectation (the homes
slice's gate stopped at idioms and never ran the corpus), now
pinned. CENSUS: 69 -> 27 files — what remains is generic impls
(`Arena<N>`, 10 files), `break`/`continue`, `extern fn`, and a
handful of singles. Suite 1527, corpus/slots proves the niche in a
field, a payload and a list, and equality through presence,
native.

PARITY RUNG 9 LANDED (2026-09-03) — THE VALUE WORDS: `Result`
construction, `+` on text, `==` on unit enums, and the HUNGER
PROTOCOL generalized. THE EPIC (2026_06_08_ERROR_HANDLING_EPIC,
read at the owner's word): produce is `fail e` and the implicit
Ok; an explicit Result value is spelled with the BARE variants
`.Ok(x)` / `.Err(e)` — a want-driven literal. So (1) THE VARIANT
LITERAL: `.name(args)` is a node of the enums feature
(`Expr.VariantLit`, F2043): the WANT names the enum (a Result's
sides through the bridge, a generic's through substitution), the
variant must be its, the payloads seat exactly (`seated`), and
the answer is the want itself; lowering is the tagged value. (2)
`Result` IS A DECLARATION — the language's own: `DeclKind.Builtin`,
minted once from the type rows that answer variants (a TypeRow's
new `variants` column — `no_variants` for List and Map, the bridge
for Result), bound in every file's namespace LAST and silently
(F3008 already reserves the name), its parts read from the ROW
(`tparams` by arity, `sig` from `variants` over its own Vars), so
`Result.Ok(v)` rides the ordinary `Type.variant(args)` surface;
`instantiated` reads a Var no payload pinned FROM THE WANT
(`pinned_by_want`, the registry's `args_of` projection) and a
builtin builds its type through its row (`Type.Res`, never a
parallel App). (3) THE HUNGER PROTOCOL, generalized: a rule that
needs a want it lacks goes hungry silently; the ONE agreement door
FEEDS it (`heard` -> `cx.feed`: the want planted, the rule re-run,
kids already typed) — so `.Ok(.Ok(1))`, `take(.Ok(5))` and `[.red,
.blue]` under `List<C>` all type through `accepts` alone; at the
walk's end every rule still hungry is re-run STARVING and speaks
in ITS OWN words (the lambda's `unfed_lambda` moved home to
closures/check.av — the driver no longer imports a feature's
voice). (4) `+` on text (`avra_str_concat`, one row/body/host; the
left side decides the seat) and `==`/`!=` on an enum whose
variants carry nothing (by TAG — `compares_by_value` beside
`comparable` in checks.av; `same_value` compares tags; a payload
enum still refuses "match on it instead"); the compiler's own
`Type`-value comparisons rewritten to predicates (`wears`,
`types_disagree`) since the language refuses them. Rung 7's
`Result.Ok` spelling stays valid; the corpus and new code use the
epic's. CENSUS: 114 -> 69 files (F3000 x26 gone, F2000 x44 ->
12). Suite 1503 (results +9, enums +4, spine +4).

PARITY RUNG 8 LANDED (2026-09-03) — THE BUILT-IN VOCABULARY, as
ROWS. Twenty method rows, each the owning feature's (the seam
rule: a method is DATA — a row of `takes | check | lower` — and a
runtime fn is a row of `rt_sigs()` plus one C body plus one
interpreter host arm; nothing dispatches on a name). LISTS
(features/lists): `contains`, `index_of` (the walk skeleton
without a fn box — `same_value`, the `==` law's `comparable`
shared from checks.av so a list of records REFUSES like `==`
does, never compares pointers), `push`, `pop`, `set` (the mut-place
prelude `opened_place`, shared), `is_empty` (length against
zero), `first`/`last` (an Opt cell seeded absent, the edge slot
adopted), `concat`/`slice`/`join` (one runtime call each, owned
answers), `enumerate` (the list ITSELF — a paired `for` head does
the pairing, so `for (i, x) in xs.enumerate()` and `for i, x in
xs` are one walk). TEXT (features/str_lit): `contains`,
`starts_with`, `ends_with`, `index_of`, `substring`, `split`,
`replace`, `char_code` (0 or 1 args — the runtime takes the
INDEX, unlike bs2's), `trim` — one runtime call each, byte
offsets, ends exclusive, clamped; `split` keeps a leading empty
piece, drops one trailing, splits empty text to nothing and keeps
the text whole under an empty separator — the interpreter cuts
it by hand (`pieces_of`) so eval == native (bs2's own `split("")`
disagrees, found by the probes). The typing rules share two
preludes (`elem_held`, `seated`: exactly N seats, each accepted —
a wrong argument speaks and the row still answers) and the walks'
skeleton split into the loop (`Walk`) and the fn box (`Box`) so
the scans reuse it. RUNTIME: `avra_array_pop` (+ `_owned` twin:
the slot's reference MOVES to the caller), `avra_array_concat`,
`avra_array_slice` (copies retain owned slots), nine `avra_str_*`
bodies; twelve `RtHost` arms. The interpreter gained
`fresh_array`/`with_array`/`whole`/`verdict`/`clamped` as its
vocabulary. MEASURED: the census's first failure moved off F2030
for 61 files (73 -> 12; the twelve left are cross-file `impl`
blocks on core types — the orphan rule, next). Suite 1484 (lists
+13, str_lit +9), corpus/vocabulary proves every row native.

PARITY RUNG 7 LANDED (2026-09-03) — PARSE CLOSURE. (a) fn TYPES
omit the answer — `fn(int)`, `fn()` — the closures gram's
`( "->" fr:type )?`; `void_ref` on the shared authoring surface
(features/builder.av) with the Builder verb `answer(i)` (the
written answer or void — fns and fn types read it alike);
`name_of` spells `fn(int)` for a void answer, the writable form.
(b) `let _ = e` — the DISCARD statement: `Stmt.Discard`, never a
block's answer (the review caught the first draft, an
`ExprStmt`, ANSWERING at a block's tail — `fn f() { let _ = 5 }`
refused as answering int); its meaning is the expression
statement's. Ordered FIRST of the three `let` branches, WITHOUT
`@recover` — a recovering first branch on a shared anchor
swallows its siblings (352 tests; the law rewritten in CLAUDE.md
with the mechanism: a committed miss recovers into a HIT and a
hit ends the choice). (c) `level` is spec-reserved (F3002), so
the compiler's own identifiers moved off it — `Scope.tier`,
`ScopeEnter(tier: Level)`, `joined`'s `runs`, the manifest's
`opt_level`; `tier` is the one value word (`enclosing_tier`,
`tier_word`). (d) A package REACHES itself: `reaches(ws, from,
k)` = its own key or a manifest dependency — the compiler's 71
test files `use @std.avrac.…` from inside @std/avrac. CENSUS: 8
-> 4 files fail to parse (`extern fn` ×3, `impl Arena<N>`), and
the first failure moved to TYPE for 126 files. Suite 1461.

PARITY RUNG 6 LANDED (2026-09-03) — THE TEST DSL, and `avra test`
(T1 and T9 of the test system; the minimal in-process runner).
THE MODEL: `spec "…" { given "…" { then "…" { body } } }` is ONE
declaration statement (features/specs — gram, builders, statement
semantics), and each `then` is a CASE: a declaration
(`DeclKind.Case`) whose root is its body, minted under the spec's
name with its group, declared as a zero-parameter fn answering
`bool` (typing_declare), and typed by the one body law with one
voice — `type.case` F2042, "a `then` answers a `bool`, this one
answers `int`". A spec nests in nothing (`resolve.nested_spec`
F3022, the shared nested-declaration voice). Cases are ordinary
declarations everywhere else: the symbol table names them
`spec$N`, lowering gives them bodies, the interpreter runs one by
symbol (`run_symbol`), and the program LISTS them in written order
(`Program.cases()` -> `TestCase { suite, group, name, file, line,
symbol }`). THE ENTRY LAW learned one thing: a case is reached by
nothing, so a test run lowers EVERY declared body
(`Program.cases_checked()` = the union with no entry) where a run
lowers the entry and what it reaches — one `checked_lowering`,
two callers. `@std/testing` (packages/std-testing) is a LIBRARY
with no compiler types and no CLI: `Outcome`, `render` (suite /
given headers, ✓/✗ lines, the failing case's note and file:line,
`N/M tests passed`), `all_passed`; `avra test <file|package>` is
ONE CLI file that analyzes once, lowers once, runs each case by
symbol and prints the library's report, exit 1 on any failure.
FOUND ON THE WAY: bs2 reserves `spec`, `given` and `then` even as
STRUCT FIELD names (CLAUDE.md); a miscounted variant pattern
(`.A(x)` against two payloads — refused by the arm law, F-coded)
still reached COVERAGE, whose rows were then ragged and
`hole_first` read past an empty row — an UNNAMED out-of-bounds
crash of the whole package check, found by lldb (`b
avra_runtime_errorf`); `padded` is now total (pad with holes or
cut to the arity), so a row always has one pattern per column.
CENSUS after this rung: 8 files fail to PARSE (fn types without
an answer `fn(A, B)` in fields and params, `impl Arena<N>`,
`extern fn`, `let _ =`), and the first failure moved to RESOLVE
for 177 files — most of them cascades of those eight (a file that
does not parse exports nothing, so 83 importers say "`features`
does not export `NodeSemantics`") plus 71 test files that `use
@std.avrac.…`, the package's OWN name (the self-dependency law,
next). THE ROUNDS (red team + review, same day): a runaway recursion
SIGSEGV'd the whole run (bs2's stack guard, exit 139, no verdict
printed) — the machine now bounds its own depth (`call_limit`,
400: the interpreter recurses on the host stack, and a bs2 test
WORKER thread holds 600–700 nested calls where the main thread
holds 1900+; a single-unit run rides the main thread, so the same
spec passed alone and crashed the shard — CLAUDE.md) and answers
"recursion too deep — 400 nested calls" as the case's note; the
module-file law (F0902) was skipped under `test` because the
union lowered "every body" by dropping the entry — `union` now
takes `every` beside `entry`, so a test run keeps the entry's laws
(`Program.cases_checked` = `checked_from(entry, every: true)`);
a `then` without its body cascaded from the `given` line —
`then_case` and `given_group` now `@recover`/`@expect` at their
own tails, so the mistake is blamed at its token and the next
case still parses (two structural mistakes, a nested `given` or
a `then` under a `then`, still cost one cascade "expected EOF" —
the honest floor without a brace-aware sync); a `then` may stand
directly under the spec (the old DSL's shape; its group is the
empty word and gets no `given` line); a group names each case
ONCE (`resolve.duplicate_case` F3023, the shared member voice:
"`s / g` declares `t` more than once"); warnings render under
`test` as under `run`. THE REVIEW moved the case law home
(`features/specs/check.av`: `fits_case` judges, `case_answers`
speaks; the driver only brackets — `answering(t, want, walk)` is
the ONE fn-return bracket, shared by fn bodies and cases, and the
case's want is read from the sig it declared), collapsed the
runner's five copied fields into `@std/testing`'s `CaseRef`
(avrac's `TestCase = { at: CaseRef, symbol }`; the library's
`Outcome = { at, verdict: Verdict }` — `Passed`/`Failed(note)`, no
sentinel pair; `words(at)` is the one-line listing form, which
avrac projects as `case_words` because bs2 test shards die reading
a foreign struct's fields — CLAUDE.md's standing trap), gave
`@std/testing` its own spec file (the report's header, change and
summary laws), pinned F2042/F3022/F3023 by code, pinned the
ragged-row crash (`.Rect(w)` against two payloads: refused once,
never crashes), and named `body_named`/`blanks`-as-`filled`/
`case_fps`. KNOWN, NOT DONE: `?`/`fail` inside a `then` get the
fn-shaped help ("declare the answer fallible"); `0/0` exits 0; a
token class still speaks as its class name ("expected STRING").
Suite 1454 (specs +19, testing +8, patterns +1), corpus/specs
proves a spec block is a declaration the program around it runs
past.

PARITY RUNG 5 LANDED (2026-09-03) — COMPREHENSIONS. `[elem for
name in source if cond]` and `[elem for (index, name) in source]`
are one Expr (`Comp`) the lists feature owns, its branch tried
before the literal's (its failure at `for` is a deferred break, so
a plain list still hits). The SOURCE is a kid (resolved outside the
binders); the element and the filter are heirs walked under them —
the binders ride the PATTERN-BIND machinery (`Binding.Pattern(elem,
j)` and `(cond, j)`, index first when named), so no new binding
currency and no statement-keyed slot. Typing: the source is a list
(an empty `[]` has no element — refused, F2041), the filter a bool,
the element slot-worthy, the answer `List<elem type>`; `?` inside
propagates like anywhere. Lowering: a fresh box, one loop over the
source, each turn binding the element register (and the index)
and pushing when the filter's region holds; the memory pass owns
the pushes by the element type as it does for literals. FOUND: the
join law lacked the Result twin of its nullable rule — `if c { v }
else { fail e }` in tail position typed the leaving branch as the
fn's promise and refused against `v`; a value beside ITS OWN Result
now joins to the Result and the auto-Ok lift wraps it at the same
edge (a leaving branch in an if-chain answers, too). corpus/
comprehensions.av; 11 specs. CENSUS: files with a parse failure
135 -> 99, comprehensions 45 -> 0; what remains is the test DSL
(71 — every test file) and a layout tail (leading-dot chain lines
16, `else` on its own line, the `fail` keyword clash in our lexer).

PARITY RUNG 4 LANDED (2026-09-03) — LAYOUT. THE LINE LAW (lexer):
a line break separates except directly inside `(` or `[` (a brace
opened inside them separates again — a `match` written inside a
call keeps its arms on their lines) and after a token that promises
more (a binary operator, `=`, `->`, `,`); an unclosed bracket runs
to the file's end, one refusal (pinned). A bare `return` leaves a
void fn and refuses where a value was declared. A BLOCK IS AN
EXPRESSION wherever one may stand — a match arm's `-> { … }`, a
`let`'s value — reached through the map's brace: the empty map is
its own branch and the full map requires `key :` before its
@expect'd close, so the block alternative can be tried (an @expect
is a HOLE-HIT, not a break: a branch whose only remaining item is
@expect'd always wins). IF-CHAINS: the statement form takes `else
{ … }` and `else if …` (a chain need not end in else), the
expression form chains `else if` too, and a chain in TAIL position
— a fn body's, a block's, the program's — is the if-expression when
every branch answers (the node store's `answered` law, one place
for blocks and the top level; a one-expression branch stays bare so
the IR is unchanged). FOUND BY IT: a latent id-family bug — a
pinned generic call handed a DeclId to a StmtId verb, invisible in
lone files and a crash in a whole-package check once the table
grew (CLAUDE.md); the verb now takes the call's own site. corpus/
layout.av; 13 specs; three cascade pins re-pinned to the bracket
law. CENSUS: files with a parse failure 163 -> 135. NEXT:
comprehensions 45 (element/iterable/filter, `?` inside, `(i, x)`
binders — binders ride the pattern-bind machinery), then a layout
tail (a leading-dot chain line 12 — continuation when the dot line
is indented deeper than the line before and that line did not open
a brace; `else` on its own line; a fn named `fail` in our lexer
clashes with the keyword and is renamed at parity), then the test
DSL 64. AND A LAW, from the crash hunt: EVERY RUNTIME TRAP NAMES
ITS SITE — an avra-built program's index or unwrap failure carries
file:line (the bootstrap's does not, which cost an hour of
bisection); the runtime rows gain a site argument minted as a
constant at each risky read, and the evaluator prints the same
text so the differential holds. Its own small rung, before the
fixed point.

PARITY RUNG 3 LANDED (2026-09-03) — PATTERNS. THE MODEL: patterns
are nodes in the store's own table (`Pat`: Wild, Rest, Bind,
Variant(name, args), Lit(expr); `PatId`), an arm is `{ pats, value }`
(alternatives are `or`), and `Expr.Match(subject, arms)`; an enum
variant carries a LIST of payloads (`Variant { name, payloads }`,
`EnumSig.payloads: List<List<TypeId>>` — a wrapper's one positional,
several named, per spec 8.3), the value's slots 1.. in order. THE
LAWS (spec 8.7 as written): a pattern fits the shape it tests — a
variant of the enum with exactly its payloads (a bare `.V` accepts
the variant whole, payloads unread), or a literal of the type; a
name binds the value at its path, keyed by the arm value and the
bind's pre-order index (`Binding.Pattern(arm, index)`, the fact
tables lists); an `or` arm binds nothing; COVERAGE is judged column
by column over pattern rows (specialize for the variants a column
tests, hole rows cover the rest — so nested arms that split a
variant cover it, and a recursive enum terminates), a literal match
needs a catch-all, a variant accepted whole twice is a repeat, and a
hole hiding more than two variants WARNS with them listed (F2040)
unless it is `rest`, the contextual deliberate remainder. LOWERING:
arms that each test one variant whole are the jump table as before;
anything else is a CHAIN of lazy tests in arm order (`||`/`&&` as
regions, so an untaken arm's payloads are never read), binds read
inside the arm's region. corpus/patterns.av; 15 specs; the three
old one-bind pins re-pinned. CENSUS: files with a parse failure
178 -> 163; match-arm first failures 49 -> 2. NEXT by files: the
LAYOUT tail (~57: trailing-operator and leading-dot continuation
lines 25, statement-position block arms `-> {` ~14 (a block is not
yet an expression primary — the map's `{` wins), bare `return` 10,
multi-line struct literals 4, multi-line signatures and arguments),
then comprehensions 38, then the test DSL 60.

PARITY RUNG 2 LANDED (2026-09-03) — THE SMALL-GAPS SWEEP: empty
record declarations (`type X = { }` — the field group optional);
force and propagate join the POSTFIX chain as a fourth family
folded by source position (`sig!.field`, `f(x)?.g` — the `forced`
ladder rung and its builder are gone); unary minus desugars at the
parse to `0 - v` (no pass learns a node); a fn or trait sig with no
`->` returns `void` (`void` names Type.Void; the trait builder
aligns returns by window like params); A BLOCK WITHOUT A VALUE IS
VOID — the block builder no longer refuses a body ending in a non-
expression statement: typing says void (or the fn's promise when
the last statement leaves), so `fn f(n: int) { let m = n }` and a
void method type and lower, and a valueless block in a value
position refuses at the RETURN ("the body answers `void` but `f`
declares `int`"); `subject is .variant` is a new Expr (`Is`) the
enums feature owns — typing demands an enum naming the variant and
answers bool, lowering reads the tag once and compares (one Bin, no
region). Five pins of the superseded laws re-pinned as the new laws;
corpus/small_gaps.av; 10 specs. CENSUS: files with a parse failure
195 -> 178; the ladder's next three families by files unblocked:
match patterns 49 (nested `.Node(.NExpr(id))`, `or`-arms, `_`
payloads and catch-all, literal arms), comprehensions 31, the test
DSL 57; then a LAYOUT tail (~20: bare `return` in void fns,
multi-line struct literals, trailing-operator and leading-dot
continuation lines, multi-line signatures and call arguments,
statement-position block arms `-> {`).

PARITY RUNG 1 LANDED (2026-09-03) — ONE-LINE BODIES, by one
engine terminal: `END` is "a Break consumed, or a `}` left for the
body that opened it"; every statement tail is spelled `END` (not
BREAK), `@recover(sync_to: "END")` syncs past the next Break or
stops before a `}` the statement did not open (braces it consumed
between entry and failure are its own to close — credited, so a
broken `let m = { "a" 1 }` still syncs line-wise and every pinned
cascade count held), and a recovery hole inside ANY body becomes a
Stmt.Error node as at the top level (the "expected a statement in a
repeated capture" builder failure is gone). The `"{" BREAK` anchors
that the floor's recovery once forced (if_stmt, let_else) are gone
with the trap. corpus/one_liners.av; 8 specs; the let-else one-liner
re-pinned as a positive. CENSUS AFTER: no remaining first failure is
a one-line body; what the brace-shaped classifier now catches is the
NEXT construct in those files — empty struct declarations `type X =
{ }` (24 files), force-then-field chains `x!.f` (several), unary
minus (`-1`), `is` expressions — recorded in the ladder below as the
SMALL-GAPS SWEEP, the next rung.

PARITY LADDER, as measured 2026-09-03 (first failure per compiler
file, so true totals are larger): one-line bodies 58 · spec/given/
then + runner 50 (the runner and reporter land as their OWN
package, `@std/testing`, the owner's call 2026-09-03; the
compiler-specific helpers stay in std-avrac's testing module) · THE
SMALL-GAPS SWEEP: empty struct declarations
`{ }` 24, `x!.f` chains, unary minus, `is` expressions 4, void fns
20, named payloads 8 · comprehensions 24 · match patterns (nested, or,
literal, wildcard) 23 · void fns 15 · named payloads 8 · `is` /
extern / fn types in fields / generic impl 10 · continuation lines,
multi-line struct literals, if/else STATEMENTS with effect bodies
(a block ending in an assignment refuses as a value block today)
12 · then the second-failure unknowns · then the fixed point.

15b.1 LANDED (2026-09-03): `@std/toml` is its own package
(packages/std-toml — the reader the manifest reads with, self-
contained, in the idiom ratchet's roots); `language/manifest.av`
reads `avra.toml` into facts and speaks every rule as
`manifest.*` (F4000–F4031; unknown sections and keys WARN — the
first Warning producer, and `clean()` now means no ERRORS);
workspace.av holds PACKAGES (root plus every path dependency
reachable from its manifest, admitted once by key, the
`Manifest` family an INPUT keyed by package); `use
@scope.name.a.{x}` cuts a package at two segments and resolves
only when the asking package's manifest declares it (F3013 made
real, with the STRUCTURED FIX when the package is already in the
workspace — the dependency line, relative path, placed after the
last one); cycles, name mismatches, missing directories and
duplicate keys refuse in the manifest's words at the manifest's
line; a directory holding its own avra.toml is never a module of
the package above it (through-paths included); `src/` is THE
source root (corpus/modules moved under it; a file outside `src/`
is a lone file); `run`/`build <dir>` enter at `[bin]` or
src/main.av, F4005 otherwise; warnings render on check (exit 0),
run and build (stderr). MEASURED on the compiler's own tree:
F3011 (no module) 58 -> 0, F3013 1 -> 0 — every `use` in 234
files now finds its module; what remains is parse parity.
DECISIONS TAKEN (from the four): Q1 (a) `src/` always; Q2 the
target rule at entry time; Q3 warnings now; Q4 one edit-only
agent wrote the TOML package. DIVERGENCES from the docs, recorded:
`@scope.name` in source (law 2); unscoped dependency keys refuse
(the manifest doc's `local = { path }`); rule 4 softened to entry
time. Suite 1364 (toml +42, manifest +19, packages +13),
corpus/packages proves a vendored path dependency eval == native.

THE STAGES (nothing ships half-built):
- 15b.1 manifest reading (F4000–F4099, `manifest.*`), path
  dependencies, `@scope.name` = `@scope/name`, cross-package
  cycle refusal, THE NESTED-PACKAGE LAW (a directory with its own
  avra.toml is not a module of the package above), `src/` as the
  one source root (spec 16.1; corpus/modules moves under src/),
  warnings for unknown sections/keys (the first Warning; `clean()`
  = no errors), the target rule enforced at entry time, `run`/
  `build <dir>` entering at `[bin]`, and the structured fix that
  writes a path dependency for a package found in the workspace.
- 15b.2 the lock: reached items per dependency with signature
  hash and use kind, the compiler hash, `--locked`, the change
  report when a path dependency's reached items change — the
  first holy-shit moment, no registry needed.
- 15b.3 git sources: D15–D19, `avra add`, the content store,
  `--offline`, `avra vendor`.
- later rungs, each with a trigger: needs/grants once `extern`
  exists in the language; sources, labels, publishing and the
  transparency log with a registry or git transport; advisories,
  migrations, contract search, the signed item cache.

THE IMPORT SYSTEM, DREAMED (proposed 2026-09-02; each line a
paradox collapsed, none built until ratified):
- (REFUSED by the owner 2026-09-02 — explicit `use` in every file is
  the law; the compiler WRITES them.) IMPORTS ARE FACTS, NOT SYNTAX. Resolution order: local scope ->
  the module (its directory) -> the PACKAGE's exports, unqualified
  (your own package is in scope everywhere; an ambiguity is a
  loud error carrying the qualified fix) -> other packages by
  qualified path (`@std.http.get`) or `use`. The `use` block
  becomes a PROJECTION: the compiler writes it on request (`avra
  fix use`, an LSP action, `--json` for agents) for readers who
  want provenance in the file. Explicit-vs-implicit collapses:
  implicit to write, explicit to read.
- (REFUSED 2026-09-02 — a second place to look; files stay self-
  contained.) A MODULE HAS ONE PRELUDE. `use` lines in a directory's
  `mod.av` apply to every sibling file — imports are per module,
  not per file. The census says this alone retires ~70% of the
  compiler's 309 `use` lines.
- PACKAGES ARE HASHES, VERSIONS ARE SURFACES. A dependency is a
  content hash (16.8); a version's compatibility is COMPUTED —
  the new surface must contain every old sig_fp (16.9's
  compiler-enforced floor, made exact). "Will this upgrade break
  me" is a query, and a build is reproducible by construction.
- IMPORTS ARE CAPABILITIES. With Axis 13's effects, a module's
  import graph IS its permission graph: a module that imports no
  `@std.fs` provably touches no file. Security-vs-ergonomics
  collapses: the same lines serve both, and `avra explain
  effects <module>` shows it.
- TESTS SEE PRIVATES. A `tests/` directory lives inside its
  parent's privacy boundary and outside its artifact.
- ONE SEPARATOR, ONE SIGIL, ONE WORD: `.` for every path, `@` for
  a package, `export` for the boundary. Nothing else.
- EVERYTHING IS A QUERY: `avra where <name>`, `avra explain
  import <path>`, who-uses, what-breaks-if — the module system's
  surface for humans and agents alike.

THE IMPORT SURFACE, RATIFIED 2026-09-02 (the owner's taste, line by
line): every import is a `use` at the top of its scope — nothing
inline, nothing implicit, every path absolute from the package
root, `.` the only separator, `@` the package sigil.
    use core.{ExprId, TypeId}          items — 15a, the census's form
    use core.ExprId                    one item, no braces
    use core.{                          newlines ARE the separators;
        ExprId                          no commas, no trailing-comma
        TypeId                          question
    }
    use @std.http / use @std.http as h whole module, qualified use
    use features {                     a PREFIX block: shared prefix,
        contract.{TypeCx}               one path per line
        lists
    }
    use { … }                          the file's block, no prefix
    use core.{ExprId as E}             an item alias
    export use lists.{lists}           a re-export (mod.av curates)
    use @std.fs.{read} in a block      scoped: the use belongs to
                                        the block it heads
    use core.*                         a glob — allowed and LINTED
                                        (spec 16.3); a collision is
                                        a loud error naming both
REFUSED: inline `@std.http.get(url)` (messy over time), implicit
local modules, relative paths, string paths, a mod.av prelude.
THE LOOP (P1): the author — a person or an LLM — writes the
`use` it believes; a wrong one is a diagnostic WITH THE FIX
("no `accepts` in `features.lists` — it lives in
`features.checks`"), and `avra fix use` is that fix in bulk
(add, drop unused, sort, fold into prefix blocks). 15a lands the
first form; 15c the rest — Avra programs get them then, the
compiler's own source at parity.

DECISIONS (D1 RATIFIED 2026-09-02: a module is a DIRECTORY — amend
spec 16.1):
(D2, decided) `.` everywhere, one resolver; (D3) 15a's imports
are `use path.{items}`; 15c widens; (D4) top-level `let` is
never exported; (D5) `check <root>` = every file, `run`/`build`
= the entry's closure; (D6, RATIFIED) 15a builds the memo core itself
rather than a one-off driver.

15a LANDED (2026-09-02) — what it is, in one breath: a program is
every `.av` file under a root, typed together, run as one. The
pieces, each one file:
- `language/db.av` — THE QUERY KERNEL (D6): cells with deps,
  changed_at/verified_at, red-green `needs_compute`, early cutoff
  in `settle`, one verifier per family, hit/miss counters. Values
  live in the families' typed tables; the kernel is bookkeeping.
- `core/modules.av` — `ModulePath` (`.`-joined, `@` package sigil,
  `dir_under`/`file_under`), `module_symbol(module, name)` (a fn's
  symbol is its name under its module — `util.twice`; the root's
  stay bare, so lone files are unchanged), `dir_of`/`last_slash`.
- `language/workspace.av` — the families `source` (input, hashed),
  `parsed`, `items` (a file's declarations, ids minted as `base +
  statement index` — THE SAME arithmetic the typing table uses, so
  the workspace's ids ARE typing's), `surface`, `foreign_of`;
  `analyze_all` (four declaration rounds across every file before
  any body); `Program { files, entry, phases, cache }` — the
  many-file artifact with the Analysis vocabulary (report,
  lowered, run, check); a lone file is `lone_program(a)`, so the
  law lives ONCE and Analysis delegates.
- typing's `DeclTable` — one type registry, one signature table by
  DeclId, every declaration's `Home` (store, stmt, module, file,
  base), methods keyed by the TARGET's DeclId with their symbol,
  impls keyed (type, trait). `typer` admits a file; the rounds are
  `declare_types/traits/fns/impls`; `type_bodies` ends it.
  `Binding.Foreign(DeclId)` is how a file's resolver names what it
  cannot see; typing reaches sigs/tparams/kinds through the table.
- lowering's `lower_all(files, entry?)` — every file's bodies,
  the entry's main (an empty one for `check`), ONE worklist: a
  specialization lowers in ITS declaring file (`home_of`), a lift
  in the file it was written (`Lift.home`), wrappers likewise.
  `Ins.Call` targets are qualified symbols; a method's symbol is
  its type's name under the IMPL's module (`x.P.v` and `y.P.v`
  coexist — pinned).
- the CLI — `check <root>` (every file, no entry) and `check|run|
  build|ir|emit <file>`: an `avra.toml` ancestor marks the root
  (15b gives it contents); a file outside any package is a LONE
  program, unchanged — the flat corpus never touches the
  workspace. `--time` prints the phases + memo hits/misses.
  `corpus/<name>/main.av` + `expected` + `avra.toml` is the
  package corpus shape (`corpus/modules` lands it).

LAWS THAT LANDED WITH IT (each a red-team find, each pinned in
workspace_adversarial_test.av):
- ONE NAMESPACE PER MODULE: a name declares once across a module's
  files (F3017 names the other file); a local declaration never
  shadows a sibling — the symbols would collide and the union
  would run the WRONG body silently (found: `helper` printed the
  sibling's answer).
- IMPORTS NEVER SHADOW: an import already visible under its name
  refuses (F3018) — unless it is the SAME declaration (a root file
  is both a sibling and a lone-file module; re-importing it is
  redundant, not a clash — silent today, a lint in 15c). Listed
  twice in one `use` refuses.
- A MODULE IS ONE THING: a directory and a file of one name refuse
  (F3016) rather than the directory winning silently.
- `export` MARKS A DECLARATION — fn, type, enum, trait (F3014);
  `export use` names 15c; `export impl` says methods travel with
  their type; `export export` is a builder refusal.
- `use` LIVES AT THE TOP LEVEL (F3019, the nested_decl voice); a
  lone file's `use` says it needs a package root (F3015).
- THE ORPHAN RULE (STRICT): an impl lives in its type's module, or
  in its trait's when the trait is this module's (F2037). A
  refused impl still declares its methods as WRECKAGE (hole sigs)
  — found as a CRASH (`self` read from an empty param list).
- ONLY THE ENTRY RUNS STATEMENTS (F0902): a module file holds
  declarations; run-time statements elsewhere are refused naming
  the entry.
- fn and type namespaces stay APART per module, as the lone-file
  rule keeps them — one law (namespace.av), two maps.

MEASURED (152 compiler files through `check --time`): parse+resolve
760ms (the parse is the cost; declare/bodies ≈ 0 because most
files still refuse at parse), lower 5ms, memo 1731 hits / 442
misses on first run. The number the performance program (PF1) now
attacks is the 760ms.

DEFERRED, WITH TRIGGERS: cross-file generic METHODS (T2, with generic
impls); `analyze_file` re-runs `analyze_all` (per-item memo of
typing is 15d — the differential oracle `incremental == scratch`
lands with it); diagnostics from ANOTHER file's Loc render with
the entry's source (the renderer takes one SourceFile — 15b's
multi-source renderer); the redundant-import and unused-import
lints (15c); host directory listings are readdir-ordered (sort at
the host when a determinism test needs it); a keyword as a module
name (`use fn.{x}`) works by the lexer's leniency in paths —
harmless, unratified.

THE CRUFT ROUND (2026-09-02, the same day, before anything stacked
on 15a) — eight structural findings, all fixed, feature set held,
the adversarial suite as the oracle:
1. Identity is INTERNED, not positional: `decls.av` is THE
   declaration table — dense ids minted by key (file, kind, name; a
   method under its owner; a repeat within a file keyed by its
   statement so the namespace law can refuse it), stable across
   edits and re-admits. Per-file facts live once, by FileId. Typing's
   `DeclTable`/`Home` and the workspace's parallel `Decl` list are
   gone; ~10 rows per real declaration became one.
2. THE KERNEL is its own module, `query/` (core -> query -> grammar
   -> features -> language): typed keys (family number + dense id,
   two list indexes, no strings), cycle detection (`Verdict.Cycle`
   instead of recursion), a sweep, and — for the first time — its
   own spec (reuse, early cutoff, cycle, sweep).
3. ONE LAW for "a name binds once": `namespace.av`. A module's
   namespace is every file's declarations (fns and types apart); a
   file's namespace adds its imports; the second binder refuses in
   its own words (same file: F3003/F3006; sibling: F3017; import:
   F3018; the same declaration again: redundant, silent). The
   resolver no longer declares top-level names — it keeps only the
   naming laws (keywords, built-in type names) and looks names up.
   `Binding.Decl(DeclId)` is every declaration, this file's or not;
   `Binding.Def` is a `let`. `Foreign`, `provenance`, `Taken`,
   `module_clashes` are gone.
4. ONE PIPELINE: `typed_together` holds the rounds once; a lone file
   is a program of one (its own declarations are its namespace, a
   `use` line is refused as needing a package); `analyze_with`,
   `no_foreign`, `packaged` are gone.
5. Diagnostics render over EVERY file's source (`render_among`): a
   frame's window comes from the file its Loc names — found as a
   bug (a non-entry file's refusal windowed the entry's text).
6. `analyze_all` is a memoized family (`analyzed`, one cell) — its
   deps are every parse and item table it read; `program` and
   `analyze_file` are queries.
7. String keys off the hot paths: methods are per-declaration
   lists, impls per-declaration trait lists, kernel keys are typed.
   Mono's symbol-string dedupe stays (symbols ARE strings; interning
   them is PF-work).
8. Deterministic listings: both hosts answer names in byte order
   (`qsort` on disk, `sorted_texts` in memory), so ids, IR order and
   the LLVM module are the same on every machine.
Also: `declared_kind`/`is_declaration` live on the store (three
copies became one), `DeclKind` is core's one vocabulary, `Program.
entry` is honestly optional, `Analysis` delegates every law to
`Program`.

THE SECOND CRUFT ROUND (2026-09-02, same day) — ten findings, nine
done, one refused on reflection:
1. ONE VOICE SHAPE: `refusal(kind, at, message, label, help)` in
   diagnostics — 173 hand assemblies became one call each; the
   shape is now ratcheted (I28), the constructor and the one
   two-frame voice licensed at their sites.
2. REGISTRIES ARE DATA: `decls` rides TypeCx and LowerCx like
   `store` and `types`; the table-read verbs (`decl_tparams`,
   `decl_tbounds`, `method_symbol`, `trait_methods`) are gone.
   `decl_of` stays a verb — it needs the file. The table itself
   moved to `features/decls.av`, the registry floor where DeclSig
   lives, so the contract can name it (features never import
   language).
3. ONE SYMBOL SOURCE: `decls.symbol(d)` names every fn AND method
   symbol (a method's owner rides its row); typing no longer
   computes symbols, `MethodEntry.symbol` and lowering's two
   constructions are gone, `method_symbol` left the contract.
4. `Analysis` is a parsed program plus facts (`p`, resolution,
   typing, decls, file); the six copied fields and the two bridge
   verbs are gone.
5. `lone_resolve` is gone — the resolver's tests read
   `analyze_source(text).resolution`. `analyze`, `check`,
   `analyze_source`, `parse_source` remain: each is a distinct seam
   (a source, a report, a text, a parse).
6. ONE CLI PROLOGUE: `on_program(args, act)` — a directory is a root
   with no entry, a file is entered, no such file exits 2.
7. THE SPLITS: typing is `typing.av` (the walk, the facts),
   `typing_declare.av` (the rounds; the types annotations write),
   `typing_impls.av` (traits, impls, methods, orphans); lowering is
   `lower.av` (every file's bodies, one worklist), `lower_walk.av`
   (one body's walk, the contexts, the entry's answer),
   `lower_state.av` (registers, slots, values, captures, symbols).
   Sibling files, one module, imports pruned to what each uses.
8. REFUSED: merging the per-expression columns (`wants`/`hungry`/
   `starved`, `widens`/`narrows`) into per-expression records. The
   columns are the columnar layout — dense, allocation-free, sized
   once by exprs.count() at ONE site — and a record per expression
   would trade that for an allocation each. Alignment is by
   construction, not by discipline. "No simpler."
9. PATHS IN ONE PLACE: `core/paths.av` (dir_of, last_slash,
   first_slash, under_dir); text ordering in `core/text.av`;
   `.ends_with` where a hand scan was.
10. A SOURCE ALWAYS HAS A NAME: `SourceFile.file: string`; the
   nameless test source is `<source>`, which the renderer already
   printed for null — no golden moved. `Loc.file` stays nullable:
   a defect has no file.

THE MINIMUM (2026-09-02, designed; D7–D16 RATIFIED the same day) — `docs/MINIMUM.md` holds the design whole: one rule
(memoized queries over inputs, values are fact tables keyed by
dense ids), six ids, the TWELVE query families (the table lives
there, verbatim), twelve structs, one feature contract (facts plus
walk verbs), diagnostics riding values, the language out of the
program — and every struct, impl and interface that supports it,
by layer. The decisions:
  D7  per-declaration granularity: `sig`, `typed`, `lowered` as
      queries; the four declaration rounds deleted (15d, pulled
      forward — it falls out of the minimum).
  D8  `Parsed` sheds the language's registries; contexts get
      `LanguageRows`.
  D9  diagnostics ride query values in one `Voices` sink; `report`
      folds; pass-owned lists and `emit` closures go.
  D10 contexts are facts plus walk verbs; reads and writes are
      methods on the fact structs (the NodeStore precedent:
      declared in a lower layer, implemented above, called from
      features).
  D11 `Analysis` and `Program` stay as facades, holding no logic.
  D12 one FileView shared by every context and facade;
  D13 mono's worklist IS the memo: `lowered(d, sub)` returns its
      lifts and wraps with the body and its cross-body wants as
      data; `program` asks; `Jobs`/`Spec`/`Lift`/`Wrap` go;
      specializations are interned (SpecId);
  D14 facades hold a workspace and a key; a lone file is a
      workspace over a memory host with root "" — the lone pipeline
      is deleted;
  D15 ModuleId; `namespace(module)` once per module;
  D16 `folded(file)` folds a file's declarations' facts.
Also decided: `TypeFacts` per declaration over its arena range;
`DeclKind.Main` for a file's run-time statements.
Order: the CONTRACT step (D8+D9+D10+D12), then the QUERY step
(D7+D13+D14+D15+D16) in two halves. First probe: a declaration's
nodes are one contiguous arena range.

THE MINIMUM, LANDED (2026-09-02, one big-bang slice, gate green):
the contract step (D8 D9 D10 D12), the query step (D13 D14 D15 D16,
and D7's signature half). `docs/MINIMUM.md` § "What landed" is the
ledger: TypeCx 16 fields / 11 verbs (was 40 / 34), LowerCx 15 / 7
(was 28 / 23); every read a method defined ONCE on the fact structs
(`features/facts.av`); `Parsed` is a store, statements, a source and
voices; the language's rows ride `Language`; signatures are lazy
per-declaration queries through the table's own read (`Decls.sig`
asks the workspace's `sig` family; `type.cycle` when a sig reaches
itself); the four declaration rounds, `typed_together`, `Staged`,
`lone_program`, `Foreign` are gone; the module namespace binds once
per ModuleId; `lower_unit` returns lifts, wrappers and wants as
data and `union` asks a memoized `unit_of` — the worklist IS the
memo; `Program { ws, … }`; a lone file is `lone_workspace`. D7's
other half — bodies per declaration — waits on cross-body reads of
top-level bindings' inferred types (found as a crash, recorded).
Measured: unchanged parse-bound timing; the memo now sees 2432
hits / 1505 misses on the compiler's own files.

THE MINIMUM, THE REST (2026-09-02, second slice, gate green): D7
whole — `typed(decl)` per declaration, `folded(file)` the fold,
`methods(decl)` a family the table's reads ask, the union the
entry's closure (`symbol_at` wants what it names; check mode seeds
every body). What the first slice misdiagnosed: bodies were not
per-declaration because a fn body could READ a top-level `let` —
resolve let it through and lowering hit a defect. That is not a
cross-body read to support; it is a law: THE BODY FLOOR (F3020,
`resolve.runtime_binding`) — a fn body, and a field default, sees
declarations and its own bindings, never the top level's run-time
values (the remedy is a parameter; module-level CONSTANTS readable
by fns are a rung of their own — trigger: the spec's module-level
`let`). Found by attack, fixed the same way: a struct literal in
one file omitting a defaulted field declared in ANOTHER lowered the
default's ExprId against the caller's store — stack overflow. A
FIELD DEFAULT IS A DECLARATION (`DeclKind.Default`): typed once in
its module, lowered once as a zero-parameter body (`P.y`), CALLED by
every literal that omits the field — its private helpers reach the
program without the literal's file naming them; a generic record's
default instantiates under the literal's arguments. The false
cycle: a recursive payload's slot re-judge asked its own sig and
the first slice's `type.cycle` voice fired (silently overwritten
then; surfaced by the merge) — the voice is gone, the kind with it;
no sig depends on another's VALUE today (trigger: type aliases).
"`P.show` is declared twice" moved from the method's sig to the
method-table CLASH law (`method_clashes` beside `module_names`):
registration is the impl block's, blame is the later declaration in
source order, whatever order the impls were asked in — the
lone-file path asks bodies before sigs and had blamed the wrong
side. `--time` now shows parse / resolve / sigs / bodies apart.
`Decls.decls_of_file` lists every kind (members and Main included)
in admitted order — a Default has no statement of its own, so the
by-statement list could not carry it.

THE DB VISION (the questions asked with this round): the kernel is
bookkeeping only — cells with deps, changed_at, verified_at, a
value hash; VALUES live in typed family tables. Three tiers: in-
process (now, one kernel per invocation); on-disk (15e: the cell
graph plus the expensive family tables, content-addressed, mmap'd
from `.avra/`, our own format — P14 — which is exactly why ids are
interned: an interner persists); daemon (15e: the kernel in a
long-lived process that is also the LSP, the CLI handing it input
changes). What makes the tiers pay is per-ITEM granularity (15d): a
signature query and a body query per declaration, early cutoff on
the signature's hash, so editing a body re-verifies no caller.

FOUND ON THE WAY, NOT MODULES: `match 2 { 2 -> … }` — an int
LITERAL pattern does not parse ("expected `}` to close the match")
— the match feature's literal patterns are unlanded; sugar
backlog.

REVIEW ROUND (2026-09-02, the round after THE MINIMUM; recorded
from `git diff --stat` — 141 files, +3229/−2889 — and the tree as
it stood when this was written). What the round REMOVED:
  - `home`: the file index every lowering job carried (`Lower`,
    `Wrap`, `Lift`, `new_lower`, `home_of`, `declared_bodies`,
    `method_bodies`) — a body's file is its view's; the field, the
    parameter and the lookup are gone.
  - The workspace's per-family ceremony: the `<family>_key` fns,
    the `verified_<family>` verifiers and the hand-grown table
    loops became ONE `enum Family` with `ordinal` and `refetched`
    (both exhaustive — a new family cannot ship half-registered)
    and two core verbs, `placed`/`placed_at`, for the sparse
    tables. `namespace` keys by ModuleId; `visible(file)` adds the
    imports; `analysis(file)` is a family, not a facade's cache.
  - `Typing`, `Resolution`, `Staged`, `typed_together`,
    `lower_all`, `lone_program`, `namespace_of_file`: the pass
    values that copied columns out of `Typer`/`Resolver`, and the
    exploded store/source/file/decls fields on `Typer`, `Resolver`,
    `Lower` and `Analysis` — each holds ONE `FileView` now, which
    gained the file's STATEMENTS (`runtime_stmts` is a view read).
    `TypeCx` is 4 data fields + 11 verbs, `LowerCx` 7 + 7.
    `language/namespace.av` moved to `features/namespace.av`,
    `language/runtime_api.av` to `core/runtime_api.av`; the fact
    structs and their reads live in `features/facts.av` (new).
  - The Map `length` miscompile: `m.length` has its own property
    row (`check_map_length`/`lower_map_length`), corpus/maps prints
    it, and the interpreter's map length reads through `with_map`.
  - Tests read `r.voices.list` where they read `r.diagnostics`, and
    `shown`/`refusals`/`refused_with` come from `@std.avrac.testing`
    instead of a copy per file.
  - Tooling holes: the I23 matcher was anchored at column 0 and had
    never read a METHOD (three real dead parameters surfaced in
    typing_impls.av; trait-impl methods are excluded by matcher,
    since the trait owns the signature); the I20 guard accepted
    `>= 1` as a count by substring — it now demands `== n` /
    `refused_with`, and I30 ratchets the `>= 1` spelling itself
    (28 sites the day it landed); `tools/vocab.sh`'s `exit 1` fired
    in a pipe's subshell and never failed the gate; `make sweep`
    now removes the per-run shard objects `bs2 test` leaves in
    build/ ROOT (21,917 of them: 3.9G → 3.6G) by run liveness and
    age; `make clean` removes `scratch/`; the run targets are
    `.PHONY`. The CLI: `--time` reaches `ir`/`emit`/`build`,
    `lowered_or_report` and `arg_command` live in shared.av, the
    scaffold's test template imports `shown`.
  Landed after that was written: `Spec`/`Ask` → ONE `Wanted { file,
  decl?, name, sub? }`, the unit of lowering — `lowered(id)` asks the
  file's `analysis` (a recorded dependency, no hand-touched fold);
  `Unit` and `Emitter` speak `Voices` like every other value (no
  string failure channel; `defect_at` is the one defect kind);
  `foreign_node(cx, e)` in the contract is the ONE lowering
  catch-all (nine features; three had minted a silent register).
  FOUND THE HARD WAY: three agents building at once crashed the
  machine — builds are serial (CLAUDE.md). And a bootstrap trap that
  ate an afternoon: a metadata-compiled test SHARD that instantiates
  an imported list-writing generic twice loses every instantiation's
  writes — `copy_into` has no unit spec; the fold and the corpus are
  its proof (CLAUDE.md). The scaffold template had rotted past the
  contract (`cx.types`, no `heirs`) because `make scaffold-check` is
  outside `make gate`; fixed, and the gate should grow it (trigger:
  the next template change).
  DRIED AFTER THE ROUND (2026-09-02): `checks.av` split at its
  banners into checks.av (agreement, join, members, calls, places,
  void, their voices), unify.av (unification, the slot law, the
  instantiation rituals) and variants.av (variant construction and
  its voices); `facts.av` into facts.av (the values and their own
  column verbs) and contexts.av (the cross-value reads and every
  context's forwarders). `make gate` now runs scaffold-check.
  CONSIDERED AND REFUSED: nesting `ResolveCx` inside `StmtResolveCx`
  for symmetry with the typing and lowering statement contexts. The
  typing and lowering statement contexts nest because their rules
  CALL the expression vocabulary (`cx.expr.type_at`); resolve's
  statement rules call none of `ResolveCx`'s node verbs (`use_name`,
  `use_call`, `use_type`, the three scopes) — nesting would add a
  field nothing reads and re-spell 45 `cx.view` reads for a symmetry
  the vocabularies do not have. `StmtResolveCx { view, facts, … }`
  is the honest shape; its `binding_of` is the one verb the
  mutation rule dispatches on.

## Interior mutation & maps — rung 14 (designed 2026-09-01)

Spec: Axis 11.1 (`mut` opts in), 11.5 (`let` is DEEPLY immutable;
a `mut` binding permits mutation at any depth — `u.address.city =
x`, `u.posts.push(p)`), 11.3 (interior mutability only through
later `Cell<T>` wrappers), 4.2 (void fns omit `-> T`; `Void` is
the spec's word). The memory doctrine's standing constraint
binds every line: aliasing NEVER observable. The census that
ordered the slices (the compiler's own non-test source): `.push`
207 sites, `Map<`/`.get`/`.set` 21/28/47, `component`/`table<`
24/36 (every feature manifest), `for (i, x) in xs.enumerate()`
64. NOTE: the spec's own `gather_points` writes `let xs = []`
then `xs.push(p)`, which 11.5 forbids — 11.5 is the decision.

THE PLACE LAW (M1): a mutation lands on a PLACE — a path from a
`mut` binding through fields and indexes (`NAME ( .f | [i] )*`).
The target parses as an ordinary expression (the postfix chain
already builds Prop/Index in order; the grammar engine's per-slot
captures cannot); core's `place_step` projects it (Root | Field |
At — the one projection for the place CATEGORY, like elems_of for
values) and `place_root` names the binding. Resolve: the root is
a `mut` binding or the refusal names the remedy (`mut x`, or
`with`). Typing: the target types as a READ — its type IS the
slot's law, the value is accepted by it (widening recorded), and
the want is planted so a lambda assigned into a fn-typed field
hears its seat. `xs.push(v)` is the same law on a method: the
receiver is a place, the argument is accepted by the element,
and it answers VOID.

THE MECHANISM: copy-on-write along the path, top-down. A write
opens the root's cell (`avra_cell_unique`: the box is returned
as-is when its count is one — the cell's own reference — and
CLONED into the cell otherwise), then each field/index step
(`avra_slot_unique`: same, one level down, the clone stored back
into the parent slot), and the last step writes (`avra_slot_set`,
rewritten to `_owned` by the memory pass's type knowledge, like
push). The clone is shallow and retains the children the box's
own owned-map names — the runtime knows exactly what release
would release, so the compiler carries nothing. THE INTERPRETER
ALWAYS COPIES: it has no counts, so `unique` clones every time —
the executable spec of value semantics; native copies only when
shared, and the differential proves they agree. Uniqueness
proofs (V2) later cancel the loads that inflate a count (`xs.push
(xs[0])` clones today — correct, one copy too many).

VOID enters the type vocabulary (`Type.Void`, spec 4.2): `push`
answers it; a `let` of a void value refuses ("answers nothing —
there is nothing to bind"); slots refuse it. Void FNS (`fn log(m:
string) { … }`) ride a follow-up slice — the compiler's own trait
methods (`resolve`, `lower_stmt`) answer nothing, so self-host
needs them.

M1 LANDED 2026-09-01: places — assignment through any path,
`push`, copy-on-write on both engines, `Type.Void`. rt28 55/55
(the red team caught a measured property (`xs.length = 3`)
reaching lowering as a place — the structural half of the law
now refuses it in typing — and a type-name root). The
assignment parses at the statement FLOOR as an optional tail
(`expression ( "=" expression )? BREAK`): one parse, order kept —
an expression-headed branch had parsed every expression statement
twice and leaked the first attempt's nodes into the arena.
Recorded: `+=` (refuses as "expected BREAK" today — wants a
hint), if-else as a STATEMENT with statement arms (the elseless
form works), mutating methods (`self` is a parameter — the
compiler's own vocabulary structs need `mut self`; spec silent;
needs ratification).

M2 LANDED 2026-09-01: maps — `Map<string, V>` (every one of the
compiler's 21 declarations is string-keyed; other keys recorded),
`{ "k": v }` literals, `{}` adopted by any map exactly as `[]` is
by a list (Type.EmptyMap, the identity lift), `get` answering
`V?` through the nullable protocol's own adoption, `set` as the
place law on a method (Void), `length`. The runtime keeps two
arrays in written order plus an open-addressing index; kinds
(array | map) decide reclaim and the copy-on-write clone; the
interpreter's map is a scan. Map values obey the slot law with
the shared promise. TRAPS recorded: string literals inside `${}`
holes and negative literals do not lex/parse yet.

rt29 51/51 (31 agreeing, 20 refusing at exact counts). TRIGGERS
recorded by it: (1) a MALFORMED LITERAL speaks twice — the
literal's `@expect` and then the statement floor's recovery
(`[1 2]` does it too; pre-existing) — the engine wants an
@expect'd failure to sync the floor without a second voice;
(2) the pronoun binds to the NEAREST method call, so
`xs.map(m.get(it) ?? 0)` starves at `get` and the outer walk
refuses too — two true voices; the starvation hint now names
the outer-lambda spelling. Considered: binding to the OUTERMOST
call instead would break the nested-scope law both engines pin.

MAP KEYS, the decision (2026-09-01): STRING KEYS ONLY in M2 —
the census, not a wall: every one of the compiler's 21 map
declarations is `Map<string, …>`, so P17 built exactly that and
`Map<int, …>` refuses with a recorded voice. The ladder for
keys: (K1) INT KEYS — cheaper than strings (hash the word,
compare by identity, nothing to retain): a key KIND chosen at
`avra_map_new` plus `string | int` in the typing rule, ~20
lines, lands the day a program wants it; (K2) STRUCT and ENUM
keys wait on STRUCTURAL EQUALITY AND HASHING over declarations
(spec 11.1's first rationale; `==` "compares scalars for now")
— a derive-style rung, and keys ride it for free; (K3) generic
`Map<K, V>` in a generic fn already types — `K` must unify to
`string` today.

THE LEAK, NAMED (asked 2026-09-01: "why is map code in
interp.av and not under the maps feature?"). What belongs to a
feature — grammar, builders, typing, lowering — IS under
features/maps. Three things are elsewhere, and they are not the
same kind of thing:
  (1) THE INTERPRETER'S HOSTS (`map_get_val` …) are the eval twin
      of runtime/avra_runtime.c — the executable spec of the
      runtime, one organ mirroring one C file, exactly as the
      backend is one organ. They are not feature semantics. But
      `rt_dispatch` reaches them by STRING MATCH on the callee —
      the accepted residual above — and every rung adds arms.
  (2) THE MEMORY PASS's owned-twin chain (`avra_array_push` ->
      `_owned`, `avra_slot_set`, `avra_map_set`, the two gets):
      five names matched by hand in owned_form. A registry
      COLUMN (`owned_twin: string?` on RtSig) kills the chain
      with no fn-typed field — nothing blocks it.
  (3) THE METHOD FORKS: walks.av, keyed.av, places.av's grow_reg
      and checks.av's list_method_call/grow_call live in the
      features ROOT because impls' dispatch cannot import a
      feature, and method_answer/method_call_reg are a growing
      IF-CHAIN of forks (keyed, grown, walked, …). That is the
      same disease the vocabulary seam rule diagnoses: N builtin
      methods on M receivers is DATA. BuilderRow proves fn-typed
      table rows work when the fn is NAMED and its payloads are
      pointers (TypeId, Reg are single-field structs — they
      survive); the 3-argument indirect-call ceiling is met by
      ONE `MethodCall { e, subject, args }` struct.
DESIGNED — R1, THE REGISTRY COMPLETION (one slice, before or
after M3 at the user's word; M3's components & tables are the
same shape in the language): (a) `MethodRow { receiver, name,
check, lower }` tables in each feature's manifest (`methods =`),
assembled like keywords and builders; impls queries the table by
receiver shape and name; the fork chain and the root files fold
into features/lists/methods.av and features/maps/methods.av.
(b) RtSig gains `owned_twin`; owned_form becomes a lookup.
(c) rt_dispatch matches a `RtHost` ENUM column instead of
strings — adding a runtime fn is a row plus a variant plus an
exhaustive interp arm (the guarantee), never a silent typo. The
hosts themselves stay in interp.av: they are the runtime's twin.

R1 LANDED 2026-09-01 — THE REGISTRY COMPLETION. (a) THE METHOD
VOCABULARY IS ROWS: `MethodRow { name, takes, check, lower }`
declared in each feature's manifest (`methods = table<MethodRow>`
— lists: map/filter/find/any/all/push; maps: get/set), assembled
with the language like keywords and builders, carried on every
context, and selected by ONE lookup (`method_row`) in the
dot-call's typing and lowering; the fork chains died, and
walks.av/keyed.av/grow_reg folded into features/lists/{methods,
walks}.av and features/maps/methods.av (the place-call voices
stay shared). The 3-argument indirect-call ceiling is met by ONE
`MethodCall { e, subject, args }`. (b) RtSig gained `has_owned_twin` (the twin is `<name>_owned` by convention):
the memory pass's five-name chain is one lookup and spells no
runtime name. (c) RtSig gained `host: RtHost`: the interpreter
dispatches EXHAUSTIVELY on the column — a new runtime row names
its host and the compiler demands the arm; no string matching
remains in either engine. The hosts themselves stay in interp.av
— the runtime's twin. rt21–rt29 all clean across the refactor;
one drift caught by a pin (`[]` and `{}` take the rows too).

R2 LANDED 2026-09-02 — the residual hand tables are rows. (a)
`TypeRow { name, arity, slots, judge, builds }` declared by the
owning features (lists: List; maps: Map with its string-key law
in the row's own words; results: Result), assembled with the
language; the annotation rule queries `type_row` and the driver
names no constructor. (b) `PropertyRow { name, takes, check,
lower }` for `length`, declared by lists, maps and str_lit; the
member law and the spine's property lowering query
`property_row`; `length_member` and `length_reg` died. Three pins
followed the rows' words. TRAPS recorded (CLAUDE.md): in a struct
field's fn type a generic PARAMETER and a nullable ANSWER refuse
(a law answers a list, its arguments ride one struct), and
`shape` is a reserved word. AS RECORDED: (a) the TYPE-CONSTRUCTOR table in
typing.av (`applied_arity`/`applied_shape`: "List" 1, "Map" 2,
"Result" 2) is a driver table naming the language's built-in
constructors — it wants to be rows the owning features declare
(`types = table<TypeRow>`), like methods; (b) the `length`
PROPERTY is special-cased by receiver shape in checks.av
(length_member) and expr_spine/lower.av (length_reg) — a
property row in the same registry. Neither blocks anything;
both are the next fork a new aggregate would add.

M3a LANDED 2026-09-02: TABLES as PURE SUGAR — `table<Row> { h |
h \n c | c }` is a builder, no node: each row becomes `Row { … }`
with the header naming the fields, so the struct literal's laws
judge every cell and the list's law the rows; a row's cell count
is the builder's one refusal (`row 2 has 2 cells…`). rt30 29
programs; it caught a PRE-EXISTING silent hole — a struct
literal under an ENUM's name returned Error without a voice and
reached lowering as a defect (three defects, the new mint-order
law among them) — now "`K` is an enum, not a record". Recorded:
generic row types (`table<Box<int>>` — the gram takes a NAME),
a bare empty table is `[]` (a typed empty literal is the ask),
`table<int>` says "no type int is declared" (a builtin-name
wording), and the malformed cascade per line (the @expect +
floor trigger, counts pinned).

M3b+M3c LANDED 2026-09-02: COMPONENTS AS SUGAR OVER FIELD
DEFAULTS, and RAW STRINGS. The one real feature is a field's
DEFAULT (`type P = { x: int, y: int = 7 }`): declared once, typed
under the field's want (a lambda default hears its seat, `[]`
adopts) and accepted by it — THE DEFAULT LAW, at the
declaration; every literal that omits the field fills it at
lowering (a managed default is value-semantic across instances —
copy-on-write, proven). `Param` carries `default: ExprId?`;
captures arrive per slot, so a default finds its field by
POSITION (`fields_zipped`, shared by both spellings). `component
Name { config { … } }` builds the StructDecl; `component Name
inst { f = v … }` builds `let inst = Name { … }` — no node, the
struct laws judge everything. THE EMPTY LITERAL `Name { }` now
parses (defaults made it the common form; the compiler's own
`ListSemantics { }` needs it). Raw strings: `"""` to `"""`, no
escapes, no holes — one Str token; the grams. rt31 29 programs;
the empty-literal gap was its find. Recorded: an instance is a
`let` (a `mut` instance is a spelling away); defaults on
generic fields refuse ("`T`"); `level` is reserved.

M4 LANDED 2026-09-02 — INDEX PAIRING: `for i, x in xs` (or `for
(i, x) in xs`) binds the loop's own counter beside the element:
`Binding.Index(stmt)` — a new binding KIND, because the
resolver's Def binds one name per statement — typed int, never
narrowed, immutable (the place law refuses it), captured by
value; lowering binds it to the turn's index register, so it
costs nothing. No tuples, no `enumerate`: bs2's spelling is
rewritten at parity. rt32 24/24; the one find: index and element
with one name shadowed silently — now "`i` names both". RUNG 14
COMPLETE: places, maps, tables, defaults + components, raw
strings, pairing.

SLICES: M1 places (assignment through paths, `push`, COW, Void)
— M2 maps (`Map<K, V>`, insertion-ordered BY DESIGN so "iterate an
ordered source" needs no rule; `get` answers `V?`; `m[k] = v` is
the place law again) — M3 components & tables (the manifests'
shape) — M4 index pairing (`for i, x in xs`). Recorded: `+=`
and friends (sugar over the place law), mut-ref captures (spec
11.4's `counter += 1` closure — refused by the V1 capture law
until the systems level), `Cell<T>`.

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
  (L3) [x] THE `it` PRONOUN — LANDED 2026-09-01, a parse bow on
       the channel: a method-call argument the pronoun rides wraps
       as an implicit one-param lambda named `it`, and the channel
       seats it — nothing downstream knows the pronoun exists.
       The one real artifact is core's `pronoun_rides`: the
       fingerprint walk's boolean twin, exhaustive over Expr (a
       new expression must answer whether the pronoun crosses it);
       a LAMBDA is its own scope, a nested METHOD call's arguments
       started fresh scopes at their own build (subject only), a
       block's STATEMENTS do not carry it (recorded). THE
       SHADOWING LAW, pinned: inside the call the pronoun wins
       (`let it = 100` stands outside). An unbound `it` names its
       home; a judging context that bails absorbs its arguments'
       hunger (one mistake, one voice). rt26 7/7;
       corpus/pronoun.av. TOUCH-POINTS: ~70 lines (core's
       pronoun_rides, the builder's wrap, one resolve voice), no
       trait growth, zero per-feature cost. The seat-starvation
       voices (rt27) are pronoun-aware. TRIGGER: `wanted_elem`
       (lists) and `wanted_arrow` (closures) are two copies of
       "the want projected through a shape" — the third want
       consumer names `wanted_as`. Still recorded: pipe `|>`, mut-ref captures (rung 14 +
       Systems), fn-value equality, closure printing.

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

## THE SEED — the chain cannot be lost (2026-09-04)

`build/avra` is built by the `build/avra` that is already there, and
NOTHING ELSE COULD BUILD IT. bs2 stopped being the cold path when the
tree outgrew its dialect: it cannot lex a raw `"""` block, and since
`grammar { … }` landed, 30 feature manifests use a construct it has
never heard of. The `avra` shim still named it, which made the
documented recovery a LIE — the real ladder was bs2 -> 551259c ->
26c11fe -> today, one binary per language change, knowledge that
lived in one head for one night.

`bootstrap/seed.ll` is the compiler, EMITTED. `make bootstrap` links
it with clang and then rebuilds from source; `make seed` refreshes
it; the shim's cold path runs the first automatically. Proved by
deleting `build/avra` and recovering in 45s — and the rebuilt
compiler was BYTE-IDENTICAL to the one destroyed.

Why the `.ll` and not the binary: it is portable to any host with
clang and LLVM 21, it is inspectable, and it gzips smaller (0.6MB
against 0.7MB). It carries a target triple, so a new platform makes
its own seed from a working compiler.

THE RULE, and it is the one bs2 broke: REFRESH THE SEED WHENEVER THE
COMPILER'S OWN SOURCE STARTS USING A CONSTRUCT THE SEED DOES NOT
UNDERSTAND. A seed that cannot compile HEAD is not a seed, it is a
fossil. `make bootstrap` is how you find out, and the day to run it
is the day a construct lands and gets dogfooded into `packages/`.

STILL OWED: nothing checks the rule. A gate step that bootstraps and
rebuilds costs ~45s and would catch a fossil the day it forms;
without one, the seed rots exactly as the bs2 path did. FIRING
CONDITION: the next construct dogfooded into the compiler's own
source.

## THE SUBSET NOTES ARE STALE — an audit owed (2026-09-04)

CLAUDE.md carries **76 "bs2 subset notes"**, and they govern how every
line here gets written: "probe before assuming", "fear of traps is how
ugly-but-safe drafts happen". But bs2 no longer compiles this tree —
it cannot even bootstrap it (raw blocks), and the toolchain dropped it
at 556274d. So each note is now a claim about OUR compiler, and many
are simply false.

FIFTEEN TESTED, SIX STALE — the compiler accepts them today:
  a struct literal in a FREE-FN argument list
  a method call on a `const` string
  `xs[i] = v` as an assignment target
  a doc comment on a STRUCT FIELD
  an INDIRECT call with four arguments
  a nested pattern with a sibling binding (`.o(.s(v), k)`)

NINE STILL HOLD, and every one of them is OURS now, not borrowed:
field punning, trait default bodies, `m["k"]`, struct destructuring in
`let`, `|` or-patterns, a bare `table` without its row type, `mut`
parameters, a top-level `let` crossing a fn floor (that one is the
CONST law working), a present-bind in an expression-position match.

WHY IT MATTERS more than tidiness: a stale note is a constraint the
writer obeys for nothing. Every "bind it to a `let` first" and
"hoist it out of the argument list" in this tree may be ceremony
paid to a dialect we no longer use — and the doctrine's own words
are that fear of traps is what produces ugly-but-safe drafts.

THE WORK: probe all 76, then SPLIT the section. What our compiler
accepts is DELETED. What it still refuses moves to "the subset
today", each entry a candidate for the sugar backlog rather than a
trap to write around — six of the nine above already went there in
this round. The section stops being a memorial to a bootstrap and
becomes an honest list of what the language cannot do yet.

## THE ROUND ON THE GRAMMAR AND UNBOXING SLICES (2026-09-04)

WHAT IT FOUND, and what it refused to invent.

A GRAMMAR DEFECT STILL CANNOT NAME ITS FEATURE, and the mechanism
that pretended to was DELETED. `Composed` carried an `owners` table
mapping rule name -> feature, with `feature_of` beside it. Nothing in
the compiler called either: the byte-offset version it replaced was
ALSO test-only, so the round removed a seam that existed to be
tested. It would have been WRONG if used — `stmt`, `primary` and
`type` are contributed by ten features each, and `feature_of` answers
with the first. RECORDED TRIGGER: when a grammar defect is rendered
to a feature author, attribution returns keyed per BRANCH (the unit a
feature actually contributes), not per rule name.

THE TEN-NAME IMPORT, LEFT ALONE. 33 files now write
`use grammar.{Grammar, Rule, Alt, Seq, Item, Prim, Rep, Build,
Expect, Recover}` because `grammar { … }` expands into those
constructors and a file must have them in scope. It is the rule of
three violated thirty-three times, and there is no honest fix in the
language today: Avra has no qualified expression path
(`grammar.Prim.Lit`) and no prelude. RECORDED TRIGGER: the second
construct whose expansion names types the source never spells — then
the shape is a language question (a prelude, or qualified paths),
not a formatting one.

BATTERIES RUN, WELL DRY: bool-literal if-else (0 hits),
`xs[xs.length - 1]` (0), `.length == 0` (17 hits, ALL on strings,
which is the correct idiom — `is_empty` ICEs on text), flag scans
(3 hits, 2 accumulators and 1 genuine fold, now licensed as I5).

## `grammar { … }` — the DSL READ WHEN THE COMPILER RUNS (2026-09-04)

The 89 seconds the pipeline measurement found were 1532 spec cases
each re-parsing 8.5KB of grammar DSL: 54ms of the 58ms assembly is
that one parse. The cure is to stop parsing at run time, and the
first half of it lands here.

`grammar { … }` is a CONSTRUCT, not a string field. Its body is not
Avra — `n:NAME` and `->` are not our tokens — so the LEXER hands the
block over whole (`scan_raw_block`), counting braces while skipping
STRING LITERALS, because `block`'s own grammar writes `"{"` as a
literal and a counter blind to quotes would end there. The builder
then parses it AT PARSE TIME and expands it into the constructors
`seed.av` writes by hand. Pure sugar, exactly as `table<Row>` is: no
node, no semantics, no IR.

WHY A BLOCK AND NOT A RAW STRING. The `"""` form needed no lexer
work and was the first thing built; it was wrong. A grammar is
syntax the compiler understands, not data a program passes, and it
should read that way. The lexer mode is ~30 lines and is what any
raw-bodied construct will want.

WHAT IT COST, honestly: `grammar` became a keyword, so the field of
that name was renamed at ~20 sites — `GrammarParse.built` and
`Language.syntax`, both better names (the latter holds a PREPARED
grammar, not a `Grammar`). And the expansion NAMES the grammar types
(`Prim.Lit`, `Rep.One`), so a file writing a block must import ten
names it never spells — invisible to a text scan, so `tools/idioms.py`
learned that a module containing `grammar {` uses them. The same
invisibility is why the round trip is proved by a spec INSIDE the
package: `shown` analyses a lone source, which has no package to
import from, so it can prove only the refusals.

COLLECTED, same day. `LanguageFeature.gram` is a `Grammar`; 27
feature manifests write `gram = grammar { … }`; `compose_text` is
`compose_grammar`, which gathers each feature's RULES in feature
order and names the start from the first. Assembly PARSES NOTHING.

  one assembly     58ms -> ~8ms
  make test         218s -> 110s
  make gate        ~320s -> 238s

The byte-range attribution went with the text, as expected: a defect
now names its feature by the RULE it landed in (`Composed.feature_of`)
where it once named it by offset. That is the better key anyway — a
rule has a name; an offset only had a position.

`avra new feature` scaffolds the block, so a new feature is born
speaking it.

## THE PIPELINE, MEASURED (2026-09-04) — where `make gate` actually goes

The gate is ~310s. It breaks down, measured end to end:

  make test    225s   of which ONE package (std-avrac) is ~170s
  make corpus   40s
  the rest      45s   (vocab, idioms, scaffold)

And the 170s of a std-avrac test run breaks down further:

  the front end (parse/resolve/sigs/bodies/lower)   51s
  emitting the LLVM module                          ~8s
  clang -O1 over 234,571 lines of .ll                4s
  RUNNING THE 1532 CASES                           127s

CLANG IS NOT THE BOTTLENECK — 4s at -O1, 1s at -O0. Neither is emission.
**The cases are.** And the cause is exact: every spec case calls
`analyze_source`, which calls `avra()`, which ASSEMBLES THE WHOLE
LANGUAGE from its features — composed grammar text parsed by the seed
grammar, merged, validated. Measured at **58ms**, 1532 times: **89
seconds**, 70% of the test run and ~29% of the whole gate.

THE FIX IS ONE ASSEMBLY PER PROCESS, and it wants a language
affordance rather than a hack. Three roads, in order of how much I
like them:
  (a) THE GRAMMAR STOPS BEING TEXT. Features contribute Grammar
      VALUES, not `gram` strings, so assembly is a merge and not a
      parse. Already booked as a self-host endgame ("`grammar { }`
      blocks replace raw-string grams"); this measurement is its
      justification.
  (b) `avra()` MEMOIZED AS A QUERY. It is pure — same features, same
      language — and the query kernel already exists. What it lacks
      is a home: every `analyze_source` builds a fresh workspace, so
      the memo would have to outlive one.
  (c) A once-per-process cache in the runtime. Rejected: a `Language`
      is an Avra value and the seam would need an unsafe cast Avra
      does not have, and should not grow for this.
NOT a mutable global: the epic forbids them, and rightly — but note
that a memo of a PURE fn breaks neither parallelism nor incrementality,
which is why (b) is the honest shape once a home exists.

ALSO MEASURED AND FIXED: `avra_rc_dead_check` was a CALL on every
array read to ask whether the debug guard is on. It is a branch now
(50.5s -> 49.0s on the compiler checking itself).

## UNBOXED RECORDS — a newtype over `int` IS an `int` (2026-09-04)

`ExprId { index: int }` cost THREE MALLOCS and a refcount. So did `Reg`,
`StmtId`, `TypeId`, `DeclId`, `PatId` — the values a compiler makes
millions of. Reading `.index` was a function call; passing one was a
retain and a release. L1 of the AST epic asks for typed ids as
"newtypes over int"; the box defeated that. Now the box is gone:
`ExprId { index: e.index + 1 }` lowers to `r0 + 1`.

NO NEW IR VOCABULARY. `Pack`/`Extract` already existed and already
lowered to `insertvalue`/`extractvalue`; scalar nullables were already
first-class aggregates. Both engines render Pack/Extract as IDENTITY
for a flat record, so the eight consumers were untouched and the
vocabulary protocol never fired.

THE RULE: a record is FLAT when it has exactly ONE field, that field is
a machine word (`Int`/`Bool`), and the record is not generic. Marked at
declaration (`flatten_record`), held in a `flats` table on the type
registry parallel to `shapes` — a side table keyed by a typed id, as
node facts are.

THE THREE LAWS IT TAUGHT:
1. `rides_pointer` answers TWO questions and they are not the same.
   "Does the VALUE ride a pointer?" — a flat record: NO. "Does its
   NULLABLE?" — YES, because a machine word has no spare value for
   absence, so `Opt(flat)` is a ONE-SLOT BOX (`Repr.Boxed`, the third
   representation beside Niche and Pair). When the two answers
   disagreed, LLVM refused the module; when they agreed but a consumer
   asked the wrong one, it miscompiled silently.
2. A READ WEARS THE TYPE OF WHAT IS READ. `slot_read` asked a
   register's recorded type, which under mono may still name a type
   parameter; `field_read` asks the subject's STATIC type. Same species
   as the callee bug in 4e27411.
3. THE AGREEMENT DOOR IS NOT OPTIONAL. `construct_variant` UNIFIED a
   payload against its seat but never called `accepts` — the one place
   a lift is RECORDED. Latent until now: widening into a payload used
   to be identity. A payload seat is a slot like any other.

A RECORD WITH AN IMPL KEEPS ITS BOX. A method may write through `self`,
and a flat record is a value in a register with no identity to write
through — behaviour must never turn on a field count. `unflatten` takes
the marking back when an impl block is declared. This is the RECEIVER
ALIASING debt showing its price: when receivers take value semantics
(the ledger's fix), the exclusion goes and the win grows.

MEASURED, honestly: 52.2s -> 50.5s on the compiler checking itself, and
release sites in the emitted module 37,908 -> 33,035 (-13%). Modest,
and the reason is exact: `array_new` went 4,104 -> 4,295 (+5%), because
every `ExprId?` now allocates the box a niche used to give free. THE
UNLOCK IS A NICHE FOR INT NEWTYPES — reserve one value (an index never
takes `i64::MIN`) and both the value and its nullable cost nothing.
That is a language decision, not a compiler one, and it is the next
question to answer.

## THE SPEED HUNT (2026-09-04) — measured, one landed, one WIP

THE RULE THIS ROUND EARNED: PROFILE, DO NOT REASON. Four changes were
argued from the code and measured afterwards; three did nothing or
made it WORSE, and the one profile run found the winner immediately.

  code_at, bs2's per-byte allocation      no change (noise)
  g.defects() hoisted out of the parse    no change (noise)
  array: three mallocs collapsed to one   2.7x WORSE (52s -> 139s)
  a stronger pointer hash                 1.6x WORSE (52s -> 93s)
  `distinct` off the parse's happy path   parse 29.4s -> 18.9s

The two regressions are the finding, not a footnote: `g_own` is a
global open-addressed table keyed by POINTER, and its cost is CACHE
LOCALITY, not collisions. Uniform allocation sizes CLUSTER it; a
strong hash SCATTERS it. It cannot be tuned, only removed.

### LANDED: the expected-set leaves the happy path

`far_merge` runs at every tie of every branch attempt, and it called
`union_expected` -> `distinct` — an O(n^2) dedup — on a parse that
SUCCEEDS and never shows the set. Dedup is a RENDERING concern: it
now happens once, in `farthest_diagnostic`, the single place a reader
meets the words (`shown_expected`). Parse 29.4s -> 18.9s.

Also landed, both measured as noise but both right: `code_at` is
`s.char_code(i)` (bs2's `char_code` dropped its index, so every
scanner allocated a one-character string PER BYTE — the ledger entry
is paid), and the assembled grammar is PREPARED once (`Ready`:
validated and indexed at assembly, not re-validated per file — 257
times per run for a fixed grammar).

### WIP, NOT LANDED: the refcount in a header (wip/)

The measured prize is real and large: replacing `g_own` with a
sixteen-byte header before every payload took the compiler from
52.6s to 27.3s user — 1.93x — with every phase moving together
(parse 18.9 -> 12.8, bodies 15.2 -> 6.9), which is the signature of a
uniform per-allocation cost. The gate ran in 125s against 302s. All
1587 specs passed.

It is NOT landed because it removes a SAFETY NET the compiler leans
on. `owned(p)` answered "not mine" for any pointer the registry had
never seen, so retaining or releasing a SCALAR, a code address or a
foreign string was silently harmless. A header cannot say "not mine"
by itself. The work in wip/ therefore also carries:
  - every string constant emitted WITH a header
    (avra_llvm_build_global_string_ptr), so the law "every pointer
    Avra holds carries a header" is the backend's too;
  - the runtime's own answers headered (`bool_text`, argv, getenv);
  - a TAG in the kind's high half so a header can be RECOGNISED
    rather than assumed, restoring the "not mine" answer.

Even tagged, the COMPILER (not ordinary programs — those pass, suites
included) overflows its stack inside `avra_rc_release`. Something in
the compiler's own object graph reclaims without bottom once releases
stop being silent no-ops. THE NEXT STEP IS TO FIND THAT, not to
re-argue the design: instrument `avra_rc_release` with a depth
counter that aborts and names the box, and read what it names.

TWO REAL BUGS THE HUNT EXPOSED, both hidden today by the registry:
  (1) A CAPTURE IS TYPED BY THE LAMBDA. `slot_reg` minted a boxed
      slot's load with the READING node's type; a capture is read AT
      the lambda expression, whose type is a managed box, so an `int`
      capture looked managed — the memory pass RETAINED A NUMBER and
      pushed it as an owned slot (`corpus/closures`, the loop
      counter). Same species as the callee bug fixed in 4e27411: a
      read must wear the type of WHAT IS READ. The obvious fix (mint
      from the slot's own register type) is WRONG as written — a
      capture's slot belongs to the ENCLOSING body, so the current
      body's register table is the wrong table to ask. The fix needs
      the captured BINDING's declared type, not a register's.
  (2) THE COLD-BOOTSTRAP PATH IS DEAD. `./avra` falls back to bs2 for
      a cold tree; bs2 cannot lex raw `"""` blocks, and every
      feature's `gram` is one, so the grammar never assembles. The
      tree can only be rebuilt from a working `build/avra` or from a
      worktree at 551259c or earlier. Either restore a bs2-parseable
      path, or state plainly that the binary IS the bootstrap and
      keep one.

## THE OPEN LEDGER — the red team's second round (2026-09-03)

980 programs, 77 candidates, 45 confirmed; every wrong answer,
divergence and crash it found in the LANGUAGE is closed (c6fe1ae,
4e27411). What remains is recorded here, in the round's own order.
Two items sit above the refusal tier and are SCHEDULED; the eight
below it are refusal QUALITY, which is a first-class bar here (P1:
correct on first generation) and each carries the round's own fix.

### (1) SUPPLY-CHAIN EXECUTION during `avra build` — CRITICAL

A DEPENDENCY's `[link] flags` row is spliced unquoted into the
`system()` string that runs clang. `link_inputs` (workspace.av) walks
EVERY package in the workspace, so a transitive manifest carrying
`flags = ["; touch /tmp/PWNED ;"]` runs that command during a build of
a program that never imports it — proved. The paths around it are
`shell_word`ed; the flags are not, on the stated reasoning that "a
`[link]` row is the project's own word". TRUE OF THE ROOT PACKAGE,
FALSE OF EVERY DEPENDENCY — the premise is the bug.

THE FIX IS STRUCTURAL, not a wider fence: replace
`avra_shell_exec_status(cmd)` with an argv row —
`avra_spawn_status(prog, argv)` over `posix_spawnp`/`execvp` — and
build argv as a LIST. Shell metacharacters then mean nothing anywhere
in the pipeline, and `shell_word` plus the `binary_name` quoting in
test.av are DELETED rather than kept as fencing. `${NAME}` expansion
in `expanded` stays: the environment is the invoker's own.

### (2) `avra test` REPORTS GREEN OVER RED — a wrong answer

`./avra test packages/.../tests/./lists_test.av` prints "no spec cases
here" and exits 0 for a file holding 42 cases. `on_cases`
(cli/commands/shared.av) selects with `c.at.file == path` — raw string
equality against the path AS TYPED — while the workspace enumerates
its files canonically through `joined_path`. Any spelling that still
satisfies `under_dir` but differs as TEXT selects zero cases, and a
`//` is what every `"$DIR/$f"` loop produces.

Two changes, the second the important one: (a) canonicalize both sides
with `normalized` (core/paths.av, already used by workspace.av for
dependency paths); (b) ZERO CASES FOR AN ARGUED FILE IS NOT SUCCESS —
a file the user named that yields no cases is a refusal, not "no spec
cases here" and exit 0. The whole job of `test` is the verdict.

### The refusal tier — eight, each with its fix

- A source path not ending in `.av` is SILENTLY DROPPED: `avra check`
  on a file full of type errors prints nothing and exits 0; the same
  bytes named `.av` refuse. Workspace already carries `lone: bool` —
  thread it instead of inferring source-hood from the extension.
- `avra build`/`run` of a non-`.av` file blames a NONEXISTENT
  `avra.toml` and prescribes editing it. `no_target` must not assert a
  manifest's contents without one; the lone-file case needs its voice.
- A module-file `const` is refused as a statement that "runs here",
  and the help ("move it into the entry") does not work. A const emits
  NOTHING — the reading here is that a module-scope const should be
  ADMITTED (resolve binds it, typing checks it, a use lowers from the
  value and not from any body's facts). Whichever way it lands, the
  message cannot stay: it calls a declaration a statement that runs.
- `const N = -1` is refused and NO spelling of a negative constant is
  accepted. `-1` desugars to `Bin(Sub, IntLit(0), IntLit(1))`; slice 2's
  evaluator dissolves this, which is why it was not special-cased —
  but until then the help points at what the user already did.
- F2045 speaks a SECOND time over a value the type law already refused
  (`const N = zzz` earns F3000 and F2045). One guard, matching its
  sibling at features/checks.av: an error-typed value has spoken.
- F2001 `names no type` anchors at COLUMN 1 and labels a `const`/`let`
  annotation "in this signature" — a const is not a signature, and on
  a multi-line declaration the snippet shows the wrong line. Prefer
  the type ref's own span; fall back to the statement's.
- F2039's or-run refusal anchors on the arm's RESULT, not on the
  binding that broke the law. `arm_checks` already holds the parallel
  `typed` list; pass the offending PatId and emit at its span.
- A non-ASCII character in name position emits ONE ERROR PER UTF-8
  BYTE (four for an emoji), and three of the carets land on
  continuation bytes the message then calls unexpected. Consume the
  run in one step in the lexer.

### The process note the round earned

c6fe1ae's message reported a spec count measured on a tree that commit
did not carry (the working tree held further edits). Measure the gate
on the COMMITTED tree, or say which tree the number came from.

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
- ~~Query engine (L6 red-green memoization) wraps the pure passes~~
  — LANDED 2026-09-02 (15a): `query/db.av` is the kernel, the twelve
  families in `language/workspace.av` are the passes as queries.
- A real feature-extensible language lexer

Update this file whenever a slice lands or the plan changes — the
roadmap lives HERE, not in conversation.
