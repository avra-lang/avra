# batcher lane log (UTC)

- 00:40Z lane started; read db05c-reland notes. Worktree ../avra-db05c (Sprite avra-rb468).
- 00:4xZ DISTURBANCE: detached ../avra-db05c to origin/main (132bc456) while predecessor run (Mac pid 6954, make avra + sound-only + cli) was live on avra-rb468. That run's sync predates the detach, so its result is batch-autobatcher's tree, not main. Ticket 1 not yet proven.
- 00:47Z Sprite still held by pid 6954 (quiet 264s+, nobody following). Asked team-lead before any `work stop`.
- PR states: #647 test SUCCESS, draft, BEHIND. #655 no test check yet. #616 test SUCCESS, BEHIND, must rebase after #657 lands. #633 DIRTY (excluded). #657 BLOCKED.
- 01:01Z ticket 1: main (132bc456) on Sprite avra-rb468, make avra=0, build/avra test packages/cli = 371/371 PASS (log build/batcher-cli.log). Predecessor run 00:55-00:59 on the same source hash e06c9ec0 showed 368/371 (3 sound-check/fmt_light failures); unexplained, not reproduced. Worktree restored to batch-autobatcher.
- 01:36Z ticket 2: batch 10 = PR #666 (DRAFT, not armed, base origin/main 132bc456). Member #647 only. Evidence on composed tree b1edda4a: make avra 0; make cache-attacks exit 0 (11 cancel steps, large, store-index); std-avrac 8735/8735. Excluded: #655 (no test check), #616 (wait for #657 to land), #633 (DIRTY). One Sprite OOM-style restart during the first cache-attacks; re-run was clean.

[items-kept 2026-10-13T01:39:33Z] for batch 10 with #647: #649 (branch refuse-names, 0a: the refusal names writer+reader; green on GitHub at 2b5af3ae, rebased on origin/main now) and #660 (branch narrow-receivers, whole-program passes read the files they survey; green on GitHub except runtime-keep pending at last look). Both independent of each other and of #647.
- 01:40-01:52Z closing check (main 132bc456, fresh make avra, Sprite alone): ./avra test packages/cli = 368/371, failing: 3 cases in sound_check_cache_test.av ("the sound check is part of what a check is kept under"). Control: AVRA_WATCH_HELD=1 ./avra test packages/cli = 371/371; build/avra test packages/cli = 371/371 (earlier). The shim's heavy path execs tools/watch.sh (cap 6000 MB, AVRA_WATCH_HELD, AVRA_BUILD_LOCK=/tmp/avra-build.lock); skipping it restores 371. CI runs build/avra test packages/$p directly (.github/workflows/checks.yml:726), so CI never sees it. Not yet root-caused inside the watchdog; no fix attempted.
02:09Z nodes-self #632 head a757db9a: cache-attacks 373 builds, 129 under a hold, 0 failed (Sprite)
- 02:18Z composed batch (origin/main c48bc794 + seal-held + query-key-bound + db06-step3 + refuse-names, tree f7ad055d): make avra 0; make cache-attacks 0; std-avrac 8732/8732. #649 has no test check yet (refused by plan). #666 (batch #10, #647 only) is superseded; asked lead before closing. Planner numbers next batch 11 while #666 exists. Tool defect: retitle double-prefixes '(lands via batch #N)' when a member was already retitled.

[items-kept 2026-10-13T02:39:34Z] #647 (seal-held) rebased on main 444e00b5 after #658: cache_attacks.sh sections unioned (hc + sl); pushed 0fa7c100. Sprite: sl 17 builds / 6 under a hold / 0 failed; full cache-attacks 393 builds / 135 under a hold / 0 failed.

[decl-lower 2026-10-13T03:06Z] #607 (inst-owner) gi,hc,ur,rb,lm,pk,rp,kr,kv,tw 71 builds/25 under a hold/0 failed; #616 (demand) ch,hc,ur,rb,lm,pk,rp,kr,kv,tw 72/26/0 failed; #651 (spans) rel_loc 11/11, codecs 4/4, hc,ur,rb,lm,pk,rp 47/15/0 failed, cache_attacks.sh identical to main. All rebased on main 444e00b5, force-pushed.

## 2026-10-13T03:13:09Z
- nodes-records: stack on main 444e00b5 (bottom-up): #635 (prepare pending), #637 pin and #650 A GREEN by name (test-equivalent: gate, keepers-a/b/static, seed-check, suites std-avrac + rest, codecs, runtime-keep; cache-attacks SKIPPED by path rule - run by hand on Sprite avra-prof: make cache-attacks exit 0, 11 steps 0 failed). Land order: #635, #637, #650, then #659, #673 (drafts).

## 2026-10-13T03:13:29Z
- GREEN by name (test, gate, suites std-avrac, seed-check, prepare): #637, #650, #659. #635 prepare not reported yet (no checks), #673 prepare pending. cache-attacks by hand on Sprite for the C tree: exit 0.
- 03:18Z batch 10 rebuild: #666 closed (branch batch-10 deleted). main moved c48bc794 -> 444e00b5 (#658). Composed tree 945d9a43 (= main + seal-held + perf-cons4 + db06-step3 + query-key-bound + narrow-receivers): make avra 0, cache-attacks 0, std-avrac 8736/8736, std-relation pending. CI test: #648 SUCCESS, #633 SUCCESS, #655 SUCCESS, #660 SUCCESS, #647 running (head 0fa7c100 re-run after update). Shim cli run = 368/371 (not 371). Retitle fix in ../avra-batch tools/batch.sh (uncommitted), batch_test 56/56.
- 03:20Z retitle fix committed locally on batch-autobatcher as a635f5f9 (NOT pushed: pushing moves #631's head). Batch 9 composed tree 8ebae319 on main e3d6b7c8 (#648 merged) = #630 #609 #631 #634 #644 #668 #653 #655; Sprite run started (cache-attacks + std-avrac).
- 03:50Z batch 9 DRAFT = PR #676 (titled 'batch #8' — tool numbered it 8: batch-8 remote was free, batch-9 branch of closed #657 deleted by me). Members #630 #609 #631 #634 #644 #668 #653 #655. Evidence tree 8ebae319: cache-attacks 0, std-avrac 8739/8739.
- 04:10Z batch 10 DRAFT = PR #683 (tool numbered it batch #9: batch-9 remote free after I deleted the closed #657 branch; #676 is batch #8). Members #633 #660 #649 #632 #647 #672 #607. Evidence tree f43af7c9 (source 23d0aa8a): cache-attacks 0, std-avrac 8737/8737.
- 04:2xZ avra-hbj9 probe (Sprite, origin/main 33c88fb9): sound_check_cache_test's avra_bin() is the SHIM (tree_root()/avra); minimal() env drops AVRA_WATCH_HELD, so each child check enters tools/watch.sh (shim prints 'watch: peak 0 MB'); build/avra direct does not. Yet in isolation two timed checks give 'cache hit' under the shim AND the binary: the watchdog wrapper alone does not flip hit(). The 3 failures need the full-suite context; not reproduced in isolation. No fix.
- 04:4xZ avra-hbj9 (origin/main 33c88fb9): REPRODUCED by directory: ./avra test packages/cli/src/commands/tests = 360/363 (the 3 sound-check cases fail); build/avra test same dir = 363/363; ./avra test <sound file> alone = 3/3. Excluded: a child check under a parent watch.sh with minimal env finishes at once with 'cache hit' (no lock wait); /tmp store dirs are real-clock per-ns (no poisoning). Not isolated; no fix.
- 04:5xZ batch 11 PLAN ONLY on origin/main f495de39 (#671 landed): clean merges 670 651 616 680 635; cache-attacks SKIPPED on 651 680 635 673 (need --attacks-ran or --attacks-na). CONFLICT: 669 (workspace.av), 673 (slots.av, builder.av). MERGED already, drop from batch 11: 637 650 659. #667/#662 not planned (edit-path to say when rebased).
- 05:xxZ lead: #637 #650 #659 are NOT on main (merged into a stacked base after a restack). Batch 11 set when its turn comes, plan only: #670 #651 #616 #680 #687 #635 + the combined nodes PR (nodes-records to write it into this file); #669 #674 #685 when rebased. Build only after batch 10 (#683) has merged. Refuse any member whose baseRefName is not main: check it by hand, since the planner may not.

## 2026-10-13T04:30:44Z
- nodes-records: stack simplified. ONE draft PR #689 (base main, branch nodes-records-C, 5 commits = old #635 + pin + A + B + C; tree 5eccc28e == the tree cache-attacks ran on, exit 0). #635 and #673 closed with pointers; #637/#650/#659 had been auto-closed as merged into base nodes-records-1b (not main) by my tangled restack - content is only in #689. Land #689 only; nothing else of mine is pending. Stacked PRs banned from now on.

[items-kept 2026-10-13T04:43:56Z] #677 (branch guess) ready: rebased on main f495de39; carries #687's commit (dp-fix) until #687 lands, then it drops out at rebase. Sprite: cache-attacks full 394 builds / 135 under a hold / 0 failed (gg incl. gone remembered file + body edit after); avra test packages/std-avrac 8751/8751, 332 programs (12 new guess_test cases). The guess key is the SET OF MOVED PATHS only (digest of sorted paths, no contents); add type+impl to shared.av: first 69 s/4 attempts, a DIFFERENT declaration added next: 22.8 s/1 attempt (rounds 2-4). Please batch it after #687.

[edit-path 2026-10-13T05:18Z] #674 (buckets, branch buckets, base main f495de39, pushed once at 2297a495): Sprite full make cache-attacks 385 builds / 129 under a hold / 1 failed — the one was attack bk's own baseline (fixed in the last commit; bk alone then 7 builds / 0 failed with the asserted counts: moved generic compiles exactly the 19 buckets its instantiations hash to, one new instantiation exactly its bucket, two cold builds key every bucket identically); make idioms 0; fmt --check clean on build.av llvm.av lower.av code_hash.av. std-avrac suite NOT run on my Sprite (left to CI). Measured: build one-edit cli emit 9.7 -> 1.9 s, wall ~41 -> 33.5 s; 5 interleaved COLD builds B=2 vs B=32: link 0.88/0.54/0.39/0.38/2.88 vs 0.35/0.45/0.39/0.37/0.38 s (outliers hit either; no penalty), cold emit 37.5-38.9 vs 32.2-33.0 s; nm -g --defined-only symbol sets of the two binaries identical (16388 each, 0 differing) — nothing dead-stripped differently. #685 (emit-width, branch emit-width, base main at the time of its PR): cold emit 37.4 -> 24.9-28.9 s on 8 cores, peak RSS +0.1 GB; ran kr,tw sections + fmt on my Sprite (it touches only the worker count); not yet rebased onto f495de39 — rebase on request.
- rule: no delete words in Bash command text; move aside with mv. Earlier in this lane I used rm -rf on scratch dirs; none pending now.

[edit-path 06:30Z] #697 (branch linked) + #699 (hit-untouched, base main, shows both commits; land #697 first or together)
- #697: host-fns row is the build's Linked answer (keep_reading/get_valid; deletes links_key/links_text/links_unchanged/tools_key, build.av net -12). Evidence on Sprite: attack lk 12 builds/0 failed, make cache-attacks 390 builds/0 failed, make idioms 0, fmt clean.
- #699: unchanged cli build 0.57-0.73 s -> 0.36-0.50 s (hit no longer re-places/renames the identical binary). lk 14 builds/0 failed (adds inode check), fmt clean.
- 06:4xZ batch 10 DRAFT = PR #701 on main de4b544d: #660 #649 #632 #647 #672 #607 #680 #674. Evidence tree 3b0e5f5f (source ace122a8): cache-attacks 0, std-avrac 8746/8746. Dropped: #633 (DIRTY, test FAILURE), #687 (test FAILURE), #697 (no test). #683 closed (superseded by #701). Retitle fix = #698 draft (pushed once).
- 07:xxZ #687: reran the failed run 38346058338 once (--failed), per lead. Batch 10 (#701) is already built, so #687 goes to batch 11 unless lead says rebuild.
## nodes-self #700 (expansion splice reuse) CLEARED for batch 11 (2026-10-13)
Evidence: collects_test 100/100, annotations_adversarial 83/83, annotations 32/32, expr_gathered 10/10, make cache-attacks 0 failed (clean work run on main+#700). Soundness witness `delegated_package_two_derived` (two parallel derived traits on a cross-file enum): main+#700 cache ON and cache DISABLED fail identically with the stale DeclId (the two-trait bug #632's maker fix repairs); on #700+#632+#587+#652 it passes (0/0 2/2 100/1). So the cache is not the cause. Effect: B cold check std-avrac peak 2071 MB (was >7200), stack-652 tree compiler builds in 268 s.
Witness test + support/twin.av: local commit 8de9cb43 on nodes-self; becomes its own tiny draft PR on main AFTER batch 10 lands.
- 07:xxZ batch 11 (lead msg): on main 98b652a5. Excluded: #700 #689 #685 #688 #633 (test FAILURE or DIRTY), #698 #616 #670 (DIRTY). #699 CONFLICTS with #697 in either order (build.av) — left for batch 12. Set: #697 #687 #695 #651 #686. Composed tree 78e1ffc2 on Sprite: make avra, cache-attacks, std-avrac running.
db06: #633 pushed 51718583 (docs attack 16/16, fmt clean); ready for batch 12.
- #633 check --baseline: reran, exit 0 (read $?), no new sites.
- 08:4xZ batch 11 DRAFT = PR #715 (tool numbered it #10; retitled via REST to 'batch #11', label full-ci added, still draft). Members #697 #687 #695 #651 #686. Evidence tree 78e1ffc2 (source d594d693): make avra 0, cache-attacks 0, std-avrac 8769/8769. Excluded: #699 (conflicts with #697 both orders), #700 #689 #685 #688 #633 (test FAILURE/DIRTY), #698 #616 #670 (DIRTY).
- 08:5xZ re-check (lead): #712 test red only (light false red) → IN, first. #700 (keepers-a), #689 (many keepers/suites), #685 (keepers/gate/suites), #688 (keepers, cache-attacks, suites) have non-light job failures → OUT. Old #715 closed, remote batch-10 deleted. Rebuilding: #712 #697 #687 #695 #651 #686, composed tree 04a94de5 on Sprite.
- 09:0xZ batch 11 build refused: batch tool requires #712 test SUCCESS; #712 test is FAILURE (light). Nothing pushed. Asked lead: label #712 full-ci for a real test verdict, or allow an override.
- 09:2xZ #715 had been closed by me at the batch-11 rebuild; restored head to remote batch-10 (0eae573d), reopened as draft, members retitled 'lands via batch #11'. Batch 12: #712 #633 (#700 #689 #685 #688 excluded: real keepers/suites/cache-attacks failures on current heads). Composed tree 41a89d10 on main 6681fe55 + 712 + 633; Sprite run started; draft with --n 12.
- 09:3xZ batch 12 composed tree 41a89d10 (main 6681fe55 + #712 + #633): make avra 0, cache-attacks 0, std-avrac 8753/8753. Draft blocked: tool refuses #712 and #633 (test FAILURE, light red). Asked lead for full-ci label or override. Excluded #700 #689 #685 #688 (real job failures on current heads).
- 09:5xZ CI facts (head vs run; lead asked):
  #712 head 154ff552: full-ci run 38373573671 SUCCESS (no failed jobs); light run 38368778165 test FAILURE. Planner no longer refuses on test.
  #700 head fb9cb6a3: run 38358511383 FAILED keepers-a, gate, test (current head). Exclude unless a newer run is green.
  #689 head d8a93a5c: run 38339543213 SUCCESS (current head); later run 38346774354 CANCELLED, test FAILED (light-style). Include candidate.
  #685 head 0a5d5e9c: run 38345466900 FAILED keepers-static, test (current head); other jobs cancelled. Real job failure: exclude.
  #688 head 1f85e633: run 38346700217 FAILED test only; the other jobs cancelled. No real-job failure seen; include candidate, no full verdict.
- 10:xxZ CLOSED batch 10 members #660 #649 #632 #647 #672 #607 #680 #674 (verified content on main 98b652a5 by merge-tree/line checks; seal-held/inst-owner/buckets differ only by the '+++' header of cache_attacks.sh). BATCH 11 = PR #715 (draft, full-ci, 5 members #697 #687 #695 #651 #686, head batch-10). BATCH 12 = PR #723 (draft, full-ci, pushed 41a89d10 as batch-12, members #712 #633 retitled 'lands via batch #12'). Override authorised by lead for #712 and #633 test.
CI per candidate, failing job vs the run's head (current head = PR head):
  #700 head fb9cb6a3: run 38358511383 (same head) FAILED keepers-a, gate, test → real failure on current head.
  #689 head d8a93a5c: run 38339543213 (same head) SUCCESS; newer run 38346774354 (same head) CANCELLED, test FAILED.
  #685 head 0a5d5e9c: run 38345466900 (same head) FAILED keepers-static, test → real failure on current head.
  #688 head 1f85e633: run 38346700217 (same head) FAILED test; other jobs CANCELLED.
- 10:4xZ #715 (batch 11) rebase onto main 7f12f428: CONFLICT in tools/cache_attacks.sh (member e179e423, #651 spans, vs main's new sections); a keep-both merge did not parse, so the rebase was aborted and #715 left on 98b652a5 (BEHIND). Needs the spans lane to rebase. Batch 12 = #712 #633 #689 #688 (#700 out: test ABSENT on head 884cce85, run in progress). Old #723 closed, batch-12 branch deleted. Composed tree 891baffa on main 7f12f428; Sprite run started.
- 1x:xxZ (limit reset) #700 full-ci run 38376704932 on head 884cce85: SUCCESS -> green for batch 13. Batch 13 plan (main 0e1126a2): #700 merges clean; #711 (head 9dedfe64) light test FAILURE only; #721 (63c4d413) full run 38375952364 SUCCESS; #716 (2343b5a3) gate+test FAILURE (light); #639 (03602cc3) test FAILURE (light); #681 (0772e21b) CONFLICTS with record.av/workspace.av when placed after the others - drop. #715 not merged yet (blocked, awaiting its last jobs); when it merges: close 697 687 695 651 686 after verifying on main, then gh pr update-branch 727.
- 1x:xxZ batch 11 #715 MERGED main 88ccbdec. Closed #697 #687 #695 #651 #686 (verified content on main). Batch 12 recompose on 88ccbdec: #633 CONFLICTS with main itself (merge-tree) -> DROPPED (name it). Composed #712 #689 #688 = ca0a8edc; Sprite evidence running.
- batch 12 = PR #727 force-pushed to ca0a8edc (main 88ccbdec + #712 #689 #688; #633 dropped). Evidence on ca0a8edc (source 767ccd81): make avra 0, cache-attacks 0, std-avrac 8810/8810. Draft, full-ci. #633 title marked dropped.
- 11:2xZ #727 = batch 12 on main 88ccbdec: #712 #689 #688 #700, composed 4a9296c0, evidence cache-attacks 0, std-avrac 8810/8810. #633 dropped (DIRTY). #681 asked to rebase after #639 (store-tw lane). Batch 13 pending: #721 (author's word), #711 #716 #639 (full runs).
- 11:4xZ batch 13 PLAN ONLY (no build until #710 merged and batch 12 armed). Current-head verdicts from newest completed run per head (main 88ccbdec):
  #711 9dedfe64: run 38384147679 SUCCESS (green).
  #716 2343b5a3: run 38384151394 FAILURE (prepare, test) - red; not in.
  #639 03602cc3: run 38384153589 SUCCESS (green).
  #721 63c4d413: run 38375952364 SUCCESS (green); author owes follow-ups - in only when author says ready.
  #633 51718583: DIRTY vs main - out until db06 pushes db06-633b.
  #685 59fd88fb: no completed run yet (38388036199 in progress) - pending.
  #728 686ceb95: run 38384025840 SUCCESS (green).
  #731 e559c889: no completed run yet (38385026928) - pending.
  #725 09604fec: run 38378684105 SUCCESS (green).
  #726 da65d144: run 38379420575 SUCCESS (green).
  #732 c7629fe6: run 38385375362 SUCCESS (green).
  #735 22feaa3b: no completed run yet (38387391514) - pending.
  #670 e8c5a9a3: no completed run yet (38388076329) - pending.
Stale-run caution: each head has a light SKIPPED run next to its full run; only the SUCCESS/FAILURE run counts.

## 2026-10-13T20:51Z — batch 12 recomposed on current main; batch 13 planned

BATCH 12 = PR #727 (reused, force-pushed). Composed on origin/main b0d98c49 by merging each member
head in order (all clean; no conflict): #712 stub-body 154ff552 -> #689 nodes-records-C d8a93a5c ->
#688 db06-unitkind 1f85e633 -> #700 expand-reentry 884cce85. HEAD d09b4d00, tree object 18a48396.
#633 left out (DIRTY vs main). #727 stays DRAFT, title 'DO NOT MERGE: batch #12: #712 #689 #688 #700',
auto-merge NOT armed (autoMerge=null), body carries `<!-- batch-members: 712 689 688 700 -->`.
All four members retitled 'DO NOT MERGE (lands via batch #12) — <title>' (#700 fixed; #633 retitled
'dropped from batch #12: DIRTY vs main b0d98c49').
Evidence on Sprite avra-rb468 against d09b4d00:
  make avra — exit 0; last line: `avra: build/avra`
  make cache-attacks — exit 0; last line: `cancel cache attack: 11 step(s), 0 failed, 2 file(s) inspected`
  ./avra test packages/std-avrac — exit 0; summary line: `8846/8846 tests passed`
  (std-avrac run needed `--for 30`; the default 900 s bound cut the first attempt.)

BATCH 13 — PLAN ONLY (no build; #710 not merged, batch 12 not armed). All three merge cleanly onto
b0d98c49 in the order given; heads have MOVED since the 11:4xZ plan:
  #711 witness-two-derived e4482cd2 (was 9dedfe64): full run 38462080431 SUCCESS; cache-attacks SKIPPED
       -> GREEN but needs --attacks-ran evidence. Plan tree 7b875de6.
  #639 fn-add-names 03602cc3 (matches): newest full run 38384153589 SUCCESS (cache-attacks SUCCESS too)
       -> GREEN/ready. Plan tree 6199bbe4.
  #721 reentrant-once b22887fe (was 63c4d413): run 38462012520 QUEUED (no verdict on current head);
       prior head 63c4d413 SUCCESS at 38375952364. Author owes follow-ups -> conditional, only when
       the author says ready. Plan tree with it d44d620f, final 6f1a3805; without it final 686e5010.
Order: #711 #639 #721 (final tree 6f1a3805); drop #721 -> #711 #639 (final tree 686e5010).

NEXT STEP: lead arms #727 (draft -> ready -> squash auto-merge) after CHANNELS' #710 merges; then build
batch 13 (Sprite evidence: make avra, cache-attacks, std-avrac) at #711 #639 once #721's author says ready
(or #711 #639 without it).
BLOCKERS: FREEZE — nothing compiler-touching lands until #710 merges (this lane did not arm #727).
#721 has no verdict on its current head and its author owes follow-ups. #711 owes cache-attacks evidence.
#633 still DIRTY vs main. Task's batch-13 heads were stale; current heads reported above.
08:03Z batch-B composed 6583f193 (in #685 #732; out conflicts #639 #661 #681 #748 #677); evidence make avra rc=0, cache-attacks rc=0 0 failed, test-std-avrac rc=0 808s. Next: batch-C evidence on sprite.
08:09Z batch-C recomposed after head moves: IN #749 (a5c4f0ae); OUT conflict #670 #633 #678 #679. Running make avra + cache-attacks + std-avrac on tree a5c4f0ae (~30 min).
08:44Z BOTH BATCH PRs OPEN (draft, autoMerge=null): #784 = batch B (tree 4ee2144e, members #685 #732; out conflict #639 #661 #681 #748 #677); #785 = batch C (tree 616c9976, member #749; out conflict #670 #633 #678 #679 — siblings off main, only first merges). Members retitled. Now running evidence make avra + cache-attacks + std-avrac per tree (~30 min each) on avra-rb468.
09:19Z STOP received: batches superseded by mega-integrate. Corrective cleanup done: draft PRs #784 (batch B) and #785 (batch C) CLOSED, remote branches batch-B/batch-C DELETED, member titles #685 #732 #749 REVERTED (no stale 'lands via batch' pointer). Nothing armed, no member PR closed. Composed trees handed over: B 6583f193 (main daaa335f + #685 #732, all evidence rc=0) and B 4ee2144e (main ab108127 + #685 #732, rc=0); C a5c4f0ae (main daaa335f + #749, rc=0) and C 616c9976 (main ab108127 + #749).
