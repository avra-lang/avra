# HANDOFF — avra-lane-web-first-paint (web first paint lane)

## Goal
The owner's order: "the time to first paint for the web is extremely high … get it to load instantly." The UI lead's rulings 1–6 govern it: the server draws the first paint, the document names every file the page fetches, bytes are compressed and cached, the budget is held by counters, and a proposal on taps before the module stands is owed.

Targets, as the UI lead restated them:
- COLD: first paint within 50 ms of the document's last byte.
- WARM: first paint ≤ 200 ms on a 120 ms RTT / 4 Mbit/s link.
- USABLE: a tap handled ≤ 600 ms cold.

## Tickets
- avra-8sb5.111.1 (P0): WebKit fetched the module twice. Fixed in e609b093, below.

## STATUS AT HANDOFF

Both commits below have LANDED on program, in f08fb217 ("first paint slice 2 + WebKit fetch …"). program is now e02d71ab. Rebasing onto it dropped both as already upstream, so `handoff/20261125-1144/avra-lane-web-first-paint` carries only this note. The "Next" step 1 below is therefore done; the next work is step 1's WebKit confirmation, then steps 2 to 4.

## Base and branches (before landing)
- Base: program `d7cd84d9` ("land: first paint slice 1 …"). Slice 1 has already landed there.
- `avra-lane-web-first-paint` at 09829958. On top of d7cd84d9 it has two commits:
  - `e609b093` — the P0 fix. The document starts the module's fetch in an inline `<script>` (`avraFetched`, keyed by the resolved URL), and bootstrap.js `compiled()` takes that same request once. The `<link rel=preload as=fetch>` is gone. It is meant to land FIRST and alone.
  - `09829958` — slice 2. The server draws the first paint, and the module adopts it:
    - std-ui_http `app_page()` reads AVRA_PAGE_MODULE, AVRA_PAGE_HOST and AVRA_PAGE_FETCHED;
    - `Document.fetched` names the files the page fetches;
    - runtime/dom/start.js is the one start script for every page;
    - `avra dev` answers "/" with the page the server draws, tells the server the page's files and restarts it when they move, holds requests while the server restarts, and serves the document compressed with a content tag;
    - the board's server draws "/" with its database's tasks;
    - first_paint.mjs gains the adoption claims (a) and (e);
    - serve_hydrated.mjs puts its `__served` marker before `<script type="module"`. That fixes the gate's Firefox failures "a server's page stands…" and "0 of 42".
- `avra-lane-web-first-paint-fix`: e609b093 alone.
- `wip-handoff`: the same tip plus this file at docs/handoff/avra-lane-web-first-paint.md. Pushed to handoff/20261125-1144/avra-lane-web-first-paint.

## Done and verified (in this container: Chromium as iPhone 13 Pro Max; WebKit and Firefox can't be downloaded here)
- Checks: runtime/dom tests all hold (bootstrap 131/131), std-ui_http 18/18, cli dev_test.av 37/37, dev_server_check.sh 13/13, first_paint.mjs 7/7, fmt clean.
- browser.mjs: 88 claims hold, 8 skipped by name, with Chromium standing in for WebKit, the --hydrated and --tampered runs included.
- Measured:

| | result | target |
|---|---|---|
| cold first paint | ~300 ms, 34–38 ms after the document's last byte | ≤50 ms after: met |
| warm first paint | ~165 ms | ≤200 ms: met |
| usable (module standing), cold | ~785 ms | ≤600 ms: missed |

- Reports and screenshots are in /tmp/claude-0/out, already sent to the controller: avra-lane-web-first-paint.md, -input.md (the proposal for taps before the module stands, NOT built) and -census.md (what the module holds, with the levers to shrink it).

## Half-done
Nothing is uncommitted.

## Next
1. Gate and land e609b093 by itself (P0), then 09829958.
   - Exact next command: in a worktree on handoff/20261125-1144/avra-lane-web-first-paint, run `git rebase --onto origin/program d7cd84d9`, then `sh tools/work land`.
   - Confirm in WebKit (ui-browser, engine webkit-iphone) that the module is fetched once and that cold first paint is about 550 ms.
2. Delete serve_hydrated.mjs once browser.mjs's --hydrated and --tampered claims run against `avra dev` directly. This needs a runnable Firefox.
3. The taps-before-adoption proposal (-input.md) waits on the UI lead's ruling.
4. Module bytes, from the census:
   - merge the 2147 data segments (≈15 KB of headers);
   - drop libc printf/strtod (≈16 KB);
   - use a smaller allocator (≈8 KB).

## Open questions
- The 600 ms usable target can't be met with the module's bytes plus an HTTP/1.1 handshake as they stand. The lead needs to accept the proposal, or accept HTTP/2 or smaller bytes as the way to close it.
- The image of a bundled asset traps in wasm ("a write landed in the binary's own data"). It reproduced only on this container's wasi-sdk 27 / wasm-ld 20, and lowering-quality could not reproduce it on CI's toolchain.

## Runs in flight
None.

## Local setup notes (this container)
- LLVM_PREFIX=/tmp/claude-0/llvmshim: LLVM 20, plus a clang wrapper that sends wasm builds to wasi-sdk 27.
- WASM_OPT=/tmp/claude-0/binaryen-version_124/bin/wasm-opt.
- Slow-link proxy: tools/ui-board/slow_link.mjs.
