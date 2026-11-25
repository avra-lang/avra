# HANDOFF — avra-lane-r2-first-paint (web first paint, round 2)

## Landed or pushed
- `lane/r2-first-paint/data-whole` @ 57673fa8, on program 79bf7fd7. The change is `wasm-opt --skip-pass=memory-packing`, with a fallback spelling for binaryen <= 108. The board's module goes from 99,647 to 94,811 B brotli, and it stands at 772–779 ms cold (was ~790–806). first_paint.budget cold goes from 126000 to 120000 (measured 117,985). first_paint.mjs passes 7/7 in Chromium. Not gated yet.

## Owed item 6: the proposal page, for the UI lead to rule on
https://claude.ai/artifact/W55wqcnruzMooCHxKac5fM. It is private; share it from its Share menu.
- Today: a BUTTON tap or an Enter before adoption is lost, 3/3. Values (a checkbox, typed text) survive through bootstrap.js `replay`.
- Prototype `held.js` (1.2 KB gzip): it holds actions, marks the control `data-avra-held` (dimmed to 0.5, progress cursor) and replays them after adoption. The module writes 3–6 ms after it stands, 3/3, with no double toggle.
- Production design (not built): an inline classic head script beside `avraFetched` fills `globalThis.avraHeld`. bootstrap.js, after `adopt`, runs value replay first and then fires the held actions through `hearing(el, ev)`, never as synthetic DOM events. If adoption draws from nothing, the queue is dropped with a console line. New first_paint.mjs claim: 0 taps lost.
- Rulings asked: (1) hold actions, (2) the held look, (3) a held tap never expires, (4) "usable" means no tap lost from first paint.

## Census of the board module (317,647 B raw; 779 fns; 2,185 data segments)
Wire cost (brotli removal delta): @std/ui 39.5 KB; libc 11.7 KB (printf ~4.4, strtod ~2.7, dlmalloc ~2.9); C runtime 8.0 KB; board 6.1 KB; json 4.1 KB; css.av 5.4 KB inside @std/ui. Data: 18.8 KB br, of which 57 KB raw is zeros. SQLite: 0 B in this module.
Levers, at about 2 ms per KB br: memory-packing (done, about −11 ms), client css.av split (about −11), no printf (about −9), allocator (≤ −6), own float reader (about −5).

## Reproduce (this container)
- Ubuntu 24.04's wasi-libc lacks setjmp. Use the wasi-sdk-27 sysroot, a clang wrapper adding `--sysroot` for wasm, `CC=<wrapper>` (CC wins over LLVM_PREFIX in `wasm_linkers`), and `make wasm-runtime wasm-packages WASI_SYSROOT=…`. Binaryen 124 goes in WASM_OPT.
- Scripts are in docs/handoff/avra-lane-r2-first-paint/. taps.mjs, shots.mjs and timeline.mjs drive `avra dev tools/ui-board`. syms.py → classify.py → brcost.mjs make the census over a name-carrying build: relink without `--strip-all`, then `wasm-opt -g --strip-dwarf`, then `-g -Oz --reorder-functions`.

## Next
1. Gate and land data-whole.
2. After the ruling: build the held taps in bootstrap.js and the document head, plus the first_paint claim.
3. The css.av split and the printf removal (runtime). The allocator goes through the alloc lane.
