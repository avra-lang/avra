# HANDOFF — the sub-300 ms warm edit

Everything learned in the session that took `packages/cli` from **~5.0 s** to **1.64–1.79 s**
for a one-comment edit, and the exact state of the work toward 300 ms. Written for an agent
picking this up cold.

---

## 1. The mission

Edit **one comment** in `packages/cli`, then `check` the package. It must finish in **< 300 ms**.
Today it takes **1.64–1.79 s**. The number is reproducible; the methodology in §4 is what makes
it so.

A second, larger target is the compiler's own package: `packages/std-avrac` takes
**3.47–4.08 s** for the same shape of edit.

---

## 2. Repo state

- Worktree: `/Users/tristan/projects/tristanMatthias/avra-hd-int`
- Branch: `hd-clean` (tracks `origin/hd-clean`, **pushed, clean**)
- Base: `76504d55` (which sits on `origin/main` `5f65f027`)
- HEAD: `7c3bcd8d`
- **14 commits** on top of the base, all pushed:

```
7c3bcd8d place: a position is a TOKEN identity, resolvable with a lex alone
d1f91bc0 store: a file's warnings are kept as DATA, their places anchored to the declarations
4aa3bebf bench: drop the marker left in shared.av by the warm-edit measurement
eaf783a4 record: a file's parse digest rides its `file` line — the column a comment cannot move
9a5e83dc store: one predicate answers whether a row stands — file_row asked a second one
12e908db time: the phases are the WORKSPACE's — a Program's copy stopped at `analysed`
df699f30 store: the held set's name carries no count — the writer and the reader disagree about it
7b71f6ce store: the held set belongs to ONE program — name it by file count, never write an empty one
19abfe7d docs: correct the seal claim — a threshold exists, and it scales with the store
0857cbda store: one reverse index per suspect computation, not a scan per fixpoint round
4db48bd8 docs: a warm edit's cost grows with the store's AGE
ae4f4c67 docs: ruled(okey) and file_ruled(path) answer different questions
3520899a docs: the hold's remaining cost, measured
63d74a94 sig: a held declaration's signature is its record's — sigs 2.19 s -> 58 ms
```

There is **no PR**. `hd-clean` has no open pull request and the gate would be red for a reason
that predates this work (see §9). Do not open one without reading §9.

Docs written along the way: `docs/2026_10_27_ONE_STORE.md` (the campaign doc — read it; it holds
the codec survey and the "build the codec THIRD" order), plus this file.

---

## 3. Numbers, end to end

| what | before | now |
|---|---|---|
| `packages/cli`, one comment edit | ~5.0 s | **1.64–1.79 s** |
| `packages/std-avrac`, same | — | **3.47–4.08 s** |
| `sigs` phase (signature computation) | 2 190 ms | **5–58 ms** |
| store aged by 7 package checks, cli edit | 7.58–8.10 s | **1.93–2.39 s** |
| store aged by the full spec suite, std-avrac edit | 11.5–12.4 s | **7.5 s** |

Current phase profile, `check packages/cli --time`, one comment edit, fresh store:

```
roots 0  names 141  rows stand 72  loaded 20  held only 0  interfaces 237
ast 110  sublang 87  pending 162  runs 0  settle 163  parse 0  resolve 123  sigs 59
bodies 234  held 577/579  attempt 0  load 699  admit 9  analyze 469  lower 57  keep 220
                                                                              wall 1.64 s
```

`check packages/std-avrac --time`, warm:

```
names 280–340  rows stand 470–875  loaded 55–67  interfaces 815–1240  unruled 280–450
ast 70–80  sublang 46–56  resolve 158–196  sigs 4–6  bodies 330–350
held 1275/1276  load 1500–2560  analyze 530–700  lower 43–58  keep 600–800   wall 3.5–4.1 s
```

**How to read these numbers.** `--time` prints per-phase durations **grouped and summed**; the
phases nest (`interfaces` contains `names`+`rows stand`+`loaded`+`held only`; `load` contains
`holding()` and `unruled`; `analyze` contains `ast`+`resolve`+`sigs`+`bodies`). The sum of the
printed numbers can exceed the wall clock. Use them for *relative* sizes, never as a budget.

**Where the 1.66 s goes, in two blocks:**

- ~920 ms — bookkeeping for the 577 files you did not touch (`load` 699 + `keep` 220)
- ~470 ms — parse + resolve + type the 2 files that were read (`analyze` 469)

**1.35 s of the 1.66 s is answering a question the edit did not change.**

---

## 4. How to build and measure (this matters more than it looks)

```sh
export LLVM_PREFIX=/opt/homebrew/opt/llvm
cd /Users/tristan/projects/tristanMatthias/avra-hd-int

# the compiler, under the machine-wide watchdog (one heavy process at a time)
cp build/avra build/avra.pre          # ALWAYS: a failed link DELETES build/avra
AVRA_DISK_FLOOR_MB=300 timeout 1700 sh ../avra/tools/watch.sh 7000 make -s avra

# a package's spec cases (the compiler's own, ~2 min, peak ~4 GB)
AVRA_DISK_FLOOR_MB=300 timeout 1500 sh ../avra/tools/watch.sh 4200 \
  ./build/avra test packages/std-avrac/src/compiler/tests/*_test.av
```

**Benchmark scripts already written** (in `/tmp`, they survive; recreate if gone):

- `/tmp/ed2.py` — toggles `memo's` ⇄ `memozz` in `packages/cli/src/commands/shared.av`
  (a comment in a doc block; **always leaves the file modified — restore it**).
- `/tmp/ed8.py` — increments a `vN` suffix on a comment in
  `packages/std-avrac/src/compiler/kept_settle.av` (guarantees a cache miss each run).

The loop that produces trustworthy numbers:

```sh
rm -rf .avra-cache
./build/avra check packages/cli >/dev/null 2>&1      # cold derive, populates the store
./build/avra check packages/cli >/dev/null 2>&1      # warm
python3 /tmp/ed2.py; /usr/bin/time -p ./build/avra check packages/cli   # the number
python3 /tmp/ed2.py                                   # restore the file
```

**Three measurement traps, all hit for real:**

1. **Clear `.avra-cache` before any A/B whose answer you will believe.** A store aged by other
   work changes the number by up to 4× (§7). Most of the "variance" in this session was store
   age, not noise.
2. **A same-length edit can be a cache hit** (50 ms) if the program key does not move; a
   length-changing comment edit is a miss (~1.6 s). Know which one you are timing.
3. **After any trapping / out-of-disk run, delete `.avra-cache`.** A poisoned store produces
   nonsense: `internal compiler error: nothing declares … — the program is not closed`, or
   `index N is out of bounds (length M)`, on a clean tree. Both happened; both were cured by
   `rm -rf .avra-cache`.

**Disk is scarce (~3–4 GiB free on a 926 GiB volume).** `.avra-cache` grows ~200 MB–1.2 GB per
package-derive batch. Reclaim by deleting **stale** `avra-*/build` directories (they are 60 MB to
1.7 GB each; anything dated two days back is dead):

```sh
cd /Users/tristan/projects/tristanMatthias
for d in avra-*/build; do [ -d "$d" ] || continue
  case "$d" in avra-hd-int/build|avra/build) continue;; esac
  [ "$(stat -f %Sm -t %Y%m%d "$d")" -gt 20261028 ] && continue
  rm -rf "$d"; done
```

**Before every commit:** `./build/avra fmt --write <changed .av files>` — the pre-commit hook
refuses non-canonical staging.

---

## 5. The architecture, as it stands

### The shape of one `check`

`build.av` → `confirmed_key` → (hit? print stored warnings : derive) → `derive.av`:

```
derive(at)
  tried_anew          a FRESH workspace; lead_reads pre-seeds known reads
    tried
      holding         ("load")   open the store; bare_interface per module ("names");
                                 holds_asked + file_rows_stand per file ("rows stand");
                                 load_interface for files that did not stand ("loaded");
                                 resolve_pending_reads/read_unkept ("pending");
                                 met_unread/read_runs ("settle")
      unruled         ("unruled") held files whose rule findings were never kept
      admit_all       ("admit")
      analysed        (program, "analyze")  parsed → resolved → sig_diagnostics → bodies
      bodies_lowered  ("lower")
      kept            ("keep")  keep_interfaces, keep_const_units, adrift check,
                                keep_asks/keep_codes per file, keep_unit_rows,
                                keep_instances, all_said
      stood           writes the manifest + the held set
```

### The hold

A file is **held** when a record can answer for it: it is minted from the module's stored
interface instead of being parsed. A file that is *not* held is **read** (parsed, resolved,
typed, lowered). On a warm edit, **577 of 579** files are held; 2 are read.

The held set is a durable row (`held_set_key`) listing the paths a derivation confirmed
standing; `holds_asked` asks only files it does not confirm, plus files the reverse index names
as having read a moved input (`suspect_rows`).

### Key files

| file | holds |
|---|---|
| `compiler/whole.av` | `Program` (no `phases` field — it is the workspace's), `analyze_all`, the phase clock |
| `compiler/derive.av` | the derivation, `Derived`, the `--time` printer, `unruled`, `kept`, `missing_rows` |
| `compiler/workspace.av` | `Workspace`, `Keys` (all the `Cell<Map>` caches), `sig()`, `timed()` |
| `compiler/workspace_analysis.av` | analysis families, `held_okey`, `settle_result` |
| `compiler/filesaid.av` | `FileRead`, `KeyParts`, `suspect_rows`, `file_kept`/`file_judged`, `held_set`, `file_row` |
| `compiler/record.av` | `record_of`, `file_lines`, `iface_digest`, `bytes_key`, `held_paths`, `keep_interfaces` |
| `compiler/interface.av` | `FileLines`, `fill_ensured`, `mint_files`, `link_file` |
| `compiler/store/{store,pack,body}.av` | the pack, the reverse index, sealed bodies |
| `compiler/build.av` | `program_key`, the manifest, `confirmed_key`, the `check` entry |
| `compiler/db.av`, `compiler/leaves.av` | durable `Db`/`DbRow`, `named_sigs`, `sig_digest` |
| `compiler/rel_loc.av` | a place kept as (declaration, offset within it) + its wire |
| `compiler/diag_wire.av` | `DiagFacts` on the wire, `Loc`s anchored (Workspace methods) |
| `compiler/token_place.av` | **new**: a place kept as (token index, offset into it), `token_digest` |
| `diagnostics/{mod,render,source}.av` | `Diag`, `DiagFacts`, `render_facts_among`, `new_source_file` |
| `grammar/lexer.av` | `lex_source(text)`, `lex_blocks(...)`, `Token { kind, text, span, raw }` |

### The record (`record_of`, `record.av:500`)

One text blob per module, one line per fact. The `file` line now carries **8** columns:

```
file <path> <text-digest> <reads-field> <iface> <idents> <global> <syntax-digest>
                                          4         5        6        7   <- appended by eaf783a4
```

- `iface` = `iface_digest(lines)` — declaration **contracts** only, deliberately body-free, so a
  body edit moves no dependent.
- `global` = `global_digest(lines)` — placed contract lines.
- **`syntax`** = `fingerprint_of_parsed(parsed(f))` — structural fingerprints + block words,
  **body-inclusive and comment-free**. This is the column that answers "did only a comment move?"

---

## 6. What landed, and why

**`63d74a94` — a held declaration's signature is its record's.** `sigs` was 2 190 ms because ONE
declaration (`program_arg` in `cli/commands/shared.av`) walked 414 held declarations recomputing
signatures from source; a single nested compute took 1.93 s. `Workspace.sig` now fills the held
row (`fill_ensured`) and settles `Family.Sig` on it. → **2 190 ms → 5–58 ms; 5.0 s → 1.8 s.**

**`0857cbda` — one reverse index per suspect computation.** `pack_suspects` scanned the whole
open index on *every fixpoint round*; the sealed body already had a per-name reverse.
`pack_readers` builds it once and `pack_suspects(pack, moved, readers)` looks each moved name up.
→ aged-store cli edit **7.58–8.10 s → 1.93–2.39 s**. (A cached version keyed on a write counter
under-approximated and the hold caught it — the reverse must be *derived*, never remembered.)

**`7b71f6ce` + `df699f30` — the held set belongs to ONE program.** `held_set_key` named the row by
`root + entry + want`, which a package's `check` shares with the test programs beside it; one
derivation's set overwrote another's, and a derivation that held *nothing* wrote an empty row
naming every file as untrusted. Fix: never write an empty set. (I then tried adding the program's
file count to the name — measured **worse**, `holds 491 → 1276`, because a derivation admits files
as it walks; reverted in `df699f30`.) → after a full suite run, **11.5–12.4 s → 7.5 s**.

**`12e908db` — the phases are the workspace's.** `Program.phases` was a *snapshot* taken inside
`analysed`, so `keep` and everything instrumented inside it never printed. Two builds were wasted
chasing a cost the instrument could not show. Field deleted; readers use `program.ws.phases.get()`.

**`9a5e83dc` — one predicate for a row's standing.** `file_row` verified every read with
`get_valid` while `file_kept` answered the same question from the suspect set. One road now.
Neutral on the clock; kept as a deletion of a second road.

**`eaf783a4` — the record's `syntax` column.** + `compiler/tests/record_syntax_test.av`.

**`d1f91bc0` — a file's warnings are kept as DATA.** `keep_warning_facts` writes one row per file
through `diag_facts_wire` (hex text form), `warning_facts_of` reads it back against the current
parse. + `compiler/tests/warning_facts_test.av`.

**`7c3bcd8d` — a position is a TOKEN identity.** `compiler/token_place.av`:
`tokens_of`, `anchored_at(text, Loc) -> Anchored`, `placed_in(text, Anchored) -> Loc?`, and
`token_digest(text)` — the file's token texts folded, comments and inter-token space gone.
+ `compiler/tests/token_place_test.av` (5 cases).

**Tests:** `packages/std-avrac/src/compiler/tests/*_test.av` = **1 646 passing**. Earlier in the
session, `features` 343, `core` 331, `grammar` 157, `diagnostics` 46 also passed; they have not
been re-run since `eaf783a4`/`d1f91bc0`/`7c3bcd8d` and should be before any landing.

---

## 7. Every experiment, with its measurement (so nobody rebuilds them)

All of these were built, measured and **reverted** unless noted.

| # | hypothesis | measurement | verdict |
|---|---|---|---|
| 1 | `sigs` recomputes held signatures (see §6) | 2 190 → 58 ms | **KEPT** `63d74a94` |
| 2 | store-level precise suspects: `Reading { name, digest }` through `pack_suspects`/`sealed_readers` | still named all **491** files | wrong — a reader records its own FILE-NARROWED view, not the module's whole answer |
| 3 | `unruled` using `file_ruled(path)` instead of `ruled(okey)` | `Q attempt 1 hold false reading 13180`, `held 0/1276`, **46 s** | the two answer different questions (`has` vs judged); reverting restored the hold |
| 4 | delete the object-keyed `rules`/`findings` rows, keep the path-keyed pair with plain `has` | `held 0/1276`, **46 s** | the path-keyed pair **spends the empty value** (no findings ⇒ no row ⇒ "not kept") while `keep_once` keeps it — not duplicates, both are load-bearing |
| 5 | `file_judged` positive-only memo | slower | `Cell<Map>` copy on `get()`; `map_cell` is the shared slot that would fix it |
| 6 | scan record LINES for `const\t` instead of `record_fields` | neutral | `record_fields` is cached; `names` pays for it anyway |
| 7 | `held_okey` using `file_kept` instead of `file_judged` | neutral/slightly worse | adds a check, saves nothing |
| 8 | file count in `held_set_key` | `holds 491 → 1276` | the count at read ≠ at write (a derivation admits as it walks) |
| 9 | seal threshold (`due = max(SEAL_FRAMES, (records+sealed)/2)`) as the aged-store cost | `opened_at` = **2–3 ms**, 10 segments, 11 bodies | not the cost; the doc claim was corrected |
| 10 | `pack_readers` caching keyed on a write counter | hold refused (`load 10 ms`) | under-approximated rows written after the build; replaced by a per-computation index (§6) |
| 11 | token digest inside `input_line` (every key line) | **4.1–4.4 s** | lexes all 580 inputs per run |
| 12 | token digest in a per-file row + `trivia_only` to stop the `seen <module>` suspect seed | suspects **491 → 83**, wall **1.97–2.51 s** | the 491 judgements were only ~70 ms; a net loss, reverted |

**Measured facts that are simply true (not hypotheses):**

- `file_judged` = **618 ms** for 2 489 calls (0.25 ms each) on a std-avrac edit; the store read
  inside it is **37 ms** — the cost is resolving each read (`read_stands` → `KeyParts`, stamps,
  forms).
- `held_okey`'s sub-costs: `at` 1.6 ms, `is_held` 1.9 ms, `okey_row` 2.3 ms, **judge 618 ms**.
- `pack_readers` = 0 ms, 5 rows. `opened_at` = 2–3 ms.
- Every parsed cli file is parsed **twice** — by design: `parse_program` is called once per file
  plain and once under block words, guarded by `parsed_under_blocks`'s `words.is_empty()`
  short-circuit. `main.av`, `shared.av`, `std-cli/src/cli.av` import block words, so they pay it.
- One `alert` edit produces **491 suspect files** because the seed is a module's NAME, and
  `held 1275/1276` afterwards proves the interface did not move.
- A warm **unchanged** `check` is a cache hit: ~13–55 ms (`judge` 13–55 ms, `load` 0.3–1.2 ms).
- `load` includes `unruled`; on std-avrac `unruled` is 280–450 ms and is `held_okey` per held file
  — whose keys `kept`'s `adrift` needs anyway.
- `keep` on std-avrac: `i ifaces` ~290–320 ms, `i said` ~250–260 ms, everything else ~0.

---

## 8. The design conclusion (first principles)

A comment edit changes **the bytes** and therefore **the positions**. It changes **no token**.
Everything the compiler derives is a function of tokens, so no derived *content* is stale — only
the *positions printed*.

Therefore: **never store a position.** Store the identity; compute the position when you print.

The smallest identity for a place that is (a) untouched by trivia and (b) cheap to resolve is
**(token index, offset inside that token)**:

- byte offset — fails (a);
- declaration + offset — passes (a) for comments *outside* the declaration, fails *inside* it
  (this is `rel_loc`, which is why it was the wrong tool for this path);
- node id — passes (a) but needs the **parse** to resolve;
- **token index** — passes (a) exactly, and resolving needs only the **lexer** (no grammar, no
  parse, no declaration table, no minting). That is `token_place.av`.

Same grain decides reuse: **`token_digest`** — equal digests mean a parser over that stream would
answer the same words, so a file's stored answers may be reused. Asking it costs a lex.

The three committed pieces are exactly this substrate: the record's `syntax` digest (the question),
warnings as data (the payload), token identities (the places).

---

## 9. The remaining plan — the hit path (this is the 300 ms)

**The blockers are measured, not guessed.** Today the fast path is not taken because the program
key folds each input's **text** digest (`input_line`, `build.av:753`), and the warnings are stored
as a **rendered string** keyed under that key (`db.warn(store, key0)`), so reusing them across a
comment edit would print yesterday's line numbers.

### Step A — make the manifest able to say "only trivia moved"

- Per read file, keep its **token digest in its own row** (`Stored.Unit`, key
  `node_key["tokens", root, path]`), written in the keep path (`derive.av`'s `file_said`, next to
  `keep_token_row`-style helpers). **Do NOT put it in `input_line`** — that lexes every input on
  every run (measured: 4.1 s, experiment 11).
- `confirmed_key` (`build.av:637`) asks, when the strict manifest fails: for each `.Input` entry,
  does the file's token digest equal the kept one? (`input_trivia_only(store, path, line)`.)
  Only the files whose *text* moved are lexed — one file for a comment edit.
- If every entry stands or is trivia-only, and at least one is trivia-only → the **shape stands**.

### Step B — on that hit, build the warning text per file

- Unchanged file → its stored **rendered** row (`said_row`) is still correct: its text did not
  move. A string copy.
- The moved file → re-render from its **facts row** (`warning_facts_of`) against a lex of its text,
  with places resolved by `placed_in` — this is why the facts row must be re-keyed from
  declaration anchoring to **`token_place`** (Step C).
- Print.

### Step C — re-key the facts row to `token_place`

`d1f91bc0` writes facts through `diag_facts_wire`, whose `Loc` crosses *anchored to a declaration*
(and decoding needs `decl_from_ref`, i.e. the declaration table — the expensive thing). Replace
that encoding with `TokenPlace`, so the row needs only a lex to read back. `compiler/token_place.av`
has everything: `anchored_at`, `placed_in`, `tokens_of`. A new wire pair will be needed;
`tools/codecs.py` **refuses an unregistered pair**, so register it in `compiler/codecs.av`'s
`codec_pairs()` in the same commit (see `docs/2026_10_27_ONE_STORE.md` §"Move 4" for the shape of
a row and the requirements: ids through a scope, absence as its own arm, one stamp — `store_wire()`).

### Step D — the fallback

If anything is missing (no facts row, no token row, a place that no longer resolves, a want other
than `.Diagnostics`), **fall straight through to today's derive**. Correct by construction, fast
when it can be.

### What it should cost

Read the stored key + one file's facts + one lex + one render + print. Tens of milliseconds of
real work; the rest is process start and the manifest read. The 920 ms of bookkeeping and the
470 ms of analysis disappear because neither is entered.

---

## 10. Traps and laws (each one cost real time here)

1. **A store aged by other work is up to 4× slower.** Clear `.avra-cache` before believing any A/B.
2. **A poisoned store survives.** After a trap or ENOSPC: `rm -rf .avra-cache`, always.
3. **`make avra` deletes `build/avra` on a link failure.** `cp build/avra build/avra.pre` first.
4. **`--time` phases nest and are summed**; their total can exceed the wall clock.
5. **`self.timed` phases are the workspace's.** `Program.phases` was a snapshot (fixed in
   `12e908db`) — if a phase you instrument never prints, suspect a snapshot, not your probe.
6. **An empty value is spent.** A row whose payload is `""` may not exist; `has` then answers
   false. `keep_once` and `keep_file_row` differ here — this is why the object-keyed and
   file-keyed `rules`/`findings` pairs are both load-bearing (experiment 4).
7. **`Cell<Map>` is copied by `get()`.** A memo keyed through `Cell<Map>` is quadratic once the
   map grows; `map_cell()` from `@std/relation/engine` is the shared slot. This is why a
   judgement memo measured slower (experiment 5).
8. **The baseline benchmark edits a file** — `/tmp/ed2.py` and `/tmp/ed8.py` leave the tree dirty.
   `git status` must be clean before committing; a stray marker was once committed and had to be
   reverted (`4aa3bebf`).
9. **`_ ->` is a registry hole; the licence is spelled `rest ->`** and `rest` binds nothing. Spell
   arms when you need the value.
10. **`given` blocks hold only `then` cases** — a `let` must live in a helper fn.
11. **A `use` of another module uses DOTS** (`use diagnostics.{…}`), and a private fn of a sibling
    file in the same `tests/` module is in scope with no import at all.
12. **`\u` and `\0` are not escapes** (see the project's CLAUDE.md); use `from_codepoint`.
13. **Disk games**: ~~`df` is noisy~~ — delete stale `avra-*/build` dirs, never the live ones.
14. **`index N is out of bounds` on a clean tree** after a trap means a poisoned store, not a bug.
15. **The full-package suite (`avra test packages/std-avrac`) cannot gate this branch**: the
    *pre-fix* binary traps with `index 308 is out of bounds (length 298)` and the fixed one peaks
    at 6.6 GB here. Run the per-directory suites (`compiler/tests/*_test.av` etc.) instead, and
    know that this trap predates every commit in §2.

---

## 11. Open questions

- **`keep` for cli is 220 ms for TWO files.** On std-avrac the split was measured (`i ifaces`
  ~300 ms, `i said` ~250 ms) but for cli `keep` has never been broken down. `i said` =
  `all_said`, which reads ~580 `said_row`s — one store read per program file to re-emit warnings
  that did not change. That is the natural next target *if* the hit path is not taken first.
- **`pending` 162 ms + `settle` 163 ms for cli.** Both were traced to module-level work
  (`resolve_pending_reads`, `met_unread`/`read_runs`/`hold_only`). `unruled` is 280–450 ms on
  std-avrac and is `held_okey` per file, whose keys `kept`'s `adrift` needs anyway.
- **The store's segment/bodies growth.** `opened_at` is cheap today (2–3 ms, 10 segs), but
  `due = max(SEAL_FRAMES=32, (records+sealed)/2)` makes each segment a fraction of the store, so
  open cost is O(store size) by design. Whether to cap it is a trade (open vs rewrites) and has
  not been decided.
- **Does a spec-case suite run still poison a package's held set?** `7b71f6ce` fixed the empty-set
  wipe; a re-measurement of "after `compiler/tests`, what is `Q holds`?" would confirm it stays 491.

## 12. Quick reference: instrumented traces

```sh
AVRA_QTRACE=1 ./build/avra check --time packages/cli 2>trace.txt
grep -a '^Q	holds'        trace.txt     # how many files were asked (healthy: 491 of 1276)
grep -a '^Q	suspects'     trace.txt     # "1 edited … N suspect files"
grep -a '^Q	attempt'      trace.txt     # "hold true/false … reading N"
grep -a '^Q	parse'        trace.txt     # distinct files parsed (twice per file under block words)
grep -a '^Q	store	open'  trace.txt     # the store opened once
AVRA_MEM_STATS=1 ./build/avra check packages/std-avrac   # live bytes by category + site
AVRA_DEBUG=1     …                                      # avra_debug (no-op unless set)
```

---

## 13. The hold: what it is, what exists, what must NOT be deleted

This is the most likely thing for a new agent to get wrong, because the campaign doc
(`2026_10_27_ONE_STORE.md`) claimed for a week that "the hold is deleted". **It is not** — that
claim described `hd-sigfix`. Verified against `hd-clean` on 2026-10-30:

| what | where | count |
|---|---|---|
| `is_held(f: FileId)` | `whole.av:156` | 1 definition, **53 call sites** |
| `hold_only(path)` | `whole.av:168` | 1 definition, **2 real callers** (`derive.av:727,746`) + 3 tests |
| `held_by_rule(path)` | `whole.av:173` | the ONE rule; `hold_only` is its only writer |
| map `decls.held` | `decls` | written only by `hold_only`; read only by `is_held` |

**HELD-NESS IS THE SPEED.** A held file contributes its declarations from the module's stored
record and is never parsed. On a warm `packages/cli` check, **577 of 579** files are held; that
is the whole difference between 1.7 s and a full rebuild. **Never delete held-ness.**

What is *owed* is only the **projection**: `decls.held` is a second place holding a fact that
`held_by_rule` already answers, so `is_held` could call `held_by_rule` directly and the map
could go. That is blocked on `Want`: `held_by_rule` needs the attempt's want and ~60 consumer
sites have none in scope (recorded in `2026_10_27_ONE_STORE.md`, "Why deleting the hold is not a
substitution"). It is a **refactor with no measured win** — do it for cleanliness, never as a
speed change, and never confuse it with removing the hold.

Four symbols the old doc said were "already true" have **zero occurrences** on this branch:
`facts_restored`, `facts_kept`, `facts_codec`, `store_wire`. Do not cite that list; re-check the
tree.
