// What a windowed list asks of the program, over a list laid out by hand:
// rows `h` tall from `top`, spacers standing for the rest, a viewport.
import { askOf } from "./windows.js";

let passed = 0;
let failed = 0;
const test = (name, holds) => {
  if (holds) { passed++; console.log(`✓ ${name}`); } else { failed++; console.log(`✗ ${name}`); }
};

const rect = (top, height) => ({ top, bottom: top + height, height });
const spacer = (top, skip, extent) => ({
  hasAttribute: (n) => n === "data-avra-window",
  getAttribute: (n) => ({ "data-avra-window": "p", "data-avra-skip": String(skip), "data-avra-extent": String(extent) })[n] ?? null,
  getBoundingClientRect: () => rect(top, skip * extent),
});
const row = (top, h) => ({ hasAttribute: () => false, getAttribute: () => null, getBoundingClientRect: () => rect(top, h) });
const view = { innerHeight: 600, getComputedStyle: () => ({ overflowY: "visible" }) };
const doc = { defaultView: view };

// A list of `total` rows, `h` tall, the built ones being `from` up to `to`,
// scrolled so the page's top is `scrolled` px down the list.
const list = (total, from, to, h, declared, scrolled) => {
  const kids = [];
  if (from > 0) kids.push(spacer(-scrolled, from, declared));
  for (let i = from; i < to; i++) kids.push(row(from * declared + (i - from) * h - scrolled, h));
  if (to < total) kids.push(spacer(from * declared + (to - from) * h - scrolled, total - to, declared));
  return { children: kids, parentElement: null };
};

test("rows on screen all built and measuring as declared ask nothing", () => askOf(list(1000, 0, 40, 30, 30, 0), view, doc) === null);
test("a first measure is asked for even where the rows serve", () => {
  const ask = askOf(list(1000, 0, 40, 30, 0, 0), view, doc);
  return ask !== null && ask.extent === 30 && ask.from === 0;
});
test("a scroll past the built rows asks for the rows on screen and a viewport each side", () => {
  const ask = askOf(list(1000, 0, 40, 30, 30, 1500), view, doc);
  return ask !== null && ask.from <= 50 && ask.to >= 70 && ask.to <= 1000 && ask.path === "p";
});
test("a scroll inside the built rows asks nothing", () => askOf(list(1000, 100, 160, 30, 30, 3500), view, doc) === null);
test("a list with every row built has no spacer and asks nothing", () => askOf({ children: [row(0, 30), row(30, 30)], parentElement: null }, view, doc) === null);
test("the window is kept inside the rows there are", () => {
  const ask = askOf(list(100, 0, 40, 30, 30, 2400), view, doc);
  return ask !== null && ask.to === 100;
});

console.log(`${passed} passed, ${failed} failed`);
process.exit(failed === 0 ? 0 : 1);
