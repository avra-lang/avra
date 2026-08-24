# Tech debt

Rent paid to the bs2 toolchain. Each item dies when the compiler
self-hosts the capability, or bs2 stops requiring it.

- [ ] `packages/std-cli/src/cli.av` — empty stub. bs2 detects a project
      root by probing for exactly this file; without it `bs2 test`
      cannot locate its runner.
- [ ] `packages/std-avrac/src/features/spec_test/{runner,reporter}.av`
      — vendored verbatim from the bootstrap tree; `bs2 test` loads
      them from this exact path. Replace with our own test harness.
- [ ] `src/` layer inside packages — bs2 resolves package entries only
      at `packages/<scope>-<name>/src/<name>.av`. Flatten when our own
      module system exists.
- [ ] `build/runtime.o` + `build/llvm_wrapper.o` copies (Makefile) —
      bs2 links against them but never builds them.
- [ ] bs2 invoked by absolute path only (Makefile) — it re-invokes
      itself via argv[0] from other working directories.
- [ ] Toolchain droppings (`*.avra-sha256`, `*.av.ll`, `packages/*/build/`)
      — bs2 writes byproducts next to sources; `make clean` sweeps them.
