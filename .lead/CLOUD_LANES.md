# Cloud lanes — how we use Claude Code web sandboxes

One lane = one cloud session = one sandbox = one branch. The lead (local Mac session) coordinates through the
`claude-web` bridge (`../claude_web_mcp`, README there is the tool reference).

## Names — one id everywhere

The bridge makes the name: `create_session {project: "avra", kind: "lane"|"ops", topic}` -> `avra-lane-<topic>`
(a taken name gets `-2`, `-3`). It sets the title and tells the agent its branch and file stem; nobody types a name.

| Where | Spelling |
|---|---|
| Cloud session title | `avra-lane-<topic>` |
| Git branch | `avra-lane-<topic>` |
| Bundle a lane hands back | `avra-lane-<topic>.bundle` |
| Lane note | `.lead/handoff/avra-lane-<topic>.md` |
| Non-lane sessions (builds, probes) | `avra-ops-<what>` |

## What a sandbox is

- Environment **Avra 2**: Ubuntu 24.04, 4 cores, 15 GB, no swap, 30 GB disk, ~2 min to start.
- Setup script leaves: LLVM 22, a built Linux compiler in `/opt/avra-tc`, the source at `/work/avra`
  (artifact `avra-work.tar.gz`: a shallow clone of `program` and open lane branches, ~150 MB — keep it small, a 290 MB download failed), lead notes at `/work/lead`, the bridge runner started.
- Suspended ~9 min after its agent's turn ends; disk survives, processes do not. A lane keeps its turn open
  while a job runs; the bridge hook restarts the runner on resume.
- No shared pool, no shared disk: a lane may run the whole gate by itself.

## The loop

1. Lead: `create_session` in "Avra 2" with `project`, `topic` and the brief (goal, files,
   what is ruled out, checks to run, how to report).
2. Lane: `cd /work/avra && git checkout -b avra-lane-<topic> program`, build with `AVRA_PROGRAM=1 make try`
   (~1.5 min), work, commit as it goes.
3. Lane self-gates in its sandbox: new-path `make try`, its own tests, `tapes --built`, the suites it touched,
   `tools/witness_program_edit.sh`. Reports exact counts with `post_to_controller`.
4. Lane hands back: `git bundle create /work/avra-lane-<topic>.bundle program..avra-lane-<topic>` and sends
   it (`send_files`). Nothing is pushed to GitHub.
5. Lead: fetch the bundle into `../avra-ho-land`, merge, run the Mac gate once per batch, move `program`,
   refresh the `avra-work.tar.gz` artifact (and the Linux compiler artifact when codegen moved).
6. Lane rebases onto the new `program` (fetch the artifact bundle) and takes its next item.

## Lead's direct door (no model in the loop)

`bun src/cli.ts exec <cse> [--cwd D --timeout S --wait S --bg] -- <cmd>` runs a command in a sandbox in ~1 s.
Use it for builds, gate runs and file pulls; use `send_message` only for judgement work.

## Rules

- Never push to main; lanes push nowhere. Hand-back is a bundle through the bridge.
- A lane touches only its own branch. Two lanes never own one file set — the brief names the files.
- Speed claims: exact counts plus `cmp` of products on one fixed source.
- Credentials in a sandbox's environment are never printed, posted or forwarded.
- The Mac gate is the bar for moving `program`; a cloud gate is the lane's own proof.

## Capacity

Each sandbox is its own machine, so lanes no longer compete for the Mac's memory or disk. The limit is the
lead's landing rate (one Mac gate per batch, merges serial), so lanes are cut by file ownership and landed in
batches.
