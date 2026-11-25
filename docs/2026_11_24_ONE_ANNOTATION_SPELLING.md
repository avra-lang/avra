# One annotation spelling

Owner-approved, 2026-11-24. `@X` is the only spelling of an annotation, and the compiler decides what it
does from what `X` names where it is written:

| `X` names | `@X` | today |
|---|---|---|
| a fn whose first seat takes a declaration | runs it over the declaration (declares, validates, generates) | `@X` |
| a fn whose first seat takes a value | a rule, spliced where a derive applies it | `@X` |
| a fn answering `@std/meta`'s `Marker` | a mark, data for the derive that claims it | `@X` |
| a trait that declares `static fn derive` | that trait's derive over the declaration | `@derive(X)` |

So `@derive(Saved)` becomes `@Saved`, beside `@short` (a fn) and `@secret` (a mark).

## The resolution rule

One resolution where the annotation is written, in both spaces: `X` in the value space, then `X` in the
type space.

- **A fn and no trait** of that name: today's annotation fn, judged by its first seat and its answer,
  unchanged. A mark is such a fn too: its identity is the annotation's `key`, and a derive asks which
  mark it is with `marks(a, secret)`, never by its word.
- **A trait and no fn**: the trait's derive. The trait must declare `derive`, and the derive's seat must
  take this kind of declaration. Both are today's `annotation.derive` laws, now said at `@X`. A derive
  takes no arguments, so `@Saved(x)` is refused by `annotation.seats`.
- **Both** (a fn `X` and a trait `X` in scope): refused, new kind `annotation.ambiguous`:
  "`@X` names both the fn `X` and the trait `X`", labelled at the word, help "import one of the two
  under another name". No precedence is guessed, and no fix is offered: which of the two to rename
  is the author's call. In the tree today no name is both: traits are
  capitalised and annotation fns are not.
- **Neither**, a name that is a type but no trait (`@Point`), or a const: `annotation.callee`, reworded
  to "an annotation names a fn or a trait", with the resolver's guess where one is near. A trait with
  no `derive` keeps `annotation.derive`'s "`X` declares no `derive`".

One question decides it. On the program layer the generator gather (`annotation_sites`,
item_generators.av), the marks-claims gather (`derive_claims`), the derive laws and the `Annotation`
crossing each ask one fn, `annotation_meant(...) -> AnnotationMeant { Fn(DeclaredName) |
Derive(DeclaredName) | Nothing }` (item_annotations.av). None re-derives the rule apiece, so eval and
native read one meaning. A word naming both is the `annotation.ambiguous` law's own question; the
others read the fn, which that law refuses.

The old path (expand.av's declare work) gets the same hook in a separate, small commit, so it can be
dropped if the old path's deletion lands first.

**Cost:** the type-space lookup runs only when the value space misses, which happens for a trait name
or an unknown word. A fn annotation pays nothing new.

## A derive's identity

`Annotation.key` names the declaration `X` resolves to: a fn's, as now, or the trait's
(`decl_key(trait file, trait name)`). `marks(a, f)` takes any declared name, fn or trait, and its law
(`type.marks_named`) refuses a value that names neither. So std-validate's
`t.annotations.any(it.name == "derive" && it.args.contains("Decode"))` (derive.av:848) becomes
`t.annotations.any(marks(it, Decode))`: identity, not text, and it serves both spellings during the
sweep. `decl(a)` stays fn-only and answers absent for a derive's annotation.

## `@derive(A, B)`

`@derive(A, B)` is `@A @B`, in written order; derives run in the order they're worn, as now. The
crossing says so: a derive reads `@derive(A, B)` among its declaration's annotations as two, `A` and
`B`, each keyed by its trait, which is what lets `marks(a, A)` serve both spellings. The tree holds one
such site.

## fmt

fmt prints an annotation as written and never rewrites one spelling into the other. That is
`fix --repair`'s job, so a formatting pass can't change what a program means.

## The migration

1. **Both spellings valid** (one commit, a Rung): the rule above, the new voice, and a warning,
   `annotation.derive_spelled`: "`@derive(X)` is `@X`". Its `Remedy.Fix` rewrites `@derive(A, B)` as
   `@A @B`. `fix --repair` applies it: the repair door takes a warning whose registry row owes a fix,
   accepted where its splice silences the warning and mints no error. The `derive` import a rewrite
   leaves is `modules.unused_import`'s to drop. That rule reads uses program-wide, so it fires once
   a package's last `@derive` is gone, and the sweep ends with an `avra fix --only
   modules.unused_import` pass.
2. **The sweep**: about 990 sites in 316 files. `fix --repair --only annotation.derive_spelled` over
   every file, then the unused-import pass, then a script for the
   sources held in strings (23 files, test sources), then `git grep '@derive('` showing only the
   retired voice's witness. This commit reads `@X` in std-avrac itself, so it needs a compiler that
   carries step 1: the next rung, landed after step 1's train as A and B were.
3. **Retire**: `annotation.derive_spelled` becomes an error with the same fix, and `@std/meta`'s
   `derive` is documented as the retired spelling. Its declaration stays while a seed or a package
   older than the sweep might still name it; removing it is a moved shape for the crossing and gets
   its own later commit.

## Not in scope

- Arguments to a derive (`@Table(name: "t")`): today no derive takes any, and the rule refuses them.
- A derive asking "which trait derived me" beyond `marks(a, T)`.
