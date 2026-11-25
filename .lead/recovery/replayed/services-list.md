# Services series on the landed head: every refusal

Branch `services-s22-on-cbc4`, head 2b838ea2: commits 1–23 of services-s22 (as replayed on 90042ca7) rebased onto cbc437f4; the 24th, 4dbdbb67 (store_seam), dropped. Compiler: gen-2 built from this tree. Bundle: `/work/out/services-s22-on-cbc4.bundle` (requires cbc437f4).

## Rebase mechanics (the only edits made)

Only the 10th commit, bb7ce67d ("a letter's error defaults to text, so a text-failing letter is `Dead<Email>`"), conflicted, in exactly the 10 std-queue tests: drain_events_once, drain_letter_refuses, home_refuses, home_seam, run_asks_again, run_backoff, run_lease, run_trap, run_wakes, trap_ends. In every hunk the series changed only `Dead<X, string>` to `Dead<X>`, while the landed side had moved the counters to `state` (and restructured run_asks_again, run_wakes, run_backoff and home_seam). Resolution: the landed lines, with `Dead<X>` spelled the series' way. No `Dead<…, string>` and no top-level `let` Cell counter is left in either package's tests. Every other commit applied clean; nothing else changed.

## The list

| # | Source | What refuses | Where | Series or landed |
|---|---|---|---|---|
| 1 | std-queue_store suite | proof `durable_emails`: eval FAILED — "`avra_sqlite_sleeps_held` is extern and this image does not carry it" | packages/std-queue_store/src/tests/durable_emails | **landed**: plain cbc437f4 fails identically |
| 2 | std-queue_store suite | proof `in_tx_late`: eval FAILED, the same extern | packages/std-queue_store/src/tests/in_tx_late | **landed** (same) |
| 3 | std-queue_store suite | proof `store_seam`: eval FAILED, the same extern; the suite then STOPS ("the rest of the suite never ran") | packages/std-queue_store/src/tests/store_seam | **landed** (same) |
| 4 | `tapes --findings` std-queue_store | warning[lists.bool_comprehension_range]: a comprehension over a range folded to a bool — that is a scan, but a bare range has no `.all` to land on without first minting a list | packages/std-http/src/route.av:784:38 | a dependency's warning |
| 5 | `tapes --findings` std-queue_store | warning[type.coalesce_never]: `??` never fires — `int` is never absent | packages/std-http_message/src/message.av:104:118 | a dependency's warning |
| 6 | `tapes --findings` std-queue_store | warning[type.alias_copy]: `held` is a copy of `among` — a write through it will not reach `among` | packages/std-relation/src/db.av:1041:48 | a dependency's warning |
| 7 | `tapes --findings` std-queue_store | warning[type.alias_copy]: `todo` is a copy of `seeds` — a write through it will not reach `seeds` | packages/std-relation/src/db.av:1051:38 | a dependency's warning |
| 8 | `tapes --findings` std-queue_store | warning[nullable.nullable_flag_local]: a nullable flag local — is this scan a find/index_of? | packages/std-sqlite/src/open.av:474:9 | a dependency's warning |
| 9 | `tapes --findings` std-queue_store | warning[nullable.nullable_flag_local]: a nullable flag local — is this scan a find/index_of? | packages/std-sqlite/src/open.av:533:5 | a dependency's warning |
| 10 | `tapes --findings` std-queue_store | warning[nullable.nullable_flag_local]: a nullable flag local — is this scan a find/index_of? | packages/std-sqlite/src/stmt.av:117:9 | a dependency's warning |
| 11 | `tapes --findings` std-queue_store | warning[nullable.nullable_flag_local]: a nullable flag local — is this scan a find/index_of? | packages/std-sqlite/src/stmt.av:118:9 | a dependency's warning |
| 12 | `tapes --findings` std-queue_store | warning[nullable.nullable_flag_local]: a nullable flag local — is this scan a find/index_of? | packages/std-toml/src/toml.av:326:5 | a dependency's warning |
| 13 | `tapes --findings` std-queue_store | warning[compiler.seen_accumulator]: `mut out` accumulates what has been seen so a later turn can ask `out.contains(...)` — once the whole list it is scanning is already in hand, that is a POSITION law: `xs.index_of(x) < j`, over `enumerate` | packages/std-toml/src/toml.av:463:29 | a dependency's warning |

Rows 1–3: the symbol is defined in std-sqlite's C (`sqlite_sentinel.c`; build/sqlite_sentinel.o has it), but the compiler image that evaluates a suite's proofs carries no `avra_sqlite_*` symbol at all (`nm build/avra`), so a proof reaching std-sqlite's held sleep fails. Plain cbc437f4 is the same: 206/206 cases, then these three.

## Clean (said for completeness)

- std-queue suite: **54/54 pass**, exit 0.
- std-queue_store suite: **219/219 cases pass** (206 on cbc437f4); its exit 1 is rows 1–3.
- `tapes --findings` std-queue: **0** findings.
- `check packages/std-queue` and `check packages/std-queue_store`: **clean**, exit 0. Both answered from saved state in under 1 s; the cold run below is std-avrac's.
- `ctx.required`, `resolve.runtime_binding`, `instance_bound`: **0 hits** in every log here (suites, findings, checks, the cold check).
- No refusal anywhere carries budget words ("ran past its budget", "took more than N steps", const.budget).

## Cold `check packages/std-avrac` (AVRA_DEBUG=1)

Run with std-avrac's `.avra-cache` dirs removed, a fresh `AVRA_CACHE_DIR`, `AVRA_MACHINE_STORE=0`, on the default (program-layer) path. **Exit 0, 0 errors**, 345 warnings, 1 m 56 s. Warnings by kind:

| count | kind |
|---|---|
| 110 | warning[type.alias_copy] |
| 82 | warning[type.mut_fn_unused] |
| 44 | warning[type.receiver] |
| 22 | warning[type.registry_hole] |
| 14 | warning[type.seat_unused] |
| 14 | warning[compiler.free_state_verb] |
| 13 | warning[compiler.bracket_ritual] |
| 11 | warning[fns.dead_parameter] |
| 10 | warning[nullable.nullable_flag_local] |
| 6 | warning[compiler.seen_accumulator] |
| 5 | warning[type.coalesce_never] |
| 4 | warning[compiler.interned_opt] |
| 2 | warning[let_stmt.unmutated_mut] |
| 1 | warning[type.unreachable_arm] |
| 1 | warning[loops.push_loop] |
| 1 | warning[lists.bool_comprehension_range] |
| 1 | warning[compiler.raw_rt_call_void] |
| 1 | warning[compiler.raw_rt_call] |
| 1 | warning[compiler.raw_mint_emit_const_int] |
| 1 | warning[compiler.interned_list] |
| 1 | warning[closures.pronoun_lambda] |

## Derive steps (the `settle:` instrument)

The program layer DOES carry the instrument: **2,924 `settle:` lines** (617 distinct names). But a codec derive prints under the derive fn's own name, `@std/relation/src/relation.av.codec`, never the type it runs on: **128 codec runs** for **42** `@codec` annotations in std-avrac (not 43; TypeFacts is one; no `@codec` type named Ins was found). So the runs **cannot be named TypeFacts or Ins** from this log. That naming gap is a finding of its own.

Budgets: steps default 600,000 (features/worklist.av `default_steps`); memory default 5 MiB (`default_memory_mib`), and std-avrac's own `[lifted] memory = 10`.

| rank | steps | of 600,000 | peak bytes | of 5 MiB | debug.log line |
|---|---|---|---|---|---|
| 1 | 585,782 | 97.6% | 3,234,855 | 61.7% | 1186 |
| 2 | 418,777 | 69.8% | 3,306,994 | 63.1% | 1477 |
| 3 | 185,604 | 30.9% | 1,481,115 | 28.3% | 83 |
| 4 | 128,858 | 21.5% | 928,747 | 17.7% | 736 |
| 5 | 113,942 | 19.0% | 805,273 | 15.4% | 1144 |

- **Max: 585,782 steps, 97.6% of the default budget**, the only codec run at or above 80% of it.
- Worst peak bytes: 3,306,994 (63.1% of 5 MiB), in the run of 418,777 steps.
- The heaviest settles of any kind: codec 585,782; relation.av.relation 424,894; codec 418,777; core/taped_derive.av TapeRoot.derive 376,587; core/tape_roots.av AVRA_TAPE_SCHEMA 360,703.
- One derive's runs climb across repeats (9,474 → 18,508 → 27,359 …), so a derive settles more than once in a cold check.

## Receipts

Logs in /work/out/services/: test-std-queue.log, test-std-queue_store.log, test-std-queue_store-cbc4.log (the landed head alone), findings-*.log, check-*.log, check-std-avrac-cold.log, debug.log (the settle lines), gather.sh (the exact commands).
