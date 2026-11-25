# avra-lane-type-refusals — hand-over

Branch `avra-lane-type-refusals`, base next-base cd4738e6 (merged). 2687f71a is NOT an ancestor (an old
branch carrying it is kept locally as avra-lane-type-refusals-on-2687 — ignore it).

DONE, handed back: bundles A, B, C, D (all landed or in batches).

BUNDLE E (on this branch, not yet sent as its own bundle — this final bundle carries it):
10 of the 13 "not lowered" witnesses as refusals in old words (when_arms, with_struct, spread_value,
spread_nullable, spread_generic, chain incl. `?.(…)` with its aside, lambda, variant_lit, let_pattern,
type_value) — compiler/item_members.av + shared voices; suite cases w_*.
Receipts on the commit before the last: make try 0; AVRA_PROGRAM=1 build cli 0; refusal suite: no
failing names; findings sweep 48 rows, 0 errors. NOT run: idioms gate, sound check, edit witness
(killed by the stop order).

IN PROGRESS (last commit daf63c56, WIP, NOT BUILT): compiler/item_loads.av — the quote_meta law skips a
quote a PATTERN writes (Pat.Quote body), so type.quote_pat_* / annotation.unread_mark speak their own
kinds. Next: `AVRA_PROGRAM=1 make try`... i.e. `make try`, then rerun the quote_pat_* witnesses from
compiler/dev/witnesses.av old vs new; the quote_pat_* laws themselves are still to write (mine).

QUEUE (from differential-2): resolve.reserved/kept_apart/reexport_twice said as resolve.unresolved;
resolve.* ACCEPTED x10; annotation.* x8; type.component_check/format/row, type.match_opt;
resolve.reexport_unreached (query cycle); UNBUILT resolve.immutable, resolve.place, type.catch,
type.interp_hole, type.let_else. type.format/format_parse are decl-shape's.

Findings: methods on List/Range are untyped on the new path where they lower fine — own-type method
law kept to scalars for that reason. Files mine: compiler/item_members.av, item_unknown_types.av,
item_annotations.av, item_format_faults.av, item_derive_contracts.av, item_component_bodies.av,
item_loads.av, item_identity_fields.av, item_impl_targets.av.
