# Hold deletion: handoff (2026-10-27, ~06:00 UTC)

Owner order: delete the hold in ONE PR, then the 300 ms edit. Centralize, with no second paths.

## The PR
- **#1371** (draft, full-ci), branch `hold-delete-cut` at **cb3ea83d**. main is bdb14737.
- `make try` builds the branch. The full CI on it is red (triage below).

## Already in the branch
- Rows name a declaration by its key, never an ordinal (hd-keys).
- Removed: the held doors, mint_files/makers, and the fake env savers (hd-delete).
- A compile-time run never executes a revived stub unit (`lowered_in` evicts it).
- An expansion re-run crosses the written decl, not the wrap body.
- A trailing empty `maker` field no longer drops a revived row.
- Visible is saved; an environment digest asks each probe before hashing it.
- Stood files' said is served from FileSaid. **tw edit parses 2 files = main.**
- Only name buckets and world reads join an environment (NameEnv cycle fixed).
- Frame stacks print in defects (`Kernel.open_stack`); a lower defect names its file and expression.
- hd-nohold: a held file is ordinary. Deleted: the held sig/const fills and HeldSig. tw edit exit 0, 4 of 4 runs.

## The blocker
The cli comment edit exits 1 with **3733 language.defect** errors. Cold and unchanged runs exit 0.
- First defect: the generated `identity` over `Stmt`, member **`Defer`** (core/stmt/stmt.av byte 6361, `@stmt_node @apart`), binds a receiver of type `<error>`. Edit run only.
- Ruled out: the collect member set, saved Visible, numeric ids in the wire, cache poison, and revived values (AVRA_VERIFY_REVIVE=1 agrees).
- Leads:
  1. arch-review: `note_producers` has no callers, so held files' re-exports and gathers read EMPTY maps. Deleting those branches is in progress (likely root).
  2. collect-closure ruled out maker ordering: `avra expand stmt.av` is byte-identical cold vs edit (1532 lines), and no `unrun` traces appear. So the generated SOURCE is the same, and the defect is in typing/lowering of re-admitted decls (`Defer`'s type resolving `<error>`).

## Still owed in the PR
- arch-review: `is_held`/`hold_only` (57 sites), held_items/joins/opened/closed, file_ensured/arm_file, the record's ref/gathers/reexport lines, the module record; port 3 tests (cancel_reach, record_held_runs, default_bit).
- store-probe: delete keep_const_units/const_rows_ready/const_unit_key on top of hd-nohold.
- edit-speed: `Consumed` as its own family, out of Sig (`o` flag). Delete typo-path's "answer unread while typing" workaround; a missing row computes via `decl_with_body`, never a default.
- collect-closure: step 2. `Expanded(file, maker)` computed from the pristine parse, with the wrap remap held as data and one minting door.
- Families ceiling: 45 vs 43. Merge NameEnv/SiblingEnv/FileSaid into one per-file family keyed by a TYPED (FileId, kind) key (arch-review, after saved.av settles).
- typo-path: NameEnv read list is 11408 (limit 3000), so group it; census +47–93% (map_claim, leaves_of_edges).

## Branches pushed at pause (not merged into the cut unless noted)
- lower-07f `hd-said` **d5d67fe3**: an absent probe digest is `absent`, not 0. NOT merged. Owed: the row codec carries empty fields explicitly (`read_row` still accepts 13 fields as 14), and the `?? 0` sweep in workspace.av (3 sites).
- edit-speed `consumed` **ee86371c** (on 134b25f8): the Consumed family. **Does NOT build**; the error is unread (Sprite avra-cev probe.log). Owed: rebase; delete the `o` flag, `fn_shape`'s consumed merge, the held branch of `computed_consumed`, and the `typing_open` workaround in `consumed_cell`.
- collect-closure `hd-expanded` **e114603b** (in the cut): Ran/Directed/Unrun enums. It does not change the 3733. Step 2 has no code.
- arch-review `hd-nohold2` **15674131** (on cb3ea83d): `items()` has no held branch; deleted file_ensured/arm_file/ensure_file/held_items/held_joins and some Hold fields. `make try` passes; tw edit not run. NOT merged. **Next:** delete the record-fed held branches (re-exports, gathers, cancel bits). `note_producers` has no callers, so those maps are empty. That is the likely 3733 root. Then is_held/hold_only, the module record, and the 3 tests.
- dry-sweep: `hold-delete-fixes2` 9bd66df0 is in the cut. no_target is a CUT regression: main's compiler passes the kr fixture, while on the cut `entry_file()` returns null even though src/main.av exists.
- int-verbs `cache-port` ab6ae263: on 092d0fc7, the tw edits parse 2 files, 79–80 queries, 1 const. cas_bytes_read budget rows are not added yet.
- parse-speed: its ast probe is UNCOMMITTED in ../avra-parse; the hook refused it because its compiler is stale. Run `sh tools/work main-compiler` then `sh tools/work compiler`, then commit. ast 10.9 s, sublang 2.5 s, parse 13.1 s cold cli.
- store-probe `hd-consts` **1e229225** (on hd-nohold 4fd23582): deletes keep_const_units/const_rows_ready/const_unit_key. Builds; no suites run. NOT merged.
- nodes-finish: `nodes-for` bf1ddfea (the For fold on main 9f75dfe8; builds; loops IR golden and suites not run). `nodes-typelit` 6d3068d2 (`v.type(T)` as a TypeLiteral node; suites unreported). neg not started. The nodes epic doc still owes the statement-door trigger note.
- typo-path: nothing unpushed (the defect-message change is 25fcd389, in the cut). **The blocker MOVED on cb3ea83d** (hd-nohold merged, clean cache): the cli edit's first error is now `SyntaxArena has no method tag_stmt` (type.method), not the Defer nameless receiver. Cold 0, unchanged 0, edit 1. Error count unknown. That is a missing impl method on a revived file: likely a generated `impl SyntaxArena` method (derive) dropped, or the record-fed branches. Start there.
- cores `cores` 251789fc: landed as #1342. The LPT N=2/4/8 numbers are owed.

## CI triage of #1371 (arch-review, run 40430811278)
Causes 1, 2 and 4 are probably fixed since. Open:
- families ceiling;
- read-lists;
- census;
- `manifest.no_target` on the kr/kv fixtures (dry-sweep: `entry_file()` returns null even though src/main.av exists);
- steps.sh (fixed in 9bd66df0).

## Lessons from tonight
- An encoding spends the empty value, repeatedly: a trailing empty field, `hash ?? 0`, a stub with an empty body, mute_lift `[]`. Name the second absence.
- Builder runs over a failing tree POISON the Sprite's `.avra-cache`, giving mint-order and `<error>` defects. `mv .avra-cache` aside before debugging. (This is a real bug, still unfixed.)
- Speed backstop noise: fixed (#1358 phases rows, verdict keyed by SPEED_ACCEPT). Ledgers use `merge=union`.

## Landed today
AY…BN batches. Includes: the seed refresh after the rung, the speed-gate fixes, the pre-commit hook fetching a stale compiler, the cores `par` verb, nodes D/E/J, InstanceBody, the Range bridge, and many UI PRs.

## Lanes (all Sonnet)
typo-path (integrator), arch-review (hold removal), collect-closure (expansion), lower-07f (said/parse), edit-speed (Consumed), store-probe (consts), lander (batches), dry-sweep (tools/CI), int-verbs (gate).
Idle or parked: parse-speed (ast 10.9 s cold), cores (CoW numbers), nodes-finish (For fold after BB, then neg).

## Next
1. Merge arch-review's re-export/gathers deletion into the cut; rerun the cli edit.
2. If it still fails: collect-closure's expand diff on Defer.
3. When the cli edit exits 0: the PR's CI, then the families/read-list/census items, then land.
