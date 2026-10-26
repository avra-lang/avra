# Observations — the client cache

**Status:** design, 2026-10-26, not built. Ticket avra-8sb5.59.27.6.
Read against main `95221334`.
Builds on: UI.md §3.3 (observation vs place), UI_DERIVATIONS §B (the
four `stream` arms) and §C (the message log), CHANNELS (the page
channel), DATA_HTTP_FORMS §5 ("GET is an observation… live, derived").
Out of scope: the device replica (.59.14) and offline writes.
No new keywords: every override below is a component SETTING or a
library verb.

`?` marks an open question for the owner (§4).

---

## 1. The thesis

Every client cache in the survey asks the author to say, by hand, what
a write changed: a key list (TanStack, SWR, Solid), an update fn
(Apollo, Relay) or a type list (urql). That is a second copy of the
handler, and it drifts.

Avra already holds both sides:

- each `get` route's READ SET — the models its handler reads;
- each action's WRITE SET — the models it writes, cascades included.

So invalidation is DERIVED (P10). And the server's database reports
what a commit actually touched, so the derived answer is checked at
run time against the truth, never trusted alone (P7, P9).

**Static for prediction, the commit for truth.** The static sets drive
`explain`, prefetch and optimistic updates. The commit's touched
tables drive every invalidation.

---

## 2. Prior art

What each does by default, and what we take.

| System | Key · dedupe | Fresh when | Back to a page | After a write |
|---|---|---|---|---|
| TanStack Query | array key, hashed · one fetch per key in flight | never (`staleTime` 0); refetch on mount, focus, reconnect | cached value, then refetch | manual `invalidateQueries(key)` |
| SWR | string/array key · 2 s `dedupingInterval` | always revalidates (`revalidateIfStale`, on focus, 5 s throttle) | cached value, then refetch | manual `mutate(key)` |
| Apollo | normalized `__typename:id` · `queryDeduplication` on | forever (`cache-first`) until evicted | cache, no request | `refetchQueries`, `update`/`cache.modify` by hand |
| Relay | normalized global id · network layer | until invalidated, or `queryCacheExpirationTime` | `store-or-network` | updater fns, `invalidateRecord`/`invalidateStore` |
| urql | hash(query, vars) · built in | `cache-first` | cache | AUTO by `__typename` in the mutation result; blind to an EMPTY list |
| LiveView | no client cache: state is server-side | always (server pushes diffs) | re-mount over the socket | server re-renders; PubSub to others |
| Turbo | URL · n/a | snapshot is a preview only | restoration visit = snapshot; app visit = preview, then fetch | the server redirects/streams; broadcasts over Cable |
| Replicache / Zero | client view keyed by row · n/a | always synced; Zero query TTL 5 m (max 10 m) | local, instant | server poke (carries no data), then pull |
| Linear | object pool by UUID · n/a | always synced (delta packets, `lastSyncId`) | local, instant | server delta to every client |
| Elm | none; `RemoteData` in the model | the author decides | the author refetches | the author refetches |
| SolidStart `query` | name + args (JSON, keys sorted) · one per key | preload reused 5 s | history reuses entries | actions revalidate (all by default, or named keys); single-flight returns fresh data in the action response |

| System | Optimistic | Errors · retry | Pages | Eviction | Security lesson |
|---|---|---|---|---|---|
| TanStack | `onMutate` snapshot + rollback, or render `variables`; must `cancelQueries` or a refetch overwrites it | 3 retries, exponential (0 on the server) | infinite query refetches EVERY page in order; `maxPages` | unread for `gcTime` 5 m | a module-level client on the server shares one cache across users |
| SWR | `optimisticData`, `rollbackOnError` | 5 s exponential retry | `useSWRInfinite` | default cache never evicts | SSR needs a cache `provider` per request; logout = clear by hand |
| Apollo | `optimisticResponse` layer, dropped on the real answer | none by default (`RetryLink`) | `keyArgs` + `merge` field policies (a common source of bugs) | none automatic: `gc()`/`evict` by hand | logout needs `resetStore`; an in-flight query can refill the cleared store |
| Relay | `optimisticResponse`/`optimisticUpdater`, auto-rollback | by the network layer | `@connection` | `retain`/`release` + release buffer | one environment per user |
| urql | Graphcache only | `retryExchange` opt-in | Graphcache resolvers | until invalidated | SSR exchange per request |
| LiveView | none (round trip) | reconnect re-mounts | `stream` + temporary assigns | server memory | a long-lived socket keeps a revoked user's view: broadcast `disconnect` on `live_socket_id` |
| Turbo | none | page-level | n/a | small snapshot cache | the Back button shows a private page's snapshot after logout: `turbo-cache-control: no-cache` |
| Replicache / Zero | mutators run locally, REBASED on each pull (rewind, apply patch, replay pending) | the server's answer wins | Zero preloads the first n per shape | Zero TTL | users sharing one `name` share one cache |
| Linear | queued transactions; rollback on reject; disk written only on confirmation | queue resent on reconnect | `partial`/`lazy` per model | lazy hydration | delivery scoped by sync groups (permission) |
| Elm / Solid | by hand / `useSubmission` | by hand | by hand | Solid: 180 s with no subscriber | — |

Sources: TanStack "Important Defaults", "Optimistic Updates", "SSR",
"Infinite Queries"; SWR API; Apollo "Queries", "Authentication",
"Garbage collection"; Relay "Staleness of Data"; urql "Document
caching"; LiveView "Security model"; Turbo handbook "Building";
Replicache "How it works"; Zero "Queries"; Solid Router `query`,
`revalidate`; Linear from community reverse-engineering
(wzhudev/reverse-linear-sync-engine), unofficial.

**What the survey says.** Libraries without the server's help pick a
number (`staleTime`, `dedupingInterval`) and trade requests for
freshness. Sync engines (Linear, Zero, LiveView) are always fresh
because the server pushes. Avra has the push (the page channel) AND the
read sets, so it needs no number for its own models.

---

## 3. The rules

### 3.1 The key

An entry is keyed by **(route, arguments, principal)**, folded as a
fixed-arity record — never a concatenated string.

- *route*: the route's declaration identity, not its URL. A remount at
  another path is the same entry; two routes at one path are not.
- *arguments*: the typed arguments under the route's own wire codec
  (one codec, DATA §7), so `list(page: 1)` and `list()` with that
  default are one entry.
- *principal*: the session's epoch (§3.10). Two users never share an
  entry, even in one tab.
- the answer type's shape hash rides along, so a deploy that changes
  `Task` never reads an old entry as the new type.

Why: TanStack/SWR keys are hand-written arrays that drift from the
fetch; Solid's name + JSON args is right in spirit. Folding is the
encoding-boundary law (CLAUDE.md): two spliced runs collide.

### 3.2 Dedupe

- One request per key in flight. Every read of that key in a turn, in
  any view, shares it (`tasks.list()` read three times is one request).
- No time window. Freshness (§3.3) decides whether a later read asks
  again.
- The answer that STANDS is the one with the highest commit sequence,
  not the last to arrive (today's `Fetch` is latest-ask-wins). This
  removes TanStack's `cancelQueries` race by construction.

Borrows: TanStack's in-flight dedupe. Rejects: SWR's 2 s window, a
number that guesses.

### 3.3 Freshness

An entry is one of three kinds, decided by its read set.

| Read set | Fresh while | Default when not |
|---|---|---|
| **known** (only our models) | the page channel is up and no notice named a model in it | re-ask on reconnect |
| **external** (the handler calls another service) | `fresh:` from the route (default 0) | re-ask on mount, focus, reconnect |
| **unknown** (an opaque call the compiler cannot see through) | never | re-ask on mount, focus, reconnect, and `explain` names it |

- **Known** is the common case: no time constant at all. An entry
  stays fresh indefinitely while live, and goes stale the moment the
  server says so.
- **Channel down = stale.** On reconnect the client sends its last
  sequence; the server answers which models changed since, or "too
  old" (everything stale). LiveView's re-mount, without the full
  re-render.
- Override (P8): the route setting `fresh: minutes(5)` for an external
  read. On a public route (no guard above it) the same value becomes
  the HTTP `max-age`.
- **Revalidation is cheap.** Each answer carries the commit sequence it
  read at, as its ETag. A re-ask sends it; when no table in the route's
  read set changed since, the server answers 304 WITHOUT running the
  handler.

Borrows: Linear/Zero (server push), Relay (fresh until invalidated).
Rejects: TanStack's `staleTime: 0` default — correct when you know
nothing, wasteful when you know everything.

### 3.4 Returning to a page

- A kept entry (§3.9) shows at once. Fresh → no request. Stale → shows,
  and re-asks behind it.
- The `stream` arms: no value yet → `loading`; a value (even while
  re-asking) → `items`/`empty`; a first-load failure → `error`.
- A view that wants to SAY it is re-asking reads `.refreshing` on the
  observation. It never flickers to `loading` by default.
- Revisiting by Back keeps the entries of the last screens in history
  alive (they count as readers), so Back is instant — Turbo's
  restoration visit.

Borrows: SWR/TanStack stale-while-revalidate, Turbo restoration.
Rejects: Turbo's snapshot of the whole page — we keep data, never a
rendered page, so nothing private survives as pixels.

### 3.5 Write → invalidation, derived

1. The compiler computes each action's **write set**: the models its
   handler writes, plus `@cascade` children, plus a `@soft_delete`'s own
   model.
2. The server's database reports what a commit **actually** touched
   (the SQLite update hook names each table). That set, with the commit
   sequence, is the truth.
3. The action's answer carries that set. The CALLING tab marks every
   entry whose read set meets it stale at once — no wait for the push.
4. The commit is pushed as a notice on the channel of every session it
   may concern. Other tabs and users mark the same way. A notice whose
   sequence a tab already applied is dropped.
5. **Single flight.** With the action, the client names the keys it
   holds whose read set meets the write set; the server answers them in
   the same response. One round trip, the Solid model, derived rather
   than listed.

- Raw SQL through `@std/db` is covered: the hook sees every write on
  the connection. Only a write OUTSIDE our database escapes, and the
  read that depends on it is already **external** (§3.3).
- A dev build checks that the runtime sets are within the static ones.
  A miss is a compiler defect, shown in the dev HUD (P7).
- Escape hatch (P8): `tasks.list.refresh()` asks again by hand, for a
  change only the program knows about.

Borrows: urql's automatic invalidation by type, Solid's single flight,
Replicache's poke. Fixes urql's blind spot: our read set is static, so
an EMPTY list is invalidated like any other.

### 3.6 Optimistic updates

Speculation is an OVERLAY, never a mutation of the cache.

- A pending write is a layer over the server entries. What a view shows
  is the server value with the pending layers applied, in order.
- The layer is dropped when an entry holding that row is answered at a
  sequence ≥ the write's commit. A refused write drops its layer and
  the value reverts with no snapshot to restore.
- Whether a write speculates is its IMPACT (DATA §5): `routine` applies
  at once; a `reversible` remove hides the row and offers undo; a
  `destructive` one confirms and waits.
- Derived layers, for `crud` routes:
  - `create` appends to every held list of that model whose filter
    the new row passes (equality filters run on the client), marked
    pending;
  - `update` patches the row by id in every entry holding it;
  - `remove` hides the row by id.
- A hand-written action has no derived layer: it shows pending, not a
  guess. `?` whether it may declare one (a `foresee:` setting).

Borrows: Replicache's rebase (layers replayed over the server truth),
Apollo/Relay's optimistic layer. Rejects: TanStack's snapshot +
rollback, which races refetches and leaves the author to write the
inverse.

### 3.7 Errors and retry

- A read (idempotent, by definition) retries a TRANSIENT failure —
  network, 5xx, 429 with `Retry-After` — 3 times, exponential with
  jitter. It never retries a 4xx.
- A failed re-ask keeps the last value and sets `.failure` beside it;
  only a failure with NO value reaches the `error` arm / `failed {}`.
- A 401 is not an error: it ends the session (§3.10).
- An action is retried after a network failure only when it carries an
  idempotency key (std-action's wire gives one per submission), since
  the server then answers a duplicate with the first receipt.
- Override: route setting `retry: 0`.

Borrows: TanStack's 3 with backoff. Rejects: TanStack's retry on every
error, 4xx included.

### 3.8 Pagination and partial lists

- A page is its own entry; its cursor is an argument. Pages of one
  route share one read set.
- Cursors are KEYSET, read from the model's order (the compiler knows
  the sort key), so a re-ask never shifts rows between pages.
- Invalidation re-asks only the pages a view shows, first to last.
- No normalization. An entry is a query's answer, not a slice of a
  shared object graph. Cross-entry consistency comes from §3.6's by-id
  layers and §3.5's invalidation.

Borrows: TanStack's in-order page refetch and `maxPages`. Rejects:
Apollo's `merge`/`keyArgs` field policies. The replica (.59.14) is
where normalization belongs — a real database, not a merge function.

### 3.9 Eviction

- An entry with a reader is never evicted.
- An unread entry is kept for `kept:` (default 5 minutes), then
  dropped.
- All unread entries share a byte cap (default 16 MB `?`), least
  recently read first. An answer's size is known when it lands.
- The server keeps NO cross-request cache of observations. A server
  render's entries live for that request and travel in the page for
  hydration, then die.
- Override: route setting `kept: minutes(30)`.

Borrows: TanStack `gcTime`, Zero TTL, Solid's idle eviction. Rejects:
SWR's and Apollo's unbounded defaults.

### 3.10 Auth and logout

- **The principal is in the key** (§3.1), so a cache cannot cross users.
  Replicache's per-user `name`, enforced rather than advised.
- **A principal change** (login, logout, a 401, account switch) bumps
  the epoch:
  - every entry of the old epoch is dropped;
  - every request in flight is cancelled, and an answer tagged with the
    old epoch is discarded on arrival — Apollo's "in-flight query
    refills the cleared store", closed;
  - the page channel closes and reopens under the new session.
- **Logout reaches every tab.** The server pushes `session ended` on
  every channel of that session (LiveView's `live_socket_id`
  disconnect).
- **Revoked access is just a write.** Access is the `@owner` chain, so
  the models it reads (`Board`, `Membership`) are in the read set.
  Removing a membership is a write to `Membership`; every observation
  scoped through it re-asks and the server's filter answers the new
  truth. No separate revocation path.
- **Notices leak nothing.** A notice carries model names and a
  sequence, never row data, and goes only to sessions whose guard
  admits that model. `?` ids too.
- **Shared caches never hold a guarded answer.** A route under a guard
  answers `Cache-Control: private, no-store`; only a route with no
  guard above it may be `public`. The compiler knows which is which
  and `explain` says so. (Shared caches keyed on the wrong part of a
  request are how most framework cache-poisoning advisories happen.)
- Nothing is persisted to disk in this design, so logout has nothing
  on disk to clear. The replica will owe that.

Borrows: LiveView (disconnect by session), Replicache (per user),
Apollo (`clearStore`), Turbo (`no-cache` for private pages, made the
default).

### 3.11 Derived fns

`done_count()` reads `tasks.list()`. Per the 10-26 ruling it is a pure
fn the compiler memoizes by read set, so it recomputes exactly when
that entry changes, with no `derived` keyword and no cache of its own.

### 3.12 What `explain` prints

```text
$ avra explain cache board
board.av  observations
  tasks.list()        key route tasks.list · principal       reads Task
                      fresh: live (channel)   kept 5m   private
                      readers: progress, list, done_count()   1 request
  weather.today(city) key route weather.today · city          reads EXTERNAL
                      fresh: 2m (route setting)   kept 5m   public, max-age=120
  report.summary()    reads UNKNOWN (calls render_pdf: opaque)
                      fresh: never — re-asks on mount, focus, reconnect

actions
  tasks.create   writes Task          stales tasks.list()   speculates: append (routine)
  tasks.update   writes Task          stales tasks.list()   speculates: patch by id
  tasks.remove   writes Task          stales tasks.list()   hides by id · undo (reversible)
  boards.remove  writes Board, Task   stales boards.list(), tasks.list()   confirms (destructive)
  archive        writes Task          stales tasks.list()   pending (no derived layer)
```

The dev HUD shows the same live: each entry, its state, its age, the
last notice that staled it, and any runtime/static disagreement.

---

## 4. Open questions for the owner

1. **Notice granularity.** Model names only (recommended for now:
   leaks nothing), or model + row ids (fewer re-asks of `find(id)`,
   but tells a session that a row it cannot see exists)?
2. **Default bounds.** `kept` 5 minutes and a 16 MB cap of unread
   entries?
3. **Hand-written optimism.** May a hand-written action declare a
   layer (a `foresee:` setting), or does it always show pending?
4. **Single flight by default.** Answer the affected observations
   inside the action's response (one round trip, a larger answer), or
   let the notice trigger ordinary re-asks?
5. **External reads.** Default `fresh` 0 (TanStack's choice), or a
   small window such as 30 s?
6. **Dev check strictness.** Is a runtime write outside the static
   write set a dev-HUD warning, or a failing test under `avra test`?
7. **Tabs.** Each tab keeps its own cache and channel (recommended
   now), or tabs share one through a `BroadcastChannel`?
8. **Prefetch on intent.** A screen's read set is known from its
   signature, so a link can prefetch on hover or when it scrolls into
   view. On by default?

---

## 5. What exists, what is new

| Piece | Today | Change |
|---|---|---|
| `Async<T>`, `Fetch<T>` | packages/std-ui/src/app/async.av (latest-ask-wins) | the entry's seat; highest-sequence-wins |
| read sets | features/read_set.av (state per expression) | through route handlers to models; write sets for actions |
| page channel | CHANNELS (designed) | the notice stream: `(sequence, models)`, `session ended` |
| commit truth | `@std/db` over SQLite | the update hook's tables + a commit sequence on each answer |
| `crud` routers | std-db / std-http (#1299 runs the board on one) | derived layers for create, update, remove |
| `explain` | per-router printout (DATA §5) | `explain cache <view>` |

**Order, each lands alone:** keyed entries + dedupe + kept/cap →
commit sequence + ETag/304 → write-set invalidation from the answer →
channel notices + reconnect → optimistic layers → single flight →
`explain cache` and the dev HUD.
