# Nodes step 1b — design (lead's; lanes do not change it)

Goal: `Expr`/`Stmt` become `collect enum …: Node`; `core/flow_derive.av` and the `@sequence`/`@branches`
words are deleted; each node's control lives ON its record. Most records write nothing.

## The mechanism (1b-a, compiler)
`collect enum E: T` today REFUSES a member with no `impl T for M`. New rule:
when `T` declares a `static fn derive(t: Type) -> …` (the existing `@derive(T)` hook), a member with no
`impl T` is DERIVED — `T.derive` runs over the member's record, exactly as `@derive(T)` written on it would —
and is not refused. A member with its own `impl T` keeps it. A trait with no `derive` still refuses.
- Where: compiler/expand.av `delegated` (also emit the derive work per un-implemented member, the way a
  written `@derive(T)` on that record is materialized — find that path: `derives_over`/`declared_work`);
  features/collects/check.av `checked_trait` (skip the refusal when the trait declares `derive`);
  `implemented_by` must then count the derived impl, so the delegating arm calls it (order: derive first).
- Proof: collects_test cases — a deriving trait fills a member with no impl; a member's own impl wins over
  the derive; a non-deriving trait still refuses. Program test: eval == native.

## The trait (1b-b, core)
New file core/node_trait.av, standing ALONE with `@std.meta` (a derive's file names nothing the annotated file
declares — CLAUDE.md):
```
/// A syntax node's own behaviour. A record that writes no impl is derived: its control runs its fields in order,
/// or nowhere when it wears `@apart`.
export trait Node {
    fn control() -> Control
    static fn derive(t: Type) -> List<Directive> { … `impl Node for ${t} { fn control() -> Control { … } }` … }
    static fn marks(t: Type) -> List<string> { ["apart"] }
}
```
The derive body is flow_derive.av's `@sequence` arm (`steps_of`, `step`, `runs`, `concatenated`) and its
`@apart` arm, moved — not rewritten. `Control` and `At` must be nameable where the impl LANDS.

## The records (1b-c, mechanical)
- `@sequence` marks: deleted (the derive is the default).
- `@apart`: stays — one word, read by `Node.marks`.
- `@branches`: the record writes `impl Node for X { fn control() -> Control { … } }`, its body MOVED from the
  matching `core/control.av` fn (`expr_binary_control` etc.). The convention fns are deleted.
- `@derive(Flow)` on Expr/Stmt is deleted; `collect enum Expr: Node = …` (and Stmt). Pat has no Flow: untouched.
- Callers: `self.store.expr_control(e)` → the delegated `control()` on the node (`grep -rn "_control(" `).
- Delete core/flow_derive.av.

## Bars
- One generation then two (`work run` builds twice). Census `check packages/cli` before/after: no worse than +2%.
- collects/enums/core/closures targeted tests; the must-analysis tests that read Control (grep consumers).
