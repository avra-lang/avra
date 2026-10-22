# UI lead handover — 2026-10-20 ~05:25 UTC

I lead UI epic **avra-8sb5.59**. My only peer is **"DB compiler 16 oct"**. The DB lead lands the batches. I relay PRs to them when they're ready. My lanes are teammates in this session. Run `ListAgents` to see them.

## Standing rules

- No `rm`/`rmdir`/`unlink` in Bash; a hook enforces it. Use `find -delete`, `git worktree remove` or `mv`.
- Never commit in the main checkout. Commit with `git -C <worktree>` only.
- Rebase onto `origin/main` only, never onto another unlanded branch.
- Heavy runs go on Sprites only. No whole suites on Sprites; GitHub CI runs them. The Mac disk is nearly full.
- PRs stay draft. Only the lead lands, through the DB lead's batches.
- Ask before changing `rt_sigs` or `core/ir.av`. Keep out of the DB-07 files without the DB lead's OK.
- Move `.avra-cache` aside before any run whose result is being compared.
- Never pkill by pattern. Never `git stash` in shared worktrees.
- Stay quiet unless there's a merge, a decision, a blocker or a failure. Reply "-" to routine notices.
- Wake any lane idle for 15 minutes or more with its next step. Never park a lane.
- Owner bar: no compromises. Find the real fix, not a workaround.

## Lanes and what they're doing

| Lane | Current work | Next |
|---|---|---|
| **ui-crash** | Text slice 1, line breaker, 1/60-px "fine" as the ONE unit; branch text-oracle-3 @ 5bbd73c1, worktree avra-text-4, Sprite avra-rb524. Proportional oracle in Firefox went 42/65 → 102/106; c099b5cd rounds per glyph (fits Gecko). | Run the oracle in WebKit too, reusing #1083's driver. Agreement = within one solver unit (a named tolerance); keep the rounding that fits both engines, or bring me numbers. Pin the two 114.5px cases. Then the wrong-breaker red run (scratch tree avra-text-5), then the PR. |
| **ui-loop** | Pipeline. #1131, defects timings, has `full-ci` on and a full run going (empty commit 8feb4445). | Quote the five slowest and the timings row count, remove `full-ci`, send me the head. After #1125 lands: the live label check on a real PR. |
| **ui-chores** | #1114 Duration bridge (`fn ms()` + within builder MethodCall + printer `span_written` unwraps MethodCall), tip afd5865e, CI rerunning. | Once green and ready → relay to the DB lead; a seed refresh is needed. Then #1106 (Duration `{ns}` @sealed, `.ms()` floors, exact `Time.minus`, `.refuses` range traps; ~45 readers converted by type; sugar ask avra-8sb5.10.182). PLUS in #1106: the `within` node keeps its limit AS WRITTEN with a `Duration` seat, lowering converts, the printer's unwrap is deleted, and an fmt round-trip witness. `now()` wall-ns is a package-C extern, so no ladder. |
| **ui-assets** | #1103 router composition, tip 6203b35b (`mounted(routes)`), bootstrapped green. #1117 specificity routing, stacked draft on #1103. Migrations step 4b (pure diff) on #1102. | #1117 TODO: typed-hole ranking (literal > narrow type > string > rest; equal → refused; partial overlap → `.Overlap`; disjoint coexist; pin all four). Replace the 7 `up` test bridges (take `ServeError` directly, or one helper in tests/support). File a ticket for an `Instance` meta shape (compile-time route validation). Rebase #1117 onto main after #1103 lands. |
| **ui-escape** | #1123 dialog outside-tap (tip af7ad76e): host fills in `closedby` + stops the click of the closing press (the real WebKit iPhone bug). | Witness the Escape claim failing (over-eager stop in scratch). Then ticket **.44.18** About "Script error.": reproduce via `avra dev --target wasm tools/ui-board --host 0.0.0.0` on a LAN address in WebKit iPhone; make scripts same-origin/`crossorigin` so `told()` shows the real stack; fix it. When batch O lands: **rebase #1096** onto origin/main and resolve `drawn_through` (#1086's body + `by_order`). Keep main's single `component_parts_of`, then `grep -c` it = 1. Run components_row_test + tests/unkeyed_owner, then send me the head. |

## PRs, state

**Relayed to the DB lead (ready for a batch):**
- #1094 trap-cleanup emit pairs + prepass. Callgrind vs main: ui-board +2.37%, cli −0.20%.
- #1083 webkit-leg. Full run 39370312669 green, 51 claims in Firefox and in WebKit.
- #1089 at d4e83c39: one `Decls.component_parts_of` accessor; cache-attacks-a 488/0 failed.
- #1070 at 183672c0: `picture_of` in the nodes.av helper. It had been dropped from batch O; the fix is in.
- #1125 at 352cdf0f, label replan. #1130 at 40d07919, Sprite provision hash. Light gate only.

**Not ready yet:**
- #1096 waits on batch O, then the rebase above.
- #1114 waits on green CI, then a seed refresh.
- #1106 waits on #1114.
- #1117 waits on its fixes and on #1103.
- #1123 waits on #1083 landing, then gets a WebKit keeper.
- #1131 waits on its full run.
- Data chain #1078 → #1088 → #1099 → #1102 (ORM, relations, migrations), plus #1081, #1086 (batch O), #1103.

## Tickets filed with the DB lead (theirs to fix)

- **.57.298**: a stale held DeclId after a rename (card.av's resolve reused under `under_hold`). Owner: sched-orders.
- **.57.296**: a flat-record defect from a NULLABLE link to a one-field model (`x: P?`). Repro sent; on #1102 b4300cd9. Owner: seed-run.
- **.57.297**: owner seed-run. **.59.44.19**: owner nodes-step3b. **ambient**: owner nodes-nfield; it must be the same mechanism as the UI's. **.59.44.20**: owner expand-design.
- **.59.44.21** Partial/Pick/Omit waits on the owner.

## Owner decisions on the data/HTTP/forms design (Claude Docs doc, project 0268a35b-…)

Router = a library component (`Routes` trait); specificity matching; `impl` + Query; policies as a library Query DSL, not compiler; `guard`/`ambient` for per-request context (not `state`); observation/caching delayed (ticket .59.27.6); type projections are ticket .59.44.21; migrations a–f all accepted. **TODO:** fold these answers into the design doc.

## Open owner items

- .44.18 About "Script error." (ui-escape is next on it).
- The `/tasks` sync 404: needs a real route via the data design.
- The main checkout's compiler needs rebuilding so `~/projects/tristanMatthias/wasm-opt-safe.sh` is no longer needed (#1066 has merged).

## Lessons from this session

- A label added after a push used to plan light. Fixed by #1125; until it lands, add the label BEFORE pushing, or push an empty commit after.
- A builder that generates a read of a std type's field is a ladder, and the formatter must not reverse-engineer a desugar.
- An oracle or keeper that examined nothing must fail. Wall-time noise (±7%) can't judge a 3% bar, so use callgrind or census counts.
- An oracle tuned to one browser is overfitting. Test against at least two engines.

## Update 2026-10-22 05:55 UTC
LANDED via batches O/P/Q (543526b6, b1e59ff3, 846e8a84): #1070 #1078 #1081 #1086 #1088 #1089 #1096 #1099 #1102 #1103 #1123.
OPEN: #1083 (green at dbb8cefe, relayed; it was reverted out of batch N for npm, now fixed), #1094, #1106 (now carries the bridge plus a seed; supersedes #1114 once green), #1114, #1117, #1125, #1130, #1131 (store warm-up running), #1138 (stacked on #1083), #1179, #1180.
New PRs from ui-chores: #1179 (census sites artifact), #1180 (workflow YAML keeper). New ticket for the DB lead: a cache serves only its own directory (copied store is cold).
