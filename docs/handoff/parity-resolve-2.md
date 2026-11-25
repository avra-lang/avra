# Handoff: parity-resolve-2 (2026-11-25)

## Goal
Cut ItemView.holds string compares on the program layer by giving laws and helpers the view their judging
already holds, instead of looking the item up again by (engine, file, at). Ticket: avra-8sb5.114.4.

## Base
gh/program e02d71ab (https://github.com/avra-lang/avra, branch program).

## Branches (on GitHub)
- lane/parity-resolve-2/views-b2b3, tip 0596d4ba: finished, NOT yet landed. Two commits on e02d71ab:
  - f0522bfa: declaring_item reads its declaration with item_read (no view built). Cost vs 000d865c:
    check-cli string_compares -0.205%, list_buffers -0.318%; list_reads +0.131%, retains +0.082% (lead accepted).
  - 0596d4ba: impls_seen(view); the 3 callers that already hold a view use it. Cost: string_compares -0.076%, no row rises.
- handoff/20261125-1144/parity-resolve-2: the same two commits plus docs/handoff/parity-resolve-2.md.

## Done (landed earlier)
- 4b954909: 69 laws over misses/breaches read through the view (misses_seen_in, breaches_seen_in).
- 000d865c: 63 laws in item_trait_impls/decl_shapes/annotations/externs/collect_shapes/uses
  (<helper>_viewed; each original keeps its item_held guard and delegates). holds 12.47M -> 6.29M on check-cli.

## Tested with
On c9780be7's tree (same diffs), cold (AVRA_MACHINE_STORE=0, fresh AVRA_CACHE_DIR), built from the gate's
c9780be7 compiler: make try 0; witnesses_test 13/13; idioms exit 0; findings-a std-avrac 0, cli 0;
program-refusals 1175/1178 (wasm_hello: this sysroot lacks -lsetjmp; wasm_package_c fails identically on the
gate's own c9780be7 compiler).

## Half-done
- Re-check on e02d71ab itself: was interrupted by this handoff after gen-1 built clean (0 errors). Not run:
  make try, witnesses, idioms, findings-a, program-refusals on e02d71ab.

## Next (exact)
On a checkout of lane/parity-resolve-2/views-b2b3 with a compiler for e02d71ab (or the gate's c9780be7 one) as build/avra:
  AVRA_MACHINE_STORE=0 AVRA_CACHE_DIR=$(mktemp -d) AVRA_PROGRAM=1 AVRA_PROGRAM_NET=0 make try
  build/avra-try test packages/std-avrac/src/compiler/tests/witnesses_test.av
  build/avra-try check packages/std-avrac --baseline tools/idioms.baseline
  build/avra-try tapes packages/std-avrac --findings ; build/avra-try tapes packages/cli --findings
  sh tools/witness_program_refusal.sh build/avra-try   (run alone: it fills the disk if run beside a census)
Then the lead lands views-b2b3.

## Open questions / findings for the lead
- What's left of holds (~6.1M on check-cli) is queries keyed by (file, at), which can't carry a view. A
  wider "take the view at a fn's top" attempt (e684f672) raised boxes/reclaims/list_writes ~0.10% and was dropped.
  The structural fix is interned file names in SourceFileAddress (the accepted residue's deadline).
- Warm-build defect (P0, routed to lowering-quality): /work/out/warm-ownership-repro.md.
- Duplicate-fn ICE (a second fn of the same name, another arity, crashes generic_values): routed to the defects lane.

## Runs in flight
None (the e02d71ab re-check was stopped for this handoff).

## Tools
Census of one commit (cold, same builder): /tmp/claude-0/s/cold-census.sh, measx.sh / meascb_inner.sh,
sites.sh (per-site streq table), cmp.py <base> <head> (cost table and the site diff).
