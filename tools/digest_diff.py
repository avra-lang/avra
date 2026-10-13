#!/usr/bin/env python3
"""Compare the digests two fresh processes gave the same named answers.

Each input is the stderr of `AVRA_LEAVES=1 avra check <pkg>`, whose
`leaves-digest<TAB>family<TAB>name<TAB>digest` lines are read. Per family
this prints how many answers present in both agree, how many exist in only
one, and the first names that differ. Exit 0 when every family agrees,
1 when one does not.
"""
import sys


def read(lines):
    fams = {}
    for line in lines:
        parts = line.rstrip("\n").split("\t")
        if len(parts) != 4 or parts[0] != "leaves-digest":
            continue
        fams.setdefault(parts[1], {})[parts[2]] = parts[3]
    return fams


def compare(a, b, shown=5):
    out, ok = [], True
    for fam in sorted(set(a) | set(b)):
        x, y = a.get(fam, {}), b.get(fam, {})
        common = sorted(set(x) & set(y))
        differ = [n for n in common if x[n] != y[n]]
        alone = len(set(x) ^ set(y))
        out.append("%s: equal across processes: %d of %d (only in one: %d)" % (fam, len(common) - len(differ), len(common), alone))
        for n in differ[:shown]:
            out.append("    differs: %s  %s != %s" % (n, x[n], y[n]))
        if differ or alone:
            ok = False
    return out, ok


def self_test():
    a = read(["leaves-digest\tF\tx\t1", "leaves-digest\tF\ty\t2", "leaves-digest\tG\tz\t3", "noise"])
    b = read(["leaves-digest\tF\tx\t1", "leaves-digest\tF\ty\t9", "leaves-digest\tG\tw\t3"])
    out, ok = compare(a, b)
    assert not ok
    assert out[0] == "F: equal across processes: 1 of 2 (only in one: 0)", out[0]
    assert out[1].startswith("    differs: y"), out[1]
    assert out[2] == "G: equal across processes: 0 of 0 (only in one: 2)", out[2]
    same, ok = compare(a, a)
    assert ok and same[0].startswith("F: equal across processes: 2 of 2")
    assert read([]) == {} and compare({}, {})[1]
    print("digest_diff: self-test passed")


def main(argv):
    if argv[1:] == ["--self-test"]:
        return self_test()
    if len(argv) != 3:
        print("usage: digest_diff.py <first.stderr> <second.stderr> | --self-test")
        return 2
    a, b = (read(open(p, errors="replace")) for p in argv[1:])
    if not a or not b:
        print("digest_diff: a file holds no leaves-digest line — run with AVRA_LEAVES=1")
        return 2
    out, ok = compare(a, b)
    print("\n".join(out))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
