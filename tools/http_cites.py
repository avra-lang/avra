#!/usr/bin/env python3
"""The HTTP docs cite fixtures as `<suite> › "<then name>"`; every
citation must name a `then` that exists in that suite, or the doc
claims coverage the tree does not have. Prints what it read."""
import re
import sys

TESTS = "packages/std-http/src/tests/"
SUITES = {
    "C": "conformance_test.av",
    "F": "frame_test.av",
    "FA": "frame_adversarial_test.av",
    "R": "reply_test.av",
    "H": "http_adversarial_test.av",
    "RA": "route_adversarial_test.av",
    "T": "target_form_adversarial_test.av",
    "S": "server_test.av",
    "SA": "server_adversarial_test.av",
    "CT": "client_test.av",
    "CA": "client_adversarial_test.av",
}
DOCS = ["docs/2026_09_06_HTTP_FRAMING_LAWS.md", "docs/2026_09_29_HTTP_CONFORMANCE.md"]
CITE = re.compile(r'\b(' + "|".join(SUITES) + r') › ((?:"[^"]*"(?:, )?)+)')


def main():
    names = {k: set(re.findall(r'then "([^"]*)"', open(TESTS + v).read())) for k, v in SUITES.items()}
    cited, missing = 0, []
    for doc in DOCS:
        for m in CITE.finditer(open(doc).read()):
            for name in re.findall(r'"([^"]*)"', m.group(2)):
                cited += 1
                if name not in names[m.group(1)]:
                    missing.append(f"{doc}: {m.group(1)} › \"{name}\"")
    for line in missing:
        print("no such fixture: " + line)
    print(f"http-cites: {cited} citation(s) across {len(DOCS)} doc(s), {len(missing)} missing")
    return 1 if missing or cited == 0 else 0


if __name__ == "__main__":
    sys.exit(main())
