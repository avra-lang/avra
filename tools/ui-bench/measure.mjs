// What a paint of the bench costs in a real browser. node measure.mjs <url>
import { openPage, firefoxBinary } from "../ui-board/firefox.mjs";

const [url] = process.argv.slice(2);
const page = await openPage(firefoxBinary(), url);
const { read, press } = page;
// The display's next frames, when the program's paint comes.
const frame = () => read("new Promise((done) => requestAnimationFrame(() => requestAnimationFrame(() => done(1))))");
for (let i = 0; i < 600; i++) {
  if (await read(`window.__ready !== undefined`).catch(() => false)) break;
  await new Promise((go) => setTimeout(go, 100));
}
const ready = await read(`window.__ready`);
await frame();
const nodes = await read(`document.querySelectorAll("*").length`);
const first = await read(`window.__frames[0]`);
const memory = await read(`window.__mod.memory.buffer.byteLength`);
const timed = async (what) => {
  const before = await read(`window.__frames.length`);
  const t0 = Date.now();
  await what();
  await frame();
  const spent = Date.now() - t0;
  const sizes = await read(`window.__frames.slice(${before})`);
  return { spent, frames: sizes.length, bytes: sizes.reduce((a, b) => a + b, 0) };
};
const tick = await timed(() => press(`[...document.querySelectorAll("button")].find((b) => b.getAttribute("aria-label") === "Tick the first")`));
const tickAgain = await timed(() => press(`[...document.querySelectorAll("button")].find((b) => b.getAttribute("aria-label") === "Tick the first")`));
console.log(JSON.stringify({ ready_ms: Math.round(ready), dom_nodes: nodes, first_frame_bytes: first, wasm_memory_mb: Math.round(memory / 1048576), tick, tickAgain }));
await page.close();
