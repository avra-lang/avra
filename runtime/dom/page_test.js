// Proves a page that cannot start says why on the page: the page's own script is run over a
// stub document, once with its modules failing to load, once with the program failing, once
// with an uncaught error and a rejected promise the page hears, and once starting cleanly.
import fs from "node:fs";

const html = fs.readFileSync(new URL("./page.html", import.meta.url), "utf8");
const script = html.match(/<script type="module">([\s\S]*?)<\/script>/)[1];
// The script's dynamic imports go through `load`, so a test can fail them.
const AsyncFunction = Object.getPrototypeOf(async () => {}).constructor;
const page = new AsyncFunction("document", "addEventListener", "load", script.replaceAll("import(", "load("));

let fails = 0;
const check = (name, got, want) => {
  const g = JSON.stringify(got), w = JSON.stringify(want);
  if (g !== w) { fails++; console.log(`✗ ${name}\n  got  ${g}\n  want ${w}`); } else console.log(`✓ ${name}`);
};

const stage = () => {
  const alerts = [];
  const listeners = {};
  const element = () => ({ attrs: {}, style: {}, setAttribute(k, v) { this.attrs[k] = v; }, textContent: "" });
  const document = {
    createElement: () => element(),
    getElementById: () => ({}),
    body: { prepend: (el) => alerts.push(el) },
  };
  return { alerts, listeners, document, addEventListener: (type, fn) => { listeners[type] = fn; } };
};

const alertsOf = (s) => s.alerts.map((el) => ({ role: el.attrs.role, text: el.textContent }));

{
  const s = stage();
  await page(s.document, s.addEventListener, () => Promise.reject(new Error("WebAssembly.Module doesn't parse at byte 398")));
  const a = alertsOf(s);
  check("a module that fails to load is told on the page, once", a.length, 1);
  check("the alert is a role=alert and says the page did not start", [a[0].role, a[0].text.startsWith("The page did not start:")], ["alert", true]);
  check("the alert carries the engine's own words", a[0].text.includes("doesn't parse at byte 398"), true);
}
{
  const s = stage();
  const load = (path) => Promise.resolve(path.endsWith("bootstrap.js") ? { run: async () => { throw new Error("no such export"); } } : { wasiPreview1: () => ({}) });
  await page(s.document, s.addEventListener, load);
  check("a program that fails to run is told on the page", alertsOf(s).map((a) => a.text.includes("no such export")), [true]);
}
{
  const s = stage();
  await page(s.document, s.addEventListener, () => Promise.reject(new Error("first")));
  s.listeners.error({ error: new Error("later error") });
  s.listeners.unhandledrejection({ reason: new Error("a rejection") });
  check("an uncaught error and an unhandled rejection are told as well", alertsOf(s).map((a) => [a.text.includes("first"), a.text.includes("later error"), a.text.includes("a rejection")]), [[true, false, false], [false, true, false], [false, false, true]]);
}
{
  const s = stage();
  const load = (path) => Promise.resolve(path.endsWith("bootstrap.js") ? { run: async () => {} } : { wasiPreview1: () => ({}) });
  await page(s.document, s.addEventListener, load);
  check("a page that starts says nothing", alertsOf(s), []);
  s.listeners.error({ message: "Script error.", filename: "http://x/app.js", lineno: 12, colno: 7 });
  const later = alertsOf(s);
  check("an error after the page started says it hit one, not that it did not start", later[0].text.startsWith("The page hit an error:"), true);
  check("an error with no error object is told with where it came from", later[0].text.includes("Script error. (http://x/app.js:12:7)"), true);
}
console.log(`page: ${fails === 0 ? "all hold" : fails + " failed"}`);
process.exit(fails === 0 ? 0 : 1);
