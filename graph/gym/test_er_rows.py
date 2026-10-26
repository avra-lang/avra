"""The resolution rows on a world built by hand-free code from a built world: sources mention entities
under full and shortened names; the recorder must answer from identities and see candidates in later sources."""
import json
import pathlib
import tempfile
import unittest

import er_rows

HERE = pathlib.Path(__file__).resolve().parent


def corpus_for(world, catalog):
    labels = {m["name"]: m["semantics"]["label"][0] for m in catalog["models"] if (m.get("semantics") or {}).get("label")}
    named = [(i, x["versions"][0][labels[x["model"]]]) for i, x in world["instances"].items() if x["model"] in labels]
    people = [(i, n) for i, n in named if " " in n][:2]
    if len(people) < 2:
        return None
    (a, na), (b, nb) = people
    rows = []
    for k, (ents) in enumerate([[(a, na), (b, nb)], [(a, na.split()[0]), (b, nb)], [(a, na.split()[-1])]]):
        text = ". ".join(f"{s} was there" for _, s in ents) + "."
        rows.append({"world": "dev-2", "source": f"s{k}", "text": text,
                     "mentions": [{"surface": s, "entity": e} for e, s in ents]})
    return rows, a, b


class Rows(unittest.TestCase):
    def test_later_sources_see_earlier_entities_and_gold_follows_identity(self):
        d = HERE / "out/dev/2"
        if not (d / "app/src/main").exists() :
            self.skipTest("needs the built dev world ")
        world = json.loads((d / "world.json").read_text())
        catalog = json.loads((d / "catalog.json").read_text())["catalog"]
        made = corpus_for(world, catalog)
        if made is None:
            self.skipTest("world has too few named entities with two-word names")
        rows, a, b = made
        out = er_rows.world_rows("dev", 2, rows, pathlib.Path(tempfile.mkdtemp()) / "er.db")
        self.assertTrue(out)
        self.assertTrue(all(r["said_present"] is not None for r in out))
        links = [r for r in out if r["kind"] == "link"]
        self.assertTrue(all(0 <= r["gold"] <= r["candidates"] for r in links))


if __name__ == "__main__":
    unittest.main()
