// The board end to end, headless: the real module + the REAL page glue
// (bootstrap + WASI surface) over a stub document. Prints the page after
// the first paint and after each event, so the wire, the glue and the app
// are proven together before any browser is opened.
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

console.log("STYLE:", style.textContent.includes(":root{") && style.textContent.includes("body{") ? "sent (theme vars and the page's base rule)" : `MISSING (${style.textContent.slice(0, 40)})`);
console.log("AFTER START:", shape(mount));
console.log("FIRST PAINT:", spent());

const row4 = keyed("t4");
const remove3 = named("Remove", keyed("t3"))[0];
console.log("ROW3 REMOVE:", remove3 ? "found" : "missing");
console.log("FIRED:", fire(remove3), "—", spent());
console.log("t3 gone:", keyed("t3") === null, " t2 kept:", keyed("t2") !== null);
// The row below the removed one is the SAME element: nothing rebuilt it.
console.log("t4 same element:", keyed("t4") === row4);

const toggle2 = named("Wire the event channel")[0];
console.log("ROW2 TOGGLE:", toggle2 ? "found" : "missing");
// The user checks the box; the control says its own state.
toggle2.checked = true;
console.log("FIRED:", fire(toggle2), "—", spent());
console.log("AFTER TOGGLE t2:", shape(keyed("t2")));

// ADD FROM THE FIELD: the input's own text rides the input event, then the
// Add button appends the task the draft named. THE CARET WITNESS: while the
// user types, the page's own value is never written back to it.
const field = named("New task")[0];
const add = named("Add")[0];
console.log("FIELD+ADD:", field ? "field" : "no field", add ? "add" : "no add");
let valueWrites = 0;
let typed = "";
Object.defineProperty(field, "value", { get: () => typed, set: (v) => { valueWrites++; typed = v; }, configurable: true });
typed = "Ship the rewrite";
console.log("FIRED:", fire(field), "—", spent());
console.log("value written while typing:", valueWrites);
console.log("FIRED:", fire(add), "—", spent());
console.log("added row:", keyed("t5") !== null, " title kept:", textOf(keyed("t5")).includes("Ship the rewrite"));
console.log("field cleared by the program:", valueWrites === 1 && typed === "");

// A TEXT OF ANY LENGTH: the program hands out a seat for the octets the
// field holds, so a value far past any fixed room arrives whole.
typed = "é".repeat(6000);
fire(field);
fire(add);
console.log("12000-octet title kept whole:", keyed("t6") !== null && textOf(keyed("t6")).includes(typed), "—", spent());

// A MODE IS A WHOLE SHEET: the theme's variables move and no element does.
const theme = named("Dark mode")[0];
const sheet = style.textContent;
console.log("FIRED:", fire(theme), "—", spent());
console.log("sheet rewritten:", style.textContent !== sheet, " button renamed:", named("Light mode").length === 1);
