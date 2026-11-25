# s-nodes handoff (lane s-nodes, worktree ../avra-hd-nodes, branch hd-nodes)
Shas: pushed f8dc603f (Worded rung 1, clean: `./avra check packages/std-avrac` exit 0). Rung 2 + WIP committed/pushed after (see git log hd-nodes).
## Done
- 8cb0a51e reverted; 11.384 redone decl-based (Decls.collects/gathered_by, collect_word), hd-marks-cycle merged; closure_far has its own `@seat in self` collect. NOT gated.
- Predecessor idiom fixes committed per package (std-relation, std-net, std-avrac). NOT compiled/gated; the 69 sites uncounted. Run `make idioms` via runner.
- 89.14 PARKED (ticket comment has the design: owner link generalizing instance_owners, value-wanted bit, ~30 files; needs a free build slot).
- Hand builders: 19 `*_written` fns + build_sublang (+2 from s-gate #15: counted_written, rest_wild_written in core/computed.av). Plain ones: exported_written, annotated_written/mark_written (need prefix-mark carrier = @facet at prefix position), collect_written (needs Worded for scope/kind, Projection nested group, order, dense facet). struct_lit_written = registry hatch (write `// LICENSED`).
## Worded (core/worded_derive.av)
- Rung 1 (f8dc603f): `@derive(Worded)` gives `worded_<E>(text) -> E?`; replaced collects scope_of, record.av shape_of, manifest.av provenance_of. Name is Worded, not Spelled (Spelled clashes in expand.av/@std.meta).
- Rung 2 (committed locally on hd-nodes HEAD, check NOT clean): `@word("+")` variant marks, `word_of_<E>`, BinOp derives it, op_symbol/binop_of/all_binops deleted (callers use word_of_BinOp/worded_BinOp/BinOp.all()), tests in core/tests/worded_test.av.
- FIXED: the marks claim returned a list literal, which trapped every derive; it returns [word_mark] (a const) now. Rung 2 check: exit 0, 0 errors.
- Extension approved but NOT written: `@word` on payload variants (word_of reads it, worded skips), shared words (worded generated only when unique), then delete kind_word (features/decls.av, ~12 callers), scope_word (record.av), Happened words (cli/trace.av). The draft is in `git diff` history only as /tmp/rung3.patch (lost on reboot): word_for -> string?, `[ "_${i}" ... ]` binders, concat_if/unique.
## Gotchas
- `./avra check packages/std-avrac` takes ~95-120s; a 118s `timeout` prints NOTHING (exit 124) and looks clean. Run it in the background to a file, wait with Monitor, read `exit N` and `grep -c '^error'`.
- BSD sed has no `\b`; use perl -pi.
- gh API limit is shared; never poll.
- Run 41409008949 (collects suite) never read.
## Next step
1. Read /tmp/chk9.txt (or rerun check). If exit 0: fmt, commit "worded: marks claim via const", push, send sha to s-gate.
2. Then payload @word / shared words, delete kind_word/scope_word/Happened tables.
3. Then `make idioms` on a runner, fix remaining sites per package.
