# Handoff — lane db-explain-2 (2026-10-08)

Worktree ../avra-db-explain · Sprite avra-unions-p2-b · current branch rule-meta-l1 @ 1f76afa (PUSHED, WIP, UNVERIFIED), off origin/main e7108bd.
In flight at pause: Sprite run Mac-mini-60861-1791449028 (build + package_rule + quote suite + std-meta suite + `rules --json`). It ran on a tree whose std-meta/rule.av was formatted afterwards (whitespace only). `sh tools/work attach` reads it.

## Other branches (state)
- #401 dyn-narrow: MERGED (351e054). Ticket avra-8sb5.11.382 closed.
- dyn-narrow-is @ f3c93f1 (PR #413): `if s is c: Code`; idioms fix pushed; lead lands it.
- Follow-ups filed: avra-8sb5.11.386 (per-instance dyn tags), .387 (duplicate typed arm unreachable).

## .378 design (approved by lead)
1. @std/meta gains `trait Subject { fn text() -> string }`, `enum Fix { Rewrite(Code), Delete(List<Site>), Say(Diagnostic) }`, `Fixes`, `component rule { run: fn(dyn Subject) -> Fix?, doc, fixes, keeps, law }` (packages/std-meta/src/rule.av).
2. std-avrac: `impl Subject for Code`; `Decls.rule_fix(ty)` is the one door for either home's Fix (widen check + walk.av `fixed`).
3. Compiler rules' arms wrap in ONE narrow `match it { c: Code -> match c { <arms> }, _ -> null }` (uses #401) — L2.
4. Package rule: `it` stays `dyn Subject`; quote binders type as the subject; a package rule's fn lowers to a trap (phase A runs rules as DATA; phase B via the meta crossing like @derive).
5. Ladder: L1 = meta shapes + impl + doors accept both homes, nothing switched; seed refresh; L2 = switch compiler/idioms.av + every feature idioms.av to meta's `rule`, delete features/fix.av's Fix and features/rule.av's component.

## L1 written (1f76afa)
- std-meta/src/rule.av; features/code.av (`impl Subject for Code`, Code.text moved into it); decls.av (`meta_type` reads Enum and Dyn shapes; `rule_fix`); checks.av + lower/walk.av use `rule_fix`.
- quote/check.av: `subject_binders` for a `dyn Subject` subject; a type hole refused (`typed_in_package`); FillClass.Held takes a Subject.
- quote/lower.av: `uncalled`/`uncalled_binds`/`held_text` (trap: "a package's rule is matched by the compiler, never called").
- Fixture compiler/tests/package_rule (avra.toml, src/main.av + main.expected "Adding zero changes nothing. 1 1").
- VERIFIED: nothing yet.

## Exact next step
Read run 60861. Fix what refuses. Then: `avra rules --json` byte-identical vs main's compiler (build main's beside, or the `make try` binary); goldens for type.quote_pat_subj's new voice; quote/narrows/meta suites; keepers-static; idioms on std-meta and std-avrac; push; lead opens the PR after a seed refresh plan.

## Bars (lead)
- L2: warm `check packages/cli` must cost ≤ 2% more, or STOP and show the lead before landing.
- A golden per voice the rules emit, diffed before and after L2.

## Traps
- Local build/avra predates #410: the pre-commit hook may misjudge formatting; build locally first (`make try` once on main base, or `make avra`, under tools/watch.sh, one heavy build at a time; check `ps -ax | grep -c "[a]vra build"`).
- `work run` with `timeout 20` can die while the Sprite wakes; give it 90 s, then confirm the run id with `work attach | head`.
- Probe scripts go in tools/lane-probe/ (synced) and are moved out before every commit.
- No whole suites on Sprites; whole suites run on the PR check.
