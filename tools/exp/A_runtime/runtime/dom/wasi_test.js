// Proves the browser WASI surface reads an iovec the way preview1 says:
// fd_write copies the bytes it is told to, and reports how many it wrote.
import { wasiPreview1 } from "./wasi.js";

const buf = new ArrayBuffer(256);
const dv = new DataView(buf);
const mem = { buffer: buf };
const wasi = wasiPreview1(() => mem, () => {});

// iovec at 0: base 64, len 5; "hello" parked at 64.
dv.setUint32(0, 64, true);
dv.setUint32(4, 5, true);
new Uint8Array(buf).set(new TextEncoder().encode("hello"), 64);

let fails = 0;
const check = (name, got, want) => {
  const g = JSON.stringify(got), w = JSON.stringify(want);
  if (g !== w) { fails++; console.log(`✗ ${name}\n  got  ${g}\n  want ${w}`); } else console.log(`✓ ${name}`);
};

const said = [];
const real = console.log;
console.log = (s) => said.push(s);
const rc = wasi.fd_write(1, 0, 1, 128);
console.log = real;

check("fd_write answers 0", rc, 0);
check("it printed the bytes the iovec named", said, ["hello"]);
check("and reported the count it wrote", dv.getUint32(128, true), 5);
check("an unknown call is simply absent, never a no-op", typeof wasi.path_open, "undefined");

console.log(fails === 0 ? "wasi: 4/4" : `wasi: ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
