
## 2026-10-12T18:15Z — PR #606 (draft, DO NOT MERGE), branch ran-by off origin/main 0fcc132b
- ran_by: narrowed (fn read inherits nothing; const read inherits its verdict's reads; seen = map). Attack rb FAILS on main ('lib.av data.av'), passes. Measured cli closure 12.9k -> 11.3k over 501 calls: NOT where keep time was.
- Cold keep was code_facts: qtrace K lines: codes 35.3 s, all_said 10.6 s, interfaces 3.7, instances 2.0 (of 52). Cause: type_shape text spells nested declarations out, up to 3.08 MB per shape, 1.04 GB of shape chars over 1936 code_facts calls, 241 MB of kept wire; it was digested per register and embedded in every fn-value node name. Fix: shapes named/hashed by digest (type_shape_key, Decls.shape_keys).
- Measured (Sprite, warm_edit.sh packages/cli): cold wall 181.9 -> 105.4 s, keep 51.5 -> 15.4 s, lower 87.4 -> 51.6 s; edit keep ~1.0 -> 0.25-1.8 s, lower 5.3 -> 3.6-4.1 s, analyze 1.5 -> 0.7 s. make cache-attacks: 352 builds, 0 failed. Not run: package suites, make idioms.
- Remaining cold keep: all_said 10.6 s, interfaces 3.7 s, instances 2.0 s (pre-fix numbers).

## 2026-10-12T20:00Z — cold keep remainder, measured (tree = #614 + ran-by-reduced; cold packages/cli keep 14.5 s)
- all_said: says 6.29 s + file_said 0.39 s over 504 files. Inside says: rule_findings 5.93 s (the idiom rules RUN over every file = real analysis work, not overhead), findings rows 0.25 s, warned 0.08 s, cases 0.01 s.
- keep_interfaces: 4.92 s over 84 modules (~58 ms/module in record_of building each module's record). No quadratic seen; would need a profile of record_of.
- One-edit keep is already 0.2 s, so neither moves the owner's <1 s bar; both are cold-only. Open question for the lead (not mine to decide): rules run for a Binary want too ("kept under every want") although only a diagnostics want speaks them — skipping them for Binary would save ~6 s of a cold build but a later check then finds them unkept (derive.av unruled).
- Landing state: branch ran-by-reduced (= #614 head + keep_codes filter + ran_by + rb attack). Nothing pushed for all_said/interfaces.

## 2026-10-12T21:46Z — why a one-edit BUILD costs 65 s where CHECK costs 7 s (packages/cli, shared.av body literal, main 64bbcd82, Sprite)
- build --time DOES print phases for a built (not cache-hit) run (the line after "time: lower+emit · built"); the scenario table missed it. Cold: lower 88.4 s, keep 64.2 s (pre-#614 numbers), emit 38.6 s, link 4.3 s.
- One-edit build, 2 rounds: wall 64.9 / 65.4 s; ast 4.0, sublang 0.6, resolve 0.6, bodies 2.3, load 2.5, admit 2.5, analyze 3.2, **lower 23.5**, **keep 8.6**, **emit 9.8–10.8**, link 0.4; held 430/466, 78 parse events, 2 attempts (check: 7 s, held 502/504, 7 parses, 1 attempt).
- QTRACE: "attempt 0 hold true homes false" then "attempt 0 hold true homes true". Cause: derive.av holding(): `!at.homes && known_homes(store, at).any(home_moved)` -> Turn.Again(homes: true). shared.av is a REMEMBERED HOME (homes_key(known_as): files instantiations were lowered from); its text moved, so ALL ~36 remembered homes (std-relation, std-grammar, std-http, std-avrac features/core, cli main/shared ...) are read from the start and re-lowered. That is the 36 unheld files, the 78 parses, the lower 23 s, keep 8.6 s.
- Why every home, not just the moved one (reading linked()/asked_print): asked_print folds EVERY home's text+key, so one moved home flips the program's asked key; instantiations are then owed, and all of them live in ONE program-module object (program_object / homed) whose IR the build must have in hand to re-emit (emit 10 s). keep_instances stores only code_facts wire per instantiation, not IR or object.
- Fix shape (not built; design-level, needs your go): instantiation objects PER HOME (or per instantiation, keyed by the generic body + type args), so a moved home re-lowers/re-emits only its own instantiations and the rest stand from the store; asked_print becomes per-home. That removes the homes:true turn for the common edit. Smaller cuts available first: (a) skip the wasted first attempt (home_moved is knowable before attempt 0 — start with homes:true; saves one cheap discard only); (b) emit only changed program-module pieces. Neither reaches 500 ms alone.
- Rule findings under Binary want (task 1): not started.

## 2026-10-12T22:12Z — PR #636 (draft): a build runs no rule; and PR #634 (draft): drop my stray tools/ep_b.sh that rode the CI commit into main
- #636: derive.av says()/file_said(): Spoken.rules is null under a Binary want, nothing kept; a check then reads files it has no rows for (unruled). Cold `build --time packages/cli`: keep 64.2 -> 57.0 s (single runs, same Sprite). Attacks: rw — build after a check is a cache hit; ee — check after a build now READS user/mod.av (flipped from held: that was the old law's witness). make cache-attacks 368 builds 0 failed. Not run: suites, idioms.
- Finding: even after that, a COLD BUILD's keep is 57 s against a CHECK's 14 s: the build's keep covers what only a build lowers (instantiations: keep_instances' code_facts over every instantiation body, plus its const units/asks) — next lead for build keep, not examined yet.

## 2026-10-12T22:13Z — DESIGN: one-edit BUILD without the homes restart (read before building; nothing built)
Facts (main eaff334c, cli, shared.av body literal): build 65 s = lower 23.5 + emit 10 + keep 8.6 + analyze/load/admit ~8; check 7 s. Cause: holding() Turn.Again(homes:true) when ANY remembered home's text moved -> ~36 homes read+re-lowered; asked_print folds EVERY home's key; all instantiations are weak bodies in ONE program-module object (build.av program_object/homed), re-emitted whole. keep_instances keeps only code_facts per instantiation (no IR, no object).
Identity (reuse, no second key): a unit row exactly as #605 unit_rows.av (RowPlace: decl + OWN syntax + file surface) EXTENDED to sub != null: key = #605 key + settled type-arg shapes (type_shape_key) + #607 Hold.owners owner. NOT inst_key_of(home okey,…): that folds the home FILE's okey, which moves on any text edit of the home — the bug in miniature. One derivation names key and row.
Laws: (L1) an instantiation is served iff its unit-row key stands; a served one needs no home read. (L2) a home is read only for the instantiations of THAT home that are not served (Turn.Again(parse:[home]) per body_asks, once), never "all homes". (L3) the program's owed set = asks whose unit key has no kept object, not a fold over homes (asked_print per unit).
Objects (choose): (a) kept IR per unit — no IR wire exists, and the emit stays whole: REJECT. (b) one object per instantiation — thousands of .o, link cost and per-module LLVM setup dominate: REJECT. (c) PARTITION the program module into B=64 buckets by hash(instance symbol); bucket object key = fold of its members' unit keys (+ opt, runtime). A one-edit moves k instantiations -> <=k buckets re-lowered/re-emitted: emit ~10 s x k/64 (k~5 -> ~0.8 s, 4 workers in parallel via the existing EMIT_WIDTH handed()), link +64 objects ~0.3 s. EMIT_WIDTH stays 4 (CI has 4 cores); measure =cores on the 8-core Sprite as a separate knob.
Steps, each its own PR, attack WRITTEN FIRST and witnessed failing on main:
 S1 attack hb + unit rows for instantiations (check want only, like #605): fixture = 2 generic homes + a caller; edit one home's unrelated body; assert the other home stays HELD, discarded 0, and the instantiation is a row hit (qtrace Q unit served). Expected check lower 2.4 -> 2.2 (no change for check; this is the identity step).
 S2 Binary derivation consumes rows: holding() drops the homes-moved turn; reads only moved homes (L2); program owed-set per unit (L3). Attack: build after a body edit in a home holds every other home (held >= n-2), link ok, binary output follows (eval==native). Expected build one-edit 65 -> ~25 s (lower 23 -> ~4, keep 8.6 -> ~2; emit still whole 10).
 S3 bucketed program module (c): attack: edit one instantiation's generic body, exactly its bucket object re-emitted (count .o written), the other 63 are store hits; edit nothing generic: 0 emitted. Expected build one-edit ~25 -> ~12 s (emit 10 -> ~1).
 S4 floor: keep_instances only for moved units, load/admit/analyze as check (the 7 s check floor). Expected ~8 s = check + ~1.5. Anything below that is the CHECK's own floor (decl-lower / items-kept lanes), not build's.
Open risk to settle in S1 before S2: whether an instantiation's lowering reads anything outside (generic decl syntax, shapes, file surface) — a const it settles, a callee's marks (consumed seats: .66 hole 3), a code_hash ask. Each is a key part or the row is refused (rows are kept only for units that spoke nothing and asked no hash, as #605). Honest bar: 0.5 s is out of reach of build until check itself is under ~1 s; this plan targets check+1.5 s.

## 2026-10-12T22:35Z — #636 PARKED; build keep split (main eaff334c, cli, Sprite)
- Cold BUILD keep on main = 15.4 s, equal to CHECK's 15.2 s (the 57 s earlier was pre-#606): interfaces 5.14, all_said 7.47 (rules ~5.9 inside), instances 0.77 (n=1447), codes 1.04, const_units 0.61, asks 0.34, unit_rows ~0. A build keeps NOTHING extra per instantiation beyond keep_instances 0.77 s. Cold build total: lower 64.0, emit 37.7, analyze 40.3, ast 22, keep 15.4, link 0.5.
- check AFTER a build today (main): 21.7 s wall, held 464/505, discarded 1, lower 5.4, load 2.3, analyze 1.5, keep 0.8. With #636 (build runs no rule): cold build keep 15.4 -> 8.4 s, but check after build 89.3 s (held 0/505: admit 25.0, analyze 13.4, lower 31.4, keep 11.8). Net loss -> #636 parked as a draft with the dependency (rules over kept Typed state) in a PR comment; its ee witness is flipped only to show the cost.
- Side finding: check-after-build on MAIN is already 21.7 s with one discarded attempt (vs 7 s check-after-check): the build leaves the store such that a check re-reads ~41 files. Not investigated.
- Design (above) stands; awaiting approval.

## 2026-10-12T23:36Z — lower-regress touches derive.av (one-edit attempt-0 start), not the homes turn

I touch: `derive.av` — `lead_reads` (adds the files a standing attempt's compile-time runs read, remembered under a new key `runs_key`, same `remember`/`remembered` format as `homes_key`), `bodies_lowered` (one `remember` line writing that set), and two helpers `runs_key`, `run_read`. I do NOT touch `holding()`, `known_homes`, `home_moved`, `homes:true` or the `Turn.Again(homes)` path, which are your S2 surface. My change only makes attempt 0 start with reads it would otherwise discover by turning.

## 2026-10-13T00:21Z — S1 PR #654 (draft): what an instantiation's lowering reads (found by instrumentation, not reading)
Method: a differential probe (patch kept in the session scratchpad: unit_verify_probe.patch): with AVRA_UNIT_VERIFY set, every SERVED unit is also lowered fresh and its code facts + wants compared; a difference traces Q unit_mismatch/unit_diff. Run over the cli with edits (comment in core/side_table.av twice, body expr in core/digest.av, private fn added to core/lists.av, comment in core/types.av): ~12k served units. Plus attack hb for reads no cli edit exercises.
1. The type NAME. 74 of 4394 served units mismatched (facts) because two instantiations whose type arguments have EQUAL SHAPES but different names (flatten<RefusesCall> / flatten<KeywordRemedy>) shared a row: shape is structure only, the NAME reaches the symbol and the code facts. Key now carries w.name (which spells the arguments) AND the shapes. After: 0 mismatches over all five edits.
2. Settled CONSTS the body reads. Not visible to the differential (the cli edits move none); attack hb found it: a const edited in another module left the unit SERVED STALE — and this is a defect in #605's PLAIN unit rows on main today (hb witnesses it failing there: 'a PLAIN fn reads K ... served stale'). Effect: stale code facts -> a code_hash keyed on the fn can be stale; not wrong output of a check. Fixed in the same place: a row keeps every const its lowering asked (hold.unit_asks) as (decl_ref, Settled.fingerprint) and is served only while each still settles to it; a unit that read an expression-root or seated const keeps no row.
3. Everything else compared equal on ~12k units. Not part of a row's facts, so not keyed: callee seat marks (Body.marks is read by the memory pass AFTER lowering, from l.fns; the served stub carries marks=[] exactly as #605's plain stubs do); code-hash VALUES (rows keep the asked targets; the answers come from the graph).
4. Consequence for S2 (a build needs IR, not facts): a bucket re-emitted for one moved instantiation needs the IR of its UNMOVED members too, so S3 re-lowers those members (1/B of all instantiations, not the moved ones only) — an extra cost I had not counted; and Body.marks of served stubs must be real in a build (they feed the memory pass of callers and so emitted retains). Both go in S2/S3's attacks.
Measured (Sprite, cli, 3 rounds, check one-edit): 8.2/7.1/6.8 s vs 7.8/6.6/6.4 s without consts keying vs 6.7-7.6 s on main — no change (cli has no instantiation units in a check); build one-edit unchanged by construction (serving is off for a Binary want). make cache-attacks 381/0, make idioms 0. hb witnessed failing on main: 4 of 5 cases + const cases. S2 waits for your go.

## 2026-10-13T02:05Z — EMIT MEASURED (cli build, stack #658<-#662<-#667 tip, Sprite, trace probes not committed): what S3 buckets buy
- One-edit build: objects owed 2–3 of 37; emit phase 9.7–10.6 s = module build 0.11–0.14 s (handed) + 8.7 s WAIT, and the wait is the PROGRAM MODULE's single-worker compile: 1606 roaming bodies, 82,609 instructions (of 14,518 bodies / 157,680 ins in the build's Lowered). => 0.105 ms per instruction; one thread, so EMIT_WIDTH=4 does nothing for it.
- Per-bucket estimate from that rate: B=16 -> ~5.2k ins, ~0.55 s a bucket; B=32 -> ~0.27 s; B=64 -> ~1.3k ins, ~0.14 s. With 4 workers a full re-emit of every bucket is ~8.7/4 = 2.2 s even if NOTHING is cached; with content-keyed buckets only changed ones compile: k=1–3 changed buckets at B=64 => 0.14–0.4 s. Link: 37 objects link in 0.4–0.55 s now; +64 objects estimate +0.3 s (unmeasured; measure in the PR).
- COLD build emit 36.8 s = 27.6–28.0 s handing 462 modules + 8.7 s final wait. Inside emit_mode the Avra-side work is only scan 3.94 s (own-filter and declare loops over ALL 15.8k bodies per module = the quadratic filter pattern) + bodies 2.89 s = 6.8 s; the other ~21 s of 'handing' is BACKPRESSURE: handing blocks while 4 workers compile (LLVM optimize+codegen throughput). So cold emit = LLVM CPU / EMIT_WIDTH: width 8 on the 8-core Sprite should take it from ~37 to ~20 s; CI runners have 4 cores. The 3.9 s scan is a cheap quadratic to group once (separate small PR). Cold payoff of buckets: NONE for cold (same total LLVM work) except through EMIT_WIDTH.
- REORDER PROPOSAL: S2 = content-keyed program-module buckets (key = bitcode bytes of each bucket, as program_object already keys the whole module by its bytes) — needs NO unit identity and no homes change: the whole program is still lowered, unmoved buckets' bytes are identical and hit the store. Build one-edit emit 9.7 -> ~0.5–2.2 s. S3 = homes turn removal / rows consumed by Binary (lower 12.5 s, keep 2.5, analyze 3.1, admit 2.5, load 2.5, ast 4.0 remain). Current one-edit build phases (tip of stack): ast 4.0 sublang 0.6 resolve 0.6 bodies 2.4 load 2.5 admit 2.6 analyze 3.2 lower 12.5 keep 2.6 emit 9.7 link 0.5 (sum ~41 s).

## 2026-10-13T03:21Z — PR #674 (draft, off main c48bc794): program bodies compiled in 64 content-keyed buckets (S2')
- Found by diffing the bitcode of two builds: first cut (name-hash buckets) recompiled 30 of 63 buckets per edit; the difference was the string constants of `avra.code_hash.*` bodies (global names .istr.<hex of the hash text>) — code-hash answers move with ANY edit and were spread over every bucket. They now share the last bucket (Body.hash_answer, a GROWTH field set in code_hash.av's hash_body). Result: 1 bucket (+1–2 file objects) compiled per edit.
- Measured (Sprite, build packages/cli, one shared.av literal, 3 rounds): emit 9.7–10.6 s -> 1.9–2.1 s; wall ~41 s -> 33.3 / 33.7 / 34.1 s; link 0.30–0.34 s unchanged (37 objects -> 100). Phases now: ast 4.1 sublang 0.6 resolve 0.6 bodies 2.4 load 2.5 admit 2.6 analyze 3.1 lower 12.3 keep 2.4 emit 2.0 link 0.3. The residual 1.9 s emit is the hash bucket (hundreds of tiny bodies, one worker): splitting it by target is available if it matters.
- Cold: emit 32.0–32.2 s (was 36.8); link 1.76 s / 5.92 s on two cold runs vs 0.4–0.5 s before: UNEXPLAINED (page cache? 64 extra objects?) — re-measure before landing.
- make cache-attacks 378 builds / 0 failed; make idioms 0. Attack bk: 20 record types x 2 generics = 40 instantiations; moving gtwo compiles fewer buckets than are linked and the program prints 270.
- Unchanged gap to check floor (build 33.5 s vs check 6.5 s) is now lower 12.3 (homes turn), analyze/admit/load/ast ~12 s, keep 2.4: S3.

## 2026-10-13T04:23Z — buckets conditions, EMIT_WIDTH, scan (PRs #674 buckets, #685 emit-width)
- #674 conditions met: new attack bk assertions — one NEW instantiation (gid<R21>) compiles exactly 1 program bucket; two cold builds key every bucket alike (Q bucket i key lines identical). B from data (cli one-edit, 3 B in one binary via a temporary env knob): emit 1.6–2.0 s at 16, 1.8–2.2 at 64, 2.6–3.4 at 256 (a module costs a scan of the program; the edit moves one bucket whatever B); link 0.3–0.6 s at all three; cold link 0.4–3.6 s varies run to run, not with B. => B=32 (commit d6945a34 + format). Linkage: roaming bodies are all weak (homed), statics private per module, entry in bucket 0, host-fn -u words are derived from full.fns (unchanged by buckets; #664's change is orthogonal); eval==native by the cache-attack programs (378 builds) — program tests via CI suites.
- #685 EMIT_WIDTH := cores online (<=16): cold build cli on the 8-core Sprite, two runs each: emit 37.4/37.5 s at width 4 -> 24.9/28.9 s at 8; peak RSS (VmHWM polling) 2.00/1.97 GB -> 2.07/2.10 GB (analysis dominates; a worker holds one module) — far under the 6000 MB cap. 4-core CI unchanged.
- SCAN GROUPING (emit_mode's per-module walks of all bodies): built it (Frame indexed once; declared bodies by place), cold emit 38.6/38.0 s vs 37.4/37.5 s before at width 4 = NO GAIN: the 3.9 s scan runs on the handing thread while 4 workers compile, so it hides behind LLVM backpressure. Not landed (branch dropped). It may matter at width 8; re-measure there if wanted.

## 2026-10-13T04:26Z — S3 DESIGN NOTE (≤20 lines; nothing built): the homes turn, per-home modules, no second remembered set
Read: items-kept REPORT 20 / #677 (the guess = the reads a standing attempt took, replayed under key (entry, edit-digest)); it makes the SAME edit start with the right reads, it does not make a FIRST edit read fewer. Today holding() fails Turn.Again(homes:true) when ANY remembered home's text moved (derive.av), and homes:true reads ALL ~36 homes (lower 12.3 s + ~12 s load/admit/analyze).
Why every home is read: a home = the file of a GENERIC (Wanted.file of an instantiation); an instantiation lowers only from its generic's source; asked_print folds every home's key, and all roaming bodies were one module (now 32 name-hash buckets, #674) — an unmoved bucket needs no IR, but a RE-EMITTED bucket needs the IR of all its members, which come from many homes. So name-hash buckets alone cannot stop the reads.
S3 := a program module PER HOME (Owned.Home(f): the roaming bodies whose generic lives in f; Body keeps its generic's file in a new field, Body.file stays null for the link), keyed by INPUTS, not bytes: key(f) = fold(f's okey [text, runs, seen interfaces], the sorted (name, sub-shape) of every instantiation asked of f [the kept asks wires already list them], the (decl_ref, fingerprint) of every const those rows read [unit_rows' consts]). All of it is read from kept rows with NO lowering. A home whose key has a stored object is neither read nor lowered; a home whose key moved (its text, or the set asked of it, or what it sees) is read and its module recompiled. This is #605/#667's row identity, folded per home, plus the bytes-keyed fallback when a module is lowered anyway.
Laws: L1 a home is read iff its module key has no stored object; L2 a NEW instantiation of a held home (caller edited) moves that home's asked-set => key moves => that home alone is read (the existing body_asks turn, once); L3 the owed set is per home. The homes_key row and the 'any home moved => read all' test are DELETED (not made cheaper); nothing remembers a set: the dirty homes are derived each time from rows that already exist. items-kept's guess stays as is and still replays turn-added reads; S3 adds no reading-set row.
Soundness: attack hb stays (per-instantiation lowered counts); new attack hh: edit ONE home's generic body -> exactly that home read and its module recompiled, the other homes held, link ok, eval==native; add a call that asks a new instantiation of a held home -> that home read once, one module recompiled; AVRA_ROW_VERIFY covers served rows. The 32 name-hash buckets of #674 remain the fallback grain INSIDE a home too large to compile on one worker (std-avrac's relation homes) — or are replaced if hh shows per-home modules suffice (decide from the per-home module sizes: measure first).
Expected seconds (one-edit build, cli, from the measured phases): lower 12.3 -> ~3, load/admit/analyze/ast 12 -> ~5, keep 2.4 -> ~1, emit 2.0 -> ~1: ≈ 33 -> ~12 s; target check + 2 s ≈ 9 s needs check's own floor (6.5 s) to fall too. Ladder: P1 attack hh + Body.home field + Owned.Home modules keyed by bytes (no behaviour change, measures per-home sizes); P2 the input key + per-home read decision, homes turn deleted. Each its own draft, hh written first.
Risk I want ruled before building: per-home modules multiply objects by the number of homes (36 in the cli, more in bigger programs): link +36 objects (≈ bucket B=32 data: 0.3–0.6 s); and a home with a huge instantiation set (std-relation's) compiles on one worker — I'd keep the name-hash split inside such a home.

## 2026-10-13T05:19Z — HOW A `build` IS ANSWERED UNDER THE DESIGN (read §6.2, §7.3, §8 DB 07/08, A2, A16; ≤20 lines; nothing built, no Sprite used)
1. ANSWER SHAPE. `Linked(entry, target)` is a root whose saved answer is the binary; its READ LIST is, by name+digest: (a) `Object(unit)` for each file/bucket module — each an answer whose reads are the `Lowered` answers of its units (§7.3 "Lowered saved"); (b) the program module's buckets, each an answer reading the `Lowered` answers of its members; (c) tools and env as INPUTS (CC, linker, ld, runtime library digest, link words, target) — DB 04's door, so "change CC => relink" (avra-8sb5.68/.69) is a read, not a remembered row. Nothing else: no closure/embeds/homes/parts/seen rows, no program_key.
2. ONE EDIT (§6.2 steps 2–5). The edited file's digest moves => its readers are SUSPECT by id; verification runs root-down: `Linked` -> its objects -> units; a unit whose `Lowered` digest is unchanged (early cutoff) stands, so its object and every bucket not containing a moved unit stand untouched; only the moved units re-lower, only the modules reading them recompile, and `Linked` relinks (0.3 s). An instantiation is just a `Lowered` answer named (generic declaration name + type-argument names) — loaded BY NAME from the store, so its home is never parsed unless that answer is missing or suspect. That is the homes turn's replacement: there is no 'homes' set to remember or to read whole.
3. WHAT I BUILT THAT IS A DB 08/07 PIECE. #674 content-keyed buckets = (b): the bucket's key is its bytes today, and under the design its read list is its members' `Lowered` digests (the bytes key becomes the verifier of last resort, A0). #685 (worker width) is backend throughput, orthogonal and stays. The hash_answer segregation is a consequence the design keeps (code-hash answers are their own answers, digest moves with reach). The name-hash membership (a body's symbol, not position) is exactly the 'named part' discipline of A11.
4. WHAT IS INTERIM. Unit rows #605/#658/#667 are a HAND-WRITTEN form of 'Lowered saved' (format-3-like: a list of consts with fingerprints I wrote by hand); under DB 07 c/DB 06 the reads are RECORDED, the consts list disappears, and the rows die with kept_settle's lines (A4). They stay as built (lead's ruling) and AVRA_ROW_VERIFY (#662) is the piece that SURVIVES: 'served == fresh' is the differential every saved answer needs (DB 06's 17 attack cases / A5 are its natural home). `Q placed`/`Q bucket` traces are inspection (DB 02).
5. WHAT I WAS ABOUT TO BUILD AND SHOULD NOT. S3 P2 (per-home modules keyed by INPUTS, a hand fold of okey + asks + const fingerprints, deleting homes_key by hand) is format 4/8 reinvented: a hand key over an unrecorded set. Stopped. P1 (measure per-home module sizes) is measurement only; I have not started it and propose dropping it: the sizes it would measure serve a design the DB removes.
6. FIRST DB 08 SLICE (small, lands on today's store, no DB 07 needed). The store already has `keep_reading(family, key, bytes, reads: List<Read>)` and `get_valid(family, key, now)` (DB 06 step 1, #618). Slice: replace `program_key` + `links_key` witness + `tools_key` row (formats 4 and 5 of A2, build.av:290–312, 515–540) by ONE `Linked` answer kept with its reads — the files linked (path, digest), the tools' identities (path, size/digest of CC, linker, ld, runtime library), the link words, the target — and read back by `get_valid`. Attack: change CC (or the runtime archive) => relink; touch nothing => hit; delete a linked file => relink; the 'cc' path of avra-8sb5.68. It deletes formats 4+5 and the tools row, adds no remembered set, and it is the read list the later `Linked`-over-objects root grows from. Ask: go on this slice? (cost: ~1 day; attacks first, witnessed failing on main for CC/runtime change).

## 2026-10-13T06:23Z edit-path: #699 hit-untouched (stacked on #697)
- Unchanged cli build 0.57-0.73 s -> 0.36-0.50 s. Phases: program_key 220 ms, get_valid <1 ms, place 70 ms, chmod 4 ms, publish (mv -f over output) 350-560 ms.
- Fix: kept_binary leaves the output untouched when its digest equals the kept bytes. Attack lk checks the inode survives a hit; lk 14 builds/0 failed; fmt clean.
- #697 needed one formatting-only commit (CI fmt).
- Lowered meter: decl-lower's AVRA_LEAVES is uncommitted in ../avra-decl-lower; asked them (lanes/decl-lower.md) to push it. No second meter from me.

## 2026-10-13T06:38Z edit-path: Lowered meter (local commit on branch lowered-meter, off db-registrations f08b9abd; not pushed)
cli cold build, AVRA_LEAVES=1: 0 of 13860 Lowered answers stand on names. Unnamed reads per answer: Analysis 13860 (all), References 11248, Names 10532, Namespace 8976, Settled 630, Sig 205.
Typed for comparison: 7771 of 15502 (Receivers 7567, Sig 93, ConstTyped 90, Lifted 47).

## 2026-10-13T07:12Z edit-path: Lowered named (3e846a1d on db-registrations, fast-forward from 8c012d99)
cli cold build AVRA_LEAVES=1: Lowered 13870 of 13870 answers on names (was 0 of 13860). Registered Analysis(file), Names(decl), Namespace(module), References(once), Settled(same spelling as ConstTyped). Typed 7904 of 15511 (Receivers 7576 is the blocker). fmt clean. Not measured: serve-by-record (served==fresh) nor how many Lowered read Analysis beyond own decl (meter counts families, not facts).

[lower-cold 2026-10-13] db-registrations fast-forwarded to settle-names: Settled named via settle_name(d, seats) (leaves.av; ConstTyped uses the same fn, expr roots = owner wire + offset), meter prints Settled; baseline now Typed/Lowered/Settled. Rebase onto it before your next push.

## 2026-10-13T08:22Z edit-path: avra-dy3r fixed, draft #712 (branch stub-body)
Cause: wanted_wire dropped Wanted.root; a replayed ask for a declared instance (tests.h2c_client.app) read back rootless, lower_unit's no-body guard fired, hold refused. Fix: W2 wire root mark, reader restores via declared_unit. Reproduced 2/2 (warm cache + changed binary, suite, check); clean after. Codec keeper 3/4 on main wire, 4/4 fixed. ROW_VERIFY std-http check 0; std-avrac check --baseline 0. No small cache-attack witness.
Lowered meter (3e846a1d on db-registrations): 13870/13870 on names. Next: LoweredSaid(unit) verify-only.

[lower-cold 2026-10-13] db-registrations ff to 908f9b87 (after decl-lower rewrote it onto main, my + edit-path 3e846a1d commits were re-applied on top): every Settled answer stands on names (cli 489/489, std-avrac 374/374); Syntax, Typed, LiftLowered, Input, Manifest registered (leaves.av named_by + spelled_ask index). Lowered Sig 206/282 unnamed on this base is not from these commits.

## 2026-10-13T10:00Z edit-path: LoweredSaid verify-only (branch lowered-said e418afce, off db-registrations ecfccd0c; pushed, no PR)
cli, AVRA_DB_VERIFY, verify mode reads every file fresh. Cold keep: 14339/14545 Lowered on names, spoke 0.
Then (valid / recomputed / mismatched): CONST edit 14339 / 1 (Settled) / 0; BODY edit 2294 / 12045 / 0 (Visible 4722, Names 2430, Namespace 2762, References 1961, Analysis 119, Methods 50, Syntax 1); SIG edit 1741 / 12599 / 0 (Names 1341, Visible 1491, Ref 7418, Namespace 2213, Analysis 124).
Found by the pass: a Lowered did not read its own decl's Syntax -> body edit left commands.here valid but different (1 mismatch). Fixed: lowered_unit reads syntax(d), Syntax is a named leaf.
Blocker to valid on body/sig edits: Names/Visible/Namespace/References digests move for thousands of untouched answers = not durable across derivations. unit_rows.av hand surface NOT deleted (valid fraction too low; deleting would lose const-edit-only gains elsewhere).
Also: decl-lower's typedsaid reports 25 mismatches + wreck under all-fresh mode (Resolved moved 8099).

## 2026-10-13T10:35Z edit-path: LoweredSaid on 16fc495c, ff-pushed to db-registrations (3ba9448d)
cli verify mode: 14620/14620 Lowered on names. valid / re-lowered / mismatched: CONST 14619 / 1 (Settled) / 0; BODY 2511 / 12108 / 0 (References 8988, Namespace 3065, Methods 53, Names 1, Syntax 1); SIG 1937 / 12683 / 0 (References 11459, Namespace 1213, Items 10).
Left to do: References per name (mine), Namespace (lower-cold). unit_fp/wanted_fp still fold indexed_ids (only Lowered's own value hash; says-based pass does not use it).

## 2026-10-13T10:44Z edit-path: PR hygiene
Closed #662, #667 (superseded by LoweredSaid), #685 (emit width; branch emit-width stays, keepers-static red, reopen as rebased single push), #699 (folded: #697 landed in #715; remaining commit rebased on main as draft #732, lk 20 builds/0 failed, fmt clean).

[items-kept 2026-10-13] FINDING for edit-path: under AVRA_DB_VERIFY (db-slice be227565 = main + db-registrations 3ba9448d lineage), cache-attacks fails 85 steps with `avra: a valid LoweredSaid differs f...` / `Q loweredsaid mismatch <unit>` ("mismatched 1", always one unit). Attack labels and the unit that mismatched:
- "c again: its own records keep the sealed layout [c]" -> program$rt-c_src_main_av (134 settled, valid 63, recomputed 71; recomputed because: Ref moved)
- "new instantiation, home may be held [a]" -> program$rt-a_src_main_av (135 settled, valid 63, recomputed 72; Ref moved 72)
- "layout: a module a never imports moves Bar flat -> boxed, a holds Foo [a]" -> program$rt-a_src_main_av
- "a sibling's answer type moves, its caller unedited [a]" -> @rt.lib.shown (135 settled, valid 62, recomputed 73; "References ...")
- also: "a seal arrives from a file that does not declare the record [b]" -> program$rt-b_src_main_av and @rt.lib.tick; "instantiation removed [a]" -> program$rt-a_src_main_av; "same, b [b]" -> @rt.lib.tick (136 settled, valid 61, recomputed 75; "new 3, Ref moved 72"); "a use reaches a package the closure has not met [d]" -> program$rt-d_src_main_av (60 settled, valid 3, recomputed 57; new 40).
Repro: AVRA_DB_VERIFY=1 sh tools/cache_attacks.sh on db-slice. Verify is now split (AVRA_DB_VERIFY=filesaid|typed|lowered|all, `1` = all) so mine does not mask yours: use AVRA_DB_VERIFY=lowered.

[lower-cold 2026-10-13] db-registrations is at 9de94c27 (ff from 22b9355b). Rerun your verify tables on it: Namespace folds decls by durable name (83 of 84 across processes under a top-of-file insert), LiftLowered durable unit digest 975 of 975, Typed(d) reads names_of(d) (Names slice, durable digest with positions from the decl; kernel keeps the placed slice so in-process cutoff is unchanged). Expect Lowered's Namespace column ~0 on a body edit.

## 2026-10-13T22:45Z edit-path: rebased on 9de94c27, new verify table; References-per-name built, witness catches an entry-unit defect

Rebase: `refs-per-name` fast-forwarded to `origin/db-registrations` 9de94c27 (3ba9448d was already in db-registrations). Built on Sprite avra-keepers-a; source 8e68b640.

### (1a) LoweredSaid verify table, base 9de94c27, AVRA_DB_VERIFY=lowered, `sh tools/cache_attacks`-scenario script `tools/_ep_18.sh` (three edits on packages/cli; every read fresh). Columns valid / recomputed / mismatched:
- cold: 14631 settled, 14631 stand; valid 0, recomputed 14631, mismatched 0 (new 14631)
- BODY edit (shared.av literal): 14631 settled; valid **3106**, recomputed **11525**, mismatched **0**; because **References moved 11469, Methods 54, Names 1, Syntax 1**
- SIG edit (shared.av `decl_unnamed` gains a default): 14632 settled; valid **2994**, recomputed **11638**, mismatched **0**; because **Ref moved 11523, Items 113, Syntax 1, new 1**
- CONST edit (shared.av WASM_TRIPLES literal): 14632 settled; valid **14631**, recomputed **1**, mismatched **0**; because **Settled moved 1**
Old (pre digest-fix, 16fc495c): const 14339/1/0; sig 1741/12599/0; body 2295/12044/**1**. So the digest fixes (Namespace/Names/Visible/LiftLowered) removed those columns and the Syntax mismatch is GONE; **References is now the sole whole-program mover** (~11.5k of ~11.6k body/sig recomputes). That is what References-per-name had to fix.

### (1b) References-per-name (branch `refs-per-name` 5f49d9a4, pushed; NOT a PR — base is db-registrations)
ReadFound(decl) and Consumed(decl) are per-decl families mirroring `Writes`: the references pass records each declaration's read bit (`decls.record_read_flags`), `read_found` stands on `ReadFound(decl)` instead of `Ref.by_decl(rows_db)`, and `consumed_cell` settles each declaration's consumed seats. `named_by_decl` registers both as leaves, so early cutoff applies per declaration.
Same cli verify table on the WIP:
- cold: 14641 settled; valid 0, recomputed 14641, mismatched 0
- BODY: valid **14585**, recomputed **56**, mismatched **0**; because **Methods 55, Syntax 1** (the References column is GONE; 11525 -> 56)
- SIG: valid **14396**, recomputed **246**, mismatched **0**; because **Items 244, Consumed 1, new 1**
- CONST: valid **14641**, recomputed **1**, mismatched **0**; because **Settled 1**
fmt --check on the 8 changed .av: 8 examined, 0 differing. `family_reflect_test` was red on the base (37 vs 38 families) and the WIP fixes it (40).

### (1c) The digest_diff/AVRA_LEAVES receipt was NOT obtained: the two-process index-shift receipt (insert a fn atop core/lists.av) does not finish under the WIP — A check of packages/std-avrac 165 s, B ran >1000 s and was cut at its 20-min bound (the A/B tables above are the receipt instead).

### (2) What it changes
The single edit path's cliff is named and removed: on the new tip a body edit re-lowers 11,525 of 14,631 units, all but 56 because a whole-program `References` answer moved; with per-declaration ReadFound/Consumed a body literal re-lowers **56**, a signature edit 246. `mismatched 0` in every cli row (the WIP does not stale-serve the cli).

### (3) Next step
Fix the ENTRY unit's reads, then the witness passes and the branch is landable. `tools/readfound_attack.sh` (its own witness, wired into `make cache-attacks`) FAILS 2 of its checks on the WIP: after `let taken = f3` in an entry, `mismatched 1` for `program$rf_src_main_av` and `ReadFound moved` never appears (recomputed 0). `ReadFound(f3)` itself DID move (leaves-digest 738978 -> 738979), so the family works; the entry unit's read list is `Analysis(entry), Items/Sig` of the callees and nothing that moves with the entry BODY, so the row stands while its wants gain `lib.f3`. Give the entry (`program$`) unit a read that moves with its own body (Syntax/Parsed of the entry), the way declaration units read `syntax(d)`; then re-run the cli table and try the two-process receipt on a smaller corpus.

### (4) Blockers
- FREEZE: branch pushed as `origin/refs-per-name` only; no PR (stacked base) and nothing armed.
- The entry-unit defect above is a real stale-serve hazard for entry-level value uses; the branch is a draft, not landable.
- Namespace on a body edit is now absent from the new table (digest fix); the remaining body-edit causes are Methods 55 + Syntax 1 (WIP).

## 2026-10-13T23:50Z edit-path: the entry unit reads its own body; attack green, cache-attacks green

Branch `refs-per-name` pushed to `origin/refs-per-name` at **5e8209fa** (child of `5f49d9a4`; base `db-registrations` 9de94c27). DRAFT, no PR, nothing armed (FREEZE still in force). Sprite `avra-keepers-a`.

### (1) The entry-unit fix + the witness

`Workspace.lowered_unit` (packages/std-avrac/src/compiler/workspace_analysis.av) read `syntax(w.decl)` only when a unit HAD a declaration. A program's entry (`program_main`: `decl: null, root: null`) has none, so its read list was `Items` of its callees, `Analysis(entry)` and `Sig` of the callees — nothing that moves with the entry's own body. It now reads the file's own parse for a body no declaration owns:

    if w.decl != null { let _ = self.syntax(w.decl!) }
    else if w.root == null { let _ = self.parsed(w.file) }

The `w.root == null` guard keeps the read to a PROGRAM ENTRY: a const initializer, a seat default or a lift is an expression root and keeps its own reads (scoping to all no-decl units had made every edited file's expression units re-lower).

Witness last line (`sh tools/readfound_attack.sh`, wired into `make cache-attacks`):

    readfound-attack: an entry's own body edit re-lowers it, another file's signature edit leaves it standing, 0 failed

**Correction to the task's second failing check.** "ReadFound moved" CANNOT appear in a `loweredsaid` cause: I dumped the entry unit's full kept read list under `AVRA_QTRACE` —

    Items m1.av, Items prelude.av, Items m2.av, Analysis main.av, Parsed main.av, Items m3.av,
    Sig c1, Sig c2, Sig c3, Sig println

— and "an unrelated signature edit" moves a Lowered unit through `Consumed(f2)` (edit-2 read list: `Syntax c2, Analysis m2, Items m2, Sig c2, Consumed f2, Sig f2`), never through `ReadFound`. `ReadFound(d)` is read only inside `computed_consumed` (compiler/consumes.av's `taken_as_value`), so it is a dep of `Consumed(d)`, not of any Lowered unit. And a read that is NEW after the edit (`ReadFound(f3)`, `Sig f3`) is not in the kept row at all, so `first_moved` can never name it — the row's already-kept reads are what decide. The witness now asserts what the fix actually provides: the entry re-lowers on its own body (`Parsed moved`), never on the whole-program `References`, and another file's signature edit leaves it standing. `ReadFound(f3)` still moves (leaves-digest 738978 -> 738979); the family works — the witness was asking a Lowered row to stand on a family that only `Consumed` reads.

### (2) cli LoweredSaid verify table (`AVRA_DB_VERIFY=lowered`, every read fresh; `tools/_ep_18.sh`, valid / recomputed / mismatched)

- cold: 14641 settled; valid 0, recomputed 14641, mismatched 0 (`new 14641`)
- BODY edit (shared.av `env_of` literal): valid **14584**, recomputed **57**, mismatched **0**; because **Methods 55, Syntax 1, Parsed 1**
- SIG edit (shared.av `decl_unnamed` gains a default): valid **14395**, recomputed **247**, mismatched **0**; because **Items 244, Consumed 1, new 1, Parsed 1**
- CONST edit (shared.av WASM_TRIPLES literal): valid **14640**, recomputed **2**, mismatched **0**; because **Settled 1, Parsed 1**

The base's BODY row (pre-WIP) was valid 3106 / recomputed 11525, `References moved 11469`; the WIP's was 56. BODY is **57** (target ~56), `mismatched 0` in every row. The +1 in BODY/SIG/CONST over the WIP (56/246/1) is the edited file's own program unit re-lowering on its `Parsed` — the entry read, doing its job. (A clean standalone cold+const shows the same coarse `Methods 55` + `Settled 1` + `Parsed 1`; the accumulated const row is 2 because the Methods movement was already spent by the body edit.)

### (3) `make cache-attacks`

Last line (13 attack scripts, all green):

    readfound-attack: an entry's own body edit re-lowers it, another file's signature edit leaves it standing, 0 failed

Earlier lines of the same run: `cache-attacks: 378 builds through one store, 129 under a hold, 0 failed`; `link-cache-attack: 13 builds through one store, 0 failed`; `store-reads-attack: 8 steps passed`; `writes-attack: one fn began writing, only its reader was told, 0 failed`. No NEW mover was exposed by the entry-unit fix beyond the one `Parsed` unit per edited file already named in the table.

### (4) sha + blockers

sha **5e8209fa** on `origin/refs-per-name` (draft; no PR, nothing armed).

- `./avra check packages/std-avrac --baseline tools/idioms.baseline` reports 24 NEW violations — ALL pre-existing WIP debt (leaves.av's `duplicated_literal` and `first_moved`'s `let_else_guard`, workspace.av's three `*_verified` free verbs, decls.av's bypass, std-relation's two), none at the entry-unit site. The WIP never carried a baseline update; not adopted here.
- `fmt --check` on the changed .av: 1 examined, 0 differing, 0 refused.
- FREEZE: the branch is compiler-touching; nothing lands until CHANNELS' #710 merges. Pushed DRAFT only.
- Pre-existing WIP items still open (from the entry above): the two-process index-shift receipt; Namespace on a body edit is now absent; body-edit causes are `Methods 55` + `Syntax 1` (+ `Parsed 1`).

## 2026-10-13T20:40Z edit-path: Lowered reads the declaration it names, not its file's Items (draft f6a2c3e3)

Branch `refs-per-name` @ **f6a2c3e3** (child of 5e8209fa; base `db-registrations` 9de94c27). DRAFT, no PR, nothing armed. Sprite `avra-keepers-a`. One line in `workspace.av`: `.Lowered` moved off `reads_rows_whole` (only `.LiftLowered/.Lifted/.Settled` stay whole), so `row_read` records the declaration's own `Named` bucket inside lowering instead of a coarse `Items(file)` edge — the same grain typing already uses.

### (1) The narrowing + the cli LoweredSaid table

The cli's 244 `Items` movers are units that read a declaration of `shared.av`; `Items(shared.av)` moves when `decl_unnamed` gains a param because `row_print` folds the row's `told` (its seats). With `Lowered` fine, only readers of the changed declaration move. `AVRA_DB_VERIFY=lowered`, every read fresh, `tools/_ep_18.sh` (three edits on packages/cli), valid / recomputed / mismatched:

- cold: 14641 settled; valid 0, recomputed 14641, mismatched 0 (`new 14641`)
- BODY edit (shared.av `env_of` literal): 14641 settled; valid **14584**, recomputed **57**, mismatched **0**; because **Methods 55, Syntax 1, Parsed 1**
- SIG edit (shared.av `decl_unnamed` gains a default): 14642 settled; valid **14638**, recomputed **4**, mismatched **3**; because **Sig 1, Consumed 1, new 1, Parsed 1**
- CONST edit (shared.av WASM_TRIPLES literal): 14642 settled; valid **14640**, recomputed **2**, mismatched **0**; because **Settled 1, Parsed 1**

SIG's recomputed drops **247 -> 4** (the 244 `Items` movers are gone; BODY is unchanged at 57). BUT `mismatched 3`: the verify wrecks (`avra: a valid LoweredSaid differs from a fresh lowering: a read is missing`), so the branch is NOT landable as it stands.

### (2) The 3 mismatches are positional synthetic symbols, not Items

The mismatched units are `commands.root_program`, `commands.wasm_runner`, `commands.verify_held` — all in `shared.av`, all AFTER `decl_unnamed`. Their kept and fresh read SETS are IDENTICAL and every digest stands, yet `says` differs. Dumped (a temporary `AVRA_SAID_ONLY` filter restricted the pass to those units; the probes are `tools/_ep_43.sh` / `_ep_44.sh`, not committed):

    kept  says: ... fn$commands.shared$l446 ... commands.shared$lit657 ...
    fresh says: ... fn$commands.shared$l447 ... commands.shared$lit658 ...

A lifted lambda is named `file_symbol(f, "l${e.index}")` (`features/decls.av` `lifted_symbol`, `lower/state.av` `lifted_as`), and a static literal `file_symbol(f, "lit${e.index}")` (`features/values.av` `spelled_static`). `e.index` is FILE-ABSOLUTE: adding a param with a default to `decl_unnamed` (declared above `root_program`) inserts nodes, so every later node's index — and thus symbol — shifts. The unit's `Syntax(d)` is structural (folds fingerprints), so it does not move, and no `Named` bucket exists for a lifted node. The old coarse `Items(shared.av)` caught this by accident (the param name moved the file's rows). A per-declaration read cannot: the dependency is on the file's arena layout, not on a declaration.

`tools/_ep_44.sh` (a small same-file program, callee + callers in one file, same sig edit) is CLEAN (mismatched 0) — `Sig`/`Consumed` cover ordinary callers; only units that LIFT a body after the inserted nodes are hit. Requires a file with an edited declaration declared BEFORE a lambda-bearing unit.

### (3) `make cache-attacks`

Last line:

    readfound-attack: an entry's own body edit re-lowers it, another file's signature edit leaves it standing, 0 failed

Full run green: `cache-attacks: 378 builds through one store, 129 under a hold, 0 failed`; `link-cache-attack: 13 builds through one store, 0 failed`; `turn-memory-attack: ... 0 failed`; `gathered-cache-attack: 7 runs ... 0 failed`; `store-reads-attack: 8 steps passed`; `static-names-attack: 17 ... 0 failed`; `moved-tree-attack: ... 0 failed`; `held-runs-attack: ... 0 failed`; `cancel cache attack: 11 step(s), 0 failed`; `writes-attack: ... 0 failed`. cache-attacks does NOT exercise the same-file sig-edit + symbol-shift kind, so it is green over a real defect.

### (4) Idioms

`./avra check packages/std-avrac --baseline tools/idioms.baseline` prints `idioms: 24 NEW violation(s)` — the SAME 24 pre-existing WIP sites as before (leaves.av, `*_verified` free verbs, decls.av bypass, std-relation). No violation cites `reads_rows_whole` or any line this commit touched. The 24 are left unadopted.

### (5) sha + blockers

sha **f6a2c3e3** on `origin/refs-per-name` (draft; no PR, nothing armed). `fmt --check` on the changed .av: 1 examined, 0 differing, 0 refused.

- **Blocker (the finding):** the narrowing is UNSOUND until lifted/static-literal symbols are addressed durably. `site_of` (`features/decls.av`) already content-addresses a literal (module, stem, content, turn) and `structs/lower.av` uses it, while `values.av`'s `spelled_static` and `lifted_symbol` still use the raw `e.index`. Make those two durable (declaration-relative or content-addressed) and the fine reads suffice; then SIG settles at ~4 with mismatched 0. That is a separate slice (it renames generated symbols, touching the `.ll` goldens and `lower_test`'s `$l<N>` assertions).
- **Alternative, if a sound win is wanted first:** read `parsed(w.file)` for units whose declaration mints a positional symbol (or, coarsely, for all units). Sound, but SIG falls only to ~the edited file's unit count (~70 for shared.av) and it regresses same-file granularity — against the lane's grain.
- FREEZE still in force: compiler-touching, nothing lands until CHANNELS' #710 merges. Pushed DRAFT only.

## 2026-10-14T11:39Z edit-path: 672e5a18 verified — SIG 4 / mismatched 0; the attack now exercises BOTH halves

Branch `refs-per-name` pushed to `origin/refs-per-name` at **606da3d3** (child of `672e5a18`;
base `db-registrations` 9de94c27). DRAFT, no PR, nothing armed. Sprite `avra-keepers-a`.

### (1) `672e5a18` verified complete and sound

`AVRA_DB_VERIFY=lowered` on packages/cli (`tools/_ep_18.sh`, `AVRA_BIN=build/avra-try`), every
read fresh (`tools/_ep_60.sh` / `_ep_62.sh`), valid / recomputed / mismatched:

- cold: 14645 settled; valid 0, recomputed 14645, mismatched 0 (`new 14645`)
- BODY edit (shared.av `env_of` literal): 14645 settled; valid **14588**, recomputed **57**,
  mismatched **0**; because **Methods 55, Syntax 1, Parsed 1**
- SIG edit (shared.av `decl_unnamed` gains a default): 14646 settled; valid **14642**,
  recomputed **4**, mismatched **0**; because **Sig 1, Consumed 1, new 1, Parsed 1**
- CONST edit (shared.av WASM_TRIPLES literal): 14646 settled; valid **14644**, recomputed **2**,
  mismatched **0**; because **Settled 1, Parsed 1**

**SIG 247 -> 4 (target ~4), mismatched 3 -> 0.** The three positional synthetic-symbol mismatches
(`commands.root_program`, `commands.wasm_runner`, `commands.verify_held`) are gone: `lifted_symbol`
(`features/decls.av`) and `literal_symbol` (there; `values.av` calls it) now name a WRITTEN lambda by
content and its turn, and a static literal by content and its deciding type. The durable naming is the
fix; `Lowered`'s fine read is sound on it.

### (2) Goldens / assertions

`lower_test`'s two `$l<N>` assertions were updated by `672e5a18` to content hashes
(`$l4403168589458213290`, `$l4547253456816728194`); no other assertion in the tree carries a generated
symbol. Scoped run `avra test .../compiler/tests/lower_test.av` = **67/67, exit 0** (`tools/_ep_65.sh`).

`git ls-files '*.ll'` answers exactly one file: `bootstrap/seed.ll` — there is no other committed `.ll`
golden. The seed is a CADENCE refresh, not a per-landing one: `tools/seed_guard.sh` says so in its own
words ("a refresh per landing conflicts every other branch on the seed"), and this branch is a DRAFT
off PRE-#705. **The seed was NOT regenerated** (a 47 MB artifact, and it would name this WIP tree).
Flagged for the lead; nothing in the gate list reads it.

### (3) The attack — and it now exercises BOTH halves

`tools/durable_symbol_attack.sh` (added by `672e5a18`) was OVERCLAIMING: its literal returned a bare
string, which lowers to an inline constant, never a `$lit` global — so only the LIFTED body was ever
checked. `606da3d3` fixes the fixture (a `List<int>` literal spells a laid-out static), compares the
WHOLE quoted-global set (lifted bodies are escaped `$24l$2D…`, static globals ride raw `.m$lit…`), and
guards that both kinds are present so neither half can silently stop being exercised.

Witness — the reverted compiler (`build/avra-try`, `lifted_symbol`/`literal_symbol` back on `e.index`),
store cleared before each run (`tools/_ep_75.sh`):

    FAIL  the sig edit moved a kept lower without a mover: ... valid 6, recomputed 3, mismatched 2 ...
    FAIL  a unit mismatched after the sig edit: Q loweredsaid mismatch lib.holds_a_literal
    FAIL  a lifted/static symbol moved with the sig edit:
          cold [@"...$24l5" @"av_lib.m$lit11" ] sig [@"...$24l6" @"av_lib.m$lit12" ]
    FAIL  the sig verify check exited 2 ...
    durable-symbol-attack: ... 4 failed

On the fixed compiler: `durable-symbol-attack: a same-file signature edit left every lifted/static
symbol standing, 0 failed`. The attack is green over nothing now.

### (4) Gate (last lines)

`make cache-attacks` exit 0 (13 attacks, `build/ep76.out`):

    cache-attacks: 378 builds through one store, 129 under a hold, 0 failed
    ...
    durable-symbol-attack: a same-file signature edit left every lifted/static symbol standing, 0 failed

`avra test packages/std-avrac` exit 1 — `8732/8760 tests passed`, 28 PRE-EXISTING DB-slice reds
(`decl_rows` 9, `method_rows` 3, `decl_grain`/`facts_family`/`held_sig`/`names_family`/`cache_walk`/
`written_where` 2 each, `readmit`/`syntax_failures`/`syntax_receivers`/`grammar_derive_adversarial` 1) —
NONE reads a generated symbol, and the only symbol golden, `lower_test`, is 67/67. The suite STOPPED at
the derive codec failure, so its tail did not run; the earlier lane reports already carried these as WIP
debt ("Plus the S1 suite" / `decl_grain_test`/`family_reflect_test`), and `672e5a18` only renames symbols.

`fmt --check` on the slice's changed `.av`: `4 examined, 0 differing, 0 refused`, exit 0.

Idioms: `./avra check packages/std-avrac --baseline tools/idioms.baseline` exits 1 with
`idioms: 24 NEW violation(s)` — the SAME pre-existing WIP sites (leaves.av `duplicated_literal`/
`hand_sized_index`/`let_else_guard`, workspace.av's three `*_verified` free verbs, core/fp.av
`modified_copy_literal`, decls.av `bypass_outside_bracket` at `decl_row_rows.get()` — NOT at
`lifted_symbol`/`literal_symbol` — and std-relation). Not adopted.

### (5) sha + blockers

sha **606da3d3** on `origin/refs-per-name` (draft; no PR, nothing armed).

- **FREEZE** still in force: compiler-touching, nothing lands until CHANNELS' #710 merges.
- The 28 suite reds and 24 idiom sites are pre-existing on the branch; this slice adds neither. The
  suite aborts early (after the derive codec case), which is itself a gap in the receipt.
- **Seed not refreshed** (see (2)) — the one deliberate delta from the task's "`.ll` goldens" wording.
