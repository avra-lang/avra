# db-store handoff (lane: DB 05 store + query code hash)

Worktree: /Users/tristan/projects/tristanMatthias/avra-db-store (Sprite avra-dev bound). Checked out: db-code-hash-shape.

## Branches / PRs
- PR #429 `db-code-hash` @ 402d89b — DB 05b: `code_hash(f)` + held-file `CodeFacts`. On origin/main e7108bd. Queues on green.
  Verified on Sprite (that tree): attacks 8/8, code_hash_test 19/19, codecs 21/21, cache-attacks 0 failed, gate_changed clean, DIAGNOSTICS matches, warm `check cli` main 0.608 vs mine 0.623 s (noise).
- `db-code-hash-shape` @ b9603a2 (stacked on #429, pushed, NO PR): types hashed by SHAPE (`type_shape`), query key = code_hash(the WRAPPER) so the codec moves it, 3 new code_hash_test cases, the shape condition in code_hash.av's doc.
  NOT verified: a Sprite run was started (attacks, code_hash_test, std-relation suite, gate_changed) and may still be running — `sh tools/work attach` to follow; log was /private/.../9b89a1a9…/scratchpad/s1.log.
- `db-store-05c-drafts` @ 8b66182 (pushed, no PR): tools/store_attacks.sh (DB 05c attacks, fail on main as intended) + tools/db_measure/store_baseline.sh.
- #392 (flock) MERGED. @std/hash (#397, db-hash) reviewed LAND.

## Next steps
1. Read the db-code-hash-shape run; if green and #429 merged: rebase onto origin/main, PR it.
2. 05b-2 C door when #411 (db-inputs-2's d2, `Stamp {path, mark}`, `Read.Tool`) lands: a `Linked` input kind = Stamp of each package object; fold into the hash of CallRt/extern bodies; C-row attack (fixture pkg with own C).
3. DB 05c store format (design §6, PR #396): attacks already drafted.
Follow-ups noted in #429 body: CallPtr fold by fn type once FnAddr types agree.

## Traps learned
- `work run` builds the compiler itself — never add `make avra` (two generations).
- Untracked binaries don't sync to the Sprite: pipe them (`sprite -s avra-dev exec -- sh -c "cat > path" < file`). Main's CI binary: `gh run download <id> -n avra-compiler` from the latest green main push run; put at /home/sprite/avra-main-bin and swap into build/avra for A/B timing.
- Sprite has no /usr/bin/time — use the shell's `time ( … )`.
- Kept records must be digested from `Lowered.unmanaged` (pre-memory), never `lo.fns`.
- `refused_in` counts check-time diagnostics only; a const's settlement refusal shows at run.
- An attack against a store must include an unchanged-rebuild step that must READ BACK, or a non-hashing compiler passes vacuously.
- The local build/avra is older than main; local `check` of std-avrac shows main's new files as errors — trust the Sprite.
- `git add -A tools` swept untracked drafts into a commit once; add named paths.
- A mut fn call inside a lambda copies `self` (type.receiver warning) — use a comprehension/loop.
