# The feature pipeline, seam by seam

Checked against `origin/main` @ `faf1afc`. Paths are under `packages/std-avrac/src/` unless they start with `tools/` or `docs/`.

**Labels.** `READ` = I opened the line (file:line beside it). `COUNT` = `git grep -c` on that commit, tests excluded. `ESTIMATE` = a guess about the proposed world. `BRIEF` = a number I was given, not one I measured. Nothing here was run.

---

## 0. The one-screen answer

A feature today is a directory of five files that is *almost* self-contained, plus about twenty hand edits in nine shared files. The feature directory is in good shape. The shared files are where the cost is.

| | today (READ/COUNT) | proposed (ESTIMATE) |
|---|---|---|
| files created for a new statement | 7 | 1 |
| shared files edited | 9 | 1 (the order list) |
| hand registrations | ~23 | 1 |
| `_ -> nothing()` re-matches of a feature's own node | 62 in 27 files (COUNT, approximate pattern) | 0 |
| ways a pass writes a fact | 3 (return / insert / mutate) | 1 (return) |

The three biggest gaps:

1. **A node is declared in `core/` and claimed in six other places by hand.** Everything a derive could read off the variant is instead re-spelled.
2. **Declarations are inserted and then patched.** Every other relation hands over a value.
3. **Per-kind logic lives in the driver, not the feature.** Signatures, declaration minting and printing all match on kind inside `compiler/` or `core/`.

---

## 1. Feature registration

**Now** — READ `features/mod.av:171-180`, `compiler/mod.av:182-275`, `compiler/program.av:116-171`.

```avra
export component LanguageFeature {
    name: string
    gram: Grammar = no_grammar()
    builders: List<BuilderRow> = []
    diags: List<DiagCode> = []
    methods: List<MethodRow> = []
    …
}
```

```avra
export fn language_features() -> List<LanguageFeature> {
    [ stmt_spine(), closures(), tasks(), … if_expr(), when_expr(), … defers(), fns(), … ]
}
```

- **Touch:** an import and a list entry in `compiler/mod.av`; an import and a field in `new_dispatch` (`program.av`); a field in `Dispatch` (`features/dispatch.av:12-62`, 49 fields). Five edits, three files.
- **DB-shaped?** No. A feature is a fn that builds a component instance and returns it. 37 of them (COUNT `LanguageFeature x {`).
- **The order is real.** Each list entry carries a comment saying why it sits there ("BEFORE mutation, whose recovering `mut` statement would otherwise swallow `mut fn`", `compiler/mod.av:217-221`). Order is ordered choice. It cannot be alphabetised.

**Could**

```avra
export feature unless {          // a top-level instance, like `rule` and `command` already are
    gram: grammar { … }
}
```

```avra
// compiler/mod.av — the ONE definition of Avra, and the only registration left
export const order = [stmt_spine, closures, tasks, …, if_expr, unless, when_expr, …]
```

- The list names declarations, not calls. Imports, `Dispatch`, `new_dispatch` are generated from it (seam 4).
- **Faster:** nothing much; the assembled language is already built once.
- **Needs:** nothing new. `export rule x { … }` is this shape today (READ `features/if_expr/idioms.av:22`).
- **Principle:** P12. Keeps "feature order is branch order is the language" exactly as written.

---

## 2. Grammar

**Now** — READ `features/if_expr/mod.av:19-24`.

```avra
gram: grammar {
    stmt = v:if_stmt END -> v
    if_stmt = "if" c:expression "{" ( t:stmt | BREAK )* "}" ( "else" … )? -> if_stmt(c, t, e) @head(c)
}
builders: rows
```

- **Touch:** the fragment, and a `table<BuilderRow>` linking `"if_stmt"` (a string) to `build_if_stmt`. `coherence.av:9-13` checks the names agree.
- **DB-shaped?** Half. Keywords already derive from the grammar. The merge laws (a dozen in CLAUDE.md) are prose.
- **Hand-kept:** the build name is spelled three times — grammar text, table row, fn name.

**Could:** the build call names the node, and captures are labelled by field.

```avra
stmt = "unless" cond:expression "{" ( stmts:stmt | BREAK )* "}" END -> Unless @head(cond)
```

- No builder table. No builder fn when the node is a plain capture (seam 3).
- The merge laws become **assembly refusals**, not prose. `grammar/first.av` already refuses "branches 1 and 2 both begin with STRING". Add: a recovering branch on a keyword another rule anchors; a NAME-headed branch merged before a keyword anchor.
- **Faster:** no.
- **Needs:** nothing new for the refusals. Risk: a refusal added to the assembler fires on the compiler's own grammar during the build that adds it (the second-build law).
- **Principle:** P1 — an LLM cannot hold twelve prose laws; it can read one refusal.

---

## 3. Builders and nodes

**Now** — READ `features/if_expr/builders.av:40-44`, `core/nodes.av:966-971`, `core/parts.av:14-18`.

```avra
fn build_if_stmt(b: Builder) -> Result<LangNode, string> {
    let c = b.expr(0)?          // captures by POSITION
    let t = b.stmts(1)?
    let e = b.stmts(2)?
    …
    b.make_stmt(Stmt.IfStmt(c, t, e))
}
```

```avra
fn let_name(s: StmtId) -> string? {
    match self.stmt(s) {
        .Let(name, _, _) or .MutLet(name, _, _) or .ConstDecl(name, _, _) or … -> …,
        .Assign(_, _) or .ExprStmt(_) or … or .IfStmt(_, _, _) or … -> …,     // every other variant, by hand
    }
}
```

- **Touch for one new `Stmt` variant** (COUNT of `IfStmt` mentions outside its own feature): `core/nodes.av` 1, `core/parts.av` **9**, `core/store.av` 2, `core/control.av` 1, `compiler/voices.av` 1, `compiler/format/source_text.av` 3.
- **Already derived:** seven derives sit on `Expr` and `Stmt` — `Children`, `Identity`, `Matchable`, `Exact`, `Rebuild`, `Grammar`, `ValueProtocol` (READ `core/nodes.av:325-331, 870-875`). Marks carry what types cannot say: `@declares`, `@expands`.
- **Not derived:** the nine projection registries in `parts.av`. They are the same idea — "which payload is the name, the value, the body" — spelled as or-runs.

**Could:** say the role once, on the payload.

```avra
Let(@binds name: Scoped, @written ty: TypeRef?, @value v: ExprId)
ForEach(index: Scoped?, @binds name: Scoped, subject: ExprId, @body stmts: List<StmtId>)
Unless(cond: ExprId, @body stmts: List<StmtId>)
```

`@derive(Parts)` writes `let_name`, `binding_ty`, `stmt_value` and the rest. A builder for a plain capture is derived from the labels; a hand builder stays for desugars (`if x is .V(p)` → `Match`).

- **Faster:** no. Fewer wrong programs.
- **Needs:** `Parts` — nothing new; `Children` already reads marks. Derived builders — a derive handed a type it does not sit on (the recorded retirement trigger in `features/node_scaffold.av:8`).
- **Principle:** P12. **Against P7:** nine functions vanish from the page. Kept inspectable by `avra explain let_name` printing the generated match — the same answer `Children` owes today.
- **Does not reopen:** "appended, never inserted" stands; nothing here moves a variant.

---

## 4. Node meaning dispatch

**Now** — READ `features/dispatch.av:74-90`, `features/if_expr/semantics.av:56-66`.

```avra
export fn semantics_of(d: Dispatch, e: Expr) -> dyn NodeSemantics {
    match e { …  .If(_, _, _) -> d.ifs,  .When(_, _, _) -> d.whens,  … }
}
```

```avra
fn type_stmt(mut cx: TypeCx, s: StmtId) {
    match cx.view.store.stmt(s) {
        .IfStmt(c, t, e) -> { cx.walk(c) … },
        _ -> nothing(),                       // the dispatch already proved this cannot happen
    }
}
```

- **Touch:** one arm in the map, one `Dispatch` field, one `new_dispatch` line, and one re-match per pass method.
- **DB-shaped?** No, and it should not be a relation: this is BEHAVIOR, so the exhaustive match is the registration (the seam rule).
- **Hand-kept:** every method re-matches its own node and writes a dead catch-all.

**Could:** the impl is the claim; the payload arrives typed.

```avra
impl StmtSemantics for Stmt.Unless {
    fn type_stmt(mut cx: TypeCx, at: StmtId) {
        cx.walk(self.cond)
        cx.require_bool(self.cond, "an `unless` condition", "this decides whether the body runs")
        cx.type_stmts(self.stmts)
    }
}
```

`semantics_of`, `Dispatch` and `new_dispatch` are generated: one arm per variant, read from the impls. A variant with no impl **fails the build**, naming the variant.

- **Faster:** slightly — no second match per call. ESTIMATE: not measurable.
- **Needs:** an impl over one variant (`impl T for Stmt.Unless`), new; and the foreign-type derive.
- **Does not reopen** "`semantics_of` is exhaustive by design": it stays one exhaustive match with no `_ ->`. Only who types the arms changes.

---

## 5. Declarations — the weakest seam

**Now** — READ `features/decls_mint.av:157-176`, `features/decls.av:870-891`.

```avra
let kind: DeclKind? = store.declared_kind(s)
…
let key = fresh_key("${path}::${kind_word(k)}::${name}", s, seen)
let d = self.mint(key, f, s, name, k, store.is_exported(s), "", null, false, store.fn_parts(s)?.body)
```

```avra
fn set_decl(idx: int, row: Decl) {
    …
    rs.put_owned(db, Decl.relation_name(), idx, d, d.stable_hash(), d.index_keys(), self.file_owners.get()[home.index])
    self.filed_by_name(idx, d.name, b)
}
```

- **Touch:** a feature that declares something edits `DeclKind` (`core/nodes.av:121`), `declared_kind`/`declared_name` in `parts.av`, and usually a special case inside `admit` (const :203, spec :214, impl :237, main :260, nested :284).
- **Counts (COUNT):** 15 `.mint(` call sites, each ten positional arguments. 7 hand-built string keys. 13 `set_decl` calls, most only to write `lo`/`hi` after the row exists.
- **DB-shaped?** The row type is (`@relation type Decl`, `features/decl_rows.av:39-76`). The write is not. `Decl` is keyless; the file says why (`decl_rows.av:26-31`).
- **Cost (COUNTED the same day):** on a one-edit check a declaration row is re-filed through a moved hash exactly ONCE (14,012 list entries rewritten, 13,554 of them in the `external` bool index's one big bucket); 11 of the 13 `set_decl` sites change only process-local columns and re-file nothing. A census figure of 93.8 M list writes (40 % of that check) was charged to this code by nearest symbol and is NOT it: three suspects named by reading were each acquitted by a count. The write path's case rests on clarity and one mechanism, not on that number.

**Could:** the feature answers what its statement declares; the file's rows are one returned value.

```avra
impl StmtSemantics for Stmt.FnDecl {
    fn declares(file: FileView, at: StmtId) -> List<Declared> {
        [Declared { name: self.name.text, kind: .Fn, exported: file.exported(at), body: self.body }]
    }
}

@relation(from: declarations_of)
type Decl = { @key file: string, @key owner: string, @key kind: DeclKind, @key name: string, @key sibling: int, … }

@query
fn declarations_of(file: string) -> List<Decl> { ranged(flatten([declared(file, s) for s in parsed(file).stmts])) }
```

- Ranges are computed **before** the row exists. No patching.
- The key is the tuple. No string is built.
- **Faster:** a body edit returns equal rows, so nothing is re-filed; a row written once, with its facts, never takes the second write. `Decl.by_name` becomes one index read.
- **Needs:** the hand-over (`Decl.replaced(db, owner, rows)`) is available now — three relations already use it. The tuple key waits for `file` to leave `@local` (DB 03).
- **Principle:** P12, P4. Law L6 held for the last relation that breaks it.

---

## 6. Names and resolve

**Now** — READ `features/namespace.av:323-345`, `compiler/references.av:105, 282`.

```avra
fn bind_fn(name: string, d: DeclId) {
    self.names.fns.set(name, d)          // a map
    self.names.fn_names.push(name)       // and a list beside it
}
```

- **Touch:** a feature writes `resolve` in its semantics (scopes via `cx.arm_scope`, `cx.scope_stmts`). Good shape. A new *namespace* is a `Binder` edit (three hard-coded spaces: Fn, Type, Syntax).
- **DB-shaped?** `Ref` is — references are surveyed and handed over whole (`Ref.replaced`, `references.av:105`). `Namespace` is a bespoke struct of maps plus parallel name lists.

**Could**

```avra
@query fn visible(file: string) -> List<Bound>       // Bound = { @key space: Space, @key name: string, decl: DeclName }
@query fn resolved(d: DeclName) -> NameFacts         // per declaration, not per file
```

- **Faster:** a lookup is `Bound.by_key`; an edit inside one fn re-resolves that fn. Today `Resolved` is keyed by file (`families.av`, family 5).
- **Needs:** DB 03 (names), DB 07 b (`Resolved` split per declaration). Risk: `kept_apart` and clash diagnostics depend on declaration order within a module — the query must return them, not push them (`self.clashes.push`, `namespace.av:245`).

---

## 7. Signatures and typing

**Now** — READ `compiler/typing/declare.av:1244-1259`, `compiler/workspace.av:1598-1604`, `features/facts.av:279-300`.

```avra
mut fn declare_one(x: Decl) {
    match x.kind {
        .Record -> self.declare_record(x.stmt),
        .Enum -> self.declare_enum(x.stmt),
        .Fn -> self.declare_fn(x.stmt),
        …
        .Const or .Collect or .State or .Trait or .Syntax or .Main or .Builtin -> nothing(),
    }
}
```

```avra
self.db.begin(k)
mut t = self.sign_cx_for(x)
t.declare_one(x)                              // writes decls.sigs as a side effect
self.sig_voices.keep(d.index, t.facts.voices) // and a second side table
let out: DeclSig? = self.decls.sigs.get()[d.index]
self.db.settle(k, sig_hash(out))              // a hand fingerprint
```

- **Touch:** a declaring feature adds a `declare_*` fn **in the driver** (`compiler/typing/declare.av`, 1,323 lines; `impls.av`) and an arm here. The enum's signature rule is not in `features/enums/`.
- **DB-shaped?** Keyed and memoised, yes. But the answer is read back out of a shared table it wrote into.
- **Typing a body** is in good shape: `TypeFacts` is one value per declaration with ~20 columns, behind `Workspace.typed(d)`. `cx.type(List<string?>)` is already the one way to spell a type (141 sites, COUNT).

**Could** (the DB doc's own example, §2b)

```avra
impl DeclSemantics for Stmt.EnumDecl {
    fn signed(mut cx: SignCx, at: StmtId) -> DeclSig { DeclSig.Enum(enum_sig(cx, self.variants)) }
}

@query fn sig(d: DeclName) -> Signed { signed(declaration(d)) }     // Signed = { sig, voices }
@query fn typed(d: DeclName) -> TypeFacts
```

- **Faster:** a signature's voices and value are one saved answer; a body edit never re-signs.
- **Needs:** DB 03 and DB 07 for saving. Moving `declare_*` into the feature is available now. Risk: `Decls.declare` also computes layout and marks the type settled (`decls.av:1677-1684`); those are facts about the type registry and must become part of the answer, not a write beside it.

---

## 8. Laws, diagnostics, rules

**Now** — READ `features/defers/mod.av:19-24`, `features/defers/check.av:44-52`, `features/if_expr/idioms.av:19-24`.

```avra
let codes = table<DiagCode> {
    kind               | summary
    "type.defer_inert" | "`defer` runs a call or a block — a bare value does nothing"
}
```

```avra
fn does_nothing(cx: TypeCx, s: StmtId, named: string) -> Diag {
    refusal("type.defer_inert", cx.stmt_loc(s), "`defer` runs its body later, …", "deferred here", "call something — `defer child.stop()` — …")
}
```

- **Touch:** a code row, a voice fn, a golden test. The kind string is typed twice. 27 code tables, 469 `refusal(` calls (COUNT).
- **Rules are the model seam already.** A rule is one declaration with its proof on it (`@fixes`, `@keeps`), gathered by `collect rules = rule in closure` (`compiler/rules_table.av:102`).
- **One residue:** `rules_table.av:17-67` imports ~50 rule names by hand so the closure reaches them.
- **Nothing compiles a remedy** (CLAUDE.md records two helps that named unparseable forms).

**Could:** a voice carries its code and its proof, the way a rule does.

```avra
/// `defer` runs a call or a block — a bare value does nothing.
@speaks("defer x", "deferring a value does nothing")
@remedy("defer child.stop()")                        // compiled where the refusal is spoken
voice defer_inert(named: string) at Stmt {
    "`defer` runs its body later, and this one only names a `${named}` — deferring a value does nothing"
    label: "deferred here"
    help: "call something — `defer child.stop()` — or write the work in a block: `defer { … }`"
}
```

- The kind is `<module>.<name>`, as a rule's id already is. The code table is `collect codes = voice in closure`. The golden is the `@speaks` line.
- **Faster:** `findings(d)` per declaration instead of a walk over a file's statements (`rule_pass.av:21-27`).
- **Needs:** nothing new for `voice` (it is a component, like `rule`). Risk: 469 call sites to move; do it per feature, old and new side by side.
- **Principle:** P1, P12. The doc sentence, the code summary and the docs page are one string.

---

## 9. Compile time: const, derives, `collect`

**What `collect` is today** — READ `features/collects/mod.av:37-47`, `compiler/families/families.av:149`, `packages/std-sql/src/parser.av:896`.

```avra
export collect rules: List<RuleEntry> = rule in closure as RuleEntry { name: it.name, run: it.run, … } by it.module, it.name
export collect enum Family = @family in self by it.mark.args[0] dense
```

- A statement that gathers every declaration of a component kind, or wearing an annotation, in a scope (`self` / `closure`), projects it and orders it.
- Its body is **synthesised at lowering** from the admitted declarations (`compiler/lower/lower.av:1124`). So it is a whole-program gather, done late.
- Three real uses in the tree.
- **It is a relation read that does not know it yet.** `Decl` already indexes `word` and `marks` (`decl_rows.av:54-56`).

**Could:** `collect` lowers to the index read. Per the DB doc: `Declaration.wearing(mark)`; adding a member reruns exactly the collects that asked.

```avra
// what `collect rules = rule in closure …` means
@query fn rules() -> List<RuleEntry> { [entry(d) for d in Decl.by_word(rule)].sorted_by(…) }
```

- **Faster:** a new rule in one file reruns one query, not lowering's gather.
- **Needs:** DB 07 a (buckets as named parts of an answer), DB 10 (`collect` membership). Risk: `closure` scope means "what I import", which is why the hand import list in seam 8 exists; the scope question should be answered once, in the query.
- **Derives:** fine as they are. The one law to keep: a derive stands alone in its file.

---

## 10. Lowering

**Now** — READ `features/if_expr/lower.av:7-16`, `features/emit.av:327, 360`.

```avra
fn if_lower(mut cx: LowerCx, e: ExprId) -> Reg {
    match cx.view.store.expr(e) {
        .If(c, t, f) -> {
            let want = cx.type_at(e)
            cx.region(cx.reg_of(c), e) { cx -> cx.arm_yield(t, cx.reg_of(t), want) } else { cx -> cx.arm_yield(f, cx.reg_of(f), want) }
        },
        _ -> cx.foreign_node(e),
    }
}
```

- **Touch:** one fn. This is the best seam in the tree. 69 emission verbs (COUNT), 34 instructions, runtime rows as data with a generated method each.
- **DB-shaped?** Yes at the right grain: `Unit` per declaration (`compiler/lower/lower.av:293`), behind `Family.Lowered` (`workspace_analysis.av:354`).
- **Could:** only the typed payload from seam 4 (drops the re-match and `foreign_node`). Then `@query fn lowered(d: DeclName) -> Unit`, saved.
- **Faster:** `Lowered` saved is the step the DB doc names as the first point 300 ms is reachable (§7.3).
- **Does not reopen** the IR protocol or per-instruction spec files. No new `Ins`.

---

## 11. After lowering

**Now** — READ `tools/vocab.sh` (the `CONSUMERS` table).

```sh
CONSUMERS="Ins  …/interp.av   step        spelled        its MEANING, interpreted
Ins  …/memory.av   memory_ins  spelled        its ownership effect
RtKind …/llvm.av   ll_rt_kind  spelled        the LLVM type it becomes"
```

- **Touch for a feature author:** none, unless the IR grows. Correct.
- **Hand-kept:** which enums are registries, and who consumes them, is a shell table. CLAUDE.md says why: "no grep tells a registry enum from a projection one."

**Could:** the enum says it.

```avra
@registry
export enum RtKind { I64, Ptr, Void, I32, U32, F64 }
```

The compiler refuses `_ ->` and `is .V` over a `@registry` enum everywhere (F2040 already counts answering arms). The curated table and its "a registry it does not name is unguarded" hole go away.

- **Needs:** nothing new. Risk: turning it on finds existing sites; land it as a warning with a baseline first.
- **Principle:** P10 — the compiler holds the knowledge instead of a script.

---

## 12. Tests and docs

**Now** — READ `compiler/suite.av:192-205`.

- A program test is a directory with `<name>.av` and `<name>.expected` (or `.refuses`). Spec tests sit beside. Discovery is by marker file.
- **Touch:** 2–3 files per proof.
- **Could:** short proofs ride the feature, as they ride a rule.

```avra
@runs("unless false { println(\"ran\") }", "ran")
@refuses("unless 1 { }", "type.condition")
export feature unless { … }
```

- Long programs keep their directory.
- **Faster:** with reads recorded, a test reruns only when a read of `Proved(test)` moved (DB doc §2b).
- **Docs:** `///` on the feature, the voice and the rule are already the source. They become rows (`doc_fact_rows.av` exists).

---

## 13. The tools on top

| tool | read surface it needs |
|---|---|
| **check** | `diagnostics(d)` per declaration = `sig(d).voices ++ typed(d).voices ++ lowered(d).voices ++ findings(d)`. Unchanged declarations are not asked. |
| **fmt** | `parsed(file)` and the node's own grammar form. Today the printer matches every variant by hand (`compiler/format/source_text.av:615, 1412`, 2,739 lines). With labels in the grammar (seam 2), a plain node prints from its rule. |
| **lint** | the same `findings(d)`; `rule` is the only way to write one (decided, D5). |
| **docs** | `Decl.by_kind`, `sig(d)`, `Doc.of(d)`, `codes()`, `rules()`. No walk. |
| **explain** | any answer's record: value, reads, who reads it. And for generated code (seams 3, 4): the generated text. This is what pays for the derives under P7. |

---

## The write path

Every place a pass writes a fact, by shape.

| shape | where | count |
|---|---|---|
| **returns a value** | `Ref.replaced` (`references.av:105`), `ErrorSite` and `Raised` (`failures.av:481, 615`); a file's kept ids (`decls_mint.av:323`) | 3 + 1 (READ) |
| **returns, then the driver stores** | `typed(d) -> TypeFacts`, `lowered(d) -> Unit`, `resolved(f) -> NameFacts` | 3 families (READ) |
| **inserts by hand** | `.mint(` declarations | 15 call sites |
| | `set_decl(` | 13 call sites |
| | hand string keys | 7 |
| | `X.insert(` — `File`, `Module`, `AssignRoot`, `Finding`, `Answer` | 5 (plus one derive template) |
| **mutates a shared table** | `Cell` fields on `Decls` | 69 (COUNT `: Cell<`, `features/decls.av`) |
| | `Cell` fields on `Workspace` | 48 (COUNT) |
| | `decls.sigs.set_at` + `sig_voices.keep` | per signature (READ) |
| | `Namespace` maps and parallel lists | per bind (READ) |
| | `types.intern(` — the type registry | 146 sites in 33 files (COUNT) |
| | `side_table(` constructions | 23 (COUNT) |

**The one shape:**

```avra
@query fn <fact>(key: <Name>) -> <Answer>       // a value; voices inside it
```

- A relation is `@relation(from: <fact>)`. Its rows are the answer.
- A side table keyed by node ids stays a side table — **inside** the answer that owns the ids (L4).
- The type registry is the honest exception. It is an interner: an identity, not a fact. It stays a `Cell`; what must change is that a saved answer holds type **names**, not `TypeId`s (L5).

---

## Worked example: `unless cond { … }`

### Today (ESTIMATE, from the COUNT of `IfStmt` sites)

A cheap path exists: desugar in the builder to `IfStmt(Not(c), t, [])`. Two files, two lines in `compiler/mod.av`. Its cost: `fmt` prints `if !c`, so the form is lost. `if x is .V(p)` hit exactly this and needed a side mark (`if_expr/builders.av:25-33`).

The honest path, a node of its own:

| file | edit |
|---|---|
| `features/unless/mod.av` | new — grammar, builder table |
| `features/unless/builders.av` | new |
| `features/unless/semantics.av` | new — three methods, three re-matches |
| `features/unless/lower.av` | new |
| `features/unless/tests/unless/unless.av`, `.expected` | new |
| `features/unless/tests/unless_test.av` | new |
| `core/nodes.av` | append `Unless(…)` |
| `core/parts.av` | add to 9 or-runs |
| `core/store.av` | 2 arms |
| `core/control.av` | 1 arm |
| `compiler/voices.av` | 1 arm |
| `compiler/format/source_text.av` | printer arm(s) |
| `features/dispatch.av` | field + arm |
| `compiler/program.av` | import + field |
| `compiler/mod.av` | import + list entry, in the right place |

**7 new files, 9 shared files, ~23 hand edits, ~120 lines.** Then the build ladder: a new variant changes positions the standing compiler baked in.

### Proposed (ESTIMATE): one file

```avra
//! `unless c { … }` — the guard, negated: the body runs when `c` is false.
use core.{Stmt, ExprId, StmtId, Reg}
use features.{feature, voice, rule, StmtSemantics, ResolveCx, TypeCx, LowerCx, nothing}

/// `unless cond { stmts }`.
@node(Stmt)                                                     // seam 3 — see decision 2
type Unless = { cond: ExprId, @body stmts: List<StmtId> }

@runs("unless false { println(\"ran\") }", "ran")               // seam 12
@refuses("unless 1 { }", "type.condition")
export feature unless {                                         // seam 1
    gram: grammar {                                             // seam 2 — labels are fields; no builder
        stmt = "unless" cond:expression "{" ( stmts:stmt | BREAK )* "}" END -> Unless @head(cond)
    }
}

impl StmtSemantics for Stmt.Unless {                            // seam 4 — the impl is the claim
    fn resolve_stmt(mut cx: ResolveCx, at: StmtId) {            // seam 6
        cx.walk(self.cond)
        cx.scope_stmts(self.stmts)
    }

    fn type_stmt(mut cx: TypeCx, at: StmtId) {                  // seam 7
        cx.walk(self.cond)
        cx.require_bool(self.cond, "an `unless` condition", "this decides whether the body runs")
        if self.stmts.is_empty() { cx.emit(unless_inert(cx.stmt_loc(at))) }
        cx.type_stmts(self.stmts)
    }

    fn lower_stmt(mut cx: LowerCx, at: StmtId) -> Reg? {        // seam 10 — today's verbs, unchanged
        cx.void_branches(cx.reg_of(self.cond)) { cx -> nothing() } else { cx -> cx.arm_stmts(self.stmts) }
        null
    }
}

/// An `unless` with an empty body does nothing.
@speaks("unless a { }", "an empty `unless` does nothing")       // seam 8 — code, golden and doc in one
@remedy("unless a { stop() }")
voice unless_inert() at Stmt {
    "an empty `unless` does nothing"
    label: "nothing runs here"
    help: "write the work in the body, or drop the statement"
}

/// `unless !c` is `if c`.
@fixes("unless !a { x }", "if a { x }")                         // seam 8 — a rule, as today
@keeps("unless a { x }")
export rule unless_not {
    quote { unless !${c} { ${b} } } -> quote { if ${c} { ${b} } },
}
```

Plus one word in `compiler/mod.av`'s order list.

**1 file, ~45 lines, 1 registration.** No seam 5 entry: `unless` declares nothing. Seams 9, 11 and 13 need nothing from it — which is the point.

**What a reader should not believe yet:** `@node(Stmt)`, `impl … for Stmt.Unless`, `voice`, `@runs`, `@speaks`, `@remedy` and the builder-free `-> Unless` do not exist. `feature`, `grammar { }`, `rule`, `quote`, the three trait methods and every `cx.` verb do.

---

## Order to build it

Each lands alone.

| # | step | waits for | size (ESTIMATE) |
|---|---|---|---|
| 1 | **Declarations returned as one value per file.** Ranges computed before the row; `Decl.replaced(db, owner, rows)`; `mint`'s ten arguments become a record; `set_decl` gone | nothing | medium; the perf win |
| 2 | **`@registry` on enums**; the compiler holds the law; `tools/vocab.sh`'s table retired | nothing | small |
| 3 | **Payload roles + `@derive(Parts)`**; the nine or-runs in `parts.av` generated | nothing | small |
| 4 | **`voice`** as a component; code tables collected; `@speaks` goldens; `@remedy` compiled | nothing | medium, per feature |
| 5 | **Per-kind logic moves home**: `declares` and `signed` on the feature's semantics; `admit`'s special cases and `declare_one` become a dispatch | step 1 | medium |
| 6 | **Typed-payload impls; generated `semantics_of`/`Dispatch`**; derived builders | a derive handed a foreign type; `impl … for Enum.Variant` | large; touches all 37 features |
| 7 | **`sig` / `resolved` / `typed` / `lowered` / `findings` as saved `@query`s by name**; `collect` as an index read | DB 03, DB 05–07, DB 10 | the DB roadmap's own |
| 8 | **A node declared in its feature file** | decision 2; a gathered enum with payloads and a fixed ordinal | large; the generation ladder |

Cheap now: 1, 2, 3, 4. Step 1 is also the DB's weakest point, so it comes first.

---

## Three decisions only the owner can make

### 1. How is feature order said?

```avra
// (a) one list — today's, minus everything else
export const order = [stmt_spine, closures, …, if_expr, unless, when_expr, …]

// (b) each feature says its neighbours
export feature unless { after: if_expr, before: fns, … }

// (c) derived from what the grammar anchors on, with exceptions
export feature unless { … }                      // "unless" is a keyword anchor → before every NAME-headed branch
export feature nullable { before: enums, … }     // the exceptions stay written
```

**Recommend (a).** The order is the definition of the language and CLAUDE.md says so. One list a reader can see beats a solved constraint set nobody can (P7). (c) is tempting and wrong today: the reasons in the list's comments are not all about anchors.

### 2. Where does a node live?

```avra
// (a) core/nodes.av, as today; the feature claims it by impl
Unless(cond: ExprId, @body stmts: List<StmtId>)          // one line in core

// (b) in the feature file; `Stmt` is gathered
@node(Stmt)
type Unless = { cond: ExprId, @body stmts: List<StmtId> }
```

**Recommend (a) now, (b) later.** (b) is the true one-file world. It needs `collect enum` to carry payloads and an ordinal that never moves — a rule's pattern is baked by position, so a gathered enum ordered by name would break the product on its own tree. Under (a) the worked example is one file plus one line in `core/nodes.av`.

### 3. Does the declaration hand-over wait for names?

```avra
// (a) now: rows as a value, ids still local, the string key kept inside
Decl.replaced(db, file_owner, rows)

// (b) later, once: the tuple key and the query together
@relation(from: declarations_of)
type Decl = { @key file: string, @key owner: string, @key kind: DeclKind, @key name: string, @key sibling: int, … }
```

**Recommend (a).** It is the shape three relations already have, it removes the re-filing cost without waiting on DB 03, and (b) then changes one type, not fifteen call sites. The risk in (a): the interface path also mints (`compiler/interface.av:368`), so held files and parsed files must hand over through the same door or there are two write paths again.
