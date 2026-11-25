# READ_SETS ruling (UI lead, 2026-11-25): APPROVED to build, with changes

The probe table made it rulable. Catching that today's answer is UNSOUND for a kept row in two shapes (a cell reached through a parameter answers `[]`) matters more than the widening.

## The six asks
1. **Rules 4, 5, 6 and 8: yes.**
   - Rule 5's "a language verb reads nothing of its own" is DATA, never a default. Each verb's fact is a row or column in the registry that already describes it: runtime rows for what bottoms out in C, and the walk-verb table for map, filter and the rest.
   - The facts: reads nothing / reads the cells of what it is handed / applies the lambda it is handed / unknown. A verb with no fact answers `?`.
   - Rule 8 as proposed: the union over the program's impls, the way ctx_reads reads a dyn call.
2. **Rule 9: Through(param) is marked, AND a kept instance observes those cells.** "Decline to keep" is not acceptable as the end state.
   - Make the walk STATIC: the parameter's TYPE says which paths hold a cell, so the compiler emits those paths and the stand observes exactly them, with no runtime walk.
   - A path through a list or a dyn of unknown length or type answers `Unknown`, in the same voice as rule 8's `?`.
   - Order: "not kept" for Through may land first if it gets rules 1–8 in sooner, with the static paths right after. Never land the `[]` answer.
3. **Rule 10: NOT a std-meta mark** (a claim nobody checks).
   - Where a method's body is Avra, rule 4 computes its set. The only LEAVES are runtime rows and externs, and their fact lives on the row (ask 1's registry column).
   - Fetch.value is Avra over a Cell, so it is computed. Cell.get's row says "reads its receiver's cell".
   - Bring any truly extern-backed case to the UI lead by name.
4. **Too wide:** a warning only under a windowed list, and only AFTER its true-positive rate is measured over std-ui and the board (report the count and how many are real). The refusing mark comes later. `avra explain` shows a component's set and the chain to its first `?`, and that lands WITH the query.
5. **A view's set stops at its children:** yes.
6. **@cut_query for both, and their own pass in the ledger:** yes.

## Five things the page must add BEFORE the kept instance is built
- **a. A fn-valued prop.** `on press {…}` is a fresh closure each paint. A fn value compares as the same code, with each capture the same by identity (one level, captures retained). Say how the compiler exposes "the same code" for two closures made at one site, and what a capture that is itself a closure does.
- **b. ctx.** An instance's set includes the contexts its body reads (ctx_reads). A kept instance compares those frame entries by the cached-fn rule. A ctx that can't compare by value makes the instance unkept, and the compiler says so.
- **c. A slot.** A parent building a child's `List<dyn View>` afresh gives the container a new prop each paint: the container re-describes, while its contents may still be kept. State this rule, and measure on the board how many instances are kept on (i) one toggled task and (ii) a window move, with the reasons the rest weren't.
- **d. Retention.** The standing retains every prop and capture it compares. Name what that costs when a retained prop is later written (a copy instead of an in-place write), with the board's worst case.
- **e. The check.** A mode that describes anyway and traps where a kept instance's nodes would have differed, run in the gate over std-ui's suites and the board for as long as this is new.

## Build order
1. The query's rules 1–8, with the registry facts and `explain`.
2. Then (a)–(e) as a second proposal section, for the UI lead to rule on.
3. Then the kept instance in std-ui. Lift the spike's `stands_on`, element reuse and the matcher's fast path; their commits are listed in avra-ios/docs/2026_11_25_IOS_BENCH.md.

Measured on the simulator with the stand-in: rows described per toggle 32 → 1, per window move 48 → 9.
