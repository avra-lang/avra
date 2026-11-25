# avra-lane-held-items hand-over
Branch avra-lane-std-store-2 (worktree /work/ws), head de576036 + this note, base next-base cd4738e6 (stage 1 merged in).
DONE / handed back: avra-lane-held-items.bundle (BoundedCache, landed); avra-lane-std-store.bundle (stage 1: machine store layer, purity bit, pack mapping fix, witness_machine_store.sh; OFF unless AVRA_MACHINE_STORE=1); cold-map, std-store design, step-2 spec md files.
IN THIS BRANCH (not handed back before): package-set generalisation — std-program package_sets.av (NameSets, interned sorted name sets, tests 4/4); query_engine read_sets per question (input = package of each path read; else union of reads), shared bit = every member shares_package; engine.packages_read(question) export for emit-speed's Package class; LayeredStore takes PackagePlace{name,root,shared}; tapes.av package_places(root,name,std,deps) set for every build (use_package_places), machine_layer only adds the store.
State: FINISHED. Proven: std-program 449/450 (only the root-chmod case, as trunk); package_sets_test 4/4; layered_store_test 7/7; AVRA_PROGRAM=1 make try exit 0; cold AVRA_PROGRAM=1 build packages/cli exit 0; witness_machine_store.sh (a)-(f) green.
Not run on this branch (stage 1 had them green): --built, idioms, edit witness x2, refusal suite. To resume: cd /work/ws && sh /work/m/gate-ws.sh
Stage 2 design: .lead/handoff/avra-lane-held-items-stage2-design.md (program step from per-package reach tables; ~7.4 s est.).
Findings: BoundedCache trim measured negative (dropped); program layer ignores std path pins (whole-program); engine.print differs per command (machine layer uses binary stamp).
Do not touch without me: std-program layered_store.av, package_sets.av, purity code in query_engine.av.
