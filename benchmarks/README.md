# The Avra benchmark suite

A checked-in, multi-language benchmark suite: a **showcase** of what the
compiler and the languages beside it do on concurrency primitives, and a
**regression tool** that refuses a row past a margin. It is its own
top-level package — a peer of `packages/`, `runtime/` and `tools/` — and
deliberately **not** `@std`.

```
benchmarks/
  bench.toml            the registry: families, languages, toolchain pins, the gate
  run.sh                the one door (below)
  README.md             this file
  lib/                  the runner, the reporter, the gate, the self-test
  results/runs.jsonl    the stored rows, one JSON object per line (checked in)
  baseline.json         the accepted gate baseline (checked in)
  report/               GENERATED: results.md and index.html, never hand-edited
  tasks/<benchmark>/
      spec.toml         the workload, the invariant, the rows, which languages
      c/ rust/ go/ python/ ...   one directory per language, whose program prints
                                 the row contract
```

## Quick start

```
sh benchmarks/run.sh                       every registered language, every benchmark
sh benchmarks/run.sh --lang c,rust,go      the named languages
sh benchmarks/run.sh --bench tasks/drain   the named benchmarks (family/name)
sh benchmarks/run.sh --record              run, store the rows, accept a baseline, regenerate the report
sh benchmarks/run.sh --report              regenerate report/ from results/runs.jsonl
sh benchmarks/run.sh --gate                the C floor and each Avra row's target against Go, refusing past it
sh benchmarks/run.sh --gate --require      a machine with no row, C or Go, refuses instead of noting
sh benchmarks/run.sh --g1                  each Avra row printed beside Go's, with the target verdict
sh benchmarks/run.sh --list                benchmarks and languages
sh benchmarks/run.sh --self-test           the gate's rules, the row contract, the report
```

A plain run prints one JSON row per `(benchmark, language)` to stdout.
`--record` also appends them to `results/runs.jsonl` (one row per
benchmark/language/machine — the latest wins) and accepts their numbers
into `baseline.json`. The **gate's floor is C alone**, so the regression
seam runs with no compiler and no other toolchain installed; `--lang`
widens it.

## The JSON schema

Every run emits ONE object with exactly these keys:

```json
{
  "benchmark": "tasks/drain",
  "language": "go",
  "version": "go version go1.25.1 linux/amd64",
  "machine": "linux-x86_64: AMD EPYC 7R13 Processor, 8 cores, Linux 6.12.105-fly",
  "when": "2026-10-15T07:20:11+00:00",
  "rows": {
    "drain_10k_ns_per_op": { "unit": "ns", "value": 48.7, "samples": 5 },
    "drain_bytes": { "unit": "bytes", "value": 80000, "samples": 5 }
  },
  "notes": "…"
}
```

- `benchmark` is `<family>/<name>`; `language` is a `bench.toml` key.
- `version` is the toolchain's own first version line; `machine` names the
  platform AND the machine, so two machines are never compared.
- `rows` maps each row name to its `{unit, value, samples}`.
- `notes` is the program's `#` lines; a language that could not run says
  `SKIPPED: <reason>` here, with an empty `rows` (never a silent cap).
- A run that fails is a loud `bench: FAIL …` on stderr and a nonzero exit.

The **reporter is a pure projection** of these rows: no clock, no
measurement, so the same `results/runs.jsonl` renders byte-identically —
the property `--self-test` checks against `report/results.md`.

`--g1` prints the **G1 view**: one row per benchmark, Avra's number
beside Go's from the SAME run, the ratio, and PASS/FAIL against the
row's target. It also names the ticket's rows that no Avra twin measures
yet, so a missing row is a finding and never a silence.

## The row contract (what a language program speaks)

A language program knows nothing of JSON, versions or machines. It prints
one line per row, tab-separated:

```
<name>\t<value>\t<unit>\t<samples>
```

and any `# …` line as a note. So a twin for `tasks/drain` might print:

```
drain_1k_ns_per_op	520.3	ns	5
drain_10k_ns_per_op	480.1	ns	5
drain_scale	0.92	x	5
drain_bytes	80000	bytes	5
```

The harness wraps those into the JSON envelope. A line that is not the
contract is refused, so a twin that drifts is never silently dropped.

## Adding a benchmark

1. `mkdir benchmarks/<family>/<benchmark>` and write `spec.toml` with
   `[benchmark]` (title, invariant, row), `[workload]`, `[rows.<name>]`
   (unit, about) and a top-level `languages = [...]`, plus a `[notes]`
   block. The invariant is what every twin must do identically.
2. Add a directory per language with its program, printing the row
   contract.
3. `sh benchmarks/run.sh --bench <family>/<benchmark> --record`.

Discovery needs no edit: a family is any directory under `benchmarks/`
holding a benchmark with a `spec.toml`.

## Adding a language

A language is **a `[languages.X]` block in `bench.toml` plus a
`<benchmark>/X/` directory**. Nothing else in the tree names it, and the
runner discovers both.

```toml
[languages.kotlin]
title = "Kotlin (Loom)"
version = ["kotlinc", "-version"]
present = ["kotlinc", "-version"]     # a language this refuses is SKIPPED with the reason
source = "main.kt"
build = ["kotlinc", "{src}", "-include-runtime", "-d", "{out}"]
run = ["java", "-jar", "{out}"]
```

`build`/`run`/`version`/`present` are argv lists (no shell), with
`{src}`, `{dir}`, `{out}` and `{avra}` filled by the runner. A language
with no `build` is interpreted (`run` alone, as Python's). A benchmark
that does not list the language records a SKIPPED row, so the report says
why. The heavy languages — Kotlin, Java (Loom), Elixir, Swift, C#, Node,
Python (beyond the threads twin) — are each a directory and a spec line
away; none is set up here.

## The gate

`--record` writes `baseline.json`, keyed by
`machine|language|benchmark|row` with the accepted value and a margin
(the registry's `[gate].margin`, overridable per benchmark or row in
`spec.toml`). `--gate` runs the floor (C) and refuses a row past its
margin (`>`, never `>=`), and states how many rows it examined and gated.
A machine with no accepted row prints the rows and does not gate;
`--require` refuses instead. The `drain_scale` row carries its own 3.0x
margin because a scaling ratio is noisier than a fixed cost.

This is the idea `tools/flow_bench/gate.py` landed for the scheduler's
transition rows, at the suite's scale. `tools/flow_bench/` is the OLDER
harness and this suite is the ONE DOOR for the Avra-beside-Go question:
`make flow-bench` runs `benchmarks/run.sh --g1`. What `tools/flow_bench/`
uniquely holds stays there — `make flow-gate` is the runtime-only C
floor a `runtime/*.c` change answers (no compiler, no Go) and
`make flow-probes` is the stack allocator's own measurements. Those are
different questions, not a second door; its Avra-beside-Go view is the
design this suite now carries.

### The G1 target against Go

A `--gate` keeps the C floor AND judges each Avra row against **Go's row
from the SAME run** — never across machines, and never a fresh Avra
against a stale Go baseline, which would charge Avra for the machine's
own drift. Where the machine has no Go, Go's recorded row for this
machine is the fallback. The factors are data in `bench.toml`:

```toml
[gate.target]
default = 2.0
[gate.target.rows]
parked_bytes = 3.0
```

the ticket's target (`avra-8sb5.34.53.21`): within 2× on the time rows —
ping-pong, fan-in, select over N, the deadline row — and within 3× on
bytes per parked task. A witness count (`check = "exact"`) is not a cost
and carries no target. A row Go never measures is a SKIP named; a row Go
measures on some machine but not on this one is a word, and `--require`
refuses instead. `--self-test` witnesses the target gate REFUSING on a
fixture, so its failure is seen and not assumed. On the tree's own Sprite
the gate is RED today: Avra's ping-pong is 2.6x Go, past the ticket's 2x
target — the finding the gate exists to make loud.

## What is measured, and what is not

The **invariant** is what every twin must do identically, written in each
`spec.toml`; the **row** is what is timed, and the **analogue** is the
primitive a language uses for it. Each `spec.toml` carries an
`[analogues]` table naming every language's primitive, and the report
prints it, because two categories that look alike are not comparable:

- `tasks/spawn` measures create and join in TWO categories that are not
  interchangeable — an OS thread (`spawn_thread`) and a user-space task
  (`spawn_fiber`). C carries both (pthreads and `ucontext`), Rust and
  Python only the thread, Go and Avra only the fiber, so a table can
  never read a `pthread_create` beside a goroutine as a speed
  difference.
- `tasks/pingpong` a round trip; `tasks/drain` a bounded-channel drain at
  two sizes with its **scaling ratio** — the shaped row a pure latency
  number cannot give, added so an O(n²) drain is visible; `tasks/fanin` N
  producers to one consumer; `tasks/parked` resident bytes per parked
  task.

Avra is measured: `produce`/`yield`/`for x in Source`/`select`/`spawn`/
`.await` and `@std/task`'s `open_channel` are its twins' vocabulary. The
runner fills placeholders inside a token (`{dir}/src/main`), which the
Avra twin's run command needs — an exact-token match never reached it.

What is **not** measured here, deliberately: the memory-per-task row off
Linux (RSS comes from `/proc`); and throughput under load, which is
`tools/bench/public.sh`'s subject (the public harness against nginx and
h2o, ticket `avra-8sb5.34.36`), alongside the methodology ticket
`avra-8sb5.1.31.12`.
