# UI PRs ready for a batch (from the UI lead)
Updated 2026-10-25. Main d704a675. All green on their last run; most are based before AF/AG, so a refresh run may be wanted.
Order constraints: #1237 → #1224 → #1265; #1220 carries #1237's commit; #1241 and #1248 conflict on skip() (second rebases).
- #1237 8b1ae974 — @model doors take no `mut db`
- #1224 772c8f24 — @std/crud (after #1237)
- #1265 90361339 — access policies: Where/Op pushdown, single-statement scoped writes (after #1224)
- #1220 58148dd0 — Time stored as its scalar, @json_text, embed-admits-no-package rung (HELD: std-time suite cost unmeasured)
- #1242 dce45a07 — SQLite reopened per process after a fork
- #1245 29e34941 — wasm-body keeper reads #if guards
- #1247 9016364d — a template's names are judged in the file that wrote it
- #1248 f4f3834c — cold Firefox relaunch; an oracle that ran 0 trees fails
- #1241 2cf9e7fc — text slice 1
- #1249 e77a5ace — mcp route's origins default to loopback only
- #1254 0c218f17 — component_home from an index (CONFLICTING: needs rebase)
- #1255 2b3af639 — a malformed field spread names its spelling
- #1257 a6519228 — compile slots: fair semaphore (Linux red-first proven)
- #1263 0e54fb75 — @json/@form records at any width
- #1264 770bbff3 — a check reports only the files its program reaches
- #1267 c3a70272 — a page's warnings reach avra dev
- #1268 5fb9ff8d — lambda seat hygiene (hole-named sibling param)
Not ready: #1252, #1260, #1261 (warm-edit ceiling: owner decision), #1270, #1246 (Task naming: owner decision).
