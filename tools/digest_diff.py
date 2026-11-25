#!/usr/bin/env python3
# tool-witness: --self-test
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


def read_reads(lines):
    """name -> {read identity: digest} from the `leaves-reads` lines."""
    out = {}
    for line in lines:
        parts = line.rstrip("\n").split("\t")
        if len(parts) != 3 or parts[0] != "leaves-reads":
            continue
        reads = {}
        for read in parts[2].split(";"):
            for leaf in read.split(","):
                if leaf == "?":
                    reads["?"] = ""
                    continue
                ident, _, digest = leaf.rpartition("=")
                reads[ident] = digest
        out[parts[1]] = reads
    return out


def standing(first_reads, second_reads, second_digests):
    """Typed answers of the first process whose every read still has its digest in the
    second, and for those that moved, the first identity that did."""
    valid, moved = 0, {}
    for name, reads in first_reads.items():
        if name not in second_reads:
            continue
        bad = None
        for ident, digest in reads.items():
            family, _, rest = ident.partition("|")
            if ident == "?" or digest == "":
                bad = "unnamed"
            elif family == "rows":
                now = second_reads[name].get(ident)
            else:
                now = second_digests.get(family, {}).get(rest)
            if bad is None and (now is None or now != digest):
                bad = family
            if bad:
                break
        if bad:
            moved[bad] = moved.get(bad, 0) + 1
        else:
            valid += 1
    return valid, moved


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
    ra = read_reads(["leaves-reads\tt1\tNames|n1=5;rows|R=7", "leaves-reads\tt2\tNames|n2=6", "x"])
    rb = read_reads(["leaves-reads\tt1\tNames|n1=5;rows|R=7", "leaves-reads\tt2\tNames|n2=6"])
    valid, moved = standing(ra, rb, {"Names": {"n1": "5", "n2": "9"}})
    assert valid == 1 and moved == {"Names": 1}, (valid, moved)
    print("digest_diff: self-test passed")


def main(argv):
    if argv[1:] == ["--self-test"]:
        return self_test()
    if len(argv) != 3:
        print("usage: digest_diff.py <first.stderr> <second.stderr> | --self-test")
        return 2
    texts = [open(p, errors="replace").read().split("\n") for p in argv[1:]]
    a, b = read(texts[0]), read(texts[1])
    if not a or not b:
        print("digest_diff: a file holds no leaves-digest line — run with AVRA_LEAVES=1")
        return 2
    out, ok = compare(a, b)
    ra, rb = read_reads(texts[0]), read_reads(texts[1])
    if ra and rb:
        valid, moved = standing(ra, rb, b)
        out.append("Typed standing after the change: %d of %d (moved, by first read family: %s)" % (valid, valid + sum(moved.values()), ", ".join("%s %d" % kv for kv in sorted(moved.items(), key=lambda kv: -kv[1])) or "none"))
    print("\n".join(out))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
