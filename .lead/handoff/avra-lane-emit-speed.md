# avra-lane-emit-speed — hand-over
Branch avra-lane-emit-speed-4, on program cf1b3e2c (head: see git log; bundle /work/avra-lane-emit-speed-final.bundle = cf1b3e2c..avra-lane-emit-speed-4).
DONE, landed: emit-speed-opt (lld, forked emit shares, opt level), emit-speed-3c (AVRA_PROGRAM_MODE, shared LLVM, layered dev link).
DONE here (-4 part 1), proven on Linux: (a) emit width split across forked shares (-O1 peak -650 MB, same wall);
  (b) layered link speaks ELF and ld64 words (tapes.av LayerWords); overlay at one path linked by ld.lld alone; exe linked once per world;
  (c) witness_layered_link prints each link command + PASS/FAIL; edit witness hashes with shasum on macOS.
  Receipts on fa78a909 vs cf1b3e2c: default product byte-identical (32 objects + binary); cli self-build 0 both modes; layered + doors witnesses green;
  full edit witness green in default AND dev (25 lines); idioms std-avrac 0 NEW; cli 0 NEW after the last commit (when-ladder fix; make try 0, layered PASS).
  Dev warm literal edit: link 0 ms after the first (overlay unchanged) / ~0.1 s when the overlay moves; emit 160–190 ms.
UNPROVEN: the ld64 side — lead runs `sh tools/witness_layered_link.sh build/avra-try` on the Mac and pastes output; fix by its link lines.
NEXT (not started): (B) per /work/avra-bucket-scheme.md + held-items' four rulings (answer hash not question hash; per-bucket
  declared/externs/statics; per-instance generic objects; reach-independent Package slots; one package-set judgement from held-items).
  First fix within (B): BucketAsked copies program-wide parts per bucket (512 buckets passes the 9.7 GB pool).
FINDINGS reported: bucket 31 moves on a literal edit because 177/179 query code hashes move (code-hash lane); 2687f71a's embed way-check (5b).
Files: packages/cli/src/commands/tapes.av (layered link, BuildMode), compiler/build.av written_across, backend/llvm.av + llvm_wrapper.c emit/link primitives,
  tools/witness_layered_link.sh, tools/witness_program_edit.sh unsigned_at.
