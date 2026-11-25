# Nodes step 3 — residue reducibility (db-a3-h, recorded on avra-8sb5.89)

Question: can each residue kind's `kids`/`heirs` override be reproduced by a structural MARK the
derive reads, or is it irreducibly semantic? (existing marks: `@declares`/`@expands` read by
children_derive; `@apart`/`@sequence`/`@branches` read by flow_derive; `heirs` default `[]`)

| kind | override | vs `@derive(Children)` complete walk | mark-able? |
|---|---|---|---|
| Block | block/semantics.av:14,19 | walk=`stmts_exprs(stmts)+some_list(value)`; kids hides BOTH; heirs=`some_list(value)` | reducible with TWO field marks: `stmts` hidden + `value` heir |
| Lambda | closures/semantics.av:12 | walk `[body]`; kids hides `body` | **YES — existing `@apart`** |
| Comp | lists/semantics.av:22,31 | kids = FIRST head's `source`+`hi` only; elem → heirs | **NO — irreducible** (predicate over clause order/kind, not shape) |
| Body | str_lit/semantics.av:12 | walk = `holes + body_view_children(view)`; kids = `holes` only | reducible: field mark on `view` (hidden); derive currently double-reaches holes+view |
| Component | components/semantics.av:12 | kids = `[check ?? expansion-root]` — ADD root, drop written `heads`/`block` | **NO with these marks** (needs "expansion ROOT stands in, `check` supersedes"; `@apart` would hide all) |
| Match | enums/semantics.av:37,46 | walk `subject+guards+values`; kids=`[subject]`; heirs=`arms[].value` | reducible via `@branches` + a HEIR mark on `arms[].value` |
| Catch | results/semantics.av:12 | walk `subject+values`; kids=`[subject]` | reducible: field mark on `values` (hidden) |
| Spawn | tasks/semantics.av:11,16 | walk `[body]`; kids=`[]` | **YES — existing `@apart`** |
| Collect | lists/semantics.av:22 | walk `[body]`; kids=`[]` | reducible: variant `@apart` or field mark on `body` |

**Verdict:** 7 of 9 are reducible with marks — `@apart` already covers Lambda and Spawn; a per-field
"hidden from kids" mark covers Collect/Catch/Body; Match/Block need that plus a "heir" mark.
**Comp and Component are irreducibly semantic** and must keep explicit overrides (or need richer
marks). So "move the residue to derived kids" is right for most kinds, wrong as stated for Comp and
Component.
