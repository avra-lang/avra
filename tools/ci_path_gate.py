#!/usr/bin/env python3
"""THE PATH GATE: which jobs a change owes, decided from the changed paths.

    git diff --name-only origin/main HEAD | ci_path_gate.py <job> --event <event>

Prints 1 when the job owes the run, 0 when it does not. A push, a hand-run
and any other non-PR event owe every job, so main's own run always carries
them. A PR owes a job only when a path it reads is changed. `checks.yml`'s
`prepare` step is the one caller, and each job's `if:` reads the output.

    ci_path_gate.py --self-test
"""
import sys

# A trailing slash is a directory; any other entry is one file.
READS = {
    "runtime-keep": ("runtime/", "Makefile", "tools/memcap.sh"),
    "layout-oracle": ("packages/std-ui/", "packages/std-text/", "tools/layout-oracle/", "tools/layout_oracle.sh"),
}


def owes(job, event, changed):
    if event != "pull_request":
        return True
    reads = READS[job]
    return any(f == r or (r.endswith("/") and f.startswith(r)) for f in changed for r in reads)


def self_test():
    cases = [
        ("runtime-keep", "pull_request", ["runtime/avra_fiber.c"], True),
        ("runtime-keep", "pull_request", ["runtime/tests/flow_test.c"], True),
        ("runtime-keep", "pull_request", ["Makefile"], True),
        ("runtime-keep", "pull_request", ["tools/memcap.sh"], True),
        ("runtime-keep", "pull_request", ["packages/cli/src/main.av"], False),
        ("runtime-keep", "pull_request", ["docs/x.md", "tools/other.py"], False),
        ("runtime-keep", "pull_request", [], False),
        ("runtime-keep", "pull_request", ["runtimes/x.c"], False),
        ("runtime-keep", "push", [], True),
        ("layout-oracle", "pull_request", ["packages/std-ui/src/place/solve.av"], True),
        ("layout-oracle", "pull_request", ["packages/std-ui/src/realize/html/css.av"], True),
        ("layout-oracle", "pull_request", ["packages/std-text/src/display.av"], True),
        ("layout-oracle", "pull_request", ["tools/layout-oracle/oracle.mjs"], True),
        ("layout-oracle", "pull_request", ["packages/cli/src/main.av", "docs/x.md"], False),
        ("layout-oracle", "pull_request", ["packages/std-uix/a.av"], False),
        ("layout-oracle", "push", [], True),
        ("runtime-keep", "push", ["packages/cli/src/main.av"], True),
        ("runtime-keep", "workflow_dispatch", [], True),
    ]
    bad = [(j, e, c, want) for j, e, c, want in cases if owes(j, e, c) != want]
    for j, e, c, want in bad:
        print("ci_path_gate: FAILED — %s %s %s should be %s" % (j, e, c, want))
    if bad:
        return 1
    print("ci_path_gate: self-test clean — %d case(s)" % len(cases))
    return 0


def main(argv):
    if "--self-test" in argv:
        return self_test()
    job = argv[0]
    event = argv[argv.index("--event") + 1]
    changed = [line.strip() for line in sys.stdin if line.strip()]
    print(1 if owes(job, event, changed) else 0)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
