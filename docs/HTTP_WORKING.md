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
CHARTERS ARE COMPLETE; the lead's own work resumes. Two laws from the lane's own tests: a hole is ONE
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

## Slice 3 — `@std.http` (AFTER)

Message types, an index-driven HTTP/1.1 framer over `Bytes`, a route trie
compiled once, the server loop, a blocking client. Then `/red-team`,
`/review-round`, benchmarks against nginx/h2o numbers.
