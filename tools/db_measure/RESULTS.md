# The compiler DB's three deciding measurements

Measured 2026-10-05/06. Every number below is MEASURED by the command
beside it unless it says READ or ESTIMATED, and holds for the scope
named — nothing here is generalised past it.

- Tree: `origin/main` @ `05fe643` plus the instrument on branch
  `db-measure` (query/kernel.av, `AVRA_DB_GRAPH`). The compiler is one
  `make avra` over main's cached compiler.
- Machine: Sprite `avra-unions-p2-b` — Linux 6.12 x86_64, AMD EPYC,
  8 cores, 8 GB, no swap. Timings are this machine's; the Mac figures
  quoted from documents are not comparable in absolute terms.
- Every compiler run: `AVRA_MEM_CEILING_MB=5000`.
- Raw output: `tools/db_measure/raw/`.

## The harness

| file | what it does |
|---|---|
| `query/kernel.av`, `AVRA_DB_GRAPH=1` | a line on stderr per family registered (`F`), input set (`I`), cell settled with the keys it read (`G`), frame abandoned (`A`), family evicted (`E`), and the recorded reads so far per family, repeats included (`C`). Off, it is one `Cell<bool>` read per recorded read. |
| `graph.py` | M1's table per family; M2's rule simulated on the graph; `--m1` the table alone; `--qtrace` `AVRA_QTRACE`'s asks per family |
| `warm_edit.sh` | cold check, two no-ops, N fresh-text one-literal edits per scenario, then the same edit under each trace |
| `digest_bench.sh` | the tree's own `core/digest.av`, compiled natively, timed |
| `readbench/` | one row read: a list, a relation, a recorded relation |
| `hist_point.sh`, `archive.sh` | one historic commit bootstrapped from its own seed and run through `warm_edit.sh` (used once, for 09-21) |

Re-run M1/M2 from a tree root on a Sprite:

    find . -name .avra-cache -type d -prune -exec rm -rf {} +
    AVRA_DB_GRAPH=1 build/avra check packages/cli 2> build/dbm_graph.txt > /dev/null
    python3 tools/db_measure/graph.py build/dbm_graph.txt packages/std-avrac/src/compiler/families/families.av

Re-run M3: `sh tools/db_measure/warm_edit.sh 3` and
`sh tools/db_measure/warm_edit.sh 3 <package> <label> <file> <literal>`.

## M1 — the fine graph

Scope: ONE cold `check packages/cli` (467 source files read), one
kernel, the graph as last settled. Raw: `raw/m1m2_cli.txt`.

| | |
|---|---|
| cells settled | **70,015** (none settled twice) |
| inputs set | 467 `Source` + 19 `Manifest` |
| direct dependency edges (deduplicated per cell) | **5,314,590** |
| recorded read calls, repeats included | **37,230,882** (7.0 per edge kept) |
| the graph as text | 45.7 MB (8.6 bytes per edge) |

This settles the three quoted figures: ticket avra-8sb5.76's "5.1 M live
deps" and PR #289's "5.3 M boxed Key edges" are this number. "≥51.6 M
deps" is not an edge count on this input; the nearest quantity of that
size is read CALLS (37.2 M here). I could not reproduce 51.6 M itself.

Per family (cells · edges out · edges in · read calls), the rows that
matter:

| family | key | cells | edges out | read by (edges) | read calls |
|---|---|---|---|---|---|
| Typed | DeclId | 13,626 | 1,881,268 | 13,768 | 13,768 |
| Lowered | ask-int | 12,324 | 1,067,477 | 0 | 0 |
| Settled | settle-int | 501 | 810,693 | 475 | 528 |
| Sig | DeclId | 13,240 | 804,506 | 1,566,564 | 3,022,206 |
| MethodDiags | FileId | 438 | 435,372 (994 each) | 438 | 438 |
| Syntax | DeclId | 12,608 | 25,216 | 491,004 | 505,639 |
| Methods | DeclId | 1,002 | 8,183 | 452,849 | 628,258 |
| Items | FileId | 458 | 458 | 243,302 | 14,463,501 |
| Named (name buckets) | int | 0 (never settled) | 0 | 2,267,786 over 10,442 buckets | 17,815,389 |
| the three std-relation families | cell | 0 | 0 | 2 | 3 |

By key type: 54,947 cells are keyed by a file, module, declaration,
package or unit; 15,068 by a process-local ask number (Lowered, Settled,
ConstTyped, Lifted, LiftLowered). The compiler's `@std/relation` rows
are almost absent from the kernel's graph: declaration reads are
recorded as `Named` / `Items` / `Methods` kernel cells.

Bytes today — `AVRA_MEM_STATS=1 build/avra check packages/cli`, cold,
peak 1,867 MB (`raw/memstats_cli.txt`, sites named by `llvm-symbolizer`):

| site | live | per unit |
|---|---|---|
| `Kernel.newly_read` (one boxed `Key` per edge) | 375 MB in 5,314,590 boxes | **74 bytes per edge** |
| `Kernel.begin` (a cell's pending list) | 70 MB for 70,015 cells | **~1,050 bytes per cell** |

So the graph's bookkeeping is ~445 MB of a 1.87 GB peak in memory, and
46 MB as unpacked text.

Same run on `check packages/std-avrac` (867 files,
`raw/benches_store_avrac.txt`): 96,690 cells, 5,864,967 edges,
39,171,691 read calls.

## M2 — under "a durable key is saved"

Scope: the M1 graph of the cli, replayed offline. Nothing was persisted.
A cell keyed by FileId / ModuleId / DeclId / package / unit is SAVED; a
cell keyed by an ask number is IN MEMORY and its reads fold up into
every saved answer that reads it. Two readings of the rule are given
because the graph forces the question:

| reading | saved answers | direct durable reads: total | min | median | p95 | max |
|---|---|---|---|---|---|---|
| A — keys exactly as typed today (name buckets are not durable) | 54,947 | 1,091,224 | 1 | 2 | 19 | 32,114 |
| A+ — name buckets and relation cells count as durable inputs | 54,947 | 3,359,012 | 1 | 3 | 510 | 41,435 |
| file grain (what main keeps today; declarations fold into files) | 4,184 | 2,672,522 | 1 | 5 | 5,090 | 12,915 |

Under A+, per family:

| family | saved | min | median | p95 | max | total |
|---|---|---|---|---|---|---|
| Sig | 13,240 | 2 | 4 | 618 | 952 | 803,634 |
| Typed | 13,626 | 3 | 11 | 583 | 2,564 | 1,900,133 |
| Syntax | 12,608 | 2 | 2 | 2 | 2 | 25,216 |
| Names | 10,209 | 2 | 2 | 2 | 2 | 20,418 |
| Methods | 1,002 | 1 | 2 | 19 | 606 | 8,183 |
| Analysis | 458 | 6 | 29 | 207 | 688 | 27,263 |
| Folded | 458 | 4 | 29 | 245 | 701 | 27,545 |
| Visible | 458 | 2 | 76 | 126 | 417 | 31,188 |
| MethodDiags | 438 | 994 | 994 | 994 | 994 | 435,372 |
| Namespace | 76 | 2 | 49 | 592 | 975 | 7,865 |
| Receivers | 1 | — | — | — | 41,435 | 41,435 |
| References | 1 | — | — | — | 13,030 | 13,030 |

(Parsed, Items, Resolved, Plain, Admitted, Expanded, Marks: all short;
see the raw file.)

What the rule does not cover as written:

1. **Name buckets.** 2,267,786 of the 5.31 M edges are reads of `Named`
   buckets, which no query settles and no input sets. Under reading A
   they have no name and those dependencies vanish. They must be durable
   inputs, by name.
2. **Roots keyed by ask numbers.** Lowered (12,324 cells, 1.07 M edges)
   and most of Settled are read by NO saved answer — only 705 of the
   15,068 in-memory cells sit under one. "Belongs to the saved answer
   that owns it" finds no owner. They need durable keys (a declaration
   and its type arguments), or they are not saved.
3. **The long lists are the whole-program answers**: Receivers,
   References, and MethodDiags (every file's cell reads all 994 method
   tables). Everything else is short; the longest folded in-memory list
   is 516.

Encoded size. No family's value was encoded by these runs; that needs a
codec per family. MEASURED instead, what one cold `check packages/cli`
writes to `.avra-cache` today: 8,964 files, 58.4 MB — `unit` 5,010 files
/ 30.8 MB, `rows` 1,172 / 26.7 MB, `warn` 2,752 / 0.13 MB, `obj` 28 /
0.7 MB. READ, not measured: Sig/facts, Settled, Lowered units,
diagnostics and Decl rows have wire codecs; Parsed, Plain, Analysis hold
arenas or closures (no codec: blocked by that); Typed, Folded, Resolved,
Visible, Namespace, Methods have none (blocked by dense ids in their
values).

Digest cost — `sh tools/db_measure/digest_bench.sh`, the tree's `core/digest.av`
compiled natively:

| | |
|---|---|
| one 11.8 MB text | 362 MB/s |
| per keyed answer, 72 bytes | 0.63 µs |
| per keyed answer, 288 bytes | 1.35 µs |
| per keyed answer, 2.3 KB | 8.3 µs |

55 k answers at 1–8 µs is 0.05–0.5 s; all 58 MB the store holds is
0.16 s; a cold check is 63 s. Encoding is not in these figures.

`perf/witness-folded` ("13,578 direct deps over 770 files, 17.6 per
file, against 33.3 M flattened"): not rebuilt. Today's
`check packages/std-avrac` gives `Analysis` 867 cells with 37,258 direct
deps — 43 per file, median 23. Same order (tens per file) on a larger
tree that now also records name-bucket reads. The 33.3 M was the
flattened closure, which this rule never builds.

## M3 — where the one-edit time goes

No bisect was run (owner ruling). History is two points on this Sprite,
same harness, same edit (`· memo` in `packages/cli/src/commands/shared.av`,
and `<source>` in `std-avrac/src/diagnostics/render.av`):

| `check packages/cli` | 2026-09-21 `86d7009` | main `05fe643` |
|---|---|---|
| `.av` files in the tree | 680 | 1,513 |
| files the check holds | 289 (READ, COMPILER.md) | 458 |
| cold | 17.9 s | 62.8–65.1 s |
| no-op | 0.046 s | 0.20 s |
| one edit, cli file | 0.47–0.51 s | 6.1–7.2 s |
| one edit, std-avrac file | 0.36–0.46 s | 4.7–5.8 s |

The 09-21 compiler was bootstrapped from that commit's own seed and
rebuilt once from its source (`hist_point.sh`). The document's 0.18 s
was a Mac figure; on this machine the same commit is 0.36–0.51 s.

### The one-edit path today, by phase

`check --time`, edit in std-avrac (`avrac.edit2/3`, `receipt.edit2/3`),
ms. The five marks partition the derivation; `ast`, `sublang`, `bodies`
are spans INSIDE them and are not added.

| phase | ms | what was done | what the edit needed |
|---|---|---|---|
| process start | 16–20 | `build/avra --help` | — |
| load | 1,820–1,900 | the store's records met, holds asked; **1.33 M recorded reads of `HeldSig`** over 75 module cells | one module's record |
| admit | 1,075–1,200 | includes `ast` ~1,050 and `sublang` ~500: **23 files parsed**, 13 sources read | 1 file |
| analyze | 450–530 | 308–316 `Typed`, 9 files' Analysis; **all 994 `Methods` tables resettled**; 9 `MethodDiags` cells each reading all 994 | the edited body's declaration |
| lower | 720–760 | 225–232 `Lowered` cells | the edited fn |
| keep | 175–190 | (first edit after a cold run: 620–650) | — |
| wall | 4,680–4,850 | held 449/458 | |

The cli-file edit is the same shape and larger: wall 6.1–6.4 s, load
1.8 s, admit 2.1 s (`ast` 1.9 s, **50 files parsed**), 573 `Typed`,
444 `Lowered`, held 437/458.

`AVRA_QTRACE` asks per family, one edit (std-avrac file / cli file):
reuse 3,670–3,873 / 12,057; compute 675–691 / 1,299 — Typed 308–316 /
573, Lowered 225–232 / 444, ConstTyped 43 / 58, Settled 22–23 / 56,
Parsed 11 / 25, Plain 13 / 25, Items/Resolved/Folded/Analysis 9 / 21.
(The trace does not see `Methods`, `Sig`, `Syntax`, `Names`, `Admitted`
or `HeldSig`; the graph dump does: 994 Methods, 288–519 Sig, 195–373
Syntax, 81–179 Admitted, 75 HeldSig cells settled.)

### The no-op path

`check · cache hit`: 0.20 s, of which process start is 0.018 s. The
kernel does nothing — 0 asks, 0 settles, 0 files parsed, no cell
settled. The 0.18 s is outside the kernel and outside every phase timer;
this run did not split it further.

### What scales with the whole program

The same kind of edit (one string literal in one body), checked from
packages of four sizes:

| package checked | files held | cold | no-op | one edit | load | admit | files parsed |
|---|---|---|---|---|---|---|---|
| std-toml | 4 | 0.47 s | 0.13 s | 0.26 s | 6 ms | 60 ms | 1 |
| std-json | 14 | 1.03 s | 0.13 s | 0.78–0.90 s (1 attempt discarded) | 120 ms | 140 ms | 3 |
| std-http | 121 | 13.0 s | 0.14 s | **12.8–13.2 s — hold refused, held 0/121** | — | — | 195 |
| cli | 458 | 62.8 s | 0.20 s | 4.7–6.4 s | 1,850 ms | 1,100–2,100 ms | 23–50 |
| std-avrac | 867 | 64.2 s | 0.19 s | 8.4–8.7 s (1 attempt discarded; first edit 31.7 s, 2 discarded) | 3,200–3,400 ms | 45 ms | 7 |

- **no-op**: ~0.125 s fixed plus ~0.1 ms per file. Not O(program) in any
  way that matters; the fixed part is the question.
- **load**: grows with the program — ~4 ms per file held (6 ms at 4
  files, 1.85 s at 458, 3.3 s at 867), whatever was edited.
- **admit**: follows the files PARSED, and the cli parses 23–50 where
  the edit touched 1; checked from std-avrac the same edit parses 7 and
  admit is 45 ms.
- **analyze / lower**: follow the cells recomputed (hundreds of Typed
  and Lowered for a one-literal edit), plus the fixed 994 Methods.
- **A discarded attempt is paid in full and printed nowhere**: std-avrac's
  phases sum to 4.5 s of an 8.5 s wall. std-http's hold is refused
  outright for this edit, so its "one edit" is a cold check.

### The reviewer's inference: recorded relation reads

"A recorded relation read is ~938 instructions against ~90 raw, and
standardising reads onto recorded rows cost the time."

- Count, one-edit `check packages/cli` (`AVRA_DB_GRAPH`, the `C` line):
  **3** recorded reads of `@std/relation` families. Kernel recorded
  reads of every kind: 1,383,865–1,553,242, of which `HeldSig` is
  1,329,310–1,436,551, `Named` 20,920–34,544, `Methods` 11,282–24,606,
  `Items` 10,605–33,740.
- Cost, `readbench/` (ns per read, native, 20,000 rows × 50 passes): a
  list read 4; `Row.get` on a relation nothing records 35–38; under an
  owner that records, 67–75. No instruction counter exists on a Sprite,
  so the 938 / 90 figures were not re-measured; the ratio here is 17×
  recorded-relation to list, 2× recorded to unrecorded.
- Bound: 1.5 M recorded reads at 75 ns is 0.11 s; at a generous 300 ns,
  0.45 s — of a 4.8–6.4 s edit. This run did not time a kernel
  `record_at` by itself.

So the inference does not hold as stated: relation reads are not on
this path, and recorded reads of all kinds bound to under a tenth of
the time. What the phases show instead: `load` walks every held
module's record (and asks `HeldSig` 1.3 M times for 75 answers), the
cli parses 23–50 files for a one-file edit, every method table is
rebuilt on every edit, and several hundred declarations are re-typed
and re-lowered for one changed literal.

## Follow-up 1 (avra-8sb5.57.191) — why unchanged files are parsed

`sh tools/db_measure/parsed_why.sh packages/cli <file> <literal>`, main `1af10de`, `READ_NAMED` lifted by a local uncommitted patch; raw:
`raw/parsed_why.txt`. `Q parse` fires twice for most files — once for the
plain parse, once under block words — so "23 parses" is 13 files and
"50 parses" is 25 files.

Edit in `std-avrac/src/diagnostics/render.av` — 13 files parsed, 1 needed:

| files | parses | the hold's reason | group |
|---|---|---|---|
| `std-avrac/src/diagnostics/render.av` | 1 | its text moved | the edit |
| `cli/src/main.av` | 2 | the entry | always read |
| `std-cli/src/cli.av` | 2 | none printed — held; parsed as `main.av`'s block-word provider | provider of a read file |
| `std-http/src/{auth,cookie,form,guard,observe,quota,ws}.av` | 14 | none printed — **no record knows them** (`held 452/461`, 9 not held, 2 named) | never kept |
| `std-http/src/{route,server}.av`, `std-time/src/time.av` | 4 | none — held; parsed as block-word providers of the seven | provider of a never-kept file |

Edit in `cli/src/commands/shared.av` — 25 files parsed: the 12 above
that are not the edit, `shared.av` itself, and 12 sibling command files
(`build check dev emit fix fmt process repr rules run test writes`), each
"nothing kept stands in: what it sees moved" with the moved key part
**"what its compile-time runs read"**.

Root causes:

1. **A module is admitted whole but kept only where reached.** `use
   @std.http.…` in `cli/src/commands/dev.av` registers all 26 files of
   module `@std.http`; the cli's uses reach 19. `admit_all`
   (compiler/whole.av:132-143) asks `items` — a parse — of every file
   that is not held, and the seven unreached files are never analysed,
   so no record line is ever written for them and they are parsed, twice
   each with three providers, on every warm run whatever was edited.
   18 of the 23 parses. It arrived with `avra dev` (#94f40e3, 10-05).
   Fix size: small — either `admit_all` skips a file nothing reaches (as
   it already skips a held one), or the module's record keeps a line for
   a parsed-but-unreached file. Hold-sensitive: cache-attacks decides.
2. **A compile-time run's key is the text of every file it read.** Each
   `command … { }` instance in the cli runs code in `shared.av` while it
   compiles, so any edit to `shared.av` — one string literal in a body —
   moves the `Runs` part of twelve files' keys. Working as designed at
   file grain; it goes away only when a run's reads are recorded per
   declaration.
3. The entry is always read (2 parses + its provider's 2).

## Follow-up 3 (avra-8sb5.57.193, first half) — `load`, split

`AVRA_LOAD_SPLIT=1 build/avra check --time packages/cli` after one fresh
edit of `std-avrac/src/diagnostics/render.av`, three rounds, main
`ada390f` + env-gated timers (compiler/derive.av `holding` /
`settle_holds`, compiler/record.av `load_named` / `meet_file` /
`read_why`). Raw: `raw/load_split.txt`. `load` is 2.00–2.03 s here
(453 of 462 files held).

| part | ms | share |
|---|---|---|
| **minting every held declaration** (`settle_holds`' last loop: `mint_module` for each of 453 held files) | 890–920 | 45 % |
| **re-keying and validating holds** (`read_why` per file) | 590–600 | 29 % |
| — of which the file's key parts (`obj_key_cached` → `key_parts`) | 460–470 | |
| — its text digest 29, `stands_in` 12, const rows 8, the rest ~80 | | |
| registering each file (`ws.file_id` in `meet_file`) | 240–250 | 12 % |
| reading and decoding module records (read 33, fields 45, fault 33, places 9) | 120 | 6 % |
| opening the store, forced reads | 85–96 | 4 % |
| `unruled` | 10 | |
| the hold worklist (`forced_runs`), `hold_only` | 0 | |
| **`HeldSig` reads inside `load`** | **0 reads** | 0 |

The 1.33 M recorded `HeldSig` reads are not in `load` at all: the count
is 0 when the holds are settled and 0 when `load` ends. They happen in
the later phases, as held rows are read.

The single change that would take the most out: mint a held module's
declarations when something first reads them instead of minting all 453
files' on every run — 0.9 s of the 2.0. The loop's own comment says why
it is eager today (a row minted inside a query arrives after its
reader, and the relation refuses a late write), so that law is what the
change has to answer. The second is the key work the ticket's step 2
names: 0.46 s.

## Follow-ups 1b and 4 — the two fixes, and who pays for a discarded attempt

**Root cause 1 of follow-up 1, fixed** (branch `db-00a-unreached-files`):
a file its module's record places is met with the files named, so a
sibling nothing names is held instead of parsed every run. One edit of a
std-avrac file, check of the cli: 13 files parsed -> 3, admit
1,075–1,200 ms -> 139–154 ms, wall 4.7–4.9 s -> 3.7 s. Root cause 2 (a
compile-time run keyed by the whole text of every file it read) is open
for DB 07.

**Every package's one-edit check** (`sh tools/db_measure/discarded_sweep.sh`,
main `982836c`, a comment line appended to one non-entry file; raw:
`raw/discarded_sweep.txt`). 40 packages; these throw an attempt away:

| package | wall | discarded | the stated reason |
|---|---|---|---|
| std-action | 14.9 s | 3,323 + 3,092 + 3,367 ms | reads the homes 83 instantiations it owes; then `src/derive.av`, then `std-meta/src/meta.av` and `src/action.av` — "a compile-time run called one of its bodies" |
| std-avrac | 10.4 s | 4,057 ms | `features/impls/tests/generic_builtin_trait/generic_builtin_trait.av` — "what its bodies ask could not be read back" |
| std-http | 14.7 s | 1,796 ms, then everything | the hold was refused (held 0/121) |
| std-relation | 2.6 s | 219 ms | reads the homes its instantiations lower from |
| std-https, std-http-soak, std-db, std-validate, std-process, std-net, std-errors | 0.3–4.3 s | 81–188 ms each | reads the homes its instantiations lower from |

The other 29 discard nothing on this edit. (An earlier edit of std-json's
`json.av` discarded 293 ms to read `std-text/src/text.av`; this sweep's
edit of `codec/codec.av` does not.)

**std-avrac's cause, fixed** (branch `db-00d-asks-read-back`): the
language's own declarations are filed under file 0 — whichever file is
first in the process — and a builtin's wire names that file. Read back in
another process it finds nothing, so a held file whose bodies ask for an
instantiation over a builtin generic (`impl Show for List<T>`) never has
its asks read: held, analysed, row unread, attempt discarded, file read,
every time. Not special to a test program — a three-file fixture
reproduces it. A builtin's wire is now resolved by name. One edit, check
of std-avrac: 10.4 s -> 5.5 s, discarded 1 -> 0.

## Two entries over the same modules, and what the builtin word costs

Sprite `avra-unions-p2-b`, main + the unreached-files fix, every store
cleared first; `tools/db_measure/hist/two_entries*.sh` (untracked scratch).

1. **Cold `check packages/cli`, then `check --time packages/std-avrac`:
   held 0/944**, a full cold derive (61 s). `avra cache held` says "it was
   never built here" of all 944. READ: a module's record is keyed by the
   root (`record_key` = compiler, `self.root`, module —
   compiler/record.av:50), so two roots never share a record.
2. **Then one edit of the cli: held 460/462, 3.7–3.8 s, nothing
   discarded** — as before std-avrac was checked. The check path is
   unharmed.
3. **`avra cache held` on the cli at that point: 349 held, 122 read**; 81
   files "what it sees moved"; 143 moved-interface notes; 104 differing
   interface lines, 104 of them naming a builtin. The inspection walk has
   the same root and no entry, so a different first file, and a builtin's
   wire names the first file. Measured cost of that spelling: a wrong
   report, not a lost hold.
4. **One file, then its directory** (`check` of `fns_test.av`, then
   `check --time packages/std-avrac`): the one file derives the package
   cold (0/944); the directory holds 883/944 and throws away four
   attempts, 27 s — 4.0 s "asks could not be read back" (fixed by
   `db-00d-asks-read-back`), 7.0 s "reads the homes 1381 instantiations
   it owes", 8.0 s and 8.2 s "a compile-time run called one of its
   bodies". No interface reported moved.
5. **`check` then `build` of the cli: held 0/471.** A check makes no
   objects.

std-http's refused hold (avra-8sb5.57.190): the held attempt refuses
with "`string` does not implement `Respond`" (route.av:182) because an
`impl Respond for string` in a held file aims at a builtin whose wire did
not read back. With `db-00d-asks-read-back`: one edit 14.7 s -> 1.8 s,
held 0/121 -> 111/121, refused 1 -> 0.

std-action's three discarded attempts (avra-8sb5.57.194): the first
derivation stands but owes 83–86 instantiations' verdict and is let go
for the homes; the next finds a compile-time run calling a body in the
held `src/derive.av`; the next finds `std-meta/src/meta.av` and
`src/action.av`; the fourth stands. One round per discovery, 1.6–2.4 s
each. Unexplained: the EDITED file `src/action.av` is named in the third
turn as newly read.

Correction to M3 above: the 1.33 M recorded `HeldSig` reads are not in
`load` (0 when it ends); they happen in analyze and lower.

## Not measured

- The encoded size of any family's value under a new codec.
- Instructions per read (no PMU or `perf` on the Sprite).
- Where the no-op's 0.18 s goes.
- Which commits introduced which cost (no bisect).
- `build`, only `check`.
