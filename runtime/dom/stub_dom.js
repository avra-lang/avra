// A document small enough to read, for the host's tests and the headless
// demo: elements and text nodes that keep their children in order, their
// attributes and their listeners — the calls bootstrap.js makes, no more.
//
// IT LOSES WHAT A PAGE LOSES. An element taken off the page gives up the
// focus under it and how far it was scrolled, as a real one does; one
// carried by `moveBefore` keeps both. A page's root is the node named
// `root`: what stands under one stands on the page.
function node(tagName, doc = null) {
  return {
    tagName, childNodes: [], attrs: {}, textContent: "", parentNode: null, listeners: new Map(),
    ownerDocument: doc, scrollTop: 0, selectionStart: null, selectionEnd: null, selectionDirection: "none",
    get nextSibling() {
      if (!this.parentNode) return null;
      const kin = this.parentNode.childNodes;
      return kin[kin.indexOf(this) + 1] || null;
    },
    get isConnected() { return this.tagName === "root" || (this.parentNode !== null && this.parentNode.isConnected); },
    contains(other) { return other === this || this.childNodes.some((c) => c.contains(other)); },
    setAttribute(k, v) { this.attrs[k] = v; },
    removeAttribute(k) { delete this.attrs[k]; },
    // As a page does it: before itself is where it stands, and before a
    // node that is no child of this one is refused.
    insertBefore(c, at) {
      if (at === c) at = c.nextSibling;
      if (at && at.parentNode !== this) throw new Error("insertBefore: the node to insert before is not a child of this node");
      if (c.parentNode) c.parentNode.removeChild(c);
      this.childNodes.splice(at ? this.childNodes.indexOf(at) : this.childNodes.length, 0, c);
      c.parentNode = this;
    },
    removeChild(c) {
      const i = this.childNodes.indexOf(c);
      if (i >= 0) this.childNodes.splice(i, 1);
      c.parentNode = null;
      taken(c);
    },
    addEventListener(name, fn) { this.listeners.set(name, fn); },
    removeEventListener(name) { this.listeners.delete(name); },
    focus() { if (this.ownerDocument && this.isConnected) this.ownerDocument.activeElement = this; },
    setSelectionRange(start, end, direction = "none") { this.selectionStart = start; this.selectionEnd = end; this.selectionDirection = direction; },
  };
}

// What a page drops from an element taken off it, and from all under it.
function taken(n) {
  if (n.ownerDocument && n.ownerDocument.activeElement === n) n.ownerDocument.activeElement = null;
  n.scrollTop = 0;
  for (const c of n.childNodes) taken(c);
}

// `carries: true` is a page that can carry an element standing on it to
// another place (`moveBefore`), dropping nothing.
export function stubDocument({ carries = false } = {}) {
  const doc = { activeElement: null };
  const made = (tag) => {
    const n = node(tag, doc);
    if (carries) {
      n.moveBefore = function (c, at) {
        if (!c.isConnected || !this.isConnected) throw new Error("moveBefore: both must stand on the page");
        const from = c.parentNode.childNodes;
        from.splice(from.indexOf(c), 1);
        this.childNodes.splice(at ? this.childNodes.indexOf(at) : this.childNodes.length, 0, c);
        c.parentNode = this;
      };
    }
    return n;
  };
  doc.createElement = made;
  doc.createTextNode = (content) => { const t = made("#text"); t.textContent = content; return t; };
  return doc;
}

export const stubElement = node;

// What a reader of the page sees under `n`: its own text nodes and every
// element's below it, in order.
export function textOf(n) {
  if (n.tagName === "#text") return n.textContent;
  return n.childNodes.map(textOf).join("");
}
