# avra-lane-memo-reads-2 — hand-over
Branch `avra-lane-memo-reads-2`, head = this commit, on trunk cf1b3e2c (next-base cf1b3e2c merged; cd4738e6 NOT merged).
DONE, handed back and landed or queued: build warnings from saved answers (file_warned/program_warned);
laws type.mut_fn_unused (item_unwritten), type.alias_copy (item_copies), type.receiver (item_receivers),
type.seat_unused (item_seats); tools/witness_program_warnings.sh and tools/program-warnings.known (old-path
over-approximations it excuses, keyed by method words). Bundles avra-lane-memo-reads-2.bundle, up to seat_unused.
DONE, NOT YET HANDED BACK: 79dc0ab7 type.coalesce_never (compiler/item_coalesce.av). Adds a generic
`cut` to Found/LawFinding plus `cut_fix` in diagnostics/voice.av; the old drop fix uses it.
Receipts on the cf1b3e2c merge: make try 0; --built 48616/48616; --ran failing name only wrap_method;
warnings witness 114 old held in exact text incl. fix lines, 6 beyond, every type.* kind has a law;
refusal 249/264, failing seat_u1 only; edit witness 12/12. NOT run: idioms (killed), sound check.
IN PROGRESS: type.unreachable_arm. Law draft in .lead/handoff/memo-reads-2-item_unreached.av.draft (to be
compiler/item_unreached.av). It reads item_holes' Cover.hole_of without editing that file. Still to do:
export voice fns `unreached_after_binder_said(name)` and `unreached_after_hole_said()` from
features/enums/check.av (the old `unreached_after_binder`/`_hole` must emit through them); register
`unreached_fact_definitions()` in item_tapes.av; build; compare. The cli has 0 old sites, so add a
fixture-package case to the warnings witness.
FINDING, not yet reported: the differential's WARN-MISSING rows for registry_hole and receiver (laws exist)
suggest the LONE-FILE build door (program_file_built in tapes.av) prints no warnings. Only program_built
does. Next: print warnings_said(program_warned) in the lone-file door too.
NEXT after that: `check` on the program layer printing the type.* warnings (coordinate with check-baseline).
Files of mine (ask first): compiler/item_{copies,receivers,seats,unwritten,coalesce}.av,
tools/witness_program_warnings.sh, tools/program-warnings.known.
