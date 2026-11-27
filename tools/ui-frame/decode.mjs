// The time a page's host spends reading a frame: the board's first paint,
// as `src/main.av` wrote it under OUT, read by the host's own reader. The
// fastest of 101 reads after 20 to warm, in µs.
import { readFileSync } from "node:fs";
import { parseFrame } from "../../runtime/dom/bootstrap.js";

const dir = process.argv[2];
const page = new Uint8Array(readFileSync(`${dir}/page.bin`));
const fastest = (read) => {
  for (let k = 0; k < 20; k++) read();
  let best = Infinity;
  for (let k = 0; k < 101; k++) { const from = process.hrtime.bigint(); read(); best = Math.min(best, Number(process.hrtime.bigint() - from) / 1000); }
  return best.toFixed(0);
};
console.log(`page decode ${fastest(() => parseFrame(page))} us, ${parseFrame(page).length} records`);
