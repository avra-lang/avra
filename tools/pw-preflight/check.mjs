const pw = await import("./node_modules/playwright/index.mjs");
const url = process.argv[2]; const browser = await pw.webkit.launch(); let bad = 0;
const say = (ok, ...a) => { if (!ok) bad++; console.log(ok ? "ok   " : "WRONG", ...a); };
for (const [name, base] of [["desktop", { viewport: { width: 1000, height: 800 } }], ["phone", pw.devices["iPhone 13 Pro Max"]]]) for (const scheme of ["light", "dark"]) {
  const ctx = await browser.newContext({ ...base, colorScheme: scheme }); ctx.setDefaultTimeout(5000); const page = await ctx.newPage();
  const fetched = {}; page.on("request", (r) => { const k = r.url().split("/").pop(); fetched[k] = (fetched[k] ?? 0) + 1; });
  page.on("pageerror", (e) => say(false, name, scheme, "pageerror", e.message.slice(0, 120)));
  await page.goto(url); await page.getByText("Auto", { exact: true }).waitFor({ timeout: 15000 }); await page.waitForTimeout(600);
  const bg = async () => ((await page.evaluate(() => getComputedStyle(document.body).backgroundColor)) === "rgb(255, 255, 255)" ? "light" : "dark");
  const want = { Auto: scheme, Light: "light", Dark: "dark" };
  for (const w of ["Dark", "Light", "Auto"]) { const b = page.getByText(w, { exact: true }); name === "phone" ? await b.tap() : await b.click(); await page.waitForTimeout(400); const got = await bg(); say(got === want[w], name, scheme, "scheme", w, "->", got); }
  const title = `check ${name} ${scheme}`; await page.fill("input[type=text], input:not([type])", title); await page.keyboard.press("Enter"); await page.waitForTimeout(900);
  const saved = (await (await fetch(new URL("/tasks", url))).json()).find((t) => t.title === title);
  say(!!saved, name, scheme, "Enter adds and saves"); say(await page.getByText(title).count() > 0, name, scheme, "the new task is drawn");
  say((await page.inputValue("input[type=text], input:not([type])")) === "", name, scheme, "the draft clears");
  if (saved) await fetch(new URL(`/tasks/${saved.id}`, url), { method: "DELETE" });
  const wasm = Object.entries(fetched).filter(([k]) => k.endsWith(".wasm")); say(wasm.length === 1 && wasm[0][1] === 1, name, scheme, "the module is fetched once:", JSON.stringify(wasm));
  say(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), name, scheme, "no sideways scroll");
  say(await page.evaluate(() => !document.querySelector("[role=alert]")), name, scheme, "no failure drawn");
  await page.screenshot({ path: `check-${name}-${scheme}.png` }); await ctx.close();
}
await browser.close(); console.log("bad", bad);
