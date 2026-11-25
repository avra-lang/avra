# spread-impl status

- #901 (spread-1): rebased on main (past #933/#936/#955), remedy rows added, pushed e09a43f6. Priority landing.
- #902 (spread-extend): draft; landing 2 (arm + one-allocation list lowering) after the seed refresh.
- PR branches, pushed, stacked, NO PRs opened (open each when its base lands; rebase onto main then):
  1. spread-literals (on spread-1): list spread + map spread; remedy rows; docs regenerated.
  2. spread-patterns (on spread-literals): list/record patterns, `is`, destructuring `let` as a LetPattern node (means door, no mark), `destructure` grammar seam; docs regenerated.
  3. spread-calls (on spread-patterns): variadic seat, `f(..opts)` into named seats, spread field pins a type parameter; remedy row for type.spread_seat; docs regenerated.
- Each branch: affected feature dirs green locally, fmt clean (literals unchecked: run `fmt --check` on open), idioms ok (patterns), voices baseline clean. The tip bootstraps from the seed (gen-1, gen-2).
- Local-only branch spread-stack is the whole linear stack; spread-4 / spread-2 / spread-3 / spread-extend2 are stale and can be deleted.
