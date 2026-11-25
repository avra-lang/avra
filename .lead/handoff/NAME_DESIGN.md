# B: identifiers as Names, interned upstream, ints downstream (ROADMAP #5)

## What carries a Name
- The type is std-program's `Name { id: int }` (names.av, 71df5b17). It is @sealed: only `name_of(text)`
  makes one. The id is dense and the PROCESS's own. `n.text()` answers the text.
- The source of every Name is the TAPE READ. The tape already numbers its texts once per tape
  (`NumberedTexts`; `TapeReader.text()` answers `texts[count()]`). The reader gains
  `name() -> Name`, which interns each distinct text slot of the tape ONCE: a lazily filled
  `List<Name?>` beside `texts`, indexed by the text's number. So an item read back pays one intern per
  distinct identifier, not one per mention. The writer gains `name(n: Name)`, which writes `n.text()`
  through the same `NumberedTexts`.
- The tape derive (core/copied_derive.av, the `untape_*`/tape writers it generates) learns one field
  kind, `Name`: read with `tape.name()`, written with `tape.name(n)`. The Matchable/kids derives need
  nothing (a Name carries no id of a node).
- Phase 1, the fields resolve compares: `Expr.Ident(name: Name)`, a pattern's bound name
  (`Pat.Bind`), `Param.name`, a lambda's params, a `let`'s binders. Resolve's frames, scope, overlays
  and lambda params become `List<Name>`, and lookups compare Names (one int each). The LOOKUP key
  arrives as a Name (from the Ident), so nothing is interned at the lookup.
- Phase 2, the declared names: `DeclaredName.name`, FileScope siblings, `Bound`. Map keys are strings
  only in this language, so a by-name table either stays keyed by `text()` or becomes a DenseWindow
  indexed by `id`, which is the process's own and never saved.

## How it is saved
- As TEXT, always: Name's `saved_bytes`/`written_into` write `NameText { text }`, and `read_from`/
  `from_saved_bytes` re-intern at load. The tape format does not change, since texts were always
  what it stored.
- Every hash, fingerprint, content key and print of a Name folds its TEXT (`folded_into`), never its
  id. A saved answer, a store key and a print are the same in every process.
- No id leaves the process: not in a saved answer, a diagnostic, a sort key, or a test's expected
  output.

## Bridge order (main's compiler builds each step)
1. Tape verbs only: `TapeReader.name()` with its per-tape intern slots, `TapeWriter.name(n)`, and the
   tape derive's `Name` field kind. No node uses it yet, so every tape is byte-identical.
2. `Expr.Ident(Name)` and its readers in one commit, about 47 match sites in 30 files: a site that
   needs text says `n.text()`, and one that compares compares Names. Resolve's scope and frames take
   `List<Name>`.
3. `Pat.Bind`, `Param`, lambda params and let binders the same way, one commit per node kind.
4. Phase 2 (declared names) as its own batch, after measuring 2–3.
None of this adds syntax or a compiler-checked law, so each step builds with the compiler before it.
The store's layouts change (a Name field is saved as a `NameText` record), so the first run of each
step re-derives cold, once. Each step's receipt: findings cmp-identical on cli, std-avrac and
std-program, gen-2; `check lawed` plus `WITNESS_ONLY=check`; census compares and retains; the
`--release` product cmp.

## What every lane touching Expr.Ident or resolve must know
- `.Ident(n)` binds a Name, not a string. Text is `n.text()`. Make one from source text with
  `name_of(text)`, never `Name { … }` (sealed).
- Compare Names with `==` (one int). Do not compare `n.text() == other.text()`: that is the string
  compare this exists to remove.
- An id is not a count and not an order. Sort by `text()` wherever order is visible (findings,
  diagnostics, listings). Two processes mint different ids for the same name.
- A Map cannot key on a Name (keys are strings). Key on `text()`, or index a DenseWindow by `id` for a
  table that lives only in this process.
- A Name in a saved type is saved as its text automatically (Name's own Saved verbs). Never hand-write
  its `id` into a record, key or hash.
- A template copied across files carries its Names as text and re-interns where it lands, so a
  splice never compares ids minted in another context.
- Merging across this batch: resolve conflicts in the type (string -> Name), then make every
  comparison in the conflicted body a Name comparison; a leftover `.text() ==` is the smell.
