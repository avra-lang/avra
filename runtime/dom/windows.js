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

// The rows of a list in runs of consecutive positions (`aria-posinset`): the
// window is the longest, and a row the focus keeps built stands apart from it.
function runsOf(rows) {
  const at = (r) => Number(r.getAttribute("aria-posinset")) - 1;
  const runs = [];
  for (const r of rows) {
    const run = runs[runs.length - 1];
    if (run && at(r) === at(run[run.length - 1]) + 1) run.push(r);
    else runs.push([r]);
  }
  return { runs, at };
}

// The key of the row the focus rests on, none ("") when it rests elsewhere.
function pinOf(rows, doc) {
  const active = doc.activeElement;
  const held = active ? rows.find((r) => r.contains(active)) : null;
  return held ? held.getAttribute("data-key") || "" : "";
}

// What one windowed list asks: null when its built rows serve and the focus
// is where the program last heard, else the rows to build, the extent to
// space by, and the row the focus rests on.
export function askOf(list, view, doc, heard = "") {
  const kids = Array.from(list.children);
  const spacers = kids.filter((k) => k.hasAttribute("data-avra-window"));
  const rows = kids.filter((k) => !k.hasAttribute("data-avra-window"));
  if (rows.length === 0 || spacers.length === 0) return null;
  const path = spacers[0].getAttribute("data-avra-window");
  const declared = Number(spacers[0].getAttribute("data-avra-extent"));
  const { runs, at } = runsOf(rows);
  const run = runs.reduce((best, r) => (r.length > best.length ? r : best), runs[0]);
  const total = Number(run[0].getAttribute("aria-setsize"));
  const built = { from: at(run[0]), to: at(run[run.length - 1]) + 1 };
  const first = run[0].getBoundingClientRect();
  const last = run[run.length - 1].getBoundingClientRect();
  const measured = Math.max(1, Math.round((last.bottom - first.top) / run.length));
  const extent = declared > 0 && Math.abs(measured - declared) * 5 <= declared ? declared : measured;
  const origin = kids[0].getBoundingClientRect().top;
  const port = viewportOf(scrollerOf(list, doc), view);
  const seen = Math.max(1, port.bottom - port.top);
  const from = Math.max(0, Math.floor((port.top - origin) / extent));
  const to = Math.min(total, Math.ceil((port.bottom - origin) / extent));
  const served = (from >= built.from || built.from === 0) && (to <= built.to || built.to === total);
  const pin = pinOf(rows, doc);
  if (served && extent === declared && pin === heard) return null;
  const reach = Math.ceil((seen * OVERSCAN) / extent);
  return { path, from: Math.max(0, from - reach), to: Math.min(total, to + reach), extent, pin };
}

// Watch a page's windowed lists. `ask(path, from, to, extent, pin)` tells the
// program; `check` is called after each frame, on each scroll and as the
// focus moves. A row the program asks to be shown is scrolled to once.
export function createWindows(doc, mount, ask) {
  const view = doc.defaultView;
  const lists = () => Array.from(mount.querySelectorAll("[data-avra-window]")).map((s) => s.parentElement);
  const heard = new Map();
  const shown = new WeakSet();
  let checking = false;
  const tell = (q) => {
    heard.set(q.path, q.pin);
    ask(q.path, q.from, q.to, q.extent, q.pin);
  };
  const check = () => {
    if (checking || !view || typeof view.getComputedStyle !== "function") return;
    checking = true;
    try {
      const seen = new Set();
      for (const list of lists()) {
        if (!list || seen.has(list)) continue;
        seen.add(list);
        const target = list.querySelector("[data-avra-reveal]");
        const path = (list.querySelector("[data-avra-window]") || { getAttribute: () => "" }).getAttribute("data-avra-window");
        if (target && !shown.has(target)) {
          shown.add(target);
          target.scrollIntoView({ block: "start" });
          const q = askOf(list, view, doc, heard.get(path) || "");
          if (q) { tell(q); continue; }
        }
        const q = askOf(list, view, doc, heard.get(path) || "");
        if (q) tell(q);
      }
    } finally {
      checking = false;
    }
  };
  if (view && typeof view.addEventListener === "function") {
    view.addEventListener("scroll", check, { capture: true, passive: true });
    view.addEventListener("resize", check, { passive: true });
    doc.addEventListener("focusin", check);
    doc.addEventListener("focusout", check);
  }
  return { check };
}
