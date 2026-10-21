"""Every source through the cascade with random spans and random choices:
no path may raise. usage: python fuzz.py request.json
"""
import json, sys, random
sys.path.insert(0, ".")
import cascade as c
req = json.load(open(sys.argv[1]))
s = req["input"]["content"]
class Enc:
    def mentions(self, text, labels):
        out = {}
        for l in labels:
            out[l] = []
        import re
        ls = list(labels)
        for m in re.finditer(r"[A-Z][\w-]*(?: [A-Z][\w-]*)*", text):
            for l in random.sample(ls, min(len(ls), random.choice([1, 1, 2]))):
                out[l].append({"start": m.start(), "end": m.end(), "confidence": random.random()})
        return out
    def records(self, text, model, anchor, fields):
        return [{f: {"start": 0, "end": min(5, len(text)), "text": text[:5], "confidence": .9} for f in fields}]
class Sc:
    calls = 0
    def begin(self, s): pass
    def pick(self, ctx, q, opts, tail=()):
        return self.choose(ctx, q, list(opts) + list(tail))
    def choose(self, ctx, q, opts):
        if not 2 <= len(opts) <= 26: raise ValueError(f"{len(opts)} options for {q[:60]}")
        self.calls += 1
        k = random.randrange(len(opts))
        return [1.0 if i == k else 0.0 for i in range(len(opts))]
class M: enc, llm, load_s = Enc(), Sc(), 0.0
for seed in range(10):
    random.seed(seed)
    res, logs = c.extract(req, M())
    if res["status"] != "complete":
        print(seed, res["problems"]); break
else:
    print("10 random runs complete")
