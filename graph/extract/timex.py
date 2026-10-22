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
import calendar
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


CLOCK = re.compile(r"\b([01]?\d|2[0-3]):([0-5]\d)\b")


def with_clock(norm, text, timezone=None):
    """The TIME a chosen DATE becomes when the expression names a clock time
    ("16 October at 11:00"), in the source's zone (UTC when it names none);
    the normalization unchanged when it names none."""
    clock = CLOCK.search(text)
    if not clock or not norm or norm["timex_type"] != "DATE":
        return norm
    zone = zone_of(timezone) or datetime.timezone.utc
    at = datetime.datetime.combine(datetime.date.fromisoformat(norm["value"]), datetime.time(int(clock.group(1)), int(clock.group(2))), tzinfo=zone)
    return {**norm, "timex_type": "TIME", "value": at.isoformat(timespec="seconds")}


def components(text):
    """What a time expression names outright: weekday, month, day number and
    year, by the calendar's own names (full or abbreviated)."""
    words = re.findall(r"[a-z]+", text.lower())
    days = {n.lower(): i for i, n in enumerate(calendar.day_name)} | {n.lower(): i for i, n in enumerate(calendar.day_abbr)}
    months = {n.lower(): i for i, n in enumerate(calendar.month_name) if n} | {n.lower(): i for i, n in enumerate(calendar.month_abbr) if n}
    plain = CLOCK.sub(" ", text)
    return {
        "weekday": next((days[w] for w in words if w in days), None),
        "month": next((months[w] for w in words if w in months), None),
        "day": next((int(n) for n in re.findall(r"\b(\d{1,2})(?:st|nd|rd|th)?\b", plain) if 1 <= int(n) <= 31), None),
        "year": next((int(n) for n in re.findall(r"\b(\d{4})\b", plain)), None),
    }


def narrowed(options, text, room):
    """The options a closed choice about `text` should offer: the dates that
    carry every component the text names outright (all of them when it names
    none, as for "tomorrow"), the nearest to the anchor day when more than
    `room`, then the instant and the non-times. A scorer picks reliably from a
    short list and not from three weeks of dates."""
    is_date = lambda o: bool(o["normalization"]) and o["normalization"]["timex_type"] == "DATE"
    dates, rest = [o for o in options if is_date(o)], [o for o in options if not is_date(o)]
    named = {k: v for k, v in components(text).items() if v is not None}
    day = lambda o: datetime.date.fromisoformat(o["normalization"]["value"])
    fits = {
        "weekday": lambda d, v: d.weekday() == v,
        "month": lambda d, v: d.month == v,
        "day": lambda d, v: d.day == v,
        "year": lambda d, v: d.year == v,
    }
    dates = [o for o in dates if all(fits[k](day(o), v) for k, v in named.items())]
    written = next((o for o in rest if o["normalization"]), None)
    if len(dates) > room and written:
        centre = datetime.date.fromisoformat(written["normalization"]["value"][:10])
        dates = sorted(sorted(dates, key=lambda o: abs((day(o) - centre).days))[:room], key=day)
    return dates + rest


def explicit(options, text):
    """The normalization of a text that names a day and a month outright when
    exactly one candidate date carries all it names, else None: that is
    calendar arithmetic, not a judgement for the scorer."""
    named = components(text)
    if named["day"] is None or named["month"] is None:
        return None
    dates = [o for o in options if o["normalization"] and o["normalization"]["timex_type"] == "DATE"]
    return dates[0]["normalization"] if len(dates) == 1 else None
