# Lead handoff — account migration (2026-11-19)

## Landed
- program (local + origin/program mirror) = batch 53: 289159282 (mirror 939424fb3)
- batch 54 gating: branch program-land-54 = 8d67e5e71 (gate/8d67e5e7)
- batch 55 assembling: branch program-land-55 = f47b89965

## Gate pipeline
- push a commit-tree of a batch tree onto program-gh as gate/<sha8> → .github/workflows/gate.yml runs ~27 min; land = ff local program, push commit-tree mirror to origin program, update-ref program-gh.
- gate builder: cached gate-builder-<sha> (newest), fallback release asset gate-builder.

## Lane refs held in ../avra-ho-land (fetched bundles, not yet merged)
- ui/unread de6acba40
- values/ann dfb5c5426
- values/fix c15de25cb
- values/lambda b4cb9a581
- values/land bbc86ae2e
- values/merged 90d41e17d
- values/merged2 f8a73a99d
- values/nf 59759be56
- values/p0 22463386f
- values/parity-values 14e7ddce0
- values/plan 57ff38711
- values/v10 b5a537738
- values/v11 14a072b44
- values/v12 ea02c9d4a
- values/v13 c83c540d0
- values/v3 7f488dbfd
- values/v4 12b7e061b
- values/v5 a28f89eb2
- values/v6 29eece064
- values/v7 cd2be2d26
- values/v8 275cead84
- values/v9 76ce368e3
- warm/ac 345bb814a
- warm/e53 2e0fb566e
- warm/e54 df52f7115
- warm/fix d03d06ef0
- warm/fixes f4918b438
- warm/fold a41d6edcc
- warm/fold2 333377364
- warm/fold3 eba617407
- warm/fold43 a18d08398
- warm/grain 06969a2ef
- warm/grain52 964cf5c72
- warm/w49 e918c1e27
- words/w1 5f698844a
- words/w2 237e8e26b
- words/w3 e67b5a92e
- words/w4 054b9c419
- words/w5 1ebadd216
- words/w6 55d98c2ac
- words/w7 1a3195937
- words/w8 90a15ac09
- wrong/avra-lane-parity-wrong-answers 2e19212fe
- wrong/cost 451ad9b87
- wrong/w10 c656c8b81
- wrong/w11 bd1ccdc30
- wrong/w12 103fccf7e
- wrong/w13 ce62ca4b4
- wrong/w14 11948b67b
- wrong/w15 88800ecd8
- wrong/w16 77acfb914
- wrong/w17 39f6db761
- wrong/w2 075de63c1
- wrong/w3 7e841948d
- wrong/w4 51a9d2629
- wrong/w5 949c802e3
- wrong/w6 73ee1995c
- wrong/w7 854db786e
- wrong/w8 3e0d71a13
- wrong/w9 f3607aa60

## Lanes (cloud, claude-web MCP) → rescue in .lead/rescue-2026-11-19/<lane>/
lowering-quality, layer-commands, parity-resolve-2, parity-wrong-answers (cost gate), alloc (noop-speed), parity-types, defects (check-baseline), parallel-main, warm (code-hash), spec-harness, laws-fusion, ui-language, parity-false-refusals, parity-values

## Plans of record
- .lead/PROGRAM_DESIGN.md: PERFORMANT BY DEFAULT; ARCHITECTURE FOR BOTH; item × phase (.lead/handoff/ITEM_PHASE_DESIGN.md)
- docs/ZERO_COST.md + CLAUDE.md law (landed batch 51)
- queue/rulings log: .lead/handoff/LEAD_2026_11_17_parity.md

## New account (acct2, claude2.r218j) lane sessions — started 2026-11-19 ~09:30 UTC, all Opus 5.5
- lowering-quality cse_01QBqJuoEhUSvvQtKNy4jgeL
- layer-commands cse_01QBqJupGRwCftk5trAChaRB
- parity-resolve-2 cse_01QBqJuoGGj1nb24ZC7g83MU
- wrong-answers cse_01QBqJuk1sDN2d7bA4Wx6k1D
- alloc cse_01QBqJuoCBfR5y7DwgakWdTU
- parity-types cse_01QBqJuoshSWsdEfYE13QV23
- defects cse_01QBqJunBfP8CSkAgkaCuvu3
- parallel-main cse_01QBqJupZAzei2S1S6XXPJDN
- warm cse_01QBqJummXpLNYcM2MzaYwF5
- spec-harness cse_01QBqJunmLveoUPzoVNUMNKB
- laws-fusion cse_01QBqJumtjtriz9rDD1xjWYc
- ui-language cse_01QBqJumMhrCeitiL9NDC4Ui
- false-refusals cse_01QBqJujuUjfCYmCnDDGZzWu
- parity-values cse_01QBqJupEEE4E8sXyxX4ypYR
Bridge: `bun src/cli.ts use acct2` (profiles), env "Default" mirrors old "Avra 2". Connector tools absent in sessions; lanes post via <to_controller>.
- batch 56 queue: services slice 18 = 76098d297 9ce8cfdb9 b186752d7 3b853ce49 91340bf08 ec3725573 7717cf775 (on top of slice 17; witness-b gains queue-witness — watch eval vs native on first run)
- batch 57 queue: services slice 19 = 96a0167a6 67a515611 bb284647c fbef2ecf2 97f600041 cbb17c73c (on rebased slice 18 48fde7fd5 — cherry-pick); parity-types (E = never / prefix type args / nullable-seat pin — services blocked); parallel-main grown+lent 8c63fade; spec-harness 8d954243
- routed services repros 11-19: ctx_spawn_* -> ui-language; export_use_cycle -> parity-resolve-2; named (receiver+named arg, test only) -> layer-commands
- batch 57/58 queue: services slice 20 = e58ebcb48 7e15776c4 902b033b7 82040a20c (touches std-meta)
- services slice 21 = 98666ae5c d50b1ecd6 (on slice 20)
- services slice 22 = b005790a2 bbf8fd413 (touches std-relation shape.av/relation.av — compiler infra; gate in its own batch 58 for clean cost attribution)
- services slice 23 = 3f636ee9a 0c05dcbc9 8c2d5b66f 877d031b9 1c5d3102d 48f554af5 (batch 58 with 22)
- services slice 24 = d617f0cf3 (std-queue_store only; batch 58)
- batch 58: warm 6e5bc566 + false-refusals 114b20a8 (both conflict w/ 57 in item_said/law_findings/held.av; merge 57's landed head first) + services 22-24
- services slice 25 = 37587bc9c 17242d7f0 6ba220c00 5da3ea24e a1f350e8d (batch 58)
- ROUTE LATER: derive cost — @derive(Saved) on Seating (106 variants, 153 payload fields) holds >5 MiB at compile time, grows per variant (parallel-main notes; guess: keeps every variant's quoted code until it answers)
- BATCH CADENCE (11-20, owner asked why 3h+): gate whatever is merged every ~2h; stragglers ride the next batch; accept explained cost rows AFTER the gate run, not before. Batch 58 gated 08:3x UTC at 24621f63 without the flip (layer-commands/parity-resolve-2 bundles were base56-era and conflict); flip + those ride 59.
