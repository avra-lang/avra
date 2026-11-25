// Screenshots of a tap before adoption, the module held back 1.5 s so the moment is visible.
import fs from "node:fs"; import path from "node:path"; import { pathToFileURL } from "node:url";
const pw = await import(pathToFileURL(path.join(process.env.PLAYWRIGHT_DIR, "node_modules/playwright/index.mjs")).href);
const out = process.argv[2]; const b = await pw.chromium.launch();
for (const kind of ["today", "held"]) {
  const c = await b.newContext({ ...pw.devices["iPhone 13 Pro Max"] });
  if (kind === "held") await c.addInitScript(fs.readFileSync("held.js", "utf8"));
  await c.route(/\.wasm$/, async (r) => { await new Promise((ok) => setTimeout(ok, 1500)); await r.continue(); });
  const p = await c.newPage();
  await p.goto("http://127.0.0.1:8765/", { waitUntil: "commit" });
  await p.waitForSelector('#app button[aria-label="Add"]');
  await p.tap('input[aria-label="New task"]'); await p.keyboard.type(`Buy milk (${kind})`); await p.tap('button[aria-label="Add"]');
  console.log(kind, "before adoption:", await p.evaluate(() => JSON.stringify({ avra: document.documentElement.dataset.avra ?? "not standing", held: [...document.querySelectorAll("[data-avra-held]")].map((e) => e.outerHTML.slice(0, 60)), styled: [...document.querySelectorAll("style")].some((s) => s.textContent.includes("avra-held")), op: getComputedStyle(document.querySelector("button[aria-label=Add]")).opacity })));
  await p.screenshot({ path: path.join(out, `${kind}-1-tapped-before-adoption.png`) });
  await p.waitForFunction(() => document.documentElement.dataset.avra === "ready");
  await p.waitForTimeout(700);
  console.log(kind, "after:", await p.evaluate(() => JSON.stringify({ li: [...document.querySelectorAll("#app li span")].map((s) => s.textContent), field: document.querySelector('#app input[aria-label="New task"]').value })));
  await p.screenshot({ path: path.join(out, `${kind}-2-after-adoption.png`) });
  await c.close();
}
await b.close();
