// The live target's fixed bootstrap — the ONLY JavaScript an Avra web app
// ships. The program (wasm) emits a frame; this reconciles it into the live
// tree. A node with a KEY is matched by key (identity moves with it); a node
// without one is matched by its PATH. Same file for every app.
//
// Wire V2: values are LENGTH-PREFIXED and carried raw, so nothing is escaped
// on either side and nothing can drift. See realize/dom/frame.av.

export const FRAME_VERSION = "V2";

// A frame's records, in frame order. A `C` line opens a record; `K`/`A`/`T`
// beside it fill key, class and words — each with its byte length, the bytes
// themselves on the following line. Null means NOTHING CHANGED.
export function parseFrame(text) {
  const head = FRAME_VERSION + "\n";
  if (!text.startsWith(head)) {
    const seen = JSON.stringify(text.slice(0, text.indexOf("\n")));
    throw new Error(`unsupported frame version ${seen} — this host speaks ${FRAME_VERSION}`);
  }
  let i = head.length;
  if (text.slice(i, i + 2) === "N\n") return null;
  const records = [];
  while (i < text.length) {
    const nl = text.indexOf("\n", i);
    if (nl < 0) break;
    const line = text.slice(i, nl);
    i = nl + 1;
    if (line === "") continue;
    const op = line[0];
    const body = line.slice(2);
    const sp = body.indexOf(" ");
    if (op === "C") {
      records.push({ path: body.slice(0, sp), tag: body.slice(sp + 1), key: null, cls: null, text: null });
    } else if (op === "K" || op === "A" || op === "T") {
      const len = parseInt(body.slice(sp + 1), 10);
      const val = text.substr(i, len);
      i += len + 1; // the value, then its newline
      const r = records[records.length - 1];
      if (op === "K") r.key = val;
      else if (op === "A") r.cls = val;
      else r.text = val;
    }
  }
  return records;
}

function parentPath(path) {
  const i = path.lastIndexOf("/");
  return i < 0 ? null : path.slice(0, i);
}

// Build the applier over one document (a real one in a browser, a stub in a
// test) and one mount element.
export function createApplier(doc, mount) {
  // LICENSED loops.push_loop: these maps ride the closure as the applier's table
  const byKey = new Map();
  let byPath = new Map();

  return function apply(text) {
    const records = parseFrame(text);
    if (records === null) return; // nothing changed — touch nothing
    const next = new Map();
    const keys = new Set();
    for (const r of records) {
      const keyed = r.key !== null && byKey.has(r.key);
      const el = keyed ? byKey.get(r.key) : byPath.get(r.path) || doc.createElement(r.tag);
      if (r.key !== null) {
        el.setAttribute("data-key", r.key);
        byKey.set(r.key, el);
        keys.add(r.key);
      }
      if (r.cls !== null) el.setAttribute("class", r.cls);
      if (r.text !== null && el.textContent !== r.text) el.textContent = r.text;
      next.set(r.path, el);
    }
    // Order each parent's children by the frame's own order.
    const order = new Map();
    for (const r of records) {
      const p = parentPath(r.path);
      if (!order.has(p)) order.set(p, []);
      order.get(p).push(r.path);
    }
    if (!order.has(null)) order.set(null, []);
    for (const [p, kids] of order) {
      const host = p === null ? mount : next.get(p);
      if (!host) continue;
      kids.forEach((path, i) => {
        const el = next.get(path);
        if (host.childNodes[i] !== el) host.insertBefore(el, host.childNodes[i] || null);
      });
      while (host.childNodes.length > kids.length) {
        host.removeChild(host.childNodes[host.childNodes.length - 1]);
      }
    }
    for (const [key] of [...byKey]) if (!keys.has(key)) byKey.delete(key);
    byPath = next;
  };
}

// Load the module and run it in a page. `imports` is the host's own table for
// module `avra:rt`; WASI's preview1 comes from the shim beside it.
export async function start(url, mount, wasi, hostImports) {
  const bytes = await (await fetch(url)).arrayBuffer();
  const { instance } = await WebAssembly.instantiate(bytes, {
    wasi_snapshot_preview1: wasi,
    "avra:rt": hostImports,
  });
  return instance.exports;
}
