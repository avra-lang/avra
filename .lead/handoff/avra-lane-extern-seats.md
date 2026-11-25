# avra-lane-extern-seats hand-over
- W1 branch `avra-lane-extern-seats-5b`, sits on next-base cd4738e6 (trunk cf1b3e2c and 933ce4bb inside). Head: this commit.
- W2 branch `avra-lane-extern-seats-6` @ 55fbf790, sits on the OLD 5b (pre per-file fix, base d12f29ce era). Not rebased.
## DONE (W1, -5b) — receipts on cd4738e6 merge
- Host fns found per file (`file_host_fns` @query over file_declares; walk pushes `hosted_in` for each file it first reads), never from a listing.
- make try 0; cold `AVRA_SOUND_CHECK=1 AVRA_PROGRAM=1 build packages/cli` 0, 0 defect lines; suite 291/301 hold, 10 known, 0 failing; cli --built 49010/49010; std-sqlite/crud/db/http --ran all; make wasm-runtime 0; make externs 0; CLI idioms 0 NEW; hf `host fn: hf hf_answer`/`40 done`, hfc 42.
- Full edit witness green on e2bce925 merge (EXIT 0, 34 min). On cd4738e6 it was STOPPED mid-run by the owner order: green through item_program.av; not completed.
- Extra commits: tools/externs.py skips tools/program-refusals cases (trunk's make externs failed on extern_decl_row_arity/legal/bare_int_mut, host_fn_hosted); tools/terminated.allow records avra_file_bytes/avra_file_placed (next-base's own rows, unrecorded; latent behind the first failure).
## FINDINGS not yet reported
- std-avrac old-path check (`check packages/std-avrac --baseline ...`) fails on next-base's own test features/ranges/tests/range_places/range_places.av: 16 `type.unknown: Range names no type` (Range-as-flat-pair lane).
- next-base cd4738e6 conflicted with -5b only in tapes.av (disk_built: build mode + `timed`); resolved keeping both.
## IN PROGRESS (W2, -6)
- Works: hello --target wasm32-wasi on program layer runs under node, same size as old (order differs); wasm refusal cases (wasm_core/fiber/hello hold, wasm_package_c known differ); warm edit re-emits 2/34 wasm objects.
- To do: merge -5b into -6; rework item_hosts W2 parts (exported_host_fns/package_extern_names) to the per-file model; fix idioms (pronoun_lambda in speaking_host_fns, duplicated_literal); ui-board page traps at `@ui/board/src/board.av.view` (record literal field default — lowering gap). Lead's acceptance set: the 20 std-ui web.av rows (7 imports + 2 runtime + 13 Host.Page exports).
- Toolchain: CC=/opt/wasi-cc/clang WASM_OPT=/opt/binaryen/bin/wasm-opt; node /opt/node24/bin/node.
## Don't touch
- compiler/item_hosts.av, compiler/hosts.av host-fn parts of item_program.av walked_from (`home`, `read`).
