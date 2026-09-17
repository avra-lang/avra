# Compiler performance handover — 2026-09-16

Worktree: `avra-cache-cas`, branch `cache/cas`. All changes are uncommitted. Run `build/avra*` directly with `LLVM_PREFIX=/opt/homebrew/opt/llvm`; the `./avra` shim can queue on a machine-wide lock. Compare **user CPU**, not wall time.

## Measured

- `check packages/cli`: `build/avra.pre` 158.7s user CPU, `build/avra.chunk` 124.7s. This remains far above the ROADMAP's old 5.25s.
- 200/400/800 files with two functions each: `build/avra.opt` 0.24/0.74/2.09s; `build/avra.chunk` 0.20/0.37/0.71s. Outputs and exit codes match on this harness.
- An attributed census found 301M list-element copies at `query.write_cell` on 800 files. Splitting the query-cell table into 256-entry rows removed the file-count growth.
- On `packages/cli`, the next largest copy sites were `Db.record_dep` (5.7B list writes) and `Origins.set_at` (4.8B). Grammar matching and template expansion also appeared in lldb stacks.

## In flight

Source now keeps dependencies per open query and batches each template's origin writes into local lists. A self-hosting build from `build/avra.chunk` is running. **These two edits are unverified.** The earlier namespace overlay and per-file method-diagnostic index are also in the worktree; their individual CLI gains were modest.

After the build: copy `packages/cli/src/main` to a new `build/avra.*` binary; run the 200/400/800 harness against `build/avra.chunk`; compare complete `check packages/std-avrac` diagnostics byte for byte against `build/avra.pre` on the same source; run the query and namespace tests; then measure `check packages/cli` user CPU. Keep the old binaries until these pass.
