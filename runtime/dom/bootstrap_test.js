// Proves the host applies every patch op and reports what the user did —
// and decides nothing: the frames below say what moved, what is a property
// and what an event says. Op numbers come from the generated table, so a
// wire the program changed is the wire this test speaks.
import { createApplier, parseFrame, sendEvent, run, HOST, WIRE_VERSION } from "./bootstrap.js";
import { NO_ID, OP, SAYS } from "./wire.gen.js";
import { stubDocument, stubElement, textOf } from "./stub_dom.js";

// A fixture encoder — the CONSUMING side is what is under test; the
// producing side's exact bytes are pinned by the Avra wire test.
const i32 = (v) => [v & 255, (v >>> 8) & 255, (v >>> 16) & 255, (v >>> 24) & 255];
const utf8 = (s) => [...new TextEncoder().encode(s)];
const str = (s) => [...i32(utf8(s).length), ...utf8(s)];
// An id is a number; a fixture names elements by small ones.
const idBytes = (n) => [...i32(n >>> 0), ...i32(n < 0 ? -1 : Math.floor(n / 4294967296))];
const create = (id, tag) => [OP.create, ...idBytes(id), ...str(tag)];
const createText = (id, content) => [OP.create_text, ...idBytes(id), ...str(content)];
const place = (id, parent, after) => [OP.place, ...idBytes(id), ...idBytes(parent), ...idBytes(after)];
const remove = (id) => [OP.remove, ...idBytes(id)];
const setAttr = (id, name, value) => [OP.set_attr, ...idBytes(id), ...str(name), ...str(value)];
const dropAttr = (id, name) => [OP.drop_attr, ...idBytes(id), ...str(name)];
const setProp = (id, name, says, value) => [OP.set_prop, ...idBytes(id), ...str(name), ...i32(says), ...str(value)];
const setText = (id, content) => [OP.set_text, ...idBytes(id), ...str(content)];
const listen = (id, kind, event, says, reads, prevents) => [OP.listen, ...idBytes(id), ...i32(kind), ...str(event), ...i32(says), ...str(reads), ...i32(prevents ? 1 : 0)];
const unlisten = (id, kind) => [OP.unlisten, ...idBytes(id), ...i32(kind)];
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
  const apply = createApplier(stubDocument(), mount, (who, kind, said) => sent.push([who, kind, said]), styleEl);
  return { mount, sent, styleEl, apply };
};
const tags = (n) => n.childNodes.map((c) => c.tagName);

// ── create, create_text, place ──
const a = page();
a.apply(frame(create(0, "div"), create(1, "span"), createText(2, "hi"), place(2, 1, NO_ID), place(1, 0, NO_ID), place(0, NO_ID, NO_ID)));
const div = a.mount.childNodes[0];
check("create and place build the page", [div.tagName, tags(div), textOf(div)], ["div", ["span"], "hi"]);

a.apply(frame(create(3, "p"), place(3, 0, 1), create(4, "b"), place(4, 0, NO_ID)));
check("place puts an element after a sibling, or first", tags(div), ["b", "span", "p"]);

const span = div.childNodes[1];
a.apply(frame(place(1, 0, 3)));
check("place moves an element that is already there — the same element", [tags(div), div.childNodes[2] === span], [["b", "p", "span"], true]);

// ── set_text ──
a.apply(frame(setText(2, "bye")));
check("set_text rewrites a run of text", textOf(span), "bye");

// ── set_attr, drop_attr ──
a.apply(frame(setAttr(0, "class", "gap-m"), setAttr(0, "title", "a b")));
check("set_attr writes an attribute, its value as given", div.attrs, { class: "gap-m", title: "a b" });
a.apply(frame(dropAttr(0, "title")));
check("drop_attr removes one", div.attrs, { class: "gap-m" });

// ── remove ──
a.apply(frame(remove(1)));
check("remove takes an element off the page", tags(div), ["b", "p"]);
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

// ── listen, unlisten, the echo ──
const c = page();
c.apply(frame(create(0, "button"), listen(0, 1, "click", SAYS.nothing, "", false), place(0, NO_ID, NO_ID)));
const button = c.mount.childNodes[0];
button.listeners.get("click")();
check("an event the page was told to hear is echoed: who, the kind as given, nothing said", c.sent[0], [0, 1, null]);

c.apply(frame(create(5, "input"), listen(5, 2, "input", SAYS.text, "value", false), place(5, NO_ID, 0)));
const field = c.mount.childNodes[1];
field.value = "typed here";
field.listeners.get("input")();
check("an event that says text sends the property the patch named", c.sent[1], [5, 2, { says: SAYS.text, value: "typed here" }]);

c.apply(frame(create(6, "input"), listen(6, 3, "change", SAYS.flag, "checked", false), place(6, NO_ID, 5)));
const box = c.mount.childNodes[2];
box.checked = true;
box.listeners.get("change")();
check("an event that says a flag sends it", c.sent[2], [6, 3, { says: SAYS.flag, value: true }]);

c.apply(frame(unlisten(6, 3), listen(6, 3, "change", SAYS.number, "value", false)));
box.value = "42";
box.listeners.get("change")();
check("an event heard anew says what it is now asked", c.sent[3], [6, 3, { says: SAYS.number, value: 42 }]);
box.value = "not a number";
box.listeners.get("change")();
check("a control that cannot say a number says nothing", c.sent[4], [6, 3, null]);

c.apply(frame(unlisten(0, 1)));
check("unlisten removes the listener", button.listeners.has("click"), false);

c.apply(frame(create(7, "form"), listen(7, 4, "submit", SAYS.nothing, "", true), place(7, NO_ID, NO_ID)));
let prevented = 0;
c.mount.childNodes[0].listeners.get("submit")({ preventDefault: () => { prevented++; } });
check("an event the patch says to stop is stopped, and echoed", [prevented, c.sent[5]], [1, [7, 4, null]]);
let kept = 0;
c.apply(frame(listen(5, 1, "click", SAYS.nothing, "", false)));
field.listeners.get("click")({ preventDefault: () => { kept++; } });
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
check("every op the table holds has a fixture here", Object.keys(OP).sort(), ["call", "create", "create_text", "drop_attr", "listen", "place", "remove", "set_attr", "set_prop", "set_text", "style", "unlisten"]);

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

// ── a page runs a program that mounts ──
const empty = Uint8Array.from([0, 97, 115, 109, 1, 0, 0, 0]);
let lacking = "";
try { await run(empty, { document: stubDocument(), mount: stubElement("root"), wasi: () => ({}) }); } catch (e) { lacking = e.message; }
check("a module that mounts nothing refuses by the names it lacks", lacking.startsWith(`the module exports no ${HOST.entry}, ${HOST.event}, ${HOST.seat}`), true);

console.log(fails === 0 ? `bootstrap: ${passes}/${passes}` : `bootstrap: ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
