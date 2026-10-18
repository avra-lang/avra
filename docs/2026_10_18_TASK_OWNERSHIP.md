# Who joins a task: the handle's last release

DRAFT for the DB lead's review. Ticket avra-8sb5.34.53.64 (the select head),
generalised. Touches the memory pass, so it is not a library change.

## The law and the gap

THE LAW: cancelling a task cancels every task it made, and each child's
defers run exactly once before the parent's unwind ends. The task law
already says the block that spawned a task joins it.

Today only a STATEMENT can own a task (`owns_tasks`: a binding through its
slot, a dropped value through its register). A `spawn` anywhere else has no
owner. Probed on main (a parent cancelled while its child sleeps; the child's
defer should run before the parent's):

| position of the `spawn` | result | want |
|---|---|---|
| bound (`let t = spawn ..`) | `lp` | `lp` |
| dropped (`let _ = spawn ..`) | `lp` | `lp` |
| call argument (`peek(spawn ..)`) | `p` | `lp` |
| list handed as an argument (`count([spawn .., spawn ..])`) | `p` | `llp` |
| receiver (`(spawn ..).done`) | `p` | `lp` |
| `??` operand (`peek(none ?? spawn ..)`) | `p` | `lp` |
| interpolation hole (`"${(spawn ..).done}"`) | `p` | `lp` |
| `select` head (`select { r in spawn .. }`) | `p` | `lp` (fixed by #960 only) |

(A record field, a capture and an answer are refused by the task law.) The
witness is `tasks/tests/cancel_child_positions` on branch `ui-tasks-owned`.

## Why a deferred join at the spawn does not work (built, red in CI)

Registering a settle at the frame's close for the register `spawn` made:
(1) in a conditional arm (`??` right side, if or match arm) the close is
outside the region that defines the register, which the memory pass proves
invalid; (2) a value that flows through a merge or a widen is a different
register, so retiring the join "where it is stored" misses and the stale join
reads a released register. Keeping a reference alive fixes the first and not
the second, which is silent: a task pushed into an outer list through a merge
from a loop body is joined at the end of every iteration, serialising it or
deadlocking a child that waits on its parent. Registers are the wrong key.

## Three designs

**(a) The join is a property of the HANDLE's last release.** The memory pass
already decides, for every register of a task type, where its last owner
ends, across regions and merges: that point is where it places the Release.
Make a task-typed Release the place the task is joined (cancelled first when
the releasing task is unwinding because it was cancelled), when it is the last
external handle. Every position in the table is covered by construction, a
bound task keeps its frame-close join (its Release is there), and a merge
cannot lose it. Both engines get it, because the lowering and the memory
pass are the one semantics. It needs the last-handle test: the running
fiber holds its own reference to the task, so "last external handle" is
`rc == 2` at release, a runtime row (`avra_task_release`), which is a row to
approve and a three-rung ladder (row, arm, declaration).

**(b) A join at each non-storing consumer.** Sound, because the consumer
knows the operand is a borrow, but it is the per-position patch: a missed
consumer is a silent leak, and there are about eight consumers. Not
recommended beyond #960's select head.

**(c) The RUNTIME settles a Task box when its handles are gone**, with no
compiler change. Cheap to state, and the catch is real on three counts:
(i) a release can run in C paths that cannot park (a list or map free
releasing its elements), so the join must not happen inside the release; the
fix is to record the orphan on the releasing fiber and join it at that
fiber's end or cancel landing, which is non-parking and sound; (ii) the
timing is the parent's END, not the frame's close, so a loop that makes a
temporary task each turn accumulates live children until the parent ends;
(iii) THE EVALUATOR HAS ITS OWN TASK MODEL (`interp_tasks.av`, virtual
tasks), so a runtime-only rule gives native a law the evaluator lacks, and
`eval == native` is the project's differential. It would need a twin in
the interpreter, and then it is (a) again with a worse timing.

## Which is sound, and why

(a) is the sound one. Memory safety holds for (a) and (c) alike (a joined
task's box outlives its join). What separates them is ENGINE AGREEMENT: the
law must be a property of the IR both engines run, and only the memory pass's
Release is that. (c) is native-only unless mirrored; (b) is sound but leaves
the law dependent on a consumer list. Recommend (a), landing in this order:
the row alone (`Unhosted`), then its arm and the memory-pass rule, then the
witness above flipping green on the evaluator, native and wasm.

## Open

- The first Release of a task COPY (`let a = t`) must not join while
  another handle stands: the `rc == 2` test is the whole answer, and a test
  must pin a copy released first.
- A Release during an unwind joins by cancelling (the parent is leaving),
  and during a normal exit joins by waiting; the row takes that as a flag the
  memory pass knows (it knows which exit it is placing).
- #960 lands as a PARTIAL fix (the `select` head) with this ticket open.
