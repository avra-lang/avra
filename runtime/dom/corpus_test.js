// Holds the page's own host to the MODEL host the program's tests judge
// the diff by: cases the program grew (realize/dom/tests/support/corpus.av
// names the lines) are applied here by bootstrap.js to a stub document,
// and the page it ends holding, what it echoes when a user speaks and what
// each listener says are compared with what the model held. Two hosts
// that read one wire two ways disagree here.
//
//   node corpus_test.js <file of lines>     (no file: the standard input)
import { readFileSync } from "node:fs";
import { createApplier } from "./bootstrap.js";
import { SAYS } from "./wire.gen.js";
import { stubDocument, stubElement } from "./stub_dom.js";

const unworded = (w) => (w === "-" ? "" : Buffer.from(w, "base64").toString("utf8"));
const bytesOf = (w) => new Uint8Array(Buffer.from(w, "base64"));

// What a stub node is made with: every other key is a property a patch or
// a user wrote.
const BUILT = new Set(Object.keys(stubElement("x")).concat(["__avra_id", "__avra_listeners", "showModal", "close"]));

// A stub element with a page's door: `showModal` opens it, where it
// stands on the page and is not open already, and `close` shuts it.
const connected = (n, mount) => n === mount || (n.parentNode !== null && connected(n.parentNode, mount));
function doored(doc, mount) {
  return {
    ...doc,
    createElement: (tag) => Object.assign(doc.createElement(tag), {
      showModal() {
        if (this.open || !connected(this, mount)) throw new Error("showModal: the element is open already, or stands nowhere on the page");
        this.open = true;
      },
      close() { this.open = false; },
    }),
  };
}

// The page as realize/dom/tests/support/seen.av's `told` tells it outward:
// a line an element, its number, tag, attributes by name, properties off
// rest, and each event THE DOCUMENT hears, by the kind the host holds it
// under.
const quoted = (s) => `"${s.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\\n")}"`;
const propShown = (v) => (v === true ? "true" : typeof v === "string" ? quoted(v) : String(v));
function line(n) {
  const number = `#${n.__avra_id} `;
  if (n.tagName === "#text") return number + quoted(n.textContent);
  const attrs = Object.keys(n.attrs).sort().map((k) => ` ${k}=${quoted(n.attrs[k])}`).join("");
  const props = Object.keys(n).filter((k) => !BUILT.has(k) && n[k] !== "" && n[k] !== false).sort()
    .map((k) => ` .${k}=${propShown(n[k])}`).join("");
  const ears = [...n.listeners.keys()].map((event) => [kindOf(n, event), event]).sort((a, b) => a[0] - b[0])
    .map(([kind, event]) => ` @${kind}:${event}`).join("");
  return number + n.tagName + attrs + props + ears;
}
// The kind the host holds a listener for `event` under: -1 for one the
// document still hears and the host has let go of.
function kindOf(n, event) {
  for (const [kind, held] of n.__avra_listeners || []) if (held.event === event) return kind;
  return -1;
}
const lines = (n, indent) => n.childNodes.flatMap((c) => [indent + line(c), ...lines(c, indent + "  ")]);
const told = (mount) => lines(mount, "").join("\n");

const find = (n, id) => {
  for (const c of n.childNodes) {
    if (c.__avra_id === id) return c;
    const under = find(c, id);
    if (under) return under;
  }
  return null;
};

// What a host's echo says, as one text: who, the kind, the tag and the value.
const echoText = ([who, kind, said]) => `${who} ${kind} ${said ? said.says : SAYS.nothing} ${said ? String(said.value) : ""}`;

// The listener for `event` on element `id` spoken to once: its echo, and
// whether it stopped the page's own answer — which, for a dismissal left
// to the page, shuts the element.
function spoken(page, id, event) {
  const el = find(page.mount, id);
  const listener = el && el.listeners.get(event);
  if (!listener) return { echo: `nothing on ${id} hears ${event}`, stopped: false };
  page.sent.length = 0;
  let stopped = false;
  listener({ preventDefault() { stopped = true; } });
  if (event === "cancel" && !stopped) el.close();
  return { echo: page.sent.map(echoText).join(" | "), stopped };
}

// What a property is given so its listener has something to say.
const probe = (says) => (says === SAYS.flag ? true : says === SAYS.number ? "3" : "p");

let fails = 0;
let checks = 0;
let cases = 0;
let page = null;
let named = "";
function check(what, got, want) {
  checks++;
  if (got === want) return;
  fails++;
  if (fails <= 5) console.log(`✗ case ${named}: ${what}\n— the model:\n${want}\n— the host:\n${got}`);
}

const act = {
  case: (seed, turn) => {
    cases++;
    named = `${seed} ${turn}`;
    const mount = stubElement("root");
    const sent = [];
    page = { mount, sent, apply: createApplier(doored(stubDocument(), mount), mount, (who, kind, said) => sent.push([who, kind, said])) };
  },
  frame: (bytes) => {
    try { page.apply(bytesOf(bytes)); } catch (e) { check("a frame is applied", e.message, "applied"); }
  },
  page: (want) => check("the page", told(page.mount), unworded(want)),
  // What a user left on an element with nothing hearing of it.
  move: (id, name, tag, value) => {
    const el = find(page.mount, Number(id));
    if (el) el[name] = Number(tag) === SAYS.flag ? unworded(value) !== "" : unworded(value);
  },
  say: (id, event, reads, tag, value, kind, says, echoed) => {
    const el = find(page.mount, Number(id));
    if (el && reads !== "-") el[reads] = Number(tag) === SAYS.flag ? unworded(value) !== "" : unworded(value);
    check(`the echo of ${event} on ${id}`, spoken(page, Number(id), event).echo, `${id} ${kind} ${says} ${unworded(echoed)}`);
  },
  hear: (id, event, kind, says, reads, prevents) => {
    const el = find(page.mount, Number(id));
    if (el && reads !== "-") el[reads] = probe(Number(says));
    const value = Number(says) === SAYS.nothing ? "" : String(Number(says) === SAYS.number ? 3 : probe(Number(says)));
    const got = spoken(page, Number(id), event);
    check(`what ${event} on ${id} says`, `${got.echo} stopped=${got.stopped}`, `${id} ${kind} ${says} ${value} stopped=${prevents === "1"}`);
  },
};

const source = readFileSync(process.argv[2] || 0, "utf8");
for (const text of source.split("\n")) {
  if (text === "") continue;
  const [word, ...rest] = text.split(" ");
  if (!act[word]) { console.log(`✗ a line opens with ${word}, which this harness does not read`); process.exit(1); }
  act[word](...rest);
}
if (cases === 0) { console.log("✗ no case was read — nothing was compared"); process.exit(1); }
console.log(`${checks - fails}/${checks} checks hold over ${cases} cases`);
if (fails > 0) process.exit(1);
