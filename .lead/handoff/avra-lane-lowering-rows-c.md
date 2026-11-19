# avra-lane-lowering-rows-c — hand-over
Branch `avra-lane-lowering-rows-c`, head = the commit adding this file (parent 3ac6da2c), on next-base cd4738e6 (trunk cf1b3e2c in it).
DONE, handed back (landed or in batches): rows 1–8, carried fields (`composers` in compiler/item_signatures.av),
Lambda/event holders, range place fix, package_rule/crossing/sublang-sql, closures/trailing (lambda mut seat),
operand law bundle 1 (avra-lane-lowering-rows-c-operands.bundle: 6f2f46af, d6a860a1).
IN PROGRESS, committed, NOT handed back (in this final bundle):
- 0065faff comparison law (==/!=: mismatched, by value with per-shape help, `== null` unasked, null==null);
  shared voices features/checks.av `uncompared`/`compare_help(Offered)`, expr_spine/check.av
  `sides_unmatched`/`null_unasked`/`always_absent`; core `Uncompared`, `Offered`, Seating.Compared; 4 laws.
- 3ac6da2c two_names (Seating.TwoNames, law `named_operands`, voice `two_named`); a name beside a third
  type now meets the operator law.
- State: builds (AVRA_PROGRAM=1 make try 0); 16 witnesses old == new byte-identical; suite cases compare_*,
  operand_two_names, compare_two_names, operand_name_other, builds_comparisons all hold; --findings 0 errors
  on cli, std-avrac, std-program, std-relation, std-http; cli self-build 0. NOT YET RUN on it: full refusal
  suite, std-avrac --ran, idioms, sound. Next: `sh /tmp/.../opreceipts.sh` equivalents: suite, `tapes
  packages/std-avrac --ran`, old-path `check --baseline tools/idioms.baseline` for cli + std-avrac.
NOT DONE: mixed_with_shape (named beside its bare shape) — waits for decl-shape's `fixes` on Found to carry
  `fix (high): write Name(value)`; currently silent (returns untyped). Claimed but not started: type.return,
  type.method (differential UNBUILT rows).
Findings: old-path defect — a range held in a `let` and walked → language.defect (recorded by lead).
Don't touch without asking: features/expr_spine/checks.av operands/compared/names_clash, item_refused.av
  operand/comparison/named laws.
