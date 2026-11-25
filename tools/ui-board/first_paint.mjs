// THE BOARD'S FIRST PAINT, HELD BY COUNTERS: the page `avra dev` serves, loaded as a phone loads
// it — through a slow link (slow_link.mjs: 120 ms round trips, 4 Mbit/s each way) in an engine
// Playwright drives under a phone's profile — and its fetches counted. Each claim is a count, never
// a stopwatch, and one failure exits 1:
//   - every file the page fetches is asked for before any of them has arrived: the chain after the
//     document is one deep, because the document names them all;
//   - each is asked for once (a preload whose mode is not the fetch's is a second request);
//   - the octets the link carries down for a cold load stand at or under the recorded budget
//     (first_paint.budget), which only ever shrinks;
//   - a reload carries less than the module: the module, named by its content, is kept.
// Beside them one time is REPORTED, never judged: first paint and the tasks listed, cold and warm.
//
//   node first_paint.mjs <page url> [--engine webkit|chromium] [--device "iPhone 13 Pro Max"]
//
// PLAYWRIGHT_DIR names the directory holding node_modules/playwright (else it is imported by name).
// Exit 3 says the engine could not launch here, and why.
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { slowLink } from "./slow_link.mjs";

const [url, ...words] = process.argv.slice(2);
const word = (name, fallback) => { const at = words.indexOf(name); return at < 0 ? fallback : words[at + 1]; };
const engine = word("--engine", "webkit");
const device = word("--device", "iPhone 13 Pro Max");
const budget = Object.fromEntries(fs.readFileSync(new URL("./first_paint.budget", import.meta.url), "utf8").split("\n").filter((l) => /^\w+ \d+$/.test(l)).map((l) => l.split(" ")).map(([k, v]) => [k, Number(v)]));

const dir = process.env.PLAYWRIGHT_DIR;
const playwright = await import(dir ? pathToFileURL(path.join(dir, "node_modules/playwright/index.mjs")).href : "playwright").catch((e) => ({ said: String(e.message).split("\n")[0] }));
let browser;
try { browser = await playwright[engine].launch(); } catch (e) { console.log(`first-paint: ${engine} could not launch — ${String(e?.message ?? playwright.said).split("\n")[0]}`); process.exit(3); }

let failed = 0;
const claim = (what, holds, said = "") => { if (holds) console.log(`ok ${what}`); else { failed++; console.log(`FAILED ${what}${said ? ` — ${said}` : ""}`); } };

// A task the board lists, so "listed" has a word to wait for.
const origin = new URL(url);
const tasks = await (await fetch(new URL("/tasks", origin))).json();
const title = tasks[0]?.title ?? "Draft the spec";
if (tasks.length === 0) await fetch(new URL("/tasks", origin), { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ title, done: false }) });

const link = await slowLink({ target: Number(origin.port) });
const slow = `http://127.0.0.1:${link.port}/`;
// The page's own files: every fetch but the document, the server's routes and dev's channel.
const own = (u) => { const p = new URL(u).pathname; return p !== "/" && !p.startsWith("/@dev/") && !p.startsWith("/tasks"); };

// One load in `context`: each own file's request and arrival times, the octets carried down, and
// the times the page reports for its first paint, its tasks listed and its module standing.
async function loaded(context) {
  const page = await context.newPage();
  const asked = [], arrived = new Map();
  page.on("request", (r) => { if (own(r.url())) asked.push({ path: new URL(r.url()).pathname, at: performance.now() }); });
  page.on("requestfinished", (r) => { if (own(r.url())) arrived.set(new URL(r.url()).pathname, performance.now()); });
  link.reset();
  await page.goto(slow, { waitUntil: "commit" });
  await page.waitForFunction((t) => document.documentElement.dataset.avra === "ready" && document.getElementById("app")?.textContent.includes(t), title, { timeout: 60000 });
  await page.waitForTimeout(250);
  const times = await page.evaluate(() => ({ ...globalThis.__painted, fcp: performance.getEntriesByType("paint").find((p) => p.name === "first-contentful-paint")?.startTime ?? null }));
  const carried = link.carried();
  await page.close();
  return { asked, arrived, carried, times };
}

const context = await browser.newContext({ ...(playwright.devices[device] ?? {}) });
await context.addInitScript((t) => {
  const seen = (globalThis.__painted = { drawn: null, listed: null });
  const look = () => {
    const app = document.getElementById("app");
    if (seen.drawn === null && app?.firstElementChild) seen.drawn = performance.now();
    if (seen.listed === null && app?.textContent.includes(t)) seen.listed = performance.now();
  };
  new MutationObserver(look).observe(document, { subtree: true, childList: true, characterData: true });
}, title);
const cold = await loaded(context);
const warm = await loaded(context);
await browser.close();
link.close();

const firstArrival = Math.min(...cold.arrived.values());
const late = cold.asked.filter((a) => a.at > firstArrival).map((a) => a.path);
claim(`every file the page fetches is asked for before any has arrived (${cold.asked.length} files, one deep after the document)`, cold.asked.length > 0 && late.length === 0, `asked only after another arrived: ${late.join(", ")}`);
const counts = cold.asked.reduce((m, a) => m.set(a.path, (m.get(a.path) ?? 0) + 1), new Map());
const twice = [...counts].filter(([, n]) => n > 1).map(([p, n]) => `${p} ×${n}`);
claim("each file is asked for once", twice.length === 0, twice.join(", "));
claim(`a cold load carries ${cold.carried} octets down, within the recorded ${budget.cold}`, cold.carried <= budget.cold, "a change that grew the page's bytes raises first_paint.budget, and says why");
const module = cold.asked.find((a) => a.path.endsWith(".wasm"))?.path ?? "(none)";
claim(`a reload carries ${warm.carried} octets down: the module ${module} is kept, not carried again`, warm.carried <= budget.warm, `more than the recorded ${budget.warm}`);

const ms = (v) => (v === null || v === undefined ? "-" : `${Math.round(v)} ms`);
console.log(`reported (${engine}, ${device}, 120 ms / 4 Mbit/s): cold first paint ${ms(cold.times.fcp ?? cold.times.drawn)}, listed ${ms(cold.times.listed)}; warm first paint ${ms(warm.times.fcp ?? warm.times.drawn)}, listed ${ms(warm.times.listed)}`);
process.exit(failed === 0 ? 0 : 1);
