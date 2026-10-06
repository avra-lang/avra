# Build-time sources — files, folders and specs as typed values (v2.1)

> 2026-10-05. Design only; no compiler code. Branch `sources-design`, base `bd36bf7`.
> v2 answered the first review; v2.1 answers the second (of `4c0ff43`). §13 holds both tables.
> **§1 is PENDING THE DB LEAD** on the points it marks. The author-side items are settled here.
> Labels: **PROBED** (I ran it; Appendix C), **READ** (I opened it, file:line), **READ(agent)** (a survey agent opened it), **ASSUMED**.
> Probes ran `avra-ui-assets-design/build/avra` (0b5bd64, one PR behind this base). Scratch: `/tmp/sources-probe/`.
> **Nothing under `@std/source` exists.** §14 lists every NEW name this design introduces. Code that uses one is design code.

## 0. Page one

The owner's sketch, as written:

```avra
use @std.source.{dir, file}
use @std.image.{resize, webp}
use @std.openapi.{openapi}

const photos = dir("./photos") |> resize(width: 320) |> webp(quality: 80)
const api    = file("./petstore.yaml") |> openapi

image(photos.hero)             // photos.heor is a compile error listing the members
api.pets.get(id: 3)?           // typed request, typed errors
icon(icons.close, color: .red)
```

**What it is made of — nothing new as a declaration kind:**

| | what | built on |
|---|---|---|
| a source is an input | `file("…")`, `dir("…")`, `url("…")` name bytes outside the program; each read is a compiler input with a content digest | `embed`, generalized and fixed |
| a transform is a fn | `x \|> f(a)` is `f(x, a)`. `resize` takes a file, a folder, a picture or a set of pictures | generic traits (landed) |
| heavy work runs native | bytes are read in a `@step`; a small one runs in the evaluator, a big one in its package's tool — a child process built once, handed only bytes | `avra build`; `@query`'s wrapper shape |
| a folder is a set | `photos.hero` is a member read, settled at compile time | `const` settlement |
| a spec declares | a `const` whose provider answers declarations beside it | Declares annotations |

**What makes line 5 run exactly as written:** one language rule that does not exist yet — a trait says its result type is decided by the implementing type (§4.5, C8, Q3). Today it needs one more stage, `dir("./photos") |> pictures |> resize(…)`, and that form is PROBED to run (C.14).

**The order (§11):** the two infrastructure doors first (§1), because every law and every cost below stands on them. `|>` is an independent track.

---

## 1. The infrastructure answer

The owner asked: is there ONE general, lovely DB mechanism for a consumer like this? **No. There are two half-doors and five persistence paths. This section says what the one input door and the one persisted-fact door are, what each replaces, and where that agrees with the DB campaign.**

### 1.1 What exists (opened first-hand)

**Inputs — seven ways to read the outside:**

| # | reader | where | tracked how |
|---|---|---|---|
| 1 | `Source` family: a `.av` file's text | `workspace.av:1123–1136`, via `host.read` | kernel input, `fp_str(text)` |
| 2 | `Manifest` family: `avra.toml` | `packages.av:48–71` (READ(agent)) | kernel input |
| 3 | `text_digest(path)` | `build.av:608` | read and hashed fresh, memoized per process; what `KeyParts` and kept lines compare |
| 4 | `digest_of_binary` — the compiler, linked objects | `build.av:296–304, 598` | fresh; names the store root |
| 5 | `current_listing_digest`, `current_file_digest` | `db.av:660–680` | hand witness of the durable `Decl` row |
| 6 | `@input fn file_text`, `env_value` (N7, landed) | `inputs.av:21–31`, reading `@std.io` directly | relation input; one caller, none |
| 7 | `embed` | `interp.av:845–859`: `avra_selfhost_read_file`, bypassing `Host` | pushed to `embeds`, then `touch(self.source(self.file_id(path)))` — a `FileId` minted in the SOURCE table (`workspace_analysis.av:576–581`) |

**Persisted facts — five paths:**

| # | path | key / witness | where |
|---|---|---|---|
| P1 | **the hold**: a file's record, object, warnings, asks | `KeyParts = { module, path, text, runs, seen }` — the file's text, "the digest of each text its compile-time runs read", each module it sees | `record.av:1092–1113` |
| P2 | **named rows** through `Db.insert` (`Decl`, `Sig`, `Warn`, `Scan`, `Canon`, `Licenses`, `Findings`, `Answer`) | validity "in the caller's key", except `Decl`'s hand listing + file witness | `db.av:590–662` |
| P3 | **`Db.answers`**: a `@query` answer under a file's `KeyParts` | built and tested; **no caller outside tests** (PROBED grep) | `answers.av:12–20` |
| P4 | **kept settlements**: a const's verdict + a `#lines` row of `u`/`c`/`m`/`f`/`b` lines, each with its own "stands" check | hand-written per-run witness; unseated consts only (`ask.seats.is_empty()`) | `kept_settle.av:38–41, 137–179` |
| P5 | **kept binary / check verdict / suite**: "path, length, digest of every input in the closure" | `build_inputs`: `.av` files, manifests, engine sources | `build.av:475`, `modules.av:275–289` |

18 direct `Store.keep*` call sites (PROBED grep: 6 `Unit`, 4 `Warn`, 2 `Obj`, 1 `Bin`, 1 `Rows`, 4 multi-line). `Db.insert` (`db.av:593`) is one of them and the funnel for P2. Keys share `node_key` (`store.av:78`). What differs per site is the wire and the validity rule.

**The two tables above are not complete, and v2 said they were.**
- Readers: the second review counts nearer **fifteen read shapes** (READ(agent)): existence and `is_dir` probes (module resolution `modules.av:102–106`, manifest presence `packages.av:81`, the `.git` root `build.av:412`, program-test markers `suite.av:143–158`); environment reads (`${NAME}` in a `[link]` row `whole.av:482`, `CC`, `WASM_OPT`, `AVRA_CWD`, `AVRA_SOUND_CHECK`); the manifest read in four places; four hand listing witnesses, not two (`current_listing_digest`, the `m` line, `SeenPart.files`, `build_inputs`).
- Kept rows that fit none of P1–P5 (READ(agent)): `interface.av:66, 85` (a second kept-const path), `build.av:719` (the links row), `derive.av:200` (the remembered closure), `derive.av:530` (`clean_key`), `suite.av:128` (`proved_key`).
- P4's witness is **transitive**, not direct: its `m`/`f` lines come from `import_closure`, "to a fixed point", one `f` line per file of every module in it (READ `kept_settle.av:144–149, 197–203`). Its `u`, `c` and `f` lines each stand by their own rule (a text digest, OR a declaration's syntax, OR a re-lowered shape; a const's verdict re-asked), not by one hash.

**Never persisted:** `Lifted` and `Expanded` — every annotation and derive (READ `expand.av:93–116`). A seated settlement.

**A correctness defect found on the way (PROBED, C.23):** `const TEXT: string = embed("x.txt")`, build, edit `x.txt`, build again → the binary still prints the old length. `avra run` prints the new one. It stays stale after an edit to the `.av` file too. Cause, READ: `build_inputs` lists no embedded file (P5), and a kept settlement has no line for one (P4). "A hold bug costs time, never a wrong answer" (COMPILER.md §2 law 6) does not hold for an embedded file today.

### 1.2 Where the DB campaign already decided to go

READ in `2026_09_26_COMPILER_DB_TOWNHALL.md`, `2026_09_21_COMPILER.md` and the tickets.

| decision | text | this design |
|---|---|---|
| townhall §4.3 | "A durable row's witness covers everything it read, plus the producing compiler's digest." | follows |
| §4.5 | "A witness is a list of (stable name, value hash). Never a dense id." | follows — it is the shape of door 2 |
| §4.7 | "A row and its witness settle in one step." | follows; P4 breaks it today (two `store.keep` calls, `kept_settle.av:150–151`) |
| §6.5a | "kernel grain cannot persist… The durable witness is the hold path's `KeyParts`… Kernel-grain deps stay in-process." Measured: 2.54 M keys, 51.6 M direct deps on one `check`. | follows: nothing here persists a kernel edge |
| avra-8sb5.57.6 | CLOSED 2026-10-01; M3's flattened witness was a library, never wired, then deleted | v1 cited it as the door. **Wrong.** Removed. |
| avra-8sb5.57.101.12 | OPEN, unowned: "write a cell's deps as (stable name, hash) into a durable row… validity is re-ask+compare" — for a COARSE thing (a module's view) | door 2 is a SIBLING of it, not the same ticket: that one wants a kernel cell's deps re-asked through the kernel for a kept module view; a kept run has no view member. Folding them would close .101.12 without unblocking .101.11. |
| N7 `@input` (avra-8sb5.57.15) | landed; its comment: "`Memo.input` reads the host ONCE per file per Workspace" | door 1 is `@input`, moved onto `Host` |
| avra-8sb5.57.4.7 | CLOSED: `File`/`Module`/`Decl` relations armed through the kernel; a late write is REFUSED (`moved: !late`, `workspace.av:580`) | door 1 keeps inputs OUT of the `File` relation — that late write is `embed`'s compiler trap (C.5) |
| COMPILER.md §2 | "A store is ONE compiler's." | follows for every row. Departs for raw bytes (§1.5). |
| `build.av:275–294, 600–608` | a stamp-keyed digest shortcut was tried twice and removed: "A stamp match is a claim about the bytes, never the bytes" (avra-8sb5.57.25, .57.19) | follows. **v1 proposed an mtime fast path. Removed.** |
| COMPILER.md §8 | "A resident compiler — no daemon; the owner's word." | follows (§8.4). v1's dev server contradicted it. Removed. |
| avra-8sb5.57.12 (N3) | `Family` as a `collect enum`; landed for the language, "apply to Family/DbKind" remains | cited, not re-ticketed |

### 1.3 Door 1 — ONE way an outside thing becomes an input

```avra
// compiler/inputs.av — the only readers of the outside, all through Host
export enum InputKind { Text, Bytes, Range, Listing, Exists, Env, Pin, Tool, Target }
/// What a read WAS: the kind, a stable name, and the digest of exactly what was read.
export type Part = { kind: InputKind, name: string, hash: string }

@input fn input_text(db: Db, at: Place) -> Text          // a .av file, avra.toml, a spec
@input fn input_bytes(db: Db, at: Place) -> Bytes
@input fn input_range(db: Db, at: Place, lo: int, hi: int) -> Bytes
@input fn input_listing(db: Db, at: Place) -> List<Entry>   // names and kinds, recursive, sorted; no content
@input fn input_exists(db: Db, at: Place) -> Entry           // Missing | File | Dir — a probe of a missing path IS a part
@input fn input_env(db: Db, name: string) -> string?         // the compiler's OWN reads only; never a program's
@input fn input_pin(db: Db, address: string) -> Bytes       // from the lock, never the network
@input fn input_tool(db: Db, name: string) -> string        // a binary's digest: the compiler, clang, wasm-opt
@input fn input_target(db: Db) -> Target
```

| rule | why |
|---|---|
| A name is STABLE: `package-name:relative/path`, a URL, a tool's manifest name. Never absolute, never a `FileId`. | §4.5; two machines agree |
| The hash is of exactly what was read. A header read is a `Range` part; the whole file is hashed only when the whole file is read. | a 10 GB video folder with 64-byte header reads hashes 64 bytes per file |
| A listing's hash covers entry NAMES and KINDS only. Content rides each file's own part. | add a file → the listing moves; edit a file → only its part moves |
| Read and hashed fresh in each process, memoized per process. No stamp shortcut. | the standing law (§1.2) |
| Every read goes through `Host` (`read_bytes` and a typed `list` are NEW on it; `host.av:8` has only `read: fn(string) -> string`). | a memory host can serve a test; no second door |
| Inputs are cells of their own, created on first read. They are NOT rows of the `File` relation. | a row minted late in `File` is refused (C.5). **Which mechanism this is — PENDING THE DB LEAD (D2).** `kernel.av:320–325` is `Memo.input`'s path, addressed by a dense int; `@input` as landed (`std-relation/src/db.av:625–648`, READ(agent)) records no read and marks its reader a writer. v2 wrote as if they were one thing. They are not. |
| `Exists` and `Env` are kinds. | The existence probes and the env reads listed in §1.1 are inputs today and tracked by nothing. `Env` covers what changes a kept row (`${NAME}` in `[link]`, `CC`, `WASM_OPT`, `AVRA_SOUND_CHECK`). It stays OUT for what changes no kept row (`AVRA_QTRACE`, `AVRA_DEP_AUDIT`, `AVRA_LIGHT`) and for `AVRA_CWD`/`PWD`, which decide where the command stands, not what a file means. A compile-time RUN still has no env row (L2). |

**Every compile-time run reports the parts it read** (today: `Settled.embeds`, a list of paths). The parts then go to exactly three places:
1. in process: a kernel dep on each (as `touch` does today for an embed);
2. the reading file's `KeyParts.runs`, which becomes `List<Part>` instead of text digests;
3. the run's own kept witness (door 2).

And the kept binary's key (P5) must fold every part a kept record names — closing C.23. **How — PENDING THE DB LEAD (D4):** `kept_binary` runs before anything is parsed (`build.av:475`), so the parts must be REMEMBERED from the last derivation, the shape the closure row has (`derive.av:200`). One sentence in v2 hid that.

**What door 1 replaces:**

| today | becomes |
|---|---|
| reader 7: `embed`'s `avra_selfhost_read_file`, `admit_embeds`' callee matched by the STRING `"embed"` (READ `whole.av:382`; a user fn named `embed` matches it — C.35), the `FileId` mint, the two path bases | `input_text`; `embed(p)` is `file(p).text()` |
| reader 2: the `Manifest` loader | `input_text(avra.toml)` |
| reader 5 + kept settlements' `m` lines: two hand-hashed listings | `input_listing` |
| reader 3: `text_digest` | `input_text(…).hash` — one memo |
| reader 4, and the keys avra-8sb5.68/.69 say are missing (wasm-opt, the linker) | `input_tool` |
| reader 6: `file_text` over `@std.io` | the same `@input`, over `Host` |
| reader 1 | stays the `.av` reader; its loader calls `input_text` |

About fifteen read shapes → one door with nine kinds.

### 1.4 Door 2 — ONE way a derived fact is kept

**A kept run.** It is P4, made general.

```avra
// compiler/kept.av — P4's verbs, one witness shape
/// A run's stable name: what kind of run, where it is declared, what it was asked.
export type RunName = { kind: RunKind, home: string, name: string, asked: string }
export enum RunKind { Const, Seated, Lift, Model, Action, Answer, Verdict }

impl Workspace {
    /// The kept value, when every part of its witness still stands.
    fn kept(run: RunName) -> Kept?
    /// Value and witness in ONE commit — the store's `read` slot IS the witness.
    fn keep(run: RunName, value: string, witness: List<Part>)
}
```

| question | answer |
|---|---|
| keyed by | the run's stable name — declaring path, declaration name, the arguments' fingerprint. Never `const$<FileId>$<StmtId>`. |
| witness | **the atom is PENDING THE DB LEAD (D8).** `Part = { kind, name, hash }` holds an INPUT. It does not hold P4's `u`, `c` and `f` lines as they are: each stands by a tiered rule, and collapsing one to a hash loses "a body edit elsewhere in the file still stands". The honest atom is either an input part or a derived-fact line with its own stands rule. |
| kept across runs | `Store.keep(family, key, bytes, read)` has an edges slot. Five non-test callers pass real edges (READ `build.av:717–726`: `[key]` three times; `interface.av:64–72`: `[obj_key_of(…)]` twice); the rest pass `[]`. **Not ready to be the witness — PENDING THE DB LEAD (D9):** no verb reads edges back; `Keeping.Aside` drops them (`store.av:129–132`); two processes can leave one's data beside the other's edges. And townhall §6.6 wants one packed file per package, never a file per row — unbuilt; ask. |
| cut off | a re-run that answers the same verdict fingerprint leaves its readers' `c` lines standing (exists: `verdict_fp`, `kept_settle.av:319`) |
| invalidated | re-ask each part's current hash; a missing part is a mismatch (§6.5a's rule) |
| inspected | `avra cache why <run>` prints the part that moved — `PartMoved { part, was, now }` exists for file keys (`record.av:1366–1373`) |
| the compiler's digest | the row lives in this compiler's store (`.avra-cache/<print>/`), so it is in every witness by position |

**Why §6.5a's measurement should not apply — UNMEASURED.** That measured kernel grain: 2.54 M keys. A kept run is one row per compile-time RUN, the grain `kept_settle.av` already persists. But P4's witness is transitive (§1.1), so "tens of parts" was wrong; lines per kept run on `check packages/cli` must be measured before this argument is made (D8).

**What door 2 replaces:**

| today | becomes |
|---|---|
| P4's `#lines` row and its five hand "stands" checks | the witness slot; one `stands` per `InputKind`/line kind |
| nothing (a seated settlement is never kept) | `RunKind.Seated` |
| nothing (`Lifted`/`Expanded` are memory only) | `RunKind.Lift` — a derive's answer survives the process AND an unrelated edit to its file |
| P3 `Db.answers`, unarmed | `RunKind.Answer` — but NOT before avra-8sb5.57.4.6's recorded deadline is paid: "a query DECLARED in an imported module whose body changes without its interface moving is read back stale… Close it by keying on the declaring file's parts too before any consumer arms Db.answers" (READ(agent)). PENDING (D10). |
| P2 `Decl`'s hand listing + file witness (`still_valid`) | a witness of `Listing` + `Text` parts |
| P5's input list | a `Verdict` run whose witness is the closure's parts — proposed; see question D4 |
| — | new consumers: a provider's model (`Model`), a native step's result (`Action`) |

**Count, corrected.** Today: P1–P5 and the five rows of §1.1 that fit none. After: P1 (its `runs` typed), the kept run — and those five rows still, until the DB lead says which fold in (D11). Fewer than today; not yet two.

Raw bytes are not a path of facts: §1.5.

### 1.5 Bytes

A made image is megabytes, and it is not a claim about the program. It is stored by the SHA-256 of its own content: `~/.avra/cache/bytes/<k2>/<sha256>`, written by staged rename (`staged_beside`/`published`, `build.av:251–259`). `AVRA_CACHE_DIR` moves it.

- A content name carries no compiler's belief, so sharing it across compilers and worktrees departs from "a store is one compiler's" only in letter. The row that says *which* bytes an action made stays in the compiler's store.
- A hit is verified by re-hashing on first use in a process.
- `avra cache gc` keeps what any kept action row or `assets.json` under the machine's known trees names; a size cap evicts oldest-read first.
- SHA-256 is NEW as a runtime row (only `avra_tls_hmac_sha256` exists — READ `std-tls/src/c/std_tls_mac.c:20`). The tree's own digest (`core/digest.av`) stays for keys; SHA-256 is for content, because a shipped name and an SRI value need it.

### 1.6 Hostile cases

| case | which key moves | what re-runs |
|---|---|---|
| add `new.svg` to `./icons` | `Listing(app:icons)`. `a.av` (holding `const icons`) carries it in `KeyParts.runs` → not held. Its kept run fails on that part → re-settled → new verdict. | `b.av` reading `icons.new`: its key follows `a`'s const exactly as it follows any cross-module const today (PROBED C.24: a body edit in `data.av` changes what `main` prints) |
| edit `close.svg` | `Range`/`Bytes(app:icons/close.svg)` | only runs that read it |
| insert a line ABOVE the anchor | the file's text → it is read, not held. Its `Lift` run must be found by a name with no offset in it, and its answer must hold no absolute span. **Neither is true as designed — PENDING THE DB LEAD (D5).** Today the name is `lift$<file>$<call>$<decl>`, three dense ids (`workspace_analysis.av:695`), and every `@std/meta` value carries `at: Loc?` byte offsets (`meta.av:137–212`). v2's receipt was "append a comment", the one edit that moves no offset. | the target: nothing runs. Today: 0.04 s → 0.25 s for 1,000 generated types on a comment (PROBED C.26) |
| edit the provider's source | the `u` line of the unit entered | that provider's runs |
| edit an embedded file | `Text(app:x.txt)` in `runs`, in the kept run, in the closure | the const, and the binary (today: neither — C.23) |
| swap `WASM_OPT` | `Tool(wasm-opt)` | the wasm link (today: nothing — avra-8sb5.68) |
| two processes at once | PENDING (D9): two processes can see different inputs, so "both wrote the same thing" is an assumption | — |
| a row with an old witness shape | the store root is the compiler's print (`build.av:199–206`), so a new wire reads no old row. (No per-row shape header exists; v2 said one did.) | re-run |
| delete `./icons` | `Listing` is missing → mismatch, never "nothing to check" | refusal at the literal |

### 1.7 PENDING THE DB LEAD

Nothing below is redesigned here. Each row is the exact question §1 waits on.

| # | waits on | the reviewer's reading | my default |
|---|---|---|---|
| D1 | Is the kept run its own ticket beside avra-8sb5.57.101.12? | a sibling | a sibling |
| D2 | **Which mechanism is door 1:** `@input` rebuilt over kernel cells with a stable-name → arg table, or `Memo.input` given `@input`'s face? | they are two things today | the DB lead's call |
| D3 | `KeyParts.runs: List<string>` → typed parts: one compiler generation? | yes — the store root is the compiler's print | one generation |
| D4 | The kept-binary fast path runs before analysis. Where are a build's input parts remembered so it can fold them (the C.23 fix)? | the closure row's shape | beside `derive.av:200`'s row |
| D5 | **A kept lift must be span-free:** a name without dense ids or offsets; spans stored relative to the declaration and re-based on load; the run's `Reach.Lookup` reads (`type_named`) in its witness. Is that the shape? | yes; unsafe as v2 wrote it | yes |
| D6 | Fresh hashing of large byte inputs each process. `digest_bytes` is an Avra loop (READ(agent) `core/digest.av:82–95`); 1 GB/s is ASSUMED. | measure; speed alone does not reopen the stamp shortcut | measure |
| D7 | Raw bytes in a content-named store outside the tree. | nothing forbids it; it must stay outside `.avra-cache`, which `rolled` sweeps (`build.av:388–392`) | also the owner's (Q11) |
| D8 | **The witness atom.** An input part, or a derived-fact line with its own stands rule? And: lines per kept run on `check packages/cli`. | `Part` cannot hold P4's lines | measure first |
| D9 | The store's `read` slot as the witness: a read verb; `Keeping.Aside`; two concurrent writers; per-row `.deps` vs §6.6's pack. | not ready | — |
| D10 | avra-8sb5.57.4.6 before `Db.answers` is armed. | a recorded deadline | pay it first |
| D11 | Which of the five rows outside P1–P5 fold into the kept run. | at least five stay | — |
| D12 | A per-process `input_tool` memo keyed by name is the shape `build.av:287` refused ("a path is the same kind of claim as a stamp"). Safe within one command? | state why or drop | drop the memo; hash per ask |
| D13 | Who owns the two doors. | the DB campaign | the DB campaign, this design its first consumer (Q12) |

---

## 2. What an author writes

```avra
use @std.source.{file, dir}
```

**1. A folder of icons.**
```avra
const icons = dir("./icons") |> vectors
icon(icons.close, color: .red)
```

**2. Photos.** A transform takes one thing or a folder of them.
```avra
const photos = dir("./photos") |> resize(width: 320) |> webp(quality: 80)
const hero   = file("./photos/hero.jpg") |> resize(width: 320) |> webp(quality: 80)
image(photos.hero, alt: "The harbour")
```

**3. A pipeline is a fn.** `each` runs any per-item fn.
```avra
fn thumb(p: Picture) -> Picture { p |> resize(width: 320) |> webp(quality: 80) |> home(.Bundle) }
const photos = dir("./photos") |> pictures |> each(thumb)      // `each` is the set's own
```

**4. Variants.** They live inside the picture; the target picks.
```avra
const photos = dir("./photos") |> widths([320, 640, 1280]) |> formats([.Avif, .Webp])
```

**5. An OpenAPI client.**
```avra
const api = file("./petstore.yaml") |> openapi
let pet = api.pets.get(id: 3)?          // Result<ApiPet, ApiPetsGetError>
fn show(p: ApiPet) -> string { p.name }
```
A large spec says what it wants — `openapi(only: ["pets", "store"])`. Expansion is whole and stops near 4,000 declarations today (§4.6).

**6. A manifest as typed config.**
```avra
const config = file("./app.toml") |> toml
listen(config.server.port)              // int; config.server.prot is a compile error
```

**7. SQL.** One anchor may read another.
```avra
const db      = dir("./migrations") |> schema
const queries = dir("./queries") |> sql(db)
```

**8. Catalogs, fonts, shaders, tables, schemas, pages.**
```avra
const messages = dir("./locales") |> catalogs(base: "en")
const inter    = file("./Inter.var.ttf") |> typeface
const blur     = file("./blur.wgsl") |> wgsl
const cities   = file("./cities.csv") |> csv
const events   = file("./events.schema.json") |> json_schema
const pages    = dir("./pages") |> markdown
```

**9. Environment — declared, never read at build.**
```avra
const env = file("./env.toml") |> environment      // names and types; no values
let e = env.load()?                                 // reads the process at RUN time
```
A compile-time run has no row that reads the environment (`Reach.World` is refused — PROBED C.3), so no build can bake a secret in.

**10. External bytes.** Three cases (§9.1).
```avra
const spec  = url("https://example.com/v3/openapi.json") |> openapi                 // fetched once, pinned, then local
const intro = url("https://cdn.acme.dev/intro.mp4") |> video |> home(.Origin)       // facts known at build; the program fetches
image(remote(https("img.acme.dev/u/42.jpg"), width: 96, height: 96), alt: user.name) // nothing known but what is written
```

### What the reader sees

```
error[type.unknown_member]: `icons` has no member `clsoe`
  ╭─[src/app.av:9:12]
9 │ icon(icons.clsoe, color: .red)
  ·            ──┬──
help: the members are `arrow_left`, `close`, `menu` — from ./icons (3 files)
```
```
error[@std/openapi:ref]: `#/components/schemas/Pett` is not declared
   ╭─[petstore.yaml:41:19]
41 │           $ref: '#/components/schemas/Pett'
   ├─ through `const api`, src/store.av:3
help: the schemas are `Error`, `Order`, `Pet`
```
```
$ avra docs photos.hero --target web
Picture 320×180 webp — app:photos/hero.jpg (2400×1350 jpeg, 412 KB)
  steps   @std.image.resized → @std.image.webp_made      tool @std/image (built 0.7 s, kept) · 14 ms · kept
  action  7c1e…                                           content b41d02aa… (17 KB)
  home    .Bundle — 17 KB is over the 4 KiB line (target rule: web)
  ships   build/web/assets/hero.b41d02aa.webp
```
`avra docs <name>` and `avra expand <file>` exist. `avra explain` does not (PROBED C.18), though CLAUDE.md documents it in three places. Every output above is a proposal for `avra docs`.

Go-to-definition on `ApiPet` lands on `petstore.yaml:52`: the provider gives each declaration the place it came from (`Directive.at` exists, `meta.av:467`).

---

## 3. `|>`

**The spec** (old tree `2026_04_18_FULL_SPEC.md` §28.7 — READ(agent)): "`x |> f` desugars to `f(x)`"; "`x |> f(y, z)` desugars to `f(x, y, z)`"; "Binds tighter than assignment, looser than arithmetic and comparison." Its examples start lines with `|>`; its own newline rule says continuation is a trailing operator.

**Today:** PROBED `expected BREAK` (C.1). Unlexable: `two_char_of` has no arm for it (READ `grammar/lexer.av:525–549`).

| question | decided | example |
|---|---|---|
| meaning | parse-time sugar into a `Call`, the left value first | `x \|> f(a, k: v)` is `f(x, a, k: v)` |
| a stage | a callee name, optional arguments, optional trailing block, optional `?` | `x \|> parse(strict: true)?` is `parse(x, strict: true)?` |
| not a stage | a method, a lambda, any other expression — refused, naming the fix | `x \|> .trim()` → "write `x.trim()`" |
| precedence | tighter than comparison and `??`, looser than arithmetic and bitwise — between `coalescing` and `bitwise` on the ladder (`expr_spine/mod.av:54–60`). This DEPARTS from the spec's "looser than comparison", on purpose: a stage is a call, so the looser reading makes the rows below errors. | `a + b \|> f` is `f(a + b)` |
| | | `x \|> f ?? d` is `f(x) ?? d` |
| | | `xs \|> count > 3` is `count(xs) > 3` |
| | | `a ?? b \|> f` is `a ?? f(b)` — parenthesize the left to pipe both |
| `x \|> f + 1` | refused: "a stage is a call — write `(x \|> f) + 1`" | |
| associativity | left | `x \|> f \|> g` is `g(f(x))` |
| in a head (`if`, `while`, `match`) | a stage with a trailing block is parenthesized, as every call there is | CLAUDE.md "A TRAILING BLOCK IN A HEAD" |
| in a table cell | not parsed (cells parse at `additive`, and `\|` separates columns). The table's refusal says: "bind the pipeline above the table". | |
| lines | **a line may END in `\|>`.** No leading form. CLAUDE.md's law stands unchanged: "A CONTINUING OPERATOR TRAILS, IT NEVER LEADS". `\|>` joins `continuing_op` (`lexer.av:720`). | |
| `_` placeholder | not now | |
| `it` | unchanged — and `it` does NOT bind at a free fn's seat today (PROBED C.13: `each(s, it * 2)` → "`it` rides a METHOD call's arguments"). `xs \|> filter(it.valid)` therefore does not work until that lands. The channels design writes that form (`2026_10_05_CHANNELS.md:183`). | |
| the formatter | a parse-owned mark on the `Call`, as `trailing` is (`core/store.av:271`). Like `trailing`, it restamps the node's fingerprint: the parsed value holds the mark, so its hash must (CLAUDE.md "AN EARLY-CUTOFF HASH MUST COVER THE WHOLE VALUE"). So `x \|> f` and `f(x)` type alike and fingerprint apart. | |
| munching | safe. No valid program has `\|` directly before `>` (PROBED C.19). The `>>` law is about a closer; `\|>` closes nothing. | |
| the channel send | settled: "`\|>` is plain application… a send is `orders.send(order)`" (READ `avra-channels-design` 3390b90, `CHANNELS.md:395`) | |

```avra
const photos = dir("./photos") |>
    resize(width: 320) |>
    webp(quality: 80)
```

---

## 4. Semantics

### 4.1 Sources and capabilities

```avra
export fn file(path: string) -> File      // a LITERAL
export fn dir(path: string) -> Files      // a LITERAL; recursive
export fn url(address: string) -> File    // a LITERAL; pinned in avra.lock

export type File  = { package: string, rel: string, name: string, size: int }
export type Files = { package: string, rel: string, names: List<string>, items: List<File> }
```

**A handle is a NAME, not a key to a lock.** PROBED C.25: any package can forge another package's exported record, with `with` or by reusing a private-typed field. Avra has no opaque type (ROADMAP.md:1796: "`opaque type Db` is F0100"). So authority cannot ride the value. It rides the DECLARATION:

> A compile-time run may read exactly what the source literals **in the declaration it is settling** name — and what the consts it reads were granted. Every read is checked by the compiler against that grant set.

| case | decided |
|---|---|
| a forged `File { package: "app", rel: "secrets/key" }` inside a library fn | refused at the read: no literal in the settling declaration covers it |
| `file("/etc/hosts")`, `file("../../x")` | refused at the literal: a path is relative, normalized, inside the package of the file that spells it (today `embed("/etc/hosts")` answers 256 — C.2) |
| a path literal inside a `quote` a dependency splices into the app | its root is the package of the file that WROTE the quote — the dependency's. Same law as spans (CLAUDE.md "A COPIED TEMPLATE'S SPANS ARE ITS ORIGIN FILE'S"). |
| the app hands `dir("./assets")` to a library fn | the library may read under `app:assets/`, nothing else |
| `File.package`, `File.rel` | the package's NAME and a `/`-separated relative path. Never absolute: a handle is fingerprinted into keys. |
| a symlink, as the literal or as an entry | refused at the literal, naming it. A build must not depend on where a link points. |
| nested folders | `dir` lists recursively; `items` holds direct files; `d.sub("guide")` is the sub-folder, from the listing already read |
| `.DS_Store`, `.gitkeep` | names starting with `.` are never listed |
| `a.svg~`, `Thumbs.db` | listed. A reader filters by kind (`files(ext: "svg")`); a reader that meets a file it cannot read refuses, naming it |
| the literal's case differs from the entry's (`./Icons` for `icons/`) | refused, on every host: the literal is compared to the listed name, so a case-folding disk cannot pass what Linux fails |
| the callee | recognized by what the file IMPORTS (`use @std.source.{file}`), never by the string of its name |

When opaque types land, `File` should become one; the check stays.

### 4.2 Reading, and native steps

```avra
f.text()   f.bytes()   f.head(n)     // each a `Reach.Source` row; each reports the Part it read
f.blob()                             // `Blob.Source(f)` — a reference; reads NOTHING
f.loc(offset)                        // a Loc inside the file, for diagnostics
```

`@step` marks a fn that reads or makes bytes (§7.4 says where it runs). It is an ordinary Declares annotation with `wraps: true` — the shape `@query` has (READ `std-relation/src/query.av:47–62`). The written body moves to a private sibling; the written name becomes a wrapper:

| the step answers | the wrapper | when the body runs |
|---|---|---|
| `Blob` | answers `Blob.Pending(action)` — a recipe, as data. Runs nothing. | when the build ships it, or another step reads it |
| a value (a model, facts) | asks the compiler to run it (§7.4) and decodes the answer | now — `check` needs it |

### 4.3 Blobs: a reference, a recipe, or bytes

```avra
export enum Blob {
    /// A file's bytes, not yet read. Its digest exists when something reads it.
    Source(file: File)
    /// Bytes someone can make: the action that makes them.
    Pending(action: Action)
    /// Bytes that exist: their SHA-256 and length.
    Made(content: string, size: int)
}
export type Action = { step: string, args: Bytes, inputs: List<Blob> }
```

Planning a set builds `Source` and `Pending` values only. **Nothing in a plan reads a whole file** (v2's reader wrote `f.content()` on every item, which did).

| | action key | content digest |
|---|---|---|
| is | digest of (compiler digest, the tool's source closure, the step's stable name, the arguments, each input's CONTENT digest, the target if read) | SHA-256 of the bytes |
| computed | when the build is about to make it — for a reached member only, because it needs its inputs' digests | when the bytes are read or made |
| names | the kept `Action` run: action key → content digest + size | the bytes in the store; **the shipped file; the SRI value** |
| moves when | the compiler, the tool, an argument or an input moves | the bytes move |

- A compiler upgrade moves every action key and re-runs every step once ("Adopting a compiler costs one cold build" — COMPILER.md §2). It does not rename a shipped file whose bytes came out the same.
- **Residue, stated:** the key folds the tool's whole source closure, so editing one step re-runs every step of its package. Per-step keys need a per-step closure fingerprint; later, if measured.
- The shipped name is needed only by `build`, when the bytes exist. `check` ships nothing.
- A remote cache: bytes by content digest are verified on arrival; an action row from someone else is believed (§8.5).

**Who may read what, outside a declaration.**

| read | the grant |
|---|---|
| the make phase reads a `Blob.Source(app:photos/hero.jpg)` | **the const it was reached through.** The build reaches an artifact through a settled const; that const's grant set — the roots its declaration's literals name, kept with its verdict — is the make phase's grant for it. A `Source` outside it is refused at make, naming the const. A forged `Pending` gains nothing: its inputs are checked the same way. |
| any read of `Blob.Made(<sha>)` | **a digest is not a grant.** The bytes are readable only when THIS build's own runs read or made that digest (a per-build set, filled by the parts read under grants and the answers of this build's actions, kept ones included once validated). A digest that came from nowhere is refused — the machine-wide store cannot leak another project's bytes into this program. |
| a const reading another const (`@dep.walk(photos)`) | everything `photos` was granted — intended. So the env law (§2 ex. 9) reads: no build can bake in a secret from outside what the app's own consts name. |

### 4.4 Sets and members

Sets are **strict, nominal records**: `Files`, `Pictures`, `Vectors`. Each is `{ names, items, … }` and declares one ordinary method:

```avra
impl Pictures { fn member(name: string) -> Picture? { … } }
```

> `c.name`, where `c` is a top-level `const` (or a member of one) whose type has no field `name` and has `member`, is the expression `c.member("name")` **settled at compile time**. Absent → `type.unknown_member` at the read, listing `c.names`.

- The mechanism is "settle this expression", which lowering already does for a component's `check()` (READ `features/components/lower.av:66–71`, `SettleRoot.Expr`).
- PROBED C.27: `const menu: Icon? = icons.member("menu")` over a generic `Set<T>` with an ordinary method settles in 0.04 s; a wrong name settles to `null`. No `const` seat, no `const self`, no generic unit — the three things v1 leaned on and probes refused (C.8b, C.8c).
- A name that is no identifier: `c.member("2fa")` with a literal. One hatch.
- `x.name` where `x` is not a const (a `Pictures` parameter): refused — "a member is read from a `const`; pass the member, or walk `x.items`".
- Reserved by the contract: the fields `names` and `items`. A file whose member name is one of them is read `c.member("items")`, and the reader warns at the literal. Methods do not collide: a method without `()` is already a refused property read.

**What is lazy, truthfully:**

| | whole set | per reached member |
|---|---|---|
| the listing (names) | one read | — |
| facts (size, format, a view box) | planned once, in ONE step over the folder, kept. The step is one run with one `Range` part per file: when one file moves the whole step re-runs (32 ms of reads for 2,000 — C.30). | — |
| a transform's plan (new size, a `Pending` action) | arithmetic per item in the evaluator | — |
| **bytes read in full, made, shipped** | — | **only these** |

PROBED cost of the strict plan: 2,000 items built, mapped by a transform and one member read — **0.06 s, inside the default 600,000-step budget** (C.28). The same 2,000 with a 400-iteration fn per item blows the budget (C.29) — that work belongs in a `@step`. OS cost of listing and reading 512 bytes of 2,000 files: 32 ms (C.30, Python).

v1's "2,000 icons, 3 used → 3 planned" was false. The true law is L5 (§5).

### 4.5 One transform, four inputs

```avra
// @std/image
export trait Shots<Out> { fn shot(f: fn(Picture) -> Picture) -> Out }
impl Shots<Picture>  for File     { … }      // decode the header, then f
impl Shots<Pictures> for Files    { … }
impl Shots<Picture>  for Picture  { … }
impl Shots<Pictures> for Pictures { … }

export fn resize<Out, S: Shots<Out>>(s: S, width: int) -> Out { s.shot((p: Picture) -> resized_to(p, width)) }
```
- Generic traits parse and dispatch today. `Out` is not inferred from the bound: PROBED C.31 "`O` is not pinned by the arguments".
- **v2's rule — "a bound with exactly one fitting impl pins its argument" — is unsound, and is CUT.** One type may implement a generic trait at two arguments (PROBED C.36: two impls check clean), so "exactly one" is a fact about today's program. A library adding a second impl would break every caller that never named it.
- **The sound rule (C8):** the TRAIT declares that the implementing type decides `Out`. A second impl of it for one type is then refused where it is written, and a bound pins `Out` from the declaration. Proposed spelling, the language lead's to settle: `trait Shots<Out> for one { … }`.
- Without it, today: `fn resize<P: Each>(p: P, width: int) -> P` over `Picture` and `Pictures` runs (C.14), and a folder says its kind once: `dir("./photos") |> pictures |> resize(…)`. A typed binding also pins it today (`let p: P = made(F { n: 1 })` → `2`, C.36).
- Fan-out stays inside the item (`widths`, `formats` fill `Picture.variants`). Fan-in is a fn from a set (`sprite(icons) -> Sheet`). `each(f)` maps any per-item fn; `filtered { … }` drops items.
- Order: a set is in name-byte order and that is the only order that reaches output.

### 4.6 Providers

> A top-level `const` whose initializer is `SOURCE |> provider(args)` — the callee's declared answer is `Provided` — is an **anchor**. The provider runs as a Declares annotation over that const: what it `made` is declared beside the const, and its `value` becomes the const's initializer.

```avra
// @std/meta — NEW
export type Provided = { value: Code, made: List<Decls>, problems: List<Diagnostic> = [] }
```

| question | decided | stands on |
|---|---|---|
| how resolve knows, before typing | prefilter at the parse: a top-level const whose initializer's head is a source literal (the callee an import from `@std.source`). Then the LAST stage's callee is looked up in what the file sees and its signature's answer is asked — exactly how an annotation's fn is found today | READ `workspace.av:1577` (`has_declares`), `expand.av:107` (`declared_work(f, d, p, vis)`, `w.ret`) |
| what the initializer may hold | one source literal, one provider call, literal arguments, and the NAMES of other anchors. No stage between the source and the provider — compose inside the provider. | today's law: arguments are source-spelled or a declaration's name (READ `expand.av:125–129`) |
| an anchor argument (`sql(db)`) | crosses as that anchor's kept model. Asking it is a kept-run lookup, so order in the file does not matter. | door 2 |
| a cycle between anchors | the kernel's cycle answer, spoken as `const.cycle` naming both | exists for consts |
| when it runs | inside the resolve it serves, WHOLE, before any table is sized. Eager. | READ `workspace.av:1512–1518` "THE ARENA IS COMPLETE BEFORE ANY TABLE IS SIZED" |
| kept | the provider's answer is a `Lift` run, kept by content (door 2). A comment edit re-splices; it does not re-run. | §1.6 |
| names | **under the anchor**: `api` declares `ApiPet`, `ApiOrder`, `ApiPetsGetError`; `config` declares `Config`, `ConfigServer`. A spec that adds a schema named `Error` adds `ApiError`. It cannot clash with a name nobody prefixed. | Q2 asks about spelling it `api.Pet` |
| a clash anyway (a written `ApiPet`) | `annotation.generated_taken` at the anchor (exists), naming the spec line | |
| traits on a provided type | the provider writes `@json` / `@derive(…)` in its template — which is silently DROPPED today (PROBED C.16). Fixing that is in C7. | |
| export | follows the anchor | `generated_export`, `modules.av:378` (READ(agent)) |

**Eager, with the costs on the table (PROBED C.26):**

| generated | `check` | peak |
|---|---|---|
| 200 record types | 0.16 s | 60 MB |
| 1,000 record types | 0.24 s | 120 MB (~75 KB per declaration) |
| 1,000 types + 1,000 fns (reviewer's probe) | 0.78 s | 282 MB (~140 KB each) |
| 4,000 | refused: the 5 MiB lifted budget | — |

- **75–140 KB of compiler memory per generated declaration is an infrastructure smell**, whoever generates them: `@relation` and `@json` pay it too. Proposed ticket (§12, I3).
- So a 5,000-endpoint spec does not expand whole in v1. The provider takes what to declare: `openapi(only: ["pets", "store"])`. That is honest, source-spelled, and what generators in other ecosystems offer.
- **Per-name materialization is CUT from this design.** It contradicts the arena invariant above; nothing per-name exists (`generated_named` expands the file whole — READ `workspace.av:1557`). Revisit after I3, with a measurement.

### 4.7 Which one do I write?

| the data is | write | generates |
|---|---|---|
| many things of one kind | a reader `fn (Files) -> Pictures` | nothing |
| one thing | a reader `fn (File) -> Typeface` | nothing |
| a shape the data decides (config, spec, schema, columns, keys) | a provider | types and fns |

---

## 5. Laws

| # | law | hostile case |
|---|---|---|
| L1 | **Reads are granted by the declaration.** A run reads what its declaration's source literals name; a literal stays in its own package. | a forged handle; `file("/etc/hosts")`; a spliced template's literal; a symlink — §4.1 |
| L2 | **No world.** No env, clock, network, process at build. | `@std.io.env` in a const → `const.reach` naming the chain (exists, C.3) |
| L3 | **A witness is what was read**, by stable name and content digest. Never a stamp, an ordinal, an absolute path. | touch a file → nothing; reorder declarations → nothing; add a file → the listing; C.23's embed edit → the binary |
| L4 | **A shipped name is the content's digest.** The action key names the cache row, never a file. | a compiler upgrade: steps re-run, names stand unless bytes moved |
| L5 | **Facts are planned for the set; bytes are made per reached member.** | 2,000 icons, 3 used: 2,000 headers read once (one step, kept), 3 files read in full and shipped |
| L6 | **`check` makes what a type or a diagnostic needs; `build` makes what ships.** A value that depends on made bytes (`trimmed(p).width`) forces that step under `check`. A `Blob` nothing reads is never made by `check`. | a broken encoder: `check` clean while nothing reads its output's facts; `build` refuses at the file, through the member, at the reading site |
| L7 | **Errors point home**: into the data, then name the anchor. | a bad `$ref` → `petstore.yaml:41` (needs C7: today an unknown file renders a window of the FIRST source — READ(agent) `diagnostics/render.av:154`) |
| L8 | **No name by run-time text.** A member is a literal. | `icons.member(user_input)` → refused: the argument does not settle |
| L9 | **Order is the name's.** | a host listing in inode order → same output |
| L10 | **Whether `a.bytes()` compiles depends on the DECLARED home**, never on a made size. | a logo grows past the line: delivery may move (web) or refuse (CLI); no program's legality changes |
| L11 | **No silent drop.** | `@derive` in a provider template (dropped today — C.16) |
| L12 | **Every provided name and shipped file answers "where from".** | `avra docs ApiPet`, `avra expand`, `assets.json` |

### 5.1 The empty case, first

| encoding | empty | decided |
|---|---|---|
| a folder with no entries | `names: [], items: []` | legal, silent. A MISSING folder is an error at the literal (git carries no empty folder). |
| a 0-byte file | `size: 0`; `text()` is `""`, present | legal for `file`. `resize` refuses "0 bytes is no picture" at the file. |
| `Blob.Made("e3b0c4…", 0)` | bytes that exist and are empty | distinct from `Pending` by VARIANT, not by a nullable (v1 used `size: int?`) |
| a step that answers 0 bytes | kept as made | never re-run as "missing" |
| a provider that declares nothing | `made: []` | legal, silent |
| a listing's hash | digest of (count, then per entry: name digest, kind) | ARITY: `["ab","c"]` and `["a","bc"]` differ. Names and kinds only (§1.3). |
| an action key | digest of (…, count, each argument's digest, count, each input's digest) | two counted runs, never spliced |
| a witness with no parts | a run that read nothing | stands always — a pure const |
| a `Range(lo, lo)` | an empty read | a part whose hash is the empty digest; still names the file, so deleting it is a mismatch |

### 5.2 Names

| case | decided |
|---|---|
| a path that is also a glob (`dir("./icons/*.svg")`) | split the verb: `dir` takes a folder; `*`, `?`, `[` are refused with the fix. Filtering is a typed seat: `files(ext: "svg")`. |
| `icon-close.svg` | member `icon_close` (`-`, space, `.` read as `_`) |
| `2fa.svg`, `type.svg`, `café.svg` | no identifier (PROBED C.17: digit-led is a parse error, `type` is `resolve.reserved`, non-ASCII is `lex.error`). Read `icons.member("2fa")`. One hatch for all three. |
| `hero@2x.png` | `@` is not mapped; the core lists it under its raw stem. `@std/image` claims `@2x`/`@3x` as a density of `hero`. |
| `Close.svg` and `close.svg` | refused naming both |
| `logo.svg` and `logo.png`; `a-b.svg` and `a_b.svg` | one member, two files: refused naming both; `files(ext:)` picks |
| `names.svg`, `items.svg` | §4.4 |
| two names equal under Unicode normalization | non-ASCII names are compared by the bytes the host lists. A build on two hosts that normalize differently differs — stated, not solved; the listing digest in the receipt shows it. |

---

## 6. Safety

| what runs | where | can reach | by |
|---|---|---|---|
| glue: a pipeline's plan, a member read, model → declarations | the evaluator, in the compiler | what its declaration was granted | `Reach` (exists), budgets (exist) |
| a `@step` of a package that declares NO extern | the evaluator or the tool (§7.4) | the bytes the compiler sends it | the reach check at tool build, and the process boundary |
| a `@step` that reaches package C | the tool, always | the bytes it is sent — plus whatever its C does that the OS does not stop | the process boundary; the OS sandbox where one is real (§7.6) |

- **A tool that links C runs only when the ROOT manifest names its package** — `[build] native = ["@acme/avif"]`; the toolchain's own `@std/*` are implicit. v2 said no grant was needed because "its C already runs in your program". That is not the same trust: build-time C runs on the developer's and CI's machine with their credentials, and includes dependencies whose C never ships. The list goes away for a host where §7.6's last row is real. (Q5.)
- **External tools (ffmpeg): no.** Unpinned, different per machine. The hatch, unbuilt until needed: a `[process.tools]` row (exists, `cli/avra.toml:8`) with a pinned digest, read through `input_tool`.
- **Budgets.** The evaluator's glue keeps the root's `[lifted]` budget (only the root raises it — READ(agent) `packages.av:74–78`). A step that outgrows it moves to its tool by rule (§7.4), so a heavy third-party provider needs no budget line in every app.

**URLs and the lock.**
```toml
# avra.lock — written by `avra lock`; committed
[[source]]
url    = "https://example.com/v3/openapi.json"
sha256 = "9f2c…"
size   = 5310022
```
`avra lock` fetches what the sources spell and the lock lacks. `avra lock --update <url>` re-fetches and shows the change. `check` and `build` never touch the network: a miss says "run `avra lock`". `--frozen` refuses a lock that would change. Bytes live in the content store (§1.5).

---

## 7. Native steps

### 7.1 The numbers

| | evaluator | native | ratio |
|---|---|---|---|
| a loop iteration (`t = t + i % 7`) | 2.4 µs (C.11) | — | — |
| `@std/json`: parse + print | 19 KB in 0.48 s ≈ **40 KB/s** (C.12) | 5.47 MB in 0.27 s user ≈ **20 MB/s** (C.32) | **~500×** |
| build the native program | — | **0.68 s** cold, 0.05 s warm (C.32) | |
| start a process | — | **2.9 ms** (200 runs in 0.57 s, C.33) | |
| a 5 MB spec, cold | ~2 minutes | 0.7 s build + 0.3 s | |
| a 12 MP image | hours | the codec's speed | |

### 7.2 The decision: a step's package is compiled for the host and run as a child

**Chosen over "fix the evaluator to 20×".** No profile stands behind 20×. At 20× JSON is still 25× slower than native, and pixels still need C — which, called from the evaluator, would run INSIDE the compiler with no boundary at all. P4 outranks minimalism.

| | how |
|---|---|
| the tool | the package's `@step` fns behind one generated entry: read a request, run the step, write the answer. Collected the way `rules` are (READ `compiler/rules_table.av:102`). |
| built by | a child `avra build --tool <package>`, for the HOST. Kept like any binary (warm: 0.05 s). |
| built when | the first time a step of that package must run in its tool (§7.4) |
| reads | **the tool opens nothing.** A read is a message the compiler checks against the grant (L1), answers, and records as a `Part`. The witness is the compiler's own; a tool cannot under-report it. |
| answers | a value in the settled wire (`settlement_wire.av`, "S2", exists compiler-side; the tool side needs a derived codec — NEW std code), or bytes, stored by content |
| batching | one process, many requests. No batch API; `@batched` is CUT. |
| parallel | N processes of one tool fed from one queue. The compiler stays single-threaded; it multiplexes N children's pipes (NEW: a poll loop). N defaults to half the cores, at most 8. |
| cross-compilation | tools build for the HOST. An answer is per TARGET only where the step read `target()`. |
| pending inputs | the compiler makes an action's inputs first, then sends bytes. A tool never asks for a tool. |

**What stays in the evaluator:** the plan (arithmetic, `Source` and `Pending` records), a set of a few thousand mapped (C.28), a member read, model → templates, and small steps (§7.4).

### 7.3 Two prerequisites v2 did not state

**(a) `avra build` cannot compile a package's C.** READ `Makefile:46–51`: "A MANIFEST SAYS WHAT TO LINK, NEVER HOW TO BUILD IT, and this rule is the how". READ `compiler/host/manifest.av:175`: `[link]` takes `objects`, `wasm_objects`, `search`, `libs`, `dynamic_symbols` — no sources. A tool that links C therefore builds only where `make` already built that object: in the toolchain's own tree, and for no third-party package at all.

| works WITHOUT it | waits on it (Q9) |
|---|---|
| every pure-Avra tool: JSON, YAML, TOML, CSV, OpenAPI, JSON Schema, SQL, catalogs, markdown, SVG (`vectors`), WGSL as text | `@std/image` (resize, WebP, AVIF), font tables read in C, any third-party codec |

So slices 1–5 and the provider half of slice 6 do not wait. The photo pipeline does.

**(b) A tool build must not need a tool.** Case: package P declares `@step fn a`, and a file in the tool's closure holds `const x = file("./x") |> a`. Building P's tool resolves that file, which needs P's tool. CLAUDE.md records this shape at 986 processes ("A SELF-TEST MUST NOT BE REACHABLE FROM THE ENTRY POINT IT EXERCISES"; "THE FIX IS THE SHAPE, never a depth counter").

> **A tool is built with no tool door.** Under `avra build --tool`, the row a step's wrapper calls does not exist: a settlement or an expansion that needs a step to RUN is refused where it stands — "`x` needs the step `a` while `@acme/p`'s tool is being built; a tool's own closure settles in the evaluator alone". The make phase does not run either: a tool ships no artifact.

Recursion is unreachable, not bounded: the mode has no way to start a process. The cost is a rule for tool authors — the files a tool's steps reach hold no const that runs a step — and its refusal says so.

### 7.4 One way to write it; a rule picks where it runs

An author writes ONE thing:

> **Bytes are read in a `@step`.** `text()`, `bytes()`, `head()` outside a step's reach are refused, naming `@step`.

Where a step runs is the compiler's rule, never the author's choice and never discovered in someone else's app:

| the step | runs |
|---|---|
| reaches package C | its tool |
| pure Avra, and the bytes its grant covers total ≤ 64 KiB | the evaluator, in the compiler |
| pure Avra, over that | its tool |
| pure Avra, in the evaluator, and it trips the step budget | its tool — the trip falls through; it is not an error |

- Both engines answer the same value (the gate's own law, eval == native), and the action key does not name the engine. One kept row serves both.
- So `const config = file("./app.toml") |> toml` needs no tool and no linker. A 5 MB spec does.
- The 64 KiB line is a guess to measure: at ~40 KB/s (C.12) it is ~1.5 s of evaluator, about two tool builds.

**`check` and tools (Q10).** A value a type or a diagnostic needs must exist under `check`. When the rule above says "its tool":

| | |
|---|---|
| cold cost | one `avra build --tool` per package with such a step: ~0.7 s each for a small one (C.32), run one after another unless designed otherwise; then kept |
| needs | a linker on the machine. Today `check` needs none. |
| where it cannot work | a compiler that cannot spawn (hosted as wasm, a playground), a machine with no linker: `check` refuses there, naming the step and its input's size. Windows is not addressed anywhere in this tree (ASSUMED: no Windows host). |

### 7.5 The pipe protocol

| | decided |
|---|---|
| descriptors | requests on fd 3, answers on fd 4. stdin is `/dev/null`. **stdout is pointed at stderr**, so a C library that prints cannot corrupt the stream. stderr is captured, bounded, shown only on a failure. |
| framing | every message is `kind (u32) · request id (u64) · length (u64) · bytes`. Kinds: `Hello`, `Call`, `Read`, `Bytes`, `Refused`, `Answer`, `Failed`. One request open per process at a time. |
| needs | a bytes-clean framed read and a full-write loop. Both NEW: `@std/process`'s long-lived child is text and lines (READ(agent) `process.av:644, 706, 719`). |
| a crash (exit, or EOF inside a frame) | the open request is blamed: "`@std/image`'s tool exited 139 while `resized` ran on `app:photos/hero.jpg`", with the stderr tail. The rest of that process's queue is re-queued ONCE to a fresh process. A second crash on the same action is its refusal; other actions go on. |
| a hang | a wall-clock limit per request (default 60 s; `[build] step_seconds`). The parent kills the process; the open request is refused as timed out; the rest re-queue. |
| partial output | a frame is whole or absent. Bytes enter the store only after the frame closes and the compiler has hashed them. |
| stray prints | cannot reach fd 4 |
| version skew | impossible by construction: the tool's key folds the compiler's digest. `Hello` carries it anyway; a mismatch is a compiler defect and traps. |
| a nondeterministic tool | one content digest is recorded and shown in the receipt; nothing detects it |

### 7.6 What is real about the sandbox

**The reach check, as it must become.** Today any extern not in the registry is World (READ `interp.av:535–542`), so the check as it stands refuses every C-calling step. At tool build:

| a step's closure reaches | ruling |
|---|---|
| registry rows marked `Pure`, `Lookup`, `Source` | allowed |
| a `World` row | refused, with the call chain (exists for settlements) |
| a package's own `extern fn`, DEFINED by an object its manifest names | allowed in the tool only; counts as "reaches package C" (§7.4) and needs the root's `native` list (§6) |
| an `extern fn` nothing in the package's objects defines (`system`, `getenv` from libc) | refused. NEW: read from the objects' symbol tables at tool build (`tools/externs.py` does the source half today). |

"Real for Avra code" therefore means: for a package that declares no extern at all.

| limit | macOS | Linux | status |
|---|---|---|---|
| Avra code: no ambient file, env or network | the reach check above | same | real, by the compiler |
| the tool opens nothing; every read is a checked message | yes | yes | real, ours to write |
| wall-clock limit | the parent kills | the parent kills | real, ours to write |
| memory ceiling | the parent polls and kills. `setrlimit` on address space is not enforced (ASSUMED). | `RLIMIT_AS` (ASSUMED) | macOS: a poll, not a wall. Nothing exists today (C.34). |
| **package C** opening a file or a socket | a pure-computation sandbox profile at tool start (ASSUMED available; deprecated API) | a seccomp filter at tool start (ASSUMED) | **convention only until built** — which is why §6 asks the root to name such packages |

---

## 8. Performance

### 8.1 The cost model

| phase | cold | nothing changed | one photo edited |
|---|---|---|---|
| read and hash inputs | each part read: ranges for facts, whole files for what ships | the same reads, fresh (the law, §1.2). 500 MB of reached photos ≈ 0.5 s at ~1 GB/s (ASSUMED; D6). | the same |
| listings | one per `dir` | the same | the same |
| plan a set | one facts step (native) + glue: 2,000 items ≈ 32 ms of reads (C.30) + 0.06 s (C.28) | 0: the const is a kept run | the facts step re-reads one range; glue re-runs (0.06 s) |
| a provider | tool build 0.7 s once per compiler; parse at ~20 MB/s; splice ~0.2 ms and ~75 KB per declaration (C.26) | 0 runs; re-splice only if its file was read | 0 |
| make (build only) | each reached action, N tools in parallel | 0: kept actions | that photo's actions |
| emit | write each reached file | skipped when the output holds the name | 1 file |

Every "0" in the middle columns is door 2. Without it each is the cold number, per process (PROBED C.26: 0.04 s → 0.25 s on a comment).

### 8.2 Memory
Blob bytes never enter the kernel: values hold a 32-byte digest or a recipe. A tool's memory is its own process's. A 4 MB text const today is static data in the binary (C.10: `check` 0.27 s, 66 MB); with blobs it is a handle unless `home(.Program)`.

### 8.3 Reachability
avra-8sb5.76 (compile only what is reached) and L5 are the same demand at two grains.

### 8.4 `avra dev`
**No resident compiler.** The dev loop is: a file event → a one-shot `avra build` → the running app reloads. The build is fast because of door 2 and kept actions, not because anything stays alive. v1's "the dev server forces a blob on first request" put the compiler in a long-lived process, against COMPILER.md §8. Removed. (`avra dev` lives on branches `ui-dev` and `os-watch`, not in this tree; whether it already works this way is not READ.)

### 8.5 A remote cache
One hook, later: `[build] cache = "https://…"`, asked on a local miss. Bytes are verified by content. Action rows are believed — so the cache is written only by builders you trust. Nothing else in the design changes when it lands.

---

## 9. Outputs and targets

### 9.1 Local or external — who has the bytes

| the bytes are | spelled | the build | the program at run time | needs |
|---|---|---|---|---|
| **local** | `file`, `dir` | reads them | has them, at its home | — |
| **pinned external** | `url(…)` | fetches once; pinned; then local | has them, at its home | `url` + the lock |
| **external, facts known at build** | `url(…) \|> video \|> home(.Origin)` | fetches once to learn size, format, dimensions, SHA-256; ships nothing | fetches from the origin; verifies the digest (SRI on web) | `url` + the lock |
| **remote** | `remote(https("…"), width: 96, height: 96)` | reads nothing | fetches; the author wrote the facts; no digest | only artifacts (§11 slice 5) |

The owner's "external asset with typed facts known at build" is row three. **It cannot land before `url` and the lock.** Until then only row four exists, with hand-typed facts. Q6.

### 9.2 Where a local asset lives

```avra
export enum Home { Inline, Program, Bundle, Cdn(origin: string), Origin }
```

| home | the build writes | the program holds |
|---|---|---|
| `.Inline` | nothing | the content in what draws it |
| `.Program` | static data in the binary or the wasm module | name, size, the bytes |
| `.Bundle` | `build/<target>/assets/<stem>.<content8>.<ext>` | name, size |
| `.Cdn(o)` | the file, for `avra deploy` | name, size, origin |

**Two separate things:**

1. **The declared home** — written with `home(…)` or `[assets]`. Known at `check`. `a.bytes()` compiles **only** when the declared home is `.Program`. (L10.)
2. **Delivery**, when nothing was declared — the build's choice, by made size and target. It decides how `image(…)` and `icon(…)` reach the bytes. It never makes `a.bytes()` legal or illegal.

**The delivery rule:**

| target | under the line | over the line | the line |
|---|---|---|---|
| web | in the module (a vector may be inlined in markup) | a hashed file | 4 KiB per asset, 64 KiB per module |
| CLI, TUI, server | in the binary | **the build stops**: "`hero` is 1.4 MiB — say `home(.Bundle)` or `home(.Program)`" | 1 MiB |
| iOS, Android | the bundle, always | — | — |

- **Who leaves when the module total is exceeded:** candidates sorted by size ascending, then name; admitted while the total fits; the rest are files. Deterministic, and in the receipt.
- On web a crossing moves an asset and the build prints it. On CLI/server it stops the build: that changes what must be deployed.

**One override, three scopes:**
```avra
const logo = file("./logo.png") |> home(.Program)                             // per asset
fn thumb(p: Picture) -> Picture { p |> resize(width: 320) |> home(.Bundle) }  // per pipeline
```
```toml
[assets]            # per project — the ROOT avra.toml
inline_under = 4096
[assets.web]
home = "bundle"
```
Precedence: the asset's own `home` (last wins) → `[assets.<target>]` → `[assets]` → the delivery rule.

### 9.3 The web case, both ways

```
$ avra docs icons.close --target web
Vector 24×24 — app:icons/close.svg (612 B)
  home      none declared → delivery: in app.wasm (612 B < 4 KiB; module assets 1.8 of 64 KiB)
  requests  0

$ avra docs photos.hero --target web
Picture 320×180 webp — app:photos/hero.jpg
  home      none declared → delivery: build/web/assets/hero.b41d02aa.webp (17 KB > 4 KiB)
  requests  1, lazy; size known at build

$ avra docs photos.hero --target web          # after `[assets.web] home = "program"`
  home      .Program — declared by [assets.web], avra.toml:14
  ships     inside app.wasm (+17 KB)
```

### 9.4 Reconciled with `2026_10_05_UI_ASSETS.md`

| that design | here |
|---|---|
| `asset art = "art" { hero { dark: "…" } }` | replaced by `const` + pipeline; a variant is an argument |
| kind sniffed from bytes; `trait Asset` collected program-wide | the reader is named in the pipeline; a mixed folder is a provider |
| laws 3, 5, 8, 10, 14, 15, 17 | kept (L8, L1, facts in the value, L5, library, library, L6) |
| law 9: "A file's public name is its KEY (source bytes ⊕ recipe ⊕ codec version)" | **changed**: the public name is the CONTENT digest (§4.3). That design rejected "public names from output bytes — unknown until an encoder ran"; but only `build` ships, and `build` has the bytes. |
| `at <home>` | `home(…)`, a fn |
| receipt, `explain`, homes, `remote` | kept |
| fonts: subsetting, shaping | untouched |

`2026_10_05_UI_ARCHITECTURE.md`: `src` carries a `Url` (READ(agent) :161–171); a `Picture` projects to a `Url.Local` on web.

---

## 10. The same mechanism, other consumers

| consumer | today | fits |
|---|---|---|
| `embed` | reader 7 | door 1; it shrinks to `file(p).text()` and its four defects go (C.2, C.5, C.9, C.23) |
| every derive and annotation (`@json`, `@model`, `@relation`, `@form`, `@derive(View)`) | re-run per process, and per edit of their file | door 2, as `Lift` runs. The compiler's own tree is the first beneficiary. |
| `@query` answers | `Db.answers`, unarmed | door 2, as `Answer` runs |
| the `Decl` row behind `avra docs` | hand listing + file witness | door 2 |
| wasm-opt and linker identity (avra-8sb5.68, .69) | no key | door 1, `Tool` |
| `wire.gen.js`, `avra_rt.h` (generate, check in, `cmp`) | make targets | an outbound artifact: `placed(blob(host_table().bytes()), …)`. Needs slice 5 only. |
| `features/rt.av` from `rt_sigs()` | the same loop | should NOT fit: it is the compiler's own source; generating it at compile time is a bootstrap cycle |
| sublanguages | parse-time | should not fit: syntax, not data |
| `@std/openapi` | emits a spec from routes at run time | the reader is a new provider beside it |
| the docs `site` | string literals | example 8 |

---

## 11. Build order

| # | slice | usable at the end | needs |
|---|---|---|---|
| **1** | **door 1** (with the DB lead): typed parts, `Host.read_bytes` and a typed listing, `@input` over `Host`, `KeyParts.runs` typed, `build_inputs` folds them, the SHA-256 row; `embed` on top; grants | `embed` correct (C.2, C.5, C.9, C.23 closed); `const cfg = parse_toml(file("./app.toml").text())`; wasm-opt keyed | D2, D3 |
| **2** | **door 2** (with the DB lead): the kept run; `Seated`, `Lift`, `Answer` on it; one-commit witness | a comment edit re-runs no derive (receipt: C.26's 0.25 s → the 0.04 s floor); the compiler's own cold `check` stops re-running every derive | D1, D4, D5 |
| 3 | members; `Files`; a reader's set | `icons.close` over a real folder — names and facts, no bytes | 1 |
| 4 | provider anchors, eager and kept; diagnostics into a non-`.av` input; annotations inside generated code; `toml`, `csv`, `environment`, `json_schema` | typed config, tables, env | 1, 2 |
| 5 | the content store; artifacts; homes; `target()`; `remote(…)`; web, html, tui, headless | `icon(icons.close)` ships; `assets.json`; `wire.gen.js` as an artifact | 1, 3 |
| 6a | tools for pure-Avra steps: `@step`, the protocol, `avra build --tool`, the engine rule, actions as kept runs, N processes | a real spec parsed in under a second; `vectors` over a big folder | 2, 5; Q10 |
| 6b | tools that link C; `@std/image` | the photo pipeline | 6a; **Q9 (who builds package C)**; Q5 |
| 7 | the bound rule (C8) | the sketch as written | — |
| 8 | `url`, `avra.lock`, `avra lock` | pinned specs; external-with-facts (§9.1 row 3) | 5 |
| 9 | the C sandbox per OS; the remote cache hook; iOS/Android delivery | | 6 |
| — | **independent track:** `\|>` (C1) | pipelines everywhere | — |
| — | **deferred:** per-name provider laziness | | I3 fixed and measured |

Slices 1 and 2 are the gate. Nothing in §8 is true before 2.

---

## 12. Compiler changes, re-sized

| # | what | where | size | landings |
|---|---|---|---|---|
| C1 | `\|>` | `grammar/lexer.av` (one arm, `continuing_op`), `features/expr_spine/{mod,builders}.av` (one rule between `coalescing` and `bitwise`, the desugar, three refusals), `core/store.av` (a mark that restamps), `compiler/format/source_text.av`, `features/tables` (refusal text) | ~250 + tests | 1 PR under the syntax-change protocol (`avra.pre`, two builds); a seed refresh before the tree writes it |
| C2 | door 1 | `compiler/inputs.av`, `host/host.av` (+ the CLI's disk host), `record.av` (`KeyParts.runs`), `kept_settle.av` (an input line), `modules.av` (`build_inputs`), `interp.av` (source rows report parts; grants), `core/ir.av` (`Reach.Source` — a registry enum, every consumer spelled, `make vocab`), `whole.av` (delete `admit_embeds`), a SHA-256 row, new `packages/std-source` | ~900 | 3: the runtime rows alone first (the row-then-declaration ladder: the compiler's own closure will name them); then the door; then `embed` moved. A record wire change (D3). |
| C3 | door 2 | new `compiler/kept.av` from `kept_settle.av`; `expand.av`/`workspace_analysis.av` (`Lifted` asked through it); `answers.av`; `db.av` (`still_valid`) | ~600, mostly moved | 2; every step under `cache_attacks` |
| C4 | members | typing of a property read (the fallback when the field is absent), lowering (`SettleRoot.Expr`), two voices | ~350 | 1 |
| C5 | artifacts and homes | `compiler/lower` (reached statics of an artifact type), `build.av`/`link.av` (the emit step, the receipt), `target()` in `@std/meta` (promised in COMPILER.md §7d, never built) | ~500 | 1–2 |
| C6 | tools | the tool row and its evaluator arm (the row-then-declaration ladder); a child `avra build --tool` with no tool door (§7.3b); the framed pipe protocol (runtime C + Avra, both new); `@step` and the seat codec (std code); the engine rule; the reach check over objects' symbols; a poll loop over N children; the make phase | **not sized.** v2 said ~2,500 lines in 4–5 landings; the reviewer calls the landing count low and I agree. Size it after Q9 and Q10. | 6a then 6b |
| C10 | **`avra build` compiles a package's C** (Q9) | `compiler/host/manifest.av` (`[link] sources`, flags), `build.av`/`link.av` (a C driver through the declared `clang` tool), the `Makefile`'s one rule retired for packages | not sized | a prerequisite of 6b only |
| C7 | providers, eager | `expand.av` (the anchor prefilter and work; a source literal as an argument; `value` spliced as the initializer), `@std/meta` (`Provided` — growth; the first READER owes the seed refresh), `diagnostics/render.av` (a non-`.av` source; no `sources[0]` fallback), annotations inside generated declarations | ~700 | 2 |
| C8 | a trait declares that the implementing type decides a parameter; a second impl for one type is refused; a bound then pins it | the traits feature's grammar and impl law; generic call pinning | not sized (not read) | 1; a language decision (Q3) |
| C9 | `url`, the lock, `avra lock` | a new command file, `std-source` | ~400 | its own slice |

Not on the list: a JIT; parallel settlement; a new keyword; a new IR instruction; a resident compiler.

**Infrastructure tickets proposed** (beyond the two doors, which are C2 and C3):

| # | what | evidence |
|---|---|---|
| I1 | **an embedded file's edit is invisible to `build`** — a wrong answer today | PROBED C.23; reproduced by the reviewer; filed as avra-8sb5.57.164. |
| I2 | `embed`: escape (in flight elsewhere), nested-call compiler trap, unlocated traps, callee matched by string, text only, a run-time trap instead of a refusal | PROBED C.2, C.5, C.9; READ `whole.av:382` (and C.35). Closed by C2. |
| I3 | **75–140 KB of compiler memory per generated declaration** | PROBED C.26 and the reviewer's probe. Blocks any large provider; taxes every derive. |
| I4 | an annotation inside generated declarations is dropped silently | PROBED C.16 |
| I5 | a diagnostic naming an unknown file renders a window of the first source | READ(agent) `diagnostics/render.av:154` |
| I6 | `avra_str_parses_float` has no registry row, so `@std/json` cannot settle | PROBED C.4; it is runtime C (READ(agent) `runtime/avra_runtime.c:1240`). One row. |
| I7 | a `const`-seat lookup with a wrong name is `check`-clean and traps at run time; a method's inner `const` reading `self` reports a compiler defect | the reviewer's probes of C.8b; not needed by this design any more, still defects |
| I8 | `it` does not bind at a free fn's seat | PROBED C.13; blocks `xs \|> filter(it.valid)` |
| I9 | no opaque type | PROBED C.25; ROADMAP.md:1796 |
| I10 | the evaluator: 2.4 µs per loop iteration; a `Map` filled in a loop is quadratic in memory (avra-8sb5.73) | PROBED C.11. No longer on this design's path; still worth a profile. |
| I11 | `avra explain` is documented and absent | PROBED C.18 |
| I12 | no process limit of any kind in the runtime | PROBED C.34. Built in C6. |

---

## 13. The review's flaws

| flaw | status | where |
|---|---|---|
| **B1 / H1** the infrastructure answer is a new cache beside the old; cites a closed ticket; ignores `KeyParts`, `Db.answers` | **FIXED** | §1: two doors, what each replaces, the campaign's decisions followed; .57.6 removed, .57.101.12 cited; five paths → two; seven readers → one; D1–D7 for the DB lead |
| B1's hostile case (add `new.svg`) | FIXED | §1.3, §1.6: a `Listing` part in `KeyParts.runs` |
| **B2 / H3, H4** laziness laws false; member rule contradicted by probes | **FIXED** | §4.4: strict nominal sets; the member rule is a settled expression over an ordinary method (PROBED C.27); L5 restated; the 2,000 case re-run: 0.06 s (C.28), and 32 ms of reads (C.30) |
| B2: `Dir` hashes every byte | FIXED | §1.3: a `Range` part; digest on read |
| B2: §2.1's reader blows the budget at 2,000 | FIXED | facts are one native step (§4.4, §7) |
| **B3 / H2** `Blob.key` is two things | **FIXED** | §4.3: action key and content digest; names and SRI from content; the compiler digest in the action key only |
| **B4 / H5** providers vs resolve | **FIXED** | §4.6: the anchor rule (parse prefilter + the last stage's signature, as annotations are found), order and cycles, eager and kept, costs on the table, names under the anchor |
| B4: per-name materialization | **CUT** | §4.6; deferred behind I3 |
| B4: the struct-literal name hole in a template | not re-probed | noted for C7 |
| **B5 / H6** forgeable handles; open cases | **FIXED** | §4.1: authority rides the declaration, not the value (PROBED C.25); template root, `File.rel`, symlinks, nested folders, case, droppings all decided |
| B5: "enforced by the OS" | FIXED | §7.6 says what is real and what is convention |
| B5: where granted C runs at `check` | FIXED | always in the tool; never in the compiler process |
| **B6 / H7** performance is a hope; workers misread | **FIXED** | §7: native tools decided on numbers (C.32, C.33); `stage.av` claim deleted; `@batched` CUT; budgets (§6) |
| **B7 / H8** homes | **FIXED** | §9.2: `a.bytes()` follows the declared home (L10); the module total rule; L6 for `check`; §8.4 no daemon; §9.1 says row three needs `url` |
| **B8 / H9** the surface | **FIXED** | §0 is the sketch as written; C8 is the one rule it needs (PROBED C.31); today's form stated |
| H9: precedence, the line form, the channel collision | FIXED | §3 |
| **H10** survey corrections | **FIXED** | C.6 and C.8b restated in Appendix C; 18 sites counted first-hand; "no KERNEL family persists; `Db.answers` does, unarmed"; `trailing` and `continued_by` described as READ; §14 lists every invented name |
| F: `at` with three meanings | FIXED | `home(…)`, `f.loc(…)`, `member` |
| F: `Dir.files` field and method | FIXED | `Files.items`; `files(ext:)` is the only method |
| F: `icons` vs `vectors` in the example | FIXED | Appendix A |
| F: three hatches for one problem | FIXED | one: `.member("…")` |
| F: `Blob.size: int?` | FIXED | an enum |
| F: listing key | FIXED | §1.3, said once |
| F: SHA-256 placement | FIXED | slice 1 |
| F: `Provided` asks four methods | FIXED | one record, no trait |
| F: L10 and the CLI line were two statements | FIXED | §9.2 only |
| F: adding a field to a set type breaks folders | FIXED | two reserved names (§4.4) |
| G: build order | FIXED | §11 |
| D: mtime fast path (not flagged; found re-reading the code) | CUT | §1.2 — it contradicted a standing law |
| **DISPUTED** | none | every re-run probe agreed with the review. One number differs, not a finding: my provider probe mints types only, 75 KB each; the reviewer's mints a type and a fn, 140 KB each. |

### 13.1 The second review (of `4c0ff43`)

| item | status | where |
|---|---|---|
| three inaccuracies under H10: the `read` slot's callers; `kernel.av:320–325`; P4's witness "direct" | **FIXED** (facts corrected) | §1.1, §1.3, §1.4 |
| D1 is a sibling of .57.101.12 | FIXED | §1.2, §1.7 |
| the reader count; the five kept rows outside "five → two" | FIXED (facts corrected) | §1.1, §1.4 |
| N7: no input kind for existence or env | **FIXED** | §1.3: `Exists`, `Env`, and what stays out |
| N1 the witness atom · C.3 the store's read verb and concurrent writers · C.5 .57.4.6 · C.6 which mechanism door 1 is · C.7 the fast-path fix and the outside rows · §6.6's pack | **PENDING THE DB LEAD** — not redesigned here | §1.7 D2, D4, D8–D11 |
| N4: a kept lift and spans | receipt restated; mechanism PENDING | §1.6, D5 |
| **N2**: `avra build` cannot compile package C | **FIXED** as a stated prerequisite; put to the owner | §7.3a, C10, Q9 |
| **N3**: a tool build can need a tool | **FIXED**, by shape | §7.3b: a tool is built with no tool door |
| D.3: `check` builds and runs native code | **FIXED**: stated, costed, put to the owner | §7.4, Q10 |
| D.4: the protocol is named, not specified | **FIXED** | §7.5 |
| D.4: the reach check refuses every C-calling step as it stands | **FIXED** | §7.6 |
| D.5: two ways to write a provider | **FIXED**: one way; a compiler rule picks the engine; a budget trip falls through | §7.4 |
| D.6: C6's size | **CUT** — not sized until Q9 and Q10 | §12 |
| **N5**: Appendix A's reader read every file | **FIXED** | `Blob.Source`; `f.blob()`; Appendix A |
| E.2: the grant for the make phase; a read by digest | **FIXED** | §4.3 |
| B3 residue: one step's edit re-runs the package's steps | stated | §4.3 |
| **N6**: C8 unsound | **FIXED**: the "one fitting impl" rule CUT; the declared form in its place | §4.5, Q3, C.36 |
| E.3: the 4,000 ceiling beside example 5; the facts step re-runs whole | FIXED | §2, §4.4 |
| Q5: the reviewer's option | **adopted** | §6, Q5 |
| Q9–Q12 | added | §15 |
| the template struct-literal hole | still not probed by me | noted for C7 |
| **DISPUTED** | none | C.36 reproduces the reviewer's two probes |

---

## 14. Every NEW name in this document

Nothing in this table exists. Everything else named in the doc does.

| package | names |
|---|---|
| `@std/source` (new package) | `file`, `dir`, `url`, `File`, `Files`, `Blob` (`Source`, `Pending`, `Made`), `Action`, `blob`, `each`, `filtered`, `Artifact`, `Home`, `home`, `placed`, `remote`, `step` |
| `@std/meta` (growth) | `Provided`, `refused`, `target`, `Target` |
| `@std/image` (new package) | `Picture`, `Pictures`, `Shots`, `pictures`, `resize`, `webp`, `widths`, `formats`, `Vector`, `vectors` |
| providers (new) | `openapi` as a reader, `toml` as a provider, `csv`, `json_schema`, `environment`, `schema`, `sql`, `catalogs`, `typeface`, `wgsl`, `markdown`, `video` |
| the compiler | `InputKind`, `Part`, `input_*`, `RunName`, `RunKind`, `kept`/`keep`, `Reach.Source`, the tool row, `Host.read_bytes`, a typed `Host.list`, a SHA-256 row, the framed pipe read and write |
| the language | `trait T<Out> for one` (C8; the spelling is a proposal) |
| the CLI | `avra lock`, `avra build --tool`, `avra cache gc`, `[assets]`, `[build] native`, `[build] step_seconds`, `[build] cache`, `[link] sources` (Q9), `avra.lock` |

Exists and is used as it is: `quote`, `Directive`, `Declared`, `Decls`, `Code`, `Diagnostic`, `refuse_at`, `literal`, `wraps: true`, `collect`, generic traits, named arguments, trailing blocks, `const` settlement, `SettleRoot.Expr`, `Reach`, `Store.keep`'s `read` slot, `KeyParts`, `Db.answers`, `@input`, `avra expand`, `avra docs`, `avra cache why`.

---

## 15. For the owner

Only decisions. Two options each, then my pick.

**Q1. Heavy build work: native tools, or a faster evaluator?**
- A: a step's package is compiled for the host and run as a child process (§7). ~500× the evaluator on a parser today.
- B: profile and speed up the evaluator; codecs as C called from inside the compiler.
- Pick **A** — and for anything with C in it, A depends on Q9.

**Q2. What is a provided type called?**
- A: `ApiPet` — the anchor's name as a prefix. No language work; a spec edit cannot clash with your names.
- B: `api.Pet` — a type path through the anchor. Reads better; needs a type-path rule and a literal form.
- Pick **A now**, B as its own design.

**Q3. The sketch as written: `dir("./photos") |> resize(width: 320)`.**
- A: land a trait form where the implementing type decides the result (`trait Shots<Out> for one`); the sketch then types as he wrote it.
- B: no language change; a folder says its kind — `dir("./photos") |> pictures |> resize(width: 320)`. Runs today.
- Pick **A**, and write B until it lands. Not v2's "one fitting impl" rule: a library adding an impl would break callers.

**Q4. Where does a local asset live when nobody says?**
- A: by size — small in the program, large beside it (web 4 KiB; CLI/server stops the build over 1 MiB and asks).
- B: by target only — web always a file, CLI always embedded.
- Pick **A**; the numbers are guesses to measure.

**Q5. A tool that links C, before an OS sandbox exists (§7.6).**
- A: runs for any dependency, in a child with two pipes and a time limit.
- B: runs only for packages the ROOT manifest lists; `@std/*` implicit.
- Pick **B** (the reviewer's; I had A). Build-time C runs with the developer's and CI's credentials, and includes dependencies whose C never ships.

**Q6. `url` and the lock: in this campaign?**
- A: yes, minimal (https, SHA-256, `avra.lock`, `avra lock`) — "external asset, facts known at build" cannot land without it.
- B: wait for package transport; until then `remote(…)` with hand-written facts.
- Pick **A**, as slice 8.

**Q7. `avra dev`.**
- A: one-shot builds on file events; the compiler never stays alive.
- B: a resident compiler that makes an asset on first request.
- Pick **A**; B reopens "no daemon".

**Q8. A compiler upgrade re-runs every step once.**
- A: yes — the action key folds the compiler's digest. Shipped names do not move.
- B: key steps by the tool's source only, and trust that codegen did not change behaviour.
- Pick **A**.

**Q9. Who builds a package's C?**
- A: the manifest learns sources and flags, and `avra build` compiles them (P13, P14: no Makefile between a package and its binary).
- B: packages ship prebuilt objects per host; `make` stays the builder for the toolchain's own.
- Pick **A**. Without it no third-party package with C can have a tool, and `@std/image` works only in the toolchain's tree. Pure-Avra tools do not wait (§7.3a).

**Q10. May `check` build and run a native tool?**
- A: yes, when the rule says a step is too big for the evaluator (§7.4): the first `check` pays ~0.7 s per such package and needs a linker.
- B: no — `check` runs everything in the evaluator; only `build` uses tools.
- Pick **A**. Under B a 5 MB spec is two minutes per cold `check`. Small sources never need a tool either way.

**Q11. A machine-wide, content-named byte store outside the tree (`~/.avra/cache/bytes`).**
- A: yes — the first toolchain state outside a checkout; made bytes are shared by worktrees and survive a compiler upgrade.
- B: bytes stay under the tree's `.avra-cache`; every worktree and every compiler re-makes its own.
- Pick **A**, for bytes only. Rows stay per compiler, per tree.

**Q12. Who owns the two doors (§1)?**
- A: the DB campaign, with this design as the first consumer.
- B: this campaign builds them.
- Pick **A**. Both doors change `KeyParts`, the kept-settle wire and the hold.

---

## 15a. Decided by the owner (2026-10-05)

| Q | decided |
|---|---|
| 1 heavy build work | native tools |
| 2 provided type names | `api.Pet` — a type path through the anchor; needs its own short design before slice 7 |
| 3 the sketch as written | land the trait form where the implementing type decides the result |
| 4 default home | by size, with the override |
| 5 a tool that links C | pending — explained to the owner, recommendation B (root manifest lists them) |
| 6 `url` and the lock | in this campaign |
| 7 `avra dev` | pending — explained, recommendation A (one-shot builds, no resident compiler) |
| 8 compiler upgrade re-runs steps | yes |
| 9 who builds a package's C | `avra build`, from the manifest |
| 10 `check` may run a native tool | yes |
| 11 machine-wide byte store | yes, bytes only |
| 12 who owns the two doors | this session with the owner; no other session exists. §1 is designed with him before anything is built on it |

`|>` is being landed on branch `pipe-op`.

# Appendix A — three things an author writes

Design code (§14). Every language form in it is one that exists.

**A reader.**
```avra
//! @acme/icons — a folder of SVGs as a set of icons.
use @std.source.{Files, File, Blob, step}
use @std.meta.{refuse_at, refused}

export type Vector  = { name: string, width: int, height: int, shape: Blob }
export type Vectors = { names: List<string>, items: List<Vector> }

impl Vectors {
    fn member(name: string) -> Vector? {
        let i = self.names.index_of(name)
        if i < 0 { return null }
        self.items[i]
    }
}

/// Every `.svg` under the folder, by its stem. ONE step for the whole folder, 512 bytes read per file.
@step
export fn vectors(d: Files) -> Vectors {
    let svgs = d.files(ext: "svg")
    Vectors { names: svgs.names, items: [vector(f) for f in svgs.items] }
}

fn vector(f: File) -> Vector {
    let box = view_box(f.head(512)) ?? refused(refuse_at(f.loc(0), "`${f.rel}` has no `viewBox`", "an icon says its own size"))
    Vector { name: f.name, width: box.w, height: box.h, shape: f.blob() }   // a reference: only 512 bytes of this file are read
}
```

**A transform.**
```avra
//! @std/image (excerpt)
/// No wider than `width`, shape kept. The plan is arithmetic; the pixels are a recipe.
fn resized_to(p: Picture, width: int) -> Picture {
    if width >= p.width { return p }
    let height = max(1, p.height * width / p.width)
    p with { width: width, height: height, pixels: resized(p.pixels, width, height) }
}

/// Bytes in, bytes out. Runs in the tool, when something needs the bytes.
@step
fn resized(src: Blob, width: int, height: int) -> Blob {
    let out = with_room(width * height * 4)
    blob(out.slice(0, avra_img_resize(src.bytes(), width, height, out)))
}

extern fn avra_img_resize(src: Bytes, width: int, height: int, out: Bytes) -> int
```
`out: Bytes` is a seat, never an answer: an extern answering `Bytes` is `type.host_seat` (PROBED C.20).

**A provider** — typed TOML. `@std/toml` runs at compile time today (C.5b) and its entries carry spans (`toml.av:23`).
```avra
//! @std/toml (addition) — a manifest as a typed record.
use @std.meta.{Provided, Decls, Code, Diagnostic, refuse_at, literal}
use @std.source.{File}

export fn toml(f: File) -> Provided {
    let doc = parse_toml(f.text())
    let made = [record_of(doc, s) for s in doc.sections()]
    Provided {
        value: value_of(doc),
        made: [root_of(doc)].concat(made),
        problems: [refuse_at(f.loc(e.lo), e.message, null) for e in doc.errors],
    }
}

/// `[server]` under `const config` is `type ConfigServer = { port: int, … }`.
fn record_of(doc: TomlDoc, section: string) -> Decls {
    let fields = [quote { type _ = { ${e.key}: ${spelled(e.value)} } } for e in doc.entries_of(section)]
    let n = "Config${camel(section)}"
    quote { export type ${n} = { ..${fields} } }
}
```
`root_of`, `value_of`, `spelled` and `camel` are ordinary fns omitted here. The anchor's name (`Config` above) reaches the provider as its first seat does for an annotation today; the exact crossing is C7's.

# Appendix B — every compile-time mechanism today

| mechanism | lives | runs | mints names? | reads | kept across runs |
|---|---|---|---|---|---|
| `const` settlement | `workspace_analysis.av:451,568`; `interp.av:352` | after typing; lazy under `check` (C.3b) | no | pure code; `embed` | P4, unseated only; P1 when the file is held |
| `const` seats | `features/fns/mod.av:51`, `checks.av:1627` | a unit per settled value | no | — | no |
| annotations: Validates / Records | `features/annotations/check.av:27,168` | at typing | no | the declaration | no |
| annotations: Declares / Derives | `expand.av:93,124`; `workspace.av:1518` | **inside resolve**, whole file | **yes** | the declaration from the parse; source-spelled arguments; `type_named` | no (P1 when held) |
| `quote` | `features/quote/mod.av:13` | parsed where written; spliced in expansion | via a directive | — | — |
| sublanguages | `features/sublang/mod.av:24` | at the parse | no | the provider module's plain parse | — |
| components | `features/components/mod.av:22` | a one-`quote` `expand` at the parse; `check()` settled at lowering | no | `self` | — |
| `collect` | `features/collects/mod.av:37` | lowering | variants (`collect enum`) | declarations of a kind | — |
| `embed` | `meta.av:311`; `interp.av:845` | at settlement | no | one text file, any path | `KeyParts.runs` when held; **not** in P4 or P5 (C.23) |
| the extern host | `interp.av:1360` | `avra run` only | — | a package's `.dylib` | — |

| asked | answer | receipt |
|---|---|---|
| Can a `const` hold a record whose fields came from data? | Through a Declares annotation that generates the type and the const — the MINTING works. The names in my probe were hard-coded; the annotation cannot read the folder. | C.6, C.7 |
| Can a compile-time fn read a file? | Only `embed`: a literal, text, in a const. | C.3, C.4, C.7 |
| Can an annotation's argument be a path? | It is a string like any other; the annotation cannot read it. | C.6 |
| What does `@std/openapi` do? | Emits a spec from routes at run time. No reader. | READ(agent) `openapi.av:26–76` |
| Does any query family persist? | No KERNEL family does. `Db.answers` persists `@query` answers and has no caller outside tests. | READ `answers.av`; PROBED grep |
| Is settlement parallel? | No. Object emission is, 4 threads (`llvm.av:179`). | READ |

# Appendix C — probe log

Binary `avra-ui-assets-design/build/avra` (0b5bd64), `LLVM_PREFIX=/opt/homebrew/opt/llvm`. `run`/`check` of scratch files, plus single-file `build` where marked.

| # | probe | output |
|---|---|---|
| C.1 | `const k = 3 \|> dbl` | `error[parse.expected]: expected BREAK while parsing 'stmt'` |
| C.2 | `embed("/etc/hosts")` | `256` |
| C.3 | `const T = read_text(…)`, read | `error[const.reach] … 'T' reaches 'avra_io_open'` |
| C.3b | the same const, unread, `check` | clean |
| C.4 | `const DOC = parse(embed("data.json"))` | `const.reach … reaches 'avra_str_parses_float' in '@std.text.parse_float'` |
| C.5 | `parse_toml(embed("cfg.toml"))` in one const | `avra: a 'File' write moved the whole relation after a compiler query (reader 936) read it this revision` |
| C.5b | through a named text const | `2 name 2` |
| C.6 | `@folder("icons") type Icons = {}`, a Declares annotation minting `type ${t}Set = { ..${fields} }` and a const; **the member names were a hard-coded list — the path literal was unused** | `icons/close.svg 24`, 0.14 s; typo → `no field 'clsoe' on 'IconsSet' … the fields are 'close', 'menu'`; `avra expand` prints both with their template line |
| C.7 | the same annotation calling `embed` | `… this compile-time call cannot return build inputs` |
| C.8 | `fn at(const s: Set, const name: string)` with an inner `const`; a wrong name | `error[const.trap] … index -1 is out of bounds`, at the library's line |
| C.8b | `impl Set<T> { fn member(const name: string) -> T }`; `s.member("b")` | `20`. **Passing case only.** The reviewer ran the wrong name: `check` clean, `run` traps. This form is no longer used (§4.4). |
| C.8c | a generic const-seat fn with an inner `const`; `at(at(outer, "in"), "x")` | `const.form … declares 'T'`; `type.const_seat … computed at run time` |
| C.9 | `embed` of a PNG; of a missing file | `avra: '…/a.png' is not UTF-8 — byte 0`; `avra: '…/nope.txt' does not exist` — no location |
| C.10 | a 4.1 MB text file as a const | `check` 0.27 s, 66 MB peak |
| C.11 | `for i in 0..n { t = t + i % 7 }`, `avra run` | n = 0.5M, 1M, 2M, 20M: 1.19 s, 2.42 s, 4.89 s, 47.6 s. Default budget refuses at 1M: `took more than 600000 steps` |
| C.12 | `parse_toml` over 17.4 KB; `@std/json` parse + print over 19 KB, `avra run` | 0.74 s; 0.48 s |
| C.13 | `each(s) { dbl(it, by: 3) }`; `each(s, it * 2)` | runs; `error[resolve.unresolved]: 'it' rides a METHOD call's arguments — nothing binds it here` |
| C.14 | `trait Pictures { fn each(f: fn(Image) -> Image) -> Self }`, impls for an item and a nominal set, `fn resize<P: Pictures>(p: P, width: int) -> P` | `3 4` |
| C.15 | generic `each<A, B>(s: Set<A>, f: fn(A) -> B)` in a const, a named fn | `2,4` |
| C.16 | `@derive(Show)` inside a Declares template | `'Pet' has no method 'show'` — dropped, no word |
| C.17 | a field named `type`; `let café`; a field `2fa` | `resolve.reserved`; `lex.error`; `parse.expected` |
| C.18 | `avra explain icons` | `avra: unknown command: explain` |
| C.19 | `grep '\|>'` over every `.av` in `packages/`, comments removed | nothing |
| C.20 | main's 09-30 binary over main's packages | `type.host_seat: the answer of 'avra_bytes_with_room' wears 'Bytes', which cannot cross to C` |
| C.21 | a const record holding a fn | `error[const.form]` |
| C.22 | `webp(1, lossless: true)` with defaulted seats | `1 q80 true` |
| **C.23** | package `ks`: `const TEXT: string = embed("x.txt")`, `println` its length. `build`, run → `3`. Edit `x.txt` to 8 bytes, `build`, run. Then also append a comment to `main.av`, edit to 12 bytes, `build`, run. Then park `.avra-cache` and `build`. | `3`; `3`; **`3`**; with the cache parked: the true length. Repeated: edit to 8 → `build` prints `2` (stale), `avra run` prints `8`. |
| C.24 | `data/data.av`: `export const K: int = made(3)`; `main.av` prints `K`. `build`, run; change `made`'s body; `build`, run | `30`; `33` |
| C.25 | package `cap`: a lib exports `type Handle = { path: string, seal: Seal }` with `Seal` private. Outside: `a with { path: "/etc/hosts" }`; `Handle { path: "/etc/passwd", seal: a.seal }` | `read /etc/hosts 7 \| read /etc/passwd 7` — both forgeries accepted |
| C.26 | a Declares annotation minting N record types, `check` | N=200: 0.16 s, 60 MB. N=1000: 0.24 s, 120 MB. Unchanged re-check: 0.04 s. One comment appended: 0.25 s. N=4000: `annotation.unsettled` (budget) |
| C.27 | `impl Set<T> { fn member(name: string) -> T? }`; `const menu: Icon? = icons.member("menu")`; `const typo: Icon? = icons.member("clsoe")` | `m.svg absent`, 0.04 s |
| C.28 | a 2,000-item nominal set built, mapped by `resized`, one member read as a const | `320`, 0.06 s, default budget |
| C.29 | a 2,000-item set where each item runs a 400-iteration fn; one member read | `error[const.budget]: … 'icons' took more than 600000 steps` |
| C.30 | Python: list 2,000 files and read 512 bytes of each; SHA-256 each whole | 31.8 ms; 34.4 ms |
| C.31 | `trait Shots<Out>`, four impls, `fn resize<O, S: Shots<O>>(s: S, width: int) -> O`; `resize(File {…}, 3)` | `error[type.mismatch]: 'O' is not pinned by the arguments` |
| C.32 | package `nt`: read a 5.47 MB JSON, `parse`, `to_text`, print the length. `avra build`; run; rebuild | build 0.68 s; run 0.27 s user (0.72 s wall, first exec), 128 MB peak; warm rebuild 0.05 s |
| C.33 | 200 runs of a tiny native Avra binary in a shell loop | 0.57 s |
| C.34 | `grep RLIMIT\|setrlimit\|sandbox_init\|seccomp` over `runtime/*.c` and every package's C | nothing |
| C.35 | a user `fn embed(p: string) -> int { p.length }`, called with a literal | `19`, no refusal. That `admit_embeds` treats this call as an embed is READ (`whole.av:382`: `callee.of != "embed"`), not observed: minting a `FileId` for a missing file prints nothing. |

| C.36 | `trait Shots<Out>`; `impl Shots<P> for F` AND `impl Shots<Q> for F`; `fn made<O, S: Shots<O>>(s: S) -> O`; `let p: P = made(F { n: 1 })` | `2`, exit 0 — two impls for one type are legal, and a typed binding pins `O` |

Not probed: the struct-literal name hole the reviewer hit in a template; whether `avra dev` on its branches is already one-shot; lines per kept run on `check packages/cli` (D8); hashing speed (D6).
