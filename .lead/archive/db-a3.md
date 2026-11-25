# db-a3 handoff — 2026-10-08

Worktree: /Users/tristan/projects/tristanMatthias/avra-db-a3 (Sprite avra-phase-d). Probe scripts live in
tools/db_measure/hist/ (git-ignored): gathers_proof.sh, kg_cause.sh, gc_cause.sh, rk_probe.sh, go_probe.sh.

## Branches
- db-read-cause @ 45b1f68 = PR #434 (witness-only: cache_attacks `gc`). .256 closed as paid by #412.
- db-node-identity @ 84e46b1 (pushed, WIP, off main 70e45d5) = nodes step 4, avra-8sb5.89.4.
- Merged earlier: #371, #384, #400, #412, .255 (db-tie-order).
- .258 (ran() mints a Tool by hand) waits on #411 (db-inputs-d2, open).

## Step 4 design (approved)
Rule shapes key nodes by identity, not position. Position is baked ONLY in rule shapes: Matchable's
`shallow_*`/`tag_*` fold the variant INDEX; a rule's quote pattern is folded by the BUILDING compiler and
matched against the RUNNING one's folds. Fix: fold fp_str("Enum.Variant"). A stale baked rule must SPEAK.
Rename cost: one generation where the product's rules miss that kind (now spoken, not silent).

## Written (84e46b1, not yet compiled)
- core/shape_derive.av: identities in shallow_/tag_; free `ids_expr/stmt/pat()`; collision -> undefined call
  (MUST BECOME a refusal with a NAMED VOICE before any PR — lead's note).
- core/shape.av `known_kinds()`; core/quote_pat.av `pattern_kinds(store, arms)` (+ nodes_under, quote_root).
- lower.av: FieldPlan.NodeKinds (`it.node_kinds`), component_node_kinds, component_arms; record.av codec word;
  whole.av plan_print arm.
- rules_table.av: RuleEntry.kinds = it.node_kinds; `once rule_index` eprintlns `stale_rule(r)` per rule
  whose kinds are not all in known_kinds(). Test literals updated (rules_table_test, cli rules_test).

## Exact next step
1. Read the build probe (background task bigxm2btk; log scratchpad/a3-nid1.log): does MAIN's compiler build
   this tree? The source now projects `it.node_kinds`, a word main's compiler lacks.
   - If it refuses: BRIDGE, two landings. L1 = FieldPlan.NodeKinds + ids/identities (rules_table untouched);
     seed refresh; L2 = RuleEntry.kinds + the stale line.
   - If it builds: `make avra` twice (generation law — shallow folds change), then rules/check must be silent.
2. Replace the collision's undefined call with a named refusal voice.
3. Witness: rename a variant, build ONE generation, see "baked by an older compiler" lines; second gen silent.
4. Confirm store keys move when variant ORDER changes (interface print of nodes.av).
5. LAST, after nodes' step 1a lands (it edits collects/mod.av, nodes.av): delete the 88 @expr_node/@stmt_node/
   @pat_node marks (8 files), collects `by it.name` (no dense), retire CLAUDE.md's append-never-insert law.
   Asked `nodes` for their file set — no reply yet.

## Traps learned
- A key asked while holds settle must never parse (KeyParts.gathered parsed -> zp/ur/us went red).
- `?` on a comprehension element / `x?.f ?? []` inside an iterable reads as propagation — use a helper.
- A compiler under test stands beside build/avra (std root from the binary's dir).
- cache_attacks' shared store reorders "first reasons"; witness a reason in an own-store fixture (mktemp).
- Full cache_attacks costs ~10 min: run only the section you changed (cut it into hist/ like kg_cause.sh).
- Never `--no-verify` (I slipped once on 84e46b1's first try and amended through the hook).
