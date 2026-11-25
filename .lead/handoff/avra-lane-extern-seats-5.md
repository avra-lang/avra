# avra-lane-extern-seats-5 — wasm W1: host fns on the program layer, and what a wasm build lacks

Branch `avra-lane-extern-seats-5` (on -4), merged on trunk f62defdb. NOT merged on next-base a683ac99: none of the files it moved are this lane's. The bundle is `program..avra-lane-extern-seats-5`. Lane commits: 04bb73b, eda176e.

## W1, as scoped

### Hosted bodies — `Body.hosted` from `is_host_fn`
- `CalledFn.hosted` (core/lowering.av).
- `callee_of` (item_lowered.av) reads a host fn first, before `extern_parts`, which also answers for a host fn: it becomes a unit whose symbol is the bare name, `hosted: true`.
- The walk lowers its body and puts its row among the externs.
- Both body makers set `Body.hosted`. The backend's existing `host_symbol_defined` then defines the bare symbol beside `mangled(name)`.
- Before: the new path called `hf_answer` and never defined it ("ld.lld: undefined symbol: hf_answer"). After: `av_hf_answer` + `hf_answer` both defined, `40 done`, as the old path.

### Roots
Every host fn the program's own sources declare (its `src/tests/` aside) is a root of the walk (`package_host_fns`, compiler/item_hosts.av). The host calls it though nothing in the program may.

### ONE free `host_fn_line`
- compiler/hosts.av `host_fn_line(package, name, host)`; the old Workspace method now calls it.
- The program layer's timed build (`build --time`) says `host fn: <package> <name>` for each exported host fn, fresh or kept, as the old path's timed build does. Byte-identical: `host fn: hf hf_answer`.

### A package calling back into its own C
A scratch package whose `[link]` C object `hfc_twice` calls the Avra host fn `hfc_answer`: old path 42, new path 42. Not a suite case: the suite has no step that compiles a case's C.

### `-u <symbol>` at the native link
`program_host_symbols` is handed to `native_link_head` → `host_kept_words`. The bare symbol survives `--gc-sections`, as it does on the old path.

### The three whole-link laws, shared not ported, plus `host_fn_unhosted`
- `host_fn_owed` (compiler/hosts.av) is the one decision, `host_fn_owed_diag` the one wording, `host_fn_shadowing` (whole.av) the one platform test.
- The old path's `host_fn_owes` now gathers its inputs and asks it.
- The program layer asks it of every host fn of the files a build reads (`program_hosts_owed`: `package_closure` minus its own tests; asked = what its own sources import). cli's `program_built` says the result after the refusal step.
- Cases in tools/program-refusals, all hold:
  - host_fn_shadows, host_fn_unhosted, host_fn_unasked, host_fn_answers (refuse, old words);
  - host_fn_hosted, host_fn_answered_own (build).
- On the way: a path dependency's root is said normalized (`near/../far` → `far`), so a transitive dependency's file reads as the old path's.

### Gaps seen, not fixed
- The program layer doesn't refuse `manifest.lib_name` (a dependency's `[lib] name` that isn't its package's).
- A dependency's host fn is exported on the program layer only from the program's own package: `speaks_for` by host is wasm's and is in the table below.
- The `@host` mark is read by its name alone, not resolved to `@std/meta`'s.

## Receipts (f62defdb + lane)
- `AVRA_PROGRAM=1 make try`: 0.
- `AVRA_PROGRAM=1 build/avra-try build packages/cli`: exit 0.
- cli --built: 46565/46565.
- Refusal suite: 131 of 154 hold, 21 known, 2 failing (seat_u1, seat_variant, as trunk).
- std-sqlite 3/3, std-crud 7/7, std-db 9/9, std-ui 52 made / 52 / 52, 0 failing.
- The evaluator answers a host fn the program calls itself: `tapes --ran` 1/1 both engines.
- idioms: cli 0 NEW, std-avrac 0 NEW.

## MEASURED: what `AVRA_PROGRAM=1 build --target wasm32-wasi` lacks
**This sandbox:** no binaryen (/opt/binaryen absent) and no wasi-libc sysroot; node 24 and wasm-ld (llvm-18/22) present. So no wasm build runs end to end here on EITHER path:
- old path: "no C compiler here links a wasm module: … has no WASI libc";
- new path: refused before anything ("the program layer builds for this machine alone, not `--target wasm32-wasi`", cli/commands/shared.av `program_target_unbuilt`).

The table is a survey of the old path's wasm build against the new path's driver (cli/commands/tapes.av `program_built`). Sizes are the old code's non-comment lines and an estimate of the new code.

| # | missing piece on the program layer | old path has it in | old size | new work (est.) |
|---|---|---|---|---|
| 1 | `--target` admitted; the target threaded through `binary_asked` → `objects_owed`/`written_across` (the backend already takes it: `written_across(…, opt, "")`) and into the object and binary keys, so a native and a wasm object never share a key | cli shared.av gate (3); build.av keys | ~10 | ~25 |
| 2 | the wasm toolchain: a clang with WASI libc, the wasm runtime archive, wasm-opt; reactor/debug words | shared.av `wasm_tools`, `wasm_linkers`, `wasm_runtime_library`, `links_wasm` | ~30 | ~10 (call them) |
| 3 | the wasm link: driver target, crt1/libc, runtime archive, reactor `--no-entry`/exports words | link.av `link_objects` wasm branch | ~25 of 38 | ~20 (lift the branch to a free fn both use) |
| 4 | a package's `wasm_objects` from its manifest | whole.av `package_wasm_objects`, `link_words(target)` | ~10 | ~10 |
| 5 | a dependency's host fn exported by its host (`@host(Host.Page)` on a page build) | whole.av `speaks_for`, `exported_host_fns`; hosts.av `hosts_of` | ~15 | ~15 (in `package_host_fns`) |
| 6 | the reached program refused where wasm has no body: fibers, cores, a package's C | llvm.av `unsupported_on_wasm`; build.av `UnsupportedOnWasm` | ~15 | ~10 |
| 7 | output named `.wasm`, placed beside the native stem | build.av `binary_path` | ~3 | ~5 |
| 8 | the shipped module shrunk by wasm-opt | build.av `shipped`, `wasm_opt_tries`, `wasm_opt_runs` | ~16 | ~5 (free fns) |
| 9 | the asyncified fallback beside a module that runs tasks | build.av `fallback_made`/`_kept`/`_published`, `asyncify_tries`, names | ~42 | ~30 (Workspace methods) |
| — | already shared: the backend's wasm emission (host exports, function table export, `avra:rt` host imports, hosted symbols) | llvm.av, keyed by `target` | — | 0 |

**tools/ui-board's page program on the program layer today, native** (`tapes --built`, since `--target` is refused):
- 1271 bodies reached, 1270 made.
- The 1 not made: "a `dyn` box over a method the type doesn't write" (`@ui/board/src/board.av.view`), lowering-gaps' area.
- It reaches 13 `@std/ui` host fns marked `@host(Host.Page)`: item 5's exports, and the backend's host exports on a page build.

So the page needs items 1–9 plus that one lowering gap; hello needs items 1–4, 7 and 8 (no host fns, no tasks).
