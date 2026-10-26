// A real browser, driven with nothing installed: Firefox, headless, over
// WebDriver BiDi — the W3C protocol it speaks on a WebSocket, which node
// speaks itself. The input is the browser's own: a pointer pressed at a
// point, keys pressed in order, so an element hears what a user's hand
// would make it hear. One page, a throwaway profile, gone at `close`.
import { spawn } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

// Where this machine keeps Firefox: `FIREFOX`, else the usual places.
export function firefoxBinary() {
  const places = [process.env.FIREFOX, "/Applications/Firefox.app/Contents/MacOS/firefox", "/usr/bin/firefox", "/usr/local/bin/firefox", "/snap/bin/firefox"];
  return places.find((p) => p && fs.existsSync(p)) || null;
}

// The keys a page hears by name, as WebDriver spells them.
export const KEY = { enter: "", tab: "", escape: "", left: "", right: "" };

const launches = 4;

// The BiDi address a launched Firefox names, or why it named none within `wait` ms.
const listening = (child, wait) => new Promise((yes, no) => {
  let said = "";
  const late = setTimeout(() => no(new Error(`Firefox named no BiDi address: ${said.slice(-400)}`)), wait);
  const read = (chunk) => {
    said += chunk;
    const found = said.match(/WebDriver BiDi listening on (ws:\/\/\S+)/);
    if (found) { clearTimeout(late); yes(found[1]); }
  };
  child.stderr.on("data", read);
  child.stdout.on("data", read);
  child.on("exit", (code) => { clearTimeout(late); no(new Error(`Firefox exited ${code}: ${said.slice(-400)}`)); });
});

export async function openPage(binary, url, { width = 900, height = 700, prefs = {} } = {}) {
  // The engine's own settings this page runs under, as a profile writes them.
  const settings = Object.entries(prefs).map(([name, value]) => `user_pref(${JSON.stringify(name)}, ${JSON.stringify(value)});\n`).join("");
  let profile = null;
  const fresh = () => {
    if (profile) fs.rmSync(profile, { recursive: true, force: true });
    profile = fs.mkdtempSync(path.join(os.tmpdir(), "avra-firefox-"));
    fs.writeFileSync(path.join(profile, "user.js"), settings);
    return profile;
  };
  // Firefox refuses a HOME another user owns, and a container denies the
  // user namespaces its content sandbox needs, so root runs it unsandboxed.
  const root = process.getuid?.() === 0;
  const envFor = (home) => ({ ...process.env, HOME: home, ...(root ? { MOZ_DISABLE_CONTENT_SANDBOX: "1", MOZ_DISABLE_GMP_SANDBOX: "1", MOZ_DISABLE_RDD_SANDBOX: "1", MOZ_DISABLE_SOCKET_PROCESS_SANDBOX: "1" } : {}) });
  // A launch that names no BiDi address in a while is a stalled start, which a
  // loaded machine produces now and then: it is killed and tried again, in a
  // profile of its own, since a killed one leaves its lock behind.
  let child;
  const gone = () => { child?.kill(); if (profile) fs.rmSync(profile, { recursive: true, force: true }); };
  process.on("exit", gone);
  let address;
  for (let attempt = 1; !address; attempt++) {
    const home = fresh();
    child = spawn(binary, ["--headless", "--no-remote", "--profile", home, "--remote-debugging-port=0"], { stdio: ["ignore", "pipe", "pipe"], env: envFor(home) });
    try { address = await listening(child, attempt < launches ? 25000 : 120000); } catch (e) { child.kill(); if (attempt >= launches) throw e; }
  }

  const socket = new WebSocket(`${address}/session`);
  await new Promise((yes, no) => { socket.onopen = yes; socket.onerror = () => no(new Error(`no BiDi session at ${address}`)); });
  let asked = 0;
  const waiting = new Map();
  const logged = [];
  socket.onmessage = (message) => {
    const said = JSON.parse(message.data);
    if (said.type === "event") { if (said.method === "log.entryAdded") logged.push(said.params); return; }
    const who = waiting.get(said.id);
    if (!who) return;
    waiting.delete(said.id);
    if (said.type === "error") who.no(new Error(`${who.method}: ${said.error}: ${said.message}`)); else who.yes(said.result);
  };
  const send = (method, params = {}) => new Promise((yes, no) => {
    const id = ++asked;
    waiting.set(id, { yes, no, method });
    socket.send(JSON.stringify({ id, method, params }));
  });

  await send("session.new", { capabilities: {} });
  await send("session.subscribe", { events: ["log.entryAdded"] });
  const { context } = await send("browsingContext.create", { type: "tab" });
  await send("browsingContext.setViewport", { context, viewport: { width, height } });
  await send("browsingContext.navigate", { context, url, wait: "complete" });

  // An expression's value in the page, awaited, as JSON carries it.
  const read = async (expression) => {
    const answer = await send("script.evaluate", { expression: `(async () => JSON.stringify(await (${expression})))()`, target: { context }, awaitPromise: true, resultOwnership: "none" });
    if (answer.type === "exception") throw new Error(`${expression} threw: ${answer.exceptionDetails.text}`);
    return answer.result.value === undefined ? undefined : JSON.parse(answer.result.value);
  };
  // A PAINT COMES AT THE DISPLAY'S NEXT FRAME: an event marks the app and the
  // page paints when the browser asks, so a reader of the page waits for that
  // frame — two, since the first may be the one the event itself raced.
  const framed = () => read("new Promise((done) => requestAnimationFrame(() => requestAnimationFrame(() => done(1))))");
  const act = async (actions) => {
    const done = await send("input.performActions", { context, actions });
    await framed();
    return done;
  };

  const pressAt = (x, y) => act([{ type: "pointer", id: "mouse", parameters: { pointerType: "mouse" }, actions: [{ type: "pointerMove", x, y }, { type: "pointerDown", button: 0 }, { type: "pointerUp", button: 0 }] }]);
  // The pointer pressed at one point, moved, and let go at another.
  const drag = (from, to) => act([{ type: "pointer", id: "mouse", parameters: { pointerType: "mouse" }, actions: [{ type: "pointerMove", x: from.x, y: from.y }, { type: "pointerDown", button: 0 }, { type: "pointerMove", x: to.x, y: to.y }, { type: "pointerUp", button: 0 }] }]);

  return {
    read,
    // The display's next frame, which is when the program's paint comes.
    frame: framed,
    // Every warning and error the page's console holds, and every uncaught one.
    complaints: () => logged.filter((entry) => entry.level === "error" || entry.level === "warn").map((entry) => `${entry.level}: ${entry.text}`),
    // The pointer pressed and let go at a point of the window.
    pressAt,
    drag,
    // The pointer pressed and let go at the middle of the element `selecting` answers.
    async press(selecting) {
      const at = await read(`(() => { const el = ${selecting}; el.scrollIntoView({ block: "nearest" }); const r = el.getBoundingClientRect(); return { x: Math.round(r.x + r.width / 2), y: Math.round(r.y + r.height / 2) }; })()`);
      await pressAt(at.x, at.y);
    },
    // These keys, each pressed and let go, sent to whatever holds the focus.
    async type(...keys) {
      await act([{ type: "key", id: "keys", actions: keys.flatMap((value) => [{ type: "keyDown", value }, { type: "keyUp", value }]) }]);
    },
    async screenshot(file) {
      const shot = await send("browsingContext.captureScreenshot", { context, origin: "viewport" });
      fs.writeFileSync(file, Buffer.from(shot.data, "base64"));
    },
    async close() {
      try { await send("browser.close"); } catch { /* already gone */ }
      process.off("exit", gone);
      gone();
    },
  };
}
