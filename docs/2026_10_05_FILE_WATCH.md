# FILE WATCH — the operating system says what moved

`@std.io.watch`: a set of paths, and a task parked until one of them
moves. No timer, no thread, no second event loop.

## 1. The verb

```avra
use @std.io.watch.{watch}

let w = watch()?
w.add("src/main.av")?          // a file: its content, and its standing
w.add("src")?                  // a directory: its entries
while true {
    match w.next(null)? {      // parks the task; null waits for ever
        .Changes(cs) -> for c in cs { println("${c.path} ${c.what}") }
        .Everything -> println("the host lost count — look at it all")
        .Quiet -> {}           // the wait, or a `within` around it, ran out
    }
}
```

- `watch() -> Result<Watch, IoError>`; `close()` ends it. Every copy is
  one watch (its state rides Cells).
- `add(path)`, `drop(path)`, and `only(paths)` — the set becomes exactly
  these, one mark-and-sweep in C, no diff written by the caller.
- `next(wait: Duration?) -> Result<Seen, IoError>` parks; `taken()`
  never waits.
- `Change { path, what }`, `what` one of `Created`, `Changed`,
  `Removed`, `Unwatched`.

## 2. Laws

- A WATCH IS ONE DESCRIPTOR, readable when something is pending: an
  inotify descriptor on Linux, a kqueue of its own on macOS (a kqueue is
  itself pollable — probed, `outer=1` for every vnode event). The task
  parks on it through the scheduler's poller (`avra_fiber_park_fd`), as
  a socket's reader does. So a file event, a socket and a timer are
  three tasks parked in one poller, and `within` bounds the wait.
- A CHANGE IS THE NET DIFFERENCE SINCE THE LAST LOOK, never an event.
  Events only mark an entry touched; `take` settles each touched entry
  against what stands now. stood/stands: no/yes `Created`, yes/no
  `Removed`, yes/yes and written or replaced `Changed`, no/no nothing.
  A burst is one change by construction; no interval is tuned.
- THE LAST EVENT IS ALWAYS FOLLOWED BY A LOOK. A reader that acts on a
  half-written save is woken again by the write that finishes it.
- A PATH IS A NAME IN ITS PARENT DIRECTORY. Every watched path holds a
  share of one OS watch on its parent, so a save by rename, a delete
  and a later create are all seen — the inode is never the identity.
  An absent file under a standing parent may be watched.
- A FILE ANSWERS CONTENT, A DIRECTORY ANSWERS ENTRIES (a name arriving
  or leaving), on both hosts. A directory watch is not recursive and
  says nothing of writes inside its files.
- A PARENT THAT GOES TAKES ITS WATCHES WITH IT, unless it stands again
  by the next look: each answers `Unwatched` and is forgotten, so `add`
  watches it afresh.
- A LOST COUNT IS SPOKEN: inotify's `IN_Q_OVERFLOW` answers
  `.Everything` and the watch resettles every entry. Never silence.
- A NUL IN A PATH IS REFUSED AT THE CROSSING (`IoError.Holed`).
- A change to mode or ownership alone is no change (macOS reports it;
  the size and write time settle it).

## 3. The hosts

| | mechanism | costs |
|---|---|---|
| Linux | inotify, ONE watch per directory (a file is matched by name in its parent's events): `IN_MODIFY CLOSE_WRITE CREATE DELETE MOVED_FROM MOVED_TO DELETE_SELF MOVE_SELF` | a watch per distinct directory; `ENOSPC` at the user's limit |
| macOS | kqueue `EVFILT_VNODE` on `O_EVTONLY` descriptors: one per directory (`NOTE_WRITE` = entries), one per file (`NOTE_WRITE EXTEND ATTRIB DELETE RENAME`). On a directory event each file under it is checked by inode against its path and re-opened when replaced. | a descriptor per file and per directory; `EMFILE` at the process's limit |
| wasm | none: `next` reaches `avra_fiber_park_fd`, a row with no wasm body, so the build refuses by name | |

FSEvents is refused: it wants CoreServices, a dispatch queue (a second
thread and loop), and coalesces by a latency timer. kqueue joins the
poller the runtime already owns.

Probed on macOS (kqueue vnode flags): append `WRITE EXTEND`; truncate
`ATTRIB` alone; rename-over `DELETE` on the file + `WRITE` on the
directory, path's inode differs from the descriptor's; move-away
`RENAME`; a sibling's write reaches neither; a directory moved `RENAME`.

## 4. The crossing

Package C (`packages/std-io/src/c/std_io_watch.c`), every entry an int:
`avra_io_watch_open/fd/add/drop/mark/sweep/take/slot/what/close`. C
owns the table and hands back SLOT numbers; Avra keeps slot -> path, so
no text crosses outward. No runtime row is added: the park is the
existing `avra_fiber_park_fd`, and the evaluator hosts the package's
externs through the uniform frame.

## 5. The fallback

Where the host refuses a watch (`EMFILE`, `ENOSPC`, a filesystem with no
events), `watch`/`add` answer the errno and the caller decides. `avra
dev` then says so once and looks on an interval; `--interval <ms>` asks
for that outright, and is the only thing the option means.

## 6. `avra dev`

```avra
let _ = p.turn()
while true {
    match p.watch.next(null) { … }      // parked: no CPU between saves
    let _ = p.turn()                    // build; `only(build_inputs)` after
}
```

## 7. Landing

No `rt_sigs` row, so the two-landing law does not bind; the split is
for review and because `dev.av` is not on main yet.
1. `@std.io.watch` + its C + the Makefile's and the Sprite build's
   object lists + tests. Nothing in the compiler calls it.
2. `avra dev` on the watch, polling kept as §5's fallback (on `ui-dev`).
