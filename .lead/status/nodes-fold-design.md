# nodes-fold-design status

- #1092 nodes 5b-5d + let_stmt fix (draft, hold). #1093 DB 07c CancelReach (draft, hold, base receivers-scc).
- #1095 DB 08a' fmt canonical verdict (draft, hold): canon_key + DbRow.Canon deleted; canon_provider_test 6/6, compiler/tests 1539; warm 1.45 s over 1439 files.
- #1097 DB 08c Proved (draft, hold): proved_key deleted; proof FILE keeps its shape (CI hands .avra-cache/proofs between shards) but holds its reads, validated by store.reads_hold (one rule, Store.holds calls it too). suite_proofs_test 4/4, let_stmt 111 with 2 real proofs, compiler/tests 1555.
- Worktrees: ../avra-nodes-syntax (nodes-5d), ../avra-db08a-canon, ../avra-db08c-proved. Sprites held: avra-nodes234, avra-reuse, avra-rebase-clean-3.
