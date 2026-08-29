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
- [ ] **[Low]** `packages/std-cli/src/cli.av` is a file SYMLINK into
      the bootstrap tree: bs2 resolves imports only from the local
      packages/ scan (manifest path-deps feed the prebuild, not
      resolution), its root sentinel is exactly this path, and
      linking the whole package would drag forge's transitive deps.
      One file-link satisfies everything without a vendored copy;
      dies when our compiler owns resolution.
- [ ] **[Low]** `src/` layer inside packages — bs2 resolves package
      entries only at `packages/<scope>-<name>/src/<name>.av`.
- [ ] **[Low]** `build/runtime.o` copy (Makefile) — bs2's own
      runtime, linked by bs2-compiled binaries; dies wholesale at
      self-host. (`llvm_wrapper.c` and `avra_runtime.c` are OURS,
      in-tree, built by our Makefile.)
- [ ] **[Med]** bs2 links its runtime objects from ITS OWN tree, not
      the working directory — so a builder ADDED to our
      backend/llvm_wrapper.c is undefined at link time until the
      Makefile installs our object into the bootstrap's build dir
      (`BOOT_WRAPPER`). `make test` hides it (the interpreter never
      links LLVM); only the native path fails. Dies when our own
      driver owns linking.
- [ ] **[Low]** bs2 invoked by absolute path only (Makefile) — it
      re-invokes itself via argv[0] from other working directories.
- [ ] **[Med]** bs2 `make build-quick` freshness detection silently
      skips rebuilds after some source edits — five consecutive
      "successful" builds shipped a stale binary during the mono fix.
      Use `make build` for anything that matters until fixed.
- [ ] **[Low]** Toolchain droppings (`*.avra-sha256`, `*.av.ll`,
      `packages/*/build/`) — bs2 writes byproducts next to sources;
      `make clean` sweeps them.
- [ ] **[Med]** Per-variant NODE CEREMONY is hand-written derive —
      a new node variant costs a fingerprint arm (nodes.av), canon
      and printing arms (types.av), a Dispatch field + boxed let +
      dispatch arm (program.av), and backend type arms (llvm.av):
      ~45 lines across 4 files at M14, every one a mechanical
      consequence of the feature's node declaration. bs2 has no
      derive/reflection, so the human executes it — SAFELY, because
      exhaustive matches break every owed site at compile time.
      Self-host derives all of it from the declaration and keeps
      the exhaustiveness check (generated AND checked, P6).
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
- [ ] **[Low]** Component instantiation cannot resolve AT ALL in
      metadata-compiled consumers (test files under the fast-path) —
      the in-package `feature()` factory bridges, and its body IS the
      instantiation, so the component stays the one construction
      path. Fixtures instantiate directly again when the registry
      crosses metadata or the clean compiler owns components.
- [ ] **[Med]** The LANGUAGE shares the grammar-DSL lexer's scanner
      (`lex_source` owns only the line policy): the token shapes and
      operator set happen to cover the milestone subset. A real
      language lexer — feature-extensible, string/comment/number
      shapes of its own — replaces this rent.

- [ ] **[Med]** The engine accumulates repetition captures by
      copy-per-append — parsing an N-statement program is O(N^2).
      Fix shape: `Many` becomes a prefix-snapshot ({shared list,
      count}); push in place at the tip, copy only after a real
      rollback. Touches the Captured currency — its own slice.
- [x] **[Med]** Native list methods `find`/`any`/`all`/`first`/
      `last`/`is_empty` typecheck but ICE at codegen — implemented
      upstream (runtime loops + optional-building emitters;
      `contains` now types as bool) and adopted tree-wide.
- [ ] **[Low]** No `find_index(pred)` list method upstream — the
      runtime scan exists (`avra_array_find_idx`); an emitter arm
      would collapse first-match-index scans (builders.av `attach`).
- [x] **[Low]** `semantics_of` boxed three dyn markers per node
      visit — fixed by dispatch-built-once: the impls box once per
      parse into `ParsedProgram.dispatch`; `semantics_of` only
      selects.
- [ ] **[Low]** The intern path materializes a string key per probe
      (bs2 `Map` is string-keyed; FNV walks bytes). The endgame is
      the epic §15.2 in-process tier: fp_mix over the int tuple
      (variant ordinal + child ids) into an int-keyed table, verify
      on collision — zero allocation. Trigger: the first composite
      shape (when `canon` starts concatenating). Route: a ~40-line
      core IntMap (open addressing over parallel `List<int>`s) or an
      int-keyed bs2 map; either swaps into `intern`'s body with zero
      caller churn. Note the hot path already never interns —
      singleton ids are threaded through the Typer.
- [ ] **[Low]** String scanning builds text by per-char concat
      (O(len^2) per string token) — a core string-builder arrives
      with real source files.
- [ ] **[Low]** A recovery hole (`Stmt.Error`) is not linked to the
      diagnostic that produced it — a sparse side table (hole ->
      diagnostic) makes the partial-tree story real for tooling.

## bs2 defects fixed upstream (2 files in this repo keep the workarounds until pruned)

- [x] Monomorphizer manufactured erased `Enum<Unknown>` instantiations
      whose payload/eq/release paths hard-ICE'd (F9999, no context).
      Fixed in the bootstrap tree: erased enum/struct specializations
      now carry `@mono_erased`; synthesized `__eq_*` compares erased
      slots as the wide scalar; expected types thread through match
      arms, list elements, and if-branches in both mono passes; the
      layout ICE now reports its full context stack, the offending
      type, and the statement cursor.
- [x] **[Med]** `grammar/executor.av`'s pinned-constructor ceremony —
      VERIFIED still required: bare `Captured.Absent` as an argument
      to a generic helper raises F1002 (arg-position ctors of a
      GENERIC enum carry no N-evidence). The pins stay.

## bs2 defects worked around in our code

CLAUDE.md's "bs2 subset notes" is the CANONICAL working list of
every trap with its symptom signature; entries here carry the rent's
death condition. The small ergonomic gaps (no `\$` escape, in-place
`.reverse()` aliasing, identity `contains`/list-`==`, no `mut`
params, no map indexing, no `xs[i] =`) are all noted there and all
die wholesale at self-host.

- [ ] **[High]** Match exhaustiveness is SILENTLY UNCHECKED when the
      subject is a closure-field call (`match cx.verb(x) {...}`) —
      compiles clean, runtime-aborts on an unlisted variant
      ("unmatched tag", styled as use-after-free). Found when
      str_lit's hole_reg survived M14 missing its .Struct arm; the
      capability-context pattern makes this OUR most exposed shape.
      Worked around by the annotated-let bind (untyped lets do NOT
      restore the check — probed). The doctrine's "a new variant
      breaks every site" holds only under that discipline until the
      checker is fixed upstream.
- [ ] **[High]** `f(x)?.field` (Result-`?` then a projection)
      refuses to parse in plain code but SILENTLY CORRUPTS the
      payload inside a comprehension element (garbage strings, null
      ids, no error). Split through a helper that `?`s first and
      projects second. A silent-corruption parse defect deserves an
      upstream fix before self-host.
- [ ] **[Med]** A nullable GENERIC struct local (`mut x: Thing<N>? =
      null`) corrupts through lib-mode mono — the executor carries
      presence in a bool flag beside non-generic pieces and
      reconstructs after the loop (fb_diags — the ugliest standing
      workaround). Un-flag when fixed.
- [ ] **[Med]** A METHOD call on a closure-captured local inside a
      loop that also early-returns ICEs at codegen ("Referring to an
      instruction in another function", forge-lang#1377) — the style
      doctrine's free-fn exception (`eval_node(ev, cx, e)` shapes)
      exists only for this and dies with the fix.
- [ ] **[Med]** A call result compared directly to a string
      (`f() == s`) misses the null guard and SIGSEGVs
      (forge-lang#1376) — bind to a `let tn: string? =` first.
- [ ] **[Med]** The F1000 tail-adoption class: a fn tail that is a
      bare enum-list literal, a `?? []` fallback, an early-returned
      generic call, or an if-else comprehension element in a generic
      body never adopts the declared return type — each needs a
      typed-let pin and a `return name`. The pins (and CLAUDE.md's
      list of them) dissolve when tails thread expected types.

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
- [x] **[Low]** Or-patterns: the spelling is `or`, not `|` —
      `.A(_) or .B ->` works and is adopted tree-wide.
- [ ] **[High]** A `dyn`-returning match boxes every arm with the
      FIRST arm's vtable — compiles clean, dispatches wrong,
      silently (forge-lang#1375). Worked around everywhere by boxing
      each impl under a typed let and selecting among the lets.
- [x] **[Med]** A `dyn` receiver whose trait kind degraded across the
      metadata boundary died "undefined method" — fixed upstream
      (registry recovery at the method fallback, PR #1374).
- [ ] **[Low]** Trait methods cannot return generic enums
      (`Result<...>`) through `dyn` — mono never instantiates
      trait-meta returns. Designed around: capability fns report,
      values return plain.
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
      match statements dropped the fn's return type. Fixed and MERGED
      upstream (forge-lang PR #1371, with a regression test).
- [x] bs2's prebuild-failure reporter ran a bare `tail $(...)` that
      read STDIN when nothing matched — every interactive `bs2 test`
      hung on the keyboard. Fixed and MERGED upstream (forge-lang
      PR #1372).
- [ ] **[Low]** Lib-mode (prebuild fast-path, `bs2 run`) does not
      thread a typed let's row type into a table literal — the
      explicit `table<Row> { ... }` form carries it in every mode and
      is the house style. The threading gap remains an upstream
      inconsistency worth closing.
- [ ] **[Med]** Trait DEFAULT method bodies typecheck but ICE at
      codegen ("undefined method") — nothing materializes the default
      for an implementor. Shaped like a template-instantiation fix at
      the impl seam; unlocks the spec's `kind()`/`message()` trait
      surface.
- [ ] **[Low]** Module-level `let` values do not resolve through
      imports — constants cross modules only as fns (kills direct
      value export for registries).
- [ ] **[Low]** `@comptime` folds only scalar int/bool bodies, so the
      seed grammar cannot be validated at compile time yet. When the
      clean compiler's comptime matures, `grammar_of_grammars().defects()`
      becomes a build-time gate.
- [ ] **[Low]** Feature grammars are raw strings (`gram = r"..."`), not
      `grammar { }` blocks — bs2's desugar calls parse_grammar per
      block, fighting the parse-once composition. Blocks return when
      our own front end owns the desugar; the conversion is mechanical.
