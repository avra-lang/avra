# FLOW G2 — naming the deadlock's tasks: design note (slice 02's leftover)

Ticket `avra-8sb5.34.53.23`. Base `origin/main` (`5ef6c8a`), lane `flow-03r`.
`f:` is `runtime/avra_fiber.c`. Tickets: the naming half of G2.

## 1. What is already named (READ)

Slice 02 landed the C case report. `case_cleared(dead)` (`f:2548`) walks the
case's live fibers oldest-first and, for each, `task_said` (`f:2455`) names its
id, spawn site and kind, `waits_said` (`f:2474`) names its `join` and each
filed waiter — `a time`, a `descriptor N`, a `gate <addr>`, a `task N's end`
(`waiter_said`, `f:2441`). The same function serves the deadlock (`dead=1`) and
the leak (`dead=0`, "outlived the case —"). `case_test.c:326-341` pins it.
The native case's leak report therefore already names task/timer/waiter; this
slice does NOT fork it.

## 2. What is not named (READ)

- THE COMPILED PROGRAM'S DEADLOCK. `next_with_world` (`f:1550`) traps with the
  bare word `"every task is waiting — deadlock"`: no task is named.
- THE EVALUATOR'S RUN DEADLOCK. While a run stands, the branch answers
  `avra_vtask_next` with 0 (`f:1549`) and the machine files the constant
  `all_waiting()` (`interp_tasks.av:632`, "every task is waiting — deadlock"):
  no task is named. (The same trap covers a virtual deadlock outside a run,
  `vtask_test.c:156`.)
- BOTH read the SAME graph `case_cleared` already reads; only the walk's sink
  and the selection differ.

## 3. The change — one walk, two more callers

`deadlock_reported()` (`f:2499`, `noinline, cold`): the header
`avra: every task is waiting, and nothing can wake one:` and one line per live
task, oldest first — `task_said` + `waits_said`, the SAME two writers the case
report uses. `main` is named first when the run is compiled (it is static and
not on `g_all`, as the door's listing already knows, `f:3007`); ids are the
process's own (`id_of`), not the case's relative ones. No heap allocation: it
writes to `stderr` only, so it is legal on `avra_trap`'s cold path.

Called at two sites:
1. `next_with_world`, before the compiled trap (`f:1551`) — the program's own
   deadlock, and a virtual deadlock asked outside any run.
2. `avra_vtask_next`, when the policy answers no task while a run stands — the
   evaluator's deadlock, named for its machine to file (`f:2339`).

No new runtime row: the run's report is stderr, so no row's declaration ladder
is owed. The machine's `all_waiting()` word is unchanged.

## 4. Tests, first

- `fiber_test.c`: `stuck()` — a task parked on a gate nobody will claim, the
  spawner joining it. The bare trap must name the program's own run and the
  task, with the gate. Fails today (no names).
- `vtask_test.c`: extend the outside-run deadlock's words to the task's line;
  add an inside-run child (`avra_sched_run_begins` … `avra_vtask_next()==0`)
  whose two gate-parked virtual tasks are both named.
- Mutations: one per call site (drop each `deadlock_reported();`), and one for
  the header line.

## 5. Not in this slice

The evaluator's run LEAK (`interp_tasks.av`'s `retired()`) retires its jobs
silently; naming it needs the machine's own report at run end
(`docs/2026_10_06_FLOW_02_DESIGN.md` §4 blocker 5 / review 1 item 5) and a
row or a reorder. Filed as a follow-up; the native leak is already named.
