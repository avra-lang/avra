"""THE ROW FILES THE RATCHETS READ, the one reader and writer: a budget and a measurement are lines of
`<key words…> <number>`, read into {key tuple: number} by a pattern naming the key groups and the value
group, and written back sorted so a diff reads. Every ratchet (speed, work, census) states its own
patterns and heads and asks this module for the rest, so no two read a row file two ways.

    read(text, pattern, keys, value, least=False, flat=False)   rows from text; a line that is not a row
                                                                is read past; `least` keeps the smallest
                                                                of a repeated key; `flat` answers a bare
                                                                key for a one-word key
    read_file(path, ...)                                        the same from a file, {} when it is absent
    lines(rows)                                                 `<key words…> <number>` per row, sorted
    lowered(measured, ceilings)                                 the ceilings after an accept: lowered to
                                                                what was measured, a new key seeded,
                                                                never one raised
"""
import os


def read(text, pattern, keys, value, least=False, flat=False):
    rows = {}
    for line in text.splitlines():
        m = pattern.match(line.strip())
        if not m:
            continue
        key = tuple(m.group(k) for k in keys)
        if flat:
            key = key[0]
        n = int(m.group(value))
        rows[key] = min(n, rows[key]) if least and key in rows else n
    return rows


def read_file(path, *args, **kwargs):
    return read(open(path).read(), *args, **kwargs) if os.path.exists(path) else {}


def lines(rows):
    return "".join(
        "%s %d\n" % (" ".join(k) if isinstance(k, tuple) else k, rows[k]) for k in sorted(rows)
    )


def lowered(measured, ceilings):
    out = dict(ceilings)
    for key, now in measured.items():
        out[key] = min(now, ceilings.get(key, now))
    return out


def self_test():
    import re

    pat = re.compile(r"^(?P<a>[a-z]+) (?P<b>[a-z]+) (?P<n>[0-9]+)$")
    assert read("x y 3\nx y 2\nnoise\nz w 9\n", pat, ["a", "b"], "n", least=True) == {("x", "y"): 2, ("z", "w"): 9}
    assert read("x y 3\nx y 2\n", pat, ["a", "b"], "n") == {("x", "y"): 2}
    assert read("x y 3\n", pat, ["a"], "n", flat=True) == {"x": 3}
    assert read_file("/no/such/file", pat, ["a"], "n") == {}
    assert lines({("b", "y"): 1, ("a", "x"): 2}) == "a x 2\nb y 1\n"
    assert lines({"k": 4}) == "k 4\n"
    assert lowered({("a", "x"): 5, ("n", "w"): 7}, {("a", "x"): 9, ("c", "z"): 1}) == {("a", "x"): 5, ("c", "z"): 1, ("n", "w"): 7}
    assert lowered({("a", "x"): 12}, {("a", "x"): 9}) == {("a", "x"): 9}
    print("ratchet_rows: self-test passed — rows read (least, flat, absent file), written sorted, lowered and never raised")
    return 0


if __name__ == "__main__":
    import sys

    sys.exit(self_test() if sys.argv[1:] == ["--self-test"] else 2)
