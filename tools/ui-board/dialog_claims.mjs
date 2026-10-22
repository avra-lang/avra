// The words of each claim `outsidePresses` makes, in order, so a run that cannot make them can name them.
export const outsidePressWords = (where) => [
  `a press inside it keeps it open${where}`,
  `a press that starts inside it and ends outside keeps it open${where}`,
  `a press outside it sends it away${where}`,
  `a press outside it over a control behind it sends it away and reaches nothing there${where}`,
  `the program heard that: About opens it again${where}`,
  `after Escape sends it away, the next press on a control behind it reaches that control${where}`,
];

// A press outside the board's open dialog sends it away, as Escape does; one
// inside it, or one that starts inside and ends outside, sends nothing away,
// and the press that sends it away reaches nothing behind it — while the next
// press after Escape sends it away does.
// `on` is any page that speaks `read`, `press`, `pressAt`, `drag` and `escape`, whatever
// engine drives it; `where` is what the claims say of it, `claim(words, holds)`
// records each, and `named` selects a control by its accessible name.
export const outsidePresses = async (on, where, claim, named) => {
  const says = outsidePressWords(where);
  const shown = `document.querySelector("dialog")`;
  const open = () => on.read(`${shown}.open`);
  await on.press(named("About"));
  const r = await on.read(`(() => { const r = ${shown}.getBoundingClientRect(); return { x: Math.round(r.left + 6), y: Math.round(r.top + 6) }; })()`);
  const away = { x: 4, y: 4 };
  await on.pressAt(r.x, r.y);
  claim(says[0], await open());
  await on.drag(r, away);
  claim(says[1], await open());
  await on.pressAt(away.x, away.y);
  claim(says[2], await open() === false);
  await on.press(named("About"));
  const behind = await on.read(`(() => {
    const d = ${shown}.getBoundingClientRect();
    const outside = (x, y) => x < d.left || x >= d.right || y < d.top || y >= d.bottom;
    const at = [...document.querySelectorAll("li input")].map((el, nth) => { const r = el.getBoundingClientRect(); return { nth, x: Math.round(r.x + r.width / 2), y: Math.round(r.y + r.height / 2), checked: el.checked }; }).find((c) => outside(c.x, c.y));
    return at ?? null;
  })()`);
  await on.pressAt(behind.x, behind.y);
  claim(says[3], await open() === false && await on.read(`document.querySelectorAll("li input")[${behind.nth}].checked`) === behind.checked);
  await on.press(named("About"));
  claim(says[4], await open());
  await on.escape();
  const spot = await on.read(`(() => { const el = document.querySelector("li input"); const r = el.getBoundingClientRect(); return { x: Math.round(r.x + r.width / 2), y: Math.round(r.y + r.height / 2), checked: el.checked }; })()`);
  await on.pressAt(spot.x, spot.y);
  claim(says[5], await open() === false && await on.read(`document.querySelector("li input").checked`) !== spot.checked);
  await on.pressAt(spot.x, spot.y);
};
