# C2 — consumers of the compiler's fact/query/cache layer (origin/main 05fe643)

Tree: `/Users/tristan/projects/tristanMatthias/avra-db-design` (`T` below). Paths are relative to `T/packages/std-avrac/src/` unless they start with `packages/` or `docs/`.
All line numbers MEASURED by reading the file at 05fe643. Nothing was built or run.

## 0. The substrate every consumer sits on (FIVE addressing schemes, not one)

| # | Mechanism | Where | Address | Lifetime | Invalidation |
|---|---|---|---|---|---|
| A | Kernel cell `(family, arg)` | `query/kernel.av:20` `export type Key = { family: int, arg: int }`; verbs `ask/begin/settle/abandon/record_dep` (kernel.av:353-559) | dense int | one process | red/green: `changed_at`/`verified_at`, deps recorded per frame |
| B | `Relation<DbRow>` typed value table per family | `query/memo.av:31` `export type Relation<T> = { kernel: Kernel, family: int, values: Table<T> }`; `input` (:128) / `demand` (:161) / `start`+`finish` (:59,:83) | `(Family, int)` via `Workspace.relation(fam)` (`compiler/workspace.av:810`) | one process | kernel |
| C | `Db` durable rows | `compiler/db.av:580` `fn get(store: Store, kind: DbKind, name: string) -> DbRow?`, `:591 fn insert(store: Store, row: DbRow)` | `(DbKind, string name)` — 8 durable kinds `Decl, Sig, Warn, Scan, Canon, Licenses, Findings, Answer` (db.av:361) | across processes (`Stored.Rows`) | `still_valid` (db.av:660): only `Decl` re-checks witnesses; the other 7 "hold unconditionally" — validity is in the caller's key |
| D | Content store | `compiler/store/store.av:21` `enum Stored { Sig Fp Unit Obj Bin Warn Rows }`; `keep(family, key, bytes, read: List<string>)` (:126), `get` (:118), `has` (:104), `place` (:189) | `(Stored, content-digest key)` + `.deps` edge file | on disk `.avra-cache` | key IS content; edges are the commit |
| E | `@std/relation` rows (`RelDb`) | `packages/std-relation/src/relation.av`; generated `T.get/all/insert/by_<index>/prior/by_key` (relation.av:619-869); `@query` (query.av), `@input` (input.av) | typed row id, `@index` buckets, `@key` | process; `@query` answers durable through `Durable` doors (`compiler/answers.av:12`) | bucket hash per name; owner-run sweep |
| F | Workspace's string-keyed per-build memo maps | `compiler/workspace.av:120` `type Keys = { bytes_keys…, view_parts…, object_keys…, text_digests…, compiler_id… }`, `Records` (:269), `Hold` (:186), `asks/lift_asks/settle_asks` (:351-359), `module_names_of/files_of/import_lists` | ad-hoc string | one process | hand-cleared ("Cleared piecemeal by `keep_interfaces`", workspace.av:117) |

db.av itself names F as "a THIRD addressing scheme neither `Memo`'s dense arg nor `Db`'s witnessed name was built for" (db.av:253-260).

Families (kernel ordinals) are declared as `@family(rank, key, answer)` markers and collected by the language's own `collect enum`:
`compiler/families/families.av:149` `export collect enum Family = @family in self by it.mark.args[0] dense` — 32 families (ranks 0..31, families.av:16-147).

Compiler relations on `RelDb` today (grep `^@relation` over std-avrac/src, MEASURED):

| Relation | File:line | Indexes | Storage |
|---|---|---|---|
| `Decl` | features/decl_rows.av:39 | `name, word, marks, key, home, external` (decls.av:112-117) | rows |
| `DeclAt` | features/decl_rows.av:86 | — | `@side` |
| `File`, `Module` | features/file_rows.av:13,21 | `path`, `module`; `name` | rows |
| `DocFact` | features/doc_fact_rows.av:14 | — | `@side` |
| `Ref` | features/decls.av:383 | `decl`, `file` | rows |
| `Expr`, `Stmt` | core/nodes.av:332,876 | — | `@arena` |
| `AssignRoot` | features/code.av:1061 | `owner` | rows |
| `ErrorSite`, `Raised` | compiler/failures.av:102,118 | `owner` | rows (own `failures_db`) |
| `Finding` | compiler/findings.av:12 | `rule`, `file` | rows (a fresh `new_findings_db()` per ask, findings.av:19) |

`@query` fns in the compiler: exactly two — `named_decls`, `exported_decls` (compiler/doc_rows.av:13,20). `@input` fns: two — `file_text`, `env_value` (compiler/inputs.av:21,30).

---

## 1. `collect`

**WHAT.** A declaration that gathers every declaration of a kind in a scope into one typed, ordered value (or enum). `features/collects/mod.av:1-6`: "every declaration of `kind`, in `scope`, as one typed, ordered value … no code contributes by hand, a declaration of the kind IS its contribution."

```avra
// features/collects/tests/collect_order_dense/collect_order_dense.av:5-20
fn migration(_what: Named, _id: int) {}
@migration(2)
fn third() {}
type Entry = { name: string, mark: MarkInfo }
collect steps: List<Entry> = @migration in self as Entry { name: it.name, mark: it.mark } by it.mark.args[0] dense
```
Real uses in the compiler: `compiler/rules_table.av:102` `export collect rules: List<RuleEntry> = rule in closure as RuleEntry { … } by it.module, it.name`; `compiler/families/families.av:149` (`collect enum Family`); `packages/std-sql/src/parser.av:896` `collect sql_sources: List<RuleSource> = @grammar_rule in self …`.

**WHERE.** `features/collects/{mod,builders,check,order,semantics}.av`; gathering door `features/decls.av:1585-1637`; synthesis `compiler/lower/lower.av:1058-1175`; admission `compiler/whole.av:148-158`; const-interaction laws `features/consts/check.av:35-62,135-175`.

**READS — a Db-relation index read, already.**
- `features/decls.av:1585` `fn gathered(word: string, scope: CollectScope, owner: FileId) -> List<Decl> { self.admit_scope(scope, owner); [d for d in self.indexed(word) if self.collectible(d, scope, owner)] }`
- `features/decls.av:1592` `fn gathered_by_mark(name: string, scope: CollectScope, owner: FileId) -> List<Decl>` → `indexed_by_mark` → `filed(marks_index, name)`.
- `features/decls.av:1338` `fn filed(i: int, v: string) -> List<Decl> { let rs = self.decl_row_rows.get(); [self.decl(x.id) for x in rs.members(rs.bucket_of_text(i, v))] }` — doc: "the bucket read **unrecorded**, each row read through `decl`, which records it."
- Per-member projections: `decls.annotations_of(d.id)` (order.av:57), `decls.doc_of`, `decls.short_module_of`, `decls.file(d.file).path` (order.av:87-93).
- Scope is a post-filter in Avra, not an index: `in_scope` (decls.av:1627) compares `package_of_file(d.file)` per row.

**CONTRIBUTES.** A `.Collect`/`.CollectEnum` declaration (binds at mint, semantics.av:13-17); its const type via `cx.view.decls.record_const_type(cx.view.file, s, declared)` (check.av:32); 15 diagnostic kinds (mod.av:17-33); a synthesized `Body` at lowering (`lower_collect`, lower.av:1063). No rows are inserted — the collect's value is recomputed from `Decl` buckets each time.

**CROSS-FILE/PACKAGE.** Scope forces admission as a side-effect hook: `admit_scope` (decls.av:1601) calls `(self.ensure_package.get())(owner)` once per package (memo `self.scoped`), and the whole-program pre-pass does it eagerly so "no file is first minted inside a query that already read the relation" (whole.av:145-147, :155-156 `let scope = p.store.collect_scope(s); if scope != null { self.decls.admit_scope(scope!, f) }`). `closure` = "everything admitted — ACROSS PACKAGES, EXPORTED DECLARATIONS ONLY" (decls.av:1616-1621).

**CACHE/INVALIDATION.** No cache of its own. The member list is re-derived at each of FOUR call sites of `gathered_members` (check.av:52, :212, :229; lower.av:1121 via `ordered_collect_members`) — the same bucket is read and re-filtered up to 4× per collect. Invalidation rides the kernel: each `decl(x.id)` read records the row's NAME bucket (`row_read`, decls.av:1003-1014). The MARK/WORD bucket itself is read unrecorded (decls.av:1335-1336), so a NEW member under an existing mark invalidates the collect's reader only through whatever else it read — **NOT VERIFIED** whether an added `@migration` fn in an already-admitted file re-runs a warm in-process reader; in the one-shot CLI it is moot, and across processes the hold decides (a held collect is a stub: `collect_stub`, lower.av:550; interface line `"collect\t${self.const_type_wire(d)}"`, interface.av:419).
- A held file's collect carries NO value: "a held collect's interface carries no value" (lower.av:1049) — the answer type is re-derived (`collect_answer_type`, lower.av:1054) and the body is a stub linked against the kept object.

**OUTSIDE READS.** None directly (admission reads files through the host).

**PAIN POINTS (from the code).**
- `it.line` designed, not built: "no line index is wired to this projection yet" (check.av:22-24).
- Component field names unchecked at typing: "this door has no component signature in hand, only its word … a name that misses is `field_named`'s DEFECT at lowering" (check.av:124-129).
- Closure fold caught only for a direct by-name read: "a helper fn hiding the read is outside what this catches cheaply" (consts/check.av:57-59).
- `AVRA_STUB_DEBUG` probe left in `unlowered_stub` (lower.av:501) — a held collect once "referenced a symbol" nothing lowered (lower.av:497).
- `by` keys are kept as ONE text and re-decoded (`order_path`, order.av:17-24) on every compare.

**IDEAL CALL.** `db.index(Decl.marks, "migration").within(scope, owner).ordered(by)` — one recorded bucket read (bucket = dependency), scope an indexed column (`package`), result memoized per `(collect DeclId)` as a kernel cell so check and lower share it.

---

## 2. The idiom `rule` engine

**WHAT.** `rule name { quote { pattern } [if guard] -> quote { rewrite } | fix_fn(...) }` — a `component rule` instance; `avra check` reports hits as `warning[<module>.<rule>]`, `avra fix` applies proven rewrites, `avra check --baseline` ratchets, `avra rules --json` lists.

```avra
// compiler/idioms.av:16-21
@fixes("pointed(error_at(\"E1\", at, \"bad\"), \"here\")", "refusal(\"E1\", at, \"bad\", \"here\", null)")
@keeps("refusal(\"k\", at, \"m\", \"l\", null)")
export rule refusal_assembled {
    quote { pointed(error_at(${kind}, ${at}, ${msg}), ${label}) } -> quote { refusal(${kind}, ${at}, ${msg}, ${label}, null) },
}
```

**WHERE.** `features/rule.av` (component), `compiler/idioms.av` (1540 lines) + each feature's `idioms.av`, `compiler/rules_table.av`, `compiler/rule_pass.av`, `rule_fix.av`, `rule_delete.av`, `rule_proof.av`, `rule_examples.av`, `features/code.av` (the `Code` handle), `compiler/findings.av`, `compiler/licenses.av`; CLI `packages/cli/src/commands/{check,rules,fix,idiom_baseline}.av`.

**HOW CANDIDATES ARE FOUND.**
1. The table is a `collect`: `compiler/rules_table.av:102` `export collect rules: List<RuleEntry> = rule in closure as RuleEntry { … } by it.module, it.name`.
2. Indexed once per process: `rules_table.av:113` `export once fn rule_index() -> RuleIndex { rules_indexed(rules) }`; `RuleIndex = { roots: List<int>, at_root: List<List<RuleEntry>>, anywhere: List<RuleEntry> }` (:110).
3. One walk per file: `rule_pass.av:21` `export fn rule_candidates(a: Analysed, stmts: List<StmtId>) -> List<Candidate>` → `every_at(store, At.Stmt(s))` (post-order over `store.kids_at`, rule_pass.av:40-43) → `index.at_node(store.shallow_at(at), store.kind_at(at))` (:55) → `r.run(code_at(a, at))` (:60). Design line: "nodes touched, never nodes × rules" (rule_pass.av:3).
4. A site carrying `// LICENSED <id>:` is dropped (`site_licenses`, rule_pass.av:69-72).

**FACTS A RULE READS — through `Code { of: Analysed, at: At }` (features/code.av:59), ~60 verbs.**

| Verb | API underneath | Kind of read |
|---|---|---|
| `type()`, `declared()`, `binding()` (code.av:328-346) | per-declaration `TypeFacts`/`NameFacts` side tables (`Analysed.facts/.names`) | pass fact table |
| `callers()` (code.av:520) | `self.of.view.decls.callers(d)` → `Ref` relation (`@index decl`) | **Db relation index** (whole-program; forces `refs_ensured`) |
| `unused_import_decls()` (code.av:741) | `decls.refs_in_file(file)`, `decls.used(r.decl)`, guarded by `decls.refs_are_incomplete()` | **Db relation**, with an "unsure" escape when files are held |
| `write_roots()` → `assign_roots_at` (code.av:1067) | `AssignRoot.by_owner(view.assign_roots(), d)` — a private `@relation` built by walking `view.store.stmt_ids()` once per file (code.av:1077-1081), cached on `FileView` | own per-file relation + bespoke arena walk to fill it |
| `fingerprint_siblings()` (code.av:473-484) | `for e in self.of.view.store.expr_ids()` comparing `expr_fingerprint` | **bespoke whole-FILE walk per call** (O(n) per candidate ⇒ O(n²) per file for `duplicated_literal`-style rules) |
| `forces()`, `reads()`, `writes()`, `local_uses` (code.av:496-545) | bounded walk of `local_range()` | bespoke bounded walk |
| `enclosing_decl` (code.av:1025) | `decls.expr_owner(file, e)` → `DeclAt` `@side` relation; non-Expr falls back to `enclosing_decl_scanned` = "linear innermost-span rescan" (code.av:1047-1053) | relation for Expr, bespoke scan for Stmt/Pat/Field/Param |
| `doc()`, `annotations()` | `DocFact` | relation |

**CONTRIBUTES.** `Diag`s (kind = `rule_id`, rule_pass.av:86-95), each with a `Suggestion` edit for Rewrite/Delete; `Finding` rows (`findings.av:13` `@relation export type Finding = { @index rule: string, @index file: string, text: string }`) — but into a THROWAWAY Db: `findings_of` does `let db = new_findings_db()` per ask (findings.av:18-22), then flattens to TSV.

**CACHED/HELD.** Three layers, all string/TSV:
- Per file, content store: `rules_key(okey)` = rendered text and `findings_key(okey)` = TSV rows, both under `Stored.Warn`, keyed by the file's OBJECT key (derive.av:138-146); written `store.keep_once(Stored.Warn, findings_key(okey), rules.rows)` (derive.av:765). "kept only by a derivation that wants diagnostics" (derive.av:135-137). A held file whose rules rows are missing is force-read (`unruled`, derive.av:399; `Reads.Unruled` "a check wants its rule findings, and none were kept", record.av:786).
- Per program, durable Db rows under the program key: `DbRow.Warn`, `DbRow.Licenses`, `DbRow.Findings` (db.av:300-319), written together in `checked` (derive.av:244-246).
- `rule_index()` is a process-lifetime `once fn`.
No kernel cell exists for "this file's rule findings": the rules pass is not a family (families.av has none), so in-process incrementality = none; cross-process = the per-file object key.

**OUTSIDE READS.** `current_source` re-reads the file's bytes through the declared `@input file_text` (findings.av:45-48; inputs.av:21) to trim the cited line — the ONE compiler use of `@input`.

**PAIN POINTS.**
- `inputs.av:8-15` RECORDED TRIGGER: `FileWitness`/`current_file_digest` (db.av) "answer the same question by hand … folding the two into one door needs `@relation`/`@query` wired to THAT `Db` … not yet built."
- The baseline needs relative `file`+trimmed `text` (idiom_baseline.av:30-31) — identity of a finding is a source LINE TEXT, not a node/decl key.
- `refs_are_incomplete()` (code.av:742): with held files the `Ref` relation cannot answer "no use anywhere", so rules silently answer empty — "unsure is never unused" (code.av:731-733).
- A rule's own pattern must be skipped by the walk (`quote_pattern`, rule_pass.av:32-39) — "a PRECISION bug".
- CLAUDE.md "A NODE VARIANT IS APPENDED": the `shallow` fold names kinds by POSITION, baked into the building compiler.

**IDEAL CALL.** A real family `Findings(FileId) -> List<Finding>` settled into ONE program-wide `Finding` relation (`Finding.by_rule(db, id)`, `Finding.by_file(db, path)`), durable by the same witness door as everything else; `Code.fingerprint_siblings()` = `db.index(Expr.fingerprint, fp)`.

---

## 3. `avra docs` (and the "docs site")

**WHAT.** `avra docs` = every exported symbol of the package the command stands in (`--json`: `{address, kind, signature, prose_lines, package}`); `avra docs <name>` = a diagnostic kind's summary + its witness, or a declared name's `///` doc + `@name(args)` annotations. There is NO docs-site generator on main: `packages/site` is a runtime `@std/http` + `@std/ui` server (`packages/site/src/site.av:19` `export server site { port: 8788 … }`), it reads no compiler facts.

```avra
// packages/cli/src/commands/docs.av:73-82
fn explained_decl(name: string, json: bool) -> int {
    let root = here()
    let ws = root_workspace(root)
    let store = ws.opened_store()
    let compiler = ws.compiler_id()
    mut d = fresh_db()
    let cached? = d.decl(store, db_qualified(root, compiler, name)) else { return derived_decl(d, store, root, compiler, name, json) }
```

**WHERE.** `packages/cli/src/commands/docs.av`; `compiler/program.av:375-466` (`explain_annotation`, `explain_doc`, `dumped_decls`); `compiler/doc_rows.av` (two `@query`s); `features/doc_fact_rows.av`; `compiler/db.av` (`DocFacts`, `FileWitness`, `still_valid`).

**READS.**
- `@query named_decls(db: RelDb, name: string) -> List<DocKey>` (doc_rows.av:13-16) — body is `[doc_key(db, d) for d in Decl.all(db) if d.name == name]`: a FULL SCAN of the `Decl` relation although `Decl.by_name` exists and is used two lines later by `keyed_decl` (doc_rows.av:34-38).
- `@query exported_decls(db: RelDb) -> List<DocKey>` (doc_rows.av:20-23) — full scan, filter `exported && !Builtin`.
- `DocFact.get_db(db, decls.doc_facts, decls.doc_facts_side, decl.id.index)` (program.av:409, :449) — `@side` relation.
- `decls.sig(d.id)?.fn_sig()` (program.av:463) — the `Sig` kernel family, per exported decl.
- Diagnostic kinds: `avra().rows.codes.find(it.kind == name)` (docs.av:29) — the language registry, not the Db.

**CONTRIBUTES.** One durable row per looked-up name: `d.insert_decl(store, db_qualified(root, compiler, name), DocFacts { root, answer, listing_digest: current_listing_digest(root), files: [FileWitness { path: f, digest: current_file_digest(f) } …] })` (docs.av:93-103).

**CACHED.** `DbRow.Decl` — the ONLY durable row with a real witness re-check (`still_valid`, db.av:662-663: listing digest + every file digest). Hit = "no program built at all" (docs.av:68-70); it runs on a `fresh_db()` "deliberately before a `Workspace` is built" (db.av:560-564) — yet `root_workspace(root)` is still constructed to get `opened_store()`/`compiler_id()` (docs.av:75-77). The dump path is uncached: "A pure read, deliberately: caching each row into `Db` … would need the same collision grouping … without an O(n²) scan … left for whoever needs it next" (docs.av:119-124).

**OUTSIDE READS.** `current_listing_digest(root)` lists and digests every `.av` path under `src/` (db.av:675-691); `current_file_digest` re-reads each witnessed file (db.av:694) — on EVERY warm hit.

**PAIN POINTS.** (i) witness is "not yet the general recorded-dependency walk a RESOLVED-type answer would need" (db.av:45-49); (ii) the witness names only the declaring file (`files: [decls.file(decl.file).path]`, program.av:414) — an annotation whose meaning lives elsewhere is not witnessed; (iii) `explain_annotation`'s doc still says "`avra explain @name`" (program.av:375) — **no `explain` command exists** (see §7); (iv) `named_decls` ignores its index.

**IDEAL CALL.** `db.ask(Docs, name)` — a durable query whose witness is the recorded read-set (name bucket + DocFact rows + sig cells) rather than a hand-listed file list; the dump = `Decl.by_exported(db, true)` joined to `DocFact`.

---

## 4. `avra check` holds, `avra build` kept binaries, `avra run`

**WHAT.** `check` = all diagnostics for a file/package; unchanged program ⇒ "costs a hash". `build` = native/wasm binary, reused when inputs match. `run` = the evaluator over the lowered program (wasm target shells to a build).

```avra
// compiler/derive.av:220-226
fn checked(entry: string?) -> Result<Checked, string> {
    if self.nothing_to_check() { fail self.rendered_shape([no_source(self.root)]) }
    let store = self.opened_store()
    let under = Keyed { named: "check:${entry ?? ""}", beside: [] }
    let key0 = self.program_key(under.named, under.beside)
    let kept: string? = self.db.warn(store, key0)
```

**WHERE.** `compiler/derive.av` (`checked`, `derived`, `Attempt`/`Turn`, `says`, `file_said`), `compiler/build.av` (`program_key`, `kept_binary`, `compiler_print`, `closure`, `embeds`), `compiler/modules.av:275` (`build_inputs`), `compiler/record.av` (1605 lines: module records, `KeyParts`, `PartMoved`), `compiler/interface.av`, `compiler/verify_held.av`, `compiler/kept_settle.av`, `compiler/cache_walk.av`; CLI `check.av`, `build.av`, `run.av`, `phase.av`, `shared.av`.

**TWO-LEVEL HOLD.**

| Level | Key | Value | Where |
|---|---|---|---|
| PROGRAM | `program_key(named, beside)` = digest(`compiler_id()`, relative entry, every `build_inputs` path + `text_digest`, every remembered embed line, every reached package object digest) (build.av:589-609) | `DbRow.Warn/Licenses/Findings` (check) or `Stored.Bin` + `Stored.Warn` + `links` (build) | derive.av:226-236; build.av:495-507 |
| FILE | object key `okey` over `KeyParts` (file text, the runs it read, seen modules' interfaces — record.av) | `Stored.Obj`, `Stored.Sig` record, `said_key`/`rules_key`/`findings_key` under `Stored.Warn`, asks/homes/clean under `Stored.Unit` (derive.av:133-192) | derive.av `stands_in` (:344), `file_hold` (:358) |

- `build_inputs(named)` (modules.av:275-289): every `.av` under every package in `closure(named)`, each `avra.toml`, plus the compiler's own `Makefile` + `backend/*.{c,h}` + `runtime/*.{c,h}`. So a program-level hit requires hashing EVERY source file of the closure each time (`text_digest`, build.av:646-652 — "always read and hashed fresh"; the stamp shortcut was removed, avra-8sb5.57.19/.25).
- `closure(named)` is REMEMBERED because "the key is asked before anything is read" (build.av:509-514): `Stored.Unit ["closure", root, named]`, grow-only — "over-covering costs a rebuild, under-covering is a silently wrong binary."
- `compiler_print` (build.av:296-310): digest of the compiler's own binary + codegen mode + build mode; the whole store root sits under it (build.av:193-199), and every durable key folds it again.
- A file is HELD (not parsed) when its record + rows stand; reasons a file is read anyway are an enum `Reads` (`.BodyAsked`, `.Reached`, `.Unruled`, …) surfaced by `avra cache held` / `--time` (derive.av:112-118).
- Retry loop: `again`/`attempted`/`tried` with `Turn` (derive.av:30, :407-446) — a hold found unsound mid-derivation ("adrift", "unheld") restarts the whole workspace (`anew`).

**FACTS READ.** The whole kernel pipeline (`analysed` → every family), through `Workspace` verbs; held files answer through record text (`Records` maps, workspace.av:269-310) and the `HeldSig` family (families.av:104).

**CONTRIBUTES.** All diagnostics; durable rows `Warn`, `Licenses`, `Findings`; store rows `Obj/Sig/Bin/Unit/Warn`.

**`avra run`.** `phased(args, "lower+run", ran)` (run.av) → `on_program` → a `Program`; no kept answer of its own (NOT VERIFIED beyond run.av:1-13 + phase.av:9-12); a `--target` run builds (kept binary path).

**PAIN POINTS (code).**
- `Checked.findings: string?` — "A missing row reads as UNKNOWN, never as EMPTY" (derive.av:232-235); the three rows are written non-atomically (derive.av:244-246).
- CLAUDE.md "A `check` HIT ON `.avra-cache` EXAMINES NOTHING" — second-binary cross-hit hazard; mitigated by `compiler_id` in the key.
- `Keys` is "Cleared piecemeal by `keep_interfaces`" (workspace.av:113-118) — hand invalidation.
- `Workspace` method "trips F2010" licences (voices.av:673, :677) — free state verbs kept because of a compiler defect.
- Program-key inputs include the engine's C sources (modules.av:270-274) because "nothing else would put them in the key".

**IDEAL CALL.** `db.durable(Checked, entry)` whose validity = recorded input set (files, embeds, env, manifests, objects, compiler print) checked by ONE witness verb; file-level hold = the same verb at `(Typed|Lowered|Findings, FileId)`.

---

## 5. `avra test` — suite cache and the light phase

**WHAT.** One linked binary per package ("suite") holding every `spec` case and every program test; `.expected` programs also run in the evaluator first; `.refuses` programs run as children; binaries are run by a re-exec of `avra` ("light phase").

```avra
// compiler/suite.av:62-68
let under = Keyed {
    named: "suite:${only ?? ""}",
    beside: [beside(path, "expected") for path in programs],
}
let binary = joined_path(joined_path(self.root, "build"), "suite")
let kept = self.kept_binary(self.program_key(under.named, under.beside), binary)
if kept != null { return .Ok(kept! with { refuses: refuses }) }
```

**WHERE.** `compiler/suite.av`, `compiler/suite_entry.av`, `packages/cli/src/commands/test.av`, `packages/cli/src/stage.av`, `commands/refuses.av`.

**READS.** Discovery is a filesystem predicate, not a fact: `program_tests()` = `[f for f in self.root_files() if self.expects_text(f)]` with `expects_text(path) = self.host.exists(beside(path, "expected"))` (suite.av:138-143); `is_program` is asked by the entry law too (suite.av:151-154). Spec cases come from each file's `Said.cases` (derive.av:63), i.e. the per-file hold row `said_key(okey)`. Rule examples: `self.rules_checked()` only when `self.manifest(0).name == "@std/avrac"` (suite.av:53-58).

**CACHED.**
- Suite binary: the SAME `program_key`/`kept_binary` door as `build` (suite.av:67), `.expected` files as `beside` inputs.
- Evaluator agreement per program: `Stored.Unit` key `proved_key` = `["proved", path, <expected text>, digests of seen_files]` (suite.av:184-190), value "" (`keep_once`, :128). `seen_files` = every file of every module the program's module sees (suite.av:174-179) — text digests, "a BODY moves a run, so an interface digest would not do".
- Per-file case list: `said_key(okey)`.
- Light phase: no cache; runs every staged binary; `first_red` stops at the first failure (stage.av:77).

**OUTSIDE READS.** `.expected`, `.refuses`, `.native-only` marker files (`host.exists`/`host.read`); child processes; env (`soundness_wanted`, stage.av:70).

**PAIN POINTS.** "A quarrel under a hold is asked again of the sources" (suite.av:110-111, :120-123) — the hold is distrusted and the whole derivation re-run `from_sources`; `refuse_eval` must use `from_sources(null, Want.Binary)` because "AN EVALUATION NEVER HOLDS A FILE WHOSE BODY IT CALLS" (stage.av:33-42). Nested package roots each build a fresh `Workspace` (`nested_at`, suite.av:40-43).

**IDEAL CALL.** `db.durable(Proved, program)` with read-set = bodies the run ENTERED (the kept-settlement line model, §8) instead of every file of every seen module; test discovery as an index: `File.by_proof(db, .Expected)`.

---

## 6. `avra fmt`

**WHAT.** Canonical print of a file from its PARSE (never analysis); `--check` = `fmt(x) == x` tree-wide; `--write` gated on the lossless/canon receipt.

```avra
// packages/cli/src/commands/fmt.av:79-83
fn canon_key(ws: Workspace, f: FileId, text: string) -> string {
    digest_of(
        "fmt.canonical\n${ws.compiler_id()}\n${block_word_key(ws, ws.block_words(f, ws.parsed(f)))}\n${text}",
    )
}
```

**WHERE.** `packages/cli/src/commands/fmt.av`; `compiler/workspace.av:1051-1123` (`formatted_source`, `write_checked_source`, `canon_defect`); `compiler/format/*`.

**READS.** Kernel families only: `ws.source(f)` (`Family.Source`, an INPUT, workspace.av:1130), `ws.parsed(f)` (`Family.Parsed`), `ws.block_words(f, parsed)` — the sublanguage words the file's `use` lines import (workspace.av:1279) — and each provider file's `ws.source(...)` text (fmt.av:98). No relation, no typing.

**CONTRIBUTES.** Durable `DbRow.Canon(name, "")` — presence-only (db.av:305-307): `ws.db.insert_canon(store, key, "")` (fmt.av:281).

**CACHED.** Content-addressed and self-validating: key = digest(compiler print, block-word names + PROVIDER FILE TEXTS, the file's own text). Hit skips print but NOT the parse: `canon_key` itself calls `ws.parsed(f)` to compute block words (fmt.av:81) — so "A cache hit answers without a parse or a print" (fmt.av:255) is contradicted by the key derivation one function up. **NOT VERIFIED by running**; read from the two cited lines.
- One `Workspace` per package root (`fold_groups`, fmt.av:203); the compiler print is shared by `seed_compiler_id` (build.av:179) to avoid re-hashing the binary per package.

**OUTSIDE READS.** File bytes; writes the file under `--write`.

**PAIN POINTS.** CLAUDE.md records the 2.5-minute-per-file cost when fmt asked for a `FileId` through typing; the dependency on provider block words had to be added by hand to the key ("§6.5, avra-8sb5.57.9.6", fmt.av:75-78) — a hand-maintained read-set.

**IDEAL CALL.** `db.durable(Canonical, FileId)` — the read-set (own Source cell + provider Source cells) recorded by the kernel while `parsed(f)` runs, instead of re-derived in `block_word_key`.

---

## 7. References / LSP-shaped asks, and every CLI command

**`explain` DOES NOT EXIST.** `packages/cli/src/main.av:34-57` composes exactly: `check ir emit build run test docs rules repr writes process expand fmt fix language runtime_header runtime_namespace diagnostics new attack cache dev`. No `explain`, `hover`, `definition`, `census` command; no LSP server. CLAUDE.md's "`explain @name` and `explain process`" is stale: the surviving pieces are `Program.explain_annotation/explain_doc/explain_repr/explain_writes` (program.av:380,404,477,500) reached by `docs`, `repr`, `writes`; `process` is its own command. `census` is `make census` (a tool), and `@census(n)` is a planner marker (`packages/std-meta/src/meta.av:289`).

| Command (file under `packages/cli/src/commands/`) | One line | Reads compiler facts? Through |
|---|---|---|
| `check` (check.av) | all diagnostics; `--baseline` ratchet | YES — `Workspace.checked` → durable `Warn/Licenses/Findings` rows, else full derivation |
| `build` (build.av) | native/wasm binary; `--verify_held` | YES — `program_key`/`kept_binary`, else derivation; `verify_held.av` re-derives and compares |
| `run` (run.av) | evaluate a program | YES — `Program` via `phased` |
| `test` (test.av + ../stage.av, refuses.av) | suites, light phase | YES — §5 |
| `docs` (docs.av) | doc of a name / export dump | YES — §3 (`Decl` relation `@query`s, `DocFact`, durable `Decl` row) |
| `rules` (rules.av) | the rule table, `--json/--markdown` | compiled-in `rules` collect value (`RuleEntry`, `rule_id`, `declared_law`) — no Workspace |
| `fix` (fix.av) | apply proven rewrites | YES — `rule_candidates` + IR proof (`rule_fix.av`, `rule_proof.av`) |
| `fmt` (fmt.av) | canonical print | YES (parse only) — §6 |
| `expand` (expand.av) | file with generated decls inlined | YES — `ws.expanded(f)` (`Expanded` family), `provenance_of` |
| `ir`, `emit` (ir.av, emit.av) | IR text / LLVM module | YES — `Program` → lowering |
| `repr` (repr.av) | a type's runtime representation | YES — `TypeRegistry` + `decls.struct_type_ref` (program.av:477-486) |
| `writes` (writes.av) | seat-0 write-flow chain | YES — `Receivers` whole-program family + `write_chain` (receivers.av:383); name lookup `decls.named_rows(fn_name).find(...)` (program.av:502) "BY BARE NAME … answers for whichever one the name's bucket holds first" |
| `cache` (cache.av) | `why/dependents/changed/held` | YES — the kernel graph itself: `db.settled_keys()`, `db.deps_of(key)` (db.av:618-621), `cache_walk.av:138` `reached_from`, `:176` `readers`; "Each mode reads as a check would and keeps NOTHING" (`Keeping.Aside`, store.av:63-66) |
| `dev` (dev.av) | wasm dev server + watch | `ws.build_inputs(entry)` as the watch set (dev.av:292); `mounts_a_page` |
| `diagnostics` (diagnostics.av) | error-index witnesses | language registry + runs each witness |
| `language` (grammar.av) | print assembled grammar | `avra().syntax` — no Workspace |
| `new`, `attack` | scaffolds / generated adversarial tests | registry / grammar model, no Db |
| `process` (process.av) | manifest `[process]` tools | `read_manifest` directly (not the `Manifest` family) |
| `runtime-header`, `runtime-namespace` | registry projections | `core.runtime_header` — no Db |

**The References relation.**
- Row: `@relation export type Ref = { @local @index decl: DeclId, @local @index file: FileId, @local at: At, kind: UseKind }` (features/decls.av:383-384); `UseKind { Call, MethodCall, Read, Write, Import, TypeUse }` (:377).
- Reads: `fn refs_of(d: DeclId) -> List<Ref> { (self.ensure_refs.get())(); Ref.by_decl(self.refs_db.get(), d) }` (decls.av:2081-2084); `callers/readers/writers/used/refs_in_file` filter that list in Avra (decls.av:2087-2123).
- Fill: ONE unit kernel cell `key(Family.References, 0)` (references.av:74) rebuilt WHOLE into `new_refs_db()` (references.av:94) and swapped in (`settle_refs`, decls.av:2127) — not per-file incremental, despite the doc line "filled per file … replaced whole when the file changes" (references.av:3-4).
- Walks to fill it, per file (`file_refs`, references.av:166-185): `0..store.exprs.count()` once for `expr_refs` (:171) and twice more in `template_refs` (:196, :199); `store.stmt_ids()` three times (:173, :177, :178).
- Held files: rows restored from the module record's `ref` lines (`restored_refs`, references.av:124-130); the position is LOST — `Ref { …, at: At.Stmt(StmtId { index: 0 }), kind }` (references.av:149). With no store attached and held files present the relation is marked incomplete (references.av:107).
- Guard, not a dependency: asking during typing TRAPS — "defect: the references relation settles after typing" (references.av:83-88).

**Sibling whole-program passes with the same shape** (unit cell + `all_decls()` scan + clear-and-refill side columns): `Receivers` (receivers.av:45-60), `Failures` (failures.av:453-460; relations `ErrorSite`/`Raised` in a private `failures_db`), `ReadReach` (workspace_analysis.av:218-230).

**IDEAL (LSP).** `Ref.by_decl(db, d)` already is the "references" ask; `definition` = `Resolved` facts at a node; `hover` = `Sig`+`DocFact`. What is missing is (a) per-file ownership of `Ref` rows (the mechanism exists: `put_owned` + file-run sweep, decls.av:955-964), (b) a stable `at` for held rows, (c) one front door instead of `Program.explain_*`.

---

## 8. Derives / annotations, const settlement, templates, sublanguages, `embed`

**WHAT.** An annotation `@name(args)` calls fn `name` over the declaration at compile time; the fn's ANSWER TYPE is its effect (`packages/std-meta/src/meta.av:21-31`): `List<Diagnostic>` validates, `void` records, `List<Directive>`/`Declared` generates, `Derived` runs a trait's `derive`.

```avra
// packages/std-relation/src/tests/plugin_guide/plugin/src/todos.av:10-11, 21-24
@relation
export type Todo = { id: int, @key title: string, @index owner: string, done: bool }
@query
export fn open_for(db: Db, owner: string) -> List<Todo> {
    [t for t in Todo.by_owner(db, owner) if !t.done]
}
```

**WHERE.** `compiler/expand.av` (1115 lines), `compiler/workspace_analysis.av:380-790` (`settled`, `lifted`, `run_lowered_for`), `compiler/kept_settle.av`, `compiler/settlement_wire.av`, `features/crossing.av`, `features/quote/*`, `features/sublang/*`, `features/consts/*`, `features/annotations/*`, `compiler/backend/interp.av` (the evaluator).

| Sub-consumer | Reads (API) | Contributes (door) | In-process cache | Cross-process |
|---|---|---|---|---|
| Declares/Derives expansion | `ws.expanded(f)` (expand.av:95): `self.parsed(f)`, `self.visible(f)`, `self.decls.decls_of_file(f)` → `declared_work` | declarations minted "idempotent by the generated key" (expand.av:93-94); `Decls.speak_expansion` voices; provenance rows | `Family.Expanded` via `start_recursive`/`finish` (expand.av:101-117) — a re-entry gets "a SMALLER view (an empty expansion for the resolve in flight), never a trap" (:96-100) | the file's object-key parts include "a run it read" (answers.av:5); generated decls ride the module record |
| One lift (annotation run) | `lifted(d, f, s, call, args)` (workspace_analysis.av:691): `run_lowered_for` lowers the annotation fn and everything it reaches; `crossed_decl` reads "the PARSE store only" (expand.av:809-811); args via `crossed_arg` | `Lifted { answer: MetaVal, heap }` | `Family.Lifted`, key = position in `lift_asks`, interned by the string `"lift\$${f.index}\$${call.index}\$${d.index}"` (workspace_analysis.av:695) — dense ids, process-local | coarse FILE read-set: `read_by(reader, paths)` → `hold.runs` (workspace_analysis.av:473-475; `recorded_reads` :482-489) |
| `type_named` / `type_exported` (a derive ASKING the compiler) | closure handed to the evaluator: `(nm: string) -> ws.type_named_lifted(f, nm)` (workspace_analysis.av:639,681,771) → `self.visible(f).type_decl(name)` or `self.decls.module_decl(module, name)` (expand.av:901-906) → `crossed_lifted` | a `MetaVal` `Type` | none of its own (rides the enclosing `Lifted` cell's recorded deps) | `type_named_lifted` does NOT call `read_by` — the file a `type_exported` reaches "need not [be] import[ed]" (meta.av:359-361), so whether its edit un-holds the asking file is **NOT VERIFIED** |
| `const` settlement | `settled(f, root, seats)` (workspace_analysis.av:451) → `Family.Settled` keyed by `settle_id` interned on `settle_symbol` = `settled_symbol(own, seats)` (:506-523; one derivation for key AND artifact name, per CLAUDE.md) | `Settlement`; static data | `Family.Settled`, `Family.ConstTyped` | **kept settlement** (kept_settle.av): `Stored.Unit` value + `"${key}#lines"` witness lines of SIX hand-coded kinds `u c m f b e` (kept_settle.av:171-180), each re-checked by `kept_row_stands` |
| Templates / `quote` | parse-time; `copied(f, file, at, fills, seat)` (expand.av:690) re-reads the TEMPLATE's origin file store; spans are origin offsets (`spanned_elsewhere`) | spliced nodes into the consumer file's arena (`Generation` runs, decls.av:1136-1151) | part of `Expanded`/`Parsed` | via the run's file read-set |
| Sublanguages `grammar { }` / `component` words | `parsed(f)` = `parsed_under_blocks(f)` (workspace.av:1152-1157, :1210): first `plain_parsed` (`Family.Plain`), then `block_words(f, p)` from each `use` line's provider (`provided_words(path)`, :1373) | block-expanded nodes wearing the library's origin | `Family.Parsed` whose "hash folds the words in, so a dependency's grammar appearing re-parses" (workspace.av:1147-1150); per-build maps `Records.grammar_scanned/component_scanned/component_names/block_named/block_rows` (workspace.av:284-300) | durable `DbRow.Scan` (digest of compiler print + file text → "1"/"0", voices.av:686-690); block words in the module record |

**`embed` (PR #282, `04a6a89`, 2026-10-05) — BESPOKE, three hand-wired places, no general input mechanism.** Read from the diff (`git show 04a6a89`):
1. **Program key.** New `embeds_key(named) = node_key(Stored.Unit, ["embeds", self.root, named])`, `embeds(named)`, `keep_embeds(named)`, `embed_said(path)`, `embed_line(path)` (build.av:538-567); `kept_key` gained `self.keep_embeds(under.named)` (build.av:574) and `program_key` gained `.concat([self.embed_line(f) for f in self.embeds(named)])` (build.av:592-595). The list is REMEMBERED from the last derivation "as the closure is, and for its reason — the key is asked before anything is read" (build.av:540-543). What counts as an embed is derived negatively: `[path for path in self.decls.file_paths() if !self.reads_as_source(path)]` (build.av:555) — every admitted File row that is not an `.av` source.
2. **Kept const verdict.** `Settled` grew an `embeds` list; `keep_verdict` appends a line `["e", path, self.embed_said(path)]` (kept_settle.av:151) and `kept_row_stands` grew the arm `"e" -> r.length == 3 && self.embed_said(r[1]) == r[2]` (kept_settle.av:178).
3. **Admission.** `admit_embeds(p)` walks EVERY expression of the file — `for e in p.store.expr_ids()` — pattern-matching a call spelled `embed` with one string literal (`embed_literal_at`, whole.av:452) and mints a File row (`self.minted_file(path)`, whole.av:171-178), "so a const's own Settled-family query never mints a late row mid-read" (whole.av:161-164). The law itself is a host verb added for it: `Host.beneath: fn(string, string) -> Beneath` (host.av, diff).
The commit message itself calls it provisional: "The build-time sources design replaces `embed` with source handles where the package is its own argument." A FIRST kept binary with no remembered embed list is safe only because the list is written by `kept_key` in the same derivation that keeps the binary (build.av:572-576).

**PAIN POINTS.** `@derive(Unwrap)` abandoned on `DbRow`: "a DIFFERENT SUBSET of them resolve as undefined each time … a real recursive-expansion correctness issue" (db.av:262-273); derive-isolation law (a derive file stands alone with `@std/meta`, relation.av:41-44; decl_rows.av:3-5); a Declares annotation's args must be literals (expand.av:122-126); `lift_failed` once silent on the Declares path (expand.av:735-737); the THREE distinct witness schemes now live: `DocFacts.files` (db.av:118-123), kept-settlement lines (kept_settle.av), `KeyParts` (record.av).

**IDEAL CALL.** `db.input(FileText, path)` / `db.input(Env, name)` as first-class kernel inputs that any query (a lift, a settlement, a parse) reads and that EVERY durable answer's witness automatically includes — so `embed` is `db.input(FileText, placed)` and items 1–2 above disappear.

---

## 9. Manifest loading, package admission, `[link]` rows

**WHAT.** `avra.toml` per package; path dependencies; `@std/*` admitted on first `use`; `[link]` rows give objects/search/libs/raw.

```avra
// compiler/packages.av:234-236, 143-149
fn reaches(from: Package, k: string) -> bool {
    k == from.key || self.depends_on(from, k) || self.std_admitted(k)
}
fn std_admitted(key: string) -> bool {
    let dir? = self.host.std_dir(key) else { return false }
```

**WHERE.** `compiler/packages.av`, `compiler/host/manifest.av` (742 lines), `compiler/host/host.av`, `compiler/whole.av:300-390` (link words), `compiler/modules.av` (`build_inputs`, `closure`), `compiler/link.av`.

**READS.** `fn manifest(i: int) -> Manifest` — a kernel INPUT: `self.relation(Family.Manifest).input_loaded(i, () -> { let text = self.host.read(path); Loaded { value: DbRow.Manifest(read_manifest(new_source_file(path, text))), fingerprint: fp_str(text) } })` (packages.av:48-70). Key = the package's ORDINAL in `package_rows` (a `Cell<List<Package>>`, workspace.av:~388), i.e. admission order.
- But two readers bypass the family and read the TOML again by hand: `manifest_objects(root)` — "read fresh and not through `manifest(i)`'s ordinal — a closure root has no ordinal before analysis admits it" (build.av:624-630) — and CLI `process` (`read_manifest` directly).

**CONTRIBUTES.** `Package` rows pushed into `package_rows` (packages.av:154-169) — a plain list, NOT a relation; `package_voices` diagnostics; admission is a side effect of the `reaches` QUESTION (`std_admitted` enters a package while answering a bool).

**CACHED.** In-process: `Family.Manifest`. Cross-process: manifests are `build_inputs` (modules.av:285); the admitted package SET is the remembered grow-only `closure` row (build.av:515-535).

**OUTSIDE READS.** `host.exists/read/absolute/std_dir`; **env through a bare extern**: `[link]` `${NAME}` holes are filled by `avra_host_env(name)` (whole.av:547-556, extern at workspace.av:109) — not through the declared `@input env_value` (inputs.av:30), and the VALUE is in no key: `program_key` covers the manifest TEXT and object digests, `links_unchanged` (build.av:326-330) covers linked FILES' digests; a changed `-L${LLVM_PREFIX}/lib` or `-l` word is covered by neither (inferred from build.av:589-609 + whole.av:326-332; **NOT VERIFIED by running**).

**PAIN POINTS.** CLAUDE.md's recorded trigger: manifests still declare `@std/*` rows until the seed carries the resolver; "one directory under two spellings" paid by comparing `host.absolute` (packages.av:130).

**IDEAL CALL.** `Package` as a `@relation` (`@key key`, `@index root`), `Manifest` keyed by package KEY not ordinal, `db.input(Env, name)` for link holes.

---

## 10. The ORM / `@model`, `@relation`, `@query` (std-db, std-relation, std-sql, std-sqlite)

`docs/2026_09_24_ORM.md` is NOT on main (not in `T/docs`; it is an untracked file in the stale `avra` checkout only — git status shows `A docs/2026_09_24_ORM.md` there). `docs/2026_09_26_COMPILER_DB_TOWNHALL.md` likewise not in `T/docs` although `compiler/inputs.av:1` cites "townhall §7.2".

| Package | What it is | Runtime-only? |
|---|---|---|
| `@std/db` (`packages/std-db/src/db.av`, 385 lines) | `@model` on a record ⇒ generated `impl`: `static fn table_name()`, `create_table_sql()`, `create_table(mut db: Db)`, `fn insert(mut db: Db) -> Result<T, ModelError>`, `static fn find(db: Db, id: int) -> Result<T?, SqlError>`, `fn update`, `fn delete` (db.av:100-140). First field must be `id: int = 0`; only mark `@unique` (db.av:49). | YES — SQLite at run time. **No typed query surface**: no filters, joins or index lookups beyond `find(id)`. |
| `@std/relation` (3218 lines) | `@relation` on a record ⇒ in-memory typed rows: `T.insert(db, ..seats)`, `T.get(db, id)`, `T.all(db)`, `T.by_<field>(db, v)` per `@index`/`@unique`, `T.by_key(db, k)`, `T.prior(db)`, `fn stable_hash()`, `fn encoded() -> Bytes` / `static fn decoded(b: Bytes)` (relation.av:515-974). Marks: `@key @unique @index @local @dense @arena @side`. `@query` (query.av) memoizes a fn per argument hash and reruns after a write to a relation it read; `@input` (input.av). | NO — **the compiler itself uses it** (the 12 relations in §0; `Decls` holds `decl_rows: Cell<RelDb>`; `hooked_db` wires its `Hooks` to the kernel via `relation_hooks(kernel)`, workspace.av:571). |
| `@std/sql` | a SQL parser (`parser.av`, itself using `collect sql_sources … = @grammar_rule in self`, :896) | runtime library |
| `@std/sqlite` | the C binding (`Db.open`, `Stmt`, `tx`) | runtime |

Declaration and call site (`@model`), `packages/std-db/src/tests/landing/landing.av:13-18, 37-41`:
```avra
@model
type Account = {
    id: int = 0,
    @unique email: string,
    balance: int,
}
…
    mut db = modeled(Db.open(path()))?
    modeled(Account.create_table(db))?
    let a = Account { id: 0, email: "ada@example.com", balance: 100 }.insert(db)?
    let inserted = word(modeled(Account.find(db, a.id))?)
```

**The typed query surface that DOES exist is `@std/relation` + the comprehension PLANNER** (`features/lists/plan.av:1-10`): "a comprehension over a relation's rows is a query. When a head scans a `@plans_all` accessor and a filter conjunct … compares its row's field to an invariant value — `r.f == v`, or `r.f.contains(v)` over a list field — and a sibling `@plans(f)` lookup exists, the head reads that lookup's rows instead … a join narrows its inner scan per outer row … A scan left whole over a relation whose `@census(n)` counts past `scan_floor` rows names the field an index would answer." Markers: `plans_all`, `plans`, `looks_up`, `census` (meta.av:274-289).
- So filters = comprehension `if`; joins = nested heads; indexes = `@index` + planner; ordering/aggregation = ordinary list verbs (no relational ordering/group-by).
- `Hooks` (std-relation/src/db.av:57-67) is the seam to a host kernel: `family`, `record`, `revision`, `reader`, `refused`, `opened`, `settled`, `running`, `moved` — all `int`-typed so "the Db never names" its owner.
- Durable `@query` answers: `Durable { answer, keep }` doors, implemented for the compiler by `Db.answers(store, parts: KeyParts)` (answers.av:12-19) into `DbRow.Answer` keyed `"${file}\t${query}\t${args}"`.

**PAIN POINTS.** `Decl` is keyless — "RECORDED TRIGGER: `@key (file, owner, name, sibling)` arrives when `file` stops being `@local`" (decl_rows.av:26-31); ids are `@dense` process-local so no row survives a process by identity; scope/`package` is not a column; `Finding` rows live in throwaway Dbs; a float / named type / type parameter column is refused unless `@local` (relation.av:23-26).

---

## 11. UI host generation / wasm

**WHAT.** `@std/ui` views compile to native or `wasm32` (reactor) and talk to a JS host through a generated op table.

**COMPILE-TIME FACT READS.**
- The `View` derive asks the compiler for six library types by module: `type_exported(tree_module, "Prim")`, `"Attribute"`, `"EventKind"`, `type_exported(style_module, box_name)`, `"Style"`, `stand_name` (`packages/std-ui/src/tree/view.av:281-286`) and `type_named(written)` (:486) — the `avra_type_named` crossing (§12). `@composes(Stand)` on the trait (view.av:59) makes every bodied component derive it with nothing written.
- `runtime/dom/wire.gen.js` is GENERATED, but not by the compiler's cache layer: `tools/ui_host.sh:5` "Regenerate: build/avra run packages/std-ui/src/realize/dom/tests/host/host.av > runtime/dom/wire.gen.js", checked by `make ui-host` (Makefile:673). A committed artifact with a keeper — outside every key.
- `avra dev`: `mounts_a_page(ws)` = `ws.all_files(ws.packages()[0].src).any((path) -> ws.imported_by(path).any(it.text() == web_module))` (dev.av:56-60) — a bespoke walk of every root source's `use` lines; the watch set is `self.lister.build_inputs(entry)` (dev.av:292) — the program key's own input list reused as a file-watch list; the JS glue dir is found beside the binary (`glue_dir`, dev.av:256).

**CACHED.** wasm builds get their own store: the build MODE (`"${target}+reactor+opt+debug"`, build.av:435-439) folds into `compiler_print` so "each mode reads from a store of its own" (build.av:445-451). Package C for wasm = manifest `wasm_objects` (whole.av:342).

**OUTSIDE READS.** glue files (`read_bytes`), `wasm-opt`/linker tools, `@std.io.watch`.

**PAIN POINT.** The dev loop needs "every file the build reads" and gets the OVER-approximate `build_inputs` closure (whole packages + engine C sources) because the real read-set is not queryable.

**IDEAL.** `db.inputs_of(Built(entry)) -> List<Input>` — the recorded read-set, for both the key and the watch.

---

## 12. `packages/std-meta` — what a plugin sees and can ASK

File: `packages/std-meta/src/meta.av` (549 lines, single file). Exports (MEASURED by `grep -n "^export "`):

| Group | Names (line) |
|---|---|
| Reflection DATA handed IN | `Kind` enum (:52), `Seat` (:90), `Param` (:142), `Fn` (:152: `name, params, answer, at, answers: Kind, doc, annotations, owner`), `Mark` (:164), `Annotation` (:172), `Site` (:189), `Field` (:198), `Variant` (:206), `Type` (:219: `name, fields, variants, at, doc, annotations, module, over: Kind, …`), `Named` (:260), `Trait` (:263) |
| What a plugin ANSWERS | `Diagnostic` (:228) + `refuse/refuse_as/refuse_as_at/refuse_at/warn` (:231-255), `Directive { twin, name, at, source: Decls?, wraps }` (:494), `Declared { made, problems }` (:516), `Derived { made }` (:527), `derive(what: Named, tr: Trait) -> Derived` (:547), `wrapped(f)` (:504), `traced` (:521), `deprecated` (:267) |
| Code as a tree | `Node` enum (:373), `Code/Stmts/Arms/Decls/Format` (:413-424), `name/literal/interpolated/list_of/template/text_node/as_code/as_stmts/as_arms/as_decls/int_node/bool_node/name_node/int_name/names_node/code_nodes/stmts_nodes/arms_nodes/decls_nodes` (:433-473), `applied(a, value)` (:176) |
| MARKERS the compiler reads (empty-bodied fns) | `plans_all`, `plans`, `looks_up`, `census` (:274-289), `dense` (:295), `composes` (:305), `identity` (:312), `bracket` (:320), `plain_field` (:327), `lacks` (:332) |
| **Verbs that ASK THE COMPILER** | **exactly three**: `embed(path: string) -> string` (:338, `extern fn avra_embed`), `type_named(name: string) -> Type?` (:352), `type_exported(module: string, name: string) -> Type?` (:362) — the last two are ONE extern, `extern fn avra_type_named(name: string) -> Type?` (:42), the module form passed as `"${module}.${name}"` (:364) |

**Can a derive ask "all types annotated `@model` in the program"? NO.** There is no enumerating verb. A derive sees ONE declaration (its first seat) and can look up ONE named type at a time. The only program-wide gather is the `collect` DECLARATION (`collect xs: List<T> = @model in closure as T { … } by …`), which is not callable from inside a derive, yields a run-time value (folding a closure collect at compile time in a library is refused: `collect.closure_fold`, collects/mod.av:31), and projects only `name/module/file/doc/mark` for an annotated kind (collects/check.av:26, :130-133) — or the whole crossed `Fn/Type/Named/Trait` via bare `it` (`crossed_lifted`, expand.av:868-876).

**Can it ask "all impls of trait T"? NO.** The compiler-internal answer exists only as a full scan: `fn implementors_of(tr: DeclId) -> List<DeclId> { [x.id for x in self.all_decls() if implements_kind(x.kind) && self.implements(x.id, tr)] }` (features/decls.av:2623-2625). Not exposed to `@std/meta`.

Rules (not derives) have a wider read vocabulary — `Code.callers()`, `.type()`, `.annotations()`, `.declaring()` (features/code.av) — but `Code` is `@std/avrac`'s, i.e. only the compiler's own package and its dependents see it.

How the three asks are served: the evaluator is handed a closure `(nm: string) -> ws.type_named_lifted(f, nm)` (workspace_analysis.av:771); resolution is "the SAME namespace an ordinary type reference reads" (expand.av:878-880); it "Reads only the DECLARED shape (`crossed_lifted`, never `lifted`), so it cannot re-enter another declaration's own derive" (expand.av:882-885). The crossing is slot-ordered rows held to `features/crossing.av` (CLAUDE.md "A BOUNDARY CHECK…").

---

## (a) Matrix — consumer × access mode

Legend: K = kernel family (`Relation<DbRow>`/raw cell); R = `@std/relation` rows + index; W = bespoke walk (arena / all-rows / filesystem); OWN = own cache outside K/R; P = persisted across processes; OUT = outside-world reads beyond `.av` sources.

| # | Consumer | K | R | W | OWN | P | OUT |
|---|---|---|---|---|---|---|---|
| 1 | `collect` | indirect (row reads record name buckets) | **YES** `Decl` `word`/`marks` buckets | post-filter by scope; re-gather ×4 | `Decls.scoped` map | value: no; type: interface record | — |
| 2 | rule engine | no family | `Ref`, `AssignRoot`, `DeclAt`, `DocFact`; `Finding` (throwaway Db) | `every_at` tree walk; `fingerprint_siblings`, `file_callees` whole-file | `once fn rule_index()`, `FileView.assign_roots` | per-file `rules`/`findings` `Stored.Warn`; program `DbRow.Findings/Licenses` | `@input file_text` |
| 3 | `avra docs` | `Sig` (dump) | `Decl` via 2 `@query`s (full scans), `DocFact` | `Decl.all` filter ×2; listing-digest dir walk | — | `DbRow.Decl` + `FileWitness` | file digests per hit |
| 4 | check / build / run | ALL | all, via pipeline | `build_inputs` dir walk; `all_files()` ×3 in derive.av | `Keys`, `Records`, `Hold` | `Warn/Licenses/Findings` rows; `Obj/Sig/Bin/Unit/Warn`; `closure`, `embeds`, `links` | compiler binary digest, manifests, C objects, runtime archive, env (unkeyed) |
| 5 | `avra test` | via 4 | via 4 | `root_files()` + `host.exists` per file ×2 markers | — | suite `Bin`; `proved` `Unit` rows; `said` rows | `.expected/.refuses/.native-only`, child processes, env |
| 6 | `avra fmt` | `Source`, `Parsed`, `Plain` | — | `all_files(src)` per package | — | `DbRow.Canon` | file writes |
| 7 | references / `writes` / `cache` | `References`, `Receivers`, `Failures`, `ReadReach` unit cells; `cache` reads `deps_of/settled_keys` | `Ref` (`by_decl`,`by_file`), `ErrorSite`, `Raised` | `all_decls()` ×4 passes; exprs.count ×3 + stmt_ids ×3 per file | `refs_db` swapped whole | `ref` lines in module record | — |
| 8 | derives / lifts / const / quote / sublang / embed | `Expanded`, `Lifted`, `Settled`, `ConstTyped`, `Plain`, `Parsed`, `LiftLowered` | decl rows; provenance | `admit_embeds` `expr_ids()`; `decls_of_file` | `lift_asks`/`settle_asks` string-interned; `Records.*_scanned` | kept settlement (6 line kinds); `DbRow.Scan`; `embeds` row; `hold.runs` in key parts | embedded files; `Host.beneath` |
| 9 | manifests / packages / `[link]` | `Manifest` (by ordinal) | — (`package_rows` is a list) | `manifest_objects` re-reads TOML; `packages().find/any` linear | `package_rows`, `closure` | `closure` row; manifests in program key | `avra.toml`, `std_dir`, `avra_host_env` |
| 10 | `@model` / `@relation` / `@query` | via `Hooks` when host-armed | **it IS R** | planner turns scans into lookups | `Memo` per `@query` | `@query` answers via `Durable` → `DbRow.Answer`; `@model` → SQLite (runtime) | SQLite files (runtime) |
| 11 | UI / wasm / `dev` | via 4, 8 | — | `mounts_a_page` over all root files' `use` lines | — | per-mode store root | glue JS, `wasm-opt`, watch; `wire.gen.js` committed |
| 12 | `@std/meta` plugin | rides the enclosing `Lifted` cell | — (no row access) | — | — | via 8 | `embed` only |

## (b) Bespoke whole-program / whole-file walks a relation + index would replace

All line numbers MEASURED at 05fe643 (paths under `packages/std-avrac/src/` unless noted).

| # | file:line | The walk | Replacing relation/index |
|---|---|---|---|
| 1 | `compiler/doc_rows.av:15` | `Decl.all(db) if d.name == name` | `Decl.by_name` (exists, unused here) |
| 2 | `compiler/doc_rows.av:22` | `Decl.all(db) if d.exported && !Builtin` | `@index exported` (+ kind) |
| 3 | `features/decls.av:1324-1325` | `decls_of_kind`: `all_decls() if d.kind == k` | `@index kind` |
| 4 | `features/decls.av:2623-2625` | `implementors_of(tr)`: `all_decls() if implements(x.id, tr)` | an `Impl { @index trait, @index target }` relation |
| 5 | `features/decls.av:1585-1596` + `:1627-1634` | `gathered`/`gathered_by_mark` then `in_scope` per row | composite index `(marks|word, package)` |
| 6 | `compiler/receivers.av:58` | `all_decls() if seated(x) && !is_held` | `@index kind` ∩ `home` |
| 7 | `compiler/failures.av:458` | `all_decls() if !is_held && inferring(x)` | `@index inferring` |
| 8 | `compiler/workspace_analysis.av:227` | `all_decls() if read_member(...)` (ReadReach) | `@index kind`/call-graph relation |
| 9 | `compiler/workspace_analysis.av:110-116` | `touch_method_tables`: `while at < decl_count()` asking `methods` of every type | type-kind index |
| 10 | `features/decls.av:1972`, `:2011` | `clear_written`/`clear_inferred`: `for x in all_decls()` | owner-run sweep (rows owned by the pass) |
| 11 | `compiler/record.av:1587` | `held_stubs`: `for d in ws.decls.all_decls()` if held | `Decl.by_home` over held files (index exists: `home`) |
| 12 | `compiler/references.av:171, :196, :199` | `0..store.exprs.count()` ×3 per file | `Expr` by kind (`exprs_by_kind` exists: failures.av:308) / `Quote` span index |
| 13 | `compiler/references.av:173, :177, :178` | `store.stmt_ids()` ×3 per file | one pass / `Stmt` by kind |
| 14 | `compiler/whole.av:172` | `admit_embeds`: `for e in p.store.expr_ids()` matching a call named `embed` | `Ref.by_decl(embed)` or `Expr` call-by-callee index |
| 15 | `features/code.av:478` | `fingerprint_siblings`: `expr_ids()` per candidate | `@index fingerprint` on `Expr` |
| 16 | `features/code.av:193` | `file_callees`: `expr_ids()` | `Ref.by_file` filtered `.Call` |
| 17 | `features/code.av:1079` | `filed_assign_roots`: `stmt_ids()` (already feeding a relation) | keep; make it a family |
| 18 | `features/code.av:1050-1053` | `enclosing_decl_scanned`: linear innermost-span rescan for Stmt/Pat/Field/Param | extend `DeclAt` side rows to statements |
| 19 | `compiler/typing/impls.av:235` | `for s in store.stmt_ids()` per method to find its writes | `AssignRoot.by_owner` (exists in code.av) |
| 20 | `compiler/derive.av:261, :355, :702`; `compiler/record.av:1566` | `decls.all_files()` filtered by `is_held` | `File` `@index standing`/held |
| 21 | `compiler/cache_walk.av:69` | `all_files().find(it.path == path)` | `File.by_path` (index exists, file_rows.av:16) |
| 22 | `compiler/whole.av:113` | `cases()`: `all_files() if reads_as_source` → `file_cases` | `Decl` `@index kind == .Case` |
| 23 | `compiler/suite.av:97, :139` | `root_files()` + `host.exists(beside(f, "expected"|"refuses"))` | `File` column `proof` |
| 24 | `compiler/program.av:624, :647` | `all_files()` for sources / kind rows | relation scan is fine; listed for completeness |
| 25 | `packages/cli/src/commands/dev.av:56-60` | `mounts_a_page`: every root file's `use` lines | `Ref.by_decl`/an `Import { @index module }` relation |
| 26 | `compiler/modules.av:275-289`, `compiler/db.av:675-691` | `build_inputs` / `current_listing_digest` directory walks | recorded read-set (`inputs_of`) + a listing input |
| 27 | `compiler/packages.av:128, :146`; `compiler/whole.av:201` | `packages().find(it.key == key)` / `.any` | `Package` relation `@key key` |
| 28 | `compiler/program.av:381, :502` | `named_rows(name).find(fn_name != null)` — first-in-bucket wins | `(owner, name)` key |

## (c) Proposal — the minimal verb set that serves all twelve consumers (≤ 10)

Written in the tree's Avra. `Q` is a query family value (today's `Family` + `@query` fn), `Row` a `@relation` type. One `Db` handle; the kernel, relations, durable rows and the content store sit behind it.

```avra
impl Db {
    /// 1. A derived fact, memoized on (query, arg); its reads recorded. Replaces
    ///    Relation.demand/start/finish, `@query` wrappers, Workspace.<family>().
    fn ask<A, T>(q: Query<A, T>, arg: A) -> T

    /// 2. An outside-world read as a tracked input: a file's bytes, a directory
    ///    listing, an env var, a tool/binary digest. Replaces Source/Manifest
    ///    inputs, FileWitness, text_digest, embed_said, avra_host_env, links_text.
    fn input<T>(kind: Input<T>, name: string) -> T

    /// 3. Rows by an index: `db.rows(Decl.marks, "model")`. Replaces filed/
    ///    indexed/by_<field> and every walk in (b) rows 1–11, 20–23, 27.
    fn rows<Row, K>(index: Index<Row, K>, key: K) -> List<Row>

    /// 4. One row by its stable key (never a dense id).
    fn row<Row, K>(key: Key<Row, K>, k: K) -> Row?

    /// 5. Rows written by the query now running, owned by it: a rerun replaces
    ///    exactly what it wrote. Replaces mint/set_decl/put_owned, settle_refs,
    ///    Finding.insert into throwaway Dbs, speak_expansion.
    fn emit<Row>(row: Row) -> Row

    /// 6. A diagnostic as an owned row of the running query (so a reused
    ///    answer still speaks). Replaces Warn/Licenses/Findings text rows,
    ///    said_key/rules_key, package_voices.
    fn say(d: Diag)

    /// 7. An ask whose answer outlives the process: looked up by the query's
    ///    durable name + arg's stable hash, valid while every recorded input
    ///    and upstream durable answer still stands. Replaces checked()'s Warn
    ///    row, kept_binary, kept_verdict's 6 line kinds, proved_key, Canon,
    ///    Scan, DocFacts, Durable.answer/keep, closure/embeds/links rows.
    fn kept<A, T>(q: Query<A, T>, arg: A) -> T

    /// 8. What an answer was a function of — the transitive recorded inputs.
    ///    Serves `avra cache why`, `avra dev`'s watch set, build_inputs.
    fn inputs_of<A, T>(q: Query<A, T>, arg: A) -> List<InputRef>

    /// 9. Who read this — reverse edges. Serves `cache dependents`, LSP
    ///    references-of-a-fact, invalidation reports (`PartMoved`).
    fn readers_of(of: FactRef) -> List<FactRef>

    /// 10. An artifact as bytes on disk under an answer's key (object, binary,
    ///     generated asset), placed where asked. Replaces Store.keep_file/place.
    fn artifact<A>(q: Query<A, Bytes>, arg: A, to: string) -> Result<string, string>
}
```

Coverage check: collect = 3 (+1 to memoize per collect); rules = 1+3+5+6 (+7 per file); docs = 7 over 3/4; check/build/run = 7+10 over 1/2/6; test = 7 (Proved) + 3 (File by proof); fmt = 7 (Canonical) over 1/2; references/LSP = 3 + 9; derives/const/embed = 1+2+5 (+7); manifests/link = 2 + 3 (`Package`); ORM = already 3/4/5 through `Hooks`; UI/dev = 8; std-meta plugin = expose 3 and 4 read-only to derives (`rows(Decl.marks, "model")`, `rows(Impl.trait, T)`) — the two asks §12 shows are impossible today.

What the proposal deliberately removes: addressing scheme F (ad-hoc string maps), the three separate witness formats, dense ids in any persisted key, and "remember the input list from last time" rows (`closure`, `embeds`) — replaced by 8.
