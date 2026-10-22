# db-warm status (latest)

## Warm-unchanged ticket: PRs #919 and #923 open
#919 (db-hit-time): `check --time` on a hit now prints open / manifest read / manifest parse / closure / listings / inputs / embeds / objects / judge / load (us). Measured (Sprite, packages/cli, unchanged = pure store hit), wall 175 ms before:
  judge ~135 = listings 58 + inputs 36 + manifest read 37 (first store.get scans the whole body pack) + rest; open <1, load <0.1.
  Producer rows (#857) are NOT a separate load: they ride in the body-pack scan (+12 MB store, +16 ms).
  Fix in #919: a covered dependency's listing walked its tests tree (source_inputs never reads it) -> listings 58 -> 10 ms, wall 175 -> ~130 ms. Witness tools/dep_tests_listing_attack.sh (semantics pin; passes before and after, the walk was a cost).
#923 (db-warm-report): the gate's "warm unchanged" is ALREADY the least of 3 rounds, so no min-of-3 change; adds stderr startup (avra rules, ~24 ms) + the hit's --time phases beside it.

## Not done (proposal, big)
Manifest read 37 ms = body_read parses every slot+row into maps at first get. A lazy index (sorted keys + offsets, binary search, rows on demand) would let an unchanged hit read only the 3-4 rows it needs. Body format change (BODY_VERSION). Not written; needs go-ahead.
Remaining judge: inputs 36 ms (reads+hashes ~1000 root/dep source files; stat-first is refused by doctrine).

## Earlier
Features-shard CI slowdown: not a compiler commit (see earlier note: pre-output compile phase grew on watcher-only commits).
#893 merged.

## Lazy body index: measured breakdown before writing it (branch db-lazy-body, nothing committed)
Unchanged `check packages/cli`, first store.get = the body open, ~34-43 ms:
  read_bytes of the 4.6 MB body.pack 9-11 ms | frame digest check 5-6 ms | body_read parse 19-24 ms (5061 slots + 12193 rows, ~1.4 us/item)
A micro-fix (compute record_key once per row) moved nothing measurable (run-to-run noise ~20%).
A lazy index (span reads of the .idx fan-out + only the 3-4 rows a hit asks) would remove most of the ~40 ms (~30% of the ~130 ms wall), but it touches every user of pack.records / pack.order / pack.slots (seal, merge, withdrawn, segments, sealed_readers) and the frame digest check; it is a store-core change, not a body_read edit. db-externs asked about the codec; no answer yet.
Rest of the ~130 ms wall: judge 83 (inputs 36, listings 10, manifest read ~35) + ~47 process start + workspace build + print (`avra rules` alone is 24 ms).
Goal is 60 ms unchanged: needs open (40) + inputs (36) + startup all attacked; the index alone gets to ~90.

## Lazy body index: PR #945 open (BODY_VERSION 5), carries the as-built design note (close #925)
Store open 35-43 ms -> ~1 ms; unchanged hit wall ~175 -> ~140 ms from the index alone (with #919's listings ~95). Counted: Traffic.rows + `Q store row` trace; store_index_attack gates <= 8 rows decoded on 10/400/1600 records. Receipts: pack_test 12/12, store tests 34/34, store_index/seal/clean/reads/quiet attacks, cache_attacks.sh 477 builds 0 failed, idioms clean. store_attacks.sh fails the same 3 as main.
Open follow-ups: `rows read N` on the check --time hit line after #919 merges; process start + workspace build split (~47 ms) next; #919/#923 branches updated onto main (wall-total gate now a warning).

## Process start split (Sprite, Linux x86-64, published main compiler)
`avra --version` 24 ms wall. Baseline fork+exec of `true` here = 5.3 ms; a native Avra hello = 6.3 ms (runtime init is free).
Experiment: a C `main(){return 0;}` linked with libLLVM.so.22 (DT_NEEDED) = 20.7 ms vs 5.9 ms without. So loading libLLVM costs ~15 ms of every command's start; callgrind of `--version` = 22.2M instructions, ~75% in ld.so relocation/symbol lookup (+ LLVM's static ctors); Avra's own code is negligible. `LD_BIND_NOW` makes it worse (27 ms). macOS shows the same ~20 ms (libLLVM.dylib).
=> startup floor controllable: ~15 ms (libLLVM) of the ~24; the rest is fork/exec and ~3 ms.
Fix shape (not built): `check`, `fmt`, `explain`, etc. never emit LLVM. Make libLLVM lazy: build backend/llvm_wrapper.c + -lLLVM into a `libavra_llvm.{so,dylib}` and have the compiler call its 98 `avra_llvm_*` rows through generated stubs that dlopen once on first use. Touches both link sites (Makefile `avra` target and the bootstrap/seed-check clang lines) and the seed. Saves ~15 ms on every non-emitting command (check hit ~135 -> ~120 ms).

## Static LLVM measured (design note PR #947, draft; nothing built)
`avra --version` on a Sprite: shared libLLVM 22.6-24.6 ms | static PIE 13.9-16.4 | static -no-pie 12.6 | floor (`true`) 5.2-5.5.
Static+no-pie removes ~12 of ~19 ms above the floor; binary 85 MB (native+wasm targets only), builds and runs (compiled and ran a program, check exits 0). Recommended over dlopen (one binary, no stubs). Plan in docs/2026_10_18_STATIC_LLVM.md: one `build/llvm.rsp` from llvm-config, read by the std-avrac [link] row and the hand-written clang lines, `-no-pie` via cli [link.raw] on Linux, export only runtime rows (dynamic list) instead of -rdynamic so gc-sections works, seed note. macOS (arm64, no no-pie) not measured.
#945 body now states a read corrupted row is refused (absent), never answered.
