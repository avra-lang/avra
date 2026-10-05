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
// no longer that one reloads the page, a failure is shown, and a good
// build of the module it runs clears what was shown.
export function watch({ doc, mine, events, reload }) {
  events.addEventListener("built", (said) => { if (said.data !== mine) reload(); else shown(doc, ""); });
  events.addEventListener("failed", (said) => shown(doc, said.data));
}

if (typeof document !== "undefined") {
  watch({
    doc: document,
    mine: document.querySelector('meta[name="avra-module"]').content,
    events: new EventSource("/@dev/events"),
    reload: () => location.reload(),
  });
}
