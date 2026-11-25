# Nodes step 2: a node's semantics are its record's `impl Node` (lead's design)

Today: `semantics_of(d, e)` (features/dispatch.av) maps each Expr variant to a per-FEATURE `XSemantics` value,
whose methods take `(cx, e: ExprId)` and RE-MATCH the node (`match cx.view.store.expr(e) { .If(c,t,f) -> … }`).
Target: each node record implements `Node`; the enum delegates; semantics_of, Dispatch's expr half and every
`XSemantics` expr type are deleted.

```
impl Node for If {
    fn kids() -> List<ExprId> { [self.cond] }
    fn heirs() -> List<ExprId> { [self.then, self.otherwise] }
    fn resolve(mut cx: ResolveCx, e: ExprId) { cx.arm_scope([], self.then)  cx.arm_scope([], self.otherwise) }
    fn type_of(mut cx: TypeCx, e: ExprId) -> TypeId { if_type(cx, e) }
    fn lower(mut cx: LowerCx, e: ExprId) -> Reg { if_lower(cx, e) }
}
```

## Layering: why `@delegates`, not `collect enum Expr: Node`
`Expr` is declared in core; `Node` names features' contexts (TypeCx, LowerCx), and core never imports features.
So the TRAIT says which enum it is delegated over, and the impl lands in features:
```
@delegates(Expr)
export trait Node { … }      // features/contract.av
```
`@std/meta` gains `delegates(tr: Trait, over: Type) -> Declared`, which is the same arms as `delegate`. A gathered member
with no `impl Node` is a PROBLEM it reports (refused at the annotation, naming the member), never a stub arm.

## Steps (each lands green)
2a. meta `delegates` + a collects/meta test (a trait in one file delegated over an enum gathered in another),
    seats keep their `mut` marks (check `Param` in meta for a mark field; the arm passes `mut` args through).
2b. `trait Node` in contract.av, `@delegates(Expr)`, every method DEFAULTING to the old dispatch
    (`semantics_of(cx.dispatch…, …).type_of(cx, e)`); every Expr member record gets `impl Node for X {}`.
    Behaviour unchanged; all suites green.
2c. Per feature (one PR may carry several): move each XSemantics expr method body into its records' impls,
    reading fields off `self` (no re-match); delete the XSemantics type and its Dispatch field.
2d. Drop the defaults; delete semantics_of and Dispatch's expr half. Callers ask `cx.view.store.expr(e).type_of(cx, e)`.
Then the same for Stmt (StmtSemantics) and Pat.

## Bars
census `check packages/cli` ≤ +2% (dyn dispatch → a match + direct call should be faster); targeted feature tests;
two generations.
