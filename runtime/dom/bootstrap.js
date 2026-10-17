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
import { WIRE_VERSION, NO_ID, OP, SAYS, HOST, ROWS, TAGS, AFTER } from "./wire.gen.js";
import { createWindows } from "./windows.js";

export { WIRE_VERSION, HOST, ROWS };

// A `place` that follows no sibling but the end of the parent's run.
export const APPENDED = -2;

// A frame's patches, in order. An id is one more than its number in seven-bit
// groups, so zero is `NO_ID`, where a record names none: the page itself as a
// parent. A `place` says where it goes with one number: the first place, the
// end of the parent's run, or two more than the sibling it follows. A tag is
// its place among `TAGS`. Every other number is four bytes; a text is its
// byte length, then its bytes.
export function parseFrame(bytes) {
  const dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const decoder = new TextDecoder();
  let i = 0;
  const seen = bytes[i++];
  if (seen !== WIRE_VERSION) {
    throw new Error(`unsupported wire version ${seen} — this host speaks ${WIRE_VERSION}`);
  }
  const int = () => { const v = dv.getInt32(i, true); i += 4; return v; };
  const varint = () => { let n = 0, scale = 1, b; do { b = bytes[i++]; n += (b & 127) * scale; scale *= 128; } while (b >= 128); return n; };
  const id = () => varint() - 1;
  const after = () => { const v = varint(); return v === AFTER.first ? NO_ID : v === AFTER.append ? APPENDED : v - AFTER.sibling; };
  const tag = () => TAGS[varint()];
  const str = () => { const len = int(); const s = decoder.decode(bytes.subarray(i, i + len)); i += len; return s; };
  const patches = [];
  while (i < bytes.length) {
    const op = bytes[i++];
    if (op === OP.create) patches.push({ op, id: id(), tag: tag() });
    else if (op === OP.create_text || op === OP.set_text) patches.push({ op, id: id(), content: str() });
    else if (op === OP.place) patches.push({ op, id: id(), parent: id(), after: after() });
    else if (op === OP.remove) patches.push({ op, id: id() });
    else if (op === OP.set_attr) patches.push({ op, id: id(), name: str(), value: str() });
    else if (op === OP.drop_attr) patches.push({ op, id: id(), name: str() });
    else if (op === OP.set_prop) patches.push({ op, id: id(), name: str(), says: int(), value: str() });
    else if (op === OP.define) patches.push({ op, kind: int(), says: int(), event: str(), reads: str(), prevents: int() !== 0 });
    else if (op === OP.listen) patches.push({ op, id: id(), kind: int(), says: int() });
    else if (op === OP.unlisten) patches.push({ op, id: id(), kind: int() });
    else if (op === OP.style) patches.push({ op, css: str() });
    else if (op === OP.call) patches.push({ op, id: id(), verb: str() });
    else if (op === OP.set_var) patches.push({ op, id: id(), property: str(), value: str() });
    else if (op === OP.drop_var) patches.push({ op, id: id(), property: str() });
    else if (op === OP.adopt) patches.push({ op, words: int(), kinds: Array.from({ length: int() }, str) });
    else throw new Error(`unknown patch op ${op}`);
  }
  return patches;
}

// A property's value as the wire's text for it. A property holds text or a
// flag: a number control's `value` is the text that spells it.
function valueOf(says, text) {
  return says === SAYS.flag ? text !== "" : text;
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

// The attribute a shortcut says its chord in: the modifiers held (`c`, `a`,
// `s`), the key's `KeyboardEvent.code`, and its `KeyboardEvent.key`, each
// after a slash.
const CHORD = "data-avra-chord";

// Whether a keydown is the chord `spec` says: exactly its modifiers (the meta
// key is no chord's), and its key — by what the key is called when that is
// ASCII, and by the place it sits at when the layout calls it something else
// (a Greek or Russian ctrl+s says `σ` or `ы` of the key `KeyS`).
function meets(spec, ev) {
  const [held, rest] = cut(spec);
  const [code, key] = cut(rest);
  const ascii = /^[\x20-\x7e]+$/.test(ev.key);
  return ev.ctrlKey === held.includes("c") && ev.altKey === held.includes("a") && ev.shiftKey === held.includes("s")
    && !ev.metaKey && (ascii ? ev.key.toLowerCase() === key.toLowerCase() : code !== "" && ev.code === code);
}

// A spec's first field, and the rest after its slash.
const cut = (text) => { const at = text.indexOf("/"); return [text.slice(0, at), text.slice(at + 1)]; };

// Where a control's caret stands — none for an element that has none, which
// a page says by answering nothing or by refusing the question.
function caretOf(el) {
  try {
    return typeof el.selectionStart === "number" ? [el.selectionStart, el.selectionEnd, el.selectionDirection] : null;
  } catch { return null; }
}

// What an element hears once it hears `def` too: a seat it already heard is
// replaced, a lone seat stays the definition itself, and only a second seat
// makes a list.
function with_seat(mine, def) {
  if (mine === undefined) return def;
  const rest = (Array.isArray(mine) ? mine : [mine]).filter((d) => d.kind !== def.kind);
  return rest.length === 0 ? def : [...rest, def];
}

// Whether the page's engine sends a dialog away on its own word, `closedby`.
const knowsClosedby = (doc) => {
  const dialog = doc.defaultView?.HTMLDialogElement;
  return typeof dialog === "function" && "closedBy" in dialog.prototype;
};

// A DIALOG THAT SAYS `closedby="any"` IS SENT AWAY BY A PRESS OUTSIDE IT: one
// that starts and ends outside its box. It hears `cancel` as Escape makes it,
// and closes unless that is stopped. An engine that knows the word does this
// itself; where `sends` is true the page does it, by the same rule. AND A PRESS
// THAT SENDS A DIALOG AWAY REACHES NOTHING BEHIND IT: a touch's click comes
// after the dialog is gone, where it stood, so the press's click is stopped.
export function dialogPresses(doc, sends) {
  const away = (ev) => {
    const d = ev.target;
    if (!d || String(d.tagName).toLowerCase() !== "dialog" || !d.open || d.getAttribute("closedby") !== "any") return null;
    const r = d.getBoundingClientRect();
    return ev.clientX < r.left || ev.clientX >= r.right || ev.clientY < r.top || ev.clientY >= r.bottom ? d : null;
  };
  let pressed = null;
  let dismissed = false;
  doc.addEventListener("pointerdown", (ev) => {
    dismissed = false;
    pressed = sends ? away(ev) : null;
  }, true);
  doc.addEventListener("pointerup", (ev) => {
    const d = pressed;
    pressed = null;
    if (d === null || away(ev) !== d) return;
    if (typeof d.requestClose === "function") d.requestClose();
    else if (d.dispatchEvent(new Event("cancel", { cancelable: true }))) d.close();
  }, true);
  doc.addEventListener("keydown", () => { dismissed = false; }, true);
  doc.addEventListener("cancel", (ev) => { if (String(ev.target?.tagName).toLowerCase() === "dialog") dismissed = true; }, true);
  doc.addEventListener("click", (ev) => {
    if (!dismissed) return;
    dismissed = false;
    ev.preventDefault();
    ev.stopPropagation();
  }, true);
}

// THE PAGE A SERVER SENT IS ADOPTED, never drawn over: its nodes, taken in
// document order, are the elements the program counted out under the same
// numbers. Markers (comments) are the writer's, between texts a parser would
// join. A page that is not the program's elements is emptied, loudly, and the
// program draws from nothing.
const nameOf = (n) => String(n.nodeName ?? n.tagName).toLowerCase();
const marker = (n) => nameOf(n) === "#comment";
// A text is its octets' length too: a parser that drops a leading newline or
// folds a line ending holds other words than the program drew.
const kindOf = (n) => (nameOf(n) === "#text" ? `#text:${new TextEncoder().encode(n.textContent).length}` : nameOf(n));

// Every element a mount holds, in document order, markers left out.
export function standingOf(mount) {
  const out = [];
  const walk = (parent) => {
    for (const n of Array.from(parent.childNodes || [])) {
      if (marker(n)) continue;
      out.push(n);
      walk(n);
    }
  };
  walk(mount);
  return out;
}

// One number over the words of every text, in document order, folded as the
// program folds its own (`words_of`, realize/html/print.av): a parser or a
// proxy that dropped a newline or rewrote a word holds other words than the
// program drew.
const PRIME = 1000000007;
const BASE = 131;
const mixed = (acc, text) => {
  const octets = new TextEncoder().encode(text);
  let at = acc;
  for (const b of octets) at = (at * BASE + b + 1) % PRIME;
  return (at * BASE + octets.length + 1) % PRIME;
};
export const wordsOf = (list) => list.filter((n) => nameOf(n) === "#text").reduce((acc, n) => mixed(acc, n.textContent), 7) + 1;

// Build the applier over one document (a real one in a browser, a stub in a
// test) and one mount element. `send(id, kind, said)` is the echo.
export function createApplier(doc, mount, send = () => {}, styleEl = null, repair = () => {}) {
  dialogPresses(doc, !knowsClosedby(doc));
  // THE PAGE'S TABLES ARE KEYED BY ID, AND IDS ARE DENSE: `nodes[id]` is the
  // element, `hears[id]` what it hears — the shared definition of its one
  // seat, or a list of them for a second — so an element costs no object here.
  const nodes = [];
  const hears = [];
  const defined = new Map();
  const armed = new Set();
  // WHO HEARS WHAT IS DATA HERE, NEVER A LISTENER ON EACH ELEMENT: one
  // capturing listener per event word on the mount finds the hearers on the
  // way up from the target.
  const fire = (el, ev, def) => {
    if (def.event !== ev.type) return;
    if (def.prevents && ev.preventDefault) ev.preventDefault();
    send(el.__avra_id, def.kind, saidBy(el, def.says, def.reads));
  };
  const hearing = (el, ev) => {
    const mine = hears[el.__avra_id];
    if (mine === undefined) return;
    if (Array.isArray(mine)) for (const def of mine) fire(el, ev, def); else fire(el, ev, mine);
  };
  // A SHORTCUT IS LIVE WHILE WHAT HOLDS IT HAS THE FOCUS, so a keydown is
  // offered to the keys among each ancestor's children, nearest first, and the
  // first whose chord it meets is pressed — and the browser's own answer to
  // that chord is stopped, the page having bound it.
  const pressed = (ev) => {
    for (let el = mount.contains(ev.target) ? ev.target : mount; el; el = el.parentNode) {
      for (const key of el.childNodes || []) {
        const spec = key.getAttribute ? key.getAttribute(CHORD) : null;
        if (spec === null || !meets(spec, ev)) continue;
        if (ev.preventDefault) ev.preventDefault();
        hearing(key, ev);
        return;
      }
      if (el === mount) return;
    }
  };
  const heard = (ev) => {
    for (let el = ev.target; el && el !== mount; el = el.parentNode) {
      hearing(el, ev);
      if (!ev.bubbles) break;
    }
  };
  let chording = false;
  const listed = (id) => { const mine = hears[id]; return mine === undefined ? [] : Array.isArray(mine) ? mine : [mine]; };
  const emptied = () => {
    nodes.length = 0;
    hears.length = 0;
    while (mount.childNodes.length > 0) mount.removeChild(mount.childNodes[0]);
  };
  let broken = false;
  // The elements the last adoption took, whose controls may hold what a user
  // typed before the program could hear it.
  let taken = [];
  const adopt = (kinds, words) => {
    const stood = standingOf(mount);
    if (kinds.length === 0) {
      if (stood.length > 0) { console.warn("avra: the page held elements this program does not draw — emptied"); emptied(); }
      return;
    }
    if (stood.length !== kinds.length || stood.some((n, j) => kindOf(n) !== kinds[j]) || wordsOf(stood) !== words) {
      console.warn("avra: the page held is not the one this program draws — drawn again from nothing");
      emptied();
      broken = true;
      return;
    }
    stood.forEach((n, j) => keep(j, n));
    taken = stood;
  };
  // A control that holds more than its markup seeded was typed in before the
  // program stood: it says so once, through the echo the program bound, and its
  // handler learns what the page already shows. One saying per control: the
  // first seat that reads the property.
  const replay = () => {
    const stood = taken;
    taken = [];
    for (const el of stood) {
      for (const def of listed(el.__avra_id)) {
        if (!def.reads || el[def.reads] === undefined) continue;
        const seeded = def.reads === "checked" ? el.getAttribute("checked") !== null : el.getAttribute(def.reads) ?? "";
        if (el[def.reads] === seeded) continue;
        send(el.__avra_id, def.kind, saidBy(el, def.says, def.reads));
        break;
      }
    }
  };
  const need = (id) => {
    const el = nodes[id];
    if (!el) throw new Error(`a patch names element ${id}, which is not on the page`);
    return el;
  };
  // An element that leaves takes everything under it.
  const forget = (el) => {
    nodes[el.__avra_id] = undefined;
    hears[el.__avra_id] = undefined;
    for (const child of el.childNodes || []) forget(child);
  };
  const keep = (id, el) => { el.__avra_id = id; nodes[id] = el; };
  // WHAT THE PAGE KEEPS ON AN ELEMENT IS NEVER THIS HOST'S TO LOSE: the
  // focus, a caret, how far it is scrolled, a video playing, an animation
  // under way. A page that can carry an element standing on it
  // (`moveBefore`) keeps all of it. One that cannot takes the element off
  // and puts it back, which drops it — so the focus and the caret under
  // it, which a page hands back when asked, are put back after.
  const carry = (parent, el, before) => {
    if (typeof parent.moveBefore === "function" && el.isConnected && parent.isConnected) { parent.moveBefore(el, before); return; }
    const held = focusUnder(el);
    parent.insertBefore(el, before);
    held();
  };
  const focusUnder = (el) => {
    const active = doc.activeElement;
    if (!active || !el.contains || !el.contains(active)) return () => {};
    const caret = caretOf(active);
    return () => {
      active.focus({ preventScroll: true });
      if (caret) active.setSelectionRange(...caret);
    };
  };

  const apply = {
    [OP.adopt]: (p) => adopt(p.kinds, p.words),
    [OP.create]: (p) => keep(p.id, doc.createElement(p.tag)),
    [OP.create_text]: (p) => keep(p.id, doc.createTextNode(p.content)),
    // A NODE THAT MOVES IS THE SAME NODE, with all the page keeps on it. One
    // that already stands where it is put is not touched.
    [OP.place]: (p) => {
      const parent = p.parent === NO_ID ? mount : need(p.parent);
      const el = need(p.id);
      const before = (p.after === NO_ID ? parent.childNodes[0] : p.after === APPENDED ? null : need(p.after).nextSibling) || null;
      if (before === el || (el.parentNode === parent && el.nextSibling === before)) return;
      carry(parent, el, before);
    },
    [OP.remove]: (p) => {
      const el = need(p.id);
      if (el.parentNode) el.parentNode.removeChild(el);
      forget(el);
    },
    [OP.set_attr]: (p) => need(p.id).setAttribute(p.name, p.value),
    [OP.drop_attr]: (p) => need(p.id).removeAttribute(p.name),
    // A CUSTOM PROPERTY IS WRITTEN THROUGH THE ELEMENT'S STYLE OBJECT, never as a
    // `style` attribute: a page that allows styles by nonce alone allows this.
    [OP.set_var]: (p) => need(p.id).style.setProperty(p.property, p.value),
    [OP.drop_var]: (p) => need(p.id).style.removeProperty(p.property),
    // A PROPERTY IS WRITTEN ONLY WHEN IT DIFFERS: writing a field's own
    // text back to it would move the caret a user is typing at.
    [OP.set_prop]: (p) => {
      const el = need(p.id);
      const value = valueOf(p.says, p.value);
      if (el[p.name] !== value) el[p.name] = value;
    },
    [OP.set_text]: (p) => { need(p.id).textContent = p.content; },
    // WHAT A SEAT'S EVENT IS arrives once (`define`), and each `listen` of it
    // is an element and two numbers.
    [OP.define]: (p) => { defined.set(p.kind * 4 + p.says, p); },
    [OP.listen]: (p) => {
      need(p.id);
      const def = defined.get(p.kind * 4 + p.says);
      if (!def) throw new Error(`a patch listens to seat ${p.kind} saying ${p.says}, which no definition told`);
      hears[p.id] = with_seat(hears[p.id], def);
      if (!armed.has(def.event)) {
        armed.add(def.event);
        mount.addEventListener(def.event, heard, true);
      }
      // A keydown with nothing focused lands on the body, outside the mount, so
      // shortcuts hear the DOCUMENT.
      if (def.event === "keydown" && !chording) {
        chording = true;
        doc.addEventListener("keydown", pressed, true);
      }
    },
    [OP.unlisten]: (p) => {
      const rest = listed(p.id).filter((def) => def.kind !== p.kind);
      hears[p.id] = rest.length === 0 ? undefined : rest.length === 1 ? rest[0] : rest;
    },
    [OP.style]: (p) => { if (styleEl) styleEl.textContent = p.css; },
    // A VERB OF THE ELEMENT'S OWN, asked for by name: the program says
    // which, and an element with no such verb refuses by name.
    [OP.call]: (p) => {
      const el = need(p.id);
      if (typeof el[p.verb] !== "function") throw new Error(`a patch calls ${p.verb} on element ${p.id}, which has no such verb`);
      el[p.verb]();
    },
  };

  const applyFrame = (bytes) => {
    for (const p of parseFrame(bytes)) {
      apply[p.op](p);
      if (broken) break;
    }
    if (broken) { broken = false; queueMicrotask(repair); return; }
    replay();
  };
  // What each element hears, for a reader of the page to inspect.
  applyFrame.ears = (id) => listed(id).map((def) => [def.kind, def]);
  // How many slots hold an element and a hearing: what the page still keeps.
  applyFrame.held = () => ({ nodes: nodes.filter((n) => n !== undefined).length, hears: hears.filter((h) => h !== undefined).length });
  return applyFrame;
}

// Load the module and run it in a page. The host supplies `rt` (its own
// rows for module `avra:rt`) and `wasi` (preview1). An import NO host row
// answers REFUSES by name — a missing row must never be a silent no-op.
// A module that links the runtime's scheduler imports its port (`avra_host`)
// whether or not the program ever parks. A host that runs tasks supplies
// `tasks`; a page does not, and the port it is given refuses BY NAME when
// called, so a program that never parks pays nothing and one that does says why.
export async function instantiate(source, host) {
  const unhosted = new Proxy({}, { get: (_, name) => () => { throw new Error(`this page hosts no tasks: the module called avra_host.${String(name)}`); } });
  // A URL in a page, the bytes themselves in a test or a node harness.
  const bytes = source instanceof Uint8Array ? source : await (await fetch(source)).arrayBuffer();
  const module = await WebAssembly.compile(bytes);
  const imports = {};
  const unknown = [];
  for (const im of WebAssembly.Module.imports(module)) {
    const table = im.module === "avra:rt" ? host.rt : im.module === "wasi_snapshot_preview1" ? host.wasi : im.module === "avra_host" ? host.tasks ?? unhosted : null;
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

// The program's `event(who: int, what: int, tag: int, num: int, len: int)`
// — `HOST.event`, a name the library's own table gives — crosses as five
// i64 seats, so the host hands it BigInts. `who` is the element's id and
// `what` the event kind, each echoed as the patch gave it. What the control
// said crosses as the tag the patch asked for (`SAYS`) and its value:
// nothing is a tag of its own, so a present zero or empty text is never
// mistaken for nothing; a number or a flag rides `num`; text is `len` UTF-8
// octets written into a seat the program hands out for exactly that many
// (`HOST.seat`), so no text outgrows its seat. ONE door for both the page
// and a test harness.
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

// The program's `scrolled(len, from, to, extent)` — `HOST.scrolled` — says which
// rows of a windowed list the page shows and how tall they measure. The first
// `len` octets of the seat are the list's path, a line break, and the key of the
// row the focus rests on (none after it for none).
export function sendScrolled(mod, path, from, to, extent, pin = "") {
  const bytes = new TextEncoder().encode(`${path}\n${pin}`);
  const at = Number(mod[HOST.seat](BigInt(bytes.length)));
  new Uint8Array(mod.memory.buffer, at, bytes.length).set(bytes);
  mod[HOST.scrolled](BigInt(bytes.length), BigInt(from), BigInt(to), BigInt(extent));
}

// The page's timers, for the program's asks. The program names a timer by
// a number it counted out (`arm(token, ms, repeat)`), the host keeps the
// handle, and `fired(token)` re-enters the program as a turn. A timer let
// go (`disarm`) never fires; a one-shot forgets itself once it has. `clock`
// is the page's `{ setTimeout, setInterval, clearTimeout, clearInterval }`,
// or a test's.
export function createTimers(clock, fired) {
  const held = new Map();
  return {
    arm: (token, ms, repeat) => {
      const t = Number(token);
      const again = Number(repeat) !== 0;
      const fire = () => { if (!again) held.delete(t); fired(t); };
      held.set(t, { again, handle: (again ? clock.setInterval : clock.setTimeout)(fire, Number(ms)) });
    },
    disarm: (token) => {
      const t = Number(token);
      const timer = held.get(t);
      if (!timer) return;
      (timer.again ? clock.clearInterval : clock.clearTimeout)(timer.handle);
      held.delete(t);
    },
    count: () => held.size,
  };
}

// A request frame the program wrote (`request_frame`, realize/dom/wire.av):
// the wire's version, the method's word, the URL, the wait in milliseconds
// (-1: none), the fields as a count and name/value pairs, and the body as its
// content type (empty: none) and its octets.
export function parseRequest(bytes) {
  const dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const decoder = new TextDecoder();
  let i = 0;
  const seen = bytes[i++];
  if (seen !== WIRE_VERSION) {
    throw new Error(`unsupported wire version ${seen} — this host speaks ${WIRE_VERSION}`);
  }
  const int = () => { const v = dv.getInt32(i, true); i += 4; return v; };
  const octets = () => { const len = int(); const o = bytes.slice(i, i + len); i += len; return o; };
  const str = () => decoder.decode(octets());
  const method = str();
  const url = str();
  const timeoutMs = int();
  const headers = [];
  for (let n = int(); n > 0; n--) headers.push([str(), str()]);
  const kind = str();
  const body = octets();
  return { method, url, timeoutMs, headers, kind, body };
}

// The page's requests, for the program's asks. The program names one by a
// number it counted out (`get(token, frame)`), the host keeps its abort handle,
// and `answered(token, status, octets)` re-enters the program as a turn: the
// status and body of the reply, or status -1 and the words of why there is
// none. An aborted request, or one already answered, never answers — a late
// answer is dropped here, not by the program. `fetchFn` is the page's `fetch`,
// or a test's; `clock` supplies the wait.
export function createFetches(fetchFn, answered, clock = globalThis) {
  const held = new Map();
  const finish = (token, status, octets) => {
    const mine = held.get(token);
    if (!mine) return;
    held.delete(token);
    if (mine.timer !== null) clock.clearTimeout(mine.timer);
    answered(token, status, octets);
  };
  return {
    get: (token, frame) => {
      const t = Number(token);
      const r = parseRequest(frame);
      const controller = new AbortController();
      const timer = r.timeoutMs >= 0 ? clock.setTimeout(() => { finish(t, -1, new TextEncoder().encode("the request timed out")); controller.abort(); }, r.timeoutMs) : null;
      held.set(t, { controller, timer });
      const headers = Object.fromEntries(r.headers);
      if (r.kind !== "" && !Object.keys(headers).some((n) => n.toLowerCase() === "content-type")) headers["content-type"] = r.kind;
      const init = { method: r.method, headers, signal: controller.signal };
      if (r.body.length > 0 && r.method !== "GET" && r.method !== "HEAD") init.body = r.body;
      Promise.resolve()
        .then(() => fetchFn(r.url, init))
        .then((res) => res.arrayBuffer().then((buf) => finish(t, res.status, new Uint8Array(buf))))
        .catch((err) => finish(t, -1, new TextEncoder().encode(String(err && err.message ? err.message : err))));
    },
    abort: (token) => {
      const t = Number(token);
      const mine = held.get(t);
      if (!mine) return;
      held.delete(t);
      if (mine.timer !== null) clock.clearTimeout(mine.timer);
      mine.controller.abort();
    },
    count: () => held.size,
  };
}

// The program's `answered(token, status, len)` — `HOST.answered`: the octets
// are written into the seat the program hands out for exactly that many
// (`HOST.seat`), then the three numbers cross as i64 seats.
export function sendAnswer(mod, token, status, octets) {
  const at = Number(mod[HOST.seat](BigInt(octets.length)));
  new Uint8Array(mod.memory.buffer, at, octets.length).set(octets);
  mod[HOST.answered](BigInt(token), BigInt(status), BigInt(octets.length));
}

// The page's frames, for the program's paints. The program asks for one when
// state moved (`next()`), once until it comes; the host calls `painted` from
// the display's own frame (`raf`, the page's requestAnimationFrame, or a
// test's), and the program paints once however many turns moved it.
export function createFrames(raf, painted) {
  let pending = false;
  return {
    next: () => {
      if (pending) return;
      pending = true;
      raf(() => { pending = false; painted(); });
    },
    waiting: () => pending,
  };
}

// The print a server stamped on the mount, none (0) for a page it did not
// send: the program compares it against the page it would draw itself.
export function printOf(mount) {
  const text = mount.getAttribute ? mount.getAttribute("data-avra-print") : null;
  return /^[1-9][0-9]{0,15}$/.test(text ?? "") ? Number(text) : 0;
}

// RUN AN APP ON A PAGE: load the module, apply each frame it sends to
// `mount`, echo what the user does, then run the program's own statements
// — its `mount(view)` paints the first frame. `document`, `mount` and
// `style` are a real page's or a stub's; `wasi(memory)` answers the
// preview1 rows over the module's memory; `sent(bytes)` sees each frame
// before it is applied. A module that is no `@std/ui` web app REFUSES by
// the name it lacks.
export async function run(source, { document, mount, style = null, wasi, sent = () => {}, failed = (e) => { throw e; }, clock = globalThis, fetch: fetchFn = (...a) => globalThis.fetch(...a), raf = (cb) => globalThis.requestAnimationFrame(cb) }) {
  let mod = null;
  const into = guarded(failed);
  const timers = createTimers(clock, into((token) => mod[HOST.fired](BigInt(token))));
  const frames = createFrames(raf, into(() => mod[HOST.painted]()));
  const fetches = createFetches(fetchFn, into((token, status, octets) => sendAnswer(mod, token, status, octets)), clock);
  const windows = createWindows(document, mount, into((path, from, to, extent, pin) => sendScrolled(mod, path, from, to, extent, pin)));
  const apply = createApplier(document, mount, into((who, what, said) => sendEvent(mod, who, what, said)), style, into(() => mod[HOST.repaired]()));
  mod = await instantiate(source, {
    wasi: wasi(() => mod.memory),
    // The seat is a Bytes: the pointer names its box, and the LENGTH comes
    // from the runtime's own reader, exported by the module.
    rt: {
      [ROWS.frame]: (ptr) => { const bytes = frameOf(mod.memory, ptr, mod.avra_bytes_len); sent(bytes); apply(bytes); queueMicrotask(windows.check); },
      [ROWS.arm]: timers.arm,
      [ROWS.disarm]: timers.disarm,
      [ROWS.get]: (token, ptr) => fetches.get(token, frameOf(mod.memory, ptr, mod.avra_bytes_len).slice()),
      [ROWS.abort]: fetches.abort,
      [ROWS.next_paint]: frames.next,
      [ROWS.stood]: () => BigInt(printOf(mount)),
    },
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
  return { mod, ears: apply.ears };
}

// EVERY WAY THE PAGE ENTERS THE MODULE — an event, a timer, a frame, an
// answer, a scroll — runs under `into(fn)`: a throw is handed to `failed`
// whole, its stack with it, where the browser's own report of an uncaught
// error may hide its words ("Script error.").
export function guarded(failed) {
  return (fn) => (...args) => {
    try { return fn(...args); } catch (e) { failed(e); }
  };
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
