# Cache handoff II — the edit is 1.4 s, the wall is now real work

Read this whole file first. It is the context the previous session paid for, plus
what the last session measured. The prior handoff is
`docs/2026_09_18_CACHE_HANDOFF.md`; the design is
`docs/2026_09_16_BUILD_CACHE.md`; the audit trail is
`docs/2026_09_18_CACHE_INTERFACE_AUDIT.md`. This one supersedes the numbers in
all three.

## 0. Mission

`build packages/cli` builds **the compiler itself** — 276 files (cli +
std-avrac + the toolchain std packages), producing `build/avra`. Targets:
**cold < 60 s**, **edit < 1 s**.

| | start of campaign | handoff I | **now** |
|---|---|---|---|
| no-op (user CPU) | 0.37 s | 0.29 s | **0.10 s** |
| warm edit (user CPU) | 6.7 s | 4.9 s | **~1.4 s** |
| cold (user CPU) | — | 30.7 s | **~28.9 s** |

Warm edit is ~4.8× better. **Sub-second was NOT reached**, and the honest reason
is that the remaining time is no longer in the cache layer — see §5.

## 1. Where you are

- Worktree `avra-cache-cas`, branch **`cache/cas`**, HEAD **`00e0370`** (the
  refreshed seed). Worktree path `/Users/tristan/projects/tristanMatthias/avra-cache-cas`.
- Cache is `.avra-cache/` at the worktree root (gitignored). **It can be poisoned**
  — see §8, it is the #1 time sink.
- **Run everything through `./avra`.** The shim cds to the tree root, exports
  `AVRA_CWD`/`LLVM_PREFIX`, takes the machine-wide lock for any directory
  argument, and wraps in `tools/watch.sh`. A single-file `./avra check f.av` is
  light. `make gate` is the bar; the branch's idiom baseline predates main's
  cleanup (57 pre-existing violations), so use the targeted checks in §3.
- **ONE heavy process at a time.** The box watchdog-panicked twice; there is a
  machine-wide lock, honour it.
- `build/avra.good-<hash>` is a saved known-good binary. Keep one before any
  risky change: `cp build/avra build/avra.good-$(git rev-parse --short HEAD)`.

## 2. Architecture (updated)

- `packages/std-avrac/src/language/store.av` — content-addressed store. Families
  `Sig Fp Unit Obj Mod Bin Warn`; rows at `<root>/<family>/<shard>/<key>` + `.deps`.
  `CACHE_FORMAT` here (bump invalidates all).
- `interface.av` — the waist. One text record per module (imports, an `iface`
  digest, declaration lines). `keep_interfaces` writes; `load_interface` /
  `mint_held_interfaces` / `fill_interfaces` rebuild without parsing.
  **Per-build caches now live here** (`record_cached`, `forget_keys`,
  `bytes_key_cached`, `obj_key_cached`, all `// LICENSED I39` free fns — see §8).
- `settlement_wire.av` — a settled const and a unit's edges wire.
- `build_cache.av` — the driver. Binary cache first; else `held_modules` →
  `load_interface` → `admit_all` → `mint_held_interfaces` → `fill_interfaces` →
  `program` → `lowered_checked` → per-file `emit_bitcode` → one clang → link.
  `--time` prints the phase split (WALL clock — see §3).
- `workspace.av` — the query kernel + lowering. `lowered` returns edges+stub for
  a held unit; `held_deps`/`unit_stub`/`attach_store`/`remember_deps` here.
  `block_grammars`/`line_grammars`/`module_names_syntax` are the sublanguage path.
- `core/digest.av` — **now a multiply-xor-rotate fold** (xor, rotate, multiply,
  splitmix finalizer; no division). Lanes masked to 63 bits because a key with a
  leading `-` is read by clang as an option (§8).
- `backend/llvm_wrapper.c` + `language/llvm.av` — `emit_bitcode` writes `.bc` for
  the build path; `emit_ll`/`emit_module` still write `.ll` for `avra emit`/`split`.

## 3. Measure and verify

**Measure user CPU, never wall.** `/usr/bin/time -p ./avra build packages/cli`.
The `--time` phases use `avra_now_ns` = `CLOCK_MONOTONIC` (wall), so they inflate
under load and do NOT sum to user CPU. For a true per-phase CPU split, temporarily
change `avra_now_ns` to `CLOCK_PROCESS_CPUTIME_ID` in `runtime/avra_runtime.c`,
`make build/avra_runtime.o && make avra`, measure, then revert and rebuild.
(`clang`/`link` are CHILD processes and show 0 in that clock.)

**Verify — all four, every change:**
1. **Differential**: a held-build compiler's `check packages/std-avrac` must be
   IDENTICAL to a whole-program (hold-off) build's. To build the wp compiler:
   set `CACHE_HOLD_ENABLED = false` in `build_cache.av`, `./avra build packages/cli`,
   save the binary, restore the source.
   Run both under the lock and diff ignoring the `watch:` line.
2. **Probe**: `./avra build build/scratch/probe` → the binary prints `42`. Run it
   on a FRESH and a CACHED build (the exec-bit bug was only visible on a hit).
3. **Self-build**: the held-built compiler builds `packages/cli` cleanly.
4. **Self-hosting**: `make avra` twice is a fixed point (the second is a hit).
- Idiom bar: `python3 tools/idioms.py` (expect 57 pre-existing; add NOTHING new —
  license at the site with `// LICENSED I<n>: reason` within 2 lines of the fn).
- Seed: after any change, `make seed` (on a clean tree), commit `bootstrap/seed.ll`
  + `bootstrap/seed.sources` TOGETHER, then `make seed-check` must say
  `the seed compiles HEAD`. The guard refuses a dirty tree and a mismatched seed.

## 4. What the last session did (all verified, all committed)

| commit | what / why | measured |
|---|---|---|
| `9b2f4eb` | a record is read once/build; a derived key computed once (memo in `Workspace`) | 6.7→5.1 s; `place` 500→2 ms, `load` 1000→300 |
| `40d3e94` | `mut`-seat write-through in `spec_id`/`drained`: a read-then-write cloned the map per unit (O(n²)) | 5.1→3.8 s; `lower` 1700→250 ms |
| `b1cbfa9` | a binary-cache HIT placed the binary without `+x` (second build unrunnable); chmod on the hit | probe runs twice |
| `abc3579` | `line_grammars` reads the provider's record before parsing the provider; the compiler declares no `syntax`, so ~100 provider parses were pure waste | 3.7→1.7 s; `admit` 2037→70 ms |
| `b5ce0db` | `digest_text` batched 7 bytes per fold (was 8 modulos/byte) | no-op 0.29→0.10; edit 1.72→1.35; cold 30.7→28.8 |
| `99c64ce` | `digest` → xor-rotate-multiply, splitmix avalanche (no division) | **neutral** (see §7); kept as the right primitive |
| `4dd9417` | build path emits BITCODE not `.ll` text | **neutral CPU**; cache 57→44 MB |
| `5a5e5b0` | `mint_identity`/`remember_held_item` append in place (were O(n²)) | **neutral**; asymptotic hygiene |
| `00e0370` | refreshed seed | `seed-check` green |

## 5. Where the time is now (measured, do NOT re-derive)

Warm edit ~1.4 s user:
- **reconstruction ~620 ms**: `load` 200 + `mint` 310 + `fill` 110.
- `lower` ~220, `analyze` ~130, `admit` ~70.
- **clang ~90 + link ~100** (child processes; ~190).
- `inputs()` hash ~60 (walk 18 + hash 60).
- no-op 0.10 s total.

Cold ~28.9 s user: `clang` 10.4 s, `emit` 7.5 s, `admit`(parse) 7.5 s,
`lower` 3.0 s, `analyze` 2.8 s, `link` 0.2 s.

**Facts that closed doors (do not reopen without a new measurement):**
- The hash fold is NOT the bottleneck: `read_text` (UTF-8 validate + allocate)
  is ~60 ms of the ~60 ms hash. Floor is memory bandwidth (~3 ms). A byte door
  on `Host` is the remaining ~50 ms, if anyone cares.
- The reconstruction is per-declaration WORK, not a quadratic: the in-place mint
  fix measured neutral. Deferring `fill` ceilings at ~110 ms (see `d6d60d3`).
- Cold emit/clang are IR CONSTRUCTION and clang OPTIMIZATION, not serialization:
  bitcode is neutral.
- The format identity: sub-second needs `load`+`mint` gone, and they are needed
  for name resolution. The real slice is a **persisted declaration/type
  environment** that loads without re-interning (the design's `sig` node,
  compact or resident) — NOT a lazy patch.

## 6. The next slices, in order

1. **Reduce the reconstruction** (`4a542a7`, §5). Biggest warm bloc (620 ms).
   Prototype a compact per-module declaration bundle (bulk arrays, no per-line
   text split, no per-declaration map/list writes). MEASURE the three passes
   first; if the cost is type interning rather than table writes, this will not
   help and the answer is a resident/namespace load instead.
2. **Rung 3 — the unit IR** (`7bb8a5e` has the full spec). Buys ARCHITECTURE, not
   clock (measured). **The hazard that gates it**: `build_cache`'s `active` remap
   moves every non-empty body whose home is held into the entry weak; loading a
   held unit's real IR would re-emit the whole held program. Land it WITH an
   emission rule that skips a body a held object already defines.
3. **Cold** is a different campaign (frontend/backend): parse 7.5 s, emit 7.5 s
   (LLVM API construction), clang 10.4 s. Nothing cheap was found.

## 7. Lessons learned (this session)

- **MEASURE, THEN CHANGE — and accept NEUTRAL.** Three changes measured neutral
  after the enabling one (the digest algorithm, bitcode, the mint in-place fix).
  The BATCHING (7 bytes/fold) was the real digest win; the algorithm swap that
  followed had nothing left to cut. Do not assume the "better algorithm" wins —
  instrument the actual cost first. `eprintln` timers, then revert them.
- **A point optimization can be dominated by the next layer down.** The digest
  arithmetic was ~190 ms; the per-file text read was ~60 ms and became the whole
  remaining cost. Always ask what the floor of the WHOLE step is, not the part
  you are touching.
- **The compiler is the product and the tool.** Every source change is compiled
  by the standing binary; a broad interface change (many files' declarations)
  can defeat the held path's stabilization (`attempt >= 2`) and poison the cache.
  See §8 for the recovery.
- **Wall-clock phases lie under load.** Use user CPU; the CPU-clock trick in §3.
- **A source interface change is a two-generation thing.** After a broad change,
  clear the cache and do ONE cold build to reach a consistent key space, then fix
  point. The negative-key incident (§8) is the extreme case.

## 8. Gotchas (the #1 time sink first)

- **CACHE POISONING / "interface records did not stabilize".** When a build fails
  with that (or with `F2030: .fingerprint(...) calls a method, and int has none`
  on the NEXT run), the cache holds records from a half-finished attempt and the
  held path reconstructs a wrong flat/boxed decision. **Recovery:** `rm -rf
  .avra-cache` and build cold ONCE with a known-good binary; or,
  if the standing binary itself was broken, `make bootstrap` (recover) — the seed
  is the way back. The saved `build/avra.good-*` is the fast way back.
- **A key that can start with `-` breaks clang.** The digest's signed lanes made
  a `.ll`/`.bc` filename start with `-`, which clang read as an option; the
  installed compiler could no longer build its own fix. `digest_key` masks each
  lane to 63 bits. Any new key surface must be non-negative.
- **Adding a method to `impl Workspace` trips a compiler defect.** One method
  makes `Analysis.program`'s `fn() -> Program` resolve to a neighbouring free fn
  (`F2010: field 'program' is 'fn() -> is_source'`). Types/fields/free fns alone
  are fine. That is why the per-build cache helpers are free fns with
  `// LICENSED I39`. NOT YET DIAGNOSED.
- **THE REPRESENTATION INVARIANT IS ABSOLUTE.** `fill_shape` decides a value's
  machine shape (`mark_flat`/`mark_named`/`declare`). Deferring, reordering, or
  changing the SET of reconstructed held declarations re-opens the campaign's
  original silent miscompile (`F2030: .fingerprint() on int`). Any change to the
  held reconstruction must keep every representation fact EAGER and
  order-independent, and must run the differential.
- **The idiom bar is line-sensitive.** `// LICENSED I<n>: reason` must be within
  2 lines ABOVE the flagged `fn` (a 3-line comment puts the word out of range).
- **The `--time` label `admit` is `admit_all`**, which on a held edit parses only
  the fresh files but used to spend ~2 s in `block_grammars` (fixed). `fill` is
  `mint_held_interfaces` + `fill_interfaces`.
- **`let x: List<T> = []` does not parse; `mut` before a `let` fails; a match arm
  sharing the brace's line needs a trailing comma; a present-bind arm must not
  follow a comma-ended arm; no `;`/`continue`/`break`/`|>`.** `0 - N` for a
  negative literal.

## 9. Tips

- Save a known-good binary before every risky change, and NAME it in every
  receipt (`build/avra.good-<hash>`).
- Park scratch in `build/scratch/` or `/tmp`, NEVER `packages/` (the keepers read
  the tree, and an untracked file turns `seed-check`/gate red against a clean commit).
- A benchmark that edits the source and restores it must **back up and restore by
  copy, never `git checkout`** (which drops the working-tree change under test).
  `build/scratch/ebench.sh` is a working model (it appends a fresh comment line
  per run so each is a real miss).
- The full gate (`make gate`) is red on this branch because it predates main's
  idiom cleanup. Use the targeted checks in §3 until the branch is rebased/merged.
- When a change measures NEUTRAL, say so in the commit and keep it only if it has
  another property (smaller artifact, better asymptotics) — do not dress it up.
- Never leave the tree unable to build itself. If a change half-lands, `git
  checkout` it and record the finding; the seed + `make bootstrap` is the way back.
