# Identity and permissions — probe sources

The sources behind docs/2026_11_27_AUTH.md §3 and §7, each run as a one-file `[bin]` package by the `gate-builder` compiler built from `program` at b2d72c7. The answers are quoted in the proposal.

## `doc_example.av`

```avra
export enum BoardRole { Owner, Editor, Commenter, Viewer }

type Seat<R> = { who: int, role: R, share: int = 0, version: int = 0 }

trait Guarded<R> {
    fn reads(m: Seat<R>) -> bool
    fn creates(m: Seat<R>) -> bool
    fn writes(m: Seat<R>, next: Self) -> bool
    fn removes(m: Seat<R>) -> bool
}

type Board = { id: int = 0, name: string, link: BoardRole? = null }

type Card = { id: int = 0, board: int, author: int, title: string, done: bool = false }

impl Guarded<BoardRole> for Card {
    fn reads(m: Seat<BoardRole>) -> bool { true }
    fn creates(m: Seat<BoardRole>) -> bool {
        match m.role {
            .Owner or .Editor -> true
            .Commenter or .Viewer -> false
        }
    }
    fn writes(m: Seat<BoardRole>, next: Card) -> bool {
        match m.role {
            .Owner or .Editor -> next.author == self.author
            .Commenter -> self.author == m.who && next.author == self.author
            .Viewer -> false
        }
    }
    fn removes(m: Seat<BoardRole>) -> bool {
        match m.role {
            .Owner -> true
            .Editor or .Commenter -> self.author == m.who
            .Viewer -> false
        }
    }
}

impl Board {
    fn admits(m: Seat<BoardRole>, role: BoardRole) -> bool {
        match m.role {
            .Owner -> true
            .Editor -> match role { .Owner -> false, .Editor or .Commenter or .Viewer -> true }
            .Commenter or .Viewer -> false
        }
    }
}

fn readable<T: Guarded<BoardRole>>(m: Seat<BoardRole>, rows: List<T>) -> List<T> { rows.filter(it.reads(m)) }

let c = Card { board: 1, author: 7, title: "a" }
let commenter = Seat { who: 7, role: BoardRole.Commenter }
let stranger = Seat { who: 8, role: BoardRole.Commenter }
let editor = Seat { who: 9, role: BoardRole.Editor }
let b = Board { id: 1, name: "b" }
println("writes own: ${c.writes(commenter, c with { done: true })}, writes other's: ${c.writes(stranger, c with { done: true })}")
println("editor steals authorship: ${c.writes(editor, c with { author: 9 })}, editor removes: ${c.removes(editor)}")
println("editor invites owner: ${b.admits(editor, .Owner)}, editor invites viewer: ${b.admits(editor, .Viewer)}")
println("readable: ${readable(commenter, [c, c]).length}")
```

## `missing_verb.av`

```avra
enum BoardRole { Owner, Viewer }
type Seat<R> = { who: int, role: R }
trait Guarded<R> {
    fn reads(m: Seat<R>) -> bool
    fn removes(m: Seat<R>) -> bool
}
type Card = { id: int = 0, author: int }
impl Guarded<BoardRole> for Card {
    fn reads(m: Seat<BoardRole>) -> bool { true }
}
println("${Card { author: 1 }.reads(Seat { who: 1, role: BoardRole.Viewer })}")
```

## `or_bool.av`

```avra
enum Role { Owner, Editor, Viewer }
fn writes(r: Role, mine: bool) -> bool { r is .Owner or mine }
println("${writes(.Owner, false)}")
```

## `is_bool.av`

```avra
enum Role { Owner, Editor, Viewer }
fn writes(r: Role, mine: bool) -> bool { r is .Owner || mine }
println("${writes(.Viewer, true)}")
```

## `any_free.av`

```avra
fn ok() -> bool { any([true, false]) }
println("${ok()}")
```

## `any_method.av`

```avra
let xs = [1, 2, 3]
println("${xs.any(it > 2)} ${xs.all(it > 0)}")
```

## `catchall.av`

```avra
enum Role { Owner, Editor, Viewer }
fn writes(r: Role) -> bool {
    match r {
        .Owner -> true
        .Editor -> true
        _ -> false
    }
}
println("${writes(.Viewer)}")
```

## `missing_arm.av`

```avra
enum Role { Owner, Editor, Viewer, Commenter }
fn writes(r: Role) -> bool {
    match r {
        .Owner or .Editor -> true
        .Viewer -> false
    }
}
println("${writes(.Viewer)}")
```

## `rest_arm.av`

```avra
enum Role { Owner, Editor, Viewer }
fn writes(r: Role) -> bool {
    match r {
        .Owner -> true
        rest -> false
    }
}
println("${writes(.Viewer)}")
```

## `generic_trait.av`

```avra
enum BoardRole { Owner, Editor, Viewer }
type Member<R> = { who: int, role: R }
trait Guarded<R> {
    fn reads(m: Member<R>) -> bool
}
type Card = { id: int = 0, board: int, author: int, title: string }
impl Guarded<BoardRole> for Card {
    fn reads(m: Member<BoardRole>) -> bool { true }
}
let c = Card { board: 1, author: 7, title: "a" }
println("${c.reads(Member { who: 7, role: BoardRole.Viewer })}")
```

## `generic_rule.av`

```avra
enum BoardRole { Owner, Editor, Viewer }
type Seat = { who: int, role: BoardRole }
trait Guarded {
    fn reads(m: Seat) -> bool
}
type Card = { id: int = 0, author: int }
impl Guarded for Card { fn reads(m: Seat) -> bool { self.author == m.who } }
fn visible<T: Guarded>(m: Seat, rows: List<T>) -> List<T> { rows.filter(it.reads(m)) }
let rows = [Card { author: 1 }, Card { author: 2 }, Card { author: 1 }]
println("${visible(Seat { who: 1, role: .Viewer }, rows).length}")
```

## `self_trait.av`

```avra
enum BoardRole { Owner, Editor, Viewer }
type Seat = { who: int, role: BoardRole }
trait Guarded {
    fn writes(m: Seat, next: Self) -> bool
}
type Card = { id: int = 0, author: int }
impl Guarded for Card {
    fn writes(m: Seat, next: Self) -> bool { self.author == m.who }
}
println("${Card { author: 1 }.writes(Seat { who: 1, role: .Viewer }, Card { author: 1 })}")
```

## `in_mark.av`

```avra
type Card = { id: int = 0, @in board: int }
println("x")
```

## `refusal.av`

```avra
enum Refusal {
    Unauthenticated
    NotFound
    Forbidden(rule: string)
    Ended
}
fn status(r: Refusal) -> int {
    match r {
        .Unauthenticated or .Ended -> 401
        .NotFound -> 404
        .Forbidden(_) -> 403
    }
}
println("${status(.Forbidden("writes"))} ${status(.NotFound)}")
```

## `bench_rule.av`

```avra
use @std.time.{now_ns}

enum BoardRole { Owner, Editor, Commenter, Viewer }
type Seat = { who: int, role: BoardRole }
type Card = { id: int = 0, board: int, author: int, title: string, done: bool = false }

impl Card {
    fn reads(m: Seat) -> bool { true }
    fn writes(m: Seat) -> bool {
        match m.role {
            .Owner or .Editor -> true
            .Commenter or .Viewer -> self.author == m.who
        }
    }
}

fn role_writes(r: BoardRole) -> bool {
    match r {
        .Owner or .Editor -> true
        .Commenter or .Viewer -> false
    }
}

let n = 1000000
let rows = [Card { id: i, board: i % 10, author: i % 97, title: "t" } for i in 0..n]
let m = Seat { who: 5, role: .Viewer }

let t0 = now_ns()
mut plain = 0
for c in rows { if c.author >= 0 { plain = plain + 1 } }
let t1 = now_ns()
mut ok = 0
for c in rows { if c.writes(m) { ok = ok + 1 } }
let t2 = now_ns()
let hoisted = role_writes(m.role)
mut ok2 = 0
for c in rows { if hoisted || c.author == m.who { ok2 = ok2 + 1 } }
let t3 = now_ns()
let readable = rows.filter(it.writes(m))
let t4 = now_ns()
println("rows ${n}: bare loop ${(t1 - t0) / n} ns/row (${plain})")
println("rule per row: ${(t2 - t1) / n} ns/row (${ok})")
println("hoisted role, row test: ${(t3 - t2) / n} ns/row (${ok2})")
println("filter by rule: ${(t4 - t3) / n} ns/row (${readable.length})")
```

## `bench_hot.av`

```avra
use @std.time.{now_ns}

enum BoardRole { Owner, Editor, Commenter, Viewer }
type Seat = { who: int, role: BoardRole }
type Card = { id: int = 0, board: int, author: int, title: string, done: bool = false }

impl Card {
    fn writes(m: Seat) -> bool {
        match m.role {
            .Owner or .Editor -> true
            .Commenter or .Viewer -> self.author == m.who
        }
    }
}

let rows = [Card { id: i, board: i % 10, author: i % 97, title: "t" } for i in 0..1000]
let seats = [Seat { who: 5, role: .Viewer }, Seat { who: 5, role: .Editor }]
let reps = 2000
let t0 = now_ns()
mut plain = 0
for r in 0..reps { for c in rows { if c.author == 5 { plain = plain + 1 } } }
let t1 = now_ns()
mut ok = 0
for r in 0..reps { for c in rows { if c.writes(seats[r % 2]) { ok = ok + 1 } } }
let t2 = now_ns()
let n = reps * 1000
println("hot, ${n} checks: field compare ${(t1 - t0) * 10 / n} dns/row (${plain}), rule ${(t2 - t1) * 10 / n} dns/row (${ok})")
```

## `bench_door.av`

```avra
use @std.time.{now_ns}
use @std.http_session.{Signer, Session}

type Seat = { who: int, role: int }

let s = Signer { key: "0123456789abcdef0123456789abcdef".bytes() }
let session = Session { signer: s, max_age: 3600 }
let cookie = session.issued("sid:Zm9vYmFyYmF6cXV4", 100).value
let n = 100000
let t0 = now_ns()
mut opened = 0
for i in 0..n { if session.opened(cookie, 200) != null { opened = opened + 1 } }
let t1 = now_ns()
mut members: Map<string, Seat> = {}
for i in 0..10000 { members.set("${i % 100}:${i}", Seat { who: i, role: i % 4 }) }
let t2 = now_ns()
mut found = 0
for i in 0..n { if members.get("${i % 100}:${i % 10000}") != null { found = found + 1 } }
let t3 = now_ns()
println("signed session opened: ${(t1 - t0) / n} ns each (${opened})")
println("membership map probe, key built: ${(t3 - t2) / n} ns each (${found} of ${n})")
```

## `bench_row.av`

```avra
use @std.time.{now_ns}
use @std.sqlite.open.{Db}

fn run(db: Db) -> string {
    let _ = db.exec("CREATE TABLE session (id INTEGER PRIMARY KEY, principal INTEGER, idle_until INTEGER)")
    let _ = db.exec("CREATE TABLE member (share INTEGER, who INTEGER, role INTEGER, PRIMARY KEY (share, who))")
    let _ = db.exec("WITH RECURSIVE c(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM c WHERE i < 100000) INSERT INTO session SELECT i, i % 5000, 9999999999 FROM c")
    let _ = db.exec("WITH RECURSIVE c(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM c WHERE i < 100000) INSERT INTO member SELECT i % 1000, i, i % 4 FROM c")
    let s? = match db.prepare("SELECT principal FROM session WHERE id = ? AND idle_until > ?") { .Ok(s) -> s, .Err(_) -> null } else { return "prepare failed" }
    let m? = match db.prepare("SELECT role FROM member WHERE share = ? AND who = ?") { .Ok(m) -> m, .Err(_) -> null } else { return "prepare failed" }
    let n = 100000
    let t0 = now_ns()
    mut found = 0
    for i in 0..n {
        let _ = s.reset()
        let _ = s.bind_int(1, (i * 7919) % 100000 + 1)
        let _ = s.bind_int(2, 1000)
        if s.step() catch false { found = found + 1 }
    }
    let t1 = now_ns()
    mut seats = 0
    for i in 0..n {
        let w = (i * 7919) % 100000 + 1
        let _ = m.reset()
        let _ = m.bind_int(1, w % 1000)
        let _ = m.bind_int(2, w)
        if m.step() catch false { seats = seats + 1 }
    }
    let t2 = now_ns()
    "session row by id: ${(t1 - t0) / n} ns (${found} of ${n}); seat by (share, who): ${(t2 - t1) / n} ns (${seats} of ${n})"
}

match Db.memory() {
    .Ok(db) -> println(run(db)),
    .Err(_) -> println("no db"),
}
```

## `principals.av`

```avra
export enum PrincipalKind { User, Service, Agent, Anonymous }
export type Principal = { id: int, kind: PrincipalKind }
enum BoardRole { Owner, Editor, Commenter, Viewer }
type Seat<R> = { who: int, role: R }
type BoardMember = { share: int, who: int, role: BoardRole }
type Card = { id: int = 0, author: int }

impl Card {
    fn writes(m: Seat<BoardRole>) -> bool {
        match m.role {
            .Owner or .Editor -> true
            .Commenter or .Viewer -> self.author == m.who
        }
    }
}

fn seat(rows: List<BoardMember>, p: Principal, share: int) -> Seat<BoardRole>? {
    let row? = rows.find(it.share == share && it.who == p.id) else { return null }
    Seat { who: p.id, role: row.role }
}

let alice = Principal { id: 1, kind: .User }
let ingest = Principal { id: 2, kind: .Service }
let triage = Principal { id: 3, kind: .Agent }
mut rows = [BoardMember { share: 9, who: 1, role: .Owner }]
let before = seat(rows, ingest, 9) == null
rows.push(BoardMember { share: 9, who: 2, role: .Editor })
rows.push(BoardMember { share: 9, who: 3, role: .Commenter })
let c = Card { author: 1 }
println("ingest before grant: ${if before { "none" } else { "seat" }}")
println("ingest writes: ${c.writes(seat(rows, ingest, 9)!)}, triage writes alice's card: ${c.writes(seat(rows, triage, 9)!)}")
rows = rows.filter(it.who != 2)
println("ingest after revoke: ${if seat(rows, ingest, 9) == null { "none" } else { "seat" }}")
```

## `named_in_rule.av`

```avra
enum BoardRole { Owner, Viewer }
type Seat<R> = { who: int, role: R }
const ingest_service: int = 2
type Card = { id: int = 0, author: int }
impl Card {
    fn writes(m: Seat<BoardRole>) -> bool {
        match m.role {
            .Owner -> true
            .Viewer -> m.who == ingest_service
        }
    }
}
println("${Card { author: 1 }.writes(Seat { who: 2, role: BoardRole.Viewer })}")
```
