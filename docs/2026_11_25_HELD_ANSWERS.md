# Held answers: bounded, per engine

## What holds the gigabytes

Every `@saved` query family generates three process-wide tables (std-program/src/saved_query.av):

- `${f}_held`: a `HashKeyedTable<HeldAnswer<T>>` keyed by the answer's hash. It holds every value an answer ever read back as, and every value just computed.
- `${f}_asked`: every question asked.
- `${f}_fresh`: the last computed answer.

Nothing removes an entry, so every decoded answer the run has made lives until exit. A cold `check packages/cli` accounts 2344 MB at peak with 1401 MB of list boxes still live at exit. That run's top sites are this table's contents: `read_saved_list` records, `*.read_from`, `checking`, and the Lowering's `Ins`/`Layout`.

The holding is load-bearing for speed. `AVRA_HELD_ANSWERS_OFF=1`, which re-decodes an answer at every ask, did not finish a cold check inside its 15-minute bound. The same check with holding on takes 63 s. So neither "hold everything" nor "hold nothing" works: decoded values have to be bounded without re-decoding a hot one.

## The design: a held table keeps what is hot, up to a budget

1. **Which families drop.** Every family's held table becomes bounded. The asked and fresh tables are untouched: a question is small and the engine's save needs it.
   - A held table is a CLOCK cache over its slots. Each hit sets the slot's reference bit.
   - Over budget, the clock hand clears bits and evicts the first slot whose bit is clear.
   - Evicting drops the value only. The answer's bytes stay in the engine's store (draft or pack), so a later ask decodes them once through the existing `answer_read_door`/`read_saved_list` path and holds the result again.
2. **When.** A value is evicted on the `put` that takes its table over budget, and never at any other time. No pass bookkeeping is needed, and no "readers settled" signal that could be wrong:
   - a value nobody asks again ages out;
   - lowered IR, once its codegen or memory reader has read it, is never asked again, so it goes;
   - `checking`, once its findings are rendered, is never asked again, so it goes.
3. **What keeps a hot answer resident.** Every hit sets the bit. A hot answer (a signature, a type head, a scope) is hit between two sweeps of the hand, so it is never evicted.
   - The warm path cannot re-read in a loop: an answer re-asked while held costs one bit write.
   - Thrash would need a working set larger than the budget. The census's `read_saved_list` decode count is that signal, and the cost ledger gets a row for it (decodes per check).
4. **The budget** is one number per engine, counted in each answer's SAVED bytes: the length the engine already knows when it decodes or saves the answer. A decoded value's size is proportional to its bytes, so no deep sizing of values is needed. All of an engine's families share the one budget through one clock, so no per-family tuning is needed.
   - `AVRA_HELD_BUDGET_MB` overrides the number.
   - `AVRA_HELD_ANSWERS_OFF` stays as the zero budget.
   - Start at 64 MB of saved bytes (decoded values run several times their bytes) and measure: cold and warm check and build, accounted peak, RSS, decode count.
5. **One derivation is alive at a time.** The held tables are a PROCESS holder of the kind that law names. They are `once fn`s, so a second engine in the process (a turn, a rebuild, a suite running many engines) keeps every earlier derivation's decoded answers alive.
   - The tables move onto the engine: one per family per engine, made on first ask, and dropped with the engine.
   - The asked table already guards by `engine.serial`. The held table is keyed by content hash, so sharing it across engines was correct but kept the dead engines' answers alive.
6. **Defect to fix on the way:** the fresh path puts into `${f}_held` without asking `answers_held()` (saved_query.av, `asking_wrapper`). The fresh put goes through the same bounded put.

## Expected

The decoded values among the 1501 MB of list boxes fall to the budget. The engine's own bookkeeping stays: `learned` at 89 MB, the question tables at about 170 MB, the store's bytes at 191 MB. Expected cold check accounted peak is about 700–900 MB, warm unchanged, wall time within a few percent of today. The S1 rows judge it.
