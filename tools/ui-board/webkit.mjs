// WebKit, driven by Playwright's own build of it: the engine every iOS browser
// is, which Firefox's reading of a page proves nothing about (it tolerates
// `showModal` on a dialog already open, and reads import encodings WebKit
// does not). The same page as firefox.mjs answers — read, press, pressAt, drag,
// escape, type, frame, complaints, screenshot, close — so browser.mjs's claims
// run unchanged, including the dialog claims that press and drag by coordinate.
import { KEY } from "./firefox.mjs";

// The keys a page hears by name, as Playwright spells them.
const NAMED = new Map([[KEY.enter, "Enter"], [KEY.tab, "Tab"], [KEY.escape, "Escape"], [KEY.left, "ArrowLeft"], [KEY.right, "ArrowRight"]]);

// Whether Playwright's WebKit can launch here, and what it says when it cannot.
export async function webkitLaunch(playwright) {
  try { return { browser: await playwright.webkit.launch() }; } catch (e) { return { said: String(e.message ?? e).split("\n").map((l) => l.trim()).filter(Boolean).slice(0, 6).join(" | ") }; }
}

// The browser is the caller's: closing a page closes its context only.
// `device` names one of Playwright's device descriptors ("iPhone 15"): a touch screen, a phone's
// viewport and user agent, and a press that is a tap.
export async function openPage(browser, url, { width = 900, height = 700, device = null, playwright = null } = {}) {
  const shape = device ? playwright.devices[device] : null;
  if (device && !shape) throw new Error(`no device named ${device}`);
  const context = await browser.newContext(shape ?? { viewport: { width, height } });
  const page = await context.newPage();
  const logged = [];
  page.on("console", (m) => { if (m.type() === "error" || m.type() === "warning") logged.push(`${m.type() === "warning" ? "warn" : "error"}: ${m.text()}`); });
  page.on("pageerror", (e) => logged.push(`error: ${e.name}: ${e.message}`));
  await page.goto(url, { waitUntil: "load" });

  // An expression's value in the page, awaited, as JSON carries it.
  const read = (expression) => page.evaluate(`(async () => (${expression}))()`);
  const framed = () => read("new Promise((done) => requestAnimationFrame(() => requestAnimationFrame(() => done(1))))");
  const pressAt = async (x, y) => { if (shape?.hasTouch) await page.touchscreen.tap(x, y); else await page.mouse.click(x, y); await framed(); };
  // A gesture from one point to another: down where it starts, one move, up where it ends. A
  // touch profile still takes it as a pointer, which is what a dialog's dismissal reads.
  const drag = async (from, to) => {
    await page.mouse.move(from.x, from.y);
    await page.mouse.down();
    await page.mouse.move(to.x, to.y, { steps: 4 });
    await page.mouse.up();
    await framed();
  };

  return {
    read,
    frame: framed,
    complaints: () => logged,
    pressAt,
    drag,
    async press(selecting) {
      const at = await read(`(() => { const el = ${selecting}; el.scrollIntoView({ block: "nearest" }); const r = el.getBoundingClientRect(); return { x: Math.round(r.x + r.width / 2), y: Math.round(r.y + r.height / 2) }; })()`);
      await pressAt(at.x, at.y);
    },
    async type(...keys) {
      for (const key of keys) await page.keyboard.press(NAMED.get(key) ?? key);
      await framed();
    },
    async screenshot(file) { await page.screenshot({ path: file }); },
    async close() { await context.close(); },
  };
}
