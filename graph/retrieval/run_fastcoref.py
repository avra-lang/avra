"""Runs extract/bench_coref.py under transformers 5, which fastcoref's model
class predates: it lacks the tied-weights map the loader reads."""
import runpy
import sys

import datasets
import datasets.fingerprint as fp
import fastcoref
import fastcoref.modeling as m

if "lingmess" in " ".join(sys.argv):
    fastcoref.FCoref = fastcoref.LingMessCoref

datasets.disable_caching()
import itertools
_n = itertools.count()
fp.Hasher.hash = staticmethod(lambda value: f"run{next(_n)}")

for cls in vars(m).values():
    if isinstance(cls, type) and cls.__name__.endswith("Model") and not hasattr(cls, "all_tied_weights_keys"):
        cls.all_tied_weights_keys = {}
sys.argv = ["bench_coref.py", *sys.argv[1:]]
runpy.run_path("../extract/bench_coref.py", run_name="__main__")
