// The page's cache, read from a dev server. A served page whose two views ask one GET tells `avra dev` a snapshot
// of its cache (`/@dev/cache`); the dev server tells it on its channel (`/@dev/events`) as a `cache` event, and
// `avra explain --cache --live` reads that channel. The claims: a snapshot naming the entry arrives; the terminal
// reader says it; and asking again moves the counts in a later snapshot.
//   node hud.mjs <page url> <avra binary>
import { execFile } from "node:child_process";
import { openPage, firefoxBinary } from "./firefox.mjs";

const [url, avra] = process.argv.slice(2);
const origin = new URL(url);

// The next `cache` event on the channel whose frame `wanted` accepts, within `wait` ms: the stream read as text.
async function snapshot(wanted, wait = 10000) {
  const stop = new AbortController();
  const late = setTimeout(() => stop.abort(), wait);
  try {
    const res = await fetch(new URL("/@dev/events", origin), { headers: { accept: "text/event-stream" }, signal: stop.signal });
    const reader = res.body.getReader();
    const decoder = new TextDecoder();
    let buffer = "";
    for (;;) {
      const { done, value } = await reader.read();
      if (done) return null;
      buffer += decoder.decode(value, { stream: true }).replace(/\r\n?/g, "\n");
      for (let at = buffer.indexOf("\n\n"); at >= 0; at = buffer.indexOf("\n\n")) {
        const block = buffer.slice(0, at);
        buffer = buffer.slice(at + 2);
        if (!block.startsWith("event: cache") && !block.includes("\nevent: cache")) continue;
        const data = block.split("\n").filter((l) => l.startsWith("data: ")).map((l) => l.slice(6)).join("\n");
        const said = JSON.parse(data);
        if (process.env.HUD_DEBUG) console.error(`frame ${said.tab} ${JSON.stringify(said.frame.counts)}`);
        if (wanted(said.frame)) { stop.abort(); return said; }
      }
    }
  } catch (_) {
    return null;
  } finally {
    clearTimeout(late);
  }
}

const reading = (frame) => frame.rows.find((r) => r.key === "/tasks");

const page = await openPage(firefoxBinary(), url);
const settled = `/left ready \\d+/.test(document.body.textContent) && /right ready \\d+/.test(document.body.textContent)`;
let both = false;
for (let tries = 0; tries < 100 && !both; tries++) {
  both = await page.read(settled).catch(() => false);
  if (!both) await new Promise((done) => setTimeout(done, 100));
}
const first = await snapshot((f) => reading(f)?.state === "ready");
const told = first ? reading(first.frame) : null;

const said = await new Promise((done) => {
  execFile(avra, ["explain", "--cache", "--live", "--port", origin.port, "--frames", "1"], { timeout: 20000 }, (error, stdout) => done(error ? "" : stdout));
});

// The page's stream says where the database stands within a moment; then asking again is skipped, as fresh.
await new Promise((done) => setTimeout(done, 1500));
const before = first ? first.frame.counts : { asks: 0, skipped: 0 };
await page.press(`[...document.querySelectorAll('[aria-label="Again"]')][0]`);
const again = await snapshot((f) => f.counts.asks > before.asks || f.counts.skipped > before.skipped);

// THE PANEL: a module of its own, in a shadow root beside the app. It is told what the server says; opened, it draws
// the entry the views read, and the app's own tree is untouched by it.
const panelText = () => page.read(`(() => { const h = document.getElementById("avra-dev-panel"); return h && h.shadowRoot ? h.shadowRoot.textContent : null; })()`);
let panelAt = null;
for (let tries = 0; tries < 100 && !(panelAt || "").includes("1 tab"); tries++) {
  panelAt = await panelText();
  if (!(panelAt || "").includes("1 tab")) await new Promise((done) => setTimeout(done, 100));
}
const appBefore = await page.read(`document.getElementById("app").innerHTML`);
await page.press(`document.getElementById("avra-dev-panel").shadowRoot.querySelector('[aria-label="cache ▸"]')`);
let opened = "";
for (let tries = 0; tries < 50 && !opened.includes("/tasks"); tries++) {
  opened = (await panelText()) || "";
  if (!opened.includes("/tasks")) await new Promise((done) => setTimeout(done, 100));
}
const appAfter = await page.read(`document.getElementById("app").innerHTML`);
await page.close();

const claims = {
  "both views settled": both,
  "a snapshot names the entry the views read, ready": told !== null && told.readers === 2,
  "the terminal reader says it": /── tab [0-9a-z]+ ──/.test(said) && said.includes("/tasks") && /asks \d+/.test(said),
  "asking again moves the counts in a later snapshot (sent, or skipped as fresh)": again !== null,
  "the panel stands in a shadow root and knows the page's one tab": (panelAt || "").includes("1 tab"),
  "opened, the panel draws the entry the views read": opened.includes("/tasks") && opened.includes("tab "),
  "and the app's own tree is the same with the panel open": appBefore === appAfter,
};
for (const [claim, held] of Object.entries(claims)) console.log(`${held ? "ok  " : "FAIL"} ${claim}`);
process.exit(Object.values(claims).every(Boolean) ? 0 : 1);
