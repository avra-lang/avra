# WAKE REPORT — night run, 2026-10-16 01:25Z → 10:2xZ

You asked for **everything in flight fully landed by the time you woke**. Here is the honest account:
what landed, what is still in flight, and what is blocked. Live queue: `.lead/LANDING_RUN.md`.
Long-form log: `.lead/NIGHT_LOG.md`. Tasks: `.tasks/avra.db`.

## LANDED on main tonight
- **#813 — nodes step 2, BOTH halves** (main `8811834c`, 08:55Z). `semantics_of` + `body_semantics`
  deleted; 21 `dyn NodeSemantics` `Dispatch` fields + 21 boxed structs gone; `NodeSemantics` is
  `@delegates(Expr)` with `kids()`/`heirs()` reading `self`; 48 record impls. **30 files, +186/−415,
  net −229 lines.** std-avrac 9021/9021. Carried #808 (statement half), closed as carried.
  En route it found a real compiler bug: the receivers pass read `[self.x].concat(xs)` as a WRITE
  through `self` (3 spurious `type.contract_write` refusals) → now `inserted(xs, 0, self.x)`.

## In flight when you woke (owned by one `land-run` integrator)
- **#812 `db-09` — LANDED** (main `99dd79ae`). Had a 3-way conflict in the `reading_whole`
  retirement; rebased by hand (interface.av / leaves.av / workspace.av), one fmt red fixed, merged.
- **#814 `nodes-carriers` — ARMED**, in CI. NVariant carrier, `build_enum_de…` killed.
- **#804 `nodes-step5b`** — VERIFIED it CONTAINS #800; land #804 and close #800 as carried.
- **#815 `db-01b`** — new `@over(lister)` surface (head `146d5354`, draft). Queued after #804.
- **#816 `db-05c`** — store clean + time-travel; receipt-green but spelled `gc`; a rename lane is
  converting it to `clean` (owner directive) before it is landable.
- **#817 + #818 `nodes-field-default`** — the two-landing ladder: #817 is landing 1 (`Field` carries
  its default, read by nobody, gates on the standing seed); #818 is the SEED REFRESH that must land
  right after it. Landing 2 (the derive that reads it + the declarer cluster) waits for both.

## Blocked / deferred (all filed, none red on main)
- **`db-s4bc` (S4b+S4c, the DB by-name load)** — NO PUSH. std-avrac reds with
  `index 129 is out of bounds (length 124)` at `input_host_test.av` (byte-identical to main since
  `eb3e9f67`); the full suite also hits the 6000 MB cap at the same test. **The FileSaid observation
  rows** (`said_row`/`rules_row`/`findings_row` + 3 `keep_file_row`) are what fix `fn-add 43/2→43/0`
  AND what reaches the trap — so both path A and path B are red. `narrow_index/index.alone` and the
  key namespace are RULED OUT; it needs a QTRACE. Filed `avra-8sb5.57.176.4` + `.176.5`. Its
  cache-attacks are GREEN 43/0 and gate_changed clean, which are held.
- **`nodes-step3` (shape-reading kids/heirs)** — a DESIGN ROUND, not a night slice. Three walls:
  (1) the Children derive is on the gathered enum, so its output lands in `nodes.av` where member
  records are out of scope; (2) a trait default cannot call an inherent `self.shape_kids()`;
  (3) a per-record derive must share the trait's package, and moving `NodeSemantics` to core orphans
  the features impls for core records. Two candidate shapes (one `impl` with `rest -> shape_kids()`,
  which undoes #813 for kids/heirs; or a shape fallback in `@delegates`, which is new surface).
  Filed on `.89.3`; worktree reset to main, no PR.
- **`db-07a` (mint ownership)** — building on `db-slice`, lands after S4 (same files).
- **`nodes-field-default`** — two-landing seed ladder (mechanism → `make seed` → reader).
- **`nodes-facet`** — `@facet` mechanism → seed refresh → `once` conversion, as three landings.
- **`db-04e`** — input-door ledger.

## Findings and lessons worth keeping
- **The `?` narrows the mutation MODEL silently** (CHANNELS' keeper law, filed `avra-1mr9`): an
  innocuous `?` on a rule grows its base so no one-token deletion empties it — a ratchet can fall
  without anyone editing the ratchet.
- **A GitHub `update-branch` refresh does NOT regenerate the seed** on a seed-owning branch
  (`avra-lkoz` / `avra-90y3`): merge, then `cp build/avra build/avra.pre; make seed; make bootstrap;
  make seed-check`.
- **The std-avrac suite wants ~10.4 GB** and peaks ~6.4 GB in ONE process while per-testdir it peaks
  ~1.8 GB and releases — the blowup is ACCUMULATION (`avra-0z7y`, `avra-7edw`).
- **`Result<(), string>` is unspellable** (unit type in a Result side) and **`table` is reserved**,
  and the parse failure CASCADED into a trap in `features/enums/check.av alternative_law`, accusing an
  innocent (`avra-n87o`).
- **`@query(over: lister)` is unspellable** — annotation args are counted positionally (`query` takes
  0); the landed form is standalone **`@over(lister)`** (`.170.3`).
- **A `@over` listing does not cross a module boundary yet** — `side table bindings holds [0, 258) —
  id 261 is outside it`, `@over`-specific, likely `facts.av:180` sizing (`.170.2`).
- **`db-05c` red-team** fixed: wall-vs-monotonic age clock, age evicting the NEWEST, a warm-hold
  writer race, and 6 unlicensed store reads.
- **The seed→reader bridge is witnessed, not assumed**: a behaviour-neutral read of `f.default` in a
  tree derive makes the seed's build generate nothing (tree compiler over the same source is clean).

## Hazards you may want to fix
- **The main checkout's index has 505 staged files / 338k insertions** and local `main` is 42 behind.
  A lane left it dirty. Nothing writes from it now (`land-run` uses `/tmp/land-db09`), but it wants a
  deliberate `git reset` / re-checkout decision.
- **Machine build-lock contention**: at one point ~6 `watch.sh` jobs were queued on the shared lock,
  and one lane self-deadlocked it by invoking `watch.sh` from inside a run (never do that).
