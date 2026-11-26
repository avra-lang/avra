#!/usr/bin/env python3
"""EVERY `AVRA_*` VARIABLE THE TREE READS IS A DECLARED SETTING, read through its projection.

The one declaration (tools/src/settings/declared.av) projects each package's readers and the
runtime's header (`wisp tree settings`); a read that spells a variable by hand is a setting the
declaration does not know, typed by nobody, invisible to `explain()` and to a child's `Env.Only`.
This keeper reads every Avra and C source under packages/*/src and runtime/ and refuses a literal
`AVRA_*` read outside the projections that tools/settings_reads.allow does not name, with its
reason. It refuses a row of that file that matches no read too, so the list only shrinks.

    python3 tools/settings_reads.py             # judge the tree
    python3 tools/settings_reads.py --self-test # the keeper's own cases
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ALLOW = os.path.join(ROOT, "tools", "settings_reads.allow")

# A read of the environment by a name spelled in the source: the Avra doors and the C ones.
READ = re.compile(r"\b(env|env_or|getenv|secure_getenv|avra_host_env|avra_getenv_raw)\(\s*\"(AVRA_[A-Z0-9_]+)\"")

# The projections the declaration writes: their reads are the declaration's own.
PROJECTED = re.compile(r"(^|/)settings/settings\.av$|^runtime/avra_settings\.h$")

SOURCES = re.compile(r"^(packages/[^/]+/src/.*\.(av|c|h)|runtime/.*\.(c|h))$")


def tracked():
    """Every source the keeper reads, relative to the tree's root."""
    out = subprocess.run(["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True).stdout
    return [p for p in out.splitlines() if SOURCES.match(p) and not PROJECTED.search(p)]


def reads_in(path, text):
    """Each (path, variable, line) a source spells a read of."""
    return [(path, m.group(2), text.count("\n", 0, m.start()) + 1) for m in READ.finditer(text)]


def allowed(text):
    """The allow rows: (path, variable) -> reason. A row is `<path> <VARIABLE> <reason>`."""
    rows = {}
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split(None, 2)
        rows[(parts[0], parts[1] if len(parts) > 1 else "")] = parts[2] if len(parts) > 2 else ""
    return rows


def judged(reads, rows):
    """Every refusal: an unlisted read, a row with no reason, a row that matches no read."""
    seen = {(p, v) for p, v, _ in reads}
    refused = [f"settings_reads: {p}:{n} reads `{v}` by hand — declare it in tools/src/settings/declared.av and read its projection, or name it in tools/settings_reads.allow with its reason"
               for p, v, n in reads if (p, v) not in rows]
    refused += [f"settings_reads: tools/settings_reads.allow names `{v}` in {p} without a reason" for (p, v), why in rows.items() if not why]
    refused += [f"settings_reads: tools/settings_reads.allow names `{v}` in {p}, which reads it no more — strike the row" for (p, v) in rows if (p, v) not in seen]
    return refused


def self_test():
    reads = reads_in("packages/a/src/x.av", 'let a = env("AVRA_A")\nlet b = env_or("AVRA_B", "")\n') + \
        reads_in("runtime/r.c", 'const char* c = getenv("AVRA_C");\nconst char* d = getenv(AVRA_SET_D);\n')
    assert [(v, n) for _, v, n in reads] == [("AVRA_A", 1), ("AVRA_B", 2), ("AVRA_C", 1)], reads
    rows = allowed("# a comment\npackages/a/src/x.av AVRA_A a fixture\nruntime/r.c AVRA_C the C's own\n")
    assert judged(reads, rows) == [judged(reads, rows)[0]] and "`AVRA_B`" in judged(reads, rows)[0]
    rows[("packages/a/src/x.av", "AVRA_B")] = "listed"
    assert judged(reads, rows) == []
    rows[("packages/gone/src/y.av", "AVRA_Y")] = "stale"
    assert judged(reads, rows) == ["settings_reads: tools/settings_reads.allow names `AVRA_Y` in packages/gone/src/y.av, which reads it no more — strike the row"]
    del rows[("packages/gone/src/y.av", "AVRA_Y")]
    rows[("runtime/r.c", "AVRA_C")] = ""
    assert judged(reads, rows) == ["settings_reads: tools/settings_reads.allow names `AVRA_C` in runtime/r.c without a reason"]
    assert PROJECTED.search("packages/cli/src/settings/settings.av") and PROJECTED.search("runtime/avra_settings.h")
    assert not PROJECTED.search("packages/cli/src/settings/other.av")
    print("settings_reads: self-test passed — 6 cases")


def main():
    if sys.argv[1:] == ["--self-test"]:
        self_test()
        return 0
    paths = tracked()
    reads = [r for p in paths for r in reads_in(p, open(os.path.join(ROOT, p), encoding="utf-8", errors="replace").read())]
    refused = judged(reads, allowed(open(ALLOW, encoding="utf-8").read()))
    for line in refused:
        print(line)
    print(f"settings_reads: {len(paths)} source(s) read, {len(reads)} hand-spelled read(s), {len(refused)} refused")
    return 1 if refused else 0


if __name__ == "__main__":
    sys.exit(main())
