#!/usr/bin/env python3
"""THE PRE-COMMIT HOOK REFUSES WITHOUT A COMPILER: staged `.av` and no `build/avra` is exit 1
naming how to get one; no staged `.av` passes with no compiler.

    python3 tools/hooks_pre_commit_check.py
"""
import os
import subprocess
import sys
import tempfile

HOOK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "hooks", "pre-commit")


def run(*cmd, cwd):
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)


def staged(name, text):
    d = tempfile.mkdtemp()
    run("git", "init", "-q", cwd=d)
    with open(os.path.join(d, name), "w") as f:
        f.write(text)
    run("git", "add", name, cwd=d)
    return d


def main():
    d = staged("a.av", "let x = 1\n")
    r = run("sh", HOOK, cwd=d)
    if r.returncode != 1 or "refused" not in r.stderr or "tools/work" not in r.stderr:
        sys.exit(f"hooks_pre_commit_check: staged .av with no compiler gave {r.returncode}: {r.stderr!r}")
    d = staged("notes.txt", "x\n")
    r = run("sh", HOOK, cwd=d)
    if r.returncode != 0:
        sys.exit(f"hooks_pre_commit_check: no .av staged must pass with no compiler, gave {r.returncode}: {r.stderr!r}")
    print("hooks_pre_commit_check: refusal and accept witnessed — 2 fixtures")


main()
