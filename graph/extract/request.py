"""Build a C01 ExtractionRequest from an acceptance source row and a catalog.

usage: python request.py SOURCE_ID CATALOG_JSON [SOURCES_JSONL] > request.json
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
        "catalog": {"fingerprint": catalog["fingerprint"], "descriptor": catalog["models"]},
        "extractor": {"producer": PRODUCER, "code": CODE, "model": model_id},
        "scope": "all",
        "candidates": [],
    }


if __name__ == "__main__":
    sid, catalog_path = sys.argv[1], sys.argv[2]
    sources = sys.argv[3] if len(sys.argv) > 3 else Path(__file__).parent.parent / "acceptance" / "sources.jsonl"
    row = next(r for r in map(json.loads, open(sources)) if r["id"] == sid)
    from cascade import MODEL_ID

    json.dump(request(envelope(row), json.load(open(catalog_path)), MODEL_ID), sys.stdout)
