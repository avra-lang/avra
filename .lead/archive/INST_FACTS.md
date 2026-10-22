# avra-8sb5.57.264: an instantiation's code facts are kept under its own key (lead's design)

Problem: an instantiation `g$^T` roams (file: null). keep_codes keeps only a file's own bodies, and a held home
makes it a bodiless stub, so every hash reaching it is absent and the query recomputes.

## Key
An instantiation's lowered code is a function of exactly:
- its home file's TEXT (the generic template, its imports): the home's text key, already in KeyParts;
- its type ARGUMENTS' SHAPES: `type_shape(decls, t)` per substituted type (from #443), never their names;
- the compiler (the whole store is keyed by compiler_print already).
Its callees are other symbols; the merkle graph hashes them itself (another instantiation recurses the same way).
`inst_key = digest(home text key, [type_shape(arg) for arg in its substitution], symbol)`.

## Write (fresh lowering)
Wherever `drained` lowers a roaming instantiation FRESH (home not held), also store its CodeFacts
(`code_facts(decls, [that body], [its statics], [its hash asks])`) under `Stored.Codes`-like row at `inst_key`.
Reuse code_facts_wire. One row per instantiation.

## Read (held home)
Where `drained` turns an instantiation into a held stub (`fresh && is_held(w.file)`), compute `inst_key` from the
Wanted (`w.sub` gives the substitution) and, when the store holds facts there, add them to the `kept` facts that
`code_hashes` reads (the same list read_held_codes fills). Absent row → absent hash, exactly as today.

## Proof (attacks, Sprite)
- held-dyn passes (step `own` reads back).
- NEW: a type ARGUMENT's shape changes under the same name (a field added to `App` in the asking file, home held)
  → the instantiation's hash moves → recompute. This is the staleness trap; it must fail before the shape fold.
- code_hash_test, cache-attacks section for holds, std-relation durable tests by file.
