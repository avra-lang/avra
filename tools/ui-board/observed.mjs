// Opens a served page whose two views ask the same GET, beside the server that answers it, and prints what the
// browser sent and what the page did with it:
//   - the two views made ONE request for /tasks, and both show its answer;
//   - the server announces changes on a stream the page listens to, so asking again sends nothing;
//   - a write by ANOTHER client reaches the page on that stream, and it asks again by itself;
//   - its own write's answer names the table it touched, and it asks again at once.
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
// The server announces what changes on a stream the page listens to; give it the moment it takes to say where the database stands.
await new Promise((go) => setTimeout(go, 1500));
await press("Again");
await new Promise((go) => setTimeout(go, 600));
good = claim("with its stream up, asking again sends nothing and the page does not move", (await sent()).length === 1 && (await page.read(`window.__moved`)) === 0, [await sent(), await page.read(`window.__moved`)]) && good;

// Another client writes: the page is told by the stream and asks again by itself.
const written = await fetch(new URL("/tasks", url), { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ title: "from elsewhere" }) });
const refreshed = await waits(`performance.getEntriesByType("resource").filter((e) => new URL(e.name).pathname === "/tasks").length === 2`);
const grown = await waits(`document.body.textContent !== ${JSON.stringify(before)}`);
const second = await sent();
good = claim("a write by another client reached the page on its stream: it asked again with no press, got 200, and shows it", written.status === 201 && refreshed && grown && second[1] === 200, [written.status, second]) && good;
const texts = JSON.parse(await page.read(`(() => { clearInterval(window.__sampler); return JSON.stringify(window.__texts); })()`));
const lost = texts.filter((s) => !(/left ready \d+/.test(s) && /right ready \d+/.test(s)));
good = claim("asking again never drew a loading word: every sample held both answers", texts.length >= 20 && lost.length === 0, { samples: texts.length, lost: lost.slice(0, 2) }) && good;

await press("Add");
await waits(`performance.getEntriesByType("resource").filter((e) => new URL(e.name).pathname === "/tasks").length === 4`);
const last = await sent();
good = claim("its own write's answer named the table and the page asked again: 201, then 200", last[2] === 201 && last[3] === 200, last) && good;
await new Promise((go) => setTimeout(go, 800));
await press("Again");
await new Promise((go) => setTimeout(go, 600));
good = claim("and asking again is free once more", (await sent()).length === 4, await sent()) && good;

await page.close();
console.log(said.join("\n"));
process.exit(good ? 0 : 1);
