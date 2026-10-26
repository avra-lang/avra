// Opens a served page whose two views ask the same GET and prints what the browser sent:
// the page must have made ONE request for /tasks, and both views must have settled on its
// answer (the page's server holds no /tasks, so the answer is a refusal both views show).
//   node observed.mjs <page url>
import { openPage, firefoxBinary } from "./firefox.mjs";

const [url] = process.argv.slice(2);
const page = await openPage(firefoxBinary(), url);
const settled = `document.body.textContent.includes("left failed") && document.body.textContent.includes("right failed")`;
let both = false;
for (let tries = 0; tries < 100 && !both; tries++) {
  both = await page.read(settled).catch(() => false);
  if (!both) await new Promise((done) => setTimeout(done, 100));
}
const sent = await page.read(`performance.getEntriesByType("resource").filter((e) => new URL(e.name).pathname === "/tasks").length`);
await page.close();
console.log(`both views settled: ${both}; requests for /tasks: ${sent}`);
process.exit(both && sent === 1 ? 0 : 1);
