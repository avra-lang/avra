# Tech debt

Rent paid to the bs2 toolchain, plus known bs2 defects we live with.
Each item dies when the compiler self-hosts the capability, bs2 stops
requiring it, or the defect is fixed. Priority = how much it hurts us.

## Toolchain rent

- [ ] **[High]** bs2 does not enforce module import closures — a
      missing `use` still compiles because a package's modules merge
      into one bundle. Every import is kept truthful by hand until our
      own resolver enforces closures.
- [ ] **[Med]** `packages/std-avrac/src/features/spec_test/{runner,reporter}.av`
      — vendored verbatim from the bootstrap tree; `bs2 test` loads
      them from this exact path. Replace with our own test harness.
- [ ] **[Med]** `grammar/executor.av` carries explicit `<N>` type
      arguments and typed-constructor ceremony because bs2 infers
      generics only from direct call arguments. Prune when the
      self-hosted checker infers better.
- [ ] **[Low]** `packages/std-cli/src/cli.av` — empty stub; bs2 detects
      a project root by probing for exactly this file.
- [ ] **[Low]** `src/` layer inside packages — bs2 resolves package
      entries only at `packages/<scope>-<name>/src/<name>.av`.
- [ ] **[Low]** `build/runtime.o` + `build/llvm_wrapper.o` copies
      (Makefile) — bs2 links against them but never builds them.
- [ ] **[Low]** bs2 invoked by absolute path only (Makefile) — it
      re-invokes itself via argv[0] from other working directories.
- [ ] **[Low]** Toolchain droppings (`*.avra-sha256`, `*.av.ll`,
      `packages/*/build/`) — bs2 writes byproducts next to sources;
      `make clean` sweeps them.

## bs2 defects worked around in our code

- [ ] **[Med]** Present-bind (`let x ->`) match arms in expression
      position can lose their binding at codegen (hit in
      `sync_cursor`; restructured to `if k == null { } else { k! }`).
      Un-restructure when fixed.
- [ ] **[Low]** Matching `null`/`let x ->` on a nullable fn call's
      result mistypes the subject (hit in `match_rule`; bound to an
      annotated `let found: Rule? =` first).
- [ ] **[Low]** Or-patterns (`.A | .B ->`) do not parse despite being
      documented — arms are written out separately.
- [ ] **[Low]** `@comptime` folds only scalar int/bool bodies, so the
      seed grammar cannot be validated at compile time yet. When the
      clean compiler's comptime matures, `grammar_of_grammars().defects()`
      becomes a build-time gate.
