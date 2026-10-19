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
    # A COMPILER'S STAMP: unstamped refuses, one older than the merge-base refuses (naming the way
    # out), one at the merge-base or built from its own edits is accepted and reported.
    def stamped_repo(stamp):
        d = tempfile.mkdtemp()
        git = lambda *a: run("git", "-c", "user.name=t", "-c", "user.email=t@t", *a, cwd=d)
        git("init", "-q", "-b", "main")
        os.makedirs(os.path.join(d, "tools"))
        os.makedirs(os.path.join(d, "build"))
        with open(os.path.join(d, "tools", "compiler_paths.sh"), "w") as f:
            f.write(open(os.path.join(os.path.dirname(HOOK), "..", "compiler_paths.sh")).read())
        with open(os.path.join(d, "Makefile"), "w") as f:
            f.write("one\n")
        git("add", "-A")
        git("commit", "-q", "-m", "one")
        first = git("rev-parse", "HEAD").stdout.strip()
        with open(os.path.join(d, "Makefile"), "w") as f:
            f.write("two\n")
        git("commit", "-q", "-am", "two")
        second = git("rev-parse", "HEAD").stdout.strip()
        git("update-ref", "refs/remotes/origin/main", "HEAD")
        with open(os.path.join(d, "build", "avra"), "w") as f:
            f.write("#!/bin/sh\nexit 0\n")
        os.chmod(os.path.join(d, "build", "avra"), 0o755)
        if stamp is not None:
            with open(os.path.join(d, "build", ".avra-built-from"), "w") as f:
                f.write("hash%s %s\n" % ("0" * 3, {"old": first, "current": second, "edited": "edited"}[stamp]))
        with open(os.path.join(d, "a.av"), "w") as f:
            f.write("let x = 1\n")
        git("add", "a.av")
        return d
    r = run("sh", HOOK, cwd=stamped_repo(None))
    if r.returncode != 1 or "says nothing about what it was built from" not in r.stderr:
        sys.exit(f"hooks_pre_commit_check: an unstamped compiler gave {r.returncode}: {r.stderr!r}")
    r = run("sh", HOOK, cwd=stamped_repo("old"))
    if r.returncode != 1 or "1 compiler commit(s) older" not in r.stderr or "tools/work compiler" not in r.stderr:
        sys.exit(f"hooks_pre_commit_check: a compiler older than the merge-base gave {r.returncode}: {r.stderr!r}")
    for kind in ("current", "edited"):
        r = run("sh", HOOK, cwd=stamped_repo(kind))
        if r.returncode != 0 or "formatting with" not in r.stderr:
            sys.exit(f"hooks_pre_commit_check: a {kind} compiler gave {r.returncode}: {r.stderr!r}")
    print("hooks_pre_commit_check: refusal and accept witnessed — 6 fixtures")


main()
