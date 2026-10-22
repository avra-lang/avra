// THE SOLVER AGAINST THE WEB TARGET. Random trees over the layout vocabulary
// are placed twice: by `place` (std-ui/src/place) with a pixel measure over
// the theme's spacing, and by Firefox running the page the REAL html realizer
// writes for the same tree. Every box must agree; a mismatch is shrunk to a
// small tree and printed with both answers.
//
//   node tools/layout-oracle/oracle.mjs [--cases N] [--seed S] [--show K] [--width W]
//
// Leaves are empty boxes of a given size (or of none, which stretch or grow),
// or text of random words. The page is set in a font whose every character is
// one pixel wide and one high (cellfont.mjs), so a character is a cell and the
// browser's soft wrapping of the real <span> is comparable with the cell
// measure.
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { pathToFileURL } from "node:url";
import { firefoxBinary, openPage } from "../ui-board/firefox.mjs";
import { openPage as openWebkit, webkitLaunch } from "../ui-board/webkit.mjs";
import { cellFontBase64 } from "./cellfont.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const tree = path.resolve(here, "../..");
const args = Object.fromEntries(process.argv.slice(2).reduce((a, x, i, all) => (x.startsWith("--") ? [...a, [x.slice(2), all[i + 1]]] : a), []));
const CASES = Number(args.cases ?? 200);
const SEED = Number(args.seed ?? 1);
const SHOW = Number(args.show ?? 3);
const WIDTH = Number(args.width ?? 300);

// --face prop: text is laid in a PROPORTIONAL face whose advances are fractional
// pixels, summed in sixty-fourths by the solver and by the browser alike. The font
// is built here with 64 units to the em, so at a font size of one pixel a glyph's
// advance in font units is its advance in sixty-fourths of a pixel.
const PROP = args.face === "prop";

// The engine the boxes are read from: firefox (default) or webkit (Playwright's, PLAYWRIGHT_DIR).
const ENGINE = args.browser ?? "firefox";

// Each engine declares its own layout quantum, in parts to the pixel: Gecko lays a length out in
// 1/60, WebKit in 1/64 (its LayoutUnit). The solver keeps one exact unit, 1/60, and knows no engine
// (it cannot, short of sniffing which will paint); the QUANTUM is a parameter of this comparison,
// handed to the face under test (`Text.quantum`) and to the bound below.
const ENGINE_QUANTUM = { firefox: 60, webkit: 64 };
const Q = ENGINE_QUANTUM[ENGINE] ?? 60;
const SHARE = 60 / Q; // one engine quantum, in sixtieths of a pixel

// HOW A BROWSER'S BOX MAY STAND FROM OURS, judged BEFORE rounding, in sixtieths of a pixel. The page
// is read as it is laid out (fractional `getBoundingClientRect`) and each number of a box — left,
// top, width, height — may differ from the solver's by at most what its own derivation can add:
//   * a hugged text's WIDTH is the engine's measure of the run, one solver unit (1/60 px), per text;
//   * a SHARE of divided room — a grow or fill size, a SpaceBetween/Around/Evenly space, half the free
//     room under Center — is cut in the engine's quantum, so it costs one quantum (SHARE) each.
// A position adds the uncertainties of everything laid before it, a size those of what it holds or
// of the room it takes. The bound is computed PER BOX from the tree, printed beside every edge that
// stands past a plain unit, and anything beyond it fails: no flat number. A text's LINE COUNT is a
// count, exact. A whole-pixel tolerance would hide the very defect this oracle exists to find.
const UNIT = 1; // one solver unit, in sixtieths of a pixel
// The page's numbers are 32-bit floats: past a few hundred pixels one step is 0.002 sixtieths of a
// pixel. This is that resolution, rounded up, and never a tolerance on the layout.
const SLACK = 0.01;

const dirOf = (n) => n.layout.direction ?? (n.prim === "Row" ? "Row" : "Column");
const mainOf = (n) => (dirOf(n) === "Row" ? "width" : "height");
const fixedOn = (n, axis) => typeof n.layout[axis] === "object" && n.layout[axis].fixed !== undefined;
const fillOn = (n, axis) => n.layout[axis] === "Fill";
const sum = (xs) => xs.reduce((a, b) => a + b, 0);
/// A node's children in the order they are laid: `order`, then tree order.
const visual = (n) => n.kids.map((k, i) => [k, i]).sort((a, b) => (a[0].layout.order ?? 0) - (b[0].layout.order ?? 0) || a[1] - b[1]).map((x) => x[0]);

/// What a size can stand off by from its CONTENT alone: a hugged text's width is the engine's
/// measure (1 unit), a fixed size is exact, a container adds up (main axis) or takes the widest (cross).
const natural = (n, axis) => {
  if (fixedOn(n, axis)) return 0;
  if (n.prim === "Text") return axis === "width" ? UNIT : 0;
  if (n.kids.length === 0) return 0;
  const inside = n.kids.map((k) => natural(k, axis));
  return mainOf(n) === axis ? sum(inside) : Math.max(...inside);
};

/// Whether a size is cut from room it was GIVEN (a definite size, or a share of its parent's) rather
/// than from its content: only then can the engine divide that room among its children.
const roomOn = (n, axis, parent, parentRoom) => {
  if (fixedOn(n, axis)) return true;
  if (parent === null) return axis === "width";
  const main = mainOf(parent) === axis;
  const shared = fillOn(n, axis) || (main && (n.layout.grow ?? 0) > 0);
  if (shared) return parentRoom[axis];
  return !main && (parent.layout.align ?? "Stretch") === "Stretch" && parentRoom[axis];
};

/// A box's DEFINITE size on an axis in pixels, where its layout fixes it (a fixed size, or the root's
/// width, which the host decides); null where it is cut from content or room.
const definiteOn = (n, axis, parent) => (fixedOn(n, axis) ? n.layout[axis].fixed : parent === null && axis === "width" ? WIDTH : null);

const px = (name) => SPACE[name ?? "None"] ?? 0;
const edgeOf = (e, axis, end) => px(e?.[{ width: ["start", "end"], height: ["top", "bottom"] }[axis][end]]);

/// Whether a container's items can SHRINK along its main axis, read from the tree: false when its
/// room is not given or when every item is fixed and together they fit; true when they overflow; and
/// true (it may) where an item is cut from content, so the fit cannot be told from the tree.
function mayShrink(parent, parentDefinite, parentRoom) {
  const axis = mainOf(parent);
  if (!parentRoom[axis]) return false;
  if ((parent.layout.wrap ?? "NoWrap") !== "NoWrap") return true;
  const inner = parentDefinite[axis];
  if (inner === null || !parent.kids.every((k) => fixedOn(k, axis))) return true;
  const pad = edgeOf(parent.layout.pad, axis, 0) + edgeOf(parent.layout.pad, axis, 1);
  const gaps = px(parent.layout.gap) * Math.max(0, parent.kids.length - 1);
  const items = sum(parent.kids.map((k) => k.layout[axis].fixed + edgeOf(k.layout.margin, axis, 0) + edgeOf(k.layout.margin, axis, 1)));
  return items + gaps > inner - pad;
}

/// A size's uncertainty given its parent's. Along the main axis an item takes a SHARE of divided
/// room when it grows or fills, and when its container may shrink it; the engine cuts that share in
/// its quantum. A share carries the parent's uncertainty, its siblings' contents and one quantum. A
/// cross size that stretches or fills carries the parent's.
const sizeBound = (n, axis, parent, parentSize, parentRoom, shrinks) => {
  if (parent === null) return fixedOn(n, axis) || axis === "width" ? 0 : natural(n, axis);
  const main = mainOf(parent) === axis;
  const shares = main && (fillOn(n, axis) || (n.layout.grow ?? 0) > 0 || shrinks);
  if (shares) return parentSize + sum(parent.kids.filter((k) => k !== n).map((k) => natural(k, axis))) + SHARE;
  if (fixedOn(n, axis)) return 0;
  // a wrapped container shares the room its lines leave across them, so a stretched item is a share too
  const wrapped = (parent.layout.wrap ?? "NoWrap") !== "NoWrap" ? SHARE : 0;
  if (!main && (fillOn(n, axis) || (parent.layout.align ?? "Stretch") === "Stretch")) return Math.max(natural(n, axis), parentSize) + wrapped;
  return natural(n, axis);
};

/// Every box's bounds [left, top, width, height] in the page's pre-order, from the node's own `layout`.
// The share of a container's free room an item's offset carries, as `spanned` in place/solve.av
// computes it: the free room (`spare`) times the running sum of the distribution's space weights
// (`spaces_of`) up to the item, over their total. The room is the container's own size less its
// items, so the container's size bound enters at this share.
function spare_share(dist, i, n) {
  const weights = { Start: [], End: [1], Center: [1], SpaceBetween: n < 2 ? [] : [0, ...Array(n - 1).fill(1)], SpaceAround: [1, ...Array(n - 1).fill(2)], SpaceEvenly: Array(n + 1).fill(1) }[dist] ?? [];
  const full = { Start: 0, End: 1, Center: 2, SpaceBetween: Math.max(n - 1, 0), SpaceAround: 2 * n, SpaceEvenly: n + 1 }[dist] ?? 0;
  return full === 0 ? 0 : weights.slice(0, i + 1).reduce((a, b) => a + b, 0) / full;
}

function bounds_of(spec) {
  const out = [];
  const walk = (n, parent, parentPos, parentSize, parentRoom, parentDefinite, before) => {
    const shrinks = parent !== null && mayShrink(parent, parentDefinite, parentRoom);
    const size = { width: sizeBound(n, "width", parent, parentSize?.width, parentRoom, shrinks), height: sizeBound(n, "height", parent, parentSize?.height, parentRoom, shrinks) };
    const room = { width: roomOn(n, "width", parent, parentRoom), height: roomOn(n, "height", parent, parentRoom) };
    const definite = { width: definiteOn(n, "width", parent), height: definiteOn(n, "height", parent) };
    const pos = { width: 0, height: 0 };
    if (parent !== null) {
      const main = mainOf(parent), cross = main === "width" ? "height" : "width";
      const index = before.length;
      const dist = parent.layout.distribute ?? "Start";
      const spaces = { SpaceBetween: index, SpaceAround: index + 1, SpaceEvenly: index + 1, Center: 1 }[dist] ?? 0;
      // the free room a distribution cuts is the container's room less EVERY item, so it carries
      // every item's uncertainty, wherever the item stands
      const everyone = dist === "Start" ? 0 : sum(parent.kids.map((k) => sizeBound(k, main, parent, parentSize[main], parentRoom, shrinks)));
      pos[main] = parentPos[main] + sum(before.map((k) => sizeBound(k, main, parent, parentSize[main], parentRoom, shrinks))) + spaces * SHARE + everyone + spare_share(dist, index, parent.kids.length) * parentSize[main];
      const align = parent.layout.align ?? "Stretch";
      // a wrapped container shares its spare cross room among its lines, at most one line per item before this one
      const wraps = (parent.layout.wrap ?? "NoWrap") !== "NoWrap";
      pos[cross] = parentPos[cross] + (align === "Center" ? parentSize[cross] + size[cross] + SHARE : align === "End" ? parentSize[cross] + size[cross] : 0) + (wraps ? sum(before.map((k) => sizeBound(k, cross, parent, parentSize[cross], parentRoom, shrinks))) + (before.length + 1) * SHARE : 0);
    }
    out.push({ left: pos.width, top: pos.height, width: size.width, height: size.height });
    const order = visual(n);
    for (const k of n.kids) walk(k, n, pos, size, room, definite, order.slice(0, order.indexOf(k)));
  };
  walk(spec, null, null, null, null, null, []);
  return out;
}

// THE BOUNDARY RULE. A box is also handed back snapped to whole pixels, each EDGE rounded halves up,
// and two numbers within their bound can round apart when a rounding boundary (k + 1/2 px) lies
// between them. The rounded boxes may differ by one pixel on an edge ONLY when that edge's fine
// value is within its bound of such a boundary; every such edge is named in the run. Anywhere else a
// rounded difference is a defect, because the fine numbers it comes from agreed.
const near_boundary = (sixtieths, bound) => {
  const r = (((sixtieths - 30) % 60) + 60) % 60;
  const reach = Math.max(UNIT, bound) + SLACK;
  return r <= reach || r >= 60 - reach;
};

/// A box is [left, top, width, height, lines, fx, fy, fw, fh]: the first four whole pixels, the
/// last four the fractional page numbers (browser) or sixtieths (solver). Returns whether the
/// browser's boxes stand within each box's bound, the edges worth naming, and the widest fine gap.
function judge(got, want, bound) {
  const notes = [];
  let gap = 0;
  if (got.length !== want.length) return { ok: false, notes, gap, why: ["a box count"] };
  let ok = true;
  const why = new Set();
  got.forEach((b, i) => {
    const w = want[i], u = bound[i];
    if (b[4] !== w[4]) { ok = false; why.add("a line count"); }
    const limits = [u.left, u.top, u.width, u.height];
    for (let q = 0; q < 4; q++) {
      const d = Math.abs(w[5 + q] - b[5 + q] * 60);
      gap = Math.max(gap, d);
      if (d > limits[q] + SLACK) { ok = false; why.add("a bound"); }
      else if (d > UNIT + SLACK) notes.push(`box ${i} ${["left", "top", "width", "height"][q]}: gap ${d.toFixed(3)}/60 px within its derived bound ${limits[q].toFixed(3)}/60 (engine quantum 1/${Q})`);
    }
    // each edge, solver sixtieths against the browser's whole pixel: left, right, top, bottom
    const edges = [[w[0], w[5], b[0], u.left], [w[0] + w[2], w[5] + w[7], b[0] + b[2], u.left + u.width], [w[1], w[6], b[1], u.top], [w[1] + w[3], w[6] + w[8], b[1] + b[3], u.top + u.height]];
    edges.forEach(([wholeSolver, fine, wholeBrowser, reach], e) => {
      if (wholeSolver === wholeBrowser) return;
      if (near_boundary(fine, reach)) notes.push(`box ${i} ${["left", "right", "top", "bottom"][e]}: fine ${fine}/60 px sits within its bound (${Math.max(UNIT, reach).toFixed(3)}/60) of a rounding boundary — solver rounds to ${wholeSolver}, browser to ${wholeBrowser}`);
      else { ok = false; why.add("a rounding"); }
    });
  });
  return { ok, notes, gap, why: [...why] };
}

const FACE_NAME = PROP ? "prop" : "cell";

/// The run's verdict, spoken once and exited on.
function refuse(said) {
  console.log(`layout-oracle: FAILED — ${said}`);
  process.exit(1);
}
const FACE = { units: 64, advances: { i: 96, m: 272, W: 320, " ": 128 }, fallback: 205 };
const LINE = 16;

// ── the trees ────────────────────────────────────────────────────

function prng(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const SIZES = ["None", "Xs", "S", "M", "L", "Xl"];
const ALIGNS = ["Start", "Center", "End", "Stretch"];
const DISTRIBUTES = ["Start", "Center", "End", "SpaceBetween", "SpaceAround", "SpaceEvenly"];
const WRAPS = ["NoWrap", "Wrap", "WrapReverse"];

function words(rand) {
  const n = 1 + Math.floor(rand() * 6);
  if (PROP) return Array.from({ length: n }, () => Array.from({ length: 1 + Math.floor(rand() * 9) }, () => "imWxa"[Math.floor(rand() * 5)]).join("")).join(" ");
  return Array.from({ length: n }, () => "abcdefghijklmnopqrstuvwxyz".slice(0, 1 + Math.floor(rand() * 9))).join(" ");
}

function generate(rand, depth) {
  const pick = (xs) => xs[Math.floor(rand() * xs.length)];
  const chance = (p) => rand() < p;
  const between = (lo, hi) => lo + Math.floor(rand() * (hi - lo + 1));
  const edge = () => ({ start: pick(SIZES), end: pick(SIZES), top: pick(SIZES), bottom: pick(SIZES) });
  const layout = {};
  const leaf = depth === 0 || chance(0.35);
  if (chance(0.3)) layout.margin = edge();
  if (chance(0.2)) layout.grow = between(1, 3);
  if (chance(0.1)) layout.order = between(-2, 3);
  if (leaf) {
    if (chance(0.3)) {
      if (chance(0.3)) layout.width = { fixed: between(2, 40) };
      return { prim: "Text", text: words(rand), layout, kids: [] };
    }
    if (chance(0.85)) layout.width = { fixed: between(4, 70) };
    else if (chance(0.5)) layout.width = "Fill";
    if (chance(0.85)) layout.height = { fixed: between(2, 30) };
    else if (chance(0.5)) layout.height = "Fill";
    return { prim: "Leaf", layout, kids: [] };
  }
  if (chance(0.3)) layout.pad = edge();
  if (chance(0.5)) layout.gap = pick(SIZES);
  if (chance(0.4)) layout.align = pick(ALIGNS);
  if (chance(0.4)) layout.distribute = pick(DISTRIBUTES);
  if (chance(0.3)) layout.wrap = pick(WRAPS);
  if (chance(0.15)) layout.direction = pick(["Row", "Column"]);
  if (chance(0.15)) layout.width = "Fill";
  else if (chance(0.1)) layout.width = { fixed: between(40, 200) };
  if (chance(0.1)) layout.height = { fixed: between(20, 120) };
  const kids = Array.from({ length: between(1, 5) }, () => generate(rand, depth - 1));
  return { prim: pick(["Row", "Column"]), layout, kids };
}

// A page's root has no parent to space it, order it or share room with it.
function rooted(spec) {
  if (spec.prim === "Text") return { prim: "Column", layout: {}, kids: [spec] };
  const { margin, order, grow, ...layout } = spec.layout;
  return { ...spec, layout };
}

// The tree that showed a fixed size squeezed by a fill beside it: a row of a
// fixed box and a fill, a gap and a pad round them.
const leaf = (layout) => ({ prim: "Leaf", layout, kids: [] });
const text = (words, layout = {}) => ({ prim: "Text", text: words, layout, kids: [] });
const FIXED_CASES = [
  // a word wider than its box is cut where it must, and no further: a text
  // held by a fixed width, a fixed column holding one, and a row that cannot
  // give a word the room it asks for
  { prim: "Column", layout: { width: { fixed: 5 } }, kids: [text("abcdefghij klm")] },
  { prim: "Column", layout: {}, kids: [text("abcdefghij klm", { width: { fixed: 3 } })] },
  { prim: "Row", layout: { width: { fixed: 10 } }, kids: [text("abcdefgh"), text("ijklmnop")] },
  { prim: "Row", layout: { gap: "Xs", width: { fixed: 12 } }, kids: [text("abc defghijkl"), leaf({ width: { fixed: 6 }, height: { fixed: 2 } })] },
  { prim: "Row", layout: { gap: "Xs", pad: { start: "Xs", end: "Xs", top: "None", bottom: "None" }, width: { fixed: 60 } }, kids: [leaf({ width: { fixed: 10 }, height: { fixed: 3 } }), leaf({ width: "Fill", height: { fixed: 3 } })] },
];

// A twenty-glyph word of 205/64 pixels each is 64.06 pixels: it wraps in 64, where
// whole-pixel advances (3 each) would not. Rows of fractional advances that land on
// the edge pin where the browser breaks.
const PROP_CASES = [
  { prim: "Row", layout: { width: { fixed: 64 } }, kids: [text("xxxxxxxxxxxxxxxxxxxx")] },
  { prim: "Row", layout: { width: { fixed: 64 } }, kids: [text("xxxxxxxxxx xxxxxxxxxx")] },
  { prim: "Row", layout: { width: { fixed: 8 } }, kids: [text("ii ii")] },
  { prim: "Row", layout: { width: { fixed: 7 } }, kids: [text("ii ii")] },
  { prim: "Row", layout: { width: { fixed: 40 } }, kids: [text("mmm WWW iii xxx mmm WWW iii xxx")] },
  { prim: "Row", layout: { width: { fixed: 61 } }, kids: [text("xxxxxxxxxxxxxxxxxxx")] },
];

// ── the solver's side and the page ───────────────────────────────

const sizing = (s) => (s === "Fill" ? ".Fill" : `.Fixed(${s.fixed})`);
const edgeSrc = (e) => `Edge { start: .${e.start}, end: .${e.end}, top: .${e.top}, bottom: .${e.bottom} }`;

function layoutSrc(l) {
  const fields = [];
  if (l.direction) fields.push(`direction: .${l.direction}`);
  if (l.wrap) fields.push(`wrap: .${l.wrap}`);
  if (l.gap) fields.push(`gap: .${l.gap}`);
  if (l.pad) fields.push(`pad: ${edgeSrc(l.pad)}`);
  if (l.margin) fields.push(`margin: ${edgeSrc(l.margin)}`);
  if (l.align) fields.push(`align: .${l.align}`);
  if (l.distribute) fields.push(`distribute: .${l.distribute}`);
  if (l.width) fields.push(`width: ${sizing(l.width)}`);
  if (l.height) fields.push(`height: ${sizing(l.height)}`);
  if (l.grow) fields.push(`grow: ${l.grow}`);
  if (l.order) fields.push(`order: ${l.order}`);
  return `Layout { ${fields.join(", ")} }`;
}

function nodeSrc(n) {
  if (n.prim === "Text") return `placed(text_node("${n.text}"), ${layoutSrc(n.layout)})`;
  const prim = n.prim === "Leaf" ? "Column" : n.prim;
  return `boxed(.${prim}, ${layoutSrc(n.layout)}, [${n.kids.map(nodeSrc).join(", ")}])`;
}

function program(cases) {
  const defs = cases.map((c, i) => `fn case_${i}() -> Node { ${nodeSrc(c)} }`).join("\n");
  const runs = cases.map((_, i) => `show(${i}, case_${i}())`).join("\n");
  return `use @std.ui.tree.node.{Node}
use @std.ui.env.{Env}
use @std.ui.style.layout.{Layout, Edge}
use @std.ui.style.tokens.{Size}
use @std.ui.style.theme.{Theme}
use @std.ui.place.measure.{Measure, Extent, Cells, fine}
use @std.ui.place.metrics.{Table, run_width_in}
use @std.ui.place.lines.{lines_in}
use @std.ui.place.text.{Text}
use @std.ui.place.solve.{place_fine, whole, Placed}
use @std.ui.realize.tui.layout.{own_lines}
use @std.ui.realize.html.html.{render}
use @std.ui.realize.tests.support.{boxed, placed, text_node}

/// The target's measure, wrapped to COUNT: the solver's own line structure for a text is what its
/// own lines_in answers at the width the solver hands it, so the count is read, never inferred
/// from a height. kept is handed the solver's path for the node whose content is measured next.
type Counting = { inner: dyn Measure, seen: Cell<Map<string, int>>, at: Cell<string> }

impl Measure for Counting {
    fn own(n: Node, avail: int) -> Extent {
        if n.prim is .Text { self.seen.put(self.at.get(), count_lines(n, avail)) }
        self.inner.own(n, avail)
    }
    fn kept(n: Node, path: string) -> int {
        self.at.set(path)
        self.inner.kept(n, path)
    }
    fn hidden(n: Node) -> bool { self.inner.hidden(n) }
    fn holds(n: Node) -> bool { self.inner.holds(n) }
    fn min_own(n: Node) -> int { self.inner.min_own(n) }
    fn gap_x(z: Size) -> int { self.inner.gap_x(z) }
    fn gap_y(z: Size) -> int { self.inner.gap_y(z) }
    fn pad_x(z: Size) -> int { self.inner.pad_x(z) }
    fn pad_y(z: Size) -> int { self.inner.pad_y(z) }
}

type Pixels = { theme: Theme }

impl Measure for Pixels {
    fn own(n: Node, avail: int) -> Extent { Cells {}.own(n, avail) }
    fn kept(_n: Node, _path: string) -> int { 0 }
    fn hidden(_n: Node) -> bool { false }
    fn holds(_n: Node) -> bool { true }
    fn min_own(n: Node) -> int { Cells {}.min_own(n) }
    fn gap_x(z: Size) -> int { self.theme.space_of(z) }
    fn gap_y(z: Size) -> int { self.theme.space_of(z) }
    fn pad_x(z: Size) -> int { self.theme.space_of(z) }
    fn pad_y(z: Size) -> int { self.theme.space_of(z) }
}

${PROP ? `fn face_metrics() -> Table {
    Table { advances: { ${Object.entries(FACE.advances).map(([c, u]) => `"${c}": ${u}`).join(", ")} }, fallback: ${FACE.fallback}, up: ${LINE * 48}, down: ${LINE * 16} }
}

fn typeface() -> Text { Text { metrics: face_metrics(), theme: Env {}.theme, rest: Cells {}, quantum: ${Q} } }

fn count_lines(n: Node, avail: int) -> int {
    lines_in(n.words(), (avail * ${Q} + fine / 2) / fine, (s: string) -> run_width_in(face_metrics(), s, ${Q})).length
}
` : `fn count_lines(n: Node, avail: int) -> int { own_lines(n, avail / fine).length }
`}
fn rows_of(p: Placed) -> List<string> {
    ["\${p.rect.x} \${p.rect.y} \${p.rect.w} \${p.rect.h}"].concat([l for k in p.kids for l in rows_of(k)])
}

fn count_of(c: Counting, n: Node, path: string) -> int {
    when { n.prim is .Text -> c.seen.get().get(path) ?? 0, _ -> 0 }
}

fn counts(c: Counting, n: Node, path: string) -> List<int> {
    [count_of(c, n, path)].concat([v for i, k in n.children for v in counts(c, k, "\${path}.\${i}")])
}

fn show(i: int, n: Node) {
    let seen: Cell<Map<string, int>> = Cell.new({})
    let at: Cell<string> = Cell.new("")
    let c = Counting { inner: ${PROP ? "typeface()" : "Pixels { theme: Env {}.theme }"}, seen: seen, at: at }
    let fine_boxes = place_fine(n, c, ${WIDTH})
    println("case \${i}")
    for l in rows_of(whole(fine_boxes)) { println(l) }
    println("fine \${i}")
    for l in rows_of(fine_boxes) { println(l) }
    println("lines \${i}")
    println(["\${v}" for v in counts(c, n, "0")].join(" "))
    println("html \${i}")
    println(render(n, Env {}).replace("\\n", " "))
    println("end \${i}")
}
${["None", "Xs", "S", "M", "L", "Xl"].map((z) => `println("space ${z} \${Env {}.theme.space_of(.${z})}")`).join("\n")}
${defs}
${runs}
`;
}

function solved(cases, work) {
  fs.mkdirSync(path.join(work, "src"), { recursive: true });
  fs.writeFileSync(path.join(work, "avra.toml"), `[package]\nname = "layout-oracle"\nversion = "0.0.1"\n`);
  fs.writeFileSync(path.join(work, "src/main.av"), program(cases));
  const avra = process.env.AVRA ?? path.join(tree, "build/avra");
  // BUILT, then run natively: the evaluator walks 300 trees in two minutes where the program,
  // compiled, answers them in seconds (the two engines agree on every program the tree tests).
  const built = spawnSync(avra, ["build", work], { encoding: "utf8", maxBuffer: 1 << 28 });
  if (built.status !== 0) { console.error(built.stdout.slice(-2000), built.stderr.slice(-4000)); process.exit(2); }
  const ran = spawnSync(path.join(work, "src/main"), { encoding: "utf8", maxBuffer: 1 << 28 });
  if (ran.status !== 0) { console.error(ran.stdout.slice(-2000), ran.stderr.slice(-4000)); process.exit(2); }
  const out = [], pages = [], counts = [], fines = [];
  for (const l of ran.stdout.split("\n")) { const m = l.match(/^space (\w+) (-?\d+)$/); if (m) SPACE[m[1]] = Number(m[2]); }
  let reading = null;
  for (const l of ran.stdout.split("\n")) {
    if (l.startsWith("case ")) { out.push([]); reading = "rects"; }
    else if (l.startsWith("fine ")) { fines.push([]); reading = "fine"; }
    else if (l.startsWith("lines ")) reading = "lines";
    else if (l.startsWith("html ")) reading = "html";
    else if (l.startsWith("end ")) reading = null;
    else if (reading === "rects" && /^-?\d/.test(l)) out[out.length - 1].push(l.split(" ").map(Number));
    else if (reading === "fine" && /^-?\d/.test(l)) fines[fines.length - 1].push(l.split(" ").map(Number));
    else if (reading === "lines" && /^-?\d/.test(l)) counts.push(l.split(" ").map(Number));
    else if (reading === "html") pages.push(l);
  }
  // The solver's line count joins its box as the fifth number, read beside the browser's own, and its
  // fine rect (sixtieths, before any snapping) as the last four.
  out.forEach((boxes, i) => boxes.forEach((b, k) => b.push(counts[i]?.[k] ?? 0, ...(fines[i]?.[k] ?? [0, 0, 0, 0]))));
  return { out, pages };
}

// ── the browser's side ───────────────────────────────────────────

const PAGE = `<!doctype html><meta charset=utf-8><style>@font-face{font-family:cell;src:url(data:font/ttf;base64,${cellFontBase64(PROP ? FACE : {})})}body{margin:0;font:1px/${PROP ? LINE : 1}px cell${PROP ? ";font-kerning:none;font-variant-ligatures:none" : ""}}</style><body></body>`;

// The page the realizer wrote is laid in a host WIDTH wide. Each box is read
// as the browser paints it: its edges, from the root's corner, snapped to the
// nearest whole unit, halves up — the law the solver hands its boxes back by.
// Each box is [left, top, width, height, lines]: the last is the element's OWN line count, read from
// its text's line boxes — never its height divided by a line height. An element holding text counts
// the lines that text is painted on; every other element counts zero.
const BROWSER = `(html, widthPx) => {
  const host = document.createElement("div");
  host.style.cssText = "position:absolute;left:0;top:0;width:" + widthPx + "px";
  document.body.appendChild(host);
  host.innerHTML = "<style>:root{--face-body:cell !important}</style>" + html;
  const root = host.lastElementChild;
  const origin = root.getBoundingClientRect();
  const out = [];
  const lineCount = (el) => {
    const node = el.firstChild;
    if (!node || node.nodeType !== 3 || el.children.length > 0) return 0;
    const range = document.createRange();
    let lines = 0, last = -1e9;
    for (let i = 0; i < node.textContent.length; i++) {
      range.setStart(node, i); range.setEnd(node, i + 1);
      const rect = range.getClientRects()[0];
      if (!rect) continue;
      if (rect.top - last > 0.5) { lines++; last = rect.top; }
    }
    return lines;
  };
  const walk = (el) => {
    const r = el.getBoundingClientRect();
    const l = Math.round(r.x - origin.x), t = Math.round(r.y - origin.y);
    out.push([l, t, Math.round(r.x + r.width - origin.x) - l, Math.round(r.y + r.height - origin.y) - t, lineCount(el), r.x - origin.x, r.y - origin.y, r.width, r.height]);
    for (const k of el.children) walk(k);
  };
  walk(root);
  document.body.removeChild(host);
  return out;
}`;

/// What a run saw beyond agree/disagree: every boundary edge, and the widest fine gap.
const SEEN = { boundary: [], gap: 0, why: {} };

/// Where a run's time goes, in milliseconds: the solver's program (compile and run), the page, and
/// the work shrinking a failure took. Printed at the end of every run.
/// The theme's spacing steps in pixels, as the solver's program reads them.
const SPACE = {};
const SPENT = { solver: 0, page: 0, calls: 0, trees: 0 };
const timed = async (key, f) => { const t = Date.now(); try { return await f(); } finally { SPENT[key] += Date.now() - t; } };

async function compare(cases, browser, work, note = false) {
  const { out, pages } = await timed("solver", async () => solved(cases, work));
  SPENT.calls += 1;
  SPENT.trees += cases.length;
  const results = [];
  // ONE round trip for every tree of this call: the page lays each out in turn and answers them all.
  const read = await timed("page", () => browser.read(`((pages, w) => pages.map((html) => (${BROWSER})(html, w)))(${JSON.stringify(pages)}, ${WIDTH})`));
  for (let i = 0; i < cases.length; i++) {
    const got = read[i];
    const verdict = judge(got, out[i], bounds_of(cases[i]));
    if (note) {
      SEEN.gap = Math.max(SEEN.gap, verdict.gap);
      for (const n of verdict.notes) SEEN.boundary.push(`case ${i}: ${n}`);
    }
    if (note && !verdict.ok) for (const w of verdict.why) SEEN.why[w] = (SEEN.why[w] ?? 0) + 1;
    results.push(verdict.ok ? null : { got, want: out[i] });
  }
  return results;
}

// Every tree one step smaller: a child dropped, a subtree made a leaf, a
// property dropped.
function reductions(n) {
  const out = [];
  n.kids.forEach((k, i) => {
    out.push({ ...n, kids: n.kids.filter((_, j) => j !== i) });
    for (const r of reductions(k)) out.push({ ...n, kids: n.kids.map((x, j) => (j === i ? r : x)) });
    if (k.kids.length > 0) out.push({ ...n, kids: n.kids.map((x, j) => (j === i ? { prim: "Leaf", layout: x.layout, kids: [] } : x)) });
  });
  for (const key of Object.keys(n.layout)) {
    const layout = { ...n.layout };
    delete layout[key];
    out.push({ ...n, layout });
  }
  return out;
}

async function shrunk(spec, browser, work) {
  let cur = spec;
  for (let round = 0; round < 30; round++) {
    const candidates = reductions(cur);
    if (candidates.length === 0) break;
    const verdicts = await compare(candidates, browser, work);
    const at = verdicts.findIndex((v) => v !== null);
    if (at < 0) break;
    cur = candidates[at];
  }
  return cur;
}

// The page in the engine asked for. A machine without it FAILS (a run that compared nothing is no pass)
// unless `--skip-if-absent` stands it down aloud.
async function opened(url) {
  const absent = (why) => {
    const skipped = process.argv.includes("--skip-if-absent");
    console.log(`layout-oracle: ran 0 trees — ${skipped ? "SKIPPED" : "FAILED"}: ${why}`);
    process.exit(skipped ? 0 : 1);
  };
  if (ENGINE === "firefox") {
    const binary = firefoxBinary();
    if (!binary) absent("no Firefox on this machine (FIREFOX names one)");
    return openPage(binary, url, { width: 1200, height: 900 });
  }
  if (ENGINE !== "webkit") absent(`no engine called ${ENGINE} (firefox or webkit)`);
  const dir = process.env.PLAYWRIGHT_DIR ?? ".";
  const loaded = await import(pathToFileURL(path.join(dir, "node_modules/playwright/index.mjs")).href).catch((e) => ({ said: String(e.message).split("\n")[0] }));
  const { browser, said } = loaded.webkit ? await webkitLaunch(loaded) : { said: loaded.said };
  if (!browser) absent(`WebKit could not launch — ${said}`);
  return openWebkit(browser, url, { width: 1200, height: 900 });
}

/// A tree's two answers, box by box: the solver's, the browser's, and a mark on every box that
/// disagrees under the fine law.
async function printed(label, spec, v) {
  console.log(`${label}\n${JSON.stringify(spec)}`);
  const bounds = bounds_of(spec);
  for (let k = 0; k < Math.max(v.got.length, v.want.length); k++) {
    const px = (x) => (x / 60).toFixed(3);
    const solver = (b) => `[${b.slice(0, 4).join(",")}] lines ${b[4]} fine ${b.slice(5).map(px).join(" ")}`;
    const browser = (b) => `[${b.slice(0, 4).join(",")}] lines ${b[4]} fine ${b.slice(5).map((x) => x.toFixed(3)).join(" ")}`;
    const holds = v.want[k] && v.got[k] && judge([v.got[k]], [v.want[k]], [bounds[k]]).ok;
    const u = bounds[k];
    const limit = u ? ` bound ${[u.left, u.top, u.width, u.height].map((x) => x.toFixed(2)).join(" ")}` : "";
    console.log(`  box ${k}: solver ${solver(v.want[k])}  browser ${browser(v.got[k])}${limit}${holds ? "" : "   <--"}`);
  }
}

/// The tree at `i`, shrunk to the smallest one that still disagrees.
async function small_enough(cases, i, browser, work) {
  // `--no-shrink` prints the tree as generated: shrinking rebuilds the solver's program every round.
  const small = process.argv.includes("--no-shrink") ? cases[i] : await shrunk(cases[i], browser, work);
  const [v] = await compare([small], browser, work);
  return { small, v };
}

async function main() {
  const rand = prng(SEED);
  const cases = args.tree ? [JSON.parse(args.tree)] : (PROP ? PROP_CASES : FIXED_CASES).concat(Array.from({ length: CASES }, () => rooted(generate(rand, 3))));
  // The solver's program lives in one directory per face, so the compiler's store (the std-ui it
  // analyses) is warm from the second run on instead of cold in a fresh temp directory every time.
  const work = path.join(tree, "build", "layout-oracle", FACE_NAME);
  const page = fs.mkdtempSync(path.join(os.tmpdir(), "avra-layout-page-"));
  fs.writeFileSync(path.join(page, "index.html"), PAGE);
  const browser = await opened("file://" + path.join(page, "index.html"));
  await browser.read('document.fonts.load("1px cell").then((faces) => faces.length)');
  const verdicts = await compare(cases, browser, work, true);
  const failing = verdicts.map((v, i) => (v ? i : -1)).filter((i) => i >= 0);
  if (cases.length === 0) { console.log("layout-oracle: ran 0 trees — FAILED: no tree was compared"); process.exit(1); }
  for (const i of failing.slice(0, SHOW)) {
    const { small, v } = await small_enough(cases, i, browser, work);
    await printed(`MISMATCH case ${i} (seed ${SEED}), shrunk:`, small, v);
  }
  await browser.close();
  for (const n of SEEN.boundary) console.log(`${/ gap /.test(n) ? "BOUND" : "BOUNDARY"} ${FACE_NAME} seed ${SEED} ${n}`);
  console.log(`layout-oracle: time ${((SPENT.solver + SPENT.page) / 1000).toFixed(1)}s = solver ${(SPENT.solver / 1000).toFixed(1)}s + page ${(SPENT.page / 1000).toFixed(1)}s, over ${SPENT.calls} compare call(s) and ${SPENT.trees} tree(s)`);
  if (Object.keys(SEEN.why).length) console.log(`layout-oracle: trees refused for — ${Object.entries(SEEN.why).map(([w, n]) => `${w}: ${n}`).join(", ")}`);
  console.log(`layout-oracle: widest fine gap ${SEEN.gap.toFixed(3)}/60 px (law: ${UNIT}/60); ${SEEN.boundary.filter((n) => / gap /.test(n)).length} number(s) past a unit within a derived bound, ${SEEN.boundary.filter((n) => !/ gap /.test(n)).length} edge(s) rounded apart at a boundary`);
  console.log(`layout-oracle: ${cases.length - failing.length} of ${cases.length} trees agree in ${ENGINE} (seed ${SEED}, width ${WIDTH})`);
  process.exit(failing.length === 0 ? 0 : 1);
}

main().catch((e) => { console.error(e); process.exit(2); });
