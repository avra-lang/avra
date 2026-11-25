// THE HELD TAP: before the module adopts the page, a tap on the server's page is held, acknowledged
// at once, and handed to the module the moment it stands — on the very element, which adoption keeps.
(() => {
  const held = [];
  const standing = () => document.documentElement?.dataset.avra === "ready";
  const mark = (el) => el?.setAttribute?.("data-avra-held", "");
  const hold = (ev) => {
    if (standing() || !ev.isTrusted) return;
    const el = ev.target;
    if (!(el instanceof Element) || !el.closest("#app")) return;
    if (ev.type === "click") {
      // A field's own click is focus, never an action: what it holds is the adoption's to carry.
      if (el.matches("input:not([type=checkbox]):not([type=radio]):not([type=button]):not([type=submit]),textarea,select")) return;
      const box = el.matches('input[type="checkbox"],input[type="radio"]');
      // A box's own toggle stands as the acknowledgement; the replay restores it first, so the
      // module's click toggles it once.
      held.push({ type: "click", el, was: box ? !el.checked : null });
      mark(el.closest("button,label,input") ?? el);
    } else if (ev.type === "input") {
      if (!held.some((h) => h.type === "input" && h.el === el)) held.push({ type: "input", el });
    } else if (ev.type === "keydown" && ev.key === "Enter") {
      held.push({ type: "keydown", el, key: "Enter" });
    }
  };
  for (const t of ["click", "input", "keydown"]) addEventListener(t, hold, true);
  const replay = () => {
    for (const t of ["click", "input", "keydown"]) removeEventListener(t, hold, true);
    globalThis.__heldReplayed = { n: held.length, at: performance.now() };
    for (const h of held) {
      if (!h.el.isConnected) continue;
      if (h.type === "click") { if (h.was !== null) h.el.checked = h.was; h.el.click(); }
      else if (h.type === "input") h.el.dispatchEvent(new Event("input", { bubbles: true }));
      else h.el.dispatchEvent(new KeyboardEvent("keydown", { key: h.key, bubbles: true }));
    }
    for (const el of document.querySelectorAll("[data-avra-held]")) el.removeAttribute("data-avra-held");
  };
  new MutationObserver((_, o) => { if (standing()) { o.disconnect(); queueMicrotask(replay); } }).observe(document, { subtree: true, attributes: true, attributeFilter: ["data-avra"] });
  const style = document.createElement("style");
  style.textContent = "#app [data-avra-held]{opacity:.5!important;cursor:progress}";
  const place = () => (document.head ? document.head.append(style) : requestAnimationFrame(place));
  place();
})();
