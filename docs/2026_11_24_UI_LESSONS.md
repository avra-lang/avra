### Milestone 1: rulings of 2026-11-18 to 2026-11-24

The board on the web, written the decided way. Each line is a ruling of the UI lead unless it says
owner.

- **`shown: T? = null` is display only.** Where given, the control shows it instead of its place;
  it never writes. Revisited at the sync study, where an optimistic value and a confirmed one differ.
- **A member's relation to a place is a mark**: `@over(place)` on what is shown instead of it,
  `@sets(place[, constant])` on the event that writes it. `@seeds` is dropped: a place's first value
  is its declaration's (`state checked: bool = self.initial`).
- **The head form is the one form.** `tab "All" { chosen: filter, shows: .All }`: what the head
  declares goes in the head, the rest in the block. Naming a head seat in the block is refused, and
  the refusal carries the edit.
- **A `state` field in a type is a shared reference**, opt-in, field by field. Its cost on a row
  drawn ten thousand times is unmeasured.
- **No `derived` keyword.** A pure fn that reads state is cached by the compiler, keyed by what it
  read. A one-day study fixes the rule (what counts as pure, where the cache lives, the bound).
- **`ctx theme` is built**: std-ui declares it, the board sets it once at its page, and a theme's
  scope on the page carries no hash. `ctx_reads` is computed lazily. Owed: the receipt for that
  laziness, the lint for a `ctx` a parameter would do for, and the 82 more boxes a paint makes.
- **The scheme is three choices**, Auto, Light, Dark, over `state mode: Mode = .System`. A two-way
  toggle between "as the system is" and "dark" changes nothing on a dark device.
- **A field hears `on submit`**, with no payload: the field's place already holds the text. Enter
  or a phone's return key fires it, never mid-composition, never in a multi-line field. The key's
  word is `submit_label: SubmitLabel = .Done` (`Done`, `Go`, `Send`, `Search`), one concept on the
  web, iOS and Android. Setting it with no `on submit` is refused. `Next` waits on focus order.
- **A page says a failure in plain words.** "This page could not start." or "This page stopped
  working."; the error's own words follow under `avra dev` only, and a built page offers a reload.
  An `error` event with no error object and no file is a script the page does not own: never drawn,
  told to the console, and under dev carried to the server's output with the browser's name.
- **The browser is a gate slice** (`ui-browser`): the board's claims run in a real browser on every
  merge.

### Lessons from the owner's first look (2026-11-24)

Three defects reached the owner on a board whose 96 browser claims were green.

- **A claim asserts what the reader sees.** Every dark-mode claim asserted "no error drawn", on a
  light-scheme browser. The toggle changed nothing on a dark phone and every claim passed. A claim
  about a look reads the drawn colour, under each scheme the OS can ask for.
- **A test runs under every dial the OS turns**: scheme, contrast, text size, pointer or touch,
  keyboard. One default configuration is one sample.
- **The keyboard is an input.** Enter in the new-task field did nothing and no claim pressed it.
  Each control's claims drive it by pointer, by touch and by key.
- **A test's side effects are checked.** A script that "added a task" never read the task list, so
  an add that saved nothing passed.
- **The lead opens the page before the owner does**, in a browser, under both schemes, and says
  what was not covered (a browser we cannot run is named, not implied).
- **A refusal with no place is a defect.** A `state` of one enum in a seat of another passed
  `check` and failed the build with "a seat refuses a value here", no line. Filed.
- **A dev loop's broken edit must not outlive the edit.** A machine-wide store kept a null under a
  good file's key after an unterminated fn, and every later build of the untouched board failed.
  Fixed, with a witness (good, broken, fixed, fresh copy).

### The storyboard (planned 2026-11-24, owner)

Every component in every state, for the owner's eye and for the gate. It grows out of
`@std/ui_gallery` (entries, cases, semantic snapshots, `changed`), which stays the one definition.

- **The list of components is the compiler's**, never written by hand: a component with no story
  is refused.
- **A story stands beside its component** and is gathered across files.
- **States are derived from the component's own members** (each `bool`, each enum, disabled,
  empty, long text), and each is drawn under each dial (scheme, contrast, text size) on each target.
- **One set of stories, three uses**: the page the owner inspects, the gate's claims and
  snapshots, and the parity check between the web and a native target.

