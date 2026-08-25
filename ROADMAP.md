# Roadmap

The strategy: a THIN VERTICAL SLICE first — two statement kinds driven
through every pass to a world-class error — then features widen, each
vertically complete. This is the AST epic's own L0-tracer doctrine at
real scale; the design sources of truth live in
`../forge-crafting-intepreters/docs/` (see CLAUDE.md).

## Milestone 1 — the front end

- [x] Grammar engine: anchor-commit alternation, farthest-failure
      expected-sets, `@expect`/`@recover`, self-hosted DSL fixed point
- [x] Authoring surface: `LanguageFeature` component, `Builder`
      context, engine-attributed spans, compose-time coherence
- [x] Statement layer: same-name rule merging, `stmt_spine`,
      `let_stmt` (recovery), `expr_stmt`
- [x] `language/` driver seam: `assemble` + `parse_program`; recovery
      holes are explicit `Stmt.Error` nodes
- [x] Harness retirement: feature tests parse through the driver;
      private test plumbing deleted

## Milestone 2 — a world-class error, end to end

- [x] @std.errors — the base error model (describe-only trait, Loc,
      Frame, graded Suggestion); compiler diagnostics implement it
- [x] Diagnostics currency: Diag over the base, kind as identity,
      F-codes as the registry's projection, the kind|id|summary table
      registered per feature and duplicate-gated at assembly
- [x] Rendering: per-file line index (byte spans -> line/col only at
      render), the miette-shaped renderer, golden rendering tests
- [x] Driver projection: engine diagnostics -> Diag, with the
      unregistered-kind validation net
- [x] `avra check` CLI over the driver (`make check FILE=...`; a
      compiled standalone binary is later polish)
- [x] Resolve pass — the first pure query: definition-site symbols,
      facts in a pass-owned dense table (O(1) by ExprId), sequential
      visibility with shadowing, use-before-def as its own kind,
      graded nearest-candidate suggestions
- [ ] Type pass: opaque `TypeId` + interning registry
      (content-addressing drops in later), the totality invariant —
      `Unknown` never reaches a consumer
- [x] GATE: `avra check` on `let x = 1 + y` prints a beautiful
      resolve error — golden-tested character-exact

## Milestone 3 — widen, vertically complete

- [ ] GATE before widening: the FIRST/FIRST coherence check — merged
      branches of one rule must not share a first token; feature
      order decides overlaps DELIBERATELY, never silently
- [ ] Comments in language source (the first human-facing lexer need)
- [ ] Each new language feature lands with grammar + builders + check
      rules together (the component model working as designed)
- [ ] Back-end decision round: eval vs LLVM emission (its own design
      conversation, spec on the table)

## Self-host endgames (recorded, not scheduled)

- Typed builders: `-> int_lit(v)` binds a typed fn; tables and
  positional accessors die (TECH_DEBT)
- `@derive(Error)`: the enum declaration becomes the error table —
  kinds from names, messages from doc-comment templates, generating
  exactly `describe()`
- Trait default method bodies (bs2 ICEs today): `kind()`/`message()`
  return as defaults over `describe()`
- `grammar { }` blocks replace raw-string grams
- Bare component instantiation (registry spans files)
- Query engine (L6 red-green memoization) wraps the pure passes
- A real feature-extensible language lexer

Update this file whenever a slice lands or the plan changes — the
roadmap lives HERE, not in conversation.
