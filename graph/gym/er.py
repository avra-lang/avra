#!/usr/bin/env python3
"""Cross-message entity-resolution corpus from built worlds: several sources
mention the same invented entities under varied names, and different entities
sharing one name; gold identity is the world's instance ids.

    python3 er.py --family eval --seeds 1,2,3 --name er-v1
"""
import argparse
import json
import pathlib
import re

import facts
from cat import Cat
from jsonutil import first_json
import llm as llmmod
import render

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE / "out"
CORPUS = HERE / "er"


def entities_of(cat, world, source):
    """{id: full name} of the labelled instances a source's statements state or reference."""
    ids = []
    for vid, i in source["statements"]:
        inst = world["instances"][vid]
        value = inst["versions"][i]
        ids += [vid] + [r for name, _ in cat.references(inst["model"]) for r in (value.get(name) if isinstance(value.get(name), list) else [value.get(name)]) if r]
    return {i: facts.label_of(cat, world, i) for i in dict.fromkeys(ids) if cat.label(world["instances"][i]["model"])}


def spans(text, mentions):
    """Mentions with start/end located in reading order; any whose surface is absent is refused (None)."""
    out, cursor = [], 0
    for m in mentions:
        at = text.find(m["surface"], cursor)
        if at < 0:
            at = text.find(m["surface"])
            if at < 0:
                return None
        out.append({**m, "start": at, "end": at + len(m["surface"])})
        cursor = at + len(m["surface"])
    return out


def source_row(llm, domain, cat, world, source, lines, tries=3):
    ents = entities_of(cat, world, source)
    listing = "\n".join(l["text"] for l in lines)
    roster = "\n".join(f"{i}: {n}" for i, n in ents.items())
    note = ""
    for _ in range(tries):
        reply = llm.generate(
            f"Domain: {domain}.\nEntities (id: full name):\n{roster}\n\nRecords as JSON lines:\n{listing}\n\n"
            "Write a short passage stating every record, in whatever form such records naturally appear. Refer to each entity by its full name at most once; "
            "elsewhere vary how it is named (a first name, surname, nickname, title with a surname, a short form, a role). Where two entities share a name, use the shared name as people do. "
            "Write dates as YYYY-MM-DD and numbers as numerals, state every field's value.\n"
            'Reply with one JSON object {"text": "...", "mentions": [{"surface": "exact words in the text", "entity": "id from the list"}, ...]} listing every naming of an entity in reading order.'
            f"{note}", 4000)
        got = first_json(reply)
        try:
            text, mentions = got["text"], got["mentions"]
            if any(m["entity"] not in ents for m in mentions):
                raise ValueError("an entity id is not in the list")
            placed = spans(text, mentions)
            if placed is None:
                raise ValueError("a mention's surface is not in the text")
            missing = facts.faithful(text, [{"names": [], "literals": [x for l in lines for x in l["literals"]]}])
            if missing is not None:
                raise ValueError(f"the text lacks {missing}")
            unnamed = [i for i in ents if not any(m["entity"] == i for m in placed)]
            if unnamed:
                raise ValueError(f"entities never mentioned: {unnamed}")
            shared = [m for m in placed if not set(re.findall(r"\w{2,}", m["surface"].lower())) & set(re.findall(r"\w{2,}", ents[m["entity"]].lower()))]
            if len(shared) > len(placed) // 4:
                raise ValueError("too many surfaces share no word with their entity's name")
            return {"text": text, "mentions": placed, "made": dict(llm.last), "entities": {i: ents[i] for i in ents}}
        except (KeyError, TypeError, ValueError) as why:
            note = f"\n\nYour previous reply was refused: {why}. Reply again."
    return None


def build(family, seeds, name, llm):
    rows = []
    for seed in seeds:
        d = OUT / family / str(seed)
        cat = Cat(json.loads((d / "catalog.json").read_text())["catalog"])
        world = json.loads((d / "world.json").read_text())
        domain = (d / "models.av").read_text().splitlines()[0].split(":", 1)[1].strip()
        for source in world["sources"]:
            lines = facts.source_lines(cat, world, source)
            row = source_row(llm, domain, cat, world, source, lines)
            if row:
                rows.append({"world": f"{family}-{seed}", "source": source["id"], **row})
        print(f"{family}-{seed}: {sum(r['world'] == f'{family}-{seed}' for r in rows)} sources", flush=True)
    CORPUS.mkdir(exist_ok=True)
    (CORPUS / f"{name}.jsonl").write_text("\n".join(json.dumps(r) for r in rows) + "\n")
    names = {}
    for r in rows:
        for i, n in r["entities"].items():
            names.setdefault((r["world"], n), set()).add(i)
    meta = {"name": name, "sources": len(rows), "mentions": sum(len(r["mentions"]) for r in rows),
            "same_name_different_entity": sum(len(v) > 1 for v in names.values()),
            "entities_seen_in_several_sources": sum(len({r["source"] for r in rows if r["world"] == w and i in r["entities"]}) > 1
                                                    for w, i in {(r["world"], i) for r in rows for i in r["entities"]}),
            "generators": sorted({r["made"].get("model", "") for r in rows})}
    (CORPUS / f"{name}.meta.json").write_text(json.dumps(meta, indent=1))
    print(json.dumps(meta, indent=1))


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--family", default="eval")
    p.add_argument("--seeds", required=True)
    p.add_argument("--name", required=True)
    args = p.parse_args()
    build(args.family, args.seeds.split(","), args.name, llmmod.Hosted())


if __name__ == "__main__":
    main()
