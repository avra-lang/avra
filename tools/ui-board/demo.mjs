// The board end to end, headless: the real module + the REAL page glue
// (bootstrap + WASI surface) over a stub document. Each claim below is
// CHECKED — a line says `ok` or `FAILED`, and one failure exits 1 — so
// the wire, the glue, `mount` and the app are proven together before any
// browser is opened. `make ui-board` builds the module and runs this.
//
// THE CONTROLS ARE THE LIBRARY'S OWN, so the events are the ones they
// declare: a button's `press`, a checkbox's `change` saying its state, a
// field's `input` saying its text. The demo finds each control as a reader
// of the page would — by its accessible name — and fires the listener the
// page was told to attach, never a synthetic event, so it proves the same
// path the page takes.
import fs from "node:fs";
import { run } from "../../runtime/dom/bootstrap.js";
import { wasiPreview1 } from "../../runtime/dom/wasi.js";
import { dispatch, stubDocument, stubElement, textOf } from "../../runtime/dom/stub_dom.js";

const mount = stubElement("root");
// The page's timers, by hand: what was armed, and a way to let it fire.
const armed = new Map();
// The page's fetch, by hand: each call waits for the test to answer it.
const asked = [];
const fetchFn = (url, init) => new Promise((resolve, reject) => asked.push({ url, init, resolve, reject }));
const clock = {
  setTimeout: (fn, ms) => { const h = armed.size + 1; armed.set(h, { fn, ms }); return h; },
  setInterval: (fn, ms) => { const h = armed.size + 1; armed.set(h, { fn, ms }); return h; },
  clearTimeout: (h) => armed.delete(h),
  clearInterval: (h) => armed.delete(h),
};
const style = { textContent: "" };
let frames = 0;
let writes = 0;

// The page's frames, by hand: the program asks for one (requestAnimationFrame)
// and the test lets the display's frame come.
const rafs = [];
const frame = () => { for (const cb of rafs.splice(0)) cb(); };
const { mod, ears } = await run(new Uint8Array(fs.readFileSync(process.argv[2])), {
  document: stubDocument(),
  mount,
  style,
  wasi: (memory) => wasiPreview1(memory, (code) => { throw new Error(`the program exited ${code}`); }),
  sent: (bytes) => { frames++; writes += bytes.length; },
  clock,
  fetch: fetchFn,
  raf: (cb) => rafs.push(cb),
});

const shape = (n) => {
  if (n.tagName === "#text") return `"${n.textContent}"`;
  const cls = n.attrs["class"] ? `.${n.attrs["class"]}` : "";
  const kids = n.childNodes.length ? `{${n.childNodes.map(shape).join(",")}}` : "";
  return `${n.tagName}${cls}${kids}`;
};
const every = (n, hit, out = []) => { if (hit(n)) out.push(n); n.childNodes.forEach((c) => every(c, hit, out)); return out; };
// A control by its accessible name, among those that listen.
const named = (name, under = mount) => every(under, (n) => n.attrs["aria-label"] === name && ears(n.__avra_id).length > 0);
// A keyed row by its key.
const keyed = (key) => every(mount, (n) => n.attrs["data-key"] === key)[0] || null;
const fire = (n) => {
  const [, ear] = ears(n.__avra_id)[0];
  dispatch(mount, n, ear.event, { bubbles: false });
  frame();
  return ear.event;
};
// What one event cost the wire: frames and bytes since the last ask.
const spent = () => { const s = `${frames} frame(s), ${writes} byte(s)`; frames = 0; writes = 0; return s; };

let failed = 0;
// One claim: its words, whether it holds, and what was seen when it does not.
const claim = (words, holds, seen = "") => {
  if (!holds) failed++;
  console.log(`${holds ? "ok    " : "FAILED"} ${words}${holds || seen === "" ? "" : ` — saw ${seen}`}`);
};

claim("the first paint sends the theme's variables and the page's base rule", style.textContent.includes(":root{") && style.textContent.includes("body{"), style.textContent.slice(0, 40));
claim("the first paint is one frame", frames === 1, spent());
spent();
claim("the page holds the four seeded rows", ["t1", "t2", "t3", "t4"].every((k) => keyed(k) !== null), shape(mount).slice(0, 80));

// THE PER-ITEM HANDLER: row 3's Remove names row 3's task.
const row4 = keyed("t4");
const remove3 = named("Remove", keyed("t3"))[0];
claim("row t3 holds a Remove that listens", Boolean(remove3));
fire(remove3);
claim("pressing it removes t3 and keeps t2", keyed("t3") === null && keyed("t2") !== null);
claim("the row below is the same element: nothing rebuilt it", keyed("t4") === row4);
claim("a removal is one frame of under 200 bytes", frames === 1 && writes < 200, spent());
spent();

// The user checks the box; the control says its own state.
const toggle2 = named("Wire the event channel")[0];
claim("row t2's checkbox listens", Boolean(toggle2));
toggle2.checked = true;
fire(toggle2);
claim("checking it is one frame of under 200 bytes", frames === 1 && writes < 200, spent());
spent();

// ADD FROM THE FIELD: the input's own text rides the input event, then the
// Add button appends the task the draft named. THE CARET WITNESS: while the
// user types, the page's own value is never written back to it.
const field = named("New task")[0];
const add = named("Add")[0];
claim("the field and the Add button listen", Boolean(field) && Boolean(add));
let valueWrites = 0;
let typed = "";
Object.defineProperty(field, "value", { get: () => typed, set: (v) => { valueWrites++; typed = v; }, configurable: true });
typed = "Ship the rewrite";
fire(field);
claim("typing writes no value back and sends no frame", valueWrites === 0 && frames === 0, `${valueWrites} write(s), ${spent()}`);
fire(add);
claim("Add appends the row the draft named", keyed("t5") !== null && textOf(keyed("t5")).includes("Ship the rewrite"));
claim("the program clears the field, once", valueWrites === 1 && typed === "", `${valueWrites} write(s), value "${typed}"`);
spent();

// A TEXT OF ANY LENGTH: the program hands out a seat for the octets the
// field holds, so a value far past any fixed room arrives whole.
typed = "é".repeat(6000);
fire(field);
fire(add);
claim("a 12000-octet title is kept whole", keyed("t6") !== null && textOf(keyed("t6")).includes(typed));
spent();

// A MODE IS A WHOLE SHEET: the theme's variables move and no element does.
const theme = named("Dark mode")[0];
const sheet = style.textContent;
fire(theme);
claim("the dark mode rewrites the sheet and renames its button", style.textContent !== sheet && named("Light mode").length === 1);

// EVERY INK READS ON EVERY FILL: the tones each mode's sheet names, as WCAG
// contrast — the least a reader with ordinary sight needs is 4.5 to 1.
const tones = (css) => Object.fromEntries([...css.matchAll(/--tone-([a-z-]+):(#[0-9a-f]{6})/g)].map((m) => [m[1], m[2]]));
const light = (hex) => {
  const [r, g, b] = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255).map((c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4));
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};
const faint = (css) => {
  const named = tones(css);
  const fills = Object.keys(named).filter((tone) => tone.startsWith("surface"));
  const inks = Object.keys(named).filter((tone) => !tone.startsWith("surface"));
  return inks.flatMap((ink) => fills.map((fill) => {
    const [a, b] = [light(named[ink]), light(named[fill])].sort((x, y) => y - x);
    return { pair: `${ink} on ${fill}`, ratio: (a + 0.05) / (b + 0.05) };
  })).filter((seen) => seen.ratio < 4.5).map((seen) => `${seen.pair} ${seen.ratio.toFixed(2)}`);
};
claim("each mode's sheet names its inks and its fills", Object.keys(tones(sheet)).length >= 4 && Object.keys(tones(style.textContent)).length >= 4);
claim("every ink reads on every fill in the light mode", faint(sheet).length === 0, faint(sheet).join(", "));
claim("every ink reads on every fill in the dark mode", faint(style.textContent).length === 0, faint(style.textContent).join(", "));

// A SOURCE IS THE HOST'S TIMER: a press asks, the page arms a timer, its
// firing is a turn, and the footer says so.
spent();
const footerWords = () => every(mount, (n) => n.tagName === "#text" && n.textContent.includes("open ·")).map((n) => n.textContent)[0] || "";
const remind = named("Remind me")[0];
claim("the footer holds a Remind me that listens", Boolean(remind));
claim("before the reminder the footer does not say it", !footerWords().includes("reminder"), footerWords());
fire(remind);
claim("pressing it arms one timer of 100 ms on the page's clock", armed.size === 1 && [...armed.values()][0].ms === 100, `${armed.size}`);
claim("asking cost no frame: nothing changed on the page", frames === 0, spent());
[...armed.values()][0].fn();
frame();
claim("the timer firing is a turn: the footer says the reminder", footerWords().includes("reminder"), footerWords());
spent();

// A SOURCE IS THE HOST'S FETCH TOO: the same Request value, one frame to the
// host, its answer a turn.
const settle = async () => { for (let k = 0; k < 8; k++) await Promise.resolve(); };
const made = (id, title, done = false) => ({ status: 200, arrayBuffer: async () => new TextEncoder().encode(JSON.stringify({ id, title, done })).buffer });
const listed = (rows) => ({ status: 200, arrayBuffer: async () => new TextEncoder().encode(JSON.stringify(rows)).buffer });
claim("the page asks the server for its tasks at start, with a GET for /tasks", asked.length === 1 && asked[0].url === "/tasks/" && asked[0].init.method === "GET", `${asked.length}`);
asked[0].resolve(listed([]));
await settle();
frame();
claim("a server with no tasks leaves the board its own: four rows, and the footer says nothing of the ask", keyed("t1") !== null && !footerWords().includes("sync"), footerWords());
asked.splice(0);
spent();
const sync = named("Sync")[0];
claim("the footer holds a Sync that listens", Boolean(sync));
spent();
fire(sync);
await settle();
claim("pressing it sends one request for /tasks with the page's fetch", asked.length === 1 && asked[0].url === "/tasks/" && asked[0].init.method === "POST", `${asked.length}`);
claim("the whole request crossed the wasm boundary: content type and the first task the server does not hold, as JSON", asked[0].init.headers["content-type"] === "application/json" && new TextDecoder().decode(asked[0].init.body) === '{"title":"Draft the spec","done":true}', JSON.stringify(asked[0].init.headers));
claim("the footer says it is syncing; the ask cost one small frame", footerWords().includes("syncing") && frames === 1, `${footerWords()} / ${spent()}`);
spent();
asked[0].resolve(made(7, "Draft the spec", true));
await settle();
frame();
claim("the answer is a turn: the footer says how many tasks the server holds", footerWords().includes("synced 1"), footerWords());
claim("the task the server kept stands where it did, under the server's key", keyed("7") !== null && keyed("t1") === null, `${keyed("7") !== null} ${keyed("t1") === null}`);
spent();
fire(sync);
await settle();
asked[1].resolve({ status: 503, arrayBuffer: async () => new ArrayBuffer(0) });
await settle();
frame();
claim("a refusal shows as the words the parse gave", footerWords().includes("sync failed: status 503"), footerWords());
spent();

// TURNS THAT LAND TOGETHER ARE ONE PAINT: a timer and a fetch answer in one
// tick wait for the display's frame, which walks the view once and sends one
// frame; a frame nothing asked for walks nothing; and an EVENT shows what is
// pending first, because the user acts on the screen they saw.
fire(remind);
fire(sync);
await settle();
frame();
spent();
const walks = () => Number(mod.avra_ui_walks());
let walked = walks();
const reminderTimer = [...armed.values()].slice(-1)[0];
asked[asked.length - 1].resolve(made(8, "Wire the event channel"));
await settle();
reminderTimer.fn();
claim("nothing is painted until the frame comes: no frame sent, no walk", frames === 0 && walks() === walked, `${frames} frame(s), ${walks() - walked} walk(s)`);
frame();
claim("the frame is one frame and one walk for both sources", frames === 1 && walks() - walked === 1, `${spent()}, ${walks() - walked} walk(s)`);
claim("what each source did shows in it", footerWords().includes("synced 2") && footerWords().includes("reminder"), footerWords());
frame();
claim("a frame nothing asked for walks nothing", walks() - walked === 1, `${walks() - walked}`);
spent();

// A source lands, then the user presses before the frame: the press meets the
// screen the user saw, so the pending paint is shown first.
walked = walks();
const mode = named("Light mode")[0] ?? named("Dark mode")[0];
const [, mode_ear] = ears(mode.__avra_id)[0];
const dark = () => dispatch(mount, mode, mode_ear.event, { bubbles: false });
fire(sync);
await settle();
asked[asked.length - 1].resolve(made(9, "Land the wasm board"));
await settle();
frame();
spent();
walked = walks();
fire(sync);
await settle();
frame();
walked = walks();
asked[asked.length - 1].resolve(made(10, "Write the tour", true));
await settle();
spent();
dark();
claim("a press after a pending answer shows the answer first, then its own change", frames === 1 && walks() - walked === 1, `${frames} frame(s), ${walks() - walked} walk(s)`);
frame();
claim("and the press's own frame follows at the display's frame", walks() - walked === 2 && named("Dark mode").length + named("Light mode").length === 1, `${walks() - walked}`);
spent();

console.log(failed === 0 ? "ui-board: every claim holds" : `ui-board: ${failed} claim(s) FAILED`);
process.exit(failed === 0 ? 0 : 1);
