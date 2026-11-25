# UI — where it stands and how to resume (2026-11-16)

Epic `avra-8sb5.59`. The design record, every unlanded idea and the full idea
ledger are in `docs/2026_11_16_UI.md`. This file is only the working state.

## Resume

- Branch from GitHub `program` (avra-lang/avra), never `main`. `main` is the old compiler.
- Set no `AVRA_PROGRAM` / `AVRA_PROGRAM_NET`: the default is the new pipeline with the old check as a net.
- Build once: `make bootstrap`, then `make avra` twice. Iterate with `make try`.
- "program-layer false refusal" in a build is a compiler defect: report it to the compiler lead; `AVRA_PROGRAM=0` for that one command.
- Landing: work lands on `program` through the compiler lead (a bundle or a branch pushed to GitHub), not by PR to main.
- GitHub `program` is local `program`'s tree as commits over main; shas differ, trees are equal.
- Needs: WASI sysroot 25, binaryen, wabt, Firefox.

## Proven on the new pipeline (1be8f5fe, per the compiler lead)

`make ui-board` 77 claims · `make ui-browser` 89 claims (Firefox) · std-ui 975/975 ·
std-ui_gallery 38/38 · std-ui_http 17/17.

## Live branches (all based on old `main`; each needs a rebase onto `program`)

| Branch | Ticket | What |
|---|---|---|
| `ui/cache-slice-5` | same | Phase A (library) LANDED on local `program` through `442e5cff6`; Phase B waits on the switch: `explain --cache`, dev HUD, `avra_ui_told` (ten commits, listed in the ticket) |
| `ui/typed-board` | same | LANDED on local `program` as `06891d4e8`; board wasm grew 8.7% (ticketed); the create door wants a keyless draft type (ticketed) |
| `ui/percent` | same | LANDED on local `program` as `2e710d948`; the Firefox layout-oracle cases are unrun |
| `ui/random` | same | `@std/random` rungs 2–3; the page CSP nonce waits on it |
| `ui/conditional-impls` | same | bounded impls slice 1; a save of uncommitted work, never built |

The cloud lane `avra-lane-ui-build` works the program layer itself and is not part of this list.

## Tickets

`tasks tree avra-8sb5.59.30.1` lists the recovered items (first sweep: 4 live, 5 restart, 17 harvest; second sweep: a frame scheduler and a canvas realizer, both restart).
New children of `avra-8sb5.59` itself fail to mint (id collision past `.52`); file under a child.
The epic's L0–L3 tickets are stale against what landed and want a rewrite.

## The archive

Every UI branch tip removed on 2026-11-16 (458 refs, uncommitted worktree state included)
is in one bundle: `~/.avra/archive/ui-2026-11-16.bundle`, also attached to the draft GitHub
release "UI branch archive, 2026-11-16". Restore one: `git fetch <bundle> <ref>`.
A second sweep on 2026-11-17, by content rather than name, added `~/.avra/archive/ui-2026-11-17-more.bundle`
(315 refs, same release): 118 local copies of PR heads and 32 UI branches were removed after judging.
Left standing and unjudged beyond their UI part: 26 mixed and 138 mostly-non-UI branches that touch UI files
(list: the `share.txt` scores are not kept; re-derive with `git log --all --not program --source -- packages/std-ui`).
Older working notes are in `.lead/archive/ui/`.

## Authoring study (2026-11-17, in progress)

Decisions and probe results: `docs/2026_11_16_UI.md`, "Authoring: decisions". Agreed: `self.` for a
component's own names; a place passed with no marker; `state` in a component head; a slot is a field
of views with `@default` on one; keys of any comparable type; `words`/`reads` into the derive; events
name no target; native by default. Context (`ctx`) is decided in outline (a language feature, a line to the end of its block, the value on the
task; `docs/2026_11_16_UI.md`, "Context"); its three study reports are in `.lead/archive/ui/studies/`.
Theming slice 1 is landed (typed theme, role pairs, Crisp, light/dark and contrast as dials).
Next: theming slice 2, then the native rendering question on paper, then animation (ticket .30.1.32).
Order of work the owner set: authoring, theming and state on the web with a small component set,
then the same set on iOS, before going further. Sync is first class and designed with state.

## The one track (owner 2026-11-17: fewer threads, move forward)

MILESTONE 1: the board, on the web, written the way the record says (a `state` head seat, a default
slot and named blocks, a key that is its id, `ctx theme`, Crisp as theme data), its claims holding.
- Library: DONE as far as it goes without the compiler (theming slices 1 and 2, the per-target event
  table). `words`/`reads` turned out to need the compiler.
- Compiler, asked of the compiler lead: `state` in a component head; `@default` on a slot and a slot
  filled by a named block; a key of any comparable type; `ctx`.
- PARKED until Milestone 1 lands: the animation, state-and-sync and distribution studies; the iOS
  spike (also waits on an iOS target); the harvest tickets (pulled only when their area is touched);
  the 164 mixed branches (left for good); rebuilding the epic's ticket tree.
Before landing any std-ui change: grep every package for what was renamed (the `Tone` -> `Ink`
landing broke a cli fixture nobody ran).

## Owner decisions on record

- No `derived` / `query` keywords; the eight cache decisions are in `docs/2026_10_26_OBSERVATIONS_CACHE.md`.
- Generic components go ahead; the typed-routes spelling is `crud tasks<Task> {}`.
- WAL is opt-in (`journal: Keep` default); the HUD panel is its own Avra module.
- `Task` stays built in; no program type overrides it (owner 2026-11-16). Examples use `Todo`.
- Cut from the first finish line, kept in the ledger: generative UI, Android (after iOS), products and paywalls (library level, later). Deploy is not now; a get-onto-devices story is owed.
- Finish line: one excellent cross-platform app by milestones, web first, then iOS.
- Structural `==` (eqstruct): hold lifted 2026-11-16, it can be worked on.
