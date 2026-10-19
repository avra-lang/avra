// Measures how the page paints when several sources land together: frames
// sent, patches in them and bytes, for the real board module. Prints; claims
// nothing. Usage: node paints.mjs <board.wasm>
import fs from "node:fs";
import { run, parseFrame } from "../../runtime/dom/bootstrap.js";
import { wasiPreview1 } from "../../runtime/dom/wasi.js";
import { stubDocument, stubElement } from "../../runtime/dom/stub_dom.js";

const mount = stubElement("root");
const frames = [];
const armed = new Map();
const clock = {
  setTimeout: (fn, ms) => { const h = armed.size + 1; armed.set(h, { fn, ms }); return h; },
  setInterval: (fn, ms) => { const h = armed.size + 1; armed.set(h, { fn, ms }); return h; },
  clearTimeout: (h) => armed.delete(h),
  clearInterval: (h) => armed.delete(h),
};
const asked = [];
const fetchFn = (url, init) => new Promise((resolve, reject) => asked.push({ url, init, resolve, reject }));
await run(new Uint8Array(fs.readFileSync(process.argv[2])), {
  document: stubDocument(),
  mount,
  style: { textContent: "" },
  wasi: (memory) => wasiPreview1(memory, (code) => { throw new Error(`exit ${code}`); }),
  sent: (bytes) => frames.push({ bytes: bytes.length, patches: parseFrame(bytes).length }),
  clock,
  fetch: fetchFn,
});
const every = (n, hit, out = []) => { if (hit(n)) out.push(n); n.childNodes.forEach((c) => every(c, hit, out)); return out; };
const named = (name) => every(mount, (n) => n.attrs["aria-label"] === name && n.listeners.size > 0)[0];
const fire = (n) => { const [, listener] = [...n.listeners][0]; listener(); };
const settle = async () => { for (let k = 0; k < 8; k++) await Promise.resolve(); };
const total = () => ({ frames: frames.length, patches: frames.reduce((a, f) => a + f.patches, 0), bytes: frames.reduce((a, f) => a + f.bytes, 0) });
const since = (mark) => { const t = total(); return `${t.frames - mark.frames} frame(s), ${t.patches - mark.patches} patch(es), ${t.bytes - mark.bytes} byte(s)`; };

// One tick of the page's event loop: a timer fires, a fetch answers, and the
// user presses a button, back to back.
fire(named("Remind me"));
fire(named("Sync"));
await settle();
let mark = total();
[...armed.values()][0].fn();
asked[0].resolve({ status: 200, arrayBuffer: async () => new TextEncoder().encode("12345").buffer });
await settle();
fire(named("Dark mode"));
console.log(`a timer, a fetch answer and a press in one tick: ${since(mark)}`);

// The same timer fired three times in one tick (a stalled tab catching up).
fire(named("Remind me"));
fire(named("Remind me"));
fire(named("Remind me"));
mark = total();
for (const t of [...armed.values()].slice(-3)) t.fn();
console.log(`three timers in one tick, the second and third changing nothing: ${since(mark)}`);
