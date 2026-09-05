# `@std/process` — the POSIX substrate

Research for a clean-room subprocess library over a single-threaded,
refcounted C runtime with an IR evaluator that must agree with native.
Targets: Darwin/arm64 first, Linux second.

**Verified on this machine** (macOS 26.5.2, build 25F84, Xcode SDK
`MacOSX.sdk`) by reading `usr/include/spawn.h`, `usr/include/sys/spawn.h`,
`usr/include/unistd.h`, `usr/include/sys/fcntl.h`, `usr/include/util.h`.
Everything marked "*(SDK)*" is a direct read of those headers, not a claim
from memory.

---

## 0. What must die, and why

`runtime/avra_runtime.c:977` today:

```c
int64_t avra_shell_exec_status(const char* cmd) {
    int status = system(cmd);
    if (status == -1) return 127;
    if (WIFSIGNALED(status)) return 128 + WTERMSIG(status);
    return (int64_t)WEXITSTATUS(status);
}
```

Six independent reasons this cannot be the seam:

1. **It is a second language.** `system()` runs `/bin/sh -c <string>`.
   Every argument is a quoting problem: a filename with a space, `$`, `;`,
   backtick, newline, or a leading `-` changes *what program runs*.
   Injection is not a bug you review your way out of — it is the interface.
2. **Signals.** POSIX requires: *"During execution of the command, SIGCHLD
   will be blocked, and SIGINT and SIGQUIT will be ignored, in the process
   that calls system()."*
   ([system(3)](https://man7.org/linux/man-pages/man3/system.3.html))
   A runtime that will own an M:N scheduler cannot have SIGCHLD blocked for
   an unbounded interval, and swallowing SIGINT means Ctrl-C is dead for the
   child's whole lifetime.
3. **Status ambiguity, twice over.** The man page: *"It is possible for the
   shell command to terminate with a status of 127, which yields a system()
   return value that is indistinguishable from the case where a shell could
   not be executed."* The code above adds a *second* collision by folding
   signal deaths into `128 + signum`: a program that legitimately exits 137
   is indistinguishable from one killed by SIGKILL, and `-1` (fork failed)
   is folded into `127` as well. Three distinct facts, one small integer.
4. **No control.** No stdin, no captured stdout/stderr, no cwd, no env, no
   timeout, no kill, no pid. It blocks the whole runtime for the child's
   lifetime.
5. **Ambient environment.** The shell re-reads `IFS`, `ENV`/`BASH_ENV`,
   `PATH`, `CDPATH`, and (bash-as-sh) `BASH_FUNC_*`. Child behaviour depends
   on our environment in ways nothing in the source shows — the exact
   opposite of P7 (visible magic).
6. **Locale.** `sh` itself emits localized diagnostics.

**Replacement law:** nothing in `@std/process` ever takes a command
*string*. The unit is `(program, List<string>)`. A user who genuinely wants
a shell writes `["/bin/sh", "-c", script]` explicitly — visible in the
source, and theirs to own.

---

## 1. SPAWN

### 1.1 posix_spawn vs fork+exec vs vfork

**Use `posix_spawn` (never `posix_spawnp` — see §1.4).**

| | cost | hazard |
|---|---|---|
| `fork()`+`execve` | O(page tables) in the parent's address space; a compiler heap of hundreds of MB makes each spawn measurably slow ([rust#87764](https://github.com/rust-lang/rust/issues/87764)) | between fork and exec only async-signal-safe calls are legal; a refcounted runtime's `malloc` and any lock held at fork time are live hazards |
| `vfork` / `clone(CLONE_VM\|CLONE_VFORK)` by hand | fastest | child *shares the parent's address space* and the parent is suspended; any write corrupts the parent, any `return`/`longjmp` is UB |
| `posix_spawn` | on glibc ≥ 2.24 it *is* `clone(CLONE_VM\|CLONE_VFORK)` internally ([posix_spawn(3) notes](https://man7.org/linux/man-pages/man3/posix_spawn.3.html)); on Darwin it is a real **system call** (`POSIX_SPAWN(2)`) | none of the above — the dangerous window lives inside libc |

You get the vfork win without writing the vfork hazard. That is the whole
argument.

**Error reporting.** On Darwin, `posix_spawn` is section 2 and returns the
real errno directly: `ENOENT`, `EACCES`, `ENOEXEC`, `E2BIG`, `ELOOP`,
`ENAMETOOLONG`, `ETXTBSY`, `ENOTDIR`, `EIO`, `ENOMEM`
([Apple posix_spawn(2)](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/posix_spawn.2.html)).
On glibc ≥ 2.24 the child shares memory with the parent until exec and
writes its failure errno back, so `posix_spawn` also returns the real errno.
The man page's *"exits with a status of 127"* fallback is the older /
other-libc behaviour — **handle both**: treat a 127 exit with no output as
*possibly* an exec failure, but never synthesize one.

**When fork+exec is genuinely required:** an arbitrary pre-exec hook —
`setrlimit`, `setuid`, `landlock_restrict_self`, `seccomp`, `sandbox_init`.
v1 offers **no hook**, deliberately: a hook is Avra code running between
fork and exec, i.e. refcounting code in a forked child that shares locks
with a suspended parent. It is also unhostable by the IR evaluator. When the
sandbox lane lands (§6), it brings a second, fork-based spawn path with it.

### 1.2 File actions — what exists where

*(SDK)* Darwin `spawn.h` availability annotations, read verbatim:

| function | Darwin | Linux/glibc |
|---|---|---|
| `posix_spawn`, `posix_spawnp` | `macos(10.5)` | always |
| `posix_spawn_file_actions_addclose` | `macos(10.5)` | always |
| `posix_spawn_file_actions_adddup2` | `macos(10.5)` | always |
| `posix_spawn_file_actions_addopen` | `macos(10.5)` | always |
| `posix_spawn_file_actions_addinherit_np` | `macos(10.7)` — **Darwin only** | — |
| `posix_spawn_file_actions_addchdir_np` | `macos(10.15)`, `__API_DEPRECATED(..., macos(10.15, 26.0))` | **glibc 2.29** |
| `posix_spawn_file_actions_addchdir` (POSIX.1-2024 name) | `macos(26.0)` | glibc ≥ 2.41 |
| `posix_spawn_file_actions_addfchdir_np` / `addfchdir` | same pair of thresholds | glibc 2.29 / ≥2.41 |

glibc 2.29 NEWS, verbatim: *"The functions
`posix_spawn_file_actions_addchdir_np` and
`posix_spawn_file_actions_addfchdir_np` have been added, enabling
`posix_spawn` and `posix_spawnp` to run the new process in a different
directory."* (bug [17405](https://sourceware.org/bugzilla/show_bug.cgi?id=17405)).
gnulib lists it *missing* on: *"glibc 2.28, macOS 10.14, FreeBSD 13.0,
NetBSD 10.0, OpenBSD 7.9, Minix 3.1.8, AIX 7.1, HP-UX 11.31, Solaris 11.0,
Cygwin 3.4.x, mingw, MSVC 14, Android API level 33"*
([gnulib](https://www.gnu.org/software/gnulib/manual/html_node/posix_005fspawn_005ffile_005factions_005faddchdir_005fnp.html)).
Needs `_GNU_SOURCE` on glibc. **musl lacks it** — Rust `dlsym`s it
([rust#131851](https://github.com/rust-lang/rust/pull/131851)).

**Resolution:** resolve `posix_spawn_file_actions_addchdir` then
`..._addchdir_np` by `dlsym(RTLD_DEFAULT, ...)` at first use, cache the
pointer. One binary then runs from macOS 10.15 through 26+, and on glibc
2.29+ and musl alike. Fallback when neither resolves: `open(".",
O_RDONLY|O_CLOEXEC)` → `chdir(cwd)` → spawn → `fchdir(saved)`. **Correct
only while the runtime is single-threaded** — flag it loudly for the M:N
era.

### 1.3 Spawn attributes

*(SDK)* `sys/spawn.h`, exact bit values:

```
POSIX_SPAWN_RESETIDS        0x0001   POSIX
POSIX_SPAWN_SETPGROUP       0x0002   POSIX
POSIX_SPAWN_SETSIGDEF       0x0004   POSIX
POSIX_SPAWN_SETSIGMASK      0x0008   POSIX
POSIX_SPAWN_SETEXEC         0x0040   Darwin only  (this is how exec() is built)
POSIX_SPAWN_START_SUSPENDED 0x0080   Darwin only
POSIX_SPAWN_SETSID          0x0400   Darwin only *bit value*; glibc has the
                                     name since 2.26 with its own value
POSIX_SPAWN_CLOEXEC_DEFAULT 0x4000   Darwin only
```

The Darwin-only block is inside
`#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)` — compile the
process TU **without** `-D_POSIX_C_SOURCE`, or with `-D_DARWIN_C_SOURCE`, or
`POSIX_SPAWN_CLOEXEC_DEFAULT` silently vanishes and every fd leaks.

What v1 sets, always:

- **`POSIX_SPAWN_SETSIGMASK` with an empty `sigset_t`.** The child must not
  inherit our mask. The moment the scheduler blocks SIGCHLD process-wide,
  every child would start with SIGCHLD blocked and hand that to *its*
  children — an invisible, deeply-nested breakage.
- **`POSIX_SPAWN_SETSIGDEF` with every catchable signal.** `execve(2)`:
  *"The dispositions of any signals that are being caught are reset to the
  default"* — but *"POSIX.1 specifies that the dispositions of any signals
  that are ignored ... are left unchanged."*
  ([execve(2)](https://man7.org/linux/man-pages/man2/execve.2.html))
  Our runtime must ignore SIGPIPE (§2.5); without SETSIGDEF **every child
  inherits ignored SIGPIPE**, so `head`, `less` and every well-behaved
  pipeline member stops dying at the right moment and instead spins on
  EPIPE. This is the single most-missed spawn bug in the wild.
  Build the set explicitly and **exclude SIGKILL and SIGSTOP** rather than
  using `sigfillset` — implementations differ on whether they reject them.
- **`POSIX_SPAWN_SETPGROUP` + `posix_spawnattr_setpgroup(&at, 0)`** when the
  caller asked for a killable tree: the child becomes its own process-group
  leader (pgid == pid) so `killpg` reaches its descendants (§3.4). Note the
  side effect: it also leaves our terminal's foreground group, so an
  interactive Ctrl-C no longer reaches the child. Make that a flag, not a
  default.
- **`POSIX_SPAWN_SETSID`** only for daemon-shaped spawns. A session leader
  has **no controlling terminal**, so it can never prompt for a password.

Never set `POSIX_SPAWN_RESETIDS` (surprising credential change) and never
`POSIX_SPAWN_SETEXEC` (that flag makes `posix_spawn` *replace* the caller —
it is Darwin's implementation of `exec`).

### 1.4 "Everything closed except what we meant"

**Darwin — solved, atomically.** `POSIX_SPAWN_CLOEXEC_DEFAULT` (0x4000):
*"only file descriptors explicitly described by the file_actions argument
are available in the spawned process; all of the other file descriptors are
automatically closed in the spawned process."* Apple's own rationale is that
it removes the race window between creating an fd and setting FD_CLOEXEC on
it ([libuv#1483](https://github.com/joyent/libuv/issues/1483)). To pass an
extra fd through *without* a dup2, `posix_spawn_file_actions_addinherit_np`
(macOS 10.7+) marks a descriptor for inheritance and clears FD_CLOEXEC on it
in the child image; it only accepts fds `< OPEN_MAX` (10240)
([cpython#109154](https://github.com/python/cpython/issues/109154)).

**Linux — not solved; two layers.**

1. *Discipline (the real fix):* every fd the runtime ever creates is
   `O_CLOEXEC` **at birth** — `pipe2(fds, O_CLOEXEC)`, `open(..., O_CLOEXEC)`,
   `socket(..., SOCK_CLOEXEC)`, `accept4(..., SOCK_CLOEXEC)`. This is a
   runtime-wide rule, not a spawn-time patch, and it is the only thing that
   is race-free once threads exist.
2. *Belt:* immediately before spawn, `close_range(3, ~0U,
   CLOSE_RANGE_CLOEXEC)` — *marks* rather than closes, so fds we are still
   using are unaffected; the file actions' `adddup2` then clears CLOEXEC on
   0/1/2. `close_range` is **Linux 5.9**, `CLOSE_RANGE_CLOEXEC` is **Linux
   5.11**, the glibc wrapper is **2.34**
   ([close_range(2)](https://man7.org/linux/man-pages/man2/close_range.2.html));
   call it via `syscall(__NR_close_range, ...)` when the wrapper is absent
   and treat `ENOSYS`/`EINVAL` as "skip".
   Pre-5.11 fallback: walk `/proc/self/fd` and `fcntl(F_SETFD, FD_CLOEXEC)`.
   **Never** `for (i = 3; i < sysconf(_SC_OPEN_MAX); i++) close(i)` — with a
   raised `RLIMIT_NOFILE` that is a million syscalls per spawn.

**Darwin has no `pipe2` and no `close_range`/`closefrom`.** *(SDK: grep of
`unistd.h` finds neither `pipe2` nor `close_range` nor `closefrom`;
`O_CLOEXEC` = `0x01000000` is present in `sys/fcntl.h`, and there is no
`O_CLOFORK`.)* So on Darwin: `pipe(fds)` then `fcntl(F_SETFD, FD_CLOEXEC)`
on both ends. The window between the two calls is a real race *in a
multithreaded program*; it is harmless today (one thread) and harmless
regardless under `CLOEXEC_DEFAULT`, but it comes back the day two OS threads
can spawn. Record it.

**dup2 subtlety:** `posix_spawn_file_actions_adddup2(fa, from, to)` with
`from == to` is required to *clear FD_CLOEXEC on `to`* rather than being a
no-op (POSIX.1-2008 TC clarification; glibc and Darwin comply). Do not rely
on it — instead guarantee every pipe fd is `> 2` by `dup`ing it up if
`pipe()` handed back 0/1/2 (which happens whenever the runtime was started
with a closed standard descriptor — a real situation under `daemon`,
`launchd`, and some CI runners). Cheap, and it deletes a whole class.

### 1.5 PATH lookup — resolve it ourselves

**Do not use `posix_spawnp`.** Three concrete reasons:

1. **It searches the *parent's* `PATH`, not the child's `envp`.** POSIX
   defines `posix_spawnp` as searching *"in the same way as for
   execvp(3)"*, and `execvp` reads `PATH` from the caller's environment. We
   are handing the child a scrubbed allow-list environment; having the
   lookup silently use *our* `PATH` is precisely the confusion that makes
   spawn behaviour unauditable.
2. **On Darwin it ignores the chdir file action.** Apple's `posix_spawnp`
   resolves the program path using the *parent's* working directory even
   when `posix_spawn_file_actions_addchdir_np` set a different one
   ([zed#55672](https://github.com/zed-industries/zed/pull/55672)). `spawnp
   + addchdir` is a trap.
3. **Empty PATH means the current directory.** *"When the PATH environment
   variable isn't defined, the path list defaults to the current directory
   followed by ... `confstr(_CS_PATH)`"*, and *"the glibc implementation
   long followed the traditional default where the current working directory
   is included at the start of the search path"* — dropped by accident
   during 2.24 refactoring
   ([exec(3)](https://man7.org/linux/man-pages/man3/exec.3.html)). An
   *empty element* in `PATH` (leading `:`, trailing `:`, or `::`) also means
   `.`. This is the classic trojan.

**Go's answer, and ours.** Since Go 1.19 `os/exec` refuses to resolve an
executable found via the current directory: *"if the usual path algorithms
would result in that answer, these functions return an error err satisfying
errors.Is(err, ErrDot)"* ([os/exec](https://pkg.go.dev/os/exec)). We go one
step further and refuse *any* non-absolute PATH element.

Our `resolve(file, path)`:

```
if file contains '/'          -> use as-is, no search
if not SEARCH_PATH flag       -> -EINVAL   (a bare name with no search is a bug)
if path is absent or empty    -> -ENOENT   (never confstr(_CS_PATH))
for each element of path split on ':':
    if element is ""          -> SKIP  (this is the "." case; refuse it)
    if element[0] != '/'      -> SKIP  (relative PATH entry; refuse it)
    cand = element + "/" + file
    stat(cand): not present   -> continue
                not S_ISREG   -> continue
                !access(X_OK) -> remember EACCES, continue
    -> cand
no candidate: -ENOENT, or -EACCES if some candidate existed but was not executable
```

`PATH` comes from **the envp we are giving the child**, never `getenv`.

**The TOCTOU this implies, stated honestly.** Between our `stat`/`access`
and the kernel's `open` inside `posix_spawn`, the path can be swapped. The
correct fix is to execute a *descriptor*: Linux has `fexecve(3)` /
`execveat(fd, "", ..., AT_EMPTY_PATH)`; **Darwin has neither, and
`posix_spawn` has no by-fd form**. So on Darwin the window is unavoidable.
Three mitigations, in order of honesty:

- Accept it, and note that `posix_spawn` re-checks: the worst case is that
  we execute a *different* file than the one we stat'd, not that we execute
  something the user could not have executed anyway.
- Prefer absolute program paths in callers; `SEARCH_PATH` is opt-in for that
  reason.
- Do **not** add "refuse world-writable directories" heuristics in v1 —
  they are half-measures that read as guarantees.

`avra_proc_which(file, path)` exposes exactly this resolution as a query, so
the answer is inspectable before the spawn (P7).

### 1.6 argv/envp limits

`execve(2)`: *"the limit per string is 32 pages (the kernel constant
MAX_ARG_STRLEN)"* — 131072 bytes on a 4 KiB-page Linux — *"and the maximum
number of strings is 0x7FFFFFFF"*; *"the total size is limited to 1/4 of the
allowed stack size"*. Darwin caps the total at `KERN_ARGMAX` (1 MiB on
macOS). Over the limit is `E2BIG`, and it is a *runtime* failure that
depends on the user's `ulimit -s`. A library that builds long argv (a
compiler driver!) must either chunk or answer `-E2BIG` clearly rather than
letting the shell-style "argument list too long" surface from nowhere.

---

## 2. I/O WITHOUT THREADS

### 2.1 The deadlock

Two pipes and one thread is a deadlock generator. If we `read()` stdout
while the child writes to stderr, the child blocks once the stderr pipe
fills (default capacity **65536 bytes** on Linux since 2.6.11, tunable with
`fcntl(F_SETPIPE_SZ)` /
[`pipe(7)`](https://man7.org/linux/man-pages/man7/pipe.7.html); Darwin
starts at 16 KiB and grows), and we block forever waiting for stdout that
will never come. Symmetrically for feeding stdin: writing more than a pipe
buffer of input without draining output deadlocks.

**The law:** stdout, stderr, and (when there is pending input) the stdin
write end are all in the **same `poll()` set**, always.

### 2.2 The pump — one tick

```c
// avra_proc_poll(h, timeout_ms): one tick, never blocks longer than timeout
struct pollfd p[4]; int n = 0;
if (h->in  >= 0 && h->in_pending)  p[n++] = (struct pollfd){h->in,  POLLOUT, 0};
if (h->out >= 0)                   p[n++] = (struct pollfd){h->out, POLLIN,  0};
if (h->err >= 0)                   p[n++] = (struct pollfd){h->err, POLLIN,  0};
// optional: h->exitfd (Linux pidfd / Darwin kqueue fd), POLLIN
int r = poll(p, n, (int)timeout_ms);      // retry on EINTR with a RECOMPUTED timeout
// for each readable fd: read() into that stream's growable buffer until EAGAIN
//   read() == 0  or POLLHUP -> close, mark EOF
// for the writable stdin fd: write() the remaining slice; on full-drain, close
// then: waitpid(h->pid, &st, WNOHANG) exactly once; cache the status
```

`poll(2)` is right on **both** platforms for 3–4 fds; `epoll`/`kqueue` only
pay off at hundreds of descriptors. Use the platform exit primitives (§3.3)
only for the *exit* event, and only once a scheduler needs to block
indefinitely.

### 2.3 Ordering rules that are not optional

- **Never reap before draining.** Data sits in the pipe after the child
  exits. `waitpid` returning does not mean the pipes are empty.
- **EOF on both pipes ≠ exited.** A child may close its descriptors and keep
  running.
- **Exited ≠ EOF on both pipes.** A *grandchild* that inherited stdout keeps
  the write end open forever — `ssh -f`, `nohup`, any daemonizing server.
  This is exactly why Go has `WaitDelay` (§4).
- **The parent must close its copies of the child's ends immediately after
  spawn** (`w_out`, `w_err`, `r_in`). Otherwise *we* are the last holder of
  the write end and EOF never arrives; the child never sees EOF on stdin.
  Trap #1 in every subprocess library ever written.

### 2.4 Non-blocking, partial reads, line splitting

- Set `O_NONBLOCK` (`fcntl(F_SETFL)`) on **our** pipe ends only. `O_NONBLOCK`
  is a property of the *open file description*; a pipe's read end and write
  end are **different descriptions**, so this never leaks into the child.
  **But:** if we ever hand the child an inherited fd (our own tty stdin),
  never set `O_NONBLOCK` on it — that description *is* shared with our
  terminal and with the invoking shell. That is the classic "shell goes
  crazy after the program exits" bug.
- `read()` returns whatever is present. A line, a UTF-8 sequence, and an
  ANSI escape can all split across two reads. **Buffer bytes; never decode
  per chunk.**
- Incremental line splitter: append the chunk to a tail buffer, emit up to
  and including the last `\n`, keep the remainder. At EOF emit the remainder
  if non-empty. Handle `\r\n` by trimming a trailing `\r` at emit time, not
  by scanning for `\r`.
- `PIPE_BUF` (4096 on Linux) only governs atomicity between *multiple
  writers*; irrelevant to a single child.
- **Every `poll`/`read`/`write` retries on `EINTR`.** With SIGCHLD at
  SIG_DFL there is no EINTR source today, but a scheduler's preemption timer
  will produce them constantly.

### 2.5 SIGPIPE

- The runtime installs `signal(SIGPIPE, SIG_IGN)` **once**, at init. Then a
  write to a pipe whose reader is gone answers `-1/EPIPE` instead of killing
  the process — [`pipe(7)`](https://man7.org/linux/man-pages/man7/pipe.7.html):
  *"a write(2) will cause a SIGPIPE ... If the calling process is ignoring
  this signal, then write(2) fails with the error EPIPE."*
- Because ignored dispositions survive `execve`, **the spawn must undo it**
  for the child via `POSIX_SPAWN_SETSIGDEF` (§1.3). The two halves are one
  decision; shipping half of it is worse than shipping neither.
- On the stdin write fd, `poll` reports `POLLERR` (Linux) or `POLLHUP` when
  the reader closes. Treat `POLLERR`/`POLLNVAL`/`EPIPE` identically: the
  child closed stdin — close our end, stop feeding, and do **not** call it
  an error. A child that reads the first line and exits (`head -1`) is
  normal.

### 2.6 Interleaving — what is actually possible

Be honest here, because every library lies about it.

- **Two pipes: the order between the streams is not recoverable.** Period.
  Timestamping at read time records when *we* read, not when the child
  wrote. A 4 KiB stdout burst and a 20-byte stderr line arrive in either
  order because the child's libc block-buffers stdout when it is a pipe and
  leaves stderr unbuffered. Go documents the same limit: `Run`, `Output` and
  `CombinedOutput` *"do not enforce ordering between stdout and stderr"*.
- **One pipe (`adddup2(w, 1)` then `adddup2(w, 2)`) is faithful.** Both
  child descriptors point at the *same open file description*, so the byte
  order in the pipe is exactly the child's write order. The price is that
  you can no longer tell the streams apart. Offer it as an explicit `MERGE`
  flag; never synthesize it.
- **Even merged, the child's own buffering distorts it.** stdout is
  block-buffered into a pipe, stderr is not, so a merged capture typically
  shows all the stderr first and then a 4 KiB stdout dump. That is a
  property of the *child's* libc, not of our pump — `stdbuf(1)` and
  `unbuffer(1)` exist for exactly this reason. Only a pty changes it.

### 2.7 PTY — not in v1, and here is why

`openpty(int *amaster, int *aslave, char *name, const struct termios *,
const struct winsize *)`, `login_tty(int fd)`, `forkpty(...)` — *(SDK:
present in `util.h` on Darwin; on Linux they need `-lutil`)*.

Five reasons it does not belong in v1:

1. **`forkpty` is fork-based.** It calls `login_tty`, which must run *in the
   child* (`setsid()` + `ioctl(TIOCSCTTY)`). There is no posix_spawn file
   action for "become a session leader with this controlling terminal", so a
   pty path forces a second, fork-based spawn implementation. That alone
   settles it.
2. **A pty is a terminal, and terminals edit your data.** `ECHO` is on by
   default, so everything you write to stdin comes back as output.
   `ONLCR` turns every `\n` into `\r\n`, so every captured line grows a
   `\r`. Programs read the window size and reflow.
3. **stdout and stderr are unavoidably merged** — a pty has one stream.
4. **EOF has two spellings.** On Linux, `read()` on the master answers
   `EIO` once the last slave closes; on Darwin it answers `0`. Two platforms,
   two idioms, and getting it wrong is an infinite loop or a spurious error.
5. **It changes the child's behaviour**: `isatty()` becomes true, so colors,
   progress bars, and pagers switch on. A v1 that captures output must be
   boring and reproducible.

A pty belongs to a later `@std/process/tty` built on a `spawn_pty` primitive
— naturally, once the fork+exec path exists for the sandbox hook anyway.

---

## 3. WAITING & IDENTITY

### 3.1 waitpid, zombies, and the ONE reap

- `waitpid(pid, &st, WNOHANG)` inside the pump tick. **Reap exactly once**
  and cache the raw status in the handle.
- **Never `signal(SIGCHLD, SIG_IGN)` and never `SA_NOCLDWAIT`.** Both make
  children auto-reaped, after which `waitpid` fails with `ECHILD` and every
  exit status is lost — silently, and only in programs that happened to set
  it somewhere far away.
- A handle closed without a wait leaves a zombie until the process exits.
  `avra_proc_close` therefore: if not yet reaped → `killpg`/`kill` SIGKILL,
  then a **blocking** `waitpid` (now guaranteed fast), then free.
  Deterministic, no leak, no thread, no reaper task.

### 3.2 The pid-reuse race, and why it costs us nothing

The race is real: *"as soon as wait() returns, the process is gone from the
process table, and therefore another fork() on the system could immediately
re-use the same PID"*. The mitigation is one line of bookkeeping:

> **After reaping, set `h->pid = -1`. `avra_proc_signal` refuses a reaped
> handle with `-ESRCH`.**

Because *only we* reap our own children, there is no interval in which our
recorded pid names somebody else's process: before the reap it names our
zombie (a signal to a zombie is a harmless no-op), and after the reap we
have no pid at all. The hazard only exists for programs that reap
asynchronously (a SIGCHLD handler, `SIG_IGN`, a second reaper) — which §3.1
already forbids.

Handles get the same discipline one level up: a **generation counter in the
high bits** of the `int64_t` handle so a stale handle can never address a
freshly allocated slot. Reuse of an integer is exactly the pid problem with
a different name.

### 3.3 Exit-event descriptors (needed only once a scheduler exists)

- **Linux: `pidfd_open(pid, 0)`** — Linux **5.3**; `PIDFD_NONBLOCK` is
  **5.10**; `PIDFD_THREAD` is 6.9
  ([pidfd_open(2)](https://man7.org/linux/man-pages/man2/pidfd_open.2.html)).
  Put it in the same `poll` set: *"When the task that it refers to
  terminates and becomes a zombie, these interfaces indicate the file
  descriptor as readable (EPOLLIN). When the task is reaped, these
  interfaces produce a hangup event (EPOLLHUP)."* Reap with `waitid(P_PIDFD,
  fd, &info, WEXITED)`; signal with `pidfd_send_signal`. Race-free by
  construction — the pidfd pins the identity. Opening it right after spawn
  is safe *provided we have not reaped and SIGCHLD is not SIG_IGN* (the man
  page's own condition); the atomic alternative is `clone3` with
  `CLONE_PIDFD`, which `posix_spawn` does not expose.
- **Darwin: kqueue `EVFILT_PROC` / `NOTE_EXIT`.**
  `EV_SET(&kev, pid, EVFILT_PROC, EV_ADD|EV_ONESHOT, NOTE_EXIT, 0, NULL)`;
  `kevent()` delivers the raw wait status in `kev.data` (readable with
  `WIFEXITED` and friends). Registering *after* the child already exited
  still reports the pending event, so it is not racy; `EVFILT_PROC` is
  self-clearing and `NOTE_EXIT` is one-shot per pid. You must still
  `waitpid` to reap. (PostgreSQL keeps a `getppid()` cross-check alongside
  its kqueue watch specifically to close a pid-reuse window — the same
  belt-and-braces our §3.2 rule buys.)
- **v1 needs neither.** `waitpid(WNOHANG)` inside a bounded poll tick is
  correct and identical on both platforms. Add the exit fd when the pump
  must block without a deadline.

### 3.4 Process groups, sessions, and killing the tree

- `POSIX_SPAWN_SETPGROUP` + pgid 0 → the child leads a new group; `killpg(pid,
  SIGTERM)` (equivalently `kill(-pid, ...)`) reaches every descendant that
  did not change groups. **This is the only portable tree-kill.**
- It is defeatable: any descendant that calls `setsid()` or `setpgid()`
  escapes the group. There is no portable containment. Linux can do better
  with a delegated cgroup (`cgroup.kill`, or freeze-then-kill); macOS cannot.
  Say so rather than implying a guarantee.
- `POSIX_SPAWN_SETSID` gives a whole new session (no controlling terminal);
  `kill(-pgid)` still only reaches the leader's group inside it.

### 3.5 What happens to children when the parent dies — the honest answer

- **Linux `PR_SET_PDEATHSIG` is not a solution.** Verbatim
  ([PR_SET_PDEATHSIG(2const)](https://man7.org/linux/man-pages/man2/PR_SET_PDEATHSIG.2const.html)):
  - *"The 'parent' in this case is considered to be the **thread** that
    created this process ... the signal will be sent when that thread
    terminates (via, for example, pthread_exit(3)), rather than after all of
    the threads in the parent process terminate."* — an M:N runtime that
    retires the worker thread which happened to spawn will kill every child.
  - *"It is also ... cleared when executing a set-user-ID or set-group-ID
    binary, or a binary that has associated capabilities"*, and *"also
    cleared upon changes to any of the following thread credentials:
    effective user ID, effective group ID, filesystem user ID, or filesystem
    group ID."*
  - *"If the parent thread and all ancestor subreapers have already
    terminated by the time of the PR_SET_PDEATHSIG operation, then no
    parent-death signal is sent to the caller."* — an inherent race.
  - And it must be called **in the child**, which `posix_spawn` gives us no
    hook for.
- **Darwin has no equivalent at all.**
- **The portable technique that does work, and its limit:** a *death pipe* —
  the parent holds the write end, the child holds the read end and never
  writes to it. When the parent dies *by any means, SIGKILL included*, the
  write end closes and the child's read reports EOF. This requires **child
  cooperation**, so it only works for children we wrote.
- For arbitrary children: **nothing is guaranteed.** The truthful API
  statement is "orphaned descendants may outlive the runtime; use a process
  group and kill it explicitly." A supervisor process, a cgroup, or (on
  Windows) a Job object is the only real containment.

### 3.6 SIGCHLD and the future M:N scheduler

One waiter loop, never a signal handler that reaps.

- **Linux:** block SIGCHLD process-wide and either drive `signalfd(SIGCHLD)`
  from the reactor, or — better — skip signals entirely and keep one
  **pidfd per child** in the reactor's epoll set. The second has no global
  state and no signal-safety rules at all.
- **Darwin:** one `EVFILT_PROC`/`NOTE_EXIT` registration per child on the
  reactor's kqueue. Again no signal handling.
- If a handler is ever unavoidable, its **only** legal body is a `write()`
  of one byte to a self-pipe; reaping happens in the loop.
- And every spawn must clear the blocked mask for the child
  (`POSIX_SPAWN_SETSIGMASK`, §1.3), or the whole tree inherits a blocked
  SIGCHLD.

### 3.7 Exit status — ONE encoding

The requirement is that a signal death can never read as a small exit code.
The shell's `128 + signum` convention **fails this** (exit 137 vs SIGKILL),
and so does today's `avra_shell_exec_status`.

**Encoding — one `int64_t`, tag in the high half:**

```c
#define AVRA_EXIT_RUNNING  0   /* not yet reaped                       */
#define AVRA_EXIT_CODE     1   /* WIFEXITED                            */
#define AVRA_EXIT_SIGNAL   2   /* WIFSIGNALED                          */
#define AVRA_EXIT_STOPPED  3   /* WIFSTOPPED (needs WUNTRACED; not v1) */

/* status = ((int64_t)tag << 32) | (payload & 0xffffffff) */
/* CODE  : payload = WEXITSTATUS(st)                    0..255         */
/* SIGNAL: payload = WTERMSIG(st) | (WCOREDUMP(st) ? 0x100 : 0)        */
```

Properties that make it safe:

- `RUNNING` is the only status whose whole word is `0`. A caller that forgot
  to wait sees "running", never "success".
- Success is `0x1_0000_0000`, **not** `0`. There is no integer that means
  both "exited 0" and "killed by signal 0", because the tag lives in bits
  the payload cannot reach.
- SIGKILL is `0x2_0000_0009`; exit 137 is `0x1_0000_0089`. Nothing collides.
- Spawn failure is **not a status at all** — `avra_proc_spawn` answers
  `-errno` and no handle is created, so the 127 ambiguity cannot arise.

Avra decodes it **once**, in one projection:

```avra
enum Exit {
    Running
    Code(code: int)
    Signal(sig: int, core: bool)
    Stopped(sig: int)
}
```

`WCOREDUMP` is not in POSIX and needs `_BSD_SOURCE`-ish exposure on glibc;
it exists on Darwin. Guard it with `#ifdef WCOREDUMP` and report `false`
where it is absent.

---

## 4. TIMEOUTS & KILL ESCALATION (no threads)

```
deadline = mono_ms() + timeout_ms
loop:
    remain = deadline - mono_ms()
    if remain <= 0: break
    ev = pump_tick(h, min(remain, 100))          /* 100 ms cap: stay responsive */
    if (ev & EXITED) && (ev & OUT_EOF) && (ev & ERR_EOF): return DONE

/* escalate */
signal_target(h, SIGTERM)                        /* killpg when NEW_PGROUP, else kill */
grace = mono_ms() + grace_ms
loop until grace: pump_tick(...); if fully done: return TERMED

signal_target(h, SIGKILL)                        /* cannot be caught */
loop with a WaitDelay bound: pump_tick(...); if exited: break
close h->out, h->err                             /* unblock ourselves */
return KILLED | TRUNCATED
```

Non-obvious requirements:

- **Monotonic clock.** `clock_gettime(CLOCK_MONOTONIC, ...)` — the runtime
  already has `avra_now_ns` doing exactly this
  (`runtime/avra_runtime.c:920`). Never `gettimeofday`: an NTP step would
  move the deadline.
- **Recompute the poll timeout every iteration.** `poll`'s timeout is
  *relative*. A loop that retries `poll(fds, n, timeout_ms)` after `EINTR`
  with the original value restarts the full timeout each time, so a child
  that generates output steadily can extend a "5 second" deadline
  indefinitely. This is a real, common bug.
- **The 100 ms cap** also bounds the case "the child exited but a grandchild
  holds the pipe": we notice `EXITED` promptly and can start the WaitDelay
  clock instead of blocking on a read that will never end.
- **Cap total captured bytes** (`max_bytes`). Time is not the only unbounded
  resource: a child printing forever exhausts memory long before any
  timeout fires. On overflow: stop reading that stream, set `CAPPED`, and
  escalate. Two bounds, both mandatory.
- **SIGKILL to the group, then keep pumping until the reap.** SIGKILL is
  uncatchable, so this always terminates — but only for processes *in the
  group*; §3.4's escape hatch still applies.

### Go's `WaitDelay`, and why we need the same thing

Verbatim ([os/exec](https://pkg.go.dev/os/exec)): *"The WaitDelay timer
starts when either the associated Context is done or a call to Wait observes
that the child process has exited, whichever occurs first."* When it
elapses, Go kills the process **and closes the I/O pipes**, returning
`ErrWaitDelay`.

It exists because **"the process exited" and "our reads finished" are
different events**. A grandchild that inherited stdout keeps the write end
open after the child is dead, so a naive "read to EOF, then wait" hangs
forever on a process that has already exited. Every `ssh -f`, every
double-forking daemon, every `npm` that leaves a watcher behind, hits it.

Our equivalent: after `EXITED`, allow at most `grace_ms` more of draining,
then **close our own read ends** and answer with what we have plus
`TRUNCATED`. Without this the one-shot has an unbounded hang, and it is not
a hang the caller can diagnose.

---

## 5. ENVIRONMENT

### 5.1 Allow-list, never inherit

`envp == NULL` means **empty**, not `environ`. The Avra layer builds the
child's environment from an explicit allow-list of *names*, copying values
from our own environment only for names on the list.

Sensible default allow-list: `HOME`, `USER`, `LOGNAME`, `SHELL`, `TMPDIR`,
`TZ`, `TERM` (only when a terminal is intended), plus a `PATH` the caller
sets explicitly.

### 5.2 Never inherit by default

**Dynamic loader — arbitrary code execution in the child:**
`LD_PRELOAD`, `LD_LIBRARY_PATH`, `LD_AUDIT`, `LD_ORIGIN_PATH`,
`LD_ASSUME_KERNEL`, `GLIBC_TUNABLES`;
`DYLD_INSERT_LIBRARIES`, `DYLD_LIBRARY_PATH`, `DYLD_FRAMEWORK_PATH`,
`DYLD_FALLBACK_LIBRARY_PATH`, `DYLD_FALLBACK_FRAMEWORK_PATH`,
`DYLD_ROOT_PATH`, `DYLD_SHARED_REGION`.
*(Nuance worth stating: dyld strips `DYLD_*` for hardened-runtime,
SIP-protected and set-uid targets, and glibc ignores `LD_PRELOAD` for
set-uid — so these only subvert **ordinary** binaries. Which is nearly
everything we will spawn.)*

**Shell — changes what a script means:**
`IFS`, `ENV`, `BASH_ENV`, `PS4`, `SHELLOPTS`, `BASHOPTS`, `CDPATH`,
`GLOBIGNORE`, `BASH_FUNC_*` (Shellshock's carrier), `POSIXLY_CORRECT`.

**Language runtimes — silently inject code or change resolution:**
`PYTHONPATH`, `PYTHONHOME`, `PYTHONSTARTUP`, `PERL5LIB`, `PERL5OPT`,
`RUBYOPT`, `RUBYLIB`, `NODE_OPTIONS`, `NODE_PATH`, `GEM_PATH`, `CLASSPATH`,
`JAVA_TOOL_OPTIONS`, `_JAVA_OPTIONS`, `LUA_PATH`, `R_HOME`.

**Tooling that changes behaviour invisibly:**
`GIT_SSH`, `GIT_SSH_COMMAND`, `GIT_CONFIG`, `GIT_CONFIG_GLOBAL`, `GIT_DIR`,
`GIT_EXTERNAL_DIFF`, `EDITOR`, `VISUAL`, `PAGER`, `http_proxy`,
`https_proxy`, `all_proxy`, `NO_PROXY`, `MALLOC_*`, `MallocStackLogging`,
`NSUnbufferedIO`.

**Ambient authority — the one people forget:** `SSH_AUTH_SOCK` hands the
child your agent's signing capability; `GPG_AGENT_INFO` likewise;
`DOCKER_HOST` is root on the box.

**Secrets that leak by accident:** `AWS_*`, `GITHUB_TOKEN`, `*_API_KEY`,
`*_TOKEN`, `*_SECRET`.

An allow-list is the only design where you never have to keep this list
current. A deny-list is a treadmill.

### 5.3 Locale

`LC_ALL`, `LC_CTYPE`, `LC_COLLATE`, `LC_NUMERIC`, `LC_TIME`, `LC_MESSAGES`,
`LANG`, `LANGUAGE`, `LC_ALL_CJK`… all change the child's *output*:

- messages are translated — `git`'s `fatal:` becomes `schwerwiegend:`, and
  every regex that parses tool output breaks;
- `sort` orders by collation, not bytes (`LC_COLLATE=en_US.UTF-8` makes
  `sort` case-insensitive and ignores punctuation);
- `LC_NUMERIC` makes `printf`/`awk` emit `3,14`;
- `LC_TIME` reformats `ls -l` and `date`;
- `[a-z]` in `sed`/`tr` means a different set.

**Rule:** if the parent *parses* the output, set `LC_ALL=C` and `LANG=C`. If
the output is for a *human*, pass the user's locale through. These are
different cases and the API should force the choice rather than pick.
`C.UTF-8` (byte-safe collation plus UTF-8 ctype) exists on glibc ≥ 2.35 —
**not on Darwin**, which has `C` and `en_US.UTF-8` and nothing between.

---

## 6. SANDBOXING A CHILD — survey

### Linux

- **Landlock** (5.13, ABI v1; v2 5.19 refer; v3 6.2 truncate; v4 6.7 TCP;
  v5 6.10 ioctl_dev). `landlock_create_ruleset` → `landlock_add_rule` →
  `landlock_restrict_self`. *"Every new thread resulting from a clone(2)
  inherits Landlock domain restrictions from its parent"*; the restriction
  *"is a one-way ratchet, inherited by children. Once applied, it cannot be
  loosened"*, **including across `execve`**
  ([landlock](https://docs.kernel.org/userspace-api/landlock.html)).
  Requires `CAP_SYS_ADMIN` **or** `prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0)`
  first. So a parent *can* honestly bound a child's filesystem authority —
  but `restrict_self` must run in the child, i.e. **fork+exec, not
  posix_spawn**.
- **seccomp**: `seccomp(SECCOMP_SET_MODE_FILTER, ...)` or
  `prctl(PR_SET_SECCOMP, SECCOMP_MODE_FILTER, ...)`; also needs
  `no_new_privs` without `CAP_SYS_ADMIN`; survives `execve` and is
  inherited. cBPF sees the syscall number and register arguments only — it
  **cannot dereference pointers**, so it can never filter by path. Good for
  "no network", "no ptrace", "no new namespaces".
- **`no_new_privs`** (3.5+) is the enabling primitive for both, is itself
  inherited, and is irreversible
  ([no_new_privs](https://docs.kernel.org/userspace-api/no_new_privs.html)).

### Darwin

- `sandbox_init(const char *profile, uint64_t flags, char **errorbuf)` in
  `<sandbox.h>` — **deprecated in headers since 10.8**, still shipping,
  still used internally by Apple. The SBPL profile language has never been
  publicly documented. It applies to the **calling** process, so restricting
  a child means calling it between fork and exec (again: not posix_spawn);
  and once a parent is sandboxed a child cannot re-init its own.
  `sandbox-exec(1)` is the CLI wrapper, likewise deprecated, with no
  documented replacement outside App Sandbox entitlements — which require
  code signing and are unavailable for an arbitrary spawned binary
  ([apple/containerization#737](https://github.com/apple/containerization/issues/737)).
- **What a parent can honestly guarantee about a child on Darwin today:**
  exactly five things —
  1. the file descriptors it hands over (`CLOEXEC_DEFAULT` makes this a real
     guarantee, not a hope),
  2. the environment it hands over,
  3. the working directory,
  4. the process group / session,
  5. resource limits set before exec (`setrlimit` — which needs a fork+exec
     hook, since posix_spawn has no rlimit attribute).

  Everything else remains: the entire filesystem readable by the user, the
  network, other processes owned by the user, the keychain (with a prompt),
  and `SSH_AUTH_SOCK` if it was leaked. **There is no supported, documented,
  non-entitlement way to say "this child may read only /tmp".** Anything
  stronger means a VM (Virtualization.framework, Apple's `container`) or the
  deprecated SBPL. State this in the docs; do not imply otherwise.

### FreeBSD

- **Capsicum**: `cap_enter()` enters capability mode — no global namespace,
  only operations on descriptors. *"Capability mode is inherited across fork
  and exec"*; `execve` is disabled in favour of `fexecve(2)`, and
  process management moves to `pdfork(2)`
  ([cap_enter(2)](https://man.freebsd.org/cgi/man.cgi?query=cap_enter)).
  The child must be *written* for it. This is the model everyone else
  approximates.

### Fuchsia — the ideal

No ambient authority at all. A process is **constructed** from handles: the
`fuchsia.process.Launcher` service is handed the job, the executable VMO,
and a bootstrap message of named handles; `fdio_spawn`/`fdio_spawn_etc` is
the convenience frontend
([process creation](https://fuchsia.dev/fuchsia-src/concepts/process/process_creation)).
"Inherit" is not a concept — a child has exactly the handles it was given.

**The lesson we can steal without the kernel:** make the fd set, the
environment, and the cwd **explicit and default-empty**. That is precisely
what `POSIX_SPAWN_CLOEXEC_DEFAULT` plus an env allow-list buy: a
capability-shaped API over an ambient-authority OS. It is also why v1
exposes *no* sandbox knobs but shapes `spawn` to take a policy bag rather
than a pile of positional booleans — the day Landlock or SBPL lands, it
brings a fork+exec path, and the surface should not have to change.

---

## 7. THE PROPOSED SURFACE — 12 C functions

### 7.1 What the seam permits

`RtKind` is `I64 | Ptr | Void`
(`packages/std-avrac/src/core/ir.av:216`). Every parameter and result is an
`int64_t` or a pointer. No structs, no bools, no floats cross the seam.

Consequence: a spawn cannot *answer* a pid plus three fds. **So C keeps a
handle table** and Avra holds one `int64_t`. That single decision is what
gets the count to 12 and makes ownership trivial.

### 7.2 The functions

```c
/* ── construction ───────────────────────────────────────────── */

/*  1 */ int64_t     avra_proc_spawn(const char* file, void* argv, void* envp,
                                     const char* cwd, int64_t flags);
/*      >=0 : handle.  <0 : -errno (ENOENT, EACCES, E2BIG, EMFILE, ENOMEM…) */

/*  2 */ int64_t     avra_proc_run(const char* file, void* argv, void* envp,
                                   const char* cwd, int64_t flags,
                                   const char* stdin_text,
                                   int64_t timeout_ms, int64_t grace_ms,
                                   int64_t max_bytes);
/*      the ONE-SHOT: spawn + pump + escalate + reap.  >=0 : a finished
        handle whose buffers hold everything and whose status is final.
        <0 : -errno from the spawn.                                        */

/* ── streaming (only for the 10% that needs it) ─────────────── */

/*  3 */ int64_t     avra_proc_poll(int64_t h, int64_t timeout_ms);
/*      one pump tick.  >=0 : an event bitset.  <0 : -errno.               */

/*  4 */ int64_t     avra_proc_write(int64_t h, const char* bytes, int64_t len);
/*      >=0 : bytes accepted.  -EAGAIN would block.  -EPIPE child closed.  */

/*  5 */ int64_t     avra_proc_stdin_close(int64_t h);       /* 0 | -errno */

/*  6 */ const char* avra_proc_take(int64_t h, int64_t stream);
/*      stream 1 = stdout, 2 = stderr.  Everything buffered since the last
        take, as a FRESH owned box; "" when nothing.  Never NULL.          */

/* ── control & identity ─────────────────────────────────────── */

/*  7 */ int64_t     avra_proc_signal(int64_t h, int64_t sig, int64_t to_group);
/*      0 | -errno.  -ESRCH once reaped (the pid-reuse guard).             */

/*  8 */ int64_t     avra_proc_status(int64_t h);   /* the §3.7 tagged word */

/*  9 */ int64_t     avra_proc_pid(int64_t h);      /* -1 once reaped       */

/* 10 */ void        avra_proc_close(int64_t h);
/*      SIGKILL the group if still alive, blocking waitpid, close fds,
        free buffers, bump the handle generation.  Idempotent.             */

/* ── queries ────────────────────────────────────────────────── */

/* 11 */ const char* avra_proc_which(const char* file, const char* path);
/*      §1.5 resolution as a query; "" when nothing resolves. Owned box.   */

/* 12 */ const char* avra_proc_error_text(int64_t err);
/*      strerror(-err) as an IMMORTAL box.  errno stays the value; text is
        only its projection.                                               */
```

If a 10-function build is wanted, `avra_proc_pid` and `avra_proc_which` are
the two to shed (both are observability, not capability), and
`avra_proc_error_text` naturally generalizes to a shared `avra_errno_text`
the day `@std/fs` lands.

### 7.3 Flags and events

```c
/* spawn flags */
#define AVRA_PROC_PIPE_IN      0x0001
#define AVRA_PROC_PIPE_OUT     0x0002
#define AVRA_PROC_PIPE_ERR     0x0004
#define AVRA_PROC_MERGE_ERR    0x0008  /* stderr -> the stdout description  */
#define AVRA_PROC_NULL_IN      0x0010
#define AVRA_PROC_NULL_OUT     0x0020
#define AVRA_PROC_NULL_ERR     0x0040
#define AVRA_PROC_INHERIT_IN   0x0080  /* our fd 0 — never set O_NONBLOCK   */
#define AVRA_PROC_INHERIT_OUT  0x0100
#define AVRA_PROC_INHERIT_ERR  0x0200
#define AVRA_PROC_NEW_PGROUP   0x0400
#define AVRA_PROC_NEW_SESSION  0x0800
#define AVRA_PROC_SEARCH_PATH  0x1000  /* else `file` must contain '/'      */

/* poll / run event bits */
#define AVRA_PROC_EV_OUT        0x001
#define AVRA_PROC_EV_ERR        0x002
#define AVRA_PROC_EV_OUT_EOF    0x004
#define AVRA_PROC_EV_ERR_EOF    0x008
#define AVRA_PROC_EV_IN_WROTE   0x010
#define AVRA_PROC_EV_IN_CLOSED  0x020
#define AVRA_PROC_EV_EXITED     0x040
#define AVRA_PROC_EV_TIMEOUT    0x080
#define AVRA_PROC_EV_CAPPED     0x100  /* max_bytes hit; output truncated   */
#define AVRA_PROC_EV_TERMED     0x200  /* we sent SIGTERM                   */
#define AVRA_PROC_EV_KILLED     0x400  /* we sent SIGKILL                   */
```

Conflicting fd flags (`PIPE_IN | NULL_IN`) answer `-EINVAL`. Never guess.

### 7.4 How `List<string>` crosses

`argv` and `envp` are `void*` pointing at `AvraArray` boxes whose slots hold
boxed `char*` (pushed by the compiler via `avra_array_push_owned`). C reads
them with the existing vocabulary:

```c
int64_t n = avra_array_len(argv);
for (int64_t i = 0; i < n; i++) {
    const char* s = (const char*)(uintptr_t)avra_array_get(argv, i);
    cargv[i] = strdup(s);           /* our copy; the box is borrowed  */
}
cargv[n] = NULL;                    /* the NULL terminator is OURS    */
```

Use `avra_array_get`, **not** `avra_array_get_owned` — the latter retains,
and we are borrowing for the duration of one call. `envp` is the same, each
string being `"KEY=VALUE"`; a string without `'='` is `-EINVAL`.

`envp == NULL` means an **empty** environment. There is no "inherit" spelling
at the C seam — inheritance is an Avra-level allow-list policy.

### 7.5 Ownership — every pointer

| pointer | owner | who frees |
|---|---|---|
| `file`, `cwd`, `stdin_text`, `bytes`, `path` | **caller (Avra)** | Avra's memory pass. C copies what it needs and touches no refcount. |
| `argv`, `envp` arrays and their string slots | **caller (Avra)** | Avra. C reads within the call only; never retains, never releases. |
| the `char**` vectors C builds | **C** | C, before returning from `spawn`/`run` — on **every** path, including errors. |
| result of `avra_proc_take`, `avra_proc_which` | **Avra** | the memory pass — the row carries `owns_result: true`. Allocated with `box_alloc(n + 1, KIND_PLAIN)`. |
| result of `avra_proc_error_text` | nobody | `str_static` — immortal, `owns_result: false`. |
| pid, fds, buffers, the handle slot | **C** | `avra_proc_close`. Avra owns only the integer. |

**The header law applies without exception** (CLAUDE.md: *EVERY POINTER AVRA
HOLDS CARRIES A HEADER*). No `strdup` result and no C string literal may
ever reach Avra: `box_alloc`/`str_owned` for owned text, `str_static` for
immortal text. A raw `malloc`'d buffer handed back would be read by
`avra_rc_retain` as memory that is not ours.

### 7.6 Errors

`-errno`, never a sentinel string, never `127`. Every negative answer is a
real `errno` value negated, so the Avra side is one projection:

```avra
fn ok(n: int) -> bool { n >= 0 }
fn err_of(n: int) -> int { 0 - n }
```

A bad handle answers `-EBADF`; an out-of-range or stale-generation handle
answers `-EINVAL`. **Never trap** on a bad handle: a trap inside the pump
leaves a live child and open fds behind, and the runtime's trap contract
exits immediately.

### 7.7 Should the one-shot live in C or in Avra?

The interesting finding is that the usual parity argument does not apply here.

`packages/std-avrac/src/language/interp.av:503-546` — `rt_dispatch` looks up
`rt_sig_of(callee)` **first**, and only falls through to the externs table
if there is no row. An extern with no row traps: *"`X` is extern — the
evaluator cannot host it; build natively."* So:

- **A process fn declared `extern fn` in Avra AND added as an `rt_sigs()`
  row with a new `RtHost.Proc*` host gets an interpreter arm.** That arm
  cannot re-implement spawning in Avra — it must call the same C. The arms
  are thin passthroughs, and **eval == native holds by construction, because
  there is exactly one implementation**, not two that agree.
- Therefore parity does not push work into Avra. What it pushes for is
  **fewer functions**, because each row costs an `RtHost` variant plus an
  exhaustive arm. That is the real reason for the ≤12 budget.
- **Performance is irrelevant to the choice.** A spawn is ~1 ms; the seam is
  ~100 ns. Neither placement is measurable.

So the decision is made on **correctness**, and it lands on C:

1. The pump has three ways to hang (forget stderr, reap before draining,
   fail to recompute the poll timeout) and one way to corrupt (splitting
   UTF-8 per chunk). **P1 says the 90% path must be right on first
   generation** — so it must not be a loop anybody writes. Put the loop
   behind `avra_proc_run`.
2. **Decisive:** Avra's string is a NUL-terminated `char*`. The box `Header`
   is `{ uint32_t tag; int32_t kind; int64_t rc; }`
   (`runtime/avra_runtime.c:50-54`) — **there is no length field**. A
   byte-level drain loop written in Avra could not carry a chunk containing
   a NUL. The pump must live where lengths exist: C.

What lives in Avra, over the same primitives — real dogfooding, zero parity
cost:

- argv assembly and validation;
- the environment allow-list and the locale decision;
- flag composition (`Cmd.pipe_out().merge_err().timeout(5s)`);
- decoding the §3.7 status word into `enum Exit`;
- incremental line splitting of already-captured text;
- retry / backoff / logging policy.

And `avra_proc_run` must be written as a plain C caller of the *same*
internal spawn/pump/wait helpers the individual primitives use — one pump,
not two.

**Residual honesty:** `avra_proc_take` answers NUL-terminated text, so a
child emitting NUL bytes truncates at the first one. v1's answer is (a)
document it, (b) route binary output to a file through the fd plan. A future
`avra_proc_take_bytes` answering a `List<int>`, or a length-carrying blob
value category, is a **core** event (a new value category) and belongs in
the ROADMAP's sugar backlog, not in v1's twelve.

---

## 8. THE PITFALL LEDGER

### Spawn

1. **`system()` blocks SIGCHLD and ignores SIGINT/SIGQUIT for the whole
   call.** → Delete `avra_shell_exec_status`. Never take a command string.
2. **`system()`'s 127 is ambiguous three ways** (shell not found / command
   exited 127 / fork failed folded to 127). → Handle-based API; spawn errors
   are `-errno`, statuses are tagged (§3.7).
3. **`128 + signum` collides with real exit codes** (137 vs SIGKILL). →
   The tagged `int64_t`; never the shell convention.
4. **`fork()` cost scales with the parent's address space.** → `posix_spawn`.
5. **Hand-rolled `vfork`/`CLONE_VFORK` shares memory with a suspended
   parent.** → `posix_spawn` (glibc already uses it internally).
6. **Between fork and exec only async-signal-safe calls are legal** — a
   refcounted runtime's `malloc` is not. → No pre-exec hook in v1; when one
   arrives it may not run Avra code.
7. **`posix_spawnp` searches the *parent's* `PATH`, not the child's
   `envp`.** → Resolve ourselves; call `posix_spawn`.
8. **On Darwin, `posix_spawnp` resolves the program against the *parent's*
   cwd even with a chdir file action.** → Resolve to an absolute path first,
   so chdir order stops mattering.
9. **An empty `PATH` element (leading/trailing/doubled `:`) means `.`; an
   absent `PATH` historically meant `.` first.** → Skip empty and
   non-absolute elements; `-ENOENT` when `PATH` is absent; never
   `confstr(_CS_PATH)`.
10. **Resolving before spawn is a TOCTOU.** → Unavoidable on Darwin (no
    `fexecve`, no by-fd `posix_spawn`). Document it; prefer absolute program
    paths; `SEARCH_PATH` is opt-in.
11. **`POSIX_SPAWN_CLOEXEC_DEFAULT` vanishes under `-D_POSIX_C_SOURCE`** —
    it lives inside `#if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)`.
    → Compile the process TU with `_DARWIN_C_SOURCE` (or no
    `_POSIX_C_SOURCE`) and `#ifdef`-guard the flag.
12. **Linux has no atomic CLOEXEC_DEFAULT.** → `O_CLOEXEC` at birth for
    every fd the runtime creates, plus `close_range(3, ~0U,
    CLOSE_RANGE_CLOEXEC)` before spawn (Linux 5.11 for the flag, 5.9 for the
    call, glibc 2.34 for the wrapper; `syscall()` otherwise, `ENOSYS` = skip).
13. **Never `for (i=3; i<_SC_OPEN_MAX; i++) close(i)`** — a million syscalls
    per spawn under a raised `RLIMIT_NOFILE`. → `close_range`, else
    `/proc/self/fd`.
14. **Darwin has no `pipe2`.** *(SDK-verified.)* → `pipe()` + two
    `fcntl(F_SETFD, FD_CLOEXEC)`; harmless while single-threaded, a real
    race once the M:N runtime spawns from two threads. Record it now.
15. **A pipe fd may come back as 0/1/2** when the runtime was started with a
    closed standard descriptor. `adddup2(n, n)` then depends on a POSIX TC
    clarification. → `dup` every pipe fd above 2 before building file
    actions.
16. **The parent must close its copies of the child's pipe ends right after
    spawn**, or stdout EOF never arrives and the child never sees stdin EOF.
17. **The child inherits our signal mask.** → `POSIX_SPAWN_SETSIGMASK` with
    an empty set, always. Critical once the scheduler blocks SIGCHLD.
18. **`execve` resets *caught* handlers but leaves `SIG_IGN` ignored** — so
    our ignored SIGPIPE infects every child. → `POSIX_SPAWN_SETSIGDEF` with
    every catchable signal (build the set explicitly; exclude SIGKILL/SIGSTOP).
19. **`posix_spawn_file_actions_addchdir_np` does not exist everywhere**
    (glibc 2.29+, macOS 10.15+ and renamed at macOS 26.0, absent on musl and
    the BSDs). → `dlsym` both names, cache; fall back to
    `open(".")`/`chdir`/`fchdir` **only while single-threaded**.
20. **`POSIX_SPAWN_SETSID` gives the child no controlling terminal** — it can
    never prompt for a password. → Not a default; daemon-shaped spawns only.
21. **`POSIX_SPAWN_SETPGROUP` removes the child from the terminal's
    foreground group**, so interactive Ctrl-C stops reaching it. → A flag the
    caller chooses, with the trade-off documented.
22. **`E2BIG` depends on the user's `ulimit -s`** (Linux: 32 pages per
    string, total ≤ ¼ of the stack limit; Darwin: `KERN_ARGMAX`). → Report
    `-E2BIG` plainly; chunk long argv in the caller.
23. **Never `POSIX_SPAWN_SETEXEC`** — on Darwin it makes `posix_spawn`
    *replace* the calling process.

### I/O

24. **Reading one pipe while the child fills the other deadlocks** (64 KiB on
    Linux). → stdout, stderr and pending-stdin always in one `poll` set.
25. **Writing more than a pipe buffer to stdin without draining output
    deadlocks.** → Same set; non-blocking writes with an offset.
26. **Reaping before draining truncates output** — data outlives the child in
    the pipe. → Drain to EOF on both, *then* reap.
27. **Exit ≠ EOF.** A grandchild holding the write end keeps the pipe open
    forever (`ssh -f`, daemonizers). → A WaitDelay-style bound after
    `EXITED`; then close our read ends and flag `TRUNCATED`.
28. **EOF ≠ exit.** A child may close its fds and keep running. → Both
    conditions before "done".
29. **`O_NONBLOCK` on an *inherited* fd leaks to the terminal and the
    invoking shell.** → Only ever set it on pipe ends we created.
30. **Partial reads split lines and UTF-8 sequences.** → Buffer bytes; split
    lines with a retained tail; never decode per chunk.
31. **`EINTR` on `poll`/`read`/`write`.** → Retry, always.
32. **Retrying `poll` after `EINTR` with the *original* timeout makes the
    deadline unreachable.** → Recompute from a `CLOCK_MONOTONIC` deadline
    every iteration.
33. **Writing to a dead child's stdin kills us with SIGPIPE.** →
    `signal(SIGPIPE, SIG_IGN)` at runtime init; treat `EPIPE`/`POLLERR` on
    stdin as a normal "child closed stdin", not an error.
34. **Interleaving between two pipes is not recoverable, and read-time
    timestamps are fiction.** → Offer a true `MERGE` (one description via two
    `adddup2`s); document that even merged output is distorted by the
    *child's* stdout block-buffering.
35. **Unbounded output exhausts memory before any timeout fires.** →
    `max_bytes`, with a `CAPPED` event and escalation.
36. **pty EOF is `EIO` on Linux and `0` on Darwin**, ECHO is on by default,
    ONLCR injects `\r`, and `isatty()` changes the child's behaviour. → No
    pty in v1; a later `spawn_pty` on the fork+exec path.

### Waiting

37. **`signal(SIGCHLD, SIG_IGN)` / `SA_NOCLDWAIT` make `waitpid` fail with
    `ECHILD`** and silently destroy every exit status. → Never set them.
38. **Reaping twice, or signalling after a reap, can hit a recycled pid.** →
    Reap exactly once; set `pid = -1` at the reap; `avra_proc_signal` answers
    `-ESRCH` on a reaped handle.
39. **A reused *handle* integer is the same bug one level up.** → Generation
    counter in the handle's high bits.
40. **A handle closed without a wait leaves a zombie.** → `avra_proc_close`
    kills the group, blocks in `waitpid`, then frees.
41. **`PR_SET_PDEATHSIG` is per-*thread*, cleared by set-uid exec and by any
    credential change, racy if the parent already died, and needs a
    post-fork hook `posix_spawn` does not provide.** Darwin has no
    equivalent. → Do not promise parent-death cleanup. Offer a cooperative
    death-pipe for children we wrote; otherwise say plainly that orphans may
    outlive the runtime.
42. **`killpg` misses any descendant that called `setsid`/`setpgid`.** →
    Document the limit; do not imply containment.
43. **`WCOREDUMP` is not POSIX.** → `#ifdef WCOREDUMP`, report `false` when
    absent.
44. **Reaping inside a SIGCHLD handler is how the pid-reuse race becomes
    real.** → One waiter loop; a handler may only `write()` one byte to a
    self-pipe. Prefer pidfd (Linux 5.3+) / `EVFILT_PROC` `NOTE_EXIT` (Darwin)
    and no signal handling at all.

### Environment

45. **`envp == NULL` must mean *empty*, not `environ`.** → Inheritance is an
    explicit Avra-level allow-list.
46. **`LD_PRELOAD` / `DYLD_INSERT_LIBRARIES` and friends are arbitrary code
    execution in the child.** → Allow-list, never deny-list. (And note that
    dyld/glibc strip them only for hardened/set-uid targets — i.e. not for
    the binaries we actually spawn.)
47. **`IFS`, `BASH_ENV`, `ENV`, `CDPATH`, `BASH_FUNC_*` change what a script
    means**; `PYTHONPATH`, `NODE_OPTIONS`, `PERL5OPT`, `RUBYOPT`,
    `JAVA_TOOL_OPTIONS` inject code into interpreters. → Same allow-list.
48. **`SSH_AUTH_SOCK` / `GPG_AGENT_INFO` / `DOCKER_HOST` hand over ambient
    authority**, and `AWS_*` / `*_TOKEN` leak secrets. → Same allow-list.
49. **Locale changes the child's output** — translated messages, collation
    order, `3,14`, reformatted dates, different `[a-z]`. → `LC_ALL=C` when
    parsing; pass through when the output is for a human; make the API force
    the choice. `C.UTF-8` exists on glibc ≥ 2.35 and **not** on Darwin.

### The seam

50. **Any pointer handed to Avra without a 16-byte header is memory
    `avra_rc_retain` must not touch.** → `box_alloc`/`str_owned` for owned
    answers, `str_static` for immortal ones; never `strdup`, never a C
    literal.
51. **`avra_array_get_owned` retains; `avra_array_get` does not.** → Borrow
    argv/envp with `avra_array_get`; never release what we did not retain.
52. **The C argv/envp vectors leak on every error path** if freed only on
    success. → One `cleanup:` label; free on every exit.
53. **An `extern fn` with no `rt_sigs()` row traps in the IR evaluator**
    (`interp.av:544`) — `avra run` would refuse every program that spawns. →
    Add a `RtHost.Proc*` variant and an arm per exported fn; the arm calls
    the same C, so eval == native by construction.
54. **Avra strings are NUL-terminated with no length in the header** — a
    child emitting NUL truncates the captured text at the first zero byte. →
    Document it; route binary through a file redirect; a bytes value category
    is a core event for the backlog, not for v1.
55. **A trap inside the pump leaves a live child and open fds.** → Bad
    handles answer `-EBADF`/`-EINVAL`; the process substrate never traps.

---

## Sources

- [posix_spawn(3) — man7](https://man7.org/linux/man-pages/man3/posix_spawn.3.html)
- [Apple posix_spawn(2)](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/posix_spawn.2.html)
- [gnulib: posix_spawn_file_actions_addchdir_np](https://www.gnu.org/software/gnulib/manual/html_node/posix_005fspawn_005ffile_005factions_005faddchdir_005fnp.html)
- [glibc 2.29 NEWS (bug 17405)](https://sourceware.org/bugzilla/show_bug.cgi?id=17405)
- [libuv#1483 — POSIX_SPAWN_CLOEXEC_DEFAULT](https://github.com/joyent/libuv/issues/1483)
- [cpython#109154 — CLOEXEC_DEFAULT + addinherit_np](https://github.com/python/cpython/issues/109154)
- [zed#55672 — posix_spawnp resolves against the parent's cwd on macOS](https://github.com/zed-industries/zed/pull/55672)
- [rust#131851 — dlsym addchdir_np on musl](https://github.com/rust-lang/rust/pull/131851)
- [rust#87764 — fork cost with large heaps](https://github.com/rust-lang/rust/issues/87764)
- [close_range(2)](https://man7.org/linux/man-pages/man2/close_range.2.html)
- [pidfd_open(2)](https://man7.org/linux/man-pages/man2/pidfd_open.2.html)
- [PR_SET_PDEATHSIG(2const)](https://man7.org/linux/man-pages/man2/PR_SET_PDEATHSIG.2const.html)
- [execve(2)](https://man7.org/linux/man-pages/man2/execve.2.html)
- [exec(3) — PATH defaults](https://man7.org/linux/man-pages/man3/exec.3.html)
- [pipe(7)](https://man7.org/linux/man-pages/man7/pipe.7.html)
- [system(3)](https://man7.org/linux/man-pages/man3/system.3.html)
- [openpty(3)](https://man7.org/linux/man-pages/man3/openpty.3.html)
- [Go os/exec — ErrDot, WaitDelay, Cancel](https://pkg.go.dev/os/exec)
- [Landlock — kernel docs](https://docs.kernel.org/userspace-api/landlock.html)
- [no_new_privs — kernel docs](https://docs.kernel.org/userspace-api/no_new_privs.html)
- [cap_enter(2) — FreeBSD](https://man.freebsd.org/cgi/man.cgi?query=cap_enter)
- [Fuchsia process creation](https://fuchsia.dev/fuchsia-src/concepts/process/process_creation)
- [apple/containerization#737 — sandbox-exec deprecation](https://github.com/apple/containerization/issues/737)
- [Way too many ways to wait for a child process with a timeout](https://gaultier.github.io/blog/way_too_many_ways_to_wait_for_a_child_process_with_a_timeout.html)
- Local, read directly: `MacOSX.sdk/usr/include/spawn.h`, `sys/spawn.h`,
  `unistd.h`, `sys/fcntl.h`, `util.h`;
  `avra-lane-b/runtime/avra_runtime.c:20-100, 880-1015`;
  `packages/std-avrac/src/core/ir.av:216-266`;
  `packages/std-avrac/src/core/runtime_api.av`;
  `packages/std-avrac/src/language/interp.av:503-550`;
  `packages/std-avrac/src/features/fns/lower.av:6-45`
