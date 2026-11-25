// Opens a served page whose box and field are each held to what the program shows (`shown`), and
// prints whether the page writes the program's word back after the gesture:
//   - a click on a box shown unticked leaves it unticked;
//   - typing in a field shown as "abc" leaves it reading "abc".
//   node shown.mjs <page url>
import { openPage, firefoxBinary } from "./firefox.mjs";

const [url] = process.argv.slice(2);
const page = await openPage(firefoxBinary(), url);
const named = (name) => `document.querySelector('[aria-label=${JSON.stringify(name)}]')`;
const waits = async (holds) => { for (let i = 0; i < 50; i++) { if (await page.read(holds).catch(() => false)) return true; await new Promise((go) => setTimeout(go, 100)); } return false; };
const said = [];
const claim = (what, holds, seen) => { said.push(`${holds ? "ok" : "FAILED"} ${what}${holds ? "" : ` — saw ${JSON.stringify(seen)}`}`); return holds; };

let good = await waits(`${named("x")} !== null && ${named("y")} !== null`);
good = claim("the page draws its box and its field", good, await page.read(`document.body.innerHTML.slice(0, 200)`)) && good;
good = claim("the field first reads what the program shows", await page.read(`${named("y")}.value`) === "abc", await page.read(`${named("y")}.value`)) && good;

await page.press(named("x"));
await page.frame();
await new Promise((go) => setTimeout(go, 300));
good = claim("a click on a box shown unticked leaves its DOM box unticked", await page.read(`${named("x")}.checked`) === false, await page.read(`${named("x")}.checked`)) && good;

await page.press(named("y"));
await page.type("d", "e", "f");
await page.frame();
await new Promise((go) => setTimeout(go, 300));
good = claim("typing in a field shown as \"abc\" leaves its DOM value \"abc\"", await page.read(`${named("y")}.value`) === "abc", await page.read(`${named("y")}.value`)) && good;

await page.close();
console.log(said.join("\n"));
process.exit(good ? 0 : 1);
