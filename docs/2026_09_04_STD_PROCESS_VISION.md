# @std/process — The Program Is The Authority, The Words Are Data

> **Status:** vision, written to be worked BACKWARDS from. Lane B's north
> star; the ladder in Part VII says what exists today, what each rung needs,
> and who owns the piece. Sibling to `THE ROOT IS THE ONLY DOOR` (the
> filesystem) and `STRINGS FROM THE FUTURE`; `2026_04_18_FULL_SPEC.md` stays
> law where they disagree. Aspirational syntax is marked `[v1]`/`[v2]`;
> unmarked code compiles against the tree as it stands on 2026-09-04.
>
> **Sources:** four research reports commissioned for this doc, beside it
> as `2026_09_04_STD_PROCESS_RESEARCH_*.md` — prior art across thirty
> process APIs, the POSIX substrate (55 numbered pitfalls), supervision and
> pipelines, and the security laws. Their verdicts are folded in and named
> where they changed a decision; their confidence ledgers are not repeated
> here — read them before promising anything marked MEDIUM or LOW there.
>
> **The axioms it serves:** P1 (an author that never sleeps writes the
> right thing or is refused with the fix attached), P3 (the shell's
> spelling, none of the shell's ceremony), P4 (one `posix_spawn`, one
> poll loop, no threads, no copies the call site cannot see), P6 (every
> section below is a paradox dissolved, not a horn picked), P7 (`avra
> explain process` prints what the binary can run), P8 (every literal is
> sugar over a constructor; every hatch is spelled and counted), P9 (a
> child is a boundary and its contract is a value), P10/P12 (the set of
> programs a binary can run is a compile-time fact, projected as a
> systemd unit, a sandbox rule, a supply-chain diff), P13 (the service
> declaration IS the ops artifact), P14 (no daemon, no supervisor
> process, no container).

> A command is a `string` asked to be three different things at once — a
> **program** (an authority: the right to run *that* binary), its
> **arguments** (data: inert words), and the **grammar** the program will
> read those words by (which word is an option, which is a file). Every
> subprocess bug of the last fifty years is what happens when one value
> carries all three. Split them, and shell injection, argument injection,
> PATH hijacking, the forgotten exit code, the zombie, the deadlocked pipe
> and the supply-chain build stop being bugs you avoid and become programs
> that do not compile.

---

## Table of contents

1. Part I — The presenting bug (it is in our tree)
2. Part II — Design from first principles: split the paradox
3. Part III — The paradoxes, collapsed (nine of them)
4. Part IV — A day in the perfect world (the code)
5. Part V — The canonical model (types, verbs, errors, the manifest, the laws)
6. Part VI — A command is a value the compiler runs in every direction
7. Part VII — Working backwards: the ladder, v0 → v1 → v2
8. Part VIII — The asks (what I need granted, and from whom)
9. Part IX — Honest limits
10. Part X — Slogans

---

# Part I — The presenting bug

```avra
// packages/cli/src/commands/shared.av:180 — the compiler linking a program
if avra_shell_exec_status("clang -w -O1 ${shell_word(ll_path)} build/avra_runtime.o ${promised} -o ${shell_word(out)}") != 0 {
```

`promised` is every `[link] flags` row of every package in the workspace,
spliced unquoted into a string handed to `system(3)`, which hands it to
`/bin/sh`. A transitive dependency whose manifest says
`flags = ["; touch /tmp/PWNED ;"]` runs that during `avra build` of a
program that never imports it. Proved by the red team; lane 0 is landing
the argv-list fix tonight as `avra_spawn_status(prog, argv)`.

Look at *why* it was written. The author quoted the paths — `shell_word`
exists — and reasoned that a `[link]` row is "the project's own word". True
of the root package, false of every dependency. But the deeper cause is
upstream of the reasoning: **the only spawn primitive in the tree took a
string.** When the door takes text, someone will eventually assemble text.
`shell_word` is the `normalize()` of subprocesses — a fence bolted onto a
door that should never have been a string.

And the argv-list fix, necessary as it is, **deletes the shell and not the
injection**. With argv as a list, `flags = ["-fplugin=./evil.so"]` is one
perfectly valid clang argument that loads an unrestricted plugin into the
compiler. That is CVE-2018-6574 exactly — Go before 1.9.4, where a fetched
repository could ship `attack.so` beside `#cgo CFLAGS: -fplugin=attack.so`.
The attacker stops writing `;` and starts writing `--`. Part V's laws are
what closes the second door; lane 0's fix is step one of five.

Three more, from the same seam:

- `avra_shell_exec_status` answers an `int`. `127` means "the shell could
  not find it", `128+n` means "a signal killed it", `1` means "the program
  said no", and a program that exits `256` reads as success. Four facts,
  one integer. The test runner already writes the rule
  (`test_run.av`: "THE STATUS IS A VERDICT, never a count") and then reads
  the verdict back through an `int`.
- `system()` runs the child with the PARENT'S WHOLE ENVIRONMENT: every
  secret in the invoker's shell, `DYLD_INSERT_LIBRARIES`, the lot. The
  compiler's own build inherits whatever the developer's terminal holds.
- The `println` every corpus program declares is `extern fn println(s:
  string)` — the host seam is reached by *naming C*, so a program prints by
  declaring a foreign function. That is the seam's tell: there is no
  library between the language and the machine, only bare externs.

Four `string`s and an `int`, and one root: **the subprocess was modelled
as text.** Text is exactly the wrong model, because text carries no
authority, and a command carries all of it.

---

# Part II — Design from first principles: split the paradox

## Name the real paradox

It is not "convenience versus safety". That is the symptom. A command
string is forced to mean three things:

1. a **program** — WHICH binary runs. An authority. Unforgeable, resolved
   once, known to the compiler.
2. its **arguments** — WHAT the program is told. Inert data. Each word is a
   word; no word is ever re-read as two.
3. its **grammar** — which words the program will read as OPTIONS and
   which as operands. This third thing is the one every "just use an argv
   list" answer forgets: `git clone $url` with `url = "--upload-pack=…"`
   is a clean argv list and a remote code execution.

The shell collapses all three into one line of text and re-parses it at
runtime, which is why `$name` with a space becomes two arguments, why `;`
becomes a second command, and why every language ships a `shell_quote`
and every quoter has a CVE.

## The collapse

Split them and each half lands at its true cost:

- **Program → `Tool`.** A value. Minted from the manifest, or from a
  literal's first word, or through one named widening from text. Resolved
  to an absolute path ONCE, at mint — there is no PATH lookup at the call
  site, so there is no window between "which git" and "run it". You
  cannot type one; you can only be handed one.
- **Arguments → words, each in a POSITION.** A hole in a command literal is
  exactly one argv word, however many spaces or semicolons it contains,
  because there is no shell to re-read it. And a word built from DATA is
  emitted where a dash is inert: fused to its flag (`--out=VALUE`, one
  element), `./`-prefixed when it is a path, or after the tool's declared
  end-of-options marker. Injection is not defended against. It becomes
  structurally unaskable — shell injection by the first rule, argument
  injection by the second.
- **Wiring → `Command`.** A record with defaults. `with` changes one field.
  The exit is an `Exit` value, never an `int`. The environment that crosses
  is a declared allow-list, never the inherited world. The cwd is a
  directory the parent holds open, never a path string.

Neither half can run a process alone. The `run` is where they meet, it is
one `posix_spawn`, and the spawn is the check.

## And then the ceremony problem

`Command::new("git").arg("log").arg("--oneline").arg(&branch)` is correct
and nobody enjoys writing it. Models have seen `git log --oneline $branch`
ten billion times and will write that. A design that fights the corpus
loses to the corpus.

Avra collapses this because Avra already has the piece: **a typed literal
with a compile-time grammar** (`grammar { }`, the embedded-sublanguage
contract). A `cmd"…"` literal ACCEPTS the shell's word spelling and
COMPILES it, at build time, into `Tool` + words. A `sh"…"` literal
accepts a TINY pipeline subset — `|`, `&&`, `||`, five redirects, quoting,
holes — and compiles it to a `Pipeline`. No shell runs. Rust's `cmd_lib`
states the security argument in one line: *parsing happens before variable
substitution, unlike bash, which always substitutes first.* The model
writes what it knows; the compiler makes it the safe thing.

> The shell's spelling, compiled to the shell's absence.

---

# Part III — The paradoxes, collapsed

Nine, each a place where every other language picked a horn.

### 1. Shell convenience vs. shell injection
**Horns:** `subprocess.run(cmd, shell=True)` (convenient, injectable) vs.
`Command::new(..).args([..])` (safe, ceremonious).
**Collapse:** the `cmd"…"` literal is parsed at COMPILE time. Words are
argv. A `${hole}` is one word; a `List<string>` hole is N words. The
program position takes a literal word only — a hole there is F4601 ("the
program is the authority; it is spelled, never computed"). Injection is
unwritable and the code reads like the shell. Bun Shell and `cmd_lib`
ship this today; neither has the next collapse.

### 2. Accept dangerous input vs. reject useful input
**Horns:** a filename may begin with `-` (so refusing dashes breaks real
files) vs. `--upload-pack=` arrives as a filename (so accepting dashes is
CWE-88). Denylists of flags were bypassed in GitPython this year by an
underscore that normalised to a dash AFTER the check ran.
**Collapse:** change WHERE the input lands, not whether it is allowed. A
value fused to its flag (`--out=VALUE`) is one element and cannot open an
option. A path is always emitted `./`-prefixed, so `-rf` is `./-rf` and
`-` is a real file, never stdin. A positional after the tool's declared
end-of-options marker is inert. These are total functions from data to a
non-option word — no per-tool knowledge, no version check. The dash is
not filtered. It is moved to where it means nothing.

### 3. One-shot ergonomics vs. streaming correctness
**Horns:** `out = run(cmd).stdout` (buffers the world, deadlocks on a
full stderr — Python's own docs carry the warning box) vs. hand-rolled
`Popen` + `communicate` + threads.
**Collapse:** ONE mechanism. `run()` is `start()` + drain + `wait()`; the
drain is one poll loop over both pipes so a full stderr can never stall
stdout; captures are CAPPED (the manifest's `max_capture`, 16 MiB unless
said otherwise — exceeding is `.TooMuch`, never OOM); `lines()` is the same
loop handed back a line at a time. The 90% case is one word; the 10% case
is the same code with the loop exposed. And there are TWO deadlines, not
one: `timeout` bounds the child's life, `drain_grace` bounds how long
output may keep arriving AFTER it exits — because "the child exited" and
"the output ended" are different events, and a grandchild holding the
write end (`ssh -f`, every daemonizer) makes the second one never come.
Go added `WaitDelay` in 1.20 for exactly this; every other stdlib hangs.

### 4. Exit code as a number vs. as a verdict
**Horns:** `if r.returncode != 0` (forgotten in half of all scripts) vs.
`check=True` throwing on `grep`'s honest `1`.
**Collapse:** `Exit` is an enum — `.Clean`, `.Code(n)`, `.Signal(sig, core)` —
and `.Code(0)` is unconstructible. `run()` JUDGES: any exit outside the
command's `ok_exits` (default `[0]`) is `Err(.Failed(exit, out))`, so `?`
propagates it and a forgotten check cannot be written. `grep`'s `1` is
`cmd"grep …" with { ok_exits: [0, 1] }` — systemd's `SuccessExitStatus=`,
spelled once at the site. `outcome()` does NOT judge: the exit is a value
you match. Two verbs, both total, the cost legible in the name.

### 5. Inherit the world vs. hermetic isolation
**Horns:** the child sees every variable in the developer's terminal
(works everywhere, leaks everything) vs. `env -i` (safe, and nothing
works).
**Collapse:** a named, versioned, PRINTED minimal base — `HOME`, `TMPDIR`,
`LANG=C`, `TERM` when stdio is a tty, and a `PATH` MINTED from the
declared tools' directories, never inherited — plus `pass = [...]` in the
manifest. (v0, honestly: until the manifest declares tools, the child's
`PATH` is the invoker's with every relative entry stripped — the
hijack-by-cwd closed, the minting waiting on the mint.) sudo's `env_reset`, Nix's `--pure`, Bazel's strict action env
and systemd's `PassEnvironment=` each reached this independently, and
sudo's manual states why a denylist cannot work. Inheriting everything is
a spelled, counted hatch, and its warning PRINTS the denylist as the
receipt: every name it just let through that turns a program into an
interpreter.

### 6. Text pipes vs. records
**Horns:** Unix (`|` carries bytes; every stage re-parses) vs. Nushell
(`|` carries records; only Nushell's own commands speak it).
**Collapse:** BOTH, at a marked boundary. Between two programs a `|` is a
kernel pipe (bytes, zero copies through us). Between the last program and
Avra, one boundary verb — `.lines()`, `.bytes()`, `.json<T>()` [v2] — and
NEVER a heuristic (`detect columns` is refused: an attempt is not a
contract). From the boundary on, `|>` and `it` take over. A `Pipeline` is
a value; its outcome carries EVERY stage's `Exit` and every stage's OWN
stderr. Bash has known for thirty years that a pipeline's status is a
vector (`PIPESTATUS`) and still defaults to throwing it away. Here
`pipefail` is not a flag. It is the data.

### 7. Long-lived children vs. structured lifetimes
**Horns:** `spawn` and forget (Rust's std documents that a dropped `Child`
keeps running; a dev server holds port 3000 an hour after the terminal
closed) vs. a supervisor daemon.
**Collapse:** a `Child` is a value that belongs to a scope. Today the
scope is a bracket fn (`serving(cmd, (c) -> …)`); with `defer` (landed,
slice D) it is the enclosing block; when `spawn { }` lands [v2] it is the task tree
(the memory doctrine's F3: "the call tree is the lifetime"). Stop is one
law: TERM to the process GROUP, a grace, KILL, reap — never a bare
`kill(pid)` racing a reaped pid. And `start(service)` RETURNS WHEN READY,
not when spawned: Trio's `nursery.start()` handshake, systemd's `READY=1`
and Kubernetes' `startupProbe` are one primitive, and it deletes `sleep 5`
from every integration test.

### 8. Fast vs. concurrent I/O without threads
**Horns:** a thread per pipe (Python, Java) vs. blocking reads that
deadlock.
**Collapse:** one `posix_spawn`, one `poll(2)` loop, zero threads, in
~300 lines of C the runtime already owns the style of. When fibers land
the loop becomes the scheduler's (three fibers per child: stdin writer,
two readers) and the library surface does not move.

### 9. Real processes in tests vs. determinism
**Horns:** tests that shell out (slow, flaky, machine-dependent) vs. mocks
that drift from reality.
**Collapse:** `Runner` is a trait. `host()` spawns; `scripted(table)`
answers from a table; `plan()` prints and returns a dry exit; later
`record`/`replay` write and read the same content-addressed entry the
build cache uses. `--dry-run`, the test double, the VCR cassette and the
cache are ONE seam and ONE hash, not four features that drift. Every law
above the syscall — the caps, the judging, the pipeline verdict, the
timeout — runs in every binding.

---

# Part IV — A day in the perfect world

Everything the subprocess chapter of every language book teaches, as it
reads here. Unmarked code compiles today (given the package); `[v1]` needs
the substrate rows and the literals; `[v2]` needs fibers and `|>` (`defer`
landed 2026-09-05).

## IV.1 The one-liner

```avra
use @std.process.{tool, cmd, ProcessError}

fn head() -> Result<string, ProcessError> {
    let git = tool("git")?                  // resolved ONCE: /opt/homebrew/bin/git
    (cmd(git, ["rev-parse", "HEAD"]).run()?).stdout.trim()
}
```

```avra
// [v1] the literal — the same value, the shell's spelling
let head = cmd"git rev-parse HEAD".run()?.stdout.trim()
```

`run()` judges. If git exits `128` this line does not return a string
with a lie in it; it fails with `.Failed(.Code(128), out)`, and `out.stderr`
holds `fatal: not a git repository`. The caller `?`s or `catch`es. There is
no way to write this line and ignore the failure.

## IV.2 The word that is one word

```avra
let branch = args.get("branch") ?? "main"      // came off the command line
let log = cmd"git log --oneline ${branch}".run()?       // [v1]
```

`branch` is `"main; rm -rf /"`. The child receives four argv words; the
fourth is that whole string; git says `fatal: bad revision`. Nothing else
happened, because nothing else CAN happen — there is no shell between the
literal and `execve`. Today's spelling says the same thing longer:

```avra
let log = cmd(git, ["log", "--oneline", branch]).run()?
```

## IV.3 The word that cannot become an option

```avra
// today: the position verbs — a value lands where a dash is inert
let clone = cmd(git, ["clone"]).flag("--depth", "1").after_options([url]).path(dest)
//  argv = ["git", "clone", "--depth=1", "--end-of-options", url, "./checkout"]
```

`url` is `"--upload-pack=touch /tmp/pwn"`. It sits after git's declared
end-of-options marker (a ROW on the tool's manifest entry — `terminator =
"--end-of-options", min = "2.43.1"` — because a terminator the installed
binary does not honour is worse than none). `dest` is a path, so it is
emitted `./checkout`; a file literally named `-rf` becomes `./-rf`. Nothing
was filtered. The dash landed where it means nothing.

```avra
// [v2] the deep tier: a package where the dangerous flag is UNSPELLABLE
use @std.process.git
let repo = git.clone(url: remote.url()?, into: work.dir(p"checkout"))?
```

## IV.4 The exit that is a value

```avra
let found: Outcome = cmd(grep, ["-q", pat]).path(file).outcome()?
match found.exit {
    .Clean -> "present",
    .Code(1) -> "absent",
    .Code(n) -> fail SearchError.tool_failed(n, found.out.stderr),
    .Signal(s, _) -> fail SearchError.killed(s),
}
// or: declare grep's convention once and let run() judge the rest
let hit = cmd(grep, ["-q", pat]).path(file) with { ok_exits: [0, 1] }
```

`outcome()`'s `?` fires only when the child never ran — the program
vanished, the spawn was refused, a pipe broke. Once it ran, its exit is
yours to read, and the compiler makes you read all of it.

## IV.5 Wiring reads as `with`

```avra
let build = cmd(clang, flags) with {
    cwd: workdir,                                   // [v1] a Dir; the child's cwd IS our fd
    env: pass(["SDKROOT"]).set("LC_ALL", "C"),
    stdin: .Closed,
    timeout: secs(120),
    max_capture: mib(64),
}
let out = build.run()?
```

A `Command` is a record with defaults; `with` changes what differs. A
timeout that fires answers `.TimedOut(after, partial)` — the partial
output rides along, because the last hundred lines before the hang are
the only evidence anyone will have.

## IV.6 Lines as they arrive

```avra
for line in cmd(tail, ["-f"]).path(log).lines() {       // a Seq<string>
    if line.contains("ERROR") { alerts.push(line) }
}
```

While this loop reads stdout, the same poll loop drains stderr into a
bounded buffer. A child that writes 10 MiB to stderr cannot stall the
loop; a child that never closes stdout is bounded by `timeout`. Both
streams, tagged and in arrival order, when the order matters:

```avra
for l in cmd(make, ["-j8"]).output() {              // Seq<Line>
    match l.stream { .Stdout -> plain(l.text), .Stderr -> red(l.text) }
}
```

## IV.7 The pipeline whose failure has a shape

```avra
let sorted = sh"cat ${f} | grep ^a | sort".run()?.stdout            // [v1]
let sorted = cmd(cat, []).path(f).pipe(cmd(grep, ["^a"])).pipe(cmd(sort, [])).run()?.stdout
```

Three children, two kernel pipes, no bytes through us. `run()` on a
pipeline judges EVERY stage by its own `ok_exits`. When `grep` finds
nothing:

```
error[F4620]: pipeline stage 2 of 3 failed
  ╭─[report.av:14:22]
14 │   sh"cat ${f} | grep ^a | sort"
   ·                 ───┬───
   ·                    ╰── `grep` exited 1
──╯
stages   1 cat    Clean       2.1 MiB out
         2 grep   Code(1)     0 B out          ← first failure
         3 sort   (not run)
stderr of stage 2: (empty — grep exits 1 for "no lines matched")
help: this pipeline treats any exit outside a stage's `ok_exits` as
      failure. grep uses 1 for "no match". Allow it at the stage:
        cmd"grep ^a" with { ok_exits: [0, 1] }
```

The failing stage is NAMED with its argv, its OWN stderr is quoted (never
the interleaved soup of all three), and the diagnostic knows grep's
convention. When failure is not failure to you, ask instead of being
judged:

```avra
let r: PipeOutcome = pipeline.outcome()?
let failing = r.stages.enumerate().find(!(it.exit is .Clean))    // pipefail, as data
```

## IV.8 Where text ends and values begin

```avra
// [v2] `|>` and the boundary verbs
let names = cmd"ls".path(dir).lines()
    |> filter(it.ends_with(".av"))
    |> map(it.replace(".av", ""))
    |> sorted()

let pkgs: List<Pkg> = cmd"cargo metadata --format-version 1".run()?.stdout.json<Meta>()?.packages
```

Between programs, bytes. From the last program to Avra, ONE boundary
verb, spelled. After it, the whole list vocabulary. There is no
`detect_columns()`. Deliberately.

## IV.9 A server that cannot be forgotten

```avra
// today: the bracket form — the child dies when the thunk returns
let status = serving(cmd(python, ["-m", "http.server", "${port}"]), .Line("Serving HTTP"), () -> {
    probe("http://localhost:${port}/")
})

// defer (landed): the scope is the lifetime; start() returns when READY
let srv: Child = cmd(python, ["-m", "http.server", "${port}"]).start(.Line("Serving HTTP"), secs(10))?
defer srv.stop()
probe("http://localhost:${port}/")
```

`stop` is TERM to the process GROUP, the command's `stop_grace`, then
KILL, then `wait` — and it answers the `Exit` it observed. `start` takes a
`Ready` and blocks until it is satisfied or `.NotReady` fires: `.Started`
(the pid exists — the weakest, and NAMED as weak), `.Line(pattern)`,
`.Exit` (the default for one-shots), `.Exec(cmd)` (a probe command exits
clean), and `.Port(n)` / `.Http(path)` / `.Notify` [v2]. There is no
variant that guesses.

## IV.10 The environment that crosses is the one you named

```toml
# avra.toml
[process.tools]
git   = { from = "path", terminator = "--end-of-options", min = "2.43.1" }
clang = { from = "env", var = "CC", default = "clang", terminator = "--" }
tar   = { from = "path", terminator = "--" }

[process.env]
base = "minimal"                          # PATH minted from the tools' dirs; HOME TMPDIR LANG TERM
pass = ["SDKROOT"]
```

```avra
// [v1] minted from the manifest — resolved at seal, absolute, pinned, printed
let head = cmd(process.git, ["rev-parse", "HEAD"]).run()?
// a program the manifest did not name:
let x = cmd(process.curl, ["…"])
```

```
error[F4602]: no tool named `curl`
  ╭─[fetch.av:9:17]
9 │ let x = cmd(process.curl, ["…"])
  ·                     ──┬─
  ·                       ╰── `process` mints 3 tools and none is `curl`
──╯
declared: git (path)  clang (env CC)  tar (path)
fix: add to avra.toml —
       [process.tools]
       curl = { from = "path", terminator = "--" }
note: adding a tool widens this package's capability set TWICE — an exec
      target, and one file in the process's Landlock ruleset. `avra caps
      diff` will report both to your dependents.
```

## IV.11 The service that is also its own unit file

```avra
// [v1] one declaration; run it here, or print it for a launcher
component Service {
    config {
        name: string,
        run: Command,
        ready: Ready = .Started,
        healthy: Ready? = null,               // same vocabulary; the consequence is a restart
        restart: Restart = .OnFailure,
        backoff: Backoff = .Exponential(ms(100), secs(30)),
        give_up: Intensity = Intensity { times: 5, within: secs(10) },
        stop: Stop = Stop { signal: .Term, grace: secs(10), scope: .Tree },
        needs: List<string> = [],             // inferred from config reads when the compiler can [v2]
    }
}

component Service postgres {
    name = "postgres"
    run = cmd"postgres -D ${data}"
    ready = .Exec(cmd"pg_isready -h localhost")
}

component Service api {
    name = "api"
    run = cmd"./api --port ${port}"
    ready = .Http("/healthz")
    healthy = .Http("/healthz")
    needs = ["postgres"]
}

supervise([postgres, api])?          // a LIBRARY LOOP: ordered by needs, restarted by policy, no daemon
```

```
$ avra explain service api --as systemd
  [Service]
  ExecStart=/srv/api --port 8080
  Restart=on-failure
  RestartSec=100ms
  RestartSteps=9
  RestartMaxDelaySec=30s               # from backoff
  StartLimitBurst=5
  StartLimitIntervalSec=10s            # from give_up
  KillSignal=SIGTERM
  TimeoutStopSec=10s
  KillMode=control-group               # from stop.scope = .Tree — full fidelity here
  After=postgres.service
  Requires=postgres.service            # BOTH: Requires alone does not wait

  DEGRADED — this target cannot express:
    ready = .Http("/healthz")
      systemd has no HTTP readiness. Emitted as Type=exec, which is
      WEAKER: the unit is "started" before the port answers.
      Honest fixes: ready = .Notify and sd_notify in the child, or
      --allow-degraded to accept the weakening.
    healthy = .Http("/healthz")
      systemd's only liveness is WatchdogSec from inside the process.
      NOT EMITTED. On k8s this projects exactly; here it is LOST.
  --strict makes any DEGRADED line a build error.
```

The supervisor is a loop over `Child` values, not a daemon (P14). The unit
file is a projection of the same record (P12). Erlang's three restart
strategies are NOT a field: the dependency graph already knows that a
`postgres` restart must restart `api`, and `needs` is a fact the compiler
can infer from which service's config reads which. `podman generate
systemd` says its output "may need further editing". **The DEGRADED block
is the feature**: it enumerates what the projection lost, so nobody trusts
a control that was never applied.

## IV.12 The fake that shares every line but the syscall

```avra
spec "release notes" {
    given "a tagged repository" {
        let fake = scripted(table<Script> {
            program | args                    | exit    | stdout
            "git"   | ["describe", "--tags"]  | .Clean  | "v1.4.0\n"
            "git"   | ["log", "--oneline"]    | .Clean  | "abc feat: x\n"
        })
        then "the version comes from the tag" {
            release_notes(fake).version == "v1.4.0"
        }
    }
}
```

`release_notes` takes a `dyn Runner`. Production hands it `host()`. The
capture caps, the judging law, the pipeline verdicts, the timeout — all
run above the seam, so the fake exercises them. Only `posix_spawn` is
faked. `avra run --dry-run` is the same trait with a `plan` binding.

## IV.13 The compiler, dogfooding

```avra
// packages/cli/src/commands/shared.av — after
let clang = cmd(process.clang, ["-w", "-O1"]).path(ll_path).path(runtime_obj).link_inputs(promised).flag("-o", out)
clang.run() catch .Failed(e, o) -> fail BuildError.link_failed(e, o.stderr)
```

`promised` is no longer free text. A dependency's `[link]` rows are TYPED
— `objects` (paths, `./`-prefixed), `search` (directories, emitted as
`-L<dir>` by us), `libs` (names matching `^[A-Za-z0-9_.+-]+$`, emitted as
`-l<name>`) — so no row can carry a `-`-leading token at all. `-fplugin=`,
`-Wl,`, `-specs=` are not filtered; they are unspellable by a dependency.
Raw flags exist for the ROOT package only, allow-listed by full-argument
regex, counted, `avra caps diff`-gated.

```avra
// packages/cli/src/commands/test.av — after: a verdict, never an int
match cmd(tool(binary)?, []).outcome()?.exit {
    .Clean -> 0,
    .Code(1) -> 1,
    .Code(n) -> wrecked("the suite's binary exited ${n}"),
    .Signal(s, _) -> wrecked("the suite's binary died of signal ${s}"),
}
```

## IV.14 What the compiler prints

```
$ avra explain process
  DECLARED — 3 tools, this package
    git     /opt/homebrew/bin/git 2.47.1    from=path   terminator --end-of-options (min 2.43.1 ✓)
    clang   /usr/bin/clang                  from=env CC terminator --
            a declared tool is an INTERPRETER: -fplugin. Your argv positions
            are the only thing between a dependency and RCE.
    tar     /usr/bin/tar                    from=path   terminator --
  REACHABLE — every program this binary can ever exec:
    /opt/homebrew/bin/git  /usr/bin/clang  /usr/bin/tar   …and nothing else. No shell is declared.
  ENVIRONMENT crossing to children: PATH(minted) HOME TMPDIR LANG=C TERM + SDKROOT
  HATCHES — counted, ratcheted
    ambient_env   0
    ambient_path  1   cli/commands/shared.av:191   (clang -o absolute)
    dynamic       0
  CONTAINMENT on this host (darwin)
    process group + TERM/grace/KILL            DEGRADED:
      a child that calls setsid() escapes the group and survives us
      exit DETECTION is exact (kqueue NOTE_EXIT); containment is not
      there is no parent-death signal on this platform. Nothing to enable.
```

```
$ avra caps diff --upgrade @acme.imaging 2.3.1 → 2.3.2
  ! PROCESS WIDENED by a PATCH release
      + /usr/bin/ffmpeg     [process.tools] ffmpeg, from=path, terminator "none"
  ! FILESYSTEM WIDENED as a consequence
      + /usr/bin/ffmpeg     READ_FILE|EXECUTE in the union Landlock ruleset
  build FAILED: a dependency may not widen [process] across a compatible upgrade.
  fix: pin it, or accept it at the site, counted and dated —
         [process.accept]
         "@acme/imaging" = ["ffmpeg"]   # reviewed 2026-09-04
```

---

# Part V — The canonical model

## V.0 The eight laws

Each deletes a named bug class; each has a diagnostic; Part IX names what
each cannot do.

1. **THE MINT LAW.** No expression names a program and no verb takes a
   command string. `process.<name>` is minted by a `[process.tools]` row
   and by nothing else; a literal's first word must name a declared tool;
   `tool(text)?` is the one widening and is counted. A shell is a
   declared tool named `sh` — spelled, counted, printed, diffed. When the
   argv row lands, `shell_word` and `binary_name`'s quoting are DELETED,
   never kept as fencing: fencing that survives the structural fix is
   fencing that will be trusted again.
2. **THE ONE-RESOLUTION LAW.** A `Tool` is resolved exactly once, at
   seal, to a printed absolute path (and where the kernel allows, to a file
   descriptor executed by `execveat`/`fexecve`, so there is no second walk
   to race). There is no PATH lookup at a call site. The child's own `PATH`
   is minted from the declared tools' directories.
3. **THE POSITION LAW.** A word built from data is emitted in the one form
   the callee cannot read as an option — fused to its flag, `./`-prefixed
   as a path, or after the tool's declared terminator — and a bare
   positional refuses a leading `-` at the widening. The terminator is a
   ROW (data, per the vocabulary seam rule), `"none"` is an honest
   declaration that fusing and prefixing are the only defence for that
   tool, and `min` is checked against the installed binary because a
   terminator it does not honour is a false one. The deep tier — a
   package per tool where dangerous flags are UNSPELLABLE — is what makes
   `allow = ["git"]` narrower than `allow = ["*"]`.
4. **THE UNTRUSTED LAW** [v2, with `Untrusted<string>`]. Untrusted text
   becomes a word or an environment value only through a named widening
   that refuses NUL, refuses emptiness, and refuses a leading `-`; no verb
   in this package takes an `Untrusted<T>`. `word()` is to argv what
   `leaf()` is to paths — the same words on purpose.
5. **THE INHERITANCE LAW.** A child inherits nothing that was not named:
   the environment is an allow-list over a printed minimal base; every fd
   is closed but the named slots; argv[0] is the `Tool`'s, so an empty
   argv (PwnKit's `argc == 0`) is unrepresentable; the cwd is a `Dir`.
   `base = "inherit"` is a counted hatch whose warning prints the
   denylist it just let through.
6. **THE PATH-BY-AUTHORITY LAW** [v1, with `Dir`]. A path reaches a child
   as a relative name under a directory the parent holds open and hands
   over as the child's cwd — `posix_spawn_file_actions_addfchdir_np` —
   never as an absolute string the parent materialized. This closes the fs
   doc's open item ("between materializing that string and the child's
   `open(2)` there is a window whose length the attacker chooses") for
   every tool that accepts relative input; `@ambient_path` is the counted
   hatch for the rest.
7. **THE DISCHARGE LAW.** A spawn answers a verdict that must be read,
   under a deadline, with a capture cap. `run()` judges by `ok_exits`;
   `outcome()` reads; an `Outcome` whose exit is never matched is F4604;
   there is no `wait()` that can deadlock because there is no verb that
   waits without draining; the deadline's kill goes to the GROUP.
8. **THE PROJECTION LAW.** The `[process]` block is the only truth: the
   compiler prints the complete list of programs the binary can run, the
   launcher's exec policy, AND what it could not emit — and fails the
   build when a dependency upgrade widens the list.

## V.1 The types

```avra
/// The right to run one binary. Unforgeable: minted, never typed.
/// `path` is absolute and was resolved exactly once.
type Tool = { name: string, path: string, terminator: string? }

/// What a program is told and how it is wired. A record with defaults;
/// `with` changes what differs; the position verbs append words.
type Command = {
    tool: Tool,
    args: List<string>,
    cwd: string? = null,             // [v1] a Dir, never text
    env: Env = minimal(),
    stdin: Stdin = .Closed,
    timeout: Duration? = null,       // the child's life
    drain_grace: Duration = secs(2), // output arriving AFTER exit — a grandchild holding the pipe
    max_capture: int = mib(16),
    ok_exits: List<int> = [0],
    stop_grace: Duration = secs(5),
}

/// Standard input's source. `Open` is a pipe held open for a started
/// child: `write` feeds it, `close_stdin` ends it.
enum Stdin {
    Closed
    Inherit
    Open
    Text(s: string)
    Lines(xs: List<string>)
    // [v2] Stream(ch: Channel<string>)
}

/// The environment a child sees: a base plus what the manifest passes.
/// `.Inherit` is the counted hatch.
enum Env {
    Only(pairs: List<EnvPair>)
    Inherit
}
type EnvPair = { name: string, value: string }

/// A child's exit — a verdict, never a count. `.Code(0)` cannot be built.
/// The substrate hands one tagged word (tag in the high half, payload
/// below, `0` meaning RUNNING), so success is never zero and SIGKILL can
/// never collide with exit 137; this enum is its one projection.
enum Exit {
    Clean
    Code(n: int)
    Signal(sig: int, core: bool)
}

/// The two captured streams, whole. `truncated` is set when a stream was
/// still open past `drain_grace` after the child exited — a grandchild
/// held the pipe — and we closed our end and kept what we had.
type Output = { stdout: string, stderr: string, truncated: bool }

/// A finished child, unjudged.
type Outcome = { exit: Exit, out: Output, took_ms: int }

/// One line from one stream, in arrival order.
enum Stream {
    Stdout
    Stderr
}
type Line = { stream: Stream, text: string }

/// A running child. Its scope is its lifetime; once ended it REMEMBERS
/// its outcome, so `stop` and `wait` answer it again and `read_line` has
/// nothing more.
type Child = { stage: Stage, command: Command, ended: Outcome? }

/// Programs joined by kernel pipes, left to right.
type Pipeline = { stages: List<Command> }
type PipeOutcome = { stages: List<Outcome> }

/// When a started child counts as up. No variant guesses.
enum Ready {
    Started
    Exit
    Line(pattern: string)
    Exec(probe: Command)
    // [v2] Port(n: int)
    // [v2] Http(path: string)
    // [v2] Notify
}

/// The supervisor's vocabulary.
enum Restart {
    Never
    OnFailure
    Always
}
enum Backoff {
    Fixed(d: Duration)
    Exponential(from: Duration, to: Duration)
}
type Intensity = { times: int, within: Duration }
enum Signal {
    Term
    Int
    Hup
    Kill
}
enum Scope {
    Process
    Tree
}
type Stop = { signal: Signal, grace: Duration, scope: Scope }
```

## V.2 The verbs

```avra
// minting
fn tool(name: string) -> Result<Tool, ProcessError>      // the ONE widening: PATH now, absolute forever
fn cmd(t: Tool, args: List<string>) -> Command              // literal words the author wrote

impl Command {
    // the position verbs — data lands where a dash is inert
    fn flag(self, name: string, value: string) -> Command      // "--name=value", or "-ovalue" for a one-letter option
    fn path(self, p: string) -> Command                        // "./p"  [v1: p: Rel]
    fn after_options(self, words: List<string>) -> Result<Command, ProcessError>   // terminator, then the words; `.Unplaceable` on a tool with none
    fn word(self, w: string) -> Result<Command, ProcessError>                      // a bare positional; refuses a leading `-`

    fn run(self) -> Result<Output, ProcessError>               // judged by ok_exits
    fn outcome(self) -> Result<Outcome, ProcessError>          // read: the exit is yours
    fn lines(self) -> Seq<string>                              // stdout by line; stderr drained, capped
    fn output(self) -> Seq<Line>                               // both streams, tagged, in order — recording is this verb's cost, never run()'s
    fn start(self, ready: Ready, within: Duration) -> Result<Child, ProcessError>   // returns when READY, or stopped and `.NotReady`
    fn pipe(self, next: Command) -> Pipeline
}

// OUR OWN exit is a verdict too — no language does this, so in every one of
// them a failure COUNT can wrap to success. `exit(.Code(failed))` reads wrong
// on purpose; the test runner writes `exit(if failed == 0 { .Clean } else { .Code(1) })`.
fn exit(v: Exit)

impl Pipeline {
    fn pipe(self, next: Command) -> Pipeline
    fn run(self) -> Result<Output, ProcessError>               // judged per stage: .StageFailed; SIGPIPE under a clean consumer is a success
    fn outcome(self) -> Result<PipeOutcome, ProcessError>      // every stage's exit and its OWN stderr; an empty pipeline is `.Empty`
    fn lines(self) -> Seq<string>                              // [v1]
}

impl Child {
    fn write(self, text: string) -> Result<int, ProcessError>  // stdin, when `Open`
    fn close_stdin(self)
    fn read_line(self, within: Duration) -> string?            // the next stdout line, or absent at the window
    fn lines(self) -> Seq<string>                              // [v1]
    fn stop(self) -> Exit                                      // TERM the group, grace, KILL, reap — and remembered
    fn wait(self, within: Duration?) -> Result<Outcome, ProcessError>
    fn pid(self) -> int
    fn is_alive(self) -> bool
}

// the bracket — `defer` landed; both forms stand
fn serving<T>(c: Command, ready: Ready, within: Duration, body: fn() -> T) -> Result<T, ProcessError>

// the many — bounded, never a fork bomb; losers stopped, never leaked
fn parallel(cs: List<Command>, limit: int) -> Result<List<Outcome>, ProcessError>   // a limit below one is one; one sibling's bound broken fails the whole
fn race(cs: List<Command>, stagger: Duration) -> Result<Outcome, ProcessError>      // the first to FINISH, success or failure; nothing to race is `.Empty`
fn supervise(services: List<Service>) -> Result<(), ProcessError>                    // [v1]

// the seam
trait Runner {
    fn outcome(c: Command) -> Result<Outcome, ProcessError>
}
fn run_through(r: dyn Runner, c: Command) -> Result<Output, ProcessError>            // judged by the command's ok_exits
fn host() -> dyn Runner
fn scripted(rows: List<Script>) -> dyn Runner                                        // a miss is `.Unscripted`
fn plan() -> dyn Runner                                        // prints; answers a dry Clean
```

`Seq<T>` is the tree's pull protocol when it lands; until then `lines()`
answers a `List<string>` behind a capped drain, and the streaming verbs
are the first rung of [v1].

## V.3 The errors

```avra
enum ProcessError {
    /// At mint: the name resolved to nothing on the PATH consulted.
    NotFound(program: string, searched: List<string>)
    /// At mint or spawn: the file exists and may not be executed.
    Denied(program: string, path: string)
    /// The working directory asked for is not a directory that is there.
    NoCwd(dir: string)
    /// An environment name that is not a name: empty, or holding `=`.
    BadEnvName(name: string)
    /// `run()` judged an exit outside `ok_exits`. The output rides along.
    Failed(exit: Exit, out: Output)
    /// A pipeline stage judged outside its `ok_exits`; every stage's outcome rides along.
    StageFailed(stage: int, exit: Exit, outs: List<Outcome>)
    /// The timeout fired; the child was stopped; what it said so far.
    TimedOut(after_ms: int, partial: Output)
    /// A stream exceeded `max_capture`; the child was stopped.
    TooMuch(stream: Stream, cap: int, partial: Output)
    /// `ready` did not come within the window; the child was stopped.
    NotReady(waited_ms: int, partial: Output)
    /// A positional word began with `-` and the tool declares no terminator.
    Unplaceable(word: string, program: string)
    /// A scripted runner has no row for this command.
    Unscripted(program: string, args: string)
    /// Nothing to run: an empty pipeline, an empty race.
    Empty(what: string)
    /// The supervisor gave up: `give_up` exceeded.
    GaveUp(service: string, times: int, within_ms: int)
    /// The host refused: errno and the call, never a sentinel string.
    Host(errno: int, call: string)
}
```

`kind()` is `process.not_found`, `process.failed`, `process.timed_out`,
… — `@std.errors`' own shape. `context()` carries the program's NAME and
resolved path, the argv, the cwd, the elapsed time. `suggestions()`
computes on `NotFound` only: the PATH entries searched and up to three
near-misses by edit distance, `.Medium` confidence at most.

Nothing here is a string tag. `"\0NULL"` and `"\0EOF"` — the old tree's
sentinels — are the antipattern this enum exists to delete.

## V.4 The manifest

```toml
[process.tools]
git   = { from = "path", terminator = "--end-of-options", min = "2.43.1" }
tar   = { from = "path", terminator = "--" }
find  = { from = "path", terminator = "none" }        # honest: fusing and ./ are the only defence

[process.tools.clang]
from       = "env"                                      # "path" | "abs" | "env" | "root" | "cli"
var        = "CC"
default    = "clang"
terminator = "--"

[process.tools.ld]
from = "root"                                           # inside a declared fs root: zero ambient
root = "toolchain"
at   = "bin/ld.lld"

[process.env]
base = "minimal"                                        # "none" | "minimal" | "developer" | "inherit" (counted)
pass = ["SDKROOT"]
set  = { LC_ALL = "C", TZ = "UTC" }

[process]
max_capture = "16MiB"
enforce     = "declared"                                # "declared" | "open"
```

**The environment law is the one most likely to fail in practice, and the
design is built around that.** `git` without `HOME` says "not a git
repository"; `cargo` without `CARGO_HOME` says "permission denied"; a
proxy without `HTTP_PROXY` says "cannot connect" — none of them mentions a
variable, and the predictable outcome is that the first tutorial writes
`base = "inherit"` and everyone copies it. Three concessions, all
mandatory or the law does not ship. (1) NAMED PROFILES, so the common
case is one honest word: `minimal` (PATH minted, `HOME`, `TMPDIR`,
`LANG=C`, `TERM` when stdio is a tty, `NO_COLOR=1`), `developer` (adds the
`*_HOME` variables, the proxies, `SSH_AUTH_SOCK`), `none`, `inherit`
(counted). (2) THE DIAGNOSTIC IS THE PRODUCT: `@std/process` carries a
`table<Needs>` — a program name and the variables it is known to want —
and a `.Failed` from a program in the table whose variable was not passed
says so: "`git` exited 128; `HOME` was not passed — add `pass = ["HOME"]`
or `base = "developer"`" (F4616). That table is DATA, per the vocabulary
seam rule, and the compiler never names a tool's needs. (3) The loader,
shell and interpreter names (`LD_PRELOAD`, `DYLD_INSERT_LIBRARIES`,
`BASH_ENV`, `PYTHONPATH`, …) can never be CONSTRUCTED from data by an
Avra program, even under `inherit` — a short, closed list that is never
legitimately set from application code.

**Provenance is the honest word.** `from = "path"` says "the machine's
PATH decided which binary this is" — once, at seal, printed. `from =
"root"` has no ambient component and is what a build should use. `from =
"cli"` is the deployment hatch: the SET of tools is fixed at compile time
and only the binding moves. A tool ending in `.bat`/`.cmd` is refused at
the declaration: Rust could not find a correct `cmd.exe` escaper
(CVE-2024-24576) and now fails at runtime; we fail at the manifest.

**The script rung.** A package with no `[process]` section may name any
tool a `cmd"…"` literal's first word spells, and the set of those words
IS its declaration — inferred, printed as an open set, refused under
`enforce = "declared"`. A *library* package never gets the script rung:
it is handed `Tool` values by its caller, exactly as it is handed a
`Dir`.

**The empty block is the strongest guarantee.** A package whose
`[process]` section is present and EMPTY declares that this binary never
runs another program — and on Linux the prelude can prove it with a
seccomp filter denying `execve` outright, which needs no pointer
dereference and no path list. That is stronger than any allow-list, and
it is what most programs should say.

**Ambient where the grant was made; a parameter where it is delegated** —
the fs doc's rule, unchanged.

## V.5 The diagnostics

| Code | Fires on |
|---|---|
| F4601 | a hole in a `cmd"…"`/`sh"…"` literal's program position |
| F4602 | `process.<x>` with no such tool — the manifest edit attached |
| F4603 | a bare `string` where a `Tool` is wanted — names `tool(s)?` |
| F4604 | an `Outcome` whose `exit` is never read |
| F4605 | `base = "inherit"` — note-severity, counted, prints the denylist as receipt |
| F4606 | a `sh"…"` stage whose program the manifest does not declare |
| F4607 | `stop()`/`write()` on a `Child` after `wait()` reaped it |
| F4608 | a hole inside `cmd(process.sh, ["-c", …])` — the one place text becomes a command again |
| F4609 | a `Child` that escapes its scope without `stop`/`wait` [v1 — `defer` landed; the law waits on escape analysis] |
| F4610 | an `extern fn` colliding with a process substrate row outside `@std.process` |
| F4611 | `after_options` on a tool declaring `terminator = "none"` |
| F4612 | a dependency upgrade that widens `[process]` — pin or accept, counted |
| F4613 | a `[link.raw]` row in a dependency's manifest (root package only) |
| F4614 | a `sh"…"` construct outside the subset: globs, `$VAR`, `$( )`, `;`, `&`, `~`, `eval` — each names the Avra way |
| F4615 | a `.bat`/`.cmd` tool declaration |
| F4616 | a child failed and a variable it is known to need was not passed — names it (note on `.Failed`) |
| F4617 | a loader/shell/interpreter variable name (`LD_PRELOAD`, `BASH_ENV`, …) built from data |
| F4620 | a pipeline stage failed — the stage, its argv, its own stderr |

```
error[F4603]: `cmd` will not take a program as text
  ╭─[deploy.av:21:9]
21 │ cmd("kubectl", ["apply", "-f", manifest])
   ·     ────┬────
   ·         ╰── a `string`; a program is an authority, not a word
──╯
help: mint it once, where the name arrives —
       let kubectl = tool("kubectl")?
fix:  cmd(kubectl, ["apply"]).flag("-f", manifest)
note: or declare it in avra.toml under [process.tools] and write
      `process.kubectl`; `avra explain process` will then print it.
```

```
error[F4614]: `sh` does not substitute commands
  ╭─[notes.av:7:16]
7 │ sh"echo on $(git rev-parse HEAD)"
  ·             ─────────┬─────────
  ·                      ╰── `$( )` turns text back into code — the thing `cmd` exists to prevent
──╯
fix: let rev = cmd"git rev-parse HEAD".run()?.stdout.trim()
     cmd"echo on ${rev}"
```

---

# Part VI — A command is a value the compiler runs in every direction

Everything above treats a `Command` as a thing you run. Take the same
leap the fs doc takes:

> A command is a value the compiler can run in every direction —
> **forward** it spawns, **backward** it prints the launcher's policy,
> **symbolically** it refuses a call, **generatively** it is your test
> double AND your cache entry, and **statically** it is the list of every
> program your binary can ever run.

## Move 1 — Statically: the blast radius is a list of names

Because the program position of every literal and every `cmd` is a
`Tool`, and every `Tool` is minted from a finite set of sites, the
compiler KNOWS every binary a program can execute — before it runs. `avra
explain process` (IV.14) prints it. A dependency cannot add `curl` to your
binary without `avra caps diff` failing the build. WASI can audit; Deno's
`--allow-run=git` enforces at runtime; here the set is a compile-time fact
and the diff is a build error.
**Holy shit:** `git diff avra.toml` is the complete review of what a
release can execute.
**Honesty, in the same breath:** the bound is on the CALL, never the
callee. Deno's own docs say `--allow-run` "essentially invalidates the
sandbox", because a program that may run `deno` may run `deno
--allow-all`. Every useful tool is an interpreter; the list bounds which
doors, and the position law plus the per-tool grammars are what narrow
the rooms.

## Move 2 — Backward: one declaration, the launcher's rules

```
$ avra explain hardening --target linux-6.12
  ENFORCED BY US — one ruleset, fs roots and exec targets, applied at caps.seal():
    landlock_restrict_self  ABI 6, layers 2/16
      /etc/thumbd        READ_FILE|READ_DIR
      ./var/data         READ_FILE|WRITE_FILE|MAKE_REG|REMOVE_FILE|REFER
      /usr/bin/clang     READ_FILE|EXECUTE      ← [process.tools] clang
      /usr/bin/git       READ_FILE|EXECUTE      ← [process.tools] git
    prctl(PR_SET_NO_NEW_PRIVS, 1)   — sudo, pkexec, ping, mount will fail for this process and every descendant
  WHEN [process] IS EMPTY (not this build):
    seccomp SCMP_ACT_ERRNO on execve, execveat, fork, vfork, clone — exact, no pointer deref
  EMITTED FOR YOUR LAUNCHER — inert unless applied:
    systemd   NoExecPaths=/  ExecPaths=/usr/bin/clang /usr/bin/git
    openbsd   pledge("stdio rpath wpath cpath proc exec", "stdio rpath")
              unveil("/usr/bin/clang", "rx"); unveil("/usr/bin/git", "rx")
  NOT EMITTED, and why
    seccomp exec allow-list: IMPOSSIBLE. BPF cannot dereference pointers, so no
      filter can name a path. Any tool claiming one is filtering the syscall
      number and hoping.
    k8s: no securityContext field expresses "these binaries only". The honest
      projection is a read-only rootfs plus an image containing only these.
  DEGRADED
    darwin: NO kernel layer. sandbox_init is deprecated with no replacement.
      Tier 0 only — say so in your threat model.
```

Landlock layers are conjunctive and `FS_EXECUTE` is a filesystem right,
so fs roots and exec targets MUST compile into one ruleset, sealed once:
**declaring a tool widens the process's filesystem authority by exactly
one file**, and `explain hardening` prints that line beside the roots.
That coupling is not a wart; it is the design telling the truth about
what a tool declaration costs.

## Move 3 — Symbolically: the deploy target's tools are checked on your laptop

```toml
[process.tools.clang]
from = "env"; var = "CC"; min = "17"
```

`avra check --target prod` resolves the tool against the target's
declared toolchain and refuses a version the code's flags need but the
target lacks — in dev, before the CI machine exists. The same shape as
the fs doc's `as = "object"`: develop against the weakest thing you will
deploy on.

## Move 4 — Generatively: the fake is the same code, and so is the cache

`scripted(table)` (IV.12) runs every law above the syscall. Because a
`Pipeline` reifies its stages, `scripted` answers per stage — a test that
`grep` returning `1` in stage two is reported as `.StageFailed(1, …)` runs
with no processes at all. And `--dry-run`, record, replay and the build
cache are the same trait keyed by the same content hash: a replay miss is
not "no recording" but a DIFF against the nearest recorded argv.

## Move 5 — Forward, and cached: a process with declared inputs is a pure function

```avra
// [v2] the compiler's own link step, as an Action
let link = action(cmd(process.clang, flags)) with { reads: [ll_path, runtime_obj], writes: [out] }
link.run()?                 // hash of program + argv + env + read digests → the cached `writes`
```

Bazel, Nix, Turborepo and ccache exist to add this to build systems from
the outside, and the honest reading of all four is the load-bearing fact:
**there are exactly two working architectures** — sandbox-and-fail (deny
undeclared reads so a wrong declaration is a loud error) and
observe-and-key (derive the key from what actually happened). Avra's
unfair advantage: when `reads` and `writes` are `Rel` values against a
`Dir`, ONE declaration is the cache key, the sandbox policy and the
verification — **an undeclared read is an EPERM, not a stale cache hit**.
Caching is opt-in per action, env is empty by default (Turborepo made
strict mode the default for this reason), `--verify-hermetic` runs the
action twice from different directories with a shifted clock and diffs
the bytes, and no hermeticity is claimed on macOS — Nix itself defaults
`sandbox = false` there.

## Move 6 — The evaluator runs the same program

`avra run` must spawn what the native binary spawns, or the corpus cannot
say `eval == native` for anything that touches a child. The interpreter
hosts runtime rows by an exhaustive `RtHost` match today; the process
rows join it (Part VIII asks for the cheaper door: one trampoline that
hosts EVERY runtime extern by name). The differential — the memory
doctrine's referee — then covers subprocesses too.

## The apex

> **Avra is the first language in which the set of programs a binary can
> execute is a value the compiler prints.** So an author who never sleeps
> may write whatever it likes against `git`: the worst thing the program
> can run was decided in three lines of manifest before the first line of
> code existed. You stop reviewing the shell-outs and start reviewing the
> list.

**Honesty rider, in the same breath:** the list bounds WHICH programs run,
not what they do once running. A child is a foreign program with the
parent's kernel authority (Part IX). The list is a real bound, and it is a
bound on the set of doors, not on the rooms behind them.

---

# Part VII — Working backwards: the ladder

Each rung names what it delivers, what it needs, and who owns the piece.
A rung is entered by the corpus, never by declaration.

## v0 — this week, lane B alone, over what the tree has today

**Delivers:** `@std/process` as a package: `Tool` + `tool(name)?`,
`Command` with defaults and `with`, the POSITION VERBS (`flag` fuses,
`path` prefixes `./`, `after_options` uses the tool's declared terminator,
`word` refuses a leading `-`), `Exit`, `Output`, `Outcome`, `ok_exits`,
`ProcessError` + `impl Error`, `run()` (judged) and `outcome()` (read),
`Env` from a minimal base, `Stdin.Text`, timeouts, capture caps,
`Pipeline` over kernel pipes with per-stage stderr and the F4620 voice,
`Child` with `start(ready)`/`write`/`stop`/`wait`, the `serving` bracket,
`parallel(limit)`, `race(stagger)`, `Runner` with `host()`, `scripted()`
and `plan()`, `exit(Exit)` as the program's own verdict, the `table<Needs>`
behind F4616, and the `minimal`/`developer` env profiles. Spec tests
beside it against `scripted`, and against `host` for the substrate. `corpus/native/process.av` proving native; a
`corpus/process/` package the moment the evaluator hosts the rows.

**Needs from the substrate (Part VIII #1):** the C rows, in
`runtime/avra_runtime.c`, headered per THE HEADER LAW. Until they land,
v0 compiles against `avra_spawn_status` alone and delivers `outcome()`
without capture — honest and small.

**Needs from the language:** nothing. `with`, defaults, enums with named
payloads, traits + `dyn`, `catch`, tables, zero-arg thunks and bracket
fns all exist. Names avoid the reserved set (`spawn`, `select`,
`channel`, `await`): the verb is `start`.

**Dogfoods:** `shared.av:180` (clang) and `test.av:44` (the suite binary)
move onto it, deleting `shell_word`. The terminator for the v0 tools is a
field on `Tool`, set by `tool(name)` from a small in-package table
until the manifest mints it.

## v1 — the literals, the mint, the seal, the scope

- **`cmd"…"` and `sh"…"`** — the embedded-sublanguage contract's first
  product clients. `cmd""`: words, quotes, typed holes (`string` → one
  word; `List<string>` → N words; `Rel` → `./`-prefixed AND an entry in
  the command's reads; `Tool` in program position; anything else
  refused) → `Command`. `sh""`: the tiny subset — `|`, `&&`, `||`,
  newline, `<`, `>`, `>>`, `2>`, `2>&1`, quoting, holes → `Pipeline`.
  Refused PERMANENTLY, each with a diagnostic naming the Avra way: globs,
  `$VAR`, `$( )`, backticks, `eval`, `~`, `;`, `&`, arithmetic, subshells,
  builtins. Anything the subset accepts means exactly what POSIX means;
  everything else is refused; there is no third category (xonsh's
  namespace heuristic is the warning). Owner: the grammar-lit owner with
  lane B writing the grammars, builders and voices in `@std/process`.
- **The mint** — `manifest.av` learns `[process]` as a KNOWN section that
  ERRORS on unknown keys; `process.<name>` synthesized as a decl with F4602
  on a miss. The same compiler work the fs doc's `fs.<root>` needs — one
  mechanism, two clients.
- **`caps.seal()`** — ONE call, fs roots and exec targets in one ruleset
  (Part VI Move 2). Shared with `@std.fs`.
- **Streaming** — `lines()`/`output()` as `Seq<T>` once the pull protocol
  exists.
- **F4609** on `defer` (landed 2026-09-05, `errdefer` with it) — the escape law itself.
- **`Dir` for `cwd`** and `Rel` for `path()` the day `@std.fs` mints them
  — the Path-by-Authority law goes live.
- **`Service` + `supervise`** with backoff, intensity, TERM/grace/KILL
  over the group, `Ready.Exec`; the projection to ONE target the team
  uses (compose or systemd) WITH the DEGRADED block; `avra explain
  services --plan`.
- **Evaluator hosting** of the rows → `corpus/process/` says eval == native.
- **Typed `[link]` rows** (Part VIII #9) — the build machine's steps two
  and three.

## v2 — the substrate

- **`|>`** lands (the lexer already continues on it): IV.8 reads as written.
- **Fibers + channels**: three fibers per child; `Stdin.Stream(ch)`;
  `Ready.Port`/`.Http`/`.Notify`; `spawn { }` scopes own children;
  `supervise` becomes a select loop. The poll loop becomes the
  scheduler's and the surface does not move.
- **`Untrusted<string>`** (the strings doc's Q2): `word()`, `flag_value()`
  and `after_options()` as the named widenings; the Untrusted law goes
  live.
- **Per-tool grammar packages** (`@std.process.git`, `.tar`, `.clang`):
  flags minted from the tool's declared vocabulary, so the dangerous ones
  are unspellable. Rows in a `table<ToolVerb>`, never a dispatch arm; a
  staleness gate against the installed version.
- **`Action`** (Move 5) → the compiler's build cache; `--verify-hermetic`.
- **`isolated(() -> …)`** — a closure run in a forked child, its answer
  marshalled back; the test runner's cure for "a trap kills every case
  after it" (test_run.av's own words). Needs a `bytes` type.
- **Backward projections** (Move 2/3) as `avra explain hardening` grows
  a `process` section beside `fs`; cgroup-delegated containment on
  Linux; k8s as a second projection target once one is proven.

---

# Part VIII — The asks

Numbered, so each can be granted or refused by name.

1. **THE SUBSTRATE ROWS** (runtime owner; lane 0 is landing the argv row
   tonight). In `runtime/avra_runtime.c`, headered, TWELVE functions over a
   C-side handle table — the seam carries only `I64 | Ptr | Void`, so a
   spawn cannot answer a pid plus three fds, and the handle integer is what
   makes ownership trivial:
   `avra_proc_spawn(file, argv, envp, cwd, flags) -> handle | -errno`;
   `avra_proc_run(file, argv, envp, cwd, flags, stdin_text, timeout_ms,
   grace_ms, max_bytes) -> finished handle | -errno` (THE ONE-SHOT: spawn,
   pump, escalate, reap — in C, because the pump has three ways to hang
   and Avra's string box carries no length, so an Avra drain loop could not
   hold a chunk containing NUL); `avra_proc_poll(h, ms) -> events`;
   `avra_proc_write(h, bytes, len)`; `avra_proc_stdin_close(h)`;
   `avra_proc_take(h, stream) -> owned text` (everything buffered since the
   last take); `avra_proc_signal(h, sig, to_group)` (`-ESRCH` once reaped —
   the pid-reuse guard); `avra_proc_status(h) -> tagged word` (`tag << 32
   | payload`; `0` is RUNNING, success is not zero, spawn failure is
   `-errno` and never a status, so `127` stops meaning three things);
   `avra_proc_pid(h)`; `avra_proc_close(h)` (kills the group if alive,
   reaps, frees, bumps the handle generation — idempotent);
   `avra_proc_which(file, path)`; `avra_proc_error_text(err)` (immortal).
   Non-negotiables the report found: `posix_spawn`, never `posix_spawnp`
   (it searches the PARENT's PATH, and on Darwin resolves against the
   parent's cwd even with a chdir action) — we resolve from the CHILD's
   envp, skipping empty and relative PATH elements; `POSIX_SPAWN_SETSIGDEF`
   on every catchable signal AND `SETSIGMASK` empty (our ignored SIGPIPE
   would otherwise infect every child); `POSIX_SPAWN_CLOEXEC_DEFAULT` on
   Darwin, `O_CLOEXEC` + `close_range` on Linux (Darwin has no `pipe2`, no
   `close_range`, no `fexecve` — SDK-verified); one `poll` set holding
   stdout, stderr and pending stdin, always; the poll timeout recomputed
   every iteration from a monotonic deadline; drain to EOF on both THEN
   reap, once, then `pid = -1`; `addchdir_np` by `dlsym` under both its
   names (renamed at macOS 26). `-errno` everywhere, never a sentinel,
   never a trap (a trap inside the pump leaves a live child). `system()`
   and `avra_shell_exec_status` are DELETED, not fenced. The report's 55
   numbered pitfalls are the implementation checklist. Lane B writes the
   library over these and will write the C too if granted the runtime
   file for this slice.

2. **THE ROWS HOSTED IN THE EVALUATOR** (interpreter owner). The
   interpreter consults `rt_sig_of` BEFORE the externs table, so each of
   the twelve gets an `rt_sigs()` row with an `RtHost.Proc*` variant and a
   thin arm that calls the SAME C — eval == native holds by construction,
   because there is exactly one implementation, not two that agree. That
   is also the real reason for the ≤ 12 budget: each row costs a variant
   and an exhaustive arm. The cheaper door for the whole std-lib lane
   remains worth its own ask: one `dlsym` trampoline keyed on the row's
   `RtKind` shape (`RtHost.Native`) hosts every runtime extern with zero
   per-row arms, and `corpus/native/` shrinks to the LLVM seam alone. Not
   blocking for process; blocking for a lane that will ship seven
   packages.

3. **`[process]` IN THE MANIFEST READER** (whoever owns `manifest.av`;
   lane D's sweep or the fs door). A known section whose unknown keys
   ERROR, and `process.<name>` synthesized as a decl. Shared with `fs`.

4. **THE `cmd"…"` AND `sh"…"` LITERALS** (grammar-lit owner). The
   embedded-sublanguage contract's first product clients. Lane B supplies
   the grammars, the typed builders and the F4601/F4606/F4608/F4614
   voices inside `@std/process`. The research is unanimous that
   `cmd""`-with-holes-as-words is the single highest-confidence item in
   the whole design; the `sh""` subset is the ambitious half and is safe
   ONLY because it is tiny and its refusals are laws, not a backlog.

5. **`defer`** — LANDED by lane B (slice D, 2026-09-05) with `errdefer`; the
   `Child`'s scope law rides it, F4609 waits on escape analysis.

6. **THE NAME DECISION, revised:** two literals, not one. `cmd""` compiles
   one command (honest: no shell is involved and the name says so);
   `sh""` compiles the tiny pipeline subset (honest: it accepts shell
   SPELLING). `sh.raw(text)` is the counted hatch that actually runs
   `/bin/sh -c` — without it people will write `cmd(process.sh, ["-c",
   s])` and we get the hazard with none of the accounting. Measured on
   generated code before the mint makes any of it law.

7. **A NAME DECISION:** `Exit.Clean` for the zero exit (`Ok` collides in
   the eye with `Result.Ok`; `Success` is long). Open to `.Zero`.

8. **THE `@std/time` STUB** in the same slice: `Duration` as `{ ms: int }`
   with `ms(n)`/`secs(n)`/`mins(n)`, `now_ms()`, `elapsed_text(d)` —
   process needs a duration on day one and `@std/time` is lane B's
   anyway. The `5s` literal waits on the literal machinery.

9. **TYPED `[link]` ROWS** (manifest owner + lane 0's fix). `flags` dies;
   `objects` (paths), `search` (directories → `-L`), `libs` (names →
   `-l`), `frameworks` replace it, so a dependency cannot spell a
   `-`-leading token; `[link.raw]` is a root-package-only full-argument
   regex allowlist (Go's `CGO_CFLAGS_ALLOW` design, adopted after
   CVE-2018-6574), counted and diffed. This is the build machine's steps
   two and three; argv-lists alone leave `-fplugin=` open.

10. **`caps.seal()` SHARED WITH `@std.fs`** (whoever lands the fs door
    first). Landlock layers are conjunctive; exec targets are
    `FS_EXECUTE` rights on files; one ruleset or neither is sound.

---

# Part IX — Honest limits

**A child is a foreign program.** Once it runs, it holds the parent's
kernel authority: every file the uid can open, the network, the ability
to spawn again. The program list bounds WHICH doors; nothing here bounds
what a program does behind its door. `allow = ["git"]` is `allow = ["*"]`
until an argv grammar constrains it: every useful tool is an interpreter —
`clang -fplugin`, `git -c core.pager=`, `tar --checkpoint-action=exec=`,
`ssh -oProxyCommand=`, `curl -K`. The position law is load-bearing on
every tool; the grammars are what make a spawn capability meaningfully
narrower than "run anything".

**Enforcement is three tiers and every claim names its tier.** Tier 0
(PROVEN, all platforms, `avra run` included): the type checker — no
undeclared program, no command string, no data in an option position, an
allow-listed env, named fds and cwd, a minted argv[0]. Defeated only by
counted hatches, declared FFI, and the child itself. Tier 1 (ENFORCED,
after `caps.seal()`): Linux ≥ 5.13 Landlock `FS_EXECUTE` + `no_new_privs`
— the process and every descendant may execute only the declared files,
forever; an empty `[process]` block gets a seccomp deny of `execve`,
exact and kernel-proven; FreeBSD `cap_enter` + `fexecve` — the only
platform where the design's model and the kernel's are the same model;
OpenBSD `pledge` execpromises. **macOS: nothing.** `sandbox_init` is
deprecated with no replacement; Tier 0 only, say so in the threat model.
Windows: nothing portable, and `.bat`/`.cmd` are refused at the
declaration. Tier 2 (EMITTED, inert): systemd `ExecPaths=`, `pledge`
lines, an AppArmor profile — applied by a launcher, verified by nobody.
Not applied under `avra run`: the interpreter has no prelude.

**`--` is a convention, not a mechanism.** git repurposed it for
pathspecs and needed `--end-of-options` (2.24), honoured by `checkout`
and `reset` only from 2.43.1; `find` and `dd` have no terminator at all;
`curl -K` reopens the option surface from inside a file; and
CVE-2023-22809 (sudoedit) is `--` used AS the payload. That is why the
terminator is a per-tool ROW with a `min`, why `"none"` is an honest
value, and why fusing and `./`-prefixing carry the weight.

**Containment is unequal and the demo will lie unless it prints.** Linux
cgroup v2 `cgroup.kill` is atomic against forks; Windows job objects
survive our own crash; macOS has a process group and nothing else — a
child that calls `setsid()` escapes it. `PR_SET_PDEATHSIG` is REFUSED as
the mechanism: it is thread-scoped with a documented unclosable race.
`avra explain process --containment` prints the platform's tier, and
`--strict` makes a DEGRADED line a build error.

**The environment allow-list is a policy, not a proof.** A child that
inherits `HOME` can read `~/.ssh`. `pass` narrows what the child SEES in
`environ`; it does not narrow what the child can OPEN. And on Darwin SIP
already strips `DYLD_*`/`LD_*` for restricted binaries, which mitigates
one class of env injection and none of the others.

**Interleaving is approximate.** Two pipes, one poll loop: `output()`
orders lines by ARRIVAL at the parent, which is the child's write order
only up to the kernel's pipe scheduling. A merged stream (one pipe for
both) is exact and loses the tag. `2>&1` in the literal gives the other;
merging by default is REFUSED (PowerShell's byte-corruption carve-out is
the cautionary tale).

**SIGPIPE is decided, not inherited.** The runtime ignores it; an EPIPE
from a stage whose consumer already finished (`… | head`) is a success,
any other EPIPE is a failure, and both are golden-tested — Rust inherited
`SIG_IGN` from a removed green-thread runtime and never documented it.

**Text is NUL-terminated.** Avra's string box carries no length, so a
child that emits a NUL byte truncates the captured text at the first
zero. v0 documents it and routes binary output through a file; a `bytes`
value category is a CORE event for the sugar backlog, not for v1's
twelve. Encoding is not decoded per chunk — lines are split with a
retained tail — so UTF-8 never tears at a read boundary.

**Capture changes the program.** A child that detects a tty prints
colour, pages, and prompts; captured, it does none of those. The minimal
base sets `NO_COLOR=1` and `LC_ALL=C` so parsed output is stable across
machines and locales; a passthrough run (`stdin: .Inherit`, streams
inherited) gets the terminal and none of that. The choice is forced,
never guessed.

**Stderr is data, never a verdict.** A program that exits clean and
writes to stderr succeeded; one that exits `1` silently failed. The
"success but stderr" heuristic is refused — the exit is the only verdict
and stderr rides along as evidence.

**`Seq` does not exist yet.** `lines()` in v0 is a capped list. The
streaming promise is v1's, and the cap is what makes the v0 verb safe to
ship at all.

**The projection must print its losses or it is net-negative.** A
generated unit that silently drops the liveness probe is worse than none,
because someone will trust it. The DEGRADED block is not decoration.

**The old drafts' lessons, named.** `bootstrap/packages/std-process`
passed JSON strings across the seam, decoded them with a hand scanner,
used `"\0NULL"` for absence and `"\0EOF"` for end-of-stream, typed
`args: string`, and exposed `is_alive(handle: int)` on a reusable pid.
`xphase7`'s `$"…"` spliced holes as TEXT and re-split them (CWE-78 by
construction) and returned a bare `string` (two thirds of the verdict
dies); its `race` never killed the losers; its `on main_end { kill }`
missed grandchildren; its `managed` component restarted with no backoff;
its `channel.merge` had a data race. Every one is a named antipattern
above. Two ideas survive: `isolated(() -> …)` (v2, on a `bytes` type),
and the instinct that a supervised service is a declaration.

**Eight of twenty everyday tasks stay longer than bash.** `for f in *.log;
do gzip $f; done` is three lines here (a glob, a loop, a `cmd`). The price
of a program that cannot be injected is that it is a program.

**The ergonomics bet is a bet.** If a model handed `cmd("git", …)` and
F4603 does not, in-loop, write `let git = tool("git")?` and move on —
or handed `.word(user_input)` and F4611 does not turn it into
`.after_options([…])` in one turn — this design is worse than
`subprocess.run`. Measure it on generated code, three model families, two
hundred programs, first-shot compiles counted, before v1's mint makes the
shape law. Nothing in this document matters as much.

---

# Part X — Slogans

1. > A command is a `string` asked to be a **program**, its **arguments**
   > and their **grammar** at once. Text is forgeable; an authority may
   > never be. Split them and there is nothing left to inject.

2. > The shell's spelling, compiled to the shell's absence.

3. > argv-as-a-list deletes the shell. It does not delete the injection.
   > The attacker stops writing `;` and starts writing `--`.

4. > A dash is not filtered. It is moved to where it means nothing — fused
   > to its flag, behind `./`, after the terminator.

5. > The program is the authority. It is spelled, never computed — and
   > resolved once, so there is no window between "which git" and "run it".

6. > An exit is a verdict, never a count. `run()` judges; `outcome()`
   > reads; and there is no verb that answers the output while forgetting
   > the exit.

7. > A hole is one word. However many spaces, semicolons or newlines it
   > holds, the child receives it as one argument, because there is no
   > second parser to hand it to.

8. > What crosses to a child is what you named. The allow-list is the
   > mechanism; the denylist is the receipt.

9. > `pipefail` is not a flag. It is the data: every stage's exit and
   > every stage's own stderr, in a value you can match.

10. > A child belongs to a scope. When the scope ends, so does the child —
    > TERM, a grace, KILL, the whole group — and `start` returns when the
    > child is READY, not when it exists.

11. > The fake is not a fake, and neither is the dry run, the cassette or
    > the cache: one seam, one hash, five bindings.

12. > The set of programs a binary can run is a compile-time fact. Print
    > it, diff it, fail the build on it. You stop reviewing the shell-outs
    > and start reviewing the list — and the empty list is the strongest
    > thing a program can say.

13. > A projection that does not print what it lost is a control nobody
    > applied. The DEGRADED block is the feature.

14. > The compiler links with `clang` through this library, or the library
    > is not finished. Dogfooding is not a demo; it is the acceptance test.

> Give the compiler the program, the words and their positions
> separately, and the sandbox rule, the unit file, the supply-chain diff,
> the test double, the cache entry and the fix-it patch all turn out to be
> printouts of one three-line manifest — because there was only ever one
> thing to know: which doors this program may open, and where each word
> lands on the way through.
