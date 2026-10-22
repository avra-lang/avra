"""Candidate TIMEX3 values for a time expression, by calendar arithmetic alone.

The model never writes a date. Given the instant a source was written (its
anchor) this enumerates what a time expression in it could mean: every date in
a window around the anchor's day, the anchor instant itself, and the two
answers that are not a time. A closed choice picks one; the chosen
normalization goes beside the field's anchor passage, its `reference` the
anchor instant. Calendar names come from the standard library, not a list here.
Durations and sets are not generated yet.

Dates are the anchor's calendar days in the source's timezone: the
envelope's own, else the host's declared default. With neither, the dates are
UTC days and every option says so, since the day a message was written can
differ by zone.
"""
import datetime
import re
import zoneinfo

from pins import parameter

NOT_SPECIFIC = "this is not a specific time"
UNKNOWN = "cannot tell from the text"
UNKNOWN_ZONE = "UTC day; the source's timezone is unknown"
OFFSET = re.compile(r"([+-])(\d\d):(\d\d)")


def zone_of(name):
    """A tzinfo for an IANA zone name or a ±HH:MM offset; None for unknown."""
    if name is None:
        return None
    fixed = OFFSET.fullmatch(name)
    if fixed:
        sign = 1 if fixed.group(1) == "+" else -1
        return datetime.timezone(sign * datetime.timedelta(hours=int(fixed.group(2)), minutes=int(fixed.group(3))))
    return zoneinfo.ZoneInfo(name)


def zone_for(request):
    """The timezone an extraction request's source was written in, by name:
    the envelope's own, else the host's declared default, else None."""
    return request["input"].get("timezone") or request.get("default_timezone")


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


def candidates(anchor_ms, timezone=None, window_days=None):
    """Options for a closed choice, in a fixed order: dates from `window_days`
    before the anchor's day in `timezone` to as many after, the anchor
    instant, then the two non-times. Each is {"label", "normalization"}; a
    non-time has none. An unknown timezone is named in every dated label."""
    window = parameter("time_window_days") if window_days is None else window_days
    if window < 0:
        raise ValueError("a time window cannot be negative")
    zone = zone_of(timezone)
    utc = anchor_of(anchor_ms)
    local = utc if zone is None else utc.astimezone(zone)
    note = f" ({UNKNOWN_ZONE})" if zone is None else ""
    reference = iso_instant(utc)
    options = []
    for offset in range(-window, window + 1):
        day = local.date() + datetime.timedelta(days=offset)
        options.append({
            "label": day_label(day) + note,
            "normalization": {"kind": "TIMEX3", "timex_type": "DATE", "value": day.isoformat(), "reference": reference},
        })
    written = reference if zone is None else local.isoformat(timespec="milliseconds" if local.microsecond else "seconds")
    options.append({
        "label": f"{day_label(local.date())} {local.strftime('%H:%M')} {timezone or 'UTC'}, when it was written{note}",
        "normalization": {"kind": "TIMEX3", "timex_type": "TIME", "value": written, "reference": reference},
    })
    options.append({"label": NOT_SPECIFIC, "normalization": None})
    options.append({"label": UNKNOWN, "normalization": None})
    return options


def chosen(options, index):
    """The normalization a choice picked, or None for a non-time."""
    return options[index]["normalization"]
