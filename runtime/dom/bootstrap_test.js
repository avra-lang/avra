// Proves the bootstrap's law over the V2 wire: a frame builds the tree, a
// second frame REUSES the live elements (identity survives), order follows
// the frame, keys move identity on a reorder, a dropped path leaves, a
// no-change frame touches nothing, and a frame of ANOTHER VERSION refuses.
import { createApplier, parseFrame } from "./bootstrap.js";

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
const V = "V2\n";

let fails = 0;
function check(name, got, want) {
  const g = JSON.stringify(got), w = JSON.stringify(want);
  if (g !== w) { fails++; console.log(`✗ ${name}\n  got  ${g}\n  want ${w}`); }
  else console.log(`✓ ${name}`);
}
const shape = (n) => ({ tag: n.tagName, text: n.textContent, key: n.attrs["data-key"] ?? null, kids: n.childNodes.map(shape) });

apply(V + "C 0 div\nC 0/0 span\nT 0/0 2\nhi\n");
const first = mount.childNodes[0];
check("a frame builds the tree", shape(first), { tag: "div", text: "", key: null, kids: [{ tag: "span", text: "hi", key: null, kids: [] }] });

apply(V + "C 0 div\nK 0 4\ncard\nC 0/0 span\nT 0/0 3\nbye\n");
check("a second frame REUSES the element (identity survives)", mount.childNodes[0] === first, true);
check("and updates in place", shape(first), { tag: "div", text: "", key: "card", kids: [{ tag: "span", text: "bye", key: null, kids: [] }] });

apply(V + "C 0 div\nC 0/0 span\nT 0/0 11\nhello world\n");
check("a value keeps its spaces (length-prefixed, never escaped)", shape(first).kids[0].text, "hello world");

apply(V + "C 0 div\nC 0/0 span\nT 0/0 1\nb\nC 0/1 span\nT 0/1 1\na\n");
check("children follow the frame's order", shape(first).kids.map((k) => k.text), ["b", "a"]);

apply(V + "C 0 div\nC 0/0 span\nT 0/0 1\nb\n");
check("a dropped child leaves", shape(first).kids.length, 1);

apply(V + "C 0 ul\nC 0/0 li\nK 0/0 1\na\nT 0/0 1\nA\nC 0/1 li\nK 0/1 1\nb\nT 0/1 1\nB\n");
const li = mount.childNodes[0];
const bEl = li.childNodes[1];
check("a keyed list builds in order", shape(li).kids.map((k) => k.text), ["A", "B"]);

apply(V + "C 0 ul\nC 0/0 li\nK 0/0 1\nb\nT 0/0 1\nB\nC 0/1 li\nK 0/1 1\na\nT 0/1 1\nA\n");
check("a KEYED reorder moves the element itself, not its text", li.childNodes[0] === bEl, true);
check("and the order follows the keys", shape(li).kids.map((k) => k.key), ["b", "a"]);

apply(V);
check("an empty frame empties the mount", mount.childNodes.length, 0);

apply(V + "C 0 div\nC 0/0 span\nT 0/0 2\nhi\n");
const kept = mount.childNodes[0];
apply(V + "N\n");
check("a no-change frame touches nothing", mount.childNodes[0] === kept && kept.childNodes[0].textContent === "hi", true);

let refused = false;
try { parseFrame("V1\nC 0 div\n"); } catch { refused = true; }
check("a frame of another VERSION refuses", refused, true);

console.log(fails === 0 ? "bootstrap: 10/10" : `bootstrap: ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
