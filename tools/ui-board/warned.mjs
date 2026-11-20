// Opens a served page in Firefox, waits for it to draw, and leaves it open long enough for what
// it says on its console to reach the dev server. Prints `drawn` when the page painted.
//   node warned.mjs <page url>
import { openPage, firefoxBinary } from "./firefox.mjs";

const [url] = process.argv.slice(2);
const page = await openPage(firefoxBinary(), url);
let drawn = false;
for (let tries = 0; tries < 100 && !drawn; tries++) {
  drawn = (await page.read(`document.querySelectorAll("button").length`)) >= 2;
  if (!drawn) await new Promise((done) => setTimeout(done, 100));
}
await new Promise((done) => setTimeout(done, 1500));
await page.close();
console.log(drawn ? "drawn" : "never drawn");
process.exit(drawn ? 0 : 1);
