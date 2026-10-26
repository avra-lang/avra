"""The fixtures' own names, read from the fixture files so nothing is listed
here. A generated name sharing a word with one is refused."""
import json
import pathlib
import re

FIXTURE = pathlib.Path(__file__).resolve().parent.parent / "acceptance"


def words(text):
    return {w.lower() for w in re.findall(r"[A-Za-z]{4,}", text)}


def fixture_words():
    out = set()
    path = FIXTURE / "entities.jsonl"
    if path.exists():
        for line in path.read_text().splitlines():
            if line.strip():
                row = json.loads(line)
                out |= words(" ".join([row.get("label", ""), *row.get("aliases", [])]))
    return out


def common_words():
    """Words the engine's own documentation and sources use: ordinary language, never a fixture's name."""
    root = FIXTURE.parent
    out = set()
    for path in sorted(p for p in (root / "src").rglob("*.av") if "tests" not in p.parts):
        out |= words(path.read_text())
    return out


FIXTURE_WORDS = fixture_words() - common_words()


def clean(name):
    return not (words(name) & FIXTURE_WORDS)
