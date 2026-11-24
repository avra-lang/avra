// THE STORYBOARD'S CLAIMS: what every case DRAWS, under every dial, in a real engine. The page is
// `tools/storyboard` served by `avra dev`; every dial is chosen, every case of every view is drawn
// in a frame per dial, and each claim family below is asked of every frame it applies to. A family
// is DATA — what it applies to and what it holds — never code per story. A failure a ruling still
// owes is pinned by name (pinned.txt); an unpinned failure, and a pin that no longer fails, exit 1.
//
// THE MUTANT: each family is asked again of a page broken in exactly what it asserts, and must
// fail there — a family that holds over a page that breaks it asserts nothing.
//
//   node claims.mjs <page url> [--engine firefox|webkit|chromium] [--device "iPhone 15"] [--no-mutants]
//
// PLAYWRIGHT_DIR names the directory holding node_modules/playwright (webkit, chromium); Firefox is
// driven over WebDriver BiDi (../ui-board/firefox.mjs). Exit 3: the engine could not launch.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { openPage as openFirefox, firefoxBinary, KEY } from "../ui-board/firefox.mjs";
import { openPage as openPlaywright } from "../ui-board/webkit.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const [url, ...rest] = process.argv.slice(2);
const word = (name) => { const at = rest.indexOf(name); return at < 0 ? null : rest[at + 1]; };
const engine = word("--engine") ?? "firefox";
const device = word("--device");
const mutants = !rest.includes("--no-mutants");
// one view alone, as the index shows it
const only = word("--view");

// ── the engine ────────────────────────────────────────────────────

async function opened() {
  if (engine === "firefox") {
    const binary = firefoxBinary();
    if (!binary) { console.log("storyboard: no Firefox on this machine (FIREFOX names one)"); process.exit(3); }
    return openFirefox(binary, url, { width: 1280, height: 900 });
  }
  const pw = await import(pathToFileURL(path.join(process.env.PLAYWRIGHT_DIR ?? ".", "node_modules/playwright/index.mjs")).href).catch((e) => ({ said: String(e.message).split("\n")[0] }));
  const launcher = pw[engine];
  if (!launcher) { console.log(`storyboard: ${engine} could not load — ${pw.said ?? "no such engine"}`); process.exit(3); }
  const browser = await launcher.launch().catch((e) => { console.log(`storyboard: ${engine} could not launch — ${String(e.message).split("\n")[0]}`); process.exit(3); });
  const page = await openPlaywright(browser, url, { width: 1280, height: 900, device, playwright: pw });
  return { ...page, async close() { await page.close(); await browser.close(); } };
}

// The keys, as the engine's own driver spells them.
const keys = engine === "firefox" ? { enter: KEY.enter, space: " ", right: KEY.right, letter: "a" } : { enter: "Enter", space: " ", right: "ArrowRight", letter: "a" };

// ── the page made ready: every dial chosen, every frame named ────────

// In the page: every dial's box ticked, and each frame's canvas marked `data-sb="view/case/dial"`.
const MARK = `(() => {
  const marked = [];
  for (const card of document.querySelectorAll("article, section")) {
    const view = card.querySelector("h2")?.textContent ?? "";
    for (const head of card.querySelectorAll("h3")) {
      const box = head.parentElement;
      for (const label of box.querySelectorAll("span.text-label")) {
        const canvas = label.parentElement.querySelector(".fill-canvas");
        if (!canvas) continue;
        canvas.dataset.sb = view + "/" + head.textContent + "/" + label.textContent;
        label.parentElement.dataset.sbFrame = canvas.dataset.sb;
        marked.push(canvas.dataset.sb);
      }
    }
  }
  return marked;
})()`;

// The page's own words for what was heard: "heard: button.press 2 · field.input 1".
const HEARD = `(() => {
  const line = [...document.querySelectorAll("span")].map((s) => s.textContent).find((t) => t.startsWith("heard: ")) ?? "heard: nothing yet";
  const counts = {};
  for (const part of line.slice(7).split(" · ")) { const at = part.lastIndexOf(" "); if (at > 0) counts[part.slice(0, at)] = Number(part.slice(at + 1)); }
  return counts;
})()`;

async function ready(page) {
  // the module mounts after the load: a box pressed before it hears nothing
  await page.read(`new Promise((done) => { const look = () => document.querySelector("article, section h2, h2") ? done(1) : setTimeout(look, 50); look(); })`);
  await page.frame();
  for (const dial of ["more", "large", "narrow"]) {
    const ticked = await page.read(`(() => { const box = [...document.querySelectorAll("label")].find((l) => l.textContent.trim() === ${JSON.stringify(dial)})?.querySelector("input"); return box ? box.checked : null; })()`);
    if (ticked === false) await page.press(`[...document.querySelectorAll("label")].find((l) => l.textContent.trim() === ${JSON.stringify(dial)}).querySelector("input")`);
    await page.frame();
  }
  await page.frame();
  if (only) {
    await page.press(`[...document.querySelectorAll("button")].find((b) => b.textContent.split(" ")[0] === ${JSON.stringify(only)})`);
    await page.frame();
  }
  // every picture asked for has answered, drawn or not
  await page.read(`Promise.all([...document.images].map((i) => i.complete ? 1 : new Promise((done) => { i.onload = i.onerror = done; setTimeout(done, 3000); })))`);
  return page.read(MARK);
}

// ── the families: what each holds, of which frames ─────────────────

// Helpers every in-page family reads, written once into the expression.
const LIB = `
  const rgb = (c) => { const m = c.match(/[\\d.]+/g); return m ? m.slice(0, 4).map(Number) : [0, 0, 0, 0]; };
  const lum = ([r, g, b]) => { const f = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; }; return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b); };
  const ground = (el) => { for (let e = el; e; e = e.parentElement) { const c = rgb(getComputedStyle(e).backgroundColor); if (c.length < 4 || c[3] > 0) return c; } return [255, 255, 255]; };
  const ratio = (a, b) => { const [x, y] = [lum(a), lum(b)].sort((p, q) => q - p); return (x + 0.05) / (y + 0.05); };
  const controls = (canvas) => [...canvas.querySelectorAll("button, input, select, textarea, a[href], [role=switch], [role=slider]")].filter((c) => c.type !== "hidden" && c.getClientRects().length > 0);
  const named = (c) => (c.getAttribute("aria-label") ?? "").trim() || (c.closest("label")?.textContent ?? "").trim() || (c.textContent ?? "").trim() || (c.getAttribute("alt") ?? "").trim();
  const worded = (canvas) => [...canvas.querySelectorAll("*")].filter((e) => [...e.childNodes].some((n) => n.nodeType === 3 && n.textContent.trim()) && e.getClientRects().length > 0);
  const frames = [...document.querySelectorAll("[data-sb]")];
`;

// WHAT IS INACTIVE, as data: words no contrast standard holds to a ratio — a disabled control's, and
// words in the theme's disabled ink, which says the same of what it draws.
const inactive = [":disabled", "[aria-disabled=true]", ".color-disabled"];

// Each family: its name, what it holds, and an in-page check over one frame answering the reasons
// it fails there (none: it holds).
const families = [
  {
    name: "named",
    holds: "every control a frame draws is named — by its label, its words or its aria-label",
    check: `(f) => controls(f).filter((c) => !named(c)).map((c) => c.tagName.toLowerCase() + " has no name")`,
  },
  {
    name: "legible",
    holds: "every word a frame draws stands out from what it is drawn on: 4.5:1, 3:1 for large type; inactive words owe nothing",
    check: `(f) => worded(f).filter((e) => !e.closest(${JSON.stringify(inactive.join(", "))})).map((e) => {
      const s = getComputedStyle(e); const size = parseFloat(s.fontSize); const large = size >= 24 || (size >= 18.66 && Number(s.fontWeight) >= 700);
      const r = ratio(rgb(s.color), ground(e)); return r >= (large ? 3 : 4.5) ? null : "\\"" + e.textContent.trim().slice(0, 24) + "\\" at " + r.toFixed(2) + ":1";
    }).filter(Boolean)`,
  },
  {
    name: "contained",
    holds: "nothing a frame draws stands past the frame's edge, as wide as its dial holds it: no overflow, no box beyond it",
    check: `(f) => { const edge = Math.min(f.getBoundingClientRect().right, f.closest("[data-sb-frame]").getBoundingClientRect().right) + 1; const out = [...f.querySelectorAll("*")].filter((e) => e.getBoundingClientRect().right > edge).map((e) => e.tagName.toLowerCase() + " " + Math.round(e.getBoundingClientRect().right - edge + 1) + " px past");
      return (f.scrollWidth > f.clientWidth + 1 ? ["scrolls " + (f.scrollWidth - f.clientWidth) + " px"] : []).concat(out.slice(0, 2)); }`,
  },
  {
    name: "input-held",
    holds: "a field's input never stands past the frame it is drawn in",
    check: `(f) => { const edge = Math.min(f.getBoundingClientRect().right, f.closest("[data-sb-frame]").getBoundingClientRect().right);
      return [...f.querySelectorAll("input")].filter((i) => i.getBoundingClientRect().right > edge + 1).map((i) => "input " + Math.round(i.getBoundingClientRect().right - edge) + " px past"); }`,
  },
  {
    name: "pictured",
    holds: "every picture a frame draws has drawn: its file arrived and decoded",
    check: `(f) => [...f.querySelectorAll("img")].filter((i) => !i.complete || i.naturalWidth === 0).map((i) => "a picture not drawn: " + (i.getAttribute("src") ?? ""))`,
  },
  {
    name: "tickable",
    holds: "a box to tick is drawn at a size a finger finds, whatever words stand beside it",
    check: `(f) => [...f.querySelectorAll("input[type=checkbox]")].filter((i) => i.getClientRects().length > 0 && i.getBoundingClientRect().width < 10).map((i) => "a box to tick " + Math.round(i.getBoundingClientRect().width) + " px wide")`,
  },
  {
    name: "reachable",
    holds: "every enabled control a frame draws is in the key order and takes the focus; a disabled one does not",
    check: `(f) => controls(f).map((c) => { const off = c.disabled || c.getAttribute("aria-disabled") === "true"; c.focus(); const took = document.activeElement === c && c.tabIndex >= 0; c.blur();
      return off === took ? (off ? c.tagName.toLowerCase() + " is disabled and takes the focus" : c.tagName.toLowerCase() + " is not reachable by key") : null; }).filter(Boolean)`,
  },
];

// Across the dials: a case's canvas, and the surface right under it, darker under `dark` than under `light`.
const SCHEME = `(() => {
  const by = {}; for (const f of frames) { const [v, c, d] = f.dataset.sb.split("/"); (by[v + "/" + c] ??= {})[d] = f; }
  const fails = [];
  for (const [k, d] of Object.entries(by)) {
    if (!d.light || !d.dark) continue;
    const surface = (f) => f.firstElementChild ?? f;
    for (const [what, pick] of [["canvas", (f) => f], ["surface", surface]]) {
      const [l, n] = [lum(ground(pick(d.light))), lum(ground(pick(d.dark)))];
      if (!(n < l)) fails.push(k + "/dark scheme: the " + what + " is no darker than under light (" + n.toFixed(3) + " vs " + l.toFixed(3) + ")");
    }
  }
  return fails;
})()`;

// Every frame's failures, by family.
async function judged(page) {
  const fails = [];
  for (const fam of families) {
    const found = await page.read(`(() => { ${LIB} const check = ${fam.check}; return frames.flatMap((f) => check(f).map((why) => f.dataset.sb + ": " + why)); })()`);
    for (const line of found) fails.push(`${fam.name} ${line}`);
  }
  for (const line of await page.read(`(() => { ${LIB} return ${SCHEME}; })()`)) fails.push(`scheme ${line}`);
  return fails;
}

// ── operable: a gesture reaches the event its component declares, once ──

// The views whose case IS a control, and the gesture that works it by key. A link is left out: its
// gesture leaves the page, which is the link's whole meaning and no claim this page can read back.
const gestures = {
  button: "enter", checkbox: "space", switch: "space", field: "letter", slider: "right",
};

async function operated(page, touch) {
  const fails = [];
  const frames = await page.read(`[...document.querySelectorAll("[data-sb]")].map((f) => f.dataset.sb)`);
  for (const sb of frames) {
    const [view, kase, dial] = sb.split("/");
    const key = gestures[view];
    if (!key || dial !== "light") continue;
    const at = `document.querySelector('[data-sb="${sb.replace(/"/g, '\\"')}"]')`;
    const target = `(${at}.querySelector("button, input, a[href], [role=switch], [role=slider]"))`;
    const shape = await page.read(`(() => { const c = ${target}; return c ? { off: c.disabled || c.getAttribute("aria-disabled") === "true", value: c.value ?? "", checked: !!c.checked } : null; })()`);
    if (!shape) continue;
    const before = (await page.read(HEARD))[`${view}.${eventOf[view]}`] ?? 0;
    if (touch) {
      // centred first: a box at the window's very edge is not where a finger lands
      await page.read(`${target}.scrollIntoView({ block: "center" })`);
      await page.press(target);
      // a finger's click follows its touch by the engine's own delay
      await page.read(`new Promise((done) => setTimeout(done, 350))`);
    }
    else { await page.read(`(document.activeElement?.blur(), ${target}.focus())`); await page.type(keys[key]); }
    await page.frame();
    const after = (await page.read(HEARD))[`${view}.${eventOf[view]}`] ?? 0;
    const want = shape.off ? 0 : 1;
    const how = touch ? "a tap" : `the ${key} key`;
    if (after - before !== want) fails.push(`${touch ? "touched" : "operable"} ${sb}: ${how} was heard ${after - before} times, wanted ${want}`);
    if (!shape.off && kase === "base") {
      const now = await page.read(`(() => { const c = ${target}; return { value: c.value ?? "", checked: !!c.checked }; })()`);
      if ((view === "checkbox" || view === "switch") && now.checked === shape.checked) fails.push(`${touch ? "touched" : "operable"} ${sb}: ${how} left the box ${now.checked ? "ticked" : "unticked"}, as it stood`);
      if (view === "field" && !touch && !now.value.endsWith("a")) fails.push(`operable ${sb}: typed "a", and the field reads "${now.value}"`);
    }
  }
  return fails;
}

// The event each control view declares, as `heard` names it.
const eventOf = { button: "press", checkbox: "change", switch: "change", field: "input", slider: "change" };

// ── the mutants: each family over a page broken in what it asserts ──

const breaking = {
  named: `document.querySelectorAll("[data-sb] button").forEach((b) => { b.textContent = ""; b.setAttribute("aria-label", ""); })`,
  legible: `(() => { const s = document.createElement("style"); s.textContent = "[data-sb] * { color: rgb(200,200,200) !important; background: rgb(255,255,255) !important }"; document.head.append(s); })()`,
  contained: `document.querySelectorAll("[data-sb]").forEach((f) => { const d = document.createElement("div"); d.style.width = "2000px"; d.style.height = "1px"; f.append(d); })`,
  "input-held": `(() => { const s = document.createElement("style"); s.textContent = "[data-sb] input { min-width: 2000px !important; max-width: none !important }"; document.head.append(s); })()`,
  pictured: `document.querySelectorAll("[data-sb]").forEach((f) => { const i = document.createElement("img"); i.src = "/no-such-picture.png"; f.append(i); })`,
  tickable: `(() => { const s = document.createElement("style"); s.textContent = "[data-sb] input[type=checkbox] { width: 0 !important; min-width: 0 !important }"; document.head.append(s); })()`,
  reachable: `document.querySelectorAll("[data-sb] button, [data-sb] input").forEach((c) => c.setAttribute("tabindex", "-1"))`,
  scheme: `(() => { const s = document.createElement("style"); s.textContent = "[data-sb] { background: rgb(255,255,255) !important }"; document.head.append(s); })()`,
  operable: `["keydown", "keyup", "keypress", "click", "input", "change", "pointerdown", "pointerup"].forEach((t) => window.addEventListener(t, (e) => { e.stopImmediatePropagation(); e.preventDefault(); }, true))`,
};

// ── the run ──────────────────────────────────────────────────────

const pinLines = fs.existsSync(path.join(here, "pinned.txt")) ? fs.readFileSync(path.join(here, "pinned.txt"), "utf8").split("\n").map((l) => l.trim()) : [];
const ceiling = Number((pinLines.find((l) => l.startsWith("# at most ")) ?? "# at most 0").slice(10));
const pinned = pinLines.filter((l) => l && !l.startsWith("#")).map((l) => l.split(" — ")[0]);
// a pin says why it fails and what ends it, and the baseline only shrinks
const malformed = pinLines.filter((l) => l && !l.startsWith("#") && !/ — .+ — waits on: .+/.test(l));
if (malformed.length || pinned.length > ceiling) {
  for (const l of malformed) console.log(`storyboard: a pin with no reason or no ruling: ${l}`);
  if (pinned.length > ceiling) console.log(`storyboard: ${pinned.length} pins, and the baseline says at most ${ceiling}: it only shrinks`);
  process.exit(1);
}
const isPinned = (line) => pinned.some((p) => line.startsWith(p));

const began = Date.now();
const page = await opened();
const marks = await ready(page);
const marked = marks.length;
const perDial = {}; for (const m of marks) { const d = m.split("/").pop(); perDial[d] = (perDial[d] ?? 0) + 1; }
console.log(`storyboard: frames by dial ${JSON.stringify(perDial)}`);
if (marked === 0) { console.log("storyboard: the page drew no frame to judge"); process.exit(1); }
const touch = !!(device && /iphone|ipad|pixel/i.test(device));
const found = (await judged(page)).concat(await operated(page, false)).concat(touch ? await operated(page, true) : []);
await page.close();

const unpinned = found.filter((l) => !isPinned(l));
const stale = pinned.filter((p) => !found.some((l) => l.startsWith(p)));
for (const fam of families) console.log(`${found.some((l) => l.startsWith(fam.name + " ")) ? "fail" : "ok  "} ${fam.name}: ${fam.holds}`);
console.log(`${found.some((l) => l.startsWith("scheme ")) ? "fail" : "ok  "} scheme: every case's canvas and surface are darker under dark than under light`);
console.log(`${found.some((l) => l.startsWith("operable ")) ? "fail" : "ok  "} operable: a key gesture on a control is heard once (never, when disabled), and what it changed is drawn`);
if (touch) console.log(`${found.some((l) => l.startsWith("touched ")) ? "fail" : "ok  "} touched: a tap is heard once (never, when disabled)`);
for (const l of unpinned) console.log(`FAIL ${l}`);
for (const p of stale) console.log(`STALE pin, it fails no more: ${p}`);
console.log(`storyboard: ${marked} frames, ${found.length} failures (${found.length - unpinned.length} pinned), in ${engine}${device ? ` (${device})` : ""}`);

// Each family over the page broken in what it asserts: it must fail there.
let survived = 0;
if (mutants) {
  for (const [fam, broken] of Object.entries(breaking)) {
    const p = await opened();
    await ready(p);
    await p.read(broken);
    await p.frame();
    const fails = fam === "operable" ? await operated(p, false) : await judged(p);
    await p.close();
    const caught = fails.filter((l) => l.startsWith(fam + " ") && !isPinned(l)).length;
    console.log(`${caught > 0 ? "ok  " : "FAIL"} mutant ${fam}: a page broken in what it asserts fails it ${caught} times`);
    if (caught === 0) survived += 1;
  }
}
console.log(`storyboard: ${((Date.now() - began) / 1000).toFixed(1)} s`);
process.exit(unpinned.length || stale.length || survived ? 1 : 0);
