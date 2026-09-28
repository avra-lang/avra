# The minimum — seams, structs, queries (2026-09-02)

Worked backwards from the smallest design that holds the feature
set. Ratified 2026-09-02 (D7–D16 in ROADMAP.md); this is the design
they ratify.

## The minimum

**One rule.** The compiler is a set of memoized queries over inputs.
An input is a file's text. Every other value is a pure function of
inputs and other queries. Values are fact tables keyed by dense
ids. Behavior lives in query functions and in features' rules;
nothing else has state.

**Seven ids, one interner each.** `FileId` (by path), `ModuleId`
(by module name), `DeclId` (by qualified key), `StmtId` and `ExprId`
(by position within a file's arena), `TypeId` (by shape), `Reg` (by
position within a body). Everything references ids, never nodes.

**Thirteen query families.** Each is one function: key in, one value
out, dependencies discovered by execution. In ordinal order — the
order `enum Family` registers them with the kernel
(`compiler/workspace.av`):

| family | key → value | what it depends on |
|---|---|---|
| `source(ws, f: FileId) -> SourceFile` | file → text | input: settles on the text's hash |
| `parsed(ws, f: FileId) -> Parsed` | file → store, statements, source, voices | source |
| `items(ws, f: FileId) -> List<DeclId>` | file → its declarations, minted into `Decls` | parsed |
| `namespace(ws, m: ModuleId) -> ModuleNames` | **module** → the names it binds, and its clashes | items of the module's files |
| `visible(ws, f: FileId) -> Namespace` | file → the names its top level sees: the module's plus its imports | namespace, items of the imported modules |
| `resolved(ws, f: FileId) -> NameFacts` | file → bindings, captures | parsed, visible |
| `sig(ws, d: DeclId) -> DeclSig?` | **declaration** → its signature (the table's own read arms it) | parsed, visible, the sigs it names |
| `methods(ws, d: DeclId) -> List<DeclId>` | type declaration → its methods | items of the modules that impl it, their sigs |
| `typed(ws, d: DeclId) -> TypeFacts` | **declaration** → the types of its body's expressions | resolved, the sigs it calls, methods |
| `folded(ws, f: FileId) -> TypeFacts` | file → every body's facts laid into one table | typed of the file's bodies |
| `analysis(ws, f: FileId) -> Analysis` | file → the facade: view, names, facts, diagnostics | resolved, folded, sig and method diagnostics |
| `lowered(ws, id: int) -> Unit` | **declaration + instantiation** (an interned `Ask`) → its bodies and what they want | analysis, typed, sigs |

`program` and `report` are NOT families: they are the `Program`
facade over the workspace — `program(ws, entry)` composes the files
and drains `lowered` to the entry's closure; `report`/`check` fold
every value's voices.

The three bold rows are the change. Typing and lowering were per
FILE before the minimum, and the four declaration rounds existed
only because typing was a batch: types before traits before fns before impls,
across all files, then bodies. With `sig(d)` a memoized query,
order is not a concern: asking a record's fields asks its sig,
which asks the sigs of the types it names, lazily; a cycle is a
diagnostic, and the kernel detects cycles. The rounds, `typer`,
`type_bodies`, `typed_together`, `Staged` — all deleted. Editing a
body re-runs one `typed` and one `lowered`; nothing that only
called it re-verifies, because its `sig` hash is unchanged. That is
15d, falling out of the minimum rather than bolted on.

**Twelve structs.** `SourceFile`, `Parsed`, `Decls` (with `Decl`,
`FileInfo`, `MethodEntry`), `Namespace`, `NameFacts`, `DeclSig`
(with the three sig kinds), `TypeFacts`, `Body`, `Lowered`, `Diag`,
`Db` (with `Key`, `Cell`), `Host`. Every one is data. The per-pass
working state (`Resolver`, `Typer`, `Lower`) is per item and
private to its query function.

**One feature contract.** A feature's rule takes a context that is
facts plus walk verbs: `TypeCx { facts, names, decls, store, types,
lang, file, error_type }` and nine verbs; `LowerCx` likewise with an
emitter and six verbs. Reads and writes are methods on the fact
structs, implemented beside them. Call sites do not change.

**Diagnostics ride values.** Every query's value carries its own
diagnostics; `report` folds them. No pass struct keeps a list of
its own; no context carries an `emit` closure.

**The language is not in the program.** `ParsedProgram` today
carries the language's keywords, method rows, type rows, property
rows and dispatch, copied into every parse. Those belong to
`Language`; `Parsed` is a store, statements, a source, diagnostics.

## The distance from today

- Contexts: 87 closures and 130 lines of wiring rebuilt per body,
  versus facts plus ~15 verbs total.
- Granularity: per file with four batch rounds, versus per
  declaration with lazy sigs — the largest cut and the largest
  payoff: it deletes the rounds, makes 15d's incrementality real,
  and makes typing and lowering parallelizable later for free.
- Pass structs: `Typing` and `Resolution` copy columns out of
  `Typer` and `Resolver` at the end; in the minimum the fact struct
  IS the value.
- Diagnostics: five separate lists and five `emit` closures, versus
  one sink per value.
- `ParsedProgram`: nine fields, four of them the language's.
- `Analysis` and `Program`: facades over the queries (tests lean on
  `analyze_source`); they hold no logic.

The one structural assumption per-item typing rests on: a
declaration's nodes occupy a contiguous range of its file's arena
(the parser builds each top-level item's subtree consecutively).
Probe it first.

**What stays.** The exhaustive `semantics_of` registration; the five
forwarding lines per feature; the ask/begin/settle bracket per
family (bs2 cannot pass a generic thunk); the columnar fact tables.

## Decisions (ratified)

- **D7** Per-declaration granularity: `sig`, `typed`, `lowered` as
  queries; the four rounds deleted.
- **D8** `Parsed` sheds the language's registries; the driver hands
  features `Language`'s rows through the context.
- **D9** Diagnostics ride query values; `report` folds; pass-owned
  lists and `emit` closures go.
- **D10** Contexts are facts plus walk verbs, reads and writes as
  methods on the fact structs.
- **D11** `Analysis` and `Program` remain as facades over queries,
  for tests and the CLI, holding no logic.

Order: D10 first (mechanical, no behavior change), then D8 and D9,
then D7 in two steps — lazy sigs, then per-item bodies and lowering.


## Further reductions (D12–D16, ratified 2026-09-02 with D7–D11)

- **D12 One view.** The five data fields every context and facade
  reads (`file`, `store`, `source`, `decls`, `types`, `lang`) are ONE
  struct, `FileView`, shared by `ResolveCx`, `TypeCx`, `LowerCx`,
  `Analysis`. Contexts become `{ view, facts, verbs }`.
- **D13 Mono's worklist is the memo.** `lowered(d, sub)` returns a
  body plus what it asked for: the lambdas it lifted and the
  wrappers it minted are ITS artifacts (they never escape the body)
  and come back with it; only specializations of OTHER declarations
  cross bodies, returned as `wants: List<Sub>`. `program(entry)`
  asks `lowered` for each want transitively; asking twice reuses.
  `Jobs`, `Spec`, `Lift`, `Wrap`, `unseen` and the 1000-step drain
  guard are deleted. Specializations are interned (`SpecId`, the
  seventh id) so a family can key by them.
- **D14 Facades hold a workspace and a key.** `Program { ws, entry }`
  and `Analysis { ws, file }` answer everything through queries;
  they hold no tables. A lone file is a workspace over a memory host
  with root "" — `under_dir(name, "")` is true for every name — so
  the separate lone pipeline (`Language.analyze`, `lone_namespace`'s
  own path, `lone_program`) is deleted. `analyze_source(text)` is
  that workspace over `{ "<source>": text }`.
- **D15 Modules have ids.** `ModuleId` (interned in `Decls`);
  `namespace(module)` is computed ONCE per module, and a file's
  `visible(file)` adds only its imports. Today each file of a module
  rebuilds the module's namespace.
- **D16 A per-file fold.** `folded(file) -> TypeFacts` folds the
  file's declarations' facts by range, for the facade's `type_at`
  and for lowering's per-file reads — a query, so it is memoized
  like the rest.

Order, amended: the CONTRACT step (D8 + D9 + D10 + D12 together —
they all touch the same contexts), gated; then the QUERY step (D7 +
D13 + D14 + D15 + D16), gated in two halves: lazy sigs and modules
first, then per-item bodies and the memo-driven closure.

## What landed (2026-09-02, the big-bang slice) and what remains

Landed: D8, D9, D10, D12 (the contract step) — `TypeCx` 4 data
fields (`view`, `names`, `facts`, `error_type`) with 11 verbs,
`LowerCx` 7 (`view`, `names`, `facts`, `out`, `body`, `sub`,
`fn_ret`) with 7, the statement contexts nesting them, every read a
method defined once on the fact structs;
`Parsed` without the language; `Voices` on every value; `FileView`.
D13 — `lower_unit` returns a body with its lifts and wrappers and
its wants; `union` asks through a memoized `unit_of`; `Jobs` is a
unit's local collector, the 1000-step guard lives in the drain.
D14 — `Program { ws, … }` and `Analysis` with a `program` closure;
`lone_workspace(path, text)` is the one lone path (root = the
file's directory, `lone` marks it for the `use` voice). D15 —
`ModuleId`, `namespace(module)` once, `visible(file)` adds imports.
D16 — `folded(file)` is the per-file fold; `typed(decl)` the family.

D7, WHOLE (the second slice, 2026-09-02): signatures are
per-declaration lazy queries — the table's own `sig` read is the
query (an `ensure` hook the workspace arms), so the four rounds are
gone; a sig reached from inside its own computation (a recursive
payload re-judging its slots) is simply not there yet, no voice —
the language has no sig that can depend on another sig's VALUE, so
a spoken cycle waits for type aliases. Bodies are per declaration
too: `typed(decl)` types one body over its own expression range,
and `folded(file)` lays every body's columns into one table (Main
first, its range spans the file; each owner over its own range;
voices in source order) for the facade and lowering. What made it
possible is THE BODY FLOOR: a fn body — and a field default — sees
declarations, never the top level's run-time bindings (resolve
refuses `resolve.runtime_binding` with the parameter remedy; before,
the read resolved and lowering hit a defect). So no body reads
another body's facts.
A field DEFAULT is a declaration (`DeclKind.Default`, keyed under
its record, a zero-parameter body answering the field's type): it
is typed once in its module and every literal that omits the field
CALLS it — which fixed a stack overflow at a cross-file literal
(the default's ExprId was lowered against the caller's store).
`Decl.root` is the expression a body IS; `has_body` gates units.

The method table is a query (`methods(decl)`): the table's `method`
and `implements` reads ask it, it asks every impl naming the type,
so a body depends on exactly the impls it dispatches through. A
type's methods are a NAMESPACE: registration is the impl block's
(under its target, in ask order), and "declared twice" is the
table's CLASH law (`method_clashes`, beside the module clash law),
spoken at the later declaration in source order, folded into that
file's diagnostics — order-independent, one voice.

The union is the ENTRY'S CLOSURE: `lower_unit` wants every body it
names (`symbol_at(decl, site)` — a call, a method, a fn value's
wrapper, a dyn box's vtable, a default), `union` seeds main alone
and drains wants; a program only CHECKED seeds every declared body,
so each speaks its refusals.

Remaining, with triggers: `methods(T)` asks `impls_named` by NAME
across the whole table (two modules each declaring a `P` over-ask
harmlessly; a resolved-target index arrives with the DB tier);
`visible`, `resolved`, `typed`, `folded`, `analysis` and `lowered`
ALL settle with the revision as their hash — no early cutoff below
the signature tier, not just on the two body families. `source`,
`parsed`, `items`, `namespace`, `sig` and `methods` settle on
content hashes, so the cutoff lives where the design put it: a body
edit re-verifies no caller, because the caller's dependency is the
unchanged `sig`. Precision below that arrives with the on-disk tier,
when a body hash is worth computing.

## The shapes

Every struct, impl and interface the minimum needs, by layer.
Long enums are elided with `...`. Layering stays one-way:
core → query → grammar → features → language → cli.

### core — ids, nodes, types, the IR

```avra
// ── ids: one interner each; everything references ids, never nodes ──
type FileId = { index: int }      // by path            (Decls.file_id)
type ModuleId = { index: int }    // by module name     (Decls.module_id)
type DeclId = { index: int }      // by qualified key   (Decls.mint)
type StmtId = { index: int }      // by arena position, per file
type ExprId = { index: int }      // by arena position, per file
type TypeId = { index: int }      // by shape           (TypeRegistry.intern)
type Reg    = { index: int }      // by position, per body
fn same_file(a, b) / same_decl(a, b)

// ── the node model: parse-owned, never accretes pass facts ──
type NodeStore = { exprs: Arena<Expr>, stmts: Arena<Stmt>, spans: ..., exported: List<bool>, ... }
enum Expr { Int(..) Str(..) Ident(..) Call(callee, pins, args) MethodCall(..) Lambda(..) Match(..) If(..) Block(..) ... }
enum Stmt { Let(..) MutLet(..) Assign(..) ExprStmt(..) FnDecl(..) StructDecl(..) EnumDecl(..) TraitDecl(..) ImplDecl(..) Use(..) Return(..) ... }
impl NodeStore {
    fn expr(e) fn stmt(s) fn expr_span(e) fn stmt_span(s)
    fn fn_parts(s) fn struct_parts(s) fn enum_parts(s) fn trait_parts(s) fn impl_parts(s) fn use_parts(s) fn lambda_parts(e)
    fn declared_kind(s) -> DeclKind?   fn declared_name(s) -> string?   fn is_declaration(s) -> bool
    fn decl_tparams(s) fn decl_tbounds(s)   fn expr_fingerprint(e) fn stmt_fingerprint(s)
    fn post_order(root) fn let_name(s) fn stmt_value(s) fn is_exported(s) ...
}

/// What a declaring statement declares; Main is a file's run-time
/// statements, one synthetic declaration per file.
enum DeclKind { Fn Record Enum Trait Method Main }

/// What a name resolves to — ids only, so it lives in core.
enum Binding { Param(int) Def(StmtId) Pattern(ExprId) LambdaParam(ExprId, int) Capture(ExprId, int) Index(StmtId) Decl(DeclId) }

// ── types ──
type TypeRegistry = { shapes: List<Type>, keys: Map<string, int> }
enum Type { Int Str Bool Null Void Error List(TypeId) Map(TypeId, TypeId) Opt(TypeId) Res(TypeId, TypeId) Fn(List<TypeId>, TypeId)
            Struct(DeclId, string) Enum(DeclId, string) App(DeclId, string, List<TypeId>) Dyn(DeclId, string) Var(DeclId, int, string) TypeName(DeclId, string) ... }
impl TypeRegistry { fn intern(Type) -> TypeId  fn shape_of(TypeId) -> Type  fn name_of(TypeId) -> string
                    fn substituted(ty, target: DeclId, args) -> TypeId  fn arrow_parts(ty) -> Arrow?  fn slot_of(..) ... }

// ── the IR: a CURATED vocabulary; six exhaustive consumers ──
type Body = { name: string, params: List<TypeId>, ret: TypeId, gives: Reg?, ins: List<Ins>, reg_types: List<TypeId> }
enum Ins { Const(..) Bin(..) Call(dst, symbol, args) CallPtr(..) CallRt(dst, name, args) FnAddr(..) Retain(..) Release(..)
           ScopeEnter(Level) ScopeExit(Reg?) RetVal(Reg) Ret(int) FnExit(Reg) SwitchStart(..) ArmEnd RegionEnd ... }
fn dst_of(i: Ins) -> Reg?
type RtSig = { name: string, params: List<RtKind>, ret: RtKind, host: RtHost, has_owned_twin: bool }
fn rt_sigs() -> List<RtSig>          // the runtime's DATA registry: one row per C fn
```

### query — the kernel

```avra
type Key = { family: int, arg: int }           // two list indexes, no strings
enum Verdict { Reuse Compute Cycle }
type Cell = { deps: List<Key>, changed_at: int, verified_at: int, value_hash: int }
type Db = { rev: List<int>, cells: List<List<Cell?>>, verifiers: List<fn(int) -> int>, frames: List<List<Key>>, open: List<Key>, hits: List<int>, misses: List<int> }
impl Db {
    fn revision() -> int  fn bump()               // the revision advances when an input changes
    fn family(verify: fn(int) -> int) -> int     // registration order IS the number
    fn set_input(key, value_hash)                 // the driver sets inputs; changed_at moves only when the hash moves
    fn ask(key) -> Verdict                        // red-green; records the dep; a key open above this ask is Cycle
    fn begin(key)  fn settle(key, value_hash)     // the bracket around a computation; early cutoff in settle
    fn any_dep_changed(cell)  fn changed_after(dep, since)  fn active(key)  fn changed_at(key) -> int  fn record_dep(key)
    fn cell(key) -> Cell?  fn write(key, cell)  fn hit()  fn miss()
    fn sweep()                                     // cells not verified this revision are dropped
    fn stats() -> string                           // `--time`'s memo line
}
// Values never live here: each family keeps its own typed table, dense by its key's arg.
```

### diagnostics

```avra
type SourceFile = { file: string, text: string, line_starts: List<int> }     // a source always has a name
type Loc = { file: string?, lo: int, hi: int }                                // a defect has no file (std-errors)
type Frame = { label: string, loc: Loc? }
enum Severity { Error Warning }
type Diag = { kind: string, severity: Severity, primary: Frame, secondary: List<Frame>, message: string, help: string?, suggestions: List<Suggestion> }
type DiagCode = { kind: string, summary: string }                             // the kind is the registry's identity
fn refusal(kind, at: Loc?, message, label, help: string?) -> Diag             // THE one voice shape (compiler.refusal_assembled)
fn error_at(kind, loc, message) -> Diag   fn defect_at(loc, message) -> Diag   fn pointed(d, label) -> Diag
fn loc_at(file: string?, s: Span?) -> Loc?   fn by_position(ds) -> List<Diag>   fn registered(codes, kind) -> bool
fn render(d, src) -> string   fn render_among(d, sources: List<SourceFile>) -> string

/// Every query value's diagnostics, one sink; `report` folds sinks.
type Voices = { list: List<Diag> }
impl Voices { fn speak(self, d: Diag)  fn heard(self) -> bool }
fn no_voices() -> Voices
```

### features — the contract

```avra
// ── declaration facts ──
enum DeclSig { Fn(FnSig) Record(StructSig) Variants(EnumSig) }
type FnSig = { params: List<TypeId>, ret: TypeId }
type StructSig = { names: List<string>, types: List<TypeId>, defaults: List<DeclId?> }   // a default is a declaration
impl StructSig { fn slot_of(name) -> int?  fn listed() -> string }
type EnumSig = { names: List<string>, payloads: List<TypeId?> }
impl EnumSig { fn tag_of(name) -> int?  fn payload_of(name) -> TypeId?  fn listed() -> string }
type Sub = { target: DeclId, args: List<TypeId> }
fn fn_sig_of(d: DeclSig?) -> FnSig?  record_sig_of  variant_sig_of        // consumers ask, never match
fn subbed_fields(types, sig, decl, args) -> StructSig?   fn subbed_variants(types, sig, decl, args) -> EnumSig?

// ── THE declaration table: every declaration once, interned ids ──
type FileInfo = { id: FileId, path: string, module_id: ModuleId }
type Decl = { id: DeclId, file: FileId, stmt: StmtId, name: string, kind: DeclKind, exported: bool, owner: string,
              parent: DeclId?, nested: bool, root: ExprId?, lo: int, hi: int }   // root: the expression a body IS; [lo, hi): its arena range
type Decls = { types: TypeRegistry, files: List<FileInfo>, paths: Map<string, FileId>,
               modules: List<string>, module_ids: Map<string, ModuleId>, module_files: List<List<FileId>>, mains: List<DeclId?>,
               stores: List<NodeStore?>, decl_ids: List<List<DeclId?>>, file_decls: List<List<DeclId>>, decls: List<Decl>, keys: Map<string, DeclId>,
               sigs: List<DeclSig?>, children: List<List<DeclId>>, methods: List<List<DeclId>>, impls: List<List<DeclId>>,
               ensure: List<fn(DeclId)>, ensure_methods: List<fn(DeclId)> }      // the two hooks: a read IS the query
impl Decls {
    fn file_id(path, module) -> FileId  fn module_id(module) -> ModuleId  fn module_name(m)  fn main_of(f) -> DeclId?  fn file(f)  fn store_of(f)
    fn admit(f, store, stmts) -> List<DeclId>   // mints top-level, methods and defaults under owners, Main, nested under `nested`
    fn range_bodies(f, store, main)  fn decls_of_file(f)  fn owns_a_range(d)  fn decl_span(d) -> Span?  fn innermost(owners, sp) -> DeclId?
    fn mint(key, f, s, name, kind, exported, owner, parent, nested, root) -> DeclId  fn mint_method(..)  fn mint_default(..)  fn orphan(parent)
    fn decl(d)  fn decl_of(f, s) -> DeclId?  fn store(d)  fn module_of(d)  fn loc(d)  fn has_body(d)  fn children_of(d)  fn default_named(record, field)
    fn sig(d) -> DeclSig?  fn arm(ensure)  fn declare(d, sig)  fn tparams(d)  fn tbounds(d)  fn is_trait(d)  fn is_enum(d)  fn type_name(d)  fn fn_name(d)
    fn symbol(d) -> string                             // THE symbol source: name under module, a member under its type
    fn trait_fns(d)  fn trait_method_names(d)  fn method(target, name) -> DeclId?  fn held_method(target, name)  fn methods_of(target)
    fn arm_methods(ensure)  fn declare_method(target, m)  fn record_impl(ty, tr)  fn implements(ty, tr)  fn holds_impl(ty, tr)
}

// ── namespaces: the one binding law, once per module ──
type Namespace = { fns: Map<string, DeclId>, types: Map<string, DeclId>, fn_names: List<string>, type_names: List<string>, voices: Voices }
type ModuleNames = { bound: List<DeclId>, clashes: List<Clash> }   // namespace(module)'s value
type Clash = { file: FileId, diag: Diag }                          // filed under the LATER declaration's file
type Import = { decl: DeclId, at: Loc? }
fn module_names(decls, ordered: List<DeclId>, shown: fn(string) -> string) -> ModuleNames
fn file_names(decls, file, module: ModuleNames, imports: List<Import>, shown) -> Namespace
fn method_clashes(decls, target: DeclId) -> List<Clash>            // a type's methods are a namespace too

// ── the view: the five data fields every context and facade reads, plus the file's statements ──
type LanguageRows = { methods: List<MethodRow>, types: List<TypeRow>, properties: List<PropertyRow>, codes: List<DiagCode> }
type FileView = { file: FileId, store: NodeStore, stmts: List<StmtId>, source: SourceFile, decls: Decls, types: TypeRegistry, lang: LanguageRows }
impl FileView { fn loc_of(e) -> Loc?  fn stmt_loc(s) -> Loc?  fn module() -> string }

// ── pass facts: data; the query values ──
type Cap = { names: List<string>, sources: List<Binding> }
type NameFacts = { bindings: List<Binding?>, captures: List<Cap?>, names: Namespace, voices: Voices }
impl NameFacts { fn binding(e) -> Binding?  fn capture(lam) -> Cap? }

/// One declaration's body, typed: columns dense over the body's
/// expression range [lo, hi) — `type_at(e)` reads `of_expr[e - lo]`.
type Asked = { subject: ExprId, on_present: bool }
type TypeFacts = { lo: int, of_expr: List<TypeId>, widens: List<TypeId?>, narrows: List<TypeId?>, asks: List<Asked?>, substs: List<Sub?>,
                   lambda_params: List<List<TypeId>?>, wants: List<TypeId?>, hungry: List<bool>, starved: List<TypeId?>,
                   pattern_types: List<TypeId?>, binding_types: List<TypeId?>, voices: Voices }
impl TypeFacts {                                    // the reads and writes — no driver, no closure
    fn type_at(e) fn set_type(e, ty) fn widen(v, ty) fn widened_at(e) fn narrow(e, opt) fn narrowed_at(e) fn record_ask(e, subject, on_present) fn ask_of(e)
    fn record_subst(e, target, targs) fn subst_at(e) fn set_want(e, ty) fn want_at(e) fn go_hungry(e) fn hungry_at(e) fn hungry_ones() fn absorb_hunger(e) fn starve(e, want) fn starved_at(e)
    fn bind_type(v, ty) fn pattern_type(v) fn record_binding(s, ty) fn declared_binding(s) fn seat_lambda(lam, tys) fn lambda_seats(lam)
    fn absorb(other)                                // another body's facts laid over its range — the per-file fold
    fn speak(d)
}

/// A body's instruction list under construction; `give` is the
/// mint-order law.
type Emitter = { ins: List<Ins>, reg_types: List<TypeId>, defined: List<Reg>, voices: Voices }   // defects speak as diagnostics
impl Emitter { fn mint_ty(ty) -> Reg  fn type_of_reg(r)  fn give(i: Ins)  fn defined_in_order(i)  fn seeded()  fn record(msg)  fn defect(what) }
type BodyRegs = { regs: List<Reg?>, slots: List<Reg?>, boxed: List<bool>, pattern_regs: List<Reg?>, index_regs: List<Reg?> }
impl BodyRegs { fn reg_at(e) fn set_reg(e, r) fn slot_of(s) fn set_slot(s, r) fn bind_slot(s, cell) fn is_boxed(s) fn pattern_reg(v) fn bind_pattern(v, r) fn index_reg(s) fn bind_index(s, r) }

// ── the contexts: the VIEW, the facts, and the verbs that need the walk's state ──
type ResolveCx = { view: FileView,                                                  // 1 data field, 6 verbs
                   use_name: fn(ExprId, string), use_call: fn(ExprId, string), use_type: fn(ExprId, string),
                   block_scope: fn(List<StmtId>, ExprId?), arm_scope: fn(string, ExprId), lambda_scope: fn(ExprId, List<Param>, ExprId) }

type TypeCx = {
    view: FileView, names: NameFacts, facts: TypeFacts, error_type: TypeId,          // 4 data fields
    // the eleven verbs that need the walk's state
    walk_type: fn(ExprId) -> TypeId,  block_type: fn(List<StmtId>, ExprId?) -> TypeId,  walk_narrowed: fn(ExprId, ExprId) -> TypeId,
    lambda_body: fn(ExprId, List<TypeId>, ExprId) -> TypeId,  retype_seated: fn(ExprId, List<TypeId>) -> TypeId?,
    target_type: fn(ExprId) -> TypeId,  enclosing_ret: fn() -> TypeId?,  behind_lambda: fn() -> bool,
    written: fn(StmtId, TypeRef) -> TypeId,  written_at: fn(ExprId, TypeRef) -> TypeId,  plant_want: fn(ExprId, TypeId),
}
impl TypeCx {                                        // methods over the facts — call sites unchanged
    fn type_at(e) fn shape_at(e) fn name_at(e) fn loc_of(e) fn stmt_loc(s) fn emit(d) fn stmt_sig(s) fn bound_decl(e) fn tparams(d) fn tbounds(d) fn sig_of(e)
    fn fields_of(ty) -> StructSig? fn variants_of(ty) -> EnumSig? fn method_sig(target, name) fn trait_sig(trait, name) fn implements(ty, trait) fn is_mut(e) fn def_type(s)
    fn bind_type(v, ty) fn widen(v, ty) fn record_ask(..) fn ask_of(e) fn record_subst(..) fn record_binding(s, ty) fn want_at(e) fn go_hungry(e) fn absorb_hunger(e) fn starve(e, want)
}

type LowerCx = {
    view: FileView, names: NameFacts, facts: TypeFacts, out: Emitter, body: BodyRegs, sub: Sub?, fn_ret: TypeId?,   // 7 data fields
    // the seven verbs that need the walk
    reg_of: fn(ExprId) -> Reg,  lower_block: fn(List<StmtId>, ExprId?) -> Reg,  def_reg: fn(ExprId) -> Reg?,  lift: fn(ExprId) -> string,
    capture_regs: fn(ExprId) -> List<Reg>,  symbol_at: fn(DeclId, ExprId) -> string,  indirect_callee: fn(ExprId) -> Reg?,
    // symbol_at: a declaration's body as instantiated at a site — WANTED on first sight, so the program is the entry's closure
}
impl LowerCx { fn viewed(ty) fn type_at(e) fn shape_at(e) fn result(e) fn mint_like(r) fn mint_shape(sh) fn mint_ty(ty) fn emit(i) fn fail(msg) fn defect(what) fn enclosing_ret()
               fn callee_of(e, name) fn fields_at(e) fn fields_of(ty) fn variants_at(e) fn variants_of(ty) fn bind_pattern(v, r) fn cell_of(e) }

// the statement contexts NEST the expression context; the view rides both
type StmtResolveCx = { view: FileView, facts: NameFacts, in_block: bool,
                       walk: fn(ExprId), walk_under: fn(List<Param>, ExprId), bind_checked: fn(StmtId), check_params: fn(List<Param>, StmtId),
                       scope_stmts: fn(List<StmtId>), bound_scope: fn(StmtId, List<ExprId>, List<StmtId>), impl_stmts: fn(List<StmtId>),
                       binding_of: fn(string) -> Binding? }                                   // 3 data fields, 8 verbs
impl StmtResolveCx { fn walk_value(s)  fn loc_of(s)  fn emit(d) }
type StmtTypeCx   = { view: FileView, expr: TypeCx, walk: fn(ExprId), walk_under: fn(StmtId, ExprId), type_stmts: fn(List<StmtId>), bind_declared: fn(StmtId, TypeRef) -> TypeId }
impl StmtTypeCx   { fn walk_value(s)  fn loc_of(s)  fn sig_of(s)  fn binding_type(s)  fn record_binding(s, ty) }
type StmtLowerCx  = { view: FileView, expr: LowerCx, lower_stmts: fn(List<StmtId>) }
impl StmtLowerCx  { fn lower_value(s) -> Reg?  fn bind_slot(s, cell)  fn bind_index(s, r) }

// ── features ──
trait NodeSemantics { fn kids(e) -> List<ExprId>  fn heirs(e) -> List<ExprId>  fn resolve(cx: ResolveCx, e)  fn type_of(cx: TypeCx, e) -> TypeId  fn lower(cx: LowerCx, e) -> Reg }
trait StmtSemantics { fn resolve_stmt(cx: StmtResolveCx, s)  fn type_stmt(cx: StmtTypeCx, s)  fn lower_stmt(cx: StmtLowerCx, s) -> Reg? }
type LanguageFeature = { name: string, gram: string, builders: List<BuilderEntry>, rows: LanguageRows }   // the manifest: component + tables
type Builder = { store: NodeStore, ... }  impl Builder { fn token(i) fn tokens(i) fn expr(i) fn stmt(i) fn make_stmt(..) fn make_expr(..) ... }
```

### language — the driver and the families

```avra
type Language = { features: List<LanguageFeature>, grammar: Grammar?, keywords: List<string>, rows: LanguageRows, dispatch: Dispatch, diagnostics: List<Diag> }
type Parsed = { store: NodeStore, stmts: List<StmtId>, source: SourceFile, voices: Voices }      // the language is not in the program
fn parse_program(lang, src) -> Parsed
type Dispatch = { ...one instance per feature's semantics... }
fn semantics_of(d: Dispatch, e: Expr) -> dyn NodeSemantics       // THE exhaustive registration — stays
fn stmt_semantics_of(d: Dispatch, s: Stmt) -> dyn StmtSemantics

// ── the workspace: the families' value tables, sparse by their keys; `sigs` and `methods` live in Decls ──
type Host = { exists: fn(string) -> bool, read: fn(string) -> string, list: fn(string) -> List<string>, is_dir: fn(string) -> bool }
type Workspace = { host: Host, root: string, lang: Language, db: Db, decls: Decls,
                   programs: List<Parsed?>, file_items: List<List<DeclId>?>, module_names: List<ModuleNames?>, visibles: List<Namespace?>,
                   name_facts: List<NameFacts?>, sig_voices: List<Voices?>, decl_facts: List<TypeFacts?>, method_clashes: List<List<Clash>?>,
                   folds: List<TypeFacts?>, analyses: List<Analysis?>, specs: Map<string, int>, asks: List<Ask>, units: List<Unit?>,
                   defects: List<Diag>, lone: bool, clock: fn() -> int, phases: List<Phase> }
type Phase = { name: string, ns: int }

/// THE FAMILIES, in pipeline order; `ordinal` and `refetched` are
/// exhaustive, so a family cannot ship half-registered.
enum Family { Source Parsed Items Namespace Visible Resolved Sig Methods Typed Folded Analysis Lowered Manifest }
// Manifest is keyed by package: an INPUT (the toml's text hash) read into a Manifest value; packages are the root's manifest and every path dependency reachable from it, admitted once by key
fn key(f: Family, arg: int) -> Key   fn ordinal(f) -> int   fn families() -> List<Family>
fn refetched(ws, f: Family, arg: int) -> int        // the kernel's ONE verifier: re-ask the key through its own query
fn placed<T>(xs: List<T?>, i, v)  fn placed_at<T>(xs, i) -> T?   // core: the sparse tables' two verbs
fn new_workspace(host, root, lang)   fn lone_workspace(path, text, lang)   fn timed_workspace(host, root, lang, clock)
impl Workspace { fn timed(name, ns)  fn defect(message) }
fn file_id(ws, path) -> FileId
fn source(ws, f: FileId) -> SourceFile              // input
fn parsed(ws, f: FileId) -> Parsed
fn items(ws, f: FileId) -> List<DeclId>
fn namespace(ws, m: ModuleId) -> ModuleNames       // once per module
fn visible(ws, f: FileId) -> Namespace             // the module's names plus the file's imports
fn resolved(ws, f: FileId) -> NameFacts
fn sig(ws, d: DeclId) -> DeclSig?                  // lazy; the table's `sig` read is armed to it
fn methods(ws, d: DeclId) -> List<DeclId>          // the impls naming the type, registered under it
fn typed(ws, d: DeclId) -> TypeFacts               // one declaration's body; Main is the file's statements
fn folded(ws, f: FileId) -> TypeFacts              // every body's facts in one table, for the facade and lowering
fn analysis(ws, f: FileId) -> Analysis
fn lowered(ws, id: int) -> Unit                    // one interned Ask: a declaration under an instantiation
fn analyze_all(ws) -> List<Analysis>  fn analyze_file(ws, path) -> Analysis  fn surface(ws, m: ModulePath) -> Map<string, DeclId>
// per-item working state, private to its query:
type Typer    = { error_type, lang, view: FileView, names, facts, narrow_defs, narrow_params, fn_ret: List<TypeId>, lam_bar, tscope }
type Resolver = { lang, view: FileView, facts: NameFacts, all_defs, def_names, visible, overlays, lframes, floors, walked, scoped }
type Lower    = { a: Analysis, fn_ret: TypeId?, sub: Sub?, jobs: Jobs, out: Emitter, body: BodyRegs }

// ── facades: no logic, for tests and the CLI ──
type Analysis = { view: FileView, names: NameFacts, facts: TypeFacts, lang: Language, diagnostics: List<Diag>, program: fn() -> Program }
impl Analysis { fn clean() fn report() fn rendered(ds) fn binding(e) fn type_at(e) fn type_name(e) fn run() fn check() fn lowered() fn ran() -> string? }
type Program = { ws: Workspace, files: List<Analysis>, entry: int?, phases: List<Phase>, cache: string, defects: List<Diag> }
fn program(ws, entry: string?) -> Program
impl Program { fn entry_file() -> Analysis? fn clean() fn report() fn rendered(ds) fn lowered() -> Lowered fn lowered_checked() fn run() fn check() }   // voices: the packages' (manifests, then the graph); clean() means no ERRORS — warnings render and never block
fn analyze_source(text) -> Analysis   fn parse_source(text) -> Parsed

// ── lowering: a unit at a time, the union the entry's closure ──
type Body = { name: string, params: List<TypeId>, ret: TypeId, gives: Reg?, ins: List<Ins>, reg_types: List<TypeId> }
type Lowered = { fns: List<Body>, entry: Body, types: TypeRegistry, diagnostics: List<Diag> }
type Wanted = { file: FileId, decl: DeclId?, name: string, sub: Sub? }   // the unit of lowering: a body (main when decl is absent), instantiated, in its file
type Unit = { bodies: List<Body>, wants: List<Wanted>, voices: Voices }  // what one unit lowered to, what it wants of others, what it said
fn lower_unit(ask: Ask) -> Unit
fn union(decls, files, entry: int?, unit_of: fn(Ask) -> Unit) -> Lowered    // seeds main (or every body, when only checked) and drains wants

// ── engines: functions of Lowered ──
fn memory(lo) -> Lowered   fn run_lowered(lo) -> Result<string, string>   fn render_ir(lo) -> string   fn emit_ll(lo, path) -> string?
```

### cli

```avra
fn disk_host() -> Host
fn program_at(args) -> Program?                       // a directory is a root with no entry; a file is entered
fn on_program(args, act: fn(Program) -> int) -> int   // the one prologue
fn lowered_or_report(p) -> Result<string, string>     // analyze, refuse with the report, or write the `.ll` — emit and build share it
fn timings(p, own, own_ns) -> string                  // `--time`: phases, the command's own, the memo's hits and misses
fn file_command(name, description)  fn arg_command(name, description, args: List<ArgDef>)  fn bare_command(name, description)   // the three CommandSpec shapes
fn <name>_command() -> Subcommand                      // one file per command; main.av composes the list
```
