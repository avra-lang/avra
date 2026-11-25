# Cold-row attribution: base57..89575bfa (parity-resolve-2)

Method: one census compiler per point, every one built by the same builder (gen-2 of 1e177af8) with its own tree's `tools/census_compiler.sh` (head's recipe for the points before 14eab4b4, which have none). Cold `check --counts`, store off, one core, over snapshot a6d0d0a0, exactly as tools/cost.sh runs check-cli and check-program. base57 (6abff86d) reproduces tools/cost.baseline to within 0.01% on every check-cli counter.
A share is (commit − its first parent). For a merge it is (merge − its base) − (first parent − the base before), so the shares add up exactly to 89575bfa − base57.

## Excess over base57, in % of the baseline row
| point | cli empty_lists | cli empty_grown | cli boxes | cli reclaims | cli list_buffers | cli copies | cli string_compares | prog empty_lists | prog boxes | prog reclaims |
|---|---|---|---|---|---|---|---|---|---|---|
| lane at the base55 merge 14eab4b4 (vs 53e67752) | +1.537 | +2.107 | +1.237 | +1.268 | +2.069 | +2.621 | +3.268 | −0.004 | −0.060 | −0.056 |
| lane at the base56 merge ee388283 (vs a73903d2) | +0.549 | +0.712 | +0.305 | +0.315 | +0.499 | +0.455 | +0.164 | −0.010 | −0.055 | −0.052 |
| lane at the base57 merge dac245bb | +0.536 | +0.706 | +0.297 | +0.307 | +0.507 | +0.456 | +0.173 | −0.010 | −0.061 | −0.057 |
| 89575bfa | +1.000 | +0.755 | +0.506 | +0.520 | +0.571 | +0.508 | +0.211 | +0.396 | +0.100 | +0.107 |
| 1e177af8 (head, after bb4859f1 and bbe499c0) | +0.714 | +0.245 | +0.350 | +0.361 | +0.187 | +0.087 | +0.242 | +0.408 | +0.102 | +0.109 |
| **fe7b46b7 (head + this fix)** | **+0.307** | **+0.217** | **+0.179** | **+0.186** | **+0.144** | **+0.074** | **+0.242** | **+0.054** | **−0.030** | **−0.027** |

## Per-commit shares that move a row (|share| ≥ 0.01%)
| commit | cli empty_lists | cli empty_grown | cli boxes | cli reclaims | cli list_buffers | prog empty_lists | prog boxes |
|---|---|---|---|---|---|---|---|
| stretch 1, 5cebcb11..324fd3c5, on its pre-base55 base: total | −12.44 | −19.52 | −29.71 | −30.14 | −24.89 | | |
| · 5cebcb11 top-level instances are declarations | +2.259 | +2.583 | +2.639 | +2.693 | +2.984 | +0.027 | +0.012 |
| · 97a803d3 one check judgement per declared instance | −0.473 | −0.433 | −0.349 | −0.356 | −0.408 | 0 | 0 |
| · ec9d036e use lines judged once, not per item | −14.178 | −21.644 | −31.937 | −32.419 | −27.430 | −10.179 | −18.783 |
| · fee7b8a7 implements asks written impls first | −0.045 | −0.027 | −0.064 | −0.061 | −0.036 | −0.069 | −0.091 |
| 14eab4b4 base55 merge (interaction) | +13.973 | +21.627 | +30.943 | +31.407 | +26.960 | +10.217 | +18.803 |
| 330025a9 an item runs by a statement that declares nothing | −0.990 | −1.389 | −0.928 | −0.948 | −1.453 | 0 | +0.008 |
| 7eafa0c8 a program starts at the first statement its entry runs | +0.002 | −0.004 | −0.001 | −0.001 | −0.085 | −0.009 | −0.006 |
| ee388283 base56 merge (interaction) | −0.003 | −0.003 | −0.004 | −0.004 | −0.032 | 0 | +0.002 |
| ed261dfa, c905744a (entry_only) | ≤0.001 | ≤0.001 | ≤0.001 | ≤0.001 | ≤0.003 | 0 | 0 |
| dac245bb base57 merge (interaction) | −0.013 | −0.007 | −0.010 | −0.010 | +0.005 | 0 | −0.006 |
| c925bd8c, d5b64366, 9aa3ad6b, c9b4a5f0 | ≤0.001 | 0 | 0 | 0 | 0 | | |
| 9d2ea337 re-export on the surface | +0.001 | +0.002 | +0.005 | +0.004 | +0.003 | +0.003 | +0.010 |
| ffc89a85 component word nobody imported | +0.025 | 0 | +0.005 | +0.006 | 0 | +0.027 | +0.005 |
| a1ef323f a grammar's shape is a value | +0.009 | +0.015 | +0.013 | +0.013 | +0.014 | 0 | 0 |
| 4f0bbd35 + 89575bfa formats (one share: 4f0bbd35's census compiler segfaults on both workloads, twice) | +0.427 | +0.031 | +0.186 | +0.190 | +0.046 | +0.374 | +0.145 |

Stretch 1 sits on 7e717b29, where the import laws cost about 30% of the cold check (ec9d036e removes them, and base55 carries the same fix). On that base its shares can't be read as what they cost on base57: only their net, the lane's excess at the base55 merge, can.

## Fixed: fe7b46b7 (on 1e177af8)
`cost: the covered-format-arm law asks an item's nodes only where it holds two format or text patterns` (89575bfa's `arm_after_format`). Every item used to run `template_nodes` and a `some_list(match_at(…))` over every node for it. Findings are unchanged: an arm can only be covered by an earlier format or text pattern, so an item with fewer than two such patterns has none.
- check-cli empty_lists +0.714% → +0.307%, boxes +0.350% → +0.179%, reclaims +0.361% → +0.186%, releases +0.166% → +0.023%, retains +0.088% → −0.042%
- check-program empty_lists +0.408% → +0.054%, boxes +0.102% → −0.030%, reclaims +0.109% → −0.027%
- Receipts at fe7b46b7 (make try, gen-2 standing): the program-refusal witnesses for all 15 format cases plus impl_undeclared_beside_generator and reexport_beside_its_import: 13 hold, 4 known to differ, 0 failing. format_arm_covered's three warnings match its warns.expected exactly. witnesses_test 13/13.

## What's left at fe7b46b7, check-cli (over base57)
empty_lists +0.307, string_compares +0.242, empty_grown +0.217, reclaims +0.186, boxes +0.179, list_buffers +0.144, copies +0.074. check-program: empty_lists +0.054 only.
Knockouts at fe7b46b7 (the law's reader returns nothing; a measurement only, never committed): what each law costs at head, in check-cli %:
| law (commit) | empty_lists | empty_grown | boxes | reclaims | list_buffers | copies | string_compares |
|---|---|---|---|---|---|---|---|
| build_reads_itself_law `builds_reading_themselves` (5cebcb11) | 0.043 | 0.024 | 0.028 | 0.029 | 0.030 | 0.024 | 0.018 |
| component_unimported `components_unimported` (ffc89a85) | 0.025 | 0 | 0.005 | 0.006 | 0 | 0 | 0 |
| use_meets_its_module `held_uses` ((2), bb4859f1 gated) | 0.019 | 0.017 | 0.008 | 0.008 | 0.014 | 0 | 0.015 |
| grammar_hole_read_as_text `grammar_holes_unread` (4f0bbd35) | 0.013 | 0 | 0.008 | 0.008 | 0 | 0 | 0.015 |
| kept_apart_type `apart_types` ((2), bb4859f1 gated) | 0 | 0 | 0 | 0 | 0 | 0 | 0.015 |
| `unknown_const_body` (5cebcb11) | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
These sum to about 0.10 of the 0.307 empty_lists. The rest, about 0.2 empty_lists and 0.2 empty_grown/string_compares, came in before the base56 merge: the lane's net excess over base56 was +0.549 empty_lists there. It can't be split further per commit, because no lane commit reverts cleanly onto head and stretch 1 sits on a base where the import laws cost ~30%. On its own base, the only stretch-1 commit that adds cost is 5cebcb11 (top-level instances are declarations: +2.26 empty_lists there). 330025a9 takes off 0.99.
Tried and dropped: `imports_name` (c3574683) as a parted query read once a module (4a310633, not on the branch). It saved string_compares 0.028 and boxes 0.014 but no empty lists, and it adds a query that a warm `use`-line edit reworks.
Not measured here: the warm edit rows and build-cli (the full slice); the lead's gate covers them. The cost of 4f0bbd35 alone: its census compiler (gen-2 builder) segfaults on both workloads (exit 139, reproducible after a rebuild), so it's reported together with 89575bfa.
