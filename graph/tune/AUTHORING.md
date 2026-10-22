# Brief for domain authors

You author synthetic training domains for a LoRA that teaches a small model to make closed choices (relation, modality, polarity, speaker, antecedent/ER, field values, planner hops) over ANY declared schema.

Work ONLY in graph/tune/corpus/ (new files; never edit other files, never commit, never use rm/rmdir/git clean or any delete word in Bash). First read: graph/tune/README.md (format + gold rules — follow exactly), graph/tune/corpus/vet_clinic.json (worked example), and skim graph/tune/extract_drive.py, graph/tune/plan_drive.py, graph/planner/structured.py.

Each domain (one file `<name>.json`, "domain" = name):
- 4–7 models invented for the domain, DIFFERENT in naming and structure from vet_clinic and each other: ≥2 entity models (referenced by others, first property the required name); ≥1 relation model with 2–4 closed labels incl. near-synonyms (forward/reverse words; vary the phrasing template: "{to} is {from}'s {label}", "{from} {label} {to}", "{to} serves as {label} for {from}" …); ≥1 record model with 2–3 reference fields to the same entity model whose roles are easily confused (requested_by/assignee/recipient-like, in the domain's own words: booked_by/coach/athlete, author/reviewer/approver …); a closed enum state; an optional boolean with an absence code; an integer quantity; an optional text field. Short, specific descriptions.
- 15–25 short realistic messages of varied form: `Name: …` chat turns, emails with sign-offs, notes, minutes, forwarded quotes with a named speaker, first-person lines. Include pronouns (he/she/they/him/her/their/I/me/my/we), denials, plans, requests, conditions, tentative drafts, reports ("X said that…"), two people sharing a first name, a full name then a short name later in the SAME message (antecedent/ER decisions incl. NEW and cannot-tell), quotes whose speaker is named or is the unnamed author. Distinctive invented names, diverse cultures. Never use: Rowan, Elena, Vale, Maison Aster, Odalys, Teodor, Wren, Pim, Greenholt, Sora, Ruth, June, Fig, Chen, Moreau, Khan, Cole, Torres, Stone, Brenner, Haldane, Castellanos, Okafor. No luxury fashion/retail, weddings, home workshop, garden or tool-lending content.
- Gold exactly per README rules (every mention and reference word listed; every stated field and only those; integers as digits; text values exact substrings of their sentence; both relation ends in the fact's sentence).
- ~15 questions with gold `cypher` in the planner dialect: speaker anchors ("my …", "I"), named anchors (question spells a stored whole name), every-record-of-a-kind with CONTAINS narrowing, relation-label hops, reverse words, reference hops both ways, counts, recorded-vs-world booleans (`coalesce(…, false)` for "is there a record of…", plain for "did/is…"), multi-property returns.

Loop per domain until clean, from graph/tune:
  python3 corpus.py <domain>                       # 0 problems
  python3 extract_drive.py <domain> > /dev/null    # stderr: decisions by kind
  python3 plan_drive.py <domain> > /dev/null       # stderr: walks, misses with the composed query
Fix misses by changing the question or gold to what is CORRECT and expressible — never bend gold toward a wrong answer. Aim ≥12 passing walks and ≥150 extraction decisions per domain, with antecedent, speaker, reference, relation, modality, polarity, field, stated all present. Read a sample of recorded decisions (stdout) to verify gold answers are right.

Final message: table domain | messages | extraction decisions by kind | walks passed/total, plus anything in the drivers that looked wrong (do not edit them).
