# nodes-carriers

[2026-10-16 00:20] lane started. Worktree /Users/tristan/projects/tristanMatthias/avra-nodes-carriers,
branch nodes-carriers off origin/main 9cdec783. No free Sprite; builds run locally under the shared
watchdog lock.

[2026-10-16 02:20] REPORT — DRAFT PR #814 (base main, NOT armed): branch nodes-carriers, head
9e3eb312, 1 commit, 11 files +143/-90.
CARRIER ADDED: `LangNode.NVariant(Variant)`; nested `payload` -> `Record.PayloadSyntax` and
`variant` -> `Record.VariantSyntax` rules; `features/variant_builder.av` mints `NVariant` and
(reusing `NParam`) the payload; `Slots.variants_of`/`marks_of` + `builder.variants_at`.
BUILDERS KILLED: `build_enum_decl` (-67) + `payloads_between` + `name_before`; enums/builders.av
144 -> 50 lines; the mark-window zip and `MarkWindows`/`window_end`/`ref_within`/`type_lo` imports
are gone from the feature.
RECEIPTS: `make avra` green; `gate_changed --refs origin/main HEAD --no-keepers` clean;
`make keepers-static` exit 0; `AVRA_CAP_MB=12000 avra test packages/std-avrac` exit 0;
scratch probe eval == native; marks program test now carries a variant mark + payload mark
(21 -> 28). RED TEAM: 8 classes run; SURVIVOR found+fixed (`a()` parsed as a zero-payload variant
because the paren group's content was optional — `enums_adversarial_test` caught it, now the group
requires >=1 payload). REVIEW ROUND: clean; `payload()`/`seat()` are two Param-builders, the third
(`NField`) is the extraction trigger.
BLOCKERS: none. NEXT: `NField` (struct fields), then `NSeat`. `Field.default` not needed by enums.
NOTE: intercom has no session named "lead"; the heartbeat file is the channel.
