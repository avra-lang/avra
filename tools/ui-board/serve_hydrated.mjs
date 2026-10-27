// Serves the board as a SERVER would: the document the server drew
// (`hydrate/main.av`'s third line), the module, and the page glue. With
// `--tampered` the document's first element is dropped before the module
// loads, so the module meets a page that is not the one it would draw. With
// `--backend <url>` every path the page does not own is the app's server's,
// as it is where the page ships.
//
// With `--hold` each page's first GET of `/tasks` waits at the proxy until something asks for
// `/__release`: the page stands on the server's own paint, with no list answered, for as
// long as a claim needs. Every load of the document arms a fresh hold, so each engine's run has its own.
//
//   node serve_hydrated.mjs <document> <module.wasm> <runtime/dom> [--tampered] [--hold] [--backend <url>]
//
// Says `serving http://127.0.0.1:<port>/` and stays until killed.
import fs from "node:fs";
import http from "node:http";
import path from "node:path";

const [documentFile, wasmFile, glue, ...flags] = process.argv.slice(2);
const tampered = flags.includes("--tampered");
const hold = flags.includes("--hold");
let release = () => {};
let released = Promise.resolve();
const armed = () => { released = new Promise((go) => { release = go; }); };
armed();
const backend = flags.includes("--backend") ? flags[flags.indexOf("--backend") + 1] : null;

// Before the module runs, every element the server drew is marked, so a page
// that kept them can be told from one that drew them again.
const marker = `<script>for (const el of document.querySelectorAll("#app *")) el.__served = true;${tampered ? ' document.querySelector("#app").firstElementChild.remove();' : ""}</script>`;
const page = fs.readFileSync(documentFile, "utf8").replace('<script type="module">', `${marker}<script type="module">`);

const types = { ".js": "text/javascript", ".wasm": "application/wasm", ".html": "text/html; charset=utf-8" };
const served = (res, kind, body) => { res.writeHead(200, { "content-type": kind, "cache-control": "no-store" }); res.end(body); };
const server = http.createServer((req, res) => {
  const url = new URL(req.url, "http://x");
  if (url.pathname === "/") { armed(); return served(res, types[".html"], page); }
  if (url.pathname === "/app.wasm") return served(res, types[".wasm"], fs.readFileSync(wasmFile));
  if (url.pathname.startsWith("/avra/")) {
    const file = path.join(glue, path.basename(url.pathname));
    if (fs.existsSync(file)) return served(res, types[".js"], fs.readFileSync(file));
  }
  if (url.pathname === "/__release") { release(); return res.writeHead(204).end(); }
  if (!backend) return res.writeHead(404).end();
  const forward = () => {
    const ahead = http.request(new URL(url.pathname + url.search, backend), { method: req.method, headers: req.headers }, (answer) => {
      res.writeHead(answer.statusCode, answer.headers);
      answer.pipe(res);
    });
    ahead.on("error", () => res.writeHead(502).end());
    req.pipe(ahead);
  };
  if (hold && req.method === "GET" && url.pathname === "/tasks") released.then(forward); else forward();
});
server.listen(0, "127.0.0.1", () => console.log(`serving http://127.0.0.1:${server.address().port}/`));
