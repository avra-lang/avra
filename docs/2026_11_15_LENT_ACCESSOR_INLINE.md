# Inlining tiny lent accessors before the memory pass: a design note

No code. The question: 62 accessor fns of at most 9 lowered instructions (`Arena.node_at` is
`self.nodes[i]`) are called 219 M times per cold cli build and hold 57 M owned-twin retains only because
their answer leaves the callee. Inlined before the memory pass, the answer is an ordinary local
lending read in the caller and the existing local rules decide its count — no ABI, no new L2 rule.

## Measured

- Sizes of the 76 lent-answer fns (every answer a view of one non-consuming, non-`state` seat), in
  lowered instructions: 22 at 5, 1 at 6, 9 at 7, 7 at 8, 23 at 9 — 62 at ≤ 9; 71 at ≤ 13; the rest 15,
  20, 25, 25, 32.
- Twin retains an inline would remove (the inlined read meets the caller's `read_outlives`, the test a
  lending row already gets): 57.09 M at N ≤ 9, and the same 57.09 M at N ≤ 13 and N ≤ 32 — every
  saving one is a ≤ 9 accessor.
- Are they still calls? The program layer emits at `-O0` by default (`AVRA_PROGRAM_OPT`): every call is
  a call. At `-O1`, callgrind of `check packages/std-relation` (one workload, both binaries built by one
  compiler from one source): 51.17 M real calls to the 76 at `-O0`, 38.66 M at `-O1` (to the ≤ 9 ones:
  35.38 M → 22.93 M). LLVM inlines 24 % of them — `TypeRegistry.shape_of` 16.3 M → 5.1 M, `Arena.node_at`
  10.9 M → 10.9 M, `Stack.at`, `Machine.at`, `Workspace.query_db` untouched: callers in another bucket
  or object are invisible to it. Static call sites: 851 at `-O0`, 795 at `-O1`. Whole run: 219.9 G Ir
  at `-O0`, 176.4 G at `-O1`.

## 1. Which fns

The T mark minus the ABI, judged on the lowered body, per mono instance: at most N instructions
(N = 9 covers every saving), no loop and no region, every answer the answer of a view step rooted at
one param through view steps only, no write row and no user call in the body. The seat may be `self`.
Only a DIRECT `.Call` whose callee symbol names that instance is inlined: never a `.CallPtr`, a dyn or
trait dispatch, a spawn or defer body, or a call the lowering cannot name. The inlined body's registers
are renumbered into the caller; its params are the call's arguments; its answer is the call's
destination. The memory pass then sees one more lending read and nothing new.

## 2. Incrementality — the cost

The caller's lowering now READS the callee's lowered body: the callee's body becomes an input of every
caller's lowering and of every caller's bucket key (a key that misses an input links stale code — the
default-rename lesson). Fan-in of the ≤ 9 accessors over the cli build (direct call sites in the
program-layer binary): 51 are called, at 803 sites in 663 caller fns across 157 files.

| accessor | caller fns | files | sites |
| --- | --- | --- | --- |
| TypeRegistry.shape_of | 235 | 70 | 274 |
| Workspace.query_db | 96 | 19 | 139 |
| SyntaxArena.pat | 76 | 19 | 82 |
| Workspace.packages | 53 | 10 | 62 |
| SyntaxArena.annotations_of | 31 | 16 | 35 |
| SyntaxArena.meant | 20 | 12 | 20 |
| QueryEngine.kept_times | 16 | 3 | 31 |
| Lowering.layout_of | 15 | 6 | 15 |

A warm edit of one accessor's BODY today re-lowers that one body and re-emits its bucket. With the
inline it re-lowers every caller and re-emits every bucket holding one: for `shape_of`, 235 bodies in
70 files (counted, not timed). Edits to an
accessor's body are rare (they are one-liners), and an edit that keeps the lowered body identical
re-keys nothing if the key is the lowered body's hash and not its source. That is the condition the
design needs: the inline reads the callee's lowered-body hash, never its span or source text.

## 3. Diagnostics and traps

The inlined instructions keep the callee's spans: an index out of bounds in an inlined `node_at` names
`node_at`'s line in arena.av, as a copied template's spans name their origin file. The caller's frame
is the one a trap's stack shows, so the trap message must carry the callee's span, not the call's.

## 4. The evaluator

Same IR, so the evaluator runs the inlined body too, and its counts match native. Nothing to do there
but run the witnesses in both engines.

## 5. Size and cold-build time

IR growth: 803 sites × (≤ 9 − 1) instructions ≈ +6 k instructions, beside the 62 bodies, which stay
for value use and other callers. Cold-build instructions saved: at `-O1`, about 0.7 calls survive of
each accessor call, so roughly 150 M real calls of the ≤ 9 accessors per cold cli build × ~10–15 Ir of
call overhead ≈ 1.5–2.3 G Ir, plus 57 M retain+release pairs × ~2 × ~10 Ir ≈ 1.1 G Ir — about 3 G Ir,
under 1 % of a cold build. At the default `-O0` the call saving is larger (no call is inlined), about
219 M × ~20 Ir ≈ 4.4 G Ir.

## 6. What LLVM would do for free

Making the program layer's `-O1` see across buckets (ThinLTO, or one module for hot leaves) would inline
all of these calls, and more, with no change to lowering: about the same call saving. But it cannot
remove the 57 M twin retains — the counts were placed before LLVM sees the code, and a retain/release
pair on two sides of an inlined call stays unless the runtime leaves are inlined too and LLVM proves the
box untouched between them. ThinLTO also has the same fan-in cost one level lower: an accessor's edit
re-imports it into every module that inlined it, and the link step re-runs the import, so the warm
edit cost moves from re-lowering to re-codegen. And it only helps once the program layer ships at
`-O1`. The IR inline gets both halves (calls and counts) at `-O0` and `-O1` alike; ThinLTO gets the
calls only, for every small fn, not just accessors. My read: the IR inline is worth it only if the warm
edit fan-in is keyed on the lowered body's hash; ThinLTO is the better first step if the program layer
moves to `-O1` anyway.
