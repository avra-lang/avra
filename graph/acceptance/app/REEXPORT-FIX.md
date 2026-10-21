# Public re-export lint fix

Task `avra-8sb5.25.74`, implemented in this branch, not yet landed on main.
This supersedes M01-HANDOFF.md's unresolved lint note, not its historical
commands or outputs. The commit adding this receipt is the fix head.

`features/code.av` now treats an exported `use` as public reachability,
independently of any particular consumer's local callers. Private unused
imports are still diagnosed. The four focused compiler regression cases
cover plain, aliased and multiple exports, plus that private counterexample.
No graph API export was removed; no baseline was added or changed.

Verified on this worktree's assigned Sprite `avra-ux2`, using a compiler
rebuilt from its synchronized source (compiler source hash
`b069995aecb31b032f8177d5575500559fc47abf92b202b6d6ea28d3288cd86a`,
binary prefix `463341efb725`):

```sh
sh tools/work run sh -c './build/avra test packages/std-avrac/src/compiler/tests/reexport_unused_test.av && ./build/avra check --baseline tools/idioms.baseline graph/acceptance/app && ./build/avra check --baseline tools/idioms.baseline graph/tests/unrelated && ./build/avra check --baseline tools/idioms.baseline graph/acceptance/app && ./build/avra check --baseline tools/idioms.baseline graph/tests/unrelated'
# exit 0; 4/4 regression cases; both consumers pass first and warm checks
tasks --db /Users/tristan/projects/tristanMatthias/avra/.tasks/avra.db verify --yes avra-8sb5.25.74
# gate g1 reran the same remote command: 1 verified, 0 failed, 0 skipped
```

Before the source fix, the same remote regression ran 1/4: all three public
cases failed, private import diagnosis passed. Two earlier local runs hit
the 3500 MB watchdog; those are resource failures, not red semantic tests.
The remote successful CLI gate completed in 95 seconds and reported at
least 6290 MB available throughout. No desktop memory cap was raised.

At this fix's verification the desktop standing `./build/avra` had not been
replaced. It has since been rebuilt with this fix and the annotation fixes;
[the P01 receipt](../../P01-HANDOFF.md) records native consumer verification.
The earlier passing receipt above deliberately identifies its own compiler.
