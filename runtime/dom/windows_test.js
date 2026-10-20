// What a windowed list asks of the program, over a list laid out by hand:
// rows `h` tall, spacers standing for the rest, a viewport.
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
  contains: () => false,
});
const row = (top, h, at, total) => ({
  at,
  hasAttribute: () => false,
  getAttribute: (n) => ({ "aria-posinset": String(at + 1), "aria-setsize": String(total), "data-key": `k${at}` })[n] ?? null,
  getBoundingClientRect: () => rect(top, h),
  contains(el) { return el === this; },
});
const view = { innerHeight: 600, getComputedStyle: () => ({ overflowY: "visible" }) };
const doc = (active = null) => ({ defaultView: view, activeElement: active });

// A list of `total` rows, `h` tall, the rows `from` up to `to` built (and the
// row `held` beside them, when given), `declared` the height each skipped row
// is spaced at, the page's top `scrolled` px down the list.
const list = (total, from, to, h, declared, scrolled, held = null) => {
  const kids = [];
  let y = -scrolled;
  const gap = (rows) => { if (rows > 0) { kids.push(spacer(y, rows, declared)); y += rows * declared; } };
  let next = 0;
  const put = (i) => { gap(i - next); const r = row(y, h, i, total); kids.push(r); y += h; next = i + 1; return r; };
  if (held !== null && held < from) put(held);
  for (let i = from; i < to; i++) put(i);
  if (held !== null && held >= to) put(held);
  gap(total - next);
  return { children: kids, parentElement: null };
};

test("rows on screen all built and measuring as declared ask nothing", () => askOf(list(1000, 0, 40, 30, 30, 0), view, doc()) === null);
test("a first measure is asked for even where the rows serve", () => {
  const ask = askOf(list(1000, 0, 40, 30, 0, 0), view, doc());
  return ask !== null && ask.extent === 30 && ask.from === 0;
});
test("a scroll past the built rows asks for the rows on screen and a viewport each side", () => {
  const ask = askOf(list(1000, 0, 40, 30, 30, 1500), view, doc());
  return ask !== null && ask.from <= 50 && ask.to >= 70 && ask.to <= 1000 && ask.path === "p";
});
test("a scroll inside the built rows asks nothing", () => askOf(list(1000, 100, 160, 30, 30, 3500), view, doc()) === null);
test("a list with every row built has no spacer and asks nothing", () => {
  const rows = [row(0, 30, 0, 2), row(30, 30, 1, 2)];
  return askOf({ children: rows, parentElement: null }, view, doc()) === null;
});
test("the window is kept inside the rows there are", () => {
  const ask = askOf(list(100, 0, 40, 30, 30, 2400), view, doc());
  return ask !== null && ask.to === 100;
});
test("a row the focus keeps built apart from the window does not move the window", () => {
  const l = list(1000, 100, 160, 30, 30, 3500, 3);
  const pinned = l.children.find((k) => k.at === 3);
  return askOf(l, view, doc(pinned), "k3") === null;
});
test("the focus moving to a row is told, with its key", () => {
  const l = list(1000, 100, 160, 30, 30, 3500);
  const focused = l.children.find((k) => k.at === 120);
  const ask = askOf(l, view, doc(focused), "");
  return ask !== null && ask.pin === "k120";
});
test("the focus leaving is told", () => {
  const ask = askOf(list(1000, 100, 160, 30, 30, 3500), view, doc(), "k120");
  return ask !== null && ask.pin === "";
});

console.log(`${passed} passed, ${failed} failed`);
process.exit(failed === 0 ? 0 : 1);
