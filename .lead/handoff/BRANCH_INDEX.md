# Branch index — every lane branch, what it is, where it stands

Generated 2026-11-15 16:03. All refs live in `../avra-ho-land` as `final/<branch>`. Trunk `program` = cf1b3e2cf; batch in gate `next-base` = abe09ce48.

## Lanes — what each is for

One lane may have several branches (`-2`, `-3`, a suffix): the highest number or the one in the table below is current.

| Lane (branch prefix `avra-lane-`) | Kind | What it is | Plan |
|---|---|---|---|
| whole-program | SWITCH | spec suites + doors on the new pipeline | land as green |
| check-baseline | SWITCH | `check` door identical to old path | land as green |
| type-refusals | SWITCH | type errors the new pipeline must refuse | land as green |
| refusals-decl-shape | SWITCH | declaration-shape errors | land as green |
| refusals-body-laws | SWITCH | body laws (loops, flow) | land as green |
| refusals-manifest | SWITCH | manifest errors | land as green |
| seat-laws | SWITCH | argument/seat errors | land as green |
| lowering-rows-c | SWITCH | operand/return/method errors (`1 + true`) | land as green |
| lowering-rows-b | SWITCH | kind rows; finished | land next batch |
| lowering-gaps | SWITCH | tests the new pipeline could not build | land as green |
| front-defects | SWITCH | state/mut defects; DONE | in gate |
| package-sweep | SWITCH | per-package blockers (std-queue) | land as green |
| ui-build | SWITCH | std-ui, site, ui-board | land as green |
| extern-seats | SWITCH | host fns + wasm target | land as green |
| embed | SWITCH | const/embed refusals | land as green |
| memo-reads | SWITCH | warnings parity | land as green |
| select-lowering | SWITCH | select + keepers fix | in gate |
| unboxed-values | SWITCH fix + SPEED rest | payload crash fix in gate; Result-side/nullable steps parked | fix in gate; rest after switch |
| soundness-cells | SAFETY | sound checker + static-write guard | in gate |
| switch-rehearsal | SWITCH | the 48-target sweep; reports only | no code |
| emit-speed | SPEED | slabs, dev-mode link | after switch |
| noop-speed | SPEED | no-op build speed | after switch |
| hot-writes | SPEED | write-path speed | after switch |
| rc-elision | SPEED | fewer refcounts | after switch |
| code-hash | SPEED | narrower code hashes (warm edit) | after switch |
| saved-answers | SPEED | saved answers / walk check | after switch |
| std-store | SPEED | machine-wide std store (cold build) | after switch |
| held-items | SPEED | held items | after switch |
| generated-items | SPEED | generated items | after switch |
| laws-cost | SPEED | cost of laws in cold build | after switch |
| ci-speed | TOOLING | CI series; held for owner review | owner review |
| ops- | TOOLING | gate scripts, Linux compiler builds | keep, no landing |

Rules: SWITCH lands batch by batch as its gate is green. SPEED/TOOLING is finished, safe, and lands only after the switch, one lane at a time, each with its own measurement. A branch is deleted only after it is LANDED or the owner says so.

## Every branch

Regenerated 2026-11-15 21:01. program = 25e8638b7, next-base = 74f7bf031.

State: LANDED = in program. IN GATE = in next-base. OPEN = not merged (speed/tooling parked, or superseded by a later branch of the same lane).

| Branch | Head | State | Last commit |
|---|---|---|---|
| avra-lane-check-baseline-8 | 4323edb84 | LANDED | merge next-base cd4759d5 |
| avra-lane-check-baseline-9 | e746f5cea | LANDED | receivers: a named type's shape method reached as the method it names, |
| avra-lane-ci-speed-2 | e76d88585 | OPEN | handoff: avra-lane-ci-speed |
| avra-lane-code-hash-3 | df5ede50d | OPEN | handoff: avra-lane-code-hash, (b) finished |
| avra-lane-embed-4 | a56c6b4f4 | LANDED | Hand-over: embed-4 on cd4759d5 |
| avra-lane-embed-5 | b0b99c6b3 | LANDED | A body const's reads compare statements by their identity |
| avra-lane-emit-speed-4 | e102979ac | OPEN | emit: a whole archive's words are a when; the lane's hand-over |
| avra-lane-extern-seats-5b | 6f6a611d2 | OPEN | Hand-over for avra-lane-extern-seats |
| avra-lane-extern-seats-6 | 55fbf790b | OPEN | A dependency's host fn is exported by the host it names |
| avra-lane-front-defects-mutlet | 2fb1d8185 | LANDED | handoff: avra-lane-front-defects |
| avra-lane-generated-items | a25cbf86a | OPEN | hand-over: handed_values finished; what is proven and what is left |
| avra-lane-hot-writes-cell | 773d5c9ba | OPEN | handoff: avra-lane-hot-writes finished |
| avra-lane-laws-cost | 2654d2008 | OPEN | handoff: laws-cost finished, edit witness green on cd4738e6 |
| avra-lane-lowering-gaps-2 | 2ec3e1768 | LANDED | handoff: avra-lane-lowering-gaps-2 on bd94a0d1 |
| avra-lane-lowering-rows-b-3 | 5e34d3c38 | LANDED | hand-over: final bundle base and how to resume |
| avra-lane-lowering-rows-c | c42b4d9d7 | LANDED | Merge branch 'next-base' into avra-lane-lowering-rows-c |
| avra-lane-memo-reads-2 | 439f14b57 | LANDED | Merge branch 'next-base' into avra-lane-memo-reads-2 |
| avra-lane-noop-speed-6 | 7f13af937 | OPEN | handoff: program_row_names finished; receipts recorded |
| avra-lane-package-sweep-2-law2 | 3e6f49a26 | LANDED | Merge branch 'next-base' into avra-lane-package-sweep-2-law2 |
| avra-lane-refusals-body-laws | 663d64e2f | LANDED | Body laws: an unbounded cleanup is judged in a fn's body, never in wha |
| avra-lane-refusals-decl-shape | 07dfff08f | LANDED | One reading of a declaration's name, found where it stands |
| avra-lane-refusals-manifest | fe47e1dac | LANDED | Edit witness: a line added to the cli's manifest; hand-over |
| avra-lane-saved-answers-4 | 371ad74a4 | OPEN | Hand-over: avra-lane-saved-answers |
| avra-lane-seat-laws-accepted | 407f97398 | IN GATE | Merge next-base a8c5e8ce |
| avra-lane-seat-laws-map | 33614405a | LANDED | Merge branch 'next-base' into avra-lane-seat-laws-map |
| avra-lane-select-lowering-6 | 05e52a095 | LANDED | hand-over: the keeper fixes built and their keepers green |
| avra-lane-soundness-cells-guard | 6764816b9 | LANDED | lead: avra-lane-soundness-cells hand-over |
| avra-lane-std-store-2 | ac541fa60 | OPEN | hand-over: package sets finished, cli self-build green |
| avra-lane-switch-rehearsal-3 | fa95cc970 | OPEN | handoff: avra-lane-switch-rehearsal — sweep 7 stopped mid-run; where i |
| avra-lane-type-refusals | b43d4b74c | LANDED | merge next-base |
| avra-lane-type-refusals-idiom | 8e868f4d8 | LANDED | item_uses: the use laws' witness module named once |
| avra-lane-ui-build | adec38e8a | LANDED | Merge branch 'next-base' into avra-lane-ui-build |
| avra-lane-ui-build-7 | 9d7c27d1d | LANDED | Edit witness: the enum fmt.av gains a variant carrying nothing, which  |
| avra-lane-ui-build-dynrecv2 | 6140823e0 | LANDED | A method called on a dyn value or a bounded type parameter writes its  |
| avra-lane-unboxed-values-nullable | e8397c832 | OPEN | WIP layout: the nullable of a record that is one word is that word and |
| avra-lane-unboxed-values-payload-cd | 1ec934951 | LANDED | hand-over: avra-lane-unboxed-values |
| avra-lane-unboxed-values-range-old | 5d1318d22 | LANDED | tests: range_places and payload_results build on both paths; read_set_ |
| avra-lane-unboxed-values-side | 5879b31ac | OPEN | Merge next-base cf1b3e2c into the side lane |
| avra-lane-whole-program-10 | feac2584d | IN GATE | An entry's answer that never arrives needs no text; module_runs_statem |
| avra-lane-whole-program-7b | 7f7696107 | LANDED | Merge next-base cd4738e6 into the whole-program lane |
| avra-lane-whole-program-9 | 2bc3e7383 | OPEN | WIP: one admission law for a package graph, shared by the workspace; h |
| avra-ops-gate | cd7a40e07 | OPEN | WIP avra-ops-gate: hand-over note and the Linux pre-gate scripts |
| avra-ops-gate-2 | ac278e067 | OPEN | handoff: batch 44 cli self-build proven (P2 == P3); the rest left as l |
| avra-ops-gate-3 | 215bb164f | OPEN | gate hand-over: batch46 gate left unresumed |
| avra-ops-linux-compiler | 1a86304c1 | OPEN | handoff: avra-ops-linux-compiler toolchain lane state |
