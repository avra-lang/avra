# avra-lane-lowering-gaps-2 — hand-over

Branch `avra-lane-lowering-gaps-2`, on next-base bd94a0d1. Bundle: bd94a0d1..branch. On the merge I took bd94a0d1's generated_expanded in place of my made_meant (same fix) and kept the filled receiver beside its const seeding.

## In this bundle (not in next-base yet)
- e0cd4d8d borrow_dyn link failure (dup `R.grow$w`): a shared dyn written-entry shim is emitted weak. Witness: tools/program-refusals/builds_dyn_written_shim.
- 917af89e generic_lit: a value that types to nothing in an open seat is checked against the seat once the call's want fills it (core/checking.av `fills`).
- 1c2f61ee std-ui `Component` ×17: superseded on the merge by bd94a0d1's generated_expanded.
- f5a9e401 model_form / read_all: bounds reach generated impls and a component's own fns (item_methods.av target_bounds). Under a fill the receiver is bound filled (item_lowered.av), and a type the body writes reads the fill (core/lowering.av `written`).

## Receipts (bd94a0d1 + these, cold)
- AVRA_SOUND_CHECK=1 AVRA_PROGRAM=1 build cli: exit 0, 0 errors, 0 defects.
- std-avrac --ran: 667 found / 663 made / 0 failing.
- std-ui --ran: 78 found / 76 made (was 58). Only failing name: web/tests/mount.
- Suite: 361 of 377 hold. The 6 failing are body-laws' new cases from c78d792f, which have no pinned expected files.

## rc_routes (on 8cb5d1f6)
- 0a20bf40: a lambda takes its seat's one record's fields by name (`{ params -> params.id }` handed a `Request`), the old path's offer. core/closures.av `takes_by_name` is shared by typing (core/checking.av offer_checked) and lifting (offer_seated).
- std-http --ran: 56 found / 56 made / 0 failing. The `test` door no longer stops on a gap: 1364/1365. The one failure is admission_test "a redirect": it needs a `::1` listener, and this container has no IPv6.

## Not mine / open
- std-ui web/tests/mount: now made, but its program answers host externs itself (`extern fn avra_ui_stood() -> int { 0 }`), which the program layer doesn't define: link fails, eval fails. That's host-fn (extern-seats W1) work.
- The idioms gate was not run this round.
