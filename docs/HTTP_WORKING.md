# HTTP working state

- Worktree: `/Users/tristan/projects/tristanMatthias/avra-lane-http`; branch `lane/http`; base `85e6344`.
- Mandate: build idiomatic, minimal, fast client/server HTTP; build missing foundations; small modules. Continue autonomously. No commits requested.
- Design: `2026_09_06_STD_HTTP_DESIGN.md`, `2026_09_06_STD_HTTP_TYPED_ROUTES.md`. Product questions answered.
- Required per implementation slice: `.claude/skills/red-team/SKILL.md`, then `review-round/SKILL.md`; watchdog for heavy commands, one at a time.
- Saved conversation recovered; original session writer-lock issue does not block this worktree. Only design docs changed so far.

## Active slice

- Implement managed `Bytes` in compiler/runtime, then owned byte views; prerequisite for HTTP framing and typed routes.
- Existing proposals: `2026_09_05_BYTES_SHAPE.md`, `2026_09_05_BYTES_RUNTIME_DIFF.md`; read as proposals, not applied patches.
- Current compiler: bootstrapped at this base. `Bytes`, typed string captures, scalar newtype/refinement spelling absent. Nominal record IDs work (probes recorded in typed-route doc).
- Inspected seams: `core/types.av`, `core/runtime_api.av`, `core/ir.av`; `language/interp.av`, `typing.av`, `memory.av`; `features/str_lit/`, `features/values.av`.
- Next: add a separate bytes feature, managed type, runtime rows and interpreter implementation; bounded access, binary equality, constructor validation, explicit copy versus retained slice.
- Watch representation: header length is uint32; checked sizes required. View must retain its root; empty slices must not pin it. No interior pointer masquerading as a string.
- Runtime proposal needs correction before use: `sized_box` does not write a terminator; constructors must. Its proposed slice clamps silently; settle explicit bounds behavior instead.
- Implemented draft (not yet compiling): `Type.Bytes`, method feature `features/bytes/`, runtime `runtime/avra_bytes.inc`, owned view reclaim, eight runtime rows, independent interpreter `language/interp_bytes.av`.
- Surface: `string.bytes() -> Bytes`, `List<int>.bytes() -> Bytes?`, `.at(i) -> int` (bounds trap), `.slice(lo,hi) -> Bytes?` (strict), `.copy()`, `.concat()`, `.length`, `.is_empty()`, value equality.
- `corpus/bytes.av` + `.expected` added FIRST; witnessed failure on old compiler (missing type/methods).
- In flight: watchdog package check, output `/tmp/avra-http-bytes-check.log`. Then fix diagnostics, build compiler, run corpus, add adversarial/lifetime tests; red-team and review/gate remain undone.
- Check next: exhaustive Type/Val consumers; feature assembly counts; extern keeper must discover split runtime include; centralize third emptiness-lowering copy during review.

## Latest completed

- Recovery: five ID probes, check/run/build; one accepted control prints `42` in both engines. Four refusals each emit exactly one expected diagnostic. Temporary fixtures removed.
