"""A PER-TASK TIMELINE from a flow trace (`AVRA_FLOW_TRACE=<file>`).

    python3 tools/flow_trace.py <trace> [--task N]   the timelines
    python3 tools/flow_trace.py --self-test          its own cases

The runtime writes one line an event, `ts=<ns> <event> id=<task> …`
(runtime/avra_fiber.c, "The trace"). This groups them by task, in the
order they happened, each stamped in milliseconds from the trace's
first line. Task 0 is the program's own run. A line it cannot read is
counted and said, never dropped in silence.
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


def worded(event, rest):
    """One event in a reader's words."""
    if event == "spawn":
        return f"spawned by task {rest}"
    if event == "spawn-at":
        return f"spawned (evaluated) at site {rest}"
    if event == "park":
        src = re.match(r"src=(\S+) arm=(\S+)", rest)
        return f"waits on {src.group(1)} as {src.group(2)}" if src else f"waits {rest}"
    if event == "claim":
        by = re.match(r"by=(\S+) arm=(\S+)", rest)
        if not by:
            return f"claimed {rest}"
        who = f"task {by.group(1)}" if by.group(1).lstrip("-").isdigit() else f"the {by.group(1)}"
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


def timelines(events):
    """Each task's events in order: {task: [(ms, words)]}, tasks in order of first sight."""
    if not events:
        return {}
    origin = events[0][0]
    by_task = {}
    for ts, event, task, rest in events:
        by_task.setdefault(task, []).append(((ts - origin) / 1e6, worded(event, rest)))
    return by_task


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
    print(rendered(events, strays, only))
    print(f"flow_trace: read {len(events)} event(s) of {len(timelines(events))} task(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
