# Resuming UI work on the new pipeline (2026-11-16)

- Branch from GitHub `program` (avra-lang/avra), never `main`. `main` is the old compiler.
- Set no AVRA_PROGRAM / AVRA_PROGRAM_NET. The default is the new pipeline with the old check as a net.
- Build the compiler once: `make bootstrap`, then `make avra` twice. Iterate with `make try`.
- "program-layer false refusal" in a build = a compiler defect: report to the compiler lead; `AVRA_PROGRAM=0` for that one command.
- Proven on the new pipeline (1be8f5fe): `make ui-board` 77 claims, `make ui-browser` 89 claims (Firefox), std-ui 975/975, std-ui_gallery 38/38, std-ui_http 17/17. Needs WASI sysroot 25, binaryen, wabt, Firefox.
- Landing: work lands on `program` through the compiler lead (bundle or branch pushed to GitHub), not by PR to main.
- Stale UI PRs to rebase onto `program`, in order: #1332, #1328, #1308, #1314, #1138, #1116, #1129. Later: #1035, #1351, #1333, #1334.
- GitHub `program` is local `program`'s TREE as commits over main (local history holds a 101 MB binary GitHub refuses). Local sha ≠ GitHub sha; trees are equal.
