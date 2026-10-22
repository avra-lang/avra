# Collections — every X in the program, as a value

Design, 2026-09-22. Not built.

**In one line:** a `collect` declaration asks the compiler a question about the
program — "every declaration of kind K" — and answers it as an ordinary typed
value, with its scope, shape and order written down.

## 1. The problem

"Every X in the program" recurs, and the tree answers it three ways:

| every… | today |
|---|---|
| test case (`spec`) | special-cased: `compiler/suite.av` finds them at lowering and calls each by symbol |
| rule (the formatter) | a hand-typed list plus a test that checks it (`compiler/rules_table.av`, avra-8sb5.25.23) |
| CLI command | a hand-typed list in `cli/src/main.av` — "a new command is a new file plus one line" |
| language feature | a hand-typed ORDERED list in `compiler/mod.av` |
| diagnostic code | glued from every feature's `diags` table |

User programs will add routes, migrations, event handlers, jobs, plugins. Three
copies of one shape name the concept.

**Why a generator cannot do it.** An annotation (`@derive`, a `Declares`
directive) runs sandboxed over ONE declaration, and that is what keeps
per-file caching sound. "Every rule everywhere" is exactly what it must never
see. Two agents tried that route for the rule table and hit the wall. The part
of the compiler that DOES see the whole program is the link/lowering stage —
which is why `suite.av` works.

**What other languages do:** Rust links (`inventory`), Java reflects, Go
registers at `init()`. All three are invisible, ordered by accident, and paid
at startup — the magic P7 refuses.

## 2. The form

```avra
/// Every rule the program links, in module order.
export collect rules: List<RuleEntry> = rule in closure
    as RuleEntry { name: it.name, module: it.module, run: it, root: it.root_kind }
    by it.module, it.name
```

| part | says | values |
|---|---|---|
| `rule` | **what** | a declaration kind, an annotation (`@get or @post`), a trait impl (`impl Error`), refined by `where …` |
| `in closure` | **where** | `self` (this module) · `package` · `closure` (everything the program links) |
| `as …` | **the projection** | `it` is the declaration; `it.name`, `it.module`, `it.file`, `it.line`, `it.mark` (its annotation and literal args), and `it` itself as a fn value |
| `by …` | **the order** | required — no default, never file order |
| `keyed …` | a `Map`, a duplicate key refused | |
| `dense` | an order that is data, a gap refused | |

Contributing needs no code: a declaration of the kind, in scope, IS its
contribution. Consuming is an ordinary read (`for r in rules { … }`).

## 3. The uses

```avra
// tests — suite.av's special case deleted
collect cases: List<TestCase> = case in self
    as TestCase { suite: it.parent.name, name: it.name, call: it }
    by it.file, it.line

// CLI commands — the "one line" deleted; two claiming a name is a compile error
collect commands: Map<string, Subcommand> = @command in package
    as it() keyed it.mark.args[0]

// routes — the same list emits the OpenAPI spec and the deploy manifest (P13)
collect routes: List<Route> = @get or @post in package
    as Route { method: it.mark.name, path: it.mark.args[0], handler: it }
    by it.mark.args[0]

// migrations — ordered by data, a gap refused
collect migrations: List<Migration> = @migration in package
    as Migration { id: it.mark.args[0], run: it }
    by it.mark.args[0] dense
```

**The strongest use — every implementor, as an enum.** The compiler mints the
enum, so a match over "every error kind" is EXHAUSTIVE across files, and adding
an implementor breaks every match on purpose (the registry law, F2040, reaching
across files):

```avra
export collect enum AnyError = impl Error in closure

match e {
    .ParseError(p) -> …
    .IoError(i) -> …
}   // a third `impl Error` anywhere refuses here, naming it
```

**A gathered variant carries its member record's fields**, in field order — a
member that is no record carries nothing. The mark says which enum a member
joins, so one record may be a variant of two. A `@derive` on the `collect enum`
is handed every member as a variant: name, fields, the record's annotations.

```avra
@shape(0) type Dot = {}
@shape(1) type Line = { from: int, to: int }
collect enum Shape = @shape in package by it.mark.args[0] dense

match Shape.Line(1, 4) { .Dot -> 0, .Line(a, b) -> b - a }   // 3
```

A member record that takes type parameters or spreads another's fields is
refused (`collect_enum.member`).

Also: a tag → decoder table for serialisation (keys checked unique), `explain`
pages, benchmarks, fuzz targets, scheduled jobs.

## 4. The laws — every edge case is a refusal

1. **Open world closes at link.** A library may READ a collection at run time;
   only a program may fold one at compile time.
   `error: \`rules\` is closed only when a program links — read it at run time`
2. **A member never reads its own collection at compile time** (a cycle).
   `error: \`meta\` is collected into \`rules\`, so it cannot read \`rules\` while compiling`
3. **Order is declared.** `error: a collection declares its order — \`by …\``
4. **Across packages, exported declarations only.** `in self`/`in package`
   may see private ones.
5. **Keys are unique** under `keyed`, naming both files.
6. **Coherence, as the orphan-impl law already holds for impls:** only the
   package that declares a collection, or the one declaring the item's type,
   may contribute to a `closure`-scoped collection — so a dependency cannot
   silently add a route to your app.
7. **Collected means reachable, so it is opt-in.** Nothing is collected unless
   a `collect` asks; tree-shaking holds everywhere else.

## 5. The mechanism

- **Lean 4's attributes are the model** (`@[simp]`): each module contributes
  its entries; contributions **merge exactly where imports merge**; `local`
  scopes them. A module's view is its closure's entries; the program's is
  everything linked. That is how open and closed world are both true (P6).
- **It is a query** in the memo kernel (`query/db.av`), one more `Family`. Its
  key is the fingerprint of the collected SET (each member's identity + its
  projected fields). The collection's TYPE never changes, so adding a member
  re-types nothing: only the one table's body is regenerated, where `suite.av`
  already synthesises its entry.
- **The store keeps it** like the program's module: per-module contributions in
  each module's record, the closed value at program level.
- **`explain` prints it** (P7):

  ```
  $ avra explain rules
  rules — List<RuleEntry>, rule in closure, by module then name — 63 entries
    lists.last_index            features/lists/idioms.av:9
    nullable.if_null_ternary    features/nullable/idioms.av:12
  ```

**The long game (stolen from CodeQL / differential dataflow):** program facts
as one relational base, with collections, callers (avra-8sb5.25.9),
"every implementor" and lint rules all as queries over it.

## 6. Build order

1. `collect` over a declaration kind, `List`, `by`, `in self|package|closure` —
   the rule table as its first user (retires avra-8sb5.25.23's hand list).
2. `suite.av`'s cases onto it; the special case deleted.
3. Annotations as the `what`, `keyed`, `Map` — CLI commands onto it.
4. `impl Trait` as the `what`, `collect enum` — exhaustive matches over implementors.
5. `dense`, the coherence law, the lockfile recording what a program collected.
6. The diag-code registry and `language_features()` (ordered, `by` a declared rank).

## Open

- **OWNER'S CALL:** `collect` as a declaration WORD (above), or an annotation on
  a `const` (`@collect(rule, in: closure) export const rules: …`)? Recommended:
  the word — a whole-program fact is not a per-declaration effect, and an
  annotation's effect is its answer type.
- Does `it` as a fn value need the rule/case/fn to share one signature, or does
  the projection adapt each (`run: (c) -> it(c)`)?
- Should a program's lockfile pin a `closure` collection's membership, so a
  dependency upgrade that adds a member is a visible diff?
