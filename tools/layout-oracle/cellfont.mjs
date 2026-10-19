// A font whose every printable ASCII glyph is blank and advances exactly one
// em, so at a font size of one pixel a character is one pixel wide: a cell.
// Built here, byte by byte, so the layout oracle needs no font file and a
// browser's soft wrapping of text can be compared with the cell measure.
const u16 = (n) => [(n >> 8) & 255, n & 255];
const i16 = (n) => u16(n & 0xffff);
const u32 = (n) => [(n >>> 24) & 255, (n >>> 16) & 255, (n >>> 8) & 255, n & 255];
const tag = (s) => [...s].map((c) => c.charCodeAt(0));
const pad4 = (bytes) => bytes.concat(Array((4 - (bytes.length % 4)) % 4).fill(0));

const UNITS = 1000;

// The .notdef glyph and one blank glyph for each printable ASCII character.
const GLYPHS = 96;

function head() {
  return [...u32(0x00010000), ...u32(0x00010000), ...u32(0), ...u32(0x5f0f3cf5), ...u16(0), ...u16(UNITS), ...u32(0), ...u32(0), ...u32(0), ...u32(0), ...i16(0), ...i16(0), ...i16(0), ...i16(0), ...u16(0), ...u16(8), ...i16(2), ...i16(0), ...i16(0)];
}

function hhea() {
  return [...u32(0x00010000), ...i16(800), ...i16(-200), ...i16(0), ...u16(UNITS), ...i16(0), ...i16(0), ...i16(0), ...i16(1), ...i16(0), ...i16(0), ...i16(0), ...i16(0), ...i16(0), ...i16(0), ...i16(0), ...u16(1)];
}

function maxp() {
  return [...u32(0x00010000), ...u16(GLYPHS), ...u16(0), ...u16(0), ...u16(0), ...u16(0), ...u16(1), ...u16(0), ...u16(0), ...u16(0), ...u16(0), ...u16(0), ...u16(0), ...u16(0), ...u16(0)];
}

function hmtx() {
  return [...u16(UNITS), ...i16(0), ...Array(GLYPHS - 1).fill([0, 0]).flat()];
}

// Format 4: printable ASCII to the one blank glyph.
function cmap() {
  const sub = [...u16(4), ...u16(32), ...u16(0), ...u16(4), ...u16(4), ...u16(1), ...u16(0), ...u16(126), ...u16(0xffff), ...u16(0), ...u16(32), ...u16(0xffff), ...i16(1 - 32), ...i16(1), ...u16(0), ...u16(0)];
  return [...u16(0), ...u16(1), ...u16(3), ...u16(1), ...u32(12), ...sub];
}

function os2() {
  return [...u16(3), ...i16(UNITS), ...u16(400), ...u16(5), ...u16(0), ...i16(0), ...i16(0), ...i16(0), ...i16(0), ...i16(0), ...i16(0), ...i16(0), ...i16(0), ...i16(0), ...i16(0), ...i16(0), ...Array(10).fill(0), ...u32(1), ...u32(0), ...u32(0), ...u32(0), ...tag("NONE"), ...u16(0x40), ...u16(32), ...u16(126), ...i16(800), ...i16(-200), ...i16(0), ...u16(800), ...u16(200), ...u32(1), ...u32(0), ...i16(0), ...i16(0), ...u16(32), ...u16(0), ...u16(1)];
}

function name() {
  const text = "Cell";
  const utf16 = [...text].flatMap((c) => u16(c.charCodeAt(0)));
  const records = [1, 2, 3, 4, 6].map((id, i) => [...u16(3), ...u16(1), ...u16(0x409), ...u16(id), ...u16(utf16.length), ...u16(0)]);
  return [...u16(0), ...u16(records.length), ...u16(6 + records.length * 12), ...records.flat(), ...utf16];
}

function post() {
  return [...u32(0x00030000), ...u32(0), ...i16(-100), ...i16(50), ...u32(1), ...u32(0), ...u32(0), ...u32(0), ...u32(0)];
}

export function cellFontBase64() {
  const tables = { OS_2: os2(), cmap: cmap(), glyf: [...i16(0), ...i16(0), ...i16(0), ...i16(0), ...i16(0), ...u16(0)], head: head(), hhea: hhea(), hmtx: hmtx(), loca: [...u16(0), ...Array(GLYPHS).fill(u16(6)).flat()], maxp: maxp(), name: name(), post: post() };
  const names = Object.keys(tables).sort();
  const dir = 12 + names.length * 16;
  let offset = dir;
  const entries = [];
  const bodies = [];
  for (const n of names) {
    const body = pad4(tables[n]);
    entries.push([...tag(n.replace("_", "/")), ...u32(0), ...u32(offset), ...u32(tables[n].length)]);
    bodies.push(body);
    offset += body.length;
  }
  const bytes = [...u32(0x00010000), ...u16(names.length), ...u16(128), ...u16(3), ...u16(names.length * 16 - 128), ...entries.flat(), ...bodies.flat()];
  return Buffer.from(bytes).toString("base64");
}
