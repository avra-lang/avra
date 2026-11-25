# Lane brief — shared rules for every hd-* lane (2026-10-30)

You are a lane under the goal in `/Users/tristan/projects/tristanMatthias/avra/.lead/GOAL_2026_10_30.md`
(read it). The lead coordinates and merges; you code, build, test and commit on YOUR branch only.

## Read first
- `docs/2026_10_30_HARVEST.md` in your worktree: the summary, your lane's row, and the parts it cites.
- `docs/2026_10_30_HANDOFF_WARM_EDIT.md` §4 (build + measure loop, traps) and §10 (traps).
- CLAUDE.md (the whole thing; it is law): the idiom bar, the Rules, "How work lands".

## Where
- Your worktree is `/Users/tristan/projects/tristanMatthias/avra-hd-<lane>`, branch `hd-<lane>`, cut from
  `hd-clean`. Commit there and push your branch (`git push -u origin hd-<lane>`). Never touch another
  worktree, never commit to hd-clean or main, never open a PR. The lead merges your branch into hd-clean.
- Your worktree holds a Sprite. Heavy work (a compiler build, any suite, a package check) runs there:
  `sh tools/work run --for <minutes> '<cmd>'` from inside your worktree. The Mac runs only quick probes.
- Building the compiler: `sh tools/work run --for 20 'make try'` builds into `build/avra-try` with the
  standing compiler; `make avra` only when the compiler must read its own change (codegen, front end, a
  refusal about its own source), and then twice (the generation law). On the Mac before any `make avra`:
  `cp build/avra build/avra.pre`.

## Prior work first
Before writing anything: find the harvested commit(s) for it (`git show <sha>`, `git log --all -S'<symbol>'`),
port them (re-expressed onto hd-clean's seams — never a blind cherry-pick of a broken branch), and say in the
commit body what you ported from where. Write new code only where the harvest found none.

## Code
- CLAUDE.md's idiom bar before every fn. Derive what can be derived. One path: a new mechanism deletes the old
  one in the same commit. No string tags. Registries spell every arm. The empty case first.
- Terse, evergreen comments. No ticket numbers or dates in code.
- `./build/avra fmt --write <changed .av files>` before every commit (the pre-commit hook refuses otherwise;
  never `--no-verify`). Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Loops and measurement
- Every command bounded: a probe ≤ 10 s, a build/targeted test ≤ ~2–20 min on the Sprite with `--for`.
  No `sleep`, no polling loops. Never put a delete word (r m) in a Bash command — a hook refuses it; use
  `find <dir> -mindepth 1 -delete` to clear a directory.
- Clear `.avra-cache` before any A/B you report. Quote the output and the commit sha for every number.
- The comment-edit benchmark: `/tmp/ed2.py` toggles a comment in `packages/cli/src/commands/shared.av` of
  the hd-int worktree — copy it and point it at YOUR worktree; restore the file after (git status clean).
- Never stop at a failure: diagnose with `AVRA_QTRACE=1`, `--time`, the defect's frame stack; fix the
  cause centrally. If truly blocked, report the blocker with evidence.

## Report (final message, ≤ 250 words, ADHD-friendly)
Result + numbers first; commits pushed (sha + one line each); tests run and their counts; what remains;
any branch you harvested that can now close (with the commit that absorbed it).

## The `by` rung (from hd-clean 3bfddb18 on)
hd-clean's grammar uses `-> Node by fn`, which the Sprite's `--builder` compiler cannot read, so `make try`/`make avra`
on a tree with hd-clean ≥ 3bfddb18 fails ("does not export `block`", "the grammar does not parse").
Once per Sprite, build a `by`-reading compiler from hd-nodes' door commit A (8f261131, which uses no `by` itself).
A big untracked tar does NOT sync; a small diff does:
1. On the Mac, in your worktree: `git diff 8f261131 -- packages runtime Makefile tools bootstrap > rungA.diff` (~400 KB, untracked, syncs).
2. `sh tools/work run --builder --for 30 'export AVRA_CAP_MB=10000; d=$HOME/rungA; mkdir -p $d && tar cf - --exclude=./build --exclude=./.avra-cache . | (cd $d && tar xf -) && cd $d && patch -R -p1 -s < rungA.diff && mkdir -p build && cp $OLDPWD/build/avra build/ && make avra >/tmp/rung.log 2>&1; s=$?; tail -3 /tmp/rung.log; [ $s = 0 ] && cp build/avra $OLDPWD/build/avra.reads-by && echo RUNG-OK || echo RUNG-FAIL'`
   Read the status, never a piped `tail`'s.
3. Then ONE more generation from your own tree (commit A predates fixes like caa0c320, and a builder that old fills the store with defect-2 rows): `sh tools/work run --builder --for 30 'export AVRA_CAP_MB=7600; cp build/avra.reads-by build/avra && make avra && cp build/avra build/avra.reads-by && cp build/avra build/avra.builder'`. From hd-deleted 8608be83 on, `--builder` uses build/avra.builder and names it in the route line; until your tree has that commit, start each command with `cp build/avra.reads-by build/avra;`.
On the Mac, the fmt hook needs a `by`-reading build/avra too: one `make try` from the merged tree, then `cp build/avra-try build/avra`.

## Ending a Sprite run
Stopping your local task (or Ctrl-C) does NOT end the run on the Sprite. It keeps the Sprite busy, and your next
`work run` waits silently. End a run with `sh tools/work stop`. If a run seems to take far longer than its bound,
check `sh tools/work status` before waiting more.
