# db-01b lane — the producer listing

Worktree: `/Users/tristan/projects/tristanMatthias/avra-db-01b`, branch `db-01b` off `origin/main` @ `9cdec783`.
No free Sprite (`work new db-01b` → "every Sprite is bound to a lane"). Heavy runs on the machine-wide
watchdog (`tools/watch.sh`), serialised by the build lock.

## Log

- [t0] worktree created; reading the design §5.1/§6.2/§7.2 + A11, the audit, and the parked
  `origin/own-db-law` branch as prior art. Task: a query whose rows are listed by the producer
  that owns them (prerequisite for 07a / `avra-8sb5.57.176.6`).

## [t1] relation receipt GREEN; probe confirms the spelling tension
- `sh tools/_d1b_receipt.sh relation` → 27 programs + 1 program proved, `eval == native == expected`, peak 293 MB, status 0. Log: /tmp/db01b-relation.log
- PROBE (`/tmp/db01b-probe/probe.av`, moved out of the tree): `@query(over: icon_dirs)` on today's
  `query(f: Fn)` → `error[annotation.seats]`: "`query` takes 0 after the declaration, this writes 1".
  The annotation law counts args exactly (`seats.length - 1 != a.args.length`) and does not bind by
  name — so the design doc's spelling `@query(over: lister)` is BLOCKED; the landed surface is the
  standalone `@over(lister)` (`over(f: Fn, lister: Fn)`), which fills its one seat and needs no law change.

## [t2] red-team pass — 2 survivors, both fixed or filed
Attacked the `@over` surface mechanically (malformed shape, every slot, wrong names,
cross-feature, both engines, ownership, refusal quality) with 7 probe programs under
`packages/std-relation/src/tests/attack_probe/` (moved out to `/tmp/db01b-probe/attacks`).
- SURVIVED #1 (FIXED, in-scope): a producer answering `List<R>?` passed the law's
  `starts_with("List<")` test, then the generated comprehension died with
  `error[type.list]` pointing at `query.av:134` — the compiler's own file, not the user's.
  Fix: ask the KIND (`is_list(f.answers)`) instead of the spelling; voice now says
  "answers a plain `List<R>`". Tests: `over_adversarial_test.av` nullable row.
- SURVIVED #2 (FILED, out of scope): `@over(Icon)` (a type name in the `Fn` lister seat)
  speaks `annotation.unsettled: `over` defect: a read from a non-array in a clean program`
  — an internal-defect channel shown to a user. ROOT CAUSE is generic: `check.av`'s
  `type_arguments` types a named declaration AS the seat and `arguments_fit` then asks
  `accepts`, which the forced type makes pass — `seat_takes` (crossing.av:806) is never
  asked of an argument. `@derive(Icon)` reaches the same hole. Fix is ~6 lines in
  `arguments_fit` (ask `seat_takes` when the arg names a declaration) + one test, but it
  is a SHARED law change needing a compiler rebuild (two generations) — and this machine
  is at 100% disk (824 MB free, dropping) with near-full swap, so `make avra`/`make try`
  both refuse under the watchdog's floor. Deferred, not smuggled into a feature PR.
- a5 (a plain fn lister, no `@query`) is ACCEPTED by design (the lister's contract is its
  SHAPE; §3.2 shows an `@input` lister) — a test NAME overstated it, renamed to
  "a lister that takes more than the Db is refused".
- THE SPELLING: the doc (§6.2/A11, line 1069) writes `@query(over: icon_dirs)`; that is
  BLOCKED (probe: `annotation.seats`). Landed surface is the standalone `@over(lister)`.

## [t3] the listing is reachable ONLY inside its own module — a `bindings` trap
Driven by the "new consumer is the instrument" law: probe = `tests/over_export/mod.av` (an
`@over` producer + written wrapper) consumed by `tests/over_written_probe.av`.
- `use tests.over_export.{rows}` (a WRITTEN export) → clean (rc=0).
- `use tests.over_export.{rows_listed}` (the GENERATED listing) → TRAP:
  `avra: side table `bindings` holds [0, 258) — id 261 is outside it`.
- a written wrapper `export fn list_all(db) -> List<Row> { rows_listed(db) }` — imported → SAME TRAP.
- `use tests.over_export.{no_such_name}` → same trap. But `tests/zz_mod.{no_such_name}` and
  `tests.twins_a.{no_such_name}` (twins_a has `@relation`) -> CLEAN `resolve.not_exported`.
  So it is `@over`-SPECIFIC, not generic to generating annotations.
- Likely root cause: `features/facts.av:180` sizes `bindings` from `exprs` at NameFacts creation;
  the generated comprehension's expressions land past it and a failed export lookup reads one.
  NOT reached by this PR's tests (a clean `check packages/std-relation` is rc=0), but it blocks
  the listing crossing a module boundary — which DB 07a needs.
- ACTION: report; the PR keeps the listing in-module. `make try`/`make avra` both refused under the
  disk floor, so the trap cannot be driven further locally.

## [t4] PUSHED — DRAFT PR #815 (head cf94302a), unarmed
- `https://github.com/avra-lang/avra/pull/815` — isDraft true, autoMergeRequest null, base main.
- GREEN locally: `avra test packages/std-relation` (27 programs + 1 proved, eval==native==expected,
  peak 1812 MB, rc=0) · `make leaves` ("no blocked share rose") · `make keepers-static` rc=0 ·
  `check <each changed file> --baseline tools/idioms.baseline` rc=0 · `fmt --check` canonical.
- CI's (no Sprite free; disk at the watchdog floor, `make avra`/`make try` both refused):
  `avra test packages/std-avrac` (queued behind the machine lock) and `make cache-attacks` (builds
  the C objects), plus `gate_changed`.
- Commit: `cf94302a` "DB 01b: the producer listing — `@over(lister)` generates `<name>_listed`".

## [t5] review-round beat — head 146d5354
- `query.av`'s module header now names `@over` (the file carries two public annotations);
  `check packages/std-relation` rc=0, `fmt --check` canonical. Pushed to #815.
- Red-team survivors, final: (1) `List<R>?` slipped the law and died naming `query.av` — FIXED
  (`is_list`), pinned in `over_adversarial_test.av`; (2) a test name overstated its scope —
  RENAMED; (3) the module-boundary `bindings` trap — REPORTED (PR body + this file), out of scope.
- Nothing armed; nothing merged. Awaiting CI on #815 for `avra test packages/std-avrac` and
  `make cache-attacks` (the machine lock was held by a peer lane for the whole session).
