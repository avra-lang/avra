// The board end to end, headless: the real module + the REAL page glue
// (bootstrap + WASI surface) over a stub document. Each claim below is
// CHECKED — a line says `ok` or `FAILED`, and one failure exits 1 — so
// the wire, the glue, `mount` and the app are proven together before any
// browser is opened. `make ui-board` builds the module and runs this.
//
// THE CONTROLS ARE THE LIBRARY'S OWN, so the events are the ones they
// declare: a button's `press`, a checkbox's `change` saying its state, a
// field's `input` saying its text. The demo finds each control as a reader
// of the page would — by its accessible name — and fires the listener the
// page was told to attach, never a synthetic event, so it proves the same
// path the page takes.
import fs from "node:fs";
import { run } from "../../runtime/dom/bootstrap.js";
import { wasiPreview1 } from "../../runtime/dom/wasi.js";
import { stubDocument, stubElement, textOf } from "../../runtime/dom/stub_dom.js";

const mount = stubElement("root");
const style = { textContent: "" };
let frames = 0;
let writes = 0;

await run(new Uint8Array(fs.readFileSync(process.argv[2])), {
  document: stubDocument(),
  mount,
  style,
  wasi: (memory) => wasiPreview1(memory, (code) => { throw new Error(`the program exited ${code}`); }),
  sent: (bytes) => { frames++; writes += bytes.length; },
});

const shape = (n) => {
  if (n.tagName === "#text") return `"${n.textContent}"`;
  const cls = n.attrs["class"] ? `.${n.attrs["class"]}` : "";
  const kids = n.childNodes.length ? `{${n.childNodes.map(shape).join(",")}}` : "";
  return `${n.tagName}${cls}${kids}`;
};
const every = (n, hit, out = []) => { if (hit(n)) out.push(n); n.childNodes.forEach((c) => every(c, hit, out)); return out; };
// A control by its accessible name, among those that listen.
const named = (name, under = mount) => every(under, (n) => n.attrs["aria-label"] === name && n.listeners.size > 0);
// A keyed row by its key.
const keyed = (key) => every(mount, (n) => n.attrs["data-key"] === key)[0] || null;
const fire = (n) => { const [event, listener] = [...n.listeners][0]; listener(); return event; };
// What one event cost the wire: frames and bytes since the last ask.
const spent = () => { const s = `${frames} frame(s), ${writes} byte(s)`; frames = 0; writes = 0; return s; };

let failed = 0;
// One claim: its words, whether it holds, and what was seen when it does not.
const claim = (words, holds, seen = "") => {
  if (!holds) failed++;
  console.log(`${holds ? "ok    " : "FAILED"} ${words}${holds || seen === "" ? "" : ` — saw ${seen}`}`);
};

claim("the first paint sends the theme's variables and the page's base rule", style.textContent.includes(":root{") && style.textContent.includes("body{"), style.textContent.slice(0, 40));
claim("the first paint is one frame", frames === 1, spent());
spent();
claim("the page holds the four seeded rows", ["t1", "t2", "t3", "t4"].every((k) => keyed(k) !== null), shape(mount).slice(0, 80));

// THE PER-ITEM HANDLER: row 3's Remove names row 3's task.
const row4 = keyed("t4");
const remove3 = named("Remove", keyed("t3"))[0];
claim("row t3 holds a Remove that listens", Boolean(remove3));
fire(remove3);
claim("pressing it removes t3 and keeps t2", keyed("t3") === null && keyed("t2") !== null);
claim("the row below is the same element: nothing rebuilt it", keyed("t4") === row4);
claim("a removal is one frame of under 200 bytes", frames === 1 && writes < 200, spent());
spent();

// The user checks the box; the control says its own state.
const toggle2 = named("Wire the event channel")[0];
claim("row t2's checkbox listens", Boolean(toggle2));
toggle2.checked = true;
fire(toggle2);
claim("checking it is one frame of under 200 bytes", frames === 1 && writes < 200, spent());
spent();

// ADD FROM THE FIELD: the input's own text rides the input event, then the
// Add button appends the task the draft named. THE CARET WITNESS: while the
// user types, the page's own value is never written back to it.
const field = named("New task")[0];
const add = named("Add")[0];
claim("the field and the Add button listen", Boolean(field) && Boolean(add));
let valueWrites = 0;
let typed = "";
Object.defineProperty(field, "value", { get: () => typed, set: (v) => { valueWrites++; typed = v; }, configurable: true });
typed = "Ship the rewrite";
fire(field);
claim("typing writes no value back and sends no frame", valueWrites === 0 && frames === 0, `${valueWrites} write(s), ${spent()}`);
fire(add);
claim("Add appends the row the draft named", keyed("t5") !== null && textOf(keyed("t5")).includes("Ship the rewrite"));
claim("the program clears the field, once", valueWrites === 1 && typed === "", `${valueWrites} write(s), value "${typed}"`);
spent();

// A TEXT OF ANY LENGTH: the program hands out a seat for the octets the
// field holds, so a value far past any fixed room arrives whole.
typed = "é".repeat(6000);
fire(field);
fire(add);
claim("a 12000-octet title is kept whole", keyed("t6") !== null && textOf(keyed("t6")).includes(typed));
spent();

// A MODE IS A WHOLE SHEET: the theme's variables move and no element does.
const theme = named("Dark mode")[0];
const sheet = style.textContent;
fire(theme);
claim("the dark mode rewrites the sheet and renames its button", style.textContent !== sheet && named("Light mode").length === 1);

console.log(failed === 0 ? "ui-board: every claim holds" : `ui-board: ${failed} claim(s) FAILED`);
process.exit(failed === 0 ? 0 : 1);
