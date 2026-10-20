#!/usr/bin/env python3
"""THE STORE'S SEGMENTS, HANDED UP AND KEPT: what a main run's shards wrote, for later runs' prepare.

    store_segments.py --merge <kept> <in>... [--prints N] [--cap-mb M]
    store_segments.py --self-test

A store segment is `seg-<writer pid>-<print>.log`: one writer's frames, which every reader merges at
open, so putting segments from many jobs in one directory IS their merge. The <print> is the
compiler's own (eight hex digits), and a reader never reads a row another print wrote, so a segment
is only worth keeping for the prints a later run can still be. `--merge` copies every segment of the
`<in>` directories into `<kept>` (a name two jobs share is the newer file's), keeps the newest
`--prints` prints by file time (default 2) and then at most `--cap-mb` megabytes, newest first. A
file that is not a segment is never touched, so a body or a lock beside them is the store's own.
"""
import os
import re
import shutil
import sys
import tempfile

SEGMENT = re.compile(r"^seg-(\d+)-([0-9a-f]{8})\.log$")


def segments(directory):
    """(name, print, mtime, bytes) of every segment standing in the directory."""
    out = []
    if not os.path.isdir(directory):
        return out
    for name in sorted(os.listdir(directory)):
        m = SEGMENT.match(name)
        if m:
            st = os.stat(os.path.join(directory, name))
            out.append((name, m.group(2), st.st_mtime, st.st_size))
    return out


def merge(kept, inputs, prints=2, cap_bytes=157286400):
    """Fold the inputs into `kept`, then bound it: newest prints, then the byte cap."""
    os.makedirs(kept, exist_ok=True)
    for d in inputs:
        for name, _, _, _ in segments(d):
            shutil.copy2(os.path.join(d, name), os.path.join(kept, name))
    standing = segments(kept)
    newest = {}
    for _, p, t, _ in standing:
        newest[p] = max(newest.get(p, 0), t)
    keep_prints = set(sorted(newest, key=lambda p: -newest[p])[:prints])
    spent = 0
    for name, p, _, size in sorted(standing, key=lambda s: -s[2]):
        if p not in keep_prints or spent + size > cap_bytes:
            os.remove(os.path.join(kept, name))
        else:
            spent += size
    return segments(kept)


def self_test():
    root = tempfile.mkdtemp()

    def put(d, name, body, t):
        os.makedirs(d, exist_ok=True)
        path = os.path.join(d, name)
        with open(path, "w") as f:
            f.write(body)
        os.utime(path, (t, t))

    a, b, kept = (os.path.join(root, x) for x in ("a", "b", "kept"))
    put(a, "seg-10-aaaaaaaa.log", "x" * 10, 100)
    put(b, "seg-11-aaaaaaaa.log", "y" * 10, 101)
    put(b, "body-3.pack", "not a segment", 102)
    got = [s[0] for s in merge(kept, [a, b])]
    assert got == ["seg-10-aaaaaaaa.log", "seg-11-aaaaaaaa.log"], got
    assert not os.path.exists(os.path.join(kept, "body-3.pack")), "a body is never carried"
    # three prints: the oldest goes
    put(a, "seg-12-bbbbbbbb.log", "z", 200)
    put(a, "seg-13-cccccccc.log", "z", 300)
    got = sorted(s[1] for s in merge(kept, [a]))
    assert "aaaaaaaa" not in got and got == ["bbbbbbbb", "cccccccc"], got
    # the byte cap drops the oldest of what stays
    put(a, "seg-14-cccccccc.log", "q" * 50, 400)
    got = [s[0] for s in merge(kept, [a], cap_bytes=50)]
    assert got == ["seg-14-cccccccc.log"], got
    # a name two jobs share is the newer file's
    put(b, "seg-14-cccccccc.log", "n" * 5, 500)
    merge(kept, [b])
    assert open(os.path.join(kept, "seg-14-cccccccc.log")).read() == "n" * 5
    # no input at all keeps what stands
    before = [s[0] for s in segments(kept)]
    assert [s[0] for s in merge(kept, [os.path.join(root, "none")])] == before
    shutil.rmtree(root)
    print("store_segments: self-test passed — merge, print bound, byte cap, newer wins, bodies untouched")


def main(argv):
    if argv[:1] == ["--self-test"]:
        return self_test()
    if argv[:1] != ["--merge"] or len(argv) < 3:
        sys.exit(__doc__)
    args, prints, cap = argv[1:], 2, 150
    if "--prints" in args:
        i = args.index("--prints")
        prints = int(args[i + 1])
        del args[i : i + 2]
    if "--cap-mb" in args:
        i = args.index("--cap-mb")
        cap = int(args[i + 1])
        del args[i : i + 2]
    left = merge(args[0], args[1:], prints, cap * 1048576)
    print("store segments kept: %d (%d prints, %d KB)" % (
        len(left), len({s[1] for s in left}), sum(s[3] for s in left) // 1024))


if __name__ == "__main__":
    main(sys.argv[1:])
