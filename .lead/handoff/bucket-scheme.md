# One bucket scheme for dev fineness and the machine store's package objects

## Today (new path; item_program.av)
- **Units.** A program is units (`ReachedUnit { called: CalledFn, kept: TestsKept, sees }`) plus program-shaped parts: the entry and its lifted bodies, wrappers, code-hash bodies, stand-ins, hashed calls.
- **Home.** A unit's home is `home_bucket(file) = fp(file) % 31` (`ReachedProgram.homes`, saved inside the SHAPE QUERY's answer). Wrappers home by `fp(symbol) % 31`. Bucket 31 holds the program-wide parts (code hashes, stand-ins). The entry joins bucket 0 and its own home.
- **Unit key.** `unit_key_words` = `[1, lowering-hash(2 words), digest(symbol + kept + sees)(2 words)]`.
- **Bucket key.** `digest(salt = [build code hash, opt, linked digests], b, entry if b holds it, the held unit keys, the wrappers, program_wide if b = 31)`.

## The scheme: a bucket is (CLASS, OWNER, SLOT)
**CLASS** is `Package` or `Program`.

- **Package-shaped unit, CLASS = Package, OWNER = its package.** A unit whose module depends on its package's sources and nothing of the program:
  - its `kept` holds no test (a dependency's tests are never kept; the root package's kept tests make a unit Program);
  - it is no instance at a type from outside its package's dependency closure (`type_params == 0`, or every type argument resolves inside that closure);
  - every body it SEES is Package-shaped, or a runtime row / extern.

  Its `sees` is then a function of the package alone, so keeping it in the key is safe and equal across projects.
- **Program-shaped, CLASS = Program, OWNER = the program.** Everything else: the root package's units, instances at project types, the entry and its lifts, wrappers, code hashes, stand-ins, hashed calls.

**SLOT** = `fp(file) % fineness(CLASS)`. The fineness is a parameter:
- `0` means one slot per file;
- the code-hash bodies, stand-ins and hashed calls keep a slot of their own;
- wrappers slot by `fp(symbol)`.

**Keys.**
- A Package bucket: `digest(compiler print, opt, target, package name@version, slot, sorted [(symbol, lowering hash, sees)] of its units)`. No program salt, no `kept` (it holds none).
- A Program bucket: today's key — salt, entry, held unit keys, wrappers, program-wide parts.
- Both are pure functions of answers the build already asks.

**Where the parts live.**
- Homes are computed at KEY time (`keyed_objects` / `bucket_asked`), not in the shape query. The scheme rides `program_binary`'s question with opt and the layering, so the shape answer and the default product are untouched.
- The fineness comes from the build mode:

| mode | scheme | Package objects |
|---|---|---|
| unset | the legacy 32 homes — byte-identical, as ruled | — |
| dev | Package fineness 0 (per file), Program fineness 0 (per file) or 128 (measured: a literal edit's emit ~10 ms at 128 buckets) | kept in the program's obj dir |
| machine store (held-items step 4) | the same CLASS/OWNER/SLOT split | kept in the machine store under the Package key, so a cold project links std's objects without emitting them |

**Linking.** Objects are linked by key exactly as now. The layered dev link puts Package objects in the world first; they never move on a project edit.

## One defect fixed with it, at any grain
Each `BucketAsked` builds its own copy of the program-wide parts: the entry body, the extern rows, the declared list. At 512 buckets the cold cli build passed the runtime's 9.7 GB memory pool. Those parts are made once per build and shared by every bucket.

## Open for held-items
- The package's identity in the key: name@version from its manifest, or the content print of its sources (the lowering hash already covers the bodies).
- Whether a std instance at a std-only type that the program reaches (e.g. `List<int>` in std code) counts as Package: by the rule above, yes, when every type argument is in std's closure.
