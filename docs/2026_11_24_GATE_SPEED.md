# Gate speed: where the program gate's half hour goes

Measured over 13 full gate runs (45472486441 … 45501610701, 81 jobs each),
job and step timings from the API, per-row seconds from the logs of
45499487807 and 45495505856.

## The wall today

| case | runs | wall (median) | seed | slices start | longest slice |
| --- | --- | --- | --- | --- | --- |
| compiler source moved | 9 | 25.2 min (23.1–34.6) | 8.4 min | +8.5 → +13 (+24 when gates overlap) | 12.7 (cost-ledger-cold) |
| compiler source as landed | 1 (45486824726) | 15.5 min | 1.5 min | +1.6 → +5 | 13.2 (build) |

Where the minutes go, compiler moved (45499487807):

| stage | min | what |
| --- | --- | --- |
| seed | 0.3 + 7.7 | builder fetch; gen-1 192 s, libs 60 s, gen-2 181 s, pack 5 s |
| queue | 0–4 (to 15) | ~60 jobs run at once (max seen 60–69); 80 slices; 31–46 when two gates overlap |
| slice overhead | ~1.0 | container 20–30 s, unpack 20–33 s (of which ~20 s was `built-from`) |
| census compiler | 1.7–2.8 | rebuilt in EACH of 12 cost slices |
| slice work | to 10.3 | cost-ledger-cold 536–561 s, avrac-d 566–618, avrac-e-1 464–608 |

Runner time: 393–454 runner-min a gate, 81–89 of it job overhead (19%),
~29 of it twelve copies of one census compiler (7%).

## Lever 4 — cache the compiler by its own source: ALREADY IN, hits 12%

gate.yml's `builder` step unpacks the `gate-builder` release (the landed
head's pack) when the tree's compiler source is its source; 45486824726 is
that path (seed 1.5 min, wall 15.5). The key moved in **52 of the last 59
landings**. Of the files that moved it, 1658 are `.av`, 54 `.c`/`.h`, 13
the Makefile; **no landing moved it with non-source files alone** (8
`.print`/`.js`/`.html`/`.md`/`.toml` files, always beside `.av`).

| package | files that moved the key |
| --- | --- |
| std-avrac | 1326 |
| std-program | 98 |
| std-ui | 93 |
| cli | 93 |
| runtime | 51 |
| others (12 packages) | 76 |

The key is not too broad: every moving landing changed source the cli
build reads. Nothing more to take here.

## Lever 1 — slices on gen-1

The proposal "gen-2 ≠ gen-1 fails the gate" is wrong: a change to
lowering or codegen makes gen-2 differ from gen-1 legitimately (gen-1 is
the new source laid out by the OLD compiler). The honest form is
speculative: slices start on gen-1 (seed ends at ~5.0 min, −3.4); a
`gen2` job builds gen-2 beside them; if the bytes are equal the gen-1
verdicts ARE gen-2's; if not, every slice runs again on gen-2 (wall ≈
today + 1 min, runner time ×2). Whether that pays depends on how often
gen-2 == gen-1, which nobody had measured — 27 of 52 moving landings touch
backend/runtime/lowering paths. **The seed now says it** (45507002101 stood at generation 2, so it is still unmeasured)
(`fact gen2-is-gen1 yes|no`); decide after ~10 gates. Below ~70% equal,
the doubled runner time on a ~60-job cap costs more than it saves.

## Lever 2 — split by measured time

| slice | work s (two runs) | change |
| --- | --- | --- |
| cost-ledger-cold | 536 / 561 | → ledger-cold-a (cold-a's build-cli, ~370) + ledger-cold-b (cold-b's two, ~200) |
| every cost slice | +101–169 census | census once, own job |
| avrac-* (11 slices) | 270–618 | next: per-dir seconds (a per-path `avra test` refuses a module that is no spec — rows only where tests stand), then deal by them |
| cost-laid | 438 / 525 | the snapshot's std answers 444 s, the counted check 49 s (45507002101) — see below |

avrac's rows are one number a slice, so no split can yet be dealt by time.

### cost-laid is its std answers

Run 45507002101's cost facts: `the snapshot's std answers 444 s`,
`check-cli-laid 49 s`. The answers are made outside any count, four jobs
on four cores (tools/std_answers.sh), by the census compiler, so they
move whenever the compiler does. gate.yml keeps them in an actions cache
keyed by compiler source and snapshot, but a `gate/**` branch restores
only its own caches and the default branch's: no gate ever restores
another gate's, so the cache has never answered — 45507002101's compiler
stood as landed and the answers still took 444 s. Two ways out, either
dropping cost-laid from ~9.6 to ~2.5 min:
- TAKEN: the answers kept beside the `gate-builder` release
  (`cost-answers.tar.gz`), which every gate reads; the slice uploads what
  it stood on as `gate-cost-answers` for a landing to publish. It hits
  where the census compiler's bytes are the landed one's — the compiler
  key held, ~12% of landings — and a miss costs what it cost before.
- FALLBACK, a spend: a 16-core runner for cost-laid alone (the answers
  already run one job a core; the counted check is on core 0 either way).
  At ~$0.042/min (Linux x64 16-core, 2026 list, to be confirmed) and ~4
  billed min a gate, ~$0.17 a gate; at the measured 14 gates in 3.3 h,
  30-100 gates a day, **~$150-500 a month**. Larger runners carry no free
  minutes, public repository or not.

### Why the answers' key cannot be narrower

The store a check reads is partitioned by the compiler's PRINT, the
digest of its own binary (compiler/build.av `digest_of_binary`, store.av
`pack_at(root, print)`): answers another binary made are not stale to
the census compiler, they are invisible to it. Narrowing the key to "the
answer-shaping code" would mean the compiler trusting answers worked out
by different analysis code — the hazard CLAUDE.md names (a cache filled
by a binary of another shape is wrong, and traps). And it would buy
nothing measured: every one of the 52 landings that moved the compiler
key touched compiler-core source (std-avrac, std-relation, std-program,
std-grammar, std-meta, std-prelude, cli, runtime, backend, Makefile). A
per-query-family code fingerprint inside the compiler is the only sound
narrower key, and it is a compiler project, not a gate change.

### The census compiler belongs to the seed

As its own job (45507002101) the census compiler was ready at +3.4 min,
and the cost matrix then queued behind seventy slices on the ~60-job cap
and started at +19.7 to +23.6. It is now the seed's last step (96 s),
uploaded apart, and the one matrix lists the cost slices first.

## Lever 3 — the runner queue

- The cap is ~60 concurrent jobs (Team plan); one gate is 81. Two gates at
  once start the last slices at +19 to +24 min (45496126374, 45497380775).
- The seed is close to single-threaded (load 1.6 on 4 cores at its end):
  a larger runner buys the seed little. Not recommended until a build
  scales with cores.
- Per-job overhead is ~1 min × 80. Fewer, fatter jobs pay where a slice's
  work is near its overhead: program-3..6 (1.4–1.6 min jobs, 17 s of
  work), fmt, idioms, idioms-cli, doors-a. Grouping those into two jobs
  saves ~8 runner-min a gate, no wall.
- What frees the queue most is runner time: census once (−29),
  `built-from` (−~17: 80 slices × ~13 s).

## Commits (each a bundle commit; each proven on a gate run)

| commit | lever | expected |
| --- | --- | --- |
| key in one cat | 3 | `built-from` 6.4 s → 1.0 s; ~15–20 s off every slice and the seed |
| ledger-cold in two | 2 | longest slice 12.7 → ~9 min job |
| census in the seed, cost first | 2/3 | −29 runner-min; seed +1.6 min, each cost slice −2.4 min and first in the queue |
| gen2-is-gen1 fact | 1 | measurement only |
| cost facts | 2 | measurement only |

## Projection (compiler moved, one gate on the runners)

| state | wall |
| --- | --- |
| today | 25 min |
| these commits | ~20–21 (avrac-d and cost-laid now bound it) |
| + avrac redealt to ≤5 min, cost-laid answers in the census job | ~15–16 |
| + lever 1 where gen-2 == gen-1 | ~12–13 |

## Train21 (45520921593): the cli's cold build, not the runner

Wall 29.7 min. The seed took 871 s: gen-1 281, libs 45, gen-2 269, census
257 (earlier runs: 192 / 60 / 181 / 96). The rows did not move together
against 45499487807: std-avrac's suites ran ×0.6–0.7, while every row
that builds the cli cold ran ×2–2.7 (edit-b 224→614 s, edit-f-2
275→740, warnings-a 98→218, needs-2 128→270, the census 2.7×). A slower
runner moves everything; this moved the cli's cold build. Train21 made
the cli reach `@std/compress` and `@std/http_compress` (the vendored
zlib and brotli, 3 MB of C), and the `.av` its build reads grew 0.3%.
That attribution wants a census of `build packages/cli` at b5a71497
against d7cd84d9. The cost ratchet cannot see it, because it measures a
pinned snapshot, never the tree's own cli.

It bounds the gate from below: an edit slice is one case (a cold
product, the edit, a warm build, the edited tree built cold), three to
four cold cli builds, so ~10–12 min at train21's speed; and the seed
builds the cli twice. Until the cli's cold build is what it was, a gate
whose compiler moved is ≥ ~22 min on these runners.

`fact gen2-is-gen1 no` at equal sizes (105905264 bytes): lever 1 had
nothing to start on there. The seed now says where they differ.

At 257 s the census in the seed held every slice back 4.3 min; it is its
own job beside the slices again, which the job packing makes safe. The
warm suite store was dropped: it saves ~20 runner-min, but in every
layout where it is not hidden behind the census it costs the suite
slices more wall than it gives them.
