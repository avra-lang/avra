// Run a wasm32-wasi module under Node's WASI preview1 host, streaming its
// stdout to ours. The exit code is the module's: a trap exits 2 (avra_trap),
// a normal answer exits what the program returned, so a trap never reads as
// an ordinary finish.
import { WASI } from "node:wasi";
import fs from "node:fs";

const wasi = new WASI({
    version: "preview1",
    args: [process.argv[2]],
    env: {},
    returnOnExit: true,
});
const module = await WebAssembly.compile(fs.readFileSync(process.argv[2]));
const instance = await WebAssembly.instantiate(module, wasi.getImportObject());
process.exitCode = wasi.start(instance);
