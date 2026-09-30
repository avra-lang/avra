// THE wasm32-wasip1 HOST: runs a program `avra build --target wasm32-wasip1`
// wrote, under node's WASI, as a native binary runs — its arguments, the
// caller's environment, the filesystem at `/` and `.`, and its exit status.
import { WASI } from 'node:wasi';
import fs from 'node:fs';

const [program, ...args] = process.argv.slice(2);
const wasi = new WASI({
    version: 'preview1',
    args: [program, ...args],
    env: process.env,
    preopens: { '/': '/', '.': '.' },
    returnOnExit: true,
});
const module = await WebAssembly.compile(fs.readFileSync(program));
const instance = await WebAssembly.instantiate(module, wasi.getImportObject());
process.exitCode = wasi.start(instance);
