#!/usr/bin/env python3
"""Serves the cascade's planner ops (choose/generate/rank) from another scorer.

    ALT_SCORER=<hf repo> ALT_SOCKET=<path> python3 serve_alt.py

One generative model, no encoder, thinking off. The extraction cascade's
source, identity and cache are untouched; only the socket and model differ.
"""
import functools
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "extract"))
import cascade  # noqa: E402

SCORER = os.environ["ALT_SCORER"]
cascade.SOCKET = os.environ["ALT_SOCKET"]
load_original = None


class Scorer(cascade.Scorer):
    def __init__(self):
        from mlx_lm import load

        self.model, self.tok = load(SCORER)
        template = self.tok.apply_chat_template
        self.tok.apply_chat_template = functools.partial(template, enable_thinking=False)
        self.calls, self.source, self.cache, self.prefix = 0, "", None, True


cascade.Scorer = Scorer
cascade.serve()
