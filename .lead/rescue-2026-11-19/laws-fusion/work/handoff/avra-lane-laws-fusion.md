# avra-lane-laws-fusion — for batch 54

Range: batch53 (d5062c32)..avra-lane-laws-fusion (bad4862c).

Commits: 1a4ba48a small cuts; 629e7cb3 fold (law families on the ItemView, pinned while judged);
437ac954 share-merge-attack asserts "a share published and read" via AVRA_QTRACE store lines;
71df5b17 std-program names.av (Name = dense id, saved/folded as TEXT) + names_minted_first/last;
bad4862c merge of batch53.

Merge: one conflict, law_findings.av: kept both (pinned_while view + batch53's `unread: kept_unread(s.unread)`).

## Measured (cli cold findings, tree at batch53, 2 runs each)
- batch53 compiler: law_findings own 38.2/40.0 s, item_unknown_types 8.9/9.3 s, total split 123.5/127.7 s.
- merged: law_findings own 54.4/53.6 s (families folded in), total split 114.1/112.9 s (-12 s).
- findings cmp-identical to batch53's compiler.

## Names test
names_minted_first / names_minted_last mint the same names in opposite orders, each in its own process:
same saved hash, key and read-back; each also proves it minted in its own order. Both
"eval == native == expected" in the std-program suite.
Idiom rule for `id` in a hash: not greppable — a Name's `.id` reads like any other `.id` field. Name is
@sealed (no construction outside names.av); its derives fold its text.

## Gate on bad4862c
seed, idioms-avrac (base d5062c32), witness-b (20 rows), edit-a..g, refusal-a/b/c, avrac-a..g: PASS.
program: FAIL rt-ns only — features/rt.av vs runtime `avra_ctx_reframed` arity (3 args); rt.av and
runtime are byte-identical to batch53's, so batch53 carries it.
