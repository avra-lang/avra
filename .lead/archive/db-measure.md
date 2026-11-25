# db-measure handoff (2026-10-08)

Worktree: /Users/tristan/projects/tristanMatthias/avra-db-said, on branch link-lld.
Sprite: avra-comptime, bound to this worktree (binding file: $(git rev-parse --absolute-git-dir)/avra-sprite reads `avra-comptime`).

## Branches (all pushed)
- link-lld @ e69b80e: off origin/main 70e45d5; NO PR (parked until #411 merges). Toolchain.ld; link_objects passes `--ld-path=<ld.lld>` on a host ELF link; cli `host_toolchain`/`elf_lld` in commands/shared.av, used by build and test.
- Open PRs from me (lead lands): #418 make-lighter @ 90afec3, #420 keepers-pr @ 1ce836d, #422 diagnostics-no-totals @ 9a0415e.

## Next step (ticket avra-8sb5.57.257, linker half)
1. Wait for #411 (db-inputs-d2) to merge, then `git rebase origin/main` on link-lld.
2. The change after #411: in shared.av `toolchain()`'s host branch:
     let ld = if links_with_ld64() { null } else { ws.tool(joined_path(dir_of(host.path), "ld.lld")) }
     Toolchain { opt: "-O1", runtime: runtime_library(), linker: host.path, tools: [host].concat(some_list(ld)), ld: ld?.path ?? "" }
   Delete link-lld's host_toolchain/elf_lld; test.av uses #411's toolchain(ws, …).
3. Owed: byte-identical witness. tools/db_measure/lld_witness.sh (untracked) FAILED twice to find the binary.
   Fix: the binary of `./avra build $D` is $D/src/main (the build's LAST stdout line is the shim's `watch:` line, not the path).
   Want: two clean builds cmp-identical; readelf .comment says LLD; build id present.
4. Receipt so far (on .57.257): the cli link 1.69 s (GNU ld) -> 0.20 s (lld); one-leaf `make try` 6.6 -> 6.1 s.

## Traps
- NEVER type a commit hash from memory; copy it from git output (I sent wrong hashes 4 times).
- `work run` builds the compiler twice and its `make avra` builds packages/cli, so a following cli build is a CACHE HIT; move .avra-cache aside for a cold number.
- In one Sprite run, two builds with the IDENTICAL edit text hit the cache; use a unique edit (date +%s%N).
- Linux make 4 prints `target: .SHELLSTATUS := 0` in `make -p`; read rule lines with `^target:[^=]*$`.
- Mac is make 3.81 (no $(file), second-granularity mtimes).
- No whole suites on Sprites (owner cost rule); targeted tests + keepers-b only; whole suites run on the PR's GitHub check.
- Untracked probes live in tools/db_measure/ (kg_probe, link_probe, lld_receipt, make_receipt, lld_witness, Makefile.main). Don't commit them.
