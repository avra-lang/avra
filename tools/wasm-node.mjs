// Run a wasm32-wasi module under Node's WASI preview1 host, streaming its
// stdout to ours. The exit code is the module's: a trap exits 2 (avra_trap),
// a normal answer exits what the program returned, so a trap never reads as
// an ordinary finish.
//
// A module that imports `avra_host` has a hosted scheduler (tasks): it runs
// under JSPI (a Node 24, which has `WebAssembly.Suspending`), the program's
// entry on the first task's stack. Without it the module exits 3 and says so
// — never a silent pass. `--asyncify <module>` is the fallback host:
// the asyncified module (`app.asyncify.wasm`) driven without suspending a
// stack, on any Node.
import { WASI } from "node:wasi";
import fs from "node:fs";
import { asyncifyTasks, faultWords, hostedTasks, jspiAvailable } from "../runtime/dom/tasks.js";

const fallback = process.argv[2] === "--asyncify";
const file = fallback ? process.argv[3] : process.argv[2];
const wasi = new WASI({
    version: "preview1",
    args: [file],
    env: {},
    returnOnExit: true,
});
const module = await WebAssembly.compile(fs.readFileSync(file));
const hosted = WebAssembly.Module.imports(module).some((i) => i.module === "avra_host");
if (!hosted) {
    const instance = await WebAssembly.instantiate(module, wasi.getImportObject());
    process.exitCode = wasi.start(instance);
} else if (!fallback && !jspiAvailable()) {
    console.error(`wasm-node: the module has tasks and this Node (${process.version}) has no WebAssembly.Suspending — run it under a Node 24 (the image's node-jspi)`);
    process.exitCode = 3;
} else {
    let instance = null;
    // a fault in a spawned task ends the run as a trap does: its words, exit 2
    const tasks = (fallback ? asyncifyTasks : hostedTasks)(() => instance.exports, (e) => {
        console.error(faultWords(e));
        process.exit(2);
    });
    const imports = { ...wasi.getImportObject(), avra_host: tasks.imports };
    instance = await WebAssembly.instantiate(module, imports);
    // wasi.start would call _start synchronously; the entry must be a promising export.
    process.exitCode = await entered(wasi, instance, tasks);
}

// The WASI object binds the instance's memory in `start`/`initialize`; a
// command module's `_start` is run through JSPI here instead, so the memory
// is bound by handing `start` an instance whose `_start` is the promised one.
async function entered(wasi, instance, tasks) {
    let done = null;
    const proxied = {
        exports: {
            ...instance.exports,
            _start: () => {
                done = tasks.start("_start");
            },
        },
    };
    const code = wasi.start(proxied);
    if (!done) return code;
    try {
        await done;
        await new Promise((resolve) => setImmediate(resolve));
        if (tasks.stranded() > 0) console.error(`wasm-node: ${tasks.stranded()} task stack(s) never ended`);
    } catch (e) {
        // a trap or an exit after the first handover surfaces here, not in start()
        console.error(faultWords(e));
        return 2;
    }
    return code;
}
