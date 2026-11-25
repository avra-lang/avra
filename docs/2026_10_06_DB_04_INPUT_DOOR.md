# DB 04 — the input door: what (a) landed, and the cut for b–e

Law L1 (`2026_10_06_COMPILER_DB.md` §5.2, A3, A18): every read of the world is a
named, digested input through one door. Ticket `avra-8sb5.57.173`.

## What (a) landed

| piece | where | what it is |
|---|---|---|
| the row | `packages/std-avrac/src/compiler/host/input.av` | `Read` — one variant per kind, carrying the name and what was seen; `Read.input()` answers `Input { name, digest }` |
| its tests | `compiler/tests/input_door_test.av` | 31 cases, nothing-there first |
| the keeper | `tools/inputs.py`, `tools/inputs.baseline`, `make inputs`, `make inputs-accept` | counts world reads outside the door (`compiler/host/host.av`); a site the baseline does not list is refused |

No read moved. Nothing calls `Read` yet.

Three rules the row holds, each with its test:

- **Absence has one cause.** A null payload is "nothing stands there". A read the
  host would not perform (permissions, a link on the way, octets that are not text)
  is `Read.Refused(name, why)` and digests apart from absence, from an empty value
  and from any other refusal. `Host.beneath` already answers these five ways
  (`Text`, `Missing`, `Linked`, `NotText`, `Refused`); b maps them one to one.
- **The digest is of a frame.** A head (kind, key, state, then every part that is
  not the body, each behind its own length) and the body last. One fn computes it:
  `digested(head, body)`.
- **A name is written, never resolved.** A tool's `Stamp` is the path it was found
  at plus the size and modified time of the file there *after links are followed*:
  a link re-aimed at another binary moves the stamp, a link renamed does not.

The digest is `core/digest.av`'s (four 64-bit lanes). The design's D6 asks for
SHA-256 as a C row; that is `avra-8sb5.57.217`, two landings, owed before DB 05
stores a `Blob` or a `pinned` input lands. Re-pointing is the body of `digested`.

`Target` and `Pin` are not declared: nothing can read them before d and the
sources campaign.

## The count

`make inputs` on `origin/main` + (a): 365 files read, **200** world reads, all
outside the door.

| subsystem | sites | by verb |
|---|---|---|
| behind `Host` | 52 | `host.exists` 21 · `host.read` 14 · `host.is_dir` 8 · `host.list` 7 · `host.beneath` 2 |
| CLI plumbing (`cli/commands/shared.av`) | 42 | `exists` 13 · `is_dir` 6 · `env` 5 · `tool_from_env` 4 · `tool` 3 · `.outcome` 3 · one each of eight more |
| commands (the rest of `packages/cli`) | 47 | `dev.av` 17 · `fmt.av` 7 · `stage.av` 6 · `process.av` 5 · `test.av`, `idiom_baseline.av` 3 each · `refuses.av` 2 · four files with 1 |
| build (`build.av` 9, `db.av` 4, `whole.av` 1) | 14 | `avra_spawn_status` 5 · reads 6 · pid 2 · the link-word `avra_host_env` in `whole.av` 1 |
| compiler (elsewhere) | 11 | debug flags 6 · `embed` 3 (`testing/mod.av`) · `compiler/inputs.av` 2 |
| not inputs | 34 | clock 21 · the evaluator 8 · the store 5 |

Against the design's 172 (a verb grep, `agent-facts.md` §5): the Host-routed
counts agree line for line (14 / 21 / 7 / 8), as do `read_text` 11, `read_bytes` 5,
`is_dir` 17, `list_dir` 3, `stamp` 2, `tool` 10, `tool_from_env` 5. The keeper
finds 28 more because it also counts `(host.beneath)(…)` 2, `embed` 3, `watch` 1,
`directory` 2, `compile_slot` 1, `argv` 1, pid 2, `avra_exec_self` 2,
`avra_self_dir` 1, `avra_ffi_open` 2, `avra_fd_read` 1, an aliased `env` 1, a
child spawned by `.outcome()` 8, and `minimal()` 1 (it reads `HOME`, `TMPDIR`,
`TERM` and `PATH`).

The door is one FILE, `compiler/host/host.av`: a read in `manifest.av` beside it
is outside. A spawn is `@std/process`'s `.run()`, `.outcome(…)` or `.start(…)`
in a file that imports `cmd`, `Command`, `Tool`, `Pipeline` or `Runner`. A name
of a world package classed pure is held to that package's source: a free fn
that reaches a world row or a counted name, itself or through the package's
free fns, is refused.

What the keeper does not see, by design or by limit:

- writes (`write_text`, `host.write`, `make_dirs`, `remove`): not reads;
- `host.cwd`, `host.std_root`, `host.compiler`: fields, read 2 times outside the
  door — d makes them inputs (`AVRA_CWD` enters as an argument, A18);
- a world verb reached through a wrapper in another module (`read_or_die`): the
  wrapper's own call is the site;
- a verb named inside a string, or after a `//` that follows code without a
  space, is counted; a string holding ` // ` hides the rest of its line;
- a `Host` held under another name (`let h = ws.host`, a `disk: Host` seat) and a
  `Host` fn handed over as a value (`ws.host.exists`);
- a spawning method in a file that imports no name of `@std/process`;
- a pure fn that reaches the world only through a METHOD;
- `tests/`, and every package but `std-avrac` and `cli`.

## What a workspace that lives across turns sees

A cell stands until the driver says the world may have moved (`world_moved`, or
`inputs_this_turn` for the whole turn). Then every input read so far is read
again, and the KIND of what differed decides:

| what differed | answer | why |
|---|---|---|
| a file's text | `Reread` — the revision moves, and the source and scans over that text follow | the kernel re-derives what read it |
| what stands, or what a directory lists | `Graph` — the workspace is let go and another opened | `module_files` and the file-to-module map are memos, not queries, and a deleted file keeps its id: the file set cannot be patched in place (`avra-8sb5.57.229`) |
| a manifest's text | `Graph` | the package list is append-only and its voices are spoken once; its kind is Text, so its loader marks the cell (`manifest_texts`) |

A one-shot `check`, `build` or `test` never calls the verb. A query that calls
it is refused, and so is a workspace asked again after `Graph`.

## The cut for b–e

Each PR ends with `make inputs-accept`; the baseline falls by the count in its row.

| PR | what moves | files | removes | leaves |
|---|---|---|---|---|
| **b** | `Host.text(path) -> Read` lands as the door's first verb, over the fields `Host` already has. The `Source` and `Manifest` loaders read through it and the kernel cell is cut by one word of the input's digest. `compiler/inputs.av` (`@input file_text` / `env_value`) is deleted; findings reads `host.text` | `host/host.av`, `host/input.av`, `workspace.av` (the Source loader), `packages.av` (the Manifest loader), `findings.av`, `derive.av` (one call), `compiler/inputs.av` (deleted) | 4 | 196 |
| **c1** | the general cell — `Family.Input` over an interned `InputName` (`compiler/world.av`) — the door verbs `there`, `listing`, `spared_text`, and `world_moved`. Every read made INSIDE A QUERY and recorded by nothing moves onto a cell; each scan of a sibling's text is a query over that text's cell. At this commit a long-lived workspace sees an edited listing, existence or scanned text after `world_moved`, and does NOT yet see an edited source or manifest | `modules.av` 6, `packages.av` 4, `voices.av` 3, `workspace.av` 1, `whole.av` 1 | 15 | 181 |
| **c2a** | one Text cell a file: a source is a query over its text's input, a manifest's row loads over it, and `Host.peek` is the one whole-file read that never ends a run (`Host.text`'s two questions are gone). `world_moved` is one loop: a TEXT that differs moves the revision; the SET of files that differs (an Exists or a Listing) or a manifest's text answers `Moved.Graph`, and the driver lets the workspace go and opens another (`inputs_this_turn`). From this commit `avra dev` sees every edit | `world.av`, `workspace.av` (`source`), `packages.av` (`loaded_manifest`), `host/host.av`, `cli/commands/dev.av`, `cli/commands/shared.av` | 0 | 181 |
| **c2b** | the driver's reads behind `Host`, the manifest re-reads in `build.av` and `manifest_source`. A driver read that must see the disk as it is NOW (a hold check, a kept record's validity, the store's roll) stays a direct read, licensed at its site and printed by the keeper as its own group | `suite.av` 11, `build.av` 10, `modules.av` 5, `record.av` 3, `whole.av` 2, `derive.av` 2, `packages.av` 1, `rule_proof.av` 1 | 35 | 146 |
| **c2c** | `embed` as a Text cell; `admit_embeds`' string match deleted | `testing/mod.av` 3, `whole.av`, `build.av` | 3 | 143 |
| **d** | env, tool, target, the compiler's identity: `Env`, `Tool`, `Compiler` reads; `Target` declared; the three `Host` fields become inputs | `cli/commands/shared.av` 42, `whole.av` (link words) 1 | 43 | 100 |
| **e** | the remaining direct sites by subsystem, and a `// LICENSED input.<why>:` line on each read that is no input | commands 47 · `build.av` 9, `db.av` 4 · debug flags 6 (licensed) · clock 21, evaluator 8, store 5 (licensed) | 100 | 0 |

Order is b, c1, c2a, c2b, c2c, d, e: c needs b's verb; d and e are independent of each other
once c is in. A read sent through the door while recording nothing would fall off
the keeper's count without becoming an input, so a site moves only with its cell.

Open for whoever takes b:

- `digest_bytes` reads eight `Bytes.at` calls a word; the text path has a row
  (`avra_str_word_at`). Measure a cold `check packages/cli` before and after b;
  if the door costs, the SHA-256 row (`.57.217`) is the fix, not a second path.
- A name is `package:relative/path`. Today's reads carry host paths; b needs the
  one fn that spells a path as its package's name (L5, DB 03).
- Package C run at const settlement (A18's last row) stays open under e.
