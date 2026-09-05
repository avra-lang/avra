# `@std/process` — design research

*What would make a language-integrated process library make people say "holy shit",
and which of those ideas survive contact with the OS.*

Read-only research pass. Nothing was built, run, or edited. Every non-obvious
claim carries a URL; anything I could not verify against a primary source is
marked **[unverified]**.

---

## 0. The frame

### 0.1 The reframe worth stealing

The filesystem sibling doc (`THE_ROOT_IS_THE_ONLY_DOOR`, Part V) says: *a root is a
value the compiler runs in every direction — forward it opens a file, backward it
prints a sandbox policy, symbolically it refuses a call, generatively it is your
test double.*

The same sentence, pointed at processes:

> **A command is not a string. It is a value the compiler runs in every direction.**
> Forward it runs a child. Backward it prints a systemd unit, a compose service, a
> k8s container and an `--allow-run` allowlist. Symbolically it refuses at compile
> time — an undeclared binary, an unexpandable glob, a widened capability on a minor
> upgrade. Generatively it is the test double *and* the cache entry, because those
> are the same hash. Sideways it is a cache key, a sandbox policy and a dry-run plan.

Everything in this report is a projection of that one sentence. The ideas that score
highest are the ones where a single declaration serves four directions; the ideas
that score lowest are the ones that only run forward.

### 0.2 The one honest limit that governs everything

This must be printed in the same breath as every claim below, or the whole design is
a lie:

> **A subprocess is where every guarantee ends.** The child does not inherit your
> sandbox, your capability set, your cancellation, or your types. It is a separate
> program with its own privileges.

Deno documents this about its own permission system in the bluntest available terms:
subprocesses "do not run in a security sandbox"; child processes "can access system
resources regardless of the permissions you granted to the Deno process that spawned
it"; `--allow-run` "essentially invalidates the Deno security sandbox", and
`--allow-run=deno` in particular lets a script re-launch itself with `--allow-all`
([Deno permissions](https://docs.deno.com/runtime/reference/permissions/),
[Deno security](https://docs.deno.com/runtime/fundamentals/security/)).

So the honest scope of everything below is: **Avra can bound and describe what *your
program* runs. It can never bound what the child does.** The value is real — it is
exactly the value Bazel gets from `aquery` and Nix gets from a derivation — but it is
a bound on the *call*, not on the *callee*. Every "holy shit" in section 8 is subject
to this line.

---

## 1. Critique of the old `xphase7_channels_std_process.md` draft

Read first, because several of its mistakes are load-bearing for the rest of the report.
The draft is a good *feature inventory* and a bad *contract*. Fourteen specific
problems, roughly in order of severity:

1. **`$"echo hello ${name}"` is CWE-78 by construction.** The draft's own
   implementation table says `$"..."` "desugars to `process.run` + split" — i.e. the
   interpolated value is spliced into text and then re-split on whitespace. A name
   containing a space breaks it; a name containing `;` owns the machine. This is the
   single defect that most needs fixing, and section 7 is the fix.
2. **`$"..."` returns a `string`, discarding the exit code and stderr.** Test 2.3 has
   no way to observe failure at all; Test 2.4's `catch` only catches the *spawn*
   failing, not the command failing. A process result is a three-part verdict
   (stdout, stderr, status) and the sugar throws two thirds away.
3. **`race` never kills the losers.** "first one wins, rest silently fail" — the
   losing `sleep 0.5` keeps running after `main` returns. This is precisely the
   orphaned-process bug that structured concurrency exists to delete (section 3).
4. **`on main_end { handle?.kill() }` does not kill the child's children.** `kill(pid)`
   signals one process. `sh -c "server &"` leaves the server. Containment needs a
   process group, a job object, or a cgroup — see section 3.2.
5. **The `managed` component restarts with no backoff and no intensity limit.** Its
   `monitor()` loop calls `start()` immediately on `code != 0`, capped only by
   `max_restarts: 3`. A crash-looping child spins the CPU. Erlang (intensity/period)
   and systemd (`RestartSec=`, `StartLimitBurst=`) both learned this decades ago.
6. **Everything crosses the FFI as JSON.** `avra_process_run(cmd, json.stringify(args),
   "{}")`, and `Channel<T>.send` does `json.stringify(value)` per message. That is a
   P4 violation (a channel send allocating and parsing JSON), and a correctness one:
   JSON cannot carry bytes, so any stdout that is not valid UTF-8 is corrupted or lost.
7. **String sentinels as control flow.** `if val == "\0NULL"`, `if line == "\0EOF"`.
   The house rule is explicit: *no string tags or string-matching to detect behavior.*
   These are `T?` and a closed channel.
8. **`process.stream` swallows the exit status and does not typecheck.** It is declared
   returning nothing yet uses `?` on `spawn(...)`, and the process's final status is
   simply dropped — a stream that ends because the command *failed* is
   indistinguishable from one that ended normally.
9. **`process.pipe(input: string, ...)` buffers the whole upstream output in memory.**
   Test 2.10 pipes `cat file` through `grep` through `sort` by materialising each
   stage's stdout as a `string`. A 10 GB file OOMs. There is no back-pressure story at
   all, and the 64 KiB pipe buffer that makes real pipelines work never appears.
10. **`process.parallel(...fns)` is an unbounded fork.** No concurrency limit; a list
    of a thousand commands is a fork bomb. It also conflicts with two documented bs2
    limits (fn-typed arguments carry no generic evidence; indirect calls cap at three
    arguments).
11. **`channel.merge` has a data race in the reference implementation.** `mut alive =
    channels.length` is decremented from N spawned fibers with no synchronisation, and
    `if alive == 0 { out.close() }` is a check-then-act on shared mutable state.
12. **Readiness is one weak mechanism.** `wait_for_output("ready", timeout: 5s)` —
    substring-matching a log line is the *least* reliable of the five readiness kinds
    (section 2.1), and it consumes the output stream, so you cannot also read it.
13. **No stderr separation, ever.** Every stage's stderr is either dropped or merged.
    In a pipeline you cannot tell which stage complained.
14. **No capability, no root, no manifest.** `process.run` is a free function on an
    ambient global. This is the exact ambient-authority shape that the filesystem doc
    spent 1,200 lines deleting. Whatever `@std/process` ships must be minted from the
    manifest like every other power.

What the draft got *right*, and should be kept: processes and channels are the same
substrate; a process is a stream source; `select` between a process and a timer is the
right shape for "wait for ready or time out"; the `managed` component's *instinct* —
that a supervised service is a declaration, not a script — is correct and is the
strongest idea in the document. It just needs the other ten knobs and a projection.

---
## 2. Supervision — `component Service` as the one truth

### 2.1 What it is

Six families of software independently invented the same declaration, and each spells
it differently:

| Concept | Erlang/OTP | systemd | Kubernetes | Compose | process-compose | s6-rc |
|---|---|---|---|---|---|---|
| what to run | `start: {M,F,A}` | `ExecStart=` | `command`/`args` | `command` | `command` | `run` script |
| when it is up | (linked, immediate) | `Type=notify` + `READY=1` | `startupProbe` | `healthcheck` | `readiness_probe`, `process_log_ready` | `notification-fd` |
| still healthy? | (exit signal only) | `WatchdogSec=` + `WATCHDOG=1` | `livenessProbe` | `healthcheck` | `liveness_probe` | — |
| on death | `restart: permanent/transient/temporary` | `Restart=` | `restartPolicy` | `restart:` | `availability.restart` | always |
| give up when | `intensity`/`period` | `StartLimitBurst`/`IntervalSec` | CrashLoopBackOff | `on-failure:N` | `max_restarts` | — |
| backoff | (none) | `RestartSec`,`RestartSteps`,`RestartMaxDelaySec` | exponential, fixed | (none) | `backoff_seconds` | — |
| how to stop | `shutdown: ms`/`brutal_kill`/`infinity` | `KillSignal`,`TimeoutStopSec`,`FinalKillSignal`,`KillMode` | `preStop`, `terminationGracePeriodSeconds` | `stop_signal`, `stop_grace_period` | `shutdown{command,signal,timeout}` | `finish` script |
| depends on | (child order) | `After=`/`Requires=`/`BindsTo=` | initContainers/sidecars | `depends_on.condition` | `depends_on.condition` | `dependencies.d/` |
| restart together | `one_for_one`/`rest_for_one`/`one_for_all` | `PartOf=`/`BindsTo=` | (pod) | `depends_on.restart` | — | — |

That is **nine concepts**. Everything else in those six systems is spelling. A real
project maintains three to five copies of this table — a Procfile for dev, a compose
file for CI, a systemd unit or a k8s manifest for prod — and they drift, and the drift
is where outages come from. Axis 19.1 of Avra's spec already names this: *"you write
code, then separately write Terraform/Kubernetes/Dockerfiles, and the two drift. This
is where most production bugs and security incidents originate."*

Details worth having exactly right, all sourced:

- **Erlang's escalation is recursive.** `intensity` (default 1) restarts per `period`
  (default 5s); exceed it and the supervisor **terminates all its children and then
  itself** with reason `shutdown`, which its own parent sees as an ordinary child
  failure and handles with the same rules one level up
  ([supervisor](https://www.erlang.org/doc/apps/stdlib/supervisor.html)). There is no
  special top-level circuit breaker; giving up is uniform all the way to the root.
- **`shutdown` is TERM-then-KILL with a number.** `shutdown: 5000` means send the
  shutdown signal, wait 5 s, then kill; `brutal_kill` skips the wait; `infinity` is
  mandatory for supervisor children so a subtree can drain. Default 5000 for workers.
- **systemd's exponential backoff is new and explicit.** `RestartSec=` defaults to
  **100 ms**; `RestartSteps=` (v254, default 0 = off) and `RestartMaxDelaySec=`
  (default infinity) ramp it. Separately, `StartLimitBurst`/`StartLimitIntervalSec`
  is a rate gate, defaulting from the manager's `DefaultStartLimitBurst=5` /
  `DefaultStartLimitIntervalSec=10s` *[confirmed only via issue threads and secondary
  docs; freedesktop.org 403'd during research]*
  ([systemd.service(5)](https://manpages.debian.org/bookworm/systemd/systemd.service.5.en.html)).
- **`WatchdogSignal=` defaults to SIGABRT, not SIGTERM** — a watchdog timeout is
  deliberately made to produce a core dump, because a hung process is a bug you want
  to read, not a process you want to quietly recycle.
- **`KillMode=control-group` is the default** and kills the whole cgroup;
  `KillMode=process` is documented as "not recommended" and `none` as leaving
  processes "outside the service manager's oversight"
  ([systemd.kill(5)](https://manpages.debian.org/bookworm/systemd/systemd.kill.5.en.html)).
  systemd's own default is the containment story of section 3.
- **Ordering and requirement are different axes** in systemd, and conflating them is
  the classic unit-file bug: `After=` only sequences; `Requires=` only pulls in;
  `Requires=` without `After=` does not actually wait
  ([systemd.unit(5)](https://manpages.debian.org/bookworm/systemd/systemd.unit.5.en.html)).
- **Kubernetes separates consequence from check.** The same HTTP endpoint under
  `startupProbe` means "don't scrutinise me yet", under `readinessProbe` means "take
  me out of rotation" (no restart — the pod IP leaves the EndpointSlice), and under
  `livenessProbe` means "restart the container". Defaults:
  `periodSeconds` 10, `timeoutSeconds` 1, `failureThreshold` 3, `successThreshold` 1
  (and `successThreshold` **must** be 1 for liveness and startup)
  ([probes](https://kubernetes.io/docs/concepts/workloads/pods/probes/)).
- **process-compose proves probes are not a container-scale idea.** It imports
  Kubernetes' probe schema near-verbatim into a single-machine supervisor, and adds
  `depends_on: condition: process_log_ready` and `process_completed_successfully`
  ([process-compose health](https://f1bonacc1.github.io/process-compose/health/),
  [configuration](https://f1bonacc1.github.io/process-compose/configuration/)).
- **s6's rule is the deepest one:** *a supervisor can only kill a process it created
  itself.* Hence `run` must `exec` in the foreground and never daemonize; hence no PID
  files; hence `PR_SET_CHILD_SUBREAPER` as the last resort for daemons that insist
  ([s6 servicedir](https://skarnet.org/software/s6/servicedir.html),
  [overview](https://skarnet.org/software/s6/overview.html)).
- **s6-rc compiles the dependency graph offline** into a binary database, so runtime
  bring-up is a linear walk of a precomputed order that tooling can print before
  anything runs ([s6-rc-compile](https://skarnet.org/software/s6-rc/s6-rc-compile.html)).
  That is a compiler doing a compiler's job — and it is exactly the seam Avra owns.

### 2.2 The strongest version in Avra

Four moves, each a paradox collapse rather than a feature.

**Move 1 — readiness is a typed value, not a string.** This is what makes the
projection possible at all, because the *target* decides how to spell it:

```avra
type Ready =
  Started                         // pid exists; the weakest, and named as weak
  Log(pattern: Regex)             // a line matched on stdout/stderr
  Port(port: int)                 // a TCP connect succeeds
  Http(path: string, port: int)   // 2xx-3xx
  Exec(cmd: Cmd)                  // exit 0
  Notify                          // the child sends READY=1 (sd_notify protocol)
  Exit                            // the child runs to completion, exit 0
```

**Move 2 — one `check`, three consequences.** Kubernetes' real insight is that the
check and its consequence are orthogonal. Avra says it in one field each:

```avra
component Service {
  config {
    run:      Cmd
    cwd:      Dir?          = null
    env:      Env           = Env.empty      // NOT the ambient environment
    ready:    Ready         = .Started
    healthy:  Ready?        = null           // same vocabulary, different consequence
    restart:  Restart       = .OnFailure
    backoff:  Backoff       = .Exponential(from: 100ms, to: 30s)
    give_up:  Intensity     = { times: 5, within: 10s }
    stop:     Stop          = { signal: .Term, grace: 10s, then: .Kill, scope: .Tree }
    needs:    List<Service> = []
  }
}

component Service postgres {
  run   = cmd"postgres -D ${data}"
  ready = .Exec(cmd"pg_isready -h localhost")
}

component Service api {
  run     = cmd"./api --port ${port}"
  ready   = .Http("/healthz", port)
  healthy = .Http("/healthz", port)     // same check, restarting consequence
  needs   = [postgres]
}
```

**Move 3 — the restart strategy is derived, not configured.** Erlang offers
`one_for_one` / `rest_for_one` / `one_for_all` as a *choice*. But the choice is
already implied by the dependency edges: if nothing depends on a child, restarting it
alone is `one_for_one`; if `api` reads `postgres.port`, then `postgres` dying must
restart `api`, which is `rest_for_one` over the transitive dependents. So Avra
offers **one** field, `restart_dependents: bool = true`, and the graph supplies the
strategy. Better: Axis 19.3's topology extraction means `needs` itself should usually
be *inferred* — if `api`'s config expression reads `postgres.port`, the edge exists
and the compiler knows it. **You do not write `depends_on`.**

**Move 4 — the projection, with its losses printed.** This is the whole payoff, and
the DEGRADED block is what separates it from every existing generator:

```
$ avra explain service api --as systemd
  # api.service  — generated from src/services.av:22, do not edit
  [Service]
  ExecStart=/srv/api --port 8080
  Type=notify                        # from ready = .Http → NO; see DEGRADED
  Restart=on-failure
  RestartSec=100ms
  RestartSteps=9
  RestartMaxDelaySec=30s             # from backoff = .Exponential(100ms, 30s)
  StartLimitBurst=5
  StartLimitIntervalSec=10s          # from give_up = 5 within 10s
  KillSignal=SIGTERM
  TimeoutStopSec=10s
  KillMode=control-group             # from stop.scope = .Tree — full fidelity here
  After=postgres.service
  Requires=postgres.service          # BOTH, because Requires alone does not wait

  DEGRADED — this target cannot express:
    ready = .Http("/healthz", 8080)
      systemd has no HTTP readiness. Emitted as Type=exec (up when exec succeeds),
      which is WEAKER: the unit is "started" before the port answers.
      Honest fixes: (a) ready = .Notify and call sd_notify in the child;
                    (b) accept the weakening — pass --allow-degraded.
    healthy = .Http(...)
      systemd's only liveness mechanism is WatchdogSec + WATCHDOG=1 from inside
      the process. An external HTTP liveness probe has no systemd equivalent.
      Not emitted. On k8s this projects exactly; on this target it is LOST.
  --strict makes any DEGRADED line a build error.
```

Compare what the incumbents say about their own generated output: `podman generate
systemd` warns that "unit files are created best effort and may need further editing;
review the generated files carefully before using them in production"
([podman-generate-systemd(1)](https://docs.podman.io/en/latest/markdown/podman-generate-systemd.1.html)).
That sentence is an admission that the tool knows it lost something and will not say
what. **Avra's differentiator is not that it generates a unit file — five tools do
that. It is that it enumerates what it could not generate.**

And because the graph is compiled, s6-rc's trick is free:

```
$ avra explain services --plan
  1. postgres   ready when `pg_isready` exits 0            (up to 30s)
  2. migrate    ready when it EXITS 0                       needs postgres
  3. api        ready when GET :8080/healthz is 2xx         needs migrate
     restart of postgres restarts: migrate, api   (derived: api reads postgres.port)
```

### 2.3 Verdict

- **SHIP-IN-V1:** the `component Service` declaration, the typed `Ready` vocabulary,
  the local supervisor (backoff + intensity + TERM/grace/KILL over a process group),
  derived dependency ordering, and `avra explain services --plan`. This is what the
  Avra build/test system itself needs, so it is dogfooded from day one.
- **SHIP-IN-V1, one target only:** the projection, to **compose** or **systemd** —
  whichever the team actually uses — *with* the DEGRADED block. One target proves the
  mechanism; the second target is cheap once `Ready` is typed.
- **SHIP-LATER:** k8s and multi-target projection. The k8s mapping is genuinely lossy
  in ways that need care (per-container `restartPolicy` only arrived in v1.34 for
  sidecars — [k8s v1.34 blog](https://kubernetes.io/blog/2025/08/29/kubernetes-v1-34-per-container-restart-policy/)),
  and a half-right pod spec is worse than none.
- **REFUSE:** exposing `one_for_one`/`rest_for_one`/`one_for_all` as a config field.
  Three names for a fact the dependency graph already holds. Also refuse
  `restart: always` as a *default* — `Restart=no` is systemd's default and
  `restart: no` is Compose's, for the good reason that infinite restart hides bugs.
- **REFUSE:** a `Ready` variant that guesses (a "wait until it looks up" heuristic).
  `.Started` is honest and weak; a heuristic is dishonest and weak.

---
## 3. Structured concurrency for processes

### 3.1 What it is

Trio, Kotlin, Swift and Java all converged on the same promise: a lexical scope that
**does not exit while a child is still running**. The exact guarantees, verbatim:

- **Trio**: "The block does not exit until *all* tasks have completed"; "Nurseries
  ensure the absence of orphaned Tasks, since all running tasks will belong to an open
  Nursery." On an unhandled child exception Trio "immediately cancels all the other
  tasks in the same nursery, and then waits for them to finish before re-raising"
  ([Trio core reference](https://trio.readthedocs.io/en/stable/reference-core.html)).
- **Java `StructuredTaskScope`** (JEP 505, still preview through JDK 26 via JEP 525):
  "All of the subtasks' threads are guaranteed to have terminated once the scope is
  closed, and no thread is left behind when the block exits"
  ([JEP 505](https://openjdk.org/jeps/505), [JEP 525](https://openjdk.org/jeps/525)).
- **Swift SE-0304**: "the child tasks within the task group scope must complete when
  the scope exits, and will be implicitly cancelled first if the scope exits with a
  thrown error" ([SE-0304](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0304-structured-concurrency.md)).
- **Kotlin**: "When the parent coroutine is cancelled, all its children are recursively
  cancelled, too" ([coroutine context](https://kotlinlang.org/docs/coroutine-context-and-dispatchers.html)).

Nathaniel Smith's essay names the three things unstructured spawn breaks: black-box
abstraction (you cannot tell from a signature whether a call leaves something running),
resource cleanup (a background task outlives the `with` block that owns its resources),
and error handling — "every mainstream concurrency framework ... simply gives up ...
the runtime just... drops it on the floor"
([vorpus.org](https://vorpus.org/blog/notes-on-structured-concurrency-or-go-statement-considered-harmful/)).

Every one of those three complaints is *more* true of subprocesses than of tasks. The
status quo in every mainstream language is the opposite of the guarantee. Rust's
standard library documents its own behaviour bluntly: "There is no implementation of
`Drop` for child processes, so if you do not ensure the `Child` has exited then it
will continue to run, even after the `Child` handle to the child process has gone out
of scope" ([std::process::Child](https://doc.rust-lang.org/std/process/struct.Child.html)).
Tokio's opt-in `kill_on_drop` defaults to `false` and even when true says "no
additional guarantees are made"
([tokio::process::Command](https://docs.rs/tokio/latest/tokio/process/struct.Command.html)).
This is why every developer has, at some point, hunted a `webpack-dev-server` still
holding port 3000 an hour after the terminal closed.

### 3.2 The one asymmetry that makes this hard

**Task cancellation in every one of those systems is cooperative. Process cancellation
is not.** SE-0304 states it outright: "The effect of cancellation within the cancelled
task is fully cooperative and synchronous. That is, cancellation has no effect at all
unless something checks for cancellation." Kotlin's `withTimeout` likewise only
*requests*. A child process checks nothing. So a scope's cancel must be an **OS**
mechanism, and the OS mechanisms are not equal:

| | Linux | macOS/BSD | Windows |
|---|---|---|---|
| best containment | **cgroup v2 `cgroup.kill`** | process group | **Job Object** |
| atomic vs. forks? | **yes** | no | **yes** |
| survives our own crash? | no (unless a manager holds it) | no | **yes** |
| die-with-parent | `PR_SET_PDEATHSIG` (racy, thread-scoped) | none | job handle close |
| exact exit detection | `waitpid`/pidfd | `kqueue` `EVFILT_PROC`/`NOTE_EXIT` | wait handles |

The load-bearing details:

- **`kill(pid, SIGTERM)` reaches one process.** Fanning out requires targeting the
  *group*: "If *pid* is less than -1, then *sig* is sent to every process in the
  process group whose ID is *-pid*" ([kill(2)](https://man7.org/linux/man-pages/man2/kill.2.html)).
  Which means the child must be *put* in its own group at spawn
  ([setpgid(2)](https://man7.org/linux/man-pages/man2/setpgid.2.html) — the same call
  "used by programs such as `bash(1)` ... to implement shell job control").
- **A process group is not a containment boundary.** A child that calls `setsid()` or
  `setpgid()` leaves it, and a `readdir`-then-kill loop races against forks.
- **cgroup v2 is the only atomic one on Linux**: "Writing '1' to the file causes the
  cgroup and all descendant cgroups to be killed"; "Killing a cgroup tree will deal
  with concurrent forks appropriately and is protected against migrations"
  ([cgroup-v2](https://docs.kernel.org/admin-guide/cgroup-v2.html)). This is precisely
  why `KillMode=control-group` is systemd's default.
- **`PR_SET_PDEATHSIG` is a trap, twice over.** It fires when the parent *thread*
  exits, "rather than after all of the threads in the parent process terminate"; and
  "if the parent thread and all ancestor subreapers have already terminated by the
  time of the `PR_SET_PDEATHSIG` operation, then **no** parent-death signal is sent"
  ([PR_SET_PDEATHSIG](https://man7.org/linux/man-pages/man2/pr_set_pdeathsig.2const.html)).
  Hence the mandatory "set it, then re-check `getppid()`" dance. A process-scoped,
  fork-inherited variant was proposed on lkml but **[unverified — no evidence it
  merged]**.
- **macOS has neither.** There is no parent-death signal and no cgroup. `kqueue`'s
  `EVFILT_PROC`/`NOTE_EXIT` gives exact *detection* (and works on non-children — "if a
  process can normally see another process, it can attach an event to it",
  [kqueue(2)](https://man.freebsd.org/cgi/man.cgi?query=kqueue&sektion=2)), but
  detection is not containment. Process group plus TERM/grace/KILL is the ceiling.
- **Windows is the best of the three.** `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE` "causes
  all processes associated with the job to terminate when the last handle to the job
  is closed", including nested jobs
  ([Job Objects](https://learn.microsoft.com/en-us/windows/win32/procthread/job-objects)).
  Because the guarantee is anchored to handle-table cleanup, it holds even if *our*
  process is killed — the one platform where the promise survives our own crash.
- Rust's ecosystem answer, `process-wrap`, deliberately refuses a single cross-platform
  API and ships composable per-OS wrappers instead
  ([process-wrap](https://github.com/watchexec/process-wrap)). That is honest, and it
  is the shape Avra's runtime layer should copy internally.
- **Kubernetes' grace budget is shared, not additive** — a subtlety worth stealing:
  "PreStop hooks are not executed asynchronously from the signal to stop the Container;
  the hook must complete its execution before the TERM signal can be sent", and the
  countdown "begins before the PreStop hook is executed"
  ([container lifecycle hooks](https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/)).
  Default grace: 30 s on k8s, 10 s on Docker Compose.

### 3.3 The strongest version in Avra

**Move 1 — a child process is a scope member, full stop.** The spec's `scope { }`
(Axis 18.7) already promises "if a scope exits cleanly, you are guaranteed no tasks it
spawned are still running." Extend the word *task* to cover a process tree, and the
promise inverts Rust's documented default:

```avra
scope {
  let pg  = start(postgres)?      // blocks until READY (see Move 2)
  let api = start(api)?
  run_integration_tests()?
}
// GUARANTEED on every exit path — success, error, panic, outer cancel:
//   TERM to each child's containment unit, 10s grace, then KILL. Nothing survives.
```

**Move 2 — the readiness contract and the startup handshake are the same primitive.**
This is the best paradox collapse in the report and nobody has shipped it. Trio's
`nursery.start()` "blocks until the new task has finished initializing itself, and
optionally returns some information from it" — the child calls `task_status.started(v)`
and *then* is moved into the nursery. That is structurally identical to systemd's
`Type=notify` + `READY=1`, to a k8s `startupProbe`, and to process-compose's
`depends_on: process_healthy`. Section 2's `Ready` enum **is** the `started()` payload.
So one word covers both:

```avra
spawn proc(cmd)      // in the scope, not waited on — the raw shape
start(service)?      // in the scope AND blocked until `service.ready` is satisfied
```

`start` is the reason you never write `sleep 5` in an integration test again, and it
is the reason `needs` can be derived: `api` is `start`ed after `pg` because it reads
`pg.port`, and `start(pg)` does not return until `pg.ready` says so.

**Move 3 — race, done properly.** RFC 8305 is explicit that the real algorithm is
*staggered*, not simultaneous: "connection attempts SHOULD NOT be made
simultaneously... one connection attempt to a single address is started first,
followed by the others in the list, one at a time", with "a recommended value for a
default delay [of] 250 milliseconds", and "once one of the connection attempts
succeeds... all other connection attempts that have not yet succeeded SHOULD be
canceled" ([RFC 8305](https://www.rfc-editor.org/rfc/rfc8305)). So:

```avra
let mirror = race([fetch(a), fetch(b), fetch(c)], stagger: 250ms)?
// losers are TERM'd by the scope, not leaked — the old draft's `race` leaked them
```

**Move 4 — a bound is not optional.** Swift task groups have no built-in concurrency
limit and the idiom is manual windowing; Kotlin uses a `Semaphore`; Trio a
`CapacityLimiter`. For *tasks* an unbounded group is a memory problem. For
*processes* it is a fork bomb. So `parallel_map` over commands takes a limit that
defaults to `cores`, and unbounded is the thing you opt into:

```avra
let results = files.parallel_map(limit: cores, (f) -> proc(cmd"clang -c ${f}").wait())?
let all     = files.parallel_map(limit: .unbounded, ...)   // written at the site, greppable
```

**Move 5 — print the containment fidelity.** The guarantee is only as strong as the
weakest supported platform, so say so rather than implying otherwise:

```
$ avra explain process --containment
  linux    cgroup v2 `cgroup.kill`        ATOMIC. fork-safe, migration-safe.
  windows  job object, KILL_ON_JOB_CLOSE  ATOMIC. holds even if WE are killed.
  darwin   process group + TERM/KILL      DEGRADED:
             a child that calls setsid() escapes the group and survives us
             a child that re-execs into a new group survives us
             exit DETECTION is exact (kqueue NOTE_EXIT); CONTAINMENT is not
             there is no parent-death signal on this platform. Nothing to enable.
  --strict makes any DEGRADED line a build error.
```

**Move 6 — the deadlock you cannot write.** Python's docs warn: "Use `communicate()`
rather than `.stdin.write`, `.stdout.read` or `.stderr.read` to avoid deadlocks due to
any of the other OS pipe buffers filling up and blocking the child process"
([subprocess](https://docs.python.org/3/library/subprocess.html)) — because a Linux
pipe holds 65,536 bytes and no more ([pipe(7)](https://man7.org/linux/man-pages/man7/pipe.7.html)).
Green threads make the correct structure free: every child gets three fibers (stdin
writer, stdout reader, stderr reader) by construction, so the classic bidirectional
deadlock is not expressible. This costs nothing and deletes a bug class that has
shipped in every language with a `Popen`.

### 3.4 Verdict

- **SHIP-IN-V1:** scope membership for child processes with the TERM/grace/KILL exit
  guarantee; `start()` with the `Ready` handshake; three-fiber I/O; `parallel_map`
  with a mandatory-in-practice limit; `race` with stagger.
- **SHIP-IN-V1:** `avra explain process --containment`. Without it the guarantee is a
  marketing claim on macOS. With it, it is the most honest concurrency story in any
  language, and the honesty is the feature.
- **SHIP-LATER:** cgroup-delegated containment on Linux (needs a delegated cgroup and
  a systemd/user-slice story). Process groups first, cgroups as the strict upgrade.
- **REFUSE:** relying on `PR_SET_PDEATHSIG` as *the* mechanism. It is thread-scoped,
  it has a documented unclosable window, and a design that leans on it will be right
  in tests and wrong in production. Use it only as a belt beside the group/cgroup brace.
- **REFUSE:** a `spawn` for processes that is unstructured by default. `spawn detached`
  already exists in the spec as the deliberate opt-out (Axis 18.7); a detached child
  process should additionally require a named owner, because "who kills this" has no
  answer otherwise.

---

## 4. Pipelines as data

### 4.1 What it is

Three separable questions hide inside "pipelines": what the *verdict* of a pipeline
is, where *text* becomes *records*, and who applies *back-pressure*.

**The verdict.** Bash's default is documented as: "The exit status of a pipeline is the
exit status of the last command in the pipeline, unless the `pipefail` option is
enabled" ([Bash: Pipelines](https://www.gnu.org/software/bash/manual/bash.html#Pipelines)).
`pipefail` upgrades that to "the value of the last (rightmost) command to exit with a
non-zero status". And `PIPESTATUS` is "an array variable containing a list of exit
status values from the commands in the most-recently-executed foreground pipeline"
([Bash Variables](https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html)).
Read those three sentences together and the conclusion is unavoidable: **the industry
has known for thirty years that a pipeline's status is a vector, has built the vector,
and still defaults to throwing it away.** Every `set -euo pipefail` at the top of every
CI script is a workaround for a bad default.

**The text/record boundary.** Nushell and PowerShell both carry structured values
between *their own* commands and hit a wall at the external boundary. Nushell's answer
is explicit, manual lifting — `lines`, `from json`, `parse`, `detect columns` — and it
does not even auto-splat: "Nushell does not automatically convert a list into external
arguments", the spread `...` is required
([running externals](https://www.nushell.sh/book/running_externals.html)). Its
capture idiom is `do -i { cmd } | complete`, which returns a record of
`{stdout, stderr, exit_code}` ([stdout/stderr/exit codes](https://www.nushell.sh/book/stdout_stderr_exit_codes.html)) —
note that Nushell independently arrived at the same three-field verdict.
PowerShell's boundary bug is even sharper: before 7.4, piping a native command's byte
output "corrupted binary data" by round-tripping through .NET strings, and the fix
(`PSNativeCommandPreserveBytePipe`) explicitly **does not** apply when stderr is merged
via `2>&1` ([about_Pipelines](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_pipelines)).
PowerShell also keeps `$?` and `$LASTEXITCODE` as genuinely different signals
([about_Automatic_Variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables)).

**Back-pressure and early exit.** A Linux pipe is 65,536 bytes ("since Linux 2.6.11,
the pipe capacity is 16 pages"), resizable with `F_SETPIPE_SZ` under
`/proc/sys/fs/pipe-max-size` (default 1 MiB) ([pipe(7)](https://man7.org/linux/man-pages/man7/pipe.7.html)).
When a downstream stage exits early, the next `write()` upstream raises SIGPIPE, whose
default disposition terminates the writer — that is the actual mechanism by which
`producer | head` stops the producer. Python deliberately ignores SIGPIPE so the error
surfaces as `BrokenPipeError`, and its docs warn against "fixing" that globally
([signal](https://docs.python.org/3/library/signal.html#note-on-sigpipe)). Rust sets
SIGPIPE to `SIG_IGN` at startup — a holdover from its removed green-threaded runtime —
and this is *not* mentioned anywhere in the `std::process` docs
([rust-lang/rust#62569](https://github.com/rust-lang/rust/issues/62569)). A new
language must decide this deliberately and write it down, because both incumbents got
it accidentally.

### 4.2 The strongest version in Avra

**Move 1 — the verdict is the return type.** `pipefail` stops being a flag you
remember and becomes the only thing that exists:

```avra
let out = pipe(cmd"cat ${log}", cmd"grep ^ERROR", cmd"sort -u").text()?
```
```
error[F7203]: pipeline stage 2 of 3 failed
  ╭─[report.av:14:22]
14 │   pipe(cmd"cat ${log}", cmd"grep ^ERROR", cmd"sort -u")
   ·                         ───────┬────────
   ·                                ╰── `grep` exited 1
   │
   stages   1 cat   exit 0     2.1 MiB out
            2 grep  exit 1     0 B out          ← first failure
            3 sort  (not run)
   stderr of stage 2:
     (empty — grep exits 1 for "no lines matched", which is not an error)
   help: this pipeline treats any nonzero stage as failure.
         `grep` uses exit 1 for "no match". Allow it:
         cmd"grep ^ERROR".ok_exits([0, 1])
```

Three things are happening there that no shell can do: the failing stage is *named
with its argv*, its **own** stderr is quoted (not the interleaved soup of all three),
and the diagnostic knows `grep`'s exit-1 convention well enough to suggest the fix.
`ok_exits` is the general escape hatch and mirrors systemd's `SuccessExitStatus=`,
which exists for exactly this reason.

**Move 2 — stderr is per-stage and typed.** In a shell every stage's stderr lands on
one fd and attribution is lost forever. Avra gives each stage its own `Stream<string>`
and keeps them tagged in the pipeline value. This is cheap, obviously right, and
nobody offers it.

**Move 3 — bytes until a named decoder. Never a heuristic.** The `lines()` boundary is
the right one, and `json<T>()` is the typed one; `detect columns`-style guessing is
refused on the "refuse, never emulate" law:

```avra
cmd"docker ps --format json" |> lines() |> json<Container>()   // typed at the boundary
cmd"ls -l"                   |> lines()                        // honest: List<string>
cmd"ls -l"                   |> detect_columns()               // does not exist. Deliberately.
```
```
error[F7211]: no decoder for stage output
  │  cmd"ls -l" |> where(it.size > 10.mb)
  │                     ─────┬─────
  │                          ╰── this is `Stream<bytes>`; it has no field `size`
  help: name the shape at the boundary:
          |> lines() |> parse(r"...")      -- regex to a record
          |> json<T>()                     -- if the tool can emit JSON
        or use the typed listing instead of shelling out:
          fs.list(d)  -> Stream<Entry>     -- `size` is a field there
```
That last line is the LLM-first payload: the diagnostic teaches the *language's own*
answer instead of only fixing the shell line.

**Move 4 — back-pressure is structural.** Because each stage is a fiber pair over a
bounded channel, back-pressure is the channel's existing semantics (Axis 18.4:
"Bounded (capacity > 0) — backpressure when full"). A `Stream` of 10 GB never
materialises. The old draft's `process.pipe(input: string, ...)` cannot say this.

**Move 5 — decide SIGPIPE on purpose and print it.** A downstream stage exiting early
is *normal* (`… |> take(10)`), so an EPIPE from a stage whose consumer already finished
is a **success**, not a failure — and any other EPIPE is a real error. Write it in the
docs, put it in a golden test, and never inherit it by accident the way Rust did.

### 4.3 Verdict

- **SHIP-IN-V1:** the `Pipeline` value with a per-stage verdict vector, per-stage
  stderr, the failing-stage diagnostic, `ok_exits`, bounded-channel back-pressure, and
  the explicit SIGPIPE rule.
- **SHIP-IN-V1:** `lines()`, `bytes()`, `json<T>()` as the *only* decoders.
- **SHIP-LATER:** `parse(regex) -> Stream<Record>` (needs the record story settled) and
  `tee` (needs a fan-out channel primitive — `channel.merge`'s inverse).
- **REFUSE:** heuristic table detection (`detect columns`). Nushell's own docs describe
  it as "attempt to automatically split text"; an *attempt* is not a contract, and a
  silently mis-parsed column is exactly the plausible-default bug class the sibling
  doc exists to delete.
- **REFUSE:** a pipeline that returns only a `string`. That is the old draft's
  `$"..."`, and it is where two thirds of the verdict goes to die.
- **REFUSE (with feeling):** merging stderr into stdout by default. PowerShell's
  `2>&1` byte-corruption carve-out is the cautionary tale.

---
## 5. Cacheable processes

### 5.1 What it is

"A process with declared inputs and outputs is a pure function; hash the inputs, cache
the outputs." Five production systems implement it, and the *honest* reading of them is
the most valuable thing in this report.

**Bazel** hashes command line + input file digests + allowlisted environment + platform
+ output paths ([remote caching](https://bazel.build/remote/caching)); in the Remote
Execution API the `Action` digest covers `command_digest`, `input_root_digest` (a
Merkle tree), `platform`, `timeout`, `do_not_cache` and an optional `salt`
([remote_execution.proto](https://github.com/bazelbuild/remote-apis/blob/main/build/bazel/remote/execution/v2/remote_execution.proto)).
Crucially, **sandboxing exists to make the declaration honest**: "Without sandboxing,
Bazel doesn't know if a tool uses undeclared input files"
([sandboxing](https://bazel.build/docs/sandboxing)). And equally crucially, **caching
and sandboxing are orthogonal knobs** — `no-sandbox` actions "may still be cached",
`no-cache` actions may still be sandboxed
([common definitions](https://bazel.build/reference/be/common-definitions)).

**Nix** goes input-addressed: a derivation's store path hashes all of its inputs. The
network is reachable only through a **fixed-output derivation** that declares
`outputHash` up front, which Nix verifies afterwards — network access traded for a
runtime-checked hash equality
([advanced attributes](https://nix.dev/manual/nix/2.24/language/advanced-attributes.html)).
One number matters enormously for Avra: **`sandbox` defaults to `true` on Linux and
`false` everywhere else** ([nix.conf](https://nix.dev/manual/nix/2.34/command-ref/conf-file.html)).
Even Nix does not claim hermeticity on macOS by default.

**Turborepo** shipped and then fixed the canonical bug. `env`/`globalEnv` are hashed;
`passThroughEnv` is explicitly **not** — "values provided in `passThroughEnv` do not
contribute to the cache key" — so any output-affecting variable put in the wrong list
silently serves a stale build. Turborepo 2.0's fix is the interesting part: `envMode:
"strict"` became the **default**, *filtering* the task's runtime environment to only
the declared variables, so an undeclared variable is now **invisible** rather than
silently unhashed ([env vars](https://turborepo.dev/docs/crafting-your-repository/using-environment-variables)).
That is a paradox collapse someone already shipped: the way to stop a hidden input from
corrupting a cache is not to hash harder, it is to **make the input unreachable**.

**ccache** is the honest-limits catalogue, and every line of it applies:
- `__TIME__` in a source forces preprocessor mode; `sloppiness = time_macros` opts back
  into caching with the stated cost that "time values in output will be from the cached
  compilation" — i.e. a knowingly wrong answer, traded for speed.
- `-g` embeds the absolute cwd into debug info, needing `base_dir`/`hash_dir` or
  `-fdebug-prefix-map`; and "it does not work to use a cache populated with `hash_dir`
  enabled after `hash_dir` is turned off" — the setting is not retroactively safe.
- The mtime safety valve, stated outright: "If modification time (mtime) or status
  change time (ctime) of the source file ... is equal to (or newer than) the time that
  ccache was invoked, ccache disables caching completely."
- Direct mode's structural gap: "header files that were not used, but would have been
  used if they existed, are not" tracked.
  ([ccache manual](https://ccache.dev/manual/4.13.6.html))

**Make** is the counter-example: mtime comparison alone, with documented clock skew
("Clock skew detected. Your build may be incomplete."), filesystem granularity, and —
the fatal one — **no representation of "the flags changed"**. *Build Systems à la
Carte* formalises exactly this axis
([MSR](https://www.microsoft.com/en-us/research/publication/build-systems-la-carte/)).
Ninja improves it with `restat` (recheck mtime; if unchanged, don't cascade) and a deps
log of **tool-reported** inputs. `redo` stays timestamp+inode with opt-in `redo-stamp`
checksums, and apenwarr's ["mtime comparison considered harmful"](https://apenwarr.ca/log/20181113)
is the standard argument.

**And then the other architecture entirely.** `tup` mounts a FUSE filesystem and
*observes* every read a command performs, deriving dependencies rather than trusting a
declaration ([tup](https://gittup.org/tup/)). `fsatrace` exists specifically "to
automatically generate dependencies... **or to ensure declared dependencies match the
real ones**" ([fsatrace](https://github.com/jacereda/fsatrace)). BuildXL detours the
Win32 filesystem API and — the strongest version — makes "the observation set... part
of the cache key" ([BuildXL sandboxing](https://github.com/microsoft/BuildXL/blob/main/Documentation/Specs/Sandboxing.md)).

**The synthesis, which is the load-bearing fact:** there are exactly two working
architectures — **sandbox-and-fail** (Bazel, Nix: deny undeclared access so a wrong
declaration is a loud error) and **observe-and-key** (tup, BuildXL: don't require a
declaration, derive the key from what happened). **No surveyed system achieves general
automatic hermeticity for arbitrary subprocesses without either kernel-level
enforcement or a named escape hatch that trades correctness for practicality.**

### 5.2 The strongest version in Avra

The Avra-specific insight is that the sibling filesystem design already minted the
right vocabulary. If `reads`/`writes` are `Rel` values against a `Dir` root — not
strings — then **one declaration serves four masters at once**, which no existing
system manages:

```avra
let compile = Cmd("clang")
  .args(["-c", src, "-o", obj])
  .reads([src, headers])          // List<Rel> against a Dir — the fs vocabulary
  .writes([obj])
  .env([Env.pass("SDKROOT")])     // empty by default; Turborepo-strict from day one
```

1. **A cache key.** Content hash of (argv, input digests, declared env, platform).
2. **A sandbox policy.** The same `Rel` set is the Landlock ruleset — precisely Move 1
   of the sibling doc, now pointed at a child process.
3. **A verification.** Under the sandbox an undeclared read is `EPERM`.
   **An undeclared read is a trap, not a stale cache hit.** That single sentence is
   the difference between Bazel's answer and Make's, and Avra gets it for free because
   the declaration was already a capability.
4. **A projection.** `avra explain build --as bazel` / `--as nix` becomes possible,
   because the action is a value.

And the fifth, which is section 6's punchline: **the cache key is also the cassette
key.** A recorded run and a cached run are the same content-addressed entry with a
different consumer.

The refusals that make it sound, each with its precedent:

```
error[F7302]: this action is not cacheable
  │  .args(["clang", "-c", src, "-g", "-o", obj])
  │                              ─┬
  │                               ╰── `-g` embeds the absolute build directory
  │                                   into debug info; the output depends on where
  │                                   the build ran, which is not in the key.
  fix: add -fdebug-prefix-map=${cwd}=. , or mark .uncacheable("debug paths")
```
```
error[F7305]: undeclared environment read
  │  the child read $SDKROOT, which is not in `env`
  hint: under strict env (the default) the child sees only declared variables.
        This process saw it because [escape_hatch] was set. Declare it or drop it.
```

**`--verify-hermetic`** closes the loop the way nobody's default does: run the action
twice, in different directories, with a shifted clock, and diff the outputs. If they
differ, print *which bytes* moved and refuse to cache — the Reproducible Builds
catalogue's failure list, turned into a compiler diagnostic
([reproducible-builds.org/docs](https://reproducible-builds.org/docs/),
[SOURCE_DATE_EPOCH](https://reproducible-builds.org/docs/source-date-epoch/), which
"over 50 upstream tools" honour — meaning the rest do not).

### 5.3 Verdict

- **SHIP-IN-V1, narrowly:** declared `reads`/`writes`/`env` on a `Cmd`, a
  content-addressed cache under the single cache root the ROADMAP already mandates,
  and **empty-env-by-default**. Used for exactly one thing: the compiler's own
  `clang`/link invocations. That is real, measurable, dogfooded value in week one.
- **SHIP-IN-V1:** `--verify-hermetic` as an opt-in mode. It costs one extra run and it
  is the only thing that converts "we declared it" into "we checked."
- **SHIP-LATER:** sandbox enforcement (Landlock on Linux, sandbox-exec on macOS), the
  observe-and-key mode (`fsatrace`-style), remote caching, and the
  `--as bazel`/`--as nix` projections.
- **REFUSE:** caching on by default. Every system surveyed makes it opt-in per action
  for good reason, and a wrong cache hit is the single worst failure mode available —
  it produces a plausible, silent, wrong binary.
- **REFUSE:** mtime as the key. mtime+size may be a *validator inside* the cache (as
  the ROADMAP already specifies), never the key. Make's clock-skew warning and
  flag-blindness are the closed case.
- **REFUSE:** network access without a declared output hash. Nix's fixed-output
  derivation is the only honest shape; anything else is a cache that lies about the
  internet.
- **REFUSE (honesty rider that must be printed):** any claim of hermeticity on macOS
  in v1. Nix itself defaults `sandbox = false` off Linux. Print
  `hermeticity: DECLARED, UNVERIFIED (no kernel enforcement on this target)`.

---

## 6. Observability and testability

### 6.1 What it is

Four ideas that turn out to be **one mechanism with four bindings**.

**The runner as a seam.** Injecting a fake command runner is ordinary practice, but the
strong version comes from the sibling doc's Move 3: *the fake is not a fake.* Under
`--profile test` every runner binds an in-memory implementation unless the site
declares `real = true`. Fidelity is structural because the same code parses argv,
resolves the binary, applies the env filter, computes the cache key, enforces the
timeout and reports the verdict — only `execve` is replaced.

**Record/replay.** VCR (Ruby), vcrpy, go-vcr established the pattern for HTTP: record
once, commit the cassette, replay deterministically ([vcr/vcr](https://github.com/vcr/vcr)),
and it has been extended to subprocess-backed protocols
([agent-vcr](https://github.com/Jarvis2021/agent-vcr)). The honest limit is that
subprocess output is far less stable than HTTP — tmpdirs, absolute paths, timestamps,
`ls` ordering — so a cassette rots silently in a way an HTTP one usually does not.

**Static blast radius.** The strongest precedent is Bazel's `aquery`, which exists for
"the actual commands run and their inputs/outputs/mnemonics", prints one command per
line with `--include_commandline`, and even has an `aquery_differ` for "verify[ing]
that the command lines being run did not change" ([aquery](https://bazel.build/query/aquery)).
Bazel can do this because an action is a value in a graph. Avra can do it for a
*program*, for the same reason.

**Structured events.** OpenTelemetry already standardised the schema, so there is
nothing to invent: CLI spans require `process.executable.name`, `process.exit.code` and
`process.pid`; recommend `process.command_args` and `process.executable.path`; set
`error.type` when the exit code is nonzero; name the span after the executable; and
span kind is `CLIENT` for the caller. One line matters for design:
`process.command_args` "SHOULD NOT be collected by default unless there is sanitization
that excludes sensitive data" ([CLI spans](https://opentelemetry.io/docs/specs/semconv/cli/cli-spans/)).
That is an argument for `Secret<T>` (Axis 19.4) reaching argv: a secret-typed hole
should render as `<redacted>` in every projection, automatically.

**Dry run.** `make -n`, `terraform plan`, `bazel aquery` — three generations of the
same idea, all beloved, all bolted on.

### 6.2 The strongest version in Avra

**Move 1 — one trait, four bindings.** This is the whole section:

```avra
trait Runner {
  fn run(self, c: Cmd) -> Exit
}
//  real      execve                                  (default)
//  memory    a table of Cmd-hash -> Exit             (--profile test, by law)
//  record    real + writes the (hash, Exit) entry    (--record)
//  replay    reads it back, refuses on a miss        (--replay)
//  plan      prints and returns Exit.dry             (--dry-run)
```

`--dry-run`, the test double, the VCR cassette and the build cache are **not four
features**. They are one seam and one content hash, which is why they are cheap and
why they cannot drift apart. That is the argument that makes both this section and
section 5 worth building: neither pays for itself alone; together they are one
mechanism with five uses.

**Move 2 — the cassette key is the cache key.** A replay miss is therefore not "no
recording found", it is a *diff*:

```
error[F7404]: no recording for this command
  │  cmd"git rev-parse ${rev}"
  the nearest recording differs in one argument:
    recorded  ["git","rev-parse","HEAD"]
    requested ["git","rev-parse","main"]
  recorded 2026-08-30, cassette tests/fixtures/git.cassette
  fix: re-record with `avra test --record git`, or make the argument a fixture
```
And `avra test --verify-cassettes` re-runs for real and diffs, so a cassette cannot rot
silently. Bazel's `aquery_differ` is the same idea applied to build actions.

**Move 3 — `avra explain process` as a bounded, ratcheted blast radius.**

```
$ avra explain process
  BINARIES REACHABLE FROM main (4)
    clang     src/build.av:41    ["clang","-c",<Rel>,"-o",<Rel>]      reads/writes declared
    git       src/vcs.av:12      ["git","rev-parse",<string>]
    ld        src/link.av:88     ["ld", ...<List<Rel>>]
    <dynamic> src/plugin.av:31   argv from `cfg.hook` — UNBOUNDED     ← 1 site
  DECLARED in avra.toml:  run = ["clang", "git", "ld"]
  SECRETS reaching argv: none          (a Secret<T> hole renders <redacted>)
  build FAILS: src/plugin.av:31 may exec a binary outside `run`.
    fix: cfg.hook: Cmd  (a Cmd value, minted from the manifest — checkable)
      or #[allow(dynamic_exec)] at the site, which joins the counted hatch list (now 1)
```

The design that makes this real is the same one the sibling doc reached: **a `Cmd` is
minted from a manifest-declared capability, not conjured from a string.** Deno already
proved the coarse version is worth something — `--allow-run=git,ls` limits which
programs may be started, and its docs recommend it precisely to "reduce the risk"
([Deno permissions](https://docs.deno.com/runtime/reference/permissions/)). Avra's
version is finer (per-package, per-binary, with argv shapes) and *checked at build
time*, which Deno's is not.

The honesty riders, both required in the output or the feature is a lie:
- the bound is **package-granularity**, exactly as the sibling doc concedes for roots;
- a `<dynamic>` site defeats it entirely, so the feature's real value is that it turns
  dynamic sites into a **counted, greppable, ratcheted list** — the same discipline
  `make idioms` already runs in this tree, pointed at authority;
- and above all, **it bounds what your program runs, never what the child does.**

### 6.3 Verdict

- **SHIP-IN-V1:** the `Runner` trait with `real` / `memory` / `plan` bindings, the
  test-profile law, and OTel-shaped structured events on every spawn (the schema is
  free; the timing data pays for the build scheduler immediately).
- **SHIP-IN-V1:** `--dry-run`. It is one binding of a trait you are building anyway.
- **SHIP-IN-V1:** `Secret<T>` redaction in every projection, following OTel's own
  "SHOULD NOT be collected by default" guidance for `process.command_args`.
- **SHIP-LATER:** record/replay cassettes. They want the content-addressed cache from
  section 5 to exist first, and shipping them on a separate hash would be the drift
  this whole design is against.
- **SHIP-LATER:** `avra explain process`'s call-graph reachability. It wants
  monomorphisation and a stable call graph; a version that misses sites is worse than
  none because it reads as a guarantee.
- **REFUSE:** any framing of `explain process` as a *security* boundary. It is a
  legibility tool. The security boundary is the OS, and a subprocess crosses it.

---
## 7. The declarative shell

Two separable proposals: a **command literal** whose holes are argv words, and a
**compile-time parse of a shell subset** into typed pipeline nodes. They are judged
separately because the first is unambiguously right and the second is the risky,
high-reward one.

### 7.1 The command literal

**What it is.** `cmd"git commit -m ${msg}"` where `${msg}` becomes exactly one argv
word regardless of its contents. Two shipped designs, and the difference between them
is the whole point:

- **zx** spawns a real bash (`$.shell` defaults to `which bash`, with
  `$.prefix = 'set -euo pipefail;'`) and defends by *quoting well before handing over*:
  "zx automatically escapes and quotes anything within `${...}`"; arrays are quoted
  per-element and joined; `$.quote` is swappable for a different target shell
  ([zx quotes](https://google.github.io/zx/quotes), [configuration](https://google.github.io/zx/configuration)).
- **Bun Shell** never hands anything to an interpreter at all: a reimplemented shell in
  the runtime, no `/bin/sh`, cross-platform, with interpolated values "escaped by
  default" and treated as single literal arguments — `` $`ls ${userInput}` `` with
  `userInput = "file; rm -rf /"` is one argv word. `${{ raw: ... }}` is the explicit
  opt-out and `$.escape()` exposes the machinery
  ([Bun Shell](https://bun.sh/docs/runtime/shell)).
- **Rust `cmd_lib`** goes further and does it at *compile time*, with the cleanest
  statement of the security argument anywhere: **"parsing happens before variable
  substitution, unlike bash which always does variable substitution first."** `$var`
  and `${var}` interpolate as atomic argv components; `$[vec]` splats into multiple
  words; pipes and redirects work "without launching any shell"
  ([cmd_lib](https://docs.rs/cmd_lib/latest/cmd_lib/)).
- **plumbum** reaches the same place without a literal at all: `local["cmd"]["arg"]`
  builds an argv list and `|` wires `Popen` objects directly, never `/bin/sh`
  ([plumbum](https://plumbum.readthedocs.io/en/latest/local_commands.html)).
- **Shelly** escapes by default and its opt-out is instructive: with `escaping False`
  it can no longer guarantee "a single program name" and stops doing `PATH` lookup
  itself ([shelly](https://hackage.haskell.org/package/shelly)) — the escape hatch
  costs you a guarantee, and the library says so.
- **PowerShell** is the cautionary tale from a shipping language: argv passing to
  native commands was broken for over a decade — "Historically, quotes must be escaped
  and it is not possible to provide empty arguments to a native application" — fixed by
  `$PSNativeCommandArgumentPassing` (experimental 7.2, mainstream 7.3), shipped as a
  documented **breaking change**
  ([about_Preference_Variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables#psnativecommandargumentpassing)).

The underlying weakness class is CWE-78, and the standing guidance — pass an argv
array, never a shell string — is why Node has both `exec()` (shell, injection surface)
and `execFile()`/`spawn()` (argv array, no shell), and why Python's docs carry a
security warning on `shell=True`.

**The strongest version in Avra.** `cmd"..."` is a *literal*, not a function taking a
string, so the compiler sees the words:

```avra
let msg  = "fix: don't; rm -rf /"
let flag = ["--no-verify", "--signoff"]

cmd"git commit -m ${msg} ${flag}"
//  argv = ["git", "commit", "-m", "fix: don't; rm -rf /", "--no-verify", "--signoff"]
//         ^ one word, with a quote, a semicolon and spaces in it. Nothing happened.
```

Four typing rules, and the third and fourth are the ones nobody else has:

1. `string` -> exactly one word, always, whatever is in it.
2. `List<string>` -> N words (Bun/zx/`cmd_lib`'s `$[]` all agree; Nushell's requirement
   to write `...` explicitly is the honest alternative and is more ceremony than P3
   allows).
3. `Rel`/`Dir` -> the path *and* an entry in the command's `reads`/`writes` set. The
   interpolation is where the fs capability and the process capability meet, so
   sections 5 and 6 get their data for free from ordinary code.
4. `Secret<T>` -> passed to the child, rendered `<redacted>` in every projection,
   log line and OTel attribute. Directly satisfies OTel's own guidance that
   `process.command_args` "SHOULD NOT be collected by default unless there is
   sanitization that excludes sensitive data".

And a hole can **never** introduce structure. There is no `raw` mode inside `cmd"..."`;
if you want a shell you say so with a different, counted construct (7.2).

**Verdict: SHIP-IN-V1, and it is the single highest-confidence item in this report.**
It costs one lexer rule, it makes an entire vulnerability class unwritable rather than
merely discouraged, and the LLM-first case is decisive: a model reaches for
`exec("git commit -m " + msg)` because ten million training examples did. `cmd"..."`
accepts the muscle memory and refuses the semantics.

### 7.2 Compile-time parsing of a shell subset

**What it is.** `sh"""..."""` containing pipes, `&&`, and redirects, parsed **by the
Avra compiler** into a `Pipeline` of `Cmd` nodes — no `/bin/sh`, at build time.

**Is that even possible?** Yes, and it is well-evidenced: Oils/YSH commits to it —
"OSH and YSH both prefer static parsing, so you get syntax errors up front"
([oils](https://oils.pub)); `mvdan/sh` is a complete Go parser for POSIX/Bash/mksh
driving `shfmt` ([mvdan/sh](https://github.com/mvdan/sh)); tree-sitter-bash is a
maintained incremental grammar. So a parser is not the risk.

**Where it gets hard — and every one of these is documented by the people who tried:**
- `mvdan/sh` explicitly does **not** resolve the `$((` arithmetic vs `((` subshell
  ambiguity, citing backtracking cost, and had to special-case `export`/`let`/`declare`
  as keywords rather than ordinary commands.
- tree-sitter-bash deliberately **excludes** reserved words (`time`, `coproc`, `trap`,
  `exec`, `exit`, `test`, …) because "including those would complicate the parser
  significantly".
- Nothing static can do `$IFS` word splitting, globbing (needs the filesystem at run
  time), `eval`, or command substitution — those are dynamic by construction.
- **xonsh is the warning.** Its subprocess-vs-Python decision is a *runtime namespace
  heuristic*: it checks whether names resolve in the Python namespace and, if one does
  not, "assumes that the left-most name is an external command", retrying the line
  wrapped in `![...]`. The documented remedy is to disambiguate by hand
  ([xonsh FAQ](https://xon.sh/faq.html)). A heuristic whose answer depends on which
  variables happen to be bound is exactly the failure mode an LLM cannot reason about.

**The strongest version in Avra.** A **tiny, fixed, strict subset**, plus one law:

> **Anything the subset accepts means exactly what POSIX means. Everything else is
> refused with a diagnostic naming the Avra way. There is no third category.**

That law is what xonsh lacks and what makes the subset safe to put in front of a model.
Accept: `|`, `&&`, `||`, newline sequencing, `<`, `>`, `>>`, `2>`, `2>&1`, quoting, and
`${hole}`. Refuse, permanently: globs, `$VAR`, `$(...)` / backticks, `eval`, `~`, `;`,
`&`, arithmetic, subshells, `set -e`, functions, and every builtin.

```avra
let report = sh"""
  cat ${log}
    | grep '^ERROR'
    | sort -u
    > ${out}
"""?
```
```
$ avra explain process report.av:9
  pipeline (3 stages, 1 redirect)
    1  cat    ["cat", <Rel log>]                    reads  ${log}
    2  grep   ["grep", "^ERROR"]                    ok_exits [0]  ← 1 is "no match"
    3  sort   ["sort", "-u"]           stdout ->    writes ${out}
  no shell is spawned. cache key: 9f2c…  (of the TREE, not the text)
```

And the refusals, which are the actual product:

```
error[F7501]: `sh` does not expand globs
  │    cat *.log
  │        ──┬──
  │          ╰── `sh` never reads the filesystem while parsing
  fix: cat ${fs.glob(d, "*.log")}     -- a List<Rel> becomes N argv words,
                                         and joins this command's `reads` set
```
```
error[F7502]: `sh` does not substitute commands
  │    echo "on $(git rev-parse HEAD)"
  │               ───────┬──────────
  │                      ╰── `$( )` turns text back into code — the thing
  │                          `cmd` exists to prevent
  fix: let rev = cmd"git rev-parse HEAD".text()?
       echo"on ${rev}"
```
```
error[F7503]: `sh` does not read environment variables
  │    ./build --sdk $SDKROOT
  │                  ────┬───
  │                      ╰── an undeclared env read is invisible to the cache key
  fix: env.get("SDKROOT") ?? fail .MissingEnv("SDKROOT")
       -- and add it to this command's `env` so it enters the hash
```

Each diagnostic is a training example. That is the LLM-first payoff: the model writes
the shell it knows, gets one build error, and learns the language's own answer in a
single round trip — instead of shipping a working-but-injectable line that nobody
reviews.

**The escape hatch, counted.** Real shell scripts exist and P8 says so. `sh.raw` runs
`/bin/sh -c` on a literal string, and it is a **counted, greppable hatch** in the mode
the sibling doc's escalation 4 describes:

```avra
#[allow(raw_shell)]                       // joins the counted hatch list
let out = sh.raw("exec 3<&0; complicated legacy incantation")?
```
```
$ avra build
  hatches: raw_shell 1 (src/legacy.av:88)   -- ratcheted; the count only goes down
```
Nix's `writeShellApplication` is the honest comparison: it punts entirely to a real
shell but at least forces `set -euo pipefail` and runs `shellcheck` over it
([writeShellApplication](https://noogle.dev/f/pkgs/writeShellApplication)). `sh.raw`
should do the same and admit it is doing so.

**Verdict.**
- **SHIP-IN-V1:** the tiny subset (`|`, `&&`, `||`, newline, the five redirects,
  quoting, holes) with the strict-superset law and the refusal diagnostics. This is
  where the "holy shit" lives, and it is only safe *because* it is tiny.
- **SHIP-IN-V1:** `sh.raw` as a counted hatch. Without it people will write
  `cmd"sh" ["-c", s]` and you will have the hazard with none of the accounting.
- **SHIP-LATER:** anything at all beyond the v1 subset, and only with evidence from
  the hatch counter that a real corpus wants it.
- **REFUSE, permanently:** globbing, `$VAR`, `$( )`, backticks, `eval`, `~`, `;`, `&`,
  arithmetic, subshells, and any heuristic that decides between shell and Avra by
  looking at what names happen to be bound. That last one is the xonsh trap, and in an
  LLM's hands it is a correctness bug rather than a papercut.
- **REFUSE:** the old draft's `$"..."` returning a bare `string`. Section 1, items 1–2.

---

## 8. Ranked: the ten "holy shit" moments

1. **A scope that cannot leak a process** — the block does not exit while a child
   tree lives, and it prints its own containment fidelity per platform, so the
   guarantee is checkable rather than claimed. Rust's std documents the opposite
   default; this inverts it.
2. **`cmd"git commit -m ${msg}"` where injection is unwritable** — the hole is one
   argv word whatever it contains, so CWE-78 stops being a thing you remember and
   starts being a thing you cannot express.
3. **A shell literal that accepts the spelling and refuses the semantics** — the model
   writes `cat *.log | grep ERROR`, gets a build error that names the Avra way, and
   learns the language in one round trip instead of shipping an injectable line.
4. **One `component Service` that prints a systemd unit *and a DEGRADED block naming
   everything the target cannot express*** — every existing generator says "review the
   output carefully"; this one says what it lost.
5. **A pipeline failure that names the stage, its argv and its own stderr** — instead
   of exit code 1 from `sort`, with all three stages' stderr interleaved beyond
   attribution.
6. **`--dry-run`, the test double, the VCR cassette and the build cache are one seam
   and one hash** — four beloved features that in every other ecosystem are four
   libraries that drift.
7. **`depends_on` you never write** — the start order is derived from which service's
   config reads which, and so is the restart strategy, so Erlang's three strategies
   collapse into a graph the compiler already has.
8. **An undeclared read is an `EPERM`, not a stale cache hit** — because `reads` is a
   `Rel` set, the cache key and the sandbox policy are the same declaration, which is
   the thing Bazel needs two subsystems to say.
9. **`avra explain process` prints every binary the program can run**, with the
   unbounded sites counted and ratcheted the way `make idioms` already ratchets this
   tree — Bazel's `aquery` for a program instead of a build.
10. **`start(service)` returns when the service is *ready*, not when it is *spawned*** —
    Trio's `task_status.started()` handshake and systemd's `READY=1` turn out to be the
    same primitive, and it deletes `sleep 5` from integration tests forever.

## 9. Ranked: the five traps that would ruin them

1. **Implying the child is contained.** A subprocess inherits none of your sandbox;
   Deno's own docs say `--allow-run` "essentially invalidates the Deno security
   sandbox". If any of §6's legibility is ever described as *security*, the whole
   design becomes a lie people trust. Print the limit in the same output as the claim.
2. **A wrong cache hit.** Non-hermetic tools plus implicit env is a silent, plausible,
   wrong binary — the failure Turborepo had to make strict-mode the default to kill,
   and the one ccache spends its entire caveats section on. Caching must be opt-in per
   action, env empty by default, and `--verify-hermetic` real. A cache that is fast and
   occasionally wrong is worse than no cache.
3. **Promising uniform containment across platforms.** Linux has `cgroup.kill`, Windows
   has job objects, macOS has neither — and `PR_SET_PDEATHSIG` is thread-scoped with a
   documented unclosable window. Ship the guarantee at the weakest platform's level and
   print the difference, or the demo works and production leaks.
4. **The shell subset creeping.** Every addition (`$VAR`, then globs, then `$( )`)
   reintroduces text-becomes-code, and the last one undoes trap 1's fix. The refusal
   list must be a law with a diagnostic each, not a backlog with a "someday".
5. **A projection that lies by omission.** `podman generate systemd` warns its output
   "may need further editing"; kompose has the same problem. A generated unit that
   silently drops the liveness probe is worse than no generator, because someone will
   trust it. **The DEGRADED block is not a nice-to-have — it is the feature.** Without
   it, ideas 4 and 8 above are net-negative.

---

## 10. Summary of verdicts

| # | Idea | Verdict |
|---|---|---|
| 7.1 | `cmd"..."` literal, holes as argv words | **SHIP-IN-V1** — highest confidence in the report |
| 3 | Scope-owned child processes, TERM/grace/KILL | **SHIP-IN-V1** |
| 3 | `start()` = structured spawn + `Ready` handshake | **SHIP-IN-V1** |
| 3 | `explain process --containment` fidelity table | **SHIP-IN-V1** |
| 3 | Three-fiber I/O (no `communicate()` deadlock) | **SHIP-IN-V1** |
| 4 | Pipeline verdict vector + per-stage stderr | **SHIP-IN-V1** |
| 4 | `lines()` / `bytes()` / `json<T>()` decoders only | **SHIP-IN-V1** |
| 2 | `component Service` + typed `Ready` + local supervisor | **SHIP-IN-V1** |
| 2 | Projection to ONE target, with DEGRADED | **SHIP-IN-V1** |
| 2 | `explain services --plan` (s6-rc's compiled order) | **SHIP-IN-V1** |
| 7.2 | `sh"""..."""` tiny subset, parsed at compile time | **SHIP-IN-V1** (tiny, or not at all) |
| 7.2 | `sh.raw` as a counted, ratcheted hatch | **SHIP-IN-V1** |
| 6 | `Runner` trait: real / memory / plan; `--dry-run` | **SHIP-IN-V1** |
| 6 | `Secret<T>` redaction in every projection | **SHIP-IN-V1** |
| 5 | Declared `reads`/`writes`/`env`, empty env default | **SHIP-IN-V1** (compiler's own build only) |
| 5 | `--verify-hermetic` (run twice, diff) | **SHIP-IN-V1** |
| 2 | k8s / multi-target projection | SHIP-LATER |
| 3 | cgroup-delegated containment on Linux | SHIP-LATER |
| 4 | `parse(regex)`, `tee` | SHIP-LATER |
| 5 | Sandbox enforcement, observe-and-key, remote cache | SHIP-LATER |
| 6 | Record/replay cassettes | SHIP-LATER (after §5's hash) |
| 6 | Call-graph blast radius | SHIP-LATER (needs a sound call graph) |
| 2 | `one_for_one`/`rest_for_one`/`one_for_all` as config | **REFUSE** — the graph knows |
| 2 | `restart: always` as the default | **REFUSE** — hides bugs, as systemd/Compose agree |
| 4 | `detect columns`-style heuristics | **REFUSE** — an attempt is not a contract |
| 4 | Merging stderr into stdout by default | **REFUSE** |
| 5 | Caching on by default; mtime as key; undeclared network | **REFUSE** |
| 5 | Any hermeticity claim on macOS in v1 | **REFUSE** — Nix itself defaults `sandbox=false` there |
| 6 | `explain process` framed as a security boundary | **REFUSE** |
| 7 | Globs, `$VAR`, `$( )`, `eval`, shell/Avra heuristics | **REFUSE, permanently** |
| 1 | `$"..."` returning a bare `string` | **REFUSE** — two thirds of the verdict dies |

---

## Appendix: claims I could not verify

- systemd's `DefaultStartLimitIntervalSec=10s` / `DefaultStartLimitBurst=5` —
  freedesktop.org returned 403 throughout; confirmed only via Debian man-page mirrors
  and issue threads.
- Docker's `HEALTHCHECK` numeric defaults (interval 30s, timeout 30s, retries 3) —
  secondary sources only.
- `cgroup.kill`'s exact minimum kernel version (5.14) — timeline-consistent with the
  [LWN patch discussion](https://lwn.net/Articles/855049/), not quoted from a kernel
  version table.
- `PR_SET_PDEATHSIG_PROC` (a fork-inherited, process-scoped variant) — found as an
  lkml proposal only; no evidence it merged. Do not design against it.
- Java `StructuredTaskScope`'s status in JDK 27 (GA due 2026-09-14) — confirmed still
  preview as of JDK 26 (JEP 525, sixth preview); finalisation unconfirmed.
- Swift `TaskGroup`'s exact method signatures (Apple's docs are JS-rendered); semantics
  corroborated from the Swift Book source and SE-0304.
- Nushell's `into record` semantics; xonsh's documented *worked example* of a wrong
  guess (the FAQ documents the heuristic, not a failure log); `just`'s and Taskfile's
  shell models (search-summarised, not primary-fetched); Node's `exec` vs `execFile`
  doc text and CWE-78's own page (standard, uncontested, but not fetched this session).
- Bun Shell's implementation language (Zig vs Rust) — irrelevant to the design; noted
  because the fetched summary was ambiguous.
