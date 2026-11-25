// Serves the bench module on a bare page, for measuring a paint in a browser.
//
//   node serve.mjs <module.wasm> <runtime/dom>
//
// Says `serving http://127.0.0.1:<port>/` and stays until killed. The page
// runs the module with a `sent` hook that notes every frame's size, and keeps
// the module on `window.__mod`, so the driver can read its memory.
import fs from "node:fs";
import http from "node:http";
import path from "node:path";

const [wasmFile, glue] = process.argv.slice(2);
const page = `<!doctype html><html><head><meta charset="utf-8"><title>bench</title><style id="avra-style"></style></head><body><div id="app"></div><script type="module">
import { run } from "/avra/bootstrap.js";
import { wasiPreview1 } from "/avra/wasi.js";
window.__frames = [];
window.__times = [];
window.__t0 = performance.now();
window.__mod = await run("/app.wasm", {
  document,
  mount: document.getElementById("app"),
  style: document.getElementById("avra-style"),
  sent: (bytes) => { window.__frames.push(bytes.length); window.__times.push(performance.now()); },
  wasi: (memory) => wasiPreview1(memory, (code) => { throw new Error("exit " + code); }),
});
window.__ready = performance.now() - window.__t0;
</script></body></html>`;
const types = { ".js": "text/javascript", ".wasm": "application/wasm" };
const server = http.createServer((req, res) => {
  const url = new URL(req.url, "http://x");
  const send = (kind, body) => { res.writeHead(200, { "content-type": kind, "cache-control": "no-store" }); res.end(body); };
  if (url.pathname === "/") return send("text/html; charset=utf-8", page);
  if (url.pathname === "/app.wasm") return send(types[".wasm"], fs.readFileSync(wasmFile));
  if (url.pathname.startsWith("/avra/")) {
    const file = path.join(glue, path.basename(url.pathname));
    if (fs.existsSync(file)) return send(types[".js"], fs.readFileSync(file));
  }
  res.writeHead(404).end();
});
server.listen(0, "127.0.0.1", () => console.log(`serving http://127.0.0.1:${server.address().port}/`));
