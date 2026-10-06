# DB 04 — the input door: what (a) landed, and the cut for b–e

Law L1 (`2026_10_06_COMPILER_DB.md` §5.2, A3, A18): every read of the world is a
named, digested input through one door. Ticket `avra-8sb5.57.173`.

## What (a) landed

| piece | where | what it is |
|---|---|---|
| the row | `packages/std-avrac/src/compiler/host/input.av` | `Read` — one variant per kind, carrying the name and what was seen; `Read.input()` answers `Input { name, digest }` |
| its tests | `compiler/tests/input_door_test.av` | 31 cases, nothing-there first |
| the keeper | `tools/inputs.py`, `tools/inputs.baseline`, `make inputs`, `make inputs-accept` | counts world reads outside `compiler/host/`; a site the baseline does not list is refused |

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

`make inputs` on `origin/main` + (a): 365 files read, **192** world reads, all
outside the door.

| subsystem | sites | by verb |
|---|---|---|
| behind `Host` | 52 | `host.exists` 21 · `host.read` 14 · `host.is_dir` 8 · `host.list` 7 · `host.beneath` 2 |
| CLI plumbing (`cli/commands/shared.av`) | 39 | `exists` 13 · `is_dir` 6 · `env` 5 · `tool_from_env` 4 · `tool` 3 · one each of seven more |
| commands (the rest of `packages/cli`) | 42 | `dev.av` 16 · `fmt.av` 7 · `process.av` 5 · `test.av`, `stage.av`, `idiom_baseline.av` 3 each · five files with 1 |
| build (`build.av` 9, `db.av` 4, `whole.av` 1) | 14 | `avra_spawn_status` 5 · reads 6 · pid 2 · the link-word `avra_host_env` in `whole.av` 1 |
| compiler (elsewhere) | 11 | debug flags 6 · `embed` 3 (`testing/mod.av`) · `compiler/inputs.av` 2 |
| not inputs | 34 | clock 21 · the evaluator 8 · the store 5 |

Against the design's 172 (a verb grep, `agent-facts.md` §5): the Host-routed
counts agree line for line (14 / 21 / 7 / 8), as do `read_text` 11, `read_bytes` 5,
`is_dir` 17, `list_dir` 3, `stamp` 2, `tool` 10, `tool_from_env` 5. The keeper
finds 20 more because it also counts `(host.beneath)(…)` 2, `embed` 3, `watch` 1,
`directory` 2, `compile_slot` 1, `argv` 1, pid 2, `avra_exec_self` 2,
`avra_self_dir` 1, `avra_ffi_open` 2, `avra_fd_read` 1, and an aliased `env` 1.

What the keeper does not see, by design or by limit:

- writes (`write_text`, `host.write`, `make_dirs`, `remove`): not reads;
- `host.cwd`, `host.std_root`, `host.compiler`: fields, read 2 times outside the
  door — d makes them inputs (`AVRA_CWD` enters as an argument, A18);
- a world verb reached through a wrapper in another module (`read_or_die`): the
  wrapper's own call is the site;
- `tests/`, and every package but `std-avrac` and `cli`.

## The cut for b–e

Each PR ends with `make inputs-accept`; the baseline falls by the count in its row.

| PR | what moves | files | removes | leaves |
|---|---|---|---|---|
| **b** | `Host.input(name) -> Input` lands as the door's verb. `Source` and `Manifest` are read through it; the kernel's `set_input` takes the input's digest. `compiler/inputs.av`'s `@input file_text` / `env_value` are folded in or deleted (its `read_text(path) catch ""` reads absent as empty) | `workspace.av` (:1050), `packages.av` (3), `build.av` (:642), `compiler/inputs.av` (2), `host/host.av`, `cli/commands/shared.av` (the `Host` literal) | 7 | 185 |
| **c** | the rest behind `Host`: `exists`, `is_dir`, `list`, `beneath`, the remaining `read`s; `embed` as `Text`; `admit_embeds`' string match deleted; the four unrecorded reads of `avra-8sb5.57.184` | `modules.av` 11, `suite.av` 11, `build.av` 9, `packages.av` 3, `voices.av` 3, `record.av` 3, `whole.av` 3, `derive.av` 2, `workspace.av` 1, `rule_proof.av` 1, `testing/mod.av` 3 | 50 | 135 |
| **d** | env, tool, target, the compiler's identity: `Env`, `Tool`, `Compiler` reads; `Target` declared; the three `Host` fields become inputs | `cli/commands/shared.av` 39, `whole.av` (link words) 1 | 40 | 95 |
| **e** | the remaining direct sites by subsystem, and a `// LICENSED input.<why>:` line on each read that is no input | commands 42 · `build.av` 9, `db.av` 4 · debug flags 6 (licensed) · clock 21, evaluator 8, store 5 (licensed) | 95 | 0 |

Order is b, c, d, e: c needs b's verb; d and e are independent of each other
once c is in. b touches `workspace.av` and `packages.av`, which other lanes
hold today — it waits for them or takes the lead's leave.

Open for whoever takes b:

- `digest_bytes` reads eight `Bytes.at` calls a word; the text path has a row
  (`avra_str_word_at`). Measure a cold `check packages/cli` before and after b;
  if the door costs, the SHA-256 row (`.57.217`) is the fix, not a second path.
- A name is `package:relative/path`. Today's reads carry host paths; b needs the
  one fn that spells a path as its package's name (L5, DB 03).
- Package C run at const settlement (A18's last row) stays open under e.
