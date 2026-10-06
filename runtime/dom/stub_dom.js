// A document small enough to read, for the host's tests and the headless
// demo: elements and text nodes that keep their children in order, their
// attributes and their listeners — the calls bootstrap.js makes, no more.
function node(tagName) {
  return {
    tagName, childNodes: [], attrs: {}, textContent: "", parentNode: null, listeners: new Map(),
    get nextSibling() {
      if (!this.parentNode) return null;
      const kin = this.parentNode.childNodes;
      return kin[kin.indexOf(this) + 1] || null;
    },
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
    removeChild(c) { const i = this.childNodes.indexOf(c); if (i >= 0) this.childNodes.splice(i, 1); c.parentNode = null; },
    addEventListener(name, fn) { this.listeners.set(name, fn); },
    removeEventListener(name) { this.listeners.delete(name); },
  };
}

export function stubDocument() {
  return {
    createElement: (tag) => node(tag),
    createTextNode: (content) => { const t = node("#text"); t.textContent = content; return t; },
  };
}

export const stubElement = node;

// What a reader of the page sees under `n`: its own text nodes and every
// element's below it, in order.
export function textOf(n) {
  if (n.tagName === "#text") return n.textContent;
  return n.childNodes.map(textOf).join("");
}
