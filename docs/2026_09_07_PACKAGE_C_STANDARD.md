# THE PACKAGE-C STANDARD — where C lives

> **Status:** the standard, written before it is made true. The
> substrate lane (under the HTTP lead) owns this document and the
> migration it orders; every file the migration touches has an owner
> named in §4, and nothing here is written in a peer's file without
> that peer hearing it first. Base for every probe below: `5575a2e`.

## 0. THE STANDARD, IN FIVE SENTENCES

**CORE** — `runtime/avra_runtime.c`, `rt_sigs`, `RtHost`, the
evaluator's host arms — owns ONLY the language's own substrate: boxes
and refcounts, strings, lists, maps, `Bytes`, floats, the process's own
facts (argv, the environment, the clock, exit, the standard streams,
`avra_errno_text`), and DESCRIPTORS — a read from a descriptor into a
fresh `Bytes` box, a write of a box from an offset, and the "taken"
hand-over. **A PACKAGE** owns everything else as its own C under
`packages/<p>/src/c/*.c` (a vendored translation unit under
`packages/<p>/vendor/`): opening, listing and removing files; child
processes; sockets and readiness; SQLite. **A managed value is minted
only by a core row** — that is the safety property, and everything
else here follows from it. Package C answers ints and pointers only,
is built to `build/<stem>.o` by ONE generic Makefile rule, is linked
through the manifest's `[link]`, is declared by `extern fn` in the
package, and is checked by `tools/externs.py`. The evaluator hosts
core rows by arms; a package's externs it hosts through the EXTERN
HOST (S2), and until that lands it refuses them with today's words
("`X` is extern — the evaluator cannot host it; build natively") and
the package is proved by a native-only corpus dir.

## 1. THE ROSTER

What is core and what is a package, by the question that decides it:
**does the row MINT a managed value, or carry a fact only the process
itself can answer?** Yes is core. Everything else is a package.

| substrate | where | why |
|---|---|---|
| boxes, refcounts, clone-on-write (`avra_rc_*`, `*_unique`) | core | the memory model |
| strings, lists, maps, `Bytes`, floats and their vocabulary rows | core | every one mints or reads a box |
| argv (`avra_args_init`, `avra_selfhost_*arg*`) | core | the process's own words, adopted as immortal boxes at entry |
| the environment (`avra_host_env`) | core | the process's own facts, immortal |
| the clock (`avra_now_ns`), exit (`avra_process_exit`), re-exec (`avra_exec_self`) | core | the process's own life |
| the standard streams (`avra_puts`, `avra_eputs`, the capture) | core | the process's own descriptors, and a capture rewires fd 1 |
| `avra_errno_text` | core | immortal text, shared by every package that answers an errno |
| the once cache | core | a process-wide table the language's `once fn` stands on |
| DESCRIPTORS: `avra_fd_read`, `avra_fd_taken`, `avra_fd_write` | core | THE ONE DOOR through which foreign bytes become a value |
| opening, listing, making, removing files; `stat`; mtime | `@std/io` C | host facts; answer ints (a status, a descriptor, a kind) |
| the spawn table, its pipes, its signals, its reaping | `@std/process` C | host facts; answer ints (a handle, its descriptors, a tagged status) |
| sockets and readiness (`avra_net_*`) | `@std/net` C | host facts; answer ints (a descriptor, a count, a NEGATIVE errno) |
| the vendored amalgamation | `@std/sqlite` | not ours; `vendor/`, its author's flags |
| the LLVM binding (`llvm_wrapper.c`) | `@std/avrac` C | the compiler's own foreign library; answers `LLVM*Ref` pointers and ints |

What leaves core under this roster, by name — the whole `avra_io_*`
section, the whole `avra_proc_*` section, and the `avra_net_*` section
now on `lane/http`. What core GAINS: nothing a package could own. The
descriptor rows already stand on `lane/http`
(`avra_fd_read`/`avra_fd_taken`/`avra_fd_write`, runtime lines
1567–1620 in that worktree, uncommitted at the time of writing).

## 2. THE LAWS, AND THE REASON FOR EACH

### 2.1 A MANAGED VALUE IS MINTED ONLY BY A CORE ROW

Every pointer Avra holds carries a sixteen-byte header before its
payload (CLAUDE.md, "EVERY POINTER AVRA HOLDS CARRIES A HEADER"), and
`avra_rc_retain`/`release` read it. A box is therefore a *representation
contract* — tag, kind, refcount, length, the size classes, the free
lists, the accounting — and only the file that DEFINES that contract
can honour it. A package that minted its own boxes would carry a copy
of the contract, and a copy is a law waiting to disagree with itself
(`acc_kind_of` filed every immortal string as a RECORD from the day
`KIND_STATIC` was born, inside the one file that owns the kinds; a
second file would have done no better). So the mint lives in one place
and packages reach it through rows.

The corollary is the whole of the package side's shape: **package C
answers ints and pointers only.** A status, a descriptor, a handle, a
kind, a count, a negative errno; a `ptr` to something C owns. Never a
`string`, never a `Bytes`, never a list. Text and bytes cross INTO the
language only through core's doors (§2.5).

### 2.2 THE EVALUATOR HOSTS CORE BY ARMS AND NEVER LEARNS A PACKAGE

`RtHost` is exhaustive by design: a new row demands its arm, and that
is what makes `eval == native` hold by construction for the language's
own substrate. The same property becomes a defect the moment a
PACKAGE's rows join the enum — the evaluator, which is the LANGUAGE's
second engine, then carries a `NetListen` arm, a `ProcSpawn` arm, an
`IoMkdir` arm, and grows one for every package anyone writes. Sockets
are not a language feature; the evaluator must not know them. Today it
knows twelve process rows and eight io rows, and `lane/http` adds
fifteen net rows: forty-three arms, each a thin call into C the native
program calls directly, each a line the language's engine carries for a
library's convenience.

The standard splits the two: CORE rows are hosted by arms, because
their meaning is the evaluator's business; a PACKAGE's externs are
hosted by ONE mechanism that reads the declaration — the extern host
(S2, `docs/2026_09_05_EXTERN_HOST_SHAPE.md`) — so the evaluator gains
one variant for "a symbol in the image, called through the uniform
frame" and never another. Until it lands, a package's corpus dir is
`native-only` with the trigger recorded on the mark: "the extern host
lands".

### 2.3 A MANIFEST SAYS WHAT TO LINK, NEVER HOW TO BUILD IT

`[link] objects` names an object that must already exist, and `[link]
flags` are words on clang's line. Nothing in a manifest says how the
object came to be, and that is deliberate: a manifest path that the
toolchain WRITES is a write primitive across a dependency boundary
(`BUILD_SEAM.diff`'s own first draft had `[build] object = …`, and a
dependency's manifest could then name the compiler's runtime as its
output). So the manifest reads and never writes.

The HOW is the tree's build, and it is ONE RULE — `build/%.o: %.c` over
every `packages/*/src/c/*.c`, `packages/*/vendor/*.c` and
`backend/*.c` — rather than one hand-written rule per object. Two
reasons. First, a hand-written list is a registry that forgets its
next member: `build/sqlite3.o` had no rule at all for a day, and the
package's suite sat outside the gate because nothing could build what
it links. Globbed, a new package's C is built without a line in the
Makefile. Second, the rule is where the tree's C discipline lives in
one place: our own C takes the runtime's `-Wall -Werror`, a vendored
unit takes its author's flags (`CFLAGS_<stem>`) and none of ours. The
generic rule KEEPS the law by being the only how there is: a package
that wants its object built adds a `.c` under `src/c/` and a `[link]`
row, and nothing else.

What this does not do, recorded rather than argued: it does not
TRAVEL. A consumer outside this tree who adds `@std/sqlite` gets a
manifest naming an object their build never produces. That is ROADMAP
B7 (`[build] sources`, the object DERIVED under the package's own
`build/`), designed in `packages/std-sqlite/BUILD_SEAM.diff` and not
landed. When it lands, the generic rule becomes the fallback for the
compiler's own tree and B7 is the shipping path; the two do not
compete, since both derive the object's path from the source's stem.

### 2.4 PACKAGE C REACHES A BOX THROUGH THE RUNTIME'S EXPORTED VERBS

A package's C receives boxes as arguments — a `string` path, a
`List<string>` argv — and it must read them. It does so ONLY through
the runtime's exported functions (`avra_array_len`, `avra_array_get`,
`avra_str_len`, `avra_bytes_len`), never through a cast to `AvraArray`
or a read before the payload. The runtime's structs are its own; a
package that casts to one has copied the representation contract, and
the day the header or the buffer layout moves, that package reads
garbage with no diagnostic. Today's `words_of` in the process section
casts — it may, since it is inside the file that owns the layout — and
it will not when it moves.

A `string` argument is a NUL-terminated payload (every text box is
minted at n+1 with the terminator written), so C may read it as a
`const char*` for the length of the call; it is borrowed, and a package
that KEEPS what it was handed takes its own reference through
`avra_rc_retain` (CLAUDE.md, "A RUNTIME ROW BORROWS ITS ARGUMENTS").
A `Bytes` never reaches package C: bytes flow OUT through
`avra_fd_write`, which reads the header's length and hands the
descriptor exactly those bytes.

### 2.5 TEXT AND BYTES ENTER THROUGH CORE'S DOORS

Two doors, both core, and a package uses the first wherever it can:

1. **THE DESCRIPTOR READ.** `avra_fd_read(fd, max)` lands up to `max`
   bytes in a scratch; `avra_fd_taken()` mints them as a fresh `Bytes`
   box, ONCE — a second take answers the EMPTY box, never null. This
   is how a file's text, a child's output and a peer's bytes all
   arrive. Package C answers the descriptor; core reads it. The empty
   case is written first (a take after nothing is the empty box), as
   CLAUDE.md's encoding law demands.
2. **THE ADOPTION.** Some host facts are text that flows through no
   descriptor — a directory entry's name is the one case in `@std/io`.
   For those, package C answers a `ptr` to a buffer it owns plus its
   length as an `int`, and ONE core row copies `(ptr, len)` into a
   fresh `Bytes` box. That row is designed in
   `docs/2026_09_06_FOREIGN_TEXT_ADOPTION.md` — a SIGNED length, a
   negative refused as a wreck before it reaches `memcpy`, `(NULL, 0)`
   answering the empty box — and the paper records that its export is
   the OWNER'S decision, put with both halves. **This standard needs
   it for exactly one verb**, and §5 names the fallback so S3 is not
   blocked on it.

What is REFUSED: a package extern that answers `string` or `Bytes`. A
foreign `const char*` typed as `string` is right only for text that is
immortal and NUL-terminated, silently wrong for text with a lifetime,
for bytes, and for text holding a NUL — and `AVRA_RC_GUARD` is blind to
all three, since an untagged pointer raises no event
(`docs/2026_09_06_FOREIGN_TEXT_ADOPTION.md`, "the danger is not HOLDING
it, it is TYPING it"). `@std/sqlite`'s four `string`-answering externs
are the one licensed exception, each read in the amalgamation and
cited by line; a package's own C has no such excuse, because it can
answer a descriptor or a `(ptr, len)` instead.

## 3. THE SHAPE OF A PACKAGE'S C — the checklist

For every package that owns C, in this order; a box unticked is a gap
the package's README names.

- [ ] Its C lives under `packages/<p>/src/c/*.c`, one or more
      translation units, each with a unique stem tree-wide (every
      object lands in `build/`). Vendored C lives under
      `packages/<p>/vendor/` and is never walked by `make idioms`.
- [ ] Its manifest's `[link]` names `../../build/<stem>.o` for each
      unit and the `-l` flags the C needs; nothing else. No `[build]`
      section until B7 registers one.
- [ ] Every C function it exports answers an `int64_t`, a
      `uint32_t`/`int32_t` at a seat that names the width, or a
      pointer. A negative answer is `-errno`, never a C `int` and
      never a sentinel of its own.
- [ ] Every `extern fn` in the package names the width its C
      prototype uses (`i32`/`u32` where the C says `int`/`unsigned`),
      and `make externs` is green — it reads the package's C through
      the manifest and holds every seat and answer to the body.
- [ ] No C function it exports answers `string` or `Bytes`. Text
      leaves C through a descriptor (§2.5.1) or as `(ptr, len)`
      (§2.5.2).
- [ ] It reads a box only through the runtime's exported verbs
      (§2.4); `grep -n 'AvraArray\|Header' packages/<p>/src/c/` is
      empty.
- [ ] A C body that KEEPS an argument retains it; one that answers a
      value it keeps answers it retained (the once cache's shape).
- [ ] Its C carries no `static` state a second process would want
      shared — a handle table is fine (one thread, like every table in
      the runtime); a global that survives `exec` is not.
- [ ] The C's own errors are its caller's to word: the package's
      Avra wraps the `-errno` in its `Error` impl and names the verb
      and the subject (`NetError { verb, subject, errno }` is the
      exemplar).
- [ ] The package's corpus dir under `corpus/<p>/` is `eval == native`
      once S2 lands, else `native-only` with the mark's text naming
      the trigger ("the extern host lands").
- [ ] Its adversarial suite attacks the C boundary as a class: the
      empty case of every representation it consumes (an empty path,
      a zero-length read, a closed descriptor), every seat's width,
      and a hostile `-errno` read back through the package's words.

## 4. THE MIGRATION ORDER, AND WHO OWNS EACH STEP

The order is the dependency order. No step is started past an open
step above it.

1. **S1 — this document and the generic rule.** (substrate lane;
   Makefile is lane A's — messaged through the HTTP lead, since the
   peer-session directory is not reachable from this lane's tools.)
   `build/sqlite3.o`, `build/llvm_wrapper.o` and
   `build/width_witness.o` fold into `build/%.o: %.c`; `witness.c`
   moves to `packages/width-witness/src/c/width_witness.c` so its
   stem names its object. Gate green. DONE when the lead has the doc.
2. **S2 — the extern host.** (lane C's `language/interp.av`; lane A's
   `core/` and `runtime/`; designed with SQLITE-LEAD and lane C.)
   The evaluator calls any linked extern by name through a uniform
   frame over `RtKind` seats; a variadic callee refuses by name. The
   constraint the design must answer, from the extern-host paper §4:
   `avra run` interprets inside `build/avra`, whose image holds
   exactly the objects the `cli` package's dependency closure links —
   `@std/io`'s and `@std/process`'s C will be there by construction
   once S3 and S4 land, and `@std/sqlite`'s will NOT. §5 lists the
   routes. Deliverable: `corpus/sqlite` and `corpus/net` are
   `eval == native`.
3. **S3 — `@std/io`.** (lane B's package; the descriptor rows are the
   HTTP lead's, on `lane/http`.) Opening, `stat`, listing, `mkdir`,
   `remove` stay package C answering ints; `read_text` becomes
   open + `avra_fd_read` loop + close, `write_text` becomes open-temp
   + `avra_fd_write` loop + commit (the rename stays in C, since the
   temp name is the package's); `env` reads core's environment row.
   The eight `avra_io_*` rows, their `RtHost` variants and their
   arms leave core. `corpus/io` stays `eval == native` under S2, or
   is marked `native-only` with the trigger.
4. **S4 — `@std/process`.** (lane B's package.) The spawn table, the
   pipes' descriptors, signals and reaping are package C; the PUMP —
   poll, drain, feed, escalate — moves into Avra over the descriptor
   rows plus one package row for readiness over a handle's
   descriptors. `avra_proc_take`, `avra_proc_write` and
   `avra_proc_stdin_close` die (a read, a write and a close of a
   descriptor); `avra_proc_run`'s one-shot loop is Avra;
   `avra_proc_which` resolves in Avra over a package `executable(path)`
   row. Twelve rows, twelve variants and twelve arms leave core.
5. **`@std/net`** joins the standard as its first NEW consumer — the
   HTTP lead's split, today, from the section on `lane/http` into
   `packages/std-net/src/c/net.c`; the fifteen `NetX` variants and
   rows never reach main.

Debris the migration retires from the runtime, found by grep at
`5575a2e` (zero Avra callers, zero references in `bootstrap/seed.ll`),
lane A's file: `avra_selfhost_file_exists`, `avra_selfhost_read_file`,
`avra_selfhost_write_file`, `avra_host_list_dir`, `avra_mkdir_p`,
`avra_spawn_status` (its own comment names the seed refresh as its
death), `avra_str_codepoint_count`. `avra_host_is_dir` has one caller
and moves with `@std/io`.

## 5. DECISIONS FOR THE LEAD

1. **THE ADOPTION ROW, or the one exception.** `list_dir` is the one
   `@std/io` verb whose text flows through no descriptor. Either the
   adoption row of §2.5.2 lands in core (lane A's seam, the owner's
   decision per its paper) and `list_dir` becomes package C answering
   `(ptr, len)` per entry; or `avra_io_list` STAYS a core row, the
   one io row core keeps, RECORDED at its row with the trigger "the
   adoption row lands". Recommendation: the second for S3, so S3 is
   not blocked on a decision outside this lane, and the row leaves
   core the day adoption lands. Everything else in S3 and S4 needs no
   adoption.
2. **WHERE THE COMPILER'S OWN LLVM BINDING LIVES.** `backend/
   llvm_wrapper.c` is `@std/avrac`'s C under this standard and belongs
   at `packages/std-avrac/src/c/llvm_wrapper.c`; the generic rule
   covers it where it stands today through `backend/*.c`. Moving it
   touches `backend/` (lane A), the README's layout, and
   `tools/externs.py`'s `tree_sources`. Recommendation: move it in a
   slice of lane A's, not this one; the rule already folds its build.
3. **HOW S2 REACHES A SYMBOL THAT IS NOT IN THE COMPILER'S IMAGE.**
   `dlsym(RTLD_DEFAULT)` reaches `@std/io` and `@std/process` once
   they are package C, because the `cli` package depends on both and
   `build/avra` links their objects. `@std/sqlite` is in no dependency
   of the compiler. Three routes, for the design conversation with
   lane C and SQLITE-LEAD: (a) `dlopen` of a per-package dylib built
   from the package's C as a COMPILER artifact in `build/` — the
   capability question the extern-host paper leaves to the owner;
   (b) the evaluator re-linked per package set — keep the compiler's
   own object, and `avra run` of a program whose packages link C
   links `build/avra.o` + those objects into `build/eval-<hash>` and
   re-execs it, no `dlopen`, static, cached by hash; (c) the compiler
   links every package object in the tree, refused — the compiler
   would carry SQLite. This is where S2 may prove larger than one
   slice; the estimate goes to the lead before a line is written.

## 6. PROPOSED FOR LAND D — as questions, not text

Neither is written by this lane; both are put to LAND D through the
HTTP lead.

**A CLAUDE.md rule, under Rules**, in the tree's voice:

> A MANAGED VALUE IS MINTED ONLY BY A CORE ROW, so C THAT IS NOT THE
> LANGUAGE'S OWN LIVES IN A PACKAGE. `runtime/avra_runtime.c`,
> `rt_sigs` and `RtHost` own boxes, strings, lists, maps, `Bytes`,
> floats, the process's own facts and DESCRIPTORS — and nothing that a
> package could own. Files, children, sockets and databases are a
> package's `src/c/*.c`, answering ints and pointers only, linked by
> the manifest's `[link]`, built by the one generic rule, checked by
> `make externs`, hosted in the evaluator through the extern host and
> never through an arm. A package's row in `RtHost` is the evaluator
> learning a library; forty-three arms were, and the standard
> (`docs/2026_09_07_PACKAGE_C_STANDARD.md`) is what moved them out.

**A DOGFOODING idiom, under the NEXT FREE NUMBER**, with its matcher:

> I<n> A PACKAGE'S ROW IN CORE. An `avra_<p>_*` symbol defined in
> `runtime/avra_runtime.c`, or a `RtHost` variant named for a package
> (`Io*`, `Proc*`, `Net*`), is a library living in the language's
> engine. The idiomatic form is the package's own `src/c/` unit and
> an `extern fn`. RATCHETABLE: the matcher greps `runtime/*.c` for
> `^[a-z].* avra_(io|proc|net|sqlite)_` and `core/ir.av`'s `RtHost`
> for those prefixes; the baseline lists today's sites and only ever
> shrinks. Licensed nowhere — a row that must stay is core by the
> roster, and its name says so.

The question for LAND D is whether the rule's second sentence should
name the roster by reference (this document) or carry it in full, and
whether the idiom's prefix list is the right matcher or whether a
manifest-driven one (every package with a `[link]` section names its
own prefix) is.

## 7. RECEIPTS, each at `5575a2e`

- `sh tools/watch.sh 4000 make bootstrap` in this worktree: exit 0,
  peak 556 MB, after waiting on another lane's lock.
- `cc -c -O2 -Wall -Werror -I$LLVM_PREFIX/include backend/llvm_wrapper.c`:
  exit 0. `cc -c -O2 -Wall -Werror packages/width-witness/src/witness.c`:
  exit 0. So the generic rule may hold every non-vendored unit to the
  runtime's warnings without a license.
- Avra callers of the runtime's CLI-facing C, by grep over
  `packages/**/*.av` outside `tests/`: `avra_selfhost_argc` 2,
  `avra_selfhost_get_arg_cstr` 2, `avra_host_is_dir` 1,
  `avra_capture_begin/end` 2 each, `avra_exec_self` 3,
  `avra_process_exit` 7, `avra_case_begin` 3, `avra_host_env` 11,
  `avra_eputs` 5, `avra_puts` 77, `avra_errno_text` 7, `avra_ptr_at`
  3; the seven named in §4 at 0, and 0 in the seed.
- `lane/http` at the time of writing carries the descriptor rows and
  fifteen `Net*` arms in core, uncommitted; `corpus/net` there is
  `native-only` and declares `avra_fd_*` as externs beside
  `avra_net_*`. That is the shape this standard makes permanent for
  the fd rows and temporary for the net ones.
