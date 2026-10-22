"""Service ops the planner asks of the resident models: `rank` scores whole
answers by the scorer's log-probability, `embed` places texts in the embedding
model's space. Neither is part of extraction (the identity's closure leaves
this module out), so a change here moves no cached extraction.
"""
import os

EMBEDDER = "mlx-community/Qwen3-Embedding-0.6B-4bit-DWQ"
# The instruction goes on the query side only.
QUERY = "Instruct: Given a question about a person's life and work, find the record type that holds its answer\nQuery: "


def ranking_prompt(context, question, shown):
    """The user message of a ranked choice: the options as an unlettered list,
    answered with one option's key."""
    return f"{context}\n\n{question}\n" + "\n".join(f"- {text}" for text in shown) + "\nAnswer with the name of one option only."


def rank(scorer, context, question, shown, keys):
    """For each key, the summed log-probability of its tokens and the turn's
    end given the prompt, and its token count. Every option competes in one
    distribution over whole answers: no letters, no heats."""
    import mlx.core as mx
    from mlx_lm.models.cache import make_prompt_cache, trim_prompt_cache

    tok, model = scorer.tok, scorer.model
    if len(set(keys)) != len(keys):
        raise ValueError("ranked keys must be distinct")
    end = tok.convert_tokens_to_ids("<|im_end|>")
    cache = make_prompt_cache(model)
    first = mx.log_softmax(model(mx.array(tok.encode(scorer.render(ranking_prompt(context, question, shown))))[None], cache=cache)[0, -1].astype(mx.float32))
    out = []
    for key in keys:
        ids = tok.encode(key, add_special_tokens=False) + [end]
        total = first[ids[0]].item()
        if len(ids) > 1:
            after = mx.log_softmax(model(mx.array(ids[:-1])[None], cache=cache)[0].astype(mx.float32), axis=-1)
            total += sum(after[i, ids[i + 1]].item() for i in range(len(ids) - 1))
            trim_prompt_cache(cache, len(ids) - 1)
        out.append({"logp": total, "tokens": len(ids)})
    mx.clear_cache()
    return out


class Embedder:
    """The embedding model, loaded on first use: last-token state, unit length."""

    def __init__(self):
        os.environ.setdefault("HF_HUB_OFFLINE", "1")
        from mlx_lm import load

        self.model, self.tok = load(EMBEDDER)

    def vectors(self, texts, query=False):
        import mlx.core as mx

        out = []
        for text in texts:
            ids = self.tok.encode((QUERY if query else "") + text)
            state = self.model.model(mx.array(ids)[None])[0, -1].astype(mx.float32)
            out.append((state / mx.sqrt((state * state).sum())).tolist())
        mx.clear_cache()
        return out
