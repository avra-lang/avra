# FLOW 03 — the tick's arm compares a cached pid (`avra-8sb5.34.53.32`)

Ticket `avra-8sb5.34.53.32` (child of `.53`, ladder 4). Base `origin/main`
(`ea3af48`), stacked on `flow-03-5` (`48838b1`) — the base is not green
without it (see Owed). `f:` is `runtime/avra_fiber.c`, `t:`
`runtime/host/avra_tick.c`.

## The bug

`ready_push` (f:277) arms the source on the ready queue's empty-to-non-empty
transition, which a round trip crosses twice. `avra_tick_armed` (t:126)
answered "is a source armed for this process" with `g_owner == getpid()`,
and `getpid()` is a call every arm. MEASURED here: `getpid()` is 96 ns/call
on the Sprite (`linux-vdso`, glibc), ~192 ns of a 302 ns C round trip.

## The fix

- `g_owner` is now "the pid the source was armed under, or 0 when none
  stands for this process" (t:32). The cold arm reads `getpid()` once
  (`this_pid`, t:47); the hot arm is `if (g_started && g_owner)` (t:126,
  t:136) — a compare, no syscall, and no frame before its first branch.
- `tick_armed_cold` (t:108, `noinline, cold`) holds the pipe/thread setup,
  so the hot path is a leaf. Disassembled: the first `sub sp`/`stp` sits
  after two branches, on the parked-wake path alone.
- `pthread_atfork(NULL, NULL, tick_after_fork)` (t:110) registers once; the
  child handler clears `g_owner` (t:43), so ANY fork — `avra_fiber_forked`
  or a raw `fork()` — makes the next arm replace the pipe and thread. That
  is the correctness the pid comparison existed for, kept.
- `tick-object` allows `pthread_atfork` (tools/tick.py): registration runs
  on the scheduler's thread, never in the thread body.

## Tests first

- `tick_test.c`: `the hot arm reads no process id` — a counted witness
  (`avra_tick_pid_reads`, declared in `avra_platform.h`) that 10k arms and
  stood-downs raise no pid read; `a raw fork re-arms` — no
  `avra_fiber_forked`, only the tick's own handler.
- `mutations.py`: 7 new HOST breaks — the registration, the handler body,
  the hot pid read, the owner-ignoring check, the stood-down pid read, the
  cold arm's record, and the counter itself. All killed; 231 of 231 total.

## MEASURED (Sprite `avra-unions-p2`, Linux x86_64, least of 5, same tree
with only `avra_tick.c` swapped)

| row | before | after | speedup | after vs Go |
|---|---|---|---|---|
| ping-pong (C runtime) | 302.4 ns/rt | 92.9 ns/rt | 3.25x | — |
| spawn+join (C runtime) | 398.3 ns | 205.2 ns | 1.94x | — |
| ping-pong (Avra G1) | 367.7 ns/rt | 154.6 ns/rt | 2.38x | 0.34x |
| spawn+join (Avra G1) | 408.7 ns | 203.5 ns | 2.01x | 0.27x |

Go best: ping-pong 459.7 ns, spawn+join 742.4 ns. The ticket's acceptance
(≤ 2x Go) holds with margin; the ticket's stated baseline (3.64x / 2.03x)
was a machine where `getpid` costs ~450 ns.

## The gate

`make flow-g1` runs the bench with the G1 verdicts (2x time, 3x memory) and
FAILs on any row that FAILs; it SKIPS, spoken, where Go or the compiler is
absent. `make runtime-tests` 0 failed, `make runtime-mutations` 231/231
killed 0 survived, `make keepers` whole exit 0.

## Owed / unverified

- `make flow-g1` currently FAILs on `10k tasks alive and parked, cold`
  (4.59x, Avra 4355 ns vs Go 948 ns) — PRE-EXISTING, not this change (the
  ticket's two rows PASS). It wants its own ticket; the gate names it
  rather than hiding it.
- This branch is stacked on `flow-03-5` (PR #510) for its green
  `runtime-tests` (the pre-existing `late_parker` flake) and
  `runtime-mutations` (`the switch ignores the tick`). Rebase onto main
  once #510 lands.
