// Both hosts against one module that hands the thread between two tasks:
// JSPI against the plain build, asyncify against the asyncified one. The
// interleaving and the answer must be the same. Run by
// tools/wasm-host-check.sh as `node --experimental-wasm-jspi tasks_proxy_test.js plain.wasm asyncified.wasm`.
import fs from "node:fs";
import { asyncifyTasks, hostedTasks } from "./tasks.js";

let checks = 0;
let fails = 0;
const check = (ok, what) => {
  checks += 1;
  if (!ok) {
    fails += 1;
    console.error(`tasks_proxy_test: FAILED ${what}`);
  }
};

const logged = (x) => Array.from({ length: x.log_at() }, (_, i) => x.log_word(i)).join(",");

for (const [name, file, make] of [
  ["jspi", process.argv[2], hostedTasks],
  ["asyncify", process.argv[3], asyncifyTasks],
]) {
  let instance = null;
  const tasks = make(() => instance.exports);
  instance = (await WebAssembly.instantiate(fs.readFileSync(file), { avra_host: tasks.imports })).instance;
  const answered = await tasks.enter("run", 41);
  check(answered === 42, `${name}: the entry answers`);
  check(logged(instance.exports) === "1,2,3,4,5,6", `${name}: the tasks interleave as the scheduler handed the thread`);
  check(tasks.stranded() === 0, `${name}: no task is left behind`);
  // a second entry runs on its own after the first
  const again = await tasks.enter("run", 1);
  check(again === 2, `${name}: a second entry answers`);
}

if (fails) {
  console.error(`tasks_proxy_test: ${fails} of ${checks} checks failed`);
  process.exit(1);
}
console.log(`tasks_proxy_test: ${checks} checks hold`);
