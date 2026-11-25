# Handoff — lane `avra-lane-layer-commands`

## Lane and scope
- Lane / session / branch / bundle stem: `avra-lane-layer-commands` (repo `/work/avra`).
- Original item (done, 13/13): every CLI command moved onto the program layer, old drivers deleted.
- Kinds this lane owns now (ask the lead before taking another): `type.alias_copy`, `type.list`,
  `type.seat`, `type.spread*` (spread, spread_nullable, spread_missing, spread_field),
  `type.record_pattern`, `type.sealed`, `type.component_event`. Also fmt (this lane owns the
  formatter) and the `run --eval` / instance `check()` questions the lead hands over.

## Base
- Branch `avra-lane-layer-commands` sits on **batch53 = d5062c32** (from `/work/batch53.bundle`).
- The lead said b15 (e2a2ef1c) is in batch 54. b16 (9c56843b, d09daad3, 62aaf883) was sent; not
  yet confirmed landed.

## Commits ahead of batch53
| sha | what | state |
|---|---|---|
| e2a2ef1c | fmt --write accepts its own canonical form in a component body (canon receipt compares a verbatim body by its parsed statements, not its raw text) | sent b15, in batch 54 |
| 9c56843b | the 10 files `fmt --check packages tools` named on batch53, written canonical (formatting only) | sent b16 |
| d09daad3 | `tools/gate.sh fmt <base>` slice: fmt_changed.sh over the diff from the program landed last | sent b16 |
| 62aaf883 | fmt reaches its fixed point in one pass (`lone_line` at the 5 one-line sites) + one_line_test cases (fixed point AND write receipts) | sent b16 |
| 64383ef9 | WIP: `on_handlers` column `@taped(expr, handler_read)` | WIP, not gated |
| 25aa6341 | WIP: a handler re-marked on read-back keeps its unheard reason (`held_unheard`); a record literal skips an unheard handler's field | WIP, not gated |

`lane.bundle` holds all six (`^batch53`). `uncommitted.patch` is empty (everything is committed).

## In flight: component_event, instance side
- Declaration side landed earlier (e187c5b8, in batch53): `compiler/item_component_events.av`,
  5 laws plus `event_heard` (instance law) that reads `store.on_handler(h).unheard`.
- Cause found: on the layer an item is read back from its tape, and the setting's `is_heard`
  stmt mark re-marked the handler with a fresh `OnHandler`, wiping the `unheard` reason the
  instance's meaning had set. Fixed in 25aa6341 (`held_unheard` in `mark_on_handler`/`mark_heard`
  in core/store.av); 64383ef9 tapes the column (keep it: the reason must ride the tape).
- Package cases from `/work/package-245.tsv` (component_event rows) are extracted at
  `/tmp/p/q00..q16` (copied to `/work/handoff/cases/package-events-sealed/`, each with `.old`/`.new` outputs beside it) (q17..q26 are the sealed ones). Compare: `AVRA_PROGRAM=0 build/avra check <dir>`
  vs `AVRA_PROGRAM_NET=0 build/avra check <dir>` (delete `<dir>/.avra-cache` between). The vendored
  `@std/meta` line was deleted from every manifest there so they resolve.
- Now 14/17 identical (q00–q04, q06–q14). Remaining:
  - q05: `panel { on size { … } }` where `size` is a FIELD (int), not an event — old says only
    component_event (undeclared event); layer adds `type.lambda` ("a lambda cannot sit here").
    The layer should not seat an unheard handler at its field: skip seating values that
    `refused_elsewhere` in `features/structs/checks.av` (the unknown-field skip is done; the
    known-field seat path still seats it).
  - q15: a template whose event is refused where declared; old path adds the note
    `refused_there` ("`lim`'s event `press` is refused where it is declared, so this instance is
    not built", kind type.component_event, a note) at each instance. Not on the layer yet.
  - q16: `panel { press: 5 }` — a plain setting naming an event, value of the wrong type; old says
    "`press` is heard by a handler, `fn()?`, and this is `int`" (type.component_event); layer says
    type.struct_fields. Needs the record-literal seat refusal for a field that is an event to use
    the event's words.
- Then: gen-2 build, a witness (tools/program-refusals, package case with a vendor dir like
  `sealed_sites`), gates, commit (squash the two WIPs into one real commit message), bundle.

## Next 3 items, in order
1. Finish component_event instance side (q05, q15, q16 above), gate, send.
2. Narrow the `check()` repro the lead sent: `/work/schedcheck/schedule_check/` (REPRO.md,
   out.txt) — real `@std/queue` schedule at the top level of a [bin]; check/build/run silent,
   `nightly.check()` at run time gives 2 refusals. Run on batch 54's head (lead sends it).
   Candidates: `at:` is `Result<Cron, CronError>?`, `sends:` is another instance, `item: T`
   generic, a defaulted fn-value field `clock: fn() -> Time = now`, two `state` defaults.
   My own probes (a lib `cron(text)` into a plain field, head/block/fn/bare) are all checked —
   see `/tmp/sch` (copied to `/work/handoff/cases/check-probe/`) — so it's one of those candidates. `settles_alone` (core/settled_alone.av) and
   `item_instances_checked` (compiler/item_instance_checks.av) decide what is judged.
3. Whatever the lead hands next; remaining sealed 2/10 were ruled not mine.

## Open rulings / asks waiting on others
- check() repro: waiting on batch 54 bundle to run it on its head.
- b16 landing (fmt slice + fixed point + 10 files) not yet confirmed by the lead.
- Known not-mine reds seen on batch 42+: `w_collect_enum_self` span trap ("a span reaches outside
  its own text"), 3 unpinned `item_tapes_test` cases, collect `Self` trap. Sandbox-only reds:
  `wasm_hello` (no `-lsetjmp` for wasm-ld) and the 9 `avra dev` wasm-link cli cases.

## Things a fresh session trips on
- `source /etc/profile.d/avra.sh` before builds. Build: `AVRA_PROGRAM_NET=0 make try`, install with
  `until cp build/avra-try build/avra 2>/dev/null; do sleep 2; done`. A law/printer change needs a
  second generation (`make try` again with the new build/avra).
- Gate: `sh tools/gate.sh <slice> [base]`; idioms/fmt slices take a base sha. One heavy job at a time
  (4 cores). Never edit files while a gate runs (it reads the working tree).
- Disk: `build/scratch` grows to 15 GB from test runs; a child `avra` refuses to start under a
  2 GB free floor ("watch: … under the 2048 MB floor"), which shows up as unexplained cli test
  failures. Clean with `find build/scratch -mindepth 1 -maxdepth 1 -mmin +90 -exec find {} -delete \;`.
- Rules: no `rm` (use `find … -delete`), no `git stash`, no `git reset --hard`, no `--no-verify`, push
  nowhere. Commit trailer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01F8zAGfLBeCXLqunb15uYv2`.
- Bridge session token for posts: `cse_01F8zAGfLBeCXLqunb15uYv2.61270d8e8c881e8f7159`.
- Kept binaries: `/tmp/proof/avra-b42` (pure batch 42), `/tmp/proof/avra-lane-229f4ffd`.
- Probes that read the store directly: a throwaway `packages/std-avrac/src/compiler/tests/zz_probe_test.av`
  using `parse_program(avra(), new_source_file(...), BlockWords { components: [ComponentWord {
  word, declared, form: Instancing.Shaped(false), origin: "" }] })`, run with `build/avra test`, then
  delete it. Without the words a component instance isn't parsed as one.
