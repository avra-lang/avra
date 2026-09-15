---
name: feedback
description: A structured survey for agents to collect EVERYTHING a work session ran into — friction, sugar asks, feature ideas, defects, doctrine gaps, performance, process — and record it in ROADMAP.md to feed the backlog. Run at the end of a session or lane, or when asked for feedback, a retro, or "what sucked". Use when asked for feedback, a survey, a retro, or "what sucked".
---

# The feedback survey

Agents are the language's first users. Every place one reached for
something that was not there is a requirement; every wall that cost an
hour is a defect in the tool, not in the agent. This pass collects
those systematically, so the roadmap is fed by evidence rather than by
whoever happened to complain loudest.

It is a SURVEY, not a review: the review round asks "is this
beautiful?", the red team asks "how does this break?", and this asks
**"what did the work want that the tree does not have?"** — in every
direction at once.

## Posture

- **Honest recall, never invention.** A finding without evidence — a
  command and its output, a `file:line` wanting site, a probe — is a
  question, not a finding. Say "unverified" when it is one.
- **Comprehensive over tidy.** More is better. Do not self-censor a
  finding because it seems small, obvious, or someone else's problem.
- **Friction is FINDING, not complaint.** "This cost two hours" is
  data about the tool, the doctrine, or the docs.
- **Attribute.** Name the tree/commit and the date. A probe result
  names the base that answered it; a count names the scope counted.
- **Dedupe, do not duplicate.** The ledgers already hold a lot. A
  confirmation is worth a line; a re-file is noise.

## The axes — sweep every one

1. **FRICTION — what cost time.** The build loop; the debug cycle; an
   error that pointed somewhere else; a workaround; a tool that did
   not exist; a step done by hand that should be automatic; a probe
   that needed a package built around it.
2. **SUGAR — a construct the language should have.** From DOGFOODING (a
   shape the compiler's own code wanted) or a wanting site. Name the
   site, quote the ugly-but-safe draft it replaced.
3. **FEATURES — a capability, larger than sugar.** Language, the
   toolchain (`explain`, `expand`, a REPL, the LSP, the inspector),
   the runtime, a keeper, a new command.
4. **DEFECTS — the compiler blaming itself.** `defect:`, `avra_trap`,
   a crash, a wrong answer, an engine divergence. Each with a
   reproduction and the exact words.
5. **DOCTRINE — a law missing, misleading, or stale.** A doc that
   disagreed with the code; a keeper that examined nothing; a rule
   that sent the reader at a form the parser refuses.
6. **PERFORMANCE — a measured cost.** Time, memory, allocations — with
   the instrument NAMED (`census`, `watch`, `AVRA_MEM_STATS`) and the
   scope. Never a guess.
7. **PROCESS — the working discipline itself.** What to keep (the
   watchdog, the census, probe-first); what to change (the build
   protocol, recovery, the gate, the ledgers).

## The sweep method (deterministic)

1. **Walk the arc.** Chronologically: every commit, every detour,
   every time the work stalled. At each moment ask — what did I reach
   for that was not there? What did I do by hand? Where did the clock
   go?
2. **Probe or cite.** Re-run the refusal; grep the wanting site; quote
   the error verbatim. A row without evidence does not ship.
3. **Dedupe** against CLAUDE.md ("The subset today"), DOGFOODING.md
   (the idiom registry), ROADMAP.md (the sugar backlog, the recorded
   triggers, the ledgers). If it is already filed, confirm it in a
   line — never re-file.
4. **Classify by what it IS**, not by where it was found. One finding,
   one axis; a finding that spans two becomes two rows that link.
5. **Quantify.** Count per axis; name the top three by cost. A number
   that carries the argument is worth having; one that pads it is not.
6. **No silent caps.** Say what was NOT surveyed — a package, a time
   window, a lane you did not open. A bounded survey that says so
   beats one that reads as total.

## The entry format

Each finding is a ledger row under its axis:

- **A NAME in caps** — the ask, not the symptom. ("A TRAP NAMES ITS
  SITE", not "bad error messages".)
- **WHAT HAPPENED** — concretely, with the cost in attempts or
  minutes.
- **EVIDENCE** — the command and its output, the wanting site
  `file:line`, or the probe and its base.
- **THE ASK** — what the language or tool should do. Concrete enough
  to schedule.
- **ATTRIBUTION** — tree/commit and date.

## Where it lands

ROADMAP.md, as a new section:

    ## Feedback survey — <date> (<lane>)

with one subsection per axis; a row per finding. **The survey is the
breadth; the backlogs are the routing.** A finding that belongs in a
specific ledger ALSO lands there, linked both ways:

- A sugar the compiler's own source wanted -> the **sugar backlog**,
  with its wanting site.
- A deferred capability -> a **recorded trigger** with its firing
  condition.
- A doctrine settlement -> the relevant section, dated, with the
  reasoning.
- An idiom -> DOGFOODING.md's registry.
- A subset refusal -> CLAUDE.md's "The subset today".

A finding that lives ONLY in the survey is a finding that gets lost
when the survey scrolls away. File it home, and cite the survey row.

## Verify

Docs-only, so `make gate` is unaffected — confirm the tree still
builds. If CLAUDE.md was touched, run its duplicate-prose check
(`grep -n "^- [A-Z]" CLAUDE.md | sed 's/^[0-9]*://' | sort | uniq -d`
must answer nothing). Re-read the section: every row has evidence, and
no row duplicates another.

## Report

- Lead with the **count per axis** and the **top three by cost**.
- Name every axis that came back EMPTY — a swept-and-clean axis is a
  real result.
- Say what was NOT surveyed.
- Offer the commit; nothing commits without the user's word.
