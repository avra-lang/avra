// What a page pays for listeners: N buttons, each told to listen for a click, applied by
// one or more bootstrap.js files in a real Firefox — how many `addEventListener` calls it
// made, how long the frame took to apply, and what one dispatched click costs.
//
//   N=100000 node tools/ui-board/listen_bench/bench.mjs runtime/dom/bootstrap.js [old/bootstrap.js …]
//
// A file under comparison is served as-is beside the current wire table, so a
// bootstrap.js from an earlier commit (`git show <rev>:runtime/dom/bootstrap.js > old.js`)
// is measured against this one. Needs Firefox; skips, spoken, without it.
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { firefoxBinary, openPage } from "../firefox.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const wire = path.join(here, "../../../runtime/dom/wire.gen.js");
// a file under comparison brings its own wire table when it sits beside one
const wireOf = (f) => (fs.existsSync(path.join(path.dirname(f), "wire.gen.js")) ? path.join(path.dirname(f), "wire.gen.js") : wire);
const files = process.argv.slice(2).map((f) => path.resolve(f));
const binary = firefoxBinary();
if (!binary) { console.log("listen_bench: SKIPPED — no Firefox here"); process.exit(0); }
if (files.length === 0) { console.error("listen_bench: name at least one bootstrap.js"); process.exit(2); }

const served = new Map([["/", [path.join(here, "page.html"), "text/html"]]]);
files.forEach((f, i) => {
  served.set(`/v${i}/bootstrap.js`, [f, "text/javascript"]);
  served.set(`/v${i}/wire.gen.js`, [wireOf(f), "text/javascript"]);
});
const server = http.createServer((req, res) => {
  const hit = served.get(req.url.split("?")[0]);
  if (!hit) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { "content-type": hit[1] });
  res.end(fs.readFileSync(hit[0]));
}).listen(0);
await new Promise((r) => server.on("listening", r));
const n = Number(process.env.N || 100000);
for (const [i, f] of files.entries()) {
  const page = await openPage(binary, `http://127.0.0.1:${server.address().port}/?m=v${i}&n=${n}`);
  await new Promise((r) => setTimeout(r, 500));
  console.log(path.relative(process.cwd(), f), JSON.stringify(await page.read("window.__bench")));
  await page.close();
}
server.close();
