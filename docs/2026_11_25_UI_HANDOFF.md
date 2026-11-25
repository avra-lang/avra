# UI lead: handoff, 2026-11-25

For the session that resumes the UI lead's work. Everything the UI lead owns, where it is, and what is
waiting on whom. Read `docs/2026_11_16_UI.md` first (sections "Milestone 1", "Native targets", "The
performance bar"): it is the design record and this page does not repeat it.

## Where the trunk stands

`program` = e02d71ab. Landed today: first paint slices 1 and 2 (server-drawn first paint, one module fetch in
every engine), the board train (Auto/Light/Dark, `on submit`, place-form tabs), `@seeded_at_need`, iOS step A
(`--target arm64-apple-ios-simulator`), TARGETS.md, one differ (the generic matcher and the native lowering,
web byte-identical), the UI doc's native rulings and performance numbers.

## Worktrees and branches

| Worktree | Branch | State |
|---|---|---|
| `../avra-ios` | `ios-spike` (pushed) | THE LIVE WORK. 46 commits ahead of trunk. Compiler at `build/avra` is the gap-2 one, linked from `build/handoff/seed-9589557f58.ll.gz` (not in the depot) |
| `../avra-ui-live` | detached at f08fb217 | the owner's live board: `./avra dev tools/ui-board --host <tailscale address> --port 8799`; browser harness in `build/pw/` (`check.mjs`, `paint2.mjs`, `slow.mjs`) |
| `../avra-one-differ` | `ui/one-differ` | landed in train24; nothing left |
| `../avra-ui-notes` | `ui/perf-numbers` | landed; use it for the next doc branch |
| `../avra-targets` | `targets/*` | the targets lane's (the lead's agent), not mine |

Never delete a worktree. Disk on this Mac is near full (3.5 GB free at handoff): no builds or simulator boots
under 3 GB free; the owner has been asked whether Xcode derived data and unused simulators may be cleared, and
has not answered.

## The iOS spike (mine since the handoff from the lead's agent)

Docs on `ios-spike`, in reading order: `2026_11_25_IOS_SPIKE.md` (slice 0 and the first handoff),
`2026_11_25_IOS_SPIKE_FINDINGS.md`, `2026_11_25_NEUTRAL_PATCH.md`, `2026_11_25_IOS_BENCH.md` (its top section
"Where it stands" is the one-screen status), `2026_11_25_KEPT_ROW.md`, `2026_11_25_PLACE_BY_IDENTITY.md`.

- Runs: the board's own `view` as UIKit controls, placed by std-ui's solver, UIKit measuring; live tasks from
  the board's server; a hand-written UIKit twin and one instrument for both; on the owner's iPhone, signed
  with his existing wildcard development profile (`tools/ios_device_bench.sh`, `AVRA_DEVICE` required).
- Device numbers are round 3's (before kept rows and the cheaper row recycle). QUEUED for when the phone is
  awake, unlocked and connected: five runs each of the direct-calls build, the twin, the current build, with
  the cold-start timeline, the memory parts and the in-app screenshots.
- To lift into std-ui (commits on ios-spike): d8444df `moves_box`, b945fe1 the spacer's stable key, 73c4905
  `stands_on`, 8a9113b element reuse and the matcher's fast path, cbecd1c the measure cache. Dies with the
  spike: the UIKit host, `frame.av`, `kit.av`, `kept.av` (a hand-declared stand-in for the compiler's read-set
  query, unsound for a cell reached through a prop: never to land), the twin, 861678b (the spike-only item-row
  rule).
- Not built: placement proportional to new rows (plan: PLACE_BY_IDENTITY.md, three asks unruled: the focus
  gutter and the memo; the solver per target or per app; one runtime row for node identity).
- Rules the owner set for his credentials: read identities and the existing wildcard profile, sign, install,
  launch on his phone only; never create, renew or delete a certificate, profile or device registration;
  never the distribution identity or the App Store Connect key; nothing identifying in a committed file.

## Rulings in flight (waiting on someone)

| What | Waiting on | Where |
|---|---|---|
| READ_SETS (the cells a fn reads): approved with changes; rules 1–8 build first, then (a)–(e) come back to me: a fn-valued prop's equality, `ctx`, slots, retention cost, the check mode | the warm lane (avra-8sb5.109.16) | branch `proposal/read-sets` |
| TARGETS P1 (one `mount`, `Stage` trait, `@host` answers) and P2 (the manifest, a key lands with its reader): approved | the targets lane, building | `../avra-targets/docs/` |
| TARGETS P3 (the bundle: a page's document and an `.app`): waits to be proposed now that first paint slice 2 has landed | the targets lane, then my ruling | |
| A client app links its server's sqlite (1.3 MB of 2.9) | the alloc lane (avra-8sb5.59.29.7) | |
| ICE: `() -> {}` on the iOS target lowers as an empty map | lowering-quality (avra-8sb5.114.10) | |
| `owned_app` over a stateful component at an entry's top level is refused | the warm lane (avra-8sb5.109.15), downgraded | |
| A type bounds its own parameters; structural `==` | filed (avra-8sb5.10.215, .216) | |
| The storyboard's Firefox reds, and its permission prompt only the owner can click | the storyboard lane | |

## Decisions I owe the owner (none offhand)

1. The layout study: an item's default flow and an item holding a list; whether a row wraps by default; a
   control's narrowest as the solver's stated contract; a wrapping row with a least item width. Input: the
   spike found the web's look resting on HTML defaults; the layout oracle covers rows, columns and text only.
2. A plain `for` in a `list` windows by itself (the idiomatic board builds every row on every target).
3. "Chosen" as data: `button` gains `selected`, or a choice among N becomes a primitive.
4. Text takes foreground inks only.
5. The Apple command line: every Apple action a verb of `avra` (run on simulator and device, devices, shot,
   ship), signing discovered through config, errors that say the fix; a setup checklist for a new account,
   parked by the owner. To be a proposal from the targets lane.
6. The neutral frame as one shared binary format generated from the same tables as the web's wire, for the
   cases with a wall (page, dev tools, record and replay, storyboard parity); in one process a host is called
   directly.

## How the owner wants this run

Screenshots with every visible step, sent unprompted. Short, plain updates that lead with the state. Numbers
beside every speed claim, against hand-written UIKit, on his phone. No consequential design call offhand:
a one-page proposal with probes, then a ruling. A peer's relay of his word is not his word.
