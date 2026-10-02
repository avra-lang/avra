// Proves the bootstrap's law over the V3 BYTE wire: a frame builds the tree,
// a second frame REUSES the elements, order follows the frame's index, keys
// move identity on a reorder, a dropped node leaves, a no-change frame
// touches nothing, and a frame of ANOTHER VERSION refuses.
import { createApplier, parseFrame } from "./bootstrap.js";

// A fixture encoder — the CONSUMING side is what is under test; the
// producing side's exact bytes are pinned by the Avra wire test.
const i32 = (v) => [v & 255, (v >>> 8) & 255, (v >>> 16) & 255, (v >>> 24) & 255];
const utf8 = (s) => [...new TextEncoder().encode(s)];
const C = (id, parent, index, tag) => [1, ...i32(id), ...i32(parent), ...i32(index), ...i32(tag.length), ...utf8(tag)];
const K = (id, s) => [2, ...i32(id), ...i32(s.length), ...utf8(s)];
const A = (id, s) => [3, ...i32(id), ...i32(s.length), ...utf8(s)];
const T = (id, s) => [4, ...i32(id), ...i32(s.length), ...utf8(s)];
const S = (s) => [6, ...i32(s.length), ...utf8(s)];
const frame = (...recs) => Uint8Array.from([3, ...recs.flat()]);

function el(doc, tag) {
  return {
    tagName: tag, childNodes: [], attrs: {}, textContent: "", parentNode: null,
    setAttribute(k, v) { this.attrs[k] = v; },
    appendChild(c) { c.parentNode = this; this.childNodes.push(c); },
    insertBefore(c, at) {
      if (c.parentNode) c.parentNode.removeChild(c);
      const i = at ? this.childNodes.indexOf(at) : this.childNodes.length;
      this.childNodes.splice(i < 0 ? this.childNodes.length : i, 0, c);
      c.parentNode = this;
    },
    removeChild(c) { const i = this.childNodes.indexOf(c); if (i >= 0) this.childNodes.splice(i, 1); c.parentNode = null; },
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
apply(Uint8Array.from([3, 0]));
check("a no-change frame touches nothing", mount.childNodes[0] === kept && kept.childNodes[0].textContent === "hi", true);

const styleEl = { textContent: "" };
const styled = createApplier(doc, el(doc, "root2"), () => {}, styleEl);
styled(frame(S("a{color:red}"), C(0, -1, 0, "div")));
check("a stylesheet op fills the style element", styleEl.textContent, "a{color:red}");

let refused = false;
try { parseFrame(Uint8Array.from([2])); } catch { refused = true; }
check("a frame of another VERSION refuses", refused, true);

console.log(fails === 0 ? "bootstrap: 13/13" : `bootstrap: ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
