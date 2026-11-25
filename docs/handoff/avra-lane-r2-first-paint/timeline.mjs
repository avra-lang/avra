import path from "node:path"; import { pathToFileURL } from "node:url";
const { slowLink } = await import("/home/user/avra/tools/ui-board/slow_link.mjs");
const pw = await import(pathToFileURL(path.join(process.env.PLAYWRIGHT_DIR, "node_modules/playwright/index.mjs")).href);
const link = await slowLink({ target: 8765 });
const b = await pw.chromium.launch();
for (let n = 0; n < 3; n++) {
  const c = await b.newContext({ ...pw.devices["iPhone 13 Pro Max"] });
  await c.addInitScript(() => { new MutationObserver(() => { if (!globalThis.__ready && document.documentElement?.dataset.avra === "ready") globalThis.__ready = performance.now(); }).observe(document, { subtree: true, attributes: true }); });
  const p = await c.newPage(); link.reset();
  await p.goto(`http://127.0.0.1:${link.port}/`, { waitUntil: "commit" });
  await p.waitForFunction(() => globalThis.__ready);
  const r = await p.evaluate(() => ({ ready: Math.round(__ready), nav: Math.round(performance.getEntriesByType("navigation")[0].responseEnd), fcp: Math.round(performance.getEntriesByType("paint").find((x) => x.name === "first-contentful-paint")?.startTime), res: performance.getEntriesByType("resource").map((e) => [new URL(e.name).pathname.slice(0, 22), Math.round(e.startTime), Math.round(e.responseStart), Math.round(e.responseEnd), e.encodedBodySize]) }));
  console.log(JSON.stringify(r)); await c.close();
}
await b.close(); link.close();
