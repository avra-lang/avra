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
- [ ] **[Low]** `packages/std-cli/src/cli.av` — empty stub; bs2 detects
      a project root by probing for exactly this file.
- [ ] **[Low]** `src/` layer inside packages — bs2 resolves package
      entries only at `packages/<scope>-<name>/src/<name>.av`.
- [ ] **[Low]** `build/runtime.o` + `build/llvm_wrapper.o` copies
      (Makefile) — bs2 links against them but never builds them.
- [ ] **[Low]** bs2 invoked by absolute path only (Makefile) — it
      re-invokes itself via argv[0] from other working directories.
- [ ] **[Med]** bs2 `make build-quick` freshness detection silently
      skips rebuilds after some source edits — five consecutive
      "successful" builds shipped a stale binary during the mono fix.
      Use `make build` for anything that matters until fixed.
- [ ] **[Low]** Toolchain droppings (`*.avra-sha256`, `*.av.ll`,
      `packages/*/build/`) — bs2 writes byproducts next to sources;
      `make clean` sweeps them.
- [ ] **[Med]** Builder registration is a value-level table and
      builders take positional args off a `Builder` context — bs2 has
      no reflection, so `-> int_lit(v)` in a grammar cannot bind to a
      typed `fn int_lit(v: Token) -> Expr` directly. When self-hosted,
      the compiler binds build calls to typed fns (arity and types
      checked at composition; the engine allocates, spans, and wraps
      the returned node), and the builder tables, positional
      accessors, and `Result<LangNode, string>` spelling all
      disappear from feature code.

- [ ] **[Low]** Feature instantiation is the keyword-prefixed
      `component LanguageFeature f { ... }` — bs2's component registry
      does not span sibling module files, so the bare
      `LanguageFeature f { ... }` form cannot resolve cross-file.
      Drops to the bare form when our compiler owns component
      registration.
- [ ] **[Med]** The LANGUAGE shares the grammar-DSL lexer's scanner
      (`lex_source` owns only the line policy): the token shapes and
      operator set happen to cover the milestone subset. A real
      language lexer — feature-extensible, string/comment/number
      shapes of its own — replaces this rent.

## bs2 defects fixed upstream (2 files in this repo keep the workarounds until pruned)

- [x] Monomorphizer manufactured erased `Enum<Unknown>` instantiations
      whose payload/eq/release paths hard-ICE'd (F9999, no context).
      Fixed in the bootstrap tree: erased enum/struct specializations
      now carry `@mono_erased`; synthesized `__eq_*` compares erased
      slots as the wide scalar; expected types thread through match
      arms, list elements, and if-branches in both mono passes; the
      layout ICE now reports its full context stack, the offending
      type, and the statement cursor.
- [ ] **[Med]** `grammar/executor.av` still carries explicit `<N>` and
      pinned-constructor ceremony written against the old inference.
      Some of it may now be prunable — verify before pruning.

## bs2 defects worked around in our code

- [ ] **[Med]** Present-bind (`let x ->`) match arms in expression
      position can lose their binding at codegen (hit in
      `sync_cursor`; restructured to `if k == null { } else { k! }`).
      Un-restructure when fixed.
- [ ] **[Low]** Matching `null`/`let x ->` on a nullable fn call's
      result mistypes the subject (hit in `match_rule`; bound to an
      annotated `let found: Rule? =` first).
- [ ] **[Med]** Int-backed newtype values inside generic enum payloads
      corrupt across fn boundaries after monomorphization (nullable
      returns come back null). Sidestepped with struct ids; the mono
      repr bug deserves an upstream fix.
- [ ] **[Low]** Or-patterns (`.A | .B ->`) do not parse despite being
      documented — arms are written out separately.
- [ ] **[Med]** Component instantiation in expression position (fn
      tail, let init) compiles and yields a silent null instead of the
      instance — statement-bind + name return is the working form.
      A silent null from valid-looking code deserves an upstream fix.
- [ ] **[Med]** A generic call taking its only `T`-evidence from a
      fn-typed argument raises F1002; with an explicit `<T>` pin it
      compiles but corrupts int payloads through mono. Killed the
      generic capture-materializer (`all_of`) — Builder's
      tokens/exprs/stmts stay written out until fixed or self-hosted.
- [x] In a non-generic fn, a match arm wrapping a payload into a
      nested generic instantiation ICE'd at layout (F9999): mono never
      threaded ctor args' declared field types, and tail-position
      match statements dropped the fn's return type. Fixed upstream
      (forge-lang PR #1371, with a regression test); the pinned-helper
      workaround in `features/mod.av` dispatch is removed. Requires a
      bs2 built from that fix.
- [ ] **[Low]** `@comptime` folds only scalar int/bool bodies, so the
      seed grammar cannot be validated at compile time yet. When the
      clean compiler's comptime matures, `grammar_of_grammars().defects()`
      becomes a build-time gate.
- [ ] **[Low]** Feature grammars are raw strings (`gram = r"..."`), not
      `grammar { }` blocks — bs2's desugar calls parse_grammar per
      block, fighting the parse-once composition. Blocks return when
      our own front end owns the desugar; the conversion is mechanical.
