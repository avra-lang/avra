# Sublanguages — a block parsed by a library's grammar, expanded as sugar

> 2026-09-14, lane comptime/templates, over lane/comptime 0c67c2e.
> Sources of truth it follows: the comptime design's §2 row ("`grammar
> { }`, `table<R> { }`, `sql { }` and `quote { }` are one shape"), §3.5
> ("`${}` is the one hole"), §5 item 6 ("sublanguages are a CONSUMER
> of this design"); the old tree's `2026_08_18_EMBEDDED_LANGUAGES_DESIGN`
> (the two-sided contract, the non-goal) and its `2026_07_16` note
> (`syntax sql = grammar { … }`, the spec's §12.4 "a registered
> `<keyword> { … }`, brace-matched, handed to the package's parser").
> Divergences are named in §9.

## 0. What a library author writes, and what a user writes

```avra
// package acme/sql — the language is a grammar; its actions are the
// package's own fns; its AST is the package's own types
export type Select = { cols: List<string>, from: string, where: Where? }
export type Where = { col: string, value: int }

export fn select(cols: List<string>, from: string, where: Where?) -> Select { … }
export fn eq(col: string, value: int) -> Where { Where { col: col, value: value } }

export grammar sql {
    select = "SELECT" c:NAME ( "," c:NAME )* "FROM" t:NAME ( "WHERE" w:where )? -> select(c, t, w)
    where  = c:NAME "=" v:NAME -> eq(c, v)
}
```

```avra
// a user
use @acme.sql.{sql, Select}
let uid = 7
let q: Select = sql { SELECT name, age FROM users WHERE id = ${uid} }
```

The block IS `select(["name", "age"], "users", eq("id", uid))` — an
ordinary call the user could have written. That is the whole design:
**a sublanguage block is PURE SUGAR, like `table<R>` and `grammar { }`
already are**: the library's grammar runs at compile time over the
block's tokens, and its ACTIONS are minted as ordinary Avra call nodes
into the user's store. Typing, hygiene, lowering and the two engines
all see a program that was always there.

What that buys, and why it is the P6 answer:

- **No crossing.** Nothing runs in the lifted interpreter; no meta
  value carries an AST; no `produces` declaration. The block's type is
  the action's answer, by the ordinary call law.
- **Typed holes for free.** A hole stands where the grammar lets a
  `NAME` stand; it becomes the action's argument, so "`${uid}` must be
  an `int`" is F2000 "argument 2 of `eq` wants `int`, found `string`"
  — the seat law by position, the builder's parameter being the
  position. The template registry (`FillClass`/`fits`) is not consulted:
  a sublanguage hole is not a template seat, it is a call seat, and
  that law already exists.
- **Hygiene by construction.** The minted call nodes wear the LIBRARY's
  origin (`Decls.origins`, exactly as a copied template node does), so
  `select`/`eq` resolve in `acme/sql` even when the user has none of
  them in scope; the hole expressions are the user's nodes and resolve
  in the user's file.
- **Runtime values flow without ceremony.** `${uid}` is a runtime
  expression; nothing needs to be static. The old design's lifted
  builders, `CapVal` carriers and span carriers (its §3.2, §5 items
  4 and 6) are not needed: captures become literals, holes become
  arguments.

## 1. The declaration — `grammar <word> { … }`

A STATEMENT of a library module: `export grammar sql { <grammar DSL> }`
— a NAMED grammar, beside the anonymous `grammar { }` value the
compiler's own features write. (`syntax` was the first spelling; a
feature's grammar fragment IS its keyword claim, and `syntax` names a
field of the compiler's own `Language` — so the word already reserved
is the declaration's word, and a named `grammar` statement takes no
`@recover`, by the anchor law: the anonymous literal shares its
keyword.)

- The body is lexed WHOLE (the `grammar {` raw scan, keyed on the
  word before the brace being preceded by `grammar`), and parsed with the grammar DSL's own parser
  (`parse_grammar`) at the declaring file's parse. Malformed notation
  refuses there, at the library.
- It declares `sql` in the module's namespace under a new declaration
  kind, `DeclKind.Syntax`. Exported like a fn; imported by `use
  @acme.sql.{sql}`; a program that does not import it has no block
  word `sql`.
- The store carries the grammar as its TEXT (`Stmt.SyntaxDecl(name,
  text)`) — `core` cannot hold `grammar`'s types, and the workspace
  parses the text once per declaration into a `Ready` grammar,
  memoized by the declaration's fingerprint.
- Every action names a fn of the DECLARING module (`-> select(c, t,
  w)`); the actions' arity is checked against the fn's signature when
  the grammar is readied (the executor's `Ready` defects, plus one
  new: "action `select` names no fn of this module"). Terminal names
  are the language's (`NAME`, `NUMBER`, `STRING`, `HOLE`, `BREAK`);
  literals are the sublanguage's own words. The first rule is the
  entry (the engine's standing convention).

Why not `syntax sql = grammar { … }` (the old note's spelling): a
`grammar { }` VALUE expands into `Grammar`/`Rule`/`Alt` struct literals
that need the compiler's own types in scope, which a library must not
import (P9: `@std/meta` is the boundary). A declaration keeps the text
and needs nothing in scope.

## 2. The consumer's block — how a word reaches the lexer

`sql { … }` is `NAME "{"`, which is also a struct literal and a name
before a block. The lexer must know the word before it reads the body,
and the word is known only through the file's imports. So:

1. **A pre-scan of the file's `use` lines** (a lex without block words;
   a `use` line holds no block) names the imported items.
2. For each item, the workspace asks the provider module's PARSED
   declarations whether `grammar <item>` is declared — the provider's
   parse is a query dependency of the consumer's parse, recorded like
   any other.
3. The file is lexed with that word set. A word in the set followed by
   `{` opens a BLOCK FRAME: the same quote-frame machinery as `quote
   {` — brace depth, `${` holes deferred to after the closing `}` as
   `HOLE_BEGIN … HOLE_END` groups — except that the body is not
   tokenized: its bytes are kept as ONE `BODY` token whose text carries
   the holes as `${k}` placeholders (the quote's placeholder names,
   the same spelling). Lines inside the body are the body's.
4. Two imports binding one word in one file refuse at the second
   `use`, naming both packages. A file that does not import the word
   reads `sql { … }` as today (a struct literal or a block after a
   name) and refuses as today.
5. **THE WORD IS THE FILE'S ALONE.** `NAME {` is also a struct
   literal's spelling and a trailing block's tail, so a block word
   in scope may not also name a type, a fn or a binding in that file:
   `type sql = { … }` or `let sql = 1` beside `use @acme.sql.{sql}`
   refuses with ONE voice at the second declaration, naming both. A
   block word is never a keyword elsewhere: `sql` alone, `sql(1)`,
   `x.sql` are what they were.
6. **THE BODY'S LEXING IS AVRA'S** — a stated LIMIT. The library's
   grammar runs over tokens Avra's lexer made: `SELECT` is a NAME,
   `=` an Op, `'x'`… is not a string (Avra's lexer refuses `'`). A
   body character Avra's lexer refuses speaks AT THE BLOCK, in the
   lexer's words, not as a grammar error. A sublanguage whose
   lexical rules are not Avra's (a regex, a `#`-commented DSL, single-
   quoted strings) waits on a lexical layer in the grammar DSL
   (`tokens { }`); the trigger is the first std package that needs
   one.

The `Parsed` memo's fingerprint folds the word set in (the early-cutoff
law): a file re-parses when a dependency's `grammar <word>` declaration
appears or goes.

The grammar rule, one for every sublanguage:

```
primary = w:BLOCK "{" b:BODY "}" ( hb:HOLE_BEGIN ( h:expression )? he:HOLE_END )* -> sublang(w, b, hb, h, he)
```

`BLOCK` is the word's token kind (the lexer's, from the set); `BODY`
the body's. The node is `Expr.Sublang(word, body, holes)`.

## 3. The expansion — where the block becomes calls

The block expands AT THE PARSE, in its builder, exactly as `table<R>`
does: the parse already depends on the providers (§2), so the
workspace hands the parser each imported word's grammar READIED
(`BlockGrammar { word, ready, origin }` on the `Builder`), and the
block's builder runs it before minting the block node. That is what
keeps every range law: the expansion's nodes stand right before the
block's, children before their owner, inside the declaration that
holds them. (The first draft expanded inside `resolved`, after
admission — and the typer's per-declaration table, sized from the
declaration's range, could not reach nodes minted later: `index 22 is
out of bounds (length 20)`. The seam was wrong, not the model.) For
each block:

1. `word` names its readied grammar among the file's imported ones.
2. The body text is lexed by the LANGUAGE's lexer in PLACEHOLDER mode:
   `${k}` lexes to a `Hole` token (the quote's kind) — so a hole
   matches a `NAME` prim in the sublanguage's grammar exactly as it
   does in Avra's. Every span is the body's offset plus the block's,
   so a refusal points into the user's file.
3. `run_from(ready, entry, tokens, build)` — the fragment entry the
   type-spelling reader already uses — with ONE generic builder: a
   `Terminal` becomes `Expr.StrLit(text)` (a `NUMBER` an `IntLit`, a
   `Hole` the user's hole expression by index), a repeated capture a
   `ListLit`, an absent one `NullLit`, and an action `-> f(a, b)` an
   `Expr.Call("f", [], args)`. The nodes mint into the user's store
   wearing the library's origin, except the holes, which are the
   user's own.
4. The node carries its expansion (`Expr.Sublang(word, body, holes,
   expansion)`): its kids are the expansion, so resolving and typing
   walk it once; typing answers its type, lowering its register, the
   printer prints the block as written. The Rebuilder copies it (a
   template may hold one) — and a copied node that a sublanguage
   minted keeps THAT library as its origin (`ForeignRange`, `made_from`),
   not the template's file, so `query` resolves in `@x/sql` even when
   the template's own file never imported it.
5. A repeated capture with ONE element or NONE arrives from the engine
   as a scalar or an absence; the grammar says which seats are lists
   (a label under `*`/`+`, `listed_seats`), and those arrive as a list
   of one or of none.

A body that does not parse speaks at the user's line, inside the
block, in the sublanguage grammar's own expected words (`sql { SELCT
name }` → "expected `SELECT`" — the executor's farthest failure,
homed by the block's offset), never "builder failed" and never at the
library; the block's type is the error type and nothing more is said.
An action naming no fn of the library's module, or the wrong arity,
speaks at the `grammar <word>` declaration in the LIBRARY when the grammar is
readied — before any user exists.

## 4. What a hole may fill

A hole is a `Hole` token; the sublanguage's grammar decides where a
`NAME` may stand, and the action's parameter decides what the hole's
value must be. Three consequences, stated:

- `FROM ${table}` types if the grammar wrote `t:NAME` there and the
  action's seat is `string`; a `${n}` where the grammar wants a
  `NUMBER` refuses at the grammar ("expected NUMBER") — a hole is
  name-shaped, as in a template.
- A hole in a seat that becomes a LITERAL capture (a bare `c:NAME`
  that the action takes as `string`) is a hole in an argument seat:
  the argument must be a `string`.
- No `splice<T>` terminal (the old design's §3.3): the type lives on
  the action's parameter, one place, and the ordinary call law speaks.

## 5. The value and its lowering

The block's value is the entry action's answer, a library type the user
imported. Lowering is the expansion's — a call — and both engines run
the same program. `avra expand` prints the block as the calls it
became, beside `// from grammar sql`, with the library's file:line.

## 6. Diagnostics, registered

| refusal | where |
|---|---|
| grammar notation does not parse | the library, at the named grammar's body (`parse_grammar`'s words) |
| an action names no fn of the module, or the wrong arity | the library, at the action |
| two imports bind one block word | the user, at the second `use`, both packages named |
| a block word also names a type, a fn or a binding in the file | the user, at the second declaration, both named |
| a body character Avra's lexer refuses | the user, at the block, the lexer's words (the lexing limit) |
| the body does not parse | the user, inside the block, the grammar's expected words |
| a hole's value does not fit the action's seat | the user, at the hole — the call law's F2000 |
| the block's type does not fit its seat | the user, at the block — the ordinary F2024 |

## 7. The proof

- `features/sublang/tests/sql/` — a program-test package with a
  provider `@test/sql` (`grammar sql`, `Select`, `select`, `eq`) and a
  user printing a query's parts: eval == native == expected.
- `sublang_test.av` / `sublang_adversarial_test.av`: the six refusals
  above with counts; a hole in every seat of the toy grammar; a block
  inside a fn body, a list, an interpolation hole; a template that
  holds a block (the Rebuilder copies it); the non-importing file; the
  two-import collision.
- `table<R>` re-expressed through this door: it does NOT fit — a
  table's cells are AVRA expressions (`additive`), and a sublanguage's
  grammar has no way to name Avra's rules; `table<R>` stays the
  compiler's own sugar. The dogfooding receipt is the toy `sql`
  package plus a second sublanguage in the same test (`kv { a = 1, b
  = ${x} }`) to prove the word set holds two.

## 8. The ladder

A lexer change (the block frame, the `BLOCK`/`BODY` kinds, placeholder
mode) and a grammar rule: the standing binary compiles the source and
the PRODUCT is the first to read a block, so `cp build/avra
build/avra.pre`, build twice to the fixed point, `make seed` on the
commit. No meta-contract shape changes (nothing crosses), so no
derive-stub crossing is expected.

## 9. Divergences from the old design, named

- **No lifted builders, no `CapVal` carrier, no span carrier, no
  `produces`, no `check` hook (its §3.2, §3.4, §3.5, §5 items 2, 3, 4,
  6).** The block is sugar over the library's fns; every one of those
  mechanisms existed to move an author's AST across a boundary this
  design does not cross. A semantic check (its §3.5, "column does not
  exist") is a `const` the library author writes over the built value
  once static data can hold it (the STATIC lane's door) — recorded as
  a later item, not built.
- **Registration is the `grammar <word>` declaration plus the `use` line** (its
  §3.1's metadata entry); the pre-scan is the cost, named in §2.
- **`${}` is the hole and the scanner finds it** (its §5 item 1 and 5),
  as the comptime design already decided.
- **`grammar sql { … }`, not `syntax sql = grammar { … }`** (§1).
- **v1 is token-compatible sublanguages** (its §3.7 stance kept): the
  body is lexed by Avra's lexer. A `tokens { }` layer is later.

## Status

- design written 2026-09-14; sent to the task master before code.
- LANDED 2026-09-14: `features/sublang` (a named grammar statement, the
  block rule, the parse-time expansion), the lexer's raw block frames
  under the file's imported words, `Cause.Block` (F2082) for a body its
  grammar refuses, F2080 for the library's own grammar law, F2081 for a
  binder or declaration wearing a block word (a READ is not a binder:
  `sql` alone is "`sql` is not defined"). Proof: `sublang/tests/sql`
  (two block words, a hole, one- and two-element captures, an absent
  optional; eval == native), `sublang_test.av` 13 cases,
  `sublang_adversarial_test.av` 10 (every seat under a hole, the block
  in a fn body / a list / an interpolation hole, the lexing limit, two
  imports of one word, two modules importing each other, a block
  inside a template copied with its library's origin). FOUND on the way: the grammar DSL swallows an
  unclosed group (`where = ( c:NAME`) and an unclosed action (`-> eq(c,
  v`) without a word — filed in the survey; `table` and `syntax` are
  keywords (a feature's grammar fragment IS its keyword claim, which
  is why the declaration's word is the reserved `grammar`).
- THE PRE-SCAN READS A PROVIDER THROUGH ITS PLAIN PARSE (`Family.Plain`,
  `plain_parsed`): a file parsed under NO block words, depending on
  its source alone. The first draft read the provider's `surface`,
  whose items demand the provider's parse, whose pre-scan demands the
  consumer's — two files importing each other were a memo cycle
  ("memo family 2 reused missing key 0", the workspace's mutual-
  recursion case). A grammar declaration is read from the plain
  parse: exported, named, readied; an alias renames its word.
  `sublang_adversarial_test.av` pins two modules importing each other,
  one declaring the grammar the other writes a block of.
- A FILE ENTERS THE TABLE AT FIRST MENTION AND A MENTION MINTS NOTHING:
  the plain read enters the provider's file with no store, and
  `cases()` — which walks the whole table — unwrapped it ("unwrapped
  an absent value", the sql program under `avra test` alone).
  `file_cases` mints the file's items first.
