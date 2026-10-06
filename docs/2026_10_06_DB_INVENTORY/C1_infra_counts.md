# C1 — cache/query infrastructure on main: first-hand inventory

Tree: `/Users/tristan/projects/tristanMatthias/avra-db-design` @ `05fe643` (origin/main, 2026-10-05). Read-only; nothing built or run.
Path legend: `A/` = `packages/std-avrac/src/`, `C/` = `packages/cli/src/`, `R/` = `packages/std-relation/src/`.
Scope of every count: NON-TEST `.av` under `A/` and `C/` (plus the C the compiler calls). "MEASURED" = counted from `grep -n` output over that scope and then read at the cited line; "ESTIMATED" = derived.

## 0. Summary counts

| Quantity | Count | How |
|---|---|---|
| Outside-read SITES (lines that read file/dir/env/tool/clock/pid/self at compile or tool time) | **~177** | MEASURED by grep + reading; per-category table A.0. `fmt.av` listing/is_dir lines are ±2 |
| …of which recorded as a KERNEL input (`Relation.input`/`input_loaded`) | **2** | `A/compiler/workspace.av:1137` (Source), `A/compiler/packages.av:64` (Manifest). (A third input family, `Named`, is internal — a declaration name bucket's hash, not a world read; C.4 row 29) |
| …of which recorded after the fact (read first, dep added later) | **1** | `embed` text: read at `A/compiler/whole.av:229`, `touch(self.source(...))` at `A/compiler/workspace_analysis.av:580`, `Settled` family only |
| …of which folded into a DURABLE KEY or WITNESS but not a kernel dep | **~14** | text_digest, digest_of_binary, manifest_objects, package listings (build_inputs), `.expected`, embed_said, Decl listing+file witness (4 lines), compiler self-digest, `AVRA_INLINE_RUNTIME`, `--target` mode, `tools.opt`/`tools.runtime` |
| …read with NO record and NO key | **~160** | everything else (all `exists`/`is_dir`, 7 of 8 listings, all env but one, all tool lookups, clock, pid) |
| `Host` abstraction | 1 type, 8 fn fields + 3 data fields + 2 methods; 3 implementations | `A/compiler/host/host.av:13`; disk `C/commands/shared.av:63`; memory `host.av:41`; overlay `A/compiler/rule_proof.av:141` |
| `Host` call sites in the compiler (non-test) | **54** | read 13, beneath 2, exists 21, is_dir 8, list 7, write 3; `stamp` **0** |
| Store WRITE call sites (`keep`/`keep_once`/`keep_file`) | **18** | table B.1 |
| Distinct persisted ROW KINDS | **27** | 8 `Rows`, 12 `Unit`, 4 `Warn`, 2 `Obj`, 1 `Bin` (table B.2) |
| …validated by re-digesting inputs at recall | **4** | `Decl` (still_valid), `Bin` (links_unchanged), kept-settle (`kept_row_stands`), module record lines (`written_from`) |
| …content-addressed (key recomputed from inputs; "hold unconditionally") | **17** | B.2 |
| …name-keyed mutable rows | **6** | record head (validated), `parts`, `seen`, `homes`, `closure`, `embeds` (last five NOT validated) |
| `Stored` families declared / actually written | 7 / **5** | `Sig` and `Fp` directories are never written (B.3) |
| Kernel query families (`Family` collect enum) | **32** (ranks 0..31) | `A/compiler/families/families.av:17-147` |
| …with a value in `Db.families` `Relation<DbRow>` | **16** | C.4 |
| …persisted as kernel cells | **0** | "Fine-grained edges are never kept" `A/compiler/cache_walk.av:4` |
| Extra kernel families minted dynamically by `@std/relation` Dbs | ≥ 1 per reached relation / `@side` / `@query` memo / `@input` slot | `A/features/decls.av:717`, `A/compiler/workspace.av:573` |
| `DbKind` variants | **24** = 16 dense + 8 durable | `A/compiler/db.av:160-185` |
| Hand-rolled caches/memos/maps outside the kernel | **~95 fields/sites** | table E (Keys 12, Records 12, Hold 20, Workspace 17, Decls ~27, other ~9) |
| `@relation` declarations in std-avrac | **12** (2 `@arena`, 2 `@side`, 8 rows) | F |
| `@query` in std-avrac | **2**; `@input` **2** (1 has no caller) | F |
| Registered codec pairs | **18** | 17 named rows `A/compiler/codecs.av:518-646` + `dbrow_check()` `:653` (MEASURED) |
| `tools/cache_attacks.sh` steps | **47** `steps=` increments (MEASURED) | G |

Headline defects/risks found while counting (each cited in its section):

1. Exactly TWO world reads are kernel inputs. Directory listings, existence checks, `.expected/.refuses/.native-only` markers, env, tools are invisible to the kernel. It survives only because every `Workspace` is one-shot (`disarmed`, `A/compiler/workspace.av:820`) and durable validity is carried by KEYS (digests recomputed up front) rather than deps.
2. `Host.stamp` is declared and supplied by the disk host but has **no caller** in std-avrac (two stamp shortcuts were removed: `A/compiler/build.av:277-294`, `:638-645`).
3. `Store.keep(…, read)`'s edge list is written to `<key>.deps` and **never read back** — only its existence is the commit bit (`A/compiler/store/store.av:109`, `:145`).
4. `Stored.Sig` and `Stored.Fp` are dead as directories: `Sig` is used only as a `node_key` name prefix; records live under `rows/`.
5. `DbRow.Answer` (durable `@query` answers) has **no production caller**: `Db.answers` is called only from `A/compiler/tests/answers_test.av:39`; `durable_db` only from tests.
6. The linker (`CC`), the clang version, `-L/-l` words and `${ENV}`-expanded link words are in NO key: `program_key` = compiler print + entry + input digests + package object digests (`A/compiler/build.av:589-609`). A kept binary survives a `CC`/`LLVM_PREFIX` change.
7. `avra fmt --check`'s "a cache hit answers without a parse" is false today: `canon_key` calls `ws.parsed(f)` before the lookup (`C/commands/fmt.av:83-87`, `:266-267`).
8. Three host reads happen INSIDE a `Parsed`/`Plain` query frame with no dep: `file_lexes_block`, `file_declares_component`, `component_names` (`A/compiler/voices.av:680,701,713`) plus `host.list(dir)` (`A/compiler/workspace.av:1315`).

---

## A. Every place that reads the outside world

### A.0 Totals per category (MEASURED)

| Category | Sites | Kernel-recorded | Folded into a durable key/witness | Unrecorded |
|---|---|---|---|---|
| File content (text/bytes) | 32 | 2 (+1 after the fact) | 8 | 21 |
| Directory listing | 10 | 0 | 2 (`build_inputs` walk, Decl listing witness) | 8 |
| Exists | 44 | 0 | 0 (some gate a key input) | 44 |
| is_dir | 22 | 0 | 0 | 22 |
| stamp/mtime | 2 (both CLI; compiler 0) | 0 | 0 | 2 |
| Env var | 19 | 0 | 1 (`AVRA_INLINE_RUNTIME`) | 18 |
| Tool lookup (PATH/env) | 12 | 0 | 0 (path strings `tools.opt`,`tools.runtime` enter Obj keys; linker does not) | 12 |
| Process spawn | 6 | 0 | — | 6 |
| Self digest / argv0 / self dir | 2 | 0 | 1 (compiler print → store root + keys) | 1 |
| Toolchain discovery (std root, runtime lib, wasm runner, dom glue) | 5 | 0 | runtime archive bytes via `links_text` | 5 |
| Clock | 21 | 0 | 0 (names/nonces/timings only) | 21 |
| Pid | 2 | 0 | 0 | 2 |
| **Total** | **~177** | **2 (+1)** | **~14** | **~160** |

### A.1 The host abstraction

`A/compiler/host/host.av:13`:
`export type Host = { exists: fn(string) -> bool, read: fn(string) -> string, beneath: fn(string, string) -> Beneath, write: fn(string, string) -> string?, list: fn(string) -> List<string>, is_dir: fn(string) -> bool, stamp: fn(string) -> int?, reads_ahead: fn(int) -> void, std_root: string? = null, cwd: string = "", compiler: string? = null }`
Methods: `absolute(path)` (`host.av:19`), `std_dir(key)` (`host.av:26`).

| Impl | Where | Notes |
|---|---|---|
| Disk host | `C/commands/shared.av:63-77` | `exists: (p) -> exists(p)`, `read: read_or_die`, `beneath: disk_beneath` (`open_beneath`), `list: list_dir(dir) catch []`, `write: write_file`, `is_dir`, `stamp: (p) -> stamp(p)`, `reads_ahead: light_or_leave`, `std_root: std_root()`, `cwd: env("PWD") ?? "."`, `compiler: own_binary()` |
| Memory host | `A/compiler/host/host.av:41-57` | tests + `lone_workspace` (`A/compiler/workspace.av:643`); `stamp: no_stamp` |
| Overlay | `A/compiler/rule_proof.av:141` | `self.ws.host with { read: (p) -> if normalized(p) == normalized(path) { text } else { self.ws.host.read(p) } }` |

Every Host call site in the compiler (MEASURED: `grep -rnE "host\.(exists|read|beneath|write|list|is_dir|stamp|…)"`):

| Method | # | Lines |
|---|---|---|
| `read` | 13 | `workspace.av:1137`; `packages.av:64,86,253`; `build.av:299,629,649`; `voices.av:680,701,713`; `suite.av:101,163,188` |
| `beneath` | 2 | `whole.av:213,229` |
| `exists` | 21 | `suite.av:143,146,158,215`; `packages.av:81,133,145`; `record.av:1047,1075,1110`; `whole.av:393`; `modules.av:106,170,285,445`; `build.av:299,412,414,628`; `derive.av:615,686` |
| `is_dir` | 8 | `suite.av:42,208,210`; `modules.av:102,219,262,444`; `build.av:363` |
| `list` | 7 | `suite.av:210`; `modules.av:103,217,260`; `build.av:364,388`; `workspace.av:1315` |
| `write` | 3 | `build.av:219,385`; `derive.av:315` |
| `stamp` | **0** | field only (`host.av:13,53,75`; disk `shared.av:71`) |
| `reads_ahead` | 1 | `derive.av:458` |
| `std_root` / `std_dir` | 2 | `modules.av:251`; `packages.av:144` |
| `absolute` | 1 line (2 calls) | `packages.av:130` |
| `compiler` | 1 | `build.av:297` |

(all paths under `A/compiler/`)

### A.2 File content

| file:line | What | Through | Recorded as a query dep? | Keyed/digested | Goes stale unnoticed → |
|---|---|---|---|---|---|
| `A/compiler/workspace.av:1137` `DbRow.Source(new_source_file(path, self.host.read(path)))` | source text | `Host.read` inside `relation(Family.Source).input(...)` (`:1131-1140`) | **YES** — `Relation.input` (`A/query/memo.av:128`) → `set_input` + `record_at` | `(s) -> fp_str(source_of(s).text)` (`:1139`) | in-process only; nothing durable keys on this hash |
| `A/compiler/packages.av:64` `let text = self.host.read(path)` | `avra.toml` text | `Host.read` inside `relation(Family.Manifest).input_loaded` (`:60-70`) | **YES** | `fingerprint: fp_str(text)` (`:67`) | in-process only |
| `A/compiler/build.av:649` `let made = digest_of_file(self.host.read(path))` | every build input's text | `Host.read` in `text_digest`, memo `keys.text_digests` | no kernel dep | `"${text.length}.${digest_of(text)}"` (`:907`) → `program_key` `input_line` (`:611`), `KeyParts.text/runs` (`record.av:1108-1110`), record `file` line (`interface.av:504`), kept-settle `u`/`f` lines, `proved_key` | (it IS the witness) a second read of the same file for `Source` can differ from the digested one — two reads, one file |
| `A/compiler/build.av:629` `read_manifest(new_source_file(path, self.host.read(path)))` | closure roots' manifests, read "fresh and not through `manifest(i)`" (`:624`) | `Host.read` | no | object paths → `object_line` digests → `program_key` | Bin/Warn rows if the manifest is edited between this read and the `Manifest` input read |
| `A/compiler/build.av:341` `match read_bytes(at)` | compiler binary; runtime archive; package objects | direct `@std.io.read_bytes` (`digest_of_binary`) | no | `digest_key(digest_bytes(new_digest(), bytes))` → compiler print (`:300-302`), `links_text` (`:321`), `object_line` (`:636`) | — |
| `A/compiler/build.av:694` `match read_bytes(bc)` | the program module's own bitcode | direct | no | `node_key(Stored.Obj, ["entry", digest, tools.opt, tools.runtime])` (`:696-704`) | — |
| `A/compiler/build.av:299` `ws.host.read(roll)` | `.avra-cache/compilers` roll | `Host.read` | no | not keyed (roll decides which stores are swept) | a lost update drops one roll line (`:377-379`) |
| `A/compiler/whole.av:229` `match (self.host.beneath)(place.root, place.rel)` | `embed` file text during a settlement run | `Host.beneath` via `embed_read`, passed into `run_settle` (`workspace_analysis.av:638`) and `run_crossed` (`:680`) | **after the fact, Settled only**: `.Ok(value) -> { for path in value.embeds { touch(self.source(self.file_id(path))) } }` (`workspace_analysis.av:580`) — a SECOND read of the same file through `Source` | kept-settle `e` line `embed_said` (`kept_settle.av:151,178`); `program_key` `embed_line` (`build.av:567,593`) via remembered `embeds` row | `Lifted` (annotation) runs that embed: `crossed_expr` passes `embed_read` (`:680`) and adds no Source dep — NOT VERIFIED that a crossed run can reach `embed` |
| `A/compiler/whole.av:213` same call | whether an `embed` literal's file stands and is text (`.Text(_) -> path`) | `Host.beneath` via `embed_placed_beside`; called at admit (`whole.av:174`), typing (`A/features/fns/check.av:691`), lowering (`A/features/fns/lower.av:32`) through hook `arm_embeds` (`workspace.av:770`) | no (the admit mints a File row; the typing read is inside `Typed` with no dep) | no | `Typed`/`Lowered` verdict about a missing/linked embed file |
| `A/compiler/voices.av:680` `let text = ws.host.read(path)` | provider file text, to decide "can it open a block word" | `Host.read` in `file_lexes_block`, called from `line_words` (`workspace.av:1352`) inside `Parsed(f)` | **no** | `digest_of("scan\n${ws.compiler_id()}\n${text}")` → `Scan` row (`:686-690`); memo `records.grammar_scanned` | in-process `Parsed(f)` of the IMPORTER (no dep on the provider's text) |
| `A/compiler/voices.av:701` `let text = ws.host.read(path)` | sibling file text, "declares a component" | `Host.read`, memo `records.component_scanned` | **no** | none | `Plain`/`Parsed` of every file in the directory |
| `A/compiler/voices.av:713` `lex_source(ws.host.read(path)).tokens` | sibling file text, component names | `Host.read`, memo `records.component_names` | **no** | none | same |
| `A/compiler/packages.av:86` | manifest text for a diagnostic's source window | `Host.read` | no | no | cosmetic |
| `A/compiler/packages.av:253` `self.host.read(manifest_path).length` | manifest length for a fix's insertion offset | `Host.read` | no | no | a suggested edit's position |
| `A/compiler/suite.av:101` `self.host.read(beside(path, "refuses"))` | `.refuses` voice text | `Host.read` | no | **not in the suite key** (`beside:` lists `.expected` only, `suite.av:64`); re-read every run, hit or miss (`:68`) | nothing kept depends on it |
| `A/compiler/suite.av:163` | `.expected` text → `ProgramCall` | `Host.read` | no | suite `program_key` via `beside` (`:64`) → `input_line` | — |
| `A/compiler/suite.av:188` | `.expected` text, raw, in `proved_key` | `Host.read` | no | `node_key(Stored.Unit, ["proved", path, <text>, <text digests>])` | — |
| `A/compiler/db.av:695` `digest_of(read_text(path) catch "")` | each witnessed file of a `Decl` row | **direct `@std.io`**, bypasses Host | no | compared to `FileWitness.digest` (`:663`) | — (it is the validator) |
| `A/compiler/inputs.av:22` `read_text(path) catch ""` | a file's current bytes for a finding's line text | `@input fn file_text` (std-relation), called only at `A/compiler/findings.av:46` | recorded on a THROWAWAY Db: `let db = new_findings_db()` per call (`findings.av:19,34`) → no lasting dep | the `@input`'s own content hash, discarded with the Db | `Findings`/`rules` rows hold text read at check time; keyed by program key/okey, so content-addressed |
| `A/compiler/store/store.av:122,175,191` | cache rows (`read_text`), a file to keep (`read_bytes(from)`), a kept binary (`read_bytes`) | direct `@std.io` | n/a | by key | — |
| `C/commands/shared.av:220` `match read_text(path)` | `read_or_die` — the disk host's `read`, and a lone file's text (`:286`) | `@std.io` | (impl of rows above) | | |
| `C/commands/shared.av:84,90` `open_beneath(root, rel)` … `o.text()` | disk host's `beneath` | `@std.io` | (impl) | | |
| `C/commands/emit.av:13`, `idiom_baseline.av:39`, `process.av:27`, `rules.av:114` | emitted `.ll`; idiom baseline file; a manifest for `avra process`; a doc for `avra rules` | direct `read_text` | no | no | tool output only (baseline: the ratchet's verdict) |
| `C/commands/dev.av:212,223,379,434` | watch loop re-reads, built wasm bytes, `page.html` | direct | no | no | dev server only |

### A.3 Directory listings

| file:line | What | Through | Recorded | Keyed | Stale risk |
|---|---|---|---|---|---|
| `A/compiler/modules.av:103` `[joined_path(dir, f) for f in self.host.list(dir) if self.listed_source(dir, f)]` | a module's files (`listed_files`) | `Host.list`; memo `files_of` keyed `"${packages().length}\t${module}"` (`:84`) | **no** | kept-settle `m` line stores the joined list (`kept_settle.av:228`); record `file` lines | in-process `Namespace(m)`: a file added to a module is invisible to the kernel |
| `A/compiler/modules.av:217` `for f in self.host.list(dir)` | recursive package walk (`all_files_under`) → `root_files`, `every_source`, **`build_inputs`** (`:278-292`) | `Host.list` | no | every path+digest in `program_key` (`build.av:590-595`) — this is how an added/removed file moves Bin/Warn/Licenses/Findings | — |
| `A/compiler/modules.av:260` | toolchain `backend/` and `runtime/` `.c/.h` files (`engine_sources`) | `Host.list` | no | in `program_key` via `build_inputs` (`:283-290`): "a code-generator change must invalidate every module it could have emitted" | only when `host.std_root` is set (`:251`) |
| `A/compiler/workspace.av:1315` `for f in self.host.list(dir) if is_source(f, dir) && file_declares_component(...)` | a directory's component-declaring siblings | `Host.list` inside `Plain`/`Parsed`/`file_id` | **no** | none | `Plain(f)`/`Parsed(f)` |
| `A/compiler/suite.av:210` | nested package roots under `src/` | `Host.list` | no | no | which suites run |
| `A/compiler/build.av:364` | `.users/` pid marks | `Host.list` | no | no | sweep liveness |
| `A/compiler/build.av:388` | `.avra-cache/*` store dirs | `Host.list` | no | no | sweep |
| `A/compiler/db.av:681` `flatten([av_files_at(dir, f) for f in list_dir(dir) catch []])` | a package's `.av` listing for the `Decl` witness | **direct `@std.io`** | no | `digest_of(joined(sorted_texts(av_files(dir)), "\n"))` (`:677`) vs `facts.listing_digest` | — |
| `C/commands/shared.av:68` | disk host `list` | impl | | | |
| `C/commands/fmt.av:154-175` (walk) | files to format | direct `list_dir` | no | no | which files are examined |

### A.4 Existence / is_dir (none recorded, none keyed)

| Lines | What each decides |
|---|---|
| `A/compiler/packages.av:81,133,145` | whether a package has `avra.toml` (root → empty manifest input, `:51-56`); dependency path valid; std package admitted. NOT a dep: a manifest created later is invisible to `Manifest(i)` (its loader for the no-manifest case hashes `0`, `:55`) |
| `A/compiler/modules.av:106,170,285,445` + `is_dir 102,219,262,444` | file-module vs dir-module; nested package boundary; which manifests join `build_inputs`; ambiguous module |
| `A/compiler/whole.av:393` | `src/main.av` as default entry |
| `A/compiler/record.av:1047,1075,1110` | `record_stands` ("every file a module's record places is one the host still has"), `files_iface`, a run's file still exists (→ `""` in `KeyParts.runs`) |
| `A/compiler/derive.av:615,686` | a remembered home still exists (`home_moved`, `asked_print`) |
| `A/compiler/suite.av:143,146,158,215` + `is_dir 42,208,210` | `.expected` / `.refuses` / `.native-only` markers (`is_program` is also asked by `Workspace.is_program_file`, which lowering's entry law reads — a MARKER FILE's existence changes a typing/lowering verdict with no dep and no key for `check`); nested roots |
| `A/compiler/build.av:299,412,414,628` + `is_dir 363` | roll present; `.git`/`avra.toml` on the way up (`tree_root`, decides WHERE `.avra-cache` is); manifest present |
| `A/compiler/store/store.av:99,109` | row committed (`exists(path) && exists(edge_path)`) |
| `A/compiler/db.av:676,687` (`is_dir`) | `src/` vs root for the Decl listing |
| `C/commands/shared.av:86,129,145,151,157,196,256,276,295,343,406,458,491,506,518,592` | own binary, std root, runtime archive, wasm crt1, argued path, `src/`, `avra.toml` ancestor (`package_root`), wasm runner |
| `C/commands/fmt.av:42,231`, `test.av:36,42,73`, `dev.av:65,66,75,209,256`, `idiom_baseline.av:38,102`, `process.av:23`, `new.av:52` | command-level |

### A.5 Environment

| file:line | Var | Through | Recorded/keyed | Stale risk |
|---|---|---|---|---|
| `backend/llvm_wrapper.c` `getenv("AVRA_INLINE_RUNTIME")` → `A/compiler/backend/llvm.av:200` `inlines_runtime()` | codegen mode | C | **keyed**: `codegen_mode()` suffix `"-calls"` in the compiler print (`A/compiler/build.av:302,334`) | — (attacked by `tools/link_cache_attack.sh`) |
| `A/compiler/whole.av:555` `expanded("${head}${avra_host_env(name)}${tail}")` | any `${NAME}` in a manifest's `objects`/`search`/`libs`/`raw`/`wasm_objects` | extern `avra_host_env` (`workspace.av:109`) | **no dep**. Objects: the EXPANDED path's bytes are digested (`build.av:630,636`). `-L${X}`/`-l`/`[link.raw]`: in no key | Bin row when e.g. `LLVM_PREFIX` changes the `-L` directory but no object's bytes |
| `C/commands/shared.av:178,437` `tool_from_env("CC", "clang")`; `:179` `env("LLVM_PREFIX")`; `:469` `NODE`; `:590` `WASM_OPT` | tool selection | `@std.process` / `@std.io.env` | linker path → `Toolchain.linker` (`:584`) — **not in any key**; `wasm_opt != ""` → `+opt` mark only (`build.av:437`) | Bin row linked by a different clang |
| `C/commands/shared.av:74` `cwd: env("PWD") ?? "."`; `:306` `env("AVRA_CWD") ?? env("PWD") ?? "."` | where relative paths root | `@std.io.env` | no; keys use `relative_path(self.root, …)` (`build.av:602,611`) but `closure_key`/`embeds_key`/`record_key`/`homes_key` fold the ABSOLUTE `self.root`/entry (`build.av:526,538`; `record.av:51`; `derive.av:189`) | a moved checkout reads none of its name-keyed rows (cold, not wrong) |
| `C/commands/shared.av:124` `env("AVRA_LIGHT")` | leave with status 75 when > 16 reads | | no | — |
| `C/stage.av:71` `env("AVRA_SOUNDNESS")` | soundness leg | | no | — |
| `A/query/memo.av:12` `once fn qtrace_flag() -> string? { env("AVRA_QTRACE") }` | tracing | `@std.io.env`, read once per process | no | — |
| `A/compiler/dep_audit.av:54` `env("AVRA_DEP_AUDIT")` | arm the audit | | no | — |
| `A/compiler/memory/memory.av:80` `env("AVRA_SOUND_CHECK") == "1"` | memory-pass soundness check | | **no — and it gates work inside lowering/memory** | NOT VERIFIED whether it changes emitted code; if it does, Obj rows are stale across the flag |
| `A/compiler/lower/lower.av:501,674` `env("AVRA_STUB_DEBUG")` | debug prints | | no | — |
| `A/compiler/inputs.av:31` `@input fn env_value(...) { os_env(key) }` | any | std-relation `@input` | would be — **no caller** (`grep env_value(` → definition only) | — |
| `A/compiler/backend/interp.av:1300` `.HostEnv -> Val.S(avra_host_env(...))`; `:1299` `.NowNs` | the EVALUATOR's host rows | extern | not recorded; a settlement that reaches the world is refused (`Unsettled.Reach`, `workspace_analysis.av` `reach_probe`) — NOT VERIFIED that every env/clock row is classed "world" | a folded const baked from env |
| `C/commands/shared.av:518` `compile_slot()` | `AVRA_MAX_COMPILES`, `AVRA_SLOT_DIR`, `AVRA_COMPILE_SLOT` (`packages/std-io/src/io.av:426-432`) | `@std.io` | no | — |

### A.6 Tools, spawns, self, clock, pid, target

| file:line | What | Recorded/keyed |
|---|---|---|
| `C/commands/shared.av:436-438` `fn linker() … tool_from_env("CC", "clang")` | PATH lookup (`packages/std-process/src/process.av:276-282` `which(name, search_path())`) | path → `Toolchain.linker`; **not keyed**; the tool's VERSION is never read anywhere (no `--version` spawn exists; MEASURED by grep) |
| `C/commands/shared.av:195` `cmd(clang, ["--target=${triple}", "-print-file-name=crt1.o"]).outcome()` | does this clang link wasm | result picks `Toolchain.target` → `mode()` → compiler print (keyed) |
| `C/commands/shared.av:581-602` `toolchain(target, reactor, debug)` | `opt: "-O1"`/`"-Oz"`, `runtime: runtime_library()`, `linker`, `target`, `reactor`, `debug`, `wasm_opt` | `tools.opt`, `tools.runtime` (a PATH string) in Obj keys `build.av:701-702,854-855`; `mode()` (`build.av:435-438`) in the print; runtime BYTES via `links_text` |
| `A/compiler/build.av:296-309` `compiler_print` | `ws.host.compiler` → `digest_of_binary(at)`; "The digest is hashed FRESH every ask" (`:277`), memo per workspace `keys.compiler_id` (`:167`) | print = `"${digest}${codegen_mode()}${"@"+mode}"` (`:302`) → store ROOT (`:201`) and folded into `record_key`, `RecordBodies.key`, `program_key`, `scan` key, `canon_key`, `db_qualified` |
| `C/commands/shared.av:128-130` `own_binary()` = `toolchain_files([file_name(avra_selfhost_get_arg_cstr(0))]).find(exists(it))`; `:214` `avra_self_dir()` | which file IS this compiler | feeds the row above; null → `unnamed_print()` = `"unnamed-${now_ns()}-${next_serial()}"` (`build.av:271-273`), a store nobody reads back |
| `C/commands/shared.av:144-146` `std_root()` = `toolchain_files(["../packages", "../lib/avra/std"]).find(is_dir(it))` | std root | not recorded; std sources enter `program_key` through the remembered closure (`build.av:515-523`) |
| `C/commands/shared.av:150-152,155-158,456-459`; `dev.av:256` | runtime archive, wasm archive, wasm runner, dom glue | archive bytes via `links_text`; others no |
| `A/compiler/build.av:256` `avra_spawn_status("mv", ["-f", staged, to])`; `:391` `"rm", ["-rf", dir]`; `:504` `"chmod", ["+x", staged]`; `:739` linker; `:867` wasm-opt | spawns by NAME through PATH | no |
| `C/commands/shared.av:296,298,312` `() -> now_ns()` (workspace clock); `A/compiler/build.av:251,272,797`; `C/commands/fmt.av:210…284`; `phase.av:11,13`; `dev.av:389,397` | clock | timings, staged-file names, the unnamed nonce, bc scratch name; never a validity input |
| `A/compiler/build.av:219` `"${avra_own_pid()}"`; `:351` `avra_pid_alive(pid) == 1` | store user marks | sweep only |
| target | CLI `--target` option (`C/commands/shared.av:615-619`) | keyed via `built_for` (`build.av:452-458`): "The mode folds into the compiler's print"; the HOST triple/CPU is never read or keyed (NOT VERIFIED beyond grep) |


---

## B. Every place that persists

### B.0 Where it lands

- Root: `<tree_root>/.avra-cache/<compiler print>/` — `stores_dir` = `joined_path(tree_root(ws), ".avra-cache")` (`A/compiler/build.av:224`); `build_cache_root` = `joined_path(stores_dir(ws), ws.compiler_id())` (`:201`). `tree_root` = nearest ancestor with `.git`, else highest `avra.toml` (`:401-410`).
- A row = two files: `<root>/<family>/<key[0..2]>/<key>` and `<…>.deps` (`A/compiler/store/store.av:86-93`).
- `node_key(family, parts)` = `digest_of(joined([family.name()].concat(parts), "\n"))` (`store.av:78-80`); `digest_of` is a 4-lane 63-bit multiply-rotate fold printed as `a.b.c.d` decimal (`A/core/digest.av:121-129`).
- Beside the rows, in the store root: `compilers` (the roll, one level up), `.users/<pid>`, `hold-refused.log`, scratch `<key>.o` and `<digest>.bc`.

### B.1 The 18 Store write call sites (MEASURED: `grep -rnE "\.(keep|keep_once|keep_file)\("`, minus `values.keep`/`Table.keep`)

| # | file:line | Family | Row |
|---|---|---|---|
| 1 | `A/compiler/db.av:593` `store.keep(Stored.Rows, durable_key(row.kind(), row.key()), encoded(row), [])` | Rows | every durable `DbRow` (8 kinds) |
| 2 | `A/compiler/derive.av:200` (`remember`) | Unit | `homes`, `closure`, `embeds` |
| 3 | `A/compiler/derive.av:509` `keep_once(Stored.Unit, self.asks_key(...), self.wanted_list_wire(asks))` | Unit | `asks` |
| 4 | `A/compiler/derive.av:530` `keep_once(Stored.Unit, clean_key(asked), "")` | Unit | `clean` |
| 5 | `A/compiler/derive.av:749` `store.keep(Stored.Unit, key, wire, [])` | Unit | `parts`, `seen` |
| 6-8 | `A/compiler/derive.av:761,764,765` `keep_once(Stored.Warn, said_key/rules_key/findings_key(okey), …)` | Warn | `said`, `rules`, `findings` |
| 9-10 | `A/compiler/interface.av:66,85` `.keep(Stored.Unit, key, settled_wire(value)/reach_wire(...), [obj_key_of(...)])` | Unit | `const` (value or structural refusal) |
| 11-12 | `A/compiler/kept_settle.av:152,153` | Unit | `kept-settle` value and `#lines` |
| 13 | `A/compiler/suite.av:128` `keep_once(Stored.Unit, self.proved_key(store, path), "")` | Unit | `proved` |
| 14 | `A/compiler/build.av:734` `keep_file(Stored.Obj, asked, program.obj, [])` | Obj | program module under what it is a function of |
| 15 | `A/compiler/build.av:757` `.keep(Stored.Unit, links_key(key), links_text(...), [key])` | Unit | `links` |
| 16 | `A/compiler/build.av:763` `keep_file(Stored.Bin, key, ready, [key])` | Bin | linked binary |
| 17 | `A/compiler/build.av:764` `keep(Stored.Warn, key, d.warnings, [key])` | Warn | a build's warnings |
| 18 | `A/compiler/build.av:821` `keep_file(Stored.Obj, o.key, o.obj, [])` | Obj | each owed object |

`Db.insert` (#1) is reached only through the 8 accessors `@derive(Rows)` generates (`A/compiler/rows_derive.av:55-57`: `fn ${writer(v)}(store: Store, key: …, facts: …) { self.insert(store, DbRow.${v}(key, facts)) }`): `insert_sig` `record.av:571,572`; `insert_warn/licenses/findings` `derive.av:244-246`; `insert_scan` `voices.av:690`; `insert_canon` `C/commands/fmt.av:281,307`; `insert_decl` `C/commands/docs.av:94`; `DbRow.Answer` `A/compiler/answers.av:17`.

### B.2 The 27 row kinds

Key ingredients legend: **CP** = compiler print folded INTO the key (every row is additionally under the per-print store root); **okey** = `key_of_parts(KeyParts)` = digest(module, path, text digest, each run-file's text digest, `seen_digest` of every seen module's interface key) (`A/compiler/record.av:1297-1306`) — NO compiler print inside; **PK** = `program_key` = digest(CP, relative entry name, `path\tlen.digest` of every `build_inputs` file + `beside` + embeds, `path\tdigest` of every reached package object) (`A/compiler/build.av:589-609`).

| Kind | Saved (type) | Key | Encoding | Validated on recall by | Class |
|---|---|---|---|---|---|
| `Rows/Decl` | `DocFacts { root, listing_digest, answer, files: List<FileWitness> }` (`db.av:118-123`) | `db_qualified(root, compiler, name)` = `"${root}::${compiler}::${name}"` (`db.av:572`) → `durable_key` | hand-written `encoded_docfacts` (`db.av:130-138`): 3 `wire_escape`d lines, a count, then doubly-escaped witnesses; `@derive(Exemplar)` only makes test exemplars | `still_valid` `db.av:662-663`: `facts.listing_digest == current_listing_digest(facts.root) && facts.files.all((w) -> current_file_digest(w.path) == w.digest)` | **re-digested** |
| `Rows/Sig` (head) | interface digest string | `record_key(m)` = `node_key(Stored.Sig, [compiler_id, root, module])` (`record.av:51`) | identity (the text) | row itself: `true` (`db.av:664`). The record it points at is validated per FILE by `written_from(at, ws.text_digest(f))` (`record.av:806,840-842`: `at!.file[2] == print`), whole by `record_fault` (`record_complete` + stray file, `:819-834`) and `record_stands` (`:1046`) | name-keyed, **mutable**, validated by the reader |
| `Rows/Sig` (body) | the module record text | `RecordBodies.key(module, iface)` = `node_key(Stored.Sig, [compiler, root, module, iface])` (`record.av:65`) | hand-written line format (`record.av`/`interface.av`): `iface\t…`, `import\t…`, `ref\t…`, `reexport\t…`, `file\t<path>\t<text digest>\t<runs|…>\t<file iface>`, then one line per declaration (shape word, file, ordinal, stmt, exported, name, kind, owner, …, facts block with its own fingerprint check `record.av:557`) | as above; NOT content-addressed by its body: "A body edit rewrites the body its interface already names" (`record.av:60`) | (module, iface)-keyed, **overwritten in place** |
| `Rows/Warn` | rendered warnings | PK of `"check:${entry}"` (`derive.av:223-224,241`) | identity | none — `true` | content-addressed |
| `Rows/Licenses` | stale `// LICENSED` lines, `file\tline\tid` | same key as Warn | identity | none | content-addressed |
| `Rows/Findings` | `rule\tfile\ttext` lines | same key | identity; a MISSING row reads `null` = unknown (`derive.av:232-235`) | none | content-addressed |
| `Rows/Scan` | `"1"`/`"0"` | `digest_of("scan\n${compiler_id}\n${text}")` (`voices.av:687`) | identity | none | content-addressed |
| `Rows/Canon` | `""` (presence) | `digest_of("fmt.canonical\n${compiler_id}\n${block_word_key}\n${text}")` (`C/commands/fmt.av:83-87`) | identity | none | content-addressed |
| `Rows/Answer` | a `@query` answer's record, hex (`answers.av:17,34`) | `"${key_of_parts(parts)}\t${query}\t${args}"` (`answers.av:13,29`) | hex of std-relation's stable `Writer` bytes | none ("a moved part names another key, so the row holds unconditionally" `db.av:320-322`) | content-addressed; **no production writer** |
| `Unit/asks` | a file's bodies' instantiation asks | `node_key(Unit, ["asks", okey])` (`workspace_analysis.av:393`) | `wanted_list_wire` (hand-written, registered codec) | decode failure → file read (`Reads.AsksUnread`, `workspace_analysis.av:404`) | content-addressed |
| `Unit/clean` | `""` | `["clean", asked]`, `asked` = `asked_print` (`derive.av:685-694`): digest(root asks' wires, `path\tokey` of each remembered home) | presence | none | content-addressed |
| `Unit/const` | settled value or `R1…` refusal | `["const", okey, name]` (`interface.av:116`) | `settled_wire` / `reach_wire` (`settlement_wire.av:35,139`; `Sv…`-style length-prefixed fields) | presence gates the hold (`const_rows_ready`, `interface.av:106-112`); decode at `fill_const` | content-addressed; only kind whose `.deps` names something (`[obj_key]`) |
| `Unit/kept-settle` + `#lines` | a read file's const verdict + its witness lines | `node_key(Unit, ["kept-settle", path, name])` (`kept_settle.av:287`) — **name-keyed** | value: `settled_wire`/`reach_wire`; lines: TSV, one witness per line (B.4) | `kept_verdict`: `if !rows.all((r) -> self.kept_row_stands(r)) { return null }` (`kept_settle.av:163`) | **re-validated line by line** |
| `Unit/proved` | `""` | `["proved", path, <.expected text>, <text digests of every seen file>]` (`suite.av:184-190`) | presence | none | content-addressed |
| `Unit/links` | `path\tdigest` per linked file | `["links", PK]` (`build.av:316`) | TSV | `links_unchanged`: `links_text(files) == kept` (`build.av:326-330`) — re-digests the runtime archive and package objects | **re-digested** (validates `Bin`) |
| `Unit/homes` | paths of files instantiations lowered from | `["homes", entry-or-root]` (`derive.av:189,551`) | newline list, grow-only (`remember` `derive.av:198-201`) | filtered by `host.exists` (`derive.av:686`); `home_moved` (`:614-620`) | name-keyed, **mutable, grow-only** |
| `Unit/closure` | `src\troot` per package | `["closure", root, named]` (`build.av:526`) | newline list, grow-only | none: "over-covering costs a rebuild, under-covering is a silently wrong binary" (`build.av:512-513`) | name-keyed, mutable |
| `Unit/embeds` | embedded file paths | `["embeds", root, named]` (`build.av:538`) | newline list, grow-only | none (feeds PK) | name-keyed, mutable |
| `Unit/parts` | a file's `KeyParts` | `["parts", path]` (`record.av:1310`) | `parts_wire` (`module\t…`, `path\t…`, `text\t…`, `run\t…`, `seen\t…`) | diagnostic only (what moved: `keep_parts` `derive.av:722-743`) | name-keyed, mutable |
| `Unit/seen` | a module's seen interfaces | `["seen", module]` (`record.av:1323`) | `seen_wire` | diagnostic only | name-keyed, mutable |
| `Warn/said` | a file's warnings + its cases | `node_key(Warn, ["said", okey])` (`derive.av:133`) | `said_wire`: count, `symbol\tlabel` lines, warnings (`derive.av:156-163`) | `said_of` decode; absent → file read (`stands_in` `derive.av:344-347`) | content-addressed |
| `Warn/rules` | rendered rule findings | `["rules", okey]` | identity | presence (`ruled`) | content-addressed |
| `Warn/findings` | a file's finding rows | `["findings", okey]` | TSV | presence | content-addressed |
| `Warn/<PK>` | a build's warnings | PK directly (`build.av:764`; read `:506`) | identity | rides `Bin` | content-addressed |
| `Obj/<okey>` | a file's object bytes | okey (`build.av:779`) | raw bytes (`keep_file`) | `store.has`/`place` | content-addressed |
| `Obj/program` | the program module's object | `node_key(Obj, ["entry", bitcode digest, tools.opt, tools.runtime])` (`build.av:696-704`) or `["program", d.asked, fp of main's ins, doors, tools.opt, tools.runtime]` (`:846-857`) | raw bytes | presence | content-addressed |
| `Bin/<PK>` | the linked binary | PK (`build.av:763`) | raw bytes; mode lost ("a stored binary is bytes, and its mode is not in them" `:503`) | `store.has(Bin, key) && links_unchanged(store, key) && store.place(...)` (`build.av:498-500`) | content-addressed + **re-digested links** |

"Holds unconditionally": everything in the content-addressed class (17 kinds) — the argument is always the same and is stated at `db.av:654-659`: "`Sig`/`Warn` carry their own validity in the caller's key (a module/program identity that changes when its inputs do) and hold unconditionally here; `Decl` alone has a witness pair to re-check."

### B.3 `still_valid`, precisely (`A/compiler/db.av:660-670`)

```
fn still_valid(row: DbRow) -> bool {
    match row {
        .Decl(_, facts) -> facts.listing_digest == current_listing_digest(facts.root) &&
            facts.files.all((w: FileWitness) -> current_file_digest(w.path) == w.digest),
        .Sig(_, _) or .Warn(_, _) or .Scan(_, _) or .Canon(_, _) or .Licenses(_, _) or .Findings(_, _) or .Answer(_, _) -> true,
        rest -> { avra_trap("defect: still_valid asked of a non-durable DbRow") false },
    }
}
```

| DbKind | still_valid | Why the code says it is safe | What actually carries validity |
|---|---|---|---|
| Decl | re-walks the package's `.av` listing (`current_listing_digest`, `:675-678`, direct `@std.io`) and re-reads+digests every witnessed file (`:694-696`) | "the original Phase 1 witness design … not yet the general recorded-dependency walk a RESOLVED-type answer would need" (`db.av:45-49`) | the two witnesses. NOT covered: the manifest, dependencies' files, the compiler (covered by `db_qualified`'s compiler segment), std packages |
| Sig | `true` | "validity is record.av's own business (a moved-records retry), not this row's" (`db.av:294-296`) | reader-side `written_from`/`record_fault`/`record_stands`; `keep_interfaces` rewrites when `made != prior` (`record.av:569`); `Attempt.adrift` retries twice (`derive.av:51-53`) |
| Warn, Licenses, Findings | `true` | key is `program_key` of all inputs | PK |
| Scan, Canon | `true` | key is the text's digest + compiler print | key |
| Answer | `true` | key is the file's `KeyParts` digest | key (but KeyParts has no compiler print; the store root does) |

`Db.get` order (`db.av:580-587`): in-process `rows` map → `recalled` (store get → `decoded` → `still_valid`) → cache in `rows`. An in-process hit is never re-validated.

### B.4 The kept-settle witness lines (`A/compiler/kept_settle.av`)

| Letter | Line | Written | Stands when (`kept_row_stands`, `:171-181`) |
|---|---|---|---|
| `u` | `u\t<path>\t<text digest>\t<decl ref>\t<decl syntax hash or "">\t<unit shape>\t<entered 0/1>\t<wanted wire>` | `kept_unit_line` `:87-107` + `finished_line` `:291-295` | text digest unchanged; else the decl resolves, is not held, and its `syntax(d)` equals; else (only if the run did NOT enter it, `r[6] != "1"`) it re-lowers to the same call shape (`:186-196`) |
| `c` | `c\t<path>\t<const name>\t<verdict fp>` | `logged_const_read` `:124-127` | the const settles again to the same `verdict_fp` (`:275-283`) — recursion into `settled` |
| `m` | `m\t<module>\t<files,comma>` | `module_line` `:228` | `module_files(m).join(",") == r[2]` — the LISTING |
| `f` | `f\t<path>\t<text digest>\t<outline or "">` | `file_line` `:231-241` | text unchanged, or the file is read and its `outline` (decl syntax + `use` lines) equals (`:245-249`) |
| `b` | `b\t<steps>:<bytes>` | `budget_line` `:310` | budgets unchanged |
| `e` | `e\t<path>\t<embed_said>` | `:151` | `embed_said(path)` equals (re-reads the file) |
| `x` | `x` | a read no line can name (`:121-122`) | never written: "a settlement that read what no line can name is not kept" (`:136`) |

### B.5 `Store` (`A/compiler/store/store.av`, 197 lines)

| Aspect | Fact | Cite |
|---|---|---|
| `Stored` | `Sig, Fp, Unit, Obj, Bin, Warn, Rows` → dirs `sig fp unit obj bin warn rows` | `:21-58` |
| Dead families | no `keep`/`get` names `Stored.Fp` anywhere; `Stored.Sig` appears only as `node_key(Stored.Sig, …)` name prefixes (`record.av:51,65`), the rows are written under `Rows` | MEASURED: `grep -rn "Stored\.Fp\|Stored\.Sig"` → 2 lines, both `node_key` |
| `Store` | `{ root: string, keeping: Keeping }`; opened per use: `Store { root: build_cache_root(self), keeping: self.keys.keeping.get() }` | `:69`; `build.av:185` |
| `has` | `self.aside_row(family, key) != null || self.on_disk(family, key)`; `on_disk` = `exists(path) && exists(edge_path)` — "NOTHING read" | `:104-110` |
| `get` | `self.aside_row(family, key) ?? self.read_disk(family, key)`; a read error is `null` | `:118-123` |
| `keep` | Disk → `written`; Aside → `rows.put(self.path(family, key), bytes)` | `:126-134` |
| `written` | `make_dirs(shard)`; `uncommit` (remove old `.deps`); `write_text(data)`; `write_text(.deps, joined(read, "\n"))` — "the DATA first, then the EDGES, so the second write is what makes the row visible" | `:136-149` |
| `keep_once` | `self.has(family, key) || self.keep(...)` | `:153-155` |
| `keep_file` | reads the file's bytes then writes data + `.deps`; Aside → `false` ("A store that keeps aside keeps no file") | `:166-185` |
| `place` | `read_bytes(path)` → `write_bytes(to, bytes)` | `:189-196` |
| The `read` slot (edges) | a `List<string>` written to `<key>.deps`. Passed non-empty at exactly 5 sites: `[obj_key]` (`interface.av:71,90`), `[key]` self-reference (`build.av:761,763,764`). **Never read back**: `edge_path` has 4 uses, all in store.av (`:93,98,109,145/181`) | MEASURED |
| `Keeping.Aside(Cell<Map<string, string>>)` | set by `Workspace.inspecting()` (`build.av:189`), used by `cache_walk` (`cache_walk.av:50`); writes go to an in-process map keyed by the row's PATH, reads check it first; carried across restarts (`workspace.av:685`) | `store.av:63-66,112-115` |
| Root keyed by compiler digest | `compiler_print` = digest of the binary's bytes + `codegen_mode()` + `@mode`; hashed fresh once per workspace | `build.av:296-309` |
| `rolled` (generation roll + sweep) | appends `"${print}\t${at}"` to `.avra-cache/compilers`, keeps the newest `STORES_KEPT = 4` lines, writes via `staged_beside` + `mv -f` (`published`), then `rm -rf`s every dir under `.avra-cache` that no kept line names and that has no live `.users/<pid>` (`has_live_user` prunes dead pid marks) | `build.av:227,381-393,361-369` |
| Runs when | every `compiler_id()` first ask in a workspace → every process that opens a store rewrites the roll and lists/sweeps the store dir | `build.av:166-169,303-307` |
| Per-row eviction | **none**. No size cap, no LRU, no age. A row dies only with its whole store (5th-newest compiler) | — |
| Scratch leak | `<root>/<key>.o` for every read file's object (`build.av:783`) and one `<digest>.bc` per link named by `now_ns()` (`:797`) are written into the store root and never removed (no `remove` on either; MEASURED by grep) | NOT VERIFIED on disk |
| Atomicity of one file | `write_text`/`write_bytes` = temp `"%s.avra-%ld.tmp"` (pid) + `close` + `rename` (`packages/std-io/src/c/std_io.c:166-205`; `io.av:281-299` "a reader sees the old file or the new, never half") | per-file atomic |
| fsync | none on this path: `avra_fd_sync` (`std_io.c:85-88`) is called only by the separate `synced` verb (`io.av:332`); the store never calls it | not crash-durable |
| Atomicity of a row | two renames (data, then `.deps`); `uncommit` removes the old `.deps` first so "a crash between them leaves nothing rather than half" | `store.av:95-101,136-149` |
| Locking | **none** (no `flock`, no lock file). Concurrency story is: content keys ⇒ same bytes; binaries staged+renamed; the roll tolerates a lost update (`build.av:377-379`) | — |
| Concurrency hole (INFERRED, not run) | for a MUTABLE name-keyed row (record head/body, `homes`, `closure`, `embeds`, `parts`, `seen`, `kept-settle`): W1 uncommit → W1 data → W2 uncommit (no-op) → W2 data → W1 `.deps` ⇒ the row is visible holding W2's data with W1's commit; and `kept-settle`'s value and `#lines` are two independent rows (`kept_settle.av:152-153`) that two writers can interleave. `remember` is read-modify-write with no lock (`derive.av:198-201`) | NOT VERIFIED |

### B.6 Other things written to disk as caches

| What | Where | Key / validation |
|---|---|---|
| The published binary beside its source / `build/suite` | `build.av:505,765` (`published(staged, binary)`) | a copy of `Bin/<PK>` |
| `<pkg>/build/<stem>.ll` | `C/commands/shared.av:364-366` | none (always rewritten) |
| `hold-refused.log` | `derive.av:314-315` | last refusal's words |
| `.users/<pid>` | `build.av:217-220` | liveness marks |
| `bootstrap/seed.ll` (+ sources hash) | Makefile `seed` (`:333`), `tools/sources_hash.sh` | "`make seed` records this beside the seed, so a fresh checkout can ask whether the seed already IS its compiler" |
| `build/.gate-green` | `tools/gate_receipt.sh` | the tree hash the gate read |
| `tools/dep_audit.tsv` | `tools/dep_audit.sh` + `A/compiler/dep_audit.av` (`write_text`) | the unrecorded-read ledger |
| idiom baseline | `C/commands/check.av:95` | ratchet file |
| docs output | none cached beyond `Rows/Decl`; `avra docs` with no name is "A pure read, deliberately" (`C/commands/docs.av:118-124`) | — |

---

## C. The kernel (`A/query/`, 4 files, 1189 lines)

### C.1 Types

| Type | Definition | Cite |
|---|---|---|
| `Key` | `{ family: int, arg: int }` | `kernel.av:20` |
| `Verdict` | `Reuse \| Compute \| Cycle` | `kernel.av:26-30` |
| `QueryCell` | `{ deps: List<Key>, changed_at: int, verified_at: int, value_hash: int? }` | `kernel.av:41` |
| `KernelState` | `rev`, `cells: List<Cell<List<QueryCell?>>>` (one table per family, indexed by arg), `verifiers: List<fn(int) -> int>`, `pending: List<Cell<List<Key>>>`, `open: List<Key>`, `restore: List<Cell<List<Restore>>?>`, `began: List<int>`, `next_reader` | `kernel.av:53-89` |
| `Kernel` (`@identity`) | `state: Cell<KernelState>`, `hits`, `misses`, `readers: Cell<List<int>>`, `stamps: Cell<List<Cell<List<int>>>>`, `whole_families`, `whole`, `audit: Audit` | `kernel.av:119-141` |
| `Audit` | the dependency audit's state (`on`, `held`, `seen`, `exempt`, `covers`, `sink`, `reach` memo …) | `kernel.av:101-114` |
| `Relation<T>` | `{ kernel: Kernel, family: int, values: Table<T> }`; `alias Memo<T> = Relation<T>` | `memo.av:31,35` |
| `MemoAsk<T>` / `MemoStart<T>` / `Loaded<T>` | `Reuse(T) \| Compute \| Cycle`; `Reuse(T) \| Compute`; `{ value, fingerprint }` | `memo.av:17-26` |
| `Fixpoint<T>` | `{ db: Kernel, family, bottom, join, fp, frame_family: Cell<int>, values: Table<T>, turn_cap }` | `fixpoint.av:36-54` |
| `KeyMarks` | `{ rows: Cell<List<Cell<List<int>>>> }` | `marks.av:5` |
| `Db` (compiler) | `{ kernel: Kernel, rows: Cell<Map<string, DbRow>>, families: Cell<List<Relation<DbRow>>> }` | `A/compiler/db.av:553` |

### C.2 Public verbs

`Kernel` (`kernel.av`): `new_kernel() -> Kernel` (149); `audit_to(width, exempt, covers, sink)` (190); `bypassed(verb, subject)` (205); `revision() -> int` (292); `bump()` (294); `family(verify: fn(int) -> int) -> int` (300); `disarm()` (314); `set_input(key, value_hash)` (320); `input_unread(key, value_hash)` (344); `ask(key) -> Verdict` (353); `active(key) -> bool` (383); `family_active(family) -> bool` (390); `reader() -> int` (398); `changed_at(key) -> int` (402); `cell(key) -> QueryCell?` (407); `deps_of(key) -> List<Key>` (410); `settled_keys() -> List<Key>` (416); `value_hash_of(key) -> int?` (428); `begin(key)` (432); `reads_whole(family)` / `reading_whole()` (455/461); `settle(key, value_hash)` (463); `settle_lazy(key, fingerprint: fn() -> int)` (488); `abandon(key)` (505); `record_dep(key)` (559); `record_at(family, arg)` (568); `sweep()` (627); `evict_family(family)` (641); `stats() -> string` (659).

`Relation<T>` (`memo.av`): `new_memo<T>(db, family)` (37); `query_key(arg)` (42); `ask(arg) -> MemoAsk<T>` (44); `start(arg) -> MemoStart<T>` (59); `start_recursive(arg)` (73); `finish(arg, value, fingerprint) -> T` (83); `finish_lazy(arg, value, fingerprint: fn(T) -> int)` (90); `begin(arg)` (94); `open(arg) -> bool` (98); `evict()` (102); `settle` / `settle_lazy` (107/118); `input(arg, load: fn() -> T, fingerprint: fn(T) -> int) -> T` (128); `input_loaded(arg, load: fn() -> Loaded<T>) -> T` (145); `demand(arg, compute, fingerprint) -> T` (161); `cycle_value(arg)` (173).

`Fixpoint<T>` (`fixpoint.av`): `new_fixpoint` (63); `value_at(arg) -> T` (109); `step` (119); `solve(members, compute) -> Result<int, FixpointRefusal>` (197); `spoken(r)` (238).

`Db` forwards verbatim (`db.av:606-649`): `ask begin settle abandon record_dep deps_of settled_keys value_hash_of family relation family_active revision active changed_at disarm stats`, plus `get`/`insert`/`recalled` for durable rows.

### C.3 Mechanics

| Topic | How | Cite |
|---|---|---|
| Dep recording | `ask` calls `record_dep(key)` FIRST, so the asker's frame records the edge even on a hit. `record_dep`: `let reader? = self.readers.get().last() else { return }` / `let stamp = self.stamp_of(key.family, key.arg)` / `if stamp == reader { return }` / `self.newly_read(key, stamp, reader)` | `kernel.av:353-354,559-564` |
| `newly_read` | if the overwritten stamp belongs to a still-open ancestor, save it (`save_restore`); write the stamp; `s.pending.last()!.push(key)`; `self.replace(s)` | `kernel.av:588-594` |
| Dedup | one int per key per family (`stamps`), "the reader id that last recorded it"; a repeat read by the same frame is "one indexed compare" | `kernel.av:130-135,552-558` |
| Per-query dep list | `pending: List<Cell<List<Key>>>` — one growable `List<Key>` per open frame, moved into `QueryCell.deps` at settle (`closed_frame`) | `kernel.av:65-69,516-527` |
| Per-edge memory (ESTIMATED from layouts) | a `Key` is a 2-field record = one boxed block: `Header` 16 B (`runtime/avra_box.h:40-45`) + `AvraArray` 40 B (5 words, `:52-59`) + `buf_bytes(2)` = 2×(8+1) = 18 B (`runtime/avra_runtime.c:1273-1275,1347`) = 74 B payload+header → size class of 16 (`CLASS_BYTES 16`, `:211`) ⇒ **80 B**, plus the slot in the deps list 8 B + 1 mark byte ⇒ **≈ 89 B per recorded edge**, before list growth slack. Plus 8 B (one stamp int) per distinct key ever read. `record_at` exists so "a repeat allocates nothing" (`kernel.av:566-567`) | ESTIMATED |
| Per-cell memory (ESTIMATED) | `QueryCell` 4 fields: 16 + 40 + 36 = 92 → 96 B, + its deps list box (16 + 40 + own buffer) ≈ 56 B + 9 B/edge slot | ESTIMATED |
| Verify | `ask`: no cell → miss; `verified_at == rev` → hit; else mark verified, then `any_dep_changed`: for each dep `verify(dep.arg) > cell.verified_at` where `verify` = the dep family's registered verifier | `kernel.av:357-381` |
| Family verifier (compiler) | `ws.refetched(f, arg)`: RE-ASKS the dep through its own query (`touch(self.parsed(file_at(arg)))` …) then answers `self.db.changed_at(key(f, arg))` | `A/compiler/workspace.av:959-995` |
| Early cutoff | `settle`: `kept_since(state_cell(s, key), value_hash) ?? state_revision(s)` — an unchanged hash keeps the old `changed_at` | `kernel.av:463-476,677-679` |
| Lazy fingerprint | `settle_lazy`: no prior cell → `value_hash = null`, fingerprint never computed ("a fresh key … costs nothing"); used by Visible, Resolved, Typed, Folded, Analysis, Lowered, LiftLowered | `kernel.av:478-499` |
| Revisions | `rev` starts at 1; moves only in `set_input` when an existing input's hash changes (`s.rev = state_revision(s) + 1`) or `bump()`. A query settles as verified at the revision it BEGAN at (`began`) | `kernel.av:151,320-339,83-87` |
| `bump()` callers | **none** outside tests (MEASURED: `grep -rnE "\.bump\(\)"` over `A/`, `C/`, `R/`). The revision still CAN move inside one compile: `set_input` is called directly for the `Named` family — `named_now(b)` = `self.record_kernel.set_input(self.name_key_at(b), self.decl_row_rows.get().bucket_hash(b))` (`A/features/decls.av:1055-1057`), which is `Family.Named`'s verifier (`workspace.av:990`); a name bucket whose hash moved after a reader saw it bumps `rev` | `kernel.av:336`; `workspace.av:814-819` says "the revision never moves" for the one-shot case |
| Cycle | `if seen.open.any(same_key(it, key)) { return Verdict.Cycle }` — a linear scan of the open stack on every ask. `Relation.start` answers `cycle_value` (the stored value or a TRAP `missing_value`); `start_recursive` re-opens the frame (a "smaller view") | `kernel.av:356`; `memo.av:59-81,173-178` |
| `abandon` | closes a frame without settling; its reads become the enclosing frame's (`for d in deps { self.record_dep(d) }`) — used by `methods()` when the table cannot be completed | `kernel.av:505-511`; `workspace.av:1782` |
| `Relation.input` | first sight: `load()`, `set_input(key, fingerprint(value))`, `record_at`, keep value; later: `record_at` and return the kept value — **the loader never runs twice in a process**, so an input cannot change after first read without an explicit `set_input` | `memo.av:128-141` |
| Grain | `reads_whole(family)` for `Lowered, LiftLowered, Lifted, Settled` — inside them a declaration-row read records the file's `Items` cell, not the name bucket | `workspace.av:514-519,762`; `A/features/decls.av:1009-1011` |
| Shutdown | `disarmed()`: evict `Analysis`, replace every verifier with a trapping `never_verify`, disarm Decls hooks | `workspace.av:820-827`; `kernel.av:314-318,709-712` |
| Persistence of cells/deps | **none**. `avra cache why/dependents` re-derives "the program in-process with nothing held, and walks the kernel's own dependencies there" | `A/compiler/cache_walk.av:4-6` |
| Audit | `AVRA_DEP_AUDIT` + a compiler built with `audit_build`: every Decls table read that skipped `ask` is held (`bypassed`) and judged at the outermost settle against `covers` | `kernel.av:96-100,205-236`; `A/compiler/dep_audit.av:52-66` |

### C.4 Every query family (32) — `A/compiler/families/families.av`; registered in a loop `for f in Family.all() { if ws.db.family((arg: int) -> ws.refetched(f, arg)) != f.ordinal { … } }` (`A/compiler/workspace.av:760-763`)

| # | Family (families.av line) | Key | Value held | Where the value lives | Query fn (file:line) | Fingerprint | Persisted? |
|---|---|---|---|---|---|---|---|
| 0 | Source (17) | FileId | `SourceFile` | `Db.families[0]` `DbRow.Source` | `source` `workspace.av:1130` (INPUT) | `fp_str(text)` `:1139` | no |
| 1 | Parsed (21) | FileId | `Parsed` | `DbRow.Parsed` | `parsed` `workspace.av:1152` (`demand`) | `parsed_fingerprint` = `fp(121, [program_hash(p), fp_str(sorted sublang words)])` `:491-494` | no |
| 2 | Items (25) | FileId | `List<DeclId>` | `DbRow.Items` | `items` `workspace.av:1428` (`start`/`finish`) | `fp_list([row_print(d) …])` `:1445` | no (a held file answers from its record, `:1431`) |
| 3 | Namespace (29) | ModuleId | `ModuleNames` | `DbRow.Namespace` | `namespace` `workspace.av:1496` (recursive) | `fp(3, [bound ids, apart ids, clashes.length])` `:1510-1517` — folds DENSE DeclIds | no |
| 4 | Visible (33) | FileId | `Namespace` | `DbRow.Visible` | `visible` `workspace.av:1528` (recursive, lazy) | `namespace_fp` | no |
| 5 | Resolved (37) | FileId | `NameFacts` | `DbRow.Resolved` | `resolved` `workspace.av:1573` (recursive, lazy) | `name_facts_fp` | no |
| 6 | Sig (41) | DeclId | `DeclSig` | **`Decls.sigs`** (not the Relation) | `sig` `workspace.av:1669` (raw ask/begin/settle) | `sig_hash(out)` = `s.fingerprint()` `:2043-2046` | via the module record's lines |
| 7 | Methods (45) | DeclId | `List<DeclId>` | `Decls.methods` | `methods` `workspace.av:1749` (raw; may `abandon`) | `fp_str(joined(method names, ","))` `:1790` | via record children |
| 8 | Typed (49) | DeclId | `TypeFacts` | `DbRow.Typed` | `typed` `workspace.av:1927` (recursive, lazy) | `type_facts_fp` | no |
| 9 | ConstTyped (53) | settle-int | `TypeId` | `DbRow.ConstTyped` | `const_type_at` `workspace_analysis.av:530` | `ty.index` (a dense id) `:564` | no |
| 10 | Folded (57) | FileId | `TypeFacts` | `DbRow.Folded` | `folded` `workspace.av:1949` (recursive, lazy) | `fp(122, [fp_list(dep_hash_fp(value_hash_of(Typed d)) …)])` `:1987-1994` | no |
| 11 | Analysis (61) | FileId | `Analysis` | `DbRow.Analysis` | `analysis` `workspace_analysis.av:163` (recursive, lazy) | `fp(1, [Resolved hash, Folded hash, fp_list(diag_fp)])` `:194-201` | no |
| 12 | Settled (65) | settle-int | `Settlement` | `DbRow.Settled` | `settled_at` `workspace_analysis.av:568` | `settlement_hash(held)` `:584` | `Unit/const`, `Unit/kept-settle` |
| 13 | Lowered (69) | ask-int | `Unit` | `DbRow.Lowered` | `lowered_in` `workspace_analysis.av:369` (recursive, lazy) | `unit_fp` `:378` | objects (`Obj`), `asks` |
| 14 | Lifted (73) | lift-int | `LiftResult` | `DbRow.Lifted` | `lifted_at` `workspace_analysis.av:712` | `lift_hash(held)` `:724` | no |
| 15 | Manifest (77) | int (package ordinal) | `Manifest` | `DbRow.Manifest` | `manifest` `packages.av:48` (INPUT) | `fp_str(text)`; `0` for no manifest | no |
| 16 | Receivers (81) | unit (0) | — | `Decls.written_seats` | `receivers` `receivers.av:46` (raw) | `writers_print(fns)` `:63` | via record lines |
| 17 | Expanded (85) | FileId | `List<DeclId>` | `DbRow.Expanded` | `expanded` `expand.av:95` (recursive) | `fp(31, [d.index …])` `:118` — dense ids | no |
| 18 | Plain (89) | FileId | `Parsed` | `DbRow.Plain` | `plain_parsed` `workspace.av:1173` (`demand`) | `program_hash` `:1180` | no |
| 19 | References (93) | unit | — | `Decls.refs_db` (`Ref` relation) | `references` `references.av:72` (raw) | `fp(41, [fp_list(fps ++ held_fps)])` `:106` | `ref` lines in the record |
| 20 | Failures (97) | unit | — | `Decls.inferred_errs`, `failures_db` | `failures` `failures.av:453` (raw) | `fp(21, …inferred error TypeId indexes)` `:465-471` | no |
| 21 | HeldSig (101) | ModuleId | record text | `records.record_texts` | `held_sig_asked` `workspace.av:1734` (raw) | `fp_str(text)` `:1740` | it IS the persisted record's dep |
| 22 | Raised (105) | DeclId | `List<TypeId>` | `raised_fixpoint.values` | fixpoint, `workspace.av:753` | `raised_fp` | no |
| 23 | MethodDiags (109) | FileId | `List<Diag>` | `method_diag_rows` | `method_diagnostics` `workspace_analysis.av:92` (raw) | `diags_fingerprint` `:77-79` | no |
| 24 | LiftLowered (113) | lift-int (shares `asks` ids) | `Unit` | `Db.families[24]` as `DbRow.Lowered` | `lift_lowered` `workspace_analysis.av:364` | `unit_fp` | no |
| 25 | Syntax (117) | DeclId | hash only | kernel `value_hash` | `syntax` `workspace.av:1807` (raw) | `syntax_hash` `:506-509` | compared in kept-settle `u`/`f` lines |
| 26 | Names (121) | DeclId | hash only | kernel `value_hash` | `name_slice` `workspace.av:1822` (raw) | `name_slice_fp` `:1827` | no |
| 27 | Marks (125) | DeclId | `List<Diagnostic>` | `Decls.marks` | `computed_marks` `workspace.av:914` (raw) | `use_warnings_fp` `:926` | no |
| 28 | Admitted (129) | FileId | — | — | `admission` `workspace.av:1454` (raw) | constant `0` `:1465` | no |
| 29 | Named (133) | name bucket | — | `Decl` relation's name index bucket | a THIRD INPUT family, set by hand: `bucket_moved` → `input_unread` (`A/features/decls.av:1021-1026`), verifier `named_now` → `set_input` (`:1055-1057`, `workspace.av:990`) | `Rows.bucket_hash(b)` (folds every same-named row's stable hash) | no |
| 30 | ReadReach (137) | unit | — | `read_fixpoint` | `read_reach` `workspace_analysis.av:215` (raw) | `fp(2, [fp_list(0/1 …)])` `:236-243` | no |
| 31 | DeclReads (141) | DeclId | `bool` | `read_fixpoint.values` | fixpoint `workspace.av:754` | `read_reach_fp` | no |

Counts: 16 families keep a typed value in `Db.families` (0-5, 8-15 except none, 17, 18, 24 — i.e. Source, Parsed, Items, Namespace, Visible, Resolved, Typed, ConstTyped, Folded, Analysis, Settled, Lowered, Lifted, Manifest, Expanded, Plain = 16, + LiftLowered reusing the `Lowered` variant); 16 use raw kernel verbs with the value in a hand table. `db.av:228-234`'s "first sixteen variants" matches.

Plus DYNAMIC families (not in `Family`): every std-relation relation reached under a kernel-hooked Db registers its own family through `kernel.family(...)`: the Decls Db via `kernel_hooks` (`A/features/decls.av:695-719`, armed at `:1088`) — `Decl`, `File`, `Module`, `DocFact` side column …; `failures_db` via `relation_hooks` (`A/compiler/workspace.av:571-586,752`) — `ErrorSite`, `Raised`; each `@query`'s `Memo` and each `@input`'s `InputSlot` also call `db.registered`. `Family.Named`'s rank (29) is a marker for the Decl name-bucket family (`arm_recording`, `workspace.av:788-795`).

---

## D. DbKind — 24 variants (`A/compiler/db.av:160-185`; rows `:275-324`)

| # | Variant | Row type | Inserted by | Read by | Index | Persists |
|---|---|---|---|---|---|---|
| 1 | Source | `SourceFile` | `workspace.av:1137` | `source_of` | dense `Db.families[Family.Source]` by FileId | no |
| 2 | Parsed | `Parsed` | `workspace.av:1156` | `parsed_of` | dense by FileId | no |
| 3 | Lowered | `Unit` | `workspace_analysis.av:378` (families 13 and 24) | `lowered_of` | dense by ask id | no (objects do) |
| 4 | Manifest | `Manifest` | `packages.av:55,65` | `manifest_of` | dense by package ordinal | no |
| 5 | Plain | `Parsed` | `workspace.av:1179` | `plain_of` | dense by FileId | no |
| 6 | Items | `List<DeclId>` | `workspace.av:1444` | `items_of` | dense by FileId | no |
| 7 | Namespace | `ModuleNames` | `workspace.av:1509` | `namespace_of` | dense by ModuleId | no |
| 8 | Visible | `Namespace` | `workspace.av:1554` | `visible_of` | dense by FileId | no |
| 9 | Resolved | `NameFacts` | `workspace.av:1612` | `resolved_of` | dense by FileId | no |
| 10 | Typed | `TypeFacts` | `workspace.av:1941` | `typed_of` | dense by DeclId | no |
| 11 | ConstTyped | `TypeId` | `workspace_analysis.av:543,564` | `const_typed_of` | dense by settle id | no |
| 12 | Folded | `TypeFacts` | `workspace.av:1986` | `folded_of` | dense by FileId | no |
| 13 | Analysis | `Analysis` | `workspace_analysis.av:193` | `analysis_of` | dense by FileId | no |
| 14 | Lifted | `LiftResult` | `workspace_analysis.av:724` | `lifted_of` | dense by lift id | no |
| 15 | Expanded | `List<DeclId>` | `expand.av:118` | `expanded_of` | dense by FileId | no |
| 16 | Settled | `Settlement` | `workspace_analysis.av:584` | `settled_of` | dense by settle id | no |
| 17 | Decl | `(name, DocFacts)` | `C/commands/docs.av:94` | `C/commands/docs.av:80` | `Db.rows: Cell<Map<string, DbRow>>` keyed `"${kind.tag()}\t${name}"` (`db.av:574`) + store | **yes**, witness-validated |
| 18 | Sig | `(name, text)` | `record.av:571,572` | `record.av:68,79`; `voices.av:631` | same map | **yes** |
| 19 | Warn | `(name, text)` | `derive.av:244` | `derive.av:225` | same | **yes** |
| 20 | Scan | `(name, text)` | `voices.av:690` | `voices.av:688` | same | **yes** |
| 21 | Canon | `(name, text)` | `C/commands/fmt.av:281,307` | `C/commands/fmt.av:267` | same | **yes** |
| 22 | Licenses | `(name, text)` | `derive.av:245` | `derive.av:231` | same | **yes** |
| 23 | Findings | `(name, text)` | `derive.av:246` | `derive.av:235` | same | **yes** |
| 24 | Answer | `(name, text)` | `answers.av:17` (called only from `tests/answers_test.av:39`) | `answers.av:23` | same | **yes**, unused in production |

Notes: dense unwrappers are hand-written, 16 of them (`db.av:376-534`), because `@derive(Unwrap)` "was attempted and abandoned" (`db.av:262-273`). `DbKind` itself is hand-kept in step with `DbRow` (`db.av:155-159`). The durable half has NO index beyond the string map (no by-package, by-file or by-kind listing; nothing can enumerate rows of a kind, on disk or in memory). `Db.rows` never evicts.

---

## E. Hand-rolled caches / memos / maps outside the kernel

"Invalidation" = what clears or re-keys it inside ONE process. None of these is a kernel cell, so none is a recorded dependency of any query that reads it.

### E.1 `Workspace.keys: Keys` (`A/compiler/workspace.av:125-150`) — "PER-BUILD KEY MEMOIZATION"

| Field | Remembers | Key | Invalidation | Filled at |
|---|---|---|---|---|
| `text_digests` | a file's `len.digest` | path | **never** in-process | `build.av:646-652` |
| `bytes_keys` | a module's interface digest | module name | cleared when a record's SEEN part moved (`record.av:583-587`) | `record.av:293-299` |
| `view_parts` | the modules a module sees + their keys | module | same | `record.av:1128-1135` |
| `typed_files` | per module: file → files its types name | module | same (`:588-589`) | `record.av:1216-1232` |
| `file_owners` | file → module whose record places it | path | same (`:590`) | `record.av:1192-1198` |
| `placed_from` | "this record's file lines were filed" | module | same (`:591-592`) | `record.av:1193-1194` |
| `object_keys` | a file's object key | `module\tpath` | cleared on EVERY `keep_interfaces` (`record.av:579-580`) | `record.av:304-311` |
| `object_parts` | a file's `KeyParts` | `module\tpath` | same (`:581-582`) | `record.av:1116-1123` |
| `compiler_id` | this compiler's print | — | reset by `built_for` when the mode changes (`build.av:454-457`); else "never cleared" | `build.av:166-169` |
| `store_root` | store directory | — | same | `build.av:199-206` |
| (`keeping`, `build_mode`) | config, not caches | | | |

### E.2 `Workspace.records: Records` (`workspace.av:251-283`) — "ONE read per record per build"

12 maps, all keyed by record key / module / path, **never cleared** (overwritten by `record_known`, `record.av:258-266`): `loaded_records`, `record_texts`, `record_lines`, `record_fields`, `record_places`, `record_fault`, `grammar_scanned` (path → lexes a block; `voices.av:677-693`), `component_scanned` (`voices.av:698-705`), `component_names` (`:710-719`), `met_files`, `block_named`, `block_rows` (`voices.av:627-636`).
The three path-keyed scan memos cache a verdict about a FILE'S TEXT read outside the kernel.

### E.3 `Workspace.hold: Hold` (`workspace.av:179-202`) — 20 fields of per-build hold state

Memo-like: `file_ready: Table<bool>` (`workspace.av:844-845`), `row_filled: Table<bool>` (`interface.av:308-309`), `minted: Map<string,bool>`, `file_module: Table<int>` (`workspace.av:1718-1722` "a file's module never moves"), `sig_asked: Table<int>` (revision a module's `HeldSig` was last asked at, `:1709-1713`), `named_in` (name → modules with an impl/trait of it, `record.av:705-714`), `runs` (file → files its compile-time runs read, `workspace_analysis.av` `read_by`), `moved`, `reexports`, `held_flat`. The rest are worklists (`forced`, `held_wants`, `body_asks`, `settling`, `hold_asked`, `read_with`, `read_seeds`, `read_files`, `holds_settled`, `settle_frames`). No invalidation; a restart builds a fresh `Workspace` (`anew`, `workspace.av:675-688`).

### E.4 Other `Workspace` fields (`workspace.av:328-407`)

| Field (line) | Remembers | Key | Invalidation |
|---|---|---|---|
| `externs: Table<ExternNames>` (345) | the program's extern symbols | slot 0 | re-made when `decl_count()` differs (`workspace_analysis.av:343-350`) |
| `sig_voices: Table<Voices>` (346) | a sig's diagnostics | DeclId | none |
| `method_clashes` (347) | a type's method clashes | DeclId | rewritten per `methods` compute (`workspace.av:1789`) |
| `method_diags` (348) | clashes grouped by file | — | "A new revision or declaration invalidates the grouping" (`:111-113`) |
| `method_diag_rows` (350) | `Family.MethodDiags`'s value | FileId | by the kernel ask (`workspace_analysis.av:99-103`) |
| `asks` + `asks_index` (351-354) | `Wanted` interning → `Lowered`/`LiftLowered` key | `w.name` | none; append-only |
| `lift_asks` + index (355-357) | → `Lifted` key | `"lift$file$call$decl"` | entry overwritten on re-ask (`workspace_analysis.av:700-702`) |
| `settle_asks` + index (358-360) | → `Settled`/`ConstTyped` key | settle symbol | none |
| `module_names_of` (367) | path → module | `"${packages().length}\t${path}"` | re-keyed by the package table's SIZE (`modules.av:34-42`) |
| `files_of` (370) | module → files (a host LISTING) | `"${packages().length}\t${module}"` | same (`modules.av:64-74,84`) |
| `file_ids_of` (372) | module → FileIds | same | same |
| `admission_asked: Table<int>` (375) | revision `Admitted(f)` was last asked | FileId | per revision |
| `reexporting` (377) | re-export lookups in flight | module+name | — |
| `import_lists` (378) | a module's imports | module | cleared when seen moved (`record.av:593-594`) |
| `package_rows`, `package_voices` (385-386) | admitted packages | — | append-only |
| `store: Cell<Store?>` (342) | the attached store | — | — |
| `failures_db`, `raised_fixpoint`, `read_fixpoint` (400-406) | relation Db + two fixpoint value tables | DeclId | replaced whole per pass |

Plus the closure-captured maps in `revision_of_hash` (`workspace.av:597-610`): `hashes`/`moved_at: Cell<Map<string, int>>` per std-relation family — a hand-built hash→revision translation layer, string-keyed by `"${cell}"`.

### E.5 `Decls` (`A/features/decls.av:393-611`) — the declaration table

Memo/answer tables (each dense by DeclId/FileId unless noted, no invalidation except where stated): `sigs` (439; `Family.Sig`'s value), `seat_types` (445), `bound_types` (447), `faces` (431), `doc_facts` + `doc_facts_side` (435-439), `held: Map<path,bool>` (421), `held_items` (422), `wire_index` (427; "kept until the file holds more declarations than it was indexed with"), `held_values` / `held_reaches` (442-446; settlements restored from records, keyed by string), `meta_ids` (529; "`@std/meta`'s declarations by name, found once each"), `marks` (532; `Family.Marks`'s value, "null = unasked"), `const_types: Map<"file/stmt", TypeId>` (537), `children`/`methods`/`impls` (543-547; `Family.Methods`'s value), `targets` (575), `seat_marks`/`declared_writes`/`written_seats` (580-584; `Family.Receivers`' value), `consumed` (590; "computed on first ask … null = unasked" — a memo with NO kernel family at all), `refs_db` (599; `Family.References`' value), `refs_incomplete` (603), `mut_seat_index` (608), `inferred_errs`/`inferred_unresolved` (613-616), `scoped` (410), `name_buckets`/`cell_names`/`rows_state`/`move_stamps` (513-520), `provenance`/`generations`/`origins`/`expansion_voices` (523-527), `decl_cells`/`file_rows`/`module_rows`/`decl_row_rows` (pinned relation storage, 487-501). ≈ 27 distinct answer tables.
Hooks, not caches (17): `ensure*`, `lifter`, `namespace_of`, `apart_of`, `composers_of`, `embed_judge`, `audit_hook`, `held_rows`.

### E.6 Process-wide and miscellaneous

| file:line | Remembers | Key | Invalidation |
|---|---|---|---|
| `A/compiler/mod.av:291` `export once fn avra() -> Language` | the assembled grammar + features | process | never |
| `A/compiler/rules_table.av:113` `once fn rule_index()` | the rule table's index | process | never |
| `A/core/runtime_api.av:10,1978` `once fn rt_sigs()`, `rt_index()` | runtime registry | process | never |
| `A/features/contexts.av:438` `once fn scalar_types()` | builtin type rows | process | never |
| `A/query/memo.av:12` `once fn qtrace_flag()` | `AVRA_QTRACE` | process | never |
| `A/compiler/build.av:237` `once fn process_serial()` | a counter | process | — |
| `A/compiler/dep_audit.av:27-34` 4 `once fn` cells | audit slots/counts/rows/samples | process | — |
| `A/compiler/db.av:553` `Db.rows: Cell<Map<string, DbRow>>` | durable rows read or written this process | `"${kind.tag()}\t${name}"` | never; an in-process hit skips `still_valid` |
| `A/core/types.av:193` `TypeRegistry.ids`, `named` | type interner | type's key string | never |
| `A/core/arena.av:14` `kinds`, `A/core/store.av:137,142` `quotes_at`, `body_starts` | per-arena indexes | string | per parse |
| `A/query/kernel.av:113` `Audit.reach: Cell<Map<string, bool>>` | reachability answers | `"f:a>f:a"` | reset each judging (`:234-235`) |
| `A/compiler/backend/interp.av:1533-1549` `remembered(callee, found)` | FFI symbol lookups | callee name | per evaluator |
| `R/db.av:475` `Memo<V>.kept` — reached through a generated **`once fn <query>_answers()`** (`R/query.av:58`) | every `@query`'s answers, PROCESS-GLOBAL | `"${db.id}:${cell}"` | `db.verdict` (owner's opinion) else the Db's write COUNT (`R/db.av:511-520`) |
| `R/db.av:593` `InputSlot<V>` — `once fn <input>_input()` (`R/input.av:31`) | every `@input`'s values + hashes, process-global | `"${db.id}:${cell}"` | only an explicit `set_<name>`; "`load` runs once, on the first ask" (`R/db.av:623-629`) |
| `R/db.av:114,124` `once fn quiet_families()`, `minted()` | family / Db id counters | process | — |
| `C/commands/fmt.av` `fold_groups(…, shared_id)` + `seed_compiler_id` (`build.av:179-181`) | one compiler print across many workspaces | caller's knowledge | — |
| `C/commands/dev.av:316` `mut at: Map<string, Mark>` | watch stamps | path | loop |

Not found (searched, none): a hand cache in the grammar engine, in `A/compiler/typing/`, in `program.av`, in `expand.av`, in the suite runner beyond `Unit/proved`, in std-root lookup (recomputed per `disk_host()` call, `C/commands/shared.av:73,144`), in manifest loading beyond `Family.Manifest` (but `build.av:629` re-reads manifests outside it).

**Total ≈ 95** remembered-answer fields/sites: Keys 10 + Records 12 + Hold 10 + Workspace 17 + Decls 27 + process-wide/misc 19 (MEASURED by reading the type definitions; the split between "cache" and "state" is a judgement).

---

## F. `@relation` / `@query` / `@input` (packages/std-relation, 3228 lines) and their use by the compiler

### F.1 What the annotations generate

| Annotation | Defined | Generates (quoted) |
|---|---|---|
| `@relation` on a record | `R/relation.av:106` `export fn relation(t: Type) -> Declared { Declared { made: RelationRow.derive(t), problems: relation_problems(t) } }` | `R/relation.av:510-527`: a `once fn <t>_stores() -> Stores<T>` (`:614`), a `<T>Key` record, a `<T>Stored` record, and `impl T { static fn relation_name() -> string …; static fn shape_hash() -> int …; fn stable_hash() -> int { ${hash_chain(t)}.finish() }; ${members(t)} }` where members are `rows_in(db)` (`:619`), `get(db, id)` (`:625`), `prior(db)` (`:631`), `all(db)` (`:638`), `insert(db, ..seats) -> T` or `-> Result<T, InsertRefused>` when `@unique` (`:688,700`), `key()`/`key_text`/`by_key` for `@key` (`:759-762`), one `by_<field>(db, v)` per `@index`/`@unique` (`:844-869`), `encoded() -> Bytes` (`:939`), `static fn decoded(b: Bytes) -> Result<TStored, CodecFault>` (`:964`) |
| field marks | `R/relation.av:1-25` | `id` (store-minted, int or `@dense`), `@key`, `@unique`, `@index` (list field → filed under every element; nullable → only when present), `@local` ("out of the stable hash and the codec") |
| `@arena` beside `@relation` | `R/relation.av:114,537-539` | nothing: `quote { impl ${t} { } }` — "a checked mark" |
| `@side` beside `@relation` | `R/relation.av:119,542-…` | `static fn get(store: SideTable<T>, id: int) -> T?`, `all(store)`, `fn stable_hash()`, `static fn get_db(db: Db, store: Cell<SideTable<T>>, side: SideRows<T>, id: int) -> T?` ("the slot's read is recorded against `side`'s family") |
| `@query` on `fn q(db: Db, …) -> A` | `R/query.av:48-66` | `once fn q_answers() -> Memo<A> { memo() }` + a wrapper under the written name (`:119-128`): `fn q(..seats) -> A { let m = q_answers(); let held? = m.kept(db, <args hash>) else { return m.ran(db, <args hash>, () -> <wrapped>(..args)) }; held.value }`; when the answer decodes, the `lasting`/`ran_lasting` form with `durable_name(f)` = `"name(seat types) -> answer"` (`:105-117,133`) |
| `@input` on `fn i(db: Db, …) -> V` | `R/input.av:22-40` | `once fn i_input() -> InputSlot<V> { input_slot() }`, the accessor `fn i(..) -> V { let m = i_input(); let cell = m.cell(db, <args hash>); m.read(db, cell, () -> <wrapped>(..args), <answer hash>) }` (`:57-66`), and `fn set_i(.., value: V) -> void { … m.write(db, cell, value, <answer hash>) }` (`:70-81`) |

Runtime model (`R/db.av`, `R/rows.av`): a `Db` is `{ id, closed, hashes, closers, sweepers, hooks: Cell<Hooks>, durable: Durable, quiet, registrars, writes, cells: Map<string,int>, runs, running: List<Frame>, owner_frames, … }` (`R/db.av:27-44`). `Hooks` (`:63-73`) is 9 int-only fns (`family, record, revision, reader, refused, opened, settled, running, moved`) by which an OWNER (the compiler's Kernel) observes it. Rows live in `Rows<R>` (`R/rows.av:124`) with `Index` = `{ texts: Map<string,int>, slots, opened, ordered }` and per-bucket `{ members, hash, read: ReadMark }` (`:78-83,122`). Read tracking is per BUCKET (cell `b + 1`) or whole relation (cell 0) (`R/db.av:52-56`). A `@query` runs in a `Frame` whose rows are stamped with its run and swept on rerun; "A query never reads a relation it writes, and two queries never own one key" (`R/db.av:7-13`). Reuse without an owner's opinion = the Db's global write count unchanged (`R/db.av:516-519`: `rest -> if held.writes == db.writes.get() { held } else { null }`) — ANY write to the Db invalidates every kept `@query` answer when the owner answers `-1`. `Durable { answer: fn(string, int) -> Bytes?, keep: fn(string, int, Bytes) -> void }` (`:98`) is the across-process door; "only from a run that wrote no rows" (`:550-553`).

### F.2 Does std-avrac's kernel/Db use them?

| Use | Where | Wiring |
|---|---|---|
| `@relation Decl` (20 columns, 6 indexes) | `A/features/decl_rows.av:39-76` | THE declaration table; rows under `Decls.decl_rows: Cell<Db>` created with `new_db()` (`A/features/decls.av:767`) and **armed onto the workspace Kernel** by `arm_recording` → `armed(kernel_hooks(self.record_kernel, self.move_stamps))` (`:1088`). `Decls.decl` reads the row raw and records the NAME BUCKET itself (`row_read`, `:1005-1015`) |
| `@relation File`, `Module` | `A/features/file_rows.av:13-25` | same Db; minted at `File.insert(…)` `A/features/decls_mint.av:45`, `Module.insert` `:73`; a file's admission is a named owner run (`owner_named("file ${id.index}")` `:48`, `opened_run`/`closed_run` `:144,289`) |
| `@relation @side DeclAt`, `DocFact` | `decl_rows.av:86-88`, `doc_fact_rows.av:14-16` | per-file `SideTable` partitions |
| `@relation @arena` ×2 | `A/core/nodes.av:332-333,876-877` | marks only |
| `@relation Ref` | `A/features/decls.av:383-384` | `refs_db`, a fresh quiet Db per `references()` pass (`let fresh = new_refs_db()` `A/compiler/references.av:94`; rows filed `:160`) — NOT kernel-hooked; the pass is one raw `Family.References` cell |
| `@relation AssignRoot` | `A/features/code.av:1061` | a fresh `new_db()` per file view (`:1078`) |
| `@relation ErrorSite`, `Raised` | `A/compiler/failures.av:102,118` | `failures_db: hooked_db(relation_hooks(kernel))` (`workspace.av:752`) — kernel-hooked through `revision_of_hash` |
| `@relation Finding` | `A/compiler/findings.av:12-13` | a fresh quiet Db per call (`:19,34`) |
| `@query named_decls`, `exported_decls` | `A/compiler/doc_rows.av:13-23` | called from `A/compiler/program.av:407,444` over `decls.decl_rows.get()`; answers kept in the process-global `once fn` Memo; `Durable` is `transient()` (the Db was made by `new_db()`), so nothing outlives the process |
| `@input file_text` | `A/compiler/inputs.av:21-22` | one caller, `findings.av:46`, over a throwaway Db |
| `@input env_value` | `A/compiler/inputs.av:30-31` | **no caller** |
| `durable_db` / `Db.answers(store, parts)` | `A/compiler/answers.av:12-19` | **tests only** (`A/compiler/tests/answers_test.av:39`) |

So: the DECLARATION TABLE and the failures pass are real std-relation relations under the compiler's Kernel; the 32 `Family` queries are NOT `@query` (the family marker file says so: "It is NOT @std.relation's user-facing `@query fn q(db, …)` … the families answer dense structural values … carry no `Db` seat, and several are inputs or whole-program fixpoints, so they cannot wear that form", `A/compiler/families/family_derive.av:9-14`); the compiler's durable `Db` (`A/compiler/db.av`) does not use `@relation` at all — `inputs.av:8-15` records the trigger: "folding the two into one door needs `@relation`/`@query` wired to THAT `Db`, which §7.5 schedules at M3 … not yet built".
Two different types are both called `Db`: `compiler.db.Db` (kernel + durable string rows) and `@std.relation.db.Db` (imported as `RelDb`).

### F.3 std-db, std-sql

**packages/std-db** (518 lines: `db.av` 385, `error.av` 133). `@model` on a record type generates the SQLite table DDL and typed CRUD from the fields: "`@model` reads a declaration's fields (their names, their shapes, their marks) and answers the table DDL and the typed CRUD that agree with it" (`packages/std-db/src/db.av:1-7`); first field must be `id: int = 0`; `@unique` is the one mark; it depends on `@std.sqlite.{Db, SqlValue, sql, prepared}` (`:40`) — a runtime ORM over SQLite, unrelated to the compiler's cache. Its manifest calls `@std/relation` the row vocabulary "shared by the compiler's Db and @std/db" (`packages/std-relation/avra.toml`), but nothing under `packages/std-db` or `packages/std-sql` mentions `std.relation`/`std/relation` (MEASURED: grep, zero hits).

**packages/std-sql** (1217 lines: `lexicon.av` 40, `parser.av` 950, `resolve.av` 227). "Real SQL, parsed and checked against declared @model shapes at compile time" (`avra.toml`): a `grammar { … }` lexicon (`lexicon.av:27-40`), a parser, and a resolver that checks column/table names against `@model` shapes. No connection to the kernel, Store or `@std/relation` (grep: none).

---

## G. Keepers and tests that guard the cache

| Name | What it checks | Where | In `make gate`? | In CI (`checks.yml` keepers)? |
|---|---|---|---|---|
| `cache-attacks` | "two programs and a library through ONE store, every edit kind a hold must survive, each binary held to the evaluator"; refuses a run where "no step ran under a hold" | `tools/cache_attacks.sh` (47 `steps=` increments, MEASURED); Makefile `:506-508` | yes (last: "It CLEARS the store") | **no** (keeper list `.github/workflows/checks.yml:110` = `fingerprints vocab families cited externs dogfooding-rules ui-host ui-host-test ui-board`) |
| `link_cache_attack` | a kept binary vs. the runtime archive, package objects and codegen mode it linked: "a changed archive or mode must relink, and an unchanged set must still be a cache hit" | `tools/link_cache_attack.sh` (4 steps); run by `cache-attacks` | yes | no |
| `wasm-cache` | one program built for host and wasm32 through one tree's stores; "a module is its own target's code and … what a build keeps is what it published" | `tools/wasm-cache-attacks.sh`; Makefile `:278-279` | not in the `gate:` line (`:850`) | no |
| `type_named_cache_attack` | `type_named`'s dependency across separate processes over one `.avra-cache` | `tools/type_named_cache_attack.sh` (4 steps) | not wired to any Makefile target (grep: none) | no |
| `hold_sweep` | touches EVERY source one at a time, builds through the hold, files the outcome | `tools/hold_sweep.sh` | manual | no |
| `witness_callee_edit` | "A CALLER'S OBJECT FOLLOWS ITS CALLEE'S BODY" across a warm store | `tools/witness_callee_edit.sh` | "A standalone witness, never a gate step" | no |
| `witness_held_instance` | a held file's declared instances read by a module that moved | `tools/witness_held_instance.sh` | manual | no |
| `witness_settled_wire` | a held const's value round-trips the wire (`check --baseline` twice over one cache) | `tools/witness_settled_wire.sh` | manual | no |
| `witness_parallel_build` | two suites / the same suite concurrently over one `.avra-cache`; the published binary never seen unfinished | `tools/witness_parallel_build.sh` | manual | no |
| `codecs` | every registered encoder/decoder pair: `decode(encode(x))` compared FIELD BY FIELD (18 rows); `tools/codecs.py` refuses an encoder/decoder-shaped fn pair the registry does not name | `A/compiler/codecs.av:514-655`, `A/compiler/tests/codecs_test.av`, `tools/codecs.py`; Makefile `:716-718` | yes | no |
| `families` | `Family` ordinals are append-only vs `tools/families.order` ("rows, kept caches and witnesses key by it") | `tools/families.py`; Makefile `:634-635` | yes | **yes** |
| `fingerprints` | fingerprint tags unique per fold space; every variable-length run folds through `fp_list` | `tools/fingerprints.py`; Makefile `:708-709` | yes | **yes** |
| `avra check --verify-held` | after a warm run, diffs every HELD declaration (identity, sig, const type/value, target, seats, flatness, facts, refs) against a fresh parse+sign; "a check that examined nothing says so" | `A/compiler/verify_held.av:30-48`; `C/commands/shared.av:532-549`; used inside `cache_attacks.sh` (`:379-382`) | via cache-attacks | no |
| `avra cache [why\|dependents\|changed\|held]` | inspection (keeps nothing, `Keeping.Aside`) | `C/commands/cache.av`, `A/compiler/cache_walk.av` | — | — |
| dependency audit | every Decls table read that skipped `ask` and that no open query covers → `tools/dep_audit.tsv` ("the file only shrinks") | `A/query/kernel.av:96-236`, `A/compiler/dep_audit.av`, `A/features/bypass.av`, `tools/dep_audit.sh` | manual; needs a compiler built with `audit_build` | no |
| `seed-check` | the committed seed compiles HEAD | Makefile `:551` | yes | bootstrap path |
| `gate_receipt` | the gate's receipt names the tree hash it proved | `tools/gate_receipt.sh` | yes (self-test) | — |
| `witness` | Avra == C on the same object (extern width seam; not the cache) | Makefile `:827-835` | yes | no |
| `witnesses` | `docs/DIAGNOSTICS.md` is what the compiler says (diagnostic goldens; not the cache) | Makefile `:760-764`; `A/compiler/dev/witnesses.av` | yes | no |

Spec suites (run by `avra test packages/std-avrac`; CI runs affected-package suites, `checks.yml:163`):

| Test file (`A/compiler/tests/` unless noted) | Guards |
|---|---|
| `store_test.av`, `store_sweep_liveness_test.av` | Store verbs; the roll's sweep vs live `.users` pids |
| `db_test.av`, `docs_adversarial_test.av`, `doc_test.av` | durable rows, `Decl` witnesses |
| `compiler_print_test.av`, `compiler_print_adversarial_test.av` | the print: "two DIFFERENT binary contents at the SAME path still disagree" (`build.av:286-290`) |
| `source_stamp_adversarial_test.av` | the removed stamp shortcut for `text_digest` |
| `held_sig_test.av`, `interface_digest_test.av`, `hold_refusal_test.av` | `HeldSig` deps, interface digests, the refusal voice |
| `kernel_relation_hooks_test.av`, `file_module_relation_test.av`, `relation_scope_rules_test.av`, `late_mint_settles_test.av` | std-relation under the Kernel |
| `syntax_family_test.av`, `names_family_test.av`, `facts_family_test.av`, `family_reflect_test.av` | declaration-grain families |
| `cache_walk_test.av`, `audit_switch_test.av`, `answers_test.av`, `settle_test.av`, `codecs_test.av`, `workspace_adversarial_test.av`, `test_run_adversarial_test.av`, `build_error_adversarial_test.av` | as named |
| `A/query/tests/kernel_test.av` (20 KB), `fixpoint_test.av`, `audit_test.av`, `marks_test.av` | the kernel itself |
| `R/tests/` (30 entries incl. `durable/`, `input/`, `query/`, `relation_adversarial_test.av`, `stable_test.av`) | std-relation |

Gap summary (MEASURED from the wiring above): the only cache keepers CI runs on a train are `families` and `fingerprints` plus the affected spec suites; `cache-attacks`, `link_cache_attack`, `codecs` run only in a local `make gate`; `wasm-cache`, `type_named_cache_attack`, `hold_sweep` and the four `witness_*.sh` scripts run only by hand.
