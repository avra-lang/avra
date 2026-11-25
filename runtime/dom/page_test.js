// Proves a page that cannot start, or stops working, says so in plain words: the page's own
// script run over a stub document — its modules failing to load, the program failing, an uncaught
// error and a rejected promise, a masked error that is not the page's, a throw inside the module,
// and a clean start — as a built page and as the page `avra dev` serves.
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

// A stub document, a built page's or, with `dev`, one `avra dev` serves (it names its module).
const stage = ({ dev = false } = {}) => {
  delete globalThis.avraRelay;
  const alerts = [];
  const listeners = {};
  const element = (tag) => ({ tag, attrs: {}, style: {}, kids: [], textContent: "", setAttribute(k, v) { this.attrs[k] = v; }, append(...k) { this.kids.push(...k); }, addEventListener() {} });
  const document = {
    createElement: (tag) => element(tag),
    getElementById: () => ({ dataset: { avraModule: "./app.wasm" } }),
    querySelector: (q) => (dev && q.includes("avra-module") ? {} : null),
    body: { prepend: (el) => alerts.push(el) },
  };
  return { alerts, listeners, document, addEventListener: (type, fn) => { listeners[type] = fn; } };
};

// Each alert drawn: its role, its first line, what follows it, and whether it offers a reload.
const alertsOf = (s) => s.alerts.map((el) => ({
  role: el.attrs.role,
  first: el.kids[0]?.textContent,
  detail: el.kids.filter((k) => k.tag === "pre").map((k) => k.textContent).join("\n"),
  reload: el.kids.some((k) => k.tag === "button" && k.textContent === "Reload"),
}));
const heard = () => globalThis.avraRelay.held;
// What the console heard while `run` ran.
const consoled = async (run) => {
  const said = [];
  const { error, warn } = console;
  console.error = (...w) => said.push(["error", w.join(" ")]);
  console.warn = (...w) => said.push(["warn", w.join(" ")]);
  try { await run(); } finally { console.error = error; console.warn = warn; }
  return said;
};
const starting = (run = async () => {}) => (path) => Promise.resolve(path.endsWith("bootstrap.js") ? { run } : { wasiPreview1: () => ({}) });

{
  const s = stage({ dev: true });
  await consoled(() => page(s.document, s.addEventListener, () => Promise.reject(new Error("WebAssembly.Module doesn't parse at byte 398"))));
  const a = alertsOf(s);
  check("a module that fails to load is told on the page, once", a.length, 1);
  check("the alert is a role=alert whose first line is plain words: the page could not start", [a[0].role, a[0].first], ["alert", "This page could not start."]);
  check("under dev the engine's own words follow the plain line", a[0].detail.includes("doesn't parse at byte 398"), true);
}
{
  const s = stage();
  const said = await consoled(() => page(s.document, s.addEventListener, starting(async () => { throw new Error("no such export"); })));
  const a = alertsOf(s);
  check("a built page that fails to run says the plain line and offers a reload, and no engine text", [a.length, a[0].first, a[0].detail, a[0].reload], [1, "This page could not start.", "", true]);
  check("the engine's words go to the console instead", said.some(([k, w]) => k === "error" && w.includes("no such export")), true);
}
{
  const s = stage({ dev: true });
  await consoled(async () => {
    await page(s.document, s.addEventListener, starting());
    s.listeners.error({ error: new Error("later error"), message: "later error", filename: "http://x/app.js" });
    s.listeners.unhandledrejection({ reason: new Error("a rejection") });
  });
  const a = alertsOf(s);
  check("an uncaught error and an unhandled rejection after start say the page stopped working", a.map((x) => x.first), ["This page stopped working.", "This page stopped working."]);
  check("under dev each carries its own words after the plain line", [a[0].detail.includes("later error"), a[1].detail.includes("a rejection")], [true, true]);
}
{
  const s = stage({ dev: true });
  const said = await consoled(async () => {
    await page(s.document, s.addEventListener, starting());
    s.listeners.error({ message: "Script error.", error: null, filename: "", lineno: 0, colno: 0 });
  });
  check("a masked error (no error object, no file) is never drawn over the app", alertsOf(s), []);
  check("the console hears it", said.some(([k, w]) => k === "warn" && w.includes("Script error.")), true);
  check("the relay carries it with the browser that ran it", heard().some((l) => l.includes("Script error.") && l.includes(globalThis.navigator?.userAgent ?? "an unknown browser")), true);
}
{
  const s = stage();
  await consoled(async () => {
    await page(s.document, s.addEventListener, starting());
    s.listeners.error({ message: "Script error.", filename: "http://x/app.js", lineno: 12, colno: 7 });
  });
  const a = alertsOf(s);
  check("an error from a file of the page's, with no error object, is the page's: told in plain words", [a.length, a[0].first, a[0].reload], [1, "This page stopped working.", true]);
}
{
  const s = stage({ dev: true });
  let failed = null;
  await consoled(async () => {
    await page(s.document, s.addEventListener, starting(async (_source, host) => { failed = host.failed; }));
    const thrown = new Error("index 9 is out of bounds (length 3)");
    failed(thrown);
    // An engine whose stack holds no message line, as Firefox and WebKit do:
    // the words are told even so.
    const bare = new Error("the module trapped at index 9");
    bare.stack = "app.js:2:3";
    failed(bare);
    const a = alertsOf(s);
    check("a throw inside the module is told by the page itself: the plain line, then under dev its stack whole", [a.length, a[0].first, a[0].detail.includes(thrown.stack)], [2, "This page stopped working.", true]);
    check("an error's own words are told before its stack, where the stack holds none", [a[1].detail.includes(bare.message), a[1].detail.includes(bare.stack)], [true, true]);
  });
  check("the relay carries every told failure", heard().filter((l) => l.startsWith("This page stopped working.")).length, 2);
}
{
  const s = stage();
  const said = await consoled(() => page(s.document, s.addEventListener, starting()));
  check("a page that starts says nothing", [alertsOf(s), said], [[], []]);
}
console.log(`page: ${fails === 0 ? "all hold" : fails + " failed"}`);
process.exit(fails === 0 ? 0 : 1);
