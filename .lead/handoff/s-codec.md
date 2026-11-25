# s-codec handoff (2026-11-02)
Branch hd-codec (worktree ../avra-hd-nodes2), pushed, clean tree: 80095e37. Extra worktree ../avra-census-clean at hd-clean 48704c95 (census/qtrace baseline; remove only with owner's say-so).

## Done (all on hd-codec, newest last)
- 726af4ed Wanted/Sub/SeatValue/Offset wear @codec, new `Wants` record; settlement_wire.av 396->124 lines. wants_text/wants_of_text/sub_text, decl/type/file spellers live in compiler/facts_scope.av. Held asks keep a small framing ("W4").
- e7301b92 + c1eef580 `Ids` deleted: fingerprint_in takes `dyn Scope`, `scope_fp(scope, kind, i)` (core/fp.av); Decls.decl_spelled/type_spelled memoize durable names as strings; FactsScope is the one scope.
- e6a26c55 decl_wire/type_wire/file_ref home by `File.name` (pkg:relative); `type_symbol` gone; `Decls.known_file_named` (`@index name` on File rows). 61a8922e line_wires/line_named take `home` = file_name(path). c06649ad tests/file_name_wire_test.av (two packages, same relative path).
- 46ad04db tools/path_leak_attack.sh (builds one package from two checkouts, names cache files carrying the checkout path; fails today, NOT in the Makefile). Leak table in .lead/ONE_PATH_2026_10_31.md.
- 80095e37 `Workspace.path_of_name` adapter: producers_of takes `path_of`; ref_target/wired_files/aimed_file words are names, mapped back to paths for Filed edges (lead wants this adapter DELETED: resolve straight to FileIds via known_file_named; producers/refs_by_target/Filed.path are path-keyed and serialized, so that is a real rework).

## Gates
- 41442886667 (61a8922e) and 41461915311 (80095e37): red, failures are the MAIN_GATE_2026_11_02 list PLUS: defects keeper "probe (check) timed out after 3s" x2 and 9 programs STALLED >10s in `check` (CPU-bound in grammar match_seq recursion; log: `gh run view 41461915311 --log-failed | grep STALLED`). hd-clean's gate shows none. s-gate told to HOLD 61a8922e; hold is NOT lifted.
- Census `test packages/std-http-fuzz` tip vs hd-clean: no counted regression (boxes 56.1M/57.2M, retains 163.3M/162.6M). Not allocation cost.
- Probe run 41490341029 on 80095e37: `./avra check packages/cli` cold still gives 170 `parse.expected: expected BREAK while parsing stmt` (+ `commands does not export ...`). That is MAIN_GATE item #1 (cli `cli avra {`, owner hd-nodes) on hd-clean too, so it may not be mine; s-families says hd-gate alone parses clean — unreconciled.

## Next step
1. Find out why defects probes stall: run `AVRA_QTRACE=1 ./avra check packages/std-http` (tip vs hd-clean via `sh tools/work run`) and count `Q parse <path>` per file. My qtrace run on the tip never started (BUSY) and hd-clean printed 0 lines (wrong target; use a defects-style copy of a program test, e.g. std-http/src/tests/h2_drain). Repeated parses of one file => a key/name mismatch (suspects: anything keyed by the old path-first wire word; grep `known_file_id(` callers fed a wire word; record.av wired_files, references.av ref_target, producers).
2. If a mismatch is found, fix, re-gate (`gh workflow run checks.yml --repo avra-lang/avra --ref hd-codec`), then lift the hold with s-gate and do the FileId-readers follow-up (delete path_of_name).
3. If the stalls are not mine, bisect 519a2f0b..80095e37 with s-families.

## Open
- Wire wording changed: stored wires (decl/type/file) are misses once on first run.
- CodeFacts/FactNode hand wires (code_facts_wire) are s-decl's @codec.
- Items left from hd-nodes2 handoff: held asks wait on hd-families2's `minting`; rows_derive.av dies with db.av.
