# Roadmap Standards — Design Principles and Doctrine

Evergreen reference. These are DECISIONS, not TASKS. Updated only when doctrine changes, not during development.

**Do not add to this file** unless you are recording a design principle that will outlive the current work. If you're documenting a phase or campaign, write it in the lane docs instead. This file is read-only for daily work — it guides decisions, not tracks progress.

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
- L4 MEMORY AS KNOWLEDGE: the refcount header in the runtime is
  scaffolding; the destination is full static ownership from
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

## Feedback survey — 2026-09-15 (phase C, C1: children and identity derived)
