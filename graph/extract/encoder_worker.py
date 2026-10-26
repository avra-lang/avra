"""The span encoder in its own process: one JSON request per stdin line,
one JSON answer per stdout line. The cascade starts it for an extraction and
ends it after, so its memory always returns to the system.

Requests: {"op":"mentions","text","labels","threshold"},
{"op":"records","text","model","anchor","fields","threshold"}, {"op":"footprint"}.
CASCADE_ENCODER picks the pinned model; device and precision come from
service_parameters.json unless CASCADE_ENCODER_DEVICE / CASCADE_ENCODER_HALF
override them for a measurement.
"""
import json
import os
import subprocess
import sys

os.environ.setdefault("HF_HOME", os.path.expanduser("~/.cache/avra-graph-ml/hf"))
os.environ.setdefault("HF_HUB_OFFLINE", "1")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pins import ENCODER, parameter  # noqa: E402


def footprint():
    out = subprocess.run(["footprint", "-p", str(os.getpid())], capture_output=True, text=True).stdout
    return next((l.split("Footprint:")[-1].strip().split(" (")[0] for l in out.splitlines() if "Footprint:" in l), "unknown")


def main():
    from gliner2 import GLiNER2

    m = GLiNER2.from_pretrained(
        ENCODER.split("@")[0],
        map_location=os.environ.get("CASCADE_ENCODER_DEVICE", parameter("encoder_device")),
        quantize=os.environ.get("CASCADE_ENCODER_HALF", "1" if parameter("encoder_half") else "0") == "1",
    )
    print(json.dumps({"ready": True, "footprint": footprint()}), flush=True)
    for line in sys.stdin:
        q = json.loads(line)
        if q["op"] == "footprint":
            out = {"footprint": footprint()}
        else:
            out = {"value": answered(m, q["text"], [q], q["threshold"])[0]}
        print(json.dumps(out), flush=True)


def schema_of(m, q):
    """The extraction schema one query asks."""
    s = m.create_schema()
    if q["op"] == "mentions":
        return s.entities(q["labels"])
    b = s.structure(q["model"], mode="natural", anchor=q["anchor"])
    for f in q["fields"]:
        b = b.field(f, dtype="str")
    return s


def answered(m, text, queries, threshold):
    """One value per query: an entity dict for a mentions query, a record list for a records query."""
    out = []
    for q in queries:
        r = m.extract(text, schema_of(m, q), threshold=threshold, include_confidence=True, include_spans=True)
        out.append(r["entities"] if q["op"] == "mentions" else r.get(q["model"]) or [])
    return out


if __name__ == "__main__":
    main()
