// THE HOST HALF OF A HOSTED SCHEDULER (runtime/avra_fiber.c, AVRA_HOSTED).
// The scheduler decides who runs; the host only holds each task's stack and
// hands the thread over. A task is one JSPI stack: `switch` starts or
// resumes the target and suspends the caller until something hands the
// thread back; `idle` suspends the caller until a time passes. A task that
// is done is not suspended — its stack ends with its body.
//
// Needs WebAssembly.Suspending / WebAssembly.promising.

export function jspiAvailable() {
  return typeof WebAssembly.Suspending === "function" && typeof WebAssembly.promising === "function";
}

// The imports a hosted module names, and `start` to run its entry on the
// first task's stack. `exports()` reads the instance's exports once it exists.
export function hostedTasks(exports) {
  const slots = new Map();
  let wake = null;

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
      const waiting = ends ? undefined : parked(from);
      slot(from).running = true;
      const next = slot(to);
      if (!next.running) {
        next.running = true;
        entry()();
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
    // Runs the program's own entry on the first stack; resolves when it ends.
    start: (name = "_start") => WebAssembly.promising(exports()[name])(),
  };
}
