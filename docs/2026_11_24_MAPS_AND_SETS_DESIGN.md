# Maps and sets — generic keys, a chunked index, one representation the compiler chooses

Design, 2026-11-24. Approved by the owner 2026-11-24, with the phasing of §12 (decisions in §11).
Tracked as epic avra-8sb5.99 (the phases are its tasks; the set literal is avra-8sb5.99.4).

**In one line:** `Map<K, V>` takes any key the compiler can hash and compare, `Set<T>` is a map with
no values, one insertion-ordered representation (dense entries plus a chunked hash index) serves both,
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

### 4.1 The default: dense entries + a chunked index (built: phase 1)

Phase 1 built this for today's text keys (runtime/avra_runtime.c, "The index"). The entries stay
the two insertion-ordered arrays `AvraMap` already has, so the backend's static map layout is
unchanged. Only the index block behind `AvraMap.index` changed:

```
chunk (64 bytes, one cache line):  tag[7]  overflow  word[7]
  word  = slot + 1 (low 32 bits; 0 is none) | the hash's low 32 bits (high half)
  tag   = 0x80 | 7 more hash bits (0 is an empty place)
  overflow = how many keys' probes passed this chunk full (255 sticks)
```

- **The probe.** The hash's low bits pick the home chunk. One 8-byte SWAR compare finds the
  lanes whose tag matches. Only a lane whose word carries the same 32 hash bits reaches the
  text compare, the same 32-bit filter today's index words carried, so a probe compares no more
  text than it did (the cost slice's `string_compares` row, §4.2.1). A miss
  ends at the first chunk whose overflow is 0: one cache line, most often. Chunks step by
  growing strides, which visits every chunk of a power-of-two table.
- **Why chunks and not the Swiss layout the first draft named.** I built the Swiss layout first
  and measured it: control bytes plus a separate word array, probing 16 bytes with SSE2. Its
  control bytes and words sit in different cache lines, so a hit paid one more cache miss than
  today's index. At 1M keys a C-level hit cost 44.8 ns against today's 29.2. The chunk keeps the
  tags and the words in one line (F14's layout, Facebook's map), and the same hit costs 24.6 ns.
- **Load.** Five entries to a seven-place chunk (71%, today's 0.7). At six to a chunk, honest
  probes reached 29 chunks; at five, 12 at a million keys, about one more per doubling. The
  tripwire that rekeys under SipHash is 64 chunks.
- **Growth** re-files the words by the hash bits each carries, so no key is hashed again. A young
  table, under 64 chunks, quadruples; a larger one doubles. A map literal of `n` pairs is made at its
  size by `avra_map_sized(n)`, arrays and table at once, so the writes that fill it grow nothing.
- **Remove** frees the place, counts the overflow passes back down, and leaves a hole in the
  entries (the key's cell NULL). The index never holds a tombstone. The holes close up in one
  pass once they outnumber the live entries: O(1) amortized, where today's remove shifted and
  re-filed everything. A remove mints a new index generation, so a probe's word from before it is
  probed afresh. `m.remove(k)` probes once: the read before it hands its word to
  `avra_map_remove_at`, which finds the key's place by the word naming its slot and compares no
  text again. Today's remove probed twice.
- **A walk** is handed the map's own key and value arrays, retained, when they hold no hole
  (two rows of its own, `avra_map_walk_keys` and `avra_map_walk_vals`). A write into the map
  copies an array first while anything else holds it. So the walk reads in place and still
  walks the snapshot it began on, and a map's clone shares its arrays until its first write.
  `keys()` and `values()` still answer fresh lists. The compiler opens a `mut` binding seeded
  by a fresh answer *thawed* (core/written.av), writing in place without a count check, so a
  list a program can write must be its own.

### 4.2 Small maps: tags, no table

At 8 entries or fewer the index is 64 bytes from the slab a box comes from: the head, eight 8-bit
tags and each entry's 32 hash bits. A lookup compares the eight tags in one word, then the bits,
then the text. A miss's word handed to a write is checked against the tags, so a small map's remove
mints no generation. A remove moves the few cells down in one loop. The ninth key moves the entries
into a table by their kept bits.

### 4.2.1 What phase 1 measured

The rows below are `benchmarks/maps/strings`, as recorded on this machine (4-core Xeon @ 2.30GHz,
one core, best of 5, ns per operation). "Before" is the same program built by the compiler and
runtime at cccc5ecb.

| row | Avra before | Avra after | Go | Rust std | Python |
|---|---|---|---|---|---|
| build 8 | 24.2 | 30.9 | 27.0 | 94.9 | 44.1 |
| hit 8 | 14.0 | 11.3 | 8.7 | 13.6 | 31.6 |
| miss 8 | 10.3 | 7.6 | 12.1 | 11.1 | 18.7 |
| walk 8 | 18.8 | 5.0 | 6.5 | 0.7 | 37.5 |
| remove 8 | 72.8 | 31.2 | 23.5 | 29.3 | 23.6 |
| build 1k | 31.8 | 44.5 | 91.9 | 98.8 | 41.8 |
| hit 1k | 14.4 | 11.6 | 9.2 | 15.3 | 33.1 |
| miss 1k | 12.5 | 9.8 | 9.5 | 13.6 | 22.7 |
| walk 1k | 15.9 | 3.1 | 9.0 | 0.8 | 29.3 |
| remove 1k | 2 435 | 45.7 | 33.2 | 33.7 | 28.5 |
| build 100k | 67.2 | 70.4 | 75.0 | 145.6 | 88.6 |
| hit 100k | 24.5 | 23.4 | 20.7 | 46.0 | 48.4 |
| miss 100k | 25.2 | 16.9 | 30.0 | 23.4 | 44.4 |
| walk 100k | 19.6 | 3.1 | 8.0 | 2.2 | 29.8 |
| remove 100k | 610 628 | 63.0 | 42.8 | 70.1 | 41.1 |

- Every row is within the gate's 2.0x of Go. The widest are remove, at 1.3–1.4x.
- The "before" remove rows reopened the list slot holding each map per key. The twin now takes each
  map out once. That made no measurable difference with the new runtime (43 against 47 ns at 8).
- **The compiler's own cost slice** (`tools/cost.sh` on the pinned snapshot, the census compiler at
  the phase 1 tip against one built at cccc5ecb): 536 rows, 0 over, 41 fell. Boxes, list writes,
  retains, releases and reclaims fell 0.01–0.11%, and `string_compares` fell on every workload
  (build-cli 245 695 254 → 245 685 500). A walk no longer copies two lists, and a remove probes
  once.
- **The build regression the first cut had is mostly recovered.** At 8 and 1 000 keys the first
  cut built 28% and 40% slower than today's map. Four things recovered most of it:
  - a small index mints no generation (an atomic add);
  - the insert path is inlined into its rows;
  - young tables quadruple;
  - literals are sized.

  At the C level, maps kept alive, ns per key from today's map to this one: 8 keys 21.7 → 17.9
  (now faster), 100 000 at parity, and 1 000 keys 27.2 → 31.5, 16% still slower: the re-files of a
  table that grows from small. The release-built bench row at 1 000 keys reads 29.7 ns against Go's
  103.6.

On program d7cd84d9, with the bench's Avra twins as release builds (as every family now builds
them) on a 4-core Xeon @ 2.10GHz, the median of three gate runs (ns per op):

| row | Avra | Go | Avra ÷ Go | C floor |
|---|---|---|---|---|
| build 8 | 21.7 | 29.9 | 0.73 | 37.3 |
| hit 8 | 7.8 | 8.9 | 0.88 | 15.3 |
| miss 8 | 6.8 | 10.9 | 0.62 | 12.8 |
| walk 8 | 2.4 | 7.8 | 0.31 | 0.5 |
| remove 8 | 32.9 | 20.6 | 1.60 | 23.3 |
| build 1k | 29.7 | 103.6 | 0.29 | 65.4 |
| hit 1k | 9.2 | 9.1 | 1.01 | 19.5 |
| miss 1k | 8.6 | 8.7 | 0.99 | 7.0 |
| walk 1k | 2.2 | 8.7 | 0.25 | 1.2 |
| remove 1k | 45.6 | 41.0 | 1.11 | 49.3 |
| build 100k | 82.4 | 125.5 | 0.66 | 206.7 |
| hit 100k | 32.2 | 31.8 | 1.01 | 44.6 |
| miss 100k | 22.0 | 33.4 | 0.66 | 97.0 |
| walk 100k | 2.4 | 8.4 | 0.29 | 13.1 |
| remove 100k | 64.8 | 61.1 | 1.06 | 40.0 |

The remove of an 8-key map is the one row past Go by much. It shifts the map's cells in insertion
order, where Go's table leaves a tombstone, and it read 31.7–44.8 ns across runs, from 1.48× to
2.17× Go's.

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
- W, K and T have their hash and eq inline in C; the probe loop is one C function per class.
- G takes the key's derived `hash` and `eq` as two fn pointers in a per-type descriptor (a static
  constant the compiler emits once per key type), so the probe loop stays one C function.
- A key type used in a hot G map can later be monomorphized in IR. That is a ZERO_COST row (§7),
  not the first build.

Why classes and not full monomorphization: Avra's runtime rows are C, and the chunk probe's
word-wide tag compare is one C function the evaluator and every target share. Four classes cover every
key the tree uses today: W for ids and enums, K for content keys, T for names-as-text and paths, and
G for the rest. The G path's indirect call is paid only by composite keys.

- **Eval == native.** The evaluator keeps its own map, not the C rows
  (compiler/backend/interp.av: `map_slot`, `map_append`, `map_keys_val`), in insertion order.
  Output order is insertion order on both, so the seed cannot make them differ. A change to the C
  representation changes no answer either gives (phase 1). A new key layout must be given to both,
  and one witness case per layout class is added to `witness_program_runs`.
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

- **The box.** A map is one box (the header with rc and kind 2, as today) that owns its two entry
  arrays (rc'd boxes themselves) and one index block.
  - Keys and values are owned: the map holds one reference each. Removing an entry releases them
    at once; a hole holds nothing.
  - The index block holds no references: plain bytes, never walked by rc. Its bytes are counted
    under the ledger's index row.
- **Copy-on-write.** A clone of a map shares its entry arrays (a retain each) and copies the index
  block, so no key is read. The first write copies an array while anything else holds it.
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

1. **Runtime** (built): the chunked index, holes on remove, the small-map tags and walks over the
   shared entries, for T keys. No language change, and it fixes today's miss, walk and remove. The
   bench family `benchmarks/maps/strings` is added and gated.
2. **Language:** hashable keys W, K and G, with derived hash and eq; `Set<T>`. Eval == native
   witnesses.
3. **The dense layout,** then the table migrations.
4. **The `list_used_as_set` rule,** then the sweep.

Each phase lands with the cost slice at 0 over and its own rows.

## 13. Core protocols (phase 2)

The owner's ask: Python's `__eq__`/`__hash__`/`__iter__`/`__contains__`/`__getitem__`/`__len__`
as traits. A small set sits in the prelude, operators lower to it, and every collection implements
one core method to get every verb.

### 13.1 What exists today

- **Traits are real and dispatch statically.** `trait`, `impl Trait for T`, and bounds on a free
  fn's or method's own parameters (`fn f<T: Tr>(x: T)`) are all there. A bounded generic is
  monomorphised: one body is lowered per instantiation (features/fns/tests/generics). `dyn Trait`
  exists as the explicit dynamic form. An impl files under a generic built-in or a user generic's
  declaration, so `impl Show for Box<T>` serves every `Box<…>` (features/decls.av `implementor`).
- **What the typer refuses**, both listed in CLAUDE.md's subset:
  - a generic method, F2031;
  - a bound on a type's own parameter: `type T<K: Tr, V>` is "expected `=`".
- **Equality is the compiler's, not a trait.** `==`, `contains`, `index_of` and a literal pattern
  compare only a scalar, text, a tagged enum or a one-field record (CLAUDE.md, "Wants the typer
  does not carry yet"). `@std/derive` has `Show` and `Eq`, but both write an *inherent* method
  (`impl T { fn eq(other: T) -> bool }`), so `==` never reaches them. `@derive(Eq)` has 2 uses
  outside tests.
- **The walk verbs are a lowering table.** They are 22 rows in features/lists/walk_lowers.av
  `walk_rows`: `find`, `find_index`, `any`, `all`, `map`, `filter`, `fold`, `count`, `contains`,
  `index_of`, `take`, `drop`, `sum`, `min`, `max`, and the stages. The compiler gives them to
  `List`, ranges, a map's entries and text's lenses, fused into one loop. No user type can join.
  docs/2026_09_30_COLLECTIONS.md already planned the surface as a `Walk` trait with default
  methods (Ruby's Enumerable shape), blocked on F2031.
- `Identity` and `Fingerprint` (25 and 45 derives) are cross-process content prints. They are not
  an in-process `Hash` (§5.3), and stay apart from it.

### 13.2 What is added: seven traits in `@std.prelude`

| trait | the one method | what lowers to it | derived |
|---|---|---|---|
| `Eq` | `fn eq(other: Self) -> bool` | `==`, `!=`, a literal pattern, `contains`/`index_of`'s compare | always, structurally; **derived-only** (decision 2) |
| `Hash` | `fn hash(into: Hasher)` | a map's or set's key | always with `Eq`; **derived-only**; floats, fns and `Cell`s have none |
| `Ord` | `fn compare(other: Self) -> Order` | `<` `<=` `>` `>=`, `sorted`, `min`, `max` | in field / variant order where every part is `Ord`; a type may write its own |
| `Walk<T>` | `fn each(visit: (T) -> bool)` (the visitor answers whether to go on) | `for x in c`, every walk verb | — |
| `Len` | `fn length() -> int` | `.length`; `is_empty` is its default | — |
| `Index<K, V>` | `fn at(k: K) -> V` | `c[k]` (a map's `m[k]` traps on a missing key, as a list's `xs[i]` does) | — |
| `Contains<T>` | `fn contains(x: T) -> bool` | `.contains` | a default, from `Walk` + `Eq` |

- **One generic definition per verb.** Each verb is a default method on `Walk<T>`: `any`, `all`,
  `find`, `find_index`, `index_of`, `count`, `fold`, `map`, `filter`, `sum`, `min`, `max`, `take`,
  `drop`, and `contains` through `Contains`. A type that writes `each` has the whole vocabulary.
  `List`, ranges, `Map` (its entries), `Set`, `Bytes` and text's lenses implement `Walk` in
  `@std.prelude`, the way user types do. The 22-row table stops being the definition: it becomes
  the lowering of the defaults, below.
- **`==` lifts the subset's law.** A two-field record, a payload enum, a list of records and a
  tuple all compare by their derived `Eq`. The "compares by value — …" refusal goes. What has no
  `Eq` (a fn, a `Cell`, a float inside a key) is refused by name: "`P` has no `Eq`: its field `f`
  is a fn".

### 13.3 How the fast path is chosen, with no runtime dispatch

1. **A type's own method beats the trait's default, at the instantiation.** Dispatch is already
   static: a call resolves against the concrete type of each monomorphised instantiation. So
   `fn has_all<C: Contains<T>, T: Eq>(c: C, xs: List<T>)` instantiated at `Set<string>` calls
   `Set.contains`, O(1). At `List<string>` it calls the default, a walk with `Eq`. No vtable and
   no tag test, because the choice is made when the body is lowered for that type. The order is
   the type's own method, then its `impl` of the trait, then the trait's default. Coherence: one
   impl per (trait, type), or the program is refused.
2. **Knowledge the compiler can't see is a type, never a guess.** A sorted list's binary search is
   `Sorted<T>`, a list type whose own `contains` and `index_of` search by halves. `xs.sorted()`
   answers one, and a push that could break the order is not on it. Nothing infers sortedness from
   a value.
3. **The defaults' lowering stays the speed.** A chain of default verbs on any `Walk` source still
   lowers to one fused loop: lambdas inlined, no intermediate list (today's `walk_rows`
   lowering, now keyed by the trait's defaults rather than by the receiver being a `List`). A
   source with its own `each` gets its `each` inlined into that loop. Two laws hold the fast path
   to the definition: eval == native, and a chain equals its comprehension.
4. **The idiom rule (§10) reads the same facts.** `list_used_as_set` fires where a `List`'s
   default `contains` runs per element of a walk. Its fix names the type whose own `contains` is
   O(1).

### 13.4 What it needs first

- **F2031, generic methods and bounded defaults.** `Walk<T>.contains` needs `T: Eq` on a default
  method.
- **Bounds on a type's own parameters**, for `Map<K: Hash + Eq, V>`. Until they land, the key
  bound is checked at each `Map`/`Set` instantiation as a built-in rule.
- **Operators routed through the trait table:** `==` → `Eq`, `<` → `Ord`, `[]` → `Index`, with
  the scalar cases still lowering to their single instructions. Those are the derived impls'
  bodies, so a scalar compare costs nothing new.

The codebase-wide trait census (avra-8sb5.104) is its own note. It finds the free-fn families
these traits and others absorb, ranks them, and adds the style rule that refuses a new one.
