// The dev client, by its own verb over a stub document and a stream it is
// handed: when it reloads, and that a failed build is shown and a mended
// one clears it.
import { hudPosting, panel, relayed, watch } from "./dev.js";
import { stubDocument, stubElement } from "./stub_dom.js";

let passed = 0;
let failed = 0;
const test = (name, holds) => {
  if (holds) { passed++; console.log(`✓ ${name}`); } else { failed++; console.log(`✗ ${name}`); }
};

// A page with a body the panel can join, found again by its id.
const page = () => {
  const doc = stubDocument();
  doc.body = stubElement("body");
  doc.body.appendChild = (el) => doc.body.insertBefore(el, null);
  doc.getElementById = (id) => doc.body.childNodes.find((el) => el.id === id) || null;
  return doc;
};
// A stream a test speaks through: each event handed to whoever listens for it.
const stream = () => {
  const heard = new Map();
  return { addEventListener: (name, hear) => heard.set(name, hear), say: (name, data) => heard.get(name)({ data }) };
};
// The client over a fresh page running module `abc`.
const client = (swap = null) => {
  const made = { doc: page(), events: stream(), reloads: 0 };
  watch({ doc: made.doc, mine: "abc", events: made.events, reload: () => { made.reloads++; }, swap });
  made.showing = () => { const panel = made.doc.getElementById("avra-dev-failure"); return panel && !panel.hidden ? panel.textContent : ""; };
  return made;
};

const same = client();
same.events.say("built", "abc");
test("the module this page runs, built, is left alone", same.reloads === 0 && same.showing() === "");

const moved = client();
moved.events.say("built", "xyz");
test("another module reloads the page", moved.reloads === 1);

const broke = client();
broke.events.say("failed", "error: x\n  at y");
test("a failed build is shown over the page, whole", broke.showing() === "error: x\n  at y");
test("a failed build never reloads: the last good module keeps running", broke.reloads === 0);
test("what is shown is an alert a reader is told of", broke.doc.getElementById("avra-dev-failure").attrs.role === "alert");
broke.events.say("failed", "error: z");
test("a second failure replaces the first", broke.showing() === "error: z" && broke.doc.body.childNodes.length === 1);
broke.events.say("built", "abc");
test("the same module built again clears what was shown", broke.showing() === "" && broke.reloads === 0);
broke.events.say("failed", "again");
broke.events.say("built", "xyz");
test("a mended build of another module reloads", broke.reloads === 1);

// A page that can swap takes the new module over itself.
{
  let swaps = 0;
  const swapping = client(async () => { swaps++; });
  await swapping.events.say("built", "xyz");
  test("another module is swapped under the page, which is not reloaded", swaps === 1 && swapping.reloads === 0);
  await swapping.events.say("built", "xyz");
  test("the module that stands after a swap is left alone", swaps === 1 && swapping.reloads === 0);
  await swapping.events.say("built", "abc");
  test("a module that is not the one standing swaps again", swaps === 2);
  const failing = client(async () => { throw new Error("no page"); });
  const warn = console.warn;
  console.warn = () => {};
  await failing.events.say("built", "xyz");
  console.warn = warn;
  test("a swap that fails reloads the page", failing.reloads === 1);
}

// The app's own words reach the server; nothing else does.
{
  const heard = [], posted = [];
  const fake = { error: (...said) => heard.push(said.join(" ")) };
  relayed({ console: fake, post: (text) => posted.push(text) });
  fake.error("ui: `counter` keeps state");
  fake.error("avra: the page held elements this program does not draw");
  fake.error("  ui: indented is not the app's");
  test("an app warning is posted to the server", posted.length === 1 && posted[0] === "ui: `counter` keeps state");
  test("every line still reaches the console", heard.length === 3);
}

// The module that stands is named on the document element, so a reader can wait on a swap.
{
  const swapping = client(async () => {});
  swapping.doc.documentElement = stubElement("html");
  watch({ doc: swapping.doc, mine: "abc", events: swapping.events, reload: () => {}, swap: async () => {} });
  const named = () => swapping.doc.documentElement.attrs["data-avra-module"];
  const before = named();
  await swapping.events.say("built", "xyz");
  test("a page names its module at start and again once a swap lands", before === "abc" && named() === "xyz");
}

// The cache's snapshots: posted once a frame, newest only, never the same twice.
{
  let take = null;
  let off = 0;
  const frames = [];
  const queue = [];
  hudPosting({ api: { on: (fn) => { take = fn; }, off: () => { off++; } }, post: (f) => frames.push(f), raf: (cb) => queue.push(cb) });
  const drain = () => { while (queue.length) queue.shift()(); };
  take('{"v":1,"rows":[{"age_ms":5,"key":"/a"}]}');
  take('{"v":1,"rows":[{"age_ms":9,"key":"/a"}]}');
  test("a burst is one post, the newest", queue.length === 1 && (drain(), frames.length === 1 && frames[0].includes('"age_ms":9')));
  take('{"v":1,"rows":[{"age_ms":50,"key":"/a"}]}');
  drain();
  test("a frame that differs only in age is not posted again", frames.length === 1);
  take('{"v":1,"rows":[{"age_ms":51,"key":"/b"}]}');
  drain();
  test("a frame that says something new is posted", frames.length === 2 && frames[1].includes("/b"));
}

// The panel: a module of its own in a shadow root, told what the server says — including what came while it loaded.
{
  const doc = page();
  const made = [];
  doc.createElement = (tag) => { const el = stubElement(tag); made.push(el); return el; };
  const hosted = { shadow: null, appended: [] };
  const created = doc.createElement;
  doc.createElement = (tag) => {
    const el = created(tag);
    if (tag === "div" && hosted.shadow === null) el.attachShadow = () => { hosted.shadow = { children: [], append(...kids) { this.children.push(...kids); } }; return hosted.shadow; };
    return el;
  };
  const told = [];
  const events = stream();
  let release;
  const loading = new Promise((go) => { release = go; });
  const starting = panel({ doc, events, source: "/@dev/panel.wasm", start: async (source, options) => { await loading; return { tell: (text) => told.push(text), source, options }; } });
  events.say("cache", '{"tab":"aa","frame":{"v":1}}');
  test("what is told while the panel loads waits", told.length === 0);
  release();
  const running = await starting;
  events.say("cache", '{"tab":"bb","frame":{"v":1}}');
  test("and is told once it runs, then each after", told.length === 2 && told[0].includes('"tab":"aa"') && told[1].includes('"tab":"bb"'));
  test("the panel is a host element holding a shadow root with the module's mount and style, beside the app", doc.body.childNodes.some((el) => el.id === "avra-dev-panel") && hosted.shadow.children.length === 2);
  test("it starts its module from the dev server, with no shipped state", running.source === "/@dev/panel.wasm" && running.options.state.length === 0 && running.options.mount === hosted.shadow.children[1]);
}

console.log(`dev: ${passed}/${passed + failed}`);
process.exit(failed === 0 ? 0 : 1);
