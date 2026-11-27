// The time a host spends reading a frame: the board's first paint on each
// wire, as `src/main.av` wrote them under OUT, read by the readers generated
// from the program's types. The fastest of 101 reads after 20 to warm, in µs.
import { readFileSync } from "node:fs";
import { parseFrame } from "../../runtime/dom/bootstrap.js";
import { READ } from "../../runtime/dom/wire.gen.js";
import { reader } from "../../runtime/dom/frame.js";

const dir = process.argv[2];
const page = new Uint8Array(readFileSync(`${dir}/page.bin`));
const neutral = new Uint8Array(readFileSync(`${dir}/neutral.bin`));
const readNeutral = () => {
  const r = reader(neutral, []);
  r.byte();
  const patches = [];
  while (!r.ended()) patches.push(READ.NativePatch(r));
  return patches;
};
const fastest = (read) => {
  for (let k = 0; k < 20; k++) read();
  let best = Infinity;
  for (let k = 0; k < 101; k++) { const from = process.hrtime.bigint(); read(); best = Math.min(best, Number(process.hrtime.bigint() - from) / 1000); }
  return best.toFixed(0);
};
console.log(`page decode ${fastest(() => parseFrame(page, []))} us, ${parseFrame(page, []).length} records`);
console.log(`neutral decode ${fastest(readNeutral)} us, ${readNeutral().length} records`);
