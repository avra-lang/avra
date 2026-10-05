// The live target's fixed bootstrap — the ONLY JavaScript an Avra web app
// ships. The program (wasm) emits a BYTE frame; this reconciles it into the
// live tree. A node is matched by its ID: the program gives one node the
// same id in every frame, whatever is inserted, removed or reordered
// beside it. Same file for every app.
//
// Wire V7: a version byte, then records of little-endian ints with ids and
// values carried raw (length-prefixed). An event record names a node and a
// kind; the handler stays in the program. Nothing is escaped; see
// realize/dom/frame.av.

export const FRAME_VERSION = 7;

// A frame's records, in frame order. `C` opens a record; `A`/`T` fill its
// class and words. The root's parent is null. Null means NOTHING CHANGED.
export function parseFrame(bytes) {
  const dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  let i = 0;
  const seen = bytes[i++];
  if (seen !== FRAME_VERSION) {
    throw new Error(`unsupported frame version ${seen} — this host speaks ${FRAME_VERSION}`);
  }
  if (bytes[i] === 0) return null;
  const records = [];
  const byId = new Map();
  const decoder = new TextDecoder();
  const int = () => { const v = dv.getInt32(i, true); i += 4; return v; };
  const str = () => { const len = int(); const s = decoder.decode(bytes.subarray(i, i + len)); i += len; return s; };
  while (i < bytes.length) {
    const op = bytes[i++];
    if (op === 1) {
      const id = str();
      const parent = str();
      const index = int();
      const tag = str();
      const r = { id, parent: parent === "" ? null : parent, index, tag, cls: null, text: null, events: [], attrs: [] };
      records.push(r);
      byId.set(id, r);
    } else if (op === 3 || op === 4) {
      const r = byId.get(str());
      const val = str();
      if (r) { if (op === 3) r.cls = val; else r.text = val; }
    } else if (op === 5) {
      const r = byId.get(str());
      const kind = int();
      const says = int();
      if (r) r.events.push([kind, says]);
    } else if (op === 8) {
      const r = byId.get(str());
      const name = str();
      const value = str();
      if (r) r.attrs.push([name, value]);
    } else if (op === 6) {
      records.stylesheet = str();
    } else if (op === 0) {
      break;
    } else {
      throw new Error(`unknown frame op ${op}`);
    }
  }
  return records;
}

// The DOM's own word for each event kind: a press is a click here.
const EVENT_NAME = { 1: "click", 2: "input", 3: "change", 4: "submit" };
// A submit's own navigation would reload the page the program is drawing.
const PREVENTED = new Set([4]);
// WHAT AN EVENT SAYS is the program's to name: the frame carries a code per
// event, and the host reads that value off the control — never a guess from
// the kind. 0 says nothing; a control that cannot say what was asked says
// nothing too.
const SAID = {
  0: () => null,
  1: (el) => { const n = Number(el.value); return Number.isFinite(n) ? { tag: "number", value: Math.trunc(n) } : null; },
  2: (el) => ({ tag: "flag", value: Boolean(el.checked) }),
  3: (el) => (el.value === undefined ? null : { tag: "text", value: String(el.value) }),
};

// A CONTROL HAS NO CONTENT: an `input` or a `progress` cannot hold its own
// words, so its node is a `label` wrapping the control and the words beside
// it. The wrapper is the node's place in the tree (its key, class and
// order); the control takes the attributes and the events.
const CONTROL = new Set(["input", "progress"]);
// State the USER moves lives in a property; the attribute is only its seed.
const PROPERTY = { checked: (el, on) => { el.checked = on; }, value: (el, on, v) => { if (el.value !== v) el.value = on ? v : ""; } };

function make(doc, tag) {
  if (!CONTROL.has(tag)) { const el = doc.createElement(tag); el.__avra_tag = tag; return el; }
  const el = doc.createElement("label");
  el.__avra_tag = tag;
  el.__avra_control = doc.createElement(tag);
  el.__avra_words = doc.createElement("span");
  el.appendChild(el.__avra_control);
  el.appendChild(el.__avra_words);
  return el;
}

// The element a node's attributes, events and value belong to.
const controlOf = (el) => el.__avra_control || el;

function setAttrs(el, attrs) {
  const at = controlOf(el);
  const had = at.__avra_attrs || new Set();
  const now = new Set();
  for (const [name, value] of attrs) {
    now.add(name);
    at.setAttribute(name, value);
    if (PROPERTY[name]) PROPERTY[name](at, true, value);
  }
  for (const name of had) {
    if (now.has(name)) continue;
    at.removeAttribute(name);
    if (PROPERTY[name]) PROPERTY[name](at, false, "");
  }
  at.__avra_attrs = now;
}

// Build the applier over one document (a real one in a browser, a stub in a
// test) and one mount element.
export function createApplier(doc, mount, send = () => {}, styleEl = null) {
  // LICENSED loops.push_loop: this map rides the closure as the applier's table
  let byId = new Map();

  return function apply(bytes) {
    const records = parseFrame(bytes);
    if (records === null) return; // nothing changed — touch nothing
    if (records.stylesheet !== undefined && styleEl) styleEl.textContent = records.stylesheet;
    const next = new Map();
    for (const r of records) {
      // AN ID IS ITS NODE, so the element that wore it is this node's — unless
      // the node became another kind of element, which no element can.
      const held = byId.get(r.id);
      const el = held && held.__avra_tag === r.tag ? held : make(doc, r.tag);
      if (r.cls !== null) el.setAttribute("class", r.cls);
      const words = el.__avra_words || el;
      if (r.text !== null && words.textContent !== r.text) words.textContent = r.text;
      setAttrs(el, r.attrs);
      el.__avra_id = r.id;
      next.set(r.id, el);
    }
    // Order each parent's children by the frame's own index.
    const order = new Map();
    for (const r of records) {
      if (!order.has(r.parent)) order.set(r.parent, []);
      order.get(r.parent).push(r);
    }
    if (!order.has(null)) order.set(null, []);
    for (const [parent, kids] of order) {
      const host = parent === null ? mount : next.get(parent);
      if (!host) continue;
      kids.sort((a, b) => a.index - b.index);
      kids.forEach((r, i) => {
        const el = next.get(r.id);
        if (host.childNodes[i] !== el) host.insertBefore(el, host.childNodes[i] || null);
      });
      while (host.childNodes.length > kids.length) {
        host.removeChild(host.childNodes[host.childNodes.length - 1]);
      }
    }
    // SUBSCRIBE: each event a frame names is a listener; one it drops, or
    // now says something else, is removed. The host calls back with the
    // node's id, the kind, and what the frame said the event says.
    for (const r of records) {
      const node = next.get(r.id);
      if (!node) continue;
      const el = controlOf(node);
      const attached = el.__avra_events || (el.__avra_events = new Map());
      const want = new Map(r.events);
      for (const [kind, held] of [...attached]) {
        if (want.get(kind) === held.says) continue;
        el.removeEventListener(EVENT_NAME[kind], held.listener);
        attached.delete(kind);
      }
      for (const [kind, says] of want) {
        if (attached.has(kind)) continue;
        const name = EVENT_NAME[kind];
        const said = SAID[says];
        if (!name || !said) continue;
        const listener = (ev) => {
          if (ev && PREVENTED.has(kind)) ev.preventDefault();
          send(node.__avra_id, kind, said(el));
        };
        el.addEventListener(name, listener);
        attached.set(kind, { says, listener });
      }
    }
    byId = next;
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
// length of the node's id, written into the id seat (`avra_id_seat`);
// `what` is the event kind. What the control said crosses as a TAG — the
// code the frame gave the event — and its value: tag 0 is NOTHING, a tag of
// its own, so a present zero or empty text is never mistaken for nothing;
// 1 is a number in `num`, 2 a flag, and 3 text of `len` octets in the
// payload seat (`avra_payload_seat`). A text that outgrows a seat's room
// (`avra_seat_room`) REFUSES: writing it would overwrite the program's
// memory. ONE door for both the page and a test harness.
const SAID_TAG = { number: 1, flag: 2, text: 3 };
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

export function sendEvent(mod, who, what, payload) {
  const seat = seatsOf(mod);
  const id = seated(mod, seat.id, seat.room, who, "a node id");
  if (!payload) { mod.avra_event(id, BigInt(what), 0n, 0n, 0n); return; }
  const tag = SAID_TAG[payload.tag];
  if (tag === 3) {
    mod.avra_event(id, BigInt(what), BigInt(tag), 0n, seated(mod, seat.payload, seat.room, payload.value, "an event's text"));
    return;
  }
  mod.avra_event(id, BigInt(what), BigInt(tag), BigInt(payload.value), 0n);
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
