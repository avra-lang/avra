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
import { run, parseFrame } from "../../runtime/dom/bootstrap.js";
import { OP } from "../../runtime/dom/wire.gen.js";
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

// The page as the first paint left it, copied before anything is done to it:
// what a server's HTML stands as before the module runs.
const copied = (n, doc) => {
  const c = n.tagName === "#text" ? doc.createTextNode(n.textContent) : doc.createElement(n.tagName);
  for (const [k, v] of Object.entries(n.attrs)) c.setAttribute(k, v);
  for (const k of n.childNodes) c.insertBefore(copied(k, doc), null);
  return c;
};
const firstPaint = mount.childNodes.map((n) => copied(n, stubDocument()));

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
// THE SERVER, BY HAND: the page's fetch is answered from a table of tasks the
// way the board's server answers its doors (GET lists, POST makes, PATCH
// replaces, DELETE removes). The board keeps no copy of its own: every change
// is sent, and the page shows the list the server answers with.
const settle = async () => { for (let k = 0; k < 8; k++) await Promise.resolve(); };
const table = { rows: [], next: 1, refusing: 0 };
const seeded = (title, done = false) => table.rows.push({ id: table.next++, title, done });
const wording = (init) => JSON.parse(new TextDecoder().decode(init.body));
const reply = (status, value) => ({ status, arrayBuffer: async () => (value === undefined ? new ArrayBuffer(0) : new TextEncoder().encode(JSON.stringify(value)).buffer) });
const answer = ({ url, init }) => {
  const id = Number(url.split("/")[2]);
  if (init.method === "GET") return reply(200, table.rows);
  if (table.refusing) return reply(table.refusing);
  if (init.method === "POST") { const row = { id: table.next++, ...wording(init) }; table.rows.push(row); return reply(200, row); }
  const row = table.rows.find((r) => r.id === id);
  if (!row) return reply(404);
  if (init.method === "PATCH") { Object.assign(row, wording(init)); return reply(200, row); }
  table.rows.splice(table.rows.indexOf(row), 1);
  return reply(204);
};
// Every ask the page has made is answered, and each answer is a turn: the change's, then the list the board asks for after it.
const answered = async () => { while (asked.length) { const ask = asked.shift(); ask.resolve(answer(ask)); await settle(); } };
const drain = async () => { await settle(); await answered(); frame(); };
const footerWords = () => every(mount, (n) => n.tagName === "#text" && n.textContent.includes("open ·")).map((n) => n.textContent)[0] || "";

claim("the first paint is the board with no tasks: the server holds them", keyed("1") === null && textOf(mount).includes("Nothing here yet."), shape(mount).slice(0, 80));
claim("the page asks the server for its tasks at start, with a GET for /tasks", asked.length === 1 && asked[0].url === "/tasks" && asked[0].init.method === "GET", `${asked.length}`);
for (const title of ["Draft the spec", "Wire the event channel", "Land the wasm board", "Write the tour"]) seeded(title, title.startsWith("Draft") || title.startsWith("Write"));
await drain();
claim("the server's tasks are the board's: four rows, under the server's keys", ["1", "2", "3", "4"].every((k) => keyed(k) !== null), shape(mount).slice(0, 80));
claim("the footer says nothing of a failed ask", !footerWords().includes("failed"), footerWords());
spent();

// THE PER-ITEM HANDLER: row 3's Remove names row 3's task, and its press is a DELETE.
const row4 = keyed("4");
const remove3 = named("Remove", keyed("3"))[0];
claim("row 3 holds a Remove that listens", Boolean(remove3));
fire(remove3);
await settle();
claim("pressing it sends one DELETE for /tasks/3 and changes nothing on the page", asked.length === 1 && asked[0].url === "/tasks/3" && asked[0].init.method === "DELETE" && keyed("3") !== null && frames === 0, `${asked.map((a) => a.init.method + " " + a.url)}`);
await drain();
claim("the server's answer takes the row: 3 is gone and 2 is kept", keyed("3") === null && keyed("2") !== null && table.rows.length === 3);
claim("the row below is the same element: nothing rebuilt it", keyed("4") === row4);
claim("the change is one frame of under 200 bytes", frames === 1 && writes < 200, spent());
spent();

// The user checks the box; the control says its own state, and the change is a PATCH of the whole task.
const toggle2 = named("Wire the event channel")[0];
claim("row 2's checkbox listens", Boolean(toggle2));
toggle2.checked = true;
fire(toggle2);
await settle();
claim("checking it sends one PATCH for /tasks/2 carrying the task as JSON", asked.length === 1 && asked[0].url === "/tasks/2" && asked[0].init.method === "PATCH" && asked[0].init.headers["content-type"] === "application/json" && new TextDecoder().decode(asked[0].init.body) === '{"title":"Wire the event channel","done":true}', `${asked.map((a) => a.init.method + " " + a.url)}`);
await drain();
claim("the server holds it done, and the board shows the server's list in small frames", table.rows.find((r) => r.id === 2).done === true && writes < 400, spent());
spent();

// ADD FROM THE FIELD: the input's own text rides the input event, then the
// Add button sends the task the draft named. THE CARET WITNESS: while the
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
await settle();
claim("Add sends one POST for /tasks carrying the draft as a task", asked.length === 1 && asked[0].url === "/tasks" && asked[0].init.method === "POST" && new TextDecoder().decode(asked[0].init.body) === '{"title":"Ship the rewrite","done":false}', `${asked.map((a) => a.init.method + " " + a.url)}`);
claim("the program clears the field, once", valueWrites === 1 && typed === "", `${valueWrites} write(s), value "${typed}"`);
claim("the row is not the board's until the server answers", keyed("5") === null);
await drain();
claim("the server's task is a row under the server's key", keyed("5") !== null && textOf(keyed("5")).includes("Ship the rewrite"));
spent();

// A TEXT OF ANY LENGTH: the program hands out a seat for the octets the
// field holds, so a value far past any fixed room arrives whole.
const long = "é".repeat(6000);
typed = long;
fire(field);
fire(add);
await drain();
claim("a 12000-octet title is kept whole by the server and shown whole", keyed("6") !== null && textOf(keyed("6")).includes(long) && table.rows.at(-1).title === long);
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

// A REFUSAL IS SHOWN IN WORDS, and the board still shows the server's list:
// a change the server refuses is a change the board never made.
table.refusing = 503;
fire(named("Remove", keyed("6"))[0]);
await drain();
claim("a refused change shows as the words the answer gave", footerWords().includes("save failed: status 503"), footerWords());
claim("and the board shows what the server holds: row 6 is still there", keyed("6") !== null && table.rows.length === 5);
table.refusing = 0;
spent();
fire(named("Remove", keyed("6"))[0]);
await drain();
claim("the next change the server takes clears the words, and the row goes", !footerWords().includes("failed") && keyed("6") === null && table.rows.length === 4, footerWords());
spent();

// TURNS THAT LAND TOGETHER ARE ONE PAINT: a timer and the answers to a change
// in one tick wait for the display's frame, which walks the view once and
// sends one frame; a frame nothing asked for walks nothing; and an EVENT shows
// what is pending first, because the user acts on the screen they saw.
fire(named("Remove", keyed("5"))[0]);
fire(remind);
await settle();
frame();
spent();
const walks = () => Number(mod.avra_ui_walks());
let walked = walks();
const reminderTimer = [...armed.values()].slice(-1)[0];
await settle();
await answered();
reminderTimer.fn();
claim("nothing is painted until the frame comes: no frame sent, no walk", frames === 0 && walks() === walked, `${frames} frame(s), ${walks() - walked} walk(s)`);
frame();
claim("the frame is one frame and one walk for both sources", frames === 1 && walks() - walked === 1, `${spent()}, ${walks() - walked} walk(s)`);
claim("what each source did shows in it", keyed("5") === null && footerWords().includes("reminder"), footerWords());
frame();
claim("a frame nothing asked for walks nothing", walks() - walked === 1, `${walks() - walked}`);
spent();

// An answer lands, then the user presses before the frame: the press meets the
// screen the user saw, so the pending paint is shown first.
walked = walks();
const mode = named("Light mode")[0] ?? named("Dark mode")[0];
const [, mode_ear] = ears(mode.__avra_id)[0];
const dark = () => dispatch(mount, mode, mode_ear.event, { bubbles: false });
fire(named("Remove", keyed("4"))[0]);
await settle();
await answered();
spent();
walked = walks();
dark();
claim("a press after a pending answer shows the answer first, then its own change", frames === 1 && walks() - walked === 1 && keyed("4") === null, `${frames} frame(s), ${walks() - walked} walk(s)`);
frame();
claim("and the press's own frame follows at the display's frame", walks() - walked === 2 && named("Dark mode").length + named("Light mode").length === 1, `${walks() - walked}`);
spent();

// ── a server's page, adopted ──
const serverPrint = process.argv[3];
// What a request decided, shipped beside the server's page: the module starts
// from it, so the page it draws is the one the server drew.
const shipped = new TextEncoder().encode(process.argv[6] ?? "");
const withState = async () => {
  const doc = stubDocument();
  const at = stubElement("root");
  await run(new Uint8Array(fs.readFileSync(process.argv[2])), {
    document: doc,
    mount: at,
    style: { textContent: "" },
    wasi: (memory) => wasiPreview1(memory, (code) => { throw new Error(`the program exited ${code}`); }),
    clock,
    fetch: fetchFn,
    raf: (cb) => rafs.push(cb),
    state: shipped,
  });
  await settle();
  return at.childNodes.map((n) => copied(n, stubDocument()));
};
const servedPaint = await withState();
claim("a module started from the shipped state draws another page than its own default", servedPaint.map(shape).join() !== firstPaint.map(shape).join());
const serverBytes = Number(process.argv[4]);
const adopting = async (print, early = null) => {
  const doc = stubDocument();
  const at = stubElement("root");
  at.setAttribute("data-avra-print", print);
  const placed = servedPaint.map((n) => copied(n, doc));
  for (const n of placed) at.insertBefore(n, null);
  if (early !== null) every(at, (n) => n.attrs["aria-label"] === "New task")[0].value = early;
  const sentFrames = [];
  const sizes = [];
  const quiet = console.warn;
  console.warn = () => {};
  const { ears: heard } = await run(new Uint8Array(fs.readFileSync(process.argv[2])), {
    document: doc,
    mount: at,
    style: { textContent: "" },
    wasi: (memory) => wasiPreview1(memory, (code) => { throw new Error(`the program exited ${code}`); }),
    sent: (bytes) => { sizes.push(bytes.length); sentFrames.push(parseFrame(bytes)); },
    clock,
    fetch: fetchFn,
    raf: (cb) => rafs.push(cb),
    state: shipped,
  });
  await settle();
  console.warn = quiet;
  return { at, placed, sentFrames, sizes, heard };
};
const kept = await adopting(serverPrint);
const all = kept.sentFrames.flat();
const first = kept.sentFrames[0] ?? [];
claim("the server's print is the number the module folds from the same view", first[0]?.op === OP.adopt && first[0].kinds.length > 0, serverPrint);
claim("an adopted page builds nothing", all.filter((p) => p.op === OP.create || p.op === OP.create_text).length === 0, `${all.length} patch(es)`);
claim("the first paint over an adopted page is the adoption, then define and listen only", first.length > 1 && first.slice(1).every((p) => p.op === OP.listen || p.op === OP.define), first.map((p) => p.op).join(","));
claim("the server's nodes are the page the module stands on", kept.at.childNodes.length === kept.placed.length && kept.placed.every((n, j) => kept.at.childNodes[j] === n));
claim("the adopted page is the page the module drew itself", kept.at.childNodes.map(shape).join() === servedPaint.map(shape).join());
claim("the first frame over an adopted page is under 1500 bytes (9326 without a server page)", kept.sizes[0] < 1500, `${kept.sizes[0]}`);
claim(`the server's page is ${serverBytes} bytes of HTML`, serverBytes > 0);
const early = await adopting(serverPrint, "typed early");
{
  const add = every(early.at, (n) => n.attrs["aria-label"] === "Add" && early.heard(n.__avra_id).length > 0)[0];
  const [, ear] = early.heard(add.__avra_id)[0];
  dispatch(early.at, add, ear.event, { bubbles: false });
  frame();
  await settle();
  await drain();
  const all = every(early.at, (n) => n.attrs["aria-label"] === "All" && early.heard(n.__avra_id).length > 0)[0];
  const [, all_ear] = early.heard(all.__avra_id)[0];
  dispatch(early.at, all, all_ear.event, { bubbles: false });
  frame();
  await settle();
  claim("text typed before the program stood is the program's when it adds the task", textOf(early.at).includes("typed early"), textOf(early.at).slice(0, 60));
}
const torn = await adopting(String(Number(serverPrint) + 1));
const tornCreates = torn.sentFrames.flat().filter((p) => p.op === OP.create).length;
claim("a print that is not the module's empties the page and draws it again", torn.sentFrames[0][0].kinds.length === 0 && tornCreates > 0 && torn.at.childNodes.map(shape).join() === servedPaint.map(shape).join());

// ── a module swapped under the page ──
const editedWasm = process.argv[5];
const swapping = async () => {
  const doc = stubDocument();
  const at = stubElement("root");
  const sentFrames = [];
  const timers = new Map();
  const own = {
    setTimeout: (fn, ms) => { const h = timers.size + 1; timers.set(h, fn); return h; },
    setInterval: (fn, ms) => { const h = timers.size + 1; timers.set(h, fn); return h; },
    clearTimeout: (h) => timers.delete(h),
    clearInterval: (h) => timers.delete(h),
  };
  const frames2 = [];
  let swap = null;
  const { ears: heard } = await run(new Uint8Array(fs.readFileSync(process.argv[2])), {
    document: doc,
    mount: at,
    style: { textContent: "" },
    wasi: (memory) => wasiPreview1(memory, (code) => { throw new Error(`the program exited ${code}`); }),
    sent: (bytes) => sentFrames.push(parseFrame(bytes)),
    clock: own,
    fetch: fetchFn,
    raf: (cb) => frames2.push(cb),
    hot: (s) => { swap = s; },
  });
  await settle();
  return { at, heard, sentFrames, swap: (path) => swap(new Uint8Array(fs.readFileSync(path))), timers, frames2 };
};
const nodesOf = (n) => [n, ...n.childNodes.flatMap(nodesOf)];
{
  const s = await swapping();
  const before = s.at.childNodes.flatMap(nodesOf);
  const shapeBefore = s.at.childNodes.map(shape).join();
  s.sentFrames.length = 0;
  await s.swap(process.argv[2]);
  await settle();
  const ops = s.sentFrames.flat();
  const after = s.at.childNodes.flatMap(nodesOf);
  claim("a swap to the same module keeps every element the page holds", before.length === after.length && before.every((n, j) => after[j] === n), `${before.length} vs ${after.length}`);
  claim("a swap to the same module says define and listen and nothing built", ops.length > 0 && ops.every((p) => p.op === OP.listen || p.op === OP.define), ops.map((p) => p.op).join(","));
  claim("and the page it leaves is the page it had", s.at.childNodes.map(shape).join() === shapeBefore);
}
{
  const s = await swapping();
  const remind = every(s.at, (n) => n.attrs["aria-label"] === "Remind me" && s.heard(n.__avra_id).length > 0)[0];
  const [, ear] = s.heard(remind.__avra_id)[0];
  dispatch(s.at, remind, ear.event, { bubbles: false });
  for (const cb of s.frames2.splice(0)) cb();
  await settle();
  const armedBefore = s.timers.size;
  await s.swap(process.argv[2]);
  await settle();
  claim("a swap lets go of the timers the module that stood down armed", armedBefore > 0 && s.timers.size === 0, `${armedBefore} then ${s.timers.size}`);
  claim("a swap starts the module from its own state over the page the host holds", s.at.childNodes.map(shape).join() === firstPaint.map(shape).join());
}
{
  const s = await swapping();
  const before = s.at.childNodes.flatMap(nodesOf);
  s.sentFrames.length = 0;
  await s.swap(editedWasm);
  await settle();
  const ops = s.sentFrames.flat();
  const texts = ops.filter((p) => p.op === OP.set_text);
  const built = ops.filter((p) => [OP.create, OP.create_text, OP.remove, OP.place].includes(p.op));
  const after = s.at.childNodes.flatMap(nodesOf);
  claim("an edited view is applied as one set_text and nothing built", texts.length === 1 && texts[0].content === "Tasks today" && built.length === 0, ops.map((p) => p.op).join(","));
  claim("and every element the page held stands", before.length === after.length && before.every((n, j) => after[j] === n));
}

console.log(failed === 0 ? "ui-board: every claim holds" : `ui-board: ${failed} claim(s) FAILED`);
process.exit(failed === 0 ? 0 : 1);
