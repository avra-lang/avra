# Handoff: the Avra compiler's new pipeline, to the switch and beyond (2026-11-10)

You are the lead on the Avra compiler's new pipeline. Avra is a programming language and its compiler is written in Avra; the owner is Tristan. The bar: the world's best compiler and language — first principles, the best data structures and algorithms, declarative, no workarounds, one definition per concept, old machinery cut aggressively. Use Fable or Opus agents for real work; you coordinate, review every change, and commit.

## The vision and the principles (read twice)
- **The mission:** the best programming language and compiler in the world, built by an AI-first team.
  - **Optimal ergonomics and performance:** the owner's MOST IMPORTANT directive is "drive for excellence": maximally optimal ergonomics AND performance. Compromise only when truly blocked, and then the block is the next work.
  - **The bar:** internal-Google-level engineering.
- **No sacred cows.** You have complete authority to change or invent any core data structure, library, runtime row or language construct. Nothing old is baked into the new design. Cut old machinery aggressively. RADICALLY simplify, centralise and reduce complexity; nothing is off limits.
- **First principles, always.** Every design starts from what the problem actually is, never from what the old tree did (follow its documented designs, never its code habits). Ask of every step: what would the best compiler ten years from now do here? The designs in the plan (the meaning/lowering/target tower; proven rules; Futamura; live programs; a learning superoptimiser) are that question answered; keep asking it.
- **The best data structures and algorithms**, even very advanced ones: columnar tapes, content addressing, incremental queries with early cutoff, frontiers with change-only deltas, e-graphs, BURS, Perceus, partial evaluation. Name the technique and its source when you use one.
- **Declarative, built from Avra's own advanced features.** Components, `collect`, quotes, meanings, arms bodies, derives. The compiler is Avra's first user: when its code wants a construct the language lacks, that ask goes in the ROADMAP sugar backlog. One source of truth, many projections (P12). Visible magic (P7): everything inspectable through `avra explain`.
- **No workarounds.** A symptom is traced to its cause, and the cause is fixed. When a trade-off feels forced, the model is wrong (P6, paradox collapse: find the design where both sides win).
- **Avra's principles** (CLAUDE.md, the spec's Part 0):
  - P1 LLM-first;
  - P2 a substrate for autonomous services;
  - P3 gloriously declarative, zero ceremony;
  - P4 Rust-level performance or better;
  - P5 full-stack vertical integration;
  - P6 paradox collapse;
  - P7 visible magic;
  - P8 escape hatches everywhere;
  - P9 boundaries are contracts;
  - P10 the compiler holds semantic knowledge no other tool has;
  - P11 machine-readability is the substrate;
  - P12 one source of truth, many projections;
  - P13 collapse dev/ops/infra;
  - P14 no runtime, no framework, no container;
  - P17 composability over featurefulness.
- **How the owner works with you:**
  - **New language features** are proposed with code examples before they are built. The owner approves spellings; the ones approved now are in the plan.
  - **What frustrates the owner:** being pulled onto checklists, infrastructure sinkholes, long local runs, hours lost, and a state that isn't stated honestly.
  - **What lands well:** an honest "it's not done, here is exactly where it is" beats a confident summary.

## Where things live
- **Plan of record:** `/Users/tristan/projects/tristanMatthias/avra/.lead/PROGRAM_DESIGN.md` (main checkout). Read these sections first:
  - "Draft, owner reviewing 2026-11-10: from typed program to running code, first principles" — the meaning design;
  - "Slice 1, built so far";
  - "Draft, owner reviewing 2026-11-10: lowering, and every target, as declared rewrites" — APPROVED, with its build order;
  - the "Measured 2026-11-10" sections;
  - "## Open".
- **Work:** worktree `/Users/tristan/projects/tristanMatthias/avra-ho`, branch `program`, tip `cfbd7a39`. Commit as you go on `program`; NEVER push to main.
- **Law:** `avra-ho/CLAUDE.md` is law: the idiom bar, evergreen terse comments, registries spell every arm, the IR vocabulary's growth protocol, the generation law, the memory laws. DOGFOODING.md lists the idioms; ROADMAP.md holds the sugar backlog.
- **Memory:** `/Users/tristan/.claude/projects/-Users-tristan-projects-tristanMatthias-avra/memory/` (index MEMORY.md).

## What exists (built and committed)
- **The program layer**, `packages/std-program`:
  - the query engine with a per-binary **frontier**: a snapshot of every valid answer, written as a chain of change-only deltas, each naming its parent;
  - inputs asked first, readers of changed inputs as suspects, everything else settled untouched;
  - structural validation of packs and frontiers at open;
  - compaction seeded from the newest 2 frontiers (one disk ceiling);
  - deep records deleted.
- **The new typer:** `std-avrac` core/checking.av (`Checking`) and core/signed_types.av (`SignedType`, `reaches`). Parity with the old typer: std-text 100%, cli 99.7%, std-program 98%, std-avrac 98%. What's left is generated code (`@derive`/`@query`), which needs generators running on the new layer.
- **Meanings (slice 1):** sugar → a ~15-form core, declared as a `meaning` component, written as `rule` is (arms of quote pattern → quote template).
  - **The pieces:** features/meaning.av (`TypedCode` subject); compiler/meanings_table.av (collected, `RootIndex`); compiler/item_elaborated.av (`elaborated_fn`: type the surface, splice meanings, type again as core); compiler/sugars.av (one `copied_template` splice door).
  - **Fills and hygiene:** fill classes `Node`/`Nodes` (holes spliced by node, arena-checked); hygiene (a template's own names marked `·e<n>`/`·s<n>`, a hole's names kept); statement meanings (`stmt_meanings`); a `match` on a condition narrows like `if`.
  - **Meanings live:** features/nullable/meanings.av (`??`), features/if_expr/meanings.av (`if … else`), features/loops/meanings.av (`for` over a list).
- **The generated parser** (`compiler/untold_parser.av`) is the compiler's parser; it matches the engine on all 2,546 files of the tree.

## Numbers (std-avrac, program layer, on the Mac)
- **Timing and memory:** cold 4.2 s; every process ≤ 45 MB of heap (parent 39); warm 93–97 ms with 0 records checked; one body edit ~170 ms (the folding write ~250).
- **Fixed point:** `make avra` twice is byte-identical at 33fadd80 (104,517,936 bytes).
- **Whole-tree receipts:** `avra tapes` 57 packages, 2,350 files, 0 differing; `avra parsers` 2,546 files, 0 differing.
- **Suites:** std-program 345/345, std-grammar 56/56.
- **std-avrac tests on a GitHub runner:** quote 150/150, subset 91/91, rules_table 7/7, the six item_* files green. The FULL std-avrac suite as one run needs > 14 GB, so it must be split into parts.

## Slice 2 step 1 is DONE and committed (8ae128b1): the typed core lowers to IR
- **Built:**
  - `core/layout.av`: `Layout` is Void, Word, Truth, Real, Boxed(BoxKind), Bare, Fields (a flat record), Tagged(counted) (a value enum and which of its tags carry a counted pointer) and Maybe (a nullable pair). Its nullable rules mirror the old `inner_repr_of`. It is read as `CheckedProgram.layout(ty)` and answers absent for type parameters and named types.
  - `core/lowering.av`: the `Lowering` context, whose verbs mirror emit.av's.
  - `core/lowers_derive.av` and `core/stmt_lowers_derive.av`: the `Lowers` and `StmtLowers` traits, collected over Expr and Stmt as `Checks` is.
  - `compiler/item_lowered.av`: `lowered_fn` → `LoweredFn`, which carries `missing`; "lowered whole" means nothing is missing.
  - Rules in `features/{expr_spine,bool_lit,str_lit,block,enums,fns,let_stmt,mutation,expr_stmt,loops}/lowers.av`: literals, names, `&&`/`||`, operators by operand layout, calls of declared and extern fns, blocks, a match on a bool, `let`, `mut`, assignment, `return`, `while`, `break`/`continue`.
  - The elseless arm of the `if_else` meaning (the other arm does nothing).
- **The receipt `avra tapes <pkg> --lowered`:** seats, answer and instructions, with registers renumbered in definition order, each register's layout held to the old TypeId's through an adapter that lives only in the receipt (cli tapes.av). It was witnessed failing on two planted bugs.

  | Package | Lowered whole | Held alike | Differing |
  |---|---|---|---|
  | std-text | 15 of 72 | 15 | 0 |
  | std-program | 48 of 556 | 48 | 0 |
  | cli | 55 of 734 | 55 | 0 |
- **Not lowered yet, counted by the first node each fn met:**
  - std-program: MethodCall 96, StructLit 67, Body 41, Prop 36, Comp 34, ListLit 30, annotated fns 30, LetElse 22, Call 21 (generic or non-plain callees), Match over enums 20, generic fns 12, lifts into nullables or `dyn` ~30.
  - cli: Body 196, MethodCall 113, Match 107, LetElse 40, Prop 38, `once` fns 23, MatchOpt 22, Comp 22, lifts into Result or nullables ~45.
- **Divergences cut and counted by the receipt,** both needing whole-program facts the new layer lacks:
  - the cancel test after a call whose callee may reach a cancel point. Cancel bits over an SCC, and the engine refuses cycles, so it needs a cancel survey on the new layer;
  - the scheduler's back-edge tick.
- **Expected but unseen:** the old registry boxes a record that a `mut` seat writes anywhere, while `Layout` reads flatness from the declaration alone.
- **Next, in this order:**
  1. The lifts at seats (nullable, `Result`, `dyn`; `SignedType.reaches` is the one judgment of them, so lower what it names).
  2. `MethodCall`, `Prop`, `StructLit`, `Match` over enums, `LetElse`/`MatchOpt`, comprehensions, `Body` (text and quote), generic fns by layout (units by layout signature).
  3. Then step 2 proper, the declared `lowering` component and `ir { }`, converting these hand-written rules.
  4. Then the interpreter and LLVM reading Layout, and program tests through the new path.

## The approved plan (owner, 2026-11-10: "Make all this happen")
- **A. The switch:**
  - (2) the `lowering` component plus `ir { }` (a quote of IR), so step 1's rules become declarations;
  - (3) every core form, and the interpreter and LLVM reading Layout;
  - (4) program tests through the new path, interpreter == native == `.expected`;
  - (5) generators (`@derive`/`@query`) on the new layer, which brings typing to 100%;
  - (6) the switch, deleting the old typer, lowering, TypeRegistry and method tables.
- **B. Targets:** a `target` component, a template per IR instruction, exhaustive. The interpreter (direct-threaded) and LLVM as declared targets; `target c` over the C runtime (`c { }` foreign bodies); copy-and-patch stencils compiled from the C templates as a millisecond dev backend; BURS multi-instruction patterns with costs; then wasm. LLVM stays the native path, and C is an extra target, never a detour.
- **C. The six ideas, in this order:**
  - (1) every meaning, lowering and target rule proven at its definition against a definitional interpreter, using the laws discharge ladder;
  - (4) live programs: a slot table, unit hot-swap, derived state migration;
  - (2) Futamura projections: partially evaluating the declared interpreter is compiling;
  - (3) a background proven superoptimiser shared through the content-addressed cache;
  - (5) fork-join and GPU from `Reach` purity, through LLVM;
  - (6) omniscient debugging, `avra why`.
- **Alongside:** slice 1's typed holes `${x: Type}`, `@example(before, after)` on any arms component, reading quote→quote rules backwards (resugaring), and one compiled matcher. Start the printer from the formatter's `render_source_of`, never a second printer.

The tower: surface --meaning--> core --lowering--> IR --target--> interpreter | LLVM | C | wasm | stencils. It's an hourglass: features are verticals (grammar, check, meaning, and a lowering only for core forms); targets are horizontals over the curated IR; `collect` gathers every declaration.

## Lessons — the hard-won ones
- **The owner's direction outranks a goal checklist or stop hook.** Last session spent ~8 hours on checklist items (runner suites, red teams of old tracks) instead of the lowering the owner asked for. If a hook re-lists items, keep the owner's priority and say so.
- **No infrastructure sinkholes.** Before infra work, say why it matters; stop after ~15 minutes of fighting tooling and report. Never run 15-minute or multi-GB jobs on the Mac.
- **Measure, never guess.** Three hypotheses last session were wrong: a "chain bug" was a seat's want, a "comprehension gap" was `index_of` answering `int`, a "Result bug" was auto-Ok. Read the output before explaining it.
- **A check that has never failed is untested.** Turn the mechanism off and watch the receipt catch it (hygiene was proven that way).
- **Verify an agent's claims** (grep, read the diff, rerun) before relaying them. Subagents don't read mid-run messages. Brief them fully: files, the bar, the verification commands, "do not commit".
- **The generation law.** A change the compiler's own source must READ needs ladder rungs:
  - commit with a `Rung: <why>` trailer, then `cp build/avra-try build/avra`, then the next change;
  - keep `cp build/avra build/avra.pre` before replacing;
  - a change to quote-pattern folding or shapes takes effect only in the SECOND generation, because the builder compiles the static shapes;
  - `make try` builds `build/avra-try` with the standing compiler; `make avra` replaces `build/avra`; the fixed point is `make avra` twice, compared with `cmp`.
- **Receipts are the oracle:**
  - `build/avra tapes <abs pkg dir>` (tapes);
  - `--signatures` (typing parity);
  - `--core` (meanings; a core may answer its seat's want if the surface type `reaches` it);
  - `--program-only` (timing; `AVRA_MEM_STATS=1` for heap, where the parent's stats print LAST);
  - `avra parsers <pkg>`;
  - soon `--lowered`.

  Edit timing: rsync std-avrac to /tmp, run cold and warm, then edit a string literal inside one fn body.
- **GitHub runners** (`sh tools/work run --for <min> "<cmd>"`):
  - Raise `AVRA_MEM_CEILING_MB=14000 AVRA_MEM_POOL_MB=14000` for std-avrac tests.
  - Run one file or directory at a time (the full suite as one binary doesn't fit 16 GB).
  - The compiler key excludes `**/tests/**`; `sources_hash` covers everything, so a seed "is the tree" only at its exact commit.
  - Receipt fixtures live under `packages/std-avrac/tests/fixtures/` (outside `src/`, so the suite never compiles them).
- **Shell and tool traps:**
  - zsh doesn't split unquoted variables, and BSD sed has no `\b` (use perl).
  - The multibyte `·` breaks grep and perl, so use python.
  - The formatter rewraps code, so re-read before anchored edits; python edit scripts assert each anchor's count.
  - Probes go in /tmp, never under an `avra.toml` (they examine nothing there).
  - `build/avra fmt --write <files>` before committing; the pre-commit hook says the command to run; never `--no-verify`.
- **Avra traps met:**
  - `then`, `when`, `given` and `trait` are keywords.
  - `match c { true -> …, false -> … }` is refused (write `_ ->`).
  - A `v? -> v` arm can't end in a comma on one line.
  - There is no `nothing()` in core.
  - `Cell.new({})` needs a typed `let`.
  - `x.word()` spells the applied type (read the head instead).
  - `is .Variant` over a registry enum is a catch-all in disguise.
- **House rules:**
  - No `rm` in commands (`find … -delete`, `mv`); no `git stash` (worktrees share it); never pkill by pattern.
  - Never remove worktrees; never clear a sibling worktree's `.avra-cache`. Your own worktree's day-old `.avra-cache/obj` may be cleared when the disk is full.
  - One heavy process at a time.
  - Language features are proposed to the owner first (now approved: `meaning`, `lowering`, `target`, `ir { }`, `c { }`, typed holes, `@example`, inversion, the matcher).
  - Replies short and scannable (the owner has ADHD): lead with the result, numbers in tables, one next action.
  - Commits end with the session's attribution trailers.

## Open, recorded in the plan
- Dropped-`match` → `void` lands at the switch (it costs one parity node now).
- Defects to pay: `fmt --write` isn't idempotent; the test private-name door doesn't resolve; frontier roots never expire; 6,000-deep nesting segfaults a shared pass; `parse_grammar_text` drops lex errors.
- Split the std-avrac suite to fit a runner before the switch.

Start: read the plan sections above, then `git -C ../avra-ho status` and the in-flight lowering diff. Finish slice 2 step 1 to its bar, then build step 2, the `lowering` component.
