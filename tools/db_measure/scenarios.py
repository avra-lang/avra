#!/usr/bin/env python3
"""THE SCENARIO TABLE, MEASURED. From a tree's root, over its own build/avra:

    python3 tools/db_measure/scenarios.py [--rounds N] [--only LABEL]

Each scenario is ONE edit to ONE file, applied to the ORIGINAL text, so every
measured edit is a single change against a warm store. A round makes two
fresh edits (fresh text, so no earlier round's answer is reused): one is
timed with no trace (wall, status, the compiler's `--time` line); the other
runs under AVRA_QTRACE=1 and is counted (files parsed, derivation attempts,
memo computes). The original file is restored after each scenario, and the
base is warmed (untimed) before each one.

Output: one TSV row per round and a summary table, also written to
build/scenarios.tsv. Nothing is fixed here; this only measures.
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
import time

AVRA = os.environ.get("AVRA_BIN", "build/avra")
CLI = "packages/cli"
STD_TEXT = "packages/std-text"
SHARED = "packages/cli/src/commands/shared.av"
ATTACK = "packages/cli/src/commands/attack.av"
EXPLAIN = "packages/cli/src/commands/explain.av"
DIGEST = "packages/std-avrac/src/core/digest.av"
TEXT = "packages/std-text/src/text.av"
ORIG = "build/scenarios-orig"

# (label, command, package-or-path, edit)
# edit = (mode, file, *args); "@U" in any replacement is a fresh unique token
SCENARIOS = [
    ("1 body literal, cli shared.av", "check", CLI,
     ("subst", SHARED, "· memo", "· memo @U")),
    ("2 body literal, leaf cli file (attack.av)", "check", CLI,
     ("firststr", ATTACK)),
    ("3 body literal, std-avrac core (digest.av)", "check", CLI,
     ("subst", DIGEST, "x & 9223372036854775807 }", "x & (9223372036854775807 + 0 * @U) }")),
    ("4 add a private fn to shared.av", "check", CLI,
     ("append", SHARED, "fn scen_private_@U(n: int) -> int { n + @U }")),
    ("5 add an exported fn to shared.av", "check", CLI,
     ("append", SHARED, "export fn scen_pub_@U(n: int) -> int { n + @U }")),
    ("6 signature: rename param of slotted_path (3 files use it)", "check", CLI,
     ("rename_in_fn", SHARED, "slotted_path", "args", "args_@U")),
    ("7 add a defaulted field to Asked (explain.av)", "check", CLI,
     ("field", EXPLAIN, "Asked", "scen_@U: bool = false")),
    ("8 comment only, shared.av", "check", CLI,
     ("append", SHARED, "// scenario @U")),
    ("9 rename a local in built_binary (shared.av)", "check", CLI,
     ("rename_in_fn", SHARED, "built_binary", "ws", "ws_@U")),
    # build: owner's bar is <= 500 ms after one body edit
    ("B1 build: body literal, shared.av", "build", CLI,
     ("subst", SHARED, "· memo", "· memo @U")),
    ("B4 build: add a private fn to shared.av", "build", CLI,
     ("append", SHARED, "fn scen_private_@U(n: int) -> int { n + @U }")),
    ("B8 build: comment only, shared.av", "build", CLI,
     ("append", SHARED, "// scenario @U")),
    # test: a body edit in std-text, then its suite
    ("T1 test: body literal, std-text text.av", "test", STD_TEXT,
     ("subst", TEXT, "== 0 { return null }", "== (0 + 0 * @U) { return null }")),
    # fmt: one edit in the cli, then a check of every cli source file
    ("F1 fmt --check: body literal, shared.av", "fmt", "packages/cli/src",
     ("subst", SHARED, "· memo", "· memo @U")),
]

_uid = [0]
_base = [int(time.time()) % 1000000 * 100]


def fresh():
    _uid[0] += 1
    return str(_base[0] + _uid[0])


def backup(path):
    dst = os.path.join(ORIG, path.replace("/", "__"))
    if not os.path.exists(dst):
        os.makedirs(ORIG, exist_ok=True)
        shutil.copyfile(path, dst)
    return dst


def restore(path):
    shutil.copyfile(backup(path), path)


def fn_span(lines, name):
    start = next(i for i, l in enumerate(lines) if re.match(r"^(export )?fn " + re.escape(name) + r"\(", l))
    for j in range(start + 1, len(lines)):
        if lines[j].startswith("}"):
            return start, j
    raise SystemExit(f"no end for fn {name}")


def apply(edit):
    """Write the original text with ONE edit (fresh @U), return the token used."""
    mode, path, *rest = edit
    u = fresh()
    text = open(backup(path)).read()
    if mode == "subst":
        old, new = rest
        if old not in text:
            raise SystemExit(f"{path} lacks {old!r}")
        text = text.replace(old, new.replace("@U", u), 1)
    elif mode == "firststr":
        m = re.search(r'"([A-Za-z][A-Za-z ,.\-]*)"', text)
        if m is None:
            raise SystemExit(f"{path} has no plain string literal")
        text = text[:m.start()] + '"' + m.group(1) + " " + u + '"' + text[m.end():]
    elif mode == "append":
        (line,) = rest
        text = text.rstrip("\n") + "\n" + line.replace("@U", u) + "\n"
    elif mode == "rename_in_fn":
        fn, old, new = rest
        lines = text.split("\n")
        s, e = fn_span(lines, fn)
        pat = re.compile(r"\b" + re.escape(old) + r"\b")
        for i in range(s, e + 1):
            lines[i] = pat.sub(new.replace("@U", u), lines[i])
        text = "\n".join(lines)
    elif mode == "field":
        typ, decl = rest
        lines = text.split("\n")
        i = next(i for i, l in enumerate(lines) if re.match(r"^export type " + re.escape(typ) + r" = \{", l))
        close = lines[i].rindex(" }")
        lines[i] = lines[i][:close] + ", " + decl.replace("@U", u) + lines[i][close:]
        text = "\n".join(lines)
    else:
        raise SystemExit(f"unknown mode {mode}")
    open(path, "w").write(text)
    return u


def run(argv, trace=False):
    env = dict(os.environ)
    env["AVRA_MEM_CEILING_MB"] = env.get("AVRA_MEM_CEILING_MB", "5000")
    if trace:
        env["AVRA_QTRACE"] = "1"
    t0 = time.time()
    p = subprocess.run(argv, capture_output=True, text=True, env=env)
    wall = (time.time() - t0) * 1000
    return wall, p.returncode, p.stdout, p.stderr


def time_line(out, err):
    for chunk in (out, err):
        for l in chunk.splitlines():
            if l.startswith("time:"):
                return l
    return ""


PHASES = ["ast", "sublang", "parse", "resolve", "sigs", "bodies", "load", "admit",
          "analyze", "lower", "keep"]


def dominant(tl):
    best, name = -1, "n/a"
    for k in PHASES:
        m = re.search(r"\b" + k + r" (\d+)ms", tl)
        if m and int(m.group(1)) > best:
            best = int(m.group(1))
            name = f"{k} {best}ms"
    return name


def held(tl):
    m = re.search(r"held (\d+)/(\d+)", tl)
    return f"{m.group(1)}/{m.group(2)}" if m else "n/a"


def counts(err):
    parsed = sum(1 for l in err.splitlines() if l.startswith("Q\tparse\t"))
    attempts = sum(1 for l in err.splitlines() if l.startswith("Q\tattempt\t"))
    computes = sum(1 for l in err.splitlines() if re.match(r"^Q\task\t\S+\t\S+\tcompute", l))
    return parsed, attempts, computes


def argv_for(cmd, target):
    if cmd == "fmt":
        files = sorted(
            os.path.join(d, f) for d, _, fs in os.walk(target) for f in fs if f.endswith(".av")
        )
        return [AVRA, "fmt", "--check"] + files
    return [AVRA, cmd, "--time", target]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rounds", type=int, default=3)
    ap.add_argument("--only", default="")
    a = ap.parse_args()
    rows = []
    for label, cmd, target, edit in SCENARIOS:
        if a.only and a.only not in label:
            continue
        path = edit[1]
        backup(path)
        argv = argv_for(cmd, target)
        restore(path)
        run(argv)  # warm the base untimed
        for r in range(1, a.rounds + 1):
            restore(path)
            apply(edit)
            wall, st, out, err = run(argv)
            tl = time_line(out, err)
            restore(path)
            apply(edit)
            _, _, _, qerr = run(argv, trace=True)
            parsed, attempts, computes = counts(qerr)
            rows.append((label, r, round(wall), st, held(tl), parsed, attempts, computes, dominant(tl), tl))
            restore(path)
            run(argv)  # warm the base again
        restore(path)
    os.makedirs("build", exist_ok=True)
    with open("build/scenarios.tsv", "w") as fh:
        fh.write("scenario\tround\twall_ms\tstatus\theld\tparsed\tattempts\tcomputes\tdominant\ttime_line\n")
        for r in rows:
            fh.write("\t".join(str(x) for x in r) + "\n")
    print(f"{'scenario':48s} rnd  wall_ms st  held  parsed att computes  dominant")
    for r in rows:
        print(f"{r[0]:48s} {r[1]:3d} {r[2]:8d} {r[3]:2d} {r[4]:>6s} {r[5]:6d} {r[6]:3d} {r[7]:8d}  {r[8]}")


if __name__ == "__main__":
    main()
