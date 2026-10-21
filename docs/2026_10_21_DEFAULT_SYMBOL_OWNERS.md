# Parameter defaults inherit their declaration owner's symbol

Task `avra-8sb5.11.390`; the commit adding this receipt is the fix head.

Private functions named `record` in two graph test files had different
defaults for their `model` parameter. Each file passed separately; together
nine extraction cases failed with the other file's model name. The minimal
`default_owner_functions` package reproduces the defect without the graph:
two sibling files' private `pick` functions should print `alpha beta`, but
the previous compiler evaluated `beta beta` (exit 1).

`Decls.symbol` now derives a default's symbol from its actual parent DeclId,
including private-file isolation and method keys. `apart_here` follows that
same ownership. No helper was renamed to hide the collision, no defaults
were copied to call sites, and no cache was removed to manufacture a pass.

Verification:

- Remote `avra-ux2` rebuilt compiler source
  `f96e57af243ffa4a75cd622040f386d0b0ea31a68454c2d2940c6798c50452c6`;
  binary prefix `40a93aa1ace9`.
- Full function suite: 826/826 tests, 19 ordinary proof programs, four
  package proof programs (including the new sibling-file case), and one
  refusal proof. All interpreter/native expected outputs agree.
- Graph: 185/185 tests, two interpreter/native proofs, baseline check exit 0.
- Remote run exit 0 in 785 seconds; available memory never below 950 MB.
- Native Mac rebuild under the unchanged 3500 MB guard: peak 3209 MB;
  binary SHA-256
  `42eccc310074d3488372ed5eb55e1ac95c36da1c8c30fa9e1c8ec64cf3da7ec7`.
  Predecessor retained in `build/graph-compiler-before-default-owners.B4ziuN/`.
- Native minimal proof, full graph, isolated consumer baseline checks,
  CLI/HTTP smoke, durability, personal app tests and native startup all pass.
  Logs: `build/graph-l01-local.log`, `build/graph-l01-native.log`.

The combined CLI task gate exceeded the task tool's fixed ten-minute
command timeout, so the remote success alone did not mark it verified.
The same coverage is being re-run as two independently bounded CLI gates;
the task remains open until those are verified. This is not a waived gate
or a claim that the compiler fix has landed on main.
