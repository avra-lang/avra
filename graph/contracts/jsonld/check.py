#!/usr/bin/env python3
"""Every key an Answer document uses must have a term in the JSON-LD context.

Usage: check.py ANSWER.json [...]   (stdlib only; not a JSON-LD processor)
"""
import json
import pathlib
import sys

CONTEXT = json.loads((pathlib.Path(__file__).parent / "answer.context.jsonld").read_text())["@context"]
OPAQUE = {"value"}


def keys(node, found):
    if isinstance(node, dict):
        for key, child in node.items():
            found.add(key)
            if key not in OPAQUE:
                keys(child, found)
    elif isinstance(node, list):
        for child in node:
            keys(child, found)
    return found


def main():
    missing = set()
    for name in sys.argv[1:]:
        missing |= keys(json.loads(pathlib.Path(name).read_text()), set()) - CONTEXT.keys()
    if missing:
        sys.exit("unmapped keys: " + ", ".join(sorted(missing)))
    print("every answer key has a JSON-LD term")


if __name__ == "__main__":
    main()
