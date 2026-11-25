# avra-lane-switch-rehearsal — sweep on trunk 25e8638b

Compiler S10 = an old-path `make try` of 25e8638b (exit 0; 363 s wall / 546 s user / 7.6 GB, against ~231 / 360 s on the
trunks before; the old-path self-build got ~50 % slower). Pool raised to 14 GB; stores cleared after each swap. 48
targets, cold per step. std-avrac's spec suite was skipped on both paths, as asked.

## Totals

- **Lone-file and package build census** (`AVRA_PROGRAM=1 avra build`, laws on), 959 program tests (861 lone-file + 98
  package-shaped): the new path fails 15 that the old path builds = **14 false refusals + 1 link failure**. Zero
  lowering gaps (sweep 7: 34).
- **`--ran`: 987 found / 956 made / 2 failing runs** = 1 name (std-ui `web/tests/mount`, link failure, both engines).
  `wrap_method` and `record_reads` now pass. std-avrac 667 found / 663 made / 0 failing.
- **Test door, spec suites** (`AVRA_PROGRAM=1 avra test <pkg>`):
  - 37 packages PASS, each with the SAME test and program counts as the old path.
  - 2 FAIL, exactly where the old path fails (std-net 6 networking tests; std-program the root-only test).
  - 7 REFUSE: "a suite whose cases reach a body not made yet".
  - The new door is faster and lighter everywhere it runs (std-program 56 s / 0.5 GB vs 152 s / 3.4 GB).
- **Check door** (`check --baseline tools/idioms.baseline`): exit 0 on both paths everywhere EXCEPT std-queue (new
  path 1, the false refusal below). The new-path check now prints the `type.*` warnings too. Finding sets mostly
  agree; std-avrac: 260 shared, 47 old-only, 4 new-only.
- **`--findings` errors:** 0 everywhere except std-queue (4, the same false refusal).
- **Run door** (the two [bin] targets):
  - site: both time out at 120 s (it serves); identical output.
  - ui-board: old exit 2; new exit 1 (link failure, below).

## Ranked root causes, smallest repro each (covered = in next-base af5e6a3c, as you said)

1. **False refusal type.method on a `.check()` of a queue declaration**: 10 std-queue tests, plus the std-queue check
   gate and `--findings`. COVERED (af5e6a3c).
   `AVRA_PROGRAM=1 avra build packages/std-queue/src/tests/flow07_queue_check/flow07_queue_check.av` →
   error[type.method]: `.check(…)` calls a method, and `List<Diagnostic>` has none, at :19:8
   (`"${a.check()[0].message}|…"`). The old path builds it, and `--ran` and the new test door both pass it: only the law
   refuses.
2. **ui host rows missing from the new path's link**: COVERED by W1 (c4888a6b).
   - `AVRA_PROGRAM=1 avra build packages/std-ui/src/web/tests/mount/mount.av` → `ld.lld: error: undefined symbol:
     avra_ui_event` (the only `--ran` failure).
   - `AVRA_PROGRAM=1 avra build tools/ui-board` → `undefined symbol: avra_ui_arm`. ui-board's old LLVM verifier failure
     is gone; the old path still fails ui-board at link.
3. **Four annotation/rule false refusals** (package-shaped tests; "come next"):
   - `compiler/tests/package_rule`: error[type.quote_pat_subj]: a `quote` pattern reads code — this program does not
     load `@std/avrac` (src/main.av:9:25, `export rule plus_zero { quote { ${x} + 0 } -> … }`).
   - `features/asset/tests/hygiene`: error[annotation.receiver]: an annotation's first seat says what it takes —
     `bundled` takes nothing.
   - `features/fns/tests/provided`: error[annotation.callee]: an annotation names a fn over a declaration — `@bundled`
     names no fn.
   - `compiler/tests/query_annotation`: error[resolve.unresolved]: `a_close` is not defined (src/main.av:9:4).
   Repro for each: `AVRA_PROGRAM=1 avra build packages/std-avrac/src/<path>`.
4. **Test door refusals: one unmade body per package** (the 7 suites that don't run yet):
   - cli: "a written receiver a `let` holds, its seed boxed" at commands/tests/dev_test.av `ended_by_signal`
   - std-http: "a call of the generic `declared` whose arguments don't lay out its type parameters" (route_components_test)
   - std-json: "`Binary`" at text_form_test.av case 0
   - std-sql: "a collect field reading a mark into a record other than its `name` and its literal `args`" (parser.av)
   - std-task: "an untyped `MethodCall`" at task.av `any`
   - std-ui: "a generic fn" at forms/model_form.av `model_form.stand`
   - std-validate: "an untyped call through a type" at text_form_test.av `Event.decoded`
   Repro: `AVRA_PROGRAM=1 avra test packages/<pkg>`.
5. **Old-path self-build ~50 % slower on this trunk** (363 s wall vs ~231 s): the old path only, not the switch.

## Table

Peak in GiB from `/usr/bin/time`. "test" = the package's spec suite (`N/M tests passed`), or REFUSED.

| target | build old/new | --ran found/made/failing | test old (pass, wall/peak) | test new (pass, wall/peak) | check old→new exit, wall/peak | check findings | --findings errors | run old/new |
|---|---|---|---|---|---|---|---|---|
| cli | 0/0 | 0/0/0 | 420/438 530s/7.5G | REFUSED 30s/0.9G | 0→0, 226s/8.0G → 249s/3.9G | 192 shared, 12 old-only, 6 new-only | 0 | - |
| site | 0/0 | 0/0/0 | 18/18 16s/0.8G | 18/18 9s/0.5G | 0→0, 10s/0.7G → 28s/0.9G | 3 shared, 0 old-only, 3 new-only | 0 | 124/124/same |
| std-action | 1/1 | 0/0/0 | 127/127 15s/0.7G | 127/127 6s/0.2G | 0→0, 9s/0.6G → 14s/0.5G | 0 shared, 0 old-only, 2 new-only | 0 | - |
| std-assets | 1/1 | 0/0/0 | 19/19 2s/0.2G | 19/19 1s/0.1G | 0→0, 1s/0.2G → 5s/0.2G | 0 shared, 0 old-only, 0 new-only | 0 | - |
| std-cli | 1/1 | 1/1/0 | 43/43 2s/0.2G | 43/43 1s/0.1G | 0→0, 1s/0.2G → 4s/0.2G | 0 shared, 0 old-only, 0 new-only | 0 | - |
| std-compress | 1/1 | 1/1/0 | 33/33 1s/0.2G | 33/33 1s/0.1G | 0→0, 1s/0.2G → 4s/0.2G | 0 shared, 0 old-only, 0 new-only | 0 | - |
| std-convert | 1/1 | 1/1/0 | 3/3 0s/0.1G | 3/3 0s/0.1G | 0→0, 0s/0.1G → 0s/0.1G | 0 shared, 0 old-only, 0 new-only | 0 | - |
| std-crud | 1/1 | 7/7/0 | 2/2 59s/0.8G | 2/2 16s/0.6G | 0→0, 18s/0.9G → 25s/0.7G | 6 shared, 0 old-only, 2 new-only | 0 | - |
| std-db | 1/1 | 9/9/0 | 187/187 35s/1.0G | 187/187 15s/0.5G | 0→0, 20s/1.2G → 15s/0.5G | 6 shared, 0 old-only, 0 new-only | 0 | - |
| std-derive | 1/1 | 0/0/0 | 0 0s/0.1G | 0 0s/0.1G | 0→0, 1s/0.1G → 3s/0.1G | 1 shared, 0 old-only, 0 new-only | 0 | - |
| std-errors | 1/1 | 0/0/0 | 21/21 0s/0.1G | 21/21 0s/0.1G | 0→0, 0s/0.1G → 0s/0.1G | 0 shared, 0 old-only, 0 new-only | 0 | - |
| std-grammar | 1/1 | 0/0/0 | 56/56 3s/0.3G | 56/56 4s/0.2G | 0→0, 4s/0.3G → 7s/0.2G | 9 shared, 0 old-only, 0 new-only | 0 | - |
| std-hash | 1/1 | 1/0/0 | 14/14 1s/0.2G | 14/14 0s/0.1G | 0→0, 0s/0.1G → 0s/0.1G | 0 shared, 0 old-only, 0 new-only | 0 | - |
| std-http-fuzz | 0/0 | 0/0/0 | 0 7s/0.5G | 0 0s/0.1G | 0→0, 7s/0.5G → 13s/0.5G | 0 shared, 0 old-only, 1 new-only | 0 | - |
| std-http-soak | 0/0 | 0/0/0 | 0 6s/0.5G | 0 0s/0.1G | 0→0, 7s/0.5G → 19s/0.5G | 0 shared, 0 old-only, 2 new-only | 0 | - |
| std-http | 1/1 | 56/56/0 | 1364/1365 125s/1.1G | REFUSED 8s/0.4G | 0→0, 26s/1.4G → 31s/0.8G | 18 shared, 0 old-only, 1 new-only | 0 | - |
| std-http_compress | 1/1 | 1/1/0 | 78/78 11s/0.6G | 78/78 3s/0.2G | 0→0, 9s/0.6G → 13s/0.5G | 0 shared, 0 old-only, 1 new-only | 0 | - |
| std-http_message | 1/1 | 0/0/0 | 17/17 5s/0.3G | 17/17 1s/0.1G | 0→0, 4s/0.4G → 9s/0.3G | 3 shared, 0 old-only, 0 new-only | 0 | - |
| std-http_session | 1/1 | 1/1/0 | 22/22 11s/0.6G | 22/22 3s/0.1G | 0→0, 9s/0.6G → 8s/0.3G | 0 shared, 0 old-only, 1 new-only | 0 | - |
| std-https | 1/1 | 7/7/0 | 19/19 22s/0.7G | 19/19 21s/0.5G | 0→0, 11s/0.7G → 22s/0.6G | 4 shared, 0 old-only, 4 new-only | 0 | - |
| std-io | 1/1 | 5/5/0 | 122/122 4s/0.3G | 122/122 3s/0.1G | 0→0, 2s/0.2G → 6s/0.2G | 0 shared, 0 old-only, 0 new-only | 0 | - |
| std-json | 1/1 | 4/3/0 | 183/183 9s/0.4G | REFUSED 4s/0.2G | 0→0, 12s/0.8G → 7s/0.2G | 1 shared, 0 old-only, 0 new-only | 0 | - |
| std-mcp | 1/1 | 0/0/0 | 143/143 13s/0.6G | 143/143 3s/0.2G | 0→0, 11s/0.6G → 16s/0.5G | 0 shared, 0 old-only, 2 new-only | 0 | - |
| std-meta | 1/1 | 3/3/0 | 0 3s/0.2G | 0 0s/0.1G | 0→0, 1s/0.2G → 4s/0.1G | 0 shared, 0 old-only, 0 new-only | 0 | - |
| std-net | 1/1 | 19/19/0 | 84/90 6s/0.4G | 84/90 7s/0.3G | 0→0, 3s/0.3G → 8s/0.3G | 0 shared, 0 old-only, 0 new-only | 0 | - |
| std-openapi | 1/1 | 1/1/0 | 12/12 12s/0.6G | 12/12 5s/0.2G | 0→0, 11s/0.6G → 14s/0.5G | 1 shared, 0 old-only, 2 new-only | 0 | - |
| std-path | 1/1 | 1/1/0 | 31/31 0s/0.2G | 31/31 0s/0.1G | 0→0, 0s/0.2G → 0s/0.1G | 0 shared, 0 old-only, 0 new-only | 0 | - |
| std-prelude | 1/1 | 2/2/0 | 0 0s/0.2G | 0 0s/0.1G | 0→0, 0s/0.1G → 0s/0.1G | 0 shared, 0 old-only, 0 new-only | 0 | - |
| std-process | 1/1 | 4/4/0 | 119/119 41s/0.3G | 119/119 40s/0.1G | 0→0, 4s/0.4G → 10s/0.2G | 4 shared, 0 old-only, 0 new-only | 0 | - |
| std-program | 1/1 | 5/0/0 | 438/439 152s/3.3G | 438/439 56s/0.5G | 0→0, 26s/1.5G → 22s/0.6G | 15 shared, 0 old-only, 0 new-only | 0 | - |
| std-queue | 1/1 | 10/10/0 | 10/10 3s/0.3G | 10/10 2s/0.1G | 0→1, 3s/0.3G → 5s/0.2G | 0 shared, 0 old-only, 1 new-only | 4 | - |
| std-relation | 1/1 | 50/43/0 | 312/312 370s/6.5G | 312/312 62s/0.6G | 0→0, 41s/2.0G → 23s/0.6G | 5 shared, 0 old-only, 0 new-only | 0 | - |
| std-sql | 1/1 | 0/0/0 | 96/96 7s/0.4G | REFUSED 1s/0.1G | 0→0, 5s/0.4G → 9s/0.2G | 10 shared, 0 old-only, 0 new-only | 0 | - |
| std-sqlite | 1/1 | 3/3/0 | 517/517 6s/0.4G | 517/517 3s/0.2G | 0→0, 6s/0.5G → 8s/0.3G | 6 shared, 0 old-only, 0 new-only | 0 | - |
| std-task | 1/1 | 5/5/0 | 11/11 3s/0.3G | REFUSED 1s/0.1G | 0→0, 2s/0.3G → 9s/0.2G | 4 shared, 0 old-only, 0 new-only | 0 | - |
| std-testing | 1/1 | 0/0/0 | 9/9 0s/0.2G | 9/9 0s/0.1G | 0→0, 0s/0.2G → 0s/0.1G | 0 shared, 0 old-only, 0 new-only | 0 | - |
| std-text | 1/1 | 7/4/0 | 208/208 7s/0.4G | 208/208 2s/0.1G | 0→0, 4s/0.4G → 5s/0.2G | 1 shared, 0 old-only, 0 new-only | 0 | - |
| std-time | 1/1 | 19/11/0 | 49/49 18s/0.7G | 49/49 6s/0.1G | 0→0, 2s/0.3G → 5s/0.2G | 0 shared, 0 old-only, 0 new-only | 0 | - |
| std-tls | 1/1 | 5/5/0 | 64/64 5s/0.4G | 64/64 3s/0.2G | 0→0, 3s/0.3G → 9s/0.3G | 0 shared, 0 old-only, 0 new-only | 0 | - |
| std-toml | 1/1 | 0/0/0 | 46/46 2s/0.3G | 46/46 1s/0.1G | 0→0, 1s/0.3G → 5s/0.2G | 2 shared, 0 old-only, 0 new-only | 0 | - |
| std-ui | 1/1 | 78/76/2 | 975/975 169s/3.1G | REFUSED 24s/0.6G | 0→0, 50s/2.4G → 55s/1.3G | 6 shared, 0 old-only, 4 new-only | 0 | - |
| std-ui_gallery | 1/1 | 0/0/0 | 38/38 9s/0.6G | 38/38 10s/0.5G | 0→0, 8s/0.6G → 18s/0.6G | 0 shared, 0 old-only, 2 new-only | 0 | - |
| std-ui_http | 1/1 | 0/0/0 | 17/17 17s/0.8G | 17/17 9s/0.5G | 0→0, 14s/0.9G → 31s/0.9G | 3 shared, 0 old-only, 3 new-only | 0 | - |
| std-url | 1/1 | 1/1/0 | 177/177 2s/0.3G | 177/177 1s/0.1G | 0→0, 2s/0.3G → 5s/0.2G | 0 shared, 0 old-only, 0 new-only | 0 | - |
| std-validate | 1/1 | 6/6/0 | 152/152 10s/0.6G | REFUSED 5s/0.2G | 0→0, 10s/0.7G → 10s/0.3G | 2 shared, 0 old-only, 0 new-only | 0 | - |
| width-witness | 0/0 | 0/0/0 | 0 0s/0.2G | 0 0s/0.1G | 0→0, 0s/0.2G → 0s/0.1G | 0 shared, 0 old-only, 0 new-only | 0 | - |
| ui-board | 1/1 | 0/0/0 | 0 11s/0.8G | 0 0s/0.1G | 0→0, 8s/0.6G → 21s/0.7G | 3 shared, 0 old-only, 1 new-only | 0 | 2/1/differs |
| std-avrac | 1/1 | 667/663/0 | skip  | skip  | 0→0, 328s/10.2G → 278s/4.1G | 260 shared, 47 old-only, 4 new-only | 0 | - |
