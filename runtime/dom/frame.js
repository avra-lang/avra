// THE FIELD KINDS, as a JavaScript host reads them — the one spelling of each
// in this language, beside `packages/std-ui/src/frame/kinds.av`'s in Avra.
// Which kinds a record holds, and in what order, is never written here: the
// readers in `wire.gen.js` are generated from the program's own types.
//
// A word is a count in seven-bit groups, low group first; where a field may
// be absent, zero is none and any other word is one more. A number is the
// word of its zigzag. A flag is one byte. A fraction is eight bytes of bits,
// low byte first. A text is its byte length, then its bytes; texts are their
// count, then each. A value told once a stream is zero, its place, then the
// value, the first time, and one more than its place after.

const decoder = new TextDecoder();

// `bytes` to be read, its stream having been told `told` (kept by the caller
// across the stream's frames).
export function reader(bytes, told) {
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  let at = 0;
  const fault = (says) => { throw new Error(`a frame breaks a law at byte ${at}: ${says}`); };
  const byte = () => { if (at >= bytes.length) fault("it ends inside a record"); return bytes[at++]; };
  const word = () => { let n = 0, scale = 1, b; do { b = byte(); n += (b & 127) * scale; scale *= 128; } while (b >= 128); return n; };
  const r = {
    ended: () => at >= bytes.length,
    byte,
    word,
    // A count that may be absent, as the number it is, -1 for none.
    wordOrNone: () => word() - 1,
    // The word of `words` a count names.
    named: (words) => { const w = words[word()]; if (w === undefined) fault("a word names nothing"); return w; },
    // The word of `words` a count names, or null for none.
    namedOrNone: (words) => { const w = word(); if (w === 0) return null; const n = words[w - 1]; if (n === undefined) fault("a word names nothing"); return n; },
    number: () => { const z = word(); return z % 2 === 1 ? -(z + 1) / 2 : z / 2; },
    flag: () => { const b = byte(); if (b > 1) fault(`a flag is ${b}`); return b === 1; },
    fraction: () => { if (at + 8 > bytes.length) fault("it ends inside a fraction"); const x = view.getFloat64(at, true); at += 8; return x; },
    octets: () => { const n = word(); if (at + n > bytes.length) fault("octets run past it"); const o = bytes.slice(at, at + n); at += n; return o; },
    text: () => { const n = word(); if (at + n > bytes.length) fault("a text runs past it"); const s = decoder.decode(bytes.subarray(at, at + n)); at += n; return s; },
    texts: () => Array.from({ length: word() }, () => r.text()),
    // A value that may be absent: 0 for none, 1 then the value.
    maybe: (read) => { const p = word(); if (p === 0) return null; if (p !== 1) fault(`a presence word is ${p}`); return read(r); },
    told: (read) => {
      const ref = word();
      if (ref !== 0) { if (!(ref - 1 in told)) fault(`nothing was told at ${ref - 1}`); return told[ref - 1]; }
      const place = word();
      const value = read(r);
      told[place] = value;
      return value;
    },
    unknown: (type, code) => fault(`no ${type} variant is ${code}`),
  };
  return r;
}
