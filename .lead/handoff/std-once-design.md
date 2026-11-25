# STD ANSWERED ONCE PER COMPILER BINARY ON THE MACHINE: design (no code)

Measured on trunk e2bce925, 4 cores, -O1, cold `AVRA_PROGRAM=1 build packages/cli`: 126–131 s wall, 351–356 s user.

## 1. What exists, and what this extends

- **The machine CAS** (`compiler/store/cas.av`, `$AVRA_CACHE_DIR` or `~/.avra/cache/cas`).
  - It is a content-addressed blob store for the OLD path's `store/pack.av`: one big value is stored once under its digest, with an LRU trim to `AVRA_CAS_MAX_MB` (2 GB) and a gc that registers its readers.
  - The new path never touches it: none of my cold new-path runs created `~/.avra`.
  - There is no `~/.cache/avra` in either path; only std-process passes `XDG_CACHE_HOME` through.
- **The new path's store** (`std-program/disk_store.av`).
  - It lives per package at `<package>/.avra-cache/tapes`.
  - Packs are immutable files, and their names carry the compiler binary's print (`pack-<print>.<gen>.<hash>.pack`). A store reads only its own binary's packs and keeps the newest 2 binaries.
  - Any number of processes publish at once through an atomic rename, and compaction is logarithmic.
  - Each binary's frontier (noop-speed's reverse edges, sealed `avrafront3`) sits beside its packs.
- **The query engine** (`query_engine.av`).
  - A question is keyed by `(query name, code hash, arguments)`.
  - Each answer is saved with its RECORD: every question it read and the hash of that answer (`whole_reads` / `part_reads`).
  - A kept answer is reused only after its reads are re-checked down to the inputs, by red-green. Input stamps (`input_stamps.av`) let an unchanged file be confirmed without being read.
  - The store is reached only through the `AnswerStore` trait.
- **Addresses** (`address.av`) are `{package_name, path_in_package}`, never an absolute path. So an answer computed over `@std/avrac` files means the same in every project built by the same binary. Its record still names the exact input hashes, so a project that resolves `@std/avrac` to different text simply fails verification and recomputes.
- **Objects** (`item_program.av` `keyed_objects`, `bucket_asked`; `build.av` `PROGRAM_BUCKETS = 32`).
  - Bodies are bucketed by `home_bucket(file) = fp(file) % 31`, plus one program-wide bucket (code hashes, stand-ins).
  - A bucket's key is `salt + b + each body's lowering-question hash + symbol + kept tests + what it sees`.
  - So std and project files share buckets, and a bucket holds only the bodies THIS program reaches. No object is reusable across programs today.

**The extension is a second `DiskStore`, not a new cache.** The machine store is `disk_store_at($machine_cache/tapes)`: the same packs, per-binary naming, publishing, compaction and frontier, in the directory the CAS already owns (`machine_cache()`). A project build opens a LAYERED `AnswerStore` with the project store over the machine store. The old CAS stays for the old path and retires with it.

## 2. The unit of reuse: decided by each question's own record, not by a list

- **Which questions are package-pure is computed, not declared.** A question is MACHINE-PURE when every input its answer read lies in a package the machine store serves, and every question it read is machine-pure.
  - Machine packages are those the compiler resolves from its own std root (`@std/*` beside the binary).
  - Inputs are source text, listings and stamps, addressed by package.
  - The engine already holds each answer's reads, so purity is one bit per question, computed bottom-up as answers are made. Its seeds: an input's package, and "found in the machine layer".
- **Where answers are written:**
  - A pure answer and its record go to the MACHINE store.
  - Everything else goes to the PROJECT store.
  - Reads try the project store, then the machine store; either way the answer is reused only through the record check that guards every warm build today.
  - A misclassified answer costs only space, never correctness, because no answer is reused unverified.
- **What falls where with no hand list** (by the rule above):
  - **Pure:** std files' words, items, tapes, generators; std signatures, impls and typed/lowered bodies; std law findings (`item_misses`, `law_findings`, `item_methods_taken`, … over std items); std `unit_facts`; mono instances of std generics at std-only type arguments.
  - **Program-dependent:** anything that reads the project's files. That covers `lowered_under(std generic, [ProjectType])`, which reads the project type's declaration; the entry; `program_reached`, `program_refused` and its combine, placement / code hashes, `keyed_objects`, `bucket_asked`; and every project item.
- **Objects:** program-shaped today, so the design changes bucketing for machine packages.
  - A machine package's bodies go in PACKAGE buckets of their own, never mixed with project files. That means `home_bucket` takes the package into account, and a package's object holds every non-generic body the package declares that lowers without the program.
  - The key is `compiler print + opt + target + package + each body's lowering-question hash + symbol`, with no `kept` or `sees`.
  - `--gc-sections` (Mach-O `-dead_strip`) drops what a program doesn't reach, as it already does.
  - What stays in the program's buckets: bodies whose `kept` tests or `sees` (the program's gatherings) are program-shaped, generic instances at program types, wrappers, and the program-wide bucket.
  - Package objects are kept in the machine store's directory as files named by their key, like `tapes-build/obj` today.
  - Cost: the first program to touch a std package emits ALL its bodies, not only the reached ones. The cli reaches most of std-avrac, so this is close to free for the cli and a one-time cost per binary for others.
- **Program-level queries stay per program:** `program_reached`, `program_refused`'s combine, placement and code hashes walk the whole reach (43 729 units). Std's answers are reused under them, but their own bodies are about 12 s serial on this box today (see section 5). Making them compose per package (a package's reach summary and placement as a pure answer the program step joins) is stage 2.

## 3. Validation

- **A new witness, `tools/witness_machine_store.sh`** (beside `witness_program_edit.sh`, with the same law: warm == cold):
  - (a) Empty every store, including the machine store. Build the cli and keep product P0.
  - (b) Copy the cli to a fresh directory (`packages/cli` copy, empty project store), keep the machine store warm, and build P1. Require `cmp P0 P1`, and that the machine store answered (std questions found > 0, reported under `AVRA_QUERY_TIMES`).
  - (c) Add a second small program over std-io/std-text into the same machine store, and build it cold and over the warm machine store: the products must be identical.
  - (d) Change one std file in a copied std root (or under `AVRA_STD_ROOT` if one exists): the machine answers that read it must fail verification. The product must equal a fully cold build of that tree.
  - (e) Two builds over one machine store at once (two worktrees). Both products must equal cold, and the store must compact clean.
- **The edit witness:** it runs as today, once with an empty machine store and once with a warm one.
- **Refusals:** the refusal suite holds unchanged, because laws over std are pure and laws over the project are not.
- **Memory and ownership:** `sound check: 0`, RC_GUARD and `mem: live 0` hold as now; no runtime change.

## 4. Cost

| What | Measured / estimated |
|---|---|
| Answer packs of one cold cli build | 1.0 GB (2 packs) |
| Std's share of what the build reads back | 96.5 % (by items read back) |
| Machine answers per compiler binary | ≈ 0.95 GB |
| Bucket objects of one cold cli build | 57.5 MB (32 objects) |
| Package objects per binary at -O1 | ≈ 55–75 MB, more because every body is emitted |
| Per opt level | the same again at -O0, if dev builds use -O0 |
| Newest 2 binaries kept | ≈ 2.2 GB on disk |

- **Eviction:** by binary, keeping the newest 2 as the project store does. On top of that, a ceiling (`AVRA_MACHINE_STORE_MB`, default 4096) trims the oldest binary's packs first, then least-recently-read objects, like the CAS trim. Lanes that rebuild their compiler hourly cycle through binaries; the owner's installed compiler keeps one.
- **Concurrency of two builds:** the store already allows many publishers. Two builds that compute the same std answers both publish, and compaction keeps one copy (the "worst a race can do is repeat work" law).
- **Readers:** a reader maps packs read-only, and compaction never removes a pack another process has mapped because the mapping stays valid. Objects are written beside their name and renamed whole, as today.
- **Memory:** no new resident cost. Packs are mapped and paged, and the machine layer adds one mapping per pack (≤ log(n) packs per binary).

## 5. The number: a project's own share plus link, over a warm machine store

Built from the cold table (4 cores, -O1, wall s):

| Part | Today, cold | Warm std, stage 1 | Stage 2 |
|---|---|---|---|
| parse / generate / bodies + laws (CPU 141 CPU-s; project share 3.5 % ≈ 5 CPU-s) | 40 | ≈ 2 | ≈ 2 |
| parent start-up / merges / verify (*) | ≈ 15 | ≈ 7 | ≈ 2 |
| program-level serial: `program_reached` 2.7, `program_refused` body 4.5 + combine, placement + code hashes 4.6 | ≈ 15 | ≈ 12 | ≈ 2 |
| emit (177 CPU-s; project objects + program-wide bucket ≈ 3.5 % + ~2) | 48 | ≈ 2 | ≈ 2 |
| link (lld, 94 MB) + store save | ≈ 12 | ≈ 4 | ≈ 1 (emit-speed's dev link 0.04 s) |
| **TOTAL** | **≈ 130** | **≈ 27** | **≈ 9** |

(*) Measured proxy: after a cold build, touching all 42 cli source files (no item moved) rebuilt in 12.2 s wall / 11.4 s user. "The start-up" was 6.7 s, the frontier opened in 1.0 s and the store saved in 0.7 s, with no emit (bucket keys held). A fresh project store has no frontier of its own, so the machine store keeps one per binary over std's inputs, checked by stamp: that's noop-speed's mechanism, opened from the machine layer.

- **On this box (≈ 2× the Mac):** stage 1 ≈ 27 s here (≈ 13–14 s on the Mac); stage 2 ≈ 9 s here (≈ 5 s on the Mac).
- **Stage 1** is this design: the machine layer, purity by record, and package objects.
- **Stage 2** makes the program-level queries compose from per-package pure parts. It is required for 5 s; nothing short of it reaches the target.
- **Order of work:**
  1. The layered `AnswerStore` and the purity bit (std-program).
  2. The machine store's directory, frontier and eviction.
  3. The witness.
  4. Package buckets for objects (std-avrac `keyed_objects` / `bucket_asked`, shared with emit-speed).
  5. Stage 2.
