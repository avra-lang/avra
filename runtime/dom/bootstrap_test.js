// Proves the bootstrap's law: a frame builds the tree, a second frame
// REUSES the live elements (identity survives), order follows the frame,
// and a path the frame drops leaves. Node's stub document stands in for a
// browser; the applier takes whatever document it is handed.
import { createApplier } from "./bootstrap.js";

function el(doc, tag) {
  return {
    tagName: tag,
    childNodes: [],
    attrs: {},
    textContent: "",
    parentNode: null,
    setAttribute(k, v) { this.attrs[k] = v; },
    appendChild(c) { c.parentNode = this; this.childNodes.push(c); },
    insertBefore(c, at) {
      if (c.parentNode) c.parentNode.removeChild(c);
      const i = at ? this.childNodes.indexOf(at) : this.childNodes.length;
      this.childNodes.splice(i < 0 ? this.childNodes.length : i, 0, c);
      c.parentNode = this;
    },
    removeChild(c) {
      const i = this.childNodes.indexOf(c);
      if (i >= 0) this.childNodes.splice(i, 1);
      c.parentNode = null;
    },
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
const shape = (n) => ({ tag: n.tagName, text: n.textContent, key: n.attrs["data-key"] ?? null, kids: n.childNodes.map(shape) });

apply("C 0 div\nC 0/0 span\nT 0/0 hi");
const first = mount.childNodes[0];
check("a frame builds the tree", shape(first), { tag: "div", text: "", key: null, kids: [{ tag: "span", text: "hi", key: null, kids: [] }] });

apply("C 0 div\nK 0 card\nC 0/0 span\nT 0/0 bye");
check("a second frame REUSES the element (identity survives)", mount.childNodes[0] === first, true);
check("and updates in place", shape(first), { tag: "div", text: "", key: "card", kids: [{ tag: "span", text: "bye", key: null, kids: [] }] });

apply("C 0 div\nC 0/0 span\nT 0/0 b\nC 0/1 span\nT 0/1 a");
check("children follow the frame's order", shape(first).kids.map((k) => k.text), ["b", "a"]);

apply("C 0 div\nC 0/0 span\nT 0/0 b");
check("a dropped child leaves", shape(first).kids.length, 1);

apply("C 0 ul\nC 0/0 li\nK 0/0 a\nT 0/0 A\nC 0/1 li\nK 0/1 b\nT 0/1 B");
const li = mount.childNodes[0];
const bEl = li.childNodes[1];
check("a keyed list builds in order", shape(li).kids.map((k) => k.text), ["A", "B"]);

apply("C 0 ul\nC 0/0 li\nK 0/0 b\nT 0/0 B\nC 0/1 li\nK 0/1 a\nT 0/1 A");
check("a KEYED reorder moves the element itself, not its text", li.childNodes[0] === bEl, true);
check("and the order follows the keys", shape(li).kids.map((k) => k.key), ["b", "a"]);

apply("");
check("an empty frame empties the mount", mount.childNodes.length, 0);

console.log(fails === 0 ? "bootstrap: 7/7" : `bootstrap: ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
