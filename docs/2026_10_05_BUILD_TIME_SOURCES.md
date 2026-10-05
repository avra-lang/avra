# Build-time sources — files, folders and specs as typed values

> 2026-10-05. Design only; no compiler code. Branch `sources-design`, base `bd36bf7`.
> Every claim about today's compiler is **PROBED** (command and output in Appendix C),
> **READ** (file:line), **READ(agent)** (a survey agent read it; I did not open it), or **ASSUMED**.
> Probes ran `avra-ui-assets-design/build/avra` (built 2026-10-05 10:44 at `0b5bd64` = `0718345` + two doc commits,
> one PR behind this base). Main's own `build/avra` is from 09-30 and refuses main's `@std/text` (PROBED), so it was not used.
> All code using `@std/source` is design code: the package does not exist. Every language form in it was probed or exists in the tree.
> Replaces the surface of `avra-ui-assets-design/docs/2026_10_05_UI_ASSETS.md` (§9 says what survives).

## 0. The idea

Three small things, no new declaration kind:

| | what | built on |
|---|---|---|
| **A source is an input** | `file("…")`, `dir("…")`, `url("…")` name bytes outside the program. Each is a compiler input keyed by content. The value is a small handle. | `embed`, generalized and fixed |
| **A step is a pure fn** | A transform is an ordinary fn. A fn marked `@step` answers a `Blob` *lazily*: its key is known at once, its bytes are made when read. | `const` settlement, `const` seats |
| **A value can declare** | A folder is a `Set<T>` whose members are read as fields (`icons.close`). A spec is a *provider*: a `const` whose value also declares types beside it. | Declares annotations, `quote` |

`|>` is application: `x |> f(a)` is `f(x, a)`. A pipeline is a fn.

**What already exists (PROBED):** an annotation that mints a typed record from a list of names works today, in 0.14 s, with the right typo error (`no field 'clsoe' on 'IconsSet' — the fields are 'close', 'menu'`) and `avra expand` showing the generated code and the template line it came from. A compile-time-checked member lookup works today through `const` seats. The one thing an annotation cannot do is read a file: `this compile-time call cannot return build inputs`.

So this is mostly **opening one door (inputs) and persisting one family (settlements)**, not a new system.

## 1. What an author writes

```avra
use @std.source.{file, dir, each}
```

**1. A folder of icons.**
```avra
const icons = dir("./icons") |> vectors
icon(icons.close, color: .red)          // icons.clsoe: compile error listing the members
```

**2. A photo pipeline.** A pipeline is a fn; a folder maps it with `each`.
```avra
fn thumb(p: Picture) -> Picture { p |> resize(width: 320) |> webp(quality: 80) }

const photos = dir("./photos") |> pictures |> each(thumb)
const hero   = file("./photos/hero.jpg") |> picture |> thumb
image(photos.hero, alt: "The harbour")
```

**3. Per-target variants.** One value; the target picks.
```avra
fn responsive(p: Picture) -> Picture {
    p |> widths([320, 640, 1280]) |> formats([.Avif, .Webp])     // variants live INSIDE the Picture
}
const photos = dir("./photos") |> pictures |> each(responsive)
const logo   = file("./logo.png") |> picture |> at(.Program)      // override: embedded on every target
```
Web gets hashed files and `srcset`; a CLI or server embeds; iOS gets a catalog entry (§9).

**4. An OpenAPI client.**
```avra
const api = file("./petstore.yaml") |> openapi

let pet = api.pets.get(id: 3)?          // Result<Pet, PetsGetError>
fn show(p: Pet) -> string { p.name }    // `Pet` is declared by `api`
```

**5. A manifest as typed config.**
```avra
const config = file("./app.toml") |> toml
listen(config.server.port)              // int; `config.server.prot` is a compile error
```

**6. SQL.**
```avra
const db      = dir("./migrations") |> schema
const queries = dir("./queries") |> sql(db)
let rows = queries.active_users(conn, since: day)?   // List<ActiveUsersRow>
```

**7. Message catalogs.**
```avra
const messages = dir("./locales") |> catalogs(base: "en")
text(messages.greeting(name: user.name))             // a key missing from fr.toml is an error AT fr.toml
```

**8. A font.**
```avra
const inter = file("./Inter.var.ttf") |> typeface
const brand = default_theme with { face: { "body": .Bundled(inter) } }
```

**9. A shader.**
```avra
const blur = file("./blur.wgsl") |> wgsl
draw(blur, BlurUniforms { radius: 4.0 })             // uniforms typed from the shader
```

**10. CSV as a table.**
```avra
const cities = file("./cities.csv") |> csv
[c.name for c in cities.rows if c.population > 1000000]
```

**11. JSON Schema / proto.**
```avra
const events = file("./events.schema.json") |> json_schema
let e = OrderPlaced.from_json(body)?
```

**12. Docs pages.**
```avra
const pages = dir("./pages") |> markdown
routes: [page_route(p) for p in pages.items]         // the whole set escapes: every page ships
heading(pages.about.title)
```

**13. Environment, declared — never read at build.**
```avra
const env = file("./env.toml") |> environment        // the file holds NAMES and TYPES, no values
let e = env.load()?                                   // reads the process at RUN time: Result<Env, EnvError>
connect(e.database_url)
```
The build reads only `env.toml`. A compile-time run has no `env` row to call (§6), so no build can bake a secret in.

**14. A pinned URL.**
```avra
const stripe = url("https://raw.githubusercontent.com/stripe/openapi/v1000/openapi/spec3.json") |> openapi
```
Fetched once, pinned by SHA-256 in `avra.lock`, never fetched by `check` or `build --frozen` (§6).

### What the reader sees

**A typo.**
```
error[type.unknown_member]: `icons` has no member `clsoe`
  ╭─[src/app.av:9:12]
9 │ icon(icons.clsoe, color: .red)
  ·            ──┬──
  ·              ╰── read here
help: the members are `close`, `menu`, `arrow_left` — from ./icons (3 files)
```

**An error in the spec points at the spec.**
```
error[@std/openapi:ref]: `#/components/schemas/Pett` is not declared
   ╭─[petstore.yaml:41:19]
41 │           $ref: '#/components/schemas/Pett'
   ·                 ─────────────┬─────────────
   ·                              ╰── named here
   ├─ through `const api`, src/store.av:3
help: the schemas are `Pet`, `Order`, `Error`
```

**Explain** (P7). `avra docs <name>` and `avra expand <file>` exist; `avra explain` does not (PROBED: `unknown command: explain`).
```
$ avra docs api.pets.get
fn get(id: int) -> Result<Pet, PetsGetError>      — declared by `const api` (src/store.av:3)
  from      petstore.yaml:18   GET /pets/{id}   operationId getPetById
  provider  @std/openapi 0.3.0 · model kept · 1 of 212 names materialized

$ avra docs photos.hero --target web
Picture 320×180 webp — ./photos/hero.jpg (2400×1350 jpeg, 412 KB)
  steps     resized(…, 320, 180) → webp(…, 80)      made 14 ms · kept
  ships     hero.9c1f2ab0.webp 17 KB  at .Bundle
  reached   src/app.av:14
```

**Go to definition** of `Pet` lands on `petstore.yaml:52` (the provider names where each declaration came from); `avra expand src/store.av` prints the record it became, as it does today for a derive.

## 2. Writing one

### 2.1 A reader, 14 lines — a folder of icons

```avra
//! @acme/icons — a folder of SVGs as a set of icons.
use @std.source.{Dir, File, Set, Blob, each}
use @std.meta.{refused, refuse_at}

export type Icon = { name: string, width: int, height: int, shape: Blob }

/// Every `.svg` in the folder, by its stem.
export fn icons(d: Dir) -> Set<Icon> { d.files(ext: "svg") |> each(icon) }

fn icon(f: File) -> Icon {
    let box = view_box(f.head(512)) ?? refused(refuse_at(f.at(0), "`${f.name}.svg` has no `viewBox`", "an icon says its own size"))
    Icon { name: f.name, width: box.w, height: box.h, shape: f.content }
}
```
No trait, no registration, no codegen. `icons.close` works because the answer is a `Set` (§4.4).

### 2.2 A transform, with its batch form — `resize`

```avra
//! @std/image (excerpt)
use @std.meta.{step, batched}
use @std.source.{Blob, blob}

export type Picture = { name: string, width: int, height: int, format: Format, pixels: Blob, variants: List<Variant> = [], home: Home? = null }

/// No wider than `width`, shape kept. PLANNING IS ARITHMETIC: the new size is known
/// without touching a pixel, and the pixels are a promise.
export fn resize(p: Picture, width: int) -> Picture {
    if width >= p.width { return p }
    let height = max(1, p.height * width / p.width)
    p with { width: width, height: height, pixels: resized(p.pixels, width, height) }
}

/// THE STEP: bytes in, bytes out. Runs on a miss, when something reads the answer.
@step
fn resized(src: Blob, width: int, height: int) -> Blob {
    let out = with_room(width * height * 4)
    blob(out.slice(0, avra_img_resize(src.bytes(), width, height, out)))
}

/// THE BATCH FORM: every pending `resized` that differs only in its first seat, at once —
/// one decoder set up, one answer per input, in order.
@batched(resized)
fn resized_all(srcs: List<Blob>, width: int, height: int) -> List<Blob> {
    let codec = avra_img_open()
    let made = [blob(resized_with(codec, s.bytes(), width, height)) for s in srcs]
    avra_img_close(codec)
    made
}

extern fn avra_img_resize(src: Bytes, width: int, height: int, out: Bytes) -> int
```
The author writes two ordinary fns. Keys, caching, laziness, parallelism and batching are the compiler's.
(`out: Bytes` as a seat, never an answer: an extern answering `Bytes` is `type.host_seat` today — PROBED.)

### 2.3 A type provider — a JSON Schema subset

Objects of scalars, arrays and nested objects become records.

```avra
//! @acme/schema — a JSON Schema as Avra records with `from_json`.
use @std.meta.{Provides, Provided, provided, Anchor, Name, Decls, Code, Diagnostic, refuse_at, literal}
use @std.source.{File}
use @std.json.{parse_located, Located}

/// THE MODEL: what the file says. Parsed once, kept by the file's content.
export type Schema = { title: string, shapes: List<Shape>, problems: List<Diagnostic> }
/// One object schema: its path under the root (`[]` is the root), its fields.
export type Shape = { path: List<string>, slots: List<Slot>, at: Loc? }
export type Slot = { name: string, ty: string, at: Loc? }

/// The provider's whole public face: a fn from a file to a model.
export fn json_schema(f: File) -> Provided<Schema> {
    match parse_located(f.text()) {
        .Ok(doc) -> provided(modelled(f, doc)),
        .Err(e) -> provided(Schema { title: "", shapes: [], problems: [refuse_at(f.at(e.at), e.message, null)] }),
    }
}

impl Provides for Schema {
    /// The names this model declares, each with where it came from. No bodies.
    fn names(a: Anchor) -> List<Name> { [Name { name: type_name(a, s.path), at: s.at } for s in self.shapes] }

    /// ONE name's declaration, asked the first time something reaches it.
    fn declared(a: Anchor, name: string) -> Decls {
        let s? = self.shapes.find(type_name(a, it.path) == name) else { return quote {} }
        let fields = [quote { type _ = { ${f.name}: ${f.ty} } } for f in s.slots]
        quote {
            @json
            export type ${name} = { ..${fields} }
        }
    }

    /// The const's own value: what a program can ask the schema at run time.
    fn value(a: Anchor) -> Code { quote { Described { title: ${literal(self.title)}, root: ${literal(type_name(a, []))} } } }

    fn problems() -> List<Diagnostic> { self.problems }
}

/// `events` + `["order", "line"]` → `EventsOrderLine`. One derivation, so a name is stable while its path is.
fn type_name(a: Anchor, path: List<string>) -> string { [camel(p) for p in [a.name].concat(path)].join("") }

/// Walk the document into flat shapes; a nested object's slot names its own shape.
fn modelled(f: File, doc: Located) -> Schema {
    let found = shapes_under(f, doc, [])
    Schema { title: doc.text_at("title") ?? "", shapes: found.shapes, problems: found.problems }
}
```
`shapes_under` (25 lines of ordinary recursion over `Located`, mapping `"integer"` → `int`, `"array"` → `List<…>`, an unknown `type` → a `refuse_at` at its offset) is omitted; nothing in it is special.

**What a provider is:** a fn answering a *model* (plain data, settled and kept like any const) and one trait impl that turns the model into declarations, one name at a time. The compiler never loads a plugin; it calls three methods on a settled value.

Two things this example needs that do not exist: `parse_located` (`@std/json`'s `Json` carries no positions — READ `std-json/src/json.av:27`; `@std/toml` does — READ `toml.av:23`), and `@json` inside generated code being expanded (today it is silently dropped — PROBED, §11 I8).

## 3. `|>`

**The spec** (old tree, `docs/2026_04_18_FULL_SPEC.md` §28.7, L5667–5707 — READ(agent)): both `|>` and method chains; "`x |> f` desugars to `f(x)`"; "`x |> f(y, z)` desugars to `f(x, y, z)`"; a `_` placeholder for another seat; "lower precedence than most operators… Binds tighter than assignment, looser than arithmetic and comparison". Its examples START lines with `|>`; its own newline rule says continuation is a trailing operator — the spec contradicts itself.

**Today:** unparsed and unlexable. PROBED: `const k = 3 |> dbl` → `parse.expected: expected BREAK`. READ: `two_char_of` has no `|`/`>` arm (`grammar/lexer.av:525–549`).

**Decided here:**

| question | answer |
|---|---|
| meaning | `x \|> f` is `f(x)`; `x \|> f(a, k: v)` is `f(x, a, k: v)`. Parse-time sugar into a `Call`; typing and lowering never see it. Works at run time and compile time alike. |
| a stage is | a callee path with optional arguments, an optional trailing block, an optional `?`: `x \|> parse(strict: true)?` is `parse(x, strict: true)?`; `xs \|> each { it + 1 }` is `each(xs) { it + 1 }` |
| not a stage | a method (`x \|> .trim()` — write `x.trim()`), a bare lambda (call it), any other expression: refused, with the fix |
| precedence | loosest binary operator: `a + b \|> f` is `f(a + b)`; `a ?? b \|> f` is `f(a ?? b)`. `catch` stays looser: `x \|> f catch e -> d` is `(f(x)) catch …` |
| associativity | left: `x \|> f \|> g` is `g(f(x))` |
| lines | a line that STARTS with `\|>`, indented deeper, continues — the rule `.name` chains already have (`continued_by`, `lexer.av:666`). A trailing `\|>` continues too. |
| placeholder `_` | not in the first landing (Q6). `_` is a keyword today (READ CLAUDE.md, "`_` IS A PARAMETER NAME NOWHERE"), so it stays free for it. |
| `it` | unchanged: `it` belongs to the nearest fn seat; inside a trailing block it is the block's (PROBED `each(s) { dbl(it, by: 3) }` runs) |
| the formatter | a parse-owned mark on the `Call` (`piped`), exactly as `trailing` is kept today (READ `core/store.av:90,271`) |

**The lexer law.** "A TWO-CHARACTER OPERATOR ENDING IN `>` CANNOT BE MUNCHED" exists because `>` closes a type argument list. `|>` is safe to munch: no valid program has `|` directly before `>` — a type never ends in `|`, a table cell never starts with `>`, `a | > b` is no expression. PROBED: `grep '|>'` over every `.av` in `packages/` finds nothing but comments.

**The collision.** `docs/2026_09_30_PLATFORM_MAP.md:84,124` floats `order |> orders` as a channel send. One operator, one meaning: `|>` is application; a send is a method. (The channels design is live in another lane — tell it.)

**Landing.** Lexer arm + `continued_by` + one rule above `disjunction` in `features/expr_spine/mod.av` + a builder + the printer's scale (`compiler/format/source_text.av:2514`). ~150 lines. The compiler's own source does not use it yet, so it is one PR under the syntax-change protocol (`cp build/avra build/avra.pre`), plus a seed refresh before the tree starts writing it.

## 4. Semantics

### 4.1 Sources

```avra
export fn file(path: string) -> File     // path: a LITERAL, relative to the file that spells it, inside its package
export fn dir(path: string) -> Dir
export fn url(address: string) -> File   // a literal; pinned in avra.lock

export type File = { path: string, name: string, size: int, content: Blob }
export type Dir  = { path: string, files: List<File>, dirs: List<string> }
```
- A handle is a **capability**: the only way a compile-time run can read. There is no `read(path: string)`.
- `File.name` is the member name: the stem, `-`, space and `.` read as `_` (§5.3).
- `f.text()`, `f.bytes()`, `f.head(n)` read. `f.at(offset)` is a `Loc` inside the file, for diagnostics.
- `d.files(ext: "svg")` answers a `Set<File>`; `d.sub("icons")` answers a `Dir` (still inside the capability's root).
- A listing is sorted by name bytes. Names starting with `.` are never listed.

### 4.2 Blobs and steps

`Blob = { key: string, size: int? }` is bytes the build has, by key. It is an ordinary small record, so it settles today.

| a blob from | its key | when its bytes exist |
|---|---|---|
| a file | SHA-256 of the bytes | always |
| `blob(bytes)` | SHA-256 of the bytes | always |
| a `@step` call | digest of (the step's code fingerprint, each argument's fingerprint, the target if it read one) | when first read |

**A `@step` answers lazily.** Calling one at compile time runs nothing: it answers a `Blob` whose key names the call. `b.bytes()` forces it (and what it depends on). Purity makes this unobservable except in *when* a failure speaks.

Consequences:
- **`check` never transforms.** Sizes, formats and names are arithmetic over headers; no step is forced (carried over from the assets design, law 9).
- **The public name is the key.** Known before any encoder runs, so the cache entry and the shipped file name are one derivation (CLAUDE.md: "THE KEY… AND THE NAME… ARE ONE DERIVATION").
- **Per-step cache for free.** Change `webp(quality:)` and `resized` keys do not move.
- A step is a memo boundary only where the author marks one. An unmarked fn runs inside its caller's settlement.

### 4.3 Sets and `each`

```avra
export type Set<T> = { names: List<string>, items: List<T> }
export fn each<A, B>(s: Set<A>, f: fn(A) -> B) -> Set<B>      // PROBED: this fn settles in a const today
```
- A set is ordered (name bytes) and that order is the only one that reaches output.
- `each` maps; `kept(s) { … }` filters; `renamed(s) { … }` renames; `joined(a, b)` unions (a clash is refused naming both).
- **Fan-out** stays inside the item where the outputs are one thing (a picture's widths and formats are `variants`), and is a nested set where they are several (`pages |> each(translations)` is a `Set<Set<Page>>`; `pages.about.fr`).
- **Fan-in** is a fn from a set: `sprite(icons) -> Sheet`, `bundle(scripts) -> File`.
- A transform is written over the **item**. Whether std transforms also accept a set directly is Q1.

### 4.4 Members

> `x.name`, where `x` is settled and its type has no field `name` but has `fn member(const name: string) -> T`, reads `x.member("name")` at compile time.

- Absent → `type.unknown_member` at the read, listing `x.names()`.
- **The member is the laziness unit.** Each distinct member settles as its own unit (this is what `const` seats do today — READ `fns/tests/const_seat`). An unread photo is never planned, never made, never shipped.
- A name that is no identifier is read `x.member("2fa")` — a `const` seat, so still a literal checked at compile time. No lookup by run-time text exists.
- A set that escapes whole (`pages.items`) reaches every member; `avra docs` names the site.

PROBED today, without the sugar: `at(icons, "menu")` answers; `at(icons, "clsoe")` is a compile error (`const.trap`) — but spoken inside the library fn, not at the call (§11 I9).

### 4.5 Providers

> A top-level `const` whose initializer answers `Provided<M>` is an **anchor**: its value is `M.value(anchor)`, and `M.names(anchor)` are declared beside it, in its module, each materialized by `M.declared(anchor, name)` when first reached.

- The model `M` is settled like any const and kept by content: a spec is parsed once per edit.
- The initializer may name only literals, sources, **imported** fns, and other anchors. It runs before the file's names resolve, like an annotation's arguments (F2067) — this widens that law from "literals" to "what the `use` lines and the parse tree can answer".
- Export follows the anchor: `export const api = …` exports what it declares.
- Names are nominal, derived from the anchor's name and the data's own path (`Pet` for OpenAPI schemas; `ConfigServer` for a TOML table). A clash with a written name is `annotation.generated_taken` (exists).
- A provided type gets traits by the provider writing `@json`/`@derive(…)` in its template, or by a provider option (`openapi(derive: [Show])`).
- **Generative, not erased:** every provided declaration is a real declaration `avra expand` prints.

**Laziness for a 5,000-endpoint spec:**

| stage | cost | when |
|---|---|---|
| parse → model | once per spec content, kept on disk | first `check` after an edit |
| `names()` | a list of strings | at resolve |
| `declared(name)` | one template | the first time `name` is resolved |
| a type's `impl` | materialized with the type | first method lookup |
| typing, lowering, codegen | only what was materialized and reached | as today |

The unit is the **name**. Resolve needs every name early and gets them cheaply; nothing else is paid for an unreached endpoint.

### 4.6 Which one do I write?

| the data is | write | generated code |
|---|---|---|
| many things of one kind (icons, photos, pages, fonts) | a reader `fn (Dir) -> Set<T>` | none |
| one thing (a font, a shader's bytes) | a reader `fn (File) -> T` | none |
| a shape the data decides (config, spec, schema, CSV columns, catalog keys) | a provider | types and fns |
| a mixed folder as one record (`art.logo`, `art.icons.close`) | a provider over a `Dir` | one record type |

## 5. Laws

Each with the hostile case that tests it.

| # | law | hostile case |
|---|---|---|
| L1 | **Hermetic.** A compile-time run reads only through a handle, and a handle is minted only by a literal in the package it reads. | `file("/etc/hosts")`, `file("../../other/secret")`, a symlink out, a library fn taking a path string and calling `file(p)` — all refused at the literal. (Today `embed("/etc/hosts")` answers 256 — PROBED.) |
| L2 | **Pure.** No env, clock, network, randomness or process at build. | a step calling `@std.io.env` → `const.reach` naming the row and the chain (exists, PROBED) |
| L3 | **Keyed by content.** A key folds every input's bytes digest, the code's fingerprint, every argument, the target if read. Never a path's mtime; never a process-local ordinal. | touch a file without changing it → nothing reruns; swap two files' contents → both rerun; reorder declarations in the provider → nothing reruns |
| L4 | **One derivation.** The cache key, the shipped name and the receipt's row are one value. | two builds on two machines → byte-identical names and receipt |
| L5 | **Lazy.** `check` forces no step. `build` makes only blobs a reached value holds. | 2,000 icons, 3 used → 3 planned, 3 shipped; `check` on a tree with a broken encoder → clean |
| L6 | **Inspectable.** Every provided name and every shipped file answers "where from". | `avra docs Pet`, `avra expand`, `assets.json`; a name with no origin is a compiler defect |
| L7 | **Errors point home.** A refusal about the data points into the data, then names the anchor. | a bad `$ref` → `petstore.yaml:41`, never `openapi.av:212` |
| L8 | **No name by text.** A member or a provided name exists only by being spelled in source. | `icons.member(user_input)` → `type.const_seat` (exists) |
| L9 | **Order is the name's.** Listings, sets, receipts and generated declarations are in name-byte order. | a host listing in inode order → same output |
| L10 | **Big bytes stay out of the program** unless asked (`at(.Program)`), and over a budget that is an error whose help writes the override. | a 40 MB video in a set → not in the binary; `at(.Program)` on it → error naming the budget |
| L11 | **A failure in a step is the build's, not the check's** — and it names the step, the input and the reading site. | a truncated JPEG: `check` clean (header reads), `build` refuses at `./photos/hero.jpg` through `photos.hero`, `src/app.av:14` |
| L12 | **No silent drop.** An annotation, a hole or a file the compiler cannot place is spoken. | `@derive` inside a provider template (dropped today — PROBED) |

### 5.2 The empty case, first

| encoding | empty | decided |
|---|---|---|
| a dir with no entries | `Set { names: [], items: [] }` | legal and silent. A member read lists "no members". (Git does not carry an empty dir: a MISSING dir is an error at the literal.) |
| a file of 0 bytes | `File { size: 0 }`, `text()` is `""`, present | legal for `file`. A reader decides: `picture` refuses "0 bytes is no picture" at the file. |
| a blob of 0 bytes | key = SHA-256 of nothing, `size: 0` | a real value, distinct from "not made" (`size: null`). Absence and empty are two answers. |
| a step answering 0 bytes | made, size 0 | kept as made; never re-run as "missing" (the `once`-cache-of-null defect, CLAUDE.md) |
| a spec with no paths | a model with no names | legal and silent; `api` has no members |
| a set after `kept { false }` | empty set | legal; reaches nothing |
| a listing key | digest of (count, then each name's digest) | ARITY: folded per entry, never names joined by a separator — `["ab","c"]` and `["a","bc"]` differ |
| a step key | digest of (step fp, count, each argument's fp) | same law; a list argument folds to one value first |
| a lock entry for a 0-byte URL | sha256 of nothing, `size = 0` | pinned like any other |

### 5.3 Two hats — names

| case | decided |
|---|---|
| a path that is also a glob (`dir("./icons/*.svg")`) | **Split the verb.** `dir` takes a directory, always; `*`, `?`, `[` in it are refused with the fix. Filtering is its own typed seat: `d.files(ext: "svg")`. |
| `file` naming a directory, `dir` naming a file | refused at the literal, naming which it is |
| `icon-close.svg` | member `icon_close` |
| `hero@2x.png` | `@` is not mapped. The core refuses the name unless a reader claims it; `pictures` claims `@2x`/`@3x` as a density of `hero`. |
| `2fa.svg` | no identifier (PROBED: a digit-led field is a parse error). Listed, shipped, read as `icons.member("2fa")`. |
| `type.svg`, `match.svg` | keywords cannot be field names (PROBED `resolve.reserved`). Read as `icons.member("type")`. |
| `Close.svg` and `close.svg` | refused naming both: a checkout on a case-folding disk cannot hold them, so the build would differ by host |
| `logo.svg` and `logo.png` | one stem, two files: refused naming both; `files(ext:)` picks, or `files(names: .WithExtension)` gives `logo_svg`, `logo_png` |
| `a-b.svg` and `a_b.svg` | two files, one member: refused naming both |
| `café.svg` | identifiers are ASCII (PROBED `lex.error`). Read as `.member("café")` with the source's own bytes. Two names equal under Unicode normalization are refused (needs an NFC table — ASSUMED absent; until then a non-ASCII name is refused by `files()` unless `names: .Raw`). |
| `.DS_Store`, `.gitkeep` | never listed |
| a member named like a `Set` field (`names.svg`, `items.svg`) | a declared field wins (the law reads members only for names the type lacks); the file is read as `.member("names")`, and `files()` warns |
| a provided name that is a keyword or a written name | the provider refuses with `annotation.generated_taken`; OpenAPI offers `prefix:` |

## 6. Safety

**The capability model.**
- Rows a compile-time run may call: `Pure`, `Lookup`, and the new `Source` (reads through a handle). `World` never (exists: `Reach`, `core/ir.av:937`).
- A handle is minted by the compiler from a literal: resolved against the spelling file's directory, normalized, refused unless it stays under that file's package root with no symlink on the way (`@std/io`'s `open_beneath` already refuses `..` and symlinks — READ(agent) `io.av:227`).
- A dependency can read its own package's files and what the app hands it. It cannot name the app's files.
- `embed(p)` becomes `file(p).text()`. The hole closes by construction, not by a check.

**Third-party providers are code in the compiler.**

| code | runs in | can reach | trust |
|---|---|---|---|
| Avra | the evaluator, fenced by `Reach`, budgeted (steps, memory) | handles it was given | none needed — this is the default and it is sound |
| package C | native, in the build's worker process | **anything** | only if the ROOT manifest grants it |

```toml
# the app's avra.toml — nothing below the root can grant this
[build]
native = ["@std/image", "@acme/avif"]     # these packages' `pure` externs may run at build
```
```toml
# the package's own avra.toml — its promise
[link]
objects = ["build/img.o"]
pure    = ["avra_img_resize", "avra_img_open", "avra_img_close"]
```
- `pure` is a promise the compiler cannot check. `native` is the app accepting it. Without the grant: `const.reach`, whose help writes the line.
- The toolchain's own `@std/*` are granted implicitly — they ship with the compiler.
- A granted step still runs in a **worker process** with a memory ceiling and a wall-clock limit (§8), so a crash or a runaway is a located refusal, never a dead compiler.

**External tools (ffmpeg, ImageMagick): no, by default.** They are unpinned, unhashed, differ by machine, and are the usual end of reproducible builds. The hatch, when a tool is the only encoder: declare it as `[process.tools]` already requires (READ `packages/cli/avra.toml:8`), **pin its digest**, and the tool's bytes become an input in every key that runs it. An unpinned tool is refused at build time. Recommended to leave unbuilt until something needs it (AVIF, Apple's catalog compiler).

**URLs and the lock.**
```toml
# avra.lock — written by `avra lock`, never by hand; committed
[[source]]
url    = "https://raw.githubusercontent.com/stripe/openapi/v1000/openapi/spec3.json"
sha256 = "9f2c…"
size   = 5310022
```
| verb | does |
|---|---|
| `avra lock` | fetch every `url(…)` the sources spell that the lock lacks; write the pin |
| `avra lock --update <url>` / `--update-all` | re-fetch, show the size and digest change, rewrite |
| `avra check`, `avra build` | never touch the network: read `~/.avra/cache/<sha256>`; a miss says `run avra lock` |
| `--frozen` | also refuse a lock that would change |
- A URL is a literal. Only `https`. The bytes live in the machine cache by SHA-256; `avra vendor` copies them into the repo for a no-network CI.
- This is the first transport and the first lockfile in the tree (the assets design says the same, §4 there). Scope it as its own slice; `file` and `dir` do not wait for it.

**Reproducible.** Same inputs → same bytes. In a key: input content digests, the step's code fingerprint (its lowered closure, so a provider's version is covered without trusting a version string), every argument, the target when read, the digest of any granted C object. Not in a key: paths outside the package, mtimes, the machine, the time.

**mtime** is a fast path only: a per-machine side table `path → (mtime, size, inode) → digest` skips re-hashing an untouched file. A hit is trusted only when the stamp is older than the table's own write (the racy-git rule). The digest is the key; the stamp never is. `avra dev` and `@std.io.watch` (on branch `os-watch`, not in this tree) wake the same door.

## 7. Mechanism — what each idea is made of

| idea | made of (exists) | new |
|---|---|---|
| sources | `Reach.Embed`, `Host.read`/`list` (`compiler/host/host.av:8`), the `Source` and `Manifest` input families | an `Input` family for bytes, listings, pins, target; `Reach.Source`; four rows |
| blobs | `Store.keep_file`/`place`, `staged_beside`/`published` (atomic) | a content-addressed `blobs/` outside the per-compiler store root |
| steps | `Family.Settled`, `settled_symbol`, kept verdicts (`kept_settle.av`) | `@step` marker (a marker annotation, like `@plans`); lazy answer; content keys; durable rows for seat-specialized units |
| members | `const` seats and their per-value units; `SettleRoot.Expr` (components' `check()` settles so) | one typing rule; one voice; settledness through a member chain |
| providers | Declares annotations run inside resolve; `quote`, field spreads, `generated_named`, `generated_export`, `avra expand` | the const anchor; per-name materialization; `Reach.Source` in a Declares run |
| outputs | settled aggregates are static data (`Ins.StaticAddr`) | reached-artifact collection; the build's emit step; the receipt |
| `\|>` | the expression spine | one rule |

## 8. Performance

**Measured (Appendix C):**

| fact | number |
|---|---|
| evaluator, tight loop | **2.4 µs per iteration** (1M iterations 2.4 s; linear to 20M = 48 s). Native: ~1–3 ns (ASSUMED) → **~1000× slower** |
| evaluator, parsing | TOML 17 KB in 0.6 s (**~28 KB/s**); JSON 19 KB parse + print in 0.4 s (**~45 KB/s**) |
| default settlement budget | 600,000 steps, 5 MiB (READ `features/worklist.av:46`) — a 1M-iteration loop is refused (PROBED) |
| a 4 MB text const | `check` 0.27 s, 66 MB peak; it becomes static data in the binary |
| a provider minting a 2-field record + const | 0.14 s end to end |
| parallelism in the compiler | object emission only: 4 threads (READ `llvm.av:179`). Analysis and settlement are single-threaded. |
| the compiler's own cold build | ~10–13 s; one edit 0.3–0.4 s (READ(agent) `COMPILER.md:137`) |

**What follows:**
- A pixel never goes through the evaluator. 12 MP × 2.4 µs is hours. **Codecs are package C**, called from a step; the evaluator only orchestrates (tens of steps per image).
- A 5 MB spec in today's evaluator is ~2–3 minutes cold. Kept by content, that is paid once per spec edit — still not good enough. **Fix the evaluator first** (§11 I5): 2.4 µs for `t = t + i % 7` is ~100× off what a register interpreter does. Then a native tier (a JIT behind `run_call`, already listed "Later" in `COMPILER.md:484`) is an optimization, not a prerequisite.

**The cost model.**

| phase | cold | warm (nothing changed) | one photo edited |
|---|---|---|---|
| hash inputs | read + SHA-256 every source file (~1 GB/s) | stat each (stamp table); 0 bytes read | 1 file re-hashed |
| listings | one `readdir` per `dir` | same; digest compared | same |
| plan (settle reached members) | header read + arithmetic per reached member, ~µs–ms each in the evaluator | 0 — kept by content key | 1 member re-planned |
| provider model | one parse per spec | 0 — the model is read from the store | 0 |
| make (build only) | every reached blob, in parallel workers, batched | 0 — blobs exist by key | that photo's steps only |
| emit | write/link each reached artifact | hard-link or skip when the output dir already holds the name | 1 file |

- **Workers.** Making is embarrassingly parallel and has no shared state: each blob is written to the store by atomic rename under its own key. The build re-executes itself as N workers (the hand-off `cli/src/stage.av` already does for the test suite — READ CLAUDE.md "The CLI"), each given a slice of pending keys. N defaults to half the cores, capped at 8. No thread-safety is asked of the kernel. Parallel *settlement* stays out of scope.
- **Batching** is how a worker runs its slice: pending calls of one step that differ in the first seat go to its `@batched` twin once. Laziness and keys stay per item.
- **Where blobs live.** `~/.avra/cache/blobs/<k2>/<key>` by default (`AVRA_CACHE_DIR` moves it), shared by every worktree and every compiler version — a blob's key already covers the code that made it, so it does not belong under the per-compiler store. Step rows (key → size, made-in-ms, inputs) sit beside them.
- **Remote cache.** The store is `get(key)`/`put(key)` over immutable content — the Bazel shape. One hook: `[build] cache = "https://…"` tried on a local miss, verified by key on arrival. A slice of its own; nothing else changes when it lands.
- **Collection.** `avra cache gc` keeps what any `assets.json` or kept verdict under the machine's known trees names, plus anything read in N days; a size cap evicts oldest-read first.
- **Memory.** Blob bytes never enter the kernel's memo: values hold handles. A worker's ceiling is `[build] step_memory` (default 1 GiB) and `step_seconds` (default 60), enforced by the OS on the worker.
- **`avra dev`.** Nothing is made at startup. The dev server's asset route forces a blob on first request and caches it by key. One photo edited → its `File` digest moves → one member's key moves → one new name → that node reloads. This needs inputs that can be re-read in a long-lived process (§11 I10).
- **Reachability** (avra-8sb5.76) and this are the same demand: a member, a provided name and a blob are each paid for only when reached.

## 9. Outputs and targets

**One value, many projections (P12).** A `Blob` reaches a running program as an `Artifact`:

```avra
export type Artifact = { name: string, size: int, key: string, home: Home }
export enum Home { Inline, Program, Bundle, Cdn(origin: string) }
```
- `name` is `stem.<key8>.<ext>` — cache-busting is the key.
- A library places a blob: `placed(p.pixels, stem: p.name, ext: "webp", home: p.home ?? default_home(target(), p))`.
- `target()` is a compile-time input (surface, OS, arch, profile). Whatever reads it is keyed by it.
- **Reached = shipped.** An `Artifact` that survives into the lowered program's static data is reached; the build collects exactly those, forces their blobs, and writes them.

| home | the build writes | the program holds | `a.bytes()` at run time |
|---|---|---|---|
| `.Inline` | nothing | the bytes inside what draws it (an SVG path in the page) | — |
| `.Program` | static data in the binary | name, size, an address | yes |
| `.Bundle` | `build/<target>/assets/<name>` | name, size | compile error: "not in the program — `at(.Program)`" |
| `.Cdn(o)` | the file, for `avra deploy` to upload | name, size, origin | compile error |

**Default home, by target** (carried over from the assets design §5; an item's `at(…)` overrides):

| target | default |
|---|---|
| CLI, TUI, server | `.Program` up to a budget (1 MiB per artifact, 16 MiB total); over it, an error whose help writes `at(.Bundle)` |
| web page | `.Bundle`; an icon shape or a picture under 2 KB `.Inline` |
| iOS, Android | `.Bundle` — the catalog, `res/` |

The compiler moves an asset between `.Inline` and a file by itself. It never moves one between `.Program` and `.Bundle` by itself: that changes what must be deployed.

**How a component receives it.** `image` takes a `Picture`; `icon` a `Vector`; a theme's face a `Typeface`. Each carries what layout needs — width, height, format, dominant tone, font metrics — as static data, so nothing is probed at run time and layout never jumps. Components stay ordinary: `icon(icons.close, color: .red)`.

**What `avra build` writes.** `build/<target>/assets/…` and `build/<target>/assets.json`: every artifact, its key, size, home, source file and licence. `assets_route()` serves from that table; a name not in it is a 404 without touching the disk.

**Reconciled with `2026_10_05_UI_ASSETS.md`.**

| that design | here |
|---|---|
| `asset art = "art" { hero { dark: "…" } }` | **replaced**: `const art = dir("./art") \|> assets` (a provider over a `Dir` for a mixed folder), or a `Set` per kind. Variants are an ordinary argument: `pictures(dark: "-dark")` or `p \|> with_dark(file("./hero-dark.jpg"))`. |
| kind from the bytes; `trait Asset`, kinds collected program-wide | **kept as library**: `assets` sniffs leading bytes and dispatches to readers. No program-wide collection: the reader is named in the pipeline. |
| law 3 no lookup by text · 5 path literal inside the package · 8 intrinsic size · 9 check never transforms, name = key · 10 only reached ships · 14 vector model · 15 font licence · 17 no silent downgrade | **kept** (L8, L1, §9, L5/L4, L5, library, library, L11) |
| `project() -> List<Artifact{name,key,make}>` | **kept, simpler**: `make` is the lazy `Blob`; no closure in a value |
| `at <home>` on a declaration | **an argument** (`at(.Program)`), no grammar |
| per-target table, receipt, `explain`, homes, `remote(url, w, h)` | kept |
| fetched pinned packages, `avra.lock`, `~/.avra/cache` | kept; the same lock serves `url(…)` |
| font subsetting and shaping (§6 there) | untouched by this design; a `typeface` reader is its front door |

`docs/2026_10_05_UI_ARCHITECTURE.md` decides `src` carries a `Url` with no unsafe value (:161–171 — READ(agent)). A `Picture` projects to a `Url.Local` on web; the law stands. `docs/2026_09_30_PLATFORM_MAP.md` says nothing about assets (READ(agent)).

## 10. The same mechanism, other consumers

| consumer | today | fits |
|---|---|---|
| `embed` | its own row, path hole, text only, string-matched callee | **as-is, and it shrinks**: `file(p).text()` |
| the CLI reading `avra.toml` | `Family.Manifest`, a bespoke input | **as-is**: it is an `Input` of kind file; typed access is the `toml` provider. The compiler keeps its own reader (it cannot depend on a provider to find packages). |
| `@std/db` `@model`, `@std/relation` | an annotation over a written type | **should not move**: the source of truth is the Avra type. The inverse (`dir("./migrations") \|> schema`) is a provider and coexists. |
| the docs `site` | pages are string literals in view fns (READ(agent) `site.av:60`) | **as-is**: example 12 |
| `wire.gen.js` (`make ui-host`) | run a program, check in the output, `cmp` in the gate | **with change X**: an *outbound* artifact — `const host = placed(blob(host_table().bytes()), …)` at `.Bundle`. Needs artifacts (§9), nothing else. The checked-in copy and the gate step go. |
| `features/rt.av` from `rt_sigs()`, `avra_rt.h` | same generate-check-in-`cmp` loop, twice | **the header: as above.** **`rt.av`: should not, yet** — it is the compiler's own source, so generating it at compile time is a bootstrap cycle; the seed would need it. Keep the loop. |
| sublanguages (`grammar {}`) | expand at the parse, nothing evaluated | **should not fit**: syntax, not data. A provider may *use* a grammar to read a file. |
| i18n | nothing | **as-is**: example 7 |
| `@std/openapi` | emits a spec FROM routes at run time (READ(agent) `openapi.av:59`) | **the inverse fits**: reading a spec is a new provider beside it. Emitting `openapi.json` at build is an outbound artifact. |
| design tokens (`tokens(embed("design/tokens.json"))`, `2026_09_29_WEB_UI.md:883`) | a doc sketch | **as-is**: a provider |
| the compiler's three generate-and-diff gates | hand-rolled | the pattern has a name now: **an outbound artifact** |

**Is there already a general solution?** Half of one, twice:
- **Declares annotations are the general "a compile-time call that declares".** Providers are that door with a const anchor and an input. Not a parallel concept.
- **`@relation` / `@query` / `@input` are the general "memoized query over inputs"** — built, tested, and not wired to the compiler's own kernel or to disk (§11 I2). Steps should be the second consumer of that durable door, not a third bespoke cache.

## 11. Compiler changes

**The minimal list.** "Rungs" = compiler generations the landing needs.

| # | what | where | why nothing existing says it | size | landing |
|---|---|---|---|---|---|
| C1 | `\|>` | `grammar/lexer.av`, `features/expr_spine/{mod,builders}.av`, `core/store.av` (a mark), `compiler/format/source_text.av` | no operator applies a fn to a left value | ~150 lines | 1 PR; syntax-change protocol; seed refresh before the tree writes it |
| C2 | inputs: `Reach.Source`, rows `source_file` / `source_dir` / `source_read` / `source_head`, an `Input` family through `Host`, handles minted with the containment law; `embed` rides it | `core/ir.av`, `core/runtime_api.av`, `compiler/backend/interp.av`, `compiler/workspace*.av`, `compiler/whole.av` (delete `admit_embeds`), new `packages/std-source` | `embed` is text-only, escapes its package, and mints a `FileId` in the source table | ~500 | `Reach` is a registry enum: every consumer spelled (`make vocab`). Rows declared from a NEW package (`@std/source`), not from the compiler's closure → one landing; if `@std/meta` declares them, two (the row-then-declaration ladder) |
| C3 | members: `x.name` over a settled value with the `member` contract; the located voice; settledness through a chain | `features/expr_spine` typing of a property read, `features/values.av` / `lower/state.av` (`SettleRoot.Expr`) | a `const` seat call does this but speaks inside the callee and does not chain (PROBED) | ~250 | 1 PR |
| C4 | blobs + `@step`: lazy keyed answer, `bytes()` forces, content-addressed store, durable step rows, workers, `@batched` | `compiler/store/store.av`, `interp.av`, `kept_settle.av`, `cli/src/stage.av` | no persisted memo below a whole const; no byte store | ~700 | after I2, I3 |
| C5 | artifacts: reached-static collection, the emit step, `assets.json`, `target()` | `compiler/lower`, `compiler/build.av`, `compiler/link.av` | nothing writes a file beside a binary | ~400 | 1 PR |
| C6 | provider anchors: `Provided<M>`, the initializer lifted before resolve, per-name materialization, diagnostics located in a non-`.av` input | `compiler/expand.av`, `compiler/workspace.av` (`has_declares`, `generated_named`), `features/annotations/check.av`, `packages/std-meta`, `features/crossing.av` | a Declares site is an annotation over a written declaration, eager per file | ~600 | `@std/meta` grows (`Provides`, `Anchor`, `Name`): growth crosses without a seed refresh until something READS the new fields — the first reader owes it |
| C7 | native at build: `[link] pure`, `[build] native`, the reach gate consults them | `compiler/host/manifest.av`, `interp.av:535` (`reaches_out`) | every package extern is `World` at compile time | ~80 | 1 PR |
| C8 | `url`, `avra.lock`, `avra lock`, a SHA-256 row | new command file, `packages/std-source` | no transport, no lockfile, no plain SHA-256 (READ(agent): only `hmac_sha256`, `std-tls/src/mac/mac.av:16`) | ~400 | its own slice |

Not on the list: a JIT; parallel settlement; any new declaration keyword; any new IR instruction.

### Infrastructure to fix first

Ranked by how hard it bites this consumer. Each is a proposed ticket.

| # | rough edge | evidence | proposed ticket |
|---|---|---|---|
| **I1** | **An input outside the source text is not a concept.** Two input families (`.av` text, `avra.toml`). Everything else is ambient or bespoke: `embed` reads with `avra_selfhost_read_file`, bypassing `Host`, then registers after the fact by minting a `FileId` in the SOURCE table; directory listings are hashed by hand in two places; tool identity in none. | READ `interp.av:845–859`, `workspace_analysis.av:576–581`, `whole.av:168–174`; READ(agent) `db.av:675`, `kept_settle.av:224`; tickets avra-8sb5.68, .69 | **One input door.** `Input { Bytes(path), Listing(path), Pin(url), Target, Tool(name) }` through `Host`, digest-keyed, stamp fast path. `embed`, manifests, listings, `wasm-opt`'s identity and the linker's all ride it. Closes .68 and .69 as instances. |
| **I2** | **Persistence is bespoke: 17 hand-written write sites, no query family persists.** `Lifted` and `Expanded` (every annotation and derive) are memory only: re-run in every cold process. A seat-specialized settlement is never kept (`ask.seats.is_empty()`). The `.deps` edges are written and never read. | READ `kept_settle.av:40`, `store.av:104`; READ(agent) the 17 sites (Appendix B), `ADDING_A_PROJECTION.md` "Not yet" | **The durable door (avra-8sb5.57.6), before this.** A family opts in with a derived codec and gets answer + hash + dependency list persisted, validated by input digests. `Settled` (all units), `Lifted`, and steps are its consumers. |
| **I3** | **Identity is an ordinal plus a side string.** `const$<FileId>$<StmtId>`, `lift$<file>$<call>$<decl>`: process-local, positional, re-interned through a `Map<string,int>`. A reordered file or a second process has a different name for the same computation. | READ `features/worklist.av:132–141`, `workspace_analysis.av:696`; ticket avra-8sb5.36 (the positional wire, patched by a re-check, "root rewrite = townhall decision 10") | **Content keys for compile-time calls**: (callee closure fingerprint, argument fingerprints). One derivation for the memo key, the store key and the artifact name. |
| **I4** | **The store is one compiler's, per worktree, evicted whole.** Root = digest of the compiler binary + mode; 4 stores kept; no GC inside one, no size cap, no row atomicity, no lock, no sharing. A rebuilt compiler discards everything, including results that do not depend on it. | READ `build.av:186–197, 227, 302`; READ(agent) `store.av:136–149`, `DB_REDESIGN.md §8` | **Split the store.** Compiler-dependent rows stay under the print. Content-addressed blobs and step rows move to a shared machine cache with atomic writes, a size cap and `avra cache gc`. |
| **I5** | **The evaluator is ~1000× native** and a `Map` filled in a loop is quadratic in memory. | PROBED 2.4 µs/iteration, 28–45 KB/s parsing; ticket avra-8sb5.73 (8,000 map sets peak 867 MB) | **Profile `run_call`'s hot loop; target 20×.** Then decide the JIT on numbers. A real provider (OpenAPI) is blocked on this; icons and photos are not. |
| **I6** | **Every package extern is `World` at compile time**, so `@std/json`'s `parse` cannot settle: it reaches `avra_str_parses_float` in `@std/text`. | PROBED `const.reach` with that chain; READ `interp.av:535–541` | **`[link] pure`** (C7), and mark `@std/text`'s scanners first. |
| **I7** | **`embed`'s defects.** (a) escapes its package; (b) nested in any expression it traps the compiler: `a 'File' write moved the whole relation after a compiler query … read it`; (c) a missing or non-UTF-8 file is an unlocated `avra:` trap; (d) the callee is found by the STRING `"embed"`; (e) text only; (f) reaching it at run time is a trap, not a refusal. | PROBED a, b, c; READ d `whole.av:382`; READ(agent) e, f (`FEEDBACK.md:4514`) | (a) is in flight on another branch. **(b)–(f) go away with C2**; do not fix them separately. |
| **I8** | **An annotation inside generated declarations is silently dropped.** `@derive(Show)` on a provided type: no method, no diagnostic. | PROBED | **Expand generated annotations, or speak.** A provided type cannot get `@json` without it. |
| **I9** | **`const` seats: three gaps.** A trap in the callee's inner `const` is spoken in the library, not at the call; a generic `T` const inside one is `const.form`; a call with all seats settled is not itself settled (`at(at(outer, "in"), "x")` → `type.const_seat`). | PROBED all three | Folded into C3; the first is a voice fix worth landing alone. |
| **I10** | **Inputs load once per process; there is no long-lived mode in this tree.** | READ `query/memo.av:126–141`; READ(agent) `COMPILER.md §8` | **A re-read verb on inputs**, for `avra dev` (lives on branches `ui-dev`, `os-watch`). |
| **I11** | **A new family costs ~8 edit sites** and a hand-written fingerprint closure; constants and dense ids are used as hashes. | READ(agent) `workspace.av:510–554, 974, 1398`, `db.av:160–216` | Derive the row plumbing from the `@family` mark (the `collect enum` is already there). |
| **I12** | **A diagnostic cannot be rendered into a non-`.av` input** without that file being in the source table. | READ `workspace_analysis.av:580` (the embed is forced through `self.source`) | A text input projects to a `SourceFile` on demand (C6). |
| **I13** | **A partly-held rebuild peaks 1.6× a cold one**; `Kernel.newly_read` holds 363 MB in 5.1 M boxes. Every kernel op snapshots and replaces the whole state. | tickets avra-8sb5.57.163, .76 (comment); READ `kernel.av:300–339` | Already ticketed. Named here because 5,000 members are 5,000 more queries. |
| **I14** | **`avra explain` is documented in CLAUDE.md and absent from the tree.** `avra cache why` re-derives cold and prints relation families as `Relation N(arg)`. | PROBED `unknown command: explain`; READ(agent) `cache_walk.av:4–6, 98–111` | One inspection verb that names a value's inputs, steps and outputs. |

**What is already good and general** (so it is built on, not replaced): the kernel itself (dependency discovery by execution, red-green, early cutoff, cycles, dynamic family registration); `Reach` as the compile-time fence; the digest-not-stamp law; `staged_beside`/`published` atomic publish; "the sources are the hold's oracle" (a cache bug costs time, never correctness); Declares annotations with hygiene and `avra expand`; `const` seats; `AVRA_DEP_AUDIT` for untracked reads.

## 12. Prior art

| | better than this design today at | steal | pain to avoid |
|---|---|---|---|
| **F# type providers** | IDE integration; a decade of providers (SQL, JSON, CSV, OpenAPI) | "the schema is a file in the repo"; sample-driven inference | erased types vanish from tooling; design-time and run-time are two assemblies; schema drift at run time; the IDE re-runs providers on every keystroke. Here: generative only, one package, kept by content. |
| **Zig** comptime + `@embedFile` | comptime is the language itself, at native-ish speed | no separate macro language | `@embedFile` puts bytes in the binary — nothing else; no types from data without hand-written comptime parsers |
| **Rust** `include_bytes!`, proc-macros, `build.rs`, sqlx offline | ecosystem; sqlx's checked queries | sqlx's offline mode = a committed snapshot (our lock + kept model) | `build.rs` and proc-macros are unsandboxed native code with ambient I/O; rerun rules are hand-written (`cargo:rerun-if-changed`) and often wrong |
| **Bazel / Buck** | hermetic actions, remote cache and execution at scale | the action key; content-addressed store; persistent workers | BUILD files beside the code, a second language. Here the graph is the program. |
| **Nix** | the derivation: the output path is known before building | lazy keyed outputs (`@step`) | evaluation cost; a store that grows without bound |
| **Vite / webpack / esbuild** loaders, import attributes | the dev loop; a huge plugin ecosystem | on-demand transforms in dev; hashed names | imports of non-code are untyped strings; plugin order is global config; caching is per-plugin |
| **Parcel** transformers | zero-config pipelines keyed by content | per-asset pipelines | config by file extension |
| **Next.js** image | request-time resize, `srcset` from one prop | intrinsic size required; variants inside the picture | needs a server at run time |
| **Swift asset catalogs / SwiftGen**, **Android `R`** | native platform integration, density and dark variants | the catalog is our iOS/Android projection; `R.drawable.close` is `icons.close` | SwiftGen is a pre-build script; `R` is ints, untyped across kinds |
| **Flutter** assets | simple declaration | — | string keys, checked at run time |
| **Gleam / Elm** codegen | simple: generated source is checked in and readable | `avra expand` gives the readable half without the check-in | stale generated files; a generate step outside the compiler |
| **Unison** | code and results stored by hash | content keys for computations (I3) | — |
| **Salsa / Adapton** | the query model itself | durable, validated-by-input-digest answers (I2) | — |

**What this does that none do together:** the pipeline is ordinary typed code in the language; only what the program reaches is planned, made and shipped; the cache key, the file name and the receipt are one value; a third-party provider is sandboxed by default; and the same handle is a typed value in a CLI, a web page and an iOS app.

## 13. Build order

Each slice ends in something usable and landable.

| # | slice | kind | usable at the end | needs |
|---|---|---|---|---|
| 1 | `\|>` | compiler (C1) | pipelines everywhere, at run time too | — |
| 2 | the input door; `@std/source` v0: `file`, `dir`, `text`, `bytes`, `Set`, `each`; `embed` on top of it | compiler (C2) + library | `const cfg = parse_toml(file("./app.toml").text())`; a folder as a `Set` read with `.member("close")`; the `embed` hole and trap gone | I1 (this slice *is* I1), I7 |
| 3 | members | compiler (C3) | `icons.close`, with the right error | I9 |
| 4 | `[link] pure` + `[build] native`; `@std/text` scanners marked | compiler (C7) | `@std/json` and codecs run at build | I6 |
| 5 | artifacts and `target()`; `Picture`/`Vector` readers; `image`/`icon` take them; web, html, tui, headless | compiler (C5) + library | `icon(icons.close)` ships a file on web and embeds in a CLI; `assets.json`; `wire.gen.js` as an artifact | 2, 3 |
| 6 | the durable door and content keys | infra (I2, I3, I4) | settlements, lifts and derives survive a process; the compiler's own cold `check` gets faster | — (independent; start early) |
| 7 | blobs, `@step`, workers, batching; `@std/image` resize + webp | compiler (C4) + vendored C | the photo pipeline, lazy, parallel, kept | 4, 5, 6 |
| 8 | provider anchors; `toml`, `csv`, `environment`, `json_schema` | compiler (C6) + library | typed config, typed tables, typed env | 2, I8, I12 |
| 9 | evaluator speed | infra (I5) | every settlement and derive is faster | — (independent; start early) |
| 10 | per-name laziness; the OpenAPI client | library + C6's second half | `api.pets.get(id: 3)?` over a real spec | 8, 9 |
| 11 | `url`, `avra.lock`, `avra lock` | compiler (C8) | a pinned remote spec; the transport packages will reuse | — |
| 12 | `avra dev` incrementality; remote cache hook; iOS/Android projections; `catalogs`, `sql`, `wgsl`, `markdown` | mixed | the rest of §1 | 7, 8, I10 |

Pure library after its slice: every reader and provider. Slices 1, 6 and 9 can start today, in parallel, with no dependency on each other.

## 14. Open questions

**Q1. Do transforms map over a set by themselves?**
```avra
const photos = dir("./photos") |> pictures |> each(thumb)                      // A: explicit
const photos = dir("./photos") |> pictures |> resize(width: 320) |> webp(80)   // B: every std transform takes an item OR a set
```
Recommend **A now, B later**. A keeps `x |> f` meaning `f(x)` and keeps fan-out honest. B is expressible today only for a nominal set type per kind (PROBED: `fn resize<P: Pictures>(p: P, …) -> P` runs); over a generic `Set<T>` it needs a bound on an impl, which is refused. B is additive when that lands.

**Q2. Member reads: sugar, or spelled?**
```avra
icon(icons.close)               // A: `x.name` reads a settled member
icon(icons.member("close"))     // B: the const-seat call, written out
```
Recommend **A**. It is the whole ergonomic point, the error lists the members, and the rule is one sentence. B stays as the door for names that are no identifier.

**Q3. How is a provider anchored?**
```avra
const api = file("./petstore.yaml") |> openapi      // A: the const is the anchor
@openapi("./petstore.yaml") type Petstore = {}      // B: today's annotation over an empty type
```
Recommend **A**. B works today with a path literal (PROBED) but anchors on a declaration that means nothing. A costs C6.

**Q4. What are provided names called?**
```avra
fn show(p: Pet)           // A: bare, in the anchor's module; a clash is refused; `openapi(prefix: "Store")` is the hatch
fn show(p: ApiPet)        // B: always prefixed by the anchor
```
Recommend **A**: put the anchor in its own file and the module is the namespace (`use store.{Pet}`), which is already how modules work. Data whose own names are paths (a TOML table) is prefixed because it has no name of its own (`ConfigServer`).

**Q5. May a package's C run at build?**
```toml
[build]
native = ["@std/image"]     # A: yes, only where the ROOT grants it; std is granted
                            # B: never — codecs wait for a native tier for Avra code
```
Recommend **A**. Without it there is no image pipeline this year. The grant is explicit, at the root, and the step still runs in a capped worker.

**Q6. `|>`: placeholder and leading lines.**
```avra
x |> format("v: {}", _)     // A: `_` places the value in another seat
x                            // B: a line may START with |>
    |> f
```
Recommend **B now, A later**. B is how every pipeline is written and matches `.name` chains. A is rarely needed once APIs take the subject first; `_` stays reserved for it.

**Q7. Does `url(…)` land with this, or with package transport?**
```avra
const api = url("https://…/spec3.json") |> openapi    // A: slice 11 here, minimal: https + sha256 + avra.lock
const api = file("./vendor/spec3.json") |> openapi    // B: vendor the file until packages bring a transport
```
Recommend **B for now**: `file` and `dir` cover everything in §1 but one line, and the first lockfile deserves its own design with fetched packages.

**Q8. Fix the evaluator, or build a native tier?**
```
A: profile and fix the interpreter (target 20×), keep one engine at build
B: JIT settlements through the LLVM already in the process
```
Recommend **A first**. 2.4 µs per loop iteration says there is a cheap order of magnitude. A JIT adds traps, fuel and a second engine to keep honest; decide it on numbers after A.

---

# Appendix A — every compile-time mechanism today

| mechanism | lives | runs | mints names? | reads | cached | cost / budget | real consumers |
|---|---|---|---|---|---|---|---|
| `const` settlement | `compiler/workspace_analysis.av:451,568`; `backend/interp.av:352` | after typing; lazily on a lowered read, eagerly for every const in a build (`derive.av:597`) | no | pure code from any package; `embed` | `Family.Settled`, in memory; kept verdict on disk only for unseated consts (`kept_settle.av:40`) | 600,000 steps, 5 MiB, raised by the ROOT's `[lifted]` | every package; `consts/tests/*` |
| `const` seats | `features/fns/mod.av:51`, `checks.av:1627` | typing + lowering; a unit per settled value | no | — | in memory, per value fingerprint | as above | regex-like `matches`, routes |
| annotations: Validates / Records | `features/annotations/check.av:27,168` | at typing | no | the declaration; computed arguments | `Family.Lifted`, memory only | as above | `@impact`, `@deprecated`, `@plans` markers |
| annotations: Declares / Derives | same; `compiler/expand.av:93,124`; `workspace.av:1518` | **inside resolve** | **yes**, into the file; other packages see them (`modules.av:378`) | the declaration from the PARSE store; literal arguments only (F2067); `type_named` | `Lifted`, `Expanded`: memory only | as above | `@json`, `@model`, `@relation`, `@query`, `@form`, `@action`, `@derive(Show/Eq/Decode/View/Codes/…)` |
| `quote { }` | `features/quote/mod.av:13` | parsed where written; spliced in expansion | via a directive | — | — | — | every derive |
| sublanguages (`grammar`, block words) | `features/sublang/mod.av:24` | at the parse; nothing evaluated | no | the provider module's plain parse | `Family.Plain` | — | `@std/sql`'s lexicon; no production block word (READ(agent)) |
| components | `features/components/mod.av:22` | a one-`quote` `expand` at the parse; a computing `expand` is refused (`template.av:88`) | no | `self` | — | — | `@std/cli` (`command`, `flag`), `@std/ui` (every primitive), `@std/http` (`get`, `server`), `rule` |
| `rule` | `features/rule.av:44` | a component instance; patterns are quotes | no | — | — | — | the idiom gate |
| `table<Row>` | `features/tables/mod.av:14` | parse-time sugar | no | — | — | — | registries |
| `collect` / `collect enum` | `features/collects/mod.av:37` | lowering; `collect enum` mints variants | variants | declarations of a kind | — | — | `Family` itself (`families.av:150`) |
| `embed` | `std-meta/src/meta.av:311`; `interp.av:845` | at settlement; admitted at the parse by callee NAME | no | one text file, any path on the machine | touched as a `Source`; `KeyParts.runs` covers it per file (`record.av:1092`) | — | tests only; no production use (READ(agent)) |
| the `@std/meta` crossing | `features/crossing.av` | each lift | — | slot-ordered records | — | — | every annotation |
| the extern host | `interp.av:1360`, `interp_host.av:255` | `avra run` only | — | a package's `.dylib` | — | — | `@std/io`, `@std/process` under `avra run` |

**Answers asked for:**

| question | answer | receipt |
|---|---|---|
| Can a `const` hold a record whose FIELDS came from data, so `photos.hero` types? | Not by itself: a const's type is its initializer's static type. **Yes through a Declares annotation** that generates the record type and the const. | PROBED C.6 |
| Can a compile-time fn read a file? | Only `embed`, only a literal, only text, only in a const settlement. `read_text` is `const.reach`. A Declares annotation cannot even `embed`. | PROBED C.3, C.4, C.7 |
| Can an annotation's argument be a path? | Yes — it is a string literal like any other. The annotation cannot read it. | PROBED C.6, C.7 |
| What does `@std/openapi` do? | Emits an OpenAPI 3.1 `Json` FROM a route table at run time. No file read, no codegen, no client. | READ(agent) `std-openapi/src/openapi.av:26–76` |
| Can the evaluator call package C? | `avra run` can (dlopen). A compile-time run cannot: an unknown row "reaches whatever it likes". | READ `interp.av:535–541`, `:195–199`; PROBED C.3 |
| Is settlement parallel? | No. | READ(agent) `workspace_analysis.av:496`, `FIBERS_DESIGN.md:160` |

# Appendix B — the compiler DB as a consumer meets it

| step | today | general? |
|---|---|---|
| 1 declare a query | a `@family(rank, …)` marker type + a `DbRow` variant + a hand unwrapper + a `demand` call + a verifier arm + ~4 exhaustive arms. 32 families. | no — ~8 edit sites |
| 2 key it | `Key = { family: int, arg: int }`; anything else interned by hand through a side `Map<string,int>` | ints only |
| 3 depend on an outside input | two input families: `.av` text and `avra.toml`. Nothing for bytes, listings, env, tools, URLs. `@input fn file_text` / `env_value` exist over the *other* `Db` (`compiler/inputs.av:21`), with one caller and none. | **no** |
| 4 early cutoff | one int compare (`kernel.av:677`); fingerprints are hand-written closures, some constant | yes, with the "whole value" hazard open (`parsed`) |
| 5 persist | `.avra-cache/<compiler-print>/{sig,fp,unit,obj,bin,warn,rows}/<k2>/<key>` + `.deps`; text rows; bytes only as whole files | **no — bespoke** (17 write sites) |
| 6 invalidate | revisions within a process; across processes, held-file keys re-derived; `anew` on a refused hold | per file |
| 7 inspect | `AVRA_QTRACE`, `--time`, `avra cache why/dependents/changed/held`, `AVRA_DEP_AUDIT` | partly — `why` re-derives cold |

**The 17 bespoke write sites** (READ(agent)): `suite.av:128`; `kept_settle.av:150`; `interface.av:66,85`; `db.av:593`; `record.av:571`; `derive.av:200, 244, 509, 530, 749, 761`; `build.av:530, 696/783, 719, 725`; `voices.av:689`; `cli/commands/fmt.av:281,307`.

**How settlements and expansions are cached:** `Settled` in memory under an interned string; on disk as a kept verdict (unseated consts only) and as a const unit row in a held file's record ("A HELD CONST'S VALUE IS THE RECORD'S, NEVER RE-EVALUATED" — READ(agent) `workspace_analysis.av:588`). `Lifted` and `Expanded` are never written: every read file re-runs its derives in each cold process.

**A 4 MB image as a const today:** impossible as bytes (`embed` is text; a PNG traps "is not UTF-8 — byte 0", PROBED C.9). As text it is static data in the binary.

# Appendix C — probe log

Binary: `/Users/tristan/projects/tristanMatthias/avra-ui-assets-design/build/avra`, `LLVM_PREFIX=/opt/homebrew/opt/llvm`. Scratch: `/tmp/sources-probe/{pkg,tp}`. Each line: what ran → what it said.

| # | probe | output |
|---|---|---|
| C.1 | `const k = 3 \|> dbl` (`check`) | `error[parse.expected]: expected BREAK while parsing 'stmt'` at the `\|` |
| C.2 | `const H: string = embed("/etc/hosts")` (`run`) | `256` — a file outside the package, read |
| C.3 | `const T = read_text("src/data.json")`, read by the program | `error[const.reach]: a const cannot read the world … 'T' reaches 'avra_io_open' in '@std.io.read_bytes'` |
| C.3b | the same const, never read (`check`) | clean — settlement is lazy under `check` |
| C.4 | `const DOC = parse(embed("data.json"))` with `@std/json` | `const.reach … reaches 'avra_str_parses_float' in '@std.text.parse_float', called from '@std.json.scan_number'` |
| C.5 | `const DOC = parse_toml(embed("cfg.toml"))` | `avra: a 'File' write moved the whole relation after a compiler query (reader 936) read it this revision` — the compiler traps |
| C.5b | `const TEXT: string = embed("cfg.toml")` then `const DOC = parse_toml(TEXT)` | `2 name 2` — TOML settles at compile time |
| C.5c | `const B: Bytes = embed("data.json").bytes()` | the same `File` trap; through a named text const: `29 123` |
| C.6 | a two-package prototype: `@folder("icons") type Icons = {}`, the annotation answering `Declared` with `type ${t}Set = { ..${fields} }` and `const ${bound} = ${t}Set { ..${inits} }`; program reads `icons.close` | `icons/close.svg 24` in 0.14 s. `icons.clsoe` → `error[type.unknown_prop]: no field 'clsoe' on 'IconsSet' … help: the fields are 'close', 'menu'`. `avra expand` prints both with `// from @folder on icons — template …/provider.av:16` |
| C.7 | the same annotation calling `embed("names.txt")` | `error[annotation.unsettled]: … 'folder' embeds a file in '@std.meta.embed', but this compile-time call cannot return build inputs` |
| C.8 | `fn at(const s: Set, const name: string) -> Icon { const it = found(s, name); it }`; `at(icons, "menu")` / `at(icons, "clsoe")` | `m.svg` / `error[const.trap]: a const trapped while settling … 'it' index -1 is out of bounds (length 2)` — spoken at the library's line, not the call |
| C.8b | `impl Set<T> { fn member(const name: string) -> T }`; `s.member("b")` | `20` |
| C.8c | a generic `fn at<T>(const s: Set<T>, const name: string) -> T` with an inner `const`; and `at(at(outer, "in"), "x")` | `error[const.form] … 'it' declares 'T'`; `error[type.const_seat]: 's' is a 'const' seat … this is computed at run time` |
| C.9 | `embed("a.png")`; `embed("nope.txt")`; `embed("empty.txt")` | `avra: '…/a.png' is not UTF-8 — byte 0` (no location); `avra: '…/nope.txt' does not exist` (no location); `0` |
| C.10 | a 4,125,000-byte text file as `const T: string = embed(…)` | `check` 0.27 s, 66 MB peak; `run` 0.12 s |
| C.11 | `for i in 0..n { t = t + i % 7 }` under `avra run`, n = 0.5M, 1M, 2M, 20M | 1.19 s, 2.42 s, 4.89 s, 47.6 s. The same as a `const`: 48.1 s. Default budget: `error[const.budget]: … took more than 600000 steps` at n = 1M |
| C.12 | `parse_toml` over 17,400 bytes; `@std/json` `parse` + `to_text` over 18,991 bytes (`avra run`) | 0.74 s; 0.48 s |
| C.13 | `each(s) { dbl(it, by: 3) }` in a const; `each(s, dbl(it, by: 5))` | first runs; second `error[resolve.unresolved]: 'it' rides a METHOD call's arguments` |
| C.14 | `trait Pictures { fn each(f: fn(Image) -> Image) -> Self }`, impls for `Image` and `Images`, `fn resize<P: Pictures>(p: P, width: int) -> P` | `3 4` — runs. `impl Pictures for Set<Image>` → `error[type.impl]: … names a specific instantiation` |
| C.15 | a generic `each<A, B>(s: Set<A>, f: fn(A) -> B) -> Set<B>` called in a const with a named fn | `2,4` |
| C.16 | `@derive(Show)` written inside a Declares annotation's template, over a generated type | `error[type.method]: 'Pet' has no method 'show'` — the annotation was dropped, silently |
| C.17 | `type R = { type: int }`; `let café = 1`; `type R = { 2fa: int }` | `resolve.reserved: 'type' is a keyword`; `lex.error: unexpected character`; `parse.expected` |
| C.18 | `avra explain icons` | `avra: unknown command: explain` |
| C.19 | `grep -rn '\|>' packages --include='*.av'`, comment lines removed | no hits |
| C.20 | main's `build/avra` (09-30) over main's packages | `error[type.host_seat]: the answer of 'avra_bytes_with_room' wears 'Bytes', which cannot cross to C` — a stale binary; not used |
| C.21 | `const s = S { f: d }` where `f: fn(int) -> int` | `error[const.form]` — a value holding a fn does not settle (why a step is not a closure in a value) |
| C.22 | `fn webp(n: int, quality: int = 80, lossless: bool = false)`; `webp(1, lossless: true)` | `1 q80 true` — named arguments skip defaulted seats |

Not probed (no build allowed here): whether an edited embedded file invalidates the kept BINARY fast path (`kept_binary`, `build.av:475`). A survey agent could not find an embed's digest in `program_key`; `KeyParts.runs` covers it per file. Probe it in slice 2.
