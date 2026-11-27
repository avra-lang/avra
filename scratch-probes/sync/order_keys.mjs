// Fractional position keys (base 95 printable): key length after N inserts.
const D = 95, lo = 32
const dig = (s, i) => i < s.length ? s.charCodeAt(i) - lo : 0
function between(a, b) {  // b === null means +inf
  let out = ''
  for (let i = 0; ; i++) {
    const x = dig(a, i), y = b === null ? D : (i < b.length ? dig(b, i) : D)
    if (y - x > 1) return out + String.fromCharCode(lo + ((x + y) >> 1))
    out += String.fromCharCode(lo + x)
    if (y - x === 1) { b = null }   // a's tail now only needs to exceed a
  }
}
function run(name, pick) {
  let keys = [between('', null)]
  for (let i = 1; i < 10000; i++) {
    const j = pick(i, keys.length)       // insert before keys[j]
    const a = j === 0 ? '' : keys[j - 1], b = j === keys.length ? null : keys[j]
    const k = between(a, b); if (!(k > a && (b === null || k < b))) throw name
    keys.splice(j, 0, k)
  }
  const ls = keys.map(k => k.length)
  console.log(name, 'max', Math.max(...ls), 'mean', (ls.reduce((s, x) => s + x, 0) / ls.length).toFixed(2))
}
let seed = 7; const rnd = n => (seed = (seed * 1103515245 + 12345) % 2147483648) % (n + 1)
run('append  ', (i, n) => n)
run('random  ', (i, n) => rnd(n))
run('head    ', (i, n) => 0)
run('same-gap', (i, n) => 1)
