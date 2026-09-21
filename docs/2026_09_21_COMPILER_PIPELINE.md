# The compiler pipeline — every stage, where it lives, what it keeps

One page. The cache's laws and numbers are `2026_09_21_COMPILER_CACHE.md`;
the source map is the header of `packages/std-avrac/src/compiler/mod.av`.

## 1. The shape

```
source ─ parse ─ items ─ namespace ─ resolve ─ sig ─ typed ─ analysis     per FILE / per DECL
                                                     │
                       settle (consts) · lift (annotations) · expand       compile time, in the evaluator
                                                     │
                                  lower (units) ─ memory ─ Lowered         per BODY, per instantiation
                                                     │
        check: what was said     run: the evaluator     build/test: objects ─ link
```

Every stage is a QUERY in the memo kernel (`query/db.av`): keyed, memoized,
with its dependencies recorded. `Family` (`compiler/workspace.av`) lists them
in pipeline order. Across runs nothing of the kernel survives; what survives is
the STORE (`compiler/store/`), and the DERIVATION decides what it may stand in for.

## 2. The stages

| stage | family | key | module | answers |
|---|---|---|---|---|
| read | `Source` | file | `workspace.av`, `host/` | `SourceFile`: text, line starts |
| parse | `Parsed`, `Plain` | file | `program.av`, `grammar/` | the AST (`NodeStore`), spans in side tables, parse voices |
| items | `Items` | file | `workspace.av`, `features/decls_mint.av` | the declarations a file MINTS |
| names | `Namespace`, `Visible` | module, file | `workspace.av`, `features/namespace.av` | what a module binds, what a file sees |
| expand | `Expanded`, `Lifted` | file, annotation call | `expand.av` | generated declarations; a lifted call's answer |
| resolve | `Resolved` | file | `resolve/` | `NameFacts`: names → bindings |
| signature | `Sig`, `Methods`, `ConstTyped` | declaration | `typing/declare.av`, `typing/impls.av` | a declaration's types; a type's method table |
| typing | `Typed`, `Folded` | declaration, file | `typing/` | `TypeFacts` over one declaration's expressions |
| analysis | `Analysis` | file | `analysis.av` | every fact of one file, in ONE value |
| receivers | `Receivers` | program | `receivers.av` | which seats are written, whole-program |
| settle | `Settled` | const / expr + seats | `workspace_analysis.av`, `backend/interp.av` | a const's value, run at compile time |
| lower | `Lowered` | unit (decl, type args, seats) | `lower/` | `Unit`: bodies of IR, the units it wants |
| memory | — | `Lowered` | `memory/` | retains, releases, scopes placed |
| emit | — | file / program | `backend/llvm*.av` | one LLVM module per file, one for the program |

A pass is `pass(p: Parsed, ...upstream Facts) -> Facts`: the program first, the
facts it reads next, its own facts out — and it OWNS its fact tables. A feature's
rule is reached through `semantics_of` / `stmt_semantics_of`; a pass never
matches a feature's node.

## 3. The derivation — what every command asks

`Workspace.derived(entry, want)` (`compiler/derive.av`):

1. **hold** — for every file: is its text the text its module's record was
   written from, and does the store hold what stands in for it under this
   `want`? A file that will be read brings the files its compile-time runs read.
2. **load · admit** — a read file's declarations from its parse. A held
   module's are minted from its record the first time anything reads them
   (`mint_module`), never all of them every build.
3. **analyse** — the stages above, for read files only.
4. **lower** — every body of every read file, and each file's top level under
   its program symbol (`Program.files_checked`). Instantiations whose generic's
   file is held are OWED (`unlowered`), not lowered.
5. **keep** — records, what each file said and asks, settled consts.

A failure under a hold is asked again of the sources; only that answer is the
program's. `check` prints `Derived.warnings`. `build` links it
(`build.av`: a file's object is the file's, made in process; the PROGRAM's module is what
no file owns plus an entry that calls). `test` is a build whose entry calls every
case and runs every program test (`suite.av`). `run`, `emit`, `ir` still lower
from the entry's reach with nothing held: the evaluator reads IR, and a held
file has none (S8 ends that).

## 4. What is kept, and under what

| row | family | key folds |
|---|---|---|
| a module's record | `Sig` | the root, the module's NAME — rewritten when its words move |
| a file's object, what it said, what it asks | `Obj`, `Warn`, `Unit` | text · its module's interface · the closure of its imports · the texts its compile-time runs read |
| the program's module | `Obj` | its bytes; and its inputs: root asks, homes' keys, the entry |
| a settled const | `Unit` | its file's key, its name |
| "these instantiations lowered clean" | `Unit` | the program's asks |
| a program the evaluator agreed with | `Unit` | the text it must print, every text it can reach |
| the binary, a suite's binary, `check`'s verdict | `Bin`, `Warn` | every input's path, length and digest — the inputs of the closure its last derivation admitted |
| a program's closure | `Unit` | the root, the program's name |
| the tree's stamps | `Fp` | one row: path → stamp, digest |

The store stands under the running compiler's print — `.avra-cache/<print>/`,
the newest four kept on `.avra-cache/compilers` — so every row is the work of
the compiler that reads it. A refusal is never kept.
