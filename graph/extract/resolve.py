"""Cross-source entity resolution: after a source is admitted, each new entity
of a model that declares a `label` is offered the graph's existing entities of
that model, and the local model makes one closed choice among them.

usage: python resolve.py < {"graph": [argv...], "source": envelope, "receipt": admit receipt, "result": extraction}
       (the argv is a graph binary's `request --db FILE` prefix; one JSON summary on stdout)

Candidates come from the engine's `referents` op (declared label, merge groups
once). The choice is the closed question of the cascade's antecedent step, over
candidates described by what the graph knows of them; a link needs the fitted
margin and a new entity the fitted ceiling (er_params.json). A link is an
explicit `merge`, reversible by `split`, decided by the scorer that chose it.
Entities of one source are never merged with each other.
"""
import hashlib
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SOCKET = os.path.expanduser("~/.cache/avra-graph-ml/cascade.sock")
KEPT = os.path.expanduser("~/.cache/avra-graph-ml/resolve")
PARAMS = os.environ.get("RESOLVE_PARAMS", os.path.join(HERE, "er_params.json"))
NEW, UNSURE = "someone new, not listed", "cannot tell"
REFERENTS = 8


def fitted(name):
    with open(PARAMS) as f:
        return json.load(f)["params"][name]["value"]


class Chooser:
    """Closed choices from the resident model service, else a model loaded here.
    An answer is kept under the digest of the scorer and the choice, since the
    scorer is deterministic and a replayed history asks the same choices."""

    def __init__(self, kept=KEPT):
        self.local, self.kept = None, kept

    def choose(self, context, question, options):
        body = json.dumps([self.scorer(), context, question, options], sort_keys=True).encode()
        path = os.path.join(self.kept, hashlib.sha256(body).hexdigest() + ".json") if self.kept else None
        if path and os.path.exists(path):
            return json.load(open(path))
        p = self.asked(context, question, options)
        if path:
            os.makedirs(self.kept, exist_ok=True)
            json.dump(p, open(path, "w"))
        return p

    def scorer(self):
        sys.path.insert(0, HERE)
        from pins import SCORER

        return SCORER

    def asked(self, context, question, options):
        import socket

        if os.path.exists(SOCKET):
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                try:
                    s.connect(SOCKET)
                except OSError:
                    s = None
                if s:
                    s.sendall((json.dumps({"op": "choose", "context": context, "question": question, "options": options}) + "\n").encode())
                    data = b""
                    while not data.endswith(b"\n"):
                        chunk = s.recv(65536)
                        if not chunk:
                            break
                        data += chunk
                    answer = json.loads(data)
                    if "p" in answer:
                        return answer["p"]
        if self.local is None:
            sys.path.insert(0, HERE)
            from cascade import Scorer

            self.local = Scorer()
        return self.local.pick(context, question, options)


def decide(p, n, margin, ceiling):
    """link:i, new, or abstain: the cascade's antecedent rule."""
    ranked = sorted(range(len(p)), key=lambda i: -p[i])
    if ranked[0] < n and p[ranked[0]] - p[ranked[1]] >= margin:
        return ranked[0]
    return "new" if ranked[0] == n and max(p[:n]) <= ceiling else "abstain"


def sentence(text, start, end):
    """The sentence or line holding [start, end)."""
    head = max([m.end() for m in re.finditer(r"[.!?]\s|\n", text[:start])] or [0])
    tail = re.search(r"[.!?]\s|\n", text[end:])
    return text[head : end + tail.end() if tail else len(text)].strip()


def merge(call, a, b, decider):
    """An explicit, reversible merge; its id is a digest of the pair, so a replay is idempotent."""
    left, right = sorted([a, b])
    tag = hashlib.sha256(f"{left}\t{right}".encode()).hexdigest()[:16]
    return call({"op": "merge", "id": f"er:{tag}", "left": left, "right": right, "decider": "er:" + decider})


class Graph:
    """The graph one request at a time; reads cached by entity until a write."""

    def __init__(self, call):
        self.call = call
        self.cached, self.owners = {}, {}

    def claims(self, entity, property):
        got = self.call({"op": "get", "id": entity})
        found = [c for c in got.get("fields", {}).get(property, []) if not c.get("denied")] if isinstance(got, dict) else []
        for c in found:
            self.owners[c["claim"]] = entity
        return found

    def owner(self, claim, members, property):
        """The group member that holds a claim."""
        for e in members:
            self.claims(e, property)
        return self.owners[claim]

    def fields(self, entity):
        if entity not in self.cached:
            got = self.call({"op": "get", "id": entity})
            self.cached[entity] = {k: [c["value"] for c in v] for k, v in got.get("fields", {}).items()} if isinstance(got, dict) else {}
        return self.cached[entity]

    def members(self, root):
        find = self.groups()
        seen = {e for m in self.call({"op": "merges"}) if m.get("active") for e in (m["left"], m["right"])}
        return [root] + sorted(e for e in seen if e != root and find(e) == root)

    def groups(self):
        parent = {}

        def find(x):
            while parent.get(x, x) != x:
                x = parent[x]
            return x

        for m in self.call({"op": "merges"}):
            if m.get("active"):
                a, b = find(m["left"]), find(m["right"])
                if a != b:
                    parent[max(a, b)] = min(a, b)
        return find


class Resolver:
    def __init__(self, schema, call=None, chooser=None, texts=None):
        self.labels = {m["name"]: m["semantics"]["label"][0] for m in schema["models"] if (m.get("semantics") or {}).get("label")}
        self.chooser = chooser or Chooser()
        self.margin, self.ceiling, self.name_margin = fitted("margin"), fitted("new_ceiling"), fitted("name_margin")
        self.texts = texts or {}
        self.call = call
        self.decisions = []

    # -- the bench and the harness enter here
    def after_admit(self, app, source, receipt, result=None):
        return self.resolve(app.call, source, receipt)

    def resolve(self, call, source, receipt):
        graph = Graph(call)
        own = [p["entity"] for p in receipt.get("records", [])]
        done = []
        for p in receipt.get("records", []):
            model = (call({"op": "get", "id": p["entity"]})).get("model")
            label = self.labels.get(model)
            names = graph.fields(p["entity"]).get(label) if label else None
            if not names:
                continue
            outcome = self.one(call, graph, source, own, p["entity"], model, names[0])
            if outcome:
                done.append(outcome)
        return done

    def offered(self, call, graph, source, own, entity, model, name):
        """The candidate groups for a mention and the closed choice over them."""
        find = graph.groups()
        mine = {find(e) for e in own if e != entity}
        found = call({"op": "referents", "model": model, "mention": name, "exclude": entity, "limit": REFERENTS})
        if not isinstance(found, list):
            return None
        candidates = []
        for r in found:
            root = find(r["entity"])
            if root not in mine and root != find(entity) and root not in candidates:
                candidates.append(root)
        if not candidates:
            return None
        return candidates, self.row(call, graph, source, entity, name, candidates)

    def one(self, call, graph, source, own, entity, model, name):
        offered = self.offered(call, graph, source, own, entity, model, name)
        if not offered:
            return None
        candidates, row = offered
        p = self.chooser.choose(row["context"], row["question"], row["options"])
        choice = decide(p, len(candidates), self.margin, self.ceiling)
        record = {"entity": entity, "mention": name, "p": [round(x, 3) for x in p], "choice": choice if choice in ("new", "abstain") else candidates[choice]}
        self.decisions.append(record)
        if isinstance(choice, int):
            record["merge"] = merge(call, candidates[choice], entity, self.who())
            graph.cached.clear()
            record["name"] = self.settle(call, graph, graph.groups()(entity), model)
        return record

    def settle(self, call, graph, root, model):
        """Merged mentions spell one name several ways; the graph keeps them
        as rivals until a claim is chosen. One closed choice names the
        spelling the entity is shown under, taken only with the fitted
        margin; below it the rivals stay, which the reader sees as a conflict."""
        asked = self.spellings(call, graph, root, model)
        if not asked:
            return None
        claims, row = asked
        p = self.chooser.choose(row["context"], row["question"], row["options"])
        ranked = sorted(range(len(p)), key=lambda i: -p[i])
        if ranked[0] >= len(claims) or p[ranked[0]] - p[ranked[1]] < self.name_margin:
            return {"spellings": [c["value"] for c in claims], "p": [round(x, 3) for x in p], "choice": "abstain"}
        claim = claims[ranked[0]]["claim"]
        return {"choice": claims[ranked[0]]["value"],
                "chosen": call({"op": "choose", "decision": f"er:name:{claim}", "claim": claim, "decider": "er:" + self.who()})}

    def spellings(self, call, graph, root, model):
        """One claim per distinct spelling of a group's label, and the choice among them;
        None when the group already reads through a chosen claim or spells it one way."""
        label = self.labels[model]
        claims = [c for e in graph.members(root) for c in graph.claims(e, label)]
        if any(c["chosen"] for c in claims):
            return None
        firsts = []
        for c in sorted(claims, key=lambda c: c["claim"]):
            if c["value"] not in [f["value"] for f in firsts]:
                firsts.append(c)
        if len(firsts) < 2:
            return None
        said = [self.said(call, graph.owner(c["claim"], graph.members(root), label), label, c["claim"]) for c in firsts]
        lines = "\n".join(f'- "{c["value"]}"' + (f', as in "{s}"' if s else "") for c, s in zip(firsts, said))
        context = f"The sources write one {model.lower()}'s name in different ways:\n{lines}"
        question = f"Which of these spellings names this {model.lower()} in full, without shortening or added description?"
        return firsts, {"context": context, "question": question, "options": [c["value"] for c in firsts] + [UNSURE]}

    def who(self):
        return self.chooser.scorer() if hasattr(self.chooser, "scorer") else "scripted"

    def row(self, call, graph, source, entity, name, candidates):
        """The closed choice as the antecedent step asks it, over candidates
        described by the graph."""
        text = source["content"]
        at = text.find(name)
        context = f'Text: "{text}"\n\nMention: "{name}" at character {max(at, 0)}.'
        described = [self.describe(call, graph, c) for c in candidates]
        known = "; ".join(described)
        question = f'Known: {known}. In the text, who is "{name}"?'
        return {"context": context, "question": question, "options": described + [NEW, UNSURE]}

    def describe(self, call, graph, root):
        """Everything the graph holds on a merge group, and where its name was said."""
        members = graph.members(root)
        merged = {}
        for e in members:
            for k, vs in graph.fields(e).items():
                for v in vs:
                    if str(v) not in merged.setdefault(k, []):
                        merged[k].append(str(v))
        model = call({"op": "get", "id": root}).get("model")
        label = self.labels.get(model, "name")
        names = merged.pop(label, [root])
        rest = ", ".join(f"{k} {'/'.join(v)}" for k, v in sorted(merged.items()))
        said = self.said(call, members[0], label)
        return f"{' / '.join(names)}" + (f" ({rest})" if rest else "") + (f', as in "{said}"' if said else "")

    def text_of(self, call, observation, revision):
        if (observation, revision) not in self.texts:
            got = call({"op": "source", "id": observation, "revision": revision})
            self.texts[(observation, revision)] = got.get("content") if isinstance(got, dict) else None
        return self.texts[(observation, revision)]

    def said(self, call, entity, label, claim=None):
        for run in call({"op": "explain", "id": entity, "property": label}) or []:
            if claim is not None and run.get("claim") != claim:
                continue
            for a in run.get("anchors") or []:
                text = self.text_of(call, a["source"]["observation"], a["source"]["revision"])
                for sel in a.get("selectors", []):
                    if text and sel.get("kind") == "TextPositionSelector":
                        return sentence(text, sel["start"], sel["end"])
        return None


def main():
    body = json.load(sys.stdin)

    def call(request):
        import tempfile

        with tempfile.TemporaryDirectory() as scratch:
            path = os.path.join(scratch, "request.json")
            open(path, "w").write(json.dumps(request))
            done = subprocess.run([*body["graph"], path], text=True, capture_output=True, timeout=60)
        try:
            return json.loads(done.stdout)
        except json.JSONDecodeError:
            return {"error": (done.stderr or done.stdout).strip()[:400]}

    resolver = Resolver(call({"op": "schema"}), call)
    done = resolver.resolve(call, body["source"], body["receipt"])
    json.dump({"resolved": done}, sys.stdout)


if __name__ == "__main__":
    main()
