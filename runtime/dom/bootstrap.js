// The live target's fixed bootstrap — the ONLY JavaScript an Avra web app
// ships. The program (wasm) emits a BYTE frame; this reconciles it into the
// live tree. A node with a KEY is matched by key (identity moves with it);
// otherwise it is matched by its ID from the previous frame. Same file for
// every app.
//
// Wire V3: a version byte, then records of little-endian ints with values
// carried raw (length-prefixed). Nothing is escaped; see realize/dom/frame.av.

export const FRAME_VERSION = 3;

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
      const r = { id, parent, index, tag, key: null, cls: null, text: null, events: [] };
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
      if (r) { if (!r.events) r.events = []; r.events.push(kind); }
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

export function createApplier(doc, mount, send = () => {}) {
  // LICENSED loops.push_loop: these maps ride the closure as the applier's table
  const byKey = new Map();
  let byId = new Map();

  return function apply(bytes) {
    const records = parseFrame(bytes);
    if (records === null) return; // nothing changed — touch nothing
    const next = new Map();
    const keys = new Set();
    for (const r of records) {
      const keyed = r.key !== null && byKey.has(r.key);
      const el = keyed ? byKey.get(r.key) : byId.get(r.id) || doc.createElement(r.tag);
      if (r.key !== null) { el.setAttribute("data-key", r.key); byKey.set(r.key, el); keys.add(r.key); }
      if (r.cls !== null) el.setAttribute("class", r.cls);
      if (r.text !== null && el.textContent !== r.text) el.textContent = r.text;
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
    // removed. The host calls back with the ID and KIND the frame gave.
    for (const r of records) {
      const el = next.get(r.id);
      if (!el) continue;
      const attached = el.__avra_events || (el.__avra_events = new Map());
      const want = new Set(r.events || []);
      for (const [kind, handler] of [...attached]) {
        if (want.has(kind)) continue;
        el.removeEventListener(EVENT_NAME[kind], handler);
        attached.delete(kind);
      }
      for (const kind of want) {
        if (attached.has(kind)) continue;
        const name = EVENT_NAME[kind];
        if (!name) continue;
        const handler = () => send(r.id, kind);
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
export async function instantiate(url, host) {
  const bytes = await (await fetch(url)).arrayBuffer();
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
  const { instance } = await WebAssembly.instantiate(module, imports);
  return instance.exports;
}

// The bytes a frame seat points at, read through the RUNTIME'S OWN length
// reader (`avra_bytes_len`, an exported row) — never a second copy of the
// header layout that could drift from runtime/avra_box.h.
export function frameOf(memory, ptr, lenOf) {
  const len = lenOf(ptr);
  if (len < 0) throw new Error("avra_dom_frame: the length reader answered a negative length");
  return new Uint8Array(memory.buffer, ptr, len);
}
