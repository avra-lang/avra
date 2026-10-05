// Proves the bootstrap's law over the V7 BYTE wire: a frame builds the tree,
// a second frame REUSES each id's element, order follows the frame's index,
// a reorder moves the elements themselves, a dropped node leaves, a
// no-change frame touches nothing, and a frame of ANOTHER VERSION refuses.
import { createApplier, parseFrame, sendEvent } from "./bootstrap.js";

// A fixture encoder — the CONSUMING side is what is under test; the
// producing side's exact bytes are pinned by the Avra wire test. An id is
// the node's own; the root's parent is the empty id.
const i32 = (v) => [v & 255, (v >>> 8) & 255, (v >>> 16) & 255, (v >>> 24) & 255];
const utf8 = (s) => [...new TextEncoder().encode(s)];
const str = (s) => [...i32(utf8(s).length), ...utf8(s)];
const C = (id, parent, index, tag) => [1, ...str(id), ...str(parent), ...i32(index), ...str(tag)];
const A = (id, s) => [3, ...str(id), ...str(s)];
const T = (id, s) => [4, ...str(id), ...str(s)];
const S = (s) => [6, ...str(s)];
const P = (id, name, value) => [8, ...str(id), ...str(name), ...str(value)];
const E = (id, kind, says = 0) => [5, ...str(id), ...i32(kind), ...i32(says)];
const frame = (...recs) => Uint8Array.from([7, ...recs.flat()]);

function el(doc, tag) {
  return {
    tagName: tag, childNodes: [], attrs: {}, textContent: "", value: "", parentNode: null, listeners: new Map(),
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
const doc = { createElement: (tag) => el(null, tag) };
const mount = el(doc, "root");
const apply = createApplier(doc, mount);

let fails = 0;
let passes = 0;
function check(name, got, want) {
  const g = JSON.stringify(got), w = JSON.stringify(want);
  if (g !== w) { fails++; console.log(`✗ ${name}\n  got  ${g}\n  want ${w}`); }
  else { passes++; console.log(`✓ ${name}`); }
}
const shape = (n) => ({ tag: n.tagName, text: n.textContent, cls: n.attrs["class"] ?? null, kids: n.childNodes.map(shape) });

apply(frame(C("0", "", 0, "div"), C("0/0", "0", 0, "span"), T("0/0", "hi")));
const first = mount.childNodes[0];
check("a frame builds the tree", shape(first), { tag: "div", text: "", cls: null, kids: [{ tag: "span", text: "hi", cls: null, kids: [] }] });

apply(frame(C("0", "", 0, "div"), A("0", "fill-surface-sunk"), C("0/0", "0", 0, "span"), T("0/0", "bye")));
check("a second frame REUSES the element (identity survives)", mount.childNodes[0] === first, true);
check("and updates in place", shape(first), { tag: "div", text: "", cls: "fill-surface-sunk", kids: [{ tag: "span", text: "bye", cls: null, kids: [] }] });

apply(frame(C("0", "", 0, "div"), C("0/0", "0", 0, "span"), T("0/0", "hello world")));
check("a value keeps its spaces (length-prefixed, never escaped)", shape(first).kids[0].text, "hello world");

apply(frame(C("0", "", 0, "div"), C("0/0", "0", 0, "span"), T("0/0", "b"), C("0/1", "0", 1, "span"), T("0/1", "a")));
check("children follow the frame's index", shape(first).kids.map((k) => k.text), ["b", "a"]);

apply(frame(C("0", "", 0, "div"), C("0/0", "0", 0, "span"), T("0/0", "b")));
check("a dropped child leaves", shape(first).kids.length, 1);

apply(frame(C("0", "", 0, "ul"), C("0/k1:a", "0", 0, "li"), T("0/k1:a", "A"), C("0/k1:b", "0", 1, "li"), T("0/k1:b", "B")));
const li = mount.childNodes[0];
const bEl = li.childNodes[1];
check("a keyed list builds in order", shape(li).kids.map((k) => k.text), ["A", "B"]);

apply(frame(C("0", "", 0, "ul"), C("0/k1:b", "0", 0, "li"), T("0/k1:b", "B"), C("0/k1:a", "0", 1, "li"), T("0/k1:a", "A")));
check("a reorder moves the element itself, not its text", li.childNodes[0] === bEl, true);
check("and the order follows the frame", li.childNodes.map((k) => k.__avra_id), ["0/k1:b", "0/k1:a"]);

apply(frame());
check("an empty frame empties the mount", mount.childNodes.length, 0);

apply(frame(C("0", "", 0, "div"), C("0/0", "0", 0, "span"), T("0/0", "hi")));
const kept = mount.childNodes[0];
apply(Uint8Array.from([7, 0]));
check("a no-change frame touches nothing", mount.childNodes[0] === kept && kept.childNodes[0].textContent === "hi", true);

const styleEl = { textContent: "" };
const styled = createApplier(doc, el(doc, "root2"), () => {}, styleEl);
styled(frame(S("a{color:red}"), C("0", "", 0, "div")));
check("a stylesheet op fills the style element", styleEl.textContent, "a{color:red}");

let refused = false;
try { parseFrame(Uint8Array.from([5])); } catch { refused = true; }
check("a frame of another VERSION refuses", refused, true);

check("an id holding more than one octet a letter reads whole", parseFrame(frame(C("0/k2:é", "", 0, "div")))[0].id, "0/k2:é");

// ── events: the frame names who listens, the applier echoes who spoke ──
const ev = parseFrame(frame(C("0", "", 0, "button"), E("0", 1)));
check("an event record names its kind and what it says", ev[0].events, [[1, 0]]);

const sent = [];
const root3 = el(doc, "root3");
const app = createApplier(doc, root3, (who, kind, said) => sent.push([who, kind, said]));
app(frame(C("0", "", 0, "div"), C("0/k1:b", "0", 0, "button"), E("0/k1:b", 1)));
const pressed = root3.childNodes[0].childNodes[0];
pressed.listeners.get("click")();
check("a click echoes its node and kind, saying nothing", sent[0], ["0/k1:b", 1, null]);

// A keyed node keeps its id, its element and its listener when a sibling
// lands above it.
app(frame(C("0", "", 0, "div"), C("0/0", "0", 0, "span"), C("0/k1:b", "0", 1, "button"), E("0/k1:b", 1)));
check("a node a sibling lands above keeps its element", root3.childNodes[0].childNodes[1] === pressed, true);
root3.childNodes[0].childNodes[1].listeners.get("click")();
check("and speaks under the same id", sent[1], ["0/k1:b", 1, null]);

app(frame(C("0", "", 0, "div"), C("0/0", "0", 0, "span"), C("0/k1:b", "0", 1, "button")));
check("an event the frame drops is unsubscribed", root3.childNodes[0].childNodes[1].listeners.has("click"), false);

// A CONTROL SAYS WHAT THE FRAME ASKED OF IT: text, a flag or a number, read
// off the control itself.
const typed = [];
const root5 = el(doc, "root5");
const app5 = createApplier(doc, root5, (who, kind, said) => typed.push([who, kind, said]));
app5(frame(C("0", "", 0, "input"), T("0", "Name"), P("0", "type", "text"), E("0", 2, 3)));
const labelled = root5.childNodes[0];
const control = labelled.childNodes[0];
check("a control is a label around it, its words beside it", [labelled.tagName, control.tagName, labelled.childNodes[1].textContent], ["label", "input", "Name"]);
check("its attributes land on the control", control.attrs.type, "text");
control.value = "typed here";
control.listeners.get("input")();
check("an event that says text sends the control's own text", typed[0], ["0", 2, { tag: "text", value: "typed here" }]);

app5(frame(C("0", "", 0, "input"), P("0", "type", "checkbox"), E("0", 3, 2)));
control.checked = true;
control.listeners.get("change")();
check("an event that says a flag sends the control's own state", typed[1], ["0", 3, { tag: "flag", value: true }]);

app5(frame(C("0", "", 0, "input"), P("0", "type", "range"), E("0", 3, 1)));
control.value = "42";
control.listeners.get("change")();
check("an event that now says a number is heard anew, and sends it", typed[2], ["0", 3, { tag: "number", value: 42 }]);
control.value = "not a number";
control.listeners.get("change")();
check("a control that cannot say a number says nothing", typed[3], ["0", 3, null]);

app5(frame(C("0", "", 0, "input"), P("0", "type", "range"), E("0", 3, 0)));
control.listeners.get("change")();
check("an event that says nothing sends nothing", typed[4], ["0", 3, null]);

// A submit's own navigation is stopped: the program draws the page.
const root7 = el(doc, "root7");
const submits = [];
const app7 = createApplier(doc, root7, (who, kind, said) => submits.push([who, kind, said]));
app7(frame(C("0", "", 0, "form"), E("0", 4)));
let prevented = 0;
root7.childNodes[0].listeners.get("submit")({ preventDefault: () => { prevented++; } });
check("a submit is echoed and its navigation prevented", [submits[0], prevented], [["0", 4, null], 1]);
let clickPrevented = 0;
app7(frame(C("0", "", 0, "button"), E("0", 1)));
root7.childNodes[0].listeners.get("click")({ preventDefault: () => { clickPrevented++; } });
check("a click keeps its own default", clickPrevented, 0);

// A checkbox's state is a property the user moves; a frame that leaves the
// attribute out clears both.
const root6 = el(doc, "root6");
const app6 = createApplier(doc, root6);
app6(frame(C("0", "", 0, "input"), P("0", "type", "checkbox"), P("0", "checked", "")));
const box = root6.childNodes[0].childNodes[0];
check("a checked attribute sets the property", [box.checked, "checked" in box.attrs], [true, true]);
app6(frame(C("0", "", 0, "input"), P("0", "type", "checkbox")));
check("an attribute the frame drops is removed", [box.checked, "checked" in box.attrs], [false, false]);

const calls = [];
const fakeMod = {
  memory: { buffer: new ArrayBuffer(64) },
  avra_id_seat: () => 16n,
  avra_payload_seat: () => 32n,
  avra_seat_room: () => 8n,
  avra_event: (who, what, tag, num, len) => calls.push([who, what, tag, num, len]),
};
const seat = (at, len) => new TextDecoder().decode(new Uint8Array(fakeMod.memory.buffer, at, len));
sendEvent(fakeMod, "0/k1:a", 1, null);
check("the id is written into the program's id seat", seat(16, 6), "0/k1:a");
check("no payload sends the id's length and tag 0", calls[0].map(String), ["6", "1", "0", "0", "0"]);
sendEvent(fakeMod, "0", 1, { tag: "number", value: 42 });
check("a number sends its value", calls[1].map(String), ["1", "1", "1", "42", "0"]);
sendEvent(fakeMod, "0", 1, { tag: "text", value: "hi" });
check("text is written into the program's payload seat", seat(32, 2), "hi");
check("text sends its length", calls[2].map(String), ["1", "1", "3", "0", "2"]);
sendEvent(fakeMod, "0", 3, { tag: "flag", value: true });
check("a flag sends one", calls[3].map(String), ["1", "3", "2", "1", "0"]);

let outgrew = "";
try { sendEvent(fakeMod, "0", 2, { tag: "text", value: "nine long" }); } catch (e) { outgrew = e.message; }
check("a text that outgrows the seat refuses, writing nothing", [outgrew, calls.length], ["an event's text is 9 octets — the program's seat holds 8", 4]);
outgrew = "";
try { sendEvent(fakeMod, "0/1/2/3/4", 1, null); } catch (e) { outgrew = e.message; }
check("an id that outgrows the seat refuses", outgrew, "a node id is 9 octets — the program's seat holds 8");

// The same id naming another kind of element is a new element: a place
// whose node changed must not wear the old node's element.
const root4 = el(doc, "root4");
const app4 = createApplier(doc, root4);
app4(frame(C("0", "", 0, "div"), C("0/0", "0", 0, "ul"), C("0/1", "0", 1, "li")));
app4(frame(C("0", "", 0, "div"), C("0/0", "0", 0, "ul"), C("0/1", "0", 1, "p"), T("0/1", "footer")));
const changed = root4.childNodes[0].childNodes[1];
check("an id whose tag changed does not reuse the element", { tag: changed.tagName, text: changed.textContent }, { tag: "p", text: "footer" });

console.log(fails === 0 ? `bootstrap: ${passes}/${passes}` : `bootstrap: ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
