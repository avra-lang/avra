# DB 07e — delete the hold (settle_holds)

Base: `origin/main` @ `3896b7c1`. Worktree `../avra-db-07e-hold`, branch `db-07e-hold`,
Sprite `avra-ux3`. Head `a9c265ee` (draft, not pushed, not landable).

## The branch I was handed

`origin/db-07e-producers` @ `36842105` (31 commits) and `origin/db07e-keyfix` @ `2bb3bfad`
are ALL landed or superseded — none needed. Merge-base `7f47f3a2`; every commit is 07a
(`#832 e1116e22`) or 07d/S4b/S4c (`#857 754c828c`) work, evolved by `#869`/`#1031`.
The tip's producer row IS main's `compiler/producers.av` (518 lines against the branch's
238; main's `Producers` is a superset: implementors, refs, narrows, typed, reach_refs,
seen, forms, forms_text, files). `hooks_released.py`, `gathered_attack`, `impl_held_attack`
and cache-attacks' `hh` are all on main. `db07e-keyfix` is a doc-only DB 00d finding.

## Measurement (Sprite, one machine, one variable)

`build/avra.clean` = main's source, 2 gens, sha `21a086c1`. `tools/cache_attacks.sh`:
**502 builds, 159 under a hold, 0 failed.**

| shape | result |
|---|---|
| `settle_holds` deleted outright | **8 failed** — kr, kv, tw, pk, gi, vd, hc, drm |
| mark held after the read set, run closure asked of the held set | **1 failed** — "a sibling's answer type moves, its caller unedited" (holds 13/19 where main holds 12/19; native prints the old int, eval prints `three`) |

The 8 are the read law: a file a read file's compile-time runs reach must be READ, and the
held mark must not be written before its reader is known. Moving the mark late fixes 7 of 8
and is the useful finding; the eighth is history-dependent (passes with
`CACHE_ATTACKS=a`, fails only after the earlier sections have filled the store).

## What 07e still needs

`settle_holds` carries two laws 07d did not move: `resolve_pending_reads`'s reader forcing
(still needed — `unruled` calls it too) and the TRANSITIVE compile-time-run closure over
files this attempt reads. That closure must live in the by-name walk (or in `read_why`)
before the function can go. Its listed prerequisites (S2/S3/S5) are not the blocker.

## Compiler note

`sh tools/work compiler` picks a binary 2 compiler commits behind, which the pre-commit
hook refuses. The depot's `3896b7c1` build (`cdadba1d…`) is current; install it by hand
from `~/.cache/avra/compilers/cdadba1d…`.
