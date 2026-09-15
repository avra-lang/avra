# STD relaunch — 2026-09-14

A session is started with its NAME and this file. It reads the
preamble, then its own section, then goes. The task master is the
session "STD TASK MASTER"; the tracker epic is `avra-ms0j`.

## Where things stand (main at 12738f7)

Surveyed 09-14: commits not on main / uncommitted files per worktree.

| worktree | branch | holds |
|---|---|---|
| ../avra-lane-http | lane/http | +325: package C, extern host, Bytes, string patterns, @std/net, @std/http. lane/strings and lane/substrate are 100% inside it |
| ../avra-stack, ../avra-stack0 | stack/1, stack/0 | squashed cuts of lane/http for PRs #2 → #3 → #4; nothing of their own |
| ../avra-lane-sq-ffi | lane/sq-ffi | 105 UNCOMMITTED lines: a float literal that does not fit (llvm.av, llvm_wrapper.c, corpus/float) |
| ../avra-lane-c, -a, -b, -d, -sqlite | lane/* | +0, clean: merged; tracker state only (Cell<T> .4.8 and the .8.3 audit have no code yet) |
| ../avra-lane-sq-driver, -sq-redteam, -sq-redteam2, -strings, -substrate, -stack0 | | +0 or contained: retired by the master |
| ../avra-comptime-*, ../avra-lane-comptime, ../avra-phase-b, .claude/worktrees/* | | OTHER masters' work — hands off |

`git merge-tree main lane/http` conflicts on ~230 paths: bootstrap/seed.ll,
Makefile, core/ir.av nodes.av types.av, most of language/, and tests that
main moved beside their features. That merge is one session's job; it is
NOT a re-implementation.

New on main since lane/http forked: `@comptime`, `derive` (`@std/derive`:
a trait with `static fn derive(t: Type) -> List<Directive>`, templates as
`quote {}`), `@std/meta`, sugar 1 (context receiver + trailing blocks),
sugar 2 (type literals `type(...)`), program tests beside their feature,
no `corpus/`.

## PREAMBLE — every session

You are `<NAME>` on the Avra compiler (`/Users/tristan/projects/tristanMatthias/avra`,
main). Read CLAUDE.md, then this file's preamble, then your section.
Your task master is the session "STD TASK MASTER" (it messages you first; REPLY to the `from=` address its message carries — the name does not resolve): report to it by
SendMessage. Never message the COMPTIME TASK MASTER or its agents.

Worktree: your section names it. An existing one: `cp build/avra
build/avra.pre`, then `git merge --ff-only main` (or the merge your
section spells), then `make bootstrap`. A new one: `git worktree add
../avra-<lane> -b <branch> main; make bootstrap`.

Tracker: `export TASKS_DB=/Users/tristan/projects/tristanMatthias/avra/.tasks/avra.db
TASKS_ACTOR="<NAME>"`. Claim before you start (`tasks claim <id>`);
create at the ROOT then `tasks update <id> --parent <epic>` (id-minting
bug avra-bzx2); close with receipts (commit, gate output). The db is the
channel: a report with no task is not filed.

Every slice, in this order, before it is done: `/red-team`,
`/review-round`, `/feedback`. The master checks the db for all three.

Rules: Opus for every subagent. ONE heavy process at a time, always
`sh tools/watch.sh 4000 <cmd>`; `cp build/avra build/avra.pre` before
any link; a compiler change reaches the product on the SECOND `make
avra`; a lexer/grammar change may need `make bootstrap` instead. Tests
are tests: spec files and program tests (`<name>/<name>.av` +
`.expected`) beside their owner; no corpus, no manifests under tests.
Commits and comments short and evergreen; no narrative docs (a
law/contract doc only). Never push or merge to main: one PR against
main per slice, ≤ 3k lines net of tests, and message the master the
PR number.

Beauty bar — the point of this relaunch. The idiom bar in CLAUDE.md
before every fn. Every table, registry, name-keyed dispatch and
hand-kept list becomes DATA the compiler reads — a derive, a comptime
`const`, a `table<Row>`, a `type(...)` literal — never a second
hand-written copy. Trailing blocks and the context receiver where they
remove noise. Every refusal is a named voice fn that states the law,
not the symptom. When the language lacks the form you want, file the
ask in the ROADMAP sugar backlog naming the site, and continue.

End of life: `/feedback`, file every want under `avra-8sb5.11`, tell
the master you are done.

## Sessions

### STD-SUBSTRATE — P0, start first
Worktree `../avra-lane-http`, branch lane/http, epics `avra-rhb2`
(substrate) and `avra-arzw` (net/http). Claim `avra-8sb5.1.10` and
`.1.7`.

You relaunch lane/http: 325 commits nobody re-implements. `cp
build/avra build/avra.pre`, then `git merge main`. Resolve ~230 paths
toward MAIN's shapes: seed.ll and the Makefile from main (regenerate the
seed with `make seed` once the build is green); tests moved beside
their features stay there; `corpus/` programs become program tests
beside their package; registries lane/http kept by hand (rt rows, width
rows, keeper tables, the http method/status tables) become data on the
way through. `make bootstrap`, `make avra` twice, gate. Then re-cut
`stack/1`, `stack/2`, `stack/3` from the merged branch so PRs #2, #3,
#4 update in place — split any cut over 3k lines. Trailing blocks on
the server loop and the reply builder. Then `.1.16` (reply framer
accepts chunked on HTTP/1.0) and `.1.17` (OWS skip recurses per octet).
Message the master when the merge gates and after each re-cut; message
STD-DATA when Bytes is on main.

### STD-DATA
Start in `../avra-lane-sq-ffi`, then `../avra-lane-sqlite`. Epic
`avra-bjkk`.

First the orphan: sq-ffi holds 105 uncommitted lines (a float literal
that does not fit — llvm.av, llvm_wrapper.c, corpus/float). Read the
diff, move the corpus test beside its feature, gate, commit, PR. Then
`git -C ../avra-lane-sqlite merge --ff-only main` and continue there.
`avra-8sb5.9.5` next, no dependency: `close(mut db)`/`finalize(mut s)`
rely on `mut b = a` aliasing and become a double free when S2 lands;
fix it now and agree the shape with LANGUAGE-CORE by message. Then
`.6.2`, the text/blob READ half, Option A as ruled on the task (the copy
exported, named unsafe, wrapped; negative length refused; (null,0) is
the empty box; an empty text/blob is an empty box, only SQL NULL is
null) — the empty case is the first test written. Then `.3.2`
read_bytes/write_bytes and `.3.6` [link] objects escaping a package
root, both once STD-SUBSTRATE says Bytes is on main. The column-type and
result-code tables become data. List every row that hands text to C and
diff it against the guarded ones (CLAUDE.md's NUL law).

### LANGUAGE-CORE
Worktree `../avra-lane-c`, branch lane/c, ff to main. Epic `avra-2y5c`.

The mutation model. `avra-8sb5.4.8` Cell<T> first (ruled: spec 11.5
wins, Cell<T> the only door, get/set not forwarding), then `.4.4` S2
(the cell ABI for receiver and parameter seats, the borrow deleted),
then `.4.5` H3 (a write through a borrowed local reports nothing — it
must speak). Before S2 lands, confirm by message that STD-DATA's
close/finalize fix is merged. Also `avra-qx1k` (a range-headed `for` as
a program's last statement traps `avra check`) and `avra-3cvq` (an
extern used as a value is F0900). One PR each. A grown IR vocabulary
pays the eight consumers; program tests prove eval == native; a
CLAUDE.md law is one paragraph.

### TOOLCHAIN
Worktree `../avra-lane-a`, branch lane/a, ff to main. Epic `avra-n1w7`.

What makes Avra usable outside this repo. `avra-2j4w`: @std/* resolves
from the compiler's install root, no manifest path for std.
`avra-3qg3`: the prelude — one implicit bottom package, layering a law
the compiler refuses to violate, tests print without reaching up.
`avra-x8gk`: `avra staged` stops being a subcommand. `avra-ihk9`: a Ptr
seat names which box (an RtSig column, so F2065 can speak). `.1.19`:
the gate's SUITES list derives from the manifests. `.1.21`: census
every hand-kept list in tools/ and the Makefile and convert each into
data — comptime where it is about the program, a keeper reading
manifests or `nm` where it is about the tree. One PR per item.

### LANE-D
Worktree `../avra-lane-d`, branch lane/d, ff to main. Epic
`avra-8sb5.5`.

Resume `avra-8sb5.8.3`, the CLAUDE.md law-wording audit, one section per
slice: each law names its mechanism and is probed once; a symptom-worded
law is reworded to the law. Then `.5.4` (three subset entries held for
Bytes and the grammar feature — probe once STD-SUBSTRATE's merge is on
main, delete what the compiler accepts) and `.5.7`. Run the duplicate
check after every prose splice: `grep -n "^- [A-Z]" CLAUDE.md | sed
's/^[0-9]*://' | sort | uniq -d` answers nothing. Docs-only PRs still
go through the master.

### SUGAR
New worktree `../avra-sugar`, branch sugar/3-5. Epic `avra-70jh`.

Sugars 3–5 in order: docs/2026_09_09_SUGAR_3 (typed runtime rows
`rt.name`), SUGAR_4 (emission as an expression), SUGAR_5 (named
arguments; retires the `else` block for a fn seat). Each: grammar +
typing, sweep the compiler's own passes to the new form, a ratchet rule
in DOGFOODING.md with its matcher, gate. A new DSL word takes the
four-generation build ladder and a seed refresh — ask the master to
seed. Then triage `avra-8sb5.10` and the survey wants under
`avra-8sb5.11`: dedupe, count wanting sites, file the top five as sugars
6–10 under your epic — tasks, not a doc.

### STD TASK MASTER
You do not write code. Tracker: `TASKS_ACTOR="STD MASTER"`, epic
`avra-ms0j`. Audit the db (not reports) each hour; chase unclaimed work;
file what sessions report; keep the owner's queue `avra-8sb5.8` to what
only the owner can decide and rule everything else on the task.
Integration: review each PR by SHAPE (a digest of recurring forms), gate
it yourself (`sh tools/watch.sh 4000 make gate` in a detached worktree
of the PR branch), merge bottom-up (substrate first), `make seed` on
main after a compiler change. Enforce: Opus for every subagent; one
heavy process at a time; the three skills per slice; tests are tests;
short commits and comments; no narrative docs; the survey at every
agent's end. Retire a worktree (`git worktree remove`) once its branch
is merged or contained; never touch another master's. Report to the
owner ADHD style: next action first, ≤ 5 items, state every turn.
