# HANDOFF — wisp lane (2026-11-25 11:44)

Goal: internal tooling into `wisp` (docs/2026_11_25_WISP.md, inventory docs/2026_11_25_WISP_INVENTORY.md).
Base: origin/program e02d71ab (branch already on it; no rebase needed).
Worktree: ../avra-wisp, branch wisp/design.

## Done (committed)
S1 rename, S3 oracle, S4 keepers registry, keepers-green, `wisp cost`, and avra-8sb5.102.3:
- 0d9453f17f / 387752ae30 (Rung: generator gains `type` entry, parser regenerated from run 45579625250, program.av still engine-side)
- 0f5afd3e29 parse_type_ref reads the generated parser; fallback gone.
Parser file = exact bytes run 45579625250 built (all steps "held").

## Half-done
Runner-green of HEAD: run 45605678435 (`work run --builder bash wisp-run.sh`) FAILED at the PREP compiler build
(before my script): type.host_seat `avra_cell_bytes_run` Cell<Bytes>, type.quote_pat_subj, annotation.said TinyNode.octets.
Likely the prep ladder from the `Rung:` trailer, or the builder key, building with a compiler that can't read this tree
(Bytes/Cell rows = a ladder law case). Not diagnosed. wisp-run.sh + rung_program.av are untracked helpers (committed on handoff branch only).

## Next
1. Read run 45605678435 log: which compiler/tree did prep build? Retry with `--builder` dropped or the Rung trailer adjusted.
2. Once green: push wisp/design, SendMessage lead sha + summary; Rung commit = 387752ae30.
3. Merge sweep verb by verb; keep "Deleted as obsolete" list. S2 waits on targets' P2.

Runs in flight: none.
