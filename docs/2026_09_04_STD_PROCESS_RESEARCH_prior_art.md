# `@std/process` — prior-art survey, bug taxonomy, and a proposed surface

Research for the Avra standard library. Every claim that is a *fact about another
system* carries a URL. Every claim that is a *design opinion* is marked as such.

The survey is organised as: **§0** the frame, **§1** the sources (one steal, one
footgun each), **§A** the bug taxonomy (the core of the document — each class
paired with the design that makes it *unwritable*), **§B** the beautiful surface
(code sketches), **§C** the one-page verdict (five laws + honest counters).

---

## §0 The frame

Subprocess APIs are the single most reliably-broken corner of every standard
library. The reason is structural, and it is worth naming before the survey:

1. **The domain is a Unix ABI from 1970** — `fork`/`exec`/`wait`/`waitpid`,
   8-bit exit statuses, signal numbers, pid integers with reuse, pipe buffers
   with a fixed capacity, fd inheritance as the *default*. Every "modern" API is
   a veneer over these, and the veneer leaks at exactly the points where the
   1970 model has no answer (What is a process *tree*? What does "the child
   failed" mean when it was killed? Who reaps?).
2. **The ergonomic path and the correct path point in opposite directions.**
   The one-liner a human wants to write (`system("git commit -m " + msg)`) is
   the injection vulnerability. Every library since has been an attempt to make
   the short form safe, and most have failed by making the safe form long.
3. **The failure mode is silence.** A full pipe buffer does not raise; it
   hangs. A truncated `maxBuffer` does not raise in some APIs; it truncates. An
   exit status of 256 does not raise; it reads as success. A leaked fd does not
   raise; it is a container escape two years later.

Avra's P6 (paradox collapse) applies hard here. The forced trade-off is
"ergonomic *or* safe"; the collapse is that the *compiler* can parse the
ergonomic form and emit the safe one — the shape xshell and cmd_lib found in
Rust, and the shape Avra can take further because it owns the manifest (P10,
P13) and can therefore make the *capability* declarative rather than a runtime
flag.

---

## §1 The sources

Format: **steal** (one sentence) / **refuse** (the concrete bug class).

### 1.1 Rust `std::process::Command`

<https://doc.rust-lang.org/std/process/struct.Command.html>

The baseline every modern API is measured against: a builder, argv as a list,
no shell anywhere.

> "Note that the argument is not passed through a shell, but given literally to
> the program. This means that shell syntax like quotes, escaped characters,
> word splitting, glob patterns, variable substitution, etc. have no effect."

Notable, well-documented sharp edges *in the docs themselves*:

- `env_clear()` on Unix does **not** leave the child with the parent's `PATH`;
  `execvp` falls back to an OS default (typically `/bin:/usr/bin`). On Windows
  the parent's `PATH` is still searched. The docs' own advice: "To avoid
  surprises, use an absolute path or explicitly set `PATH` on the `Command`."
- A relative program path (`./script.sh`) resolving against the *parent's* cwd
  or against `current_dir` is "platform specific and unstable" — the docs
  recommend `canonicalize`.
- The Windows note: `cmd.exe` and `.bat` files "use a non-standard way of
  decoding arguments" and are "vulnerable to malicious input", where "a
  malicious argument can potentially run arbitrary shell commands." (This is
  the family that produced BatBadBut / CVE-2024-24576.)
- `Child` does **not** wait on drop → zombies.
- Non-zero exit is **not** an error. `Command::new("false").status()?` is `Ok`.

**Steal:** argv-as-list with a builder, and the explicit `Stdio`
`inherit`/`piped`/`null` trichotomy — a program's three real I/O intentions
named as three values instead of inferred from flags.

**Refuse:** *success-by-default*. `status()` returning `Ok` for a failed
program is the single most-copied mistake in the survey; it converts "the build
failed" into "the build ran". Bug class: **unchecked exit status**.

### 1.2 duct (Rust / Python) — Jack O'Connor

<https://docs.rs/duct/latest/duct/> · <https://github.com/oconnor663/duct.py/blob/master/gotchas.md>

duct is the most valuable single document in this survey, because its
`gotchas.md` is an *itemised list of everything std libraries get wrong*, written
by someone who then fixed each one. The list (paraphrased headings, quotes
verbatim):

1. **Reporting errors by default** — "Most programming languages make error
   checking the default … but the child process APIs in most standard libraries
   … do the opposite, ignoring non-zero exit statuses by default."
2. **Catching pipe errors when writing to standard input** — duct "catches and
   ignores broken pipe errors (`EPIPE`)" when feeding stdin.
3. **Cleaning up zombie children** — "child processes hold some OS resources
   even after they exit, until their parent process waits on them."
4. **Making `kill` thread-safe** — "On Unix-like platforms there's a race
   condition between `kill` and `waitpid`" that can kill an *unrelated* process
   if the pid was reused.
5. **Adding `./` to program names given as relative paths** — Unix requires it,
   Windows does not; duct normalises.
6. **Preventing `dir` from affecting relative program paths on Unix** — "On
   Windows the path is interpreted from the parent's working directory, but on
   Unix it's interpreted from the child's."
7. **Preventing pipe inheritance races on Windows** — making a pipe inheritable
   is a *process-global* act, so "any child spawned while a pipe is inheritable
   will inherit it, which is a race condition in multithreaded programs."
8. **Preventing pipe inheritance races on macOS** — "macOS doesn't support
   `pipe2`", so there is "a brief race condition … where other threads spawning
   child processes can accidentally inherit unrelated pipes."
9. **Matching platform case-sensitivity for environment variables.**
10. **Using IO threads to avoid blocking children** — "`start` uses background
    threads to do IO, so that IO makes progress even if `wait` is never called."
    The deadlock it prevents, in duct's own words: "The call to `handle.wait`
    would block until child1 was finished. Then child2 would block writing to
    stdout, because the parent wouldn't be reading it yet. Finally, child1 would
    block on child2 … That would be a deadlock, and it would probably be
    difficult to reproduce and debug."
11. **Killing grandchild processes** — "**Currently unsolved.**" And, crucially:
    "Observing that a child process has exited does not guarantee that its IO
    pipes will close … If the child process spawns any grandchild processes, the
    grandchildren usually inherit copies of the child's IO pipes, and they can
    outlive the child and keep those pipes open indefinitely."

**Steal:** *the whole list is the spec for §A.* Concretely: pipefail-by-default
(`.pipe()` reports either side's failure), errors-by-default with `.unchecked()`
as the named escape, and mandatory concurrent draining so a deadlock has nowhere
to live.

**Refuse:** duct still hands you a `pipe()` whose ends you cannot name, and it
concedes grandchildren as unsolved. An API that stops at the *child* has stopped
one generation too early. Bug class: **orphaned grandchildren holding the pipe
open** — the reason `wait()` hangs forever after the child you care about
exited.

### 1.3 xshell (Rust) — matklad

<https://docs.rs/xshell/latest/xshell/>

The critical move: `cmd!(sh, "git commit -m {msg}")` is **parsed by a proc-macro
at compile time**. The literal text is split into argv *at compile time*;
interpolated values are inserted as *whole arguments*, never re-split. `{var...}`
splats an iterable into multiple arguments.

> "the `cmd!` macro parses the command string at compile time, so you don't have
> to worry about escaping the arguments."

`cmd!(sh, "touch {file}")` with `file = "contains a space"` creates **one** file.
That is the entire injection class, deleted by construction, while keeping the
shell-shaped one-liner.

The `Shell` struct also carries *its own* cwd and env (`push_dir` returns an RAII
guard) rather than mutating the process's global cwd — which is what makes it
safe under concurrency.

**Steal:** **compile-time command templates.** This is the P6 collapse for
Avra: the ergonomics of a shell string, the semantics of argv, decided by the
compiler, which Avra's `LanguageFeature` grammar is *already* built to do. Also
steal the shell-local (not process-global) cwd/env.

**Refuse:** nothing major; the honest limit is that the template can only be a
literal — you cannot build a command dynamically without dropping to the builder,
and xshell's answer (`{args...}` splat) covers most but not all of it. Bug class
avoided at the cost of expressiveness: **dynamic argv construction falls off the
safe path**.

### 1.4 cmd_lib (Rust)

<https://docs.rs/cmd_lib/latest/cmd_lib/>

Goes further than xshell: `run_cmd!` / `run_fun!` parse a *shell-like* language
(pipes `|`, redirects `<` `>`, a `cd` builtin, `$var` and `$[array]`
interpolation) at compile time and emit `std::process` calls — "trying to provide
the redirection and piping capabilities … without launching any shell."

> "Using macros can actually avoid command injection, since we do parsing before
> variable substitution."

That sentence is the design principle in nine words: **parse before substitute.**

**Steal:** "parse before substitute", and the observation that pipes and
redirects are *syntax*, not a shell — a language can own them.

**Refuse:** it re-implements a shell dialect, so users import shell's mental
model (globbing is *not* included and must be done with an external crate; `set
-e` semantics are re-invented). Bug class: **shell-lookalike with different
semantics** — the user's bash intuition is wrong in ways that only show up on
weird inputs. (The same critique lands on plumbum and `sh`.)

### 1.5 tokio::process

<https://docs.rs/tokio/latest/tokio/process/index.html> ·
<https://docs.rs/tokio/latest/tokio/process/struct.Command.html#method.kill_on_drop>

> "a spawned process will, by default, continue to execute even after the
> `Child` handle has been dropped."

> "The tokio runtime will, on a best-effort basis, attempt to reap and clean up
> any process which it has spawned. No additional guarantees are made with
> regard to how quickly or how often this procedure will take place."

And on `kill_on_drop`:

> "Although issuing a `kill` signal to the child process is a synchronous
> operation, the resulting zombie process cannot be `.await`ed inside of the
> destructor to avoid blocking other tasks. … If stronger guarantees are
> required, it is recommended to avoid dropping a `Child` handle where possible,
> and instead utilize `child.wait().await` or `child.kill().await`."

**Steal:** the *honesty*. Tokio documents precisely why drop-based cleanup
cannot be reliable in a destructor: you cannot block in `Drop` to reap.

**Refuse:** the conclusion. "Best-effort cleanup + a doc comment telling you to
be careful" is not a design; it is a bug generator. Bug class: **cleanup by
destructor** — which is unreliable in *every* language that has tried it,
because reaping is a blocking operation and destructors cannot block. The fix is
not a better destructor, it is a **scope** (see Racket custodians §1.13,
Haskell `withProcess` §1.11): the cleanup happens at a *statement boundary* the
compiler can see, where blocking is legal.

### 1.6 Python `subprocess`

<https://docs.python.org/3/library/subprocess.html>

The most-read subprocess documentation on Earth, and a museum of the taxonomy.

- **The shell warning** (verbatim): "If the shell is invoked explicitly, via
  `shell=True`, it is the application's responsibility to ensure that all
  whitespace and metacharacters are quoted appropriately to avoid shell
  injection vulnerabilities."
- **The deadlock warning** on `Popen.wait()` (verbatim): "This will deadlock when
  using `stdout=PIPE` or `stderr=PIPE` and the child process generates enough
  output to a pipe such that it blocks waiting for the OS pipe buffer to accept
  more data. Use `Popen.communicate()` when using pipes to avoid that."
- **The memory warning** on `communicate()` (verbatim): "The data read is
  buffered in memory, so do not use this method if the data size is large or
  unlimited."
- **The signal encoding**: `returncode` is "negative value `-N`" for termination
  by signal N on POSIX. But under `shell=True` you get the *shell's* status,
  which maps signals to `128+N`. **The same event has two different numeric
  encodings depending on a keyword argument.**
- **`timeout=`**: "If the timeout expires, the child process will be killed and
  waited for." — but note *killed*, i.e. `SIGKILL` with no `SIGTERM` grace, and
  only for `run()`; `Popen.communicate(timeout=)` requires the documented manual
  dance:
  ```python
  try:
      outs, errs = proc.communicate(timeout=15)
  except TimeoutExpired:
      proc.kill()
      outs, errs = proc.communicate()
  ```
  Two `communicate` calls. The second one is the part everybody forgets, and
  forgetting it leaks a zombie.
- **`close_fds`** defaulted to `False` until **Python 3.2**, and on Windows until
  **3.7**. A decade of fd leaks was the default.
- **PATH resolution**: "when resolving or searching for the executable path,
  `cwd` overrides the current working directory and `env` can override the
  `PATH`" on POSIX — but on Windows with `shell=False`, "`cwd` does not override
  the current working directory and `env` cannot override the `PATH`." The docs'
  advice: "Using a full path avoids all of these variations."
- **Python 3.12** changed the Windows `shell=True` search order to `%COMSPEC%`
  and `%SystemRoot%\System32\cmd.exe`, so "dropping a malicious program named
  `cmd.exe` into a current directory no longer works." — a *2023* fix to a
  cwd-hijack in the world's most popular scripting language.

**Steal:** `run()` + `CompletedProcess` as the 90% API — one call, one record,
`check=True`. It is genuinely the best-shaped *common case* in the survey.

**Refuse:** `check=False` as the default, `shell=True` existing as a *keyword
argument* (a one-token flip from safe to injectable), and `communicate()` being
the only deadlock-free door while `wait()` sits right next to it looking
equivalent. Bug class: **the safe call and the deadlocking call are adjacent
names with the same shape.**

### 1.7 `asyncio.subprocess`

<https://docs.python.org/3/library/asyncio-subprocess.html>

Same deadlock warning, restated for the async world, plus two new classes:

- **The 64 KiB line limit.** Streams default to `limit=65536`; `readline()` on a
  longer line raises `LimitOverrunError` / `ValueError: Separator is not found,
  and chunk exceed the limit`. **Line-oriented streaming has an invisible
  maximum line length**, and the failure is an exception in the middle of a log
  tail.
- **No `timeout=`.** You must wrap in `asyncio.wait_for()` and kill by hand.
- **GC-based cleanup**: "If the process object is garbage collected while the
  process is still running, the child process will be killed." — i.e. the same
  destructor-cleanup mistake, now non-deterministic.

**Steal:** streams as first-class async readers (this maps directly onto Avra
channels).

**Refuse:** a buffer limit that turns into an exception rather than
backpressure. Bug class: **partial-line / long-line failure in streaming
capture.**

### 1.8 plumbum (Python)

<https://plumbum.readthedocs.io/en/latest/local_commands.html>

`local["ls"]["-l"]` builds *command objects*; `|`, `>`, `<`, `&` are overloaded to
compose them. No shell is invoked for the local case. `run()` returns
`(retcode, stdout, stderr)`; `retcode=` accepts an int, `None` (any), or a tuple
of acceptable codes; `TF` / `RETCODE` modifiers give a bool / int instead of an
exception.

**Steal:** `retcode=(0, 1)` — *declaring the acceptable verdict set at the call
site.* `grep` returning 1 for "no match" is not a failure, and every API that
only offers "check or don't check" forces you to turn checking off entirely.

**Refuse:** the operator cosplay. `>` and `|` *look* like shell but compose
Python objects, so the boundary where shell-quoting *does* reappear (nested
commands over `ssh`) is invisible: plumbum's own docs note that nesting works "by
shell-quoting the nested command", and `sudo[ls | grep[".py"]]` silently means
something different from the `ssh` case. Bug class: **shell semantics reappearing
at a nesting boundary the syntax does not mark.**

### 1.9 `sh` (Python)

<https://sh.readthedocs.io/en/latest/>

Programs become importable Python functions (`from sh import git`). Underscored
kwargs are execution modifiers (`_out`, `_in`, `_bg`, `_timeout`, `_cwd`, `_env`,
`_iter`, `_ok_code`). Exceptions are *dynamically generated per exit code*
(`ErrorReturnCode_2`).

**Steal:** `_iter` (stream lines as an iterator) and `_ok_code` as an
allow-list, and `.bake()` for partial application of a command.

**Refuse:** **`_tty_out` defaults to `True`.** The library allocates a pty by
default, so programs that check `isatty()` behave *differently under `sh` than
under a plain pipe* — colours, progress bars, line buffering, and the loss of
stdout/stderr separation (a pty merges them). This is the TTY-detection bug class
promoted to a default. Also: dynamically-generated exception classes are
unnameable ahead of time, which is hostile to both static analysis and LLM code
generation (P1). Bug class: **capture that changes the program's behaviour.**

---

<!-- SECTIONS FILLED IN AS AGENT REPORTS ARRIVE -->
### 1.10 Go `os/exec`

<https://pkg.go.dev/os/exec> · <https://go.dev/doc/go1.19> · <https://tip.golang.org/doc/go1.20> · <https://go.dev/blog/path-security>

Go is the most interesting source in the survey because it is the only stdlib
that has *shipped fixes* for two of the deepest classes in living memory.

**`Cmd.Cancel` + `Cmd.WaitDelay` (Go 1.20).** `CommandContext` sets `Cancel` to
kill the process when the context is done. `WaitDelay`:

> "If WaitDelay is non-zero, it bounds the time spent waiting on two sources of
> unexpected delay in Wait: a child process that fails to exit after the
> associated Context is canceled, and a child process that exits but leaves its
> I/O pipes unclosed."

And the release notes name the bug class exactly:

> "if WaitDelay is zero (the default), I/O pipes will be read until EOF, which
> might not occur until orphaned subprocesses of the command have also closed
> their descriptors for the pipes."

This is duct's gotcha #11 stated from the other side. The insight worth
extracting: **"the child exited" and "the output ended" are two different
events**, and the second can never happen, because EOF on a pipe requires *every*
holder of the write end to close it — including grandchildren the API never knew
about. Go's answer is a *deadline on the second event*, separate from the
deadline on the first.

**The PATH change (Go 1.19, `ErrDot`).**

> "`Command` and `LookPath` no longer allow results from a PATH search to be
> found relative to the current directory."

`LookPath("prog")` will never return `./prog`; it returns an error satisfying
`errors.Is(err, ErrDot)` — "cannot run executable found relative to current
directory". Windows' `NoDefaultCurrentDirectoryInExePath` is now respected. The
escape hatch is `GODEBUG=execerrdot=0`.

The history matters, because it is the clearest illustration in the survey of a
*taxonomy class shipping as a real CVE in a major language*. The concrete
instance: `go get` invoking cgo, which shells out to the host C compiler *by
name* (`gcc`), doing that PATH lookup from inside the *downloaded package's
source directory*. A malicious module containing a file named `gcc.exe` executes.
That is **CVE-2021-3115**, fixed in Go 1.14.14/1.15.7 (Jan 2021), announced with
the ["Command PATH security in Go"](https://go.dev/blog/path-security) blog post
and the interim `golang.org/x/sys/execabs` shim; the general fix landed in the
stdlib as `ErrDot` in Go 1.19 (Aug 2022). The class itself is Grampp & Morris,
1984. **A forty-year-old bug shipped in the world's most security-conscious
mainstream stdlib in 2021.** (Related: **CVE-2020-27955**, Git LFS, same
mechanism.)

Other Go specifics:

- `Cmd.Env` nil means **inherit the whole parent environment**. Duplicate keys:
  last wins.
- `Cmd.Stdout`/`Stderr` nil means **`/dev/null`**, not inherit — the opposite
  default from Java and .NET.
- `StdoutPipe` carries this in the docs: "**Cmd.Wait will close the pipe after
  seeing the command exit … It is thus incorrect to call Wait before all reads
  from the pipe have completed. For the same reason, it is incorrect to call
  Cmd.Run when using StdoutPipe.**" — a documented ordering contract in prose,
  enforced by nothing.
- `ExitError.Stderr` "may contain only a prefix and suffix of the output, with
  the middle replaced with text about the number of omitted bytes" — a nice
  touch: bounded, and *says so in the data*.
- No portable tree-kill. The Unix idiom is
  `SysProcAttr{Setpgid: true}` then `syscall.Kill(-pgid, SIGKILL)`; nothing
  equivalent on Windows.
- PID reuse is a tracked hazard: [golang/go#13987, "os: on unix Process.Kill()
  can kill the wrong process"](https://github.com/golang/go/issues/13987).

**Steal:** the **two separate deadlines** (`Cancel` = how the child is asked to
die; `WaitDelay` = how long output is allowed to keep arriving after that), and
`ErrDot` — refusing a PATH result found in the cwd, by default, with a named
error.

**Refuse:** `Env == nil` meaning "inherit everything". The most dangerous
default in the file is spelled as the absence of a field.

### 1.11 Java `ProcessBuilder` / `Process`

<https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/ProcessBuilder.html>

- `ProcessBuilder.startPipeline(List<ProcessBuilder>)` (Java 9) — "Starts a
  Process for each ProcessBuilder, creating a pipeline of processes linked by
  their standard output and standard input streams." Only the first builder's
  stdin and last builder's stdout redirects are honoured; everything else must be
  `Redirect.PIPE` or you get `IllegalArgumentException`. If any process fails to
  start, "all processes are forcibly destroyed."
- `ProcessHandle.descendants()` (Java 9) — "the children of the process plus the
  descendants of those children, recursively." **The only portable tree-kill
  primitive in a major stdlib.**
- `inheritIO()` — "gives behavior equivalent to most operating system command
  interpreters, or the standard C library function `system()`."
- `destroyForcibly()` carries a startling caveat: "The default implementation of
  this method invokes `destroy()` and so **may not forcibly terminate the
  process**."
- `Runtime.exec(String)` splits on `" \t\n\r\f"` with a plain `StringTokenizer`,
  **no quote awareness at all**. `C:\Program Files\Java\bin\java` becomes two
  garbage arguments, and quoting does not help because quotes are not honoured
  either. See [CODE WHITE, "Java and Command Line Injections in
  Windows"](https://codewhitesec.blogspot.com/2016/02/java-and-command-line-injections-in-windows.html)
  and JDK-6550942 / JDK-4506936 / JDK-7051946.
- The canonical deadlock writeup is ["When Runtime.exec() won't"
  (JavaWorld, 2000)](https://www.infoworld.com/article/2157336/when-runtime-exec-won-t.html)
  — the article that named the "three `Runtime.exec()` traps". Twenty-six years
  old and still the top result.

**Steal:** `startPipeline` — the pipeline as a **first-class object**, wired by
the runtime, with the "intermediate stages must be PIPE" invariant checked; and
`descendants()` as a portable process-tree.

**Refuse:** `redirectErrorStream(true)` as the answer to interleaving. It gets
you order at the cost of *ever being able to tell the streams apart again* — a
lossy, irreversible merge performed at the OS level. (See §A.16: Avra can have
both.)

### 1.12 .NET `System.Diagnostics.Process`

<https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.processstartinfo.argumentlist>

- **`ArgumentList`** (added .NET Core 2.1): "Strings added to the list **don't
  need to be previously escaped**." And the crucial framing: "ArgumentList and
  the Arguments property are independent of one another and **only one of them
  can be used at the same time**." The safe API is not a parameter *on* the
  unsafe API; it is a *different, mutually exclusive* API. That is the exact
  shape §C's Law 1 argues for.
- `UseShellExecute` **defaults to `false` on .NET Core / .NET 5+ but `true` on
  .NET Framework** — a security-relevant default that flipped between runtime
  generations. Redirection and shell-execute are mutually exclusive.
- The deadlock is documented on `RedirectStandardOutput`: "A deadlock condition
  can result if the parent process calls `p.WaitForExit` before
  `p.StandardOutput.ReadToEnd` and the child process writes enough text to fill
  the redirected stream."
- The subtler one, on `WaitForExit(int)`: "**When standard output has been
  redirected to asynchronous event handlers, it is possible that output
  processing will not have completed when this method returns.** To ensure that
  asynchronous event handling has been completed, call the `WaitForExit()`
  overload that takes no parameter after receiving a `true` from this overload."
  A **two-call protocol documented in prose** — `WaitForExit(timeout)` then
  `WaitForExit()`.
- `Kill(bool entireProcessTree)` (.NET Core 3.0): "processes where the call lacks
  permissions to view details are silently skipped", and "`WaitForExit` and
  `HasExited` do not reflect the status of descendant processes … will indicate
  that exiting has completed after the given process exits, **even if all
  descendants have not yet exited**."

**Steal:** `ArgumentList` as a *parallel, mutually exclusive* API — and
`Kill(entireProcessTree: true)` existing at all.

**Refuse:** a two-call protocol whose necessity lives only in a doc paragraph.
Bug class: **"the completion you were handed is not the completion you needed."**

### 1.13 Node.js `child_process`

<https://nodejs.org/api/child_process.html>

The canonical cautionary tale. `exec(command)` **defaults to `shell: true`** and
takes a single string. Node's own docs, repeated for every shell-invoking entry
point:

> "Never pass unsanitized user input to this function. Any input containing shell
> metacharacters may be used to trigger arbitrary command execution."

Other specifics:

- **`maxBuffer` defaults to 1 MiB** for `exec`/`execFile`/`*Sync`. Docs: "If
  exceeded, the child process is terminated and any output is truncated." There
  is a dedicated doc anchor `#maxbuffer-and-unicode` about truncation landing
  *mid multi-byte UTF-8 sequence*. Modern Node raises
  `ERR_CHILD_PROCESS_STDIO_MAXBUFFER`.
- **The `stdio` fd array** is genuinely good: `['pipe','inherit',fileFd,'ipc']`,
  each slot independently `'pipe' | 'inherit' | 'ignore' | Stream | fd |
  'ipc' | 'overlapped'`.
- `detached: true` → `setsid(2)`, own process group; `process.kill(-child.pid)`
  to signal the group. Docs: "On Linux, child processes of child processes will
  not be terminated when attempting to kill their parent."
- **Windows signals are a lie**: `SIGKILL`, `SIGTERM`, `SIGINT`, `SIGQUIT` all
  forcibly terminate identically; `SIGWINCH` throws `ENOSYS`; `SIGSTOP` throws
  `ERR_UNKNOWN_SIGNAL`.
- `EPIPE` on writing to a dead child's stdin, with no built-in guard —
  [nodejs/node#40085](https://github.com/nodejs/node/issues/40085),
  [#29206](https://github.com/nodejs/node/issues/29206).
- The `'spawn'` event exists specifically so callers have a race-free signal that
  no `'error'` for a *failed spawn* is still coming — i.e. "did it start?" and
  "did it work?" needed separating.

**Steal:** the per-fd `stdio` array. Three streams is the common case, not the
law; a design that hard-codes exactly three cannot express `--status-fd=3`.

**Refuse:** `exec` — a string command, a shell by default, a 1 MiB silent
ceiling, and the safe sibling one letter away (`execFile`). Bug class:
**injection by default with the safe alternative differing only by name.**

### 1.14 Deno — `Deno.Command` and `--allow-run`

<https://docs.deno.com/api/deno/~/Deno.Command> · <https://docs.deno.com/runtime/fundamentals/security/>

`new Deno.Command(cmd, { args, cwd, env, clearEnv, stdin, stdout, stderr, uid,
gid, signal, windowsRawArguments })`. `.output()` / `.outputSync()` /
`.spawn()`. `CommandOutput = { code, signal, success, stdout: Uint8Array, stderr:
Uint8Array }`. Streams are WebStreams. `Deno.run` was removed in Deno 2.0 as "the
old and error-prone subprocess API" — one documented failure being resource
leakage that tripped Deno's own test resource sanitizer
([denoland/deno#9885](https://github.com/denoland/deno/issues/9885)).

**Bytes, not strings, by default.** `stdout` is a `Uint8Array` and always was;
decoding is the caller's explicit act.

**And then the permission story, in Deno's own words:**

> "`--allow-run` lets the program spawn subprocesses. A subprocess runs as a
> separate program with its own permissions, not the restricted set you granted
> the Deno process."

> "`--allow-run=deno` is especially dangerous: a script that can start a new
> `deno` process can start it with `--allow-all`, inheriting none of the parent's
> limits and escaping the sandbox entirely."

> "Be careful when combining `--allow-write` with `--allow-run`. Write access to
> a directory that contains an allowed executable (or to the executable itself)
> lets a program overwrite that binary, so the next subprocess it spawns runs
> attacker-controlled code."

> "Treat both [`--allow-run` and `--allow-ffi`] as equivalent to `--allow-all`
> when deciding whether to trust the code you are running."

**Steal:** `Uint8Array` output as the default; and the *honesty* of that last
sentence, which every capability-based design must internalise.

**Refuse:** the belief that a subprocess capability can be scoped by naming the
binary. It cannot — the moment you can run `bash`, `sh`, `env`, `perl`, `make`,
`git` (which runs hooks), or the runtime itself, the allow-list is decorative. A
per-binary allow-list is a *lint*, not a sandbox, and should be sold as one. Bug
class: **capability laundering through a permitted binary.**

### 1.15 Bun — `Bun.spawn` and Bun Shell (`$`)

<https://bun.sh/docs/api/spawn> · <https://bun.sh/docs/runtime/shell>

`Bun.spawn` is a solid Node-shaped API with better `stdin` polymorphism (a
`Blob`, `Response`, `TypedArray`, `Bun.file()`, `ReadableStream`, or fd), an
`.exited` promise, `resourceUsage()` (maxRSS, CPU time), and a PTY option.

**Bun Shell is the important artifact.** `$` is a template tag backed by a
**native shell interpreter written in Rust inside the Bun process** — not
`/bin/sh`. Consequences:

- It runs identically on Windows. No `cmd.exe` / PowerShell / WSL split.
- **Every `${...}` interpolation is escaped by default.** `` $`ls ${userInput}` ``
  with `userInput = "f.txt; rm -rf /"` passes one literal argument.
- **Arrays expand to separate, individually-escaped arguments**:
  `` $`cat ${['a.txt','b.txt']}` `` → `cat a.txt b.txt`.
- Raw injection is opt-in and *visibly ugly*: `` $`echo ${{ raw: '$(foo)' }}` ``.
  `$.escape(str)` is exposed.
- Native cross-platform builtins: `cd ls rm echo pwd bun cat touch mkdir which
  mv exit true false yes seq dirname basename`.
- Redirection targets can be **JS objects** — `` $`cat < ${response}` `` with a
  `Response`, a `Buffer`, a `Bun.file()`.
- `.text()` `.json()` `.lines()` `.blob()` `.quiet()` `.nothrow()` `.cwd()`
  `.env()`; **throws on nonzero exit by default**.

Bun's own documented footguns are the two that matter most:

1. Escaping evaporates the moment you invoke a real shell yourself:
   `` $`bash -c "echo ${x}"` `` is fully injectable again.
2. **Argument injection survives correct escaping.** A perfectly escaped
   `"--upload-pack=echo pwned"` handed to `` $`git ls-remote origin ${branch}` ``
   is still read by *git* as a flag. Escaping is not validation.

**Steal:** the whole shape — a template tag, escaped by default, arrays splatting
to argv, an owned interpreter so semantics are one thing everywhere, and raw
injection spelled so it is visible in review.

**Refuse:** re-implementing a *shell language* (globs, `$(...)`, `2>&1`, word
splitting) as the surface. Bun must, because JS cannot parse at compile time.
Avra can parse the template into argv at compile time (xshell/cmd_lib) and *not*
ship a shell dialect at all. Also refuse the framing "interpolation is safe" —
footgun 2 proves it is only *quoting* that is safe.

### 1.16 zx

<https://google.github.io/zx/> · <https://google.github.io/zx/quotes>

Same `$` template tag, but **it shells out to real bash** (`$.shell` defaults to
`which bash`). Automatic quoting via a swappable `$.quote` (there is a
`quotePowerShell`). `ProcessPromise` is a `Promise` subclass with `.stage`,
`.exitCode`, `.text()` `.lines()` `.json()`, `.pipe()`, `.kill()`, `.abort()`,
`.timeout(ms, signal)`, `.nothrow()`, `.quiet()`, `Symbol.asyncIterator` over
stdout lines, and `$({halt: true})` for deferred start. `within()` scopes
cwd/env for a block.

zx's own documented footguns are instructive because they are the *inverse* of
injection: **you cannot use the shell features you expect in an interpolation
slot.** A glob in `${}` is escaped into a literal and silently does not expand;
`~` does not expand. You must call `glob()` / `os.homedir()`.

**Steal:** `.timeout(ms, signal)` naming the signal at the call site; `within()`
as a scoped config block; `Symbol.asyncIterator` over lines.

**Refuse:** bash as the engine. It re-imports every bash semantic (word
splitting, `errexit`, locale, `$IFS`) into a library whose selling point was
escaping them, and it is why the glob footgun exists at all. Bug class:
**escaped-slot vs shell-feature confusion** — the failure is silent (a glob that
matched nothing) rather than loud.

### 1.17 Haskell `typed-process`

<https://hackage.haskell.org/package/typed-process> · <https://tech.fpcomplete.com/blog/2017/02/typed-process/>

The most *type-forward* design in the survey, and the one with the sharpest idea.

`data ProcessConfig stdin stdout stderr` — **three type parameters tracking what
each stream produces**. `ProcessConfig Handle Handle Handle` is a different type
from `ProcessConfig () (STM ByteString) ()`. Configuring a stream as `nullStream`
and then trying to read it is a **compile error**, not a runtime `Nothing`.

The data constructor is not exported; you build only through `proc :: FilePath ->
[String] -> ProcessConfig () () ()` (argv, no shell) or `shell :: String -> …`.
Stream specs: `inherit`, `nullStream`, `byteStringInput bs`, `byteStringOutput`
(captures via **a background draining thread into an `STM ByteString`** — the
deadlock is structurally impossible), `createPipe` (the raw escape hatch).

Lifetime is bracket-based and the two brackets are named for their *policies*:

- `withProcessWait` — wait for normal exit; force-kill only if the inner action
  threw.
- `withProcessTerm` — always `stopProcess` on scope exit, however you leave.

`stopProcess` terminates, **waits for actual exit**, then closes stream
resources — i.e. it is a real reap, done at a point where blocking is legal,
which is exactly what a destructor cannot do (§1.5).

Snoyman's stated motives for the clean break: stream configuration untracked by
types; a "big split" between `CreateProcess`-based and command/argv-pair
functions making it hard to set env/cwd *and* capture output simultaneously; and
`process` being a GHC boot library, so breaking it is prohibitively expensive.

**Also:** *turtle* (external commands as `Shell` streams; `inproc` = argv/no
shell, `inshell` = shell string — the safety split is in the *name*), and
*shelly* (`run :: FilePath -> [Text] -> Sh Text`, shell-escaped by default with
`escaping False` as the opt-out, and per-`Sh` env/cwd so it is thread-safe).

**Steal:** *the stream configuration is part of the type.* This is directly
expressible in Avra generics and is the single strongest idea in the survey for
P1 (LLM-first): a model that configures `stdout: null` and then reads
`out.stdout` gets a **compile error with a fix**, not a runtime null.

**Refuse:** nothing significant. The honest cost is that the type parameters make
signatures noisy; Avra can hide most of it behind defaults and inference.

### 1.18 Scala `os-lib`

<https://github.com/com-lihaoyi/os-lib> · <https://www.lihaoyi.com/post/HowtoworkwithSubprocessesinScala.html>

`os.proc(cmd: Shellable*)` → `.call()` (blocking, `CommandResult`) / `.spawn()`
(handle) / `.stream()` (callback, no buffering).

The load-bearing idea is **`Shellable`**: a *closed* typeclass of implicit
conversions into `Seq[String]` — `String`, `CharSequence`, `Symbol`, `Path`,
`RelPath`, numerics, `Option[T]`, any `Iterable[T]`, `Array[T]`. So
`os.proc("rm", "-rf", paths)` with `paths: Seq[Path]` works, every element
becomes exactly one argv entry, no shell is invoked, nothing is word-split or
glob-expanded. Ergonomics and safety are *the same code path*.

`check = false` opts out of the default `os.SubprocessException` on nonzero exit.
`env` is **merged into**, not replacing, the current environment.

**Steal:** `Shellable`. Avra's answer is a trait — `ToArgs` — with impls for
`string`, `Path`, `int`, `List<T: ToArgs>`, `T?` (absent → no argument, which
kills the "conditionally add a flag" string-building pattern), so
`run("rustc", [src, opt_flag, extra_args])` type-checks with mixed element kinds
and cannot produce a mis-split argument.

**Refuse:** `env` merging by default (see §A.3) — convenient, and it is exactly
how `LD_PRELOAD` and a leaked `AWS_SECRET_ACCESS_KEY` reach the child.

### 1.19 Zig `std.process.Child`

`lib/std/process/Child.zig` · <https://github.com/ziglang/zig/issues/22504>

Two ideas, both excellent.

**1. `Term` is a tagged union, not an int:**

```zig
pub const Term = union(enum) {
    Exited: u8,
    Signal: u32,
    Stopped: u32,
    Unknown: u32,
};
```

"Exited with 9" and "killed by SIGKILL" are **structurally distinct values**. No
`128+n` convention, no negative-N convention, no `WIFEXITED` macro, no way to
compare a signal to zero and conclude success.

**2. `max_output_bytes` is always present.** `run(.{ …, max_output_bytes: usize
= 50*1024 })` and the underlying `collectOutput(child, alloc, stdout, stderr,
max_output_bytes)`. Exceeding it returns `StdoutStreamTooLong` /
`StderrStreamTooLong`. **There is no unbounded `readAllOutput` in the std API at
all.** Both streams drain concurrently, so the deadlock class is closed too.

Also: `StdIo` is `Inherit | Ignore | Pipe | Close` per stream; `expand_arg0` is
an explicit choice; every allocation takes an explicit allocator; there is no
hidden shell anywhere.

Known rough edges (Zig's own tracker): `collectOutput` can leak or crash when
handed a non-empty `ArrayList` ([#20952](https://github.com/ziglang/zig/issues/20952),
[#16653](https://github.com/ziglang/zig/issues/16653)); on Windows it waits for
the longest-living process rather than returning per-process
([#22709](https://github.com/ziglang/zig/issues/22709)); and an
[overhaul is under discussion](https://github.com/ziglang/zig/issues/22504)
precisely because the `init → spawn → collectOutput → wait` protocol is easy to
misuse (`collectOutput` drains but does **not** reap).

**Steal:** both ideas, verbatim. `Term` becomes Avra's `Exit` enum; bounded
capture becomes the *only* capture.

**Refuse:** the four-step protocol with an unenforced ordering contract. Bug
class: **a lifecycle whose correct sequence the type system does not encode.**

### 1.20 Elixir / Erlang Ports

<https://hexdocs.pm/elixir/Port.html> · <https://www.theerlangelist.com/article/outside_elixir>

`Port.open({:spawn, cmd}, opts)` runs `cmd` through `/bin/sh -c` — **a shell, by
default, in the "obvious" constructor.** `{:spawn_executable, path}` with `:args`
is the safe counterpart. `System.cmd/3` is the safe high-level API (no shell,
argv list); `System.shell/1,2` and `:os.cmd/1` are the shell ones. The
argv-vs-shell split lands *in the name*, as in Racket.

The port has exactly one **owner process**; if the owner dies the port closes.
Framing is explicit: `{:packet, N}` (1/2/4-byte length prefix — binary-safe) or
`{:line, N}` (newline-delimited, bounded). `:exit_status` opts into receiving
`{port, {:exit_status, status}}`, which is otherwise not delivered.

**And then the defect that spawned an ecosystem:** closing a port closes the
*pipes* and sends **no signal to the OS process**. A child that is busy computing
and not touching stdio never notices, and becomes an orphan under `init`,
indefinitely. This is why
[erlexec](https://github.com/saleyn/erlexec) exists (a C companion managing
process groups and SIGKILL propagation) and why
[muontrap](https://github.com/fhunleth/muontrap) exists (cgroups on Linux, so
tearing down the cgroup kills every descendant). Jurić's own workaround absent
those: **write a wrapper shell script** that watches its own stdio and
self-terminates.

**Steal:** the **owner** concept — a subprocess belongs to exactly one supervising
green thread, and that thread's death is an event the process's lifetime is tied
to. This maps perfectly onto Avra's green threads + structured concurrency. Also
steal `{:packet, N}` framing: a length-prefixed, **binary-safe** child protocol
that never has a "partial line" problem.

**Refuse:** cleanup that closes pipes and calls it termination. Bug class:
**cleanup that signals nothing** — the most silent orphan generator in the
survey.

### 1.21 Swift `Process` → `swift-subprocess`

<https://developer.apple.com/documentation/foundation/process> · <https://github.com/swiftlang/swift-subprocess>

Old `Process` (née `NSTask`): `standardOutput: Any?` — **untyped**, so
misconfiguration is a runtime cast failure. Its one good idea is
`terminationReason: TerminationReason` — `.exit` vs `.uncaughtSignal` — a
two-case enum separating exit code from signal number (the same instinct as Zig's
`Term`, less complete). Its deadlock is the standard one and has [its own
long-running Swift Forums
thread](https://forums.swift.org/t/the-problem-with-a-frozen-process-in-swift-process-class/39579);
the prescribed fix is hand-rolled `readabilityHandler` + `DispatchGroup`.

The new **swift-subprocess** ([proposal
0007](https://github.com/swiftlang/swift-foundation/blob/main/Proposals/0007-swift-subprocess.md))
is the direction of travel across the whole industry: `async` `run()` overloads,
output as an `AsyncSequence` of buffers (`.strings()` for lines), a **closure
form that binds the child's lifetime to the enclosing task scope**, and a
"teardown sequence" triggered by task cancellation. `.name("foo")` for PATH
search vs an explicit URL.

**Steal:** cancellation propagating into the child as a *teardown sequence*
(TERM, wait, KILL), driven by structured concurrency rather than by a
`try/finally` the caller writes.

**Refuse:** `Any?`-typed stream configuration. Bug class: **stream config
divorced from stream type** — precisely what typed-process fixes.

### 1.22 Racket

<https://docs.racket-lang.org/reference/subprocess.html>

Two ideas.

**1. The `*` convention.** `process` / `system` run a command string through the
platform shell; `process*` / `system*` take argv and never invoke a shell. The
suffix is load-bearing and consistent across the family — **you can tell at the
call site, without checking docs, whether a shell is involved.**

**2. Custodian-scoped lifetime.** `current-subprocess-custodian-mode` is a
parameter: `#f` (default — not registered), `'kill` (custodian shutdown calls
`subprocess-kill` with `force? = #t`), `'interrupt` (POSIX interrupt). A
custodian is Racket's *general* resource scope — threads, ports, subprocesses —
so a whole tree of subprocess lifetimes can be scoped to one object and torn down
together. `subprocess-group-enabled` puts new children in their own process
group so `subprocess-kill` reaches grandchildren.

And Racket documents the limit honestly: because `process`/`system` may spawn an
intermediate shell, custodian kill reaches the shell and "probably not" what the
shell spawned.

**Steal:** the custodian — a *general, ambient, tree-shaped* resource scope that
owns many children at once, generalising Haskell's per-call bracket. And the `*`
naming convention as a cheap, effective readability device.

**Refuse:** custodian mode defaulting to `#f`. The good behaviour is opt-in.

### 1.23 Kotlin/JVM process libraries

<https://github.com/zeroturnaround/zt-exec> · <https://github.com/pgreze/kotlin-process> · <https://github.com/JetBrains/pty4j>

- **zt-exec**: `.command(...)`, `.readOutput(true)`, **`.timeout(n, unit)`**
  (auto-destroy), **`.destroyOnExit()`** (JVM shutdown hook so the child dies with
  the JVM), **`.exitValues(0, 1)`** (declared acceptable verdicts, else
  `InvalidExitValueException`), `.redirectOutput()` to a logger / stream / line
  callback.
- **kotlin-process**: `Redirect` as a **sum type** — `PRINT`, `CAPTURE`,
  `SILENT`, `ToFile(File)`, `Consume { flow -> … }` — instead of stream plumbing.
- **pty4j**: real PTY allocation (ConPTY on Windows, WinPTY fallback) — the only
  library in the survey that treats "the child wants a terminal" as a first-class,
  explicit capability rather than an accident.

The independent articulation of what these exist to paper over
([javachannel.org](https://javachannel.org/posts/external-program-invocation-in-java/)):
"**if you read either stdout or stderr, you must read both**", and you must call
`waitFor()` even when you do not want the output, or you leave a zombie until JVM
exit.

**Steal:** timeout and lifetime-binding as **declarative builder properties**,
not caller-written guards; `Redirect` as a sum type; PTY as an explicit,
first-class option (see §A.17).

**Refuse:** `destroyOnExit()` being opt-in, and being a *shutdown hook* — which
does not run on `SIGKILL`, on a hard crash, or on `Runtime.halt`.

### 1.24 Nushell — structured pipelines

<https://www.nushell.sh/book/running_externals.html> · <https://www.nushell.sh/book/stdout_stderr_exit_codes.html>

Internal commands pass typed records/tables. **External commands are a hard
bytes/text wall** — Nushell never guesses structure from a subprocess; you write
`^curl … | from json` explicitly. `^` forces PATH lookup past a same-named
builtin. Lists must be spread (`...$paths`) rather than implicitly splatted.

`… | complete` runs an external to completion and returns **one record**
`{stdout, stderr, exit_code}` — the whole outcome as a single value.
`$env.LAST_EXIT_CODE` holds the most recent external's code.

**Breaking change in 0.98.0** ([PR
#13515](https://github.com/nushell/nushell/pull/13515)): a non-zero exit or
signal termination from an external now raises a catchable Nushell error; it was
previously swallowed. `$env.config.display_errors.exit_code` controls *printing*,
independent of catchability.

Redirection: `o>` `e>` `o+e>` to files, `e>|` to pipe *just stderr* onward.
Known gap: stdout and stderr to two *different* files in one call is currently
rejected ([#7364](https://github.com/nushell/nushell/issues/7364)).

**Steal:** the hard type wall (P9: boundaries are contracts) — a process emits
bytes, and every promotion to structure is a visible parse. And `complete`: **the
whole outcome as one record** rather than three out-parameters.

**Refuse:** changing exit-code error semantics in a point release. For a P1
LLM-first language this is the sharpest possible warning: training data straddles
such a change, and generated code silently means something else. Bug class:
**exit semantics as an unversioned contract.**

### 1.25 PowerShell

<https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parsing>

Objects flow down the pipe — until a native command, where everything is text
again and *three independent failure signals* appear:

1. `$LASTEXITCODE` — the raw int from the last native program.
2. `$?` — a bool; for natives it is `$LASTEXITCODE -eq 0`, for cmdlets it is
   "did a terminating error occur". Two different derivations behind one name.
3. **stderr becoming an `ErrorRecord`** (`NativeCommandError`) — triggered by
   *any* stderr byte, regardless of exit code, and historically *not* suppressed
   by `$ErrorActionPreference = 'SilentlyContinue'`. Every well-behaved Unix tool
   that logs progress to stderr (git, ffmpeg) looked like it was failing.

`$PSNativeCommandUseErrorActionPreference` (experimental 7.3, stable and on by
default in **7.4**) finally makes a non-zero exit raise a
`NativeCommandExitException` that respects `$ErrorActionPreference`.

Argument passing was equally broken until **7.3**'s
`$PSNativeCommandArgumentPassing`: `Legacy` (the old mangling), `Standard`
(faithful, via `ProcessStartInfo.ArgumentList`), `Windows` (default on Windows —
`Standard` *except* for `cmd.exe`, `cscript.exe`, `wscript.exe`, and
`.bat`/`.cmd`/`.js`/`.vbs`/`.wsf` targets, which fall back to `Legacy` because
those consumers expect the broken quoting). The `--%` stop-parsing token turns
off PowerShell parsing for the rest of the line.

**Steal:** shipping a semantics change as a **named, versioned preference** with
a migration window rather than a flag day.

**Refuse:** three failure signals per call. Bug class: **wrong-signal error
handling** — checking `$?` after a pipeline reads a stale value, and treating
stderr output as failure misclassifies every progress-logging tool.

### 1.26 Oil / YSH

<https://github.com/oils-for-unix/oils/blob/master/doc/error-handling.md> · <https://oils.pub/release/0.37.0/doc/simple-word-eval.html>

Oils' own words: "POSIX shell has fundamental problems with error handling. With
`set -e` aka `errexit`, you're damned if you do and damned if you don't."

The diagnosis, which is the most precise statement of `errexit`'s failure in
print:

- A command used as an `if`/`while`/`&&`/`||` **condition** is immune to errexit
  — and *as soon as a function is called as a conditional, errexit is suppressed
  for that function's entire body*. Action at a distance.
- Only a pipeline's **last** command is checked, absent `pipefail`.
- Command substitution runs in a subshell that (pre-4.4) does not inherit
  errexit; `local x=$(false)` masks failure because the *assignment builtin's*
  status is what is tested.
- Process substitution failures are invisible to the parent entirely.

Oils' answer is not to fix errexit but to add orthogonal, opt-in machinery:
`try { … }` (which itself **always exits 0**, so it never trips an enclosing
errexit, and records the outcome in a separate `_error` register — deliberately
*not* `$?`), `if failed { … }`, `_pipeline_status` (PIPESTATUS equivalent),
`_process_sub_status`, `shopt -s inherit_errexit` (which bash later adopted),
`command_sub_errexit`, `process_sub_fail`, `strict_errexit` (a *static* refusal
of the `if myfunc` pattern), and `boolstatus cmd` — which treats 0/1 as
true/false but **aborts on 2+**, targeting `grep`'s "no match (1)" vs "real error
(2)" ambiguity directly.

And `simple_word_eval`, which is the deepest idea here. Unquoted substitution in
POSIX shell is a hidden three-stage pipeline: substitute → **word-split on
`$IFS`** → **glob-expand, and elide the argument entirely if empty**. So
`file="my document.txt"; rm $file` deletes up to three things; `pat='*.py'`
unexpectedly globs; an empty variable *vanishes as an argument* rather than
passing as `''`. `simple_word_eval` collapses this to one stage — every
substitution yields **exactly one argument, verbatim** — with splitting and
globbing as explicit opt-ins (`@[split(s)]`, `@[glob(p)]`).

**Steal:** (a) `try` that always exits 0 and reports through a **separate
channel** — decoupling "did that fail" from "is the enclosing failure machinery
about to fire"; (b) `boolstatus` — refusing to interpret an out-of-contract code
as a boolean; (c) `simple_word_eval` as the *default and only* semantics: one
substitution, one argument, always.

**Refuse:** needing an opt-in dialect switch at all. Avra has no legacy. Bug
class: **silent multi-stage reinterpretation of a string as code** — triggered
merely by *not quoting*.

### 1.27 bash — the baseline

<https://mywiki.wooledge.org/BashFAQ/105> · <https://mywiki.wooledge.org/CommandSubstitution>

- `false | true` exits **0** without `set -o pipefail`. With it, the pipeline's
  status is the rightmost non-zero stage's.
- `PIPESTATUS` (bash-only) holds every stage's code — but is **clobbered by the
  next command**, so it must be copied immediately.
- `set -e`'s immunity list is BashFAQ/105's seven cases (conditions, non-last
  pipeline stages, `&&`/`||` chains, functions-called-as-conditions, command
  substitution subshells, assignment builtins, process substitution).
- `IFS` defaults to `$' \t\n'` and governs both word splitting and `read`.
- **`$(cmd)` strips *all* trailing newlines** — it cannot distinguish "none" from
  "one" from "several". Bash 5.3 added `${| cmd; }`, which captures via `$REPLY`
  *without* stripping.
- **Exit-code space collision**: `128+N` for signals (141 = SIGPIPE, 130 =
  SIGINT, 137 = SIGKILL, 143 = SIGTERM), `126` = found but not executable
  (permission, bad shebang, wrong arch, `noexec` mount), `127` = not found — all
  sharing the 0–255 namespace with program-chosen codes. `yes | head -1`
  legitimately SIGPIPEs `yes`, and `pipefail` faults the pipeline on 141 unless
  special-cased (Oils has `sigpipe_status_ok` for exactly this).
- `system()`/`popen()` spawn `/bin/sh -c` and inherit the whole environment —
  `PATH`, `IFS` (which can subvert splitting inside the invoked shell even for
  otherwise-safe strings), and **locale** (`LC_NUMERIC` flips decimal comma vs
  point; `LC_COLLATE` changes sort order), so a program that shells out and parses
  stdout misparses numbers under an unexpected locale. See
  [dwheeler, "Environment Variables"](https://dwheeler.com/secure-programs/Secure-Programs-HOWTO/environment-variables.html).

**Steal:** `PIPESTATUS` as *the default*, not an opt-in — every stage's verdict,
retained, in the result value.

**Refuse:** the shared code namespace. Bug class: **exit-code space collision** —
a program legitimately exiting 141 is indistinguishable from one killed by
SIGPIPE, and no amount of `$?` decoding can separate them.

### 1.28 Procfile supervisors — foreman, overmind, process-compose

<https://github.com/F1bonacc1/process-compose> · <https://github.com/DarthSim/overmind>

foreman: `Procfile`, spawn, forward signals, aggregate logs. No dependency graph,
no health checks. Overmind adds real **tmux** panes per process (so colours,
interactivity and attaching a debugger work) and per-process restart.

**process-compose** is the one with the ideas:

- **`depends_on` conditions — five distinct definitions of "ready"**:
  `process_started` (forked), `process_completed` (exited, any code),
  `process_completed_successfully` (exited 0), `process_healthy` (passed its
  readiness probe), `process_log_ready` (a specific line seen, via
  `ready_log_line`).
- **Probes**, Kubernetes-shaped: `readiness_probe` and a liveness probe, each
  `exec` (zero exit = healthy) or `http_get`, with `initial_delay_seconds`,
  `period_seconds`, `timeout_seconds`, `success_threshold`, `failure_threshold`.
- **`availability`**: `restart: no|on_failure|always`, `backoff_seconds`,
  `max_restarts`; plus `exit_on_failure` and `exit_on_end` at the composition
  level.
- **`shutdown`**: `command` (a pre-stop hook inheriting the process's env),
  `signal` (default 15), `timeout_seconds` (default 10, after which **the whole
  process group** gets SIGKILL), and `send_keys` for interactive processes
  (`'q'`, `'\x03'`).

**Steal:** readiness as a **spectrum, chosen by the dependent**. "The process
forked" and "the process can serve traffic" are different facts with different
latencies, and the *consumer* is who knows which one it needs.

**Refuse:** the shape of
[process-compose#403](https://github.com/F1bonacc1/process-compose/issues/403) —
"process with `availability.restart: on_failure` gets permanently killed when its
readiness_probe fails". Bug class: **two failure sources feeding two separately
designed state machines.** Probe failure and process exit must feed *one*
restart/backoff machine, and the design must say so out loud.

### 1.29 systemd

<https://www.freedesktop.org/software/systemd/man/systemd.service.html> · <https://www.freedesktop.org/software/systemd/man/systemd.kill.html>

**`Restart=`** decomposes "why did it stop" into orthogonal triggers:
`no` (default), `always`, `on-success` (clean exit: code 0 *or* one of
SIGHUP/SIGINT/SIGTERM/SIGPIPE — the "clean signal" set), `on-failure`
(non-zero code, abnormal signal, timeout, or watchdog), `on-abnormal` (signal /
timeout / watchdog but **not** a plain non-zero exit), `on-abort` (only an
uncaught signal outside the clean set), `on-watchdog` (only a missed `sd_notify`
keepalive). **Four independent facts, each separately opt-in** — where
process-compose collapses to two and most libraries to one boolean.

**The circuit breaker**: `StartLimitIntervalSec=` (default 10s) /
`StartLimitBurst=` (default 5) — exceed the burst and the unit is marked
**failed** with "start request repeated too quickly". A restart loop becomes a
bounded, observable failure instead of infinite resource burn. `RestartSec=`
(default 100ms) is the delay between attempts.

**`KillMode=`** (default `control-group`): `control-group` kills everything left
in the unit's cgroup — the only mode that reliably reaps daemonized
grandchildren; `mixed` signals the main process, then SIGKILLs the rest of the
cgroup after the stop timeout; `process` touches only the tracked main process,
letting descendants **escape the unit's lifecycle entirely**; `none` sends no
signal at all and is documented as strongly discouraged/deprecated.

**The escalation ladder**: `KillSignal=` (default SIGTERM) → wait
`TimeoutStopSec=` → `FinalKillSignal=` (default SIGKILL, gated by
`SendSIGKILL=`, default yes). `SendSIGHUP=` additionally tells shell-like
children their controlling connection died.

**`Type=` and readiness**: `simple` (started the instant fork+exec succeeds — the
weakest possible guarantee), `exec` (waits for `execve()` to succeed),
`forking` (waits for the original parent to exit), `oneshot`,
**`notify`/`notify-reload`** (the service calls `sd_notify(3)` with `READY=1`
when it is *actually* able to serve; systemd blocks "started" until that arrives;
`notify-reload` adds `RELOADING=1`/`READY=1` around SIGHUP), `dbus`, `idle`.
`NotifyAccess=` gates which process may send it.

**Steal:** (a) the `Restart=` taxonomy — four distinguishable stop reasons, not a
`crashed?` boolean; (b) the start-limit circuit breaker as a *default*; (c)
`sd_notify READY=1` as a **push** readiness signal from inside the process,
complementing external probes; (d) the escalation ladder as the only shape a
"stop" ever takes.

**Refuse:** `KillMode=process` / `none`. Bug class: **orphaned grandchildren
surviving their supervised parent** — only cgroup-wide (or, portably, process
group-wide) killing reaps a tree, which is exactly why systemd deprecated the
alternatives.

### 1.30 Bazel / Nix — a process as a cacheable pure function

<https://bazel.build/basics/hermeticity> · <https://bazel.build/remote/cache-remote> · <https://nix.dev/manual/nix/2.18/compiler/derivations>

**Bazel**: every build step is an *action* — a closed set of declared inputs, a
command (argv + env), declared outputs. The Remote Execution API formalises the
cache key exactly: an `Action` digest over `command_digest` (argv **and env**) +
`input_root_digest` (a Merkle hash of every declared input's *content*) +
`timeout` + `platform`. Differ in any of those and you get a different key.
Results live in an `ActionCache` keyed by that digest, with blobs in a CAS — so
an identical action digest is a guaranteed hit regardless of which machine ran
it. `--spawn_strategy` picks execution: `local`/`standalone` (no isolation),
`sandboxed`/`linux-sandbox` (only declared inputs visible), `worker` (a persistent
reused process), `remote`.

Bazel's own list of hermeticity breakers: wall-clock time and build IDs, reliance
on host-installed tools rather than versioned toolchains fetched as inputs,
writing into the source tree during a build, unconstrained logic in build config.

**Nix**: a derivation's builder gets **only** `args` and an `env` set. Attributes
become env vars (paths are copied to the store first and the var becomes the
store path; derivations are built first and the var becomes their output path).
The output store path is itself `hash(name, all-build-inputs)`, so any input
change produces a different, non-colliding path. The sandbox strips everything a
Unix process expects: **`PATH=/path-not-set`** (no ambient tool lookup at all —
every tool must be a declared input), **`HOME=/homeless-shelter`**, a private
`/tmp`, and only declared store paths visible. **Network is denied for every
derivation** — except **fixed-output derivations**, which declare
`outputHash`/`outputHashAlgo`/`outputHashMode` up front, are granted network in
exchange, and are verified against that hash afterwards. After a build Nix
normalises timestamps to the epoch and permissions to read-only.

**Steal:** the whole model — *a process with declared inputs, argv, env and
outputs is a pure function and can be memoised* — and specifically **Nix's
fixed-output escape hatch as the P6 collapse** between "hermetic" and "needs the
network": you may have the network *if* you commit to the output's hash. That is
"escape hatches everywhere" (P8) done without abandoning the guarantee.

**Refuse:** nothing — but note the honest cost. Bug class this creates:
**ambient-environment leakage that never fails, only silently poisons the
cache.** A process reading wall-clock, `$HOME`, hostname, locale, or an
undeclared file builds "successfully" and produces a subtly different result that
gets cached and served as if pure. The defence is *enumerating what is visible*
(Nix's stripped env, Bazel's sandbox), never *detecting leakage afterwards* —
which is an argument for §C Law 4 (closed environment) independent of security.

---
# §A THE BUG TAXONOMY

Twenty-four classes. Each carries: the **mechanism** (why it happens at the OS
level), **who has it**, **the concrete bug**, the **design that makes it
unwritable**, and — honestly — the **residue** that survives the design.

Three tiers of "unwritable", named so the claims stay honest:

- **T1 — refused by the compiler.** The program does not build. This is the only
  tier that deserves the word *unwritable*.
- **T2 — impossible at runtime.** The API has no shape that performs the wrong
  act; the runtime owns the correct one.
- **T3 — loud.** It can still happen, but it fails with a named diagnostic
  instead of hanging, truncating, or silently succeeding.

Anything a design can only reach at T3 should say so, because a "safe by
default" claim that is really T3 is how the next generation inherits the class.

---

## A1. Shell injection via string commands

**Mechanism.** `system()`/`popen()`/`/bin/sh -c` take *one string* and re-parse
it as a program. Any byte of that string that came from data is now code.
`CWE-78`.

**Who.** C `system`, Python `shell=True` and `os.system`, Ruby `` `backticks` ``
and one-arg `system`, PHP `exec`/`shell_exec`, Node **`exec` by default**, Java
`Runtime.exec(String)` (which does not even shell out — it tokenizes with
`StringTokenizer`, which is worse), .NET `ProcessStartInfo.Arguments` string,
Erlang `Port.open({:spawn, cmd})`, Racket `system`/`process`, Elixir
`System.shell`, PowerShell native-command lines, every shell script ever.

**The concrete bug.** `run("git commit -m " + msg)` where `msg` contains
`"; rm -rf /"`. Or, subtler and far more common in practice: `msg` contains a
newline, an apostrophe, or a `$` — and the command breaks in production on a
commit message rather than in a security review.

**Unwritable by (T1).** *There is no function whose parameter is a command
string.* The command literal `cmd"git commit -m ${msg}"` is a **grammar
construct parsed by the Avra front end at compile time** into an argv list —
this is xshell's proc-macro and cmd_lib's "parse before substitute", promoted to
a language feature because Avra owns its grammar. `${msg}` is a *hole in the
argv vector*, not a hole in a string; it can never be re-scanned for
metacharacters because there is no scanner downstream. A genuine shell is a
different type, `ShellScript`, produced only by the `sh"""…"""` literal, consumed
only by `run_shell`, and **gated in `avra.toml`** — so an audit is `grep 'shell'
avra.toml`, one line per package, not a corpus-wide grep for string
concatenation.

**Residue.** `run(cmd"bash", ["-c", user_text])` is still expressible, because
`bash` is a program and `-c` is an argument. No type system stops that. What the
design buys is that the dangerous thing is now *visible*: the word `bash` appears
in the source. §C Law 1's counter-argument addresses this directly.

## A2. Argument injection (option smuggling) — distinct from A1

**Mechanism.** Correct quoting delivers the value as *one argument*. The target
program then parses it as an *option*, because it begins with `-`.

**Who.** Every argv-based API in the survey, including the ones marketed as
injection-proof. **Bun's own docs name it**: an escaped
`"--upload-pack=echo pwned"` in `` $`git ls-remote origin ${branch}` `` is still
read by git as a flag. Same for `tar --to-command`, `rsync -e`, `find -exec`,
`curl -o`, `ssh -o ProxyCommand`, `zip --unzip-command`.

**The concrete bug.** A web app runs `git ls-remote origin <user-branch>`; the
attacker supplies a branch named `--upload-pack=…`. Quoting was perfect. RCE
anyway.

**Unwritable by (T3, honestly).** No general design closes this — it requires
knowledge of the callee's argument grammar, which no caller-side type system
has. What Avra *can* do:

1. A `ToArgs` impl for a `Positional` wrapper: `${positional(branch)}` emits
   `--` before the value if the program is known to accept `--` (registry), or
   refuses a leading `-` at runtime with a named diagnostic.
2. **A lint the compiler can actually run** (P10): a command literal whose
   interpolation lands in a *positional* slot, fed by a value the compiler cannot
   prove is `-`-free, emits a warning with a fix — insert `--`, or wrap in
   `positional(…)`. Avra's compiler knows the argv shape at compile time, which
   is exactly the fact no other language's subprocess library has.

**Residue.** Large. This is the honest limit of "escaping is safe". The
documentation must say what Bun's says, and louder.

## A3. PATH hijacking / relative-path lookup in the cwd

**Mechanism.** `execvp` searches `$PATH`. If `.` or an empty entry (`PATH=:/bin`
— an empty element *means* the cwd) is in `PATH`, or if the platform searches the
cwd implicitly, then `cd`-ing into attacker-controlled data and running a
common command name executes their file. Grampp & Morris named this in **1984**.

**Who.** Every language, historically. **Go shipped a CVE for it in 2021**
(CVE-2021-3115: `go get` → cgo → looks up `gcc` by name from inside the
downloaded module's directory; a file named `gcc.exe` in the module executes) and
fixed the class in the stdlib in Go 1.19 with `ErrDot`. **Python fixed the
Windows variant in 3.12** ("dropping a malicious program named `cmd.exe` into a
current directory no longer works"). Git LFS: CVE-2020-27955.

**The compounding trap:** the *program path* and the *cwd option* interact.
Rust's docs: a relative program path with `current_dir` set is "platform specific
and unstable". duct's gotcha #6: "On Windows the path is interpreted from the
parent's working directory, but on Unix it's interpreted from the child's." So
`run("./build.sh", cwd: "sub/")` runs **different files on different platforms.**

**Unwritable by (T2 + T1).**

1. **Lookup never consults the cwd, ever, with no flag to re-enable it.** Go's
   `ErrDot` without the `GODEBUG` escape.
2. **An empty or `.` `PATH` element is a hard error at spawn**, not a silent cwd
   search.
3. **Resolution happens exactly once, at spawn, against the *resolved* `PATH`
   from the child's env**, and the resolved absolute path is recorded in the
   `Output` (P7: visible magic — you can print what actually ran).
4. **T1:** a *relative* program path is a **different constructor**. `cmd"./x"`
   does not compile; you write `run(local("./build.sh"))`, which is documented as
   "resolve against the child's cwd" and does so on every platform. The
   ambiguity is deleted by making the two meanings two spellings.

**Residue.** An attacker who controls `PATH` still controls what `git` means.
That is what A4 is for.

## A4. Environment inheritance leaks, and environment injection

**Mechanism.** Two directions, usually discussed as one:

- **Leak (outbound).** `fork`+`exec` copies `environ` by default. Every secret
  the parent holds (`AWS_SECRET_ACCESS_KEY`, `GITHUB_TOKEN`, `DATABASE_URL`) is
  handed to every child, including `curl`, including a build script, including
  whatever a package's `postinstall` runs. It is also visible in `/proc/PID/environ`
  on many configurations.
- **Injection (inbound).** A subset of variables are *executable*:
  `LD_PRELOAD`, `LD_LIBRARY_PATH`, `LD_AUDIT` (glibc);
  `DYLD_INSERT_LIBRARIES`, `DYLD_LIBRARY_PATH` (macOS, stripped only under SIP
  for protected binaries); `BASH_ENV` and `ENV` (sourced by non-interactive
  bash/sh); `IFS` (changes word splitting *inside* any shell you invoke, which
  can subvert an otherwise-safe command string); `PATH`; `PYTHONPATH`,
  `PERL5LIB`, `NODE_OPTIONS`, `RUBYOPT`, `GIT_SSH_COMMAND`,
  `GIT_EXTERNAL_DIFF`; `LC_*` (see A22). Shellshock (CVE-2014-6271) was
  environment-borne code execution by definition.
  See [SEI CERT ENV03-C](https://wiki.sei.cmu.edu/confluence/display/c/ENV03-C.+Sanitize+the+environment+when+invoking+external+programs).

**Who.** Inheritance-by-default is universal. Go: `Env == nil` means inherit
everything — **the most dangerous default in the survey is spelled as the absence
of a field.** os-lib *merges into* the current env. Rust, Python, Node, Java,
.NET, Deno, Bun: inherit by default. Nix is the only system in the survey that
inherits *nothing* (`PATH=/path-not-set`, `HOME=/homeless-shelter`).

**The concrete bug.** A CI job runs `npm install`; a transitive dependency's
install script reads `process.env` and exfiltrates the deploy key. No code in
your program did anything wrong. This is the supply-chain attack of the decade
and it is *entirely* an env-inheritance bug.

**Unwritable by (T2, with a T1 escalation).** **The environment is closed by
default.** A child receives exactly what the manifest and the call site declare:

```toml
[process.env]
pass = ["PATH", "HOME", "LANG", "TERM"]     # names passed through from the parent
set  = { LC_ALL = "C" }                     # pinned for every child
```

Inheriting wholesale is `env: inherit_all()` — a named, greppable act. And two
teeth beyond a default:

- **T1:** the *dangerous* names — `LD_PRELOAD`, `LD_AUDIT`, `DYLD_*`,
  `BASH_ENV`, `ENV`, `IFS` — **cannot be set by a literal at all**. `env { IFS
  "…" }` is a compile error naming why. Setting one requires
  `env.unsafe_set(name, value)`, which the manifest must permit. This is the one
  place a deny-list beats an allow-list, because these names are *known*, few,
  and never legitimately set from application code.
- **P7:** `Output.env` records what the child actually received.

**Residue.** The default breaks `git` (which wants `HOME` for config, `SSH_AUTH_SOCK`
for agents), `cargo` (`CARGO_HOME`, `RUSTUP_HOME`), and interactive tools
(`TERM`). §C Law 4's counter-argument owns this; the mitigation is a small set of
named profiles (`env.posix`, `env.developer`) plus a diagnostic that *names the
missing variable* when a child fails with something PATH-shaped.

## A5. File-descriptor inheritance leaks (missing CLOEXEC)

**Mechanism.** `fork` copies the whole fd table; `exec` keeps every fd that is
not marked `FD_CLOEXEC`. So a child inherits your open database socket, your
listening socket, your `/etc/shadow` handle from a moment of privilege, your
inotify fd, your log file — and can read or write through them regardless of its
own permissions.

**Who.** **Python's `close_fds` defaulted to `False` until 3.2** (2011), and on
Windows until 3.7. C, C++ and Zig leak by default
([ziglang/zig#18887](https://github.com/ziglang/zig/issues/18887)). Mozilla ran a
[systematic CLOEXEC audit](https://bugzilla.mozilla.org/show_bug.cgi?id=1463873).
The class is live: **CVE-2024-21626** (runc "Leaky Vessels") is a container
escape caused by an fd leaked into the container's process, and runc has an
[advisory covering several breakouts "due to internally leaked
fds"](https://github.com/opencontainers/runc/security/advisories/GHSA-xr7r-f8xq-vfvv).

**The concrete bug.** A server accepts a connection, spawns a helper, and the
helper inherits the *listening* socket. The helper crashes but its own child
lives on, holding the port — the server cannot restart. Or: a setuid helper
inherits a writable fd to a file the invoker could not open.

**Unwritable by (T2).** **Every fd Avra opens is `O_CLOEXEC` at creation** (via
`open(…, O_CLOEXEC)`, `pipe2(…, O_CLOEXEC)`, `SOCK_CLOEXEC`, `accept4`) — never
`fcntl` afterwards, which is a race in a threaded program (duct's gotchas #7 and
#8 are exactly this race on Windows and macOS, where `pipe2` is unavailable). The
child's fd table is then **constructed**, not inherited: the `stdio` record names
fd 0, 1, 2 and any extras explicitly, and everything else is closed.

**Residue.** An fd from a C `extern` binding is not ours and may not be CLOEXEC.
The FFI boundary must document this; `stdio.extra(3, fd)` should be the only way
a non-standard fd reaches a child, so the leak has one door.

## A6. The stdout/stderr full-pipe deadlock

**Mechanism.** A pipe has a fixed kernel buffer (64 KiB on Linux by default).
When it fills, the writer blocks. If the parent is blocked in `wait()` for the
child's exit, and the child is blocked writing to a pipe the parent is not
reading, neither ever proceeds. If the parent reads stdout *to completion* before
touching stderr, the same deadlock occurs on the stderr buffer.

**Who.** **Every single one.** This is the universal class:

- Python: documented on `Popen.wait()` — "This will deadlock when using
  `stdout=PIPE` or `stderr=PIPE` and the child process generates enough output…"
- .NET: documented on `RedirectStandardOutput` — "A deadlock condition can result
  if the parent process calls `p.WaitForExit` before `p.StandardOutput.ReadToEnd`…"
- Java: ["When Runtime.exec() won't"](https://www.infoworld.com/article/2157336/when-runtime-exec-won-t.html),
  2000, still the canonical writeup.
- Swift: [its own Forums thread](https://forums.swift.org/t/the-problem-with-a-frozen-process-in-swift-process-class/39579).
- Go: `StdoutPipe`'s "it is incorrect to call Wait before all reads from the pipe
  have completed."
- Kotlin/JVM (javachannel): "**if you read either stdout or stderr, you must read
  both.**"
- Haskell's old `process`; Elixir raw ports; C by construction.

Solved *structurally* by only two: **typed-process** (`byteStringOutput` spawns a
draining thread) and **Zig** (`collectOutput` drains both concurrently). duct
solves it too, with IO threads, and documents why.

**The concrete bug.** It works on your machine for a year, because the output was
under 64 KiB. Then a test starts failing verbosely, and CI hangs until the job
timeout — with no error, no stack, and a "flaky" label.

**Unwritable by (T2 + T1).**

1. **There is no API that hands you one pipe end and a `wait()`.** Capture is
   whole (`Output`), or streamed as **channels** — and Avra has green threads, so
   the runtime spawns one drainer per stream unconditionally, at zero syscall
   cost relative to what it must do anyway. Draining is not a thing the caller
   can forget, because the caller never touches a pipe.
2. **T1 escalation, stolen from typed-process:** the `Command` type carries its
   stream configuration in its type parameters —
   `Command<Stdin, Stdout, Stderr>`. Configuring `stdout: null` and then reading
   `out.stdout` is a **compile error**, not a runtime null. Avra generics express
   this directly.

**Residue.** A caller who takes `stdio.raw()` (the P8 escape hatch) can rebuild
the deadlock. It should require naming both readers, so the shape of the mistake
is at least visible.

## A7. Unbounded capture, silent truncation, and OOM

**Mechanism.** "Give me the output" is unbounded by nature; the child decides how
much. Either you buffer it all (OOM) or you cap it (truncation).

**Who.** Python: "The data read is buffered in memory, so do not use this method
if the data size is large or unlimited." Rust `output()`: unbounded. Go
`Output()`: unbounded. Java, .NET, Deno, Bun, os-lib: unbounded. **Node caps at
1 MiB (`maxBuffer`) and, historically, truncated** — with a dedicated doc anchor
about the truncation landing *mid multi-byte UTF-8 sequence*. **Only Zig gets it
right**: `max_output_bytes` is present on every output-collecting path with no
unbounded alternative in the std API at all, and exceeding it is
`StdoutStreamTooLong`. Go's `ExitError.Stderr` bounds itself *and says so in the
data* ("the middle replaced with text about the number of omitted bytes").

**The concrete bug.** Two shapes, both bad. Unbounded: `docker logs` on a busy
container OOM-kills the supervisor. Truncating: `git diff` output silently loses
its tail, the parser sees a valid-looking prefix, and the wrong patch is applied.

**Unwritable by (T2).** **Capture is bounded, always, and overflow is an error,
never a truncation.** `run()` takes `capture_limit` (manifest default, e.g.
8 MiB) and answers `Err(OutputTooLarge { limit, stream })`. There is **no
unbounded capture function**. Unbounded output is a *different verb* —
`stream()`, which yields a channel and never accumulates — so the choice
"buffer it or stream it" is made at the call site, which is the only place that
knows.

**Residue.** A caller can set `capture_limit: 4GiB`. That is P8 working as
intended: the limit is *named at the site*, so a reviewer sees the decision.

## A8. Zombie processes / forgotten `wait`

**Mechanism.** On Unix an exited child stays in the process table as a zombie
until its parent reaps it with `wait`/`waitpid`. Zombies consume pid table slots;
enough of them exhaust the pid space.

**Who.** Rust: `Child` does not wait on drop. Go: `Wait` "releases any resources
associated with the Process"; `Release` "only needs to be called if Wait is not."
Java/Kotlin: forgetting `waitFor()` leaves a zombie until JVM exit. Tokio reaps
"on a best-effort basis" with "no additional guarantees". Python's `asyncio` kills
on GC — non-deterministically.

**The concrete bug.** A long-running service spawns a helper per request and
checks `is_alive()` instead of waiting. After some days: `fork: Resource
temporarily unavailable`, and every subsequent spawn fails, including the ones
that would have logged the problem.

**Unwritable by (T2).** **There is no un-reaped child**, because there is no
handle you can drop. Every child is created inside a `spawn(…) { child -> … }`
scope; leaving that block by *any* path (normal, `?`, `fail`, cancellation) runs
the teardown, which ends in a `wait`. Reaping is done at a **statement
boundary**, where blocking is legal — which is exactly what a destructor cannot
do, and exactly why tokio's `kill_on_drop` documentation reads as an apology.
This is Haskell's `withProcessTerm` and Racket's custodian, made the *only* door.

**Residue.** `detach()` exists (P8) and hands the child to the OS deliberately.
It must be a distinct verb with a distinct return type (no `wait` on it), so
"I meant to do that" is legible.

## A9. Orphaned children when the parent dies

**Mechanism.** When the parent dies, the child is re-parented to `init` (or the
nearest subreaper) and keeps running. Nothing in POSIX ties a child's life to its
parent's.

**Who.** Everyone. `PR_SET_PDEATHSIG` is the Linux mitigation and is [full of
traps](https://man7.org/linux/man-pages/man2/pr_set_pdeathsig.2const.html): "The
'parent' in this case is considered to be the **thread** that created this
process" — so it fires when a *thread* exits, not the process; "The
parent-death signal setting is **cleared for the child of a `fork(2)`**"; it is
cleared "when executing a set-user-ID or set-group-ID binary"; and "if the parent
thread and all ancestor subreapers have already terminated by the time of the
`PR_SET_PDEATHSIG` operation, then **no parent-death signal is sent**" — a race
with no closing. On BSD/macOS the equivalent is a `kqueue` `EVFILT_PROC`
`NOTE_EXIT` watch, which is a different mechanism with different failure modes.
zt-exec's `destroyOnExit()` uses a JVM shutdown hook, which does not run on
SIGKILL. **Elixir ports are the worst case:** closing a port closes the pipes and
**sends no signal at all**, which is why erlexec (a C companion) and muontrap
(cgroups) exist.

**The concrete bug.** `overmind`/`foreman` is Ctrl-C'd; the webpack dev server it
started keeps holding port 3000; the next `npm start` fails with `EADDRINUSE` and
the developer reboots.

**Unwritable by (T2, best-effort by nature).** A layered guarantee, each layer
covering the previous one's hole:

1. **Every child starts in its own process group** (`setpgid` in the
   `posix_spawn` file actions) — so signalling the group reaches grandchildren
   (A10).
2. **Scope exit signals the group**, with escalation (A15).
3. **`PR_SET_PDEATHSIG` on Linux / `kqueue NOTE_EXIT` on BSD** as the
   parent-died backstop, set in the child *after* fork, with the documented race
   closed by a re-check of `getppid()` immediately after the call.
4. **On Linux, a cgroup per supervised group when available** — systemd's
   `KillMode=control-group`, which is the only mechanism that reliably reaps a
   tree, and muontrap's answer for Elixir.

**Residue.** A `SIGKILL`ed parent runs no code, so layers 2 and 4 do not fire;
only 3 and the cgroup do. And on macOS there is no cgroup. This must be
documented as best-effort, at T2-with-caveats, and *not* claimed as a guarantee.

## A10. Orphaned grandchildren holding the pipe — the EOF that never comes

**Mechanism.** This is A9's evil twin and deserves its own number because the
*symptom* is completely different. Grandchildren inherit copies of the child's
stdout/stderr write ends. EOF on a pipe requires **every** holder of the write end
to close it. So the child you care about can exit cleanly while a daemonized
grandchild holds the pipe open forever — and your `wait()`, which reads to EOF,
hangs.

**Who.** duct calls it "**Currently unsolved**" and documents it precisely:
"Observing that a child process has exited does not guarantee that its IO pipes
will close … grandchildren … can outlive the child and keep those pipes open
indefinitely." Go's 1.20 release notes: "I/O pipes will be read until EOF, which
might not occur until orphaned subprocesses of the command have also closed their
descriptors for the pipes." It is the reason `Cmd.WaitDelay` exists.

**The concrete bug.** `ssh host 'nohup ./server &'` returns instantly from the
shell but hangs your program forever, because the backgrounded server holds the
ssh session's stdout. Every developer has hit this and blamed ssh.

**Unwritable by (T2).** **Two deadlines, never one** — Go's insight, made
mandatory:

- `timeout` bounds *the child's life* (TERM → KILL, on the group).
- `drain_grace` (default: small, e.g. 2s) bounds **how long output may keep
  arriving after the child has exited**. On expiry the pipes are force-closed and
  the result carries `truncated_by_grandchild: true` — a *fact in the data*,
  never a hang and never a silent short read.

Because the child is in its own process group and teardown signals the group, the
grandchild usually dies before this fires; the grace is the backstop for the
detached/re-parented case.

**Residue.** A grandchild that ignores TERM, is in a different session, and holds
the pipe still forces the truncation path. That is the honest floor — but it is a
*bounded* floor with a flag in the result, not an infinite hang.

## A11. Exit status as a count, not a verdict

**Mechanism.** `exit(n)` truncates to 8 bits: `n & 0xFF`. `exit(256)` is
`exit(0)`. The wait status packs the code into the high 8 bits of a 16-bit word,
which is why a raw status of 256 means "exited 1" and why `WEXITSTATUS` exists.

**Who.** Every Unix program. The bug is written by the *program*, but the API
invites it by typing the exit as an `int`.

**The concrete bug.** A linter counts violations and returns the count. 256
violations → exit 0 → **CI goes green on the worst commit in the repo's
history.** (This project's own doctrine already states the rule: "A PROCESS
STATUS IS A VERDICT, never a count".)

**Unwritable by (T1).** `exit()` in Avra **does not take an int**. It takes a
`Verdict`:

```avra
enum Verdict { Success, Failure, Usage, NotFound, Custom(code: int) }
```

`Custom` is range-checked at compile time when the argument is a literal, and at
runtime otherwise — `exit(Custom(count))` with an out-of-range count is a
**named trap**, not a wraparound. And a `main` returning `Result` maps `Err` to
`Failure` automatically, so the common case never touches a number.

**Residue.** A child written in C still does the wrong thing. Avra cannot fix
other people's programs — but it can refuse to *encourage* the pattern in its
own, and it can make the reading side (A12) unable to misinterpret the result.

## A12. Signals vs exit codes — three incompatible encodings for one event

**Mechanism.** "The child was killed by SIGSEGV" is encoded as:

- a wait status where `WIFSIGNALED` is true and `WTERMSIG` is 11 (the kernel);
- **`128 + 11 = 139`** (every shell);
- **`-11`** (Python's `returncode`);
- `Exited: 11` vs `Signal: 11` (Zig — the only one that keeps them apart).

And these collide with real exit codes: **126** = found but not executable (bad
shebang, no execute bit, wrong architecture, `noexec` mount); **127** = not found
on `PATH`; **141** = SIGPIPE *or* a program that legitimately chose 141.
`yes | head -1` produces a genuine SIGPIPE in `yes`, and `set -o pipefail` faults
the pipeline on it — which is why Oils needed a `sigpipe_status_ok` option.

**Who.** Everyone except Zig (`Term` tagged union) and, partially, Swift
(`terminationReason`: `.exit` vs `.uncaughtSignal`). Python is uniquely bad
because **the same event has two encodings depending on a keyword argument**:
`returncode` is `-N` normally, but `128+N` under `shell=True`, because you are
then reading *the shell's* status.

**The concrete bug.** `if code != 0 && code != 141 { fail }` — written to tolerate
SIGPIPE — silently swallows a real failure the day a tool starts using 141 for
something, or the day the pipeline runs under a shell that reports it as `-13`.

**Unwritable by (T1).** The verdict is a **tagged union**, Zig's `Term`
generalised, and it is the *only* thing `run` reports:

```avra
enum Exit {
  Done                              // exited 0
  Code(code: int)                   // exited non-zero
  Killed(signal: Signal)            // terminated by a signal
  Stopped(signal: Signal)           // stopped, not terminated
  NotFound(program: string)         // the 127 case, as a fact
  NotExecutable(path: string, why: string)   // the 126 case
}
```

`Signal` is an enum, not an int. **There is no `.code: int` field on `Output`.**
You cannot compare a verdict to zero, cannot add 128 to it, cannot mistake a
signal for a code. `NotFound` and `NotExecutable` are lifted out of the numeric
space entirely and reported by the *spawn*, where the truth is known, rather than
inferred from a shell's convention.

**Residue.** `Code(141)` from a program that really did SIGPIPE-and-report is
still ambiguous if the child was a shell. That ambiguity belongs to the shell,
and the design's answer is that Avra does not run one.

## A13. "Success but stderr", and the wrong failure signal

**Mechanism.** Three independent facts — exit code, stderr content, and stream
liveness — get conflated into one boolean.

**Who.** **PowerShell is the case study**: `$LASTEXITCODE` (int),
`$?` (bool, derived differently for natives and cmdlets), and stderr becoming a
`NativeCommandError` **triggered by any stderr byte regardless of exit code**,
historically not suppressible by `$ErrorActionPreference = 'SilentlyContinue'`.
Every well-behaved Unix tool that logs progress to stderr (git, ffmpeg, curl,
rsync, wget) therefore "failed". The inverse error is equally common: CI scripts
that `grep` stderr for "error" and miss a clean non-zero exit.

**The concrete bug.** `git clone` prints "Cloning into 'x'..." to stderr and exits
0. A wrapper treats stderr-non-empty as failure and the deploy aborts. Or:
`curl -f` exits 22 with an empty stderr and the wrapper reports success.

**Unwritable by (T1).** **Stderr is data, never a verdict.** `Output.err` is
`Bytes`. There is no boolean derived from it and no code path that consults it.
The verdict is `Output.exit`, and it is the `Exit` union of A12. If a program's
contract really is "stderr means trouble", you write that predicate yourself, at
the site, visibly. And — Oils' `boolstatus` — a *declared* acceptable-verdict
set:

```avra
run(cmd"grep -q ${pat} ${file}") { accept [Done, Code(1)] }   // 1 = no match
```

Anything outside the declared set is an error. This is plumbum's `retcode=(0,1)`
and zt-exec's `.exitValues(0,1)`, promoted from an escape hatch to the *only* way
to widen success — because the alternative every library offers ("turn checking
off") is how a real error becomes invisible.

**Residue.** None significant. This one is genuinely closable.

## A14. SIGPIPE / EPIPE on writing to a dead child

**Mechanism.** Writing to a pipe whose read end is closed raises `SIGPIPE`
(default action: terminate) or, if blocked/ignored, fails with `EPIPE`. Feeding
stdin to `head -1` is *guaranteed* to hit this — that is `head` working
correctly.

**Who.** Node: `EPIPE` on `subprocess.stdin` with no built-in guard
([#40085](https://github.com/nodejs/node/issues/40085),
[#29206](https://github.com/nodejs/node/issues/29206)) — the fix is remembering
to attach an `'error'` listener *before* writing. Rust: the process aborts unless
`SIGPIPE` is handled (Rust's runtime sets `SIG_IGN`, so you get `EPIPE`, which
`?` then propagates as a hard error). **duct's gotcha #2 is the correct answer:**
"When writing to a child's stdin, Duct catches and ignores broken pipe errors
(`EPIPE`)."

**The concrete bug.** `feed_lines(big_list) |> cmd"head -1"` fails with "Broken
pipe" — a *correct* pipeline reported as an error.

**Unwritable by (T2).** **EPIPE on a child's stdin is not an error; it is EOF.**
The stdin feeder swallows `EPIPE`/`SIGPIPE` and records
`stdin_closed_early: true` in the `Output` — a *fact*, available if you care,
never a failure if you do not. `SIGPIPE` is set to `SIG_IGN` in the Avra runtime
and **restored to `SIG_DFL` in the child before `exec`** (a step many runtimes
forget, which is why some children behave oddly under Rust/Node parents — the
disposition is inherited across `exec`).

**Residue.** A program that genuinely needs to know its consumer vanished reads
the flag. That is the right place for it.

## A15. Timeouts without kill escalation

**Mechanism.** `SIGTERM` is catchable and is how a process gets to flush buffers,
remove temp files, and close connections. `SIGKILL` is not catchable and leaves
corruption. A timeout that sends only TERM can hang forever on a process that
ignores it; one that sends only KILL corrupts state on every timeout.

**Who.** **Python's `run(timeout=)` sends `kill()`** — no grace. `Popen` requires
the documented two-`communicate()` dance, and forgetting the second one leaks a
zombie. Node's `timeout`+`killSignal` defaults to TERM with **no escalation** —
a child ignoring TERM hangs the parent forever. Java `waitFor(timeout)` returns
`false` and does *nothing*; you must kill by hand. `asyncio` has no timeout at
all. **systemd gets it right and is the model**: `KillSignal=` (default TERM) →
wait `TimeoutStopSec=` → `FinalKillSignal=` (default KILL, gated by
`SendSIGKILL=`). process-compose matches it: `shutdown.signal`,
`shutdown.timeout_seconds` (default 10), then **SIGKILL to the whole process
group**.

**The concrete bug.** A test harness times out a database process with SIGKILL;
the next run finds a corrupt WAL and fails for an unrelated-looking reason.

**Unwritable by (T2).** **A timeout is a ladder, and there is no rung-less
form.** `timeout: 30s` *means*:

1. at 30s, `SIGTERM` to the **process group**;
2. wait `grace` (default 5s, manifest-configurable);
3. `SIGKILL` to the group;
4. `wait` for every member;
5. answer `Err(TimedOut { after, escalated_to: Killed(SIGKILL) })` — which says
   *how far up the ladder it went*, so "it shut down cleanly but slowly" and "we
   had to kill it" are different, inspectable outcomes.

Naming a signal (`stop_signal: SIGINT`) changes rung 1; `grace: 0s` collapses the
ladder deliberately. There is no way to express "TERM and then hope."

**Residue.** A process that blocks in uninterruptible D-state ignores SIGKILL
too. Nothing in userspace fixes that; the design's answer is that step 4's `wait`
is bounded by the same drain grace as A10 and reports the fact.

## A16. Killing a pid after it was reaped — pid reuse

**Mechanism.** Once a child is reaped, its pid is free for reuse. `kill(pid)`
afterwards signals **whatever process now holds that pid**. On Linux, pids wrap
at `/proc/sys/kernel/pid_max` (32768 by default) — a busy machine recycles in
minutes.

**Who.** duct's gotcha #4 ("there's a race condition between `kill` and
`waitpid`" that can kill an unrelated process). Go tracks it as
[golang/go#13987, "os: on unix Process.Kill() can kill the wrong process"](https://github.com/golang/go/issues/13987).
Node's docs note that signalling an exited pid "is not itself an error, but is
unsafe because PIDs get reused." Every language that hands you a `pid` integer
has it.

**The fix the OS provides.** `pidfd_open(2)` — a file descriptor referring to the
*process*, not the number. From the man page: even if the process terminates
before `pidfd_open` is called, "its PID will not have been recycled and the
returned file descriptor will refer to the resulting zombie process" (under
stated SIGCHLD conditions), and `clone(CLONE_PIDFD)` gives the guarantee
unconditionally. Then `pidfd_send_signal(2)` and `waitid(P_PIDFD, …)` are
race-free. Rust exposes `create_pidfd`. FreeBSD has `pdfork`/`pdkill`.

**The concrete bug.** A supervisor times out a worker, kills it, reaps it, and a
retry loop kills the "stale" pid again a second later — terminating an unrelated
production process that just inherited the number.

**Unwritable by (T1 + T2).**

1. **`Child` does not expose a raw pid as a signalling target.** `child.pid` is
   an `int` for *logging only*; there is no `kill(pid: int)` function. Killing is
   `child.stop()` — a method on a live handle.
2. The handle wraps a **pidfd** (Linux ≥ 5.3 via `CLONE_PIDFD`), a **pdfork**
   descriptor (FreeBSD), or a **process handle** (Windows — which never had this
   bug, because Windows handles are references, not numbers). macOS lacks a
   pidfd; there the handle serialises kill-and-reap through the owning scope so
   the window cannot open.
3. After reaping, the handle's state is `Reaped`; `stop()` on it is a **no-op
   returning the recorded verdict**, never a syscall.

**Residue.** macOS's serialised fallback is a lock, not a kernel guarantee; a
`kill` from a different process still races. Documented, bounded, and not the
common case.

## A17. The cwd race, and process-global `chdir`

**Mechanism.** `chdir(2)` is **process-global and not thread-safe**. The
traditional way to spawn a child in a directory is: `chdir(target)`, `fork`,
`exec`, `chdir(back)`. In a threaded program, every other thread's relative path
resolves against the wrong directory for that window — a data race with
filesystem consequences.

**Who.** Anything built on `fork`+`chdir`+`exec`, including older glibc
`posix_spawn` paths ([GLib #2063](https://gitlab.gnome.org/GNOME/glib/-/issues/2063)).
The fix is `posix_spawn_file_actions_addchdir_np(3)` — "all file actions are
processed in sequence in the context of the child at a point where the child
process is still single-threaded", which exists precisely because "changing the
working directory of the child would require temporarily changing the working
directory in the parent process … but this requires locking in a multi-threaded
process." It is [missing on many platforms](https://www.gnu.org/software/gnulib/manual/html_node/posix_005fspawn_005ffile_005factions_005faddchdir_005fnp.html),
including older glibc and some macOS versions.

Compounding it: A3's platform split on *which* cwd a relative program path
resolves against, and the fact that xshell and shelly both keep cwd **on the
shell object** rather than in the process, exactly to avoid this.

**The concrete bug.** A green-threaded build server runs four compilations in
four directories. One writes its output into another's tree. Reproduces once a
week.

**Unwritable by (T2).** **Avra never calls `chdir` to spawn a child.** The
child's directory is a `file_action`
(`posix_spawn_file_actions_addchdir_np`, or `fchdir` between `fork` and `exec`
where that is unavailable — legal there because the child is single-threaded).
And **there is no process-global "current directory" verb in `@std/process`** —
cwd is a field on the command, resolved per call, like xshell's `Shell`. A
"change directory" that affects other green threads simply does not exist in the
API.

**Residue.** `@std/fs` still resolves relative paths against the process cwd.
That is a separate design question, but the two must agree; the honest answer is
that `@std/fs` should also prefer `*at()` syscalls against a directory handle.

## A18. `argv[0]` semantics

**Mechanism.** `argv[0]` is *convention*, not identity. `execve` takes the path
and the argv vector separately; they need not agree. Programs use `argv[0]` to
decide what they are (busybox, `vim` vs `view`, `gzip` vs `gunzip`), and `ps`
shows it.

**Who.** Python's `executable` parameter: "*executable* replaces the program to
execute specified by *args*. However, the original *args* is still passed to the
program … On POSIX, the *args* name becomes the display name for the executable
in utilities such as **ps**." Rust: `arg0()` (Unix only). Zig: `expand_arg0`.
Most languages conflate the two silently.

**The concrete bug.** Two directions. Someone sets a login shell as `-bash` and
is surprised it reads `.bash_profile`. Or, security-relevant: a wrapper spawns a
helper with a *disguised* `argv[0]` so it does not appear in `ps` under its real
name — and an auditing tool that greps `ps` misses it.

**Unwritable by (T1).** The program and `argv[0]` are **two fields**, and the
default is that `argv[0]` is the program path. Setting them apart is
`arg0: "sh"` — explicit, greppable, and recorded in `Output.spawned` (P7). There
is no path by which they diverge by accident.

**Residue.** None. This is a small class; it is here because getting it wrong is
silent.

## A19. Windows quoting (mentioned, not solved here)

**Mechanism.** Win32 `CreateProcess` takes **one command-line string**, not an
argv vector. Every language must therefore *re-serialise* argv into a string,
and the target must parse it back. `CommandLineToArgvW` defines one set of rules;
`cmd.exe`, `.bat`/`.cmd` files, and MSVC's CRT startup define others.

**Who.** Everyone, badly. Rust's docs warn that `cmd.exe` and `.bat` files "use a
non-standard way of decoding arguments" and are "vulnerable to malicious input"
— the **BatBadBut / CVE-2024-24576** family, which hit Rust, Node, Python, PHP,
Erlang and Go simultaneously in April 2024. Java's `Runtime.exec(String)`
tokenizes with a quote-blind `StringTokenizer` (JDK-6550942, JDK-4506936,
JDK-7051946) and the JDK carries a "legacy vs strict mode" split governed by
`jdk.lang.Process.allowAmbiguousCommands`. PowerShell needed
`$PSNativeCommandArgumentPassing` in 7.3 with a `Windows` mode that *deliberately
falls back to the broken behaviour* for `cmd.exe`, `.bat`, `.cmd`, `.js`, `.vbs`,
`.wsf` because those consumers expect it. .NET's `ArgumentList` (Core 2.1) exists
to take the escaping away from the caller entirely.

**Position for Avra.** Out of scope for the first design, but the shape is fixed
now so it does not have to be retrofitted: argv is the *model*; Windows
serialisation is a backend concern; `.bat`/`.cmd` targets are **refused by
default** with a named diagnostic (they cannot be safely quoted, full stop) and
permitted only via an explicit `windows_raw_command_line(s)` escape hatch that is
obviously dangerous at the site. That is .NET's `ArgumentList`-vs-`Arguments`
split, decided in the right direction from day one.

## A20. Text vs bytes, encoding errors, partial lines

**Mechanism.** A process emits **bytes**. "Text" is an interpretation requiring an
encoding, and it can fail. Line-oriented reading additionally requires a
*maximum line length* or an unbounded buffer.

**Who.** Python: `text=`/`encoding=`/`universal_newlines=` (three spellings of
overlapping concepts), with newline translation applied on the way in and out.
Node: `encoding: 'utf8'` by default for `exec`, so binary output is silently
mangled unless you ask for `'buffer'`. **Node's `maxBuffer` truncation can land
mid multi-byte UTF-8 sequence** — a documented anchor in its own docs. Go, Rust,
Java: bytes, correctly. **Deno gets it best**: `Uint8Array`, always, decode
explicitly. **asyncio has the sharpest partial-line bug**: `StreamReader`'s
default `limit` is 65536, and a longer line raises `LimitOverrunError` /
`ValueError: Separator is not found, and chunk exceed the limit` — line-oriented
streaming with an invisible maximum line length, failing mid-log-tail.

Related and underrated: **`$(cmd)` strips all trailing newlines** in bash — it
cannot distinguish none from one from several, which quietly breaks byte-exact
capture. Bash 5.3 added `${| cmd; }` to get the unstripped form.

**The concrete bug.** A tool captures `git show :file` to check a hash. The file
is a PNG. UTF-8 decoding with replacement characters mangles it, the hash
mismatches, and the error says "corrupt object".

**Unwritable by (T1).** **`Output.out` is `Bytes`.** Text is a *fallible
projection*: `out.text()` returns `Result<string, EncodingError>` naming the byte
offset. `out.lines()` yields a channel of `Line { stream, text }` with an
explicit `max_line` (error, never silent truncation, on overflow). **No implicit
trimming anywhere** — `.trimmed()` is a separate, named verb, so byte-exact
capture is the default and the convenience is opt-in. No newline translation,
ever.

**Residue.** `text()?` on every capture is more ceremony than `.stdout`. The
mitigation is that `run(…).text()?` is one chained call, and that `cmd_text"…"`
can exist as a sugar for the overwhelmingly common "I know this is UTF-8" case —
still returning `Result`.

## A21. The interleaving of stdout and stderr is lost

**Mechanism.** Two pipes are two independent buffers with independent flush
timing. If you capture them separately you get correct separation and **no
ordering**. If you merge them at the OS level (`dup2(1, 2)`,
`redirectErrorStream(true)`, `2>&1`, `CombinedOutput()`) you get ordering and
**can never separate them again**. Everyone treats this as a fundamental
trade-off.

**Who.** Java: `redirectErrorStream(true)`. Go: `CombinedOutput()`. Bash: `2>&1`.
Nushell: `o+e>` (and it currently *rejects* redirecting the two to different
files at once — [#7364](https://github.com/nushell/nushell/issues/7364)). PTY
libraries merge them by construction. **Nobody in the survey offers both.**

**The concrete bug.** A build fails. The log shows all 400 stdout lines then all
12 stderr lines, so you cannot tell **which file** was being compiled when the
error was printed. Every developer has done this by hand with `2>&1` and lost the
ability to filter stderr separately.

**Unwritable by (T2) — and this is a genuine P6 collapse.** The trade-off is
false. It exists only because the parent reads the pipes lazily. **Avra's runtime
is already draining both concurrently on green threads (A6),** so it can record
*sequence* at the moment each chunk arrives — for free, in the drain it must
perform anyway. `Output` therefore carries **all three views of one capture**:

```avra
out.out    // Bytes  — stdout alone
out.err    // Bytes  — stderr alone
out.log    // List<Chunk>  — { stream: Stream, bytes: Bytes }, in arrival order
```

Separate *and* interleaved, from one run, with no `2>&1` and no loss. **No
language in this survey offers this**, and it costs nothing beyond a sequence
number per chunk.

**Residue.** "Arrival order at the parent" is not "emission order in the child" —
the child's own buffering (stdout line-buffered to a tty, block-buffered to a
pipe; stderr unbuffered) reorders things before we ever see them. The docs must
say *arrival order*, precisely, and not overclaim. A PTY (A23) is the only way to
get true emission order, and it costs separation.

## A22. `system()` locale and inherited shell state

**Mechanism.** A shell inherits the whole environment, and several variables
change how *text* behaves: `LC_NUMERIC` (decimal comma vs point — so `printf
"%.2f"` emits `3,14` in a German locale and your parser sees an integer),
`LC_COLLATE` (changes `sort` order, so `[a-z]` in a glob or a range matches
differently), `LC_TIME` (date formats), `LC_MESSAGES` (**tool error messages come
back translated**, so a script grepping stderr for "No such file" finds nothing),
`LANG`, `TZ`, and `IFS` (which subverts word splitting inside the invoked shell
even for an otherwise-safe command string). See
[dwheeler](https://dwheeler.com/secure-programs/Secure-Programs-HOWTO/environment-variables.html)
and [Perl #13459](https://github.com/Perl/perl5/issues/13459) for the decimal
case.

**Who.** Everything that shells out and parses stdout — i.e. most build tooling
in existence. The mitigation everyone eventually learns is `LC_ALL=C`.

**The concrete bug.** CI passes in the US and fails in Germany, in a test that
parses `du -h` output. Or: a script greps `git status` for "nothing to commit"
and silently always thinks there are changes, on a French developer's machine.

**Unwritable by (T2).** A4's closed environment does most of the work; this class
adds the *pin*. The default child environment sets **`LC_ALL=C`** (and `TZ=UTC`
for reproducibility) unless the call site says otherwise. A program that wants
the user's locale asks for it — `env { pass ["LC_ALL", "LANG"] }` — which is
exactly the set of programs whose *output is for a human*, and never the set
whose output is being parsed.

**Residue.** A tool that renders a UI for the user through Avra now needs one
line to get their locale back. That is the correct direction for the default to
be wrong in.

## A23. TTY detection — capture changes the program's behaviour

**Mechanism.** Programs call `isatty(1)`. When the answer changes, so does the
output: colour codes appear or vanish, progress bars become line spam or silence,
buffering flips from line to block (so output *arrives* in different chunks), and
`git`/`less` decide whether to page. **Capturing a program's output changes what
the program does.**

**Who.** Everyone with pipes; and the inverse offenders are worse. **Python's
`sh` library defaults `_tty_out=True`** — it allocates a pty *by default*, so
every program behaves as if interactive, colour codes land in your captured
strings, and stdout and stderr are merged by the pty. **pty4j** (JetBrains) is
the only library in the survey that treats "the child wants a terminal" as an
explicit, first-class capability. Overmind runs every process in a real tmux pane
for exactly this reason. Bun's `spawn` has a `terminal` option.

**The concrete bug.** A CI script captures `cargo build` output and greps for a
warning. Locally it works (colour off when piped). Then someone sets
`CARGO_TERM_COLOR=always` in the environment and the grep fails against
`\x1b[33mwarning\x1b[0m`. Or the reverse: a progress bar written for a tty emits
50 MB of `\r`-separated output into a log when piped.

**Unwritable by (T2 + T1).**

1. **The default child environment pins the answer.** With A4's closed
   environment, `TERM` is absent and `NO_COLOR=1` is set by default, so
   colour-emitting programs behave *deterministically under capture*. The bug
   above cannot be introduced by an ambient variable, because there are no
   ambient variables.
2. **A tty is an explicit capability, not an accident**: `tty: true` allocates a
   pty (pty4j's model). And **T1**: the type says what you get — a pty run's
   `Output` has **no `err` field**, because a pty *cannot* separate the streams.
   Asking for `out.err` on a pty capture is a compile error explaining why,
   rather than a silently empty buffer (which is what every pty wrapper hands you
   today).

**Residue.** A program that ignores `NO_COLOR` and checks `isatty` still behaves
differently under capture than in a terminal. That is unavoidable without a pty;
the design's contribution is making the *default* deterministic and the pty
*explicit*.

## A24. Cancellation not propagating into children

**Mechanism.** The parent's control flow unwinds — an exception, a `return`, a
cancelled task, a timeout at a higher level — and the child, which is an OS
object rather than a language object, is unaffected.

**Who.** Everyone whose cleanup is a destructor or a `finally` the caller writes.
Tokio: "a spawned process will, by default, continue to execute even after the
`Child` handle has been dropped", and `kill_on_drop` is best-effort because you
cannot block in `Drop`. Java's `onExit()` documents that "the process may be
observed to have terminated with `isAlive()` before the CompletableFuture is
completed". .NET's `Kill(entireProcessTree: true)`: "`WaitForExit` and
`HasExited` do not reflect the status of descendant processes … even if all
descendants have not yet exited". Erlang ports **send no signal at all** on close.
**swift-subprocess is the state of the art**: the closure form binds the child's
lifetime to the enclosing task, and task cancellation triggers a "teardown
sequence". Racket's custodians are the same idea, ambient and tree-shaped.

**The concrete bug.** An HTTP handler shells out to `ffmpeg`; the client
disconnects; the request task is cancelled; ffmpeg keeps transcoding for six
minutes at 100% CPU. Repeat under load until the box falls over.

**Unwritable by (T2).** **A child is owned by the green thread that spawned it,
and cancellation is a first-class, propagating event** — Erlang's port-owner
model with the missing half (an actual signal) supplied. When the owning thread
is cancelled or unwinds:

1. the scope's teardown ladder runs (A15: TERM → grace → KILL, on the group);
2. it `wait`s, bounded by the drain grace (A10);
3. the child's outcome is attached to the cancellation, so a supervisor can see
   *what was killed* rather than inferring it.

Because Avra's green threads make blocking cheap, the teardown can *actually
wait* — which is the resource that destructor-based designs do not have and is
the whole reason they are best-effort.

**Residue.** A `detach()`ed child is deliberately outside this, and a `SIGKILL`ed
parent runs no teardown (A9's layers 3–4 are the backstop).

---

## The taxonomy, condensed

| # | Class | Best prior art | Avra tier |
|---|---|---|---|
| A1 | Shell injection | xshell / cmd_lib (compile-time parse) | **T1** |
| A2 | Argument injection | Bun (documents it) | T3 + lint |
| A3 | PATH / cwd hijack | Go `ErrDot`, Nix (`PATH=/path-not-set`) | **T1**/T2 |
| A4 | Env leak + injection | Nix (closed env) | T2 + **T1** deny-list |
| A5 | fd leak (CLOEXEC) | Python ≥3.2, runc's scars | T2 |
| A6 | Full-pipe deadlock | typed-process, Zig, duct | T2 + **T1** |
| A7 | Unbounded / truncated capture | **Zig `max_output_bytes`** | T2 |
| A8 | Zombies | Haskell `withProcessTerm`, Racket custodians | T2 |
| A9 | Orphans on parent death | systemd cgroups, muontrap | T2 (caveated) |
| A10 | Grandchild holds the pipe | **Go `WaitDelay`** | T2 |
| A11 | Status as a count (256→0) | — (nobody) | **T1** |
| A12 | Signals vs codes | **Zig `Term`** | **T1** |
| A13 | Success-but-stderr | Oils `boolstatus`, plumbum `retcode=` | **T1** |
| A14 | EPIPE to a dead child | **duct** (swallows it) | T2 |
| A15 | Timeout without escalation | **systemd** ladder | T2 |
| A16 | Kill after reap (pid reuse) | `pidfd`, Windows handles | **T1**/T2 |
| A17 | cwd race | `posix_spawn_file_actions_addchdir_np`, xshell | T2 |
| A18 | `argv[0]` | Rust `arg0`, Zig `expand_arg0` | **T1** |
| A19 | Windows quoting | .NET `ArgumentList` | (scoped out, shape fixed) |
| A20 | Bytes vs text | **Deno** (`Uint8Array`) | **T1** |
| A21 | Interleaving lost | — (nobody has both) | T2 — *new* |
| A22 | Locale / inherited shell state | `LC_ALL=C` folklore | T2 |
| A23 | TTY detection | pty4j (explicit pty) | T2 + **T1** |
| A24 | Cancellation propagation | **swift-subprocess**, Racket custodians | T2 |

Two rows have no prior art at all: **A11** (no language types its own exit as a
verdict) and **A21** (no language gives you separated *and* ordered output). Both
are cheap. A21 in particular is free, because the concurrent drain that closes A6
is already producing the ordering information every other library throws away.

---
# §B THE BEAUTIFUL SURFACE

Twelve sketches of the tasks people actually do. Syntax is plausible-Avra, not
final. Each says what gets it best today and where ours is better — and where it
is only *equal*, which is said plainly.

The shared vocabulary, so the sketches read:

```avra
// A command literal. Parsed by the compiler into argv. No shell exists.
cmd"git commit -m ${message}"

// The verdict. There is no `.code: int` anywhere.
enum Exit {
  Done
  Code(code: int)
  Killed(signal: Signal)
  Stopped(signal: Signal)
  NotFound(program: string)
  NotExecutable(path: string, why: string)
}

// The result of a completed run.
type Output = {
  exit:    Exit,
  out:     Bytes,          // stdout alone
  err:     Bytes,          // stderr alone
  log:     List<Chunk>,    // both, in arrival order
  spawned: Spawned,        // resolved path, argv, env, cwd — P7
}
```

---

## B1. Run and capture

```avra
let version = run(cmd"git --version")?.out.text()?.trimmed()
```

And the failure path, which is the point:

```avra
let out = run(cmd"cargo build --release") catch (e) {
  fail("build failed: ${e.exit} — ${e.err.text() ?? "<binary>"}")
}
```

**Best today:** Python's `subprocess.run(..., check=True, capture_output=True,
text=True)` — one call, one record. os-lib's `os.proc(...).call()` is equal and
shorter.

**Better here:** non-zero is `Err` with **no flag to turn checking off** (only
`accept [...]` to widen the verdict set — B11); `.out` is `Bytes` so a PNG
survives (A20); `.text()` is fallible and names the bad offset; there is no
`text=True` / `encoding=` / `universal_newlines=` triple; and capture is bounded,
so a chatty child is `Err(OutputTooLarge)` rather than an OOM (A7). The `?`
already reads like Python's `check=True` without being a keyword you can forget.

## B2. Run and stream lines as they arrive

```avra
for line in stream(cmd"cargo build") {
  when {
    line.stream == .Err && line.text.starts_with("error") -> report(line.text)
    _                                                     -> log(line.text)
  }
}
```

Or through the pipe, with `it`:

```avra
stream(cmd"kubectl logs -f ${pod}")
  |> filter(it.text.contains("ERROR"))
  |> map(alert_of(it))
  |> each(send(it))
```

**Best today:** `sh`'s `_iter`, zx's `Symbol.asyncIterator`, Bun's `.lines()`,
Deno's `ReadableStream`.

**Better here:** the stream is a **typed channel**, so everything Avra's channel
vocabulary already does (`filter`, `batch`, `debounce`, `merge`, `select`) works
on process output with no adapter — that is P17, composability over
featurefulness, cashed in. Each `Line` carries **which stream it came from**, so
you never need `2>&1` to see stderr in order and never lose the ability to filter
it. And `max_line` is explicit, so asyncio's `LimitOverrunError` mid-log-tail
(A20) has no equivalent.

## B3. Pipe A into B into C, with pipefail semantics

```avra
let uniq = run(cmd"git log --format=%an" |> cmd"sort" |> cmd"uniq -c")?
```

`Err` if **any** stage failed. And every stage's verdict is retained, always:

```avra
let r = run(pipeline) catch (e) {
  let failed = e.stages.enumerate().find(it.1 != Exit.Done)!
  fail("stage ${failed.0} (${pipeline.stage(failed.0)}) → ${failed.1}")
}
```

**Best today:** duct (`pipefail` by default, either side's failure reported).
bash needs `set -o pipefail` *and* `PIPESTATUS`, and PIPESTATUS is clobbered by
the very next command.

**Better here:** `PIPESTATUS` is not a global that evaporates — it is
`stages: List<Exit>` **on the result value**, so it cannot be clobbered, cannot
be read after the wrong command, and is a typed verdict per stage rather than an
int (A12). Java's `startPipeline` is the closest structural relative and it gives
you no per-stage status at all. SIGPIPE in a non-final stage
(`yes |> head -1`) is **not a failure** — Oils needed a `sigpipe_status_ok`
option for exactly this; here it is the default because `Killed(SIGPIPE)` on a
non-final stage whose successor exited `Done` is a *correct* pipeline, and the
type system can see that.

## B4. Run with a timeout and kill escalation

```avra
let out = run(cmd"./integration-tests") {
  timeout     10m        // TERM the group
  grace       30s        // then, if still alive, KILL the group
  stop_signal .Int       // optional: SIGINT instead of SIGTERM
}?
```

The ladder is *in the error*:

```avra
run(job) catch (e) {
  match e {
    .TimedOut(after, .Killed(_)) -> warn("hung past ${after}; had to SIGKILL")
    .TimedOut(after, _)          -> info("stopped cleanly after ${after}")
    _                            -> fail(e)
  }
}
```

**Best today:** systemd (`KillSignal=` → `TimeoutStopSec=` → `FinalKillSignal=`)
and process-compose. In *languages*: zt-exec's `.timeout()`, and nothing else
escalates — Python `run(timeout=)` sends a bare `kill()`, Node sends TERM and
waits forever, Java's `waitFor(timeout)` does nothing at all.

**Better here:** systemd's ladder brought into a language, as **the only shape a
timeout has** — there is no way to spell "TERM and hope". The signal goes to the
**process group**, so grandchildren die too (A9/A10). And the error says *how far
up the ladder it went*, which is the difference between "slow but clean" and
"we corrupted its state" — a distinction no language API in the survey reports.

## B5. Run N in parallel with bounded concurrency

```avra
let results = repos
  |> map(cmd"git -C ${it} fetch --all")
  |> run_all(limit: 8)?
```

Fail-fast, with cancellation reaching the children:

```avra
let built = targets |> map(build_cmd(it)) |> run_all(limit: cpus(), stop_on_error: true)?
```

**Best today:** honestly, nothing in a standard library. It is `xargs -P`, GNU
parallel, `asyncio.Semaphore` + `gather`, or a hand-rolled worker pool.

**Better here:** green threads make the bounded pool a library function rather
than a framework, and `stop_on_error` **propagates cancellation into every
running child** (A24) — TERM, grace, KILL, on each group — instead of leaving
seven `git fetch`es running after the eighth failed, which is what `asyncio.gather`
and `Promise.all` do today.

## B6. A long-lived child with a ready-signal and graceful shutdown

```avra
spawn(cmd"redis-server --port ${port}") { redis ->
  redis.ready { line "Ready to accept connections" }?
  run_the_suite(port)?
}   // TERM → grace → KILL on the group, then wait — on every exit path
```

Readiness is a **spectrum**, chosen by whoever is waiting (process-compose's five
conditions):

```avra
redis.ready { line   "Ready to accept" }?          // a log line appeared
api.ready   { http   "http://localhost:${p}/healthz", every 200ms }?
worker.ready{ exec   cmd"pg_isready -p ${p}" }?    // zero exit = ready
migrate.ready{ done_ok }?                          // ran to completion, exit 0
sidecar.ready{ started }?                          // merely forked (the weak one)
```

And a declarative supervised process, as a component:

```avra
managed api {
  command   cmd"./target/release/api --port ${port}"
  ready     { http "http://localhost:${port}/healthz" }
  restart   .OnFailure          // systemd's taxonomy, not a bool
  backoff   { initial 200ms, max 30s, jitter true }
  limit     { burst 5, within 10s }     // then FAILED, not an infinite loop
  stop      { signal .Term, grace 15s }
  on crashed(exit) { alert("api died: ${exit}") }
}
```

**Best today:** systemd for the semantics, process-compose for the config shape,
swift-subprocess and Haskell's `withProcessTerm` for the scope.

**Better here:** all four in one artifact, in the language, type-checked. The
`restart` field is systemd's **four-way** taxonomy (`.Never`, `.Always`,
`.OnFailure`, `.OnAbnormal`), not `on_failure|always`, so "exited non-zero" and
"was killed by a signal" are separately opt-in. `limit` is systemd's circuit
breaker as a **default**, so a crash-loop becomes an observable failure instead
of infinite resource burn — the thing every hand-rolled supervisor forgets. And,
learning from
[process-compose#403](https://github.com/F1bonacc1/process-compose/issues/403):
**probe failure and process exit feed the same restart state machine**, stated in
the docs, because "obviously the same" is where that bug came from.

## B7. Feeding stdin — from a string, a list, or a channel

```avra
let sorted = run(cmd"sort -u") { stdin text(names.join("\n")) }?.out.text()?

let hashed = run(cmd"sha256sum") { stdin bytes(blob) }?

// From a channel — backpressured, unbounded, never buffered
let counted = run(cmd"wc -l") { stdin lines(events) }?

// From a file, without reading it into memory
let checked = run(cmd"gpg --verify sig.asc -") { stdin file(payload_path) }?
```

**Best today:** Bun's polymorphic `stdin` (a `Blob`, `Response`, `TypedArray`,
`Bun.file()`, `ReadableStream`, or fd) is the richest. Haskell's
`byteStringInput` is the most principled.

**Better here:** `lines(channel)` makes a *green-thread producer* the input to a
process with no glue — the compiler's own build could pipe its diagnostics
channel straight into a formatter. And EPIPE is **not an error** (A14): `head -1`
closing early sets `out.stdin_closed_early` and the run succeeds, which is duct's
gotcha #2 as a default rather than a library that had to discover it.

## B8. Environment narrowed to an allow-list

The manifest is the default, and it is the *contract* (P9, P13):

```toml
[process.env]
pass = ["PATH", "HOME", "LANG"]
set  = { LC_ALL = "C", TZ = "UTC", NO_COLOR = "1" }
```

The call site narrows further, or widens deliberately:

```avra
let out = run(cmd"terraform apply -auto-approve") {
  env {
    pass ["PATH", "HOME"]                    // and nothing else
    set  { TF_IN_AUTOMATION "1" }
    give { AWS_ROLE_ARN role_arn }           // a secret, to exactly one child
  }
}?

let legacy = run(cmd"./ancient-build.sh") { env inherit_all() }?   // greppable
```

And the deny-list has teeth (T1):

```avra
run(cmd"x") { env { set { LD_PRELOAD "/tmp/evil.so" } } }
//                   ^^^^^^^^^^ F1xxx: `LD_PRELOAD` changes how a program loads code
//                              and cannot be set from a literal.
//                              help: `env.unsafe_set("LD_PRELOAD", …)`, permitted in
//                              avra.toml under [process.env] allow-unsafe
```

**Best today:** Nix. Its builders get `PATH=/path-not-set` and
`HOME=/homeless-shelter` and nothing else, and that is *why* Nix builds
reproduce. No general-purpose language does this; Go's `Env == nil` inherits
everything, and os-lib *merges into* the ambient environment.

**Better here:** Nix's discipline available to ordinary programs, with the
allow-list in the manifest so it is reviewed once per package rather than argued
at every call site. `give` (a secret to exactly one child) makes the blast radius
of a leaked token visible in the source. `Output.spawned.env` records what the
child actually got (P7). And `LC_ALL=C` + `TZ=UTC` + `NO_COLOR=1` as defaults
close A22 and A23 in the same stroke.

## B9. Working directory

```avra
let status = run(cmd"git status --porcelain") { cwd repo_path }?
```

**Best today:** xshell's `sh.push_dir()` (RAII, shell-local) and shelly's
per-`Sh` cwd — both deliberately avoid the process-global `chdir`.

**Better here:** there is **no process-global cwd verb in the library at all**,
so the threaded-`chdir` race (A17) has no expression. The directory is applied as
a spawn file action in the child, and a *relative program path* is a different
constructor (`local("./build.sh")`) with one documented meaning on every platform
— closing duct's gotcha #6, which is a real cross-platform behaviour difference
that every other library either documents or ignores.

## B10. stdout and stderr — separately AND interleaved, from one run

```avra
let out = run(cmd"cargo test")?

out.out.text()?                                   // stdout alone
out.err.text()?                                   // stderr alone
out.log |> each(println("${it.stream}: ${it.text()?}"))   // both, in order
```

Debugging a failure with full fidelity:

```avra
let r = run(cmd"make -j8") catch (e) {
  e.log
    |> drop_while(it.stream == .Out)     // everything from the first stderr byte
    |> take(40)
    |> each(println(it.text()?))
  fail(e)
}
```

**Best today:** you have to choose. Java `redirectErrorStream(true)`, Go
`CombinedOutput()`, bash `2>&1` — order, no separation. Everyone else —
separation, no order. Nushell currently cannot even send the two to different
files in one call.

**Better here:** **all three views of one capture.** This is the P6 collapse: the
"trade-off" is an artifact of lazy pipe reading, and Avra's runtime is already
draining both concurrently on green threads to close the deadlock (A6). Recording
arrival order costs a sequence number per chunk. **No language in the survey has
this.** (Honest caveat, in the docs and not just here: it is *arrival* order, not
the child's emission order — the child's own buffering reorders things before we
see them. A pty gives true emission order and costs separation, which is B12's
`tty: true`.)

## B11. Exit status as a typed verdict

```avra
match run(cmd"grep -q ${pat} ${file}") {
  .Ok(_)                        -> found()
  .Err(e) -> match e.exit {
    .Code(1)                    -> not_found()
    .Code(2)                    -> fail("grep: ${e.err.text()?}")
    .NotFound(p)                -> fail("`${p}` is not installed")
    .Killed(s)                  -> fail("grep died of ${s}")
    .NotExecutable(p, why)      -> fail("${p}: ${why}")
    _                           -> fail(e)
  }
}
```

Or, when the contract is known, declare it — and never turn checking off:

```avra
let matched = run(cmd"grep -q ${pat} ${file}") { accept [.Done, .Code(1)] }?
              .exit == .Done
```

**Best today:** Zig's `Term` tagged union is the only real verdict type in the
survey. plumbum's `retcode=(0,1)` and zt-exec's `.exitValues(0,1)` are the only
declared-acceptable-set APIs. Oils' `boolstatus` is the only thing that *refuses*
an out-of-contract code.

**Better here:** all three at once. `NotFound` and `NotExecutable` are lifted out
of the numeric space entirely (no 127/126 folklore); `Signal` is an enum, not an
int (no `128+n`, no `-N`, no dependence on whether a shell was involved — A12);
there is **no `.code: int` field to compare against zero**; and `accept` widens
success without ever *disabling* the check, so the "just use `check=False`"
reflex that hides real errors has nothing to reach for.

## B12. The escape hatches, spelled at the site

A real shell, when you genuinely need one — a distinct type, a distinct verb,
and a manifest opt-in (`[process] shell = true`):

```avra
let out = run_shell(sh"""
  set -euo pipefail
  find . -name '*.log' -mtime +30 -print0 | xargs -0 gzip -9
""")?
```

A pty, when the child insists on a terminal — and note the type change:

```avra
let session = run(cmd"ssh ${host} 'sudo -S apt upgrade'") { tty true }?
session.out       // ok — the merged terminal stream
session.err       // COMPILE ERROR: a pty capture has no separate stderr
```

And the one genuinely new idea: **a process as a cacheable pure function**
(Bazel/Nix, in a language):

```avra
let artifact = run_pure(cmd"protoc --go_out=. ${proto}") {
  inputs  [proto, "buf.yaml"]        // content-hashed
  outputs ["gen/api.pb.go"]
  tools   [pin("protoc", "27.1")]    // the toolchain is an input, not ambient
}?
```

The key is `hash(argv, env, input contents, tool identity, platform)`. A second
call with the same key does not run the process at all; it materialises the
outputs. Network is denied — unless you commit to the answer, which is **Nix's
fixed-output derivation as the P8 escape hatch that keeps the guarantee**:

```avra
let src = run_pure(cmd"curl -sSL ${url}") {
  outputs   ["dist.tar.gz"]
  result_hash "sha256:1a2b…"        // network permitted, output verified
}?
```

**Best today:** Bazel and Nix — but only as *build systems*, never as a library
call. No general-purpose language lets an ordinary program declare "this
subprocess is a pure function of these inputs" and get memoisation for it.

**Better here:** P10 and P13, literally. The compiler already knows the argv
(A1's compile-time parse) and the manifest already declares the environment (B8),
so **the two hardest parts of a cache key are already computed**. The escape
hatch keeps the guarantee rather than voiding it, which is the paradox collapse
Nix found and nobody else copied.

---

# §C THE ONE-PAGE VERDICT

Five laws. Each with the strongest honest counter-argument, and the answer.

---

### Law 1 — **argv is a list; a shell string is a distinct type, spelled at the site.**

There is no function taking a command string. `cmd"…"` is a compile-time-parsed
argv template; an interpolation is a hole in the *vector*, not in a string, so it
can never be re-scanned. A real shell is `sh"""…"""` — a different type
(`ShellScript`), a different verb (`run_shell`), and a manifest opt-in. Splitting
and globbing are named functions (`split(s)`, `glob(p)`), never implicit stages.

*Prior art:* xshell + cmd_lib (parse before substitute), .NET's `ArgumentList` as
a mutually exclusive API, Racket's `*` convention, Oils' `simple_word_eval`.

**Counter-argument (the strongest one):** *this is a lie of omission.* The
attacker's path is not `run(user_string)` — nobody writes that any more. It is
`run(cmd"bash -c ${script}")`, `run(cmd"ssh ${host} ${remote_cmd}")`,
`run(cmd"docker exec ${c} sh -c ${x}")` and `run(cmd"make ${target}")`, all of
which type-check perfectly and all of which are injection. Worse, Bun's
documented argument-injection gap (A2) means even a *correctly quoted* value can
smuggle an option. So the law buys a *category* of safety while the real
vulnerabilities in modern codebases live one layer out, and a designer who
believes the law has closed the class will stop looking.

**Answer, honestly:** conceded — the law is necessary, not sufficient, and the
docs must say so in those words. Two things make it worth having anyway. First,
the residue is *visible*: `bash`, `ssh`, `sh -c` are literals in the source, so a
grep and a lint both find them, whereas string concatenation is invisible in the
general case. Second, Avra can do what no other language can here (P10): the
compiler holds the parsed argv, so it *knows* which interpolation lands in which
slot, and can warn on a positional slot fed by an unproven value, offering `--` or
`positional(…)` as the fix. That is a real, mechanical improvement over "read the
docs carefully", and it is only available because the parse happens at compile
time.

---

### Law 2 — **A verdict is a value, never an integer.**

`Exit` is a tagged union: `Done`, `Code(int)`, `Killed(Signal)`,
`Stopped(Signal)`, `NotFound(program)`, `NotExecutable(path, why)`. There is no
`.code: int` on `Output`. Non-zero is `Err` by default; success is widened with
`accept [...]`, never by disabling the check. Stderr is data and never a verdict.
Symmetrically, `exit()` takes a `Verdict`, not an int, so a count can never wrap
to success.

*Prior art:* Zig's `Term`, Oils' `boolstatus`, plumbum's `retcode=`, duct's
errors-by-default. *Nobody* does the `exit()` side.

**Counter-argument:** exit codes are a **wire protocol between programs**, not an
internal representation, and pretending otherwise is a leaky abstraction that
costs real work. `rsync` has twenty-odd documented codes; `curl` has ninety;
`diff` uses 0/1/2 meaningfully; `git bisect run` requires 0/1/125/126/127. Code
that speaks these protocols wants arithmetic and ranges, and forcing it through a
union means unwrapping `Code(n)` to get `n` anyway — pure ceremony, plus a
`_ ->` arm for variants that will never occur for that program. Meanwhile the
128+N and 126/127 conventions are *real*, in every shell script the program has
to interoperate with, and hiding them means Avra's view disagrees with what the
user sees in their terminal.

**Answer:** the union does not hide `n` — `Code(n)` binds it, and a program that
speaks curl's ninety codes matches on `Code(n)` and does its arithmetic in one
arm. What the union removes is the ability to conflate *categories*: `Code(139)`
and `Killed(SIGSEGV)` are different values, so a range check written for exit
codes cannot silently catch a crash, and a count that overflows cannot read as
success. The disagreement with the shell's view is real and is the *point* — the
shell's view is lossy (A12), and the correct response to "the user sees 139" is
that `Killed(SIGSEGV)` renders as "killed by SIGSEGV (shell would report 139)",
which is strictly more information. The honest cost is one extra match arm in
protocol-speaking code; the honest benefit is that the linter-counts-to-256 bug
and the SIGPIPE-141 bug are both unwritable.

---

### Law 3 — **A child has a scope; the scope owns its death.**

Every child is created inside `spawn(…) { child -> … }` or completes inside
`run(…)`. Leaving by any path — normal, `?`, `fail`, cancellation, panic — runs
the teardown ladder: `SIGTERM` to the **process group**, wait `grace`, `SIGKILL`
to the group, `wait` every member, bounded by a drain grace. There is no
droppable handle, no destructor-based cleanup, no `wait()` you can forget.
Signalling targets a **pidfd/handle**, never a pid integer. Detaching is a
distinct verb with a distinct return type.

*Prior art:* Haskell `withProcessWait`/`withProcessTerm`, Racket custodians,
swift-subprocess's task-scoped teardown, systemd's `KillMode=control-group` and
kill ladder, Erlang's port-owner (with the missing signal supplied), `pidfd_open`.

**Counter-argument:** *scopes do not match how servers are written.* A connection
pool, a plugin host, a language server, a dev-tool supervisor — all of these hold
children whose lifetime is a *field on a struct*, not a lexical block. Forcing
every child into a block either produces a callback pyramid or pushes everyone to
`detach()`, at which point the guarantee is gone and the API is worse than one
that made the unscoped case first-class and safe. Structured concurrency has been
tried and people route around it. And group-killing is itself dangerous: kill the
group and you may kill a shared daemon a child legitimately handed work to.

**Answer:** the lexical block is the *default*, not the only form. A struct-held
child is a child owned by a **supervisor value** whose own lifetime is scoped —
Racket's custodian exactly, ambient and tree-shaped, so a pool owns twenty
children and the pool's scope owns the pool. That is one indirection, not a
pyramid. On group-kill: the danger is real, and the answer is that the group is
*ours* — every child gets a **fresh** process group at spawn (`setpgid`), so the
group contains our child and its descendants and nothing else. A child that hands
work to a pre-existing shared daemon is talking to a process in a *different*
group, untouched. The residual honesty is A9's: a `SIGKILL`ed parent runs no
teardown, so `PR_SET_PDEATHSIG`/`kqueue`/cgroups are backstops and the guarantee
is T2-with-caveats, not absolute — and the docs must say "best effort under
SIGKILL" rather than implying otherwise.

---

### Law 4 — **The environment is closed, and `PATH` resolution never consults the current directory.**

A child receives what `avra.toml` and the call site declare: a `pass` allow-list,
a `set` map, defaults of `LC_ALL=C`, `TZ=UTC`, `NO_COLOR=1`. Inheriting
everything is `inherit_all()` — one greppable call. The executable names —
`LD_PRELOAD`, `LD_AUDIT`, `DYLD_*`, `BASH_ENV`, `ENV`, `IFS` — are **compile
errors** from a literal. PATH search never consults the cwd, an empty PATH
element is a hard error, and a relative program path is a different constructor
with one meaning on every platform.

*Prior art:* Nix's stripped builder environment, Go's `ErrDot`, Python 3.12's
Windows cwd fix, SEI CERT ENV03-C, the `LC_ALL=C` folklore made policy.

**Counter-argument:** *this breaks everything, and users will disable it on day
one.* `git` needs `HOME` for config and `SSH_AUTH_SOCK` for agents. `cargo` needs
`CARGO_HOME`, `RUSTUP_HOME`, and increasingly `RUSTC_WRAPPER`. `docker` needs
`DOCKER_HOST`. Kerberos needs `KRB5CCNAME`. Proxies need `HTTP_PROXY`/`NO_PROXY`.
Every one of these fails with a *bad* error message — "permission denied",
"cannot connect", "not a git repository" — that does not mention environment
variables at all. The predictable outcome is that the first tutorial says
`env inherit_all()`, everyone copies it, and the law's only lasting effect is one
extra line of noise. Nix gets away with it because Nix owns the whole world
inside its sandbox; a general-purpose language does not.

**Answer:** this is the law most likely to fail in practice, and the design must
be built around that risk rather than around the ideal. Three concessions.
(1) **Named profiles**, so the common case is one honest word, not an audit:
`env posix` (PATH/HOME/LANG/TERM), `env developer` (adds the `*_HOME`, proxy and
agent variables), `env inherit_all()`. (2) **The diagnostic is the product.**
When a child fails and the closed environment is plausibly why, the error must
name it: *"`git` exited 128; `HOME` was not passed — add `pass ["HOME"]` or use
`env developer`"*. That requires a small table of well-known programs and the
variables they need, which is exactly the kind of semantic knowledge P10 says the
compiler should hold. Without that table this law is user-hostile and should not
ship. (3) The deny-list (`LD_PRELOAD` et al.) is the part that must **never** be
negotiable, because it is short, closed, and never legitimately set from
application code — so even a package that calls `inherit_all()` still cannot
*construct* an `LD_PRELOAD` injection from data.

---

### Law 5 — **Output is bounded-and-captured or streamed; there is no third door, and both are drained concurrently.**

`run()` captures with a limit and errors on overflow — never truncates.
`stream()` yields channels and never accumulates. The runtime drains every stream
concurrently on green threads, so the caller never holds a pipe end and cannot
sequence a deadlock. Bytes are bytes; `text()` is fallible; nothing is trimmed
implicitly. Because the drain is concurrent, arrival order is recorded for free:
`out`, `err`, and `log` are three views of one capture. Two deadlines exist —
one on the child's life, one on how long output may arrive after it exits.

*Prior art:* Zig's mandatory `max_output_bytes`, typed-process's draining thread
and type-tracked streams, duct's IO threads, Go's `WaitDelay`, Deno's
`Uint8Array`. The three-views idea has no prior art.

**Counter-argument:** *a mandatory limit turns a working program into a failing
one for no security benefit.* Every developer will hit `OutputTooLarge` on a
legitimate `git log` or `docker logs` and will set the limit to something absurd
rather than restructure into `stream()`, so the law converts a rare OOM into a
common annoyance and then gets defeated anyway. And the three-views capture is
not free: it holds a per-chunk record for the whole run, so a chatty process
costs allocation and memory proportional to *chunk count*, not just byte count —
paying, on every run, for a debugging affordance most runs never read.

**Answer:** the limit's defence is Zig's evidence — Zig has shipped with no
unbounded path and the ecosystem did not revolt, because the failure is *loud and
actionable* ("stdout exceeded 8 MiB — raise `capture_limit` or use `stream()`")
rather than an OOM-kill with no stack. A developer raising the limit at the call
site has made a visible decision, which is P8 working, not the law being
defeated. The memory objection is fair and changes the design: `log` should be
**opt-in per run** (`interleaved true`) or, better, capped by chunk count with
the same loud overflow, so the common `run()` pays only two byte buffers. What
must *not* be opt-in is the concurrent drain itself, because that is what closes
A6 — the ordering is a by-product, and only the *recording* of it is optional.

---

## The five, in one line each

1. **argv is a list; a shell string is a distinct type, spelled at the site.**
2. **A verdict is a value, never an integer** — and `exit()` takes one too.
3. **A child has a scope; the scope owns its death** — group, ladder, pidfd.
4. **The environment is closed; `PATH` never looks in the cwd.**
5. **Bounded capture or streaming, concurrently drained** — no third door.

## What this survey says is genuinely new

Most of the above is theft, and says so. Three things are not:

- **A11** — no language types its own `exit()` as a verdict, so the
  count-wraps-to-256 bug is available in all of them.
- **A21 / B10** — no language gives you stdout and stderr *separately and in
  order* from one run. It is free once the drain is concurrent, and every other
  library throws the information away.
- **B12's `run_pure`** — Bazel and Nix proved a process with declared inputs is a
  cacheable pure function, but only inside a build system. Avra already computes
  the two hard parts of the key (argv, at compile time; env, from the manifest),
  so it is the first general-purpose language in a position to offer it as a
  library call — with Nix's fixed-output hash as the escape hatch that keeps the
  guarantee instead of voiding it.
