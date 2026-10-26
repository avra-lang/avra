// The dev server's own client — served by `avra dev` and by nothing else; a
// production page never carries it. It listens to the server's event
// stream: `built` says the id of the module that stands, and a page running
// another reloads; `failed` says what the build said, SHOWN over the page
// while the last good module keeps running under it.
//
// THE CHANNEL IS AN EVENT STREAM (`/@dev/events`): the server only ever
// tells, and a stream that drops — the server restarted — is opened again
// by the browser itself, to hear where things stand now.

// The failure, over the page: created when first needed, emptied when the
// build is good again.
function shown(doc, failure) {
  let panel = doc.getElementById("avra-dev-failure");
  if (!panel) {
    if (failure === "") return;
    panel = doc.createElement("pre");
    panel.id = "avra-dev-failure";
    panel.setAttribute("role", "alert");
    panel.setAttribute("style", "position:fixed;inset:auto 0 0 0;max-height:60vh;overflow:auto;margin:0;padding:16px;background:#1b1b1b;color:#ffb4b4;font:13px/1.4 ui-monospace,monospace;white-space:pre-wrap;z-index:2147483647;border-top:2px solid #ff6b6b");
    doc.body.appendChild(panel);
  }
  panel.textContent = failure;
  panel.hidden = failure === "";
}

// The module the page runs, named on the document element: set at start and
// again each time a swap lands, so a reader waits on the change.
function stands(doc, id) {
  if (doc.documentElement) doc.documentElement.setAttribute("data-avra-module", id);
}

// Hear the stream for the page running the module `mine`: a module that is
// no longer that one replaces it under the page — `swap()` starts the new
// module over the elements the page holds, so an edit is applied as a diff —
// or reloads the page where nothing can swap or the swap failed. A failure
// is shown, and a good build of the module it runs clears what was shown.
export function watch({ doc, mine, events, reload, swap = null }) {
  let running = mine;
  stands(doc, mine);
  events.addEventListener("built", async (said) => {
    if (said.data === running) { shown(doc, ""); return; }
    if (!swap) { reload(); return; }
    try {
      await swap();
      running = said.data;
      stands(doc, running);
      shown(doc, "");
    } catch (e) {
      console.warn(`avra: the module could not take over the page (${e && e.message ? e.message : e}) — reloading`);
      reload();
    }
  });
  events.addEventListener("failed", (said) => shown(doc, said.data));
}

// What the app tells the developer ("ui: …", its walk's warnings) reaches the console of a page
// nobody has open to the server's own output too: each such line is posted to `post`.
export function relayed({ console, post }) {
  const error = console.error.bind(console);
  console.error = (...said) => {
    error(...said);
    const text = said.join(" ").replace(/\s+$/, "");
    if (text.startsWith("ui: ")) post(text);
  };
}

// THE PANEL, a module of its own: the cache of this page, drawn by a program (`tools/dev-hud`) that `run` starts into
// a mount in a shadow root beside the app — never the app's tree, never its loop. It is told what the server says
// (`cache` events), not what the app does, so an app that traps leaves the last snapshot standing. `start` is
// `run` with the page's own rows (wasi) filled in, `source` the panel's module.
export async function panel({ doc, events, start, source }) {
  const host = doc.createElement("div");
  host.id = "avra-dev-panel";
  host.setAttribute("style", "position:fixed;inset:auto 0 0 0;z-index:2147483646;max-height:45vh;overflow:auto;margin:0;background:#fff;color:#111;border-top:1px solid #bbb;font:13px/1.4 ui-monospace,monospace");
  const shadow = host.attachShadow({ mode: "open" });
  const style = doc.createElement("style");
  const mount = doc.createElement("div");
  shadow.append(style, mount);
  doc.body.appendChild(host);
  // What the server tells while the module is still loading is kept and told once it runs.
  const early = [];
  let running = null;
  events.addEventListener("cache", (said) => { if (running) running.tell(said.data); else early.push(said.data); });
  running = await start(source, { document: doc, mount, style, state: new Uint8Array(0) });
  for (const said of early.splice(0)) running.tell(said);
  return running;
}

// THE CACHE'S SNAPSHOTS, posted: `api` is what the page offers (`on(take)` turns them on, `off()` stops them),
// each snapshot is a JSON frame, and `post(frame)` sends one to the server under this page's own `tab`. A
// frame that says what the last said is not sent again, and a burst is coalesced to the newest at the next
// animation frame, so the page posts at most once a frame and only what changed.
export function hudPosting({ api, post, raf }) {
  let latest = null;
  let sent = null;
  let waiting = false;
  const settled = (frame) => frame.replace(/"age_ms":\d+,/g, "");
  api.on((frame) => {
    latest = frame;
    if (waiting) return;
    waiting = true;
    raf(() => {
      waiting = false;
      if (latest === null || (sent !== null && settled(latest) === settled(sent))) return;
      sent = latest;
      post(latest);
    });
  });
  return () => api.off();
}

if (typeof document !== "undefined") {
  relayed({ console, post: (text) => fetch("/@dev/said", { method: "POST", body: text, keepalive: true }).catch(() => {}) });
  // The cache's snapshots go to the server, one set of frames per tab: a page offers the verb once its module runs.
  const events = new EventSource("/@dev/events");
  const tab = Math.random().toString(36).slice(2, 10);
  const posting = () => hudPosting({
    api: globalThis.avraHud,
    raf: (cb) => requestAnimationFrame(cb),
    post: (frame) => fetch("/@dev/cache", { method: "POST", headers: { "content-type": "application/json", "x-avra-tab": tab }, body: frame, keepalive: true }).catch(() => {}),
  });
  if (globalThis.avraHud) posting(); else addEventListener("avra-hud", posting, { once: true });
  // The panel starts beside the app; a page that cannot start it is no worse for it.
  panel({
    doc: document,
    events,
    source: "/@dev/panel.wasm",
    start: async (source, options) => {
      const { run } = await import("./bootstrap.js");
      const { wasiPreview1 } = await import("./wasi.js");
      return run(source, { ...options, wasi: (memory) => wasiPreview1(memory, () => {}), failed: (e) => console.warn(`avra: the dev panel failed (${e && e.message ? e.message : e})`) });
    },
  }).catch((e) => console.warn(`avra: the dev panel did not start (${e && e.message ? e.message : e})`));
  watch({
    doc: document,
    mine: document.querySelector('meta[name="avra-module"]').content,
    events,
    reload: () => location.reload(),
    // Asked when a build lands, not when this script loads: the page's own
    // script offers the verb once its module runs.
    swap: async () => {
      if (typeof globalThis.avraSwap !== "function") throw new Error("the page offers no swap");
      await globalThis.avraSwap("./app.wasm");
    },
  });
}
