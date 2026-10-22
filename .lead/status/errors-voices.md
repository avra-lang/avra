# errors-voices status (2026-10-17)

- #891 land-voices-2: rebased onto origin/main 83395deb (one conflict, docs/VOICES.md, took main's side). Not pushed yet.
- Next: `make try` on avra-comptime (running), then regenerate DIAGNOSTICS.md, VOICES.md, baseline; fmt; push.
- #895 land-errors-2: after #891.
- If make try is OOM-killed on avra-comptime: need a bigger Sprite.

## update
- #891 pushed (rebased, docs regenerated, baseline holds at 187). BLOCKED on checks only.
- #895 merged with main (fdd1c5b9) and pushed; docs NOT regenerated: tree compiler build on avra-comptime
  exceeded 2400s (the #891 tree built in 399s). Not a memory problem; needs CI's verdict or a look at why the build hangs.
