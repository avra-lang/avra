# `program/`: the clean-room design (DRAFT, in progress with the owner)

Everything lives in one package, `packages/std-program/`, engine and store included, so its tests compile only it: 6.3 s cold, 1.3 s warm, against 6.9 GB and minutes inside `std-avrac`. Its generic parts hold no Avra concepts.

## Agreed

### Layer 1: the face

    let p = Program.open(root, host)
    p.files()  p.parsed(f)  p.items(f)  p.names(m)  p.sig(d)
    p.typed(d)  p.lowered(u)  p.said(f)  p.linked(entry)

- Every call is a pure read. There are no write verbs.
- No cold, warm or held mode: a caller can't tell computed from restored.
- Passes receive what they need and return their result as the answer.

### The layers

| # | Part | Knows | Never knows |
|---|---|---|---|
| 1 | Face (`Program`) | the verbs | storage, memory ids |
| 2 | Facts: one pure function per verb | passes, identity | disk, caching |
| 3 | Identity: stable names | package-relative paths, names | memory positions |
| 4 | Engine: records reads, stops at unchanged answers, finds readers | keys, digests | Avra |
| 5 | Store: bytes on disk | records | what the bytes mean |
| — | World (host): file text, listings | the disk | everything above |

### Decisions

- The engine is designed fresh; `@std/relation` is a source to port from, not a dependency to assume.
- The bar is incredibly beautiful code: derived, using all the language's features, a law-abiding exemplar of `CLAUDE.md` and `DOGFOODING.md`. A want the language can't state goes to the sugar backlog at discovery.
- Identity as drafted is agreed. Name reads group by module with per-name digests inside. Each typed answer is its own small record. A new compiler starts cold for now.

## Draft, not agreed: layer 3, identity

Adopts `docs/2026_10_06_COMPILER_DB.md` A17, §6.3.

| Thing | Stable name |
|---|---|
| File | package + relative path |
| Module | package + dotted path |
| Declaration | file · owner path · name · sibling number (same-named siblings of one owner only) |
| Generated declaration | its source declaration + generator + name |
| Type | its spelling, naming declarations by stable name; never an interned id |
| Unit | declaration + type arguments |
| Syntax node | owner declaration + index within it |
| Source position | anchor declaration + offset |

- Keys are length-prefixed per component, so `("a.b","c")` differs from `("a","b.c")`.
- In memory a name is interned to a small integer that never reaches a key or saved bytes.
- A file's `items` holds each declaration's start offset. Moving a declaration changes only that.

## Agreed 2026-11-06: names point at content

The owner approved the full draft in this file as the design, and we build it one file at a time, walking through each together.

Two levels, like git refs and objects:

- **Address:** the stable name above. It's how people, diagnostics and the reverse index find things. Mutable.
- **Content:** a hash of a declaration's normalized syntax (no comments, no spans, local names numbered). Immutable. Facts are saved by content.

Saved answers are keyed by query + content hash, and each key may hold several traces (reads with digests); any trace whose reads stand answers it ("constructive traces", Build Systems à la Carte). So nothing is ever invalidated: a changed declaration just has a different key, and a revert, a branch switch, a move between files or another worktree finds its old answer.

Spans and comments live in a separate per-file table, applied only when rendering. Text files stay the input; the hash is the substrate (P11, P12).

## Draft, not agreed: laws the design must make impossible to break

From `docs/2026_10_06_COMPILER_DB.md` §2, `.lead/ONE_PATH_2026_10_31.md`, `.lead/HANDOVER.md`.

1. One input door. Facts read the outside only through the World.
2. A saved answer is its value plus (name, digest) of each DIRECT read; valid only if every digest stands. Reads are never flattened (measured +62% cold, +216% edited std-avrac).
3. A read with no durable name makes its reader unsavable; it is never dropped.
4. A query returns its rows and writes nothing else.
5. The bytes saved are the bytes digested.
6. Warm is never O(program).
7. Keys name files, never the program; no absolute path, machine, time or local id.
8. Refusals and incomplete answers (cycle member, budget stop) are never saved. Answers with diagnostics are.
9. A missing dependency is a mismatch, never "nothing to check". Empty is a value, distinct from absent.
10. A digest is taken of a complete answer, never mid-fill. With no shared tables there's nothing to fill.

## Draft, not agreed: the run (10-06 §6.2)

Map the store → digest inputs → moved inputs mark readers suspect → ask roots; non-suspects stand untouched → verify suspects root-down with early cutoff → append records and one commit marker. No daemon.

## Draft, not agreed: performance built in

| Technique | Evidence |
|---|---|
| Budgets are tests: answers computed per edit, reads per answer | p95 ≤600 reads, none >3000; counts, no stopwatch |
| Grain is the declaration, never the node | per-node recording 2.5× on repeats, 15× on first reads (measured) |
| One record per run's reads, grouped name reads under one digest | 15,807→3,420 reads on `Settled` (measured) |
| Verify without decoding: columnar meta and value regions; mmap | designed; mmap never yet used |
| Packed store, never one file per record | 1,300 opens 60–100 ms, 10,994 opens 490 ms (probed) |
| Whole packages trusted by one digest | `@std` confirmed by compiler id |
| Packed reads, ~9 bytes each | boxed 74 B, 375 MB in 5.3M (measured; packed estimated) |
| Reverse index built per run from saved reads, never remembered | remembered index under-approximated; per-computation 7.6–8.1 s→1.9–2.4 s (measured) |
| No read of a whole collection through `get` | whole-collection copies were the real cost |
| Don't save an answer whose reads can't verify in another process | 178 MB, 21,089 recomputes (measured) |
| Fewer reads before faster reads: mapping the value file only moved 1.4 s of `read` to ~0.9 s of `memmove` (measured, cause unproven) | L-reuse |
| Test with an edit corpus and count answers that stood | "run twice and compare" passes on an unchanged tree |

Floors: process 31 ms (grammar assembly 16, start 15, measured); inputs ~40 ms for 580 files (measured). Budgets: unchanged ≤60 ms, body edit ≤300 ms, build ≤500 ms.

## Already rejected, don't revisit

Daemon; stat-first on sources (owner rule); one file per record; flattened read sets; interface digest standing for a module; program-level standing verdict; eager minting of unread files; remembered reverse index; opt-in saving flags; `Db.insert` inside a query; codec migrations (recompute).

## Evidence from the last patching lane (L-reuse, `L-buckets-wip` 0420b1b3)

- First whole-program cause on a new fn: the `declares_alike` gate, then `names_settled` asks `items` and `expanded` of every open file. Read from code, not run.
- Sizes (grep upper bounds): 84 `Cell` fields on `Decls`, 77 in workspace.av, ~103 writes in decls and decls_mint, 630 `.index` reads, 39 `unheard`, 53 `_kept`, 14 whole-program walk sites.
- **The defect that matters: nothing tells a read missing a record from one that stands.** Four false stands in one batch, tests green throughout. New law: every answer has a record by construction, and a read of something with no record is a miss, never a pass.
- The earlier warm == cold byte-identical result covered one edit on one binary and doesn't prove the mechanism.
- Settle first: `declare` and `expand` mint rows mid-query. In the way: `FileId`/`DeclId`/`ExprId` as dense arena numbers through every feature; whole-program fixpoints.
- Keep the warm == cold and two-process attack suites first: they caught what reading didn't.

## Draft, not agreed: generated declarations

- `written(m)`: names from parsing alone. `generated(d)`: one annotated declaration's output, a saved answer.
- `names(m)` = `written(m)` + `generated(d)` of each annotated declaration in `m`.
- A generator's own code resolves against `written` names only, never against generated ones (Roslyn's rule). That breaks the cycle with no language change. To verify against the compiler's own derives.
- Most derives make `impl`s, so they add methods to a type, not names to a module.
- Swift-style declared names stay an optional later optimization: they'd let `names(m)` skip restoring `generated(d)`.

Measured re-entry into a file's expansion, cold `check` of cli and std-avrac: `core/nodes.av` 381 (196 read a half-finished list), `features/contract.av` 17 (1), 6 `delegates` test programs 7 (1). Doesn't count generators reading another file's generated names.

**The hard case, `collect enum Expr: Kids, …` (`expand.av` `delegated`).** `Expr` gathers `@expr_node` members across the package, and `delegate` expands each member's file first "so its crossing must see the member's impl". Those member files use `Expr`, so the enum and its members wait on each other. Draft resolution:

- `marked(mark, scope)`: a saved answer listing declarations wearing a mark, from `written` items alone. Membership needs no expansion; it moves only when a mark does.
- `generated(E)` reads `marked` and writes the dispatch. It doesn't look at members' impls.
- A member missing an impl is reported when the generated body is typed, as an ordinary error.

## Draft, assumes names point at content: layer 2, facts

| Query | Keyed by | Reads | Answers |
|---|---|---|---|
| `text(f)` | file address | World | bytes |
| `parsed(t)` | text hash, block-word hash | nothing else | per-declaration syntax (numbered within itself), each one's content hash, spans and comments table, parse diagnostics |
| `items(f)` | file address | `text`, `parsed` | address → content hash, start offset, marks, imports |
| `marked(mark, scope)` | mark, scope | `items` of the scope's files | who wears a mark |
| `generated(c)` | annotated declaration's content, generator's content | that declaration, generator's closure | new declarations, addressed by source + generator + name |
| `names(m)` | module address | `items`, `generated`, per module's files | name → address and signature hash, per-name digest, root digest |
| `sig(c)` | content hash | parts of `names`, other `sig`s | signature; signature hash |
| `typed(c)` | content hash | parts of `names`, `sig`s, `impls` parts, generic bodies it instantiates | relative types, diagnostics |
| `impls(type)` | type name, package | `items` | impls for that name |
| `settled(c)` | content hash | `typed`, what it runs | value, or why it can't settle |
| `lowered(c, args)` | content hash, type arguments | `typed`, `sig`s | one unit's IR, the units it asks for |
| `said(f)` | file address | `parsed`, names, `sig`, `typed` of that file; spans table | rendered facts for that file |
| `linked(entry)` | entry | walk of `lowered` | binary |

Recursive facts (writes, cancel bits, raised errors) are one query per declaration with one cycle handler: a cycle resolves as a unit, keyed by the hash of its members. An incomplete answer is never saved.

## Draft, assumes names point at content: layer 4, engine

Generic: no Avra concept. One annotation, `@query`; durability is inferred.

1. **Frame.** Each ask pushes a frame; every read is recorded, by construction, as (key, part?, digest). A read through anything else isn't possible: facts receive only the query context.
2. **Part reads.** An answer may be a keyed map. A reader records the part it read, including absent. The map carries a Merkle root, so two versions diff by changed keys in O(changes).
3. **Records.** Every answer has a record: key, digest, reads, value. No record means a miss, never a pass.
4. **Traces.** A key may hold several records. Any whose reads all stand answers it. An unchanged digest stops recomputation of readers (early cutoff).
5. **In-process answers.** An answer that can't be saved still keeps a digest-only record, so a reader can stand without it.
6. **Reverse index.** Built per run from saved reads as postings (name part → readers), held in compressed bitmaps. A checking mode re-verifies everything root-down and must agree.
7. **Order.** Digest inputs; moved inputs give suspects; ask roots; non-suspects stand; verify suspects root-down with early cutoff; append records and one commit marker.
8. **Budget tests.** Every run can report computes, reads and records touched. Tests assert those counts over an edit corpus.

## Built: layer 5, store (`disk_store.av`)

- **Packs only.** A directory of immutable packs. Publishing is one atomic rename, so there is no log, no commit marker, no torn frame and no lock.
- **Answers stream (2026-11-09, e6ca3edd).** Each answer is appended to a per-process draft (`@std/io` `Draft`: a temp named by pid and serial, published under a name chosen at the end) in 1 MiB writes, and read back through a mapping of the draft, remapped every 16 MiB. The process holds where answers lie, never their bytes. Publish appends the sorted index (`PackIndex`: answer spans and question records) and the seal; the pack is never built in memory. A failed write spoils the draft, so no index points at missing octets. Drafts of dead processes are swept when a store opens. Seal `avrapak3`.
- **Records are words (105c3aad).** A record's reads are flat words, 4 per whole read and 8 per part read, checked in place from the mapping with nothing decoded.
- **Absorption.** A new pack absorbs every pack holding no more entries (answers plus questions) than it has gathered, smallest first, so packs stay logarithmic. Two processes absorbing the same packs repeat work only.
- **Damage costs work.** A pack without its seal is ignored; one removed under a reader still answers from its mapping. Nothing is fsynced: it is a cache.
- **A process that learned nothing writes nothing.** The engine keeps only answers and records the store doesn't hold.
- **One question, one entry.** A pack holds a question once, beside its records, so reads never decode arguments.
- **Measured and left out.** Searching outward from where a hash word should fall: no gain over binary search on the benchmark (14.4 vs 14.3 ms). Re-measure on real tables, where most are larger and page faults count.
- **Working ahead.** With 16 or more unknown items, `worked_ahead.av` forks one process per core; each answers its share and publishes a pack, and the parent merges them. Packs needed no change for this. Dynamic claiming by file lock gave no gain over round-robin (1.35 vs 1.28 s), so it was removed. This machine has 4 fast and 4 slow cores, so about 3× is the ceiling.
- **Measured 2026-11-09, std-avrac (1,267 files), program layer.** Warm 77–90 ms, about 60 MB RSS. One body edit 279–285 ms. Cold about 17 s; heap peak 317 → 119 MB, RSS 430 → 259 MB (much of RSS is mapped file pages, shared). Cold self time: item_tape 8.6 s (lex 0.9, grammar and builders 6.7, tape write 0.9), file_scope 2.3, file_meant 1.4, file_words 1.4, item_needs 0.9, publish 0.5.
- **Merged 2026-11-09: track B (7bb3b1f4, 0172bab8, 84d08341).** A file's scope holds only its own: kept-apart names, imports, clashes, siblings' kept-apart names. `resolved` answers `Named`, `KeptApart` (a third file's read of a name two siblings keep private, never lent by the prelude) or `Unbound`, reading the module's winner and the prelude's export as parts of parted answers (`module_winners`, `module_declares`), so a reader of one name stands when another moves. Files are lexed once (`file_items`); an item's needs ride its tape's about. Red team: 25 cases, one wrong answer fixed (a missing file got its module's names).
- **Measured after B, std-avrac (1,268 files).** Cold 12.2–14.5 s, 34,234 answers; heap peak 94 MB (bytes 41, lists 53), RSS 210 MB. Warm 75–93 ms. One body edit 227 ms. file_scope 2.35 → 0.14 s (45 → 2.6 MB of answers).
- **Merged 2026-11-09: track B memory (c70ae14a, 2204478f).** Questions stream to the draft like answers; packs carry over as they lie; compaction marks in place; the engine's settled answer holds its query name, answer hash, deep flag and the in-place record it was reused through, nothing decoded. A spoiled draft (a failed write) is dropped, what it kept stays readable in memory, and only publishing is refused. Seal `avrapak5`. Measured: cold heap peak 94 → 40 MB (the peak is now mid-parse, in the parser); compaction heap 84 → 31 MB, 0.6 → 0.35 s. Warm 97 ms, one edit 248 ms.
- **Merged 2026-11-09: track C, the generated parser (12298b69..c671237e).** std-grammar generates a grammar's untold run as Avra source (generate.av, untold.av), one fn per rule branch: tokens by literal slot and class bit, captures as locals, a diagnostic carried as a count; a run that speaks falls to the engine's telling run, so every word and recovery is the engine's by construction. std-avrac carries Avra's (compiler/untold_parser.av, 41k generated lines, 307 rules), used only while its print matches the assembled grammar; `make parser` refuses a stale one. Proof: `avra parsers` compares every builder call, 2,467 files, 0 differing; 19,343 mutant runs, 0 differing. Grammar run 7.5 → 2.2 s.
- **2026-11-09, lead.** `once` fns keep their answer on every exit (ec14517c, one exit door). Items read under only the words they spell, answers read where they lie (dc4d8326). `fmt` judges a body's form from its own brace, so a wrapped head never changes it: a fixpoint again, lossless on every canonical file (9cbdcf08). A cold package is read across cores first: each core reads its share of files' words, nothing crossing files (d35fd604).
- **Final, std-avrac (1,273 files), program layer, binary loaded.** Cold **3.66 s** wall (8.7 s CPU across cores; 7.1 s on one core); cold heap peak 40–45 MB; warm **106 ms** (0.16 s wall); one body edit **237–271 ms**. Forked: 9 processes, none above 44 MB of heap. Fixed point: `make avra` twice, byte-identical. Whole tree on `program`: `avra tapes` 47 packages, 2,285 files, 0 differing; `avra parsers` (every builder call, generated vs engine) 2,464 files, 0 differing. Suites: std-program 269, std-grammar 53, std-avrac grammar/ 163, features/fns 830, lower 67, item tests 17+4+9+25+3, one_line 27.
- **Signatures (fed3be6b).** `fn_signature(file, name)` resolves every type a fn writes: its own type parameter, a type the language owns, or the declaration the file's top level names (by file and name). Aliases expand (`alias_target`), unions take one order, a C width rides the seat, `_` is marked for typing. `avra tapes --signatures`: all 47 packages, 0 differing. Next: typing on the engine.
- **Cold, by query (one core, before the fork):** item_tape 4.3 s (lex, grammar and builders, tape), file_items 1.1 s (lexing each file whole), file_words 0.4, source_text 0.25, the rest under 0.2 each. Next by size: builders and tape writing (~2 s, wants the parser to write the tape directly), the second lex (an item re-lexes what its file's lex already read), and the lexer itself (430 ns/token, Token records rather than columns).
- **Engine (85c4c29d): deep records cost the graph once.** A root's deep record gathered its inputs by walking everything beneath it, per root: a tool asking thousands of roots walked the graph thousands of times. Each question's inputs are now a bit set over the process's input places, worked out once and shared by every root above it. std-avrac's receipt: over 240 s to 64 s.
- **Compaction (d25d661c).** Marks from each root's newest two code versions (by query and arguments) through each question's newest three records, always including its newest shallow one, to the questions and answers they read; copies only those. Triggered when the store holds more than 2× what its last compaction kept plus 64 MiB, so it stays within about 2× live. Unreadable packs count against the room and go at compaction; one other binary's pack fits under the doubling rule. Measured: 0.9 s on std-avrac, 300 MB RSS peak (it decodes every question); marking in place is the follow-up.
- **Decided 2026-11-09 (owner delegated it to the lead): the ceiling is relative, per store.** Compaction when a store passes 2× what its last compaction kept plus 64 MiB, so it holds about 2× its live data (std-avrac: ~70 MB live, under ~200 MB on disk), keeping each root's newest 2 code versions (two binaries sharing a store each keep theirs; a third repeats work, never wrong) and each question's newest 3 records (about two edits back stays instant). Why not one absolute machine-wide budget: it needs a number nobody can choose well and cross-store eviction, and it bounds only what the relative rule already bounds per store. Revisit only if the sum across worktrees becomes the problem, measured.
- **Not built.** Per-file clustering; string pool, perfect hash and xor filter, each pending a measurement. (Marking in place was built with track B's memory work: compaction heap 84 → 31 MB, 0.6 → 0.35 s.)

## Open

- From the tracks B and C red team, open:
  - **Deep nesting crashes.** 6,000 nested parentheses segfault `check` in a pass both parsers share, and `avra parsers` at 2,000. A runaway compiler recursion wants a trap with words, as a program's does at 100,000 calls.
  - **Grammar text parser.** std-grammar's `parse_grammar_text` drops lex errors silently, and an empty alternative gets "unexpected input after `grammar`".
  - **Receipt gaps.** `tapes` compares no clash lists, and doesn't save its store, so a rerun checks no reuse across processes.
  - **Mutants.** `--mutants` picks 8 places by arithmetic, and wants `all`.
  - **A harness to keep.** The degenerate-grammar harness should become a std-grammar fixture.
  - **Old workspace.** A `src` directory named `weird.av` traps it, which predates both tracks.
  - **Warnings.** Two `type.alias_copy` warnings stand in `pack_collection.av` and `frontier.av`.

- Findings from the format batch, to pay:
  - `avra fmt --write` is not idempotent: an over-long one-line fn body holding a `+` chain wraps inside its braces on the first pass and reflows to a block on the second, so a file formatted once fails `--check` (repro `/tmp/fbprobe/fmtrepro/a.av`).
  - The test door to a module's private names doesn't resolve: `use frontier.{FrontierDelta}` from std-program's `src/tests/` is refused as "does not export", against CLAUDE.md's law. Narrow exports stand in for it.
  - Roots never expire: a root asked once (a deleted file's listing) stays, and its input is asked every run.
  - Records checked grow by ~5 an edit, since each edit adds a record and the oldest are tried first. This predates the frontier, and compaction caps it at three.

- Review round over slice 1 and the frontier (5236f5fe): one splice door, one generic root index (a meaning that can't narrow its root was never tried), a shared table search and sealed read, and `SettledAnswer`'s source as one enum. Its proposals, as decided:
  - **One format batch, one seal bump** (next): delete the dead `deep` fields; a `FrontierState` enum in place of three cells (and a `List` used as an optional); `frontier_seeds` stops deleting from inside an argument list; structural validation at open; the change-only frontier write as a delta chain.
  - **Next rung of the meaning engine:** a typed `Node.Held(arena, index)` in `@std/meta` in place of the `Many([Name(arena), Int(i)])` encoding, which can't tell an empty run of names from an empty run of nodes.
  - **Logged:** the two `meanings_adversarial` README receipts become a keeper that runs them; the third post-order walk becomes `SyntaxArena.every_at`; statement meanings get a note sentence once a refusal is first spoken inside one.
  - std-avrac's rewrite_test, subset refusals and rules_table tests were checked by hand; they owe a CI run (their test binary passes the 6 GB local cap).

- Typing rule for the switch (the lead's call, recorded): a branching form whose value is dropped is `void` whatever its branches answer, `match` as `if` already is. The new typer types a dropped `if` so and a dropped `match` by its arms, so `meaning if_else` changes a dropped two-branch `if` with value branches (`if c { g(1) } else { g(2) }` as a statement) from `void` to the arms' type, and with disagreeing branches to nothing. No such shape stands in the tree (receipts 0 differing). Giving `match` the rule now costs typing parity one node: the old typer types cli's dropped `match` in `relayed` as `{}`. So it lands with the switch, when the old typer stops being the reference.
- Cache files deliberately garbled but sealed trap the process that opens them (a frontier's or a pack's index read out of bounds), which the red team showed: every process traps until the file is removed. Decided: validate a file's structure when it opens (its index tables' lengths and offsets within the file, and a frontier's read places within its entries), never a whole-file hash (warm would pay a pass over every pack). A file that fails reads as foreign, and compaction removes it. Next after the change-only frontier write.



- Defect, found by the first full std-avrac suite on a runner (run 42757152485, 14 GB ceiling: the suite's test binary peaks at 9.0 GB): 226 rule examples proved, the program proofs ran, and `features/collects/tests/closure_entry_b` evaluated to `[]` instead of `[knob]`. That test guards a batch: two programs sharing one store, one declaring a `@seat` in its entry file, must each read their own closure collect. Reproduced in miniature (a scratch package holding `closure_entry_a`, `closure_entry_b` and `closure_support` as nested tests, run by one `avra test`): `program`'s compiler fails it, **main's passes it** (main bootstrapped from main's seed). Each program alone passes. Not this session's typing or engine work (the old evaluation path uses neither); most likely the inherited 11-04/05 base-lane commits that made per-program answers lasting across a batch (`302c7eec` "the program's closure that fed them", `d263370e` Names lasting, `908d9341` a unit's lowering lasting). Diagnosed (no bisect possible: the lanes' trees each needed their day's compiler, none kept): the order matters one way — `b` after `a` reads `[]`, `b` first and both pass. `AVRA_QTRACE` shows `b` taking 149 lowered units straight from the store: `lowered_unit_of` is a lasting answer keyed by its want (d0e27583), and a unit's reads are its syntax plus what it asks. A `closure` collect's members (`gathered_by_mark`/`gathered_into`, features/decls.av) depend on the program being built but are no recorded read, so `owners()`'s unit, with the collect baked empty by `a`, stands for `b`. A silent wrong-output defect for any two programs sharing a cache. Fix, and why a recorded read is not one: the unit's key carries no program, so any read `a` recorded keeps verifying in `b`'s process (`a`'s closure didn't move). A closure collect's members belong to the final program, as a linker's registration table does (C++ static registration, Rust's `inventory`). So the library's unit must not bake them: lower a closure collect's members as a static unit keyed by the program being built, referenced from the library's unit by symbol. Library units stay shared across programs; only the program's own small unit holds the table. The program layer's lowering takes the same shape from the start. **Fixed in the old compiler (65c7e283):** a closure-scoped collect's own unit is `unkept` (as a unit with voices already is), so it's lowered for each program and never served to another; every other unit stays shared. Witnessed by the miniature batch in both orders, eval == native == expected (a then b failed before). The full suite is rerunning on the runner to confirm.


- Defect, `@std/meta` (old compiler): the collect-enum delegate (`delegated_arm`, std-meta/src/meta.av) decides a member has an impl from `implemented_by` (compiler/expand.av), which looks impls up by their WRITTEN target name. So `impl PatChecks for FormatPat`, where `FormatPat` is an import alias, reads as "no impl", and the member's arm calls the enum's own method: infinite recursion, a segfault at run time. The law (`collect_enum.trait`) resolves the alias and passes it. Two spellings of one question that disagree. Avoided by naming members by their own names; the new layer's impl index files by resolved declaration. The old one wants `implemented_by` and the law to share one answer.

- Language finding: `|` binds tighter than `<<` in Avra (the formatter printed `w | 1 << n` as `(w | 1) << n`), the reverse of C, Rust, Go and Java. A bit-set written the familiar way compiled clean and was wrong until a test caught it. Decide whether the precedence table should follow the family every reader knows, or whether mixing them should demand parentheses.

- The whole std-avrac suite (`compiler/tests` alone is about 1,782 tests, 6–7 GB, 15 min) does not run on the Mac; it runs on a GitHub runner through `tools/work run` (the owner's 2026-11-02 route for heavy runs). Getting there took three fixes, all in 83fcb822: the seed refreshed on `program` (no published compiler reads its front end), committed gzipped (the IR passed the host's 100 MB file limit), and `make compiler` linking a seed emitted from this very tree before climbing any ladder. `decl_grain_test` failed before this push (it tests the old Workspace). Each later change to compiler source on `program` needs `make seed` again before a runner run, until `program` lands and main's compilers read it.

- Machine safety: BUILT (0d5a5083). Past a 256 MB allowance every Avra process reserves its memory from a machine-wide pool (60% of RAM, 256 MB slots, an flock per slot the kernel drops on exit); a run holding nothing waits, one holding slots waits 120 s then refuses in its own words; `make pool-check` holds it with real processes. Agents can run in parallel again under it.

- Idiom debt on `program`: 38 new sites in std-avrac, 23 in cli, none in a file this push touched (all from the base lane's unlanded work: workspace.av, derive.av, record.av, cache_walk.av and others). Paying or baselining them belongs to that lane's landing.

- Layer 2: each fact's inputs and answer. Per-name versus per-module name reads (7.6M of 8.3M reads are per-name).
- Granularity: one row per answer versus typed answers filed with their parent (a 7.9 GB OOM).
- Staleness stamp: compiler print, per-query code hash, or `store_wire`.
- A derived codec on `TypeFacts` once ran out of memory building; later codecs didn't. Probe it.
- Engine location: all in `program/` now; 10-06 D11 wants it shared with running programs via `@std/relation`.
- Layer 4: the engine's rules. Layer 5: the storage format. Porting.
- Sources: `.lead/ONE_PATH_2026_10_31.md`, `docs/2026_10_27_ONE_STORE.md`, `docs/2026_10_30_HARVEST.md` part B for unlanded commits worth porting.

## Draft, not agreed: the best known technique per part

Each is a candidate until measured against the plain version in Avra. A technique stays only if it wins on the budget tests.

| Part | Technique | Replaces |
|---|---|---|
| Saved values | In-place layout (Cap'n Proto, FlatBuffers, rkyv family): fixed section, relative offsets, one canonical byte form, readable from the mapped file with no copy and no decode | LEB128 read in sequence, which must pass every earlier field to reach one |
| Lists of numbers | Each list states its element width, the smallest that fits (1, 2, 4 or 8 bytes): O(1) indexing and compact | Per-number varints |
| Records | Two bits of size per field, so one large field widens nothing else; reaching a field adds the sizes before it. Built: `program/saved_layout.av` | One width per node |
| Mapped reads | A view over the mapping that loads words in place, with no box | `avra_mmap_slice`, which answers a new string per read |
| Writing | One native growable buffer | A `List<int>` of boxed octets |
| Text | One string pool per sealed pack; a text is an offset | Repeated copies of the same names |
| Read lists | Sorted, delta-coded, compressed in blocks (StreamVByte family) | 9-byte packed reads |
| Reverse index | Compressed bitmaps per name (Roaring) | Walking records |
| Key lookup in a sealed pack | A static perfect hash built at seal (PTHash family), then one load | Fan-out and binary search |
| "Is this key absent?" | A xor filter per pack | Probing each pack and segment |
| Name maps | A hash trie with hashes at each node (Merkle HAMT): diff in O(changes), shares structure between versions | Rebuilt per-name tables |
| Multiset digests | Sum of finalized row hashes: O(1) incremental | Rehashing whole lists |
| Store shape | Tiered merge of sealed packs, per-file clustering (LSM family) | Rewrite at compaction |
| Execution | Pure queries on a work-stealing pool | One thread for 60 s cold |
| Memory | A bump region per query, freed whole; answers copied out | 2.1 billion retains per check (language/runtime change; investigate) |

## Draft, not agreed: the syntax layer, from first principles

Measured 2026-11-06 on the real tree (403 files, 126k lines, 5.3 MB, 868,635 tokens), one core: lexing 415 ms, lexing plus parsing 3.88 s, so lexing is about 11%. Splitting into items, a rough line-based count: about 11,000 items, median 6 lines, p99 112. Editing a random line reparses about 1,073 lines per file today and about 150 per item. Probed: `fn f() { 1 }` is refused as "the body answers `int` but `f` declares `void`", so a body can't change a signature.

**What consumers need, most frequent first.** Did it change? What does it declare? What is its signature? Its body, only when retyping. Positions and comments, only when speaking or formatting. Each gets the cheapest form that answers it.

**Assumptions dropped.**

| Assumption | Replaced by |
|---|---|
| Detecting a change needs a tree | A hash of the item's exact bytes needs no parse. Early cutoff happens one stage later, on the tape's hash, which can't forget a field |
| A file is the unit of parsing | An item: a top-level declaration, or one member of an `impl` or `trait` |
| Everything is parsed before anything is asked | Bodies parse when first asked; bracket matching skips them in O(1) |
| Comments and positions need their own tables | Tokens hold offsets, and a comment is the gap between two tokens |
| Nodes are objects | A flat tape of columns, in memory and on disk alike |
| Trees must be saved | Text is already lossless. Saving a tape is one flag on one query, set by measurement |

**The layers.**

1. **Lexed file.** Columns: token kind (1 byte), start offset, and each opening bracket's partner. Keyed by text hash and block-word hash. Block words are an input here, which also fixes the 56 files that parse with errors.
2. **Items.** For each item, hashes of its exact bytes, split at the body's bracket: `signature`, `body`, and `docs` from the gap above it. An unchanged hash means no parse. Comments between items belong to no item, so editing them costs nothing. The split and the deferred block are generic grammar marks, with no language concept in them.
3. **Tape.** A query from an item's tokens and the grammar's print. Post-order columns: kind, subtree size, payload. Walking a node's children backwards is size arithmetic. Schema per kind is derived from the closed node enums. Positions are token numbers in a section nobody opens unless speaking. Names are numbers into the item's own table, each with its 64-bit hash, so comparing names compares words.
4. **Nodes.** The tape hydrates into today's `Expr` and `Stmt` only on a miss. Passes move to direct views as they are ported.

**Two hashes, two jobs.** Bytes say whether to parse. The tape's hash, without positions, says whether anything downstream must rerun: a comment or reindent inside a body reparses that one item, its tape is unchanged, and everything after it stands. A sublanguage's body is held in the tape as its exact bytes, so whitespace-sensitive sublanguages are correct by construction, and needing no rule about them. Generated declarations take the same tape hash.

**Taken out by this.** Fingerprint walks and the bug class recorded under "a hash that forgets a payload". They stay only as a test witness until item parsing is proven.

**Measured or estimated against, and left out.**

| Technique | Why not now |
|---|---|
| Sharing identical subtrees (hash-consing) | Hashing every node costs; only about 3.6% of whole items repeat, and those already share by content address. Subtree rate unmeasured |
| Hashing with local names erased (de Bruijn) | Diagnostics need the names, and pure renames are rare. Unmeasured |
| Succinct trees (LOUDS, balanced parentheses) | A size column is already about a byte per node and needs no rank or select |
| Compressing saved trees | Breaks reading in place; the text is already 5.3 MB |
| Reparsing inside an item (red-green trees) | p99 is 112 lines. Only a few outliers such as `rt_sigs` (2,900 lines) would gain |

**Costs and risks.**

- A comment edit inside a body costs one item's parse, estimated at under 5 ms on today's parser. A repo-wide reformat parses everything once, then cuts off.
- The token split is only a speedup. Unbalanced brackets, or an item that fails to parse, send that file to a whole-file parse under its real words, so a sublanguage's text never has to balance; it only runs slower when it doesn't.
- A sublanguage whose brackets balance but mislead the split could divide an item wrongly without an error. Compare split and whole-file parses on every file; the case hasn't been seen.
- Parsing a member alone must give the tree the whole-file parse gives. Compare every item on the real tree.
- A derive that reads a doc comment must record a read of the `docs` part.
- This doesn't touch the 90 ms warm floor. An edit's parsing falls from about 33 ms to about 8 ms including the lex, out of about 70 ms above that floor.

**Found while connecting the real lexer.**

- All 403 files balance with no block words, so splitting needs none. Hashing does: a raw body's line comments belong to the generated program, and lexing without words would drop them from the hash, which is a wrong answer.
- Block words depend on a file's `use` lines and on other modules' exports (`words_under`), so they are a read of other modules' answers, not a fact of the text.
- The old compiler already hashes tokens per file (`shape_digest` in `compiler/token_place.av`). It also folds in `// LICENSED` claims, doc positions, and for some readers every token's line. So some comments are content to some reader, and line numbers are read by answers that print a place (a task's `file:line`). Those need parts of their own.
- `parse_program` parses twice when a file has errors, so the 3.88 s above is inflated by the files that parse with errors under no block words. Re-measure once they parse.
- Handing tokens over and building columns cost 35 + 21 ms against 443 ms of lexing.

**Items checked against the real parse.** `source_items.av` splits all 403 files in 2 ms into 8,695 items and 5,174 members. On the 347 files that parse without errors under no block words: same count and every statement inside its item in all 347 (8,262 statements), and every one of 492 `impl`s has the same member count. The other 56 can't be compared until block words exist. An item starts at `export`, where a statement's span starts after it.

**Hashes checked on the real tree.** `item_hashes.av` hashes 13,869 items and members in 12 ms. Editing the first body of each of the 391 files with one moved exactly that one body hash in all 391, and adding a comment above it moved exactly one `above` hash in all 391. One simulated edit per file. Bodies are 51% of the bytes (2.7 of 5.3 MB, 10,408 bodies), which caps what lazy bodies can skip.

**Item facts on the real tree, no parsing yet.** `source_facts.av` is rewritten over items and `declarations_in` is gone. Cold on all cores 470 ms, one core about 1,000 ms. Unchanged 58 ms. First edit of `llvm.av` 132 to 143 ms; repeating or undoing it 58 to 63 ms. These aren't comparable with the earlier parsed numbers. The first run after a build takes about 1,770 ms, from the binary being read for the first time; it isn't lingering processes.

**Deep records.** A root's answer is also kept as a record reading only inputs (a deep constructive trace, from Build Systems a la Carte). They're checked first, and an unchanged program then settles 405 questions instead of 15,886: asked falls from 66 to 19 ms. No new machinery: it's a record, and its check is the ordinary one. It rests on a root's code hash covering everything it calls. Each state adds about 20 KB, and warm grew from 58 to 63 ms over 8 states, so it needs the disk limit.

**Where warm's 58 ms goes.** About 36 ms is starting the process: a tiny binary starts in 2.2 ms and this one, which links the compiler and LLVM, in 36.5. About 19 ms is asking, of which 11 is reading files and 3 hashing. So the next warm gain is a small process that doesn't map LLVM until it must.

**What's in the store, 12.3 MB.** An input's bytes aren't kept now, which took 5.3 MB out. By query, in octets: per-item stand-in 5.0 M (3.1 M of it questions), `written_items` 3.1 M, `read_file` 1.7 M, questions overall 3.5 M. Each question repeats its query's name and code hash and its file's address; a pack's string pool would take most of that out. `read_file`'s bytes are never read back unless it reran, so they could be held like an input's.

**Parsing by item, proven on the real tree.** Each item parsed alone, with the text above it, against the whole-file parse, by fingerprint: 8,262 of 8,262 statements and 5,067 of 5,067 `impl` members on the 347 clean files. The 56 files with errors give 124 errors either way; only the count is compared, and they still lack block words. Whole-file 3.89 s, item by item 4.07 s, since each item is lexed again. Items here are parsed through `parse_source`, with no change to the parser. A `///` above an item moves today's fingerprint, so docs must be kept out of the tape's hash for a doc edit to cut off. Trait members weren't compared, since their rule isn't `stmt`.

**Tape format built.** `syntax_tape.av`: post-order columns of kinds, subtree sizes and word ends, a run of words per node, a text table with each text once, and offsets and widths apart from the meaning. The hash covers the meaning alone and is computed once and saved. Read in place through `TapeView`. Tested with a small tree; no language writes one yet. No per-name 64-bit hash yet: added when name resolution first compares names. Owner's choice 2026-11-06: straight to the tape, no stand-in query first.

**Field survey, by a source scan, not by the compiler.** 103 nodes: 63 `Expr`, 29 `Stmt`, 11 `Pat`, none with more than 6 fields. Direct fields: 66 child, 46 text, 33 list of child, 11 list of text, 10 list of `Param`, 10 optional child, 9 `TypeRef`, 7 list of `TypeRef`, 4 optional `TypeRef`, 4 bool, 3 optional text, 2 int, and one or two each of 9 more record and enum types. 22 helper types are reached, and no field is a map, a fn or a pointer. Every shape has a form already (`saved_form`). The harder part is what isn't on a node: the arena holds 26 columns, of which about 20 are side tables a parse fills (marks, annotations, docs, pattern reads, sugar links, extensions). The existing `@copied` marks and `copied_derive` already say which ride with a node, and `@derive(Identity)` over `collect enum` already walks every field, so the tape writer follows those two instead of adding a new way.

**Tape design, owner's direction 2026-11-06: no sacred cows, no limit on what a node may hold.**

- **Any value.** `saved_form` grows a form for every kind that has bytes: floats, maps, results. A value that has none, like a closure or a pointer, is still allowed: parsing is pure and a tape is only a cache, so that item isn't saved. It's parsed again in each process, and its cutoff falls back to its bytes. Slower, never wrong, and nothing is prevented. Named fns can be saved by name if one ever appears.
- **Side tables stop being special on the tape.** A column is a fact about nodes, so the tape holds columns generally: a sparse column is sorted node numbers beside values. Measured over the real tree (250,778 exprs, 51,543 stmts, 18,866 patterns, parsed with no block words): annotations 0.7% full, docs 15%, `minted_by` 0.8%, `meaning` 0.3%, `pat_reads` 20%, and `grammars`, `component_insts`, `collect_dense`, `sugar_matches`, `extensions` empty there. An empty column costs nothing. A rank bitmap or Elias-Fano isn't worth it: items are small, so a search covers a handful of entries.
- **Built:** three sections. A meaning fact moves the meaning's hash, an above fact moves only `above_hash`, and a place fact moves neither. Each section has its own text table, so a doc's text can't move the meaning. One byte form however facts are written, and two facts about one node in one column stop the program.
- **Built: the node writer, for any language.** `taped_fields.av` in `std-program` generates a node's writing from its declaration, as `folding` does for `Identity`; a language's trait wraps it in an impl naming its own tree. Fields holding nodes become children and plain fields become words. A kind is its name, a number into the meaning's own text table, so no language numbers its nodes, kinds take one byte, and a tape reads with no language at hand. A field with no bytes leaves a place and clears `holds_only_bytes`. An enum variant is a node of its own for now; a fieldless enum as one word is the size saving to measure first. Proved on a tiny tree with every shape, and by mutation (a dropped list length fails two tests).
- **Measured: real nodes on tapes, before any trimming.** `Taped` in `std-avrac` over `Expr`, `Stmt`, `Pat` and 23 helper types; names over plain values are words, read through `type_named`. The compiler's own 5.3 MB of source, 8,695 items: 859,440 nodes, 667,755 words, none without bytes. Tapes 12.5 MB, meaning 7.7 MB. Parse 3.7 s, tape 0.27 s, save 0.24 s. By width-times-length: offsets 1.8 MB, widths 1.6, text 1.6, sizes 1.25, word ends 1.2, kinds 1.1, words 0.85; about 3 MB is per-item framing. Only 310,660 nodes have a place; lists are 34% of nodes, absences 16%. A fieldless enum is 1.3% of nodes, so one-word enums aren't worth doing. `SeatMark` is 24,727 nodes and 124k words (19% of words), so a record of only bools wants one word. Kinds aren't always one byte: they number into the whole text table, so a big item widens them. Facets aren't on the tape yet.
- **Trim 1: places.** A bit per node says which are placed, eight to a number, with a count of placed nodes before each run of 512, so a node's place is a few reads. Offsets and widths are kept for placed nodes only and count from the item's first byte, so an item that moves keeps its whole tape. Places 3.4 MB → 1.3 MB; tapes 12.5 → 10.0 MB, biggest 279 → 198 KB; meaning unchanged. A zero-width place is a place (its own bit, never width 0 as a sign).
- **Proposed: the schema tape (measured in a Python model of the same 8,695 items).** The tree is typed, so a node's shape is known from its type: which fields hold nodes, which hold words, which are lists. A tape then needs only what the type can't say: a variant where the type is an enum, absent-or-not where it's optional, a length where it's a list, and the words. Pre-order, varints, three streams per item: structure, texts (kind names gone, since kinds live in the schema), places (bits plus delta offsets). No sizes, no word ends, no per-list framing.
  - Sizes: now 10.0 MB → schema stream 3.4 MB (structure 1.5, texts 1.1, places 0.8) → with zstd and a dictionary trained on the store, per item, 1.5 MB. Whole-file zstd 1.13 MB. The entropy floor of the structure is about 0.4 MB (tags 0.15, words 0.24), so a context coder of our own could reach about 1.2 MB in all.
  - The schema is derived by the same generator that writes the tape, saved once by its hash; `@derive(Taped)` also writes the reader, so decoding is one generated linear pass with no schema lookups.
  - Cost: a tape is no longer read in place at a random node. Read-back is a sequential rebuild anyway; partial reads (a signature without its body) are their own saved answers.
  - Found: kinds named by bare name collide. `Variant` is both a node and a helper type, so one kind has two shapes. The schema names kinds by their whole path.
  - Step 2 owes one reading of a field's type. `saved_derive.av` (`has_bytes`, `saved_form`) and `taped_fields.av` (`is_words`, `words_written`, `children_written`) each classify `Kind` by hand, the same way, and the schema would be the third copy. So step 2 is `Kind` → `FieldSchema` once, and the tape's writer, its reader and its schema all read that. Still to decide there: floats and bools as numbers, `Bytes` as a list of numbers, `Cell` read through, and a map and a result in `Holds`. An optional node whose type has a choice folds absence into the variant number (absent is 0), saving a number.
- **Step 2 built: the schema, by root.** `field_shapes.av` is the one reading of a field's type (`TapeTypes.shape_of`); a language hands it its declarations, which fields it writes, and which id stands for which ROOT. `@derive(TapeRoot)` on `Expr`, `Stmt`, `Pat` works out each root's own schema and the helper types only it reaches, while the compiler builds, and emits it as the code that constructs it; at run time `avra_tape_schema()` gathers the roots through each other: 27 types, 153 variants, 298 fields, 244–323 µs, 13 KB saved. Measured on the way: one whole-tree walk inside a derive cost about 75 s and 1 GB of the compile-time evaluator, and saving bytes inside a derive alone broke its 5 MB budget, so work while building stays per root and never saves. A fresh-store `check packages/std-avrac` is about 129 s with or without the roots (the 53 s figure was a warm store).
- **One reading, built (11-07).** `value_shapes.av`'s `Reading.shape_of` answers one `ValueShape` (plain, option, list, cell, name over a shape, map entries, result sides, declared, id), and `@derive(Saved)`, the tape writer and the schema all fold over it; `field_shapes`, `taped_fields` and `named_shapes` are gone. A language plugs in only its declarations and a `FieldRole` per field (written, carried, or apart, as Avra's `@facet` is). Ids say what they name, `@indexes(Expr)` on `ExprId`, so no id table exists. `Kind.Bytes` is a real kind (it was `Unspelled("Bytes")`, matched by string in 13 places). Saved answers keep their own layout on purpose: the disk store binary-searches them in place, which a sequential tape can't do; the two layouts are projections of the one reading. Landing needs a ladder: the committed seed spells Bytes the old way, so the first rung carries a two-spelling bridge.
- **Step 3 built: the writer.** A tape is three octet runs, parents first: structure (variant only when a type has more than one; a variant's bools and optional presences as flags, 63 to a number; then fields; lengths before lists; varints, zigzag for ints, floats as 8 octets), texts (each once, numbered by first use) and places (per id node, width+1 then a zigzag delta of the offset, 0 for none; nodes standing for ids are numbered in that order, and facts go by those numbers). A root's derive writes its own dispatch (`taped_node`), since a collect enum's members can't know their variant number.
- **No column can be forgotten.** A derive over `SyntaxArena` requires every column to say what it is: meaning (hashed), place (not hashed), above (docs and comments), or derived (rebuilt, like fingerprints). A new column that says nothing is a compile error, the same law as `@derive(Saved)`.
- **One proof.** Read back into a fresh arena and compare every column with a direct parse, on every item.
- **Step 4 built: the reader, and load measured (11-07).** `@derive(Taped)` writes each node's reader beside its writer from one layout per variant; a language names only its tree, its reading and three tree verbs (`TapeLanguage`), and a root writes its own id's writer and reader. A field the tape doesn't hold reads back as its default or fresh from the tree (`@made_by`), else the derive refuses it. Avra's statements round-trip through a fresh arena, meaning and places equal. Measured on the compiled suite, `decls.av` (167 KB, 119 items): parse 104 ms, load from saved bytes 5.2 ms (decode 0.2, node building 5.0), so about 20x; saved 82 KB, half the source. What's left of a load is building nodes (allocation, arena side tables, identity hashing), the same work a parse pays. **Save flag: yes**, by this measurement.
- **Before a cache can load: facts.** Hydrated nodes miss their side tables (marks, grammars, annotations, docs, pattern reads, sugar links...), so loading today would hand the compiler a different program. The arena already declares which columns ride with a node (`@copied(stmt|expr, verb)`, `@copied_by_hand`, `@not_copied`), and `copied_derive` reads those marks, so the tape's facts are derived from the same marks: each copied column's value per node, read through `Reading` like a field, kept sparse.
- **Facts built (11-07, `3d72cdcd`).** A tape is a copy whose source is a tape: `@copied` tables go on it from the same marks (`copied_derive`), a third word projects what's minted again, `@not_taped` leaves a node unsaved, the by-hand columns follow the copier's walk, and a sugar's meaning is minted again (`settled_since`). One `@placed(from, to)` shape puts spans and seat ids among the places. Every statement of std-avrac and the cli round-trips, 9,497 of 9,498 with equal fingerprints; the last is a parse defect (avra-4dfy). Found on the way: a fingerprint is a chain of stamps, so order matters, and rebuild copies stamp in another order than a parse (avra-dfbt).
- **The cache built (11-07, `b2278786`).** `item_tape(item_text)` is a saved query keyed by an item's bytes; `file_tapes(file)` answers each item's start and tape. Avra: `compiler/item_tapes.av`. On disk, over 445 files: parse 4.2 s; a later process 50 ms of answers and 225 ms of trees, 357 files from tapes and none differing from a parse. The other 88 hold component instances, which want their file's block words: **next, an item's tape keyed by its bytes and its file's block words.** A file's header and comments stay with the file's own read.
- **Where it's going.** Every read goes through one door, `store.expr(id)`. Once the tape is the truth, that door can build a record on first read, so an unread body never becomes objects. Whole-item read-back comes first, and the lazy door is decided by measuring it.

## Agreed 2026-11-08: the whole parse on the tape

Owner: everything goes on the tape, nothing stays with the old compiler, no half way. Best structures, no sacred cows.

**The law.** An item's tape is everything its parse made. Reading it back needs the tape alone: no grammar, no words, no other file, nothing minted again. Every arena table declares its tape route, and a table that declares none is a compile error.

**What that takes, each part from first principles.**

1. **Shared nodes.** A sugar's meaning holds the very nodes its sugar was written with (a hole is filled with the written node), so a parse is a DAG, and a tape of a DAG names a node it holds already instead of writing it twice. A root's node leads with its variant, so a number past the last variant is free to mean "the node that many back": a node written once costs nothing more, and one written again costs one number, usually one octet. The writer finds a node's number in a dense window (an array offset by the lowest index met; one item's ids are a narrow band, so O(1), no hashing); the reader keeps number → index, reserved when the place is read and filled when the node is made. A root is read only through its id, so it has no other reader. **Built.**
2. **Every table routes by what it is.** A table is one of: what was written (on the tape), what the language made of it (on the tape, since the key covers the language and the words), a number folded from those (remade while reading: fingerprints), or what the parse was handed (on the tape as data, so reading needs nothing else). Each table says which with one mark, and a table that says none is a compile error; nothing is "not taped". `@copied` stays the template copier's word only.
3. **Meanings ride the tape.** `meaning`, `minted_by`, `means_notes`, `extensions`, `sugar_matches`, `on_handlers` and an instance's expansion are what the language made, so they're written, and nothing is minted while reading: `settled_since`'s minting and the trailing-mark projection go.
4. **What an instance was handed rides as data.** Its component as the file read it (`Provided`) is on the tape; a template component's statements are nodes on the same tape, so a read-back tree is a whole template source and no other file is opened.
5. **Origin is a node's own fact.** `foreign` ranges are an encoding that renumbering breaks, so each node's origin (path, spanned home, module) is a column, and the ranges go.
6. **Every byte belongs to one item.** Items partition a file's text: each runs from the end of the one before, the last to the file's end, an item is any number of statements (hoisted ones, several, none). So the header doc, every remark and every refusal belong to one item's tape.
7. **Every position counts from the item.** A tape reused where the item moved must read every position back moved, so positions are typed: a span is `@placed`, and an int that is an offset is marked `@offset` (`Remark.at`, a block voice's and a `Loc`'s `lo`/`hi`); a raw offset on a tape is refused.
8. **A parse that speaks is saved too.** Its diagnostics are what it made, so they're on its tape like the rest.
9. **The key is the whole input.** A tape is a pure function of the item's bytes, the language, and the block words its file stands under, so it's keyed by exactly those: the words fingerprinted as a value, never by which files they came from. The words are a program query over a file's `use` items and what they name, which declarations open a block read off the grammar.

**Found on the way, each from first principles (11-08).**

- **A fact points down, never up.** A tape reads a node's facts after the node, so a fact naming an ancestor names a node still being read. `instance_owners` (instance to its statement) is kept as `owned_instances` (statement to the instance it wraps), and `minted_by` (node to the sugar that minted it) as `mints` (sugar to its nodes); the upward tables are their indexes, rebuilt while reading in a parse's own order.
- **One fact, one column.** `docs` and `doc_ats` were two tables for a doc group and where it began, `-1` meaning none: one `DocGroup?` now, so absence is null and the offset moves with the item.
- **A by-hand route is invisible to the schema**, so none is left for facts: annotations, docs, the owner and an instance's facts are values. Only a root's own arena and places stay with its nodes (`@taped_with_nodes`), which its derive already describes.
- **A value holding a tree of its own lies as a tape of its own** (`@nested_tape`, `Holds.Tape`): a template's statements live in their provider's arena, and read back into a fresh arena so their spans never pass for the reader's.
- **A field a tape writes has bytes, or the derive refuses it.** `met_no_bytes` and the runtime "this tape can't stand" are gone.
- **A per-node fact keyed as text is a column.** `body_starts` was a `Map<string, int>` keyed `"${index}"`; `foreign` was ranges found by a linear search, now a column per node kind, O(1), and the ranges are gone.
- **The derive budget is declared.** `Expr`'s root writes and reads 64 variants in one compile-time run: `[lifted] steps = 2000000` beside `memory = 32`.

**Built (11-08):** `35b06082` shared nodes; `10294fdd` every table routed, meanings and what an instance was handed on the tape; `1d7dd880` one refusal table, tags, every byte in an item; `1fb10d4c` a subset entry found on the way.

**Decided 2026-11-08 (owner): a parse records what was written; an instance's meaning is a query.**

- **Reading.** An item's tape holds what was written, and the meanings of sugars that depend on the item alone (a pipe, a trailing block). It depends on the item's bytes, the language, and the *shapes* of the words its file stands under: each word, the component it names, and whether its instance binds its name (a record with no head). Never a template body, so no reading loops between modules, and a template edit re-reads no file.
- **A word's shape** comes from its declaration read with no words of its own (a template's body may use words; its shape never does), so a file's shapes need its `use` items and the declarations they name, and nothing recursive.
- **Expansion.** An instance's meaning is a saved query of its own: the instance's content and its component's template, by content, answering a tape of the expanded nodes. It points at the instance's written nodes by their numbers on the item's tape. A template edit re-runs only its instances' expansions.
- **A sublanguage block is the same case.** The lexer needs only its word (a shape) to read its body raw; running the provider's grammar over that body is its meaning, another file's, so it is an expansion too, its root kept as the block's meaning rather than in the node.
- **One definition.** Expansion is one verb (`Builder.minted_beside`): the parse calls it at an instance whose component it has, and `instances_expanded` calls it for the instances a parse of shapes left, so nothing is spelled twice.
- **A meaning stands where its instance does.** A declaration owns its nodes by allocation order ("source order is ownership order"), so an instance's meaning is allocated at the instance, before the statements around it. Expanding at the end of a parse, or even at the end of its item, puts meanings outside their declaration's run and the memory pass reads out of bounds (both were tried). So a parse that has the component expands inline, as it always did, and a parse that reads only a word's shape (`Instancing.Shaped`) leaves the instance meaning nothing; reading a tape back reads each instance's expansion at the instance, so the allocation order is a parse's.
- **Built (11-08, `ec102db7`): the context.** An item's tape is keyed by its bytes and its file's context, a saved query the language answers through the engine; Avra's is its words' shapes, worked out by the program's own module resolution, each declaration read with no words. With no words the context is the empty one, so a file without words shares one tape per item text everywhere.
- **The expansion, designed (corrected 11-08).** One saved query per item, `item_expanded(text, shapes, forms)`: the item's written tape read back, its instances handed their components and given their meaning by `instances_expanded`, and the whole item written again as one ordinary tape. A tape is written by structure, a meaning inside its instance's facts, so reading it back allocates each meaning right after its instance, a parse's order, whatever order the expansion's arena holds them in. Keyed by the written tape's key and the content of the forms the item's instances use, so a template edit re-runs exactly the expansions of its instances and re-reads no file. An item with no instance answers its written tape.
  - Tried and dropped the same day: a second tape extending the item's, read beside it at each instance. It needed references into another tape's numbering and a reader holding its extension, which is a cycle; one whole tape is simpler, reads faster, and costs only an instance-holding item's written nodes twice.
  - **A place says whether it's in the item's file.** A template's nodes copied home keep their provider's offsets so their refusals point home; those are absolute, every other place counts from the item. Built (`a6b07313`).
  - **What an instance was handed names its component, never copies it** (`52f7d458`): the expansion hands it again from the program.
- **Order.** (1) Expansion one verb, deferred only under shapes, results identical. (2) The parse reads word shapes; full words only expand. (3) The item tape keyed by shapes; instance meaning off it. (4) Program queries: a file's word shapes over `use` items and module resolution. (5) The expansion query. (6) The compiler reads tapes.

**Later, by the owner's word (11-08): found on the way, not in this work's path.**

- `decl_grain_test` "a declaration added keeps every query of main's" is red on the tree before this work too: `refs_index`, one whole-program reverse index from the hold lane (`b9271f8f`), moves with any declaration added anywhere and sits in main's frontier.
- 38 idiom violations in hold-lane files (`derive.av`, `cache_walk.av`, `program.av`'s `index_compared` from `f6372b27`, `db.av`'s `repeated_unwrap`, and more).
- `avra-oyy3`: a store once answered a derive's old output after the derive changed; not reproduced on demand.
- The formatter accepts two layouts of `program.av` as canonical (each is its own fixed point): whether a layout the author chose should survive is a formatter decision.

**The proof.** Generated from the same routes: every table of a direct parse and of a read-back compared, entry by entry under the node renumbering, on every item of the tree. A route nobody can compare is refused.

**Parse time.** Most of it waits for the generated parser. Before that, block words end the double parse on files with errors, parsing by item cuts an edit's reparse, and lazy bodies skip unused dependency bodies. A full cold `check` of a package still parses all its own bodies.

**Order.** (1) Lexed columns, items and hashes, with block words. (2) Parsing by item, compared against whole-file. (3) Tape and hydration, then measure load against parse and decide the save flag.

**Borrowed from.** Post-order tape with a size column: Carbon, Zig. Token columns and stored bracket partners: Zig, simdjson. Bodies parsed when asked: Zig's lazy analysis. Names compared as numbers: interning.

**Pace.** Owner 2026-11-06: slowly. One small file at a time, with a short explanation, then wait for review.

**Estimate.** 2-3 days, a rough guess.

- **The receipt, built 11-08: `avra tapes <package>`.** Every file read off its items' tapes for what it means, held to the old parse statement for statement: the same tape, every node where it was, the same fingerprint. Whole tree: 2264 files in 47 packages, 0 differing (std-avrac 1261 in 37 s). It found eight defects the old compiler carried, all fixed at the cause:
  - the `it` seat wore a sentinel id (-1): every seat now has an identity, and `implicit` says the source never wrote it;
  - an item split dropped the break its statement consumed: an item owns the token that ends it;
  - a node's print folded its marks in the order they were made, and snapshotted its children's prints at allocation: marks are a set (`Stamped`), and a settle derives every print from the finished tree, on demand, children first;
  - a trailing block was marked trailing by the meaning, after its parent was printed: the `trailing` rule says it, as a facet;
  - `is_heard`, `is_asset` were never worn back; `is_provide` was dead;
  - a template's format was named by file stem and arena index: by its own text's digest, hoisted once;
  - a template copy marked every node made during it as the template's, the user's fills too: the copier names what it copied (`made_nodes`);
  - a value a copied node held (a seat's written type) was placed in the item: a value stands where its node does (`entered`/`left`/`placed_within`);
  - a component's form read only its declaring item: its whole file, keyed by the file's declared components; components naming each other are one closure key.
  - Origins: the program names a file by address, the workspace by disk path; the receipt respells the workspace's (`respelled_origins`). The address is the truth: tapes are shared across worktrees.

- **Built 11-08, after the receipt** (`9fd246f3`, `7538c80c`, `949282fb`, avra-ho):
  - Sublanguage blocks wait for their grammar: the context keeps a word, its origin and whether its notation reads; the expansion reads each deferred block, keyed by the notation. A notation edit re-reads one item and re-expands only its users.
  - The tape schema is a const read off the declarations (`Reading.tapes_schema`); no derive generates schema, and `[lifted]` is gone from both manifests.
  - `quotes_at` is a `DenseWindow`; `hex`/`unhex` live in `@std/text`.
  - Red-team: a shared format head, an unread notation, a component edit.
  - Left, with reasons: the kind lookup by string (≤4 short kinds, no measurable cost); the Workspace's own copy of origins (retires with the Workspace); six other hex helpers across json/net/url/http/lexer/gallery (review-round sweep onto `@std/text`); 23 hold-lane idiom sites (item 8).
- **Next, in order:** (1) the compiler reads tapes instead of re-parsing (old Workspace untouched, new path beside it); (2) names and facts on the program engine; (3) the engine evicts answers it can reload — the memory fix (a whole-package check should peak at its working set, not the program).

## Clean before building on it (draft, 2026-11-06)

Each of these gets harder to change once later facts stand on it.

**Fix in the syntax layer.**

1. **Lexing reads imports.** Owner's decision 2026-11-06, refined the same day: whitespace-sensitive sublanguages must work. Splitting uses tokens from a file's text alone, with no block words, and is checked by the parse. Parsing an item reads the file's words, as a recorded read. Measured with no block words: 2,521 `.av` files, none unbalanced, one with a lex error (a `${…}` hole outside a string in `features/sublang/tests/sql`), which the split must tolerate. Component words are told apart at parsing.
2. **`declarations_in`.** Still has to go. No Avra connection file is needed: whoever composes a run hands over the lexer, `avra().syntax` and `avra_lexeme()`. The language hands over tokens and item kinds; the parser becomes its own seam from an item's tokens to a tape. `declarations_in` is removed.
3. **Item names.** Done: `item_name` in `source_items.av`, read from the grammar's rules. An item is called by the token after the run of declaring words opening its last line; an item that opens by holding members without declaring, or declares nothing, by the tokens before its first bracket. Owner's direction 2026-11-06: completely grammar driven, using existing structure. `item_shape` in `@std/grammar` is computed once at `ready` and held on `Ready`, with no language concept: item rule `stmt`, attached `PKG`, holders `spec`, `impl`, `trait`, `while`, `for`, `given`, deferred `fn`, `then`, assembly 14 ms. Tokens go through the existing `Lexeme<T>` seam, and `std-program`'s tests run a small real grammar. On the 347 files that parse clean, names agree on all 6,195 declared names, and all 492 `impl`s are named by their head. Across the tree: columns 101 ms, split 4 ms, hash 13 ms, names 3 ms. The other 56 can't be compared until they parse.
4. **Token hand-over.** Done: one octet of role bits per token, written through the grammar's token seam.
5. **Tape encoding.** The tape's hash must be one canonical form: sequences carry their lengths, so two different trees can't share bytes.

**Fix before typed facts.**

6. **Global world.** `current_world()` is process-wide mutable state behind the inputs. A world belongs to the engine value, so two engines can't share or race one.
7. **Positions in answers.** Diagnostics must point at item plus relative token, or moving a declaration invalidates them. Answers that print a line number read a part of their own.
8. **One reader's print.** `language_print` covers all reading. Split it per stage, so a parser change doesn't rerun lexing.
9. **Answers that can't be saved.** The design promises a digest-only record; the engine doesn't have one.

**Fix before landing.**

10. A crashed forked process traps the parent with the server's words. It should fall back to doing the work itself.
11. Disk limit and stale temporary files.
12. The compiler's suite against the memo change.

## Later ideas, not now

- Built-ins as real source in a toolchain package (like `@std/prelude`), which would remove the `BuiltIn` origin. Needs a small language addition; the owner deferred it 2026-11-06.

## Tracks B and C: merged, red-teamed, reviewed (2026-11-09)

- **Merged.** `program-scope` (track B) merged at c70ae14a/2204478f. `program-parser` (track C): its ten commits landed in `program` one at a time as reviewed cherry-picks, and e8717b05 records the merge (`git cherry` marks all ten patch-equivalent; the trees differ only by `program`'s later `pool-check`). Both branches are ancestors of `program`.
- **Red team and review round, tracks B and C, done (33fadd80, 2026-11-10), per the red-team and review-round skills:**
  - Programs run:
    - Track B: 31 packages through four oracles, 23 processes across edits, and 6 memory cases.
    - Track C: 21 degenerate grammars with every one-token mutant (3,581 runs, 0 differing), recursion depth, and the largest and empty files.
  - Six wrong answers, all fixed with tests written first:
    - two test-import resolutions of private names;
    - a module that is both a file and a directory losing its files;
    - a damaged store's stale part read;
    - the generated parser's print missing slot order, which would have kept a stale parser passing payloads swapped;
    - the generator writing parsers for grammars the engine refuses.
  - Decided for the program layer, against the old workspace: a third file's read of a name two siblings keep private stays `KeptApart` even when the prelude exports it (CLAUDE.md's law; the workspace lends the prelude's), and a name declared as both a fn and a type binds both spaces (the workspace binds the type, then refuses the call).
  - Tests: std-program 345/345, std-grammar 56/56.
  - Receipts: tapes, `--signatures`, `--core` and parsers 0 differing.
- **Red team, track C (earlier).** `avra parsers --mutants 8` holds the generated parser to the grammar engine on each package's files AND eight broken mutants of each, trees and errors and recovery alike: std-text, std-program, cli, std-io, std-meta, 1,638 files, 0 differing, at 4a5df7f6. Plain differential over the whole tree: 57 packages, 2,516 files, 0 differing.
- **Red team, track B.** `avra tapes --signatures` holds every resolved signature and every typed node to the old Workspace, by span: 0 differing on std-avrac (1,311 files), cli, std-program, std-text. Every difference found on the way was a named bug and fixed (alias expansion, union order, C widths, import renames, `_`, and in the binder slice, the `@std/meta` delegate defect below).
- **Review.** Every commit landed on `program` was read before landing; findings fixed in place were the impl index filing by written name (now by resolved declaration), work-ahead re-reading every input (now one engine), and the doubled path walk in `avra_io_open`.
- **Suites run on the tip:** std-program 269/269, std-io 121/121, std-text 200/200, std-grammar 53/53, std-prelude and std-meta programs eval == native == expected. Not run here: std-avrac's and cli's, each a whole compile of std-avrac in its test binary (6–7 GB); they need the runner (below).
- **Receipt scope:** the goal named 47 packages, the count when it was written; the tree now holds 57 (tools/ included), and the receipts above cover all 57.

## Measured 2026-11-10 at 33fadd80 (after the tracks B and C round)

- **Fixed point:** `make avra` twice, byte-identical (104,517,936 bytes).
- **Whole-tree receipts:** `avra tapes` over all 57 packages, 2350 files, 0 differing; `avra parsers` over all 57, 2546 files, 0 differing (generated 3.3 s, engine 10.6 s).
- **std-avrac, program layer** (67a86ecd, unchanged since): cold 4.2 s, every process ≤ 45 MB of heap (parent 39), warm 93–97 ms with 0 records checked, one body edit ~170 ms.
- **The generated parser has landed:** `compiler/untold_parser.av` is the parser the compiler runs, used whenever its print matches the assembled grammar. `make parser` refuses a stale one, the print now covers start, render and slots, and `AVRA_ENGINE_PARSE=1` selects the grammar engine instead. It matches the engine on every file of the tree, trees and errors and recovery: 57 packages, 2,546 files, 0 differing, at 33fadd80.
- **std-avrac tests on a GitHub runner from the refreshed seed (d7db5c27):** the three the review round changed, `features/quote/tests` 150/150, `compiler/tests/subset` 91/91, `rules_table_test` 7/7. Each peaks ~7.9 GB, so the shim's 6,000 MB ceiling is raised for the runner only (`AVRA_MEM_CEILING_MB=14000`). The item-layer tests, the same way: item_names 4/4, item_package 3/3, item_scope_adversarial 25/25, item_scope 9/9, item_signatures 7/7, item_tapes 17/17. Three of item_tapes' read counts were stale against the scope fix, which reads a module's files from the listing instead of probing the file it isn't; their expectations were updated at 26528ce2.
- **std-avrac's full suite as one run does not fit a 16 GB runner**, measured (runs 42855506178 → 42861437855, 11-10):
  - Raising the shim's 6 GB ceiling and the 60% memory pool for the runner gets it through all 226 rule examples and ~430 program proofs.
  - Building the remaining test units then passes even a 14 GB ceiling (peak 13.8 GB).
  - This predates today's work: run 42762284118 on 11-09 failed on a 15 GB ceiling.
  - So it runs **split into parts that each fit**, the owner's plan for just before the switch. Every std-avrac test file today's work touched has run green that way.
  - Two lessons from the runs: receipt fixtures belong under a package's `tests/` but outside `src/`, so the suite never compiles them and the compiler key never counts them; and a runner needs `AVRA_MEM_CEILING_MB` and `AVRA_MEM_POOL_MB` sized to it.
- **Suites:** std-program 345/345, std-grammar 56/56. std-avrac's own suite does not fit this machine (its test binary passes 6 GB); by the owner's direction of 11-10 it runs once, split to fit a runner, just before the switch lands.

## Measured 2026-11-10 after the format batch (30df1bfc)

- **std-avrac, program layer:**

  | Run | Time | Records checked |
  |---|---|---|
  | cold | 3677 ms | — |
  | warm | **92–95 ms** | 0 |
  | one body edit, through a delta | **155–171 ms** | — |
  | the write that folds (every fifth) | 237 ms | — |

  - The frontier's write fell from ~125 ms (whole) to 14–16 ms (a delta).
  - What's left of an edit beyond warm: suspects +13 ms, verifying ~2,230 records 33 ms, the write ~15 ms, about 6 µs per settled answer compared with the frontier.
  - The new base is 1.8 MB (was 2.25).
- **What was built:**
  - Change-only frontier writes as one delta chain, each file named by its bytes' hash and naming its parent. A reader stops at a fork, a torn delta or one that doesn't fit. A delta is written while the chain is under 4 and the change is at most a quarter of the base; otherwise, and at every compaction, the chain folds.
  - Structural checks at open: packs' and frontiers' tables lie within their files; spans and read places are checked where read, so warm doesn't pay a pass over 59k spans. A file that fails reads as foreign.
  - Roots are marked, so unreached inputs are forgotten.
  - `FrontierState` is an enum, and deep records are deleted, all in one seal bump.
  - std-program 330/330.
- **Whole-tree parsers receipt at 67a86ecd:** `avra parsers` (generated parser against the grammar engine, every builder call, trees and errors) over all 57 packages, 2531 files, 0 differing; generated 3.3 s against the engine's 10.7 s.
- **Cold heap, fixed at 67a86ecd:** every process ≤ 45 MB; the parent is 39 MB (was 94). The largest, 45 MB, is a worker lexing source. A learned answer is the frontier's entry, and its reads are plain number pairs. Columns are built straight from places, and the writer puts no box on each number. The format is byte-identical. Edits are unchanged on the same machine (170–179 ms that day). std-program 339/339.
- **Cold heap, as first measured at 30df1bfc (`AVRA_MEM_STATS`), regressed:** the parent peaks at 94 MB; the 8 workers at 9–45 MB. Before the frontier the largest process was ~46 MB, so the regression is the frontier base built and written in the parent at a cold run's end (34,441 entries; top sites `FrontierColumns.written_into`, `placed_entry`, `renumbered_entry`, the saved-layout writer). Being fixed by streaming the columns, target every process ≤ ~50 MB.


## Measured 2026-11-10 after the red team (015be8a4 and the dyn fix)

- **Red team, frontier and meanings:** 44 frontier cases and 142 meaning packages, every attack class.
  - Five defects fixed with witnesses:
    - an input asked first read twice, a stale answer forever;
    - the print missing `is_input`, a stale answer;
    - an idle process blanking the frontier;
    - `??` over a never-absent left;
    - `for` matching only one-statement bodies, a quote fold keeping the run's count.
  - Recorded in Open: dropped-`match` typing for the switch, and validating sealed but garbled cache files.
  - std-program 308/308.
- **Fixed point:** g2 == g3 (104,310,944 bytes). g1 differs because it is the first generation whose compiled quote shapes carry the run fold.
- **Meanings receipt, 0 differing:** std-text 11 sugars and 1 loop; cli 208 and 46; std-program 87 and 18.

## Measured 2026-11-10 on the tip (160d137d)

- **Fixed point:** `make avra` twice at 160d137d, byte-identical (104,310,736 bytes), with slice 1's meanings, the frontier and the idiom fixes in the source.
- **std-avrac, program layer, with the frontier:** warm checks 0 records in 97–98 ms; one body edit checks ~2,230 records in 258–268 ms (about 125 ms of it the whole-frontier write); cold 4.0 s.
- **Meanings receipt (`tapes --core`), 0 differing:** std-text 11 sugars, 1 loop, 1387 nodes; cli 209, 29, 13538; std-program 76, 7, 6938.
- **Suites:** std-program 269/269.
- **Whole-tree receipt at 160d137d:** `avra tapes` over all 57 packages (packages/ and tools/), 2,348 files, 0 differing.

## Measured 2026-11-09 on the tip (49d1d221 → 4a5df7f6)

- **Fixed point:** `make avra` twice, byte-identical, at 49d1d221 and again at 4a5df7f6 (104,192,528 bytes).
- **Whole-tree receipts at 4a5df7f6:** `avra tapes` over all 57 packages (packages/ and tools/), 2,337 files, 0 differing; `avra parsers` (generated parser against the grammar engine) over the same 57, 2,516 files, 0 differing, generated 3.4 s against the engine's 11.1 s.
- **std-avrac, program layer (`avra tapes --program-only`):**
  - cold 3.7–4.3 s over 9 processes; heap peak 13 MB in the parent, largest child 48 MB (runtime accounting, `AVRA_MEM_STATS`). Peak RSS reads 224 MB, but that includes the mapped 104 MB binary.
  - warm 87–99 ms in-process, ~130 ms wall (about 40 ms of that is process start, dynamic symbol binding).
  - one edit 280–340 ms: **over the 300 ms target**. Profiled with 20 distinct edits in one process: the root's deep record misses, so ~18,000 questions re-verify through their stored records. The time is store decoding: index binary searches (~17 probes each), word reads through `avra_mmap_word_at`, shifts lowered as runtime calls (`avra_int_shl`). Not the pool, not store growth (a fresh store measures the same), not disk syncs.
  - Built since: a question beneath a root keeps a deep record when it reads no more inputs than its own reads (never bigger, never slower to check), so an edit verifies it without walking beneath it: one edit now **284–299 ms**, under the target. Left, by size: the shift and word-read rows emitted inline rather than called (every program gains); interpolation search over the uniform hash keys (~4%).
  - Counted 2026-11-10 (`records checked`, a deterministic counter in the engine, printed by `tapes --program-only`): warm checks 1,039 kept records in 107 ms; one body edit checks **26,445** in 277–316 ms while computing only 6 answers. The edit's cost is the pull walk from the root, about 8 µs a record. Next: push from the changed inputs instead (Skyframe-style change pruning over reverse edges kept in the pack), so an edit checks only what it can have changed: expected tens of records, edit ≈ warm.
  - **Why, found:** after an edit the root is re-settled, and keeping its new deep record walks every record beneath it (`deep_record_kept` → `inputs_reached` → `settling_record` → `stands_now`): most of the 26,445 checks are that walk, not verification. **The fix, designed (the 10-06 design's §6.2 steps 2–5, push-dirty pull-verify):** each run's save writes a **frontier** for its binary (keyed by the definitions' print): the input digests it saw and every answer it settled or carried, each with its reads as positions. The next run of that binary asks the frontier's inputs first, diffs digests, takes the changed inputs' transitive readers over the reverse of those reads as suspects (one pass over the edges, only when something changed), and settles every other question from the frontier untouched; a suspect is pull-verified as now, early cutoff included. The frontier written next holds the questions settled in this run plus the non-suspect ones carried, a closed set: a carried question's reads are carried or settled, since a reader of a suspect is a suspect. Each frontier is written whole by one process (draft + rename), so it is self-consistent at the digests it names, whatever other processes write; a missing or other binary's frontier means pull as today. Deep records are then redundant and are deleted with their bit sets (the frontier covers warm, and edits stop walking). Expected: warm about 0 records checked, an edit about its suspects (tens to a few thousand), edit ≈ warm. Queued behind slice 1.
  - **Built and committed (285b8f39, 2026-11-10), and reviewed: std-program 269/269.**
    - A reviewing agent's probes found two defects in the first draft, both fixed with witnesses: (1) an unhashed query's code can change under one print, so the frontier served its readers' old answers; now such a query is read afresh like an input. (2) a save that compacted before the frontier was written left a frontier naming dropped answers, and the next process trapped; now the store holds the frontier as pending, seeds compaction from it, and writes the file only after the pack holding its answers is published.
    - A part read whose bytes are gone re-asks with the question in hand, or doesn't hold.
  - **The first draft, as built:**
    - `std-program/src/frontier.av` holds each binary's frontier. The engine asks the frontier's inputs first, takes the readers of changed inputs as suspects (`readers_of`, one pass over the edges), and settles every other answer untouched, roots included. A save writes the frontier when anything besides an input was learned.
    - Deep records are no longer written, and their bit sets are gone.
    - Compaction seeds its walk from the newest two frontiers by generation, and removes older frontier files under the same ceiling. Before this, compaction's roots were "questions holding a deep record", so deleting deep records alone would have kept nothing; the suite caught it.
    - **Measured on std-avrac:** warm checks **0** records in **90–97 ms**; one body edit checks ~2,230 in **257–275 ms**, ~125 ms of it rewriting the frontier whole.
    - **The write made O(change), designed:** an edit verifies ~2,230 suspects but changes only a handful, and a verified-unchanged entry needs nothing written, since the base still says it. So a save writes a **delta** beside the base: the entries whose answer or reads changed, new questions, and the places of suspects it didn't verify (stale, so the next process treats them as suspects). Readers overlay the deltas, a small hash, over the base. Compaction folds them into a new base, and the number of deltas is bounded the way packs are, by absorbing ones no bigger than the newest. **Concurrency:** an entry is right only at the inputs its writer read, so two processes' deltas can't be merged entry by entry. Each delta names the frontier it was built on (base plus the deltas it read, by hash), and a reader follows one linear chain. A delta whose parent isn't the chain's end is a fork, and the chain stops before it: repeat work, never a wrong answer. This is the 10-06 design's live segment (frames with a commit marker, a torn frame ignored) given a parent. Expected: an edit's write drops from ~125 ms to a few, and an edit costs ≈ warm + its suspects (~135 ms).
    - **Left:** sixteen std-program expectations (deep counts, compaction tests writing a frontier, version-keeping now per frontier, an in-memory frontier), then making the write O(change).
- **The seed is committed compressed (a6ce4603).** `program`'s compiler emits 102.5 MiB of IR, past GitHub's 100 MB per-file limit, so the seed is `bootstrap/seed.ll.zst` (zstd -19: 4.4 MiB, 0.5 s to decompress); one Makefile rule makes `build/seed.ll` for `recover`, `bootstrap` and `seed-check`. A refresh now adds ~4 MB to history instead of ~100. `make bootstrap` is green from it and reaches the same fixed point.
- **Warm-path fix (9150939c):** work-ahead now hands back the engine that asked what was known; a warm read used to open the store twice and run three engines, re-reading every input each time (110 → ~92 ms).

## Draft, owner reviewing 2026-11-09: typing on the engine

The old typing rules are written against a process-wide type table (numbers valid in one process), side tables keyed by node ids and a whole-file context. None of that carries over. The rules' logic does, ported.

1. **A typing rule is data, compiled into the checker.** A feature states its rule in its own `mod.av`, as an instance of a `check` component (an ordinary Avra component like `command`, no new compiler syntax):

       check If { cond: bool, yes: want, no: want } -> joined(yes, no)
       check Call { callee: fn(..args) -> ret, args: each(args) } -> ret

   The component's expansion generates the checker: one fn per node kind, no dispatch tables, as the generated parser does for the grammar. A rule that isn't a plain judgment (patterns, exhaustiveness, borrows) stays code, `impl Checks for <Node>`, against the same context. `avra explain` prints a node's rule.
2. **Type off the tape.** The checker walks an item's saved tape and writes a types column beside it; it never rebuilds the node arena. Inside a body a type is a small handle into a per-body table, with union-find for generic variables; equality is one compare. Only the settled column is saved.
3. **One query per declaration, behind the signature firewall.** `typed(decl)` reads its own signature and, per name it uses, `resolved` then that declaration's signature. A body edit re-checks that body; a signature edit re-checks its readers. Answer: the types column and the refusals.
4. **Types as content values** (`SignedType`, built for signatures), hash-consed; saved and shared across processes.
5. **Bidirectional checking**: each node checked against a want or synthesized, as the old rules already do in spirit.
6. **Refusals are data**, a stable key and payload, worded only when rendered (`said(f)`).
7. **A prebuilt std pack**: std ships with the compiler, so `make` types it once and ships the answers; a user's cold check never parses or types std.
8. **Parallel by declaration**: bodies are independent, so typing fans out across cores like the cold parse.
9. **Proof**: `avra tapes --types` holds every node's type to the old compiler's, as `--signatures` does; 0 differing, or a named bug.

**Built (1fcf2d62, d32b9767).** `Checks` (collected over `Expr`) and `StmtChecks` (over `Stmt`), defaulting to "check what the node holds, answer nothing"; `Checking` in core with types as values and the program's answers handed in as fns; `typed_fn(file, name)`; rules for literals, names, calls, `if`, blocks, `let`/`mut`, expression statements. An expectation is used (`Exactly`/`Free`), dropped, or unknown. `avra tapes --signatures` holds every typed node to the old typer, paired by span: std-avrac 1,288 files, cli, std-program, std-text, 0 differing.

**Built since (c86b0098 → 1e03c844).**
- **Every binder has a rule; the fallback is deleted.** Patterns type through one `PatChecks` trait collected over `Pat`, every kind answering. `match`, `v? ->`, `is`, `catch`, comprehensions, `let` patterns, `select` arms, components, `collect`, `const`, assignment, `defer` each say what they bind. Gone: `held_checked`, the `unruled` counter, opaque scopes. A node holding a binder gets no derived default, so a binder without a rule doesn't build: a compile error, never a silent wrong read.
- **One concept per job.** Narrowing and `is` are one `Proof`. `null` is `never?`, `[]`/`{}` are `List<never>`/`Map<string, never>`: no variants of their own. One join (`joined_with`) serves branches, literals and type-parameter fills. `Checking.fills` is the one instantiation (calls, records, written type arguments). A type counts its nulls (`T?` filled with `string?` is `string??`).
- **The language's own types' verbs are signatures (49d1d221).** `@std/prelude`'s `verbs/<Type>.av` declares each built-in method as a plain fn, receiver first (`fn map<T, U>(xs: List<T>, f: fn(T) -> U) -> List<U>`); `verbs/props/` the properties. Nothing compiles them; what a verb does stays the compiler's. Every method, an impl's or a verb, is one fn type, receiver first: the receiver seat unifies with the subject, then `fills` as for a call (plain arguments, then the seat's want for what's still open, then fn arguments; a fill holding `never` pins nothing). This replaces, for typing, the ten feature `table<MethodRow>`s' 60-odd `check_*` fns. When the old typer goes, their `lower` column is what stays.
- **Meeting, as the old typer has it:** an `if`'s branches join first and take the seat's type only where they can't; a `match`'s arms take the seat's type first. Only a guard `if` (a statement) and its branches are `void`.
- **Size:** the new typer is about 2,000 lines (rules, core, signatures) against the old ~14,000 (10.7k in feature `check.av`, 3.2k in `compiler/typing`).
- **Coverage, measured as parity (7ddb318f):** of the nodes the old typer types, the program layer types identically **std-text 100%** (1,407), cli 99.7% (43 left of 13,678), std-program 98% (107 left), std-avrac 98% (4,158 left of 264,334); 0 differing. Rules since 92%: types as values (`Meta`), statics and trait methods, verbs as signatures with overloads by receiver, text and quote bodies, `?.`, components, defaulted seats, tasks, named arguments, spreads, `when`, literal and computed consts, bidirectional lambdas. **What is left is mostly generated code** — methods and fns `@derive`/`@query`/`@parted_query` write (`AnswerParts.parts_in_place`, `kept_length_definition()`) and the nodes reading them. The program layer sees written source only; reaching 100% means running generators, the "generated declarations" stage, which needs lowering and evaluating on the new typer: in effect, the switch.
- **Next by size:** the language's own types' methods and properties (one table, read by method calls and field reads); `Binary` over every operand kind; `dyn` and traits; then refusals as data, and delete the old typer.

- The receipt skips nodes the old typer left untyped (a literal folded into `-1`) and orders unions by spelling: comparison honesty only, nothing in the new typer.

Order: the memory pool (a machine-wide memory reservation every heavy process takes before starting, so parallel tracks can't crash the machine); the typing core (2, 3, 4, 5) with the If/literal/call/let slice as code; the `check` component (1), proven by porting that slice; the rest of the features in parallel tracks; then 7 and 8.

## Draft, owner reviewing 2026-11-10: from typed program to running code, first principles

**The observation everything follows from.** A feature's meaning and a `@derive` are the same thing: code that writes code. `x ?? d` means `match x { v? -> v, null -> d }`; `@derive(Saved)` means "these methods, written so". Today the two live in different worlds: 4,700 lines of per-feature lowering emit IR by hand, and generators run in a separate expansion engine. Collapse them (P6). **Every feature means a rewrite into a small core of Avra, written as a quote, and a generator is the same kind of rewrite.** One engine elaborates both; only the core reaches the machine.

**1. The core: about fifteen forms, and nothing else lowers.** Literals; names; `let`; calls (direct, of a value, of a runtime row); records and variants built and read; `match` (over variants, presence and literals: the one branch); `loop`/`break`; `return`/`fail`; closures; cells. Every other construct is sugar: `?.`, `??`, `if`, `for`, comprehensions, `?`, `with`, interpolation, `when`, `collect`, `spawn`, components. The core is typed by the typer that already exists, so every rewrite is checked: a feature whose meaning doesn't type is caught at its definition, not by a crash in a backend.

**2. Meanings are declared, beside the grammar that reads the feature.** A `meaning` component, an ordinary Avra component like `command`, in each feature's `mod.av`:

    meaning Coalesce { left, right } = quote { match ${left} { v? -> v, null -> ${right} } }
    meaning ForEach { name, subject, body } = quote { …index loop over ${subject}… }

Its expansion compiles the rewrites into the elaborator: native code, no dispatch tables, as the generated parser compiles the grammar. A feature is then three declarations, each a few lines and each readable: its grammar, its typing rule, its meaning. `avra explain --core f` prints any fn as the core it means (P7). An LLM learns a feature by reading what it means in the language it already knows (P1).

**3. Generators run through the same engine.** A generator is a pure function from a declaration's shape to code. Its answer, `generated(d)`, is a saved answer keyed by the declaration's tape hash and the generator's code hash, so it runs once per change on any machine that shares the cache. A generator resolves against written names only (Roslyn's rule): no cycles. Generated code then elaborates, types and lowers like written code, and typing parity reaches 100% as a consequence.

**4. Memory: Perceus on the core.** Ownership is decided once, on the small core, where it's tractable and provable (Koka): every value's last use is known, so dup and drop go exactly where they're needed, borrowed parameters cost nothing (as now), and a box that dies is **reused in place** by the next allocation of its layout. A functional update (`r with { x }`, rebuilding a list) becomes an in-place write whenever the value is unique (functional but in place). The memory pass's 5,600 lines of inference over the low-level IR become a precise pass over fifteen forms.

**5. Instantiate by layout, not by type, and share code by content.** A generic body's machine code depends on its type arguments' layouts (word, float, pointer to a box), not their names, so a unit instantiates once per **layout signature**: `List<Foo>` and `List<Bar>` share one `map`, as Go's GC-shape stenciling does. What does differ by type, a trait method, is passed as a witness, as Swift does; hot paths specialise past that by plain inlining. Then every unit is content-addressed by its IR hash: two units with one IR are one symbol, identical-code folding before LLVM ever runs, and the object code is cached by that hash across builds, branches and machines (the CAS already exists).

**6. The IR: structured, columnar, layout-typed.** Structured control flow (regions, as now: what the interpreter and wasm want, and LLVM is happy with), stored as columns (kinds, operands, an extra pool), read in place, Zig AIR-style. Register types are layouts, not language types, so the backend, interpreter and memory pass ask nothing of a type registry, and the old `TypeRegistry` retires with the old typer. The curated `Ins` vocabulary and its growth protocol stay: the core-to-IR lowerer is the one place that emits it, a few hundred lines, hand-tuned (switch tables, presized buffers, in-place pushes).

**7. Two engines, one IR, and a fast dev path.** The interpreter runs generators and `avra run` straight off the IR, with no LLVM. Release builds emit LLVM per unit, in parallel across cores, each object cached by IR hash, so a one-fn edit compiles one fn.

**8. Everything is a query on the engine, early cutoff at each stage.** `elaborated(d)` → `core_typed(d)` → `owned(d)` (Perceus) → `lowered(unit)` → `object(ir hash)`. A body edit moves one chain; a comment moves none; a generator re-runs only when its input or its code moved.

**What it deletes when done:** the old typer (~14k lines), per-feature lowering (4.7k), the expansion engine's separate world, the memory pass's inference (most of 5.6k), the `TypeRegistry`, and the ten `MethodRow` tables (verbs carry their runtime row: `fn push<T>(mut xs: List<T>, x: T) = rt avra_array_push`).

**Proof.** Semantics first: every program test, eval == native == expected, through the new path. Then performance: `make census` counts (retains, releases, allocations) no worse than the old path on the same programs, and better wherever reuse applies. Then the old path is deleted.

**Already in the tree, and what the engine builds on (one mechanism, never a second).** `Meaning.means(cx) -> Rewrite?` (a quote) and `Meaning.minted(cx)` (hand-built nodes) are spliced at parse time by `compiler/sugars.av`, and typing and lowering read the meant node (`cx.meant_type`, `cx.meant_reg`). One feature already means by quote: `~x` is `quote { ${self.value} ^ -1 }`. Seventeen mint by hand. Derives are quotes already (`@std/derive`'s `static fn derive(t: Type) -> List<Directive>`). The engine generalises this hook rather than standing beside it. It gains three things: **typed once** (a template is checked generically under its holes' types, so a meaning can't make ill-typed code), **hygienic** (a template's binders are fresh, Racket's sets-of-scopes), and **type-directed** (a meaning may choose by a field's type, picked by the unification that picks verb overloads).

**Approved by the owner 2026-11-10, with all five additions:** (1) typed holes `${x: Type}`; (2) a quote-to-quote arm read backwards: resugaring in errors and `explain`, code actions both ways; (3) `@example(before, after)` on any arms component, generalising `rule`'s `@fixes`/`@keeps`, run by the compiler and shown in docs; (4) every instance's arms compiled into one matcher, refusing an arm that can never fire and a sugar kind with no meaning; (5) template names fresh, a name for the user's code spelled `${name("it")}`.

**Spelling:** no new syntax. `meaning` is an ordinary component, `export component meaning { run: fn(dyn Subject) -> Code? }`, written the way `rule` already is: an arms body, quote patterns on the left, quotes on the right — `meaning coalesce { quote { ${left} ?? ${right} } -> quote { match ${left} { v? -> v, null -> ${right} } } }`. Type-directed choice is an arm guard (`if xs.type()…`, as `str_grown_quadratically` already writes); a typed hole `${xs: List<_>}` is the sugar both `rule` and `meaning` want. The first draft's `meaning X { fields } = quote {…}` was new syntax and is dropped.

**Beyond the switch, each its own slice:**
- **Perceus reuse:** `consumed` seats are already inferred, and reuse turns them into in-place writes.
- **Generics by layout.**
- **Case-of-case and proven laws in an e-graph** (egg, Cranelift aegraphs).
- **A copy-and-patch dev backend:** a stencil per `Ins`, compiled from C at build time (Xu & Kjolstad 2021).
- **Live update in `avra dev`:** a slot table, with state kept.
- **`avra ask`/`explain --core|--memory|--units` over MCP**, every decision a fact with its reason.

**Slice 1, built so far (2026-11-10, `program` 5d069b36 → 30297a5c):**
- **What landed:**
  - `component meaning { run: fn(TypedCode) -> Rewrite? }` beside `rule`, gathered by `collect meanings` and filed by root kind.
  - Its subject `TypedCode` is one node of an item the new typer read, with `type()`.
  - `FillClass.Node` splices a hole by node, never by text, and `fills_by_node` replaced the two `is .Id || is .PatId` registry tests that had silently forgotten it.
  - On the new layer, `elaborated_fn` types a body, splices each sugar's meaning beside it (`rewritten_beside`, the existing splice) and types the body again as core (`Checking.meanings`).
  - `meaning coalesce` is the first instance.
- **The ladder:** three rungs, each committed with a `Rung:` trailer, because the compiler's own meanings need a builder that knows the fill class and the subject law.
- **Receipt `avra tapes --core`:** a sugar's surface type and its core type must agree, or the core answers its seat's want and the surface type reaches that seat (`SignedType.reaches`: as it is, `never`, widened to nullable, or `Ok`).
  - std-text: 3/3.
  - std-program: 22/22.
  - cli: 100 alike plus 4 answering their seat of 108, **0 differing**, 4 untyped on a side. Three of those are untyped on both sides; one is a `??` in a comprehension clause the core pass leaves untyped.
- **Since (1ce59bc4, 629d69f3):**
  - A held node fills only its own arena's seat: a handle fills as arena and index, a run of handles as one fill (`FillClass.Nodes`), and a mismatch is refused in words, never read as the wrong node.
  - `meaning if_else` means a two-branch `if` as a match on its condition. A node the parse already gave a meaning keeps it.
  - Receipt, 0 differing: std-text 11/11; cli 199 alike plus 5 answering their seat of 208; std-program 67 of 77, 10 untyped on both sides (derive code).
  - Backlog: `true` and `false` together don't cover `bool`.
- **`for` needs four things first:**
  - statement meanings (a statement's `meant` link, and a `Rewrite` whose body is statements);
  - **hygiene**, since a template's counter would capture a user's `i`;
  - the counter incremented before the body, or `continue` never ends;
  - the loop's label carried over, since `break b12` names the `for`.
  
  Typed choice (list, range, map) then picks the arm.
- **The rest of slice 1, where to start:** `@example`, reading a rule backwards and `avra explain --core` all need a core tree printed as source. The formatter's `render_source_of(store, stmts, text)` (compiler/workspace.av's `formatted_source`) renders from the node store but takes the source text too. A meaning's minted nodes are placed at the sugar's span, so a span-reading print would spell the sugar's text where the core stands. Probe that first. If it reads spans for literals or names, the printer needs a mode that prints a node from its fields alone. That is one definition serving `fmt`, `explain --core` and examples (P12), never a second printer.
- **Seed refreshed at the fixed point (d7db5c27):** a runner now builds the tip straight from the seed instead of climbing five rungs.
- **`for` and statement meanings, built (fc6226bb, a8e07815):**
  - A statement means statements (`stmt_meanings`, by key, made by elaboration). `meaning for_each` walks a list's positions, counting past each element before the body runs, so `continue` terminates. A body that breaks by label keeps the surface form, since the label names the `for`.
  - A match on a condition now proves what an `if` does (`true`/`false` arms, and a catch-all after one literal). Without it the `if` meaning lost flow typing.
  - `tapes --core` holds every node, not only sugars. 0 differing: std-text 11 sugars, 1 loop, 1387 nodes; cli 209, 29, 13552; std-program 77, 8, 6894. Parity unchanged.
  - **Hygiene witnessed failing without it:** with the mark off, std-program's `token_columns` had a user `at` (a `Loc`) in a `for` body captured by the template's counter. Two nodes differed; with the mark on, 0.
- **Hygiene, built (7aed7fb3):** a meaning's copy marks every scope name its template writes with `·<sugar index>`, unspellable and the same every build, so its binders neither capture nor are captured. A name through a hole keeps its spelling (the escape), and derives copy unmarked. Receipts unchanged at 0 differing. The capture witness lands with `for`.

**Step 1, done (2026-11-10): the core is a subset of the nodes that already exist.** The tree has 92 node kinds (63 expressions, 29 statements). Fifteen are the core, and the typer already types every one of them:

| Core form | Existing node |
| --- | --- |
| literal | `IntLit` `FloatLit` `BoolLit` `StrLit` `BytesLit` `NullLit` |
| name | `Ident` |
| bind | `Let`, `MutLet` |
| write | `Assign` |
| sequence | `Block` |
| call | `Call` (a fn or a runtime row) |
| call a value | `CallValue` |
| primitive op | `Binary` `Not` `Neg` `Bitnot` |
| build | `StructLit` `VariantLit` |
| read a field | `Prop` |
| branch | `Match` (variants, presence, literals) |
| loop | `While` |
| leave a loop | `Jump` |
| exit | `Return` `Fail` |
| closure | `Lambda` |

So elaboration rewrites sugar nodes into core nodes **in the same arena**, the same typer re-types the result (the check that every meaning is sound), and the same tapes store it. No new language, no new node types.

Sugar, about 48 expression and 10 statement kinds, each meaning a rewrite into the core:
- **Branches:** `If` → `Match` on `bool`. `Coalesce`, `Chain*`, `Force`, `Propagate`, `Is`, `MatchOpt`, `LetPattern`, `LetElse`, `When`, `Catch` → `Match`.
- **Loops:** `ForEach`, `Comp`, `Collect` → `While` over an index, pushing into a presized list.
- **Builds:** `With` → `StructLit` over the copied fields. `ListLit`, `MapLit`, `Table`, `Range` → builds and runtime rows.
- **Calls:** `MethodCall`, `Pipe`, `Named`, `Index` → `Call`.
- **Closures:** `Trailed`, `BlockLambda`, `ArmsBody` → `Lambda`.
- **Statements:** `Defer` → exits woven in. `Discard`, `ExprStmt` → `Let _`.
- **Bodies:** a text `Body` → concatenation rows; a quote `Body` → `Code` builders.
- **Tasks and components:** `Select`, `WaitArm`, `Spawn`, `Within`, `Emit`, `Produce`, `Channel` → runtime rows and closures. Components → builds and closures.
- **Small cases:** `Receiver` → a name. `TypeLiteral`, `ChainType`, `Env`, `GrammarLit` → constants. `Error` was already refused.

Declarations (`FnDecl` … `Spec`, about 15) aren't expressions. Each becomes units, or nothing at run time.

1. The core's forms, and the typer covering them (most already).
2. `elaborated(d)` and the `meaning` component, proven on `??`, `?.`, `if`, `for`.
3. The core-to-IR lowerer, `layout(type)`, and units by layout.
4. Program tests through the new path, the interpreter first.
5. Generators through the engine, typing to 100%.
6. Perceus with reuse.
7. LLVM per unit, cached by hash, in parallel.
8. Switch, and delete.

**Sources:** Koka/Perceus (precise RC, reuse, FBIP); Lean 4 and Racket (a tower of rewrites into a small core); GHC Core (a typed core as the checked contract); Go GC-shape stenciling and Swift witness tables (instantiation by layout); Zig AIR and Cranelift (columnar IR); Unison and Bazel (content-addressed, cached, hermetic generators); Salsa (the incremental engine underneath).

## Draft, owner reviewing 2026-11-10: lowering, and every target, as declared rewrites

**The observation.** Meanings showed that sugar → core is a set of declared rewrites, pattern to template, checked and hygienic. The rest of the back end is the same shape, one level down each time. So the whole compiler past typing is **one tower of three rule kinds on one engine**:

    surface --meaning--> core --lowering--> IR --target--> interpreter | LLVM | C | wasm | stencils

Every kind is an arms component (as `rule` and `meaning` are), exhaustive over the enum it reads (a missing case is refused when the compiler builds, as an `Ins` with no arm in a target), carries `@example`, and prints through `avra explain --core | --ir | --c <fn>`.

1. **Lowering is a fold, declared.** The core has ~15 forms. Each declares its IR as a template whose holes are the registers its children lowered to: syntax-directed translation, a catamorphism over the core. Example: `lowering add { quote { ${a: int} + ${b: int} } -> ir { add ${a} ${b} } }`. `ir { … }` is a quote of IR, as `quote { … }` is of code. Typed holes choose by layout. Rules compile into native code by the same generator that compiles meanings, with no dispatch at run time.
2. **The IR is target-neutral.**
   - **Shape:** layout-typed, structured (regions, never gotos, so C and wasm need no structuring pass), columnar like the tapes, and content-addressed per unit.
   - **Units:** a unit is lowered once per layout signature; it is stored in the frontier-incremental store, so a body edit relowers one unit; and identical IR is one unit.
3. **Optimisation is rewrites too.**
   - **Equality saturation (egg, Cranelift aegraphs):** proven `law`s and case-of-case run over an e-graph of the IR, with extraction priced by the target's own costs.
   - **Perceus:** reference counting placed precisely, with reuse in place.
4. **A target is a declared template per instruction.** `target c { ir { ${d} = add ${a} ${b} } -> c { ${d} = ${a} + ${b}; } … }`. Its body is a foreign-language body with holes, which Avra already has. LLVM's arms call the LLVM API; the interpreter's arms evaluate, compiled into one direct-threaded dispatch. Patterns may cover several instructions, chosen by tree-pattern matching with dynamic programming (BURS, iburg): optimal tiling by declared cost.
5. **C is a target, and the C templates are the stencils.**
   - **What C buys:** readable C over the existing C runtime, so any C compiler and any platform (embedded too) can build it.
   - **Stencils from the same text:** each instruction's C template, compiled once with its holes as relocations, is that instruction's copy-and-patch stencil. One declaration gives a C backend and a millisecond dev backend.
   - **LLVM stays** the native, optimising path, and parallelism and laws go through it as decided on 09-22. C is an additional target, never a detour.
6. **Proof, per stage.** Each target runs the same program tests: interpreter == LLVM == C == wasm == `.expected`, the expected output being the oracle (agreement alone isn't correctness). `--lowered` holds the IR to the old lowering until the switch.

**Order:**
1. Step 1, building now: `Layout`, a hand-written core lowering, and the `--lowered` receipt.
2. The `lowering` component and the `ir { }` quote; step 1's rules become declarations.
3. Every core form, then the interpreter and LLVM reading layouts.
4. Program tests through the new path.
5. Generators, then the switch.
6. `target c` and its stencils.
7. Perceus and the e-graph.

**How it keeps the codebase self-contained: an hourglass with the IR at the waist.**
- **Features are verticals.** Each feature directory holds its grammar (`mod.av`), its typing rule (`checks.av`), its meaning if it is sugar (`meanings.av`), and a `lowering` only if it is one of the ~15 core forms. Most features never lower at all.
- **Targets are horizontals.** Each target is one file over the curated IR, and knows no feature.
- **`collect` gathers every declaration**, so a feature joins with no edit elsewhere.
- **A new feature costs** a grammar, a typing rule and a meaning, and it runs on every target.
- **A new IR instruction is a core event.** Every target refuses to build until it has that instruction's arm.
- **A package's own `syntax` declarations** get meanings the same way, so user-defined sugar lowers to every target too.

**Beyond, proposed (the owner to choose what leads):**
1. **Every rewrite proven when it is written.** A meaning, a lowering arm or a target template is a small declared pattern, so each is checked once at its definition against a definitional interpreter of the core. The check uses the laws design's discharge ladder: exhaustive at compile time over small domains, then generated cases, then a solver. A rule that miscompiles is refused with a counterexample. This is only possible because every rule is declared.
2. **The Futamura projections.** The interpreter is a declared target, so partially evaluating it on a program is compiling that program. Compile-time evaluation, generators and code generation become one mechanism, and the compiler builds itself by specialising its own interpreter.
3. **A compiler that learns, safely.** A background superoptimiser searches hot units for cheaper IR, proves each find equivalent by rule 1, and publishes it to the content-addressed cache. Every machine sharing the cache gets the faster code, and none can get wrong code.
4. **Live programs at native speed.** Units are content-addressed and called through a slot table in dev. An edit relowers one unit and swaps it into the running process. A changed type's layout difference derives its state migration, so state survives the edit.
5. **Parallelism and GPU from purity.** The `Reach` column already says what is pure. The lowering forks pure subtrees, such as a large `map`, where the target's cost model says it pays, on a work-stealing pool. A `target nvptx` is one more template file, through LLVM as decided on 09-22.
6. **Omniscient debugging.** The interpreter target records cheaply, and `avra why <value>` answers which inputs, rules and instructions made it, as a query.

**Step 1 built (8ae128b1):**
- **The pieces:** `Layout` (core/layout.av); `lowered_fn` over the elaborated core through `Lowers`/`StmtLowers` rules in each feature's lowers.av, against a `Lowering` context (core/lowering.av); the elseless `if_else` arm.
- **The receipt, `tapes --lowered`, 0 differing:** std-text 15 of 72 fns lowered whole, std-program 48 of 556, cli 55 of 734. It was witnessed failing on two planted bugs.
- **Two divergences cut and counted, both needing whole-program facts:** the cancel test after a call that may reach a cancel point, and the scheduler's tick.
- **Not lowered yet,** in order: lifts at seats, method calls, record literals and fields, enum matches, `let … else`, comprehensions, bodies, generic fns by layout.
- **Next:** those forms, then the declared `lowering` component.

The work continues in a fresh Fable session from `.lead/HANDOFF_FABLE_2026_11_10.md`.

**Approved by the owner 2026-11-10: all of it** — the tower (meaning, lowering, target), the four spellings below, and all six ideas above. Build order:
- **A. The switch:**
  - step 1, the core lowering and its receipt;
  - step 2, the `lowering` component and `ir { }`;
  - every core form, and the consumers on layouts;
  - program tests through the new path;
  - generators on the new layer;
  - the switch, deleting the old typer, lowering and registry.
- **B. Targets:** the `target` component; the interpreter and LLVM as declared targets; `target c`; stencils from its templates as the dev backend.
- **C. The six ideas:** (1) proven rules, then (4) live programs, then (2) Futamura, (3) the learning superoptimiser, (5) parallelism and GPU, and (6) omniscient debugging.
- **Alongside:** slice 1's typed holes, `@example`, inversion and the one compiled matcher, each where it first pays (the matcher when meanings number in the dozens, `@example` with the first declared lowering).

**Spellings (approved):** `lowering` and `target` as arms components; `ir { … }` as a quote of IR; `c { … }` as a foreign body.

**Approved by the owner 2026-11-10 (second session):**
- **`ir { … }` text is the IR's existing printed syntax** (`ir_text.av`, what `tapes --lowered` prints), with `${holes}`: one IR syntax, printed and parsed.
- **An interpreter arm's right side is a `quote { … }` of Avra** over the machine's state (`regs`, `cells`, `pc`): `ir { ${d} = ${a} + ${b} } -> quote { regs[${d}] = regs[${a}].plus(regs[${b}]) }`. This is what later makes the Futamura projection fall out.
- **Order changed for the interpreter only:** it is built as the first declared `target` now, not ported to `Layout` first and declared after the switch. LLVM and the memory pass still port to `Layout` by hand first.
- **`for` loops keep their meaning.** The meaning can't match the old walk instruction for instruction, so those fns are counted apart in `tapes --lowered` and proven by running programs.
- **Three whole-program facts the new layer lacks:** whether a call can reach a cancel point, whether a loop needs a scheduler tick, and whether a method writes its receiver. One survey over the call graph answers all three; mutually recursive fns are grouped and answered together, since the engine refuses cycles.

**Slice 2 progress, 2026-11-10 second session (`program` a2c4c03d), `tapes --lowered`, 0 differing:** std-text 55 of 72 fns whole, std-program 281 of 556, cli 570 of 743. Lanes: `avra-ho` (program), `avra-ho-b` (program-b), `avra-ho-c` (program-c, the `ir { }` quote and `target`).

## Last, after everything else: a generated parser

Owner decision 2026-11-06: agreed to do, and last.

- **Goal.** Generate native parser code from a grammar at build time: one function per rule, tokens matched by number, no lists of labels. It stays generic for any language. The aim is cold on one core, now about 30k lines/s.
- **Estimate.** 3–5 days, reviewed from the engine's size and shape, not from reading all of it. The 10–30× gain is a guess until the probe measures it.
- **First step, half a day.** Generate one rule family by hand and measure it. Stop there if the gain is small.
- **Why not tune instead.** Allocation and reference counts are 35% of parse time, so removing all of it gives at most about 1.5×.
- **Hard parts.** Identical error messages and recovery, because exact-output tests pin them. LLVM's compile time on large generated functions, unmeasured. The tree-walking engine stays for grammars assembled at runtime, so both must agree.
- **Proof.** Run both engines over the real tree and compare trees and errors; any difference is a named bug.
- **Comes after the syntax layer.** A generated parser then writes the tape directly, and rollback is cutting the tape short.

## Measured 2026-11-10, end of the second session (`program` 439f5db9)

**Steps 1 to 5 of the switch each have a working slice, every one held by a receipt witnessed failing.**

| Receipt | std-text | std-program | cli |
|---|---|---|---|
| `tapes --lowered` free fns whole | 64 of 72 | 442 of 556 | 713 of 776 |
| methods whole | 2 of 2 | 243 of 302 | 52 of 68 |
| trait defaults | n/a | 16 of 16 | 3 of 3 |
| generic units whole | n/a | 72 of 84 | 91 of 186 |
| differing | 0 | 0 | 0 |
| `tapes --signatures` typed | n/a | 9350 of 9425 | 16113 of 16113 |

- **`tapes <dir> --ran`** (a program test built through the new path, run in the evaluator and natively, held to `.expected`): 370 program tests under `features/*/tests`, 122 made on the program layer, 122 printing their `.expected` in both engines, 0 failing.
- **Consumers on `Layout`:** the memory pass, the LLVM emitter and the interpreter read each register's layout; the compiler built through them is byte-identical. Two reads still need a language type: the census label and the NUL guard's "is this exactly `string`".
- **Generators:** `@derive(Saved)`'s declarations stand on the new layer through `compiler/generator_seam.av`, which runs the generator in the old evaluator and is deleted at the switch. `@query`, `collect enum` and the rest are not done.
- **Declared targets (`program-c` ee8caba9, not merged):** `ir { }` as a pattern over `Ins`, `component target`, and a `target interp` of 15 arms; 8 of 8 tests. The printed IR is ambiguous in two places (`Call`/`CallRt`, `RetVal`/`Ret`); the dispatch a declared target replaces is about 175 of the interpreter's 4,549 lines.
- **Whole-program facts:** whether a method writes its receiver is `receiver_use` (one query, a visiting set inside it). The cancel test and the scheduler tick are still cut and counted; 39 program tests wait on them (`spawn`).

**Open, found this session:**
- **The memory pool never gives slots back** until a run exits (`runtime/avra_pool.c`); a test run held 6.9 GB of 9.6 GB while using 475 MB. A fix is parked at `.lead/pool-release-wip.patch`; its check passes but was never witnessed failing.
- **`tapes --signatures` counts an unresolved name as differing**, but that comparison was never witnessed failing (needs a package whose derive comes from another package).
- **Old-lowering defects recorded, to fix at the switch:** a retain of a nullable foreign pointer; a thaw emitted on a plain word; a write lost through a non-pointer value below `self`; a guard on a match's last arm never evaluated; an error passed between different error unions; the NUL guard skipping `string?` and named strings; a value enum laid out differently in a list than in a record.
- **`let … else` and `for i, x in xs` cannot be declared meanings yet:** the quote matcher has no name seat at those binders (`avra-8sb5.10.201`).
- **A build's `keep` phase and the 2.5-minute `make try`** are the old workspace's cost; a cold build in a new worktree reuses nothing from the shared cache.

## Approved by the owner 2026-11-11: the gate is running, and one number drives the work

**Decided, to shorten the path to the switch:**
1. **Matching the old lowering instruction for instruction is no longer a gate.** `tapes --lowered` stays as a diagnostic: a `differs` line is a place to look, never a blocker by itself. Correctness is judged by running: program tests through the new path against `.expected` (`tapes --ran`), then the compiler built through the new path building itself and passing its own receipts. A lowering that differs because the old compiler has a rule the new design does not (a record boxed because some `mut` seat writes it; an over-reported cancel test; a shape a meaning states otherwise) is counted apart by its reason, and is not matched.
2. **One burndown: every body the compiler's own program reaches that the new path cannot build yet,** ranked by cause. It is `made_reaching` over `packages/cli`'s entry with its `missed` list. Every lane takes a slice of that list; work that is not on it stops (the tail of the three small packages, program tests the compiler's own code does not need, old-quirk matching).
3. **Also decided this session: switch first, declare after.** The hand-written lowering rules are converted to the declared `lowering` component after the old lowering is gone, with no parity constraint.

**Measured 2026-11-11 on std-avrac (lane C; not rerun by the lead):** typing 273958 of 277377 nodes (98%); `--generators` 28 written, 23 made, 138 of 177 sites failing; `--lowered` on `src/core/` alone 649 of 800 fns and 647 of 1027 methods whole, 70 differing (about 49 a record of truths the old registry boxes, 20 a generic instance's symbol). The full `--lowered` cannot finish: `surveyed` (`compiler/item_writes.av`) reads a whole impl back per reached method, unsaved. Largest untyped causes: methods on a `dyn` value in `@computed` builders 520, `.of` on the named type `Scoped` 470, a type literal at a `TypeLit` seat 333, `@derive(ValueProtocol)` projections 292, a match over the collect enums `Expr`/`Stmt`/`Pat` 276, their variant literals 183.

**The memory pool gives slots back** (`program` 233b1a90): a measure counts the bytes being taken; a free past the low mark and a run about to spawn give back what the run no longer fills. `make pool-check` holds 5 cases and is not wired into CI.

## Approved by the owner 2026-11-11: `select` is a declared meaning over `Waitable`

- `@std/task` gains `trait Waitable<T> { fn ready() -> bool; fn taken() -> T; fn filed(arm: int) }`, implemented for Task, List<Task>, Source, `.ended` and timers over the existing wait rows.
- `select { … }` is a meaning: test each arm's `ready()` in order, bind `taken()`, run the body; else file every arm and rest. `@fair` is a second meaning. The old 454-line lowering is not ported.
- State at approval: `program` 27e95f40; burndown 34 not yet of 39,571; `avra rules` runs from the new-path-built cli; `avra check` hits a miscompile ("unwrapped an absent value") lane A is isolating.

## Sequencing decided 2026-11-11 (lead): `select` lands after the flip, before the old lowering is deleted

- The old typer refuses `impl Tr<T> for X<T>` (the trait's argument being the impl's own parameter) on any generic type, and a record holding a `Task` is `type.task_escape`. Both block `Waitable<T>` only while the OLD typer checks `@std/task`.
- So: flip to the new path first; then `impl Waitable<T> for Task<T>` / `List<Task<T>>` / `Source<T>` directly (no wrapper records), `select` as a declared meaning, `@fair` a second meaning; then delete the old lowering. Until then the cli's 3 `select` bodies and `@std/net` `raced` trap by name.
- Built before the flip because Select needs them and they are right anyway: the meaning splice fills nested templates through the generator splice's one definition; a meaning's names resolve at the meaning's origin; the new typer accepts `impl Tr<T> for X<T>`.
- Bridge already landed (f9259e60): `Task.filed(arm, member)` and `Task.since()` in the old tasks method table.
- Sugar backlog owed with the meaning: a template repeating a piece once per element of a run hole.

## Parked 2026-11-11: the one typing difference left in std-avrac (`collect_branches`)

- `features/lists/tests/collect_branches`: `plain` types node 379 `int`, the old typer `void` (an `if` statement inside `collect`). Diagnostic only; every collect test runs green on `program`.
- Two fixes tried and not landed (lane A's broke `view_arms`; lane C's 5c9abbff on `program-c3` reaches 0 differing and breaks 5 runs). The right rule: a collect gathers what a statement-holding node's branches leave (`core/gathering.av`), to be done when `collect` becomes a declared meaning.
- Build memory, measured and parked: one `make try` peaks ~5.3 GB because the old path holds its whole analysis to exit (no holder above 383 MB); not worth fixing in code the switch deletes. One build slot on the 16 GB Mac.

## Measured 2026-11-11 evening: where the switch stands

- `program` f21ee8b1: cli burndown 40,192 of 40,196 made; the 4 left are Select (after the flip). std-avrac program tests 320 of 457 made on the new path, 0 failing. A cli built by the NEW lowering runs `check` byte-identical to the old through `packages/cli` (88 s vs 128 s, 2.9 vs 4.1 GB; single samples).
- SEAM (lane A): no command runs through the program layer. `build`/`run`/`test`/`check` all call the old Workspace; the layer is reached only via `tapes`. The new typer answers types only and speaks no refusal: of `check packages/cli`'s 2,589 lines (328 findings: 98 `type.*`, 230 rule findings) it can produce 0.
- Staged flip: (a) `AVRA_PROGRAM=1 avra build` through `made_program` (switch written, ~40 lines, unbuilt); (b) `run` (small) and `test` (suites on the layer, not started); (c) `check` — the long pole; only (c) lets the old typer be deleted.
- DIAGNOSTICS STUDY (lane C, read-only): 283 kinds registered (138 `type.*`, 34 `resolve.*`, 30 manifest, 17 annotation, 16 flow, …); 83 rules, 70 syntax-only. Recommended: hybrid by family, each law a query answering `Finding` rows (`diagnostics(item)`), voices re-seated on `SignedType`, old code deleted per family at a filtered byte-identical gate; an adapter over `Analysed` is a second copy of the database and is refused. Estimate 18–27 rounds. Proposed to the owner, not approved: a `law` component (kind + fact query + voice + witness in one declaration) and a table for the seat/argument family.
- Program tests not made (137), by cause: `T??` element absence ~15, a program's own `collect` ~13, Select 10, writing method on a flat record/`state` field 10, hole over a named/non-scalar type ~8, dyn box over inline value 5, `string.chars` 5, long tail ~45.

## Approved by the owner 2026-11-11: the `law` component, and "find other cases aggressively"

- `law` (kind + fact query + voice + help + witness in one declaration, shaped like `rule`) is approved; the kind registry row and the witness table are generated from it. Stage 0: `Finding` rows and `diagnostics(item)` on the program layer; first laws `registry_hole` and `parse.*`; gate is byte-identical `check` output filtered by kind.
- Owner, verbatim: "really find other cases for this type of idea/port. Good work. Do that aggressively." Lane C sweeps every remaining port for hand code one declaration could replace (verb meanings, typed tables generated from the prelude's `verbs/*.av`, diagnostic projections, commands as thin queries, suites as a meaning, IR/targets) and ranks them; new language features still go to the owner with a code example first.

## Declaration sweep 2026-11-11 (lane C), ranked — what one declaration can replace

1. `law` (approved; per law, kind as shared key) — ~2,600 lines: 261 kind rows, witness table, remedy table, coverage scraping.
2. Prelude verbs ARE the verb table (`@row`, `@shape`, `@walk`, `@stage`, `@lends` marks on `verbs/*.av`, compiler tables a `collect`) — own_rows/own_shapes/walk_rows/lending + the old MethodRow copies. Open: collect across packages, seat types in a mark's row.
3. Verbs as prelude bodies — `removed_at`, `Map.entries`, `is_empty` today; walks need lambda-argument inlining and a stage declaration for fusion (new features).
4. `OwnType` via `@derive(Words)` + marks (derive moves std-ui → std-meta; approved by lead as a relocation).
5. IR consumers derived from role marks on `Ins` (~250 lines; two fact fns already disagree: `view_source`, `immortal_dst` in memory.av vs soundness.av).
6. Commands as `command` declarations + a `baseline` component (~350 lines).
7. Specs as components gathered by `collect`, run by @std/testing (~400 lines + hand IR entry) — needs string-named instances and `collect` over fns/cases (owner).
8. Seat/argument mismatch as one law over `Refused` rows. 9. `RtHost` generated from runtime rows. 10. `avra_box.h` generated. 11. Memory/soundness brackets from role marks. 12. Stmt projections by payload-mark derive. 13. DeclKind/ItemKind words.
Not declarable: per-instruction meaning in interp/LLVM, fusion machinery (until stage declarations), row choice by layout.

## Approved by the owner 2026-11-11 (night): do ALL of the declaration sweep; explore new language features that help

Owner, verbatim: "A and b. And yes unblock yourself in the collect thing. I love what you're doing!! … I'd love to do all of them. Also continue to push with this. And if there are new language features that help feel free to explore to. Make sure all this is documented in the plan."

Standing rule from this: when a port reaches hand code that one declaration could own, build the declaration. New language features that remove hand code may be explored and built; each is shown to the owner as a terse code example in the report that lands it (not asked first), and recorded here.

Approved new features:
- `collect` exposes a fn's seats: `seats: it.params` (unblocks the prelude as the verb table).
- Component instances named by a STRING, and `collect` over fns/cases (specs as components).
- Lambda arguments inlined at the call (`inline fn(T) -> U` seat) and stage declarations (`@stage`) so fused walks are prelude code.
- `@derive(Words)` lives in std-meta.

The thirteen, as proposed shapes (a lane probes the exact spelling before building; these are sketches, not verified syntax):

1. law — one declaration per law, kind as shared key
   `export law registry_hole for "type.registry_hole" { reads: answering_holes(item)  warn h -> "… ${h.hidden.join(", ")}"  help: "…" }` + `@witness("…")`
2. the prelude IS the verb table
   `@row("avra_str_len") fn length(s: string) -> int {}`  /  `collect own_rows: List<OwnRow> = @row in closure as OwnRow { verb: it.name, mark: it.mark, seats: it.params }`
3. verbs as prelude bodies
   `fn removed_at<T>(xs: List<T>, at: int) -> List<T> { xs.slice(0, at).concat(xs.slice(at + 1, xs.length)) }`
   `@stage fn map<T, U>(xs: Walk<T>, f: inline fn(T) -> U) -> Walk<U> { for x in xs { yield f(x) } }`
   `fn any<T>(xs: Walk<T>, f: inline fn(T) -> bool) -> bool { for x in xs { if f(x) { return true } } false }`
4. built-in types from one marked enum
   `@derive(Words) enum OwnType { @word("int") @laid(Layout.Word) Int, @word("List") @laid(BoxKind.List) List, … }`
5. IR consumers from role marks
   `enum Ins { @tag(3) @word("call") Call(@dst Reg, Symbol, @view List<Reg>), @bracket(Open) IfStart(Reg), … }` → `ins_words`, `remapped`, `same_ins`, text lines derived
6. commands
   `command ir { phase: "lower+emit", act: ir_of, flags: [time, json] }`  /  `baseline idioms { file: "tools/idioms.baseline", key: it.site }`  /  `collect commands = command in package`
7. specs as components
   `spec "a map keeps insertion order" { given m = { "b": 1, "a": 2 }  then m.keys().join(",") == "b,a" }` — an ordinary component, gathered by `collect`, run by @std/testing
8. seat/argument mismatch as one law
   `export law seat_mismatch for "type.mismatch" { reads: refused_seats(item)  error r -> "`${r.seat}` wants `${r.want}`, found `${r.found}`"  fix r -> r.conversion }`
9. runtime host generated from the rows
   `@derive(Hosts) const RT_SIGS = table<RtSig> { … }` → `RtHost` and typed `Lowering.<row>()` generated
10. the C box header generated
   `@c_header("runtime/avra_box.h") type ArrayBox = { len: int, cap: int, cells: ptr }`
11. memory/soundness brackets read #5's `@bracket` role (one definition of opens/closes/turns)
12. statement projections by payload mark
   `Let(@named name: Plain, …)` → `let_name`, `type_decl_name` derived
13. kind words
   `@derive(Words) enum ItemKind { @word("fn") Fn, @word("type") Type, … }`

Owners: lane C — 1, 8, then `it.params` and 2, 4, the three bodies of 3. Lane A — the `build` switch, then 7 (it is stage (b) `test`). Lane B — test side, then the walk half of 3 (inline lambda seats, `@stage`). Queued: 6 when `check` moves, 5 + 11 when the IR is next touched, 9, 10, 12, 13 opportunistic.

## Owner refocus 2026-11-11 (night): the switch first, `build` first

Owner: "focus on the ones that get us to switch faster. The rest can be done after." and agreed to switching `build` first.
- ON the path: (A) `AVRA_PROGRAM=1 avra build` through the program layer, not-made bodies as trapping stand-ins (the 4 Select bodies), true fixed point, cold/warm/one-line-edit timings; then `run`; then `test` via specs as components (#7). (B) program tests through the new path, by cause. (C) `law` and the diagnostic families (#1, #8) — the long pole of moving `check`.
- AFTER the switch: #2 prelude verb table and `it.params`, #3 verbs/walks as prelude code (`inline fn` seats, `@stage`), #4 `OwnType` words, #5/#11 IR roles, #6 commands, #9, #10, #12, #13, Select as `Waitable<T>`.

## MILESTONE 2026-11-11 20:30: the compiler builds itself through the program layer (`program` 4044773e)

- `AVRA_PROGRAM=1 avra build <pkg>` parses, types and lowers on the program layer (`built_binary` → `program_built`); not-made bodies become trapping stand-ins and are listed (3, all Select: dev.av `Page.watching`/`Page.clocked`, @std/net `raced`).
- Lead's own run: `AVRA_PROGRAM=1 build packages/cli` exit 0, 182 s, 1.98 GB peak; the product's `check` on std-text and std-program byte-identical to the old-path compiler's.
- Lane A's chain (single samples): p1 (new path) → p2 (new path, built by p1): identical but for 1 byte, the file name inside the ad-hoc signing identifier. p1 `check packages/cli` 93.8 s / 2.7 GB vs 141.3 s / 4.0 GB.
- Build timings, old path vs program layer: cold 138 s / 2.7 GB vs 178 s / 2.1 GB; warm no-op 126 s vs 130 s; warm one-line edit 158 s vs 144 s. The saved store works (0.1 s of queries on a no-op, 7.7 s after an edit); ~130 s is redone outside every query: whole-program walk + memory pass, `emit_object` over ~40k bodies uncached, the link, `linked_words` building an old Workspace.
- NEXT (lane A): emitted objects cached by lowered digest in the shared CAS, walk/memory pass as queries, `linked_words` from manifests; gate is a byte-identical product; target warm no-op in seconds.
- Bug found by the self-build: an arm binder named by a hole captured the template's own read (`.RetVal(r) -> same_reg(r, r)`), so the self-built compiler copied on every borrow (bea284c3).

## Measured 2026-11-11 21:30: warm builds after lowering became a saved query (lane A, 7d9db304, not yet landed)

- `AVRA_PROGRAM=1 build packages/cli`, single samples: cold 188 s; warm no-op 36 s (was 130; old path 126); one-line edit in core/lowering.av 48 s (was 144; old path 158). Products byte-identical to cold builds.
- Remaining warm no-op: walk + memory pass 15 s, emit 10 s, link words 9 s. Next: memory pass per body, `linked_words` from manifests, objects in the existing bitcode-keyed buckets, `collect_members` (8 s after an edit).
- Answers are keyed per query by `code_hash` (the query's own code and what it calls), so a rebuilt compiler re-asks only queries whose code moved.
- Lead's cold profile (50 s sample of `--built`, top of stack): 48% allocation/refcount/copies, 14% decoding saved answers, 3% hashing. Lane B owns cold: census by caller, top five causes, target the 113 s typing+lowering walk under 60 s.
- `program` f7fcccab: std-avrac program tests 368 of 461 made, 0 failing (one native run failed once under load in the lead's first run and passed on rerun — a flake to watch); written flat seats are handed their place (core/written.av).

## Measured 2026-11-11 22:00: cold speed, batch 1 (lane B, `program` f3af06ed)

- Census of `tapes packages/cli --built` before: 5.9 G retains, 8.35 G releases, 2.45 G boxes, 23.2 G list reads. Top causes: (1) every ask re-encoded its arguments, hashed the question and DECODED the saved answer into fresh boxes; (2) `filed` copied the found list per body; (3) `sourced_symbol` untaped every item per literal; (4) identity/fingerprint folds building lists to hash; (5) small `List<int>` boxes.
- Fixed 1–3: the `@query` wrapper holds a decoded answer per answer hash (`once fn <q>_held()`; the read is still recorded; answers holding a Cell are never held; `AVRA_HELD_ANSWERS_OFF=1` turns it off); `filed` pushes in place; `written_sites(file, kind)` query.
- Lane B, cold, same tree: `AVRA_PROGRAM=1 build packages/cli` 128.3 s → 80.2 s (old path cold ~138 s), peak 1.81 → 2.18 GB; `--built` 110.6 → 86.3 s. Memo on vs off: byte-identical product. Lead's run of `--built` on a kept store: 55 s (was 116–123 s on the same kind of run).
- Still owed: argument re-encoding per ask (octets + blake3) — a question memo keyed by the arguments' own values; causes 4 and 5. Target: the walk under 60 s cold.

## CORRECTION 2026-11-11 22:20: the "cold 128 → 80 s" entry above is WRONG

- Lane B's method was confounded: the program layer's store for the cli lives in `packages/cli/.avra-cache` and each std package's own `.avra-cache`, not only the tree root's; only the root's was cleared. The "before" reused every answer; the "after" ran on a just-filled store. The lead's own "55 s" `--built` was a kept-store run and proves nothing about cold.
- Re-measured, every `.avra-cache` in the worktree moved aside before EACH run, both binaries built the same way: `--built` cold 84.2 → 78.6 s (walk 78 → 74 s); `AVRA_PROGRAM=1 build packages/cli` cold 112.5 → 110.1 s; peak ~2.7 GB. Batch 1 is ~7% on the walk, ~2% on the build. Decode-once helps repeated reads, which a cold run barely has. The memo-on/off byte-identity still holds.
- A COLD MEASUREMENT CLEARS EVERY `.avra-cache` UNDER THE WORKTREE (`find <worktree> -name .avra-cache -type d`), before each run. Lane A's cold/warm table has not been re-checked against this.
- Cold is NOT fixed: new path cold build ~110 s (old path ~138 s by lane A's sample, itself unverified under this rule). Lane B is re-profiling the cold walk with full call trees before changing anything.

## Corrected build table 2026-11-11 22:40 (lane A, 7d9db304; every `.avra-cache` under the worktree moved aside before each cold; single samples)

| run | wall | CPU | peak | note |
|---|---|---|---|---|
| old path cold | 188 s | 255 s (parallel object workers) | 3.5 GB | waited on the pool |
| old path no-op | 199 s | 116 s | 3.3 GB | waited on the pool |
| new path cold | 611 s wall (≈420 s waiting on the pool) | 186 s | 2.6 GB | |
| new path no-op | 35 s | 35 s | 2.3 GB | no wait |
| new path one-line edit | 48 s | | | old path 158 s from a partly warm store |

- The old path's earlier "cold 138 s" ran warm (its store is the tree root's `.avra-cache`, which was not cleared). The new path's colds were cold (its store is `packages/cli/.avra-cache/tapes`).
- Warm before/after for lowering-as-a-query stands: no-op 130 → 36 s, one-line edit 144 → 48 s, same binary, same clear.
- WALL TIME ON THIS MAC IS POLLUTED BY THE MEMORY POOL WAIT whenever another lane builds; compare CPU, or measure with the other lanes idle. Cold CPU: new 186 s (single-threaded) vs old 255 s (parallel workers).

## Measured 2026-11-11 23:20 (`program` b0544bf0): warm builds after steps 1–3 (lane A; all `.avra-cache` aside before colds; no pool wait; single samples)

| `AVRA_PROGRAM=1 build packages/cli` | wall | peak | old path (strict) |
|---|---|---|---|
| cold | 124 s | 2.3 GB | 188 s |
| warm no-op | 19.8 s | 1.8 GB | 199 s |
| one-line edit in core/lowering.av | 27.4 s | 2.1 GB | 158 s |

- Step 1 lowering as saved queries; step 2 trap closing in two walks (memory pass is 0.8 s, per-body query skipped); step 3 link words from the manifests (`LinkWorld`, `manifest_link_words`, one definition with the old Workspace; `tapes --link-words` gate: cli 90 words, std-http 9, std-sqlite 7, identical).
- No-op remaining: emit 10.6 s, program made 7.1 s. Next: objects through the bitcode-keyed buckets + the kept binary; `collect_members` after an edit.
- Cold (lane B, 60d4146d, not yet landed): read-back items held per process — an `impl` is one item and each method's lowering re-read it; cold build 133 → 100 s, walk 86 → 61 s, peak 2.1 → 2.9 GB (bound being tuned). Next: question memo for argument encoding.
- After the flip: typing and lowering bodies across cores (bodies are independent once signatures are known).
- Disk: owner cleared for good the question of caches — clear and report, never ask; Spotify's app cache cleared (8.7 GB) on the owner's yes.

## Measured 2026-11-12 00:20 (`program` 6b0d16ad): warm builds after steps 4–5

| `AVRA_PROGRAM=1 build packages/cli` | lane A | lead's own run | old path (strict) |
|---|---|---|---|
| cold | 122 s | — | 188 s |
| warm no-op | 12.5 s | 14.0 s, then 11.0 s | 199 s |
| one-line edit in core/lowering.av | 13.5 s | — | 158 s |

- Step 4: objects through `bucket_objects` (one definition, both paths), made only where lacking; the binary kept under a digest of object keys + link words + the runtime archive; `Body.home` hashed before the name so an edit moves its own file's bucket (edit emit 13.0 → 0.3 s). Step 5: `collect_members` reads `file_marks`, one saved query per file. `made_reaching` pushes in place.
- No-op remaining (CPU): program made 6.7 s, bitcode for 31 modules ~3 s, startup ~1 s. Possible structural step: a saved query answering the bucket keys so a no-op skips the walk; trade to be brought to the lead first.
- Lane B's cold work (e0b28295: walk 58 s, build 94 s cold) is merging onto this; its first combined table is pending.
- KNOWN RISK surfaced by lane B's sweep: program tests in 11 OTHER packages have FAILING runs on the new path (wrong output, not merely not made); std-relation 6/42, std-http 10/55, std-ui 4/74 made. Failing runs outrank not-made tests; the default flip of `build` waits on them.

## Recorded 2026-11-12 01:30

- OLD-COMPILER DEFECT (not copied): `check` drops the warnings of a dependency file reached only through a FILE-module import — `reaches_file` (compiler/record.av) compares the import's file-module name with the file's DIRECTORY module (`module_of`), so `check packages/cli` prints none of @std/http's 18 findings (cli imports `@std.http.fetch` etc., never `@std.http`). The program layer's `program_files` reports them; the findings gate compares outside @std/http.
- OLD-COMPILER DEFECT (not copied): a nullable scalar as a map value (`Map<string, int?>`) is handed to `avra_map_set` as the raw pair, not a box.
- REGRESSION AND ITS LESSON: 6b0d16ad (`collect_members` reading `file_marks`) dropped GENERATED members, so a compiler built by the new path could not run the new path; unnoticed ~2 h because no lane re-ran the second generation. STANDING RECEIPT for every sha: P1 builds cli with `AVRA_PROGRAM=1` → P2 → P3; P3's `check packages/std-program` byte-identical to P1's.
- LINT RULES (lane C, f7863bd2, pending landing): `rule` takes `Syntax`, `fact_rule` takes `Code`; the typer classified them — 70 syntax, 13 fact. `rule_entries()` holds both; the program layer runs the 70 over each file's whole read-back store. Gate identical on std-text (1), std-program (10), cli (154).
- THE NEW TYPER HAS NO AGREEMENT STEP: `Checking.check(e, expected)` hands `Expected.Exactly(want)` down and nothing compares the node's type with it. So under `AVRA_PROGRAM=1` an ill-typed program is not refused by typing at all — it is only safe behind the old `check`. Stage plan for `Refused` rows (lane C): (1) one `accepts` door in `check` after `made`, recording `Refused { at, want, found, seat }`; `Expected.Exactly(ty, seat)` — 37 planting sites, each mapped to its old voice (arguments, conditions, arms, lambda answers, bindings, assignment, return/body, fields, payloads, elements, map key/value, bounds/index, catch arm, within, operands); (2) `law seat_mismatch` keyed on `Seat`; (3) the conversions (`text`, `[x]`, `x!`, named wrap) re-seated on `SignedType` — the bulk; (4) count rows (`Miscounted`). Gate: old voice witnesses, one per seat; type spellings must match the old `name_of`.
- Combined speed table (lane B branch a08f6fcb, both lanes' work): cold build 70 s, warm no-op 8.9 s, one-line edit 8.0 s.

## 2026-11-12 01:50 (`program` 53112fe6): the lanes build the compiler through the program layer

- Regression fixed (f11a1a04 `generated_marks`; witness `features/collects/tests/generated_member`). A second fixed-point break found by the same receipt: the program layer's link only dead-stripped, so a new-path-built compiler lost the C fns its evaluator calls by name — both links now share `native_link_head` (53112fe6).
- LEAD'S OWN RUN of the fixed point on 53112fe6: P1 → P2 (100 s) → P3 (103 s), each listing only the 3 Select traps; P3's `check packages/std-program` == P1's (106 lines).
- `tools/program_traps.baseline` (idiom baseline's format, one reader, only shrinks): an `AVRA_PROGRAM=1` build under a tree holding it FAILS on a stand-in trap it doesn't list. Rows: dev.av `Page.watching`, `Page.clocked`, @std/net `raced`. Every program-layer refusal ends with the `build/avra check <file>` that explains it.
- LANE PROCEDURE (builder = lane A's 53112fe6 product, installed in avra-ho, -b, -c, -d): iterate with `AVRA_PROGRAM=1 make try` (~95 s cold, ~15 s after an edit, <2.5 GB; old path 151 s / 5 GB); `program.trap`/"doesn't build this program yet" → run the printed old-path `check`; a new-path-built `avra-try` loses positional args of `test`/`fmt`/`tasks`/`db` until the nested-child fix lands (use `./avra`); BEFORE REPORTING A SHA one plain old-path `make try` (the only type check — the new typer has no agreement step), then receipts incl. P1→P2→P3.
- OPEN MISCOMPILES (lane B2): a component instance's nested child instance is dropped (`command c { arg file {…} }` → 0 args; std-cli `cli`); std-ui `echo` (a component in an imported module not found). Harness gap: `tapes --ran` links no package C (14 tests).

## 2026-11-12 02:55: memory-pool deadlock between two old-path builds (defect in runtime/avra_pool.c, not fixed)

- Two old-path `build packages/cli` runs (lanes A and C) each took part of the pool (20 and 18 of 38 slots), then each waited for more; neither refused after AVRA_MEM_POOL_WAIT_MS=420000; a third lane's processes waited for a first slot behind them. 12.5 minutes lost by three lanes. The lead found it with `lsof` on `$TMPDIR/avra-pool/slot-*` and stopped one build by its checked pid.
- Rule until fixed: old-path builds never overlap (check with `pgrep -fl "build/avra build packages/cli"` + cwd); iterate with `AVRA_PROGRAM=1 make try` (2 GB). The fix belongs in the pool: a holder that cannot grow within its wait must release and re-queue (or refuse), and a waiter must be able to see who holds.
- `program` 27476fea: lint rules on the program layer (70 syntax rules; 13 `fact_rule`s stay on `Code`), findings gate identical on std-text 1, std-program 10, cli 154; fixed point green on lane C's tree.
- Lane A measured: a compiler BUILT by the new path reuses none of its saved answers (code-hash bodies are absent stand-ins) — builder must stay an old-path product until the program layer computes code hashes; fix in progress, with a failing build (not an empty hash) when a hash cannot be computed, and P2's warm no-op in seconds as a new standing receipt.

## 2026-11-12 03:20: the machine cache crosses worktrees (old-path defect) — lanes isolated; 27476fea re-landed

- Lane C: 27476fea fails an old-path build with worktree caches deleted but `~/.avra/cache` left (4 parse errors at `export fact_rule …`), and builds from NOTHING with `AVRA_CACHE_DIR` pointed at an empty directory (exit 0). Cause: the machine pack is shared by every tree whose compiler has the same print; the lead had installed ONE builder in all four lanes, so a lane's build read another lane's `features` module record (no `fact_rule`) and `line_words` → `module_names_block_word` answered from it. The old path trusts a record another tree wrote for the same module name.
- So "delete `.avra-cache`" was never a cold build. COLD = every `.avra-cache` under the worktree deleted AND `AVRA_CACHE_DIR` set to an empty directory.
- Rule: every lane runs every compiler command with its OWN machine cache — `export AVRA_CACHE_DIR=<worktree>/build/machine-cache` — so no lane reads another's answers. Earlier cross-lane oddities (and possibly false passes) may trace to this; receipts before this point were not isolated.
- `program` re-landed at 27476fea (lint rules on the program layer).

## Approved 2026-11-12 03:35: parallel work-ahead by forked workers (lane D, stage 1)

- Facts: Avra tasks are fibers on ONE OS thread; refcounts are plain (not atomic); multi-core Avra exists only as PROCESSES (`@std` cores, fork, share nothing). The old path's "parallel object workers" are C pthreads in backend/llvm_wrapper.c and the new path already uses them. The new path already HAS process work-ahead: std-program/src/worked_ahead.av `engine_worked_ahead` (fork N cores, each answers `item % N == core`, publishes with `saved_alone`; parent merges and reads), used only for parsing by `tapes --program_only`. The store is built for many writers (immutable content-named packs, atomic rename, no lock); the parent accepts a child's answer only through `stands_now` (every read re-checked), never by name or print.
- Cold phase split (old-path-built compiler, 1 run, loaded machine): 104 s wall / 112 s CPU / 2.0 GB; program made 86 s (lowered_method_under 34.1 s self, lowered_under 19.2 s, parse 7.3 s, generators 6.3 s, receiver/survey/impl facts ~12 s incl.); emit 14.7 s (already pthread-parallel); bitcode 2.8 s; memory pass 1.0 s.
- Stage 1: `engine_worked_ahead` before `program_built`'s engine is made, over every declared body, min(cores, 4) workers, `AVRA_WORK_AHEAD_OFF=1`. Gate: product identical on vs off, both cold. Expected (Amdahl, lane D): cold 104 → ~60–65 s; ~50 s with 8 workers on an idle machine. Shared-heap threads are a runtime + language campaign, not now.
- Then: 1b parse/generator work-ahead; 2 wave-synchronous work-ahead inside `made_reaching` if the reached share is low; 3 emit (the keyed module handed straight to the worker).

## 2026-11-12 11:40 (`program` 188972d8, lane B2; verified by the lead: --built 41233/41237, std-avrac --ran 474 tests / 401 made / 0 failing, std-cli green, `--findings` no `once` trap)

- Landed (each with a witness seen failing first; cold isolated old-path build exit 0; P1→P2→P3 identical): nested named child instances join their `collect` (a `let` of a component instance); `tapes --ran` links/opens package C through `manifest_link_words`/`manifest_library`; generic units seat by name/default; calls through a type naming args; a template's copied names read at its home; MISCOMPILE fixed — a file's own private `const` in a match pattern was read as a binder; spread-field defaults; write evidence reads only a quote's holes; components cross to generators as Types (View derive made over 38 std-ui sites); a `collect` over an unmade generator is unknown and says why; `dyn` over an inline value (`<sym>$v` read-back entry); prelude verb BODIES (`string.chars`, take_while/drop_while/filter_map/flat_map/min_by/max_by/inserted, Map map/any/find_map/flat_map — plain fns, unfused: a perf follow-up); matches by `dyn` type, record fields, named shape; the runtime `once` table grows; `@owns` owners settled at scope end.
- OLD-PATH DEFECT, corrected diagnosis (lane C, fix 607fbb4c pending landing): no key crosses trees. The `use`-line block-word gate (`module_names_block_word`) trusted a module's persisted record without checking its files still hold the text it was written from; a component added later was no block word to a `use` naming it alone. Present since the Nov 10 standing binary. Per-lane `AVRA_CACHE_DIR` stays (isolation is still right) but was not the cure.
- OPEN, with rulings: (1) a declaration a MEANING mints (Format hoists, std-http `declared` 21) must be a program item of the file the instance stands in, declared through the same door as `generated_declares` — lane B. (2) a generated item's type names read at the generator's home (std-ui `SeatRow`) — same law as hole-spliced names, one more seat kind — lane B, on lane A's `read_from`. (3) std-ui's compiler-filled slots (`Site`, `Cells`, `Structural`, `Opaque`, `Words` — the reactive contract, 62 tests): PARKED until after `build` flips for non-UI packages (UI is on hold by the owner's earlier rule). (4) code hashes on the program layer: lane A's (febcabdb), not to be ported twice. (5) `@plans` planner as a declared meaning in std-relation (a rewrite of the comprehension head's source), after 1–2.
- Divergences for the type-agreement stage (new path accepts, old refuses): a `Code` in a quote's name hole (`type.quote_hole`); `fn(string) -> int` into a seat `fn(string) -> R?`.
- Machine events: the disk hit 0 (ENOSPC) around 04:10 and stopped lane C; all four lanes idle from ~06:20 to 11:30; shared `~/.avra/cache` (2.1 GB, unused since isolation) cleared by the lead.

## OWNER TARGETS 2026-11-12 ("That's really important"): warm edit under 300 ms, cold under 5 s

Owner, verbatim: "As for times, the warm edit needs to be done in less than 300ms. Cold in under 5s. That's really important." Also: "Please make sure to use Avra's features very heavily and to also propose creative solutions like this in the future."
Read as: building the compiler itself (≈220k lines, ≈41k bodies) through the program layer — the hardest case we have.

Where we are (single samples): warm one-line edit 13–17 s (old path 158 s); warm no-op 9–20 s; cold 78–107 s (old path 188 s).
Gap: warm edit ≈45×, cold ≈20×. Tuning will not close either; both need structural changes.

WARM EDIT < 300 ms — what an edit build does today and what must go:
| phase now | time | must become |
|---|---|---|
| start-up (open the store, load indexes) | ~1 s | mapped, lazy; nothing read that the edit doesn't touch |
| walk every saved body to assemble the program | 5–7 s | no walk: the engine's frontier names what the edit reaches; bucket keys are saved answers |
| re-lower what the edit reaches | <1 s | stays, bounded by the edit |
| module bitcode for 31 buckets to read their keys | ~3 s | only the bucket the edit is in |
| LLVM for the changed bucket | 0.3 s | smaller buckets, or a fast dev backend |
| link a ~100 MB binary | unmeasured, likely >300 ms alone | incremental link / per-bucket images — measure first |
| code-hash over-invalidation (118 of 120 queries on a query edit) | — | fn-type keying finished (lane A's (b)) |

COLD < 5 s — ≈44k lines/s on 8 cores:
| lever | expected | state |
|---|---|---|
| work-ahead across cores (parse, generators, bodies) | 78 → ~45–50 s | stage 1 built; an intermittent worker trap must be explained first |
| per-body cost ÷5–10 (≈1.5 ms now): no byte round-trip of intermediates on a cold run, type from syntax in memory, allocation | → ~10–15 s | not started; census method |
| fast non-optimising dev backend (LLVM kept for release) or LLVM O0 across cores | → <5 s | not started; its own project |
| a shared content-addressed store so a fresh checkout is rarely cold | sidesteps cold | design exists (saved answers are content-keyed) |

Standing instruction from the same message: lean on Avra's own features (declarations, collect, derives, meanings, generators, components) and bring creative proposals unprompted. Queued from this: typed format holes through a trait (`{id: IdeaId}` → `IdeaId.from_text(span)?`) once formats land as generated code.

## THE TABLE 2026-11-12 13:30 (lane A, 9ba46e7c, not landed; every run isolated: all `.avra-cache` deleted + own `AVRA_CACHE_DIR` emptied before each cold; single samples)

`build packages/cli`:
| builder | cold | warm no-op | one-line edit (core/lowering.av) |
|---|---|---|---|
| old path, old-path-built builder | 191 s wall / 270 s CPU, 3.8 GB | **3.2 s** (kept-binary hit before analysis) | 98 s, 4.0 GB |
| new path, old-path-built builder (P1) | 98.5 s CPU, 2.1 GB (wall waited on the pool) | 12.5 s | 17.8 s |
| new path, NEW-path-built builder (P2) — the switched world | 118 s / 113 s CPU, 1.6 GB | 22.5 s, 26.8 s | 30–43 s wall / 25–29 s CPU (machine loaded) |

- CORRECTS earlier entries: the old path's warm no-op is ~3 s, not ~199 s (that sample was not a kept-binary hit / was confounded); its one-line edit is ~98 s, not 158 s.
- So today: a no-op is SLOWER on the new path (12–27 s vs 3 s); an edit is 3–5× faster with P1 and 2–3× with P2; cold is ~1.6× faster.
- P2 is slower than P1 on the same source (22 s vs 12.5 s no-op): 9.8 s is a code-hash regression lane A introduced with fn-type keying (fix drafted: one shared node per group of fn values); the rest is unexplained — possibly the new lowering's codegen quality making the compiler itself slower. Split owed.
- Editing a query's callee costs the same as editing a plain fn today (26 vs 29 s CPU): the fixed cost hides the over-invalidation.
- Receipts on 9ba46e7c: cold isolated old-path build exit 0; --built 41302/41298/4; --ran 475/402/0 failing with P1 and with P2; 348/348 run by P2's own `test`; P3 `check` == P1's; nested `arg` blocks kept (lane B's fix).
- Targets (owner): warm edit < 300 ms, cold < 5 s. Against the switched world: ~100× and ~24×.
- Disk: the hog since last night was /tmp/gw_aside (15.7 GB of moved-aside caches and product copies from the first lane-B agent's measurements); deleted, 17–19 GB free.

## 2026-11-12 14:20 (`program` c7bf5969)

- LANDED today: lint rules on the program layer (70 syntax rules via `rule`/`Syntax`; 13 `fact_rule`s on `Code`); the stale-record fix in the old path's block-word gate (607fbb4c); formats as GENERATED bodies (`pattern`/`parse`/`parse_octets`/`print` over prelude `format_spans`; ~2× slower than the old emitted scan on 1M parses, causes named); the RUNG for `parse_octets` (old-path door; 48 octets callers moved in lane B's 2dbda974, pending receipts); code hashes computed by the program layer over its own lowered bodies (no absent stand-in; a hash that can't be worked out fails the build); a self-built compiler reuses its answers (no-op ~10–18 s).
- KNOWN GAP (b): a real edit to one query's callee moves 118 of 120 hashes where 39 is right (482 un-noted fn-box call sites; ~1,970 lambdas noted with the generic seat type). Safe (over-invalidates); costs compiler editors only.
- DEFECT FOUND BY LANE D, TOP CORRECTNESS ITEM: answers on the generator/scope chain depend on ASK ORDER — `file_scope → generated_names → file_generated → generator_print → lowered_under → impls_with → package_impls → resolved → file_scope`. In a different first-ask order it either closes into a cycle refusal or `file_generated` answers NO ITEMS (seen as a worker trap "index k out of bounds (length 0)"; 2 of 9 runs; a pinned hash seed does not determine it). Masked whenever answers are reused in the walk's order; exposed by any process whose first ask is a body in such a file (a warm edit, `check` of one file). Not the store, not the held memos. Lane D: deterministic single-process witness, the branch that answers empty, the second variation source, then the fix as a design (stratify generated NAMES from running generators; a generator lowered in its own home; no query swallowing a cycle).
- RULED: bounded generic parameters are keyed by TYPE (monomorphised where a bound makes the body ask the type something); unbounded stay by layout (lane B building). Formats split into two verbs, no overloading, no meaning.
- UNEXPLAINED (lead's measurement): P2's no-op took 160 s twice in a row before a third run took 17.7 s; lane A to reproduce cold → 2nd → 3rd.
- Stage 1 of work-ahead (identical products, kill-safe) is NOT landed: it waits on the order defect above. Its measured floor: ~31 s serial after the parallel part (emit ~17 s).

## WARM-EDIT DESIGN 2026-11-12 14:50 (lane A; approved by the lead for steps 1–5; steps 6–7 with the owner)

Today (P2, one body edit, 19.1 s CPU): start-up 10–80 ms; inputs 0.1 s; queries recomputed/re-verified 2.1–2.8 s; assembling the program 4.8 s; code hashes 2.4 s; memory pass 1.4 s; bitcode for 31 buckets 4.0 s; LLVM for the edited bucket 0.5 s; link 0.6–1.0 s (39 objects, 31 MB + static LLVM → 100 MB); place 0.1 s.

| # | phase | today | target | change |
|---|---|---|---|---|
| 1 | inputs + roots | all of it | ~40 ms | the build is a query: `@query fn binary_of(engine, entry) -> KeptBinary`; a no-op is the engine settling one root from the frontier |
| 2 | assembling the program | 4.8 s | ~0 | `bucket_body_set(engine, bucket)`, a saved answer per bucket |
| 3 | memory pass | 1.4 s | ~0 | per body, inside `lowered_under`'s answer |
| 4 | code hashes | 2.4 s | ~5 ms | `code_hash_of(engine, target)` over bodies' saved hashes; finish (b) |
| 5 | bitcode | 4.0 s | ~0 | an object keyed by its bodies' saved answers, not by emitted bytes |
| 6 | LLVM for the edited bucket | 0.5 s | 60–100 ms | one bucket per FILE, O0 |
| 7 | link | 0.6–1.0 s | 30–60 ms | DEV builds: a base dylib (LLVM, runtime, package C) linked once + one dylib per bucket + a thin main; release stays one static image |
| 8 | recompute what the edit reaches | 2.1–2.8 s | 60–100 ms | push-dirty/pull-verify exists (257–275 ms measured for a std-avrac edit via `tapes --program-only`, ~125 ms of it rewriting the frontier whole); append-only frontier segment; (b) |
| 9 | start + store open | 10–80 ms | ~15 ms | mapped store |
Sum of targets ≈ 300 ms; it rests on 6–8. Unsure, each measured first: LLVM O0 for one file's module; static LLVM inside a base dylib (link, load, ~40k dynamic symbols); whether the frontier recompute holds at ~100 ms under the cli's 41k bodies.
Also from lane A: `avra explain` for "why did this rebuild" from the frontier (P7), built with step 1; buckets as a `collect` over a package's files with objects as CAS answers (a fresh worktree's warm edit can hit another worktree's objects); a dev mode that loads changed bucket dylibs into a running program (hot reload) — the same mechanism as step 7.
- P2 vs P1 on the same source: Avra-bound phases run ~1.2–1.4× slower in a new-path-compiled compiler, uniformly (codegen quality, not one hot spot); census owed.
- The lead's "160 s twice" was a collision with lane A's cache-clearing script, not a defect: cold → 2nd → 3rd with P2 = 98.5 s, 10.5 s, 13.4 s.
- Where a cycle becomes an empty answer (lane A, for lane D's defect): the only cycle guard is `run_recording`; `reused_answer` / `standing_answer` / `settled_from_frontier` and the held memos can serve an OPEN question a standing answer. Law owed in the engine: an open question is answered only by its own computation.

## COLD-UNDER-5 s PLAN 2026-11-12 15:00 (lane D, read-only; from phase timers + one 30 s sample of a cold single-process walk)

One cold build, single process, ~88 CPU-s: body typing+lowering ~27 (≈1.6 ms a body, ~17k bodies); upstream per body ~10; parse ~7; generators 12–16 (serial, in the evaluator); walk + memory pass + trap closing ~8; LLVM module building in Avra ~3 + ~3 (done TWICE: key bitcode, then object); LLVM O0 codegen 12–15 CPU-s on 8 threads (≈2–3 s wall); link ~2. (Correction: "emit 15–18 s" is CPU across LLVM's threads, ~5 s wall; the serial tail after the parallel part is ~18–20 s wall, not 31.)
A body's cold cost: ~61% runtime memory traffic (rc release/retain, box free, array ops, clones 2.8%), ~4% decoding saved answers, 1.5% blake3.
Moves (all needed; none alone reaches 5 s):
1. PARALLEL work-ahead: → ~45–60 s. Waits on the generator-chain cycle fix.
2. PER-BODY ÷3–5: (a) A REGION PER QUERY — a pure query's temporaries live in one arena freed at once; only the answer is copied out (runtime + memory-pass feature; the `@query` wrapper knows what escapes); (b) cold never round-trips bytes — an answer is used as computed and encoded once by a write-behind child; (c) the copy-on-write clone sites.
3. MACHINE CODE: (a) build each bucket's module once (−3 s); (b) build modules inside the body workers; (c) a DIRECT arm64 dev backend (Mach-O writer, AAPCS64, spill-everything; ~3–5k lines of Avra + relocations; weeks; ≈LLVM O0 quality, ~0.2 s for 40k bodies) — best after "IR consumers from role marks" (#5/#11).
4. GENERATORS run as compiled code (they are lowered programs already), not in the evaluator; parse waves.
Arithmetic: CPU 88 → ~35 (move 2 at 4×), LLVM ~18 → ~1, generators 14 → ~3; over ~5.5 P-core equivalents ≈ 6–8 s, with the serial walk/memory pass/link the last wall — which lane A's warm design makes per-body/incremental.
Also: a machine-wide CAS keyed by code hash + content makes a fresh worktree cold only for what nobody on the machine has built (does not help the compiler rebuilding itself after an edit to itself).
- TYPE REFUSALS on the program layer landed (f607b7d2): one agreement door, `Refused { at, want, found, seat: Seating }`, nine laws; byte-identical to `check` on witnesses; 0 false refusals on cli and std-program. Gap found by the lead: entry (top-level) statements are not walked by the door. Next: conditions, conversion help, count rows, and `AVRA_PROGRAM=1 build` FAILING on a refusal.
- Lane D acknowledged the stop order: 1b paused; the cycle is its only job (witness → LAW 1 names stratified / LAW 2 a generator is its home's program → engine law → budget measure).

## ROOT CAUSE 2026-11-12 17:00 — the "order-dependent" worker trap was a RUNTIME fd race (lane D; fix uncommitted, landing with stage 1)

- `became_core` (runtime/avra_cores.c) called `avra_fiber_forked()` first — re-arming the tick in the child: a fresh wake pipe and a tick THREAD reading it — and THEN `close_all_but(keep)`, which closed that new pipe while its thread kept reading the fd NUMBER. The core's next `open()` reused that number; the tick thread read that FILE a byte at a time to EOF, concurrently with the main thread, so the main thread's read began at EOF: a source file read as EMPTY (or short). No items → written names look unwritten → fallback to `generated_names` → the query cycle; indexes past the count → "index k out of bounds (length 0)".
- A two-thread race: nondeterministic, seed-independent, never single-process, worse with more workers, moved by anything that changed timing (the pool, the held-answer memo — both red herrings). It CAN hand out wrong values that don't trap (a short source is a wrong input recorded as truth).
- Retracted along the way (each refuted by lane D's own replay receipts): "answers depend on ask order"; the generator memory-budget theory; "needs held answers + the pool". The earlier plan entries saying the generator/scope chain is order-dependent are WRONG as a diagnosis; the chain exists but was only reached downstream of the bad read.
- Fix: descriptors first (`close_all_but`, then `avra_fiber_forked`); the atfork child handler closes the inherited wake pipe while its numbers are still that pipe's and forgets them; `descriptors_stay` checks by identity (st_dev/st_ino). Witness `runtime/tests/cores_test.c` `tick_forgets_its_pipe`: failed 3/3 before, passes after. 8 workers cold: 13 failing of 14 before, 3 of 3 clean after.
- Owed before landing (lead): a read that ends short of the size it opened, or starts at a non-zero offset, TRAPS naming the path; a typo'd name in a file wearing a derive must give "not defined", not the cycle (else the minimal LAW 1); an audit of every fd number held across a fork/close sweep; N ≥ 20 clean runs at 4 and 8 workers; a cold-first-ask sweep as a standing receipt.
- Kept instruments: the cycle voice naming its questions' arguments; `AVRA_TRAP_TRACE`; `tapes --first` and `tapes --share k/n`.
- WARM (lane A): (a) of steps 2+5 built (24a8993d, not landed): objects keyed by answers; edit 12.2–12.4 s; revert to a built state 4.3–5.0 s; cold regressed (re-encoding 41k bodies through `body_lowered`) — lands with its fix. `QUESTION_SHAPE` versions every identity; keyed questions never encode arguments on a reused ask. cli has 186 NEW idiom findings against the baseline (debt on `program`).

## 2026-11-12 20:15 (`program` f856bce1) — state, the plan to the targets, and a ruling

Curve (P2 building the cli, CPU; machine saturated by four lanes): no-op 0.2–0.4 s; literal-only edit 5.3–6.9 s; call-adding edit 10.8–16.9 s; query-file edit 21–31 s; cold 76–107 s by load.
Landed since the table: `program_binary` as one query + `explain --why`; keyed question identities (`QUESTION_SHAPE`, colliding-pair tests); objects keyed by answers; `bucket_program`; six default/trait lowerings as queries (cold 117 → 76 s); `placed_code` + `program_code_hashes`; `unit_facts`/`placed_names`; change pruning. Type refusals: one agreement door, nine seat laws + conditions (lane C; "the door visits every body, and a build refuses on it" at 1efd09a1 pending its merge). Bounded type parameters keyed by the filling type (lane B, pending landing); std-relation 42/42 made.
RULING (lead): a query may read ITS OWN LAST ANSWER and the set of its reads that moved (an engine primitive in std-program) so `program_reached` and the code-hash fold revisit only what a change reaches. Law: the full computation is the oracle — a fold's answer is byte-identical to from-scratch; a switch turns folding off; a check mode computes both and traps on a difference; cold or shape-changed → full. Declared form, shown to the owner when it lands.
PLAN, warm (lane A2): fold primitive → `program_reached` fold → code-hash fold → gap (b) → append-only frontier + lazy store → [owner] one bucket per file at O0 → [owner] dev builds as base dylib + per-bucket dylibs → tune to 300 ms. Expected ~1 s after the known steps; the last ×3 is tuning.
PLAN, cold (lane D): runtime fd fix + work-ahead stage 1 → 1b (parallel parse/generators, shared facts once) ~45 s → region per query (probe; the 61%) → no byte round-trip cold → generators as compiled code → modules built once, in the workers ~10–12 s → [owner] direct arm64 dev backend → <5 s with the warm track's incremental assembly/link.
OWNER DECISIONS PENDING: (1) dev builds as a base library + per-file libraries (release unchanged); (2) a direct arm64 backend for dev builds; (3) whether lane B moves to cold-speed work.
PROCESS: lanes B and C sat 3.5–4 h with finished, unreported work (background receipts, turn ended, never woken) — the lead checks every worktree hourly. Lane A's agent was replaced at f856bce1 (context spent) by lane-a2 with a full brief. Machine saturated: load 12–25, swap 4.8 of 6.1 GB; wall times are not usable; a no-op waited 6 minutes for a compile slot.

## PROCESS 2026-11-12 22:40: lanes run light receipts; the lead runs the heavy gate once per landing

- Why: new-path builds are ~2 GB / seconds, but every lane was still running the OLD-path cold build (5 GB) and old-path `check packages/cli` (3–4 GB) plus full sweeps and P1→P2→P3 per reported sha — four lanes of that saturate a 16 GB Mac (load 12–25, a 0.2 s build waited 6 min for a slot, lanes stalled for hours on background receipts). The owner ruled runners out for now (≈5 min to start with the current setup).
- Now: a lane reports a sha after `AVRA_PROGRAM=1 make try`, its own touched tests and its subject's gates only, and no longer merges `program`. The lead merges in the integration worktree `/Users/tristan/projects/tristanMatthias/avra-ho-land` (branch `program-land`) and runs ONE heavy gate there per landing: cold isolated old-path build, `--built`, std-avrac `--ran` (the made count must not drop), std-program suite, idioms 0 new (cli, std-program, std-avrac), the findings gate, P1→P2→P3 — then moves `program`.
- `program` 93c5c9a8: bounded type parameters keyed by the filling type; idioms 0 new in cli/std-program/std-avrac; std-relation 42/42 made. Pending: lane B 4b46599d (test-file idioms); lane C false-refusal fixes (6 valid programs were refused: named arguments checked by position; a list/map literal into a named seat) + all-packages sweep; lane C's whole-program refusal rule HELD (it added 82 CPU-s cold because every body is surface-typed twice — one saved surface typing per body owed); a misspelled name BUILDS on the new path (`resolve.unresolved` law owed); lane D's runtime fd fix series (0 failures in 38 runs; the defect is on main too); lane A2's `@folded_query`.

## COLD: lane D's census of one cold new-path cli build (2026-11-13) — the arena is shelved, the box COUNT is the lever

- Exact counts (census runtime, ~42k bodies, 165 s user): 1.106 G boxes (958 M lists, 116 M strings, 30 M bytes, 2.6 M maps) = ~26,000 per body; retains 1.80 G, releases 2.88 G; list reads 10.5 G, writes 3.29 G.
- Top sites: `SavedLayoutWriter.write_octet` 491 M pushes (the answer encoder pushes each octet into a List<int>); `avra_insist` 140 M retains; `CheckedProgram.named_shape` 44.6 M appends; `SignedType.bound` 32.4 M; `SignedType.filled` 12.9 M; copy-on-write clones `Ident.identity` 4.2 M, `TypeRef.fingerprint` 2.0 M, `MethodCall.identity` 1.6 M.
- Time (sample of the cold walk, inclusive): runtime memory traffic ~61% (release/free ≈ 25%), encode answers 7.2%, decode 3.2%, hashing 2.1%.
- Per-query arena: removes at most ~15% (bulk free) to ~30–35% (with the memory pass skipping counts), does not reduce the count, and needs a promote-on-store barrier for held answers, held items, `once` caches, interning Cells. SHELVED.
- Order now: (1) encoder into a Bytes builder; (2) a computed value held as its answer, never decoded in the same process; (3) measure `x!` retains; (4) boxes per body ÷5 — representation work in typing (top ten sites, design with expected counts first). Lane B: generators as compiled code (12–16 s of cold). Lane A: code-hash reach-sum fold, then "program built"/"store saved" per edit.
- Edit curve at 5c6419c7 (CPU, loaded): no-op 0.35 s; literal 7.2–8.6 s; call-adding 7.4–12.1 s; query-file 6.6–8.3 s (was 21–31 s).
- `program` = 4b46599d (std-avrac idioms 0 new). `two_grammars_test` run still owed (a single spec file needs more pool than is free while lanes build).

## OWNER MANDATE 2026-11-13: restructure for extreme efficiency

- Owner: different data structures and algorithms are wanted — "really advanced ways to restructure things… EXTREMELY efficient". No further approval needed for representation changes on the new pipeline.
- Standing rules for it: census before/after (exact counts), products byte-identical, the old shape kept as an oracle behind a check mode where one exists, design note with expected counts before a change that touches many files.
- Candidates on the table: types interned as ids (hash-consed, one registry); node facts as columns keyed by typed ids; question/answer keys as hash words; per-ask bookkeeping as rows of words; the encoder writing straight through; decoder views instead of copies; evaluator jump tables + symbol index; reach sets as bitsets with a summed digest; `x!` on a held view taking no reference.
- `program` = 39ddf380 (lane D's fd series + stage 1 landed; `two_grammars_test` 5/5 run on an idle machine).

## REPRESENTATION OVERHAUL — the plan of record (owner 2026-11-13)

Owner: restructure for extreme efficiency; extend the std libs where needed; ANY core lib or data structure is written GENERICALLY (a library type others can use, never a compiler-private special case).

Goal: boxes per compiled body ÷5 or better (26.5k → ≤5k), cold < 5 s, warm edit < 300 ms.

| # | Change | Replaces | Owner | Status |
|---|---|---|---|---|
| 1 | Types hash-consed into one registry, passed as 32-bit ids; `bound`/`filled`/`unwrapped` as memoised id→id maps | a fresh type value (lists) per use | lane D designs; owners assigned from the design | design owed |
| 2 | Node facts as columns keyed by typed ids (syntax, typed facts, lowered instructions) | one record per node | lane D (typing/syntax), lane B (lowering) | design owed |
| 3 | Text interned to symbol ids | string compares and string keys | lane D design | design owed |
| 4 | Sets as bitsets / sorted id runs | lists | lane D design | design owed |
| 5 | Saved answers laid out so a read is a view over mapped bytes | decode into fresh boxes | lane D | computed answers already held undecoded (4dc377bf, ungated) |
| 6 | Questions/answers keyed by hash words end to end | text keys | lane D | answers done (54d73412, ungated); question keys next |
| 7 | Per-ask bookkeeping as rows of words | a record per ask | lane D | queued |
| 8 | Encoder writes straight through into a byte builder | per-octet pushes into List<int> (491 M per cold build) | lane D | folded into the row rung |
| 9 | Evaluator: symbol index, per-body jump tables, then pre-decoded instructions / flat frames | linear scans per call and per jump (~300 ns/step) | lane B | in progress |
| 10 | Lowering emits into packed columns; tapes as packed token arrays read by view | a record per instruction/token | lane B | census + design owed |
| 11 | Code hash = summed digest over the reached set, updated by delta | colour refinement over the giant SCC per edit | lane A | written, unchecked |
| 12 | `x!` on a held view takes no reference (memory pass) | 115 M retains per cold build | proposal by lane D, owner unassigned | proposal owed |

Library and language pieces these need — GENERIC, in the std libs, one rung for all new runtime rows:
- a packed integer list (`List<u32>`-like) and unboxed small records inside lists;
- an in-place `Bytes` builder (append octets / words);
- a hash row (blake3 over words, or a wrapping 64-bit mix);
- an interner (`Interned<T>` / symbol table), a hash-consing registry, a bitset, a columnar side table — each a generic library type with its own tests, used by the compiler like any other user.

Rules: census before/after (exact counts); products byte-identical at every step; the old shape kept as an oracle behind a check mode where one exists; a design note with expected counts before a change that touches many files; measured ideas that lost are recorded as dropped (per-query arena: ≤15–35%, no count change; native generators: ~3 s net).

- Owner 2026-11-13: the runtime fd fix is NOT carried to `main` separately — it reaches `main` when `program` merges. Open owner decisions left: split dev build; direct arm64 backend.

### Overhaul rulings 2026-11-13 (lane D's proposals)

- TYPES (items 1, 3): `SignedType` is a recursive record of lists rebuilt by every `bound`/`filled`/`unwrapped`/`with` (55 M appends, 44.6 M in `named_shape`, clones for equality/fingerprints) and saved whole in answers; 82 files name it. RULING: two names for one type — a DENSE LOCAL ID (32-bit index) inside a process, the CONTENT KEY (128-bit hash of its saved bytes) at every boundary (saved answers, fork results, fingerprints). The id type has no Saved impl, so it cannot cross. Operations are memoised id→id tables. The interner is a GENERIC std type (`Interned<T>` over any saved `T`), SignedType its first user. Stages: (1) interned + memoised behind the unchanged API — lane D; (2) answers save keys (store version bump); (3) node facts as columns. Lane D's estimate for 1–3: 23k → ~14k boxes/body; ÷5 also needs the IR `Ins` stream as columns (lane B's lowering census).
- `x!` ON A HELD VIEW (item 12): approved — a second row `avra_insist_view` chosen by the memory pass where `standing_regs` proves the operand stands; four AVRA_RC_GUARD witnesses. Rides the single runtime-row rung with the Bytes builder, hash/mix row, packed list. Lane D, after stage 1.
- POOL: a waiter must never hold a partial claim (two runs each held 19 of 38 slots and slept; 36 min lost, twice). Fix in runtime/avra_pool.c — lane D, first.
- Evaluator jump tables + symbol index measured 1.46× (250 → 171 ns/step); what remains is a boxed `Val` per register write — representation change in lane B's note.
- OPEN DEFECT: a warm call-adding edit in cli/commands/cache.av traps in `tests_kept` ("index 6 is out of bounds (length 6)") — lane A bisecting; engine landings held if it is on `program`.
- Lane C: all-packages sweep found 37 false refusals in five families (spread arguments, named method arguments, component instances in a typed seat ×2, a lambda's dyn answer); fixing to 0 before its batch is gated.

### Scoped memory levels and the overhaul (owner question, 2026-11-13)

- Spec Axis 9: memory is a property of SCOPE — application (RC + arenas), `systems { }` (owned, deterministic, zero RC), `bare { }`; arenas are compiler-detected, provider-declared (`@arena_scope`) or `@arena fn`; RC elision (9.7). Nothing of it is implemented in std-avrac today (no `systems`/`bare`/`@arena` in the compiler source).
- Fit with the measurements: (a) ARENA — a query's compute is the spec's arena-suitable shape, and `@query` is the provider that would declare it; lane D measured ≤15% (bulk free) to ~30–35% (no counts), no change in box COUNT, and the spec's rule "no storage of scope-local values in outer-scope containers" is exactly what held answers / interning tables / `once` caches break — so it is second, after the count falls, with promote-on-return. (b) SYSTEMS LEVEL — the overhaul's library types (packed list, byte builder, bitset, interner table, columns) are owned buffers of unboxed words: that IS the systems level. (c) RC ELISION (9.7) — `x!` on a held view and the borrowed-params law are instances.
- Sequencing constraint: until the flip the compiler's own source must build on the OLD path, so a new language form the compiler uses must be implemented in the old typer/lowering too. Runtime rows + generic library types are cheap now (one rung); real `systems { }` scopes are built ONCE, on the new pipeline, after the flip — the library types' APIs are designed now so their bodies move to systems level without their users changing.
- Correction to the line above: `systems` and `bare` are RESERVED words (compiler/resolve/resolve.av) with no meaning yet, and `@arena` exists today in a different sense — std-relation's storage mode for a relation (`Arena<Node>`, ids into one store; core/nodes.av uses it twice). The scoped MEMORY levels themselves are unimplemented. The existing `@arena` relation mode is a candidate home for "node facts as columns" (overhaul item 2) — lane D to check before designing a new table.

### Owner 2026-11-13: scoped memory levels wait until AFTER the switch

- `systems { }` / arena scopes are not built before the switch. Before it: runtime rows + generic library types only, shaped so their bodies can move to systems level later.

### THE SWITCH — stages and what blocks each (2026-11-13)

- STAGE A — `build` of the COMPILER defaults to the new pipeline (old path kept behind a flag and as the gate's oracle). Blockers: (1) the warm-edit `tests_kept` trap (lane A); (2) a misspelled name builds — `resolve.unresolved` (lane C); (3) lane C's refusal batch gated and landed (0 false refusals across all packages); (4) a type error anywhere fails the build without the +82 s (one saved surface typing per body); (5) the two-methods-one-name refusal. Not blockers: Select (4 bodies, trap baseline), speed targets.
- STAGE B — `build` defaults to the new pipeline for EVERY package. Blockers: packages not yet made on the program layer — std-http 12/56 tests, std-ui 5/75 (reactive slots), std-crud 0/7, Select as `Waitable<T>`, sqlite extern seats; and the errors a user can hit must be refused by name (the diagnostics study: 283 kinds).
- STAGE C — `check`, `test`, `run` move; the old typer, lowering and type registry are deleted. Blocker: full diagnostics parity.

## ROOT CAUSES (owner go-ahead 2026-11-13): fix under the hood, not site by site

- Measured root: ~0.85 G boxes and ~4 G rc ops per cold cli build, ~61% of the walk in runtime memory traffic. Three causes: (1) nearly everything is boxed (only a one-scalar-field record is flat); (2) almost no RC elision (spec 9.7 unbuilt: `x!` always retains; a field handed to a call retains; path reads clone); (3) the new engine encodes/decodes every answer at fine grain.
- (1) and (2) live in the memory pass / backend / runtime, which BOTH pipelines share — they do not wait for the switch and speed every Avra program.
- STARTED: RC ELISION — lane D, rule by rule (R1 borrowed reads incl. `x!` on a held view and a standing root's field lent to a call; R2 last-use move; R3 unique locals; R4 pair cancelling). Each: prize censused by site and by the memory pass's reason, law at its site, borrowed_params-shaped witnesses under AVRA_RC_GUARD with every hazard, fixed point P1→P2→P3, sweeps. Rows in one rung.
- NEXT (design before build): UNBOXED SMALL VALUES — records of a few scalars and simple enums inline in registers, fields and lists.
- ENGINE (3): lanes B (items by view, backed `Arena<T>` in @std/relation) and the cold findings (store write-behind; generator programs lowered once) — the latter two to be reassigned from lane D.
- Deferred: interned SignedType (lane D re-measured: no longer a top box site; tens of M list ops).
- `program` = af30310e: pool whole-claim fix landed and installed in all six worktrees; lane C's batch (0 false refusals, 48 packages) landed with 8 idiom findings owed; lane E (new) owns the acceptance laws — `resolve.reserved` done and queued.
- Infra: October Sprite bill $178.79 (RAM $95.84 > CPU $71.28: idle-awake machines). Recommended one fixed-price dedicated server (Hetzner AX102-class, ~€122/mo, 128 GB) for lanes + gate + a warm CI runner; owner deciding. 40 cold Sprites still exist (storage); not deleted.

- 2026-11-13 14:45 `program` = 4113f576: landed lane E's `resolve.reserved` (three laws, one voice both paths speak), lane D's allocation cuts (cold cli ~0.85 G boxes, −24% from 1.116 G) and the pool deadlock fix (a pool held wholly by waiters: the least holder gives up, naming it), lane B's cache-first item reads + generated items held under a whole-tape key. Gate: old build 0; --built 42448/42444/4; --ran 412 made 0 failing; std-relation 42/42; std-program 375/375; runtime tests 0. OWED: 12 cli idiom findings (8 lane C: tapes.av, core/checking.av, features/fns/checks.av; 4 lane E: compiler/item_misnamed.av). Compiler reinstalled in all six worktrees.
- Lane D stopped (ignored five reorders) and restarted as lane D2 in the same worktree on: (1) work-ahead must not fork on a no-op build (+1.5 s CPU per no-op), (2) RC elision R1–R4. Its unassigned findings: saved WRITER builds a List<SavedSlot> per record (~80 M boxes; emit slot statements onto a reusable int stack); question-key spelling ~48 M; store save 9.6–12.8 s serial at the end of a cold build; generator programs lowered in each of 4 workers. Census totals are noisy (816 M vs 847 M on one binary) — compare sites.
- Gate process: lanes never run package idiom checks (one held 31/38 pool slots for 32 min); the lead runs them once per batch. Gate now ~18–22 min for several batches merged together.
- Missing refusals found on the new path today: reserved word as a name (done), a misspelled name (lane E), two methods of one name (lane E), `it` with no element / type.lambda (lane C). Wanted voice: two types of one name reaching a derive's file surface as a generator query cycle.
- Open: lane A has not answered the warm-edit `tests_kept` trap (stage-A blocker); its hash fold costs 3.2–4.5 s cold vs 1.4 s — not landing until ≤ old.

## 2026-11-13 evening — where the typing+lowering half goes, and the lane reset

- MEASURED (lane B, cold `tapes cli --built`, 26,469 bodies): program ASKS repeat massively and nothing is memoised per type — named_of 6.53 M asks 4.6–5.4 s; enum_of 1.84 M 3.0–3.5 s; record_of 0.90 M 1.8–2.3 s; method_of 1.7–2.2 s own; named 1.8–2.2 s; method 1.0–1.3 s; value_named 0.8–1.1 s; toolchain_type 2.9 → 0.4 s (fixed, aa9fdfea). Emit walk own by node: Prop 4.3 s / 56,282 nodes (76 µs: each field read rebuilds the record's field list and every field's layout — fields_of, seat_layouts, laid_out, variants_of, named_over); MethodCall 2.8 s / 53,946. ONE cure: memo by TYPE IDENTITY → interned type ids are back, as the memo key (≈20 s of asks + ≈7 s of walk), not for box count. Owner: lane B3 builds both the generic `Interned<T>` (dense local id, content key at boundaries, per engine) and the id-keyed memo layer with AVRA_TYPE_MEMO_CHECK as oracle.
- Dropped by measurement today: per-query arena; native generators (~3 s); lazy backed Arena (99.998% of built nodes are read); IR columns (<1% of boxes); int-as-text map keys in lowering (1.65 M of 40 M — the bulk is question-key spelling ≈48 M, unowned: keys as bytes); interned types as a BOX fix (≈37 M).
- Unowned, ready to assign: question keys as bytes (≈−45 M boxes); the saved WRITER (≈−80 M boxes; slot statements onto a reusable int stack); store save 9.6–12.8 s serial at the end of a cold build (write-behind / per-phase saving; compaction off the build path — DiskStore.saved in std-program/src/disk_store.av); generator programs lowered once in the parent before the fork (item_generators.av `made_programs` is a per-process `once` cache each core misses); unboxed small values (design).
- THE WARM-EDIT TRAP: cause = cf3e8fab's fold re-asking the last answer's reads with a positional key (`TestsKept` = a flag per test POSITION of the old body). Fixed at the cause by lane A3 (5475ead7 on program-a: TestsKept is a RULE over the body's own sites); warm == cold of the edit. Landing via a branch off `program`. Engine law to state: a question's key never indexes another answer's positions.
- Work-ahead regressions found after landing: forked on every no-op (+1.5 s; fixed by lane D2 e37da9a3, not landed — conflicts with lane C's refusal step in tapes.av `program_built`) and on every edit (≈7–10 s CPU; lane D2 next). The gate needs a no-op + one-edit CPU check.
- LANE RESET: the long-running lanes read their inbox only at the end of long turns and kept working replaced orders (and one woke a stopped lane by messaging it). All four were stopped and restarted with short complete briefs: A3 (warm-edit trap, then cold cost of the summed hash), B3 (type ids + ask memos), C3 (idiom debt + gate/sweep scripts into tools/, whole-program refusal rule in the work-ahead children with one walk per item, type.unknown/unknown_prop/method, new-path `check --baseline`), D2 (work-ahead costs nothing warm; RC elision R1–R4). Lane E (new today) finished three acceptance laws: resolve.reserved (landed), resolve.unresolved, type.impl twice — two receipts owed (all-packages sweep; the std-http `let x = <component instance>` binder). Never message lane-a2 / lane-b2 / lane-c2 / lane-d.
- Lane C's old gate/sweep scripts are saved at .lead/scripts/lane-c/.
- `program` = cfbc3269. 12 cli idiom findings owed (8 in lane C's landed code → lane C3 task 1; lane E fixed its 4 in ab0550a4, unlanded).

## PERFORMANT BY DEFAULT — the plan of record (owner 2026-11-18)

The language is not too loose; its COST IS INVISIBLE. Every slowdown found on 11-18 was natural-looking
code whose price nobody could see. Two halves, both owed.

### Half 1 — the compiler makes the obvious code fast (representation is the compiler's job)
- Packed lists of scalars (landed, batch 48); strided lists of flat records (alloc lane, in progress).
- A nullable flat record carried as presence + words, one box only at a pointer seat (alloc (2), after
  the aggregate rewrite; acceptance: .lead/handoff/nullable-pair-step0.md).
- Static method tables per (type, trait): a `dyn` box is [value, table], never N code pointers copied
  per value (lowering-quality, in progress).
- Aggregates held as leaf scalars in the emitter, every unfilled part zero-filled (parallel-main).
- Next: a record that never escapes its fn lives on the stack — no box at all (escape analysis).

### Half 2 — cost is visible and gated
1. **Exact-count gate.** The census's deterministic counters (boxes, retains/releases, list writes,
   clones) over fixed workloads (cli cold check/build, std-program) are a RATCHET: a PR that raises one
   past a stated tolerance fails, a PR that lowers one tightens the baseline. Never a warning — the
   10-19 4x regression landed green because speed_note.sh only warned.
2. **Slow-shape rules**, found by `avra check` as `rule` declarations like the idioms:
   a string/name compare inside a loop; a list or record made per element only to be dropped;
   `concat` in a loop; a scan nested inside a scan (quadratic); a lookup filtering a whole list by name.
3. **`avra explain cost <fn>`** — boxes, copies, retains and calls per run of a fn, from the
   compiler's own lowering facts (a thin query over the DB), so a writer sees the price before shipping.

### Instances that motivated it (11-18 census, cli cold)
- lexer ~11 boxes a token (a ScanStep record per step, a Loc per token) — 35 M boxes
- `dyn Slots` Builder box: 41 pushes of code pointers per node — 18% of the parse
- re-settling every node of a file per item read back — quadratic, ~7 s
- string compares in hot lookups: rules_table 44.5 M, same_method 27.4 M, naming_of 19.9 M,
  alias_written 41.3 M
- a one-element list per typed expression to drop nulls — 29 M boxes
- RecordedRead record per engine read — 18.8 M boxes + 94 M pushes

### Half 1 — the rest of the list (standard techniques, not yet done here)
- **Interned names**: a name is an int id minted once; every name compare is an int compare and every
  name-keyed lookup an indexed one. Kills the string-compare class at its root (the 11-18 hot lookups).
- **Reuse in place (Perceus/FBIP)**: when a box's count is 1 at its last use, a constructor of the same
  size reuses it instead of free + alloc; a functional update becomes an in-place write.
- **Drop specialization / borrow inference**: a value's last use moves it (no retain + release pair);
  extend the consumes pass from params to every binding.
- **Devirtualization**: a `dyn` call whose concrete type is known at the site is a direct call.
- **Deforestation**: a `map`/`filter`/`flatten` chain ending in a fold or `for` builds no
  intermediate list (walk chains do this for some heads; make it total).
- **Scalar replacement**: a record built and read inside one fn is its fields in registers (LLVM SROA
  does this only when the record never touches the heap — our boxing hides it).
- **Escape analysis → stack records** (listed above).
- **Arenas per query**: a query's temporaries come from one region freed when the query settles.
- **Set/switch lowering**: `x in ["a", "b", …]` over literals lowers to a switch or a static set.
- **SoA option** for List<Record> read by column (strided is AoS; columns when a loop reads one field).

## ARCHITECTURE FOR BOTH — cold and warm together (owner 2026-11-18: no sacred cows, never trade warm for cold)

### The measured picture (parallel-main, cold cli dev build, 4 cores, 323fe0a1)
- 183 CPU-s, 56 s wall, 82% parallel efficiency. Zero idle would still be 46 s: CPU is the wall.
- Bodies wave 95 CPU-s = ENGINE 50 + COMPUTE 42. Engine: lookups 12.0, recording reads/records/frontier
  10.9, decode 9.2 (values only 1–4; the rest records), encode 5.9, store packs + claims 8.0
  (of which pack SEARCH 11.3 across the whole wave: binary search over 5 mapped packs, a C call a word).
- Compute: laws 19.4, lowering 12.5, signatures/resolution 4.9, typing 4.7.
- 1.22 M reused asks at ~7 µs; 418,834 per-item law asks at ~48 µs (mostly engine).
- RC traffic: 2.6 G retains, 3.5 G releases; 870 M–1 G boxes per build.
- Serial middle (the walk, program_walked/reached, keys) ≈ 6 s of wall; wave edges/stragglers ≈ 4 s.

### The principle: COMPUTE COARSE, INVALIDATE FINE
A query exists only where an edit can be cut off: ITEM × PHASE (parse, signature, types, lowering,
laws). Inside one, plain fns, no bookkeeping. Each item-phase answer records WHICH NAMES / SIGNATURES it
read (once, per item), so an edit re-runs exactly the items whose read names changed — today's
invalidation set — and early cutoff stays at the item. What is given up is reuse INSIDE an item, which a
warm edit never gets (you edited that item). Warm gets faster too: fewer, cheaper asks per edit, and a
no-op warm checks ~110 k item answers instead of ~1.2 M.

### Warm is protected by gate, not by promise
- The edit witness (warm == cold) stays in the gate.
- The exact-count gate counts RE-RUN WORK PER EDIT KIND (body, signature, comment, declaration added,
  rename): a PR raising any one fails. Wall targets reported beside: warm edit ≤ 300 ms, no-op ~100 ms.

### The changes, ranked by (cold gain + warm gain) / risk
| # | change | cold | warm | state |
|---|---|---|---|---|
| 1 | **Item × phase query boundaries** (above); laws first (the fold) | ~−20 s+ | fewer asks per edit | laws fold in progress (laws-fusion); engine design (warm lane) |
| 2 | **Hash index in every store pack**, later one merged index (compaction past N packs) | −9 s | every saved-answer lookup | approved (parallel-main) |
| 3 | **Dense typed keys**: a question is (phase, item id), an answer a row in a column table indexed by id; no hashing of encoded questions; one probe per reused ask | −6 s | no-op warm ~1.2 M → ~110 k cheap probes | warm lane steps 2/3/5 |
| 4 | **Interface firewall**: every item exports a SUMMARY (signature + the facts other items may read) with its own hash; a dependent reads summaries only, never another item's body facts. A body edit then provably re-checks only that item (decl_grain's remaining cross-item re-asks — item_misses/item_receivers — are this missing) | — | the core warm guarantee, by construction | to design (warm lane) |
| 5 | **Interned names** (dense ids, saved as text) | −1.5–2 s | cheaper compares in every re-run | approved (laws-fusion, after the fold) |
| 6 | **One walk per item per phase**: every fact a phase needs computed in one pass over the item's nodes (laws fusion generalized to typing/lowering facts) | −5–10 s | same per touched item | laws first |
| 7 | **Prebuilt std answers**: the toolchain ships std packages' saved answers (the machine CAS already exists, ~/.avra/cache/cas) so a user program's cold build reuses std; only its own code is cold | large for every user program | — | to design |
| 8 | **Publish once**: a worker's answers reach the parent from the wave's shared table where they stand, not re-encoded as learned rows | −3 s | — | parallel-main (B) |
| 9 | **Parallel serial middle**: the walk, program_walked/reached, keys folded per file in the waves, merged at the end; split the heaviest emit bucket | −6 s wall | warm walk incremental per file | lowering-quality, measured 11-19: serial middle ≈7 s of 64 s cold (answers taken 1.3 s = #8; walk 2.7 s, survey 1.2; program_reached 1.5; file_refused 0.8; keys 0.7). Measured, not worth it: wave seams ≤0.5 s, compact cancel keys 0.3 s, item_starts fold ≤0.4 s. Generators-wave lock imbalance: hubs/heaviest-first order measured no gain (structural); declarations sub-wave built (e936dde7) and reverted (849d79ca): waits 14.5 → 7.6 s while cold wall held 88.6 → 89.7 s (±3 s), so not on the critical path. #8 publish once: take 0.4–0.9 → ~0.1 s per wave. Cold CHECK runs no work-ahead at all (profile 11-20: one pid, 124 s serial; laws 46% + rules 20% inclusive) |
| 10 | **The compiler's own RC traffic** (2.6 G retains): borrow inference to every binding, reuse in place, per-item-phase arenas for temporaries freed in bulk — the zero-cost techniques applied to the compiler itself | large | same per re-run | ZERO_COST rows |
| 11 | **Per-fn object cache + incremental link** for warm emit; at dev level a fn's object is reused whenever its lowered body hash is | — | warm build emit ≈ changed fns only | to design |
| 12 | **A fast dev backend** (direct machine code for dev builds instead of LLVM -O0; LLVM stays for release) | emit 20 → ~3 CPU-s | warm build emit too | research; large |

### Considered and set aside (with the reason, so it is not re-proposed blind)
- **Shared frozen answer arena across threads** — measured: value decode is 1–4 CPU-s; the cost was search, which #2 takes.
- **Claim-order tricks in the generators wave** — the waits are true dependencies; parking needs fibers sharing one engine (~2 s for a big change).
- **A resident daemon** — owner rule (one-shot processes, a store on disk); #1–#4 make one-shot warm cheap enough.

### Order
Laws fold (#1 for laws, #6) and pack index (#2) now → engine dense keys (#3) and the item × phase design
(#1 generalized, #4) → interned names (#5) → publish once (#8) and the serial middle (#9) → RC (#10) →
std answers (#7) → emit (#11, #12). Each lands with: the bodies-wave table before/after, the cold census,
and the warm re-run counts per edit kind.

### Item × phase: the design of record (warm lane, 11-18; full text .lead/handoff/ITEM_PHASE_DESIGN.md)
- Warm re-runs measured today (laws phase, one edit to cli/src/commands/cache.av): literal 69, body 70,
  signature 103, declaration added before an item 303. Designed after: 6 / 6 / ~10 / ~8.
- Three causes: POSITIONAL identity (an item is (file, at), so an insertion renumbers everything after
  it); ABSOLUTE places (item_start / spans move on any edit above); FINE-GRAINED law questions.
- Shape: ~211 queries → ~12 query kinds (items(file) parted, parse, summary — the interface, types, laws,
  lowered, file_findings, module_names parted, program). Item id = (file, declared key, occurrence),
  never position. A question is (phase, item id); answers in column tables; a reused ask is one index.
- Order: laws (with the fold) → stable ids + relative places → summary as the one interface → dense
  keys + column tables → types and lowering as item-phase answers. Each step: witness, count.py per edit
  kind, cold census, bodies-wave table.

- Fix C (direct calls through Lexeme fn fields via const lex seats): PARKED 2026-11-20. Cost 2–3 days, mostly an executor refactor (lex out of MatchContext, a const seat through the match recursion) plus a compile-time form for a const record of named fns. Value ~0.3–0.5 s of a cli build (token_mask 77M indirect calls/check-cli); fix A already removed 61M at no source cost.

- Work-ahead over-reach (2026-11-20, measured): a cold cli build lowers ~2.8K bodies and types ~1.2K the program never reaches (~5–6 s CPU) for halving the wall (78 s vs 162 s). Walk-led waves rejected: walk depth 25, ~0.9 s per wave barrier = 2–4x the saving. Revisit if per-wave cost falls ~10x.

## CENTRALIZATION: the plan of record (owner, 2026-11-24)
One definition per concept. A second spelling is deleted in the same change that adds the first. Each line is an epic or ticket in the tasks db; design text lives in the doc each one names.

### Identity and keys
- ContentKey: one identity type, plus a law refusing text compares used as identity (.103; lowering-quality lane).
- One interned `Name` for every name-keyed table (.104.4).
- Map/Set: generic keys, a Swiss index, the representation the compiler's to choose (.99; design docs/2026_11_24_MAPS_AND_SETS_DESIGN.md, §11 decided).
  - Phase 1, runtime index, laws-fusion lane (.99.5). Phase 2, hashable keys and Set<T> (.99.1). Phase 3, dense-id layout replacing SideTable/IdMemo/DenseWindow/HashKeyedTable (.99.2). Phase 4, list-as-set rule and sweep (.99.3).
  - Set literal (.99.4; lead recommends `#{a, b}`). Core protocols, one algorithm per verb with the fast path per type (.99.6).
  - Perfect hashing for static key sets (.99.7), roaring bitsets for dense id sets (.99.8), Eytzinger layout for sorted static lookups (.99.9). SIMD deferred by the owner (.62.1.3).

### One definition per layer (.104)
- Traits everywhere: free-fn families become traits and impls (.104.1).
- One side table: every per-node store becomes one `@derive(Facts)` table (.104.2; design note from parity-types: 26 SideColumns, 46 SideTable uses).
- Derived persistence: save and load derived from the declaration (.104.3).
- The six inefficiency families in ZERO_COST.md, each with a detector that fails the gate (.104.5).
- One typed settings source replacing the 247 `AVRA_*` env vars (.104.6).
- One annotation spelling: `@Trait` derives, `@fn` calls, `@mark` is read (alloc lane).
- One oracle format: warm==cold, eval==native, gated==ungated and refusal goldens, declared once (.100.2).
- wisp, the internal CLI: every Make target, tools script and AVRA_* var classed keep, merge or delete (.100, .100.1).

### Soundness and gates
- Store soundness by construction: enforced input door, `avra cache check`, model-based fuzzer (.101.1–.101.5).
- Every keeper on every gate (.102); a gate of 12–15 min on free runners, same checks; no paid runner, owner 11-24 (.112).
- Seed refreshed to the program head (.112.1). History is clean, `program` = origin/program (.112.2, done 11-24).

### The ledger measures what can regress (.105)
- Warm-edit matrix including the broken edit (.105.1). Peak memory (.105.2). Allocations per unit per pass (.105.3). Re-work detectors: duplicate computes, order shuffle, items read per own item (.105.4).

### Cold check under 5 s (.114)
- One tape ask per item (.114.1). No generator work in files that declare none (.114.2). Template copier cuts (.114.3). The next item-view batch (.114.4). Frame pointers for profiling (.114.5). Cold worktrees share build results (.114.6).

## MEMORY REGRESSION (2026-11-24, open, P0 .119)
- A cold cli build peaks at 3.8 GB on a Linux runner and 6.4 GB on the Mac; it was about 1.1 GB. A cold `check packages/cli` alone passes 2.6 GB, so the cost is in the front end, not codegen.
- On a small package, accounted live bytes peak at 134 MB while RSS reaches 373 MB.
- Why no gate caught it: the ledger counts deterministic events (boxes, compares, copies) but holds no peak-memory row, and runners have room to spare, so nothing failed. .105.2 adds the row. The mem-hunt lane is finding the cause.
