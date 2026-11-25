# @model for the task board

Built from UI.md §2.2, §3.3, §3.4, §3.7, §3.8, §16; UI_DERIVATIONS (form
projection, `.without`); SHARING_MODEL §4.3 (`state` and `@model` as two
projections of one declaration). Spellings are theirs.

## What exists, what is new

| | Exists | New |
|---|---|---|
| Schema | `@std/db` `@model`: table DDL, `insert`, `find`, `update`, `delete` over @std/sqlite, `id: int = 0` first, `@unique`; the caller passes a `Db` | `access:`, `delete:`, `trash:` arguments; the home (`at`); no `Db` in sight |
| Writers | `@action` for logic | derived NAMED doors: create (`Task.insert(...)`), per-field `update`, `delete` and its `undo` through trash, listed by `explain` (.59.12) |
| Reads | `find(db, id)` | observations: `Task.all()` read in render, filtered by `access`, live, suspends while pending (§3.3) |
| Forms | `form`, `field`, `error_text` components | `form(Task)` creates, `form(t)` edits, `.without(.id)` / `.with(...)` projection (UI_DERIVATIONS) |
| Sync | the change log of #1063 (slots written in place) | device replica, server-pushed diffs, outbox (.59.14); the routes derived from the doors |
| Dev | `avra dev` builds and serves the page | `avra dev` also serves the doors' routes over a dev database |

## The board, before

294 lines. The model is a hand-kept `state`:

    type Todo = { id: string, title: string, done: bool }
    state tasks: List<Todo> = [ four literals ]
    state seq: int = 5
    state synced: Fetch<int> = fetch()
    fn add(title: string)                    // concat, bump seq
    fn marked(t, id, done) -> Todo           // rebuild the list
    fn sync() / counted / synced_words       // a literal POST nobody declares
    row:   on change { c -> tasks = [marked(x, id, c) for x in tasks] }
    row:   on press  { tasks = [x for x in tasks if x.id != id] }
    clear: on press  { tasks = [t for t in tasks if !t.done] }

Nothing persists; "Sync" posts a made-up body.

## The board, after

    @model(at: .device, access: .owner, trash: days(30))
    type Task = { id: int = 0, title: string where it.length in 1..200, done: bool = false }

    component new_task { form(Task) }               // title field + Add; id is the model's

    component task_row(task: Task) {
        item {
            checkbox self.task.title {
                checked: self.task.done
                on change { c -> self.task.update(done: c) }
            }
            button "Remove" { on press { self.task.delete() } }   // undo toast derived (§3.4)
        }
    }

    fn visible() -> List<Task> { [t for t in Task.all() if admits(t)] }    // observed, live
    // footer: [t for t in Task.all() if t.done].length ...
    // clear:  for t in Task.all() { if t.done { t.delete() } }

Gone: `Todo`, `tasks`, `seq`, `add`, `marked`, `sync`, `counted`,
`synced_words`, `Fetch` (~70 lines). Rows stay keyed (`by it.id`, now the
row's own id). `at: .device` makes the board persistent with no server;
`.account` or `.shared` adds the replica and server by changing one word,
and the build prints the sync it adds (§16). The page and `term/` still
mount the same view.

## What the compiler derives from the one declaration

1. Table and migration: DDL from the fields; a migration is the diff
   against the shape stored in `__avra_models__` (additive applies; a
   rename or drop is a printed plan, never guessed).
2. The doors, each running the `access` check, named and printed by
   `avra explain data`; an agent reaches one only when listed (§16).
3. The reads: `Task.all()` is "the tasks I may read"; its read set is what
   the screen observes, so the replica computes exactly that subset (§3.8).
4. The routes and the call from the page: the doors over @std/http, and
   the page's call to a door compiled to the request, one signature on
   both sides (no hand-written client).
5. The form, validation from `where` on both sides, per-field error slots.

## Order of work, each lands alone

1. `@std/db`: `all`, filtered reads, `delete`/`trash`, the migration diff
   (library only; today's explicit `Db` stays as the escape hatch, P8).
2. `access:`/`delete:`/`trash:` and the derived doors (.59.12).
3. `at` (.59.13) so `@model(at: …)` and `state … at` share one tail.
4. Observations in render, then the replica and pushed diffs (.59.14).
   The change log of #1063 is the primitive: a commit logs the cells whose
   slots were written, so a query result held in a cell is re-asked when
   its key appears. Collection writes are not logged (recorded deadline),
   which is why a result is replaced as a whole, not pushed into.
5. `form(Task)` and `.without`; `avra dev` mounts the routes.

## Owner decisions

- **`at` as a contextual literal** (.59.13). Keywords are every
  identifier-shaped grammar literal (F3002), so `at` either becomes
  contextual (recommended) or is reserved and costs every field named `at`.
- **The access-policy shape.** `access: .owner`, `.board` (inherit a
  parent's, §16), or a predicate fn over the row and principal? Nothing
  but `.public` can run until ERRORS' auth shape exists. Recommendation:
  a closed set of named policies plus a predicate fn escape hatch.
- **Where a door runs.** One signature, a query on the server and the
  request in the page (recommended; `explain` says "runs on: server"),
  against an explicit remote marker.
- **Dev database:** on disk under `.avra/`, reset by a flag.

Not claimed: the `where` mark's runtime check lives in the door or the
database; the policy value set; the migration prompt's exact wording.
