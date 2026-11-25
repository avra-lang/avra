# A warm build links an object compiled against a callee's OLD ownership convention

Found by parity-resolve-2 while bisecting cold cost. A census compiler (and a plain `make try`
product) built warm segfaults; the same commit built cold is clean.

## Repro (this machine, reproduced three times)
Builder: gen-2 of 1e177af8 (any recent compiler should do). The machine store is on, as by default.
1. A tree with a fresh package store: `find . -name .avra-cache -type d -prune -exec rm -rf {} +`.
2. `git checkout 89575bfa`; `make -s ready`; `AVRA_PROGRAM=1 AVRA_PROGRAM_NET=0 make try` → OK.
3. `git checkout 4f0bbd35` (89575bfa's parent); `make -s ready`; same `make try` → OK.
4. `build/avra-try check packages/std-program` (or `packages/cli`) over any clean tree, store off:
   **SIGSEGV, exit 139.**

Controls:
- 4f0bbd35 built cold (`AVRA_MACHINE_STORE=0`, a fresh `AVRA_CACHE_DIR`) is clean.
- 4f0bbd35 built with a fresh package store but a warm machine store (4 s, everything from the
  machine store, after the cold build) is clean.
- a1ef323f → 4f0bbd35 in one fresh isolated store is clean. The order that breaks is CHILD → PARENT,
  where the callee's convention flips between the two trees.
- The census build (`tools/census_compiler.sh`, `AVRA_INLINE_RUNTIME=0`) breaks the same way with
  steps 2–3 swapped for `sh tools/census_compiler.sh <out>`.

## What the bad binary does
- No guard: SIGSEGV in `strlen` ← `map_index_rebuild` ← `avra_map_slot` ← `QueryEngine.definition_of`
  ← … ← `law_findings.file_erring`. A map key, a freed string, is read.
- `AVRA_RC_GUARD=1` (census runtime): "released an already-dead box (len 2)" from
  `law_findings_compute`, at the release after its call of `law_findings$body`. The box is
  law_findings' `file` argument (a SourceFileAddress record), on the FIRST law_findings call.
- A gdb watchpoint on that record's rc (int32 at payload−8), compared with the same run under a
  clean binary of 89575bfa: one event differs. Inside `grammar_holes_unread` (the
  `grammar_hole_read_as_text` law's reader, which 4f0bbd35 adds) the sequence is +1 (`Signing { …,
  file: file }` retains), −1 (the record freed, cascading), then **−1 `avra_rc_release2` from
  `grammar_holes_unread`**: the body's end-of-scope release of its parameters.

## Why
- At 4f0bbd35, whole-program IR (`avra ir packages/cli`) lowers `grammar_holes_unread(r0, r1, r2)`
  as OWNING its parameters: it ends `release r1; release r0`. Its fn-value wrapper
  `grammar_holes_unread$w` retains both before the call, and `read_whole` calls the law through the
  closure, so the whole-program IR balances.
- At 89575bfa the same fn (rewritten to `signing_in(...)`) BORROWS them: no end release and no
  wrapper retain.
- The warm binary runs the 4f0bbd35 body, which releases its parameters, but the retain its wrapper
  owes never runs. The object for the wrapper or its caller (the law table / `read_whole` unit) was
  reused from the 89575bfa build. So an object's store key does not cover its callee's
  parameter-ownership convention: a callee whose convention flips leaves its callers' objects
  standing.

## Worth checking
- The key an emitted unit is reused under: does it fold each callee's ownership signature (or the
  `$w` wrapper's own body), not only the callee's interface or face?
- Shipping builds inline the runtime, so a double release there is silent corruption, not a guarded
  abort: here it shows as the same segfault.
