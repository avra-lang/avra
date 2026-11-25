# Implicit context in Avra: what the tree does today

Read on branch `program` (HEAD b76776889), 2026-11-16. I only read code: nothing was built or run. Paths are relative to the repo root, and `src/` means `packages/std-avrac/src/`. UNKNOWN marks anything reading could not settle.

---

## 1. `within`, end to end

### Grammar
`src/features/tasks/mod.av:63`:
```
primary = "within" limit:expression body:block -> Expr.Within(limit = limit, body = body) @head(limit)
```
`within` is a head that keeps its brace, like `if` and `while`. It is not a lambda. `src/features/tasks/node.av:26-33`:
```
/// `within limit { body }` — the body runs with a deadline arming the
/// calling task: every park under it ends by `limit` from now, and
/// the body answers as written. The body stays INLINE, so `return`
/// and `?` leave through the enclosing fn — the reason this is a head
/// keeping its brace and never a lambda.
export type Within = { limit: ExprId, body: ExprId }
```
History: `within` used to be a `@std/time` template component. FLOW_03 D4 (`docs/2026_10_06_FLOW_03_DESIGN.md:33`) moved it into the tasks feature so the body could stay inline.

### Typing
`src/features/tasks/check.av:12-30`. The answer is `Result<T, TimedOut>`, where `TimedOut` and `Duration` are `@std/time`'s, looked up by package name:
```
fn within_expr_type(mut cx: TypeCx, e: ExprId) -> TypeId {
    ...
            if cx.view.types.shape_of(answer) is .Void { return answers_nothing(cx, body) }
            let late? = time_type(cx, "TimedOut") else { return no_time(cx, e) }
            let span? = time_type(cx, "Duration") else { return no_time(cx, e) }
            if !cx.accepts(limit, span) { return limit_unfit(cx, limit, span) }
            cx.view.types.intern(Type.Res(answer, late))
```
A body that answers `void` is refused (`type.within`).

### Lowering
There are two lowerers in the tree: the old `LowerCx` one (`src/features/tasks/lower.av:22-50`) and the newer `Lowering` one (`src/features/tasks/lowers.av:42-66`). Both have the same shape. Which one the current pipeline uses is UNKNOWN from reading. The newer one, `lowers.av:42-60`:
```
impl Lowers for Within {
    fn lowered(mut cx: Lowering, e: ExprId) -> Reg {
        ...
        let millis = cx.call_fn(Layout.Word, ms, [limit])        // Duration.ms(), the library's own conversion
        let answer = cx.seeded_cell(cx.laid_out(body), cx.hollow_of(body))
        let landing = cx.seeded_cell(Layout.Word, cx.const_int(0))
        cx.loop_start()
        cx.unwritten()
        cx.loop_cond(cx.const_bool(true))
        cx.within_opened(millis, landing)
        cx.stored(answer, cx.lower(self.body))
        cx.within_closed()
        cx.jumped(false)
        cx.loop_end()
        let landed = cx.bin(Layout.Truth, BinOp.Ne, cx.loaded(Layout.Word, landing), cx.const_int(0))
        ... region(landed) { failure_of(whole, timed_out(...)) } else { answered_unless_unwinding(...) }
```
The open and close are a runtime row plus an "ending" that the frame machinery runs on every exit path. `src/core/endings.av:253-270`:
```
    /// A `within`'s turn opened: the deadline scope armed for `millis` milliseconds, its end held by the
    /// turn's scope and whether an unwind landed there kept in `landing`; an unwind inside now leaves
    /// the innermost loop.
    mut fn within_opened(millis: Reg, landing: Reg) {
        let scope = self.call_row(Layout.Word, rt_sig_of("avra_fiber_within")!, [millis])
        self.withins.push(WithinMark { loop: self.loops.get() - 1, floor: self.endings.get().length })
        self.opened()
        self.ends_with(Ending.Landed(scope, landing))
    }
    mut fn within_closed() {
        self.closed()
        ...
```
So the lowering does three things: (a) a runtime call opens a scope on the current task and returns a scope id; (b) the id sits in an `Ending.Landed` that runs `avra_fiber_within_end(id)` when the frame leaves (normal end, `return`, `?`, or unwind); (c) after the one-turn loop, a non-zero landing becomes `Err(TimedOut{limit, frames})`.

### Runtime: where the deadline lives
The deadline is per task. Each `Fiber` record holds a stack of scopes. Nothing is global, and there is no compiler-visible value. `runtime/avra_fiber.c:209-214, 255-270`:
```
// A `within`'s scope on its task: its id, its limit in ns, the scope
// with the earliest limit of it and every scope outside it — the outer
// one on a tie — ...  whether it is a SHIELD SCOPE ...
typedef struct { int64_t id, at; uint32_t first; uint8_t shield; } Scope;
enum { SCOPES = 4 };
...
    int64_t scope_by;       // the scope whose limit passed and whose request stands, else 0
    int64_t deadline;       // the owner's limit, in ns; 0 when no scope may still ask
    uint32_t scopes_n;      // the scopes open, outermost first
    uint32_t armed;         // the scopes below this depth may still ask
    uint32_t owner;         // the armed scope whose limit is `deadline`
    Scope scope[SCOPES];
    Scope* deeper;          // the scopes past the inline ones
    Waiter due;             // the deadline's own waiter
```
Opening a scope, `avra_fiber.c:1340-1364`:
```
static int64_t within_opened(Fiber* f, int64_t ms) {
    ...
    int64_t at = deadline_after(ms < 0 ? 0 : ms);
    int64_t id = AVRA_SCOPE_IDS | ++g_scope_seq;
    uint32_t first = i;
    if (i > 0) {
        uint32_t outer = scope_at(f, i - 1)->first;
        if (scope_at(f, outer)->at <= at) first = outer;
    }
    *scope_at(f, i) = (Scope){ id, at, first, f->shield_depth > 0 };
    f->scopes_n = i + 1;
    ...
```
`avra_fiber.c:3016`: `int64_t avra_fiber_within(int64_t ms) { return within_opened(g_current, ms); }`. It acts on `g_current`, the running task.

### How a deep callee finds the deadline
No callee reads it explicitly. Every park (sleep, join, descriptor wait, wait set) and every cancel point asks `g_current`'s record: `deadline_passed(f)` at `avra_fiber.c:1433-1444`, and the checks at `:2274`, `:2325`, `:2376`, `:2928`, `:2947`. So any code running on that task while the scope is open is subject to it, however deep the call stack. **This is dynamic scoping per task in the runtime.** There is no lexical channel, and the type system does not see it. The fn effect fact `parks`/`spins` (FLOW_03 §3.1) decides only where the compiler places an unwind test after a call.

### Nesting
"EVERY SCOPE KEEPS ITS OWN LIMIT" (`avra_fiber.c:1313-1315`). The task's effective deadline is the earliest limit among the armed scopes, and the outer scope wins a tie (`first` above, `owner_found` at `:1320-1329`). So an inner `within` with a longer limit does not extend the outer one. When the owner's limit passes, `deadline_reached` (`:1412-1427`) sets `scope_by = owner id`, and only the landing whose id matches clears it (`scope_landed`). Every other `within … catch` on the way is passed (FLOW_03 D3 "R1"). A task cancel outranks every scope except a shield scope.

### Scope exit
`scope_ended` at `avra_fiber.c:1376-1389` pops only the innermost scope. Ending any other scope traps (`scope_out_of_order` at `:1369-1374`: "a `within` ended while one inside it stands"). This is LIFO and strictly tied to the frame, enforced because the frame's ending runs it on every exit.

### Spawned tasks
A spawned task inherits exactly one scope record, copied from its spawner. `avra_fiber.c:1452-1463`:
```
// A TASK STARTS UNDER ITS SPAWNER'S LIMIT: one record, the scope whose
// request stands or else the owner, copied whole — its id is the
// spawner's scope's, so no scope of the child's own lands it.
static void scope_inherited(Fiber* child, const Fiber* from) { ... child->deadline = s->at; }
```
It is called from `avra_task_spawn` (`avra_fiber.c:2570-2575`). The evaluator does the same through `avra_vtask_inherits` (`src/compiler/backend/interp_tasks.av:226`). Inheritance is a snapshot at spawn time. The child is not linked live to the parent's scope stack.

### A closure made inside `within` and called after the block ended
Nothing ties the deadline to the closure. A lambda is lifted into its own unit (§3), and the scope lives on the task, not in any value. A closure that runs inside the block, on the same task, sees the deadline. One called after the block ended sees whatever scopes the calling task has open at call time. This follows directly from the per-task design; I did not probe it.

### What the docs say is intended
- `docs/2026_09_22_FIBERS_DESIGN.md:340-345` (§12): "DEADLINES ARE A SCOPE, NEVER A PARAMETER (P6) … a callee the caller does not own (a handler's query) cannot inherit it. `within d { … }` is both: lexically visible, and every park inside — in this task or one it spawns — ends by it. Nested scopes take the earlier deadline; the block restores the outer one however it exits."
- `docs/2026_10_06_FLOW_03_DESIGN.md:75` (§3.4): each scope keeps its own limit, the owner is the earliest limit, a firing is landed only by the scope with that id, and a spawned task starts with one record copied from the owner, "so an inherited deadline unwinds the child to its top."
- `docs/2026_10_05_CHANNELS.md:860`: "`within d { body }` answers `Result<T, TimedOut>` … ALSO DECIDED".

---

## 2. Tasks: what spawn copies, task-local storage, cancellation

### Task-local storage exists: four managed slots plus an id
`runtime/avra_runtime.h:25-33`:
```
// WHAT A TASK CARRIES: a few managed values and its id. The running
// task's stand behind one pointer; `main`'s are the core's own, so a
// program that never spawns has them and links no scheduler.
enum { AVRA_SLOT_ASKER = 0, AVRA_SLOT_FLOW = 1, AVRA_TASK_SLOTS = 4 };
typedef struct { void* slot[AVRA_TASK_SLOTS]; int64_t id; int64_t clock_asks; int64_t clock_holds; } AvraTaskLocal;
extern AvraTaskLocal* avra_task_local;
```
The scheduler swaps the pointer on every switch: `avra_task_local = next->local;` (`avra_fiber.c:1885`, `:1905`). The rows that read and write a slot are at `runtime/avra_runtime.c:4645-4658`:
```
void* avra_task_slot(int64_t key) {            // retained answer, NULL when empty
    if (__builtin_expect((uint64_t)key >= AVRA_TASK_SLOTS, 0)) slot_refused();
    void* v = avra_task_local->slot[key]; ...
void avra_task_slot_set(int64_t key, void* v) { ... retain v, release old ... }
```
They are registry rows `avra_task_slot` and `avra_task_slot_set` (`src/core/runtime_api.av:2398-2422`), with evaluator arms at `src/compiler/backend/interp_tasks.av:819-835` and LowerCx verbs at `src/features/rt.av:789-795`. Slots are released at task end (`avra_fiber.c:2550-2555`) and when a task is abandoned (`:3540`).

The only Avra users I found are tests: `features/tasks/tests/root_slot`, `wait_set` and `tasks_test`. `AVRA_SLOT_ASKER` and `AVRA_SLOT_FLOW` are named in the header, but nothing outside tests uses them (grep). Keys 2 and 3 are unassigned.

**Slots are not inherited at spawn.** `fiber_new` zeroes the record (`avra_fiber.c:347-361`, `memset(f, 0, sizeof(Fiber))`, `f->local = &f->own`). The root_slot test states this (`src/features/tasks/tests/root_slot/root_slot.av:1-2`): "a slot the program's own run sets before any task exists is its own after one does, and no task is born with it."

### What `spawn` copies today
`avra_fiber.c:2570-2578`:
```
void* avra_task_spawn(void* body) {
    stacks_settle();
    Fiber* f = fiber_new(NULL, 0);
    void* task = task_made(f, body);
    f->task = task;
    scope_inherited(f, g_current);
    ...
```
The child gets one deadline scope record (§1). It gets no slots, no cancel bit, and no shield. Everything else it holds comes from its body closure's captured lanes (`src/features/tasks/lowers.av:23-37`: `fn_box(..., [cx.lane_value(...) for name in lift.lanes], ...)`).

### Cancellation from parent to child
Cancellation propagates through structured joins, not by inheritance. A scope that owns a task joins it as the scope ends, and if the joining task is itself cancelled it cancels first. `avra_fiber.c:2678-2683`:
```
void avra_task_settle(void* task) {
    if (!task) return;
    if (g_current->cancel_by != 0) task_cancelled(task, id_of(g_current));
    task_awaited(task, 1);
}
```
`docs/2026_10_18_TASK_OWNERSHIP.md:8-10` states the law: "cancelling a task cancels every task it made, and each child's defers run exactly once before the parent's unwind ends." Today only a statement owns a task (a bound `let`, or a dropped `let _`). A `spawn` in an argument, receiver, `??` or interpolation position is unowned and the child is not cancelled (table at `:16-25`). The approved fix is a task-typed `Ins.Release` that joins, cancelling first while unwinding (`:87-108`). A deadline reaches a child only through the inherited scope copy, not through cancel propagation.

---

## 3. Closures and fn values

### How captures are represented
`src/core/closures.av:1-5`:
```
//! A FN AS A VALUE: a lambda's body lowered as its own unit, register 0 the box it's handed and its
//! seats after; every name the body reads from further out is a lane of that box, in the order the
//! body first reads it ... Where the lambda stands, its captures are read in lane order and boxed behind the body's code
//! address; a call through such a box hands it the box first.
```
The box is built at `closures.av:103-117` (`fn_box`): an array whose slot 0 holds the code address (`Ins.FnAddr`), followed by the captured words. A call through it, at `closures.av:143-149`:
```
    mut fn called_code(l: Layout, code: Reg, box: Reg, args: List<Reg>, of: SignedType?) -> Reg {
        ...
        self.emit(Ins.CallPtr(dst, code, [box].concat(args)))
```
- **Captures are by value.** Lane values are read where the lambda stands and copied into the box. Assigning to a capture is refused (F3005, CLAUDE.md "The subset today"). SHARING_MODEL §1.1/§1.2: "A capture copies." A `state` binding is the exception: it is a `Cell`, so the capture copies the cell pointer and shares the place (SHARING_MODEL §1.3).
- **There is a hidden environment pointer.** A lifted body's register 0 is its own box, and every fn-value call hands the box first (`[box].concat(args)`). The lifted body binds outer names through lanes: `body.bind(name, b.outer(name, lanes))` (`closures.av:65-67`).
- A `spawn` body is a lifted lambda in "tasked" mode: its answer is a one-cell list and its symbol carries a `$task` suffix (`closures.av:73-81`).

### Type of a fn value
`src/core/types.av:95`: `Fn(params: List<TypeId>, marks: List<SeatMark>, ret: TypeId)`. The marks are part of the type's identity (`types.av:261`, the interning key `"15:${params}:${mark_words(marks)}:${ret}"`). At runtime, a fn value's box is keyed by seat count plus seat types, **without marks** (`closures.av:155-160`, `value_key`).

### What CLAUDE.md says (Rules, "A FN TYPE CARRIES ITS SEATS' CONTRACT")
"`fn(mut Cx, int) -> int` is a DIFFERENT TYPE from `fn(Cx, int) -> int`, and the interner keeps them apart (the marks ride the key) … a seat that PERMITS writing accepts a callee that does not write (`fn_fits`) … A fn type's marks are NORMALIZED at `intern` … A SEAT'S PROMISES ARE ONE CHANNEL: `SeatMark { mutable, settled }`, carried as a `List<SeatMark>` on `Type.Fn`, `Arrow`, `TypeRef` and `Param` — never a parallel `List<bool>` per promise … added as a FIELD it reaches every reader through the one `mark_at`."

### Could a fn type carry an extra hidden seat?
Nothing like it exists today. Facts that bear on the question:
- (a) The calling convention already prepends one hidden argument (the box) to every fn-value call.
- (b) Direct calls of a declared fn do not pass a box. `declare_user` (`src/compiler/backend/llvm.av:871-879`) declares exactly `bd.seats`.
- (c) `value_key` counts seats, so any extra seat changes box keys.
- (d) `SeatMark` already has fields the fn-type spelling cannot write: `state`, `unshared`, `consumed`. So the type can carry promises that are never spelled.

---

## 4. Seats and marks

### `SeatMark` today
`src/core/types.av:1094`:
```
export type SeatMark = { mutable: bool, settled: bool, state: bool = false, unshared: bool = false, consumed: bool = false }
```

| mark | source word | where it is parsed | notes |
|---|---|---|---|
| `mutable` | `mut` | fn `param` (`src/features/fns/mod.av:53`), `seat`/`once_seat` (`:55-56`), `trailing_seat` (`src/features/expr_spine/mod.av:63`), fn-type `fn_seat` (`src/features/closures/mod.av:31`) | |
| `settled` | `const` | same places | compile-time settlement |
| `state` | `state` (STATE token) | fn `param` only (`fns/mod.av:53`) | "a PLACE the caller owns" (`types.av:1127-1133`) |
| `unshared` | `isolated` | fn `param` only (`fns/mod.av:53`) | refusal `type.isolated` (`fns/mod.av:46`) |
| `consumed` | none | computed by the consumes pass (`src/compiler/consumes.av`) | never written in source |

The fn-type grammar spells only `const` and `mut` (`closures/mod.av:31`: `fn_seat = ( settled:"const" )? ( mutable:"mut" )? ty:type -> Record.FnSeat`). `FnSeat.mark()` (`src/core/nodes.av:711`) builds only `mutable` and `settled`.

All seats share one builder, `src/features/seat_builder.av:10-36`:
```
promises: SeatMark {
    mutable: self.present_of("mutable")?,
    settled: self.present_of("constant")?,
    state: self.present_of("state")?,
    unshared: self.present_of("unshared")?,
},
...
state: self.present_of("state_field")?,
```
`Param` (`src/core/nodes.av:842`) also carries `marks: List<Mark>` (annotations), `state` (a field's `state`, not the seat mark), `says` (events), `prop`, `spread`, and `implicit` (the `it` pronoun's minted seat, `src/core/store.av:1294-1302`).

### Where `state` and defaults are accepted

| construct | `state` | default `= expr` | rule |
|---|---|---|---|
| fn param | yes (seat mark) | yes | `fns/mod.av:53` |
| record field | yes (`state_field`) | yes | `src/features/structs/mod.av:54` |
| component body field (`cfield`) | yes (`state_field`) | yes | `src/features/components/mod.av:46` |
| component HEAD seat (`hseat`) | **no** | **no** | `components/mod.av:45`: `hseat = ( marks:mark )* name:NAME ":" ty:type -> Record.ParamSyntax` |
| fn-type seat | no | no | `closures/mod.av:31` |
| lambda / extern seat | no | no (CLAUDE.md subset: "`extern fn` and a lambda refuse it") | |

`docs/2026_11_16_UI.md:28`: "A child component's head takes no `state` seat." SHARING_MODEL §3.5 recorded both missing pieces, `ambient` and head defaults, as asks.

### What a new mark touches
These are the readers of `unshared`/`isolated_mark`, the most recently added mark (grep, tests excluded):
- `src/core/types.av`: `mark_words`/`mark_letter` (the identity key, `:1169-1184`), `mark_at`/`*_mark`, `zip_marks`
- `core/signed_types.av`, `core/checking.av`, `core/nodes.av` (Param, FnSeat, `exact_seat_mark` at `:1213`)
- `features/seat_builder.av`, `features/checks.av`, `features/fns/checks.av`, `features/fns/mod.av` (grammar plus the voice), `features/impls/mod.av`
- `compiler/item_signatures.av`, `compiler/codecs.av`, `compiler/record.av`, `compiler/consumes.av`, `compiler/item_typed.av`, `compiler/signed.av`

`state` has a wider reader set, because it changes what the argument is (a place): `core/paths.av`, `layout.av`, `frame_reads.av`, `calls.av`, `features/fns/lower.av`, `features/components/builders.av`, and more (about 30 files).

Two more consumers sit across boundaries: the `@std/meta` crossing (`Seat`/`Param` meta shapes; UI.md:358 records a pending "Seat and Param carry one SeatMark" moved-shape change) and `make fingerprints` (SeatMark derives `Fingerprint` and `Identity`).

---

## 5. How std-ui builds and draws a tree

### When bodies run
Building an instance is eager. Describing it is lazy and nested.

A component with a body is a **composition**. `@derive(View)` writes two impls for it (`packages/std-ui/src/tree/view.av:185-230`):
```
impl ${t} {
    fn ${composed}() -> List<dyn View> {
        let made = gathered { ${body} }      // the author's body runs HERE
        made.items
    }
}
impl View for ${t} {
    fn describe(at: Standing) -> List<Node> {
        let me = ${me}                       // the kept instance (state) or self
        made_of(at, me.${composed}(), self.key)
    }
}
```
So writing `panel { text "x" }` builds records only: `panel`'s instance record with `text`'s record in its list field. Component bodies run inside `describe`, during the paint walk. A parent's `describe` calls `made_of` → `each_described`, which calls each child's `describe` (`view.av:150-177`):
```
fn each_described(at: Standing, items: List<dyn View>, drawn: bool) -> List<List<Node>> {
    let said = [v.stand() for v in items]
    let stands = at.children([s.spelled() for s in steps(said)], shared(said), drawn)
    [v.describe(stands[j]) for j, v in items]
}
```
A primitive (`@prim`) builds one `Node`, with children produced by `described(at, members)` (`view.av:582-585`). The walk is therefore an ordinary depth-first call stack: **a parent's `describe` frame is live while each descendant's body runs.** The only value threaded down the walk is `at: Standing` (identity and kept state).

### `mount` → walk → realize
- `packages/std-ui/src/web/web.av:60-81`: `mount(view: fn() -> V, theme: fn() -> Theme = plain)` → `paged(view, theme, live(), send)` → `made.app.paint()`. The terminal `mount` (`terminal/terminal.av:724`) takes **no theme**.
- `app/app.av:150-178` (`owned_app`) holds the theme as `theme: Cell<fn() -> Theme>` and the view as `drawn = (at) -> rooted(view().describe(at))`.
- `app/app.av:203-222` (`paint`):
```
        let view = self.view.get()
        let theme = self.theme.get()
        ...
        let root = view(self.stands)          // the walk; no theme in it
        ...
        self.show(root, theme())              // theme handed to the target only here
```
- `realize/dom/live.av:116-334`: `patches(root, theme)` → `painted` → `restyled`, then `root_vars(theme)`. `realize/html/css.av:444-446`:
```
export fn root_vars(t: Theme) -> string {
    ":root{color-scheme:${scheme(t.mode)};${space_vars(t)}${radius_vars(t)}${tone_vars(t)}${face_vars(t)} }"
}
```
`tone_vars` (`css.av:427-429`) emits `--tone-<word>:<colour>;`. Nodes carry token **names** (a `Tone` enum, `style/tokens.av:21`), and classes read `var(--tone-…)`. So the theme never enters the walk or any `Node`. It becomes one `:root` CSS block per page, and a theme change rewrites the variables and moves no class. Only one theme exists per page, and no subtree can override it (UI.md:35-36: "A theme is set once, at `mount`; no subtree overrides it.").
- Terminal: `realize/tui/tui.av:16`, `export fn render(root: Node, _env: Env, width: int)`, ignores its env.
- `packages/std-ui/src/env.av` declares `Env = { theme: Theme = default_theme, direction: Direction = .Ltr, locale: string = "en" }` ("A target reads it; nothing threads it through a component's fields"). Only `realize/html/html.av:98,107` (`render(root, env)`, `Page.env`) and the tui stub take it. **No component reads `Env`.**

### Where event handlers are called from
Handlers are closures stored on `Node.events` by the last paint. They are not called during the walk. Web path: the host calls `avra_ui_event(who, what, tag, num, len)` (`web/web.av:115-121`) → `held.heard(...)` (`realize/dom/page.av:51-54`) → `self.app.turn_of(id, () -> self.page.fire(...))` → `App.turn` (`app/app.av:314-330`) → `(self.guard.get())(act)`. The default guard is `contained_turn` (`app.av:125`), i.e. `@std.meta.contained`, which runs the body under `avra_guard_run`, a per-task catch point for traps (`packages/std-meta/src/meta.av:485-509`). So **a handler runs after the walk that created it has returned**, under a trap guard, on whatever task the host's call landed on, with no `describe` frame on the stack.

---

## 6. Module-level places: `once fn`, `state`, `const`, `let`

- **A top-level `let`/`mut` is invisible to fn bodies.** Law `resolve.runtime_binding` (`src/compiler/item_unresolved.av:151-157`; voice at `src/compiler/resolve/walk.av:706-711`): "`${name}` is a run-time binding of the top level — a fn body or a const sees declarations, not the values around it", help "pass `${name}` in as a parameter, or make it a fn".
- **A top-level `state` is a declaration.** It is readable and writable from any fn body. `src/features/decls_mint.av:206-212`: "A `state` at the top level is a DECLARATION … this statement mints a State row and a body ever sees it in the namespace." Its lowering, `src/core/lowering.av:131-133`: `Kept(callee, held)`, "its unit answers the one-slot box that keeps it, built at its first read; a read is what the box holds now, a write what it holds next." It is process-global, one cell (SHARING_MODEL §4.1: "`state` is ONE cell for the whole process (and, with `run()`, one per core)"). Witness: `packages/std-ui/src/tests/module_state`.
- **`const`** is a declaration settled at compile time (static data, CLAUDE.md "A SETTLED AGGREGATE IS STATIC DATA"). Bodies can read it, but it is immutable.
- **`once fn`** answers once per process (`src/core/once.av:1-5`: "kept in the fn's own slot the first time its body answers"). The runtime keeps the answer in a process-wide table keyed by symbol (`runtime/avra_runtime.c:2465-2530`, `avra_once_get`/`avra_once_set`). A `once fn` takes no arguments and must answer a managed value (CLAUDE.md subset). std-ui uses `once fn x() -> Cell<T>` as module-global mutable state (`web/web.av:30`, `:46-51`).
- **Mechanisms a default could ride today:** module `state` and `once fn … -> Cell<T>` (process-wide, shared by every task), `const` (immutable), and the runtime's per-task slots (§2), which have no Avra-level surface.

---

## 7. Host fns: what runs at entry

- The backend defines a host fn's bare symbol as a pure trampoline (`src/compiler/backend/llvm.av:887-930`, `host_symbol_defined`): "a fn of the bare name, under its extern row's shape, that hands its seats straight to the body and its answer straight back." It has no prologue: no task setup, guard, slot or scope. On wasm it is just exported (`avra_llvm_set_export`).
- So `avra_ui_event`'s body runs on the current fiber. On wasm (`AVRA_HOSTED`, `runtime/avra_fiber.c:43-44, 81-99`) the host holds the stacks. Which fiber the host's call lands on, and what slots or deadline it holds, is UNKNOWN from reading. Main is a fixed record with `.local = &avra_main_local` (`avra_fiber.c:310`).
- In the evaluator, a call of a host fn's name becomes a call of its body (`hosted_within`, per CLAUDE.md). `rooted` files the program's run as a task on first use and re-keys guards (CLAUDE.md "AN IDENTITY ASSIGNED LATE MUST RE-KEY").
- What does exist on entry is library code, not compiler-established: `avra_ui_event` reads `mounted()` (a `once fn` Cell), and `App.turn` wraps the handler in `guard` (`contained`). Nothing anywhere establishes defaults on entry.

---

## 8. Earlier design text on implicit context

**`provide x: T = v` / `env T` (deleted).** `docs/2026_10_04_SHARING_MODEL.md:180-221` (§1.5). It was a type-keyed environment with a scope stack in typing and lowering, and a missing provider was a compile error. **REJECTED and deleted (avra-xubk.6.1, done):**
- it introduced a second lookup rule (by type) when every other name in the language resolves by name;
- it needed a bespoke scope stack duplicated in typing and lowering;
- it hid dependencies;
- two keywords encoded one flag;
- the probe showed a `provide` did not reach a `fn` body at all ("strictly weaker than the lexical rule").

Owner: "it's all such a fucking mess."

**The `ambient` seat mark.** SHARING_MODEL §3 (`:247-390`), §8, §9.
- Spelling: `component text(content: string, ambient env: Env = Env.default)`.
- The seat is filled from the caller's scope by name, through ordinary lexical lookup, and can be overridden per call (`text("Hi", env: dark_env)`).
- It is visible in the signature and has a default.
- The supply is a top-level `const` or `state`. A subtree override is a shadowing `let env = env with {…}`.
- Capabilities go through a fn-valued or `dyn Trait` ambient seat.
- Per-request context (caller, session, tenant, trace) is a guard-supplied `ambient` seat, "never a `state`" (§4.1).

**DECIDED** (§8), but **unbuilt**: `ambient` is a parse error, and component head defaults are a separate parse error (§3.5). **OPEN** (§8): "(f) the exact `ambient` lowering (a param default vs a hidden field); (g) whether `ambient` is also a READER". Ticket avra-xubk.6.2.

**Sugar 1, context as receiver.** `docs/2026_09_09_SUGAR_1_CONTEXT_RECEIVER.md`. It is about a compiler pass threading `cx`. Levels 1 (verbs as methods) and 2 (trailing blocks) were proposed, and both exist today (`cx.region(...) { cx -> } else { … }`). Level 3, the Kotlin-style implicit receiver, was "NOT proposed here … It costs visible magic (P7): a reader cannot see which calls touch the context. Decide after 1 and 2 exist." It is left open.

**UI ledger, Provider rules.** `docs/2026_11_16_UI.md:613`, from an older COMPILED doc: "missing provider is a COMPILE error (lexical, never a runtime stack); nearest wins; a provider must be stable across renders; reads flow through the read set; NO GLOBAL STORE." Its evidence column says "no provide". The doc that held these rules is superseded on the mechanism by SHARING_MODEL.

**Effects with typed requirements.** UI.md:614 and :844 ("Plan 5: effects with typed requirements tied to `provide`/`env`"). Borrowed from Effect-TS: "`R` requirements statically checked → `provide`/`env` ('needs a Database' is a compile error)". Evidence column: "none". **Not built**, and its stated vehicle (`provide`/`env`) is deleted.

**Old UI text.** UI.md:700-701 (`provide theme: Theme = brand` / `let t = env Theme`, carrying values and actions; "a listed runtime lookup when composition is dynamic") and :747 are both annotated superseded by `ambient`. UI.md:720 and :697 record a rejection: "call-order slots behind an ambient cursor (hooks-style) — a hidden global and identity by call ORDER."

**Current state.** UI.md:35-36: "`provide` / `env` are gone and nothing replaced them: no `ambient` seat exists in the code. A theme is set once, at `mount`; no subtree overrides it." UI.md:93-96: "In study, not decided: how a value reaches a whole subtree. Two candidates: the `ambient` seat settled on 2026-10-04 (… unbuilt), a parameter the compiler fills by name from the caller's scope; and inheritance down the node tree, as data, for what is presentation (theme, density, direction, locale)."

**Deadlines.** FIBERS_DESIGN §12: "DEADLINES ARE A SCOPE, NEVER A PARAMETER (P6)." `within` is the one implicit, dynamically scoped value that is built today.

---

## Constraints any context design must respect

1. `within`'s deadline is per task and dynamically scoped in the runtime (`Fiber.scope[]`). Callees never name it. A spawned child gets a snapshot of one record. Scopes are strictly LIFO, and ending them out of order traps.
2. Per-task slots exist: `AvraTaskLocal.slot[4]`, two keys named and two free, swapped on every fiber switch. They are not inherited by `spawn`, and no Avra surface uses them outside tests. The evaluator mirrors them (`tasks[].slots`).
3. Cancellation propagates through structured joins (`avra_task_settle`), and only for tasks a statement owns. Spawns in other positions are unowned today (TASK_OWNERSHIP).
4. Lambdas capture by value into a box. Every fn-value call passes that box as a hidden first argument. Direct calls of declared fns pass no hidden argument.
5. Fn-type identity includes `SeatMark`s, and marks must stay one channel (CLAUDE.md). The fn-type spelling writes only `mut` and `const`. The runtime box key ignores marks.
6. Component head seats take neither marks-with-defaults nor `state`. Only fn params take `state` and `isolated` marks.
7. Fn bodies cannot read top-level `let`/`mut` (`resolve.runtime_binding`). They can read `state` (process-wide, one cell) and `const`.
8. In std-ui, instance construction is eager and records-only. Bodies run inside a nested `describe` walk. Event handlers run later from the host entry under `contained`, with no walk on the stack.
9. The theme reaches only the realizer (`show(root, theme())` → `:root` CSS vars). Nodes carry token names. Terminal `mount` has no theme. `Env` exists, but no component reads it.
10. Host fn symbols are trampolines with no prologue. Nothing establishes context on host entry.
11. `provide`/`env T` (type-keyed, scope stack) is deleted for stated reasons. Hooks-style ambient cursors are rejected. `ambient` (a by-name seat with a default) is decided but unbuilt, with its lowering open. Sugar 1's implicit receiver was left open over P7.
