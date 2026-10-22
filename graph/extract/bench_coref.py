"""Does a coreference model link each reference to the right named entity?

usage: python bench_coref.py [MODEL_ID]   (default biu-nlp/f-coref)
Gold: bench/coref_gold.json, each case a word (by its n-th occurrence) and
the name it refers to. A case is right when the word's cluster contains a
mention whose text is that name or contains it. Prints accuracy, misses,
load and per-source time, and the model's footprint.
"""
import json
import os
import subprocess
import sys
import time

os.environ.setdefault("HF_HOME", os.path.expanduser("~/.cache/avra-graph-ml/hf"))
here = os.path.dirname(os.path.abspath(__file__))
gold = json.load(open(os.path.join(here, "bench", "coref_gold.json")))
sources = {json.loads(l)["id"]: json.loads(l)["content"] for l in open(os.path.join(here, "..", "acceptance", "sources.jsonl"))}


def nth(text, word, n):
    at = -1
    for _ in range(n):
        at = text.find(word, at + 1)
    return at


def footprint():
    out = subprocess.run(["footprint", "-p", str(os.getpid())], capture_output=True, text=True).stdout
    return next((l.split("Footprint:")[-1].strip().split(" (")[0] for l in out.splitlines() if "Footprint:" in l), "unknown")


def main():
    model_id = sys.argv[1] if len(sys.argv) > 1 else "biu-nlp/f-coref"
    from fastcoref import FCoref

    t = time.time()
    model = FCoref(model_id, device="cpu")
    load_s = time.time() - t
    right = total = 0
    times = []
    for sid, cases in gold.items():
        if sid == "note":
            continue
        text = sources[sid]
        t = time.time()
        clusters = model.predict(texts=[text])[0].get_clusters(as_strings=False)
        times.append(round(time.time() - t, 2))
        for word, n, name in cases:
            at = nth(text, word, n)
            cluster = next((c for c in clusters if any(a <= at < b for a, b in c)), [])
            ok = any(name in text[a:b] for a, b in cluster)
            right += ok
            total += 1
            if not ok:
                print(f"  miss {sid} {word!r}#{n} -> {name}: cluster {[text[a:b] for a, b in cluster]}", file=sys.stderr)
    print(json.dumps({"model": model_id, "right": right, "total": total, "accuracy": round(right / total, 3),
                      "load_s": round(load_s, 1), "source_s": times, "footprint": footprint()}))


if __name__ == "__main__":
    main()
