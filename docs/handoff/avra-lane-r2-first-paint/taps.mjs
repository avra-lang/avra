// Taps before adoption, measured: the board through the slow link, a phone's profile, a tap the
// moment the server's paint stands — with and without the held-tap script — and when (if ever) the
// module answers it.  node taps.mjs <page url> <out dir> [--runs n]
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";
const [url, out, ...words] = process.argv.slice(2);
const runs = Number(words[words.indexOf("--runs") + 1] || 3);
const board = "/home/user/avra/tools/ui-board";
const { slowLink } = await import(pathToFileURL(path.join(board, "slow_link.mjs")).href);
const pw = await import(pathToFileURL(path.join(process.env.PLAYWRIGHT_DIR, "node_modules/playwright/index.mjs")).href);
const held = fs.readFileSync(new URL("./held.js", import.meta.url), "utf8");
const origin = new URL(url);
const link = await slowLink({ target: Number(origin.port) });
const slow = `http://127.0.0.1:${link.port}/`;
const browser = await pw.chromium.launch();
fs.mkdirSync(out, { recursive: true });

const watch = () => {
  const seen = (globalThis.__t = { painted: null, ready: null, wrote: null });
  const f = globalThis.fetch;
  globalThis.fetch = function (input, init) {
    const u = new URL(typeof input === "string" ? input : input.url, location.href);
    const m = (init?.method ?? input?.method ?? "GET").toUpperCase();
    if (seen.wrote === null && m !== "GET" && u.pathname.startsWith("/tasks")) seen.wrote = performance.now();
    return f.apply(this, arguments);
  };
  new MutationObserver(() => {
    if (seen.painted === null && document.querySelector('#app button[aria-label="Add"]')) seen.painted = performance.now();
    if (seen.ready === null && document.documentElement?.dataset.avra === "ready") seen.ready = performance.now();
  }).observe(document, { subtree: true, childList: true, attributes: true });
};

async function one(kind, scenario, n, shots) {
  const context = await browser.newContext({ ...pw.devices["iPhone 13 Pro Max"] });
  await context.addInitScript(watch);
  if (kind === "held") await context.addInitScript(held);
  const page = await context.newPage();
  link.reset();
  await page.goto(slow, { waitUntil: "commit" });
  await page.waitForFunction(() => globalThis.__t?.painted !== null, null, { timeout: 30000 });
  const title = `Buy milk ${kind} ${n} ${Date.now() % 100000}`;
  let tapped, answered = null;
  const statusText = () => page.evaluate(() => [...document.querySelectorAll("#app span.color-muted")].pop()?.textContent ?? "");
  const stored = async () => (await (await fetch(new URL("/tasks", origin))).json()).find((x) => x.id === 1)?.done;
  const before = scenario === "add" ? await statusText() : await stored();
  if (scenario === "add") {
    await page.tap('input[aria-label="New task"]');
    await page.keyboard.type(title, { delay: 0 });
    tapped = await page.evaluate(() => performance.now());
    await page.tap('button[aria-label="Add"]');
  } else {
    tapped = await page.evaluate(() => performance.now());
    await page.tap('#app li input[type="checkbox"]');
  }
  const readyAtTap = await page.evaluate(() => globalThis.__t.ready);
  if (shots) await page.screenshot({ path: path.join(out, `${scenario}-${kind}-1-tapped.png`) });
  const done = scenario === "add"
    ? (t) => [...document.querySelectorAll("#app li")].some((li) => li.textContent.includes(t))
    : () => globalThis.__t.wrote !== null;
  const arg = scenario === "add" ? title : before;
  await page.waitForFunction(() => globalThis.__t.ready !== null, null, { timeout: 30000 });
  try {
    await page.waitForFunction(done, arg, { timeout: 8000, polling: 16 });
    answered = await page.evaluate(() => performance.now());
  } catch { answered = null; }
  const t = await page.evaluate(() => globalThis.__t);
  if (shots) await page.screenshot({ path: path.join(out, `${scenario}-${kind}-2-after.png`) });
  await page.waitForTimeout(1200);
  const flipped = scenario === "toggle" ? (await stored()) !== before : null;
  const boxShown = scenario === "toggle" ? await page.evaluate(() => document.querySelector("#app li input").checked) : null;
  const field = scenario === "add" ? await page.evaluate(() => document.querySelector('#app input[aria-label="New task"]').value) : "";
  await context.close();
  return { kind, scenario, painted: Math.round(t.painted), tapped: Math.round(tapped), ready: Math.round(t.ready), tapped_before_ready: readyAtTap === null, answered: answered === null ? null : Math.round(answered), wrote: t.wrote === null ? null : Math.round(t.wrote), flipped, box_shown: boxShown, stored_after: scenario === "toggle" ? await stored() : null, field_after: field };
}

const results = [];
for (const scenario of ["add", "toggle"]) {
  for (const kind of ["today", "held"]) {
    for (let n = 0; n < runs; n++) results.push(await one(kind, scenario, n, false));
  }
}
await browser.close();
link.close();
fs.writeFileSync(path.join(out, "taps.json"), JSON.stringify(results, null, 1));
for (const r of results) console.log(JSON.stringify(r));
