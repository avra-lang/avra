// The live target's fixed bootstrap — the ONLY JavaScript an Avra web app
// ships. The program (wasm) decides everything: it diffs the page it drew
// against the page it wants and sends PATCHES. This applies them, and
// reports what the user did. It holds no tree, no reconciler and no table
// of the library's facts: which event a control hears, what it says, what
// is a property and what moved all arrive IN the patches, and the numbers
// the wire spells them with are generated (`wire.gen.js`) from the
// program's own declarations — see realize/dom/wire.av.
//
// Same file for every app.
import { WIRE_VERSION, OP, SAYS } from "./wire.gen.js";

export { WIRE_VERSION };

// A frame's patches, in order. Every number is four little-endian bytes;
// an id and every other text is its byte length, then its bytes. An empty
// id is no id: the page itself as a parent, the first place as a sibling.
export function parseFrame(bytes) {
  const dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const decoder = new TextDecoder();
  let i = 0;
  const seen = bytes[i++];
  if (seen !== WIRE_VERSION) {
    throw new Error(`unsupported wire version ${seen} — this host speaks ${WIRE_VERSION}`);
  }
  const int = () => { const v = dv.getInt32(i, true); i += 4; return v; };
  const str = () => { const len = int(); const s = decoder.decode(bytes.subarray(i, i + len)); i += len; return s; };
  const patches = [];
  while (i < bytes.length) {
    const op = bytes[i++];
    if (op === OP.create) patches.push({ op, id: str(), tag: str() });
    else if (op === OP.create_text || op === OP.set_text) patches.push({ op, id: str(), content: str() });
    else if (op === OP.place) patches.push({ op, id: str(), parent: str(), after: str() });
    else if (op === OP.remove) patches.push({ op, id: str() });
    else if (op === OP.set_attr) patches.push({ op, id: str(), name: str(), value: str() });
    else if (op === OP.drop_attr) patches.push({ op, id: str(), name: str() });
    else if (op === OP.set_prop) patches.push({ op, id: str(), name: str(), says: int(), value: str() });
    else if (op === OP.listen) patches.push({ op, id: str(), kind: int(), event: str(), says: int(), reads: str(), prevents: int() !== 0 });
    else if (op === OP.unlisten) patches.push({ op, id: str(), kind: int() });
    else if (op === OP.style) patches.push({ op, css: str() });
    else throw new Error(`unknown patch op ${op}`);
  }
  return patches;
}

// A value as the wire's text for it, read back by what it says.
function valueOf(says, text) {
  if (says === SAYS.flag) return text !== "";
  if (says === SAYS.number) return Number(text);
  return text;
}

// What a control says, read off the property the patch named. A control
// that cannot say what was asked says nothing.
function saidBy(el, says, reads) {
  if (says === SAYS.nothing) return null;
  const held = el[reads];
  if (says === SAYS.flag) return { says, value: Boolean(held) };
  if (says === SAYS.number) { const n = Number(held); return Number.isFinite(n) ? { says, value: Math.trunc(n) } : null; }
  return held === undefined ? null : { says, value: String(held) };
}

// Build the applier over one document (a real one in a browser, a stub in a
// test) and one mount element. `send(id, kind, said)` is the echo.
export function createApplier(doc, mount, send = () => {}, styleEl = null) {
  const byId = new Map();
  const need = (id) => {
    const el = byId.get(id);
    if (!el) throw new Error(`a patch names \`${id}\`, which is not on the page`);
    return el;
  };
  // An element that leaves takes everything under it.
  const forget = (el) => {
    byId.delete(el.__avra_id);
    for (const child of el.childNodes || []) forget(child);
  };
  const keep = (id, el) => { el.__avra_id = id; byId.set(id, el); };

  const apply = {
    [OP.create]: (p) => keep(p.id, doc.createElement(p.tag)),
    [OP.create_text]: (p) => keep(p.id, doc.createTextNode(p.content)),
    [OP.place]: (p) => {
      const parent = p.parent === "" ? mount : need(p.parent);
      const before = p.after === "" ? parent.childNodes[0] : need(p.after).nextSibling;
      parent.insertBefore(need(p.id), before || null);
    },
    [OP.remove]: (p) => {
      const el = need(p.id);
      if (el.parentNode) el.parentNode.removeChild(el);
      forget(el);
    },
    [OP.set_attr]: (p) => need(p.id).setAttribute(p.name, p.value),
    [OP.drop_attr]: (p) => need(p.id).removeAttribute(p.name),
    // A PROPERTY IS WRITTEN ONLY WHEN IT DIFFERS: writing a field's own
    // text back to it would move the caret a user is typing at.
    [OP.set_prop]: (p) => {
      const el = need(p.id);
      const value = valueOf(p.says, p.value);
      if (el[p.name] !== value) el[p.name] = value;
    },
    [OP.set_text]: (p) => { need(p.id).textContent = p.content; },
    [OP.listen]: (p) => {
      const el = need(p.id);
      const held = el.__avra_listeners || (el.__avra_listeners = new Map());
      const listener = (ev) => {
        if (p.prevents && ev) ev.preventDefault();
        send(p.id, p.kind, saidBy(el, p.says, p.reads));
      };
      el.addEventListener(p.event, listener);
      held.set(p.kind, { event: p.event, listener });
    },
    [OP.unlisten]: (p) => {
      const el = need(p.id);
      const held = el.__avra_listeners && el.__avra_listeners.get(p.kind);
      if (!held) return;
      el.removeEventListener(held.event, held.listener);
      el.__avra_listeners.delete(p.kind);
    },
    [OP.style]: (p) => { if (styleEl) styleEl.textContent = p.css; },
  };

  return function applyFrame(bytes) {
    for (const p of parseFrame(bytes)) apply[p.op](p);
  };
}

// Load the module and run it in a page. The host supplies `rt` (its own
// rows for module `avra:rt`) and `wasi` (preview1). An import NO host row
// answers REFUSES by name — a missing row must never be a silent no-op.
export async function instantiate(source, host) {
  // A URL in a page, the bytes themselves in a test or a node harness.
  const bytes = source instanceof Uint8Array ? source : await (await fetch(source)).arrayBuffer();
  const module = await WebAssembly.compile(bytes);
  const imports = {};
  const unknown = [];
  for (const im of WebAssembly.Module.imports(module)) {
    const table = im.module === "avra:rt" ? host.rt : im.module === "wasi_snapshot_preview1" ? host.wasi : null;
    const fn = table ? table[im.name] : undefined;
    if (typeof fn !== "function") { unknown.push(`${im.module}.${im.name}`); continue; }
    imports[im.module] = imports[im.module] || {};
    imports[im.module][im.name] = (...args) => fn(...args);
  }
  if (unknown.length > 0) {
    throw new Error(`the module needs host rows this page does not answer: ${unknown.join(", ")}`);
  }
  // A COMPILED module instantiates to the instance itself; only the bytes
  // form answers { module, instance }.
  const instance = await WebAssembly.instantiate(module, imports);
  return instance.exports;
}

// The program's `avra_event(who: int, what: int, tag: int, num: int, len:
// int)` crosses as five i64 seats, so the host hands it BigInts. Text
// crosses through the program's own SEATS: the host writes UTF-8 octets at
// the address the program gave and passes their length. `who` is the
// length of the element's id, written into the id seat (`avra_id_seat`);
// `what` is the event kind, echoed as the patch gave it. What the control
// said crosses as the tag the patch asked for (`SAYS`) and its value:
// nothing is a tag of its own, so a present zero or empty text is never
// mistaken for nothing; a number or a flag rides `num`, and text is `len`
// octets in the payload seat (`avra_payload_seat`). A text that outgrows a
// seat's room (`avra_seat_room`) REFUSES: writing it would overwrite the
// program's memory. ONE door for both the page and a test harness.
const seats = new WeakMap();

function seatsOf(mod) {
  let held = seats.get(mod);
  if (held === undefined) {
    held = { id: Number(mod.avra_id_seat()), payload: Number(mod.avra_payload_seat()), room: Number(mod.avra_seat_room()) };
    seats.set(mod, held);
  }
  return held;
}

// The text's octets written at a seat; their count.
function seated(mod, at, room, text, what) {
  const bytes = new TextEncoder().encode(text);
  if (bytes.length > room) throw new Error(`${what} is ${bytes.length} octets — the program's seat holds ${room}`);
  new Uint8Array(mod.memory.buffer, at, bytes.length).set(bytes);
  return BigInt(bytes.length);
}

export function sendEvent(mod, who, what, said) {
  const seat = seatsOf(mod);
  const id = seated(mod, seat.id, seat.room, who, "an element id");
  if (!said) { mod.avra_event(id, BigInt(what), BigInt(SAYS.nothing), 0n, 0n); return; }
  if (said.says === SAYS.text) {
    mod.avra_event(id, BigInt(what), BigInt(said.says), 0n, seated(mod, seat.payload, seat.room, said.value, "an event's text"));
    return;
  }
  mod.avra_event(id, BigInt(what), BigInt(said.says), BigInt(said.value), 0n);
}

// The bytes a frame seat points at, read through the RUNTIME'S OWN length
// reader (`avra_bytes_len`, an exported row) — never a second copy of the
// header layout that could drift from runtime/avra_box.h.
export function frameOf(memory, ptr, lenOf) {
  // `avra_bytes_len` answers i64 on wasm, so read it as a BigInt.
  const len = Number(lenOf(ptr));
  if (!Number.isFinite(len) || len < 0) {
    throw new Error(`avra_dom_frame: the length reader answered ${len}`);
  }
  return new Uint8Array(memory.buffer, ptr, len);
}
