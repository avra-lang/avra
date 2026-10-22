#!/usr/bin/env python3
"""THE TOOLS' OWN WITNESSES, DERIVED. Every instrument under tools/ that
proves itself on fixtures is run by some keeper, and no list names them by
hand: a hand list let witnesses and self-tests be written and run by nobody.

A tool is a WITNESS when it is `tools/witness_*.sh` or `tools/*_test.sh`
(run bare), or its source answers `--self-test` (run with it). One is
HELD ELSEWHERE when a Makefile recipe or another tool already runs it that
way — a keeper that pairs an instrument's self-test with its real run keeps
it. One that cannot run here (it needs a compiler, a cold build, a machine)
says so AT ITS SITE with `# tool-witnesses: by hand — <reason>`. Every
other witness is this keeper's to run.

    python3 tools/tool_witnesses.py list   # each witness and who runs it
    python3 tools/tool_witnesses.py run    # run the ones no one else does
    python3 tools/tool_witnesses.py --self-test
"""
import os
import re
import subprocess
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
BY_HAND = re.compile(r"^#\s*tool-witnesses:\s*by hand\s*—\s*\S", re.M)
SELF = "tool_witnesses.py"


def mode_of(name, text):
    """`bare`, `--self-test`, or None for a tool that proves nothing itself."""
    if name.startswith("witness_") or name.endswith("_test.sh"):
        return "bare"
    if "--self-test" in text:
        return "--self-test"
    return None


def code_lines(text):
    return [l for l in text.splitlines() if not l.lstrip().startswith("#")]


def runs(line, name, mode):
    """Whether one line of shell or a recipe runs `name` the way `mode` says."""
    n = re.escape(name)
    start = r"(?:^\s*[@-]*|[;&|{(!]|\$\(|\bthen|\bdo|\belse)\s*(?:\w+=\S*\s+)*(?:sh|bash|exec|python3)\b[^#;|&`\n]*"
    tail = r"""["']?\s+(?:[^;|&#`\n]*\s)?--self-test\b""" if mode == "--self-test" else r"\b"
    return re.search(start + r"\b" + n + tail, line) is not None


def witnesses(root):
    """[(name, mode, held_by)] — held_by is a Makefile target or tool, `by hand`,
    or None when this keeper owns the run."""
    tools = os.path.join(root, "tools")
    texts = {}
    for f in sorted(os.listdir(tools)):
        p = os.path.join(tools, f)
        if os.path.isfile(p) and f.endswith((".sh", ".py")):
            texts[f] = open(p, encoding="utf-8", errors="replace").read()
    recipes, target = [], None
    for line in open(os.path.join(root, "Makefile"), encoding="utf-8").read().splitlines():
        m = re.match(r"^([A-Za-z0-9_.-]+(?:\s+[A-Za-z0-9_.-]+)*)\s*:(?!=)", line)
        if m:
            target = m.group(1).split()[0]
        elif line.startswith("\t") and target != "tool-witnesses":
            recipes.append((target, line))
    modes = {n: mode_of(n, t) for n, t in texts.items() if n != SELF and mode_of(n, t)}
    held = {}
    for name, mode in modes.items():
        if BY_HAND.search(texts[name]):
            held[name] = "by hand"
        else:
            held[name] = next(("make " + t for t, l in recipes if runs(l, name, mode)), None)
    # A TOOL HOLDS A WITNESS ONLY WHEN THE TOOL ITSELF RUNS: two tools naming
    # each other hold nothing, so a cycle is broken by running it here.
    holders = {name: [o for o, ot in texts.items() if o != name
                      and any(runs(l, name, mode) for l in code_lines(ot))]
               for name, mode in modes.items() if held[name] is None}
    ran = {n for n, h in held.items() if h and h != "by hand"} | {n for n, hs in holders.items() if not hs}
    ran |= {o for hs in holders.values() for o in hs if o not in modes}
    moved = True
    while moved:
        moved = False
        for name, hs in holders.items():
            h = next((o for o in hs if o in ran), None)
            if h and held[name] is None:
                held[name], moved = h, True
                ran.add(name)
    return [(n, modes[n], held[n]) for n in sorted(modes)]


def run_all(root):
    fail = []
    owned = [(n, m) for n, m, h in witnesses(root) if h is None]
    for name, mode in owned:
        argv = (["python3"] if name.endswith(".py") else ["sh"]) + [os.path.join(root, "tools", name)]
        if mode == "--self-test":
            argv.append("--self-test")
        if subprocess.call(argv, cwd=root) != 0:
            fail.append(name)
    if fail:
        print("tool-witnesses: refused — %s" % " ".join("[%s]" % f for f in fail))
        return 1
    print("tool-witnesses: %d witness(es) run here, each proved on its fixtures" % len(owned))
    return 0


def self_test():
    import tempfile
    with tempfile.TemporaryDirectory() as d:
        os.mkdir(os.path.join(d, "tools"))

        def tool(name, body):
            open(os.path.join(d, "tools", name), "w").write(body)

        tool("a.sh", 'case "$1" in --self-test) echo ok ;; esac\n')
        tool("b.py", 'if "--self-test" in sys.argv: pass\n')
        tool("witness_c.sh", "exit 0\n")
        tool("d_test.sh", "exit 0\n")
        tool("e.sh", "# tool-witnesses: by hand — needs a compiler\n--self-test\n")
        tool("f.sh", "echo plain\n")
        tool("witness_g.sh", 'exec python3 "$(dirname "$0")/g.py" --self-test\n')
        tool("g.py", 'if "--self-test" in sys.argv: pass\n')
        tool("h.sh", "# a comment naming sh d_test.sh runs nothing\n--self-test\n")
        tool("i_test.sh", 'sh "$here/j_test.sh"\n')
        tool("j_test.sh", 'echo "run it as `sh tools/i_test.sh`"\nsh tools/i_test.sh\n')
        open(os.path.join(d, "Makefile"), "w").write(
            "keeper:\n\t@python3 tools/b.py --self-test\n"
            "other:\n\t@python3 tools/b.py\n"
            "tool-witnesses:\n\t@sh tools/a.sh --self-test\n")
        got = {n: (m, h) for n, m, h in witnesses(d)}
        want = {
            "a.sh": ("--self-test", None),           # this keeper's own recipe holds nothing
            "b.py": ("--self-test", "make keeper"),  # a run without --self-test does not count
            "witness_c.sh": ("bare", None),
            "d_test.sh": ("bare", None),             # a comment naming it is no run
            "e.sh": ("--self-test", "by hand"),
            "witness_g.sh": ("bare", None),
            "g.py": ("--self-test", "witness_g.sh"),
            "h.sh": ("--self-test", None),
        }
        # two tools that run each other hold nothing: both run here
        assert (got["i_test.sh"][1], got["j_test.sh"][1]) == (None, None), got
        assert "f.sh" not in got, got
        for n, w in want.items():
            assert got.get(n) == w, (n, got.get(n), w)
        tool("e.sh", "# tool-witnesses: by hand\n--self-test\n")
        assert dict((n, h) for n, _, h in witnesses(d))["e.sh"] is None, "a by-hand mark with no reason is no mark"
    print("tool_witnesses: self-test passed — 12 fixtures (both modes, held by recipe and by tool, "
          "by hand with a reason, comments and strings run nothing, a cycle runs here)")
    return 0


def main(argv):
    if argv == ["--self-test"]:
        return self_test()
    if argv == ["list"]:
        for name, mode, held in witnesses(ROOT):
            print("%-34s %-12s %s" % (name, mode, held or "tool-witnesses"))
        return 0
    if argv == ["run"]:
        return run_all(ROOT)
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
