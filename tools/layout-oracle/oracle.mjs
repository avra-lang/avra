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
import { firefoxBinary, openPage } from "../ui-board/firefox.mjs";
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
use @std.ui.place.measure.{Measure, Extent, Cells}
use @std.ui.place.metrics.{Table}
use @std.ui.place.text.{Text}
use @std.ui.place.solve.{place, Placed}
use @std.ui.realize.html.html.{render}
use @std.ui.realize.tests.support.{boxed, placed, text_node}

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

${PROP ? `fn typeface() -> Text {
    Text {
        metrics: Table { advances: { ${Object.entries(FACE.advances).map(([c, u]) => `"${c}": ${u}`).join(", ")} }, fallback: ${FACE.fallback}, up: ${LINE * 48}, down: ${LINE * 16} },
        theme: Env {}.theme,
        rest: Cells {},
    }
}
` : ""}
fn rows_of(p: Placed) -> List<string> {
    ["\${p.rect.x} \${p.rect.y} \${p.rect.w} \${p.rect.h}"].concat([l for k in p.kids for l in rows_of(k)])
}

fn show(i: int, n: Node) {
    println("case \${i}")
    for l in rows_of(place(n, ${PROP ? "typeface()" : "Pixels { theme: Env {}.theme }"}, ${WIDTH})) { println(l) }
    println("html \${i}")
    println(render(n, Env {}).replace("\\n", " "))
    println("end \${i}")
}
${defs}
${runs}
`;
}

function solved(cases, work) {
  fs.mkdirSync(path.join(work, "src"), { recursive: true });
  fs.writeFileSync(path.join(work, "avra.toml"), `[package]\nname = "layout-oracle"\nversion = "0.0.1"\n`);
  fs.writeFileSync(path.join(work, "src/main.av"), program(cases));
  const avra = process.env.AVRA ?? path.join(tree, "build/avra");
  const ran = spawnSync(avra, ["run", work], { encoding: "utf8", maxBuffer: 1 << 28 });
  if (ran.status !== 0) { console.error(ran.stdout.slice(-2000), ran.stderr.slice(-4000)); process.exit(2); }
  const out = [], pages = [];
  let reading = null;
  for (const l of ran.stdout.split("\n")) {
    if (l.startsWith("case ")) { out.push([]); reading = "rects"; }
    else if (l.startsWith("html ")) reading = "html";
    else if (l.startsWith("end ")) reading = null;
    else if (reading === "rects" && /^-?\d/.test(l)) out[out.length - 1].push(l.split(" ").map(Number));
    else if (reading === "html") pages.push(l);
  }
  return { out, pages };
}

// ── the browser's side ───────────────────────────────────────────

const PAGE = `<!doctype html><meta charset=utf-8><style>@font-face{font-family:cell;src:url(data:font/ttf;base64,${cellFontBase64(PROP ? FACE : {})})}body{margin:0;font:1px/${PROP ? LINE : 1}px cell${PROP ? ";font-kerning:none;font-variant-ligatures:none" : ""}}</style><body></body>`;

// The page the realizer wrote is laid in a host WIDTH wide. Each box is read
// as the browser paints it: its edges, from the root's corner, snapped to the
// nearest whole unit, halves up — the law the solver hands its boxes back by.
const BROWSER = `(html, widthPx) => {
  const host = document.createElement("div");
  host.style.cssText = "position:absolute;left:0;top:0;width:" + widthPx + "px";
  document.body.appendChild(host);
  host.innerHTML = "<style>:root{--face-body:cell !important}</style>" + html;
  const root = host.lastElementChild;
  const origin = root.getBoundingClientRect();
  const out = [];
  const walk = (el) => {
    const r = el.getBoundingClientRect();
    const l = Math.round(r.x - origin.x), t = Math.round(r.y - origin.y);
    out.push([l, t, Math.round(r.x + r.width - origin.x) - l, Math.round(r.y + r.height - origin.y) - t]);
    for (const k of el.children) walk(k);
  };
  walk(root);
  document.body.removeChild(host);
  return out;
}`;

async function compare(cases, browser, work) {
  const { out, pages } = solved(cases, work);
  const results = [];
  for (let i = 0; i < cases.length; i++) {
    const got = await browser.read(`(${BROWSER})(${JSON.stringify(pages[i])}, ${WIDTH})`);
    results.push(JSON.stringify(got) === JSON.stringify(out[i]) ? null : { got, want: out[i] });
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

async function main() {
  const rand = prng(SEED);
  const cases = args.tree ? [JSON.parse(args.tree)] : (PROP ? PROP_CASES : FIXED_CASES).concat(Array.from({ length: CASES }, () => rooted(generate(rand, 3))));
  const work = fs.mkdtempSync(path.join(os.tmpdir(), "avra-layout-oracle-"));
  const binary = firefoxBinary();
  if (!binary) {
    const skipped = process.argv.includes("--skip-if-absent");
    console.log(`layout-oracle: ran 0 trees — ${skipped ? "SKIPPED" : "FAILED"}: no Firefox on this machine (FIREFOX names one)`);
    process.exit(skipped ? 0 : 1);
  }
  const page = fs.mkdtempSync(path.join(os.tmpdir(), "avra-layout-page-"));
  fs.writeFileSync(path.join(page, "index.html"), PAGE);
  const browser = await openPage(binary, "file://" + path.join(page, "index.html"), { width: 1200, height: 900 });
  await browser.read('document.fonts.load("1px cell").then((faces) => faces.length)');
  const verdicts = await compare(cases, browser, work);
  const failing = verdicts.map((v, i) => (v ? i : -1)).filter((i) => i >= 0);
  for (const i of failing.slice(0, SHOW)) {
    const small = await shrunk(cases[i], browser, work);
    const [v] = await compare([small], browser, work);
    console.log(`MISMATCH case ${i} (seed ${SEED}), shrunk:\n${JSON.stringify(small)}`);
    const n = Math.max(v.got.length, v.want.length);
    for (let k = 0; k < n; k++) {
      const a = JSON.stringify(v.want[k]), b = JSON.stringify(v.got[k]);
      console.log(`  box ${k}: solver ${a}  browser ${b}${a === b ? "" : "   <--"}`);
    }
  }
  await browser.close();
  if (cases.length === 0) { console.log("layout-oracle: ran 0 trees — FAILED: no tree was compared"); process.exit(1); }
  console.log(`layout-oracle: ${cases.length - failing.length} of ${cases.length} trees agree (seed ${SEED}, width ${WIDTH})`);
  process.exit(failing.length === 0 ? 0 : 1);
}

main().catch((e) => { console.error(e); process.exit(2); });
