# UI archive index

Every UI branch, worktree and stash snapshot from before 2026-10-17 lives
on origin under `archive/ui/*`. Each ref was verified equal to its source.
Nothing else UI-related stands locally except `eqstruct` (PR #811) and
`flow-06-dev` (CHANNELS').

The table is generated, not kept by hand. Regenerate it from the repo with:

```sh
git fetch origin
git for-each-ref --sort=refname --format='%(refname:lstrip=3)|%(objectname:short)|%(contents:subject)' refs/remotes/origin/archive/ui/ \
  | awk -F'|' '{ s=$3; gsub(/\|/,"/",s); printf "| `%s` | `%s` | %s |\n", $1, $2, s }'
```

Restore one with `git -C <worktree> checkout origin/archive/ui/<name> -- <paths>`
after `sh tools/work new <name>`. Names: a local branch `b` becomes
`archive/ui/<b with / as ->`; uncommitted worktree state becomes
`archive/ui/<b>-wip`; an origin branch `r` becomes `archive/ui/origin-<r>`.

| Ref | Tip | Last commit subject |
|---|---|---|
| `archive/ui/eqstruct` | `3a2a8390` | eqstruct: structural == design + held prototype (DO NOT MERGE) |
| `archive/ui/flow-06-dev` | `fd6df4ea` | flow 06 S5+S6: class @std/task's signals and @std/time's quiet, regenerate the witness index |
| `archive/ui/flow-06-dev-premerge` | `07d98228` | Merge origin/flow-06-rung2: a signal a task parks on (FLOW 06 S1) into the select base |
| `archive/ui/lane-ui-core` | `3cbebda8` | docs(ui): Phase 0b redone with the owner — LIBRARIES.md (eleven rules), the component is the node, mirrored realizers, three compiler changes first |
| `archive/ui/lane-ui-h` | `792a2601` | chore(land): the ratchet baseline moved for lane/ui's landing |
| `archive/ui/lane-ui-h-wip` | `b6da83a9` | archive: uncommitted state of worktree avra-ui-h (lane/ui-h), 23 paths, 2026-10-17 |
| `archive/ui/lane-ui-i` | `57656789` | runtime: compiles for wasm32-wasip1 — make wasm32 |
| `archive/ui/lane-ui-i-wip` | `d3ace97f` | archive: uncommitted state of worktree avra-ui-i (lane/ui-i), 18 paths, 2026-10-17 |
| `archive/ui/lane-ui-site` | `04527875` | test(site): adversarial suite — near-miss targets, foreign methods, the 404's shape; refactor(site): one table of screens drives the routes and the navigation, a Screen carries its status, a Belief shows itself, one fixture file |
| `archive/ui/origin-closeout-avra-ui-bisect` | `81bd9284` | feat(lang): find_map on List and payload-binding `is` under an if (avra-8sb5.10) |
| `archive/ui/origin-closeout-avra-ui-declared` | `a65ae37b` | fix(avrac): a Declared-answering @derive emits the impls it made |
| `archive/ui/origin-closeout-avra-ui-findis` | `d2278991` | feat(lang): find_map on List and payload-binding `is` under an if (avra-8sb5.10) |
| `archive/ui/origin-closeout-avra-ui-l2b` | `7b89116a` | fix(ui): the L2 fields map to their attributes |
| `archive/ui/origin-closeout-avra-ui-render2` | `ab255cac` | feat(ui): the data-driven render — a component projects to a neutral Node, targets are tables |
| `archive/ui/origin-closeout-avra-ui-tree` | `2e57035d` | wip(closeout): secure lane state |
| `archive/ui/origin-recover-stash-ui-fieldstate--191` | `2a26f1ae` | index on ui-fieldstate: 3881dda wasm32: the gate runs the target's proof (#218) |
| `archive/ui/origin-recover-stash-ui-fieldstate--199` | `bc329d3b` | untracked files on ui-fieldstate: 3881dda wasm32: the gate runs the target's proof (#218) |
| `archive/ui/origin-recover-stash-ui-m1--29` | `fb348002` | WIP on ui-m1: edc5be5 Merge branch 'wasm32' into ui-m1 |
| `archive/ui/origin-recover-stash-ui-m1--293` | `63b579ea` | index on ui-m1: edc5be5 Merge branch 'wasm32' into ui-m1 |
| `archive/ui/origin-recover-stash-ui-m1--312` | `b5d39d6f` | WIP on ui-m1: 5373a86 Merge branch 'ui-dom' into ui-m1 |
| `archive/ui/origin-recover-stash-ui-m1--575` | `b0a067cb` | index on ui-m1: 5373a86 Merge branch 'ui-dom' into ui-m1 |
| `archive/ui/origin-recover-stash-ui-msg--415` | `528886d2` | untracked files on ui-msg: eb32f18 feat(providers): the reader is `env T`, and both words are soft keywords (#235) |
| `archive/ui/origin-recover-stash-ui-msg--78` | `65809088` | index on ui-msg: eb32f18 feat(providers): the reader is `env T`, and both words are soft keywords (#235) |
| `archive/ui/origin-recover-stash-ui-state--178` | `fe18312b` | WIP on ui-state: 6fadf19 fix(sp): exclude the persistent-disk-fault Sprite from the pool (#199) |
| `archive/ui/origin-recover-stash-ui-state--533` | `4357275c` | untracked files on ui-state: 6fadf19 fix(sp): exclude the persistent-disk-fault Sprite from the pool (#199) |
| `archive/ui/origin-recover-stash-ui-state--92` | `309ca439` | index on ui-state: 6fadf19 fix(sp): exclude the persistent-disk-fault Sprite from the pool (#199) |
| `archive/ui/origin-ui-l2b` | `7b89116a` | fix(ui): the L2 fields map to their attributes |
| `archive/ui/origin-ui-lib` | `66c41a6d` | feat(ui): Style and Theme as data — the look, and what its tokens mean |
| `archive/ui/origin-ui-runstream` | `685e539d` | fix(runtime): a printed line is on its stream when the call returns |
| `archive/ui/origin-ui-splice` | `3330e52d` | feat(meta): list_of builds a list literal of any length from List<Code> |
| `archive/ui/origin-wasm-flat` | `2e448a94` | perf(wasm32): flat child rows in a settled static |
| `archive/ui/os-watch` | `4219ee5f` | refactor(io): the watch is a module of its own — a wasm program that reads a file carries none of it |
| `archive/ui/os-watch-dev` | `a911e309` | feat(cli): `avra dev` is woken by the host's file events — `--interval` is the clock asked for outright, and the fallback where a host gives no watch |
| `archive/ui/os-watch-dev2` | `7a3b7080` | feat(cli): `avra dev` is woken by the host's file events — `--interval` is the clock asked for outright, and the fallback where a host gives no watch |
| `archive/ui/ui-a11y` | `51faf8ae` | feat(ui): the accessible-name contract as data |
| `archive/ui/ui-assets-design` | `0b5bd646` | docs(ui): assets — one word over a file or a folder, homes, fetched art, fonts in two engines (avra-8sb5.59.44.11) |
| `archive/ui/ui-bisect` | `0e67451c` | feat(db): the family collect orders by rank, append-stable (avra-8sb5.57.148) (#171) |
| `archive/ui/ui-charter` | `6daa7fe9` | docs(ui): the charter's flexibility — a fixed substrate and an open surface |
| `archive/ui/ui-charter-flex` | `38189dcf` | docs(ui): the charter's flexibility — a fixed substrate and an open surface |
| `archive/ui/ui-dev` | `895027e3` | docs(std-net): `bound`'s contract stands on `bound` |
| `archive/ui/ui-diff-fuzz` | `16003a2e` | build(ui): ui-host-test and ui-fuzz name what their native program links |
| `archive/ui/ui-docs-web` | `63319e6e` | docs(ui): track WEB_UI.md, the web constitution the plan references |
| `archive/ui/ui-dom` | `d71eacb5` | fix(ui): Live.diff remembers the BARE tree, so no_change can fire |
| `archive/ui/ui-emit` | `4db05453` | fix(ui): a Hoist or Direct site must be closed, not merely read no state |
| `archive/ui/ui-host-owned` | `8bfef25d` | test(ui-board): the carried control's name is its own in the browser script |
| `archive/ui/ui-l0` | `01cca998` | feat(ui): layout, appearance, the shared Box, and the inherited environment |
| `archive/ui/ui-l0b` | `33cba303` | feat(ui): the describe target — the semantic trace |
| `archive/ui/ui-l0c` | `ba0c05a9` | feat(ui): layout and appearance reach the HTML target |
| `archive/ui/ui-l1` | `41f7d17d` | feat(ui): layout and appearance reach the HTML target |
| `archive/ui/ui-lib` | `66c41a6d` | feat(ui): Style and Theme as data — the look, and what its tokens mean |
| `archive/ui/ui-own-state` | `6c9add31` | Merge remote-tracking branch 'origin/main' into ui-own-state |
| `archive/ui/ui-primargs` | `d6b32221` | feat(annotations): a bare variant argument sees its seat's type, and is captured |
| `archive/ui/ui-render2` | `760553e6` | feat(lang): find_map on List and payload-binding `is` under an if (avra-8sb5.10) (#181) |
| `archive/ui/ui-runstream` | `685e539d` | fix(runtime): a printed line is on its stream when the call returns |
| `archive/ui/ui-splice` | `3330e52d` | feat(meta): list_of builds a list literal of any length from List<Code> |
| `archive/ui/ui-state` | `deec663b` | feat(state): a capture reads and writes the place, transparently |
| `archive/ui/ui-testdiff` | `75d5a991` | refactor(specs): the case-failure rule lives with its feature |
| `archive/ui/ui-tree` | `bcd33785` | feat(ui): the realizer — a neutral tree, one method per component |
| `archive/ui/wasm-stamps` | `c15019a0` | make: a wasm object follows its source's content and headers, as a host object does |
