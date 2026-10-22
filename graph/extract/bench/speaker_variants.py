import json, os, socket
SOCK = os.path.expanduser("~/.cache/avra-graph-ml/cascade.sock")
def choose(ctx, q, opts):
    s = socket.socket(socket.AF_UNIX); s.connect(SOCK)
    s.sendall(json.dumps({"op": "choose", "context": ctx, "question": q, "options": opts}).encode() + b"\n")
    out = b"".join(iter(lambda: s.recv(65536), b"")); s.close(); return json.loads(out)["p"]
desc = "A directed family relationship: relative is subject's relation."
cases = [("My mum Ruth is visiting on 23 October.", "Elena", "Ruth", "mother (mum, mom)", 0),
         ("My sister Mina Torres will meet her at the station.", "Elena", "Mina Torres", "sister", 0),
         ("My own mum June isn't coming on this visit. — Rowan", "Rowan", "June", "mother (mum, mom)", 0),
         ("Alex Chen: My wife Sora can hand over the garment bag to Rowan on 27 October.", "Alex Chen", "Sora", "wife", 0),
         ("Thanks, Alex. I'll check the handover time with you later.", "Elena", "Alex Chen", "wife", None)]
variants = {
 "spoken": lambda s, sp: f'Sentence: "{s}"\nThis sentence is spoken by {sp}.',
 "speaker-words": lambda s, sp: f'Sentence: "{s}"\nThe speaker of this sentence is {sp}; the words the speaker uses for themself mean {sp}.',
}
Q = desc + "\n\nWhich of these does the sentence itself explicitly state? Do not infer from other sentences or world knowledge."
Q2 = desc + "\n\nWhich of these does the sentence itself state?"
for vname, v in variants.items():
    for qn, q in (("explicit", Q), ("state", Q2)):
        ok = 0; ps = []
        for s, sp, other, lab, gold in cases:
            opts = [f"{other} is {sp}'s {lab}", f"{sp} is {other}'s {lab}"]
            p = choose(v(s, sp), q, opts + ["none of these is explicitly stated"])
            best = max(range(3), key=lambda i: p[i])
            want = 2 if gold is None else gold
            ok += best == want; ps.append(round(p[best], 2))
        print(vname, qn, f"{ok}/5", ps)
