// WINDOWED LISTS ON A PAGE. The program builds only the rows of a list that
// are on screen and stands a spacer in for each side's rest (`data-avra-window`
// names the list; `data-avra-skip` is how many rows the spacer stands for;
// `data-avra-extent` how tall it took each). The host owns the geometry: it
// reads where the list sits against the viewport and tells the program which
// rows to build and how tall a row measures. A list whose rows all stand has
// no spacer and is never asked about.
//
// A request goes out only when the rows on screen are not all built, or the
// rows measure otherwise than the spacer assumed, so a scroll inside the built
// rows costs nothing.

// How far past the viewport rows are built, in viewports.
const OVERSCAN = 1;

// The scroller a list moves in: the nearest ancestor that scrolls, else the page.
function scrollerOf(el, doc) {
  const view = doc.defaultView;
  for (let up = el.parentElement; up; up = up.parentElement) {
    const style = view.getComputedStyle(up);
    if (/(auto|scroll)/.test(style.overflowY) && up.scrollHeight > up.clientHeight) return up;
  }
  return null;
}

// The part of the scroller on screen, as client coordinates.
function viewportOf(scroller, view) {
  if (!scroller) return { top: 0, bottom: view.innerHeight };
  const r = scroller.getBoundingClientRect();
  return { top: Math.max(r.top, 0), bottom: Math.min(r.bottom, view.innerHeight) };
}

// What one windowed list asks: null when its built rows serve, else the rows
// to build and the extent to space by.
export function askOf(list, view, doc) {
  const kids = Array.from(list.children);
  const spacers = kids.filter((k) => k.hasAttribute("data-avra-window"));
  const rows = kids.filter((k) => !k.hasAttribute("data-avra-window"));
  if (rows.length === 0) return null;
  const before = spacers.find((s) => s === kids[0]);
  const after = spacers.find((s) => s !== before);
  const skipBefore = before ? Number(before.getAttribute("data-avra-skip")) : 0;
  const skipAfter = after ? Number(after.getAttribute("data-avra-skip")) : 0;
  const path = (before || after || { getAttribute: () => "" }).getAttribute("data-avra-window");
  if (!path) return null;
  const first = rows[0].getBoundingClientRect();
  const last = rows[rows.length - 1].getBoundingClientRect();
  const measured = Math.max(1, Math.round((last.bottom - first.top) / rows.length));
  const declared = Number((before || after || { getAttribute: () => "0" }).getAttribute("data-avra-extent"));
  const extent = declared > 0 && Math.abs(measured - declared) * 5 <= declared ? declared : measured;
  const origin = before ? before.getBoundingClientRect().top : first.top;
  const port = viewportOf(scrollerOf(list, doc), view);
  const total = skipBefore + rows.length + skipAfter;
  const seen = Math.max(1, port.bottom - port.top);
  const from = Math.max(0, Math.floor((port.top - origin) / extent));
  const to = Math.min(total, Math.ceil((port.bottom - origin) / extent));
  const built = { from: skipBefore, to: skipBefore + rows.length };
  const served = (from >= built.from || built.from === 0) && (to <= built.to || built.to === total);
  if (served && extent === declared) return null;
  const reach = Math.ceil((seen * OVERSCAN) / extent);
  return { path, from: Math.max(0, from - reach), to: Math.min(total, to + reach), extent };
}

// Watch a page's windowed lists. `ask(path, from, to, extent)` tells the
// program; `check` is called after each frame and on each scroll.
export function createWindows(doc, mount, ask) {
  const view = doc.defaultView;
  const lists = () => Array.from(mount.querySelectorAll("[data-avra-window]")).map((s) => s.parentElement);
  let checking = false;
  const check = () => {
    if (checking || !view || typeof view.getComputedStyle !== "function") return;
    checking = true;
    try {
      const seen = new Set();
      for (const list of lists()) {
        if (!list || seen.has(list)) continue;
        seen.add(list);
        const q = askOf(list, view, doc);
        if (q) ask(q.path, q.from, q.to, q.extent);
      }
    } finally {
      checking = false;
    }
  };
  if (view && typeof view.addEventListener === "function") {
    view.addEventListener("scroll", check, { capture: true, passive: true });
    view.addEventListener("resize", check, { passive: true });
  }
  return { check };
}
