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
import { WIRE_VERSION, NO_ID, OP, SAYS } from "./wire.gen.js";

export { WIRE_VERSION };

// A frame's patches, in order. An id is a number in eight little-endian
// bytes — the same width however deep its element sits — and `NO_ID` where
// a record names none: the page itself as a parent, the first place as a
// sibling. Every other number is four bytes; a text is its byte length,
// then its bytes.
export function parseFrame(bytes) {
  const dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const decoder = new TextDecoder();
  let i = 0;
  const seen = bytes[i++];
  if (seen !== WIRE_VERSION) {
    throw new Error(`unsupported wire version ${seen} — this host speaks ${WIRE_VERSION}`);
  }
  const int = () => { const v = dv.getInt32(i, true); i += 4; return v; };
  const id = () => { const lo = dv.getUint32(i, true); const hi = dv.getInt32(i + 4, true); i += 8; return hi * 4294967296 + lo; };
  const str = () => { const len = int(); const s = decoder.decode(bytes.subarray(i, i + len)); i += len; return s; };
  const patches = [];
  while (i < bytes.length) {
    const op = bytes[i++];
    if (op === OP.create) patches.push({ op, id: id(), tag: str() });
    else if (op === OP.create_text || op === OP.set_text) patches.push({ op, id: id(), content: str() });
    else if (op === OP.place) patches.push({ op, id: id(), parent: id(), after: id() });
    else if (op === OP.remove) patches.push({ op, id: id() });
    else if (op === OP.set_attr) patches.push({ op, id: id(), name: str(), value: str() });
    else if (op === OP.drop_attr) patches.push({ op, id: id(), name: str() });
    else if (op === OP.set_prop) patches.push({ op, id: id(), name: str(), says: int(), value: str() });
    else if (op === OP.listen) patches.push({ op, id: id(), kind: int(), event: str(), says: int(), reads: str(), prevents: int() !== 0 });
    else if (op === OP.unlisten) patches.push({ op, id: id(), kind: int() });
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
    if (!el) throw new Error(`a patch names element ${id}, which is not on the page`);
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
      const parent = p.parent === NO_ID ? mount : need(p.parent);
      const before = p.after === NO_ID ? parent.childNodes[0] : need(p.after).nextSibling;
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

// THE NAMES A PROGRAM ANSWERS TO. `avra_main` is the compiler's: a wasm
// module's own statements, where an app says `mount(view)`. The other two
// are the exports of `@std/ui`'s web module (web/web.av), under the names
// the compiler gives a library's fns.
export const HOST = { entry: "avra_main", event: "@std.ui.web.event", seat: "@std.ui.web.seat" };

// The program's `event(who: int, what: int, tag: int, num: int, len: int)`
// crosses as five i64 seats, so the host hands it BigInts. `who` is the
// element's id and `what` the event kind, each echoed as the patch gave
// it. What the control said crosses as the tag the patch asked for (`SAYS`)
// and its value: nothing is a tag of its own, so a present zero or empty
// text is never mistaken for nothing; a number or a flag rides `num`; text
// is `len` UTF-8 octets written into a seat the program hands out for
// exactly that many (`seat`), so no text outgrows its seat. ONE door for
// both the page and a test harness.
export function sendEvent(mod, who, what, said) {
  const event = mod[HOST.event];
  if (!said) { event(BigInt(who), BigInt(what), BigInt(SAYS.nothing), 0n, 0n); return; }
  if (said.says !== SAYS.text) { event(BigInt(who), BigInt(what), BigInt(said.says), BigInt(said.value), 0n); return; }
  const bytes = new TextEncoder().encode(said.value);
  // THE SEAT IS ASKED FOR FIRST: handing it out may grow the program's
  // memory, and a view made before that would name the old buffer.
  const at = Number(mod[HOST.seat](BigInt(bytes.length)));
  new Uint8Array(mod.memory.buffer, at, bytes.length).set(bytes);
  event(BigInt(who), BigInt(what), BigInt(said.says), 0n, BigInt(bytes.length));
}

// RUN AN APP ON A PAGE: load the module, apply each frame it sends to
// `mount`, echo what the user does, then run the program's own statements
// — its `mount(view)` paints the first frame. `document`, `mount` and
// `style` are a real page's or a stub's; `wasi(memory)` answers the
// preview1 rows over the module's memory; `sent(bytes)` sees each frame
// before it is applied. A module that is no `@std/ui` web app REFUSES by
// the name it lacks.
export async function run(source, { document, mount, style = null, wasi, sent = () => {} }) {
  let mod = null;
  const apply = createApplier(document, mount, (who, what, said) => sendEvent(mod, who, what, said), style);
  mod = await instantiate(source, {
    wasi: wasi(() => mod.memory),
    // The seat is a Bytes: the pointer names its box, and the LENGTH comes
    // from the runtime's own reader, exported by the module.
    rt: { avra_dom_frame: (ptr) => { const bytes = frameOf(mod.memory, ptr, mod.avra_bytes_len); sent(bytes); apply(bytes); } },
  });
  const lacks = Object.values(HOST).filter((name) => typeof mod[name] !== "function");
  if (lacks.length > 0) {
    throw new Error(`the module exports no ${lacks.join(", ")} — a page runs a program whose statements \`mount\` a view (\`use @std.ui.web.{mount}\`)`);
  }
  // A REACTOR: initialize the C runtime once, then the program's own
  // statements — never a `main` that exits.
  mod._initialize();
  const code = mod[HOST.entry]();
  if (code !== 0) throw new Error(`the program's statements answered ${code}`);
  return mod;
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
