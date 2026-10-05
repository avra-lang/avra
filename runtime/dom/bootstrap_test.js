// Proves the host applies every patch op and reports what the user did —
// and decides nothing: the frames below say what moved, what is a property
// and what an event says. Op numbers come from the generated table, so a
// wire the program changed is the wire this test speaks.
import { createApplier, parseFrame, sendEvent, WIRE_VERSION } from "./bootstrap.js";
import { OP, SAYS } from "./wire.gen.js";
import { stubDocument, stubElement, textOf } from "./stub_dom.js";

// A fixture encoder — the CONSUMING side is what is under test; the
// producing side's exact bytes are pinned by the Avra wire test.
const i32 = (v) => [v & 255, (v >>> 8) & 255, (v >>> 16) & 255, (v >>> 24) & 255];
const utf8 = (s) => [...new TextEncoder().encode(s)];
const str = (s) => [...i32(utf8(s).length), ...utf8(s)];
const create = (id, tag) => [OP.create, ...str(id), ...str(tag)];
const createText = (id, content) => [OP.create_text, ...str(id), ...str(content)];
const place = (id, parent, after) => [OP.place, ...str(id), ...str(parent), ...str(after)];
const remove = (id) => [OP.remove, ...str(id)];
const setAttr = (id, name, value) => [OP.set_attr, ...str(id), ...str(name), ...str(value)];
const dropAttr = (id, name) => [OP.drop_attr, ...str(id), ...str(name)];
const setProp = (id, name, says, value) => [OP.set_prop, ...str(id), ...str(name), ...i32(says), ...str(value)];
const setText = (id, content) => [OP.set_text, ...str(id), ...str(content)];
const listen = (id, kind, event, says, reads, prevents) => [OP.listen, ...str(id), ...i32(kind), ...str(event), ...i32(says), ...str(reads), ...i32(prevents ? 1 : 0)];
const unlisten = (id, kind) => [OP.unlisten, ...str(id), ...i32(kind)];
const style = (css) => [OP.style, ...str(css)];
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
a.apply(frame(create("0", "div"), create("0/0", "span"), createText("0/0/+text", "hi"), place("0/0/+text", "0/0", ""), place("0/0", "0", ""), place("0", "", "")));
const div = a.mount.childNodes[0];
check("create and place build the page", [div.tagName, tags(div), textOf(div)], ["div", ["span"], "hi"]);

a.apply(frame(create("0/1", "p"), place("0/1", "0", "0/0"), create("0/2", "b"), place("0/2", "0", "")));
check("place puts an element after a sibling, or first", tags(div), ["b", "span", "p"]);

const span = div.childNodes[1];
a.apply(frame(place("0/0", "0", "0/1")));
check("place moves an element that is already there — the same element", [tags(div), div.childNodes[2] === span], [["b", "p", "span"], true]);

// ── set_text ──
a.apply(frame(setText("0/0/+text", "bye")));
check("set_text rewrites a run of text", textOf(span), "bye");

// ── set_attr, drop_attr ──
a.apply(frame(setAttr("0", "class", "gap-m"), setAttr("0", "title", "a b")));
check("set_attr writes an attribute, its value as given", div.attrs, { class: "gap-m", title: "a b" });
a.apply(frame(dropAttr("0", "title")));
check("drop_attr removes one", div.attrs, { class: "gap-m" });

// ── remove ──
a.apply(frame(remove("0/0")));
check("remove takes an element off the page", tags(div), ["b", "p"]);
let gone = "";
try { a.apply(frame(setText("0/0/+text", "x"))); } catch (e) { gone = e.message; }
check("and everything under it is forgotten", gone, "a patch names `0/0/+text`, which is not on the page");

// ── an empty frame ──
const before = JSON.stringify(tags(div));
a.apply(frame());
check("a frame of the version alone touches nothing", JSON.stringify(tags(div)), before);

// ── style ──
a.apply(frame(style("a{color:red}")));
check("style fills the style element", a.styleEl.textContent, "a{color:red}");

// ── set_prop ──
const b = page();
b.apply(frame(create("0", "input"), setProp("0", "value", SAYS.text, "Ann"), setProp("0", "checked", SAYS.flag, "1"), place("0", "", "")));
const input = b.mount.childNodes[0];
check("set_prop writes a property as the value it means", [input.value, input.checked, input.attrs], ["Ann", true, {}]);
b.apply(frame(setProp("0", "checked", SAYS.flag, "")));
check("a flag at rest is false", input.checked, false);
let writes = 0;
let held = "typed";
Object.defineProperty(input, "value", { get: () => held, set: (v) => { writes++; held = v; } });
b.apply(frame(setProp("0", "value", SAYS.text, "typed")));
check("a property that already holds the value is not written — the caret stays", writes, 0);
b.apply(frame(setProp("0", "value", SAYS.text, "")));
check("and one that differs is", [writes, held], [1, ""]);

// ── listen, unlisten, the echo ──
const c = page();
c.apply(frame(create("0", "button"), listen("0", 1, "click", SAYS.nothing, "", false), place("0", "", "")));
const button = c.mount.childNodes[0];
button.listeners.get("click")();
check("an event the page was told to hear is echoed: who, the kind as given, nothing said", c.sent[0], ["0", 1, null]);

c.apply(frame(create("1", "input"), listen("1", 2, "input", SAYS.text, "value", false), place("1", "", "0")));
const field = c.mount.childNodes[1];
field.value = "typed here";
field.listeners.get("input")();
check("an event that says text sends the property the patch named", c.sent[1], ["1", 2, { says: SAYS.text, value: "typed here" }]);

c.apply(frame(create("2", "input"), listen("2", 3, "change", SAYS.flag, "checked", false), place("2", "", "1")));
const box = c.mount.childNodes[2];
box.checked = true;
box.listeners.get("change")();
check("an event that says a flag sends it", c.sent[2], ["2", 3, { says: SAYS.flag, value: true }]);

c.apply(frame(unlisten("2", 3), listen("2", 3, "change", SAYS.number, "value", false)));
box.value = "42";
box.listeners.get("change")();
check("an event heard anew says what it is now asked", c.sent[3], ["2", 3, { says: SAYS.number, value: 42 }]);
box.value = "not a number";
box.listeners.get("change")();
check("a control that cannot say a number says nothing", c.sent[4], ["2", 3, null]);

c.apply(frame(unlisten("0", 1)));
check("unlisten removes the listener", button.listeners.has("click"), false);

c.apply(frame(create("3", "form"), listen("3", 4, "submit", SAYS.nothing, "", true), place("3", "", "")));
let prevented = 0;
c.mount.childNodes[0].listeners.get("submit")({ preventDefault: () => { prevented++; } });
check("an event the patch says to stop is stopped, and echoed", [prevented, c.sent[5]], [1, ["3", 4, null]]);
let kept = 0;
c.apply(frame(listen("1", 1, "click", SAYS.nothing, "", false)));
field.listeners.get("click")({ preventDefault: () => { kept++; } });
check("an event it does not say to stop keeps its own answer", kept, 0);

// ── the wire itself ──
let refused = false;
try { parseFrame(Uint8Array.from([WIRE_VERSION + 1])); } catch { refused = true; }
check("a frame of another VERSION refuses", refused, true);
let unknown = "";
try { parseFrame(Uint8Array.from([WIRE_VERSION, 200])); } catch (e) { unknown = e.message; }
check("an op the table does not hold refuses", unknown, "unknown patch op 200");
check("an id holding more than one octet a letter reads whole", parseFrame(frame(create("0/k2:é", "div")))[0].id, "0/k2:é");
check("every op the table holds has a fixture here", Object.keys(OP).sort(), ["create", "create_text", "drop_attr", "listen", "place", "remove", "set_attr", "set_prop", "set_text", "style", "unlisten"]);

// ── the echo's seam ──
const calls = [];
const fakeMod = {
  memory: { buffer: new ArrayBuffer(64) },
  avra_id_seat: () => 16n,
  avra_payload_seat: () => 32n,
  avra_seat_room: () => 8n,
  avra_event: (who, what, tag, num, len) => calls.push([who, what, tag, num, len]),
};
const seat = (at, len) => new TextDecoder().decode(new Uint8Array(fakeMod.memory.buffer, at, len));
sendEvent(fakeMod, "0/k1:a", 1, null);
check("the id is written into the program's id seat", seat(16, 6), "0/k1:a");
check("nothing said sends the id's length and the nothing tag", calls[0].map(String), ["6", "1", String(SAYS.nothing), "0", "0"]);
sendEvent(fakeMod, "0", 1, { says: SAYS.number, value: 42 });
check("a number sends its value", calls[1].map(String), ["1", "1", String(SAYS.number), "42", "0"]);
sendEvent(fakeMod, "0", 1, { says: SAYS.text, value: "hi" });
check("text is written into the program's payload seat", seat(32, 2), "hi");
check("text sends its length", calls[2].map(String), ["1", "1", String(SAYS.text), "0", "2"]);
sendEvent(fakeMod, "0", 3, { says: SAYS.flag, value: true });
check("a flag sends one", calls[3].map(String), ["1", "3", String(SAYS.flag), "1", "0"]);

let outgrew = "";
try { sendEvent(fakeMod, "0", 2, { says: SAYS.text, value: "nine long" }); } catch (e) { outgrew = e.message; }
check("a text that outgrows the seat refuses, calling nothing", [outgrew, calls.length], ["an event's text is 9 octets — the program's seat holds 8", 4]);
outgrew = "";
try { sendEvent(fakeMod, "0/1/2/3/4", 1, null); } catch (e) { outgrew = e.message; }
check("an id that outgrows the seat refuses", outgrew, "an element id is 9 octets — the program's seat holds 8");

console.log(fails === 0 ? `bootstrap: ${passes}/${passes}` : `bootstrap: ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
