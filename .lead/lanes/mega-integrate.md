# mega-integrate lane

- ROOT CAUSE: #677 guess. `edit_print` keys a guess by the MOVED-FILE SET alone.
  The spin->park check read mid.av (its key moved under the attempt) and stored
  that read in the guess; the park->park edit moves the same files with no key
  move, reuses the guess, and force-reads mid. Key never moved (check --time
  showed attempt 0). Only cancel_cache collided; cancel_bits/cw/bw passed.
- REAL, not stale: the cancel law holds; the guess masked it.
- FIX: `guessable(r)` — a read whose reason is `Adrift` may not join a guess; the
  next edit's own hold judges the key it actually wears. Every other read stands.
- RECEIPTS (final formatted source, compiler rebuilt):
  make idioms    exit 0 — no new violations, 42 packages
  make cache-attacks exit 0 — 0 FAIL (cancel_cache 11 steps 0 failed,
                 cancel-bits 14 steps 0 failed)
  gate_changed --files derive.av --packages std-avrac --no-keepers: clean
- PUSHED: f722f6e6 (origin/mega-integrate 94a45d9a..f722f6e6, one push)
