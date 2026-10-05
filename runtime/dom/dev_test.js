// The dev client, by its own verb over a stub document and a stream it is
// handed: when it reloads, and that a failed build is shown and a mended
// one clears it.
import { watch } from "./dev.js";
import { stubDocument, stubElement } from "./stub_dom.js";

let passed = 0;
let failed = 0;
const test = (name, holds) => {
  if (holds) { passed++; console.log(`✓ ${name}`); } else { failed++; console.log(`✗ ${name}`); }
};

// A page with a body the panel can join, found again by its id.
const page = () => {
  const doc = stubDocument();
  doc.body = stubElement("body");
  doc.body.appendChild = (el) => doc.body.insertBefore(el, null);
  doc.getElementById = (id) => doc.body.childNodes.find((el) => el.id === id) || null;
  return doc;
};
// A stream a test speaks through: each event handed to whoever listens for it.
const stream = () => {
  const heard = new Map();
  return { addEventListener: (name, hear) => heard.set(name, hear), say: (name, data) => heard.get(name)({ data }) };
};
// The client over a fresh page running module `abc`.
const client = () => {
  const made = { doc: page(), events: stream(), reloads: 0 };
  watch({ doc: made.doc, mine: "abc", events: made.events, reload: () => { made.reloads++; } });
  made.showing = () => { const panel = made.doc.getElementById("avra-dev-failure"); return panel && !panel.hidden ? panel.textContent : ""; };
  return made;
};

const same = client();
same.events.say("built", "abc");
test("the module this page runs, built, is left alone", same.reloads === 0 && same.showing() === "");

const moved = client();
moved.events.say("built", "xyz");
test("another module reloads the page", moved.reloads === 1);

const broke = client();
broke.events.say("failed", "error: x\n  at y");
test("a failed build is shown over the page, whole", broke.showing() === "error: x\n  at y");
test("a failed build never reloads: the last good module keeps running", broke.reloads === 0);
test("what is shown is an alert a reader is told of", broke.doc.getElementById("avra-dev-failure").attrs.role === "alert");
broke.events.say("failed", "error: z");
test("a second failure replaces the first", broke.showing() === "error: z" && broke.doc.body.childNodes.length === 1);
broke.events.say("built", "abc");
test("the same module built again clears what was shown", broke.showing() === "" && broke.reloads === 0);
broke.events.say("failed", "again");
broke.events.say("built", "xyz");
test("a mended build of another module reloads", broke.reloads === 1);

console.log(`dev: ${passed}/${passed + failed}`);
process.exit(failed === 0 ? 0 : 1);
