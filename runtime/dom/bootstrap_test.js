// Proves the bootstrap's law over the V4 BYTE wire: a frame builds the tree,
// a second frame REUSES the elements, order follows the frame's index, keys
// move identity on a reorder, a dropped node leaves, a no-change frame
// touches nothing, and a frame of ANOTHER VERSION refuses.
import { createApplier, parseFrame, sendEvent } from "./bootstrap.js";

// A fixture encoder — the CONSUMING side is what is under test; the
// producing side's exact bytes are pinned by the Avra wire test.
const i32 = (v) => [v & 255, (v >>> 8) & 255, (v >>> 16) & 255, (v >>> 24) & 255];
const utf8 = (s) => [...new TextEncoder().encode(s)];
const C = (id, parent, index, tag) => [1, ...i32(id), ...i32(parent), ...i32(index), ...i32(tag.length), ...utf8(tag)];
const K = (id, s) => [2, ...i32(id), ...i32(s.length), ...utf8(s)];
const A = (id, s) => [3, ...i32(id), ...i32(s.length), ...utf8(s)];
const T = (id, s) => [4, ...i32(id), ...i32(s.length), ...utf8(s)];
const S = (s) => [6, ...i32(s.length), ...utf8(s)];
const E = (id, kind, site) => [5, ...i32(id), ...i32(kind), ...i32(site)];
const PText = (id, s) => [7, ...i32(id), 1, ...i32(s.length), ...utf8(s)];
const PInt = (id, v) => [7, ...i32(id), 2, ...i32(Number(v & 0xffffffffn)), ...i32(Number((v >> 32n) & 0xffffffffn))];
const PBool = (id, b) => [7, ...i32(id), 3, b ? 1 : 0];
const frame = (...recs) => Uint8Array.from([4, ...recs.flat()]);

function el(doc, tag) {
  return {
    tagName: tag, childNodes: [], attrs: {}, textContent: "", parentNode: null, listeners: new Map(),
    setAttribute(k, v) { this.attrs[k] = v; },
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
function check(name, got, want) {
  const g = JSON.stringify(got), w = JSON.stringify(want);
  if (g !== w) { fails++; console.log(`✗ ${name}\n  got  ${g}\n  want ${w}`); }
  else console.log(`✓ ${name}`);
}
const shape = (n) => ({ tag: n.tagName, text: n.textContent, key: n.attrs["data-key"] ?? null, cls: n.attrs["class"] ?? null, kids: n.childNodes.map(shape) });

apply(frame(C(0, -1, 0, "div"), C(1, 0, 0, "span"), T(1, "hi")));
const first = mount.childNodes[0];
check("a frame builds the tree", shape(first), { tag: "div", text: "", key: null, cls: null, kids: [{ tag: "span", text: "hi", key: null, cls: null, kids: [] }] });

apply(frame(C(0, -1, 0, "div"), K(0, "card"), A(0, "fill-surface-sunk"), C(1, 0, 0, "span"), T(1, "bye")));
check("a second frame REUSES the element (identity survives)", mount.childNodes[0] === first, true);
check("and updates in place", shape(first), { tag: "div", text: "", key: "card", cls: "fill-surface-sunk", kids: [{ tag: "span", text: "bye", key: null, cls: null, kids: [] }] });

apply(frame(C(0, -1, 0, "div"), C(1, 0, 0, "span"), T(1, "hello world")));
check("a value keeps its spaces (length-prefixed, never escaped)", shape(first).kids[0].text, "hello world");

apply(frame(C(0, -1, 0, "div"), C(1, 0, 0, "span"), T(1, "b"), C(2, 0, 1, "span"), T(2, "a")));
check("children follow the frame's index", shape(first).kids.map((k) => k.text), ["b", "a"]);

apply(frame(C(0, -1, 0, "div"), C(1, 0, 0, "span"), T(1, "b")));
check("a dropped child leaves", shape(first).kids.length, 1);

apply(frame(C(0, -1, 0, "ul"), C(1, 0, 0, "li"), K(1, "a"), T(1, "A"), C(2, 0, 1, "li"), K(2, "b"), T(2, "B")));
const li = mount.childNodes[0];
const bEl = li.childNodes[1];
check("a keyed list builds in order", shape(li).kids.map((k) => k.text), ["A", "B"]);

apply(frame(C(0, -1, 0, "ul"), C(1, 0, 0, "li"), K(1, "b"), T(1, "B"), C(2, 0, 1, "li"), K(2, "a"), T(2, "A")));
check("a KEYED reorder moves the element itself, not its text", li.childNodes[0] === bEl, true);
check("and the order follows the keys", shape(li).kids.map((k) => k.key), ["b", "a"]);

apply(frame());
check("an empty frame empties the mount", mount.childNodes.length, 0);

apply(frame(C(0, -1, 0, "div"), C(1, 0, 0, "span"), T(1, "hi")));
const kept = mount.childNodes[0];
apply(Uint8Array.from([4, 0]));
check("a no-change frame touches nothing", mount.childNodes[0] === kept && kept.childNodes[0].textContent === "hi", true);

const styleEl = { textContent: "" };
const styled = createApplier(doc, el(doc, "root2"), () => {}, styleEl);
styled(frame(S("a{color:red}"), C(0, -1, 0, "div")));
check("a stylesheet op fills the style element", styleEl.textContent, "a{color:red}");

let refused = false;
try { parseFrame(Uint8Array.from([2])); } catch { refused = true; }
check("a frame of another VERSION refuses", refused, true);

// ── the payload channel: op 7 decodes, the applier hands it to send, and
// sendEvent puts it on the ABI's tag/value seats ──
const ev = parseFrame(frame(C(0, -1, 0, "button"), E(0, 1, 1234), PText(0, "t3")));
check("a text payload decodes", ev[0].events[0].payload, { tag: "text", value: "t3" });
const evInt = parseFrame(frame(C(0, -1, 0, "button"), E(0, 1, 7), PInt(0, -5n))).pop().events[0].payload;
check("an int payload is exact", { tag: evInt.tag, value: String(evInt.value) }, { tag: "int", value: "-5" });
const evBool = parseFrame(frame(C(0, -1, 0, "button"), E(0, 1, 7), PBool(0, true))).pop().events[0].payload;
check("a bool payload decodes", evBool, { tag: "bool", value: true });

const sent = [];
const root3 = el(doc, "root3");
const app = createApplier(doc, root3, (site, kind, payload) => sent.push([site, kind, payload]));
app(frame(C(0, -1, 0, "button"), E(0, 1, 99), PText(0, "x")));
root3.childNodes[0].listeners.get("click")();
check("the applier hands its payload to send", sent[0], [99, 1, { tag: "text", value: "x" }]);

const calls = [];
const fakeMod = {
  memory: { buffer: new ArrayBuffer(64) },
  avra_payload_seat: () => 16n,
  avra_event: (site, what, tag, num, len) => calls.push([site, what, tag, num, len]),
};
sendEvent(fakeMod, 7, 1, null);
check("no payload sends tag 0", calls[0].map(String), ["7", "1", "0", "0", "0"]);
sendEvent(fakeMod, 7, 1, { tag: "int", value: 42n });
check("an int sends its value", calls[1].map(String), ["7", "1", "1", "42", "0"]);
sendEvent(fakeMod, 7, 1, { tag: "text", value: "hi" });
check("text is written into the program's seat", new TextDecoder().decode(new Uint8Array(fakeMod.memory.buffer, 16, 2)), "hi");
check("text sends its length", calls[2].map(String), ["7", "1", "3", "0", "2"]);

// A pre-order id shifts when the list above a node changes size: reuse must
// not wear an element of another tag, or a footer becomes the node it moved
// past. Without the tag guard this p is the old second li.
const root4 = el(doc, "root4");
const app4 = createApplier(doc, root4);
app4(frame(C(0, -1, 0, "div"), C(1, 0, 0, "ul"), C(2, 1, 0, "li"), C(3, 1, 1, "li"), C(4, 0, 1, "p"), T(4, "footer")));
app4(frame(C(0, -1, 0, "div"), C(1, 0, 0, "ul"), C(2, 1, 0, "li"), C(3, 0, 1, "p"), T(3, "footer")));
const shifted = root4.childNodes[0].childNodes[1];
check("a shifted id does not reuse another tag", { tag: shifted.tagName, text: shifted.textContent }, { tag: "p", text: "footer" });

console.log(fails === 0 ? "bootstrap: 22/22" : `bootstrap: ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
