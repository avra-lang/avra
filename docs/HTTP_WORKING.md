# HTTP working state

- Worktree `../avra-lane-http`, branch `lane/http`. Taken over 2026-09-06 by
  session avra-2a [1fab91] after the first session died; fast-forwarded to main
  at `957ba39`. The design papers are `2026_09_06_STD_HTTP_DESIGN.md` and
  `2026_09_06_STD_HTTP_TYPED_ROUTES.md`; framing laws arrive in
  `2026_09_06_HTTP_FRAMING_LAWS.md` (research agent, in flight).
- Mandate: `@std.http` client and server, backbone-grade performance, tiny and
  idiomatic; build missing foundations, never entrench a workaround. Every
  slice: `/red-team`, then `/review-round`. No commits without the owner's
  word; nothing merges from this lane until the owner rules on each
  capability (lane A: whether Avra gains a value type is the OWNER's call).

## Slice 1 — `Bytes` (BUILT, suite green, awaiting the owner's ruling)

The shape: `docs/2026_09_05_BYTES_SHAPE.md` (the sqlite campaign's paper,
written for lane A, never lane A's) with three deviations ruled correct by
lane A on the merits: `at` traps through `trap_bounds` (never -1), `slice`
traps through `trap_slice` (never clamps — a short answer parses), and NO
view kind (a view's pointer is not its data, so it breaks "a Bytes crosses as
Ptr"; a tiny view pins a receive buffer). Slices copy; the HTTP parser is
index-driven. The spare byte past the length is a NUL, by lane A's overrule
of my 0xFF: a poison byte makes an accidental C-string read a heap over-read
on network data, a NUL makes it a bounded truncation.

- Surface: `s.bytes()` (total), `[ints].bytes() -> Bytes?` (null past a
  byte), `b.text() -> string?` (null unless UTF-8; a NUL IS text — lane B's
  warning stands: the five C-string primitives on `string` are the debt, see
  ROADMAP H1), `.length`, `is_empty`, `at`, `slice`, `concat`,
  `index_of(needle, from)` (-1 on a miss; `from` may equal the length; empty
  needle found at `from`), `==`/`!=` over every byte, `Bytes?` niche-encoded.
  THE SCANS, added after the framing-laws paper (§2.5: a parser asks where a
  token ends, never what each byte is): `run(from, table)` — the end of the
  run a 256-byte class table admits, `eq_at(lo, hi, needle)`, `ieq_at` (ASCII
  letters folded). Thirteen rows; `corpus/bytes_scan.av`; two more trap rows.
- Runtime: one section in `runtime/avra_runtime.c` (`KIND_BYTES = 4`,
  `ACC_BYTES`, `box_bytes` +1 arm, no release arm), ten rows in `rt_sigs`,
  `RtHost` variants, the validator from the runtime-diff paper. Review patch
  for lane A: `docs/patches/bytes-runtime.diff` (delete before committing).
- Evaluator: `Val.Y(v: List<int>)`, held directly and PERMANENTLY (lane C:
  immutable means no identity means no handle), `language/interp_bytes.av`.
- Two collapses in lane C's files, verified by lane C and asked to land ALONE
  ahead of the ruling: `worded` exported from `features/checks.av` (str_lit
  imports it), `lower_is_empty` exported from `features/emit.av` (str_lit and
  lists deleted their copies; lane C proved the short form expands to the
  long one).
- Proof: corpus/bytes.av (eval == native), corpus/bytes-header (native-only,
  the text row reads a Bytes' header through the extern door), 41 `then`
  cases in features/bytes/tests, three rows in tools/traps.sh,
  `AVRA_RC_GUARD=1` clean, `make idioms`/`vocab`/`externs` green,
  `./avra test packages/std-avrac` 1968/1968.
- Owed: lane A's `DEMANDS` in tools/externs.py must learn `Bytes` the hour it
  lands (every Bytes extern seat is unchecked until then); lane B lands
  `read_bytes`/`write_bytes` on the seed; ROADMAP entries (Axis 18 wanting
  site, typed captures wanting site, H1's decision).

## Slice 2 — the net substrate (BUILT, split out of core on the owner's word)

THE STANDARD the owner set on 2026-09-06 (the substrate lane writes it
up and applies it to io and process): CORE owns the language's own
substrate — boxes, strings, lists, maps, Bytes, float, the process's
own facts, and DESCRIPTORS (`avra_fd_read` into ONE scratch, answering
a TOKEN — the scratch's generation — that `avra_fd_taken(token)` must
present, trapping on a stale one, so a read landing between a read and
its take is a loud wreck and never a stranger's bytes — lane B's
finding, reviewing io's shape; `avra_fd_write` from an offset),
because a managed value is minted ONLY by a core row — and that law is
MECHANICAL, not moral (the substrate lane measured it): an `extern fn`
that is not a row has `owns_result: false` hard-coded, so what it mints
is never released; `avra_fd_taken` as a bare extern leaked 3 MB per
200k takes, 0 as a row. The three doors are `rt_sigs` rows with
`RtHost` variants and evaluator arms, so the evaluator hosts the fd
half; the socket half stays native-only. AND THE SECOND-BUILD RULE
HELD, measured: a compiled program stopped leaking after one `make
avra`, the EVALUATOR only after the second (3 MB then 0), because the
product's own body was compiled by the pre-row binary. Everything
socket-shaped is `packages/std-net/src/c/net.c`, built to
`build/std_net.o` by the Makefile, linked by the manifest's `[link]`,
declared by `extern fn` in `net.av`, answering ints only (a peer
address comes back as words the package formats). SIGPIPE is ignored
at the FIRST SOCKET VERB, never at load, so a program that opens no
socket keeps the platform's convention. The evaluator hosts no socket
row: `corpus/net` is native-only until the substrate lane's extern
host lands. Level-triggered on both platforms; kqueue reports read
and write as two events per descriptor, epoll as one; act on every
event or unwatch. The C was drafted by agent `net-substrate` (109
loopback checks) and integrated by hand.

The face, `@std.net`: `listen(host, port)`, `connect(host, port,
timeout)`, `poller()`, `Listener.accept() -> Conn?`, `Conn.read(max)
-> Read` (`.Data(b)`, `.Eof`, `.Pending`), `Conn.write(b, from) ->
int` (0 when it would block), `shutdown_write`, `close`, `peer`,
`Poller.watch(fd, readable, writable)`, `wait(timeout?) ->
List<Event>`; every failure a `NetError { verb, subject, errno }`
implementing `Error`. Loopback spec in `packages/std-net/src/tests`; the red team's survivors
in `net_adversarial_test.av`. RED-TEAMED 2026-09-07 (13 programs, native):
every wrong type in every slot refuses once in its own words (a text
port, an int host, a bool interest, a string body, an int timeout); the
edges hold. Three findings, all fixed: a NEGATIVE `Duration` reached
`connect` as "forever" (a sentinel in a value — refused now, a zero
budget looks once); a read or write on a gone peer named an EMPTY
subject (it names the descriptor now); the poller's wait named nothing.
ONE HAZARD RECORDED, NOT FIXED: a closed descriptor's NUMBER is reused
by the next open, so a stale `Conn` value's `close()` can close a
stranger — the answer is the ROADMAP's generation-tagged handle table,
which needs process-wide package state (sugar backlog); until then a
`Conn` is used once and dropped, and the tests pin the refusal words
for the honest case (EBADF).

## Slice 3 — `@std.http` (IN PROGRESS)

`frame.av`: the framer, stateless and strict (every widening MAY
refused; a refusal names its law and its status; every line end CRLF),
index-driven over `run`/`index_of`/`eq_at`/`ieq_at`; the chunked
decoder is RESUMABLE (`chunker`/`fed`, a `Phase`), never a re-walk;
45 attack-table rows pinned in `tests/frame_test.av`. `http.av`:
`Request` (spans into its own buffer; `header(name)` slices on ask),
`Response`, `wire`, `reason`. THE FRAMER'S COST, MEASURED (bench in
`tools/bench/frame_head`, ignored): 3457 ns per four-field 112-byte
head natively, an order of magnitude off picohttpparser's 366 ns for
nine fields. Sampled top of stack: `once` reads a THIRD (`once_at` does
a strcmp per earlier entry on every read — lane A's, asked with the
numbers), refcount traffic a third (the `with`-copied `Framing` per
field and the per-field boxes — mine, to measure after lane A's fix),
the scans a tenth, the framer's own code three percent. Not hoisted
around: the code reads as it should. RE-MEASURED after lane A's two-pass
`once` fix reached this branch through main (6f528dd): 2420/2399/2427
ns a head, a 30% drop with no framer change — the `once` third was the
strcmp scan, and a read is ~12 ns now; lane A measured a per-site O(1)
slot at 1.7 ms of a 5.8 s compile and refused it for the compiler, and
the framer makes no case for it either: what remains is the refcount
traffic, mine. NEXT: `server.av` (the event loop, a
handler `fn(mut A, Request) -> Response`, app state threaded as a
value), the response framer, `client.av`. The strings lane's typed
patterns are LANDED on this branch (e49a637): `"{method} {path}
HTTP/{major}.{minor}"` binds from one scan, 120 ns against 90 ns by
hand, an untaken arm mints nothing; typed holes wait on the decimal
row; the framer's own scans stay until the `Bytes`-subject parity is
measured (the strings lane's S3), then they become patterns.

## Sub-lane: strings — S3 (the octet parity)

THE NUMBER THE CAMPAIGN NEEDED: over octets the compiled scan is 1.24x a
hand-written one (74 against 90 ns), and the gap is COUNTED — four
literal-to-octet conversions per attempt, ~4 ns each, because the IR has
no `Bytes` constant; the ROADMAP's hoisted-octets trigger fired by its
own condition and is an ask of the core owners now. Over text 1.58x, the
extra being the subject conversion the framer never pays. The harness
rule: a `once` read inside a timed loop inflated both sides 20% — hoist
the subject. The NUL-past-both-separators scan is a corpus pair. The
formats feature contributes zero F2047 warnings. MERGED into lane/http at
8d56477 (two commits, 70b10b5 and 23cd31a), full gate green. Lane A ruled
the octets ask by measurement: a `once` read is ~12 ns, so the per-site
O(1) slot comes FIRST and the lowering hoist after; a `ConstBytes` waits
for `Bytes` on main. NEXT: S4, the `grammar` value that parses, probed to
need no new door.

## The gate had never run this campaign's suites

`SUITES` in the Makefile named every std package but `std-net` and
`std-http`, so the 22 net cases and the 45 framer cases ran only by hand —
the sq-redteam lane's finding ("the gate had never run a sqlite test")
one campaign over, found by counting the gate's package lines after lane
B's process guard added seven cases and the visible total did not move.
Both suites join SUITES at d58ff78; the gate is green with them (22 and 45
under the watchdog, every other suite unchanged). LANE B'S PROCESS GUARD
(`Holed(word, at)`, every value the host is handed judged over its bytes;
a 30-character `Tool.path` had RUN `/bin/echo`) is on lane/http at
a0dbd4e by `cherry-pick -x` of lane/b f012645 — main's working tree holds
another session's uncommitted work across the same file, so lane B holds
its integration rather than conflict a pop; the merge from main later
sees the same patch. The substrate lane's S4 face builds ON it: the guard
judges the whole command before the first staged word, and stdin stays
length-aware as `avra_fd_write` (a NUL is data in a stream and two names
in a path).

## Main merged with static methods (aa5e8e6 … ebc60e3): five conflicts, two of them design

The owner granted static methods; lane C landed `static fn` on main
(e351840) and the merge into lane/http met the strings lane's grammar
door head on. RESOLVED: `type_receiver` is ONE rule — variant (the
type's own shape) → grammar door (the vocabulary, `method_row` before
`declared` as for a value; lane C's precedent, reversing my first order)
→ `static fn` (the user's impl) → the variant's answer; the obligation
recorded that a static named like a door becomes unreachable the day a
grammar type holds an impl (F2059's twin at the declaration). The
`statics` and `grammars` side tables both stand; `mark_static` and
`mark_grammar` had BOTH claimed fingerprint 110 — the keeper caught it,
the grammar mark is 113, next free 114 — and lane C's five-marks check
is a case now (nodes_adversarial_test: plain, `mut`, `once`, `static`
and a grammar mark are five fingerprints). THE CODES COLLIDED TOO: the
strings lane's F2058/F2059 (claimed by announcement) met lane C's
`type.static_fn`/`type.static_name` on main; the coherence law refused
the merged tree, and the formats codes are F2063/F2064 here. The
externs keeper is the union of both sides (78 cases, 10 C sources); the
sqlite sentinel joined the generic rule as `src/c/sqlite_sentinel.c`
with its CFLAGS line. THREE LESSONS PAID: my resolution left
`is_static` unclosed and the store's later methods vanished — the
SEED-BUILT compiler caught it where `make avra` could not (its binary
already knew the methods), so `make bootstrap` from the committed seed
is the check that a resolution is CLOSED; that bootstrap then produced a
product whose OWN registry held the duplicate codes and refused every
run — the way back was the saved `build/avra.pre`; and my test named
bindings `static` and `once`, which are keywords now. Gate green at
ec2a60d (87 corpus programs), seed refreshed and proven at ebc60e3.
MAIN AGAIN at 6e206a9 (lane A's census caller and its label fix, lane
C's seats bracket, the sqlite lane's own sentinel move to the same path
mine chose — the merge reconciled the rename with no hand work, only the
Makefile's hand rules dropped once more); gate green, seed refreshed and
proven after.

## Sub-lane: substrate — S4 (process) LANDED (945a251); the seed refreshed (c53fd88)

Eleven rows, eleven `RtHost` variants and eleven evaluator arms out of
core, 525 lines of C out of the runtime: the spawn table, pipes, signals
and reaping are the package's own C answering ints, a child's streams are
descriptors, the pump is Avra under lane B's three ORDER invariants (the
deadline asked before any poll; the sweep the last act before declaring a
timeout; the grace a floor) — the turn length never tuned once. The words
are STAGED (an append answering the count; a generation refusing a stale
stage; E2BIG at both caps) because an aggregate cannot cross the extern
host, and the §2.4 cast died with it. FOUR DEFECTS lane B's suite found in
the move: nothing closed a stream at EOF; the pump closed a caller-owned
`Open` stdin the instant the pipe was writable; the grace marked
truncation without stopping the tree; and A GROUP OUTLIVES ITS LEADER —
the signal tested the child's own life first and went silent once the
leader was reaped, exactly when the grandchild holding our pipe is who a
caller means (lane B: complementary to their face, which short-circuits a
seen end; one bound added to the red team — `ESRCH` records the group
gone so a recycled pgid is never signalled). THE SEAM GAINED AN ENGINE:
`corpus/native/process_seam.av` became `corpus/proc-seam`, a package
corpus dir, `eval == native == expected` where it was native-only. 14
`avra_proc_*` symbols at both link sites, every one the package's. The
seed was refreshed over the merged tree at c53fd88 and proven. THE RED
TEAM (ae3fd47, merged at 7a38127, gate green) found a DIVERGENCE: a
`max_capture` of 1000 against `yes` kept 680 KB natively and 52 MB under
the evaluator — both engines agreed on `TooMuch` and disagreed by 51 MB
on the partial the caller reads, because the drain emptied the pipe and
THEN tested the bound, so the capture was bounded by the child's speed;
it asks for one byte past what is left now and stops at the crossing,
1002 bytes on either engine. THE LAW: a bound tested after the work is a
bound on ACCEPTANCE, not on the thing it names. The C refuses a nameless
env entry on its own account. Survived: nine degenerate shapes, fourteen
hostile seat values, every one an errno and never a trap; the three
order invariants to the letter. A NEAR-MISS ON RECORD: `AVRA_RC_GUARD=1`
showed 1486 MB live at exit under forty capped floods — the guard KEEPS
every box that reaches zero; without it 1 MB and nothing live. Knowing
what an instrument does to a measurement is part of reading it. 95 cases
in `@std/process`. THE CHARTER CLOSED (82e6daf lane B's bound — a group
observed EMPTY is never signalled again, its fixture failing once for
the wrong reason, a 400-poll bound where a shell needs 32,213; 29496c9
the standard's review round — four places it misled, every one found by
a package built against it, never by reading: a descriptor contract
stale under its own heading, the predicate split missing and invented
twice, the roster and §5.1 disagreeing about listing for the whole
campaign, a checklist asking for less than was reachable; 2acff96 lane
D's shell-variable case — `$NAME`, since a same-named local makes
`${NAME}` silent). Merged at db0b41e, gate green, 97 process cases.
Five laws drafted for lane D: two already on main, three sent (lane D
took the examined-nothing corollary and order-not-granularity, declined
the staging law as a one-mechanism property — it lives in the standard).
THE S2C PAPER (5551523, merged at 597aa54; `docs/2026_09_07_S2C_DYLIB.md`)
puts the last door to the owner with numbers: `build/avra` 2.1 MB,
`sqlite3.o` 2.08 MB and 357 symbols, a 13.61 s cold compile — but the
objection to linking every package into the compiler is CONTAINMENT, not
size: `dlsym(RTLD_DEFAULT)` searches the whole image, so a program that
never named `@std/sqlite` could call it. RECOMMENDED: a per-package
shared library DERIVED by the tree from the object the manifest names
(never named by a manifest — an opened path is a load primitive across a
dependency boundary), opened by the program's own closure — the only
shape where the host's reach MATCHES the native link; today's reach is
wider (libc is in the image). A dylib's own symbol namespace is a
different guarantee than the flat image's, to be stated. The standard
took its fifth correction from the sentinel: `CFLAGS_<stem>` is what OUR
C needs for a header past its directory, not a vendored concession.

## Sub-lane: strings — S5 (print, the round-trip law) LANDED (aaab397)

`Name.print(r)` weaves the record back through the same door, and the
domain that keeps the round trip true is ENFORCED, not proven in prose —
because implementing the paper's condition PROVED IT WRONG: §6.3 said an
interior capture round-trips when its text does not contain the following
piece; `grammar G = "{a}--{b}"` with `a = "x-"` passes that test, prints
`x---b`, and parses back as `[x][-b]` on both engines — a capture ending
in a proper prefix of its delimiter overlaps it, which `contains` cannot
see. THE CORRECTED CONDITION asks the scan's own question of the smallest
text that can answer it, `(c + p).index_of(p) == |c|`, IN OCTETS (a check
built from `contains` or a C-string `index_of` would inspect different
bytes than the scan it protects — the guard-and-guarded law). The last
hole takes anything, its end fixed by the suffix anchor — an asymmetry
that falls out of the scan law and is tested as such. Red team: 15
programs, zero findings; three tests that asserted `print` was doorless
now test the admission rule with a name no grammar declares; three review
collapses and one voice (`doorless`). `corpus/grammar_print.av` on both
engines. THE ARC IS COMPLETE: S1 the paper, S2 the patterns, S3 the
octet parity, S4 the value that parses, S5 print and the law. S6 ANSWERED
NO, with an attack table (b6f63d6, `tools/bench/frame_patterns`): the
framer keeps its hand scans. Nine request lines from the framing laws
against `grammar RequestLine = "{method} {path} HTTP/{major}.{minor}"`:
the pattern TAKES seven the framer REFUSES — two spaces, `HTTP/1.1extra`,
`HTTP/11.1`, `HTTP/a.1`, a leading space, an HTAB inside the method, a
trailing space — every one a smuggling shape RFC 9112 names. THE LAW: a
format pattern is a SPLITTER; the framer's scan is a splitter AND a
validator (a method is a `token`, the target excludes CTL and SP, a field
name must touch its colon, a value is `field-vchar`), and applying the
classes after the split costs more than the one pass that does both. The
header line is worse in both directions at once: `": "` refuses the valid
`Host:example.com` and accepts the invalid `Host : example.com`. 146 ns
for the pattern against 1201 for a whole head is not comparable and would
not matter — a faster scan that accepts a smuggled request is not a win
at any speed. WHERE THE PATTERNS WIN is the ROUTE, already framed, its
captures values a handler wants — which is where the typed-routes paper
put them before any of this existed. S7 is the router.

## Sub-lane: strings — S7 (the router) LANDED (ab23a41)

`grammar Idea = "/ideas/{id}"`, a handler `fn(Request, Idea) -> Response`,
`routed<Idea>(...)` the ONE place a record type is erased, `dispatch`
the first route whose method, width and target answer; 404 is a value;
an unroutable target is a 404 and never a 400 (the framer admits
`obs-text`, so it is well formed and unrouted). RULINGS: the query is the
REQUEST's (positional grammar, keyed query — measured failing both
ways); erasure at the table boundary; the linear scan first with the
trie earning its number; `parse` gains a `Bytes` seat — one door, two
seats, the seat following the argument, the crossing at the door.
MEASURED: 308/506/773 ns at 1/4/8 routes, ~66 ns a route — at eight
routes the dispatch costs a whole head, the trie's number; the lane's
first draft cost 36% (a per-route width check) and the bench found it.
The octets seat then cost 10% at eight routes (850 against 773) because
the door converts the whole target per route — RULED as S7's design,
not a hunch: scan octets, convert only a hit's captures, a miss
allocation-free. BUILT, AND IT INVERTED ITS OWN COST (0f8446d): at eight
routes the string seat is 773 ns, converting up front at the door 850,
SCANNING OCTETS AND CROSSING ON A HIT 661 — keeping the framer's
boundary is faster than the shortcut, 80 ns a route to 54; one crossing
on a hit is every capture's crossing, because a span between two literal
matches inside valid UTF-8 is itself valid. THE SWEEP, GENERATED
(f348e6c, `tools/bench/routes/generate.py`): 370 ns at 3 routes, 1860 at
30, 23,800 at 300 — at thirty routes, where a real API sits, dispatch
costs nearly what framing a head costs (2410 on `frame_head`), and at
three hundred ten times; the trie has its number at the point that
matters and the point that proves it. The 8-route slope predicted ~24 µs
and the measurement said 23.8: right this time, knowable only after.
THE TABLE (b9c313e): a full-depth trie keyed on each literal segment's
hash — NOT a first-segment index, which would have won the flat bench
and lost on `/api/v1/...`-shaped tables — measured on THREE shapes at
300 routes: flat 23,427 → 346 ns, deep (shared `/api/v1`) 23,361 → 437,
wild (a hole first) 36,492 → 423; flat across shapes where the scan is
not, and it wins at three routes too (324 against 460), so there is no
crossover and no threshold branch. The descent is one octet pass with
the hash folded and spent per segment, zero allocation; `separates` is
the one definition of a segment for the descent and the pattern's cut.
Two measurements changed the design: fusing the descent into one pass
(352 against 425), and the guess that went the other way — reading a
node's two lists through the table to dodge retains measured SLOWER
than passing the node by value (337 against 317). THE RED TEAM FOUND
THREE: a hole-free route was UNSPELLABLE (a grammar refuses to bind
nothing, so `/health` and `/` could not be declared — `fixed` is the
door; the new-consumer law on the lane's own feature); the conflict law
asked about SHAPE and missed `/ideas/new` dying under `/ideas/{id}` —
it is SUBSUMPTION now, the same-shape case its symmetric instance, and
sound the day typed holes land because `open_hole` asks the type; and
the new law cried wolf over a static path holding braces — `Route.literal`
says which kind of string a pattern is. 87 case-pairs over 9 routes
agree with a linear scan on both engines; 60,000 dispatches over a
`once fn` table peak at 0 MB. Recorded, not fixed: a grammar cannot
state its own pattern text, so `routed` takes it twice and a
disagreement is a silently dead route (ROADMAP ask); `covers`
under-reports a mixed segment, the safe direction. A capture holds RAW
OCTETS — nothing is percent-decoded, `%2F` is not a separator — tested.
S8: the tail capture, then the query as keyed fields. BOTH SUB-LANE
CHARTERS ARE COMPLETE; the lead's own work resumes.
S8 LANDED (936ef6a) — the query as keyed fields over raw octets (`%26`
is not `&`, `;` is not a separator, `+` is not a space, absent / bare
/ empty / repeated four answers, `decoded` the one place decoding
happens and a malformed escape absence), the tail route declared by
its door, and the live bug in the router (it matched the whole target;
`Request.path()` is the one split, asking where the path class ends so
a head with no query is not scanned whole — 47 ns at 2 and at 62
fields). S9 LANDED (6f24335, merged 827fdb7) — the greedy hole
`{name...}` taking its literal at the LAST occurrence, no backtracking;
the round-trip proof's mirror, and THE TWO DOMAINS ARE COMPLEMENTS AT
THE OVERLAP CASE (`a = "x-"` under `"{a}--{b}"`, the value that forced
S4's correction: lazy refuses, greedy round-trips); greed inert on the
last hole (63 against 64 ns) so a route's pattern and its grammar carry
one string; greedy search linear in the occurrences (94 → 1008 ns at
99), the backward-scan row refused by lane A until a consumer is
linear-bound; `Hole.greedy` folded into the fingerprint — and lane A's
question found the pattern fingerprint splicing holes flat at a fixed
stride where the grammar mark folded them: both fold each hole through
`hole_fp` now (0b0bfb2), closed by construction. Two laws from the lane's own tests: a hole is ONE
segment (`/ideas/{id}` had bound `7/extra`), and segments are counted
by separators, never `split`. An ask recorded: a grammar's door as a
VALUE (`Idea.parse` unapplied is F2003; every route wraps it). Owed:
the conversion fix, the trie at 3/30/300 (generated), the red team,
the review. A REAL BUG in the octets seat, found by a test that pinned
the feature's ABSENCE and broke when it landed: `from_octets` minted its
answer and then `reg_of`'d its argument, which may lower lazily and mint —
I29's second specimen verbatim ("register r1 defines out of mint order");
a probe over a BINDING hid it, the test's EXPRESSION argument found it
(a88585a).

## Three receipts from keeping the branch (2026-09-07, to 28f1a4a)

A SEED NOBODY CHOSE, MINE: the main-merge chain ran `make seed` AFTER the
merge commit and never committed the result, so a regenerated seed sat
in the worktree and every `make bootstrap` proof after it ran from a
seed the branch did not carry — exactly what the Makefile's comment on
`seed` warns of. Found by `git status` after an unrelated failure;
discarded, and the COMMITTED seed re-proven twice (after the strings
fold and after main's float and renderer fixes): `make bootstrap` green,
two builds, gate green, tree clean. The rule: a bootstrap proof is
taken from a CLEAN tree, and `git status` is part of the receipt.
A CODE COLLISION INSIDE ITS OWN REMEDY: moving `grammar_fp` to code 56
landed on `Stmt.Spec`'s (one payload shape apart — a spec named X and a
grammar headed X could fingerprint alike); lane C found it reading the
pair, I renumbered to 64, and the strings lane did better in the same
hour — the format folds into the mark's own code 63 as payload, no
second reservation (d0fd2e9 superseded my 3dbc04e at the merge). Their
survey: nine tags repeat tree-wide, all across separate spaces (AST
fingerprints in nodes.av; memo tags in workspace/receivers), benign by
construction; the keeper's rule is uniqueness WITHIN a space, asked of
lane A. Fingerprint codes have no coherence law — a repeat is a silent
alike-fingerprint, not a red build. MAIN MERGED TWICE (589e52c: lane B's
process guard, doc fixes; 0be7257: the sqlite REAL class, the float
container fix, lane A's renderer fix — an arrow points at something, so
three declaration goldens lost their empty `╰──` line at 28f1a4a). AND A
THIRD AND FOURTH TIME (0713e6d, 8a74436): lane C's arm-boundary fix (arms
flattened into one run hashed alike — found by following the code count),
then lane A's `make fingerprints` KEEPER in the gate and the ARITY fold —
the survey's "separate spaces" premise was wrong, `Pat.Rest == Expr.Receiver`
exactly, and the deeper defect was movable boundaries in flat payloads,
nine of thirteen adversarial cases failing on the parent; `fp` is linear,
so a tag separates nothing and arity does. The merge renumbered ours under
the keeper's eye (it refused 106/107 — Defer's — and 55 — reclaimed):
marks 103/104, the grammar mark 110 with each hole folded to one value
under 111, the format pattern 112. Gate green at db4f08e.

## Sub-lane: strings — S4 (grammar values) LANDED (5e1f118)

`grammar RequestLine = "{method} {path} HTTP/{major}.{minor}"` declares
its capture RECORD (a `StructDecl`, the `component` precedent; merged at
9806321), and `RequestLine.parse(line)` answers `RequestLine?` on both
engines (`corpus/grammar.av`; lane/strings 5efa5fa, b7b1d28, awaiting
its red team, review round and goldens before merge). THE ROUTE, ruled
on the lane's own count after it refuted its paper: the value shape
(`Fmt<R>` as a builtin generic) needs a new core `Type` variant — 44
exhaustive matches in 19 files across three lanes, of which `make vocab`
names two — against compile-time EXPANSION through `Callee`'s four
consumers in one directory; the expansion is also the faster answer (no
format exists at run time). It landed SMALLER than lane C authorized: no
new `Callee` variant — `named_type` in impls/callee.av answers the
existing `Callee.Row(door)` when the DECLARATION has a format
(`grammar_of`, a side table keyed by StmtId beside `exported`/
`mutating`/`onces`, restamped over the whole format) AND the vocabulary
has a door of that name, else `Callee.Variant` byte for byte; lane C's
four constraints verified by running (a grammar with no `print` door
refuses as a construction; `Port.parse` on a record still names the
record). MEASURED WITH A CONTROL: `Name.parse` 122–125 ns against
121–125 for the pattern plus the same record built in the arm (the bare
pattern 97–100, by hand 62–63), so the door adds nothing of its own — and
the trigger as first written ("above the pattern") would have fired
forever naming a cost the value shape pays identically; corrected to
"above the pattern plus an equivalent record", where it does not fire.
Route B is vindicated by measurement. REVIEWS: lane C approved the rule
against all four constraints and rules that the lane writes constraint 4
in this slice at features/variants.av:114, a grammar's own voice beside
the record refusal, firing only where a grammar's door lookup failed;
lane A approved the core shape with two findings for the close — a
reserved code 63 with the format hash as PAYLOAD instead of a hash in the
tag slot, and `type_fp`'s doc comment moved back below `grammar_fp`.
CLOSED AND MERGED at 5e1f118 (a7dcd85: `restamp(s, tag, payload)`, the
mark at code 63, `grammar_fp`'s own code 56; 0ab01ac: constraint 4 as the
grammar's own voice in variants.av, 28 red-team programs over seven
classes with zero findings in the feature, two review-round collapses —
a third `carried_type` and an invented projection — and the
declaration's goldens; 56 spec cases, 50 adversarial). One finding for
the parse channel's owner: a builder refusal renders with an empty label
(`Cause.Builder` has no label field). NEXT: S5, `print` and the
round-trip law enforced by the compiler.
Rule B, STATIC METHODS, is the owner's, recorded in the asks with both
wanting sites. Two grammar-law findings paid on the way: a recovering
statement branch on `grammar` ate the compiler's own `grammar { … }`
expressions (the anchor law now reaches across rules, main 88bb058), and
an adjacent-hole grammar was accepted until the declaration heard every
law in the builder. S5 is `print` and the round-trip law, stated and
proven over the paper's reference implementation, enforced end to end
only once `print` exists.

## Sub-lane: substrate — S3b LANDED (8fd2a6e): a NUL path read another file

MERGED (lane/substrate c9c7880 io, 1be60fd the build split), bootstrap +
two builds + full gate green. THE FINDING: a path holding a NUL read a
DIFFERENT FILE than it named, on both engines — a 79-byte name ending
`/../../etc/passwd` with a NUL at byte 5 read a 5-byte file and answered
ok, `exists` answered true for nothing, `write_text` created a file under
a truncated name. Agreement, not correctness: the face measured the
header's length and C stopped at the NUL. `one_path` refuses it at all
six verbs that hand C a path, judged over the BYTES (a door built from
`==`/`is_empty`/`contains` stops at the same NUL), four cases pin the
words and the offset. The empty path came back clean, run: ENOENT at
three verbs, `kind_of("")` Missing, identically on both engines — a
pointer to a terminator, never NULL. THE TWINS: `read_bytes`/`write_bytes`
land and the text verbs are built ON them; `ab\xffcd` → `NotText(path,
2)` is a real case beside lane B's NUL accept case. THE GATHER: 64 MB
file, 0.97 s concatenating per landing → 0.46 s gathering once, peak 128
MB either way (the parts and the box coexist as the last concat's two
buffers did). THE ENV CONDITION at the site, premise verified. THE BUILD
SPLIT: `COMPILER_OBJS`/`PACKAGE_OBJS`, `TREE_OBJS` retired, `make avra`
no longer compiles the amalgamation; `stems.sh` asks `nm` of the binary
and the manifests of the packages, and reports a zero-object scan aloud.
NEAR-MISS: moving the block dropped `CFLAGS_sqlite3` and the amalgamation
rebuilt without its flags; only `@std/sqlite`'s suite, asking the library
its compile options, noticed. NEXT: S4, `@std/process` on the standard.

## Sub-lane: substrate — S3b (in progress): the cold path, the offset

MERGED at c8af70b (lane/substrate 3f8da0a): `make bootstrap` from the
REFRESHED SEED green here (685 MB), two builds, 11 io symbols, full gate.
THE FINDING THE GATE COULD NOT SEE: deleting seven runtime symbols left
the committed seed referencing them, so the cold path was broken while
`make avra` gated clean twice — it never touches the seed. Three of the
seven are restored by naming the package's object; four exist nowhere by
design, so only a seed refresh restores `make bootstrap`, and it rides
the removing commit so every commit bootstraps. RECEIPT LAW, to CLAUDE.md
via lane D: a slice that removes a runtime symbol is proved by `make
bootstrap` green. LANDED: `NotText(path, at)` ("is not UTF-8 — byte 5"),
the FIFO sentence, the twins check (one C body reached through two
identical declarations — nothing could drift). A FINDING against lane
B's fold-it-in: a character straddling a chunk seam makes per-landing
validation unsound; one walk over the assembled bytes, a RESUMABLE
validator recorded as the ask. OPEN: the byte twins, the real refuse
case, the gather, the env condition at the site, lane A's per-target
object split, the marshalling probes and the NUL-path refusal.

## Sub-lane: substrate — S3 (io) LANDED, with two findings open

MERGED into lane/http at 7a9f227 (lane/substrate 0cf47f2), built twice, 11
`avra_io_*` symbols in the image, full gate green (2138 + 406 cases, 15
traps, 84 corpus programs, witness). THE HEADLINE: `corpus/io` KEPT BOTH
ENGINES — the compiler's image links `@std/io`, so the extern host runs
the package's own C under `avra run`; ordering the host first made the
regression window zero. Ten int-answering entry points in
`packages/std-io/src/c/std_io.c`; seven rows, seven `RtHost` variants and
seven arms left core; `avra_io_taken` died (no remnant, the mint keeper
green). THE ENVIRONMENT split rather than moved: `fd_landed` is static,
so the package answers the PREDICATE (set or unset) and the VALUE rides
the existing `avra_host_env` row — `avra_io_env` is GONE from rows,
`RtHost` and the evaluator (lane C caught my summary saying its arm was
kept); lane B's distinction kept with nothing new in core, atomic only
while nothing mutates the environment — the condition is written at the
site in S3b. THE BUILD:
`avra`/`seed`/`bootstrap` depend on `$(TREE_OBJS)` (every object the
tree compiles, so no link can want an absent one — the ffi.o class
fixed, not the instance), `RUNTIME_OBJS` renamed `COMPILER_OBJS`, and
`tools/stems.sh` reads the manifests against make's own list (witnessed
naming three objects). For lane A's standard: a seventh `RtKind` variant
fails NINE sites, not eight (`carries_cell` arrived with the inout
refusal). TWO FINDINGS AGAINST LANE B'S BINDING RULINGS, sent back as
S3b: `NotText(path)` carries NO BYTE OFFSET (io.av:167 tests
`Bytes.text()` for null — the shape lane B refused by name); and
`read_bytes`/`write_bytes`, the lossless twins ordered in the SAME slice,
did not land — with `write_bytes` the "cannot be provoked from inside the
package" note becomes a real case (`ab\xffcd` reads back as
`NotText(path, 2)`). Lane C's arm-against-C-body check was not reported;
its result, negative or not, is owed in S3b's message.

## Sub-lane: substrate — S3 (io) rulings

THREE DECISIONS, ALL MEASURED BY THE LANE, RULED 2026-09-07. (1) `avra_io_env`
STAYS A CORE ROW beside `avra_io_list`, both landing through the descriptor
scratch: a package's C cannot reach `fd_landed`, and the standard's roster
already names the environment as the process's own fact — a law, not an
exception. (2) `read_text` VALIDATES UTF-8 (lane B's word): every file the
compiler reads was scanned, 547, zero invalid; a stray `0xff` in a STRING
LITERAL passes `check` clean today, so the change closes a silent hole. The
refusal carries the PATH AND THE BYTE OFFSET (`utf8_bad_at`, never
`Bytes.text() ?? fail`, which throws the offset away), the scan folds into
the read loop's one pass, and `read_bytes` lands in the same slice as the
lossless twin — split the verb, one per promise. (3) THE FIFO stays
BLOCKING and `Other` is not refused: `read_text("/dev/null")` answers `""`
today and `/dev/null` is `Other`, so a refusal would newly reject a
legitimate read; the artifact is one doc sentence on `read_text` naming the
block and `kind_of` as the question to ask first. THE CORE DELETIONS (rows,
`RtHost` variants, evaluator arms leaving core) are the lane's to write, in
lane A's and lane C's files, for their review before merge — both told.

## Slice 4 — the SERVER LOOP (de9d3f1 … e77fae3), the lead's own

`packages/std-http/src/server.av`: the loop is a VALUE with a `turn`
verb — one wait, every ready descriptor served, the count answered;
`run` turns forever, a test turns by hand on one thread with a client
on the same poller. A connection's whole state is a `Link` (the
framing paper's per-connection list: socket, unconsumed bytes, the
scan's reach, the head awaiting its body, the chunked decoder, output
owed and written, closing, served, heard) and every link lives in a
`List<Link?>` by descriptor. `Server<A>` carries the app state and a
`fn(mut A, Request) -> Response` the handler writes through — the
probe for that shape (a nullable record field, a generic server with a
mut-seat fn field fed from its own state) found a FALSE F2050: a call
writing through a fn FIELD's `mut` seat is invisible to the receiver
pass, and the help walks the writer into a silent write — lane C
reproduced it and is fixing the pass (234d17c). THE LAWS, each a case:
responses leave in request order and a pipelined tail is framed next
from the same buffer; a refused head answers its status with
`connection: close`, shuts the write side and reads the peer to its
end; a peer's FIN is not a delimiter and not disinterest; `100
Continue` when a body is expected and none has arrived; a HEAD carries
the body's length and none of its bytes; a link idle past its `Timing`
deadline is dropped. Twelve exchanges exact (server_test), fifteen
attacks over four classes (server_adversarial_test: every split, the
bounds at 431/413, garbage/bare LF/HTTP/2.0, peers that vanish) with
one harness finding — a peer closing mid-head takes three wake-ups,
one read per wake-up by design. `corpus/http-serve` runs the loop end
to end natively, `AVRA_RC_GUARD=1` silent, nothing live at exit. Two
review findings of my own gone (a `Progress` variant nothing built, a
one-line alias). AND A LATENT TRAP IN THE CORPUS RUNNER: it captured a
package build's stderr into the binary-path file and EXECUTED the
file, so the first warning-carrying package corpus program ran
`warning[F2050]:` as a shell command and reported native != expected;
the path is stdout alone now, under build/ (e77fae3, lane A's review) —
and lane A swept the class: fourteen more shared /tmp paths in the same
Makefile, the sharpest under `make witness` (one lane's C run by
another under a rule claiming "the same object"), the quietest the
profiler's default file (a wrong measurement read as yours, which no
check can go red on); the lock alone stays in /tmp, machine-wide being
its job.

## Slice 5 — the REPLY FRAMER and the CLIENT (d59d292 … 224c89b)

`framed_reply` in frame.av: `HTTP/1.x SP 3DIGIT SP reason`, the field
walk a request and a reply now SHARE (`field_lines`, split out of the
request's `fields`), then a reply's delimiting by its status and the
request's method before any field — none for a HEAD's answer, a 1xx,
a 204 or a 304; chunks; a length; else the close, which cannot persist.
Twenty cases (reply_test). `client.av`: `Client` has the server's shape
— `sent` writes a request whole, `polled` is one wait and one read
answering the reply when it is whole, `fetched` polls until the reply
or the deadline; `Answer` (status, fields as text, body), `ClientError`
(the network, a refused reply naming the status it would earn, the
peer closing before a reply, the deadline); `request` writes a request
on the wire. Five exchanges against the server on one thread; twelve
attacks against a scripted peer speaking raw bytes — torn heads and
bodies, chunks across reads, a reply whole only at the close, a
refusal, a head past its bound, a cut-short body, a close before any
reply, a silent peer, two replies on one connection — with ONE TCP
FACT pinned as its own verdict: a peer that closes with the request
UNREAD resets the connection, and the client reports the network's
error, not a clean close. Two review findings of mine: a header
compare indexed by characters where bytes were meant, and a
content-length rule keyed on string-matched method names (the length
is written when there is a body; a body-less request needs no field).
`@std/http` is 157 cases; the gate is green at 224c89b.
THE LIBRARY IS WHOLE — framer, router, server loop, client.

## Slice 6 — THE LOOP UNDER LOAD (b83abf9, 2fd7fd6)

`tools/bench/serve` is a server answering "hello" on 18080;
ApacheBench on the same machine, one server thread, loopback:

    keep-alive,  50 concurrent, 20,000 requests   102,059 req/s   99% ≤ 1 ms
    keep-alive, 200 concurrent, 50,000 requests   118,281 req/s   99% ≤ 2 ms
    a connection per request, 50 concurrent        41,688 req/s   99% ≤ 4 ms

Zero failed requests in every run. CPU-ACCOUNTED (`ps -o utime,stime`
on the server after 300,000 requests, twice): 1.46 s user + 1.01 s
system per 300,000 — 8.2 µs a request, 4.9 µs the loop's own code and
3.4 µs the kernel's three calls; at 116k req/s the thread is 96% busy,
so the generator and the loop are both near the ceiling. THE SAMPLER
LIED: `AVRA_SAMPLE` under watch.sh reported every sample in `kevent`
for a server that accounting shows 96% busy — read a server profile
from that tool with that in mind. `tools/bench/turn` (a server and a
client on one thread, 200,000 keep-alive requests turned by hand) is
the deterministic instrument: 21.1 µs a round trip including the
client's own three calls, census-able. The instrument is named because
it bounds the number: `ab` is single-threaded and shares the core, so the
keep-alive figure is close to what the generator can drive, not what
the loop can serve — a multi-core generator on another host is the
next measurement. THE FIRST `ab -k` RUN TIMED OUT, which was a law:
`ab` speaks HTTP/1.0, and a server that honours a 1.0 peer's
keep-alive must SAY `connection: keep-alive` or the peer waits for a
close that never comes (RFC 9112 §9.3) — `wire` speaks the
connection's fate whenever the peer cannot assume it, both 1.0 cases
pinned. S8 from the strings lane merged in the same window (936ef6a):
the query as keyed fields over raw octets and the tail route declared
by its door — and a LIVE BUG in the router I had merged: it matched
the whole target, so `?redirect=/home` made its route 404; the header
said "a route matches the PATH" since S7 and nobody checked the code
held it. The loop's suite now drives the router with such a target.
@std/http is 254 cases.

## Slice 7 — THE FRAMER UNDER THE CENSUS (bccc2f4)

`-DAVRA_CENSUS` with `AVRA_CENSUS_SITES=1` over `tools/bench/frame_head`
(2M four-field heads), sites named by `atos`. PER HEAD: 226 retains,
263 releases, 74 reclaims, 132 list reads, 140 list writes, and 52
`once` reads costing 988 POINTER COMPARES — nineteen per read, because
the framer holds ~20 `once` tables and the pointer pass walks the
entries before the hit; the single largest retain site in the program
is `avra_once_get` at 104M, one retain per read, released by the
caller. So `once` is a quarter of the head in a mechanism the framer's
code does not spell. THE ASK TO LANE A, with these numbers: a `once`
answer is IMMORTAL (minted once, alive for the process, its header
wearing the STATIC kind so a read is a borrowed load with no retain and
no release) plus the per-site O(1) slot — ~15 ns × 52 off every head,
and every `once`-tabled scanner in the tree gets it. TWO WASTES WERE THE
FRAMER'S OWN AND ARE GONE: `method_of` built a nine-element list per
head to `find` a verb (18M pushes), and `crlf_only` read `cr()`/`lf()`
inside its loop; 2410 → 2185 ns a head, 254/254. Left where it is: the
`Framing` fold's per-field record copies (4 retains a head at
`settled`) and the empty-literal copies on a `mut` list's first push
(2 a head) — small, and allocation here is cheap. THE LOOP UNDER THE
CENSUS (`tools/bench/turn`, 200k round trips): 323 retains, 401
releases, 308 list writes and 37 `once` reads a round trip; the
sites are the framer's per-field records, the poller's event list,
`Conn.read`'s record and `avra_once_get` — and ONE SCALABILITY DEFECT:
the idle sweep walked every link on every turn, O(connections) per
event; it runs on quiet turns and once a second under load now. A
breadth case (two hundred clients in bursts of fifty) found a kernel
fact rather than a defect: macOS caps a listen backlog at 128 whatever
was asked, so a burst past it times out on the connect side; and the
loopback delivers after the write returns, so a client reads until its
answer lands. LANE A LANDED HALF
(a) on main (6b38795): the `once` cache is an index keyed by the
symbol's pointer, one probe a read at any table count, a strcmp hit
indexed on the way out; merged at e25f46a and re-taken on shipping:
2063/2043/2040 ns a head against 2185 — ~140 ns, the compares were
real. What remains of the `once` share is the retain/release pair
around each read, half (b), with the owner. The ledger: the framer's
own wastes 2410 → 2185, the slot 2185 → 2045, both on shipping.

## RED at ec98057 — door 1 met its one exception (2026-09-07)

Door 1 merged (lane/substrate d0d5756: `avra_str_crossing` at three
seams — the native lowering, the extern frame, and the evaluator's row
path, which the brief had not named and without which the engines would
disagree about which strings may cross; `inert` on `RtSig` with CHECKED
as the default; four trap contracts) and THE GATE WENT RED in
`std-sqlite`: the driver's own case "a `const char*` seat that CARRIES a
length" trapped at byte 6. The case is right and the seam is right:
`sqlite3_bind_text` takes text WITH a length, so a NUL inside is DATA
and the callee resolves nothing. The design's named escape is a `Bytes`
seat — "a package that means octets takes `Bytes`" — and it must be
spellable on a package extern for the design to hold; the substrate
lane lands it in the same slice, the driver's `bind_text`/`bind_blob`
seats move to it (the sqlite lead's package, told). Lane A's review
found the marking pass answering two identical rows differently
(`avra_host_env` checked, `avra_io_env` inert — the same `getenv`); not
a live hole, since both cross through package externs that are never
inert, but a false fact in a registry, so `make externs` grows an
`inert` keeper (a body calling `getenv`/`fopen`/`stat`/`opendir`/
`exec*`/`posix_spawn*` on a text seat cannot be inert) and the four are
re-marked, lane A's. NOTHING MERGES INTO lane/http UNTIL THE GATE IS
GREEN AGAIN.
GREEN AGAIN AT ac4e185. The `Bytes` seat crossed (lane/substrate
f431d98): a package extern seat typed `Bytes` hands C the payload
pointer, the face passes the length beside it, no crossing check runs
by the seat's type — natively it always crossed, so it had been
spellable on ONE engine and nobody had written one. The sqlite lead's
sweep found FOUR such seats (`bind_text`, `bind_blob`, `keyword_check`,
`prepare_v3` — the hottest in the driver) and SEVEN resolving ones, and
gave the rule its mechanical form: A SEAT WHOSE PROTOTYPE CARRIES ITS
OWN LENGTH IS `Bytes`; a bare `const char*` is checked; a NUL inside a
`Bytes` is data. STAGING IT CAUGHT A USE-AFTER-FREE the lane had just
written (a box materialised only to be staged had no holder; native
`kind=2` against evaluated `kind=0`; staged boxes are held until the
call returns) — and the same shape one level up: `bind_text_unsafely_
borrowed` takes `Bytes` now, because a `string` face would have MINTED
octets nobody else held and turned a keepable promise into a dangling
pointer created by the verb; the sqlite lead's law: A TYPE MIGRATION
CAN MOVE WHO HOLDS A VALUE, AND A LIFETIME PROMISE IS A PROMISE ABOUT
THE HOLDER. The guard reads `hdr()` directly and skips a foreign
pointer visibly (its first draft was bounded by `strlen` and could
never find an interior NUL); `puts`/`eputs` read the header's length
and a NUL-bearing line prints whole. The four false marks lane A named
do not exist here — those rows left the registry in S3 and S4 — and
main's `inert` keeper (0bc7426), merged, certifies the column unchanged:
80 inert, two checked, both resolving. Two adversarial groups that
asserted the truncation are trap contracts now (20). Worst case: 25 µs
per megabyte crossing, ~47 GB/s, eight distinct strings cycled. A
LIBRARY REFUSES BEFORE THE LANGUAGE TRAPS is §2.7's layering, in the
sqlite lead's words.
THE RED TEAM OVER THE SEAM (46 programs, both engines): the CHECK
SURVIVED EVERYTHING — 17 cases both ways, byte-identical words and
status; the three severes are in the FRAME beside it, fixed in the same
slice. (1) An aggregate at an extern seat passed `check` clean and the
evaluator staged its HANDLE as an address (a record, a map: segfault on
eval, garbage natively; a list refused) — an extern seat's type must be
one that crosses, a check-time law. (2) The `unstageable` refusal did
not stop the call — `puts` printed "(null)" and THEN the refusal; the
frame stops at the first. (3) An extern declared with a CORE ROW's name
is dispatched to the row with its own seats and answer discarded
(`extern fn avra_host_env(a, b) -> int` handed a program a raw pointer
as an int, and inherited the row's `inert`, so "never inert by
construction" was false as written) — an agreement law at the dispatch.
And the `Bytes` exemption was unenforced: `Bytes` joins `make externs`'s
demands. THE TREE'S ONLY AGGREGATE SEAT, `avra_exec_self(args:
List<string>)` in packages/cli, becomes a ROW (§2.1: a C body that
reads a box is a row) and works under `avra run` for the first time.
THREE FACES THAT TRAP WHERE THEY SHOULD REFUSE, routed to their owners
by §2.7's own rule: @std/io's `env`/`env_or` (no NUL check before the
seat — the "NUL-lossy `contains`" reading was retracted, see the merge
entry below), @std/process's
`tool_from_env` and `Env.Only.get` answering the prefix's value where
`Env.Inherit.get` traps on the same name (lane B); @std/sqlite's
`equal_nocase`, `like`, `glob`, `is_complete`, `compiled_with`, with a
`HoldsNul` cause the package has and does not use there (the sqlite
lead).

## Main merged (9fe4efe, fixed at c921b93): the three routed faces came home

The seam's red team routed three trapping faces to their owners; main
brought all three back in one day, plus the half of door 1 that was
waiting on the owner's word in lane A's session:

- LANE B (85abb9e): `env`/`env_or` judge the NUL FIRST — `env("PATH\0/
  junk")` had answered PATH's own value, a silent read of a different
  variable, because NO check stood before the extern seat and `getenv`
  truncates whatever our own verbs do; `tool_from_env` refuses as
  `tool` does; `Env.get` answers null for a holed name under both
  variants. (Lane B's first rationale — that the `=` guard was built
  from a NUL-lossy `contains` — was RETRACTED the same night: lane A's
  f57372a had already made every primitive read the header, so nothing
  on the Avra side was blind. The crossing is the extern seat and only
  that; the fixes stand, the reason moved.)
- THE SQLITE LEAD (0130321): `compiled_with`, `equal_nocase`, `like`,
  `glob` answer a `Result` and refuse a NUL with `HoldsNul` — reaching
  for the cause `is_complete` already had.
- LANE A (f57372a): `==` is a length compare then `memcmp`; `contains`,
  `index_of`, `split`, `replace` walk the header's length with `memmem`.
  Measured there: `contains` over a megabyte 477 -> 681 us, equality
  free, the self-check ~1%.

FOUR CONFLICTS, one of them design. The env guard lands on this
branch's set/host shape with the NUL judged first — on this branch a
holed name that reached the extern would TRAP at the crossing, so the
library's refusal must come before it. The io and process suites take
both sides' cases. The sqlite suite keeps the seam's comment and every
FACE case of main's, and DROPS main's two WALL cases: `wall_completes`
with a NUL passes a holed string to a bare `const char*` seat, which
here ends the process. The wall's truncation is witnessed in
`tools/traps.sh`, which exists for cases a suite cannot hold.

TWO GREENS THE MERGE THEN NEEDED, both expiries rather than defects.
The query suite's "the lossy primitives stop before it, so the two
disagree" PINNED `==` stopping at a NUL — a witness of the lie, written
so it could not drift unnoticed — and the lie is gone, so the case
asserts the truth now: a decoded `a%00b` is not its own prefix. And the
traps row `nul_at_a_package_wall` drove its trap through
`equal_nocase`, which main taught to refuse before the wall; the row
calls `sqlite3_stricmp` directly, the call a package that has not
thought about it would write, and meets the floor its own comment had
named. A TEST THAT PINS A LIE EXPIRES WITH THE LIE, and the expiry
reads as a red gate.

TWO RECEIPTS FROM THE DAY. Lane B's: "a guard is not a place, it is a
property of every crossing" — the defect survived one door down in a
file whose path door was already judged over bytes. Lane D's: a COUNT
offered as a correction names its TREE — five aggregate extern seats
on main against one here (S4 killed the other four), both right, and
the aggregate-seat law lands alone on this branch.

Built twice (594, 624 MB), gate green at 330 MB, twenty trap
contracts held. The seed is unchanged: no runtime symbol moved.
Door 1's primitives half is DONE; its seam half is the substrate
lane's, in flight; immortal `once` is still on the owner's word.

## The seam's fixes landed (342ad91), the review round (01d4b3d), and S2c approved in shape

The substrate lane's 55c2dd4 fixed the three severe findings its red
team made beside the crossing check, and a cold bootstrap proved them:
the frame REFUSES BEFORE THE WORK (it had recorded the refusal and
staged on, so `atoi` read address zero and the evaluator segfaulted
five ways with `check` clean — the one sibling of four not hoisted
above the work); F2065, an extern that names a row IS the row (both
engines ask the registry first, so a same-named extern's seats were
discarded in silence; it fires nowhere, which is the point); and
`make externs` holds the `Bytes` exemption by whether the CALLEE KNOWS
THE LENGTH — from its prototype, or from the box header that only core
may read — which is why three of our own lengthless seats are right
and foreign C's never are. Merged with one conflict, the keeper's
self-test list (octet and inert cases unioned, 92 hold).

The review round (c1dea58) found the frame's text door justifying its
unconditional check with the sentence F2065 had just disproved — the
check stays, the reason moved, and a comment carrying a justification
carries the true one. `carries_text` stays where it is until a THIRD
consumer asks the question.

S2C, THE DESIGN NOTE (1247120, `docs/2026_09_07_S2C_DESIGN.md`), read
whole and APPROVED IN SHAPE before any code, with lane A's review in
the named tree. Its centre is a hazard found by looking at how the
corpus runs: every corpus program runs in ONE PROCESS, so a library
opened `RTLD_GLOBAL` would let every LATER program reach `sqlite3_open`
whether or not it declared the dependency — a PASS that should have
been a refusal, decided by directory order. The library is opened
`RTLD_LOCAL`, written explicitly, and the scope test is an ORDERED pair
in one process. Its second find is the deadline law self-applied: the
acceptance test "no sqlite dependency refuses `sqlite3_open`" passes
today only because the symbol is ABSENT from `build/avra`
(`nm | grep -c` answers 0, verified on main by lane A), so it expires
the day anything links sqlite into the compiler.

THE TWO QUESTIONS, answered by lane A and matching this lead's
recommendation: the lookup takes the handles AS AN ARGUMENT
(`avra_ffi_symbol_in(handles, name)`) — the frame's staging area is
per-CALL scratch and a handle set is per-PROGRAM identity, and a set
held in frame state is §1's leak one layer up; and `tools/libs.py`
groups the `[link]` rows per package and answers a package's library as
DATA that `stems.sh` consumes, since make cannot parse TOML and a
generated `.mk` adds a staleness nothing reports. Folded in before
code: the ordered test WITNESSED failing under `RTLD_GLOBAL`; the order
of the pair a property of the harness, never of a directory walk; the
gate's corpus target depending on `libs`; every §5 number with its
commit beside it (2,263,008 bytes is lane/http's image, main's is
2,122,704 — unbased numbers are not a comparison); §6 as its own line
in §2.3; and a registered condition — under the evaluator two programs
that depend on sqlite share the library's PROCESS-GLOBAL STATE, which
native never did, and symbol scoping does not scope state.

Order from here: the `avra_exec_self` row and the aggregate-seat law
(ROW, ruled; the law worded as the PLAIN half of F2056, lane D's
verified wording), then S2c in its §8 order.

## Door 3 landed: a `once` answer is IMMORTAL (main 2b4685d, merged at 6c3522a, seed 1c47ce5)

Lane A landed the second half of the `once` ask on the owner's word in
their session: a `once` answer is minted once and lives for the
process, and its header says so as a REFLECTION of the kind
(`-(kind + 4)`, negative for every shape so `kind < 0` still no-ops
retain and release for free) — never a replacement for it. TWO
DESIGNS FAILED FIRST, both worth carrying with lane A's name on them:
marking the box `KIND_STATIC` CORRUPTS, because `box_clone` dispatches
on kind and a once-answered map would have been cloned as an array —
the registry law in C again; and the BORROW route (`lends: true`, no
retain) segfaulted every suite, because the lowering's region has ARMS
THAT DIFFER IN OWNERSHIP — the present arm carries the cached value,
the absent arm a fresh one — and the caller releases either way. That
is what immortality buys and borrowing does not: it makes the
asymmetry HARMLESS instead of teaching the lowering about it. And the
prerequisite landed as part of the decision: an immortal value is
shared by definition, `is_shared` answers true, a write through it
copies (lane A's probe: `after poke: 3, cache now: 2`).

THE NUMBER LANE A COULD NOT TAKE, taken here on ONE tree: lane/http
1c47ce5, the same compiler and the same bench binary
(`tools/bench/frame_head`, 2M four-field heads), only the runtime
object swapped between e45e37b's and 1c47ce5's, census sites resolved
by `nm`.

    retains    410,001,348 -> 238,000,998   (205 -> 119 a head)
    releases   480,001,749 -> 308,001,380   (240 -> 154 a head)
    reclaims    70,000,401 -> 70,000,401
    once reads  86,000,194 -> 86,000,194, one pointer compare each
    avra_once_get as a retain site: 86,000,175 -> gone, and the two
    call-site retains behind it (crlf 12.0M, tchar 10.0M) with it

172M retains and 172M releases off the run — twice the read count,
the retain at the read and the caller's release of it. Timing, three
runs each back to back: 2066/2104/2069 -> 2028/2038/2020 ns a head,
~40 ns, ~2%, at the edge of what the stopwatch resolves; THE COUNT IS
THE RECEIPT and the clock only agrees with it. The framer's ledger on
shipping: 2410 (own wastes) -> 2185 (once index) -> 2045 -> ~2030.
Largest retain site now: `avra_array_get_owned` at 11 a head, then the
framer's own `settled` records. Also in this merge: the sqlite lead's
retraction of the lossy claim in four more places, and lane B's
`nul_at` as ONE SEARCH (`s.index_of(nul_needle())`, a `memmem` over
the header's length, allocating nothing) — which beat the octet body
this branch had given the shared helper hours earlier, so that body
and its needle died. All three doors are now decided and two are
landed; door 2 (S2c) is the substrate lane's, approved in shape above.

## The last seam slice (c3b8b18, merged at 7e85f5d): two rows, and F2056's second arm

The substrate lane's fourth fix on the ROW ruling, green from a cold
bootstrap. THE SWEEP SAID ONE AGGREGATE SEAT AND THERE WERE TWO:
`avra_spawn_status(prog, args: List<string>)` is declared inside a
program `tools/traps.sh` GENERATES, so a grep over `.av` files could not
see it — the generated-caller lesson, second firing — and it would have
turned `make traps` red at this merge. Both are runtime rows now on
§2.1's reading (their C reads an `AvraArray`); `avra_exec_self` re-execs
under `avra run` for the first time, and the receipt is behavioural (it
re-ran the compiler and printed `explain F2056`). F2056 grew its second
arm in lane D's verified wording — the voice and the test say PLAIN, so
the `mut` half already settled is never re-litigated — and the law is
spelled as what is ALLOWED: a new type is refused at an extern seat
until someone decides it crosses, because C is on the other side of
that door. A ROW'S WORDS NEEDED THEIR OWN CHECK, which nobody had
named: the seam checks a SEAT, and a `List<string>` seat is a pointer
to a box, so every word inside crossed unexamined while `execv` and
`posix_spawn` resolve each one; both C bodies check per word, and the
trap contract sits on the SPAWNING twin, because a contract whose
regression is a fork bomb does not belong in a harness (§2.8).

A REFUSING MIRROR WAS ASKED FOR AND NOT BUILT, with the number: a rule
refusing a `string` seat over a length-carrying prototype is sound in
one direction only — an integer after the pointer may be a flag, and
`open(const char*, int)` declared `string` is correct — and it fires
ZERO times on this tree, since every such seat is `Bytes` already. A
rule with no true-positive rate and a known false-positive shape is
F2040 in new clothes, so the other surface is WITNESSED: `make externs`
reports the nine `Bytes` seats that earn the exemption. The right call.
§7.3's near-miss is worth carrying: four probes run while `make
bootstrap` was relinking `build/avra` came back CLEAN and would have
read as the law not firing — during a bootstrap there is no stable base
for a probe to name.

LANE A'S ARITHMETIC ON THE DOOR-3 NUMBER, which says more than either
of us claimed: 172,000,350 retains removed over 86,000,194 `once` reads
is 2.00 per read where the design predicted ONE. `avra_once_get`'s own
retain is 86M of it; the other 86M is every OTHER site that touched the
value, because an immortal box no-ops a retain wherever it is taken —
`crlf` and `tchar` are two, and 64M sit at sites nobody listed. The
exactness of 2.00 says the account is complete. So immortality is worth
about twice what borrowing would have been, which is a second argument
for the door that nobody had when it was chosen. And RECLAIMS UNCHANGED
AT EXACTLY 70,000,401 BOTH WAYS IS THE CONTROL: nothing died
differently, only the counting stopped — a refcount change that moved
reclaims would be a behaviour change wearing a performance change's
clothes. The `KIND_STATIC` failure is the registry-obligation law in C
for the second time on one file: `box_clone`'s kind dispatch is a chain
keyed on our kinds that no keeper can see, as `acc_kind_of` was.

AND THE SECOND ROW CLOSED A BLIND SPOT IN LANE A'S KEEPER (main
e05d4b2, merged at c148b12): `make externs` globbed `packages/` and
`corpus/`, and `tools/traps.sh` writes whole programs from heredocs —
four `extern fn` declarations it had never read, one of them the
genuinely unchecked `avra_spawn_status`, the other three covered BY
ACCIDENT rather than by scope. It reads the GENERATOR now, not its
output, because a keeper whose coverage varies with which target ran
first reports different things on different days. Lane A's sentence
is the one to keep: A KEEPER'S GLOB IS A CLAIM ABOUT WHERE ITS SUBJECT
LIVES, and this one had been wrong twice while reporting green — the
showcase in `corpus/`, then the generated fixture — both times exactly
where the interesting declarations were. 300 externs, 562 seats here.

THE PREMISE UNDER `Bytes`, RE-READ AFTER THE RETRACTION. Lane D swept
CLAUDE.md's three stale receipts (the five primitives NUL-lossy, a text
EQUAL to its own prefix) and marked ROADMAP H1 — "is a `string` text,
or bytes?" — ANSWERED BY IMPLEMENTATION: the entry's two ways out were
"make the five length-aware" or "add `Bytes` with exactly that scope",
and lane A took the first. So one argument for `Bytes` is gone, and
the design was re-read for anything that DEPENDED on it. Nothing did:
the feature's words are octets as a value (`s.bytes()` total,
`b.text()` null unless UTF-8, `==` over every byte); the seam's
exemption is a seat whose PROTOTYPE carries the length, a fact about C;
the framer scans indices over octets because a body need not be text.
The shape paper quotes the lossy claim at its line 11 as the question
that opened it and marks that reason STALE at its line 203. `Bytes`
stands for binary data on its own terms — the stronger footing, as
lane D said. A DESIGN INPUT IS A RECEIPT TOO, and this one was probed
before it was sent, which is exactly why it read as trustworthy; the
check that found nothing to re-plumb cost one grep and is what makes
the footing a fact rather than a hope.

RECORDED TRIGGER (lane B's caveat, on the record at their ask): the
shared `nul_at` took the string SEARCH (`s.index_of(nul_needle())`)
over this branch's octet body because the search allocates nothing and
`s.bytes()` copies — a comparison measured over `string` (lane B's 41x
on main, 1.64s -> 0.04s over 2M guarded words), never over `Bytes`. It
FIRES when a string's bytes become a borrowed view rather than a copy:
then the octet form is allocation-free too and the choice is
RE-MEASURED, not inherited from that number. Owner: nobody yet — that
view is unbuilt and unasked-for.

## S2c step 1 (816a7a2, merged): the package libraries, derived — and the design shrank twice

`tools/libs.py`, `make libs`, the keeper, the measurements. Building
it found two things the note could not, and both make the design
SMALLER. A PACKAGE THE COMPILER ALREADY CARRIES GETS NO LIBRARY: six
packages declare `[link]` objects and three — @std/avrac, @std/io,
@std/process — are inside `build/avra`, which is why S2a could host
their externs at all; a library for one adds no reach and a SECOND
COPY of state meant to be single (`ffi.o`: one staging area in the
image, another in the library, lookup order deciding which a call
used — §1's leak by a different cause). The roster is the linking
packages MINUS the image, tested with `nm build/avra`, the instrument
stems.sh already reads, so one truth answers both questions: THREE
libraries, not six, and a package split across that seam is refused
in words. THE RUNTIME IS LEFT UNDEFINED ON PURPOSE: the first link
failed on `avra_trap`, and linking the runtime INTO each library —
the obvious fix — would give every library its own allocator, free
lists and accounting, so a box minted in one and released by the
evaluator reaches the wrong list. The libraries bind those symbols to
the HOST at load. Measured: exactly one runtime symbol left open
across all three (`avra_trap`, @std/net); sqlite and the witness
leave none; the rest is libc. The flag that permits it also permits
a typo, so stems.sh holds every undefined `avra_*` to what
`build/avra` exports, consuming `libs.py --undefined` rather than
re-deriving — witnessed failing first on a bogus `avra_nosuch`. The
same instrument answers the question this lead asked about a symbol
that is neither `avra_*` nor libc: `--undefined` names every open
symbol per library, so a new one is visible.

LANE A APPROVED THE BINDING AND CORRECTED ITS REASON, which is the
half worth keeping: the free lists are the WEAKEST argument — two
copies of `g_free[CLASSES]` PARTITION one malloc heap rather than
corrupt it (a box freed into one list is re-used from that list), a
footprint cost, and a footprint argument loses to "it links". THE
DECISIVE REASON IS `g_once`: a second copy of the `once` table means a
`once fn` reachable from both settles TWICE with two different
answers, where "one value for the whole process" is the contract
F2055 exists to protect — and since 2b4685d those answers are
IMMORTAL, so two immortal answers where the language promises one,
neither ever dying. A semantic break, not a cost. Second, `g_acc_live`:
`AVRA_MEM_STATS` would report one copy's view and look complete —
`acc_kind_of`'s lesson, structurally. And the honest narrowing: today's
libraries are PURE C from `[link]` rows — no Avra code, no `once`, no
allocation — which is exactly why one open symbol was measured; the
hazard is not live at step 1, it is what makes "bind to the host" the
RULE rather than a lucky default, and it fires the first time a
package's C calls back into Avra. `hdr()` is no obstacle (alignment and
a 4 GB floor, not an image range), and `T _avra_trap` is exported.

NUMBERS ON ONE BASE (b2255fe): `make avra` 12.45s/2.08s -> 12.22s/
1.81s user/sys; `build/avra` 2,263,728 bytes BOTH times, the same
number and not a similar one; the three libraries link in 0.52s and
occupy 1.73 MB in `build/`, nothing in any user's binary. WALL TIME
NOT QUOTED, and the reason is a law for this machine: the "before"
run's wall was 503s against 12s of CPU, all of it waiting on the
shared build lock — WALL TIME HERE MEASURES THE QUEUE, so CPU is the
measurement and wall is noise with a plausible face. The gate's
corpus target took its `libs` dependency before anything opens a
library. Gate green at 593 MB peak with the libraries built inside it.

## S2c step 3 landed (1bb5684, 7a56bc2, 6ade15d; merged, seed 934f395): the evaluator reached package C

`corpus/net` and `corpus/http-serve` read `eval == native == expected`
— the first package C the evaluator has ever reached. The closure's
libraries open `RTLD_LOCAL`, written explicitly; the absent library
refuses by name; the workspace hands the closure's derived stems
through `Lowered.libraries` and no manifest path is ever opened.

THE ORDERED PAIR DIED, and the reason is worth more than the test: the
corpus runs many programs in ONE process — exactly what the leak
needs — but builds ONE WORKSPACE over the directory, so every program
shares one dependency closure, and "a program that does not depend on
sqlite, running after one that does" cannot be written there. A
harness for two closures would have been a compiler change made to
serve a test. So `tools/libscope.sh` tests the MECHANISM directly: one
program that depends on @std/sqlite asks the frame's image-only lookup
for a symbol its own closure opened, and under `RTLD_LOCAL` that
answers 0 — no order to get wrong, no directory walk, no rename that
reverses it. WITNESSED FAILING as lane A required: `RTLD_GLOBAL` turns
the second row red, `RTLD_LOCAL` green again. `make libscope`.

THE HOST TAKES ONE HANDLE, NOT A LIST, and this slice's own law
decided it: `avra_ffi_symbol_in(handle, name)` asks about one library
because an aggregate cannot cross an extern seat under F2056, so a
`List<int>` of handles could not be a seat at all; the loop lives in
the evaluator, where per-program identity belongs. Lane A reached that
from the LIFETIME side, the seat law from the TYPE side, and they met.

AND SQLITE STILL DOES NOT CROSS, FOR A DIFFERENT REASON — the honest
result: `corpus/sqlite` and `corpus/sqlite-refusals` refuse with
"`sqlite3_open_v2` has a `mut` seat — the frame does not carry an
inout yet". That is §5.6.8's recorded refusal, whose trigger read "the
first in-image extern with a `mut` seat, or S2c putting a package's
own C in reach" — S2c FIRED IT, so the inout frame is the next slice
rather than a surprise, which is what a recorded trigger is for.

THE KEEPER ACCOUNTS FOR EVERY OPEN SYMBOL (6ade15d), and the answer to
"what bounds a symbol that is neither ours nor libc" is sharper than
"nothing yet": under `RTLD_LOCAL` a symbol another PACKAGE's library
defines cannot resolve AT ALL, so a cross-package C reference is a
DEFECT the keeper names exactly. Three bands per library — OURS (an
`avra_*` the host exports), MISSING (an `avra_*` it does not: the typo
band, refused), FOREIGN (the platform's; one another library defines
is named as a cross-package reference and refused) — both new bands
witnessed on planted symbols, and "libstd-net leaves 26 symbol(s) open
— 1 ours (avra_trap), 25 the platform's" printed so a new one arrives
visibly. The runtime-binding reason is corrected in the note and in
libs.py's docstring to lane A's: `g_once` decisive, `g_acc_live`
second, the free lists a footprint argument; and the hazard is not
live while the libraries are pure C. Two derivations of the library
stem (the compiler's and libs.py's) are tolerable where `keeps` and
`inert` were not, because a disagreement here is LOUD — nothing opens,
the refusal names the package — and that reason is written down.

THE TRACKER. On the owner's word the tree's work is now tracked in a
LOCAL SQLite db (`TASKS_DB=/Users/tristan/projects/tristanMatthias/
avra/.tasks/avra.db`, root `avra-8sb5`, the `tasks` CLI in direct
mode); this lead is tasks master for every stream. Two lanes declined
to switch their reporting channel on this lead's relay of the owner's
word — the right fence — so the owner's own line in each session is
what moves them; meanwhile their lists are mirrored into the db from
their messages. 124 open or deferred nodes, including the ROADMAP's
sweep: 61 open asks and unfired triggers filed, landed ones left in
the ROADMAP as its record.

## The S2c red team (d876659, merged at 28a0650, seed 058f215), and lane A's review of step 3

THE ARGUMENT WAS RIGHT AND THE CODE WAS NOT. The design note waved
through two spellings of the stem rule (the compiler's and libs.py's)
because a disagreement between them is LOUD — nothing opens, the
refusal names the package. That holds. Nobody had checked whether the
two spellings AGREED: `lstrip("@")` strips every leading `@`,
`.replace("@", "")` strips one anywhere, so `@std/a@b` derived two
different stems. Both now strip exactly ONE leading `@` and replace
every `/` — a rule written to be COPIED, the property a twice-spelled
rule actually needs and neither original had. AND THE COLLISION THEY
SHARED WAS NOT LOUD: `@std/a-b` and `@std/a/b` derive ONE stem in both
halves — two packages, one library path, the second build overwriting
the first, the evaluator opening whichever was on disk — under a
docstring that said "two packages collide here only if their full
names collide, which the workspace already refuses", the kind of
sentence that reads as settled so nobody checks it. The build refuses
a collision now and names both packages; the stem is NOT escaped to
buy injectivity, because an escape renames every existing library for
a case nobody has hit. Witnessed both ways. Survived: a bare file with
no closure, a package with no objects, an unbuilt library, a handle of
0, both keeper bands under attack; the three libscope rows held.

LANE A REVIEWED STEP 3 at 934f395 and approves the mechanism —
`RTLD_NOW | RTLD_LOCAL` written explicitly with its reason, and the
detail that carries the narrowing: a handle of 0 answers 0 rather than
reaching the process, the one line they read first, since a zero
handle falling through to `RTLD_DEFAULT` would have undone the design
quietly. `libscope.sh` is better than the pair they asked for, for the
reason given. ONE FINDING, in their own pattern from tonight:
`symbol_of` (interp.av:825) is called once per extern call and
allocates a list to find one element, evaluates every handle (N
`dlsym`s, not until-found) and repeats a lookup whose answer is fixed
for the life of the program — the third instance of A LOOKUP WHOSE
ANSWER CANNOT CHANGE, RECOMPUTED PER USE (`once_at`'s scan, 19 probes
a read, now 1; `avra_once_get`'s retain, 104M gone). Fix: a memo keyed
by callee, the image fallback memoized alike; measured before/after
under `avra run` over corpus/net, which is differential now. Routed
to the substrate lane's review round (the file and the arc are theirs;
lane A reviews the result). Lane A's closing line is worth the log: a
design two independent laws agree on — the seat law and the lifetime
law meeting at one handle — is one nobody has to remember the reason
for.

## S2c COMPLETE (030a66a, merged at 06e3862, seed ec96a1e): the review round, and what the arc delivered

The review round found one real thing and the arc was otherwise clean:
the machine held bare handles in a list PARALLEL to the program's
libraries, so the refusal that names an unopened package indexed one
list by the other's position — both readers need both halves (the
lookup asks the handle, the refusal names the package), and they
travel as one value now, the index arithmetic gone with the alignment
it depended on. Two leave-alones with reasons: `opened` tries `.dylib`
then `.so` rather than asking the platform, because the compiler has
no platform verb and inventing one to save a failed `dlopen` on a cold
path is the wrong trade (kept); and `symbol_of` evaluating every
handle before taking the first hit "because only a miss reaches it" —
NOT kept, because the premise is wrong: `hosted_extern` calls it on
EVERY extern call (interp.av:704), which is exactly lane A's finding,
and the memo (.1.13) is the next slice.

WHAT S2C DELIVERED, for the owner's read: a program run under the
evaluator reaches a package's C only when it DEPENDS on the package —
one derived library per linking package outside the image, opened
`RTLD_LOCAL`, asked before the image, refused by name when unbuilt;
`corpus/net` and `corpus/http-serve` differential for the first time;
the leak refused by mechanism and witnessed under `RTLD_GLOBAL`; the
keeper accounting for every open symbol in three bands; one stem rule
and a collision refused. What it did not deliver, honestly: the two
sqlite corpora stay native-only, because `sqlite3_open_v2` has a `mut`
seat and the frame carries no inout — §5.6.8's recorded trigger fired,
and the inout frame is the substrate lane's next slice after the memo.

## Main merged (d8422aa, 082f284, 8bb0d85) and the symbol memo (d8f996a, merged at fcfa831; seed a59138d)

MAIN'S ELEVEN: lane A's watchdog DISK FLOOR (e7e1d1f — it REFUSES where
the memory floor WAITS, because memory pressure passes when a process
exits and a full volume stays full, so a wait loop would spin forever
while looking like patience; exit 2, remedy named, `AVRA_DISK_FLOOR_MB`
moves it, checked before the lock), the integrator's TREE PIN
(fe1c152 — HEAD, the tracked content and the untracked list pinned
across the gate; its first draft pinned the porcelain alone and its
own test caught that the porcelain names WHICH files are dirty and
not what is in them), the content-hashed object rule (ba2f495), the
keeper refusing an integer seat over a pointer (5542ef3), lane B's
Env.get narrowing, and the doctrine sweeps. TWO CONFLICTS. The keeper:
a union. THE MAKEFILE, a FOLD: main hashes two NAMED objects
(`build/runtime.sha: SHA_SRC := …`), this branch builds every object
through ONE stem rule with per-stem flags and `-MMD`, so two named
rules beside it would have been the stem law's second definition and
bypassed both. The fold is `build/%.sha: %.c FORCE` — the stem resolves
its source through vpath as `build/%.o` does — and the object depends
on the stamp. THE FOLD BIT AT ONCE: the first build printed `rm
build/llvm_wrapper.sha …` — make DELETED the stamps — and every object
would have rebuilt every run, the exact opposite of the rule, reading
as a slow build and never as a wrong one. `.PRECIOUS: build/%.sha`
keeps them; witnessed: the second build recompiled the five once
against fresh stamps, the third compiled nothing. LANE A REPRODUCED IT
IN A SCRATCH MAKEFILE AND CORRECTED THE MECHANISM: not the MENTION
(their guess, refused by their own probe) but the CHAIN — `a.c ->
a.sha -> a.o`, made by one pattern rule and consumed by another, and
make deletes the middle of a chain; main's `%.sha: FORCE` has no source
prerequisite, joins no chain, and needs nothing. So `.PRECIOUS` is
LOAD-BEARING AT INTEGRATION, when main takes the generic form, for a
reason visible in neither diff — recorded on the integration task.

THE MEMO (d8f996a, substrate-2, closing lane A's finding): a symbol's
address is asked once per callee — a `Map<string, int>` on the
machine, ABSENCE MEMOIZED TOO (0 is a real answer at this seam, so a
callee nothing carries stays absent rather than re-walking every
handle: the empty-value law at a cache boundary, and a program with
one bad extern name would have paid the full walk on every call), no
short-circuit because caching dominates and the early exit would be
the flag loop. MEASURED on base db688ac, 200,000 extern calls under
`avra run` over a two-library closure, medians of three: the program
1.12s -> 0.58s; the extern calls alone 0.62s -> 0.09s — 3.1 us -> 0.45
us per call, ~7x, bigger than "invisible in the compiler, real in a
framer" because the walk was N `dlsym`s plus a list allocation rather
than one lookup. THE CONTROL: the same loop with the extern call
removed, 0.50s before and 0.49s after — the difference is the lookup,
not the interpreter. Not measured, said rather than implied: the
compiler's own suite, whose native path never takes this seam. Lane A
believes the number for the control. Gate green at 571 MB, seed
a59138d. Disk: 4.6 GiB before the link, checked. Next: the inout frame.

## The INOUT FRAME (e92ac37, merged at a540a3b, seed 79b415c): sqlite crosses to the evaluator

`corpus/sqlite` and `corpus/sqlite-refusals` lost `native-only` and
read `eval == native == expected`; every corpus directory but
`corpus/bytes-header` is differential now, and that one is held by an
unrelated evaluator defect the substrate lane is filing, not by this
seam. §5.6.8's TRIGGER IS PAID AND ITS REFUSAL DELETED: the refusal
said the marshalling would be "an instrument nothing could exercise"
and recorded the condition that would change that; S2c fired it, and
the refusal was removed rather than left beside its replacement — a
trigger is paid by the code it held a place for, and a dead refusal
that still reads as current is the thing this tree keeps finding.

THE SQLITE RED TEAM'S FINDING, REPRODUCED AND CLOSED BY CONSTRUCTION.
With the width normalisation disarmed, the width witness answers
`out=4294967295,4294967294` where native says `out=-1,-2` — a plausible
number, not a crash, exactly the `int*` shape they reported: a C
`int*` writes 32 bits and leaves the top half of a 64-bit cell stale.
The frame reads the width from the SAME `cells` column the backend's
normalisation reads, so the two engines agree by construction rather
than by two hand-written tables happening to match; restored, they
agree byte for byte across every seat the witness has.

TWO THINGS WRONG FIRST, BOTH THE EMPTY-VALUE LAW at a seam built this
week: `whole` calls a `null` a defect, and a `ptr?` cell STARTS at null
— `sqlite3_open_v2`'s handle is precisely that — so seeding had to
read `word_of`, where absence is the address zero; and reading back,
zero is ABSENCE and not the number nought, or a program that took `0`
for a failed open would carry a non-null handle to a database that
never opened. Walked into twice by the author of the seam, which is
the law's own claim about itself.

Merged clean, built twice, gate green at 596 MB with both sqlite
corpora on both engines, seed 79b415c (3.5 GiB free before the link,
checked — the volume is drifting down again as lanes build). The
substrate lane's red team and review round over the frame come next,
on their own task; S2c's remaining open item is `bytes-header`.

## The inout frame's red team and review (25b73dd, 7a1abdd; merged at a9f7963, seed 1c21943)

THE DIVERGENCE HUNTED HAS NO PROGRAM. The attack expected to land was
aliasing — one `mut` binding handed to TWO seats of a single call: the
frame gives each seat its own storage, so it would pass two addresses
where native passes one and the engines would disagree about which
write survives. It cannot be built: F2048 refuses it at check time
("`same` is handed `mut` twice in one call"). Recorded as a survivor
rather than shrugged off, because THE FRAME DOES NOT DEFEND AGAINST IT
AND DOES NOT NEED TO — the defence is upstream, in a law written for a
different reason, and whoever narrows F2048 later would be taking a
load this seam never knew it was carried by. Knowing which layer holds
a property is how it stays held; it is written at the seam now. The
rest of the set found nothing: every width the `cells` column can name,
a cell the callee never writes (the seeded value survives — the inout
half of the contract, now a test), a call refused before the frame runs
(cells not settled), a stale cell from an earlier call (reset zeroes
the cell storage as it zeroes the slots).

THE REVIEW found two things in code an hour old: `settled_cells` built a
slot map on EVERY extern call to discover nothing needed settling — an
allocation per call beside the lookup just made free; it asks the cells
column first now — and one projection spelled twice. NOT QUOTED AS A
WIN: 0.58s before, 0.60s after, inside a control that varies 0.48 to
0.50; the saving is real but small for a one-seat extern, the change
stands on the reasoning (the cost grows with seat count, the benefit is
the common case), and saying so beats dressing a noise reading as a
result.

WHERE THE EVALUATOR STANDS, for the owner: every corpus directory is
differential except `corpus/bytes-header`, held by an evaluator defect
("a non-string reached text in a clean program") the substrate lane
now owns; package C, sqlite included, runs under `avra run` and answers
what the native binary answers. That was the whole arc. Disk: 2.3 GiB
free before the seed's link — falling as lanes build; the floor lane A
set will start refusing links at 2 GiB, which is the design working.

## The night the disk filled (2026-09-08): a refusal that re-entered itself

The data volume hit ~500 MiB free three times in six hours, and the
explanations went in this order, each better than the last and only
the last one true. FIRST: the owner's data — 884 GiB used, the avra
trees under a gigabyte, a directory walk seeing 344 GiB and a ~540 GiB
gap invisible to `du`, which is APFS snapshot retention around a
pending macOS update (still true, still the owner's, still the only
DURABLE fix). SECOND, on the owner's word: cleaning — 390 MiB of
corpus outputs and IR dumps across the avra worktrees, 4,087 MiB of
`target/` and `build/` from the forge trees; free space rose to 4.8
GiB and fell to 653 MiB within an hour with nothing deleted. THIRD:
swap — `vm.swapusage` 6.9 GB total, 6.5 GB used, 31% memory free, the
sessions and builds pressing on memory; real, and secondary. FOURTH,
from lane B noticing TWO `./avra build packages/cli` in main's tree
and not killing them: `build/avra-build.out` in main at 4,541,804,579
bytes and growing, its tail the disk floor's refusal — "watch: … links
straight at it. Free space first; AVRA_DISK_FLOOR_MB moves the floor."
— repeated without end, then "cat: stdout: No space left on device /
make[3]: *** [avra] Error 1 / make[2]: *** [bootstrap] Error 2".

THE MECHANISM, from the make levels: `tools/census.sh` removes
`build/avra` to relink it with the counting runtime and runs `make
avra`; `make avra` runs `./avra build packages/cli`; `./avra` on a
tree with no compiler BOOTSTRAPS; bootstrap's last step is `$(MAKE)
-s avra`, which runs `./avra` again, which finds no compiler again —
and lane A's new disk floor (e7e1d1f, right to exist, right to refuse)
refusing at a swap trough turned that re-entry into an unbounded
recursion whose every level appended the refusal to one log. A
refusal that re-enters the thing it refused is a disk fill wearing a
guard's words. The process was killed (the build step, never a `cp`),
the log deleted, 120 MiB -> 4.3 GiB; the census run continues and the
loop returns the moment the floor refuses again, so its owner is
asked to stop it. Filed as a P0 bug under lane A's epic (avra-y1e6):
`./avra` must not bootstrap from inside a bootstrap — an env guard
the way `AVRA_WATCH_HELD` marks the lock — a refused floor inside
bootstrap EXITS rather than re-enters, and the avra rule's redirected
log gets a bound.

THREE LESSONS, each paid for. A DELETION THAT FREES SPACE WHICH THEN
VANISHES AGAIN NAMES A WRITER, NOT A SNAPSHOT — the question "what
consumed 4 GB in four minutes" (lane D's) was the right one and the
first three answers did not answer it; `find -size +300M -mmin -20`
over the plausible directories missed the file because it was inside
`build/`, the one directory everyone had already measured as small,
an hour earlier. THE TRACKER'S ID MINTING COUNTS A PARENT'S CHILDREN,
so a task reparented out of an epic keeps its number and every later
create under that epic collides forever — create at the root and
reparent. AND A KILL IS A VERDICT TOO: lane B declined to kill two
builds because killing mid-`cp` is a corruption path, and that
restraint is what left the evidence in the log to read; the kill,
when it came, was aimed at the writer, once.

## The owner delegated the open decisions (2026-09-08), and the restart closed the disk

THE OWNER'S WORDS: "i need you to handle 4. you are task master. stop
asking me to do this sort of thing." So the four decisions that had sat
under the owner epic were ruled by the tasks master from the lanes' own
options, each recorded on its task with the reasoning, and the owner
queue is EMPTY. Cell<T> (avra-8sb5.8.2): spec 11.5 wins and Cell<T> is
the only door — a copy is a copy, sharing is visible at the type, H3
closes as a consequence, and the nine compiler sites plus @std/sqlite's
close(mut db)/finalize(mut s) are paid INSIDE S2's slice; get/set, not
forwarding; @memo's write is the compiler's state. Foreign bytes
(.8.5): Option A — the copy exported, named unsafe, wrapped, a negative
length refused before memcpy, (null, 0) the empty box, an empty text or
blob an EMPTY BOX and only SQL NULL null, the borrowed view a recorded
trigger. The foreground-gate rule (.5.2): THE LOCK IS THE LAW AND THE
FOREGROUND WAS ITS MECHANISM — a foreground-launched watchdog run the
harness backgrounds violates nothing; a process outside the lock, or
one launched to run BESIDE another, is what the two panics were. Main's
uncommitted files (.5.3): the docs campaign's live edits stay where
they are, the ignore line was committed, and the integrator moves to a
DETACHED CLEAN WORKTREE of main so it never stashes the primary. Two
more, ruled the same way: the law-wording audit is lane D's, one
section per slice, each law probed once; weak captures is a recorded
trigger (the second owner-capturing closure that must outlive a
one-shot), because one consumer does not earn a language feature.

THE DISK closed with the restart: macOS 26.6.2 installed, the three
update snapshots gone, 46 GiB free, swap 1 GB. Lane A's re-entry guard
(8a61f86) and lane C's retain histogram are on lane/http (dc4d16d,
gate green at 708 MB, seed 4382c4a). Every lane session resumed; the
substrate subagent did not, and its uncommitted bytes-header fix is
being finished by its successor from the worktree it left.

## A Bytes at a text seat (0ef691e, merged at d8173f0, seed 1093d2f): every corpus directory on both engines

The last native-only corpus is differential. THE LAW: a runtime row's
pointer seat is filled by BOTH a string and a `Bytes` — natively they
are the same headered box and the C body reads the header either way —
so a `Bytes` at a text seat IS those bytes viewed as text, and the two
engines must agree about it. The decode is lossless for UTF-8 and only
for UTF-8 (twelve bytes through a NUL and a snowman round-trip
exactly); an evaluator string cannot hold arbitrary octets, so octets
that are not UTF-8 are REFUSED BY NAME ("octets that are not UTF-8
reached a text seat — the evaluator carries text as text and cannot
hold these bytes; build natively") rather than approximated, because
a silent disagreement with the native answer is the one outcome worse
than a refusal; the retiring trigger (a byte-lossless string, or a
Bytes twin for the text rows) lives in the ROADMAP's Bytes entry, not
in a code comment. IMPLEMENTED ONCE, in the text projection, so the
fourteen row arms that read a pointer seat as text — twenty-three
`text_val` call sites — inherit it; the class avra-8sb5.1.15 named is
closed by construction. Only then is the corpus the oracle:
`[104, 0, 105]` is valid UTF-8, so `0 0 2 3` is right by the law.

THE SUCCESSOR TIGHTENED THE PREDECESSOR'S DIFF before building: an
eight-variant match over a value the projection only ever answers two
ways was a projection spelled as a registry, and reads as absence now
(`utf8_text(data) ?? self.refused_octets()`); the refusal is a named
voice; the narration left the doc comments. Witnessed first: the stale
binary answered "a non-string reached text in a clean program" on both
corpus programs, the fixed product answers by the law, and a non-UTF-8
`Bytes` traps by name while its length still answers. Coverage:
`corpus/bytes-as-text` (trim, length, the snowman, a NUL inside) and
three specs in run_test.av. Gate green at 650 MB here; std-avrac 2285,
std-sqlite 413. With this, S2c is closed end to end and the final red
team over the branch begins.

## The FINAL RED TEAM over lane/http (three Opus teams, 9e97b5b -> 64a802e)

Three teams, all eight classes each, deterministic, every survivor a
test written first: the HTTP library; the extern seam, the keeper and
the build rules; the Bytes value with its evaluator twin and @std/net.
Roughly 400 programs run. THE FINDINGS, worst first, by the law each
one broke.

THE WIRE HAD NO GUARD ON THE WAY OUT. Both @std/http writers
interpolated `name: value` unguarded while the framer refused those
bytes inbound, so a query value with a CRLF in it split the response
and smuggled a second one — proven end to end against a loopback
server through the library's own documented handler shape; a status
outside 100..999 wrote a malformed status line, a handler's
content-length joined the writer's, its transfer-encoding rode beside
a length, its connection contradicted the fate. One `writable` law
composed from the framer's own `is_tchar`/`is_vchar`; `wire` answers
500, `request` answers `Bytes?`; 29 assertions go red with the guards
removed. A HEAD cut mid-field was introduced by that fix and caught by
re-attacking it — one `as_sent` verb, asked by both readers. The query
reader searched the body per pair: 102 ms per request at default
limits, 2 ms now, fixed structurally so the tests assert what is held
and never a duration. `target()` answered "" for an admitted obs-text
target: `string?` now.

A Bytes CARRYING A NUL RAN A DIFFERENT PROGRAM. `avra_spawn_status`
over ("/usr/bin/true" + NUL + "/evil").bytes() RAN /usr/bin/true
natively, and `avra_host_env` as a Bytes answered PATH for a name that
is not PATH; the identical values spelled `string` were refused in
both engines. `crossing` tested `is .Str` — the registry-is shape this
tree's own doctrine condemns — and forgot `.Bytes`; the evaluator's
`text_of_val` had `rest -> null` and forgot it too, so its trap arrived
from a different seat and was a near-miss, not a check. The exemption
is load-bearing for a PACKAGE's extern (sqlite3_bind_blob carries its
length), so the check is scoped to core rows, whose non-inert bodies
carry no length beside the pointer, and `names_a_name` spells every
Type arm under `make vocab`. `starts_with` used strncmp — the sixth
NUL-blind verb after f57372a's five; `read(0)` stole a byte off the
wire; `Poller.wait(ms(-1))` blocked forever three verbs below a
refusal of the same budget; a string at an octet row was a defect
shown to a user (0ef691e's law read the other way, the half left
standing); and AN EFFECT AFTER A REFUSAL — a row that reads and acts
in one expression acted with the stand-in inside it, the child ran —
so the four acting rows read seats, ask `failures.is_empty()`, then
act. That last one no suite can see; the receipt is the probe.

THE CROSSING HAS TWO ENDS AND ONLY ONE WAS HELD. The keeper abstained
on every bool, float and f64 seat — `points_at` named four of seven
scalars — so nine declarations lying about their C passed as matching
and were COUNTED among the 577; a register file is not a width. An f32
C return read through a declared f64 answers 5.28e-315 for 1.5f in
BOTH engines — a green differential over a wrong number, the claim
retracted in the standard and its ancestor. One symbol in two
libraries: `symbol_of` memoizes under the NAME alone, so the
evaluator ran alpha's C for beta while native could not link, and
eval == native never saw it because there was no binary; stems.sh
refuses it tree-wide. F2056 held every seat and nothing held the
ANSWER: a record, enum, dyn or Bytes answer from a non-row extern
segfaulted after a clean check — the answer arm now, two
positively-spelled sets because the ends differ. A `void` seat reached
the frame past three comments asserting it could not; a case-only
stem clash was silent because build/ is a directory, not a set of
names.

WHAT SURVIVED, which is the other half of the receipt: the router,
attacked hardest, zero findings (its oracle-vs-scan design is why); 38
wrong-type placements with exactly one error each and no cascade; an
88-line eval-vs-native differential over the whole HTTP library,
byte-identical before and after; the inout frame 10/10 on both
engines; the content stamps' five claims; ownership 0 live at exit
under AVRA_RC_GUARD and AVRA_MEM_STATS everywhere; the Bytes UTF-8
matrix at every text row; every net refusal naming verb, subject and
the platform's word on both engines.

RECORDED, NOT FIXED, each filed with its probe: a nullable at a host
seat is a NULL C dereferences (atoi(null) SIGSEGVs both engines and
the evaluator takes the compiler down — avra-somc, this lane, before
integration); absolute-form targets route unlike origin-form (ruled:
`path()` answers the path of every form — avra-ffek, this lane);
a row's Ptr seat says a pointer, not which box (an RtSig column —
lane A, avra-ihk9); an extern fn used as a value is F0900 in all three
engines (avra-3cvq); a program ending in a range-headed `for` traps
`avra check` on main too (lane C, avra-qx1k); four comparison rows
still refuse octets (a ROADMAP trigger). Gate green at 709 MB; seed
64a802e.

BOTH OF THIS LANE'S TWO ARE NOW FIXED. avra-somc (317c72b): a nullable
at a CORE ROW's seat is F2066, refused by name where the compiler knows
the body; and at a PACKAGE's seat the null STAYS, because `free(null)`
answers under both engines and @std/sqlite hands `SQLITE_STATIC` — a
null — at every bind seat. The evaluator guards the FAULT instead: a
SIGSEGV inside a hosted call is a trap naming the callee and the seats
that carried absence, pinned by `tools/traps.sh`'s new `trapped_run`.
avra-ffek: `Request.path()` answers the PATH COMPONENT of every target
form and `authority()` hands back what it stripped, so `/admin` and
`http://h/admin` reach ONE handler through the real router — measured
200/404 before and 200/200 after, in `corpus/http-route` on both
engines and in 31 specs.

TWO PROCESS FINDINGS. The three teams were briefed with the lane's
PATH as "your isolated worktree" and all three worked in the branch
itself, interleaving commits and, once, sweeping one team's
uncommitted evaluator halves into another's commit (5099e70 carries
findings its message does not describe); a brief names the agent's
OWN worktree or names nothing. And THE SURVEY: on the owner's word
every agent is now asked at the end of its life what it wanted from
the language and did not have — forty wants under avra-8sb5.11 from
three teams, the count already doing its job (a differential command
and raw multi-line strings asked for by every team; `index_of` with
no bound and a public struct literal each named as the CAUSE of a
defect rather than friction).

## The red team's two follow-ups (317c72b, 546a76b) and main's typed link rows (f6a9cca, seed a46e4dd)

A ROW'S SEAT TAKES NO ABSENCE, AND THE EVALUATOR GUARDS THE FAULT
RATHER THAN THE NULL. `row_agrees` compares ABI kinds, and a nullable
fills the same Ptr its present twin does, so a declaration naming a
core row wore the row's shape exactly and `atoi(null)` went through to
a SIGSEGV in both engines, the evaluator's taking the compiler down
with it. F2066 refuses a nullable at a ROW's seat by name ("seat 1 of
`avra_host_env` wears `string?`, and a runtime row's seat takes no
absence"), three specs witnessed failing first. THE PACKAGE HALF
DEVIATED FROM THE RULING, ON A MEASUREMENT: `free(null)` answers 7 in
both engines today, and @std/sqlite hands SQLITE_STATIC — a null
pointer — at every bind seat and a null vfs at open, so refusing the
null under the evaluator would refuse two shipping doors and MINT a
divergence where the engines agree. The null is not the fault; the
dereference is, and only the callee's contract says whether it makes
one. So ffi.c arms a verdict around each hosted call and takes
SIGSEGV/SIGBUS inside one — "a foreign body faulted inside `atoi` —
seat 1 was handed `null`", exit 2 — async-signal-safe by construction
(words composed before the call, one write, one _exit); a fault outside
a hosted call restores the default disposition and re-faults, so a
compiler defect still wrecks exactly as before. Wider than a null
check (a stale ptr and a freed handle end the same way) and free for
every correct program. tools/traps.sh had no way to pin an `avra run`
law at all; `trapped_run` shares its scaffold now, 24 contracts.
Recorded: natively `atoi(null)` is still a bare signal — whether an
Avra binary should ever die so is the runtime owner's call.

`path()` ANSWERS THE PATH COMPONENT OF EVERY TARGET FORM. Measured
through the real framer and router before: origin `/p` 200, absolute
`http://h/p` 404 — the differential. After: both 200 with
authority `h`; `http://h` is `/` (9110 §4.2.3, minted rather than
sliced, or the root's one slash-less spelling 404s); asterisk-form and
authority-form answer a null path and `dispatch` never walks the table
for them. `frame.av` gained `TargetForm`, and `target_form_fits` is a
projection over it — one decision, two readers. The hostile case that
paid: `http://h?x=/admin` has authority `h` and path `/`. 31 specs in
target_form_adversarial_test.av, corpus/http-route differential,
std-http 427. One call to overturn if wanted: `authority()` answers
null for authority-form (CONNECT), spelled as its own arm.

MAIN'S TYPED LINK ROWS could not be bootstrapped from main's seed:
that seed names `avra_io_*`/`avra_proc_*`, the runtime symbols this
branch moved into package objects under the standard, so the link
failed — and DELETED build/avra, exactly as the doctrine says; the
saved copy was the way back. The syntax-change protocol carried it:
our seed, the compiler package's manifest in the OLD spelling for the
first build, then the typed spelling built twice by the product that
reads it. No other manifest here spelled `flags`. Gate green at 667 MB.

## THE REVIEW ROUND over lane/http (2123273 … bff319e)

THE HEADLINE IS A KEEPER THAT HAD NEVER OPENED THIS CAMPAIGN'S CODE.
`tools/idioms.py` kept its scan roots as a hand-written list of twelve
`packages/*/src` paths. std-http, std-net and std-sqlite were never on
it, so every `make idioms` of this campaign — inside every gate, on
every merge — printed DEBT 0 over three packages it had never opened.
71 unlicensed sites were behind that, including three
`xs[xs.length - 1]` where I7 has been ratcheted for four milestones,
one `?? 0` on a payload the caller had already proved (I18, which
exists because that shape is a SILENT WRONG ANSWER), and twelve
imports nothing used. The roots are read from `packages/*/src` now,
and the run PRINTS WHAT IT LOOKED AT — 389 file(s) in 16 package(s) —
because a check that examined nothing is not a check that passed and
the number is the only thing that tells a reader which one happened.
DOGFOODING's bar grew a fifth law for it, and names the two other
known hosts of the same disease: the Makefile's two link sites, and
any keeper whose subject list a new arrival does not join.

TWO MATCHER REACH DEFECTS FELL OUT OF THE WIDENING, and both were
ACCUSING CODE THE COMPILER REQUIRES:

- I23 took a fn's parameter list to the LINE'S LAST `)`, so a one-line
  body holding a lambda put that lambda's seat in the fn's own list.
  SEVEN sites in std-sqlite were that, latent, against 23 true hits —
  and the round TRIPLED it to ten in one commit, because DRYing
  target_form's three readers into `tf_read(line, pick)` wrote three
  more one-line bodies with lambdas in them. A latent false positive
  is invisible until a new consumer writes its shape; that is the
  whole of how this one surfaced. (5aa15e5's message quotes "nineteen
  true ones" and a 34% rate; nineteen is the count of HANDLERS
  renamed, and the true HIT count is 23 — the rate is 30%. Corrected
  here rather than in a rewritten commit, which is what this file is
  for.)
- I21 read ONE field segment, so `pr.s.turn(…)` — a writing method on
  a field PATH, which the compiler refuses to call on a `let` — read
  as no mutation at all. Three sites accused.

AND THE MECHANISM THOSE TWO WERE MISSING: a keeper has two surfaces,
and every fixture the tool had exercised only what it REFUSES. `CLEAN`
holds the shapes a rule must NOT fire on, checked beside SPECIMENS,
and both entries were WITNESSED FAILING against the pre-fix matchers
before the fixes were kept.

WHAT THE ROUND FOUND IN THE LIBRARY ITSELF, by shape:

- A LAW TWO WRITERS KEPT, SPELLED TWICE. `sendable` (the reply) and
  `sayable` (the request) each hand-spelled the smuggling law — every
  field framable, none of the ones the writer writes itself. This
  module already composes its CLASSES rather than restating them
  (`path_char` from `is_target`); its field law was the one place that
  did not. `fields_writable(headers, written_by)` is the one spelling.
- THE FRAMING LAWS A REQUEST AND A REPLY KEEP ALIKE, spelled twice —
  the field fold, the delimited-two-ways refusal, the coding refusal,
  the body bound, the persistence rule. Three verbs hold them now
  (`framing_of`, `body_refusal`, `persists`) and the two callers keep
  their own asymmetries where they belong. THE EXTRACTION SURFACED AN
  ASYMMETRY NOBODY HAD DECIDED: a REQUEST is refused for chunked on
  HTTP/1.0 and a REPLY is not. Filed (avra-8sb5.1.16) rather than
  changed — a shape round does not move a framing law.
- TWO HEX READERS, one in frame.av and one in query.av with its digit
  ranges spelled as bare numbers. One `hex_of` now, and `is_hex` and
  the chunk-size reader compose from it, so the class table and the
  value can no longer disagree about the same octet.
- A TABLE READ WHILE IT WAS STILL BEING BUILT: `compiled` put the node
  list in one struct field while another field's expression was still
  filling it through a `mut` seat. Correct today only because both
  hold the same box, and silently empty the day field order or the
  copy rule moves. The root is bound first now.
- I39, A NEW IDIOM: a comprehension over a LIST built only to be
  folded by `.any(it)`/`.all(it)` is a SCAN — seven sites, five in the
  two writer laws above, and the file holding one of them spelled the
  scan correctly two lines further down, which is what makes it a
  habit rather than a belief. Ratcheted, licensed BY THE MATCHER over
  a range (a range takes no methods) and under a paired head.

AND THE TEST DRY THE THREE-TEAM NIGHT PREDICTED. Six suites each built
a `Request` from octets — two pairs byte-identical, an eighth inlined;
three `from_codepoint(0)` helpers; four copies of the server pair
scaffolding, two of them inlined beside the helper that already held
it; three copies of the client wiring; two exchange loops; and in
std-net a `holds` that was `passes` renamed and an `Attacked` that was
`Pair` renamed. Every file in a tests directory is ONE module, so the
prefixes existed only to dodge a clash the sharing removes.
`fixtures_test.av` holds the one builder; 135 net lines went.

I23'S LICENSED CASE GAINED A SPELLING, which is I22's lesson one rule
over: nineteen route handlers whose signature `routed`/`fixed`/
`tailed` owns now name the unread seat `_q`. The bar has ALWAYS
skipped a leading underscore and nothing in the tree had ever written
one — a license the tool could read, sitting unused, while the
alternative was nineteen comments.

LEFT ALONE, WITH THE REASON:
- `method_of`'s nine-arm `when` over `verbs()[0..8]` is index-coupled
  to a list, and stays: its doc says "nothing built per head", and a
  `find` with a closure would build one per request. The coupling is
  real and the trade is documented, which is the difference between a
  smell and a decision.
- traps.sh's rows repeat their program text. That text IS the row —
  a trap contract's virtue is that each row reads standalone — and
  the three NUL positions are a parameter sweep, not a copy.
- `bytes_test.av` and traps.sh hold the same program and the same
  message. Not duplication: `refused_at_run` runs the INTERPRETER and
  `trapped` builds and runs a NATIVE binary, so the pair is a
  two-engine differential of one trap.
- `passes` / `passes_client` / `passes_with` ask three different
  questions of a Result and keep three names.
- Each route suite's own grammars and handler words are its subject,
  not scaffolding.

AND THE SAME DISEASE, HUNTED THROUGH THE ARC'S OWN TOOLS once the
idiom bar named it. Two more live blind spots, both measured:

- `tools/externs.py` walked `packages/**`, `corpus/**` and
  `tools/*.sh` — non-recursive for the last — so
  `tools/bench/frame_head/src/main.av`'s `extern fn avra_now_ns() ->
  int` had never once been checked. It is CORRECT (`int64_t
  avra_now_ns(void)`), which is exactly why nobody found it. Fixed
  here; the keeper now reads 520 declaring sources and says so.
- `tools/libs.py` reads `link.get("flags")` — a key the compiler's own
  manifest law CANNOT admit under `[link]` (manifest.av:103-104 puts
  `flags` under `[link.raw]`, which no manifest declares). So the
  flags list is always empty, `expanded()`'s 17 lines are unreachable,
  and the two keys manifests DO declare are never read:
  `libs = ["m", "pthread"]`. `nm -u build/libstd-sqlite.dylib` leaves
  13 libm/libpthread symbols open, and S2C_DESIGN.md:91-97 says in its
  own words that a package library must link "exactly the objects and
  flags the `[link]` row already promises" or be forced onto
  `-undefined dynamic_lookup`, "the flag that turns a link error into
  a run-time crash" — which libs.py:90 passes unconditionally on
  darwin. Latent here, a link failure on linux. FILED
  (avra-8sb5.1.20), not fixed: it changes what `make libs` emits, and
  the design is the substrate lane's.

Six more hand-kept lists were censused and filed as a group
(avra-8sb5.1.21) — externs.py's two-directory tree-C tuple sitting
UNDER a comment that says "a hand-written list is a registry that
silently forgets its next member", stems.sh's third copy of the same
set, the Makefile's SUITES (audited: covers every package that has
tests today, and nothing checks it — avra-8sb5.1.19). None is a wrong
answer today; each is the same shape as the one that hid 71 sites.

LEFT ALONE THERE TOO: `stems.sh` prints "that rule examined NOTHING"
when no compiler objects are on disk and does not fail. Measured
rather than assumed — `make stems` lists `$(COMPILER_OBJS)
$(PACKAGE_OBJS)` as prerequisites, so make builds them before the
script runs, and the summary reports `$looked` either way. The
mechanism is the prerequisite line, and the keeper already says what
it looked at.

VERIFIED: std-http 427/427, std-net 25/25, std-sqlite 413/413; the
http-route, http-serve, net and net-sizes corpora byte-identical;
`make idioms` debt 0 across 16 packages, `make vocab`, `make
fingerprints`, `tools/externs.py` (10 C sources, 582 seats) and
`tools/stems.sh` (14 rows, 391 symbols) all green. Two defects filed
(avra-8sb5.1.16, .1.17), three survey wants (avra-8sb5.11.47-.49), two
sugar-backlog asks with their wanting sites.

## WHERE THE CAMPAIGN STANDS (2026-09-07, lane/http ea2a6ce)

BOTH SUB-LANE ARCS ARE COMPLETE AND MERGED. Strings: the paper, typed
string patterns, the octet parity (1.24x), grammar values that parse
and print with the round-trip law enforced, the framer's no with its
attack table, the router with a full-depth trie (68x, flat across three
shapes), the query and the tail, the greedy hole (the two domains
complements at the overlap case), and the once-index re-take as a pair.
Substrate: the package-C standard, the extern host, io and process out
of the runtime onto their own C with the evaluator running the same
bodies, the descriptor scratch and the stage, the build's per-target
lists and keepers, the S2c paper. The lead's own: the server loop, the
reply framer, the client, corpus/http-serve, the loop under load and
under the census. @std/http is 259 cases across framer, reply, router,
query, server and client suites, every one in the gate.

THE NUMBERS THE MANDATE ASKED FOR, each with its instrument named: a
four-field head frames in 2,045 ns on shipping (`tools/bench/frame_head`);
the loop serves 102–118k keep-alive requests a second on one core at
8.2 µs CPU a request, 4.9 in the loop and 3.4 in the kernel (`ab -k`,
`ps`); dispatch over 300 routes is 346 ns; a request line by pattern is
1.24x a hand scan over octets.

THE THREE DOORS, DECIDED BY THE OWNER 2026-09-07 and each in the
ROADMAP's HTTP asks with its measurements: (1) a NUL crossing to C —
"do the same thing as other mature languages": the five lossy string
primitives ARE CORRECT (length-aware, lane A's C — landed on main at
f57372a, merged here at 9fe4efe), the seam TRAPS only a seat the callee RESOLVES (a
path, a name, a command word, an environment key — the substrate lane,
in flight), `inert: true` at the site means "reads the header's length",
faces refuse with words first, `Bytes` the escape; (2) S2c — the
per-package shared library the evaluator opens by the program's own
closure, derived by the tree and never named by a manifest (the
substrate lane, after the seam); (3) immortal `once` answers with the
`is_shared` line landed alongside — LANDED, main 2b4685d, merged here at
6c3522a and measured above. Still owed: the validation of lane/http itself, before
anything reaches main.

## Slice 3 — `@std.http` (AFTER)

Message types, an index-driven HTTP/1.1 framer over `Bytes`, a route trie
compiled once, the server loop, a blocking client. Then `/red-team`,
`/review-round`, benchmarks against nginx/h2o numbers.
