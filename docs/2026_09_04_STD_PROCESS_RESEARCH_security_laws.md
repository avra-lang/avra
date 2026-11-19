# THE CHILD IS A FOREIGN PROGRAM — laws for `@std.process`

*Security research for Avra's subprocess library. Companion to
`2026_09_04_THE_ROOT_IS_THE_ONLY_DOOR.md`; same tier vocabulary, same honesty
discipline, same diagnostic shape. Read-only research — nothing was built or run.*

---

## Table of contents

- [Part 0 — The frame, and the one sentence](#part-0)
- [Part I — Injection taxonomy, and the design that deletes each](#part-i)
  - [I.1 Shell injection](#i1)
  - [I.2 ARGUMENT injection — the long section](#i2)
  - [I.3 Environment injection](#i3)
  - [I.4 cwd / PATH hijacking](#i4)
  - [I.5 Option/filename confusion, NUL, argv[0]](#i5)
  - [I.6 The non-injection classics a process API must also delete](#i6)
- [Part II — The authority model: mint, narrow, audit](#part-ii)
- [Part III — Backward projections](#part-iii)
- [Part IV — The child's environment as contract](#part-iv)
- [Part V — The build machine](#part-v)
- [Part VI — THE LAWS](#part-vi)
- [Part VII — Honest limits, per tier](#part-vii)
- [Part VIII — Confidence ledger](#part-viii)
- [Sources](#sources)

---

<a name="part-0"></a>
# Part 0 — The frame, and the one sentence

The fs doc split `string` into an **address** (`Rel`) and an **authority** (`Dir`) and
the paradox evaporated. Spawn has the same shape and one extra half.

> A command line is a `string` asked to be three things at once: **which program**
> (authority), **what to say to it** (address/data), and **what the program should
> read as an instruction** (grammar). Every language spells all three as text, so
> every language ships `shlex.quote`, an argv list, a denylist of dangerous flags,
> and a CVE feed.

Splitting gives four values, each at its true cost:

- **`Program`** — authority to execute one file. An fd, resolved once, before `main`.
  Unforgeable, unprintable-as-a-path, unsendable.
- **`Flag`** — a token the *tool* defined. Minted only from the tool's declared
  vocabulary. Data can never become one.
- **`Arg`** — inert bytes destined for one argv slot, carrying its **position kind**
  so the emitter knows the one form in which it cannot be re-read as a `Flag`.
- **`Dir` / `File`** — authority the child receives *as an open fd*, never as a path
  string the parent materialized.

And the sentence the whole document hangs on, which is also its central honest limit:

> **argv-as-a-list deletes the shell. It does not delete the injection.** The attacker
> stops writing `; rm -rf /` and starts writing `--upload-pack=`, and every argv-list
> library in the world hands that straight to `exec` with a clean conscience.

The tree's own ROADMAP (Lane 0, and the red team's open ledger item (1)) plans exactly
the argv-list fix for `avra build`. That fix is necessary, correct, and **step one of
five**. Part V says what the other four are.

---

<a name="part-i"></a>
# Part I — Injection taxonomy, and the design that deletes each

A summary table; each row is expanded below. "Deleted by" names the *law* from Part VI.

| # | Class | The classic shape | Deleted by |
|---|---|---|---|
| 1 | Shell injection | `system("clang " + flags)` | **L1** — no expression produces a shell |
| 2 | **Argument injection** | attacker word starts with `-` | **L3** — position law + declared vocabularies |
| 3 | Env injection | `LD_PRELOAD`, `BASH_ENV`, `GIT_SSH_COMMAND` | **L5** — inherit nothing unnamed |
| 4 | PATH / cwd hijack | relative exe, `.` in PATH, Windows cwd search | **L2** — one resolution, before `main` |
| 5 | Option/filename confusion | a file literally named `-rf` or `-` | **L3** — `Rel` emits as `./name` |
| 6 | NUL in argv | `"a\0--upload-pack=x"` truncates | **L4** — the widening refuses NUL |
| 7 | argv[0] spoofing / `argc == 0` | PwnKit | **L5** — argv[0] is the `Program`'s |
| 8 | Path-to-child TOCTOU | absolute string + attacker-chosen window | **L6** — a `Rel` under a handed-over `Dir` |
| 9 | Ignored status / deadlock / orphans | `wait()` on a full pipe | **L7** — discharge law |
| 10 | Silent capability widening | a dep bump adds a spawnable program | **L8** — projection law + `avra caps diff` |

---

<a name="i1"></a>
## I.1 Shell injection — the easy one, and why it is still open here

`system(3)`, `sh -c`, `shell=True`, backticks. Well understood; the fix is universally
known and universally re-broken, because **the shell is the easiest thing to reach for
and every stdlib puts it one character away.**

Avra's tree has it live today, and the source comment states the false premise out
loud (`packages/cli/src/commands/shared.av:180`, `:206`):

```avra
if avra_shell_exec_status("clang -w -O1 ${shell_word(ll_path)} build/avra_runtime.o ${promised} -o ${shell_word(out)}") != 0 {

/// … Declared flags are NOT quoted: a `[link]` row is
/// the project's own word, and may be a flag rather than a path.
fn promises(p: Program) -> string {
    joined([expanded(f) for f in link_inputs(p.ws)], " ")
}
```

`link_inputs` walks **every package in the workspace**, so "the project's own word" is
false for every transitive dependency. `runtime/avra_runtime.c:978` is `system(cmd)`.

**The design that deletes it:** there is no verb in the language that takes a command
*string*. `avra_shell_exec_status` is replaced by `avra_spawn_status(prog_fd, argv,
envp, actions)`. A shell, if you truly want one, is a declared `[process.tools]` row
named `sh` whose first argument is `-c` — which makes it **greppable, counted, printed
by `avra explain process`, and diffed by `avra caps diff`**. The hatch exists (P8); it
is never the default and never invisible.

The subtlety worth stating, because it is the whole reason argv-lists get oversold:
once you have argv-lists, `shell_word` and the quoting in `test.av` must be **deleted,
not kept as belt-and-braces**. Fencing that survives the structural fix is fencing that
will be trusted again the next time someone builds a string.

---

<a name="i2"></a>
## I.2 ARGUMENT injection — the long section

### The shape

No shell is involved. The wrapper builds a clean argv array and calls `execve`
directly. The *callee* then parses one of those arguments as an option, because it
starts with a dash. CWE-88.

```
git clone <attacker-url> /tmp/dest
        → attacker-url = "--upload-pack=touch /tmp/pwn"
```

Sonar's catalogue lists, for code execution alone: `chrome`, `env`, `git-blame`,
`git-clone`, `git-diff`, `git-fetch`, `git-grep`, `git-ls-remote`, `hg`, `psql`,
`qt5`, `ssh`, `tar`, `zip`; for file write: `git-archive`, `git-log`, `sendmail`; for
file read: `git-tag`. The exact payloads it publishes:

- **git**: `git clone '-u$({touch,/tmp/foo})' ':x'` — the vector *needs a second
  positional argument*, which is why "the attacker only controls one field" is not a
  defence.
- **tar**: `--checkpoint=1 --checkpoint-action=exec="sh shell.sh"` — needs two
  injected arguments plus a positional.
- **ssh / rsync**: `-oProxyCommand=…` and `-e` are legitimate features weaponised by
  attacker-controlled hostnames and filenames.
- **curl**: `-K/--config` reads a config file that can set *any* option — so the
  injection can arrive through a file the attacker wrote, entirely past argv hygiene.
- **find**: `-exec` is a positional predicate; `find` has no end-of-options marker at
  all.

Historic instances (from the `--end-of-options` writeup; see the citation caveat in
Part VIII): CVE-2017-1000117 (git), CVE-2017-1000116 (Mercurial), CVE-2017-9800
(Subversion), CVE-2017-12836 (CVS) — all `ssh://` hostnames beginning `-oProxyCommand=`;
CVE-2019-13139 (`docker build`, URL fragment → `--upload-pack`); and a run of package
managers: CVE-2021-43809 (Bundler), CVE-2022-24828 (Composer), CVE-2023-5752 (pip),
CVE-2025-68119 (Go).

### Why the four obvious fixes are each insufficient

**(a) argv-as-a-list.** Deletes the shell metacharacter. Delivers `--upload-pack=…`
perfectly intact. *This is the most important sentence in this document.*

**(b) A denylist of dangerous options.** Verified, current, and exactly the wrong
shape: **CVE-2026-42215** (GitPython ≥3.1.30 <3.1.47, patched 3.1.47). GitPython
blocks `--upload-pack`, `--receive-pack`, `--exec`, `--config`. The advisory:

> "The vulnerable API paths check the raw kwarg names before they're … normalized into
> command-line flags"

so `remote.fetch(**{"upload-pack": helper})` is blocked and
`remote.fetch(upload_pack=helper)` **is allowed and reaches helper execution** — the
underscore normalises to a dash *after* the check. A denylist checked against the wrong
string is not a denylist. And a denylist is unbounded by construction: it must
enumerate every dangerous flag of every version of every tool, forever.

**(c) The `--` separator.** A *convention*, honoured by getopt-shaped tools, and:

- **git does not have it where it matters.** git repurposed `--` to separate revisions
  from pathspecs, so `git log "$rev"` with a dash-leading `$rev` still parses as an
  option. That is why `--end-of-options` was added in git 2.24 (Nov 2019) — and its
  support landed unevenly: `git rev-parse` needed 2.30.0, `git checkout` and `git
  reset` needed **2.43.1 (Feb 2024)**. A wrapper that emits `--` against git 2.28 is
  emitting a decoration.
- **`find` has no terminator.** Its arguments are a predicate grammar.
- **`dd` has no terminator** (`key=value` arguments).
- **`tar`'s old-style invocation** (`tar cf`) is not option-parsed at all.
- **`curl -K`** re-opens the option surface from inside a file.
- **And `--` is itself an injection primitive.** **CVE-2023-22809** (sudo 1.8.0 –
  1.9.12p1, Synacktiv): `sudoedit` tried to stop users passing extra editor arguments
  by scanning for spaces and quotes, and *failed to account for `--`*. `EDITOR='vim --
  /etc/sudoers'` appends an arbitrary file to the edit list → root. The mitigation
  shipped in sudoers is `env_delete+="SUDO_EDITOR VISUAL EDITOR"` — i.e. **give up on
  filtering and delete the input channel**, which is the lesson of this whole section.

**(d) Escaping.** Windows is the proof it cannot be done in general. **CVE-2024-24576**
("BatBadBut", Rust < 1.77.2, fixed 2024-04-09): `cmd.exe`'s parsing of `.bat`/`.cmd`
arguments defeated the standard library's escaper. The Rust team's own conclusion is
the design input:

> "Due to the complexity of `cmd.exe`, we didn't identify a solution that would
> correctly escape arguments in all cases" — so the fix "Changed the `Command` API to
> return an `InvalidInput` error when it cannot safely escape an argument."

**Refuse, never emulate** (Part VI escalation 4 of the fs doc), arrived at
independently by another language's security team, under duress.

### The design that deletes it — three tiers, all in one law

**T1 — THE POSITION LAW (mandatory, every tool, no configuration).**
An argv element built from *data* is emitted in the one form the callee cannot
re-read as an option:

| The data is… | Emitted as | Why it is safe |
|---|---|---|
| the value of a declared flag | **one** argv element `--flag=VALUE` | a fused value cannot open a new option; it is not a separate word |
| a path (`Rel`) | `./VALUE` | a relative path always accepts a `./` prefix; `-rf` becomes `./-rf`; `-` becomes `./-` (a real file, never stdin) |
| a bare non-path positional | verbatim, **and a leading `-` is refused at the widening** | see L4 |

`--flag=VALUE` and `./VALUE` are not hardening tricks; they are **total functions from
data to a non-option argv element**, and that is why they need no per-tool knowledge
and no version check. This tier alone kills every published payload in the Sonar
catalogue whose entry point is a *value* field.

**T2 — THE TERMINATOR IS DATA, NOT BEHAVIOUR** (the vocabulary seam rule: a per-tool
fact is a registry row, not a dispatch). The `[process.tools]` row declares it:

```toml
[process.tools]
git   = { at = "/usr/bin/git",  terminator = "--end-of-options", min = "2.43.1" }
tar   = { at = "/usr/bin/tar",  terminator = "--" }
find  = { at = "/usr/bin/find", terminator = "none" }
```

`terminator = "none"` is not a failure — it is an **honest declaration that T1 is the
only defence for this tool**, printed by `avra explain process`, and it makes a
positional-argument verb on that tool require the counted `@ambient_arg` hatch. `min`
is checked at seal time against `--version`, because a terminator the installed binary
does not implement is worse than no terminator: it is a *false* one.

**T3 — PER-TOOL ARGUMENT GRAMMARS (the deep tier, in a package, never in the language).**

```avra
use @std.process.git

let r = git.clone(url: remote, into: fs.work.dir(p"checkout"))?
```

Here `--upload-pack` is not *blocked* and not *denied* — it is **unspellable**, because
the only constructors of a `git clone` argv are the typed ones and `Flag` values are
minted only inside `@std.process.git`. This is the tier that answers the confused-deputy
limit in Part VII: `allow = ["git"]` is `allow = ["*"]` until a grammar constrains the
argv.

Two house rules on T3. It lives in a **package**, so the compiler never names a tool's
flags (the same reason the fs doc withdrew the hardcoded misnomer list from
`compiler/`). And its rows are **data** — a `table<ToolVerb>` — so adding `git fetch`
is a row, not a dispatch arm.

**T4 — `Untrusted<string>` (the fs doc's law, extended).** No verb in `@std.process`
takes an `Untrusted<T>`. The widenings are:

- `word()` — one argv element: refuses NUL, refuses empty, **refuses a leading `-`**.
- `flag_value(f)` — attaches to a declared `Flag`, emitting the fused single element.
  A leading `-` is *fine here*, and that is the point: the position makes it inert.
- `dash_word()` — the counted hatch, legal only after a declared terminator, greppable,
  and reported by `avra explain process`.

Note what falls out: the safe widening for a `-`-leading value is not "escape it", it
is "**move it to a position where a dash means nothing**". That is the paradox
collapse (P6): the two horns were "reject useful input" and "accept dangerous input",
and the third answer is *change where the input lands*.

---

<a name="i3"></a>
## I.3 Environment injection

The environment is a second argv that nobody audits. The dangerous names, by mechanism:

| Mechanism | Names |
|---|---|
| Dynamic loader | `LD_PRELOAD`, `LD_AUDIT`, `LD_LIBRARY_PATH`, `DYLD_INSERT_LIBRARIES`, `DYLD_LIBRARY_PATH` |
| libc data paths | `GCONV_PATH`, `LOCPATH`, `NLSPATH`, `TZDIR` |
| Shell startup | `BASH_ENV`, `ENV`, `SHELLOPTS`, `PS4` (with `-x`), `IFS` (historical), `CDPATH` |
| Interpreter pre-load | `PYTHONPATH`, `PYTHONSTARTUP`, `PERL5OPT`, `RUBYOPT`, `NODE_OPTIONS`, `JAVA_TOOL_OPTIONS` |
| Tool-specific exec | `GIT_SSH_COMMAND`, `GIT_SSH`, `GIT_EXTERNAL_DIFF`, `GIT_CONFIG*`, `SSH_ASKPASS`+`DISPLAY`, `SUDO_EDITOR`/`VISUAL`/`EDITOR`, `LESSOPEN`, `MANPAGER`, `PAGER` |
| Location | `PATH`, `TMPDIR`, `HOME`, `ZDOTDIR` |

Verified instances: **CVE-2021-4034** (PwnKit) is an environment-injection outcome
reached through an argv bug — `pkexec` invoked with `argc == 0` reads past `argv` into
the contiguous `envp` and reintroduces `GCONV_PATH` into the *secure* environment,
giving root on every major distribution, latent since 2009. Shellshock
(CVE-2014-6271) made every exported environment variable a bash function body.

Two important platform facts:

- **macOS strips `DYLD_*` and `LD_*` for restricted processes** — setuid/setgid, a
  `__RESTRICT` section, or hardened-runtime binaries AMFI declines to grant the flag
  to. So on Darwin the *loader* class is partly mitigated by the OS, and the
  interpreter and tool-specific classes are not mitigated at all.
- **Nobody has ever succeeded with a denylist.** sudo's own manual says it plainly:

  > "Since it is not possible to block all potentially dangerous environment variables,
  > use of the default `env_reset` behavior is encouraged."

  Every serious system converged on the same answer independently: sudo `env_reset`
  (minimal env: `TERM PATH HOME MAIL SHELL LOGNAME USER SUDO_*`, plus `env_keep`);
  `env -i`; Nix `nix-shell --pure` ("the environment is almost entirely cleared …
  `HOME`, `USER` and `DISPLAY` are retained", with `--keep` to add back); Bazel
  `--incompatible_strict_action_env`, on by default since 0.21, which stops using the
  client's `PATH`/`LD_LIBRARY_PATH` and passes only a whitelist; systemd's
  `PassEnvironment=`.

**The design that deletes it:** Part IV. In one line — **the allow-list is the
mechanism; the denylist is the error message.**

---

<a name="i4"></a>
## I.4 cwd / PATH hijacking

- **Go 1.19** (Aug 2022 — the change is often mis-dated to 2023) made `os/exec` refuse
  to resolve a program through a PATH entry relative to the current directory:
  `LookPath("go")` will not return `./go`, and returns an error satisfying
  `errors.Is(err, ErrDot)`. The escape hatch is `GODEBUG=execerrdot=0`. Note what the
  Go team did *not* do: they did not make it configurable per call, they made it a
  compile-visible break with a global, greppable, deprecated opt-out.
- **Windows is worse by default.** `CreateProcess` with `lpApplicationName == NULL`
  takes the module name from the first whitespace-delimited token of `lpCommandLine`
  and searches, among other places, "the directory from which the application loaded"
  and **the current directory of the parent process**. With an unquoted path
  containing spaces it tries `C:\Program.exe` first. CodeQL ships a query for exactly
  this (`cpp-unsafe-create-process-call`).
- **PATH lookup at the call site is also a TOCTOU.** Every call re-resolves; the answer
  can change between calls; and the process's own `PATH` can be mutated by any library
  in the address space.

**The design that deletes it (L2):** resolution happens **once, before the first line
of the program runs**, in the same prelude that already plumbs argv (`llvm.av:111-127`,
`avra_runtime.c:906-921`) and that the fs doc uses for `fs.seal()`. The answer is an
**fd**, not a path:

- Linux: `open(O_PATH|O_CLOEXEC)` at seal; spawn with
  `execveat(fd, "", argv, envp, AT_EMPTY_PATH)` (Linux ≥3.19). No path walk at the call
  site, so **no TOCTOU window at all** — not a smaller one, none.
- FreeBSD: `fexecve` on the pre-opened fd, which is *the only exec available in
  capability mode*.
- Darwin/Windows: the resolved **absolute** path is used with `posix_spawn` /
  `CreateProcess` with an explicit application name. The window is real; the tier says
  so (Part VII).

And the child's `PATH` is never inherited (L5), so the child cannot hijack its own
grandchildren through the environment we handed it.

---

<a name="i5"></a>
## I.5 Option/filename confusion, NUL bytes, argv[0]

**`-` meaning stdin, and files named `-rf`.** Deleted by T1: a `Rel` is *always*
emitted `./`-prefixed. There is no flag, no mode, no configuration — it is the only
projection from `Rel` to argv that exists.

**NUL bytes.** argv and envp are NUL-terminated with no length side-channel: "There is
no parameter specifying the lengths of the strings in argv, so there's no way for an
invoked program to know if the argv parameters have embedded null bytes." A validator
that checked `"safe\0--upload-pack=x"` sees the safe prefix; `exec` delivers the same
prefix; but the *validator's* language may have kept the whole string, and any later
component that re-derives from it disagrees about the value. jq's advisory
(GHSA-vf2h-chrj-q3fg) is the same bug in a file: the program is truncated at the NUL
and the remainder silently ignored. CPython now raises on embedded NULs in
`PyUnicode_AsUTF8` for precisely this reason.

Deleted by L4: `word()` refuses NUL **and so does the env widening** — one rule, both
places, because they are one mechanism.

**argv[0] spoofing and `argc == 0`.** PwnKit is the canonical outcome. In Avra, argv[0]
is minted by the runtime from the `Program` and the language has no expression that
addresses slot 0 — an empty argv is unrepresentable, so the `argc == 0` shape cannot
occur. (Linux ≥5.18 also forces a single empty string when argv is empty; we do not
rely on it.) The hatch — a login shell needs argv[0] `-bash`, busybox dispatches on it
— is `as_argv0:` on the tool's declared row, printed.

---

<a name="i6"></a>
## I.6 The non-injection classics a process API must also delete

These are not injections and they are what actually breaks production. An LLM-first
library that deletes injection and ships these has traded one bug class for another.

- **The PIPE/`wait` deadlock.** Python's own documentation carries the warning:
  deadlock occurs "when using `stdout=PIPE` or `stderr=PIPE` and the child process
  generates enough output to a pipe such that it blocks waiting for the OS pipe buffer
  to accept more data" (typically 64 KiB on Linux). **A stdlib whose warning box
  describes its own easiest verb has already chosen for you** — the same argument the
  fs doc makes about `write_file`. In Avra there is no `wait()` that can deadlock:
  a `Cmd` is discharged by `run()` (both streams drained concurrently, to a declared
  cap), `stream()` (a fiber per stream), or `passthrough()`.
- **Unbounded capture.** `run()` without a byte cap is a compile error, not an OOM.
- **The ignored exit status.** The tree already holds the law — *A PROCESS STATUS IS A
  VERDICT, never a count* — and `avra_shell_exec_status` already returns `128+signal`
  so a wreck can never read as a small exit code. Extend it into the type system: a
  `Status` is a **must-discharge** value, exactly like the fs doc's `Pending` (F4515).
- **Orphans and runaway children.** Every spawn carries a deadline; the child is put in
  its own process group (`POSIX_SPAWN_SETSID`) and the kill goes to the **group**,
  because killing the pid leaves the grandchildren.
- **fd leaks into the child.** CERT FIO22-C. Everything Avra opens is `O_CLOEXEC`, and
  the child does `close_range(3, ~0U, 0)` (Linux ≥5.9) / `closefrom` (BSD) before exec,
  keeping only the named slots — which is what `libcapsicum` does ("closing all
  undelegated file descriptors, forking … flushing the address space using
  `fexecve()`"), and what CVE-2019-5736 (runc) exploited the absence of, in spirit: a
  descriptor reachable from the child was enough to overwrite the host binary.

---

<a name="part-ii"></a>
# Part II — The authority model: mint, narrow, audit

## II.1 The mint — the manifest, and nothing else

Mirroring `[fs.roots]` exactly. Option (a) from the brief, with option (b)'s provenance
folded in, because a bare program *name* is not a capability — a name is resolved by
PATH, and PATH is ambient.

```toml
[process.tools]
clang = { at = "/usr/bin/clang", from = "path", terminator = "--", env = "minimal" }
git   = { at = "/usr/bin/git",   from = "path", terminator = "--end-of-options", min = "2.43.1" }

[process.tools.ld]
from      = "root"          # resolved inside a declared fs root — no ambient component
root      = "toolchain"
at        = "bin/ld.lld"
env       = { base = "none", set = { LC_ALL = "C" } }
deadline  = "5m"
```

That block **mints** `process.clang`, `process.git`, `process.ld` — each an unforgeable
`Program`. `process.<anything else>` is F4601 with the manifest edit attached. The
`[process]` namespace, like `fs`, **has no functions in it**: it is the namespace of
the tools your manifest declared.

**The four provenances, and what each honestly says:**

| `from` | Resolution | What it admits |
|---|---|---|
| `"abs"` | the literal absolute path, `open(O_PATH)` at seal | nothing ambient; the machine must have that exact file |
| `"path"` | one PATH lookup at seal, then **pinned to the resolved path, which is printed** | "the machine's PATH decided which binary this is" — said out loud, once, in the build output and in `explain` |
| `"root"` | `openat` under a declared `Dir` | **zero ambient component.** The hermetic choice; what a build should use |
| `"cli"` | supplied by the operator at startup (`--tool clang=/opt/llvm/bin/clang`) | the deployment hatch — the *set* of tools is still fixed at compile time; only the binding moves |

`from = "path"` is the honest common case and must not be quietly promoted to
`"abs"`-like confidence: the fs doc's `F4516` (an fs verb before `fs.seal()` on a
`from`-provenance root) has an exact twin here.

**Boundary law, inherited verbatim:** `process.<name>` resolves **only inside the
package that owns the manifest**. In a library package the `process` namespace is
empty and a `Program` arrives as a parameter. *Ambient where the grant was made; a
parameter where it is delegated.*

## II.2 The narrowing — what the child receives

Option (c) from the brief, and it is the piece that closes the fs doc's open item.

```avra
let out = process.clang
    .arg(f"-c")                       // a declared Flag
    .path(src)                        // a Rel → "./src/x.c", under the cwd below
    .flag_path(f"-o", obj)            // "-o./build/x.o" — fused, so it cannot open an option
    .cwd(fs.work)                     // a Dir: the child's cwd IS our fd
    .env_pass(["SDKROOT"])
    .deadline(30.s)
    .run(cap: 1.mb)?
```

Three narrowings, in order of strength:

1. **cwd is a `Dir`, never a string.** `posix_spawn_file_actions_addfchdir_np` (glibc
   ≥2.29, Darwin ≥10.15) makes the child's cwd our open fd. Every path argument is then
   a *relative* name resolved by the child inside a directory we opened. **No absolute
   string is ever materialized, so the fs doc's TOCTOU window does not exist for the
   common case.** This is the single largest win in the design, and it is available on
   every platform.
2. **Handles at named slots.** `fds: { in: file, cfg: dir }` — the fd crosses; the argv
   element is `/dev/fd/N`. This is a **counted hatch** and inherits every objection the
   fs doc raised against `/proc/self/fd/N` (absolute, may be unmounted, no Windows
   equivalent, `…/N/../..` walks the real tree upward) — *except the one that mattered*:
   the fd is already open, so the attacker cannot re-point it. Strictly better than an
   absolute path, strictly worse than a cwd-relative name.
3. **An absolute path (`@ambient_path`).** The last resort, for tools that refuse
   relative input. Counted, greppable, printed. **`@ambient` becomes bounded and
   enumerated — the fs doc's stated honest target — and for cwd-relative tools it
   reaches zero.**

## II.3 The audit — prior art, and what each one teaches

| System | Mechanism | What it gets right | What it costs / concedes |
|---|---|---|---|
| **Deno** `--allow-run=git` | runtime flag, per-program allow-list | the *shape* is right: name your programs | Deno's own docs: `--allow-run` "is an escape hatch out of the sandbox"; subprocesses "do not run in a security sandbox"; a program that may run `deno` may run `deno --allow-all`. **A runtime allow-list with no argv constraint is a confused deputy** |
| **Capsicum / CloudABI** | `cap_enter`, fd-only authority, `fexecve` | capability mode **inherited across fork and exec**; `execve` is *disabled* because it takes a filename | almost no real program can enter it — they all call `open(2)` by path. **An Avra program provably does not**, which the fs doc already identifies as its strongest argument, and which applies verbatim to exec |
| **Fuchsia** | `fuchsia.process.Launcher`, handles + a routed namespace | there is no `fork`/`exec`-by-path at all; a component's authority is the handles it was given | requires the whole OS |
| **WASI** | *no spawn* | the honest refusal — "WASI has no concept of a process" | the ecosystem grew WASIX to add it back, with per-module declared permissions |
| **Landlock** | LSM, path-walk hooked | `LANDLOCK_ACCESS_FS_EXECUTE` restricts *which files may be executed*; **inherited by every descendant** and cannot be removed | needs `no_new_privs`; does not hook `chdir/stat/chmod/chown/setxattr/utime/fcntl/access`; `chroot(2)` is **not** denied |
| **seccomp** | BPF over syscall args | can express *"no `execve` at all"* exactly and cheaply | **cannot ever express "these paths"** — "BPF programs may not dereference pointers", by design, to avoid TOCTOU. Any tool claiming a path-based seccomp exec policy is lying |
| **`no_new_privs`** | prctl | "`execve()` promises not to grant the privilege to do anything that could not have been done without the execve call"; "inherited across fork, clone, and execve and **cannot be unset**" | setuid/setgid stop elevating and file capabilities stop adding — `sudo`, `pkexec`, `ping`, `mount` fail for this process **and every descendant** |
| **OpenBSD `pledge`/`unveil`** | `pledge(promises, execpromises)` | **the parent declares the child's promises.** The closest existing analogue to what `[process]` should *mean*: a first-class, kernel-enforced statement about a program you did not write. A child raising its own promises above the parent's execpromises is silently ignored | OpenBSD only; setuid/setgid execs are refused with `EACCES` |
| **macOS** | `sandbox_init` / `sandbox-exec` | — | **deprecated since ~2016 with no replacement for non-App-Store processes**; SBPL was never documented as API. There is no third-party mechanism to sandbox a child |
| **systemd** | `NoExecPaths=` / `ExecPaths=` | `NoExecPaths=/` + `ExecPaths=/usr/bin/serviced` is *exactly* a declared exec allow-list, enforced by mount namespace | a launcher artifact — inert unless applied; Tier 2 |

**Two findings from this table that change the design.**

**Finding 1 — the empty `[process]` block is the strongest guarantee in the system.**
seccomp cannot filter `execve` by path, but it can deny `execve`/`execveat`/`fork`/
`clone` *entirely*, precisely, with no pointer deref and no TOCTOU. So:

- **No `[process]` block → the prelude installs a seccomp filter denying exec.** A
  kernel-proven "this binary never runs another program", free, exact, on every Linux.
  That is a stronger statement than any allow-list, and it is the *default*.
- **A `[process]` block → Landlock `LANDLOCK_ACCESS_FS_EXECUTE` on exactly the declared
  tool paths**, inherited by every descendant.

**Finding 2 — exec and fs must be ONE Landlock ruleset, sealed once.** `FS_EXECUTE` is
a *filesystem* right, and Landlock layers are conjunctive: access must be permitted by
every layer. If layer 1 (the fs roots) does not grant `READ_FILE|EXECUTE` on
`/usr/bin/clang`, a later layer granting it changes nothing — it is still denied. So
`fs.seal()` and `process.seal()` are **one `caps.seal()` compiling both blocks into one
ruleset**, and it follows that:

> **Declaring a tool widens the process's filesystem authority by exactly one file**,
> and `avra explain hardening` must print that line beside the roots.

That coupling is not a wart; it is the design telling the truth about what a tool
declaration costs. It also matters for layer budget — the fs doc already spends 2 of 16.

---

<a name="part-iii"></a>
# Part III — Backward projections

One declaration, run backward. Sketched outputs.

### `avra explain process`

```
$ avra explain process
  DECLARED — 3 tools, this package
    clang  /usr/bin/clang            from=path (resolved 2026-09-04)
           sha256 9f3a…c118          terminator "--"   env minimal
           argv grammar: none — T1 only (values fused, paths ./-prefixed)
    git    /usr/bin/git 2.47.1       from=path   terminator "--end-of-options"
           argv grammar: @std.process.git  (clone, fetch, rev_parse)
    ld     toolchain:bin/ld.lld      from=root — NO ambient component
  REACHABLE — the complete list of programs this binary can ever exec:
    /usr/bin/clang  /usr/bin/git  <fs.toolchain>/bin/ld.lld
    …and nothing else. No shell is declared.
  HATCHES — 2, both counted:
    @ambient_path   1  cli/commands/shared.av:191  (clang -o absolute)
    @ambient_env    0
  DEGRADED
    `git` min=2.43.1 satisfied; `--end-of-options` is honoured by
      rev-parse/checkout/reset on this build.
    `clang` accepts -fplugin: a declared tool is an INTERPRETER. Your
      argv grammar is the only thing between a dependency and RCE.
      See `avra explain process --flags clang`.
```

### `avra explain hardening --target linux-6.12` (extends the fs doc's block)

```
  ENFORCED BY US — one ruleset, applied at caps.seal():
    landlock_restrict_self  ABI 6, layers 2/16
      /etc/thumbd        READ_FILE|READ_DIR
      ./var/data         READ_FILE|WRITE_FILE|MAKE_REG|REMOVE_FILE|REFER
      /usr/bin/clang     READ_FILE|EXECUTE      ← [process.tools] clang
      /usr/bin/git       READ_FILE|EXECUTE      ← [process.tools] git
    prctl(PR_SET_NO_NEW_PRIVS, 1)
    close_range()  every inherited fd except 3 (root `inbox`)
  WHEN [process] IS EMPTY (not this build):
    seccomp SCMP_ACT_ERRNO(EPERM) on execve, execveat, fork, vfork, clone(CLONE_VM=0)
      — exact, kernel-proven, no pointer deref. The strongest tier here.
  EMITTED FOR YOUR LAUNCHER — inert unless someone applies it:
    systemd   NoExecPaths=/
              ExecPaths=/usr/bin/clang /usr/bin/git
    k8s       securityContext.readOnlyRootFilesystem: true
              (no k8s primitive expresses an execve allow-list — see NOT EMITTED)
    openbsd   pledge("stdio rpath wpath cpath proc exec", "stdio rpath")
              unveil("/usr/bin/clang", "rx"); unveil("/usr/bin/git", "rx")
  NOT EMITTED, and why
    seccomp exec allow-list: IMPOSSIBLE. seccomp-BPF cannot dereference
      pointers, so no filter can name a path. Any tool that claims one
      is filtering the syscall number and hoping.
    k8s: no securityContext field expresses "these binaries only".
      NoExecPaths has no k8s equivalent; the honest projection is a
      read-only rootfs plus an image that contains only these binaries.
  DEGRADED
    darwin: NO kernel layer. sandbox_init is deprecated with no
      replacement. Tier 0 only — say so in your threat model.
    landlock does not hook chdir/stat/chmod/chown/setxattr/utime/fcntl,
      and does NOT deny chroot(2).
    a child inherits the landlock domain (kernel-proven) — and that
      domain is a SUPERSET of this package's Avra-level authority.
  --strict makes any DEGRADED line a build error.
```

### `avra caps diff` — the supply-chain gate

```
$ avra caps diff @acme/imaging 2.3.1 → 2.3.2
  ! PROCESS CAPABILITY WIDENED by a PATCH release
      + /usr/bin/ffmpeg        [process.tools] ffmpeg, from=path
      + terminator "none"      → positional args need @ambient_arg
  ! FILESYSTEM WIDENED as a consequence
      + /usr/bin/ffmpeg        READ_FILE|EXECUTE  (union landlock ruleset)
    unchanged: fs roots, env allow-list, hatch counts
  build FAILED: a dependency may not widen [process] across a
    semver-compatible upgrade.
  fix: pin it —
         [dependencies]
         "@acme/imaging" = { version = "=2.3.1" }
       or accept it, at the site, counted —
         [process.accept]
         "@acme/imaging" = ["ffmpeg"]   # reviewed 2026-09-04
  note: `avra explain process --since 2.3.1` prints the dependency's own
        diff of the declaration, and `git diff avra.toml` is the whole
        security review of this upgrade.
```

### `avra explain process --llms`

The LLM projection (P11/P12): the tool table, every declared `Flag`, every widening,
and the T1 emission rules — so the model writes `flag_path(f"-o", obj)` on the first
try instead of `"-o " + path`.

---

<a name="part-iv"></a>
# Part IV — The child's environment as contract

**The safe default for an LLM-written program is `base = "minimal"`: a named,
versioned, printed set — never the parent's environment.**

```toml
[process.tools.clang]
at  = "/usr/bin/clang"
env = { base = "minimal", pass = ["SDKROOT", "MACOSX_DEPLOYMENT_TARGET"],
        set  = { LC_ALL = "C", TZ = "UTC" } }
```

- **`base = "none"`** — `env -i`. Nothing. The hermetic choice; many tools break.
- **`base = "minimal"`** (default) — a *declared, versioned* list, printed by `explain`:
  `PATH` (**minted from the declared tools' directories only, never inherited**),
  `HOME`, `TMPDIR`, `LANG=C`, `TERM` when stdio is a tty. This is sudo's `env_reset`
  (`TERM PATH HOME MAIL SHELL LOGNAME USER SUDO_*`) and Nix's `--pure` (`HOME`, `USER`,
  `DISPLAY` retained) and Bazel's strict action env, and the fact that four independent
  systems converged on "a tiny named list" is the strongest available evidence that it
  is the right default.
- **`pass = [...]`** — systemd's `PassEnvironment=`, Nix's `--keep`, sudo's `env_keep`.
  Named, one at a time, in the manifest, diffable.
- **`set = {...}`** — literal values, from the manifest.
- **`base = "inherit"`** — the counted hatch, `@ambient_env`, required at the site,
  greppable, counted in build output, ratcheted by CI like `make idioms` ratchets
  idiom debt. And it prints its bill:

```
warning[F4607]: `@ambient_env` passes the whole environment to `sh`
  ╭─[deploy.av:44:9]
44 │     @ambient_env
   ·     ─────┬──────
   ·          ╰── every variable this process holds reaches the child
──╯
note: this hands the child, among 61 variables, every name that turns a
      program into an interpreter:
        LD_PRELOAD  LD_AUDIT  DYLD_INSERT_LIBRARIES  GCONV_PATH  BASH_ENV
        PYTHONPATH  PERL5OPT  RUBYOPT  NODE_OPTIONS  GIT_SSH_COMMAND
        SSH_ASKPASS  LESSOPEN  EDITOR
      A denylist cannot close this; sudo's own manual says so. The
      allow-list is the mechanism — this note is only the receipt.
counted: @ambient_env 1 (was 0) — `make caps` fails on an increase.
fix: name what you need —
       env = { base = "minimal", pass = ["SSH_AUTH_SOCK"] }
```

**One rule for both channels:** an environment value is bytes with no NUL, minted from
`Untrusted<string>` only through the same named widening as argv. Environment
*names* are stricter still: `^[A-Za-z_][A-Za-z0-9_]*$`, refused otherwise, because a
name containing `=` splits a variable in two.

---

<a name="part-v"></a>
# Part V — The build machine

The tree's live vulnerability, root-caused in its own ROADMAP: a transitive
dependency's `[link] flags` row is spliced unquoted into the `system()` string that
runs clang, and `link_inputs` walks **every package in the workspace** — so a
dependency the program never imports runs a command during `avra build`. Proved with
`flags = ["; touch /tmp/PWNED ;"]`.

The planned fix (`avra_spawn_status(prog, argv)` over `posix_spawnp`, argv as a LIST,
`shell_word` deleted) is correct and is **step one of five**. Steps two through five
are the difference between deleting the shell and deleting the injection.

### Step 2 — argv-lists are not enough, and cgo is the proof

With argv-lists, `flags = ["; touch /tmp/PWNED ;"]` becomes one inert argv element.
`flags = ["-fplugin=./evil.so"]` becomes one *perfectly valid* clang argument that
loads an unrestricted plugin into the compiler. That is **CVE-2018-6574** exactly — Go
before 1.8.7/1.9.4/1.10rc2, where a repository could ship `attack.so` beside
`// #cgo CFLAGS: -fplugin=attack.so` and own the build machine. Go's own wiki states
the reasoning for the fix's *shape*:

> "running `go get` downloads and builds Go code from the Internet, Go code that uses
> cgo can specify options to pass to the compiler, so careful use of `-fplugin` can
> cause `go get` to execute arbitrary code."

and rejects the denylist explicitly:

> "if some new unsafe option is added to a compiler, all existing Go releases will
> become immediately vulnerable" [if a blocklist were used]

So Go shipped a **default-deny allow-list** of known-safe flags, widened only by
environment: `CGO_CFLAGS_ALLOW`, `CGO_LDFLAGS_ALLOW`, `CGO_CXXFLAGS_ALLOW`, each a
regexp that **must match a full argument** — "to allow `-mfoo=bar`, use
`CGO_CFLAGS_ALLOW='-mfoo.*'`, not just `CGO_CFLAGS_ALLOW='-mfoo'`". That
full-argument rule is the same insight as T1: a partial match is a position bug.

### Step 3 — the structural fix: `[link]` stops being free text

Go allow-lists flags because it accepts free text. **Avra deletes the free text.**

```toml
[link]
objects = ["../../build/llvm_wrapper.o"]   # a Rel under THIS package's own root
search  = ["${LLVM_PREFIX}/lib"]           # a directory
libs    = ["LLVM"]                         # a NAME: ^[A-Za-z0-9_.+-]+$
frameworks = ["CoreFoundation"]            # darwin only
```

The emitter builds `-L<dir>` and `-l<name>` itself. **No row can carry a `-`-leading
token at all**, so `-fplugin=`, `-Wl,`, `-B`, `-specs=`, `--sysroot` and every future
compiler feature are *not expressible by a dependency* — not filtered, unspellable.
This is T3 (per-tool argument grammars) applied to the compiler's own use of clang, and
it is the same law, not a special case.

Note what this also fixes about `${NAME}` expansion, which the ROADMAP proposes to keep
("the environment is the invoker's own"). That is right, and it becomes *safe* for a
sharper reason than quoting: **one manifest row is one argv element**, so a space or a
`;` inside `LLVM_PREFIX` cannot split anything, and the row is typed as a directory so
it cannot become a flag. Keep the expansion; the typing is what makes it defensible.

### Step 4 — the residue, with Go's exact design

Some project genuinely needs `-Wl,--version-script=…`. Then:

- a **default-deny per-tool allow-list**, full-argument regexps, in the *root* package's
  manifest only — **never a dependency's** (a dependency may declare `objects`, `search`,
  `libs`; it may not declare a raw flag, ever);
- printed by `avra explain process --flags clang`, counted, and `avra caps diff`-gated.

```toml
[link.raw]            # root package only; F4613 if a dependency writes it
clang = ["-Wl,--version-script=.*"]
```

### Step 5 — the deep move: the toolchain is a declared root

`from = "root"` on the tool row makes the build's clang a file inside a declared `Dir`,
not whatever the machine's PATH answers. That is Bazel's hermeticity
(`--incompatible_strict_action_env`, sandbox mounts `/` read-only, only a whitelist of
env vars passes) arrived at from the capability side rather than the reproducibility
side — and it is the same declaration, so it prints backward into a Dockerfile.

### What Cargo teaches, by contrast

`build.rs` is **arbitrary code** with the developer's full authority, run on every
build, and `cargo:rustc-link-arg` passes arbitrary linker arguments. The trust model is
"you already trusted the crate", and the review advice is necessarily manual — check
whether a build script makes network calls, reads env beyond `CARGO_*`/`OUT_DIR`,
writes outside `OUT_DIR`, or execs binaries.

> **A declaration can be diffed. A build script cannot.** That is the whole argument
> for `[link]` being data, and it is why `avra caps diff` is possible here and
> impossible for Cargo.

---

<a name="part-vi"></a>
# Part VI — THE LAWS

Eight. Each deletes a named bug class; each has a diagnostic.

---

### L1 — THE MINT LAW

**There is no expression in Avra that names a program, and no verb that takes a command
string; `process.<name>` is minted by a `[process.tools]` row and by nothing else.**

Deletes **shell injection** and **arbitrary-program spawn** — the `system(3)` class, the
`shell=True` class, and Deno's `--allow-run` escape where a sandboxed program spawns
`deno --allow-all`. The shell is not banned: it is a declared row named `sh`, which
makes it greppable, counted, printed by `avra explain process`, and gated by `avra caps
diff`. The mechanism is the same one the fs doc uses for roots, so a reader who has
learned one has learned both, and an LLM that has seen `fs.data` writes `process.git`
without being told. Corollary, enforced at the seam: when the argv row lands,
`shell_word` and `binary_name`'s quoting are **deleted, not kept as fencing** — surviving
fencing is fencing that will be trusted again.

```
error[F4601]: no tool named `ffmpeg`
  ╭─[thumb.av:31:13]
31 │     let r = process.ffmpeg.arg(f"-i").path(src).run(cap: 1.mb)?
   ·                     ───┬──
   ·                        ╰── `process` has 3 tools and none is `ffmpeg`
──╯
declared tools: clang (path)  git (path)  ld (root:toolchain)
fix: add to avra.toml —
       [process.tools]
       ffmpeg = { at = "/usr/bin/ffmpeg", from = "path", terminator = "--" }
note: adding a tool widens this package's capability set TWICE — it adds an
      exec target AND one file to the process's landlock ruleset
      (READ_FILE|EXECUTE). `avra caps diff` will report both to your dependents.
```

---

### L2 — THE ONE RESOLUTION LAW

**A `Program` is resolved exactly once, in the prelude, to a file descriptor and a
printed absolute path; there is no PATH lookup, and no path walk, at a call site.**

Deletes **PATH hijacking**, **cwd hijacking** (Go's `ErrDot` class; Windows'
`CreateProcess` search of the parent's current directory when `lpApplicationName` is
NULL), and **exec TOCTOU** — on Linux and FreeBSD not by shrinking the window but by
removing it: `execveat(fd, "", AT_EMPTY_PATH)` and `fexecve` execute the fd that was
checked, so there is no second resolution to race. The resolved path and its digest are
printed at build time and at `explain` time, so "which clang" is a fact in the build
output rather than a property of whoever's shell started the process. `from = "root"`
removes the ambient component entirely and is what a build should use.

```
error[F4602]: `process.clang` used before `caps.seal()`
  ╭─[build.av:12:5]
12 │     process.clang.arg(f"--version").run(cap: 4.kb)?
   ·     ──────┬──────
   ·           ╰── this tool has `from = "path"`; its binary is not pinned yet
──╯
note: a `from = "path"` tool is resolved by ONE PATH lookup, in the prelude.
      Until `caps.seal()` runs, the pin does not exist and the lookup would
      happen here — at a call site, racily, per call.
fix: seal first —
       caps.seal()?          // one ruleset: fs roots + exec targets
       process.clang.arg(f"--version").run(cap: 4.kb)?
```

---

### L3 — THE POSITION LAW

**An argv element built from data is emitted in the one form the callee cannot re-read
as an option — fused to its flag (`--flag=VALUE`), `./`-prefixed when it is a path, or
after the tool's declared terminator — and a `Flag` is minted only from the tool's
declared vocabulary.**

Deletes **argument injection**: `--upload-pack`, `--receive-pack`, `--exec`,
`--checkpoint-action=exec=`, `-oProxyCommand=`, `-e`, `-K`, `-exec`, and the
`--`-as-payload class (CVE-2023-22809). argv-as-a-list does not delete this; nothing
short of controlling the *position* does. The `--flag=VALUE` fusion and the `./` prefix
are total functions from data to a non-option element, so they need no per-tool
knowledge and no version check; the declared `terminator` is a registry row (data, per
the vocabulary seam rule), and `terminator = "none"` is an honest declaration that T1 is
the only defence for that tool. The deep tier — `git.clone(url, into: Dir)` in a
package — makes dangerous flags **unspellable** rather than denied, which is the only
answer that survives GitPython's CVE-2026-42215, where a denylist was bypassed by an
underscore that normalised to a dash *after* the check ran.

```
error[F4603]: this value would be read as an option
  ╭─[fetch.av:18:31]
18 │     process.git.arg(f"clone").word(remote)?.path(dest)
   ·                               ──────┬──────
   ·                                     ╰── `remote` is `Untrusted<string>` from the wire
──╯
note: git parses any argument beginning with `-` as an option. A remote of
      `--upload-pack=touch /tmp/pwn` is CWE-88, and an argv LIST does not
      stop it — there is no shell involved in the attack.
note: `git`'s declared terminator is `--end-of-options` (2.24+), and this
      build's git is 2.47.1, so a terminated position is available here.
help: `u.word()?` refuses a leading `-`; `after_terminator()` opens a
      position where a `-` is inert.
fix:  process.git.arg(f"clone").after_terminator(remote.word()?).path(dest)
      — or use the grammar, where the flag is unspellable:
        use @std.process.git
        git.clone(url: remote.url()?, into: fs.work.dir(p"checkout"))?
```

```
error[F4604]: `-fplugin=…` is not an expressible link input
  ╭─[@acme/imaging/avra.toml:9:11]
 9 │ flags = ["-fplugin=./evil.so"]
   ·           ───────┬───────────
   ·                  ╰── a dependency may not name a raw compiler flag
──╯
note: this is CVE-2018-6574 (Go, 2018): a downloaded package that can name a
      compiler flag can load an unrestricted plugin into the compiler and own
      the build machine. Go answered with a default-deny allow-list; Avra
      answers by deleting the free-text row.
fix: say what it IS, in typed rows —
       [link]
       objects = ["build/imaging.o"]     # a Rel under this package's root
       search  = ["${IMAGING_PREFIX}/lib"]
       libs    = ["imaging"]
note: raw flags exist for the ROOT package only, allow-listed by full-argument
      regexp in `[link.raw]`, counted, and gated by `avra caps diff`.
```

---

### L4 — THE UNTRUSTED LAW

**Untrusted text becomes an argv element or an environment value only through a named
widening that refuses NUL, refuses emptiness, and refuses a leading `-`; no verb in
`@std.process` takes an `Untrusted<T>`.**

Deletes **NUL truncation** (argv and envp carry no lengths, so a validator and `exec`
can disagree about where a string ends — jq's GHSA-vf2h-chrj-q3fg is the same bug in a
file), **empty-argument confusion**, and the `-`-leading word at its source. This is the
fs doc's third law, extended one channel outward, and deliberately the *same words*:
`leaf()` widens one path component, `word()` widens one argv element, and a reader who
knows one predicts the other. `dash_word()` exists (P8) and is legal only after a
declared terminator; it is counted.

```
error[F4605]: `word` will not take a NUL
  ╭─[serve.av:22:24]
22 │     process.tar.word(req.query["name"].word()?)
   ·                      ──────────┬─────────────
   ·                                ╰── contains byte 0x00 at index 4
──╯
note: argv strings are NUL-terminated and carry no length, so the value your
      validator saw and the value the child receives are different values.
      Nothing downstream can detect the difference.
fix: reject it at the boundary, where the shape is known —
       let name = req.query["name"].word()?   // refuses NUL, empty, leading `-`
```

---

### L5 — THE INHERITANCE LAW

**A child inherits nothing that was not named: the environment is an allow-list over a
printed base, every fd is closed but the named slots, the cwd is a `Dir`, and argv[0] is
the `Program`'s.**

Deletes **environment injection** (`LD_PRELOAD`, `LD_AUDIT`,
`DYLD_INSERT_LIBRARIES`, `GCONV_PATH`, `BASH_ENV`, `PYTHONPATH`, `PERL5OPT`,
`NODE_OPTIONS`, `GIT_SSH_COMMAND`, `SSH_ASKPASS`, `SUDO_EDITOR` …), **fd leaks** (CERT
FIO22-C; the child does `close_range(3, ~0U, 0)` / `closefrom` before exec, which is
what libcapsicum does), and **argv[0] spoofing including PwnKit's `argc == 0`** — an
empty argv is unrepresentable because the language has no expression addressing slot 0.
The default base is `minimal`, a named, versioned, printed list — the answer sudo
(`env_reset`), Nix (`--pure`), Bazel (`--incompatible_strict_action_env`) and systemd
(`PassEnvironment=`) each reached independently, and sudo's manual states the reason a
denylist cannot work. The child's `PATH` is minted from the declared tools' directories,
never inherited, so the child cannot hijack its own grandchildren with the environment
we handed it. `base = "inherit"` is `@ambient_env`: required at the site, greppable,
counted, and it prints every dangerous name it just let through.

*(Diagnostic F4607 rendered in Part IV.)*

---

### L6 — THE PATH-BY-AUTHORITY LAW

**A path reaches a child as a `Rel` under a `Dir` the parent opened and handed over —
as the child's cwd, or as an fd at a named slot — never as an absolute string the parent
materialized.**

Deletes the **argv-path TOCTOU** the fs doc left open: "between materializing that
string and the child's `open(2)` there is a window whose length the attacker chooses."
With `cwd:` bound to a `Dir` fd (`posix_spawn_file_actions_addfchdir_np`), the child
resolves a *relative* name inside a directory we already hold, and no absolute string
exists to race. This closes the item to the degree it can be closed and moves
`@ambient` from *unbounded* to **bounded and enumerated** — the fs doc's own honest
target — reaching zero for the many tools that accept relative input. `/dev/fd/N`
remains a counted hatch that inherits every objection the fs doc raised, minus the one
that mattered: the fd is already open, so it cannot be re-pointed.

```
error[F4608]: an absolute path handed to a child needs `@ambient_path`
  ╭─[thumb.av:52:39]
52 │     process.clang.word(fs.work.absolute(obj)?)
   ·                        ──────────┬───────────
   ·                                  ╰── materializes a path outside the fd model
──╯
note: between this string and the child's open(2) there is a window whose
      length an attacker chooses. `clang` accepts relative paths.
help: `.cwd(dir)` makes the child's working directory YOUR fd; a `Rel` then
      resolves inside it, and no absolute path is ever produced.
fix:  process.clang.cwd(fs.work).path(obj)
counted: @ambient_path 1 — `make caps` fails on an increase.
```

---

### L7 — THE DISCHARGE LAW

**A spawn answers a `Status` that must be discharged, under a declared deadline, with a
declared output cap; an ignored status, an unbounded capture, and a missing deadline
are compile errors.**

Deletes the four bugs that actually take production down: the **`stdout=PIPE` + `wait`
deadlock** that Python's own documentation warns about (a stdlib whose warning box
describes its easiest verb has already chosen for you — the fs doc's argument about
`write_file`, one library over), **unbounded capture OOM**, the **ignored exit status**,
and **orphans** (the child gets its own process group and the deadline's kill goes to
the *group*, because killing the pid leaves the grandchildren). The tree already holds
half of this law — *a process status is a verdict, never a count*, and
`avra_shell_exec_status` already answers `128+signal` — and this makes the other half a
type: an undischarged `Status` is the fs doc's `Pending` (F4515) wearing a different
hat.

```
error[F4609]: this `Status` is never discharged
  ╭─[build.av:61:5]
61 │     process.clang.cwd(fs.work).path(src).run(cap: 1.mb)
   ·     ─────────────────────┬─────────────────────────────
   ·                          ╰── answers `Status`, dropped here
──╯
note: 256 failures read as success when a status is truncated to eight bits,
      and a status nobody reads is a build that reports green over red.
help: `.ok()?` refuses a non-zero verdict; `.status()` names it; a signal
      reads as 128+n so a wreck is never a small exit code.
fix:  process.clang.cwd(fs.work).path(src).run(cap: 1.mb)?.ok()?
```

```
error[F4610]: `capture` with no cap
  ╭─[scan.av:14:44]
14 │     let out = process.git.arg(f"log").capture()
   ·                                       ────┬───
   ·                                           ╰── unbounded
──╯
note: the pipe buffer is ~64 KiB. An unbounded capture is either an OOM or —
      if you wait before draining — the deadlock Python's own docs warn about:
      the child blocks writing, you block waiting, forever.
fix:  .run(cap: 8.mb)      // both streams drained concurrently, to a cap
help: for output larger than memory, `.stream()` gives a fiber per stream.
```

---

### L8 — THE PROJECTION LAW

**The `[process]` block is the only truth: the compiler prints the exec policy, prints
the complete list of programs the binary can ever run, and fails the build when a
dependency upgrade widens that list.**

Deletes **silent supply-chain capability escalation** — a patch bump that adds a
spawnable program, which no lockfile diff and no `npm audit` will show you. The
projections are one derivation printed several times: Landlock `FS_EXECUTE` on exactly
the declared paths (inherited by every descendant, unremovable); a seccomp filter
denying `execve` outright when the block is *empty*, which is the strongest and cheapest
guarantee in the system precisely because it needs no pointer dereference; systemd
`NoExecPaths=/` + `ExecPaths=`; OpenBSD `pledge` execpromises and `unveil`. The compiler
must also print what it **cannot** emit — no seccomp filter can name a path, and no k8s
`securityContext` field expresses an execve allow-list — because a projection that
quietly omits an impossible enforcer is how a team comes to believe in a control that
was never applied.

```
error[F4612]: `@acme/imaging` 2.3.2 widens [process]
  ╭─[avra.toml:14:1]
14 │ "@acme/imaging" = { version = "^2.3.1" }
   · ────────────────┬───────────────────────
   ·                 ╰── a patch upgrade added an exec target
──╯
  + /usr/bin/ffmpeg   [process.tools] ffmpeg, from = "path", terminator = "none"
  + /usr/bin/ffmpeg   READ_FILE|EXECUTE in the union landlock ruleset
fix: pin it —
       "@acme/imaging" = { version = "=2.3.1" }
     or accept it, at the site, counted and dated —
       [process.accept]
       "@acme/imaging" = ["ffmpeg"]   # reviewed 2026-09-04
note: `terminator = "none"` means ffmpeg has no end-of-options marker; every
      positional argument this dependency builds needs `@ambient_arg`.
note: `git diff avra.toml` is the complete security review of this upgrade.
```

---

<a name="part-vii"></a>
# Part VII — Honest limits, per tier

**Enforcement is the fs doc's three-tier ladder, and every claim site must name its
tier.** For spawn the ladder is *shorter than for files*, and the reason is one
sentence:

> **A child is a foreign program. Once it runs, it does whatever its inherited kernel
> authority allows, and no type system in the parent has any opinion about it.**

### Tier 0 — PROVEN, all platforms, including `avra run`

No expression names an undeclared program; no verb takes a command string; no argv
element built from data occupies an option-eligible position; env is an allow-list; fds
and cwd are named; argv[0] is minted. Enforced by the type checker. Defeated only by
`@ambient*` (counted), FFI (declared), or a declared shell (declared).

**What Tier 0 does not do:** it does not stop the *declared tool* from doing anything
that tool can be made to do.

### The confused-deputy limit — the biggest one, and it is not platform-specific

> **`allow = ["git"]` is `allow = ["*"]` until an argv grammar constrains it.**

Every useful tool is an interpreter. `clang` has `-fplugin`. `git` has `-c
core.pager=`, `--upload-pack`, `--exec`. `tar` has `--checkpoint-action=exec=`. `ssh`
has `-oProxyCommand=`. `curl` has `-K`, which re-opens the entire option surface from
inside a file. `env` and `psql` and `zip` are in Sonar's catalogue for the same reason.
So L3's T1 emission rules are load-bearing on **every** tool, and the T3 grammars — not
the allow-list — are what make a spawn capability meaningfully narrower than "run
anything". Deno's `--allow-run=git` has exactly this hole and its documentation says so.

### Tier 1 — ENFORCED, named platforms, after `caps.seal()`

| Platform | Mechanism | What is honestly guaranteed | What is not |
|---|---|---|---|
| **Linux ≥5.13 (ABI 1+)** | Landlock `FS_EXECUTE` + `no_new_privs` | the process **and every descendant, forever** may execute only the declared files; the domain cannot be removed, only narrowed | not `chdir`/`stat`/`chmod`/`chown`/`setxattr`/`utime`/`fcntl`/`access`; **`chroot(2)` is not denied**; the network is Landlock-restrictable only from ABI 4 (TCP) and ABI 10 (UDP), not by this design |
| **Linux, empty `[process]`** | seccomp deny `execve`/`execveat`/`fork`/`clone` | exact, kernel-proven, no pointer deref: this binary never runs another program | nothing weaker is available *with* a `[process]` block — seccomp can never name a path |
| **FreeBSD ≥13** | `cap_enter` + `fexecve` | capability mode is inherited across fork and exec; `execve` (which takes a filename) is *disabled*. **The only platform where the design's model and the kernel's model are the same model** | the child must itself be Capsicum-aware to do anything useful with its handles |
| **OpenBSD** | `pledge(promises, execpromises)` + `unveil` | the parent **declares the child's promises**, kernel-enforced; a child raising them above the parent's execpromises is silently ignored; setuid/setgid execs fail `EACCES` | OpenBSD only; execpromises are coarse categories, not a path list |
| **macOS** | **nothing** | — | `sandbox_init`/`sandbox-exec` deprecated since ~2016; SBPL was never documented as API; App Sandbox does not apply to non-apps. **Tier 0 only. Say so in your threat model.** SIP does strip `DYLD_*`/`LD_*` for restricted processes, which mitigates one env class and no others |
| **Windows** | **nothing portable** | — | job objects bound resources, not exec. And `.bat`/`.cmd` are **refused outright at compile time**: Rust could not find a correct `cmd.exe` escaper (CVE-2024-24576) and now returns `InvalidInput` at runtime; Avra should refuse at the declaration |

**`no_new_privs` has a bill, and it is inherited.** "The setuid and setgid bits will no
longer change the uid or gid; file capabilities will not add to the permitted set" —
for this process **and every descendant, and it cannot be unset**. `sudo`, `pkexec`,
`ping`, `mount` fail. Landlock requires it for unprivileged tasks, and the kernel docs
warn that skipping it (with `CAP_SYS_ADMIN`) leaves sandboxed processes able to exec
setuid binaries that then "run with elevated privileges while being restricted by a
Landlock domain they may not expect, making them potential confused deputies."

### Tier 2 — EMITTED, inert

systemd `NoExecPaths=`/`ExecPaths=`, an AppArmor/SELinux profile, a Dockerfile, a
`pledge` line. Generated from the same declaration, applied by a launcher, **verified by
nobody**. `avra explain hardening` must keep them visually separate from Tier 1, as the
fs doc already does.

### The five things a process library can never promise

1. **A child's authority is a superset of the parent's Avra-level authority.** The
   Landlock domain is process-wide and is the union of every package's declared roots
   plus every declared tool path; a shell child can read every byte under that union,
   including files the parent could never name. Both statements are true at their own
   layer; only one used to be printed.
2. **The kernel layer is process-wide; the type system's partition is not.** A
   dependency declaring `sh` makes exec-of-`sh` live for every line in the binary.
3. **A permitted program is an interpreter** (above).
4. **Nothing on macOS or Windows.** The strongest sentence available there is Tier 0's,
   and Tier 0 is defeated by FFI, by `@ambient*`, and by the child itself.
5. **Not applied under `avra run`** — the interpreter has no prelude, so there is no
   seal, so Tier 1 does not exist there. Same limit the fs doc states.

### And the limit specific to *this* tree, today

**The build machine is already owned.** Until `avra_shell_exec_status` is replaced *and*
`[link]` is typed (Part V steps 1–3), no capability claim in this document extends to
build time — a dependency already owns the build machine, which is strictly larger than
any tool it could declare. Step 1 alone (argv-lists) closes the shell but leaves
CVE-2018-6574's shape wide open.

---

<a name="part-viii"></a>
# Part VIII — Confidence ledger

### HIGH — verified against primary or vendor sources in this session

| Claim | Evidence |
|---|---|
| seccomp cannot filter `execve` by path, ever | kernel docs: "BPF programs may not dereference pointers" — deliberate, to prevent TOCTOU |
| `no_new_privs` is inherited across fork/clone/execve and cannot be unset | kernel docs, quoted verbatim |
| Landlock has `LANDLOCK_ACCESS_FS_EXECUTE`; domains are inherited by all descendants; ABI 3 added TRUNCATE, ABI 4 TCP, ABI 5 IOCTL_DEV | kernel docs, ABI table read directly |
| Landlock does not hook chdir/stat/flock/chmod/chown/setxattr/utime/fcntl/access, and does **not** deny `chroot(2)` | kernel docs, quoted |
| `execveat(fd, "", AT_EMPTY_PATH)` executes an fd; Linux ≥3.19; it is how `fexecve` is implementable without `/proc` | man7 execveat(2) |
| Capsicum: capability mode inherited across fork **and exec**; `execve` disabled because it takes a filename; `fexecve` is the replacement | FreeBSD man pages + Capsicum papers |
| OpenBSD `pledge`'s 2nd argument is `execpromises`, applied after execve; a child raising promises above them is silently ignored; setuid execs → `EACCES` | pledge(2) |
| Go 1.19 `os/exec` returns `ErrDot` rather than resolving `./prog`; `GODEBUG=execerrdot=0` opts out | pkg.go.dev + golang/go#43724 |
| CVE-2018-6574 + the `CGO_*_ALLOW` design; the regexp must match a **full argument**; blocklists rejected on stated grounds | go.dev/wiki/InvalidFlag, fetched |
| CVE-2024-24576 (BatBadBut), Rust <1.77.2, fixed 2024-04-09; `Command` now returns `InvalidInput` when escaping is impossible; quoted rationale | Rust security advisory blog post, fetched |
| CVE-2026-42215 (GitPython ≥3.1.30 <3.1.47): denylist checked **pre-normalization**, `upload_pack=` bypasses `--upload-pack` | GitHub advisory GHSA-rpm5-65cw-6hj4, fetched |
| CVE-2023-22809 (sudo 1.8.0–1.9.12p1): `--` in `EDITOR`/`VISUAL`/`SUDO_EDITOR` defeats the argument check | multiple vendor advisories (Ubuntu, SUSE, IBM, SentinelOne) |
| CVE-2021-4034 (PwnKit): `argc == 0` reads into contiguous `envp`, reintroduces `GCONV_PATH` | Qualys writeup + vendor advisories |
| CVE-2019-5736 (runc): `/proc/self/exe` + a leaked fd overwrites the host binary | cve.org + Red Hat |
| sudo `env_reset` semantics and the "cannot blocklist" statement | sudoers(5), quoted |
| Nix `--pure` retains HOME/USER/DISPLAY; `--keep` adds back | Nix reference manual |
| Bazel `--incompatible_strict_action_env` default-on since 0.21; drops client PATH/LD_LIBRARY_PATH | bazelbuild/bazel#6648 |
| systemd `NoExecPaths=/` + `ExecPaths=/usr/bin/x` is an exec allow-list via mount namespace | systemd.exec(5) |
| Deno: `--allow-run` "is an escape hatch out of the sandbox"; subprocesses run unsandboxed | Deno docs |
| macOS: `sandbox_init`/`sandbox-exec` deprecated, SBPL undocumented, no replacement for non-apps | Apple docs + apple/containerization#737 |
| macOS strips `DYLD_*`/`LD_*` for restricted (setuid, `__RESTRICT`, hardened-runtime) processes | Apple forums + dyld analyses |
| Python's docs warn that `stdout=PIPE` + `wait()` deadlocks on a full pipe buffer | docs.python.org subprocess |
| `CreateProcess` with NULL `lpApplicationName` searches the parent's current directory; unquoted paths try `C:\Program.exe` | Microsoft Learn + CodeQL `cpp-unsafe-create-process-call` |
| argv/envp carry no lengths, so embedded NULs are undetectable by the callee | eklitzke + CPython gh-111656 |
| Sonar's argument-injection catalogue and the exact git/tar payloads | sonarsource.github.io/argument-injection-vectors |
| git's `--end-of-options` (2.24), and its uneven subcommand support (rev-parse 2.30.0; checkout/reset 2.43.1) | nesbitt.io writeup — **single source**, see caveat |
| The tree's own live vulnerability and its exact chain | read directly: `shared.av:180`, `:206`, `avra_runtime.c:978`, ROADMAP ledger item (1) |

### MEDIUM — reasoned from strong evidence, not run

- `posix_spawn_file_actions_addfchdir_np` on glibc ≥2.29 and Darwin ≥10.15 is the
  portable way to bind a child's cwd to an fd. **This is the design's load-bearing
  ergonomic claim (L6) and it needs a probe on both platforms before it is promised.**
- Closing all fds in a `posix_spawn` child: the portable answer is `O_CLOEXEC` on
  everything we open plus an explicit close list; `close_range`/`closefrom` is the belt
  in a fork+exec child. `posix_spawn_file_actions_addclosefrom_np` exists on recent
  glibc — **unverified in this session**.
- Landlock layer arithmetic: fs roots + exec targets **must** compile into one ruleset
  because layers are conjunctive and `FS_EXECUTE` is an fs right. Reasoned from the
  kernel docs' conjunctive-layer semantics; not measured.
- One row = one argv element makes `${NAME}` expansion in `[link]` safe against flag
  smuggling. Follows from argv semantics; worth a red-team case.

### LOW — hopes, and what would raise each

| Claim | What would raise it |
|---|---|
| **The T1 emission rules (`--flag=VALUE`, `./path`) are accepted by the tools we care about** | run the corpus against clang, git, tar, ld with every argument in fused/prefixed form. Some tools reject `--flag=value` for short flags; the registry row must then carry the flag's *style*, which is a schema change, not a patch |
| **`fexecve` on Darwin** | probe. If absent, Darwin's L2 claim degrades from "no window" to "a window, printed" — the tier text above already hedges, and must not be un-hedged without the probe |
| **The ergonomics bet, again** | the fs doc's is the same bet and the same answer: **generate 200 programs against this surface with three model families and count first-shot compiles.** If a model writes `process.git.word(user_input)` and F4603 does not turn it into `.after_terminator(...)` in one turn, this design is worse than an argv list |
| **T3 grammars stay honest** | a grammar that drifts from its tool is a false sense of safety. Needs a staleness gate — the fs doc's misnomer registry has the same unsolved problem, called out in its own ledger |
| **`avra caps diff` is computable across a registry** | it needs every dependency's manifest, which package resolution already reads; unproven at scale |

### Citation caveat

Verified above means *fetched or read in this session from a primary or vendor source*.
The following were seen in **one** secondary source only and must be spot-checked before
this document leaves the repo: CVE-2017-1000117 (git), CVE-2017-1000116 (Mercurial),
CVE-2017-9800 (Subversion), CVE-2017-12836 (CVS), CVE-2019-13139 (docker build),
CVE-2021-43809 (Bundler), CVE-2022-24828 (Composer), CVE-2023-5752 (pip),
CVE-2025-68119 (Go), CVE-2026-40938 (Tekton), and jq's GHSA-vf2h-chrj-q3fg. The
**mechanisms** they illustrate are independently confirmed by the Sonar catalogue and by
the verified CVEs above; the identifiers are not. The web-search budget was exhausted
before they could be checked individually — the same failure mode the fs doc records,
and the reason its caveat exists.

---

<a name="sources"></a>
# Sources

**Kernel / OS primitives**
- [Landlock — Linux kernel docs](https://docs.kernel.org/userspace-api/landlock.html)
- [no_new_privs — Linux kernel docs](https://docs.kernel.org/userspace-api/no_new_privs.html)
- [Seccomp BPF — Linux kernel docs](https://docs.kernel.org/userspace-api/seccomp_filter.html)
- [Seccomp and deep argument inspection — LWN](https://lwn.net/Articles/822256/)
- [execveat(2) — man7](https://man7.org/linux/man-pages/man2/execveat.2.html)
- [cap_enter(2) — FreeBSD](https://man.freebsd.org/cgi/man.cgi?query=cap_enter&sektion=2)
- [Capsicum: practical capabilities for UNIX — LWN](https://lwn.net/Articles/482858/)
- [pledge(2) — OpenBSD](https://man.openbsd.org/pledge.2)
- [systemd.exec(5) — ExecPaths=/NoExecPaths=](https://man.archlinux.org/man/systemd.exec.5.en)
- [sudoers(5) — man7](https://man7.org/linux/man-pages/man5/sudoers.5.html)
- [posix_spawn_file_actions_addclose — POSIX](https://pubs.opengroup.org/onlinepubs/9799919799/functions/posix_spawn_file_actions_addclose.html)
- [FIO22-C. Close files before spawning processes — CERT](https://wiki.sei.cmu.edu/confluence/display/c/FIO22-C.+Close+files+before+spawning+processes)
- [CreateProcessW — Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createprocessw)
- [NULL application name with an unquoted path in CreateProcess — CodeQL](https://codeql.github.com/codeql-query-help/cpp/cpp-unsafe-create-process-call/)

**Argument injection**
- [Argument Injection Vectors — SonarSource](https://sonarsource.github.io/argument-injection-vectors/)
- [tar vector](https://sonarsource.github.io/argument-injection-vectors/binaries/tar/) · [git-clone vector](https://sonarsource.github.io/argument-injection-vectors/binaries/git-clone/)
- [`--end-of-options` — Andrew Nesbitt](https://nesbitt.io/2026/07/21/end-of-options.html)
- [GHSA-rpm5-65cw-6hj4 — GitPython, CVE-2026-42215](https://github.com/advisories/GHSA-rpm5-65cw-6hj4)
- [CVE-2023-22809 — sudoedit](https://ubuntu.com/security/CVE-2023-22809)
- [CVE-2024-24576 — Rust security advisory](https://blog.rust-lang.org/2024/04/09/cve-2024-24576/)
- [OS Command Injection Defense — OWASP](https://cheatsheetseries.owasp.org/cheatsheets/OS_Command_Injection_Defense_Cheat_Sheet.html)

**Environment and PATH**
- [CVE-2021-4034 PwnKit — Qualys](https://blog.qualys.com/vulnerabilities-threat-research/2022/01/25/pwnkit-local-privilege-escalation-vulnerability-discovered-in-polkits-pkexec-cve-2021-4034)
- [Bash environment variable code injection (Shellshock) — Red Hat](https://www.redhat.com/en/blog/bash-specially-crafted-environment-variables-code-injection-attack)
- [macOS SIP sanitizes your environment](https://briandfoy.github.io/macos-s-system-integrity-protection-sanitizes-your-environment/)
- [os/exec — Go packages (ErrDot)](https://pkg.go.dev/os/exec) · [golang/go#43724](https://github.com/golang/go/issues/43724)
- [nix-shell — Nix reference manual](https://nix.dev/manual/nix/2.35/command-ref/nix-shell.html)
- [bazelbuild/bazel#6648 — incompatible_strict_action_env](https://github.com/bazelbuild/bazel/issues/6648)
- [How to keep a Bazel project hermetic — Tweag](https://www.tweag.io/blog/2022-09-15-hermetic-bazel/)

**Build-time supply chain**
- [Go Wiki: InvalidFlag — the cgo flag allowlist](https://go.dev/wiki/InvalidFlag)
- [CVE-2018-6574 — golang/go#23672](https://github.com/golang/go/issues/23672)
- [Build Scripts — The Cargo Book](https://doc.rust-lang.org/cargo/reference/build-scripts.html)
- [Rust/Cargo supply chain security — build script risks](https://www.systemshardening.com/articles/cicd/rust-cargo-supply-chain-security/)
- [CVE-2019-5736 — runc container escape](https://www.cve.org/CVERecord?id=CVE-2019-5736)

**Capability runtimes**
- [Deno — Security and permissions](https://docs.deno.com/runtime/fundamentals/security/) · [Permissions reference](https://docs.deno.com/runtime/reference/permissions/)
- [Fuchsia — Process creation](https://fuchsia.dev/fuchsia-src/concepts/process/process_creation) · [Introduction to components](https://fuchsia.dev/fuchsia-src/concepts/components/v2/introduction)
- [WASI — Design principles](https://github.com/WebAssembly/WASI/blob/main/docs/DesignPrinciples.md) · [WASI#26 — remove remaining "process" dependencies](https://github.com/WebAssembly/WASI/issues/26)
- [apple/containerization#737 — sandbox-exec deprecation with no replacement](https://github.com/apple/containerization/issues/737)

**API hazards**
- [subprocess — Python docs (PIPE/wait deadlock)](https://docs.python.org/3/library/subprocess.html)
- [Unexpected places you can and can't use null bytes](https://eklitzke.org/unexpected-places-you-can-and-cant-use-null-bytes)
- [cpython#111656 — embedded NULs](https://github.com/python/cpython/issues/111656)

**In-tree**
- `packages/cli/src/commands/shared.av:176-206` — `link`, `shell_word`, `promises`, `expanded`
- `runtime/avra_runtime.c:975-981` — `avra_shell_exec_status`, `system(cmd)`
- `ROADMAP.md:96-105` (Lane 0), `:145` (`@std/process`), `:5985-6001` (red-team ledger item 1)
- `docs/2026_09_04_THE_ROOT_IS_THE_ONLY_DOOR.md` — Parts II, IV.0, IV.6, V, VI, VIII
