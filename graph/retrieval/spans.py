"""Spans of a text that name a known entity: every run of up to `span_words`
words is linked, those scoring over the fitted threshold are kept, and
overlaps keep the best score (the longer span on a tie)."""
import re

from link import PARAMS


def word_runs(text, longest):
    words = [(m.start(), m.end()) for m in re.finditer(r"\w+(?:['’-]\w+)*", text)]
    return [(words[i][0], words[j][1]) for i in range(len(words)) for j in range(i, min(i + longest, len(words)))]


def linked_spans(linker, text, threshold=None, longest=None):
    threshold = PARAMS["span_threshold"] if threshold is None else threshold
    runs = word_runs(text, longest or PARAMS["span_words"])
    scored = [(a, b, e, s) for (a, b), (e, s) in zip(runs, linker.best_many([text[a:b] for a, b in runs]))]
    return [{"start": a, "stop": b, "text": text[a:b], "entity": e, "score": s} for a, b, e, s in kept_spans(scored, threshold)]


def kept_spans(scored, threshold):
    """(start, stop, entity, score) runs over the threshold, non-overlapping, best first kept."""
    scored = [r for r in scored if r[3] >= threshold]
    kept = []
    for a, b, e, s in sorted(scored, key=lambda r: (-r[3], -(r[1] - r[0]), r[0])):
        if all(b <= x or a >= y for x, y, *_ in kept):
            kept.append((a, b, e, s))
    return sorted(kept)
