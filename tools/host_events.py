#!/usr/bin/env python3
"""THE WEB'S EVENT VOCABULARY IS DERIVED, never kept by hand.

packages/std-ui/assets/webref_events.json is w3c/webref's ed/events.json at
the commit PIN names; tree/dom_event.av is `DomEvent`, the enum a
seat's `@host(web: .Click)` is checked against, written from that file. A
host event that is not in the file is not in the enum.

  host_events.py              the keeper: asset == pin, enum == the asset's
  host_events.py --write      regenerate the enum from the asset
  host_events.py --fetch SHA  pin a new webref commit, then --write
"""
import hashlib, json, os, re, sys, urllib.request

PIN = "b5dd81b5400206d36f17ae1929e4096cc89ca28e"
DIGEST = "2bd63a9df35348c4c2c2941eb4589bf946026fc201c737714911585eeaf96265"

WIDTH = 101
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
asset = os.path.join(root, "packages/std-ui/assets/webref_events.json")
out = os.path.join(root, "packages/std-ui/src/tree/dom_event.av")


def variant(t):
    return t[0].upper() + t[1:]


def quoted(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def rows(entries):
    """One row per event type: its interface and every element it fires at."""
    by = {}
    for e in entries:
        r = by.setdefault(e["type"], {"interface": e["interface"], "targets": []})
        for t in e["targets"]:
            if t["target"] not in r["targets"]:
                r["targets"].append(t["target"])
    return [(t, by[t]) for t in sorted(by)]


def targets_line(items):
    """`targets` on one line when it fits the formatter's width, else one item a line."""
    one = f"        targets: [{', '.join(items)}],"
    if len(one) <= WIDTH + 2:
        return [one]
    return ["        targets: ["] + [f"            {i}," for i in items] + ["        ],"]


def generated(entries):
    table = rows(entries)
    names = [variant(t) for t, _ in table]
    clash = {n for n in names if names.count(n) > 1}
    if clash:
        sys.exit(f"host-events: two event types spell one variant: {sorted(clash)}")
    lines = [
        f"//! `tree/dom_event.av` — THE WEB'S EVENTS, generated from w3c/webref @ {PIN[:12]}",
        "//! (tools/host_events.py, `make host-events`): never edited. A variant is an event",
        "//! type with its first letter capitalised; `word` is the type the DOM spells it with.",
        "",
        "/// An event the web platform fires.",
        "export enum DomEvent {",
    ]
    lines += [f"    {n}" for n in names]
    lines += ["}", "", "/// What the platform says of one event: the interface its event objects", "/// implement and every interface it fires at.", "type DomRow = { event: DomEvent, interface: string, targets: List<string> }", "", "const dom_rows: List<DomRow> = ["]
    for t, r in table:
        items = [quoted(x) for x in r["targets"]]
        flat = f"    DomRow {{ event: .{variant(t)}, interface: {quoted(r['interface'])}, targets: [{', '.join(items)}] }},"
        if len(flat) <= WIDTH:
            lines += [flat]
            continue
        lines += ["    DomRow {", f"        event: .{variant(t)},", f"        interface: {quoted(r['interface'])},"]
        lines += targets_line([quoted(x) for x in r["targets"]])
        lines += ["    },"]
    lines += ["]", "", "impl DomEvent {", "    /// The event type as the DOM names it.", "    fn word() -> string {", "        match self {"]
    lines += [f"            .{variant(t)} -> {quoted(t)}," for t, _ in table]
    lines += [
        "        }",
        "    }",
        "",
        "    /// The interface its event objects implement.",
        "    fn interface() -> string { dom_rows.find(it.event == self)!.interface }",
        "",
        "    /// The interfaces it fires at.",
        "    fn targets() -> List<string> { dom_rows.find(it.event == self)!.targets }",
        "}",
        "",
    ]
    return "\n".join(lines)


def fetch(sha):
    url = f"https://raw.githubusercontent.com/w3c/webref/{sha}/ed/events.json"
    data = urllib.request.urlopen(url, timeout=60).read()
    open(asset, "wb").write(data)
    print(f"host-events: pinned {sha}; set PIN and DIGEST in tools/host_events.py to:")
    print(f'PIN = "{sha}"\nDIGEST = "{hashlib.sha256(data).hexdigest()}"')


def main():
    args = sys.argv[1:]
    if args[:1] == ["--fetch"]:
        return fetch(args[1])
    data = open(asset, "rb").read()
    if hashlib.sha256(data).hexdigest() != DIGEST:
        sys.exit("host-events: the webref asset is not the pinned file — it is fetched (--fetch SHA), never edited")
    text = generated(json.loads(data))
    if args[:1] == ["--write"]:
        open(out, "w").write(text)
        return print(f"host-events: wrote {out}")
    if not os.path.exists(out) or open(out).read() != text:
        sys.exit("host-events: tree/dom_event.av is not what the pinned webref says — it is generated: python3 tools/host_events.py --write")
    print(f"host-events: DomEvent is the pinned webref's ({len(rows(json.loads(data)))} event types)")


main()
