// Proves the host applies every patch op and reports what the user did —
// and decides nothing: the frames below say what moved, what is a property
// and what an event says. Op numbers come from the generated table, so a
// wire the program changed is the wire this test speaks.
import { createApplier, createFetches, createFrames, createTimers, parseFrame, parseRequest, sendAnswer, sendEvent, run, HOST, ROWS, WIRE_VERSION } from "./bootstrap.js";
import { AFTER, NO_ID, OP, SAYS, TAGS } from "./wire.gen.js";
import v8 from "node:v8";
import vm from "node:vm";
import { dispatch, stubDocument, stubElement, textOf } from "./stub_dom.js";

// A fixture encoder — the CONSUMING side is what is under test; the
// producing side's exact bytes are pinned by the Avra wire test.
const i32 = (v) => [v & 255, (v >>> 8) & 255, (v >>> 16) & 255, (v >>> 24) & 255];
const utf8 = (s) => [...new TextEncoder().encode(s)];
const str = (s) => [...i32(utf8(s).length), ...utf8(s)];
// An id is a number; a fixture names elements by small ones.
const varint = (n) => (n < 128 ? [n] : [(n % 128) + 128, ...varint(Math.floor(n / 128))]);
const idBytes = (n) => varint(n + 1);
const afterBytes = (n) => varint(n === NO_ID ? AFTER.first : n + AFTER.sibling);
const create = (id, tag) => [OP.create, ...idBytes(id), ...varint(TAGS.indexOf(tag))];
const createText = (id, content) => [OP.create_text, ...idBytes(id), ...str(content)];
const place = (id, parent, after) => [OP.place, ...idBytes(id), ...idBytes(parent), ...afterBytes(after)];
const placeAtEnd = (id, parent) => [OP.place, ...idBytes(id), ...idBytes(parent), ...varint(AFTER.append)];
const remove = (id) => [OP.remove, ...idBytes(id)];
const setAttr = (id, name, value) => [OP.set_attr, ...idBytes(id), ...str(name), ...str(value)];
const dropAttr = (id, name) => [OP.drop_attr, ...idBytes(id), ...str(name)];
const setProp = (id, name, says, value) => [OP.set_prop, ...idBytes(id), ...str(name), ...i32(says), ...str(value)];
const setText = (id, content) => [OP.set_text, ...idBytes(id), ...str(content)];
const define = (kind, event, says, reads, prevents) => [OP.define, ...i32(kind), ...i32(says), ...str(event), ...str(reads), ...i32(prevents ? 1 : 0)];
const listen = (id, kind, event, says, reads, prevents) => [...define(kind, event, says, reads, prevents), OP.listen, ...idBytes(id), ...i32(kind), ...i32(says)];
const unlisten = (id, kind) => [OP.unlisten, ...idBytes(id), ...i32(kind)];
const setVar = (id, property, value) => [OP.set_var, ...idBytes(id), ...str(property), ...str(value)];
const dropVar = (id, property) => [OP.drop_var, ...idBytes(id), ...str(property)];
const style = (css) => [OP.style, ...str(css)];
const call = (id, verb) => [OP.call, ...idBytes(id), ...str(verb)];
const frame = (...recs) => Uint8Array.from([WIRE_VERSION, ...recs.flat()]);

let fails = 0;
let passes = 0;
function check(name, got, want) {
  const g = JSON.stringify(got), w = JSON.stringify(want);
  if (g !== w) { fails++; console.log(`✗ ${name}\n  got  ${g}\n  want ${w}`); }
  else { passes++; console.log(`✓ ${name}`); }
}
const page = () => {
  const mount = stubElement("root");
  const sent = [];
  const styleEl = { textContent: "" };
  const doc = stubDocument();
  const apply = createApplier(doc, mount, (who, kind, said) => sent.push([who, kind, said]), styleEl);
  return { mount, sent, styleEl, apply, doc };
};
const tags = (n) => n.childNodes.map((c) => c.tagName);

// ── create, create_text, place ──
const a = page();
a.apply(frame(create(0, "div"), create(1, "span"), createText(2, "hi"), place(2, 1, NO_ID), place(1, 0, NO_ID), place(0, NO_ID, NO_ID)));
const div = a.mount.childNodes[0];
check("create and place build the page", [div.tagName, tags(div), textOf(div)], ["div", ["span"], "hi"]);

a.apply(frame(create(3, "article"), place(3, 0, 1), create(4, "label"), place(4, 0, NO_ID)));
check("place puts an element after a sibling, or first", tags(div), ["label", "span", "article"]);

const span = div.childNodes[1];
a.apply(frame(place(1, 0, 3)));
check("place moves an element that is already there — the same element", [tags(div), div.childNodes[2] === span], [["label", "article", "span"], true]);

// ── set_text ──
a.apply(frame(setText(2, "bye")));
check("set_text rewrites a run of text", textOf(span), "bye");

// ── set_attr, drop_attr ──
a.apply(frame(setAttr(0, "class", "gap-m"), setAttr(0, "title", "a b")));
check("set_attr writes an attribute, its value as given", div.attrs, { class: "gap-m", title: "a b" });
a.apply(frame(dropAttr(0, "title")));
check("drop_attr removes one", div.attrs, { class: "gap-m" });

// ── set_var, drop_var ──
a.apply(frame(setVar(0, "--w", "8px"), setVar(0, "--h", "3px")));
check("set_var writes a custom property through the style object, never an attribute", [div.vars, div.attrs], [{ "--w": "8px", "--h": "3px" }, { class: "gap-m" }]);
a.apply(frame(setVar(0, "--w", "9px"), dropVar(0, "--h")));
check("set_var rewrites one and drop_var removes one", div.vars, { "--w": "9px" });

// ── remove ──
a.apply(frame(remove(1)));
check("remove takes an element off the page", tags(div), ["label", "article"]);
let gone = "";
try { a.apply(frame(setText(2, "x"))); } catch (e) { gone = e.message; }
check("and everything under it is forgotten", gone, "a patch names element 2, which is not on the page");

// ── an empty frame ──
const before = JSON.stringify(tags(div));
a.apply(frame());
check("a frame of the version alone touches nothing", JSON.stringify(tags(div)), before);

// ── style ──
a.apply(frame(style("a{color:red}")));
check("style fills the style element", a.styleEl.textContent, "a{color:red}");

// ── set_prop ──
const b = page();
b.apply(frame(create(0, "input"), setProp(0, "value", SAYS.text, "Ann"), setProp(0, "checked", SAYS.flag, "1"), place(0, NO_ID, NO_ID)));
const input = b.mount.childNodes[0];
check("set_prop writes a property as the value it means", [input.value, input.checked, input.attrs], ["Ann", true, {}]);
b.apply(frame(setProp(0, "checked", SAYS.flag, "")));
check("a flag at rest is false", input.checked, false);
let writes = 0;
let held = "typed";
Object.defineProperty(input, "value", { get: () => held, set: (v) => { writes++; held = v; } });
b.apply(frame(setProp(0, "value", SAYS.text, "typed")));
check("a property that already holds the value is not written — the caret stays", writes, 0);
b.apply(frame(setProp(0, "value", SAYS.text, "")));
check("and one that differs is", [writes, held], [1, ""]);

// ── what the page keeps on an element is the page's ──
// A list of two rows, an input in each, on a page that can carry an
// element (`moveBefore`) or one that cannot.
const listed = (carries) => {
  const mount = stubElement("root");
  const doc = stubDocument({ carries });
  const apply = createApplier(doc, mount);
  apply(frame(create(0, "ul"), create(1, "li"), create(2, "input"), place(2, 1, NO_ID), place(1, 0, NO_ID), create(3, "li"), create(4, "input"), place(4, 3, NO_ID), place(3, 0, 1), place(0, NO_ID, NO_ID)));
  const ul = mount.childNodes[0];
  return { doc, apply, ul, first: ul.childNodes[0], second: ul.childNodes[1] };
};
// A user in the first row's input: focused, the caret mid-text, the row
// scrolled, and text no patch ever wrote.
const used = (at) => {
  const input = at.first.childNodes[0];
  input.value = "typed";
  input.focus();
  input.setSelectionRange(2, 4, "forward");
  at.first.scrollTop = 40;
  return input;
};
const state = (at, input) => [at.doc.activeElement === input, input.selectionStart, input.selectionEnd, input.selectionDirection, input.value, at.first.scrollTop];

const k = listed(true);
const kin = used(k);
k.apply(frame(setAttr(0, "class", "wide"), setAttr(1, "title", "t"), create(5, "li"), place(5, 0, 3), setProp(4, "value", SAYS.text, "other")));
check("patches that name other things leave a used control as the user left it", state(k, kin), [true, 2, 4, "forward", "typed", 40]);
k.apply(frame(place(1, 0, 5)));
check("a row carried to another place is the same row, in its new place", [k.ul.childNodes.map((c) => c.__avra_id), k.ul.childNodes[2] === k.first], [[3, 5, 1], true]);
check("on a page that can carry it, a moved row keeps its focus, its caret, its text and its scroll", state(k, kin), [true, 2, 4, "forward", "typed", 40]);

const u = listed(false);
const uin = used(u);
u.apply(frame(place(1, 0, 3)));
check("on a page that cannot, the focus and the caret are put back and the text stays", state(u, uin).slice(0, 5), [true, 2, 4, "forward", "typed"]);
check("and how far it was scrolled is lost: that page takes the row off to move it", u.first.scrollTop, 0);

const s = listed(false);
const sin = used(s);
let moves = 0;
const really = s.ul.insertBefore;
s.ul.insertBefore = function (c, at) { moves++; return really.call(this, c, at); };
s.apply(frame(place(1, 0, NO_ID), place(3, 0, 1)));
check("an element placed where it already stands is not touched", [moves, state(s, sin)], [0, [true, 2, 4, "forward", "typed", 40]]);
s.apply(frame(remove(3)));
check("a sibling leaving takes nothing from it", state(s, sin), [true, 2, 4, "forward", "typed", 40]);
s.apply(frame(remove(1)));
check("an element that leaves takes its focus with it", s.doc.activeElement, null);

// ── a shortcut: a key stands hidden, saying its chord, and is pressed by the keydown that meets it ──
const sc = page();
const keyed = (id, chord, kind) => [create(id, "div"), setAttr(id, "hidden", ""), setAttr(id, "data-avra-chord", chord), listen(id, kind, "keydown", SAYS.nothing, "", false)];
sc.apply(frame(
  create(0, "div"), place(0, NO_ID, NO_ID), create(1, "input"), placeAtEnd(1, 0), ...keyed(2, "c/KeyS/s", 7), placeAtEnd(2, 0),
  ...keyed(7, "c/Slash//", 7), placeAtEnd(7, 0), ...keyed(8, "c/Period/.", 7), placeAtEnd(8, 0),
  create(3, "div"), placeAtEnd(3, NO_ID), create(4, "input"), placeAtEnd(4, 3), ...keyed(5, "c/KeyS/s", 7), placeAtEnd(5, 3),
  ...keyed(6, "//F5", 7), placeAtEnd(6, NO_ID),
));
const inside = sc.mount.childNodes[0].childNodes[0];
const aside = sc.mount.childNodes[1].childNodes[0];
const body = stubElement("body");
const stroke = (target, ev) => {
  let prevented = false;
  dispatch(sc.doc, target, "keydown", { preventDefault: () => { prevented = true; }, ctrlKey: false, altKey: false, shiftKey: false, metaKey: false, code: "", ...ev });
  return prevented;
};
const heard = () => sc.sent.splice(0).map((s) => s[0]);
check("a keydown that meets a key's chord presses it, and the browser's answer is stopped", [stroke(inside, { key: "s", ctrlKey: true }), heard()], [true, [2]]);
check("a chord that is not the key's presses nothing and stops nothing", [stroke(inside, { key: "a", ctrlKey: true }), heard()], [false, []]);
check("the key without its modifier presses nothing", [stroke(inside, { key: "s" }), heard()], [false, []]);
check("an extra modifier is another chord", [stroke(inside, { key: "s", ctrlKey: true, shiftKey: true }), stroke(inside, { key: "s", ctrlKey: true, metaKey: true }), heard()], [false, false, []]);
check("a letter meets its chord in either case, since shift is a modifier of its own", [stroke(inside, { key: "S", ctrlKey: true }), heard()], [true, [2]]);
check("a key is pressed only from within what holds it: the other holder's key answers there", [stroke(aside, { key: "s", ctrlKey: true }), heard()], [true, [5]]);
check("a key held at the page's root is live everywhere under it", [stroke(inside, { key: "F5" }), stroke(aside, { key: "F5" }), heard()], [true, true, [6, 6]]);
check("a keydown heard by no key is left alone", [stroke(inside, { key: "q" }), heard()], [false, []]);
check("with nothing focused the keydown lands on the body, and the root's key answers it", [stroke(body, { key: "F5" }), heard()], [true, [6]]);
check("and a key held below the root does not", [stroke(body, { key: "s", ctrlKey: true }), heard()], [false, []]);
check("a layout whose key is another script meets a letter chord by the key's place", [stroke(inside, { key: "ы", code: "KeyS", ctrlKey: true }), stroke(inside, { key: "σ", code: "KeyS", ctrlKey: true }), heard()], [true, true, [2, 2]]);
check("and a punctuation chord by its place too", [stroke(inside, { key: "ю", code: "Period", ctrlKey: true }), stroke(inside, { key: "/", code: "Slash", ctrlKey: true }), heard()], [true, true, [8, 7]]);
check("a key of another script at another place is no chord of that key", [stroke(inside, { key: "ы", code: "KeyA", ctrlKey: true }), heard()], [false, []]);

// ── listen, unlisten, the echo ──
const c = page();
c.apply(frame(create(0, "button"), listen(0, 1, "click", SAYS.nothing, "", false), place(0, NO_ID, NO_ID)));
const button = c.mount.childNodes[0];
dispatch(c.mount, button, "click");
check("an event the page was told to hear is echoed: who, the kind as given, nothing said", c.sent[0], [0, 1, null]);

c.apply(frame(create(5, "input"), listen(5, 2, "input", SAYS.text, "value", false), place(5, NO_ID, 0)));
const field = c.mount.childNodes[1];
field.value = "typed here";
dispatch(c.mount, field, "input");
check("an event that says text sends the property the patch named", c.sent[1], [5, 2, { says: SAYS.text, value: "typed here" }]);

c.apply(frame(create(6, "input"), listen(6, 3, "change", SAYS.flag, "checked", false), place(6, NO_ID, 5)));
const box = c.mount.childNodes[2];
box.checked = true;
dispatch(c.mount, box, "change");
check("an event that says a flag sends it", c.sent[2], [6, 3, { says: SAYS.flag, value: true }]);

c.apply(frame(unlisten(6, 3), listen(6, 3, "change", SAYS.number, "value", false)));
box.value = "42";
dispatch(c.mount, box, "change");
check("an event heard anew says what it is now asked", c.sent[3], [6, 3, { says: SAYS.number, value: 42 }]);
box.value = "not a number";
dispatch(c.mount, box, "change");
check("a control that cannot say a number says nothing", c.sent[4], [6, 3, null]);

c.apply(frame(unlisten(0, 1)));
check("unlisten removes the listener", c.apply.ears(0).length > 0, false);

c.apply(frame(create(7, "form"), listen(7, 4, "submit", SAYS.nothing, "", true), place(7, NO_ID, NO_ID)));
let prevented = 0;
dispatch(c.mount, c.mount.childNodes[0], "submit", { preventDefault: () => { prevented++; } });
check("an event the patch says to stop is stopped, and echoed", [prevented, c.sent[5]], [1, [7, 4, null]]);
let kept = 0;
c.apply(frame(listen(5, 1, "click", SAYS.nothing, "", false)));
dispatch(c.mount, field, "click", { preventDefault: () => { kept++; } });
check("an event it does not say to stop keeps its own answer", kept, 0);

// ── a verb of the element's own ──
const d = page();
d.apply(frame(create(0, "dialog"), place(0, NO_ID, NO_ID)));
let shown = 0;
d.mount.childNodes[0].showModal = () => { shown++; };
d.apply(frame(call(0, "showModal")));
check("a call asks the element for the verb the patch named", shown, 1);
let verbless = "";
try { d.apply(frame(call(0, "levitate"))); } catch (e) { verbless = e.message; }
check("a verb the element does not have refuses by name", verbless, "a patch calls levitate on element 0, which has no such verb");

// ── the wire itself ──
let refused = false;
try { parseFrame(Uint8Array.from([WIRE_VERSION + 1])); } catch { refused = true; }
check("a frame of another VERSION refuses", refused, true);
let unknown = "";
try { parseFrame(Uint8Array.from([WIRE_VERSION, 200])); } catch (e) { unknown = e.message; }
check("an op the table does not hold refuses", unknown, "unknown patch op 200");
check("an id past 32 bits reads whole", parseFrame(frame(create(5000000000, "div")))[0].id, 5000000000);
check("no id reads as no id", parseFrame(frame(place(1, NO_ID, NO_ID)))[0].after, NO_ID);
// ── a removed element is let go ──
const churn = page();
const rows = 10000;
churn.apply(frame(create(0, "ul"), place(0, NO_ID, NO_ID), ...Array.from({ length: rows }, (_, k) => [create(k + 1, "li"), placeAtEnd(k + 1, 0), listen(k + 1, 1, "click", SAYS.nothing, "", false)]).flat()));
check("the page holds the list and its rows, each hearing", churn.apply.held(), { nodes: rows + 1, hears: rows });
const watched = new WeakRef(churn.mount.childNodes[0].childNodes[7]);
churn.apply(frame(remove(0)));
check("removing the list lets go of every row's slot and hearing", churn.apply.held(), { nodes: 0, hears: 0 });
check("and a removed element's id names nothing", (() => { try { churn.apply(frame(setAttr(5, "class", "x"))); return "applied"; } catch (e) { return e.message; } })(), "a patch names element 5, which is not on the page");
v8.setFlagsFromString("--expose-gc");
const collect = vm.runInNewContext("gc");
await new Promise((resolve) => setTimeout(resolve, 0));
collect();
check("a row taken off the page is collected, not kept by the host", watched.deref(), undefined);

const edges = [0, 127, 128, 16383, 16384, 2097151, 2097152, 2 ** 40];
check("ids at the seven-bit edges read whole, in the bytes of one more than the id", [parseFrame(frame(...edges.map((n) => remove(n)))).map((p) => p.id), edges.map((n) => idBytes(n).length)], [edges, [1, 2, 2, 3, 3, 4, 4, 6]]);
const ended = page();
ended.apply(frame(create(0, "div"), place(0, NO_ID, NO_ID), create(1, "span"), placeAtEnd(1, 0), create(2, "a"), placeAtEnd(2, 0), create(3, "li"), place(3, 0, NO_ID)));
check("a place that says the end of the run goes last, and one that says first goes first", tags(ended.mount.childNodes[0]), ["li", "span", "a"]);
check("every op the table holds has a fixture here", Object.keys(OP).sort(), ["call", "create", "create_text", "define", "drop_attr", "drop_var", "listen", "place", "remove", "set_attr", "set_prop", "set_text", "set_var", "style", "unlisten"]);

// ── the echo's seam ──
// A program that hands out each seat at 32, GROWING its memory as it does:
// a host that viewed the memory before asking would write into the old one.
const calls = [];
const asked = [];
const fakeMod = {
  memory: { buffer: new ArrayBuffer(0) },
  [HOST.seat]: (room) => { asked.push(room); fakeMod.memory.buffer = new ArrayBuffer(32 + Number(room)); return 32n; },
  [HOST.event]: (who, what, tag, num, len) => calls.push([who, what, tag, num, len]),
};
const seat = (at, len) => new TextDecoder().decode(new Uint8Array(fakeMod.memory.buffer, at, len));
sendEvent(fakeMod, 7, 1, null);
check("nothing said sends who, the kind and the nothing tag", calls[0].map(String), ["7", "1", String(SAYS.nothing), "0", "0"]);
sendEvent(fakeMod, 5000000000, 1, { says: SAYS.number, value: 42 });
check("a number sends its value, under an id of any size", calls[1].map(String), ["5000000000", "1", String(SAYS.number), "42", "0"]);
check("an event that says no text asks for no seat", asked.length, 0);
sendEvent(fakeMod, 0, 1, { says: SAYS.text, value: "hi" });
check("text is written into the seat the program handed out", seat(32, 2), "hi");
check("text sends its length", calls[2].map(String), ["0", "1", String(SAYS.text), "0", "2"]);
sendEvent(fakeMod, 0, 3, { says: SAYS.flag, value: true });
check("a flag sends one", calls[3].map(String), ["0", "3", String(SAYS.flag), "1", "0"]);
const long = "é".repeat(5000);
sendEvent(fakeMod, 0, 2, { says: SAYS.text, value: long });
check("a seat is asked for by the text's own octets, however many", asked.map(String), ["2", "10000"]);
check("a long text arrives whole", [seat(32, 10000) === long, String(calls[4][4])], [true, "10000"]);
sendEvent(fakeMod, 0, 2, { says: SAYS.text, value: "" });
check("an empty text is text, of no octets", calls[5].map(String), ["0", "2", String(SAYS.text), "0", "0"]);

// ── the page's timers ──
// A clock a test turns by hand: a timer is due at a time and fires when the
// clock reaches it; an interval fires again each period.
const clockAt = () => {
  const due = new Map();
  let now = 0;
  let next = 1;
  return {
    setTimeout: (fn, ms) => { due.set(next, { at: now + ms, fn, every: null }); return next++; },
    setInterval: (fn, ms) => { due.set(next, { at: now + ms, fn, every: ms }); return next++; },
    clearTimeout: (h) => due.delete(h),
    clearInterval: (h) => due.delete(h),
    advance: (ms) => {
      const to = now + ms;
      for (;;) {
        const ready = [...due.entries()].filter(([, t]) => t.at <= to).sort((a, b) => a[1].at - b[1].at)[0];
        if (!ready) break;
        const [h, t] = ready;
        now = t.at;
        if (t.every === null) due.delete(h); else t.at += t.every;
        t.fn();
      }
      now = to;
    },
    pending: () => due.size,
  };
};
{
  const clock = clockAt();
  const fired = [];
  const timers = createTimers(clock, (t) => fired.push(t));
  timers.arm(1n, 10n, 0n);
  timers.arm(2n, 10n, 1n);
  clock.advance(9);
  check("a timer does not fire before its time", fired, []);
  clock.advance(1);
  check("a one-shot and a period fire at their time, in the order armed", fired, [1, 2]);
  check("a one-shot forgets itself, a period stays", [timers.count(), clock.pending()], [1, 1]);
  clock.advance(25);
  check("a period fires every period and a one-shot never again", fired, [1, 2, 2, 2]);
  timers.disarm(2n);
  clock.advance(100);
  check("a disarmed period never fires again, and nothing is left on the clock", [fired.length, timers.count(), clock.pending()], [4, 0, 0]);
  timers.arm(3n, 5n, 0n);
  timers.disarm(3n);
  timers.disarm(3n);
  timers.disarm(99n);
  clock.advance(10);
  check("a disarmed one-shot never fires; disarming twice, or a stranger, says nothing", [fired.length, timers.count()], [4, 0]);
  check("the rows a page answers are named by the generated table", Object.keys(ROWS).sort(), ["abort", "arm", "disarm", "frame", "get", "next_paint"]);
}

// ── the page's requests ──
// A request frame as the program writes it (`request_frame`): the version, the
// method's word, the URL, the wait (-1: none), the fields, the body's content
// type and its octets.
const requestFrame = ({ method = "GET", url, timeoutMs = -1, headers = [], kind = "", body = [] }) => Uint8Array.from([
  WIRE_VERSION, ...str(method), ...str(url), ...i32(timeoutMs), ...i32(headers.length), ...headers.flatMap(([n, v]) => [...str(n), ...str(v)]), ...str(kind), ...i32(body.length), ...body,
]);
{
  const r = parseRequest(requestFrame({ method: "POST", url: "/a?b=1", timeoutMs: 250, headers: [["accept", "text/plain"]], kind: "application/json", body: utf8("{}") }));
  check("a request frame reads back: method, url, wait, fields, content type, octets", [r.method, r.url, r.timeoutMs, r.headers, r.kind, new TextDecoder().decode(r.body)], ["POST", "/a?b=1", 250, [["accept", "text/plain"]], "application/json", "{}"]);
  const e = parseRequest(requestFrame({ url: "/x" }));
  check("a bare get has no wait, no fields and no body", [e.method, e.timeoutMs, e.headers.length, e.kind, e.body.length], ["GET", -1, 0, "", 0]);
  let refused = "";
  try { parseRequest(Uint8Array.from([WIRE_VERSION + 1, 0, 0, 0, 0])); } catch (err) { refused = err.message; }
  check("a request of another wire version is refused by name", refused.startsWith("unsupported wire version"), true);
}
{
  // A fetch a test answers by hand: each call is a promise the test settles.
  const calls = [];
  const fetchFn = (url, init) => new Promise((resolve, reject) => {
    const call = { url, init, resolve, reject };
    calls.push(call);
    init.signal.addEventListener("abort", () => reject(Object.assign(new Error("aborted"), { name: "AbortError" })));
  });
  const reply = (status, text) => ({ status, arrayBuffer: async () => new TextEncoder().encode(text).buffer });
  const heard = [];
  const clock = clockAt();
  const fetches = createFetches(fetchFn, (t, status, octets) => heard.push([t, status, new TextDecoder().decode(octets)]), clock);
  const settle = async () => { for (let k = 0; k < 6; k++) await Promise.resolve(); };

  fetches.get(1n, requestFrame({ method: "POST", url: "/p", headers: [["x-id", "7"]], kind: "text/plain; charset=utf-8", body: utf8("hi") }));
  await settle();
  check("a request is sent with its method, fields, content type and body", [calls[0].url, calls[0].init.method, calls[0].init.headers, new TextDecoder().decode(calls[0].init.body)], ["/p", "POST", { "x-id": "7", "content-type": "text/plain; charset=utf-8" }, "hi"]);
  calls[0].resolve(reply(200, "ok"));
  await settle();
  check("an answer crosses with its status and octets, and the request is forgotten", [heard, fetches.count()], [[[1, 200, "ok"]], 0]);

  fetches.get(2n, requestFrame({ url: "/g" }));
  await settle();
  check("a get carries no body", calls[1].init.body === undefined, true);
  fetches.abort(2n);
  calls[1].resolve(reply(200, "late"));
  await settle();
  check("an aborted request is aborted at the host and a late answer is dropped", [calls[1].init.signal.aborted, heard.length, fetches.count()], [true, 1, 0]);

  fetches.get(3n, requestFrame({ url: "/n" }));
  await settle();
  calls[2].reject(new Error("offline"));
  await settle();
  check("a failure crosses as status -1 and its words", heard[1], [3, -1, "offline"]);

  fetches.get(4n, requestFrame({ url: "/t", timeoutMs: 20 }));
  await settle();
  clock.advance(25);
  await settle();
  check("a request past its wait answers -1 and is aborted", [heard[2], calls[3].init.signal.aborted], [[4, -1, "the request timed out"], true]);

  fetches.get(5n, requestFrame({ url: "/two" }));
  await settle();
  calls[4].resolve(reply(204, ""));
  calls[4].resolve(reply(500, "again"));
  await settle();
  check("a request answers once", heard.filter((h) => h[0] === 5).length, 1);
  fetches.abort(99n);
  check("aborting a stranger says nothing", fetches.count(), 0);

  // the answer crosses into the program through the seat
  const seen = [];
  const mod = { memory: { buffer: new ArrayBuffer(64) }, [HOST.seat]: (room) => { seen.push(["seat", Number(room)]); return 16n; }, [HOST.answered]: (t, st, len) => seen.push([Number(t), Number(st), Number(len)]) };
  sendAnswer(mod, 9, 201, new TextEncoder().encode("abc"));
  check("an answer writes its octets into the seat, then names the token, status and length", [seen, new TextDecoder().decode(new Uint8Array(mod.memory.buffer, 16, 3))], [[["seat", 3], [9, 201, 3]], "abc"]);
  check("the rows a page answers include the request rows", ["get", "abort"].every((k) => typeof ROWS[k] === "string"), true);
}

// ── the page's frames ──
{
  const queue = [];
  const painted = [];
  const frames = createFrames((cb) => queue.push(cb), () => painted.push(1));
  frames.next();
  frames.next();
  frames.next();
  check("asking for a frame again before it comes asks the display once", [queue.length, frames.waiting()], [1, true]);
  queue.shift()();
  check("the display's frame calls the program once", [painted.length, frames.waiting()], [1, false]);
  frames.next();
  check("a new ask after the frame is a new frame", queue.length, 1);
}

// ── a page runs a program that mounts ──
const empty = Uint8Array.from([0, 97, 115, 109, 1, 0, 0, 0]);
let lacking = "";
try { await run(empty, { document: stubDocument(), mount: stubElement("root"), wasi: () => ({}) }); } catch (e) { lacking = e.message; }
check("a module that mounts nothing refuses by the names it lacks", lacking.startsWith(`the module exports no ${HOST.entry}, ${HOST.event}, ${HOST.seat}`), true);

console.log(fails === 0 ? `bootstrap: ${passes}/${passes}` : `bootstrap: ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
