import fs from "node:fs"; import zlib from "node:zlib";
const [wasmPath, rowsPath] = process.argv.slice(2);
const b = fs.readFileSync(wasmPath); const rows = JSON.parse(fs.readFileSync(rowsPath, "utf8"));
let p = 8; const leb = () => { let r = 0, s = 0, x; do { x = b[p++]; r |= (x & 0x7f) << s; s += 7; } while (x & 0x80); return r >>> 0; };
const secs = [];
while (p < b.length) { const id = b[p++]; const n = leb(); secs.push({ id, start: p, end: p + n }); p += n; }
const code = secs.find((s) => s.id === 10), data = secs.find((s) => s.id === 11);
p = code.start; const count = leb(); const bodies = [];
for (let i = 0; i < count; i++) { const n = leb(); bodies.push(b.subarray(p, p + n)); p += n; }
// function index = imports + position; rows carry objdump's index
const imports = rows.map((r) => r.i).sort((a, c) => a - c)[0];
const br = (buf) => zlib.brotliCompressSync(buf, { params: { [zlib.constants.BROTLI_PARAM_QUALITY]: 11, [zlib.constants.BROTLI_PARAM_LGWIN]: 22 } }).length;
const full = br(b);
const group = (r) => r.name.startsWith("avra_ui_") ? "avra @std/ui" : r.name === "avra_main" ? "avra @ui/board" : r.origin;
const groups = [...new Set(rows.map(group))];
const nonCode = Buffer.concat([b.subarray(0, code.start), b.subarray(code.end)]);
const out = { full, raw: b.length, code_raw: code.end - code.start, data_raw: data.end - data.start, code_br: br(Buffer.concat(bodies)), data_br: br(b.subarray(data.start, data.end)), rest_br: br(Buffer.concat([b.subarray(0, code.start), b.subarray(data.end)])), groups: {} };
for (const g of groups) {
  const kept = Buffer.concat(bodies.filter((_, k) => group(rows.find((r) => r.i === k + imports)) !== g));
  const raw = rows.filter((r) => group(r) === g).reduce((s, r) => s + r.size, 0);
  out.groups[g] = { raw, marginal_br: out.code_br - br(kept), alone_br: br(Buffer.concat(bodies.filter((_, k) => group(rows.find((r) => r.i === k + imports)) === g))) };
}
// libc pieces and ui modules
const pick = (pred) => { const kept = Buffer.concat(bodies.filter((_, k) => !pred(rows.find((r) => r.i === k + imports)))); return out.code_br - br(kept); };
out.pieces = {
  "printf (vfprintf+fwrite+stdio)": pick((r) => /vfprintf|fwrite|__stdio|fflush|wctomb|__towrite|fputs|snprintf|vsnprintf|sn_write|__fwritex|frexp|fmt_fp/.test(r.mod + r.name)),
  "strtod/floatscan": pick((r) => /strtod|floatscan|shgetc|__shlim|scalbn|copysign/.test(r.mod + r.name)),
  "dlmalloc": pick((r) => /dlmalloc/.test(r.mod)),
  "@std/ui realize/html/css.av": pick((r) => r.mod === "realize/html/css.av"),
  "@std/ui realize/html/*": pick((r) => r.origin === "avra @std/ui" && r.mod.startsWith("realize/html/")),
  "@std/json": pick((r) => r.origin === "avra @std/json"),
  "@std/validate": pick((r) => r.origin === "avra @std/validate"),
};
console.log(JSON.stringify(out, null, 1));
