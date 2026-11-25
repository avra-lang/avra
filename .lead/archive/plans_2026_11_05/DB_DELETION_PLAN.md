# DB deletion plan — 07e (the hold/attempts) and DB 08 (roots)

Base: `origin/main` @ `bbb4e4f9`. S1 (DB 03a + DB 06 registration) is on main as `c9db00e3`
(#768); the local checkout (`b0d98c49`) predates it, so **every line below is quoted from
`origin/main`**. Read: `docs/2026_10_06_COMPILER_DB.md` §8, §6.2, A2, A4, A16;
`.lead/DB_LANDING_PLAN.md`; `.lead/HANDOVER_2026-10-13.md` §4; and the files named.

**Never resurrect (A16).** `KeyParts`/`stands_in`; module record lines/`written_from`;
`program_key`; `kept_settle.av`'s `u c m f b e`; `proved_key`/`clean_key`/`canon_key`; the
`closure`/`embeds`/`homes`/`parts`/`seen` remembered rows; any new `*_stands` beside L3.
A new kept answer records `(name, digest)` reads, and nothing else.

## 1. DB 07e — what the machinery does today

**Attempt/turn loop — `compiler/derive.av` (1,269 lines).**
- `Attempt` (:43): entry, want, `parse` (files read whatever the store holds), `homes`,
  `hold`, `moved`, `turned`, `left`, `sealed`.
- `Turn` (:61) = `.Again(Attempt)` | `.Refused(string)`; `having_read` (:71), `unheld`
  (:77, the hold's oracle), `adrift` (:98, records moved twice). `Turn.Again` is spelled 6×.
- `again` (:580) / `tried_anew` (:585) / `turned` (:605): every attempt gets a fresh
  Workspace; a phase that finds its question wrong returns `Turn.Again` and the derivation
  restarts from sources. `tried_anew` discards its workspace unless the attempt stood.
- `under_hold` (:444): a held attempt that refused, its workspace having held a file, strips
  the hold and asks again from sources — **the D10 re-ask, retired at DB 07 with no switch**.
  `stood_first` (:426): a held derivation owing instantiations drops its workspace and
  re-asks with `homes`.
- Entry `derived_owing` (:412); `holding` (:638) is load/admit: seeds `hold.forced` from
  homes+parse, `load_interface`s every `held_modules` (record.av:640), then `settle_holds`.
- `settle_holds` (:1044): a worklist over `kept_runs` (what each held file's compile-time
  runs read), minting every held file and declaration *before* any query reads the relation
  (comments :1063–:1084).

**The hold's yes/no.** `stands_in` (derive.av:494): `Stored.Warn` + `asks_key` + `codes_key`
present, and `Stored.Obj` for a Binary want. `record.av`'s `read_why` (:962) consults it at
:975 to answer `Reads.Unkept`. 5 references.

**Hand key validity — `compiler/record.av` (1,951 lines; formats 1 and 2).**
`KeyParts` (:1269) = module · path · text digest · `runs` · `gathered` · `seen`. Built by
`key_parts` (:1276), memoized by `key_parts_cached` (:1307), digested by `key_of_parts`
(:1520), folded into `object_key_of_parts` (:1262) — the key of `Stored.Obj` **and of
`answers.av`'s `Answer` rows**. Row wire: `parts_key` (:1537), `parts_wire` (:1540),
`parts_of` (:1568), `seen_wire`/`seen_of` (:1554/:1560); the report `parts_moved` (:1625).
`written_from` (:1009) is format 2. 15 sites name these; `parts_wire` 5.

**Memo maps.** `Keys` (workspace.av:146), `Hold` (:228), `Records` (:358).
**Whole files the ledger deletes:** `verify_held.av` 486, `answers.av` 30, `db.av` 883.

## 2. DB 07e — deletion order

One commit per step, gated; "breaks if early" is the invariant that must already hold.

| # | delete | breaks if early | receipt it is gone |
|---|---|---|---|
| 1 | `settle_holds` (:1044) and `holding`'s hold block (:638–:660) | `load_interface` has no seeder; `hold.forced` reads stale. This *is* 07d's by-name loading replacing load/admit (S4c) | `grep settle_holds` = 0; `AVRA_QTRACE` shows no `Q attempt`; warm check unchanged |
| 2 | `stands_in` (:494) and `read_why`'s `Reads.Unkept` branch (record.av:975) | a kept object whose reads moved is adopted → stale binary/verdict; the kernel read-list digest is the only guard | `make cache-attacks` + `AVRA_DB_CHECK=1` corpus; `grep stands_in` = 0 |
| 3 | `Attempt`/`Turn` loop: `again` :580, `tried_anew` :585, `turned` :605, `under_hold` :444, `stood_first` :426, `having_read` :71, `unheld` :77, `adrift` :98, `Left`/`turn_said`/`left_line`, and their `Attempt` fields | with the hold still present a refused held derivation has no fallback; safe only after steps 1–2 (D10) | `grep 'Turn.Again'` = 0; `turn-memory-attack` under ceiling |
| 4 | `KeyParts` and formats 1+2: record.av :1262/:1269/:1276/:1307/:1520/:1537/:1540/:1568/:1625/:1009 | `object_key_of_parts` keys `Stored.Obj` and the `Answer` rows; without a name+reads replacement every kept object is orphaned | `grep -E 'KeyParts\|parts_wire\|parts_of'` = 0; store writes no `parts`/`seen` rows; `make cache-attacks` |
| 5 | `Keys`/`Hold`/`Records` fields whose families are queries (workspace.av) | the family still reads them | `make leaves`; `make families-left` only falls |
| 6 | `verify_held.av` and `answers.av` whole | nothing — last | no references; `make leaves` |

**Slices that must land first.** S1 (on main) → **S2** CancelReach split (`origin/cancel-bits`
`0ef03292`) → **S3** durable-symbol slice, then References split (`origin/refs-per-name`
`672e5a18`, the split itself `f6a2c3e3`) → **S4a** MethodDiags (`db-slice` `86df6e81`) →
**S4b** FileSaid + store body reverse index → **S4c = DB 07d** on-demand hold (`ec276593`) →
**S5** DB 07b (`Resolved`/`Folded` per declaration + `Placed`/names slice). S5 is required
for the ≤60 ms receipt, not for the deletion. Also owed: **DB 05b wiring** (`family_code_hash`
exists at workspace.av:2382, but the store's `FAMILY_STAMP` is still `""`, pack.av:66) and
**DB 05c** (store body reverse index).

## 3. DB 08 — design vs tree today

Design (§8, §6.2): three **roots** — the check verdict, the linked binary, the proved suite.
Each becomes a named query answer whose `(name, digest)` read list replaces the hand key;
tools and env become inputs; formats 4 and 7–9 and the `closure`/`embeds`/`homes` rows die.

| design | `origin/main` today |
|---|---|
| `Verdict` — the check verdict | `program_key` fold (build.av:535, format 4) + `checked` (derive.av) writing `Stored.Warn` / `DbRow.Warn`+`Licenses`+`Findings` under it; `clean_key` (derive.av:310, format 8) is the per-instantiation clean verdict |
| `Linked` — the linked binary | `kept_binary` (build.av:443) + `program_key` + `linked_reads`/`host_fns_key` (build.av:301/:293, format 5, DB 06) + `lower.av`'s `LinkedPackage` closure (:157) baked into `Lowered` (:159). Tools are witnessed (`told`); `CC` and link words are not inputs (avra-8sb5.68/.69) |
| `Proved` — the suite's evaluator agreement | `proved_key` (suite.av:275, format 7); `canon_key` (cli/commands/fmt.av:81, format 9); `lower.av`'s `Lowered`/`Unit` (:313)/`InstanceCode` (:735)/`KeptInstance` (:739) and `unlowered_stub` (:576). `kept_settle.av`'s unit lines (`u f c m b e`, :322–:331) are the per-unit proof, removed by **DB 09**, not DB 08 |

The input-door value layer is already on main (`host/input.av`'s `Read`/`Input`/`digested`;
`Store.keep_reading`/`get_valid` from DB 06 step 1), so a root can record reads today.

## 4. DB 08 — first landable slice: 08a `Verdict`

Branch `land/db08-verdict` off `origin/main`; three commits:
1. **Name it.** A `Verdict` answer in `leaves.av`, keyed by the program name + want,
   digest-only (the shape the digest-only families landed in S1).
2. **Ask it.** `checked` (derive.av) records the program's source reads as `(name, digest)`
   through the `Read`/`Input` door instead of folding them by hand; `Stored.Warn` stays the
   value row.
3. **Delete the diagnostics half of `program_key`**; `kept_binary` keeps the binary half
   until 08b `Linked`.

Files: `compiler/derive.av`, `compiler/build.av`, `compiler/leaves.av`, `compiler/store/`,
`compiler/tests/`. Receipt: `make leaves` (Verdict named, no unnamed reads, baseline only
falls) · `tools/digest_diff.py` two-process on an index-shifting edit (Verdict 1/1) ·
`make cache-attacks` · `make db-corpus` · `sh tools/db_measure/warm_edit.sh` unchanged
≤60 ms. A parallel isolated slice is **08a′ `canon_key`** (format 9): it lives in
`cli/commands/fmt.av` and needs only the DB 06 rule.

**Blocker for 08a:** the program's closure must be recorded as `Listing`/`Manifest`/`Text`
inputs rather than read from the unvalidated `closure`/`embeds` rows (build.av:471/:497) —
i.e. DB 04b/c; and DB 05b's `FAMILY_STAMP` wiring. 08b `Linked` additionally needs DB 04d
(tool/env inputs, `CC` a read). 08c `Proved` needs the DB 05c reverse index.

## 5. Blockers and ORDER

1. **S2 (CancelReach)** — blocker: rebase `0ef03292` over the #705 links bit; `families.ceiling`
   is 38 on main and may only fall.
2. **S3 (durable symbol, then References)** — blocker: `lifted_symbol`/`spelled_static` name
   generated symbols by file-absolute `e.index`; UNSOUND until declaration-relative or
   content-addressed. Receipt must show mismatched 0.
3. **S4a/S4b/S4c(07d)** — blocker: on-demand hold `ec276593` cannot pay until the whole-program
   families are split; FileSaid needs the DB 05c body reverse index.
4. **DB 05b wiring / DB 05c / DB 06 step 5 (producer stamp)** — blocker: `FAMILY_STAMP` empty;
   no branch carries the producer stamp.
5. **07e** — after S2–S4 + DB 05b/05c; deletion order in §2.
6. **DB 08** — after 07e (so the derive path is single) and DB 04 (closure/embeds/tools/env as
   inputs); first slice in §4.
