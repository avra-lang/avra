// The dev client, by its own verbs over a stub document: what it makes of
// an answer, when it reloads, and that a failed build is shown and a
// mended one clears it.
import { standingOf, verdict, watch } from "./dev.js";
import { stubDocument, stubElement } from "./stub_dom.js";

let passed = 0;
let failed = 0;
const test = (name, holds) => {
  if (holds) { passed++; console.log(`✓ ${name}`); } else { failed++; console.log(`✗ ${name}`); }
};

test("a standing is its number, its module and what a failed build said", (() => {
  const s = standingOf("3\nabc\nerror: x\n  at y");
  return s.serial === "3" && s.module === "abc" && s.failure === "error: x\n  at y";
})());
test("a good standing says nothing failed", standingOf("1\nabc\n").failure === "" && standingOf("1\nabc").failure === "");
test("the module this page runs, standing good, is left alone", verdict("abc", standingOf("1\nabc\n")).show === "");
test("another module reloads the page", verdict("abc", standingOf("2\nxyz\n")).reload === true);
test("a failed build is shown and never reloads, whatever module stands", (() => {
  const act = verdict("abc", standingOf("2\nxyz\nbroken"));
  return act.show === "broken" && !act.reload;
})());

// A page with a body the panel can join, found again by its id.
const page = () => {
  const doc = stubDocument();
  doc.body = stubElement("body");
  doc.body.appendChild = (el) => doc.body.insertBefore(el, null);
  doc.getElementById = (id) => doc.body.childNodes.find((el) => el.id === id) || null;
  return doc;
};
// The client run over `answers`, each handed to one ask; a thrown answer is
// a server that did not answer. Ends when the page reloads.
const session = async (answers) => {
  const doc = page();
  const asked = [];
  const seen = [];
  let breaths = 0;
  let reloads = 0;
  await watch({
    doc,
    mine: "abc",
    ask: async (since) => {
      asked.push(since);
      const next = answers.shift();
      const panel = doc.getElementById("avra-dev-failure");
      seen.push(panel && !panel.hidden ? panel.textContent : "");
      if (next instanceof Error) throw next;
      return next;
    },
    reload: () => { reloads++; },
    breath: async () => { breaths++; },
  });
  return { asked, seen, breaths, reloads };
};

const ran = await session(["1\nabc\n", "2\nabc\nbroken here", new Error("gone"), "3\nabc\n", "4\nxyz\n"]);
test("the first ask names no number, and each later one the number last heard", ran.asked.join() === ",1,2,2,3");
test("a failed build is shown over the page", ran.seen[2] === "broken here");
test("a server that does not answer is asked again after a breath", ran.breaths === 1);
test("a mended build clears what was shown", ran.seen[4] === "");
test("a new module reloads the page, once", ran.reloads === 1);

console.log(`dev: ${passed}/${passed + failed}`);
process.exit(failed === 0 ? 0 : 1);
