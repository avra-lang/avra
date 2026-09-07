# THE PACKAGE-C STANDARD — where C lives

> **Status:** the standard, written before it is made true. The
> substrate lane (under the HTTP lead) owns this document and the
> migration it orders; every file the migration touches has an owner
> named in §4, and nothing here is written in a peer's file without
> that peer hearing it first. **Base for every probe and every count
> below: `4516b15`** — this lane's merge of `lane/http` at `5cca925`,
> which carries the descriptor rows, lane C's pattern seam and lane A's
> float and default-goal fixes. Every number here was re-measured at
> that base after two builds; a receipt from another tree is labelled
> as one, and where a relayed count and my own disagree BOTH are
> printed with their bases.

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
| the environment's VALUE (`avra_host_env`) | core | the process's own facts, immortal — and a package adds the PREDICATE beside it (§2.5.3), because the value cannot carry set-from-unset |
| the clock (`avra_now_ns`), exit (`avra_process_exit`), re-exec (`avra_exec_self`) | core | the process's own life |
| the standard streams (`avra_puts`, `avra_eputs`, the capture) | core | the process's own descriptors, and a capture rewires fd 1 |
| `avra_errno_text` | core | immortal text, shared by every package that answers an errno |
| the once cache | core | a process-wide table the language's `once fn` stands on |
| DESCRIPTORS: `avra_fd_read`, `avra_fd_taken`, `avra_fd_write` | core | THE ONE DOOR through which foreign bytes become a value — core ROWS as of `3bfab94`, `owns_result: true` on the take, `RtHost.FdRead/FdTaken/FdWrite` with evaluator arms |
| opening, making, removing files; `stat` | `@std/io` C | host facts; answer ints (a status, a descriptor, a kind) |
| LISTING a directory (`avra_io_list`) | core | an entry's name flows through no descriptor — the ONE io row core keeps, until the adoption row lands (§5.1). The roster said this was the package's for four slices while the tree said otherwise. |
| the extern frame (`ffi.c`) | `@std/avrac` C | the compiler's own machinery, in no user's binary (§5.6.1) |
| the spawn table, its pipes, its signals, its reaping | `@std/process` C | host facts; answer ints (a handle, its descriptors, a tagged status) — and it reads NO box at all, which is stronger than §3 asks (§2.5.3) |
| sockets and readiness (`avra_net_*`) | `@std/net` C | LANDED; host facts, answering ints (a descriptor, a count, a NEGATIVE errno) |
| the vendored amalgamation | `@std/sqlite` | not ours; `vendor/`, its author's flags |
| the LLVM binding (`llvm_wrapper.c`) | `@std/avrac` C | the compiler's own foreign library; answers `LLVM*Ref` pointers and ints |

What leaves core under this roster, by name — the whole `avra_io_*`
section and the whole `avra_proc_*` section, `avra_io_list` excepted
(§5.1). What core has GAINED: the three descriptor doors as real rows,
and nothing a package could own.

## 2. THE LAWS, AND THE REASON FOR EACH

### 2.1 A MANAGED VALUE IS MINTED ONLY BY A CORE ROW

The first draft argued this from the header contract, and the argument
was true but soft. Measuring the tree turned it into a mechanism, and
then lane A narrowed the mechanism into a law that is exact. Theirs is
the wording that stands:

> AN EXTERN WHOSE C BODY MINTS AN OWNED BOX MUST BE A ROW, because
> `owns_result` lives on a row and nowhere else — and an extern
> answering foreign or immortal text must NOT be, for the same reason.

**WHY ONLY A ROW CAN CARRY IT.** `rt_owns(name)`
(`core/runtime_api.av`) answers from `rt_sig_of(name)` — the CORE
registry index over `rt_sigs()`, keyed by NAME. A program's own extern
rows are built by `extern_row`/`inout_row` with `owns_result: false`
HARD-CODED, and nothing else in the tree ever writes that field. Two
consumers act on the answer: `managed_dst` plans NO RELEASE, and
`view_of` files the answer as a BORROW of an argument — for a
zero-argument mint, a view of nothing. So an extern that mints and
answers a box leaks every one, silently: nothing warns, the program is
correct, the box is never freed.

MEASURED WHEN IT WAS BROKEN, `./avra build` then `AVRA_MEM_STATS=1`:
`avra_fd_taken()` 200k times left 3 MB live and 800k left 12 MB, `now
== peak` both times, while `avra_str_from_codepoint(65)` — declared
`extern fn` in the SAME loose-file shape but a core row — left 0 MB.
The control was the finding: the defect is not "extern", it is NOT A
ROW. It was a leak and not a use-after-free; four taken boxes pushed
into a `List<Bytes>` under `AVRA_RC_GUARD=1` exited clean, because the
pack retains and only the mint's own +1 went unspent.

**AND THE OTHER HALF IS WHY A REFUSAL BY ANSWER TYPE WOULD BE WRONG.**
Most externs answering `string` answer memory that was never ours —
`str_static`'s immortal text, or a library's rodata. Making one of
those a row would file it for release, and the release would write
memory that is not ours. So the two cases look identical on the Avra
side and only the C BODY tells them apart, which is why the keeper
lives in `tools/externs.py` (lane A's, prototyped and landing): a C
function is an owned mint when its body reaches
`str_owned`/`box_alloc`/`sized_box` through a `return`, excluding
`str_static`. A compiler diagnostic keyed on the answer TYPE was
designed and WITHDRAWN for exactly this — it would refuse every
foreign-text extern to catch one real leak, and a lint's true-positive
rate is its spec.

THE FIXTURE IS THE WHOLE POPULATION, and it is small enough to name.
Measured at `4516b15`: thirteen extern declarations answer a managed
type; five are not rows and all five are correct as they stand —
`avra_selfhost_get_arg_cstr` (argv through `str_static`) and
`@std/sqlite`'s `libversion`, `sourceid`, `errstr` and
`compileoption_get` (the amalgamation's rodata). The sixth,
`avra_float_text_bits`, DID mint through `str_owned` and leaked every
float the evaluator rendered; it is a row now with its own
`RtHost.FloatTextBits` — not `RtHost.Text`, whose seat is an `F64`.
**TWO COUNTS, RECONCILED, AND THE RECONCILIATION IS THE USEFUL PART.**
A relayed count of seven named `sqlite3_errmsg` as a sixth foreign
case. It is not declared as an extern anywhere in this tree — the
match was a MARKDOWN line, `packages/std-sqlite/src/c/CENSUS.md:213`,
which spells `extern fn sqlite3_errmsg(db: ptr) -> string` as a
PROPOSAL while the real declaration beside it answers `ptr`. The grep
that found it was scoped to `packages/` without restricting to `.av`,
so a document describing a declaration was counted as one. Restricted
to `.av` that count is twelve at its own base and thirteen here, which
is the same measurement one merge later. Both are printed because
neither lane is wrong about its own tree, and a fixture built from the
unrestricted number would have had a member that does not exist.

IT IS THE SAME MISTAKE THIS LANE MADE IN THE OTHER DIRECTION, ONE
SECTION DOWN: §4's debris list read two live names as dead because its
grep was scoped to `packages/` and missed `corpus/`. One window was
too wide by file type and one too narrow by directory, and both
produced a confident count. A COUNT IS A CLAIM ABOUT A WINDOW —
whoever quotes one owes the window with it.

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

AND THE MEASUREMENT ITSELF HAS A RULE. A memory-pass or ownership
change reaches the COMPILER'S OWN BODY only on the second build:
`make avra` compiles the source with the standing binary, so a product
built once carries the fix as source while its own body was compiled by
the binary that predated it. Lane A measured their float leak after one
build and read the identical number. A compiled user program needs one
build; anything the evaluator or the compiler itself exercises needs
two.

### 2.2 THE EVALUATOR HOSTS CORE BY ARMS AND NEVER LEARNS A PACKAGE

`RtHost` is exhaustive by design: a new row demands its arm, and that
is what makes `eval == native` hold by construction for the language's
own substrate. The same property becomes a defect the moment a
PACKAGE's rows join the enum — the evaluator, which is the LANGUAGE's
second engine, then carries a `ProcSpawn` arm, an `IoMkdir` arm, and
grows one for every package anyone writes. Sockets are not a language
feature; the evaluator must not know them.

The count at `4516b15`: nineteen arms are a package's — eight `Io*`,
eleven `Proc*` — each a thin call into C the native program calls
directly, each a line the language's engine carries for a library's
convenience. **`@std/net` is the proof the standard works**: it landed
with fifteen C entry points and added ZERO `RtHost` variants and ZERO
arms. The first draft of this document predicted fifteen `Net*` arms
and was wrong, because the package was built to the standard before
the standard was finished. That non-event is the better receipt.

The three `Fd*` arms core gained in the same week are the counter-case
that shows the line is drawn by the ROSTER and not by a quota. They
are core because they MINT, and §2.1 is why only core can. A package's
row is the evaluator learning a library; a descriptor door is the
evaluator learning how bytes become a value, which is its own
business.

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
vendored unit takes its author's flags and none of ours; a header is a
source, so `-MMD -MP` and an `-include` of the `.d` files mean editing
a `.h` rebuilds what includes it, which the hand-written rules never
did.

**`CFLAGS_<stem>` IS NOT ONLY FOR VENDORED UNITS**, which is a
correction the FIFTH consumer made — a package this lane did not
write. `@std/sqlite`'s destructor sentinel is OUR C, held to our
warnings, and it still needed `CFLAGS_sqlite_sentinel :=
-Ipackages/std-sqlite/vendor` because it includes a header outside its
own directory. So the claim above holds for the OBJECT and not for the
FLAGS: a new package's C is built with no line, and one line is owed
the moment it reaches past itself for a header. The paragraph read as
"vendored units only" until a consumer needed otherwise.

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

**AND THE STEM LAW GUARANTEES ONE OBJECT PER STEM. IT HAS NEVER
GUARANTEED ONE SYMBOL PER NAME**, and S2c is where that distinction
becomes observable for the first time. Under a flat image two packages
exporting one name collide at link time and somebody notices. Under
per-handle lookup they resolve PER HANDLE and nobody does — a program
reaches only what its own manifest named, which is strictly SAFER and
is exactly why the moved guarantee will go unnoticed. This gets its
own line rather than a note beneath the stem law for that reason: a
reader who has just read "a stem is unique tree-wide" will carry it to
symbols unless told here that it does not reach them.

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

THREE shapes, and the third is the one this section did not have when
four packages were built against it — see §2.5.3, which is a review
round's finding against this document rather than against the tree.

1. **THE DESCRIPTOR READ.** `avra_fd_read(fd, max)` lands up to `max`
   bytes in a scratch and answers a TOKEN — the scratch's generation;
   0 at EOF, a negative errno otherwise. `avra_fd_taken(token)` mints
   that landing as a fresh `Bytes` box, ONCE, and TRAPS on a stale or
   spent token. This is how a file's text, a child's output and a
   peer's bytes all arrive. Package C answers the descriptor; core
   reads it. The empty case is written first: a landing of zero bytes
   answers a token whose take is the empty box.

   **THE TOKEN REPLACED A BARE TAKE, and the reason is worth keeping**
   — a shared scratch with an unkeyed take is a WINDOW a deferred read
   steps into, so the second reader gets the first reader's bytes with
   nothing to say so. The generation makes that unspellable rather
   than unlikely, and the same reasoning shaped `@std/process`'s stage
   (§2.5.3) one slice later. This paragraph said "a second take
   answers the EMPTY box, never null" for four slices after that
   stopped being true, which is what a receipt costs when the design
   it describes moves underneath it.

   **THEY ARE ROWS**, as of `3bfab94` — `rt_sigs` entries with
   `owns_result: true` on the take, `RtHost.FdRead/FdTaken/FdWrite`,
   and evaluator arms. They were `extern fn` declarations against
   runtime C for one slice, and §2.1's leak is what that cost: every
   socket read kept its buffer. Re-measured here at `4516b15` after
   two builds — 800k takes, 0 MB live natively, and the EVALUATOR now
   hosts them rather than trapping, 40k takes through `avra run` at
   0 MB. `@std/io` already had the shape done right and was the model:
   `avra_io_read` answers a count and `avra_io_taken` is the mint,
   both rows. The fd pair is that pair generalized from a path to a
   descriptor.

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

3. **THE PREDICATE SPLIT — the shape that needs no door at all, and
   the one this section was missing.** Some host facts are text the
   language ALREADY has a core row for, and what the package must add
   is not the value but a QUESTION only C can answer. `@std/io`'s
   `env` is the instance: the runtime's environment row answers "",
   for a variable that is unset AND for one set to nothing, so the
   value alone cannot tell them apart — the package's C answers the
   PREDICATE (0 set, -1 not) and the language assembles the answer
   from core's existing row. `@std/process`'s `which` is the same
   shape: C answers `executable(path)` and the SEARCH is the
   language's walk.

   IT WAS INVENTED TWICE BECAUSE THIS SECTION DID NOT NAME IT. S3
   reached for it when a package's C turned out to be unable to reach
   the runtime's scratch at all (`fd_landed` is static, and the door
   that would open it is §2.5.2's adoption row, the owner's); S4
   reached for it again without recognising the repetition until the
   review round. A shape found twice by accident is a shape the
   document owed its readers.

   THE TEST: before designing a door, ask whether core ALREADY answers
   the value and the package need only answer the question. Two of the
   four migrations needed no door once that was asked.

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

**THIS REFUSAL WANTS TO BE A KEEPER AND IS PROSE** — and the keeper is
not the compiler. It reads the C BODY, not the Avra answer type, for
the reason §2.1 gives: a refusal keyed on the answer would refuse five
correct foreign-text externs to catch one real leak. It is lane A's,
in `tools/externs.py`, and §5.4 records the diagnostic that was
designed and withdrawn in its favour.

### 2.6 A STAGE THAT CROSSES THE SEAM CANNOT BE SPARSE OR STALE

Some values cannot cross as one argument. A spawn's argv and
environment are lists, and a list cannot reach a package's C at all —
the evaluator holds one as a HANDLE into its own table, never as a
box, so the extern frame refuses it. The words are LANDED one at a
time and the act consumes them, which is this tree's land-then-act
idiom a fourth time.

A stage kept between calls has exactly two ways to be wrong, and both
must be made UNSPELLABLE rather than checked, because a stage that CAN
be written wrong will be.

**SPARSE — a hole that reads as a value.** An index-keyed
`word(i, text)` can be called with 0 and 2 and never 1, and the
missing slot arrives at the child as an EMPTY ARGUMENT rather than as
an error: a command silently one word short, in the right shape. The
answer is that there is no index. `word(text)` APPENDS and answers the
new count, so the third word cannot exist without the second.

**STALE — another call's words spent by this one.** A caller that
stages and then fails BEFORE acting leaves the words standing, and the
next act spends them. "Clear on the act" does not close this: the
abandoned stage is never reached by an act at all. The answer is a
GENERATION — every stage carries one, and a token from an abandoned
stage is refused by every verb that takes it, the act included.

THE EMPTY CASE IS THE FIRST CASE, as CLAUDE.md's encoding law demands:
a stage opened and acted on with NOTHING landed is a legitimate act,
not an error. And an oversized stage refuses by a named errno rather
than truncating — a cap that truncates is the bound-after-the-work
mistake in another costume.

**WHY THIS LIVES HERE AND NOT IN CLAUDE.md.** It was offered as a
tree-wide law and lane D declined it, rightly: CLAUDE.md is loaded
into every session, and a law that fires for one mechanism in one
package pays rent from everyone. RECORDED TRIGGER: it becomes a law
the day a SECOND mechanism shows the shape. The descriptor scratch's
generation is its cousin and not a second instance — that guards one
scratch against a deferred read, where this guards a multi-call
sequence against abandonment.

### 2.7 A STRING CROSSING TO C IS ONE STRING

Avra measures text by the header's length; C reads to the first NUL.
So a string holding one is TWO VALUES at the seam — the guard and the
callee inspect different bytes, and a name that was checked is not the
name that is used. `@std/io` measured what that costs: a 79-byte path
ending `/../../etc/passwd` read a 5-byte file and `exists` answered
true for a path that does not exist, identically on both engines.

**THE CHECK IS AT THE CROSSING AND NOWHERE ELSE.** One C helper,
`avra_str_crossing`, called from both seams — the native lowering
emits it at every non-inert text seat, and the extern frame's text
staging calls the same function. That is what makes it impossible for
the engines to disagree about which strings may cross. A NUL traps
with the offset in its words and exit 2: never a truncation, never an
escape, never a quieter spelling that gets through.

**WHAT MATURE RUNTIMES DO**, because this is not novel and the design
should not pretend it is. Rust's `CString::new` answers a `NulError`
carrying the position. Go's `syscall.ByteSliceFromString` answers
`EINVAL`. Python raises `ValueError: embedded null byte`. Node throws
`ERR_INVALID_ARG_VALUE`. PHP's long history of truncating instead is
the counter-example each of them was written against.

**THE TRAP GOVERNS ONLY WHAT THE CALLEE RESOLVES**, and that boundary
is the whole of it. A path, a name, a command word, an environment key
— where a NUL makes TWO names and no correct answer exists. Everywhere
else there IS a correct answer and the fix is to give it, not to
refuse: a row that reads the header's length treats a NUL as DATA and
carries it through untouched.

That distinction cost this slice a correction. `avra_puts` and
`avra_eputs` were first marked CHECKED because `fputs` truncates a
line at a NUL — but writing bytes RESOLVES nothing, so trapping was
the wrong tool. They read the header's length now
(`fwrite(s, 1, str_len(s), …)`), a NUL-bearing line prints WHOLE on
both engines where it was silently cut before, and only then is their
row honestly `inert`.

**THE EXEMPTION'S POLARITY IS THE POINT.** `inert: true` says THIS ROW
READS THE HEADER'S LENGTH; A NUL IS DATA TO IT. THE DEFAULT IS
CHECKED, because an `exempt: false` default makes forgetting the field
identical to deciding it and the forgetting is silent. A package's
extern can NEVER be inert — its C is not ours to certify, and the
constructors that build an extern's row leave the field at its
default, so that holds by construction rather than by discipline.
Eighty rows are inert; TWO are not, `avra_host_env` and
`avra_io_list`, and both resolve.

**AND "BY CONSTRUCTION" WAS TOO STRONG BY EXACTLY ONE CASE**, which
the red team found by declaring one. A DECLARATION THAT NAMES A ROW
*IS* THE ROW: both engines ask `rt_index()` before the program's own
externs, so a same-named extern's seats and answer are DISCARDED and
the call is made on the ROW's shape. It inherits the row's `inert`
along with everything else — which is sound, because it inherits the
row's C and its certification too. What was NOT sound is that the
declaration's own shape was thrown away in silence:
`avra_host_env(a: string, b: string) -> int` over a one-seat row built
and ran, and handed the program 4294967295-shaped garbage — a RAW
POINTER as an `int` natively, nothing at all under the evaluator. Two
engines, two wrong answers, no diagnostic. **F2065** holds it now: an
`extern fn` naming a row wears that row's arity, seat kinds and answer
kind, or it names its own C something else. It fires nowhere in the
tree, which is the point — every existing redeclaration already
agreed, and nothing said so.

**THE GUARD READS THE SAME BYTES THE CALLEE WILL.** It asks the HEADER
directly and never `str_len`, whose fallback is `strlen` for a pointer
that is not ours — and a scan bounded by `strlen` can never find an
interior NUL. It would pass every foreign string VACUOUSLY while
looking exactly like a check, which is this tree's guard-and-guarded
law firing inside the guard itself. A foreign pointer has no interior
NUL by definition, so the check is SKIPPED there, visibly, rather than
performed on a length that makes it meaningless.

**THE FACES REFUSE FIRST, AND THIS IS THE BELT.** `@std/io`'s
`Holed(path, at)` and `@std/process`'s guard refuse with words a
program can HANDLE, before any C is reached. The trap is what stands
behind a face nobody wrote.

**THE RULE IN THREE SENTENCES.** A text seat the callee RESOLVES is
checked. A seat whose prototype CARRIES ITS OWN LENGTH is `Bytes`. A
NUL inside a `Bytes` is data.

**AND THE EXCEPTION IS NOT "A PACKAGE THAT MEANS OCTETS".** That is an
intention, and an intention cannot be held to. It is "A SEAT WHOSE
PROTOTYPE CARRIES ITS OWN LENGTH" — which is greppable in the header
beside the seat, so `make externs` holds it: a `const char*` beside
a length parameter is `Bytes`, a bare one is checked. The sqlite
lead's wording, and it is better than mine was.

**AND UNTIL THE RED TEAM, `make externs` DID NOT HOLD IT.** `Bytes`
was not in the keeper's `DEMANDS`, so `seat_fits` ABSTAINED on every
`Bytes` seat — the sentence above described a keeper that did not
exist, which is the intention it refuses, one level up. Declaring
`sqlite3_stricmp(const char*, const char*)` with `Bytes` seats
restores the truncation in full: "ab\0cd" and "ab\0ce" compare EQUAL
on both engines, where `memcmp` over the same five bytes does not. The
rule is enforced now, and WRITING IT TAUGHT IT SOMETHING. A PROTOTYPE
IS NOT THE ONLY WAY A CALLEE KNOWS THE LENGTH: three of our own seats
carry none and are RIGHT — `avra_str_len`, `avra_utf8_bad_at` and the
frame's `avra_ffi_set_bytes` read the Avra box's HEADER, which is core
doing what §2.1 says only core may. So the exemption is earned by the
callee KNOWING the length, from the prototype OR from the box, and a
body this tree did not write knows only what its prototype says. The
keeper's scope is FOREIGN C — a body under `packages/*/vendor/` — with
two limits written at the rule: an integer after the pointer may be a
length or a flag and no spelling tells them apart, and a package's own
C is trusted the way core's is though nothing certifies it.

`sqlite3_bind_text(stmt, i, text, n, …)` is the shape. Their driver
has FOUR such seats — `bind_text`, `bind_blob`, `keyword_check` and
`prepare_v3`, the last being the hottest in the package, on the path
of every prepare — and as `string` seats every SQL statement in every
program would have paid an interior-NUL scan per call. As `Bytes`
seats they pay none, by the seat's own type.

**AND THE MIGRATION, NOT THE VERB, WAS THE HAZARD.** The sqlite lead's
framing, better than the one this section shipped with. Changing those
four seats from `string` to `Bytes` is arithmetic on signatures right
up to the moment it changes who HOLDS the value — and
`bind_text_unsafely_borrowed(…, value)` promises the caller's bytes
outlive the statement, which is keepable only because the caller's own
box goes straight through. Migrating the WALL seat while the FACE kept
`string` would have forced the face to call `.bytes()`, minting a box
whose only holder is that call: dead at return, a dangling pointer
handed to SQLite every time, with the caller having done nothing
wrong. A TYPE MIGRATION CAN MOVE WHO HOLDS A VALUE, AND A LIFETIME
PROMISE IS A PROMISE ABOUT THE HOLDER. So the face takes the new type
too, and the type now says what the contract always required.

THE SEATS WHERE THIS BITES ARE FEW AND GREPPABLE — the ones whose
contract mentions LIFETIME. It is a TWO-INSTANCE law, and lane D holds
the second: one level down, a box materialised ONLY to be staged has
no other holder, so its last reference dies before the call and C
reads freed memory. The engines disagreeing is how that one was seen,
and the frame holds staged boxes until the call returns because of it.

**A LIBRARY REFUSES BEFORE THE LANGUAGE TRAPS.** The sqlite lead's
principle, adopted here. Their guards answer a `Result` with a named
cause at exactly the seats the callee resolves, because the driver
knows WHY a seat resolves — a NUL path opens a private temporary
database deleted at close. The seam's trap is the FLOOR for a package
that has not thought about it. Neither makes the other redundant, and
the trap firing inside a package that HAS guards is a bug in the
guards.

**THE COST OF THE LAYERING, MEASURED.** A value that came through a
guard is scanned once there and again at the crossing. At the hot
length-carrying seats that second scan is ZERO, because those are
`Bytes`: a bind plus step plus reset with an 80-byte value is about
400 ns and none of it is a crossing scan. The double scan remains only
at the seats the callee resolves, which is where both layers are
wanted.

**THE COST, AT THREE SCALES.** The inert rows pay nothing, which is
why the framer benches are unchanged — and their spreads overlap
completely across the change, which confirms no regression rather than
proving a number.

At a TYPICAL size, 400,000 crossings of a 128-byte name: 142 ns per
call with the check against 136 without, medians of three runs with a
132-183 spread on a machine shared by eight sessions. Below the noise
floor of the `getenv` it guards.

At the WORST case, 200 crossings of a 1.18 MB name: 82 ms with against
76 ms without, and the runs are 82/82/82 against 76/77/78 — tight
enough that the signal is real where the smaller one was not. That is
25 µs added per megabyte-sized crossing, about 47 GB/s for the scan, a
figure worth stating because it is the sanity check lane A insists on:
a throughput above memory bandwidth means the loop was hoisted, and
this one is cache-resident and plausible.

A BENCHMARK THAT REPEATS ITS ARGUMENT MEASURES NOTHING. Lane A read
`strstr` at 1.8 µs against `memmem` at 692.7 µs — a 385x regression
that was 580 GB/s and physically impossible — because `strstr` is
declared pure and the loop was hoisted to one call. The bench above
cycles eight DISTINCT megabyte strings for that reason, and computes
its implied throughput so the impossible answer cannot be believed.

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
      empty. BETTER, AND `@std/process` PROVED IT REACHABLE: it reads
      no box AT ALL. An aggregate seat cannot cross the extern frame
      anyway — the evaluator holds a list as a handle, not a box — so
      the words are STAGED one at a time, and the cast the checklist
      tolerates simply dies.
- [ ] A STAGE IT KEEPS BETWEEN CALLS CANNOT BE WRITTEN SPARSE OR ACTED
      ON STALE, and both are STRUCTURAL rather than checked (§2.6): an
      append that answers the count leaves no index to hole, and a
      generation refuses a token from an abandoned stage. The empty
      stage acts; an oversized one refuses by name.
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
   the committed `bootstrap/seed.ll`. It bit this lane twice before it
   was noticed, both times while probing a variable's value. Lane A
   found and fixed it independently on main, and the merge left the
   fix stated TWICE with different prose — this lane's copy is dropped
   and theirs stands, since it sits where the seed rule does and its
   size figure is the current one. MERGED into `lane/http` at
   `e45f818`, the Makefile taken whole; `corpus/net`'s manifest kept
   the lead's shape rather than this lane's `[link]` row, because the
   corpus program was rewritten to speak the package's face.
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
3. **S3 — `@std/io`. DONE.** Its C is
   `packages/std-io/src/c/std_io.c`, ten entry points answering ints
   only: `kind`, `open`, `close`, `mkdir`, `remove`, the durable-write
   four (`temp`, `temp_fd`, `commit`, `drop`) and `env_set`. Seven
   `avra_io_*` rows, seven `RtHost` variants and seven evaluator arms
   left core; `avra_io_list` stays by §5.1 and now lands in the ONE
   descriptor scratch, answering its token. `read_text` is open plus a
   read loop plus close; `write_text` is a temp, a write loop and a
   commit, with `defer drop(h)` on both paths.

   THREE THINGS WORTH KEEPING FROM IT. **`corpus/io` DID NOT BECOME
   NATIVE-ONLY** — it stays `eval == native == expected`, because the
   compiler's own image links `@std/io` and S2a's host resolves the
   package's C. The regression window was zero, which is what ordering
   S2a first bought; predicted by the lead and measured here.

   **THE ENVIRONMENT COULD NOT MOVE THE WAY IT WAS SPECIFIED**, and
   the reason was mechanical: routing the value "through the
   descriptor scratch" needs `fd_landed`, which is `static` in the
   runtime with no exported door — the adoption row of §2.5.2, the
   owner's to export. The shape that needs no door splits the
   question: the package's C answers the PREDICATE (`env_set`, 0 set
   and -1 unset) and core's existing environment row answers the
   VALUE. That keeps the distinction the ruling was protecting — the
   host hands back "" for a variable that is unset AND for one set to
   nothing, so the value alone cannot tell them apart — and it needs
   nothing new in core.

   **AND `read_text` GAINED A REFUSAL**: bytes are now checked for
   UTF-8, so `IoError.NotText` is possible where the old path handed
   back whatever was on disk typed as `string`. That is the standard's
   own §2.5 logic reaching the package's API. It cannot be provoked
   from inside the package — every Avra `string` is already valid
   UTF-8, so `write_text` cannot build the file its own refusal is
   for — which is recorded as the absence of a test case rather than
   papered over with one that asserts the wrong thing.

   **THE TWINS, CHECKED — and the answer is stronger than "they
   agree".** Every one of the seven evaluator arms that left core was
   `Val.I(avra_io_x(self.text_val(vals[0])))` — a direct call into the
   SAME C body the native path calls. Not one canned a value,
   simplified, skipped an effect or answered a fixed handle. They were
   never two implementations: they were ONE body reached through TWO
   declarations, `interp.av`'s and `@std/io`'s, which at the pre-S3
   commit are byte-for-byte identical and were each held to that body
   by `make externs`. So there was nothing to drift, and after the
   move there is one declaration where there were two. (Checked after
   the writing rather than before it, which was the instruction; the
   result would have been the same and the order was not.)

   **AND THE COLD PATH BROKE, WHICH ONE EDIT DOES NOT FIX.** Deleting
   seven runtime symbols leaves the committed seed referencing symbols
   that no longer exist: `make bootstrap` fails on
   `avra_io_env/kind/mkdir/read/remove/taken/write`. Three of those
   seven live in the package's object and are reached by naming it in
   the compiler's link list — necessary, and not sufficient. The other
   FOUR (`read`, `write`, `taken`, `env`) exist NOWHERE in the tree by
   design, so only a SEED REFRESH restores the cold path. A slice that
   removes a runtime symbol owes one, and the receipt is
   `make bootstrap` green rather than `make avra` green — the second
   never touches the seed. The failed link also DELETES `build/avra`,
   which is why the protocol saves it aside first.

4. **S4 — `@std/process`. DONE.** Its C is
   `packages/std-process/src/c/std_process.c`, fourteen entry points
   answering ints. Eleven rows, eleven `RtHost` variants and eleven
   arms left core; 525 lines of C left the runtime. The pump — poll,
   drain, feed, escalate — is Avra, over the descriptor rows.

   THE ARGUMENT LIST COULD NOT CROSS THE FRAME, which the migration
   order did not anticipate: a spawn took `List<string>` argv and
   envp, and that works only while it is a runtime ROW, because the
   evaluator holds a list as a HANDLE and a package's extern cannot be
   handed one. The words are STAGED instead — land-then-act a fourth
   time — which also kills §2.4's cast rather than moving it.

   THE PUMP'S RULES ARE ORDER, NOT GRANULARITY, and that is why the
   turn length never needed tuning: a deadline already passed fires
   before any poll, a timeout sweeps before it declares, and the drain
   grace is a floor. Two of those are opposite orderings around one
   event, which is why no turn size satisfies both.

   `corpus/process` kept both engines and the SEAM GAINED one:
   `corpus/native/process_seam.av` could not survive the move, since a
   loose file cannot link a package's object, so it is `corpus/proc-seam`
   and it is `eval == native` where it was native-only.

5. **`@std/net` — LANDED ahead of this document.** It is the
   standard's first consumer and it never needed the migration:
   fifteen C entry points under `packages/std-net/src/c/std_net.c`, a
   `[link]` naming one object, zero `RtHost` variants, zero evaluator
   arms. What it did not do at first was §5.3 — it reached the
   descriptor doors as externs rather than rows, and §2.1 is what that
   cost — and that is closed. `corpus/net` speaks the package's face
   through a `[dependencies]` row rather than raw externs and a
   `[link]`, which is how a corpus dir proving a package should link;
   it stays `native-only` until S2c, because the fifteen `avra_net_*`
   externs are a package's and the evaluator cannot host them yet.

Debris the migration retires from the runtime — FIVE names, lane A's
file to delete: `avra_selfhost_read_file`, `avra_selfhost_write_file`,
`avra_host_list_dir`, `avra_mkdir_p`, `avra_str_codepoint_count`. Zero
callers in `packages/` and `corpus/`, zero in `tools/`, zero in the
`Makefile`, and zero in `bootstrap/seed.ll`.

**THE LIST WAS WRONG TWICE, IN OPPOSITE DIRECTIONS, AND THE LAW IS
WORTH MORE THAN THE LIST.** It began at eight.

*Two were live in a window this lane did not open.*
`avra_selfhost_file_exists` and `avra_host_is_dir` are called by
`corpus/native/externs.av`; the grep was scoped to `packages/`, and
absence in a window was read as absence.

*One was live in a window NOBODY opens by widening a source search.*
`avra_spawn_status` is declared and called inside a program
`tools/traps.sh` WRITES into `build/traps/…/src/main.av` at gate time,
builds, runs and deletes. No amount of grepping `.av` files reaches
it, because the caller is a string inside a shell script. Lane A found
it; verified here, at `tools/traps.sh:156` and `:198`.

**A SEARCH FOR "WHO CALLS THIS" OVER SOURCE FILES MISSES CALLERS THAT
ARE GENERATED.** Search the GENERATORS — `tools/`, the `Makefile` —
and the built artifacts too, and say explicitly that the SEED
(`bootstrap/seed.ll`, the compiler emitted as LLVM) was checked,
because it is the second invisible caller and it is 9 MB of text
nobody reads. A count with no window named is a claim, not a finding.

AND A CITATION DECAYS WHILE YOU WATCH: lane A reported the calls at
`traps.sh:105` and `:147`; at this base they are `:156` and `:198`,
because `traps.sh` grew between the two readings. The names were right
and the line numbers were not, which is why a receipt names its base.

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

**5.3 ARE THE DESCRIPTOR DOORS ROWS OR EXTERNS? SETTLED — ROWS,
landed by the HTTP lead at `3bfab94`.** Three `rt_sigs` entries with
`owns_result: true` on the take, three `RtHost` variants, three
evaluator arms. The leak is gone (§2.5), the evaluator hosts the fd
half, and §0's central sentence is true of the tree. Its one-line
sibling landed too: `avra_float_text_bits` is a row with its own
`RtHost.FloatTextBits`, so the evaluator no longer leaks the text of
every float it renders. The decision was smaller than it looked
because `@std/io` already shipped the same shape as rows; the fd pair
generalizes a path to a descriptor and invented nothing.

**5.4 SHOULD THE MANAGED-ANSWER REFUSAL BE A COMPILER LAW? DESIGNED
AND WITHDRAWN, and the withdrawal is the more useful record.** The
proposal was a refusal by name when an `extern fn`'s answer type is
managed and its symbol is not a registry row. Lane A counted the
population and it does not survive contact: five of the six
non-row managed answers are CORRECT, answering foreign or immortal
text that must never be filed for release, so the diagnostic would
refuse five to catch one. A lint's true-positive rate is its spec
(CLAUDE.md), and one in six is not a spec. The law it was meant to
enforce is real and now stated exactly in §2.1; the keeper reads the C
body rather than the Avra type and lives in `tools/externs.py`, lane
A's. WHAT THE NEAR-MISS TEACHES: the doctrine was right, the CURRENCY
was wrong. A rule about ownership cannot be enforced from the side of
the boundary that cannot see who allocated.

**5.5a WHAT THE S2 SURVEY MEASURED.** Four findings, each against
`0998a7c` and every one since acted on — the pointer answered by lane
C, the variadic refusal landed as S2b, §5.3 done, the capability
objection retired. Each was a thing the prior design
(`docs/2026_09_05_EXTERN_HOST_SHAPE.md`, the sqlite lane's for lane C)
does not answer.

- THE EVALUATOR HAS NO POINTER — ANSWERED BY LANE C, and the answer is
  that it does not need one. A foreign pointer RIDES `Val.I`,
  witnessed by the seat's `RtKind` in the row, with no new variant.
  The fact the survey and the prior paper both missed: the evaluator
  already hosts `RtKind.Ptr` rows (`avra_array_new`, `avra_map_new`,
  `avra_cell_unique`) as HANDLES — `Val.A/M/C` — so "Ptr" there
  already means "a managed box"; a FOREIGN pointer is the new thing,
  an address never dereferenced, with no identity Avra can observe. A
  `Val.P` would differ from `Val.I` in zero reachable behaviours, since
  a `ptr` has no dereference, no equality, no text projection and no
  arithmetic — eight consumers paid for nothing. The witness is the
  ROW and not the type registry, which is what makes `eval == native`
  hold by construction: the native path reads each seat's `RtKind` to
  decide how a value crosses, and the evaluator reads the same column.
  The mapping lives at the boundary only — a `Ptr` answer of 0 is
  `Val.N` and non-zero is `Val.I(address)`; a `Ptr` seat takes `Val.N`
  as 0 and `Val.I(a)` as `a` — unambiguous because the row says the
  seat is a pointer. AND THE REVERSAL CONDITION IS WRITTEN AT THE
  MAPPING, not here: a pointer rides `Val.I` only while Avra cannot
  tell a pointer from a number, and the day `ptr` gains equality, a
  text projection or arithmetic, `Val.P` is earned. Not a handle
  table: handles exist for identity and mutation, and a foreign
  pointer has neither.
- THE VARIADIC REFUSAL IS PLACED WRONG TODAY, by that paper's own
  receipt. It reasons that the refusal belongs at interpretation
  because "the native path can host variadics perfectly well" — but
  `declare`'s vararg flag is hard-wired false at both call sites and
  the grammar has no ellipsis, so the NATIVE path emits a fixed call
  and reads the garbage that paper measured. The refusal belongs at
  the DECLARATION until the grammar can spell a variadic seat — LANDED
  as S2b, with that narrowing condition written at the keeper — and
  `make externs` already reads each package's real C definitions, so
  it can see the `...` and refuse with a source location.
- §5.3 WAS FORCED, NOT OPTIONAL, AND IS NOW DONE. The host's own law
  is that a returned foreign pointer is never adopted as text, and
  `avra_fd_taken` answers `Bytes` — so while the doors were externs
  the host had to break its own law or refuse them. They are rows
  (§5.3), which is why the trampoline S2a builds NEVER MINTS: every
  minting door is a row, hosted by an arm, and the uniform frame only
  ever moves words and addresses.
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

## 5.6 S2a — THE EXTERN HOST, LANDED. What follows is the design; §5.6.8 is where the tree disagreed with it.

The prior paper (`docs/2026_09_05_EXTERN_HOST_SHAPE.md`) settled the
spine and it stands: ONE fully-applied C prototype rather than libffi,
integer class then floating class, the answer read through the seat's
declared width so the host and the backend narrow from ONE declaration.
Its ABI argument holds on both targets — the doubles never reach the
stack, so the k-th stacked integer of the uniform shape lands where the
k-th stacked integer of any all-integer callee lands. What follows is
what that paper does not say.

### 5.6.1 THE TRAMPOLINE IS `@std/avrac`'s C, NOT THE RUNTIME'S

This falls straight out of §0 and it is the decision with the largest
blast radius. `build/avra_runtime.o` is hard-coded into the link line
of EVERY avra-built program (`cli/src/commands/shared.av:277`), so a
`dlsym` trampoline placed there ships in every binary the compiler
emits. `build/llvm_wrapper.o` is linked only by `@std/avrac`, and only
`packages/cli` depends on it — so the compiler's own foreign machinery
already has a home, and the trampoline belongs beside it as
`packages/std-avrac/src/c/ffi.c`, built to `build/ffi.o` by the one
generic rule with no Makefile line, named in `@std/avrac`'s `[link]`.

Two things follow. The blast radius is the COMPILER, never a user's
program — which answers most of the owner's capability question by
construction rather than by policy. And S2a becomes the first NEW
package C to land under this standard, which is the proof the standard
is usable by its own author and not only by the package that predated
it.

### 5.6.2 THE TRAMPOLINE NEVER MINTS

Every door that mints a managed value is a core row hosted by an arm
(§5.3). So the uniform frame only ever moves WORDS and ADDRESSES, and
the host's law — a returned foreign pointer is never adopted as text —
costs it nothing, because there is no code path where it could. That
is why §5.3 had to land first.

### 5.6.3 THE VALUE MAPPING, at the boundary and nowhere else

Lane C's answer: a foreign pointer rides `Val.I`, witnessed by the
seat's `RtKind` in the row, with no new variant (§5.5a). The mapping:

| direction | `RtKind` | the host |
|---|---|---|
| argument | `I64`/`I32`/`U32` | the next integer slot, narrowed by the seat's width with the sign that width names |
| argument | `Ptr` | the next integer slot; `Val.N` is 0, `Val.I(a)` is `a` |
| argument | `F64` | the next FP slot, from `Val.F`'s bits |
| answer | `Void` | discarded |
| answer | `Ptr` | 0 is `Val.N`, non-zero is `Val.I(address)` |
| answer | `I64`/`I32`/`U32` | the return register read through the seat's width, extended as that width names |
| answer | `F64` | `Val.F` of the returned bits |

A REVERSAL CONDITION IS WRITTEN AT THE MAPPING: a pointer rides
`Val.I` only while Avra cannot tell a pointer from a number, and the
day `ptr` gains equality, a text projection or arithmetic, `Val.P` is
earned.

### 5.6.4 THE STAGING PROTOCOL, and why not nineteen seats

The uniform prototype needs MAX_I integers and MAX_F doubles fully
applied. Declaring that directly is an `extern fn` with nineteen
seats. The alternative is the shape this tree already uses for
descriptors — LAND, THEN ACT: `avra_ffi_set_int(k, v)` and
`avra_ffi_set_f64(k, bits)` stage into the trampoline's own slots, and
`avra_ffi_call(sym, nint, nf64) -> int64` performs the one fully
applied call. Five seats instead of nineteen, no Avra-side array
building, and the same idiom as `avra_fd_read` followed by
`avra_fd_taken`.

ITS CONDITION, named rather than assumed: the staging area is static,
so it is correct only while an extern cannot call back into Avra.
Nothing can today. If a callback seat ever lands, the staging must
become a frame or the protocol breaks silently, which is the worst
way for it to break — so the condition is written at the staging
area, not here.

### 5.6.5 THE REFUSALS ALMOST ALL BECAME STATIC

The prior paper lists eight shapes the uniform frame cannot host and
places their refusal at INTERPRETATION, by name. S2b moved the most
dangerous one — the variadic callee — to the DECLARATION, where
`make externs` reads the real C body. The same currency reaches the
rest: a struct or union by value, a struct returned by value, a
`long double`, an `__int128`, a vector, an `f32` parameter and an
integer-class arity past MAX_I are ALL visible in the C signature the
keeper already reads. So they belong in the keeper too, and S2a's
runtime refusal shrinks to almost nothing.

WITH ONE HONEST EXCEPTION, which is the seam: the keeper can only read
a C body it has a SOURCE for. An extern naming a libc symbol has none.
For those the Avra DECLARATION bounds the shape — a seat can only be
`int`, `ptr`, a named width or `float`, so a struct by value cannot be
spelled at all — and only the arity limits remain as a runtime check.
That is the whole of the interpretation-time refusal, and it is a
defect-shaped one rather than a law: a shape that reaches it should
have been refused by the keeper.

### 5.6.6 WHAT THE SLICE OWES

- `RtKind` gains TWO new exhaustive consumers in `language/interp.av`
  — the argument coercion and the answer coercion — and both must join
  `tools/vocab.sh`'s table in the SAME slice. All five of today's
  consumers are in `llvm.av`; a keeper that has only ever guarded one
  file is the untested instrument this tree keeps finding.
- One `RtHost` variant for "a symbol in the image, called through the
  uniform frame", and the seam at the evaluator's runtime dispatch,
  which today asks `any(it.name == callee)` and throws away the row it
  finds. `find` hands it the name, the answer kind, the seat kinds and
  the inout cells with no plumbing.
- THE INOUT HALF, which the backend already specifies for the
  interpreter in its own comment: allocate an eight-byte slot, seed it
  from the evaluator's cell, pass its address in the integer slot,
  read it back, truncate and extend by the row's `cells[j]` with the
  same sign table the backend uses, and write it back to the cell.
- The extension of `make externs` in §5.6.5.

### 5.6.7 WHAT IT DELIVERS, AND WHAT IT DOES NOT

It retires the evaluator's blanket extern trap for every symbol in the
compiler's image — 125 of the tree's 235 declarations at the S2 survey
— and moves `corpus/native/externs.av` into the differential corpus.
It delivers NEITHER `corpus/net` NOR `corpus/sqlite`: those are 110
symbols outside the image and they are S2c, the owner's. Saying so
here is the point, because "the extern host lands" is the recorded
trigger on several marks and it must not be read as delivering more
than it does.

A FLOAT IN A HEAP CONTAINER ICES ON MAIN until an approved fix merges,
so nothing in this slice boxes one; the FP class travels as bits in
registers only.

### 5.6.8 WHERE THE TREE DISAGREED WITH THE DESIGN

Four deltas, each found by building the thing rather than by reading
the plan — which is the only way any of them could have been found.

**NO `RtHost` VARIANT WAS NEEDED.** §5.6.6 said the slice owed one. An
extern's row carries `Unhosted`, and the seam handles it BEFORE the
`match host`, so the variant would have been a state nothing reaches.
The design asked for machinery the seam already made unnecessary.

**THE TEXT ANSWER IS A CAST AT THE DESTINATION, not a second call
shape.** The design's frame had three entry points, one of them a
`const char*` variant. But a `-> string` extern's row says `Ptr`, and
a kind cannot say whether the declaration meant text — so choosing the
entry point before the call is impossible. The DESTINATION can say it,
and `rt_val` is already where the bool answer narrows for exactly that
reason. So the frame answers every pointer as its address and the
destination reads it as text, through a pure cast with the target
called once.

**THE INOUT IS REFUSED, NOT MARSHALLED**, and the reason is a rule
this file already holds. No symbol in the compiler's image takes a
`mut` seat — every one in the tree belongs to `@std/sqlite` or the
width witness, both outside — so the marshalling would have been an
instrument nothing could exercise, which is how a keeper comes to look
only for the shape its author imagined. The trigger is written at the
refusal's voice: the first in-image extern with a `mut` seat, or S2c
putting a package's own C in reach.

**THE READY-MADE PROOF WAS NOT READY.** The design nominated
`corpus/native/externs.av`, following the prior paper. Moving it into
the differential corpus fails, and the reason is worth keeping: its
own `println` is an EXTERN writing to fd 1, so its output escapes the
evaluator's capture while the hosted `avra_puts` is captured. Its
printed ordering is therefore a native property — the paper's own
point about a buffered stdout flushing at the seam — and not a
differential one. It stays native-only. `corpus/extern_host.av` is the
differential proof instead: a text seat, a word seat, no seats, an FP
seat, and answers that are a word, a pointer, absence and foreign
text.

AND ONE THING THE DESIGN UNDERCOUNTED: `RtKind` gained FOUR exhaustive
consumers in the evaluator, not two — the argument coercion, the
answer coercion, and two projections the registry law forbids writing
as `is .Variant`. All four are in `make vocab`, which reports eight
where it reported five.

**AND `make vocab` NAMING THEM IS THE REGISTRATION, NOT THE PROOF.**
The proof is the enum growing and every consumer breaking. Measured:
a throwaway seventh variant added to `RtKind` fails NINE sites —
five in `llvm.av` (`ll_rt_kind`, `rt_arg`, `answers_word`, `answered`,
`narrow_sign`) and four in `interp.av` (`stage_seat`, `answered`,
`rides_fp`, `carries_cell`). Nine, not the eight a relayed estimate
expected, because `carries_cell` was added after the design when the
inout refusal landed. The variant was removed and the build is green
again; the number is here so the next person does not have to run it
to know what to expect.

THE STATIC REFUSALS LANDED WITH IT. `make externs` now refuses a
`long double`, an `__int128`, a vector, a bare struct or union by
value, and an `f32` SEAT — each detected positively and by name, never
as "not a scalar I recognise", which would refuse every typedef the
keeper has not met and make the rule's true-positive rate its author's
imagination. An f32 RETURN is fine and passes, because an answer is
read back through the declared width rather than from a slot the
caller filled. WHAT IS NOT COVERED, said out loud: a struct by value
behind a TYPEDEF reads as an ordinary name and passes. It cannot bite
while an Avra seat can only be `int`, `ptr`, a width word or `float`,
none of which can name a struct — and that is the recorded trigger.

### 5.6.9 WHAT THE RED TEAM CHANGED ABOUT THE HOST

§5.6.5 recorded that the refusals "almost all became static", and the
one that stayed dynamic is the one that broke. THE FOUR REFUSALS WERE
NOT WRITTEN ALIKE: `no_symbol`, `too_many_seats` and `inout_seat` were
all asked BEFORE the staging and returned; `unstageable` was asked
INSIDE it and only recorded. So the frame refused an aggregate seat
and then called the symbol anyway, with the slot at
`avra_ffi_reset`'s zero — a callee that dereferences read address
zero and the evaluator SEGFAULTED, five shapes, with `./avra check`
clean. A LAW REFUSES BEFORE THE WORK, and three siblings in the same
function already did; the odd one out was the defect. `staged_seats`
answers a bool now.

THE SHAPE THAT LET IT HIDE IS WORTH MORE THAN THE FIX. `stage_pointer`
carried the aggregate law in a `rest ->` arm over `Val` — and `Val` is
a REGISTRY, its handles at `.A`, `.M` and `.C`. A catch-all there
discharges the registry's obligation no better than `_ ->` and is
harder to see, which is this tree's own law about registry enums,
firing inside the host. Every variant is spelled now.

AND `.Void` WAS GROUPED WITH `.Ptr` in the backend's `rt_arg`, so a
`void` seat got a crossing check natively that `carries_text` does not
give it in the evaluator. Nothing can fill a void seat today, so it
was an asymmetry waiting for the day one becomes fillable rather than
a live divergence — which is exactly the kind that is cheap now and
expensive later. The arms are separate.

WHAT THE HOST STILL OWES, and it is a CHECK-TIME law rather than a
frame one: the evaluator refuses an aggregate at an extern seat and
the NATIVE binary does not. It hands C a real box pointer and the
program gets a wrong answer with nothing said — `atoi` over a record
answered 0, `puts` over a list answered 10, `strlen` over a map
answered 5. Only a law at the declaration covers both engines, and it
is held pending the lead because the tree's aggregate seats must move
first: `avra_exec_self(args: List<string>)` reads an `AvraArray` in C,
which §2.1 makes core's and §2.2 makes a ROW.

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

## 7. RECEIPTS, and what four consumers cost this document

The receipts below are at `82e6daf`, after the four migrations. What
matters more than any of them is §7.1: this document MISLED in four
places, each found by a package being built against it and none
visible to a reader of the document alone.

### 7.1 WHERE THE STANDARD MISLED, and what fixed it

- **THE DESCRIPTOR CONTRACT WENT STALE UNDER ITS OWN SECTION.** §2.5.1
  said a second take answers the empty box; the take became a TOKEN
  and a stale one TRAPS, four slices before anyone re-read the
  paragraph. A design section describing a contract it does not own is
  a receipt, and receipts decay.
- **THE THIRD SHAPE WAS MISSING, AND SO WAS INVENTED TWICE.** §2.5 had
  two doors and no PREDICATE SPLIT, so S3 discovered it under
  pressure (a package's C cannot reach the runtime's scratch) and S4
  reached for it again without noticing the repetition. It is §2.5.3
  now, with the test that would have found it first: ask whether core
  already answers the VALUE and the package need only answer the
  QUESTION.
- **THE ROSTER PUT LISTING IN THE PACKAGE** while §5.1 kept it in
  core, and the two sat four sections apart disagreeing for the whole
  campaign. A roster row and a decision about the same name must be
  one place or one of them is wrong.
- **THE CHECKLIST ASKED FOR LESS THAN WAS REACHABLE.** "Reads a box
  only through the runtime's exported verbs" tolerates a cast that
  `@std/process` turned out not to need at all: an aggregate cannot
  cross the extern frame, so the words are staged and the package
  reads NO box. The stronger form is in §3 now, with the stage's two
  structural properties beside it.

### 7.2 THE MEASUREMENTS

- The ownership law's leak, before the doors were rows: 800k takes of
  `avra_fd_taken` left 12 MB live; the identical extern shape whose
  name IS a row left 0.
- One gather beats a concat per landing: 64 MB read in 0.97 s before
  and 0.46 s after, peak 128 MB either way.
- A cap bounds CAPTURE, not acceptance: `max_capture: 1000` against
  `yes` kept 679,786 bytes natively and 52,035,584 under the
  evaluator — the same verdict, a 51 MB divergence in the value the
  caller reads — and 1002 bytes on both engines after.
- The extern frame reaches what the image carries: 235 declarations,
  125 in `build/avra` at the survey.
- `RtKind` grown by a throwaway variant breaks NINE consumers: five in
  the backend, four in the evaluator.
- `nm build/avra | grep -c ' T _avra_io_'` answers 11 after
  `make avra` and 11 after `make bootstrap`; the process count is 14
  at both.

### 7.3 THE NEAR-MISSES, which are the cheaper half

- A path holding a NUL read a DIFFERENT FILE than it named, and
  `exists` answered true for a path that does not exist — on both
  engines, which is agreement rather than correctness.
- 1486 MB "leaked" under `AVRA_RC_GUARD=1` and 1 MB without it: the
  guard poisons and KEEPS every box that reaches zero, so `now ==
  peak` is the instrument working. Nearly reported as a defect.
- A debris list of eight was five: two names live in a directory the
  grep did not open, one live inside a program the test harness
  WRITES at gate time. A search for callers over source files misses
  callers that are generated.
- A refusal case pinned the WRONG refusal because it named a symbol
  `build/avra` carries and the TEST binary does not.
- A case bounded its wait at 400 immediate asks where the child needed
  32,213, so a correct fix read as a failing one.
- A PROBE RUN MID-BOOTSTRAP ANSWERED ABOUT A COMPILER THAT NO LONGER
  EXISTED. `make bootstrap` links straight at `build/avra`, so while
  it runs the front door IS being replaced — four probes of the new
  seat law came back CLEAN and would have read as the law not firing.
  A probe result names the base that answered it, and during a
  bootstrap there is no stable base to name. Nothing was concluded,
  because the law had fired on those same four programs ten minutes
  earlier; that is luck, not method. Do not probe while a bootstrap
  holds the lock.
- THE TEST WHOSE NAME WAS BROADER THAN ITS BODY, found by attacking
  what it claimed: "an aggregate seat is refused as a law, with the
  remedy in its words" asserted the WORDS and never that the call was
  STOPPED. It picked `avra_ffi_set_int`, which tolerates the reset's
  zero, so it was green for as long as the refusal did not refuse. A
  reader deciding whether the question was settled reads the NAME.


### 2.8 A PLAIN EXTERN SEAT WEARS A TYPE THAT CROSSES

The `mut` half of this was landed with the inout ABI: a `mut` seat
hands C the ADDRESS of the caller's cell, so only a few shapes line
up and F2056 says which. THE PLAIN HALF WAS HELD BY NOTHING. A record,
a list or a map at a `const char*` seat compiled clean and crossed —
the native binary handing C the box's address and answering garbage
(`atoi` over a record answered 0, `strlen` over a map answered 5), the
evaluator staging a HANDLE into its own table as if it were an
address. Both engines wrong, differently, with `./avra check` silent.

F2056 grew the second arm rather than taking a new code, because it is
one law about one thing: A HOST SEAT WEARS A TYPE THAT CROSSES. A
plain seat is a machine word or ONE pointer C can read — `int`,
`float`, `bool`, a width word, `string`, `Bytes`, `ptr`, or a nullable
over those. Everything else that rides a pointer is a box in Avra's
layout and its address means nothing on the far side.

**IT IS SPELLED AS WHAT IS ALLOWED.** A forbidden list would admit
every type the language grows, in silence, at the door C is on the
other side of. Spelled positively, a new type is REFUSED at an extern
seat until someone decides it crosses — a loud answer a writer can act
on, and the catch-all's contract says exactly that.

**A ROW IS THE EXEMPTION, AND NOT A SPECIAL CASE.** A row has a
hand-written arm on both sides that MATERIALISES the aggregate, which
is precisely what a uniform frame cannot do; `avra_str_join` has taken
a `List<string>` that way since before this law. So the two aggregate
seats in the tree became rows, which is what §2.1 already said about
them — their C reads an `AvraArray`. `avra_exec_self` now re-execs
under `avra run` for the first time, and `avra_spawn_status` spawns
there; both answered on both engines where the evaluator used to stage
a handle as an address.

**AND A ROW'S WORDS ARE CHECKED IN C, because the seam checks a
SEAT.** A `List<string>` seat is a pointer to a box, so every word
inside it crosses unexamined while `execv` and `posix_spawn` RESOLVE
each one. Neither row is `inert` and both bodies call
`avra_str_crossing` per word — the flag says a NUL is data to the
body, and to these bodies it is two words. Proved on both engines: a
NUL word traps at byte 1, a clean word spawns.

**THE CONTRACT IS ON `avra_spawn_status` AND NOT ON `avra_exec_self`,
deliberately.** They are the same law, and a program that re-execs
ITSELF with a word the check no longer refuses would LOOP. A contract
whose regression is a fork bomb does not belong in a harness, so the
harness holds the child-spawning twin and this paragraph holds the
reason.

### 7.4 THE RED TEAM OVER THE SEAM

46 programs, both engines, run against the crossing check the day it
landed. What SURVIVED first, because a class attacked and found empty
is a result: the three NUL positions and a two-NUL string reporting
the FIRST, a NUL at byte 1000, through an interpolation hole, a `for`,
a lambda, a comprehension, a generic call's answer and a `string?` —
17 cases, byte-identical words and status on both engines. The empty
string and an empty `Bytes` cross clean. Inert rows carry a NUL
through untouched. A `Bytes` seat is never checked and its octets
arrive whole. The frame's seat bound refuses at 11 with the remedy and
is tested BEFORE staging.

WHAT BROKE was never the check. It was the frame beside it.

**A LAW MUST REFUSE BEFORE THE WORK.** `unstageable` fired correctly
for every aggregate and then the staging loop CARRIED ON and the
symbol was CALLED, with the slot at `avra_ffi_reset`'s zero. `puts`
printed "(null)" and the refusal followed it; `atoi`, `atol` and
`strlen` read address zero and the evaluator SEGFAULTED — five ways,
with `./avra check` clean. The three sibling refusals in the same
function (`no_symbol`, `too_many_seats`, `inout_seat`) were all
hoisted above the work and returned; this one alone was recorded
inside it. `staged_seats` answers a bool now and `hosted_extern`
refuses on it, so the shape matches its siblings.

**AND `stage_pointer` WAS A REGISTRY WEARING A CATCH-ALL.** Its `rest
->` arm carried the whole aggregate law over a `Val`, which is a
REGISTRY enum — the handles are `.A`, `.M` and `.C`, and a catch-all
there would have silently swallowed the next variant that is not an
address. It spells every variant now.

**WHAT IS STILL OPEN, AND IT IS THE ENGINES DISAGREEING.** Native has
no law here at all: an aggregate at an extern seat is handed to C as a
real box pointer and the program gets a wrong answer with nothing said
(`atoi` over a record answered 0, `puts` over a list answered 10,
`strlen` over a map answered 5). The evaluator refuses, the binary
answers garbage, and only a CHECK-TIME law covers both. The law is one
line — an extern seat names a scalar, `string`, `Bytes`, `ptr` or
their nullable twins, never an aggregate — and it is held pending the
lead's word because the tree's aggregate seats must go somewhere
first: `avra_exec_self(args: List<string>)` reads an `AvraArray` in C,
which by §2.1 makes it core's and by §2.2 makes it a ROW. Lane D
counts five such seats on main against one on `lane/http`; both counts
are right about their own base.

**AND THREE FACES TRAP WHERE §2.7 SAYS THEY SHOULD REFUSE.** A trap
inside a package that HAS guards is a bug in the guards, and each of
these has guards:
- `@std/io`: ten verbs answer `io.holed`; `env` and `env_or` trap.
  ALL THREE ARE FIXED (lane B, 85abb9e), and MY READING OF THE THIRD
  WAS WRONG. I wrote that `env`'s guard, `name.contains("=")`, was a
  NUL-LOSSY call that let `"A\0=B"` hide its `=`. Lane B retracted
  that the same night and they are right: f57372a had already made
  every `@std/text` verb read the HEADER, so nothing on the Avra side
  was ever blind. Re-probed here on this base, where all three of the
  doctrine's old receipts now answer the other way — `"A\0=B"
  .contains("=")` is TRUE, a five-byte text is UNEQUAL to its own
  two-byte prefix, and `from_codepoint(0) + "x"` is unequal to `""`.
  THE CAUSE WAS THAT NO CHECK STOOD BEFORE THE EXTERN SEAT, and
  `getenv` truncates regardless of what any guard saw. The fixes
  stand; the reason moved. THE CROSSING IS THE EXTERN SEAT AND ONLY
  THAT, which is where this section's own check lives — and the
  correction is worth more than the finding was, because a
  guard-and-guarded diagnosis aimed at the LANGUAGE would have sent
  someone to re-plumb five primitives that were already right.
- `@std/process`: `tool` guards, `tool_from_env` traps on its `var`,
  and `Env.Only(…).get("AB\0CD")` answers `"v"` — the value of `AB` —
  while `Env.Inherit.get` on the SAME argument traps. One method, two
  readings of one name, chosen by the variant.
- `@std/sqlite`: `equal_nocase`, `like`, `glob`, `is_complete` and
  `compiled_with` hand text to C unguarded. The package already has a
  `HoldsNul` cause it does not use at those five.
