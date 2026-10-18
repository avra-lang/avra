// The host half of a hosted scheduler, against a reactor that parks in a host
// fn (tools/wasm-host): how the page enters the program decides whether a
// task may park, and which artifact a page fetches. Run by
// tools/wasm-host-check.sh as `node --experimental-wasm-jspi tasks_test.js <module.wasm>`.
import fs from "node:fs";
import { PARKED_UNDER_HOST, chooseArtifact, faultWords, hostedTasks, jspiAvailable } from "./tasks.js";
import { wasiPreview1 } from "./wasi.js";

let checks = 0;
let fails = 0;
const check = (ok, what) => {
  checks += 1;
  if (!ok) {
    fails += 1;
    console.error(`tasks_test: FAILED ${what}`);
  }
};

if (!jspiAvailable()) {
  console.error("tasks_test: this Node has no JSPI — skipped");
  process.exit(0);
}

const module = await WebAssembly.compile(fs.readFileSync(process.argv[2]));

// A module of its own, run to its first prompt: a refused plain call leaves
// the scheduler mid-wait, so the checks that follow it stand on another.
async function booted() {
  let instance = null;
  const tasks = hostedTasks(() => instance.exports);
  const wasi = wasiPreview1(
    () => instance.exports.memory,
    (code) => {
      throw new Error(`exit ${code}`);
    },
  );
  const imports = { wasi_snapshot_preview1: wasi, avra_host: tasks.imports };
  for (const i of WebAssembly.Module.imports(module)) {
    if (i.module !== "wasi_snapshot_preview1" && i.module !== "avra_host") {
      imports[i.module] = { ...(imports[i.module] ?? {}), [i.name]: () => { throw new Error(`no host row ${i.name}`); } };
    }
  }
  instance = await WebAssembly.instantiate(module, imports);
  instance.exports._initialize();
  await tasks.enter("avra_main");
  return { instance, tasks };
}

const plain = await booted();
const { instance, tasks } = await booted();

// 8. a program entered by a plain call has no stack to suspend: the first park
// is refused, and the host speaks it in the program's words
let refused = null;
try {
  plain.instance.exports.avra_probe_wait(1n);
} catch (e) {
  refused = e;
}
check(refused instanceof WebAssembly.SuspendError, "a plain call that parks is refused by the engine");
check(refused && faultWords(refused) === PARKED_UNDER_HOST, "and the host speaks it in the scheduler's words");

// 9. the same callback entered through `enter` runs to its answer, as many
// times as it is asked, one after another
check((await tasks.enter("avra_probe_wait", 1n)) === 2n, "an entered callback parks and answers");
check((await tasks.enter("avra_probe_wait", 41n)) === 42n, "and the next entry does too");
check(tasks.stranded() === 0, "no stack is left behind by the entries");
// entries that arrive together are turns, and turns are serial: the second waits for the first
const together = await Promise.all([tasks.enter("avra_probe_wait", 1n), tasks.enter("avra_probe_wait", 5n), tasks.enter("avra_probe_wait", 9n)]);
check(together.join(",") === "2,6,10", "entries that arrive together each answer");
check(tasks.deepest() === 1, "and never stand inside the program at once");

// 11. the artifact a page fetches follows what the host can suspend
check(chooseArtifact("app.wasm", true) === "app.wasm", "a host that suspends fetches the clean module");
check(chooseArtifact("app.wasm", false) === "app.asyncify.wasm", "a host that cannot fetches the asyncified one");
const saved = WebAssembly.Suspending;
delete WebAssembly.Suspending;
check(chooseArtifact("app.wasm") === "app.asyncify.wasm", "and the choice reads the host when none is given");
WebAssembly.Suspending = saved;
check(chooseArtifact("app.wasm") === "app.wasm", "restored, it reads the host again");
// the clean module carries no asyncify machinery: a JSPI host pays nothing for the fallback
const exported = WebAssembly.Module.exports(module).map((x) => x.name);
check(!exported.some((n) => n.startsWith("asyncify_")), "the clean module exports no asyncify_ symbol");

if (fails) {
  console.error(`tasks_test: ${fails} of ${checks} checks failed`);
  process.exit(1);
}
console.log(`tasks_test: ${checks} checks hold`);
