# UI lead handover — 2026-10-27 06:05 PT, updated 07:00 PT

Epic avra-8sb5.59. PRs land themselves: arm auto-merge on a green, up-to-date PR
and the watcher refreshes a stale one (`tools/pr_watcher.py`). The pre-10/27
"send the head sha to the DB lead and it batches" instruction is RETIRED — the
DB sessions on this machine are the hold-deletion lane (`DB HOLD`, PR #1371) and
the graph lane, neither of which batches. Verified with both.

## Where main is

`5f65f027` — observations cache slice 4 (#1377). Before it `bc917ecb` view-arms
(#1375), `dea443b8` typed routes slice 2 (#1378), `4470ba64` typed routes slice 1
(#1363), `bdb14737` batch BN (#1376). Main moves fast; pull `origin/main` right
before any rebase.

## Nothing unlanded — all three landed

| PR | Result |
|---|---|
| #1378 typed-asks | merged `dea443b8` |
| #1375 view-arms | merged `bc917ecb` |
| #1377 cache-slice-4 | merged `5f65f027` |

Main is `5f65f027`. Each landed itself on a green, up-to-date run with auto-merge
armed; no batcher was involved, and there is no lander session to route to.

### What each one needed

**#1377** — the rebase's only conflict (slice 4's `Hub`/feed vs typed routes'
`standing`/`described`/`address`) resolved by union, `.Events` given an address and
a `standing` arm, and `Routes<T>` grown by an `events` field so the descriptor can
name a door the router serves. Two real defects it surfaced:

- `avra_ui_noticed` had no `@host(Host.Page)`, so `keepers-wasm` refused and two
  `wasm-refuses` fixtures could not link.
- **A stream outlived its client.** A write into a half-closed socket SUCCEEDS, so
  a stream whose only evidence of a departure is a failed write stood for a reader
  that was gone and 20 s of writes could not reap it. `pumped`
  (`std-http/src/server.av`) now asks the transport between pulls
  (`wire_silent`, whose own rule is that a connection which is not silent is
  closed, never read again): the native leg went from a 20 s stall to 0.7 s. The
  law is in CLAUDE.md ("A STREAM ENDS BECAUSE ITS PEER IS GONE").
- `inputs` refused the dev relay's `connect` and six unclassified `@std.http` /
  `@std.net` names; the site is licensed and the names joined WORLD.

**#1375** — the if-expr half planted the seat's want as the arms' anchor and judged
with `accepts`, which CHECKS and does not RECORD the widen, so a
`Result<Card?, SqlError>` seat refused `Card`/`null` arms across std-db, std-http
and std-https. The branches now JOIN when they can and the want judges them only
where they cannot join among themselves (where a `dyn View` seat boxes a note and a
badge). Three more paid on the way: `Gathering` seeds its want through
`want_gathered` so the licensed literal keeps the text the baseline holds;
`site_licenses` reads the site off the FINDING when the subject is a BLOCK (every
`bracket_ritual` licence was decorative before); and two main specs were re-pinned
to the diagnostics the slice moved.

#1378 typed-asks LANDED as `dea443b8` (typed routes slice 2). Typed routes 2b
(the shared `@ui/board-model` package) is unblocked by it.

### #1375 view-arms is RED and needs its author

Four findings, three of them real compiler regressions — recorded in full in a
comment on the PR. In short:

- `if cx.want_at(e) != null { return cx.arms_agree(...) }` (if_expr/check.av)
  plants the want as the arms' anchor and judges each arm with `accepts`, which
  CHECKS and does not RECORD the widen. So a `Result<Card?, SqlError>` seat
  refuses arms `Card` / `null` that previously joined to `Card?` and were
  auto-Ok'd by the seat's own agreement door. std-db, std-http and std-https all
  fail on this shape (`an `if`'s branches disagree: `Card` vs the seat's
  `Result<Card?, SqlError>``). The match/collect half is the slice's feature and
  its witness; the if-expr half is what regresses.
- `gate`: one new `compiler.bracket_ritual` — `self.gathers.push(Gathering { …
  want: want … })` in typing.av. The baseline lists the site with the literal's
  OLD text, so widening it reads as a new site; the `// LICENSED
  compiler.bracket_ritual` line directly above silences it under `check
  packages/std-avrac` but NOT when the file is read as a dependency under `check
  packages/cli`. That is a licence read against `a.view.source` rather than the
  finding's own file — a licence is a property of the SITE, not of the root
  package. Until it is fixed no baselined site can change its text, so this is
  worth its own slice.

Rebase notes, so the next session does not re-derive them:

- **#1377** conflicted in `packages/std-crud/src/routes.av` — slice 4's
  `Hub`/feed machinery against typed routes' `standing`/`described`/`address`.
  Resolution: imports unioned; `crud_routes` keeps slice 4's `every` seat and
  `held = hub(...)`, and filters with `standing(d.door, w.soft, without)`
  (slice 4's `opened` already excludes trash/restore when not soft, so
  `standing` is equivalent and is the one declaration). `.Events` — a Door
  variant slice 4 adds — gained an `address` (`GET /events`) and an arm in
  `standing` (it always stands). `described()` leaves it out on purpose:
  `Routes<T>` has no `events` field, and the page learns the feed path from the
  server's `avra-feed` header (`std-ui/src/app/feeds.av`). If typed routes ever
  needs to describe the feed, adding that field is the ask.
  Checks clean on std-crud, std-ui, std-http_message; fmt clean.
- **#1375** rebased clean from bdb14737; the local worktree
  (`avra-generic-comp`) already had the rebase done plus two commits, so this
  was reparenting, not resolving.
- **#1378** needed only `gh pr update-branch`.

## The rest of the "open UI PRs" list is LANDED

A batch squash-merges, so `git merge-base --is-ancestor` never proves landing.
Grep `batch-members` in main's commit bodies instead:

- #1319 → batch AX `5c8706b2`
- #1328 → batch BF `7982c422` and BL `6854559f`
- #1332 → batch AY `06fa6cc6` and BC `6c359f6d`
- #1351 → batch BF `7982c422`
- #1344 → batch BC `6c359f6d`
- #1314 → batch AY `06fa6cc6` and BC `6c359f6d`
- #1308 → batch AV `b4567df2`
- #1363 → merged `4470ba64`

Member PRs stay open after their batch lands. Do not rebase them, and do not
read DIRTY as unlanded.

## Worktrees

| Worktree | Branch | Note |
|---|---|---|
| `../avra-obs-cache` | detached at `0de443bd` (#1377) | the slice-4 tree; `tools/dev-hud/` and `.avra/` untracked |
| `../avra-generic-comp` | `view-arms` `cbd645c9` (#1375) | clean |
| `../avra-generic-events` | `conditional-impls` @ `6854559f` | bounded impls slice 1, coded, unbuilt, 19 dirty files — untouched |
| `../avra-busy` | `cache-slice-4` @ `bf13a6d0` | STALE: an old slice-4 tip with leftover dirty files. Do not push from here; the PR is at `d5d899ea`. |

## #1377's four fixes on the branch (all pushed)

- The `.Events` door gained an `address` (`GET /events`) and an arm in
  `standing`; `crud_routes` keeps slice 4's `every` seat and `held = hub(...)`
  and filters with `standing(...)`. Verified: `wasm-refuses`'s `untouched` and
  `model_text` fixtures build.
- `Routes<T>` (`std-http_message/src/route.av`) gained `events:
  Route<Nothing, Nothing>?` and `described` fills it. Without it the descriptor
  could not name a door the router serves, so typed routes' own law was false and
  `crud_paths` read `served 5` against a router serving 6. Growth (appended
  field), not movement.
- `avra_ui_noticed` (a bodied extern added by slice 4) needed `@host(Host.Page)`
  — without it `keepers-b (wasm)` refused with `lower.host_fn_unhosted`, and
  two wasm-refuses fixtures could not link. Also dropped a `?? -1` on
  `index_of`, which is never absent.
- `crud_feed` subtracts what stood before its section from the "three watching"
  number (the counter is the PROCESS's) and keeps the last number ABSOLUTE.

## Queued work, in order

0. DONE — the stream/peer law landed with #1377 (`pumped` asks `wire_silent`).
1. Cache slice 5 (optimistic layers + write lanes, plus the red-team fixes for
   trapped-parse and the reconciled re-ask bound). It must DELETE the board's
   interim write lanes. **Unblocked now** — it lives on the local `obs-seq`
   branch (26 commits: slice 3 and 4 rebased, then slice 5, the HUD frame,
   `explain --cache`, the dev panel, and the trapped-parse fix). Rebase it onto
   `5f65f027`; its slice-3/4 commits become empty and git drops them, leaving
   slice 5 onward.
2. The HUD runtime half, `/@dev/cache`, `explain --cache --live`, and the panel
   as its own module instance. After slice 5.
3. Typed routes 2b: a new package `tools/ui-board/model` (`@ui/board-model`, one
   `@crud @json Todo`) shared by the page, server, term and hydrate. The board
   moves onto `ask`/`send`. PR headline is the board's wasm size before and
   after. Approved.
4. Bounded generic impls: slice 1 conditional (`impl Decode for List<T: Decode>`)
   is coded in `../avra-generic-events`; slice 2 blankets
   (`impl Args for T: Decode`) with orphan/overlap/cycle voices. Slice 2 lets
   `ask_list` fold into `ask`.
5. The `shape_inputs` rewrite to one exhaustive `match` (a saved patch), after
   #1375 lands — and #1375 needs its if-expr half repaired first.
6. `crud tasks<Task>`, the full-stack generic component. `Task` is a built-in
   name, so examples use `Todo`.

## Owner decisions on record

- #1312 budget raise approved: rule_nodes 1545→1553, rule_runs 30483→30629.
- No `derived`/`query` keywords. The 8 cache decisions are in
  `docs/2026_10_26_OBSERVATIONS_CACHE.md`. Generic components go ahead.
- Owner may revisit: WAL is opt-in (`journal: Keep` default); the typed-routes
  spelling is `crud tasks<Task> {}`; the HUD panel is its own Avra module.

## Infra facts

- The disk floor bites: `./avra` refused at 2020 MB free (floor 2048). Clearing
  `avra-obs-cache/.avra-cache` (617 MB) was enough. Clear only `.avra-cache`.
- A full std-avrac suite does not fit a Sprite's memory cap (SIGKILL). CI
  finishes it.
- The pre-commit hook needs a merge-base compiler; never `-n` or `--no-verify`.
- WebKit is missing on avra-o-lower and avra-db-names (provisioning gap).
- `gh pr edit` fails on this token (`read:project`); use `gh api PATCH`.

## Laws re-learned today

- A probe names its base. `git merge-base --is-ancestor` cannot prove a batch
  landed; the `batch-members` line in the batch commit body can.
- Reading the worktree's `ls` is not reading main: the primary checkout sat at
  `99adde36` while `origin/main` was `4470ba64`, and that made a landed file
  look new.
- A parse function under observation must be pure
  (`ui.pure_observation_parse`).
