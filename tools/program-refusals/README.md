# The program layer's refusal suite

Each directory here is a package of its own, one case: a source the program layer must refuse
in the old path's words, or must build. `sh tools/witness_program_refusal.sh` judges them all;
its head says what each file means. In short:

- `refuses.expected`: the old path's `avra check` words, its warnings aside, paths as `<case>`.
  Both the old `check` and `avra build` exit 1 saying exactly this.
- `prints.expected`: what the product prints. The old `check` exits 0, the program layer builds
  the package, and its binary prints exactly this.
- `differs.why`: the paths are known to differ here, for the reason on its first line. The case
  is said and not failed while it differs, and fails once it holds until the file goes.
  `sh tools/witness_program_refusal.sh --known` lists them.

A new case is a directory with `avra.toml` and `src/main.av`; `PIN=1 sh
tools/witness_program_refusal.sh build/avra-try <case>` gives it the old path's expectation.

WHY HERE AND NOT UNDER A PACKAGE'S `src/`: `avra test` builds every package nested under a
package's sources as a suite of its own (`nested_roots` in compiler/suite.av), so a case that must
be refused would fail that package's tests. Under `tools/` no suite reaches them, as with
`tools/wasm-refuses/`.
