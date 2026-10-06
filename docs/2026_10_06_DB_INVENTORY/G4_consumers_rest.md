# G4 — consumers of the compiler DB, and the remainder scan

Reference main: `avra-db-design` @ origin/main `05fe643` (2026-10-05/06). All counts MEASURED by the scripts
`g4_partb.sh`, `g4_flag.sh`, `g4_cmp.sh`, `g4_grep.sh` in this directory (raw: `g4_partb_raw.txt`) unless marked.
"landed" = patch-id match (`git cherry` `-`) OR subject found in origin/main's log (squash) AND the key file/symbol present in avra-db-design.

## 0. Headline findings

| # | finding | evidence |
|---|---|---|
| H1 | The only UNLANDED DB-layer code in my whole scope is one commit: **`avra-keepers-green@01c219c` "fix(cache): a kept settlement stands only under the layout it was laid out in"** — a new `l` line kind in `kept_settle.av` (a seventh hand "stands" rule). Active lane (2026-10-05 19:49). | `avra-keepers-green:packages/std-avrac/src/compiler/kept_settle.av` diff: `+ fn kept_layout(f: FileId, s: StmtId) -> string? { … joined(["l", self.decls.crossing_layout(ty)], "\t") }`; no subject match on origin/main |
| H2 | **`avra-sources-design/docs/2026_10_05_BUILD_TIME_SOURCES.md`** (1249 lines, unlanded, 6 commits) is the biggest pending CONSUMER of the DB: it asks for two "doors" (one input door, one kept-fact door) and parks 13 questions (D1–D13) on the DB lead. Owner decided 2026-10-05 that §1 is "designed with him before anything is built on it" (§15a Q12). | doc lines 43–238, 1078–1093 |
| H3 | That doc's base (`bd36bf7`) is 9 commits behind main, and **main #282 (`04a6a89`) already fixed its defect C.23 by hand** — adding an `e` line to kept settlements and a remembered `embeds` row folded into `program_key`. This is exactly the "one more hand path" the doc argues against; door 1/2 now have one more thing to replace. | `avra-db-design:packages/std-avrac/src/compiler/kept_settle.av:151` `.concat([joined(["e", path, self.embed_said(path)], "\t") for path in distinct(embedded)])`; `build.av:538` `fn embeds_key(named)`; `build.av:593` `.concat([self.embed_line(f) for f in self.embeds(named)])` |
| H4 | **`avra dev` (landed #276/#278/#281) consumes `Workspace.build_inputs`** as its watch set. `build_inputs` does NOT list embedded files (they ride `embeds()` separately), so an edit to an embedded file is in the program key but not in dev's watch set. NOT VERIFIED by a run — read only. | `avra-db-design:packages/cli/src/commands/dev.av:292` `[Watched { path: p, mark: mark_of(p) } for p in self.lister.build_inputs(entry)]`; `modules.av:275–289` (closure files + manifests + engine sources only); `build.av:590–593` embeds concatenated after `build_inputs` |
| H5 | `avra dev` is a one-shot child `avra build` per file event, no resident compiler — matches the sources doc's Q7 pick A (still "pending" with the owner). | `dev.av:9` "A BUILD IS A CHILD: `avra build`, as anyone runs it"; `dev.av:369–373` `cmd(self.compiler, ["build", "--target", …])` |
| H6 | Every other Part A worktree is LANDED (code identical to main or squash-merged) or docs-only with no DB content. No Part A worktree has unlanded edits to `query/`, `db.av`, `store.av`, `record.av`. |  §1 table |
| H7 | Part B: 137 worktrees scanned; 3 carry live/unlanded DB-adjacent work (keepers-green, wants-modules, pipe-op); 4 are abandoned DB experiments (revert-mark, perf-kvm-revert, revert-45, impl-closure-trace); the rest landed or unrelated. | §3 |

---

## 1. Part A — per worktree

`ahead/behind` vs origin/main. "cherry +" = commits not on main by patch-id.

| worktree | branch | HEAD (sha date subject) | ahead/behind | cherry + | landed as | dirty | DB touch? | verdict |
|---|---|---|---|---|---|---|---|---|
| avra-collections-bench | collections-bench | 67c8c09 09-30 docs(collections): 3.8.1 baseline | 2/201 | 2 | #83 `d764530` (squash; `tools/bench/collections/run.sh` on main) | — | no | ABANDON (landed) |
| avra-collections-chains | detached | 44922a2 10-04 fix(pipeline) (#259) | 0/21 | 0 | is main history | — | no | ABANDON |
| avra-collections-pipeline | collections-pipeline | 06eca3a 10-01 comprehensions lower through a pipeline (E1) | 1/147 | 0 | #135 `b5e7488` | — | no | ABANDON (landed) |
| avra-mapswalks | mapswalks | ba4504c 10-02 fix(maps) one coalesce | 2/75 | 2 | #207 `8d559fc` (maps_test.av on main is a superset: 0 wt-only lines) | — | no | ABANDON (landed) |
| avra-mapswalks-order | mapswalks-order | 8f34741 10-04 insertion-order adversarial | 1/25 | 0 | #260 `461c4ca` | — | no | ABANDON |
| avra-mapswalks-pair | mapswalks-pair | b208e93 10-04 `for k, v in m` | 1/21 | 0 | #266 `5d93478` | — | no | ABANDON |
| avra-mapswalks-remove | mapswalks-remove | d7c0aa9 10-02 remove/is_empty | 1/73 | 0 | #211 `69d3d1f` | — | no | ABANDON |
| avra-deepwalks | deepwalks | 47122b5 10-02 inline-lambda lowering | 1/77 | 0 | #205 `78f88be` | — | no | ABANDON |
| avra-deepwalks-range | deepwalks-rangetype | 260bd2d 10-02 Type.Range | 1/72 | 0 | #213 `3e9d2d0` | — | no | ABANDON |
| avra-deepwalks-rangetest | deepwalks-rangetest | 33e995e 10-04 range element is int | 2/21 | 2 | #264 `2a58e7b`; fix present: `avra-db-design:core/types.av:810` `.Range -> self.intern(Type.Int),` | — | no | ABANDON (landed) |
| avra-deepwalks-seed | deepwalks-seed | 84c6de1 10-02 chore(seed) | 1/73 | 0 | #209 `d3e4ae8` | — | no | ABANDON |
| avra-files-stream | files-stream | 31e620c 10-01 static file as pulled stream | 1/110 | 0 | #177 `1e942cc` | — | no (runtime http) | ABANDON |
| avra-sql | lane/sql-fast | d23eccb 09-26 Merge main | 0/1359 | 0 | — | ` M packages/std-sql/src/parser.av` | **consumes** const settlement (see 1.1) | REWORK (tiny, re-do on main) |
| avra-won-orm | perf/won-orm | 0e6b5b4 09-29 "measure: witness ON" | 1/539 | 1 | never; flag deleted on main | — | **touches** `compiler/derive.av` (see 1.2) | ABANDON |
| avra-sources-design | sources-design | 06594b4 10-05 docs(sources): owner's decisions on §15 | 6/9 | 6 | NOT on main | `?? docs/…SOURCES.html` | **the main DB consumer design** (§2) | **KEEP** |
| avra-docs-collections | docs/collections | 87e27cb 09-30 tracker epic | 3/291 | 3 | #36 `5725537`; main's doc is newer (67 main-only lines, 3 wt-only table rows) | — | no | ABANDON |
| avra-docs-platform | docs/platform-map | c9d4035 09-30 §5 | 2/291 | 2 | #34 `13b36b8`; file SAME as main | — | mentions `@model` only as a status row (`PLATFORM_MAP.md:46`) | ABANDON |
| avra-docs-render | docs-render | 7747fb2 10-02 (#169) | 0/110 | 0 | is main history | — | no | ABANDON |
| avra-docs-validate | docs/validate-and-routes | a5f6fba 09-30 Merge main | 5/291 | 4 | #33 `2ac8df0` + #55 `b100cac`; main's STD_VALIDATE.md is a superset (0 wt-only lines) | — | no | ABANDON |
| avra-docset-close | docset-close | a41777e 10-01 H9 doc set closed | 1/133 | 0 | #146 `540369a` | — | no | ABANDON |
| avra-validate | lane/validate | 4adfe22 09-30 Merge main | 8/291 | 7 | #55 `b100cac` (squash body names derive(Decode), expressions as annotation args) | — | touches `features/decls.av` (+2 lines), `features/crossing.av`, annotations (see 1.3) | ABANDON (landed) |
| avra-validate-c | lane/validate-compiler | 8145d15 09-30 @derive(Decode) | 7/293 | 7 | #55 (same commits as avra-validate) | — | same | ABANDON |
| avra-validate-perf | lane/validate-perf | e0c255b 09-30 direct reader fix | 8/192 | 8 | #55; `std-validate/src/{json,validate,derive}.av` and `docs/2026_09_30_STD_VALIDATE.md` SAME as main | — | no (runtime decode + bench) | ABANDON |
| avra-spread | lane/spread | a69120a 09-30 test(structs) | 5/430 | 5 | #59 `a92e540`; `docs/2026_09_30_FIELD_SPREAD.md` SAME | — | touched `compiler/interface.av`, `compiler/record.av`, `core/store.av` (held record carries spreads) — landed | ABANDON |
| avra-cell-set-at | cell-set-at | efd26e5 09-30 memory: depth below a borrow's slot | 3/202 | 3 | #81 `ba3a17c` (squash body names all three subjects) | `?? tools/probe-cs/` (probe scripts, patches) | no (memory pass) | ABANDON |
| avra-cell-shared-empty | cell-shared-empty | 375e358 09-30 test(cells) | 1/223 | 0 | #60 `ff82d5a` | `?? tools/cse-probe/` | no | ABANDON |
| avra-census-sites | census-sites | f148662 09-30 | 1/210 | 0 | #76 `f05f47c` | — | no | ABANDON |
| avra-census-linux | census-linux | 250f2c5 09-30 | 1/217 | 0 | #68 `06213ff` | — | no | ABANDON |
| avra-ui-assets-design | ui-assets-design | 0b5bd64 10-05 docs(ui): assets (avra-8sb5.59.44.11) | 2/10 | 2 | doc NOT on main (`docs/2026_10_05_UI_ASSETS.md` absent); its §10 embed defects landed as #282 | — | **consumer design** (see 2.6) | REWORK → superseded by sources design §9.4 |
| avra-ui-docs-web | ui-docs-web | 63319e6 10-01 track WEB_UI.md | 1/150 | 0 | #129 `2897ae5`; SAME | — | no | ABANDON |
| avra-os-watch | os-watch-dev2 | 7a3b708 10-05 `avra dev` woken by file events | 4/7 | 3 | #278 `c2d1938` + #281 `7a999c1`; `dev.av`, `watch.av`, `std_io_watch.c`, `FILE_WATCH.md` all SAME as main | — | **consumes** `build_inputs` (H4) — landed | ABANDON (landed) |
| avra-net-copies | net-copies | cd9653b 10-01 | 1/116 | 0 | #163 `fdb68e3` | — | no | ABANDON |
| avra-channels-design | channels-design | 2d716bd 10-05 docs(flow): v4 | 5/9 | 5 | NOT on main (`CHANNELS.md` 1974 l, `CHANNELS_CANVAS.md` 193 l) | `?? docs/…CHANNELS.html` | no compiler-DB ask (see 2.7) | KEEP (not DB) |

Docs that show as "only in worktree" in the stale collections/mapswalks trees (`PROVIDE_ENV`, `UI_TARGETS_AND_WIRE`, `DECLARATIVE_BOARD`, `INLINE_HANDLER_DISPATCH_REACHABILITY`, `INSTANCE_STATE`) are files main later DELETED (#274 `0718345`, #271 `e0be066`), not unlanded work; UI-only.

### 1.1 avra-sql (dirty, uncommitted)
`avra-sql: packages/std-sql/src/parser.av` (uncommitted):
```
-const SQL_KNOWN_TERMINALS: List<string> = [...]
+/// The parser grammar prepared once, at compile time — every parse reads it, none rebuilds it.
+const SQL_PARSER: Ready = ready(sql_parser_grammar(), ["IDENT", ...])
```
Main still has the per-call form: `avra-db-design:packages/std-sql/src/parser.av:940,945` (`ready(sql_parser_grammar(), SQL_KNOWN_TERMINALS)` inside `parse_sql`).
DB relevance: a `const` holding a prepared grammar is a P4 kept-settlement consumer with a large settled value (a whole `Ready`). Worktree is 1359 behind; whether `Ready` settles as a const today is NOT VERIFIED. Value: a 10-line perf idea worth a ticket, not the tree. Verdict REWORK (re-apply on main; a good real-world test of a big kept const).

### 1.2 avra-won-orm
One commit flipping `const witness_enabled: bool = false` → `true` in `compiler/derive.av` to measure the M3 flattened witness. `witness_enabled` no longer exists on main (grep empty); #104 `85f1046` "the flattened witness and its switch are deleted". Verdict ABANDON.

### 1.3 avra-validate / -c / -perf (landed #55)
DB-relevant only as a CONSUMER class: `@derive(Decode)` is a Declares annotation — "never persisted … every annotation and derive" (sources doc §1.1 line 78), i.e. a future `RunKind.Lift` client. Nothing unlanded.

---

## 2. DB-relevant docs that exist only in worktrees

| doc | tree | lines | on main? | DB relevance |
|---|---|---|---|---|
| `docs/2026_10_05_BUILD_TIME_SOURCES.md` | avra-sources-design | 1249 | no | HIGH — §2.1–2.5 below |
| `docs/2026_10_05_UI_ASSETS.md` | avra-ui-assets-design | 280 | no | MEDIUM — §2.6 |
| `docs/2026_10_05_CHANNELS.md`, `…_CANVAS.md` | avra-channels-design | 1974 + 193 | no | NONE for the compiler DB — §2.7 |
| `docs/2026_10_05_FILE_WATCH.md` | avra-os-watch | 131 | yes, SAME | consumer of `build_inputs` (line 112: "`only(build_inputs)` after") |

### 2.1 BUILD_TIME_SOURCES §1 — "two doors" (lines 43–238)
Framing (line 45): "is there ONE general, lovely DB mechanism for a consumer like this? **No. There are two half-doors and five persistence paths.**"

**§1.1 inventory it claims (base bd36bf7; I did not re-verify each line number):**
- Inputs: 7 readers (Source family, Manifest family, `text_digest`, `digest_of_binary`, `current_listing_digest`/`current_file_digest`, `@input fn file_text`/`env_value`, `embed`), and "nearer fifteen read shapes" counting existence probes, env reads, 4 hand listing witnesses (line 74).
- Persisted facts: P1 the hold (`KeyParts = { module, path, text, runs, seen }`), P2 named rows via `Db.insert`, P3 `Db.answers` ("built and tested; **no caller outside tests**"), P4 kept settlements (`#lines` row of `u`/`c`/`m`/`f`/`b` lines), P5 kept binary/check verdict/suite. Plus 5 kept rows fitting none (`interface.av:66,85`, `build.av:719`, `derive.av:200`, `derive.av:530`, `suite.av:128`). "18 direct `Store.keep*` call sites".
- "**Never persisted:** `Lifted` and `Expanded` — every annotation and derive".
- STALE vs main: C.23 (embed edit invisible to `build`) is fixed by #282 by hand (H3). P4 now has an `e` line too; keepers-green adds an `l` line (H1). So P4 has 5→6 (main) →7 (with 01c219c) line kinds, each with its own stands rule.

**§1.3 Door 1 — one way an outside thing becomes an input** (`compiler/inputs.av`):
`InputKind { Text, Bytes, Range, Listing, Exists, Env, Pin, Tool, Target }`, `Part = { kind, name, hash }`, nine `@input fn input_*` all through `Host`.
Rules: stable names (`package:relative/path`, never absolute, never `FileId`); hash of exactly what was read (a `Range` part for a header read); a listing hashes names+kinds only; "Read and hashed fresh in each process, memoized per process. No stamp shortcut."; inputs are cells of their own, NOT rows of the `File` relation ("a row minted late in `File` is refused (C.5)").
Each run's parts go three places: an in-process kernel dep; the reading file's `KeyParts.runs` (becomes `List<Part>`); the run's own kept witness. Replaces: `embed`'s reader + `admit_embeds` (callee matched by the STRING `"embed"`), the Manifest loader, two hand-hashed listings, `text_digest`, `digest_of_binary` (+ wasm-opt/linker keys avra-8sb5.68/.69), `file_text` over `@std.io`.

**§1.4 Door 2 — one way a derived fact is kept** (`compiler/kept.av`, "P4, made general"):
`RunName = { kind, home, name, asked }`, `RunKind { Const, Seated, Lift, Model, Action, Answer, Verdict }`, `Workspace.kept(run) -> Kept?`, `Workspace.keep(run, value, witness: List<Part>)` — "Value and witness in ONE commit".
Keyed by stable name ("Never `const$<FileId>$<StmtId>`"); invalidated by re-asking each part's hash; cutoff via `verdict_fp`; inspected by `avra cache why <run>`. Replaces P4's `#lines` row, adds `Seated`/`Lift` (derive answers survive the process), arms P3 as `Answer`, replaces `Decl`'s hand witness, makes P5 a `Verdict` run.
Honest caveat it states (line 193): "Fewer than today; not yet two."

**§1.5 Bytes:** made bytes stored by SHA-256 at `~/.avra/cache/bytes/<k2>/<sha256>`, shared across compilers/worktrees (departs from "a store is ONE compiler's" "only in letter"); rows stay per compiler. Owner: yes, bytes only (§15a Q11).

**§1.7 the 13 questions parked on the DB lead (verbatim gist):**
| D | question |
|---|---|
| D1 | Is the kept run its own ticket beside avra-8sb5.57.101.12? (default: sibling) |
| D2 | Which mechanism is door 1: `@input` rebuilt over kernel cells with a stable-name→arg table, or `Memo.input` given `@input`'s face? "They are two things today." |
| D3 | `KeyParts.runs: List<string>` → typed parts in one compiler generation? |
| D4 | Kept-binary fast path runs before analysis: where are a build's input parts remembered? (main #282 answered for embeds: a `remembered` row beside the closure row — `build.av:538–556`) |
| D5 | A kept lift must be span-free: name without dense ids/offsets (today `lift$<file>$<call>$<decl>`), spans relative to the declaration, `Reach.Lookup` reads in the witness |
| D6 | Cost of fresh hashing large byte inputs per process (`digest_bytes` is an Avra loop; 1 GB/s ASSUMED) |
| D7 | Raw bytes in a content-named store outside `.avra-cache` |
| D8 | **The witness atom**: an input `Part`, or a derived-fact line with its own stands rule? "`Part` cannot hold P4's lines". And measure lines per kept run on `check packages/cli` (UNMEASURED) |
| D9 | The store's `read` (edges) slot as the witness: no read-back verb; `Keeping.Aside` drops edges; two concurrent writers; per-row deps vs townhall §6.6's pack |
| D10 | Pay avra-8sb5.57.4.6 (stale imported `@query` body) before arming `Db.answers` |
| D11 | Which of the five rows outside P1–P5 fold into the kept run |
| D12 | A per-process `input_tool` memo by name is the shape `build.av:287` refused |
| D13 | Who owns the two doors (owner: "this session with the owner; no other session exists") |

### 2.2 BUILD_TIME_SOURCES §12 — compiler changes (lines 894–926)
| # | what | where | size (doc's ESTIMATE) |
|---|---|---|---|
| C1 | `\|>` | lexer, expr_spine, `core/store.av` (a mark that restamps the fingerprint), format | ~250; in flight on `avra-pipe-op` (§3) |
| C2 | door 1 | `compiler/inputs.av`, `host/host.av`, `record.av` (`KeyParts.runs`), `kept_settle.av` (an input line), `modules.av` (`build_inputs`), `interp.av`, `core/ir.av` (`Reach.Source`), `whole.av` (delete `admit_embeds`), SHA-256 row, new `packages/std-source` | ~900, 3 landings, "A record wire change (D3)" |
| C3 | door 2 | new `compiler/kept.av` from `kept_settle.av`; `expand.av`/`workspace_analysis.av` (`Lifted` asked through it); `answers.av`; `db.av` (`still_valid`) | ~600 mostly moved; "every step under `cache_attacks`" |
| C4 | members (`icons.close`) | property-read typing fallback, `SettleRoot.Expr` | ~350 |
| C5 | artifacts and homes | lower, `build.av`/`link.av`, `target()` in `@std/meta` | ~500 |
| C6 | native tools (`@step`, `avra build --tool`, pipe protocol, actions as kept runs) | many | not sized |
| C7 | providers, eager | `expand.av`, `@std/meta` (`Provided`), `diagnostics/render.av` | ~700 |
| C8 | trait form where the impl type decides the result | traits | not sized |
| C9 | `url`, `avra.lock` | new command | ~400 |
| C10 | `avra build` compiles package C | manifest, build/link | not sized |
Proposed infra tickets: I1 embed staleness (= avra-8sb5.57.164, CLOSED by #282), I3 **75–140 KB compiler memory per generated declaration** (PROBED C.26), I4 annotation inside generated declarations dropped silently, I5 diagnostic for an unknown file renders the first source, I6 `avra_str_parses_float` has no registry row so `@std/json` cannot settle, I7 const-seat wrong-name is check-clean/traps at run, I11 `avra explain` documented and absent.

### 2.3 Every place the sources doc needs the compiler to CACHE or INVALIDATE
| § / line | need | door |
|---|---|---|
| §1.3 l.130–135 | each compile-time run reports the `Part`s it read; parts become kernel deps, `KeyParts.runs`, and the kept witness; kept binary key folds every part | 1 |
| §1.6 l.210 | add a file to a `dir` → `Listing` part moves → the holding file not held, its kept run re-settled; dependents follow the const's verdict | 1+2 |
| §1.6 l.211 | edit one file → only runs that read that `Range`/`Bytes` part | 1 |
| §1.6 l.212 | insert a line above an anchor → `Lift` run must be found by an offset-free name and hold no absolute span ("Neither is true as designed — D5"); MEASURED there: 0.04 s → 0.25 s for 1,000 generated types on a comment (C.26) | 2 |
| §1.6 l.213 | edit a provider's source → the `u` line of the unit entered → that provider's runs | 2 |
| §1.6 l.215 | swap `WASM_OPT` → `Tool(wasm-opt)` part → wasm link re-runs ("today: nothing — avra-8sb5.68") | 1 |
| §1.6 l.216 | two processes at once — PENDING D9 | 2 |
| §1.6 l.218 | delete the folder → `Listing` missing = mismatch, never "nothing to check" | 1 |
| §4.3 l.444–454 | action key = digest(compiler digest, tool's source closure, step name, args, each input's CONTENT digest, target); kept `Action` run maps action key → content digest+size; compiler upgrade re-runs every step once; shipped names are content digests | 2 + byte store |
| §4.3 l.460–461 | a const's GRANT SET (roots its literals name) is "kept with its verdict"; a per-build set of digests this build read/made gates reads of `Blob.Made` | 2 |
| §4.4 l.485 | facts for a folder planned in ONE step, kept; one file moving re-runs the whole step | 2 |
| §4.6 l.525–528 | an anchor argument (`sql(db)`) is "a kept-run lookup, so order in the file does not matter"; provider answer is a `Lift` run kept by content — "A comment edit re-splices; it does not re-run" | 2 |
| §5 L3 l.563 | "A witness is what was read, by stable name and content digest. Never a stamp, an ordinal, an absolute path." | both |
| §5.1 l.581–586 | empty cases: 0-byte answer kept as made; listing hash = (count, per entry name digest, kind); witness with no parts stands always; `Range(lo,lo)` still names the file | both |
| §7 l.647–649, 712 | tool binary "kept like any binary"; the tool opens nothing — every read is a message the compiler records as a `Part`; tool key folds the compiler's digest | 1+2 |
| §8.1 l.742–751 | cost table: "Every '0' in the middle columns is door 2. Without it each is the cold number, per process" | 2 |
| §8.4 l.760 | `avra dev`: file event → one-shot `avra build`; fast "because of door 2 and kept actions, not because anything stays alive" | 2 |
| §8.5 | later: `[build] cache = "https://…"` remote cache, asked on local miss; action rows "believed" | 2 |
| §10 l.860–864 | other consumers: `embed` (door 1); every derive/annotation `@json`, `@model`, `@relation`, `@form`, `@derive(View)` as `Lift` runs ("The compiler's own tree is the first beneficiary"); `@query` answers as `Answer` runs; the `Decl` row behind `avra docs`; wasm-opt/linker identity as `Tool` | both |
| §11 l.877–890 | slices 1 (door 1) and 2 (door 2) "are the gate. Nothing in §8 is true before 2." | — |
| CLI l.1006 | new: `avra lock`, `avra build --tool`, `avra cache gc`, `[build] cache`, `avra.lock` | — |

### 2.4 Owner decisions already taken (§15a, 2026-10-05)
Q1 native tools; Q2 `api.Pet` type path; Q3 land the trait form; Q4 home by size; Q6 `url` + lock in this campaign; Q8 compiler upgrade re-runs steps: yes; Q9 `avra build` builds package C; Q10 `check` may run a native tool: yes; Q11 machine-wide byte store: yes, bytes only; Q12 doors owned by "this session with the owner". Pending: Q5 (tool that links C), Q7 (`avra dev` one-shot — already how main works, H5).

### 2.5 What is not on main and still valuable (sources-design) — verdict KEEP
- The first-hand inventory of read shapes and kept paths (§1.1) — a ready checklist for "every derived fact goes through one layer". Needs a refresh against 05fe643 (embed `e` line, `embeds` row; keepers-green's `l` line).
- D1–D13 as the DB design's open-question list from its first external consumer.
- The hostile-case table §1.6 as cache_attacks cases.
- Its stated corrections of its own v1: no mtime/stamp fast path, no resident compiler, no persisted kernel edges (follows townhall §6.5a "2.54 M keys, 51.6 M direct deps").

### 2.6 UI_ASSETS.md (avra-ui-assets-design) — REWORK / superseded
Asks of the compiler (`UI_ASSETS.md:86–94`): an `asset` declaration "read as a build input (octets and directory names), settled at check"; folder → generated record; `trait Asset` kinds "collected program-wide"; "reach per member of a settled record"; "`collect … reached`" (a collection of only what is reached); `project() -> List<Artifact>` where "`make` runs on a cache miss"; `target()`.
Law 9 (line 74): "A file's public name is its KEY (source bytes ⊕ recipe ⊕ codec version) — one derivation for the cache entry and the shipped name." — the sources doc §9.4 explicitly CHANGES this to the content digest and replaces `asset` with `const` + pipeline.
`avra dev` (line 115): "A changed file re-settles its handle and reloads that node."
Its §10 embed defects are fixed on main by #282. Remaining unique DB ask: **`collect … reached`** (reach-filtered collection) — not in the sources doc's C-list by that name (it uses "reached statics of an artifact type", C5).

### 2.7 CHANNELS docs — no compiler-DB ask
`CHANNELS_CANVAS.md:129–135` "### The compiler: not a channel — `query/fixpoint.av:205-231`, `query/kernel.av:69-70,432-527` … worklists, a frame stack and a sink list. One task, no wait, no second party." Uses `@relation`'s stable encoder for `queue … of T` (`CHANNELS.md:906` "generates T's encoder and decoder with the same machinery `@relation` uses") — a std-relation `stable.av` consumer at RUN time, not the compiler cache. `@store type Main` is a program store (sqlite), unrelated to `compiler/store.av`.

---

## 3. Part B — remainder scan (137 worktrees; script `g4_partb.sh`)

Flag rule: unlanded commits or dirty files touching the listed DB paths, or subjects matching the keyword list. Many keyword hits were false ("held as a draft", "holds a fn") — triaged by opening the commits (`g4_flag.sh`).

### 3.1 FLAGGED — real DB-layer content

**avra-keepers-green** (branch keepers-green, 4 unlanded, HEAD 5f495f5 2026-10-05) — ACTIVE
- what: `01c219c` fix(cache): a kept const verdict is keyed beside the LAYOUT of every declared type its answer reaches; `5f495f5` ci: cache-attacks held on every PR and train.
- how far: committed, tests added (`packages/cli/src/commands/tests/kept_settle_test.av` +37). Bug it fixes: "a program that seals a record read back a value another program through the same store … kept flat, and the crossing refused it".
- landed? NO (no subject match on origin/main).
- DB meaning: P4 gains a 7th hand line kind (`l`); evidence that a kept VALUE depends on whole-program facts (a `mut` seat anywhere) that no source-digest witness names — a direct input to D8 (witness atom).
- verdict: **KEEP** (land; fold into door-2 design).

**avra-wants-modules** (wants-modules, 2 unlanded + dirty CLAUDE.md, 2026-10-05) — ACTIVE
- what: `f7cc30a` embed: a path opening with `@` names a package; `726cf54` wip host fns (bodied `extern fn`), "unverified".
- how far: wip; touches `compiler/verify_held.av` (+1: `maybe_mismatch(path, name, "facts.hosted", …)`), `features/decls.av` (+12), `core/store.av`, `whole.av` (+92).
- landed? NO.
- DB meaning: adds a field to the held-facts comparison — the recurring "a field added after its hash/witness" hazard; whether the hold RECORD wire also carries `hosted` is NOT VERIFIED.
- verdict: KEEP (active); DB lead should check the record wire when it lands.

**avra-pipe-op** (pipe-op, 4 wip commits, 2026-10-05) — ACTIVE
- what: `|>` (sources doc C1). `core/store.av` +59 (parse-owned mark), `expr_spine/pipe.av`, lexer.
- how far: "wip … tests green on the spine".
- landed? NO.
- DB meaning: only via fingerprints — the doc says the mark "restamps the node's fingerprint" so `x |> f` and `f(x)` "type alike and fingerprint apart". Not a DB change.
- verdict: KEEP (not DB work).

**avra-revert-mark** (lane/revert-verify-mark, 1 unlanded, 2026-09-30) and **avra-perf-kvm-revert** (detached bc2d64a, dirty `query/kernel.av`)
- what: both REVERT `0be202b` "fix(query): a cell under verification is marked before its deps are walked" (kernel.av −8/+5; revert-mark also deletes 40 lines of kernel_test) to A/B it (`avra-revert-mark/tools/.ab.sh`: two `make avra`, then `test packages/cli` cold/warm counting defects).
- how far: experiment only; no result recorded in the tree (NOT VERIFIED what it showed).
- landed? No, and the fix it reverts is still on main: `avra-db-design:query/kernel.av:359` "Marked verified at this revision BEFORE its deps are walked".
- verdict: **ABANDON** both.

**avra-revert-45** (revert-45, 2 unlanded, 6 staged files, 2026-09-30)
- what: `00f4371` "Revert #45 (f7dc8e0): it breaks the witness_stale_manifest and witness_refusal tests" + `b921a74` cells: a new cell owns what it holds; staged edits in memory/consumes/soundness.
- how far: a bisect/repair attempt around #45; #45 stayed on main and the follow-up landed as #71 `3d6318c` ("a module's own words never make every parse read the manifest" — `declaring_siblings` at `avra-db-design:workspace.av:1312`).
- DB meaning: historical — a PARSE that read the manifest made every file depend on it (a dependency-edge bug class).
- verdict: ABANDON.

**avra-impl-closure-trace** (1 unlanded scratch commit; both scripts staged-deleted)
- what: `trace127.sh` / `rt125.sh` — qtrace repro for avra-8sb5.57.127 ("an unrelated trait impl added in an unnamed file leaves the importer held").
- ticket: CLOSED 2026-10-01; comment: "Traced with AVRA_QTRACE=1. Could not reproduce the 'held' claim in a clean run."
- verdict: ABANDON (the repro shape is a candidate cache_attacks case if not already there — NOT VERIFIED).

**agent-a4866be31854b20a3** (`avra/.claude/worktrees/…`, base 9f30b28 2026-09-22, 2121 behind, 0 ahead)
- dirty: ` M features/decls_mint.av` (+29: the sibling-floor fix) and `?? packages/std-relation/` (files dated Sep 28; relation.av 722 l vs main's 1291).
- landed? decls_mint fix = `avra-fix-4647@745c383`, present on main (`decls_mint.av:834` "previous sibling's end"; tests `features/tests/derive_sibling_floor*`). std-relation copy is an OLD snapshot (main has `input.av`, `query.av` it lacks).
- verdict: ABANDON.

**avra-ui-h** (lane/ui-h, 0 ahead, 23 dirty, base 09-29)
- dirty includes `compiler/verify_held.av` (adds `place=${bool_str(m.place)}` to the seat-mark line) and `compiler/record.av`, `core/store.av`.
- landed? The `place` capture work landed as #219 `1d44a63` "feat(state): a capture reads and writes the place" (NOT VERIFIED that it is the same diff).
- verdict: ABANDON (stale uncommitted draft).

### 3.2 FLAGGED by path/keyword — verified LANDED or not DB work (one line each)

| worktree | why flagged | resolution |
|---|---|---|
| avra-lang-names | `0b26d5c` fix(cache): re-exporting file reached by importers (a WRONG-BINARY fix) | landed in #96 `a131469`; `avra-db-design:record.av:1160,1201` `reexporting_files`; `tools/cache_attacks.sh:545–549` rx steps |
| avra-licenses, avra-licenses-warm | `659f7c3` touches `query/fixpoint.av`, workspace.av (`@plain_field` on `@identity`) | landed: `avra-db-design:std-meta/src/meta.av:327` `export fn plain_field` |
| avra-bracket | merge commit carries DB files; own commits = idiom `compiler.bypass_outside_bracket` + cache-attacks witness rename | landed as bracket-lint2 #38 `9cee431` (NOT VERIFIED line-for-line) |
| avra-dyn, avra-gtraits, avra-generic-traits, avra-dyn-dispatch, avra-from-trait, avra-trait-bounds | `verify_held.av`/`features/decls.av` ("held facts carry trait arguments") | landed #59 `a92e540`, #67 `cb931b3`, #87 `341787a`, `80e8dda` |
| avra-http-hygiene (+ dirty workspace.av), avra-http-hygiene-fix | "a store names the codegen mode", "a kept binary is reused only while what it linked is unchanged", `declaring_siblings` | landed #45 `f7dc8e0` + #71 `3d6318c` |
| avra-http-app, -app-warm, avra-http-perf, avra-land-batch-wt(-warm), avra-land-speed-wt, avra-land-stable | workspace_test.av; "avra docs reads the Decl relation through two @query fns", `name_slice_fp` | landed #37 `c1699cd`, #40 `0531e8b`, #38, #32 `fca7c55` |
| avra-ui-own-state | workspace.av, decls.av (components' bodies, `Site`) | tree IDENTICAL to origin/main (`git diff origin/main HEAD` empty) — landed #284 `05fe643` |
| avra-fix-4647 | decls_mint floors | on main (see agent-a4866) |
| avra-gates-fix | `opt_decl_fp` fingerprint tags | landed #75 `8a418cf` |
| avra-wasm32, avra-wasm-pkgc, avra-wrap-method, avra-ui-primargs, avra-gimpls, avra-gimpls2, avra-test-onmain | workspace.av / decls.av edits for features | landed (#206, `9480ace`, patch-id `-`, etc.) |
| avra-cli-fresh-roots | "no earlier run's cache answers for it" (test hygiene) | landed (unlanded=0) |
| avra-skill-warm | docs: review-round smoke-tests `avra cache why` | landed (unlanded=0) |
| avra-test-single, avra-test-single-red | untracked `tools/witness_scope.sh` — exercises `avra test <path>` shapes, not the cache witness | no DB work |
| kp (/private/tmp/claude-502/kp) | "keeper witness" = externs keeper scratch | no DB work |
| uib2 (/private/tmp) | wasm measure branch, 34 unlanded | no DB work; path GONE on recheck (uib, uib_base, uibm also MISSING) |
| avra-keeper-drafts, avra-lock-order, avra-train-slots, avra-claude-pr-gate, avra-eval-rc, avra-ui-dom, avra-ui-emit, avra-ui-l2b, avra-ui-dev, avra-http-conformance/-h2fix/-harden/-http2 | keyword false positives ("held", "holds", "kept", "cached per second", "digest") | no DB work (ui-dev landed #276) |

### 3.3 UNFLAGGED — one row each ("no DB work" for all)

| name | topic |
|---|---|
| avra (main checkout, stale, 156 dirty/untracked notes) | stale main checkout |
| avra-248-stackdoc | fibers stack doc (landed) |
| avra-bench-methodology | http bench doc (landed) |
| avra-canon-flake | fmt --check shim (landed) |
| avra-ci-checks, -ci-idioms-all, -ci-keepers, -ci-main-cache, -ci-shards | CI workflow |
| avra-claude-md-names, -claude-timeout-rule | CLAUDE.md edits (landed) |
| avra-cleanup-land-sh | land.sh retirement (landed) |
| avra-client-method | std-http client (landed) |
| avra-const-div | backend sdiv (landed) |
| avra-cse-old | detached at #36; untracked `tools/cse-probe/` |
| avra-e2e-train-scratch-1/2/3 | land-train scratch files |
| avra-env-inherit | cli spawn tests env |
| avra-fix-suite-paths | ci suite paths (landed) |
| avra-fmt-bugs (lane/wrap, 13 dirty) | WRAP/quote draft edits (expand.av, crossing.av, decls_mint.av uncommitted) — annotation work, stale |
| avra-gate-preflight2 | land OOM guard (landed) |
| avra-h2-task-stack, -h2client, -h2clients, -h2pool, -http-coding, -http-flagloops, -http-idiomfix, -http-wave2, -http-client, -http-streaming, -hardening-doc, -https-tour, -tour-client, -tour-streaming, -tls-readme, -url-readme | std-http/tls/url code and docs |
| avra-integrate-c-s2b | old seed merge |
| avra-keeper-stuck, -land-enqueue, -work-land-existing, -work-watch, -train-diff-main, -sp-build-fails, -sp-dryrun, -sp-exclude, -sprites-fix, -spx-1 | landing/Sprite tooling |
| avra-lang-loops, -loops-lambda-seat, -loops-stack, -seed-loops, -seed-pid | loops / seeds |
| avra-perf-hang-timeouts | cli test hang bound (landed) |
| avra-perf-speed-gate | dirty checks.yml + `tools/warm_speed.sh` (a warm-speed CI gate draft; measures, does not change, the cache) |
| avra-stringlenses, -stringlenses-lens (merge conflict `UU loops/lower.av`) | string walks |
| avra-ui-a11y, -ui-bisect, -ui-charter, -ui-core, -ui-declared, -ui-diff-fuzz, -ui-findis, -ui-i, -ui-lib, -ui-render2, -ui-runstream, -ui-splice, -ui-state, -ui-testdiff, -ui-tree | UI library / wasm |
| avra-wants-values | language wants (lists.get/fold, enums, nullable call) — 12 unlanded, no cache files |
| avra-wasm-flat, -wasm-size | wasm size |
| avra-watch-dash | watchdog process group (landed #156) |

Named-in-task checks: `avra-perf-*` other than assigned = hang-timeouts (landed), kvm-revert (ABANDON, §3.1), speed-gate (CI draft); `avra-validate*` = Part A (landed #55); `avra-ui-own-state` = landed #284; `avra-keepers-green` = H1; `avra-cli-fresh-roots` = landed; `avra-test-single*` = no DB work; `avra-fix-suite-paths` = landed; `avra-docs-*` = Part A, landed; `avra-wants-*` = §3.1 / §3.3; `avra-impl-closure-trace` = ABANDON; `agent-a4866be31854b20a3` = ABANDON.

---

## 4. What the DB design should take from this scope

1. **P4 (kept settlements) keeps growing hand line kinds**: `u c m f b` (doc) + `e` (main #282) + `l` (keepers-green, unlanded). Two of the three additions happened on 2026-10-05 alone. This is the strongest evidence for door 2 / a single witness atom (D8), and that the atom must admit non-input facts (a program-wide layout).
2. **Remembered-row-before-analysis is now a pattern with two instances** (`closure_key`, `embeds_key` in `build.av:526–556`) — D4's answer in practice.
3. **`build_inputs` has three consumers with different needs**: `program_key` (+ embeds bolted on), `avra dev`'s watch set (no embeds — H4), and the suite/check verdict. One "what did this build read" relation would serve all three.
4. `Db.answers` (P3) still has no production caller per the doc (PROBED grep there; not re-run here — NOT VERIFIED on 05fe643); D10 gates arming it.
5. Unpersisted `Lifted`/`Expanded` is the cost every derive-heavy consumer pays (`@derive(Decode)`, `@model`, `@relation`, UI `View`): doc MEASURED 0.04 s → 0.25 s per comment edit for 1,000 generated types, and 75–140 KB compiler memory per generated declaration.
