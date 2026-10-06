# Collection vocabulary — lists, maps, sequences

**Tracker:** epic `avra-8sb5.65` — S0 `.65.2`, S1 `.65.3`, S2 `.65.4`, S3 `.65.5`, S4 `.65.6`, bench `.65.1`; one ticket per work item.

**Status:** design, 2026-09-30. Not built. Probes and counts name base
`96fa525` (main).
**Not to confuse with** `docs/2026_09_22_COLLECTIONS.md`, which is the
whole-program `collect` declaration. This doc is the verbs a program
calls on a `List`, a `Map`, `Bytes`, a range, or its own type.

**In one line:** one vocabulary over one protocol; a chain is one loop
and a name is a list; every verb is a loop shape the compiler lowers,
so a method chain, a comprehension and a hand loop compile to the same
code.

---

## 0. The decisions

| # | decision | why, in one line |
|---|---|---|
| D1 | One vocabulary, every receiver: `List`, `Bytes`, a range, a `Map`'s entries, a user type | the same idea has one name (P1, P17) |
| D2 | **A chain is one loop, a name is a list.** Adapters in one expression fuse; the value materializes where a `List` is needed | Rust's speed without `.collect()` or a `Sequence` type |
| D3 | Evaluation order is **per element**, stated by the language | fusion then needs no purity proof, so speed never hangs on an invisible fact (P7) |
| D4 | Method chains lower to the **comprehension's pipeline**, generalized with a sink | one mechanism; the planner and fusion reach method chains for free |
| D5 | A lambda in a verb seat is **inlined**; a named fn is a direct call; only a fn *value* pays `CallPtr` | measured 2x today (§1.9) |
| D6 | Pure answers of receiver-changing words are **participles** (`sorted`, `reversed`, `inserted`); no in-place twin | reuse-in-place makes `xs = xs.sorted()` the in-place sort already |
| D7 | Every lookup answers **`T?`**: `index_of`, `pop`, `get(i)`, `min`, `max` join `find`/`first`/`last` | one absence spelling; `-1` retires |
| D8 | Sort is **stable by contract**; unstable (pdqsort) only where stability is unobservable | determinism for free, speed where it costs nothing |
| D9 | `Map` stays insertion-ordered, gains `has`/`remove`/`keys`/`values`/`entries`/paired `for`; hash becomes **seeded, length-aware, one probe** | today's hash is a DoS hole (§1.8) |
| D10 | Loop shapes are **IR**, algorithms are **Avra**, only allocator primitives stay **C** | P14 and epic `avra-8sb5.62` |

---

## 1. Inventory

### 1.1 Built-in method rows (compiler)

| receiver | rows | file |
|---|---|---|
| `List<T>` | `map filter find find_index any all contains index_of push pop set is_empty first last concat slice enumerate join` + `length` | `features/lists/mod.av:56-84` |
| `Map<string, V>` | `get set` + `length` | `features/maps/mod.av:31-43` |
| `Bytes` | `bytes text at slice concat index_of is_empty run eq_at ieq_at` + `length` | `features/bytes/mod.av:24-40` |
| `string` | `contains starts_with ends_with index_of substring split replace char_code trim is_empty` + `length` | `features/str_lit/mod.av:38-53` |
| `Cell<T>` | `new get set push set_at put` | `features/cells/mod.av:24-31` |

Paths are under `packages/std-avrac/src/`.

### 1.2 Comprehensions and walks

| form | where | lowering |
|---|---|---|
| `[e for x in xs if p]`, many heads, `for i, x in xs`, `for i in lo..hi` | grammar `lists/mod.av:87-89` | **fused**: one nested loop, push at the innermost turn, no closure (`lists/lower.av:20-60`) |
| `collect { … }` | `lists/mod.av:87` | pushes every discarded value (`lists/lower.av` `collect_reg`) |
| comprehension over a `@plans_all` relation | `lists/plan.av:1-12` | **planned**: a filter conjunct becomes an index lookup |
| `for x in xs` | `loops/check.av:57-110` | walks a `List` only; a `Map`, `string`, `Bytes` are refused |
| `xs.map(f)` etc. | `lists/walks.av:120-250` | **boxed**: the fn box is called through `CallPtr` once per element (`turn_call`, `walks.av:263`) |

### 1.3 Runtime facts

| fact | where |
|---|---|
| Every list cell is ONE `int64` word plus one mark byte; records in a cell are boxed | `runtime/avra_box.h:52-59` |
| An element read is a call: guard-flag load, bounds check, load | `runtime/avra_hot.c:47-53` |
| `%` is a call (`avra_int_mod`), even by a constant | `runtime/avra_runtime.c:834` |
| Map = keys array + values array (insertion order) + open-addressing index | `runtime/avra_runtime.c:1668-1800` |
| Map hash = FNV-1a, **unseeded**, walks to the first **NUL** | `avra_runtime.c:1674-1678` |
| `m.get(k)` = `map_has` then `map_get`: **two probes, two hashes** | `features/maps/methods.av:71-80` |
| `join` is one linear row; `split` is one row | `avra_runtime.c:1833`, `:2701` |
| `concat`/`slice` have `_reusing` twins (reuse in place) | `core/runtime_api.av:777-813` |

### 1.4 Free helpers (grep over `packages/`, call sites excluding the definition)

| helper | defined | sites | verdict |
|---|---|---|---|
| `flatten` | `core/lists.av:6`, **and** `std-grammar/src/util.av:6` | 278 | method `xs.flatten()` |
| `joined` | `core/lists.av:78` (O(n log n) pairwise merge) | 231 | method `xs.join(sep)` (linear row, exists) |
| `some_list` | `core/lists.av:72`, `std-grammar/src/util.av:21` | 91 | `filter_map` / `flatten()` over `T?` |
| `distinct` | `core/lists.av:107`, `std-grammar/src/util.av:27` | 36 | method `xs.distinct()` |
| `filled` | `core/lists.av:16`, `std-grammar/src/util.av:16` | 35 | `List.filled(n, v)` |
| `sorted_texts` | `core/text.av:70` | 30 | `xs.sorted()` |
| `inserted` | `core/lists.av:48`; a second, different one in `std-http/src/route.av:394` | 15 | `xs.inserted(at, x)` |
| `list_eq` | `core/lists.av:22` | 14 | stays (an equality, not a collection verb) |
| `reversed` | `core/lists.av:53` | 12 | method `xs.reversed()` |
| `found_at` | `core/lists.av:65` (wraps `index_of`'s `-1`) | 9 | deleted: `index_of` answers `int?` |
| `copied` | `core/lists.av:35` | 8 | stays |
| `sorted_by` (comparator) | `core/lists.av:131` (merge sort) | 6 | `xs.sorted_with(before)` |
| `sum_of` | `std-grammar/src/ast.av:120` | 4 | `xs.sum()` |
| `repeat` | `std-text/src/text.av:56` | — | stays (text) |
| `codepoints`, `chars` | `std-text/src/text.av:138`, `:143` | — | `s.chars()` |

### 1.5 Hand-rolled algorithms

| shape | sites |
|---|---|
| O(n²) selection sort by slice+concat | `grammar/lexer.av:698` `sorted_remarks`, `core/types.av:1170` `sorted_distinct_ids`, `diagnostics/source.av:98` `sorted_by_lo_desc` |
| O(n²) insertion sort | `std-http/src/route.av:385` `sorted_distinct` |
| max fold | `core/shape.av:555-580` (three), `compiler/soundness/soundness.av:716` `largest`, `compiler/format/source_text.av:2331` `max_len` |
| `Map<string, bool>` used as a set | 35 declarations |
| `mut best`/`mut m` accumulator loops | 46 |
| `LICENSED loops.push_loop` (an accumulator the idiom bar could not state) | 55 |
| `[... for i in 0..xs.length]` index comprehensions | 51 |
| `[…].is_empty()` / `[…].length` over a comprehension (a count or `any` that builds a list) | 20 / 85 |

### 1.6 The asks (tasks db)

| ticket | ask | wanting site |
|---|---|---|
| `.11.202` | `flatten`, `fold`, `sum`, `max` as std verbs | std-http `guard.av`, `http_compress.av`, `form.av` |
| `.11.190` | `sort_by(key)`, stable | std-http `jar.av` `Jar.sent` (RFC 6265 §5.4) |
| `.11.206` | `Map.remove`, map iteration, a bounded map | std-http `quota.av` `Rate.kept` |
| `.11.63` | `fold`/`scan` | `language/interp.av` `static_val`, `decls_mint.av` `stmts_end` |
| `.11.136` | a first-class fold | lane/tail survey |
| `.11.207` | methods on `List<Operation>` | std-openapi `described()` |
| `.10.22` | `filter_map` (one computed value for filter and element) | `defs_of` |
| `.11.55` | a comprehension over `List<T?>` that drops absence | cli `test.av` `eval_quarrels` |
| `.10.113` | `flatten` reachable from std (std-grammar keeps a copy) | std-ui `realize/lists.av` |
| `.10.133` | `(lo..n).find(p)` that stops early | `backend/interp_bytes.av` |
| `.10.112` | `min`/`max` over ints | the terminal target's line widths (it calls `.max()` now: std-ui `realize/tui/layout.av`) |
| `.10.27` | `for c in s.chars()` | the lexer |
| `.10.56` | slicing a range | — |
| `.10.24` | list spread `[0, ..xs]` | fingerprint arms |
| `.11.105`, `avra-do6w` | int map keys (K1), struct/enum keys (K2) | `source_text.av` trivia tables |
| `.11.211` | `impl Counted for List<T>` | std-validate `length<T: Counted>` |
| `.34.42` | nested comprehension costs 2-3x a push loop for flatten | core `flatten` |
| `.28.1` | `collect … keyed` (compile time) | models |

### 1.7 Refused today (probed at `96fa525`, scratch outside the tree)

| probe | answer |
|---|---|
| `xs.reverse()`, `.sort()`, `.every(…)`, `.fold(…)`, `.sum()` | `type.method` "`.x(…)` calls a method, and `List<int>` has none" |
| `m.keys()`, `m.remove(k)` | `type.method` on `Map<string, int>` |
| `for k in m`, `[k for k in m]` | "`for … in` walks a `List`" / `type.list` |
| `for c in s`, `for c in b` (`string`, `Bytes`) | "`for … in` walks a `List`" |
| `m["a"]` | "`[...]` indexes a `List`" |
| `(0..n).any(it == 2)` | F0100 "expected `)` to close the group" |
| `Map<int, int>` | `type.applied` "a map's keys are strings" |
| `[0, ..xs]` | F0100 "expected `]`" |
| `break`, `continue` | F3000 "is not defined" |
| `trait Seq<T> { … }` | F0100 "expected `{`" |
| `impl W { fn kept<T>(…) }` | `type.impl` "generic methods are recorded, not landed" |
| `impl Show for Box<T>` | `type.impl` "a trait impl over a generic type is recorded" |
| `impl Counted for List<T>` (and `List`, `List<int>`) | **silently ignored**: no error at the impl, F2030 at the call |
| `fn g<T: Counted>(x: T)` called with a `List<int>` | help "write `impl Counted for List<int>`", **a form that is itself ignored** |
| `trait Dup { fn dup() -> Self }` | parses; the impl's `-> P` is refused: `Self` names nothing |
| `xs.filter(it > 1).map(it * 2)`, `xs.map { x -> x * 2 }`, `find_index`, `collect` | compile |

The two ignored-impl rows are a defect (a remedy that names a dead
form); filed with this doc's landing, not fixed by it.

### 1.8 Found while reading: the map hash is a DoS hole

`str_hash` hashes up to the first NUL while equality compares the
header length. So `"k" + nul + anything` all hash as `"k"`: an
attacker who controls keys (a header name, a JSON object, a form field)
forces every insert onto one probe chain, O(n²). FNV-1a is also
unseeded, so collisions can be precomputed without a NUL. Fixing it is
the first slice (§3.10 S0).

### 1.9 Measured baseline (Mac, local, indicative; not a receipt)

3,000,000 ints, 100 turns, user seconds, median of 3. Avra at
`96fa525`, Rust 1.93 `-O -C target-cpu=native`.

| workload | Avra | Rust | ratio |
|---|---|---|---|
| `filter(%3==0).map(*2)` to a list, **method chain** | 1.01 | 0.22 | 4.6x |
| same, **comprehension** | 0.51 | 0.22 | 2.3x |
| count where `%3==0` (Avra `for` loop, Rust `filter().count()`) | 0.40 | 0.10 | 4.0x |
| sum of `filter.map` (Avra comprehension then loop) | 0.55 | 0.11 | 5.0x |

The loop body (`avra emit`): a call to `avra_array_get` and a call to
`avra_int_mod` per element, so LLVM cannot vectorize. The chain pays a
second list and an indirect call per element.

### 1.10 DOGFOODING's collection idioms

| entry | line | says |
|---|---|---|
| List comprehensions for filter/map | `DOGFOODING.md:756` | comprehension over loops |
| The native list vocabulary | `:768` | the row list; "a fold is a loop, and there is no sort" |
| A pure map never mutates | `:857` | push loop → comprehension |
| Map as a built-once index | `:1092` | `get` answers `T?` |
| Comprehension as list copy | `:1124` | `[x for x in xs]` to snapshot |
| `enumerate` for indexed walks | `:1217` | |
| `flatten`/`joined`/`filled`/`some_list` from core | `:1225` | the free helpers |
| rules | `lists/idioms.av` | `last_index`, `bool_comprehension_list`, `bool_comprehension_range` (no rewrite: "a bare range has no `.all`") |
| rules | `loops/idioms.av` | `push_loop`, `branched_push_loop`, index-walk → `enumerate` |

### 1.11 The inconsistencies

| kind | instances |
|---|---|
| two names, one idea | `slice` (List, Bytes) vs `substring` (string) · `join` (method, linear) vs `joined` (free, n log n) · `at(i)` (Bytes) vs `[i]` (List) vs `char_code(i)` (string) · `set(i, v)` (List) vs `set_at(i, v)` (Cell) · `set(k, v)` (Map) vs `put(k, v)` (Cell) · `Cell.set(v)` replaces whole where `List.set` writes a slot |
| two absence spellings | `find`/`first`/`last`/`find_index` answer `T?`; `index_of` answers `-1`; `pop` traps |
| free fn vs method | `flatten`, `reversed`, `distinct`, `sorted_by` are free; `map`, `filter`, `concat` are methods; `flatten` and `distinct` exist twice |
| verb vs participle | methods are verbs (`map`, `concat`), free fns participles (`reversed`, `joined`, `inserted`), with no rule saying which |
| eager vs fused | a comprehension fuses, the same chain as methods builds each step |
| receivers | `for` walks lists only; ranges walk only in heads; a map cannot be walked at all |
| stale comments | `core/lists.av:52` ("`.reverse()` mutates in place and aliases" — no such method); `:105` ("`contains` compares other elements by identity" — it compares by value) |

---

## 2. Prior art

| system | model | best idea | we take | we refuse |
|---|---|---|---|---|
| Rust iterators | lazy adapters, `collect()` | zero-cost fusion; closures monomorphized and inlined; `fuse` | fusion, mono, inlining | `collect::<Vec<_>>()` ceremony; `Iterator` state machines for random-access data |
| Kotlin | eager `List` API + lazy `Sequence` | a small, well-named vocabulary; `sorted`/`sort` split; `filterNotNull`, `groupBy`, `associateBy` | names and scope | two APIs for one idea (eager vs `asSequence()`) |
| Swift | `Sequence`/`Collection` protocols, `.lazy` | protocol tiers: forward-only vs random access; `sorted()`/`sort()` naming | tiers (`Walk`, `Indexed`) | `.lazy` as an opt-in the reader must notice |
| C# LINQ | lazy `IEnumerable` + expression trees | a query IS data: `IQueryable` compiles to SQL | the planner already does this (`lists/plan.av`); chains reach it | deferred execution surprises (re-enumeration) |
| Java Streams | lazy, one-shot, sinks | pipeline = source + stages + terminal sink; parallel by flag | the sink model (§3.7 E1) | boxed primitives, one-shot streams |
| Clojure transducers | reducer transformers | composition with no intermediate collection, independent of source | the pipeline is source-independent | runtime composition; we compose at compile time |
| Haskell fusion | foldr/build rewrite rules | the compiler removes intermediates | fusion by construction, not by rule firing | fragile rules (a missed fusion is silent) |
| Elixir `Enum`/`Stream` | eager Enum + lazy Stream over one protocol | one protocol (`Enumerable`) for lists, maps, ranges | a map walks as entries; a range is a value | two modules for one idea |
| Ruby `Enumerable` | one `each`, ~60 methods | implement ONE method, get the whole vocabulary | `Walk` is one method | method sprawl (`collect`/`map`, `select`/`filter` aliases) |
| Python itertools | lazy building blocks | `chunks`, `windows`, `groupby`, `accumulate` (= `scan`) | the names where they are clearest | free fns over methods |
| F#/Gleam/OCaml `List` | module functions, pipes | total, `Option`-returning lookups (`tryFind`) | every lookup answers `T?` | module-qualified free fns (Avra has methods) |
| Scala collections | rich hierarchy, views, `CanBuildFrom` | "the result keeps the receiver's shape" (`filter` on a `Map` is a `Map`) | shape-keeping for `filter`-like verbs | the type-level machinery that delivers it |
| Julia broadcast | `f.(g.(x))` fused into one loop | syntactic fusion guarantee, SIMD | fusion as a guarantee, not an optimization | — |

**Naming.** Swift and Kotlin: `sort()` mutates, `sorted()` answers.
Kotlin uses the participle exactly where a mutating twin exists
(`sorted`, `reversed`, `shuffled`) and the bare verb where none could
(`map`, `filter`). Avra's habit already is past participles for pure
answers (`reversed`, `joined`, `filled`, `inserted`). The rule adopted
(D6): **a word that reads as a command to change the receiver answers
as its participle; a word that cannot be misread keeps its verb.** So
`map`, `filter`, `concat`, `join`, `take` stay; `sort`, `reverse`,
`insert`, `remove_at` become `sorted`, `reversed`, `inserted`,
`removed_at`.

**One protocol, many methods** (Ruby, Elixir, Swift): the receiver
implements a minimal protocol; the vocabulary is written once over it.
Avra's version is sharper: the vocabulary is compiler rows, so it costs
no dispatch and needs no default methods.

---

## 3. The design

### 3.1 The protocol

Every built-in collection is array-backed, so random access is the
common case, and a counted loop is what LLVM vectorizes. Two tiers:

```avra
/// Forward-only: visit each element in order; answer false to stop.
trait Walk<T> { fn walk(visit: fn(T) -> bool) }

/// Random access: a length and an element at a place. Every Indexed walks.
trait Indexed<T> {
    fn length() -> int
    fn at(i: int) -> T
}
```

| receiver | tier | element | notes |
|---|---|---|---|
| `List<T>` | Indexed | `T` | |
| `Bytes` | Indexed | `int` (an octet) | |
| range `(lo..hi)` | Indexed | `int` | a flat value `{lo, hi}`, no box |
| `Map<K, V>` | Indexed | `Entry<K, V> = { key: K, value: V }` | insertion order |
| `s.bytes()` | Indexed | `int` | zero-copy (REUSE D1) |
| `s.chars()` | Walk | `int` (a code point) | decoded as walked |
| `s.lines()`, `s.split(sep)` | Walk (as a source) | `string` | a `List` when named |
| a user type | whichever it impls | its `T` | stage S3 (§3.10) |

`string` itself is **not** a collection: its elements are ambiguous
(bytes? code points? graphemes?), so the reader names the view
(Rust's choice; Swift's grapheme default costs every walk).

The protocol is internal iteration (a visitor), not a `next()` cursor:
the producer keeps its own loop, so a tree walks by its own recursion,
and the visitor inlines under mono. Early exit is the visitor's `false`,
so no `break` is needed to implement or consume it.

### 3.2 Answer shapes

| verb class | answer |
|---|---|
| shape-keeping (`filter`, `take`, `drop`, `take_while`, `drop_while`, `distinct`, `sorted…`, `reversed`, `slice`, `concat`) | the receiver's type: `List→List`, `Bytes→Bytes`, `Map→Map`; a range or `Walk` source → `List<T>` |
| element-changing (`map`, `filter_map`, `flat_map`, `flatten`, `scan`, `chunks`, `windows`, `enumerate`…) | `List<U>` |
| terminal | a scalar, `T?`, `string`, or `Map` |

Shape-keeping is decided by the rows, so no `Self` type is needed.

### 3.3 The vocabulary

Receivers: **L** List · **B** Bytes · **R** range · **M** Map entries ·
**W** any `Walk`. "All" means every row. Pure unless marked **mut**.

**Transform**

| verb | signature | on | replaces |
|---|---|---|---|
| `map` | `(f: fn(T) -> U) -> List<U>` | all | — |
| `filter` | `(p: fn(T) -> bool) -> shape` | all | — |
| `filter_map` | `(f: fn(T) -> U?) -> List<U>` | all | `.10.22`, `.11.55`, `some_list` |
| `flat_map` | `(f: fn(T) -> W<U>) -> List<U>` | all | nested comprehension |
| `flatten` | `() -> List<U>` when `T` is a `Walk<U>` or `U?` | L | `flatten(…)`, `some_list` |
| `scan` | `(seed: A, f: fn(A, T) -> A) -> List<A>` | all | `.11.63` |
| `enumerate` | head only: `for i, x in xs.enumerate()` | all | unchanged |
| `zip` | head only: `for a, b in xs.zip(ys)` | Indexed | until tuples |
| `chunks` / `windows` | `(n: int) -> List<List<T>>` | L B | index loops |

**Filter and slice**

| verb | signature | on |
|---|---|---|
| `take` / `drop` | `(n: int) -> shape` | all |
| `take_while` / `drop_while` | `(p: fn(T) -> bool) -> shape` | all |
| `slice` | `(lo: int, hi: int) -> shape` | L B R, and `string` (replaces `substring`) |
| `distinct` | `() -> shape` (by `==`, first kept) | all |
| `distinct_by` | `(key: fn(T) -> K) -> shape` | all |

**Search** (every miss is absence)

| verb | signature | on |
|---|---|---|
| `find` / `find_last` | `(p) -> T?` | all / Indexed |
| `find_index` | `(p) -> int?` | Indexed |
| `index_of` | `(v: T, from: int = 0) -> int?` (a sub-run for B and `string`) | L B `string` |
| `contains` | `(v: T) -> bool` | all, `string` |
| `any` / `all` | `(p) -> bool` | all |
| `first` / `last` | `() -> T?` | Indexed |
| `get` | `(i: int) -> T?` (`xs[i]` still traps) | L B |
| `binary_search` | `(v: T) -> int?` (receiver sorted) | L B |

**Aggregate**

| verb | signature | on |
|---|---|---|
| `length` | property, `int` | Indexed (a `Walk` counts with `count()`) |
| `is_empty` | `() -> bool` | all |
| `count` | `(p: fn(T) -> bool) -> int`; `count()` with no fn counts | all |
| `sum` | `() -> T`, `T` is `int` or `float`; empty is `0` | all |
| `min` / `max` | `() -> T?`, `T` ordered | all |
| `min_by` / `max_by` | `(key: fn(T) -> K) -> T?`, first wins a tie | all |
| `fold` | `(seed: A, f: fn(A, T) -> A) -> A` | all |

No `sum_by`, `count_by`, `reduce`, `none`: `xs.map(f).sum()` fuses, so
they would be second spellings (P17). `every` stays unborn: `all`.

**Order** (stable by contract, D8)

| verb | signature | on |
|---|---|---|
| `sorted` | `(descending: bool = false) -> shape`, `T` ordered | L B |
| `sorted_by` | `(key: fn(T) -> K, descending: bool = false) -> shape` | L |
| `sorted_with` | `(before: fn(T, T) -> bool) -> shape` | L |
| `reversed` | `() -> shape` | L B R |

*Ordered* is the `==` law's set, ordered: `int`, `float` (total order,
NaN last), text (byte order), a one-field record of those, a
payload-free enum (by declaration order). Anything else refuses in the
`==` law's words and names `sorted_by`.

**Combine and split**

| verb | signature | on |
|---|---|---|
| `concat` | `(ys: shape) -> shape` | L B, `string` via `+` |
| `inserted` / `removed_at` | `(at: int, x: T)` / `(at: int) -> shape` | L |
| `join` | `(sep: string) -> string` on `List<string>`; on `List<Bytes>` → `Bytes` | L |
| `partition` | `(p) -> Parts<T>`, `Parts<T> = { kept: List<T>, rest: List<T> }` | all |
| `group_by` | `(key: fn(T) -> K) -> Map<K, List<T>>`, keys in first-seen order | all |
| `index_by` | `(key: fn(T) -> K) -> Map<K, T>`, the later element wins | all |

**Write on a `mut` place** (the only in-place verbs; O(1) amortized,
where a pure spelling would copy without reuse)

| verb | on |
|---|---|
| `push(v)`, `pop() -> T?`, `set(i, v)` | L |
| `set(k, v)`, `remove(k) -> V?` | M |

### 3.4 `Map`

| verb | signature |
|---|---|
| `get` | `(k: K) -> V?` |
| `has` | `(k: K) -> bool` |
| `set` **mut** | `(k: K, v: V)` — a new key appends to the order, an old one keeps its place |
| `remove` **mut** | `(k: K) -> V?` — the rest keep their order |
| `length`, `is_empty` | |
| `keys` / `values` / `entries` | `() -> List<K>` / `List<V>` / `List<Entry<K, V>>` |
| `for k, v in m`, `[f(k, v) for k, v in m]` | a paired head, like `enumerate` |
| every walk verb | over `Entry<K, V>`; `filter` answers a `Map` |

Order is **insertion order**, a property of the value. So a map IS an
ordered source, and the CLAUDE.md law "map iteration order never
reaches output" becomes "a map's order is its insertion order"
(owner's call, Q4). Keys: `string` now, `int` next (K1,
`avra-do6w`), records and enums with the derive rung (K2).

### 3.5 Constructors

| form | answers |
|---|---|
| `[a, b]`, `[]`, `[e for x in xs if p]`, `collect { … }` | `List<T>` (unchanged) |
| `List.filled(n, v)` | `List<T>` (replaces `filled`) |
| `(lo..hi)` | a range value; `for`, heads and every Indexed verb take it |
| `{}`, `{"k": v}` | `Map` (unchanged) |
| `xs.group_by(k)`, `xs.index_by(k)` | a `Map` built from a walk |
| `ints.bytes()`, `s.bytes()` | `Bytes` (unchanged) |

A range needs parentheses to take a method: `0..n.any(p)` binds to `n`.

### 3.6 Laziness: a chain is one loop, a name is a list

Adapters are `map`, `filter`, `filter_map`, `flat_map`, `flatten`,
`take`, `drop`, `take_while`, `drop_while`, `enumerate`, `zip`, `scan`,
`distinct`. A run of adapters inside one expression is ONE pipeline.
It materializes only where a `List` is needed:

| where | what happens |
|---|---|
| a terminal (`sum`, `find`, `any`, `fold`, `join`, `min`, `count`, `group_by`…) | the pipeline runs into the sink; no list exists |
| a `let`, a field, an argument, an answer, an index | one list is built, pre-sized when the length is known |
| an order verb (`sorted`, `reversed`) | one buffer, then sorted in place |
| a comprehension's source or a `for` head | the pipeline becomes the loop's own clauses |

**Evaluation order is per element** (D3): each element passes through
the whole chain before the next enters, as in Rust and Java streams.
Written into the spec, it makes fusion correct for every lambda,
including ones that print, with no purity proof. Eager-per-step
(Kotlin's `List`) would need a Reach proof before fusing, so speed would
hang on a fact the reader cannot see.

**Why not a lazy `Sequence` value:** fusion covers every finite chain,
and an infinite or streaming source (a socket, a file's lines) is a
fiber-shaped pull that deserves its own design (Q8). No `.lazy()`, no
`.collect()`: the seat decides the answer, and the typer knows the seat.

`explain` prints the fused pipeline (P7):

```
$ avra explain pipeline src/main.av:14
xs.filter(it > 1).map(it * 2).sum()
  source  xs: List<int>  (Indexed, length known)
  clause  filter  inline lambda
  clause  map     inline lambda
  sink    Sum<int>
  one loop, 0 lists, 0 closure boxes
```

### 3.7 Efficiency

**E1. One pipeline IR, a sink per terminal.** Generalize `comp_reg`
(`lists/lower.av:20`) from "push at the innermost turn" to a sink:

```
Pipeline = { source: Source, clauses: List<Clause>, sink: Sink }
Source   = List | Bytes | Range | MapEntries | Walk(fn)
Clause   = Head | Filter(cond) | Map(f) | FilterMap(f) | FlatMap(f) | Take(n) | Drop(n) | TakeWhile(p) | DropWhile(p) | Scan(seed, f) | Distinct
Sink     = Push(dst) | Count | Sum | Fold(seed, f) | Find | FindIndex | Any | All | MinMax | Join(sep) | GroupBy(k) | IndexBy(k)
```

A comprehension is `Pipeline` with `Push`. A method chain is folded
into the same value at lowering. So one mechanism, and three wins
arrive at once: method chains fuse (2x today, §1.9), the relation
planner (`lists/plan.av`) narrows `rows.filter(it.f == v)` exactly as
it narrows `[r for r in rows if r.f == v]`, and `bool_comprehension_*`
rules retire (a comprehension into `.all` is the same pipeline).
Short-circuit sinks use the walk's existing `early_exit`.

The stage a chain folds by is a TYPING fact, not a column on
`MethodRow`: `check_map`/`check_filter` record `PipeStage` in the
TypeFacts `stages` table (the `alias_copies`/`spreads` pattern —
checking's one answer, lowering's one read) and lowering walks the
chain from its base outward. A `MethodRow` stage column would have
edited ~60 rows across six feature tables for a list-only mechanism.
The base source lowers BEFORE the adapter fns are boxed (source order),
fixing the old arg-before-receiver order at `walks.av:123-124`.

**E2. No closure at a verb seat.** A lambda literal binds its parameter
to the element register and lowers its body in place. A named fn is a
`call_decl` LLVM can inline. Only a fn-typed *value* keeps `CallPtr`.
Today every walk calls through the box (`walks.av:263`).

**E3. The element read is a load.** The loop reads `data` and `len`
once; an index the loop bound proves in range needs no bounds check
and no guard-flag read. Scalar lists then vectorize. The hoist is
sound when the body cannot write the source (a value is copied at a
write, spec 11.5); a body that writes the source's own place keeps the
per-turn read. `%` and `/` by a nonzero constant inline (no
`avra_int_mod` call). Target: the §1.9 count loop within 1.2x of Rust.

**E4. Pre-size.** `map`, `enumerate`, `zip`, `scan`, `sorted` over an
Indexed source know their length: one `avra_array_sized(n)`, no
growth. `filter` sizes to the source's length (words are cheap,
ALLOCATION HERE IS CHEAP) and measures before trimming. `.34.42`
(nested comprehension 2-3x a push loop) is diagnosed under this slice.

**E5. Reuse in place.** Every list cell is one word
(`avra_box.h:52-59`), so a map from `T` to `U` always fits the
source's cells: Perceus's same-size condition holds for every list.
When the source dies at the chain and the runtime finds it unique
(REUSE D3/D4, the `_reusing` twin pattern), the pipeline writes into
the source buffer:

| clause run | in place? | why |
|---|---|---|
| `map`, `filter`, `filter_map`, `take`, `drop`, `*_while`, `distinct` | yes | the write cursor never passes the read cursor |
| `sorted…`, `reversed` | yes | permutes the unique buffer |
| `flat_map`, `flatten`, `concat` | grows in place when the block has room (R1's `sized_grown`) | |

Marks are rewritten per cell (a scalar-to-managed `map` changes the
owned bit). `xs = xs.sorted()` is then an in-place sort, which is why
D6 needs no `sort()`.

**E6. Sort.** Stable by contract. Stability is unobservable for `int`,
`bool` and payload-free enum words (equal ones are identical), so those
take **pdqsort**; text, records and every `sorted_by`/`sorted_with`
take a **stable run-adaptive merge** (driftsort-shaped: run detection,
n/2 scratch). The body is Avra and generic, so mono inlines the key or
comparator (Rust's `sort_by` advantage over C's `qsort`). `sorted_by`
computes a non-trivial key once per element (keys as words beside a
permutation). Text compares by header length and 8-byte words
(`core/text.av:50` already does).

**E7. Map.**

| now | design |
|---|---|
| FNV-1a, unseeded, to the first NUL | a fast keyed hash (rapidhash/wyhash class) over the **header length**, seeded per process |
| worst case O(n) per probe, reachable by an attacker | a probe-length **tripwire**: past a bound, that one map rehashes under SipHash-1-3. Fast in the common case, DoS-bounded in the worst |
| `get` = `has` + `get`: two probes, two hashes | one row answers the slot (or absent); `m.set(k, f(m.get(k)))` fuses to one probe |
| index stores slot numbers | index stores the slot plus 7 hash bits (SwissTable tag), so a miss rarely compares text; group probing with SIMD once `.62.1.3` lands |
| no remove | tombstone the entry, mark the index slot deleted, compact when dead > live (Python 3.6's compact dict, which the current layout already is) |

The seed never reaches output: iteration is insertion order, not hash
order. Tests can pin it (`AVRA_HASH_SEED`).

**E8. Monomorphization.** The rows are generic over `T`; mono gives
typed word reads, inlined keys and comparators, and no `dyn`. R13
(identical mono copies merged) keeps code size flat across element
types that share a word shape.

**E9. What is IR, what is Avra, what is C.**

| verb family | home | why |
|---|---|---|
| every adapter and every terminal | **IR**, lowered by the pipeline | a loop shape; must fuse |
| `sorted…`, `binary_search`, `distinct`, `group_by`, `index_by`, `chunks`, `windows` | **Avra**, a toolchain package the compiler links implicitly (Q6) | an algorithm; mono-specialized, readable, provable (`law`s) |
| array alloc/grow/slice/concat and their `_reusing` twins, map probe/insert | **C rows** today | allocator-facing; move with epic `.62.4` |
| `join`, `split`, Bytes scans | **C rows** today | byte loops; move with `.62.3` (SIMD Avra) |
| the map hash | C now, Avra with `.62.1` | needs the raw fragment and SIMD |

### 3.8 Bench plan

`tools/bench/collections/`, one Avra program and one Rust twin per
workload, same input generated from one seed. Runs on a quiet Sprite,
interleaved, median of 5, `make bench-collections` prints the table.

| id | workload | Rust twin | target |
|---|---|---|---|
| C1 | `xs.filter(p).map(f).sum()`, 10M ints | `iter().filter().map().sum()` | ≤1.2x |
| C2 | `xs.map(f)` to a list, 10M | `iter().map().collect::<Vec<_>>()` | ≤1.3x |
| C3 | same with the source dying (reuse) | `into_iter().map().collect()` (in place) | ≤1.2x, 0 allocations |
| C4 | `flat_map`, 1M × 4 | `flat_map().collect()` | ≤1.5x |
| C5 | `sorted()`, 1M ints: random, sorted, reversed, few-unique | `sort_unstable` | ≤1.3x |
| C6 | `sorted()`, 200k strings | `sort` | ≤1.5x |
| C7 | `sorted_by(it.key)`, 500k records | `sort_by_key` | ≤1.5x |
| C8 | `group_by`, 1M → 1k keys | `HashMap<_, Vec<_>>` entry loop | ≤1.5x |
| C9 | map insert 1M string keys, then 1M hits, 1M misses | `HashMap` (foldhash) | ≤1.5x |
| C10 | map insert 100k **adversarial** keys (shared NUL prefix; FNV collisions) | same | linear: ≤2x C9's per-key cost |
| C11 | `join`, 1M strings | `concat`/`join` | ≤1.2x |
| C12 | `(0..n).find(p)`, early hit | `(0..n).find()` | constant time |

Also held: `make census` counts on `check packages/cli` before and
after each slice (same source, CLAUDE.md), and `AVRA_MEM_STATS` peak.

#### 3.8.1 Baseline

`make bench-collections` at `d249615` (main `755a1fc` plus the
harness), Sprite `avra-comptime` (8 cores, x86_64, load 2.8 after the
runs), rustc 1.90 `-C target-cpu=native`, LTO. Median of 5, Avra and
Rust interleaved; seconds are the timed kernel only, input built
before the clock. Sizes are §3.8's, none reduced.

| id | workload | Avra s | Rust s | ratio | target | verdict |
|---|---|---:|---:|---:|---|---|
| C1 | `filter(p).map(f).sum()`, 10M ints | 0.0879 | 0.0127 | 6.94x | ≤1.2x | over |
| C2 | `map(f)` to a list, 10M ints, source kept | 0.103 | 0.0381 | 2.71x | ≤1.3x | over |
| C3 | `map(f)` to a list, 10M ints, source dying | 0.0747 | 0.00813 | 9.18x | ≤1.2x | over |
| C4 | `flat_map`, 1M ints × 4 | 0.0537 | 0.0144 | 3.74x | ≤1.5x | over |
| C5r | `sorted()`, 1M ints, random | 0.677 | 0.0221 | 30.64x | ≤1.3x | over |
| C5s | `sorted()`, 1M ints, sorted | 0.483 | 0.000856 | 564.17x | ≤1.3x | over |
| C5v | `sorted()`, 1M ints, reversed | 0.479 | 0.00089 | 538.35x | ≤1.3x | over |
| C5u | `sorted()`, 1M ints, 16 values | 0.57 | 0.00467 | 122.03x | ≤1.3x | over |
| C6 | `sorted()`, 200k strings | 0.363 | 0.0368 | 9.86x | ≤1.5x | over |
| C7 | `sorted_by(it.key)`, 500k records | 1.05 | 0.029 | 36.19x | ≤1.5x | over |
| C8 | `group_by`, 1M ints to 1k keys: key to slot | 0.0827 | 0.0482 | 1.71x | ≤1.5x | over |
| C8m | `group_by`, 1M ints to 1k keys: map of lists, `concat` | 2.7 | 0.0482 | 56.07x | ≤1.5x | over |
| C9 | map, 1M inserts + 1M hits + 1M misses | 0.355 | 0.357 | 0.99x | ≤1.5x | met |
| C9i | map, 1M inserts alone | 0.192 | 0.261 | 0.73x | — | reference |
| C10n | map, 100k inserts sharing a NUL prefix | 0.013 | 0.00787 | 1.65x | ≤2x C9i per key | met (0.68x) |
| C10f | map, 100k inserts colliding under FNV-1a | 0.0118 | 0.00878 | 1.35x | ≤2x C9i per key | met (0.62x) |
| C11 | `join`, 1M strings | 0.043 | 0.011 | 3.91x | ≤1.2x | over |
| C12l | `(0..n).find(p)`, early hit, ×10, n = 10M: loop | 3.9e-06 | 4.09e-06 | 0.95x | constant | constant (10M/1M 1.0x) |
| C12c | `(0..n).find(p)`, early hit, ×10, n = 10M: comprehension | 0.856 | 3.94e-06 | 217045x | constant | linear (10M/1M 19.4x) |

What each row spells today (each program's header names its target):

- C1: a comprehension, then a `for` sum. C2/C3: a comprehension; C3's
  source dies at it. C4: a nested comprehension over a list literal.
- C5–C7: core's `sorted_by` (a stable merge sort over `slice`s) with a
  comparator, imported from `@std.avrac.core`; C6 compares with core's
  `text_before`. The Rust twins: `sort_unstable`, `sort`, `sort_by_key`.
  No sort is cheaper on sorted or reversed input today (C5s/C5v).
- C8: the fastest spelling found, a `Map<string, int>` to a slot in a
  `List<List<int>>`; C8m is the obvious one, `m.set(k, (m.get(k) ??
  []).concat([x]))`, which copies every group on every insert. Keys are
  text (`Map<int, …>` is refused). Rust has one spelling, so C8m's Rust
  time is C8's.
- C9: Rust is `foldhash` over borrowed `&str` keys, no pre-size; it
  re-reads key text when the table grows, where Avra's index word
  keeps the hash.
- C10: the keyed hash (#53) makes both adversarial sets ordinary, so
  both run cheaper per key than C9i — a 100k map fits cache better than
  a 1M one. The FNV-1a set (10 four-byte blocks per stage, 5 stages)
  shares its low 18 bits under the old unkeyed hash; the Rust twin
  asserts that.
- C12: a range takes no methods, so the idiom bar's scan is a
  comprehension (C12c), which builds the whole list; C12l is a loop
  with an early `return`.

### 3.9 Migration

Every old spelling becomes a `rule` in `features/lists/idioms.av`
(`lists.<rule>`), with `@fixes` so `avra fix` rewrites the tree, and
the registry entry lands in DOGFOODING at the same time. The helpers are
then deleted (both copies where there are two).

| old | new | sites | rule |
|---|---|---|---|
| `flatten(xs)` | `xs.flatten()` | 278 | `lists.free_flatten` |
| `joined(xs, s)` | `xs.join(s)` | 231 | `lists.free_joined` |
| `.substring(lo, hi)` | `.slice(lo, hi)` | 200 | `lists.substring` |
| `b.at(i)` | `b[i]` | ~172 | `lists.bytes_at` |
| `.index_of(v)` answering `-1` | answers `int?` | 146 | type change; `< 0`/`>= 0` sites refused with a fix |
| `some_list(x)` | `filter_map` / `.flatten()` | 91 | `lists.some_list` |
| `.pop()` answering `T` | answers `T?` | 64 | type change; `!` where proven |
| `distinct(xs)` | `xs.distinct()` | 36 | `lists.free_distinct` |
| `filled(n, v)` | `List.filled(n, v)` | 35 | `lists.free_filled` |
| `Map<string, bool>` as a set | `Set<string>` (if Q5) | 35 | `maps.bool_set` |
| `sorted_texts(xs)` | `xs.sorted()` | 30 | `lists.sorted_texts` |
| `inserted(xs, at, x)` | `xs.inserted(at, x)` | 15 | `lists.free_inserted` |
| `reversed(xs)` | `xs.reversed()` | 12 | `lists.free_reversed` |
| `found_at(ns, n)` | `ns.index_of(n)` | 9 | `lists.found_at` |
| `sorted_by(xs, before)` | `xs.sorted_with(before)` | 6 | `lists.free_sorted_by` |
| `.char_code(i)` | `s.bytes().at(i)` | 147 | `lists.char_code` |
| `codepoints(s)`, `chars(s)` | `s.chars()`, `s.chars().map(from_codepoint)` | — | `lists.codepoints` |
| selection/insertion sorts (§1.5) | `sorted_by` / `distinct().sorted()` | 4 | hand |
| max folds, `sum_of`, `larger`/`smaller` | `max`/`max_by`/`sum`, prelude `min`/`max` | ~8 | hand |
| `[… for i in lo..hi].find/any/all` | `(lo..hi).find/any/all` | — | `lists.bool_comprehension_range` gains its rewrite |
| `[…].length` / `[…].is_empty()` over a comprehension | `count(p)` / `!any(p)` | ~105 | `lists.counted_comprehension` |
| `LICENSED loops.push_loop` accumulators | `flatten`, `flat_map`, `fold`, `scan` | 55 | review each licence |

`Cell`'s `set_at`/`put` stay: a `Cell` is a slot, not a collection
(Q10).

### 3.10 What ships when

| stage | contents | language needs |
|---|---|---|
| **S0** | map hash: seeded, header length, one-probe `get` | none. A security fix; ships alone, first |
| **S1** | the pipeline IR (E1) and inline lambdas (E2); range as a value; the vocabulary rows on L B R and map entries (all but order and the Avra-bodied verbs); `Map.has/remove/keys/values/entries`, paired `for`; `T?` answers; migration rules for the renames | grammar: `(lo..hi)` as a primary |
| **S2** | E3–E5 (read hoist, pre-size, reuse twins); the order family and the Avra-bodied verbs (E6); K1 int keys; `Set` if Q5 | the implicit Avra toolchain package (Q6) |
| **S3** | user types: `impl Walk<T> for Tree<T>` | trait type parameters; trait impls over generic types (F2031); `impl Tr for List<T>` actually landing (`.11.211`) |
| **S4** | streams: pull-based, fiber-backed, infinite sources | its own design (Q8) |

| language need | needed by | status at `96fa525` |
|---|---|---|
| `(lo..hi)` as a value | S1 | F0100; grammar only |
| inline lambda lowering | S1 | compiler-internal |
| seat defaults on method rows (`descending:`) | S2 | fn seats have them; rows need them |
| trait type parameters | S3 | F0100 |
| generic trait impls | S3 | F2031 |
| generic methods | not needed (the vocabulary is rows) | F2031 |
| `Self` | **not needed** (shape-keeping is the rows') | parses, names nothing |
| `break` / `continue` | **not needed** (early exit is IR's; `Walk` answers `bool`) | F3000; `.11.168` stands alone |
| tuples | not needed; `zip`/`enumerate` stay head-only, `partition` answers `Parts<T>` | absent |
| list spread `[0, ..xs]` | not needed; `concat` fuses | F0100; `.10.24` stands alone |

### 3.11 Open questions for the owner

| # | question | recommendation |
|---|---|---|
| Q1 | Is per-element evaluation order the language's semantics for a chain? | **Yes.** Fusion becomes unconditional; the alternative ties speed to a hidden purity proof |
| Q2 | Participles only (`sorted`), no in-place `sort()`? | **Yes.** Reuse makes `xs = xs.sorted()` in place; two spellings of one act is what D1 removes |
| Q3 | Every lookup answers `T?`, breaking `index_of`'s `-1` and `pop`'s trap? | **Yes.** 146 + 64 sites, mechanical; one absence spelling |
| Q4 | Rewrite the law "map iteration order never reaches output" as "a map's order is its insertion order"? | **Yes.** It already is, by construction (`avra_runtime.c:1668`); the law predates the guarantee |
| Q5 | A `Set<T>`? | **Yes**, as a map with no values over the same runtime: 35 `Map<string, bool>` sites spell a value nobody reads |
| Q6 | Where do Avra-written bodies (sort, `group_by`) live? | **An implicit toolchain package** that is the Avra half of the runtime (epic `.62`'s destination), linked like `libavra_runtime.a` and never imported |
| Q7 | Map hash: fast seeded hash with a SipHash tripwire, or SipHash always? | **Tripwire.** Rust's default pays SipHash on every key to guard a case the tripwire bounds |
| Q8 | Lazy/infinite sequences now? | **No.** Their own design over fibers (`Pull` in std-http, `Lines` in std-mcp are the wanting sites) |
| Q9 | `string` not walkable; name the view (`bytes()`, `chars()`)? | **Yes** (Rust's choice); the lexer's `.10.27` ask is `s.chars()` |
| Q10 | Rename `Cell.set_at`/`put` to match `List.set`/`Map.set`? | **No.** `Cell.set` already means "replace whole"; a cell is a slot, not a collection |
| Q11 | `filter`/`map` or new words (`keep`, `where`)? | **Keep them.** Every language an LLM has read uses them (P1) |

## Owner decisions (2026-09-30)

All eleven recommendations accepted: Q1–Q9 and Q11 **yes**, Q10 **no**
(Cell keeps `set_at`/`put`). S0, the map hash fix, starts immediately
(`avra-8sb5.34.49`).

## Strings: one protocol with `docs/2026_06_30_STRINGS_FROM_THE_FUTURE.md`

That doc (old tree, `../forge-crafting-intepreters/docs/`) designed strings
from first principles; this vocabulary adopts it rather than inventing a
parallel one.

| strings doc | here | decision |
|---|---|---|
| `Seq<T>` protocol, "strings aren't special" | `Walk<T>` + `Indexed<T>` | ONE protocol. `Walk<T>` is the source half of `Seq`; `Indexed<T>` is its int-position half; a string's positions are `Cursor`s, not ints, so a string is `Walk` but never `Indexed` |
| `s.chars()`, `s.bytes()`, `s.graphemes()` lenses | Q9: `string` not walkable, name the view | the lens NAMES come from the strings doc — `chars` (Unicode scalars), `bytes`, `graphemes` — each spelled as a CALL; `codes()` is dropped; `graphemes` is avra-8sb5.65.3.15 |
| `Cursor` (opaque byte offset, O(1)) | — | adopted for strings: `find` on a `chars` lens answers `Cursor?`, `s[c..]` is an O(1) slice |
| no bare `s[i]`, no bare `.length` on a string | — | adopted, with the doc's F-code voice naming the three intents |
| typed string patterns (`"{head}{tail}"`) | — | already built (lane strings, `features/dispatch.av`); unchanged |
| `+=` in a loop is amortised append | reuse-in-place | already true for a unique buffer; stated as a guarantee |

Built today: typed string patterns, `Bytes`, `.text()`, and the `s.chars()`
and `s.bytes()` lenses as `Walk` sources. Not built: `Cursor`,
`s.graphemes()`, small-string inline storage. Those land with S2
(`Cursor`, slices as views).

## How it is implemented: traits for the surface, the lowering for speed

- **The surface is two small traits with default methods**, Ruby's
  Enumerable shape: a type implements ONE method (`walk`, or `length` +
  `at`) and inherits every verb as a trait default. User types get the
  whole vocabulary by writing one fn.
- **The speed is not the trait.** The compiler recognises a verb chain on
  any `Walk` source and lowers it to ONE loop: monomorphised, lambdas
  inlined, no intermediate list, reuse-in-place on a dying buffer. The
  trait default is the semantics; the lowering is the fast path, and a
  law (`eval == native`, chain == comprehension) holds them equal.
- Built-ins (`List`, `Bytes`, ranges, map entries, string lenses) get the
  vocabulary from the compiler in S1, and move onto the traits in S3 when
  trait impls over generic types (F2031) land. No user-visible change.
