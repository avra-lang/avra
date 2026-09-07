# THE PACKAGE-C STANDARD — where C lives

> **Status:** the standard, written before it is made true. The
> substrate lane (under the HTTP lead) owns this document and the
> migration it orders; every file the migration touches has an owner
> named in §4, and nothing here is written in a peer's file without
> that peer hearing it first. **Base for every probe and every count
> below: `9fe5597`** — the tree after `@std/net` and `Bytes` landed.
> A receipt from another tree is labelled as one; there are none here.

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
only by a core row** — that is the safety property, and §2.1 shows it
is also a MECHANICAL requirement rather than a preference. Package C
answers ints and pointers only, is built to `build/<stem>.o` by ONE
generic Makefile rule, is linked through the manifest's `[link]`, is
declared by `extern fn` in the package, and is checked by
`tools/externs.py`. The evaluator hosts core rows by arms; a package's
externs it hosts through the EXTERN HOST (S2), and until that lands it
refuses them with today's words — `interp.av:642`, "``X`` is extern —
the evaluator cannot host it; build natively" — and the package is
proved by a native-only corpus dir.

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
| DESCRIPTORS: `avra_fd_read`, `avra_fd_taken`, `avra_fd_write` | core | THE ONE DOOR through which foreign bytes become a value — **externs today, not rows; §2.1 is why that is a live defect** |
| opening, listing, making, removing files; `stat`; mtime | `@std/io` C | host facts; answer ints (a status, a descriptor, a kind) |
| the spawn table, its pipes, its signals, its reaping | `@std/process` C | host facts; answer ints (a handle, its descriptors, a tagged status) |
| sockets and readiness (`avra_net_*`) | `@std/net` C | LANDED; host facts, answering ints (a descriptor, a count, a NEGATIVE errno) |
| the vendored amalgamation | `@std/sqlite` | not ours; `vendor/`, its author's flags |
| the LLVM binding (`llvm_wrapper.c`) | `@std/avrac` C | the compiler's own foreign library; answers `LLVM*Ref` pointers and ints |

What leaves core under this roster, by name — the whole `avra_io_*`
section and the whole `avra_proc_*` section, `avra_io_list` excepted
(§5.1). What core GAINS: nothing a package could own, and the three
descriptor doors as REAL ROWS, which they are not yet.

## 2. THE LAWS, AND THE REASON FOR EACH

### 2.1 A MANAGED VALUE IS MINTED ONLY BY A CORE ROW

The first draft of this section argued the law from the header
contract, and the argument was true but soft. Measuring the tree
turned it into a mechanism, so the header argument is the second
reason now and this is the first.

**ONLY A ROW CAN CARRY `owns_result`, so a mint that is not a row has
no ownership plan.** `rt_owns(name)` (`core/runtime_api.av:217`)
answers from `rt_sig_of(name)` — the CORE registry index over
`rt_sigs()`, keyed by NAME. A program's own extern rows are built by
`extern_row`/`inout_row` (`runtime_api.av:182,188`) with
`owns_result: false` HARD-CODED, and nothing else in the tree ever
writes that field. Two consumers act on the answer:

```
memory.av:431   managed_dst:  .CallRt(_, callee, _) -> if rt_owns(callee) { dst } else { null }
memory.av:293   view_of:      .CallRt(d, callee, _) -> if rt_owns(callee) { null } else { d }
```

The first plans NO RELEASE. The second files the answer as a BORROW of
an argument — for a zero-argument mint, a view of nothing. So an
`extern fn` that answers a managed type leaks every value it mints,
and does so silently: nothing warns, the program is correct, the box
is simply never freed.

MEASURED, `./avra build` then `AVRA_MEM_STATS=1`, loose files:

| program | live at exit |
|---|---|
| `avra_fd_taken()` x 200k | 3 MB, `now == peak` |
| `avra_fd_taken()` x 800k | 12 MB, `now == peak` |
| `avra_str_from_codepoint(65)` x 200k | 0 MB |
| `("a" + "b")` x 200k | 0 MB |

The control is the finding. `avra_str_from_codepoint` is declared
`extern fn` in the SAME loose-file shape and leaks nothing, because its
name is also a core row with `owns_result: true`. The defect is not
"extern"; it is NOT A ROW. It is a leak and not a use-after-free: four
taken boxes pushed into a `List<Bytes>` under `AVRA_RC_GUARD=1` exit
clean, because the pack retains and only the mint's own +1 goes unspent.

Two live instances at this base, and no others — every extern in the
tree answering a managed type was read:

- `avra_fd_taken() -> Bytes`, NOT a row. `packages/std-net/src/net.av:120`
  is `.Ok(.Data(avra_fd_taken()))`, so a server leaks a buffer per read.
- `avra_float_text_bits(bits) -> string` (`language/interp.av:1140`),
  NOT a row; `runtime/avra_runtime.c:1362` ends in `str_owned`. The
  EVALUATOR leaks every float it renders — 60k renders under `avra run`
  left 1 MB of strings live, `now == peak`. Its compiled twin
  `avra_float_text` IS a row (`runtime_api.av:47`) and does not leak.

Clean, and worth naming so the next reader does not re-check them:
`avra_io_taken`, `avra_proc_take`, `avra_proc_which` and
`avra_str_from_codepoint` are rows with `owns_result: true`
(`runtime_api.av:93,98,110`); `avra_errno_text`, `avra_host_env` and
`avra_selfhost_get_arg_cstr` answer immortal text; `@std/sqlite`'s four
`string` externs answer static C strings that were never boxes.

THE SECOND REASON, the one the first draft had. Every pointer Avra
holds carries a sixteen-byte header before its payload (CLAUDE.md,
"EVERY POINTER AVRA HOLDS CARRIES A HEADER"), and
`avra_rc_retain`/`release` read it. A box is a *representation
contract* — tag, kind, refcount, length, the size classes, the free
lists, the accounting — and only the file that DEFINES that contract
can honour it. A package that minted its own boxes would carry a copy
of the contract, and a copy is a law waiting to disagree with itself
(`acc_kind_of` filed every immortal string as a RECORD from the day
`KIND_STATIC` was born, inside the one file that owns the kinds; a
second file would have done no better).

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
second engine, then carries a `ProcSpawn` arm, an `IoMkdir` arm, and
grows one for every package anyone writes. Sockets are not a language
feature; the evaluator must not know them.

The count at this base: nineteen arms are a package's — eight `Io*`,
eleven `Proc*` — each a thin call into C the native program calls
directly, each a line the language's engine carries for a library's
convenience. **`@std/net` is the proof the standard works**: it landed
with fifteen C entry points and added ZERO `RtHost` variants and ZERO
arms. The first draft of this document predicted fifteen `Net*` arms
and was wrong, because the package was built to the standard before
the standard was finished. That non-event is the better receipt.

The standard splits the two: CORE rows are hosted by arms, because
their meaning is the evaluator's business; a PACKAGE's externs are
hosted by ONE mechanism that reads the declaration — the extern host
(S2) — so the evaluator gains one variant for "a symbol in the image,
called through the uniform frame" and never another. Until it lands, a
package's corpus dir is `native-only` with the trigger recorded on the
mark: "the extern host lands".

### 2.3 A MANIFEST SAYS WHAT TO LINK, NEVER HOW TO BUILD IT

`[link] objects` names an object that must already exist, and `[link]
flags` are words on clang's line. Nothing in a manifest says how the
object came to be, and that is deliberate: a manifest path that the
toolchain WRITES is a write primitive across a dependency boundary
(`BUILD_SEAM.diff`'s own first draft had `[build] object = …`, and a
dependency's manifest could then name the compiler's runtime as its
output). So the manifest reads and never writes.

The HOW is the tree's build, and it is ONE RULE — `build/%.o: %.c`
over every `packages/*/src/c/*.c`, `packages/*/vendor/*.c`,
`backend/*.c` AND `runtime/*.c` — rather than one hand-written rule
per object. Three reasons. First, a hand-written list is a registry
that forgets its next member: `build/sqlite3.o` had no rule at all for
a day, and the package's suite sat outside the gate because nothing
could build what it links. Globbed, a new package's C is built without
a line in the Makefile. Second, the rule is where the tree's C
discipline lives in one place: our own C takes `-Wall -Werror`, a
vendored unit takes its author's flags (`CFLAGS_<stem>`) and none of
ours; a header is a source, so `-MMD -MP` and an `-include` of the
`.d` files mean editing a `.h` rebuilds what includes it, which the
hand-written rules never did.

Third, and it is the one the red team found: **ONE HOW FOR EVERY
OBJECT, because a hand-written rule beside the pattern SHADOWS it.**
Make prefers an explicit rule, so while `build/avra_runtime.o` had its
own recipe, a package source named `avra_runtime.c` was compiled by
NOBODY and that package's manifest linked the runtime instead — the
same silent substitution the stem law below refuses, arriving by a
different door. The runtime's recipe and the pattern's were the same
flags in a different order, so folding `runtime/*.c` into the glob
closed the hole as a consequence rather than as a special case. The
variables are `TREE_C`/`TREE_OBJS`, not `PACKAGE_*`: the rule builds
the language's own C too, and a name that claimed otherwise would be
the coverage-versus-label trap CLAUDE.md names.

**A STEM NAMES ITS OBJECT, so a stem is unique tree-wide.** Every
object lands in one flat `build/` and `vpath` answers the FIRST
directory carrying a name, so a package-generic file name is a
collision waiting for the second package that picks it. MEASURED
before the law existed: two packages each given a `src/c/util.c`
produced `build/util.o` TWICE in the object list and compiled only
`@std/io`'s, in silence. The link cannot name that — it fails on a
symbol that does exist in the tree, in a file nothing ever compiled.
So the Makefile names it: `TREE_STEM_LAW` refuses at parse time and
prints every file sharing a stem with "rename one of". Two sources
were renamed in the slice that landed the rule —
`packages/width-witness/src/witness.c` to `src/c/width_witness.c`, and
`packages/std-net/src/c/net.c` to `src/c/std_net.c` — each so that the
object its manifest already named is the object the rule builds.

`tools/stems.sh` is the law's keeper and drives the Makefile's own
three lines with synthetic `TREE_C` values, so the rule and its test
are ONE definition and no file is created to test it. It exercises
BOTH surfaces — four clashes it must refuse by name, four distinct
sets it must accept — and its failure has been witnessed: disarming
`TREE_STEM_LAW` fails four of its eight rows and names each.

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
An `extern fn` lowers to `Ins.CallRt` (`features/fns/lower.av:70`),
which `retained_args` does NOT retain for — so the borrow is the
convention on both sides of the seam, and a package C body that
released what it was handed would free a live box.

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

   **THEY ARE NOT ROWS YET, AND THAT IS §5.3's DECISION.** At
   `9fe5597` the three doors are C in `runtime/avra_runtime.c`
   (lines 1567–1620) reached through `extern fn` declarations in
   `packages/std-net/src/net.av:16-18` and `corpus/net/src/main.av:8-10`
   — no `rt_sigs` entry, no `RtHost` variant, no evaluator arm. Two
   consequences, both real: `avra_fd_taken` leaks every box it mints
   (§2.1, measured), and the evaluator cannot host the fd half of
   `corpus/net` any more than it can host the net half, so that corpus
   dir would stay `native-only` even after S2 hosts `avra_net_*`.
   `@std/io` already has this shape done RIGHT and it is the model:
   `avra_io_read(path)` answers an `I64` and `avra_io_taken()` is the
   mint, and both are rows (`runtime_api.av:104,110`) with
   `owns_result: true` on the take.

2. **THE ADOPTION.** Some host facts are text that flows through no
   descriptor — a directory entry's name is the one case in `@std/io`.
   For those, package C answers a `ptr` to a buffer it owns plus its
   length as an `int`, and ONE core row copies `(ptr, len)` into a
   fresh `Bytes` box. That row is designed in
   `docs/2026_09_06_FOREIGN_TEXT_ADOPTION.md` — a SIGNED length, a
   negative refused as a wreck before it reaches `memcpy`, `(NULL, 0)`
   answering the empty box — and the paper records that its export is
   the OWNER'S decision, put with both halves. **This standard needs
   it for exactly one verb**, and §5.1 names the fallback the lead has
   already chosen, so S3 is not blocked on it.

What is REFUSED: a package extern that answers `string` or `Bytes`.
§2.1 gives the mechanical reason — no row, no `owns_result`, no
release — and the typing gives the second: a foreign `const char*`
typed as `string` is right only for text that is immortal and
NUL-terminated, silently wrong for text with a lifetime, for bytes,
and for text holding a NUL, and `AVRA_RC_GUARD` is blind to all three
since an untagged pointer raises no event
(`docs/2026_09_06_FOREIGN_TEXT_ADOPTION.md`, "the danger is not HOLDING
it, it is TYPING it"). `@std/sqlite`'s four `string`-answering externs
are the one licensed exception, each read in the amalgamation and
cited by line, and they are safe on both counts: the C strings they
answer are static, so there is nothing to free and no lifetime to
outlive. A package's own C has no such excuse, because it can answer a
descriptor or a `(ptr, len)` instead.

**THIS REFUSAL WANTS TO BE A KEEPER AND IS PROSE.** A checklist item
is invisible to the next author; the law belongs in the compiler, as a
refusal by name when an `extern fn`'s answer type is managed and its
symbol is not a registry row. That is §5.4, and no line of it is
written.

## 3. THE SHAPE OF A PACKAGE'S C — the checklist

For every package that owns C, in this order; a box unticked is a gap
the package's README names.

- [ ] Its C lives under `packages/<p>/src/c/*.c`, one or more
      translation units, each with a unique stem tree-wide (every
      object lands in `build/`; §2.3). Vendored C lives under
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
- [ ] No C function it exports answers `string` or `Bytes` — §2.1,
      the leak, and §2.5, the typing. Text leaves C through a
      descriptor (§2.5.1) or as `(ptr, len)` (§2.5.2).
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
   All five objects — `sqlite3`, `llvm_wrapper`, `width_witness`,
   `std_net` and `avra_runtime` — fold into `build/%.o: %.c`; two
   sources are renamed so their stems name their objects; the stem
   law and `tools/stems.sh` land with it (§2.3). One trap was closed
   on the way: the Makefile's default goal was `seed`, so a bare
   `make` — and any `make -p` reading a variable — silently rewrote
   the committed 9.6 MB `bootstrap/seed.ll`. It bit this lane twice
   before it was noticed, both times while probing a variable's
   value. `.DEFAULT_GOAL := avra` now. Gate green. DONE when the lead
   has the doc.
2. **S2 — the extern host.** (lane C's `language/interp.av`; lane A's
   `core/` and `runtime/`; designed with SQLITE-LEAD and lane C.)
   The evaluator calls any linked extern by name through a uniform
   frame over `RtKind` seats; a variadic callee refuses by name. The
   constraint the design must answer: `avra run` interprets inside
   `build/avra`, whose image holds exactly the objects the `cli`
   package's dependency closure links — `@std/io`'s and
   `@std/process`'s C will be there by construction once S3 and S4
   land, and `@std/sqlite`'s will NOT. §5.5 lists the routes.
   Deliverable: `corpus/sqlite` and `corpus/net` are `eval == native`
   — `corpus/net` needs §5.3 as well, since its fd half is unhosted
   for a different reason than its net half.
3. **S3 — `@std/io`.** (lane B's package; the descriptor rows are the
   HTTP lead's.) Opening, `stat`, listing, `mkdir`, `remove` stay
   package C answering ints; `read_text` becomes open + `avra_fd_read`
   loop + close, `write_text` becomes open-temp + `avra_fd_write` loop
   + commit (the rename stays in C, since the temp name is the
   package's); `env` reads core's environment row. Seven of the eight
   `avra_io_*` rows, their `RtHost` variants and their arms leave core;
   `avra_io_list` stays by §5.1. `avra_io_taken` dies into
   `avra_fd_taken`. `corpus/io` stays `eval == native` under S2, or is
   marked `native-only` with the trigger.
4. **S4 — `@std/process`.** (lane B's package.) The spawn table, the
   pipes' descriptors, signals and reaping are package C; the PUMP —
   poll, drain, feed, escalate — moves into Avra over the descriptor
   rows plus one package row for readiness over a handle's
   descriptors. `avra_proc_take`, `avra_proc_write` and
   `avra_proc_stdin_close` die (a read, a write and a close of a
   descriptor); `avra_proc_run`'s one-shot loop is Avra;
   `avra_proc_which` resolves in Avra over a package `executable(path)`
   row. Eleven rows, eleven variants and eleven arms leave core.
5. **`@std/net` — LANDED at `9fe5597`, ahead of this document.** It is
   the standard's first consumer and it never needed the migration:
   fifteen C entry points under `packages/std-net/src/c/std_net.c`, a
   `[link]` naming one object, zero `RtHost` variants, zero evaluator
   arms, `corpus/net` marked `native-only`. What it did NOT do is
   §5.3: it reached the descriptor doors as externs rather than rows,
   and §2.1 is the cost.

Debris the migration retires from the runtime, re-verified by grep at
`9fe5597` (zero Avra callers outside `tests/`, zero references in
`bootstrap/seed.ll`), lane A's file: `avra_selfhost_file_exists`,
`avra_selfhost_read_file`, `avra_selfhost_write_file`,
`avra_host_list_dir`, `avra_mkdir_p`, `avra_spawn_status` (its own
comment names the seed refresh as its death),
`avra_str_codepoint_count`. `avra_host_is_dir` has one caller and
moves with `@std/io`.

## 5. DECISIONS — settled and open

**5.1 THE ADOPTION ROW, or the one exception. SETTLED by the lead.**
`avra_io_list` STAYS a core row — the one io row core keeps — RECORDED
at the row with its trigger (lane A's adoption row). `list_dir` is the
one `@std/io` verb whose text flows through no descriptor, and S3 is
not blocked on a decision outside this lane. The row leaves core the
day the adoption row of §2.5.2 lands. Everything else in S3 and S4
needs no adoption.

**5.2 WHERE THE COMPILER'S OWN LLVM BINDING LIVES. SETTLED by the
lead.** `backend/llvm_wrapper.c` stays in `backend/`. The generic rule
covers it where it stands, through `backend/*.c`. Under the roster it
is `@std/avrac`'s C and would belong at
`packages/std-avrac/src/c/llvm_wrapper.c`; moving it touches
`backend/` (lane A), the README's layout and `tools/externs.py`, and
is a slice of lane A's if it is ever taken.

**5.3 ARE THE DESCRIPTOR DOORS ROWS OR EXTERNS? OPEN, and it is the
one that costs memory today.** §2.1 measures the leak; §2.5.1 shows
`@std/io` already does the same shape as rows. The recommendation is
three `rt_sigs` entries (`owns_result: true` on the take), three
`RtHost` variants and three evaluator arms — which fixes the leak,
makes §0's central sentence true of the tree, and gives the fd half of
`corpus/net` `eval == native` before S2 lands. It touches
`core/runtime_api.av` and `core/ir.av` (lane A), `language/interp.av`
(lane C) and `packages/std-net/src/net.av` (the HTTP lead). A second,
one-line half: `avra_float_text_bits` gains its row beside
`avra_float_text`, both `owns_result: true`, and the evaluator stops
leaking every float it renders.

**5.4 SHOULD THE MANAGED-ANSWER REFUSAL BE A COMPILER LAW? OPEN.**
§2.5's "no package extern answers `string` or `Bytes`" is prose in a
checklist, and prose is invisible to the next author — CLAUDE.md's
EXEMPTION LAW one axis over. As a keeper it is a refusal by name when
an `extern fn`'s answer type is managed and its symbol is not a
registry row, in lane C's typing, with `@std/sqlite`'s four static-text
externs needing a spelled license at the site. Not written.

**5.5a WHAT THE S2 SURVEY MEASURED, before any of it is written.**
Four findings, each against `0998a7c`, and each one a thing the prior
design (`docs/2026_09_05_EXTERN_HOST_SHAPE.md`, the sqlite lane's for
lane C) does not answer.

- THE EVALUATOR HAS NO POINTER. `Val` has eight variants and none is
  an address; `Val.N` is ABSENCE, minted for a null-riding constant.
  So the prior design's `Ptr` return row has nowhere to land, and the
  argument side has the same hole. Lane C's value model decides it,
  and nothing should be built before they do.
- THE VARIADIC REFUSAL IS PLACED WRONG TODAY, by that paper's own
  receipt. It reasons that the refusal belongs at interpretation
  because "the native path can host variadics perfectly well" — but
  `declare`'s vararg flag is hard-wired false at both call sites and
  the grammar has no ellipsis, so the NATIVE path emits a fixed call
  and reads the garbage that paper measured. The refusal belongs at
  the DECLARATION until the grammar can spell a variadic seat, and
  `make externs` already reads each package's real C definitions, so
  it can see the `...` and refuse with a source location.
- §5.3 IS FORCED, NOT OPTIONAL. The host's own law is that a returned
  foreign pointer is never adopted as text. `avra_fd_taken` answers
  `Bytes`. So while the doors are externs, the host must break its own
  law or refuse them, and `corpus/net` can never be `eval == native` —
  which is S2's stated deliverable. The rows are a precondition, not a
  tidy-up.
- THE CAPABILITY OBJECTION IS ALREADY MOOT. That paper worries the
  host widens what the "just look at it" verb can do. `avra run`
  already reaches the host in full through the hosted `Proc*` and
  `Io*` arms: `corpus/process` under the evaluator spawns children,
  captures both streams, feeds stdin, kills one by signal 9, and runs
  a pipeline and a scripted runner. The host adds REACH, not a class
  of power that was denied. Measured, not argued.

AND WHAT TIER 1 BUYS, by comparing every declaration against the
compiler's own symbol table: 235 externs declared tree-wide, 125
already in `build/avra`'s image, 110 not — 88 `sqlite3_*`, 14
`avra_net_*`, 8 `witness_*`. So a `dlsym(RTLD_DEFAULT)` tier hosts a
clear majority on day one and reaches NEITHER corpus S2 names.

**5.5b HOW S2 REACHES A SYMBOL THAT IS NOT IN THE COMPILER'S IMAGE.
OPEN — the owner's, routed through the lead.** `dlsym(RTLD_DEFAULT)` reaches
`@std/io` and `@std/process` once they are package C, because the `cli`
package depends on both and `build/avra` links their objects.
`@std/sqlite` is in no dependency of the compiler. Three routes:
(a) `dlopen` of a per-package dylib built from the package's C as a
COMPILER artifact in `build/` — a capability question for the owner;
(b) the evaluator re-linked per package set — keep the compiler's own
object, and `avra run` of a program whose packages link C links
`build/avra.o` plus those objects into `build/eval-<hash>` and
re-execs it, no `dlopen`, static, cached by hash; (c) the compiler
links every package object in the tree, refused — the compiler would
carry SQLite. This is where S2 may prove larger than one slice; the
estimate goes to the lead before a line is written.

## 6. PROPOSED FOR LAND D — as questions, not text

Neither is written by this lane; both are put to LAND D through the
HTTP lead.

**A CLAUDE.md rule, under Rules**, in the tree's voice:

> A MANAGED VALUE IS MINTED ONLY BY A CORE ROW, so C THAT IS NOT THE
> LANGUAGE'S OWN LIVES IN A PACKAGE — and the reason is mechanical
> before it is architectural: `owns_result` is a field of `RtSig` and
> `rt_owns` reads it from the CORE registry by NAME, so a mint that is
> not a row has no ownership plan and LEAKS, silently, forever
> (`avra_fd_taken` leaked 12 MB in 800k calls; `avra_str_from_codepoint`,
> the same extern shape but a row, leaked nothing).
> `runtime/avra_runtime.c`, `rt_sigs` and `RtHost` own boxes, strings,
> lists, maps, `Bytes`, floats, the process's own facts and
> DESCRIPTORS — and nothing that a package could own. Files, children,
> sockets and databases are a package's `src/c/*.c`, answering ints and
> pointers only, linked by the manifest's `[link]`, built by the one
> generic rule, checked by `make externs`, hosted in the evaluator
> through the extern host and never through an arm. A package's row in
> `RtHost` is the evaluator learning a library; nineteen arms were, and
> `@std/net` landing with ZERO is the proof the split holds
> (`docs/2026_09_07_PACKAGE_C_STANDARD.md`).

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

The question for LAND D is whether the rule's second half should name
the roster by reference (this document) or carry it in full, and
whether the idiom's prefix list is the right matcher or whether a
manifest-driven one (every package with a `[link]` section names its
own prefix) is.

## 7. RECEIPTS, each at `9fe5597` in this worktree

- `sh tools/watch.sh 4000 make bootstrap` after merging `lane/http`:
  exit 0, peak 654 MB.
- `make -B -n` resolves all five objects through the one rule, each
  from the source its stem names: `build/sqlite3.o` (with
  `SQLITE_FLAGS`, no `-Wall -Werror`), `build/llvm_wrapper.o` (with
  `-I$LLVM_PREFIX/include`), `build/width_witness.o`,
  `build/std_net.o`, `build/avra_runtime.o`.
- The rule's `-Wall -Werror` is real, not decorative: a package `.c`
  with an unused local failed the build ("1 error generated"). A
  vendored unit takes none of it — `make -n build/sqlite3.o` shows
  `SQLITE_FLAGS` and no warning flag.
- Header dependencies work: a package `.c` including a new `.h` wrote
  `build/<stem>.d` naming the header, and touching the header
  re-ran the compile.
- The stem law, before it existed: two packages each given a
  `src/c/util.c` put `build/util.o` in the object list TWICE and
  compiled only the first, silently. After: `make` refuses at parse
  time naming both files, exit 2. A package source named
  `avra_runtime.c` was shadowed by the explicit runtime rule and is
  now named by the same law.
- `sh tools/stems.sh`: 8 rows green. With `TREE_STEM_LAW` disarmed:
  4 of 8 fail, each named. Restored: green again.
- `make idioms` (debt 0), `make vocab` (Ins 8 consumers, RtKind 5,
  Type 2), `make externs` (238 externs, 491 parameter seats, 6 C
  sources, 23 of the keeper's own cases): all exit 0.
- The leak, and its control, in §2.1's table. The guard probe
  (`List<Bytes>` of four takes, `AVRA_RC_GUARD=1`) exits 0 with no
  event: a leak, not a use-after-free.
- `RtHost` at this base holds eight `Io*` and eleven `Proc*` variants
  and ZERO `Net*`; the evaluator carries nineteen matching arms.
  `grep` for `avra_fd_read|avra_fd_taken|avra_fd_write` across
  `*.av` and `*.c` outside `tests/` finds exactly three sites: the
  runtime's bodies, `packages/std-net/src/net.av:16-18`, and
  `corpus/net/src/main.av:8-10` — all three declarations, no row.
- Avra callers of the seven debris fns named in §4: 0 each outside
  `tests/`, and 0 in `bootstrap/seed.ll`. `avra_host_is_dir`: 1.
- Every `extern fn` in the tree answering `string`, `Bytes` or a list,
  read one by one for §2.1's "two live instances and no others": 27
  declarations across `packages/` and `corpus/`.
