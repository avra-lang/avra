// The board in a REAL browser: the module and the page glue served over an
// HTTP origin, loaded by headless Firefox, and driven with the browser's
// own pointer and keys (firefox.mjs). demo.mjs proves the wire over a stub
// document; this proves what only an engine can — that the sheet styles
// the page, that a control is the control a reader expects, that typing
// keeps its caret, that the keyboard reaches everything. Each claim is
// CHECKED and one failure exits 1. `make ui-browser` builds and runs it.
//
//   node browser.mjs <page url> [--engine firefox|webkit] [--shots <directory>] [--source <the view's file>]
//
// `--engine webkit` runs the same claims in Playwright's WebKit (webkit.mjs), the engine
// every iOS browser is; PLAYWRIGHT_DIR names the directory holding node_modules/playwright.
// Exit 3 says WebKit could not launch here, and why.
//
// With `--source` the page is `avra dev`'s, and the loop is proven too: the
// view's file is edited where it stands and the running page must follow.
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { openPage, firefoxBinary, KEY } from "./firefox.mjs";
import { openPage as openWebkit, webkitLaunch } from "./webkit.mjs";
import { outsidePresses, outsidePressWords } from "./dialog_claims.mjs";

const [url, ...named_words] = process.argv.slice(2);
const word = (name) => { const at = named_words.indexOf(name); return at < 0 ? null : named_words[at + 1]; };
const shots = word("--shots");
const source = word("--source");
const hydrated = word("--hydrated");
const tampered = word("--tampered");
const engine = word("--engine") ?? "firefox";
// The engine's browser, launched once; every page the claims read opens in it.
let launched = null;
async function engineBrowser() {
  if (launched) return launched;
  const loaded = await import(pathToFileURL(path.join(process.env.PLAYWRIGHT_DIR ?? ".", "node_modules/playwright/index.mjs")).href).catch((e) => ({ said: String(e.message).split("\n")[0] }));
  const { browser, said } = loaded.webkit ? await webkitLaunch(loaded) : { said: loaded.said };
  if (!browser) { console.log(`ui-browser: WebKit could not launch — ${said}`); process.exit(3); }
  launched = { browser, loaded };
  return launched;
}
// A page at `at`, in the engine asked for.
async function opened(at, options = {}) {
  if (engine !== "webkit") return openPage(firefoxBinary(), at, options);
  const { browser, loaded } = await engineBrowser();
  return openWebkit(browser, at, { device: process.env.UI_BROWSER_DEVICE ?? null, playwright: loaded });
}
// THE BOARD'S TASKS ARE THE SERVER'S: its claims begin from a server holding the four tasks the board
// is shown with, made through the server's own doors, and each is known by the key the server gave it.
const first_tasks = [["Draft the spec", true], ["Wire the event channel", false], ["Land the wasm board", false], ["Write the tour", true]];
async function seeded(tasks = first_tasks) {
  await emptied();
  const keys = [];
  for (const [title, done] of tasks) {
    const made = await fetch(url + "tasks", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ title, done }) });
    if (!made.ok) { console.log(`ui-browser: seeding the server, POST /tasks answered ${made.status}`); process.exit(1); }
    keys.push(String((await made.json()).id));
  }
  return keys;
}
const [k1, k2, k3, k4] = await seeded();
const page = await opened(url);
const { read, press, type, frame } = page;

let failed = 0;
const claim = (words, holds, seen = "") => {
  if (!holds) failed++;
  console.log(`${holds ? "ok    " : "FAILED"} ${words}${holds || seen === "" ? "" : ` — saw ${JSON.stringify(seen)}`}`);
};
const shot = async (name) => { if (shots) await page.screenshot(path.join(shots, `${name}.png`)); };

// A control by its accessible name, as a reader of the page finds it.
const named = (name, nth = 0) => `[...document.querySelectorAll('[aria-label=${JSON.stringify(name)}]')][${nth}]`;
const row = (key) => `document.querySelector('li[data-key=${JSON.stringify(key)}]')`;
const rows = () => read(`[...document.querySelectorAll("li")].map((li) => ({ key: li.dataset.key, done: li.querySelector("input").checked, words: li.querySelector("label").textContent }))`);
const keys = async () => (await rows()).map((r) => r.key);
// Until `holds` answers true of the page: a change is the server's to answer before the board shows it.
const waited = async (holds) => { for (let i = 0; i < 100; i++) { if (await read(holds).catch(() => false)) return true; await new Promise((go) => setTimeout(go, 50)); } return false; };
// The page's keys, once they are `want` (or as they stand when they never are).
const keys_become = async (want) => { for (let i = 0; i < 100; i++) { const now = (await keys()).join(); if (now === want) return now; await new Promise((go) => setTimeout(go, 50)); } return (await keys()).join(); };
const progress = () => read(`document.querySelector("progress").value`);
// Until the page and the server hold the same tasks, in the same state, twice over a beat: the changes
// sent so far have all been answered, so a later press cannot meet an older answer.
const watch = (on) => on.read(`(() => { window.__sent = 0; window.__done = 0; window.__log = []; const asking = globalThis.fetch.bind(globalThis); globalThis.fetch = (...a) => { window.__sent++; const mark = ((a[1] && a[1].method) || "GET") + " " + a[0] + (a[1] && a[1].body ? " " + new TextDecoder().decode(a[1].body) : ""); window.__log.push("> " + mark); return asking(...a).then((r) => { window.__log.push("< " + r.status + " " + mark); return r; }).finally(() => { window.__done++; }); }; document.addEventListener("change", (e) => window.__log.push("change " + e.target.getAttribute("aria-label") + " " + e.target.checked), true); return 1; })()`);
const agreed = async (on = page) => {
  const same = async () => {
    if (await on.read(`window.__sent !== window.__done`)) return false;
    const mine = (await on.read(`[...document.querySelectorAll("li")].map((li) => li.dataset.key + ":" + li.querySelector("input").checked)`)).sort().join();
    const theirs = (await (await fetch(url + "tasks")).json()).map((t) => `${t.id}:${t.done}`).sort().join();
    return mine === theirs;
  };
  for (let i = 0; i < 100; i++) {
    if (await same()) { await new Promise((go) => setTimeout(go, 150)); if (await same()) return true; }
    await new Promise((go) => setTimeout(go, 50));
  }
  return false;
};
const focused = () => read(`document.activeElement.getAttribute("aria-label")`);
const styled = (selecting, property) => read(`getComputedStyle(${selecting})[${JSON.stringify(property)}]`);
const sheet = () => read(`document.getElementById("avra-style").textContent`);
// The buttons whose words do not stand out from what they are drawn on:
// WCAG contrast of each one's ink against the nearest fill under it, under
// 4.5 to 1.
const faint = () => read(`(() => {
  const light = (rgb) => { const [r, g, b] = rgb.match(/[\\d.]+/g).slice(0, 3).map((v) => { const c = v / 255; return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4; }); return 0.2126 * r + 0.7152 * g + 0.0722 * b; };
  const clear = (rgb) => rgb === "transparent" || /,\\s*0\\)$/.test(rgb);
  const under = (el) => { const fill = getComputedStyle(el).backgroundColor; return clear(fill) && el.parentElement ? under(el.parentElement) : fill; };
  const ratio = (el) => { const [a, b] = [light(getComputedStyle(el).color), light(under(el))].sort((x, y) => y - x); return (a + 0.05) / (b + 0.05); };
  return [...document.querySelectorAll("button")].filter((b) => ratio(b) < 4.5).map((b) => b.textContent);
})()`);

await read(`new Promise((ready) => { const look = setInterval(() => { if (document.querySelector("li")) { clearInterval(look); ready(1); } }, 20); })`);
await watch(page);

// ── the first paint ─────────────────────────────────────────────
await shot("first");
claim("the page loads with nothing on its console", page.complaints().length === 0, page.complaints());
claim("the sheet styles the page: the body wears the theme's surface", await styled("document.body", "backgroundColor") === "rgb(255, 255, 255)" && await styled("document.body", "marginTop") === "0px");
claim("the server's four tasks are drawn in order, under its keys", (await keys()).join() === [k1, k2, k3, k4].join(), await keys());
claim("a done task is a real checkbox, checked", await read(`[...document.querySelectorAll("li input")].map((i) => i.type + ":" + i.checked).join()`) === "checkbox:true,checkbox:false,checkbox:false,checkbox:true");
claim("the progress holds its amount and its end", await read(`(() => { const p = document.querySelector("progress"); return [p.value, p.max]; })()`).then((v) => v.join() === "2,4"));
claim("every control's words are drawn beside it", await read(`[...document.querySelectorAll("label > span")].every((s) => s.getBoundingClientRect().width > 0)`));
// The least space between two neighbours on one line under each element
// `selecting` answers: the list is those whose neighbours touch.
const touching = (selecting) => read(`[...${selecting}].filter((el) => [...el.children].some((kid, i, kids) => i > 0 && kid.getBoundingClientRect().left - kids[i - 1].getBoundingClientRect().right < 1 && kid.getBoundingClientRect().top < kids[i - 1].getBoundingClientRect().bottom)).map((el) => el.textContent)`);
const leads = (selecting) => read(`(() => { const label = ${selecting}.closest("label"); return label.querySelector("span").getBoundingClientRect().right <= ${selecting}.getBoundingClientRect().left; })()`);
const fill = (selecting) => styled(selecting, "backgroundColor");

claim("a field and a progress are named and then shown", await leads(named("New task")) && await leads(named("Done")));
claim("a box is ticked and then named", !(await leads(named("Draft the spec"))));
claim("nothing in a row or an item touches its neighbour", (await touching(`document.querySelectorAll("li, .dir-row")`)).length === 0, await touching(`document.querySelectorAll("li, .dir-row")`));
claim("an item keeps its marker", await styled(`document.querySelector("li")`, "display") === "list-item");
claim("every button's words stand out from what it is drawn on", (await faint()).length === 0, await faint());
claim("the chosen filter is told from the others by its fill", await fill(named("All")) !== await fill(named("Active")), await fill(named("All")));
claim("what stacks its children draws the gap it names", await styled(`document.querySelector("article")`, "display") === "flex" && await styled(`document.querySelector("article")`, "rowGap") === "16px");
claim("a closed dialog is not drawn, whatever its classes say", await styled(`document.querySelector("dialog")`, "display") === "none");

// ── the pointer ─────────────────────────────────────────────────
await read(`document.querySelectorAll("li").forEach((li) => { li.witness = li.dataset.key; }), 1`);
await press(`${row(k3)}.querySelector("button")`);
claim("pressing a row's Remove takes that row alone, once the server has answered", await keys_become([k1, k2, k4].join()) === [k1, k2, k4].join(), await keys());
claim("the row below is the same element: nothing rebuilt it", await read(`${row(k4)}.witness`) === k4, await read(`[...document.querySelectorAll("li")].map((li) => li.dataset.key + ":" + li.witness)`));
claim("and the server no longer holds the task", !(await (await fetch(url + "tasks")).json()).some((t) => String(t.id) === k3));

await press(named("Wire the event channel"));
claim("ticking a box marks its task done and moves the progress, once the server has answered", await waited(`document.querySelector("progress").value === 3`) && (await rows())[1].done, await progress());
claim("and the server holds the task done", (await (await fetch(url + "tasks")).json()).find((t) => String(t.id) === k2).done === true);

// ── typing ──────────────────────────────────────────────────────
await press(named("New task"));
await type(..."Ship it");
await type(KEY.left, KEY.left, KEY.left, "X");
claim("typing mid-text keeps the caret where the user put it", await read(`(() => { const f = ${named("New task")}; return [f.value, f.selectionStart]; })()`).then((v) => v.join() === "ShipX it,5"));
await shot("typing");
await press(named("Add"));
claim("the program clears the field", await read(`${named("New task")}.value`) === "");
claim("Add appends the row the server made of it", await waited(`[...document.querySelectorAll("li")].some((li) => li.textContent.includes("ShipX it"))`) && (await rows()).at(-1).words === "ShipX it", await rows());
const k5 = (await rows()).at(-1).key;

// ── the filters ─────────────────────────────────────────────────
await press(named("Active"));
claim("Active shows the open tasks", (await keys()).join() === k5, await keys());
await press(named("Done", 1));
claim("Done shows the done tasks", (await keys()).join() === [k1, k2, k4].join(), await keys());
await press(named("All"));
claim("All shows every task", (await keys()).join() === [k1, k2, k4, k5].join(), await keys());

// ── the theme ───────────────────────────────────────────────────
const light = await sheet();
await press(named("Dark mode"));
await shot("dark");
claim("the dark mode swaps the sheet and the page wears it", await sheet() !== light && await styled("document.body", "backgroundColor") === "rgb(18, 18, 18)");
claim("the browser's own controls wear the dark scheme", await styled("document.documentElement", "colorScheme") === "dark");
claim("the chosen filter is told from the others in the dark mode too", await fill(named("All")) !== await fill(named("Active")), await fill(named("All")));
claim("every button's words stand out from its fill", (await faint()).length === 0, await faint());

// ── the dialog ──────────────────────────────────────────────────
const dialog = `document.querySelector("dialog")`;
await press(named("About"));
await shot("dialog");
const box = await read(`(() => { const r = ${dialog}.getBoundingClientRect(); return { top: r.top, left: r.left, bottom: r.bottom, right: r.right, wide: innerWidth, high: innerHeight }; })()`);
claim("About opens a real dialog, drawn whole inside the window", await read(`${dialog}.open`) && box.top >= 0 && box.left >= 0 && box.bottom <= box.high && box.right <= box.wide, box);
claim("it is modal, and the focus has moved inside it", await read(`${dialog}.matches(":modal")`) && await read(`${dialog}.contains(document.activeElement)`));
claim("an open dialog wears the theme's surface", await styled(dialog, "backgroundColor") === "rgb(18, 18, 18)");
await read(`${named("About")}.focus(), 1`);
claim("nothing behind it takes the focus", await read(`${dialog}.contains(document.activeElement)`), await focused());
await press(named("Close"));
claim("Close closes it, and the focus goes back where it was", await read(`${dialog}.open`) === false && await focused() === "About");
await press(named("About"));
await type(KEY.escape);
claim("Escape sends it away", await read(`${dialog}.open`) === false);
await press(named("About"));
claim("the program heard that: About opens it again", await read(`${dialog}.open`) && await read(`${dialog}.matches(":modal")`));
await press(named("Light mode"));
const stillOpen = await read(`${dialog}.open`);
claim("a press outside it sends it away, and reaches nothing behind it", stillOpen === false && await read(`${named("Light mode")} !== undefined`), { open: stillOpen, closedby: await read(`${dialog}.getAttribute("closedby")`) });
await press(named("About"));
claim("and it opens again after that too", await read(`${dialog}.open`));
await press(named("Close"));
await press(named("Light mode"));

await outsidePresses({ ...page, escape: () => type(KEY.escape), quiet: () => agreed(page) }, "", claim, named);

// ── the keyboard ────────────────────────────────────────────────
await read(`${named("Dark mode")}.focus(), 1`);
const order = [];
for (let i = 0; i < 7; i++) { await type(KEY.tab); order.push(await focused()); }
claim("Tab reaches each control in reading order", order.join() === "All,Active,Done,Clear done,Newest first,New task,Add", order);
await shot("focus");
await read(`${named("Dark mode")}.focus(), 1`);
await type(" ");
claim("Space presses the focused button, and the focus stays on it", await focused() === "Light mode", await focused());
await type(KEY.enter);
claim("Enter presses it too", await focused() === "Dark mode");

// ── what the page keeps ─────────────────────────────────────────
// A handler is run from script (`click()`), so the focus stays where the
// user left it while the program repaints.
const field = named("New task");
await press(field);
await type(..."Keep me");
await type(KEY.left, KEY.left);
await read(`${named("Draft the spec")}.click(), 1`);
await agreed();
claim("the box ticked from script repainted the page: the server's list moved the progress", await progress() === 2 && (await rows())[0].done === false, { rows: await rows(), log: await read(`window.__log.slice(-14)`), footer: await read(`[...document.querySelectorAll("*")].find((e) => e.children.length === 0 && e.textContent.includes("open ·"))?.textContent`), server: await (await fetch(url + "tasks")).json() });
claim("a repaint elsewhere leaves a field its text, its caret and the focus", await read(`(() => { const f = ${field}; return [f.value, f.selectionStart, document.activeElement === f]; })()`).then((v) => v.join() === "Keep me,5,true"));
await read(`${named("Draft the spec")}.click(), 1`);
await agreed();

const carried = named("Wire the event channel");
await read(`(() => { const b = ${carried}; b.focus(); b.witness = "kept"; ${row(k2)}.witness = "t2"; })(), 1`);
await read(`${named("Newest first")}.click(), 1`);
await frame();
claim("Newest first turns the rows end for end", (await keys()).join() === [k5, k4, k2, k1].join(), await keys());
claim("a keyed row carried to another place is the same element", await read(`${row(k2)}.witness`) === "t2");
claim("and the focus is kept on the control inside it", await read(`(() => { const b = ${carried}; return [document.activeElement === b, b.witness]; })()`).then((v) => v.join() === "true,kept"));
await read(`${named("Newest first")}.click(), 1`);
await frame();
claim("the rows turn back, the focus still kept", (await keys()).join() === [k1, k2, k4, k5].join() && await read(`document.activeElement === ${carried}`), await keys());

// ── the dev loop ────────────────────────────────────────────────
// Until `holds` answers true of the page, asked for as long as a build takes.
const until = async (holds) => { for (let i = 0; i < 200; i++) { if (await read(holds).catch(() => false)) return true; await new Promise((go) => setTimeout(go, 100)); } return false; };
if (source) {
  await agreed();
  const written = fs.readFileSync(source, "utf8");
  const says = (words) => `document.body.textContent.includes(${JSON.stringify(words)})`;
  claim("the dev page names the module it loaded", (await read(`document.querySelector('meta[name="avra-module"]').content`)).length > 0);

  await read(`(window.witness = "kept", 1)`);
  const ticked = (await rows())[1].done;
  const standing_module = () => read(`document.documentElement.getAttribute("data-avra-module")`);
  const before = await standing_module();
  fs.writeFileSync(source, written.replace(`fn title() -> string { "Tasks" }`, `fn title() -> string { "Chores" }`));
  // The page names its module again when the swap lands: wait on that, for as long as a build may take, and say so if it never comes.
  const swapped = await until(`document.documentElement.getAttribute("data-avra-module") !== ${JSON.stringify(before)}`);
  if (!swapped) console.log(`  no swap landed within the build bound: the page still runs module ${before}`);
  claim("a view edited where it stands reaches the running page", swapped && await read(says("Chores")) && !(await read(says("Tasks"))), await standing_module());
  claim("and the page was not reloaded to show it", await read(`window.witness`) === "kept");
  claim("and the state the page had comes through the edit: a ticked box stays ticked", ticked === true && (await rows())[1].done === true, await rows());
  await shot("edited");

  fs.writeFileSync(source, `${written}\nfn broken( {\n`);
  const failure = `document.getElementById("avra-dev-failure")`;
  claim("a build that fails is shown over the page, naming the file", await until(`${failure} && !${failure}.hidden && ${failure}.textContent.includes(${JSON.stringify(path.basename(source))})`));
  await shot("failed");
  await press(named("Wire the event channel"));
  await agreed();
  claim("the last good page keeps running under it", await read(says("Chores")) && (await rows())[1].done === false);

  fs.writeFileSync(source, written);
  claim("the mended source is served, and the failure is gone", await until(`${says("Tasks")} && !(${failure} && !${failure}.hidden)`));
}

claim("nothing reached the console while the board was used", page.complaints().length === 0, page.complaints());
await page.close();

// ── every change is the server's ────────────────────────────────
// `avra dev` runs the board's server beside the page, and the server holds a
// file database. Each change the board makes is sent through the server's
// doors as it is made, and a page loaded again in a browser that has never
// seen it shows what the server holds: an added task, a ticked one, a removed one.
{
  await emptied();
  const board = await openPage(firefoxBinary(), url);
  const waits = async (holds) => { for (let i = 0; i < 100; i++) { if (await board.read(holds).catch(() => false)) return true; await new Promise((go) => setTimeout(go, 100)); } return false; };
  const drawn = (p) => p.read(`[...document.querySelectorAll("li")].map((li) => ({ key: li.dataset.key, done: li.querySelector("input").checked, words: li.textContent }))`);
  const reloaded = async (until) => {
    const again = await openPage(firefoxBinary(), url);
    let seen = [];
    for (let i = 0; i < 100; i++) { seen = await drawn(again).catch(() => []); if (until(seen)) break; await new Promise((go) => setTimeout(go, 100)); }
    const complaints = again.complaints();
    await again.close();
    return { seen, complaints };
  };
  await waits(`document.body.textContent.includes("Nothing here yet.")`);
  await watch(board);
  claim("a server holding no tasks leaves the board with none", (await drawn(board)).length === 0, await drawn(board));
  await board.press(named("New task"));
  await board.type(..."Buy milk");
  await board.press(named("Add"));
  claim("an added task is the board's once the server has made it", await waits(`[...document.querySelectorAll("li")].some((li) => /^[0-9]+$/.test(li.dataset.key) && li.textContent.includes("Buy milk"))`), await drawn(board));
  let again = await reloaded((rows) => rows.some((r) => r.words.includes("Buy milk")));
  claim("and a page loaded again shows it", again.seen.length === 1 && again.seen[0].words.includes("Buy milk") && !again.seen[0].done, again.seen);
  await board.press(named("Buy milk"));
  claim("a task ticked is ticked on the server: a page loaded again shows it done", await (async () => { const r = await reloaded((rows) => rows.length === 1 && rows[0].done); return r.seen.length === 1 && r.seen[0].done; })());
  // Writes to one task go out in click order, each after the last was answered: a burst sends its first
  // change and its last, and the server ends as the last click left it.
  const logged = await board.read(`window.__log.length`);
  await board.read(`(() => { const box = document.querySelector('[aria-label="Buy milk"]'); box.click(); box.click(); box.click(); return 1; })()`);
  await agreed(board);
  const patches = (await board.read(`window.__log.slice(${logged})`)).filter((entry) => entry.startsWith("> PATCH")).length;
  claim("three quick ticks send two writes at most", patches >= 1 && patches <= 2, patches);
  again = await reloaded((rows) => rows.length === 1 && !rows[0].done);
  claim("and a page loaded again shows the state the last click left: three ticks undo one", again.seen.length === 1 && !again.seen[0].done, again.seen);
  // A RELOAD DURING A WRITE: the page that comes back shows what the server holds, whichever way the write fell.
  await board.read(`(() => { document.querySelector('[aria-label="Buy milk"]').click(); setTimeout(() => location.reload(), 0); return 1; })()`);
  await waits(`document.querySelector("li") !== null && document.documentElement.getAttribute("data-avra") === "ready"`);
  await watch(board);
  claim("a page reloaded during a write shows what the server holds", await agreed(board) && (await drawn(board)).length === 1, await drawn(board));
  await board.press(`document.querySelector("li button")`);
  claim("a task removed is gone from the board once the server has answered", await waits(`document.querySelectorAll("li").length === 0`), await drawn(board));
  again = await reloaded((rows) => rows.length === 0);
  claim("and a page loaded again shows none", again.seen.length === 0, again.seen);
  claim("the server holds nothing", (await (await fetch(url + "tasks")).json()).length === 0);
  claim("nothing reached either console", board.complaints().length === 0 && again.complaints.length === 0, [...board.complaints(), ...again.complaints]);
  await board.close();
}

// ── an engine that does not send a dialog away on its own ───────
// The same board where the browser knows no `closedby`: the page sends the
// dialog away itself, by the same rule. The pref is Firefox's, so this page
// is that engine's alone.
if (engine === "firefox") {
  await seeded();
  const unaware = await openPage(firefoxBinary(), url, { prefs: { "dom.dialog.light-dismiss.enabled": false } });
  await unaware.read(`new Promise((ready) => { const look = setInterval(() => { if (document.querySelector("li")) { clearInterval(look); ready(1); } }, 20); })`);
  await watch(unaware);
  claim("this engine knows no `closedby`", await unaware.read(`!("closedBy" in HTMLDialogElement.prototype)`));
  await outsidePresses({ ...unaware, escape: () => unaware.type(KEY.escape), quiet: () => agreed(unaware) }, ", where the engine knows no `closedby`", claim, named);
  claim("nothing reached that page's console", unaware.complaints().length === 0, unaware.complaints());
  await unaware.close();
}
// A claim an engine cannot make is named with its reason, never left out unsaid.
if (engine !== "firefox") {
  const why = "the page that knows no `closedby` is made with Firefox's preference dom.dialog.light-dismiss.enabled, which this engine has no switch for";
  for (const words of ["this engine knows no `closedby`", ...outsidePressWords(", where the engine knows no `closedby`"), "nothing reached that page's console"]) {
    console.log(`skipped in ${engine}: ${words} — ${why}`);
  }
}

// Every task the board's server holds, removed through its own doors, so a
// section's claims begin from the board's seeds alone.
async function emptied() {
  let listed = null;
  for (let i = 0; i < 1500 && !(listed && listed.ok); i++) {
    listed = await fetch(url + "tasks").catch(() => null);
    if (!(listed && listed.ok)) await new Promise((go) => setTimeout(go, 200));
  }
  if (!(listed && listed.ok)) { console.log(`ui-browser: the server never answered GET /tasks (${listed ? listed.status : "no answer"})`); process.exit(1); }
  for (const row of await listed.json()) {
    const gone = await fetch(url + "tasks/" + row.id, { method: "DELETE" });
    if (!gone.ok) { console.log(`ui-browser: emptying the server, DELETE /tasks/${row.id} answered ${gone.status}`); process.exit(1); }
  }
}
await emptied();

// The module has run and painted: the page says so itself.
const standing = async (p) => { for (let i = 0; i < 200; i++) { if (await p.read(`document.documentElement.getAttribute("data-avra") === "ready"`).catch(() => false)) { await p.frame(); return true; } await new Promise((go) => setTimeout(go, 100)); } return false; };

// ── a server's page, adopted by the module ──────────────────────
// The elements the server drew are marked before the module runs.
if (hydrated) {
  // The server holds the tasks the page it drew showed, so the list it answers with is the one shipped.
  await seeded();
  const adopted = await opened(hydrated);
  const asked = adopted.read;
  const ready = `document.querySelector("#app button") !== null && [...document.querySelectorAll("#app *")].length > 0`;
  claim("a server's page stands before the module runs", await asked(`[...document.querySelectorAll("#app *")].every((el) => el.__served === true) && ${ready}`));
  claim("the module stands on it", await standing(adopted));
  const total = await asked(`document.querySelectorAll("#app *").length`);
  const kept = await asked(`[...document.querySelectorAll("#app *")].filter((el) => el.__served === true).length`);
  claim("the module took the server's elements over and built none", kept === total, `${kept} of ${total}`);
  const held = await asked(`[...document.querySelectorAll("li")].map((li) => li.dataset.key)`);
  claim("the module started from the state the server shipped: the done tasks, in the dark", (await asked(`[...document.querySelectorAll("li")].map((li) => li.querySelector("label").textContent)`)).join() === "Draft the spec,Write the tour" && await asked(`getComputedStyle(document.body).backgroundColor`) === "rgb(18, 18, 18)");
  // The server's list is answered only now: the page stood on the server's paint until it came.
  await fetch(hydrated + "__release");
  const answered = await (async () => { for (let i = 0; i < 100; i++) { const now = await asked(`[...document.querySelectorAll("li")].map((li) => li.dataset.key)`); if (now.join() !== held.join()) return now; await new Promise((go) => setTimeout(go, 50)); } return held; })();
  claim("the server's list then lands as the board's: the done tasks stand under the server's keys", answered.length === 2 && answered.every((key) => /^[0-9]+$/.test(key)), answered);
  await adopted.press(`document.querySelector('[aria-label="Light mode"]')`);
  claim("and the page answers a press through the adopted elements", await asked(`document.querySelector('[aria-label="Dark mode"]') !== null`));
  claim("nothing reached the console while the server's page was adopted", adopted.complaints().length === 0, adopted.complaints());
  await adopted.close();
}
if (tampered) {
  const torn = await opened(tampered);
  await standing(torn);
  claim("a page the module did not draw is drawn again whole", await torn.read(`document.querySelectorAll('#app [aria-label]').length >= 5 && document.querySelector('[aria-label="Light mode"]') !== null`));
  await torn.press(`document.querySelector('[aria-label="Light mode"]')`);
  claim("and it answers a press", await torn.read(`document.querySelector('[aria-label="Dark mode"]') !== null`));
  await torn.close();
}
console.log(failed === 0 ? `ui-browser: every claim holds in ${engine}` : `ui-browser: ${failed} claim(s) FAILED in ${engine}`);
await launched?.browser.close();
process.exit(failed === 0 ? 0 : 1);
