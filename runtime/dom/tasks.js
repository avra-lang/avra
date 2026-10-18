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
  if (e instanceof RangeError && /call stack/i.test(e.message)) return "avra: a task's stack overflowed";
  if (typeof WebAssembly.SuspendError === "function" && e instanceof WebAssembly.SuspendError) return PARKED_UNDER_HOST;
  return String(e && e.message ? e.message : e);
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
    enter: (name, ...args) => WebAssembly.promising(exports()[name])(...args),
  };
}
