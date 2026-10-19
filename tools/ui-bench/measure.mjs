// What a paint of the bench costs in a real browser. node measure.mjs <url>
import { openPage, firefoxBinary } from "../ui-board/firefox.mjs";

const [url, mode] = process.argv.slice(2);
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
// FROM THE CLICK TO THE FRAME, inside the page: no driver round trip, no waits for frames.
const inPage = async () => read(`(async () => {
  const b = [...document.querySelectorAll("button")].find((x) => x.getAttribute("aria-label") === "Tick the first");
  const n = window.__times.length;
  const t0 = performance.now();
  b.click();
  while (window.__times.length === n) await new Promise((go) => setTimeout(go, 0));
  return Math.round((window.__times[n] - t0) * 10) / 10;
})()`);
const inPageMs = [];
for (let i = 0; i < 5; i++) { inPageMs.push(await inPage()); await frame(); }
const tick = await timed(() => press(`[...document.querySelectorAll("button")].find((b) => b.getAttribute("aria-label") === "Tick the first")`));
const tickAgain = await timed(() => press(`[...document.querySelectorAll("button")].find((b) => b.getAttribute("aria-label") === "Tick the first")`));
// WINDOWED: the page is scrolled to the top, the middle and the bottom; at each the rows
// built stay bounded and the row at the screen's centre is the one the scroll
// position names.
const scrolls = [];
const claims = {};
if (mode === "windowed") {
  const settle = async () => { for (let i = 0; i < 6; i++) await frame(); };
  await settle();
  const total = await read(`document.documentElement.scrollHeight`);
  for (const at of [0, 0.5, 0.999, 0.25]) {
    const t0 = Date.now();
    await read(`(window.scrollTo(0, Math.floor((document.documentElement.scrollHeight - innerHeight) * ${at})), 1)`);
    await settle();
    const spent = Date.now() - t0;
    const nodes = await read(`document.querySelectorAll("*").length`);
    const centre = await read(`(() => { const e = document.elementFromPoint(innerWidth / 2, innerHeight / 2); const m = e && /Row number (\\d+)/.exec(e.closest("li") ? e.closest("li").textContent : ""); return m ? Number(m[1]) : -1; })()`);
    const height = await read(`document.documentElement.scrollHeight`);
    scrolls.push({ at, spent, nodes, centre, scroll_height: height });
  }
  // THE LIST TELLS A SCREEN READER WHERE A ROW STANDS IN THE WHOLE, built or not.
  claims.rowcount = await read(`(() => { const r = document.querySelector("li[aria-setsize]"); return r ? Number(r.getAttribute("aria-setsize")) : -1; })()`);
  // THE FOCUSED ROW STAYS BUILT: focus the first row's box, scroll far away, and the focus is still there.
  await read(`(window.scrollTo(0, 0), 1)`);
  await settle();
  await read(`(document.querySelector("li input[type=checkbox]").focus(), 1)`);
  await settle();
  await read(`(window.scrollTo(0, document.documentElement.scrollHeight), 1)`);
  await settle();
  claims.focus_kept = await read(`document.activeElement ? document.activeElement.getAttribute("aria-label") : null`);
  claims.focus_nodes = await read(`document.querySelectorAll("*").length`);
  await read(`(document.activeElement.blur(), 1)`);
  await settle();
  // ASKED TO SHOW A ROW, THE PAGE SCROLLS TO IT.
  await press(`[...document.querySelectorAll("button")].find((b) => b.getAttribute("aria-label") === "Jump to the middle")`);
  await settle();
  claims.jump_top = await read(`(() => { const want = "r" + Math.floor(document.querySelectorAll("li[aria-setsize]")[0].getAttribute("aria-setsize") / 2); const e = document.querySelector('li[data-key="' + want + '"]'); return e ? Math.round(e.getBoundingClientRect().top) : null; })()`);
}
console.log(JSON.stringify({ click_to_frame_ms: inPageMs, claims, scrolls, total_height: scrolls.length ? await read(`document.documentElement.scrollHeight`) : 0, ready_ms: Math.round(ready), dom_nodes: nodes, first_frame_bytes: first, wasm_memory_mb: Math.round(memory / 1048576), tick, tickAgain }));
await page.close();
