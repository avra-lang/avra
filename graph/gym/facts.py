"""What each source states, as structured fact lines read off the catalog's
declarations: the material a source text is written from and checked against."""
import json
import re

import times
from cat import Cat


def label_of(cat, world, vid):
    inst = world["instances"][vid]
    return inst["versions"][0][cat.label(inst["model"])]


def readable(cat, world, model, value, prefix=()):
    """(fields, names, literals) of one engine value, shown the way the declarations say it is held."""
    fields, names, lits = {}, [], []
    tp, qs = cat.time_paths(model), (cat.quantities(model) if not prefix else {})
    for p in cat.props(model if not prefix else prefix[1]):
        name = p["name"]
        if name not in value:
            continue
        v = value[name]
        path = (name,) if not prefix else prefix[0] + (name,)
        c = cat.core(p["shape"])
        if cat.target(p["shape"]):
            ids = v if isinstance(v, list) else [v]
            shown = [label_of(cat, world, i) for i in ids]
            names += shown
            fields[name] = shown if isinstance(v, list) else shown[0]
        elif isinstance(c, dict) and "embedded" in c:
            sub = readable(cat, world, model, v, (path, c["embedded"]))
            fields[name] = sub[0]
            names += sub[1]
            lits += sub[2]
        elif path in tp:
            d = times.day(v, tp[path])
            fields[name] = d
            lits.append({"date": d})
        elif name in qs:
            q = qs[name]
            dp = q["decimal_places"]
            unit = q["unit"].get("constant") if isinstance(q["unit"], dict) and "constant" in q["unit"] else get_unit(value, q["unit"])
            amount = f"{v // 10 ** dp}.{v % 10 ** dp:0{dp}d}" if dp else str(v)
            fields[name] = f"{amount} {unit}"
            lits.append({"amount": (v // 10 ** dp, v % 10 ** dp)} if dp else {"number": v})
        elif p.get("enum") or c == "boolean":
            fields[name] = v
        elif isinstance(v, str):
            fields[name] = v
            lits.append({"text": v})
        elif isinstance(v, (int, float)):
            fields[name] = v
            lits.append({"number": v})
        else:
            fields[name] = v
    return fields, names, lits


def get_unit(value, unit):
    path = next((v for v in unit.values() if isinstance(v, list)), [])
    for k in path:
        value = value.get(k) if isinstance(value, dict) else None
    return value


def sentence(cat, world, model, value):
    r = cat.relation(model)
    if not r or not r.get("phrasing"):
        return None
    sub, obj = (label_of(cat, world, value[r["from"][0]]), label_of(cat, world, value[r["to"][0]]))
    return r["phrasing"].replace("{from}", sub).replace("{to}", obj).replace("{label}", str(value.get(r["label"][0], "")))


def source_lines(cat, world, source):
    out = []
    for vid, i in source["statements"]:
        inst = world["instances"][vid]
        model, value = inst["model"], inst["versions"][i]
        fields, names, lits = readable(cat, world, model, value)
        label = cat.label(model)
        if label:
            names = [value[label], *names]
        body = {"record_kind": model, "meaning": cat.models[model]["description"], "fields": fields}
        s = sentence(cat, world, model, value)
        if s:
            body["relation"] = s
            names += [label_of(cat, world, value[cat.relation(model)["from"][0]]), label_of(cat, world, value[cat.relation(model)["to"][0]])]
        if i:
            body["restates"] = "this replaces an earlier statement about the same record; the changed property is " + str(inst["changed"])
        out.append({"text": json.dumps(body), "names": list(dict.fromkeys(names)), "literals": lits, "key": vid})
    return out


def numeral_in(text, n):
    return re.search(rf"(?<![\d.]){n}(?![\d]|\.\d)", text) is not None


def carried(text, lit):
    """Whether the text carries a literal, by structure: strings verbatim, numbers as numerals, dates by year and day."""
    if "text" in lit:
        return lit["text"].lower() in text.lower()
    if "number" in lit:
        return numeral_in(text, lit["number"])
    if "date" in lit:
        y, _, d = lit["date"].split("-")
        return lit["date"] in text or (y in text and numeral_in(text, int(d)))
    if "amount" in lit:
        major, minor = lit["amount"]
        return numeral_in(text, major) or re.search(rf"{major}[.,]{minor:02d}", text) is not None
    return True


def faithful(text, lines):
    """The first name or literal of the lines missing from the text, or None."""
    for line in lines:
        for n in line["names"]:
            if n not in text:
                return n
        for lit in line["literals"]:
            if not carried(text, lit):
                return lit
    return None
