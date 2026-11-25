# IR gaps: what the program layer's IR lacks or shapes worse than the old path's

Source: the 29 `ir_of` spec cases pinned in tools/gate/std-avrac.names at 98b72e5b (batch41 base).
Old shape = what the spec asserts (it held on the old path). Layer shape = `render_ir(judged(src).lowered())`,
read at 98b72e5b. Cost guess: H = work per call or per element at run time, M = a constant per site or
lost specialization, L = order/placement only, ? = not yet read line by line.

| # | case (spec file:line) | program | old shape | layer shape | cost |
|---|---|---|---|---|---|
| 1 | defers_test:232 a method call on a captured receiver needs no closure box | `mut s = Stmt{..}; defer s.reset()` | deferred call direct: no `avra_array_sized`, no `callptr` | builds a 3-slot closure box (`avra_array_sized` + `addr f.lambda38` + 2 pushes), runs it by `avra_array_get` + `callptr` in BOTH cleanup exits, plus a lifted `f.lambda38` body that re-packs the fields | H: an allocation + indirect call per deferred call |
| 2 | defers_test:189 a deferred call opens a cleanup region where the defer stands | `defer note(1); if x == 0 { return 0 }; x` | 3 `cleanup 0 {` regions, 3 direct `call note(` | 2 cleanup regions; `note` reached through a lifted `f.lambda6` closure (static box), 1 direct call inside the lambda | H: same closure indirection as #1 |
| 3 | str_lit_test:227 a `for` over chars is one loop and mints no list | `for c in "héllo".chars() { n = n + c }` | one loop over the text, no `avra_array_*` | calls `@std/prelude/verbs/string.av.chars` (a 200-line body with 3 loops) that BUILDS a list (`avra_array_push`), then a 4th loop walks it with `avra_array_get` | H: O(n) allocation + a second walk |
| 4 | str_lit_test:235 a comprehension over chars is one loop | `[c + 1 for c in "héllo".chars()].length` | one loop, no `avra_array_get` | same as #3: list minted, then walked | H |
| 5 | str_lit_test:239 a chain over chars is one loop and mints no list | `"héllo".chars().filter(it > 127).count()` | one loop, no array | same as #3 | H |
| 6 | fns_test:722 two distinct settled values lower TWO units | `fn pick(const pattern: string, s: string)`, called with "x","y","x" | 2 units `pick$@…`, one per settled value | ONE body `alone/src/main.av.pick(r0: box text, r1: box text)`; the const seat is an ordinary run-time seat | M: a `const` in the body cannot fold per value (the regex-compiled-once case) |
| 7 | fns_test:743 a generic fn's settled seat specializes like a plain one | `fn first<T>(const x: T, y: T)` ×3 values | 2 units `first$…` | one `first$word/maybe word/0` | M |
| 8 | fns_test:747 two settled seats keep their ORDER | `pair(1, 2) + pair(2, 1)` | 2 units `pair$@…` | one `pair` | M |
| 9 | fns_test:756 forwarded units split PER VALUE | `outer(3) + outer(4)` → `inner(y)` | 2 units `inner$@…` | one `inner`, one `outer` | M |
| 10 | fns_adversarial_test:655 a settled seat keys on THE VALUE alone | `pick("x","1")`, `pick("x","2")` | exactly 1 unit `pick$@…` | no unit at all (plain `pick`) | M |
| 11 | maps_test:137 a value reading its own key hands the write its word | `m.set(k, (m.get(k) ?? 0) + 1)` | `avra_map_slot` then `avra_map_set_at` (the write reuses the read's probe), no `avra_map_set` | `avra_map_slot` + `avra_map_value_at` for the read, then a fresh `avra_map_set(m, k, v)` | H: a second hash + probe per counted write |
| 12 | maps_test:143 a literal key written twice is one key | `m.set("a", (m.get("a") ?? 0) + 1)` | `avra_map_set_at` | `avra_map_set` | H |
| 13 | aftercall_test:32 a compiler unit's call is tested | `state counter: int = 0` / `counter` | ≥1 `flag unwinding` test after the call of the state's own unit | no `flag unwinding` in the entry after `call counter()` | L for speed; a SOUNDNESS question (old comment: "an omission here would let a caller read a hollow") |
| 14 | aftercall_test:38 a task's cold exit answers an EMPTY cell | `let t = spawn { work() }; t.await` over a parking `nap()` | task lambda carries a test and boxes an empty answer on its cold exit | the lone program is NOT MADE on the layer (ir_of falls back) | ? not made |
| 15 | backedge_test:144 a top-level park links the scheduler for a top-level `while` | top-level `while` beside a top-level sleep | 1 `flag tick` + 1 `avra_tick_cold()` in the entry | not 1/1 (count not read) | ? |
| 16 | cancel_reach_test:177 a `defer` beside a call through a value: the cold exit carries no shield | `defer …` + `held((n: int) -> n + 1)` | `flag unwinding` present, no `avra_fiber_shield` | assertion fails (which half not read) | ? |
| 17 | loops_test:87 a for reads its end once | `for i in 0..2 { t = t + i }` | end `int 2` evaluated BEFORE the count cell's slot | the count cell's `slot`/`store` first, then `int 2`; same instructions, `r7 = load r3` / `r8 = load r3` read the cell twice in the body | L (order) — check the double load |
| 18 | lower_test:1008 a filter, a map, then a sum | `xs.filter(..).map(..).sum()` | one loop; `avra_array_len(r0)` before the accumulator's slot | one loop, no list; the accumulator's `int 0`/slot placed before `avra_array_len` | L (order only) |
| 19 | lower_test:1051 a filter then a terminal (`any`) | chain ending on its first hit | one loop | one loop, same order difference | L |
| 20 | lower_test:1101 a filter then a map | pushes once, both fn boxes read before the loop | one loop | one loop, same order difference | L |
| 21 | lower_test:791 each head opens inside the one before it | 4-head comprehension | text match of the nest | not compared line by line | ? |
| 22 | lower_test:424 a value the condition MINTS is released before the test | `while self.tag().length <= at { … }` | release of the minted string inside the loop, before the test | `cond_mint_settled` false | ? possible leak-per-turn or late release |
| 23 | lower_test:431 a LENDING read in a condition borrows | `while self.cells.length <= at { self.cells.push(1) }` | no owned get in `keep` | an owned get (`avra_owned_*`) in `keep` | M: a retain/release per turn; may force a copy before the in-place push |
| 24 | lower_test:737 the cell settles at the scope's end | `mut x: Far? = null; x = Far{..}` | ≥2 cell settles in `hold` | fewer | ? |
| 25 | lower_test:743 a store of null into a managed cell releases what it held | `mut x: Far? = Far{..}; x = null` | ≥2 settles in `drop` | fewer | ? possible leak |
| 26 | lower_test:754 the arm never reaches the read after it, so the borrow costs no retain | early-exit borrow, `skips` | no owned get | owned get present | M: a retain/release |
| 27 | lower_test:761 the change stands between the borrow and its read, so it stays owned | `stays` | owned get present | absent | ? SOUNDNESS: a borrow across a write |
| 28 | lower_test:777 the body's own lowered marks say a seat is consumed | `fn always(p: P) -> List<P> { [p] }` | `consumed_mark(always.marks, 0)` | mark absent on the layer's Body | M: the caller cannot move the argument |
| 29 | fns_test:114 the widths leave pointer seats alone | `extern fn c_open(p: string) -> ptr` / `c_open("x")` | extern row `ptr -> ptr` in `Lowered.externs` | program not made / no row for `c_open` | ? |
| 30–31 | state_cell_test:42/45 a `state` local's slot and its loads wear a cell | `fn d() -> int { state n = 1; let f = () -> { n = n + 1 }; f(); n }` | every `slot` of `d`, and every load from one, is `Cell<int>` | on the layer the slots/loads of `alone/src/main.av.d` are not all `box cell` layouts (or `d` has no slot) — not read line by line | ? |
| 32 | backedge_test:133 an `@unbroken` fn's own `while` carries no check | package: `@unbroken fn rouse() { while i < 3 { … } }`, spawned | no `flag tick` / `avra_tick_cold()` in `rouse` | the layer's `app/src/main.av.rouse` still carries the back-edge check: `@unbroken` is not read when a package's body is lowered | M per turn; and the mark's meaning is lost |
Read first, by cost: #1–#5 and #11–#12 (work per call or per element), then #6–#10 (the `const` seat is not
specialized at all), then #22–#28 (memory placement; #25 and #27 want a soundness read, not only a speed one).
#17–#20 are order only and may be acceptable as the layer's own shape.

How to see any row: `AVRA_SPEC_DIFFERENTIAL=ir build/avra test <spec file>` prints an `=====IRDIFF` block per
`ir_of` source whose IR differs past names (first differing line, both sides).
