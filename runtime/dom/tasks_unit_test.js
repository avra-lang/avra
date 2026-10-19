// The host half's plain JS, with no module: the artifact choice, the fault
// words, and the SERIAL entry of the program. `WebAssembly.promising` is
// stood in for by an async wrapper, since only the order of entries is under
// test. Run as `node tasks_unit_test.js`.
import { PARKED_UNDER_HOST, chooseArtifact, faultWords, hostedTasks } from "./tasks.js";

let checks = 0;
let fails = 0;
const check = (ok, what) => {
  checks += 1;
  if (!ok) {
    fails += 1;
    console.error(`tasks_unit_test: FAILED ${what}`);
  }
};

// the artifact a page fetches follows what the host can suspend
check(chooseArtifact("app.wasm", true) === "app.wasm", "a host that suspends fetches the clean module");
check(chooseArtifact("app.wasm", false) === "app.asyncify.wasm", "a host that cannot fetches the asyncified one");
check(chooseArtifact("dir/app.wasm", false) === "dir/app.asyncify.wasm", "the suffix is changed, not the path");
const savedSuspending = WebAssembly.Suspending;
const savedPromising = WebAssembly.promising;
WebAssembly.Suspending = undefined;
check(chooseArtifact("app.wasm") === "app.asyncify.wasm", "with no Suspending the choice is the fallback");
WebAssembly.Suspending = function Suspending() {};
WebAssembly.promising = function promising() {};
check(chooseArtifact("app.wasm") === "app.wasm", "with both, the choice is the clean module");

// the engine's words become the scheduler's
check(faultWords(new RangeError("Maximum call stack size exceeded")) === "avra: a task's stack overflowed", "a call stack that ran out is a task's overflow");
check(faultWords(new Error("boom")) === "boom", "any other fault is its own message");
if (typeof WebAssembly.SuspendError === "function") {
  check(faultWords(new WebAssembly.SuspendError("trying to suspend JS frames")) === PARKED_UNDER_HOST, "a park under a host call is spoken as such");
}

// entries are serial: a second waits for the first
WebAssembly.promising = (fn) => async (...args) => fn(...args);
let inside = 0;
let widest = 0;
const order = [];
const slow = (label, ms) => async () => {
  inside += 1;
  widest = Math.max(widest, inside);
  order.push(`${label} in`);
  await new Promise((r) => setTimeout(r, ms));
  order.push(`${label} out`);
  inside -= 1;
  return label;
};
const tasks = hostedTasks(() => ({ a: slow("a", 20), b: slow("b", 1), c: slow("c", 1) }));
const answers = await Promise.all([tasks.enter("a"), tasks.enter("b"), tasks.enter("c")]);
check(answers.join("") === "abc", "entries each answer");
check(widest === 1 && tasks.deepest() === 1, "and never stand inside at once");
check(order.join(",") === "a in,a out,b in,b out,c in,c out", "in the order they arrived");
// an entry that fails does not stop the line
const failing = hostedTasks(() => ({ boom: async () => { throw new Error("no"); }, fine: async () => 3 }));
const failed = failing.enter("boom").then(() => "ran", () => "failed");
const after = failing.enter("fine");
check((await failed) === "failed" && (await after) === 3, "a failed entry does not stop the entries after it");

WebAssembly.Suspending = savedSuspending;
WebAssembly.promising = savedPromising;
if (fails) {
  console.error(`tasks_unit_test: ${fails} of ${checks} checks failed`);
  process.exit(1);
}
console.log(`tasks_unit_test: ${checks} checks hold`);
