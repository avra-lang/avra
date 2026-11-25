# hd-fixes (lead-written; lane force-stopped)
- hd-ghrun dc2eab58: GitHub `tools/work run` (default; --sprite old path), one lane cache (~125 MB). hd-gatefix 12e57992: MAIN_GATE #8-11 + ci-invariants + tool-witnesses fixed. Both are merged in hd-gate da3a93cb (not yet pushed to hd-clean).
- Open, blocking the hd-clean push: `witnesses` keeper wants docs/DIAGNOSTICS.md regenerated (`./avra diagnostics > docs/DIAGNOSTICS.md`) after the mixed_bitwise witness. fmt-lossless: "0 differing, 32 refused"; find the 32 and fix at cause.
- hd-writes (in hd-clean): point 8 W1/W2/W4/W6 done. Next: cancels/record_cancel and written_seats (same hand-fixpoint-table shape), file_tokens' row write (needs saved ctx queries).
