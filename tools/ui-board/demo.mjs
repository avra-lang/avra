// M1 end to end, headless: the real module + the REAL page glue (bootstrap +
// WASI surface) over a stub document. Prints the tree after the first paint
// and after each event, so the wire, the glue and the app are proven together
// before any browser is opened.
//
// THE CONTROLS ARE THE LIBRARY'S OWN, so the events are their own kinds: a
// button subscribes `click`, a checkbox `change`, a field `input`. The demo
// finds each control by its words and presses the kind it bound — never a
// synthetic event — so it proves the same path the page takes.
import fs from "node:fs";
import { createApplier, instantiate, frameOf, sendEvent } from "../../runtime/dom/bootstrap.js";
import { wasiPreview1 } from "../../runtime/dom/wasi.js";

function el(tag) {
  return {
    tagName: tag, childNodes: [], attrs: {}, textContent: "", value: "", parentNode: null,
    listeners: new Map(),
    setAttribute(k, v) { this.attrs[k] = v; },
    removeAttribute(k) { delete this.attrs[k]; },
    appendChild(c) { c.parentNode = this; this.childNodes.push(c); },
    insertBefore(c, at) {
      if (c.parentNode) c.parentNode.removeChild(c);
      const i = at ? this.childNodes.indexOf(at) : this.childNodes.length;
      this.childNodes.splice(i < 0 ? this.childNodes.length : i, 0, c);
      c.parentNode = this;
    },
    removeChild(c) { const i = this.childNodes.indexOf(c); if (i >= 0) this.childNodes.splice(i, 1); c.parentNode = null; },
    addEventListener(name, fn) { this.listeners.set(name, fn); },
    removeEventListener(name) { this.listeners.delete(name); },
  };
}
const doc = { createElement: (t) => el(t) };
const mount = el("root");
const style = { textContent: "" };
let mod = null;
const applier = createApplier(doc, mount, (who, what, payload) => sendEvent(mod, who, what, payload), style);

mod = await instantiate(new Uint8Array(fs.readFileSync(process.argv[2])), {
  wasi: wasiPreview1(() => mod.memory, (code) => { throw new Error(`the program exited ${code}`); }),
  rt: { avra_dom_frame: (ptr) => applier(frameOf(mod.memory, ptr, mod.avra_bytes_len)) },
});

const shape = (n) => {
  const cls = n.attrs["class"] ? `.${n.attrs["class"]}` : "";
  const text = n.textContent ? `("${n.textContent}")` : "";
  const kids = n.childNodes.length ? `{${n.childNodes.map(shape).join(",")}}` : "";
  return `${n.tagName}${cls}${text}${kids}`;
};
const findClick = (n) => {
  if (n.listeners.has("click")) return n;
  for (const c of n.childNodes) { const hit = findClick(c); if (hit) return hit; }
  return null;
};
const findByKey = (n, key) => {
  if (n.attrs && n.attrs["data-key"] === key) return n;
  for (const c of n.childNodes) { const hit = findByKey(c, key); if (hit) return hit; }
  return null;
};
// A control by its words: whichever kind it bound, the demo presses that.
// A labelled control's words sit beside it, and its listeners on the control.
const wordsOf = (n) => (n.__avra_words ? n.__avra_words.textContent : n.textContent);
const findControl = (n, words) => {
  const control = n.__avra_control || n;
  if (wordsOf(n) === words && control.listeners.size > 0) return control;
  for (const c of n.childNodes) { const hit = findControl(c, words); if (hit) return hit; }
  return null;
};
const press = (n) => { const [kind, fn] = [...n.listeners][0]; fn(); return kind; };

mod._initialize();
mod.avra_start();
console.log("STYLE:", style.textContent.includes(":root{") ? "sent (theme vars present)" : `MISSING (${style.textContent.slice(0, 40)})`);
console.log("AFTER START:", shape(mount));
const clickable = findClick(mount);
console.log("CLICKABLE:", clickable ? clickable.tagName : "none");

const remove3 = findByKey(mount, "t3") && findControl(findByKey(mount, "t3"), "Remove");
console.log("ROW3 REMOVE:", remove3 ? "found" : "missing");
if (remove3) {
  console.log("PRESSED:", press(remove3));
  console.log("t3 gone:", findByKey(mount, "t3") === null, " t2 kept:", findByKey(mount, "t2") !== null);
}
const toggle2 = findByKey(mount, "t2") && findControl(findByKey(mount, "t2"), "Wire the event channel");
console.log("ROW2 TOGGLE:", toggle2 ? "found" : "missing");
if (toggle2) {
  console.log("PRESSED:", press(toggle2));
  const row2 = findByKey(mount, "t2");
  console.log("AFTER TOGGLE t2:", shape(row2));
}

// ADD FROM THE FIELD: the input's own text rides the input event, then the
// Add button appends the task the draft named.
const field = findControl(mount, "New task");
const add = findControl(mount, "Add");
console.log("FIELD+ADD:", field ? "field" : "no field", add ? "add" : "no add");
if (field && add) {
  field.value = "Ship the rewrite";
  console.log("PRESSED:", press(field));
  console.log("PRESSED:", press(add));
  console.log("added row:", findByKey(mount, "t5") !== null, " title kept:", findControl(mount, "Ship the rewrite") !== null);
}
