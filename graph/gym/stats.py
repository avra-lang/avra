"""Paired evaluation statistics: cluster bootstrap intervals (BCa), the exact
mid-p McNemar test, and risk-coverage for abstention."""
import math
import random
from statistics import NormalDist

N01 = NormalDist()


def by_cluster(clusters, hits):
    """[(hits, size)] per cluster, in first-seen order."""
    order, tally = [], {}
    for c, h in zip(clusters, hits):
        if c not in tally:
            order.append(c)
            tally[c] = [0, 0]
        tally[c][0] += h
        tally[c][1] += 1
    return [tuple(tally[c]) for c in order]


def ratio(parts):
    n = sum(s for _, s in parts)
    return sum(h for h, _ in parts) / n if n else float("nan")


def bca(parts, stat, replicates, alpha):
    """BCa interval of `stat` over cluster parts; `replicates` bootstrap statistics."""
    theta = stat(parts)
    reps = sorted(replicates)
    below = sum(r < theta for r in reps) + 0.5 * sum(r == theta for r in reps)
    z0 = N01.inv_cdf(min(max(below / len(reps), 1e-6), 1 - 1e-6))
    jack = [stat(parts[:i] + parts[i + 1:]) for i in range(len(parts))] if len(parts) > 2 else []
    mean = sum(jack) / len(jack) if jack else 0
    num = sum((mean - j) ** 3 for j in jack)
    den = 6 * sum((mean - j) ** 2 for j in jack) ** 1.5
    a = num / den if den else 0.0
    out = []
    for q in (alpha / 2, 1 - alpha / 2):
        z = N01.inv_cdf(q)
        adj = N01.cdf(z0 + (z0 + z) / (1 - a * (z0 + z)))
        out.append(reps[min(len(reps) - 1, max(0, int(adj * len(reps))))])
    return theta, out[0], out[1]


def accuracy_ci(clusters, hits, draws=10000, alpha=0.05, seed=0):
    """(accuracy, low, high) resampling whole clusters."""
    parts = by_cluster(clusters, hits)
    rng = random.Random(seed)
    reps = [ratio([rng.choice(parts) for _ in parts]) for _ in range(draws)]
    return bca(parts, ratio, reps, alpha)


def difference_ci(clusters, hits_a, hits_b, draws=10000, alpha=0.05, seed=0):
    """(A - B accuracy, low, high): the same clusters are resampled for both, so the pairing holds."""
    both = by_cluster(clusters, [a - b for a, b in zip(hits_a, hits_b)])
    rng = random.Random(seed)
    stat = lambda parts: ratio(parts)  # noqa: E731
    reps = [stat([rng.choice(both) for _ in both]) for _ in range(draws)]
    return bca(both, stat, reps, alpha)


def mcnemar_midp(b, c):
    """Exact two-sided mid-p for discordant counts b (A right, B wrong) and c (A wrong, B right)."""
    n = b + c
    if n == 0:
        return 1.0
    k = min(b, c)
    below = sum(math.comb(n, i) for i in range(k)) / 2 ** n
    at = math.comb(n, k) / 2 ** n
    return min(1.0, 2 * (below + 0.5 * at))


def mcnemar_exact(b, c):
    n = b + c
    if n == 0:
        return 1.0
    k = min(b, c)
    return min(1.0, 2 * sum(math.comb(n, i) for i in range(k + 1)) / 2 ** n)


def paired(clusters, hits_a, hits_b, draws=10000, seed=0):
    b = sum(a and not x for a, x in zip(hits_a, hits_b))
    c = sum(x and not a for a, x in zip(hits_a, hits_b))
    diff, lo, hi = difference_ci(clusters, hits_a, hits_b, draws, seed=seed)
    return {"a_only": b, "b_only": c, "difference": diff, "ci": [lo, hi], "mcnemar_midp": mcnemar_midp(b, c), "mcnemar_exact_p": mcnemar_exact(b, c)}


def risk_coverage(rows):
    """rows: (confidence or None for abstained, correct). Returns the curve [(coverage, risk)] taken by answering
    the most confident first, and the area under it (abstentions are never answered)."""
    answered = sorted((r for r in rows if r[0] is not None), key=lambda r: -r[0])
    n = len(rows)
    curve, wrong = [], 0
    for i, (_, ok) in enumerate(answered, 1):
        wrong += not ok
        curve.append((i / n, wrong / i))
    area = sum(risk for _, risk in curve) / len(curve) if curve else float("nan")
    return curve, area


def risk_at(curve, coverage):
    """Selective risk at the largest coverage not above the given one."""
    fits = [r for c, r in curve if c <= coverage + 1e-12]
    return fits[-1] if fits else float("nan")
