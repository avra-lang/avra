// Runs a WASI preview1 module under node: argv[2] is the module, the rest its arguments. Its exit is the module's.
import { readFileSync } from 'node:fs';
import { WASI } from 'node:wasi';
const wasi = new WASI({ version: 'preview1', args: [process.argv[2], ...process.argv.slice(3)], env: {}, preopens: { '.': '.' } });
const { instance } = await WebAssembly.instantiate(readFileSync(process.argv[2]), { wasi_snapshot_preview1: wasi.getImportObject().wasi_snapshot_preview1 });
process.exitCode = wasi.start(instance);
