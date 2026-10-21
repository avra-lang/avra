#!/usr/bin/env python3
"""Scores the planner's closed decisions offline against their gold labels.

    python3 graph/planner/bench/bench.py [--resume results/bench-<time>.json]

Every decision in decisions.jsonl is put to the shared model service's
`choose` op exactly as the planner puts it (both option orders, averaged).
It reports accuracy per decision kind and per question (a question's walk is
right only when all its decisions are), with latency, and writes
results/bench-<time>.json beside the decisions it scored. A service cut
loses only the decision in flight: rerun with --resume to skip scored ones.
"""
import argparse
import collections
import datetime
import json
import pathlib
import subprocess
import sys
import time

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent.parent
sys.path.insert(0, str(HERE.parent))
from plan import SOCKET, Shared, shared_socket  # noqa: E402
from structured import debiased  # noqa: E402


def kind(question):
    """The decision's kind, read from its question's fixed wording."""
    for prefix, name in (("Who or what is the question about first", "anchor"),
                         ("Which kind of record is the person asking", "speaker model"),
                         ("Which kind of record holds the answer", "kind"),
                         ("Which relation does the question mean", "relation"),
                         ("Where next", "hop"),
                         ("Is the answer about this", "arrival"),
                         ("Which of these narrows", "narrowing"),
                         ("What does the question ask for", "mode"),
                         ("What does the question want to know", "recorded"),
                         ("Which recorded status", "status"),
                         ("Does the answer need their", "property")):
        if question.startswith(prefix):
            return name
    return "other"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--resume", help="a partial results file to continue")
    args = parser.parse_args()
    if not shared_socket():
        raise SystemExit(f"bench: no shared model answers on {SOCKET}")
    model = Shared(SOCKET)
    rows = [json.loads(l) for l in (HERE / "decisions.jsonl").read_text().splitlines() if l.strip()]
    header, decisions = rows[0], rows[1:]
    out = pathlib.Path(args.resume) if args.resume else \
        HERE / "results" / f"bench-{time.strftime('%Y%m%dT%H%M%S')}.json"
    done = json.loads(out.read_text())["scored"] if args.resume else []
    out.parent.mkdir(exist_ok=True)
    commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, text=True,
                            capture_output=True).stdout.strip()
    for d in decisions[len(done):]:
        started = time.time()
        p = debiased(model, d["context"], d["question"], d["options"])
        pick = max(range(len(p)), key=p.__getitem__)
        done.append({"question_id": d["question_id"], "kind": kind(d["question"]), "gold": d["gold"],
                     "pick": pick, "p_gold": p[d["gold"]], "ms": int((time.time() - started) * 1000)})
        out.write_text(json.dumps({"decisions": header, "commit": commit,
                                   "scored_at": datetime.datetime.now().isoformat(timespec="seconds"),
                                   "scored": done}, indent=1))
    by_kind, by_question = collections.defaultdict(list), collections.defaultdict(list)
    for s in done:
        by_kind[s["kind"]].append(s["pick"] == s["gold"])
        by_question[s["question_id"]].append(s["pick"] == s["gold"])
    print(f"{'kind':<14} right / total")
    for k, hits in sorted(by_kind.items()):
        print(f"{k:<14} {sum(hits)} / {len(hits)}")
    walks = {q: all(h) for q, h in by_question.items()}
    print("walks right:", sum(walks.values()), "/", len(walks), " ", " ".join(f"{q}{'+' if w else '-'}" for q, w in sorted(walks.items())))
    print(f"decisions right: {sum(s['pick'] == s['gold'] for s in done)} / {len(done)};"
          f" mean {sum(s['ms'] for s in done) / max(len(done), 1):.0f} ms per decision")
    print("results:", out.relative_to(ROOT))


if __name__ == "__main__":
    main()
