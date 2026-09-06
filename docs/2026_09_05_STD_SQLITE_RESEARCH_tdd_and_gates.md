# @std/sqlite — TDD AND THE GATES: the machinery this campaign is proved by

> Companion to `docs/2026_09_05_STD_SQLITE_RESEARCH_probe_log.md` (what the
> compiler does), `_api_surface.md` (what SQLite offers) and
> `_avra_ffi_spec.md` (what the language must grow). This file answers one
> question only: HOW each of those is proved, using machinery that exists in
> this tree today, with the file and line where it lives.
>
> Everything in Part I was READ from the tree at `lane/sqlite` (main
> `d96a328`). Nothing in Part I was run — this session is read-only on the
> tree by the machine rule (`CLAUDE.md:682`). Where a claim is inferred
> rather than read, it says so.

---

# PART I — THE MACHINERY, READ FROM THE TREE

## 1. The test DSL — `spec` / `given` / `then`

It is a compiler FEATURE, not a library. Its whole definition is four files
under `packages/std-avrac/src/features/specs/`.

**The grammar** (`features/specs/mod.av:27-31`):

```
stmt        = "spec" n:STRING "{" ( BREAK | g:given_group | g:then_case )* "}" END @recover(sync_to: "END") -> spec_decl(n, g)
given_group = "given" n:STRING "{" ( BREAK | t:then_case )* "}" @expect("}", …) @recover(sync_to: "END") -> given_group(n, t)
then_case   = "then" n:STRING b:block @recover(sync_to: "END") -> then_case(n, b)
```

So the surface is exactly:

```avra
spec "<suite>" {
    given "<group>" {
        then "<claim>" { <statements…> <bool expression> }
    }
    then "<claim>" { true }          // a `then` may stand directly under the spec
}
```

**What each word is.**

| word | what it is | law | code |
|---|---|---|---|
| `spec` | a top-level DECLARATION; the program around it still runs | lives at the top level | F3022 (`specs/mod.av:23`) |
| `given` | a GROUP NAME and nothing more — no setup, no teardown, no state | a group names each case once | F3023 (`specs/mod.av:24`, `semantics.av:33-36`) |
| `then` | a BODIED DECLARATION answering `bool` — typed, lowered, and run like any fn | a `then` answers a bool | F2042 (`specs/mod.av:25`, `check.av:11-19`) |

The three words are keywords because the gram's identifier-shaped literals
ARE the keyword claim (`Grammar.keywords()`, `CLAUDE.md:445`). Nothing lists
them by hand.

A case's identity is its three names plus its place —
`suite / group / name @ file:line` (`packages/std-testing/src/testing.av:24-26`),
pinned by `features/specs/tests/specs_test.av:90-97`.

Cases are gathered by PARSING alone, before any analysis
(`workspace.av:882-890`), so `avra test` on a package knows its case list
before a line of it or of its dependencies is typed.

**Discovery.** `root_files(ws)` is every `.av` under the ROOT package's `src`,
recursively (`workspace.av:739-741`) — so `src/tests/*_test.av` compiles for
`avra test packages/<pkg>` and for nothing else: a package that DEPENDS on
`@std/sqlite` never compiles `@std/sqlite`'s tests, because module files are
reached by `use`, and nothing `use`s `tests`. `CLAUDE.md:263` states the
placement rule: *every module has `spec`/`given`/`then` tests in `tests/`
beside it*.

## 2. What a `then` MAY contain

Pinned by `features/specs/tests/specs_test.av:110-133`:

- statements then a final bool expression — `let a = 2 … b == 4` (`:117`)
- an early `return true` (`:120`)
- calls to fns declared LATER in the file (`:114`) and in sibling modules (`:123`)
- anything else a fn body holds: `mut`, `while`, `for`, `match`, `defer`
  (a deferred cleanup inside a case is live in `std-io/src/tests/io_adversarial_test.av:57-60`)
- **calls to `extern fn`s.** `avra test` compiles the cases to LLVM and links
  a native binary (`packages/cli/src/commands/test.av:1-4, 33-43`); the link
  line carries `link_words(p.ws)` — every package's `[link]` promise
  (`packages/cli/src/commands/shared.av:275`,
  `packages/std-avrac/src/language/workspace.av:938-955`). **This is the
  campaign's single most important machinery fact: spec cases can call
  SQLite today, natively, with no interpreter change.**

## 3. What a `then` MAY NOT contain — the real limits

1. **No `?`.** A case promises `bool`, so a propagation refuses:
   *"`?` makes this fn answer the failure, but it promises a `bool`"*
   (`features/nullable/check.av:241`). This is not style — it is why EVERY
   suite in this tree hoists its work into named `Result`-answering helper
   fns above the spec block and lets the `then` compare one exact string
   (`std-process/src/tests/process_adversarial_test.av:40-190` is 25 such
   helpers feeding 35 one-line cases). **The sqlite suites must be written
   the same way from the first line.**
2. **No value on failure.** The native runner prints `    ✗ <label>` and
   nothing else (`language/test_run.av:160-166`). There is no
   expected-vs-actual, no diff, no assertion library. **A case's NAME is its
   entire diagnosis** — which is why every name in this tree reads as a
   sentence stating the claim.
3. **A trap kills the rest.** `avra_trap` names the running case and exits 2
   (`runtime/avra_runtime.c:449-459`); `verdict_of` maps any status but
   0/1/127 to `.Died` (`language/test_run.av:49-56`) and the runner prints
   *"STOPPED — the case or program named above trapped, and everything after
   it never ran"* (`commands/staged.av:44-47`). A segfault in a driver case
   is a trap. **One bad case masks every later case in the package.**
4. **No per-case isolation.** All of a package's cases run in declaration
   order in ONE process, one address space. A leaked connection in case 3 is
   still open in case 40.
5. **No hooks.** `given` carries no setup or teardown; a fixture is a fn the
   case calls.
6. **No parameterization, no properties, no snapshots.** Spec Axis 24.2 and
   24.3 specify `property` and `assert_snapshot` from a `@std/test` provider
   (`FULL_SPEC.md:4812-4888`); neither exists here.
7. **No filtering.** `avra test <path>` takes a package directory or ONE FILE
   (`commands/shared.av:113-134`). `--filter`, `--parallel`, `--watch`,
   `--coverage` (spec:4802-4807) do not exist.
8. **No expected-failure marker.** A `then` that must fail has nowhere to say so.

**DIVERGENCE FROM THE SPEC, flagged.** Axis 24.1 decides *(c) provider-supplied
via `@std/test` — registers `test` and `describe` keywords*
(`FULL_SPEC.md:4766`). This tree instead ships `spec`/`given`/`then` as a
compiler feature. The tree's shape is better for P10 (the compiler holds the
knowledge) and is what exists; the campaign follows the tree, and this
divergence is already the tree's, not the campaign's.

## 4. Fixtures, temp directories, cleanup

The convention, read from `std-io`'s two suites:

```avra
/// The scratch directory, made.
fn scratch() -> string {
    let dir = "${env_or("TMPDIR", "/tmp")}/avra-io-spec"
    let _ = make_dirs(dir)
    dir
}

/// A path under the scratch directory with nothing standing at it —
/// a directory left by an earlier run is emptied first.
fn fresh(name: string) -> string {
    let p = "${scratch()}/${name}"
    for n in list_dir(p) catch [] { let _ = remove("${p}/${n}") }
    let _ = remove(p)
    p
}
```
(`packages/std-io/src/tests/io_test.av:8-21`)

Four laws are visible in it:

1. **The temp root is `TMPDIR`, with `/tmp` as the fallback** — never a
   hard-coded path, never the tree.
2. **CLEANUP IS BEFORE, NOT AFTER.** `fresh` clears what an earlier run left,
   then answers the path. A crashed run leaves litter; the next run's fixture
   removes it. Nothing depends on a case having finished.
3. **Each suite owns its own root.** The adversarial suite uses `pit()` /
   `cleared()` under `avra-io-adversarial`
   (`std-io/src/tests/io_adversarial_test.av:10-24`) so the two suites cannot
   collide even when run in one process.
4. **A `defer` inside a case is legal cleanup** for the within-case half
   (`io_adversarial_test.av:57-60`).

Data fixtures are typed table literals — `table<Row> { … }` (DOGFOODING.md:653);
the diagnostics registry tests use exactly that shape
(`diagnostics/tests/render_test.av:6-13`).

## 5. Asserting a refusal — two different mechanisms

**(a) The COMPILER refuses (a diagnostic).** `@std/avrac`'s shared helpers,
`packages/std-avrac/src/testing/mod.av`:

| helper | line | what it asserts |
|---|---|---|
| `shown(source)` | `:7` | the program's printed value, or `"<refused>"` |
| `refusals(source)` | `:13` | how many diagnostics one program earns |
| `refused_with(source, phrase)` | `:22` | `diagnostics.length == 1` **AND** the report contains `phrase` |
| `refused_at_run(source, phrase)` | `:31` | analyzes CLEAN, then the RUN refuses saying `phrase` |
| `ir_of(source)` | `:41` | the program as IR, memory strategy applied |

`refused_with`'s doc states the law: *"The count is not optional here — one
mistake earns one message, so a refusal test that does not pin the count
cannot catch a cascade."*

**The ratchet enforces it.** `I20` and `I30` are TESTS_ONLY rules
(`tools/idioms.py:369-370`): a `then` whose block uses `.report().contains(`
with no count FAILS `make idioms` (`uncounted_refusal`, `idioms.py:123-131`);
`refusals(…) >= 1`, `diagnostics.length >= 1`, `voices.list.length >= 1` all
FAIL (`AT_LEAST_ONE`, `idioms.py:136-137`).

**(b) A LIBRARY refuses (a `Result`).** The suite writes a PROJECTION fn that
turns `Result<T, E>` into one exact string, and the case compares:

```avra
fn message(r: Result<string, IoError>) -> string {
    match r {
        .Ok(t) -> "ok: ${t}",
        .Err(e) -> e.describe().message,
    }
}
…
then "reading what is not there" {
    let p = fresh("nope.txt")
    message(read_text(p)) == "`${p}` does not exist"
}
```
(`std-io/src/tests/io_test.av:24-29, 82-85`)

`@std/process` generalizes it into a two-level projection — `kind(e)` turning
every error variant into `tag:payload`, and `shown(r)` folding ok and err into
one string (`process_adversarial_test.av:18-38`). **This is the shape the
sqlite suites take**: one `kind(SqliteError) -> string`, one
`shown(Result<T, SqliteError>) -> string`, and every case a one-line equality.

The variant question is asked with `is`:
`.Err(e) -> e is .NotFound` (`io_test.av:97-100`).

## 6. The corpus — `.av` beside `.expected`

`corpus/` holds 161 entries (`ls corpus | wc -l`), in three shapes.

**Shape 1 — a flat program.** `corpus/<name>.av` beside
`corpus/<name>.expected`. Run by `./avra corpus corpus` (`Makefile:100`),
which is ONE process: every program evaluated in turn against its
`.expected`, then ALL of them compiled into ONE binary whose entry runs each
under capture and compares again (`commands/corpus.av:1-8, 73-91`).
`corpus/` has NO `avra.toml`, so a flat program has no dependencies and no
`[link]` flags — builtins only.

**Shape 2 — a native-only program.** `corpus/native/*.av`, run by
`./avra corpus --native-only corpus/native` (`Makefile:101`) — the evaluator
is skipped because the programs are the host's (externs).
`corpus/native/externs.av` and `process_seam.av` are the two, and they are the
model for every SQLite corpus program: bare `extern fn` declarations, a small
projection fn, and a final interpolated string.

**Shape 3 — a package.** `corpus/<name>/avra.toml` + `src/main.av` +
`expected` (`corpus/io`, `corpus/json`, `corpus/cli`, `corpus/modules`).
The Makefile's loop (`Makefile:102-115`) runs EACH of these through
`./avra run` (the evaluator) AND `./avra build` + execute, diffing both
against `expected`, and prints `<dir>: eval == native == expected`.

**"eval == native" means exactly this**: the same source produces byte-identical
stdout under the tree-walking evaluator (`language/interp.av`) and under the
LLVM-compiled binary. `make native-check FILE=…` (`Makefile:143-148`) is the
one-file version.

**What a corpus program may print** (`CLAUDE.md:446-452`):
- its FINAL statement's expression, and only when that statement IS an
  expression. The law is `print_lowering` (`language/lower_walk.av:133-160`):
  `Str`, `Int`, `Bool` and `List<scalar>` project; a struct, enum, `Result`,
  `Opt`, `dyn`, `Fn`, `Ptr` or type name REFUSES with F0901 *"the program's
  answer is a `X`, which has no text projection yet"* (`:163-165`).
  `Map`, `Void` and `Error` print nothing and do not refuse.
- an interpolation hole prints **scalars and strings only** —
  `type.interp_hole`: *"an interpolation hole prints as a scalar or string,
  found `X`"* (`features/str_lit/check.av:1-13`). A list is shown through
  `join`, an index, or `length`.
- `println` may print extra lines BEFORE the answer (`corpus/io/src/main.av`
  prints eight lines then answers `"${exists(dir)}"`).
- **`.expected`'s final newline is dropped** before comparison
  (`commands/corpus.av:63-68`).
- A missing `.expected` is a refusal, not a skip (`commands/corpus.av:39-42`).

**THE SQLITE CONSEQUENCE, and it is a blocker — see BLOCKERS §B1.** A
package-shaped corpus entry is run under the EVALUATOR unconditionally
(`Makefile:105-107`). An sqlite program needs `[link] flags = ["-lsqlite3"]`
or vendored objects, which only a manifest can supply — and the only
manifest-bearing corpus shape is the package shape, which the evaluator must
run. `corpus/native/` skips the evaluator but has no manifest today.

## 7. The gates

```
gate: vocab idioms tested corpus          # Makefile:136
```

### `make vocab` (`Makefile:127`, `tools/vocab.sh`)

The IR vocabulary's guarantee AND its consumer registry. Eight dispatches are
named in the script itself:

| file | fn | decides |
|---|---|---|
| `core/ir.av` | `dst_of` | the register it defines |
| `language/interp.av` | `step` | its MEANING, interpreted |
| `language/memory.av` | `memory_ins` | its ownership effect |
| `language/ir_text.av` | `body_lines` | its human projection |
| `language/llvm.av` | `emit_ins` | its machine projection |
| `features/facts.av` | `give` | whether the runtime registry validates it |
| `core/ir.av` | `body_symbol` | the program body it names |
| `core/ir.av` | `hosted_symbol` | the hosted fn it calls |

The gate FAILS if any of them grows a `_ ->` catch-all — because the
exhaustive match IS the registration, and a catch-all would let the next
instruction ship unimplemented. `float` will add IR variants (`CLAUDE.md:349-372`
is the protocol); each one breaks all eight at compile time. That is the
design, not an obstacle.

### `make idioms` (`Makefile:119`, `tools/idioms.sh` → `tools/idioms.py`)

Four laws (`idioms.py:1-27`, DOGFOODING.md:37-49):

1. **The baseline LISTS SITES, never counts.** `tools/idioms.baseline` is
   currently five comment lines and **zero sites — the debt is ZERO**
   (DOGFOODING.md:88-91). A single new violation fails the gate; there is no
   amnesty left to hide in.
2. **No tool path adds to the baseline.** `--accept` only PRUNES sites that
   are gone (`idioms.py:648-653`).
3. **A license lives AT the site**: `// LICENSED I<n>: reason`, on the line or
   within two lines above (`idioms.py:574-579`).
4. **The registry may not outrun the ratchet**: every `I<n>` in DOGFOODING.md
   must have a matcher in `RULES` or an entry in `UNRATCHETED` with its
   reason, else the tool refuses to run (`idioms.py:633-640`).

Plus a self-test that would catch a dead rule: every matcher must catch every
one of its own SPECIMENS, and a repeated I-number is refused by reading the
tool's own source (`idioms.py:524-566`).

Ratcheted today: **I3 I4 I7 I9 I11 I12 I13 I14 I15 I16 I18 I19 I20 I21 I22
I23 I24 I26 I28 I30 I33 I35 I36** (`idioms.py:372-431`; DOGFOODING.md:61).

**THE SQLITE CONSEQUENCE.** `idioms.py`'s `SRC` list is hard-coded
(`idioms.py:30-33`) and does not include a package that does not exist yet.
**A new `packages/std-sqlite/src` is invisible to the ratchet until that list
grows** — the single-line edit is part of landing the package, and skipping it
means the driver is written outside the bar. Same for `Makefile:19`'s `SUITES`:
a package not listed there is never run by `make test`, so its suites are not
in the gate.

The rules that will bite the driver hardest:
- **I36** — `s = s + piece` in a loop is quadratic; a `@std/text` `builder()`
  is the spelling. A SQL builder is exactly this shape.
- **I22** — a match where TWO OR MORE variants answer is a REGISTRY and may
  not end in `_ ->`. Mapping SQLite's ~30 result codes to error variants is a
  registry: **every arm spelled**, `or`-runs keeping it affordable.
- **I20 / I30** — refusal tests pin the count.
- **I18** — a payload the dispatch GUARANTEES may not be read with
  `?? <plausible default>`. `column_blob(…) ?? empty` is both an I18 violation
  and the OOM bug the probe log's §2a names — **the ratchet and the semantics
  agree**.
- **I4** — a `mut x: T? = null` scan flag is a `find`/`any`.

### `make tested` (`Makefile:138-141`)

Scaffolds a throwaway feature (`avra new feature zz_probe`), runs `make test`
with it in the tree, removes it however the suites end (a `trap`). `make test`
(`Makefile:58-61`) runs `./avra test <p>` for each package in `SUITES`
(`Makefile:19`), stopping at the first red.

### `make corpus` (`Makefile:99-115`) — described in §6.

### Not in the gate

`make fuzz` (`tools/fuzz.sh`) — seven deterministic mutations of every flat
corpus program through `avra check`, which must DIAGNOSE (exit 0-2) and never
crash. Spawn-heavy, standalone; run after grammar or lexer work. **The float
lexer change is grammar work: fuzz is not optional for that slice.**

`make bench` (`tools/bench.sh`) — suite and corpus wall times. A curve, not a
gate; a 10x regression should be news.

`make scaffold-check` (`Makefile:161-169`).

## 8. `tools/watch.sh` — the watchdog and the machine-wide lock

`sh tools/watch.sh <cap_mb> <cmd…>` (`tools/watch.sh:1-30`):

- **The lock** is a directory in `/tmp/avra-build.lock`, so every worktree and
  every session queues on the same one. A waiting step names the holder. The
  lock dies with the step. A stale lock whose pid is gone is reclaimed
  (`:32-42`).
- **`./avra` takes this lock ITSELF** for any package-scale run — an argument
  that is a directory — so no path around it exists (`CLAUDE.md:688-692`).
  `AVRA_WATCH_HELD` makes a nested step run directly (`:29-31`).
- **The memory floor**: a step does not START while
  `kern.memorystatus_level` is under `AVRA_MEM_FLOOR` percent (default **20**)
  (`:45-50`).
- **The cap is 4000 MB by default** and every documented invocation passes
  `4000` explicitly (`ROADMAP.md:81-83`, `tools/integrate.sh:29`). A gate is
  ~0.3 GB honestly measured; the cap is a wreck-catcher.
- **The tripwire is RSS**, polled four times a second; the honest
  `footprint` — which counts pages the compressor holds, where RSS read a
  2.4 GB compiler as 1.4 GB — is read every fourth poll (`:88-100`).
- Exit status is the command's, or **137** when the cap fired (`:120-124`);
  the peak is always printed.
- `AVRA_SAMPLE=<seconds>` profiles under the lock, into `AVRA_SAMPLE_FILE`
  (`:62-66`).
- `AVRA_WATCH_TRACE=1` prints each poll's per-process footprint.

**The poll is not a wall.** A fast leak reached 16 GB between two footprint
polls before the kill (`CLAUDE.md:729-731`). Never run a suspect product over
a big input "to see".

## 9. `tools/integrate.sh` — landing a lane

`sh tools/integrate.sh <lane> <message-file>` (`tools/integrate.sh:1-20`), in
order:

1. Commit the lane's working tree with the message.
2. If main moved: rebase the lane onto main, `make bootstrap`, then the FULL
   gate on the rebased lane — both through the watchdog (`:36-42`).
3. **THE PRE-FLIGHT** (`:44-70`, the addition lane D's two slips forced):
   can MAIN's standing compiler READ the lane's tree?
   `sh tools/watch.sh 4000 "$main/build/avra" check "$worktree/packages/cli"`,
   with the binary NAMED absolutely — `../avra/avra` is a shim that cds to its
   own root and would check main's tree.
   - main reads it → normal merge.
   - main cannot, but the lane's own product can → main's compiler is BEHIND;
     it is seeded from the lane's product after the merge (`:81-85`).
   - **neither reads it → the tree is broken, not ahead: main is untouched and
     the run exits 1** (`:63-67`).
4. Merge with `--no-ff`, stashing and restoring any edits another session left
   on main's working tree (`:72-79`).
5. **THE FIXED POINT** (`:87-104`): `make avra` until two consecutive products
   are byte-identical, up to three builds — because main's standing binary may
   predate a CODEGEN change the lane carries (`CLAUDE.md:714-728`).
6. `make seed`, then `make bootstrap` from the refreshed seed, and
   `cmp` — the seed must CYCLE byte-identically or it is not a seed (`:105-109`).
7. Commit `bootstrap/seed.ll` (derived; never merged by hand).
8. Rebase the lane onto the new main and bootstrap it there (`:117-121`).

## 10. Golden and diagnostic tests

**A diagnostic's rendering is pinned by an exact-string comparison inside a
`then`.** `packages/std-avrac/src/diagnostics/tests/render_test.av:1-2`:
*"Golden renderings: the human text is a contract. Every code's shape is
asserted EXACTLY — a drifted gutter or caret fails here."* The mechanism is a
triple-quoted literal:

```avra
then "the rendering is exact — header, window, pointer, help" {
    let at = Loc { file: "app.av", lo: 14, hi: 15 }
    let d = error_at("parse.expected", at, "expected NAME while parsing `stmt`")
        with { primary: Frame { label: "expected NAME", loc: at }, help: "a `let` names its value" }
    let expected = """error[F0100]: expected NAME while parsing `stmt`
  ╭─[app.av:2:5]
2 │ let = 3
  ·     ┬
  ·     ╰── expected NAME
──╯
help: a `let` names its value"""
    render(d, rendered_registry(), two_lines()) == expected
}
```
(`render_test.av:33-47`)

The same triple-quoted-golden shape pins the IR (`render_ir(ir_of(source)) == expected`,
`language/tests/lower_test.av:255-284`) and the whole end-to-end parse
rendering (`language/tests/language_test.av:58-60`).

**The F-code registry.** A diagnostic names a KIND (a dotted string); the
F-code is the registry's PROJECTION of that kind
(`diagnostics/mod.av:29-36`).

- **Built-in codes** live in `language/codes.av`: `engine_codes()`
  (`:16-24`, five engine causes: F0001, F0100, F0101, F0102, F0900) and
  `pass_codes()` (`:26-42`, the driver's own passes: F3000, F3001, F3002,
  F0901, F0902, F2014, F3007, F3008, F3010, F3020).
- **A feature's codes** are a `table<DiagCode> { kind | id | summary }` in its
  `mod.av`, handed to the component as `diags = codes`
  (e.g. `features/specs/mod.av:20-25`).
- **Assembly gathers them**: `code_registry(features)` is
  `builtin_codes()` plus every feature's rows in feature order
  (`language/mod.av:112-115`).
- **A duplicate kind OR a duplicate F-code refuses ASSEMBLY** —
  `code_defects` (`features/coherence.av:97-111`), pinned by
  `language/tests/language_test.av:47-56` with the exact defect messages.
- **An unregistered kind is a loud defect**: `netted` appends
  *"`<kind>`: diagnostic kind is not registered"* (`language/codes.av:72-79`),
  and `render` falls back to printing the kind itself
  (`diagnostics/render.av:59-60`), pinned at `render_test.av:63-66`.
- **`avra explain <F-code|kind>`** reads the same registry
  (`commands/explain.av:19`), which is why an F-code is API and may never be
  reused.

**HOW A NEW DIAGNOSTIC KIND IS REGISTERED — the exact recipe.**

1. Pick a dotted kind in the owning feature's namespace
   (`type.*`, `resolve.*`, `lower.*`, `manifest.*`).
2. Add a row to that feature's `diags` table in `mod.av`:
   `"type.<name>" | "F20NN" | "<one-line meaning for avra explain>"`.
3. Take the **NEXT FREE NUMBER**. In use today (greped from
   `packages/std-avrac/src`): F0001, F0100-F0102, F0900-F0902,
   F2000-F2055 (F2002 and F2018 unused), F3000-F3025, F4000-F4014,
   F4020, F4030-F4031. **Next free: F2056 (typing), F3026 (resolve),
   F0903 (lowering), F0103 (parse).** A collision refuses assembly, so the
   mistake is loud — but it refuses the WHOLE language, not one test.
4. Write the voice as a NAMED VOICE FN whose whole body is the one
   `refusal(kind, at, message, label, help)` call, in a voices section at the
   file's tail (`CLAUDE.md:73-77`; I28 ratchets `pointed(error_at(` as the
   hand-assembled shape).
5. Add a `then` asserting it with `refused_with(source, phrase)` — the count
   is not optional (I20/I30).
6. Add a golden rendering `then` where the shape is new.
7. `make gate`.

## 11. The commands a lane runs, in order

```sh
# ONCE, cold worktree
git worktree add ../avra-lane-sqlite -b lane/sqlite      # already done
sh tools/watch.sh 4000 make bootstrap                    # ~45s from the seed

# THE INNER LOOP — a scratch probe is sub-second and needs no lock
./avra check scratch/probe.av

# ONE SUITE (a package-scale run; ./avra takes the lock itself)
sh tools/watch.sh 4000 ./avra test packages/std-sqlite

# ONE CORPUS PROGRAM, both engines
sh tools/watch.sh 4000 make native-check FILE=corpus/native/sqlite_seam.av

# THE BAR, before any "done"
sh tools/watch.sh 4000 make gate                         # vocab idioms tested corpus

# AFTER GRAMMAR OR LEXER WORK (the float literal)
sh tools/watch.sh 4000 make fuzz

# MEMORY QUESTIONS — measured, never reasoned
AVRA_MEM_STATS=1 sh tools/watch.sh 4000 ./avra check packages/std-sqlite
AVRA_RC_GUARD=1 ./avra run scratch/small.av             # SMALL PROGRAMS ONLY

# PROFILE, under the lock
AVRA_SAMPLE=12 sh tools/watch.sh 4000 ./avra test packages/std-sqlite

# LANDING
sh tools/integrate.sh sqlite /tmp/lane-sqlite-msg.txt
```

Never a bare `make gate`. Never a background one. Never `build/avra`
directly. One heavy step at a time, machine-wide (`CLAUDE.md:682-712`).

---

# PART II — THE TEST PLAN FOR @std/sqlite

## 1. THE PYRAMID

Five tiers. The tier is decided by ONE question: **what does this case need in
order to be deterministic?**

### Tier 0 — COMPILER SUITES: the language features, before the driver exists

These live in the compiler's own tree and use `refused_with` / `shown` /
`ir_of`. They are written FIRST because the driver cannot be written past an
open gap (`ROADMAP.md:1516-1520`).

| suite | file | pins |
|---|---|---|
| `features/floats` | `packages/std-avrac/src/features/floats/tests/floats_test.av` | the literal lexes, `float` names a type, arithmetic, comparison ORDERED not signed, the text projection round-trips, `int`↔`float` conversions refuse or convert explicitly, NaN/±Inf/−0.0 |
| `features/decimals` | `.../decimals/tests/decimals_test.av` | exact base-10 arithmetic, no binary rounding, the money cases, the projection |
| `features/bytes` | `.../bytes/tests/bytes_test.av` | `Bytes` names a type; `==` is byte-wise **past a NUL**; `.length` is the header's; empty and absent are distinguishable; `Bytes` ↔ `string` conversions are explicit |
| `features/fns` (grown) | `.../fns/tests/fns_test.av` | `extern fn f(mut p: ptr)` parses; a `mut` extern seat passes the caller's slot address; F2051 still warns on an unwritten `mut` seat |
| `features/opaque` | `.../opaque/tests/opaque_test.av` | `opaque type Db` declares; a value of it has no fields; `@free_with` drops it at scope end exactly once; a moved handle is not double-dropped |
| `features/fns` (annotations) | `.../fns/tests/extern_ownership_test.av` | `@returns_borrowed` refuses a `-> string` extern; `@takes_ownership` / `@returns_ownership` change the memory pass's release placement — asserted with `ir_of` and a release COUNT |
| `language/interp` (extern host) | `.../language/tests/interp_extern_test.av` | `avra run` hosts an extern through dlsym; a symbol that does not resolve refuses in words; each uniform ABI shape round-trips |
| `diagnostics/render` | existing `render_test.av` | the golden rendering of every NEW F-code |

Every one of these is `refused_with(source, phrase)` or `shown(source) == "…"`
over a source STRING — no file, no database, no host. They are the fastest
tests in the campaign and they are where the language is actually specified.

### Tier 1 — UNIT, no database at all

Pure projections over data the driver owns. `packages/std-sqlite/src/tests/sqlite_test.av`.

- **The error registry**: every SQLite result code → its `SqliteError`
  variant → its message. A table-driven case per family, and one case
  asserting the registry is TOTAL (an unknown code maps to a named
  `.Unknown(code)` variant, never a default).
- **The extended result codes**: `SQLITE_CONSTRAINT_UNIQUE` (2067) and
  `SQLITE_CONSTRAINT` (19) are DIFFERENT and both must map.
- **Open-flag composition**: `Open.ReadOnly`, `.ReadWrite`, `.Create` compose
  to the exact integers 1, 2, 6 …; a flag set the C API refuses is refused
  BEFORE the call.
- **SQL text building** where the driver builds any (`@std/text` `builder()`,
  never `s = s + piece` — I36).
- **Storage-class ↔ Avra-type mapping**: the five classes to the five reads,
  and the refusal for a mismatch.
- **Value projections**: `SqlValue.Text("x").to_string()` and friends.

### Tier 2 — A DATABASE, no file: `:memory:`

`packages/std-sqlite/src/tests/sqlite_memory_test.av`. Most of the driver
lives here. An in-memory database is created and destroyed with the
connection: no path, no cleanup, no cross-run state, no TMPDIR.

- open / close / handle lifecycle
- prepare / bind / step / column / reset / finalize
- every bind type and every column type, both ways
- NULL in every slot
- the transaction verbs (BEGIN / COMMIT / ROLLBACK, and the `tx(() -> …)`
  scoped form the probe log §5 proves is expressible)
- `changes()`, `total_changes()`, `last_insert_rowid()`
- multi-statement prepare and the tail pointer
- named parameters, `?NNN`, `:name`, `@name`, `$name`
- `sqlite3_limit` lowered, then the refusal at the lowered limit (see §2.6)

### Tier 3 — A REAL FILE

`packages/std-sqlite/src/tests/sqlite_file_test.av`, with the `scratch()` /
`fresh()` fixture pattern copied verbatim from `io_test.av:8-21` and its own
root `${TMPDIR}/avra-sqlite-spec`.

Everything memory cannot express:
- **WAL** — `PRAGMA journal_mode=WAL` answers `"wal"` only for a file-backed
  database; the `-wal` and `-shm` siblings appear; a checkpoint truncates them
- **BUSY** — two connections on the same file (see §2.3)
- **read-only file**, **a directory where a file belongs**, **a file that is
  not a database**, **a corrupted page**
- **persistence** — a value written, the connection closed, reopened, read back
- **backup / serialize / deserialize**
- **VACUUM** and `PRAGMA integrity_check`

### Tier 4 — A REAL SCHEMA

`packages/std-sqlite/src/tests/sqlite_schema_test.av`. A fixture schema
created once per case (in memory, so it cannot leak between cases), exercising
what a driver's users hit and an ORM will need:
- foreign keys ON, a violation refused with `SQLITE_CONSTRAINT_FOREIGNKEY`
- UNIQUE, NOT NULL, CHECK — each with its own extended code
- INTEGER PRIMARY KEY vs rowid vs WITHOUT ROWID
- column metadata (`sqlite3_column_decltype`, `_database_name`,
  `_table_name`, `_origin_name`) — **the vendored build is what makes these
  exist at all** (`SQLITE_ENABLE_COLUMN_METADATA`)
- views, triggers, generated columns
- a JOIN whose result columns collide by name

### Tier 5 — ADVERSARIAL

`packages/std-sqlite/src/tests/sqlite_adversarial_test.av`, its own scratch
root `${TMPDIR}/avra-sqlite-adversarial`, following
`io_adversarial_test.av` and `process_adversarial_test.av`. Part II §3 is its
contents.

### And the CORPUS, which is a different axis

Two entries, both proving end-to-end what a suite cannot:

- `corpus/native/sqlite_seam.av` + `.expected` — the raw extern seam, bare
  `extern fn sqlite3_*`, native only (blocked on the link-flag problem —
  BLOCKERS §B1).
- `corpus/sqlite/` (package-shaped, `avra.toml` + `src/main.av` + `expected`)
  — the driver used as a user uses it, proving **eval == native == expected**.
  This one lands the day the interpreter's extern host lands, and **it is the
  proof that the extern host works** — no other test in the tree can be.

## 2. THE HARD PART — MAKING A DRIVER DETERMINISTIC

### 2.1 In-memory first, files only where a file is the subject

`:memory:` gives a fresh, empty, private database per connection with no path,
no cleanup, and no cross-run state. **Default to it.** A case that uses a file
must be able to say WHY in its own name: WAL, locking, persistence, corruption,
permissions.

Do **not** reach for `file::memory:?cache=shared` to get two connections onto
one in-memory database. Shared cache changes the locking model — table-level
locks instead of file-level — so a BUSY test written on it is testing a
different mechanism from the one users hit. (MEDIUM-HIGH: SQLite documentation;
not probed.)

### 2.2 Temp files and cleanup

Copy the io fixture exactly, and extend it for the three siblings SQLite makes:

```avra
/// A database path under the scratch root with nothing standing at it —
/// the journal, the wal and the shm an earlier run left are removed too.
fn fresh_db(name: string) -> string {
    let p = "${scratch()}/${name}"
    for suffix in ["", "-journal", "-wal", "-shm"] { let _ = remove("${p}${suffix}") }
    p
}
```

Cleanup is BEFORE, never after — a trapping case never runs its `defer`, and
the next run must still start clean.

### 2.3 SQLITE_BUSY without a race

**The deterministic recipe, no threads, no sleeps, no timing:**

1. Open connection A and connection B on the SAME temp file.
2. `sqlite3_busy_timeout(B, 0)` — B never waits. **This is what removes the
   race**: with a non-zero timeout the outcome depends on the clock.
3. On A: `BEGIN IMMEDIATE` — this takes the RESERVED write lock at once,
   rather than deferring it to the first write.
4. On B: any write (`INSERT`, or `BEGIN IMMEDIATE`). It returns
   `SQLITE_BUSY` (5) **on the first try, every time**.
5. Assert the code, the message, and — the case that actually matters — that
   the driver's `SqliteError` carries `.Busy` and not a generic `.Failed`.
6. `ROLLBACK` on A; the same write on B now succeeds. **Assert that too**:
   a BUSY that is not recoverable is a different bug from a BUSY that is not
   raised.

A second case with `busy_timeout(B, 50)` asserts the timeout is honoured —
but assert only that it EVENTUALLY refuses with `.Busy`, never how long it
took. **A test that asserts a duration is a test that fails on a loaded
machine**, and this machine is shared with a loaded desktop.

Confidence: HIGH on the mechanism (`BEGIN IMMEDIATE` takes RESERVED
immediately; `busy_timeout(0)` disables the handler — SQLite documentation).
Not probed here; probe it in the first slice.

### 2.4 WAL

`PRAGMA journal_mode=WAL` returns a row whose one text column is `"wal"` —
**read the returned row; do not assume the pragma succeeded.** On a
`:memory:` database it answers `"memory"` and the mode does NOT change; that
refusal is itself a case.

Pin:
- the returned mode text
- `is_file("${p}-wal")` after a write (the sibling exists)
- a second connection reads a committed row while the first holds a read
  transaction (WAL's readers-do-not-block-writers property)
- `PRAGMA wal_checkpoint(TRUNCATE)` returns three integers and the `-wal`
  file shrinks
- closing the last connection removes `-wal` and `-shm`
- reopening the file after a WAL write reads the data back

### 2.5 A BLOB that survives byte for byte

This is the campaign's central correctness claim and it needs THREE tests,
not one, because the tree's own history says the empty case is where an
encoding loses information (probe log §2b).

1. **The NUL case.** A blob whose bytes are `61 00 62` — write it, read it
   back, assert `length == 3` AND `byte_at(0) == 0x61 && byte_at(1) == 0x00 &&
   byte_at(2) == 0x62`. **Length alone is not the assertion** —
   `io_adversarial_test.av:139-145` makes exactly this distinction (*"the byte
   survives in the middle, not just the count"*) and it is the shape to copy.
2. **The empty case, FIRST not last.** A zero-length blob is
   indistinguishable from SQL NULL through `sqlite3_column_blob`, which
   returns NULL for BOTH (and for OOM — probe log §2a, `sqlite3.h:5519-5525`).
   Pin: an empty blob round-trips as an empty `Bytes`, is `!= null`, and its
   `column_type` is `SQLITE_BLOB` (4) and not `SQLITE_NULL` (5). **The test
   that proves the driver asks `column_type` FIRST.**
3. **The full-range case.** All 256 byte values, in order, round-tripped;
   then the same bytes compared with `==` — which is what a `Bytes` type
   exists to make honest, because `string`'s `==` is `strcmp`
   (`runtime/avra_runtime.c:475-478`) and truncates at the NUL.
4. **The big case, cheaply.** `SELECT zeroblob(1000000)` makes a megabyte
   without a megabyte of Avra literal. Assert the length and a sampled byte.

### 2.6 The 1 GB limit, without allocating 1 GB

`SQLITE_LIMIT_LENGTH` defaults to 1,000,000,000 bytes. **Do not test at the
default** — the machine rule forbids it and a 1 GB allocation under the
watchdog's 4000 MB cap is a wreck waiting for a poll.

`sqlite3_limit(db, SQLITE_LIMIT_LENGTH, 1024)` lowers it, the call ANSWERS
the previous limit, and a 2000-byte blob then refuses with `SQLITE_TOOBIG`
(18) — deterministically, in microseconds. Restore the limit and assert the
same blob succeeds. **This is the pattern for every "at the limit" case**:
`SQLITE_LIMIT_SQL_LENGTH`, `_COLUMN`, `_EXPR_DEPTH`, `_COMPOUND_SELECT`,
`_VARIABLE_NUMBER`, `_LIKE_PATTERN_LENGTH`, `_ATTACHED`.

### 2.7 PROVING the copy — that a returned pointer is not aliased

`sqlite3_column_text` and `_blob` answer a pointer into the statement's own
buffer, invalidated by the next `step`, `reset`, `finalize`, or a type
conversion on the same column. If the driver hands that pointer to Avra
without copying, the value silently rots. `AVRA_RC_GUARD` **cannot see this**:
the guard watches retain/release events and an untagged foreign pointer raises
none (probe log §6, `runtime/avra_runtime.c:363-379`). So the copy must be
proved by CONSTRUCTION, three ways:

1. **THE MUTATION TEST — the direct proof.**
   `SELECT 'first' UNION ALL SELECT 'second'` (or a two-row table).
   - step → row 1 → read column 0 into a local `a`
   - step → row 2 → read column 0 into a local `b`
   - **assert `a == "first"` AND `b == "second"` AFTER both steps.**
   If the value aliased the statement buffer, `a` would read `"second"`, or
   garbage. This is deterministic because SQLite reuses that buffer for the
   next row's value — it is not a hope, it is the documented lifetime.
2. **THE SURVIVE-FINALIZE TEST.**
   Read a value, `finalize` the statement, THEN assert the value.
   With the amalgamation compiled with `SQLITE_MEMDEBUG` this is a hard
   fault; without it it is a silent stale read. Run this ONE case under
   `AVRA_RC_GUARD=1` too — the guard cannot see the foreign pointer, but it
   CAN see a double-release of the box the copy made.
3. **THE POISON TEST — the strongest, and cheap.**
   After reading a text value and before asserting it, run
   `SELECT hex(randomblob(4096))` on the same connection — which churns the
   same allocator. A held alias reads churn; a copy reads what it copied.
   This makes the failure LOUD rather than lucky.

Name them so a failure diagnoses itself, because a failing `then` prints only
its name:
- `then "a text column read from row one still says row one after row two is stepped"`
- `then "a text value outlives the statement that produced it"`
- `then "a value read then followed by unrelated allocation is unchanged"`

### 2.8 Refcount correctness

`AVRA_RC_GUARD=1` keeps a released box, marks it dead, and traps at the next
read; a second release reports the box's whole history
(`runtime/avra_runtime.c:354-411`). It is bounded but expensive — **small
programs only** (`CLAUDE.md:708-710`).

So the guarded artifact is NOT the suite. It is a set of **three or four tiny
scratch programs**, each 20 lines, each exercising one ownership seam, run by
hand and recorded in the probe log:

- `scratch/rc_open_close.av` — open, close, in a loop of 100. No growth.
- `scratch/rc_row_text.av` — 1000 rows of text read into locals that die each
  turn. **THE CONDITION RUNS EVERY TURN** (`CLAUDE.md:566-577`): a `while
  sqlite3_step(s) == 100` condition that MINTS a value settles inside the
  loop, and a release placed after the loop leaks every other turn — the exact
  bug that cost 9 s and 17.5 GB for 60k pushes. **A driver's row loop is that
  shape.** This program is the one that catches it.
- `scratch/rc_blob.av` — a `Bytes` per row, dropped per turn.
- `scratch/rc_error_path.av` — a failing prepare in a loop; the error message
  is a copy and is released.

And the whole-package instrument for hoards is
`AVRA_MEM_STATS=1 ./avra check packages/std-sqlite` — live bytes by category,
by list capacity, and by the allocation site that made them, with
`atos -o build/avra <addr>` naming it (`CLAUDE.md:696-703`).
**PROFILE, DON'T REASON**: the first hoard the accounting named was a refcount
leak no reading had found.

### 2.9 An error's message is the right one

Three separate claims, three separate cases, because they fail independently:

1. **The CODE is right.** `SQLITE_CONSTRAINT_UNIQUE` (2067), not
   `SQLITE_CONSTRAINT` (19), not `SQLITE_ERROR` (1).
2. **The VARIANT is right.** The driver's `SqliteError` carries `.Constraint`
   with the extended detail — asserted with `is`, the tree's spelling
   (`e is .Constraint`).
3. **The TEXT is right, exactly.** `sqlite3_errmsg` answers a message valid
   only until the next API call on that connection — **so the driver COPIES it
   at the boundary, and the test proves that**: raise the error, then run an
   unrelated statement, THEN assert the message. Same three-part shape as §2.7.

And the fourth, which the whole tree treats as first-class: **the driver's own
refusals name their subject**. `@std/io`'s cases assert
``"`${p}` does not exist"`` with the path interpolated
(`io_test.av:82-85`). `@std/sqlite`'s must assert the SQL, the parameter
index, the column name — whatever the user needs to fix it.

### 2.10 Two engines, one answer

For everything the interpreter can host, `make native-check FILE=…` proves
eval == native on one file, and the corpus proves it for the set. Until the
extern host lands, **no sqlite code has an eval half at all** — which is the
strongest argument for landing the extern host early rather than last
(see §4).

## 3. THE RED-TEAM CATALOGUE

Forty-nine cases, written as the `then` names they will carry. Grouped by
`given`, in the shape `sqlite_adversarial_test.av` will take. Names are the
whole diagnosis, so each states its claim.

### given "handles at their edges"

1. `then "a connection to a path that cannot be created refuses with the path in its words"`
2. `then "a database opened read-only refuses a write, and the read still works"`
3. `then "a directory where a database belongs is CANTOPEN, not a trap"`
4. `then "a file that is not a database is NOTADB, and the file is left as it was"`
5. `then "a database whose first page is scribbled is CORRUPT, named as corruption"`
6. `then "closing a connection with a live statement is refused, and the connection still works"`
   — `sqlite3_close` answers `SQLITE_BUSY` while a statement is unfinalized;
   `sqlite3_close_v2` marks it a zombie and closes when the last statement
   finalizes. **The driver must pick one and the test must pin WHICH.**
7. `then "a second close of the same connection is refused by the type, not by the runtime"`
   — a double-close is undefined behaviour in C. It must be UNREPRESENTABLE.
   This is therefore a Tier-0 COMPILER case (`refused_with`), not a runtime
   case: the `opaque type` + `@free_with` drop must make a closed handle
   unnameable.
8. `then "a statement used after finalize is refused by the type, not by the runtime"`
   — same law, same tier. **A driver that can only catch these at runtime has
   the wrong API.**
9. `then "opening the same file twice gives two connections that see each other's commits"`
10. `then "an interrupted step answers INTERRUPT and the statement resets clean"`

### given "parameters"

11. `then "binding index zero is out of range, named as the index"`
12. `then "binding one past the parameter count is out of range, named as the count"`
13. `then "a negative bind index is out of range, never a wrap"`
14. `then "a parameter never bound reads as NULL, not as a refusal"`
15. `then "a named parameter bound by the wrong name refuses, naming both names"`
16. `then "the same parameter bound twice keeps the second value"`
17. `then "a bind after step and before reset is refused, saying reset first"`
18. `then "SQL injected through a bound parameter is inert — the row count is one, and the table still stands"`
    — bind `"'; DROP TABLE t; --"` as a value; assert the row holds that
    literal text and `t` still exists. `@std/process`'s
    `hostile_words` case is this test's sibling
    (`process_adversarial_test.av:135-138`).

### given "columns"

19. `then "a query returning zero columns steps to DONE and answers no columns"`
    — `CREATE TABLE`, `INSERT`: `column_count` is 0, `step` is `SQLITE_DONE`.
20. `then "an empty statement prepares to nothing, not to a statement"`
    — whitespace-only SQL: `SQLITE_OK` with a NULL statement pointer, which
    the niche reads as `null` (probe log §2).
21. `then "a column index past the count is refused, not read"`
22. `then "an INTEGER column read as text converts, and the driver says it converted"`
23. `then "a TEXT column read as an integer is zero, and the driver refuses rather than lying"`
24. `then "a NULL column is absent in every read, and column_type says NULL"`
25. `then "an empty blob is a blob, not a NULL and not an absence"`
    — the probe log's §2a law, made a test.
26. `then "a text value holding a NUL comes back whole, bytes and length both"`
27. `then "invalid UTF-8 bound as text comes back byte for byte"`
    — SQLite stores the bytes; the driver must not "fix" them.
    (MEDIUM: pin what actually happens rather than what is expected.)
28. `then "two joined columns with the same name are told apart by index"`
29. `then "reading a column twice gives the same value both times"`
    — the alias test of §2.7, in its simplest form.

### given "values at their limits"

30. `then "a blob at the lowered length limit is accepted and one byte past it is TOOBIG"`
31. `then "the largest and smallest integers round-trip exactly"`
    — `9223372036854775807` and `-9223372036854775808`.
32. `then "a NaN bound to a REAL column stores as NULL"`
    — **SQLite converts NaN to NULL on bind.** Pin what the engine does, not
    what feels right. (MEDIUM: documented behaviour, not probed.)
33. `then "positive and negative infinity round-trip as themselves"`
34. `then "negative zero is negative zero coming back"`
35. `then "a REAL that is exactly an integer stays REAL, not INTEGER"`

### given "SQL the parser refuses"

36. `then "a syntax error names the offending token and the byte offset"`
37. `then "an expression nested past the depth limit refuses, not crashes"`
    — lower `SQLITE_LIMIT_EXPR_DEPTH` first (§2.6) so the case is cheap.
38. `then "a recursive CTE without a termination is stopped by the limit, not by the machine"`
    — `LIMIT` in the CTE, or `sqlite3_interrupt` after N steps. **Never an
    unbounded recursion under the watchdog.**
39. `then "a statement with a tail prepares the first and names where the rest begins"`
40. `then "sixty-four nested subqueries prepare and step"`
    — the affirmative twin of 37, proving the limit is a LIMIT and not a low
    ceiling.

### given "transactions and locking"

41. `then "a write under another connection's IMMEDIATE transaction is BUSY at once with busy_timeout zero"`
42. `then "the same write succeeds after the holder rolls back"`
43. `then "a rollback undoes every statement of the transaction, counted"`
44. `then "a failing statement inside a scoped transaction rolls it back, and the error is the statement's not the rollback's"`
45. `then "a nested savepoint releases without touching the outer transaction"`
46. `then "a constraint violation names which constraint, by its extended code"`

### given "the frames" — the campaign's OWN traps, from the probe log

47. `then "an errcode read after a suspect NULL is the connection's, with a deferred cleanup standing in the frame"`
    — probe log §2b's specified test, made concrete. A frame holding
    `defer { stmt.reset() }`, a NULL read, a `?` between the read and the
    check. It fails the moment the `defer` is in place.
48. `then "a thousand rows read in a while loop leave no live bytes behind"`
    — the loop-condition memory law (`CLAUDE.md:566-577`), asserted by the
    runtime's own accounting rather than by a feeling.
49. `then "an extern answering foreign text is refused by the compiler"`
    — Tier 0. `extern fn sqlite3_libversion() -> string` must STOP compiling
    once `@returns_borrowed` lands; today it compiles and is wrong by accident
    (probe log §6). **The best test in this catalogue, because it turns an
    accident into a law.**

## 4. THE TDD ORDER

### The principle

The campaign's rule is the ROADMAP's (`:1516-1520`): *a gap in the language or
the stdlib is not papered over — it is recorded and CLOSED, and only then is
the driver written past it.* So the red-to-green sequence is **not** driver
features. It is LANGUAGE features, each forced into existence by a test that
cannot be made green any other way.

Two ordering constraints decide everything else:

- **A commit that adds a COMPILER FEATURE leaves the tree compilable by
  main's current compiler**; the compiler's own uses of the feature land in
  the NEXT commit, once the seed carries it (`ROADMAP.md:88-92` — lane D
  slipped on this twice).
- **A codegen fix reaches the product on the SECOND build** (`CLAUDE.md:714-728`).
  Every slice that touches the memory pass or the backend builds twice before
  its peak is trusted.

### THE FIRST FAILING TEST

```avra
// packages/std-avrac/src/features/fns/tests/extern_ownership_test.av
spec "features/fns — the foreign wall" {
    given "text that is not ours" {
        then "an extern answering `string` is refused — foreign text has no header" {
            refused_with("extern fn sqlite3_libversion() -> string\nsqlite3_libversion().length",
                         "an extern answers `ptr` for foreign text — a `string` must carry our header")
        }
    }
}
```

**Why this one first.** It is red today for the WORST possible reason: the
program it refuses **compiles and appears to work** (probe log §6 —
`3.51.0`, `.length` 6, `==` true) while hiding three wrongs the driver is made
of, and `AVRA_RC_GUARD` prints clean on it by construction. It is the only
test in the campaign that turns a silent accident into a compiler law, it
needs no database, no file, no float, no bytes, and it costs one diagnostic
kind plus one check. **Landing it means no line of the driver can ever be
written wrong in that way.**

It forces into existence:
- one new F-code (F2056, the next free) + its registry row in
  `features/fns/mod.av`'s `diags` table
- one named voice fn in `features/fns/check.av`
- the first FFI annotation vocabulary decision — because the refusal must
  name the escape hatch (`@returns_borrowed`), and P8 says an escape hatch
  must exist
- a golden rendering case in `render_test.av`

### THE FIRST FIVE, in order

**1. `then "an extern answering \`string\` is refused — foreign text has no header"`**
→ forces: the diagnostic kind, the F-code, the voice, and the DECISION that
the foreign wall answers `ptr`. Tier 0. No dependencies.
Green when: `make gate`, and the seven existing `-> string` externs in the
tree still compile (they are backed by real headered boxes — probe log's
audit — so they must pass through whatever exemption the law carries; that
exemption is `@returns_borrowed` or an allowlist of our own runtime symbols,
and **which one it is, is decided by this test**).

**2. `then "a Bytes holding a NUL is not equal to its prefix"`**
```avra
shown("let a: Bytes = bytes([97, 0, 98])\nlet b: Bytes = bytes([97])\n\"${a == b} ${a.length}\"") == "false 3"
```
→ forces: the `Bytes` core value category — the type, the literal or
constructor, byte-wise `==` (not `strcmp`), `.length` from the header (not
`strlen`), and the empty/absent distinction the niche rule threatens (probe
log §2a's closing note). This is a CORE event: `core/types.av`, the value
protocol (`truth_of`/`text_of`/`elems_of` gain a sibling), the IR, the
backend, the interpreter's `Val`, and a text projection. Tier 0.
Green when: `make gate` + `make fuzz` (a new literal shape is lexer work).
**Bytes before float**, because BLOB round-tripping is the driver's
correctness core while REAL is one of five storage classes.

**3. `then "a mut seat on an extern hands the callee the caller's slot"`**
```avra
shown("extern fn avra_out_probe(mut p: int) -> int\nmut v = 0\nlet r = avra_out_probe(v)\n\"${r} ${v}\"") == "0 42"
```
(with a tiny `avra_out_probe` added to the runtime as the test's own witness,
which is legitimate — it is OUR C, not a shim over sqlite)
→ forces: the out-param. The syntactic half is aligning
`features/fns/mod.av:32` with `:33` — the extern rule is a narrower copy of
the fn rule, lacking `( mk:"mut" )?` (probe log Part II). The semantic half is
what `mut` MEANS across the C boundary. **Without this, `sqlite3_open_v2` and
`sqlite3_prepare_v2` cannot be called at all, and no workaround exists**
(the `List<int>` hack hands C the `AvraArray` whose first field is the
capacity — `ROADMAP.md:1584-1590`). Tier 0.
Also decide here whether P6's collapse applies: a C fn answering a STATUS and
writing a HANDLE **is** a `Result`. If the compiler projects
`(status, mut out T)` to `Result<T, E>` at the declaration, every C library
loses its wrapper layer, not just this one.

**4. `then "sqlite says its version through the seam, natively"`**
`corpus/native/sqlite_seam.av` + `.expected`:
```avra
extern fn sqlite3_libversion_number() -> int
"${sqlite3_libversion_number() > 3000000}"
```
→ forces: **the vendoring**, which is the first non-language deliverable —
the amalgamation in the tree, the `[link] objects`/`flags` row that names it,
the build flags (`SQLITE_ENABLE_COLUMN_METADATA`, `DESERIALIZE`, `SESSION`,
`FTS5`, `RTREE`, `SQLITE_DQS=0`, `SQLITE_THREADSAFE=…`), and **the corpus
link-flag hole in BLOCKERS §B1**, which this test is what discovers.
Green when: `make corpus` is green with the new entry.
This is the first test whose green means "SQLite is in the tree".

**5. `then "a connection opened in memory answers its own handle, and closing it is the last word"`**
`packages/std-sqlite/src/tests/sqlite_test.av`, the driver's first suite:
```avra
fn opened() -> Result<string, SqliteError> {
    let db = open(":memory:")?
    let v = "${db.is_open()}"
    "${v}/${close(db)}"
}
then "a connection opened in memory answers its own handle, and closing it is the last word" {
    shown(opened()) == "true/closed"
}
```
→ forces: `packages/std-sqlite/` into existence — the manifest with its
`[link]` row and `[dependencies]`, `Makefile:19`'s `SUITES` gaining the
package, `tools/idioms.py:30`'s `SRC` gaining `packages/std-sqlite/src`, the
`SqliteError` enum and its total code registry (I22: **every arm spelled**),
the `open`/`close` pair, and the `opaque type Db @free_with(sqlite3_close_v2)`
decision — because case 7 of the red-team catalogue (double close) can only
be answered by the type.
Green when: `sh tools/watch.sh 4000 ./avra test packages/std-sqlite` is green
and `make gate` is green with the package in SUITES.

### After the first five

- **6.** `float` — the second CORE event (lexer literal, `core/types.av`, the
  value protocol, the IR's fadd/fcmp **ordered not signed**, the backend, the
  interpreter's `Val`, and a round-tripping text projection whose shortest
  representation is the hard half). Forced by
  `then "a REAL column round-trips through a float exactly"`.
- **7.** The interpreter's extern host (dlsym + a fixed set of uniform ABI
  shapes, never libffi — spec 15.3). Forced by moving
  `corpus/native/sqlite_seam.av` to `corpus/sqlite/` and demanding
  **eval == native == expected**. **This one test is the whole feature's
  proof**, and it retires the message at `language/interp.av:574`.
- **8.** `opaque type` + `@free_with` — forced by red-team cases 7 and 8,
  which are compiler-refusal tests and cannot be answered any other way.
- **9.** `decimal` — forced by the ORM's money cases, not by SQLite (SQLite
  has no decimal storage class; it rides TEXT or INTEGER-scaled). Design it
  with the ORM in view.
- **10.** Callback trampolines (spec 15.3) — forced by hooks, custom SQL
  functions, collations, the busy handler, the authorizer, the progress
  handler. The last language slice, because everything else is reachable
  without it.

### The rhythm, per slice

```
write the failing test        (Tier 0 first; it names the gap)
→ ./avra check scratch/probe.av              (probe the shape, sub-second)
→ implement
→ sh tools/watch.sh 4000 ./avra test <pkg>   (the one suite)
→ sh tools/watch.sh 4000 make gate           (vocab idioms tested corpus)
→ sh tools/watch.sh 4000 make fuzz           (grammar/lexer slices only)
→ /red-team, then /review-round              (CLAUDE.md's standing order)
→ ledgers fed: ROADMAP.md, CLAUDE.md, DOGFOODING.md, the probe log
→ hand the commit message over; the owner's word commits
→ sh tools/integrate.sh sqlite <message-file>
```

---

# BLOCKERS

Things missing from the tree's own machinery that stop the test plan, each
with a proposed shape. (Language gaps — float, Bytes, out-params, opaque
types, annotations, callbacks — are the ROADMAP's `THE GAPS` list at
`:1548-1655` and are not repeated here.)

## B1 — A CORPUS PROGRAM CANNOT HAVE LINK FLAGS AND SKIP THE EVALUATOR

**The bind.** An sqlite corpus program needs `[link] flags = ["-lsqlite3"]`
or vendored objects, and link inputs come only from a manifest
(`workspace.av:938-946`). The corpus has exactly three shapes:

| shape | manifest? | evaluator? | source |
|---|---|---|---|
| `corpus/*.av` (flat) | **no** — `corpus/` has no `avra.toml`; a rootless workspace reads an empty manifest (`workspace.av:1103-1112`) | yes | `Makefile:100` |
| `corpus/native/*.av` | **no** — same | **no** (`--native-only`) | `Makefile:101` |
| `corpus/<pkg>/` | yes | **yes, unconditionally** | `Makefile:102-115` |

So today: the shape with flags must run under the evaluator, and the evaluator
traps on every extern (`interp.av:574`). **No sqlite program can enter the
corpus gate.**

**The fix, smallest first.**

1. **`corpus/native/avra.toml`.** `programs_workspace` builds a root package at
   the corpus directory and reads `avra.toml` there if it exists
   (`workspace.av:1140-1145`, `manifest(ws, 0)` at `:1103`). A manifest at
   `corpus/native/` would supply `[link]` flags to every native-only corpus
   program, and — because `admit_dependencies` runs for the root — could also
   name `"@std/sqlite" = { path = "../../packages/std-sqlite" }`.
   **Confidence MEDIUM: read from the code path, not run.** Probe it in the
   vendoring slice; it is a two-line experiment.
2. **If (1) does not hold**, grow the Makefile's package-corpus loop with a
   native-only marker — a `corpus/<pkg>/native` sentinel file, or a
   `[package] eval = false` manifest key — so a package-shaped corpus entry
   can skip `./avra run`. This is the honest fix and it is small.
3. **Either way it is TEMPORARY.** The interpreter's extern host removes the
   need entirely, and the moment it lands, `corpus/sqlite/` runs both engines
   and becomes the extern host's own proof. **Design (1) or (2) as scaffolding
   with a removal date, not as a permanent second class of corpus program.**

## B2 — A NEW PACKAGE IS INVISIBLE TO TWO HARD-CODED LISTS

`Makefile:19`'s `SUITES` and `tools/idioms.py:30-33`'s `SRC` are hand-written
lists. A `packages/std-sqlite` absent from either is a package whose suites
never run in the gate and whose code is never held to the idiom bar — **and
both fail SILENTLY GREEN**, which is the exact disease the ratchet's four laws
exist to prevent one level down.

**Fix.** Two one-line edits in the package's first commit, plus a keeper in
the style of `tools/vocab.sh`: a gate step that lists `packages/` and refuses
a package that is in neither `SUITES` nor `SRC`. The check cannot be written
from inside Avra (a suite cannot see the Makefile), so it belongs in the same
place the other registry keeper does — a small shell script the gate runs.
**Worth writing once for every future package, not just this one.**

## B3 — A TRAPPING CASE MASKS EVERY LATER CASE IN ITS PACKAGE

`avra_trap` exits 2; `verdict_of` calls it `.Died`; the runner prints
"everything after it never ran" (`test_run.av:49-56`, `staged.av:44-47`).
A driver's failure modes include segfaults, and one of them silently hides an
arbitrary number of green cases.

**Fix (a, cheap and immediate).** Split the driver's suites by BLAST RADIUS,
not only by subject: the cases most likely to trap (use-after-finalize probes,
corruption, limits) live in their own file so a trap there costs one file's
cases, not the package's. `avra test <file>` runs one file
(`shared.av:113-134`), so a trapping file is also independently re-runnable.

**Fix (b, the real one, and a genuine tree improvement).** The runner knows
which case was running — `avra_case_begin` stores the label
(`runtime/avra_runtime.c:443-445`) and `avra_trap` prints it. Have the staged
runner RESUME after a trap: re-exec the binary with a "start at case N+1"
argument, and report the trapped case as a failure rather than as the end of
the run. This is a change to `language/test_run.av`'s entry and
`commands/staged.av`, it benefits every package, and a driver campaign is
exactly the campaign that justifies it. **Propose it; do not assume it.**

## B4 — `AVRA_RC_GUARD` IS BLIND AT THIS SEAM, AND THE TREE HAS NO OTHER INSTRUMENT

The guard watches retain/release events; an untagged foreign pointer raises
none, so it prints clean for a correct borrow and for a use-after-free alike
(probe log §6; `hdr`'s tag check at `runtime/avra_runtime.c:66-73` gates
everything). **Everywhere else in this tree the guard is the instrument of
record; here it is silent by construction**, and a driver author reaching for
it is reassured by nothing.

**Fix.** Three layers, none of them the guard:
1. **The compiler law** — first-five test #1. If the wall cannot answer
   foreign text as `string`, the class of bug is unrepresentable.
2. **The mutation/poison tests** of §2.7, which prove the copy positively
   rather than hoping the guard would catch its absence.
3. **A vendored amalgamation compiled with `SQLITE_DEBUG` and
   `SQLITE_MEMDEBUG`** for a test-only build profile — SQLite's own allocator
   then fills freed memory with a known pattern, and a stale read is LOUD
   instead of lucky. `avra.toml` has `[profile.dev]` in the manifest grammar
   (`language/tests/manifest_test.av:9`) — **whether a profile can select
   different `[link] objects` today is UNVERIFIED and needs a probe.**

## B5 — NO PROPERTY TESTS, NO SNAPSHOTS, NO FILTERING

Spec Axis 24.2/24.3 specify `property` and `assert_snapshot`
(`FULL_SPEC.md:4812-4888`); neither exists. For a driver, property tests are
the natural fit for round-tripping — *for all byte strings b, read(write(b)) == b*.

**Fix.** Do **not** grow the test DSL in this lane; that is a separate feature
with its own owner. Write the round-trip as a bounded, deterministic LOOP
inside one case — the tree already does exactly this
(`io_adversarial_test.av:158-168` writes two hundred files in a `while` and
asserts the listing), and a loop over a fixed 256-value byte table is a
property test with a fixed generator. **Record the ask in the ROADMAP's sugar
backlog, naming this suite as the wanting site** (`CLAUDE.md:293-303`).

## B6 — NO FLOATING POINT MEANS NO REAL COLUMN, AND NO BYTES MEANS NO BLOB

Restated here only because they are the two gaps that make **half the red-team
catalogue unwritable today** (cases 25-27, 30-35). They are ROADMAP items
(`:1548-1566`), they are CORE events with the IR protocol's eight consumers
to pay (`CLAUDE.md:349-372`), and they are first-five items #2 and #6. Nothing
in Tier 2 or above is fully testable until both land.

---

# CONFIDENCE LEDGER

| # | claim | how verified | confidence |
|---|---|---|---|
| 1 | The test DSL is `spec`/`given`/`then`, a compiler feature, grammar as quoted | read `features/specs/mod.av:27-31` | HIGH |
| 2 | A `then` is a bodied declaration answering `bool`; F2042 | read `features/specs/check.av:11-19`, `mod.av:25` | HIGH |
| 3 | A spec is top-level (F3022); a group names each case once (F3023) | read `features/specs/semantics.av:20-36`, `mod.av:23-24`; pinned at `specs_test.av:136-141` | HIGH |
| 4 | A `then` may hold statements, `return`, forward references, sibling-module calls | read `specs_test.av:110-133` (the tree's own pins) | HIGH |
| 5 | A `then` may NOT hold `?` — it promises `bool` | read `features/nullable/check.av:241`; consistent with every suite hoisting into `Result` helpers | HIGH |
| 6 | `avra test` compiles cases NATIVELY and links the package's `[link]` words | read `commands/test.av:1-4, 33-43`; `shared.av:253-277`; `workspace.av:938-955` | HIGH |
| 7 | A failing case prints its label and nothing else | read `language/test_run.av:160-166` | HIGH |
| 8 | A trap names the case, exits 2, and every later case never runs | read `runtime/avra_runtime.c:443-459`; `test_run.av:49-56`; `staged.av:44-47` | HIGH |
| 9 | Fixtures use TMPDIR, clean BEFORE not after, one root per suite | read `io_test.av:8-21`, `io_adversarial_test.av:10-24` | HIGH |
| 10 | `refused_with` pins `diagnostics.length == 1`; I20/I30 ratchet it, TESTS_ONLY | read `testing/mod.av:22-27`; `idioms.py:123-137, 369-370, 405-409` | HIGH |
| 11 | The corpus has three shapes; the package shape runs eval unconditionally | read `Makefile:99-115`; `commands/corpus.av` | HIGH |
| 12 | `corpus/` and `corpus/native/` have no `avra.toml`, so no link flags | `ls -a corpus/ corpus/native/` | HIGH |
| 13 | A manifest at a corpus root WOULD supply link flags | read the code path `workspace.av:1140-1145` → `manifest(ws,0):1103-1122` → `link_inputs:938-946`; **not run** | MEDIUM |
| 14 | A corpus program prints its final expression only; F0901 for the rest; holes are scalars/strings | read `language/lower_walk.av:133-165`; `features/str_lit/check.av:1-13`; `CLAUDE.md:446-452` | HIGH |
| 15 | `make gate` = vocab idioms tested corpus | read `Makefile:136` | HIGH |
| 16 | `make vocab` names eight exhaustive Ins consumers and fails on a catch-all | read `tools/vocab.sh` | HIGH |
| 17 | The idiom baseline is sites-not-counts, prune-only, license-at-site, registry-must-not-outrun; **debt is ZERO** | read `tools/idioms.baseline` (five comment lines, no entries); `idioms.py:1-27, 633-653`; DOGFOODING.md:88-91 | HIGH |
| 18 | `idioms.py`'s SRC and `Makefile`'s SUITES are hard-coded and would omit a new package | read `idioms.py:30-33`; `Makefile:19` | HIGH |
| 19 | `watch.sh` holds a machine-wide `/tmp` lock, 20% memory floor, default cap 4000, RSS tripwire + footprint every 4th poll, 137 on cap | read `tools/watch.sh` end to end | HIGH |
| 20 | `integrate.sh` gained a PRE-FLIGHT: main's compiler must read the lane's tree, else seed main from the lane's product, else refuse with main untouched | read `tools/integrate.sh:44-70` | HIGH |
| 21 | A diagnostic's rendering is pinned by a triple-quoted exact-string `then` | read `diagnostics/tests/render_test.av:1-2, 33-66` | HIGH |
| 22 | A new kind is a `table<DiagCode>` row in the owning feature's `mod.av`; duplicate kind or id refuses ASSEMBLY | read `features/specs/mod.av:20-25`; `features/coherence.av:97-111`; `language/mod.av:112-115`; pinned `language_test.av:47-56` | HIGH |
| 23 | Next free F-codes: F2056, F3026, F0903, F0103 | greped every `"F####"` in `packages/std-avrac/src` and sorted | HIGH |
| 24 | `str_len` falls back to `strlen` when the header length is 0; `avra_streq` is `strcmp`; `contains`/`index_of` are `strstr` | read `runtime/avra_runtime.c:272-275, 475-478, 1144-1162` | HIGH |
| 25 | `AVRA_RC_GUARD` cannot see a foreign untagged pointer | read `hdr` at `avra_runtime.c:66-73` gating `rc_note`; probe log §6 records the guard running clean on a known borrow | HIGH |
| 26 | Test files under `src/tests/` compile for `avra test` on the ROOT package only | read `workspace.av:739-741` (`root_files` = packages[0].src) and the module-by-`use` resolution | HIGH |
| 27 | `[dev-dependencies]` exist and are admitted for the root only | read `manifest.av:58`; `workspace.av:1148-1154` | HIGH |
| 28 | Spec Axis 24 specifies `test`/`describe` from `@std/test` with properties and snapshots — this tree diverges | read `FULL_SPEC.md:4758-4888` | HIGH |
| 29 | `BEGIN IMMEDIATE` + `busy_timeout(0)` on a second connection yields SQLITE_BUSY deterministically | SQLite documented semantics; **not probed in this tree** | MEDIUM-HIGH |
| 30 | `sqlite3_column_blob` returns NULL for SQL NULL, a zero-length blob, AND out-of-memory | quoted from `sqlite3.h:5411, 5519-5525` in the probe log §2a | HIGH |
| 31 | `sqlite3_column_text`'s buffer dies at the next step/reset/finalize or on a type conversion | SQLite documentation; probe log records it as MEDIUM pending the driver's first row | MEDIUM |
| 32 | `sqlite3_close` refuses with BUSY while statements live; `close_v2` zombifies | SQLite documentation; not probed | MEDIUM-HIGH |
| 33 | NaN bound with `bind_double` stores as NULL | SQLite documented behaviour; **not probed — the test must pin what happens, not what is expected** | MEDIUM |
| 34 | `sqlite3_limit` lowers a limit and answers the previous one, making limit tests cheap | SQLite documentation; not probed | MEDIUM-HIGH |
| 35 | SQLite does not validate UTF-8 on `bind_text` | SQLite documentation; **weakest claim here — pin the behaviour, do not assume it** | LOW-MEDIUM |
| 36 | The result-code integers quoted (BUSY 5, READONLY 8, INTERRUPT 9, CORRUPT 11, CANTOPEN 14, TOOBIG 18, CONSTRAINT 19, MISUSE 21, RANGE 25, NOTADB 26, ROW 100, DONE 101, CONSTRAINT_UNIQUE 2067) | SQLite's stable public API | HIGH |
| 37 | Avra calls SQLite today with one `[link]` row, no shim | probe log Part I §1 — built and ran, printed `3051000` | HIGH (inherited) |
| 38 | An `avra test` link line uses the RELATIVE path `build/avra_runtime.o`, so runs must start at the tree root | read `shared.av:275` | HIGH |

**OVERALL: HIGH on the machinery, MEDIUM on the SQLite semantics the tests
assert.** The weakest link is that no SQLite call beyond
`sqlite3_libversion_number` has been made from Avra in this tree — every
claim about BUSY, WAL, column lifetimes, NaN and UTF-8 is documentation, not
measurement. **PROBE, DON'T REASON**: the first slice's job is to turn rows
29-35 of this ledger into probe-log entries, and any of them that comes back
different is a better finding than the plan it corrects.
