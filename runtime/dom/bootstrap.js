// The live target's fixed bootstrap — the ONLY JavaScript an Avra web app
// ships. The program (wasm) emits a BYTE frame; this reconciles it into the
// live tree. A node with a KEY is matched by key (identity moves with it);
// otherwise it is matched by its ID from the previous frame. Same file for
// every app.
//
// Wire V5: a version byte, then records of little-endian ints with values
// carried raw (length-prefixed). An event record names a node and a kind;
// the handler stays in the program. Nothing is escaped; see
// realize/dom/frame.av.

export const FRAME_VERSION = 5;

// A frame's records, in frame order. `C` opens a record; `K`/`A`/`T` fill
// key, class and words. Null means NOTHING CHANGED.
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
  const str = (at, len) => new TextDecoder().decode(bytes.subarray(at, at + len));
  while (i < bytes.length) {
    const op = bytes[i++];
    if (op === 1) {
      const id = dv.getInt32(i, true); i += 4;
      const parent = dv.getInt32(i, true); i += 4;
      const index = dv.getInt32(i, true); i += 4;
      const len = dv.getInt32(i, true); i += 4;
      const tag = str(i, len); i += len;
      const r = { id, parent, index, tag, key: null, cls: null, text: null, events: [], attrs: [] };
      records.push(r);
      byId.set(id, r);
    } else if (op === 2 || op === 3 || op === 4) {
      const id = dv.getInt32(i, true); i += 4;
      const len = dv.getInt32(i, true); i += 4;
      const val = str(i, len); i += len;
      const r = byId.get(id);
      if (r) { if (op === 2) r.key = val; else if (op === 3) r.cls = val; else r.text = val; }
    } else if (op === 5) {
      const id = dv.getInt32(i, true); i += 4;
      const kind = dv.getInt32(i, true); i += 4;
      const r = byId.get(id);
      if (r) r.events.push(kind);
    } else if (op === 8) {
      const id = dv.getInt32(i, true); i += 4;
      const nameLen = dv.getInt32(i, true); i += 4;
      const name = str(i, nameLen); i += nameLen;
      const valueLen = dv.getInt32(i, true); i += 4;
      const value = str(i, valueLen); i += valueLen;
      const r = byId.get(id);
      if (r) r.attrs.push([name, value]);
    } else if (op === 6) {
      const len = dv.getInt32(i, true); i += 4;
      records.stylesheet = str(i, len); i += len;
    } else if (op === 0) {
      break;
    } else {
      throw new Error(`unknown frame op ${op}`);
    }
  }
  return records;
}

// Build the applier over one document (a real one in a browser, a stub in a
// test) and one mount element.
const EVENT_NAME = { 1: "click", 2: "input", 3: "change", 4: "submit" };

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

export function createApplier(doc, mount, send = () => {}, styleEl = null) {
  // LICENSED loops.push_loop: these maps ride the closure as the applier's table
  const byKey = new Map();
  let byId = new Map();

  return function apply(bytes) {
    const records = parseFrame(bytes);
    if (records === null) return; // nothing changed — touch nothing
    if (records.stylesheet !== undefined && styleEl) styleEl.textContent = records.stylesheet;
    const next = new Map();
    const keys = new Set();
    for (const r of records) {
      // REUSE ONLY A MATCHING ELEMENT. A pre-order id shifts when a node is
      // added or removed, so the element byId holds for this id may be a
      // DIFFERENT node now — a tag test refuses to wear it, and the reorder
      // below trims the stale one. Without it a list whose size changed
      // rewrote every later node into the element of a node that moved.
      const keyed = r.key !== null && byKey.has(r.key);
      const reused = byId.get(r.id);
      const el = keyed ? byKey.get(r.key) : reused && reused.__avra_tag === r.tag ? reused : make(doc, r.tag);
      if (r.key !== null) { el.setAttribute("data-key", r.key); byKey.set(r.key, el); keys.add(r.key); }
      if (r.cls !== null) el.setAttribute("class", r.cls);
      const words = el.__avra_words || el;
      if (r.text !== null && words.textContent !== r.text) words.textContent = r.text;
      setAttrs(el, r.attrs);
      // The id is THIS frame's: a listener reads it when it fires, so a node
      // that moved speaks under the id the program last gave it.
      el.__avra_id = r.id;
      next.set(r.id, el);
    }
    // Order each parent's children by the frame's own index.
    const order = new Map();
    for (const r of records) {
      if (!order.has(r.parent)) order.set(r.parent, []);
      order.get(r.parent).push(r);
    }
    if (!order.has(-1)) order.set(-1, []);
    for (const [parent, kids] of order) {
      const host = parent === -1 ? mount : next.get(parent);
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
    // SUBSCRIBE: each event a frame names is a listener; one it drops is
    // removed. The host calls back with the node's CURRENT id and the kind.
    for (const r of records) {
      const node = next.get(r.id);
      if (!node) continue;
      const el = controlOf(node);
      const attached = el.__avra_events || (el.__avra_events = new Map());
      const want = new Set(r.events);
      for (const [kind, handler] of [...attached]) {
        if (want.has(kind)) continue;
        el.removeEventListener(EVENT_NAME[kind], handler);
        attached.delete(kind);
      }
      for (const kind of want) {
        if (attached.has(kind)) continue;
        const name = EVENT_NAME[kind];
        if (!name) continue;
        // AN INPUT SAYS ITS OWN TEXT: what the user typed lives in the page,
        // so an input event carries the element's value. Every other kind
        // says nothing.
        const handler = () =>
          send(node.__avra_id, kind, kind === 2 && el.value !== undefined ? { tag: "text", value: String(el.value) } : null);
        el.addEventListener(name, handler);
        attached.set(kind, handler);
      }
    }
    for (const [key] of [...byKey]) if (!keys.has(key)) byKey.delete(key);
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
// int)` crosses as five i64 seats, so the host hands it BigInts. `who` is
// the node's id in the last frame, `what` the event kind. What the control
// said crosses as a TAG and its value: tag 0 is ABSENT — a tag of
// its own, so a present zero or empty text is never mistaken for no payload
// — 1 is an int in `num`, 2 a bool, and 3 text whose UTF-8 octets the host
// writes into the program's own seat (`avra_payload_seat`) and adopts by
// pointer. ONE door for both the page and a test harness.
const PAYLOAD_TAG = { text: 3, int: 1, bool: 2 };
const seats = new WeakMap();

export function sendEvent(mod, who, what, payload) {
  if (!payload) { mod.avra_event(BigInt(who), BigInt(what), 0n, 0n, 0n); return; }
  const tag = PAYLOAD_TAG[payload.tag];
  if (tag === 3) {
    const bytes = new TextEncoder().encode(payload.value);
    let seat = seats.get(mod);
    if (seat === undefined) { seat = Number(mod.avra_payload_seat()); seats.set(mod, seat); }
    new Uint8Array(mod.memory.buffer, seat, bytes.length).set(bytes);
    mod.avra_event(BigInt(who), BigInt(what), BigInt(tag), 0n, BigInt(bytes.length));
    return;
  }
  const num = payload.tag === "bool" ? (payload.value ? 1 : 0) : payload.value;
  mod.avra_event(BigInt(who), BigInt(what), BigInt(tag), BigInt(num), 0n);
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
