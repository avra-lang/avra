// The live target's fixed bootstrap — the ONLY JavaScript an Avra web app
// ships. The program (wasm) emits a text frame; this reconciles it into the
// live tree. A node with a KEY is matched by key (identity moves with it);
// a node without one is matched by its PATH. Same file for every app.

// The separators the compiler escapes in a value.
export function unesc(s) {
  return s.replace(/%0a/g, "\n").replace(/%20/g, " ").replace(/%25/g, "%");
}

// Parse a frame into node records in frame order. A record starts at a `C`
// op; `K`/`A`/`T` beside it fill key, class and words.
export function parseFrame(text) {
  if (text === "") return [];
  const records = [];
  for (const line of text.split("\n")) {
    const i = line.indexOf(" ");
    const op = i < 0 ? line : line.slice(0, i);
    const rest = i < 0 ? "" : line.slice(i + 1);
    if (op === "C") {
      const j = rest.indexOf(" ");
      records.push({ path: rest.slice(0, j), tag: rest.slice(j + 1), key: null, cls: null, text: null });
    } else if (op === "K") {
      const r = records[records.length - 1];
      const j = rest.indexOf(" ");
      r.key = unesc(rest.slice(j + 1));
    } else if (op === "A") {
      const r = records[records.length - 1];
      const j = rest.indexOf(" ");
      r.cls = unesc(rest.slice(j + 1));
    } else if (op === "T") {
      const r = records[records.length - 1];
      const j = rest.indexOf(" ");
      r.text = unesc(rest.slice(j + 1));
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
    const next = new Map();
    const keys = new Set();
    for (const r of records) {
      const keyed = r.key !== null && byKey.has(r.key);
      let el = keyed ? byKey.get(r.key) : byPath.get(r.path) || doc.createElement(r.tag);
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
    for (const [key, el] of [...byKey]) if (!keys.has(key)) byKey.delete(key);
    byPath = next;
  };
}

// Load the module and run it in a page. `imports` is the host's own table
// for module `avra:rt`; WASI's preview1 comes from the shim beside it.
export async function start(url, mount, wasi, hostImports) {
  const bytes = await (await fetch(url)).arrayBuffer();
  const { instance } = await WebAssembly.instantiate(bytes, {
    wasi_snapshot_preview1: wasi,
    "avra:rt": hostImports,
  });
  return instance.exports;
}
