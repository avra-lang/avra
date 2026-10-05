// The board in a REAL browser: the module and the page glue served over an
// HTTP origin, loaded by headless Firefox, and driven with the browser's
// own pointer and keys (firefox.mjs). demo.mjs proves the wire over a stub
// document; this proves what only an engine can — that the sheet styles
// the page, that a control is the control a reader expects, that typing
// keeps its caret, that the keyboard reaches everything. Each claim is
// CHECKED and one failure exits 1. `make ui-browser` builds and runs it.
//
//   node browser.mjs <page url> [directory for screenshots]
import path from "node:path";
import { openPage, firefoxBinary, KEY } from "./firefox.mjs";

const [url, shots] = process.argv.slice(2);
const page = await openPage(firefoxBinary(), url);
const { read, press, type } = page;

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

// ── the first paint ─────────────────────────────────────────────
await shot("first");
claim("the page loads with nothing on its console", page.complaints().length === 0, page.complaints());
claim("the sheet styles the page: the body wears the theme's surface", await styled("document.body", "backgroundColor") === "rgb(255, 255, 255)" && await styled("document.body", "marginTop") === "0px");
claim("the four seeded rows are drawn in order", (await keys()).join() === "t1,t2,t3,t4", await keys());
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
await press(`${row("t3")}.querySelector("button")`);
claim("pressing a row's Remove takes that row alone", (await keys()).join() === "t1,t2,t4", await keys());
claim("the row below is the same element: nothing rebuilt it", await read(`${row("t4")}.witness`) === "t4");

await press(named("Wire the event channel"));
claim("ticking a box marks its task done and moves the progress", (await rows())[1].done && await read(`document.querySelector("progress").value`) === 2 + 1);

// ── typing ──────────────────────────────────────────────────────
await press(named("New task"));
await type(..."Ship it");
await type(KEY.left, KEY.left, KEY.left, "X");
claim("typing mid-text keeps the caret where the user put it", await read(`(() => { const f = ${named("New task")}; return [f.value, f.selectionStart]; })()`).then((v) => v.join() === "ShipX it,5"));
await shot("typing");
await press(named("Add"));
claim("Add appends the row the field named", (await rows()).at(-1).words === "ShipX it", await rows());
claim("the program clears the field", await read(`${named("New task")}.value`) === "");

// ── the filters ─────────────────────────────────────────────────
await press(named("Active"));
claim("Active shows the open tasks", (await keys()).join() === "t5", await keys());
await press(named("Done", 1));
claim("Done shows the done tasks", (await keys()).join() === "t1,t2,t4", await keys());
await press(named("All"));
claim("All shows every task", (await keys()).join() === "t1,t2,t4,t5", await keys());

// ── the theme ───────────────────────────────────────────────────
const light = await sheet();
await press(named("Dark mode"));
await shot("dark");
claim("the dark mode swaps the sheet and the page wears it", await sheet() !== light && await styled("document.body", "backgroundColor") === "rgb(18, 18, 18)");
claim("the browser's own controls wear the dark scheme", await styled("document.documentElement", "colorScheme") === "dark");
claim("the chosen filter is told from the others in the dark mode too", await fill(named("All")) !== await fill(named("Active")), await fill(named("All")));
claim("every button's words stand out from its fill", (await faint()).length === 0, await faint());

// ── the dialog ──────────────────────────────────────────────────
await press(named("About"));
await shot("dialog");
const box = await read(`(() => { const r = document.querySelector("dialog").getBoundingClientRect(); return { top: r.top, left: r.left, bottom: r.bottom, right: r.right, wide: innerWidth, high: innerHeight }; })()`);
claim("About opens a real dialog, drawn whole inside the window", await read(`document.querySelector("dialog").open`) && box.top >= 0 && box.left >= 0 && box.bottom <= box.high && box.right <= box.wide, box);
claim("an open dialog wears the theme's surface", await styled(`document.querySelector("dialog")`, "backgroundColor") === "rgb(18, 18, 18)");
await press(named("Close"));
claim("Close closes it", await read(`document.querySelector("dialog").open`) === false);
await press(named("Light mode"));

// ── the keyboard ────────────────────────────────────────────────
await read(`${named("Dark mode")}.focus(), 1`);
const order = [];
for (let i = 0; i < 6; i++) { await type(KEY.tab); order.push(await focused()); }
claim("Tab reaches each control in reading order", order.join() === "All,Active,Done,Clear done,New task,Add", order);
await shot("focus");
await read(`${named("Dark mode")}.focus(), 1`);
await type(" ");
claim("Space presses the focused button, and the focus stays on it", await focused() === "Light mode");
await type(KEY.enter);
claim("Enter presses it too", await focused() === "Dark mode");

claim("nothing reached the console while the board was used", page.complaints().length === 0, page.complaints());
await page.close();
console.log(failed === 0 ? "ui-browser: every claim holds" : `ui-browser: ${failed} claim(s) FAILED`);
process.exit(failed === 0 ? 0 : 1);
