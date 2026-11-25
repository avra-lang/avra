# avra-lane-seat-laws hand-over

Branch `avra-lane-seat-laws-map` @ (this commit), on next-base cd4738e6 (merged clean; laws in item_refused.av = union, 34).

DONE and handed back (all landed or in the gate): A/element (seat laws, receiver, walk, index, list element), lambda (pinned generic seat),
literal (named nullable seat; state written from a lambda), widen (Code->Fix), cover (match coverage, catch-alls,
refutable let, repeated arm, variant arity, suite comparer fix), unknown/B (seat-laws-unknown.bundle, suite 0 failing).

THIS BRANCH (not yet handed back): type.map_key + type.map_value seats (Seating.MapKey/MapValue, laws map_key_mismatch /
map_value_mismatch, voices map_keyed/map_holds in features/maps/check.av); seat_mismatch witness moved to a lambda body of
the wrong type; suite cases map_value_mismatch, map_key_not_text, map_value_beside_spread; seat_c1 differs.why removed.
State on cd4738e6: AVRA_PROGRAM=1 make try 0; refusal suite 289/298 hold, 9 known, 0 failing; cli --findings 0.
On cf1b3e2c base: sweep 47/47, idioms cli+std-avrac 0 NEW, sound 0, --built 48501/48501, self-build 0.
Not run on cd4738e6: sweep, idioms, sound, --built, self-build. Next: the full gate, then bundle next-base..avra-lane-seat-laws-map.

Scoreboard (differential-2.md) codes I keep: ACCEPTED binds_twice, builtin_name, const_seat, contract_write, isolated,
sealed, spread_field, syntax_action; UNBUILT list_element (join wording), list_pattern, map_value (join), member_pattern,
narrow, not_offered, or_binds, pattern, record_pattern, spread_list, spread_map, spread_seat, variant_arity (literal),
enum_all, is_bind, case, cell_map, code_hash_named; OTHER-ERROR applied, kept_arm, map_key (fixed on this branch).
WARN-MISSING (unreachable_arm etc.) need memo-reads' warning machinery: ask the lead first.

Findings not reported: none beyond the posts. Merge rule learned: when resolving item_refused.av, keep BOTH sides of
every non-arm-list block and diff the `export law` lists before/after (4b77e4a once dropped four extern laws).
Files others must not touch without merging: core/checking.av coverage section (arms_cover..lengths), compiler/item_refused.av readers.
