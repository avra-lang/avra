"""A PER-TASK TIMELINE from a flow trace (`AVRA_FLOW_TRACE=<file>`).

    python3 tools/flow_trace.py <trace> [--task N]   the timelines
    python3 tools/flow_trace.py <trace> --shape      what both engines say alike
    python3 tools/flow_trace.py --self-test          its own cases

The runtime writes one line an event, `ts=<ns> <event> id=<task> …`
(runtime/avra_fiber.c, "The trace"). This groups them by task, in the
order they happened, each stamped in milliseconds from the trace's
first line. Task 0 is the program's own run. A line it cannot read is
counted and said, never dropped in silence.

A JOIN IS ONE LINE: a compiled join also files a wait on its task's
gate, an evaluated one files nothing, so the wait a join files is read
as part of it.

A SPAWN SAYS WHERE: the `site` line that follows a spawn is read into
it — a source line, or the code's address where the code carries none.

THE SHAPE is each task's events in order with nothing an engine owns:
no stamp, no address, no descriptor's number, and no spawn of the
program's own run. A site that is a source line is both engines'. A program run evaluated and compiled prints the
same shape wherever the two agree by design.
"""
import re
import sys

LINE = re.compile(r"^ts=(-?\d+) ([a-z-]+) id=(-?\d+) ?(.*)$")


def parsed(text):
    """Every event as (ts, event, task, rest), and the lines that were none."""
    events, strays = [], []
    for raw in text.splitlines():
        m = LINE.match(raw)
        if m:
            events.append((int(m.group(1)), m.group(2), int(m.group(3)), m.group(4)))
        elif raw.strip():
            strays.append(raw)
    return events, strays


def is_line(site):
    """Whether a site is a source line, not a bare address."""
    return site is not None and not site.startswith("0x")


def worded(event, rest, site=None):
    """One event in a reader's words."""
    where = f" at {site}" if site else ""
    if event == "spawn":
        return f"spawned by task {rest}{where}"
    if event == "spawn-at":
        return f"spawned (evaluated){where}" if site else f"spawned (evaluated) at site {rest}"
    if event == "join":
        on = rest.removeprefix("on=")
        return "joins a task nothing runs" if on == "unrun" else f"joins task {on}"
    if event == "park":
        src = re.match(r"src=(\S+) arm=(\S+)", rest)
        return f"waits on {src.group(1)} as {src.group(2)}" if src else f"waits {rest}"
    if event == "claim":
        by = re.match(r"by=(\S+) arm=(\S+)", rest)
        if not by:
            return f"claimed {rest}"
        hand = "a task nothing runs" if by.group(1) == "unrun" else f"the {by.group(1)}"
        who = f"task {by.group(1)}" if by.group(1).lstrip("-").isdigit() else hand
        return f"woken by {who} on {by.group(2)}"
    if event == "retract":
        return f"takes back {rest} wait(s) that lost"
    if event == "deadline-set":
        return f"deadline filed for {rest} ns"
    if event == "deadline-fired":
        return "its deadline came"
    if event == "cancel":
        return f"cancelled by task {rest}"
    if event == "end":
        return "ends"
    return f"{event} {rest}".strip()


def sites(events):
    """Where each task was spawned: {task: text}."""
    return {task: rest for _, event, task, rest in events if event == "site"}


def folded(events):
    """The events a reader is told: no site line — its spawn says it — and
    no gate wait a join files: the join said it."""
    out, last = [], {}
    for e in events:
        _, event, task, rest = e
        if event == "site":
            continue
        joins_gate = event == "park" and rest.startswith("src=gate:") and last.get(task) == "join"
        last[task] = event
        if not joins_gate:
            out.append(e)
    return out


def timelines(events):
    """Each task's events in order: {task: [(ms, words)]}, tasks in order of first sight."""
    if not events:
        return {}
    origin = events[0][0]
    by_task, at = {}, sites(events)
    for ts, event, task, rest in folded(events):
        by_task.setdefault(task, []).append(((ts - origin) / 1e6, worded(event, rest, at.get(task))))
    return by_task


def shape_worded(event, rest, site=None):
    """One event with what an engine owns left out."""
    if event in ("spawn", "spawn-at"):
        return f"spawned at {site}" if is_line(site) else "spawned"
    if event == "deadline-set":
        return "deadline filed"
    if event == "park":
        src = re.match(r"src=(gate|fd:[rw]|at)\S* arm=(\S+)", rest)
        if src:
            return f"waits on {src.group(1)} as {src.group(2)}"
    return worded(event, rest)


def shape(events):
    """Each task's events in order, by id: the text both engines print alike."""
    by_task, at = {}, sites(events)
    for _, event, task, rest in folded(events):
        if task == 0 and event == "spawn-at":
            continue
        by_task.setdefault(task, []).append(shape_worded(event, rest, at.get(task)))
    out = []
    for task in sorted(by_task):
        out.append("the program's own run" if task == 0 else f"task {task}")
        out.extend(f"  {words}" for words in by_task[task])
    return "\n".join(out)


def rendered(events, strays, only=None):
    out = []
    for task, rows in timelines(events).items():
        if only is not None and task != only:
            continue
        waits = sum(1 for _, w in rows if w.startswith("waits"))
        span = rows[-1][0] - rows[0][0]
        name = "the program's own run" if task == 0 else f"task {task}"
        out.append(f"{name} — {len(rows)} event(s), {waits} wait(s), {span:.3f} ms from first to last")
        out.extend(f"  +{ms:10.3f} ms  {words}" for ms, words in rows)
    if strays:
        out.append(f"{len(strays)} line(s) were no event; the first: {strays[0][:80]}")
    return "\n".join(out)


COMPILED = (
    "ts=10 spawn id=1 0\n"
    "ts=20 join id=0 on=1\n"
    "ts=30 park id=0 src=gate:0x7f00 arm=0:0\n"
    "ts=40 park id=1 src=at arm=0:0\n"
    "ts=50 claim id=1 by=timer arm=0:0\n"
    "ts=60 claim id=0 by=1 arm=0:0\n"
    "ts=70 end id=1 0\n"
)
EVALUATED = (
    "ts=5 spawn-at id=0 0\n"
    "ts=10 spawn-at id=1 17\n"
    "ts=20 join id=0 on=1\n"
    "ts=40 park id=1 src=at arm=0:0\n"
    "ts=50 claim id=1 by=timer arm=0:0\n"
    "ts=60 claim id=0 by=1 arm=0:0\n"
    "ts=70 end id=1 0\n"
)
SITED = (
    "ts=1 spawn id=1 0\n"
    "ts=2 site id=1 pkg/main.av:8\n"
    "ts=3 spawn id=2 0\n"
    "ts=4 site id=2 0x55d0\n"
    "ts=5 spawn-at id=3 4\n"
    "ts=6 site id=3 pkg/main.av:8\n"
)
SHAPE = (
    "the program's own run\n"
    "  joins task 1\n"
    "  woken by task 1 on 0:0\n"
    "task 1\n"
    "  spawned\n"
    "  waits on at as 0:0\n"
    "  woken by the timer on 0:0\n"
    "  ends"
)


def self_test():
    text = (
        "ts=1000000 spawn id=1 0\n"
        "ts=1500000 park id=1 src=gate:0x55 arm=0:5\n"
        "ts=1600000 park id=1 src=at arm=1:0\n"
        "ts=3500000 claim id=1 by=0 arm=0:5\n"
        "ts=3600000 retract id=1 1\n"
        "ts=3700000 claim id=2 by=timer arm=1:0\n"
        "ts=3900000 end id=1 0\n"
        "flow trace: capped\n"
    )
    events, strays = parsed(text)
    lines = rendered(events, strays).splitlines()
    cases = [
        ("every event line is read", len(events) == 7),
        ("a line that is no event is counted", len(strays) == 1 and "1 line(s) were no event" in lines[-1]),
        ("tasks keep the order of first sight", [k for k in timelines(events)] == [1, 2]),
        ("a task's head counts its events and waits", lines[0] == "task 1 — 6 event(s), 2 wait(s), 2.900 ms from first to last"),
        ("a stamp is milliseconds from the first line", lines[2].strip() == "+     0.500 ms  waits on gate:0x55 as 0:5"),
        ("a task claimant is named as a task", "woken by task 0 on 0:5" in lines[4]),
        ("a scheduler's hand is named as itself", any("woken by the timer on 1:0" in l for l in lines)),
        ("one task alone can be asked for", rendered(events, [], only=2).splitlines()[0].startswith("task 2 — 1 event(s)")),
        ("an empty trace renders nothing", rendered(*parsed("")) == ""),
        ("a join names its task", worded("join", "on=2") == "joins task 2"),
        ("a join of a task nothing runs says so", worded("join", "on=unrun") == "joins a task nothing runs"),
        ("a waking by a task nothing runs says so", worded("claim", "by=unrun arm=0:0") == "woken by a task nothing runs on 0:0"),
        ("the wait a join files is the join's", shape(parsed(COMPILED)[0]) == SHAPE),
        ("a gate wait that follows no join stays", "waits on gate as 0:5" in shape(parsed(text)[0])),
        ("both engines' traces have one shape", shape(parsed(EVALUATED)[0]) == shape(parsed(COMPILED)[0])),
        ("a spawn says its source line", "spawned by task 0 at pkg/main.av:8" in rendered(*parsed(SITED))),
        ("a spawn with no line says its code's address", "spawned by task 0 at 0x55d0" in rendered(*parsed(SITED))),
        ("an evaluated spawn says its source line", "spawned (evaluated) at pkg/main.av:8" in rendered(*parsed(SITED))),
        ("a site line is no event of its own", sum("site" in l and "spawned" not in l for l in rendered(*parsed(SITED)).splitlines()) == 0),
        ("the shape keeps a source line and drops an address", shape(parsed(SITED)[0]) == "task 1\n  spawned at pkg/main.av:8\ntask 2\n  spawned\ntask 3\n  spawned at pkg/main.av:8"),
        ("the timeline folds the join's wait too", sum("gate" in l for l in rendered(*parsed(COMPILED)).splitlines()) == 0),
    ]
    failed = [name for name, ok in cases if not ok]
    for name in failed:
        print(f"flow_trace: FAILED {name}")
    print(f"flow_trace: {len(cases)} cases, {len(failed)} failed")
    return 1 if failed else 0


def main(argv):
    if argv[1:] == ["--self-test"]:
        return self_test()
    if len(argv) < 2:
        print(__doc__)
        return 1
    only = int(argv[argv.index("--task") + 1]) if "--task" in argv else None
    events, strays = parsed(open(argv[1]).read())
    if "--shape" in argv:
        print(shape(events))
        if strays:
            print(f"flow_trace: {len(strays)} line(s) were no event; the first: {strays[0][:80]}", file=sys.stderr)
        return 1 if strays else 0
    print(rendered(events, strays, only))
    print(f"flow_trace: read {len(events)} event(s) of {len(timelines(events))} task(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
