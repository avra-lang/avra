# Fibers — the tour

Part I: one program that touches every piece of
docs/2026_09_22_FIBERS_DESIGN.md. Part II: three programs that carry
the same scope algebra to the cores, the GPU and a cluster
(docs/2026_09_22_BEND_LAWS_PARALLEL_AND_BEYOND.md). Syntax that does
not exist yet is the design's proposal; everything else is today's
Avra.

# Part I — waiting on the world

## The program: a shop's order service

```avra
//! The order service: HTTP in, sqlite for orders, a supplier API out,
//! a background mailer. Every piece of the fiber design appears once.
use @std.http.{Request, Response, text, json}
use @std.http.server.{Server, serve}
use @std.http.client.{get}
use @std.sqlite.{Db, open}
use @std.task.{Task, Channel, all, race, within, Cancelled, TimedOut}
use @std.time.{ms, secs}

type Order = { id: int, sku: string, qty: int, email: string }
type Stock = { sku: string, left: int }
type Mail = { to: string, body: string }

type Shop = {
    db: Db,
    mail: Channel<Mail>,            // (8) bounded: backpressure is built in
    reserved: Cell<int>,            // (10) shared across handlers, explicitly
}

// ── main: the root scope ──────────────────────────────────────────
fn main() -> Result<int, string> {
    let db = open("shop.db")?
    let shop = Shop { db: db, mail: Channel<Mail>(capacity: 256), reserved: Cell(0) }

    serve(":8080", shop) { server ->              // (2) the SERVER is a scope value
        server.spawn { mailer(server.shop.mail) } // (2) background work, owned by the server
        server.routes {
            .Post("/orders") { mut shop, q -> place(mut shop, q) }
            .Get("/stock/{sku}") { shop, q, sku -> stock(shop, sku) }
        }
    }                                             // (1) server stops -> its tasks are cancelled
}

// ── a handler: runs on its connection's own fiber ─────────────────
fn place(mut shop: Shop, q: Request) -> Response {
    let order = q.json<Order>() catch _ -> return text(400, "bad order")

    within secs(2) {                              // (5) deadline is a property of the scope
        // (6) two independent calls, run together, joined here
        let (stock, price) = all {
            local_stock(shop.db, order.sku)       // (9) sqlite: a BLOCKING row -> helper thread
            supplier_price(order.sku)             // (7) network: parks this fiber only
        }?

        atomic {                                  // (11) no pause point may appear in here
            if shop.reserved.get() + order.qty > stock.left {
                return text(409, "out of stock")
            }
            shop.reserved.set(shop.reserved.get() + order.qty)
        }
        errdefer shop.reserved.set(shop.reserved.get() - order.qty)  // (4) runs on cancel too

        let id = save(shop.db, order, price)?     // (9) blocking row, offloaded
        shop.mail.send(Mail { to: order.email, body: "order ${id}" })  // (8) parks if full
        text(201, "order ${id}")
    } catch {
        .TimedOut -> text(504, "took too long")   // (5) the deadline, as an ordinary failure
        e -> text(500, e.message())
    }
}

// ── a race: the first mirror to answer wins, the losers are cancelled
fn supplier_price(sku: string) -> Result<int, string> {
    race {                                        // (6)
        get("https://eu.supplier.com/price/${sku}")
        get("https://us.supplier.com/price/${sku}")
    }?.body.text().parse_int() ?? fail "no price"
}

// ── background: a channel consumer with select ───────────────────
fn mailer(inbox: Channel<Mail>) {
    mut batch: List<Mail> = []
    loop {
        select {                                  // (8)
            m = inbox.receive() -> match m {
                mail? -> batch.push(mail)
                null -> { flush(batch); return }  // channel closed and drained
            }
            _ = after(secs(5)) -> {               // flush a partial batch every 5 s
                flush(batch)
                batch = []
            }
        }
    }
}

fn flush(batch: List<Mail>) {
    defer log("flushed ${batch.length}")          // (4) runs even if cancelled mid-send
    for m in batch { smtp_send(m) }               // (7) each send parks, never blocks the thread
}

// ── leaf work ─────────────────────────────────────────────────────
fn local_stock(db: Db, sku: string) -> Result<Stock, string> {
    db.one<Stock>("select sku, left from stock where sku = ?", sku)
}

fn save(db: Db, o: Order, price: int) -> Result<int, string> {
    db.insert("insert into orders(sku, qty, email, price) values(?,?,?,?)", o.sku, o.qty, o.email, price)
}

fn stock(shop: Shop, sku: string) -> Response {
    let s = local_stock(shop.db, sku) catch _ -> return text(404, "no such sku")
    json(200, s)
}
```

## What the compiler says about it

Refusals: mistakes you cannot write.

```
error[F2101]: a task cannot outlive the block that spawned it
  --> shop.av:88
   |  fn start(url: string) -> Task<Response, HttpError> { spawn { get(url) } }
   |                                                      ^^^^^^^^^^^^^^^^^ joined at this `}`
   = help: spawn into an owner that lives long enough: `server.spawn { … }`

error[F2102]: `atomic` holds no pause point — `send` may park this task
  --> shop.av:52
   |  atomic { shop.mail.send(m) }
   = help: move the send after the `atomic` block
```

Hints: speedups it offers, never takes silently (decision 3, option C).

```
hint[H0301]: `local_stock` and `supplier_price` are independent — run them together
  --> shop.av:40
   |  let stock = local_stock(shop.db, order.sku)?
   |  let price = supplier_price(order.sku)?
   = fix: let (stock, price) = all { local_stock(…), supplier_price(…) }?
```

Visible magic (P7): `avra explain` shows what the compiler knows.

```
$ avra explain shop.av --tasks
fn place          may pause: all, send, save (offloaded), local_stock (offloaded)
                  atomic region 47–52: pause-free ✓
                  frame: exact, 1.8 KiB (no recursion, no dynamic calls)
fn mailer         may pause: receive, after, flush
                  frame: exact, 2.4 KiB
fn supplier_price frame: guarded stack (calls through a fn value in `get`)
scheduler:        linked — main spawns (the server, the mailer)
```

Live, on a running process (`kill -QUIT` or `avra tasks <pid>`):

```
main                                   waiting: server
└─ server :8080                        412 connections
   ├─ mailer                           waiting: select (inbox, timer 3.1 s)
   ├─ conn 10.0.0.4:51022              waiting: all
   │  ├─ local_stock                   on helper thread 2 (sqlite)
   │  └─ supplier_price                waiting: race
   │     ├─ get eu.supplier.com        waiting: read fd 31
   │     └─ get us.supplier.com        waiting: read fd 32
   └─ … 411 more
```

## The test: deterministic, virtual time

```avra
spec "place" {
    given "a supplier slower than the deadline" {
        let shop = test_shop(stock: 5)
        fake_route("https://eu.supplier.com/price/{sku}", delay: secs(3), answer: "10")
        fake_route("https://us.supplier.com/price/{sku}", delay: secs(3), answer: "11")

        then "the order times out and the reservation is undone" {
            let r = place(mut shop, post_json("/orders", order(qty: 2)))
            expect(r.status == 504)
            expect(shop.reserved.get() == 0)      // the errdefer ran on the timeout
            expect(elapsed() == secs(2))          // virtual time: the test took ~0 ms
        }
    }

    given "two orders racing for the last unit" {
        let shop = test_shop(stock: 1)
        then "exactly one wins, under every interleaving" {
            let (a, b) = all {
                place(mut shop, post_json("/orders", order(qty: 1)))
                place(mut shop, post_json("/orders", order(qty: 1)))
            }
            expect([a.status, b.status].sorted() == [201, 409])
        }
    }
}
```

```
$ avra test shop
place / two orders racing … explored 1,204 interleavings ✓
place / supplier slower … ✓ (virtual 2.000 s, real 3 ms)
12/12 passed · seed 0x5eed1e55
```

Delete the `atomic` and replace `Cell` with a read-then-await-then-write:

```
place / two orders racing … FAILED at interleaving 37 (seed 0x5eed1e55)
  both reserved the last unit: task A paused at `all` (line 43) between
  reading `reserved` (line 41) and writing it (line 48)
  replay: avra test shop --seed 0x5eed1e55 --case "two orders racing"
```

## How the pieces interact

| # | Piece | Where | Leans on |
|---|---|---|---|
| 1 | Every block is a scope | `serve`'s block, `within`, `all` | 4: a cancelled child runs its `defer`s |
| 2 | Spawn into an owner | `server.spawn { mailer }` | 1: the server's end cancels the mailer |
| 3 | No colouring | `place` is a plain `fn` | 7, 9: pausing is the runtime's, not the signature's |
| 4 | Cancellation = a failure at a pause point | `errdefer` in `place`, `defer` in `flush` | 5, 6: deadlines and race losers cancel through it |
| 5 | Deadlines on scopes | `within secs(2)` | 4: `.TimedOut` arrives on `catch` like any error |
| 6 | `all` / `race` | stock+price, the two mirrors | 1: both are scopes; `race` cancels its losers (4) |
| 7 | Pausing I/O | `get`, `smtp_send` | parks the fiber; the thread serves other connections |
| 8 | Bounded channels + `select` | `mail`, `mailer` | 7: a full channel parks the sender (backpressure) |
| 9 | Blocking rows offloaded | sqlite calls | the row's effect column; no annotation in the source |
| 10 | Shared state is explicit | `Cell<int>` in `Shop` | values cross tasks as copies; only `Cell` shares |
| 11 | `atomic { }`, checked | the reservation | 3: the compiler knows every pause point without colouring |
| 12 | Exact-size frames | `explain --tasks` | the whole call graph; guarded stack as fallback |
| 13 | Compiler hints | H0301 | same fact as 11: which calls are independent |
| 14 | Deterministic tests, virtual time | the spec | 5: deadlines on a virtual clock; 11: races found, not hoped |
| 15 | Pay for what you use | "scheduler: linked" | a program with no `spawn` links none |
| 16 | Task tree | `avra tasks <pid>` | 1: every task has an owner, so the tree is total |

The load-bearing chain: **scopes (1) make cancellation (4) total, cancellation
makes deadlines (5) and `race` (6) safe, and pause points being a compiler fact
(3) is what makes `atomic` (11), the hints (13) and the explored tests (14)
possible.**


---

# Part II — one scope algebra, four placements

Part I waits on the world. Part II computes. The claim that makes the
two one design: **a scope is a scope wherever its work runs.** Joining
at `}`, cancellation at a pause point, deadlines, `all`/`race`, the
task tree and the deterministic test mode are the SAME for all four
placements. What changes per placement is the PROOF the compiler
demands before it lets the work go there.

| placement | spelled | runs on | the compiler must prove | first at |
|---|---|---|---|---|
| fiber | `spawn { }` | the calling thread, interleaved | nothing: copies cross, `atomic` guards | Part I |
| cores | `parallel { }`, `par for` | a work-stealing pool | the FORK LAW: no world reach, no `mut` capture | Program A |
| vector / device | `par for` over the KERNEL FRAGMENT, `on .gpu { }` | SIMD lanes, or a GPU | the fragment: flat numbers, no allocation, no recursion | Program B |
| nodes | `cluster.spawn { }`, `on rank(r) { }` | other machines | every crossing value is PLAIN DATA (serialisable) | Program C |

Placement is a SCOPE PROPERTY, like a deadline: `within secs(2) { }`
bounds time, `on .gpu { }` pins place. Unpinned work is placed by the
cost model (docs/2026_09_21_COST_MODEL.md): a task whose derived cost
is under the transfer cost stays where it is. Every placement decision
is printed by `explain` (P7) and can be pinned (P8).

## Program A — fork-join on the cores (Bend-style)

```avra
//! Parallel sort and a scan: the recursion shape Bend's benchmarks
//! use, with the balance kept by the compiler instead of the author.
use @std.task.{parallel}

/// Split, sort both halves on different cores, merge.
fn sort(xs: List<int>) -> List<int> {
    if xs.length <= 2048 { return xs.sorted_small() }   // the grain: below it a fork costs more than it saves
    let mid = xs.length / 2
    parallel {                                          // (A1) a scope: both halves join at `}`
        let lo = sort(xs.slice(0, mid))
        let hi = sort(xs.slice(mid, xs.length))
    }
    merge(lo, hi)                                       // (A2) lo and hi are owned, bound after the block
}

/// Every element's distance to the nearest centroid, all cores.
fn nearest(points: List<Point>, centroids: List<Point>) -> List<int> {
    [closest(p, centroids) par for p in points]         // (A3) the compiler halves the index space
}

/// A sum whose answer is identical on 1 core or 64.
fn total(xs: List<float>) -> float {
    [x par for x in xs].reduce(0.0, add)                // (A4) a FIXED reduction tree
}

law add_assoc_int {                                     // (A5) the law that licenses reordering
    for a: int, b: int, c: int
    (a + b) + c == a + (b + c)
}
```

What the compiler says:

```
error[F2110]: a forked body writes a capture — two lanes would race on `seen`
  --> sort.av:31
   |  parallel { let a = walk(left, mut seen)  let b = walk(right, mut seen) }
   = help: answer the sets and union them after the block: `seen = a.union(b)`

error[F2111]: a forked body reaches the world through `avra_io_write`
   = help: fork the computation, print after the join

$ avra explain sort.av --parallel
fn sort       fork: 2 ways, grain 2048 (cost model: 1 fork ≈ 1.1k compares)
              retains inside forks: 0 (arguments are only read)
fn nearest    par for: halving to 64 leaves (cores 16), kernel fragment ✓ -> SIMD 4×f64
fn total      par for + reduce: FIXED TREE, 1024 leaves — bit-identical for any core count
              float `add` is not associative: order is pinned, never reassociated
```

- **A1 — `parallel` is a scope.** A trap on one lane cancels the other
  and re-raises at `}`, exactly like Part I's `all`.
- **A3 — balance is the compiler's job.** Bend asks the author to keep
  forks balanced. `par for` halves the INDEX SPACE, so balance holds by
  construction. Recursive forks (A1) are balanced by work stealing.
- **A4 + A5 — reproducible AND fast.** GPU and threaded reductions are
  nondeterministic everywhere else because floats reassociate by
  thread count. Here the reduction tree is fixed by the data length,
  never the worker count: same bits on a laptop and a cluster. Where a
  `law` proves associativity (ints), the compiler may reshape the tree
  freely. The law is what unlocks the optimisation.

## Program B — vectors and the GPU

```avra
//! Softmax and a matmul: the kernel fragment on SIMD lanes and on a device.
use @std.tensor.{Tensor, zeros}

/// One row-wise softmax. Two `par for`s the compiler FUSES into one pass.
fn softmax<R: const, C: const>(x: Tensor<float, [R, C]>) -> Tensor<float, [R, C]> {
    [row_softmax(x.row(r)) par for r in 0..R]          // (B1) rows in parallel
}

fn row_softmax<C: const>(row: Tensor<float, [C]>) -> Tensor<float, [C]> {
    let m = row.max()
    let e = [exp(v - m) par for v in row]              // (B2) SIMD lanes
    let s = e.sum()
    [v / s par for v in e]                             // (B3) fused with B2: one read of `row`
}

fn matmul<M: const, K: const, N: const>(
    a: Tensor<float, [M, K]>, b: Tensor<float, [K, N]>,
) -> Tensor<float, [M, N]> {
    on .gpu {                                          // (B4) placement pinned: a scope property
        [dot(a.row(i), b.col(j)) par for i, j in 0..M, 0..N]
    }
}

fn main() {
    let a = zeros<float, [512, 784]>()
    let w = zeros<float, [784, 10]>()
    let y = softmax(matmul(a, w))                      // (B5) shapes checked at compile time
    let bad = matmul(w, a)                             // refused, below
}
```

What the compiler says:

```
error[F2120]: shapes disagree — `matmul` wants [K, N] with K = 10, this is [512, 784]
  --> nn.av:28
   |  let bad = matmul(w, a)
   = help: did you mean `matmul(a, w)`?

error[F2121]: this `par for` body allocates through `avra_array_push`, so it runs on the CPU
  --> nn.av:19
   = note: `on .gpu` requires the kernel fragment: flat numbers, no allocation, no recursion
   = help: write into the answer slot instead of building a list

$ avra explain nn.av --kernels
fn row_softmax  par for (B2) + (B3): FUSED, 1 pass, SIMD 8×f32 (NEON 2×4), no allocation
fn matmul       on .gpu: kernel ✓  target NVPTX sm_90, 512×10 threads, tile 16×16
                inputs: a (1.5 MiB) b (30 KiB) copied; unified memory: no
fn softmax      par for over rows: cores (cost 10 rows < GPU launch cost)
```

- **B2/B3 — vectorisation is a checked CLAIM, not a hope.** Auto-
  vectorisers fail silently; intrinsics are fast and unreadable. Here a
  `par for` over the fragment either vectorises or `explain` says which
  line stopped it. Fusion is legal because the fragment is pure.
- **B4 — one language, one compiler.** No Python orchestrating, no
  separate CUDA source. The kernel is emitted from the same LLVM module
  through the NVPTX target (Bend doc §5), and the compiler has already
  certified the body.
- **B5 — shapes are const generics,** settled at comptime. The useful
  half of dependent types without the half FULL_SPEC 14.3 rules out.

## Program C — training across machines and GPUs

```avra
//! Data-parallel training of a small MLP: 4 nodes × 8 GPUs, elastic,
//! checkpointed, reproducible. Every Part I and Part II idea at once.
use @std.task.{within, all, Cancelled, TimedOut}
use @std.cluster.{Cluster, Rank, join_cluster}
use @std.tensor.{Tensor}
use @std.data.{Shards}
use @std.time.{secs}

type Params = { w1: Tensor<float, [784, 256]>, w2: Tensor<float, [256, 10]> }
type Batch  = { x: Tensor<float, [64, 784]>, y: Tensor<int, [64]> }

@derive(Grad)                                             // (C1) generates `loss_grad`
fn loss(p: Params, b: Batch) -> float {
    cross_entropy(softmax(matmul(relu(matmul(b.x, p.w1)), p.w2)), b.y)
}

law loss_finite {                                         // (C2) checked on generated batches
    for p: Params, b: Batch
    loss(p, b).is_finite()
}

fn main() -> Result<int, string> {
    let cluster = join_cluster("train.toml")?             // (C3) the cluster is an OWNER, like the server
    let data = Shards("s3://mnist", ranks: cluster.size)

    durable "run-17" {                                    // (C4) checkpointed at each step's `}`
        mut p = init_params(seed: 17)
        for step in 0..10_000 {
            let grads = all {                             // (C5) one task per rank, joined here
                [cluster.spawn(on: rank(r)) { local_step(p, data.shard(r), step) } par for r in 0..cluster.size]
            }?
            p = sgd(p, grads.mean_fixed_tree(), lr: 0.01) // (C6) same bits for any rank count
        }
        save(p, "mnist.params")
    }
}

/// Runs on one rank: 8 GPUs, overlapping the gradient exchange with compute.
fn local_step(p: Params, shard: Shard, step: int) -> Result<Params, string> {
    within secs(30) {                                     // (C7) a straggler is a timeout, not a hang
        let parts = all {
            [on .gpu(g) { loss_grad(p, shard.batch(step, g)).grad } par for g in 0..8]
        }?
        parts.mean_fixed_tree()                           // (C6) again, inside the node
    }
}
```

What happens when things go wrong, all by the Part I rules:

- **A node dies.** Its task fails -> the `all` at C5 fails -> the
  `durable` scope restarts the step from the last checkpoint with the
  ranks still alive (`Shards` re-deals). Elasticity is cancellation +
  a durable scope, not a separate framework.
- **A node is slow.** C7's `within` fails it with `.TimedOut`, the
  same failure as a dead node, with the same recovery.
- **A value cannot cross.** `cluster.spawn` demands plain data. A
  capture holding a `Db` or a `Cell` is refused: `F2130: a task sent to
  another machine captures `db`, which holds a local handle`.

What the compiler says:

```
$ avra explain train.av --placement
fn main        durable "run-17": checkpoint = { p, step } (1.6 MiB), at C4's `}` per step
               cluster.spawn: crossing values p (0.8 MiB), shard handle (plain) ✓
fn local_step  on .gpu(g) ×8: kernel ✓ (loss_grad: 6 fused kernels, 0 host round trips)
               exchange: mean_fixed_tree over 8 devices, then 4 nodes — ring, overlapped
               with the next batch's forward pass (hint H0302 applied: you wrote `all`)
fn loss        C2 loss_finite: checked (2,000 generated batches), no counterexample

hint[H0302]: the gradient exchange does not depend on the next batch —
             start the next forward pass before `mean_fixed_tree` finishes
   = fix: move `shard.batch(step + 1, g)`'s load into the `all`
```

And the test: a 4-node × 8-GPU run SIMULATED in one process, on virtual
time, with faults injected by seed (FoundationDB-style):

```
$ avra test train --simulate "nodes: 4, gpus: 8, faults: kill(1)@step 3, slow(2)@step 5"
train / survives a dead node … ✓  (restarted step 3 from checkpoint, 3 ranks)
train / survives a straggler … ✓  (rank 2 timed out at 30.000 s virtual)
train / reproducible         … ✓  params bit-identical: 4 nodes vs 3 nodes vs 1 node
3/3 passed · seed 0x7ea1 · virtual 41 min, real 2.1 s (GPUs simulated on the CPU pool)
```

## How Part II leans on Part I

| Part I piece | what it becomes when work computes |
|---|---|
| every block is a scope | `parallel { }`, `on .gpu { }`, `durable { }`, `cluster.spawn` all join at `}` |
| cancellation at a pause point | a dead node, a straggler, a trapping lane: one failure, one recovery path |
| `within` | straggler detection |
| spawn into an owner | `cluster.spawn` (the cluster owns remote tasks as the server owns connections) |
| values cross as copies | across cores: free; across machines: serialisation is the copy |
| `atomic` / pause points as facts | the FORK LAW: work that may run in parallel is proven not to write shared state |
| compiler hints | fusion, overlap (H0302), "this body allocates, so it runs on the CPU" |
| deterministic tests + virtual time | simulated clusters with injected faults, and bit-reproducible training |
| pay for what you use | a program with no `par for` links no pool; no `on .gpu`, no device runtime |

## Recorded, later

- Automatic parallelism for PROVEN read-only calls (decision 3's
  second half), and its compute twin: an un-annotated `for` the
  compiler proves independent, earning a `par for` hint.
- Location transparency for FIBERS (a `Task` whose owner is on another
  machine) — Program C's `cluster.spawn` is its first form.
- Laws over COST: "this step's derived cost fits the GPU's memory".
