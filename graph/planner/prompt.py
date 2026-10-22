"""Prompt helpers: one-line text and the token budget a prompt must fit."""


def line(text):
    """A description on one line, whole: the prompt budget, not a cut, bounds it."""
    return " ".join(text.split())


class Budget:
    """The prompt budget, in tokens: the model's declared context window less
    the tokens an answer may take. A prompt's character count bounds its token
    count from above (a token spans at least one character), so a prompt whose
    characters fit the budget fits the model."""

    def __init__(self, context_tokens, answer_tokens):
        self.tokens = context_tokens - answer_tokens if context_tokens else None

    def holds(self, *texts):
        size = sum(len(t) for t in texts)
        if self.tokens is not None and size > self.tokens:
            raise SystemExit(f"planner: a prompt of {size} characters may exceed the model's {self.tokens}-token budget")


def declared_context(model_id, hub):
    """The context window the model's own config declares, if it is on disk."""
    import json
    import pathlib

    configs = sorted(pathlib.Path(hub).glob(f"models--{model_id.replace('/', '--')}/snapshots/*/config.json"))
    if not configs:
        return None
    return json.loads(configs[-1].read_text()).get("max_position_embeddings")
