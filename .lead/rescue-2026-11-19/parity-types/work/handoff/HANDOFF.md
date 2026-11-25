# HANDOFF: avra-lane-parity-types

## Lane

- Name: `avra-lane-parity-types`. The branch, the file stem and the bundle name are exactly that. The repo is `/work/avra`.
- Scope: the type-agreement family. The old path (`AVRA_PROGRAM=0`) refuses these programs, and the program layer (`AVRA_PROGRAM_NET=0`) was silent or said other words.
- The type.mismatch family is DONE: 127 of the lead's 143 closed; the rest are ruled, routed to other lanes, or behind parse errors.
- The lane then took language work routed by the lead from the services session (std-queue): partial type arguments, type-parameter defaults, `never`, seat pinning, generic methods.
- Brief: `/work/lead/.lead/LANE_BRIEF.md` and `/work/avra/CLAUDE.md`.

## Base

- Newest batch held: `batch54` = `99def0d2`, fetched as `refs/remotes/b54/batch54` from `/work/batch54.bundle`. Its prerequisite is `d750dfa7`.
- The branch head is `a356f6af` ("Merge batch54 into avra-lane-parity-types"). The tree is clean; `uncommitted.patch` is empty.

## Commits ahead of batch54

| sha | what |
|---|---|
| `0b820238` | Prefix type arguments for fn calls, record literals and component instances; the count law becomes "at most N". |
| | Declared type-parameter defaults `<T, E = never>`, on fns and components only. |
| | `never` written in types; it lays out as void, so `X<never>?` holds only null. |
| | A generic call pinned by a NULLABLE seat, in typing and lowering through one shared `answer_pinned` + `defaulted` in `core/checking.av`. |
| | A literal leaving a parameter unpinned → `type.struct_targs`, with a golden help naming the field. |
| | `NewOnly.TypeDefault`, `Never` and `PrefixArgs`. |
| | Tests: `features/fns/tests/partial_targs_test.av` (11/11), proof `features/components/tests/partial_targs` (eval == native == expected), witnesses `builds_prefix_type_args` and `seat_pin_nullable` (known to differ, by ruling). |
| `3aab618f` | `core/tests/param_syntax_test.av`: the golden field listing gains `tdefault`. |
| `a356f6af` | Merge batch54. `item_new_only.av` NewOnly: union. `item_refused.av` seat lists: batch54's lines plus `LiteralUnpinned` appended. |

Receipts at `a356f6af`: make try 0; layer `check packages/std-avrac` EXIT 0; cli NET=0 exit 0, 0 refusals; gate avrac-a..g ALL PASS; witness 985/1021 hold, 36 known, 0 failing.

The idioms run was stopped by the handoff, so it is unconfirmed at this head. Last known: 0 findings. The old-path run exits 1 only on batch49's 16 `ctx.old_path` plus 2 `type.struct_targs` on my `partial_targs` proof. Those are prefix literals the old path refuses by design; the UI lane is making the old path skip NewOnly files.

The lead has NOT yet received a bundle containing `a356f6af`; the last one posted was `3aab618f`. `0b820238` and `3aab618f` are not in batch54.

## In flight

Nothing is half-applied. One thing is written but not applied:

**Named arguments beside a field read** (services ask). `q.send(self.item, id: x)` doesn't BUILD on the layer when the field is a record (e.g. `self.item: Job`) or the call is inside a component.
- The message is "a method that may write its receiver: `self` handed to `send`, whose seats aren't read".
- Cause: `compiler/item_writes.av` `fed()` gives up on any labelled argument; it has the seats' write marks only by position.
- Fix, written as a script, NOT applied: `scripts/named_args.py`. It edits `item_writes.av`:
  - `fed` gets a `names` parameter and places labelled arguments with `store.seat_plan`.
  - Callers that know seat names pass them.
  - Two new helpers, `called_names` and `seat_names`.
- Repro probes: `probes/nb3.av`, `probes/nb5.av` (fail to build). Positional control: `probes/nb6.av`.
- Apply with `python3 scripts/named_args.py`, then `make try`, then run nb3/nb5 on the layer. Add a witness (`builds_named_arg_field_receiver`) with prints.expected.

## Next 3 items, in order

1. **Named-arg fix above.** Apply, build, witness, receipts.
2. **Record/enum/alias type-parameter defaults** (owner-approved; the lead said don't leave it long). Their type params are `List<Plain>` built from `tparams:NAME` (structs/mod.av lines 50, 51, 55; enums/mod.av 54).
   - Plan: add a `tdecl = name:NAME ( "=" tdefault:type )? -> Record.ParamSyntax` rule with NO bound, so bounds on a type's own parameters (a separate roadmap item) don't sneak in.
   - Make StructDecl/EnumDecl/NamedType/Alias `tparams: List<Param>`.
   - Fix their readers: `core/parts.av` 210, 472, 480, 487, 509, `name_over`; `compiler/format/source_text.av` 581–620, where the formatter must print `= default`; `features/formats/builders.av:90` (passes `[]`).
   - Have `decl_tbounds` return them, so `signing.defaults_written` reaches records via `record_signature` → `RecordShape.defaults`, which the literal door already reads.
   - Also update the NewOnly TypeDefault detector, which already scans `decl_tbounds`.
3. **Generic methods** (lead said GO, as designed; the design post is in the bridge transcript):
   - Signature: impl's params, then the method's own.
   - Typing: one door with free calls (`Checking.called`); the receiver pins the impl's params, then a written prefix, then the arguments, then the seat, then the default.
   - Instances: mono via lowering's `instantiated_as`, with `found` seeded from the receiver's args (as `instantiated_on` does); `laid_unit` is keyed by the full arg list.
   - Dispatch: static; through a bound, OK; through `dyn`, refused: "a generic method can't be called through `dyn` — call it on the type, or bound a type parameter".
   - `NewOnly.GenericMethod`.
   - In the SAME change: remove the CLAUDE.md "The subset today" text "a generic method is 'generic methods are recorded, not landed'" (line ~1722) AND its case `compiler/tests/subset/refusals_test.av` "a generic method is refused" (~line 413).
   - The refusal lives in old `compiler/typing/impls.av:443/601/718` and layer `compiler/item_generic_methods.av`.
   - Case set (complete per lead): own-param inferred; pinned as a prefix; defaulted; bounded and refused; on a generic impl (<T> + <U>); through a bound; through `dyn` refused; eval == native.

Then: **a foreign generic record literal as a generic fn's TAIL** (services ask, program layer only). "a body not made yet: an untyped record literal `Dead`", while a typed `let` passes. It's an inference gap at a tail seat. Find one case; fix through the one door (likely the body's answer as the literal's `expected` in `fills`, now that the literal door passes `expected`).

## Rulings in force (from the lead)

- **Sibling pinning:** a sibling arm's type is a seat for an arm that names none, in `if`/`match`/`when`/`??`, for generic calls AND bare variants. Witnesses `sibling_pin_*`, `w_variant_lit_branch` (known to differ). ROADMAP note "A sibling arm's type is a seat for the arm that names none".
- **Precedence**, one door, a later step never overriding an earlier one: written prefix → arguments → wanting seat (a nullable seat by its present type) → declared default → refused.
- `pw_rest_spread_element`: the layer's element words are kept (don't "fix" `f(1, ..["s"])` to whole-argument words).
- `xs?[0] ?? 0` warning on both paths is correct (propagate-then-index).
- The 40 warning follow-ons in package-245/split-368 close with their errors; leave them.
- `E.all(1)`, find_map and Pair.made words → parity-words lane. `{}`.length and `[].map` etc. → resolve-2. Don't take them.

## Open asks waiting on others

None blocking. The lead tells the services session when features land.

## Trip hazards

- **Environment:** `. /etc/profile.d/avra.sh` before builds. `make try` builds `build/avra-try` (4–11 min).
- **ONE heavy job at a time:** builds, gate, `check packages/std-avrac` and the cli build. Two at once OOM'd and restarted the container (twice). Never edit `/work/avra` sources while a gate runs: the suite reads them, and that tainted one run.
- **Receipts:** `scripts/rc.sh` runs, in order: make try, layer check std-avrac, probes, cli NET=0, gate a–g, witness, idioms. Summary in `/tmp/rc-sum.log`; it takes ~70–90 min. Delete `/tmp/rc-*.log` before a run, or a wait loop returns on a stale log.
- **Idioms** needs `AVRA_MEM_POOL_MB=13000`; the default pool ran out (exit 2).
- **Witness:** `sh tools/witness_program_refusal.sh build/avra-try <cases>`; `PIN=1` writes expectations from the old path.
  - `differs.why` beside a case = known to differ; once it holds, it FAILS until the file is removed.
  - A warning difference needs `warns.expected` (refusals are compared "warnings aside").
  - A form only the layer builds is held on the layer alone (NewOnly).
- **Spec strings:** `${…}` inside a spec's source string must be written `\${…}`, or the spec file interpolates it.
- **Probes and measures:**
  - `scripts/cmp.sh <file.av>` compares old vs layer `check` output.
  - `scripts/warn.py <tsv> <out.json>` is the warnings count; it writes packages to `/tmp/ww/pkg` and symlinks `vendor/<x>` to `packages/std-<x>`.
  - **CAUTION:** `warn.py` reuses ONE directory, so the old path's store can keep a previous row's facts. My census "difference" was that artifact. Use a fresh dir per row for anything delicate.
- **Scratch worktree** `/work/wt`: detached, holds a staged copy of the 0b820238 draft. Reset it before reuse: `git reset -q && git checkout -- .`
- `/work/avra-standing-backup` is an older standing compiler binary (not needed).
- **Bridge:** `mcp__claude-bridge__post_to_controller` with the session token from the brief. Posts: ≤12 lines, numbers first, only at a bundle, a blocker or a ruling. Push nowhere.
- **Bundles:** `git bundle create /work/avra-lane-parity-types.bundle b54/batch54..avra-lane-parity-types` (or against the newest batch), then post `BUNDLE READY <path> <head>`.
