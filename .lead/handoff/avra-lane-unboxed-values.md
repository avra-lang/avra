# avra-lane-unboxed-values — hand-over
- Branch avra-lane-unboxed-values-payload-cd (this file), base next-base cd4738e6. Also in the final bundle:
  avra-lane-unboxed-values-side (5879b31a, on cf1b3e2c) and avra-lane-unboxed-values-nullable (e8397c83, WIP on side).
- DONE, handed back: census-4 tooling (landed), range-3 bundle (Range as Fields(lo,hi); landed in cd4738e6),
  avra-lane-unboxed-values-payload.bundle (267d04bf on cf1b3e2c: variant_word's Owned arm judged by layout).
- IN PROGRESS 1, payload-cd: the same fix re-merged onto cd4738e6, one arm in variant_word (diff vs cd4738e6 =
  that arm + payload_results test + tools/program-refusals/builds_enum_result_payload). Receipts so far (build/p2.log):
  P1 make try 0, P2 == P3, payload_results package = .expected with RC_GUARD 0 and live 0, range_places package =
  .expected with RC_GUARD 0, the whole payload grid correct. Stopped before: the refusal suite, the program-layer sound
  build, cli --built and --ran. Next command: `sh build/p2.sh` in /work/avra-rf, then re-send the bundle.
- IN PROGRESS 2, side (step 2: side_word gives 0 for a one-Word FlatRecord; test results/tests/word_side): it failed
  only on the enum-payload ICE that the payload fix cures. Next: cherry-pick 78b99346 onto payload-cd and run receipts
  (build/s1.sh pattern), with a census against payload-cd for the drop in `box enum` (expected ~1.69 M).
- IN PROGRESS 3, nullable (step 3: nullable_laid gives Maybe(Word) for a one-Word FlatRecord; test nullable/tests/
  word_nullable written first: ids 0/-1 against null, Id?? through a generic seat, once caching null, consts). Never built.
- FINDINGS: the enum-payload Result bug had three failure modes on trunk (wrong answer, compiler segfault, LLVM ICE),
  already reported. scalar_field is the only by-name judgement left in core/layout.av (an admission list, harmless).
  The program-refusal suite needs build/sqlite3.o and build/sqlite_sentinel.o (`make` them) in a fresh tree.
- Don't touch core/layout.av variant_word/side_word/nullable_laid until these land.
