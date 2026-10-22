"""Candidate TIMEX3 values for a time expression, by calendar arithmetic alone.

The model never writes a date. Given the instant a source was written (its
anchor) this enumerates what a time expression in it could mean: every date in
a window around the anchor's day, the anchor instant itself, and the two
answers that are not a time. A closed choice picks one; the chosen
normalization goes beside the field's anchor passage, its `reference` the
anchor instant. Calendar names come from the standard library, not a list here.
Durations and sets are not generated yet.
"""
import datetime

from pins import parameter

NOT_SPECIFIC = "this is not a specific time"
UNKNOWN = "cannot tell from the text"


def anchor_of(ms):
    """The UTC instant of a source's millisecond timestamp."""
    return datetime.datetime.fromtimestamp(ms / 1000, tz=datetime.timezone.utc)


def iso_instant(at):
    """ISO 8601 in UTC, keeping milliseconds only when present."""
    text = at.strftime("%Y-%m-%dT%H:%M:%S")
    if at.microsecond:
        text += f".{at.microsecond // 1000:03d}"
    return text + "Z"


def day_label(day):
    return f"{day.strftime('%A')} {day.day} {day.strftime('%B')} {day.year}"


def candidates(anchor_ms, window_days=None):
    """Options for a closed choice, in a fixed order: dates from `window_days`
    before the anchor's UTC day to as many after, the anchor instant, then the
    two non-times. Each is {"label", "normalization"}; a non-time has none."""
    window = parameter("time_window_days") if window_days is None else window_days
    if window < 0:
        raise ValueError("a time window cannot be negative")
    anchor = anchor_of(anchor_ms)
    reference = iso_instant(anchor)
    options = []
    for offset in range(-window, window + 1):
        day = anchor.date() + datetime.timedelta(days=offset)
        options.append({
            "label": day_label(day),
            "normalization": {"kind": "TIMEX3", "timex_type": "DATE", "value": day.isoformat(), "reference": reference},
        })
    options.append({
        "label": f"{day_label(anchor.date())} {anchor.strftime('%H:%M')} UTC, when it was written",
        "normalization": {"kind": "TIMEX3", "timex_type": "TIME", "value": reference, "reference": reference},
    })
    options.append({"label": NOT_SPECIFIC, "normalization": None})
    options.append({"label": UNKNOWN, "normalization": None})
    return options


def chosen(options, index):
    """The normalization a choice picked, or None for a non-time."""
    return options[index]["normalization"]
