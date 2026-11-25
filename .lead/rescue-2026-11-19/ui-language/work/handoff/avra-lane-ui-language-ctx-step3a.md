# ctx step 3, part a: capture (S2a, cd6ed6e7 on R2 e398cfa2)

`/work/avra-lane-ui-language-ctx-S2a.bundle` = `avra-lane-ui-language-ctx-r2..avra-lane-ui-language-ctx-s2`.

## What it does
- A lambda whose body reads a context carries the frame current where it is made in its box's first
  lane, and its body enters it. The check is inline: a load of lane 1, a FlagRead of the frame word,
  a compare, and a call to avra_ctx_enter only where they differ. The body's own endings frame takes
  it back (`Ending.Entered`) by every way out.
- A task its block owns is such a lambda, so it starts under its spawn's frame.
- **Which lambdas:** the program's step-2 survey over pass A (bodies lowered with nothing framed) marks
  each lift whose body reads a context. A body making one is asked as
  `BodyAsked.Framed(asked, framed)`: for fns, methods and the entry, `lowered_under` /
  `lowered_method_under` / the entry take `framed` in their key. `met_for` attaches the framed set to
  the unit in the walk; the query is `program_framing(package)`. A program declaring no context stops
  at that check.
- **FlagRead** is generalized by width. `RtFlag.Frame` is the word `avra_ctx_now`; `flag_layout` (bytes
  → Truth, Frame → Word) is what a read answers. LLVM uses an i8 test or an aligned i64 load, and the
  evaluator answers the frame handle. Every RtFlag consumer spells all three arms, and vocab's curated
  table has RtFlag (5 consumers).
- The evaluator arms the frame rows, and its `==` compares two box handles by identity.

## Zero cost, measured (`avra ir`, R2's compiler vs S2a's)

| Program | IR lines | Diff |
|---|---|---|
| a closures + spawn program | 213 | 0 |
| the terminal app fixture (std-ui) | 92,565 | 0 |
| the knob fixture (std-ui) | 18,575 | 0 |
| tools/ui-board | 72,137 | 0 |

A program that declares a context but has lambdas that read none: only the reading lambda and its
maker change. The non-reading lambda and its maker are byte-identical.

## Proofs and receipts
- New program captured.av, eval == native == expected:
  - a lambda made under `depth = 7` reads 7 when called under 3 and under 100;
  - one made with nothing set reads the default;
  - an owned spawn reads its spawner's 3;
  - the caller's frame stands after each.
- All 3 ctx programs proved; 10/10 ctx cases.
- ctx_frame_test 32; runtime-tests pass.
- std-ui 1022/1022 + 83; NET=0 cli exit 0.
- vocab passes. idioms std-ui 0; cli 0 of mine (5 NEW in memory.av/ir_text.av, batch48b's release rows,
  files this branch leaves as batch48 has them).
- fmt clean.

## Not yet (part b, next)
- F1: re-frame a reading handler's box at placement, where the frame differs.
- F2: the standing keeps its drawn frame for a lone repaint.
- F3: a set's value read under paint tracking.
- The walk entering an instance's made frame.
- Framing of lambdas in field/seat defaults, trait statics and the other lowering kinds. Those still run
  under the caller's frame.
