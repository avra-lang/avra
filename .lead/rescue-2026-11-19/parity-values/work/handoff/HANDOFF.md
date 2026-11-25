# HANDOFF — lane `avra-lane-parity-values` (annotations and values)

## Who and what
Lane `avra-lane-parity-values` on the Avra compiler, for the lead (controller) reached over the bridge
(`mcp__claude-bridge__post_to_controller` / `send_files`, session token in the bridge note; bundles go out as
`/work/avra-lane-parity-values.bundle`, branch name EXACTLY `avra-lane-parity-values`). Goal: the program layer
(AVRA_PROGRAM default; `AVRA_PROGRAM_NET=0` turns off the old-path safety net) speaks every refusal the old path
(`AVRA_PROGRAM=0`) speaks, in the old voices (shared voice fns), so the old path can be deleted. My area:
annotations (validating annotations, generators, marks), values (consts, settlement), enums/match/patterns/lambdas.

Standing rules: commit on the branch, push NOWHERE; no `rm` (use `find … -delete`), no `git stash`/`reset --hard`/
`--no-verify`; `fmt --write` touched .av; a law never assembles prose (named voice fn shared with the old path);
post only at a bundle/blocker/ruling, <=12 lines; gate reds that are not mine are REPORTED, never fixed; every
bundle's receipts = `check packages/std-avrac` exit 0 AND `sh tools/gate.sh avrac-a..g` no unpinned failure, idioms
0 NEW from my files, cli NET=0 build exit 0, witnesses, fmt --check.

## Base and commits ahead
Base: batch53 `d5062c32` (/work/batch53.bundle; prerequisite d750dfa7). Branch HEAD `ac776a62`. Ahead of batch53:
- ac776a62 WIP: the counterfeit-receiver law speaks only where the annotation's arguments name something
- d6889b3c the annotation laws only the net said, said by the layer alone (derived traits' marks claims; trait `Self` as a type variable; trait place item-relative; the 21 `net_off_*` witnesses)
- edeb2641 a validator's computed argument runs at compile time (argument_lifted; broken run = annotation.unsettled)
- ba016bb4 a wrap that doesn't stand is refused (wrap_missing/bodiless/mismatch; externs cross as Fn)
- 2aef1bec callee/receiver laws the net alone said (let-named callee, counterfeit receiver, derive on the wrong kind)
- fac8c8fd an annotation that makes declarations is handed only what the source spells
- ad95e4d7 std/db: a key's run-time refusal names the declaration, never a place
- 1e51f958 a declaration crosses with its places counted from its own item (derived-edit witness green)
- 0e392e26 the annotation rows the old path says and the layer didn't (same-file generator, generated_taken, unfit literal)
Already landed in lead's batches (not ahead): everything up to and incl. c83c540d (Field seats, std-db `@unique(a,b,..)`,
[lifted] budget help, seat-args, validators, record-const crossing, etc.).
Bundle of the above: /work/handoff/lane.bundle (`git bundle create … avra-lane-parity-values ^d5062c32`). Uncommitted
diff: none (/work/handoff/uncommitted.patch is empty).

## In flight and how far it got
THE 21 SILENT ANNOTATION LAWS (switch blocker; list: scratch/annotation-silent-21.txt). All 21 now say the same
`error[kind]` set on both paths (runner: scratch/s21.py, cases rebuilt as /tmp/s21/N) and each has a layer-alone witness
`tools/program-refusals/net_off_*` (21, pinned from the old path, hold 21/21 with the net off).
Receipts on d6889b3c: gate avrac-a,c,d,e,f,g PASS; avrac-b had ONE unpinned failure ("an argument that does not type is
refused as any expression is" — my counterfeit-receiver law added a 2nd error); fixed in ac776a62 (verified by running
`build/avra-try test packages/std-avrac/src/features/annotations`: 185/188, the 3 failing are pinned in
tools/gate/std-avrac.names). layer check 0 errors; cli 0; idioms exit 1 with 0 NEW (27 `ctx.old_path` from batch51's own ctx
tests — REPORTED, not mine). Witnesses on d6889b3c: all hold except `annotation_unresolved` (fixed by ac776a62; passes).
witness_program_edit: every section green; once, edit 5 (cli fmt.av `Walk`) "taken back" failed during the full run but
passes alone (WITNESS_ONLY="5") — a one-off under load, not reproduced.
NOT DONE: receipts on ac776a62 itself (full run), and the bundle to the lead.

## Next 3, in order
1. Run the receipts on ac776a62 (`sh scratch/full.sh`, see Gotchas), then `git bundle create /work/avra-lane-parity-values.bundle batch53..avra-lane-parity-values`, send, and post a <=12-line BUNDLE READY (numbers first). Include: the 21 net_off laws, item-relative crossing (builds_annotation_crossing_whole is pinned known-to-differ: places are item-relative), std-db names the declaration not a place.
2. Promised and NOT done: a type-level `@unique(a)` on a `@model` that names ONE field is a key of one column; its shape line `unique(a)` is unreadable (std-db/src/shape.av `unique_read` only reads keys of >=2 columns). Refuse it in `unique` (db.av) with a voice like model_key_empty: "use the field's own `@unique` mark". Then std-db DECLARED INDEXES over the same `..fields: List<Field>` seat: type-level `@index(a, b)`, recorded as `index(a,b)` lines in the shape text (shape.av shape_text/shape_read), Step.Index/Unindex in migrate.av (diff keys_between, statements, notes), `declared` voices like `model_key_*` in db.av, tests in packages/std-db/src/tests, layer-only witnesses like builds_db_model_key. Tell the services session (via the lead) when it lands.
3. annotation.meta (5 rows, parked for me): /work/package-245.tsv (+ split-*.tsv). scratch/rerun.py re-ran every annotation row of package-245 on batch53: only `annotation.unplaceable` (pinned known-to-differ) differed after my fixes, so re-run it on the new head and confirm annotation.meta is already closed before doing more. Parked singles still parked: `self()` (receiver type absent from method typed nodes), trailing block in a non-fn seat, `Show.lifted`, unknown_prop inside untyped lambda bodies.

## Open rulings / asks waiting on others
- Lead owes: nothing pending from me. I never posted the services-session note for ad95e4d7 (std-db text now names the declaration, `Fact` / `Fact.slug`, never `at …:NN`): the lead asked "tell the services session (via me)" — put it in the next bundle post.
- Asked the warm lane (via lead) nothing yet: the lead asked me to confirm I share ITS placing fn, not a second rebaser. I use `file_placed` / `placed_in_item` / `span_in_file` (item_context.av) only — one placing fn; the item is carried in a crossed place's `Loc.file` as `pkg:path#<item>` (`item_spelled`/`spelled_item`).
- Labelled annotation arguments: the old path types `@f(1, flag: true)` against the next unlabelled seat and refuses it; the layer accepts. Lead agreed it's an old-path defect; left unpinned.
- Known/pinned differences I own: w_annotation_unplaceable; budget cases (body_const_budget, const_over_budget, w_const_default_steps, w_dependency_const_budget_is_its_own — ruling (c): a const's budget is its OWN package's [lifted]); validator_past_its_budget / validator_that_traps (old path silently passes); validator_handed_what_does_not_cross; builds_annotation_crossing_whole.

## Gotchas
- `. /etc/profile.d/avra.sh` first. Env for heavy runs: `AVRA_MAX_COMPILES=16`, `AVRA_MEM_POOL_MB=14000` (idioms).
- Build: `AVRA_PROGRAM_NET=0 make try` -> build/avra-try (built by the standing build/avra). If the standing compiler can't build the tree (a bug it carries), bootstrap: `AVRA_PROGRAM=0 make try; cp build/avra-try build/avra; AVRA_PROGRAM_NET=0 make try`. build/avra-try currently = ac776a62's tree.
- Receipts driver: scratch/full.sh = `sh /tmp/gate8.sh` (copy scratch/gate8.sh to /tmp; resumable, writes /tmp/gate8.out, skips slices already recorded for the sha; ends `ALL_DONE <sha>`) then `make try`, 3 witness shards over `tools/program-refusals/*` (/tmp/cases.sh.aa/ab/ac, logs /tmp/wit.a?.log), prints idioms from /tmp/idioms.log. Run `tools/witness_program_edit.sh build/avra-try` separately. Spec runs and the gate COMPILE THE TREE: no source edits while they run.
- Disk: /tmp/tmp.* witness dirs and caches fill the disk (a full disk makes dozens of witnesses fail with "No space left"): `for d in /tmp/tmp.*; do find "$d" -delete; done`. Container restarts kill background jobs; use the resumable gate script, one heavy run at a time.
- Subprocess probes: set `PWD` to the case dir (the compiler reads $PWD), a private `AVRA_CACHE_DIR`, `AVRA_STORE_KEPT_HERE=1`; case package names must differ or the store collides.
- Witness cases: `tools/program-refusals/<case>/{avra.toml,src/main.av,refuses.expected|prints.expected,differs.why,warns.expected}`; `PIN=1` pins from the OLD path (layer-only forms are held on the layer alone); `@std/meta` comes from the toolchain (no dep line); sources must be `fmt`-clean; layer-only forms are `NewOnly` (compiler/item_new_only.av; FieldSeat is mine).
- Idiom rules that bit: closures.pronoun_lambda, compiler.duplicated_message/duplicated_literal, if_expr.when_ladder, fns.dead_parameter, structs.index_compared; private module-level names must be unique across a module; variant payloads take no defaults; `it` fails in nested calls.
- A law is `export law name { kind, reads, voice, warns?, witness, witness_files? }`; voices live in features/annotations/check.av (shared with the old path); worn annotations: `worn_on` / `WornOn` in compiler/item_annotations.av.
- Scratch kept: scratch/ (s21.py, mk21.py, rerun.py, parse.py, tables). /tmp/an*, /tmp/s21, /tmp/svc are throwaway.
- Old branches seat-args, seat-args2 in the repo are merged in; ignore. I'm on whatever model the session runs; attribution lines on commits per the session's reminder.
