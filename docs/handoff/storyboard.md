# HANDOFF — lane: storyboard (session avra-lane-storyboard)

## Goal
The storyboard (docs/2026_11_24_STORYBOARD.md): every std-ui view in every state its own members
imply, under every OS dial, for the owner's page (`avra dev tools/storyboard`), the gate
(semantic snapshots + Firefox claims with mutants), and later web/native parity.

## Tickets
- avra-8sb5.109.9  ruling (1) a control always has a name — DONE except the literal `""` refusal (blocked, below)
- avra-8sb5.109.13 ruling (2) text takes an ink subset — investigated; spelling proposed to the warm lane via the lead; nothing built
- avra-8sb5.109.10 field containment — DONE (web rule + terminal test)
- avra-8sb5.109.12 wrapping row with a least width — on the layout study's list (ROADMAP), not built (P3, by ruling)

## Branches and tips (all on avra-lang/avra)
- lane/storyboard/slices-1-3 @ 0e1d051875e0122aaeba35bc54f74acf26848d95 — slices 1–3 + rulings work, rebased on gh/program e02d71ab, ready to land
- handoff/20261125-1144/storyboard — the same tip plus this file as docs/handoff/storyboard.md
- Base: program e02d71ab (land: std-ui one differ …)

## Done (on the branch)
- @viewed rows (std-ui tree/viewed.av, the View derive's view_row): 29 views incl. compositions
- @story / @case + the derivation registry (tree/story.av); stories in all 29 component files
- page: std-ui_gallery/src/storyboard.av, tools/storyboard (index, filter, dial checkboxes, frames, pins shown)
- gate slice `storyboard` in tools/gate.sh: test std-ui_gallery (golden 122 snapshots + coverage) + tools/storyboard_browser.sh (Firefox claims, tools/storyboard/claims.mjs, baseline tools/storyboard/pinned.txt `# at most 9`)
- realize/html: input held to its box; fieldset min-width:0
- ruling (1): tree/named.av (names_itself, nameless), app paint says `ui:` warning; empty case dropped where it draws a nameless control
- Tested with e02d71ab's gate-builder compiler: std-ui 1103/1103 + 88 proofs; std-ui_gallery 52/52; Firefox 158 row green (570 frames, 21 failures all pinned, 9/9 mutants), 78 s

## Half-done
- Literal `""` label refusal (ruling 1): six `fn check() -> List<Diagnostic> { control_named("<c>", self.label) }`
  in components/{button,checkbox,field,link,slider,switch}.av + the `control_named`/`unnamed` voice in tree/named.av.
  Built and reverted (not on the branch). BLOCKED by a compiler defect: a component with `fn check()` loses
  its row `key` to the repeated-rows law — packages/std-avrac/src/features/repeated.av `rows_under` reads
  `store.walked(e)`, which answers the judged form and hides the struct literal's `key`. Repro sent to the lead.
- Ruling (2): proposal `alias Words = Ink.{Text, Muted, Disabled, Danger, Success, Warning, Link}` for
  Style.color, Wear.ink, error_text.ink (Wear.line keeps all of Ink). Warm lane owns the type side.
  After it lands: the derivation's enum rule reads the subset's variants -> the `legible error_text/ink Border/` pin goes.

## Next
1. Land lane/storyboard/slices-1-3 (open a PR / train it).
2. When repeated.av's key fix lands: re-add the six checks (one commit), witness `button ""` refused once each.
3. When the ink subset lands: drop error_text's non-text ink cases, remove its pin, lower `# at most`.
Exact next command for a local check: `CI=true sh tools/storyboard_browser.sh` (needs Firefox via
.github/ci/install_firefox.sh; wasm needs CC=wasi-sdk clang + WASM_OPT=binaryen ≥ 123 in this container).

## Open questions
- Hold the six checks together (recommended) or land button/link first?
- packages/site suite fails 1/18 ("a POST to a screen is refused as a page too") on base too — not this lane's.
- `avra fmt` drops `export` on `export state` (refuses: "a comment was lost").
- A store entry made under an old generator shape traps check/dev ("index 19 is out of bounds (length 15)") until .avra-cache is emptied.

## Runs in flight
None.
