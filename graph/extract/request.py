"""Build a C01 ExtractionRequest from an acceptance source row and a catalog.

usage: python request.py SOURCE_ID CATALOG_JSON [SOURCES_JSONL] [--candidates FILE] > request.json
CATALOG_JSON is the app's `{"op":"schema"}` answer.
"""
import json
import sys
from datetime import datetime
from pathlib import Path

PRODUCER = "graph-extract-cascade"
CODE = "cascade:1"


def epoch_ms(stamp):
    return int(datetime.fromisoformat(stamp.replace("Z", "+00:00")).timestamp() * 1000)


def envelope(row):
    """Source metadata only; fixture gold never enters the envelope."""
    return {
        "contract": 2,
        "source": {"observation": row["observation"], "revision": row["revision"]},
        "authored_at_ms": None,
        "received_at_ms": epoch_ms(row["received_at"]),
        "author": row.get("author"),
        "participants": [],
        "conversation": row.get("thread"),
        "media_type": "text/csv" if row.get("kind") == "csv" else "text/plain",
        "content": row["content"],
        "frames": [],
    }


def request(source, catalog, model_id):
    return {
        "contract": 1,
        "request": f"extract:{source['source']['observation']}:{source['source']['revision']}",
        "input": source,
        "catalog": {"fingerprint": catalog["fingerprint"], "descriptor": catalog["models"], "derivations": catalog.get("derivations", [])},
        "extractor": {"producer": PRODUCER, "code": CODE, "model": model_id},
        "scope": "all",
        "candidates": [],
    }


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    cand = sys.argv[sys.argv.index("--candidates") + 1] if "--candidates" in sys.argv else None
    sid, catalog_path = args[0], args[1]
    sources = args[2] if len(args) > 2 else Path(__file__).parent.parent / "acceptance" / "sources.jsonl"
    row = next(r for r in map(json.loads, open(sources)) if r["id"] == sid)
    from pins import MODEL_ID

    made = request(envelope(row), json.load(open(catalog_path)), MODEL_ID)
    if cand:
        made["candidates"] = json.load(open(cand))
    json.dump(made, sys.stdout)
