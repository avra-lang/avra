"""Smoke test of the retrieval ops through the service's wire shape, without the generative model."""
import json
import sys

import service

ents = [{"id": "e1", "name": "Elena Vale", "aliases": ["Lena"], "kind": "Person"}, {"id": "e2", "name": "Maison Aster", "kind": "Organization"}]
print(json.dumps(service.answered({"op": "link", "entities": ents, "mentions": ["Elna", "Aster house"]})))
print(json.dumps(service.answered({"op": "link", "entities": ents, "text": "Did Lena visit Maisson Aster last week?"})))
print(json.dumps(service.answered({"op": "block", "entities": ents, "mentions": ["E. Vale"]})))
ps = [{"id": "p1", "text": "Lena signed the contract on 3 May.", "source": "s1", "facts": ["f1"], "entities": ["e1"]}, {"id": "p2", "text": "The aster order shipped to Paris.", "source": "s2", "facts": ["f2"], "entities": ["e2"]}]
print(json.dumps(service.answered({"op": "retrieve", "passages": ps, "entities": ents, "question": "When did Elena sign?", "mentions": ["Elena"], "n": 2}), indent=0)[:600])
