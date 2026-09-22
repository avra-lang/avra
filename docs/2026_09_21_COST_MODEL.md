# The cost model — a program's resources, derived from source

Design, 2026-09-21. Not built. Written after the build-cache campaign, which
is what makes it affordable: every stage is a query, every artifact is kept
under a content key, and one edited file re-derives in ~100 ms.

**In one line:** a cost is a FUNCTION, not a number. The compiler derives its
SHAPE (a polynomial over named sizes) from the IR; the runtime's own
accounting supplies the CONSTANTS; a declared or observed load supplies the
ARGUMENT. Nobody reads the program to know what it costs. They query it.

**Who it is for:** an agent running a business on Avra, which needs to know
what a program will cost to run, where it is slow, and whether a change
made it worse — before deploying, and with no human to ask.

## 0. The paradox, collapsed

"Static analysis cannot know inputs or constants" is true and is not a
trade-off. It is three inputs being asked to do each other's jobs.

| input | who supplies it | never touches |
|---|---|---|
| shape: `steps = 3·|rows|·log|rows| + 12` | the compiler, from the IR | a clock |
| constants: steps → seconds, allocations → bytes | the runtime's accounting, per machine class | the source |
| argument: `|rows| = 1e6`, `rps = 200` | a `deploy` block, or production observation | the compiler's derivation |

Kept apart, each is exact at its own job, and the product is a cost the
compiler can stand behind. Mixed, every one becomes a guess.

## 1. Where the knowledge is

Three facts about this compiler make the derivation honest rather than
heuristic:

1. **Every world touch is a row.** `RtSig` (core/ir.av) is the ONE door to
   C, disk, net, process, time. `Reach { Pure, Embed, World }` already
   partitions it. Nothing spends a resource without passing a row.
2. **Every allocation is placed by the memory pass.** Retains, releases,
   scope ends, cell settles, `Ins.StaticAddr` for immortal data. Peak live
   memory is a fact the pass already computes without naming it.
3. **Every unit is concrete.** `Lowered` is keyed per (decl, type args,
   seats). Under mono, `sort<User>` and `sort<int>` are different units
   with different costs, which is the truth.

So cost is a FIFTH READER of the IR beside interp, memory, ir_text and llvm:
an exhaustive dispatch over `Ins`, no `_ ->`, `make vocab` names its arms. It
is a semantics over SIZES where the evaluator's is over values.

## 2. The query

The doc DB design (`2026_09_06_DOC_DB_ARCHITECTURE.md`) is the template: a
query family, every surface a projection.

```
cost(ws, unit: UnitKey) -> CostFacts     per Lowered unit; memoized; kept in the store
```

| what | where it lives |
|---|---|
| per `ExprId` / `StmtId`: a `Cost` | side tables keyed by typed ids (the node-facts law); spans project to lines |
| per unit: parameters' size variables, the summary `Cost`, the call edges with their substitutions | `CostFacts` |
| a package's cost rows | its RECORD, under law 8 (the file's key) — a dependency's cost is READ, never re-derived |
| a runtime row's cost | columns on `RtSig` (the seam rule: data is a registry row) |

`@std/*` and package C ship their costs the way they ship their objects. A
row with no cost column is refused by `make externs`, so sqlite's and http's
rows declare theirs where their seat boxes are declared today.

## 3. The value

A `Cost` is a VECTOR over resource kinds; each entry is a polynomial over
size variables.

| kind | measures | minted by |
|---|---|---|
| `steps` | abstract CPU work | every `Ins`; rows' `steps` columns |
| `heap` | peak live bytes; allocations | the memory pass's placements; rows' `bytes` columns |
| `disk`, `net` | bytes crossed | `Reach.World` rows |
| `procs` | spawns | the process rows |

**Size variables** are the managed parameters' measures: `|xs|` for a list,
`|s|` for text, the sum of fields for a struct, `|k|·|v|·n` for a map. A
scalar that bounds a loop is a RANGE variable. `for x in xs` is exactly
`|xs|` turns. A call substitutes the caller's size expressions for the
callee's variables; composed up the call graph, that substitution is the
tree.

**Honesty is an enum, never a default:**

```avra
enum Cost {
    Exact(Poly)
    Upper(Poly)
    Unbounded(Site)      // a `while` with no derivable bound, a recurrence past the solver
}
```

A `while` the compiler cannot bound is `Unbounded`, naming the loop, help
"declare `@bound(n)`". Recursion solves the common recurrences (linear,
divide-and-conquer, the master theorem's three cases) and answers
`Unbounded` past them. A plausible `O(n)` written where the compiler does not
know is the protocol-default bug wearing cost's clothes, and the reader who
takes any number as truth is exactly the reader this is for.

## 4. Claims are checked, never trusted

```avra
@cost(steps: n * log(n), heap: n)
@bound(|queue| + 1)
fn drain(mut queue: List<Job>) -> int { while queue.length > 0 { … } }
```

A `@cost` is a claim in the sense `@shows` is: `avra test` runs the program
tests under the runtime's accounting (what `make census` reads today) and
REFUSES a claim whose measured growth disagrees with its shape. A `@bound`
pays an `Unbounded` and is checked the same way. A trusted hint would be an
assumption nothing ever tries to violate.

## 5. What the reader sees

```
avra cost <pkg>                  a table per unit; JSON is the substrate, the table its projection
avra cost <pkg> --load n=1e6     the same, evaluated — MB and seconds, calibrated or refused
avra explain cost <fn>           the derivation: every number with its provenance
```

- `explain cost` reads: "n² because `concat` at line 41 inside the `for` at
  line 38, `n = |rows|`" — P7, every number inspectable.
- **Perf lints** are consumers of the query, never a second analysis:
  "F5010: `concat` inside a loop; `push` is amortized constant." Each ships
  with a measured true-positive rate (the lint law).
- **Effect inference falls out:** a fn's reach is the join of its rows'
  reach, so `Pure`/`World` on user fns costs nothing extra.
- A number is never printed without a load, and never in seconds without a
  calibration. `Uncalibrated` and `Unobserved` are values.

## 6. Calibration and load

**Constants** come from the runtime's accounting: the counters
`AVRA_MEM_STATS` and `make census` already read, sampled per machine class,
kept in the store per compiler print beside the objects. Steps to seconds is
a table, not a model.

**Load** comes from the `deploy` block the spec reserves (19.1, "validates the
deploy is feasible — memory budgets"), or from `--load`, or — Part 2 — from
production.

---

# Part 2 — the compiler when only agents write code

When the writer is a model, the compiler is the only party that cannot
hallucinate. A human closes a compiler's gaps with experience; an agent
closes them with a guess. So every question an engineer once answered from
experience becomes a query, and the source becomes the human projection
(P11) of a store that is the truth.

## 7. What-if: the compiler is the agent's search oracle

```
avra what-if <patch>     → the diff of every fact table: cost, reach, heap, units, Unbounded
```

`anew` a workspace, apply the patch in memory, re-derive the units whose
keys moved, diff `CostFacts`. Law 8 makes it one file's units, so it is
sub-second. An agent proposes ten rewrites, the compiler costs all ten, the
agent picks. Nothing is guessed at.

## 8. Budgets and reach are contracts; breaking one refuses the build

P9 at its end: what ops enforced at 3am is a declaration, judged at compile
time.

```avra
deploy orders {
    budget { heap: 512.MB, steps: 40.ms @ load { rps: 200, |Order.lines|: 12 } }
    reach  { Pure, Db }              // no net, no process, no clock
}
```

- **A cost regression is an F-code.** "F5020: `orders` needs 611 MB at the
  declared load; `merge_lines` grew from n to n²." The unit, the cause, a
  structured fix.
- **A capability escalation is an F-code.** `spawn` or `http.get` inside
  `billing` is refused, because reach is a column on every row and the join
  up the call graph is the walk cost already takes. Injected code that
  phones home is a compile error, not a review comment.

## 9. Production writes back; the compiler is the SRE

Collapse dev/ops/infra (P13) literally. The running binary ships the
runtime's accounting, and the fleet writes two things into the store beside
the objects:

1. **Observed size distributions.** `|Order.lines|` is measured, not
   declared; the cost function is evaluated at reality.
2. **Calibration** for the machine class it runs on.

The derived shape and the observed growth are then two readings of one
quantity, and disagreement is a diagnostic: "`search` was derived n log n
and measures n^2.1 over the last 10k calls — an input assumption broke."
The claims law of §4, run against production instead of a test, in the
channel errors already arrive in.

## 10. The PR is a fact diff; review is a predicate

A human cannot read a thousand agent changes a day and should not. The
change's description is GENERATED from the store: cost delta at observed
load, reach delta, new units, new `Unbounded` sites, claims added or broken,
differential agreement (`@shows`, eval == native, old == new over the
program tests). Merge policy is a predicate over that diff — "no new World
reach, cost within budget, zero Unbounded, every claim green" — and a
change that meets it merges. The human sets the predicate; the compiler
judges; the agent works inside it. Autonomy is bounded by contracts a
non-hallucinating judge enforces, which is the P6 collapse of autonomy
against trust.

## 11. `avra optimize`: the compiler improves programs with no model in the loop

Diagnostics already carry structured fixes; perf lints carry them too. The
loop is deterministic:

```
lint → fix → what-if → differential → accept when better AND equal
```

The compiler proposes, costs, proves semantics kept, and hands the agent a
verified diff. The agent's job shrinks to intent. P10 at full strength: the
tool that holds the knowledge does the rewriting it can prove.

## 12. The fleet is simulated from source, and assumptions get expiry dates

Cost per unit, the topology the deploy block already extracts (who calls
whom), and the observed distributions of §9 are a discrete-event model of
the whole system, runnable in the evaluator at build time. "At 10x load,
`checkout` breaches heap first, at request 3,400" is answered before a box
is provisioned.

Observed distributions have trends, so the compiler extrapolates them:
"`users` crosses the budget in 41 days." The doctrine law that an unstated
condition is a deadline becomes a diagnostic with a date on it, and the
deadline is paid by a new consumer arriving — here, by the compiler itself.

## 13. What makes this land rather than demo

- **Every fact is citable.** Each number has a derivation tree and a store
  key. An agent's claim in a PR is a link to a fact, never prose.
- **The compiler refuses to lie.** `Unbounded`, `Uncalibrated`,
  `Unobserved` are values, never defaults.
- **The agent tools ARE the query families.** `cost`, `what_if`, `reach`,
  `explain` over MCP, as the spec already promises for docs (17.3). An agent
  never reads source to understand it.
- **No new mechanism.** Each part is an existing seam — the memo kernel, the
  CAS, `RtSig`, `Reach`, the memory pass, the evaluator, the diagnostic
  registry — read by one more consumer. Doctrine is tested by building
  against it.

## 14. Refused, with the reason

| refused | why |
|---|---|
| a termination prover | `Unbounded` plus a declared `@bound` is the whole answer; a prover is a research programme |
| costs in the type system | a cost is a fact table, like spans; a signature that carries one makes every caller re-check |
| cycle-level machine modeling | steps plus calibration is the right altitude; LLVM decides the rest |
| a model inside the compiler | the compiler is the one party that cannot hallucinate; keep it that way |
| auto-merge without a human-set predicate | the predicate is where the human's authority lives |
| any number printed without a load, any seconds without a calibration | an agent takes every number as truth |

## 15. Build order

Each composes on the last; none is useful before its predecessor.

1. **The cost query** (§2–§6): `RtSig` cost columns, the fifth IR reader,
   `CostFacts`, `avra cost`, `explain cost`, calibration in the store.
2. **What-if** (§7).
3. **Contracts** (§8): the `deploy` block's `budget` and `reach`; F5xxx
   codes with goldens.
4. **Production write-back** (§9): the runtime ships its accounting; the
   store takes observations.
5. **Fact-diff review** (§10), then **optimize** (§11), then **simulation
   and expiry** (§12).

## 16. What this wants from the language

Recorded here at design, for the sugar backlog:

- `@cost(...)` and `@bound(...)` as checked claims (§4).
- A `deploy` block with `budget` and `reach` (§8) — reserved in the spec,
  unbuilt.
- A type's SIZE MEASURE as a declared or derived notion (§3): `List<T>` is
  `n·|T|`, a struct is the sum of its fields; a user type may declare its
  own.
- Reach on user fns, inferred and spellable (§5), so a signature may promise
  `Pure`.
