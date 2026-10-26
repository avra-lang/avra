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

// Hear the stream for the page running the module `mine`: a module that is
// no longer that one replaces it under the page — `swap()` starts the new
// module over the elements the page holds, so an edit is applied as a diff —
// or reloads the page where nothing can swap or the swap failed. A failure
// is shown, and a good build of the module it runs clears what was shown.
export function watch({ doc, mine, events, reload, swap = null }) {
  let running = mine;
  events.addEventListener("built", async (said) => {
    if (said.data === running) { shown(doc, ""); return; }
    if (!swap) { reload(); return; }
    try {
      await swap();
      running = said.data;
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

if (typeof document !== "undefined") {
  relayed({ console, post: (text) => fetch("/@dev/said", { method: "POST", body: text, keepalive: true }).catch(() => {}) });
  watch({
    doc: document,
    mine: document.querySelector('meta[name="avra-module"]').content,
    events: new EventSource("/@dev/events"),
    reload: () => location.reload(),
    // Asked when a build lands, not when this script loads: the page's own
    // script offers the verb once its module runs.
    swap: async () => {
      if (typeof globalThis.avraSwap !== "function") throw new Error("the page offers no swap");
      await globalThis.avraSwap("./app.wasm");
    },
  });
}
