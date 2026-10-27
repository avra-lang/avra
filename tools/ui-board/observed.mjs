// Opens a served page whose two views ask the same GET, beside the server that answers it, and prints what the
// browser sent and what the page did with it:
//   - the two views made ONE request for /tasks, and both show its answer;
//   - asking again sent the version held, the server answered 304, and the page changed not at all;
//   - after a write the next ask answered new, and the page shows it.
//   node observed.mjs <page url>
import { openPage, firefoxBinary } from "./firefox.mjs";

const [url] = process.argv.slice(2);
const page = await openPage(firefoxBinary(), url);
const waits = async (holds) => { for (let i = 0; i < 100; i++) { if (await page.read(holds).catch(() => false)) return true; await new Promise((go) => setTimeout(go, 100)); } return false; };
const sent = () => page.read(`performance.getEntriesByType("resource").filter((e) => new URL(e.name).pathname === "/tasks").map((e) => e.responseStatus)`);
const words = () => page.read(`document.body.textContent`);
const press = (name) => page.press(`[...document.querySelectorAll('[aria-label=${JSON.stringify(name)}]')][0]`);
const said = [];
const claim = (what, holds, seen) => { said.push(`${holds ? "ok" : "FAILED"} ${what}${holds ? "" : ` — saw ${JSON.stringify(seen)}`}`); return holds; };

let good = true;
const both = await waits(`/left ready \\d+/.test(document.body.textContent) && /right ready \\d+/.test(document.body.textContent)`);
const first = await sent();
good = claim("two views asking one GET sent it once", both && first.length === 1 && first[0] === 200, first) && good;

await page.read(`(() => { window.__moved = 0; new MutationObserver((m) => { window.__moved += m.length; }).observe(document.body, { subtree: true, childList: true, characterData: true, attributes: true }); return 1; })()`);
const before = await words();
await page.read(`(() => { window.__texts = []; window.__sampler = setInterval(() => window.__texts.push(document.body.textContent), 5); return 1; })()`);
await press("Again");
const asked = await waits(`performance.getEntriesByType("resource").filter((e) => new URL(e.name).pathname === "/tasks").length === 2`);
await new Promise((go) => setTimeout(go, 300));
const second = await sent();
good = claim("asking again sent the version it held and the server answered 304", asked && second[1] === 304, second) && good;
const texts = JSON.parse(await page.read(`(() => { clearInterval(window.__sampler); return JSON.stringify(window.__texts); })()`));
const lost = texts.filter((s) => !(/left ready \d+/.test(s) && /right ready \d+/.test(s)));
good = claim("asking again never drew a loading word: every sample held both answers", texts.length >= 20 && lost.length === 0, { samples: texts.length, lost: lost.slice(0, 2) }) && good;
good = claim("a 304 changed nothing on the page", (await words()) === before && (await page.read(`window.__moved`)) === 0, await page.read(`window.__moved`)) && good;

await press("Add");
await waits(`performance.getEntriesByType("resource").filter((e) => new URL(e.name).pathname === "/tasks").length === 3`);
await press("Again");
await waits(`performance.getEntriesByType("resource").filter((e) => new URL(e.name).pathname === "/tasks").length === 4`);
const grown = await waits(`/left ready \\d+/.test(document.body.textContent) && document.body.textContent !== ${JSON.stringify(before)}`);
const last = await sent();
good = claim("after a write the next ask answered 200 and the page shows the new answer", grown && last[3] === 200, last) && good;

await page.close();
console.log(said.join("\n"));
process.exit(good ? 0 : 1);
