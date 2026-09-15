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

## THE LANES (opened 2026-09-04) — the work, dished out

Four streams, cut so that no two lanes edit the same files, and one
rule that makes them safe on one machine: EVERY heavy step goes
through `sh tools/watch.sh 4000 <cmd>`, which holds a machine-wide
lock (`/tmp/avra-build.lock`) and a memory cap. A second session's
gate QUEUES; it never runs beside another. The machine has panicked
twice under concurrent load; the lock is the mechanism, the rule is
the memory.

HOW TO TAKE A LANE
  1. Branch a worktree from main: `git worktree add ../avra-<lane>
     -b lane/<lane>`; `cd` there; `make bootstrap` (a cold worktree
     builds from the seed, ~45s).
  2. Work the lane's checklist top to bottom — the order IS the
     dependency order. Tick items here as they land.
  3. Every gate, suite or whole-package check: `sh tools/watch.sh
     4000 make gate` (or `./avra test …`). Never a bare `make gate`,
     never a background one.
  4. Every slice: red-team, then review-round, ledgers fed (this
     file, CLAUDE.md, DOGFOODING.md), commit message handed over.
     Nothing commits without the owner's word.
  5. To land: rebase on main, full gate through the lock, merge.
     A commit that adds a COMPILER FEATURE leaves the tree compilable
     by main's current compiler — the compiler's own uses of the
     feature land in the NEXT commit, once the seed carries it (lane
     D slipped twice; the cheap pre-flight from the lane is `sh
     tools/watch.sh 4000 ../avra/build/avra check "$PWD/packages/cli"`
     — the SHIM cds to its own root, so `../avra/avra` would check
     main's tree — and the integrator should run it before merging;
     lane A's tool).
     THE MERGER runs `make seed` and commits the refreshed
     `bootstrap/seed.ll`; that file is DERIVED and is never merged
     by hand.
  6. A lane may run IN THE CLOUD (its own machine: no queue) once
     the probe below says the toolchain is there.

LANE 0 — CORRECTNESS FIRST (half a day; anyone; touches cli/ and
the runtime's host seam). Two wrong answers from the red team's
open ledger, above every other item:
  - [x] SUPPLY-CHAIN EXECUTION (PAID 2026-09-04): a dependency's `[link] flags` are
        spliced unquoted into the `system()` string that runs clang
        (`shared.av:180`, `workspace.av:837`). FIX: an argv row —
        `avra_spawn_status(prog, argv)` over `posix_spawnp` in the
        runtime, argv built as a LIST; `shell_word` and
        `binary_name`'s quoting DELETED, not fenced. DONE WHEN a
        manifest with `flags = ["; touch /tmp/PWNED ;"]` builds
        without running it, and the corpus is green. — DONE: the
        runtime's `avra_spawn_status(prog, args)` over posix_spawnp,
        `link_argv` in the library (one word per input, pinned by
        workspace_test with a poisoned manifest), `shell_word` and
        the shell row deleted; the live proof: clang refused the flag
        as a nonexistent file and nothing ran. corpus/native pins the
        verdicts (3, 127, 137, a literal word).
  - [x] `avra test` GREEN OVER RED (PAID 2026-09-04): `on_cases` selects `c.at.file ==
        path` (`shared.av:113`) as raw text, so a path spelled with
        `//` or `./` selects zero cases and exits 0. FIX: normalize
        both sides (`core/paths.av`'s `normalized`), and ZERO CASES
        FOR AN ARGUED FILE IS A REFUSAL, not "no spec cases here".
        DONE WHEN `./avra test packages/std-avrac/src/./core/tests/
        lists_test.av` runs the cases and a file with none exits 1.
        — DONE: `Program.cases_at(path)` normalizes both sides (six
        spellings pinned); the caseless file refuses in its own
        words and exits 1.
  - [x] THE RED TEAM'S YIELD ON LANE 0 (2026-09-04; 14 programs and
        9 live CLI attacks): ONE WRONG ANSWER — the child's output
        came out BEFORE the parent's buffered stdout (the old
        `system()` had it too); `avra_spawn_status` flushes at the
        seam, and corpus/native pins the order. ONE MASKED REFUSAL —
        a spec file that failed to analyze had no cases, and the new
        "holds no spec cases" voice hid its diagnostics; an unclean
        file now reports them. TWO POOR REFUSALS — `clang` missing
        from PATH said "clang failed linking" and a test binary that
        could not start said "the case named above trapped"; both
        name 127 now. AND A CENTRALIZATION: `${NAME}` expansion moved
        into the library beside `link_argv` (a hole naming nothing
        leaves no empty word), where workspace_test pins it. Survived:
        3000 arguments, an empty word, an empty program name, a path
        with a space, 200 spawns under the guard, `..` past the root,
        an absolute path, a lone spec file, a trailing slash, a
        non-source file, a `./` directory; and impl blocks of two
        packages sharing a bare name keep their own methods
        (packages_test pins the by-name index's package law).

LANE A — SPEED (owns runtime/, grammar/, core/ hot paths;
measures with `./avra test packages/std-avrac --time` and `sample`,
user CPU, never wall). Baseline 2026-09-04: parse 14.2s, resolve
2.4s, sigs 0.3s, bodies 8.3s, lower 6.2s; the 1571 cases ~17s;
the compiler checking itself 28.8s.
  - [x] PROFILE FIRST (2026-09-04): one `sample` of the compiler
        checking itself named two things the ledger had not: the
        hottest frames by self time were `is_impl_of`/`impls_named`
        — `methods(ws, target)` walked EVERY declaration in the
        workspace per method dispatch to find impl blocks by name,
        because `Decls.impls` is keyed by target and filled only at
        registration — and `source(ws, f)`, asked per declaration
        typed, re-read the file, re-fingerprinted it and rebuilt its
        line index every time. FIXED: `Decls.impls_by_name` (filled
        at mint, one lookup) and `Workspace.sources` (one read, one
        index per file per run; a live host clears an entry when its
        file changes). MEASURED: the compiler checking itself 28.8s
        -> 22.3s; the suite's `bodies` 8.3s -> 1.0s, lower 6.2s ->
        5.2s; the gate 152s -> 135s wall. Parse stayed at 13.8s —
        the engine, next.
  - [x] THE MANIFEST, PARSED PER FILE (2026-09-04): `manifest(ws, i)`
        re-read and re-parsed `avra.toml` at every ask, and
        `is_excluded` asked it per file. `Workspace.manifests` (one
        parse per package per run): the suite's `resolve` 2.2s ->
        0.67s; the check 22.3s -> 21.0s. The same profile blamed
        `Decls.mint`; the frames were `innermost`/`decl_span` inlined
        beside it — `range_bodies` read each owner's span from the
        store once per (expression, owner) pair. Spans are read once
        per file now; MEASURED AS NOISE on parse, kept for the shape.
        THE ROUND'S TRIGGERS: `source` and `manifest` now share one
        Table-memo shape (two copies wait; the third input family
        memoized this way — 15b.2's lock file — names an `input_memo`
        verb); packages_test's `answered(p)` twins testing's `shown`
        for a Program (the third test rendering a Program's answer
        names `Program.shown`); the empty `Manifest` literal is spelled
        once in `manifest()` (a second site names `no_manifest()`).
  - [x] THE BUILDER DISPATCH (2026-09-04): every node built walked
        all 34 features' builder rows with string compares to find
        its builder. `Language.builders` (indexed once at assembly,
        first registrar wins — dispatch's own order) and
        `build_named` (one lookup). MEASURED: the suite's parse 14.2s
        -> 11.9s; the check 21.0s -> 19.7s.
  - [x] THE PACKRAT MEMO'S KEY (2026-09-04): every rule attempt spelled
        `"${name}@${cursor}"` (an interpolation, an allocation) and
        probed two string maps. The memo is one flat table of
        `rules x (tokens + 1)` ints indexed by rule ordinal and
        cursor, holding one past the answer's index in a results list
        — two reads, no key — with the ordinals settled once in
        `ready`. MEASURED: the check 19.7s -> 18.5s; the suite's parse
        11.9s -> 11.6s (its cases are tiny; the compiler's own files
        carry the win). A two-level table was the first design and a
        probe refused it: a nested element write copies the row
        (recorded under lane C). TRIGGER: "the first registrar wins"
        is spelled twice (`builder_index`, coherence's `registrar_of`,
        which answers the FEATURE's name); a third reader of the
        registration order names it.
        FOUND ON THE WAY, AND FIXED HERE: `packages/std-cli/src/cli.av`
        was a SYMLINK into the old bootstrap tree, so every worktree
        read one mutable file outside git — and while lane C edited
        it, `./avra test packages/cli` flickered red on main and in
        every lane. It is a real file now, the forge's committed
        content; the vendored package still dies with lane B's
        `@std/cli`.
        FOUND ON THE WAY (manifests — lane B / 15b's owner takes it):
        an ABSOLUTE `path` in `[dependencies]` was joined under the
        manifest's directory (`/tmp/x/avra.toml` naming
        `/Users/.../std-avrac` looked for `/tmp/x/Users/.../std-avrac`
        and refused F4007 with that mangled path). FIXED 2026-09-05 by
        lane B where it belonged — in `joined_path` itself
        (`@std/path`), which now answers an already-absolute name as
        itself, so every caller is right at once and no call site
        needs a guard. Lane D confirmed the mechanism: the leading `/`
        became an empty segment that `normalized` then dropped.
  - [x] THE ENGINE'S CAPTURE COPYING (MEASURED and REFUSED 2026-09-05): repetition captures are
        copied per append, so an N-statement program parses in
        O(N^2) (the debt below the ledger). `Many` becomes a prefix snapshot
        ({shared list, count}): push at the tip, copy only after a
        real rollback. DONE WHEN parse drops measurably on the
        suite and the corpus is green; record the number here.
        PROFILED 2026-09-04 (the suite's parse, 10.4s): ~60% is
        allocation and refcount traffic under `match_seq`/`match_alt`
        (a result record, a state, a captured value per hit); 13% is
        `run_grammar` RELEASING the memo at the end of each file; 6%
        is `Decls.mint` CLONING `keys` per declaration (the field read
        retains the map, so `set` sees it shared — lane C's alias
        borrow, S4, pays it; `range_bodies` clones the same way);
        `bind_label`'s list copy is 2%. The capture copying is not
        the parse's weight — the records per hit and the memo's
        teardown are.
        THE CLAIM MEASURED (2026-09-05): a body of 500, 1000, 2000,
        4000 `let` statements checks in 0.05, 0.11, 0.22, 0.51s of
        user CPU — LINEAR, the per-append copy a 16% superlinearity
        at 4000 statements, below any real file's noise. The prefix
        snapshot is not needed; struck.
        THE MEMO ITSELF was tried WITHOUT (2026-09-04): parse 10.4s ->
        11.4s, so packrat pays for itself here; REFUSED as a lever.
        SIZE-CLASS FREE LISTS in the runtime (2026-09-04): a box of up
        to 256 bytes is recycled through a per-class list, the class
        in the header's `len` (owned strings wear KIND_STR so theirs
        reads from the text length). MEASURED: the suite's parse
        10.4s -> 8.7s, lower 3.6s -> 2.9s, the suite 30s -> 25.7s,
        the cases binary 8.6s -> 7.2s, the compiler's self-check
        ~15s -> 13.0s. ONE CLASSED BUFFER PER LIST
        (2026-09-05): a list's cells and owned marks share one
        allocation, and a buffer of capacity 8, 16 or 32 is recycled
        through a per-capacity list (a bigger one is malloc's and
        grows in place). MEASURED: the suite 21.6s -> 14.7s (parse
        8.6s -> 5.7s, lower 2.9s -> 1.7s), the cases binary 7.2s ->
        4.8s, the compiler's self-check 13.0s -> 8.7s; the gate
        48.7s -> 33s user. The lists are BOUNDED (16384 per class):
        unbounded, they hoard a phase's freed memory by class. THE
        PEAK, HONESTLY: a compiler run's footprint is ~2.1-2.4 GB
        either way (main's runtime 2083 MB twice; this one 1898 and
        2319 MB — the poller's noise). The 1.4 GB the watchdog
        reported before 2026-09-05 was RSS under compression, an
        under-report; the watchdog reads the physical footprint now
        (`footprint`, per process, the Summary skipped — its first
        form summed the Summary too and read a gate at 4.5 GB).
        HONEST PEAKS (2026-09-05): the suite 3551 MB — the compiler
        at ~2.4 GB HELD while the 1.1 GB cases binary it spawned
        runs (the binary peaks at 1065 MB with main's runtime, 1089
        with this one: no leak). The cap is 6000 by default, a
        wreck-catcher; the shape is the next item.
  - [x] THE LOOP'S PRELUDE LEAKED (FOUND by the accounting 2026-09-05;
        lane C's S4c-1 landed the same fix first, line for line): the
        memory pass settled a loop condition's managed reads at the
        ENCLOSING scope's end — once — while the condition ran every
        iteration, so `while self.rows.length <= i { self.rows.push(…) }`
        leaked one reference per extra iteration, the next write saw
        the list as SHARED and cloned it, and the old version could
        never die. Every table write in the compiler has that shape
        (`Table.keep`, `Decls` columns, `union`'s accumulators): 1.27
        GB of live clones in a self-check, 244k clones made, found by
        THE ACCOUNTING (below). The prelude is a scope of its own now,
        settled before the test. MEASURED: the self-check's footprint
        2372 -> 955 MB, the suite's peak 2399 -> 1189 MB, the gate's
        2405 -> 1249 MB; the suite's bodies 0.99s -> 0.47s, sigs 0.16
        -> 0.05, lower 1.87 -> 1.60, parse 6.0 -> 6.5s (the executor's
        loops now settle per iteration) — net 9.5s -> 9.1s of compile.
        Eleven-line witnesses, all clean under AVRA_RC_GUARD; S4c-1's
        golden in lower_test.av pins the release before `while`.
  - [x] THE ACCOUNTING (2026-09-05): `AVRA_MEM_STATS=1` makes the
        runtime say what a process's memory is MADE OF — live bytes
        and peaks by category (records, strings, list boxes, list
        buffers, map boxes, map indexes), list buffers by capacity,
        and live list bytes by the ALLOCATION SITE that made them
        (the constructor's return address, unslid, so `atos -o
        build/avra <addr>` names the Avra fn; a clone, concat or
        slice names its Avra caller). Printed at exit and before an
        exec. Under AVRA_RC_GUARD it replays the life of a sample box
        per site whose count never balanced. What it showed first:
        records are ARRAYS (structs pack as lists: a two-field struct
        is a 48-byte box and a 72-byte buffer), 5.3M small lists in a
        self-check, and the clone hoard above.
  - [x] THE FAR RECORDS RETAINED (FOUND and PAID 2026-09-05): after the prelude fix a self-check
        still holds 2.78M `FarthestFailure` records made at terminal
        misses (`match_prim`'s `.Lit`/`.Named` miss arms, 100% of
        those made) and 788k merged ones with their expected lists —
        ~600 MB, 60% of what is left. A lone 4000-statement file
        keeps 184k. The results that carried them die; something else
        holds them. The guard's replay, aimed at the site, named it:
        the fold's `mut farthest: FarthestFailure? = null` CELL. A
        cell wore its FIRST VALUE's type, and a `null` widened into a
        boxed nullable keeps the null's own type (that widen is
        identity), so the memory pass saw no managed cell to settle
        at the scope's end — and `x = null` settled nothing, since a
        store settled by the VALUE's type. Two laws: the cell wears
        its binding's declared type; a store settles by the cell's
        type. Bisected to a twelve-line witness (two merges through
        the cell, no loop); six red-team shapes (list, string, a
        cell in a loop body, a generic `T?`, a never-assigned cell, a
        `mut` parameter's field) clean under the guard, eval ==
        native. MEASURED: the self-check's footprint 955 -> 268 MB
        (2372 at the day's start), the far sites 0 live of 2.47M.
  - [x] SIZED BOXES (2026-09-05): a record, a variant, a closure and
        a list literal took a cap-8 buffer — 72 bytes for a two-slot
        struct, 5.3M small lists in a self-check — because every box
        was born by `avra_array_new`. `avra_array_sized(n)` (a row,
        sharing the evaluator's array-new behavior) gives a box a
        buffer of exactly its slots; the size register is minted
        before the box, the answer last; a clone takes its source's
        length; buffers of one to eight slots have their own free
        lists, and a small box that grows goes to eight. MEASURED:
        the self-check's footprint 268 -> 230 MB (accounted 215 ->
        170), the suite's peak 328 -> 282 MB; time unchanged (9.4s
        against main's 9.45s on the same check). Two IR goldens and
        one lowering golden regenerated from the new truth.
  - [x] THE FARTHEST POINT AS ONE SLOT — tried and REFUSED
        (2026-09-05): a miss made a `FarthestFailure` record and every
        result merged its children's, 2.47M records per check. One
        slot in the context (written by a miss at least as deep,
        `mut cx` threaded through the match fns — a generic mut
        parameter writes through under mono, probed) took parse 6.6s
        -> 6.2s and deleted three folds — and changed the messages:
        the failed sub-match's OWN expectations became the union of
        every attempt at the deepest cursor ("expected `<`, `?`, `,`
        or `)`" for "expected `)`"), five goldens red, six broken
        programs reading differently against main. The per-result
        farthest is user-facing semantics, not an optimization.
        Reverted; the records stay.
  - [x] THE GATE'S TWO SPARE COMPILES (2026-09-05): the scaffold check
        and the cli suite each compiled the whole compiler again for
        one case and for nine — 19s of a 39s gate. The scaffolder's
        template is now scaffolded into std-avrac BEFORE the suites
        run and removed after, however they end (`make tested`), so
        its test is one case of that suite; and `avra test <package>`
        knows a package's cases from PARSING alone — the root's files
        entered, their items minted, nothing typed — so a package
        without cases says so in 0.2s instead of analyzing its
        dependencies. The fast exit needs a CLEAN parse: a broken
        spec file parses to no cases, and its refusal is the answer
        (pinned). The verdict vocabulary (`Verdict`, `verdict_of`,
        `plan_binary`) moved to the runner beside `cases_entry`, with
        its nine cases. MEASURED: the gate 39s -> 20.5s of user CPU,
        1726 cases.
  - [x] THE INTEGRATOR PRE-FLIGHTS MAIN'S COMPILER (2026-09-05, lane D's
        find, two broken merges): the integrator merged BEFORE its
        fixed-point rebuild, so a lane whose TREE uses a feature
        main's STANDING binary lacks left main merged with a compiler
        that cannot parse it and a stale seed — recoverable only by
        hand. It now asks, from the lane's worktree and before the
        merge, whether main's binary can check the lane's
        packages/cli. The binary is NAMED, never main's shim (which
        cds to main's root and would check MAIN's tree), and the path
        is absolute for the same reason. A red does not refuse: the
        lane's OWN product is asked the same question, and since it
        built and gated this very tree, main is seeded from it after
        the merge and the fixed point re-derives main's own. Only
        when NEITHER compiler reads the tree — broken, not ahead — is
        the merge refused, with main untouched. PROVED both ways: the
        seed from the commit before trait default bodies landed
        refuses today's tree and refuses a trait-default program
        ("expected `}` while parsing `stmt`") where today's binary
        accepts it.
  - [ ] CORE-SIDE FACTS FOR THE THREE LANGUAGE ASKS (sized ints,
        float, Bytes), recorded by lane A 2026-09-05 because they are
        about lane A's files and whoever takes those slices needs
        them. Verified in the tree, not asserted:
        AMENDED 2026-09-06, AND THE AMENDMENT IS THE POINT: this
        entry UNDER-SIZED float, a lane sized their ask from it, and
        the under-sizing propagated through two sessions before
        anyone opened the files. It described the SEAT half and
        omitted the VALUE half entirely.
        * `RtKind` is `{ I64, Ptr, Void, I32, U32 }` at
          core/ir.av:278 — the sized-int slice landed and APPENDED,
          so the ordinals held. The extern wall still cannot DECLARE
          a float seat, and `rt_kind_of` maps every non-void
          non-pointer to I64 — a double in an integer register,
          silently wrong, the same class as the width bug above.
        * GROWING RtKind IS STILL SMALL AND ENFORCED, but it is no
          longer ONE match: `make vocab` names FIVE consumers
          (`ll_rt_kind`, `rt_arg`, `answers_word`, `answered`,
          `narrow_sign`), two of them converted from `is .I64` tests
          by lane A the same morning this entry was written — so the
          entry was stale about its own author's change. The
          interpreter still dispatches on RtHost, never on RtKind —
          AND THAT SENTENCE EXPIRES WHEN lane/substrate's extern host
          merges (f9e2168), which gives `interp.av` four exhaustive
          RtKind consumers and takes `make vocab` from five to eight.
          Recorded as a trigger rather than amended, because the fact
          is TRUE ON MAIN today (main's interp.av has zero RtKind
          mentions, the keeper reports five) and a record that
          describes a LANE is wrong about the tree it lives in. Amend
          at the merge, not at the report.
        * AND THAT IS THE LEAST OF FLOAT. A WIDTH IS A PROPERTY OF A
          SEAT; A FLOAT IS A VALUE, which is why the sized-int slice
          is the COUNTER-EXAMPLE to cite and not the precedent. It
          created no value category, so nothing dispatched. Float
          creates one: `Val` in interp.av has six variants and needs
          a seventh, with 57 `.I(` sites in that one file;
          `bin_value` emits `avra_llvm_build_add` and must become a
          dispatch on OPERAND TYPE rather than on the operator; the
          type registry gains a primitive and typing gains the rules
          for a second numeric type (what `1 + 1.5` means, whether
          it means anything, what `==` does across them). A lexer
          literal and four extern seats are the small half. THE
          WITNESS IS A REQUIREMENT, not an option — a double in an
          integer register is silently wrong and no test that stays
          inside Avra can see it.
        * A NEW SCALAR TYPE MUST JOIN `is_managed`'s unmanaged arm
          (language/memory.av): `.Ptr or .Int or .Bool or .TypeName
          or .Var or .Null or .Error or .Void -> false`. One line —
          but omit it and the memory pass treats the new type as a
          BOX, retaining and releasing a number. `Ptr` is the closest
          existing precedent for what a new scalar must do at every
          seam; read it end to end before designing one.
        * BYTES MUST NOT REUSE THE STRING BOX. `str_len` is
          `(h && h->len) ? h->len : strlen(s)`, so a zero length
          falls back to `strlen`. A wart for text; a correctness bug
          for a BLOB, since an empty blob is legal and common and the
          fallback walks off the end. Bytes needs its own kind where
          the header length is authoritative.
        * `make externs` CANNOT SEE A THIRD PARTY'S HEADERS. It
          closes our half of the width class only. A binding to
          someone else's library is unprotected until the sized types
          land — do not write declarations against the keeper.
  - [x] THE EXTERN SEAM ANSWERS EXHAUSTIVELY (2026-09-05, found by
        re-checking a claim lane A had already made confidently). I
        told the sqlite lane that `RtKind` has ONE exhaustive consumer
        (`ll_rt_kind`) so the compiler would demand the arm for a new
        width. TRUE AND INCOMPLETE: two more consumers were `is .I64`
        BOOLEAN tests, which the compiler cannot see as partial.
        `rt_arg` read "not I64 means pass UNCONVERTED" — right for
        three variants, wrong for four, and every conversion that
        matters (`ptr_to_int`, the bool `zext`) lives inside the
        branch it skips, so a new `i32` seat would take an i64
        register untruncated. `answers_word` is the same shape on the
        way back. Both are exhaustive matches now, so a new kind must
        state how it crosses the boundary or the build fails.
        THE KEEPER GREW A SECOND REGISTRY: `make vocab` guarded `Ins`'s
        eight consumers and nothing guarded `RtKind`'s, precisely
        because `RtKind` stayed three variants and never grew. It now
        names RtKind's three and refuses BOTH a catch-all AND an
        `is .Variant` test there — an `is` is a partial handler the
        compiler cannot flag. Proved by restoring the boolean test and
        watching the gate name the fn. THE GENERAL RULE: for a
        REGISTRY enum, `is .Variant` is a catch-all wearing different
        clothes; for a PROJECTION enum it stays the right idiom.
  - [ ] THE 43 STRING-TAKING EXTERNS GO FROM SAFE-BY-CONSTRUCTION TO
        SAFE-BY-CONVENTION THE DAY `Bytes` LANDS (recorded 2026-09-05
        while reviewing the sqlite lane's UTF-8 validator; a TRIGGER,
        not open work). PREMISE RETRACTED: an Avra string CAN hold a
        NUL and a program mints one with no foreign input at all —
        `@std/text`'s `from_codepoint(0)` (landed fc7026d, the same day
        this entry was written). So the safe-by-construction half was
        already false when recorded; what landed instead was a guard at
        the crossing (`nul_at`/`has_nul`, 26 sites), not the length law
        below. The seat count is 109 today, not 43. So handing one to C, which reads a bare
        NUL-terminated `const char*`, is safe for a reason nobody
        wrote down: there is nothing to truncate.
        U+0000 IS VALID UTF-8 and is one byte. So a correct
        bytes-to-text conversion — which the sqlite lane's validator
        accepts, rightly — MINTS a perfectly valid Avra string with
        an embedded NUL, and every one of the 43 `extern fn f(s:
        string)` sites in the tree becomes a place where C sees a
        prefix. The conversion is right, the validator is right, and
        the hazard is real: it arrives from the direction where
        everything is correct.
        NOT FIXED BY REFUSING NUL — that would make the converter lie
        about what it validates and MOVE the defect rather than close
        it. The answer is the law the sqlite lane took: text crossing
        to C carries a LENGTH, never a terminator. Their C API was
        already shaped for it (`sqlite3_bind_text(…, int nByte, …)`),
        and the `-1` sentinel meaning "measure with strlen" is the one
        form a binding must never use.
        NO KEEPER: a check over `extern fn f(s: string)` would fire on
        all 43 today, every one of them legitimate, and teach people
        to license it — the same reason the `is .Variant` law has no
        ratchet. WHEN IT FIRES: the first bytes-to-text conversion.
  - [x] THE WELL IS DRY FOR LANE A (re-profiled 2026-09-05 at the
        day's end, main 9e8916d, self-check 8.2s / gate 20.2s). The
        remaining cost is three things and lane A owns none of the
        cheap part of any of them:
        1. REFCOUNT TRAFFIC, ~35% of samples, inside
           `avra_rc_retain`/`avra_rc_release` themselves. LTO across
           the runtime was measured NEUTRAL (9.34 vs 9.36), so it is
           the bodies, not the calls.
           CORRECTED 2026-09-05 (lane C): this entry said "that is
           S3 liveness" and attributed the whole third to it. The
           MEASUREMENT stands; the attribution was wrong. S3 governs
           only the slot `Load`. The other half is the OWNED TWIN —
           `owned_form` chose `avra_array_get_owned` whenever a
           call's destination was managed, unconditionally, so a
           field read minted a +1 that lived to the scope's end and
           the write after it found the value shared and cloned.
           That is S3b (cfa834d), and it is where the compiler's own
           hot paths were: lane A's `known_id` fix was THIS mechanism
           applied at ONE site by hand, which is why it bought about a
           second and no more. RE-MEASURED HERE on S3b: the
           self-check 8.2s -> 7.2s (three runs, 7.15/7.28/7.43), the
           gate 20.2s -> 18.9s. STILL UNPAID, so the number is not
           attributed twice: retain/release at CALL SEATS —
           `retained_args` retains every managed argument of every
           call because callee-cleans requires it, and no liveness
           analysis touches that. A callee that only READS its seat
           needs no caller retain; that is a different design and it
           is scoped nowhere.
        2. ALLOCATION, ~12% (`box_alloc`/`box_free`/`buf_alloc`/
           `buf_free`). Already paid twice today — size-class free
           lists, then one classed buffer per list, then sized boxes.
        3. THE FIELD READ, ~10% (`avra_array_get` + its owned twin).
           CONSIDERED AND REFUSED: a struct field read passes a
           COMPILE-TIME index into a compiler-built box, so its
           bounds check is provably dead weight and an unchecked row
           would drop a load and two branches. MEASURED SHARE: ~2% of
           the check, ~0.2s of 8.2s. REFUSED because that bounds
           check is the trap that turns a wrong generated index into
           a named failure instead of memory corruption — this tree
           has been bitten by exactly that ("index -1" from a
           name-keyed table read). Two percent is not worth trading a
           loud failure for a silent one. Emitting the load INLINE in
           the backend was refused for a second reason: it would
           couple the backend to `AvraArray`'s private layout, which
           changed twice today.
        Further rounds here would start inventing work. The next real
        gain arrives with S3, or with a persistent memo across
        processes (recorded, big, not scheduled).
  - [ ] ONE PRECEDENCE LEVEL COSTS ~9% OF EVERY COMPILE, measured
        2026-09-07 across 44d5e31 -> b82bfaf. Not an argument against
        the feature that revealed it — the owner asked for bitwise
        and it is right — but a COST MODEL NOBODY HAD, and the next
        operator family costs the same again.
        THE NUMBERS, and the disproportion is the finding: the source
        grew 2.0% (36,801 -> 37,523 lines of std-avrac) while the
        self-check grew 11% (5.25s -> 5.83s user). Exact counts say
        it is MORE WORK rather than slower work — retains 557M ->
        610M (+9.4%), releases 662M -> 725M, list reads 402M -> 439M,
        list writes 481M -> 525M, all within a point of each other.
        THE CAUSE IS ONE GRAMMAR RULE. `expr_spine/mod.av` gained
        exactly one: `bitwise = l:additive ( op … r:additive )*`,
        inserted between `coalescing` and `additive`, taking the
        expression chain from 16 rules to 17. Every expression in
        every program now descends one level deeper, and each level
        costs a `MatchResult` box, a bindings list and the
        retain/release traffic they carry — which is the recorded
        trigger about a MatchResult per attempt, arriving with a
        price tag.
        SO THE ENGINE'S COST IS PER LEVEL, NOT PER OPERATOR: a family
        of six operators sharing one level cost what one operator
        would. A future precedence level — a pipeline, a comparison
        chain, a range band — costs another ~9% whether it carries
        one operator or ten. That is the number to weigh before
        adding a band, and the argument for precedence CLIMBING over
        a rule-per-level chain if the count keeps rising.
  - [x] THE WELL WAS NOT DRY — the entry above is REFUTED, and its
        reasoning is the instructive part (2026-09-05, main 7b90a46,
        self-check 7.21s -> 5.25s, the gate 18.9s -> 15.9s user).
        Point 1 argued: LTO across the runtime measured neutral,
        "SO it is the bodies, not the calls". Both halves of that
        dichotomy were wrong, and the P6 answer was underneath: it
        was the FRAME the bodies were forced to build. Each hot leaf
        had a COLD PATH INLINED INTO IT — a lazy `getenv` guard in
        `rc_guarded`/`accounting`, an 80-byte `char msg[80]` for the
        out-of-bounds message in `avra_array_get`, the grow branch in
        `avra_array_push`, a `__builtin_return_address` read for the
        accounting site in `avra_array_sized` — and clang hoisted the
        register saves those need ABOVE the fast path. `avra_rc_retain`
        saved FOUR register pairs, 64 bytes of stack, to perform one
        `add`; `avra_array_get` reserved 128 bytes per read. LTO
        cannot see this: the cold code is INSIDE the hot function.
        THE FIX is one shape, applied six times: the cold path moves
        out of line (`noinline`, `cold`, and `noreturn` where it
        traps) so the branch to it is a TAIL call, and the two env
        flags settle in `__attribute__((constructor))`. All six are
        now frameless leaves — verified in the disassembly, which is
        how the defect was found and the only honest way to confirm
        the fix.
        THE PROOF OF NO SEMANTIC CHANGE: the census counts are
        byte-identical across the fix — 557,093,839 retains,
        661,868,151 releases, 104,997,459 reclaims, 402,442,417 list
        reads, 481,289,282 list writes, before and after. The
        compiler does the same work on the same boxes in the same
        order; only each operation got cheaper.
        ITS BOUNDARY, named by lane C who nearly reached for it: this
        proof works for a COST-ONLY change and not for a PLACEMENT
        one. A suite proves the answers did not move; the invariant
        proves the WORK did not — so a memory-pass change that moves
        where a retain sits (S3, S3b) cannot use it, because moving
        the counts is exactly what it does.
        TWO EXPERIMENTS REFUTED HERE, recorded so they are not
        retried: (a) deduplicating the expected-set merge in
        `far_merge` — its `concat` is the single largest copy origin
        at 2.66M calls, and the reader deduplicates anyway, so the
        merge provably changes no message — measured 3% SLOWER, both
        with `all` (a closure box per merge) and with a hand loop;
        (b) skipping the empty `diagnostics.concat` in `match_seq`
        (1.54M calls) — measured NEUTRAL. Both fail for ONE reason,
        which is now the standing caution for this runtime: lane A's
        own size-class free lists made allocation cheap enough that
        AVOIDING an allocation with a scan, or even with a branch, is
        a losing trade. Measure before removing an allocation here.
        A CONFIRMED ONE, 2026-09-07, AND IT IS RECORDED HERE BECAUSE
        THE COMMIT THAT MADE IT CANNOT SEE IT. `6b38795` turned the
        `once` cache from a scan into a pointer index — 3.00 pointer
        compares per read to 1.00 in this compiler, three collisions
        in a whole self-check — and measured NO clock change here
        (5.85-5.93s against 5.87-5.93s), because 286k compares out of
        billions is under the noise floor. The commit says so.
        THE WIN IS REAL AND BELONGS TO ANOTHER WORKLOAD. The cost was
        O(tables) per read: this compiler holds one `once` table and
        paid 3, the HTTP lane's framer holds twenty and paid 19. Their
        shipping measurement after merging it: 2185 -> 2045 ns a
        parsed head, ~140 ns, 6.5%, which is what 52 reads x 18 saved
        probes should cost. Predicted from the counts, confirmed on
        the clock, by the lane whose workload shows it.
        SO A CHANGE CAN BE INVISIBLE IN THE TREE THAT MAKES IT. A
        self-check is one program with one shape, and "no measurable
        change" here means only that — this lane's stopwatch is not
        the language's. When the counts say a cost is O(n) and n is 1
        locally, hand the clock to a caller with a bigger n rather
        than concluding the well is dry.
        AND THE STRINGS LANE RE-TOOK IT WITH A CONTROL, which is the
        method worth copying rather than the number. Probe counts
        PREDICTED FIRST from what each path emits, then five
        independent before/after pairs: 1 probe 47->40 ns, 1 probe
        25->17, 3 probes 210->191, 9 probes 655->598 — ~6-7 ns
        recovered per read. THE CONTROL IS THE HALF THAT MAKES IT A
        FINDING: the ZERO-probe paths (a greedy scan, a scalar ask, a
        marked last hole) moved by noise and no more. Without them the
        same five numbers are indistinguishable from a machine warming
        up, and this tree has already published one product of two
        aggregates and one frame fix inside its own noise floor.
        THE CLAIM IS PER-READ, NOT PER CENT: "6-7 ns per read, and the
        read count is what you can count" survives being quoted; a
        percentage is a fact about one benchmark's denominator.
        AND A FLOOR IS NOT A REFUTATION: their router's composite
        dispatch bench has a +/-40 ns floor and cannot see its one
        probe's 7 ns. The isolated measurement resolves what the
        composite cannot, and reading the composite's silence as
        absence is the instrument reporting what it cut.
        IMMORTAL `once` ANSWERS (2b4685d) MEASURED THE SAME WAY, and
        the accounting says something the design did not promise. On
        ONE tree (lane/http 1c47ce5), one compiler, one bench binary,
        only `build/avra_runtime.o` swapped:

            retains   410,001,348 -> 238,000,998   (205 -> 119 a head)
            releases  480,001,749 -> 308,001,380
            reclaims   70,000,401 -> 70,000,401    (unchanged)
            2066/2104/2069 ns a head -> 2028/2038/2020

        RECLAIMS UNCHANGED IS THE CONTROL: nothing died differently,
        only the counting stopped. And 172,000,350 retains removed
        against 86,000,194 once reads is EXACTLY 2.00 PER READ, where
        the design predicted one — `avra_once_get`'s own retain is
        86M of it, and the other 86M is every OTHER site that touched
        the value, because an immortal box no-ops a retain wherever it
        is taken. Two of those are named (`crlf` 12.0M, `tchar`
        10.0M); 64M sit at sites nobody listed.
        SO IMMORTALITY IS WORTH ~2x WHAT BORROWING WOULD HAVE BEEN,
        which is an argument for the door independent of the one that
        chose it. Borrowing removes the READ's retain and its paired
        release; immortality removes the value's retains EVERYWHERE.
        The borrow route was rejected for over-releasing (the once
        region's arms differ in ownership); it would also have been
        half the prize.
        A THIRD, 2026-09-07: TAKING THE FRAME OUT OF
        `avra_array_get_owned` — REFUTED, and it refines the
        cold-path law rather than denying it. That fn builds a
        48-byte frame on its FAST path: it inlines two already-clean
        leaves (`avra_array_get`, `avra_rc_retain`) and their cold
        tails, and clang hoists the union's register saves above
        everything, which is the law's own mechanism one level up —
        FIXING EACH LEAF DOES NOT FIX A CALLER THAT INLINES SEVERAL.
        Restructured so the guarded half is one `noinline cold` tail
        call: the prologue GOES (`adrp` first, no `sub sp`), and the
        self-check measured 5.90/5.91/5.94 against 5.87/5.93/5.87.
        Nothing.
        WHY IT PAID AT 26% AND NOT HERE, which is the transferable
        part: the win is the FRAME-TO-BODY RATIO, not the frame.
        `avra_rc_retain` is ~5 instructions called 557M times, so a
        4-instruction prologue more than doubled it. `get_owned` is
        ~20 instructions at 3.9% of self time, so the same prologue
        is worth ~0.8% — BELOW THIS MEASUREMENT'S NOISE FLOOR
        (+/-0.05s on 5.9s is ~1%). So this is honestly "too small to
        see with a stopwatch", not "zero": resolving it needs a
        microbenchmark or a census, and it is not worth either.
        The `stp`-counting shortcut is ALSO refuted as an instrument:
        `avra_array_get` reports one and is CLEAN — its `stp` sits
        below the `ret`, on the cold path. Count frame ops before the
        first branch, or read the disassembly.
        AND ONE SUSPECT ACQUITTED: the law names a
        `__builtin_return_address` read as a cause. It is not this
        one — removing it left the prologue byte-identical. The cold
        branch being a CALL is what clobbers x30 and forces the save.
        WHAT IS LEFT, re-profiled after the fix: `avra_rc_release`
        22% and its out-of-line reclaim 21% (real work — 105M boxes
        freed), `avra_rc_retain` 12%, `avra_array_sized` 10%,
        `avra_array_get` 9%. The remaining refcount cost is the
        header's belt (an alignment test, an image-base test, a tag
        load) which is a SAFETY LAW, not overhead to shave, and the
        call count itself — which is the `retained_args` question in
        point 1, still lane C's and still unscoped.
  - [x] TWO TOOLS AND A KEPT CONTRACT (2026-09-05, with the above).
        `make census` (tools/census.sh) rebuilds the runtime with
        -DAVRA_CENSUS for EXACT counts — a sampling profiler charges
        a release cascade to whoever was on the stack, which is how
        the grammar executor looked like 45% of a run and was not.
        `AVRA_CENSUS_SITES=1` adds two per-caller tables: writes
        charged to the runtime fn that makes them, and whole-value
        copies charged to the AVRA fn that asked, because a concat is
        one call and many writes. Counting costs 8% of a run, so it
        is a separate build and the shipping runtime carries none of
        it; the script restores the shipping runtime ON EVERY EXIT.
        `make traps` (tools/traps.sh) keeps the runtime's TRAP
        CONTRACT — the exact words and exit 2 — which no corpus
        program can hold, because the corpus runs every program in
        one process and a trap ends it. THE GAP IT CLOSES WAS
        MEASURED, not assumed: with the bounds message deliberately
        reworded, the whole gate stayed green (1880 tests, 77
        programs), because the only existing out-of-bounds test goes
        through the evaluator. Three contracts, 1.4s, in the gate.
  - [x] THE KEEPER'S FIRST NEW DOMAIN BROKE IT, which is this tree's
        own law arriving one domain over (2026-09-05). The SQLITE
        lane's manifest-driven source list put a VENDORED
        amalgamation inside `tools/externs.py`'s reach for the first
        time, and it immediately found 61 wrong declarations — 53
        TRUE, which nothing else in this tree could have caught,
        since both engines agree on a narrow C return's wrong answer.
        AND 8 FALSE, all from one cause: the keeper reads the
        SPELLING of a C return, and a third party names its widths
        through TYPEDEFS (`sqlite3_int64` -> `sqlite_int64` -> `long
        long int`) and prefixes them with a MACRO (`SQLITE_API`). It
        had spent its whole life reading C THIS TREE WROTE, which
        spells `int64_t` plainly, so its width set had never met
        either — it passed every day while structurally unable to see
        the case it was about to be asked to guard. Same shape as
        `RtKind`'s two `is .Variant` consumers, same shape as the
        runtime's `acc_kind_of`.
        A SECOND FALSE CLASS WAS FOUND BEFORE IT COULD BITE: the
        32-bit rules are ANCHORED, so `SQLITE_API int` would have
        failed a correctly declared `i32` seat too — the lane would
        have fixed all 53 and stayed red.
        THE FIX RESOLVES rather than lists. Typedefs come from the
        same sources the keeper already reads, because a list of
        known names would be right for SQLite and wrong for the next
        library — the very defect the keeper exists to catch. A name
        keeps EVERY definition it has across preprocessor branches
        (`__int64` on one compiler, `long long int` on another) and a
        seat is satisfied only when ALL readings agree; disagreement
        fails rather than guesses. All-caps words are dropped as
        macros, since no C base type shouts. `__int64` joined the
        wide set, which the fixture caught and no tree source would
        have.
        AND THE KEEPER NOW TESTS ITSELF: nine cases pinning these
        readings run before any verdict, and a failure says the
        model moved and its verdicts are not to be trusted. Verified
        to have teeth by breaking the wide set and watching them
        fail. An unexercised keeper is an untested instrument, and
        this one proved it by being wrong the first day its domain
        widened.
  - [ ] AN EARLY-CUTOFF HASH THAT COVERS A PROJECTION OF ITS VALUE
        IS A LIE, and the memo kernel has one. Found 2026-09-06 by
        the docs campaign's spine lane for doc comments; VERIFIED AND
        WIDENED here, because the general case is worse than the one
        they reported. `parsed` settles on `program_hash`
        (workspace.av:319), a fold of STRUCTURAL statement
        fingerprints, and core/nodes.av:5 says so outright:
        "reformatting never changes a fingerprint". But the VALUE is
        `Parsed = { store, stmts, source, voices }` — it carries the
        SourceFile's whole TEXT and, in the store's side tables,
        every SPAN, which are byte offsets (`Span { lo, hi }`).
        So `settle` (db.av:155-162) keeps `changed_at` on an
        unchanged hash while the value it summarises has changed.
        THE REPORTED CASE is a doc-comment edit: same structure, so
        dependents are marked green over changed prose. THE WIDER ONE
        is any edit that MOVES TEXT WITHOUT CHANGING STRUCTURE — a
        blank line, a reindent, an ordinary `//` — after which every
        later span is stale and the cutoff says nothing changed. A
        dependent that renders a diagnostic would point at the wrong
        place, and be certified fresh doing it.
        IT CANNOT FAIL TODAY, which is the whole shape of it: compiles
        are one-shot, `disarmed` kills the verifiers at revision one
        (workspace.av:64-67 says as much), and nothing edits. It is
        the untested-instrument law arriving in the memo kernel, and
        the first incremental consumer is its first real test.
        THE FIX IS NOT ONE HASH. Hashing the text restores soundness
        and destroys the property worth having — that reformatting
        does not re-run typing. The cutoff must be PER CONSUMER: a
        dependent that read only structure may cut off on the
        structural fingerprint, one that read spans or text may not.
        So `parsed` owes two fingerprints, not one, and a consumer's
        cutoff must name which it read. NOT SCHEDULED — incremental
        editing does not exist yet — but recorded so whoever builds
        it does not inherit a silent lie. The docs lane's
        `touch(source(ws, f))` fixes their family and not this.
  - [ ] A MINTED POINTER HANDED TO A RUNTIME ROW IS A DEREFERENCE,
        so `avra_ptr_at`'s stated ground is already false — found
        2026-09-06 by lane A while judging a foreign-text proposal,
        PROBED, not reasoned. The runtime comment says "the danger is
        DEREFERENCING, and Avra has no dereference at all". The
        language has none; THE ROWS DO. `avra_array_push` casts what
        it is handed straight to `AvraArray*` and writes through
        `a->data[a->len]` with no `hdr()` check — it cannot have one,
        since it is handed real arrays constantly — and the extern
        seam accepts ANY name at check time (a nonexistent symbol
        passes `check`; a real internal one links). So this compiles
        clean today, with no diagnostic and no unsafe marker:
            extern fn avra_ptr_at(address: int) -> ptr
            extern fn avra_array_push(arr: ptr, v: int)
            fn poke(a: int, v: int) { avra_array_push(avra_ptr_at(a), v) }
        That is an arbitrary WRITE, which is worse than the arbitrary
        read the foreign-text debate was fencing against, and it
        needs no new capability.
        WHAT IS AND IS NOT THE DEFECT. A systems language with an
        unrestricted FFI has this property by construction and P8
        wants escape hatches, so the CAPABILITY may well be right.
        THE FALSE PREMISE IS THE DEFECT: a comment asserting a safety
        property that does not hold is what lets the NEXT capability
        be granted on bad grounds, which is exactly what nearly
        happened — a foreign-text proposal was argued on "my option
        leaves that sentence true", and the sentence was already
        untrue. Restate the ground: creating a pointer is inert IN
        THE LANGUAGE, and the rows dereference what they are handed,
        so the FFI is the unsafe corner and should be named as one.
        AND THE SEAM PROPERTY GENERALISES, worth its own line: AN
        EXPORTED C SYMBOL IS A LANGUAGE CAPABILITY, because any file
        may declare an extern for any linked symbol with nothing
        central authorising it (`avra_trap` is declared privately in
        query/db.av). There is no "reachable from C but not from
        Avra" in this design, so every runtime export is a language
        decision whether or not anyone frames it as one.
  - [x] A POINTER FROM AN INTEGER — ANSWERED YES by the owner and
        LANDED 2026-09-05 as `avra_ptr_at` (lane C's block below).
        The answer did NOT land in lane A's file: it needed no
        constant expression and no compiler change at all, only a
        runtime row. What follows is the question as it stood.
        `ptr` WAS receive-only:
        no cast, no constructor, and `const P: ptr = 1` is F2024
        "`P` declares `ptr`, this is `int`" (probed). So the blocker
        is the TYPER, not lowering, and the question is not "may we
        fold a pointer constant" but MAY AN AVRA PROGRAM BUILD A
        POINTER FROM AN INTEGER AT ALL — a coherent no, with real
        safety value. What wants it: a named pointer sentinel, e.g.
        SQLite's `SQLITE_TRANSIENT` = `(void*)-1`, without which a
        driver ships no TEXT or BLOB bind.
        THE WRAPPER WAS OFFERED AND DECLINED as premature — a
        backend wall exists to serve lowering, and one serving none
        pre-announces a capability the owner may refuse. THE TRAP IT
        WOULD CARRY IS RECORDED INSTEAD, which is the part worth
        keeping: it is `LLVMConstIntToPtr`, a CONSTANT expression
        that folds to `null` at zero, NOT the `LLVMBuildIntToPtr`
        INSTRUCTION already at llvm_wrapper.c:371 (and inside
        `cast_to_type`). The names differ by one word and the wrong
        one emits an instruction where a constant belongs. On a yes,
        this is minutes.
        A RELAYED APPROVAL WAS TRIED AND REFUSED (2026-09-05). A peer
        carried word that the owner had said "do it"; lane A wrote the
        wrapper on it and reverted it unlanded when lane C declined
        the same relay, in better words than either of us had: taking
        it second-hand converts "the owner decides" into "the owner
        decides, or someone says they did", and the second is not a
        fence. THE YES MUST REACH THE LANE THAT BUILDS, FROM THE
        OWNER. Recorded here so the next relay meets a precedent
        rather than a memory — the fence is only worth what it
        refuses under pressure, and it was tested that same day.
  - [x] THE EXTERN WALL'S WIDTH (2026-09-05, the SQLITE lane's find,
        REPRODUCED here before acting): Avra's `int` is 64 bits and
        C's is 32. `declare_externs` declares every extern answering
        `int` as `i64`, but a C body answering a narrow type writes
        only the low half, and neither ABI promises the bits above
        it — both compilers materialise a 32-bit result with a
        32-bit write, which ZEROES the upper half. MEASURED under
        lane A's own hand, five C fns at -O2 linked through an
        object: a C `int` of -1 reads 4294967295, INT_MIN reads
        2147483648, a C `short` of -1 reads 4294967295, and
        `f() == 0 - 1` answers FALSE. A C `long` is right, and an
        unsigned MAX is right by luck. The emitted line is
        `declare i64 @avra_probe_i32_neg()`.
        BOTH ENGINES AGREE ON THE WRONG ANSWER, so `eval == native`
        cannot catch this class — that property is AGREEMENT, never
        correctness, and it is worth saying out loud because the tree
        leans on it hard.
        OUR HALF IS CLOSED: an audit of all 98 externs whose C body
        we own found exactly two narrow, both in
        backend/llvm_wrapper.c (`print_module_to_file`,
        `verify_module_print`), both right today only because their
        values are 0 and 1 and a 32-bit write of 0 zeroes the
        register. Both answer `int64_t` now, and `make externs`
        (tools/externs.py, in the gate) refuses the class: a C body
        we own, read as `int`, must answer a 64-bit type or a
        pointer. Proved by restoring a narrow return and watching the
        gate go red.
        WHAT IT CANNOT DO: it cannot read a THIRD party's headers, so
        a binding to someone else's library is unprotected. That is
        the sized integer types' job (spec Axis 15.2: `i32`, `u32`
        map to fixed-width C types; today `extern fn f() -> i32` is
        F2001 "`i32` names no type"). Specified, missing, and
        producing wrong answers — a LANGUAGE slice, not lane A's to
        schedule.
  - [x] THE REBASED LANE IS REBUILT BY WHICHEVER COMPILER READS IT
        (2026-09-05, lane C's find, relayed by lane D): the pre-flight
        fixed the MERGE side; the REBASE side had the mirror gap. The
        integrator ran `make bootstrap` in the lane worktree after a
        rebase, which assumes main's SEED can read the lane — false for
        a lane that ADDS a construct and USES it in the same slice,
        which is the normal shape of a language change. Lane C hit it
        landing `once fn` and finished by hand. `rebuilt_lane` now
        tries the lane's OWN product first (it knows the lane's
        constructs) and the seed second (it knows main's), so each
        single-sided case is automatic. Only a lane that adds syntax
        WHILE main added syntax defeats both, and that message names
        CLAUDE.md's two-slice procedure instead of a bare failure.
  - [x] THE STATE BOX DISSOLVED (2026-09-05): a `MatchState` was
        boxed per hit and per call — cursor and bindings — and a
        result carried one. The cursor and the bindings are the
        result's own fields and the walk's locals now; `state_at` is
        gone. MEASURED: the suite's parse 6.67s -> 5.72s, the suite
        17.1s -> 16.1s, the gate 20.6s -> 19.5s; the self-check level
        (8.39s -> 8.47s, its parse 5.9s -> 5.66s). What remains of the
        records per hit: a MatchResult per attempt and a bindings
        list copied per label — worth a look after lane C's S3 makes
        the retains cheaper, when the profile is re-read.
  - [x] CAPTURES ON DEMAND — tried, MEASURED NEUTRAL, reverted
        (2026-09-05): boxing a terminal's capture only where an item
        is labeled or its branch passes through, and no value list
        for built branches, changed nothing measurable (the
        self-check 9.47s against 9.4s, the suite 17.2s against 17.1s)
        and added a flag through three fns. The executor's cost is
        not its terminal captures; it is the state and result records
        per hit and the bindings copied per label — the records
        item, still open.
  - [x] `Decls.mint` CLONED ITS KEY MAP per declaration (2026-09-05):
        10% of a self-check's samples in `map_index_rebuild` under
        `Decls.mint` through `avra_slot_unique` — the read
        `self.keys.get(key)` two lines above the write held the map
        to the scope's end (lane C's I34). The read asks in its own
        scope (`known_id`), and the write finds the map unshared.
        Lane C's S3 (liveness) retires the whole class.
  - [x] LTO ACROSS THE RUNTIME — tried, NEUTRAL (2026-09-05): 35% of
        a self-check's samples are inside `avra_rc_retain` and
        `avra_rc_release` themselves, 7% in `avra_array_get` (a
        record's field read is a runtime call). The runtime compiled
        to bitcode and the compiler linked `-flto -O1`: 9.34s against
        9.36s. The cost is the bodies — the header's checks and its
        cache line — not the call. Fewer retains is the lever: lane
        C's S3 liveness, which this number prices at a third of every
        compile.
  - [x] THE CYCLE (FOUND and ENDED 2026-09-05): the cases binary
        held 922 MB at exit — 7.2M small lists, ~4300 per case: every
        case's language, grammar and workspace tables. The workspace
        stores closures that capture the workspace (13 query
        verifiers, 3 declaration hooks, and the Analysis of each file
        in its own table), and counting never frees a cycle; the
        compiler never noticed with one workspace per process. A
        one-shot workspace now ends its own cycles at
        `Language.analyze` (`disarmed`: the verifiers refuse, the
        hooks are no-ops, the analyses table is emptied and never
        refilled; an Analysis asked after is remade over the memoized
        parts). MEASURED: the cases binary 920 -> 60 MB peak, the
        suite's peak 1083 -> 327 MB; the case run 4.8s -> 5.6s, the
        price of freeing what it makes (7M lists per run). THE
        LANGUAGE ASK, in the sugar backlog: WEAK CAPTURES — a capture
        that holds no reference, read through the header (a
        generation beside the count tells a dead box from its reused
        memory), so a table's hooks can name their owner and the
        owner still dies.
  - [x] THE GATE'S SHAPE (LANDED 2026-09-05): the compiler holds its workspace (~2.4 GB)
        while it waits on clang and on the test or corpus binary, so
        a suite peaks at their SUM. The light phase — link and run —
        belongs to a fresh process: after `emit_ll` the command
        EXECS itself (`avra_exec_self(args)`, a runtime row over
        `_NSGetExecutablePath` + execv) with a continuation
        subcommand that links the staged module with the words the
        heavy phase computed and runs the binary; the image is
        replaced, the workspace gone. DONE WHEN the suite's peak is
        max(compiler, binary) ≈ 2.4 GB, measured with the trace.
        LANDED: `avra staged <plan>` (hidden; the plan is clang's
        words beside the module, the binary the word after `-o`),
        reached through `avra_exec_self`. MEASURED with the trace:
        the suite 3551 -> 2399 MB, the gate 2405 MB; while clang
        (61 MB) and the cases binary (821 MB) run, the compiler's
        image is 2.4 MB. The cap is back at 4000.
        THROWAWAY BINARIES LINK AT -O0 (2026-09-04): the suite module
        (13.9 MB) links in 1.1s instead of 6.6s and runs the cases in
        the same time, since the hot code is the runtime's, compiled
        on its own. `avra test` and `avra corpus` link so; `build`
        stays -O1 (a product).
  - [x] LENGTH-CARRYING STRINGS (2026-09-04): the profile's real
        find behind a phantom `Decls.mint` frame — `avra_str_char_code`
        bounded its index with `strnlen(s, i + 1)`, O(i) per byte, so
        every scanner walking a string with `code_at` was quadratic in
        the string. The header carries the length at no size cost (a
        32-bit count beside a 32-bit length in the same sixteen
        bytes); every producer sets it, the backend's constants
        carry it, `char_code`, `.length` (`avra_str_len`, the rt row
        `strlen` retired) and `substring` read it in O(1), and a zero
        measures — which is what carried the transition build, whose
        own constants had no length. MEASURED: the suite's parse
        11.6s -> 10.7s; the check 18.5s -> 17.6s. I27's ratchet
        retires; the ledger's `s.length` entry is struck. CLAUDE.md's
        "A STRING's `.length` is `strlen`" note is now false — lane
        D's file; it goes with their next sweep.
  - [x] ONE `avra()` PER PROCESS: every spec case assembles the
        language (dispatch boxes, rows_of), ~12s of the suite's
        case run. PROBED 2026-09-04, BLOCKED ON A CONSTRUCT: a
        module-level value cannot be shared — `export let` is
        refused ("`export` marks a fn, type, enum or trait — not
        this statement") and a fn body cannot read a top-level
        `let` ("a run-time binding of the top level — a fn body
        sees declarations, not the values around it", the const
        law). The language needs ONCE-PER-PROCESS PURE VALUES (the
        sugar backlog, below); lane C owns the files. DONE WHEN
        `avra()` is `once` and the case run drops by the measured
        share (7.6ms x 1578 cases).
        RE-MEASURED 2026-09-04: the profile of the cases binary put
        HALF the run inside `distinct` — `rule_first` re-walked a
        referenced rule's whole body at every reference and every
        union allocated a map, so the "cost of `avra()`" was mostly
        first sets re-derived forty times. `FirstCx.firsts` (each
        rule's set once) took the cases binary 24.9s -> 8.6s and the
        suite 46s -> 30s, one assembly 30ms -> 20ms. What `once`
        would still buy is the remaining per-case assembly —
        re-profile before building it.
        MEASURED AGAIN (2026-09-05, after the free lists): 300 cases
        that only assemble run in 0.65s — 2.2 ms per assembly — and
        the suite's 1674 cases run in 4.8s, 2.9 ms each: assembly is
        THREE QUARTERS of the case run, ~3.6s of the gate. The
        construct is worth building; the design that needs no IR
        variant: `once fn f() -> T` lowers to a body guarded by two
        runtime ROWS (`avra_once_get(id) -> ptr?`, `avra_once_set(id,
        v)`), the cache holding one immortal reference, each call
        answering it retained; scalars refused at first (a once
        value is one the runtime owns). Lane C's files.
        LANDED 2026-09-05 (lane C) — `once fn` is a construct: a
        zero-argument fn whose answer settles for the process, kept
        by the runtime under the fn's OWN SYMBOL (unique in a binary
        by the linker's law, and per Machine in the evaluator, so
        both engines agree). Two rows and no IR variant, exactly as
        designed: `avra_once_get(key) -> ptr` (owns_result, so every
        ask answers retained) and `avra_once_set(key, v)` (the cache
        takes its own reference to both, forever); the lowering is
        the niche guard the nullable protocol already uses —
        `ConstStr`, `CallRt`, `Bin(Ne, got, 0)`, `IfStart` /
        `ArmEnd(got)` / body / `CallRtVoid` / `RegionEnd`. The laws
        refuse what cannot settle: arguments, a scalar or void
        answer, a record of one scalar field (it travels as the
        field), and a method (its answer would depend on a
        receiver). MEASURED, the ledger's own bar: `avra test
        packages/std-avrac` 16.5s -> 12.1s with `avra()` alone, and
        -> 11.3s with `rt_sigs`/`rt_index` once as well (the memory
        pass, the backend and the evaluator all asked the 48-row
        table per instruction; `rt_sig_of` is a lookup now, not a
        rebuild). A 32% drop, 1744 cases unchanged. FOUND on the
        way, both now laws in CLAUDE.md: (1) A RUNTIME ROW BORROWS
        ITS ARGUMENTS — the first C bodies followed the Avra
        callee-cleans convention, released what they were handed and
        kept what they never retained, and the cases binary
        segfaulted on its second ask; (2) WHETHER A VALUE RIDES A
        POINTER IS ITS DECLARATION'S ANSWER — flatness is set when a
        record's signature is asked, so the answer law refused a
        flat record under the CLI and accepted it under
        `analyze_source` until it asked the declaration first. Red
        team: 15 probes (every value category, chaining, a nullable
        answer that settles nothing and stays honest, recursion,
        generics, a method, a flat record) and a differential over
        157 programs — check, run and IR identical to main's binary
        everywhere, the only diff two `declare` lines every module
        now carries. 13 new cases + corpus/once (eval == native);
        1758/1758.
  - [x] PROFILE THE CASE RUN (2026-09-04): its top frame was
        `distinct`, the O(n^2) dedup behind `Grammar.keywords()`,
        recomputed by every case's `avra()` over ~1000 literals —
        linear now (a seen-map; order kept). Beside it: `rt_sig_of`
        rebuilding the runtime table per evaluator call and
        `FirstCx.alt_first` computing FIRST sets per `ready()` — both
        the once-per-process family, recorded under the ask. Lowering's
        window is clang: the parent sits in `link` waiting.
  - [x] THE RUNTIME TABLE, INDEXED WHERE IT IS ASKED PER CALL
        (2026-09-04): `rt_index()` in core — the rows by name, built
        once by a consumer — held by the backend's `Emit` (once per
        module) and the evaluator's `Machine` (once per run), where
        `callee_sig` and `rt_dispatch` rebuilt the 48-row table on
        every call. The std-avrac suite 48.2s -> 44.4s user. The memory
        pass's `rt_owns`/`rt_owned_twin` per instruction lowered still
        rebuild it — memory.av is lane C's; the once-value covers it.
        Pinned: every row indexed under its name and nothing else; an
        extern declared with a runtime row's name is the runtime's row
        on both engines (`shown` answers the whole OUTPUT, `x\n2`, not
        the value — a pin taught me that).
  - [x] LOWERING'S OWN WHOLE-TABLE SCAN (2026-09-04): every body's
        emitter gathered the program's extern symbols by walking EVERY
        declaration (`extern_names`, asked from `new_lower` per body
        and per lift) — I32 in the lowering. Gathered once per run
        (`Workspace.externs`, complete because every file is admitted
        before the first unit lowers) and once per lone lowering, and
        handed to each unit through `Jobs`; `union`'s per-file
        `concat` of wanted units is one `flatten`. MEASURED: the
        suite's lower 6.1s -> 3.7s. What remains in lowering is the
        memory pass asking `rt_sig_of` per instruction (15% of the
        phase; memory.av is lane C's, and the once-value covers it).
  - [x] THE MISS PATH (2026-09-04): a terminal miss — the engine's
        commonest outcome — cost eight allocations for a literal (an
        interpolation to backtick the expected word, a one-element
        list, the farthest-failure record, the result record, an
        `Absent`, an empty diagnostics list) and five for a token
        class. The expected-word lists are spelled once per grammar in
        `ready` (`lit_expects`/`kind_expects`), and one `Absent` and
        one empty diagnostics list per run ride the context, shared —
        immutable values share freely; a consumer that changed one
        would copy. Two allocations per miss now. MEASURED: the
        suite's parse 11.2s -> 10.2s; with the externs slice, the
        check 17.6s -> 15.6s.
  - [x] THE CORPUS AS ONE PROCESS (measured and LANDED 2026-09-04):
        `make corpus` is 67s of wall for 10.8s of CPU. A freshly
        linked binary's FIRST execution costs ~150ms of kernel
        signature assessment (3ms on the second run; a copy of the
        same bytes pays it again), and each of the 74 programs is
        built by its own compiler process and its own clang spawn.
        THE FIX IS `avra test`'s shape: every corpus program compiled
        into ONE binary whose entry runs each program's entry in turn
        and diffs against its `.expected` — one compiler process, one
        clang, one assessment. Era IV's "one process" for the corpus;
        the gate would lose ~45s of its ~125s. A runner slice, its own
        red team; not a constant to shave.
        LANDED as `avra corpus <dir>`: `make corpus` 67s -> 3.7s wall
        (1.8s CPU), the gate ~118s -> 87s. A directory of programs is
        a workspace where EVERY FILE IS ITS OWN MODULE
        (`programs_workspace`, `Workspace.per_file`) holding only its
        own files; capture sits at the DESCRIPTOR (fd 1 behind a temp
        file) because the externs corpus spawns a child whose output
        an in-memory hook never saw; a `Ret` constant wears the fn's
        declared answer type. THE RED TEAM'S FIND, on main since the
        start: a program showed the running last register ANY
        statement answered — a trailing `let` printed its value, a
        trailing assignment the `mut`'s initial value, a trailing
        `for` after an expression TRAPPED the evaluator, and
        corpus/mut.av had pinned the wrong answer. The answer is the
        final RUNNING statement's expression when it is one
        (`shown_value`, `program_answer`); corpus/unshown proves it
        with an empty expectation, and silence is an answer.
  - [x] THE QUERY KERNEL'S NESTED WRITES (2026-09-04): `Db.cells` was
        a list of rows, so every `write` copied its family's whole
        row (thousands of cells, each retained and released — the rc
        traffic the parse profile showed), and every `record_dep`
        copied the open frame's dep list. Both are flat now: cells
        ARG-MAJOR (`arg * families + family`) so a write is one element
        set through the field and growth is an append, and one flat
        `deps` list with a stack of frame `marks`. A key with an
        unregistered family still traps (the old layout's bounds
        check, kept by reading the verifier). MEASURED: sigs 268ms ->
        173ms, bodies 1170ms -> 734ms, the check 15.6s -> 14.9s, the
        suite's peak RSS ~300 MB lower. db_test pins the layout: a far
        arg grows the table and the earlier cells stand; two families
        at one arg keep apart; an unseen key is as new as now.
        TRIGGER, for the borrow's deletion (lane C, after the inout
        seats): every in-place write lane A landed is borrow-shaped —
        `mut cs = self.cells; cs.set(…)` in the kernel, `mut results
        = cx.memo.results` in the executor, `Table.keep` under the
        workspace memos — and each becomes a `mut` seat or a `mut fn`
        writing `self.field.set(…)` in ONE sweep when the borrow goes,
        never by breakage. Lane C's S4a rewrote the owned-state
        parameters; these receivers are the remainder.

LANE B — STD LIBS (owns NEW packages only; each package: `avra.toml`,
spec tests beside it, a corpus package under corpus/<name>/ proving
eval == native; each a slice with red-team + review-round). The
driver is what the compiler and its tools need — the spec has no
std-lib chapter, so dogfooding decides the surface.
  - [ ] `@std/process` — DESIGNED 2026-09-04, FIRST (the user's
        word: the first real std lib dogfoods everything). The vision
        is `docs/2026_09_04_STD_PROCESS_VISION.md` on lane/b, with
        four research reports beside it (`…_RESEARCH_*.md`); it merges
        with the first slice. THE SPLIT: a command is a PROGRAM (an
        authority — `Program`, minted from `[process.tools]`, resolved
        ONCE to an absolute path), its WORDS (data — a literal hole is
        one argv word) and their POSITIONS (a word from data is fused
        `--flag=v`, `./`-prefixed as a path, or after the tool's
        declared terminator — argv-lists delete the shell, NOT
        argument injection). An exit is `Exit { Clean, Code(n),
        Signal(sig, core) }`; `run()` judges by `ok_exits` (default
        `[0]`; grep spells `[0, 1]` once), `outcome()` reads. Env is a
        named profile (`minimal`/`developer`; `inherit` counted; the
        failing child's missing variable is NAMED, F4616). Two
        deadlines (`timeout`, `drain_grace` — a grandchild holding the
        pipe). `start(ready)` returns when READY. `Runner` is a trait:
        `host`/`scripted`/`plan`. GRANTED (2026-09-04): (1) lane B
        writes the TWELVE substrate rows in `runtime/avra_runtime.c`
        over a handle table with a tagged status word (`0` RUNNING,
        success never zero, spawn failure `-errno`) — `posix_spawn`
        never `posix_spawnp`, PATH resolved from the CHILD's envp,
        SETSIGDEF+SETSIGMASK, CLOEXEC_DEFAULT/close_range, one poll
        set, drain then reap once; lane 0's `avra_spawn_status`
        (posix_spawnp, `environ`) is the v0 bridge these REPLACE, and
        `system()` dies with it; (2) each row gets an `rt_sigs()` row
        and a thin `RtHost.Proc*` arm calling the same C, so `avra
        run` spawns and eval == native holds by construction; (3)
        `manifest.av` learns `[process]` (unknown keys ERROR;
        `process.<name>` a decl) — the same door `@std.fs` needs.
        OPEN, per lane: (4) the `cmd""`/`sh""` literals ride the
        embedded-sublanguage contract — ONE grammar (the shell's word
        and pipe spelling), lane B writes it in the package, the
        grammar-lit owner wires the literal hook; (5) `defer` — WANTED
        by process (a `Child`'s scope is its lifetime, F4609); LANDED
        by lane B on the user's word (slice D, below); (9) typed `[link]`
        rows (`objects`/`search`/`libs`, no `-`-leading token a
        dependency can spell; `[link.raw]` root-only, allow-listed) —
        the build machine's steps two and three after lane 0's argv
        row; (10) `caps.seal()` shared with fs — exec targets are
        `FS_EXECUTE` rights and Landlock layers are conjunctive. v0
        SCOPE (lane B alone, this week): the package over the twelve
        rows with the constructor forms (`program(name)?`,
        `cmd(p, words)`, the position verbs, `with`), `Pipeline` over
        kernel pipes with per-stage stderr, `Child`, the `serving`
        bracket, `parallel(limit)`, `race(stagger)`, `exit(Exit)`,
        `@std/time`'s `Duration` stub; `shared.av:198` and `test.av:44`
        move onto it. DONE WHEN the cli links through `@std/process`,
        `corpus/process/` says eval == native, and `avra explain
        process` prints the tool set.
        SLICE A LANDED 2026-09-04 — THE SUBSTRATE AND THE CORE.
        `runtime/avra_runtime.c` grew the process section: twelve
        functions over a handle table (`avra_proc_spawn/run/poll/
        write/stdin_close/take/signal/status/pid/close/which/
        error_text`), one poll set, one reap, the tagged status word,
        `posix_spawn` by absolute path with SETSIGDEF+SETSIGMASK,
        CLOEXEC_DEFAULT on Darwin, the child's group id kept past the
        reap so a truncated run stops its tree; the runtime ignores
        SIGPIPE at `avra_args_init`. Fourteen `rt_sigs()` rows with
        `RtHost.Proc*`/`NowNs`/`HostEnv` arms in interp.av — the
        evaluator calls the same C, so eval == native by
        construction (`corpus/process/` proves it; corpus/native/
        process_seam.av pins the seam's refusals). `@std/time`
        (`Duration`, `ms/secs/mins`, `now_ms`, `duration_text`) and
        `@std/process` v0: `Tool` (RENAMED from the vision's
        `Program` — the compiler's own `Program` type sits at every
        dogfood site; the manifest says `[process.tools]` anyway),
        `tool(name)?` (PATH resolved once, relative entries never
        searched), `Command` with defaults and `with`, the position
        verbs (`flag` fuses `--x=v` and attaches `-ov`; `path`
        anchors `./`; `after_options` uses the tool's declared
        terminator — a `table<Terminator>`, git's `--end-of-options`,
        find/dd none; `word` refuses a leading dash), `Exit { Clean,
        Code, Signal(sig, core) }`, `run()` judged by `ok_exits`,
        `outcome()` read, `Env { Only, Inherit }` with `minimal()`/
        `developer()`/`passing`/`with_var`, `Stdin`, `Output.
        truncated`, `Outcome.took_ms`, `ProcessError` + `impl Error`,
        `exit(Exit)`. 45 spec cases. THE RED TEAM (3 attack packages,
        both engines, ~40 programs; the RC guard): FIVE WRONG ANSWERS
        — a negative timeout DISABLED the deadline (now a deadline
        already passed); a bad `cwd` was blamed on the tool (now
        `NoCwd`, the runtime stats it first); an env name holding `=`
        split silently (now `BadEnvName`, checked before the spawn);
        `-o` fused as `-o=x` (a one-letter option attaches); `path("")`
        became `./` (stays empty). ONE LEAK — a grandchild holding the
        pipe survived a truncated run (the group is killed by its id,
        which outlives the reap). TWO REFUSALS — `Failed` quoted a
        capture's worth of stderr (first line); the compiler's F2023
        help for `x()?.field` says "write `.field`", wrong advice for
        propagate-then-read (`(x()?).field`) — LANE C's voice.
        NO DIVERGENCE anywhere. Survived: handle misuse (EBADF/EINVAL/
        ESRCH), double close, stale handles after slot reuse, 1 MiB
        intact, NUL kept, EPIPE on a deaf child, zero timeout, cap 0
        lifts, `ok_exits: []` accepts nothing, exit 255 / 256, 3000
        words, hostile words literal, crossings with fields, lists,
        closures, recursion and holes. v0 POLICY, honestly: the
        child's PATH is the invoker's with relative entries stripped
        (minting waits on the manifest mint); `max_capture: 0` lifts
        the cap, spelled. SUGAR ASKS from the slice (wanting sites in
        process.av and its tests): bitwise ops (`has_bit` divides);
        `const` in a module file (fifteen flag fns); `is` with a
        payload pattern; a method after `?` on a Result; a `Duration`
        literal (`5s`). NEXT: slice B — `Pipeline`, `Child`
        (`start(ready)`, `write`, `stop`, `wait`), the `serving`
        bracket, `parallel(limit)`, `race(stagger)`, the `Runner`
        trait with `host`/`scripted`/`plan`; the seam pin moves into
        the `Child` tests.
        SLICE B LANDED 2026-09-04 — THE REST OF v0. The seam grew two
        arguments, not two functions: `avra_proc_spawn` takes the
        capture cap and an UPSTREAM handle whose stdout becomes the
        child's stdin through the kernel's own pipe (the read end
        handed over with its non-blocking flag CLEARED — the red team's
        first find: `sort` read EAGAIN and quit, and `printf` died of
        SIGPIPE). `Stdin.Open`; `Ready { Started, Exit, Line, Exec }`;
        `Child` riding a shared `Stage` (one pump `ticked`, one
        `collected`, one `launched`, one `abandoned`, one `broken` — the
        three drivers `Pipeline.outcome`, `parallel`, `race` and the
        child all ride them), `start(ready, within)` that RETURNS WHEN
        READY or stops the child and refuses `NotReady` with its words;
        `write`/`close_stdin`/`read_line(within)`/`wait`/`stop`/
        `is_alive`; a child REMEMBERS its ending (the red team: `stop`
        twice said KILL for a child that met TERM; `wait` after `stop`
        said timeout and would spin forever unbounded; `read_line`
        after `wait` handed out delivered output again). `serving`
        bracket. `Pipeline` with per-stage stderr, `StageFailed`, the
        SIGPIPE law (a producer killed under a clean consumer
        SUCCEEDED — `yes | head`, as the shell never managed to say),
        `Empty` for nothing to run (the red team: an empty pipeline
        TRAPPED on `.last()!`), a later stage's stdin IS the pipe.
        `parallel(cs, limit)` (a limit below one is one; a sibling
        past its bound stops every sibling), `race(cs, stagger)` (the
        first to FINISH; losers stopped; an unstartable racer fails
        the race, spelled). `Runner` trait + `run_through`, `host()`,
        `scripted(table<Script>)` with `Unscripted`, `plan()` over the
        hosted `avra_puts`. 82 spec cases (child_test, pipeline_test,
        the adversarial set grown by 13); corpus/process pins a
        pipeline, a child fed through an open stdin, a scripted run,
        `parallel` and `race` — eval == native throughout; the RC
        guard silent over the attack set. SUBSET FINDS: `fail` in a
        catch arm's block is F2029 (not divergence) — a statement
        match instead; `[null for …]` under `List<T?>` is F2006 — a
        `T?` fn fills the slot. NEXT: slice C — the cli dogfoods
        (`shared.av` links through `cmd(clang, …)`, `test.av` judges
        through `exit(Exit)`), `avra_spawn_status` and `system()` die,
        `manifest.av` learns `[process]`, `avra explain process`.
        SLICE C LANDED 2026-09-05 — THE COMPILER DOGFOODS. `shared.av`
        links through `cmd(clang, words)` — `clang` minted by
        `tool_from_env("CC", "clang")`, the same row the cli's own
        manifest now declares under `[process.tools]` (the mint reads
        it the day the manifest mints) — and `test.av` judges the
        suite's binary through `Exit` (`Clean`, code 1, else STOPPED
        naming the code or the signal; a binary that cannot run names
        the host's reason). Both run `at_the_terminal`: the developer's
        environment, their terminal for the words, their Ctrl-C — the
        two hatches the compiler's own tools spell. `avra_spawn_status`
        DELETED from the runtime (the cli's extern too); corpus/native/
        externs.av pins the seam's verdicts instead (`1:3`, `-2`,
        `2:9`, the injection word intact, the flush before the child).
        `Streams { Captured, Inherited }` on `Command`; `tool_from_env`.
        `manifest.av` learns `[process]`, `[process.tools]` (inline
        rows and `[process.tools.<name>]` tables), `[process.env]`:
        `ToolRow { name, from: Provenance { Path, Env, Abs }, var,
        default, at_path, terminator }`, `terminator = false` for a
        tool with none, and an unknown key under `[process]` REFUSES
        (`manifest.unknown_process_key`) — a bound on what may run is
        never a degraded load; `env` without `var` and `abs` without
        `at` refuse. `avra explain process [at]` prints the declared
        tools minted as the library mints them, their provenance and
        where their options end (the front door stands at the root, so
        the package is an argument). THE MACHINE CRASHED (2026-09-05,
        three lanes): lane B's bare `./avra test <pkg>` runs beside
        watched gates, and a direct `build/avra` sample elsewhere —
        the lock covered only what was wrapped. FIXED at the front
        door by lane A the same night (`./avra` takes the lock for any
        package-scale run; `AVRA_WATCH_HELD` keeps a gate's own runs
        off its lock); CLAUDE.md names both bypasses. REBASED onto
        main twice the same night (lane A's lock and list buffers,
        lane C's S4b-3a..3c "the context IS the pass"): the new `avra
        corpus` command moved onto `run_linked` beside `avra test`
        (one helper: the linked binary at the terminal). THE SEED'S
        SHIM: the seed that predates this lane links
        `avra_spawn_status`, so the C function stays in the runtime
        until a refreshed seed has landed — nothing in Avra declares
        it. TRIGGER: delete it in the first slice after this lane's
        seed refresh. Gate green at 3.6 GB peak on the merged base.
        SLICE D LANDED 2026-09-05 — `defer` AND `errdefer`, the
        `Child`'s scope law. A new feature dir (`features/defers/`):
        `defer e` / `errdefer e` are keyword statements; the builder
        wraps `e` as a lambda of no seats (`Stmt.Defer(lambda,
        on_error)`), so captures, the lift and the call convention
        are the closure feature's — captures are COPIES at the
        statement (`defer show(i)` before `i = i + 1` shows the old
        `i`, as Go evaluates deferred arguments). THE FRAME LAW:
        every STATEMENT LIST runs in a frame — a scope's (block,
        loop turn, fn body: `LowerCx.scope_enter/scope_exit`) or a
        statement-list arm's (an `if` statement's branch, a `let …
        else`'s else: `arm_stmts`) — the list's defers run as the
        frame closes, last first, AFTER the value or step that
        follows its statements; `return`, `fail`, `?` and a
        selective `catch`'s default run every open frame innermost
        first (`leaving()` for answers, `failing()` for the failure
        channel, which alone runs errdefers). The deferred call is
        the box's slot 0 through `CallPtr`, emitted before the
        bracket, so the memory pass retains it for the callee and
        the frame releases the box — no new IR. THE RED TEAM'S TWO
        FINDINGS, both laws now: an `errdefer` slept through a
        failure that left by `return .Err(e)` or the tail (a Result
        variable included) — only `fail`/`?` ran it; now `return`
        and the tail run it BEHIND THE ANSWER'S TAG at run time
        (`run_if_failed`: an `IfStart` on okness around the call; a
        bare success, lifted past the frame, never has a tag to ask,
        so the seats' bracket is frameless — `seats_enter/exit` —
        and the body block's close at depth 1 IS the tail). And a
        bare value deferred (`defer child` for `defer child.stop()`)
        did nothing silently — F2054 refuses a body that only names
        a value (literal, name, `self`, lambda; the store's `inert`
        projection). Laws: F2052 a deferred body answering a
        `Result` (a failure nobody would hear; `catch` it or `defer
        { let _ = … }`), F2053 an `errdefer` with no channel — the
        top level, a fn that cannot fail, or behind a lambda's
        barrier — F2054 the inert body. 27 spec cases + 49
        adversarial (eight classes; 50 accepted probes eval ==
        native; the guard clean under managed captures and dropped
        managed answers), `corpus/defers` (eval == native), the IR
        shape pinned. NOTE FOR THE MEMORY EPIC: O4's "errdefer
        (ownership milestone)" is this — it needed no ownership
        work, since FnExit already settles every open scope at the
        site. A CONSEQUENCE FOR FOREIGN STATE, found 2026-09-05 with
        the sqlite lane and worth knowing before the next FFI
        package: because an early exit runs every open frame's
        deferred calls BEFORE the exit, a `?` sitting between a
        foreign call and a read of the global state that call set
        will run cleanup in between — and the offending call is not
        on the line, it is a `defer` registered far above, firing on
        a control path the reader is not looking at. SQLite is the
        specimen: `sqlite3_errcode` must be asked IMMEDIATELY after a
        suspect NULL, before any other call on that connection, to
        tell an out-of-memory from an SQL NULL from a zero-length
        blob — the C API folds all three into one NULL pointer. So
        the suspect read and its check must share a frame with
        nothing between them that can leave. Our own libraries are
        immune by construction, and that is the pattern to copy:
        every io and process row answers `-errno` as its STATUS
        rather than leaving a global for the caller to read later, so
        no window exists to clobber. FOUND ON THE WAY (sugar
        backlog): a deferred `xs.push(v)` is refused as "`xs` is not
        `mut`" — the CAPTURE is the copy, and the voice blames the
        binding.
        MERGED lane A's hand-off onto `@std/process` on the way:
        `avra staged` links through `clang_ran`/`run_binary`
        (`Tool`, `Exit`); `Verdict` reads an `Exit`, and a binary
        the host will not start is the host's refusal, never a 127.
        Gate green on main tip 5d2760f at 1.3 GB peak. FOR THE MERGER,
        TWICE OVER: the standing binary compiles the source, so a
        product built right after a memory-pass fix merges carries
        the fix as source while its own body was compiled by the
        pre-fix pass — lane B's product compiled the suite at 7 GB
        until rebuilt by a binary that had the fix; `make avra` twice
        after such a merge, and check the peak before the gate.
        NEXT: `@std/io`.
  - [x] `@std/io`: println/eprintln, read/write file, env, list
        dir — over the runtime's existing externs, so a program
        prints without declaring C. DONE WHEN `packages/cli` and
        the corpus import it and declare no `extern fn println`.
        LANDED 2026-09-05 (lane B, slice E). NOT over the existing
        externs after all: those could not tell a missing file from
        an empty one, nor an unset variable from an empty value, so
        the runtime grew nine io rows over ONE convention — a verb
        answers a STATUS (0 done, -errno refused) and hands text
        through a single stash `avra_io_taken` empties
        (`avra_io_kind/read/write/list/mkdir/remove/env`,
        `avra_eputs`); `avra_proc_error_text` became
        `avra_errno_text`, shared by process and io. The selfhost
        externs stand on the same bodies (`read_whole`,
        `write_whole`, `mkdir_all`) until nothing declares them.
        Each row has an `RtHost` arm, so `avra run` hosts the
        library. The surface: `println`/`eprintln`; `read_text`,
        `write_text` (whole, through a sibling temp file and a
        rename), `list_dir` (byte order, `.`/`..` out), `make_dirs`,
        `remove`; `kind_of` -> `Entry { Missing, File, Dir, Other }`
        with `exists`/`is_file`/`is_dir`; `env` -> `string?`,
        `env_or`. Every refusal is an `IoError` naming its path
        (`NotFound`, `Denied`, `IsDirectory`, `NotDirectory`,
        `Failed(path, errno)`) with `impl Error`. A writing verb
        answers the path it wrote — `Result<void, E>` is F2019
        (sugar backlog). The cli's extern wall is three lines
        (`avra_exec_self`, `avra_process_exit`, `avra_now_ns`); the
        `Host` seam reads through `catch ""`/`catch []`, which is
        its contract. 26 spec cases on a TMPDIR scratch (a fixture
        empties a stale directory — the host's filesystem folds
        case, so `B` and `b` are one file) + 16 adversarial, `corpus/io`
        eval == native. THE RED TEAM'S THREE FINDINGS, all fixed
        test-first: a filename holding a newline listed as two names
        (the stash joined on `\n`; it joins on `/`, the one byte no
        name can hold); `make_dirs("")` spoke of a name too long (now
        ENOENT); and `env("PATH=")` answered PATH's value — the C
        library reads a name up to its `=` — so a name holding `=` is
        null. Also: the temp file a write goes through carries the
        pid, so two writers never share it. Every accepted probe eval
        == native; the guard clean over 300 writes and reads; a wrong
        type in any of the six slots is one refusal. `corpus/native/
        externs.av` keeps `extern fn println` as the seam's proof, by
        design. THE REVIEW ROUND'S FIND: an UNREADABLE source file
        parsed as an empty program — `avra check` answered 0 and
        `avra run` printed a blank line — because the `Host` seam's
        `read` is `fn(string) -> string` and the refusal had nowhere
        to go; the cli's `read_or_die` now speaks the io message and
        exits 2 for every file the workspace reads. LEAVE-ALONE: the
        seam's type itself (workspace.av) — a `Host` over Results is
        the trigger, with `@std/fs`. This closes lane
        D's "extern fn println replaced" item below. FOUND ON THE WAY
        (manifests — lane C / 15b's owner): a path dependency written
        ABSOLUTE (`path = "/Users/…/packages/std-io"`) is joined under
        the package's directory and refused F4007 as "holds no
        avra.toml" at a path that never existed — an absolute path
        should be taken as written, or refused as absolute in its
        own words; a scratch package outside the tree cannot reach
        the std packages today.
  - [x] `@std/cli`, OURS: subcommands, flags, the `Runnable` seam
        — what `packages/cli` uses of the vendored one (12 sites).
        DONE WHEN `packages/std-cli/` is DELETED and the cli builds.
        LANDED 2026-09-05 (lane B, slice F). The vendored package is
        deleted; `packages/std-cli` is ours, 400 lines over `@std/io`
        and `@std/errors`, written fresh. A command line is DATA the
        program declares: `App { name, description, version, commands
        }`, `Subcommand { meta: CommandSpec, body: dyn Runnable }`,
        `CommandSpec { name, description, hidden, flags, args, options
        }` with `FlagDef`/`OptionDef`/`ArgDef` — the shapes the cli
        already built, kept. What the line said is a `CliResult` with
        VERBS (`has_flag`, `option`, `arg`, `args_of`) by plain name
        (a flag is declared as typed, `--time`, and asked for bare,
        `time`); the cli's five accessor sites moved onto them.
        `parse(app, words)` answers `Result<CliResult, CliError>` —
        `UnknownCommand`, `UnknownFlag`, `MissingValue`, `MissingArg`,
        `ExtraArg`, each naming the command and the word, with `impl
        Error`. The law: a declared flag by name, short or whole-token
        alias; an option's value in the next word or after `=`;
        `--` ends options; positionals bind by declaration order, a
        variadic takes the rest; a word past the last declaration
        refuses. Help renders from the declarations alone
        (`app_help`, `command_help`: usage line, words, then flags,
        options and args aligned; hidden commands stay out of the
        list). `App.run` answers 2 for a line it cannot read — the
        refusal and the way to the help on stderr — 0 for help and
        version, else the command's verdict. 24 spec cases + 17
        adversarial (an app with no commands, a command declaring
        nothing, a required variadic with nothing, duplicate command
        names, flags declared without dashes, an alias with `=`, a
        value beginning with `-`, `--level=`, `--=x`, `---x`, a
        second `--`, repeated flags and options, a flag and an
        option sharing a name), `corpus/cli` eval == native, 300
        parses clean under the guard. THE RED TEAM'S ONE FINDING: an
        empty line refused as "unknown command: " naming nothing —
        it says "no command given". The four std packages now sit
        under the idiom ratchet (tools/idioms.py's roots), which
        found nine unused test imports (I24), a `Script` row forced
        open three times (I26), a captured-`Output` literal spelled
        four times (I12 — `gathered(stage)` names it) and two
        first-over-turns folds (I4, licensed at the site); debt 0. FOUND ON THE WAY: `bare` is a
        reserved word and `spec` a keyword — both bit as parameter
        names, F3002 spoke; a match arm's body cannot be a bare
        `fail` (CLAUDE.md's subset list has it).
  - [x] `@std/text`: a string builder (per-char concat is
        O(len^2) in the scanners), pad/align/repeat, the code-point
        walk. DONE WHEN the lexer and the renderer use it.
        LANDED 2026-09-05 (lane B, slice G). `Text` keeps pieces
        apart and joins once (`builder()`, `push`, `built`) — a
        scanner pushes RUNS, `src.substring(run, j)` at each escape,
        so the lexer's string literal, the toml scanner and
        `quoted_text` went from n²/2 to n. `repeat`, `pad_left`,
        `pad_right` measure in CODE POINTS, so an `é` takes one
        column; `lines` (a closing newline opens no empty row),
        `indent`, `is_blank`. The walk — `codepoints`, `chars`,
        `codepoint_count` — decodes UTF-8 by lead byte in plain
        arithmetic (no bitwise operators in the language), a stray
        or cut-short byte standing for itself. The compiler
        (`@std/avrac`), `@std/toml` and `@std/cli` depend on it: the
        lexer, the diagnostics renderer (`repeated` gone), the
        escaper, the toml string scan and the cli's padding read
        through it. Idiom I36 ratchets the smell (`x = x + "…"`,
        `x = x + y.substring(…)`); four sites converted, two
        fixtures licensed. 20 spec cases + 15 adversarial, `corpus/text` eval ==
        native. The constructor is `builder()`, not `text()` — every
        scanner already calls its subject `text`.
  - [x] `@std/path`: promote `core/paths.av` (join, normalize,
        dir_of, extension) out of the compiler.
        LANDED 2026-09-05 (lane B, slice H). `core/paths.av` is gone;
        `packages/std-path` holds it, generalized: `dir_of`,
        `file_name`, `stem_of` (the LAST extension dropped — `a.tar.gz`
        is `a.tar`; a leading dot is a name, `.gitignore` keeps it; a
        dot in the directory never counts), `extension_of` (no dot;
        "" for none), `with_extension`, `joined_path`, `under_dir`,
        `normalized`, `relative_path`, `segments`, `first_slash`,
        `is_absolute`. Nothing touches the host — `@std/io` reads and
        lists, these cut strings. The compiler's four importers
        (decls, workspace, modules, lower) and the cli's four read
        `@std.path`. 15 spec cases + 14 adversarial, `corpus/path` eval == native. THE RED TEAM'S FINDING, inherited from the compiler's copy: `normalized("/")` answered "" — the root folded to nothing; it answers `/`.
  - [x] `@std/json`: read and write, over maps and lists — the
        projection format `avra explain`/`lsp`/`doc` will speak.
        LANDED 2026-09-05 (lane B, slice I). `Json { Null, Bool, Int,
        Str, Arr(items), Obj(fields) }` — an object is a LIST of
        `Field { key, value }`, never a map: maps have no ordered walk
        (no `keys()`), and what is written must read back the same.
        `parse(text) -> Result<Json, JsonError>` is a recursive
        descent over bytes — strings copy runs into a `@std/text`
        builder, every escape decodes (`\uXXXX`, surrogate pairs as
        one code point, a lone surrogate as U+FFFD), numbers are
        INTEGERS (the language has no float: a fraction or exponent
        is `Fraction(at)`, refused by name, never rounded). `to_text`
        writes compact, `pretty` two-space indents with empty
        containers kept `[]`/`{}`. Accessors: `get`/`at` answer `Json?`
        (absence exact), `member`/`item` answer `Null` for absence so
        a walk CHAINS — `doc.member("tags").item(1).int()`, and answer
        Null rather than making every step optional. Every `JsonError` names its
        byte: `Unexpected(at, found)` with what was wanted,
        `Unterminated`, `BadEscape`, `Fraction`, `Trailing`. The one
        new runtime row: `avra_str_from_codepoint` — `@std/text`'s
        `from_codepoint`/`from_codepoints`, the walk's inverse, which
        the `\u` escapes needed. 24 spec cases + 27 adversarial (deep
        nesting, every odd token, escapes at their edges, duplicate
        keys kept in order), `corpus/json` eval == native. FOUND ON
        THE WAY: a string literal has no `\u` escape — the lexer
        keeps an unknown escape's two characters (subset list; sugar
        backlog).
  - [ ] `@std/time`: now_ns, a duration's text — what `--time` and
        the bench print by hand today.

LANE C — ROADMAP INTO RENT (owns language/ and features/ typing and
lowering). The first item unblocks the two biggest ledger entries;
the order is the dependency.
  - [ ] `mut self` — RATIFY the design (rung 14's mutating methods:
        a method that writes through self is inferred `mut self`,
        the call site needs a mut place, the receiver is opened
        unique before the call — the V1 law "aliasing never
        observable" kept). Then land it: typing + lowering + the
        corpus pair. DONE WHEN `let d = c; d.set(5)` leaves `c`
        unchanged, natively and in eval.
        DESIGNED AND RATIFIED IN DIRECTION 2026-09-04 — "`mut self`
        — THE INOUT RECEIVER" (this file, near the end): `self` is
        a KEYWORD, implicit, never in a parameter list; the receiver
        of a writing method is the caller's CELL; a `mut` parameter
        is the same seat; the fact is a whole-program fixpoint; one
        runtime row asked (`avra_slot_addr`); liveness lands in the
        memory pass. Slices S0-S4 there. #1377 probed: not ours.
        S0 LANDED 2026-09-04: `self` is a keyword (`Expr.Receiver`,
        `Binding.Receiver`), implicit in every method, never in a
        list; `mut fn` parses and is recorded; 746 declarations and
        51 test strings rewritten by script; the compiler compiles
        itself in the new spelling (1618 cases, corpus 72/72).
        S1 LANDED 2026-09-04: `mut` parameters parse (fns, `mut fn`,
        trait sigs); the receivers pass (`language/receivers.av`, a
        whole-program fixpoint, one memo family) records every
        writing method; the seat law and the exclusivity law refuse,
        the receiver law WARNS — 981 sites in the compiler's own
        source, the conversion's census; the trait contract refuses,
        an unused `mut fn` warns (1655 cases, corpus 73/73). ORDER
        AMENDED: the conversion (S4) comes BEFORE the ABI (S2) — the
        cell ABI has no legacy path, so every writing call site must
        be a place first; the receiver law's warning becomes the
        refusal the day S4 closes.
        S4a LANDED 2026-09-04: every owned-state parameter is a `mut`
        seat by script (1004 seats in 18 types; 71 let-bound
        contexts became `mut`; 9 inline contexts bound first); the
        receiver-law census fell 981 -> 108, every survivor a
        shared-state root (`ws`, `types`, `decls`, `store`); the
        captured-seat law warns at 91 sites — the closure fields,
        S4b's list. The ratchet reads through the `mut` mark (I21,
        I23). 1661 cases, corpus 73/73.
        S4b-1 LANDED 2026-09-04 — THE HONEST SEATS: the pass covers
        every seat of every fn (a fixpoint over (decl, seat) with
        flows between seats; a trait's declared seat is a write by
        permission; a local bound to a call, a construction or a
        place is typed from declarations; an untypable subject marks
        its managed arguments, never its scalars); `type.seat_unused`
        F2051 warns a `mut` seat the body never writes through, and
        the script removed 270 marks the census named — the tree's
        `mut` now tells the truth (0 unused seats, 108 receiver-law
        sites at shared-state roots, 54 captured seats). 1661 cases,
        corpus 73/73.
        S4b-2 LANDED 2026-09-04 — THE BRACKETS: every bracket whose
        thunk captured the driver is spelled at its site — the
        resolver's overlay and receiver scopes open and close as two
        verbs, the typer's narrow frame takes a SELECTOR and the walk's
        inputs, the hunger door is `hungry(cx, e)` behind an `if`, and
        the presence region is `open_presence` / `present_arm` /
        `close_presence` at its seven sites. Captured seats 54 -> 39,
        all closure fields now (S4b-3). 1669 cases, corpus 73/73.
        S4b-3a LANDED 2026-09-04 — THE CONTEXT IS THE TYPER: `TypeCx`
        carries the pass's state (the seats in scope, the narrows,
        the promises, the lambda barriers, the paired heads, the
        dispatch) and the walk's verbs are its methods in
        language/typing.av — `walk`, `walk_under`, `type_stmts`,
        `block_type`, `walk_narrowed`, `lambda_body`, `feed`,
        `speak_hungry`; `StmtTypeCx` and its `cx.expr` are gone (44
        sites), the thunked `answering` bracket is a push and a pop at
        its two sites, and five duplicate verbs died (`stmt_loc`,
        `def_type`, `record_binding`, `method_sig`, `stmt_sig`;
        `written_at` folded into `written`). Typing's captured seats
        11 -> 0 (F2048 20 -> 9: the resolver's and lowering's closure
        fields, S4b-3b/c). `Dispatch`, `semantics_of`,
        `stmt_semantics_of` and `post_order` moved to
        features/dispatch.av so a features-level context can hold
        them. FOUND on the way: (1) the impl in the driver's module
        was an ORPHAN under a MODULE-level orphan law — the spec's
        (16.5) is PACKAGE-level, and the law now is (F2037 names the
        package; sibling modules may give a type its verbs; a
        dependency's type takes only a local trait); the general
        ledger's STRICT entry is amended. (2) A refused impl's methods
        declared WRECKAGE without the receiver seat and the walk
        TRAPPED reading a param ("index 1 is out of bounds") — the
        recorded crash class; `seated_wreckage` seats the receiver,
        and the old binary's trap on `impl Nope { fn f(n: int) … }` is
        the new binary's F2031. (3) An orphan's method, called,
        CASCADED (F2037 + F2030): the orphan refusal stands alone now
        — the impl still serves its target for the walk. (4) STARVING
        was the re-run node's alone by an accident of the old wiring
        (every nested walk minted a fresh cx); three tests pinned it,
        and brackets in `walk`/`type_stmts`/`feed` keep it. (5) The
        ratchet's I26 and I21 matchers did not read `mut fn` as a fn
        header (I23's blind spot again) — fixed, a specimen added.
        (6) `make avra` sends refusals to /dev/null: `avra build`
        prints diagnostics on stdout while warnings ride stderr — a
        CLI channel finding for the sweep lane; `./avra check` reads
        a failed build. Red team: 20 probes through the old and new
        binaries, 19 byte-identical, 1 crash -> refusal; 6
        package-level orphan attacks as spec tests. A bridge compiler
        (HEAD + the law) built the tree. 1674 cases, corpus 73/73.
        docs/MINIMUM.md's `Typer`/`StmtTypeCx` shapes are the ratified
        2026-09-02 snapshot, superseded here.
        S4b-3b LANDED 2026-09-05 — THE CONTEXT IS THE RESOLVER:
        `ResolveCx` carries the pass's state (the definitions, the
        program scope, the overlays, the lambda frames, the floors,
        the receivers, the open body's `mut` seats, the walked and
        scoped bits, the seat names in scope, `in_block`) and the
        walk's verbs are its methods in language/resolve.av —
        `resolve_stmts`, `walk`, `walk_under`, `scope_stmts`,
        `bound_scope`, `block_scope`, `arm_scope`, `lambda_scope`,
        `impl_stmts`; the four name-use verbs wear the contract's
        names (`use_name`, `use_call`, `use_type`, `use_receiver`);
        `StmtResolveCx` is gone (33 sites), `Def` and `LFrame` live
        with the context, and `speak` is `emit` in every pass context
        (one diagnostic verb; typing's 26 sites swept too). Captured
        seats F2048 9 -> 3 (lowering's closure fields, S4b-3c);
        receiver-law F2047 97 -> 94, no new site in features. Red
        team: 25 resolver probes (shadowing at every scope, capture
        chains, the floor and the const crossing, keywords and
        reserved words, `self` outside a method, `mut` seats, paired
        loops, arm binds over params) byte-identical through the
        S4b-3a binary and this one on check and run; no finding, so
        no new test — the existing resolve suite already pins each
        shape. 24 files, +284/-310; 1674 cases, corpus 73/73. The
        gate's peak is 2.3 GB now (lane A's parallel suite), up from
        1.4 GB — relevant to the machine's load budget.
        S4b-3c LANDED 2026-09-05 — THE CONTEXT IS THE LOWERING, AND
        S4b IS DONE: `LowerCx` carries the body's state (the
        emitter, the registers and slots, the instantiation and the
        declared answer, the dispatch, the mono worklist) and the
        walk's verbs are its methods in language/lower_walk.av —
        `reg_of`, `lower_block`, `lower_stmts`, the narrow/widen
        edge, the dyn lift, the printed answer — with the state's
        vocabulary in lower_state.av; `StmtLowerCx` is gone (29
        sites) and with it the `mut ex = cx.expr` borrow (5 sites);
        `Jobs`/`Wanted`/`Lift`/`Wrap` live in features/worklist.av.
        Captured seats F2048 3 -> 0 — EVERY closure field in the
        three passes is a method now — and THE SEAT LAW'S CAPTURED
        CASE IS A REFUSAL. It caught one site: the memo kernel's toy
        test handed a captured tally to `mut` seats and counted runs
        through list aliasing — (B)'s shape in a test; its seats
        read until `Cell`. Receiver-law F2047 94 -> 92 (one lowering
        helper took the context by value and called `reg_of`; a
        `mut` seat now). Red team: 28 lowering probes (every loop,
        let-else, cells, fn values and wrappers, nested lifts, dyn
        boxes, two instantiations of a generic, `fail` and `?`,
        every printable answer and the unprintable one) through the
        S4b-3b binary and this one — check, run, the IR text and the
        LLVM module all byte-identical, zero diffs in 112
        comparisons; no finding, no new test. 26 files, +334/-426;
        1674 cases, corpus 73/73.
        S4c-1 LANDED 2026-09-05 — THE PASS-OWNED BORROWS PAID, AND
        TWO LAWS FOUND: 43 of the 78 `mut x = self.field` borrows are
        direct path writes (decls 16, facts 9, the memo kernel 4,
        namespace 4, resolve 4, lower_state 4, types 2, unify 1); the
        35 left are the (B) roots' (workspace `ws.` 5, the toy test
        3, interp `m.` 14 and llvm `em.` 6 — free fns whose seats
        become methods on `mut self`, S4c-2 — and lane A's grammar
        3). (1) A BORROW ALIASES, A PATH WRITE THROUGH A SHARED
        INTERMEDIATE COPIES (CLAUDE.md): the lowering's worklist,
        ONE box shared by design, lost every lift the moment its
        pushes became path writes — the toml suite's `toml$l1040`
        undeclared; every body now OWNS its worklist and hands it
        back (features/worklist.av), the unit drains values. (2) THE
        CONDITION RUNS EVERY TURN (CLAUDE.md): the memory pass had
        released a `while` condition's owned load ONCE, after the
        loop — a leak per turn since the loop rung landed, invisible
        until a path write in the body met the leaked reference and
        copied the list each turn (the kernel's `cells` grow: 9 s and
        17.5 GB for 60k pushes; the compiler checking itself 6.9 GB,
        killed). A loop region opens a scope for its condition,
        settled at each `LoopCond`: 0.26 s and 1.6 MB; the compiler's
        self-check 1.1 GB -> 0.68 GB, the gate's peak 3.4 -> 1.9 GB;
        lower_test pins the placement (fails on the old binary). The
        fix needed a two-stage build — a binary compiled by the old
        pass leaks in its own kernel loop. Receiver-law F2047 92 ->
        96: the kernel's methods now visibly write at `ws.db` (the
        borrow hid it). Red team: 125 programs through main's binary
        and this one, check/run/IR identical (none reads a managed
        field in a loop condition — hence the new test); the
        bisection ran through the product checking its own package
        as the oracle. 1674 -> 1675 cases, corpus 73/73.
        S4c-2 LANDED 2026-09-05 — THE INTERPRETER AND THE BACKEND ARE
        VOCABULARIES: interp.av's 72 free fns over `m: Machine` (273
        call sites) and llvm.av's 31 over `em: Emit` (88) are methods
        on `self` — `impl Machine`, `impl Emit` — and the 11 lambdas
        that captured the machine to reach a writing verb
        (`with_array(v, what, (id) -> self.popped(id))`) are a
        let-else guard each, no capture; the checklist's "38 free
        state fns become methods" is paid. Of their 21 borrows, 18
        are LICENSED I33 (new in DOGFOODING's registry): THE BORROW
        UNDER A SAME-SCOPE READ. A path write after a same-scope read
        of the field finds the list SHARED — the read's owned load
        lives to the scope's end — and CLONES it: `slot_written`
        cloned the interpreter's whole array table per store (the
        pop probe 0.7 s -> 43 s), and 18 of S4c-1's conversions had
        the shape too (`Decls.mint` cloning `children` per mint). The
        license has two laws: the borrow is taken AFTER any callee
        that path-writes the field (a borrow before `module_id` went
        stale and `file_id` trapped), and liveness (S3) retires it.
        The scan that finds the shape (a read of `self.X` before a
        `self.X.push/set/pop` in one fn) is the landing's tool; the
        registry entry is UNRATCHETED with that reason. Also found:
        the compiler's self-check timings swing 6 s to 36 s on this
        machine between two identical runs — measure twice before
        naming a regression. F2047 96 -> 98: `Pins.pin` writes
        visibly now, and the unify family threads `bound: Pins`
        unseated (10 fns, every caller a `let`) — the next (A) seat
        to pay. F2048 0. Red team: 137 programs through main's binary
        and this one, check/run/IR/LLVM identical; the interpreter
        probes at main's speed. 9 files, +1081/-936; 1675 cases,
        corpus 73/73.
        TRAIT DEFAULT METHOD BODIES — DESIGNED AND LANDED 2026-09-05.
        THE DESIGN, one sentence: a trait declares ONE type parameter,
        `Self`, bounded by the trait itself, and a member with a body
        is a GENERIC METHOD over `Self` — typed once against the
        trait's own contract, lowered per signatory by the mono
        worklist. Every piece rides machinery that stood: `Self` is
        `Var(trait, 0)` (`Decls.tparams` of a trait; `tbounds` binds
        it to the trait, so `self.show()` inside a default is the
        bounded call already judged for `T: Show`); the default's
        body is the member's root (`declared_body`: a sig's body is a
        HOLE, a default's a block), ranged by the member's statement
        spanning name to body's end; `Decls.method` answers a
        signatory's own method first and the trait's default second
        (`defaulted`, through the impls it recorded — recorded BEFORE
        the conformance check, so a member the signatory never wrote
        is answered); a call names the body `method_symbol` mints —
        the default under `Self` := the receiver's type (`Sub {
        target: trait, args: [recv] }`), the dyn vtable through the
        same verb with the boxed value's type — and `lower_fn` types
        register 0 as the receiver through `viewed`; `selfed_sig`
        substitutes `Self` at every call site, so `fn me() -> Self`
        answers the receiver's type. ONE CONVENTION CHANGED: every
        method sig carries its receiver at seat 0 — a trait member's
        wears `Self` — so `sigs_agree` compares past the receiver, a
        contract's seats count from 1 (`contract_judged`, the
        receivers pass's `feed`), and the "self omitted" reading of a
        trait sig is gone. `Self` is a reserved name with its own
        voice. THE GRAMMAR: `( mb:block )?` after a member's answer,
        windowed by span like its params. Red team, 16 probes + the
        corpus pair (`corpus/trait_defaults`: a default per struct and
        enum, an override reached THROUGH a default, a `mut fn`
        default writing through, a bounded generic and two dyn boxes,
        `Self` as an answer — eval == native == the hand-computed
        expected): a default reading `self.x` refuses ("no property
        `x` on `Self`" — a Var has no fields, only the trait's
        members); a body disagreeing with its declared answer refuses
        once, at the default; an empty default is a void method; a
        signatory's INHERENT method of the same name wins over the
        default (pinned); recursion through `self`; `type Self`
        refuses in the trait's words; an override with the wrong sig
        and a call with the wrong arity refuse in the existing voices;
        the abstract member is still owed beside a default. FOUND on
        the way: the member's statement wore its NAME's span, so a
        default's expressions fell to the trait's range and the
        member's own facts table was empty (a trap, "index 3 out of
        bounds"); and `Self` in a sig needed the trait's type scope
        entered at declaration. Differential: 138 programs, the only
        diffs the old binary refusing the syntax and one
        specialization's symbol shifting two interned ids
        (`safe_show$12` -> `$14`, the trait's `Self` interned). F2047
        98 -> 99 (`selfed_sig`'s `substituted` interns — a `mut` seat
        now). 19 new cases (10 vertical, 9 adversarial), 1694/1694;
        corpus 73 both ways. `Self` in a BODY's local annotation is
        the recorded generic-impl gap (the tscope is the fn's own).
        THE PAYOFF SWEEP, LANDED 2026-09-05: the pass methods a
        feature had nothing to say at are the contract's DEFAULTS —
        `kids` and `heirs` answer `[]`, `resolve`, `resolve_stmt` and
        `type_stmt` do nothing, `lower_stmt` answers null — and the
        26 impl methods that spelled exactly that are gone (9 `heirs`,
        6 `lower_stmt`, 4 `resolve`, 4 `type_stmt`, 2 `kids`, 1
        `resolve_stmt`), with the 10 imports only they used; `type_of`,
        `lower` and every statement's own verb stay mandatory. The
        compiler's own dispatch now runs through defaults mono'd per
        feature — the first program to exercise the feature at scale
        is the compiler. The dead-parameter rule (I23) exempts a
        trait's own block as it exempted `impl Trait for T`: a
        default's seats are the contract's. Differential: 157
        programs, check/run/IR/LLVM identical; F2047 99 -> 97; 19
        files, +35/-114; 1714/1714.
        THE PINS SEAT, LANDED 2026-09-05 — the last (A) seat the
        borrow had hidden: the unify family's `bound: Pins` is `mut`
        exactly where it WRITES (`var_binds`'s `pin` and the eight
        that hand it there — `unify`, `paired_unify`, `app_unifies`,
        the five shape unifiers, `generic_argument`, `generic_field`,
        `agreed`), plain where it reads (`bound_args`, `bound_closed`,
        `fully_bound`, `unpinned_of`, `unified_lift`, `pinned_by_want`),
        and every creation site a `mut` local. THE SEAT LAW DREW THE
        LINE ITSELF: a blanket `mut` refused twelve call sites (a
        temporary handed to a writer, a `let` handed to a reader
        marked as a writer), the fixpoint's F2051 named the two seats
        marked without a write, and the honest marking is what
        remains. F2047 97 -> 96, F2051 0. 5 files, +17/-17;
        1714/1714.
        `mut` IN A FN TYPE — THE SEAT LAW'S MISSING HALF, LANDED
        2026-09-05. A SOUNDNESS HOLE, found by lane D and re-verified
        here: a `mut`-taking fn stored in a plain `fn(T) -> V` seat
        wrote through an immutable `let` with ZERO diagnostics, both
        engines (`1 2 2` where the V1 law demands `1 1 0`). The law
        held at the direct call and evaporated at the indirect one.
        THE FIX, in the type: `Type.Fn` carries a parallel `muts`,
        the interner's key carries them, and `fn(mut Cx, int) -> int`
        is a DIFFERENT TYPE from `fn(Cx, int) -> int` — so the
        agreement door refuses the store with no new law written. The
        spelling is `fn(mut T, U) -> V` (the closures grammar, marks
        windowed by span like a fn's own parameters), and the seat
        law now reads MARKS rather than a DeclId, so a declared
        callee and a fn-typed value are ONE rule (`declared_marks`
        projects a declaration into that currency; `seats_judged`
        applies it at every indirect call). ONE ASYMMETRY, the sound
        direction: a seat that PERMITS writing accepts a callee that
        does not write (`fn_fits`), a seat that promised not to write
        refuses one that does — that is what lets 14 plain builders
        keep their honest spelling in a `fn(mut Builder)` seat.
        FOUND on the way: (1) marks must be NORMALIZED at `intern`
        (trailing unwritten ones dropped), else `fn(T)` built two
        ways refuses itself with identical words on both sides — the
        mapping agent flagged the same hazard independently; (2) the
        law immediately found two REAL defects in the tree — the
        `defer` builders write through their Builder without saying
        so, and `build_named` handed a freshly built Builder to a
        `mut` seat (a value, not a place); (3) `pinned_by_answer`
        carried a `mut` seat it never wrote. F2051 is now ZERO and
        F2047 is unchanged at 96. THE SEAM IS SPELLED: `BuilderRow.build`,
        `MethodRow.check`/`lower` and `PropertyRow.check`/`lower` say
        `fn(mut …)`, which retired the three F2051 warnings lane D
        reported in lists/walks.av. The seven `seated` preambles
        there COULD now collapse through a higher-order verb; judged
        CHURN and left — it would put an indirect call in the
        compiler's own lowering path to save eleven lines, and the
        guard reads plainly as it stands. THE BUILD took four stages,
        because a language change the tree uses cannot bootstrap:
        marks ignored -> seams spelled -> marks live -> the widening
        (each stage's product compiling the next). Red team: 14
        probes (the hole, the indirect call both ways, the widening,
        a lambda into a marked seat, a field, a parameter, an answer,
        two marks, one root twice, a capture, a trailing comma) —
        every accepted program eval == native; 15 new cases and
        corpus/fn_seats. 1856/1856, corpus 75/75. NOT MINE, recorded:
        a generic fn as a VALUE (`ident<int>` unapplied) does not
        parse — "expected BREAK while parsing `stmt`" — which is why
        a generic `mut`-seat fn cannot be stored yet.
  - [ ] THE ALIAS BORROW paid: the 38 free state fns
        (interp.av `m.frames`, resolve.av `r.overlays`,
        workspace.av `ws.specs`, llvm.av `em.vals`, …) become
        METHODS writing `self.field.push(v)`; `borrows_field`,
        `mark_borrow` and `unique_box`'s borrow load DELETED; a
        `mut` bound to a parameter's field path REFUSED. (bs2's
        #1377 ICE — a method call on a captured local in an early-
        returning loop — is why they were free fns; prove ours does
        not have it first, with one probe.)
        PROBED 2026-09-04: ours has no #1377 (eval and native
        agree). SIZED the same day: this is the design's S4 —
        methods are half of it; the other half is the pass
        contexts (355 mutating calls through a context parameter,
        929 context-first fns), which the design pays with `mut`
        parameters on the same seat. A parameter's field path
        bound `mut` becomes a COPY, not a refusal (see the design).
  - [ ] RECEIVER ALIASING closed: the ledger entry struck, the
        memory doctrine's V1 line updated to "by law, enforced".
  - [x] A NESTED ELEMENT WRITE COPIES THE ROW — CLOSED 2026-09-05 by
        S3b, which is exactly the diagnosis below: "the row arrives
        shared (the read ahead of the write retains it)". That read
        was the OWNED TWIN, and liveness now declines it. The probe's
        shape — a struct field `List<List<int>>`, a nested `.set`
        through a `mut` parameter, 20k writes into a 20k row — runs
        in 0.00s against main's 0.29s, well inside the 200ms the
        DONE WHEN asked for. Lane A needs it for the parse memo.
  - [x] (the original entry, kept for its diagnosis) A NESTED
        ELEMENT WRITE COPIES THE ROW (probed 2026-09-04 by
        lane A, which needs it for the parse memo): `mut s = m.slots`
        then `s[i].set(j, v)` answers correctly but costs O(row) per
        write — 20k writes into a 20k row took seconds. The place
        path opens slot `i` unique, but the row arrives shared (the
        read ahead of the write retains it), so `slot_unique` clones
        every time. DONE WHEN the probe (`/tmp/placeprobe/p.av`'s
        shape: a struct field `List<List<int>>`, a nested `.set`
        through a parameter) runs 20k writes under 200ms.
  - [ ] PAIRS IN SLOTS (O4): a scalar nullable in a list slot, a
        struct field and a capture lane — ONE design, three sites,
        the three "cannot hold this yet" voices retired together.
        SIZED 2026-09-05: the typing half is a `slot_worthy` that
        sees the carried shape; the LOWERING half needs a slot that
        holds a PAIR (`{present, value}` is two words, a slot is
        one) — the runtime's slot layout, lane A's. Blocked on that
        layout; the design is the nullable representation's (above).
        A NAMED WANTING SITE, 2026-09-06, from the HTTP lane:
        `packages/std-http/src/frame.av`'s `Framing`, where "a
        Content-Length was seen" is exactly a nullable int and
        `{ length: int? = null }` is F2008. It carries a count beside
        the value for now — an honest workaround rather than an
        entrenched one, since the framing law needs that count
        anyway. Their probe also isolates the boundary the way this
        entry claims it: a nullable ENUM field COMPILES (it rides a
        pointer, so its nullable is a niche), and only the SCALAR
        nullable refuses. Verified here at both halves.
        A wanting site is what turns a blocked item from a want into
        a debt, so it belongs here rather than as a fourth record of
        one thing in the sugar backlog.
  - [ ] FIELD PUNNING `T { name, value }` (needs the type-name
        lexical class decided with the spec — Capitalized?).
        SIZED 2026-09-05: the builder is a line, the grammar is not.
        A punned literal `NAME "{" NAME ("," NAME)* "}"` reads
        `while flag { x }` (a block of one ident after an ident
        condition) as a literal — today's rule survives on the `:`
        that a field requires. The spec (28.5) makes types PascalCase
        and the compiler warns on the rest, so a TYPE token class in
        the lexer (lane A's engine) is the honest key: a literal
        opens on a TYPE, a block never does. Blocked on that class.
  - [x] TRAIT DEFAULT METHOD BODIES (every `nothing()` pass method
        collapses; `kind()`/`message()` as defaults). LANDED
        2026-09-05 — the design and the landing below; the
        `nothing()` sweep is the next slice's payoff.
  - [ ] H3 — THE BORROW CHANNEL IS A SILENT HOLE, and it reorders
        this arc. Measured 2026-09-05 with `./avra check` and both
        engines. H2's shape (a writing method on a non-`mut`
        receiver) at least WARNS. Borrow the field first and there is
        NO diagnostic at all:

            impl Bag {
                fn sneak(v: int) {
                    mut ys = self.xs
                    ys.push(v)
                }
            }
            fn touch(b: Bag, v: int) -> int { b.sneak(v)  b.size() }

        `touch` takes an immutable parameter, and two calls answer
        `1 2 2` on BOTH engines where 11.5 demands `1 1 0`. The
        direct spelling (`self.xs.push(v)`) warns F2047; the borrowed
        one is silent, because the receivers pass never sees a write
        through `self` — the write goes through a local. 32 such
        borrows are in the compiler's own source and 5 of their
        methods are classified NON-WRITING because of it, so the
        F2047 census UNDER-COUNTS by construction.
        THE CONSEQUENCE, and it is the reorder: S3 (LIVENESS) NOW
        COMES BEFORE S2. Three independent reasons, none of them a
        preference. (1) Flipping F2047 to a refusal does not close
        the hole while this channel is open — the law would refuse
        the honest spelling and pass the silent one, which is worse
        than the warning. (2) S2's "what dies" list DELETES the
        borrow mechanism, and DOGFOODING's I34 licenses 17 borrow
        sites precisely because the pass lacks liveness — deleting
        the borrow first turns each into a cloning path write, whose
        measured shape is 60x. Only liveness retires them. (3) S3
        needs no owner decision; S2 needs several (below). Lane A's
        retain/release third is paid by the same slice.
  - [x] S3 — LIVENESS IN THE MEMORY PASS. LANDED 2026-09-05, ahead
        of S2 for the three reasons in H3 above. A managed `Load` was
        an owned +1 at every read; it is now a BORROW of the cell's
        one reference, and earns its own +1 only when it must OUTLIVE
        it — `borrow_outlives` collects the load's register plus
        every MANAGED register derived from it by a non-owning read
        (a scalar pulled out of a box is a copied word and holds
        nothing), finds the last use, and owns when a use gives the
        value upward, or when a bracket or a step that could change
        the cell stands between. Conservative by construction: what
        the scan cannot read as safe owns. Retain and ownership now
        travel TOGETHER — a borrow the scope does not own is a
        release it must not emit.
        MEASURED, which is what the slice was defined by. The
        read-then-write clone class is GONE: the ledger's own 20k
        probe (`let k = m.n` then `m.frames.push(k)`, which cloned
        the frames list once per push) ran 1.71s and now runs in the
        BASE LOOP'S TIME, 0.00s, guard clean on both engines. The
        compiler checking itself, three runs each way: 7.72 / 7.61 /
        7.57 user before, 7.40 / 7.39 / 7.34 after — 3.3%, and the
        small figure is the honest one, since most retains are
        callee-cleans at call seats rather than reads.
        `reads_of` and `same_reg` are new projections in core/ir.av,
        each ONE definition beside the enum: the reads list is what a
        pass asks instead of growing its own, and register identity
        joins `same_expr`/`same_decl`. 1874 cases, 77 programs
        eval == native == expected.
        THE RED TEAM raised 23 and three stood. Two were taken: the
        scan's two INVARIANTS are now written where they are relied
        on — `changes_cell` is COMPLETE rather than merely
        conservative (a cell register never escapes an Alloca, a
        Load, a Store, `avra_cell_unique` or this pass's release, so
        the day one does the test goes blind and the scan is unsound,
        not pessimistic), and `view_of` is spelled as a REGISTRY over
        every `Ins` variant, so a value-carrying instruction cannot
        land without answering it. The third was DECLINED with its
        reason: a `keeps_args` column on RtSig, forcing a borrow
        handed to a storing runtime row to own. It would duplicate a
        law the C side already holds ("a body that KEEPS what it was
        handed takes its OWN reference") and cost a retain on the
        push path, and the hazard it names is not this slice's — a
        keeping row that does not retain dangles whether the read
        owns or not, before and after. What WAS wrong there was a
        registry comment of mine: `avra_once_set` was documented as
        consuming the caller's reference when its body retains. Fixed;
        the reliance is written at `borrow_outlives`.
        WHAT S3 DOES NOT BUY, measured the same day and correcting
        this entry's own first draft: it does NOT retire the I34
        borrows. The sweep was built — 42 sites to the direct path
        write, of which 31 the law accepts, 5 more once the grammar
        executor's `mut cx` cascade converged (4 rounds, no other
        error), and 9 blocked at lane D's capture wall (`ws` is
        captured by value in the lambda that calls `spec_id`). It
        was gate-green at 1877 and it made the compiler 3.4x SLOWER:
        7.5s to 25.6s user, `./avra check packages/std-avrac`,
        reverted and the 7.69s baseline returned. Lane A audited the
        machine rather than assert (every heavy step in integrate.sh
        runs under the lock; their run-to-run variance is under 2%
        across the day), so the ratio is the change, not the load.
        THE MECHANISM, and it is the next slice. A direct path write
        on a receiver field still clones whenever the same fn also
        READS that field: the read goes through the OWNED TWIN
        (`owned_form` picks `avra_array_get_owned` whenever the
        destination is managed), its +1 lives to the scope's end,
        and `avra_slot_unique` then finds the value shared.
        `mark_flat` is the exemplar — `if self.flats[id.index].sealed
        { return }` before `self.flats.set(...)`. S3 as landed
        governs the slot `Load` alone; the design's own words
        ("a USE is transitive through non-owning reads: a child taken
        by `avra_array_get`") say the twin choice belongs to liveness
        too, and that is S3b. Lane A's `known_id` fix is the same
        mechanism paid at ONE site, which is why it bought about a
        second and no more — their ledger attributes the whole
        retain/release third to S3 and is being corrected.
        S3b LANDED THE SAME DAY and closed it. `owned_form`'s twin
        choice is now liveness-governed: a LENDING row's answer — one
        whose subject still holds it — is a borrow unless it must
        outlive the subject. Which rows lend is a REGISTRY COLUMN
        (`lends`, false by default), because the distinction is DATA:
        `avra_array_pop` also has an owned twin and must never be
        borrowed, since a pop HANDS OVER — declining its twin trapped
        "a managed slot popped as a scalar", which is how the column
        earned its place. MEASURED: S3b alone is 7.49s -> 6.83s on
        the compiler checking itself, 8.8% on top of S3's 3.3%, on a
        tree still written in the borrow idiom. Then the sweep — 34
        sites to the direct path write, plus 5 `mut` seats where the
        grammar executor's cascade converged (5 rounds, no other
        error) — is FREE: 6.87s against 6.90s, inside the noise. All
        17 I34 licenses are gone and the idiom is retired.
        H3 IS STILL OPEN, and the reason is exact: the borrow
        MECHANISM cannot be deleted while 9 sites still need it —
        `ws.packages`, `ws.specs`, `ws.asks` and the db_test fixture,
        every one blocked at lane D's capture wall (`ws` is captured
        by value in the lambda that calls `spec_id`). Deleting it
        anyway was tried and reproduced S0's exact failure: the
        compiler built and its declaration tables were EMPTY ("index
        0 is out of bounds"), because a borrow that becomes a copy
        pushes into the copy. So H3 closes with S2, not before, and
        the carve-out's own expiry note ("bs2's aliasing, honored
        until self-host") is now the only thing left of it.
  - [x] THE POINTER-CONSTANT LAW. LANDED 2026-09-05, flagged by the
        SQLITE lane with lane A's placement argument, both adopted. A
        `ConstInt` aimed at a pointer-riding register IS the null
        pointer in BOTH engines (`llvm.av`'s `const_int_value`
        discards the value; `interp.av`'s `const_int_val` answers
        `Val.N`), so a NON-ZERO one would be read as null by each —
        the two engines agreeing on a wrong answer, which is the one
        class eval == native cannot catch. The premise that made it
        safe was true and lived in a COMMENT: "the only ConstInt
        lowering ever aims at a pointer register is 0", which holds
        because `ptr` WAS receive-only when this landed. It arms the moment a
        pointer sentinel becomes spellable, and every C API has one
        (SQLITE_TRANSIENT is `(void*)-1`).
        The guard is in LOWERING, not either engine: the backend's
        emitter has NO failure channel while the interpreter has
        `defect_val`, so guarding the one that can refuse would make
        them disagree on a single instruction — the `print_lowering`
        precedent. One scan at `union`, one refusal, both engines
        inherit it. Unreachable today, so it costs nothing and
        refuses nothing that exists; landing it now converts a
        commented premise into an enforced one while it is free.
        Pinned by three cases fed a hand-built body, since source
        cannot reach the shape. 1877 cases.
        STILL UNREACHED after `avra_ptr_at` landed the same day, and
        the reason is the shape the capability took: a mint is a
        RUNTIME CALL, so its answer arrives in a pointer register
        from a `CallRt` and no integer CONSTANT ever aims at one.
        Probed — `avra_ptr_at(0 - 1)` lowers to `r4 = call
        avra_ptr_at(r3)` and `./avra check` is clean. Had the
        capability been a constant fold instead, this guard would
        have armed on its first use and lane A's `LLVMConstIntToPtr`
        wrapper would have been needed; neither is.
        THE LAW LANE A DREW FROM IT, which is more general than this
        case and is the reason the near miss is recorded rather than
        just survived: MACHINERY BUILT AHEAD OF A DECISION BIASES
        THE DECISION TOWARD THE SHAPE IT SERVES. A correct, unused
        `LLVMConstIntToPtr` is not inert — it is a thumb on the scale
        for the constant-fold route, and that route collides with a
        law landed the same morning, so the feature's first
        legitimate use would have forced someone to weaken or
        special-case it. Lane A declined the wrapper on the weaker
        ground that a backend wall serving no lowering pre-announces
        a capability; this is the stronger one.
        AND THE RECEIPT SHAPE: "the prediction did not come true, and
        here is the mechanism" beats "it came true". The first can be
        luck; the second names a cause.
  - [x] A `mut` SEAT KEEPS ITS BOX (F0900). LANDED 2026-09-05,
        reported by the SQLITE campaign's FFI lane. `fn bump(mut i:
        Id) { i.index = 1 }` over `type Id = { index: int }` was an
        internal defect — "an assignment to a non-place survived a
        clean analysis" — and the trigger is FLATNESS: a record of
        one scalar field travels AS the field, so it arrives in the
        seat as a word with no place behind it and the write has
        nowhere to land. Two fields worked; the `mut fn` METHOD twin
        worked. The law already existed for the receiver and says
        why — typing_impls unflattens an impl's target because "a
        flat record is a value in a register with no identity" — and
        a `mut` seat is the same seat from the other side. `keep_boxed`
        seals every `mut` seat's type at declaration, so behaviour
        never turns on a field count. It matters because `type Id = {
        index: int }` is this tree's documented idiom for a typed id,
        and because `mut` in a fn TYPE landed the same day so a row
        table can hold a writing fn — a row's fn writing through a
        flattened seat is exactly this shape.
        Pinned twice: the flat seat answers, and it answers the SAME
        as its two-field twin. 1880 cases.
        NOT FIXED, and pre-existing on main for boxed records too:
        `mut copy = held` then a write through `copy` still reaches
        `held` (`5 105 105 105` where value semantics wants `5 5 105
        105`). That is the receiver-aliasing hole, S2's, and the fix
        above makes flat and boxed agree about it rather than
        differing.
  - [ ] THE CONDITIONAL ABI IS WORTH LESS THAN S3b's ENTRY IMPLIES,
        and this amends it. `retained_args` retains every managed
        argument of every `Call`/`CallPtr` because callee-cleans
        requires it, and no liveness touches that — so S3b's entry
        says "most retains are callee-cleans at call seats rather
        than reads", which is still true by COUNT. It is no longer
        true by COST: lane A's cold-path fix (44d5e31) took the
        self-check 7.2s to 5.3s by getting a cold branch out of every
        hot leaf — `avra_rc_retain` was saving four register pairs
        and 64 bytes of stack to perform one increment. The per-call
        price the ABI change would remove has already fallen, so a
        CONDITIONAL ABI — a callee that only READS its seat needing
        no caller retain — must be re-measured before anyone argues
        from the old share. It was always a much bigger claim than a
        placement rule; it is now a bigger claim for a smaller prize.
        THE INSTRUMENT IS `make census`, NOT A SAMPLER (lane A, the
        hard way): a sampling profiler charges a release cascade to
        whoever is on the stack, and had them convinced the grammar
        executor was 45% of a run. It is not. Two optimizations were
        landed and refuted on that reading.
        AND THE TECHNIQUE WORTH STEALING: for a change that touches
        COST and not semantics, an EXACT INVARIANT beats a suite.
        Lane A's census counts were byte-identical across their fix —
        557,093,839 retains, 104,997,459 reclaims, 402,442,417 list
        reads — proving same work, same boxes, same order, each
        operation cheaper. A memory-pass change that moves PLACEMENT
        (S3, S3b) cannot use it, because placement changes counts;
        one that moves only cost can.
        RE-MEASURED 2026-09-07 (lane A), as this entry asked, and it
        RE-PRICES UPWARD rather than down. Two 6s samples of
        `./avra check packages/std-avrac`, leaf SELF time — the one
        reading a sampler is sound for, since the cascade caveat is
        about attributing to CALLERS, not about a leaf's own time:

            refcounting, all leaves   41.2% / 41.0%
            avra_rc_retain + release  22.9% / 22.6%
            release_dead (the frees)  16.0% / 16.3%

        So the cold-path fix made each retain cheaper WITHOUT making
        the traffic small: refcounting is still forty per cent of
        self time. The conditional ABI's ceiling is the RETAIN AND
        ITS PAIRED RELEASE — callee-cleans means removing one removes
        both — so ~23% times the share of seats whose callee only
        reads, and NOT `release_dead`, which reclaims the same boxes
        whoever owns them. A qualifying share of a third is ~7%; two
        thirds is ~15%. That is a real prize, and the entry above
        ("a bigger claim for a smaller prize") should be read as
        pricing the PER-CALL saving, which did fall, rather than the
        total, which did not.
        WHAT IS STILL UNMEASURED, and it is the whole decision: the
        QUALIFYING SHARE. Nothing here counts how many call seats
        have a callee that only reads. The census attributes pushes
        and copies to sites but has no retain table, so that number
        needs either one or a compiler-side count of `retained_args`
        emissions by callee disposition. Do not argue the ABI from
        the 23% alone — it is the ceiling, not the estimate.
        AND THE FENCE ABOVE IS ONE LEVEL TOO SHALLOW (lane C, same
        day, correcting this entry as it was written). TWO unknowns
        sit under the 23%, not one:
          1. The AVRA-CALL SHARE. `retained_args` retains for `.Call`
             and `.CallPtr` alone — a `CallRt`/`CallRtVoid` argument
             arrives BORROWED — so part of the 22.9% is traffic the
             ABI cannot reach at all, and the seat denominator must
             exclude runtime rows or the exclusion is counted twice.
          2. The QUALIFYING SHARE IS ITSELF WEIGHTED. "The callee only
             reads" is a STATIC property of the callee (does the seat
             escape its body); "how many retains run here" is a
             DYNAMIC property of the call site. The prize is the sum
             over sites of one TIMES the other, so a tree whose
             qualifying callees are all cold and whose hot ones all
             escape prices near zero while BOTH halves read "two
             thirds". A count of qualifying seats is not the share.
        So: ceiling = 22.9% x (Avra-call share) x (weighted
        qualifying share), and neither factor is measured. The
        split of work is agreed — lane A builds the retain table
        keyed by CALL SITE (the seat is what qualifies, not the
        call), lane C counts callee-side escape against the IR,
        where `view_of` already answers what an instruction does to
        a register and `borrow_outlives` is the same question turned
        around. Neither half is a number on its own.
        MEASURED 2026-09-07 (lane C, `avra seats` against `keeps`):
        **1980 of 5389 managed seats are READ-ONLY, 36.7%** — one
        factor, a floor (a seat handed to another Avra fn still counts
        as escaping), with all five known-answer bodies correct and
        `packs` right on the first run, which is what `keeps` bought.
        The bracket collapsed on the QUALIFYING axis exactly as
        intended (it was 8.6%-47.8%).
        THE CONVERSION TO SELF TIME IS NOT ESTABLISHED, and
        `36.7% x 22.9% = 8.4%` IS NOT IT — recorded because that
        product is the natural next keystroke and it repeats both
        errors this entry already names. It substitutes a STATIC seat
        count for the WEIGHTED share (point 2 above: qualifying seats
        would have to run as often as escaping ones), and it multiplies
        by the WHOLE 22.9%, which includes retain traffic the ABI
        cannot reach — `avra_array_get_owned` retains on every managed
        list read, and cells retain too, while `retained_args` reaches
        `.Call`/`.CallPtr` only (point 1). The second error inflates;
        the first has unknown sign. So the product is an ESTIMATE
        WEARING A FLOOR'S CLOTHES, and 36.7% being a floor does not
        make it one.
        WHAT REMAINS IS ONE FACTOR: the call-seat share of retain
        traffic, and its per-site weight. That is the retain table,
        lane A's, unbuilt. Until it exists nobody can convert seats
        into seconds, and the two published figures — 36.7% of seats,
        22.9% of self time — are measured on DIFFERENT AXES and do not
        multiply.
        AND IT WAS NOT A NEXT KEYSTROKE — I PUBLISHED IT, and lane A
        refused it. The wording above is more generous than the
        record: 8.4% went out as a finding, called a floor, and was
        withdrawn an hour later. It matters because a receipt that
        softens who made the error stops being checkable, and this
        entry is where someone looking for the number will land.
        THE PART THAT GENERALISES: A LAW YOU HAVE JUST FINISHED
        WRITING IS NOT A LAW YOU HAVE INTERNALISED. Clause 2 above is
        mine, written FOUR HOURS EARLIER to correct another lane for
        this exact substitution in the other direction; it stopped
        their version and not my own, in the same lane, the same
        night. And the tell was already in my hand — one message
        before, I had refused to leave a stale upper bound standing
        beside a correct number on the grounds that a range someone
        can quote the top of is worse than no range.
        THE JOIN, WHEN THE TABLE EXISTS, IS PER SITE: weights keyed by
        the call site's callee symbol and seat index, joined to the
        static qualification, summed over sites — never two aggregates
        multiplied, which is the only form that cannot smuggle
        uniformity back in. If only a coarser table is reachable the
        join is UNAVAILABLE, not approximate; approximating it is how
        this error returns wearing a different hat.
  - [x] A RECONSTRUCTION NAMES ONE FIELD, NEVER THE REST. LANDED
        2026-09-06; found by the DOCS campaign's subset lane, and it
        was a latent hole in the seat law's own slice. `plain(t)`
        answered "the same written type with its `?` dropped" by
        spelling SIX of TypeRef's seven fields, so `muts` — added by
        the `mut`-in-a-fn-type slice itself — was dropped from the
        day it existed. A `mut`-taking fn stored in a plain fn seat
        writes through an immutable `let` with no diagnostic, in both
        engines, which is the hazard that slice was landed to close.
        LATENT ON A GAP THAT WILL CLOSE, which is the shape this lane
        keeps meeting: the one caller feeds `fn_written`, and a
        nullable fn type is UNSPELLABLE today (the `?` binds to the
        return, and the fn-type grammar has no trailing `?`), so
        nothing can reach `plain` with marks. The day it can, the
        marks are dropped on the path that decides seat
        compatibility, and no test fails in between — the same
        structure as the sqlite double-close, one level in.
        THE FIX KILLS THE CLASS: `t with { optional: false }`. A
        reconstruction names WHAT CHANGES and inherits the rest, so
        the next field cannot be dropped. Spelling the others out is
        what drops them — and a field with a DEFAULT drops with no
        compile error at all, so the thing that makes a field cheap
        to ADD is exactly what makes its omission invisible.
        Pinned by a hand-built value, since the grammar cannot reach
        it, and FIRE-TESTED: the test fails against the old `plain`
        and passes against the new.
  - [x] A BUILDER'S WORDS ARE ITS CLAIM. LANDED 2026-09-06, the
        features half of a two-owner fix the SQLITE-LEAD asked for.
        The executor prefixes EVERY builder error with "builder
        failed:" (grammar/executor.av:365), which reads as an
        internal defect — so a LAW the writer can fix sends them to
        file a bug instead of adding a parenthesis. Measured before
        recommending: FIVE laws already read that way today —
        "`export` written twice", "a `catch` needs at least one arm",
        "a `when` has ONE `_` arm", "the `_` arm ends a `when` — move
        it last", "an `impl` block holds `fn` declarations only" —
        against eight that genuinely are defects.
        IT IS NOT A SEAM CHANGE, which is what made it cheap: `Cause`
        ALREADY separates `Builder` from `Defect`
        (grammar/diagnostics.av:8), so the vocabulary exists and only
        the wording lies. Nothing needed adding to `BuilderRow`'s
        `Result<LangNode, string>` — the WORDS ARE THE CLAIM, so a
        builder cannot say the wrong one by accident.
        THIS HALF: the eight span defects now say "defect: … — the
        arena and the grammar disagree", following the tree's own
        precedent (`tables/builders.av` already said "defect:"). They
        read correctly under the blanket prefix AND without it, so
        this half stands whatever the other half does.
        THE OTHER HALF is `grammar/executor.av:365` — dropping the
        prefix — and it is lane A's file, routed with the
        measurement. Sequenced AFTER the bitwise merge on the
        SQLITE-LEAD's argument, which is right: that slice is gated
        at a fixed point built twice, and folding a two-owner
        diagnostics change into it would put a proven artifact back
        in flight to fix five messages that have read wrong for as
        long as they existed.
  - [ ] THE SECOND-BUILD RULE IS NOT ONLY FOR CODEGEN. CLAUDE.md
        writes it for a codegen fix — "a product built right after
        merging a memory-pass fix carries the fix as SOURCE but its
        own body was compiled by the pre-fix pass". The bitwise lane
        hit it THREE TIMES IN ONE SLICE on FRONT-END changes, and
        their sentence is the one to keep: THE BUILD THAT SUCCEEDED
        WAS THE BUILD THAT LIED. Their first build passed because the
        standing binary knew nothing of `>>`; the failure appeared on
        the NEXT build, when the compiler that had learned to munch
        it tried to read `workspace.av`. `make bootstrap`, not `make
        avra`, was the way out each time. Routed to CLAUDE.md's
        curator as a generalisation of the existing rule.
  - [x] THE PATTERN LADDER GAINS ITS SEAM. LANDED 2026-09-06 for the
        strings lane's typed string patterns. `Pat` is CORE's, and
        its three consumers — `pat_types` (enums/check.av),
        `pat_reg` and `bind_regs` (enums/lower.av) — matched it
        exhaustively from inside `features/enums/`. So the moment a
        SECOND feature owns a `Pat` variant, those enums functions
        must answer for a variant enums does not own, which the
        doctrine forbids in its own words: "a feature never matches
        ANOTHER feature's variants". That is why the seam is OWED
        rather than a rule-of-three judgement — the strings lane
        offered the weaker argument and I replaced it.
        `PatSemantics` (contract.av) with NO DEFAULTS, since a
        pattern that types without accepting is a silently wrong
        match rather than a missing feature; `pat_semantics_of`
        (dispatch.av) beside its twins, exhaustive over `Pat`; enums'
        three bodies behind `EnumPatSemantics`, unchanged.
        THE RECURSION GOES THROUGH THE SEAM — the point that makes it
        work at all. A nested pattern is reached by asking
        `pat_semantics_of` again (`pat_types_of`, `pat_accepts_of`,
        `pat_binds_of`), never by a local call, so one feature's
        pattern can sit inside another's. All seven call sites route
        through it. 1928 cases, 397 spec, no behaviour change.
  - [ ] THE PATTERN TEST SLOT HAS NO CLEARING LAW, and the reason is
        a CHAIN OF OTHER LAWS rather than a property of the slot.
        `bind_test` written twice for one pattern would silently lose
        the first scan's registers and read the wrong offsets. The
        strings lane checked every path and none exists — but the
        argument rests on: the COVERAGE LAW (a format is refutable
        and a string subject has no variants, so `needs_catch_all`
        forbids a format as the last arm, where `chained_reg` emits
        no test), and the BIND LAW (F2039 refuses an `or` run that
        binds). Both live, and I CHANGED the first one today.
        SO THE DEPENDENCY IS WRITTEN DOWN rather than the law built:
        if `needs_catch_all` is ever relaxed for a non-enum subject,
        or F2039 ever permits a binding `or` alternative, this slot
        gains a second write and nothing says so.
        WHY NOT A CHEAP GUARD: "written" would have to mean
        "non-empty", and an encoding that spends the empty value is
        the law this tree has already paid for twice. It happens to
        be exact for FORMATS — a hole-free literal builds `Pat.Lit`,
        so a `Pat.Format` always has at least one hole and never
        writes empty — but the slot is general, and an empty list
        pattern would write empty legitimately. A guard exact for one
        owner and wrong for the next is worse than a named
        dependency.
  - [ ] AN UNRESOLVABLE `dyn` TRAIT AT A FIELD SEAT REPORTS THE WRONG
        LAW, and it cost an hour today. `Dispatch { enumpats:
        EnumPatSemantics { } }` with `PatSemantics` NOT IMPORTED into
        the file reports F2010 "field `enumpats` is `dyn
        PatSemantics`, this is `EnumPatSemantics`" — which reads as
        "your type does not implement the trait" and sends you to
        audit the impl. The truth is F2032 "`dyn PatSemantics` names
        no trait", which the same value under a TYPED LET reports
        immediately.
        THE CAUSE: `dyn_accepts` (checks.av:173) asks
        `dyn_contract(shape_of(want))` and answers FALSE when the
        name does not resolve, so the field seat falls through to its
        generic mismatch. The typed-let path asks whether the name
        IS a trait first. Two paths, one question, different answers.
        This is the builder-prefix defect one law over: a message
        that is TRUE about the symptom and points away from the
        cause. The fix is for the field seat to ask the same question
        the typed let asks, before judging the value.
  - [ ] A CONTENT HASH THAT EXCLUDES SPANS CUTS OFF CONSUMERS THAT
        CARRY THEM — lane A's finding, traced into this lane's files
        and made concrete. The premise is deliberate and documented:
        core/nodes.av:5, "reformatting never changes a fingerprint".
        `parsed` settles on `program_hash`, a fold of those
        fingerprints (workspace.av:319), and `items` settles on
        `fp(7, [item_print(…)])` — "its name, kind and visibility"
        (workspace.av:333, :344). Neither hash moves when only spans
        move.
        THE CONCRETE EXPOSURE HERE: `Decl` carries `lo` and `hi`
        (decls.av:24). Reformat a file so a declaration's offsets
        move with no name, kind or visibility changed, and `parsed`
        RE-RUNS — its dependency on `source` is dirty — so the store's
        spans are fresh, but `items` CUTS OFF, so `ws.decls` keeps
        the old `Decl.lo/hi`. Every diagnostic pointing at that
        declaration then points at the wrong place, and the query
        layer reports green.
        NOT `Typed`: it settles on `ws.db.revision()`
        (workspace.av:473), so it never cuts off and is not exposed.
        The rule is narrower than "any consumer of `parsed`" — it is
        any consumer settling on a hash that omits what the consumer
        answers.
        LATENT, on the usual gap: `disarmed` kills the verifiers and
        nothing re-verifies at revision one, so a one-shot CLI cannot
        reach it. It fires the day the workspace is long-lived, which
        is Era IV's whole premise. FOURTH instance in a day of A
        SAFETY PROPERTY RESTING ON A GAP THAT WILL CLOSE.
        THE FIX IS PER-CONSUMER, not a second hash: a query whose
        answer carries spans must settle on something that moves when
        spans move. Recorded, not built — it wants the live-editing
        fixture that makes it go red, which does not exist yet.
  - [ ] A CONST'S REGISTER WEARS THE LITERAL'S TYPE, where the
        DECLARATION's should decide — CLAUDE.md's cell law one seat
        over, never audited for consts. `constant_reg`
        (lower_state.av:118) says so in its own doc, "minted at the
        literal's OWN shape", and `lifted_constant` lifts for `.Opt`
        alone. Found 2026-09-05 by the SQLITE campaign's FFI lane
        while scoping a pointer sentinel.
        LATENT, and the reason is the typer rather than luck: the
        only divergence a const can reach today is a literal under a
        nullable annotation, which the `.Opt` lift already handles.
        Every other mismatch is refused before lowering — `const P:
        ptr = 1` is F2024 "declares `ptr`, this is `int`". So the law
        is violated in shape and not yet in effect.
        NOT FIXED, deliberately: unlike the pointer-constant guard,
        which REFUSES and so costs nothing to land early, this one
        CHANGES lowering, and there is no reachable case to test it
        against beyond the one already handled. Changing working
        codegen with no observable difference and no test that can
        distinguish it is churn carrying risk. The fix lands WITH
        whatever first makes a declared type diverge from its
        literal's — the sentinel, if the owner grants it.
  - [ ] A GENERIC BODY NOTHING INSTANTIATES IS NEVER LOWERED, so
        every lowering-level law is blind to it — the pointer-constant
        guard, the mint-order law, every `lower_defect` a feature can
        raise. Not "runs and passes": never runs. Found 2026-09-05 by
        the SQLITE campaign as a claim about LIBRARIES, which is
        false and worth recording as false: a library has no entry,
        and `union` (lower.av:134) seeds `bodies` with every declared
        body exactly when `entry == null`, so `avra check` on a
        library already lowers all of them. The hole is the FILTER —
        `declared()` goes through `lowers_plain` (lower.av:223),
        which requires `tparams(d).is_empty()` and the parent's too.
        A generic body has nothing to instantiate it WITH, so no
        `every` flag reaches it.
        NOT A FLAG. Lowering a generic body with no instantiation
        needs either a canonical instantiation or a lowering that
        tolerates unbound type parameters, and both are design
        questions. Recorded, not scoped.
        THE SIBLING TRAP, worth its own line because two lanes were
        caught by it in one day: a REDUCTION THAT REMOVES THE CALL
        SITE REMOVES THE PASS. A repro cut down to a declaration is a
        program whose entry reaches nothing, so a lowering defect
        goes quiet for a reason that has nothing to do with the bug.
        That is how F0900 hid.
  - [ ] S2's SIZE, censused by lane D on cfa834d and NOT what either
        of us expected: 100 sites in std-avrac, UNCHANGED by the
        borrow retirement, plus 3 in std-toml which lane D fixed.
        The hidden sites did not become visible, and the reason is
        structural: F2047 fires on a non-`mut` RECEIVER AT A CALL
        SITE, and a write through `self` INSIDE a method is the
        receiver's own law, so the warning lives at the caller — who
        was already counted. The retirement moved writes from a
        borrowed local to `self.field`, which is a shape the lint
        still does not count. The exception proves it: every newly
        visible warning was in std-toml, whose readers are FREE
        FUNCTIONS taking `rd: Reader` rather than methods.
        SO F2047 IS THE WRONG INSTRUMENT FOR H3. A self-rooted write
        never was countable by it. The instrument is the BORROW SITES
        themselves — 34 before the sweep — and anyone sizing H3's
        channel from the lint's number will size it at zero.
        S2's shape is unchanged site for site: 9 captures (8
        production in workspace.av and lower.av, 1 the db_test
        fixture), 38 value-args (2 production), 1 alias at
        typing.av:410, the rest tests.
  - [x] A PROGRAM MAY MINT A POINTER FROM AN INTEGER. LANDED
        2026-09-05 on the OWNER'S WORD — escalated as a capability
        rather than decided in a lane, held through a peer's relay of
        the approval, and built on the owner's own say-so. `ptr` is
        no longer receive-only, and the two entries above that said
        so are corrected in place rather than left to rot — a stale
        SUBSET claim is worse than none, because it says "do not
        write this" and charges every future author the workaround
        forever while reading exactly like a live one.
        THE SHAPE COST NO COMPILER CHANGE: one C body,
        `avra_ptr_at(int64_t) -> void*`, reached the way every std
        primitive is reached — an `extern fn` declaration and the
        existing host seam. The capability was a RUNTIME row, not a
        language feature, which is the vocabulary seam rule answering
        correctly on its own.
        ANSWERS `ptr?`, and the failability is the NICHE rather than
        a check: a non-optional pointer structurally cannot hold 0,
        so zero IS null and SQLITE_STATIC arrives as absence with no
        extra word. SQLITE_TRANSIENT is -1 and differs from it by
        PRESENCE alone, which is the one thing observable about a
        `ptr`.
        THE FENCE HOLDS, probed three ways: an int literal at a `ptr`
        seat is F2000, an int binding under a `ptr` annotation is
        F2024, and — stronger than promised — a MINTED `ptr?` at a
        bare `ptr` seat is F2000 too, so even the minted pointer
        cannot slide anywhere without a deliberate unwrap. One named
        door, no cast operator, no widening seat, and the grammar has
        no cast syntax to extend.
        WHY IT IS SAFE, from the research (docs/2026_09_06_RESEARCH_
        ptr_from_int.md, every claim quoted from a primary source):
        CREATING a pointer is harmless in every model surveyed and
        DEREFERENCING is the entire danger — and THE LANGUAGE has no
        dereference. CORRECTED THE SAME NIGHT by lane A, who tested
        the premise instead of accepting it: the ROWS dereference
        what they are handed. `avra_array_push` casts its argument to
        an array and writes through it with no header check — it
        cannot afford one — and the extern seam accepts any linked
        symbol at check time, so `avra_array_push(avra_ptr_at(a), v)`
        is an arbitrary WRITE composed of two safe-looking parts, and
        it compiles clean. That property needs no new capability and
        holds with or without this door, so the owner's yes stands on
        its merits; what was wrong was the SENTENCE, and a comment
        asserting a safety property that does not hold is what lets
        the NEXT capability be granted on bad grounds. Lane A caught
        it within the hour, grading foreign-text designs against a
        property none of them had.
        AND THE BIGGER FACT IN IT: AN EXPORTED C SYMBOL IS A LANGUAGE
        CAPABILITY IN THIS TREE. Any file may declare an extern for
        any linked symbol with nothing central authorising it —
        `avra_trap` is declared privately in query/db.av and no
        registry blessed it. There is no "reachable from C but not
        from Avra" here, so every runtime export is a language
        decision whether or not anyone frames it as one. Java is the decisive precedent because it drew
        the line explicitly rather than inheriting it
        (`MemorySegment.ofAddress` unrestricted, `reinterpret`
        restricted); Rust's `without_provenance` names our case in
        its own docs; Go forbids it for a MOVING GC we do not have,
        which is the right kind of negative evidence because the
        reason does not transfer.
        THE CAVEAT TO CARRY: SQLITE_TRANSIENT is a FUNCTION pointer,
        and Clang signs those on arm64e. It is safe today only
        because SQLite COMPARES it and never calls it — which stops
        being true the day C callbacks land.
        Proved in `corpus/native/externs.av`, a file that already
        existed for the host seam: `null some some`.
  - [x] THE FINGERPRINT CLASS CLOSED by lane A at 292d273, and two
        PROCESS laws came out of it that are worth more than the fix.
        NINE OF THIRTEEN splice sites collided; all thirteen pass
        now. The fix is at the COMBINER: `fp` folds the payload's
        LENGTH before its parts, so arity rides the hash and no
        boundary can move. It subsumes `fp(29, …)` per arm, which
        was already that shape.
        1. RENUMBERING WOULD HAVE FIXED NOTHING, and I recommended it
           — I told the HTTP lane "64 is free, that's the fix". The
           OLD `fp` was `h = tag` then `h*131 + p + 7`, so a
           single-part hash is `131·tag + part + 7`: LINEAR IN THE
           TAG. Changing a code shifts every hash by a constant and
           separates nothing, because a payload can be chosen to
           absorb it. The axis was never WHICH code, it was whether
           ARITY is in the hash. A fix that moves the cases rather
           than separating them turns the first test green and leaves
           every collision reachable.
        2. A TEST THAT PASSES FOR THE WRONG REASON IS WORSE THAN NO
           TEST. Lane A's first `type_fp` case compared two `let`s
           differing only in optionality — which differ by TAG anyway,
           so it would have passed against the BROKEN tree. It was in
           the file until they ran it against the PARENT commit. That
           is the fire-test discipline stated as a law: a test for a
           defect that has never been SEEN to fail is a test you are
           trusting on faith, and running it against the parent is
           what converts faith into evidence.
        AND THE SPACE QUESTION IS SETTLED THE OTHER WAY: core/nodes.av
        is ONE space, not three. Patterns, expressions and statements
        MEET, because `arm_fps` folds two of them together and
        `restamp` wraps the third. The earlier "benign across spaces"
        reading was wrong about this file. `make fingerprints` is in
        the gate, with its teeth witnessed.
        AND IT CAUGHT A REAL ONE WITHIN HOURS, which is the receipt
        that matters more than the teeth test. Lane C's statics slice
        went red on `make fingerprints`: tag 105 claimed twice — lane
        A's `fp_list` and lane C's `mark_static`, two lanes picking
        the same free number the same night, exactly the way I33 was
        once landed twice and silently dropped the earlier rule.
        Neither author could have seen the other's choice, no review
        would have compared them, and the collision would have been
        SILENT — a fingerprint that quietly conflates two node kinds
        does not fail, it answers wrong later. Caught in the gate, on
        a case the keeper was not built for, by a lane that did not
        know it existed. A keeper's worth is measured by the catch it
        did not anticipate, and this one had it on day one.
  - [ ] THE CLASS CHECK BEFORE IT WAS WRONG — RETRACTED THE SAME HOUR by
        lane A, who found ~10 more sites and CONSTRUCTED three
        collisions from ordinary source. What follows is kept as
        written, because the way it was wrong is the useful part.
        HOW IT WAS WRONG: I grepped fifteen flattened fingerprints,
        EXAMINED TWO, and reported on all fifteen. `.Call(callee,
        pins, args)` was in my own grep output and I never opened it
        — it splices pins and args flat, and `type_fp` of an OPTIONAL
        type is `fp(2, [fp_str(name)])` while `.Ident(name)` is
        `fp(2, [fp_str(name)])`, byte for byte. So `f<A>(B)` and
        `f<A, B?>()` are one fingerprint, with no crafted literal.
        That is a measured fact plus an inference asserted at the
        confidence of the measurement — the exact shape I have named
        in three other lanes today, committed by me while naming it.
        LANE A'S FIX GENERALISES MINE: a sequence folds to ONE value
        (`fp_list`), so every payload has fixed arity and no boundary
        can move — which is what `fp(29, …)` did per arm, applied to
        every splice. And the tell they found is our own law in our
        own core: `.If` already reached for a separator,
        `stmt_fps(then) ++ [0] ++ stmt_fps(else)`, and 0 IS NOT A
        SPARE VALUE — a statement fingerprint can be 0, and then the
        separator is data. AN ENCODING SPENDS THE EMPTY VALUE, in the
        file that records the law.
        SEVERITY, theirs and bounded: `program_hash` is the parse
        query's value, so a collision reuses stale analysis for a
        changed program — latent while a workspace is one-shot, live
        the day incremental re-analysis ships, where the symptom is
        "the compiler ignored my edit".
  - [x] THE CLASS CHECK, AS WRITTEN AND WRONG: every other flattened
        fingerprint in core/nodes.av is unambiguous, and the reasons
        are worth recording so nobody re-derives them.
        A FLATTEN IS AMBIGUOUS ONLY WHEN TWO OR MORE VARIABLE-LENGTH
        RUNS MEET WITH NO BOUNDARY BETWEEN THEM. The survivors are
        safe by one of two structures: FIXED ARITY PER GROUP
        (`case_fps` 3 per case, `param_fps` 2 per param — the group
        size implies the boundary), or PAIRED LISTS OF EQUAL LENGTH
        (`When`'s conds and values, which `build_when` refuses to
        build unequal, so 2n+1 determines n).
        `variant_fps` is the one that is ambiguous only by a HASH
        COINCIDENCE rather than by construction — a variant name's
        `fp_str` sitting where a param's would — which is the
        birthday risk every hash carries and not this defect. The arm
        case was different in kind: two different structures mapped
        to the SAME SEQUENCE with no coincidence needed, because a
        pattern's hash and an expression's hash are the same space.
  - [ ] A NUL AT THE C BOUNDARY DOES NOT LOSE DATA, IT REDIRECTS
        THE OPERATION — and that is a bigger claim than CLAUDE.md's
        NUL law makes. Found 2026-09-07 by the HTTP campaign's
        substrate lane, following this lane's marshalling redirect on
        the io slice. A 79-byte path ending `/../../etc/passwd` with
        a NUL at byte 5 READ A 5-BYTE FILE and answered ok; `exists`
        answered true for nothing; `write_text` created a file under
        a truncated name. Both engines AGREED — which is the class
        eval == native cannot catch, three times over now.
        THE EXISTING LAW IS ABOUT LOSS: five string primitives stop
        at the first NUL, so a five-byte text reads equal to its
        two-byte prefix. This is about TARGET: the same truncation,
        applied to a NAME the C side resolves, does not answer a
        wrong value — it acts on a DIFFERENT OBJECT. That is a
        security property rather than a correctness one.
        THE FIX IS A REFUSAL AT THE BOUNDARY, not a sanitisation:
        six verbs that hand C a path now judge over the BYTES and
        refuse, with the NUL's offset in the words.
        AND IT GENERALISES PAST IO, which is the part this lane
        should carry: with the extern host, ANY package may declare
        `extern fn f(path: string)`, and every one inherits this.
        io fixed its six verbs; the next package will not know. So
        the question is a LANGUAGE one — what does a string crossing
        to C mean when it holds a NUL — and the answers are a refusal
        at the seam for every `string` seat of an extern, a `Bytes`
        seat that carries the length, or a documented hazard. It is
        not io's to decide and it is not settled by io's fix.
  - [x] STATIC METHODS (RULE B) — LANDED 2026-09-07, on the owner's
        direct word in this session. The design below is unchanged by
        the build; what the build ADDED is at the end. Every claim is
        a probe's output, not a reading of the code.
        WHAT IS TRUE TODAY. `self` is IMPLICIT — the impls feature's
        remedy table says so ("`self` is implicit in a method — drop
        it from the parameter list") and `primary = "self" ->
        receiver()` makes it an EXPRESSION, never a parameter. So a
        receiverless fn under an impl COMPILES CLEAN and is a method
        with a receiver it never touches:

            impl Point { fn origin() -> Point { Point { x: 0, y: 0 } } }

        reachable only as `q.origin()` off an instance — useless for
        the constructor that is the whole motivation.
        THE CALL SIDE NEEDS NO NEW SYNTAX, which is the finding that
        resizes the slice. `Type.name(args)` already PARSES; the
        CHECKER refuses it, with a variant-shaped message:

            Point.origin()   F2003 `Point` is a record, not an enum
            K.other()        F2003 `K` has no variant `other`
                                   help: the variants are `a`, `b`

        Both are one resolution step from working. The slice is a
        marker plus a FALL-THROUGH in variant resolution, not a new
        call form.
        THE SPELLING IS `static fn`, AND THE ARGUMENT IS `mut fn`.
        The receiver-disposition marker ALREADY EXISTS in that exact
        grammar slot with TWO values — `fn` reads the receiver, `mut
        fn` writes it (its own stmt rule `mut_fn_decl`; F2046 refuses
        it outside an impl precisely because it speaks ABOUT a
        receiver). `static fn` is that field's THIRD value, not a
        second mechanism for the same fact, and it composes for free:
        a fn with no receiver cannot write one, so `static mut fn` is
        a refusal the compiler SPEAKS rather than a hole. `static` is
        not reserved today (`let static = 1` compiles), so the break
        is real — but F3002 names a word and its status, so it breaks
        loudly with help attached.
        REJECTED, `fn Point.origin()` / `fn Self.origin()`: inside
        `impl Point` the type is already in the header, so the name
        repeats it and invents a disagreement to refuse; under
        `impl<T> Box<T>` the name must spell a generic. And `Self`
        NAMES NO TYPE — F2001, "the types today are `int`, `string`,
        `bool`, and your declared types".
        REJECTED, AND THIS IS THE LOAD-BEARING REJECTION: inferring
        it from the BODY. A fn that never mentions `self` could be
        called static — and then ADDING a `self` read to a body
        silently changes the fn's arity and breaks every call site.
        A BODY EDIT MUST NEVER CHANGE A SIGNATURE.
        TWO THINGS THE SLICE MUST CARRY. First, a LIVE LATENT
        COLLISION — this compiles CLEAN in the tree right now:

            enum K { a, b }
            impl K { fn a() -> int { 7 } }

        A variant and a would-be static share a name with no
        diagnostic. The day `K.a()` resolves, `K.a` and `K.a()` are
        two different things spelled the same and nothing refuses the
        pair. THE SHAPE THIS LANE KEEPS MEETING — a safety property
        resting on a gap that will close — and the refusal belongs AT
        THE DECLARATION, not at the call. Second: a trait-level
        static (`trait Default { static fn default() -> Self }`) is
        BLOCKED on `Self` existing at all, so the slice lands
        INHERENT statics and says so, or it grows `Self` first.
        WHAT THE BUILD ADDED TO THE DESIGN, all three found by
        running rather than reading:
        1. THE PRECEDENCE BELONGS IN `callee.av`, not in either
           consumer. That file's header already promised what the
           slice needed — who answers a dot-call is decided ONCE and
           matched EXHAUSTIVELY by typing and lowering — so
           `Callee.Static` is a variant there and both matches paid
           it at compile time. Deciding it twice (a test in typing, a
           fact-table absence in lowering) was the first draft and it
           would have let the two passes disagree about a call.
        2. THE TRAIT RULE SPELLS ITS OWN MEMBERS, so `static fn` in a
           trait did not PARSE and the law could not reach it — a
           bare "expected `fn`" for the mistake every Rust reader
           makes first. The rule now accepts `( sk:"static" )?` for
           the same reason a `once fn`'s rule accepts a parameter
           list it forbids: so the refusal can SPEAK. Alignment is by
           span window, as `mut` already was.
        3. THE COLLISION CHECK'S FIRST DRAFT WOULD HAVE POISONED THE
           TYPE REGISTRY. It asked `types.intern(Type.Enum(target,
           tname))` for the target's variants — for a RECORD target
           that MINTS A BOGUS ENUM the registry then keeps, since it
           holds the first shape it sees for a key, and every later
           printing of that type carries it. The DECLARATION answers
           the same question with no write:
           `variant_sig_of(decls.sig(target))`. A read that mints is
           not a read.
        AND THE MINT LAW CAUGHT THE LOWERING, unprompted: the first
        `static_dispatch` minted its answer before the operands and
        the corpus program refused with "register r2 defines out of
        mint order". Three F0900s, no debugging, one line to fix.
        AND `make fingerprints` CAUGHT A COLLISION THE SUITE COULD
        NOT: `mark_static` restamped at tag 105, which lane A's
        `fp_list` already owned — 1979 cases green, gate RED. The
        keeper the collision thread produced, catching a collision
        introduced by the lane that retracted about that thread, on
        the keeper's first day, from a lane that did not know it
        existed. A fingerprint conflating two node kinds does not
        FAIL, it answers wrong later; that is why the class was worth
        chasing and why no test would have found this.
        AND THE NEAR-MISS BESIDE IT IS THE PART TO KEEP, because it
        SHARPENS A LAW WHOSE OWN PRESCRIBED CURE FAILED. Choosing the
        replacement tag, `grep -oE "fp\([0-9]+"` answered
        `102 105 108 109` and I reasoned from it that 106 and 107
        were free. THEY ARE NOT — `type_fp` and `Defer` spell theirs
        as `fp(if … { 106 } else { 107 }, …)`, so four of the ten
        taken numbers are INVISIBLE to a grep for literals. I took
        110 by habit (highest plus one), not by judgement; reasoning
        about the gap would have introduced a second collision the
        same night. Lane A independently nearly quoted the shorter
        list.
        THE LAW IT SHARPENS is "A PROBE THAT TRUNCATES ITS OWN OUTPUT
        REPORTS THE ABSENCE OF WHAT IT CUT" (CLAUDE.md), whose cure
        is written as `grep -oE … | sort -u`, which "costs nothing
        and cannot lie by omission, where a `head` always can". IT
        LIED BY OMISSION. Not by truncating — **a grep for literal
        values cannot see a value that is COMPUTED**. So the cure
        holds only for literals, and the general form is: ENUMERATE
        FROM WHAT THE CONSUMER SEES, NOT FROM WHAT THE SOURCE SPELLS.
        The keeper reads the tag space correctly — it found the
        collision — so the honest way to ask "what is free" was to
        ASK THE KEEPER, not to grep the file it guards. The
        instrument was already in the gate and a worse one was used
        to plan against it.
  - [x] A LAW CAN BE PAID IN ONE PASS AND UNPAID IN ANOTHER. LANDED
        2026-09-07; found by the HTTP lane probing a server shape,
        verified here at `234d17c`, and it is a SILENT wrong answer
        of the class this lane spent the night on.

            type S = { app: C, handle: fn(mut C, int) -> int }
            impl S { mut fn turn(by: int) -> int { self.handle(self.app, by) } }

        The call WRITES through `self.app` — probed, the counter
        reaches 5 — and F2050 said "`turn` never writes through
        `self`". WORSE THAN A WRONG WARNING: its help reads "drop
        `mut`: the compiler infers a writing method", and TAKING THE
        HELP MADE `./avra check` PRINT NOTHING AT ALL while the write
        still happened. A diagnostic whose remedy walks the writer
        into the hole it should have named.
        THE SPLIT, which the reporter suspected and did not probe:
        a DECLARED callee's `mut` seat was seen (`bump(self.app, by)`
        warns correctly); a fn-typed FIELD's was not. Typing was never
        blind — `fielded_call` carries `arrow.muts` into
        `mut_seats_law`, and `self.app` is a lawful `mut` place, so
        the seat law rightly said nothing. THE BLINDNESS WAS IN
        `language/receivers.av`, the survey that INFERS whether a
        method writes its receiver: its own `Callee` enum had
        `Row`/`Method`/`Static`/`Contract`/`None` and NO fn-field
        case, so the call fell to `declared_method`, found no method
        of that name, answered `None`, and the write was never
        flowed back. THE MARKS EXISTED — this lane put them on the
        interner key — and this pass never asked for them.
        WHAT IT SHARPENS, and why it is recorded as a law rather than
        a fix: the seat law's own entry says the marks make "a
        declared callee and a fn-typed value ONE RULE and not two".
        TRUE OF TYPING, FALSE OF THE SURVEY, which still wore the
        two-rule shape the entry claims to have retired. **A LAW CAN
        BE PAID IN ONE PASS AND UNPAID IN ANOTHER**, and an entry
        that records the currency reaching the interner reads as
        though it settled everywhere. When a law lands, name the
        passes that consume it, not the seam that carries it.
        THE FIX: `Callee.FnSeats(held: Arrow)` answering ahead of the
        impl table for struct and App receivers, and `feed_marks`,
        `feed`'s twin over MARKS rather than a declaration's seats —
        it MARKS rather than flows, since a fn VALUE names no callee
        to flow into and any fn of that type may fill the field.
        Three adversarial cases, one of them the silent shape.
  - [ ] REVIEWS THIS LANE OWES, recorded because they live in
        messages and messages do not survive a compaction. Each is a
        diff another lane writes in this lane's files, with this
        lane's word already given and its conditions already stated:
        1. THE `Callee` VARIANT + grammar's side (strings lane, one
           slice). Four constraints: BOTH conditions (a grammar type
           with no door of that name still falls through), the test
           asks the DECLARATION'S KIND and never "has an inherent fn"
           (which would be Rule B wearing Rule A's clothes), the
           fall-through byte for byte, and the refusal names the door
           it tried. Rule B — a general type-qualified call, which is
           STATIC METHODS (ROADMAP:10786, recorded not this arc) — is
           the OWNER'S and no relay of an answer is a grant.
        2. `Bytes` (HTTP lane) — DISCHARGED 2026-09-07 on the
           `is_managed` point, and answered from the code and the C
           rather than from the compiler's pointer: `.Str or .Bytes
           -> true`, `KIND_BYTES = 4`, `bytes_box` through
           `sized_box` with the terminator written, and `acc_kind_of`
           filing it as its own `ACC_BYTES` row — the miscounting-
           STATIC lesson applied AT BIRTH rather than after
           `AVRA_MEM_STATS` was caught lying. Every source is a FRESH
           box (`.bytes()`, `avra_fd_taken`, `concat`/`slice`/
           `gathered`, `Bytes.of_list`), and a C body answering
           octets goes through `bytes_owned` or not at all — the
           header law's fourth instance, named as one.
           WHY THE QUESTION WAS WORTH ASKING ANYWAY: an exhaustive
           match tells you a variant is UNANSWERED and cannot tell
           you the answer typed is the right one, and an OR-RUN makes
           the wrong answer a one-word edit. A `Bytes` in the
           unmanaged run compiles clean, passes every test, and leaks
           or double-frees — and `hdr` refuses an untagged pointer,
           so the guard no-ops and a leak reports clean. THE COMPILER
           POINTS AT THE ARM; ONLY THE AUTHOR KNOWS WHICH ARM WAS
           MEANT.
           RESIDUAL, raised as a glance not a blocker: whether
           `Bytes` took a fresh INTERNER KEY. The type registry keeps
           the FIRST shape it sees for a key, so two variants sharing
           one do not fail loudly — they quietly become one type, and
           the symptom is a wrong `name_of` or a seat taking the
           wrong value. That is today's fingerprint-collision class
           in the type registry, and unlike fingerprints and idioms
           it has NO KEEPER and nothing announces what is free.
        3. THE OPAQUE TYPE / Drop design (SQLITE lane) for the
           memory-pass parts. Position already given: the WRAPPER BOX
           route, because the guard is structurally blind at the
           foreign seam — `hdr` refuses an untagged pointer, so
           retain and release no-op on one and a borrowed foreign
           pointer reports clean.
        4. THE INTERPRETER HALF of the uniform-ABI extern host, mine
           to land if the ABI research holds. Their variadic finding
           is verified under their own hand and the refusal belongs
           at the DECLARATION.
  - [ ] S2 CARRIES A SEARCH OF ITS DEPENDENTS — a GATE CONDITION,
        not a courtesy, and the reason is verified rather than
        feared. `mut b = a` ALIASES today, both engines:

            type Db = { raw: int, tag: int }
            fn close(mut d: Db) -> int {
                if d.raw == 0 { return 0 }
                d.raw = 0
                1
            }
            mut a = Db { raw: 7, tag: 0 }
            mut b = a
            close(b)            -> 1
            close(a)            -> 0, and a.raw is 0

        Nulling through `b` nulls `a`. @std/sqlite's `close(mut db)`
        nulls the handle it closed, and that is what closes the
        double-close — so the day `mut` bindings COPY properly,
        `close(b)` nulls b's handle only, `a.raw` still holds the
        pointer `sqlite3_close_v2` already freed, and `close(a)` is a
        DOUBLE FREE in a std package. The driver's own test uses one
        binding and passes on both sides of the fix, so nothing
        fails and nobody is warned. Found by the SQLITE campaign
        BEFORE it fired, which is the first of the day's class caught
        ahead of time rather than after.
        THE LAW, general: A CORRECTNESS FIX THAT CHANGES AN ALIASING
        PROPERTY MUST AUDIT ITS DEPENDENTS, because code that was
        safe BY the bug becomes unsafe by the fix, and its tests keep
        passing — they were written against the behaviour, not the
        law. S2 is not green until that search is done and its
        findings are named.
        S2'S NAMED CHECKLIST, because a general instruction to search
        is weaker than a list (lane D's point, taken). @std/sqlite is
        IN THIS TREE NOW, and it holds TWO sites of one shape — the
        second is mine, found by looking for siblings of the first:

          packages/std-sqlite/src/open.av:358   close(mut db: Db)
          packages/std-sqlite/src/stmt.av:102   finalize(mut s: Stmt)

        Both are guard-then-null — `if x.raw == null { return 0 }`,
        call the C destructor, `x.raw = null` — and both say in their
        own doc comments that the idempotence IS the `mut` seat
        ("closing an already-closed `Db` answers 0 and does nothing,
        which is the whole point of the `mut` seat"; "the handle
        NULLED so it cannot be destroyed again"). Every word of that
        is true only while the write is visible to every holder.
        Make copies copy and `close(a)` after `close(b)` is
        `sqlite3_close_v2` on a freed pointer; `finalize` is the same
        against `sqlite3_finalize`.
        THESE ARE LANDMINES, NOT LATENCIES, and that is why they are
        on the checklist rather than in the register: the other
        instances of the shape expire into a diagnostic or a latent
        bug, and these expire into a double free in a SHIPPING
        package whose own suite cannot catch it, because it uses one
        binding.
        AND EVIDENCE THE SEAT LAW ALREADY PAYS: the unsafe shape is
        this narrow only because `close(db)` on a `let` is F2048, so
        a closable handle cannot be held in an immutable place. That
        arrived today from unrelated work and made a driver safe by a
        route nobody planned.
  - [ ] S2 NEEDS THE OWNER, and the questions are named so the slice
        does not start in the wrong shape. (a) SPEC 11.4 vs 11.5:
        11.4 says v1.0 app-level aliasing is SHARED ("closures can
        mutate shared state, observer patterns work naturally") with
        `let increment = () -> counter += 1` as its own example,
        which the V1 capture law refuses; 11.5 says a `let` is deep
        and the memory doctrine says aliasing is NEVER observable.
        The compiler has already chosen 11.5. Is `Cell<T>` the
        intended reconciliation, or does 11.4 mean the receiver law
        stays a warning at app level? The arc's whole justification
        rests on this. (b) `Cell<T>`'s SURFACE: the spec specifies
        `get`/`set`, but get/set on an AGGREGATE is refused
        alternative (b) — it clones the fact tables per diagnostic.
        In-place forwarding is a deviation from 11.3 and needs the
        owner's word. (c) CACHE vs STATE: 13.3 says `@pure` forbids
        interior-mut writes and `@memo` requires `@pure`, so the memo
        kernel built on `Cell` contradicts the spec as written. A
        cache has a testable definition the kernel already asserts
        (`Db.sweep()`: clearing it leaves every answer unchanged);
        whether that becomes a mark, a second wrapper, or an
        amendment to 13.3 is the owner's.
  - [ ] F2051 MISREADS A FORWARDING SEAT (lane D, 2026-09-05, with
        a reproduction). A fn that PASSES its `mut` seat into another
        `mut` seat is warned "never writes through it", and taking
        the help's advice does not compile — the caller's plain seat
        is then refused by F2048 at the inner call. Passing to a
        marked seat IS writing through the seat; the pass looks for
        DIRECT writes only. The fixpoint already computes flows
        between seats, so the fix is one edge: an argument that fills
        a marked seat marks the seat it came from. No code in the
        tree has the shape (hence the census's zero) because the only
        thing wanting it is a higher-order forwarding verb. LANDS
        WITH S2 — the same fixpoint gains the cell facts there, and
        it is one visit.
  - [x] THE COVERAGE LAW COUNTS ITS OWN DOCTRINE (F2040). LANDED
        2026-09-05 — the lint counted HIDDEN VARIANTS where the
        doctrine counts ANSWERING ARMS, so it fired at 191 SITES
        tree-wide (361 warning lines across a package sweep: a shared
        dependency is counted once per package that checks it) and
        NONE was the defect it names — the audit reached every
        NON-TEST site (the 23 it did not reach are test files, which
        lane D deduped independently and confirmed): every real
        registry was already annotated, and the noise sat in the
        column errors arrive in (lane A: "the F2040/F2047 warnings
        now hide real errors in every build log"). `coverage_checks`
        now counts arms that TEST a variant, an or-run being one, and
        warns only when two or more answer AND the hole hides
        something; the voice says which variants the hole would
        forget. A hole that BINDS gets the other exit named instead,
        since `rest` binds nothing and cannot take that arm's place.
        AMENDS SPEC 8.7, which chose "(b) lint warning when a
        wildcard hides > 2 variants": the threshold becomes TWO OR
        MORE ANSWERING ARMS. Proposed, the owner decides — the
        evidence is the 191-site measurement, and the spec's own
        purpose (the LLM feedback loop: "either add cases or
        acknowledge") is better served by a law that fires only
        where a case is genuinely missing. The `rest` exemption is
        the spec's, unchanged and now load-bearing: 8.7 already
        calls it "the acknowledgement the lint asks for, carried in
        the syntax instead of an annotation", which is exactly what
        THE LICENSE IS A SPELLING means.
        The 15 real registries spell `rest ->`, which the
        language already reads as a deliberate remainder — so THE
        LICENSE IS A SPELLING both the compiler and the ratchet
        read, and all 42 `// LICENSED I22` prose licenses (measured
        dead: the grep flags zero sites tree-wide) kept their reason
        and lost the claim of an approved deviation.
        F2040 is 0 across ALL TWELVE packages (measured both ways:
        main's compiler over main's tree is the 361, the product over
        this one is 0); 1869 cases, 77 programs eval == native. Warning noise left
        for S2: F2047's 96, which the cell ABI retires.
  - [ ] A PRELUDE or qualified expression paths (the 33 files that
        import ten names for a `grammar { }` expansion).

LANE D — THE SWEEP (cheap items for the gaps between builds; owns
CLAUDE.md, the cli entry, this ledger's bs2 section).
  - [x] THE 76 SUBSET NOTES audited (2026-09-04): every note probed
        with `./avra check` (and `run`/`build`, plus a scratch
        package for the module, dependency and `avra test` notes).
        TALLY: 37 ACCEPTED -> deleted; 28 REFUSED -> CLAUDE.md "The
        subset today" with the refusal's exact words (23 gaps, 5
        laws that speak — named in its preface, not listed); 11
        REWORDED -> 2 bs2-toolchain notes deleted, 4 house rules to
        a new "Working discipline" section, the IR bool law to
        Rules, 3 runtime facts kept as ours (`.length` is strlen —
        measured native, 0.91s against 0.44s hoisted at 150k;
        `split` drops a trailing empty; `avra run`'s 400-call
        floor), and the #1377 Style exception retired (ours has no
        #1377: probed with the exact shape). Every accepted probe
        also agrees eval == native (52 programs built; the one
        divergence is the interpreter's documented floor), and
        `corpus/sweep.av` pins the accepted shapes no other corpus
        program witnesses, so a deleted note stays deleted. SUGAR
        CANDIDATES the
        sweep surfaced, for the backlog: a trailing comma in a
        parameter list; struct destructuring in `let`; bindings
        across `or` alternatives; range comprehensions; `type Id =
        int`; `table` under a typed let's row; an empty-block match
        arm; `?` before `.` on a Result; `export const`; a no-arg
        generic call pinned by its want; a lambda's body reading its
        declared answer for bare variants; a `dyn` want reaching
        into arms; variant arms through a nullable; `T` in a generic
        impl's local annotation; the bare component form and
        instantiation as an expression; value `==`/`contains` over
        lists, structs and enums; `List.reverse/sort/find_index`,
        `string.is_empty`, map indexing. FOUND ON THE WAY, not lane
        D's to fix: an ABSOLUTE `path =` in `[dependencies]` is
        joined under the package root (F4007 names `<root>/Users/…`);
        the `mod x` grammar rule (features/modules) is dead weight
        now; I25 RETIRED — the compiler refuses a wrong payload
        count on one-line enums too (F2015), so the ratchet, its
        matcher and the one-variant-per-line house rule are gone;
        `core/tests/lists_test.av`'s `LICENSED I3` ("a bs2
        test unit miscompiles an interpolated comprehension
        element") is stale — ours takes `["${x}" for x in xs]`; and
        lane A's PROBE FIRST is answered: a module-level `let` read
        from a fn body is F3020 (the const law) and `export let` /
        `export const` is F3014, so a once-per-process `avra()` needs
        the memo road, not a top-level binding. Two parse CASCADES
        (one mistake, several messages) for the grammar's owner: an
        empty-parens pattern `.A()` speaks five F0100s, and `s is
        .A(_, _)` speaks an F0100 plus a "body answers `void`".
  - [x] `packages/cli/src/main_stamped.av` and its `exclude` line
        deleted; `.gitignore` forgets it; `make clean` sweeps a
        dropping (the main worktree carries one — `make clean`
        there, or `rm -f`, after the merge).
  - [x] The `mod commands` stub deleted from `cli/src/main.av`: a
        directory IS a module (a scratch package's `use commands.{…}`
        resolved with no stub; the cli checks clean without it).
  - [x] `extern fn println` / `eprintln` replaced by `@std/io` (after
        lane B lands it) — DONE by lane B with the library, 2026-09-05:
        the cli declares neither; externs.av keeps its proof. THE SITES: `cli/src/commands/shared.av`
        declares both (its extern wall, lines 7-18) and nothing else
        in the cli does; `corpus/native/externs.av` declares
        `println` as the PROOF of the host seam, so it keeps an
        extern when the cli stops declaring one. THE CENSUS, for
        lane B's surface (what the cli declares today, every one a
        `@std` row): read_file, file_exists, write_file, mkdir_p,
        list_dir, is_dir, env (`@std/io`); shell_exec_status
        (`@std/process`); now_ns (`@std/time`); process_exit.
  - [x] CLAUDE.md's "Vendored code" paragraph: `spec_test` is gone;
        `std-cli` alone remains, until lane B. README's Toolchain
        section rewritten with it (nobody's file; stale since the
        seed).
  - [x] TECH_DEBT.md DELETED: every bs2 item died on the probes or
        moved below the ledger as OUR debt with its trigger.
  - [x] THE bs2 DEBT LEDGER closed (below): every entry struck or
        handed to its lane; what remains is ours.
  - [x] THE WIDENED SWEEP (2026-09-05, the owner's word: code,
        sugar, architecture): fourteen slices landed through the
        integrator — see THE SWEEP'S FINDINGS below the ledger for
        each (A-E done; of H, the want-pinning, the answer into a
        lambda's body and a comprehension's element, `v.ordinal` and
        `a?.m(args)` landed; or-arm bindings, a `mut` seat in a fn
        type, `rest ->` over the enumerations in core, and the third
        `Callee` copy name lane C or lane A). What waits: `extern fn
        println` on lane B's `@std/io`; the FIELD-seat lambda's
        answer on lane C's rescue path.
  - [x] THE LANGUAGE SLICE (2026-09-05): a comprehension's head is
        the `for` statement's (bare pairs, ranges — `Comp.hi`, a
        counting walk, F2000/F2041 voices for the bounds and the
        index); EVERY comma list takes a trailing comma (nine
        grammar spots, one law); `string.is_empty()` (lowered
        through the shape's measure word; 47 `.length == 0` tests
        rewritten); the `mod x` rule deleted; the bootstrap's pins
        un-pinned (18 typed lets that existed for a dead dialect);
        five counting `while` loops now `for i in 0..n`; `code_at`
        calls read `s.char_code(i)` at 39 sites. THE LEDGER LINE WAS
        FALSE and is corrected 2026-09-05: the shim did not stay for
        `core/text.av` alone — `language/manifest.av` and
        `language/interp.av` were never swept and their `code_at`
        predates the sweep by two days. Six readers, retired together
        with the shim. Spec cases in seven
        feature test files; corpus/comprehensions.av proves the new
        heads native. THREE REVIEWS of the tree (features; grammar +
        core; language + cli) are filed under THE SWEEP'S FINDINGS
        below the ledger — the next slices come from there.

THE CLOUD (probed 2026-09-04): an agent asked for "remote" isolation
from a session on the Mac mini lands on the SAME Mac mini, in a
worktree under `.claude/worktrees/` — same machine, same lock, no
extra compute. A claude.ai cloud session is a Linux container and
IS extra compute: install LLVM 21 and clang there (`apt install
llvm-21 clang-21`), run with `LLVM_PREFIX=/usr/lib/llvm-21`, then
`make bootstrap`; the runtime's address screen (`hdr` refuses
addresses below 0x100000000) holds under PIE, which is what clang
emits by default. First thing in a cloud lane: `make corpus` green,
recorded here with the container's `uname -a`.

LANE SQLITE — THE DRIVER THAT GROWS THE LANGUAGE (opened 2026-09-05;
owns `packages/std-sqlite/` and the FFI surface — the extern grammar in
`features/fns/`, the ownership annotations, `opaque type`, and the
interpreter's extern host; BORROWS `core/` and `runtime/` from lane A,
`language/interp.av` from lane C).

THE MISSION: `@std/sqlite`, the full SQLite surface, test-driven, as the
substrate a later ORM is built on. THE RULE THE OWNER SET: a gap in the
language is not papered over — it is recorded here and CLOSED, and only
then is the driver written past it. The driver is the forcing function;
the language is the deliverable.

THE DECISIONS (owner, 2026-09-05):
  - DIRECT `extern fn sqlite3_*`, no hand-written C shim. A shim is the
    paper, written in C: every call Avra cannot express would hide inside
    it. Where the call cannot be spelled, the LANGUAGE grows (Axis 15).
  - THE AMALGAMATION IS VENDORED, our flags. Apple's libsqlite3 is not
    stock: `OMIT_LOAD_EXTENSION`, `DQS=3` (a typo'd column name becomes a
    string literal), no `sqlite3session.h`, Apple's SEE codec,
    `BUG_COMPATIBLE_20160819`, `THREADSAFE=2` — and it ships 3.51.0 where
    upstream is 3.53.4. A driver whose test results depend on the host's
    sqlite is not a test. One version, every machine (P14).
    TWO RECOMMENDED FLAGS REFUSED, each with a segfault behind it:
    `OMIT_AUTOINIT` (a first call forgetting `sqlite3_initialize()`
    crashes silently, and the WALL cannot call it — dropping to the raw
    surface is a continuation, not an escape) and `MAX_EXPR_DEPTH=0` (a
    LEFT-DEEP chain keeps the parser stack shallow while the Expr tree
    grows; 50 000 terms segfaults in `prepare`, kept at 1000).
  - `float` LANDS — four entry points, and the sharp part is that
    `RtKind` is `{I64, Ptr, Void}` (`core/ir.av:219`), so the wall cannot
    DECLARE a double seat and `rt_kind_of` puts every non-void
    non-pointer in an integer register. `RtKind` grows an `F64` variant:
    a registry COLUMN, not an eight-consumer instruction.
  - `decimal` IS DEFERRED, and it is CORE when it lands (owner: "make it
    part of core. i dont' want an std.numbers" — spec 31.3 superseded).
    Deferred because SQLite HAS NO DECIMAL STORAGE CLASS, so it gates
    zero externs; it lands with the ORM campaign, and costs a literal
    syntax, exact base-10 arithmetic with a DECLARED rounding mode, an
    exactly round-tripping text projection, a total order, and EXPLICIT
    conversions — silent promotion is how every language with both loses
    money.
  - THE INTERPRETER LEARNS TO HOST ANY EXTERN — dlsym plus a fixed set of
    uniform ABI shapes, never libffi (spec 15.3). THE SHAPE TABLE
    COLLAPSES: feared combinatorial (~2000 for N <= 8), it is ONE
    fully-applied prototype plus SIX return kinds, because the register
    files are independent and a callee cannot observe arguments it does
    not declare.
  - LATER, DESIGNED FOR AND NOT BUILT: SQL checked at compile time
    against the schema (P10), `table<Row> { … }` backed by SQLite (P5).

THE CAMPAIGN'S PAPERS, under `docs/` — decisions are recorded HERE:
  - `..._STRING_REPRESENTATION.md` — DECIDED, and every other paper
    stands on it. The string is a POINTER to a headered box, not the
    legacy spec's 24-byte inline value; 9.15's SSO is superseded, because
    a `Bytes` box sharing the representation, `rides_pointer`, and any
    verb handing C a payload address all need a `string` to BE a pointer,
    and an inline short string has no address. THE LAW IT SETTLES: A
    LENGTH IS CARRIED, NEVER MEASURED.
  - `..._STD_SQLITE_VISION.md` (the north star), `..._SYNTHESIS.md` (the
    merged design the driver is built from — three competing drafts were
    judged into it and are in git history, not beside the finished
    paper), `..._RESEARCH_probe_log.md` (GROUND TRUTH, everything RUN),
    `..._STD_SQLITE_TRAPS.md` (all 174 traps indexed, the 15 the package
    cites in full), `..._BYTES_SHAPE.md` + `..._BYTES_RUNTIME_DIFF.md`
    (lane A), `..._EXTERN_HOST_SHAPE.md` (lane C),
    `..._RESEARCH_ptr_from_int.md`.
  - `packages/std-sqlite/src/c/CENSUS.md` — the ABI census, measured
    against the VENDORED header. The only census counting what we link.

*** THE RETURN-WIDTH LAW — A WRONG ANSWER LIVE IN THE TREE, above every
other item in this lane ***
  AN EXTERN OVER A C `int` READS ITS NEGATIVES AS HUGE POSITIVES. Avra's
  `int` is 64 bits, C's is 32; `declare_externs` (`llvm.av:169`) declares
  every I64-answering extern as `i64`, and both compilers materialise a
  narrow result with a 32-bit write (`mov w0, …`) that ZEROES the upper
  half. MEASURED at -O2 through a `[link]` row: C `int` -1 reads
  4294967295, INT_MIN reads 2147483648, `short` -1 reads 4294967295,
  `long` -1 reads -1 (really 64-bit), `unsigned` MAX reads 4294967295
  (correct by luck). IT SHIPS IN BUILT BINARIES, and BOTH ENGINES AGREE
  ON THE WRONG ANSWER, so eval == native does not catch it. AND IT IS
  CALLEE-DEPENDENT: `atoi("-1")` answers -1 (macOS's is
  `(int)strtol(...)`) while a hand-written `int f(void){return -1;}`
  answers 4294967295 — same prototype, opposite answers — so it cannot be
  audited by CALLING things, only caught AT THE DECLARATION.
  OUR HALF IS CLOSED (lane A): all 98 externs whose C body we own
  audited, exactly two narrow, both right only because their values are 0
  and 1; both answer `int64_t` now and `make externs` refuses the class
  statically, proved by restoring one and watching the gate go red. It
  cannot read a third party's headers — 226 of the vendored surface
  answers C `int`. THE FIX IS SPEC'D AND ABSENT: Axis 15.2's `i32`/`i64`
  are F2001 "`i32` names no type" — cheapest of the three asks.

AN ARMED LATENT DEFECT: A NON-ZERO POINTER CONSTANT SILENTLY BECOMES
NULL, in both engines — `const_int_value` (`llvm.av:307`) discards its
value when the destination rides a pointer, `const_int_val`
(`interp.av:190`) is the twin. Sound today only because `ptr` is
RECEIVE-ONLY. WHAT ARMS IT: `SQLITE_TRANSIENT` is `(void*)-1`,
`RTLD_DEFAULT` `(void*)-2`, `MAP_FAILED` `(void*)-1` — a silently-nulled
destructor IS `SQLITE_STATIC`, so the Avra box is freed at scope end and
the next `step` reads freed memory. THE GUARD BELONGS IN LOWERING: the
backend's `Emit` has no failure channel, the interpreter does, and
guarding only the engine that CAN refuse would make the two disagree.
Free today (unreachable), which is why it lands now — it turns a premise
documented in a comment into one enforced. Lane C's file.

THE SENTINEL'S SHAPE: a NAMED MINT lowered inline to `inttoptr` — never a
runtime row (a real call per bind), never a C body (the shim wearing
another hat), and NEVER a general `int -> ptr` at extern seats. That last
is refused on P9: a door accepting anything integer-shaped means
`sqlite3_open_v2("x.db", 5, 6, null)` typechecks, so a transposed
argument becomes a WILD POINTER — strictly worse than a wrong integer,
which merely gives a wrong answer. Nine languages surveyed agree and
sharpen it: every one that revisited this moved toward a NAME and away
from a CAST, the answer is `ptr?` so address 0 IS `null`, and the reverse
direction ships separately or not at all (ptr_from_int paper).

THE GAPS, EACH PROVED BY PROBE (`./avra check`, refusal quoted; an entry
the compiler starts accepting is struck):
  - [ ] NO FLOATING POINT. `let x: float = 1.0` is F0100 "expected
        BREAK", pointing AT the `.` — the lexer has no float literal, so
        the gap starts before the type surface.
  - [ ] NO BYTES. `let b: Bytes = "hi"` is F2001. A `string` already
        HOLDS arbitrary bytes, but `==`, `contains`, `index_of`,
        `replace` and `split` are C string calls, so a blob compares
        EQUAL to its own truncation at the first NUL.
  - [ ] AN EXTERN CANNOT TAKE A `mut` SEAT — the out-param. THREE
        SPELLINGS, kept apart because conflating them mis-sizes the work:
        `fn g(mut p: int)` WORKS TODAY; a `mut` seat in a fn TYPE closed
        on main at `656e650`; `extern fn f(mut p: ptr)` is F0100. THE
        GRAMMAR HALF IS ONE LINE (`features/fns/mod.av:32` lacks `(
        mk:"mut" )?`) AND SIZING IT AS ONE LINE IS THIS CAMPAIGN'S MOST
        LIKELY UNDER-ESTIMATE: the semantic half is the INOUT ABI, which
        the tree names as not-yet-landed (`impls_test.av:130`). NO
        WORKAROUND: a one-element `List<int>` hands C the `AvraArray`
        pointer whose FIRST FIELD IS THE CAPACITY. THE PARADOX WORTH
        COLLAPSING (P6): a C fn answering a STATUS and writing a HANDLE
        through an out-param IS a `Result`, and the compiler projecting
        `(status, mut out T)` to `Result<T, E>` deletes the hand-written
        wrapper the spec's own example concedes — for every C library.
  - [ ] NO OPAQUE TYPES, NO DROP. `opaque type Db` is F0100; a `sqlite3*`
        is a bare `ptr`. THE SHAPE, agreed with lane C: a WRAPPER BOX (a
        headered Avra box whose payload holds the foreign pointer), not a
        new header kind — it keeps the raw pointer out of every managed
        seat and adds one thing rather than changing four.
  - [ ] NO FFI ANNOTATIONS. `-> ptr @free_with(g)` is F0100 at the `@`;
        spec 15.4's whole ownership vocabulary is unspelled.
  - [ ] A FOREIGN `string` IS ACCEPTED, AND RIGHT ONLY BY ACCIDENT.
        PROBED: `extern fn sqlite3_libversion() -> string` answers
        `3.51.0`, because `hdr` refuses an untagged pointer so
        retain/release no-op and `str_len` falls back to `strlen` — right
        only for text that is IMMORTAL and NUL-TERMINATED. AND THE
        INSTRUMENT IS BLIND: `AVRA_RC_GUARD=1` watches retain/release
        EVENTS, which an untagged pointer never raises, so it reads clean
        for a correct borrow and a use-after-free alike. THE BELT HIDES
        THREE WRONGS and the driver is made of all three: text with a
        LIFETIME, BYTES (a blob's length is not `strlen`), and text
        HOLDING A NUL.
  - [ ] NO CALLBACKS ACROSS THE BOUNDARY (spec 15.3's trampolines). But
        14 of the 43 apparent "callback" functions are NOT callbacks —
        they take a two-valued integer sentinel, so they need only a
        mintable `ptr`. The real trampolines are hooks, custom SQL
        functions, collations, the busy handler and the authorizer.
  - [ ] `Result<void, E>` IS REFUSED (F2019) — a driver is full of verbs
        that only succeed or fail, so it shapes the whole API surface and
        lands BEFORE the driver's API is frozen.
  - [ ] A MANIFEST SAYS WHAT TO LINK, NEVER HOW TO BUILD IT. `[link]
        objects` names an object that must ALREADY EXIST; today the root
        `Makefile` builds `llvm_wrapper.o` for `@std/avrac`, so a
        consumer adding `@std/sqlite` gets a manifest pointing at an
        object no step in their build produces. Blocks SHIPPING.

WHAT ALREADY WORKS, PROVED BEFORE ANYTHING WAS BUILT:
  - AVRA CALLS SQLITE TODAY — one `[link]` row and `extern fn
    sqlite3_libversion_number() -> int` prints `3051000`; against the
    vendored object, `vendored 3.53.4 threadsafe=1`. No shim, no compiler
    change, no runtime row.
  - A C NULL READS AS AVRA `null`, by the SPECIFIED layout, not luck:
    `features/values.av:229` picks `Repr.Niche` for anything
    pointer-shaped, so `ptr?` costs what `ptr` costs, and a bare `ptr`
    cannot be compared at all (F2000).
  - BUT A NICHE SPENDS THE NULL POINTER AND CANNOT GET IT BACK.
    `sqlite3_column_blob` answers NULL for SQL NULL, a ZERO-LENGTH BLOB,
    and OUT-OF-MEMORY, so a column read NEVER tests the pointer — it asks
    `sqlite3_column_type` first (MEASURED: `select x''` gives ptr NULL
    with type 4, `null` type 5). AND THE OOM CHECK IS `errcode`
    IMMEDIATELY, which `defer` can break invisibly, since `?`, `fail` and
    a propagating `catch` all run open frames' deferred calls first. THE
    STRONG FORM: the suspect read and its errcode check SHARE A FRAME,
    and NOTHING BETWEEN THEM MAY LEAVE.
  - EMPTY IS NOT ABSENT inside the language, on both engines; the null is
    spent twice only at the C BOUNDARY. Hence: A ROW ANSWERS AN EMPTY BOX
    FOR EMPTY, AND NULL ONLY FOR ABSENT. (CLAUDE.md carries it as AN
    ENCODING SPENDS THE EMPTY VALUE.)
  - A `ptr` RIDES IN A STRUCT FIELD; a `List<T>` CROSSES AN EXTERN SEAT,
    so an argument vector needs no marshalling; a LAMBDA IN AN ARGUMENT
    SEAT works, so `db.tx(() -> { … })` is expressible — there is NO
    trailing-lambda sugar (`tx { 42 }` is F0100). Sugar-backlog shaped.
  - F2031 STANDS: `impl Show for Box<T>` is refused; the design routes
    around it with a trait BOUND on a fn (`fn note_of<C: Cells>(c: C)`).

THE CHECKLIST — the ORDER is the dependency order, and no driver code is
written past an open gap above.
  A LAW ABOVE THE LIST, because it regenerated THREE TIMES from three
  sequencing tables: A SEQUENCING TABLE COUNTS CALLABILITY, AND CALLABLE
  IS NOT CORRECT. Any row reading "the bind_* family costs nothing" is
  arithmetically true and is THE INVERSION below. NO BIND VERB SHIPS
  BEFORE THE MINT AND THE GUARD, and the marking belongs IN the row.
  - [ ] The LOWERING GUARD for a non-zero pointer constant. Lane C's.
  - [ ] SIZED INTEGER TYPES (`i32`/`u32`, in extern signatures at least).
        THE DOCTRINE that makes it cheap: A WIDTH IS A PROPERTY OF A
        SEAT, NOT OF A VALUE — Avra keeps ONE integer, an extern's seat
        names the MACHINE WIDTH its C prototype uses, and the compiler
        narrows at the argument and widens the answer WITH THE SIGN THE
        WIDTH NAMES. So `let x: i32 = 5` staying refused FOLLOWS from the
        doctrine rather than being a scope line to defend. Lane A's.
  - [ ] `float`, with `RtKind`'s `F64` column. Four entry points.
  - [ ] `Bytes`, to `docs/2026_09_05_BYTES_SHAPE.md`.
  - [ ] A `mut` seat on an extern, and the INOUT ABI behind it.
  - [ ] `opaque type T @free_with(f)` as a wrapper box.
  - [ ] The interpreter's extern host, so `corpus/sqlite/` proves eval ==
        native by construction.
  - [ ] `@std/sqlite` itself, to the merged design in the synthesis.

THE CAMPAIGN'S FINDINGS — none is about SQLite; each was found because a
driver forced someone to read a seam nobody had grown before.

  - THE WIDTH NEVER BECOMES A TYPE, and that seam is what made the work
    small: `core/types.av` is UNTOUCHED and there is NO new `Type`
    variant, so not one exhaustive match changed. `widthless` rewrites
    the width word to `int` ON THE EXTERN PATH ONLY and the width is read
    back FROM THE STORE at `extern_row_of`. COROLLARY refused in the HELP
    rather than left to be discovered: `List<i32>` is refused — a seat
    property that leaks into an element type is no longer one.
  - `RtKind` HAD TWO SILENT CONSUMERS — `rt_arg` (llvm.av:432) and
    `answers_word` (:398) tested `is .I64` rather than matching, so a new
    width would have put an Avra `int` in an i32 seat with no truncation,
    compiling clean. Both are exhaustive now and `make vocab` names them.
    STANDING RULE: WIDENING A REGISTRY ENUM WITHOUT NAMING IT IN `make
    vocab` IN THE SAME SLICE IS NOT A LANDING — live candidates `RtHost`
    and `RtSig`'s BOOLEAN COLUMNS, the same hazard with no enum to hang
    it on. (CLAUDE.md carries the law.)
  - `avra_llvm_cast_to_type` IS THE WIDTH DEFECT'S SECOND HOME: its
    int->int arm is `LLVMBuildZExt` UNCONDITIONALLY on widening
    (llvm_wrapper.c:617), and :623 BITCASTS double<->i64, which is right
    for reinterpreting bits and WRONG for a numeric conversion. Adding a
    correct sibling and leaving the trap is not the fix — a helper that
    silently zero-extends is a trap with a friendly name. The primitive
    the sentinel needs is already at :614 (`LLVMBuildIntToPtr`).
  - VENDORING MAKES THE KEEPER COVER A THIRD PARTY: `make externs` cannot
    read a third party's HEADERS, but a vendored amalgamation is a C
    SOURCE IN THE TREE. Made manifest-driven it refused the driver's
    merge — 53 of 84 declarations answered a narrow C `int` and were
    declared `int` — plus 8 FALSE POSITIVES, its width set having only
    met C WE wrote. `__int64` was missing from that set and NOTHING IN
    THIS TREE SPELLS IT; only the MSVC branch of a vendored typedef
    surfaced it.
  - TWO CORRECT RULES CAN COMPOSE INTO A WRONG ANSWER, and neither is the
    one to weaken. "An all-caps return-type word is noise" and "a typedef
    keeps every definition across branches, disagreement fails" are both
    right; composed they meet `typedef SQLITE_INT64_TYPE sqlite_int64`
    (sqlite3.c:615), an all-caps body stripping to the EMPTY STRING —
    nothing is never wide, so a right declaration is refused. THE FIX
    SHARPENS: a branch that strips to nothing MUST NOT VOTE. AND AN
    ABSTENTION KEYED ON EMPTINESS MISSES THE DECORATED CASE — `unsigned
    SQLITE_INT64_TYPE` strips to a BARE `unsigned`, votes, and reads
    32-BIT. WHEN A FIX IS "IGNORE THE EMPTY CASE", ASK WHAT THE HALF-
    EMPTY CASE DOES.
  - THE CENSUS, FINAL AND RECONCILED (`packages/std-sqlite/src/c/
    CENSUS.md`; header preprocessed with the package's flags,
    cross-checked against `nm build/sqlite3.o`):
        362 DECLARED / 357 EXPORTED / 5 DECLARED-BUT-ABSENT
        exclusive, summing to 362: 234 (a) plain, 59 (d) out-param,
        56 (c) fn pointer, 8 (e) variadic, 5 (b) double
        touching: 226 (g) narrow C `int`, 14 (f) pointer sentinel
        SEQUENCING: nothing new 234 -> OUT-PARAMS 286 -> [STATIC 300,
        BLOCKED — see THE INVERSION] -> float 305 -> trampolines 354.
        **OUT-PARAMETERS ARE THE ONLY THING ON THE CRITICAL PATH.**
    THREE NUMBERS, NOT TWO: 365 is what the API IS, 362 what a
    DECLARATION CAN NAME under our flags, 357 what it CAN LINK — A
    BINDING IS BOUNDED BY THE SMALLEST. Apple's header parses to 284
    under the same script, so the old figures were never wrong; the gap
    is the vendoring decision. A COUNT EARNS BELIEF BY REPRODUCING THE
    NUMBER IT REPLACES, NEVER BY BEING NEWER — "153 of 284" versus "226"
    is two headers, not a correction, and what was wrong is that four
    lanes repeated a figure for hours without asking WHICH HEADER IT
    COUNTED. `nm` against the object linked settles it in a minute.
  - AND `avra check` ACCEPTS A DECLARATION FOR A SYMBOL THAT DOES NOT
    EXIST, with no signal — shown by declaring one of the five absent
    entry points and watching the LINKER answer `Undefined symbols`.
    That is the honest scope of `check` over a wall: it proves the
    declaration parses and types, never that anything answers it.
  - THE VARIADIC ESCAPE ROUTE IS REFUSED, not merely discouraged — the
    api_surface report offered "bind one narrow extern per argument
    shape" and it reached a shipped design. MEASURED across two
    translation units: the fixed prototype answers -298729216 where the
    variadic answers 12345, silently, on `sqlite3_db_config`. AND A
    CROSS-BOUNDARY PROBE THAT SHARES A TRANSLATION UNIT IS NOT TESTING
    THE BOUNDARY: an earlier form AGREED, clang having resolved the
    aliased declaration to the variadic.
  - THE INVERSION: THE DANGEROUS BIND IS FREE TO WRITE AND THE SAFE ONE
    CANNOT BE WRITTEN. `SQLITE_STATIC` IS the null pointer, spellable
    today; `SQLITE_TRANSIENT`, which COPIES and is the safe default, is
    `(void*)-1` and UNSPELLABLE — and under STATIC the header (:4946)
    requires the object stay valid until finalize, so a box released
    before `step` is a USE-AFTER-FREE INSIDE SQLITE. RATIFIED: the mint
    and the guard are PREREQUISITES OF BINDING A SINGLE VALUE, and the
    driver offers NO BIND VERB AT ALL until they land — A HAZARD
    DOCUMENTED AT A VERB THE CALLER CAN REACH IS A HAZARD SHIPPED.
  - THE 59 OUT-PARAMETERS ARE FIVE DIFFERENT LANDING PROBLEMS: 26 handle
    `T**` (the `opaque type` candidates), 22 scalar `int*`/`i64*` (which
    must write AT THE C WIDTH), 9 borrowed `const char**` (a LIFETIME),
    17 OWNED `char**` (a DROP OBLIGATION), 6 op-typed `void*` no
    declaration can type — a `mut` seat is one mechanism, these are five
    contracts. SO THEY ARE DOWNSTREAM OF THE WIDTHS: `wal_checkpoint_v2`
    writes 4 bytes into an 8-byte cell, answering -1 as int32 and
    4294967295 as int64. AND THE 22 ARE REALLY 19 — RECORDED AS LUCK:
    three write through `sqlite3_int64*` and are exact at ANY width, and
    all three first-slice reachers are in the OTHER 19, so a width-less
    seat FAILS ON THE FIRST THING THE DRIVER DOES rather than SHIPPING
    BEHIND THREE GREEN TESTS.
  - THE FLAG TEST, RATIFIED (census §19.1): settle a capability at
    compile time only when it is VARIADIC-ONLY **AND INVISIBLE AT THE
    DRIVER'S OWN DOOR**; visible at the door means refuse at the door — A
    COMPILE FLAG HAS NO CALLER AND CANNOT CHANGE ITS MIND; A DOOR CAN
    REFUSE PER-VERB AND SAY WHY. Its whole output: `USE_URI` COMES OUT
    (measured, the `file:` prefix was stripped even with no `OPEN_URI`
    flag, and the only way off is one of the eight variadics — A COMPILE
    FLAG WHOSE ESCAPE HATCH IS VARIADIC IS PERMANENT); `DEFAULT_DEFENSIVE`
    REFUSED, two of its three protections being SILENT NO-OPS
    (`journal_mode=OFF` reads back `delete`, `schema_version=99` reads
    back `1`, both rc=0) — A WRONG ANSWER WEARING A SAFETY LABEL; and
    ATTACH IS A CAPABILITY WE CANNOT REMOVE, so it is a CONTRACT —
    measured, `ATTACH` then `CREATE TABLE side.made(x)` both succeed, so
    A PROGRAM THAT HANDS @std/sqlite ARBITRARY SQL HAS HANDED IT THE
    FILESYSTEM, declared in the README as a property (P9) with
    `sqlite3_set_authorizer` (not a text scan) as the door — a
    REQUIREMENT on the trampoline rung. AND A RULING THAT REFUSES A CLASS
    MUST BE AUDITED FOR WHAT THE CLASS WAS THE ONLY DOOR TO, answered by
    MEASURING our own object rather than reading `#define`s.
  - ASSERT THE ABSENCE. When a capability is REMOVED by decision, the
    removal gets a TEST — `USE_URI` moved from `promised()` to
    `forbidden()`, so re-adding it fails the suite. ITS TWIN: A FIXTURE
    GENERATED FROM ITS SOURCE CANNOT DRIFT FROM IT — the error test
    enumerates all 82 extended result codes the VENDORED header declares,
    generated from it rather than typed from the docs. One makes a
    REMOVAL fail if undone, the other an ADDITION fail if unnoticed.
  - `SQLITE_LOCKED` IS NOT RETRYABLE, AND THE DESIGN SAID IT WAS — a
    defect whose failure mode is A HANG. `SQLITE_BUSY` means ANOTHER
    connection holds the lock; `SQLITE_LOCKED` means THE SAME one does,
    so a retry loop waits for a lock it is itself holding, forever. The
    existence of an entire `unlock_notify` API is the evidence. DEPARTED
    FROM THE DESIGN, pinned by two cases: A DESIGN DOCUMENT IS EVIDENCE,
    NOT AUTHORITY — its own research (T49) contradicted it.
  - A GUARD AND THE THING IT GUARDS MUST READ THE SAME BYTES — found by
    a red team, the campaign's own NUL law arriving through the door
    built to stop it. `path_fault` refused the empty path with **the
    pre-`f57372a` `==`**, then a C string call stopping at the first NUL,
    so `"\0x"` (length 2 in Avra) passed and reached SQLite as THE EMPTY
    STRING — the private temporary database DELETED AT CLOSE, every write
    succeeding and the data gone. Fixed with `has_nul` over `char_code`.
    AND THE NEAR-MISS IS THE SHARPER HALF: `":memory:\0x"` WAS refused
    before the fix, ACCIDENTALLY, because **that same pre-`f57372a` `==`**
    truncated it into a match — a test asserting the right answer would
    have locked the wrong reason in.
    THE MECHANISM IS HISTORY AND THE LAW IS NOT. `f57372a` moved all five
    primitives onto the header's length, so nothing on the Avra side
    truncates now and that accident is no longer reachable. **The law is
    untouched, because the truncation was only ever on ONE side**: the
    callee still sees different bytes than the guard did, at the EXTERN
    SEAT and only there. The version is named in both clauses on
    purpose — a reader with no dates cannot otherwise tell a live
    mechanism from a dead one, and four documents inherited this
    sentence before anyone noticed.
  - A CLOSED REGISTRY SURFACES DESIGN GAPS THAT PROSE REVIEW MISSED — the
    catch-all doctrine read FORWARDS. The driver's `Cause` enum has no
    `_ ->`, so a refusal the design promised but never picked up has
    NOWHERE TO BE SPOKEN and the compiler says so. The tree's law says a
    catch-all forgets the NEXT variant; this says the ABSENCE of one
    makes an unimplemented decision fail to COMPILE rather than to HAPPEN.
  - AN EXPORTED GENERIC FN THAT NOTHING INSTANTIATES IS NEVER LOWERED:
    `declared()` filters through `lowers_plain`, which requires
    `tparams(d).is_empty()`, so a GENERIC body is excluded in a library
    AND a program. The design's spine is `fn note_of<C: Cells>(c: C)`, so
    the driver's central abstraction is in the one shape `check` does not
    lower. (REPLACES a wrong entry — "a library's uncalled exports are
    unchecked" — false at `lower.av:134`, where `union` seeds from every
    declared body exactly when `entry == null`.)
  - THREE DRIVER-INTERNAL RULINGS LIVE IN THE SYNTHESIS, not here: the
    `;` splitter is a CANDIDATE GENERATOR WITH THE PARSER AS JUDGE (the
    rule was never "no scanning", it was "no scan may be the JUDGE");
    SKIP OR REFUSE SPLITS BY VERB (a script skips a comment-only
    statement, a single-statement verb refuses it); and enumerating
    `OpenConfig`'s 64 combinations produced only 48 DISTINCT flag words,
    so `Mode` became THE THREE LAWFUL COMBINATIONS AND A FOURTH CANNOT BE
    SPELLED — illegal states found by counting rather than by reasoning.
  - CORRECT BY SPECIFICATION IS NOT CORRECT BY LUCK. This lane ruled that
    `sqlite3_complete` must wait for `i32` because a narrow C return
    declared `int` is "correct by luck". WRONG: the header STATES the
    range is 1, 0, or SQLITE_NOMEM — all NON-NEGATIVE — so the widening
    is exact for every value it can produce. LUCK is "the values so far
    have fitted"; SPECIFICATION is "the range cannot leave the safe set".
    A refusal that catches safe code teaches people to route around it.
  - FIX C WHERE IT IS WRONG; INHERIT IT WHERE IT IS ONLY ARBITRARY — the
    sharpest statement of what LLM-FIRST means for a language decision.
    `flags & MASK == 0` parses in C as `flags & (MASK == 0)`, almost
    never what anyone wrote: C is WRONG, so Avra binds the band TIGHTER
    than comparison. `1 << BASE + i` parses as `1 << (BASE + i)`: C is
    only ARBITRARY, and every model writing that line learned C's
    reading, so Avra inherits it. THE TEAM LEAD RECOMMENDED DIVERGING ON
    THE SECOND, from what a human reader naively expects, and was
    overruled — the input is not what a reader expects but WHAT A MODEL
    WAS TRAINED ON.
  - ADDING A CONSTRUCT IS NOT USING ONE. CLAUDE.md's save-the-standing-
    binary procedure is for a lane that adds a construct AND USES IT in
    the compiler's own source; the bitwise slice is not that case, since
    the runtime-row design makes shifts CALLS and the lexer rows, grammar
    fragment and node variants are all DATA. THE CHECK rather than the
    assumption: grep the finished diff for a bare `<<` outside a string
    and a gram fragment; empty means the procedure was never needed.
  A CITATION IS A COPY THAT DOES NOT KNOW IT IS ONE — lane B's, and the
  reason two thorough file-keyed sweeps both missed the same claim. A
  citation names the FINDING rather than the MECHANISM, so **it survives
  the mechanism changing**, and it reads as independent corroboration
  when it is one fact copied. The NUL claim lived in FOUR documents
  across THREE campaigns — this ledger's red-team entry, CLAUDE.md's
  subset note, the documentation vision (attributing the finding back to
  this campaign), and the doc probe log. **Four documents agreeing looked
  like four confirmations and was one claim four times.**
  AND IT DEFEATS A FILE-KEYED SWEEP BY CONSTRUCTION. Two sweeps ran here
  — four sites, then five more — both thorough, both scoped to
  `@std/sqlite`, and neither could ever reach a ROADMAP entry or another
  campaign's paper. Lane B's own sweep was scoped to CLAUDE.md and missed
  all four for the same reason. **SWEEP BY THE CLAIM, and grep for the
  DISTINCTIVE EXAMPLE that carries it** — here `ab\0cd` and `"\0x"` —
  because the example travels into citations where the mechanism's words
  do not.
  AND NAME THE VERSION IN THE SENTENCE, which costs four words: "the
  pre-`f57372a` `==`". A mechanism clause written in the present tense
  reads as CURRENT BEHAVIOUR to a reader with no dates, so an accurate
  history becomes a false claim the day the mechanism moves — without
  anyone editing it. The entry keeps its incident and its near-miss,
  both real; only the tense was doing the lying.
  THE LAW ITSELF SURVIVED ALL OF IT UNTOUCHED, which is the test of
  whether a retraction was done right: the truncation was only ever on
  ONE side, so the callee still sees different bytes than the guard did,
  at the extern seat and only there. **A retraction that has to weaken
  the law is a retraction of the law; this one replaced only the
  reason.**
  A TEST MOVES DOWN A LAYER RATHER THAN INTO THE BIN — THIRD FIRING, and
  the third is the one that makes it a law rather than a habit, because
  the test could not simply be REWRITTEN: it had to change PROCESS. When
  the extern seam began trapping on an interior NUL at a bare `const
  char*` seat, two adversarial cases documenting the WALL's truncation
  (`wall_completes("select 1;\0 select")`, and `sqlite3_stricmp` on text
  and its own prefix) **stopped being expressible in a suite at all** —
  a trap ends the process, so the assertion cannot be made where
  assertions live. They became a `traps.sh` row demanding the trap's
  exact words.
  THE C BEHAVIOUR THEY DOCUMENTED IS UNCHANGED AND STILL TRUE. What
  changed is which layer can WITNESS it: the face refuses (a `Result` a
  caller catches), the seam traps (a verdict, exit 2), and the wall's
  truncation is now visible only from a harness that expects a process to
  die. **Ask whether the old assertion is FALSE or merely in the wrong
  PLACE** — here it was in the wrong place twice over, first the wrong
  layer and then the wrong kind of harness.
  AND THE LAW IT PROVES IS THE LAYERING ONE: with the seam trapping
  beneath them, "a library refuses before the language traps" became
  literally true rather than aspirational — the trap is the FLOOR under
  the driver's guards, so a trap firing inside `@std/sqlite` is now a
  bug in the guards by construction rather than by agreement.
  A LIBRARY REFUSES BEFORE THE LANGUAGE TRAPS — the layering rule this
  campaign owes the NUL crossing, earned when the language began trapping
  on an interior NUL at a `string` extern seat. The driver already
  refused at three of those seats with a NAMED CAUSE (`path_holds_a_nul`,
  `script_holds_a_nul`, `Cause.HoldsNul` — *"reads only the bytes before
  it, so the answer would be about a prefix"*), and the language's trap
  is a WRECK. **For a caller who typed a bad path, a refusal they can
  catch is strictly better than a trap they cannot**, and the DRIVER is
  the layer that knows WHY the seat resolves. So: the seam is the FLOOR
  for every package that has not thought about it; a package that HAS
  thought converts the wreck into a diagnosis; **neither makes the other
  redundant, and the trap firing inside a guarded package is a bug in the
  GUARDS.**
  AND THE EXCEPTION IS GREPPABLE RATHER THAN AN INTENTION, which is the
  better form of the same rule. The crossing check's exception was first
  written as *"a package that MEANS octets takes `Bytes`"* — an
  intention, which every author will read in their own favour. The
  mechanical test is **"a seat whose C PROTOTYPE CARRIES ITS OWN LENGTH"**:
  the callee resolves nothing when it is told how many bytes to read, so
  a NUL is data. Inside one package that splits 4 / 7 and the split is
  not a judgement call —
      LENGTH-CARRYING   bind_text, bind_blob, keyword_check, prepare_v3
      RESOLVING         open_v2, complete, bind_parameter_index,
                        db_readonly, db_filename, txn_state,
                        compileoption_used
  `sqlite3_complete` is the clean demonstration: **no length at all**, so
  C measures it with `strlen` and a NUL genuinely makes the answer about
  a prefix. A DESIGN RULE STATED AS AN INTENTION IS ARGUED AT EVERY SITE;
  STATED AS A PROPERTY OF THE PROTOTYPE IT IS CHECKED ONCE.
  AND THE MEASUREMENT BEHIND THE EXCEPTION IS THIS CAMPAIGN'S: a SQLite
  TEXT value is a BYTE STRING WITH A TERMINATOR APPENDED, not a C string
  — `bind_text("ab\0cd", 5)` reads back `column_bytes` 5 and `strlen` 2.
  The exception is therefore what the LIBRARY DOES rather than a
  concession to a test.
  A KEEPER THAT INTERROGATES THE ARTIFACT CAUGHT A BUILD REFACTOR THAT
  NOTHING ELSE DID (HTTP lane, `1be60fd`, reported to this campaign).
  Splitting the compiler's object list from the packages' — so `make
  avra` no longer compiles the amalgamation, 9.2 s off every cold build —
  **silently took `CFLAGS_sqlite3` with the moved block**, and
  `build/sqlite3.o` rebuilt WITHOUT its author's flags. **Nothing in the
  build noticed**: the object compiled, linked and ran, and every
  behavioural test passed, because the flags it lost were the ones that
  disable features rather than the ones that produce code.
  WHAT CAUGHT IT WAS `@std/sqlite`'s `compiled_with(option)` — a test
  that asks the LIBRARY which options it was built with, through
  `sqlite3_compileoption_get`, rather than reading the Makefile that was
  supposed to set them. **THE ARTIFACT IS THE ONLY HONEST WITNESS TO ITS
  OWN BUILD**: a build file states an INTENTION, and the gap between the
  intention and the object is exactly where a refactor lands. Same
  instinct as a stems keeper reading `nm` of the binary rather than the
  link line, and the same shape as ASSERT THE ABSENCE — the flags removed
  by decision (`USE_URI`) already had a test that fails if they return,
  and this is its twin: the flags ADDED by decision have a test that
  fails if they leave.
  AND IT IS A RECEIPT FOR A TEST WRITTEN MONTHS BEFORE ITS FAILURE MODE
  EXISTED. Nobody wrote `compiled_with` anticipating a Makefile
  reorganisation by another lane; it was written because a vendored
  library's build flags are a CONTRACT and a contract wants a witness.
  The general form: A TEST THAT READS THE ARTIFACT RATHER THAN THE
  RECIPE PAYS OFF AT A DISTANCE, in changes its author never imagined,
  and that is what makes it worth the awkwardness of asking a library
  about itself.
  THE COUNTING RULE, WORKED — four `is`-chains over `Type`, and they do
  not all go the same way. The law says count the ANSWERING ARMS and no
  grep separates a registry from a projection; these are the first hard
  cases anyone has written down.
    `comparable` — 4 shapes answer true. REGISTRY, converted.
    the interpolation law — 5 answer printable. REGISTRY, converted,
      extracted as a named `printable(sh)` whose doc says why it is a
      match and not a chain.
    `wears(sh, want) || sh is .Error` — ONE arm answers. The `is` asks
      whether a shape is THE ABSORBER, and a new type is never the
      absorber. **PROJECTION: `is` is the right idiom and a match would
      be ceremony.**
    `sh is .Opt` / `sh is .Str` in lowering — strictly THREE behaviours,
      therefore a registry — AND THE CATCH-ALL IS HONEST, which is the
      case the law did not have. Lowering there is deliberately
      TYPE-AGNOSTIC: it emits `Bin` and the BACKEND picks the instruction
      from the operand type, which is exactly why float needed no edit at
      that site. **The hazard is one level down** — a future value
      category needing a different lowering SHAPE (as `Str` does) would
      silently get `Bin`. Left, flagged, and reported as reasoning rather
      than as a patch, because converting it refactors the lowering
      dispatch: a slice, not a line.
  So HALF of a reflexive sweep would have been churn dressed as rigour,
  and the difference is visible only by counting.
  **AND A CONVERTED REGISTRY THAT CANNOT BREAK IS THEATRE.** The
  conversions were FIRE-TESTED: a throwaway `Probe` variant added to
  `Type`, rebuilt, and both converted sites now appear in the break list
  **where they were silent before**; probe reverted, tree clean. That is
  the untested-instrument law turned on one's own fix, unprompted — and
  it is the step that separates "I made it exhaustive" from "I watched it
  refuse".
  AND A KEEPER'S ORDER CARRIES ATTRIBUTION. `make gate` now runs `traps`
  AFTER `tested` (lane A, `34faa19`), because a trap row may now depend on
  a PACKAGE: under the old order a broken `@std/sqlite` failed the TRAP
  KEEPER first — "tx_hot_journal did not COMPILE" — **naming the harness
  for the driver's defect.** The suites run first so a package's own cases
  fail before anything of the keeper's does. Attribution over a
  two-second head start, and the same shape as the three cascades that
  misdirected three authors in one evening: an error naming an innocent
  artifact.
  FLOAT'S FINDINGS, NONE OF WHICH ARE FLOAT (built 2026-09-06; 13 files
  and 30 arms for `Type.Float`, 4 for `Expr.FloatLit`, 5 for
  `RtKind.F64` — the compiler enumerated every one).
  **A WITNESS COMPARES BITS, NOT TEXT.** The float witness FAILED first
  time: C's `%g` printed `11` where Avra printed `11.0`. **The values
  were identical and the FORMATTERS differed.** Comparing rendered text
  tests the formatter; comparing bit patterns tests the BOUNDARY, and the
  boundary is what a witness is for — a witness that renders is measuring
  the wrong artifact and will go red for a reason that has nothing to do
  with the seam it guards. It covers a double ANSWER, a double ARGUMENT,
  and a MIXED call (`int64_t, double, int64_t, double`), because the
  classic way a wrong register file shows up is when the two files fill
  independently.
  **A TABLE THAT ONLY EVER HELD ONE KIND OF ROW WAS NEVER TESTED AGAINST
  A SECOND** — `RtKind`'s lesson one level over, in a table its own
  author wrote weeks earlier. `widthless` mapped EVERY width word to
  `"int"`: correct while every width was an integer, wrong the instant
  `f64` existed, so an `f64` seat resolved to `int` and refused a
  `float`. **Found by the WITNESS FAILING TO BUILD, not by any test.** It
  carries a `carries` column now. The generalisation is the point: the
  untested-instrument law is usually read about KEEPERS, and it applies
  identically to any TABLE, REGISTRY or ROSTER whose rows have only ever
  been one shape.
  AND THE `is .Variant` SHAPE IN THE WILD, failing CLOSED. Two laws did
  NOT break at compile time — `comparable` (`sh is .Int || sh is .Bool ||
  sh is .Str`) and the interpolation-hole law — because they enumerate
  scalars with `is` tests rather than an exhaustive match, so a new
  `Type` variant is invisible to them. Float was REFUSED rather than
  silently accepted, which is the safe direction, but they had to be
  found by RUNNING. **`make vocab` does not cover `Type`** — the second
  enum in one day whose consumers turned out to be only partly guarded.
  AND A FIXTURE WHOSE PREMISE A SLICE DELETES. Two pre-existing tests
  used `float` as their example of *a name that names no type*
  (`fns_test.av:163`, `type_expr_test.av:37`). Landing float made both
  false — not wrong when written, and not detectable by reading either
  one. Moved to `decimal`, which will itself need moving the day decimal
  lands: **visible debt rather than silent**, which is the right kind.
  THE KEEPER PAID OFF: all five `RtKind` consumers broke on `.F64`
  (`ll_rt_kind`, `rt_arg`, `answers_word`, `answered`, `narrow_sign`). A
  keeper exercised once and hardened once has now been tested twice and
  held. AND THE AUTHOR NEARLY REPORTED THE OPPOSITE — a first grep for
  `"must handle .F64"` answered zero, where the real text is ``must
  handle `.F64` ``: one wildcard where two characters stood. **THE FOURTH
  TIME IN ONE EVENING THAT THE PROBE WAS THE FAULT AND NOT THE
  COMPILER**, across three authors, and every time the truncated or
  mismatched view was COHERENT.
  A FENCE BUILT BEFORE THE THING THAT WOULD CLIMB IT — and the honest
  artifact for one is a TRACE, not a test. `str_len`'s zero-length fix
  (`44c36f1`) changes behaviour in exactly one situation: a headered box
  with `len == 0`. Asked to verify it by making it matter rather than by
  re-running the gate, the checker found **the distinguishing case is NOT
  CONSTRUCTIBLE TODAY**, and traced every path that could produce one:
  `box_alloc` never yields zero (`bytes = size > 0 ? size : 1`, and the
  len IS the allocation size); a zero length comes only from
  `sized_box(0, kind)`, which allocates n+1 and stores n; and **all eight
  of its callers write the terminator** (`str_static` memcpy's n+1,
  `str_owned` writes `buf[n]`, `read_whole` writes `buf[got]`, `int_text`
  via `snprintf`). So every box that can reach the changed branch has
  `buf[0] == '\0'` and both mechanisms answer 0.
  **THE FIX IS CORRECT AND ITS CORRECTNESS IS UNOBSERVABLE**, and the
  reason is the same convention the fix RETIRES: every sized box is
  minted at n+1 with the terminator written. The fix removes the
  DEPENDENCE on that convention without removing the convention — which
  is exactly why nothing changes today and exactly why it is right
  anyway. Adoption through `str_owned` keeps the convention; a `Bytes`
  box allocated at exactly n would not, and **on that day the branch
  becomes reachable and the old code would have been wrong.**
  THIS IS THE INVERSE OF THE UNTESTED-INSTRUMENT LAW, AND THE QUESTION
  THAT SORTS THEM IS: **CAN THE TRIGGERING CASE BE CONSTRUCTED FROM THE
  LANGUAGE TODAY?** YES -> untested instrument; the check has been
  passing on arrangements that happened to work, so MAKE IT FAIL, and a
  trace is a rationalisation because the case exists and you did not try
  it. NO -> fence built early; no test can distinguish the fix from its
  absence, so the TRACE is the verification and a green test is theatre.
  AND IT IS A QUESTION RATHER THAN A PAIR OF DESCRIPTIONS BECAUSE THE
  ANSWER MOVES. The same artifact sits under the second law now and the
  first law the day a box can be allocated at exactly n — **and nothing
  about the artifact changes when it crosses.** What changes is the tree
  around it. So the owed deadline is not bookkeeping: A TRACE IS A CLAIM
  ABOUT THE WHOLE TREE AT ONE MOMENT, A TEST IS A CLAIM ABOUT ONE BRANCH
  AT EVERY MOMENT — without the deadline the fix stays verified-by-trace
  forever, in a tree where the trace stopped being true. ASK WHETHER THE
  CASE CAN BE CONSTRUCTED, AND RECORD WHEN THE ANSWER WILL CHANGE.
  AND THE RISK WAS CLEARED IN THE BREAKING DIRECTION, which is the half
  that makes the trace trustworthy: a "trust the header" change breaks by
  reading 0 for a headered box that HOLDS CONTENT while claiming zero
  length — a silent truncation to empty, where `strlen` used to rescue
  it. No such box exists, by the same trace. Checked rather than assumed,
  and checked in the direction that would have hurt.
  THE LIVE PROBES, adjacent and not nothing: nine ways the tree makes an
  empty string all answer 0, an empty arriving from OUTSIDE through
  `str_static` answers 0, the four string-answering externs still fall
  back through `hdr()` -> NULL -> `strlen` (6, 12, 33, 19, by hand), and
  the NUL asymmetry is unchanged.
  AND THE DEADLINE DID NOT ARM — THE MECHANISM IS THE RECEIPT. `Bytes`
  was named, hours after the fence entry, as the thing that would make
  `str_len`'s traced branch reachable: a box allocated at exactly n,
  header authoritative. The HTTP lane built it and **IT DOES NOT ARM**,
  for a reason neither predictor had: the box is still minted at n+1
  through `sized_box`, its length comes from its OWN accessor reading the
  header with no fallback, and NO TYPED PATH HANDS A `Bytes` TO
  `str_len`. Two people reasoned from the ALLOCATION and the answer lay
  in the TYPED PATHS.
  **AND THEY ARMED IT DELIBERATELY ANYWAY**, which is better than either
  outcome: a witness through the one door that reaches it (`extern fn
  avra_str_len(b: Bytes)`). The fixed branch now has a test that does not
  depend on anyone remembering a deadline — the deadline's whole purpose,
  discharged by someone who READ the entry rather than by the breakage
  arriving.
  AND THE FIRST DRAFT OF THAT WITNESS PUT 0xFF IN THE SPARE BYTE, "so a
  `Bytes` is never accidentally a C string" — OVERRULED BY LANE A, and
  the reason is a law rather than a preference. **A POISON BYTE DOES NOT
  BUY A DETERMINISTIC FAILURE, IT BUYS AN OUT-OF-BOUNDS READ**: `strlen`
  walks past the end of the allocation until it finds a zero in unrelated
  heap, so it can crash, or answer garbage, or answer n+1 because the
  next byte happened to be zero. Undefined — and this campaign had ruled
  hours earlier that a stable measurement of undefined behaviour is still
  undefined behaviour. In a server parsing bytes off a network a
  truncation is a bug and **A HEAP OVER-READ ON ATTACKER-INFLUENCED DATA
  IS A VULNERABILITY CLASS**. THE TWO-HATS LAW ASKS FOR THE
  REINTERPRETATION TO BE MADE IMPOSSIBLE, NOT DANGEROUS — **a poison byte
  is an escape wearing a fence's clothes.** The spare byte is a NUL and
  the witness says what it proves.
  AND THE TEAM LEAD RELAYED THE POISON BYTE AS A VIRTUE — into this
  ledger and to the owner — an hour AFTER it was overruled and accepted,
  from a snapshot taken before the ruling. THE CACHED-REF LAW ONE
  SUBSTRATE OVER: a fact that was true when it was read, repeated as a
  fact that is true. A relay carries the READING's timestamp, never the
  tree's.
  THE LAW IT INSTANCES IS ALREADY HERE and this is its second sighting:
  "THE PREDICTION DID NOT COME TRUE, AND HERE IS THE MECHANISM" BEATS "IT
  CAME TRUE". The first was the pointer-constant guard failing to arm
  because a mint is a CALL. This one lands on the entry written to test
  it, within hours, by a third party — and the useful half is that BOTH
  predictors reasoned about the same wrong thing.
  A WORDING LAW REPAIRS MESSAGES NOBODY HAS WRITTEN YET — the argument
  for landing one rather than filing it, and it arrived as a NON-EVENT
  spotted in review. Two slices were written the same evening by
  different authors who never spoke: the bitwise operator law, whose
  mixed-run refusal rendered as `builder failed: \`|\` and \`&\` in one
  expression have no agreed order`, and lane C's builder-wording law,
  which dropped the executor's blanket prefix. **THE SECOND FIXED THE
  FIRST'S DIAGNOSTIC BEFORE ANYONE NOTICED IT WAS WRONG.** The case made
  for the wording law had been about FIVE EXISTING messages; the better
  case is the sixth, which did not exist when the fix was designed. So
  the value of a wording law is not the backlog it clears — it is every
  message written after it, for free, by authors who never read it.
  AND TWO BROKEN PROBES, THREE MINUTES APART, REACHING ONE WRONG ANSWER.
  A lane reported `a & b` still F0001 after bitwise merged, concluding
  the slice had not landed; the team lead, checking that claim, ran a
  probe using `println` in a LOOSE file, got an error, and nearly read it
  the same way — it was F3000 "no `fn println` is defined", with the
  operators parsing fine. Caught only by piping to `grep -oE 'F[0-9]{4}'
  | sort -u` instead of `tail`, which is THE PROBE-TRUNCATION LAW paying
  for itself inside the hour it was being quoted. THE ANSWER, run in both
  binaries rather than reasoned: `(a&b)+(a|b)+(a^b)+(a<<2)+(a>>1)+(~a)`
  with a=6 b=3 is **34** in main AND in the lane's own tree — the lane's
  compiler could always do it. **A PROBE HAS ITS OWN DEFECTS, AND A
  FAILING PROBE IS EVIDENCE ABOUT THE PROBE UNTIL ITS OTHER LINES ARE
  CLEARED.** Both authors were verifying rather than assuming, and both
  verifications were honest; the artifact under test was simply not the
  one either of them meant to run.
  AND THE INTEGRATOR RAN WHILE THE LANE WAS STILL EDITING — the team
  lead's error, on the discipline he had spent the evening enforcing on
  everyone else. A merge read a working tree HALFWAY THROUGH A RENAME
  (`holes` -> `slots`), coherent at either end and red in between, and
  the gate's `does not export holes` read as a lost export rather than as
  a snapshot of work in flight. **"TAKE MY WORKING TREE" IS TRUE AT THE
  MOMENT IT IS SENT AND FOR NO LONGER.** A lane that asks for its
  uncommitted state to be merged is describing a photograph; the merge
  waits for the lane to say GREEN, which is a claim about the tree at the
  time the claim is made. Nothing was lost (no stashes, main untouched),
  and the cost was one wasted gate — but the same mistake against a lane
  mid-rewrite of a shared file is how the 250-line ROADMAP loss happened.
  THE DRIVER HAD NO CORPUS PROGRAMS BECAUSE THE FORM DID NOT EXIST, not
  because nobody wrote them — and that distinction is the finding.
  `corpus/native/` takes LOOSE files, and a loose file cannot reach a
  package at all (`use @std.sqlite.{version}` is F3015, "this file is not
  in a package"). So `corpus/native/` can only ever prove a WALL —
  externs declared in the file itself, which is exactly what `externs.av`
  and `process_seam.av` are. A driver built ON a package needs the
  PACKAGE form, and the package leg runs the evaluator first, which no
  FFI package survives. **NEITHER FORM FIT, so nothing was written, and
  the driver never showed up to be excluded.** A `native-only` file
  beside `expected` is the mark that was missing; the package leg drops
  the evaluator when it sees one, and the gate now says what it actually
  proved:
      corpus/sqlite:           native == expected
      corpus/sqlite-refusals:  native == expected
      corpus/text:         eval == native == expected
  THE SIBLING LINE IS THE POINT: a reader learns what a two-engine
  program looks like from the output itself, where a sentence in a
  document saying "the differential was unavailable" reaches nobody.
  TWO THINGS CHECKED RATHER THAN READ, both by the author. The mark is
  LOAD-BEARING — removed and re-run, the leg fails with "`sqlite3_open_v2`
  is extern — the evaluator cannot host it", exit 1; a mark that changed
  nothing would have been decoration. And **`make clean` WOULD HAVE EATEN
  IT**: the corpus sweep deletes every file that is not a `.av`, an
  `.expected`, an `expected` or an `avra.toml`, so the first clean after
  landing would have removed both marks SILENTLY and the next gate would
  have failed in the evaluator with nothing saying why. Found by RUNNING
  clean rather than by reading the `find`.
  AND A CORPUS PROGRAM IS A PLACE A FINDING CAN WAIT WHERE SOMEONE WILL
  MEET IT — which is the label argument arriving somewhere nobody aimed
  it. Read in order, the refusals program puts three lines together:
      a column past the row          sqlite.out_of_row
      a cell read before stepping    sqlite.out_of_row
      a parameter outside the holes  sqlite.out_of_row
  `Cause.OutOfRow(column, width)` is doing duty for `(index, holes)` too,
  so a caller branching on it cannot tell a BIND mistake from a READ
  mistake. It had been reported a round earlier AS A SENTENCE IN A
  MESSAGE and gone nowhere; as three adjacent lines in a file people read,
  it is unignorable. Owed: an `error.av` arm split.
  AND THE PROGRAM EARNED ITS KEEP BEFORE IT WAS GREEN. The `mut` seat on
  `step` cost nothing visible in the suite — a test binds a statement and
  steps it in one scope — and collided immediately with the corpus
  program's OWN HELPERS (`read_one`, `summed`), because a caller writing a
  LOOP threads the seat through their own functions. **The ergonomic cost
  of a fix showed up in the shape a user meets it, one commit after the
  fix was written**, which no test in the package would have shown.
  BITWISE LANDED (2026-09-06, `../avra-lane-sq-ffi`: 13 files, 202
  insertions, 1927/1927, `corpus/bitwise: eval == native == expected`,
  traps 6/6, built twice to a fixed point). THE OPERATORS ARE THE LEAST
  OF IT — TWO TOKEN COLLISIONS, EACH SURFACING AS A LIE ABOUT A MODULE
  BOUNDARY.
    `>>` CANNOT BE ONE TOKEN, BECAUSE IT CLOSES NESTED GENERICS.
    `Table<List<string>>` lexed its last two characters as a shift, so
    `workspace.av` never parsed and the cascade read `@std.avrac.language
    does not export Program` — FROM THE FILE THAT DEFINES `Program`. The
    split every generic language makes somewhere: **`<<` MUNCHES, `>>`
    DOES NOT** — shift-right is two adjacent `>` the GRAMMAR joins (both
    branches capturing ONE token into the same label, so the run stays
    1:1 and the mixed-operator law still sees a whole run). `<<` has no
    twin, since nothing opens two argument lists with no name between
    them, so munching it is safe; the asymmetry is documented AT the
    lexer, because the next reader will try to munch `>>`.
    AND `|` WAS RULED FREE, AFTER A GENUINE CHECK, AND IS NOT. The
    ruling verified `|` against or-patterns and against the deleted `|>`
    pipe — both real, both correctly performed, neither touching TABLE
    LITERALS, where `|` is the COLUMN SEPARATOR (`tables/mod.av:20`) in
    **114 sites**, every feature's builder table and diagnostic registry
    among them. `"fn_decl" | build_fn` folded into one bitwise-or, the
    row had one cell against a two-column header, and it surfaced as
    `@std.process does not export Tool`. Fix is ONE WORD — a cell parses
    at `additive`, and a cell wanting the whole grammar parenthesises.
    WRONG SCOPE AGAIN, the third way an honest check lies, TWICE IN ONE
    EVENING by two authors. The transferable half is not "check `|`": it
    is that **A RULING THAT NAMES WHAT IT CHECKED SHOWS ITS OWN HOLE** —
    "free of or-patterns and the pipe" invites "and of what else?", where
    "free" closes the question. THE EVIDENCE LAW, stated as a habit for
    RULINGS rather than for findings.
    THE CASCADE IS THE HAZARD IN BOTH: neither error named the change
    that caused it, and both accused an innocent module boundary. What
    made it cheap was ISOLATING FIRST — stash, `make bootstrap`, confirm
    the clean base builds — which turns "main is broken" into "mine is
    broken" in one step.
    `UnOp` NEVER GREW: `~v` desugars to `v ^ -1` at parse, as `-v`
    desugars to `0 - v`; two's complement makes them exact, `core/ir.av`
    is untouched, no consumer was paid and no catch-all was tempting.
    The OPPOSITE call from `Paren` and for a stated reason — `~` is
    already spellable through an operator that exists, `Paren` was not.
    THE PRECEDENCE, MEASURED BOTH WAYS: `f & m == m` answers `true`,
    where C reads `f & (m == m)` and answers false — the band binds
    TIGHTER than comparison because C is WRONG there. `a << 1 + 2`
    answers 8, C's reading, inherited because C is only ARBITRARY there.
    ONE WART LEFT STANDING, deliberately: the mixed-operator refusal
    renders as `builder failed: \`|\` and \`&\` in one expression have no
    agreed order`. The words are right, but "builder failed:" is the
    executor's blanket prefix (`grammar/executor.av:365`), so A LAW READS
    AS AN INTERNAL DEFECT. It cannot move to typing — after folding, `a |
    b & c` and `a | (b & c)` are the SAME TREE, the parenthesis blindness
    that killed clause 3 — so the run is visible only in the builder.
    Open: whether a builder-raised LAW deserves a different prefix from a
    builder DEFECT.
  - A NEGATIVE LITERAL NOW FOLDS AT PARSE (`ee9e3df`, ten lines):
    `build_neg` folds an int-literal operand through core's VALUE
    PROTOCOL (`int_of`). Both rejections are in the commit message so
    nobody re-argues them — not a `Neg` node, not a general folder; and
    `const B: int = -A` stays refused, `-9223372036854775808` stays F0001
    at the LEXER. THE RULE IT EARNED (lane C's, worth more than the
    slice): AN ASK THAT ARRIVES WITH THE CASES THAT STAY REFUSED IS AN
    ASK THAT CAN BE LANDED IN AN AFTERNOON. AND THE MISREAD BEHIND IT:
    this campaign reported twice, to the owner, that AVRA HAS NO UNARY
    MINUS — false, `expr_spine/builders.av:49` desugars it; the misread
    was `core/nodes.av:173`'s "the one unary, until minus", about which
    AST NODE exists, not which OPERATOR the language has. A DOC COMMENT
    IS EVIDENCE ABOUT THE THING IT SITS ON.
  - A LAW LANDED FOR ONE REASON CLOSED A HAZARD IN A PACKAGE NOBODY HAD
    WRITTEN YET — the argument for landing LAWS rather than FIXES. The
    `mut` seat law landed for the extern inout ABI, and it is why
    `close(db)` on a `let` is F2048, why a closable handle cannot be held
    immutably, and why the driver's double-close surface is ONE
    DELIBERATE COPY rather than every binding in the program. Nobody
    planned that; the driver did not exist when the law was written. With
    `Db = { raw: ptr? }` and `close(mut db)` nulling the handle, the same
    binding closed twice closes ONCE — the unsafe shape is unspellable
    rather than merely documented, which is what the first answer ("the
    type cannot prevent it, so the doc says so") would have settled for.
  - A SAFETY PROPERTY RESTING ON A KNOWN DEFECT — and fixing the defect
    opens the hole. The last double-close path is `mut b = a`, both
    closed. VERIFIED on main (binary 2026-09-05 23:17:22, checkout
    f88d0ce): `first=1 second=0 a.raw=0` — `mut b = a` ALIASES, so
    nulling through `b` nulled `a`. It is safe TODAY only because the
    copy is not a copy: it rests on lane C's S2 receiver-aliasing hole.
    THE DAY `mut` BINDINGS COPY PROPERLY, `close(b)` nulls b's handle
    alone, `a.raw` still holds a freed pointer, and `close(a)`
    double-frees inside a std package — AND NOTHING WOULD NOTICE, since
    the driver's test uses ONE binding and passes either way. THE LAW,
    landed as a GATE CONDITION on S2 at `6553ec6` rather than a note: A
    CORRECTNESS FIX THAT CHANGES AN ALIASING PROPERTY MUST AUDIT ITS
    DEPENDENTS, because code that was safe BY the bug becomes unsafe by
    the fix AND ITS TESTS KEEP PASSING, HAVING BEEN WRITTEN AGAINST THE
    BEHAVIOUR AND NOT THE LAW. The driver writes the test that FAILS when
    the fix lands, with its expiry in the comment.

ASSERT THE GUARANTEE, NOT THE MECHANISM. Measuring what a trap
mid-transaction actually does — a forked child that begins, inserts
twice and `_exit(2)` — showed SQLite's hot journal recovering it: 1 row
not 3, stable across two reopens. AND THE DETAIL REASONING WOULD HAVE
GOT WRONG: the journal is STILL PRESENT AND NON-EMPTY after the
recovering read, while the data is correctly rolled back. A test
asserting "the journal is gone" would have been green today and red on
a WAL database, a different journal mode, or a version that defers
cleanup — BROKEN WHILE THE GUARANTEE HELD PERFECTLY. The guarantee is
THE WRITE IS ABSENT; the journal's lifetime is SQLite's business.
And the recovery is labelled in `tx.av` as SQLITE'S guarantee rather
than ours, which is what stops a later reader assuming the driver does
it.

A STABLE MEASUREMENT OF UNDEFINED BEHAVIOUR IS STILL UNDEFINED
BEHAVIOUR — and this is PROFILE, DON'T REASON cutting the other way.
A red team measured a double `sqlite3_close_v2` answering `0,21` and
concluded API_ARMOR made it detectable rather than undefined. Then read
the C: `sqlite3Close` calls `sqlite3SafetyCheckSickOrOk(db)`, which
reads `eOpenState` — at :188850 the state is written, at :188856 the db
is FREED. **The second close reads freed memory**, and the 21 arrives
only because the freed block still holds the byte. Stress-tested stable
in 40 of 40 runs, including ten connections opened and closed in
between to force the block's reuse.
STABLE IS NOT A CONTRACT. The test was about to pin UB as a guarantee —
in a suite whose whole job is to warn — where it would have taught the
next reader that closing twice is answerable and gone red the day a
lookaside or size class moved. Removed; the suite now asserts only what
the driver PROMISES, with the measurement, both line numbers and the
40-run result recorded as an OBSERVATION.
THE SHARPENING: the tree's law says profile rather than reason, and it
is right — but a measurement tells you WHAT HAPPENED, never WHAT IS
GUARANTEED. Where the contract says undefined, forty green runs are
forty samples of one arrangement, and the honest artifact is a recorded
observation rather than an assertion.

A TEST MOVES DOWN A LAYER RATHER THAN INTO THE BIN. When `is_complete`
stopped truncating at a NUL, the test asserting the truncation did not
become FALSE — it became MISPLACED. C still truncates; the wall still
sees it. So the assertion moved onto `sqlite3_complete` directly and the
face's refusal was added beside it: two layers, two behaviours, both
asserted. **NOTHING THAT WAS TRUE STOPPED BEING ASSERTED.** The failure
mode it prevents is the common one — a fix lands, a test goes red, and
the test is deleted because "the behaviour changed", when what changed
is WHICH LAYER OWNS IT. Ask whether the old assertion is false or
merely in the wrong place.

THE ARM IS RIGHT AND THE SENTENCE UNDER IT IS NARROWER THAN THE ARM.
Twice: `Cause.Syntax` covers `SQLITE_ERROR`, which is SQLite's GENERIC
code, so "no such table" reads as a syntax error; and `waiting_clears`
explains `SQLITE_LOCKED` as "the lock is held by the retry loop itself",
true for detail 0 and false for 262, which is another connection in a
shared cache — in a package that ships the field enabling that mode.
Both times the instinct is to SPLIT THE ARM, and both times that would
have been wrong: the discriminator was already in the value (a parse
error carries a token offset; a shared-cache lock carries its detail).
A REGISTRY ARM CAN BE CORRECT WHILE ITS JUSTIFICATION IS NARROWER THAN
ITS MEMBERSHIP, and the honest repair is to narrow the SENTENCE, not the
arm. Recording the limit beats adding a variant to guess with.

AND THE EMPTY-VALUE LAW, IN THE FORM THE API DEMONSTRATES BEST: AN
ENCODING SPENDS THE EMPTY VALUE, AND SQLITE SPENDS IT THREE WAYS IN ONE
FUNCTION — `""`, `":memory:"`, and a URI whose path component is empty.
Three spellings of the same absence, each meaning something different,
all reaching the temporary database that is deleted at close with every
write succeeding. The third was found by a red team after two were
already guarded.

A SWEEP KEYED TO A FILE LEAVES THE SENTENCE STANDING ELSEWHERE. When
`ptr_at` landed, a sweep corrected all three ROADMAP entries asserting
`ptr` was receive-only — correctly and completely. The SAME CLAIM stood
in a fourth place, `docs/BYTES_SHAPE.md`, with a DECISION hanging off
it ("the driver must not offer a bind at all"), already lifted in
messages and not in writing. A DOCTRINE CLAIM IS NOT OWNED BY ONE FILE:
a sweep keyed to a file finds three and reports done; a keeper keyed to
the CLAIM finds all four. Rot window measured at 8.2 hours and 14
commits with four lanes watching — an absent instrument, not
carelessness. And the shape that hid it: of the page's three clauses,
two went false and one stayed true, which is what let it keep reading
as correct. Found by the docs campaign, not by this one.

THE RED TEAM'S SECOND CAMPAIGN (2026-09-06, `f212c7a`; 380/380 sqlite,
1909/1909 tree). Four findings, three of one shape: A SETTING THAT IS
ACCEPTED, ECHOED BACK, AND NEVER APPLIED.
  A RESET IS ALSO A REWIND, AND THE DRIVER RECORDED ONLY HALF OF IT.
  `step` past DONE answers `false` every time and RE-RUNS THE STATEMENT:
  `insert into t(v) values (1)` stepped three times gives `DONE DONE
  DONE` and THREE ROWS; a select's rows come out again. The auto-reset
  was already written down — as the reason ERROR CODES ARE HONEST, which
  is true and is the harmless half. NOTHING in the answer distinguishes
  "did nothing" from "wrote another row", so A DEFENSIVE EXTRA STEP IS A
  DUPLICATE INSERT — and a defensive extra step is what a careful author
  writes. NOT FIXED, for a MEASURED reason rather than a preference:
  SQLite's own witness cannot carry it (`sqlite3_stmt_busy` is 1 mid-row
  and 0 after DONE, so a guard on it refuses the half still standing and
  misses the half that finished — the partial blocklist this driver
  refuses everywhere else). The refusal needs a flag on `Stmt` and a
  `mut` seat on `step`, which moves `open.av`'s call site, so it was
  REPORTED rather than restructured across a file another lane owns —
  and pinned with the ROW COUNT in the assertion, so the fix flips the
  test instead of merely satisfying it.
  A BLAME ARM IS A CONTRACT WITH THE CALLER, AND THIS ONE WAS BACKWARDS.
  `Cause.Defect` documented "a statement used after finalize … never the
  caller's mistake, report it" — but finalize-then-step is a CALLER'S
  THREE-LINE SEQUENCE through the public face, so the driver was sending
  people to file a bug about their own code. Now `Cause.Finalized`, with
  `step` guarding the null handle the way `in_holes` guards a bind
  index. The three shape verbs answer `int` and CANNOT refuse, so they
  still answer a silent 0 on a dead statement — ASSERTED rather than
  hidden, which is the honest treatment of what a signature cannot fix.
  A LIMIT THAT IS STORED, REPORTED, AND NEVER APPLIED. `SQLITE_DEFAULT_
  MEMSTATUS=0` buys speed and silently costs ENFORCEMENT:
  `hard_heap_limit64(102400)` is accepted, reads back exactly 102400,
  and then `zeroblob(8388608)` allocates 8 MB while `memory_used()`
  answers 0. A service bounding its own memory gets a number back that
  means nothing. Documented at both declarations AND beside the flag
  that causes it — because the defect is not in either place alone, it
  is in their PAIRING, which is the file-keyed sweep's failure one level
  down.
  AND THE BOUND ON WHAT "GATE GREEN" MEANS HERE — HALF RIGHT AS FIRST
  RECORDED, corrected by lane A within the hour and kept here in both
  forms, because the wrong half was an ASYMMETRY THAT DOES NOT EXIST.
  TRUE: `eval == native` can never apply to a package that binds C. The
  evaluator refuses externs outright (`avra_ptr_at` through `avra run`:
  "extern — the evaluator cannot host it; build natively", the same
  program native answers 1), and that holds for every FFI package until
  the extern host lands. FALSE, as first written: "all 380 tests are
  native-only, beside sibling suites that get two". **`avra test` IS
  NATIVE FOR EVERY PACKAGE IN THIS TREE** — std-avrac's 1909 cases are as
  single-engine as sqlite's 380. THE DIFFERENTIAL DOES NOT LIVE IN THE
  SUITES AT ALL; it lives in the CORPUS, which is why the gate prints
  those legs on separate lines. So the driver stands beside IDENTICALLY
  guaranteed siblings, and the one leg it cannot join is the corpus's
  eval-vs-native.
  AND THAT MAKES IT A CATEGORY TO USE RATHER THAN A BOUND TO RECORD:
  `corpus/native/` already exists for exactly this — `externs.av` and
  `process_seam.av` live there, `avra corpus --native-only` is the flag
  ("the programs are the host's: skip the evaluator", `corpus.av:117`),
  and `make` runs it as its own line. **THE LABEL TRAVELS WITH THE
  ARTIFACT**, which a note in a document never does. The driver's real
  gap is therefore not the missing differential; it is that
  `@std/sqlite` has ZERO corpus programs, so it appears in NEITHER
  corpus leg — owed: `corpus/native/sqlite*.av` with their `.expected`.
  THE SHAPE OF THE MISTAKE, which is the campaign's own one shape again:
  a REAL measurement (the evaluator does refuse externs) carrying an
  UNMEASURED COMPARISON (that siblings get two engines) — WRONG SCOPE,
  the third way an honest check lies, committed in the same entry that
  names it.
  WHAT SURVIVED, worth as much as what did not: the NULL-pointer law
  holds under attack — SQL NULL is class 5 with a NULL pointer, a
  zero-length blob is class 4 with the SAME NULL pointer, so asking the
  CLASS first genuinely separates the two reachable cases. Also per-row
  type variance, a NUL bound as text arriving whole, int64 edges exact,
  a real refused rather than truncated, `reset` keeping bindings, and a
  5000-deep expression refusing instead of segfaulting.

THE EVIDENCE LAW — the campaign's most transferable output, earned by its
authors being wrong repeatedly in public. CLAUDE.md carries the general
form; this is the evidence behind it.
  **"ALWAYS CHECK" IS NOT THE RULE. "NAME WHAT YOU CHECKED" IS.** Four
  people produced a genuine error from a genuine run and each was wrong —
  a stale binary; `git log -1` quoted as the base, which names the
  CHECKOUT and not the compiler that answered; a reduction retyped from
  memory that dropped its trigger; two files run between one pair of
  echoes, attributed by elimination. All four DID verify.
  THE THREE WAYS AN HONEST CHECK LIES: STALE BASE (a real run against a
  tree that has moved); WRONG GRANULARITY (a real read of a LINE reported
  as the TOOL — `externs.py:63`'s regex read as the keeper, while line 96
  strips macros before it ever sees the type); WRONG SCOPE (a real GREEN
  run that never saw the subject — "104 externs matched, 9 keeper cases
  hold" on main, where `git ls-tree main -- packages/std-sqlite` is ZERO
  FILES). THE HABIT: SAY THE ARTIFACT AND THE CLAIM IN THE SAME BREATH.
  THE F0900 LEDGER — how a contested finding gets recorded, each line
  carrying its base: PRESENT at `d96a328` (clean tree, call site
  included) and `cabce5f`; WITHDRAWN at `22adc6a` (attributed by
  elimination, no evidence either way); FIXED at `349c74d` by lane C, who
  reproduced it independently; ABSENT at `7b90a46`, freshly bootstrapped.
  A ROW THAT SAYS WITHDRAWN IS WORTH MORE THAN A ROW DELETED. THE
  TRIGGER, so nobody re-derives it: a FLAT record in a `mut` seat whose
  body writes the field, AND A CALL SITE. Fixed in TYPING, not lowering.

AND THE ONE SHAPE'S LAST INSTANCE IS THE COORDINATION ITSELF: QUOTE
THE CLAUSE YOU ARE ANSWERING. Two sessions sharing the name `SQLITE`
misdirected five things in a day — a lost message, a duplicated backlog
entry, an attribution dispute over rulings nobody had misattributed, a
peer nearly accepting a fault that was not theirs, and credit for a
finding landing in a third session's inbox. Addressing by REF closed
the name collision and did not close the last two, **because the defect
was never in the addressing**: a correctly-addressed reply can still
answer a conversation the recipient was never in.
THE FIX IS A CONVENTION, NOT A MECHANISM. A message that carries a
FRAGMENT OF ITS PARENT is self-identifying in a way no address can be —
the address says where it went, the quote says what it answers. One
quoted line would have caught both remaining cases in the first reply
rather than the third. It costs a line, survives every routing failure
including ones nobody has met, and needs nothing from the transport.
Which is the campaign's one shape exactly: an identifier that resolves
differently on the two sides of a boundary, fixed by making the
identifier carry what it means rather than by making the boundary
smarter.

THE ONE SHAPE, which is what this campaign actually found. Every finding
above and every coordination failure it suffered is the same bug in a
different substrate: AN IDENTIFIER THAT RESOLVES DIFFERENTLY ON THE TWO
SIDES OF A BOUNDARY. In the compiler: a guard reading `==` while the
callee reads the header; a declaration saying `int` while the C body
answers 32 bits; a probe naming a CHECKOUT while a binary answered from
another; a doc comment about a NODE read as a claim about the LANGUAGE.
In the coordination, the same day, by the people writing those laws: a
worktree two sessions wrote to -> 250 ROADMAP lines lost to a whole-file
`git checkout`; a worktree renamed without notice -> a failed `cd`
RE-POINTED an `&&` chain into main; a name two sessions answered to -> a
lost message and a duplicated backlog entry.
  MAKE THE IDENTIFIER SAY WHICH ONE IT MEANS. Read the same bytes as the
  thing you protect; name the binary and the commit it was built from,
  not the tree; address a ref, not a name. TWO OPERATIONAL COROLLARIES,
  both paid for: a lane that shares a worktree REVERTS BY HUNK OR NOT AT
  ALL, and a failed `cd` in an `&&` chain RE-POINTS it rather than
  stopping it — write `cd X || exit 1` before it. Changing a shared
  layout is an ANNOUNCEMENT, not a cleanup.

## THE HTTP CAMPAIGN (opened 2026-09-06) — `@std.http`, and the foundations it forces

Lane `lane/http` (worktree `../avra-lane-http`), taken over 2026-09-06 by
session avra-2a after the first session died mid-slice. The mandate: a
client and a server, backbone-grade, tiny and idiomatic; build the
missing foundations, never entrench a workaround. Papers:
`docs/2026_09_06_STD_HTTP_DESIGN.md` (an endpoint is a contract),
`docs/2026_09_06_STD_HTTP_TYPED_ROUTES.md` (one format, two directions),
`docs/2026_09_06_HTTP_FRAMING_LAWS.md` (RFC 9110/9112 framing, the fast
parsers' tricks, the event loop, the attack table). The working log is
`docs/HTTP_WORKING.md`.

THE SLICES, in dependency order: `Bytes` (built, gated, awaiting the
OWNER's ruling on the capability — lane A: who touches a file is a lane's
to say, whether Avra gains a value type is not) → the net substrate
(runtime rows: listen/accept/connect, nonblocking read into an
exact-size box, write from an offset, a readiness poller over
kqueue/epoll) → `@std.http` (an index-driven HTTP/1.1 framer over
`Bytes`, a route trie compiled once, an event loop, a blocking client).

*** `Bytes` — WHAT WAS DECIDED, and by whom ***
  - The shape is `docs/2026_09_05_BYTES_SHAPE.md` — the SQLITE campaign's
    paper written FOR lane A, never lane A's — with three deviations
    ruled correct by lane A on the merits, all three moving from a silent
    wrong answer to a loud refusal:
    1. `at` TRAPS past the end (through `trap_bounds`, as a list index
       does), never answers -1: a byte is 0..255, so -1 is a legal-looking
       value spent as a sentinel, and a framing parser would read it.
    2. `slice` TRAPS on bad bounds (`trap_slice`, cold and noreturn beside
       `trap_bounds`), never clamps. `substring` and a list's `slice`
       clamp, and that precedent was nearly followed for consistency —
       but a clamp is a display artefact for text and a SILENT WRONG
       ANSWER THAT PARSES for a protocol. Consistency with a precedent
       from a different domain is how a clamp gets into a parser.
    3. NO VIEW KIND. The first draft carried `KIND_BYTE_VIEW` (a retained
       `{owner, offset, length}`); dropped because a view's pointer is
       not its data, which breaks "a Bytes crosses as Ptr" at every
       extern seat — the property the whole wall rests on — and a tiny
       view pins a large receive buffer. Slices COPY; the HTTP parser is
       index-driven and slices only what escapes. Views return the day
       the compiler can hand back an unboxed (ptr, len) — slot-layout
       territory, a recorded trigger, not a workaround.
  - THE SPARE BYTE IS A NUL, by lane A's overrule of a 0xFF poison byte.
    The poison was argued from the two-hats law (make the reinterpretation
    impossible); it bought an OUT-OF-BOUNDS READ instead — `strlen` walks
    past the box into unrelated heap, undefined and attacker-influenced on
    a server. A NUL makes an accidental C-string read a BOUNDED
    TRUNCATION: wrong in one documented way, never undefined. Wrong is
    fine; undefined is not.
  - THE LAW THAT SORTED THE ROWS: A BOUND IS A PRECONDITION AND TRAPS; A
    DOMAIN IS A QUESTION AND ANSWERS NULL. `at`, `slice` and `index_of`'s
    `from` trap; `[ints].bytes()` past a byte and `b.text()` on
    non-UTF-8 answer null, through the pointer niche, and mean absence
    and nothing else.
  - AN EMPTY BYTES IS PRESENT, BY CONSTRUCTION (lane C asked; it is the
    one class eval == native cannot catch): every minting row goes
    through `bytes_box(n)` = `sized_box(n, KIND_BYTES)`, so a zero-length
    value is a real box, and no row returns NULL to mean "empty".
    Pinned as `corpus/bytes_presence.av`, written as "every way to make
    one" so the next constructor has a list to join.
  - THE EVALUATOR HOLDS OCTETS DIRECTLY, `Val.Y(List<int>)`, permanently
    (lane C): the vocabulary splits on IDENTITY, not on scalar-or-heap —
    a string is held directly and an array by handle because mutation
    must show through every holder. Bytes is immutable, so no identity,
    so no handle, and the representation is the evaluator's business.
  - `text()` ANSWERS A STRING FOR A NUL, because U+0000 is text and a
    validator that refuses valid input to protect a downstream boundary
    moves the defect rather than closing it. What that forces is H1's
    other half, below.
  - THE DEADLINE THAT DID NOT ARM, with its mechanism (lane A's register
    entry at 44c36f1 predicted `Bytes` would be the box allocated at
    exactly n that made `str_len`'s fallback live): the box is minted at
    n+1 through `sized_box`, its length is read by its OWN accessor, and
    no typed path hands a Bytes to `str_len`. The one door that does —
    `extern fn avra_str_len(b: Bytes)`, which any file may declare — is
    `corpus/bytes-header`, and it answers the header — differential
    since the text-seat law below; it was native-only until then.
  - A `Bytes` AT A TEXT SEAT IS THOSE BYTES VIEWED AS TEXT (the
    substrate lane, 2026-09-08). A row's seat kind is `Ptr`, which a
    string and a `Bytes` both fill — natively one headered box, read
    the same way — while the evaluator held them as two `Val` variants
    and its text projection read one: `corpus/bytes-header` was
    native-only, and `avra_str_trim(" hi ".bytes()).length` was `2`
    compiled and "a non-string reached text in a clean program"
    interpreted. Fixed ONCE, in `text_val` (interp.av), so every row
    arm that reads a pointer seat as text — fourteen, measured:
    Strlen, StrContains, StrStartsWith, StrEndsWith, StrIndexOf,
    StrSplit, StrReplace, StrTrim, StrConcat, BytesOfStr, HostEnv,
    Eputs, IoList, SpawnStatus — inherits it by construction. THE
    DECODE IS LOSSLESS FOR UTF-8 AND ONLY FOR UTF-8 (probed: twelve
    bytes through a NUL and a snowman round-trip exactly); an
    evaluator string cannot hold arbitrary octets, so bytes that are
    not UTF-8 are REFUSED BY NAME rather than approximated, and a
    LENGTH never decodes — `Strlen` answers the header for any octets,
    as the row does natively. RECORDED TRIGGER: a byte-lossless
    evaluator string, or a `Bytes` twin for the text rows, retires the
    refusal (`refused_octets`, interp.av) and its spec in
    `language/tests/run_test.av`. `corpus/bytes-as-text` pins the
    decode on both engines.
  - THE KEEPER GAP THAT OPENS THE DAY THE TYPE LANDS (lane A's, theirs to
    close in the same hour): `tools/externs.py`'s `seat_fits` ABSTAINS
    on a declared type it has no reading for, so every `Bytes` extern
    seat is unchecked and reported green until `DEMANDS` learns it.
  - TWO COLLAPSES LAND ALONE, ahead of the ruling (lane C's request,
    verified in their tree): `worded` (a row's seats, then its answer)
    exported from `features/checks.av`, and `lower_is_empty` exported
    from `features/emit.av` — lane C proved the short form EXPANDS to the
    long one ("one is the other with a verb around it"), and checked the
    one thing a collapse silently breaks, the I29 mint order.
  - THE RED TEAM: 85 programs over eight classes; zero findings in the
    type. Every accepted program agrees on both engines under
    `AVRA_RC_GUARD=1` with zero live bytes at exit; every refusal refuses
    once, in its own words. The survivors are `features/bytes/tests`
    (two specs, ~100 cases), three rows in `tools/traps.sh`, and four
    corpus programs.

*** TYPED STRING PATTERNS — LANDED (the strings lane, 2026-09-07) ***
  `match line { "{method} {path} HTTP/{major}.{minor}" -> … }` binds
  four holes from ONE anchored scan: the first piece is a prefix, the
  last a suffix, every piece between found at its first occurrence
  after the cursor — no backtracking, linear by construction, and the
  law was CORRECTED BY RUNNING IT (the first draft found an empty last
  piece at the cursor). The format is read out of the PEG ladder (a
  string-literal token whose holes a small reader parses at build
  time); enums' STRING pattern alternative moved to formats because the
  grammar coherence check refuses two branches with one first token
  (grammar/first.av:117) — the gram decides ownership of PARSE,
  `semantics_of` of MEANING, and a hole-free literal still means
  `Pat.Lit`. The seam it needed, `pat_semantics_of` (lane C, owed the
  moment a SECOND feature owns a `Pat` variant), and the per-pattern
  slot `bind_test`/`test_regs_of` (lane C) let the test find the spans
  and the binds cut them, so AN UNTAKEN FORMAT ARM MINTS NOTHING.
  MEASURED (tools/bench/frame_scan, subject hoisted, three runs): a
  request line over TEXT by hand 62 ns, by format 97 ns (1.58x); over
  OCTETS — where the framer works and nothing is converted — by hand
  74 ns, by format 90 ns, 1.24x. The difference between the two ratios
  is the subject conversion the text path pays and the octet path does
  not, ~6 ns. THE HARNESS RULE, found by an inflated first run: a
  `once` read inside a timed loop cost 20% on both sides and
  compressed the ratio — hoist the subject, or the harness measures
  the runtime's lookup. Red-teamed: 30 programs, seven classes, zero
  findings; `formats_adversarial_test.av`; the NUL-past-both-separators
  scan (`a | NUL b | c`, three exact spans, both engines) is
  `corpus/formats_bytes.av`, the guard-and-guarded law pinned where a C
  string scan would lose both separators.
  THE MEANING CHANGE, measured before it was made: 37 arm-head string
  patterns across packages/ and corpus/ at 9fe5597, ZERO containing a
  brace; a pattern with braces used to compile as a literal that could
  never match and fell through silently.
  TRIGGERS, recorded with their firing conditions:
  - [ ] TYPED HOLES: `{n: int}` refuses today (F2060, naming the
        pending row). FIRES when a TEXT -> INT PARSE ROW lands — the
        framer's `decimal`, the hole and a user's `"42"` are one law.
        ROUTED TWICE WRONG AND SETTLED 2026-09-07 by the SQLITE lead: it
        is NOT the `decimal` question (`decimal` is a VALUE TYPE — exact
        base-10 arithmetic, ruled core, deferred to the ORM campaign) and
        it is nobody's in flight — measured, NO such row exists: no
        `to_int`, no `parse_int`, no `strtol` in the runtime, and
        @std/text's twelve exports parse nothing. So the trigger stays
        recorded because nobody has built it. THE ROW'S SHAPE, as
        proposed and agreed: text -> `Result<int, E>`, refusing at the
        first bad byte with its offset, an overflow answer. FOUR LAWS IT
        OBEYS: (1) it reads the HEADER'S LENGTH, never `strlen` — a
        parse built on C string calls reads `"12\0garbage"` as 12 and
        the caller never learns, and this row will parse a path segment
        off the network; (2) THE EMPTY CASE FIRST, and it REFUSES —
        `""` is not zero; (3) OVERFLOW REFUSES, never wraps or
        saturates (the 320-digit float literal that became `inf` is the
        precedent: what must never stand is a number nobody wrote); (4)
        it ACCEPTS `-9223372036854775808`, which the LEXER refuses as a
        literal (F0001) — lane A's law settles both: a literal is what
        the programmer wrote and the compiler can see it does not fit; a
        computation's result is discovered at runtime and the parse's
        own contract defines it — written AT THE SITE, or the next
        reader files one of the two as a bug. OWNERS: the row is lane
        A's (runtime rows), the face @std/text's owner's; the strings
        lane is the consumer. THE ORDER WHEN THE SLICE COMES, lane A's:
        lane A writes `<row>_adversarial_test.av` against the four laws
        FIRST, with nothing behind it; the strings lane implements in
        the owner's file until it goes green; lane A reviews the C for
        what a test cannot see (the header law, the allocation). The
        fourth law is the reason for tests-first: an asymmetry that is
        correct reads as a bug to whoever implements it and gets "fixed"
        into a refusal — as a named failing test it survives the lane,
        the rebase and the next person. The hole ships as TEXT with the
        handler converting, so the typing lands against a live consumer.
  - [ ] HOISTED LITERAL OCTETS — FIRED 2026-09-07, now an ASK of the
        core owners: the scan converts each literal piece to octets on
        EVERY attempt because the IR carries no `Bytes` constant, and
        over octets that is THE WHOLE remaining gap — four conversions,
        17 ns of a 90 ns scan, ~4 ns each, the cost of a small box
        here. The hand-written scan hoists its separator into a `once
        fn`, as frame.av hoists every literal it scans for. A `Bytes`
        constant is a vocabulary event under the eight-consumer
        protocol; the strings lane does not grow the IR. WANTING SITE:
        `features/formats/lower.av`'s per-piece conversion.
        THE CENSUS ANSWER (2026-09-07, `tools/bench/frame_head` under
        `-DAVRA_CENSUS`): a framed head pays 52 `once` reads = 104
        retain/release ops (`avra_once_get` is the program's largest
        retain site, 104M over 2M heads) and 988 pointer compares
        (nineteen a read — a program holding twenty tables, not the
        compiler's one). THE ASK, TWO HALVES: (a) the per-site O(1)
        slot — lane A: "take it", pure lookup cost, no semantics; (b)
        A `once` ANSWER IS IMMORTAL — its header wears the STATIC kind
        and a read is a borrowed load, no retain, no release. LANE A'S
        PROBE against (b) as stated: `is_shared` answers FALSE for a
        STATIC box (`kind == -1`), so `avra_cell_unique` hands the box
        back for in-place mutation — `mut xs = shared(); xs.push(99)`
        writes INTO THE CACHE for every later reader, no diagnostic
        (today rc == 2 makes the write copy). THE PREREQUISITE is one
        line — an immortal value is shared by definition, so
        `is_shared` is `kind == KIND_STATIC || (kind >= 0 && rc > 1)`
        — landed WITH the decision, not before it (machinery ahead of a
        decision biases it). THE OWNER'S CALL on (b); the census ratio
        (~a quarter of a head) is on a runtime ~8% slower than
        shipping, the counts are exact.
        RULED BY LANE A, MEASURED (4M reads): a `once` read is ~12 ns
        and it is ENTIRELY the read — call, pointer scan, retain, the
        caller's release — so hoisting four conversions through a
        `once` today trades 17 ns for 12, a 5 ns saving not worth a
        lowering change; the hoist pays only once the read is O(1) (a
        per-site slot, a load and a null test, ~1 ns: sixteen of the
        seventeen). SO THE ORDER IS THE FINDING: the per-site `once`
        slot FIRST (lane A's, scoped after measuring what it buys IN A
        COMPILE — `rt_index()` is a `once fn` read per instruction
        lookup — never on a parser's number alone), the lowering hoist
        after. A `ConstBytes` is blocked until `Bytes` is on main and,
        when it can land, pays its eight consumers as `ConstFloat`
        did — the right cost for a value category, the wrong one for
        a hoistable conversion. AND THE 4 ns IS NOT STABLE UPWARD: it
        is a small box's cost because the size-class free lists made
        it one; a conversion that outgrows a class stops being 4 ns.
  - [ ] MOVE 4, a grammar on a live stream: FIRES when the server's
        read loop shows the head re-scanned per read in a census.

*** THE LANGUAGE ASKS, each with its wanting site ***
  - [ ] AXIS 18 — GREEN THREADS. `spawn`, `Task<T, E>`, fibers parked on
        kqueue/epoll, blocking-looking I/O rows that yield. WANTING SITE:
        the `@std.http` SERVER. Its handler is `fn(Request) -> Response`,
        synchronous, so the API is fiber-shaped from day one; until the
        scheduler exists the server is an EVENT LOOP in Avra over the net
        rows, and a handler that blocks (a sqlite call) blocks the loop.
        Nobody owns Axis 18 (lane A, 2026-09-06); a runtime scheduler is
        in no lane's plan. Recorded here as the first consumer's ask.
  - [ ] TYPED STRING CAPTURES / NAMED FORMATS. `"/ideas/{id: int}"` as a
        pattern binding `id` (F3000 today), and `route P = "…"` as a
        value that parses AND prints (`docs/2026_09_06_STD_HTTP_TYPED_ROUTES.md`).
        WANTING SITE: `@std.http`'s router. Unclaimed (lane C searched).
        LANE C'S ADVICE, adopted: keep it OUT of the `match` pattern
        ladder — that grammar already carries or-arms, `rest`, nested
        variants, binds and literals, and CLAUDE.md's grammar laws are
        its scar tissue; a format that lives elsewhere fails cheaper.
        Routes compile at runtime into a trie until then.
  - [ ] STATIC METHODS — the owner said "Yes to static methods" to
        the HTTP lead 2026-09-07; lane C, who lands it, holds that a
        relayed word is not a grant (the pointer-mint fence), so it
        lands when the owner says so IN LANE C'S SESSION. THE SHAPE
        BEING APPROVED, probed by lane C: a fn under an impl with no
        `self` is TODAY silently a method with an implicit receiver
        (`p.make(5)` compiles clean), so the slice is (1) a MARKER for
        a receiver-less fn under an impl — a declaration-surface change
        with a grammar half; (2) the admission test reading it; (3) the
        refusal's voice widening; (4) `Self`, if in the same slice.
        Grammar's `parse` then becomes one case of the general door and
        nothing landed under Rule A is thrown away. LANDED on main at
        e351840 (lane C) and merged into lane/http: `type_receiver`
        resolves a type-name receiver as VARIANT (the type's own
        shape) → GRAMMAR DOOR (the vocabulary, `method_row` before
        `declared` as for a value) → `static fn` (the user's impl) →
        the variant's answer. OBLIGATION RECORDED (lane C): the day a
        grammar type can hold an impl, a `static fn` named like a door
        is unreachable — the refusal belongs at the declaration in
        `static_shadows`'s shape (F2059's twin, asked of the
        declaration's doors); no test can fail on it yet.
        THE ASK AS IT WAS PUT — a type-qualified call (`Name.parse(text)`
        meaning a call to an inherent fn, not variant construction),
        THE OWNER'S DOOR, put separately by lane C's ruling and not
        taken as a feature's side effect: the ROADMAP already records
        "STATIC METHODS do not exist today … when the spec wants them
        they need their own marker", and CLAUDE.md records the absence
        from the other side (`g.keywords()` is a method on a Grammar
        VALUE because Avra has no type-qualified call). WANTING SITES:
        the strings lane's `grammar Name = "…"`, whose `parse` is the
        first consumer — landing NOW under lane C's narrow admission
        RULE A (a type-name receiver is a call only when the type's
        declaration is a `grammar`, a feature giving meaning over its
        own declared types), a `Callee` variant in features/impls with
        four consumers; and every selfless fn a type wants to own. IF
        GRANTED (RULE B, any type name with an inherent fn of that
        name), A's admission test widens by one line in lane C's file
        and nothing written under A is thrown away. Costed against the
        alternative before asking: a `Fmt<R>` value type would have
        been a new core `Type` variant, 44 exhaustive matches in 19
        files across three lanes (`make vocab` names two of them).
  - [ ] A `string` CROSSING TO C THAT HOLDS A NUL — THE OWNER'S DOOR,
        raised by lane C (main 9c49b6e) off the io lane's finding: a
        79-byte path with a NUL at byte 5 READ A DIFFERENT FILE on both
        engines, and lane B's twin in @std/process RAN A DIFFERENT
        PROGRAM. Not loss — the C side RESOLVES the name, so the
        truncation acts on an object the program never named; and
        eval == native is blind to it by construction, the third such
        finding in a day. Every package may declare `extern fn f(path:
        string)` through the extern host and inherits it; io fixed six
        verbs, process its three plus every word — the next package will
        not know how many verbs it has. THE HTTP LEAD'S RECOMMENDATION,
        by the two-hats law (a value the callee reinterprets wears two
        hats; the fix makes the reinterpretation impossible, never an
        escape): (1) THE SEAM TRAPS — every `string` seat of a package
        extern checks the header's length against the first NUL at the
        crossing, in ONE check both engines share (the trampoline's
        marshalling and the native lowering's), and a NUL there is a
        wreck ("a string holding a NUL crossed to C as two strings",
        exit 2), so the invariant is the seam's and no package can
        forget a verb; (2) A FACE THAT TAKES FOREIGN TEXT REFUSES WITH
        WORDS BEFORE THE SEAM (`one_path`, `Holed(path, at)`), the
        braces to the seam's belt, because a trap is not an answer a
        program can handle; (3) `Bytes` IS THE ESCAPE HATCH — a seat
        that carries its length, for a caller who means octets; and a
        documented hazard with a lint is REFUSED, since a lint documents
        what it cannot close. AMENDED BY LANE C'S PROBE, run on main:
        `avra_host_env("PATH" + NUL + "NOT_A_REAL_VARIABLE")` answers
        PATH's value — a RUNTIME ROW truncated at byte 4 and resolved a
        name the program never wrote — and `avra_proc_spawn`/`run`/
        `which` are rows whose first seat is a PROGRAM PATH, so "rows
        are trusted" would let a NUL-bearing path SPAWN A DIFFERENT
        PROGRAM with the seam declining to look. THE AXIS IS NOT ROW
        VERSUS EXTERN: it is whether the CALLEE RESOLVES THE STRING
        AGAINST SOMETHING OUTSIDE THE PROGRAM. `avra_str_join` holds a
        NUL harmlessly (our body, bytes we own — the LOSS hazard already
        documented); `avra_proc_run` resolves a path against a
        filesystem and is a door that happens to be a row. So clause
        (1) attaches to the SEAT, not the family: a registry column
        beside `lends`, and THE DEFAULT IS THE SAFE ONE — every `string`
        seat is CHECKED unless its row writes `inert: true` at the site
        (its C body operates on bytes the program owns and resolves
        nothing), the exemption law's shape: an exemption not written
        where the code is would be an unbounded amnesty, and the hot
        string rows the framer scans with are exactly the ones that
        write it. A package extern's `string` seats are always checked;
        a package that means octets takes `Bytes`. COST: one scan per
        checked seat per call, on calls that are syscalls, spawns or
        lookups. `avra_fd_*` take `Bytes` and carry their length.
        DECIDED BY THE OWNER 2026-09-07 ("yes do the same thing as
        other mature languages. make it beautiful and safe and
        performant."), AND DOORS 2 AND 3 DECIDED THE SAME DAY ("yes to
        decision 2 and 3"): S2c's per-package library is the substrate
        lane's slice after the seam; immortal `once` answers with the
        `is_shared` prerequisite are lane A's, on the owner's word in
        lane A's session. AND SHARPENED BY LANE A BEFORE A LINE WAS
        WRITTEN — the first brief had two readings: (A) the check
        governs only seats the callee resolves, and the LANGUAGE stays
        as lossy as today (`"ab\0cd" == "ab"` true); (B) the column
        governs every row, and `==` TRAPS. Neither is what mature
        languages do: Rust, Go, Python and Java answer FALSE, because
        their string operations read the whole length. THE THIRD
        READING, taken: (1) the five lossy primitives (`==`,
        `contains`, `index_of`, `split`, `replace`) become CORRECT —
        length-aware `memcmp`/`memmem` in the runtime, lane A's C, the
        worst case (a megabyte string) measured; (2) the seam TRAP
        governs only seats the callee RESOLVES outside the program —
        paths, names, command words, environment keys — where a NUL
        is two names and no correct answer exists; (3) `inert: true`
        means "reads the header's length; a NUL is data", the state
        every string row is in after (1), so CHECKED-by-default bites
        only the resolving rows; (4) the guard reads the header's
        length only for a pointer that is ours — a foreign pointer has
        no interior NUL by definition, so the check is skipped there
        rather than passed vacuously through a `strlen` fallback. The
        substrate lane writes (2)–(4) under lane A's review. AND THE
        EXCEPTION, STATED MECHANICALLY (the sqlite lead, sweeping their
        wall after the first merge went red on their length-carrying
        `bind_text` case): the escape is not "a package that means
        octets" — an intention — but A SEAT WHOSE PROTOTYPE CARRIES ITS
        OWN LENGTH, greppable in the header: a `const char*` beside a
        byte count is `Bytes` and pays no scan (four in the driver —
        `bind_text`, `bind_blob`, `keyword_check`, and `prepare_v3`, the
        hottest seat in the package); a bare `const char*` is checked
        (seven in the driver, two of them already guarded with a
        `Result`). A SQLite TEXT value is a byte string with a
        terminator appended, so a NUL there is legal, stored data. And
        the layering: A LIBRARY REFUSES BEFORE THE LANGUAGE TRAPS — a
        package that knows why a seat resolves answers a named cause;
        the seam is the floor for every package that has not thought
        about it; the trap firing inside a guarded package is a bug in
        the guards.
  - [ ] A GRAMMAR'S DOOR AS A VALUE. `routed<Idea>(…, Idea.parse, …)`
        is F2003 "`Idea` is a record, not an enum": the type-name
        admission rule fires for a CALL, never for a bare `Name.parse`
        passed as a fn value, so every route wraps it — `(t: string)
        -> Idea.parse(t)`, one honest line. WANTING SITE: the router's
        table (`packages/std-http/src/route.av`), the first consumer
        where a door wants to be a value; the same door-as-value
        question the subset's "a generic fn as a value" entry records
        for pinned calls. Recorded by the strings lane at S7.
  - [ ] A GRAMMAR CANNOT STATE ITS OWN PATTERN TEXT, so `routed` takes
        the pattern TWICE — once as the string the route table keys on,
        once as the grammar the reader is — and a disagreement is a
        SILENTLY DEAD route: at the string's target the reader refuses,
        at the grammar's the table never offers it; never a wrong
        answer, never a word. The ask: `G.pattern` (a grammar's format
        as a value), or a `routed` that takes the grammar itself.
        WANTING SITE: `packages/std-http/src/route.av`. The sharpest
        thing S7 taught about the formats feature (strings lane).
  - [ ] AN UNBOXED (ptr, len) VIEW, escape-analysed: the zero-copy
        capture the typed-routes paper wants. WANTING SITE: the framer's
        header values. Slot-layout territory (lane A). Until then, the
        Request holds OFFSETS into its own buffer and materialises a
        value when the user asks for it — which is the moment it escapes.

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
  no-ops BY CONSTRUCTION (avra_rc_release guards NULL and reads no
  header on what is not a box). The representation IS the safety
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

## Recorded triggers — the integrator's substrate

- [x] THE GATE PROVES A TREE AND THE INTEGRATOR COMMITS A TREE —
      FIXED at fe1c152: integrate.sh commits, THEN gates, THEN merges,
      and HEAD, the tracked content and the untracked list are pinned
      before the gate and compared after (avra-8sb5.2.2). Reported by
      the SQLITE lead, the deepest of three found the same night. `tools/integrate.sh` runs `make gate` over the
      working tree and then merges what git has; a working tree that
      moves between the two — a half-finished rename, a deliberate
      break left in a file — is gated in one state and merged in
      another. It cost two wasted gates that night, which is the
      cheap way to meet it.
      THE OTHER TWO ARE FIXED (16fb4a4) AND NAMING THEM TOGETHER IS
      THE POINT, because they are ONE SHAPE ON THREE SUBSTRATES: the
      tree the gate READ, the tree the script COMMITTED, and the tree
      a `/tmp` path BELONGED TO. Each is a verification whose subject
      is not pinned to the thing being verified.
      NOT A PATH-NAMESPACING FIX. It wants the gate to prove the
      EXACT COMMIT that merges — gate the committed tree, or refuse
      to merge a tree that changed under the gate. Worth designing
      rather than patching.

- [ ] A TRAP NAMES ITS SITE, AND A COUNT-BORN TABLE IS GUARDED. The
      2026-09-11 feedback survey (lane/comptime) found the highest-cost
      friction in the slice: two `index N out of bounds (length M)`
      aborts that named no file, pass or declaration (roughly two
      hours bisecting with hand-added prints; `lldb` named the fault in
      minutes), a `defect:` that read `family 5 key 0` instead of
      `Resolved`/file 0, and a debug print that cost an extern
      declaration (F3017, module-wide). The capability: every
      `avra_trap` / `trap_bounds` / `missing_value` prints the current
      PASS and the declaration in hand, a `--trace-passes` breadcrumb,
      and a keeper that names a per-file table sized from
      `store.exprs.count()` or `store.stmts.count()` at pass start —
      the class that bit TWICE in one slice and was found only by
      lldb. FIRES when the next bounds abort costs more than a minute
      to localize, or at the next pass added, whichever comes first.
      Evidence: ROADMAP "Feedback survey — 2026-09-11".

## Feedback survey — 2026-09-14 (NAMED TYPES, comptime/types)

One slice on 9d0f331: `type Name = Shape` — a DISTINCT named type
over any shape, the design doc's §7 q1 law landed whole
(docs/2026_09_14_NAMED_TYPES.md). Gate green, idioms debt 0, fixed
point identical, seed refreshed. Everything below was met writing it;
nothing was surveyed outside this worktree, and no other lane's tree
was read.

### FRICTION — what cost time

- **A SPEC CASE CANNOT PRINT.** Twenty-two `shown(...)` cases went red
  while every CLI probe of the same source passed, and a spec case
  answers a bool — so there was no way to see what `analyze_source`
  actually said. The debug loop was: build a THROWAWAY PACKAGE
  depending on `@std/avrac`, write `println(a.report())` into its
  entry, `avra build` it, run it. ~25 minutes and three heavy builds
  for one question. EVIDENCE: /tmp/avra-probes/dbg, built twice
  because the first copy was a generation behind the fix. THE ASK: a
  failing spec case should print the two sides it compared, as a
  program test's diff does — or `avra test --explain <case>` should
  re-run one case with its intermediate values shown.
- **A PROGRAM TEST INSIDE THE TREE CANNOT BE RUN BY HAND.** `./avra
  run packages/.../tests/named/named.av` reads the file as a MODULE
  of std-avrac and answers F0902 once per statement. Every iteration
  went through a `cp` to /tmp. THE ASK: `avra run` on a file the
  harness would treat as a program test should treat it as one.
- **THE PRODUCT AND THE PROBE GO STALE SEPARATELY.** A debug package
  built against `@std/avrac` keeps the OLD compiler's behaviour until
  it is rebuilt, and nothing says so — one round was spent concluding
  a fix had not worked when the probe was simply a generation behind.
  THE ASK: nothing structural; the entry belongs in the working
  discipline (below).

### SUGAR — a construct the language should have

- **AN IDEMPOTENT CONVERSION.** `Name(v)` where `v` already wears the
  name refuses ("argument 1 of `A` wants `int`, found `A`"), so a
  generic-ish helper that normalises its input cannot write
  `Rows(xs)` unconditionally. WANTING SITE: the first draft of
  `named_managed.av`'s `widened`. The ask is small — accept the
  identity conversion, or refuse it in its own words ("`xs` is
  already a `Rows`").
- **A PAIRED COMPREHENSION**, confirmed again (already filed, I3
  licences): `[f(j, p) for j, p in ps]` does not parse, so
  `seat_words` and three sites in this slice kept accumulator loops.
- **A `mut` METHOD ON A NAMED TYPE'S SHAPE WITHOUT AN IMPL.**
  `rows.push(v)` works; `rows.sorted()` does not exist because the
  LIST has no such verb. Not this slice's ask, but the named type
  makes the gap visible: a name is where a user would naturally hang
  the verb, and `impl Rows { … }` is the answer — which works today.
  Confirmation, not a new row.

### FEATURES — a capability, larger than sugar

- **A NAME OVER AN ENUM SHOULD FORWARD `match` AND `is`.** `type K =
  Color` declares, constructs and compares; `k is .Red` refuses
  cleanly. Forwarding needs `variants_of_type` and `fields_of_type`
  to see through, which also lets `K { … }` and `w with { … }` reach
  a shape the LAYOUT laws do not follow — so it is a slice, not a
  line. RECORDED TRIGGER below.
- **A NAMED CONSTRUCTION AT A `const` SEAT.** `seat(A(3))` is F2073:
  the settled-seat law reads the SOURCE, and `A(3)` is a call. The
  fix is to teach `literal_meta` that a named construction over a
  literal is source-spelled. RECORDED TRIGGER below.

### DEFECTS — the compiler blaming itself

All four were found IN THIS SLICE, by the red team, and all four are
fixed with a permanent case in `named_adversarial_test.av`:

- **A DOUBLE RELEASE AT THE IDENTITY PACK.** A fn answering a named
  value released the part and handed the caller freed memory. The
  ENGINES DISAGREED ON THE VALUE while agreeing on the verdict — `xq`
  evaluated, empty natively — and `AVRA_RC_GUARD=1` named it
  ("released an already-dead box"). CAUSE: `Ins.Pack` was read as a
  VIEW; the outermost scope's yield carries the reference the scope
  already holds, so a pack that owns nothing leaves the answer dead.
- **A ROW READING A RECEIVER IT COULD NOT SEE THROUGH.** `Counts.get`
  over `type Counts = Map<string, int>` answered the ABSORBING error
  type with NO diagnostic — a clean analysis that then wrecked the
  run ("defect: a non-string reached text"). CAUSE: `value_held` read
  `shape_at`, which answers `.Struct` for every named value.
- **A NULLABLE'S LAYOUT READ OFF THE BARE SHAPE.** `type Maybe =
  string?` took the scalar-pair representation and text came out of a
  register holding a pointer.
- **THE PROGRAM'S ANSWER LAW.** A named answer refused with "no text
  projection yet" though its value is an int.

### DOCTRINE — a law missing, misleading, or stale

- **A LAW IS NOT APPLIED UNTIL ITS LIST IS ENUMERATED.** The slice's
  own sentence names the READS — "a property, a method, an index, a
  `for` head, an interpolation hole" — and a LITERAL PATTERN is one
  and was not on the list, so `match id { 5 -> … }` over a `UserId`
  refused F2038 "a `int` never matches `UserId`". FOUND IN REVIEW,
  not by the red team, which had attacked every vocabulary a name can
  stand over and never written a pattern. THE LESSON: a law stated as
  a LIST is applied by ENUMERATING the sites, not by reading the
  list — the gap is invisible to anyone holding the same list.
- **A REFUSAL THAT NAMES A RELATIONSHIP THAT DOES NOT EXIST.** One
  voice served every mixed operand, so `A == B` (two names over
  `int`) said "a named type never mixes with its SHAPE" and offered
  `A(b)` — a wrap that cannot be honest, because `B` is not `A`'s
  shape. FOUND IN REVIEW. Three refusals now, chosen by what the
  OTHER side is. THE LESSON: when a voice takes one argument and the
  truth depends on two, it will be wrong on some pair — and the pair
  it is wrong about is the one nobody wrote a case for.
- **A CLOSER NEVER CONTINUES A LINE** — new, filed in CLAUDE.md.
  `>` was in the lexer's continuation set and closes a type argument
  list, so `type Rows = List<int>` swallowed the statement below it.
  No statement in the tree had ever ENDED in `>` (a trait's bodiless
  `fn a() -> List<T>` does, and parsed only because a `}` supplied
  its END), so the rule had never been tested.
- **A NAMED TYPE'S MARK IS MADE AT ITS DECLARATION** — the flat law's
  own declaration-ORDER hazard, one type over, filed in CLAUDE.md.
  The CLI signs types first and every probe was green;
  `analyze_source` types the entry first and refused every literal
  fill. ONE TREE, TWO ANSWERS — and the CLI is the instrument a lane
  reaches for first, so the hazard hides behind a green probe.
- **THE FLAT LAW'S COMMENTS WERE STALE THE MOMENT IT GENERALISED.**
  `flat_fields`, `mark_flat` and `unflatten` each said "a record of
  scalars, which rides REGISTERS and holds no reference" — true of
  every flat record that existed, and false of the first one that
  did not. Rewritten in the same change that generalised them.
- **A "VIEW" AND AN "OWNER" ARE NOT THE ONLY TWO ANSWERS.**
  `view_of` and `managed_dst` disagreed about `Extract` for as long
  as no flat record was managed, and the disagreement read as a bug
  in one of them. It was not: `Extract` IS a view and `Pack` IS an
  owner, and they share a shape only by accident.

### PERFORMANCE — a measured cost

- **THE SEE-THROUGH DOOR COSTS 0.1–0.2%**, measured. `make census
  CMD="check packages/std-cli"`, same compiler generation, HEAD's
  source as the control (stash, `make avra`, census, pop):

      control  19,581,050 retains  23,476,926 releases  14,867,956 list reads
      slice    19,609,090 retains  23,505,650 releases  14,898,556 list reads
      delta        +28,040 (+0.14%)   +28,724 (+0.12%)     +30,600 (+0.21%)

  The cost is one list index and a null test inside `element`,
  `carried`, `cell_inner`, `res_parts`, `arrow_parts` and
  `rides_pointer`. No allocation was added. Gate peak moved inside
  its usual band (679–802 MB across the slice's runs).

### PROCESS — the working discipline itself

- **KEEP: the front-end ladder, exactly as written.** `cp build/avra
  build/avra.pre`, build twice, `cmp`. The grammar change compiled
  happily on the first build and the `>` defect appeared only on the
  second — the "build that succeeded was the build that lied", on
  schedule.
- **KEEP: `AVRA_RC_GUARD=1` on a small native program.** It named the
  double release in one run, after the differential had already gone
  green on the interpreter. The guard is the only instrument that saw
  it.
- **ADD TO THE DISCIPLINE: A PROBE PACKAGE IS A PRODUCT TOO.** A
  debug package built against `@std/avrac` carries the compiler
  generation it was built with, and nothing says so. A round was lost
  reading a stale probe as evidence that a fix had failed. Rebuild
  the probe after every `make avra`, or treat its answer as dated.

## Feedback survey — 2026-09-13 (COMPTIME STATIC, comptime/static)

Three slices on acb3a93: static data for aggregate consts (025366f),
budgets from measurement (7846d89), package-namespaced diagnostic
kinds (uncommitted at survey time). Each red-teamed and reviewed;
probes name the base `comptime/static` unless said otherwise. NOT
SURVEYED: the templates lane's files, the sqlite packages beyond
their gated suite, any lane but this one.

### FRICTION — what cost time

- A `mut`-SEAT WRITE-THROUGH SURFACED AS A NUMBER, NOT A CHANNEL.
  The law-correct fix (open every `mut`-seat argument unique) trapped
  the product's own `check` with "index 304 is out of bounds (length
  303)" — an hour to learn the compiler's source rides that channel.
  EVIDENCE: H3b (this ledger); the pre-fix product checking the same
  source clean was the tell. THE ASK: a trap in the compiler's own
  body names the BODY it trapped in (a symbol beside the index), so a
  second-generation trap reads as "this body" rather than "the tree".
- `./avra test <subdir>` RUNS THE WHOLE PACKAGE SUITE. A measurement
  loop over 26 test subdirs ran the std-avrac suite 26 times and was
  killed by the low-memory guard (10 GB swap). EVIDENCE: 165 identical
  `settle:` lines per subdir in the measurement log. THE ASK: a subdir
  argument runs that module's cases alone, or the runner says at the
  top which suite it is about to run.
- A PACKAGE-ROOT TEST RUN DROPS ITS CHILDREN'S STDERR: `./avra test
  packages/std-avrac` printed no `settle:` line while a subdir run
  printed 165 — the sharded runner does not forward a child's stderr.
  THE ASK: forward it, or say the run is sharded.
- A PROGRAM TEST INSIDE A PACKAGE CANNOT BE BUILT ALONE: `./avra build
  <pkg>/src/…/tests/nested/nested.av` refused "move it into the entry"
  (the file reads as a module of the package); a copy in scratch
  built. THE ASK: `build` of a program-test file builds that program.
- `avra explain @name` AND `explain process` NEVER SAW THE CALLER'S
  PACKAGE: the `avra` shim `cd`s to the tree's root and `root_program
  (".")` analysed the tree, so `explain @deprecated` from
  packages/std-meta answered "no fn `deprecated` is declared in this
  package" on the old product too. FIXED with task 3: the shim exports
  `AVRA_CWD`, commands root at `here()`. Cost: two rebuilds and a
  debug line to see `files=0`. THE ASK: a command's "here" is a
  library verb, never a `.`.
- `Cell` IS A BUILT-IN TYPE NAME (F3008), so the static slot enum was
  renamed `Slot` after a full patch; F3008 fires only at check, not at
  the declaration. Cost: a rename sweep. THE ASK: none — the refusal
  was right; noting the name is reserved.

### SUGAR — a construct the language should have

- A NULLABLE SCALAR STRUCT FIELD (`{ steps: int? }`): F2008 "a struct
  field cannot hold this yet". WANTING SITES: language/manifest.av's
  `[lifted]` rows (resolved to defaults at read time instead), the
  static-data red team's `optfield` fixture. CLAUDE.md "The subset
  today" now carries the refusal. THE ASK: the pair repr in a slot (a
  two-cell layout, or a boxed pair) so a record can carry `int?`.
- UNARY MINUS ON A FLOAT LITERAL: `[1.5, -2.25]` is F2000 "`-` needs
  `int` operands, found `float`". WANTING SITE: consts/tests/
  static_shapes (spelled `0.0 - 2.25`). Base comptime/static.
- A FOLD THAT READS ITS OWN ACCUMULATOR (`built.push(box_val(b,
  built))`) has no comprehension form and is LICENSED I3 at
  interp.av's `static_val`. THE ASK: a `fold`/`scan` verb over lists.

### FEATURES — a capability, larger than sugar

- (LANDED 2026-09-14, `every_expr` in core/nodes.av) ONE COMPLETE
  EXPRESSION WALK. `post_order` walks
  `kids`, and `if`/`match`/`catch`/nullable arms/lambda bodies hide
  theirs; three consumers want the whole body: `runtime_read` (the
  F0900 defect below), `reads_settled_seat`, and the package-kind
  registry (`Program.kind_rows`, which therefore registers a
  conditional `refuse_as` only by being spoken). Recorded trigger in
  this ledger (the walk entry beside H3b). Owner unconfirmed.
- A KINDED WARNING CONSTRUCTOR: `refuse_as`/`refuse_as_at` exist; a
  warning with a kind is spelled as a literal `Diagnostic { …,
  warning: true, kind: "W1" }` today. THE ASK: `warn_as(kind,
  message)` in @std/meta — one line, when a warning wants a kind.
- `avra explain` OVER A PACKAGE KIND analyzes the package it stands in
  (a full analysis for one lookup). Fine today; the ask is the
  registry cached per workspace revision when explain runs inside an
  LSP.

### DEFECTS — the compiler blaming itself

- A CONST READING A RUN-TIME PARAMETER INSIDE A HIDDEN BRANCH:
  `fn g(n: int) -> int { const C = if true { n } else { 0 }  C }` is
  not refused F2074 and `./avra check` prints `error[F0900]: defect:
  a compile-time value did not cross as `int`` (F0900). Pre-existing on
  acb3a93; reproduced on comptime/static 2026-09-13. Fix: the
  complete walk above.
- H3b: A `mut` SEAT'S ARGUMENT IS NEVER OPENED (this ledger, beside
  H3): a const's box and another binding's list written through a
  `mut` local on BOTH engines; under static data the runtime now moves
  a laid-out buffer's cells out rather than freeing the binary's
  memory. Reproducer pinned in the entry.
- THE ROOT PACKAGE HAD NO NAME IN THE DECLARATION TABLE: `package_of`
  answered "" for a root module while the manifest named it, so a
  kind spoken by a root package's annotation stood bare, and giving
  the root its name in one read and not the other made the orphan-impl
  law refuse every impl in the compiler's own cli (a second-generation
  build refusing its own source). FIXED with task 3: `Decls.
  package_named` is the one read; `impls_test` and the cli build pin
  it.
- A SETTLED STRING HOLDING A NUL WAS TRUNCATED NATIVELY (eval 3,
  native 1): the string-constant seam measured with `strlen`. FIXED
  025366f — the length crosses the seam (`avra_llvm_build_text`);
  consts/tests/static_nul pins it on both engines.
- A STATIC MAP PAST 11 KEYS HUNG NATIVELY: the lazy index was sized 16
  regardless of keys. FIXED 025366f; consts/tests/static_map pins it.
- `[lifted] memory = 9223372036854775807` WRAPPED NEGATIVE and refused
  every settlement. FIXED 7846d89 (saturating MiB); manifest_test pins
  it.
- AN EMPTY OR NON-WORD KIND RENDERED `error[@acme/audit: ]`. FIXED
  (task 3): a kind is a word, F2079 speaks in place of the verdict.

### DOCTRINE — a law missing, misleading, or stale

- CLAUDE.md gained: static data's law and the second-generation-trap
  diagnostic step; the nullable-scalar-field subset entry. Design §4.4
  carries the measured budgets and the run; §4.5 the static-data
  landing; §7 q4/q5 decided.
- "A COPY IS A COPY" IS STATED FOR PLACES AND NOT FOR SEATS: the
  places doctrine (a write through a shared value clones) does not
  say that a `mut` SEAT's argument is handed as read, so a copy of a
  const handed to a `mut` seat writes the const. H3b names it; the
  doctrine line belongs beside the borrow law once H3 closes.

### PERFORMANCE — a measured cost

- STATIC DATA (`make census CMD="check packages/std-avrac"`, task 1's
  tree vs acb3a93): once reads 296,938 → 182,033; retains
  4,675,242,720 → 4,650,927,372; releases 4,844,261,186 →
  4,820,834,453. `AVRA_MEM_STATS=1` on a const program: every category
  0 MB (nothing allocated for the consts; the `.ll` holds the globals).
- THE ALWAYS-ON LIVE-BYTE COUNT (`avra_mem_live`, one add per alloc
  and free): `check packages/std-avrac` under the watchdog 34.29 /
  33.83 / 34.18 s with it on, 34.89 / 35.48 / 34.36 s with it gated —
  inside the noise; `objdump` shows no leaf grew a prologue (the add
  sits in bodies that already call malloc/free).
- BUDGET MEASUREMENT: 164 distinct successful settlements across the
  compiler's own checks and every package's test module; max 60,027
  steps and 445,314 bytes (a 5,000-element const list); the compiler's
  largest derive 3,824 steps (`Eq`), largest const 4,339 steps /
  120,517 bytes (`builtin_codes`). Defaults set at ×10.

### PROCESS — the working discipline itself

- KEEP: `cp build/avra build/avra.pre` before every risky build — it
  was the way back twice (the seat-fix trap; an accidental `git
  checkout` of the runtime while timing).
- KEEP: the pre-fix product checking the same source before reading a
  second-generation trap as the tree's (now in CLAUDE.md).
- CHANGE: `git checkout HEAD -- <file>` as a "restore" step in a
  measurement script reverted a whole slice's runtime changes; a
  measurement toggle is a patch and its inverse, never a checkout.
- CHANGE: the two-commit split of one tree by hunk (task 1 vs task 2
  shared six files) was done by inverting the second slice's patches
  by hand; commit each slice before starting the next when the task
  master allows.
- NOTED: a lane's loop that runs a package suite per subdir is the
  same bypass as three concurrent gates — it was serialized under the
  lock and still took the machine to the low-memory guard.

## Feedback survey — 2026-09-11 (lane/comptime)

The first run of `/feedback` (`.claude/skills/feedback`): a survey of
the two-tier namespace slice (S3f) — the compiler recovery, the
`@traced` materializer, and the debugging it took. Every row carries
its evidence; the base is `c48a4e6` unless noted. Counts: FRICTION 5,
SUGAR 4, FEATURES 4, DEFECTS 3 (all fixed in the slice), DOCTRINE 2,
PERFORMANCE 1, PROCESS 2.

### FRICTION — what cost time

- **A TRAP NAMES ITS SITE.** `index 5 is out of bounds (length 4)`
  (the `decl_ids` table) and `index 12 is out of bounds (length 12)`
  (the resolver's tables) aborted the compile with NO file, pass or
  declaration. Roughly two hours went to bisecting with hand-added
  `avra_eputs` prints; `lldb -o 'breakpoint set -n trap_bounds' -o bt`
  named it in minutes (`TypeCx.decl_of` -> `avra_array_get_owned` ->
  the unguarded read). THE ASK: `trap_bounds` / `missing_value` /
  `avra_trap` print the current PASS and the declaration in hand, and a
  `--trace-passes` breadcrumb keeps the last few pass entries reachable
  from a backtrace. (Routed: FEATURES "a trap breadcrumb".)
- **AN INTERNAL DEFECT NAMES ITS SYMBOL.** `defect: memo family 5
  reused missing key 0` (query/memo.av:148) — family 5 is `Resolved`
  and key 0 is file 0, but neither is named. THE ASK: the family's
  registered NAME and the key's symbol, not two ints.
- **A DEBUG PRINT NEEDS NO DECLARATION DANCE.** Adding `extern fn
  avra_eputs(line: string)` to `features/decls.av` was F3017
  "`avra_eputs` is declared twice in this module — here and in
  `language/interp.av`": the extern wall is MODULE-wide, and a
  `core`/`features` file cannot see the `language` module's row. THE
  ASK: one always-available debug verb (a `core`-level `say` builtin),
  so instrumenting a pass never edits an import or an extern.
- **A SCRATCH PROBE OF AN IMPORTED FEATURE NEEDS A PACKAGE.** `use
  @std.meta.{traced}` in a loose file is F3015 "this file is not in a
  package — `use` needs a root", so every probe of the annotation had
  to build a package dir (`tests/traced/`). THE ASK: a scratch/lone
  mode (`avra check --root <pkg> <file>`), or a synthesized root for a
  lone file that reaches a dependency by path.
- **THE BUILD ADVANCES ONE GENERATION, SILENTLY.** `make avra`
  compiles with the standing binary, so a front-end/lowering change
  needs a SECOND build (CLAUDE.md doctrine) — and the FIRST build
  PASSED while the new behavior was absent, which reads as "the fix
  did not work". CONFIRMS the doctrine; the ask is a one-line "built
  with generation N, source is N+1" notice.

### SUGAR — a construct the language should have

- **GROW A LIST TO SIZE.** `mint_generated` needs `decl_ids[f]` to
  reach a new statement: `by_stmt.concat(filled<DeclId?>(n -
  by_stmt.length, null))` (features/decls.av). THE ASK: `xs.resize(n,
  v)` (a List method) so a sized table extends in one verb.
- **A GUARD THAT STILL COUNTS ARMS.** The `is`-catch-all law
  (CLAUDE.md) forced `match effect! { .Declares -> …, .Records or
  .Validates -> false }` where `effect! is .Declares` was the obvious
  draft (features/annotations/check.av). THE ASK: a spelling that
  reads as a guard yet discharges the registry obligation — an
  equality over a payload-free enum, or an `is` the compiler proves
  exhaustive.
- **INTERPOLATE A VALUE, NOT ONLY A SCALAR.** Instrumentation wanted
  `${r.answer}` (a `MetaVal`); F2007 "an interpolation hole prints as
  a scalar or string, found `MetaVal`". THE ASK: a derived `Show` (S4
  `@derive`) reachable from interpolation, or a `--debug` form.
- **SHORTEN THE IMPORT WALL.** Every new helper edits a 40-name `use
  core.{…}` (language/workspace.av:17). THE ASK: a module-qualified
  reference or a glob form, so a helper's home does not cost a
  line-long edit.

### FEATURES — a capability

- **`avra explain` / `avra expand`** — wanted to SEE the generated
  twin's AST and IR; already S3g (docs/2026_09_09_COMPTIME_DESIGN.md).
  CONFIRMS the design; the survey adds the wanting site (debugging
  `mint_generated`).
- **DUMP ONE DECL'S IR WHILE ANOTHER IS BROKEN.** `avra ir` traps on
  a bad program, so the twin's IR could not be read to check the mint
  order. THE ASK: `avra ir <decl>` lowers only that declaration (or
  prints what it can), so a broken sibling does not hide a good one.
- **A TRAP BREADCRUMB ON EVERY PATH.** `avra_case_begin` is set only
  by language/test_run.av, so a trap under `avra run`/`check` names
  no case; the test runner proves the machinery works. THE ASK: every
  driver announces the declaration/statement in hand, so a wreck names
  where it died (FRICTION "a trap names its site", reused).
- **A KEEPER FOR COUNT-SIZED TABLES.** The slice's two bounds bugs
  were ONE class: a per-file table sized from `store.exprs.count()` or
  `store.stmts.count()` at pass start, then a GENERATED node grows the
  arena past it. THE ASK: a keeper that names a table born from a
  count that can later grow, so the third instance is caught by `make
  gate`, not by lldb.

### DEFECTS — the compiler blaming itself (all fixed in the slice)

- **`decl_ids` BORN BEFORE THE TWIN.** `decl_of` read past the table
  (`TypeCx.decl_of` -> `index 5 out of bounds (length 4)`); fixed by
  growing the table in `mint_generated`.
- **RESOLVER TABLES BORN BEFORE THE EXPANSION.** `bindings` sized to
  the pre-twin arena; fixed by materializing expansions in
  `resolved(f)` before the resolver sizes its tables and resolving the
  generated statements after the written ones.
- **`@traced([1, 2])` -> `defect: memo family 5 reused missing key
  0`.** Fixed into F2067: a `Declares` annotation reaches literals
  only.

### DOCTRINE

- **THE DECLARES PHASE LAW** (new this slice): a name-generating
  annotation runs inside the resolve its generated names serve, so its
  arguments cross from the parse tree alone. Filed at CLAUDE.md "The
  subset today", the design doc's S3f, and the sugar backlog.
- **PROFILE, DON'T REASON, proved again.** Two hours of reasoning
  about which table could not name it; the `lldb` backtrace did, in
  minutes.

### PERFORMANCE

- **THE GATE'S PEAK** — `watch: peak ~600 MB` for `make gate` (the
  compiler compiling itself). Recorded, not a new finding; the
  instrument is `tools/watch.sh`.

### PROCESS

- **THE SEED IS A FOSSIL UNLESS REFRESHED.** Recovery took the
  bootstrap ladder (CLAUDE.md, ROADMAP). `make seed-check` is now in
  the gate and `make clean` preserves `build/avra`. CONFIRMS.
- **`/feedback` IS A SKILL NOW.** This section is its first run; the
  survey lands with the change that ran it.

### ADDENDUM — S3g (`explain @name`), same day

- **A CONDITIONAL PROGRAM NEED HAS NO CLEAN SHAPE.** `avra explain`
  takes a registry key OR needs a program (`@name`). `phased`/`on_program`
  read the `file` arg (`explain` has none), and `phased`'s act is
  `fn(Program) -> Result<int,string>` — it cannot receive the name
  argument. The workaround: `root_program(".")` and a name-only fn.
  THE ASK: a command helper for "a program when the argument asks for
  one", or a `phased` that passes the command's own args through.
- **DOC COMMENTS ARE NOT STORED.** `avra explain @name` should print
  the annotation fn's doc comment (§4.6), but the lexer drops them.
  THE ASK: a doc-comment side table on the declaration.
- **`explain @name` PRINTS THE SIGNATURE ALONE**, which is honest (the
  signature IS the effect) but the doc half is owed. REMAINING S3g:
  stored doc comments, now that `avra expand` + the node source
  printer landed at `bc5a7a7`.
- **A SAME-FILE `Declares` ANNOTATION WAS SILENT, AND IS REFUSED NOW.**
  The provider-only guard (`declared_work`) skipped an annotation fn
  that stood in the file it annotated — no twin, no diagnostic (found
  writing the S3g test). Now `check_annotation` refuses it: "`gen`
  generates declarations and stands in this file — declare the
  annotation fn in another file". The boundary is honest: expanding
  needs the annotation fn's signature, which needs this file's names,
  which are the very thing being resolved.

### ADDENDUM — S3g node source printer, same day (`bc5a7a7`)

- **FEATURES — `AVRA EXPAND` NOW SHOWS THE FILE, CLOSED.** The earlier
  survey's request is landed: `language/source_text.av` exhaustively
  projects the AST, and `Program.expanded_source` inserts generated
  declarations immediately after their annotated origins. Evidence:
  `./avra expand …/annotations/tests/traced/src/main.av` printed the
  written `sum`, its provenance, the
  complete `sum_traced` wrapper, and the final expression.
- **DEFECTS — TWO PRECEDENCE WRONG ANSWERS, FIXED.** Structural
  round-trip tests first failed for `(-3).magnitude` (printed as
  `-3.magnitude`) and `(a & b) | (c ^ d)` (printed without the groups
  the mixed-bitwise law requires). `numeric` now gives a negative
  folded literal unary precedence, and mixed bitwise left children
  retain their group. Both witnesses are permanent in
  `language/tests/source_text_test.av`.
- **DOCTRINE — A SOURCE PROJECTION PROVES ITS TREE, NOT ONLY ITS
  TEXT.** The printer suite reparses every fixture, reaches a textual
  fixed point, and compares top-level statement fingerprints before
  and after. This caught semantic regrouping that a pretty golden
  alone would miss. The direct value-call witness also pins `(f)(1)`
  so it never becomes declaration call `f(1)`.
- **FRICTION / PERFORMANCE — CONFIRMED, ALREADY ROUTED.** Targeted
  printer specs took about 20.5 s and peaked near 318 MB under
  `tools/watch.sh`, while emitting the already-recorded F2047 warning
  flood; the final gate peaked at 572 MB. F2047 remains routed to S2,
  and the survey adds no duplicate backlog row.
- **PROCESS — THE IDIOM KEEPER PAID FOR ITSELF.** The first gate found
  11 violations in the new slice; all were removed with no baseline
  increase, including quadratic interpolation assembly (now the
  `@std/text` builder) and a hand-rolled DeclId comparison (now
  `same_decl`). `make gate`: 2236/2236 compiler tests and 88 compiler
  programs, plus both annotation programs, green.
- **SUGAR, NEW FEATURE ASKS, OWNERSHIP, REFUSAL QUALITY:** swept; no
  new evidence beyond the already-filed doc-comment, trap-breadcrumb,
  and count-sized-table asks. The next S3g work is stored doc comments.

### ADDENDUM — S3g stored doc comments, same day (`f868c2f`)

- **FEATURES — DOC COMMENTS ARE STORED, PRINTED, AND EXPLAINED.** The
  lexer retains a contiguous declaration-leading `///` group as its
  LINES with the anchor `before` (the first token after the group);
  `NodeStore.docs` holds it per statement, `statement_after` lands the
  anchor on the earliest statement beginning at or after it, the source
  projection re-emits the group above its declaration, and
  `avra explain @name` appends it to the signature. The doc rides the
  statement fingerprint, so a doc-only edit cannot be cut off by the
  parsed-program memo. Evidence: `avra expand` reproduces all 31 doc
  lines of `@std/meta/src/meta.av` and all 321 of
  `language/workspace.av`, and a doc-bearing program is `eval == native`.
- **DEFECTS — TWO SILENT DOC LOSSES, FOUND BY THE RED TEAM AND FIXED.**
  (1) An EMPTY doc line vanished: the printer re-split a joined string,
  and `split` drops a trailing empty segment while `""` splits to `[]`,
  so `///` alone and a trailing `///` line were lost — the group is now
  stored as lines, never round-tripped through a join. (2) An ordinary
  comment between a doc group and its declaration DETACHED it, so
  `/// doc` + `// LICENSED I23: …` + `fn` lost the doc — measured on the
  compiler's OWN `grammar/lexer.av` (2 lines) and `features/mod.av` (5).
  A comment is now transparent; only a BLANK line (or a non-declaration
  token) detaches. `avra expand` on `grammar/lexer.av` now reproduces
  all 122 doc lines (was 120). Witnesses:
  `language/tests/docs_adversarial_test.av`, `grammar/tests/lexer_test.av`,
  `language/tests/source_text_test.av`.
- **DEFECT (OPEN, ATTRIBUTED, PRE-EXISTING AT `eb35bea`) — `avra
  expand` ON A STATEMENT-LESS PROGRAM TRAPS.** `avra: index 0 is out of
  bounds (length 0)`, exit 2, where the command's own guard says "the
  program is empty". Reached by an empty file, a file holding only a
  doc comment, an unclosed interpolation hole, and a CR-only file whose
  single line is a comment. Attributed by stashing the doc work and
  rebuilding at `eb35bea`, where it reproduces identically. THE ASK:
  `Program.entry_file` answers null when no file was parsed, so
  `expand`'s existing message speaks.
- **LIMITATION, RECORDED (A DEADLINE, NOT A STYLE CHOICE) — DOCS WITH
  NO TABLE ARE DROPPED.** A module's `//!`, an enum variant's and a
  struct field's `///` are not retained: they are not
  declaration-leading, and the printer walks statements. Measured over
  the compiler's own source: `core/nodes.av` loses 158 doc lines (all
  variant docs) and `features/mod.av` 5. The day `fmt` consumes the
  projection it will DELETE those lines. Pinned by the
  `docs_adversarial_test.av` row that must fail when the tables land.
  (No `docs_adversarial_test.av` exists in this tree — the pin is on
  the docs campaign's branch or unwritten; a deadline whose keeper
  cannot be found is unpinned. Confirm with the DOCS lead first.)
- **DOCTRINE — A FLAT JOIN IS NOT A ROUND TRIP WHEN THE TAIL IS EMPTY.**
  An instance of CLAUDE.md's arity law: `join("\n")`/`split("\n")`
  round-trips only while no line is empty; the empty tail is what
  `split` spends, so the lens was discarded and the join kept as the
  fingerprint key alone.
- **SURVIVED (no finding).** 57 attack programs: every `///`-prefix
  position (`/`, `//`, `//!`, `////`, `/// `, `///\t`, trailing after
  tokens, inside `(`/`[` continuations, CRLF, CR-only, EOF, inside a
  string, inside an interpolation hole); every cross-feature seat (fn
  body, `while`/`match` arm, impl, trait, `spec`, `const`, `extern`,
  `once`, `static`, a local `type`, struct/enum members); doc text
  carrying keywords, `${}`, braces, quotes, semicolons, unicode and
  trailing spaces (opaque and byte-preserved); ownership
  (`AVRA_MEM_STATS=1 ./avra check` settles every category to zero at
  exit); and refusal quality (zero `defect:` lines). One class is N/A:
  a comment takes no value, so "every slot, every wrong type" has no
  seats.

## Feedback survey — 2026-09-11 #2 (lane/comptime, S3h–S4f)

The second `/feedback` run: the slice that took `@deprecated` through a
working `@derive(Show, Eq)` — quote literals, `${}` holes, generated
source parsed into the asking file, and two shipped traits. Every row
carries its evidence; the base is `c451cb0` plus this lane's commits
unless noted. Counts: FRICTION 4, SUGAR 2 (+3 confirms), FEATURES 3,
DEFECTS 4 (all fixed in the slice), DOCTRINE 4, PERFORMANCE 0 (empty),
PROCESS 4.

### FRICTION — what cost time

- **A POISONED PRODUCT CANNOT REBUILD ITSELF, AND `make bootstrap` IS
  NOT A CLEAN-BINARY TARGET.** A probe (`avra_trap`) left in an
  analysis path fired during the compiler's SELF-compile, so `make
  avra` aborted and left `build/avra` holding the probe; every retry
  then aborted the same way. `make bootstrap` links the seed and THEN
  runs `make avra`, so it too produced the probe binary. The only way
  back was to link the seed by hand and keep it: `clang -w -O1
  bootstrap/seed.ll build/llvm_wrapper.o build/avra_runtime.o
  -L$LLVM_PREFIX/lib -lLLVM -o build/avra.clean`, then `cp
  build/avra.clean build/avra` before each build. Cost: ~20 minutes
  and several false "the fix did not work" reads. CONFIRMS the
  `cp build/avra build/avra.pre` doctrine; THE ASK: a `make recover`
  that links `bootstrap/seed.ll` and STOPS (no `make avra`), so a
  clean compiler is one command. **LANDED** in this slice: `make
  recover` is that target, and `make bootstrap` now depends on it.
- **A DEBUG TRAP IN AN ANALYSIS PATH IS A TRAP ON EVERY BUILD.** The
  compiler walks its own passes while compiling itself, so
  `avra_trap("marker")` placed in `computed_marks` aborted the build.
  THE ASK (the prior survey's "a debug print needs no declaration
  dance", trap variant): a `core`-level debug verb that is a no-op
  unless an env flag is set, so instrumenting a pass never breaks
  `make avra`. **LANDED** in this slice: `core.debug` (`core/debug.av`)
  over the runtime's `avra_debug`, live only under `AVRA_DEBUG`
  (verified: a probe at `built` printed under `AVRA_DEBUG=1` and was
  silent without).
- **THE IDIOM BASELINE IS BY SITE, SO ANY NEARBY EDIT RE-FILES OLD
  DEBT.** Refactoring `declared_work` moved a pre-existing I26
  violation and `make idioms` reported it as NEW
  (`workspace.av:948`, later `check.av:13`); no violation had
  changed. CONFIRMS the baseline's design (CLAUDE.md: "sites, never
  counts"); THE ASK: key a baseline entry by a stable identity (fn
  name + the offending expression's text) so a line shift is not a
  new debt.
- **A KERNEL DEFECT NAMES NEITHER FAMILY NOR KEY.** Hit again this
  slice: `defect: memo family 5 reused missing key 0`. It cost a
  hand-built mental model until `lldb -o 'breakpoint set -n
  avra_trap' -o bt build/avra` named the path (`crossed_fields` ->
  `fields_of_type` -> `sig` -> `type_cx_for` -> `resolved`).
  CONFIRMS the prior survey's row; the family was `Resolved`, key
  file 0, and neither word appeared.

### SUGAR — a construct the language should have

- **A LIST SEAT FILLED BY MANY ARGUMENTS.** `@derive(Show, Eq)` should
  hand one list seat two traits, but an annotation is arity-exact, so
  `@std/meta.derive` takes ONE `Trait` and stacks. Wanting site:
  `packages/std-meta/src/meta.av` (`derive(what: Named, tr: Trait)`).
  FILED in the sugar backlog below; confirms.
- **ESCAPING A LITERAL `${` IN A GENERATED STRING MISDIRECTS.** A
  derive that wants the GENERATED code to interpolate writes
  `"\${self.${f.name}}"`; forgetting the `\` is F3000 "`self.` is not
  defined" pointing at the derive, not at the stray `${`. Wanting
  sites: `packages/std-derive/src/derive.av`,
  `packages/std-meta/src/meta.av`. THE ASK: a diagnostic at a `${`
  with no binding that names the escape (`\${`), or a quote-aware
  string. FILED in the sugar backlog below.
- **TYPE ALIASES** would let `Named` and `Trait` share one shape
  (`packages/std-meta/src/meta.av:73,76`). CONFIRMS the subset entry;
  no new evidence.
- **A GUARD THAT STILL COUNTS ARMS.** CONFIRMS the prior survey's row
  (`act is .Derives` beside a two-arm `match`); no new evidence.

### FEATURES — a capability

- **A LONE-FILE ANNOTATION PROBE.** `use @std.meta.{derive}` in a loose
  file is F3015 "this file is not in a package", so a probe of the
  derive machinery built a package and, for the spec harness, a COPY
  of `@std.meta` (`annotations_adversarial_test.av`'s `packaged`
  vendor string). CONFIRMS the prior survey's ask; adds the
  wanting site and the copy-the-dependency smell.
- **A `TRAIT` META VERB.** S4a makes a trait's associated fn callable
  through a TYPE (`P.derive(3)`), but not through the trait itself
  (`Show.derive(t)`); `@derive` dispatch was landed as a compiler
  `.Derives` effect instead. THE ASK: if the design keeps `tr.derive(t)`
  as a meta verb, a way to call a trait's associated fn on a meta
  value; otherwise the effect is the seam and the design should say so.
- **`avra expand` SHOWS THE DERIVED SOURCE — TRUE BY CONSTRUCTION.**
  Because generated code is parsed INTO the asking file's store, the
  landed source printer shows it with no new work. No ask; recorded
  as a win for the parse-into-store choice.

### DEFECTS — the compiler blaming itself (all fixed in the slice)

- **THE CROSSING ASKED A SIGNATURE DURING RESOLVE.** `crossed_fields`
  / `crossed_variants` used `fields_of_type`/`variants_of_type`
  (a signature) to read a type's members; a `Type`-receiver derive
  runs inside the resolve it serves, so this re-entered the file's
  own resolve: `defect: memo family 5 reused missing key 0`. Fixed by
  reading `declared_fields`/`declared_variants` and the written
  `TypeRef` spellings — which is what the crossing's own doc claimed.
  Reproduction: `@derive(Show)` with a `Type`-receiver trait on a
  struct, `./avra check` of the derive test package.
- **TWO DERIVES ON ONE TYPE MINTED ONE IMPL.** The generated key for an
  impl was `generated$<file>$Point$$impl` for BOTH `Show` and `Eq`, so
  the second reused the first's DeclId and `eq` never registered —
  `@derive(Show) @derive(Eq)` silently produced only `show`. Fixed by
  carrying the generated source's fingerprint in the key.
  Reproduction: the `derive` program test before the fix
  (`Point has no method eq`).
- **`@derive` WAS A SILENT NO-OP** for an argument that is not a trait
  and for a trait that declares no `derive`. Fixed as F2072.
  Reproduction: `@derive(Point)` (a record) compiled clean before the
  law.
- **A BUILTIN HAS NO STATEMENT RECORD.** `computed_marks` read
  `p.store.annotations_of(x.stmt)` for a builtin/synthetic
  declaration, trapping `index 0 is out of bounds (length 0)` during
  the self-compile. Fixed with a `stmt.index` guard; a builtin is
  unannotated by construction.

### DOCTRINE

- **A DOC THAT WAS RIGHT AND CODE THAT DRIFTED.** `crossed_decl`'s doc
  said "Reads the PARSE store only: an expanded sibling is generated
  before this file's typed facts exist", while the body asked the
  signature. The doc was the law; the code was the defect. THE LESSON
  (CLAUDE.md-shaped): a crossing that runs INSIDE resolve must read
  the parse tree, never a signature — encode it as a review question.
- **A GENERATED DECLARATION IS KEYED BY ITS SOURCE, NOT ITS TARGET.**
  Two derivations on one type are two declarations; a target-keyed
  generated key silently drops one. Adjacent to CLAUDE.md's
  flat-concatenation/arity law: the key must carry the discriminating
  value.
- **THE PROVIDER LAW GENERALIZES.** "A Declares annotation's fn stands
  in another file" became "a `@derive` trait's `derive` stands in
  another file" (F2072 covers the trait half; the same-file half
  speaks). Filed in the design doc's S4 status.
- **A SILENT NO-OP IS WORSE THAN A REFUSAL.** `@derive(NonTrait)` and
  `@derive(NoDerive)` both did nothing; the boundary must speak
  (F2072). This is the annotation-level instance of "a check that
  examined nothing is not a check that passed".

### PERFORMANCE

- EMPTY. No new measurement this session; `make gate` peaked 556–688
  MB across runs (instrument `tools/watch.sh`), already recorded.

### PROCESS

- **THE RECOVERY PROTOCOL NEEDS A CLEAN-BINARY TARGET.** See FRICTION
  row one: `cp build/avra build/avra.pre` works only if a clean
  `build/avra` WAS saved; a source that traps at self-compile has no
  such binary on a cold tree. `make recover` (seed link, stop) is the
  missing rung.
- **PROBE-FIRST PAID, AGAIN.** `./avra check`/`./avra run` on a scratch
  file confirmed `P.derive(3)` (S4a), `@uses(Show)` (S4b), and
  `quote { a${n}b }` (S4f) in seconds each, before any test package
  existed. Confirms.
- **THE IDIOM KEEPER IS THE CHEAPEST REVIEWER.** `make idioms` (24–25
  MB peak, sub-second source scan) caught every nullable-local and
  unused-parameter drift this slice; each fix was a guard-once
  rewrite. Confirms.
- **A COMMIT MESSAGE WITH BACKTICKS NEEDS `-F`.** `git commit -m
  "...`Decls.marks`..."` ran the backticks through the shell and
  mangled the message; `git commit --amend -F - <<'MSG'` is the
  safe form. (Agent-tooling, not the tree — recorded once.)

### NOT SURVEYED

No runtime, backend, LLVM, ownership, or performance work happened
this slice; the std packages other than `@std/meta`/`@std/derive`, the
sqlite/process/http lanes, and S5 (`const` seats) were not opened. The
survey is bounded to the comptime lane, `c451cb0..877bf6c`.

## Feedback survey — 2026-09-12 (lane/comptime, S5a)

The `/feedback` run for the seat-mark slice: the `const` seat mark, and
the unified `SeatMark` channel it landed on. Base `f33e64e` plus this
lane's four commits (`01e03f4`, `c3dc862`, `2cd3dff`, `a0e6686`);
every row quotes its command. Counts: FRICTION 3, SUGAR 1 (+1 confirm),
FEATURES 2, DEFECTS 0 (empty), DOCTRINE 2, PERFORMANCE 0 (empty),
PROCESS 2. Top three by cost: the front-end generation ordering (one
wasted gate cycle + a confusing refusal), full-suite granularity when
only four cases were new, and the param-grammar repetition (design
debt, filed).

### FRICTION — what cost time

- **A FRONT-END ARITY CHANGE FAILS ON THE NEXT GATE, IN A USER'S
  FIXTURE.** `TypeLit.Fn` gained a fourth field (`consts`), so the
  `.type(…)` desugaring emits `.Fn(params, muts, consts, ret)`; the
  gate then refused `fns`/`type_lit` with "`.Fn` takes 3 arguments,
  found 4" — a correct refusal, but its SITE was the test's own
  `Spelling` enum, not the contract that moved. Cost: one gate cycle
  and a re-read to find it was the desugaring. CONFIRMS CLAUDE.md's
  generation law; THE ASK: the `interned` receiver's variant SHAPES
  (today the 3-arg `Fn`, and now 4) are an undocumented contract — see
  DOCTRINE below.
- **THE LANE BRIEF NAMES `./avra test <dir>`, SO A SINGLE SPEC RUN WAS
  NOT KNOWN.** Four new `const` cases cost a full `std-avrac` run
  (2275 cases, ~40s) each iteration; `./avra test
  packages/std-avrac/src/features/fns/tests/fns_test.av` runs 57/57 in
  a moment. Probe (base `c3dc862`): the file form exists and works.
  THE ASK: name the file form beside the directory form in the brief
  and in CLAUDE.md's test recipe.
- **A FRONT-END CHANGE RESTRICTED TO TESTS NEEDS NO GUARD COMPILER.**
  The `const` params appeared only in `*_test.av` files, and `make avra`
  does NOT compile test files, so the standing binary built the new
  grammar with no `guardN` dance; the tests then ran under the fresh
  binary. THE ASK: state the carve-out in the brief's gotcha list (see
  PROCESS).

### SUGAR — a construct the language should have

- **A REUSABLE `param` GRAMMAR RULE.** Every param list spells
  `( "const" )? ( "mut" )?` by hand — 10 sites
  (`fns/mod.av:33-35`, `impls/mod.av:50-52`, `closures/mod.av:24-25`,
  `expr_spine/mod.av:36`) — while the LOGIC is one place
  (`marked_seats`). The DSL has no parameter rule the fragments can
  reference. Filed in the design doc's queue as a leave-alone with its
  trigger (a THIRD mark or a new param-taking form); re-filed here per
  the routing rule, wanting site named. THE ASK: a `param` rule whose
  builder answers `List<Param>`, so the window alignment dies with it.

### FEATURES — a capability, larger than sugar

- **S5b + S5c — settled seats widen `Sub`, and fold per instantiation.**
  Today a `const` seat is a TYPE contract with no call-site
  enforcement: `matches(compute(), s)` is accepted, because the
  settlement law is not landed. The seams, mapped so the next lane
  does not re-derive: `Sub` (`features/contract.av`), its record
  `record_subst` (`features/facts.av:192`), the name/mangle
  `symbol_at`/`wanted`/`mangle` (`language/lower_state.av:45`,
  `language/lower.av:448`), the call entry `dispatched_call`
  (`features/fns/check.av:87`), the view `viewed`
  (`features/contexts.av:275`). S5b widens `Sub` and the mangling; S5c
  binds the seat's value in the unit so `const prog = compile(pattern)`
  folds. Queued in the design doc.
- **A SINGLE-SPEC test filter.** The file form covers one FILE; there
  is no way to run one `given`/`then` (the `fns_test.av` run is 57
  cases). Low cost, real loop value for a red team iterating one
  class. THE ASK: `avra test <file> --filter <substring>`.

### DEFECTS — the compiler blaming itself

EMPTY. No `defect:`, `avra_trap`, wrong answer, or engine divergence
in the slice: `./avra check` refused in its own words, the differential
`const_seat` program read eval == native == expected, and the red team's
~20 programs produced no crash.

### DOCTRINE — a law missing, misleading, or stale

- **THE `.type(…)` RECEIVER'S VARIANT SHAPES ARE AN UNDOCUMENTED
  CONTRACT.** A user `interned` receiver matches the compiler's
  desugaring by variant name and arity (`Fn`, `Map`, …); S5a changed
  `Fn` from 3 to 4 payloads, and the only place that records the
  contract is `features/expr_spine/type_lit.av`'s builder. THE ASK:
  document the surface (the variant names and their arities) beside
  the type-literal docs, so the next shape change is not archaeology.
- **CONFIRM: CLAUDE.md's "`const` in a MODULE file … F0902" is stale.**
  The design doc's S5 queue says a module's `const` is already accepted
  and names that entry. UNVERIFIED here (needs a two-file package
  probe); filed as a question, not a finding. CONFIRMED and rewritten
  2026-09-13 (comptime/const): a module const is a declaration.

### PERFORMANCE — a measured cost

EMPTY / NOT MEASURED. The slice is representation-neutral (a `List<bool>`
became a `List<SeatMark>`; no algorithm changed), so no `census` was
run. The gate's peak stayed in its established band (671-807 MB across
the four runs). A `census` of the seat-mark readers would be measuring
the instrument, not the change.

### PROCESS — the working discipline itself

- **`make avra` EXCLUDES TEST FILES.** The front-end generation gotcha
  ("a new syntax the compiler reads cannot be built by a binary that
  predates it") has a carve-out: syntax used ONLY in `*_test.av` does
  not block the build, because tests are compiled later by `make test`.
  Evidence: `make avra` green at `c3dc862` with `const` params present
  only in tests. THE ASK: add the carve-out to the brief's gotcha list,
  so a lane does not reach for the `guardN` protocol needlessly.
- **KEEP: the committed-seed + `make recover` backstop was not needed.**
  Every build was green; `cp build/avra build/avra.pre` was taken once
  as insurance and never used. A clean slice is a real result.

---

## Feedback survey — 2026-09-12 #2 (lane/comptime, S5b)

The `/feedback` run for the settled-seat slice. Base `6ff814b` plus
this lane's two commits (`001259c`, `572456c`). Counts: FRICTION 2,
SUGAR 0 (empty), FEATURES 1, DEFECTS 0 (empty), DOCTRINE 1,
PERFORMANCE 0 (not measured), PROCESS 1. Top by cost: the per-unit
settlement input S5c needs (found, not filed anywhere), then the
idiom gate's first-draft catch (the gate working).

### FRICTION — what cost time

- **THE SETTLEMENT MACHINERY IS SINGLE-UNIT BY CONSTRUCTION, WHICH IS
  S5c'S WHOLE PROBLEM.** `settlement_of`/`isolated`
  (`language/workspace.av:793`) lower a const's initializer as a
  standalone program with `Wanted { sub: null, root }`, so a `const`
  inside a specialized body (`const prog = compile(pattern)`) is
  lowered WITHOUT the unit's settled-seat values: the parameter has no
  binding in a params-less root, and `run_settle` has nothing to read.
  Cost: mapping S5c to the mechanism took reading three layers
  (`defined_reg` → `jobs.settle` → `isolated`), and the design doc's
  queue did not name this seam. THE ASK: S5c threads the unit's
  settled values into the isolation — `Wanted` gains a settled-seat
  environment (the values, not only `Sub.consts` fingerprints), and
  the substituted initializer is what gets isolated. Filed in the
  design doc's S5c pick-up map.
- **THE IDIOM RATCHET CAUGHT THE FIRST DRAFT.** `const_seats` shipped
  with an unread `e` param (I23) and `symbol_at`/`dispatched_call`
  with a nullable local forced open 3+ times (I26); `make gate`
  refused all three and named the lines. CONFIRMS the gate's value —
  no user-visible cost, one build cycle. No ask.

### FEATURES — a capability, larger than sugar

- **S5c — per-unit folding.** The last S5 piece: inside a unit a
  settled seat IS a const, so its dependents fold and both pinned S5b
  boundaries (forwarding a settled seat; an aggregate literal inline)
  lift. Depends on the per-unit settlement input above; queued in the
  design doc with its seams.

### DOCTRINE — a law missing, misleading, or stale

- **A RECORD FIELD ADDED WITH A DEFAULT IS THE BREAK-FREE WAY INTO AN
  EXISTING CURRENCY.** `Sub` gained `consts: List<string> = []`, so
  every existing `Sub { target, args }` construction compiled
  untouched, and only the sites that READ the new field changed. Worth
  recording beside the `TypeRef` default-field hazard: a default can
  drop silently on RECONSTRUCTION, but it lets a new field land without
  a 5-site sweep when the field is genuinely additive. (No file: it is
  a note for the next currency change.)

### PROCESS — the working discipline itself

- **KEEP: a call-site law (F2073) landed in the SAME slice as the
  mechanism it guards.** S5b keys units by VALUE, so a runtime value at
  a settled seat had to refuse at once; deferring the refusal would have
  made the stored fingerprint a lie. The staged slices did NOT force a
  staged law here — worth keeping as the default when a mechanism makes
  a value meaningful.

---

## Feedback survey — 2026-09-12 #3 (lane/comptime, S5c)

The `/feedback` run for the per-unit folding slice (base `0179e9f`
plus `8c487e7`, `419d29a`). Counts: FRICTION 3, SUGAR 0 (empty),
FEATURES 1, DEFECTS 1 (a P1 wrong answer, fixed), DOCTRINE 1,
PERFORMANCE 0 (not measured), PROCESS 2. The top finding is the
DEFECT: a `const` that read a PLAIN parameter was silently
mis-settled and cached.

### DEFECTS — the compiler blaming itself

- **A CONST THAT READ A RUN-TIME PARAMETER ANSWERED A WRONG VALUE,**
  SILENTLY. `fn f(x: int) -> int { const y = x + 1; y }` settled `y`
  from an uninitialized register and cached it: `f(10)` answered `2`,
  `f(3) + f(5)` answered `4`, `f(1)+f(2)+f(3)` with `x + 10` answered
  `60`. No diagnostic, both engines agreeing on the wrong number. The
  settlement had no notion of which parameters it could read, so it
  read `Reg{i}` for a param that was never a register in a params-less
  root. FIXED in S5c: a const may depend only on its fn's `const`
  seats, and any other parameter refuses F2074 "a const cannot read a
  run-time parameter". THE LESSON: an isolated computation over a
  subtree must know its FREE VARIABLES — "the initializer lowers as a
  program" said nothing about which of the body's names exist in it.

### FRICTION — what cost time

- **A SILENT OFF-BY-ONE SURVIVED ONE RED-TEAM ROUND.** `call_seats`
  tested `settled_mark(marks, j)` where the argument fills `base + j`,
  so every free-fn case passed and every METHOD case carried no value
  (and a gap would have folded). It surfaced only through the debug
  instrument (`core.debug`, S4) printing `subnull`/`seats`/`marks`:
  the F2074 refusal looked like a law failure, not an index bug. THE
  ASK: none — it is the red team's second round, doing its job.
- **THE IDIOM KEEPER READS A `quote { }` BODY AS CODE.** Confirmed
  again: converting one test to `quote` produced 11 false I23s. Filed
  in the sugar backlog with the two asks; the tests keep escaped
  strings until the keeper learns quote bodies.
- **A MEMO KEY AND THE ARTIFACT IT NAMES DESYNCED.** The settlement
  was keyed per unit while the materialized const unit was named by
  the plain statement, so the first unit's folded value served every
  other (`x!ay!b` came back `y!ay!b`). Fixed by one `settled_symbol`
  for both; the law is pinned in CLAUDE.md.

### FEATURES — a capability, larger than sugar

- **S5 REFINEMENTS.** Forwarding a settled seat to another fn, and a
  direct aggregate literal at a settled seat, still refuse; both want
  the value carried through the OUTER unit's template. Queued in the
  design doc.

### DOCTRINE — a law missing, misleading, or stale

- **AN ISOLATED COMPUTATION OWES ITS FREE-VARIABLE LAW.** S1's "a
  const's initializer lowered as a program of its own" was silent on
  parameters, and silence became a wrong answer. Recorded as the
  CLAUDE.md memo-key law's sibling paragraph and in the design doc.

### PROCESS — the working discipline itself

- **`core.debug` (S4) EARNED ITS KEEP.** The receiver off-by-one was
  invisible from the source; one temporary `debug` line plus
  `AVRA_DEBUG=1` named it in a single build. KEEP: the debug verb
  reaches any module, is inert without the flag, and never breaks the
  self-compile.
- **THE COMMITTED `build/avra.pre` RECOVERY WAS READY, NOT USED.** The
  S5c slice had a poisoned-binary scare earlier (the eager `seat_names`
  cross-file crash in the S5b review) and recovered cleanly; S5c
  itself never needed it. A clean slice, again.

---

## Feedback survey — 2026-09-12 #4 (lane/comptime, S1 `export const`)

A short survey for the slice that made an exported top-level `const`
a declaration (base `bea9e9f` plus `93eff83`). Counts: FRICTION 2,
SUGAR 0, FEATURES 0, DEFECTS 0, DOCTRINE 1, PERFORMANCE 0,
PROCESS 0.

### FRICTION — what cost time

- **A DECLARATION-KIND WIDENING IS A WHOLE-TREE SEMANTIC MOVE.**
  Adding `DeclKind.Const` broke every exhaustive `DeclKind` match (8
  sites, by design) AND — the expensive half — changed
  `declared_kind`/`is_declaration` for EVERY `const`, including
  NESTED ones, so a fn body's `const prog = compile(pattern)` became
  a "declaration" its own walk skipped (`index 0 out of bounds
  (length 0)`). The fix: admit a const Decl ONLY for an EXPORTED
  top-level const, and leave `declared_kind` a projection over the
  STATEMENT (it has no top-level context) — `admit`, `runtime_stmts`
  and `runs_at_top` apply the position test. THE LESSON: a store
  projection asked "is this a declaration" cannot know WHERE the
  statement stands; the admit and run walks can, so the position test
  lives there.
- **THE CONST TYPE IS ASKED AND ENSURED, NOT STORED LOCALLY.** A
  cross-file read needed `decl_type_of` to answer a Const declaration
  from the shared const-type query, and that query had to type the
  const's OWN declaration (a const left Main's statement list, so
  touching Main no longer ran `check_const`). Two queries, one value.

### DOCTRINE — a law missing, misleading, or stale

- **"RE-PROBE X" WRITTEN AS A CONCLUSION IS A CLAIM, NOT A PROBE.**
  The design doc's S1 bullet read "A module's `const` is ALREADY
  accepted (re-probe CLAUDE.md: a module const is not F0902 today)" —
  the parenthetical names a probe nobody ran, and the claim is FALSE:
  a plain module const IS F0902, which is why the scoping is
  `is_exported` and why CLAUDE.md's own subset entry was right all
  along. The doc now records the correction. THE ASK: a "re-probe" in
  a design doc is a TODO, not evidence — run it or drop it.

---

## Feedback survey — 2026-09-12 #5 (lane/comptime, const dogfooding)

The `/feedback` run for the sweep that turned the compiler's own
constant-shaped functions into `export const` (base `c34254d` plus
`e3762a4`..`548289a`). Counts: FRICTION 4, SUGAR 1, FEATURES 2,
DEFECTS 0, DOCTRINE 2, PERFORMANCE 1 (measured effect named), PROCESS
2. The headline is a LANGUAGE GAP the sweep exposed: a private
top-level `const` is file-local and ORDER-SENSITIVE, so every
internal constant had to be `export`ed.

### SUGAR — a construct the language should have

- **A PRIVATE TOP-LEVEL `const` SHOULD BE MODULE-SCOPED, LIKE A FN.**
  A `fn` in a module file is visible to every file of that module and
  may be called before its textual definition; a non-exported `const`
  is FILE-LOCAL and F3001 "used before its definition" (probed:
  `receiver_law` at `features/annotations/check.av:163`). The sweep
  converted 86 functions; ~60 of them were PRIVATE and only compiled
  once every one was written `export const`, widening `@std.avrac`'s
  public API with `unit_ceiling`, `settle_steps`, `open_readonly` and
  kin. THE ASK: a non-exported top-level `const` is a module
  DECLARATION (visible within its module, not importable outside),
  exactly as a private `fn` is — so order does not matter and no
  `export` is owed. THE TRADE the ask settles: admitting EVERY
  top-level const as a module Decl (private included) changes
  same-name shadowing (`const N = 1; let N = 2; fn f { N }` now reads
  the const; two `const N` clash), which the const adversarial suite
  pins the other way — so this is a deliberate semantic migration, not
  a one-line fix, and it is WHY the sweep exported instead.
  LANDED 2026-09-13 (comptime/const): every top-level const is a
  module declaration; the suite was rewritten deliberately; the 58
  private exports came off.
- **A TEMPLATE CANNOT NAME WHAT IT GENERATES** (found by the
  private-const red team, 2026-09-13; pre-existing, both binaries).
  Origin hygiene resolves a template's names in the file that WROTE
  the quote, and `generated_named` is "never asked for a template's
  own name" — so two declarations generated by one quote cannot see
  each other (`const G_SUM = G_LIT + …` where the same quote
  generates `G_LIT`: F3000 at the template line). Every real derive
  so far generates ONE impl, whose methods find each other through
  `self`, which is why it never bit. THE ASK: a template's generated
  names join the lookup for reads whose origin is that template — the
  expansion's own declarations, keyed by origin, tried after the
  writing file's namespace. Wanting site: a `@consts`-shaped
  annotation generating a computed const from a sibling.

### FRICTION — what cost time

- **THE TRANSFORM IS ABOUT SCOPES, NOT NAMES.** A global `NAME()` →
  `NAME` replace hit three innocent DEFINITIONS: a test's own
  `fn halver`, `sqlite_open_adversarial_test`'s own `fn words`, and
  `@std.process`'s `fn words` METHOD. A rename must respect the scope
  the name resolves in; a finder that reports "0 fn-value uses" is
  silent about a SAME-NAME definition elsewhere.
- **A SINGLE-LINE COLLAPSE EATS `//` COMMENTS.** Converting
  `grammar_of_grammars` by collapsing its 140-line body to one line
  put every `// rule = …` comment before the rest of the grammar, so
  the const ended at the first comment and the whole 150-rule grammar
  vanished — 326 cascading "no `fn seq`/`item`/`named` is defined".
  The fix: keep the body MULTI-LINE after `=` (`=` continues the
  line). A mechanical collapse must know what a `//` does.
- **USING NEW SYNTAX IN THE COMPILER'S OWN SOURCE STALES THE SEED.**
  `seed-check` refuses the moment `export const` appears in the
  source, because the committed seed predates the feature (`F3014`,
  plus a `text_of` cascade from the broken module). `make seed`
  refreshed in the same commit, as the lane brief requires.

### FEATURES — a capability, more than sugar

- **THE MODULE-SCOPED PRIVATE CONST** (above) is the language change
  the dogfooding asks for; it is filed in the sugar backlog with its
  wanting sites.
- **AN `avra consts` INSTRUMENT.** The finder used here is a throwaway
  Python script; a compiler command that lists zero-arg single-value
  fns (`avra consts`) would make the next sweep one command and catch
  new candidates at review time.

### DOCTRINE — a law missing, misleading, or stale

- **F0902 WAS ABOUT EFFECTS, NOT VALUES.** A module file may now hold
  a private top-level `const`: it never runs, so the entry-only rule
  did not reach it. `runs_at_top` excludes every const.
- **"A CONST IS A DECLARATION" HAS A HOLE AT PRIVATE SCOPE.** The
  model is complete for EXPORTED consts (module namespace, cross-file
  reads, the const-type query) and incomplete for private ones. The
  sweep is the evidence; the sugar ask is the repair.

### PERFORMANCE — a measured effect

- **THE GRAMMAR IS BUILT ONCE.** `grammar_of_grammars` was rebuilt on
  every `ready(...)` call (150 `rule(...)` constructions); it is a
  settled constant now. Not timed in isolation, so the claim is
  shape-level: the rebuild is gone from the parse path.

### PROCESS — the working discipline itself

- **AN INDEPENDENT AUDIT FOUND WHAT A GREP MISSED.** The finder
  could not judge MUTATION or FN-VALUE use; a subagent that read every
  use site classified all 114 candidates and its KEEP list (fresh
  `new_*`/`empty_*` accumulators, `dyn`-carrying values, every world
  reader) is what kept the sweep safe. Delegate the CLASSIFICATION,
  keep the TRANSFORM — the two need different tools.
- **RECOVERY WAS ONE `git checkout`.** The grammar collapse and two
  bad renames were reverted cleanly because each conversion round was
  its own commit; the seed refresh rode the same commit as the source
  that needed it.

---

## Feedback survey — 2026-09-13 #7 (lane/comptime, S4r origin hygiene)

The `/feedback` run for the slice that made a quote a `Code` VALUE with origins, keyed the resolver by them, homed every generated diagnostic, and red-teamed the result (base `693d8f5` -> this tree; 50 attack programs). Counts: FRICTION 5, SUGAR 2, FEATURES 2, DEFECTS 6 (all FIXED and pinned), DOCTRINE 3, PERFORMANCE 1, PROCESS 3. The headline: a META SHAPE CHANGE broke the compiler's own derives in the standing binary through two WHOLE-PROGRAM leaks into a resolve, and nothing in the tree could say so — eight blind builds before a one-line trace named the chain.

### FRICTION — what cost time

- **A WHOLE-PROGRAM PASS LEAKED INTO A RESOLVE, AND NOTHING SPOKE.** Adding `source: Code? = null` to `@std.meta.Directive` made the cli build refuse "`Expr` has no method `int_of`" and "no property `index` on `ExprId`" — the derive had RUN, its generated impl was there under `avra expand`, and the package alone checked clean. The receivers pass (`receivers()`) asked every fn's sig from inside the lifted derive and signed `nodes.av`'s decls from a smaller view; `impls_by_name["Code"]` dragged `features/worklist.av` into the same resolve. Eight builds bisecting the diff found nothing; one `debug("sig mid-resolve …")` line in `sig()` printed the open-query chain (`6/1954 5/64 17/64 14/0 13/1 11/232 10/232 8/4280 16/0`) and named it in one run. ASK: a KEEPER — a whole-program family (`Receivers`, `Methods` over all decls, `method_diagnostics`) beginning while a `Resolved` key is open is a defect the kernel can assert (`Db.begin` knows both). The three guards today are hand-placed. (lane/comptime, 2026-09-13)
- **A FAILED TRAIT DERIVE WAS SILENT.** `trait_directives` answered `[]` on `.Err` and the user read "no method `show`". FIXED: `derive_law` re-asks the memoized lifted call and voices its `Unsettled`. Confirmation of survey #3's silence finding, one seam over.
- **`;` IS NOT A STATEMENT SEPARATOR, AND THE FIRST TEMPLATE SPELLED ONE.** `let tmp = 1; let picked = ${body}` was refused as "unexpected character" — at the time SILENTLY (generated source did not speak), so the symptom was "no `fn go_wrapped` is defined". Filed in "The subset today"; the refusal speaks at the template line now. Probe `fn f() -> int { let a = 1; a + 1 }`, base this tree.
- **TEST FILES IN ONE DIRECTORY ARE ONE MODULE, EVEN IN A SINGLE-FILE RUN.** `quote_adversarial_test.av` duplicating `quote_test.av`'s `packaged`/`clean` helpers refused F3017 "declared twice in this module" when run ALONE. The fixtures had to be shared by name across the two files. ASK: say so in DOGFOODING's test section, and give `@std.avrac.testing` a Program-level `packaged(files)` so the in-memory `@std/meta` mock (now in TWO test files: annotations_adversarial, quote_test) has one home before a third copies it.
- **THE STANDING BINARY DOES NOT READ THE NEW META, SO A META CHANGE IS A TWO-COMMIT LADDER.** `Directive.code: string?` had to stay one build as a bridge so the seed could compile HEAD; S2 removed it. Confirmation of the four-generation-ladder rule (sugar1 memory) for META types, not just syntax.

### SUGAR — a construct the language should have

- **`join` OVER `List<Code>`.** `joined(arms, ", ")` is a free fn because `join` is a `List<string>` row (`str_lit`'s method table). A derive reads `arms.join(", ")` more naturally. Wanting sites: `packages/std-derive/src/derive.av:25,38,43`. ASK: method rows keyed by a TRAIT (`Joinable`) rather than by one element type — the same door `Show`-typed printing would use.
- **A HOLE IN NAME POSITION COMPLETES THE NAME.** `quote { l${i} }` makes ONE identifier `l0` whose origin is its first byte's (the template's), while `${spliced("l${i}")}` makes a hole-origin one — the same name, two colours, and a derive that mixes them binds a name it cannot read. Today's rule ("a name's origin is its first byte") is pinned in the design doc; the honest fix is a parsed template where a hole IN a name is one token. Wanting site: `derive.av`'s `eq_arm` (spliced both ends). Recorded under the parsed-templates trigger.

### FEATURES — a capability, more than sugar

- **`avra expand` NAMES WHERE A GENERATED RUN WAS WRITTEN.** Diagnostics are homed now; `expand` still prints a generated declaration with only `// from @derive on Point`. ASK: a second line per generated declaration naming the template's file and line (the `Generation`'s first origin segment), so a reader of the expansion can open the quote that wrote it. P7.
- **PARSED TEMPLATES (the campaign).** Typed holes by position, `Code<T>`, and a hole completing a name all wait on parsing a quote where it is written (design §3.5). Every origin mechanism landed here (generations, segments, keyed binders) is what it sits on. Recorded trigger in the handoff.

### DEFECTS — the compiler blaming itself (all FIXED this slice, each pinned)

- **A SIG SIGNED MID-RESOLVE, KEPT.** "no property `index` on `ExprId`" from `features/worklist.av:51` under a clean tree — the receivers-pass leak above. Guard in `receivers.av`; pinned by the cli build itself (`make gate`'s seed-check).
- **`const C: Code = quote { k }` — TWO DEFECTS** ("an unresolved name survived a clean analysis", "register r1 defines out of mint order"): a hole-less quote claimed `is_literal`, and the const fast-path (`lower_state.av:238`) read it through the value protocol. `is_literal` is the protocol's again; annotation gates ask `source_spelled`. Pinned: `quote_adversarial_test` "a `const` holds a quote".
- **A SPAN TRAP ON A DEPENDENCY'S LOC.** "a span reaches outside its own text — offset 252 of 135 in main.av": a homed Loc named the provider's file and `Analysis.report` rendered it against the target's source (`source_named` fell back to `sources[0]`). `Program.rendered` now renders every file over EVERY loaded source. Pinned: the homed-refusal cases in `quote_test`.
- **A RAW BODY INSIDE A HOLE NEVER CLOSED** (`"${quote { x }}"`, `quote { ${quote { y }} }`): "unterminated string" / "a `quote` block is never closed". `balanced` pays the enclosing hole's count. Pinned: `quote_adversarial_test` "the raw body inside a hole".
- **A `}` IN A `//` COMMENT ENDED A QUOTE OR GRAMMAR BODY.** Both raw scans skip line comments. Pinned.
- **A GENERATED FN LOST TO A WRITTEN ONE IN SILENCE** (`fn go_wrapped` written + `@wrapped` generating it answered the written 5). F2077 at the annotation. Pinned.

### DOCTRINE — a law missing, misleading, or stale

- **A PREDICATE OVER THE VALUE PROTOCOL IS A REGISTRY CONSUMER.** `is_literal` was widened to quotes for one consumer (the annotation gate) and broke another (the const fast-path) that dispatches on what `is_literal` promises. The law: a predicate that says "the protocol answers this" may not be widened past the protocol; a wider question gets its own name (`source_spelled`). Filed here; CLAUDE.md's registry law covers the match half, not the predicate half.
- **A NAME-KEYED TABLE CROSSES MODULES** — pinned in CLAUDE.md (`impls_by_name`, `aims_at`).
- **A RAW BODY'S CLOSING BRACE IS A TOKEN**, and a raw body inside a hole pays the hole's count — pinned in CLAUDE.md's grammar-authoring rules.

### PERFORMANCE — a measured cost

- **THE GATE'S PEAK MOVED 706 -> 694-749 MB** across the slice's three gate runs (`tools/watch.sh`), inside the run-to-run swing; the compiler's spec count went 2294 -> 2309. No census was run: the quote lowering is three `Ins.Call`s per template run (`quoted`, `spliced`, one `joined`), and `meta_named` was found rescanning `@std/meta`'s declarations on every call by the review round and memoized (`Decls.meta_ids`). NOT MEASURED: a derive-heavy package; the cost of `visible(origin)` per template name read (memoized, one map lookup).

### PROCESS — the working discipline itself

- **KEEP: PROFILE, DON'T REASON, extended to QUERY CHAINS.** Eight bisecting builds explained nothing; one inert trace line did. The line is permanent now (`AVRA_DEBUG=1` prints "sig mid-resolve: <name> in <file>"), because "a generated impl's methods went missing" will recur and this is the first thing to look at.
- **CHANGE: A WORKTREE TWO SESSIONS WRITE TO NEEDS A LOCK ON TEST FILES.** `quote_test.av` changed on disk mid-slice (a `spoken` helper appeared, `refused_n` vanished, 16:00) while this session was editing it; the merge was by hand. The gate's watchdog serialises builds, not edits.
- **CHANGE: THE HARNESS SCRATCHPAD CAN VANISH MID-SESSION** ("no longer available"); probes moved to `build/scratch/` (gitignored). A lane's probe harness belongs under `build/`, never under a session temp.

NOT SURVEYED: the private-const ask (item 4 of the handoff, unchanged), `@std/derive` beyond `Show`/`Eq`, and any package outside std-avrac/std-meta/std-derive.

---

## Feedback survey — 2026-09-13 #6 (lane/comptime, S5 refinements)

The `/feedback` run for the slice that lifted the two S5b boundaries: a settled seat FORWARDED to another fn, and a direct AGGREGATE literal at a settled seat (base `6134110`; the S5c mechanism extended, not a second channel). Counts: FRICTION 2, SUGAR 2, FEATURES 1, DEFECTS 0, DOCTRINE 3, PERFORMANCE 0 (compile-time only), PROCESS 1. The headline is a WORKFLOW GAP the slice fell into: `avra run` and `avra build` lower only REACHED units, while `avra test` lowers EVERY declared body — and the two disagreed.

### FRICTION — what cost time

- **`run`/`build` GREEN, `test` RED — `every`-mode lowers TEMPLATES.** `programs_checked`/`cases_checked` call `lowered_as(entry, every=true, programs=true)` (workspace.av:1674-1693), so EVERY declared body lowers; `run`/`build` use `lowered_checked` (`every=false`) and lower only what the entry REACHES. A forwarded seat cannot resolve in a TEMPLATE body, so a call there enqueued a specialization with EMPTY seats, and the callee's const refused F2074 — a message that pointed at the callee, never at the template. Two rebuild cycles to find. A probe over `run`/`build` does NOT cover `test`.
- **THE `./avra` SHIM CHANGES DIRECTORY, so a RELATIVE `.av` PATH FAILS** (`avra: no such file`) with no clue it is a cwd effect. A whole eval-vs-native sweep first read as "all diffs" until every path was made absolute. Probes should pass absolute paths.

### SUGAR — a construct the language should have

- **A `const` NESTED IN AN AGGREGATE LITERAL AT A SETTLED SEAT.** `const N: int = 5; take(P { x: N })` refuses F2073 because `literal_meta` (the source-spelling check) has no bindings table, so a NAME inside an aggregate is not source-spelled. The top-level name itself settles (`take(N)` works, via the `const` branch); only the nested one does not. Wanting site: `features/values.av`'s `literal_record`. Either `literal_meta` takes `NameFacts` and resolves a `const` ident, or the aggregate crosses through the evaluator.
  LANDED 2026-09-13 (comptime/const): the second — typing's law is a
  source walk (`spelled_by_source`) and lowering settles the argument
  as an expression (`SettleRoot.Expr`, on the unit's seats).
- **AN INLINE VARIANT LITERAL AT A SETTLED SEAT.** `take(.B)` refuses F2073 with the misleading "computed at run time" — `.B`'s enum type is only known AFTER the call's seat WANTS are fed, and the const-seat check runs BEFORE `seats_fit`/`accepts` feeds them (`dispatched_call`, features/fns/check.av:93 -> features/checks.av:615). The real fix is an ORDER change: feed the seats before judging the settled fills. A struct literal works only because its type name is explicit. Wanting site: `take(.B)`, probed 2026-09-13.
  LANDED 2026-09-13 (comptime/const) WITHOUT the order change: the
  seat law reads the source and the bindings, never the facts, so the
  variant's type need not be known when it is judged. `K.B` and
  `K.B(1)` (a qualified variant — a method-call node on the enum's
  name) settle too.

### FEATURES — a capability, more than sugar

- **AN `every`-MODE PROBE.** A command that lowers EVERY declared body the way `avra test` does (`avra check --every`, or have `check` lower every body when no entry runs) would let a lane catch template-body defects without a package test. The gap cost the F2074 detour above.
  LANDED 2026-09-13 (comptime/const): `avra check --every`
  (`Program.check_every`, one `check_bodies(every)` behind both).

### DOCTRINE — a law missing, misleading, or stale

- **THE S5b NOTE UNDER-SPECIFIED THE FILL.** It said "a literal or a `const` (computed ones included)"; it did not say a SETTLED SEAT of the ENCLOSING fn may be FORWARDED, nor that an AGGREGATE must be fully written (an omitted default is a body the evaluator runs, so it is not source-spelled). Both are now pinned in the design doc's queue.
- **A TEMPLATE BODY FALLS BACK TO THE PLAIN CALLEE.** A forwarded seat is per-unit; a template has none, so it calls the plain body (whose consts are already skipped). That is now a comment at `seats_complete` (language/lower_state.av).
- **A SEAT FINGERPRINT CARRIES ITS KIND.** A source-spelled fill `e`s and a settled fill `v`s the hash, so the `_` join of a call's seats can never read one seat's role as another's — the flat-concatenation law applied to `settled_symbol`'s join.

### PROCESS — the working discipline itself

- **KEEP:** the S5c mechanism carried BOTH boundaries with no second channel — `SeatValue` widened to the crossing tree, `lower_root` seeding, per-unit keys. A refactor that reuses the existing seam is cheaper than a parallel one, three times now.

---

## Sugar backlog — dogfooding asks

- A LOOP THAT DIVERGES STILL OWES A TAIL VALUE (filed 2026-09-08, the
  HTTP lane's review round). `while true { ... }` whose every path
  `return`s or propagates is a diverging loop, and the type checker
  cannot see it, so each such fn ends with an UNREACHABLE expression
  written only to satisfy the answer type. FOUR WANTING SITES, all in
  code a reader has to be told to ignore: `frame.av`'s `fed` ends
  `.More(cur)`, `server.av`'s `run` ends `.Ok(turns)`, its `advanced`
  ends `.Ok(l.conn.fd)`, its `accepted` ends `.Ok(n)`. THE COST IS
  HONESTY, not keystrokes: the dead tail is a VALUE a reader must
  decide is unreachable, and in `fed`'s case it is a `Chunked` variant
  that would be a WRONG ANSWER if it ever ran. THE FORM WANTED: either
  a `loop { }` that types as never, or flow analysis that reads `while
  true` with no `break` as diverging — the second costs no syntax and
  reaches the sites already written. NOT the recursion these fns would
  otherwise use: `avra run` traps at 400 nested calls, and a chunked
  body of 200 chunks reaches that.

- A WILDCARD PARAMETER (filed 2026-09-08, the HTTP lane's review
  round). `fn f(_: int)` is F3002 "`_` is a keyword — cannot be a
  name", while `let _ = g()` and `.Bind(_)` are ordinary. WANTING
  SITE: nineteen route handlers in std-http's suites whose signature
  `routed`/`fixed`/`tailed` owns and whose body never reads the
  request — they spell `_q` today, which works and which the idiom bar
  reads, but the language already has the word for "I am deliberately
  not naming this" and a seat is the one place it refuses it. Cheap,
  and it makes I23's licensed case spell itself the way I22's does.

DECIDED 2026-09-14 (owner + task master), for type operators: `type
Name = Shape` is always DISTINCT (a name that counts); no alias form.
Literals fill it, the shape's methods forward, `Name(value)` converts
and the refusal suggests it. Typed ids shorten to `type UserId = int`.
Design doc §7 q1 carries the reasoning; the wanting site is every
`{ index: int }` id in core/nodes.av and the type-operator later row.
LANDED 2026-09-14 (comptime/types), whole: the grammar, the
construction, the literal fill, read forwarding, the named operand
law and the `Name(v)` suggestion. The model, the seams and the exact
refusal words are docs/2026_09_14_NAMED_TYPES.md; the law is
CLAUDE.md's "A NAME IS OPAQUE AT A SEAT AND TRANSPARENT AT A READ",
the idiom DOGFOODING's I42, the proof
`features/structs/tests/named{,_managed}` plus 64 spec cases in
`named_test.av` and `named_adversarial_test.av`. Recorded triggers
below.

RECORDED TRIGGERS from that slice (comptime/types, 2026-09-14) — each
REFUSES cleanly today, so none is a silent hole:

- A GENERIC NAMED TYPE (`type Box<T> = List<T>`): F2083 "`Box` is a
  named type with type parameters, which is recorded, not landed".
  The record form's tparams do NOT carry over — `App(decl, name,
  args)` interns per instantiation, so the name's mark would have to
  be SUBSTITUTED and made at `applied_decl` rather than at declare.
  FIRES at the first site that wants a generic typed id.
- A NAME OVER AN ENUM OR A RECORD FORWARDING `match`/`is`/`with`:
  `k is .Red` over `type K = Color` is F2013 "`is` asks an enum for
  its variant, found `K`", and `w with { … }` over `type W = P` is
  F2011. Forwarding means `variants_of_type` and `fields_of_type`
  seeing through, which also lets `K { … }` and a field read reach a
  LAYOUT the flat law does not follow — a slice, not a line. FIRES at
  the first site that wants a named enum or a named record.
- A NAMED CONSTRUCTION AT A `const` SEAT: `seat(A(3))` is F2073
  "computed at run time" — the settled-seat law reads the SOURCE and
  `A(3)` is a call. FIRES at the first `const` seat that wants a
  named type; the fix is `literal_meta` reading a named construction
  over a literal as source-spelled.
- AN IDEMPOTENT CONVERSION: `Name(v)` where `v` already wears the
  name refuses in the seat's words. FIRES when a normalising helper
  wants to write it unconditionally.
- THE SWEEP OF THE COMPILER'S OWN `*Id = { index: int }` IDS (seven
  declarations, `.index` read thousands of times). FIRES when those
  reads can be replaced mechanically — by a forwarding property or a
  scripted rewrite with a gated diff. Deliberately NOT done in the
  landing slice: the representation is already identical, so the
  sweep buys spelling and nothing else, and it would have hidden the
  four defects the red team found.
- A LITERAL PATTERN OVER A NAMED ENUM (`match k { .Red -> … }`) —
  the VARIANT half of the `match` trigger above. The SCALAR half
  landed 2026-09-14: a literal pattern reads its subject through the
  name, exactly as `==` does.

FROM THE 2026-09-13 #8 FEEDBACK SURVEY (comptime/templates; rows and
evidence under "Feedback survey — 2026-09-13 #8"): a hole in a
STRING's literal run (site `std-derive`'s `Show`); a PARAMETER-LIST
hole (no site yet); a FLOAT in a hole (`quote/lower.av`'s
`fill_reg`); PEG lookahead in the grammar DSL (`quote/mod.av`).
PAID by that campaign: "a hole in NAME position completing the name"
from survey #7 (`l${i}` is one `Hole` token now); `join` over
`List<Code>` is moot — a list fills a seat directly.

FROM THE 2026-09-13 #7 FEEDBACK SURVEY (lane/comptime): `join` over
`List<Code>` (a trait-keyed method row; sites `std-derive/src/derive.av`),
and a hole in NAME position completing the name (waits on parsed
templates; site `derive.av`'s `eq_arm`).

FROM THE 2026-09-11 FEEDBACK SURVEY (lane/comptime; full rows and
evidence under "Feedback survey — 2026-09-11"):

- GROW A LIST TO SIZE — `xs.resize(n, v)` (a List method). Wanting
  site: `Decls.record_generated`'s `by_stmt.concat(filled<DeclId?>(n -
  by_stmt.length, null))`.
- A LIST SEAT FILLED BY MANY ARGUMENTS — `@derive(Show, Eq)` should
  hand one `List<Trait>` seat two traits, as the design writes it
  (`derive(t: Type, traits: List<Trait>)`), but an annotation is
  arity-exact, so `@std/meta.derive` takes ONE `Trait` and stacks
  instead. Wanting site: `@std/meta.derive` (`packages/std-meta/src/
  meta.av`); the shape is a REST/LIST seat any call may fill with
  several written arguments.
- A STRAY `${` IN A STRING NAMES ITS ESCAPE — a derive whose GENERATED
  code interpolates writes `"\\${self.${f.name}}"`, and forgetting the
  `\\` is F3000 "`self.` is not defined" pointing at the derive, never
  at the interpolation. Wanting sites: `packages/std-derive/src/
  derive.av`, `packages/std-meta/src/meta.av`. The ask: at a `${` with
  no binding, name the escape (`\${`) in the help. Survey
  2026-09-11 #2, SUGAR.
- A GUARD THAT STILL COUNTS ARMS — `effect! is .Declares` was the
  obvious draft but violates the registry law, so a two-arm `match`
  stands (features/annotations/check.av). Wants a guard spelling the
  compiler can still prove exhaustive.
- INTERPOLATE A VALUE, NOT ONLY A SCALAR — `${r.answer}` on a
  `MetaVal` is F2007. Wants a derived `Show` (S4 `@derive`) reachable
  from interpolation.
- SHORTEN THE IMPORT WALL — every new helper edits a 40-name `use
  core.{…}` (language/workspace.av:17). Wants a module-qualified
  reference or a glob form.
- MEMBER AND MODULE DOCS HAVE NO TABLE — a `///` on an enum variant or
  a struct field, and a module's `//!`, are dropped by the source
  projection (`core/nodes.av` loses 158 lines, `features/mod.av` 5).
  WANTING SITE: `fmt`, which would delete them the day it consumes
  `language/source_text.av`. Needs a doc seat on `Variant`/`Param` (or
  an anchor-keyed table) and one for the module header.


- AN AGGREGATE ARGUMENT TO A DECLARATION-GENERATING ANNOTATION. A
  `Declares` annotation's generated name must exist while the file's
  names are still being resolved, so its arguments cross from the
  PARSE tree alone: `@traced([1, 2])` refuses with F2067 "generates
  declarations, so its arguments come from the source alone", where
  a `Records`/`Validates` annotation takes aggregates because it runs
  after resolve. The ask is the quote phase (S4) — a template that
  yields a meta value without the declaration's typed answers.
  Wanting site: `@traced`'s label is a literal `"sum"` today; a
  computed label is the first shape the quotes unblock. Landed as a
  law and an adversarial test (2026-09-10, lane/comptime).

- EMBED OUTSIDE COMPILER EVALUATION IS A RUN-TIME TRAP TODAY, not a compile-time
  refusal: `let t = embed("x")` at the top level compiles and traps
  when it runs (both engines, the same words). The static law is a
  effect-graph check from each runtime root. A `Jobs.settling` bit was
  tried and REFUSED during the comptime memo review: `meta.embed` is
  phase-polymorphic, so marking its memoized body makes the answer
  depend on which phase lowered it first and rejects the std package
  when bodies are checked independently. The call graph must carry
  `Reach.Embed`; runtime roots refuse it, while settlement and crossed
  annotation roots admit and track it. RECORDED TRIGGER: lands with
  the expansion/effect graph, before declaration-producing annotations.
  Probed 2026-09-10 on lane/comptime.

- PROCESS-WIDE MUTABLE STATE — a package cannot own a handle table.
  MEASURED: `once fn slots() -> List<int> { [] }` then three pushes
  answers `1 1 1 | table now holds 0`, eval == native — every caller
  gets a FRESH COPY, because `once` memoizes a PURE value and that is
  what it is for. So there is no mechanism for a package to hold state
  across calls. WANTING SITE: `@std/sqlite`'s `Db`. A generation-tagged
  handle (`gen << 32 | idx` over a table, the shape
  `runtime/avra_runtime.c:1727` already uses for child processes) would
  turn a double-close from undefined behaviour into a NAMED refusal —
  but that table lives in the C RUNTIME, and a package building its own
  would be the C shim this campaign refuses by its first rule.
  ASYMMETRY WORTH KEEPING when it lands: the CONNECTION takes an id
  (touched once per call), the STATEMENT keeps its raw pointer (touched
  per column per row).

- ~~BITWISE OPERATORS~~ — LANDED 2026-09-06 at 2c6b35f (the sqlite
  campaign's bitwise lane): all six parse, type, lower and run, eval
  == native. `flags_of` can spell `|` and the test that existed only
  to say the invariant aloud goes with it. Filed 2026-09-05 (lane D; found by the sqlite
  campaign's driver lane, probed here). None of `|`, `&`, `^`, `~`,
  `<<`, `>>` exist, in two tiers — `|`/`<<`/`>>` lex and have no
  grammar, `&`/`^`/`~` do not lex.
  THE WANTING SITE IS NOT ERGONOMIC, which is why it is filed rather
  than noted: @std/sqlite's `flags_of` builds SQLite's open-flag word
  by SUMMING its contributors, because `+` is the only spelling
  available, and a sum equals an OR only while every contributor is
  a distinct bit. The driver lane's reviewer first called that test
  redundant — "make it an OR so it pins a fact rather than a
  coincidence" — and the probe inverted the note: there is no OR to
  replace it with, so `+` equalling `|` is NOT a coincidence the
  code chose but a PROPERTY THE LANGUAGE FORCES IT TO DEPEND ON, and
  the test is the only thing anywhere stating it. A language gap
  that turns an invariant into a coincidence, and pushes the burden
  of saying it into a test, is the shape worth recording. Every
  binding to a C API meets a flag word.
- `export use`, a RE-EXPORT (filed 2026-09-05, lane D; the driver
  lane's ask, refusal verified here). F3014 "`export use` — a
  re-export — arrives with a later slice"; rung 15c names it. THE
  COST IS NOT ERGONOMIC EITHER: without it a package's FILE LAYOUT
  IS ITS PUBLIC API, so a package cannot curate its own surface and
  any later move of a type between files breaks every caller. The
  wanting site is packages/std-sqlite/src/sqlite.av, ATTRIBUTED —
  that package is not in this tree.
- ~~TRAILING LAMBDAS for the bracket verbs~~ — LANDED 2026-09-09 as
  sugar 1's level two (docs/2026_09_09_SUGAR_1_CONTEXT_RECEIVER.md):
  `f(a) { x -> body }` is `f(a, (x) -> body)`, `else { … }` after it
  fills the next fn seat (PROVISIONAL — the word is positional and
  reads as a branch, a lie wherever the seat is not a choice's other
  arm; sugar 5 retires it for the seat's name, `other: { … }`, docs/
  2026_09_09_SUGAR_5_NAMED_ARGUMENTS.md), `{ … }` with no arrow takes no seat (or `it`
  when the body reads it, its statements included), a name or a field
  read takes one as a call with no parentheses (`run { … }`, `db.tx {
  … }`), and the block is a POSTFIX like the rest (`xs.find { it > 1
  } ?? 0`, `xs.filter { … }.length`). A seat HEARS its slot's `mut`
  mark as it hears its type, so a block on `fn(mut Cx) -> R` writes
  through the context it is handed; a lambda may write `mut` on its
  own seats. THE HEAD LAW paid for it: `if f(a) { … }` keeps its
  brace because a head (`if`, `while`, `for`, `match`, `if let`,
  `let … else`) is matched with trailers CLOSED until a delimiter
  opens — two DSL marks (`@head(c)`, `@trailer(tb)`) and an executor
  cap, memoized per cursor; a block on a call in a head is
  parenthesised (`if (f(a) { … }) { … }`), Swift's rule. NOT
  spelled: a trailer on a `?.` chain (`a?.m { … }` — the chain lowers
  to a match, so the block goes in the parentheses), and `(f(a)) {
  … }` widens `f(a)` — a paren group mints no node, so the trailer
  cannot tell it from `f(a) { … }` — while `f(a)() { … }` applies the
  answer. THE EXPANSION LESSON: a `grammar { }` literal is expanded
  into constructor code by the COMPILING compiler, spelling `Item`'s
  fields by hand, so the two new marks reached no product for one
  generation ("every field is spelled", grammar_lit/builders.av) —
  and a DSL word is a syntax change to the compiler's own source:
  the ladder was seed -> a product that knows the words with no rule
  using them -> the full grammar -> the fixed point. Filed 2026-09-05
  (lane D from the sqlite driver lane's ask); the wanting site was
  attributed (`../avra-sq-driver`'s `db.tx(() -> { … })`), and the
  compiler's own regions were the first sweep: `cx.region(c, e) { cx
  -> … } else { cx -> … }`, `cx.presence(v, held, e) { cx, carried ->
  … } else { … }`, `cx.void_region(c) { cx -> … }` at 22 sites, IR
  byte-identical.
- THE RED TEAM ON TRAILING BLOCKS (2026-09-09, 90 programs across the
  eight classes, eval == native on every accepted one — no wrong
  answer, no divergence). Six survivors, each a test now
  (closures/tests/trailing_adversarial_test.av): a block with no
  seats on a slot whose answer already REFUSED cascaded a second
  message (`fn_fits` absorbs an errored answer, as every Error does);
  `{ x, x -> x }` bound one name to two seats silently — a fn refuses
  it, and a paren lambda did not either (pre-existing, fixed for
  both); a second BARE block (`f { 1 } { 2 }`) filled a third seat
  silently, where `else { }` is the spelling and the misread is a
  block statement — refused in those words; `run { it }` on a
  seatless fn slot said "not a fn" of a fn (the pronoun voice assumed
  a scalar seat); `noop { }` is a RECORD LITERAL by the grammar (a
  name before an empty brace pair), so the remedy names `noop() { }`.
  TWO FOUND AND LEFT, named: a CALL BY NAME resolves the declared fn
  before a fn-typed local of the same name — `fn f() …` then `fn run(f:
  fn() -> int) -> int { f() }` calls the declared `f` (`use_call`, "the
  pinned arm law", by design and documented; the red team's own
  fixture fell into it, and a seat named like a top-level fn is the
  trap); and a head with an unparenthesised block (`for v in xs.map {
  … } { }`) refuses as "expected `..`" — the farthest failure names
  the range branch, not the head law; the cure would be a head's own
  voice, unbuilt. AND THE F2051 GAP the sweep closed: a `mut` seat
  handed to a fn VALUE's `mut` seat (`f(c)` with `f: fn(mut C)`)
  counted as never written (`valued_evidence`, receivers.av).
- ~~TYPE LITERALS~~ — LANDED 2026-09-09 as sugar 2
  (docs/2026_09_09_SUGAR_2_TYPE_LITERALS.md): `v.type(T)` is a
  postfix like the rest, expanded at PARSE time to ONE call,
  `v.interned(<T as a TypeLit value>)` — bare variants heard from
  the seat, so no site imports anything and the receiver is read
  once (`cx.type(List<string?>)` is `cx.interned(.List(.Opt(.Str)))`).
  The words and `List`/`Map`/`Result`/`fn(…) -> R` spell shapes; any
  other NAME is a HOLE, the binding it names (`cx.type(Map<string,
  want>)`). THE WORD IS `type`, not the doc's `ty`: a new keyword
  reserves a name, and `ty` names 273 bindings in the tree while
  `type` was reserved already. THE RECEIVER IS EXPLICIT, not "the
  context in scope": the 128 sites spelled ten receivers
  (`cx.view.types`, `self.types`, `types`, `reg`, `e.types`,
  `a.view.decls.types`…), so no one binding was "the" table;
  TypeCx, LowerCx and Decls carry `interned` so `cx.type(int)` reads
  as the doc wanted. 87 sites swept, 37 left — every one a shape the
  literal cannot spell (a declared type, `Error`, `Null`, the empty
  literals) or a part that is an expression. I40 ratchets it.
  DOGFOODING ASKS FROM THE SWEEP: (1) AN EXPRESSION HOLE —
  `cx.type(List<${elem_of(x)}>)`: four sites keep `intern(Type.Opt(
  seat!.elem))` because a hole is a NAME, so a computed part binds a
  name first; (2) a TYPE PARAMETER is no hole in a program —
  `x.type(T)` in `fn g<T>` refuses as "`T` is not defined", true and
  misdirecting, and the compiler's own bodies never wanted it; (3)
  `int??` is unspellable in the type grammar (one `?` per name), so a
  doubly-nullable literal is `List<T?>?`-shaped or nothing.
- THE RED TEAM ON TYPE LITERALS (2026-09-09, 142 programs across the
  eight classes, eval == native on every accepted one — no wrong
  answer, no divergence). Eleven survivors, every one a refusal's
  WORDS, each a test now (expr_spine/tests/type_lit_adversarial_
  test.av): a value in the slot (`n.type(1)`) fell through to a
  method call named `type` and said "declare `fn type`" — a keyword
  can never be declared, so a dot-call NAMED BY A KEYWORD that no
  method answers speaks as the grammar form it failed to be
  (`form_refusal`, impls/check.av); `?.type(T)` read `int` as an
  expression — the chain is spelled now, lowered to the same match
  every `?.` link is; `N.type(int)` on a type NAME spoke as a variant
  construction; a hole holding the wrong type said "argument 1 of
  `.Id` wants `int`" — the expansion's seat leaked, so a hole is
  MARKED and refuses as a hole; a trailing block after a literal
  widened the expansion's call ("`N.interned` takes 1 arguments…") —
  refused in the literal's words. FOUND AND LEFT, named: a parser
  hole plus the statement's "expected BREAK" is two messages for one
  mistake at nine malformed shapes (`fn(mut)`, `List<int>>`, `f()`
  in the slot) — the hole law's, not the literal's; `n.type(List<>)`
  is the hole plus the arity law, both true; and an `interned` that
  is a FN FIELD or takes an `int` seat says "`.Int` builds a variant,
  and `int` has none" — the receiver's contract in the variant's
  words.
- A BOUND METHOD AS A VALUE (filed 2026-09-09, the sugar 1 sweep).
  `xs.any(self.stmt_rides)` is F2003 "no field `stmt_rides` on
  `NodeStore`" — a method name read without parentheses is a property
  read, and typing asks the record for a field. A free fn IS a value
  (`xs.any(big)` answers), so the gap is the receiver: the method
  plus the `self` it closes over. The spelling today is the wrapper
  lambda `(k) -> self.stmt_rides(k)`, which the sweep wrote at ten
  sites (the pronoun trap forced it: `xs.any(self.verb(it))` rebinds
  `it` to the nearest method call). WANTING SITES: core/nodes.av's
  `any_rides` and `any_stmt_rides`, features/unify.av's three
  `all`/`find` folds, workspace.av's `parse_clean`. THE SHAPE: a
  method read on a receiver answers `fn(seats) -> answer` with the
  receiver captured — the same fn box a lambda mints, seat 0 the
  receiver — so it is the pronoun's wrapper minted by the reader
  rather than the writer, and the lambda feature owns it.
- THE PRONOUN INSIDE A BLOCK'S STATEMENTS (landed with the above):
  `pronoun_rides` read a block's VALUE alone, recorded as a
  limitation; a trailing block exists for multi-statement bodies, so
  `it` now rides a block's statements too (`stmt_rides`, exhaustive
  over Stmt). Strictly more programs compile; an unbound `it` was
  F3000 before and is bound now.
- `pop` ANSWERS `T?`, SO THE TRAP IS SPELLED (filed 2026-09-05, lane
  D; the change is lane C's files and lane A's db.av). `xs.pop()`
  answers the ELEMENT today and traps on an empty list ("pop on an
  empty list", exit 2, both engines — probed). So each of the 36
  `.pop()` sites hides a trap the source does not show, and a reader
  cannot tell a pop that CANNOT fail from one that can. The dead `??`
  proves the confusion is live: query/db.av's `self.marks.pop() ?? 0`
  and language/lower.av's `?? "the entry"` are both F2044 "`??` never
  fires" — each an author reaching for a fallback the API refuses,
  and db.av's would TRAP where its author wrote 0.
  THE ASK: `pop` answers `T?`, joining `find`'s settled `T?`. Absence
  then reads straight (`?? 0` works as written), and the
  known-non-empty case spells its claim as `xs.pop()!` — which traps
  exactly as today, but VISIBLY. The cost is mechanical: 36 sites
  gain a `!` or a null test (typing.av 5, resolve.av 5, memory.av 4,
  db.av 3, the rest scattered). The trade is P3's ceremony against
  P7's visible magic, and the `!` is one character bought for a trap
  that is invisible in every one of those 36 lines today.
- SIZED INTEGER TYPES (`i32`/`u32` at least, at least in extern
  signatures). SPECIFIED (spec Axis 15.2: "`i32`, `i64`, `u8`, etc.
  map to fixed-width C types directly"), MISSING (`extern fn f() ->
  i32` is F2001, "`i32` names no type"), and PRODUCING WRONG ANSWERS
  today: Avra's `int` is 64 bits and C's is 32, so an extern over a C
  `int` reads -1 as 4294967295 on the NATIVE path, and both engines
  agree on it. WANTING SITE: the @std/sqlite lane, whose library
  answers C `int` at 153 of 284 entry points. Lane A closed OUR half
  (two narrow returns widened; `make externs` keeps the class) but
  the keeper cannot read a third party's headers. Cheapest of the
  three asks: no literal syntax, no arithmetic, no text projection —
  only the width an extern declares and the extension the backend
  emits at the boundary. THE CORE-SIDE FACTS are recorded under lane
  A's block ("CORE-SIDE FACTS FOR THE THREE LANGUAGE ASKS"), verified
  in the tree: what RtKind is, how few consumers it has, and the one
  line in `is_managed` a new scalar must join.
- FLOAT (IEEE-754 binary64). WANTING SITE: the @std/sqlite lane —
  SQLite's five storage classes are NULL, INTEGER, REAL, TEXT, BLOB
  and Avra has three, so a REAL column cannot be bound at all. The
  seam is narrower than it looks: `RtKind` is `{ I64, Ptr, Void }`
  (core/ir.av:219) so the extern wall cannot DECLARE a float seat,
  but growing it is a REGISTRY-COLUMN event, not an eight-consumer
  instruction event — one exhaustive match (`ll_rt_kind`), none in
  the interpreter (it dispatches on RtHost). The hard part is not the
  seam but printing a double so it round-trips and reads naturally,
  which is a runtime problem.
- BYTES. WANTING SITE: the @std/sqlite lane needs arbitrary bytes
  with embedded NULs across the C boundary; `string` is the only byte
  carrier today and there is no `Bytes` type (zero hits in
  core/types.av and the runtime). It must NOT reuse the string box:
  `str_len` falls back to `strlen` on a zero recorded length, which
  is a wart for text and a CORRECTNESS BUG for a legal empty blob.
  Its own kind, header length authoritative.
- WEAK CAPTURES. A closure stored in a value that captures the value's
  owner is a cycle, and counting never frees one: the workspace's
  query verifiers, its declaration hooks and its analyses all
  capture the workspace, so a workspace lives forever unless its
  last user ends the cycles by hand (`disarmed`, 2026-09-05). THE
  ASK: a capture marked weak (`weak ws` at the lambda, or a core
  `Weak<T>` with `get() -> T?`) holds no reference; a read checks
  the box's header — a GENERATION beside the count, bumped when a
  box is freed, so a dead box's reused memory never answers for it —
  and traps or answers null on a dead owner. Lowering: an unowned
  lane in the capture pack (no retain, no release); the runtime: the
  generation in the header's spare bits and a `weak_get` row.
- ONCE-PER-PROCESS PURE VALUES. `avra()` assembles the language —
  merges 34 grammars, prepares and validates the result, boxes the
  dispatch — and every spec case calls it: 7.6ms x 1578 cases = 12s
  of a 48s suite run, measured 2026-09-04. The value is PURE (the
  same features make the same language), so computing it once per
  process is semantically invisible, and the language has no way to
  say so: `export let` is refused, and a fn body cannot read a
  top-level `let` (the const law, rightly — a `let` is run-time
  state). THE ASK: a zero-argument pure fn marked `once` (`once fn
  avra() -> Language`) whose first call settles its answer for the
  process. THE SKETCH: lowering gives the fn a hidden static cell
  (one new memory boundary — the IR vocabulary protocol's eight
  consumers pay it once: a `Global` slot the backend emits as an
  LLVM global, the interpreter as a machine-level cell) plus a
  presence guard; the mut-cell protocol already owns the cell's one
  reference. Typing refuses `once` on a fn with parameters or one
  that reads a `mut`. Wanting sites: `avra()` (language/mod.av),
  every `shown(src)` in 1578 cases through `analyze_source`, and the
  CLI's own `avra()` per command; `rt_sig_of(name)`, which rebuilds
  the whole 48-row runtime table on EVERY call — the memory pass per
  runtime call lowered, the backend per call emitted, the evaluator
  per runtime call EXECUTED (~8% of the case run and of lowering,
  sampled 2026-09-04; a second spelling of the table was refused —
  `once fn rt_index()` is the fix). Rejected on the way: a runtime
  cache (a `Language` is an Avra value; the seam would need a cast
  Avra does not have) and threading a language through every test
  helper (1500 call sites).
- FIELD PUNNING: `T { name, value }` where a local of each name is
  in scope. Refused today ("expected BREAK") and it is OURS, not
  bs2's — the ledger entry that blamed bs2 was checked and moved
  here. Wanting sites: every builder that binds locals and then
  repeats their names into a literal.
- ONCE-PER-PROCESS PURE VALUES — LANDED 2026-09-05 (lane C) as
  `once fn`. The SKETCH below (a hidden static cell, a `Global` IR
  variant, the eight consumers) was REFUSED in favour of the design
  the ledger item records: two runtime rows and no IR variant.
- TRAIT DEFAULT METHOD BODIES — LANDED 2026-09-05 (lane C: a
  default is a generic method over the trait's `Self`, lowered per
  signatory; LANE C's block records the design). What it buys —
  `kind()`/`message()` as defaults over `describe()`, and every
  `nothing()` / bare-`null` pass method in the StmtSemantics impls
  collapsing so an impl states only what it DOES — is the sweep
  that follows.
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
- A ONCE-PER-PROCESS BINDING for a PURE fn — LANDED as `once fn`
  2026-09-05 (lane C); the entry below is the sketch it superseded.
  ORIGINAL. `avra()` is pure and was
  re-run 1532 times; the fix landed as "stop making the work
  expensive" rather than "remember the answer", because Avra has no
  lazy static and the epic forbids mutable globals — rightly, but a
  memo of a pure fn breaks neither parallelism nor incrementality.
  FIRING CONDITION: the second pure whole-program value that wants
  computing once (the dispatch table is the likely next).
- ~~A PAIRED COMPREHENSION~~ — LANDED 2026-09-05 (lane D): the
  comprehension's head IS the `for` statement's — `[f(i, x) for i, x
  in xs]` pairs and `[f(i) for i in lo..hi]` counts (one grammar
  alternative and one payload field, `Comp.hi`); nine one-push loops
  became one line each and their I3 licenses retired. The sites
  still spelled as loops write through a `mut` receiver in the body
  (`store.alloc_stmt`), which a comprehension element does not.

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

- A MUTATING CAPTURE. A lambda's capture is a copy of the binding,
  so `defer xs.push(v)` (and `defer log.rows.push(v)`) is refused
  F2034 "`xs` is not `mut`" — blaming the binding when it is the
  CAPTURE that carries no `mut`. Found landing `defer` (2026-09-05;
  the probe was a deferred push, the cleanup every log wants). TWO
  ASKS: the voice should name the capture ("a capture is a copy —
  `xs` inside the lambda is not the `mut xs` outside"); and a
  managed capture could carry the binding's `mut` mark — the
  pointer is already shared, only the mark is lost, so `defer
  xs.push(v)` would compile with no copy semantics changed. Wanting
  site: any deferred cleanup that records into a list.

- `Result<void, E>` — a verb that can only refuse. `@std/io`'s
  `write_text`, `make_dirs` and `remove` want to answer nothing on
  success and an `IoError` otherwise; F2019 refuses the slot ("a
  `Result` slot cannot hold this yet"), so each answers the path it
  wrote — a fine convention, but chosen by the subset, not the
  design. Found landing `@std/io` (2026-09-05). THE ASK: the Result
  register triple (O4) or a unit payload, so `fn f() -> Result<void,
  E>` types and `f()?` in statement position is the whole call.

- `\u{…}` ESCAPES in string literals. `"\uFFFD"` is not refused:
  the lexer keeps an unknown escape as its two characters, so a test
  that meant the replacement character asserted a backslash and a
  `u`. Found landing `@std/json` (2026-09-05). THE ASK: `\u{XXXX}`
  in the lexer's `unescape`, encoded through the runtime's
  `avra_str_from_codepoint` — the row exists; `@std/text`'s
  `from_codepoint(65533)` is the spelling until then. Wanting sites:
  the json specs' surrogate and control-character cases.

- A PRE-COMMIT GATE RUNS THE CHEAP KEEPERS. The lane's own history
  proves agents commit past the bar: 82a7ecd (the MetaVal crossing)
  landed five new idiom violations, an unused import, and a settle
  test that passed vacuously — all caught only by a later `make gate`
  (2026-09-10, lane/comptime). The cheap keepers (`idioms`, `vocab`,
  `fingerprints`, `externs`) are sub-second; wire hooks.json to refuse
  on them, and the full gate stays the merge bar.

- THE IDIOM REPORT NAMES THE LOCAL IT FLAGS. tools/idioms.py's I26
  matcher already computes `[name! xN]` and truncates it away, so the
  site reads "one nullable local forced open 3+ times" and the reader
  greps the tool to learn which local. Print the binding's name
  (`held! x4`) in the site line — the difference between acting and
  investigating. Wanting site: every I26 fix (values.av's
  meta_record/meta_enum exemplars).

- `??` GUARD-BINDING, SO "GUARD ONCE, BIND ONCE" IS ONE LINE. The
  idiom's own cure is the three-line
  `let held = f(); if held == null { return … }; let sig = held!` —
  longer than the smell, so the ratchet punishes
  the commonest pass stanza (values.av's meta_record/meta_enum; the
  compiled compiler holds dozens). THE ASK, probed before assuming:
  a guarded bind — `let sig = self.fields_of(ty) ?? { return … }` —
  or a failure-lane `or`, so the idiomatic form is SHORTER than the
  violation and the class collapses by construction.

- AN EMPTY AGGREGATE LITERAL ADOPTS A PLANTED NON-NULLABLE WANT.
  `[]` under a `List<int>` want types as `List<int>`, `{}` under
  `Map<string, int>` as that map — never `.EmptyList`/`.EmptyMap`
  when the seat knows its element. Today only the BINDING's declared
  type rescues the literal (`let xs: List<int> = []` works by
  declared type), so a const's materializer had to carry the const's
  type in a new `Wanted.answer` field to route AROUND the literal's
  own shape (lane/comptime 422fe46, 2026-09-10) — the wart this ask
  removes at its root. The NULLABLE want stays refused (F2024, the
  subset cache's entry). Probe before assuming: want-less `[]` method
  refusals (`unmeasurable_empty`, lists/methods.av) and
  `empty_adopted`'s identity widen (checks.av) both rest on the
  literal NOT adopting, and `plant_want` must keep flowing to heirs
  (a lambda in the seat hears it).

- `avra probe` — BASE-STAMPED PROBE RECORDS. A probe result names
  the base that answered it (the Attribution law, CLAUDE.md), and
  today the stamping is hand prose. THE ASK: `avra probe <file>`
  writes one row — source, refusal F-codes, base commit, compiler
  binary — into the probe log, so a re-probe after a merge shows its
  own age instead of reading current forever. Companion to `avra
  query`/`avra impact`; the subset cache's recorded-trigger (probe
  logs as gate-verified program tests) is the natural home.

- `avra check <file>` SCOPES TO THE FILE WHEN IT IS ONE FILE IN A
  PACKAGE. Checking `packages/std-avrac/…/aggregate.av` surfaced
  dozens of F0902 module-file refusals from OTHER files (sweep.av),
  the named file's two real defects buried at the tail — signal
  drowning hides findings (2026-09-10, lane/comptime). The named
  file's defects come first, or a single-file argument checks only
  that file.

- `avra impact <symbol>` — THE COMPILER ANSWERS "WHAT DOES THIS
  TOUCH" TODAY. Which program tests cover the fn, which bodies lower
  it, who settles it: the workspace's memo graph (declaration → body
  → settlement → lift) already IS the dependency index, and `explain`
  is the seed. Ends grep-guessing test scope; P10/P11 own the
  premise — the compiler is the semantic index agents grep around.

- `avra query <file>:<line> --json` — type-at-point, the binding, the
  law that refused and why, from the facts tables the compiler
  already holds. The one probe result an agent asks for fastest;
  today it is grep plus reading, the floor P10 was meant to raise.

- A SESSION HANDOFF ARTIFACT PER LANE. Resuming a dropped agent
  session cost a 26 MB JSONL mine plus reconstructing intent from a
  staged/unstaged split (2026-09-10, lane/comptime). The dated STATUS
  paragraphs in docs/2026_09_09_COMPTIME_DESIGN.md were the best
  orientation available — make that pattern first-class: a
  `docs/<date>_HANDOFF_<lane>.md` (entry / mid / next, human- and
  agent-readable) touched at each checkpoint commit, so the resume
  reads one file.

- DOCS SPELL `rg`, NEVER GNU-ONLY `grep -g`. Two commands copied
  verbatim from CLAUDE.md/subset failed on macOS BSD grep this
  session; an agent copies, so the tax is real. Standardize the
  examples on `rg` (or spell both forms).

- REVIEW-ROUND CHECKLIST: NAME THE ROW A TEST TRIPS ON. The staged
  settle_test embed case "passed" while refusing on `avra_puts`,
  never exercising the embed admission — an instance of "A TEST'S
  NAME IS READ AS ITS SCOPE", caught by assertion surgery rather than
  the green (2026-09-10, lane/comptime). A review-round item: for
  each via-the-machine case, say which runtime row it actually trips.

FROM THE 2026-09-12 COMPTIME S5 SLICES (lane/comptime; wanting sites
and probes in the same commit):

- A REUSABLE `param` GRAMMAR RULE. Every param list spells
  `( "const" )? ( "mut" )?` by hand — TEN sites (`fns/mod.av:33-35`,
  `impls/mod.av:50-52`, `closures/mod.av:24-25`,
  `expr_spine/mod.av:36`) — while the LOGIC is one place
  (`marked_seats`). The DSL has no parameter rule a fragment can
  reference, so a third mark is 10 more spellings. THE ASK: a `param`
  rule the declaration fragments reference, its builder answering
  `List<Param>` so the span-window alignment dies with it.

- `quote { }` FOR TEST SOURCES, AND A KEEPER THAT KNOWS A QUOTE BODY IS
  TEXT. Every spec case spells Avra source as an escaped `"…"` with
  `\n` and `\"` (e.g. `features/fns/tests/fns_test.av`). Probe: one
  const-seat case rewritten as a `quote { … }` block compiled and
  passed (64/64) — then `make idioms` flagged ELEVEN false I23s,
  because the line-based scanner reads the quote body as real code.
  Two asks: teach `tools/idioms.py` brace-depth-aware quote skipping
  (and the same for any `grammar { }`/`table { }` body it scans), then
  spell test sources as quote blocks. The readability win is large.

- A `Seat` RECORD — NEVER PARALLEL `params`/`marks`. S5a made seat
  promises ONE `SeatMark` currency, but the marks still travel as a
  list PARALLEL to `List<TypeId> params`, zipped by index at every
  reader (`core/types.av` `seat_words`, `features/checks.av`
  `declared_marks`, the `for j, p in params { mark_at(marks, j) }`
  shape). That is CLAUDE.md's moving-boundary hazard living in the
  type currency. THE ASK: `Fn(seats: List<Seat>, ret)` with
  `Seat = { ty: TypeId, mark: SeatMark }`, so an off-by-one is
  unspellable. (Wanting site: `core/types.av`, `Arrow`, `Type.Fn`.)

- `continue`, OR A GUARDED ITERATION. `const_seats` wanted "skip the
  unmarked seats" and had to nest an `if` around the whole body
  (`features/checks.av`), because `continue` is not a statement. THE
  ASK: `continue` in a `for` (the comprehension bar still prefers a
  filter; this is for a fold with a skip), or a `for x in xs if
  <cond>` head.

- FLAGS, OR A SET OF AN ENUM. `SeatMark { mutable, settled }` is a
  two-bit flag set; building and reading it is a struct literal and
  nested `if`s (`core/types.av` `mark_prefixed`/`mark_word`). THE ASK:
  a combinable enum value (`SeatMark.mutable | .settled`, `.has(…)`)
  or a `Set<E>` — the honest shape for "some of these hold".

- ONE DECLARATION-PARAM READ. A declaration's parameters are read
  three ways: `store.fn_parts(stmt)?.params` (`features/checks.av`
  `seat_names`), `declared_params(store, stmt)`
  (`language/workspace.av:1977`), and `written_seats(keywords, params)`
  (`features/contexts.av:125`, a filter). THE ASK: one
  `Decls.params(d)` verb (reading the DECLARATION's own store — the
  cross-file read that crashed S5b), with the receiver-implicit truth
  stated once.

- A PRIVATE TOP-LEVEL `const` IS MODULE-SCOPED. A private `fn` in a
  module file is visible to every file of that module and callable
  before its textual definition; a private `const` is FILE-LOCAL and
  F3001 "used before its definition". The const-dogfooding sweep
  (survey 2026-09-12 #5) converted 86 fns and had to export ~60
  PRIVATE ones to compile at all, widening `@std.avrac`'s API with
  `unit_ceiling`, `settle_steps`, `open_readonly` and kin. WANTING
  SITES: `features/annotations/check.av` (`receiver_law`, read at
  :163), `std-sqlite/src/script.av` (`semicolon`, read at :37),
  `std-io/src/io.av` (`enoent`, read at :72). THE ASK: a non-exported
  top-level `const` is a module DECLARATION (module-visible, not
  importable outside), exactly as a private `fn` is — order-free, no
  `export` owed. NOTE: admitting EVERY top-level const as a Decl
  changes same-name shadowing (`const N = 1; let N = 2; fn f { N }`)
  and turns two `const N` into a clash, so the migration must update
  `features/consts/tests/consts_adversarial_test.av` deliberately —
  which is why the sweep exported instead of doing it inside the
  dogfooding.

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
- ~~`code_at(s, i)` = `s.substring(i, i + 1).char_code()`~~ — PAID:
  `code_at` IS `s.char_code(i)` (core/chars.av), and ours answers the
  index (`"hello".char_code(1)` is 101, probed 2026-09-04).
- `s.length` is `strlen` (hoisted at 8+ sites, I27) — OURS, measured
  2026-09-04 (a 150k re-asking loop: 0.91s user against 0.44s
  hoisted, native). -> LANE A: length-carrying strings; the ratchet
  retires with them.
- ~~Typed ids interchangeable, pattern and construction arity
  unchecked~~ — STRUCK 2026-09-04: probed, Avra refuses all three
  (F2000 "wants `StmtId`, found `DeclId`"; F2015 "`.A` carries 3, the
  pattern names 2" / "`S.A` carries 2 values, given 1"). The I25
  ratchet RETIRED with it the same day: its baseline was empty and
  the compiler refuses the shape on one-line enums too.
- ~~The reserved words bs2 lexes even as fields/locals~~ — STRUCK
  2026-09-04: ours has its own law with a voice (F3002 names the
  word as a keyword or "reserved for a future Avra feature"); `none`,
  `ref`, `shape` and `where` are free. The renames stand.
- ~~Every entry of CLAUDE.md's "bs2 subset notes"~~ — STRUCK
  2026-09-04: the section is deleted. Of its 76 notes, 37 were
  probed ACCEPTED (struct literals in every argument seat, `<N>`
  pins from struct arguments and fn-typed arguments, the
  closure-field-call discipline — exhaustiveness IS checked there —
  multi-line `use`, present-bind arms under mono, `.last()!` and
  `xs[i]` as copies, `xs[i] = v`, `\${`, `"}"`, …); the 28 it still
  refuses are OUR gaps in "The subset today", each with the
  refusal's words (lane D's block has the tally and the candidates).
- ~~FIELD PUNNING (`T { name, value }`)~~ — MOVED: it is ours, not
  bs2's; the sugar backlog holds it and lane C lands it.
- ~~bs2's `mod x` stub (cli/src/main.av)~~ — PAID 2026-09-04: the
  line is deleted and the cli checks clean (a scratch package's
  directory module resolved with no stub). The grammar rule that
  parses `mod x` as `use x.{}` (features/modules) is dead weight now
  — its owner deletes it with the next touch of that feature.
- ~~The vendored `spec_test` feature~~ (GONE — `avra test` is the
  runner) and ~~`std-cli`, a symlink into the old tree~~ — STRUCK
  2026-09-05: lane B's `@std/cli` replaced it in place, so
  `packages/std-cli` is ours (its own manifest, doc header and two
  spec files) and `find packages -type l` returns nothing. The tree
  vendors nothing from bs2 now.
- ~~THE GENERIC ANSWER'S IDENTITY~~ — STRUCK 2026-09-04: probed, a
  field read and a `with` on a generic method's answer both type
  with no bind; the annotated lets in `memory.av` go with the next
  touch (lane C's file). What bs2 shared with us: a generic impl's
  body still cannot name its own `T` in a local annotation (F2001
  "`T` names no type") — in "The subset today", a candidate.
- ~~THE `"}"` LITERAL~~ — PAID 2026-09-04: ours lexes a `}` inside a
  string, so `closing_brace` reads `index_of("}")` and says what it
  means. Its companion paid with it: 206 sites across 31 files spelled
  a literal `${` as `"$" + "{"` because bs2 has no `\$` escape. Ours
  does, and they say `\${` now.
- ~~THE ELEMENT WRITE (`mut x = xs[i]; x.push(v)`)~~ — STRUCK
  2026-09-04: probed, `xs[i]`, `.last()!` and a handed list are all
  copies under ours; the tree writes the value back. DOGFOODING
  holds the pattern.
- ~~THE STAMPED ENTRY (`packages/cli/src/main_stamped.av`)~~ — PAID
  2026-09-04: the generator was already gone; the `exclude` line, the
  manifest's cache-key prose and both `.gitignore` lines are deleted,
  and `make clean` sweeps a dropping. The `./avra` shim STAYS: it is
  the cold-tree door (`build/avra`, else the seed), not a stamp.
- `extern fn println` / `eprintln` in the compiler's own entry and
  commands: the tree declares the C prototypes it links against. ->
  LANE B: `@std/io` over the same externs; then lane D replaces the
  externs in the cli and the corpus.

THE LEDGER CLOSES HERE (2026-09-04): every bs2 entry above is struck
or handed to its lane. What follows is OURS — the debt TECH_DEBT.md
carried that outlived the bootstrap, each with the trigger that pays
it:
- NODE CEREMONY is hand-written derive: a new node variant costs a
  fingerprint arm (nodes.av), canon and printing arms (types.av), a
  Dispatch field + boxed let + dispatch arm (program.av) and backend
  type arms (llvm.av) — ~45 lines across 4 files, every one a
  mechanical consequence of the declaration, SAFE because the
  exhaustive matches break every owed site. TRIGGER: the compiler
  deriving from declarations (P6: generated AND checked).
- BUILDER REGISTRATION is a value-level table, and builders take
  positional args off a `Builder` context: a grammar's `-> int_lit(v)`
  cannot bind a typed `fn int_lit(v: Token) -> Expr`. TRIGGER: build
  calls bound to typed fns at composition (arity and types checked;
  the engine allocates, spans and wraps) — the tables, accessors and
  `Result<LangNode, string>` spelling then leave feature code.
- THE LANGUAGE SHARES THE GRAMMAR DSL's SCANNER (`lex_source` owns
  only the line policy): the token shapes and operator set happen to
  cover the language. TRIGGER: the first token shape the DSL's
  scanner cannot carry; a feature-extensible lexer replaces the rent
  (lane B's `@std/text` code-point walk is a piece of it).
- THE INTERN PATH materializes a string key per probe (a string-keyed
  `Map`; FNV walks bytes). TRIGGER: the first composite shape, when
  `canon` starts concatenating — an int-keyed table (fp_mix over the
  variant ordinal and child ids, verify on collision), zero
  allocation; the hot path already never interns.
- A RECOVERY HOLE (`Stmt.Error`) is not linked to the diagnostic that
  produced it. TRIGGER: the first tool that reads partial trees
  (`avra explain` over a hole, the lsp) — a sparse side table, hole
  -> diagnostic.
- BUILD DROPPINGS: `avra build` writes `<file>.av.ll` and the binary
  beside the source (`packages/*/src/main`, `corpus/*/src/main`), and
  `make clean` sweeps them. TRIGGER: `avra build` growing an output
  directory, as `avra test` already has (`build/` under the root).
- THE FREE STATE FNS (the ALIAS BORROW and RECEIVER ALIASING entries
  above) -> LANE C, with `mut self`.
- Everything else TECH_DEBT.md carried was bs2's and died on the
  probes: import closures (F3000/F3012 refuse both directions but the
  unused one — I24), the vendored runner, the `src/` layer (ours by
  convention now), runtime linking, freshness, the closure-field
  exhaustiveness hole, `f(x)?.field`'s silent corruption (F2023 now),
  the nullable-generic-local corruption, #1377, `f() == s`, the F1000
  tail class, present-bind arms, newtype corruption (no newtypes),
  the `dyn` vtable mix (F2013 now), `Result` through `dyn`, the
  component silent null (F2000 now), fn-typed-arg evidence,
  `grammar { }` blocks (landed), component instantiation in test
  files (works). A `find_index` list method is still wanted ("The
  subset today").

THE SWEEP'S FINDINGS (2026-09-05, three read-only reviews of every
product file no lane held — features; grammar + core + query +
diagnostics; language + cli + the std packages). Ranked by lines and
by meaning; each is a slice for lane D unless a lane is named.
- A. THE EMISSION VOCABULARY — PART ONE LANDED 2026-09-05 (lane
  D): features/emit.av speaks the region (`open_region`, `arm_end`,
  `close_region`, `close_region_as` — 13 raw triples and 20 renamed
  callers), the constants (`const_int`/`const_bool`; three copies
  and 12 raw pairs gone) and the measure (`measured_reg`; the three
  verbatim `length` lowerings are one row fn). The IR of all 73
  corpus programs was byte-identical before and after; I33 ratchets
  the rule. PART TWO LANDED the same day: the walk (`opened`,
  `counted`, `turn_*`, `early_exit`), the loop brackets and the cells
  live in emit.av; `loops/lower.av` speaks them (its hand copy of the
  skeleton is gone); I33 covers the loop instructions; the enum tag
  ladder x3 is `variant_tag`; "a span between two offsets" x7 is one
  `within`; nullable's fourth `length` is `measure_of`. LEFT: the
  seven `lower_*` seat preambles in `lists/walks.av` — a
  `seated_walk` needs a `mut` seat in a fn TYPE, which does not parse
  (now in "The subset today"; a candidate under H).
- ~~B. TWO LATENT INCONSISTENCIES~~ — DONE 2026-09-05 (lane D). (2)
  WAS REAL: the enum payload seat short-circuited unify and refused a
  `dyn` box (`Holder.Holds(P { x: 3 })`, F2015) and an auto-Ok
  (`Wrap.Res(4)`, F2015) that a call argument and a struct field
  took — `agreed()` in checks.av is the one door, three callers, the
  failing tests written first (enums_adversarial), corpus/seats.av
  proves the three seats agree native. (1) WAS NOT a bug: `App` is
  absent from `declared_decl` ON PURPOSE — a trait impl over a
  generic type is recorded, not landed (F2031), so a generic
  instantiation must not box into a `dyn` it cannot dispatch; the
  stale doc ("wait for T2") now says so, and the two identical
  RECEIVER projections folded into `receiver_decl` beside it, the
  difference named. `writable` spells every arm. FOUND: a generic
  enum under a `dyn`-carrying want pins `T` from the argument, not
  the want (`let c: Cap<dyn Show> = Cap.Some(P {…})` is F2024) — the
  want-into-generic class, filed under H.
- ~~C. THE DOT-CALL DECIDED ONCE~~ — DONE 2026-09-05 (lane D):
  `impls/callee.av` decides WHO ANSWERS (`Callee`: Variant, Bounded,
  Contract, FnField, Row, Declared, Nameless — every arm spelled) in
  the surface's precedence, and typing and lowering each match it
  exhaustively; the two hand-ordered ladders, the `Receiver` record,
  `var_bound`/`BoundSeat`, `type_receiver` and the helpers' null
  answers are gone (a `Bounded` receiver at lowering is a mono
  defect, named). The IR of all 74 corpus programs is byte-identical;
  eleven attacks agree eval == native; the field-over-method
  precedence is pinned by a test. language/receivers.av's own
  `Callee` (Row/Method/Contract/None) is the third copy of this
  decision — lane C's to fold onto impls' when it next touches it.
- ~~D. THE ERROR-ABSORB VERB~~ — DONE 2026-09-05 (lane D): 43 sites
  in three spellings ask `cx.errored(e)` / `cx.errored_ty(ty)`,
  the verbs beside `shape_at` on TypeCx (features/contexts.av).
- ~~E~~ — DONE 2026-09-05 over two slices (lane D), except lists/methods.av's prelude, whose ten sites vary in their wants and read as one honest line each. VOICES, SCANS, DEAD CODE, STOLEN DOCS: twinned voices
  (lists/maps `unslottable_want`, lists/loops `not_walkable`,
  results `covers`/`total`); the struct field law twice
  (`structs/check.av` generic_field/field_check, same refusal text
  inline); I28 prose at variants.av:24, structs/check.av x4,
  checks.av x3; hand scans that are `find` (mod.av method_row/
  property_row, coherence.av registrar_of, enums tests_variant/
  tests_first/switchable); `lists/methods.av`'s prelude+seat guard
  x10 -> `held_and_seated`; DEAD: mutation/resolve.av
  `through_receiver`, expr_spine/check.av `unpinned_read`,
  checks.av `empty_into`, typing.av `module_word`, llvm_api's
  sdiv/srem, `declare`'s `variadic`; I31 stolen `///` runs x13
  (checks.av:35 wears THE ASSIGNMENT LAW mid-sentence, values.av x2,
  variants.av x2, nullable/check.av:92, impls/check.av:79,
  contexts.av:264, core/parts.av:131 — `diverges` sits bare while
  `leaves` wears its doc — lexer.av x2, nodes.av x2, analysis.av:57).
- F. GRAMMAR + CORE (lane A owns these files; SENT to lane A
  2026-09-05, and lane A has since LANDED the lexer residue (where
  verification found `|>` was UNLEXABLE, not merely unparsed, and
  `continuing_ops()` minted a fresh 17-string list per source line),
  the fallback flag as one nullable local with a corpus program
  pinning the retired limit, the Rep suffix inverse, and the
  Alt/Seq walk — where their verification found lane D's THIRD copy
  was a FOURTH (features/coherence.av) and that the proposed
  `prims_of` served none of them; it is `Alt.seqs`/`Alt.items`/
  `Seq.deep_items`, four call sites, nine lines shorter. HANDED
  BACK, and the hand-back is right: `grammar_build`'s string
  dispatch is NOT a Rules violation — the Rules forbid a string
  deciding BEHAVIOR, and this is the DSL's own builder-name currency
  crossing a data seam, named as a string on both sides. What
  survives is a narrower and better-evidenced point, offered to lane
  A rather than re-filed: features/coherence.av cross-checks builder
  names as DATA (it reports a builder no feature registers, and one
  no rule calls), and the grammar side cannot have that check while
  its builders are a match. Measured: the seed calls 12 and
  builders.av implements 12, with no drift today and nothing
  mechanical keeping it so. The cheap half is a
  `grammar_builder_names()` list the validator compares against,
  which buys the check without restructuring the dispatch.
  Earlier, adversarial verification KILLED six of the
  thirteen — recorded here so nobody re-files them. STRUCK: the
  `ready(grammar_of_grammars())` perf claim (the DSL seed is 9 rules /
  12 branches, so it is microseconds; the count is 28 not 29; and a
  cached Ready is not expressible — no globals, no lazy statics);
  the BinOp roster x3 (op_symbol and fp_binop are exhaustive, so a
  14th operator IS a compile error at two of three sites); the
  BREAK-vs-END divergence (unreachable — no feature grammar puts an
  `@expect` on an END item, and a probe prints `expected BREAK`);
  `first_slash` vs `index_of` (already fixed in core/paths.av, though
  it rode into @std/path); declared_kind's re-matching (view.stmts is
  top-level only and the projection short-circuits — a nit, not a
  cost); the three no-ops (nothing_noted has ONE call site and
  `touch<T>` is a different verb). WHAT SURVIVED:
  PERF — `grammar/parse.av:14` calls `ready(grammar_of_grammars())`
  INSIDE parse_grammar, so the 27 `grammar { }` literals of a
  self-compile each rebuild and re-validate the seed grammar (~120
  allocations and a FIRST fixpoint) that `Ready`'s doc promises once;
  six Alt->Seq->Item->Prim descents, three of them one flat walk ->
  `prims_of`/`items_of`; the BinOp roster x3 (`op_symbol`,
  `all_binops`, `fp_binop`) -> `fp_binop(op) = fp_str(op_symbol(op))`;
  `grammar_build` is an 84-line STRING-MATCH dispatch (the rules
  forbid it; compose.av's table is the shape); `Rep` <-> suffix
  twice with a lying `_ -> Rep.Opt`; a missing terminal reads
  "BREAK" on one path and "END" on another -> one `expected_of`;
  the `fb_diags` flag -> a nullable local; `first_slash` is
  `index_of`; "every character satisfies" x3 -> `all_codes`;
  `alt_defects`/`defects` concat folds -> `flatten`;
  `declared_kind`/`declared_name` re-match the statement up to 11
  times -> one `declared(s)`; three no-ops (`nothing_noted`,
  `touch`, `nothing`) -> one in core. ARCHITECTURE: the
  language-agnostic LEXER hardcodes Avra's words (`grammar`, `else`,
  `or`, `with`, an operator list with `|>`) and `line_boundary` is a
  callback whose body is `true` -> a `LexFlavor` VALUE supplied by
  language/, as `Grammar.keywords()` already supplies the keywords.
- F-VERDICTS (lane A, 2026-09-05): the eight that reached lane A were
  re-verified against HEAD, one skeptic each, refute-by-default, plus
  five fresh lenses over grammar/ and core/. SEVEN of eight hold; every
  cited line number was ~10 low, so read the code, not the citation.
  HANDED BACK: `grammar_build` is a string-match dispatch, but it does
  NOT hold as a Rules violation — the Rules forbid a string deciding
  BEHAVIOR, and this is the DSL's own builder-name currency crossing
  the grammar's data seam, which compose.av's table cannot replace
  without inventing a second registry for nine private fns.
  THE SEAM DISTINCTION the hand-back turns on, worth keeping because
  the same word names two different laws: features/coherence.av must
  cross-check builder NAMES as data, because separate features
  register separately and nothing sees both sides at once. The DSL's
  own builders need no such check — one file holds both sides, and
  `grammar_build`'s catch-all is an `.Err` that becomes a
  `fatal_defect`, which passes every speculation boundary, so an
  unimplemented builder fails the compiler's own build 28 times over
  (one per feature grammar literal) with the name printed. A
  `grammar_builder_names()` list would move an unmissable failure to
  the same moment with the same information, and pay for it with a
  hand-written list of twelve names beside a match of twelve arms
  with nothing keeping THOSE in sync — the rule of three used against
  itself. MEASURED and refused 2026-09-05.
  REFUSED ON MERIT though TRUE: the `LexFlavor`. CLAUDE.md's
  grammar-authoring rules PLACE the line law in the lexer by doctrine
  ("the LINE LAW lives in the lexer"), so the continuation words and
  the operator list are residents, not leaks; DOGFOODING's I23
  licenses exactly `line_boundary`'s shape; and the count is a severe
  UNDERCOUNT — the lexer also hardcodes Avra's whole token alphabet
  (twenty single-op codes, ten two-char operators, six escapes, `//`,
  `"""`, `@`-words, the `${` hole), so a five-field flavor parameterizes
  four of ~eleven facts and leaves the layering claim just as false,
  bought with a struct and five indirections in the scanner's inner
  loop. LANDED INSTEAD, the residue that was real: `|>` was not merely
  unparsed but UNLEXABLE (`two_char_of` has no 124/62 arm, so no token
  can carry that text) and its list entry was dead data; and
  `continuing_ops()` MINTED A FRESH 17-STRING LIST PER SOURCE LINE of
  every file the compiler reads — the same reasoning the file's own doc
  had already applied to `two_char_of` 150 lines earlier, unapplied
  here. It is a `match` now. The callback's doc stated another fn's
  invariant, incompletely (it said "before an `else`" where the code
  tests `else` or `or` or `with`); it now states its own, and the line
  law moved onto `lex_source`, corrected. THE ONE SURVIVING WANT from
  A13: the lexer spells `"grammar"` while features/grammar_lit's gram
  fragment already claims it — a projection spelled twice — but
  deriving it needs a RAW primitive in the notation, dragging seed.av,
  parse.av, ast.av and validate.av. A slice, not a finding's fix; not
  scheduled.
  ALSO LANDED: the `fb_diags` flag is one nullable local, and the
  stale "GENERIC locals cannot carry loop state through mono" note it
  hid behind is gone — corpus/generics.av now pins a generic `T?`
  local carrying state across a loop at TWO instantiations, so the
  retired limit is a permanent proof rather than two lanes' memory.
  The `Rep` <-> suffix inverse is named (`rep_of_suffix`, `as_rep`),
  killing two plausible defaults: `_ -> Rep.Opt` turned an impossible
  token into a silent `?`, and `.Node(_) or .Many(_) -> Rep.One` did
  the same for an impossible shape. Both refusals are UNREACHABLE by
  construction — the DSL's rule is `postfix = primary ( "*" | "+" |
  "?" )?` — which is the point: an honest refusal over a guaranteed
  dispatch, not a default that lies.
  PROBED, more working shapes recorded: `[self]` as a list element
  recursing through a method; a comparison inline as a comprehension
  element's ARGUMENT; a leading-dot `.concat` continuation after a
  closing paren; `string?` compared to `string` with a bare `==`; and
  `?.` reaching a NULLABLE FIELD (a nested optional — the tree had no
  precedent, and it types and runs).
  PROBED (records a WORKING shape, so the fear shrinks): an `or`-RUN
  over STRING literals in a match arm compiles and runs
  (`"+" or "-" or ... -> true`). It had no precedent in the tree.
- G. LANGUAGE + CLI (lane C owns language/; SENT to lane C
  2026-09-05. STRUCK by verification: the mono mangling by TypeId
  ordinal (real mechanism, wrong harm — those ordinals index the
  COMPILED program's registry, so a compiler refactor leaves
  `avra ir corpus/*.av` byte-identical, no IR goldens are tracked,
  and the seed is regenerated wholesale anyway); and `Entry { at }`
  (a single-field struct IS this tree's newtype, and "entry" already
  means three things in workspace.av). WHAT SURVIVED:  the
  memo-query ritual x14 in workspace.av (~70 lines of kernel
  bookkeeping) -> `Table<T>.memo(db, key, compute)` — blocked on a
  CLOSURE THROUGH A GENERIC SEAT (sugar); the `dyn` boxing pins —
  34 in program.av and 11 `let body: XCmd = XCmd { }` in the cli ->
  a `dyn` want reaching a struct-literal FIELD seat (sugar); the
  `Family` registry x3 plus a runtime agreement guard -> an enum's
  ORDINAL (sugar); `imported_line` and seven `resolve.*` voices live
  in the driver (workspace.av:742-791, 1194-1225; one code spoken
  twice with different words) -> features/modules; typing_impls.av
  and typing_declare.av hold ~380 lines of per-declaration feature
  rules as TypeCx METHODS -> the features, dispatched as
  semantics_of dispatches; memory.av has no context struct;
  `method_diagnostics` rescans the whole declaration table per file
  (I32); `Entry { at }` earns nothing; llvm.av's 31 free fns on
  `Emit`. THE CLI (lane D's): ~~five commands are ONE body
  written five times~~ — DONE 2026-09-05: `commands/phase.av`'s
  `phased(args, phase, act)` holds the body once and each command is
  a named act answering `Result<int, string>` (150 lines -> 121 over
  six files; every command's stdout and exit code byte-identical to
  main's binary on a clean and a refused program); the CommandSpec trio is one record with defaults; four
  program-locating fns are one `program_for(path, entered)`. FOUND
  2026-09-05 (lane D, by diffing the corpus IR across a pure
  refactor): a monomorphized fn's mangled name carries the
  instantiation's TypeId ORDINAL (`twice$14`), so any change to the
  order types are interned renames every instantiation — the IR and
  the seed churn for no semantic reason, and a stable diff of two
  compilers is impossible. A mangling by the type's canonical NAME
  (`twice$G`, `both$P_G`) is reproducible; lane C's (lower).
- FOUND 2026-09-05 (lane D, for lane C's typing): THE RESCUE
  re-walks a hungry lambda's body without re-recording the lambda's
  own facts. With the seat's answer planted on the body (so a bare
  variant in a FIELD-seat lambda types), `Cx { get: (n: int) ->
  .Ok(n * 3) }` LOWERS as `fn $l4(r0: <error>) -> <error>` with the
  body reading a constant where `n` should be — the interpreter
  answers 9 for `cx.get(2)`, LLVM refuses the module. The plant is
  withheld at that seat (CLAUDE.md names it); a typed let's arrow
  reaches the body already. The probe is scratchpad/lam/m4.
- ~~H1. IS A `string` TEXT, OR BYTES?~~ — ANSWERED BY IMPLEMENTATION
  2026-09-07 (f57372a, lane B): the entry named TWO ways out — make
  the five length-aware, or add a `Bytes` value whose scope is
  exactly those five — and the FIRST was taken. `==`, `contains`,
  `index_of`, `split` and `replace` walk the length under
  `memcmp`/`memmem`, so every verb in @std/text reads the header and
  a NUL is an ordinary character on this side. Re-probed by lane D:
  `ab\0cd` answers `5 false true` where this ledger recorded `5 true
  false`. WHAT SURVIVES: the crossing is the EXTERN SEAT — `getenv`,
  `execvp`, `fopen`, `sqlite3_open` still end at the first NUL — so
  a refusal belongs there and nowhere on this side, and `Bytes` is
  no longer needed to carve out those five. The original entry
  follows, kept because its reasoning is what made the choice
  legible.
- H1 (as raised). A decision, not a bug report,
  raised 2026-09-05 (lane B found it, lane D verified both engines).
  Text that arrives from outside can carry a NUL, and the primitives
  disagree about it: `.length`, `char_code`, `starts_with`,
  `ends_with`, `trim` and `+` read the header's length and keep the
  whole value, while `==`, `contains`, `index_of`, `split` and
  `replace` are C string calls that stop at the first NUL. The
  visible consequence is a silent wrong answer: a five-byte text
  compares EQUAL to its own two-byte prefix.
  WHERE A NUL COMES FROM, corrected 2026-09-05 (lane B; lane D had
  recorded it as foreign-only and verified the correction): it needs
  no foreign input. `@std/text`'s `from_codepoint(0)` answers a
  one-byte NUL and `from_codepoints` weaves one, so any package
  depending on @std/text mints one in process — `"ab" + z + "cd"` is
  five bytes long and compares EQUAL to `"ab"`, with no file, env
  var or child anywhere. It also arrives from outside.
  So TWO ways out decide it, not three: make the five length-aware
  (text is bytes, `==` compares 5 against 2 and answers false), or
  add a `Bytes` value whose scope is exactly those five and leave
  `string` meaning text. A third — refuse a NUL where foreign text
  ENTERS — does not close it, because the mint is inside; it only
  becomes an option as "a NUL is unrepresentable in a `string`",
  which means `from_codepoint(0)` refuses too. The @std/sqlite lane
  will meet this first, since a blob is the common case, and it can
  test the whole class with `from_codepoint(0)` and no fixture file.
  THE SECOND WAY OUT IS TAKEN, AND IT FORCES THE FIRST (2026-09-06,
  the HTTP lane): `Bytes` exists, `string` means text, and
  `b.text()` answers a string for a NUL because U+0000 is text. So a
  CORRECT conversion now mints the five-byte string that compares
  equal to its two-byte prefix, from the honest direction, and the
  five C-string primitives are BUGS ON `string`'S SIDE to fix, not a
  reason for `text()` to lie. Calibrated by lane B from the bodies:
  `==` is ONE memcmp (`str_len(a) == str_len(b) && memcmp`),
  behaviour-preserving by construction for every NUL-free string,
  guard for a foreign pointer kept; `contains`/`index_of` share one
  length-aware search helper; `split`/`replace` are REWRITES that
  decide the end by NUL today and must reproduce the PINNED edges —
  a trailing empty dropped, a leading one kept, `"".split(".")` is
  `[]`, the empty separator — none of which a rewrite may normalise.
  Land `==` first: it is the one that misleads rather than
  under-reports. Owner: unassigned; the runtime is lane A's.
- ~~H0. THE FN TYPE DROPS `mut` — A SOUNDNESS HOLE~~ — CLOSED
  2026-09-05 by lane C, and re-verified by lane D against the probe
  that found it. A `mut`-taking fn stored in a NON-`mut` fn type used
  to keep writing through, so a call through that seat mutated an
  IMMUTABLE `let` with no diagnostic — eval and native both answered
  `1 2 2` where the V1 law demands `1 1 0` — and the compiler's own
  MethodRow/PropertyRow seam rode it. Today the same probe refuses at
  the store: F2010 "field `go` is `fn(Cx, int) -> int`, this is
  `fn(mut Cx, int) -> int`", and an immutable place handed to a marked
  seat is F2048. A fn type carries a parallel `muts` in the interner
  and the key carries them, so the agreement door refuses with no new
  law written; the seat law reads MARKS rather than a DeclId, so the
  direct and indirect calls are ONE rule. The asymmetry is deliberate
  and measured: a seat that PERMITS writing accepts a callee that does
  not write (so plain builders keep their honest spelling), while a
  seat that promised not to write refuses one that does. F2051 is now
  zero tree-wide.
  ONE THING THE FIX LEAVES, found by lane D probing the closed hole
  and reported: a fn that FORWARDS its `mut` seat into another `mut`
  seat is warned F2051 "never writes through it", and taking the
  warning's advice does not compile — dropping the mark makes the
  inner call F2048 "`cx` is not `mut` — seat 1 of `go` writes through
  it". Passing to a mut seat IS writing through, from the caller's
  side. Nothing in the tree hits it (F2051 is zero), and the shape
  that would is exactly the `seated_walk` verb lane C declined —
  which is a second reason to have declined it.

- H2. A METHOD LAUNDERS AN IMMUTABLE RECEIVER — THE SIBLING OF H0
  (found 2026-09-05 by lane D; lane C's, typing). A WRITING METHOD
  called on a NON-`mut` receiver is only WARNED (F2047), the program
  is ACCEPTED, and the mutation is OBSERVABLE — the same `1 2 2`
  signature H0 wore, where deep immutability (spec 11.5) and the
  memory doctrine's "aliasing NEVER observable" both demand `1 1 0`.
  The comparison IS the finding: the DIRECT write through a non-`mut`
  parameter is an ERROR (F3005 "parameters are immutable"), and the
  IDENTICAL write moved behind a method is a warning that compiles.
  A method call launders an immutable seat into a mutable one. Probed
  at both depths (`c.keep(n)` and `w.cache.keep(n)`) and on both
  layouts (a scalar field, a list field): eval == native == `1 2 2`
  on all four.
  THE SCALE, measured with main's compiler under the watchdog and
  DEDUPED by site: F2047 stands at 101 unique sites — workspace.av 62,
  features/contexts.av 11, test_run.av 6, lower.av 6, db_test.av 5,
  receivers.av 5, the rest in twos. THE COUNTING TRAP, paid once here:
  checking one package reports its DEPENDENCIES' warnings too, so
  summing per-package runs double-counts — `cli`'s 168 F2040s are 166
  std-avrac sites and NONE of its own, and the tree's real F2040 total
  is 191 unique, not the 361 the sum claims. Count unique `file:line`,
  never the sum of runs. These are TRUE positives: the lint traces a
  method that genuinely writes, and every one probed mutates
  observably. This is
  not a lint that miscounts the wrong thing (that is F2040's, lane
  C's slice) — it is a law that shipped as a warning and was never
  paid. It arrived with `feat(impls,fns): the inout seats`.
  THE ADVICE TERMINATES, so the conversion is mechanical: marking the
  seat `mut` moves the refusal up to the call sites as F2048, and
  marking the root binding `mut` clears it — probed clean end to end.
  And `mut` on a record parameter is ADVISORY today, not a
  representation: the mutation propagates either way, so the
  conversion is annotation-only, with no semantic or layout change.
  WHAT MAKES IT A DECISION rather than a patch: 62 of the 101 are the
  MEMO KERNEL, where `parsed(ws, f)` and its siblings read as pure
  queries while writing a cache through `ws.db`/`ws.decls`. Enforcing
  the law spells that mutation out — every query fn takes `mut ws` —
  which buys P7 (visible magic) at the cost of P3 (zero ceremony).
  The other answer is rung 14's own 11.3 `Cell<T>`, which hides it
  again and is the shape the spec already reserves for exactly this.
  Lane C's call; lane D will do the mechanical conversion on request.
  LANE C'S DECISION 2026-09-05: DO NOT CONVERT. The 62 memo-kernel
  sites are the case 11.3's `Cell<T>` exists for, so converting them
  to `mut ws` now would be undone when the cell lands — two
  conversions of the same sites, one of them waste — and the rest are
  lane C's files, which change again with the cell ABI. The whole
  conversion lands with S2, from lane C, and F2047 stays a warning
  until that day. IT IS NOT NOISE: it counts exactly the right thing
  and fires because the conversion was never paid, which is the
  MIRROR IMAGE of F2040 and not another instance of it. A reader who
  has just watched a lint's false positives be deleted must not
  conclude that a loud warning is a warning to weaken.
  AND THE HOLE LAUNDERS CAPTURE-BY-VALUE TOO (lane D, taking the two
  offered exceptions). A lambda captures by VALUE — F3005 says so —
  yet a mutation reaching the capture through a method reaches the
  ORIGINAL: eval == native == `1 2 2`, the outer binding reads 2. And
  the compiler KNOWS, which is the sting: annotate the seat honestly
  and it REFUSES at the capture with F2048 "`t` is captured by value
  — a lambda's copy cannot fill seat 1 of `verified_double`". The
  honest spelling is refused where the silent one compiles, and that
  asymmetry is the mechanism by which this debt was never paid.
  query/tests/db_test.av is the live case: its memo fixture captures
  `t` in the family lambda, so those 5 sites are NOT
  annotation-fixable and the fixture's behaviour rests on the hole —
  it needs restructuring, not a `mut`, and it goes to S2 with the
  rest. std-toml's 1 site WAS ordinary and is FIXED (three marks: the
  two reader fns and the root binding), leaving 100.

  THE CAPTURE CENSUS (lane D for lane C's S2 scoping, 2026-09-05).
  Method: mark all 100 F2047 seats `mut`, cascade with the compiler
  until no further seat can be marked (4 rounds, 66 more seats), and
  read what REMAINS. F2047 goes to 0 and NO other error is introduced,
  so the conversion itself is sound; 55 unique sites refuse, in four
  kinds, and capture-rootedness is NOT the dominant one:
    CAPTURE 9 — a lambda's by-value copy cannot fill a `mut` seat.
      8 PRODUCTION (workspace.av 7, lower.av 1), 1 FIXTURE (db_test).
    VALUE-ARG 38 — a `mut` seat handed a VALUE, not a place.
      36 TEST, 2 PRODUCTION (workspace.av).
    ALIAS 1 — typing.av:410, `self` handed `mut` twice in one call
      (`decl_type_of(self.view.decls, self.facts.voices, …)`): two
      `mut` seats rooted at one place, the aliasing law refusing
      correctly. PRODUCTION.
    NOT-MUT 7 — packages_test.av roots the sweep did not reach. TEST.
  SO THE SHAPE OF S2 IS 11 PRODUCTION SITES AND 44 TEST SITES, not
  100 of anything. And all 8 production captures are ONE shape: a
  CALLBACK REGISTRATION into the memo machinery — `ws.db.family((arg:
  int) -> refetched(ws, f, arg))`, `ws.decls.arm((d: DeclId) ->
  ensured(ws, d))`, the `program:` thunk, `(w: Wanted) ->
  lowered(ws, …)`, and lower.av's `(w: Wanted) -> lower_unit(a, …)`.
  The lambda captures the workspace and calls back into a query that
  writes its cache, which is the same shape as the workspace cycle
  `disarmed` exists for. Weak captures and `Cell<T>` are aimed at one
  target between them.
  THE CENSUS IS A FLOOR, not a total — see H3. F2047 can only count
  a write the receivers pass SEES, and a write through a borrowed
  local is invisible to it, so 100 is what the lint reaches and not
  what the law covers.

- PAID 2026-09-14 (comptime/static): `NodeStore.every_expr` in
  core/nodes.av, a registry beside the fingerprints; `runtime_read`,
  `reads_settled_seat` and `Program.kind_rows` walk it; the F0900
  below is F2074 in consts_adversarial. THE EXPRESSION WALK STOPS AT
  HIDDEN BRANCHES, and two consumers want the whole body (found
  2026-09-13 by the COMPTIME STATIC red team). `post_order` walks `kids`, and `if`, `match`, `catch`, the
  nullable arms and a lambda's body hide theirs (each types under its
  own narrowing), so a walk written for "every expression a body
  holds" sees the unconditional ones only. (1) A DEFECT SHOWN TO A
  USER: `fn g(n: int) -> int { const C = if true { n } else { 0 }  C }`
  is not refused F2074 (`runtime_read` never sees `n` inside the
  branch), settles, and `./avra check` prints `error[F0900]: defect: a
  compile-time value did not cross as `int``. (2) The package-kind
  registry (`Program.kind_rows`) registers `refuse_as("E1", …)` only
  where the walk reaches, so a conditional kind — most kinded
  refusals — registers by being spoken and `avra explain` misses an
  unspoken one; its miss says so. RECORDED TRIGGER — FIRED AND PAID at
  865c806: `every_expr` is one walk (core/nodes.av) and all three
  consumers read it — `runtime_read` and
  `reads_settled_seat` (lower_state.av) and `kind_rows_in`
  (workspace.av).
  The third consumer named the concept, as recorded.
- H3b. A `mut` SEAT'S ARGUMENT IS NEVER OPENED (found 2026-09-13 by
  the COMPTIME STATIC red team, both engines, native and evaluated).
  A `mut` local handed whole to a `mut` seat is LOADED, not opened
  unique, so the callee writes the box the local still shares:
    fn big() -> List<int> { [i for i in 0..40] }
    const BIG = big()
    fn grow(mut xs: List<int>) -> int { xs.push(9)  xs.length }
    mut ys = BIG
    let g1 = grow(ys)
    let shared = [1, 2]
    mut alias = shared
    let g3 = grow(alias)
    "${g1} ${BIG.length} ${g3} ${shared.length}"
  answers `41 41 3 3` on both engines where a copy is a copy demands
  `41 40 3 2` — the const's own data and the `let`'s list are written.
  Under static data (comptime/static) BIG is a laid-out global, so the
  write grows a static buffer; the runtime's `array_grow` moves the
  cells out (`laid_out`) rather than freeing or reallocating memory
  that is the binary's, which keeps the hole exactly the once path's
  and no worse. THE FIX IS ONE VERB AND IT IS BLOCKED: opening every
  `mut`-seat argument unique at the call (`seated_regs`, probed in
  places.av — a `.Root` cell through `unique_box`, a path through
  `slot_opened`) TRAPS THE COMPILER'S OWN `check` ("index 304 is out
  of bounds (length 303)"), and so does the narrower form that opens
  only handed LOCALS: the compiler's source hands `mut` locals whose
  box another holder shares and relies on the write reaching both.
  So H3b closes with H3 — after the sites that ride the channel are
  converted — and not before; the reproducer above is its test, and
  the F2048 law (a `mut` seat wants a `mut` place) already names the
  seats to audit.
- H3. THE BORROW CHANNEL IS SILENT — H2'S SIBLING WITH NO WARNING AT
  ALL (found 2026-09-05 by lane C; verified here). H2 at least warns.
  Borrow the field into a local first and there is NO diagnostic:
    impl Bag { fn sneak(v: int) { mut ys = self.xs  ys.push(v) } }
    fn touch(b: Bag, v: int) -> int { b.sneak(v)  b.size() }
  `touch` takes an IMMUTABLE parameter; two calls answer `1 2 2` on
  both engines where 11.5 demands `1 1 0`, and `./avra check` reports
  ZERO diagnostics (verified by lane D against the probe). The direct
  spelling warns F2047; the borrowed one is invisible, because the
  receivers pass never sees a write through `self` — the write goes
  through a local that merely ALIASES it. Measured in our own source:
  37 `mut x = self.field` borrows (46 counting other roots), and lane
  C reports 5 of their methods classified NON-WRITING because of it.
  So H2's 100-site census is a FLOOR: the lint counts what it can
  see, and this channel is what it cannot.
  THE CLOSURE IS ONE DELETED PREDICATE, and it is already scoped —
  lane C read it out after lane D flagged the gap, and lane D
  verified it in place. features/places.av:57 is the whole hole:
    if borrows(cx, s) { cx.emit(Ins.Load(dst, cell!)) }
    else { cx.emit(Ins.CallRt(dst, "avra_cell_unique", [cell!])) }
  `borrows()` answers true for a `mut` local bound to a PARAMETER'S
  FIELD PATH, so that one cell writes THROUGH to the field where
  every other cell opens copy-on-write. Delete it and `mut ys =
  self.xs` opens unique — the parameter holds a reference, so the
  count is two, the write lands on a COPY, and the probe answers
  `1 1 0`. The carve-out names its own expiry in its comment,
  "bs2's aliasing, honored until self-host", and self-host has
  happened: it has outlived the condition it was written against.
  SO IT LOOKED LIKE ONE SLICE WITH THE I34 RETIREMENT — but see the
  correction below; it is two, and only the first has landed. Deleting the borrow makes the
  34 sites copy, and the fix at each is the DIRECT form
  (`self.xs.push(v)`), which cloned once per write BEFORE S3 and does
  not after. That is why the sweep was unaffordable in both
  directions until liveness landed: keep the borrow and stay unsound,
  or drop it and pay a clone per write. The slice is the 34 rewrites,
  the deletion of `borrows`/`is_borrow`/`borrows_field` and the
  borrows column, and I34's 17 licenses retiring.
  WHAT STAYS OPEN AFTER IT, named rather than assumed closed: not
  unsoundness, but SILENCE ABOUT INTENT. A future `mut ys = self.xs`
  will compile, copy, and say nothing — the author meant a borrow and
  got a copy. The remedy is already recorded and deliberately not
  built ("a lint for a mutated copy of a field that is never read
  back"), and it stays recorded: once the copy IS the semantics, this
  is a want, not a soundness question.
  IT REORDERS THE ARC. S3 (liveness) goes BEFORE S2 (the receiver
  conversion), for three reasons that are not preferences: flipping
  F2047 to a refusal while this channel is open would refuse the
  HONEST spelling and pass the silent one, which is worse than the
  warning; S2's own "what dies" list deletes the borrow mechanism,
  and the 17 I34 licenses exist precisely because the pass lacks
  liveness, so deleting the borrow first turns each into a cloning
  path write (measured 60x); and S3 needs no owner decision where S2
  needs several.
  RECORDED TRIGGER — FIRED AND PAID at 85aa9a8 (S3b): CLAUDE.md's "A
  BORROW ALIASES, A PATH WRITE THROUGH A SHARED INTERMEDIATE COPIES"
  lost its performance rationale — liveness reaches the OWNED TWIN
  choice, so a path write no longer finds its own read's +1 and no
  longer clones. Sweeping 34 borrow sites measured FREE (6.87s against
  6.90s) and all 17 I34 licenses retired (DOGFOODING.md I34, RETIRED). A borrow is now written for its ALIASING and never for
  speed; nine sites still need that aliasing, and that same aliasing is
  H3's silent channel.

  THE RETIREMENT LANDED AND H3 DID NOT CLOSE (2026-09-05, lane C's
  measurement, lane D's census). The I34 retirement is in at cfa834d
  and all 17 licenses are gone, but DELETING the borrow mechanism
  reproduced S0's failure exactly — the compiler built with EMPTY
  declaration tables, "index 0 is out of bounds", because a borrow
  that becomes a copy pushes into the copy. Nine sites still need the
  aliasing (`ws.packages`, `ws.specs`, `ws.asks`, the db_test
  fixture), every one of them blocked at the CAPTURE wall this
  ledger's census measured. So H3 closes with S2, not with the
  retirement: lane D's first reading — that the closure was a
  separate thing — was right, and the "one slice" correction above
  was itself wrong. TWO SLICES: the retirement (landed) and the
  deletion (blocked on captures).
  AND THE RETIREMENT ALSO NEEDED S3b, which is why the advice to stop
  writing borrows dates from cfa834d and not from the message that
  first gave it. S3 alone made the compiler 3.4x SLOWER (7.5s to
  25.6s, lane A audited the machine so the ratio is the change): a
  read of `self.field` took the OWNED TWIN whenever the destination
  was managed, and that +1 lived to the scope's end, so the write
  that followed found the value shared and cloned. S3 governed the
  slot `Load` alone. THE REGISTRY LESSON from fixing it: which rows
  may be borrowed is a `lends` COLUMN, false by default, never a name
  test — `avra_array_pop` also has an owned twin and must NEVER be
  borrowed, because a pop HANDS OVER, and a row nobody has thought
  about must be safe.
  THE POST-RETIREMENT CENSUS (lane D, on cfa834d). The true total is
  100 in std-avrac — UNCHANGED from the floor — plus 3 in std-toml,
  now fixed. The previously-hidden sites did NOT become visible, and
  the reason is structural rather than lucky: F2047 fires on a
  non-mut RECEIVER AT A CALL SITE, and the retirement moved writes
  from a borrowed local to `self.field`, neither of which is an F2047
  site INSIDE a method — the warning lives at the caller, which the
  census had already counted. Only FREE FUNCTIONS taking their state
  as a parameter gained visible warnings, which is why every new one
  was in std-toml (`placed`, `refused`, `read_entry`; three marks,
  back to zero, no errors). So "the census is a floor" was true for a
  different reason than either lane thought: H3's channel is not
  countable by F2047 at all, because a self-rooted write never was.
  The production blockers are UNCHANGED — 9 captures (8 production,
  1 fixture), 38 value-args (2 production), 1 alias, and the rest
  tests. S2's shape does not move.

- H4. A GENERIC BODY IS NEVER LOWERED BY `check` (found 2026-09-05 by
  the sqlite campaign's FFI lane, verified here). `declared()` filters
  through `lowers_plain`, which demands the declaration's OWN type
  parameters and its PARENT's both be empty (lower.av:217-226), so a
  generic fn — and a method on a generic type — is never seeded, in a
  library or a program alike. Nothing instantiates it into existence
  either, so `avra check` over a package is BLIND to the
  lowering-defect class in every generic body it holds: the defect
  waits for a caller with concrete types, which in a library may
  never arrive from inside the package at all.
  NOT the wider hole first reported, and the retraction is the
  finder's own: a library DOES lower its uncalled exports, because
  `union` seeds from every declared body exactly when `entry == null`
  (lower.av:134) — which is precisely a library. Verified here.

- H5. A DECLARATION IS NOT EVIDENCE THE SYMBOL EXISTS (sqlite lane's
  red team, probed here in full). `./avra check` accepts an `extern
  fn` for a C symbol that does not exist, with NO signal of any kind:
  `extern fn sqlite3_win32_set_directory(a: int) -> int` checks
  clean, and the LINKER produces the entire failure at build time —
  "Undefined symbols for architecture arm64", exit 1. So the gap
  between a declared boundary and a real one is invisible for the
  whole of the checking phase, and a package can ship a declaration
  nothing satisfies. `nm` over the `[link]` row's libraries is the
  only step that knows. THE DECISION, not yet made: whether `check`
  should verify declared symbols against the manifest's libraries
  (it can, and it would make the extern boundary honest at the phase
  that claims to check it), or whether the linker is the right and
  sufficient owner of that failure. Filed as a question because the
  answer sets what `check` PROMISES.

- THE SCOPE-NARROWING PATTERN — the bar is met, the audit is not done
  (lane D, 2026-09-06/07). FOUR laws in CLAUDE.md were found this
  session to have a stated scope NARROWER than their actual danger,
  every one found by a lane walking into the gap and none by anyone
  auditing the file: the second-build rule said CODEGEN and applied
  to the front end; the syntax-change protocol said REWRITING and
  applied to additions; the recovery law said WITHIN A RULE and
  applied across rules; and the base-naming rule said PROBE LOGS and
  applied to a live correction (a count offered as a correction, each
  side right about a different tree).
  THE MECHANISM, which is why it recurs: a law is written from the
  ONE instance that taught it, so its wording carries that instance's
  shape — and the shape is invisible to the author precisely because
  it is the only case they had. The author cannot see it; the next
  lane walks into it.
  I SET THE BAR AT FOUR and it is met, so this is a shape rather than
  three accidents. What is NOT done is the deliberate audit: reading
  every law in the file and asking what its wording EXCLUDES that its
  mechanism does not. That is a large pass over a 1500-line file and
  it is the owner's call whether it happens, not a thing to start on
  a hunch at the end of a long session.

- H. SUGAR THE CODE WANTS, with the sites: a `rest ->` arm the
  compiler EXPANDS or refuses-until-acknowledged (~50 lines of pure
  variant enumeration in core/parts.av and core/nodes.av; F2040
  already names `rest ->` — verify what it does today); fn-typed
  arguments through generics, mono-safe (`as_each<T>` for
  grammar/builders.av's four `.Ok([want(f(x), …)? …])` copies, and
  the memo bracket); a BINDING across `or` alternatives (memory.av's
  `.Call`/`.CallPtr` spelled twice, F2039); ~~an enum's ORDINAL~~ — LANDED 2026-09-05 (lane D): `v.ordinal` is
  a property row on enum shapes, the tag read; workspace.av's
  `Family.ordinal()` and its runtime agreement guard can now go (lane
  C's file); ~~a
  no-argument generic call pinned by its WANT~~ — LANDED 2026-09-05
  (lane D): a Var the arguments leave free unifies the declared
  answer with the seat's want, and with no want yet the call goes
  HUNGRY like a generic literal (fns/check.av `pinned_by_answer`);
  the tree's explicit no-argument pins are gone (the commit after the seed carried the feature); the one that stays sits in a generic struct literal's field seat, which unifies rather than wants — in "The subset today". ~~A `dyn` want in a
  struct-literal FIELD~~ — it already reached one (probed both
  engines); the 34 pins in program.av and 7 in the cli were
  bootstrap ceremony and are inlined (4 more sit in lane B's held
  cli files); reverse iteration (`last_slash`, `reversed`).

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
unless it is `rest`, the contextual deliberate remainder
(SUPERSEDED 2026-09-05: the hole is judged by ANSWERING ARMS, not by
how many it hides — the landing is in LANE C's block). LOWERING:
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
- THE ORPHAN RULE (STRICT, at the spec's PACKAGE level since
  2026-09-04, lane C): an impl lives in its type's package, or in
  its trait's when the trait is this package's (F2037) — a module
  may give a sibling's type its verbs. A refused impl still
  declares its methods as WRECKAGE (hole sigs, the receiver's seat
  among them — a param read from a seatless sig was this class's
  second crash), and the refusal stands alone: the impl serves its
  target for the walk.
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

(REVERSED BY MEASUREMENT 2026-09-04 — THE SPEED HUNT below: the
registry's probe was the compiler's single largest cost, and the
header took the compiler checking itself from 59.8s to 28.8s. The
law survived the reversal in a new form: every pointer Avra holds
carries a header, statics as IMMORTAL ones, so the no-op on a
literal is still by construction — read from the header, not
looked up in a table.)

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
       niche strings in mut CELLS already work; a CAPTURE LANE is
       the third slot, refused since the header's round); errdefer; the
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

PAID at 296c008: `make seed-check` links the committed
seed and builds packages/cli with it, refusing with "the seed cannot
compile HEAD — run `make seed` (a stale seed is a fossil)". It is a
gate step (`make gate`), so a fossil is caught the day it forms.

## ~~THE SUBSET NOTES ARE STALE — an audit owed~~ — DONE THE SAME DAY
## IT WAS WRITTEN (2026-09-04), and never marked until 2026-09-07

STRUCK. The audit this section asks for was performed on the day the
section was written: all 76 notes probed, 37 ACCEPTED and deleted, 28
still refused and moved into CLAUDE.md's "The subset today" with
their refusals quoted, 11 reworded. The completion record is the
struck entry above (search "Every entry of CLAUDE.md's"), and the
"bs2 subset notes" section it describes no longer exists in
CLAUDE.md.

WHY IT MATTERED THAT NOBODY MARKED IT: this section reads in the
PRESENT TENSE — "CLAUDE.md carries 76 notes", "an audit owed" — so
three days later the tasks master read it and filed the audit as open
work owed by lane D. Nobody misread anything; the text says what it
says. It is the same shape as the retracted NUL receipts: A
CORRECTION THAT DOES NOT SWEEP THE OLDER PASSAGES LEAVES FINISHED
WORK WEARING AN OPEN TASK'S CLOTHES, and a ledger's stale entry
recruits, exactly as a wrong owner in a trigger does.

The original text follows, kept because its reasoning is why the
audit happened at all.


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

### LANDED: the refcount in a header (2026-09-04)

`g_own` is gone. Every box carries sixteen bytes before its payload
— `{ u32 tag "AVRA", i32 kind, i64 rc }` — and retain/release read
the header the payload's own cache line holds. MEASURED, like for
like, on the compiler checking itself (`./avra check
packages/std-avrac`, user CPU):

  registry                                   59.8s
  header                                     28.8s   (2.07x)
  + the impl index and the source memo       22.3s   (2.69x)
  + the manifest memo                        21.0s   (2.85x)
  + the builder index                        19.7s   (3.04x)
  + the memo by ordinal and cursor           18.5s   (3.23x)
  + lengths in the header                    17.6s   (3.40x)
  + the externs once, the miss path          15.6s   (3.83x)
  + the query kernel flat                    14.9s   (4.01x)
  make gate, wall                           223s -> 152s -> 135s
  make avra (the compiler building itself)  37.6s -> 25.3s
  peak RSS of a gate                         1.8 GB (measured, the watchdog)

WHAT THE PRIOR ATTEMPT GOT WRONG, now known: it counted string
CONSTANTS. A constant lives in read-only memory and is released at
every scope exit, so a counted one either faults on the write or,
made writable, reaches zero and hands `.rodata` to `free()` — the
"bottomless" reclaim was the allocator walking a corrupted heap. A
constant is IMMORTAL: `kind = STATIC`, its header read and never
written. `avra_llvm_build_global_string_ptr` emits `{ i32 tag, i32
-1, i64 0, [N x i8] }` at align 16 and answers a GEP sixteen bytes
in. The same kind covers the runtime's own words, argv and the
environment (`str_static`). The tag restores "not mine": `hdr()`
refuses an unaligned or sub-image address before reading, then a
header without the tag — which is exactly what carried the
TRANSITION: the first rebuild runs a binary whose own literals are
headerless (the old wrapper is baked into it) against the new
runtime, and every literal reads as foreign; the second rebuild
reaches the fixed point. The OLD seed bootstraps the same way and
rebuilt a byte-identical compiler.

THE BUG THE REGISTRY HID, found by the guard the day the header
landed: a lambda calling a CAPTURED fn value released the box it
called and had never retained it. `callee_binding` read the lane
as `Type.Ptr` — "the lane holds a pointer, and says so" — and `Ptr`
is UNMANAGED, so the memory pass neither owned the read nor
retained the seat, while the callee (callee-cleans) released it at
exit. Net -1 per call; under the registry a released box was "not
mine" on its second release, so the leak of nothing was silent;
under the header the second release is a write into freed memory.
`AVRA_RC_GUARD=1 corpus/closures` named it in one line. THE FIX IS
A FACT: `TypeFacts.captures` — each lambda's captures typed in lane
order, seated by `lambda_walked` through the driver's own
`binding_ty` — and every capture read in lowering wears it: the
ident (`read_binding`), the callee (`callee_binding`), the pack
(`capture_regs`, which also closes the WIP's bug (1): a captured
`int` no longer wears the lambda's box type, so the pass stops
retaining a number). `read_wearing(e, b, ty)` is the one read with
the type named by the caller who knows it; `slot_reg` mints a
boxed slot's load at that type. 69/69 corpus binaries clean under
the guard.

THE RUNTIME ALSO LEARNED to wreck loudly: a freed box's tag is
cleared before `free`, the guard's log is bounded (8M events), and
a list or map past 2^31 cells traps as a corrupted box instead of
asking the machine for the memory.

WHAT THE HUNT COSTS TO RUN: a gate is one process at ~1.8 GB for
two and a half minutes. It runs in the foreground, alone, under
`tools/watch.sh` — the machine panicked (a WindowServer watchdog
timeout) with a background gate and compiler runs beside it.

THE WRAPPER, SWEPT. backend/llvm_wrapper.c was "adopted whole" from
the bootstrap tree: 1643 lines, 135 fns, of which the tree named 62.
The review round deleted 73 — a coverage subsystem, a JIT and its
`@comptime` string copier, float and bit ops, `emit_object`, the
`split_defines` IR splitter — and THREE WEAK SHIMS of runtime fns
(`avra_host_env` among them, answering a RAW `getenv` pointer: a
headerless source the law forbids, hidden behind `weak` "for bs2,
which links this one alone"). 640 lines now, every fn named by
llvm_api.av, compiled under -Wall -Werror. `avra_rc_alloc` in the
runtime served the JIT alone and went with it. The bs2-era `.ll`
files in packages/*/src — the only remaining spellings of its name —
were swept; `make fresh` owns the sidecars.

THE COLD-BOOTSTRAP note in the WIP is closed by THE SEED (above):
the binary is not the bootstrap; `bootstrap/seed.ll` is, refreshed
with this slice.

THE RED TEAM'S YIELD (38 programs: every value category captured,
every construct crossed, arities 0..3 managed in and out, 20k-deep
reclaim, 20k-call churn, the constants of every shape, the host's
words). Four LATENT crashes, every one reproduced on the pre-slice
compiler built from HEAD's seed, so none was the header's — and
every one a refusal in its own words now, pinned in
closures_adversarial_test (26 specs):
  (1) A PAIR NULLABLE CAPTURED segfaulted the compiler: the pack
      pushed two words into one lane, the lifted body extracted a
      pair from an i64, and LLVM's C API answered NULL. A capture
      lane is a SLOT; it now asks the slot law the list and the
      field ask (`slot_worthy`, through a `capture_seats` verb on
      the typing context) and refuses: "a lambda cannot capture
      `int?` yet". The lane joins O4's list below — pairs in
      slots are one design, three sites.
  (2) A CALL THROUGH A MUT FN CELL failed LLVM verification: the
      cell's load was minted at the CALL's type (its answer, an
      int), so the box loaded as `i64`. Same species as the capture
      lane: `callee_binding` now wears the BINDING's type for the
      two reads that mint (`def_type_of` for a cell, the captures
      fact for a lane). lower_test pins both shapes.
  (3) ASSIGNING TO A CAPTURE, a lambda's param, or a pattern's bind
      showed the user a DEFECT ("an assignment to a non-place
      survived a clean analysis"): resolve's law said "the walk
      already spoke" and it had not. Four voices now — captured by
      value, a parameter, a pattern's bind, a fn's name.
  (4) A FN'S NAME walked through resolve as a place, because the
      rule asked `binding_of(name)` — a LOCALS table — instead of
      the binding the walk had just recorded. Ask the binding: the
      name-keyed verb had no other reader and died with the bug.

## THE HTTP RED TEAM — @std/http, all eight classes (2026-09-07)

Four defects fixed with tests (131e146, a406103, db23051, bc39156).
Two findings are recorded rather than fixed, because each is a
DECISION someone else owns.

### (1) ABSOLUTE-FORM IS FRAMED AND CANNOT BE ROUTED — a routing differential — FIXED 2026-09-08

The framer ACCEPTS absolute-form by RFC 9112 §3.2.2, and frame_test
pins that it does. `Request.path()` then answers the target up to its
first `?`, which for `GET http://h/p HTTP/1.1` is the WHOLE URI —
scheme, authority and all. So a route declared `/p` answers the
origin-form request and 404s the absolute-form one for the same
resource. Probed at 9e97b5b, both engines:

    origin-form   /p           -> 200
    absolute-form http://h/p   -> 404
    path=[http://h/p] segs=4

RFC 9112 §3.3 says a server MUST accept absolute-form and MUST ignore
the received Host when it does, so a conforming origin server routes
on its PATH. The differential is the hazard, not the 404: a front end
that normalises absolute-form to origin-form and an Avra origin
behind it disagree about WHICH ROUTE ANSWERS, and a filter on
`/admin` in front of a server that reads `http://h/admin` as a
different path is the whole shape of a routing bypass.

FIXED AS THE LEAD RULED, and the contract moved rather than the
framer: `path()` answers the PATH COMPONENT of the target in EVERY
form. Origin-form as sent; absolute-form with scheme and authority
stripped, with `authority()` beside it handing back what was stripped
— which §3.3's "its authority wins over `Host`" needs in order to be
obeyable at all; ABSENT for `*` and CONNECT's authority, which name no
resource, and `dispatch` never walks the table for those. Measured in
this tree at 317c72b and after:

    before  origin /p 200  absolute http://h/p 404   path=[http://h/p]
    after   origin /p 200  absolute http://h/p 200   path=[/p] authority=[h]

AN EMPTY PATH IS `/` (9110 §4.2.3) and is MINTED rather than sliced:
`http://h` names the root, and answering the empty octets would have
404'd the one spelling of the root that carries no `/` — the same
differential one target further in. THE HOSTILE CASE THAT PAID: the
authority ends where the PATH CLASS does, so `http://h?x=/admin` has
authority `h` and path `/`, and the `/` inside the query neither
becomes the path nor extends the authority. `corpus/http-route` proves
it on both engines; 31 specs in `target_form_adversarial_test.av` go
through the real framer and the real router.

### (2) A PROGRAM ENDING IN A RANGE-HEADED `for` CRASHES THE COMPILER

Not @std/http's. Found while writing an ownership probe, minimised to
one line, and it is on MAIN as well as on lane/http (main's build/avra
of 2026-09-07 20:08 answers the same):

    $ cat a.av
    for i in 0..1 { let x = i }
    $ ./avra check a.av
    avra: index 3 is out of bounds (length 3)

Exit 2 — a trap, no diagnostic, no file, no line, and the same for
`run` and `build`. The index is always exactly the list's length, so
something reads one past a per-statement table. It fires only when
the LAST top-level statement of a program is a `for` over a RANGE:
the same loop over a LIST is fine, a `while` is fine, a `for` inside
a fn is fine, and moving one statement below it is fine.

    for i in [1, 2] { let x = i }        -> clean
    while false { let x = 1 }            -> clean
    for i in 0..1 { let x = i }  then  0 -> clean

It bites this surface because a program driving a server ends in a
turn loop, which is exactly that shape. Reported, not fixed: it is
`packages/std-avrac`'s, and a front-end change there wants the
two-build protocol and its owner.

## THE SUBSTRATE-VALUES RED TEAM — `Bytes` at the row seat, and @std.net (2026-09-07)

Base `9e97b5b`, every probe re-run at HEAD after two builds. Six
defects fixed with tests; three findings are recorded rather than
fixed, because each is a DECISION the seat law's owner holds.

FIXED, with where each is pinned:
1. `starts_with` walked to a NUL where `==` walked the length, so at
   equal length the two disagreed about the same pair. The pair, in
   the spelling that MINTS the hazard (`\0` is not an escape, so a
   literal cannot carry one):

       let a = "ab" + from_codepoint(0) + "cd"
       let b = "ab" + from_codepoint(0) + "ce"
       a == b            -> false
       a.starts_with(b)  -> TRUE

   `strncmp` -> `memcmp` over the header, four cases in std-text's
   NUL block. The sweep that taught the other five verbs the length
   walk named five, and these two were the sixth and seventh.
2. `avra_fd_read` clamped a zero ASK up to one, so `Conn.read(0)`
   took a byte off the wire nobody asked for — the next message's
   first byte, taken and never reported. The answer encoding already
   spends 0 on EOF, so a zero landing had no code; it presents its
   token now and answers an empty box. A negative ask answers
   -EINVAL rather than reading. `corpus/net-sizes`, both engines.
3. `Poller.wait(ms(-1))` BLOCKED FOREVER — the sentinel `connect`
   refuses by name three verbs up, in the one verb an event loop
   cannot afford to have block. Absence already spells forever, so a
   present negative budget is refused.
4. `Machine.octets` had a catch-all where `text_val` has every
   variant, so a string at a row that READS OCTETS
   (`avra_bytes_len("hi")`) answered 2 compiled and "defect: a
   non-Bytes value reached a byte operation in a clean program"
   interpreted. That is 0ef691e's law read the other way, and it was
   the half left standing.
5. A ROW THAT ANSWERS A SCALAR FROM OCTETS NEVER DECODES —
   `byte_length` was the first of the family and `avra_str_char_code`
   its sibling, refusing octets the native row answers for.
   `BytesOfStr` joined it: octets in, octets out, no decode between.
6. A `Bytes` carrying a NUL crossed CORE's four name-resolving rows
   unguarded, so the same holed value refused as a `string` read a
   different environment variable and RAN A DIFFERENT PROGRAM as a
   `Bytes`. `tools/traps.sh` gained the two rows.

### (1) A ROW'S `Ptr` SEAT SAYS A POINTER, NOT WHICH BOX

F2056 refuses an aggregate at a host seat — "seat 1 of `atoi` wears
`List<int>`, which cannot cross to C". A declaration NAMING A ROW
goes through F2065 instead, which compares ABI KINDS, and every
pointer-riding type fills `Ptr`. So the seat law is enforced where
the compiler knows least (a package's C) and skipped where it knows
most (its own rows). Probed at HEAD, `./avra check` silent on all
five:

    extern fn avra_str_len(b: List<Bytes>) -> int   native 40, eval defect
    extern fn avra_str_len(b: List<int>) -> int     native 40, eval defect
    extern fn avra_str_len(b: Map<string, int>)     native 32, eval defect
    extern fn avra_str_len(b: P)                    native 40, eval defect
    extern fn avra_str_len(b: E)                    native 40, eval defect

Natively a box's internal header word is read as a text LENGTH; the
evaluator says "defect: a non-string reached text in a clean
program", which is the compiler blaming itself for a program it
accepted. A BLANKET refusal is wrong — `avra_array_push`'s `Ptr`
seat takes a list and means it — so closing this wants the row to
carry what its pointer seats MEAN, which is a column on `RtSig` and
the vocabulary seam's owner's call.

### (2) A NULLABLE AT A HOST SEAT IS A NULL POINTER C DEREFERENCES — PAID 2026-09-08

PAID IN TWO HALVES, and the second is not the one this entry proposed.
The ROW half landed as written: a nullable at a core row's plain seat
is F2066 "seat 1 of `avra_host_env` wears `string?`, and a runtime
row's seat takes no absence", because the compiler knows those bodies
and `row_agrees` could not see it — a nullable fills the same `Ptr` its
present twin does. THE PACKAGE HALF WAS MEASURED BEFORE IT WAS
REFUSED, and the measurement turned it around: `free(null)` answers
under both engines today, and @std/sqlite hands `SQLITE_STATIC` — a
null — at every bind seat and a null `vfs` at `sqlite3_open_v2`, so
`avra run` over a sqlite program works. Refusing the null under the
evaluator would have refused two shipping doors and MINTED a divergence
where the engines agree. THE NULL IS NOT THE FAULT; the dereference is,
and only the callee's contract says whether it makes one. So the
evaluator's frame arms a verdict and takes SIGSEGV/SIGBUS while inside
a hosted call: `avra: a foreign body faulted inside `atoi` — seat 1 was
handed `null``, exit 2, pinned by `tools/traps.sh`'s new `trapped_run`.
That is wider than a null check — a stale `ptr` and a freed handle end
the same way — and it costs no correct program. What remains open is
NATIVE: `atoi(null)` in a built binary is still 139, because the guard
lives in the compiler's C (§5.6.1) and not in the runtime every emitted
binary carries. Whether an Avra binary should ever die with a bare
signal is the runtime owner's call.



`extern fn atoi(x: string?) -> int` then `atoi(null)` checks CLEAN
and **crashes both engines with SIGSEGV (139)** — the evaluator's
crash takes the compiler's own process down. `Bytes?` at a row seat
does the same. F2056's help says a plain host seat may be "a nullable
over those", so the allowance is deliberate and fresh; what has no
holder is the NULL that then crosses. The split is real and is why
this is a decision and not a patch: a package's C may take
`const char*` OR NULL and mean it (`getaddrinfo(NULL, …)` is the
wildcard `avra_net_listen_all` exists to name), while CORE's rows
never take NULL at a text seat and the compiler knows their bodies.
Refusing a nullable at a ROW's seat closes the crash without taking
the capability away from a package.

### (3) THE FOUR COMPARISON ROWS STILL REFUSE OCTETS NATIVE ANSWERS FOR

`avra_streq`, `avra_str_contains`, `avra_str_starts_with` and
`avra_str_ends_with` decode both seats, so octets that are not UTF-8
trap in the evaluator where the native row answers:

    extern fn avra_streq(a: Bytes, b: Bytes) -> int
    avra_streq([255, 254].bytes()!, [255, 254].bytes()!)
    eval  : octets that are not UTF-8 reached a text seat …
    native: 1

They belong to the family fixed above and the reason they were left
is MEASURED, not assumed: a length and a byte read are answered per
question (`byte_length`, `byte_at`) at no cost, while a COMPARISON
needs both sides in one currency, and the evaluator's currency for
octets is `List<int>` — two list builds, or two `Bytes` copies, on
the hottest string operation the evaluator has. The ROADMAP's
recorded trigger (a byte-lossless evaluator string, or a `Bytes`
twin for the text rows) retires these four; it no longer covers the
scalar rows, which needed no trigger at all.

### WHAT SURVIVED

`Bytes` in every seat and every crossing of every feature, the UTF-8
matrix at every text row (empty, ASCII, an interior NUL, a snowman, a
four-byte code point, a BOM — 6 fixtures x 8 rows, `eval == native`),
ownership under `AVRA_RC_GUARD=1` with zero live bytes at exit, and
@std.net's hosts, ports, gone descriptors, poller edges, hand-made
descriptors and write bounds — every one refusing in its own words,
once, on both engines.

## THE OPEN LEDGER — the red team's second round (2026-09-03)

980 programs, 77 candidates, 45 confirmed; every wrong answer,
divergence and crash it found in the LANGUAGE is closed (c6fe1ae,
4e27411). What remains is recorded here, in the round's own order.
Two items sit above the refusal tier and are SCHEDULED; the eight
below it are refusal QUALITY, which is a first-class bar here (P1:
correct on first generation) and each carries the round's own fix.

### (1) SUPPLY-CHAIN EXECUTION during `avra build` — CRITICAL (PAID 2026-09-04, lane 0)

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

### (2) `avra test` REPORTS GREEN OVER RED — a wrong answer (PAID 2026-09-04, lane 0)

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

## `mut self` — THE INOUT RECEIVER (designed 2026-09-04, lane C; amended the same day at the owner's word: `self` is a keyword, no rent anywhere)

Two ledger entries name one hole: a method writes through `self`
into the caller's box without opening it unique (RECEIVER
ALIASING), and a `mut` bound to a parameter's field path writes
through (THE ALIAS BORROW). Both exist because bs2 aliased and the
compiler's own state fns leaned on it. The V1 law stands: aliasing
is NEVER observable. This section designs the mechanism that keeps
the law AND keeps the compiler's hot methods in place, so that both
entries can be struck. THE OWNER'S STANDING ORDER for it, given
2026-09-04: this is the primary user's perfect world, not the least
change — nothing here works around rent.

THE ONE SENTENCE: **the receiver of a writing method is the
caller's cell** — `self` in such a method IS a `mut` local whose
slot the caller owns, and every proof the tree already holds for
mut locals (corpus/places, the mut-cell protocol, `avra_cell_unique`)
carries over verbatim. No new IR shape, no new law: a call passes
a place instead of a value, and the callee's writes open it exactly
as a mut local's do. A `mut` PARAMETER is the same seat at any
position — one mechanism, ratified as one.

WHAT WAS FOUND WHILE DESIGNING (both measured on this tree):
- A mut local CLONES on every read-then-write in one scope: the
  read's Load is an owned +1 that lives to the scope's end, so the
  write's `avra_cell_unique` sees a count of two. `u.age = u.age +
  1` clones the record; `let k = m.n` then `m.frames.push(k)` clones
  the FRAMES LIST per push. Measured: 20k pushes after a same-scope
  read 1.71s user, the same loop without the read 0.00s. Every
  `mut` struct local in the tree pays this today; a receiver that
  is a cell would inherit it, so the design fixes it at its root
  (LIVENESS below).
- bs2's #1377 ICE (a method call on a closure-captured local in a
  loop with an early return) is NOT in our codegen: probed
  2026-09-04 with `scan(b, want)` capturing `b` in a lambda and
  calling `b.count()` in an early-returning `while` — eval and
  native agree (`2 -1`). The style doctrine's free-fn exception was
  rent, and CLAUDE.md already says so.
- THE RED TEAM ON THE DESIGN (2026-09-04, twelve programs on both
  engines): today the engines AGREE on six WRONG answers — `let c;
  c.bump()` changes `c` (2); `mut k; let snap = k; k.bump()` changes
  the snapshot ("2 2", a flat record); `c.m(c)` reads its own write
  (5); `xs[0].m(xs)` reads it through the parent (5); a lambda
  capturing `self` sees a later write (9); a value answered by a
  reading method sees a later write (9). No divergence: the LAW is
  what is missing. Two attacks broke the design as first written
  and are answered below: two `mut` seats sharing a root (a slot
  address dangling under a sibling's push), and a by-value read of
  a receiver's PARENT in the same call (the open ran before the
  argument's retain). `mut fn` at the top level cascades today
  (the mutation statement's recovery swallows it, then "no `fn f`"
  — two messages for one mistake); `let self = 1` is accepted.
  Every line here is a spec test in S0-S2.

THE SURFACE — `self` IS A KEYWORD, and it is never spelled in a
parameter list:
```
type C = { n: int }
impl C {
    fn bump() { self.n = self.n + 1 }      // writes: inferred
    fn get() -> int { self.n }
}
trait Tick { mut fn tick() }               // the contract declares
impl Tick for C { fn tick() { self.n = 0 } }
```
`self` names the receiver of the innermost enclosing method, always
— there is nothing else it could mean, so the list never repeats it
(the way `it` is never declared). Outside a method body it REFUSES
at resolve ("`self` names a method's receiver — this is not a
method"). Inside a lambda in a method it is captured like any
binding (a copy; assigning through it there refuses as every
capture write does). The keyword derives from the grammar as every
keyword does: the impls feature contributes `primary = "self"`, a
new core node `Expr.Receiver` (no name — a string could only be a
tag), and a new `Binding.Receiver`; every exhaustive match over
`Expr` and `Binding` gains its arm, which is the compiler listing
the consumers. `place_step(Receiver)` is a Root; `is_mut_at
(Receiver)` is TRUE by construction (a write through it makes the
method writing — the fixpoint below); the three string tests
(`is_mut_at`'s `ident_name(e) == "self"`, `through_receiver`'s,
typing's `selfed`) DIE, as do `homeless_self`, `selfless_method` and
`registrable`'s self check — every fn under an `impl` is a method.
The TYPED sig keeps the receiver as seat 0 (`params[0]`, the ABI's
truth and the machine projection, P11); the surface omits it (the
human projection). `mut fn` is the DECLARED form — required in a
trait sig, optional documentation on an inherent method (written
and never writing, it WARNS). The marker is the impls grammar's
(`( "mut" )? fs:stmt` in the impl body loop, `( "mut" )? "fn"` in
the trait sig loop) and lands as a store flag beside `exported`
(`mark_mutating(s)`), so `FnDecl`'s payload does not grow and the
mutation feature's recovering `mut` statement is never in the same
ordered choice. STATIC METHODS do not exist today (a selfless fn
under an impl was refused) and are not created here; when the spec
wants them they need their own marker — recorded.

THE TRANSITION (self-hosting, no dual-form window): the grammar
change is written in the OLD spelling and built by the standing
binary; that binary's product accepts only the NEW spelling; the
tree's 733 method declarations and 13 trait sigs are then rewritten
by script in the same slice and built by the product; the merger
refreshes the seed. Order is the whole trick — no cycle accepts
both forms.

THE LAW (typing, spec 11.5: a `mut` binding permits mutation at
any depth; a method's receiver is a path under that binding):
1. A method WRITES THROUGH ITS RECEIVER when its body assigns to a
   place rooted in `self`, calls a mutating vocabulary method
   (`push`, `set`, `pop`) on one, or calls a writing method on one.
   INFERRED for inherent methods — the receiver is the type's own
   business (Swift asks for `mutating`, Rust for `&mut self`; we
   are LLM-first and the compiler holds the fact, P10).
2. A TRAIT SIG DECLARES: `mut fn tick()`. The trait is the contract
   (P9), and one dyn call site serves every impl, so the declaration
   decides the ABI for all of them. An impl method that writes
   under a plain trait sig REFUSES ("`tick` writes through `self`,
   but `Tick.tick` declares no `mut` — declare `mut fn tick()` in
   the trait"). An impl that does not use a declared `mut` is fine:
   a permission, not an obligation. Bounded (`T: Tick`) and `dyn
   Tick` receivers judge by the trait's declaration.
3. THE CALL LAW: a call to a writing method needs a PLACE receiver
   rooted in a `mut` binding — the same law as `push`, the same
   voice family (`not_a_place_call`, `not_mut_call`): `let d = c;
   d.set(5)` refuses "`d` is not `mut` — `set` mutates it"; a
   temporary (`make().set(5)`) refuses as a value. Inside ANY
   method, `self` is a place: a write there is what makes that
   method writing.
4. A `mut` PARAMETER (`fn check(mut cx: TypeCx, s: StmtId)`) is
   DECLARED, never inferred: a parameter is a boundary with the
   caller, a receiver is the type's own. The argument must be a mut
   place (the call law again, at seat N); a body that writes
   through a plain parameter refuses as today, and the help names
   `mut`. Trait sigs carry it (`fn type_of(mut cx: TypeCx, e:
   ExprId)`), so dyn dispatch passes cells. No site marker
   (`f(&cx)`): the sig says it, the `mut` binding at the site says
   it, and `c.bump()` carries none either.
5. Effective per method decl: `mut_self(m) = declared(m) ||
   declared(m's trait sig) || writes(m)`; per parameter seat:
   declared only. One bit per seat decides the ABI, the call law,
   and the projection (`avra explain`, doc, and the sig rendering
   show `mut fn` and `mut cx` whether written or inferred — P7).

THE FACT (a pass, not a guess): `writes(m)` is a WHOLE-PROGRAM
FIXPOINT over per-method summaries. A summary reads the RESOLVED
body and the DECLARATIONS alone — no body typing: every self-rooted
place has a declared type along its whole path (the impl target,
then `fields_of_type(...).slot_of(name)` per field step, the list's
element per index step — the place grammar `self (.f | [i])*` is
exactly what declarations can type), so at each site the summary
knows whether the callee is a vocabulary row that mutates (a
`writes` COLUMN on the method row — a registry fact, not a string),
a declared method (an edge to it), a trait sig (its declared flag),
or a call passing the place into a `mut` seat (declared). `own_writes
[m] || any(writes[callee])` iterates to a fixpoint over the
program's methods. Why not demand-driven through the memo kernel
with "cycle = false": UNSOUND — `a` calls `b` and `x`; `b` calls
`a`; only `x` writes. Asking `a` first settles `b` as false (its
edge to `a` is a cycle) before `x` makes `a` true, and `let v;
v.b()` then writes through a `let`. The fixpoint is deterministic,
order-free, and cheap (a bit per method per round). It lives as one
workspace query (`Family.Receivers`) over per-decl summary cells,
recorded into a dense `Decls` column (`writes_receiver`), read
through an armed hook exactly as `methods(ws, t)` is — a call site's
ask records the dependency. The store grows two projections it is
owed anyway: `assign_target(s)` (the `.Assign(t, _) -> t` match is
spelled THREE times today — resolve, check, lower — the third copy
names the concept) and `method_parts(e)`.

THE ABI — a `mut` seat carries the ADDRESS OF THE PLACE:
- A ROOT place (`c.bump()`, `f(c)` into a `mut` seat; `c` a mut
  local): the caller passes the local's own slot — the Alloca
  register — nothing opened, nothing retained.
- A NESTED place (`u.addr.rename(..)`, `xs[i].bump()`,
  `self.inner.bump()`): the caller opens the PARENT path unique
  through the existing `unique_box` chain (`avra_cell_unique`, then
  `avra_slot_unique` per step, so the write lands in the structure
  the caller sees) and passes the slot's address: `avra_slot_addr
  (parent, i) -> void**` — THE ONE RUNTIME ROW this design asks for
  (one line: `&a->data[i]`; a registry row plus the interpreter's
  host, `Val.R(arr, i)`, a first-class place there: `Load` reads
  the element, `Store` writes it, `cell_unique` clones into the
  slot). This is not rent: a `void**` IS the machine's one shape
  for "where a pointer lives", and `avra_cell_unique` already reads
  exactly that from an Alloca. THE INVARIANT that makes the address
  safe: it lives only for the call, and during the call its parent
  is unreachable — the caller's places are frozen, the callee holds
  only the slot, every other path to the parent is a by-value alias
  that would clone before writing. The parent cannot grow, so
  `data` cannot move.
- IN THE CALLEE, a `mut` seat is a mut local it does not own: the
  seat is typed `Ptr` (unmanaged: the caller retains nothing, the
  exit releases nothing — the two seat laws agree, and
  `AVRA_RC_GUARD` would name any disagreement); `cell_of(Receiver)`
  and `cell_of(a mut Param)` answer the seat's register, so
  `unique_box`'s Root arm — `avra_cell_unique(cell)` then the write
  — is the mut-local path verbatim; reads Load. A write clones into
  the caller's slot exactly when the box is shared — and the count
  sees EVERY alias: a `let d = c` before the call, an argument that
  reads the receiver (`c.m(c)`: the argument is retained at the
  call, the first write clones, `other.n` reads the old value), a
  `let s = self` inside the body, a result carrying `self` out of a
  reading method. No static exclusivity rule is needed, and none
  was complete: the refused alternative (pass the box, write
  unchecked, refuse bare `self` as a value) cannot see a reading
  method that answers `self`.
- `self.bump()` inside a writing method passes the seat through;
  `self.count()` (a reading method) loads the box and pays callee-
  cleans as any receiver does.
- A FLAT record needs NO BOX: its cell holds the word, `self.n = v`
  is the flat place's `Store` (already the mut-local path), and the
  `unflatten` in `declare_impl_block` DIES — the exclusion UNBOXED
  RECORDS recorded ("when receivers take value semantics, the
  exclusion goes and the win grows") goes now.
- Dyn dispatch: the caller opens the dyn box unique and passes
  `avra_slot_addr(box, 0)`; mono's bounded receivers reach the
  concrete method's body, which wears the cell ABI because its
  trait sig declared it. One call site, every impl, one seat kind.
- The interpreter clones on every open (the executable spec); eval
  == native over the corpus is the proof, as for every place.
- THE OPEN IS LAST: at a call, every argument is evaluated BEFORE a
  `mut` seat's place is opened — so an argument that read the
  receiver's parent (`xs[0].m(xs)`) holds its +1 when the open asks
  the count, the open clones, the seat points into the clone, and
  the argument keeps the old box. With the receiver opened first
  the count was one, the seat and the argument shared the parent,
  and the callee's write showed through (the red team's 5). Order
  is also what a nested seat NEEDS: an argument's own writing call
  (`c.m(c.add(1))`) may replace the cell's box, and a slot address
  taken earlier would be stale.
- THE EXCLUSIVITY LAW, one clause: two `mut` seats of one call never
  share a ROOT binding (`f(mut a.x, mut a.y)`, `xs[i].m(mut xs[j])`,
  `xs[0].m(mut xs)`, `self.inner.k(mut self)`). Distinct roots are
  separated by copy-on-write; the same root is two addresses into
  one structure, where a sibling's `push` reallocates the parent
  under the other seat, and equal indexes alias outright. Refused
  at typing, syntactically (`place_root`): "`xs` is passed `mut`
  twice in one call — bind `mut b = xs[j]` first and write it back".
  Swift traps this at run time; we refuse it at compile time. A
  by-value read of a `mut` seat's place or its parent in the same
  call is FINE — the count is the proof (the argument's retain
  precedes the open).

LIVENESS IN THE MEMORY PASS (the performance half, done as the
real thing — V2's first rung, not a lowering trick): a managed
Load retains ONLY when its register is live past a point where its
cell's box may change, or escapes. A USE is transitive through
non-owning reads: a child taken by `avra_array_get`, a word by
`Extract`, anything a non-owning row answers over the register —
the child is a borrow of the box, so its uses are the box's (the
red team's `use(u.tags, u.add(1))`: the child rides to the second
call while the first writes the box). Concretely the retain stays
when any such use (a) is at or after a CHANGE POINT of the cell —
a `Store` to it, `avra_cell_unique` on it, `avra_cell_release` of
it, or a `Call`/`CallPtr` receiving the cell or a seat OPENED from
it (a writing callee opens it there);
(b) lies inside a loop opened after the Load (a back-edge re-runs
the use after the body's writes); or (c) is an escape — the
register is given upward (`ArmEnd`, `RegionEnd`, `ScopeExit`,
`RetVal`, `FnExit`), stored, packed, or handed to an owned twin.
A Load passed as an ordinary call argument needs no retain of its
own: callee-cleans retains the seat and the callee releases it, and
the box stays alive through the cell for the call's length. Every
other Load is a BORROW of the cell's reference: `u.age = u.age + 1`
and `let k = m.n; m.frames.push(k)` write in place, for `self` and
for every mut local in the tree alike. One backward scan per body
over the flat list with a use index; conservative by construction
(an `if` arm's write before a later arm's use keeps the retain
though the arms exclude each other — correct, cheap, and V2's
later rungs refine it). The interpreter runs the same stream, so
eval == native still referees; the guard and a leak count on the
corpus witness the counts. DONE WHEN the 20k-push probe above runs
in the base loop's time natively with the guard clean, and the
compiler checking itself is measured before and after.

WHAT DIES: `self` in 746 parameter lists; `borrows_field`,
`mark_borrow`, `is_borrow` and the `borrows` column; `borrows()` and
the Load arm in `unique_box`, and its "self is the box itself" arm;
the three string tests and the three selfless voices; the unflatten
of impl targets; a `mut` bound to a PARAMETER'S FIELD PATH becomes a
COPY like a local's — legal, and silent: the compiler cannot know a
copy was meant as a borrow, so the tree's borrow-in-disguise sites
are found by S1's census and the suite, not by a refusal (a lint
for "a mutated copy of a field that is never read back" is
recorded, not built). That is the ledger's entry struck at its
root — and DOGFOODING's "A write reaches a PLACE, never a value",
which teaches the field-path borrow as the idiom, rewrites in S2 to
say what is then true: a fn changes its caller's data through a
`mut` seat, and a handed value is a copy.

THE CORPUS PAIR (`corpus/mut_self.av`, the DONE WHEN made a
program): a root receiver (`mut c = C { n: 1 }; let d = c;
c.bump(); c.bump()` — `c.n` 3, `d.n` 1); a flat receiver
(`type K = { n: int }` with `bump`, no box); a nested receiver
(`u.addr.rename("x")` with a snapshot kept); a slot receiver
(`xs[1].bump()` with a `let ys = xs` kept); a writing method that
also ANSWERS (`Arena<N>.add` returning the index, two instantiations
— `corpus/generic_impls` rewrites to `mut ints` and
`self.nodes.push(n)`, its `let` receivers were the aliasing the law
forbids); a method aliasing itself (`c.m(c)`); a chain of writing
methods on self; a `mut` parameter root and nested; a trait's `mut
fn` through `dyn`. Spec tests pin every refusal in its own words
(`let d = c; d.set(5)`; a temporary; an impl writing under a plain
trait sig; a plain parameter written through; `self` outside a
method; a parameter's field path bound `mut`) and the warning.
Rendering goldens for each new diagnostic kind.

THE SLICES, in order, each red-teamed then reviewed, each a gate
(the red team's twelve programs are the first adversarial file,
`impls_adversarial_test.av`, written before S0's code):
- S0 THE KEYWORD — LANDED 2026-09-04 (what it taught, below the
  slice list): `self` a keyword, `Expr.Receiver`,
  `Binding.Receiver`, the lists emptied by script, `mut fn` parsed
  and flagged. FOUR VOICES, each exactly one message: `self`
  outside a method ("`self` names a method's receiver — this is not
  a method"); `self` in a parameter list ("`self` is implicit in a
  method — drop it from the list", the transition's own help);
  `mut fn` outside an `impl` or `trait` (today the mutation
  statement's recovery swallows it and a second message follows);
  `let self`/`mut self`/a field or fn named `self` (the keyword
  law's own words). The transition above reaches the 51 sources
  embedded as strings in the test files and the 9 doc examples,
  not only the 746 declarations. Landed alone it changes no
  semantics — the receiver still aliases — and every string test
  dies.
- S1 THE FACT AND THE LAW: the summary, the fixpoint, the column,
  the call law at seat 0 and seat N, the trait agreement, `mut`
  parameters parsed, explain. Landed alone it CHANGES NO CODEGEN;
  its first use is a CENSUS — `./avra check packages/std-avrac`
  names every call site the law refuses in the compiler's own
  source, which is the honest size of S4.
- S2 THE ABI: the cell seat for receivers and parameters, the
  runtime row and its host, flat receivers unboxed, the corpus
  pair; the borrow deleted. DONE WHEN `mut d = c; d.set(5)` leaves
  `c` unchanged natively and in eval, `let d = c; d.set(5)`
  refuses, and the gate is green.
- S3 LIVENESS, measured on the probe and on the compiler checking
  itself (before/after user CPU recorded here).
- S4 THE CONVERSION: the contexts refactor and the state fns —
  BEFORE S2 (amended at S1's landing: the ABI has no legacy path).
  DONE WHEN the receiver law's 981 warnings are zero and it turns
  into the refusal.

S0 LANDED (2026-09-04), what it taught: (1) THE TRANSITION ORDER
HELD — the grammar written in the old spelling, built by the
standing binary (saved aside first: the product refuses the old
form, and a broken product leaves no compiler), the tree rewritten
by script (91 files, 809 sites), built by the product, gated
(1618 cases, 72 corpus programs); no cycle accepted both forms.
(2) THE BORROW MUST HONOR THE RECEIVER UNTIL S2 DELETES IT: with
`self` a `Receiver` binding, `borrows_field`'s `is .Param` test
turned every `mut xs = self.field` in the compiler's own methods
into a COPY, and the compiler compiled itself into a binary whose
declaration tables stayed empty ("index 0 is out of bounds" in
`Decls.admit`, found with lldb on `avra_trap`). The lesson is the
design's own: aliasing is a property of the BINDING, and a change
to the binding vocabulary must visit every law that asks it. (3)
A REWRITE SCRIPT MUST NOT CROSS A SYMLINK: `packages/std-cli/src/
cli.av` was a symlink into the old tree, and the script rewrote
bs2's file; it is a real file now, and the discipline is in
CLAUDE.md. (4) A BARE KEYWORD PARAMETER DECLARES NO SEAT
(`written_seats`): `fn get(self)` refuses once with the receiver's
remedy instead of cascading into an arity error. (5) THE REMEDIES
TABLE: a feature that claims a keyword may write what to write
instead (`KeywordRemedy` on the manifest; `refuse_keyword` reads
it) — the first registry the naming law consults. (6) The red
team's fourteen further attacks found two gaps, closed: a generic
`mut fn` cascaded through the mutation statement's recovery, and
an `impl` inside a fn body was silently accepted (F3025 now).
Recorded from it: `fn bump(mut self)` — the OLD design's spelling
— parses as a hole today; S1's `mut` parameters give it the
receiver's remedy.

S1 LANDED (2026-09-04), what it taught: (1) THE ORDER OF THE
SLICES WAS WRONG BY ONE: the cell ABI cannot coexist with a
legacy box-passing path — a writing callee compiles ONE way, so
every call site must hand a place before the ABI lands. S4 (the
conversion) therefore precedes S2, and the receiver law lands as
a WARNING: 981 sites in the compiler's own source today (the
census the design promised), zero refusals, the gate green. (2)
`mut` SEATS IN THE TRANSITION WRITE THROUGH: a `mut` parameter is
lowered exactly as a receiver is today — the box, in place — so
`grow(v)` grows the caller's `v` on both engines; the ABI makes
the seat a cell without changing a program's answer. A seat
assigned WHOLE has no cell yet and refuses with the trigger named.
(3) THE DECLARED AND THE INFERRED STAY APART: `declares_writing`
(the word, `mut fn`) and `written` (the pass) are two columns, and
`writes_receiver` is their disjunction — folding the word into the
summary silenced the never-writes warning. (4) A COLUMN READ MUST
GO THROUGH THE SIG HOOK: `mut_seat(d, i)` read the table directly
and answered `[]` for a callee declared after its caller; the pass
found a fn's seat only when the fn came first. Every declaration-
table read that a body may ask before the declaration's sig ran
goes through `ensure`. (5) A CAPTURED ROOT IS A COPY, and the seat
and receiver laws say so in their own words instead of "not
`mut`". (6) The red team's thirty-seven programs: the fixpoint's
counterexample cycle answers right, mutual recursion without a
write is silent, a generic seat instantiates twice, a trait's
`mut` seat dispatches through `dyn`.

S4 DESIGNED (2026-09-04, from the census): THE STATE THE COMPILER
MUTATES IS TWO KINDS, and the inout seat pays for exactly one.
(A) OWNED PASS STATE — a pass's own tables and the drivers' frames
(`TypeFacts`, `NameFacts`, the `Emitter`, the `Typer`'s and
`Resolver`'s stacks, the `Machine`, a `Builder`'s captures): ONE
owner, the driver; rules borrow it for a call. That is an inout
seat: every rule takes `mut cx`, the contexts hold the driver's
state as FIELDS instead of closure fields capturing it, and each
closure field (`walk_type`, `block_type`, `lower_block`, …) becomes
a METHOD that recurses with `self` — 23 of the 981 warnings are
captured roots today, and those are exactly the closure fields.
Fourteen types carry (A): the six contexts, `Typer`, `Resolver`,
`Lower`, `Machine`, `Emit`, `Builder`, `MatchContext`, `Survey`.
(B) SHARED PROGRAM STATE — the type registry (an INTERNER: two
holders interning one shape must get one id), the declaration
table, the node store, the query kernel, the workspace's tables.
These are reached from MANY places at once (`cx.view.types`,
`decls.types`, `ws.decls.types` name one box) and written from
many; a mut seat cannot hold them, because a seat is one place
with one root and the exclusivity law refuses two roots to one
box — and under the cell ABI a write through one path would clone
the registry away from every other. 95 of the 981 warnings are
`intern` alone. Spec 11.3 names this case by name — caches, lazy
initialization, pooled resources — and gives it INTERIOR
MUTABILITY BY TYPE: `Cell<T>`, the documented exception to deep
immutability, visible in every signature that carries it. So (B)
becomes `Cell<TypeRegistry>`, `Cell<Decls>`, `Cell<NodeStore>`,
`Cell<Db>`: a shared box whose writes are visible through every
alias BY DECLARATION, with methods forwarding in place (the spec's
`get`/`set` surface plus in-place calls — the design owed to the
owner: a `Cell<T>` is a core type with a runtime box, and its
cycle law is the doctrine's own exception). THE SLICES: S4a the
(A) seats by script (`mut` before every (A)-typed parameter and
trait seat; the seat law then names every site that must change
shape), S4b the closure fields into methods, S4c the 79 `mut x =
y.field` borrows into path writes; S2 (the cell ABI) is BLOCKED
on (B)'s ratification — until `Cell` lands, a (B) seat marked
`mut` writes through as today and the receiver law stays a warning
at (B)'s roots (`ws`, `types`, `decls`, `db`: 145 sites). S4b DONE
2026-09-05: every closure field is a method (captured seats 0), and
the seat law's captured case REFUSES — the first site it caught was
the memo kernel's toy test, a tally shared with a family's closure
through list aliasing, which is (B)'s shape in a test (its seats
read until `Cell`). The receiver law's warning stays until `Cell`.

THE CONVERSION'S TRUE SIZE — measured 2026-09-04 so S4 is not
underestimated: methods are HALF of the borrow's users. The census
(79 `mut x = y.field` sites) splits into fns that borrow a
parameter's field (interp `m.`, resolve `r.`, llvm `em.`,
workspace `ws.`, typing `t.`) — those become methods on a `mut`
local the driver owns — and PASS CONTEXTS HANDED TO FEATURE RULES:
`cx.emit(d)` reaches `self.facts.speak(d)` — a writing method on a
nested place — from `check_assign(cx: StmtTypeCx, …)`. 355 mutating
calls go through a context parameter, 929 fns take a context or
state struct first, 20 files hold impls that write through `self`.
The whole capability-record pattern (closure fields capturing the
driver's state) worked only because bs2 aliased; under value
semantics a closure captures a COPY. S4 therefore: every rule fn
takes `mut cx`; the contexts' closure fields (`walk_type`,
`block_type`, …) become METHODS on the context, recursing with the
same cell; the drivers' state moves INTO the context; NodeSemantics
and StmtSemantics sigs take `mut cx`, so dyn dispatch passes cells;
and no mut-ref capture is needed for any pass. The contexts' shape
is doctrine (contract.av), so S4 opens with its own short design
section naming the new shape before the rewrite.

RECORDED, NOT THIS ARC: (1) MUT-REF CAPTURES — spec 11.4's
`counter += 1` inside a closure is by-reference capture, which the
V1 law refuses as written; the honest shapes are a cell capture
that may not escape its cell's scope (non-escaping closures, as
Swift's default: the same seat a third time) or an interior-
mutability wrapper (11.3, `Cell<T>`); decide when a program wants
it, with the spec. (2) A TEMPORARY RECEIVER (`make().bump().get()`)
is safe by construction (nothing shares a fresh box) and refused
like `push` on a value; relax when a wanting site appears. (3)
STATIC METHODS and a `Self` type. (4) V2's later rungs (moves at
last use, reuse in place).

REFUSED ALTERNATIVES, so they are not re-argued: (a) pass the box,
write unchecked, close aliasing statically — incomplete (results
carrying `self`) and it needs a trap for the rest; (b) copy-in
copy-out through an owning temp cell — clones every nested
receiver on its first write (`self.facts.speak` would clone the
fact tables per diagnostic); (c) a new call variant marking the
seat — the `Ptr` seat type already says it, and the memory pass's
seat laws already read types; (d) inference by demand with cycles
answered false — the counterexample above; (e) inferring `mut`
parameters — invisible magic at a boundary (P7 over P3 there); (f)
a borrowed Load minted by lowering for adjacent projections — it
would have been right for exactly those sites and a workaround for
the memory pass's missing liveness, so the pass gets the liveness;
(g) `self` kept as a name — three string tests and a word any
local could shadow.

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

---

## Feedback survey — 2026-09-13 #7 (comptime/const, the private const and survey #6's leftovers)

The `/feedback` run for the lane that made a top-level `const` a
module declaration (c0e5cb8), made a `const` seat take what the source
spells (d92cda0) and landed `avra check --every` (300de49). Counts:
FRICTION 5, SUGAR 2 (both confirmations), FEATURES 1 (confirmation),
DEFECTS 4 (all fixed in-lane), DOCTRINE 4, PERFORMANCE 0 (one
unmeasured note), PROCESS 3. Top three by cost: the cross-family
cycle (one build cycle and a design), the F0900 on assigning a const
(a defect users would have read), and the two one-run stalls (a
keeper's false positive, a test string's own interpolation). NOT
SURVEYED: the std packages beyond the 58-export sweep, the docs
campaign's files, and the templates lane's regions of workspace.av.

### FRICTION — what cost time

- **A CYCLE ACROSS TWO QUERY FAMILIES IS SEEN BY WHICHEVER IS ENTERED
  FIRST.** `const X = X`: asked from Main, the const-type family
  cycled and spoke; asked by the report typing the const's own
  declaration first, the TYPED family re-entered itself through
  `start_recursive`, answered a smaller view in silence, and the
  const-type ask never cycled — the first fix worked in one ordering
  and not the other. One build cycle. THE ASK, PAID: `Memo.open(arg)`
  — a family asks whether the OTHER family's query is in flight before
  touching it (workspace.av `const_type_at`). Attributed:
  comptime/const c0e5cb8.
- **THE I18 MATCHER FLAGS ANY `_of(` FOLLOWED BY `??`.**
  `settled_type(self.store_of(f), …) ?? known_const_type(…)` was
  named "a payload the dispatch GUARANTEES, papered over with a
  default" — `store_of` is a table read, not the value protocol. One
  gate run; the site was reshaped into two statements. THE ASK: the
  matcher names the protocol's verbs (`int_of`, `text_of`, `bool_of`,
  `bits_of`, `pairs_of`, `elems_of`, `quote_of`), not the suffix —
  its true-positive rate is its spec (CLAUDE.md, "A LINT COUNTS WHAT
  ITS DOCTRINE COUNTS"). tools/idioms.py:445.
- **A `${}` INSIDE A TEST'S SOURCE STRING IS THE TEST FILE'S OWN
  HOLE.** `shown("…\"${f()} ${N}\"")` interpolated `f()` in the
  test module — F3000 "no `fn f` is defined" AT THE TEST'S LINE, which
  read as the feature being broken. One suite run. The spelling is
  `\${…}` (the const adversarial suite already does it once). No ask:
  a fact worth one line where tests are written.
- **A CHECK-TIME HELPER ASSERTS NOTHING ABOUT A LOWERING-TIME
  REFUSAL.** Two cycle cases were written with `refused_with` (analysis
  only) for a settlement trap that speaks at lowering; both failed
  until rewritten as `refused_at_run`. Minor; the names say it.
- **A GREP FILTER MANUFACTURED A DIVERGENCE.** A red-team harness
  filtered eval output with a character class that excluded spaces, so
  `4 6` vanished and read as eval=[] against native=[4 6] — the most
  serious finding available, for one probe, false. Compare RAW outputs
  and filter after; the differential harness in `tools/` should own
  this rather than each lane's shell.

### SUGAR — a construct the language should have

- **A TEMPLATE CANNOT NAME WHAT IT GENERATES** — filed above under
  survey #5's section this lane extended; routed to COMPTIME
  TEMPLATES by the task master. Confirmation only.
- **`it` BINDS TO THE NEAREST CALL** — `all_defs.any(it.name == name
  && store.const_value(it.stmt) == null)` refused F2033 inside the
  nested call; the lambda was written out. Already in CLAUDE.md's
  subset ("`it` through a self-method wrapper"). Confirmation only.

### FEATURES — a capability, more than sugar

- **`avra check --every`** — survey #6's ask, LANDED 300de49.
  Confirmation only.

### DEFECTS — the compiler blaming itself, or silent

- **`const X = X` COMPILED CLEAN AND ANSWERED NOTHING** (found on
  c0e5cb8's first build, latent before it only because a plain const's
  own name did not resolve inside its value). The type cycle was
  swallowed as an Error type; `check_const` treated Error as "already
  spoken". FIXED: F2078 at the const, both orderings.
- **ASSIGNING A CONST WAS F0900** "defect: an assignment to a
  non-place survived a clean analysis" — the assignment law's `Decl`
  arm answered nothing for a const. Found by the red team (class 2).
  FIXED: F3005 in the const's words.
- **A GENERATED TOP-LEVEL `const` WAS NEVER ADMITTED** (pre-existing:
  `mint_code_stmt` minted fns, types and impls). FIXED:
  `mint_code_const`; consts/tests/generated_const.
- **`take(K.B(5))` REFUSED AS "COMPUTED AT RUN TIME"** — a qualified
  payload variant is a method-call node on the enum's name. FIXED in
  d92cda0's source walk.

### DOCTRINE — a law missing, misleading, or stale

- **CLAUDE.md's "`const` in a MODULE file … F0902" WAS STALE TWICE
  OVER** — F0902 had been relaxed for consts, then the migration made
  a const a declaration. REWRITTEN as the top-level-const law.
- **THE DESIGN DOC'S "ONLY WHEN EXPORTED" SCOPING** (S1 `export
  const`) is SUPERSEDED; marked at the entry.
- **A CROSS-FAMILY CYCLE NEEDS THE OPEN CHECK** (the friction row
  above, as a law): a query that touches another family's query must
  ask `open` first when the two can re-enter each other, because
  `start_recursive` on the other side answers a smaller view rather
  than a cycle. Worth a keeper the day a third family joins the
  const/typed pair.
- **THE SEAT LAW READS THE SOURCE, NOT THE FACTS** — survey #6's
  proposed ORDER change was a fix to a symptom; a law about what the
  source spells must not consult typing facts at all. Pinned in the
  design doc's queue.

### PERFORMANCE — a measured cost

- None measured. UNMEASURED NOTE: a `const`-seat argument that is not
  a bare literal now costs one isolated lowering plus an evaluator run
  per distinct argument expression per unit (memoized under
  `expr$<file>$<expr>` plus the seats). `make census` over a program
  dense in such calls would size it; none exists in the tree today.

### PROCESS — the working discipline itself

- **THE WATCHDOG LOCK SERIALIZED TWO LANES' BUILDS** without anyone
  coordinating ("waiting for the build lock (held by pid …)" four
  times this lane). Keep.
- **A FAILING TEST MUST FAIL FOR THE RIGHT REASON** before the fix: the
  `check_every` spec first failed on a fixture typo (`unreached` vs
  `unused`) — a test that fails for a typo proves nothing about the
  law. Read the failure's words, not its colour.
- **"ONE COMMIT EACH" BENT WHERE ONE MECHANISM PAID TWO ASKS**: the
  nested-const and inline-variant leftovers were one law (the source
  walk) and landed as one commit, reported as such rather than split
  into a commit whose second half changes nothing.

## Feedback survey — 2026-09-13 #8 (comptime/templates, parsed templates slice a)

Counted per axis: friction 4, sugar 4, features 2, defects 3 (mine,
found by the red team, fixed), doctrine 2, performance 0, process 3.
The top three by cost: the two-binary ladder (each boundary crossed
by hand-writing the compiler's own derived accessors), the `it`
pronoun binding to the nearest call, and the arm-vs-statement
ordered choice with no lookahead. Not surveyed: the sqlite and http
lanes' trees; this tree at the merge points only.

### FRICTION — what cost time

- **THE LADDER HAS NO TOOL.** Crossing a syntax boundary in the
  compiler's own source (twice today: mine, then CONST's order-free
  consts against my lexer) is: strip the two `@derive`s to
  hand-written accessors, build, restore, build twice, `make seed`.
  Four edits and five builds, by hand, each time. EVIDENCE: this
  lane's session, `protocol.av`/`projections.av`/`nodes.av`/
  `contract.av` edited twice. THE ASK: `make ladder` — a target that
  builds with the derives stubbed from a checked-in stub file, then
  restores and builds to the fixed point.
- **`it` BINDS TO THE NEAREST CALL.** `xs.all(store.hole_stmt(it) !=
  null)` is F2033 at the inner call; seven sites wrote the lambda
  instead. EVIDENCE: `core/rebuild.av:59`, `quote/check.av:38`,
  `quote/lower.av:31`. Already in "The subset today"; CONFIRMS.
- **NO STATEMENT SEPARATOR.** `if x { a(); return s }` is F0001
  "unexpected character" at the `;`, three lines each. EVIDENCE:
  `grammar/lexer.av`'s `routed`. THE ASK: none — the line law is the
  design; a subset-today row so the next writer knows.
- **A SPEC ASSERTION'S LINE ANCHOR IS FRAGILE.** The quote spec pins
  `prov.av:7`; adding a doc line to the vendored provider moved every
  anchor. EVIDENCE: `quote_test.av`'s `provider()`. THE ASK: assert
  the LINE by a marker search of the vendored text, not a number.

### SUGAR — a construct the language should have

- **A HOLE IN A STRING'S LITERAL RUN.** `"${f.name}: …"` as generated
  text has no spelling; `interpolated(parts, holes)` builds it.
  Wanting site: `std-derive/src/derive.av`'s `Show` (`shown_parts`).
- **A PARAMETER-LIST HOLE.** `fn f(${params})` is not a seat; a
  derive that forwards a fn's seats has no spelling. Wanting site:
  none yet in tree — the `@traced` twin would want it.
- **A FLOAT IN A HOLE.** No `float_node` row: a `float` in an
  expression seat is refused. Wanting site: `quote/lower.av`'s
  `fill_reg` (`rest ->`).
- **PEG LOOKAHEAD IN THE GRAMMAR DSL.** `( a:arm | s:stmt | BREAK )*`
  tries the arm first, so every statement-shaped line of a quote body
  leaks one pattern node from the failed attempt. `&`/`!` would let
  the arm branch require its `->` before committing a node. Wanting
  site: `features/quote/mod.av`'s grammar.

### FEATURES — a capability, larger than sugar

- **`Type` CARRIES `Kind`.** A type hole filled from a SPELLING parses
  the text with the `type` rule (`program.av`'s `parse_type_ref`) —
  the one text the splice still reads, because `Variant.payload` and
  `Field.ty` are strings. Retires with §3.6's `Kind`.
- **A REBUILDER-SHAPED DERIVE.** `core/rebuild.av` is 420 lines of
  exhaustive arms that a `@derive(Walk)` could write from the enums —
  the inventory's class D/E, now with a real consumer.

### DEFECTS — the compiler blaming itself (all fixed in the slice)

- **A HOLE-ONLY QUOTE TYPED BY ITS FIRST HOLE'S NAME.** `quote {
  ${parts} }` with `parts: List<Decls>` answered `Code`; a scalar in
  it lowered as a NAME. Found by the red team's `twice`; fixed by
  `seat_of`/`kind_word` in `quote/check.av`.
- **TWO IMPLS OF ONE TARGET IN ONE GENERATION MINTED ONE.** The
  generated key was the whole generation's tag plus the target, so
  the second `impl P` took the first's slot. Found by `two_impls`;
  fixed by keying per statement (`mint_generated_code`).
- **A TEMPLATE'S OWN DECLARATION WAS INVISIBLE TO ITS OWN READS**
  (CONST's finding, left for this lane): `fn plain_base` generated
  from a template, `plain_base()` in the same template was F3000.
  Fixed: `generated_named` answers a template-origin read with the
  generated declarations its template wrote (`resolve.av`). Pinned:
  `quote/tests/self_read`.

### DOCTRINE — a law missing, misleading, or stale

- **"A HOLE HAS NO POSITION UNTIL THE SPLICE PARSES" WAS A PROPERTY
  OF THE TEXT MODEL, WRITTEN AS A LAW.** §7 q2 decided `Code`
  untyped on it; the tree model retired it the same day. Amended in
  the design doc with the by-kind answer.
- **"THE NEXT BUILD IS `make bootstrap`" ASSUMES THE SEED KNOWS YOUR
  SYNTAX.** After a lexer change, the committed seed predates it and
  bootstrap builds a compiler that cannot read the compiler's own
  templates; the way through was `make seed` from the fixed point
  FIRST, then bootstrap as the receipt. Recorded in the design doc's
  ladder.

### SUBLANGUAGES (2026-09-14, the same lane's second campaign) — appended rows

- **DEFECT, FIXED: AN EXPANSION AFTER ADMISSION CANNOT BE TYPED.** The
  first draft expanded a block inside `resolved`; the typer's
  per-declaration table, sized from the declaration's range at
  admission, could not reach the nodes ("index 22 is out of bounds
  (length 20)", `TypeCx.type_node` via `checked_fn`). Moved to the
  PARSE, where `table<R>` expands. The general law: a node minted
  after admission belongs to no declaration's range — mint at the
  parse, or mint a declaration.
- **DOCTRINE: A FEATURE'S GRAMMAR FRAGMENT IS ITS KEYWORD CLAIM, AND
  THE CLAIM LANDS ON THE COMPILER'S OWN NAMES.** `stmt = "syntax" …`
  made `syntax` a keyword and refused `Language.syntax` in the
  product's second build — the build that succeeded was the build
  that lied, again. Check `grep -rn "\b<word>\b" packages` before
  claiming a word; the declaration is `grammar <word> { … }` for that
  reason.
- **DEFECT, FILED: THE GRAMMAR DSL SWALLOWS AN UNCLOSED GROUP AND AN
  UNCLOSED ACTION.** `where = ( c:NAME` and `-> eq(c, v` both parse
  with no word and ready with no defect (`sublang_test.av` probes;
  `where: c:NAME` is what refuses). EVIDENCE: `./avra check` of a
  library declaring them, 2026-09-14. THE ASK: `parse_grammar` refuses
  an unclosed `(` and an action missing its `)`.
- **FRICTION: `table` IS A KEYWORD.** A `Select { table: string }`
  field refused F3002 three lines down; `relation` instead. Already
  in "The subset today" as a reserved word; CONFIRMS.
- **FRICTION: A PRESENT-BIND ARM AFTER A COMMA-ENDED ARM**, twice in
  one afternoon (`null -> "", h? -> …`, `null -> [], b? -> …`) — each
  read as "expected `}` to close the match" and cost a build.
  CONFIRMS the subset row; the ask stands.
- **SUGAR: A LEXER MODE PER SUBLANGUAGE.** A body's lexing is Avra's;
  `'x'` in an SQL block refuses as two unexpected characters at the
  block (pinned). Wanting site: `sublang_adversarial_test.av`'s
  lexing-limit case. THE ASK: a `tokens { }` layer beside a named
  grammar.
- **DEFECT, FIXED: A PARSE THAT READS ANOTHER FILE'S ITEMS IS A
  CYCLE THE DAY THAT FILE IMPORTS BACK.** The block pre-scan read the
  provider's `surface` (items → parsed → its own pre-scan → the
  consumer's parse, in flight): "memo family 2 reused missing key 0"
  at the workspace's mutual-recursion case, which no sublanguage test
  reached because every one had a one-way import. A parse may read
  another file's SOURCE, never its items: `Family.Plain` is the
  word-less parse, and the pre-scan reads exported `grammar`
  statements from it. THE LAW: a memo family's dependencies point
  strictly down the pipeline, and the PARSE is the floor — anything
  it reads of another file must be that file's source or its plain
  parse. Pinned: two modules importing each other, one's block of the
  other's grammar.
- **DEFECT, FIXED: A FILE ENTERS THE TABLE AT FIRST MENTION, AND
  `cases()` WALKS THE TABLE.** The plain read minted the provider's
  FileId with no store; the test command's `cases()` walked every
  file and unwrapped the store ("unwrapped an absent value", found
  only by `avra test` on the sql program ALONE — the package sweep's
  green did not reach it, because there every provider had already
  been resolved). `file_cases` mints the file's items first. THE
  GENERAL SHAPE: a table that fills "as files are first asked for"
  carries an unstated invariant about WHAT an ask does; the second
  kind of ask broke it silently.

### PROCESS — the working discipline itself

- **KEEP:** the red team's on-disk attack packages — 19 programs in
  the scratchpad, 10 promoted to `quote/tests/*` as eval == native
  program tests; the two real defects came from `twice` and
  `selfread_plain`, neither of which the spec suite had a shape for.
- **KEEP:** the expand byte-identity receipt — `avra expand` over the
  derive test and the compiler's own two derives, diffed against
  lane/comptime's binary; it caught the right-fold `&&` (semantically
  equal, textually not) before it shipped.
- **CHANGE:** a guard that says "no expected text may change" should
  name the CONTRACT it protects; two spec assertions changed because
  the mechanism moved (a refusal's seat words, a parse error now at
  the library) and were reported, not hidden.

## Feedback survey — 2026-09-14 (STD-SUBSTRATE: main 12738f7 into lane/http, 23fc98c..d3406ce)

Surveyed: the merge, the http fixes, the red team and the review round
in ../avra-lane-http. NOT surveyed: lane/http's own 325 commits (their
lanes filed theirs), the toolchain PRs landing beside this work.

### FRICTION — what cost time

- TWO FRONT ENDS LEAVE NO COMPILER THAT COMPILES THE MERGE. Main's seed
  names runtime symbols lane moved into package C (`recover` failed on
  eleven `avra_io_*`/`avra_proc_*`), and main's compiler refuses lane's
  `Bytes` in the merged source; lane's compiler refuses main's syntax.
  Half the session went to the ladder: gen-0 = the seed over MAIN's
  runtime; gen-1 = gen-0 over a throwaway spelling (Bytes as string in
  four files) with main's std-io/std-process and an io/proc shim
  (`ld -r -exported_symbols_list` over main's runtime); then `make avra`
  to a byte-identical fixed point. The shim's first cut split the io
  family, and `list_dir`'s text landed in the other runtime's stash — a
  compiler that could READ files but list none, refusing "src/main.av
  does not exist" on a file it had just read. THE ASK: a seed that
  carries the runtime it links (seed.ll beside the runtime C it was
  emitted against), so `make bootstrap` links on every tree; until then
  the ladder is on avra-wbra.
- THE MACHINE LOCK IS A QUEUE NOBODY CAN SEE. Four sessions gating at
  once: every heavy step waited 10–40 minutes, and the harness killed my
  waiting shells six times under memory pressure (swap 15.9 of 17.4 GB,
  `sysctl vm.swapusage`). What survived was a run launched in its own
  session (`python3 -c "os.setsid(); os.execvp(...)"`). THE ASK:
  `tools/watch.sh` prints the queue depth and who holds the lock;
  the bootstrap README names the detached form.
- A LOOSE FILE'S NATIVE BUILD TAKES THE LOCK. `./avra build one.av`
  queues behind package gates, so "does eval == native on this probe"
  cannot be asked quickly; the honest form was a scratch PACKAGE with
  `src/tests/<name>/<name>.av` run once. THE ASK: a lock-free
  single-file differential, or the lock only for directory arguments.
- A FILE-ENTRY CHECK INSIDE A PACKAGE WITH PROGRAM TESTS IS A WALL: 628
  F0902 lines (main's own tree: 588 on `lists/check.av`) because every
  program test's top level is read as a module's statements. THE ASK: a
  file-entry check leaves program tests (an `.expected` beside) out of
  the module set.

### SUGAR — a construct the language should have

- A REVERSE CLASS-TABLE SCAN. `run` scans forward only, so trailing OWS
  is a `while` with a counter (std-http frame.av `before_ows`) where the
  leading side is one `buf.run(at, ows())`. Wanting site: frame.av:367.
  THE ASK: `b.run_back(hi, table) -> int`, one C row.
- A HOLE-LESS LITERAL OVER OCTETS COMPARES OCTETS. `match r { "k-1" -> }`
  over a `Bytes` (or a name over one) is F2038 "a `string` never matches
  `Raw`" while `"k-{n}"` with a hole cuts octets. Probed at ad9186e
  (build/scratch/rt/nb_lit.av). THE ASK: formats builds the equality
  pattern as an octet compare when the subject is octets.

### FEATURES — a capability, larger than sugar

- A DIAGNOSTIC-CODE KEEPER IN THE GATE. Two lanes claimed F2060/61/63/65/66
  and the collision surfaced only when the merged compiler ASSEMBLED its
  language at run time ("registered more than once") — after a whole
  generation was built. The fingerprint and idiom keepers caught their
  twins statically (tags 111/112, I39); codes have no keeper. THE ASK:
  a keeper over every `diags` table, in `make gate`.

### DEFECTS — the compiler blaming itself

- `avra test <dir>` WITHOUT A MANIFEST EXITS 2 AND SAYS NOTHING. Main's
  binary too (`../avra/build/avra test build/scratch/rt/programs`: exit
  2, no output). A refusal must speak; a directory of programs at the
  top level is not a shape today (only a nested root under a package's
  `src/` is), and the refusal should name the shape it wants.
- A BUILTIN'S STATIC VOCABULARY ADMITTED EVERY TYPE NAME. `builtin_static`
  (main, for `Cell.new`) consulted the method rows for any `TypeName`
  receiver before the declaration-based door admission, so a plain
  record's `Port.parse(...)` typed as a grammar door and lowering said
  "a grammar door without its declaration survived typing". Latent on
  main alone (no other rows took a type name); fixed in 23fc98c — the
  language's declarations alone.

### DOCTRINE — a law missing, misleading, or stale

- "A LANE'S FIRST BUILD IS `make bootstrap`" ASSUMES THE SEED LINKS. It
  does not when the merge moved runtime symbols into packages; the law
  needs the second half: when `recover` fails on symbols the tree no
  longer defines, the bridge is a seed over the OTHER side's runtime and
  a throwaway spelling for the constructs that compiler cannot read,
  never a rewrite. Attributed here, 2026-09-14.
- "THE MAKEFILE FROM MAIN" was the merge brief; the honest resolution
  was main's TARGETS (recover, seed-check, the named suites) over lane's
  OBJECT MACHINERY (one rule, COMPILER_OBJS/PACKAGE_OBJS, the stem law),
  because the brief's own subject — package C — IS the Makefile change.

### PERFORMANCE — a measured cost

- The merged gate peaks at 828 MB (`watch: peak`), gen-1's build at 764,
  the seed refresh + bootstrap at 740; the machine's swap sat at 14–16 GB
  of 15–17 GB throughout from concurrent sessions. No regression
  measured against main's gate; nothing else was measured.

### PROCESS — the working discipline itself

- KEEP: one lock, every heavy run under the watchdog; the deterministic
  red-team battery as a scratch PACKAGE's tests dir (16 programs, one
  lock turn, both engines); a probe result names its base — the stale
  standing binary answered F2084 for a case the fixed library passed.
- CHANGE: a waiter that sleeps is still a process the harness kills; a
  run that must survive is launched in its own session, and a chain of
  heavy steps is ONE watchdog hold, never several queued behind each
  other.

## Feedback survey — 2026-09-14 lane/d (the Style-section law audit)

Counted per axis: friction 2, sugar 0, features 1, defects 0,
doctrine 3, performance 0, process 2. The top three by cost: a law
that was false forty minutes after it landed and stood for eight
days; a hand-kept list beside the tool that owns it; a refuter's
final sentence that had to be checked against the tree like any
other claim. Not surveyed: any package's code beyond the names the
seven laws cite; the other sections of CLAUDE.md (the next slices).
No Avra was written this slice, so sugar, defects and performance
are empty by scope and not by sweep.

### FRICTION — what cost time

- **A SUBAGENT REPORT TRUNCATES AT THE HARNESS, NOT AT THE
  FINDING.** Both agents' reports were cut mid-law and had to be
  re-requested in pieces; the cut fell inside the one law that
  mattered, twice. EVIDENCE: two `SendMessage` round trips for laws
  5–7 and for law 5's final text. THE ASK: none for the tree — brief
  a subagent to lead with verdicts and put exact texts LAST, so the
  cut lands on the recoverable half.
- **THE GATE OUTGROWS THE FOREGROUND WINDOW.** `make gate` under the
  watchdog crossed 600 s and moved to the background; the lock held
  and the peak printed (728 MB), exactly as the LOCK law says.
  EVIDENCE: this slice's gate. CONFIRMS CLAUDE.md's "THE LOCK IS THE
  LAW"; no ask.

### FEATURES — a capability

- **A KEEPER FOR THE NAMES DOCTRINE CITES.** CLAUDE.md names 98
  snake_case identifiers in backticks; before this slice two of the
  seven Style laws cited fns dead since 20dae3b, and no tool could
  say so. Measured after the fix: 96/98 resolve, and the two that do
  not are a negative example (`emit_loop`, a shape the law refuses)
  and a prose shortening (`get_owned`). EVIDENCE: a grep of every
  `` `a_b` `` in CLAUDE.md against packages/, tools/, runtime/,
  backend/. THE ASK: `make doctrine` — grep each cited identifier
  and refuse a dead one unless the sentence licenses it; a 2%
  false-positive floor is the price of not finding the next
  `printed_value` by hand.

### DOCTRINE — a law missing, misleading, or stale

- **A LAW CAN BE STALE THE DAY IT LANDS.** The builder-words law was
  written at 56424e0 (15:05) asserting a "builder failed:" prefix
  the same author removed at c7b5038 (15:46). The entry described
  the tree it was about to change, in the present tense, and the
  correction was in the commit body and not in the doctrine.
  EVIDENCE: `git log -1 --date=iso` on both. THE ASK: a change that
  retires a mechanism a law names carries the law's edit in the same
  commit — the cited-name keeper above is the enforcement.
- **A COUNT IN A LAW NAMES ITS RECEIPT.** "five of today's messages
  … against eight real defects" never matched c7b5038's own body
  ("five of the seven builder refusals lane C sampled"); today's
  split is 10 defect-worded to 13 law-worded. Reworded to the
  receipt's figure and its commit. CONFIRMS "A COUNT FROM A PACKAGE
  SWEEP IS LINES, NOT SITES" one level up: a count with no base is a
  claim.
- **A GENERAL SHAPE MUST FIT ITS OWN INSTANCE.** The law's lesson
  read "put the claim in the words, not in a flag — a flag can be
  set wrong", while its instance was the reverse: the flag
  (`Cause.Builder`, still projected to F0102) was right and the
  prose restating it lied. Reworded: a paraphrase of a flag is a
  second copy; words carry the claim, structure the category, and
  the words never restate the category. EVIDENCE:
  `grammar/executor.av:374`, `language/codes.av:19`.

### PROCESS — the working discipline

- **KEEP: the auditor/refuter pair, and check the refuter too.** The
  refuter found both the count mismatch and the incoherent general
  shape, which the auditor had passed; its own closing sentence
  ("either the words carry the claim or the structure does, never
  both") contradicted the tree and was corrected against
  `codes.av:19`. A refutation is a claim like any other.
- **KEEP: the hand list dies in the same commit that finds it.**
  DOGFOODING's `Ratcheted:` line lagged the tool by two rules;
  `python3 tools/idioms.py --rules` answers now and the doc points
  at it. One flag, one pointer, no third copy.

## Feedback survey — 2026-09-14 lane/d (the Rules-section law audit)

Counted per axis: friction 1, sugar 0, features 1, defects 1 (a
keeper's, latent), doctrine 4, performance 0, process 2. The top three
by cost: a keeper that read three of nine `Ins` consumers only up to
their first arm; a consumer count spelled in three places while the
keeper's table grew past it; a lead's own grep that missed the first
row of a heredoc. Not surveyed: "The subset today" and "Working
discipline" (the next slices); any package's code beyond what the 68
laws cite. No Avra was written, so sugar and performance are empty by
scope.

### FRICTION — what cost time

- **A GREP FOR `^Ins` MISSES THE ROW ON THE OPENER'S LINE.**
  `CONSUMERS="Ins …` puts the first row after the variable name, so a
  line-anchored grep counted eight rows of nine and I filed `dst_of`
  as missing from the keeper, added a duplicate, and read `Ins 10`
  back. Cost: one false finding, one revert. EVIDENCE: tools/vocab.sh:28.
  THE ASK: none for the tree — ask the keeper (`make vocab` prints its
  count) before grepping the file it guards; CLAUDE.md's "ENUMERATE
  FROM WHAT THE CONSUMER SEES" already says so.

### FEATURES — a capability

- **THE ROSTER IS ONE TABLE.** The `Ins` consumer list is spelled in
  tools/vocab.sh, core/ir.av's header and `avra new ins`'s scaffold;
  the two prose copies said "eight" while both listed nine. This slice
  made the prose count-free and left three lists. THE ASK: the
  scaffold and the header read vocab.sh's rows (a comptime `const` over
  the table, or the scaffold shelling to `make vocab --rows`); the
  third copy names the concept and dies.

### DEFECTS — a keeper that examined too little

- **A CONSUMER ENDED AT THE FIRST CLOSING BRACE.** tools/vocab.sh ended
  a fn at `/^ *}$/`, so a dispatch with a braced arm was scanned only
  to that arm's close: `memory_ins` 78 of 224 lines, `body_lines` 54
  of 121, `give` 397 of 403. Latent — the unread regions carry no
  catch-all today — and witnessed both ways on copies: a planted
  `_ ->` at memory_ins:75 refused, at :150 accepted. Fixed in this
  slice: a fn ends at the brace on ITS OWN indent, the keeper prints
  lines examined per consumer, and a two-surface self-test plants the
  shape. EVIDENCE: the rules refuter's probe; `make vocab` now prints
  the per-consumer count. CLAUDE.md's "THE DELIMITER IS NOT WHERE THE
  LAYOUT SUGGESTS" names this exact shape, for a different tool.

### DOCTRINE — stale facts in nine of 68 laws

- **A COUNT IN A LAW IS A CLAIM WITH NO RECEIPT.** "19 sites" (no
  grep reproduces it), "eight consumers" (nine), "four emitters"
  (five: `.Pack`, memory.av:210), "three features" (four). All four
  counts were true when written and none carried the command that
  produced them. Reworded count-free or to the keeper that holds the
  number. CONFIRMS "A COUNT FROM A PACKAGE SWEEP IS LINES, NOT SITES".
- **A DEAD NAME IN A LAW IS INVISIBLE TO EVERY READER.** `balanced`
  and the `"quote" "{" t:STRING "}"` rule both died at 131f044 when a
  quote became a parsed tree; the law kept teaching `quote {` as a raw
  body. Survey #9's cited-name keeper ask covers it; 93 backticked
  names now resolve but two licensed.
- **AN ATTRIBUTION EXPIRES WHEN THE CODE LANDS.** "The sqlite lane's
  empty-path door is the instance, attributed" — landed at 7ac2c51
  (open.av's `path_fault`) and still labelled as another tree's. THE
  ASK: a merge that lands an attributed instance edits its label in
  the same commit; the cited-name keeper cannot see this one.
- **A LAW'S EXAMPLE WEARS THE TREE'S CURRENT SPELLING.** Two examples
  (`tag_of(cx, v)`, `lower_defect(cx, e, …)`) were free-fn forms I39
  now refuses; a reader copying the law's own example would have
  tripped the ratchet. Reworded to the methods.

### PROCESS — the working discipline

- **KEEP: parallel auditors, one refuter, and the refuter checks the
  lead too.** Four Opus auditors over 17 laws each, one refuter over
  their nine texts; the refuter found the keeper defect while testing
  a fact I had handed it as established, and refuted two of my three
  handed-down facts. A fact in a brief is a claim like any other.
- **KEEP: exact FROM/TO pairs applied by script.** Nine rewordings
  landed by `str.count(old) == 1` replacement with no hand editing; a
  FROM that did not match would have failed loudly instead of
  splicing at the wrong anchor (CLAUDE.md's twice-applied-patch law).

## Feedback survey — 2026-09-14 lane/d (the Working-discipline law audit)

Counted per axis: friction 0, sugar 0, features 0, defects 0,
doctrine 3, performance 0, process 2. The top three by cost: four
`file:line` pointers that had all rotted in one law; a law calling a
fn "never existed" the day after that fn landed; a keeper whose
accepted surface had no fixture while the law beside it demanded
one. Not surveyed: "The subset today" (the last slice; probe-heavy).
No Avra was written, so the empty axes are empty by scope.

### DOCTRINE — stale facts in six of 24 laws, plus one in Rules

- **A LINE NUMBER IN A LAW IS A CLAIM WITH A HALF-LIFE OF ONE EDIT.**
  `Makefile:59-64` now lands on the bootstrap target (`make recover`
  moved it), `ROADMAP:2018/2109/2190/2345` all point elsewhere,
  `open.av:358` is a doc comment two fns down. Reworded to NAMES: a
  target, a fn, a heading, a greppable phrase. EVIDENCE: wd-gA's
  probes; `grep -n "^avra:" Makefile`. THE ASK: the cited-name keeper
  (survey #9) refuses a bare `file:NNN` in CLAUDE.md, or resolves it
  and reports drift.
- **"HAS NEVER EXISTED" IS A DATED CLAIM.** The two-surfaces law said
  no `refused_n` had ever existed; it landed at c515f04 with 30
  callers, and the idioms matcher that once permitted a dead spelling
  now permits a live one. The law's own ask — N spellings, N positive
  fixtures — was unpaid in the tool. Paid: `ACCEPTED` in
  tools/idioms.py, five fixtures, falsified by dropping one spelling.
- **A LABEL EXPIRES WITH THE LANDING, TWICE.** The two-hats law still
  said "the sqlite driver lane reports" for a URI door in open.av
  here, and the receipts law cited that label as its live exemplar.
  Slice three fixed one expired label and read past this one in the
  same section; a sweep by CLAIM ("attributed", "lane's") finds them,
  a sweep by law does not. CONFIRMS "THE SWEEP IS BY CLAIM, NEVER BY
  FILE".

### PROCESS — the working discipline

- **KEEP: refuse a fresh line number as a fix.** The refuter was told
  to reject any TO text that swapped a rotted line for today's, and
  did; every replacement cites by name. A rule stated to the reviewer
  beats one hoped for from the author.
- **KEEP: land the label fix before the law that cites it.** Two
  hats before the receipts law, or the receipts law names a label
  still standing in the same commit. One PR, ordered hunks.

## Feedback survey — 2026-09-14 lane/d (the subset re-probe; the audit's last slice)

Counted per axis: friction 2, sugar 0, features 0, defects 3 (the
compiler's, filed), doctrine 3, performance 0, process 2. The top
three by cost: three compiler defects found by re-running the file's
own examples; a probe harness that rewrote `\u` into U+FFFD and
reported a holding entry as accepted; an entry that contradicted its
neighbour eleven lines down. Not surveyed: the two entries a loose
file cannot reach (a declares-annotation needs a second module; a
minted NUL needs `@std/text`) — cited from source, not probed. No
Avra was written beyond scratch probes.

### FRICTION — what cost time

- **THE PROBE HARNESS REWRITES `\u`.** A heredoc and the editor's
  Write both turned `"�"` into a real U+FFFD, so entry 26's
  probe first read ACCEPTED where it HOLDS (length 6, a backslash and
  a `u`). `printf '\134u'` writes the byte. EVIDENCE: sub2's report.
  THE ASK: none for the tree — write probe files with printf and
  octal escapes; a probe's file is checked with `od -c` before its
  result is believed.
- **`$?` AFTER A PIPE IS THE PIPE'S.** Four exit-0 readings were
  `tee`'s status. Read the compiler's status before piping.

### DEFECTS — the compiler's, filed under avra-8sb5.5

- **A `null ->` ARM OVER A NULLABLE ENUM CASCADES F3002** ("`null` is
  a keyword — pick another name") beside the true F2013, and carets
  the arm's body. Filed avra-ismf.
- **AN ANNOTATION ON A FN'S TAIL EXPRESSION IS SILENT**: `@no_such`
  before the tail `1` checks and runs clean; on a statement or a
  declaration it is F3000. Filed avra-mtrh.
- **A USER `fn main` CALLED FROM THE TOP LEVEL RECURSES** into the
  program's own entry ("recursion too deep — 400 nested calls"), no
  annotation involved. Filed avra-ewei.

### DOCTRINE — the cache moved under nine entries

- **A CACHE ENTRY NAMES ITS BASE OR IT CANNOT BE RE-CHECKED.** 58
  entries re-probed at f178c17: 46 held verbatim; 8 refuse with a
  different code or different words today (`ident` unpinned now
  SPEAKS F2033; the two-`for` comprehension now names the
  comprehension first; a parse error no longer stops typing for the
  file); `@comptime` parses now (F3000, a speaking law, deleted);
  `export const` compiles (the guard spares a `const_value`, the
  clause retired). Every rewording quotes the output it was
  re-probed with.
- **TWO ENTRIES CONTRADICTED EACH OTHER ELEVEN LINES APART.** The
  `export const` refusal and the top-level-`const` entry ("exported
  only when it says `export`") both stood; one was stale. CONFIRMS
  the duplicate-prose law's premise that prose has no gate; a
  cross-entry contradiction needs a reader, and this audit was one.
- **AN EXAMPLE THAT TRIPS A SECOND LAW HIDES THE ONE IT SHOWS.**
  Entry 22's comprehension example named a parameter `as`, a
  keyword, so its probe drew F3002 beside the refusal it exists to
  demonstrate. Re-spelled.

### PROCESS — the working discipline

- **KEEP: the refuter re-runs every probe.** Told that a verdict it
  had not reproduced was not a verdict, it refuted one of eleven
  (entry 27's "stops there": the whole file goes untyped, earlier
  declarations included) and narrowed two others.
- **RECORDED TRIGGER, unchanged:** when `lang/subset/*.av` lands as
  gate-verified program tests, this section becomes a pointer. Its
  first two members are the entries a loose file cannot reach.

## Feedback survey — 2026-09-14 #14 (TOOLCHAIN, the pointer seat's box — PR pending)

Counted per axis: defects 1 (the keeper's, mine, caught by making it
fail), doctrine 1, process 1; friction, sugar, features, performance
empty. Not surveyed: any tree but ../avra-lane-a.

### DEFECTS

- **A KEEPER THAT LOOKED UP ONLY WHAT THE WALL NAMED.** The first
  `wrong_boxes` took the C signatures already in hand, and those are
  looked up BY THE NAMES `extern fn` DECLARATIONS ASK ABOUT — so a
  row nobody declares (`avra_str_len`, emitted by the compiler) was
  never compared and a flipped box passed. Found by flipping one box
  and watching nothing happen; it reads every row's C now. The
  "make it fail" law, paid on the day the keeper was written.

### DOCTRINE

- **THE COLUMN IS FILLED FROM THE C, NOT BY HAND.** `const char*` is
  `Text` and `void*` a box; the sweep that wrote 46 rows read the C
  bodies' parameter types, and the keeper reads them again on every
  gate, so the fill and its check are one reading. A hand-filled
  column would have been a second registry.

### PROCESS

- **A PROBE THAT IMPORTS A KEEPER RUNS IT.** `import externs` ran the
  keeper's main and exited before the probe's first line; the listing
  it was meant to produce came from a standalone regex instead. A
  tool meant to be imported by a probe guards its main.

## Feedback survey — 2026-09-15 lane/d (the recorded-trigger audit, avra-8sb5.9)

Counted per axis: friction 1, sugar 0, features 1, defects 1 (the
compiler's std, filed), doctrine 4, performance 0, process 2. The top
three by cost: a deadline that fired the day it was written and stood
eight days (the digit fold that wraps); 37 triggers recorded in the
ledgers and in no task; three triggers recorded AFTER their own
condition had arrived. Not surveyed: triggers inside docs/ (only
ROADMAP, CLAUDE.md and DOGFOODING were swept); other masters' epics
beyond a keyword search. No Avra was written beyond scratch probes.

Verdicts over the 30 children of avra-8sb5.9, every non-OPEN one
re-run by a refuter: 19 OPEN (condition re-worded as a law, owner
named or "owner unconfirmed"), 6 FIRED-UNPAID, 4 FIRED-AND-PAID
(closed with the commit), 1 OBSOLETE (closed with the mechanism).
The sweep's 49 candidates refuted to 37 untracked (8 tracked in other
epics, 3 not triggers, 1 duplicate), all 37 minted under .9.

### FRICTION — what cost time

- **A SWEEP THAT SEARCHES ONE EPIC CALLS TRACKED WORK UNTRACKED.**
  Eight of 49 candidates had tasks under other epics (avra-8sb5.2,
  .4, .5, .10, .11). The refuter searched the whole db by keyword.
  THE ASK: none for the tree — a sweep for "untracked" searches the
  whole tracker, never the epic it will file into.

### FEATURES — a capability

- **ONE INTEGER PARSE ROW.** `v = v*10 + (c-48)` is hand-rolled in
  four places and guarded in one (grammar/lexer.av's `int_value`
  answers `int?`); json.av, toml.av and core/holes.av wrap silently
  at 9223372036854775808. `"42".to_int()` is F2030 and the runtime's
  `avra_int_text` has no inverse. The trigger (.9.1) fired unpaid;
  routed to STD-DATA avra-bjkk. THE ASK is the row, once, that the
  three copies then call.

### DEFECTS — filed

- **THE DIGIT FOLD WRAPS** (above): `max=9223372036854775807
  over=-9223372036854775808 way_over=7766279631452241919`, exit 0,
  no trap, in the std parsers, where the lexer refuses identical text
  with F0001. Task .9.1 carries the probe.

### DOCTRINE

- **A TRIGGER RECORDED AFTER ITS CONDITION IS A DEADLINE ALREADY
  PASSED.** Three of thirty fired at birth: .9.15 (`once fn` had
  landed), .9.30 (the render path landed two days before the
  trigger), and .9.20's "fifth walk" count was uncountable in its own
  commit. THE LAW: a trigger's first probe is run the day it is
  recorded, and the result is written beside the condition.
- **A LEDGER ENTRY THAT IS PAID AND STILL READS LIVE RECRUITS.** Three
  ROADMAP triggers were paid (85aa9a8, 865c806, 296c008) and still
  written as open; one `- [ ]` box was fixed at fe1c152. Corrected in
  place with the commit. CONFIRMS "a stale ledger entry recruits like
  a wrong owner does" (epic avra-8sb5.5's notes).
- **A RETRACTED PREMISE STOOD IN THE ROADMAP AFTER CLAUDE.md SWEPT
  IT.** ROADMAP's extern-seat trigger still said "no Avra string can
  hold a NUL, because nothing mints one"; `from_codepoint(0)` landed
  the same day the entry was written. CLAUDE.md's "A RETRACTED FACT
  SPREADS BY CITATION" law, firing on the file it names. Corrected.
- **A DEADLINE WHOSE KEEPER CANNOT BE FOUND IS UNPINNED.** The docs
  deadline cites `docs_adversarial_test.av`; no such file is in this
  tree. Marked; the DOCS lead confirms or writes it.

### PROCESS — the working discipline

- **KEEP: the trigger-owner law.** Two OPEN triggers named owners
  inferred from a file or a prose handoff; both reworded to "owner
  unconfirmed" — a named owner in a trigger is a routing instruction.
- **KEEP: name the paying epic, never mint a twin.** A FIRED-UNPAID
  trigger keeps its task and gains the paying epic in its comment; the
  master re-parents it. Six went that way.

## Hand-kept lists in tools/ and the Makefile — the census paid (2026-09-14, TOOLCHAIN)

avra-8sb5.1.21's six, re-measured on main at 12738f7, and the sweep
that found what the six missed. CONVERTED: (1) `tools/externs.py`'s
`("runtime", "backend")` tuple is a glob of every `*/*.c` under the
tree's root outside `packages/` — a new top-level C directory joins
the keeper the day it appears; (3) its three opens of
`runtime_api.av` are one `rt_api()`; (5) `SUITES` is derived
(tools/suites.py, its own PR). RETIRED BEFORE MEASURED: (2)
`tools/stems.sh` and (6) `tools/libscope.sh` are not in the tree; (4)
`NOT_A_POINTER` is gone from externs.py. FOUND BY THE SWEEP, the one
that mattered: `tools/idioms.py`'s `SRC` listed twelve package roots
and the tree had fifteen — std-sqlite, std-meta and std-derive were
never read by `make idioms`, which reported debt 0 over them. The
roots are every `packages/*/src` now; widening them exposed 18 sites,
of which 7 were the KEEPER's — I23 read a one-line fn's `with { mode:
… }` as a parameter list (a greedy `\((.*)\)`), the false positive a
positive-only specimen table cannot see, so the tool has a CLEAN
table now, the shapes a matcher must accept. The other 11 are
licensed at the site (four C out-parameter cells, two annotation
decoders, three callback contracts) or fixed (one unused import).
LEFT AS DATA, each with its reason: `tools/vocab.sh`'s CONSUMERS —
naming a registry's consumers IS the law's enforcement (CLAUDE.md);
`SQLITE_FLAGS` — the definition, kept honest by `promised()`;
`tools/traps.sh`'s fixture manifests — programs, not a registry.
LEFT WITH A TRIGGER: the Makefile's per-package object rules
(`build/sqlite3.o`, `build/sqlite_sentinel.o`, `build/width_witness.o`)
and `test:`'s object prerequisites are one list spelled in two
places, and the package-C standard (lane/http, ROADMAP B7) is the
derivation — fires when it lands on main. `tools/census.sh:18`
respells the runtime's compile line with `-DAVRA_CENSUS`; a second
respelling names the Makefile variable it should read.

## Feedback survey — 2026-09-14 #11 (TOOLCHAIN, the hand-kept-list census — PR pending)

Counted per axis: defects 1 (a keeper's), doctrine 1, process 1;
friction, sugar, features, performance empty. Not surveyed: any tree
but ../avra-lane-a at 12738f7.

### DEFECTS

- **THE IDIOM KEEPER READ TWELVE OF FIFTEEN PACKAGES.** `SRC` was a
  list; std-sqlite, std-meta and std-derive were never read, and
  `make idioms` reported debt 0 over them from the day each joined.
  Roots are every `packages/*/src` now; the widening exposed 18
  sites, 7 of them the keeper's own false positives (I23's greedy
  `\((.*)\)` on one-line fns carrying `with { k: v }`). EVIDENCE:
  tools/idioms.py:29 before; `make idioms` over the widened roots.

### DOCTRINE

- **A KEEPER HAS TWO SURFACES AND HAD ONE TABLE.** `SPECIMENS` proves
  each matcher fires; nothing proved one stays quiet. `CLEAN` is the
  accept-side table now (the clean check named the old regex when it
  was put back — witnessed). CLAUDE.md's "a keeper has two surfaces"
  entry already states the law; this is its second instance and the
  first with a fixture table.

### PROCESS

- **A CENSUS AGES FAST.** Of avra-8sb5.1.21's six items, three were
  gone before they were measured (two tools deleted, one list
  retired); the sweep that mattered found a seventh the census had
  named as fixed. Re-measure a census on the day it is paid, and
  count what the sweep finds beside it.

## Feedback survey — 2026-09-14 #10 (TOOLCHAIN, the suites derived — PR #9)

Counted per axis: friction 1, defects 2 (the tool's own, found by its
red team, fixed), doctrine 1, process 1; sugar, features and
performance empty. Not surveyed: any tree but ../avra-lane-a.

### FRICTION — what cost time

- **A GATE KILLED FROM OUTSIDE THE WATCHDOG.** The harness stopped a
  running `make gate` "because the system is running low on memory"
  while the watchdog's own floor (20%) had admitted it; the tree was
  left clean (the `tested` trap removed the scaffold) and the gate
  was re-queued by hand, ~25 minutes. THE ASK: none the tree can
  pay — the harness's floor is not the watchdog's; a lane reads a
  killed gate as "re-run", never as a verdict.

### DEFECTS — silent shapes in a keeper written that morning

- **A DIRECTORY HOLDING TESTS WITH NO MANIFEST WAS QUIETLY NO SUITE.**
  The first draft skipped it, which is the exact disease the tool
  exists to kill. Refuses now ("holds tests and no avra.toml —
  nothing would ever run them"), fixture pinned.
- **A SYMLINKED PACKAGE WAS TWO SUITES.** `packages/alias -> a` listed
  both and would have run one suite twice; refuses now, fixture
  pinned. Both found by building the hostile tree, not by reading.

### DOCTRINE

- **A DEV EDGE ORDERS NOTHING.** Ordering by every dependency row
  found a cycle on the first run (`std-io -> std-text -> std-io`,
  through text's dev edge to io); the order reads `[dependencies]`
  alone, which is the workspace's own law (`dep_chain`: a dev edge
  starts its own chain). Written into the tool's doc.

### PROCESS

- **A TOOL'S RED TEAM IS A HOSTILE TREE.** Nine trees built in a
  scratch script found two silent shapes in a tool whose five
  fixtures were all green; the fixtures were the shapes the author
  imagined. Keep: build the trees before calling a keeper done.

## Feedback survey — 2026-09-14 #9 (TOOLCHAIN, `avra staged` retired — PR #8)

Counted per axis: friction 3, sugar 0, features 0, defects 0,
doctrine 1, performance 1, process 1. The top three by cost: the
build lock's queue (a step launched first waits behind steps launched
later), a scratch probe that cannot print, and a one-file test that
compiles its whole package. Not surveyed: any tree but
../avra-lane-a at 12738f7 + this slice.

### FRICTION — what cost time

- **THE LOCK'S QUEUE IS NOT A QUEUE.** A one-file test launched at
  14:45 was still waiting at 14:57 while a `make avra` launched at
  14:53 held the lock: `watch.sh` polls, so whoever polls at the
  right moment wins, and a long waiter can starve. Cost: the test was
  killed and the whole suite run instead. EVIDENCE: `ps` at 14:57
  listed five `watch.sh` waiters and the 14:53 holder. THE ASK: a
  ticket — the lock directory holds a queue file, and a waiter takes
  the lock only when its ticket is the lowest.
- **A PROBE CANNOT PRINT.** The laziness of `??` was probed by a
  TRAP on the right side, because a scratch file has no `println`
  (F3000 "no `fn println` is defined") and its shown value is one
  expression. CONFIRMS avra-3qg3 (the prelude); this is its wanting
  site outside the tree's tests.
- **ONE FILE'S CASES COST THE PACKAGE'S COMPILE.** `avra test
  <file>` in `@std/avrac` compiles the whole package to run five
  cases — the same cost as the whole suite (peak 462 MB, watch), so
  the suite is the cheaper receipt and the per-file form buys
  nothing. THE ASK: a per-file test compiles the file's module
  closure, not the package's.

### DOCTRINE

- **THE CLI RULE NAMED ONLY COMMANDS.** CLAUDE.md's CLI rule read
  "main.av only composes the list", and the entry now also hands off
  before the app runs. AMENDED in this slice, in the same paragraph.

### PERFORMANCE

- **A GATE PEAKS AT ~740 MB, NOT 0.3 GB.** Every gate and `make avra`
  in this slice peaked between 712 and 791 MB under `watch.sh`
  (bootstrap 712, `make avra` 745/789/791, gate 744/738) at
  12738f7. CLAUDE.md's "a gate is ~0.3 GB" and `watch.sh`'s header
  describe an older tree; the number is worth re-measuring by whoever
  next reads a peak as a regression.

### PROCESS

- **A PIPE'S EXIT IS THE LAST COMMAND'S.** Two red-team rounds read
  `./avra … | head -1; echo $?` as the compiler's exit and recorded
  0 for a refusal that exits 2. The truncating-probe law one step
  over: record an exit code with no pipe on the line, and the words
  from a second run.

## Feedback survey — 2026-09-14 #12 (TOOLCHAIN, @std from the install root — PR pending)

Counted per axis: friction 2, defects 2 (found by the slice's own
probes, fixed), doctrine 2, process 1; sugar, features, performance
empty. Not surveyed: any tree but ../avra-lane-a.

### FRICTION — what cost time

- **THE SHIM READS THE SUBCOMMAND WORD AS A PATH.** `avra build x.av`
  was a heavy step under the lock because `build/` is a directory
  at the tree's root and the heaviness loop tested every argument —
  every `avra build` of one file has queued behind the machine lock
  since the loop was written. FIXED: the loop skips the first word.
- **A TEST CANNOT RUN A PROGRAM WITHOUT ITS ENTRY.** Three new cases
  wrote `program(null).run()` after the pattern of the cases-at
  tests beside them and answered nothing; `program("/w/src/main.av")`
  is the spelling the running tests use. One name (`program`) for
  "the package's program" and "this file's program" — the null form
  should refuse a `run` it cannot enter.

### DEFECTS

- **A RELATIVE PATH ARGUMENT WAS READ WHERE THE TREE STOOD.** The shim
  `cd`s to the tree's root before the CLI reads argv, so `avra check
  src/main.av` from another directory found nothing; only `explain`
  rooted at `AVRA_CWD`. Every path argument is rooted there now,
  absolutely. Its twin: a bare binary run from a package's own root
  with a relative path never found the `avra.toml` at `.` (the walk
  stops before the empty directory) — absolute rooting pays both.
- **A KNOWN KEY IS NOT A REACHABLE KEY.** The first draft of the
  toolchain door answered "reachable" for any key some package
  carried, so a transitive `@acme/words` stopped being F3013 — one
  existing test caught it. A std key the toolchain carries is
  everyone's; any other key is the manifest's.

### DOCTRINE

- **A DECLARED ROW PINS FOR THE WHOLE GRAPH, AND ONLY WHEN THE STD
  PACKAGES DECLARE NO ROWS OF THEIR OWN.** A root's `"@std/text" =
  { path = "vendor/text" }` beside a toolchain `@std/io` that itself
  declares `"@std/text" = { path = "../std-text" }` is F4014 — two
  directories, honestly. The pin works once the std packages resolve
  their siblings through the toolchain, which is why their rows
  must go — RECORDED TRIGGER: strip every `@std/*` row from
  `packages/std-*/avra.toml` and `packages/cli/avra.toml` AFTER
  `make seed` has refreshed the seed with this resolver; a seed that
  predates it cannot compile a manifest with no rows, and
  `seed-check` would fail the gate.
- **THE HOST CARRIES THE TOOLCHAIN'S FACTS.** `Host.std_root` and
  `Host.cwd` are defaulted fields; a memory host has no toolchain
  unless a test gives it one, and `memory_host_at` stands in a cwd
  as the disk does. Written into workspace.av.

### PROCESS

- **PROBE FROM OUTSIDE THE TREE.** Every defect above was invisible
  from inside: every in-tree path is relative to the root the shim
  moves to. A slice about "usable outside this repo" is probed from
  a scratch directory first, and the scratch package's stray files
  join its program (two hostile `use` lines made a clean `run`
  fail) — one file per probe package.

## Feedback survey — 2026-09-14 #13 (TOOLCHAIN, the prelude — PR pending, stacked on #11)

Counted per axis: friction 1, sugar 1, doctrine 2, process 1;
features, defects, performance empty. Not surveyed: any tree but
../avra-lane-a.

### FRICTION — what cost time

- **A PACKAGE'S OWN PROGRAM TEST IS A FILE OF THE PACKAGE.** The
  prelude's proof, laid out as `src/tests/hello/hello.av`, belonged
  to the prelude package and so saw no prelude — one gate. The proof
  is a nested package (`tests/hello/avra.toml` + `src/main.av`),
  which is also the user's shape. The lesson generalises: a package
  whose feature is "what other packages see" proves it from a
  package that is not itself.

### SUGAR — a construct the language should have

- **`print` WITHOUT A NEWLINE.** Lane C's list named it; no runtime
  row backs it (`avra_puts` writes a line, `avra_io_write` a file),
  so the prelude cannot carry it under its own rule. THE ASK: an
  `avra_print` row, then `print` joins the floor.

### DOCTRINE

- **THE PRELUDE IS A PACKAGE, NOT A SCOPE.** Lane C's recommendation,
  taken: it is a node in the graph, so the layering has a bottom and
  the floor law (F4018, a prelude manifest declaring a dependency) is
  enforceable; a scope could not be at the bottom of anything.
- **WEAK BINDING IS THE SHADOW LAW.** A prelude export binds only
  where nothing else holds the name (`bind_prelude`, beside
  `bind_builtin`), so a file's `fn println`, its `use @std.io.
  {println}` and a `let println` all win in silence — witnessed from
  an outside package for each. No warning: a name the floor offers is
  a default, and a default overridden is not a mistake.

### PROCESS

- **THE SEED'S GENERATION GATES TWO SWEEPS.** Both this slice's and
  #11's stripping sweeps (io's two verbs; the std manifests' rows)
  wait on one `make seed` on main; filed as one recorded trigger in
  CLAUDE.md each, both naming the same event.

## Feedback survey — 2026-09-15 lane/d (the Bytes re-probe, and the process-spin read)

Counted per axis: friction 1, sugar 1, features 0, defects 0,
doctrine 3, performance 0, process 3. The top three by cost: a held
fact that recorded half a signature; a held fact that was false in
this tree rather than merely unlanded; a law whose own evidence
argued against it. Not surveyed: anything needing a package (the
grammar claim was settled from the tree's own suite instead).

### FRICTION — what cost time

- **A HELD FACT CANNOT BE PROBED WITHOUT THE FEATURE, AND THAT IS THE
  POINT.** Three facts sat held for eight days because the section's
  standard is that every entry quotes a refusal probed against THIS
  compiler. When Bytes landed, one probe each settled them — and two
  of the three were wrong in ways no amount of re-reading the fact
  would have shown. THE ASK: none. The hold was correct and the
  eight days were the feature's, not the process's.

### SUGAR — a construct the compiler's own users will want

- **A REFUSAL THAT NAMES THE WRONG SHAPE SHOULD NAME THE RIGHT VERB.**
  `b[0]` on a `Bytes` answers "`[...]` indexes a `List`, found
  `Bytes`" — true, and silent about `.at(i)`, which is the thing the
  writer wanted. Every other refusal in this tree that removes a form
  names its replacement. WANTING SITE: features/bytes, the index
  seat. THE ASK: a help line naming `.at(i)`.

### DOCTRINE

- **A FACT RECORDED FROM HALF A SIGNATURE DECAYS LIKE A COUNT.** The
  held fact said "`List<int>.bytes()` answers `Bytes?`, not `Bytes`".
  True, and one third of the method: `bytes()` answers by RECEIVER —
  `Bytes` from a string, `Bytes?` from a `List<int>`, and a plain
  `Bytes` from a `List<Bytes>`, which GATHERS. I found the other two
  halves by reading `check_of_list` before the compiler existed to
  probe, and the probe then confirmed all three. A fact taken from
  one call site is a count in different clothes.
- **"UNLANDED" AND "FALSE HERE" ARE DIFFERENT VERDICTS.** The third
  held fact ("a grammar with no holes is refused") was filed as
  describing an unlanded feature. It is contradicted: no such refusal
  exists anywhere in the tree, and the suite EXERCISES a hole-less
  sublang block expecting it to work. A held fact is re-probed, never
  promoted on the strength of its having waited.
- **THE SECTION'S OWN CHARTER DECIDED WHERE THESE GO.** "The subset
  today" is for what the compiler REFUSES THAT THE LANGUAGE WILL
  WANT — a sugar-backlog candidate. A nullable answer for a
  non-octet is correct design and will never be closed, so all of
  this landed under "Runtime facts, ours to ratify" instead. Filing a
  permanent design in the gap list would have put a line there that
  no future slice can ever delete.

### PROCESS

- **KEEP: read the source, then probe — in that order, once.** The
  two-answer correction came from reading `check_of_list` while no
  Bytes-aware binary existed, and was labelled unconfirmed until the
  probe. Reading found the question; the probe answered it. Neither
  alone would have.
- **KEEP: a build slot asked for, not queued into.** The machine was
  under a P0 spin fix and two integrations; asking for the lock and
  waiting cost nothing, and the bootstrap then ran on a tree that
  waits instead of spinning.
- **THE THIRD INSTANCE OF THE CLAIM UNDER TEST, and it is mine.**
  Correcting a peer's unrun magnitude, I wrote an unrun magnitude
  into a law three paragraphs later. A peer's retraction sent me back
  to my own sentence. Recorded rather than quietly fixed, because a
  rule breached in the hour it was enforced is the strongest evidence
  the rule needs enforcing.

### PROCESS — a prediction from source, and what the numbers said

TWO FIXES PREDICTED FROM SOURCE, BOTH NEEDED, NO BINARY. Reading the
pre-fix pump I named two places the honest fix could go: ask the pipe
question INSIDE the grace loop, or make the poll row sleep when there
is nothing to poll regardless of whether the child is alive — the
second called the better home, because that row's own comment already
states the law it fails to keep. Both turned out to be REQUIRED, and
the second alone was not enough: with the burn gone the wall time
stood, because the loop still asked the clock alone. Measured by
STD-SUBSTRATE (00ec4fb, 8f9713e; theirs, quoted): 349.57 s wall and
22.66 s user with the spin fixed alone, 15.42 s and 9.17 s with both,
against a 7.38 s / 1.04 s pre-substrate baseline — 21x wall and 35x
CPU recovered, and the suite 104/106 -> 108/108.

THE RECEIPT THAT MATTERS IS NOT THE VERDICT. A prediction that named
the SHAPE of a fix nobody had written yet, timestamped before the
branch existed, is a different kind of evidence from a verdict on a
diff — and this tree has no entry for it. It is the inverse of "the
prediction did not come true, and here is the mechanism": same
discipline, opposite outcome, and both beat a verdict delivered after
the fact.

AND THE TEST WOULD HAVE CAUGHT THE ORIGINAL, which is rare enough to
state: the CPU cases shipped with the fix FAIL on main as it stands.
A test written after a fix usually cannot fail for the real reason —
this one can, because it measures CPU, the only witness that
separates a wait from a spin. The control I asked for is in the suite
too: the old body with a grandchild still holding a pipe, which is
what makes "the defect was the missing state, never the grace loop"
a proof instead of an assertion.

AND I HAD TO APPLY MY OWN CORRECTION TO MYSELF. Correcting their
unrun "a 200 ms turn would have cut the spin tenfold", I wrote into
the law that cutting the grace "would have bought a real tenfold" —
a counterfactual magnitude I had not run either, three paragraphs
later. It now states the mechanism (the spin lasted exactly the
grace, so cutting it cuts the burn in proportion) and carries no
number. The seconds above live here, in a dated survey, because that
is where a measurement can decay honestly.

### DOCTRINE — HOW TO WRITE A LAW SO IT SURVIVES (the audit's 99 laws, re-read)

The claim the STD MASTER asked for, tested against the audit's own
verdicts rather than asserted.

THE RESULT IN ONE SHAPE: 99 / 17 / 0. Ninety-nine laws, seventeen
carrying a stale decoration, ZERO whose law sentence was wrong — and
twelve of the seventeen were invisible to every tool this tree has.
The doctrine is sound and its FOOTNOTES are not, which is a different
problem from "laws rot" and has a different fix: the laws need no
rewriting, the decorations need a keeper or deleting.

WHAT THE DATA SAYS. Ninety-nine laws audited across four sections;
seventeen carried something stale. In every one of the seventeen the
verdict was MIXED and never SYMPTOM — the LAW SENTENCE was right in
all ninety-nine. What rotted was always a DECORATION beside it: a
count, a line number, an attribution, a name, a negative claim.

THE SPLIT THAT MATTERS is not mechanism-versus-instance, which was
the first wording and is too coarse. It is CHECKABLE versus
UNCHECKABLE decoration.
- A NAME is checkable: `printed_value`, `bool_word`, `balanced`,
  `tag_of(cx, v)`, "all in core/nodes.av". Five rotted; a grep finds
  every one, and `make doctrine` (avra-if44) would refuse them.
- A COUNT, a LINE NUMBER, an ATTRIBUTION and a NEGATIVE CLAIM are
  not: "19 sites", "eight consumers", "four emitters", "three
  features", "31 `avra_io_` references", `Makefile:59-64`,
  `ROADMAP:2018`, "the sqlite lane's", "no such fn has ever
  existed". Twelve rotted and nothing could see any of them —
  they were found by a person re-deriving each claim by hand.

THE COUNTER-EXAMPLE, which is why the coarse wording fails: the
header law names a MECHANISM (sixteen bytes before every payload)
and still described the fourth field wrongly — a size class where
the runtime stores a length. Naming a mechanism makes a claim
CHECKABLE; it does not make it true.

SO THE RULE FOR WRITING A LAW: state the law, then decorate it only
with what a tool or a reader can re-derive. A name, yes. A count, a
line number or an attribution only with the command that produced
it, or not at all — and a count that a keeper already holds (the
`Ins` consumers, the ratcheted idioms) is cited by naming the
keeper, never copied.

THE SECOND BODY OF EVIDENCE is this citation happening at all: the
"ORDER, NOT GRANULARITY" law was findable at a live defect two weeks
later because it named its mechanism (the process pump's turn
length). A law written as a general principle would not have been
greppable from the symptom. One instance is not a proof, and it is
the reason to keep the rule as a claim under test rather than a
settled law.

THE SECOND BODY OF EVIDENCE, and it adds a SUBCATEGORY the first pass
missed. The decorations above divide into checkable and uncheckable;
this one is a third thing — CHECKABLE IN ONE GREP AND FALSE. The
ORDER law cited, as its proof, that "the process pump's turn length
was never tuned once when it moved from C into Avra". Three receipts,
all git-only: the law landed 2026-09-07 and the pump moved into Avra
2026-09-14, seven days later; on the law's own date the Avra side
chose a turn PER CALL SITE (100, 50, 0, 100); and the tree carries
two turn lengths today, a named 20 and a bare 10 at three sites.

WHY THAT RANKS ABOVE THE ROTTED ONES. An uncheckable decoration
merely decays. A checkable-and-false one ARGUES FOR THE OPPOSITE of
the law it adorns — this one offered "we never needed to tune" as
evidence, from a pump that had tuned four times. And the tell is the
cruel part: the law was believed BECAUSE its evidence was concrete.

SO THE RULE GAINS ITS SECOND HALF: decorate a law only with what can
be re-derived, AND RE-DERIVE IT. The first half stops the rot; only
the second stops a law from carrying an argument against itself.

THE CLAUSE ABOUT NUMBERS, which is this rule applied and not a second
one. A number in a law is either its SUBJECT or its EVIDENCE, and the
test above decides which: can it be re-derived from a NAMED
INSTRUMENT? The cold-path law's arithmetic IS its judgement — without
the ratio worked out nobody can tell a 26% win from an invisible 0.8%
one — and it names `make census` and `objdump` in the same entry, so
it stays. A count of the tree or a run's seconds names no instrument,
and belongs in a dated survey. A standing rule that all measurements
leave the laws was proposed and WITHDRAWN on exactly this ground: it
condemned the two laws that use numbers correctly.

## Feedback survey — 2026-09-15 (STD-SUBSTRATE: the pump, PR #16)

Three rows from one P0: the std-process pump burned a core and paid a
floor nobody was waiting for (avra-7202, fixed in #16 — `00ec4fb`,
`8f9713e`). Each stands on its own; the third is the one to read.

### PROCESS — A LOUD FAULT HIDES A QUIET ONE ON THE SAME PATH, AND THE
### FIX'S OWN NUMBERS ARE WHAT SEPARATE THEM

Two independent defects sat on the drain grace. The loud one: with the
child reaped and both pipes closed there was nothing to poll and
nothing to sleep on, so `avra_proc_ready` answered instantly and the
loop spun — a core, for the whole grace. The quiet one: the loop asked
the CLOCK alone, so a command with no holder at all still paid the
full floor.

NO MEASUREMENT OF THE ORIGINAL COULD HAVE SEPARATED THEM. Before the
fix the suite read real 329.81s / user 322.70s — wall and CPU within
2%, which says "it is computing", and the quiet fault contributed
nothing visible because the loud one was already consuming every
millisecond of the same window.

WHAT EXPOSED IT WAS THE FIRST FIX'S OWN NUMBERS: real 349.57s against
user 22.66s. A 15x gap between wall and CPU is a WAIT NOBODY ASKED
FOR, and that pair of columns is the whole instrument — cheaper than a
profiler and available in `/usr/bin/time`. Both fixed: 108/108, real
15.42s, user 9.17s (21x the wall, 35x the CPU).

THE ASK, and it is a habit rather than a tool: read wall and CPU
TOGETHER, before and after, and treat a change in their RATIO as a
finding of its own. A fix that cuts CPU and leaves wall alone has not
finished; it has uncovered.

### DEFECT — A MEASUREMENT THAT MEASURED NOTHING PRINTS A NUMBER

Two runs of the before/after measurement reported `real 0.00 user 0.00
sys 0.00` and looked like results. The subject had never built: the
fresh worktree had no `build/avra`, `avra test` died at once, and
`/usr/bin/time` timed the failure faithfully. Caught only by reading
the output instead of the exit status — the runs "succeeded".

This is the tree's own "a check that examined nothing is not a check
that passed", arriving in an INSTRUMENT rather than a keeper, and it
is nastier there: a keeper that examines nothing says success, while a
measurement that measures nothing says A NUMBER, and a number is what
everyone quotes. THE ASK, done in this arc and worth generalising: a
measurement refuses to print a row unless its subject says it ran —
no `tests passed` line, no number, and the refusal names what it saw.

### DOCTRINE — THE GUARD WAS WRITTEN FOR THE STATE THAT EXISTED

`avra_proc_ready`'s fallback carried the comment "nothing to watch but
a child still running: a bare wait, since polling no descriptors would
spin" — the hazard was SEEN and the guard was written for the live
child. The state that arrives one line later, a reaped child whose
pipes are closed, was the one nobody wrote, and its condition
(`p->pid >= 0 && timeout_ms > 0`) fails on its first conjunct there:
the timeout is never read at all.

FOURTH INSTANCE TODAY of "an assumption nothing has ever tried to
violate is not a guarantee", after the integrator's missing `mkdir`
and the uncapped build log (twice). The shape is identical each time:
correct for the arrangement its author had, silent about the one that
arrives next. Attributed: LANE-D found this from source with no binary
and predicted both homes for the fix.

AND IT CORRECTED ME. I wrote that tuning `turn_ms` (20 -> 200) would
have cut the spin tenfold and left it a spin. False, and checkable in
four lines: the timeout is never read in that window, so the turn
length changes nothing measurable. The tempting knob was
`drain_grace` (`secs(2)`), where cutting it WOULD have cut the burn in
proportion, left the spin intact, and paid for it by shortening the
window a grandchild has to speak — a tuned interval standing in for
the ordering the loop actually needed.

## Feedback survey — 2026-09-15 lane/d (`make cited`, the keeper for doctrine citations)

Counted per axis: friction 2, sugar 0, features 1, defects 1 (mine,
in the keeper's own first draft), doctrine 2, performance 1, process
2. The top three by cost: a keeper that read its own source and so
whitelisted its own fixture; a path matcher that stopped at the first
file of that basename; a worktree carrying another session's
uncommitted work into my staging area. Not surveyed: ROADMAP.md
citations, deliberately out of scope.

### FEATURES — what landed

- **`make cited`.** Refuses a name or a path CLAUDE.md or
  DOGFOODING.md cites that the tree cannot answer, and a bare
  `file.av:NNN`. In the gate. On its first real run it found five
  dead names and two unresolved paths; three names were genuine rot
  (`index_of_name`, `union_expected`, `refused_impl` — sites renamed
  or removed) and are fixed, two are licensed absences, and both
  paths were the keeper's own bug.
  IT REACHES A THIRD, AND ITS NAME SAYS WHICH THIRD. Of the audit's
  17 stale decorations, 5 were names and 12 were counts, line numbers
  and attributions. A keeper called `doctrine` would have claimed the
  other two thirds — the test-name law, in a Makefile target.

### DEFECTS — in the keeper's own first draft

- **A KEEPER THAT READS ITSELF WHITELISTS ITS OWN FIXTURES.** The
  symbol set is "every lowercase word the tree uses", and the tool
  lives in `tools/`, so its own fixture name counted as defined and
  the self-test refused to run. Caught by the self-test on the first
  execution, which is the only reason it did not ship. THE FIX: the
  keeper does not read its own source or its allow file. THE
  GENERAL SHAPE: a tool inside the tree it measures is part of the
  measurement, and it is the loosest possible whitelist — any name
  becomes "defined" by being mentioned in the tool.

### FRICTION

- **A PATH MATCHER THAT RETURNS AT THE FIRST CANDIDATE.** The first
  draft found the first file of a basename, tested it, and returned —
  so every `mod.av` in the tree but one read as missing. It matches
  path SEGMENTS IN ORDER now, so `std-sqlite/boundary.av` resolves
  `packages/std-sqlite/src/boundary.av`: strict about names, tolerant
  of the middles a reader would skip.
- **MAIN'S WORKTREE CARRIES ANOTHER SESSION'S WORK.** I branched in
  it and staged 131 changed lines of DOGFOODING.md, of which ~10 were
  mine — the rest another session's uncommitted type-syntax edits. I
  reverse-applied my own four edits, restored the branch, and moved
  to a clean worktree. THE ASK is the standing one (lane epic .5.3):
  a lane never branches in the shared worktree. Nothing was lost, and
  only the line count in `git diff --stat` made it visible.

### DOCTRINE

- **THE SCOPE LINE IS LIVE DOCTRINE VERSUS DATED RECEIPTS.**
  CLAUDE.md and DOGFOODING.md state what is true now, so a dead name
  there is a defect. ROADMAP.md is receipts with dates, and checking
  it would demand edits that falsify the record. The keeper says
  which files it read and how many source files it read them
  against.
- **A LICENCE CARRIES ITS REASON OR THE SELF-TEST FAILS.**
  `tools/cited.allow` holds four entries, each with why: two negative
  examples (a shape the law refuses), one sugar-backlog name, one
  prose shortening. A licence with no reason fails the self-test
  rather than passing quietly.

### PERFORMANCE

- **ONE PASS, NOT N GREPS.** The first attempt ran a grep per cited
  name over the tree and was killed at 120 s. Reading the tree once
  into a symbol set does the same work in about a second, over 686
  source files.

### PROCESS

- **KEEP: falsify both surfaces before landing.** Four fixtures run
  by hand against the built keeper: a dead name, a dead path, a bare
  line citation, and a licence with no reason — each refused, and the
  tree green again after. The accepted spellings have fixtures in the
  self-test, which is the defect I found in `tools/idioms.py` this
  morning and did not want to repeat in a keeper written the same day.
- **KEEP: the keeper's first run is a measurement, not a formality.**
  It found three real stale citations in a file nobody suspected,
  written by people who had every reason to keep it current.

## Feedback survey — 2026-09-14 #15 (TOOLCHAIN, after the seed — toolchain/after-seed, no PR)

Counted per axis: friction 2, doctrine 1, process 1; sugar, features,
defects, performance empty. Not surveyed: any tree but
../avra-lane-a; the slice lands last, bootstrapped from the refreshed
seed, so its seed-check receipt is the master's.

### FRICTION — what cost time

- **A BINARY CANNOT SAY ITS GENERATION.** The worktree's standing
  `build/avra` was the Ptr-seat product (off main) when this branch —
  whose manifests assume the std-root resolver — was built with it,
  and the refusal was F3013 on every std `use` in the cli: a true
  message about the wrong cause, one chain lost. The way out was the
  generation ladder (build the prelude branch's product, then this
  branch twice). THE ASK: `avra --version` carries the source commit
  the binary was built from (P7), so "my binary predates my source"
  is one command instead of a diagnosis.
- **A TOML COMMENT HAS NO OWNER.** Stripping rows and their emptied
  sections by regex ate a comment block that belonged to the NEXT
  section twice (`[process.tools]`'s in cli, `[link]`'s in sqlite),
  and left three that belonged to removed rows standing; the rule
  that held — a block glued to a following header is that header's —
  is a heuristic. THE ASK: manifest edits as structured fixes the
  compiler writes (`dependency_fix` already adds a row; a `drop row`
  fix and a section-empty rule beside it), so no sweep regexes TOML.

### DEFECTS

- **THE SEED-CHECK BINARY COULD NOT SEE THE STD IT WAS TESTING.**
  `seed-check` links the seed's compiler into `build/seed-check/`, and
  `@std/*` resolves from the binary's own directory — so it looked for
  `build/packages`, found no std root, and reached std only through the
  manifest rows. It went red the moment this slice removed them, with
  a diagnostic pointing at `plan_binary` in stage.av and nothing about
  resolution. The binary links beside `build/avra` now, which is the
  layout the resolver describes; law in CLAUDE.md. The tell was that
  the failing call sat in a file whose imports had just changed —
  and the cause was neither the file nor the imports.

### DOCTRINE

- **A BRANCH'S BUILD NEEDS A PRODUCT OF ITS MANIFESTS' GENERATION.**
  A manifest with no std rows is readable only by a compiler that
  carries the resolver, so the standing binary must be at least that
  generation or the build refuses with a message about dependencies.
  Held in this slice's commit message and on avra-n1w7; the general
  form is CLAUDE.md's "after a language change merges, a lane's
  first build is `make bootstrap`" — this is its pre-merge twin,
  where the seed is the older one and a sibling branch's product is
  the bootstrap.

### PROCESS

- **FOUR HARNESS KILLS TODAY.** Two more gates stopped "because the
  system is running low on memory" (444 MB and 376 MB peaks, both
  under the watchdog's floor); every one left the tree clean and was
  re-queued. CONFIRMS avra-kbxq; nothing new to file.

## Feedback survey — 2026-09-15 #16 (TOOLCHAIN, the redirect audit)

Counted per axis: defects 1 (mine, caught by its own fixture on the
first run), doctrine 1, process 1; friction, sugar, features,
performance empty. Not surveyed: any tree but ../avra-lane-caps.

### DEFECTS

- **A CAPTURE WRAPPER THAT ANSWERED GREEN FOR EVERY RED COMMAND.**
  `tools/capped.sh` runs a command with its output capped and must
  answer the command's own status, since a bare pipe answers `tail`'s.
  The status rides the stream as a marker at its end, where `tail`
  cannot cut it — and `set -e` was inherited by the subshell the
  pipeline's first element runs in, so a failing command ended that
  subshell BEFORE the marker was written, the marker's absence read
  as "no status", and the wrapper answered 0. EVIDENCE: the fixture
  asserting a red command's status, on its first run, before the tool
  was wired anywhere. Nothing in the tree would have caught it: every
  site is `cmd || { show; exit 1; }`, so the failure mode is a build
  that reports success.

### DOCTRINE

- **A CAP BELONGS ON A LOG, NEVER ON DATA THAT IS COMPARED.** Four of
  the six redirects are logs read by their tail and take the cap; the
  two that `witness` and `native-check` DIFF do not, because a `tail`
  over both can truncate two different outputs into agreement —
  manufacturing the equality those rules exist to test, with no
  failing run to reveal it. In CLAUDE.md with the slice.

### PROCESS

- **A KILLED PROBE IS CHEAPER THAN A QUEUED ONE.** A smoke test of a
  capped site in a born-clean worktree became a heavy run: `./avra`
  with no `build/avra` bootstraps from the seed and takes the
  machine-wide lock, so a "light" probe sat in front of another
  lane's gate. Killed it and ran the checks that need no compiler.
  Know which probes are light BEFORE the worktree has a binary.

## Feedback survey — 2026-09-15 #17 (TOOLCHAIN, the Type registries)

Counted per axis: defects 1, doctrine 2, process 0; friction, sugar,
features, performance empty. Not surveyed: any tree but this one.

### DEFECTS

- **THE MACHINE PROJECTION ITSELF WAS UNGUARDED.** `ll_type_of` in
  llvm.av dispatches exhaustively over `Type` and decides the LLVM
  type every value takes; `make vocab` had never named it, so a new
  `Type` variant could have reached codegen with no arm and nothing
  would have said so. It was invisible to the task that found the
  other two because nobody had asked. The keeper reports Type 6 where
  it reported Type 3.

### DOCTRINE

- **A KEEPER'S FALSE POSITIVE CAN NAME A MISSING VERB.** Naming
  `slot_worthy` made `make vocab` refuse it: an arm asked
  `types.shape_of(inner) is .Var`, which a grep cannot tell from a
  dispatch on the value being judged. The test was legitimate — it
  asks about the `Opt`'s INNER type — so the cheap answers were a
  license or a narrower matcher. The right one was the question the
  refusal was really asking: that test deserved a name. It is
  `abstract_yet(id)` on the registry now, beside `opt_rides_pointer`,
  and the arm reads as prose. Before licensing a keeper's false
  positive, ask what it was reaching for.
- **A REGISTRY LAW CAN BE MISAPPLIED, AND THE COST IS CEREMONY.** The
  six `machine_shape` callers are refused deliberately; the section
  below carries the argument and the trigger.

## The `machine_shape` callers — a registry law MISapplied (2026-09-15, TOOLCHAIN)

avra-0fay asked for three unguarded `Type` registries. Two are
registries and are now in `tools/vocab.sh`'s table (`ptr_shape`,
`slot_worthy`), along with a third the task did not name and the
keeper had never seen: `ll_type_of`, the machine projection itself.
`machine_shape` is NOT one — it is `if is_flat … else shape_of`, no
match at all, so it cannot be a consumer. What the task was reaching
for is its SIX `is .Variant` CALLERS, and the answer there is to
change the value they ask about rather than the way they ask.

THE CALLERS, judged one at a time. `binary_value` asks `is .Float` to
choose the float arithmetic; `call_rt_value` asks `is .Bool` for the
answer's icmp and `is .Float` for the unslotting bitcast; `slotted`
asks `is .Bool` for a zext and `is .Float` for a bitcast; `rt_val` in
the interpreter asks `is .Bool` to rebuild a boolean. Every one asks
THE SAME THREE-WAY QUESTION — does this value live in a float
register, is it a bool needing a width, or is it a plain word — and
each spells it as one or two `is` tests with a fallthrough.

WHY SEVEN EXHAUSTIVE MATCHES WOULD BE THE LAW MISAPPLIED. The
registry law exists so that a NEW VARIANT MUST DECIDE. A new `Type`
variant has no opinion about floatness: forcing `.Decimal`, `.I32` or
the next value category to state, six times over 25 variants, that it
is not a float is ceremony that hides the one decision that matters.
The tree already spells the right shape one enum over — `rides_fp`
answers, for an `RtKind`, which register file a seat rides — so the
concept has a name and a precedent here.

THE FIX IS A NARROW FORM, AND IT IS NOT MINE TO LAND. `machine_shape`
should answer a small machine FORM (word, float, bool, pointer) with
ONE exhaustive projection from `Type`; the six callers then match
over three or four variants, and a new type decides once, in the
projection, where the decision belongs. STD-DATA is adding `SlotForm`
to the slot table, which is this concept arriving from the other
side. HANDED TO THEM with this reasoning rather than done quickly and
wrongly here; the six callers are listed above by name so the sweep
is mechanical once the form exists. RECORDED TRIGGER: when `SlotForm`
(or its successor) lands, `machine_shape` answers it and this entry
is what the sweep follows.

## Feedback survey — 2026-09-15 #18 (TOOLCHAIN, the lane's whole night)

Nine slices landed or pushed tonight (staged, suites, census, std
root, prelude, Ptr-seat box, seed-check, after-seed, gate receipt,
caps, idiom tables, Type registries, the receipt's channels). This
survey covers what the NIGHT taught that the per-slice surveys #9 to
#17 did not, and does not repeat them.

Counted per axis: friction 2, features 1, defects 3 (all mine, all
caught before or at first use), doctrine 4, process 3; sugar 0,
performance 0. The top three by cost: the fork bomb I wrote and then
misdiagnosed (three sessions' builds, ~40 minutes of other lanes'
work), the lock's unfairness (gates queued 10 to 30 minutes all
evening, read as ordinary contention until another campaign measured
it), and the two-channel contract that shipped a skip firing on "no
receipt". NOT SURVEYED: any tree but this lane's five worktrees, and
the integrator's behaviour after my branches left my hands.

### DEFECTS — mine, and what each says about testing

- **A FORK BOMB IN A SELF-TESTING TOOL, AND ITS AUTHOR MISREAD ITS
  FIRST SYMPTOM.** `gate_receipt.sh --self-test` invoked `write`, and
  `write` ran the fixtures first — "an instrument proves itself
  before it certifies anything" — so the fixtures ran the verb that
  ran the fixtures: 986 and 985 processes in one chain, 2441 of a
  2666 fork limit, and every other session's builds died on `fork:
  Resource temporarily unavailable`. THE HALF WORTH KEEPING: ten
  minutes earlier a probe of mine had died with that exact message
  and I wrote it off as machine load, because the self-test passed on
  either side of it. The signature — A RESOURCE EXHAUSTION PRESENTS
  AS A FAILURE IN WHATEVER ELSE HAPPENS TO BE RUNNING — fooled the
  author of the bomb, holding its own output. Fixed by SHAPE: every
  verb is a function, the fixtures call the functions, and
  `grep -c 'sh "$0"'` over the capture path is 0, so recursion is
  unreachable rather than bounded. Filed as avra-l33q.
- **A TWO-CHANNEL CONTRACT WHERE THE CALLER READ THE WRONG
  CHANNEL.** `receipt_trusts` printed its refusal REASON on stdout
  and returned 1; the caller I wrote in the same commit read stdout
  and swallowed the status with `|| true`, so "no receipt in
  …/build" READ AS PERMISSION and the skip fired exactly where it
  must not. Caught on the feature's first integration by the
  announcement the design required, not by a test. MY FOUR FIXTURES
  PROVED THE WRONG CONTRACT: they called the function and checked its
  EXIT STATUS, which is not how the caller used it — four green
  fixtures over a function nobody invoked that way. Same family as "a
  test with its own copy of the logic tests the copy", one seam over:
  the copy is the CALLING CONVENTION. Filed as avra-zxo9; the
  contract now fails safe (stdout non-empty if and only if trusted).
- **A CAPTURE WRAPPER THAT WOULD HAVE ANSWERED GREEN FOR EVERY RED
  COMMAND**, caught by its own fixture on the first run — recorded in
  survey #16, cited here because it is the third instance of the same
  night's pattern: the defect was in the SHELL's semantics, not the
  logic, and only a fixture that ran the real thing could see it.

### DOCTRINE

- **A REFUSAL THAT EXPLAINS ITSELF ON THE SAME CHANNEL AS ITS CONSENT
  IS A TRAP FOR THE NEXT CALLER.** The general law behind the skip
  defect, and it reaches well past that tool: when a verb answers
  both a VERDICT and PROSE, the prose must not travel where a
  careless reader takes it for the verdict. Give consent its own
  channel and the failure mode inverts from open to safe.
- **A DESIGN NOTE THAT MAKES THE MECHANISM SAY WHAT IT DID IS AN
  INSTRUMENT**, whether or not it was written as one. "A skip is
  announced with what it trusted, because a verification that is
  sometimes skipped and never says so is one nobody can audit" was
  written as a justification for a design choice; it printed two
  contradictory lines next to each other and caught the design's own
  defect on its first real run. The inverse of this tree's entry
  about a doc that demonstrates a hazard being code that has never
  been run.
- **A KEEPER'S FALSE POSITIVE CAN NAME A MISSING VERB** — survey #17,
  cited here as the night's best small outcome: the cheap answers
  were a license or a narrower matcher, and the right one was to ask
  what the refusal was reaching for.
- **A NAME IS NOT AN IDENTITY, AT THE FILESYSTEM TOO.** The
  integrator derived its worktree path from a lane name and began a
  rebase inside a lane's live worktree, which it did not own; earlier
  the same day a directory was removed because its name matched a
  convention. Both are the `impls_by_name` hazard wearing a
  filesystem's clothes — a key that does not identify, failing
  silently and confidently. (STD MASTER's, attributed; their practice
  changed rather than mine.)

### FRICTION

- **THE BUILD LOCK IS A RACE, NOT A QUEUE** — and I read it as
  ordinary contention for a whole evening. A lane running
  back-to-back steps re-takes the lock before a waiting lane's next
  poll fires. My gates queued 10 to 30 minutes each; the COMPTIME
  campaign measured one of their workers losing the race 161 times in
  a row. Their fix (a ticket per waiter, dead tickets reaped) is on
  lane/comptime at 37f1ec4 and only helps between worktrees that BOTH
  carry it. Corroborates avra-3inr from the other side.
- **A BORN-CLEAN WORKTREE COSTS A BOOTSTRAP BEFORE ITS FIRST GATE,**
  and that bootstrap takes the machine-wide lock — so a "light" probe
  in a fresh worktree sat in front of another lane's gate until I
  killed it. Five worktrees tonight, five bootstraps. THE ASK: a way
  to seed a new worktree's `build/` from a sibling whose tree is
  compatible, which is what I did by hand for the after-seed ladder.

### FEATURES

- **`avra --version` SHOULD CARRY THE SOURCE COMMIT ITS BINARY WAS
  BUILT FROM** (avra-s351, filed earlier tonight): a lane cannot tell
  its binary's generation, and a stale one refuses with a true
  message about the wrong cause. It cost one wrong diagnosis here and
  the ladder to recover.

### PROCESS

- **A PATTERN THAT MATCHES THE FIRST OCCURRENCE OF SOMETHING A RUN
  PRINTS MORE THAN ONCE IS NOT A COMPLETION TEST.** My wait-loop
  watched a chain's log for `watch: peak` and fired on the
  BOOTSTRAP's peak, so I read a gate as finished when it had not
  started. Filed as avra-9f7h with the truncating-probe law and
  avra-dnf2 as one family: treating the first hit as authoritative
  when the key does not identify. I wait on a task's own exit now.
- **THE HARNESS KILLS HEAVY RUNS FOR MEMORY THAT THE WATCHDOG'S FLOOR
  ADMITTED.** Six kills tonight, every one leaving the tree clean and
  every one re-queued; peaks at the moment of death were 376 to 447
  MB, well under the cap. A killed gate is a re-run, never a verdict.
- **VOLUNTEERING A WRONG CALL COSTS LESS THAN IT LOOKS AND IS WORTH
  MORE THAN THE FIX.** Twice tonight I reported a conclusion I had
  reached and then falsified — the fork bomb misdiagnosed as machine
  load, and a gate read as finished that had not started. Both went
  into the ledgers as their own findings; neither was visible to
  anyone but me, and both generalise past the incident. A lane that
  reports only its fixes hands the next reader a tidier and less
  useful record.

## Feedback survey — 2026-09-15 (STD-DATA: the word slot, PR #20)

Scope: `avra-0wv6` only — reading the relaunch doc, falsifying the
task, the `SlotForm` registry, its red team and review round, four
gates. Base `../avra-lane-sq-ffi` at main `6f09bf7`. NOT surveyed:
@std/sqlite (the next slice), @std/process (`avra-0m3d`, unopened),
and any performance question — nothing in this slice was measured for
time or memory, so that axis is honestly EMPTY rather than clean.

Counts: friction 4, features 1, defects 1, doctrine 3, process 3,
sugar 0, performance 0 (not swept). Top three by cost: the four gates
(~50 min of lock), the hand-rolled differential (six commands per
probe, six probes), the loose-file refusal (six file copies and one
misread minute).

### Friction

- **A NAMED FILE IS MORE SPECIFIC THAN THE MANIFEST AROUND IT.**
  `./avra run scratch/tiny.av` inside the tree answers `F4005:
  '<root>/avra.toml' declares no [bin], and 'src/main.av' does not
  exist — nothing to run`. The refusal never mentions the file that
  was named, so it reads as a broken manifest rather than "that file
  is not in a runnable position". Every red-team probe was copied
  outside the repo to be run. THE ASK: when a FILE is argued, the
  refusal names that file; `file_workspace`
  (cli/src/commands/shared.av:99) already has the three cases and the
  voice does not. Probed at `6f09bf7`, 2026-09-15.
- **I HAND-ROLLED AN INSTRUMENT THE GATE ALREADY HAS.** Six commands
  per differential — run, build, read the path, run the binary, diff,
  report — written out six times. `make native-check FILE=<f>` does
  exactly that and answers `native == eval`; confirmed on this tree.
  The tool was not the gap, knowing it existed was. THE ASK: the
  red-team skill names it, and `avra --help` or the Makefile's own
  header lists the probe targets. A hand-rolled second instrument is
  not a shortcut, it is an unverified one — this file says so about
  greps and it is just as true about harnesses.
- **FOUR GATES FOR ONE SLICE, ~50 minutes of lock.** Initial, after
  the deadline doc, after the review-round fixes, after a rename.
  Three earned their receipt. The fourth did not change a byte of
  behaviour, and nothing in the tree says what a change CAN affect,
  so a rename costs the same as a codegen edit. THE ASK: unclear, and
  recorded as friction rather than as a demand — a gate that guesses
  what a diff can reach is a gate that will guess wrong.
- **THE MACHINE LOCK IS A RACE, NOT A QUEUE.** A bootstrap waited 20
  minutes behind back-to-back steps from other lanes. CONFIRMING an
  existing finding (the comptime campaign measured the cause and one
  of their workers lost 161 times in a row); no re-file.

### Features

- **A KEEPER SHOULD COUNT FROM ITS OWN TABLE.** `tools/vocab.sh`
  printed its summary from a hand-kept `for e in Ins RtKind Type`
  beside the `CONSUMERS` table it counts, so a registry added to the
  table went uncounted by the keeper's own report — the
  label-wider-than-its-coverage species, inside a keeper. Fixed here
  (it reads the table's first column). THE GENERAL ASK: every keeper
  that reports a count derives it from the thing it read.

### Defects

- **A RUNTIME ROW'S ANSWER KIND IS CHECKED BY NOBODY** — filed
  `avra-kln6`, P1, routed to TOOLCHAIN. `extern fn avra_array_new()
  -> bool` checks clean; `./avra run` prints `made=[]` (a `bool` as a
  LIST) and the native binary prints `made=true`. `row_shape_law`
  (features/fns/check.av:129) checks a row's arity and each POINTER
  seat's box; the answer is checked by nothing. The native build DOES
  notice and CANNOT speak — its `[warn] redeclared with a different
  type` channel exists for seed/source skew, and a name in `rt_sigs`
  redeclared with a different answer is not skew.

### Doctrine

- **I44: A PACK AND ITS UNPACK READ ONE TABLE** — landed in
  DOGFOODING.md's registry, unratcheted, with `make vocab` as its
  keeper rather than a grep, since nothing textual links two fns as
  inverses.
- **THE SLOT TABLE HAS A SECOND COPY AND IT IS UNREACHABLE.**
  `rt_kind_of` (core/runtime_api.av:122) is the same `is`-chain —
  `.Void`, `.Float`, `rides_pointer`, else I64 — and asks `shape_of`
  where `machine_shape` belongs, so a FLAT record over `float` files
  as a word and a double would ride an integer seat. Unreachable
  today: F2056 refuses a named type at an extern seat and
  `extern_kind` is the only caller. RECORDED TRIGGER: the day an
  extern seat may wear a named type, or the day `rt_kind_of` gains a
  second caller, it must become an exhaustive match over
  `machine_shape`. Owner unconfirmed.
- **A STALE DOC IN @std/sqlite.** `stmt.av`'s `step` reads "The fix
  is a flag on `Stmt` and a `mut` seat here; until then, step until
  `false` and then stop" — the flag landed and the doc still
  recommends it as future work. Paid in the next slice
  (`avra-8sb5.9.5`), which rewrites that seat.

### Process

- **A WORKTREE CAN BE CLEAN AND IN USE AT THE SAME TIME.**
  `../avra-lane-sqlite` was removed while a `make bootstrap` was
  running inside it; it was clean and zero commits ahead, and both
  facts were true and irrelevant. Cost: one bootstrap. "Safe to
  delete" is a question about PROCESSES as much as about content.
- **KEEP: THE PLANTED MUTATION.** `.Float -> SlotForm.Word`, one
  `make avra`, and the new program test was witnessed FAILING — the
  native build dies on LLVM verification while the evaluator still
  answers correctly. One generation is enough to witness a codegen
  mutation, since only the product's OUTPUT is under test. And the
  result is its own finding: neither engine alone catches it and the
  DIFFERENTIAL does, which is the counter-example to "the engines
  agreeing proves consistency, not correctness" — here the engines
  disagreeing is the only witness.
- **KEEP: MEASURE THE TASK BEFORE WORKING IT.** `avra-0wv6` named
  105 uncommitted lines as a fix that was already on main under two
  commits, with the corpus program already relocated. Three tasks
  handed out that day were falsified the same way by the lane that
  received them. A task is a claim with a date on it.

## Feedback survey — 2026-09-15 (STD-DATA: the handle cells, avra-8sb5.9.5)

Scope: `avra-8sb5.9.5` only — @std/sqlite's handles becoming cells, its
red team and review round. Base `../avra-lane-sq-ffi`, rebased onto
main `b118773`. NOT surveyed: @std/sqlite's read half (`.6.2`, next
after `avra-f3qo`), @std/io, @std/process.

Counts: friction 2, sugar 0, features 0, defects 1, doctrine 3,
performance 1, process 2. Top three by cost: a probe touching a std
package needs a whole scratch PACKAGE (three attempts before the
probe ran), the compiler-guided sweep (a KEEP, and the cheapest part
of the slice), and one avoidable gate.

### Friction

- **A LOOSE FILE CANNOT REACH `@std/*`.** `use @std.text.{has_nul}` in
  a file outside any package is `F3015: this file is not in a package
  — 'use' needs a root`, help "put an `avra.toml` at the package root".
  So a probe that touches ANY std package needs a scratch package —
  manifest, `src/`, `[bin]` — and three attempts went into discovering
  that. The requirement is about MODULE NAMING, which a `@std` import
  does not need: the toolchain now finds std from its own install root
  with no manifest row at all. THE ASK: a loose file admits `@std/*`
  and refuses only a bare `use some.local.module`. Re-probed on main
  `b118773`, AFTER the toolchain's install-root resolver landed, so it
  is not a staleness artifact. Pairs with the survey above's "a named
  file is more specific than the manifest around it" — together they
  are why every probe in two slices ran from outside the repo.
- **ONE AVOIDABLE GATE.** The field default below was found by probing
  AFTER the tree had gated, so the improvement cost a second full gate.
  A probe that answers "can the language do X" belongs before the code
  that works around X, and the idiom bar already says so — this is the
  bar being skipped, recorded rather than excused.

### Defects

- **@std/sqlite: TEN STATEMENT VERBS NEVER ASK THE FINALIZED DOOR** —
  filed `avra-f3qo`. `step` and `finalize` test the handle; `width`,
  `standing`, `slots`, `reset` and every `bind_*`/`*_at` do not, and
  hand NULL to C. Measured on a finalized statement:
  `width=0 standing=0 slots=0 reset=0`,
  `class=sqlite.out_of_row int=sqlite.out_of_row`,
  `bind_int=sqlite.out_of_slots`. Two laws broken at once: the safety
  rests on `-DSQLITE_ENABLE_API_ARMOR=1` in the MAKEFILE (line 410),
  which no reader of the package would look at, and the refusals that
  do arrive state the SYMPTOM — a caller reading a finalized statement
  is sent to their column index.

### Doctrine

- **A DEADLINE IS PAID BY DELETING THE CHANNEL, NOT BY MEETING IT** —
  landed in CLAUDE.md's deadline register. `close(mut db)` was on that
  register as a double free waiting for S2; the fix was not to make
  the seat safer but to stop using a seat, so the property belongs to
  the type and survives whatever a seat copy comes to mean.
- **WHEN A DEADLINE NAMES ONE PASSENGER, ASK WHAT ELSE IS ABOARD** —
  landed beside it. The register named the HANDLE because losing it
  traps; `Stmt.done` rode the same seat unnamed, and losing that
  re-runs the statement and answers rows a second time with nothing in
  the answer saying so. The loud passenger is the one that gets
  written down.
- **A FIELD DEFAULT IS EVALUATED PER CONSTRUCTION** — landed in
  DOGFOODING. `done: Cell<bool> = Cell.new(false)` gives every `Stmt`
  its own cell; two values, two slots, measured on both engines. The
  shared-mutable-default trap other languages have does not exist
  here, and a field whose initial value is a fresh box belongs at the
  field rather than repeated at every construction site.

### Performance

- **THE CELL'S COST IS BELOW THE INSTRUMENT.** 300 open/prepare/step/
  reset/finalize/close rounds, each through two copies of both
  handles, read 0 MB peak and 0 MB live in every `AVRA_MEM_STATS`
  category. One box per handle is real and this says only that it is
  under 1 MB at 300 — not that it is free. Unmeasured: the cost at
  a connection pool's scale.

### Process

- **KEEP: THE COMPILER DROVE THE SWEEP.** Removing the `mut` seats
  left 13 declarations and 49 alias bindings stale across six files,
  and F2048/F2051 named every one — two `./avra check` cycles found
  them all. A conversion whose fallout the type system enumerates is a
  conversion that can be done at once rather than in nervous pieces.
- **A SCRIPT THAT ENDS A FN AT THE NEXT UNINDENTED LINE.** The alias
  collapse was mechanical over 49 sites, and the tool that did it used
  exactly the heuristic CLAUDE.md warns about — the delimiter is not
  where the layout suggests. It was correct here because every test fn
  is top-level, and the DIFF was read site by site rather than
  trusted. Recording the check, not the cleverness.

## Feedback survey — 2026-09-15 #19 (TOOLCHAIN, a row's answer)

Counted per axis: defects 1 (live on main, STD-DATA's find), doctrine
1, process 1; friction, sugar, features, performance empty. Not
surveyed: any tree but this lane's.

### DEFECTS

- **THE SEAT LAW HELD EVERY ARGUMENT AND NOTHING HELD THE ANSWER.**
  `row_shape_law` checked a row's arity and each pointer seat's box;
  an extern naming a row could declare ANY answer.
  `extern fn avra_array_new() -> bool` checked clean, exit 0, and the
  engines disagreed — `made=[]` evaluated against `made=true` native.
  Both halves are refused now: the currency (`extern_kind` against
  `RtSig.ret`) and, for a pointer, the box (`RtSig.answer`).
  ATTRIBUTED: found by STD-DATA red-teaming the word-slot registry,
  filed as avra-kln6 with a complete diagnosis; I wrote the fix.

### DOCTRINE

- **A `defect:` MESSAGE RAISED BY A PROGRAM THE COMPILER ADMITTED IS A
  MISSING LAW, NOT A BUG IN THE PASS THAT SPEAKS.** The compiler's
  self-blame channel is for its own invariants, so when a CLEAN
  program reaches it — "a non-Bytes value reached a byte operation in
  a clean program" — the pass is telling the truth about a
  declaration nothing refused. It is the compiler's own voice saying
  the check is in the wrong place, and it goes on saying so after a
  fix that satisfies the bug report: `-> bool` refused, `-> Bytes`
  still admitted. Read a defect message as evidence about the
  ADMITTING law, never as a defect in the reporting one.
- **A HALF-FIX LEAVES A TWIN OF THE SAME DEFECT.** The kind check
  alone closes the reported program and leaves
  `avra_array_new() -> Bytes` accepted — same kind, different box,
  and the program reads a list's header as octets: "a non-Bytes value
  reached a byte operation in a clean program". The complete law
  needed the answer's BOX as well as its currency, which is the seat
  column of avra-ihk9 arriving at the other end of the call. When a
  law is added to one end of a seam, ask what the other end's version
  of it is before calling the slice done.

### PROCESS

- **A TEST THAT REFUSES YOUR CHANGE MAY BE ENCODING A LAW NOBODY
  WROTE DOWN.** The first draft spoke twice for
  `avra_host_env(a, b) -> int` — wrong arity AND wrong answer — and
  failed an existing case asserting exactly one message. Editing the
  expectation is the near-universal instinct and would have been
  wrong: the case wanted one message because a declaration whose
  ARITY disagrees may be naming a row its writer did not mean, so
  every complaint beneath it is about a fn they were not declaring.
  Arity speaks alone; seats and the answer speak once the shape is
  right. The law is at the site now, where the test can no longer be
  the only place it lives.
- **A WARNING THAT CANNOT BECOME AN ERROR IS STILL EVIDENCE.** The
  native build already printed "avra_array_new redeclared with a
  different type — stale: ptr (), source: i64 ()" for this exact
  program, and that channel must stay a warning because it exists for
  seed/source generation skew. The task said so before I started, and
  it saved me from the obvious wrong fix — promoting the warning —
  which would have made every skewed build red. A channel's PURPOSE
  decides whether its signal can be tightened, not the signal's
  accuracy.

## Feedback survey — 2026-09-15 #21 (TOOLCHAIN, what ends text at a terminator)

Counted per axis: defects 1 (mine, in the probe rather than the
tree), doctrine 2, process 2; friction, sugar, features, performance
empty. Not surveyed: whether any public verb actually reaches an
unguarded crossing — that is avra-dtdp and it needs the compiler.

### DOCTRINE

- **A GUARD IS A DOOR AT A PACKAGE'S PUBLIC ENTRY, NOT A SPELLING AT
  A CALL SITE.** `@std/io` never calls `nul_at`: its door is
  `one_path`, spelling the scan inline. `@std/process` guards at
  `tool`, `tool_from_env` and `Env.get`, and its internal `which` and
  `search_path` hand text straight to C — correctly, because the
  public entry above them already guarded. So "does this body guard"
  is the wrong question, and a grep asking it accused 30 sites with 0
  true positives, measured before shipping. The right question is
  whether a PUBLIC verb can reach a terminator-consuming row without
  passing a door, which is a call-graph question the compiler answers
  and no tool in `tools/` can: P10 from the other end. Split out as
  avra-dtdp with this column as its premise.
- **A TASK'S STATED SIZE IS A CLAIM LIKE ANY OTHER.** avra-8tbo asked
  for a length carried across 109 extern string seats. Derived: 71
  rows take text, and 19 of them END it at a terminator — the rest
  cross into our own runtime, which reads the header. The exposure is
  a quarter of the claim and concentrated in rows the guard law
  already names, so the migration would not have caught any of the
  eight defects that prompted it.

### DEFECTS

- **A FILTER OVER THE WRONG COLUMN ANSWERS EMPTY, WHICH READS AS
  "NOTHING QUALIFIES".** The first wiring took its text seats from
  `externs()`, whose rows carry a RETURN TYPE where this needed the
  parameters, so the filter matched nothing and the keeper reported
  all 19 recorded rows as having left the set. It looked like a
  finding about the tree and was a finding about my read. A filter
  that answers empty deserves the same suspicion as one that answers
  everything.

### PROCESS

- **A PROBE WHOSE OUTPUT IS GARBLED IS A FACT WAITING TO BE QUOTED.**
  An earlier census printed `f, g, s` where function names belonged —
  `re.findall` with one group returns strings, and I indexed `[0]`.
  Caught because "f" is obviously not a function name; the version
  that ships is the one where the garbling produces PLAUSIBLE names.
- **MEASURING A CHECK'S RATE BEFORE BUILDING IT COST TEN MINUTES AND
  SAVED THE HOUR.** F2040 shipped because nobody measured; this one
  was refused on its own numbers before a line of it was written.

## Feedback survey — 2026-09-15 #22 (TOOLCHAIN, the three fired-unpaid triggers)

Counted per axis: doctrine 2, process 2; friction, sugar, features,
defects, performance empty. Not surveyed: the other 27 triggers in
LANE-D's audit — these are the three routed here.

### DOCTRINE

- **THREE TRIGGERS PROBED, TWO WRONG AS FILED, AND WRONG IN
  DIFFERENT DIRECTIONS.** avra-8tbo asked for a length carried across
  "109 extern string seats": derived, 71 rows take text and 19 end it
  at a terminator, so the exposure was a quarter of the claim and
  concentrated in rows the guard law already names — and the fix it
  asked for would not have caught any of the eight defects that
  prompted it. avra-ul2v asked to delete `avra_spawn_status` as "a
  symbol no Avra source declares": it has a registry row, an `RtHost`
  variant, an interpreter arm, a seed reference and a trap fixture.
  avra-nmmv held exactly as written. A TRIGGER IS A CLAIM WITH A DATE
  ON IT, and these were written by reading code rather than running
  it; the audit that mirrored them found three of thirty had already
  fired at birth. Evidence for the owner's open question (avra-us1e)
  that a trigger's first probe belongs on the day it is recorded.
- **A DELETION THAT REMOVES AN ATTACK IS NOT A CLEANUP.**
  `avra_spawn_status`'s live Avra consumer is `tools/traps.sh`'s
  `nul_crossing_bytes_prog` case, which attacks the
  argv-is-not-a-shell-line law on the one axis the other three cases
  miss. A chore that deletes a symbol and takes a hostile test with
  it reads as a tidy-up in the diff, and the coverage loss appears
  nowhere. Before deleting anything, ask what tests it.

### PROCESS

- **A RECEIPT IS A LINE THAT SAYS THE THING, QUOTED VERBATIM, OR
  THERE IS NO RECEIPT.** I told the master a branch had "gated green"
  when its chain had only ever printed "waiting for a build slot",
  and the task output I read was the commit subject. Third instance
  of one shape tonight — output that EXISTED, read for what it did
  not say — after a bootstrap's peak read as a gate's and a fork
  bomb's first symptom read as machine load. I caught two and sent
  the third, and corrected it unprompted before it could be acted
  on. The escalation is the lesson: my own law says a pattern
  matching the first of a repeated line is not a completion test, and
  "the task produced output at all" is that error with the pattern
  removed entirely.
- **A WORKTREE I HAVE JUST COMMITTED IN FEELS IDLE AND IS NOT.**
  Twice tonight I started the next slice inside the worktree whose
  gate was still running, because committing feels like finishing.
  The gate is the part still using it. The habit that fixes it: the
  next slice starts in a NEW worktree, always, not in the one whose
  receipt is still outstanding.

## Feedback survey — 2026-09-15 (STD-DATA: the sweep's pacing, avra-0m3d)

Scope: `avra-0m3d` only — @std/process's two turn lengths and what
measuring them found. Base: branch `data/process-turn` on main
`ffe0e68`. NOT surveyed: @std/process's other runners, @std/sqlite's
read half (`.6.2`, fenced pending the owner's own line).

Counts: friction 1, defects 1, doctrine 2, performance 1, process 2,
sugar 0, features 0. Top by cost: none — the measurement answered in
two probes and the fix was six lines. The value here is entirely in
what the measurement said versus what the task said.

### Defects

- **A RACE'S LAUNCHER WAS THROTTLED BY ITS OWN SWEEP, quadratically.**
  `race` launched ONE command per pass, and a pass waits a turn per
  live stage — so starting the k-th command waited for a sweep of the
  k-1 already running. `race(cs, ms(0))`, which asks for all of them
  at once, paid the most: 33 commands whose winner exits instantly took
  **5.4 seconds** to report it, all of it before the winner was even
  started. Fixed by launching every command that is DUE rather than one
  (`while`, not `if`) — a stagger that is not zero is unaffected,
  because `next_at` still holds the rest back.

### Performance

- **MEASURED, three runs each, `/usr/bin/time -p` beside the program's
  own `now_ms`:**

  | | before | after |
  |---|---|---|
  | race of 33, winner last, stagger 0 | 5468, 5462, 5452 ms | 98, 53, 73 ms |
  | race of 9, same shape | 494, 497, 495 ms | 29, 33, 34 ms |
  | 32 parallel sleepers (500 ms each) | 562, 595, 619 ms | 578, 616, 686 ms |
  | whole probe, wall | 8.04, 7.81, 7.73 s | 2.13, 1.96, 2.04 s |
  | user / sys | 0.37 / 0.60 s | 0.29 / 0.45 s |

  **73x on the case that was broken**, 3.9x on the probe as a whole,
  and CPU DOWN in both columns — fewer waits, no spin. The 32-sleeper
  row is ~6% slower and that is the honest cost: the one waiting stage
  now waits the named `turn_ms` (20) where the sweep used a bare 10.
  ONE value with ONE name was the task's ask, and this is its price.
  What it buys is that the field's size no longer sets the latency.

### Doctrine

- **A TUNED INTERVAL IS THE SMELL — AND THE NUMBER WAS NEVER THE BUG.**
  The task offered two options: one name for both values, or two
  documented constants. Neither was the answer. Halving 20 to 10 was
  someone keeping a sweep's feel near a single stage's, and the sweep
  did not want a smaller number — it wanted ONE WAIT instead of N. With
  `paced`, a sweep spends the turn on the first stage it asks and polls
  the rest at zero, so a stage that turns ready during that wait is
  seen one turn later at worst rather than N turns. The bare 10 is gone
  because there is nothing left for it to pace.
- **THE HAND-OFF'S DIAGNOSIS WAS RIGHT AND ITS PREDICTION WAS WRONG,
  and the difference is worth keeping.** STD-SUBSTRATE read the code
  and said whole-sweep latency GROWS WITH N. Measured, the sweep's
  throughput cost barely grows — N waits overlap the children's own
  work, so more stages means fewer passes and the total is bounded by
  the children, not by N. What grows with N is the LATENCY OF NOTICING,
  and it grows quadratically in `race` for a reason the reading did not
  reach: the launcher sits inside the polling loop. A correct reading
  of a mechanism still owes a measurement of its consequence.

### Friction

- **A CLOCK ASSERTION IN A DIFFERENTIAL PROBE MAKES THE ENGINES
  DISAGREE ABOUT NOTHING.** `native-check` failed on `ms_under_3s`:
  16 MB of piped output is under 3 s natively and over it evaluated.
  The probe was wrong, not the code. `avra-j8o4` — CLOSED IN THIS
  EPIC — says "a suite that measures the PUMP must not measure the
  CLOCK", and I wrote one anyway an hour after reading it. A law you
  have read is not a law you have applied.

### Process

- **KEEP: THE CLOCK-FREE WITNESS.** The fix is about latency, and a
  latency test wants a stopwatch and a margin. There was a better
  shape: give the losers a 300 ms deadline and put the instant winner
  LAST. The old launcher needs longer than that deadline just to REACH
  the winner, so the losers go overdue and the race REFUSES; the new
  one starts all seventeen and the winner is home first. A pass/fail
  difference, no bound, no flake — `refused` before, `winner=won`
  after. When a timing fix seems to need a timing test, look for the
  threshold that turns the latency into a REFUSAL.
- **KEEP: THREE CASES, AND ONLY ONE IS A DISCRIMINATOR.** Run against
  the old code the suite answers 17/18 and names exactly the case
  written for the defect. The other two — a stagger still staggers, a
  stage polled without a wait is still drained whole — PASS on the old
  code, and that is what a regression guard is for. Saying which is
  which is the difference between three tests and one test plus two
  guards.
## Feedback survey — 2026-09-15 (STD-DATA: the text/blob read, avra-8sb5.6.2)

Scope: `avra-8sb5.6.2` — the adoption door, the row, the evaluator's
arm and @std/sqlite's `text_at`/`blob_at`. Base: branch
`data/sqlite-read` on main `2001b36`. NOT surveyed: `.3.2`/`.3.6`,
still queued.

Counts: friction 2, doctrine 3, process 2, defects 0, sugar 0,
features 0, performance 0 (not swept — a copy's cost against a
borrowed view is the trigger's question, not this slice's). Top by
cost: a grep I let the shell eat, which nearly sent the design down a
road that did not need building.

### Friction

- **A LAW THAT POSTDATES ITS OWN RULING.** The ruling says the verb
  "takes (ptr, int)" and that "(null, 0) is the empty box". F2088 —
  *a runtime row's seat takes no absence* — landed after that was
  written, so a null cannot reach the row at all. The law did not
  change, its HOME did: `taken` (stmt.av) answers the empty box for a
  buffer of no octets and never asks C to read address zero, and the
  runtime keeps its own null branch as the belt for a direct C caller.
  A ruling is a claim with a date on it, exactly as a doc is.
- **THE GENERATION LADDER FOR A NEW REGISTRY ROW, which nothing
  documents.** A row used by the compiler's OWN source cannot be
  declared until the compiler knows the row, and the compiler cannot
  be built while its source is refused. Generation 1 carries the row
  and a placeholder arm; generation 2 adds the declaration and the
  real arm; generation 3 proves the fixed point. CLAUDE.md spells the
  ladder for a new DSL WORD and for codegen; a new `rt_sigs` row is
  the same shape and is not on that list.

### Doctrine

- **`Bytes` IS THE ANSWER TYPE AND `string` WOULD HAVE DIVERGED.** The
  evaluator turns a pointer answer into text by reading a
  NUL-TERMINATED C string at that address (`rt_val`, interp.av), so a
  door answering `string` would truncate a blob at its first zero
  byte while the native binary carried the header's full length. Two
  engines, one green suite, different values — the family this tree
  already records. Pinned: `x'004100ff00'` reads 5 octets, and text
  holding a NUL round-trips at length 5.
- **THE EMPTY CASE IS THE FIRST CASE, AND THE CLASS IS WHY IT CAN BE.**
  `sqlite3_column_blob` answers a NULL POINTER for SQL NULL and for a
  ZERO-LENGTH BLOB alike, so a read that branched on the POINTER would
  spend absence twice and hand an empty blob back as `null`. Asking
  `sqlite3_column_type` first is what makes "empty" and "absent"
  different answers, and the five cases written before the code assert
  exactly that.
- **`make externs` EARNED ITS KEEP ON A SEAT NOBODY WOULD HAVE
  QUESTIONED.** The adoption's C seat was `const char*` — the obvious
  spelling — and the keeper refused it: a `const char*` seat must name
  the `Text` box, and this one names `Any` because the address is
  FOREIGN. It is `const void*` now, which is also the honest type: a
  `char*` invites a terminator, and the length is the whole contract.

### Process

- **A GREP THE SHELL ATE ANSWERED "ABSENT" ABOUT A THING THAT
  EXISTS.** `grep -rn avra_ptr_at . --include=*.av` died on zsh's
  glob ("no matches found: --include=*.av") and I read the empty
  output as absence — then spent a long detour designing around a
  missing capability that is at `runtime/avra_runtime.c:2257` and used
  in two test files. CLAUDE.md records this exact miss, with this
  exact symbol, and I repeated it in the same session I quoted the law
  in. THE FIX IS MECHANICAL: a grep that finds nothing must be
  re-run without its filters before "absent" is believed, because a
  shell error and an empty result look identical.
- **THE SEED RIDES THIS COMMIT, and the gate is what said so.**
  `seed-check` failed with "the seed cannot compile HEAD — run `make
  seed` (a stale seed is a fossil)": the committed seed predates the
  row, so it refuses the compiler's own declaration of it. The refresh
  is in the slice rather than a later chore, which is the same rule
  this file states for a REMOVED runtime symbol — a new row the
  compiler's own source uses is the same hazard pointing the other
  way. It is a 45k-line diff and it will conflict with any concurrent
  refresh; the integrator may prefer to drop it and re-run `make seed`
  on main.
