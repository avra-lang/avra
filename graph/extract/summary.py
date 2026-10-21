"""One line per proposed record: model, readable fields, qualifiers, score.

usage: python summary.py result.json
"""
import json
import sys

r = json.load(open(sys.argv[1]))
names = {x["local_id"]: x["fields"][0]["value"] for x in r["records"] if x["fields"]}
print(r["status"], *(p["message"] for p in r.get("problems", [])))
for f in r.get("proposed_frames", []):
    print(f"  frame {f['id']} parent={f['parent']} speaker={names.get(f['speaker'], f['speaker'])} {next((s['exact'] for s in f['passage']['selector'] if s['kind'] == 'TextQuoteSelector'), '')[:50]!r}")
for x in r["records"]:
    parts = [f"{f['property']}={names.get(f['value'], f['value']) if isinstance(f['value'], str) else f['value']}" for f in x["fields"]]
    q = x["fields"][-1]
    score = next((f["score"] for f in x["fields"] if "score" in f), "")
    res = x.get("resolution", {}).get("kind", "")
    print(f"  {x['local_id']} {x['model']}: {', '.join(parts)} [{q['factuality']}/{q['speech_act']}] {res} {score}")
