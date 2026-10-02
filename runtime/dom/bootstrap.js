// The live target's fixed bootstrap — the ONLY JavaScript an Avra web app
// ships. The program (wasm) emits a text frame; this applies it to the
// live tree, keyed by PATH. Paths are stable for a stable shape, so a
// re-render moves nothing it need not. Same file for every app.

// The three separators the compiler escapes in a value.
export function unesc(s) {
  return s.replace(/%0a/g, "\n").replace(/%20/g, " ").replace(/%25/g, "%");
}

// Parse a frame's text into ops. Unknown opcodes are ignored, not guessed.
export function parseFrame(text) {
  if (text === "") return [];
  return text.split("\n").map((line) => {
    const i = line.indexOf(" ");
    const op = i < 0 ? line : line.slice(0, i);
    return { op, rest: i < 0 ? "" : line.slice(i + 1) };
  });
}

function split2(rest) {
  const i = rest.indexOf(" ");
  if (i < 0) return [rest, ""];
  return [rest.slice(0, i), rest.slice(i + 1)];
}

function parentPath(path) {
  const i = path.lastIndexOf("/");
  return i < 0 ? null : path.slice(0, i);
}

// Build the applier over one document (a real one in a browser, a stub in
// a test). One mount element holds the tree; each frame reconciles it.
export function createApplier(doc, mount) {
  // LICENSED loops.push_loop: the map rides the closure as the applier's one table
  const nodes = new Map();

  function element(path, tag) {
    const had = nodes.get(path);
    if (had && (tag === undefined || had.tagName.toLowerCase() === tag)) return had;
    const el = doc.createElement(tag);
    nodes.set(path, el);
    return el;
  }

  return function apply(text) {
    const live = [];
    const seen = new Set();
    for (const { op, rest } of parseFrame(text)) {
      if (op === "C") {
        const [path, tag] = split2(rest);
        element(path, tag);
        live.push(path);
        seen.add(path);
      } else if (op === "K") {
        const [path, key] = split2(rest);
        element(path).setAttribute("data-key", unesc(key));
      } else if (op === "T") {
        const [path, words] = split2(rest);
        const el = element(path);
        if (el.textContent !== unesc(words)) el.textContent = unesc(words);
      }
    }
    // Anything this frame no longer names leaves its parent and the table.
    for (const [path, el] of [...nodes]) {
      if (seen.has(path)) continue;
      if (el.parentNode) el.parentNode.removeChild(el);
      nodes.delete(path);
    }
    // Every LIVE node's children are exactly the frame's, in its order.
    const order = new Map();
    for (const path of live) if (!order.has(path)) order.set(path, []);
    order.set(null, []);
    for (const path of live) {
      const p = parentPath(path);
      if (!order.has(p)) order.set(p, []);
      order.get(p).push(path);
    }
    for (const [p, kids] of order) {
      const host = p === null ? mount : nodes.get(p);
      if (!host) continue;
      kids.forEach((path, i) => {
        const el = nodes.get(path);
        if (host.childNodes[i] !== el) host.insertBefore(el, host.childNodes[i] || null);
      });
      while (host.childNodes.length > kids.length) {
        host.removeChild(host.childNodes[host.childNodes.length - 1]);
      }
    }
    return seen;

  };
}

// Load the module and run it in a page. `imports` is the host's own table
// for module `avra:rt`; WASI's preview1 is supplied by the shim beside it.
export async function start(url, mount, wasi, hostImports) {
  const bytes = await (await fetch(url)).arrayBuffer();
  const { instance } = await WebAssembly.instantiate(bytes, {
    wasi_snapshot_preview1: wasi,
    "avra:rt": hostImports,
  });
  return instance.exports;
}
