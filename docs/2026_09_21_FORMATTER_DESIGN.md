# The formatter — one rule engine: layout, idiom, lint

Design, 2026-09-21. Not built. Written after the build-cache campaign, which is
what makes it affordable.

**In one line:** the formatter is a rule engine INSIDE the compiler. A rule is
a declaration in ordinary Avra, living beside its feature's grammar; the compiler proves a
rewrite safe by lowering it; spans make every edit lossless; the store makes it
a query. A model that has never seen Avra writes any reasonable dialect, and
the toolchain emits one.

## 1. Why now, and what is wrong today

| today | the problem |
|---|---|
| `avra fmt`: a 680-line hand-written printer (`compiler/format/source_text.av`) | no `--write`: it drops trailing `//` comments; every new feature owes it an arm |
| it parses and does not analyse | typing one file once cost 2.5 minutes — so it cannot know a type |
| idioms: `tools/idioms.py`, ~1,000 lines of Python regex | 29 of 50 numbered idioms have a matcher; ~45 documented forms have no number; `debt 0` answers only for the 29 |
| sweeps: throwaway scripts | the `it` sweep ate a parenthesis at every site on its first run |

Measured tree-wide on the day this was written, unseen by any keeper: ~545
`if x == null { return } … x!`, 63 literal copies that are `with`, 49
null-ternaries that are `??`, 61 lambdas that were `it`.

**What changed:** with the store, analysing ONE edited file with everything else
held costs ~100 ms. The formatter can afford to know types, purity, nullability,
whether a `match` is a registry, and what the memory pass knows. A regex knows
none of it.

## 2. A rule is a declaration, written in Avra

No rule sublanguage, and no limit from what the language has today — §2a lists
what it gains. The perfect rule:

```avra
// features/nullable/idioms.av

/// A null test that picks the value or a default is `??`.
@fixes("if n != null { n! } else { 0 }", "n ?? 0")
@keeps("if next() != null { next()! } else { 0 }")
rule default {
    quote { if ${x} != null { ${x}! } else { ${d} } } if x.pure -> quote { ${x} ?? ${d} }
}
```

That is the whole rule: no registration, no number, no matcher, no test file.

- **`rule` is a declaration**, as `spec` is. Its body is ordinary `match` arms
  over the code in hand; a miss answers nothing. It reads as — and `avra explain`
  shows it as — `fn default(e: Code) -> Fix? { match e { …, _ -> null } }`. One
  grammar, one expression language.
- **A `quote` in PATTERN position binds its holes.** The precedent is in the
  tree: a STRING in pattern position already parses and binds (`match b {
  "{x}|{y}" -> … }`, features/formats). A literal that BUILDS as an expression
  MATCHES as a pattern:

  | | expression position | pattern position |
  |---|---|---|
  | `"{a} {b}"` | interpolates | scans, binds `a` `b` |
  | `quote { ${x} ?? ${d} }` | splices `x` `d` | matches nodes, binds `x` `d` |

  A hole's KIND comes from its seat (an expression, a name, a type); `${..body}`
  is a RUN; a hole named twice must match the SAME code, by fingerprint; layout
  and parentheses never matter — the match is over nodes.
- **The code in hand is ANALYSED** (P10). A bound hole answers what the compiler
  knows, as properties — no context parameter: `x.pure`, `x.type`, `x.binding`,
  `e.type.is_registry`, `xs.shared_here` (the memory pass's word), `f.callers`.
- **An arm takes a guard** — `pattern if cond -> value` — in every `match`.
- **A feature's rules are the `rule`s in its directory.** Never listed by hand,
  as keywords are never listed. Identity is `<feature>.<rule>` —
  `nullable.default`; its diagnostic code is a row in the feature's `diags`. A
  package's rules are the `rule`s it exports.
- **`///` is the teaching sentence**, `@fixes`/`@keeps` are the tests AND the
  `explain` page's before/after. A rule with no `@fixes`, a `@fixes` that does
  not produce its after, or a `@keeps` that fires, is an ASSEMBLY DEFECT.

The same form at every scale:

```avra
/// A match that answers a bool about one variant is `is` — for a projection.
rule asks {
    quote { match ${e} { .${v} -> true, _ -> false } } if !e.type.is_registry -> quote { ${e} is .${v} }
}

/// A write that finds its box shared copies it — every turn, in a loop.
rule copied_in_loop {
    quote { ${xs}.push(${v}) } if xs.shared_here && xs.in_loop -> copies_every_turn(xs)
}

/// A free fn taking the state first is a method.
rule free_verb {
    quote { fn ${f}(${s}: ${S}, ${..ps}) -> ${R} { ${..body} } } if S.is_state_in(f.module) -> f.moved_onto(S)
}
```

An arm answers a `Fix`: a quote (a rewrite — a quote under a `Fix` want widens,
as auto-Ok does), a named VOICE (a finding with no rewrite), or a refactor verb
(`moved_onto`: the declaration AND every call site, one transaction).

**The tier falls out of the arm**, never out of a label:

| the arm answers | it is | `avra fix` |
|---|---|---|
| a rewrite the compiler can prove equivalent | a FORMAT | applies it |
| a rewrite it cannot prove | a SUGGESTION | shows it, never applies it |
| a voice | a LINT | reports it |

From the one declaration the toolchain DERIVES: the matcher and its root-kind
index (read from the rule's own patterns), the fix, the diagnostic and its
`explain` page, the DOGFOODING registry, the tests, and a before/after pair for
teaching a model. One source of truth, many projections (P12).

### 2a. What the language gains

Must, in build order:

1. **Arm guards** — `p if c -> v`. General; the tree wants it today.
2. **`quote` as a pattern** — binding holes, run holes, same-name-same-code.
3. **Analysed `Code`** — a hole's facts as properties, answered from the store.
4. **`rule`** — the declaration, `Fix`, `@fixes`/`@keeps`, rules-by-directory.
5. **`@foreign` in the grammar DSL** — accept wide IN THE PARSER (below).

Later: `///` kept as data (the docs campaign wants it too) · `or` arms that bind
the same names on every side (F2039 lifted) · comments as a trivia side table
keyed by node, so a rewrite carries them · layout marks in the grammar DSL (§4).

**Accept wide is a grammar mark, not a rule.** A refused spelling does not
parse, so no quote can match it. The grammar takes the foreign token and says
what it should have been:

```
arm     = p:pattern ( ( "or" | "|" @foreign("or") ) p:pattern )* "->" v:expression
boolean = l:expr ( "&&" | "and" @foreign("&&") ) r:expr
```

The parser builds the SAME node, records a fix at the token's span, and `check`
reports it with the fix attached; `fix` splices it. Every help string that names
a spelling (`|` is `or`, `m["k"]` is `.get`, a `;`, a leading `&&`) becomes a
mark the toolchain compiled — CLAUDE.md's "a help is a claim about the grammar
that nothing checks" closes mechanically. A model writes the habit every other
language taught it, and the tree only ever holds Avra.

## 3. Safe by proof, not by care

The compiler has an IR with fingerprints and two engines. Per site:

| tier | what proves the rewrite | when |
|---|---|---|
| **proved** | the declaration lowers to the SAME IR fingerprint before and after | every application |
| **tested** | the IR differs (a flag loop → `xs.any(…)`), but the rule's `@fixes` examples agree on both engines | at assembly |
| **suggested** | neither | never applied |

A formatter that checks IR equality before it writes cannot change behaviour.
The three-part hand rule for `with` (same type, every field listed, each copy
exact) becomes a check the machine runs. The store makes it cheap: lowering one
body is milliseconds and keyed.

## 4. Lossless by construction

Every node's span is already in a side table, so the first version needs no
full-fidelity tree:

- **An edit is a span splice.** Replace one node's span with the rendered new
  node. Every byte outside it is untouched — layout, comments, blank lines.
- **The receipt is built in.** Lex the input and the output; any token that moved
  outside a declared rewrite refuses the write. Losslessness stops depending on
  a suite someone remembers to run (`fmt(fmt(x)) == fmt(x)` was green while
  every comment was being deleted).
- **A comment inside a replaced span** moves to the statement, or the fix is
  refused. A region with a parse hole keeps its bytes.
- **Diffs are minimal**, which is what an agent's loop and a neighbour's merge
  both want.

Whole-file canonical layout comes after, and in the perfect version the printer
is DERIVED from the grammar DSL — the rule already states its own shape, and a
comma list that takes a trailing comma is a "break all or none" group. A feature
contributes syntax once and gets its parser and its printer; `parse(print(n)) ==
n` is checked for every rule at assembly. The hand-written printer goes.

## 5. It is a query

- `formatted(file)` is keyed like every other row: the file's text, the
  interfaces it sees, and a print of the RULESET.
- Nothing moved: a kept verdict — the cost of a no-op `check` (~30 ms).
- An edit: rules run only over declarations whose fingerprint moved.
- Findings ride the `Said` rows a file already keeps, so a held file's findings
  survive the hold.
- Rules are indexed by ROOT NODE KIND, as the grammar skips a branch by its first
  token: the cost is nodes touched, never nodes × rules.

## 6. Accept wide, emit narrow

P1 asks for "correct on first generation". For a model with no Avra in its
training that is unreachable; **correct after one deterministic normalisation**
is not.

- `avra fix` applies every proved and tested rewrite. `--dry`, `--only <rule>`,
  `--since <ref>` (only declarations that moved).
- `avra fix --json` answers, per application: the rule, before, after, ONE
  teaching sentence, and the `explain` link. The agent learns the idiom from its
  own diff.
- `avra check` already reports the same findings, with the fix attached.
- `// LICENSED <rule>: reason` stays the escape hatch (P8) — read from the tree,
  never grepped.

## 7. What only a compiler can do

- **"this write copies `xs` every turn"** — the memory pass knows when a load
  pins a box a later write opens. As a rule, it would have found the 33% map
  clone statically.
- **"a free fn taking the state first is a method"** — a rewrite ACROSS files.
  The engine knows every call site; it applies the move as one transaction and
  re-checks, or applies nothing.
- unused imports, dead parameters, a registry `_ ->`, a `match` that answers a
  bool — today regexes or one-off laws, here rows.

Rules therefore declare a SCOPE: expression, statement, declaration, module,
program.

## 8. What goes

`tools/idioms.py`, its baseline and its specimen tables · the hand-kept registry
in DOGFOODING.md (generated) · throwaway sweep scripts · help strings nothing
compiles · in time, the hand-written printer.

## 9. The hard parts

- **Run holes.** `${..before} let ${x} = ${e} ${..after}` needs ONE anchored pass
  with no backtracking, as the format scan has; two adjacent runs are refused.
- **Analysed `Code` has a price.** A fact read by a rule is a query dependency,
  so a rule's verdict is keyed by exactly the facts it read — which is what
  keeps a whole-program fact (`f.callers`) from re-running every rule.
- **Rule interaction.** Rewrites must terminate and not fight. The engine runs to
  a fixpoint per declaration and, when a fingerprint repeats, names both rules
  as a defect.
- **How much "proved" covers.** Probably half the rules. The rest need the
  tested tier, so a rule's `@fixes` examples carry real weight.
- **Rules from packages** run at compile time with the evaluator's budget; a
  dependency's rules may suggest, and whether they may FIX is the owner's call.

## 10. Order

1. The ~30 existing matchers as typed AST rules in the compiler, span-splice
   fixes, `avra fix`; the regex tool deleted. About a week of slices.
2. Arm guards, `quote` patterns, analysed `Code`, `rule` (§2a, 1–4); the phase-1
   matchers rewritten as `rule`s; explain, registry and tests derived; the
   IR-equality gate.
3. Findings keyed in the store; `--json`.
4. Layout derived from the grammar; canonical whole-file format; `--write`.
5. `@foreign` grammar marks, replacing the help strings; program-scope
   refactors.

## Open

- Which facts does a hole answer first? (Start: type, nullability, purity,
  registry-or-projection, binding.)
- May a dependency's rule FIX, or only suggest?
- Does `fix` run inside `build`, or only on request? (Proposed: never inside
  `build`; `check` reports, `fix` writes.)
