// The fallback host's unwind buffer has an end: a task whose frames do not fit
// is a stack overflow, spoken as one — never a silent write past the buffer.
// Run by tools/wasm-host-check.sh as `node tasks_overflow_test.js asyncified.wasm`.
import fs from "node:fs";
import { asyncifyTasks, faultWords } from "./tasks.js";

let checks = 0;
let fails = 0;
const check = (ok, what) => {
  checks += 1;
  if (!ok) {
    fails += 1;
    console.error(`tasks_overflow_test: FAILED ${what}`);
  }
};

const file = process.argv[2];
const run = async (depth, bytes) => {
  let instance = null;
  let fault = null;
  const tasks = asyncifyTasks(() => instance.exports, (e) => { fault = e; }, bytes);
  instance = (await WebAssembly.instantiate(fs.readFileSync(file), { avra_host: { switch() {}, idle: tasks.imports.idle } })).instance;
  const answer = await tasks.enter("run", depth);
  return { answer, fault };
};

const fits = await run(100, 4096);
check(fits.fault === null && typeof fits.answer === "number", "a recursion that fits its buffer parks and answers");
const roomy = await run(400, 64 * 1024);
check(roomy.fault === null, "and the same recursion fits a bigger buffer");
const over = await run(400, 4096);
check(over.fault !== null && faultWords(over.fault) === "avra: a task's stack overflowed", "frames past the end of the buffer are a task's stack overflowing, in its words");
check(over.answer === undefined, "and the run does not go on with a half-written stack");

if (fails) {
  console.error(`tasks_overflow_test: ${fails} of ${checks} checks failed`);
  process.exit(1);
}
console.log(`tasks_overflow_test: ${checks} checks hold`);
