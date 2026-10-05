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

export async function openPage(binary, url, { width = 900, height = 700 } = {}) {
  const profile = fs.mkdtempSync(path.join(os.tmpdir(), "avra-firefox-"));
  const child = spawn(binary, ["--headless", "--no-remote", "--profile", profile, "--remote-debugging-port=0"], { stdio: ["ignore", "pipe", "pipe"] });
  const gone = () => { child.kill(); fs.rmSync(profile, { recursive: true, force: true }); };
  process.on("exit", gone);

  const address = await new Promise((yes, no) => {
    let said = "";
    const late = setTimeout(() => no(new Error(`Firefox named no BiDi address: ${said.slice(-400)}`)), 30000);
    const read = (chunk) => {
      said += chunk;
      const found = said.match(/WebDriver BiDi listening on (ws:\/\/\S+)/);
      if (found) { clearTimeout(late); yes(found[1]); }
    };
    child.stderr.on("data", read);
    child.stdout.on("data", read);
    child.on("exit", (code) => no(new Error(`Firefox exited ${code}: ${said.slice(-400)}`)));
  });

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
  const act = (actions) => send("input.performActions", { context, actions });

  const pressAt = (x, y) => act([{ type: "pointer", id: "mouse", parameters: { pointerType: "mouse" }, actions: [{ type: "pointerMove", x, y }, { type: "pointerDown", button: 0 }, { type: "pointerUp", button: 0 }] }]);

  return {
    read,
    // Every warning and error the page's console holds, and every uncaught one.
    complaints: () => logged.filter((entry) => entry.level === "error" || entry.level === "warn").map((entry) => `${entry.level}: ${entry.text}`),
    // The pointer pressed and let go at a point of the window.
    pressAt,
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
