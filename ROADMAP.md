# Roadmap — Active Work

**Structure:** Four focused files. No dumping ground:
- **ROADMAP.md** (this file): OPEN work ONLY. 65 active items. Mark DONE and archive when finished.
- **ROADMAP-STANDARDS.md**: Design principles and doctrine. Evergreen. Read-only for daily work.
- **ROADMAP-ARCHIVE.md**: Completed lanes and milestones. Historical reference.
- **FEEDBACK.md**: Timestamped findings and asks from each phase. Read-only lessons learned.

**Rules:**
1. **Every item in ROADMAP.md must be OPEN** — if you finish it, mark `[x]` to remove it on the next archive sweep.
2. **No feedback surveys, reviews, or research notes here** — those live in docs/ or lane docs. Only tracked work.
3. **No "ideas" or "wants"** — lane docs capture those during the work. Archive them when the lane lands or ends.
4. **Archive sweep:** When a lane merges or closes, move all its DONE items to ROADMAP-ARCHIVE.md with the merge commit or closure note.

Completed lanes are archived in ROADMAP-ARCHIVE.md. Design standards and doctrine live in ROADMAP-STANDARDS.md.

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

LANE A — SPEED (owns runtime/, grammar/, core/ hot paths;
measures with `./avra test packages/std-avrac --time` and `sample`,
user CPU, never wall). Baseline 2026-09-04: parse 14.2s, resolve
2.4s, sigs 0.3s, bodies 8.3s, lower 6.2s; the 1571 cases ~17s;
the compiler checking itself 28.8s.
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

            impl Point { fn origin() -> Point { Point { x: 0, y: 0 } } }

        reachable only as `q.origin()` off an instance — useless for
        the constructor that is the whole motivation.
        THE CALL SIDE NEEDS NO NEW SYNTAX, which is the finding that
        resizes the slice. `Type.name(args)` already PARSES; the
        CHECKER refuses it, with a variant-shaped message:

            Point.origin()   F2003 `Point` has no static fn `origin`
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
  - [ ] A PRELUDE or qualified expression paths (the 33 files that
        import ten names for a `grammar { }` expansion).

LANE D — THE SWEEP (cheap items for the gaps between builds; owns
CLAUDE.md, the cli entry, this ledger's bs2 section).

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

## THE C LEVEL (opened 2026-09-23) — @std/http per request at a hand-written C server's cost

Epic avra-8sb5.34; design and numbers: docs/2026_09_23_REUSE_IN_PLACE.md.
On the Linux Sprite the kernel floor (tools/bench/floor — no parsing) is
0.88 µs CPU per request pipelined; a C server doing @std/http's work is
~1.0 µs (estimate); Avra is ~6 µs. The gap is PER-REQUEST cost: tasks,
fibers and cores raise throughput and never lower it.

Landed: R1 reuse in place (a dying value lends its box), R2 records as
one block (box and cells in one allocation).

The ladder:
1. **Value records** (R4, avra-8sb5.34.6): records of scalars — `Span`,
   `Field`, `Line` — live in registers, with no box and no count. The
   biggest single lever.
   **Inline embedding** (R4b, avra-8sb5.34.10): R4 as first built makes a
   record of ints a value, but every one-word seat — a record field, an
   enum payload, a list cell — re-boxes it, so http's `Span` inside
   `Field` inside `FieldLine` inside `List<Field>` stayed 40 boxes a
   request. Embedding lays a value record field as N consecutive slots
   of the box holding it, as C lays out a struct member: field offsets
   become sums of widths, and `with`, payload reads, statics and both
   engines follow. Nested flatten (a `Field` of two `Span`s is four ints)
   comes with it. After R6; every program benefits.
2. **Count elision** (R5, avra-8sb5.34.7): no retain or release on a
   value that never escapes the fn that made it. Consuming params (R3,
   avra-8sb5.34.4) fold in here.
3. **Zero-alloc std-http** (R6, avra-8sb5.34.8): header spans in one
   flat int buffer, once-tables as static addresses, the response
   written straight into the connection's output buffer.
4. **Multi-core** (R7, avra-8sb5.34.9): one share-nothing server per
   core on SO_REUSEPORT — throughput times cores, on top.

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
  - [x] TYPED HOLES — FIRED AND PAID 2026-09-24 (COMPONENTS): `{n: int}`
        reads its span through `parse_int` in a pattern, a `grammar` and a
        route; a span that is no int fails the match. The entry as it stood:
        `{n: int}` refused (F2060, naming the
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
        OWNED (2026-09-22): the fibers campaign, lane/fibers, task
        avra-8sb5.10.1. Design docs/2026_09_22_FIBERS_DESIGN.md (every
        block a scope, cancellation at pause points, a deterministic test
        scheduler, no scheduler unless used); worked programs
        docs/2026_09_22_FIBERS_TOUR.md.
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
        is F2003 "`Idea.parse` is a static fn, and a static fn is not a
        value yet", whose help writes the wrapper: a static fn is
        callable (`Idea.parse(t)`) but not yet a value, so every route
        wraps it — `(t: string) -> Idea.parse(t)`, one honest line. WANTING SITE: the router's
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

## Sugar Backlog — Feature Requests and Language Asks

Tracked in the tasks db under epic `avra-8sb5.10` (the canonical SUGAR BACKLOG epic; `tasks tree avra-8sb5.10`), not here — this section used to hand-list them, which let the same ask get filed three or four times under different wording before anyone noticed. Every ticket carries an `Example:` and a `Callsite:`. Landed asks are closed there with the evidence that proved it (a probe against `build/avra check`, not a doc's memory); duplicates found across ROADMAP/FEEDBACK/DOGFOODING and the SURVEY epic were merged into one ticket each.

### Interim record — the tasks server was unreachable at landing

The two asks of `docs/2026_10_01_FIRST_OF_AND_IS_BINDING.md`
landed on branch `ui-findis`; this stands in until the tickets can be
filed. Both carry an `Example:` and a `Callsite:`.

- **`find_map` on `List`** — LANDED.
  `Example: attrs.find_map(match it { .Level(r) -> r, rest -> null }) ?? 1`.
  `Callsite:` `std-http/src/jar.av`'s `last_of`/`expiry` first-match
  reads. Evidence: `features/lists/tests/find_map` (eval == native,
  the short-circuit trap witness) and `find_map_adversarial_test.av`.
- **Payload-binding `is`** — LANDED for an `if` condition (parse-time
  desugar to the match machinery).
  `Example: if a is .Level(r) { return r }`.
  `Callsite:` the `level_of` scan in the design note.
  FOLLOW-UP still owed: the same binding in a `when` arm —
  `Example: when { a is .V(r) -> r, _ -> 0 }`; `Callsite:` any scan
  that would rather choose than branch. To be filed as its own ask
  when the tasks server returns.
