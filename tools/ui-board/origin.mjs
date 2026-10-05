// An HTTP origin for one module and the page glue, for the browser proof:
// prints its address, serves until it is ended.
import http from "node:http";
import fs from "node:fs";
import path from "node:path";

const [glue, wasm] = process.argv.slice(2);
const html = "text/html; charset=utf-8";
const script = "text/javascript; charset=utf-8";
const served = {
  "/": [html, () => fs.readFileSync(path.join(glue, "page.html"), "utf8").replace("<!--TITLE-->", "Board")],
  "/app.wasm": ["application/wasm", () => fs.readFileSync(wasm)],
  "/bootstrap.js": [script, () => fs.readFileSync(path.join(glue, "bootstrap.js"))],
  "/wasi.js": [script, () => fs.readFileSync(path.join(glue, "wasi.js"))],
  "/wire.gen.js": [script, () => fs.readFileSync(path.join(glue, "wire.gen.js"))],
};
const server = http.createServer((asked, answer) => {
  const found = served[asked.url.split("?")[0]];
  if (!found) { answer.writeHead(404); answer.end(); return; }
  answer.writeHead(200, { "content-type": found[0] });
  answer.end(found[1]());
});
server.listen(0, "127.0.0.1", () => console.log(`http://127.0.0.1:${server.address().port}/`));
