// The dev server's own client — served by `avra dev` and by nothing else; a
// production page never carries it. It asks the server what the build is
// and is answered when that moves: a module that is no longer the one this
// page loaded reloads the page, and a build that failed is SHOWN over the
// page while the last good module keeps running under it.
//
// THE CHANNEL IS ONE LONG POLL: `GET /@dev/build` answers the standing
// build at once, and with `x-avra-since: <number>` only when the build has
// moved past that number. Three lines: the number, the module's id, and —
// from the third line on — what a failed build said, empty when it built.

// What the server answered, as its three parts.
export function standingOf(text) {
  const [serial, module, ...said] = text.split("\n");
  return { serial, module, failure: said.join("\n") };
}

// What the page does about a standing build: reload when the module is no
// longer the one it runs, else show the failure, or nothing.
export function verdict(mine, standing) {
  if (standing.failure !== "") return { show: standing.failure };
  if (standing.module !== mine) return { reload: true };
  return { show: "" };
}

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

// Ask until the page goes: each answer is acted on, and a server that does
// not answer is asked again after a breath — it may be restarting.
export async function watch({ doc, mine, ask, reload, breath }) {
  let since = null;
  for (;;) {
    let standing;
    try { standing = standingOf(await ask(since)); } catch { await breath(); continue; }
    since = standing.serial;
    const act = verdict(mine, standing);
    if (act.reload) { reload(); return; }
    shown(doc, act.show);
  }
}

if (typeof document !== "undefined") {
  watch({
    doc: document,
    mine: document.querySelector('meta[name="avra-module"]').content,
    ask: async (since) => (await fetch("/@dev/build", { cache: "no-store", headers: since === null ? {} : { "x-avra-since": since } })).text(),
    reload: () => location.reload(),
    breath: () => new Promise((go) => setTimeout(go, 500)),
  });
}
