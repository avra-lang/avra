# alloc lane replay (avra-lane-replay-alloc)

Bundle: `/work/out/avra-lane-replay-alloc.bundle`, branch `avra-lane-replay-alloc` = 50ae8c39,
prerequisite e2bce925, `git bundle verify` okay. Source transcript: cse_01QBqJuoCBfR5y7DwgakWdTU.md
(the full copy has no Write/Edit calls in the replayed range, and its Bash commands are identical).

Start: held ref `refs/lanes/alloc/b59` = c2f1532b (the first land58 merge, which did arrive in
all-lanes.bundle). Replayed from the lane's re-merge onto 451aaeb2 (transcript 2026-11-20T16:08:54)
to its last commit (2026-11-21T04:14). No uncommitted work at the end, so there's no `-wip` branch.

The original commits were SSH-signed, so the shas differ. Each replay was checked against the
transcript's printed outputs, and against the lane's printed compiler hashes. Every generation
built here is **bit-identical** to the lane's.

| # | original → new | subject | verified against |
|---|---|---|---|
| 1 | 96024d99 → 30daead1 | Merge branch 'land58' into avra-lane-alloc | clean ort merge; gathering.av grep lines match; gen-2 u2 `3eec1e48928e` = lane's |
| 2 | 55657d11 → d767205b | strided lists: an element is pushed as one write, and a list grows in elements | every edit's printed output; fmt "6 examined, 1 written"; x1 `3ed84e67cbe9`, x2=x3 `492f852332a2` = lane's; rt.av/avra_rt.h regenerated as the lane did; stride_list_test 551/0; staged file list identical (12 files) |
| 3 | 70df2a55 → df2ee864 | strided: a row's name is compared only where the receiver is a map | diff --stat 1 file +1/−1; fmt 0 written |
| 4 | 8bb78f91 → cb39501f | program: the bodies that call an opened name are found by a set of the names | fmt 0 written |
| 5 | 186cd82d → 09f0ac6d | layout: a one-word value enum is spelled with no list made | printed diff identical; y1..y3 `48052fa6f466` = lane's |
| 6 | 07e9bafe → e426517a | strided lists: a join grows its list once, room for its first eight elements | printed grep line numbers (2566/2576/4026); stride_list_test 551/0; runtime diffstat consistent with the lane's (+14/−5, then room_for +2) |
| 7 | c0eab1b6 → b62bcfe7 | layout: a value enum's masks are two words, never a list (the Tagged reshape) | each edit's printed output; fmt "29 examined, 4 written"; **29 files changed, 241 insertions(+), 156 deletions(-)** identical; z `e3d2474f3738` = lane's |
| 8 | ccefaef5 → 2c815ebc | layout: a value enum's registers and absence are laid by its width, with no list made | decls.av lines and fmt "5 examined, 3 written" match; v `71f3d2444acc` = lane's |
| 9 | 6f39f261 → 50ae8c39 | layout: a word's mask is one law, read by the layout and the masks alike | fmt 0 written; idioms check (std-avrac --baseline) rc=0 as the lane's; e `7540f6172555` = lane's |

UNCERTAIN: none. Every replayed edit was a python/sed command with its asserts intact. The
lane's interactive steps were measurements only: cost runs, censuses, the grow-site patch (which
it reverted itself), and the gates.

Skipped (measurement only): yc/c4/fz/fv/fe/grow/grow2 cost and census runs, pkills, the
notes-file edits to /work/avra-lane-alloc.md (outside the repo).

## Receipts (run here)
- Chain per the lead: /opt/avra-tc → a73903d2 ×2 (b56 `ec37005dc759`, then gen-2 `f9f7fcb8ee10`) →
  6abff86d (b57 `58169f137512`) → 30daead1 gen-1/gen-2. No manifest edit. Saved as build/avra.b56,
  .b56g2, .b57.
- Fixpoints: u, x, y, z, v, e (each gen-2 == gen-3, hashes above).
- On the final compiler e2: `make rt-header rt-ns` pass (294 / 291 rows);
  wide_value_enums eval == native == expected; enums_binds_adversarial_test 34/34;
  runtime_counts_test 5/5; features/ctxs 6/6 (6 programs eval == native == expected);
  std-ui placed and placed_rows eval == native == expected; `make runtime-tests` rc=0
  (stride_list_test 551 checks, 0 failed).
- Note: placed_rows first STOPPED on missing build/sqlite3.o in this fresh tree. `make libs`
  fixed it, so the cause was the environment, not the code.
- Not run, per the brief: the cost slice and the full gate.
