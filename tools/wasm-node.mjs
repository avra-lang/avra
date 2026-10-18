// Run a wasm32-wasi module under Node's WASI preview1 host, streaming its
// stdout to ours. The exit code is the module's: a trap exits 2 (avra_trap),
// a normal answer exits what the program returned, so a trap never reads as
// an ordinary finish.
//
// A module that imports `avra_host` has a hosted scheduler (tasks): it runs
// under JSPI (`node --experimental-wasm-jspi` until Node ships it on), the
// program's entry on the first task's stack. Without JSPI it exits 3 and
// says so — never a silent pass.
import { WASI } from "node:wasi";
import fs from "node:fs";
import { hostedTasks, jspiAvailable } from "../runtime/dom/tasks.js";

const wasi = new WASI({
    version: "preview1",
    args: [process.argv[2]],
    env: {},
    returnOnExit: true,
});
const module = await WebAssembly.compile(fs.readFileSync(process.argv[2]));
const hosted = WebAssembly.Module.imports(module).some((i) => i.module === "avra_host");
if (!hosted) {
    const instance = await WebAssembly.instantiate(module, wasi.getImportObject());
    process.exitCode = wasi.start(instance);
} else if (!jspiAvailable()) {
    console.error("wasm-node: the module has tasks and this Node has no JSPI — run with --experimental-wasm-jspi");
    process.exitCode = 3;
} else {
    let instance = null;
    const tasks = hostedTasks(() => instance.exports);
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
    } catch (e) {
        // a trap or an exit after the first handover surfaces here, not in start()
        console.error(String(e && e.message ? e.message : e));
        return 2;
    }
    return code;
}
