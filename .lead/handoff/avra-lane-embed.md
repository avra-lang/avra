# avra-lane-embed hand-over (branch avra-lane-embed-4)
Base: next-base cd4759d5 (merged; one import-order conflict in features/consts/check.av). Bundle: /work/avra-lane-embed-4.bundle = cd4759d5..avra-lane-embed-4.
DONE in this bundle (lane commits fc4a596e, 9863ebd7, faa8b3d9):
- body consts reading earlier body consts settle as statics (core/names_read.av body_const_reads,
  Lowering.settled_consts, ConstSeed, SignedBody.consts, LoweredProgram.body_const(s, ty, seeds)).
- body-const const.trap / const.reach / const.budget refused, old words (item_refused.av consts_broken).
- const.form on the program layer, old words (compiler/item_const_form.av: const_formed + law
  const_unformed; body consts via consts_broken; features/consts/check.av exports unformed_voice and
  const_written for both paths).
Suite cases: body_const_{trap,reach,budget,read_trap,forward_read,chain_builds}, const_form_{fn,body,
optional_int,builds}. Receipts on cd4759d5: this lane's 28 suite cases hold; witness_body_consts green;
AVRA_PROGRAM=1 build packages/cli exit 0.
Not run this round (budget rule): full suite, --ran, edit witness (no new query the build reads).
Known gap seen, not this lane's: a literal const written `string` read as `string?` is "not lowered yet".
Nothing in progress.
