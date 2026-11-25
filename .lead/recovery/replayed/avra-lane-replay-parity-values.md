# Replay: parity-values (transcript cse_01QBqJupEEE4E8sXyxX4ypYR)

Bundle: /work/out/avra-lane-replay-parity-values.bundle (prerequisite e2bce925, verified in a clone holding only e2bce925)
- `avra-lane-replay-parity-values` = 2fa7215c (lane tip, on held flip59 60ed14bd)
- `flip-alone` = 4027791d (on land58 d00e7c64, as the lane left it; not re-cut onto 58's final head, the lane never did)

Held, not rebuilt: flip59 60ed14bd already contains fc00aa84, 858b8131, 19fed332, 099cd25c, db39f1f2 and 303acfef (LANES.md listed them as lost).
Nothing was uncommitted at the end of the transcript, so there is no -wip branch.

## Commits
| original | new | subject | verified against |
|---|---|---|---|
| 2ff3a52f | 476661a5 | mark a dependency's collect gathers is read (pre-reorder) | python asserts; fmt counts; witness prints `first,second`, refuses.expected head = transcript |
| 70f3353b | 0478951c | const through a fn value (pre-reorder) | python asserts (line nos 2797/2809 match); fmt "1 written" |
| 5bc44a47 | 7e2596c0 | program layer: a mark a dependency's collect gathers is read, not refused as unread | reorder from 303acfef, tree == 0478951c |
| afc3e0a8 | 51d14e8f | program layer: a const that reaches its program's collect through a fn value is each program's own | same |
| eb92803e | bfefa801 | THE FLIP (re-tip) | same tree |
| beab8bb2 | 54d94de6 | flip-alone: a const each program gathers is settled as its program gathers it | conflicts resolved to 5bac9c7a; tree == 5bac9c7a (as transcript) |
| d92c4d17 | e5fdb888 | flip-alone: a program's gathering asked of every file it reads | same |
| 73657e35 | 7a7d8790 | flip-alone: a gathered const's run gathers as its program does | same |
| 9b97b7fc | 4027791d | flip-alone: THE FLIP | clean pick; land58..tip = 4 commits, 12 files, +214/−54 (= transcript) |
| c064e93d | 8a811d65 | A (pre-reorder) | fmt "5 examined, 4 written"; 7 witnesses after=1/before=0 (= transcript) |
| 1c0633e4 | c3ec1f1e | B (pre-reorder) | sed line 275 = transcript; fmt "1 written"; witness after 1/before 0 |
| bc6f2350 | 5b198cb5 | C (pre-reorder) | fmt "4 examined, 2 written" then "0 written"; item_refused 18+/18− (= transcript); 2 witnesses hold |
| e202a9f6 | 6a61928b | D (pre-reorder) | fmt "0 written"; witness after 1/before 0 |
| 80d06939 | 9c990d8c | E (pre-reorder) | fmt "1 written"; witness after 1/before 0 |
| 3576157f | 1549d95b | A: a type pattern over a `dyn` names one concrete type that implements its trait | reorder onto 51d14e8f, tree == 9c990d8c |
| b8329f82 | f210a82d | B: a `with` that writes a field its record doesn't have is refused | same |
| 49d54716 | c5f76457 | C: a `when`'s arms answer what its `_` arm answers | same |
| 241b9b16 | 508cecad | D: a `for` counter read after its loop is not defined | same |
| 272a5c54 | 41fffae9 | E: a named argument to a fn value is refused | same |
| a7538d78 | 8360de4f | THE FLIP (re-tip) | same |
| 15c27fe0 | 2fa7215c | cost: the new laws read nothing of an item that holds none of their forms | 5 python edits asserted; fmt "6 examined, 3 written" (same 3 files); 18/18 witnesses (= transcript) |

The "fix 0f…" (declares_a_const) that the lane's posts mention was never committed separately. It is the law_findings.av edit (S8WKW8wx), folded into 15c27fe0 as in the transcript.

UNCERTAIN:
- The fixtures under /tmp/netoff were rebuilt from the transcript: lz2 from its heredocs and sed, and the tri/* cases by re-running the lane's ext.py on the same test titles, plus the println it appended to n_impl. They agree with every printed head. The witness main.av files exist in no original sha, so they couldn't be byte-checked.
- refuses.expected/prints.expected were PIN'd with each step's gen-1 compiler, where the lane used gen-2. These are old-path words, and the lane's own checks printed the same results.
- Commit shas differ from the originals (different commit times). The trees follow the transcript.

## Receipts
- Compiler chain: /opt/avra-tc → a73903d2 gen-1 → a73903d2 gen-2 → 6abff86d → target (gen-1, gen-2). No manifest edit.
- Lane tip 2fa7215c: `make avra` twice = 0; 18 witnesses (narrow_*, when_*, with_writes, mark_gathered, gathered_const*, for_counter, fn_value_seats, defer_calls, coalesce_on): 18 of 18 hold.
- flip-alone 4027791d: `make avra` twice = 0; gathered_const witness holds.
- Not run, per the brief: the cost slice, the full gate, and the std-ui undelivered program (/tmp/netoff/r/ud isn't in the transcript).
