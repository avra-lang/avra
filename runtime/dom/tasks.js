// THE HOST HALF OF A HOSTED SCHEDULER (runtime/avra_fiber.c, AVRA_HOSTED).
// The scheduler decides who runs; the host only holds each task's stack and
// hands the thread over. A task is one JSPI stack: `switch` starts or
// resumes the target and suspends the caller until something hands the
// thread back; `idle` suspends the caller until a time passes. A task that
// is done is not suspended — its stack ends with its body.
//
// Needs WebAssembly.Suspending / WebAssembly.promising.

// What a fault in a task is, in the program's own words: the engine's call
// stack running out is the task's stack overflowing, as a native guard page
// says it. Anything else is its own message.
export function faultWords(e) {
  if (e instanceof UnwindOverflow) return "avra: a task's stack overflowed";
  if (e instanceof RangeError && /call stack/i.test(e.message)) return "avra: a task's stack overflowed";
  if (typeof WebAssembly.SuspendError === "function" && e instanceof WebAssembly.SuspendError) return PARKED_UNDER_HOST;
  return String(e && e.message ? e.message : e);
}

// A task's frames did not fit the buffer they were unwound into: the same
// overflow as a native guard page, spoken in the same words.
export class UnwindOverflow extends Error {
  constructor() {
    super("a task's frames overran its unwind buffer");
  }
}

// A task parked while a host callback was on the stack: JS frames cannot be
// suspended, so the program was entered by a plain call, not by `enter`.
export const PARKED_UNDER_HOST = "avra: a task parked under a host call — enter the program with tasks.enter, which gives each entry a stack of its own";

// The artifact a page fetches: the clean module where the host can suspend a
// stack, the asyncified fallback where it cannot.
export function chooseArtifact(url, suspends = jspiAvailable()) {
  return suspends ? url : url.replace(/\.wasm$/, ".asyncify.wasm");
}

export function jspiAvailable() {
  return typeof WebAssembly.Suspending === "function" && typeof WebAssembly.promising === "function";
}

// The imports a hosted module names, and `start` to run its entry on the
// first task's stack. `exports()` reads the instance's exports once it exists.
export function hostedTasks(exports, fault = (e) => { throw e; }) {
  const slots = new Map();
  let wake = null;
  let live = 0;
  let line = Promise.resolve();
  let inside = 0;
  let peak = 0;

  const slot = (id) => {
    let s = slots.get(id);
    if (!s) {
      s = { running: false, resume: null };
      slots.set(id, s);
    }
    return s;
  };

  // The promise a suspended task waits on; whoever hands the thread back
  // resolves it.
  const parked = (id) => {
    const s = slot(id);
    return new Promise((resolve) => {
      s.resume = resolve;
    });
  };

  const imports = {
    switch: new WebAssembly.Suspending((from, to, ends) => {
      // a task that ends leaves no slot: the scheduler reuses its record's
      // address for the next task, which must start rather than resume
      const waiting = ends ? undefined : parked(from);
      if (ends) slots.delete(from);
      else slot(from).running = true;
      const next = slot(to);
      if (!next.running) {
        next.running = true;
        live += 1;
        entry()().then(
          () => {
            live -= 1;
          },
          (e) => {
            live -= 1;
            fault(e);
          },
        );
      } else {
        next.resume();
      }
      return waiting;
    }),
    idle: new WebAssembly.Suspending((ns) => {
      if (wake) wake();
      return new Promise((resolve) => {
        wake = resolve;
        if (ns < 0n) return;
        setTimeout(resolve, Number((ns + 999999n) / 1000000n));
      });
    }),
  };

  let promised = null;
  const entry = () => (promised ??= WebAssembly.promising(exports().avra_task_entry));

  return {
    imports,
    // How many started tasks have not ended: a stack that outlives its body.
    stranded: () => live,
    // Runs the program's own entry on the first stack; resolves when it ends.
    start: (name = "_start") => WebAssembly.promising(exports()[name])(),
    // A host callback (an echo, a timer, a fetch's reply) enters the program
    // on a stack of its own, so whatever it runs may park. A plain call of
    // the export has no stack to suspend and is refused at the first park.
    // ENTRIES ARE SERIAL, as the turns they are: an entry that comes while
    // another is parked waits its turn, so two never stand in for the
    // program's one main stack at once.
    enter: (name, ...args) => {
      const run = line.then(() => {
        inside += 1;
        peak = Math.max(peak, inside);
        return WebAssembly.promising(exports()[name])(...args);
      });
      const done = () => {
        inside -= 1;
      };
      line = run.then(done, done);
      return run;
    },
    // The most entries that were ever inside the program at once.
    deepest: () => peak,
  };
}

// THE FALLBACK HOST, for an engine that cannot suspend a stack: the same two
// imports, driven by binaryen's asyncify. The module is the asyncified build
// (`app.asyncify.wasm`); a task parks by UNWINDING its wasm frames into a
// buffer of its own and is resumed by REWINDING it, by calling the same
// top-level export again. One task runs at a time and none ever nests, so
// the driver is a loop: run a task until it unwinds or ends, then run
// whichever the scheduler named. `exports().avra_asyncify_buffer(bytes)`
// is the module's allocator for those buffers.
const UNWOUND = 1;
const BUFFER_BYTES = 512 * 1024;

export function asyncifyTasks(exports, fault = (e) => { throw e; }, bytes = BUFFER_BYTES) {
  const tasks = new Map();
  let current = null;
  let pending = null;
  let live = 0;
  let line = Promise.resolve();
  let inside = 0;
  let peak = 0;

  const buffer = () => {
    const at = exports().avra_asyncify_buffer(bytes);
    const view = new Int32Array(exports().memory.buffer, at, 2);
    view[0] = at + 8;
    view[1] = at + bytes;
    return at;
  };

  const imports = {
    // The scheduler hands the thread to `to`. The caller unwinds, unless it
    // is done: then it simply returns and its stack ends with it.
    switch: (from, to, ends) => {
      if (exports().asyncify_get_state() === 2) {
        exports().asyncify_stop_rewind();
        return;
      }
      current.id = from;
      tasks.set(from, current);
      pending = { kind: "switch", to };
      if (ends) {
        tasks.delete(from);
        return;
      }
      current.at ??= buffer();
      exports().asyncify_start_unwind(current.at);
    },
    // The world is waited on: the caller unwinds, the driver waits, and the
    // same task is rewound.
    idle: (ns) => {
      if (exports().asyncify_get_state() === 2) {
        exports().asyncify_stop_rewind();
        return;
      }
      pending = { kind: "idle", ns };
      current.at ??= buffer();
      exports().asyncify_start_unwind(current.at);
    },
  };

  // Runs `first` and whatever the scheduler hands the thread to, until the
  // scheduler hands it to no one.
  const drive = async (first) => {
    let task = first;
    let answer;
    while (task) {
      current = task;
      pending = null;
      if (task.parked) exports().asyncify_start_rewind(task.at);
      let got;
      try {
        got = task.replay();
      } catch (e) {
        // asyncify traps (`unreachable`) when an unwind crosses the end of its buffer, and
        // is left unwinding: that is a task's stack overflowing, not a fault of the program
        const unwinding = exports().asyncify_get_state() === UNWOUND;
        fault(unwinding && e instanceof WebAssembly.RuntimeError ? new UnwindOverflow() : e);
        return answer;
      }
      if (exports().asyncify_get_state() === UNWOUND) {
        try {
          exports().asyncify_stop_unwind();
        } catch (e) {
          // the end of the buffer is checked as the unwind is closed
          fault(e instanceof WebAssembly.RuntimeError ? new UnwindOverflow() : e);
          return answer;
        }
        task.parked = true;
      } else {
        if (task === first) answer = got;
        if (task !== first) live = Math.max(0, live - 1);
      }
      const asked = pending;
      if (!asked) return answer;
      if (asked.kind === "idle") {
        await new Promise((resolve) => setTimeout(resolve, asked.ns < 0n ? 0x7fffffff : Number((asked.ns + 999999n) / 1000000n)));
        continue;
      }
      let next = tasks.get(asked.to);
      if (!next) {
        next = { replay: () => exports().avra_task_entry(), parked: false, at: null, id: asked.to };
        live += 1;
      }
      task = next;
    }
    return answer;
  };

  const run = (replay) => drive({ replay, parked: false, at: null, id: null });
  return {
    imports,
    stranded: () => live,
    start: (name = "_start") => run(() => exports()[name]()),
    // Entries are serial: a second waits for the first (see `enter` above).
    enter: (name, ...args) => {
      const result = line.then(() => {
        inside += 1;
        peak = Math.max(peak, inside);
        return run(() => exports()[name](...args));
      });
      const done = () => {
        inside -= 1;
      };
      line = result.then(done, done);
      return result;
    },
    deepest: () => peak,
  };
}
