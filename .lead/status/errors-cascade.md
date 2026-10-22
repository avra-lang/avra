# errors-cascade status

Last: 2026-10-18

- #920, #928 on main (batch #936). #891 on main.
- DRAFT PR #958 (says-main, off main): 62 of 63 say-only rules carry @says; their no_fix baseline lines pruned. Tree built by the published compiler. voices 139 baselined, DOGFOODING block matches, rule_test 9/9, idioms std-avrac exit 0, keepers-static exit 0. modules.unused_import stays baselined (real Fix.Delete, no lone @fixes example possible) - needs a call.
- DRAFT PR #944 (remedy-rows, base remedy-keeper): no_remedy at zero, now also resolve.not_a_dependency + resolve.package_form rows; retarget to main once #895 lands. (#957 closed, superseded.)
- LESSON: a detached Sprite process is suspended unless an exec session stays attached.

## 2026-10-19
- #1015 (batch C): head ecf1524c, #960 reverted (breaks ui-browser dev loop), sealed-index fix in (bisected, O(log n), second generation ~100 s). On the runners after #1026.
- Local commit 4df1d15c on branch ui-browser-skip: a local ui-browser skip FAILS unless UI_BROWSER_SKIP=<reason>, self-test both surfaces; rides the next tools batch.
- Local branch witness-burn-1 (on batch-c; rebase onto main once #1015 lands): 21 of the 68 no_witness lines burned (9 manifest, 5 resolve, 8 annotation: 4 witnessed, 4 stated Beyond with the suite golden), 6 remedy rows, baseline 137 -> 109, docs regenerated. Left: resolve.reexport_cycle plus the type.*, flow, const, parse/build/language/block lines.
- witness-burn-1 (local, on batch-c; rebase onto main after #1015): no_witness burned to zero — baseline 137 -> 64 (63 no_fix pending #958, build.failed no_help). 62 kinds witnessed or stated, 2 dead kinds removed (type.list_empty, flow.source_loop), 17 remedy rows, `.Block` refusals gained a help. Const-floor trap fix is its own commit 23ebf10d (branch const-floor) for batch E.
