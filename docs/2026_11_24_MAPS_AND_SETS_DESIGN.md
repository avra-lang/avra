# Maps and sets — generic keys, a Swiss index, one representation the compiler chooses

Design, 2026-11-24. Approved by the owner 2026-11-24, with the phasing of §12 (decisions in §11).
Tracked as epic avra-8sb5.99 (the phases are its tasks; the set literal is avra-8sb5.99.4).

**In one line:** `Map<K, V>` takes any key the compiler can hash and compare, `Set<T>` is a map with
no values, one insertion-ordered representation (dense entries plus a Swiss-table index) serves both,
the compiler picks a cheaper layout where the key type allows it, and every list the tree uses as a
set moves.

Every number below was measured in this session, unless it says otherwise. The sources:
- **Rust:** `/work/bench/rbench`.
- **Avra:** `/work/bench/abench`, built by a gen-2 compiler of the train-2 tip over cccc5ecb.
- **Censuses:** the cost slice's own (snapshot 91ebc6c5).
- **Site counts:** a probe `fact_rule`, never committed.

Each table names its machine and method.

## 1. What the tree has today

### The built-in Map (runtime/avra_runtime.c §"Maps", runtime/avra_box.h `AvraMap`)

- **Keys are text only.** `alias M<K> = Map<K, int>` is refused with "a map's keys are strings, not `K`"
  (features/structs/tests/alias_adversarial_test.av:48).
- **The layout is already the indexmap / CPython-dict split.** Two dense arrays, `keys` and `vals`,
  hold insertion order. An open-addressing index of `int64` words (slot + 1 in the low half, the
  hash's high 32 bits above) finds a slot, probing in growing strides. An index of capacity 0 is
  unbuilt and built on first lookup.
- **Hashing is already hardened.** It is a keyed wyhash-shaped fast hash with process secrets from
  the OS. A probe past `PROBE_TRIPWIRE = 128` rekeys that one map under SipHash-1-3. The seed never
  reaches output (CLAUDE.md, "A MAP'S ORDER IS ITS INSERTION ORDER").
- **Remove is O(n).** `avra_map_remove` shifts both arrays (`array_drop`) and then
  **rebuilds the whole index** (`map_index_rebuild`) on every removal.
- **A walk copies the map.** `for k, v in m` lowers to `avra_map_keys` plus `avra_map_vals`
  (features/lists/walk_lowers.av:189), and each of those is an `array_clone`: two fresh lists and a
  retain per element before the first iteration.

### What grew around it (non-test sites in `packages/`)

| structure | where | sites | what it really is |
|---|---|---|---|
| `HashKeyedTable<T>` | std-program/src/hash_keyed_table.av | 81 | a map keyed by a content hash / two words |
| `SideTable<V>` | std-avrac/src/core/side_table.av | 76 | a dense map keyed by a typed id (`ExprId`, `StmtId`, …) over a window |
| `Interned<T>` | std-program/src/interned.av | 8 | a map value → dense id, plus the reverse list |
| `IdMemo<V>` | std-program/src/interned.av | 11 | a dense map keyed by an `InternId` |
| `DenseWindow` | std-program/src/dense_window.av | 9 | a dense map over an id window |
| `Map<string, bool>` | everywhere | 196 | a set of strings |

### Lists used as sets

A probe `fact_rule` fired on `xs.contains(x)` and `xs.index_of(x)` where `xs` types as a `List`. It
was the shape the migration rule (§8) will have, added to a scratch tree and run with
`avra check` over eight packages. Sites are de-duplicated by `file:line:col`.

| | sites | not in tests | on a line with `for`/`any`/`all`/`filter`/`map`/`find`/`count` |
|---|---|---|---|
| `List.contains` | 569 | **528** (std-avrac 424, std-relation 26, std-grammar 22, std-ui 18, cli 17, std-http 13) | **223** |
| `List.index_of` | 133 | **101** (std-avrac 81) | not split |

The Lead's figure of 2,150 `.contains(` counts every receiver. 1,561 of those calls are in tests,
and most of them are `string.contains` (a substring test, which stays).

### What maps cost the compiler today

On the check-cli census (snapshot 91ebc6c5, train-2 tip), `avra_map_slot` is
**40.6 M of 148.3 M string compares (27%)**. Those are text keys compared on a hit: the compiler
keys its maps by text because no other key is allowed.

## 2. The measurements this design is held to

Machine: 4 vCPU cloud container, one core pinned (`taskset -c 0`), best of 5. Rust 1.97 with
`opt-level=3, lto=fat, codegen-units=1`, hashbrown 0.15, indexmap 2.14, foldhash 0.1, rapidhash 1.
The workload: build N entries, look every key up (hit), look N absent keys up (miss), walk every
entry. Keys are `"key{i}"` / `"nokey{i}"`. Int keys are `i * 0x9E37…` in Rust and `"${i*7919}"` in
Avra, the only key Avra takes. Rust's string "build" includes cloning each `String`, a malloc that
Avra's (rc) map does not pay.

| ns/op | n | build | hit | miss | walk |
|---|---|---|---|---|---|
| **Avra Map (text)** | 8 | 43.1 | 22.0 | 19.6 | 25.3 |
| Rust indexmap + foldhash (String) | 8 | 56.6 | 10.4 | 7.0 | 9.4 |
| **Avra Map (text)** | 1 000 | 29.6 | 12.9 | 19.9 | 12.0 |
| Rust indexmap + foldhash (String) | 1 000 | 59.0 | 6.1 | 3.3 | 0.39 |
| Rust hashbrown + foldhash (String) | 1 000 | 67.5 | 5.7 | 4.1 | 2.08 |
| **Avra Map (text)** | 100 000 | 110.2 | 39.9 | 38.4 | 14.2 |
| Rust indexmap + foldhash (String) | 100 000 | 86.3 | 12.6 | 10.6 | 1.25 |
| **Avra Map (text)** | 1 000 000 | 106.9 | 38.9 | 37.4 | 11.2 |
| Rust indexmap + foldhash (String) | 1 000 000 | 221.7 | 30.8 | 14.7 | 1.35 |
| Rust hashbrown + foldhash (String) | 1 000 000 | 347.1 | 33.7 | 9.4 | 2.78 |
| Rust std HashMap (SipHash-1-3) | 1 000 000 | 480.8 | 118.1 | 26.6 | 3.01 |
| **Avra Map, int keys as text** | 1 000 000 | 113.9 | 33.8 | 37.4 | 11.0 |
| Rust hashbrown + foldhash (u64) | 1 000 000 | 27.1 | 8.7 | 4.2 | 2.20 |
| Rust indexmap + foldhash (u64) | 1 000 000 | 83.5 | 14.4 | 5.7 | 0.80 |

What the table says:
- **Text hits are close already.** At 1 M, Avra's hit (38.9 ns) is 1.26× indexmap's (30.8).
- **Misses are not.** At 1 M a miss costs 2.5× indexmap's and 4× hashbrown's: the `int64`-word
  index has no group probe, so a miss walks a stride chain.
- **Walks are 8–30× slower.** The two `array_clone`s plus a retain per element are the whole gap.
- **Int keys are 4× hashbrown on a hit and 9× on a miss,** because an int must be spelled as text,
  hashed as text, and compared as text.
- **Small maps (n = 8) pay 2× indexmap on a hit:** an index probe where a scan of eight entries
  would do.

## 3. Surface

```avra
let m: Map<ExprId, Ty> = {}            // any hashable key
let seen: Set<string> = Set.new()      // no values
seen.add("a")                          // answers whether it was new
if seen.has(x) { … }
for k, v in m { … }                    // insertion order, as today
for x in seen { … }                    // insertion order
```

- **`Map<K, V>`.** The vocabulary is unchanged: `get`/`set`/`has`/`remove`/`keys`/`values`/
  `entries`, and `for k, v in m`. The law that a key must be text is lifted. `K` must be
  **hashable**:
  - int, bool, text, `Bytes`;
  - every enum, every record and every tuple whose fields are all hashable;
  - `Name` (interned: its id is the hash);
  - `ContentHash` and every content key (§5).
  - **Never hashable:** floats (NaN breaks `==`; a `Map<float, …>` is refused with the reason),
    fn values, `Cell`s, and anything holding one.
- **`Set<T>`** has `add`/`has`/`remove`/`length` and walks in insertion order. Set algebra
  (`union`, `intersect`, `minus`) answers in the order the left operand holds, then the right's new
  members. Proposed literal: **none at first.** `Set.of([a, b])` and `xs.set()` are enough, and a
  literal is an owner decision (§10).
- **Hash and equality are derived, never written.** The compiler derives both for every hashable
  type, structurally, the way `@derive(Identity)` derives identity today. There is no user `impl
  Hash`. A record that wants another equality is a different key type (a projection), which keeps
  `==` and the map's notion of "same" one law.

## 4. Representation

One representation is the default. The compiler chooses a cheaper layout where the key type says
it is safe. Every layout keeps the **insertion-order law**.

### 4.1 The default: dense entries + Swiss index (indexmap's split, Abseil's probe)

```
AvraMap2 { header; entries: { hash: u64, key: K, val: V }[]  (insertion order, tombstoned)
           ctrl: u8[cap + GROUP]   (EMPTY | DELETED | h2 = top 7 bits of the hash)
           slot: u32[cap]          (index into entries)
           len, live, cap }
```

- **The probe.** Lookup takes `h1 = hash >> 7` to pick a group and `h2 = hash & 0x7f`. It compares
  16 control bytes at once (SSE2 `_mm_cmpeq_epi8` + `movemask` on x86-64, NEON on arm64, a portable
  SWAR 8-byte path elsewhere, as hashbrown does). Then it checks only the entries whose h2 matched,
  **cached hash first, key second.** A miss usually ends in its first group: one 16-byte compare
  and no key read. This is the fix for the miss column above.
- **Size.** The index is 5 bytes a slot (1 control + 4 u32) where it is 8 today. A map can then hold
  up to 2³² − 1 entries, and larger maps fall back to u64 slots, as indexmap does.
- **The cached hash in each entry** makes growth a re-file of hashes with no key read, and filters
  most false h2 matches before the key compare.
- **Remove** marks the entry a tombstone and the control byte DELETED: O(1), not today's O(n)
  shift + full rebuild. When tombstones pass ¼ of the entries, one compaction pass closes them up in
  order and re-files the index (CPython's dict). Insertion order is kept exactly.
- **A walk** reads `entries` in place, skipping tombstones. The map is a value with copy-on-write,
  so a walk is a borrow of the version it started on: a write during the walk copies the map, as a
  write to a shared list does today. No `array_clone` of keys and values happens: that is the walk
  column's 8–30×.

### 4.2 Small maps: no index

At ≤ 8 live entries there is no index: lookup scans the entries comparing cached hashes, then keys.
That is hashbrown's and CPython's small-table insight, and indexmap's gap at n = 8 above. The first
insert past 8 builds the index. This is a runtime branch on `cap`, not a type.

### 4.3 Dense ids: a direct table (subsumes `SideTable`, `IdMemo`, `DenseWindow`)

When `K` is a **declared dense id type** (`ExprId`, `StmtId`, `PatId`, `DeclId`, `InternId`, any
record of one `int` field that the compiler marks dense), the map is `{ lo, vals: V[], present:
bitset }`.
- `get` is a bounds check plus a bit test.
- The order law still holds, because ids are walked in **insertion order** through a side list of
  inserted ids, kept only when the map is walked. The compiler knows statically when a dense map is
  never walked and drops the list.
- `SideTable<V>`, `IdMemo<V>` and `DenseWindow` become `Map<Id, V>`, with this layout chosen.
  `SideTable`'s "born total with a seed" is `Map.filled(window, seed)`.
- The choice is made by the type, never by the writer: a `Map<ExprId, Ty>` is this layout. It falls
  back to §4.1 when the inserted ids are sparse (span > 4 × live, checked at growth).

### 4.4 Sets

`Set<T>` is `Map<T, ()>` with the `val` column absent: entries are `{ hash, key }`, and a dense set
is a bitset plus the insertion list. `Map<string, bool>` used as a set (196 sites) becomes
`Set<string>`.

### 4.5 Key layout classes (what the runtime sees)

| class | keys | hash | eq | entry key size |
|---|---|---|---|---|
| **W** word | int, bool, enums without payload, `Name`, ids | one folded multiply with the seed | one compare | 8 |
| **K** content key | `ContentHash`, `Key`, `NameKey` | §5.2 | two compares | 16 |
| **T** text | `string` | §5.1 | length, then bytes | 8 (pointer) |
| **G** composite | records, tuples, payload enums, `Bytes` | compiler-derived fold of the fields' hashes | compiler-derived | pointer or inline ≤ 16 B |

## 5. Hashing

### 5.1 Text and bytes

Keep today's design and swap the core: **rapidhash** (wyhash's successor, the same multiply-mix
family the runtime already has) with process secrets drawn from the OS, plus the existing
SipHash-1-3 rekey past the probe tripwire. Measured here on string keys:
- rapidhash and foldhash are within noise of each other at 1 k entries (hit 7.6 vs 5.7 ns);
- foldhash leads at 1 M (hit 33.7 vs 46.6 ns);
- both are 3–4× faster than SipHash-1-3 (std HashMap: 118 ns a hit at 1 M).

**Recommendation: foldhash's string path** (a folded multiply over 16-byte chunks), keyed per
process. Before choosing, run its hit and miss on Avra's own key population (identifiers, paths,
query keys), not only `key{i}`. Either way the output never depends on the seed, because order is
insertion order.

### 5.2 Content keys skip hashing their bytes, never the seed

A `ContentHash` is already 128 uniformly distributed bits (blake3-derived), so the map does not
hash its bytes again. But it is still **one folded multiply with the per-process seed**:
`hash = fold_mul(high ^ seed0, low ^ seed1)`. An attacker who controls content can grind partial
collisions on a known bucket function: finding k colliding low bits costs only 2^k tries. The seed
makes the buckets unknowable. The cost is one multiply. "Skip hashing" means skip the bytes, never
the seed.

### 5.3 Words and composites

- **W keys:** `fold_mul(x ^ seed0, seed1)`, foldhash's integer path, one 64×64→128 multiply.
- **G keys:** a compiler-derived fold. Each field's hash is mixed into a running state with the
  same `fold_mul`, in declaration order. Each variant's tag is mixed first. The derivation lives
  beside `@derive(Identity)` and reuses its field walk. It differs from identity: identity is a
  cross-process content print; a map hash is in-process and seeded.

### 5.4 The laws that stay

- The seed never reaches output. `AVRA_HASH_SEED` pins it for tests.
- A probe chain past the tripwire rekeys that one map under SipHash.
- Equal keys hash equal across layouts: a W key and the same value in a G record field hash through
  the same `fold_mul`.

## 6. Runtime and IR

**One family per layout class, not per type.**
- `avra_map_w_*`, `avra_map_k_*`, `avra_map_t_*` (today's rows, re-laid) and `avra_map_g_*`.
- W, K and T have their hash and eq inline in C; the probe loop is one C function per class
  (SIMD in C, where intrinsics live).
- G takes the key's derived `hash` and `eq` as two fn pointers in a per-type descriptor (a static
  constant the compiler emits once per key type), so the probe loop stays one C function.
- A key type used in a hot G map can later be monomorphized in IR. That is a ZERO_COST row (§7),
  not the first build.

Why classes and not full monomorphization: Avra's runtime rows are C. A per-type IR probe loop
loses the SIMD group compare unless the IR emitter grows vector intrinsics. Four classes cover every
key the tree uses today: W for ids and enums, K for content keys, T for names-as-text and paths, and
G for the rest. The G path's indirect call is paid only by composite keys.

- **Eval == native.** The evaluator calls the same C rows: it already reaches the runtime for maps.
  Output order is insertion order on both, so the seed cannot make them differ. One witness case
  per layout class is added to `witness_program_runs`.
- **The dense layout (§4.3)** is chosen in lowering from the key type. It has its own rows
  (`avra_dmap_*`), equally shared by the evaluator.

## 7. ZERO_COST.md rows this adds

Each row has its detector, per that file's law ("a technique without a detector is a wish").

| technique | detector | candidates today |
|---|---|---|
| **list used as a set → `Set`** | the `list_used_as_set` rule (§8) | 528 `contains` + 101 `index_of` (223 per element) |
| **`Map<string, bool>` → `Set<string>`** | a shape rule on the declared type | 196 |
| **text key of a typed value → typed key** (`m.get("${id}")`, `name.text()` as key) | census: `avra_map_slot` string compares by caller | 27% of check-cli's string compares |
| **dense-id map** (§4.3) | chosen by type; a census site of `avra_map_*` over an id key is a miss | the 76 + 11 + 9 SideTable/IdMemo/DenseWindow sites |
| **walk without copy** | census: `array_clone` callers under a map walk | every `for k, v in m` |
| **small-map scan** | a runtime branch, not a row: the census shows `avra_map_slot` probes at n ≤ 8 | |
| **G-key monomorphized probe** (later) | census: indirect-call share of `avra_map_g_*` by key type | none until G keys exist |

## 8. Memory law (CLAUDE.md: headers, rc)

- **The box.** A map is one box (the header with rc and kind 2, as today) that owns three
  allocations: entries (rc'd elements), ctrl and slot.
  - Keys and values in `entries` are owned: the map holds one reference each. Removing an entry
    releases them at once; a tombstone holds nothing.
  - ctrl and slot hold no references: plain bytes, never walked by rc.
- **Copy-on-write.** A copy of a map is a retain. The first write to a shared map copies entries
  (retaining each element) and rebuilds the index from the cached hashes, so no key is read.
  "A snapshot keeps the order it had" (CLAUDE.md) holds by construction.
- **W and K keys are inline**, never boxed. A `Map<ExprId, Ty>` boxes nothing per key.
- **The dense layout's `present` bitset** is plain bytes, so a missing value carries no rc.

## 9. Benchmarks and targets

The `benchmarks/` suite gets a `tasks/maps` family with the workload of §2, in Avra, Rust (indexmap
+ foldhash and hashbrown + foldhash), and C (the runtime rows called directly, the floor). The gate
refuses a regression past its margin, as for the concurrency family. The targets, against
indexmap + foldhash on the same machine and core:

| | target |
|---|---|
| text keys, hit and miss, n ≥ 1 k | ≤ 1.2× |
| text keys, build (excluding key allocation) | ≤ 1.2× |
| int / id keys (W), hit and miss | ≤ 1.2× hashbrown + foldhash (u64) |
| dense-id map get | ≤ 2 ns (a bounds check and a bit test) |
| walk, every layout | ≤ 1.5 ns/entry (today 11–25) |
| n = 8, hit | ≤ 1.2× indexmap |
| remove | O(1) amortized; a 1 M-entry remove-all ≤ 2× its build |

These are the "best and fastest languages today" bar made concrete: hashbrown is Rust's std map, and
indexmap is the ordered map Avra's law requires.

## 10. Migration

1. **The rule.** `list_used_as_set`, a `fact_rule` in compiler/idioms.av fires on `xs.contains(x)`
   and `xs.index_of(x)` where `xs: List<T>` with `T` hashable, and the call stands:
   - in a loop body or comprehension that does not build `xs`;
   - in a fn the program layer marks as a query or a law;
   - or on a list that is the answer of `distinct`/a dedup.

   The fix: "build `Set.of(xs)` once, outside the walk". A `@says` names the case it can't decide
   (the list is also used in order). The probe that produced §1's counts is this rule without the
   placement condition. Ratcheted like idioms: new sites refused, the baseline falls.
2. **The sweep,** by package and by census weight: std-avrac's 424 first, ordered by the census's
   `List.contains` cost by caller. Each batch has a cost-slice run, and a batch that doesn't fall is
   named.
3. **The tables.**
   - `SideTable`/`IdMemo`/`DenseWindow` → `Map<Id, V>` (dense layout).
   - `HashKeyedTable<T>` → `Map<ContentHash, T>` (K layout).
   - `Interned<T>` stays as a library over `Map<T, InternId>` plus the reverse list.
   - `Map<string, bool>` → `Set<string>`.

   Each table's API shim lands first, then its callers, then the type is deleted.
4. **Text keys of typed values** (the 27% `avra_map_slot` share): each compiler map keyed by
   `"${id}"` or `name.text()` moves to its typed key. This is where ONE NAME TYPE (queued next) and
   this design meet: a `Map<Name, V>` is a W map whose hash is the name's id.

## 11. Decided (owner, 2026-11-24)

1. **A set literal:** none at first; `Set.of([…])` is the spelling, and a literal replaces it
   (avra-8sb5.99.4). The lead's recommendation for it: `#{a, b}` (empty `#{}`), which neither a block
   nor a map can be. `{a, b}` would make `{x}` mean a block or a set by context.
2. **Hash and eq are derived only:** no user `impl Hash`.
3. **Float keys are refused.**
4. **Set operations answer in the left operand's order,** then the right's new members.
5. **`Map` is one name for every layout;** the compiler chooses the layout.

## 12. Phasing

1. **Runtime:** the Swiss index, tombstones and the small-map scan for T keys. No language change,
   and it fixes today's miss, walk and remove. The bench family is added and gated.
2. **Language:** hashable keys W, K and G, with derived hash and eq; `Set<T>`. Eval == native
   witnesses.
3. **The dense layout,** then the table migrations.
4. **The `list_used_as_set` rule,** then the sweep.

Each phase lands with the cost slice at 0 over and its own rows.
